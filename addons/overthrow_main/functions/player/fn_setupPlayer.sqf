OT_Map_EachFrameLastTownCheckPos = getPosATL player;
OT_Map_EachFrameLastTown = player call OT_fnc_nearestTown;

player call OT_fnc_statsSystem;
player call OT_fnc_wantedSystem;

[OT_fnc_perkSystem, player, 1] call CBA_fnc_waitAndExecute;
[OT_fnc_notificationLoop, player, 1] call CBA_fnc_waitAndExecute;

// Town info popup, one loop per body since this also runs on respawn and "Reset UI". The loop ends when the body dies
if ((missionNamespace getVariable ["OT_townCheckUnit", objNull]) isNotEqualTo player) then {
    OT_townCheckUnit = player;
    [OT_fnc_townCheckLoop, player, 5] call CBA_fnc_waitAndExecute;
};

player setVariable ["player_uid", getPlayerUID player, true];
player setUnitTrait ["UAVHacker", true];

disableUserInput false;
