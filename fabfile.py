#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Fabric deployment script for the CTS-API
"""
from __future__ import with_statement

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
env.prod = False
env.use_ssh_config = True
env.path = '/opt/webapps/' + env.project_name
env.user = os.getenv("USER")
env.git_version = 1.9
env.build_dir = None
env.corpora = None
TIMESTAMP_FORMAT = "%Y%m%d%H%M%S"


# environments
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
        target=env.build_dir + "/db",
        user=user
    )

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


def db_setup():
    """ Setup the database """
    shell.run(env.db.setup(), local)


def db_stop():
    """ Stop the database """
    shell.run(env.db.stop(), local)


def db_start():
    """ Start the database """
    shell.run(env.db.start(), local)


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

    _init()
    results = []

    for corpus in env.corpora:
        for resource in corpus.resources:
            results = results + shell.documentTestResults(resource.inventory.testTextsCitation(ignore_replication=ignore_replication), no_color=no_color)

    if nosuccess is True:
        results = [result for result in results if isinstance(result, (shell.Success)) is False]

    shell.run(results, local, input_required=False)
    clean()


@task
def deploy():
    """ Build a clean local version and deploy. """
    #_check_git_version()
    _init()
    print("Downloading DB software")
    env.db.retrieve()
    """
    for corpus in env.corpora:
        corpus.retrieve()
    """
    db_setup()
    db_start()
    db_stop()


@task
def clean():
    """ Clean up build directory """
    shutil.rmtree(_get_build_dir())


@task
def push_cts():
    """ Push Corpora to the Database """
    if env.db is None:
        _init(retrieve_init=False)
    db_start()

    documents = []
    for corpus in env.corpora:
        for resource in corpus.resources:
            documents = documents + resource.getTexts(if_exists=True)

    shell.run(env.db.put(documents), local)


@task
def push_xq():
    """ Push XQueries to the Database """
    if env.db is None:
        _init(retrieve_init=False)
    db_start()

    shell.run(env.db.feedXQuery(), local)


@task
def push_inv():
    """ Push inventory to the Database """
    if env.db is None:
        _init(retrieve_init=False)
    db_start()

    for corpus in env.corpora:
        for resource in corpus.resources:
            if resource.inventory.path is not None:
                shell.run(env.db.put((resource.inventory.path, "inventory")), local)


@task
def stop_db():
    _init(retrieve_init=False)
    db_stop()


@task
def start_db():
    _init(retrieve_init=False)
    db_start()
