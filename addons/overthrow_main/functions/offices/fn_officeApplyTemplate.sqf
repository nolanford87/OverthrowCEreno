/*
    Description:
    Puts a mayor's office defence template on a building: the fortifications and props of every tier
    up to the one asked for, and the guards at their posts (OT_fnc_officeTemplate, placed with
    modelToWorld so the building can stand anywhere, facing any way). Items flagged "outside" stand
    on the ground; everything else goes at the template's floor height and is then let down onto
    whatever is under it (the floor, the ground floor's terrain, a table: the probe's floor heights
    are the building positions', up to half a metre above the floor). Props and fortifications have
    no simulation. Each thing made remembers its item (variable "OT_officeItem": [key, tier, index in
    the tier, item]) and the building remembers them all ("OT_officeObjects", "OT_officeGuards",
    "OT_officeTier"). Server.

    Parameters:
        _this # 0: OBJECT - The building (the main one of a multi-piece building, see OT_fnc_officeParts)
        _this # 1: NUMBER - Defence tier, 1 to 5
        _this # 2: SIDE - Side of the guards
        _this # 3: ARRAY - (Optional) The building's other pieces, remembered with it ("OT_officeParts"), default none
        _this # 4: BOOL - (Optional) Placeholders: the guards stand still, unarmed, can't be hurt and
            don't fight (the template review), default false
        _this # 5: NUMBER - (Optional) The first tier placed: only tiers _this # 5 to _this # 1 (the layout
            editor adds one tier's additions to what stands), default 1

    Usage: ([_building, 3, west] call OT_fnc_officeApplyTemplate) params ["_objects", "_guards"];

    Returns: ARRAY - [objects, guards (units)] made, [[], []] for a building without a template
*/

params [["_building", objNull, [objNull]], ["_tier", 1, [0]], ["_side", west, [west]], ["_parts", [], [[]]], ["_placeholders", false, [false]], ["_from", 1, [0]]];

private _key = [_building] call OT_fnc_officeTemplateKey;
private _tiers = [_key] call OT_fnc_officeTemplate;
if (isNull _building || { _tiers isEqualTo [] }) exitWith { [[], []] };
_tier = (round _tier) max 1 min 5;

private _objects = [];
private _guards = [];
private _group = grpNull;
private _buildingDir = getDir _building;
for "_t" from (_from max 1) to _tier do {
    {
        private _item = _x;
        _item params ["_kind", "_what", "_pos", "_dir", ["_extra", []]];
        if !(_kind in ["guard", "object"]) then { continue }; // "doorway" markers are for the checks, nothing stands there
        private _world = _building modelToWorld _pos;
        private _outside = "outside" in _extra;
        if (_outside) then { _world set [2, 0] };
        private _d = _buildingDir + _dir;
        if (_kind isEqualTo "guard") then {
            if (isNull _group) then { _group = createGroup [_side, true] };
            private _unit = [_what, _world, _d, _group, _placeholders] call OT_fnc_officeGuard;
            _unit setVariable ["OT_officeItem", [_key, _t, _forEachIndex, _item]];
            _guards pushBack _unit;
        } else {
            private _class = _what;
            if ("flag" in _extra && { !isNil "OT_flag_NATO" } && { isClass (configFile >> "CfgVehicles" >> OT_flag_NATO) }) then {
                _class = OT_flag_NATO;
            };
            if !(isClass (configFile >> "CfgVehicles" >> _class)) then {
                diag_log format ["Overthrow: office template %1 tier %2 item %3: no such class %4", _key, _t, _forEachIndex, _class];
                continue;
            };
            private _object = createVehicle [_class, [0, 0, 0], [], 0, "CAN_COLLIDE"];
            _object setDir _d;
            if (_class isKindOf "FlagCarrier" || { "gate" in _extra }) then {
                _object setVectorUp [0, 0, 1]; // A flag pole stands straight whatever the ground does, and a gate tilted on a slope lands off its mark
            } else {
                if (_outside) then {
                    _object setVectorUp (surfaceNormal _world);
                } else {
                    _object setVectorUp (vectorUp _building);
                };
            };
            _object setPosATL _world;
            if (!_outside) then {
                // Down onto what's under it (the floor, the ground floor's terrain, a table): the
                // template's floor height is the building positions', up to half a metre above the floor
                private _asl = getPosASL _object;
                private _hits = lineIntersectsSurfaces [_asl vectorAdd [0, 0, 0.5], _asl vectorAdd [0, 0, -1.2], _object, objNull, true, 1, "GEOM", "NONE"];
                if (_hits isNotEqualTo []) then {
                    _object setPosASL [_asl select 0, _asl select 1, ((_hits select 0) select 0) select 2];
                };
            };
            _object enableSimulationGlobal false;
            _object setVariable ["OT_officeItem", [_key, _t, _forEachIndex, _item]];
            _objects pushBack _object;
        };
    } forEach (_tiers select (_t - 1));
};

_building setVariable ["OT_officeObjects", _objects];
_building setVariable ["OT_officeGuards", _guards];
_building setVariable ["OT_officeParts", _parts];
_building setVariable ["OT_officeTier", _tier];
[_objects, _guards]
