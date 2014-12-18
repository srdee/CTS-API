#!/usr/bin/python
# -*- coding: utf-8 -*-
import cts.xml.texts


def TestNamespaceURI():
    c = cts.xml.texts.Citation(
        xml="<citation label=\"chapter\" xpath=\"/tei:div2[@n='?']\" scope=\"/tei:TEI.2/tei:text/tei:body/\"/>",
        namespaces={
            "tei:": "{http://www.tei-c.org/ns/1.0}"
        }
    )
    warnings = c.testNamespaceURI(xml="""<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="http://www.stoa.org/epidoc/schema/latest/tei-epidoc.rng" schematypens="http://relaxng.org/ns/structure/1.0"?>
        <TEI>
        <teiHeader></teiHeader>
        <text></text>
        </TEI>
    """)
    assert "No namespace uri found in this document" in [warning.string for warning in warnings], "Absence of xml:ns should raise Error"

    warnings = c.testNamespaceURI(xml="""<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="http://www.stoa.org/epidoc/schema/latest/tei-epidoc.rng" schematypens="http://relaxng.org/ns/structure/1.0"?>
        <TEI xmlns="http://google.fr">
        <teiHeader></teiHeader>
        <text></text>
        </TEI>
    """)
    assert "Wrong namespace URI found" in [warning.string for warning in warnings], "Not in self.namespaces xml:ns should raise Error"

    warnings = c.testNamespaceURI(xml="""<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="http://www.stoa.org/epidoc/schema/latest/tei-epidoc.rng" schematypens="http://relaxng.org/ns/structure/1.0"?>
        <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <teiHeader></teiHeader>
        <text></text>
        </TEI>
    """)
    assert len(warnings) == 0, "Good formated xmlns should not raise Error"


def TestNamespaceWarnings():
    #Test when there is one element with no namespace
    c = cts.xml.texts.Citation(
        xml="<citation label=\"chapter\" xpath=\"/tei:div2[@n='?']\" scope=\"/TEI.2/tei:text/tei:body/\"/>",
        namespaces={
            "tei:": "{http://www.tei-c.org/ns/1.0}"
        }
    )
    errors = [e.string for e in c.testNamespace()]
    assert len(errors) == 1, "Scope with no namespace shortcut should raise an error"
    assert "has no namespaces shortcuts like 'tei:'" in errors[0], "Scope with no namespace shortcut in xPath should have a message about it"

    #Test when there is one element with unknown namespace
    c = cts.xml.texts.Citation(
        xml="<citation label=\"chapter\" xpath=\"/tei:div2[@n='?']\" scope=\"/google:TEI.2/tei:text/tei:body/\"/>",
        namespaces={
            "tei:": "{http://www.tei-c.org/ns/1.0}"
        }
    )
    errors = [e.string for e in c.testNamespace()]
    assert len(errors) == 1, "Scope with unknown namespace shortcut in xPath"
    assert "has namespaces shortcuts with no bindings" in errors[0], "Scope with unknown namespace shortcut in xPath should have a message about it"

    #Test when there is one element with no namespace
    c = cts.xml.texts.Citation(
        xml="<citation label=\"chapter\" xpath=\"/div2[@n='?']\" scope=\"/tei:TEI.2/tei:text/tei:body/\"/>",
        namespaces={
            "tei:": "{http://www.tei-c.org/ns/1.0}"
        }
    )
    errors = [e.string for e in c.testNamespace()]
    assert len(errors) == 1, "xpath with no namespace shortcut should raise an error"
    assert "has no namespaces shortcuts like 'tei:'" in errors[0], "xpath with no namespace shortcut in xPath should have a message about it"

    #Test when there is one element with unknown namespace
    c = cts.xml.texts.Citation(
        xml="<citation label=\"chapter\" xpath=\"/google:div2[@n='?']\" scope=\"/tei:TEI.2/tei:text/tei:body/\"/>",
        namespaces={
            "tei:": "{http://www.tei-c.org/ns/1.0}"
        }
    )
    errors = [e.string for e in c.testNamespace()]
    assert len(errors) == 1, "xpath with unknown namespace shortcut in xPath"
    assert "has namespaces shortcuts with no bindings" in errors[0], "xpath with unknown namespace shortcut in xPath should have a message about it"

    #Test when there is one element with unknown namespace
    c = cts.xml.texts.Citation(
        xml="<citation label=\"chapter\" xpath=\"/tei:div2[@n='?']\" scope=\"/tei:TEI.2/tei:text/tei:body/\"/>",
        namespaces={
            "tei:": "{http://www.tei-c.org/ns/1.0}"
        }
    )
    errors = [e.string for e in c.testNamespace()]
    assert len(errors) == 0, "Correct xpath and scope should not raise error"