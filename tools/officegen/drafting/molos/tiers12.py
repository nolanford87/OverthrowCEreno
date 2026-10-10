"""Molos (the user's: the chapel is the office, the occupier's strongpoint): draft T1/T2, light like the other
bracket-3 towns' (T1 nothing, T2 a few sandbags at the HQ's doors). The chapel has one way in (OTBEXIT: its west end,
model y 2.9), and the road runs right past that end's north half, so the bags stand south of the door and round the
building, off the road (blocklib's roads, 1 m or more clear). Model coordinates (the chapel faces north, dir 0)."""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))  # tools/officegen
import merge_layouts as ml, blocklib as bl
b = bl.load()['Molos']
O = b.pos
# (class, model x, y, facing x, y)
T2 = [("Land_BagFence_Short_F", -13.8, -0.5, -1, 0),     # beside the door, facing the street west
      ("Land_BagFence_Long_F", -15.5, -3.2, -0.94, -0.34),  # the corner in front of the door
      ("Land_BagFence_Short_F", -9.5, -6.8, 0, -1),      # the south side by the porch
      ("Land_BagFence_Short_F", 14.2, 0.0, 1, 0)]        # behind the apse, facing east
towns = ml.load_saved('Altis')
t = towns['Molos']
items = []
for cls, x, y, fx, fy in T2:
    w = (O[0] + x, O[1] + y)
    items.append(["object", cls, f"[{w[0]:.3f},{w[1]:.3f},{b.ground(*w):.3f}]", f"[[{fx:.4f},{fy:.4f},0.0000],[0.0000,0.0000,1.0000]]", "ground"])
t['tiers'][1] = []
t['tiers'][2] = items
ml.write_saved('Altis', towns)
ml.write_sqf('Altis', towns)
print("Molos T1: nothing; T2:", len(items), "sandbags")
