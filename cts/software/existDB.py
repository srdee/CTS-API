#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import hashlib
import xml.etree.ElementTree as ET
import glob

from ..db import DB
from .. import shell
from ..xmls.texts import Text


class ExistDB(DB):
    """Implementation of DB for ExistDB"""
    def __init__(self, software, version, method, path, data_dir=None, target="./", user=None, port=8080):
        super(ExistDB, self).__init__(software=software, version=version, method=method, path=path, data_dir=data_dir, target=target, user=user, port=port)

    def setup(self):
        """ Returns a string to do a cmd """
        return [
            shell.Separator(),
            shell.Helper("java -jar {0} -console".format(self.file.path)),
            shell.Request("Select target path [{0}]".format(os.path.abspath(__file__))),
            shell.Parameter("{0}".format(self.directory)),
            shell.Request("Data dir:  [webapp/WEB-INF/data]"),
            shell.Parameter("{0}".format(self.data_dir)),
            shell.Request("Enter password: []"),
            shell.Parameter(self.user.password),
            shell.Request("Enter password: []"),
            shell.Parameter(self.user.password),
            shell.Warning("Remind the password you are gonna enter !"),
            shell.Request("Maximum memory in mb: [1024]"),
            shell.Parameter("1024"),
            shell.Request("Cache memory in mb: [128]"),
            shell.Parameter("128")
        ]

    def start(self):
        return [shell.Helper("{0}/bin/startup.sh ".format(self.directory))]

    def stop(self):
        if self.user.password:
            return [shell.Command("{0}/bin/shutdown.sh -p {1}".format(self.directory, self.user.password))]
        else:
            return [shell.Command("{0}/bin/shutdown.sh".format(self.directory))]

    def put(self, texts):
        if isinstance(texts, list):
            commands = list()
            for text in texts:
                commands = commands + self.put(text)
            return commands
        elif isinstance(texts, Text):
            return [
                shell.Command(
                    "{binPath}/bin/client.sh -u {user} -P {password} -m {collection} -p {textPath} -ouri=xmldb:exist://localhost:{port}/exist/xmlrpc".format(
                        textPath=texts.document.path,
                        binPath=self.directory,
                        collection=texts.document.db_dir,
                        user=self.user.name,
                        password=self.user.password,
                        port=self.port
                    )
                )
            ]
        else:       # Tuple
            return [
                shell.Command(
                    "{binPath}/bin/client.sh -u {user} -P {password} -m /db/{collection} -p {textPath} -ouri=xmldb:exist://localhost:{port}/exist/xmlrpc".format(
                        textPath=texts[0],
                        binPath=self.directory,
                        collection=texts[1],
                        user=self.user.name,
                        password=self.user.password,
                        port=self.port
                    )
                )
            ]

    def feedXQuery(self, path=None, version=5):
        """ Feed an XQuery collection

        :returns: List of ShellObjects
        :rtype: List(ShellObject)

        """
        if version == 3:
            path = "/../../xquery/existDB-cts3"
        else:
            path = "/../../xquery/existDB"

        package_directory = os.path.abspath(os.path.dirname(os.path.abspath(__file__)) + path)
        xqs = glob.glob('/'.join([package_directory, '*.xquery'])) + glob.glob('/'.join([package_directory, '*.xq']))

        if version == 3:
            xqs = [(xq, "xq") for xq in xqs]
        else:
            xqs = [(xq, "repository") for xq in xqs]

        return self.put(texts=xqs)

    def dump(self, fn, cts=5, output="./{md5}.zip"):
        if cts == 3:
            dbs = ["/db/xq", "/db/repository"]
        else:
            dbs = ["/db/repository"]

        cmds = list()
        backedUp = list()

        for db in dbs:
            outputFile = output.format(md5=hashlib.md5(db).hexdigest())
            backedUp.append((outputFile, db))
            password = ""
            if self.user.password:
                password = " -p {password} ".format(password=self.user.password)

            cmds.append(
                shell.Command("{directory}/bin/backup.sh -u {username} {password} -b {db} -d {output} -ouri=xmldb:exist://localhost:{port}/exist/xmlrpc".format(
                    directory=self.directory,
                    password=password,
                    username=self.user.name,
                    db=db,
                    output=outputFile,
                    port=self.port))
            )

        shell.run(cmds=cmds, host_fn=fn)    # We run the commands using function given

        return backedUp

    def restore(self, fn, cts=5, directory=""):
        if cts == 3:
            dbs = ["/db/xq", "/db/repository"]
        else:
            dbs = ["/db/repository"]

        password = ""
        if self.user.password:
            password = " -p {password} ".format(password=self.user.password)
        files = ["{directory}/{md5}.zip".format(directory=directory, md5=hashlib.md5(db).hexdigest()) for db in dbs]
        cmds = list()

        for f in files:
            cmds.append(
                shell.Command("{directory}/bin/backup.sh -u {username} {password} -r {input} -ouri=xmldb:exist://localhost:{port}/exist/xmlrpc".format(
                    directory=self.directory,
                    password=password,
                    username=self.user.name,
                    db=db,
                    input=f,
                    port=self.port))
            )

        shell.run(cmds=cmds, host_fn=fn)    # We run the commands using function given

        return dbs

    def jetty_config_xml_attribute(self, xpath, attribute, value):
        """ Change an xml attribute in jetty's configuration

        :param xpath: Xpath to node
        :type xpath: str or unicode
        :param attribute: Attribute to Change
        :type attribute: str or unicode
        :param value: New value for attribute
        :type value: str or int
        """

        path = self.directory + "/tools/jetty/etc/jetty.xml"
        tree = ET.parse(path)
        root = tree.getroot()
        SystemProperty = root.findall(xpath)[0]
        SystemProperty.set(attribute, str(value))

        with open(path, mode="w") as f:
            f.write("""<?xml version="1.0"?>
<!DOCTYPE Configure PUBLIC "-//Jetty//Configure//EN" "http://www.eclipse.org/jetty/configure.dtd">
"""+"\n".join(ET.tostring(root, encoding='utf8', method='xml').split("\n")[1:])
            )

    def update_config(self):
        """ Update the config files """
        self.jetty_config_xml_attribute(
            xpath='./Call[@name="addConnector"]/Arg/New/Set[@name="port"]/SystemProperty',
            attribute="default",
            value=self.port
        )

    def get_config_files(self):
        """ Returns a list of config file to be uploaded on the server

        :returns: list of config files' paths
        :rtype: list(str|unicode)
        """
        return ["/tools/jetty/etc/jetty.xml"]

    def get_service_file(self):
        """ Returns path to an executable to run the database as a service 

        :returns: path of executable
        :rtype: str or unicode
        """
        return self.directory + "/tools/wrapper/bin/exist.sh"