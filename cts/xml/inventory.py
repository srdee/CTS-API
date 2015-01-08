#!/usr/bin/python
# -*- coding: utf-8 -*-

from .helpers import xmlParsing, namespace, getNamespaceFromVersion, cts5ns, cts3ns, set_prefixes
from .errors import *
from .texts import *
from xml.etree.ElementTree import ElementTree


class Work(object):
    """ Represents an opus/a Work inside a WorkGroup inside a CTS Inventory """
    def __init__(self, xml, rewriting_rules={}, strict=False, version=5):
        """ Initiate the object

        :param xml: A string representing the TextGroup in XML or a ElementTree object
        :type xml: str or unicode or ElementTree.Element
        :param rewriting_rules: A dictionary where key are string to be replaced by their value
        :type rewriting_rules: dict
        :param strict: Indicate wether we should raise Exceptions on CTS compliancy failure
        :type strict: boolean
        :param version: Indicate the version of CTS used
        :type version: int
        """
        self.strict = strict
        self.rewriting_rules = rewriting_rules

        self.version = version

        self.xml = xmlParsing(xml)

        if self.version == 3:
            self.id = self.xml.get("projid")
        else:
            self.id = self.xml.get("urn")

        self.titles = {}
        self._retrieveTitles()

        self.editions = []
        self.translations = []

        self._retrieveEditions()
        self._retrieveTranslations()

    def getTexts(self):
        """ Retrieve texts in the hierarchy of the work

        :returns: All texts in this Work
        :rtype: list(cts.xml.texts.Text)
        """
        return self.editions + self.translations

    def _retrieveTitles(self):
        """ Retrieve titles from the xml """
        for title in self.xml.findall("{0}title".format(getNamespaceFromVersion(self.version))):
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
            keysList = list(self.titles.keys())
            if "en" in keysList:
                defaulttitle = "en"
            elif "eng" in keysList:
                defaulttitle = "eng"
            else:
                defaulttitle = list(self.titles.keys())[0]
            return self.titles.get(lang, self.titles[defaulttitle])
        except:
            raise NoTitleException()

    def _retrieveEditions(self):
        """ Retrieve and create editions based on self.xml """
        for edition in self.xml.findall("{0}edition".format(getNamespaceFromVersion(self.version))):
            self.editions.append(Edition(edition, rewriting_rules=self.rewriting_rules, strict=False, version=self.version))

    def _retrieveTranslations(self):
        for translation in self.xml.findall("{0}translation".format(getNamespaceFromVersion(self.version))):
            self.translations.append(Translation(translation, rewriting_rules=self.rewriting_rules, strict=False, version=self.version))


class TextGroup(object):
    """ Represents a TextGroup in a CTS Inventory """
    def __init__(self, xml, rewriting_rules={}, strict=False, version=5):
        """ Initiate the object

        :param xml: A string representing the TextGroup in XML or a ElementTree object
        :type xml: str or unicode or ElementTree.Element
        :param rewriting_rules: A dictionary where key are string to be replaced by their value
        :type rewriting_rules: dict
        :param strict: Indicate wether we should raise Exceptions on CTS compliancy failure
        :type strict: boolean
        :param version: Indicate the version of CTS used
        :type version: int
        """
        self.strict = strict
        self.rewriting_rules = rewriting_rules

        self.xml = xmlParsing(xml)

        self.version = version

        if self.version == 3:
            self.id = self.xml.get("projid")
        else:
            self.id = self.xml.get("urn")

        self.name = self.xml.find("{0}groupname".format(getNamespaceFromVersion(self.version))).text

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
        for work in self.xml.findall("{0}work".format(getNamespaceFromVersion(self.version))):
            self.works.append(Work(work, rewriting_rules=self.rewriting_rules, version=self.version))


