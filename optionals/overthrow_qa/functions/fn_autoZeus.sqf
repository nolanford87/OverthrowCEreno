/*
    Description:
    With the QA addon loaded, every player gets Zeus (server, from postInit): the mission's Zeus
    module (zeusCurator) goes to the first player, anyone else gets a module of their own. Checked
    every 10 seconds, so players who join later or respawn get it back. Everything already in the
    mission is made editable once; new things are added by the mission's own code (allCurators).

    Usage: automatic (CfgFunctions postInit)
*/

if (!isServer) exitWith {};

[] spawn {
    waitUntil { sleep 1; !isNil "OT_NATOInitDone" || { time > 300 } };
    private _setUp = [];
    while { true } do {
        {
            private _player = _x;
            if (!isNull (getAssignedCuratorLogic _player)) then { continue };
            // A module nobody (alive) has: the mission's first, else one made for them
            private _free = allCurators select { isNull (getAssignedCuratorUnit _x) || { !alive (getAssignedCuratorUnit _x) } };
            private _curator = _free param [0, objNull];
            if (isNull _curator) then {
                private _group = createGroup [sideLogic, true];
                _curator = _group createUnit ["ModuleCurator_F", [0, 0, 0], [], 0, "NONE"];
                _curator setVariable ["Addons", 3, true];
                _curator setVariable ["owner", "", true];
            };
            if (!isNull (getAssignedCuratorUnit _curator)) then { unassignCurator _curator };
            _player assignCurator _curator;
            if !(_curator in _setUp) then {
                _curator addCuratorEditableObjects [allUnits + vehicles, true];
                _setUp pushBack _curator;
            };
            "Zeus enabled (Overthrow QA tools)" remoteExec ["OT_fnc_notifyMinor", _player, false];
            diag_log format ["Overthrow QA: Zeus given to %1", name _player];
        } forEach ((allPlayers - (entities "HeadlessClient_F")) select { alive _x });
        sleep 10;
    };
};
