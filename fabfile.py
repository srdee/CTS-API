#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Fabric deployment script for the CTS-API
"""
from __future__ import with_statement

import os
from datetime import datetime
import json
from fabric.api import *

from cts.software import db

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
    env.db = db.instantiate(
        software=env.config["db"]["software"],
        version=env.config["db"]["version"],
        source=env.config["db"]["source"],
        path=env.config["db"]["path"],
        target=env.build_dir + "/db"
    )


def _check_git_version():
    """Ensure we have access to git """
    version_string = local("git --version", capture=True)
    if version_string.find("git version {0}".format(env.git_version)) == -1:
        abort("Incorrect git version version: should be at least 1.{0}".format(env.git_version))


def _get_build_dir():
    if not env.build_dir:
        env.build_dir = "{0}/build/{1}/".format(os.path.dirname(os.path.abspath(__file__)), datetime.now().strftime(TIMESTAMP_FORMAT))
    return env.build_dir


def deploy():
    """ Build a clean local version and deploy. """
    _check_git_version()
    _get_config()
    _get_build_dir()
    _fill_config()
    env.db.get()
    #local("%(play_bin)s clean stage" % env)


def test():
    """ Use the remote testing server """
    env.hosts = ['cts-test']
