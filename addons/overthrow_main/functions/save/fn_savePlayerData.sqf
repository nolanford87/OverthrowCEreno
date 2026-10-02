params ["_player"];
if !(_player getVariable ["OT_loaded", false]) exitWith {};

private _uid = getPlayerUID _player;
private _data = [];

// Smuggling deposits whose job no longer runs (the game was loaded mid-job, or it was delivered while
// they were away, OT_fnc_logisticsSettle): paid back now, before their money is saved
if (isServer) then {
    isNil {
        private _deposits = server getVariable ["logisticsDeposits", []];
        private _jobs = missionNamespace getVariable ["OT_logisticsJobs", createHashMap];
        private _due = _deposits select { (_x select 0) isEqualTo _uid && { !((_x select 2) in _jobs) } };
        if (_due isNotEqualTo []) then {
            private _total = 0;
            { _total = _total + (_x select 1) } forEach _due;
            server setVariable ["logisticsDeposits", _deposits - _due, true];
            _player setVariable ["money", (_player getVariable ["money", 0]) + _total, true];
            format ["Smuggling deposit returned: +$%1", [_total, 1, 0, true] call CBA_fnc_formatNumber] remoteExec ["OT_fnc_notifyMinor", _player, false];
        };
    };
};

{
    private _v = _player getVariable _x;
    if (!isNil "_v") then {
        if (_x isEqualTo "home" && !(_v isEqualType [])) then {
            private _owned = _player getVariable ["owned", []];
            if (_owned isEqualTo []) then {
                diag_log format ["Warning: Player %1 owns no buildings to be set as home", name _player];
                //fallback to current pos
                _v = getPos _player;
            } else {
                private _buildid = _owned select 0;
                private _pos = buildingpositions getVariable [_buildid, []];
                if (_pos isEqualTo []) then {
                    //fallback to current pos (this runs on the server, where player is null on a dedicated server)
                    _v = getPos _player;
                } else {
                    _v = _pos;
                };
            };
        };
        _data pushBack [_x, _v];
    };
} forEach (allVariables _player select {
    _x = toLower _x;
    !(_x in ["ot_loaded", "morale", "player_uid", "hiding", "randomValue", "saved3deninventory", "babe_em_vars", "marta_reveal", "ot_beingsearched", "ot_logisticsactive", "ot_killedby"])
        && { !("diwako_dui" in _x) } // Diwako DUI
        && { !("bettinv_" in _x) } // Better Inventory..?
        && { !("emr_main" in _x) } // Enhanced Movement rework
        && { !((_x select [0, 4]) in ["ace_", "cba_", "bis_", "aur_", "l_es"]) }
        && { !((_x select [0, 3]) in ["sa_", "ar_"]) }
        && { (_x select [0, 11]) != "missiondata" }
        && { !((_x select [0, 9]) in ["seencache", "essp_core"]) };
});

players_NS setVariable [_uid, _data, true];
players_NS setVariable [format ["loadout%1", _uid], getUnitLoadout _player, true];
