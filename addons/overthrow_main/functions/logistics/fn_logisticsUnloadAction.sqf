/*
    Description:
    Gives the player of a freight job an "Unload delivery cargo" action (client, from
    OT_fnc_logisticsStart) for as long as the job runs: shown within 40 m of the drop-off, in or
    within 15 m of a vehicle carrying the job's crates (OT_fnc_logisticsCargoVehicle); it sets every
    one of them down behind the vehicle (OT_fnc_logisticsUnload). Put back on the player's new body
    after a respawn.

    Parameters:
        _this # 0: STRING - Job id
        _this # 1: ARRAY - Drop-off position

    Usage: [_id, _toPos] remoteExec ["OT_fnc_logisticsUnloadAction", _player];
*/

params ["_id", "_toPos"];

if (!hasInterface) exitWith {};

OT_haulUnload = [_id, _toPos];
// The job flag can arrive a moment after this
private _wait = time + 10;
waitUntil { sleep 0.5; (player getVariable ["OT_logisticsActive", ""]) isEqualTo _id || { time > _wait } };

private _unit = objNull;
private _action = -1;
while { (player getVariable ["OT_logisticsActive", ""]) isEqualTo _id } do {
    if (_unit isNotEqualTo player) then {
        if (!isNull _unit) then { _unit removeAction _action };
        _unit = player;
        _action = _unit addAction [
            "<t color='#ffd27f'>Unload delivery cargo</t>",
            {
                params ["", "_caller"];
                OT_haulUnload params ["_id"];
                private _veh = [_caller, _id] call OT_fnc_logisticsCargoVehicle;
                if (isNull _veh) exitWith {};
                [_veh, _id] remoteExec ["OT_fnc_logisticsUnload", 2];
                "Unloading the delivery" call OT_fnc_notifyMinor;
            },
            nil, 6, true, true, "",
            "!isNil 'OT_haulUnload' && { (_this distance2D (OT_haulUnload select 1)) < 40 } && { !isNull ([_this, OT_haulUnload select 0] call OT_fnc_logisticsCargoVehicle) }"
        ];
    };
    sleep 2;
};
if (!isNull _unit) then { _unit removeAction _action };
if (!isNil "OT_haulUnload" && { (OT_haulUnload select 0) isEqualTo _id }) then { OT_haulUnload = nil };
