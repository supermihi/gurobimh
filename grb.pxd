# -*- coding: utf-8 -*-
# distutils: include_dirs = /opt/gurobi600/linux64/include
# distutils: libraries = ['gurobi60', 'gurobi_c++']
# Copyright 2015 Michael Helmling
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation

"""cdef headers for talking to the Gurobi C library through Cython."""

from libcpp.string cimport string

cdef extern from 'gurobi_c++.h':

    cppclass GRBEnv:
        GRBEnv() except +
        void set(GRB_IntParam, int) except +
        void set(GRB_DoubleParam, double) except +

    cppclass GRBVar:
        double get(GRB_DoubleAttr)
        string get(GRB_StringAttr)
        void set(GRB_DoubleAttr attr, double val)

    cppclass GRBModel:
        GRBModel(GRBEnv &env) except +
        GRBModel(GRBEnv &env, const string &filename) except +
        void set(GRB_StringAttr	attr, string newvalue) except +
        void set(GRB_DoubleAttr	attr, double newvalue) except +
        void set(GRB_IntAttr	attr, int newvalue) except +
        int get(GRB_IntAttr)
        string get(GRB_StringAttr)
        double get(GRB_DoubleAttr)
        GRBVar addVar(double lb, double ub, double obj, char type, string name) except +
        GRBEnv getEnv()
        GRBConstr addConstr(const GRBLinExpr &lhsExpr, char sense, const GRBLinExpr &rhsExpr,
                            string name) except +
        GRBConstr *getConstrs()
        void setCallback(GRBCallback *)
        void setObjective (GRBLinExpr linexpr, int sense)
        GRBVar *getVars()
        void remove(GRBConstr constr)
        void update()
        void terminate()
        void optimize() except +
        void write(const string&)

    cppclass GRBConstr:
        int get(GRB_IntAttr)
        double get(GRB_DoubleAttr attr)
        string get(GRB_StringAttr attr)

    cppclass GRBLinExpr:
        GRBLinExpr()
        GRBLinExpr(double constant)
        GRBLinExpr(GRBVar var)
        GRBLinExpr(GRBVar var, double coeff)
        GRBLinExpr operator+(GRBLinExpr other)
        GRBLinExpr operator-(GRBLinExpr other)
        unsigned size()
        double getCoeff(int)
        GRBVar getVar(int)

    cppclass GRBCallback:
        GRBCallback()
        void abort()
        double getDoubleInfo(int what)
        int where

    enum GRB_StringAttr:
        GRB_StringAttr_ModelName,
        GRB_StringAttr_VarName,
        GRB_StringAttr_ConstrName,
        GRB_StringAttr_QCName

    enum GRB_DoubleAttr:
        GRB_DoubleAttr_Runtime
        GRB_DoubleAttr_ObjCon
        GRB_DoubleAttr_LB
        GRB_DoubleAttr_UB
        GRB_DoubleAttr_Obj
        GRB_DoubleAttr_Start
        GRB_DoubleAttr_RHS
        GRB_DoubleAttr_QCRHS
        GRB_DoubleAttr_MaxCoeff
        GRB_DoubleAttr_MinCoeff
        GRB_DoubleAttr_MaxBound
        GRB_DoubleAttr_MinBound
        GRB_DoubleAttr_MaxObjCoeff
        GRB_DoubleAttr_MinObjCoeff
        GRB_DoubleAttr_MaxRHS
        GRB_DoubleAttr_MinRHS
        GRB_DoubleAttr_ObjVal
        GRB_DoubleAttr_ObjBound
        GRB_DoubleAttr_MIPGap
        GRB_DoubleAttr_IterCount
        GRB_DoubleAttr_NodeCount
        GRB_DoubleAttr_X
        GRB_DoubleAttr_RC
        GRB_DoubleAttr_Pi
        GRB_DoubleAttr_QCPi
        GRB_DoubleAttr_Slack
        GRB_DoubleAttr_QCSlack
        GRB_DoubleAttr_BoundVio
        GRB_DoubleAttr_BoundSVio
        GRB_DoubleAttr_BoundVioSum
        GRB_DoubleAttr_BoundSVioSum
        GRB_DoubleAttr_ConstrVio
        GRB_DoubleAttr_ConstrSVio
        GRB_DoubleAttr_ConstrVioSum
        GRB_DoubleAttr_ConstrSVioSum
        GRB_DoubleAttr_ConstrResidual
        GRB_DoubleAttr_ConstrSResidual
        GRB_DoubleAttr_ConstrResidualSum
        GRB_DoubleAttr_ConstrSResidualSum
        GRB_DoubleAttr_DualVio
        GRB_DoubleAttr_DualSVio
        GRB_DoubleAttr_DualVioSum
        GRB_DoubleAttr_DualSVioSum
        GRB_DoubleAttr_DualResidual
        GRB_DoubleAttr_DualSResidual
        GRB_DoubleAttr_DualResidualSum
        GRB_DoubleAttr_DualSResidualSum
        GRB_DoubleAttr_ComplVio
        GRB_DoubleAttr_ComplVioSum
        GRB_DoubleAttr_IntVio
        GRB_DoubleAttr_IntVioSum
        GRB_DoubleAttr_Kappa
        GRB_DoubleAttr_KappaExact
        GRB_DoubleAttr_SAObjLow
        GRB_DoubleAttr_SAObjUp
        GRB_DoubleAttr_SALBLow
        GRB_DoubleAttr_SALBUp
        GRB_DoubleAttr_SARHSLow
        GRB_DoubleAttr_SAUBLow
        GRB_DoubleAttr_SAUBUp
        GRB_DoubleAttr_SARHSUp
        GRB_DoubleAttr_Xn
        GRB_DoubleAttr_FarkasProof
        GRB_DoubleAttr_FarkasDual
        GRB_DoubleAttr_UnbdRay
        GRB_DoubleAttr_PStart
        GRB_DoubleAttr_DStart

    enum GRB_IntAttr:
        GRB_IntAttr_NumConstrs
        GRB_IntAttr_NumVars
        GRB_IntAttr_NumSOS
        GRB_IntAttr_NumQConstrs
        GRB_IntAttr_NumNZs
        GRB_IntAttr_NumQNZs
        GRB_IntAttr_NumQCNZs
        GRB_IntAttr_NumIntVars
        GRB_IntAttr_NumBinVars
        GRB_IntAttr_NumPWLObjVars
        GRB_IntAttr_ModelSense
        GRB_IntAttr_IsMIP
        GRB_IntAttr_IsQP
        GRB_IntAttr_IsQCP
        GRB_IntAttr_Status
        GRB_IntAttr_SolCount
        GRB_IntAttr_BarIterCount
        GRB_IntAttr_VBasis
        GRB_IntAttr_CBasis
        GRB_IntAttr_PWLObjCvx
        GRB_IntAttr_BranchPriority
        GRB_IntAttr_BoundVioIndex
        GRB_IntAttr_BoundSVioIndex
        GRB_IntAttr_ConstrVioIndex
        GRB_IntAttr_ConstrSVioIndex
        GRB_IntAttr_ConstrResidualIndex
        GRB_IntAttr_ConstrSResidualIndex
        GRB_IntAttr_DualVioIndex
        GRB_IntAttr_DualSVioIndex
        GRB_IntAttr_DualResidualIndex
        GRB_IntAttr_DualSResidualIndex
        GRB_IntAttr_ComplVioIndex
        GRB_IntAttr_IntVioIndex
        GRB_IntAttr_IISMinimal
        GRB_IntAttr_IISLB
        GRB_IntAttr_IISUB
        GRB_IntAttr_IISConstr
        GRB_IntAttr_IISSOS
        GRB_IntAttr_IISQConstr
        GRB_IntAttr_TuneResultCount
        GRB_IntAttr_Lazy

    enum GRB_IntParam:
        GRB_IntParam_SolutionLimit
        GRB_IntParam_Method
        GRB_IntParam_LPMethod
        GRB_IntParam_ScaleFlag
        GRB_IntParam_SimplexPricing
        GRB_IntParam_Quad
        GRB_IntParam_NormAdjust
        GRB_IntParam_Sifting
        GRB_IntParam_SiftMethod
        GRB_IntParam_SubMIPNodes
        GRB_IntParam_VarBranch
        GRB_IntParam_Cuts
        GRB_IntParam_CliqueCuts
        GRB_IntParam_CoverCuts
        GRB_IntParam_FlowCoverCuts
        GRB_IntParam_FlowPathCuts
        GRB_IntParam_GUBCoverCuts
        GRB_IntParam_ImpliedCuts
        GRB_IntParam_MIPSepCuts
        GRB_IntParam_MIRCuts
        GRB_IntParam_ModKCuts
        GRB_IntParam_ZeroHalfCuts
        GRB_IntParam_NetworkCuts
        GRB_IntParam_SubMIPCuts
        GRB_IntParam_CutAggPasses
        GRB_IntParam_CutPasses
        GRB_IntParam_GomoryPasses
        GRB_IntParam_NodeMethod
        GRB_IntParam_Presolve
        GRB_IntParam_Aggregate
        GRB_IntParam_IISMethod
        GRB_IntParam_PreCrush
        GRB_IntParam_PreDepRow
        GRB_IntParam_PreMIQPMethod
        GRB_IntParam_PrePasses
        GRB_IntParam_DisplayInterval
        GRB_IntParam_OutputFlag
        GRB_IntParam_Threads
        GRB_IntParam_BarIterLimit
        GRB_IntParam_Crossover
        GRB_IntParam_CrossoverBasis
        GRB_IntParam_BarCorrectors
        GRB_IntParam_BarOrder
        GRB_IntParam_PumpPasses
        GRB_IntParam_RINS
        GRB_IntParam_Symmetry
        GRB_IntParam_MIPFocus
        GRB_IntParam_NumericFocus
        GRB_IntParam_AggFill
        GRB_IntParam_PreDual
        GRB_IntParam_SolutionNumber
        GRB_IntParam_MinRelNodes
        GRB_IntParam_ZeroObjNodes
        GRB_IntParam_BranchDir
        GRB_IntParam_InfUnbdInfo
        GRB_IntParam_DualReductions
        GRB_IntParam_BarHomogeneous
        GRB_IntParam_PreQLinearize
        GRB_IntParam_MIQCPMethod
        GRB_IntParam_QCPDual
        GRB_IntParam_LogToConsole
        GRB_IntParam_PreSparsify
        GRB_IntParam_Seed
        GRB_IntParam_ConcurrentMIP
        GRB_IntParam_ConcurrentJobs
        GRB_IntParam_LazyConstraints
        GRB_IntParam_TuneResults
        GRB_IntParam_TuneTrials
        GRB_IntParam_TuneOutput
        GRB_IntParam_TuneJobs
        GRB_IntParam_Disconnected
    
    enum GRB_StringParam:
        GRB_StringParam_LogFile
        GRB_StringParam_NodefileDir
        GRB_StringParam_ResultFile
        GRB_StringParam_WorkerPool
        GRB_StringParam_WorkerPassword
        GRB_StringParam_Dummy

    enum GRB_DoubleParam:
        GRB_DoubleParam_Cutoff
        GRB_DoubleParam_IterationLimit
        GRB_DoubleParam_NodeLimit
        GRB_DoubleParam_TimeLimit
        GRB_DoubleParam_FeasibilityTol
        GRB_DoubleParam_IntFeasTol
        GRB_DoubleParam_MarkowitzTol
        GRB_DoubleParam_MIPGap
        GRB_DoubleParam_MIPGapAbs
        GRB_DoubleParam_OptimalityTol
        GRB_DoubleParam_PerturbValue
        GRB_DoubleParam_Heuristics
        GRB_DoubleParam_ObjScale
        GRB_DoubleParam_NodefileStart
        GRB_DoubleParam_BarConvTol
        GRB_DoubleParam_BarQCPConvTol
        GRB_DoubleParam_PSDTol
        GRB_DoubleParam_ImproveStartGap
        GRB_DoubleParam_ImproveStartNodes
        GRB_DoubleParam_ImproveStartTime
        GRB_DoubleParam_FeasRelaxBigM
        GRB_DoubleParam_TuneTimeLimit
        GRB_DoubleParam_PreSOS1BigM
        GRB_DoubleParam_PreSOS2BigM


