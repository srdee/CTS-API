#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Fabric deployment script for the CTS-API
"""
from __future__ import with_statement

from datetime import datetime
import os
import json
import shutil
from distutils.util import strtobool

from fabric.api import *

import cts.software.helper
from cts.db import Credential
from cts import shell
from cts.resources import Corpus


# globals
env.project_name = 'cts-api'
env.replicate_name = env.project_name + "-replicate"
env.local_build_name = env.project_name + "-builder"
env.use_ssh_config = True

env.build_dir = None
env.corpora = None
env.as_service = False
env.config = None
env.target = None
env.hosts = list()
TIMESTAMP_FORMAT = "%Y%m%d%H%M"
env.version = datetime.now().strftime(TIMESTAMP_FORMAT)


# Private functions
def _set_host_db(version=None):
    """ Set a remote_db according to a config file

    :param version: Version to use. If set to none, will retrieve the last automatically
    """
    _db_config()

    remote_user = Credential()
    remote_user.from_dic(env.target["user"])

    if env.as_service is False:
        if version is None:
            version = _actual_version()

        env.remote_db = cts.software.helper.instantiate(
            software=env.config["db"]["software"],
            method=env.config["db"]["method"],
            source_path=env.config["db"]["path"],
            binary_dir=env.target["db"] + "/" + version + "/",
            data_dir=env.target["data"] + "/" + version + "/",
            download_dir=env.target["dumps"],
            user=remote_user,
            port=env.target["port"]["default"]
        )
    else:
        env.remote_db = cts.software.helper.instantiate(
            software=env.config["db"]["software"],
            method=env.config["db"]["method"],
            source_path=env.config["db"]["path"],
            binary_dir=env.target["db"] + "/",
            data_dir=env.target["data"] + "/",
            download_dir=env.build_dir,
            user=remote_user,
            port=env.target["port"]
        )


def _actual_version(service_name=None):
    _db_config()
    if service_name is None:
        service_name = env.project_name

    print("Looking for last installed version")
    if env.as_service is True:
        fn = local
    else:
        fn = run

    v = fn("ls -la /etc/init.d/{service_name}".format(service_name=service_name), quiet=True)
    last_version = v.split("\n")[-1].split()[-1].replace("//", "/").replace(env.db.get_service_file().replace(env.db.directory, ""), "").split("/")[-1]
    return last_version


def _define_env(build_dir=False):
    """ Define the function to be used

    :param env: a string representing an environment
    :type env: str or unicode
    :returns: function to use for shell.run(host_fn)
    :rtype: fn
    """
    if bool(strtobool(str(build_dir))) is True:
        return local
    elif env.as_service is True:
        return local
    return run


def _remove_service(service_name=None, local_fn=False):
    """ Remove the service link

    :param service_name: Name of the service
    :type service_name: String
    :param local_fn: If true, use local as a function to run commands
    :type local_fn: boolean
    """
    if service_name is None:
        service_name = env.project_name

    before = [
        "/etc/init.d/{project_name} stop".format(
            project_name=service_name
        ),
        "rm /etc/init.d/{project_name}".format(
            project_name=service_name
        )
    ]

    fn = sudo
    if local_fn is True or env.as_service is True:
        before = ["sudo " + cmd for cmd in before]
        fn = local

    with warn_only():
        [fn(cmd) for cmd in before]


def _make_service(service_name=None, local_fn=True, db=None):
    """ Create the service link

    :param service_name: Name of the service
    :type service_name: String
    :param build_dir: If true, use the building_dir env.db
    :type build_dir: boolean
    """
    if service_name is None:
        service_name = env.project_name

    if db is None:
        db = env.db

    make_srv = "ln -s {service_executable} /etc/init.d/{project_name}".format(
        service_executable=db.get_service_file(),
        project_name=service_name
    )

    fn = sudo
    if local_fn is True:
        make_srv = "sudo " + make_srv
        fn = local

    _remove_service(service_name=service_name, local_fn=local_fn)
    fn(make_srv)  # Make the link


def _get_config():
    """ Loads the JSON file data into Fabric """
    with open("config.json") as f:
        env.config = json.load(f)
    if not env.config:
        raise ValueError("No config file available")


def _rewriting_path(string, modulo=""):
    if isinstance(string, (str, unicode)):
        return string.replace("#", env.build_dir + modulo)
    elif isinstance(string, (dict)):
        return _rewriting_dic(string, modulo=modulo)
    elif isinstance(e, (list)):
        return _rewriting_list(elements, modulo=modulo)
    return string


def _rewriting_list(elements, modulo=""):
    r = []
    for e in elements:
        if isinstance(e, (str, unicode)):
            r.append(_rewriting_path(r, modulo=modulo))
        elif isinstance(e, (list)):
            r.append(_rewriting_list(elements, modulo=modulo))
        elif isinstance(e, (dict)):
            r.append(_rewriting_dic(e, modulo=modulo))
    return r


def _rewriting_dic(dic, modulo=""):
    """ Reformat rewriting_rules, replacing # with env.build_dir """
    ret = {}
    for key in dic:
        if isinstance(dic[key], (str, unicode)):
            ret[key] = _rewriting_path(dic[key], modulo=modulo)
        elif isinstance(dic[key], (dict)):
            ret[key] = _rewriting_dic(dic[key], modulo=modulo)
        elif isinstance(dic[key], (list)):
            ret[key] = _rewriting_lists(dic[key], modulo=modulo)
    return ret


