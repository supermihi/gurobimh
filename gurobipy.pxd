cimport grb


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
    cdef grb.GRBmodel *model
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
    cpdef remove(self, Constr constr)
    cpdef update(self)
    cpdef optimize(self, callback=?)
    cpdef write(self, filename)