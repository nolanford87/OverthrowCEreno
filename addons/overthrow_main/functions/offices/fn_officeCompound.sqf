/*
    Description:
    A town's occupier compound area at a tier (tools/officegen/COMPOUND_PLAN.md): the polygon the compound
    covers, world [x, y] vertices in order round it, from OT_fnc_officeCompounds_<world>. Tiers expand the
    compound: a tier without its own area has the nearest lower tier's. Read once per mission
    (OT_officeCompounds). Any machine.

    Parameters:
        _this # 0: STRING - Town
        _this # 1: NUMBER - Tier, 1 to 5

    Usage: private _area = [_town, 4] call OT_fnc_officeCompound; // [] when the town has none

    Returns: ARRAY - [[x, y], ...], [] for none
*/

params [["_town", "", [""]], ["_tier", 3, [0]]];

if (isNil "OT_officeCompounds") then {
    OT_officeCompounds = call (missionNamespace getVariable [format ["OT_fnc_officeCompounds_%1", worldName], { createHashMap }]);
};
private _tiers = OT_officeCompounds getOrDefault [_town, []];
private _area = [];
for "_t" from ((round _tier) min 5) to 3 step -1 do {
    if (_area isEqualTo []) then { _area = _tiers param [_t - 3, []] };
};
_area
