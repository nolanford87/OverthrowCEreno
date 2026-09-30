/*
    Description:
    A FOB's vehicle was destroyed or taken by a player: its "Vehicle" upgrade becomes "VehicleLost",
    so the vehicle doesn't come back when the game is loaded and the FOB can't buy another. The FOB's
    takeover timer starts if it hadn't yet (lost on the way).

    Parameters:
        _this # 0: OBJECT - The FOB's vehicle

    Usage: [_veh] call OT_fnc_NATOreleaseFOBVehicle;
*/

params ["_veh"];
private _fobPos = _veh getVariable ["OT_fobVehicle", []];
if (_fobPos isEqualTo []) exitWith {};
_veh setVariable ["OT_fobVehicle", nil];

private _fobs = server getVariable ["NATOfobs", []];
{
    _x params ["_pos", "", "_upgrades"];
    if (_pos isEqualTo _fobPos) exitWith {
        private _index = _upgrades find "Vehicle";
        if (_index > -1) then { _upgrades set [_index, "VehicleLost"] };
    };
} forEach _fobs;
server setVariable ["NATOfobs", _fobs, true];
[_fobPos] call OT_fnc_NATOstartFOBTimer;
