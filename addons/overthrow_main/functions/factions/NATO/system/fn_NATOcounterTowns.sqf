/*
    Author: ThomasAngel, ARMAZac

    Description:
    The occupier decides whether to counter-attack a town the resistance holds (OT_fnc_NATOCounterTown).
    Run on every NATO turn (every 8-17 minutes when nothing else is going on).
    - Only once the resistance has captured its first occupier base (an objective or airfield, not a
      tower or town): "NATOcounterUnlocked", saved, stays on even if the base is lost again
    - One counter-attack at a time, at least 25 real minutes after the last one started and 10 after
      the last QRF ended
    - The target is the least defended resistance town not in a grace period (OT_fnc_NATOcounterTarget)
    - It costs its strength: the town's population x 3 (x 4 over 1000 controlled population, x 5 over
      2000), between 300 and 1200, and the occupier needs 300 resources at least (it spends what it
      has, up to the strength)
    - Chance on each turn: 15% + 5% per town the resistance holds + 1% per 100 resources, at most 80%.
      Mid-game (5 towns, 1500 resources: 55%) that's one about every 40-50 real minutes

    Parameters:
        _this # 0: BOOL - Skip the chance, cooldowns and resource check (QA tests), default false
        _this # 1: STRING - Town to attack instead of the least defended one (QA tests), default ""
        _this # 2: NUMBER - Warning time in seconds instead of the intelligence-based one (QA tests),
            default -1

    Usage: [] call OT_fnc_NATOcounterTowns;

    Returns: Boolean - was a town counter-attacked
*/

params [["_force", false, [false]], ["_town", "", [""]], ["_warning", -1, [0]]];

private _abandoned = server getVariable ["NATOabandoned", []];

// Unlocked by the first base the resistance captures (also caught here for older saves)
if !(server getVariable ["NATOcounterUnlocked", false]) then {
    if ((OT_objectiveData + OT_airportData) findIf { (_x select 1) in _abandoned } > -1) then {
        server setVariable ["NATOcounterUnlocked", true, true];
    };
};
if !(server getVariable ["NATOcounterUnlocked", false]) exitWith { false };
if ((server getVariable ["NATOcounterTarget", ""]) isNotEqualTo "") exitWith { false };

private _resources = server getVariable ["NATOresources", 2000];
private _held = { _x in _abandoned } count OT_allTowns;
private _chance = ((15 + (5 * _held) + (_resources / 100)) max 0) min 80;
OT_counterTownChance = _chance; // For the QA tests and debugging

private _go = _force || {
    call {
        if (_resources < 300) exitWith { false };
        if ((time - (server getVariable ["NATOlastTownCounter", 0])) < 1500) exitWith { false };
        if ((time - (server getVariable ["NATOlastattack", 0])) < 600) exitWith { false };
        private _roll = missionNamespace getVariable ["OT_counterTownRoll", random 100]; // Set only by the QA tests
        _roll < _chance;
    };
};
if !(_go) exitWith { false };
if (_town isEqualTo "") then { _town = [] call OT_fnc_NATOcounterTarget };
if (_town isEqualTo "") exitWith { false };

private _population = server getVariable [format ["population%1", _town], 100];
private _popControl = call OT_fnc_getControlledPopulation;
private _multiplier = 3;
if (_popControl > 1000) then { _multiplier = 4 };
if (_popControl > 2000) then { _multiplier = 5 };
private _strength = ((_population * _multiplier) max 300) min 1200;
if (!_force) then { _strength = _strength min _resources };

server setVariable ["NATOresources", _resources - _strength];
server setVariable ["NATOcounterTarget", _town, true];
server setVariable ["NATOlastTownCounter", time, true];
diag_log format ["Overthrow: %1 counter-attacking %2 (strength %3, chance was %4%%)", OT_NATO_name, _town, _strength, round _chance];
[_town, _strength, _warning] spawn OT_fnc_NATOCounterTown;
true;
