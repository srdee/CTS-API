#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Fabric deployment script for the CTS-API
"""
from __future__ import with_statement

import os
import json
import shutil

from fabric.api import *

import cts.software.helper
from cts.db import Credential
from cts import shell
# globals
env.project_name = 'cts-api'
env.prod = False
env.use_ssh_config = True
env.path = '/opt/webapps/' + env.project_name
env.user = os.getenv("USER")
env.git_version = 1.9
env.build_dir = None
TIMESTAMP_FORMAT = "%Y%m%d%H%M%S"


# environments
def _get_config():
    """ Loads the JSON file data into Fabric """
    with open("config.json") as f:
        env.config = json.load(f)
    if not env.config:
        raise ValueError("No config file available")


def _fill_config():
    """ Create needed instances """
    user = Credential()
    user.from_dic(env.config["db"]["user"])

    env.db = cts.software.helper.instantiate(
        software=env.config["db"]["software"],
        version=env.config["db"]["version"],
        source=env.config["db"]["source"],
        path=env.config["db"]["path"],
        target=env.build_dir + "/db",
        user=user
    )


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


def deploy():
    """ Build a clean local version and deploy. """
    #_check_git_version()
    print("Downloading DB software")
    env.db.retrieve()
    db_setup()
    db_start()
    db_stop()


def clean():
    """ Clean up data """
    shutil.rmtree(_get_build_dir())


def test():
    """ Use the remote testing server """
    env.hosts = ['cts-test']


_get_config()
_get_build_dir()
_fill_config()
