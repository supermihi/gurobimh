# -*- coding: utf-8 -*-
# distutils: libraries = ['gurobi60']
# distutils: language = c++
# Copyright 2015 Michael Helmling
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation

from __future__ import division, print_function
cimport grb
from libcpp.string cimport string

from collections import Iterable
from cython.operator cimport dereference as deref
import numbers

cdef grb.GRBEnv *env = new grb.GRBEnv()

def read(fname):
    """Read model from file; *fname* may be bytes or unicode type."""
    cdef string cpp_fname
    cdef grb.GRBModel *model
    if type(fname) is bytes:
        cpp_fname = fname
    else:
        assert type(fname) is unicode
        cpp_fname = fname.encode('utf8')
    model = new grb.GRBModel(deref(env), cpp_fname)
    ret = Model(create=False)
    ret.model = model
    return ret

cpdef quicksum(iterable):
    """Create LinExpr consisting of the parts of *iterable*. Elements in the iterator must be either
    Var or LinExpr objects."""
    cdef LinExpr result
    cdef object part, it
    it = iter(iterable)
    try:
        result = LinExpr(next(it))
    except StopIteration:
        # empty iterable
        return LinExpr()
    for part in it:
        if type(part) is Var:
            result.expr += grb.GRBLinExpr((<Var>part).var)
        elif type(part) is LinExpr:
            result.expr += (<LinExpr>part).expr
        else:
            raise ValueError()
    return result


cdef class Callbackcls:
    cdef:
        readonly int MIPNODE
        readonly int MIPNODE_OBJBST

    def __init__(self):
        self.MIPNODE = grb.GRB_CB_MIPNODE
        self.MIPNODE_OBJBST = grb.GRB_CB_MIP_OBJBST

cdef class GRBcls:
    """Dummy class emulating gurobipy.GRB"""

    cdef:
        readonly char BINARY
        readonly char CONTINUOUS
        readonly char INTEGER
        readonly int MAXIMIZE, MINIMIZE, INFEASIBLE, OPTIMAL, INTERRUPTED, \
            INF_OR_UNBD, UNBOUNDED
        readonly char LESS_EQUAL, EQUAL, GREATER_EQUAL
        readonly object Callback, callback
    # workaround: INFINITY class member clashes with gcc macro INFINITY
    property INFINITY:
        def __get__(self):
            return grb.GRB.INFINITY

    def __init__(self):
        self.BINARY = grb.GRB_BINARY
        self.CONTINUOUS = grb.GRB_CONTINUOUS
        self.INTEGER = grb.GRB_INTEGER
        self.OPTIMAL = grb.GRB_OPTIMAL
        self.INF_OR_UNBD = grb.GRB_INF_OR_UNBD
        self.UNBOUNDED = grb.GRB_UNBOUNDED
        self.LESS_EQUAL = grb.GRB_LESS_EQUAL
        self.EQUAL = grb.GRB_EQUAL
        self.GREATER_EQUAL = grb.GRB_GREATER_EQUAL
        self.MAXIMIZE = grb.GRB_MAXIMIZE
        self.MINIMIZE = grb.GRB_MINIMIZE
        self.Callback = Callbackcls()
        self.callback = self.Callback


GRB = GRBcls()


class Gurobicls:

    def version(self):
        cdef int major, minor, tech
        grb.GRBversion(&major, &minor, &tech)
        return major, minor, tech


gurobi = Gurobicls()

cdef dict callbackFns = {}
cdef int callbackNr = 0

cdef int runCallback(nr, where) except +:
    model, fn = callbackFns[nr]
    fn(model, where)

cdef cppclass OMGCallback(grb.GRBCallback):
    int nr

    __init__(int nr):
        this.nr = nr

    void callback():
        runCallback(nr, where)

    double getDbl(int what):
        return getDoubleInfo(what)

