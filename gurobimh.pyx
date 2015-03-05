# -*- coding: utf-8 -*-
# cython: profile=False
# cython: boundscheck=False
# cython: nonecheck=False
# Copyright 2015 Michael Helmling
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation

from __future__ import division, print_function
from numbers import Number
from cpython cimport array as c_array
from array import array


class GurobiError(Exception):
    pass


cdef GRBenv *masterEnv = NULL
_error = GRBloadenv(&masterEnv, NULL)
if _error:
    raise GurobiError('Loading Gurobi environment failed: error code {}'.format(_error))




def read(fname):
    """Read model from file; *fname* may be bytes or unicode type."""
    cdef int error
    cdef GRBmodel *cModel
    cdef Model model
    error = GRBreadmodel(masterEnv, _chars(fname), &cModel)
    if error:
        raise GurobiError('Unable to read model from file: {}'.format(error))
    model = Model(_create=False)
    model.model = cModel
    for i in range(model.NumVars):
        model._vars.append(Var(model, i))
    for i in range(model.NumConstrs):
        model._constrs.append(Constr(model, i))
    return model



cpdef quicksum(iterable):
    """Create LinExpr consisting of the parts of *iterable*. Elements in the iterator must be either
    Var or LinExpr objects."""
    cdef LinExpr result = LinExpr()
    for element in iterable:
        result += element
    return result


cdef class CallbackClass:
    """Singleton class for callback constants"""
    cdef:
        readonly int MIPNODE
        readonly int MIPNODE_OBJBST

    def __init__(self):
        self.MIPNODE = GRB_CB_MIPNODE
        self.MIPNODE_OBJBST = GRB_CB_MIPNODE_OBJBST
        CallbackTypes[self.MIPNODE] = int
        CallbackTypes[self.MIPNODE_OBJBST] = float


cdef class AttrConstClass:
    """Singleton class for attribute name constants"""
    cdef:
        readonly char* ModelSense
        readonly char* NumConstrs
        readonly char* NumVars
        readonly char* Status

        readonly char* IterCount
        readonly char* LB
        readonly char* UB
        readonly char* NodeCount
        readonly char* Obj
        readonly char* ObjCon
        readonly char* ObjVal
        readonly char* Start
        readonly char* X

        readonly char *ConstrName
        readonly char *VarName

    def __init__(self):
        self.ModelSense = IntAttrs[b'modelsense'] = GRB_INT_ATTR_MODELSENSE
        self.NumConstrs = IntAttrs[b'numconstrs'] = GRB_INT_ATTR_NUMCONSTRS
        self.NumVars = IntAttrs[b'numvars'] = GRB_INT_ATTR_NUMVARS
        self.Status = IntAttrs[b'status'] = GRB_INT_ATTR_STATUS

        self.IterCount = DblAttrs[b'itercount'] = GRB_DBL_ATTR_ITERCOUNT
        self.LB = DblAttrs[b'lb'] = GRB_DBL_ATTR_LB
        self.UB = DblAttrs[b'ub'] = GRB_DBL_ATTR_UB
        self.NodeCount = DblAttrs[b'nodecount'] = GRB_DBL_ATTR_NODECOUNT
        self.Obj = DblAttrs[b'obj'] = GRB_DBL_ATTR_OBJ
        self.ObjCon = DblAttrs[b'objcon'] = GRB_DBL_ATTR_OBJCON
        self.ObjVal = DblAttrs[b'objval'] = GRB_DBL_ATTR_OBJVAL
        self.Start = DblAttrs[b'start'] = GRB_DBL_ATTR_START
        self.X = DblAttrs[b'x'] = GRB_DBL_ATTR_X

        self.ConstrName = StrAttrs[b'constrname'] = GRB_STR_ATTR_CONSTRNAME
        self.VarName = StrAttrs[b'varname'] = GRB_STR_ATTR_VARNAME


