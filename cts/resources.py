#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
    Text Resources handler

    #######################################

    Configuration file :
    source" : "git",
    "path" : "https://github.com/PerseusDL/canonical.git",
    "ressources" : [
        {
            "texts" : "./CTS_XML_TEI/perseus",
            "inventory" : "./CTS_XML_TextInventory/allcts.xml"
        }
    ]
"""


class Ressource(object):
    """ Object representing an element of Corpus """
    def __init__(self, text, inventory):
        pass


class Corpus(object):
    """ Object representing a text resource """
    def __init__(self, source, path, ressource):

        pass
