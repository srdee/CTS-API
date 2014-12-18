#!/usr/bin/python
# -*- coding: utf-8 -*-

import xml.etree.ElementTree as ElementTree


def xmlParsing(xml=None):
    """ Parse XML, whether it's a string representation, a path, or an ElementTree.Element

    :returns: XML Object represented by xml variable
    :rtype: ElementTree.Element
    """
    if isinstance(xml, (str, unicode)):
        if "<" in xml and ">" in xml:
            return ElementTree.fromstring(xml)
        else:
            return ElementTree.parse(xml).getroot()
    elif isinstance(xml, ElementTree.Element):
        return xml
    else:
        msg = "XML given is no XML \n {0}".format(xml)
        raise ValueError(msg)
