/*
    Description:
    Counts down the FOB takeover timers (OT_fnc_NATOstartFOBTimer). A timer whose FOB was cleared is
    dropped. When one runs out, the town falls back under the occupier's control: 100% stability,
    no resistance support, a small occupier garrison, and the FOB's vehicle (if it still has it) joins
    the town's garrison. The FOB then disbands once no living player is within 1 km of it.
    Run by the NATO loop every few seconds, the time left is saved with the game.

    Usage: call OT_fnc_NATOFOBtimers;
*/

private _now = time;
// The loop only runs with players online, time without any doesn't count
private _elapsed = ((_now - (missionNamespace getVariable ["OT_fobTimerLast", _now])) max 0) min 30;
OT_fobTimerLast = _now;

// FOBs that took their town back disband once no living player is within 1 km
private _fobList = server getVariable ["NATOfobs", []];
private _disband = _fobList select {
    private _fobPos = _x select 0;
    ("Disband" in (_x select 2)) && { (allPlayers - entities "HeadlessClient_F") findIf { alive _x && { (_x distance2D _fobPos) < 1000 } } isEqualTo -1 }
};
if (_disband isNotEqualTo []) then {
    {
        private _fobPos = _x select 0;
        private _statics = [OT_flag_NATO, OT_NATO_Barrier_Small, OT_NATO_Barrier_Large, OT_NATO_Sandbag_Curved, OT_NATO_HMG, OT_NATO_Mortar] + OT_NATO_StaticGarrison_LevelOne;
        {
            { deleteVehicle _x } forEach (crew _x);
            deleteVehicle _x;
        } forEach ((nearestObjects [_fobPos, _statics, 60]) select { !(_x call OT_fnc_hasOwner) });
        // Its soldiers (on foot, the vehicle left for the town)
        { deleteVehicle _x } forEach ((_fobPos nearEntities ["CAManBase", 250]) select { side group _x isEqualTo blufor && { !isPlayer _x } && { isNull objectParent _x } });
        deleteMarker format ["natofob%1", str _fobPos];
        _fobList deleteAt (_fobList find _x);
        diag_log format ["Overthrow: %1 FOB near %2 disbanded", OT_NATO_name, _fobPos call OT_fnc_nearestTown];
    } forEach _disband;
    server setVariable ["NATOfobs", _fobList, true];
};

private _timers = server getVariable ["NATOfobTimers", []];
if (_timers isEqualTo []) exitWith {};
private _fobs = (server getVariable ["NATOfobs", []]) apply { _x select 0 };
private _keep = [];

{
    _x params ["_fobPos", "_left", "_town"];
    if !(_fobPos in _fobs) then {
        format ["The %1 FOB near %2 was cleared, %2 stays as it is", OT_NATO_name, _town] remoteExec ["OT_fnc_notifyGood", 0, false];
        continue;
    };
    _left = _left - _elapsed;
    if (_left > 0) then {
        _keep pushBack [_fobPos, _left, _town];
        continue;
    };

    // Time's up: the town is the occupier's again
    private _abandoned = server getVariable ["NATOabandoned", []];
    private _index = _abandoned find _town;
    if (_index > -1) then { _abandoned deleteAt _index };
    server setVariable ["NATOabandoned", _abandoned, true];
    server setVariable [format ["NATOpatrolsent%1", _town], false];

    [_town, -(server getVariable [format ["rep%1", _town], 0])] call OT_fnc_support;
    [_town, 100 - (server getVariable [format ["stability%1", _town], 0])] call OT_fnc_stability;

    // The garrison a town at 100% stability starts with (initNATO)
    private _garrison = [2, 4] select (_town in OT_NATO_priority);
    server setVariable [format ["garrison%1", _town], (server getVariable [format ["garrison%1", _town], 0]) max _garrison, true];

    // The FOB's vehicle, if it still has it, joins the town's garrison and drives over to it
    private _veh = vehicles select { alive _x && { (_x getVariable ["OT_fobVehicle", []]) isEqualTo _fobPos } } param [0, objNull];
    if (!isNull _veh && { !(_veh call OT_fnc_hasOwner) }) then {
        _veh setVariable ["OT_fobVehicle", nil];
        _veh setVariable ["vehgarrison", _town, true]; // Destroyed or stolen, it comes off the town's list
        private _list = server getVariable [format ["vehgarrison%1", _town], []];
        _list pushBack (typeOf _veh);
        server setVariable [format ["vehgarrison%1", _town], _list, true];
        private _group = group driver _veh;
        if (!isNull _group) then {
            private _park = ((server getVariable [_town, getPos _veh]) findEmptyPosition [10, 150, typeOf _veh]);
            _group setVariable ["OT_patrolCenter", server getVariable [_town, getPos _veh]];
            _group setVariable ["OT_patrolHome", [_park, getPos _veh] select (_park isEqualTo [])];
            { _x setVariable ["garrison", _town, false] } forEach (crew _veh);
        };
    };

    // The FOB has done its job, it goes once no player is near
    private _fob = (server getVariable ["NATOfobs", []]) select { (_x select 0) isEqualTo _fobPos } param [0, []];
    if (_fob isNotEqualTo []) then { (_fob select 2) pushBackUnique "Disband" };

    format ["%1 is back under %2 control", _town, OT_NATO_name] remoteExec ["OT_fnc_notifyBad", 0, false];
    diag_log format ["Overthrow: %1 FOB took %2 back", OT_NATO_name, _town];
} forEach _timers;

server setVariable ["NATOfobTimers", _keep];
