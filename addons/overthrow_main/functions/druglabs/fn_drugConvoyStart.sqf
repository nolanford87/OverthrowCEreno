/*
    Description:
    Sends a gang's chemical convoy on its way (server; OT_fnc_drugConvoyTick, or a test): a covered
    truck with 6-10 blow precursors in its cargo (OT_drugConvoyLoad) and 2-3 of the gang's members in
    it, from a road by their camp to another gang's camp (half the time, if one is 1.5-6 km away), a
    town 1.5-6 km away, or else the nearest map edge. OT_drugConvoyEscortChance (30%) of runs have an
    occupier police car in front, its crew in the gang's pay (in the gang's group). Only one at a time:
    a running one is cleared away first.
    They all drive along peacefully (captive, holding fire) until someone fires near them or hurts them
    (OT_fnc_drugConvoyMonitor). Word of the run goes to players with OT_drugConvoyIntelRep (10) rep with
    the gang or within OT_drugConvoyIntelRange (2.5 km) of where it sets off, with a rough marker on
    the truck and one on where it's going (OT_fnc_drugConvoyIntel).

    Parameters:
        _this # 0: NUMBER - Gang id
        _this # 1: NUMBER - (Optional) Escort: -1 the usual chance (default), 0 none, 1 always
        _this # 2: ARRAY - (Optional) Set off from here instead of the camp
        _this # 3: ARRAY - (Optional) Go here instead

    Usage: [_gangId] call OT_fnc_drugConvoyStart; (server)

    Returns: ARRAY - [id, truck, escort vehicle (objNull for none), group], [] if it couldn't set off
*/

params ["_gangId", ["_escort", -1], ["_startPos", []], ["_toPos", []]];

if (!isServer) exitWith { [] };
private _gang = OT_civilians getVariable [format ["gang%1", _gangId], []];
if ((count _gang) isNotEqualTo 9) exitWith { [] };
_gang params ["", "", "_town", "", "_camp", "", "", "", "_gangName"];

private _current = missionNamespace getVariable ["OT_drugConvoy", []];
if (_current isNotEqualTo []) then { [_current, 0] call OT_fnc_drugConvoyCleanup };

private _from = [_camp, _startPos] select (_startPos isNotEqualTo []);
private _road = [_from, 600] call BIS_fnc_nearestRoad;
if (isNull _road) exitWith { [] };

// Where to: another gang's camp, a town, or the map edge
private _toName = "";
if (_toPos isEqualTo []) then {
    private _camps = [];
    {
        {
            private _g = OT_civilians getVariable [format ["gang%1", _x], []];
            if ((count _g) isEqualTo 9 && { _x isNotEqualTo _gangId }) then {
                private _d = (_g select 4) distance2D _from;
                if (_d > 1500 && { _d < 6000 }) then { _camps pushBack [_g select 4, format ["%1's camp near %2", _g select 8, _g select 2]] };
            };
        } forEach (OT_civilians getVariable [format ["gangs%1", _x], []]);
    } forEach OT_allTowns;
    private _towns = (OT_townData select { private _d = (_x select 0) distance2D _from; _d > 1500 && { _d < 6000 } }) apply { [_x select 0, _x select 1] };
    private _dest = call {
        if (_camps isNotEqualTo [] && { (random 100) < 50 || { _towns isEqualTo [] } }) exitWith { selectRandom _camps };
        if (_towns isNotEqualTo []) exitWith { selectRandom _towns };
        // The nearest map edge on land, by a road if there's one near
        private _edges = [[_from select 0, 200, 0], [_from select 0, worldSize - 200, 0], [200, _from select 1, 0], [worldSize - 200, _from select 1, 0]] select { !surfaceIsWater _x };
        if (_edges isEqualTo []) exitWith { [] };
        private _edge = ([_edges, [_from], { _x distance2D _input0 }, "ASCEND"] call BIS_fnc_sortBy) select 0;
        private _r = [_edge, 600] call BIS_fnc_nearestRoad;
        if (!isNull _r) then { _edge = getPosATL _r };
        [_edge, "the edge of the map"]
    };
    if (_dest isNotEqualTo []) then {
        _toPos = +(_dest select 0);
        _toName = _dest select 1;
    };
} else {
    _toName = _toPos call OT_fnc_nearestTown;
};
if (_toPos isEqualTo []) exitWith { [] };
_toPos set [2, 0];
if (_toName isEqualTo "") then { _toName = _toPos call OT_fnc_nearestTown };

