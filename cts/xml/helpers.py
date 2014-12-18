#!/usr/bin/python
# -*- coding: utf-8 -*-

import xml.etree.ElementTree as ElementTree


def xmlParsing(xml=None):
    """ Parse XML, whether it's a string representation, a path, or an ElementTree.Element

    :returns: XML Object represented by xml variable
    :rtype: ElementTree.Element
    """
    if isinstance(xml, (str, unicode)):
        try:
            return ElementTree.fromstring(xml)
        except:  # If it fails to parse sring, it means it's a path
            try:
                return ElementTree.parse(xml).getroot()
            except:
                return None
    elif isinstance(xml, ElementTree.Element):
        return xml
    else:
        return None
