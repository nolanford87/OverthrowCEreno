/*
    Description:
    A town's mayor's office layout, authored in the town itself (the "townlayout" QA suite, merged by
    tools/officegen/merge_layouts.py into the OT_fnc_officeLayouts_<world> function): the office
    building and, per defence tier, everything standing there at that tier (a full snapshot, not what
    the tier adds), in world coordinates, so it can use the street and the neighbouring buildings. Read
    once per mission (OT_officeLayouts). Any machine.

    Parameters:
        _this # 0: STRING - Town

    Usage: ([_town] call OT_fnc_officeLayout) params ["_office", "_tiers"];

    Returns: ARRAY - [office, [tier 1 snapshot, ..., tier 5 snapshot], confirmed, bracket], [] for a town
        without one; bracket: the population bracket it was authored for (OT_fnc_officeBracket), 0 for none
        office: [class, position ASL, direction, spawned (not a map building)]
        snapshot: [[kind, what, position ASL, orientation, extra], ...], [] for a tier not authored;
            kind "guard" (what: a role, OT_fnc_officeGuardClass; orientation: direction) or "object"
            (what: a class; orientation: [vectorDir, vectorUp]); extra flags: "flag" (gets the occupier's flag);
            or "hide": a map object removed at that tier (what: its model, getModelInfo's name, or its class; OT_fnc_officeHide)
*/

params [["_town", "", [""]]];

if (isNil "OT_officeLayouts") then {
    OT_officeLayouts = call (missionNamespace getVariable [format ["OT_fnc_officeLayouts_%1", worldName], { createHashMap }]);
};
OT_officeLayouts getOrDefault [_town, []]
