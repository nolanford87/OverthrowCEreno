//Setup our spawners
diag_log "Overthrow: Virtualization start";
{
    _x params ["_p", "_i"];
    [_p, OT_fnc_spawnBusinessEmployees, [_p, _i]] call OT_fnc_registerSpawner;
} forEach (OT_economicData);

diag_log format ["Overthrow: %1 businesses virtualized", count OT_economicData];

waitUntil { !isNil "OT_economyLoadDone" };

private _count = 0;
{
    _x params ["_cls", "_name"];
    private _pos = server getVariable [format ["factionrep%1", _cls], []];
    if (_pos isNotEqualTo []) then {
        _count = _count + 1;
        [_pos, OT_fnc_spawnFactionRep, [_cls, _name]] call OT_fnc_registerSpawner;
    };
} forEach (OT_allFactions);

diag_log format ["Overthrow: %1 faction reps virtualized", _count];

private _allobs = OT_NATOobjectives + OT_NATOcomms;
{
    _x params ["_pos", "_name"];
    [_pos, OT_fnc_spawnNATOObjective, [_pos, _name]] call OT_fnc_registerSpawner;
} forEach (_allobs);

diag_log format ["Overthrow: %1 objectives virtualized", count _allobs];

{
    private _pos = getMarkerPos _x;
    [_pos, OT_fnc_spawnNATOCheckpoint, [_pos, _x]] call OT_fnc_registerSpawner;
} forEach (OT_NATO_control);

diag_log format ["Overthrow: %1 checkpoints virtualized", count OT_NATO_control];

OT_townSpawners = [
    OT_fnc_spawnShops,
    OT_fnc_spawnCivilians,
    OT_fnc_spawnGendarmerie,
    OT_fnc_spawnPolice,
    OT_fnc_spawnCarDealers,
    OT_fnc_spawnGunDealer,
    OT_fnc_spawnAmbientVehicles,
    OT_fnc_spawnBoatDealers,
    OT_fnc_spawnStabilityObjects,
    OT_fnc_spawnOffice
];

{
    private _pos = server getVariable _x;
    private _town = _x;
    [
        _pos,
        {
            params ["_spawntown", "_spawnid"];
            private _handles = OT_townSpawners apply { [_spawntown, _spawnid] spawn _x };
            // Only return once every town spawner has finished, the town counts as spawning until then
            waitUntil { sleep 0.5; (_handles findIf { !scriptDone _x }) isEqualTo -1 };
        },
        [_town]
    ] call OT_fnc_registerSpawner;
} forEach (OT_allTowns);

diag_log format ["Overthrow: %1 towns virtualized", count OT_allTowns];

// Each town's mayor's office on the map (OT_fnc_officeCapture)
{
    private _layout = [_x] call OT_fnc_officeLayout;
    if (_layout isEqualTo []) then { continue };
    private _marker = createMarker [format ["%1-office", _x], ASLToAGL ((_layout select 0) select 1)];
    _marker setMarkerTypeLocal "loc_Bunker";
    _marker setMarkerColor "ColorBlack";
    [_x, [_x] call OT_fnc_officeTier] call OT_fnc_officeHide; // The map objects its tier removes, gone from the start
    [_x, [_x] call OT_fnc_officeTier] call OT_fnc_officeDoors; // The doors out of its compound locked
} forEach (OT_allTowns);

//Start Virtualization Loop
[
    "OT_virtualization_loop",
    "true",
    "
        {
            _x params ['_id', '_start', '_end', '', '', '_time'];
            private _spawnidx = OT_allSpawned find _id;
            private _val = (_spawnidx > -1);
            if ((_start select 0) isEqualTo (_end select 0)) then {
                if (_val) then {
                    if ((time - _time) > 30 && { (time - (spawner getVariable [format ['spawning%1', _id], -100000])) > 300 }) then {
                        if !([_start] call OT_fnc_inSpawnDistance) then {
                            OT_allSpawned deleteAt _spawnidx;
                            _x spawn OT_fnc_despawn;
                        };
                    };
                } else {
                    if ([_start] call OT_fnc_inSpawnDistance) then {
                        OT_allSpawned pushBack _id;
                        _x spawn OT_fnc_spawn;
                    };
                };
            } else {
                if (_val) then {
                    if ((time - _time) > 30 && { (time - (spawner getVariable [format ['spawning%1', _id], -100000])) > 300 }) then {
                        if !(([_start] call OT_fnc_inSpawnDistance) || { [_end] call OT_fnc_inSpawnDistance }) then {
                            OT_allSpawned deleteAt _spawnidx;
                            _x spawn OT_fnc_despawn;
                        };
                    };
                } else {
                    if (([_start] call OT_fnc_inSpawnDistance) || { ([_end] call OT_fnc_inSpawnDistance) }) then {
                        OT_allSpawned pushBack _id;
                        _x spawn OT_fnc_spawn;
                    };
                };
            };
        } forEach (OT_allSpawners);
    "
] call OT_fnc_addActionLoop;
