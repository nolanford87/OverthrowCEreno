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
    if (isNil "OT_huntLicenceLoopId") then { OT_huntLicenceLoopId = [OT_fnc_huntingLicenceLoop, 10] call CBA_fnc_addPerFrameHandler };
};

player setVariable ["player_uid", getPlayerUID player, true];
player setUnitTrait ["UAVHacker", true];

disableUserInput false;