cdef class Var:

    property obj:
        def __get__(self):
            return self.var.get(grb.GRB_DoubleAttr_Obj)

        def __set__(self, double obj):
            self.var.set(grb.GRB_DoubleAttr_Obj, obj)

    property lb:
        def __get__(self):
            return self.var.get(grb.GRB_DoubleAttr_LB)

        def __set__(self, double lb):
            self.var.set(grb.GRB_DoubleAttr_LB, lb)
    
    property ub:
        def __get__(self):
            return self.var.get(grb.GRB_DoubleAttr_UB)

        def __set__(self, double ub):
            self.var.set(grb.GRB_DoubleAttr_UB, ub)

    property X:
        def __get__(self):
            return self.var.get(grb.GRB_DoubleAttr_X)

    property VarName:
        def __get__(self):
            return self.var.get(grb.GRB_StringAttr_VarName)

    property Start:
        def __get__(self):
            return self.var.get(grb.GRB_DoubleAttr_Start)
        def __set__(self, double val):
            self.var.set(grb.GRB_DoubleAttr_Start, val)

    def __add__(self, other):
        return LinExpr(self) + other

    def __mul__(self, other):
        return LinExpr(self, other)

    def __str__(self):
        return 'Var(name={})'.format(self.VarName)


cdef class Constr:

    property slack:
        def __get__(self):
            return self.constr.get(grb.GRB_DoubleAttr_Slack)

    property ConstrName:
        def __get__(self):
            return self.constr.get(grb.GRB_StringAttr_ConstrName)


cdef class Model:

    def __cinit__(self, string name='', create=True):
        if create:
            self.model = new grb.GRBModel(deref(env))
            self.model.set(grb.GRB_StringAttr_ModelName, name)
        self.attrs = {}
        self._cbNr = -1
        self._cb = NULL

    def setParam(self, str param, value):
        if param == 'OutputFlag':
            self.model.getEnv().set(grb.GRB_IntParam_OutputFlag, <int>value)
        elif param == 'Threads':
            self.model.getEnv().set(grb.GRB_IntParam_Threads, <int>value)
        elif param == 'Method':
            self.model.getEnv().set(grb.GRB_IntParam_Method, <int>value)
        elif param == 'OptimalityTol':
            self.model.getEnv().set(grb.GRB_DoubleParam_OptimalityTol, <double>value)
        elif param == 'PrePasses':
            self.model.getEnv().set(grb.GRB_IntParam_PrePasses, <int>value)
        elif param == 'Presolve':
            self.model.getEnv().set(grb.GRB_IntParam_Presolve, <int>value)
        elif param == 'MIPFocus':
            self.model.getEnv().set(grb.GRB_IntParam_MIPFocus, <int>value)
        else:
            raise ValueError('Unsupported param: {}'.format(param))

    def __setattr__(self, key, value):
        self.attrs[key] = value

    def __getattr__(self, key):
        return self.attrs[key]

    cpdef addVar(self, double lb=0, double ub=grb.GRB_INFINITY, double obj=0.0,
               char vtype=GRB.CONTINUOUS, string name=''):
        cdef grb.GRBVar var = self.model.addVar(lb, ub, obj, vtype, name)
        ans = Var()
        ans.var = var
        return ans

    cpdef addConstr(self, lhs, char sense, rhs, string name=''):
        if type(lhs) is not LinExpr:
            lhs = LinExpr(lhs)
        if type(rhs) is not LinExpr:
            rhs = LinExpr(rhs)
        self.model.addConstr((<LinExpr>lhs).expr, sense, (<LinExpr>rhs).expr, name)

    cpdef setObjective(self, LinExpr expression, sense=None):
        cdef int cSense = 0
        if sense is not None:
            cSense = <int>sense
        self.model.setObjective(expression.expr, cSense)

    cpdef getVars(self):
        cdef grb.GRBVar *vars = self.model.getVars()
        cdef int num = self.numVars
        lst = []
        for i in range(num):
            v = Var()
            v.var = vars[i]
            lst.append(v)
        del vars
        return lst

    cpdef getConstrs(self):
        cdef grb.GRBConstr *constrs = self.model.getConstrs()
        cdef int num = self.numConstrs
        lst = []
        for i in range(num):
            c = Constr()
            c.constr = constrs[i]
            lst.append(c)
        del constrs
        return lst

    cpdef remove(self, Constr constr):
        self.model.remove(constr.constr)

    cpdef update(self):
        self.model.update()

    cpdef optimize(self, callback=None):
        cdef OMGCallback* cb
        if callback is not None:
            if self._cb != NULL:
                cb = <OMGCallback*>self._cb
                del cb
                del callbackFns[self._cbNr]
            global callbackNr
            nr = callbackNr
            callbackNr += 1
            cb = new OMGCallback(nr)
            self.model.setCallback(cb)
            self._cbNr = nr
            self._cb = cb
            callbackFns[nr] = (self, callback)
        self.model.optimize()

    cpdef terminate(self):
        self.model.terminate()

    def cbGet(self, int what):
        #print('getget')
        if what == grb.GRB_CB_MIP_OBJBST:
            return (<OMGCallback*>(self._cb)).getDbl(what)

    cpdef write(self, string filename):
        self.model.write(filename)

    property numConstrs:
        def __get__(self):
            return self.model.get(grb.GRB_IntAttr_NumConstrs)

    property Status:
        def __get__(self):
            return self.model.get(grb.GRB_IntAttr_Status)

    property ObjVal:
        def __get__(self):
            return self.model.get(grb.GRB_DoubleAttr_ObjVal)

    property numVars:
        def __get__(self):
            return self.model.get(grb.GRB_IntAttr_NumVars)

    property IterCount:
        def __get__(self):
            return self.model.get(grb.GRB_DoubleAttr_IterCount)

    property NodeCount:
        def __get__(self):
            return self.model.get(grb.GRB_DoubleAttr_NodeCount)

    def __dealloc__(self):
        cdef OMGCallback *cb
        if self._cb != NULL:
            cb = <OMGCallback*>(self._cb)
            del cb
            del callbackFns[self._cbNr]
        del self.model