def _corpora_config(force=False):
    """ Use corpora config to feed config

    :param force: Force retrieval of files if folder exists
    :type force: boolean
    """
    if not env.config:
        _get_config()
    env.corpora = [
        Corpus(
            method=r["method"],
            path=r["path"],
            resources=_rewriting_list(r["resources"], modulo="data"),
            target=_get_build_dir() + "/data",
            retrieve_init=False
        ) for r in env.config["repositories"]
    ]
    try:
        for corpus in env.corpora:
            corpus.retrieve()
    except:
        if force is True:
            shutil.rmtree(_get_build_dir() + "/data")
            _corpora_config()
        else:
            for corpus in env.corpora:
                corpus.instantiate_resources()


def _db_restore(db, source_dir, localhost, cts=5):
    db.restore(fn=_define_env(localhost), cts=cts, directory=source_dir)


def _db_backup(cts, db, localhost):
    """ Backup the database

    :param cts: Version of cts
    :type cts: int
    :param db: DB instance to use
    :type db: cts.software.DB
    :param localhost: Wether or not we use loca
    :type localhost: boolean
    """
    return db.dump(fn=_define_env(localhost), cts=cts, output=db.download_dir+"/{md5}.zip")


def _db_config():
    """ Create DB instance """
    if not env.config:
        _get_config()
    user = Credential()
    user.from_dic(env.config["db"]["user"])

    env.db = cts.software.helper.instantiate(
        software=env.config["db"]["software"],
        method=env.config["db"]["method"],
        source_path=env.config["db"]["path"],
        binary_dir=env.build_dir + "/db/conf",
        data_dir=env.build_dir + "db/data",
        download_dir=env.build_dir + "/db",
        user=user
    )


def _fill_config():
    """ Create needed instances """
    _db_config()
    _corpora_config()


def _init():
    """ Initiate the configuration """
    _get_build_dir()
    _get_config()
    _fill_config()


def _get_build_dir():
    if not env.build_dir:
        env.build_dir = "{0}/build/{1}/".format(os.path.dirname(os.path.abspath(__file__)), "build_dir")
    return env.build_dir


def _db_setup(db=None, local_fn=True):
    """ Setup the database

    :param db: DB Instance to set up
    :type db: cts.software.DB
    :param local_fn: Use of local instead of run/sudo
    :type local_fn: boolean
    """
    if db is None:
        db = env.db
    shell.run(db.setup(), _define_env(local_fn))


