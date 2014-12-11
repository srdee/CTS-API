#!/usr/bin/python
# -*- coding: utf-8 -*-

from ..db import DB


class BaseX(DB):
    """Implementation of DB for BaseX"""
    def __init__(self, software, version, source, path, target="./"):
        super(BaseX, self).__init__(software=software, version=version, source=source, path=path, target=target)