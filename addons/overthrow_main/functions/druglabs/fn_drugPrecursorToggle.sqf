/*
    Description:
    Switches a resistance-owned industrial business (OT_precursorBusinesses) to making blow precursors
    as well as its usual output, or back (server variable "precursorsAt", OT_fnc_drugPrecursorCycle).
    From the main menu's button at the business (OT_fnc_manageArea).

    Parameters:
        _this # 0: STRING - Business name
        _this # 1: BOOL - (Optional) On or off, default: the other way round

    Usage: [_name] remoteExec ["OT_fnc_drugPrecursorToggle", 2];

    Returns: BOOL - Whether it makes precursors now
*/

params ["_name", ["_on", -1, [true, 0]]];

private _at = server getVariable ["precursorsAt", []];
if (_on isEqualType 0) then { _on = !(_name in _at) };
if !(_name in OT_precursorBusinesses) exitWith { false };
if (_on && { !(_name in (server getVariable ["GEURowned", []])) }) exitWith { false };

if (_on) then {
    _at pushBackUnique _name;
    format ["%1 now makes blow precursors as well ($%2 of chemicals each)", _name, OT_precursorCost] remoteExec ["OT_fnc_notifyMinor", 0, false];
} else {
    _at = _at - [_name];
    format ["%1 no longer makes blow precursors", _name] remoteExec ["OT_fnc_notifyMinor", 0, false];
};
server setVariable ["precursorsAt", _at, true];
_on;
