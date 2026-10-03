OT_Map_EachFrameLastTownCheckPos = getPosATL player;
OT_Map_EachFrameLastTown = player call OT_fnc_nearestTown;

player call OT_fnc_statsSystem;

// Systems tied to the player's body are only started once per body. This also runs on respawn and from
// "Reset UI", where running them again stacked event handlers and loops (and made the player captive again)
if ((missionNamespace getVariable ["OT_setupPlayerUnit", objNull]) isNotEqualTo player) then {
    OT_setupPlayerUnit = player;
    player call OT_fnc_wantedSystem;
    [OT_fnc_perkSystem, player, 1] call CBA_fnc_waitAndExecute;
    [OT_fnc_notificationLoop, player, 1] call CBA_fnc_waitAndExecute;
    [OT_fnc_townCheckLoop, player, 5] call CBA_fnc_waitAndExecute; // Town info popup
    call OT_fnc_garageInitPlayer; // Virtual garage actions
    // Hunting: pick up a dead animal as raw meat, the licence counting down
    player addAction ["Pick up the carcass", { [cursorObject] spawn OT_fnc_huntPickup }, nil, 1.5, true, true, "",
        "isNull objectParent _this && { !isNull cursorObject } && { !alive cursorObject } && { (typeOf cursorObject) in OT_huntMeat } && { (_this distance cursorObject) < 3.5 } && { !(cursorObject getVariable ['OT_pickingUp', false]) }"];
    // Drugs: harvest a wild ganja plant within 3 m (OT_fnc_ganjaHarvest)
    player addAction ["Harvest the ganja plant", { [] spawn OT_fnc_ganjaHarvest }, nil, 1.5, true, true, "",
        "isNull objectParent _this && { isNil 'OT_ganjaPicking' } && { ((missionNamespace getVariable ['OT_ganjaPlants', []]) findIf { !isNull _x && { (_this distance2D _x) < 3 } }) > -1 }"];
    if (isNil "OT_huntLicenceLoopId") then { OT_huntLicenceLoopId = [OT_fnc_huntingLicenceLoop, 10] call CBA_fnc_addPerFrameHandler };
    // Fishing: the driver of a fishing boat casts its net, once every 15 seconds, going slowly
    player addAction ["Cast the net", {
        params ["_caller"];
        private _boat = vehicle _caller;
        _boat setVariable ["OT_netReady", time + 15];
        [_boat, _caller] remoteExec ["OT_fnc_castNet", 2];
    }, nil, 1.5, false, true, "",
        "driver (vehicle _this) isEqualTo _this && { (typeOf vehicle _this) in OT_fishingBoats } && { (speed vehicle _this) < 12 } && { time > ((vehicle _this) getVariable ['OT_netReady', 0]) }"];
};

player setVariable ["player_uid", getPlayerUID player, true];
player setUnitTrait ["UAVHacker", true];

disableUserInput false;
