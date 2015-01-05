#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
from nose import with_setup
from nose.tools import assert_is_instance
import cts.xml.inventory
import cts.xml.texts
import cts.resources

basePath = os.path.dirname(os.path.abspath(__file__)) + "/test_files"
test_inventory_path = basePath + "/test_inventory.xml"
inv = cts.xml.inventory.Inventory(xml=test_inventory_path, rewriting_rules={}, strict=False)
inv_correct = cts.xml.inventory.Inventory(
    xml=test_inventory_path,
    rewriting_rules={
        "/db/repository/greekLit/tlg0003/tlg001/": basePath + "/"
    },
    strict=False
)

editionTest = """
<edition projid="greekLit:perseus-grc2">
    <label xml:lang="en">The Peloponnesian War (Oxford 1942 Epidoc)</label>
    <description xml:lang="eng">Thucydides. Historiae in two volumes. Oxford, Oxford University
      Press. 1942.</description>
    <online docname="/db/repository/greekLit/tlg0003/tlg001/tlg0003.tlg001.perseus-grc2.xml">
      <validate schema="tei-xl.xsd"/>
      <namespaceMapping abbreviation="tei" nsURI="http://www.tei-c.org/ns/1.0"/>
      <citationMapping>
        <citation label="book" xpath="/tei:div[@n='?']" scope="/tei:TEI/tei:text/tei:body/tei:div">
          <citation label="chapter" xpath="/tei:div[@n='?']" scope="/tei:TEI/tei:text/tei:body/tei:div/tei:div[@n='?']">
            <citation label="section" xpath="/tei:div[@n='?']" scope="/tei:TEI/tei:text/tei:body/tei:div/tei:div[@n='?']/tei:div[@n='?']"/>
          </citation>
        </citation>
      </citationMapping>
    </online>
</edition>
"""


def inventory_setup():
    pass


@with_setup(inventory_setup, None)
def TestInventoryAttributes():
    """ Test Inventory attributes are written """
    assert len(inv.textGroups) == 1
    assert len(inv.getTexts()) == 2


@with_setup(inventory_setup, None)
def TestTextGroupsAttributes():
    textgroup = inv.textGroups[0]
    assert textgroup.id == "greekLit:tlg0003"
    assert textgroup.name == "Thucydides"
    assert len(textgroup.works) == 1


@with_setup(inventory_setup, None)
def TestWorkAttributes():
    work = inv.textGroups[0].works[0]
    assert work.id == "greekLit:tlg001"
    assert work.getTitle() == "The Peloponnesian War"  # Default should be english
    assert work.getTitle("en") == "The Peloponnesian War"
    assert work.getTitle("fr") == "La guerre du Peloponnese"
    assert len(work.editions) == 1
    assert len(work.translations) == 1


@with_setup(inventory_setup, None)
def TestTranslationAttributes():
    trans = inv.textGroups[0].works[0].translations[0]
    assert trans.id == "greekLit:perseus-eng1"
    assert trans.getTitle() == "History of the Peloponnesian War (English translation by Thomas Hobbes)"  # Default should be english
    assert_is_instance(trans.document, cts.xml.texts.Document)


@with_setup(inventory_setup, None)
def TestTranslationDocumentNoRewriting():
    doc = inv.textGroups[0].works[0].translations[0].document
    assert doc.path == "/db/repository/greekLit/tlg0003/tlg001/tlg0003.tlg001.perseus-eng1.xml"  # Because no rewriting_rules


@with_setup(inventory_setup, None)
def TestTranslationDocumentCitation():
    doc = inv_correct.textGroups[0].works[0].translations[0].document
    assert doc.path == basePath + "/tlg0003.tlg001.perseus-eng1.xml"  # Because no rewriting_rules
    assert_is_instance(doc.citation, cts.xml.texts.Citation)
    results, errors = doc.testCitation()
    assert results == [True, True], "Results for Translations document citation test should be successful"
    assert "Citation Mapping (2) has label chapter, while refState[2] has unit error_creator" in [error.string for error in errors]


@with_setup(inventory_setup, None)
def TestEditionDocumentCitation():
    doc = inv_correct.textGroups[0].works[0].editions[0].document
    assert doc.path == basePath + "/tlg0003.tlg001.perseus-grc2.xml"  # Because no rewriting_rules
    assert_is_instance(doc.citation, cts.xml.texts.Citation)
    results, errors = doc.testCitation()
    assert results == [True, True, False], "Results for Translations document citation test should be successful except level 3"


def TestGetTexts():
    resources = inv_correct.textGroups[0].works[0].getTexts()
    assert len([t for t in resources if isinstance(t, cts.xml.texts.Edition)]) == 1, "getTexts() should returns Edition"
    assert len([t for t in resources if isinstance(t, cts.xml.texts.Translation)]) == 1, "getTexts() should returns Translation"


def TestGetDocuments():
    R = cts.resources.Resource(name="don't care", texts="don't care", inventory=inv_correct, rewriting_rules={})
    texts = R.getDocuments(if_exists=False)
    assert len([t for t in texts if isinstance(t, cts.xml.texts.Document)]) == 2, "getTexts() should returns all documents when not checking if exists"

    texts = R.getDocuments(if_exists=True)
    assert len([t for t in texts if isinstance(t, cts.xml.texts.Document)]) == 2, "getTexts() should returns all documents if they exists"

    R = cts.resources
    R = cts.resources.Resource(name="don't care", texts="don't care", inventory=inv, rewriting_rules={})
    texts = R.getDocuments(if_exists=True)
    assert len([t for t in texts if isinstance(t, cts.xml.texts.Document)]) == 0, "getTexts() should returns no documents if documents don't exist"
