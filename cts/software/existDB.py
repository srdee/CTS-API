#!/usr/bin/python
# -*- coding: utf-8 -*-

from ..db import DB


class ExistDB(DB):
    """Implementation of DB for ExistDB"""
    def __init__(self, software, version, source, path, target="./"):
        super(ExistDB, self).__init__(software=software, version=version, source=source, path=path, target=target)