/*
    Description:
    A hunting spot's heat: how much shooting the poachers have heard there. It cools from full
    (OT_poacherFull) to nothing over OT_poacherCoolTime real seconds (OT_poacherCoolRate per second
    instead, if a test set it) and never goes above full. Worked out when asked, from the last value
    and the time since.

    Parameters:
        _this # 0: NUMBER - Spot index
        _this # 1: NUMBER - (Optional) Heat to add (default: 0)
        _this # 2: BOOL - (Optional) Reset it to nothing first (default: false)

    Usage: [_index, 1] call OT_fnc_poacherHeat; (server)

    Returns: NUMBER - The heat now
*/

params ["_index", ["_add", 0], ["_reset", false]];

if (isNil "OT_poacherHeat") then { OT_poacherHeat = createHashMap };
private _rate = missionNamespace getVariable ["OT_poacherCoolRate", OT_poacherFull / OT_poacherCoolTime];
(OT_poacherHeat getOrDefault [_index, [0, time]]) params ["_heat", "_stamp"];
_heat = (_heat - (_rate * ((time - _stamp) max 0))) max 0;
if (_reset) then { _heat = 0 };
_heat = (_heat + _add) min OT_poacherFull;

if (_heat <= 0) then {
    OT_poacherHeat deleteAt _index;
} else {
    OT_poacherHeat set [_index, [_heat, time]];
};
_heat
