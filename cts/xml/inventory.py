#!/usr/bin/python
# -*- coding: utf-8 -*-

import xml.etree.ElementTree as ElementTree
from .errors import *
from .texts import *


class Work(object):
    """ Represents an opus/a Work inside a WorkGroup inside a CTS Inventory """
    def __init__(self, xml, rewriting_rules={}, strict=False):
        """ Initiate the object

        :param xml: A string representing the TextGroup in XML or a ElementTree object
        :type xml: str or unicode or ElementTree.Element
        :param rewriting_rules: A dictionary where key are string to be replaced by their value
        :type rewriting_rules: dict
        :param strict: Indicate wether we should raise Exceptions on CTS compliancy failure
        :type strict: boolean
        """
        self.strict = strict
        self.rewriting_rules = rewriting_rules

        if isinstance(xml, ElementTree.Element):
            self.xml = xml
        else:
            self.xml = ElementTree.parse(xml).getroot()

        self.id = xml.get("projid")

        self.titles = {}
        self._retrieveTitles()

        self.editions = []
        self.translations = []

        self._retrieveEditions()
        self._retrieveTranslations()

    def _retrieveTitles(self):
        """ Retrieve titles from the xml """
        for title in self.xml.findall("{http://chs.harvard.edu/xmlns/cts3/ti}title"):
            self._title_lang = title.get("{http://www.w3.org/XML/1998/namespace}lang")
            self.titles[self._title_lang] = title.text

        if self.strict is True and len(self.titles) == 0:
            raise NoTitleException("Work ID {0} has no title".format(self.id))

    def getTitle(self, lang=None):
        """ Returns the title in given lang if available

        :param lang: The lang to be returned
        :type lang: str or unicode
        :returns: Title of the Work
        :rtype: str or unicode
        """
        try:
            defaulttitle = list(self.titles.keys())[0]
            return self.titles.get(lang, self.titles[defaulttitle])
        except:
            raise NoTitleException()

    def _retrieveEditions(self):
        """ Retrieve and create editions based on self.xml """
        for edition in self.xml.findall("{http://chs.harvard.edu/xmlns/cts3/ti}edition"):
            self.editions.append(Edition(edition, rewriting_rules=self.rewriting_rules, strict=False))

    def _retrieveTranslations(self):
        for translation in self.xml.findall("{http://chs.harvard.edu/xmlns/cts3/ti}translation"):
            self.translations.append(Translation(translation, rewriting_rules=self.rewriting_rules, strict=False))


class TextGroup(object):
    """ Represents a TextGroup in a CTS Inventory """
    def __init__(self, xml, rewriting_rules={}, strict=False):
        """ Initiate the object

        :param xml: A string representing the TextGroup in XML or a ElementTree object
        :type xml: str or unicode or ElementTree.Element
        :param rewriting_rules: A dictionary where key are string to be replaced by their value
        :type rewriting_rules: dict
        :param strict: Indicate wether we should raise Exceptions on CTS compliancy failure
        :type strict: boolean
        """
        self.strict = strict
        self.rewriting_rules = rewriting_rules

        if isinstance(xml, (ElementTree.Element)):
            self.xml = xml
        else:
            self.xml = ElementTree.parse(xml).getroot()

        self.id = xml.get("projid")
        self.name = self.xml.find("{http://chs.harvard.edu/xmlns/cts3/ti}groupname").text

        self.works = []
        self._retrieveWorks()

    def getId(self):
        """ Returns the id of the TextGroup

        :returns: Id of the text group
        :rtype: str or unicode
        """
        return self.id

    def getName(self):
        """ Returns the name of the TextGroup

        :returns: Name of the text group, usually name of an author
        :rtype: str or unicode
        """
        return self.name

    def _retrieveWorks(self):
        for work in self.xml.findall("{http://chs.harvard.edu/xmlns/cts3/ti}work"):
            self.works.append(Work(work, rewriting_rules=self.rewriting_rules))


class Inventory(object):
    """ Represents a CTS Inventory file """
    def __init__(self, path=None, lookup_directory=None, rewriting_rules={}, strict=False):
        """ Initiate an Inventory object

        :param path: The path to the Inventory.xml file
        :type path: str or unicode
        :param lookup_directory: The path to XML files
        :type lookup_directory: str or unicode
        :param rewriting_rules: A dictionary where key are string to be replaced by their value
        :type rewriting_rules: dict
        :param strict: Indicate wether we should raise Exceptions on CTS compliancy failure
        :type strict: boolean
        """
        self.strict = strict
        self.rewriting_rules = rewriting_rules

        self.path = path
        self.textGroups = list()
        self._load()
        self._retrieveTextGroup()

    def _load(self):
        """ Load the xml for further checking
        """
        self.xml = ElementTree.parse(self.path)
        self.root = self.xml.getroot()

    def _retrieveTextGroup(self):
        for group in self.xml.findall("{http://chs.harvard.edu/xmlns/cts3/ti}textgroup"):
            self.textGroups.append(TextGroup(xml=group, rewriting_rules=self.rewriting_rules))
        return self.textGroups

    def getTexts(self, instanceOf=[Edition, Translation]):
        """ Return all documents in subsections of the Inventory instance

        :param instanceOf: A list of object type including Document object to be taking care of
        :type instanceOf: list(Text.__class__)
        :returns: A list of Document() object found in the Inventory
        :rtype: list(Text)
        """
        docs = []
        for textgroup in self.textGroups:
            for work in textgroup.works:
                if Edition in instanceOf:
                    for edition in work.editions:
                        docs.append(edition)

                if Translation in instanceOf:
                    for translation in work.translations:
                        docs.append(translation)
        return docs

    def testTextsCitation(self):
        """ Test all documents available in the Inventory

        :returns: A list of tests results associated in a tuple with a Text.id
        :rtype: list(tuple(str, tuple(list(boolean), list(ConsoleObject))))
        """
        docs = self.getDocuments()
        results = []
        for doc in docs:
            results.append((doc.id, doc.document.testCitation()))
        return results
