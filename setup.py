# -*- coding: utf-8 -*-
# Copyright 2015 Michael Helmling
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation


import sys, os, io
import re
from os.path import dirname, abspath, join
from setuptools import setup
from Cython.Build import cythonize

here = abspath(dirname(__file__))
try:
    GHOME = os.environ['GUROBI_HOME']
except KeyError:
    raise RuntimeError('GUROBI_HOME not set')

directives = {}
if '--profile' in sys.argv:
    directives['profile'] = True
    sys.argv.remove('--profile')
extensions = cythonize(['gurobimh.pyx'], compiler_directives=directives)
extensions[0].include_dirs = [join(GHOME, 'include')]
extensions[0].library_dirs = [join(GHOME, 'lib')]
# find library version: library name includes major/minor version information (e.g.
# libgurobi65.so vs libgurobi60.so). This hack-ish solution parses version information from
# the C header file.
with open(join(GHOME, 'include', 'gurobi_c.h'), 'rt') as f:
    gurobi_c_h = f.read()
major = re.findall('define GRB_VERSION_MAJOR\s+([0-9]+)', gurobi_c_h)[0]
minor = re.findall('define GRB_VERSION_MINOR\s+([0-9]+)', gurobi_c_h)[0]
extensions[0].libraries = ['gurobi' + major + minor]

# read current gurobimh version from gurobimh.pyx file
with io.open('gurobimh.pyx', 'rt', encoding='UTF-8') as f:
    version_match = re.search(r"^__version__ = ['\"]([^'\"]*)['\"]", f.read(), re.M)
    version = version_match.group(1)


def readme():
    return io.open('README.md', 'rt', encoding='utf8').read()


setup(
    name='gurobimh',
    version=version,
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
    test_suite='tests',
    install_requires=['Cython'],
    data_files=[('', ['gurobimh.pxd'])],
)
