/*
    Description:
    Virtualizes an occupier FOB's garrison: registers a spawner for it (OT_fnc_spawnNATOFOB), so its
    soldiers and gun crews only exist while a player is within spawn distance, like the garrisons of
    the occupier's towns and bases. The garrison is stored in the FOB's entry of server "NATOfobs":
    [position, soldiers on foot, upgrades, crewed HMGs, crewed mortars] (an entry without the last
    two gets them from its upgrades, fully crewed). Once per FOB, cleared by OT_fnc_NATOclearFOB.
    A group already at the FOB (the soldiers who just set it up) is handed to the spawner as its
    soldiers on foot: they're despawned with the rest once no player is near.

    Parameters:
        _this # 0: ARRAY - The FOB's entry in server "NATOfobs"
        _this # 1: GROUP - (Optional) Soldiers already at the FOB

    Usage: [_fob] call OT_fnc_NATOregisterFOB;

    Returns: STRING - The spawner id
*/

params ["_fob", ["_group", grpNull]];
_fob params ["_pos", "", "_upgrades"];

if ((count _fob) < 5) then {
    _fob set [3, [0, 4] select ("HMG" in _upgrades)];
    _fob set [4, parseNumber ("Mortar" in _upgrades)];
};

if (_pos in OT_fobSpawners) exitWith { OT_fobSpawners get _pos };

private _id = format ["spawn%1", [_pos, OT_fnc_spawnNATOFOB, [_pos]] call OT_fnc_registerSpawner];
OT_fobSpawners set [_pos, _id];

if (!isNull _group) then {
    // Recorded as spawned without a break, the virtualization loop sees it whole
    isNil {
        {
            _x setVariable ["OT_fob", _pos];
            _x setVariable ["OT_fobRole", "foot"];
        } forEach (units _group);
        spawner setVariable [_id, [_group], false];
        private _index = OT_allSpawners findIf { (_x select 0) isEqualTo _id };
        if (_index > -1) then { (OT_allSpawners select _index) set [5, time] };
        OT_allSpawned pushBack _id;
    };
};

_id;
