/* ----------------------------------------------------------------------------
Function: incomeSystem
---------------------------------------------------------------------------- */
//Manages passive income for all players (Lease + taxes)
//Paid every 6 game hours, scaled to 1.5x the original real-time rate (time at 4x): at 24x a quarter of the full amount every 15 minutes (OT_fnc_timePace)
//The influence with it is scaled the same way, rounded up

waitUntil {
    sleep 1;
    server getVariable ["StartupType", ""] != "";
};
income_system_lasthour = date select 3;

[
    "income_system_loop",
    "_counter % 3 isEqualTo 0 && { income_system_lasthour isNotEqualTo (date select 3) }",
    "
        income_system_lasthour = date select 3;

        if (OT_fastTime) then {
            if (income_system_lasthour isEqualTo 19) then {
                setTimeMultiplier OT_timeMultiplierNight;
            };
            if (income_system_lasthour isEqualTo 7) then {
                setTimeMultiplier OT_timeMultiplierDay;
            };
        };

        if (income_system_lasthour in [0, 6, 12, 18]) then {
            private _inf = 1;
            private _total = 0;

            private _paceScale = 1.5 * (call OT_fnc_timePace);
            private _t = call OT_fnc_getTaxIncome;
            _total = round ((_t select 0) * _paceScale);
            _inf = ceil ((_t select 1) * _paceScale);

            private _totax = 0;
            private _tax = server getVariable ['taxrate', 0];
            if (_tax > 0) then {
                _totax = round (_total * (_tax / 100));
            };
            private _townTax = _totax;

            {
                private _owned = _x getVariable ['leasedata', []];
                private _lease = 0;
                {
                    _x params ['', '_cls', '', '_town'];
                    private _data = [_cls, _town] call OT_fnc_getRealEstateData;
                    _lease = _lease + (_data select 2);
                } forEach (_owned);
                _lease = round (_lease * _paceScale);
                if (_lease > 0) then {
                    private _tt = 0;
                    if (_tax > 0) then {
                        _tt = round (_lease * (_tax / 100));
                    };
                    _totax = _totax + _tt;
                    [_lease - _tt, 'Lease Income'] remoteExec ['OT_fnc_money', _x, false];
                };
            } forEach (allPlayers - (entities 'HeadlessClient_F'));

            [_totax] call OT_fnc_resistanceFunds;
            _total = _total - _townTax;

            private _numPlayers = count (allPlayers - (entities 'HeadlessClient_F'));
            if (_numPlayers > 0) then {
                if (isNil '_total') then { _total = 0 };
                private _perPlayer = round (_total / _numPlayers);
                if (_perPlayer > 0) then {
                    private _diff = server getVariable ['OT_difficulty', 1];
                    if (_diff isEqualTo 0) then { _perPlayer = round (_perPlayer * 1.2) };
                    if (_diff isEqualTo 2) then { _perPlayer = round (_perPlayer * 0.8) };

                    _inf remoteExec ['OT_fnc_influenceSilent', 0, false];
                    {
                        private _money = _x getVariable ['money', 0];
                        _x setVariable ['money', _money + _perPlayer, true];
                    } forEach (allPlayers - (entities 'HeadlessClient_F'));
                    format ['Tax income: $%1 (+%2 Influence)', [_perPlayer, 1, 0, true] call CBA_fnc_formatNumber, _inf] remoteExec ['OT_fnc_notifyMinor', 0, false];
                } else {
                    _inf remoteExec ['OT_fnc_influence', 0, false];
                };
            };
        };
    "
] call OT_fnc_addActionLoop;
