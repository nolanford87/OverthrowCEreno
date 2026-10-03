/*
    Description:
    Sends every machine the wild ganja plants spawned right now (OT_ganjaPlants), for the "Harvest
    the ganja plant" action. Plants already deleted (despawned) are dropped.

    Usage: call OT_fnc_ganjaPublishPlants; (server)
*/

private _all = [];
{
    private _alive = (OT_ganjaZonePlants get _x) select { !isNull _x };
    OT_ganjaZonePlants set [_x, _alive];
    _all append _alive;
} forEach (keys OT_ganjaZonePlants);
if (_all isNotEqualTo (missionNamespace getVariable ["OT_ganjaPlants", []])) then {
    OT_ganjaPlants = _all;
    publicVariable "OT_ganjaPlants";
};
