#!/usr/bin/python
# -*- coding: utf-8 -*-

from .files import File


class DB(object):
    """Abstraction of a DB class"""
    def __init__(self, software, version, source, path, target="./"):
        """ Initiate the object

        :param software: Name of the software
        :type software: unicode or str
        :param version: Version of the software
        :type version: unicode or str
        :param source: Source type, should be git or url or local
        :type source: unicode or str
        :param path: Path to which source-downloader needs to query
        :type path: unicode or str
        :param target: Path where file needs to be deployed
        :type target: unicode or str

        """
        self.software = software
        self.version = self._version_tuple(version)
        self.source = source
        self.path = path
        self.file = self._feed_file_instance(source=source, path=path, target=target)

    def _version_tuple(self, version):
        """ Return a tuple representing the version for further tests

        :param version: String representation of the version
        :type  version: unicode or str
        :returns: numeric representation using tuple
        :rtype: tuple

        """
        return tuple([int(version_part) for version_part in version.split(".") if version_part.isdigit()])

    def _feed_file_instance(self, source, path, target):
        """ Returns a File() object corresponding to Git, Local or URL resource

        :param source: Source type, should be git or url or local
        :type source: unicode or str
        :param path: Path to which source-downloader needs to query
        :type path: unicode or str
        :param target: Path where file needs to be deployed
        :type target: unicode or str
        :returns: numeric representation using tuple
        :rtype: cts.files.File

        """
        instance = File(source=path, target=target, method=source)
        return instance

    def get(self):
        """ Get the file used for running the DB

        :returns: Boolean indicating if the file exists
        :rtype: boolean
        """
        return self.file.get()
