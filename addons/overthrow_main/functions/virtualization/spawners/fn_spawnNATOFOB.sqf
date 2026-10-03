/*
    Description:
    Spawns an occupier FOB's garrison while a player is within spawn distance (the spawner registered
    by OT_fnc_NATOregisterFOB): its soldiers on foot and the crews of its HMGs and mortar, as many as
    its stored garrison has left. The garrison is kept in the FOB's entry of server "NATOfobs":
    [position, soldiers on foot, upgrades, crewed HMGs, crewed mortars]. Deaths come off it
    (OT_fnc_NATOFOBunitLost), so a worn down FOB stays worn down.
    It tops up: what this spawner already has spawned isn't spawned again, so it's also run when an
    upgrade adds to a FOB that is spawned. The construction (flag, barriers, sandbags and the guns
    themselves, OT_fnc_NATOupgradeFOB) and the FOB's vehicle aren't virtualized.

    Parameters:
        _this # 0: ARRAY - FOB position
        _this # 1: STRING - Spawner id

    Usage: [_pos, _spawnid] spawn OT_fnc_spawnNATOFOB;
*/

params ["_pos", "_spawnid"];

private _fobOf = {
    (server getVariable ["NATOfobs", []]) select { (_x select 0) isEqualTo _pos } param [0, []];
};
// Its living units of a role spawned by this spawner (not ones from an earlier spawn still being despawned)
private _live = {
    params ["_role"];
    private _groups = spawner getVariable [_spawnid, []];
    allUnits select {
        (_x getVariable ["OT_fobRole", ""]) isEqualTo _role
        && { (_x getVariable ["OT_fob", []]) isEqualTo _pos }
        && { (group _x) in _groups }
    };
};
private _addGroup = {
    params ["_group"];
    spawner setVariable [_spawnid, (spawner getVariable [_spawnid, []]) + [_group], false];
};

// Soldiers on foot, one at a time. Each is counted and made without a break, so two of these
// running at once (a spawn and an upgrade) never make more than the stored garrison
private _group = grpNull;
private _done = false;
while { !_done } do {
    isNil {
        private _fob = call _fobOf;
        if (_fob isEqualTo [] || { !(_spawnid in OT_allSpawned) } || { (count (["foot"] call _live)) >= (_fob select 1) }) exitWith {
            _done = true;
        };
        if (isNull _group) then {
            _group = createGroup [blufor, true];
            [_group] call _addGroup;
        };
        private _civ = _group createUnit [selectRandom OT_NATO_Units_LevelOne, [[[_pos, 50]]] call BIS_fnc_randomPos, [], 0, "NONE"];
        _civ setVariable ["garrison", "HQ", false];
        _civ setVariable ["OT_fob", _pos];
        _civ setVariable ["OT_fobRole", "foot"];
        _civ setRank "LIEUTENANT";
        _civ setVariable ["VCOM_NOPATHING_Unit", true, false];
        _civ setBehaviour "SAFE";
    };
    if (!_done) then { sleep 0.2 };
};
if (!isNull _group && { (units _group) isNotEqualTo [] }) then {
    _group call OT_fnc_initMilitaryPatrol;
};

// Crews for its guns, up to the number of crewed guns it has left. A gun destroyed, taken by a
// player or with a body in it isn't crewed
{
    _x params ["_role", "_index", "_type"];
    isNil {
        private _fob = call _fobOf;
        if (_fob isEqualTo [] || { !(_spawnid in OT_allSpawned) }) exitWith {};
        private _crewed = [];
        { _crewed pushBackUnique (_x getVariable ["OT_fobGun", objNull]) } forEach ([_role] call _live);
        private _want = (_fob param [_index, 0]) - (count _crewed);
        if (_want <= 0) exitWith {};
        private _guns = (nearestObjects [_pos, [_type], 60]) select {
            alive _x
            && { (_x getVariable ["OT_fobStatic", []]) isEqualTo _pos }
            && { !(_x in _crewed) }
            && { !(_x call OT_fnc_hasOwner) }
            && { (crew _x) isEqualTo [] } // A dead gunner left in it takes the seat
        };
        {
            if (_want <= 0) exitWith {};
            _want = _want - 1;
            private _gun = _x;
            private _g = [_gun] call OT_fnc_createNATOCrew;
            [_g] call _addGroup;
            {
                _x setVariable ["OT_fob", _pos];
                _x setVariable ["OT_fobRole", _role];
                _x setVariable ["OT_fobGun", _gun];
            } forEach (crew _gun);
            if (_role isEqualTo "Mortar") then {
                {
                    _x disableAI "AUTOTARGET";
                    _x disableAI "FSM";
                    _x disableAI "AUTOCOMBAT";
                    _x setVariable ["NOAI", true, false];
                } forEach (crew _gun);
                _g setCombatMode "BLUE";
                [_gun, _g] spawn OT_fnc_NATOMortar;
            };
        } forEach _guns;
    };
} forEach [
    ["HMG", 3, OT_NATO_StaticGarrison_LevelOne select 0],
    ["Mortar", 4, OT_NATO_Mortar]
];