cdef class ParamConstClass:
    """Singleton class for parameter name constants"""
    cdef:
        readonly char* Method
        readonly char* MIPFocus
        readonly char* Threads
        readonly char* OutputFlag
        readonly char* PrePasses
        readonly char* Presolve

    def __init__(self):
        self.Method = IntParams[b'method'] = GRB_INT_PAR_METHOD
        self.MIPFocus = IntParams[b'mipfocus'] = GRB_INT_PAR_MIPFOCUS
        self.Threads = IntParams[b'threads'] = GRB_INT_PAR_THREADS
        self.OutputFlag = IntParams[b'outputflag'] = GRB_INT_PAR_OUTPUTFLAG
        self.PrePasses = IntParams[b'prepasses'] = GRB_INT_PAR_PREPASSES
        self.Presolve = IntParams[b'presolve'] = GRB_INT_PAR_PRESOLVE



cdef dict IntAttrs = {}
cdef dict DblAttrs = {}
cdef dict StrAttrs = {}
cdef dict IntParams = {}
cdef dict DblParams = {}
cdef dict CallbackTypes = {}

cdef AttrConstClass cAttr = AttrConstClass()
cdef ParamConstClass cParam = ParamConstClass()


cdef class GRBcls:
    """Dummy class emulating gurobipy.GRB"""

    cdef:
        readonly char BINARY
        readonly char CONTINUOUS
        readonly char INTEGER
        readonly int MAXIMIZE, MINIMIZE, INFEASIBLE, OPTIMAL, INTERRUPTED, \
            INF_OR_UNBD, UNBOUNDED
        readonly char LESS_EQUAL, EQUAL, GREATER_EQUAL
        readonly object Callback, callback, Param, param, Attr, attr
    # workaround: INFINITY class member clashes with gcc macro INFINITY
    property INFINITY:
        def __get__(self):
            return GRB_INFINITY

    def __init__(self):
        self.BINARY = GRB_BINARY
        self.CONTINUOUS = GRB_CONTINUOUS
        self.INTEGER = GRB_INTEGER
        self.OPTIMAL = GRB_OPTIMAL
        self.INF_OR_UNBD = GRB_INF_OR_UNBD
        self.UNBOUNDED = GRB_UNBOUNDED
        self.LESS_EQUAL = GRB_LESS_EQUAL
        self.EQUAL = GRB_EQUAL
        self.GREATER_EQUAL = GRB_GREATER_EQUAL
        self.MAXIMIZE = GRB_MAXIMIZE
        self.MINIMIZE = GRB_MINIMIZE
        self.callback = self.Callback = CallbackClass()
        self.Param = self.param = cParam
        self.Attr = self.attr = cAttr


GRB = GRBcls()


class Gurobicls:
    """Emulate gurobipy.gorubi."""
    def version(self):
        cdef int major, minor, tech
        GRBversion(&major, &minor, &tech)
        return major, minor, tech


gurobi = Gurobicls()


cdef class VarOrConstr:
    """Super class vor Variables and Constants. Identified by their index and a pointer to the
    model object.
    """
    #TODO: model should be weak-referecned as in gurobipy

    def __cinit__(self, Model model, int index):
        self.model = model
        self.index = index

    def __getattr__(self, key):
        if self.index < 0:
            raise '{} not yet added to the model'.format(self.__class__.__name__)
        return self.model.getElementAttr(_chars(key).lower(), self.index)

    def __setattr__(self, key, value):
        if self.index < 0:
            raise '{} not yet added to the model'.format(self.__class__.__name__)
        self.model.setElementAttr(_chars(key).lower(), self.index, value)

    def __str__(self):
        ret = '<gurobimh.{} '.format(type(self).__name__)
        if self.index == -1:
            return ret + '*Awaiting Model Update*>'
        elif self.index == -2:
            return ret + '(Removed)>'
        elif self.index == -3:
            return ret +'*removed*>'
        else:
            return ret + '{}>'.format(self.VarName if isinstance(self, Var) else self.ConstrName)

    def __repr__(self):
        return str(self)


cdef class Var(VarOrConstr):

    def __add__(self, other):
        cdef LinExpr result = LinExpr(self)
        LinExpr.addInplace(result, other)
        return result

    def __mul__(self, other):
        return LinExpr(other, self)

    def __richcmp__(self, other, int op):
        if op == 2: # __eq__
            return TempConstr(LinExpr(self), GRB_EQUAL, other)
        elif op == 1: # __leq__
            return TempConstr(LinExpr(self), GRB_LESS_EQUAL, other)
        elif op == 5: # __geq__
            return TempConstr(LinExpr(self), GRB_GREATER_EQUAL, other)
        raise NotImplementedError()


