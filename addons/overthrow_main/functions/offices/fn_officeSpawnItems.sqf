/*
    Description:
    Makes a mayor's office layout's things (OT_fnc_officeLayout's item format) exactly where they're given:
    guards at their posts (OT_fnc_officeGuard), props and fortifications with no simulation, a flag pole
    with the occupier's flag, a gate ("open") with its doors open; a closed gate locked and worked by the
    occupier (OT_fnc_officeGates; open and unlocked once the resistance holds the town). Each thing remembers its item ("OT_officeItem": tag + [index, item]).
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
    if (_kind in ["hide", "gate"]) then { continue }; // A map object removed (OT_fnc_officeHide), a gate's opening (a marker)
    if (_kind isEqualTo "guard") then {
        if (isNull _group) then { _group = createGroup [_side, true] };
        private _p = ASLToATL _at;
        if ("ground" in _extra) then { _p set [2, 0] };
        private _unit = [_what, _p, _orient, _group, _placeholders] call OT_fnc_officeGuard;
        _unit setVariable ["OT_officeItem", _tag + [_forEachIndex, _item]];
        _guards pushBack _unit;
    } else {
        if (_kind isEqualTo "static") exitWith {
            // A static weapon by role (OT_fnc_officeStatic), the occupier's own, crewed unless placeholders
            private _static = createVehicle [[_what] call OT_fnc_officeStatic, [0, 0, 0], [], 0, "CAN_COLLIDE"];
            _static setPosASL _at;
            _static setVectorDirAndUp _orient;
            if ("ground" in _extra) then { _static setPosATL [_at select 0, _at select 1, 0] };
            _static setVariable ["OT_officeItem", _tag + [_forEachIndex, _item]];
            _objects pushBack _static;
            if (!_placeholders) then {
                if (isNull _group) then { _group = createGroup [_side, true] };
                private _gunner = [["rifleman", (getPosATL _static) vectorAdd [0, 0, 1], getDir _static, _group] call OT_fnc_officeGuard];
                (_gunner select 0) moveInGunner _static;
                (_gunner select 0) setVariable ["OT_officeItem", _tag + [_forEachIndex, _item]];
                _guards append _gunner;
            };
        };
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
        // A drafted layout's flags (tools/officegen/townlib.py): "ground" on the terrain here, "drop" down onto
        // whatever is under it (a floor, the ground); a layout saved in the editor has exact positions
        if ("ground" in _extra) then { _object setPosATL [_at select 0, _at select 1, 0] };
        if ("drop" in _extra) then {
            private _hits = lineIntersectsSurfaces [_at vectorAdd [0, 0, 0.6], _at vectorAdd [0, 0, -1.5], _object, objNull, true, 1, "GEOM", "NONE"];
            if (_hits isNotEqualTo []) then { _object setPosASL [_at select 0, _at select 1, ((_hits select 0) select 0) select 2] };
        };
        // "open": a gate's doors swung open (and simulated, so they stay so), for the AI's men and vehicles; every
        // gate of a town the resistance holds
        private _gate = "gate" in toLower _class;
        private _town = _tag param [0, ""];
        private _held = _town isNotEqualTo "" && { (server getVariable [format ["officeheld%1", _town], false]) || { _town in (server getVariable ["NATOabandoned", []]) } };
        if ("open" in _extra || { _gate && _held }) then {
            { if ("sound_source" in toLower _x) then { _object animateSource [_x, 1, true] } } forEach (("true" configClasses (configOf _object >> "AnimationSources")) apply { configName _x });
        } else {
            if (_gate) then {
                // A closed gate locked, simulated so it swings: only a charge opens it for players
                // (OT_fnc_officeBreach), the occupier's men and vehicles open it (OT_fnc_officeGates)
                for "_d" from 1 to getNumber (configOf _object >> "numberOfDoors") do { _object setVariable [format ["bis_disabled_Door_%1", _d], 1, true] };
                _object setVariable ["OT_officeGate", true, true];
                if (!_placeholders) then { [_object] call OT_fnc_officeGates };
            } else {
                _object enableSimulationGlobal false;
            };
        };
        _object setVariable ["OT_officeItem", _tag + [_forEachIndex, _item]];
        _objects pushBack _object;
    };
} forEach _items;

[_objects, _guards]
