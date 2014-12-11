#!/usr/bin/python
# -*- coding: utf-8 -*-

from ..db import DB


class BaseX(DB):
    """Implementation of DB for BaseX"""
    def __init__(self, software, version, source, path, target="./", user=None):
        super(BaseX, self).__init__(software=software, version=version, source=source, path=path, target=target, user=user)

    def setup(self):
        """ Returns a string about how to setup the BaseXServer """
        return "java -cp {0} -Xmx512m org.basex.BaseXServer".format(self.file.path)

    def start(self):
        """ Returns a string about how to start the BaseXServer """
        return "java -cp {0} -Xmx512m org.basex.BaseXServer".format(self.file.path)

    def stop(self):
        """ Returns a list of command to run to stop the BaseXServer """
        return ["java -cp {0} -Xmx512m org.basex.BaseXServer stop".format(self.file.path)]
