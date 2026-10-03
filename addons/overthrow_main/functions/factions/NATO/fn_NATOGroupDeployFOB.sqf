private _leader = _this;

private _group = group _leader;
private _targetPos = _leader getVariable ["OT_targetPos", objNull];
private _veh = vehicle _leader;

private _near = false;

{
    unassignVehicle _x;
} forEach (units _group);
(units _group) allowGetIn false;

sleep 10;
if ((units _group) findIf { alive _x } == -1) exitWith {};

if (!isNull _veh) then { deleteVehicle _veh };

private _fobs = server getVariable ["NATOfobs", []];

{
    private _pb = _x select 0;
    if (_pb distance _targetPos < 500) then {
        _near = true;
    };
} forEach (_fobs);
_group setVariable ["OT_deployFOBDone", true, false];
if (_near) exitWith {};

OT_flag_NATO createVehicle _targetPos;

// Its garrison is stored and virtualized, this group is its soldiers on foot until no player is near
// (OT_fnc_NATOregisterFOB). Tagged "OT_fob", they're cleared with the FOB (OT_fnc_NATOclearFOB)
private _fob = [_targetPos, { alive _x } count (units _group), [], 0, 0];
_fobs pushBack _fob;
[_fob, _group] call OT_fnc_NATOregisterFOB;
server setVariable ["NATOfobs", _fobs, true];
_group call OT_fnc_initMilitaryPatrol;
