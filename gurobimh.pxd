cpdef quicksum(iterable)


cdef class VarOrConstr:
    cdef int index
    cdef Model model


cdef class Var(VarOrConstr):
    pass


cdef class Constr(VarOrConstr):
    pass


cdef class LinExpr:
    cdef list _vars
    cdef list _coeffs
    cdef double _constant


cdef class Model:
    cdef GRBmodel *model
    cdef dict attrs
    cdef list _vars
    cdef list _constrs
    cdef list _varsAddedSinceUpdate
    cdef list _varsRemovedSinceUpdate
    cdef list _constrsAddedSinceUpdate
    cdef list _constrsRemovedSinceUpdate
    cdef _getElementAttr(self, key, int element)
    cpdef addVar(self, double lb=?, double ub=?, double obj=?, char vtype=?, name=?)
    cpdef addConstr(self, lhs, char sense, rhs, name=?)
    cpdef setObjective(self, expression, sense=*)
    cpdef terminate(self)
    cpdef getVars(self)
    cpdef getConstrs(self)
    cpdef remove(self, VarOrConstr what)
    cpdef update(self)
    cpdef optimize(self, callback=?)
    cpdef write(self, filename)


cdef extern from 'gurobi_c.h':
    ctypedef struct GRBenv:
        pass
    ctypedef struct GRBmodel:
        pass
    const char GRB_BINARY, GRB_CONTINUOUS, GRB_INTEGER
    const char GRB_EQUAL, GRB_LESS_EQUAL, GRB_GREATER_EQUAL

    const char *GRB_INT_ATTR_MODELSENSE
    const char *GRB_INT_ATTR_NUMCONSTRS
    const char *GRB_INT_ATTR_NUMVARS
    const char *GRB_INT_ATTR_STATUS

    const char *GRB_DBL_ATTR_ITERCOUNT
    const char *GRB_DBL_ATTR_SLACK
    const char *GRB_DBL_ATTR_LB
    const char *GRB_DBL_ATTR_UB
    const char *GRB_DBL_ATTR_OBJ
    const char *GRB_DBL_ATTR_X
    const char *GRB_DBL_ATTR_OBJVAL
    const char *GRB_DBL_ATTR_OBJCON

    const char *GRB_STR_ATTR_CONSTRNAME
    const char *GRB_STR_ATTR_VARNAME

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
    GRBenv* GRBgetenv(GRBmodel *)
    int GRBloadenv(GRBenv **envP, const char *logfilename)
    int GRBnewmodel (GRBenv *, GRBmodel **modelP, const char *Pname, int numvars, double *obj,
                     double *lb, double *ub, char *vtype, const char **varnames )
    int GRBresetmodel (GRBmodel *)
    int GRBfreemodel (GRBmodel *)
    int GRBaddvar (GRBmodel *, int numnz, int *vind, double *vval, double obj, double lb,
                   double ub, char vtype, const char *varname )
    int GRBsetintattr (GRBmodel *, const char *attrname, int newvalue)
    int GRBgetintattr (GRBmodel *, const char *attrname, int *valueP)
    int GRBgetdblattr (GRBmodel *, const char *attrname, double *valueP)
    int GRBsetdblattr (GRBmodel *, const char *attrname, double newvalue)
    int GRBsetdblattrelement (GRBmodel *, const char *attrname, int element, double newvalue)
    int GRBgetdblattrelement (GRBmodel *, const char *attrname, int element, double *valueP)
    int GRBgetintattrelement (GRBmodel *, const char *attrname, int element, int *valueP)
    int GRBgetintattrelement (GRBmodel *, const char *attrname, int element, int *valueP)
    int GRBgetstrattrelement (GRBmodel *, const char *attrname, int element, char **valueP)
    int GRBsetdblattrarray (GRBmodel *, const char *attrname, int start, int len, double *values)
    int GRBgetdblattrarray (GRBmodel *, const char *attrname, int start, int len, double *values)
    int GRBsetintparam (GRBenv *, const char *paramname, int newvalue)
    int GRBsetdblparam (GRBenv *, const char *paramname, double newvalue)
    int GRBupdatemodel (GRBmodel *)
    int GRBaddconstr (GRBmodel *, int numnz, int *cind, double *cval, char sense, double rhs, const char *constrname)
    int GRBdelconstrs (GRBmodel *, int numdel, int *ind)
    int GRBdelvars (GRBmodel *, int numdel, int *ind)
    int GRBoptimize (GRBmodel *)
    void GRBterminate (GRBmodel *)
    int GRBwrite(GRBmodel *, const char *filename)