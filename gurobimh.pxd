from cpython cimport array
DEF ERRORCODE = -987654321

cpdef quicksum(iterable)


cdef class VarOrConstr:
    cdef int index
    cdef Model model
    cdef dict attrs  # user attributes

cdef class Var(VarOrConstr):
    pass


cdef class Constr(VarOrConstr):
    pass


cdef class Column:
    cdef int numnz
    cdef array.array coeffs
    cdef list constrs


cdef class LinExpr:
    cdef int length
    cdef list vars
    cdef array.array coeffs
    cdef double constant
    cpdef int size(LinExpr self)
    cpdef double getCoeff(LinExpr self, int i)
    cpdef Var getVar(LinExpr self, int i)
    cpdef double getConstant(LinExpr self)
    cpdef double getValue(LinExpr self)
    cdef LinExpr copy(self)
    @staticmethod
    cdef int addInplace(LinExpr first, other) except -1
    @staticmethod
    cdef int subtractInplace(LinExpr first, other) except -1
    @staticmethod
    cdef int multiplyInplace(LinExpr expr, double scalar) except -1

cdef class Model:
    cdef GRBmodel *model
    cdef int error
    cdef dict attrs  # user attributes
    cdef list vars, varsAddedSinceUpdate, varsRemovedSinceUpdate
    cdef list constrs,  constrsAddedSinceUpdate, constrsRemovedSinceUpdate
    cdef bint needUpdate
    cdef array.array varInds, varCoeffs
    cdef dict linExpDct
    # callback handling
    cdef object callbackFn
    cdef void *cbData
    cdef int cbWhere
    cdef bint cbInterrupt
    # internal helpers
    cdef int compressLinExpr(self, LinExpr expr) except -1


    # =======================
    # public Cython interface
    # =======================
    #
    # attribute handling
    cdef getElementAttr(self, char* key, int element)
    cdef char* getStrAttr(self, char *attrname)
    cdef int getIntAttr(self, char *attr) except ERRORCODE
    cdef double getDblAttr(self, char *attr) except ERRORCODE
    cdef double getElementDblAttr(self, char *attr, int element) except ERRORCODE
    cdef int setElementDblAttr(self, char *attr, int element, double value) except -1
    cdef int setElementAttr(self, char* key, int element, value) except -1
    cdef int fastGetX(self, int start, int length, double[::1] values) except -1
    # model modification
    cdef fastSetObjective(self, int start, int len, double[::1] coeffs)
    cdef Constr fastAddConstr(self, double[::1] coeffs, list vars, char sense, double rhs, name=?)
    cdef Constr fastAddConstr2(self, double[::1] coeffs, int[::1] varIndices, char sense, double rhs, name=?)

    # =======================
    # public Python interface
    # =======================
    cpdef getAttr(self, char* attrname, objs=?)
    cpdef addVar(self, double lb=?, double ub=?, double obj=?, char vtype=?, name=?, column=?)
    cpdef addRange(self, LinExpr expr, double lower, double upper, name=?)
    cpdef addConstr(self, lhs, basestring sense=?, rhs=?, name=?)
    cpdef setObjective(self, expression, sense=*)
    cpdef setPWLObj(self, Var var, x, y)
    cpdef LinExpr getObjective(self)
    cpdef terminate(self)
    cpdef getVars(self)
    cpdef getConstrs(self)
    cpdef getVarByName(self, name)
    cpdef getConstrByName(self, name)
    cpdef remove(self, VarOrConstr what)
    cpdef reset(self)
    cpdef update(self)
    cpdef optimize(self, callback=?)
    cpdef cbGet(self, int what)
    cpdef write(self, filename)

cdef class TempConstr:
    cdef LinExpr rhs, lhs
    cdef char sense