def _db_stop(local_fn=False, db=None, service_name=None):
    """ Stop the database

    :param local_fn: Use of local instead of run/sudo
    :type local_fn: boolean
    :param db: DB Instance to set up
    :type db: cts.software.DB
    :param service_name: Name of the service to start
    :type service_name: str or unicode
    """
    if db is None:
        db = env.db

    if service_name is None:
        service_name = env.project_name
    cmd = "/etc/init.d/{service_name} stop".format(service_name=service_name)
    if env.as_service is True or local_fn is True:
        local("sudo " + cmd)
    else:
        sudo(cmd)


def _db_start(local_fn=False, db=None, service_name=None):
    """ Start the database

    :param local_fn: Use of local instead of run/sudo
    :type local_fn: boolean
    :param db: DB Instance to set up
    :type db: cts.software.DB
    :param service_name: Name of the service to start
    :type service_name: str or unicode
    """
    if db is None:
        db = env.db

    if service_name is None:
        service_name = env.project_name

    cmd = "/etc/init.d/{service_name} start".format(service_name=service_name)
    if env.as_service is True or local_fn is True:
        local("sudo " + cmd)
    else:
        sudo(cmd)


def _db_restart(service_name=None):
    """ Restart the database

    :param service_name: Name of the service to start
    :type service_name: str or unicode
    """
    if service_name is None:
        service_name = env.project_name
    cmd = "/etc/init.d/{service_name} restart".format(service_name=service_name)
    if env.as_service is True:
        local("sudo " + cmd)
    else:
        sudo(cmd)


def _push_texts(db, build_dir):
    documents = []
    for corpus in env.corpora:
        for resource in corpus.resources:
            documents = documents + resource.getTexts(if_exists=True)

    shell.run(db.put(documents), _define_env(build_dir))


def _push_xq(db, build_dir, cts=5):
    shell.run(db.feedXQuery(version=cts), _define_env(build_dir))


def _push_inv(db, build_dir):
    for corpus in env.corpora:
        for resource in corpus.resources:
            if resource.inventory.path is not None:
                shell.run(db.put((resource.inventory.path, "repository/inventory")), _define_env(build_dir))


def _install_locally(convert=True, build_dir=True):
    db = env.db
    service_name = env.local_build_name
    if build_dir is False:
        db = env.remote_db
        service_name = env.project_name

    with warn_only():
        local("sudo rm -rf {directory}".format(directory=db.directory))
        local("sudo rm -rf {directory}".format(directory=db.data_dir))

    db.retrieve()

    _remove_service(service_name=service_name, local_fn=True)

    if convert is True:
        convert_cts3(copy=False)

    _db_setup(db=db, local_fn=True)

    #Making service and removing service make it easier to install
    if build_dir is True:
        service_name = env.local_build_name
        env.as_service = True
    _make_service(service_name=service_name, local_fn=True, db=db)
    if build_dir is True:
        env.as_service = False

    _db_start(service_name=service_name, local_fn=True)  # As of @0036d8a, we make a service from the building dir to avoid opening a new terminal session
    _push_texts(db=db, build_dir=build_dir)
    _push_xq(db=db, build_dir=build_dir)
    _push_inv(db=db, build_dir=build_dir)


# Environments related tasks
@task
def localhost():
    """ When run before other functions, set the deployment host as localhost """
    env.as_service = True
    _get_config()
    env.target = env.config["localhost"]


@task
def set_hosts(host):
    """ Set the remote host to deploy to """
    _get_config()
    # Update env.hosts instead of calling execute()
    env.hosts = [host]
    env.target = env.config["hosts"][host]


