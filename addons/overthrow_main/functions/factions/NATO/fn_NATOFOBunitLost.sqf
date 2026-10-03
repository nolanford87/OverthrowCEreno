/*
    Description:
    One of a FOB's garrison was killed (OT_fnc_deathHandler): it comes off the FOB's stored garrison
    (server "NATOfobs", see OT_fnc_spawnNATOFOB), so it isn't spawned again. A gunner comes off the
    crewed guns once nobody is left alive on his gun.

    Parameters:
        _this # 0: OBJECT - The dead unit (its "OT_fob" and "OT_fobRole" set)

    Usage: [_unit] call OT_fnc_NATOFOBunitLost;
*/

if (!isServer) exitWith {};
params ["_unit"];

private _pos = _unit getVariable ["OT_fob", []];
private _role = _unit getVariable ["OT_fobRole", ""];
if (_pos isEqualTo [] || { _role isEqualTo "" }) exitWith {};
_unit setVariable ["OT_fobRole", nil]; // Counted once

private _fobs = server getVariable ["NATOfobs", []];
private _fob = _fobs select { (_x select 0) isEqualTo _pos } param [0, []];
if (_fob isEqualTo []) exitWith {};

private _index = ["foot", "HMG", "Mortar"] find _role;
if (_index isEqualTo -1) exitWith {};
_index = [1, 3, 4] select _index;
if (_index > 1) then {
    private _gun = _unit getVariable ["OT_fobGun", objNull];
    if (!isNull _gun && { allUnits findIf { _x isNotEqualTo _unit && { (_x getVariable ["OT_fobGun", objNull]) isEqualTo _gun } } > -1 }) then { _index = -1 };
};
if (_index isEqualTo -1) exitWith {};

_fob set [_index, ((_fob param [_index, 0]) - 1) max 0];
server setVariable ["NATOfobs", _fobs, true];