cdef class LinExpr:
    def __cinit__(self, arg1=0.0, arg2=None, create=True):
        if not create:
            return
        if isinstance(arg2, Var):
            arg1, arg2 = arg2, arg1
        if isinstance(arg1, Var):
            if arg2 is None:
                self.expr = grb.GRBLinExpr((<Var>arg1).var)
            else:
                assert isinstance(arg2, numbers.Real)
                self.expr = grb.GRBLinExpr((<Var>arg1).var, <double>arg2)
        elif isinstance(arg1, numbers.Real):
            assert arg2 is None
            self.expr = grb.GRBLinExpr(<double>arg1)
        elif isinstance(arg1, LinExpr):
            self.expr = (<LinExpr>arg1).expr
        else:
            for i in range(len(arg1)):
                self.expr += grb.GRBLinExpr((<Var>arg2[i]).var, arg1[i])

    def __add__(LinExpr self, other):
        if not isinstance(other, LinExpr):
            other = LinExpr(other)
        cdef LinExpr ret = LinExpr(create=False)
        ret.expr = self.expr + (<LinExpr>other).expr
        return ret

    def __sub__(LinExpr self, other):
        if not isinstance(other, LinExpr):
            other = LinExpr(other)
        cdef LinExpr ret = LinExpr(create=False)
        ret.expr = self.expr - (<LinExpr>other).expr
        return ret

    def __str__(LinExpr self):
        parts = []
        size = self.expr.size()
        for i in range(size):
            parts.append('{}*{}'.format(self.expr.getCoeff(i), self.expr.getVar(i).get(
                grb.GRB_StringAttr_VarName)))
        return ' + '.join(parts)