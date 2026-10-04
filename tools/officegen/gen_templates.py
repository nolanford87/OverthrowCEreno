"""
Mayor's office defence templates for the Altis house classes (Overthrow CE).

Reads the probe (probe_offices.txt) and writes one SQF template function per building to
addons/overthrow_main/functions/offices/templates/fn_officeTpl_<Key>.sqf, using the shared
library (officegen_lib.py). The per-building tuning is the SPECS dict below: where the generator
can't tell (buildings without door memory points, which door is the main one), it is told here.

Usage (from the repository root):
    python tools/officegen/gen_templates.py            writes the templates
    python tools/officegen/gen_templates.py --render   also prints each template on the floor plans
    python tools/officegen/gen_templates.py --only Land_i_House_Big_01_V1_F
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import officegen_lib as og  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROBE = os.path.join(ROOT, "tools", "officegen", "probe_offices.txt")
OUT = os.path.join(ROOT, "addons", "overthrow_main", "functions", "offices", "templates")

# Class -> spec (see officegen_lib.build_tiers for the keys)
SPECS = {
    # Two-storey stone village house, outside stairs up to a landing on the east side. No door memory
    # points: the ground floor opens through the gap in its south wall (grid), the landing is the
    # "roof" position.
    "Land_i_Stone_HouseBig_V1_F": {
        "size": "small",
        "extra_doors": [([3.0, -1.6, -0.4], 180)],
        "perimeter_margin": 4.0,
    },
    # Two-storey town house (Big 02): front door on the west side in a recess, a back door north.
    # The middle door (index 1) and its twin upstairs are between rooms.
    "Land_i_House_Big_02_V1_F": {
        "size": "small",
        "main_door": 0,
        "perimeter_margin": 4.5,
    },
    # Two-storey villa (Big 01): doors on the south and east sides, the upstairs door is between rooms.
    "Land_i_House_Big_01_V1_F": {
        "size": "small",
        "main_door": 0,
        "perimeter_margin": 4.5,
    },
}


def main(argv):
    render = "--render" in argv
    only = None
    if "--only" in argv:
        only = argv[argv.index("--only") + 1]
    data = og.parse_probe(PROBE)
    for cls, spec in SPECS.items():
        if only and cls != only:
            continue
        b = data[cls]
        key = og.template_key(cls)
        tiers, plan = og.build_tiers(b, spec)
        problems = og.check_tiers(b, tiers, plan)
        path = os.path.join(OUT, "fn_officeTpl_%s.sqf" % key)
        og.write_template(path, key, cls, tiers)
        print("%s -> %s: guards %s, items per tier %s" % (
            cls, os.path.relpath(path, ROOT), og.guard_counts(tiers), [len(t) for t in tiers]))
        for line in plan.log:
            print("    note: " + line)
        for p in problems:
            print("    PROBLEM: " + p)
        if render:
            print(og.render(b, tiers, ring=plan.ring))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
