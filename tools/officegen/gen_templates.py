"""
Mayor's office defence templates for the eight Altis office buildings (Overthrow CE).

Reads the probe (probe_offices.txt) and writes one SQF template function per building to
addons/overthrow_main/functions/offices/templates/fn_officeTpl_<Key>.sqf with the shared rule
engine (officegen_lib.build_tiers: the rules from the reviews are documented there). What the
engine can't tell is in SPECS: which door is the main entrance, which door points are between
rooms, which way a door opens when the grid misreads it, the building's size class, and a few
hand-placed flavour props for the big buildings.

Usage (from the repository root):
    python tools/officegen/gen_templates.py            writes the templates
    python tools/officegen/gen_templates.py --render   also prints each template on the floor plans
    python tools/officegen/gen_templates.py --check    checks and renders, writes nothing
    python tools/officegen/gen_templates.py --only Land_i_House_Big_01_V1_F
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import officegen_lib as og  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROBE = os.path.join(ROOT, "tools", "officegen", "probe_offices.txt")
OUT = os.path.join(ROOT, "addons", "overthrow_main", "functions", "offices", "templates")

G_OFFICES, L3_OFFICES = -6.7, 5.0
G_HOSPITAL = -7.8
TABLE_TOP = 0.76  # Land_CampingTable_F's top above its floor

# Class -> spec (see officegen_lib.build_tiers for the keys). Door indices are 0-based into the
# probe's DOORS line; main_door indexes the exterior doorways the engine finds (a double door's two
# points become one doorway).
SPECS = {
    # Two-storey stone village house, outside stairs up to a landing (its "balcony"). No door memory
    # points: the ground floor opens through the gap in its south wall at x 3.
    "Land_i_Stone_HouseBig_V1_F": {
        "size": "small",
        "extra_doorways": [{"centre": (3.0, -2.0), "d": 180, "width": 1.0}],
        "perimeter_margin": 4.0,
    },
    # Two-storey town house (Big 02): front door on the west side in a recess, a door north; the
    # middle door and the upstairs ones are between rooms.
    "Land_i_House_Big_02_V1_F": {
        "size": "small",
        "interior_doors": [1],
        "main_door": 0,
        "office_near": (-1.2, 2.0, 1.0),  # upstairs, the flat's north room (the review: the ground floor is cramped)
        "perimeter_margin": 4.5,
    },
    # Two-storey villa (Big 01): doors south (main) and east; the upstairs door is between rooms.
    "Land_i_House_Big_01_V1_F": {
        "size": "small",
        "main_door": 0,
        "perimeter_margin": 4.5,
    },
    # Small shop: the double front door south (points 0 and 1, one doorway) up a porch, a back door
    # north up two steps; the upstairs doors are the flat's and the balcony's.
    "Land_i_Shop_01_V1_F": {
        "size": "small",
        "main_door": 0,
        "door_dirs": {2: 0},  # the back door opens north up its steps (the grid reads the steps' side)
        "perimeter_margin": 4.0,
    },
    # Large shop: the west door is the only outside door on the ground; the second door point is
    # inside the shop.
    "Land_i_Shop_02_V1_F": {
        "size": "medium",
        "interior_doors": [1],
        "main_door": 0,
        "door_dirs": {0: 270},
        "perimeter_margin": 4.0,
    },
    # Research HQ: glass walled, the entrance on the west under a canopy; the second door is upstairs.
    "Land_Research_HQ_F": {
        "size": "medium",
        "main_door": 0,
        "door_dirs": {0: 270},
        "perimeter_margin": 4.0,
    },
    # Five-storey office block: the south double door (points 0 and 1) is the entrance, the north-west
    # door (4) a side door; 2 and 3 are inside, 5 and 6 on the top floor.
    "Land_Offices_01_V1_F": {
        "size": "large",
        "interior_doors": [2, 3],
        "main_door": 0,
        "office_near": (10.8, -2.2, L3_OFFICES),  # the top floor's corner room
        "perimeter_margin": 5.5,
        "extra": {
            1: [
                og.obj("Land_WaterCooler_01_new_F", (12.4, -1.4, G_OFFICES), 270),
                og.obj("Land_CampingChair_V2_F", (-11.0, 5.1, G_OFFICES), 0),
                og.obj("Land_CampingChair_V2_F", (-12.0, 5.1, G_OFFICES), 0),
                og.obj("Land_OfficeCabinet_01_F", (-6.0, 4.95, G_OFFICES), 0),
                og.obj("Land_OfficeCabinet_01_F", (-7.0, 4.95, G_OFFICES), 0),
            ],
            3: [
                # the radio room: the small top-floor room north of the corner office
                og.obj("Land_CampingTable_F", (5.3, 2.4, L3_OFFICES), 90),
                og.obj("Land_PortableLongRangeRadio_F", (5.3, 2.4, L3_OFFICES + TABLE_TOP), 90),
                og.obj("Land_CampingChair_V2_F", (4.5, 2.4, L3_OFFICES), 90),
                og.obj("MapBoard_altis_F", (5.5, 3.9, L3_OFFICES), 180),
            ],
        },
    },
    # The Kavala hospital with its two wings (OT_fnc_officeParts): the entrance pair on the block's
    # west face (points 1 and 2), door 0 in the north wing's south wall, doors 3 and 4 in the covered
    # bay on the south side, which the grid can't read (no wall shows round them): they face south.
    "Land_Hospital_main_F": {
        "size": "large",
        "main_door": 1,
        "door_dirs": {0: 180, 1: 270, 2: 270, 3: 180, 4: 180},
        "office_near": (-5.8, 11.65, G_HOSPITAL),  # the lobby under the entrance canopy, not the open bay
        "perimeter_margin": 5.5,
        "extra": {
            1: [
                og.obj("Land_CampingChair_V2_F", (-7.5, 8.6, G_HOSPITAL), 90),
                og.obj("Land_CampingChair_V2_F", (-7.5, 9.8, G_HOSPITAL), 90),
                og.obj("Land_WaterCooler_01_new_F", (-3.4, 18.6, G_HOSPITAL), 270),
            ],
            3: [
                # the command post at the lobby's south end: radio table, map, board, cabinets
                og.obj("Land_CampingTable_F", (-4.1, -1.4, G_HOSPITAL), 0),
                og.obj("Land_PortableLongRangeRadio_F", (-4.4, -1.4, G_HOSPITAL + TABLE_TOP), 0),
                og.obj("Land_Map_altis_F", (-3.7, -1.4, G_HOSPITAL + TABLE_TOP), 90),
                og.obj("Land_CampingChair_V2_F", (-2.8, -1.4, G_HOSPITAL), 270),
                og.obj("MapBoard_altis_F", (-6.6, -0.6, G_HOSPITAL), 90),
                og.obj("Land_OfficeCabinet_01_F", (-7.6, -3.5, G_HOSPITAL), 90),
                og.obj("Land_OfficeCabinet_01_F", (-7.6, -4.3, G_HOSPITAL), 90),
            ],
        },
    },
}

NOTES = {
    "Land_Offices_01_V1_F": "The five-storey office block: only the east tower section is enterable, the roof is one open terrace.",
    "Land_Hospital_main_F": "Positions are in the main building's model coordinates; the framework spawns the wings itself\n(OT_fnc_officeParts). The ground is an open undercroft and lobby, the terraces at z 7.6 are the roofs.",
}


def main(argv):
    render = "--render" in argv or "--check" in argv
    write = "--check" not in argv
    only = argv[argv.index("--only") + 1] if "--only" in argv else None
    data = og.parse_probe(PROBE)
    bad = 0
    for cls, spec in SPECS.items():
        if only and cls != only:
            continue
        b = data[cls]
        key = og.template_key(cls)
        tiers, plan = og.build_tiers(b, spec)
        problems = og.check_tiers(b, tiers, plan)
        print("%s -> %s: guards %s, items per tier %s, doorways %s" % (
            cls, key, og.guard_counts(tiers), [len(t) for t in tiers],
            [(dw["role"], tuple(round(c, 1) for c in dw["centre"][:2]), dw["d"], dw["width"]) for dw in plan.doorways]))
        for line in plan.log:
            print("    note: " + line)
        for p in problems:
            print("    PROBLEM: " + p)
            bad += 1
        if render:
            print(og.render(b, tiers, ring=plan.ring))
        if write:
            path = os.path.join(OUT, "fn_officeTpl_%s.sqf" % key)
            og.write_template(path, key, cls, tiers, note=NOTES.get(cls, ""))
            print("    wrote " + os.path.relpath(path, ROOT))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
