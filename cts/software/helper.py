#!/usr/bin/python
# -*- coding: utf-8 -*-

from .baseX import BaseX
from .existDB import ExistDB


def instantiate(software, version, source, path, target="./", user=None):
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
    :returns: An instance of DB given the software
    :rtype: DB subclass
    """
    if software.lower() == "existdb":
        return ExistDB(software=software, version=version, source=source, path=path, target=target, user=user)
    elif software.lower() == "basex":
        return BaseX(software=software, version=version, source=source, path=path, target=target, user=user)
    else:
        raise NotImplemented("This DB software is not implemented yet.")
