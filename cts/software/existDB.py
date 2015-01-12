#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import hashlib

from ..db import DB
from .. import shell
from ..xml.texts import Text
import glob


class ExistDB(DB):
    """Implementation of DB for ExistDB"""
    def __init__(self, software, version, method, path, target="./", user=None):
        super(ExistDB, self).__init__(software=software, version=version, method=method, path=path, target=target, user=user)

    def setup(self):
        """ Returns a string to do a cmd """
        return [
            shell.Separator(),
            shell.Helper("java -jar {0} -console".format(self.file.path)),
            shell.Request("Select target path [{0}]".format(os.path.abspath(__file__))),
            shell.Parameter("{0}".format(self.directory + "/conf")),
            shell.Request("Data dir:  [webapp/WEB-INF/data]"),
            shell.Parameter("{0}".format(self.directory + "/data")),
            shell.Request("Enter password: []"),
            shell.Parameter("Secured password or simply [password]"),
            shell.Request("Enter password: []"),
            shell.Parameter("Password entered previously"),
            shell.Warning("Remind the password you are gonna enter !"),
            shell.Request("Maximum memory in mb: [1024]"),
            shell.Parameter("1024"),
            shell.Request("Cache memory in mb: [128]"),
            shell.Parameter("128")
        ]

    def start(self):
        return [shell.Helper("{0}/conf/bin/startup.sh".format(self.directory))]

    def stop(self):
        if self.user.password:
            return [shell.Command("{0}/conf/bin/shutdown.sh -p {1}".format(self.directory, self.user.password))]
        else:
            return [shell.Command("{0}/conf/bin/shutdown.sh".format(self.directory))]

    def put(self, texts):
        if isinstance(texts, list):
            commands = list()
            for text in texts:
                commands = commands + self.put(text)
            return commands
        elif isinstance(texts, Text):
            return [
                shell.Command(
                    "{binPath}bin/client.sh -u {user} -P {password} -m {collection} -p {textPath}".format(
                        textPath=texts.document.path,
                        binPath=self.directory+"/conf/",
                        collection=texts.document.db_dir,
                        user=self.user.name,
                        password=self.user.password
                    )
                )
            ]
        else:       # Tuple
            return [
                shell.Command(
                    "{binPath}bin/client.sh -u {user} -P {password} -m /db/{collection} -p {textPath}".format(
                        textPath=texts[0],
                        binPath=self.directory+"/conf/",
                        collection=texts[1],
                        user=self.user.name,
                        password=self.user.password
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
                shell.Command("{directory}/conf/bin/backup.sh -u {username} {password} -b {db} -d {output}".format(
                    directory=self.directory,
                    password=password,
                    username=self.user.name,
                    db=db,
                    output=outputFile))
            )

        shell.run(cmds=cmds, host_fn=fn)    # We run the commands using function given

        return backedUp
