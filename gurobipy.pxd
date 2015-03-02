cimport grb
from libcpp.string cimport string

cpdef quicksum(iterable)

cdef class Var:
    cdef grb.GRBVar var

cdef class Constr:
    cdef grb.GRBConstr constr

cdef class LinExpr:
    cdef grb.GRBLinExpr expr


cdef class Model:
    cdef grb.GRBModel *model
    cdef dict attrs
    cdef int _cbNr
    cdef void* _cb
    cpdef addVar(self, double lb=?, double ub=?, double obj=?, char vtype=?, string name=?)
    cpdef addConstr(self, lhs, char sense, rhs, string name=?)
    cpdef setObjective(self, LinExpr expression, sense=*)
    cpdef terminate(self)
    cpdef getVars(self)
    cpdef getConstrs(self)
    cpdef remove(self, Constr constr)
    cpdef update(self)
    cpdef optimize(self, callback=?)
    cpdef write(self, string filename)