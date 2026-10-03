/*
    Description:
    Harvests the nearest wild ganja plant (the "Harvest the ganja plant" action): 2.5 seconds
    kneeling, then the server takes the plant and hands over its ganja (OT_fnc_ganjaPick).

    Usage: [] spawn OT_fnc_ganjaHarvest;
*/

if (!isNil "OT_ganjaPicking") exitWith {};
private _near = (missionNamespace getVariable ["OT_ganjaPlants", []]) select { !isNull _x && { (player distance2D _x) < 3 } };
if (_near isEqualTo []) exitWith {};
private _plant = ([_near, [], { player distance2D _x }, "ASCEND"] call BIS_fnc_sortBy) select 0;
OT_ganjaPicking = true;

player playMoveNow "AinvPknlMstpSnonWnonDnon_medic_1";
[2.5, false] call OT_fnc_progressBar;
sleep 2.5;
player playActionNow "stop";
OT_ganjaPicking = nil;

if (isNull _plant || { !alive player } || { !isNull objectParent player } || { (player distance2D _plant) > 4 }) exitWith {};
[_plant, player] remoteExec ["OT_fnc_ganjaPick", 2];