class Inventory(object):
    """ Represents a CTS Inventory file """
    def __init__(self, xml=None, rewriting_rules={}, strict=False):
        """ Initiate an Inventory object

        :param path: The path to the Inventory.xml file or a string or a xml ElementTree representation
        :type path: str or unicode
        :param rewriting_rules: A dictionary where key are string to be replaced by their value
        :type rewriting_rules: dict
        :param strict: Indicate wether we should raise Exceptions on CTS compliancy failure
        :type strict: boolean
        """
        self.strict = strict
        self.rewriting_rules = rewriting_rules
        self.path = None

        if os.path.exists(xml):
            self.path = xml        # Quick fix, should find a way to check if string is a path
        self.xml = xml

        self.textGroups = list()
        self._load()

        self._retrieveTextGroup()

    def convert(self, path=None, update=True):
        """ Converts CTS3 Inventory to CTS5

        :param path: The path to the Inventory.xml file
        :type path: str or unicode
        :param update: Overwrite on XML file
        :type update: boolean
        :returns: XML of Inventory
        :rtype: Element
        """
        if self.version == 5:
            return self.xml

        if path is not None:
            path = path
        elif self.path is not None:
            path = self.path
        else:
            raise AttributeError("Path of the Inventory is inexistant")

        root = self.xml
        root.set("xmlns:ti", cts5ns.replace("{", "").replace("}", ""))
        root.set("xmlns:dc", "http://purl.org/dc/elements/1.1")

        #First, we fix TextInventory
        root.tag = "{0}TextInventory".format(cts5ns)
        InventoryName = path.split("/")[-1].replace(".xml", "")
        root.set("tiid", InventoryName)

        self.xml = root

        for node in root.iter():
            node.tag = node.tag.replace(cts3ns, cts5ns)

        set_prefixes(root, {
            "ti": cts5ns.replace("{", "").replace("}", ""),
            "dc": "http://purl.org/dc/elements/1.1"
        })

        for group in root.findall("{0}textgroup".format(getNamespaceFromVersion(5))):
            groupUrn = "urn:cts:" + group.get("projid")
            group.set("urn", groupUrn)
            group.set("tiid", InventoryName)

            for work in group.findall("{0}work".format(getNamespaceFromVersion(5))):
                workUrn = groupUrn + "." + work.get("projid").split(":")[-1]
                work.set("groupUrn", groupUrn)
                work.set("urn", workUrn)

                for textType in ["edition", "translation"]:
                    texts = work.findall("{0}{1}".format(getNamespaceFromVersion(5), textType))
                    i = 0
                    for text in texts:
                        text.set("workUrn", workUrn)
                        text.set("urn", workUrn + "." + text.get("projid").split(":")[-1])
                        if len(texts) == 1:
                            text.set("default", "true")
                        elif i == len(texts) - 1:
                            text.set("default", "true")
                        i += 1

        if update is True:
            ET = ElementTree(root)
            ET.write(path, encoding="utf-8")

        return self.xml

    def reload(self):
        """ Reload all children of Inventory
        """
        self._load()
        self._retrieveTextGroup()

    def _load(self):
        """ Load the xml for further checking
        """

        self.xml = xmlParsing(self.xml)
        self.namespace = namespace(self.xml)

        if self.namespace == "http://chs.harvard.edu/xmlns/cts3/ti":
            self.version = 3
            self.id = self.path.split("/")[-1].replace(".xml", "")
        else:
            self.version = 5
            self.id = self.xml.get("tiid")

    def _retrieveTextGroup(self):
        for group in self.xml.findall("{0}textgroup".format(getNamespaceFromVersion(self.version))):
            self.textGroups.append(TextGroup(xml=group, rewriting_rules=self.rewriting_rules, version=self.version))
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

    def testTextsCitation(self, ignore_replication=False):
        """ Test all documents available in the Inventory

        :param ignore_replication: Ignore testReplication test
        :type ignore_replication: boolean
        :returns: A list of tests results associated in a tuple with a Text.id
        :rtype: list(tuple(str, tuple(list(boolean), list(ConsoleObject))))
        """
        docs = self.getTexts()
        results = []
        for doc in docs:
            results.append((doc.document.filename, doc.document.testCitation(ignore_replication=ignore_replication)))
        return results