cdef class Constr(VarOrConstr):
    pass



cdef char* _chars(s):
    """Convert input string to bytes, no matter if *s* is unicode or bytestring"""
    if isinstance(s, unicode):
        # encode to the specific encoding used inside of the module
        s = (<unicode>s).encode('utf8')
    return s


cdef int callbackFunction(GRBmodel *model, void *cbdata, int where, void *userdata):
    """Used for GRBsetcallbackfunc to emulate gurobipy's behaviour"""
    cdef Model theModel = <Model>userdata
    theModel.cbData = cbdata
    theModel.cbWhere = where
    try:
        theModel.callbackFn(theModel, where)
    except Exception as e:
        return GRB_ERROR_CALLBACK
    return 0


cdef class Model:

    def __init__(self, name='', _create=True):

        self.attrs = {}
        self._vars = []
        self._constrs = []
        self._varsAddedSinceUpdate = []
        self._varsRemovedSinceUpdate = []
        self._constrsAddedSinceUpdate = []
        self._constrsRemovedSinceUpdate = []
        self._varInds = array('i', [0]*25)
        self._varCoeffs = array('d', [0]*25)
        self.needUpdate = False
        self.callbackFn = None
        self._leDct = {}
        if _create:
            self.error = GRBnewmodel(masterEnv, &self.model, _chars(name),
                                     0, NULL, NULL, NULL, NULL, NULL)
            if self.error:
                raise GurobiError('Error creating model: {}'.format(self.error))

    def setParam(self, param, value):
        if isinstance(param, unicode):
            param = (<unicode>param).encode('utf8')
        param = param.lower()
        if param in DblParams:
            self.error = GRBsetdblparam(GRBgetenv(self.model), param, <double>value)
        elif param in IntParams:
            self.error = GRBsetintparam(GRBgetenv(self.model), param, <int>value)
        else:
            raise GurobiError('Parameter {} not implemented or unknown'.format(param))
        if self.error:
            raise GurobiError('Error setting parameter: {}'.format(self.error))


    def __setattr__(self, key, value):
        self.attrs[key] = value

    def __getattr__(self, key):
        cdef int intValue
        cdef double dblValue
        if isinstance(key, unicode):
            key = key.encode('utf8')
        if key.lower() in IntAttrs:
            self.error = GRBgetintattr(self.model, key.lower(), &intValue)
            if self.error:
                raise GurobiError('Error retrieving int attr {}: {}'.format(key, self.error))
            return intValue
        elif key.lower() in DblAttrs:
            self.error = GRBgetdblattr(self.model, key.lower(), &dblValue)
            if self.error:
                raise GurobiError('Error retrieving dbl attr: {}'.format(self.error))
            return dblValue
        return self.attrs[key]


    cdef getElementAttr(self, char * key, int element):
        cdef int intValue
        cdef double dblValue
        cdef char *strValue
        if key in StrAttrs:
            self.error = GRBgetstrattrelement(self.model, key, element, &strValue)
            if self.error:
                raise GurobiError('Error retrieving str attr: {}'.format(self.error))
            return str(strValue)
        elif key in DblAttrs:
            self.error = GRBgetdblattrelement(self.model, key, element, &dblValue)
            if self.error:
                raise GurobiError('Error retrieving dbl attr: {}'.format(self.error))
            return dblValue
        else:
            raise GurobiError("Unknown attribute '{}'".format(key))

    cdef int setElementAttr(self, char * key, int element, newValue) except -1:
        if key in StrAttrs:
            self.error = GRBsetstrattrelement(self.model, key, element, <const char*>newValue)
            if self.error:
                raise GurobiError('Error setting str attr: {}'.format(self.error))
        elif key in DblAttrs:
            self.error = GRBsetdblattrelement(self.model, key, element, <double>newValue)
            if self.error:
                raise GurobiError('Error setting double attr: {}'.format(self.error))
        else:
            raise GurobiError('Unknonw attribute {}'.format(key))

    cpdef addVar(self, double lb=0, double ub=GRB_INFINITY, double obj=0.0,
               char vtype=GRB_CONTINUOUS, name=''):
        cdef Var var
        if isinstance(name, unicode):
            name = name.encode('utf8')
        self.error = GRBaddvar(self.model, 0, NULL, NULL, obj, lb, ub, vtype, name)
        if self.error:
            raise GurobiError('Error creating variable: {}'.format(self.error))
        var = Var(self, -1)
        self._varsAddedSinceUpdate.append(var)
        self.needUpdate = True
        return var

    cdef int _compressLinExpr(self, LinExpr expr) except -1:
        """Compresses linear expressions by adding up coefficients of variables appearing more than
        once. The resulting compressed expression is stored in self.varInds / self.varCoeffs.
        :returns: Length of compressed expression
        """
        cdef int i, j, lenDct
        cdef double coeff
        cdef Var var
        cdef c_array.array[int] varInds
        cdef c_array.array[double] varCoeffs
        self._leDct.clear()
        for i in range(expr.length):
            var = <Var>expr.vars[i]
            if var.index < 0:
                raise GurobiError('Variable not in model')
            if var.index in self._leDct:
                self._leDct[var.index] += expr.coeffs.data.as_doubles[i]
            else:
                self._leDct[var.index] = expr.coeffs.data.as_doubles[i]
        lenDct = len(self._leDct)
        if len(self._varInds) < lenDct:
            c_array.resize(self._varInds, lenDct)
            c_array.resize(self._varCoeffs, lenDct)
        c_array.zero(self._varCoeffs)
        varInds = self._varInds
        varCoeffs = self._varCoeffs

        for i, (j, coeff) in enumerate(self._leDct.items()):
            varInds[i] = j
            varCoeffs[i] = coeff
        return lenDct

    cpdef addConstr(self, lhs, char sense=-1, rhs=None, name=''):
        cdef LinExpr expr
        cdef int lenDct
        cdef Constr constr
        if isinstance(lhs, TempConstr):
            expr = (<TempConstr>lhs).lhs - (<TempConstr>lhs).rhs
            sense = (<TempConstr>lhs).sense
        else:
            expr = LinExpr(lhs)
            LinExpr.subtractInplace(expr, rhs)
        lenDct = self._compressLinExpr(expr)
        self.error = GRBaddconstr(self.model, lenDct, self._varInds.data.as_ints,
                                  self._varCoeffs.data.as_doubles, sense,
                                  -expr.constant, _chars(name))
        if self.error:
            raise GurobiError('Error adding constraint: {}'.format(self.error))
        constr = Constr(self, -1)
        self._constrsAddedSinceUpdate.append(constr)
        self.needUpdate = True
        return constr

    cdef fastAddConstr(self, double[:] coeffs, list vars, char sense, double rhs, name=''):
        cdef int[:] varInds = self._varInds
        cdef int i
        cdef Constr constr
        if len(self._varInds) < coeffs.size:
            c_array.resize(self._varInds, coeffs.size)
            c_array.resize(self._varCoeffs, coeffs.size)
        for i in range(coeffs.size):
            varInds[i] = (<Var>vars[i]).index
        self.error = GRBaddconstr(self.model, coeffs.size, &varInds[0],
                                  &coeffs[0], sense, rhs, _chars(name))
        if self.error:
            raise GurobiError('Error adding constraint: {}'.format(self.error))
        constr = Constr(self, -1)
        self._constrsAddedSinceUpdate.append(constr)
        self.needUpdate = True
        return constr

    cpdef setObjective(self, expression, sense=None):
        cdef LinExpr expr = expression if isinstance(expression, LinExpr) else LinExpr(expression)
        cdef int i, error, length
        cdef Var var
        if sense is not None:
            self.error = GRBsetintattr(self.model, GRB_INT_ATTR_MODELSENSE, <int>sense)
            if self.error:
                raise GurobiError('Error setting objective sense: {}'.format(self.error))
        length = self._compressLinExpr(expr)
        for i in range(length):
            self.error = GRBsetdblattrelement(self.model, GRB_DBL_ATTR_OBJ,
                                              self._varInds.data.as_ints[i],
                                              self._varCoeffs.data.as_doubles[i])
            if self.error:
                raise GurobiError('Error setting objective coefficient: {}'.format(self.error))
        if expr.constant != 0:
            self.error = GRBsetdblattr(self.model, GRB_DBL_ATTR_OBJCON, expr.constant)
            if self.error:
                raise GurobiError('Error setting objective constant: {}'.format(self.error))
        self.needUpdate = True

    cpdef getVars(self):
        return self._vars[:]

    cpdef getConstrs(self):
        return self._constrs[:]

    cpdef remove(self, VarOrConstr what):
        if what.model is not self:
            raise GurobiError('Item to be removed not in model')
        if what.index >= 0:
            if isinstance(what, Constr):
                self.error = GRBdelconstrs(self.model, 1, &what.index)
                if self.error != 0:
                    raise GurobiError('Error removing constraint: {}'.format(self.error))
                self._constrsRemovedSinceUpdate.append(what.index)
            else:
                self.error = GRBdelvars(self.model, 1, &what.index)
                if self.error:
                    raise GurobiError('Error removing variable: {}'.format(self.error))
                self._varsRemovedSinceUpdate.append(what.index)
            what.index = -2
            self.needUpdate = True

    cpdef update(self):
        cdef int numVars = self.NumVars, numConstrs = self.NumConstrs, i
        cdef VarOrConstr voc
        if not self.needUpdate:
            return
        error = GRBupdatemodel(self.model)
        if error:
            raise GurobiError('Error updating the model: {}'.format(self.error))
        for i in sorted(self._varsRemovedSinceUpdate, reverse=True):
            voc = <Var>self._vars[i]
            voc.index = -3
            del self._vars[i]
            for voc in self._vars[i:]:
                voc.index -= 1
            numVars -= 1
        self._varsRemovedSinceUpdate = []
        for i in sorted(self._constrsRemovedSinceUpdate, reverse=True):
            voc = <Constr>self._constrs[i]
            voc.index = -3
            del self._constrs[i]
            for voc in self._constrs[i:]:
                voc.index -= 1
            numConstrs -= 1
        self._constrsRemovedSinceUpdate = []
        for i in range(len(self._varsAddedSinceUpdate)):
            voc = self._varsAddedSinceUpdate[i]
            voc.index = numVars + i
            self._vars.append(voc)
        self._varsAddedSinceUpdate = []
        for i in range(len(self._constrsAddedSinceUpdate)):
            voc = self._constrsAddedSinceUpdate[i]
            voc.index = numConstrs + i
            self._constrs.append(voc)
        self._constrsAddedSinceUpdate = []
        self.needUpdate = False

    cpdef optimize(self, callback=None):
        if callback is not None:
            self.error = GRBsetcallbackfunc(self.model, callbackFunction, <void*>self)
            if self.error:
                raise GurobiError('Error installing callback: {}'.format(self.error))
            self.callbackFn = callback
        self.update()
        self.error = GRBoptimize(self.model)
        self.callbackFn = None
        if self.error:
            raise GurobiError('Error optimizing model: {}'.format(self.error))

    cpdef cbGet(self, int what):
        cdef int intResult
        cdef double dblResult = 0
        if what not in CallbackTypes:
            raise GurobiError('Unknown callback "what" requested: {}'.format(what))
        elif CallbackTypes[what] is int:
            self.error = GRBcbget(self.model, self.cbWhere, what, <void*> &intResult)
            if self.error:
                raise GurobiError('Error calling cbget: {}'.format(self.error))
            return intResult
        elif CallbackTypes[what] is float:
            self.error = GRBcbget(self.cbData, self.cbWhere, what, <void*> &dblResult)
            if self.error:
                raise GurobiError('Error calling cbget: {}'.format(self.error))
            return dblResult
        else:
            raise GurobiError()

    cpdef terminate(self):
        GRBterminate(self.model)


    cpdef write(self, filename):
        if isinstance(filename, unicode):
            filename = filename.encode('utf8')
        self.error = GRBwrite(self.model, filename)
        if self.error:
            raise GurobiError('Error writing model: {}'.format(self.error))

    def __dealloc__(self):
        GRBfreemodel(self.model)


