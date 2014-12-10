#!/usr/bin/python3
# -*- coding: utf-8 -*-
import os
import subprocess
import shutil
import zipfile


class File(object):
    """ Abstraction for File Objects"""
    def __init__(self, source, target, method):
        """ Feeds methods of object

        :param source: A url, path or git repository from which to retrieve file(s)
        :type source: str or unicode
        :param target: A path to which we needs to put data
        :type target: str or unicode
        :param method: A value of inside ["git", "url", "local"]
        :type method: str or unicode

        """
        self.source = source
        self.target = target
        self.method = method
        self._path()

    def _path(self):
        """ Defines self.path given self.source, self.method and self.target """
        if self.target[-1] != "/":
            self.target += "/"

        if "/" in self.source:
            self.path = self.target + self.source.split("/")[-1]
        else:
            raise NotImplementedError("This software is not done for Windows")
        if self.method == "git":
            self.path = self.path.replace(".git", "")

    def _directory(self):
        """ Check if self.dir exists

        :returns: Availability of a directory
        :rtype: boolean
        """
        dir = self.target

        if not os.path.exists(dir):
            return os.makedirs(dir)
        return True

    def get(self):
        """ Based on method given, download, clone or copy the file to given path

        :returns: Indicates if the process has been successful
        :rtype: boolean
        """
        if self._directory() is False:  # If the directory doesn't exist and can't be created
            raise ValueError("File instance can't create directory {0}".format(self.target))

        if self.method == "url":
            return self._download()
        elif self.method == "git":
            return self._clone()
        elif self.method == "local":
            return self._copy()
        else:
            raise NotImplementedError("Method not implemented yet.")

    def _download(self):
        """ Download a file

        :returns: Indicates if the process has been successful
        :rtype: boolean
        """
        subprocess.call(['wget', '-r', '-l', '1', '-nv', '-p', '-O', self.path, self.source])
        return self.check(force=False)

    def _clone(self):
        """ Clone a file using git

        :returns: Indicates if the process has been successful
        :rtype: boolean
        """
        subprocess.call(['git', 'clone', self.source, self.path])
        return self.check(force=False)

    def _copy(self):
        """ Copy a local file to a given place

        :returns: Indicates if the process has been successful
        :rtype: boolean
        """
        if os.path.isfile(self.source):
            shutil.copy(self.source, self.path)
        elif os.path.isdir(self.source):
            shutil.copytree(self.source, self.path)
        else:
            raise ValueError("Local path does not exist")

        return self.check(force=False)

    def check(self, force=False):
        """ Check if the file is already download or available

        :param force: Indicate wether or not we should get the file if the file doesn't exists
        :param force: boolean
        :returns: Indicate if file is accessible or not
        :rtype: boolean
        """
        if os.path.isfile(self.path) is False and os.path.isdir(self.path) is False:
            if force is True:
                return self.get()
            return False
        return True


class Zip(File):
    def __init__(self, source, target, method):
        """
        Download a file at @url and put it in Software_Root/path/filename
        """
        super(Zip, self).__init__(source, target, method)

    def unzip(self, path=None, sourceDir=None):
        if not path:
            path = self.path
        self.directory(path)
        with zipfile.ZipFile(self.path, 'r') as myzip:
            filelist = myzip.namelist()
            if sourceDir:
                filelist = [f for f in filelist if f.startswith(sourceDir) and not f.endswith("/")]
            if len(filelist) == 0:
                raise ValueError("The filelist is empty, nothing to unzip")
            for filepath in filelist:
                try:
                    filename = os.path.basename(filepath)
                    source = myzip.open(filepath)
                    target = file(os.path.join(path, filename), "wb")
                    with source, target:
                        shutil.copyfileobj(source, target)
                except Exception as E:
                    print (E)
                    return False
            return True
        return False