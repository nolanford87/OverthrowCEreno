/*
    Description:
    A drug lab's 15-minute business cycle (OT_fnc_GUERLoop, after wages): its employees cook the blow
    precursors in containers within 50 m into blow, into its container (OT_fnc_drugLabContainer).
    Each employee cooks OT_drugLabPerCook (1) precursor, OT_drugLabCap (6) at most per cycle, each
    one making OT_drugLabYield (3) blow. Whatever it makes heats the lab up for the occupier
    (OT_fnc_drugHeat: [lab id, "blow", amount]). Shut after a raid (OT_fnc_drugOpShut), it cooks nothing.

    Parameters:
        _this # 0: STRING - Lab name
        _this # 1: ARRAY - Its position
        _this # 2: NUMBER - Employees (OT_fnc_GUERLoop caps them at 20)

    Usage: [_name, _pos, _num] call OT_fnc_drugLabCycle; (server)

    Returns: NUMBER - Blow made
*/

params ["_name", "_pos", "_num"];

private _site = _name call OT_fnc_drugLabData;
if (_site isEqualTo []) exitWith { 0 };
private _opId = _site select 0;
_name call OT_fnc_drugLabRegister;
if (([_opId] call OT_fnc_drugOpShut) > 0) exitWith { 0 }; // Raided and shut for a while (OT_fnc_drugRaid)
private _container = _name call OT_fnc_drugLabContainer;

private _want = ((_num max 0) * OT_drugLabPerCook) min OT_drugLabCap;
private _used = 0;
{
    if (_used >= _want) then { break };
    private _c = _x;
    {
        _x params ["_cls", "_amt"];
        if (_cls isEqualTo "OT_Precursors") exitWith {
            _used = _used + ([_c, _cls, _amt min (_want - _used)] call OT_fnc_removeFromCargo);
        };
    } forEach (_c call OT_fnc_unitStock);
} forEach (nearestObjects [_pos, [OT_item_CargoContainer], 50]);

private _qty = _used * OT_drugLabYield;
if (_qty > 0) then {
    _container addItemCargoGlobal ["OT_Blow", _qty];
    [_opId, "blow", _qty] call OT_fnc_drugHeat;
};
_qty;
