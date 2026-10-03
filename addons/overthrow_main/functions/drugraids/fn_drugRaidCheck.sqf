/*
    Description:
    The occupier decides whether to raid a drug operation (OT_fnc_drugRaid). Rolled every
    OT_drugRaidRollEvery real seconds (5 minutes) by OT_fnc_initDrugRaids:
    - One raid at a time ("drugRaidTarget"), and none while the occupier is fighting a QRF or has a
      counter-attack on the way
    - The target is the operation with the highest chance (OT_fnc_drugRaidChance: owned, hot, not
      shut or in cooldown; the hotter it is and the less stable its town, the likelier), rolled once
    - Who comes depends on its heat: the gendarmerie under OT_drugRaidMilitaryHeat, the military from
      it. The raid costs its strength (OT_drugRaidStrength) in resources, which the occupier must have
    OT_drugRaidChance holds the last chance rolled against, for the QA tests.

    Parameters:
        _this # 0: BOOL - Skip the chance, cooldowns and resource check (QA tests), default false
        _this # 1: STRING - Operation to raid instead of the likeliest one (QA tests), default ""
        _this # 2: NUMBER - Warning time in seconds instead of the intelligence-based one (QA tests),
            default -1

    Usage: [] call OT_fnc_drugRaidCheck; (server)

    Returns: BOOL - Was a raid started
*/

params [["_force", false, [false]], ["_opId", "", [""]], ["_warning", -1, [0]]];

if ((server getVariable ["drugRaidTarget", ""]) isNotEqualTo "") exitWith { false };
private _ops = server getVariable ["drugOps", []];

private _chance = 0;
if (_opId isEqualTo "") then {
    // The operation most likely to be raided
    {
        private _c = [_x select 0] call OT_fnc_drugRaidChance;
        if (_c > _chance) then { _chance = _c; _opId = _x select 0 };
    } forEach _ops;
} else {
    _chance = [_opId] call OT_fnc_drugRaidChance;
};
OT_drugRaidChance = _chance; // For the QA tests and debugging
if (_opId isEqualTo "") exitWith { false };
if ((_ops findIf { (_x select 0) isEqualTo _opId }) < 0 || { !([_opId] call OT_fnc_drugOpOwned) }) exitWith { false };

private _heat = ([_opId] call OT_fnc_drugHeatGet) select 0;
private _forces = ["police", "military"] select (_heat >= OT_drugRaidMilitaryHeat);
private _strength = OT_drugRaidStrength get _forces;
private _resources = server getVariable ["NATOresources", 2000];

private _go = _force || {
    call {
        if (_chance <= 0) exitWith { false };
        if ((server getVariable ["NATOattacking", ""]) isNotEqualTo "" || { (server getVariable ["NATOcounterTarget", ""]) isNotEqualTo "" }) exitWith { false };
        if (_resources < _strength) exitWith { false };
        private _roll = missionNamespace getVariable ["OT_drugRaidRoll", random 100]; // Set only by the QA tests
        _roll < _chance;
    };
};
if !(_go) exitWith { false };

server setVariable ["NATOresources", _resources - _strength];
server setVariable ["drugRaidTarget", _opId, true];
diag_log format ["Overthrow: %1 raiding drug operation %2 (%3, heat %4, chance was %5%%)", OT_NATO_name, _opId, _forces, round _heat, round _chance];
// Its state exists from now on (filled in by OT_fnc_drugRaid), not only once the spawned script runs
OT_drugRaidState = createHashMapFromArray [["op", _opId], ["phase", "starting"], ["cancel", false]];
[_opId, _forces, _strength, _warning, OT_drugRaidState] spawn OT_fnc_drugRaid;
true