#Þests Related tasks
@task
def test_cts(nosuccess=False, ignore_replication=False, no_color=False):
    """ Test the CTS-Compliancy of our data.

    :param nosuccess: Boolean indicating if we should print Success
    :param ignore_replication: Boolean indicating if we should test for replication of CitationMapping in Files
    :param no_color: Boolean indicating if we should have non-styled string messages
    """

    if nosuccess is not False:
        nosuccess = bool(strtobool(str(nosuccess)))
    if ignore_replication is not False:
        ignore_replication = bool(strtobool(str(ignore_replication)))
    if no_color is not False:
        no_color = bool(strtobool(str(no_color)))

    _corpora_config(force=True)

    results = []

    for corpus in env.corpora:
        for resource in corpus.resources:
            results = results + shell.documentTestResults(resource.inventory.testTextsCitation(ignore_replication=ignore_replication), no_color=no_color)

    if nosuccess is True:
        results = [result for result in results if isinstance(result, (shell.Success)) is False]

    shell.run(results, local, input_required=False)
    clean()


@task
def deploy(convert=True, localhost=False, reuse_local=False):
    """ Build a clean local version and deploy.

    :param convert: Force conversion of CTS3 inventory
    :param convert: bool
    :param localhost: Deploy a local version only if set to True
    :type localhost: bool
    :param reuse_local: If you forgot to put set_hosts or as_service
    :type reuse_local: boolean
    """
    _init()
    """ shortcode for testing
    if reuse_local is not False:
        reuse_local = bool(strtobool(str(reuse_local)))

    if reuse_local is False:
    """

    if convert is not True:
        convert = bool(strtobool(str(convert)))

    if env.as_service is True:
        _set_host_db()
        _install_locally(convert=convert, build_dir=False)
    elif env.target is not None:
        _install_locally(convert=convert, build_dir=True)

        print("Dumping DB")
        backed_up_databases = _db_backup(cts=5, db=env.db, localhost=True)
        #We don't need our DB anymore !
        _db_stop(local_fn=True, service_name=env.local_build_name)

        run("mkdir -p {0}".format(env.target["dumps"]))
        run("mkdir -p {0}".format(env.target["db"]))
        run("mkdir -p {0}".format(env.target["data"]))

        #We put the db stuff out there
        put(local_path=env.db.file.path, remote_path=env.target["dumps"])
        _set_host_db(version=env.version)
        _db_setup(db=env.remote_db, local_fn=False)

        #Now we do the config file dance : we update the config locally
        env.db.set_port(env.target["port"]["replicate"])
        env.db.update_config()
        env.remote_db.set_port(env.target["port"]["replicate"])

        #We copy the given config files to remote
        for path in env.db.get_config_files():
            put(
                local_path=env.db.directory + path,
                remote_path=env.remote_db.directory + path
            )
        #We update our remote_db to have the new replicate_port

        for backed_up_database in backed_up_databases:
            put(local_path=backed_up_database[0], remote_path=env.target["dumps"])   # We upload the files on the other end

        _make_service(service_name=env.replicate_name, local_fn=False, db=env.remote_db)
        _db_start(service_name=env.replicate_name, local_fn=False)
        _db_restore(db=env.remote_db, source_dir=env.target["dumps"], localhost=False)

        #No we stop old main implementation and start the new one
        _db_stop(service_name=env.replicate_name, local_fn=False)

        #We also need to put the right running port
        env.db.set_port(env.target["port"]["default"])
        env.db.update_config()

        #We copy the given config files to remote
        for path in env.db.get_config_files():
            put(
                local_path=env.db.directory + path,
                remote_path=env.remote_db.directory + path
            )

        _make_service(service_name=env.project_name, local_fn=False, db=env.remote_db)

        _db_start(service_name=env.project_name, local_fn=False)
        _remove_service(service_name=env.local_build_name, local_fn=True)
        clean()


@task
def clean():
    """ Clean up build directory """
    shutil.rmtree(_get_build_dir())


