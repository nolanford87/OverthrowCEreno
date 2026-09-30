params ["_i", "_s", "_e", "_c", "_p"];
private _groups = spawner getVariable [_i, []];
spawner setVariable [_i, [], false];
{
    // Cleanup a group
    if (_x isEqualType grpNull) then {
        private _units = units _x;
        if (_units isEqualTo []) then {
            [_x] call OT_fnc_cleanupEmptyGroup;
        };
        {
            if !(_x call OT_fnc_hasOwner) then {
                [_x] call OT_fnc_cleanupUnit;
                sleep 0.1;
            };
        } forEach (_units);
        continue;
    };

    // Cleanup a vehicle / object (unless it's already gone: stored in the garage, a cleaned up wreck...)
    if (_x isEqualType objNull) then {
        if (isNull _x) then { continue };
        if !(_x call OT_fnc_hasOwner) then {
            [_x] call OT_fnc_cleanupVehicle;
        };
        continue;
    };

    // Cleanup a marker
    if (_x isEqualType "") then {
        deleteMarker _x;
        continue;
    };

    // We don't know what it is
    diag_log format ["Overthrow: Failed to despawn %1", _x];
} forEach (_groups);
