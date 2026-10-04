/*
    Description:
    One mayor's office guard put at his post (OT_fnc_officeApplyTemplate, OT_fnc_officeApplyLayout):
    made in the group, standing, facing his way and holding the post. Nothing hurts him for his first
    moments (a man put down on an upper floor now and then dies of the knock the engine gives him
    settling on the floor). Placeholders (the template review and the layout editor) stand still,
    unarmed, can't be hurt and don't fight. Server.

    Parameters:
        _this # 0: STRING - Role (OT_fnc_officeGuardClass) or a unit class
        _this # 1: ARRAY - Position ATL
        _this # 2: NUMBER - Direction
        _this # 3: GROUP - His group
        _this # 4: BOOL - (Optional) A placeholder, default false

    Usage: private _unit = ["marksman", _posATL, 90, _group] call OT_fnc_officeGuard;

    Returns: OBJECT - The guard
*/

params [["_what", "rifleman", [""]], ["_pos", [0, 0, 0], [[]]], ["_dir", 0, [0]], ["_group", grpNull, [grpNull]], ["_placeholders", false, [false]]];

private _class = [[_what] call OT_fnc_officeGuardClass, _what] select (isClass (configFile >> "CfgVehicles" >> _what));
private _unit = _group createUnit [_class, _pos, [], 0, "CAN_COLLIDE"];
_unit setDir _dir;
_unit setPosATL _pos;
_unit setUnitPos "UP";
doStop _unit; // Holds the post until the office's own AI takes over
_unit allowDamage false;
if (_placeholders) then {
    { _unit disableAI _x } forEach ["MOVE", "PATH", "TARGET", "AUTOTARGET", "AUTOCOMBAT", "FSM", "SUPPRESSION"];
    removeAllWeapons _unit;
    _unit setCaptive true;
    _unit setBehaviour "CARELESS";
    _unit setVariable ["OT_placeholder", true];
} else {
    [_unit] spawn { params ["_unit"]; sleep 3; if (alive _unit) then { _unit allowDamage true } };
};
_unit
