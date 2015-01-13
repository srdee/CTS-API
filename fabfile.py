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
env.prod = False
env.use_ssh_config = True
env.path = '/opt/webapps/' + env.project_name
env.user = os.getenv("USER")
env.git_version = 1.9
env.build_dir = None
env.corpora = None
TIMESTAMP_FORMAT = "%Y%m%d%H%M"


# environments
@task
def set_hosts(host):
    _get_config()
    # Update env.hosts instead of calling execute()
    env.hosts = [host]
    env.target = env.config["hosts"][host]


def _define_env(localhost=False):
    """ Define the function to be used

    :param env: a string representing an environment
    :type env: str or unicode
    :returns: function to use for shell.run(host_fn)
    :rtype: fn
    """
    if bool(strtobool(str(localhost))) is True:
        return local
    return run


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


def _fill_config(retrieve_init=True):
    """ Create needed instances """
    user = Credential()
    user.from_dic(env.config["db"]["user"])

    env.db = cts.software.helper.instantiate(
        software=env.config["db"]["software"],
        version=env.config["db"]["version"],
        method=env.config["db"]["method"],
        path=env.config["db"]["path"],
        data_dir=env.build_dir + "db/data",
        target=env.build_dir + "/db",
        user=user
    )
    env.db.set_directory(env.build_dir + "db/conf")
    env.corpora = [
        Corpus(
            method=r["method"],
            path=r["path"],
            resources=_rewriting_list(r["resources"], modulo="data"),
            target=env.build_dir + "/data",
            retrieve_init=retrieve_init
        ) for r in env.config["repositories"]
    ]


def _init(retrieve_init=True):
    _get_config()
    _get_build_dir()
    _fill_config(retrieve_init=retrieve_init)


def _check_git_version():
    """Ensure we have access to git """
    version_string = local("git --version", capture=True)
    if version_string.find("git version {0}".format(env.git_version)) == -1:
        abort("Incorrect git version version: should be at least {0}".format(env.git_version))


def _get_build_dir():
    if not env.build_dir:
        env.build_dir = "{0}/build/{1}/".format(os.path.dirname(os.path.abspath(__file__)), "build_dir")
    return env.build_dir


def _db_setup(localhost=False, db=None):
    """ Setup the database """
    if db is None:
        db = env.db
    shell.run(db.setup(), _define_env(localhost))


def _db_stop(localhost=False, db=None):
    """ Stop the database """
    if db is None:
        db = env.db
    shell.run(db.stop(), _define_env(localhost))


def _db_start(localhost=False, db=None):
    """ Start the database """
    if db is None:
        db = env.db
    shell.run(db.start(), _define_env(localhost))


def test():
    """ Use the remote testing server """
    env.hosts = ['cts-test']


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

    if not hasattr(env, "db"):
        _init(retrieve_init=False)

    results = []

    for corpus in env.corpora:
        for resource in corpus.resources:
            results = results + shell.documentTestResults(resource.inventory.testTextsCitation(ignore_replication=ignore_replication), no_color=no_color)

    if nosuccess is True:
        results = [result for result in results if isinstance(result, (shell.Success)) is False]

    shell.run(results, local, input_required=False)
    clean()


