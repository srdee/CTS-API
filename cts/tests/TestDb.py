#!/usr/bin/python
# -*- coding: utf-8 -*-

from cts.software.db import DB
import os

test_file_dir = os.path.dirname(os.path.abspath(__file__)) + "/test_files/"
test_output_dir = os.path.dirname(os.path.abspath(__file__)) + "/test_output_dir/"


def clean_test_output():
    """ Remove data fixture directory """
    os.rmtree(test_output_dir)


def test_version():
    db = DB(software="existDB", version="2.2", source="url", path="http://cznic.dl.sourceforge.net/project/exist/Stable/2.2/eXist-db-setup-2.2.jar")
    assert db.version == (2, 2)
    db = DB(software="existDB", version="2.2.2", source="url", path="http://cznic.dl.sourceforge.net/project/exist/Stable/2.2/eXist-db-setup-2.2.jar")
    assert db.version == (2, 2, 2)


def test_local():
    """ Test that local file can be copied """
    clean_test_output()
    db = DB(software="existDB", version="0.0.1", source="local", path=test_file_dir+"false.jar", target=test_output_dir)
    db.get()
    assert db.file.check() is True
    assert os.path.isfile(test_output_dir + "false.jar") is True
