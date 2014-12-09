"""
Fabric deployment script for the CTS-API
"""
from __future__ import with_statement

import os
import datetime
import subprocess

from datetime import datetime
from fabric.api import *
from fabric.contrib.console import confirm
from fabric.contrib.project import upload_project
from fabric.contrib.files import exists
from contextlib import contextmanager as _contextmanager

# globals
env.project_name = 'cts-api'
env.prod = False
env.use_ssh_config = True
env.path = '/opt/webapps/' + env.project_name
env.user = os.getenv("USER")
env.git_version = 1.9

TIMESTAMP_FORMAT = "%Y%m%d%H%M%S"

# environments


def check_git_version():
    "Ensure we have access to git"
    version_string = local("git --version", capture=True)
    if version_string.find("git version {0}".format(env.git_version)) == -1:
        abort("Incorrect git version version: should be at least 1.{0}".format(env.git_version))


def deploy():
    """Build a clean local version and deploy."""
    check_git_version()
    #local("%(play_bin)s clean stage" % env)


def test():
    "Use the remote testing server"
    env.hosts = ['ehritest']
