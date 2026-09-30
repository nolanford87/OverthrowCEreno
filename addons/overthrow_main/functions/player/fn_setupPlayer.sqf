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
};

player setVariable ["player_uid", getPlayerUID player, true];
player setUnitTrait ["UAVHacker", true];

disableUserInput false;
