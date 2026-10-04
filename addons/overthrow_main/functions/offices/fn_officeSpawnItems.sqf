/*
    Description:
    Makes a mayor's office layout's things (OT_fnc_officeLayout's item format) exactly where they're given:
    guards at their posts (OT_fnc_officeGuard), props and fortifications with no simulation, a flag pole
    with the occupier's flag. Each thing remembers its item ("OT_officeItem": tag + [index, item]).
    OT_fnc_officeApplyLayout uses it; so does the layout editor for a layout moved from another town. Server.

    Parameters:
        _this # 0: ARRAY - Items: [[kind, what, position ASL, orientation, extra], ...]
        _this # 1: SIDE - Side of the guards
        _this # 2: BOOL - (Optional) Placeholders (OT_fnc_officeGuard), default false
        _this # 3: ARRAY - (Optional) What each thing's "OT_officeItem" starts with, default [] (e.g. [town, tier])

    Usage: ([_items, west] call OT_fnc_officeSpawnItems) params ["_objects", "_guards"];

    Returns: ARRAY - [objects, guards] made
*/

params [["_items", [], [[]]], ["_side", west, [west]], ["_placeholders", false, [false]], ["_tag", [], [[]]]];

private _objects = [];
private _guards = [];
private _group = grpNull;
{
    private _item = _x;
    _item params ["_kind", "_what", "_at", "_orient", ["_extra", []]];
    if (_kind isEqualTo "guard") then {
        if (isNull _group) then { _group = createGroup [_side, true] };
        private _unit = [_what, ASLToATL _at, _orient, _group, _placeholders] call OT_fnc_officeGuard;
        _unit setVariable ["OT_officeItem", _tag + [_forEachIndex, _item]];
        _guards pushBack _unit;
    } else {
        private _class = _what;
        if ("flag" in _extra && { !isNil "OT_flag_NATO" } && { isClass (configFile >> "CfgVehicles" >> OT_flag_NATO) }) then {
            _class = OT_flag_NATO;
        };
        if !(isClass (configFile >> "CfgVehicles" >> _class)) then {
            diag_log format ["Overthrow: office layout %1 item %2: no such class %3", _tag, _forEachIndex, _class];
            continue;
        };
        private _object = createVehicle [_class, [0, 0, 0], [], 0, "CAN_COLLIDE"];
        _object setPosASL _at;
        _object setVectorDirAndUp _orient;
        _object enableSimulationGlobal false;
        _object setVariable ["OT_officeItem", _tag + [_forEachIndex, _item]];
        _objects pushBack _object;
    };
} forEach _items;

[_objects, _guards]