private _withEscort = switch (_escort) do {
    case 0: { false };
    case 1: { true };
    default { (random 100) < OT_drugConvoyEscortChance };
};

// On the road, the escort in front
private _spots = [_road, [1, 2] select _withEscort, _toPos, 30] call OT_fnc_NATOroadPositions;
private _spotFor = {
    params ["_i", "_cls"];
    private _s = _spots param [_i, []];
    if (_s isNotEqualTo []) exitWith { _s };
    private _p = (getPosATL _road) findEmptyPosition [5, 80, _cls];
    if (_p isEqualTo []) then { _p = getPosATL _road };
    [_p, (getPosATL _road) getDir _toPos]
};

OT_drugConvoyCount = (missionNamespace getVariable ["OT_drugConvoyCount", 0]) + 1;
private _id = format ["chem%1", OT_drugConvoyCount];

private _group = createGroup [opfor, true];
_group setVariable ["VCM_TOUGHSQUAD", true, true];
_group setVariable ["VCM_NORESCUE", true, true];
_group setVariable ["Vcm_Disable", true, true];
_group setVariable ["lambs_danger_disableGroupAI", true];

private _truckCls = ["C_Truck_02_covered_F", "C_Truck_02_transport_F", "C_Van_01_box_F", "C_Offroad_01_F"] select { isClass (configFile >> "CfgVehicles" >> _x) } select 0;
([[1, 0] select _withEscort, _truckCls] call _spotFor) params ["_tPos", "_tDir"];
private _truck = createVehicle [_truckCls, _tPos, [], 0, "CAN_COLLIDE"];
_truck setDir _tDir;
_truck setVariable ["OT_drugConvoy", _id, true];
clearWeaponCargoGlobal _truck;
clearMagazineCargoGlobal _truck;
clearBackpackCargoGlobal _truck;
clearItemCargoGlobal _truck;
OT_drugConvoyLoad params ["_min", "_max"];
_truck addItemCargoGlobal ["OT_Precursors", _min + floor (random (_max - _min + 1))];

private _units = [];
for "_i" from 1 to (2 + floor (random 2)) do {
    private _unit = _group createUnit [OT_CRIM_Unit, _tPos getPos [8, random 360], [], 0, "NONE"];
    [_unit] joinSilent _group;
    [_unit, _town, [], _gangId] call OT_fnc_initCriminal;
    _unit setVariable ["OT_gangid", _gangId, true];
    _unit setVariable ["hometown", _town, true];
    _unit setVariable ["OT_drugConvoy", _id, true];
    if (_i isEqualTo 1) then { _unit assignAsDriver _truck; _unit moveInDriver _truck } else { _unit assignAsCargo _truck; _unit moveInCargo _truck };
    _units pushBack _unit;
};
private _leader = _units select 0;

