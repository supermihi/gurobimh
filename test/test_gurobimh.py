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
    m.addConstr(grb.quicksum(weights[item]*item_selected[item] for item in items) <= capacity)
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

        self.assertAlmostEqual(x1.X, 0)
        self.assertAlmostEqual(x2.X, 0)
        self.assertAlmostEqual(x3.X, 0)
        self.assertAlmostEqual(x4.X, 1)
        self.assertAlmostEqual(x5.X, 10)

        self.assertAlmostEqual(x1.RC, 34/3.0)
        self.assertAlmostEqual(x2.RC, 20/3.0)
        self.assertAlmostEqual(x3.RC, 34/3.0)
        self.assertAlmostEqual(x4.RC, 0)
        self.assertAlmostEqual(x5.RC, 0)

        self.assertAlmostEqual(m.ObjVal, 131)

        self.assertAlmostEqual(iron_constr.Pi, 13/3.0)
        self.assertAlmostEqual(calcium_constr.Pi, 10/3.0)

    def test_knapsack1(self):
        weights = [70, 73, 77, 80, 82, 87, 90, 94, 98, 106, 110, 113, 115, 118, 120]
        values = [135, 139, 149, 150, 156, 163, 173, 184, 192, 201, 210, 214, 221, 229, 240]
        capacity = 750
        m, item_selected = get_knapsack_model(capacity, weights, values)
        m.optimize()
        solution = m.getAttr('X', item_selected)
        target_solution = [1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0.721739130435, 1, 1]
        for i, j in zip(solution, target_solution):
            self.assertAlmostEqual(i, j)

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
