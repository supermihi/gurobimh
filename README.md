gurobimh: Unofficial Alternative Gurobi/Python Interface
========================================================

Overview
--------
`gurobimh` is a drop-in replacement for the `gurobipy` API bindings shipped with
[Gurobi](www.gurobi.com). It offers several advantages:

* `gurobimh` can be compiled for all current versions of Python (in particular, Python 3.4); you do not need
  to rely on Gurobi officially supporting your desired Python version.
* `gurobimh`'s performance is much better, especially when modifying models a lot (like in a hand-written
  branch and bound solver).
* `gurobimh` is free software an can be easily extended
* `gurobimh` ships Cython `pxd` file which allows you to write statically typed Cython programs
  for virtally C performance.
  
Of course, there are also disatvantages:
* Up to now, `gurobimh` supports only a subset of the official `gurobipy` API, in particular
  quadratic programming is not yet supported. However these features are easy to implement once you 
  look at how the others are, so you are welcome to contribute. I simply do not use these features
  so I did not bother implementing them.
* Though I have successfully verified that `gurobimh` behaves like `gurobipy` for my programs,
  there are probably lots of bugs, and of course there's no commercial support.

Requirements
------------
The API is written in [Python](www.python.org). To compile it, you need [Cython](www.cython.org). Of
course, you need to have Gurobi installed, and the `GUROBI_HOME` environment variable needs to be
set correctly.

Installation
------------

Download the package and type:

    python setup.py install --user


In both commands, replace ``python`` by an appropriate call to your Python interpreter.

Contact
-------
Please contact [me](helmling@uni-koblenz.de) or use the GitHub features for comments, bugs etc.