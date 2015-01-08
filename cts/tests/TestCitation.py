#!/usr/bin/python
# -*- coding: utf-8 -*-
import cts.xml.texts
from nose.tools import assert_is_instance


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


def TestChildrenRetriever():
    c = cts.xml.texts.Citation(
        xml="<citation label=\"chapter\" xpath=\"/tei:div2[@n='?']\" scope=\"/tei:TEI.2/tei:text/tei:body/\"/>",
        namespaces={
            "tei:": "{http://www.tei-c.org/ns/1.0}"
        }
    )
    assert c.children is None, "When there is no child, there should be no child"
    c = cts.xml.texts.Citation(
        xml="""<citation xmlns="http://chs.harvard.edu/xmlns/cts3/ti" label=\"chapter\" xpath=\"/tei:div2[@n='?']\" scope=\"/tei:TEI.2/tei:text/tei:body/\">
        <citation label=\"chapter\" xpath=\"/tei:div2[@n='?']\" scope=\"/tei:TEI.2/tei:text/tei:body/\"/>
        </citation>
        """,
        namespaces={
            "tei:": "{http://www.tei-c.org/ns/1.0}"
        },
        version=3
    )
    assert_is_instance(c.children, cts.xml.texts.Citation), """ Citation using CTS3 have children founds """


def TestReplication():
    right = """<TEI xmlns="http://www.tei-c.org/ns/1.0">
  <teiHeader type="text">
    <encodingDesc>
      <refsDecl>
        <refState unit="book" delim="."/>
        <refState unit="chapter" delim="."/>
      </refsDecl>
    </encodingDesc>
  </teiHeader>
  </TEI>
    """
    wrong = """<TEI xmlns="http://www.tei-c.org/ns/1.0">
  <teiHeader type="text">
    <encodingDesc>
      <refsDecl>
        <refState unit="error_maker" delim="."/>
        <refState unit="chapter" delim="."/>
      </refsDecl>
    </encodingDesc>
  </teiHeader>
  </TEI>
    """
    c = cts.xml.texts.Citation(
        xml="""<citation xmlns="http://chs.harvard.edu/xmlns/cts3/ti" label=\"book\" xpath=\"/tei:div2[@n='?']\" scope=\"/tei:TEI.2/tei:text/tei:body/\">
        <citation label=\"chapter\" xpath=\"/tei:div2[@n='?']\" scope=\"/tei:TEI.2/tei:text/tei:body/\"/>
        </citation>
        """,
        namespaces={
            "tei:": "{http://www.tei-c.org/ns/1.0}"
        }
    )
    results = c.testReplication(xml=right)
    assert len(results) == 0, "Good replication should not fail"
    results = c.testReplication(xml=wrong)
    assert len(results) > 0, "Wrong replication on one level should fail on one level"


def TestAndOperator():
    xml = """<TEI.2 xmlns="http://www.tei-c.org/ns/1.0">
  <teiHeader type="text">
    <encodingDesc>
      <refsDecl>
        <refState unit="book" delim="."/>
      </refsDecl>
    </encodingDesc>
  </teiHeader>
  <text>
    <body>
        <div1 n="1" type="book" />
    </body>
  </text>
  </TEI.2>
    """
    c = cts.xml.texts.Citation(
        xml="""<citation xmlns="http://chs.harvard.edu/xmlns/cts3/ti" label=\"book\" xpath=\"/tei:div1[@n='?' and @type='book']\" scope=\"/tei:TEI.2/tei:text/tei:body/\" />""",
        namespaces={
            "tei:": "{http://www.tei-c.org/ns/1.0}"
        }
    )
    status, error = c.test(target=xml)
    assert (False not in status and len(error) == 0) is True, """ [@attr1 and @attr2] should not fail when xml is good """

    c = cts.xml.texts.Citation(
        xml="""<citation xmlns="http://chs.harvard.edu/xmlns/cts3/ti" label=\"book\" xpath=\"/tei:div1[@n='?' and @type='error_maker']\" scope=\"/tei:TEI.2/tei:text/tei:body/\" />""",
        namespaces={
            "tei:": "{http://www.tei-c.org/ns/1.0}"
        }
    )
    status, error = c.test(target=xml)
    assert (True not in status and len(error) == 0) is True, """ [@attr1 and @attr2] should fail when xml is wrong """