@task
def deploy(convert=True, localhost=False):
    """ Build a clean local version and deploy.

    :param convert: Force conversion of inventory
    """
    _init()

    print("Downloading DB software")
    env.db.retrieve()

    if convert is not True:
        convert = bool(strtobool(str(convert)))

    if convert is True:
        convert_cts3()

    print ("Installing locally")
    _db_setup(localhost=True)
    _db_start(localhost=True)
    push_cts(localhost=True, start=False)
    push_xq(localhost=True, start=False)
    push_inv(localhost=True, start=False)

    if localhost is False:
        print("Dumping DB")
        backed_up_databases = db_backup(cts=5, localhost=True)
        #We don't need our DB anymore !
        _db_stop(localhost=True)

        run("mkdir -p {0}".format(env.target["dumps"]))
        run("mkdir -p {0}".format(env.target["db"]))
        run("mkdir -p {0}".format(env.target["data"]))

        #We put the db stuff out there
        version = datetime.now().strftime(TIMESTAMP_FORMAT)
        put(local_path=env.db.file.path, remote_path=env.target["dumps"])

        remote_user = Credential()
        remote_user.from_dic(env.target["user"])
        env.remote_db = cts.software.helper.instantiate(
            software=env.config["db"]["software"],
            version=env.config["db"]["version"],
            method=env.config["db"]["method"],
            path=env.config["db"]["path"],
            data_dir=env.target["data"] + "/" + version + "/",
            target=env.target["dumps"],
            user=remote_user,
            port=env.target["port"]["replicate"]
        )

        env.remote_db.set_directory(env.target["db"] + "/" + version + "/")
        env.remote_db.data_dir = env.target["data"] + "/" + version + "/"

        _db_setup(db=env.remote_db)
        open_shell()

        #Now we do the config file dance : we update the config locally
        env.db.set_port(env.target["port"]["replicate"])
        env.db.update_config()

        #We copy the given config files to remote
        for path in env.db.get_config_files():
            put(
                local_path=env.db.directory + path,
                remote_path=env.remote_db.directory + path
            )

        for backed_up_database in backed_up_databases:
            put(local_path=backed_up_database[0], remote_path=env.target["dumps"])   # We upload the files on the other end

        with settings(warn_only=True):
            sudo("/etc/init.d/{project_name} stop".format(
                project_name=env.replicate_name
            ))
            sudo("rm /etc/init.d/{project_name}".format(
                project_name=env.replicate_name
            ))

        sudo("ln -s {service_executable} /etc/init.d/{project_name}".format(
            service_executable=env.remote_db.get_service_file(),
            project_name=env.replicate_name
        ))
        sudo("/etc/init.d/{project_name} start".format(
            project_name=env.replicate_name
        ))

        db_restore(db=env.remote_db, source_dir=env.target["dumps"])

        #No we stop old main implementation and start the new one
        sudo("/etc/init.d/{project_name} stop".format(
            project_name=env.replicate_name
        ))

        #We also need to put the right running port
        env.db.set_port(env.target["port"]["default"])
        env.db.update_config()

        #We copy the given config files to remote
        for path in env.db.get_config_files():
            put(
                local_path=env.db.directory + path,
                remote_path=env.remote_db.directory + path
            )

        with settings(warn_only=True):
            sudo("/etc/init.d/{project_name} stop".format(
                project_name=env.project_name
            ))
            sudo("rm /etc/init.d/{project_name}".format(
                project_name=env.project_name
            ))

        sudo("ln -s {service_executable} /etc/init.d/{project_name}".format(
            service_executable=env.remote_db.get_service_file(),
            project_name=env.project_name
        ))
        sudo("/etc/init.d/{project_name} start".format(
            project_name=env.project_name
        ))
        clean()


@task
def clean():
    """ Clean up build directory """
    shutil.rmtree(_get_build_dir())


@task
def push_cts(localhost=True, start=True):
    """ Push Corpora to the Database """
    if not hasattr(env, "db"):
        _init(retrieve_init=False)

    if start is True:
        db_start(localhost=localhost)

    documents = []
    for corpus in env.corpora:
        for resource in corpus.resources:
            documents = documents + resource.getTexts(if_exists=True)

    shell.run(env.db.put(documents), _define_env(localhost))


@task
def push_xq(cts=5, localhost=True, start=True):
    """ Push XQueries to the Database """
    if not hasattr(env, "db"):
        _init(retrieve_init=False)

    if start is True:
        db_start(localhost=localhost)

    shell.run(env.db.feedXQuery(version=int(cts)), _define_env(localhost))


@task
def push_inv(localhost=True, start=True):
    """ Push inventory to the Database """
    if not hasattr(env, "db"):
        _init(retrieve_init=False)

    if start is True:
        db_start(localhost=localhost)

    for corpus in env.corpora:
        for resource in corpus.resources:
            if resource.inventory.path is not None:
                shell.run(env.db.put((resource.inventory.path, "repository/inventory")), _define_env(localhost))


@task
def db_stop(localhost=False):
    """ Stop the database """
    _init(retrieve_init=False)
    _db_stop(localhost=localhost)


@task
def db_start(localhost=False):
    """ Start the database """
    _init(retrieve_init=False)
    _db_start(localhost=localhost)


@task
def convert_cts3():
    """ Convert CTS3 inventory files to CTS5 Inventory files """
    if not hasattr(env, "db"):
        _init(retrieve_init=False)
    i = 0
    for corpus in env.corpora:
        for resource in corpus.resources:
            if resource.inventory.convert() is not None:
                i += 1
                print ("{0} inventory converted".format(i))


@task
def db_backup(cts=5, localhost=False):
    """ Backup dbs """
    if not hasattr(env, "db"):
        _init(retrieve_init=False)

    return env.db.dump(fn=_define_env(localhost), cts=cts, output=env.build_dir+"/{md5}.zip")


@task
def db_restore(cts=5, localhost=False, db=None, source_dir=None):
    """ Backup dbs """
    if not hasattr(env, "db"):
        _init(retrieve_init=False)

    if db is None:
        db = env.db

    if source_dir is None:
        source_dir = env.build_dir

    db.restore(fn=_define_env(localhost), cts=cts, directory=source_dir)
    print("Done.")


@task
def test_port(port=8888):
    if not hasattr(env, "db"):
        _init(retrieve_init=False)
    env.db.set_port(port)
    env.db.update_config()


@task
def test_run():
    run("/home/thibault/test-cts-api/database/software/201501131231//bin/startup.sh", pty=False, shell=False, quiet=True)
