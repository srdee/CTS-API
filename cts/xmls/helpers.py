#!/usr/bin/python
# -*- coding: utf-8 -*-

import xml.etree.ElementTree as ElementTree
from codecs import *
import re
import os.path

entities = re.compile("(\&[a-zA-Z0-9\.]+\;)")
ns = re.compile('\{(.*)\}')
cts5ns = "{http://chs.harvard.edu/xmlns/cts}"
cts3ns = "{http://chs.harvard.edu/xmlns/cts3/ti}"


def removeEntities(path):
    """ Open a file, remove its entities and send back its content

    :param path: Path of the file to open
    :type path: str or unicode
    :returns: Content of the XML File (- Entities)
    :rtype: str or unicode
    """
    if os.path.isfile(path) is False:
        raise IOError("File does not exist ( {0} )".format(path))

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


def namespace(element):
    """ Return the element namespace """
    m = ns.match(element.tag)
    return m.group(1) if m else ''


def getNamespaceFromVersion(version=5):
    """ Returns the namespace according to the CTS version

    :param version: Indicate the version of CTS used
    :type version: int
    :returns: namespace
    :rtype: str or unicode
    """
    if version == 3:
        return cts3ns
    return cts5ns
