params ["_sink"];

private _nozzle = _sink getVariable "ace_refuel_nozzle";
private _source = _nozzle getVariable "ace_refuel_source";

if ((typeOf _source) in OT_fuelPumps) then {
    // Only compare against the fuel level recorded during this refuel session, otherwise fuel burned
    // since the last visit to a pump would be refunded. ACE raises this about once a second while
    // refueling, so a different nozzle or a gap means a new session.
    (_sink getVariable ["ot_lastFuel", [objNull, 0, -100]]) params ["_lastNozzle", "_lastFuel", ["_lastTime", -100]];
    private _sameSession = (_lastNozzle isEqualTo _nozzle) && { (CBA_missionTime - _lastTime) < 5 };
    private _last = [fuel _sink, _lastFuel] select _sameSession;
    private _fueled = ((fuel _sink) - _last) max 0;
    private _litresFueled = _fueled * getNumber (configOf _sink >> "fuelCapacity");

    private _pricePer = [OT_nation, "FUEL", 100] call OT_fnc_getPrice;
    private _total = round (_pricePer * _litresFueled);

    //take money from nearest player
    private _player = objNull;
    private _close = -1;
    {
        private _dis = (_x distance _sink);
        if (_close isEqualTo -1 || _dis < _close) then {
            _player = _x;
            _close = _dis;
        };
    } forEach (allPlayers);
    private _money = _player getVariable ["money", 0];
    if (_money < _total) then {
        _nozzle setVariable ["ace_refuel_lastTickMissionTime", nil];
        _nozzle setVariable ["ace_refuel_isRefueling", false, true];
        "You cannot afford fuel" remoteExec ["OT_fnc_notifyMinor", _player];
        _sink setFuel _last;
    } else {
        [-_total] remoteExec ["OT_fnc_money", _player];
    };

    _sink setVariable ["ot_lastFuel", [_nozzle, fuel _sink, CBA_missionTime], false];
};
