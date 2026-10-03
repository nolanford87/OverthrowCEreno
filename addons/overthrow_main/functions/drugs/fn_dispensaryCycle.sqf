/*
    Description:
    A dispensary's 15-minute cycle (OT_fnc_GUERLoop, after wages): it sells to its customers from the
    stock players put in its container (or other containers within 50 m), at the town's drug price
    (OT_fnc_getDrugPrice), for resistance funds. Up to 3 ganja per employee (OT_dispensarySell); at
    level 2 its back room also moves up to 1 blow per employee. Legal: it costs nobody cover. Each sale
    is reported to the heat hook (OT_fnc_drugHeat) when there is one.

    Parameters:
        _this # 0: STRING - Dispensary (business name)
        _this # 1: ARRAY - Its position
        _this # 2: NUMBER - Employees (up to 20)

    Usage: [_name, _pos, _num] call OT_fnc_dispensaryCycle; (server)

    Returns: NUMBER - Income
*/

params ["_name", "_pos", "_num"];

private _level = [_name] call OT_fnc_dispensaryRegister; // Registered once bought, also from older builds
[_pos] call OT_fnc_dispensaryContainer;
private _town = _pos call OT_fnc_nearestTown;

private _income = 0;
{
    _x params ["_cls", "_heatType", "_minLevel"];
    if (_level < _minLevel) then { continue };
    private _toSell = (OT_dispensarySell getOrDefault [_cls, 0]) * _num;
    private _sold = 0;
    {
        if (_toSell <= 0) exitWith {};
        private _c = _x;
        {
            _x params ["_stockCls", "_amt"];
            if (_stockCls isEqualTo _cls) exitWith {
                private _removed = [_c, _cls, _amt min _toSell] call OT_fnc_removeFromCargo;
                _sold = _sold + _removed;
                _toSell = _toSell - _removed;
            };
        } forEach (_c call OT_fnc_unitStock);
    } forEach (nearestObjects [_pos, [OT_item_CargoContainer], 50]);
    if (_sold > 0) then {
        _income = _income + (_sold * ([_town, _cls] call OT_fnc_getDrugPrice));
        if (!isNil "OT_fnc_drugHeat") then { [_name, _heatType, _sold] call OT_fnc_drugHeat };
    };
} forEach [["OT_Ganja", "ganja", 1], ["OT_Blow", "blow", 2]];

if (_income > 0) then { [_income] call OT_fnc_resistanceFunds };
_income
