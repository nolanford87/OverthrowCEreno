/*
    Description:
    A fishery's 15-minute cycle (OT_fnc_GUERLoop, after wages): its employees catch fish into its
    container (2 per employee, mostly small fish), and it sells the fish delivered to containers within
    50 m - up to 5 per employee, at 1.2x the shop price - for resistance funds. A fish left in its
    container is sold next cycle unless taken out.

    Parameters:
        _this # 0: STRING - Business name
        _this # 1: ARRAY - Business position (on land by the pier)
        _this # 2: NUMBER - Employees

    Usage: [_name, _pos, _num] call OT_fnc_fisheryCycle; (server)

    Returns: NUMBER - Income
*/

params ["_name", "_pos", "_num"];

// Its container, on land within 50 m (the position is on land by the pier); the same 50 m for finding
// it again and for what's delivered
private _container = (nearestObjects [_pos, [OT_item_CargoContainer], 50]) param [0, objNull];
if (isNull _container) then {
    private _land = [];
    for "_r" from 5 to 35 step 10 do {
        for "_dir" from 0 to 330 step 30 do {
            private _p = (_pos getPos [_r, _dir]) findEmptyPosition [0, 5, OT_item_CargoContainer];
            if (_p isNotEqualTo [] && { !surfaceIsWater _p }) exitWith { _land = _p };
        };
        if (_land isNotEqualTo []) exitWith {};
    };
    if (_land isEqualTo []) then { _land = _pos };
    _container = OT_item_CargoContainer createVehicle _land;
    [_container, (server getVariable ["generals", []]) param [0, ""]] call OT_fnc_setOwner;
    clearWeaponCargoGlobal _container;
    clearMagazineCargoGlobal _container;
    clearBackpackCargoGlobal _container;
    clearItemCargoGlobal _container;
};

// Sell what was delivered
private _income = 0;
private _toSell = 5 * _num;
{
    private _c = _x;
    {
        _x params ["_cls", "_amt"];
        if (_toSell <= 0) exitWith {};
        if (_cls in OT_fishSellItems) then {
            private _removed = [_c, _cls, _amt min _toSell] call OT_fnc_removeFromCargo;
            _income = _income + (round (([OT_nation, _cls, 0] call OT_fnc_getSellPrice) * 1.2) * _removed);
            _toSell = _toSell - _removed;
        };
    } forEach (_c call OT_fnc_unitStock);
} forEach (nearestObjects [_pos, [OT_item_CargoContainer], 50]);
if (_income > 0) then { [_income] call OT_fnc_resistanceFunds };

// Its own catch
for "_i" from 1 to (2 * _num) do {
    _container addItemCargoGlobal [selectRandomWeighted ["OT_Fish_Salema", 0.3, "OT_Fish_Ornate", 0.25, "OT_Fish_Mullet", 0.25, "OT_Fish_Mackerel", 0.2], 1];
};

_income;
