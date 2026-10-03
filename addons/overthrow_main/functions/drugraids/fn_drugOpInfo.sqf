/*
    Description:
    The heat and raid lines for a drug operation's business info (OT_fnc_showBusinessInfo, every
    machine): shut after a raid (how long for), the occupier's heat on it and the raid chance that
    makes (OT_fnc_drugRaidChance), who would come, and the cooldown since the last raid.

    Parameters:
        _this # 0: STRING - Business name (a dispensary or a drug lab)

    Usage: _text = _text + ([_name] call OT_fnc_drugOpInfo);

    Returns: STRING - Structured text lines, "" for a business that's no drug operation
*/

params ["_name"];

private _opId = _name;
if (_name in (missionNamespace getVariable ["OT_drugLabs", []])) then { _opId = (_name call OT_fnc_drugLabData) param [0, ""] };
if (_opId isEqualTo "" || { ((server getVariable ["drugOps", []]) findIf { (_x select 0) isEqualTo _opId }) < 0 }) exitWith { "" };
([_opId] call OT_fnc_drugHeatGet) params ["_heat", "_shut", "_cooldown"];

private _text = "";
if (_shut > 0) then {
    _text = _text + format ["<t size='0.65' color='#ff6060'>RAIDED: shut for another %1 min, nothing is made or sold meanwhile</t><br/>", ceil (_shut / 60)];
};
if (_heat < OT_drugRaidHeatMin) then {
    _text = _text + format ["<t size='0.65'>Occupier heat: %1 (no raids under %2)</t><br/>", round _heat, OT_drugRaidHeatMin];
} else {
    private _who = ["the gendarmerie", "the military"] select (_heat >= OT_drugRaidMilitaryHeat);
    private _chance = [_opId] call OT_fnc_drugRaidChance;
    if (_chance > 0) then {
        _text = _text + format ["<t size='0.65' color='#ffb060'>Occupier heat: %1, a raid by %2 is %3%% likely every %4 min (less the more stable the town)</t><br/>", round _heat, _who, round _chance, round (OT_drugRaidRollEvery / 60)];
    } else {
        _text = _text + format ["<t size='0.65'>Occupier heat: %1, %2 would come</t><br/>", round _heat, _who];
    };
};
if (_cooldown > 0) then {
    _text = _text + format ["<t size='0.65'>No raid for another %1 min after the last</t><br/>", ceil (_cooldown / 60)];
};
_text