@task
def push_texts():
    """ Push Corpora to the Database """
    _set_host_db()
    _corpora_config()
    db = env.remote_db
    local_fn = False

    if env.as_service is True:
        local_fn = True

    with warn_only():
        _db_start(local_fn=local_fn, service_name=env.project_name)

    _push_texts(db=db, build_dir=False)


@task
def push_xq(cts=5):
    """ Push XQueries to the Database """
    _set_host_db()
    db = env.remote_db
    local_fn = False

    if env.as_service is True:
        local_fn = True

    with warn_only():
        _db_start(local_fn=local_fn, service_name=env.project_name)

    _push_xq(db=db, build_dir=False, cts=int(cts))


@task
def push_inv():
    """ Push inventory to the Database """
    _set_host_db()
    _corpora_config()
    db = env.remote_db
    local_fn = False

    if env.as_service is True:
        local_fn = True

    with warn_only():
        _db_start(local_fn=local_fn, service_name=env.project_name)

    _push_inv(db=db, build_dir=False)


@task
def db_stop():
    """ Stop the database """
    _set_host_db()
    local_fn = False

    if env.as_service is True:
        local_fn = True
    _db_stop(db=env.remote_db, local_fn=local_fn)


@task
def db_restart():
    """ Restart the database """
    _set_host_db()
    _db_restart(service_name=env.project_name)


@task
def db_start():
    """ Start the database """
    _set_host_db()
    local_fn = False

    if env.as_service is True:
        local_fn = True
    _db_start(db=env.remote_db, local_fn=local_fn)


@task
def convert_cts3(copy=True):
    """ Convert CTS3 inventory files to CTS5 Inventory files

    :param copy: If not false, copy the result of conversion in env.build_dir/../ by default or to the given folder
    :type copy: string or boolean
    """

    _corpora_config()

    if copy is True:
        directory = env.build_dir + "/../"
    else:
        directory = copy

    i = 0
    converted = list()
    for corpus in env.corpora:
        for resource in corpus.resources:
            if resource.inventory.convert() is not None:
                i += 1
                converted.append(resource.inventory.path)
                print ("{0} inventory converted".format(i))

    if directory is not False:
        for inventory in converted:
            new_inventory = "{directory}/{filename}".format(directory=directory, filename=inventory.split("/")[-1])
            shutil.copyfile(inventory, new_inventory)
            print ("{inventory} \n --> {new_inventory}".format(inventory=inventory.split("/")[-1], new_inventory=os.path.abspath(new_inventory)))


@task
def db_backup(cts=5, version=None):
    """ Backup dbs """
    _init()
    localhost = False

    if env.as_service is True:
        env.as_service

    if version is None:
        version = _actual_version()

    _set_host_db(version=version)
    db = env.remote_db

    return _db_backup(cts=cts, db=db, localhost=localhost)


@task
def db_restore(cts=5, db=None, source_dir=None):
    """ Restore dbs """
    _init()
    localhost = False

    if env.as_service is True:
        env.as_service

    if version is None:
        version = _actual_version()

    if source_dir is None:
        source_dir = db.download_dir

    _set_host_db(version=version)
    db = env.remote_db

    _db_restore(db=db, source_dir=source_dir, localhost=localhost, cts=cts)


@task
def available_versions():
    _init()
    values = run("ls -l {dir}".format(dir=env.target["data"]), quiet=True)
    values = [str(line.split()[-1]) for line in values.split("\n")]
    values.sort()
    if values == 0:
        print ("No version available")
    else:
        if values > 1:
            print ("Last version : {last}".format(last=values[-1]))
            print ("Other versions :")
        else:
            print ("Available versions :")
        for v in values[0:-1]:
            if len(str(v)) == 12:
                print ("({year}/{month}/{day} {hour}:{minute}) - Name : {version}".format(
                    year=v[0:4],
                    month=v[4:6],
                    day=v[6:8],
                    hour=v[8:10],
                    minute=v[10:],
                    version=v
                ))
            else:
                print (v)

_get_build_dir()