cdef extern from 'gurobi_c.h':
    const char GRB_BINARY, GRB_CONTINUOUS, GRB_INTEGER
    const char GRB_EQUAL, GRB_LESS_EQUAL, GRB_GREATER_EQUAL
    const char *GRB_INT_ATTR_MODELSENSE
    const char *GRB_DBL_ATTR_OBJ
    const char *GRB_DBL_ATTR_X
    const char *GRB_DBL_ATTR_OBJVAL
    const char *GRB_INT_PAR_OUTPUTFLAG
    const char *GRB_INT_ATTR_NUMCONSTRS
    const char *GRB_INT_ATTR_STATUS
    const char *GRB_DBL_ATTR_ITERCOUNT
    const char *GRB_DBL_ATTR_SLACK
    const char *GRB_DBL_ATTR_LB
    const char *GRB_DBL_ATTR_UB
    const char *GRB_INT_PAR_METHOD
    const int GRB_MAXIMIZE, GRB_MINIMIZE, GRB_INFEASIBLE, GRB_OPTIMAL, GRB_INTERRUPTED, \
        GRB_INF_OR_UNBD, GRB_UNBOUNDED
    const double GRB_INFINITY
    const int GRB_CB_POLLING, GRB_CB_PRESOLVE, GRB_CB_SIMPLEX, GRB_CB_MIP, GRB_CB_MIPSOL, \
        GRB_CB_MIPNODE, GRB_CB_MESSAGE, GRB_CB_BARRIER
    const int GRB_CB_MIP_OBJBST
    void GRBversion (int *majorP, int *minorP, int *technicalP)