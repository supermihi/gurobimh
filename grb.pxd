# -*- coding: utf-8 -*-
# distutils: include_dirs = /opt/gurobi600/linux64/include
# distutils: libraries = ['gurobi60', 'gurobi_c++']
# Copyright 2015 Michael Helmling
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation

"""cdef headers for talking to the Gurobi C library through Cython."""



cdef extern from 'gurobi_c.h':
    ctypedef struct GRBenv:
        pass
    ctypedef struct GRBmodel:
        pass
    const char GRB_BINARY, GRB_CONTINUOUS, GRB_INTEGER
    const char GRB_EQUAL, GRB_LESS_EQUAL, GRB_GREATER_EQUAL
    const char *GRB_INT_ATTR_MODELSENSE
    const char *GRB_DBL_ATTR_OBJ
    const char *GRB_DBL_ATTR_X
    const char *GRB_DBL_ATTR_OBJVAL
    const char *GRB_DBL_ATTR_OBJCON
    const char *GRB_INT_PAR_OUTPUTFLAG
    const char *GRB_INT_ATTR_NUMCONSTRS
    const char *GRB_INT_ATTR_NUMVARS
    const char *GRB_INT_ATTR_STATUS
    const char *GRB_DBL_ATTR_ITERCOUNT
    const char *GRB_DBL_ATTR_SLACK
    const char *GRB_DBL_ATTR_LB
    const char *GRB_DBL_ATTR_UB
    const char *GRB_STR_ATTR_CONSTRNAME
    const char *GRB_INT_PAR_METHOD
    const char *GRB_INT_PAR_THREADS
    const char *GRB_INT_PAR_OUTPUTFLAG
    const int GRB_MAXIMIZE, GRB_MINIMIZE, GRB_INFEASIBLE, GRB_OPTIMAL, GRB_INTERRUPTED, \
        GRB_INF_OR_UNBD, GRB_UNBOUNDED
    const double GRB_INFINITY
    const int GRB_CB_POLLING, GRB_CB_PRESOLVE, GRB_CB_SIMPLEX, GRB_CB_MIP, GRB_CB_MIPSOL, \
        GRB_CB_MIPNODE, GRB_CB_MESSAGE, GRB_CB_BARRIER
    const int GRB_CB_MIP_OBJBST
    void GRBversion (int *majorP, int *minorP, int *technicalP)
    GRBenv* GRBgetenv(GRBmodel *model)
    int GRBloadenv(GRBenv **envP, const char *logfilename)
    int GRBnewmodel (GRBenv *env, GRBmodel **modelP, const char *Pname, int numvars, double *obj,
                     double *lb, double *ub, char *vtype, const char **varnames )
    int GRBresetmodel (GRBmodel *model)
    int GRBfreemodel (GRBmodel *model)
    int GRBaddvar (GRBmodel *model, int numnz, int *vind, double *vval, double obj, double lb,
                   double ub, char vtype, const char *varname )
    int GRBsetintattr (GRBmodel *model, const char *attrname, int newvalue)
    int GRBgetintattr (GRBmodel *model, const char *attrname, int *valueP)
    int GRBgetdblattr (GRBmodel *model, const char *attrname, double *valueP)
    int GRBsetdblattr (GRBmodel *model, const char *attrname, double newvalue)
    int GRBsetdblattrelement (GRBmodel *model, const char *attrname, int element, double newvalue)
    int GRBgetdblattrelement (GRBmodel *model, const char *attrname, int element, double *valueP)
    int GRBgetintattrelement (GRBmodel *model, const char *attrname, int element, int *valueP)
    int GRBgetintattrelement (GRBmodel *model, const char *attrname, int element, int *valueP)
    int GRBgetstrattrelement (GRBmodel *model, const char *attrname, int element, char **valueP)
    int GRBsetdblattrarray (GRBmodel *model, const char *attrname, int start, int len, double *values)
    int GRBgetdblattrarray (GRBmodel *model, const char *attrname, int start, int len, double *values)
    int GRBsetintparam (GRBenv *env, const char *paramname, int newvalue)
    int GRBsetdblparam (GRBenv *env, const char *paramname, double newvalue)
    int GRBupdatemodel (GRBmodel *model)
    int GRBaddconstr (GRBmodel *model, int numnz, int *cind, double *cval, char sense, double rhs, const char *constrname)
    int GRBdelconstrs (GRBmodel *model, int numdel, int *ind)
    int GRBoptimize (GRBmodel *model)
    void GRBterminate (GRBmodel *)
    int GRBwrite(GRBmodel *model, const char *filename)