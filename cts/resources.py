#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
    Text Resources handler

    #######################################
"""

from .files import File
from .xml.inventory import Inventory


class Resource(object):
    """ Object representing an element of Corpus """
    def __init__(self, name, texts, inventory, rewriting_rules={}):
        """ A resource object which goal is to become a collection

        :param name: The name of the collection
        :type name: str or unicode
        :param texts: The folder where we can find texts of the collection
        :type texts: str or unicode
        :param inventory: The inventory file or path
        :type inventory: str or unicode
        """
        self.name = name
        self.texts = texts
        self.inventory = Inventory(xml=inventory, rewriting_rules=rewriting_rules)
        self.rewriting_rules = rewriting_rules


class Corpus(object):
    """ Object representing a text resource """
    def __init__(self, method, path, resources, target="./", retrieve_init=False):
        """ Instantiate a Corpus object, which contains potentially multiple Resource

        :param method: The method to use to retrieve the resources (url, git, local)
        :type method: str or unicode
        :param path: The path of the elements to retrieve
        :type path: str or unicode
        :param resources: A list of resources
        :type resources: list(Resource) or list(dict())
        :param retrieve_init: If set to True, retrieves files before taking care of resources
        :type retrieve_init: boolean

        """
        self.method = method
        self.path = path
        self.target = target

        self.file = self._get_file()

        if retrieve_init is True:
            self.retrieve()

        if isinstance(resources, list) and len([r for r in resources if isinstance(r, Resource)]) > 0:
            self.resources = resources
        elif isinstance(resources, list) and len([r for r in resources if isinstance(r, dict)]) > 0:
            self.resources = [
                Resource(
                    name=resource["name"],
                    texts=resource["texts"],
                    inventory=resource["inventory"],
                    rewriting_rules=resource["rewriting_rules"]
                ) for resource in resources
            ]
        else:
            raise TypeError("Value for resources is not a dict or a list of Resource object")

    def _get_file(self):
        """ Instantiate self.file

        :returns: The File / Directory containing our data
        :rtype: File
        """
        self.file = File(source=self.path, target=self.target, method=self.method)
        return self.file

    def retrieve(self):
        """ Download the source files used for Resources

        :returns: Indicator of success
        :rtype: boolean
        """
        return self.file.get()
