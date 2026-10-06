/*
    Description:
    Puts a town's authored mayor's office layout (OT_fnc_officeLayout) up at a defence tier: the
    office building found where the layout says (made there when it's a spawned one, or gone) and
    everything of that tier's snapshot exactly where it was saved, and the map objects it removes hidden
    (OT_fnc_officeHide). Props and fortifications have no simulation. Each thing made remembers its item ("OT_officeItem": [town, tier, index, item]) and the
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

([_tiers param [_tier - 1, []], _side, _placeholders, [_town, _tier]] call OT_fnc_officeSpawnItems) params ["_objects", "_guards"];
[_town, _tier] call OT_fnc_officeHide; // The map objects the tier removes
[_town, _tier] call OT_fnc_officeDoors; // The doors out of its compound locked

_building setVariable ["OT_officeObjects", _objects];
_building setVariable ["OT_officeGuards", _guards];
_building setVariable ["OT_officeTier", _tier];
[_building, _objects, _guards]
