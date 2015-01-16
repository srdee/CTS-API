#!/usr/bin/python
# -*- coding: utf-8 -*-

from ..db import DB


class BaseX(DB):
    """Implementation of DB for BaseX"""
    def __init__(self, software, method, source_path, binary_dir, data_dir=None, download_dir="./", user=None, port=8080):
        super(BaseX, self).__init__(software=software, method=method, source_path=source_path, binary_dir=binary_dir, data_dir=data_dir, download_dir=download_dir, user=user, port=port)

    def setup(self):
        """ Returns a string about how to setup the BaseXServer """
        return "java -cp {0} -Xmx512m org.basex.BaseXServer".format(self.file.path)

    def start(self):
        """ Returns a string about how to start the BaseXServer """
        return "java -cp {0} -Xmx512m org.basex.BaseXServer".format(self.file.path)

    def stop(self):
        """ Returns a list of command to run to stop the BaseXServer """
        return ["java -cp {0} -Xmx512m org.basex.BaseXServer stop".format(self.file.path)]
