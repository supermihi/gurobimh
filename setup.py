#!/usr/bin/python2
# -*- coding: utf-8 -*-
# Copyright 2015 Michael Helmling
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation


import sys
import os
from os.path import dirname, abspath, join
from setuptools import setup


here = abspath(dirname(__file__))
try:
    GHOME = os.environ['GUROBI_HOME']
except KeyError:
    raise RuntimeError('GUROBI_HOME not set')

if '--cython' in sys.argv:
    from Cython.Build import cythonize
    extensions = cythonize(['gurobipy.pyx'])
    sys.argv.remove('--cython')
else:
    from distutils.extension import Extension
    extensions = [Extension('gurobipy', ['gurobipy.c'],)]
extensions[0].include_dirs = [join(GHOME, 'include')]
extensions[0].library_dirs = [join(GHOME, 'lib')]
extensions[0].libraries = ['gurobi60']
setup(
    name='gurobipy',
    version='0.2',
    author='Michael Helmling',
    author_email='helmling@uni-koblenz.de',
    license='GPL3',
    ext_modules=extensions,
    include_package_data=True,
)
