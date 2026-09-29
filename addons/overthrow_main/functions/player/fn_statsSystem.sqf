disableSerialization;

private _layer = ["stats"] call BIS_fnc_rscLayer;
_layer cutRsc ["OT_statsHUD", "PLAIN", 0, false];

// Only the newest stats loop keeps running, this is also run on respawn and from "Reset UI"
OT_statsLoopId = (missionNamespace getVariable ["OT_statsLoopId", 0]) + 1;

[
    { !isNull (uiNamespace getVariable "OT_statsHUD") },
    {

        disableSerialization;
        private _display = uiNamespace getVariable "OT_statsHUD";
        private _setText = _display displayCtrl 1001;
        _setText ctrlSetBackgroundColor [0, 0, 0, 0];

        [OT_fnc_statsSystemLoop, _this, 1] call CBA_fnc_waitAndExecute;
    },
    [_this, OT_statsLoopId]
] call CBA_fnc_waitUntilAndExecute;
