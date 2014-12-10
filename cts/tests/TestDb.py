#!/usr/bin/python
# -*- coding: utf-8 -*-

from nose import with_setup
from nose.tools import assert_is_instance

from cts.software.db import DB, instantiate, ExistDB, BaseX
import os
import shutil

test_file_dir = os.path.dirname(os.path.abspath(__file__)) + "/test_files/"
test_output_dir = os.path.dirname(os.path.abspath(__file__)) + "/test_output_dir/"
test_git_repo = "https://github.com/PonteIneptique/CTS-Nose-Test-Repo.git"
test_zip_file = "http://github.com/PonteIneptique/CTS-Nose-Test-Repo/archive/master.zip"
test_url_file = test_zip_file


def clean_test_output_dir():
    """ Remove data fixture directory """
    shutil.rmtree(test_output_dir, ignore_errors=True)


def test_instantiate():
    """ Test object generation and type retrieved from string """
    exist = instantiate(software="existDB", version="2.2", source="url", path="http://cznic.dl.sourceforge.net/project/exist/Stable/2.2/eXist-db-setup-2.2.jar")
    assert_is_instance(exist, ExistDB)

    basex = instantiate(software="BaseX", version="2.2", source="url", path="http://cznic.dl.sourceforge.net/project/exist/Stable/2.2/eXist-db-setup-2.2.jar")
    assert_is_instance(basex, BaseX)


def test_version():
    """ Test version conversion in DB objects """
    print("Testing X.X version")
    db = DB(software="existDB", version="2.2", source="url", path="http://cznic.dl.sourceforge.net/project/exist/Stable/2.2/eXist-db-setup-2.2.jar")
    assert db.version == (2, 2)

    print("Testing X.X.X version")
    db = DB(software="existDB", version="2.2.2", source="url", path="http://cznic.dl.sourceforge.net/project/exist/Stable/2.2/eXist-db-setup-2.2.jar")
    assert db.version == (2, 2, 2)


@with_setup(None, clean_test_output_dir)
def test_local():
    """ Test that local file can be copied """
    db = DB(software="existDB", version="0.0.1", source="local", path=test_file_dir+"false.jar", target=test_output_dir)
    assert db.get() is True
    assert db.file.check() is True
    assert os.path.isfile(test_output_dir + "false.jar") is True


@with_setup(None, clean_test_output_dir)
def test_git():
    """ Test that git files can be cloned """
    db = DB(software="existDB", version="0.0.1", source="git", path=test_git_repo, target=test_output_dir)
    assert db.get() is True
    assert db.file.check() is True
    assert os.path.isdir(test_output_dir + "CTS-Nose-Test-Repo") is True
    assert os.path.isfile(test_output_dir + "CTS-Nose-Test-Repo/README.md") is True


@with_setup(None, clean_test_output_dir)
def test_url():
    """ Test that url file can be downloaded """
    db = DB(software="existDB", version="0.0.1", source="url", path=test_url_file, target=test_output_dir)
    assert db.get() is True
    assert db.file.check() is True
    assert os.path.isfile(test_output_dir + "master.zip") is True
