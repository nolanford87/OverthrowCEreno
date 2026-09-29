params ["_input", "_num", "_pos"];
if (_num isEqualTo 0) exitWith { true };
if (_num < 1) then { _num = 1 };
private _gotit = false;
{
    if (_gotit) exitWith {};
    private _c = _x;
    {
        _x params ["_cls", "_amt"];
        if (_cls == _input && _amt >= _num) exitWith {
            // The stock also counts backpacks etc. in the container, so take from those too
            _gotit = ([_c, _cls, _num] call OT_fnc_removeFromCargo) >= _num;
        };
    } forEach (_c call OT_fnc_unitStock);
} forEach (_pos nearObjects [OT_item_CargoContainer, 50]);
_gotit;