cdef extern from 'gurobi_c.h':
    ctypedef struct GRBenv:
        pass
    ctypedef struct GRBmodel:
        pass
    const char GRB_BINARY, GRB_CONTINUOUS, GRB_INTEGER, GRB_SEMICONT, GRB_SEMIINT
    const char GRB_EQUAL, GRB_LESS_EQUAL, GRB_GREATER_EQUAL
    # objective sense
    const int GRB_MAXIMIZE, GRB_MINIMIZE
    # status codes
    const int GRB_INFEASIBLE, GRB_OPTIMAL, GRB_INTERRUPTED, GRB_ITERATION_LIMIT, GRB_INF_OR_UNBD,\
        GRB_UNBOUNDED, GRB_LOADED, GRB_CUTOFF, GRB_TIME_LIMIT, GRB_SOLUTION_LIMIT, GRB_NUMERIC,\
        GRB_SUBOPTIMAL, GRB_INPROGRESS
    const double GRB_INFINITY
    # callback "where"'s
    const int GRB_CB_POLLING, GRB_CB_PRESOLVE, GRB_CB_SIMPLEX, GRB_CB_MIP, GRB_CB_MIPSOL, \
        GRB_CB_MIPNODE, GRB_CB_MESSAGE, GRB_CB_BARRIER
    # callback "what"'s
    const int GRB_CB_MIPNODE_OBJBST
    const int GRB_CB_SPX_OBJVAL

    # Error codes
    const int GRB_ERROR_CALLBACK

    void GRBversion (int *majorP, int *minorP, int *technicalP)
    char *GRBplatform()
    GRBenv *GRBgetenv(GRBmodel *)
    char *GRBgeterrormsg(GRBenv *env)
    int GRBloadenv(GRBenv **envP, const char *logfilename)
    int GRBnewmodel (GRBenv *, GRBmodel **modelP, const char *Pname, int numvars, double *obj,
                     double *lb, double *ub, char *vtype, const char **varnames )
    int GRBreadmodel(GRBenv*, const char* filename, GRBmodel **modelP)
    int GRBresetmodel (GRBmodel *)
    int GRBfreemodel (GRBmodel *)
    int GRBaddvar (GRBmodel *, int numnz, int *vind, double *vval, double obj, double lb,
                   double ub, char vtype, const char *varname )
    int GRBsetintattr (GRBmodel *, const char *attrname, int newvalue)
    int GRBgetintattr (GRBmodel *, const char *attrname, int *valueP)
    int GRBgetdblattr (GRBmodel *, const char *attrname, double *valueP)
    int GRBsetdblattr (GRBmodel *, const char *attrname, double newvalue)
    int GRBgetstrattr (GRBmodel *, const char *attrname, char **valueP)
    int GRBsetstrattr (GRBmodel *, const char *attrname, const char *newvalue)
    int GRBsetdblattrelement (GRBmodel *, const char *attrname, int element, double newvalue)
    int GRBgetdblattrelement (GRBmodel *, const char *attrname, int element, double *valueP)
    int GRBgetintattrelement (GRBmodel *, const char *attrname, int element, int *valueP)
    int GRBgetstrattrelement (GRBmodel *, const char *attrname, int element, char **valueP)
    int GRBsetstrattrelement (GRBmodel *, const char *attrname, int element, char *value)
    int GRBsetcharattrelement (GRBmodel *, const char * attrname, int element, char value)
    int GRBsetdblattrarray (GRBmodel *, const char *attrname, int start, int len, double *values)
    int GRBgetdblattrarray (GRBmodel *, const char *attrname, int start, int len, double *values)
    int GRBsetintparam (GRBenv *, const char *paramname, int newvalue)
    int GRBsetdblparam (GRBenv *, const char *paramname, double newvalue)
    int GRBupdatemodel (GRBmodel *)
    int GRBaddrangeconstr (GRBmodel *, int numnz, int *cind, double *cval, double lower, double upper, const char *constrname)
    int GRBaddconstr (GRBmodel *, int numnz, int *cind, double *cval, char sense, double rhs, const char *constrname)
    int GRBdelconstrs (GRBmodel *, int numdel, int *ind)
    int GRBgetvarbyname (GRBmodel *, const char *name, int *varnumP)
    int GRBgetconstrbyname (GRBmodel *, const char *name, int *constrnumP)
    int GRBchgcoeffs (GRBmodel *, int numchgs, int *cind, int *vind, double *val)
    int GRBdelvars (GRBmodel *, int numdel, int *ind)
    int GRBoptimize (GRBmodel *)
    int GRBsetcallbackfunc (GRBmodel *, int	(*cb)(GRBmodel *model, void *cbdata, int where, void *usrdata),
  	  	void *usrdata)
    int GRBcbget(void *cbdata, int where, int what, void *resultP)
    void GRBterminate (GRBmodel *)
    int GRBwrite(GRBmodel *, const char *filename)
    int GRBsetpwlobj (GRBmodel *model, int var, int npoints, double *x, double *y)