private _escortVeh = objNull;
if (_withEscort) then {
    ([0, OT_NATO_Vehicle_Police] call _spotFor) params ["_ePos", "_eDir"];
    _escortVeh = createVehicle [OT_NATO_Vehicle_Police, _ePos, [], 0, "CAN_COLLIDE"];
    _escortVeh setDir _eDir;
    _escortVeh setVariable ["OT_drugConvoy", _id, true];
    // Its crew made in the gang's group from the start and kept on it (joining another group's units
    // in later can make them get out)
    private _crew = [];
    {
        private _u = _group createUnit [OT_NATO_Unit_Police, _ePos getPos [6, random 360], [], 0, "NONE"];
        [_u] joinSilent _group;
        if (_x isEqualTo "driver") then { _u assignAsDriver _escortVeh; _u moveInDriver _escortVeh } else { _u assignAsCargo _escortVeh; _u moveInCargo _escortVeh };
        _crew pushBack _u;
    } forEach ["driver", "cargo"];
    {
        _x setVariable ["OT_drugConvoy", _id, true];
        _x setVariable ["OT_drugConvoyEscort", true, true];
        _units pushBack _x;
    } forEach _crew;
    _leader = driver _escortVeh;
};
_group selectLeader _leader;
_group addVehicle _truck;
if (!isNull _escortVeh) then { _group addVehicle _escortVeh };
// Nothing hurt settling onto the road (a knock would read as an ambush)
{ _x allowDamage false } forEach ([_truck, _escortVeh] - [objNull]);
[[_truck, _escortVeh] - [objNull]] spawn { params ["_vehs"]; sleep 10; { if (!isNull _x) then { _x setDamage 0; _x allowDamage true } } forEach _vehs };
{
    private _o = _x;
    _o setCaptive true;
    { _x addCuratorEditableObjects [[_o], false] } forEach allCurators;
} forEach (_units + [_truck, _escortVeh] - [objNull]);

_group setFormation "COLUMN";
_group setBehaviour "CARELESS";
_group setCombatMode "BLUE";
_group setSpeedMode "LIMITED";
private _wp = _group addWaypoint [_toPos, 0];
_wp setWaypointType "MOVE";
_wp setWaypointCompletionRadius 40;

private _convoy = createHashMapFromArray [
    ["id", _id], ["gang", _gangId], ["truck", _truck], ["escort", _escortVeh], ["group", _group],
    ["units", _units], ["from", getPosATL _truck], ["to", _toPos], ["toName", _toName],
    ["started", time], ["hostile", false], ["over", false], ["reason", ""], ["cleaned", false]
];
OT_drugConvoy = _convoy;

// Word of it
private _text = format ["Word is %1 are moving a chemical shipment from near %2 to %3%4", _gangName, _town, _toName, ["", ", with an occupier police escort"] select _withEscort];
{
    if (((_x getVariable [format ["gangrep%1", _gangId], 0]) >= OT_drugConvoyIntelRep) || { (_x distance2D _truck) < OT_drugConvoyIntelRange }) then {
        _text remoteExec ["OT_fnc_notifyMinor", _x, false];
        [_id, _truck, _toPos] remoteExec ["OT_fnc_drugConvoyIntel", _x, false];
    };
} forEach (allPlayers - (entities "HeadlessClient_F"));
// The state of every man in it (the escort's crew went missing in QA): at once, then after 0.5 s
OT_drugConvoyDebug = {
    params ["_id", "_when", "_units", "_escortVeh"];
    diag_log format ["Overthrow: chemical convoy %1 %2: escort %3 (alive %4, crew %5); men [class, alive, in, captive, side, lifeState, group]: %6",
        _id, _when, typeOf _escortVeh, alive _escortVeh, count crew _escortVeh,
        _units apply { [typeOf _x, alive _x, typeOf objectParent _x, captive _x, side group _x, lifeState _x, str group _x] }];
};
[_id, "at once", _units, _escortVeh] call OT_drugConvoyDebug;
[_id, _units, _escortVeh] spawn { params ["_id", "_units", "_escortVeh"]; sleep 0.5; [_id, "after 0.5 s", _units, _escortVeh] call OT_drugConvoyDebug };
diag_log format ["Overthrow: %1 chemical convoy %2 from %3 to %4 (%5), escort: %6", _gangName, _id, (getPosATL _truck) apply { round _x }, _toName, _toPos apply { round _x }, _withEscort];

[_convoy] spawn OT_fnc_drugConvoyMonitor;
[_id, _truck, _escortVeh, _group];
