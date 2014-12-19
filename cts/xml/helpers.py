#!/usr/bin/python
# -*- coding: utf-8 -*-

import xml.etree.ElementTree as ElementTree
from codecs import *
import re
import os.path

entities = re.compile("(\&[a-zA-Z0-9\.]+\;)")


def removeEntities(path):
    """ Open a file, remove its entities and send back its content

    :param path: Path of the file to open
    :type path: str or unicode
    :returns: Content of the XML File (- Entities)
    :rtype: str or unicode
    """
    if os.path.isfile(path) is False:
        raise IOError("File {0} does not exist".format(path))

    with open(path, "r") as f:
        xml = f.read()
        xml = entities.sub("", xml)
        return xml

    return None


def xmlParsing(xml=None):
    """ Parse XML, whether it's a string representation, a path, or an ElementTree.Element

    :returns: XML Object represented by xml variable
    :rtype: ElementTree.Element
    """
    if isinstance(xml, (str, unicode)):
        if "<" in xml and ">" in xml:
            return ElementTree.fromstring(xml)
        else:
            return ElementTree.fromstring(removeEntities(xml))
    elif isinstance(xml, ElementTree.Element):
        return xml
    else:
        msg = "XML given is no XML \n {0}".format(xml)
        raise ValueError(msg)
