/*
    Description:
    The real entrances of the mayor's office buildings, in the building's model coordinates: the doorway's
    centre at floor height, its outward direction relative to the building and its width, measured off the
    office probe (tools/officegen/probe_offices.txt). The layout editor stands the host in front of the
    "main" one, and the town probe logs them (OTTOWN|town|DOOR), which tools/officegen/townlib.py reads
    (it also reads this file, for the office's model origin: keep the list a plain literal, in this order).

    Parameters:
        _this # 0: STRING - Office key (OT_fnc_officeKey)

    Usage: private _main = (["i_House_Big_01_V1_F"] call OTQA_fnc_officeDoorways) select { (_x select 0) isEqualTo "main" };

    Returns: ARRAY - [[role ("main", "back" or "side"), [x, y, z], outward direction, [width, door index]], ...],
        [] for a key not listed
*/

params [["_key", "", [""]]];

(createHashMapFromArray [
    ["Hospital_main_F", [
        ["side", [12.2, 19.8, -7.8], 180, [1.25, 0]],
        ["main", [2.9, 16.43, -7.8], 270, [1, 1]],
        ["side", [2.9, 8.12, -7.8], 270, [1, 2]],
        ["side", [-3.58, -7.9, -7.8], 180, [1, 3]],
        ["side", [-11.3, -21, -7.8], 180, [1.2, 4]]
    ]],
    ["Offices_01_V1_F", [
        ["main", [10.46, -7.7, -6.7], 180, [2.93, 0]],
        ["back", [-14.8, 8.4, -6.7], 0, [1.25, 4]]
    ]],
    ["Research_HQ_F", [
        ["main", [-4.4, 0.58, -2.4], 270, [1.5, 0]]
    ]],
    ["i_House_Big_01_V1_F", [
        ["main", [-3.3, -7.35, -2.5], 180, [2.25, 0]],
        ["side", [4.9, 5.62, -2.5], 90, [1, 1]]
    ]],
    ["i_House_Big_02_V1_F", [
        ["main", [-4.65, -6.17, -2.5], 270, [3.5, 0]],
        ["side", [0.1, 5.3, -2.5], 0, [1.25, 2]]
    ]],
    ["i_Shop_01_V1_F", [
        ["main", [2.98, -2.6, -2.7], 180, [1, 1]],
        ["back", [2.3, 7.2, -2.7], 0, [1.25, 2]]
    ]],
    ["i_Shop_02_V1_F", [
        ["main", [-5.9, -3.2, -2.6], 270, [1.25, 0]]
    ]],
    ["i_Stone_HouseBig_V1_F", [
        ["main", [3, -2, -1.4], 180, [1, -1]]
    ]]
]) getOrDefault [_key, []]