cdef c_array.array dblOne = array('d', [1])


cdef class LinExpr:

    def __init__(self, arg1=0.0, arg2=None):
        cdef int i
        if arg2 is None:
            if isinstance(arg1, Var):
                self.constant = 0
                self.vars =[arg1]
                self.coeffs = c_array.copy(dblOne)
                self.length = 1
                return
            elif isinstance(arg1, Number):
                self.constant = float(arg1)
                self.coeffs = c_array.clone(dblOne, 0, False)
                self.vars = []
                self.length = 0
                return
            elif isinstance(arg1, LinExpr):
                self.vars = (<LinExpr>arg1).vars[:]
                self.coeffs = c_array.copy((<LinExpr>arg1).coeffs)
                self.constant = (<LinExpr>arg1).constant
                self.length = len(self.coeffs)
                return
            else:
                arg1, arg2 = zip(*arg1)
        if isinstance(arg1, Var):
            self.vars = [arg1]
            self.coeffs = c_array.clone(dblOne, 1, False)
            self.coeffs.data.as_doubles[0] = arg2
            self.constant = 0
            self.length = 1
        else:
            self.length = len(arg1)
            self.coeffs = c_array.clone(dblOne, self.length, False)
            for i in range(self.length):
                self.coeffs.data.as_doubles[i] = arg1[i]
            self.vars = list(arg2)
            self.constant = 0

    @staticmethod
    cdef void addInplace(LinExpr first, other):
        cdef LinExpr _other
        if isinstance(other, LinExpr):
            _other = other
            first.vars += _other.vars
            c_array.extend(first.coeffs, _other.coeffs)
            first.constant += _other.constant
            first.length += _other.length
        elif isinstance(other, Var):
            first.vars.append(other)
            c_array.resize_smart(first.coeffs, len(first.coeffs) + 1)
            first.coeffs.data.as_doubles[len(first.coeffs)-1] = 1
            first.length += 1
        else:
            first.constant += <double>other

    @staticmethod
    cdef void subtractInplace(LinExpr first, other):
        cdef LinExpr _other
        cdef int origLen = len(first.coeffs)
        cdef int i
        if isinstance(other, LinExpr):
            _other = other
            first.vars += _other.vars
            c_array.extend(first.coeffs, _other.coeffs)
            for i in range(origLen, len(first.coeffs)):
                first.coeffs.data.as_doubles[i] *= -1
            first.constant -= _other.constant
            first.length += _other.length
        elif isinstance(other, Var):
            first.vars.append(other)
            c_array.resize_smart(first.coeffs, len(first.coeffs) + 1)
            first.coeffs.data.as_doubles[len(first.coeffs) - 1] = -1
            first.length += 1
        else:
            first.constant -= <double>other

    cdef LinExpr _copy(LinExpr self):
        cdef LinExpr result = LinExpr(self.constant)
        result.vars = self.vars[:]
        result.coeffs = c_array.copy(self.coeffs)
        result.length = self.length
        return result

    def __add__(LinExpr self, other):
        cdef LinExpr result = self._copy()
        LinExpr.addInplace(result, other)
        return result

    def __sub__(LinExpr self, other):
        cdef LinExpr result = self._copy()
        LinExpr.subtractInplace(result, other)
        return result

    def __isub__(LinExpr self, other):
        LinExpr.subtractInplace(self, other)
        return self

    def __iadd__(LinExpr self, other):
        LinExpr.addInplace(self, other)
        return self

    def __richcmp__(self, other, int op):
        if op == 2: # __eq__
            return TempConstr(self, GRB_EQUAL, other)
        elif op == 1: # __leq__
            return TempConstr(self, GRB_LESS_EQUAL, other)
        elif op == 5: # __geq__
            return TempConstr(self, GRB_GREATER_EQUAL, other)
        raise NotImplementedError()

    def __repr__(self):
        return ' + '.join('{}*{}'.format(c, v) for c, v in zip(self.coeffs, self.vars)) + ' + {}'.format(self.constant)

cdef class TempConstr:

    def __init__(self, lhs, char sense, rhs):
        self.lhs = lhs if isinstance(lhs, LinExpr) else LinExpr(lhs)
        self.rhs = rhs if isinstance(rhs, LinExpr) else LinExpr(rhs)
        self.sense = sense