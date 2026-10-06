/*
    Description:
    The map's own objects a town's mayor's office layout removes at a tier (its "hide" items: a fence, a low
    wall, a shed, a tree in the way, at that tier or any below it) hidden for everyone, and those the town hid before that the tier keeps
    shown again. Kept per town in OT_officeHidden. The trees and bushes within 10 m of a lookout tower (a
    "lookout" item, tools/officegen/tower_gen.py) of the tier or any below it are cleared too, kept apart in
    OT_officeCleared (the layout editor saves OT_officeHidden as the layout's hides; these follow the towers). Called for every office when the game starts (at its tier),
    by OT_fnc_officeApplyLayout for the tier it puts up, and with tier 0 to bring them all back. Server.

    Parameters:
        _this # 0: STRING - Town
        _this # 1: NUMBER - Defence tier, 1 to 5; 0 for none

    Usage: [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeHide;

    Returns: ARRAY - The map objects hidden now
*/

params [["_town", "", [""]], ["_tier", 0, [0]]];

if (isNil "OT_officeHidden") then { OT_officeHidden = createHashMap };
if (isNil "OT_officeCleared") then { OT_officeCleared = createHashMap };
// A map object removed at a tier stays removed at every tier above it (the user's rule): the tier's own and those below
private _tiers = ([_town] call OT_fnc_officeLayout) param [1, []];
private _items = [];
for "_i" from 0 to ((_tier min 5) - 1) do { _items append (_tiers param [_i, []]) };
private _now = [];
private _cleared = [];
{
    _x params ["_kind", "_model", "_at", "", ["_extra", []]];
    if ("lookout" in _extra) then {
        { _cleared pushBackUnique _x } forEach (nearestTerrainObjects [ASLToAGL _at, ["TREE", "SMALL TREE", "BUSH"], 10, false, true]);
        continue;
    };
    if (_kind isNotEqualTo "hide") then { continue };
    // The map object of that model (or class, as the probe names one that has a class) standing there, within a metre
    private _near = nearestTerrainObjects [ASLToAGL _at, [], 1, true, true];
    private _o = _near param [_near findIf { ((getModelInfo _x) select 0) == _model || { (typeOf _x) == _model } }, objNull];
    if (isNull _o) then {
        diag_log format ["Overthrow: office layout %1 tier %2: no map object %3 at %4 to hide", _town, _tier, _model, _at];
        continue;
    };
    _now pushBackUnique _o;
} forEach _items;

{ if (!isNull _x) then { _x hideObjectGlobal false } } forEach (((OT_officeHidden getOrDefault [_town, []]) + (OT_officeCleared getOrDefault [_town, []])) - _now - _cleared);
{ if !(isObjectHidden _x) then { _x hideObjectGlobal true } } forEach (_now + _cleared);
OT_officeHidden set [_town, _now];
OT_officeCleared set [_town, _cleared];
_now
