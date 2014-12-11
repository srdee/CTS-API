#!/usr/bin/python
# -*- coding: utf-8 -*-

from .files import File


class Credential(object):
    """ Credential for a user """
    def __init__(self, name="admin", password=None):
        """ Represents credentials used to access Database

        :param name: The username
        :type name: str or unicode
        :param password: The password
        :type password: str or unicode or None
        """
        self.name = name
        self.password = password

    def from_dic(self, data):
        """ Set name and password variables using a dictionary

        :param data: A dictionary containing potentially a name and a password key
        :param type: dict
        :returns: Tuple corresponding to name/password
        :rtype: tuple
        """
        if "name" in data and isinstance(data["name"], (str, unicode)):
            self.name = data["name"]
        if "password" in data and isinstance(data["password"], (str, unicode)):
            self.password = data["password"]
            if len(data["password"]) == 0:
                self.password = None
        return (self.name, self.password)

    def __str__(self):
        return "{0}:{1}".format(self.name, self.password)


class DB(object):
    """Abstraction of a DB class"""
    def __init__(self, software, version, source, path, target="./", user=None):
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
        if user:
            self.user = user
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

    def put(self, path):
        """ Push XML file(s) into the XML database

        :param path: Path to a directory
        :type path: unicode or str
        :returns: Boolean indicating success
        :rtype: boolean

        """
        raise NotImplemented("This function is not implemented in this class")
