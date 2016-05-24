import unittest
import sys
sys.path.append('..')

import gurobimh as grb
GRB = grb.GRB


def get_knapsack_model(capacity, weights, values):
    items = range(len(weights))
    m = grb.Model()
    m.ModelSense = GRB.MAXIMIZE
    m.ModelName = "knapsack"
    item_selected = [m.addVar(ub=1, obj=values[item], name="item_selected." + str(item))
                              for item in items]
    m.update()
    m.addConstr(grb.quicksum(weights[item]*item_selected[item] for item in items) <= capacity,
                name='knapsack')
    m.update()
    return m, item_selected


def get_knapsack_model_column(capacity, weights, values):
    items = range(len(weights))
    m = grb.Model()
    m.ModelSense = GRB.MAXIMIZE
    m.ModelName = "knapsack_column"
    constr = m.addConstr(0, 'L', capacity, name='knapsack')
    m.update()
    item_selected = [m.addVar(ub=1, obj=values[item], column=grb.Column(weights[item], constr),
                              name="x." + str(item))
                     for item in items]
    m.update()
    return m, item_selected


class GurobiMHTest(unittest.TestCase):
    def test_simple_mip(self):
        m = grb.Model()
        x = m.addVar(vtype=GRB.BINARY, name='x')
        y = m.addVar(vtype=GRB.BINARY, name='y')
        z = m.addVar(vtype=GRB.BINARY, name='z')
        m.update()
        m.setObjective(x + y + 2 * z, GRB.MAXIMIZE)
        c0_name, c1_name = 'constraint0', 'constraint1'
        c0 = m.addConstr(x + 2 * y + 3 * z <= 4, c0_name)
        c1 = m.addConstr(x + y, '>', 1, name=c1_name)
        c2 = m.addConstr(x + y, GRB.LESS_EQUAL, 1)
        m.optimize()
        m.write('mip1.lp')
        self.assertAlmostEqual(x.X, 1)
        self.assertAlmostEqual(y.X, 0)
        self.assertAlmostEqual(z.X, 1)
        self.assertAlmostEqual(m.ObjVal, 3)
        self.assertAlmostEqual(c0.Slack, 0)
        self.assertAlmostEqual(c1.Slack, 0)
        self.assertEqual(x.VarName, 'x')
        self.assertEqual(y.VarName, 'y')
        self.assertEqual(z.Varname, 'z')
        self.assertEqual(c0.ConstrName, c0_name)
        self.assertEqual(c1.ConstrName, c1_name)

    diet_solution = [0, 0, 0, 1, 10]
    diet_rcs = [34/3.0, 20/3.0, 34/3.0, 0, 0]
    diet_pis = [13/3.0, 10/3.0]
    diet_cost = 131

    def test_diet(self):
        m = grb.Model()
        x1 = m.addVar(lb=0, ub=GRB.INFINITY, obj=20, vtype=GRB.CONTINUOUS, name='x.1')
        x2 = m.addVar(obj=10, name='x.2')
        x3 = m.addVar(obj=31, name='x.3')
        x4 = m.addVar(obj=11, name='x.4')
        x5 = m.addVar(obj=12, name='x.5')
        m.update()
        lhs = 2*x1 + 3*x3 + x4 + 2*x5
        iron_constr = m.addConstr(lhs, GRB.GREATER_EQUAL, 21, 'nutrient.iron')
        calcium_constr = m.addConstr(x2 + 2*x3 + 2*x4 + x5 >= 12, 'nutrient.calcium')
        m.update()
        m.optimize()
        self.assertAlmostEqual(m.ObjVal, self.diet_cost)
        for var, soln, rc in zip([x1, x2, x3, x4, x5], self.diet_solution, self.diet_rcs):
            self.assertAlmostEqual(var.X, soln)
            self.assertAlmostEqual(var.RC, rc)
        for constr, pi in zip([iron_constr, calcium_constr], self.diet_pis):
            self.assertAlmostEqual(constr.Pi, pi)
        m.write('diet.lp')

    def test_diet_dual(self):
        m = grb.Model()
        m.ModelSense = GRB.MAXIMIZE
        pi_i = m.addVar(obj=21)
        pi_c = m.addVar(obj=12)
        m.update()
        f1 = m.addConstr(2*pi_i <= 20)
        f2 = m.addConstr(pi_c <= 10)
        f3 = m.addConstr(3*pi_i + 2*pi_c <= 31)
        f4 = m.addConstr(pi_i + 2*pi_c <= 11)
        f5 = m.addConstr(2*pi_i + pi_c <= 12)
        m.update()
        m.optimize()
        self.assertAlmostEqual(m.ObjVal, self.diet_cost)
        for var, pi in zip([pi_i, pi_c], self.diet_pis):
            self.assertAlmostEqual(var.X, pi)
        for constr, soln, rc in zip([f1, f2, f3, f4, f5], self.diet_solution, self.diet_rcs):
            self.assertAlmostEqual(constr.Pi, soln)
            self.assertAlmostEqual(constr.Slack, rc)

    def test_diet_read(self):
        m = grb.read('diet.lp')
        m.optimize()
        self.assertAlmostEqual(m.ObjVal, self.diet_cost)
        x = [m.getVarByName('x.' + str(i)) for i in range(1, 6)]
        for var, soln, rc in zip(x, self.diet_solution, self.diet_rcs):
            self.assertAlmostEqual(var.X, soln)
            self.assertAlmostEqual(var.RC, rc)
        constrs = [m.getConstrByName('nutrient.iron'), m.getConstrByName('nutrient.calcium')]
        for constr, pi in zip(constrs, self.diet_pis):
            self.assertAlmostEqual(constr.Pi, pi)

    def test_knapsack(self):
        weights = [70, 73, 77, 80, 82, 87, 90, 94, 98, 106, 110, 113, 115, 118, 120]
        values = [135, 139, 149, 150, 156, 163, 173, 184, 192, 201, 210, 214, 221, 229, 240]
        capacity = 750
        m, item_selected = get_knapsack_model(capacity, weights, values)
        m.optimize()
        self.assertIsNotNone(m.getConstrByName('knapsack'))
        self.assertAlmostEqual(m.getConstrByName('knapsack').RHS, capacity)
        solution = m.getAttr('X', item_selected)
        target_solution = [1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0.721739130435, 1, 1]
        for i, j in zip(solution, target_solution):
            self.assertAlmostEqual(i, j)

        m2, item_selected2 = get_knapsack_model_column(capacity, weights, values)
        m2.optimize()
        solution = m2.getAttr('X', item_selected2)
        for i,j in zip(solution, target_solution):
            self.assertAlmostEqual(i, j)
        self.assertEqual(m2.ModelName, "knapsack_column")

        for var in item_selected:
            var.vtype = GRB.BINARY
        m.optimize()
        solution = m.getAttr('X', item_selected)
        target_solution = [1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1]
        for i, j in zip(solution, target_solution):
            self.assertAlmostEqual(i, j)

        self.assertEqual(m.ModelName, "knapsack")

if __name__ == '__main__':
    unittest.main()
