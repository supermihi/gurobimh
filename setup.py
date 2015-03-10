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

# if '--cython' in sys.argv:
#     from Cython.Build import cythonize
#     extensions = cythonize(['gurobimh.pyx'])
#     sys.argv.remove('--cython')
# else:
#     from distutils.extension import Extension
#     extensions = [Extension('gurobimh', ['gurobimh.c'],)]
from Cython.Build import cythonize
directives = {}
if '--profile' in sys.argv:
        directives['profile'] = True
        sys.argv.remove('--profile')
extensions = cythonize(['gurobimh.pyx'], compiler_directives=directives)
extensions[0].include_dirs = [join(GHOME, 'include')]
extensions[0].library_dirs = [join(GHOME, 'lib')]
extensions[0].libraries = ['gurobi60']


def readme():
    readmeFile = os.path.join(os.path.dirname(__file__), 'README.md')
    if sys.version_info[0] >= 3:
        return open(readmeFile, 'rt', encoding='utf8').read()
    else:
        import io
        return io.open(readmeFile, 'rt', encoding='utf8').read()

setup(
    name='gurobimh',
    version='0.3',
    url='https://github.com/supermihi/gurobimh',
    classifiers=[
      'Development Status :: 3 - Alpha',
      'Intended Audience :: Science/Research',
      'License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)',
      'Operating System :: OS Independent',
      'Programming Language :: Python :: 2.7',
      'Programming Language :: Python :: 3',
      'Topic :: Scientific/Engineering :: Mathematics',
    ],
    description='alternative python interface for the Gurobi optimization software',
    long_description=readme(),
    author='Michael Helmling',
    author_email='helmling@uni-koblenz.de',
    license='GPL3',
    ext_modules=extensions,
    include_package_data=True,
)
