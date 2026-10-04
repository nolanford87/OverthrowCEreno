/*
    Description:
    Puts a town's authored mayor's office layout (OT_fnc_officeLayout) up at a defence tier: the
    office building found where the layout says (made there when it's a spawned one, or gone) and
    everything of that tier's snapshot exactly where it was saved. Props and fortifications have no
    simulation. Each thing made remembers its item ("OT_officeItem": [town, tier, index, item]) and the
    building remembers them ("OT_officeObjects", "OT_officeGuards", "OT_officeTier"), so
    OT_fnc_officeClearTemplate takes them off again. Server.

    Parameters:
        _this # 0: STRING - Town
        _this # 1: NUMBER - Defence tier, 1 to 5
        _this # 2: SIDE - Side of the guards
        _this # 3: BOOL - (Optional) Placeholders (OT_fnc_officeGuard), default false

    Usage: ([_town, 3, west] call OT_fnc_officeApplyLayout) params ["_building", "_objects", "_guards"];

    Returns: ARRAY - [office building, objects, guards]; [objNull, [], []] for a town without a layout,
        no things when that tier isn't authored
*/

params [["_town", "", [""]], ["_tier", 1, [0]], ["_side", west, [west]], ["_placeholders", false, [false]]];

private _layout = [_town] call OT_fnc_officeLayout;
if (_layout isEqualTo []) exitWith { [objNull, [], []] };
_layout params ["_office", "_tiers"];
_office params ["_class", "_pos", "_dir"];

private _building = (nearestObjects [ASLToAGL _pos, [_class], 3, true]) param [0, objNull];
if (isNull _building) then {
    _building = createVehicle [_class, [0, 0, 0], [], 0, "CAN_COLLIDE"];
    _building setDir _dir;
    _building setPosASL _pos;
};
_tier = (round _tier) max 1 min 5;

private _objects = [];
private _guards = [];
private _group = grpNull;
{
    private _item = _x;
    _item params ["_kind", "_what", "_at", "_orient", ["_extra", []]];
    if (_kind isEqualTo "guard") then {
        if (isNull _group) then { _group = createGroup [_side, true] };
        private _unit = [_what, ASLToATL _at, _orient, _group, _placeholders] call OT_fnc_officeGuard;
        _unit setVariable ["OT_officeItem", [_town, _tier, _forEachIndex, _item]];
        _guards pushBack _unit;
    } else {
        private _cls = _what;
        if ("flag" in _extra && { !isNil "OT_flag_NATO" } && { isClass (configFile >> "CfgVehicles" >> OT_flag_NATO) }) then {
            _cls = OT_flag_NATO;
        };
        if !(isClass (configFile >> "CfgVehicles" >> _cls)) then {
            diag_log format ["Overthrow: office layout %1 tier %2 item %3: no such class %4", _town, _tier, _forEachIndex, _cls];
            continue;
        };
        private _object = createVehicle [_cls, [0, 0, 0], [], 0, "CAN_COLLIDE"];
        _object setPosASL _at;
        _object setVectorDirAndUp _orient;
        _object enableSimulationGlobal false;
        _object setVariable ["OT_officeItem", [_town, _tier, _forEachIndex, _item]];
        _objects pushBack _object;
    };
} forEach (_tiers param [_tier - 1, []]);

_building setVariable ["OT_officeObjects", _objects];
_building setVariable ["OT_officeGuards", _guards];
_building setVariable ["OT_officeTier", _tier];
[_building, _objects, _guards]
