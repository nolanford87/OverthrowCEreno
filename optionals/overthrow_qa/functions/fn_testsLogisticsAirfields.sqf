/*
    Description:
    Logistics, airfield freight offices and long hauls (OT_fnc_logisticsBrokers, OT_fnc_logisticsOffers):
    each airfield has a freight office outside its fence within 1.5 km of its centre, staffed whoever
    holds the airfield; brokers offer long hauls to ports and airfields; every contract has the
    15-element format [id, fromPos, fromName, toPos, toName, crates, size, pay, timeLimit, danger,
    brokerId, kind, contraband, addon, gangId]. Part of the current QA tests. Run it as the host
    (offers are made on the server); it makes every broker's offers again and moves the player.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Logistics airfields: on the map, each airfield's 'Freight office' marker sits outside its fence, by a road" call OTQA_fnc_manual;
"Logistics airfields: drive to an airfield the occupier holds; its freight office broker talks ('Freight contracts') and you aren't in a restricted area there" call OTQA_fnc_manual;

// The map's runways from its ILS data (CfgWorlds): [[position on the runway every 50 m, ...], ...]
OTQA_air_runwayPoints = {
    private _points = [];
    private _read = {
        params ["_cfg"];
        private _ils = getArray (_cfg >> "ilsPosition");
        if ((count _ils) < 2) exitWith {};
        private _dir = getArray (_cfg >> "ilsDirection");
        private _len = sqrt (((_dir param [0, 0]) ^ 2) + ((_dir param [2, 1]) ^ 2)) max 0.001;
        private _ux = (_dir param [0, 0]) / _len;
        private _uy = (_dir param [2, 1]) / _len;
        private _along = [0];
        {
            private _xz = getArray (_cfg >> _x);
            for "_i" from 0 to (count _xz) - 2 step 2 do {
                _along pushBack ((((_xz select _i) - (_ils select 0)) * _ux) + (((_xz select (_i + 1)) - (_ils select 1)) * _uy));
            };
        } forEach ["ilsTaxiIn", "ilsTaxiOff"];
        for "_t" from (selectMin _along) to (selectMax _along) step 50 do {
            _points pushBack [(_ils select 0) + (_t * _ux), (_ils select 1) + (_t * _uy), 0];
        };
    };
    private _world = configFile >> "CfgWorlds" >> worldName;
    [_world] call _read;
    private _secondary = _world >> "SecondaryAirports";
    for "_i" from 0 to (count _secondary) - 1 do {
        if (isClass (_secondary select _i)) then { [_secondary select _i] call _read };
    };
    _points
};

[
    ["Logistics airfields: each airfield has a freight office outside it, within 1.5 km", {
        private _brokers = server getVariable ["logisticsBrokers", []];
        ["Logistics airfields: brokers picked the new way (version 4)", (server getVariable ["logisticsBrokersVersion", 0]) isEqualTo 4,
            str (server getVariable ["logisticsBrokersVersion", 0])] call OTQA_fnc_check;
        if (OT_airportData isEqualTo []) exitWith { format ["Logistics airfields: %1 has no airfields, nothing to test", worldName] call OTQA_fnc_manual };
        private _offices = _brokers select { (_x param [7, ""]) isNotEqualTo "" };
        private _missing = OT_allAirports select { private _a = _x; (_offices findIf { (_x select 7) isEqualTo _a }) isEqualTo -1 };
        ["Logistics airfields: every airfield has a freight office", _missing isEqualTo [],
            format ["%1 offices on %2: %3; missing %4", count _offices, worldName, _offices apply { _x select 1 }, _missing]] call OTQA_fnc_check;
        ["Logistics airfields: offices are named '<Airfield> Freight Office'", (_offices findIf { (_x select 1) isNotEqualTo format ["%1 Freight Office", _x select 7] }) isEqualTo -1,
            str (_offices apply { _x select 1 })] call OTQA_fnc_check;

        private _runway = call OTQA_air_runwayPoints;
        private _buildings = (missionNamespace getVariable ["OT_airportTerminals", []]) + ["Land_Airport_Tower_F", "Land_Airport_01_controlTower_F", "Land_Airport_02_controlTower_F", "Land_Hangar_F", "Land_Airport_01_hangar_F"];
        private _bad = [];
        private _report = [];
        {
            _x params ["_id", "_name", "_stand", "_loading", "_origin", "_dir", "", "_airfield"];
            private _air = OT_airportData select { (_x select 1) isEqualTo _airfield };
            if (_air isEqualTo []) then { _bad pushBack [_name, "airfield not found"]; continue };
            private _center = (_air select 0) select 0;
            private _shed = (missionNamespace getVariable ["OT_brokerSheds", createHashMap]) getOrDefault [_id, objNull];
            private _middle = if (isNull _shed) then { _origin } else { _shed modelToWorld [3.75, 3.35, 0] };
            private _dist = round (_middle distance2D _center);
            private _toRunway = if (_runway isEqualTo []) then { -1 } else { round selectMin (_runway apply { _x distance2D _middle }) };
            private _near = nearestObjects [_middle, _buildings, 100];
            private _problems = [];
            if (isNull _shed) then { _problems pushBack "no shed" };
            if (_dist < 300 || { _dist > 1500 }) then { _problems pushBack format ["%1 m from the centre", _dist] };
            if (_toRunway >= 0 && { _toRunway < 150 }) then { _problems pushBack format ["%1 m from the runway", _toRunway] };
            if (_near isNotEqualTo []) then { _problems pushBack format ["airfield buildings within 100 m: %1", _near apply { typeOf _x }] };
            if (_airfield in OT_NATO_priority && { _dist < 500 }) then { _problems pushBack "in the restricted area (500 m)" };
            if (!isOnRoad _loading) then { _problems pushBack "loading spot not on a road" };
            if (_problems isNotEqualTo []) then { _bad pushBack [_name, _problems] };
            _report pushBack format ["%1: %2 m from the centre, %3 m from the runway", _name, _dist, _toRunway];
        } forEach _offices;
        ["Logistics airfields: each office is 300 m - 1.5 km from its airfield, off its runway and away from its buildings", _bad isEqualTo [],
            format ["%1 | %2", _bad, _report]] call OTQA_fnc_check;
    }, 30],

    ["Logistics airfields: an occupier-held airfield's office is staffed and has contracts", {
        private _offices = (server getVariable ["logisticsBrokers", []]) select { (_x param [7, ""]) isNotEqualTo "" };
        if (_offices isEqualTo []) exitWith { "Logistics airfields: no airfield offices, the occupier-held test was skipped" call OTQA_fnc_manual };
        // One the occupier holds; if it holds none, hand one back to it for the test
        private _abandoned = server getVariable ["NATOabandoned", []];
        private _held = _offices select { !((_x select 7) in _abandoned) };
        private _handedBack = "";
        if (_held isEqualTo []) then {
            _held = [_offices select 0];
            _handedBack = (_offices select 0) select 7;
            server setVariable ["NATOabandoned", _abandoned - [_handedBack], true];
        };
        (_held select 0) params ["_id", "_name", "_stand", "", "", "", "", "_airfield"];
        ["Logistics airfields: the airfield is occupier-held", !(_airfield in (server getVariable ["NATOabandoned", []])), _airfield] call OTQA_fnc_check;

        private _home = getPosATL player;
        player setPosATL ((_stand getPos [25, 0]) findEmptyPosition [0, 40, "CAManBase"]);
        private _civ = objNull;
        private _timeout = time + 30;
        waitUntil { sleep 1; _civ = (allUnits select { (_x getVariable ["OT_broker", ""]) isEqualTo _id }) param [0, objNull]; !isNull _civ || { time > _timeout } };
        ["Logistics airfields: the office's broker is there, alive and civilian", !isNull _civ && { alive _civ } && { (side _civ) isEqualTo civilian },
            format ["%1: %2, %3", _name, _civ, if (isNull _civ) then { "-" } else { side _civ }]] call OTQA_fnc_check;
        server setVariable [format ["logisticsOffers%1", _id], [], true];
        private _offers = [_id] call OT_fnc_logisticsOffers;
        ["Logistics airfields: the office has contracts", _offers isNotEqualTo [], str (_offers apply { _x select 4 })] call OTQA_fnc_check;
        player setPosATL _home;
        if (_handedBack isNotEqualTo "") then {
            server setVariable ["NATOabandoned", (server getVariable ["NATOabandoned", []]) + [_handedBack], true];
        };
    }, 60],

    ["Logistics airfields: long hauls to ports and airfields, the 15-element contract format", {
        private _brokers = server getVariable ["logisticsBrokers", []];
        // The long-haul destinations' names: town docks, fisheries, airfields' offices
        private _longNames = (OT_townData select { (server getVariable [format ["activepiersin%1", _x select 1], []]) isNotEqualTo [] }) apply { format ["%1 docks", _x select 1] };
        _longNames append OT_fisheries;
        _longNames append ((_brokers select { (_x param [7, ""]) isNotEqualTo "" }) apply { _x select 1 });
        private _longPos = [];
        {
            _x params ["_pos", "_town"];
            private _piers = server getVariable [format ["activepiersin%1", _town], []];
            if (_piers isNotEqualTo []) then { _longPos pushBack (_piers select 0) };
        } forEach OT_townData;
        { if ((_x select 1) in OT_fisheries) then { _longPos pushBack (_x select 0) } } forEach OT_economicData;
        { if ((_x param [7, ""]) isNotEqualTo "") then { _longPos pushBack (_x select 3) } } forEach _brokers;

        private _all = [];
        private _without = [];
        private _payBad = [];
        {
            _x params ["_id", "_name", "", "_loading"];
            server setVariable [format ["logisticsOffers%1", _id], [], true]; // Made again now
            private _offers = [_id] call OT_fnc_logisticsOffers;
            _all append _offers;
            // Is there a long haul to be had: a port or airfield over 1.5 km away, reachable by road
            private _possible = (_longPos findIf { (_x distance2D _loading) > 1500 && { [_loading, _x] call OT_fnc_regionIsConnected } }) > -1;
            private _longs = _offers select { (_x select 4) in _longNames && { (_x param [11, ""]) isEqualTo "" } };
            if (_possible && { _longs isEqualTo [] }) then { _without pushBack _name };
            // A long haul pays at least the usual rate for its distance and load, with at least the usual time
            {
                _x params ["", "_from", "", "_to", "_toName", "_crates", "", "_pay", "_time"];
                ([_from, _to, _crates] call OT_fnc_logisticsPay) params ["_basePay", "_baseTime"];
                if (_pay < _basePay || { _time < _baseTime }) then { _payBad pushBack [_name, _toName, _pay, _basePay, _time, _baseTime] };
            } forEach _longs;
        } forEach _brokers;
        ["Logistics airfields: every broker offers a long haul to a port or airfield when one can be had", _without isEqualTo [],
            format ["%1 of %2 brokers without one: %3", count _without, count _brokers, _without]] call OTQA_fnc_check;
        ["Logistics airfields: long hauls pay and allow at least the usual for their distance and load", _payBad isEqualTo [], str _payBad] call OTQA_fnc_check;
        private _toAirfields = { (_x select 4) in ((_brokers select { (_x param [7, ""]) isNotEqualTo "" }) apply { _x select 1 }) } count _all;
        private _toPorts = { ((_x select 4) in OT_fisheries) || { ((_x select 4) find " docks") > -1 } } count _all;
        ["Logistics airfields: some contracts go to airfields and some to ports", (OT_airportData isEqualTo [] || { _toAirfields > 0 }) && { OT_piers isEqualTo [] || { _toPorts > 0 } },
            format ["%1 to airfields, %2 to ports, of %3", _toAirfields, _toPorts, count _all]] call OTQA_fnc_check;

        // The format: 15 elements; a legal contract without an add-on offer ends "", "", [], ""
        private _badFormat = _all select {
            (count _x) isNotEqualTo 15
            || { !((_x select 11) isEqualType "") } || { !((_x select 12) isEqualType "") }
            || { !((_x select 13) isEqualType []) } || { !((_x select 14) isEqualType "") }
            || { (_x select 11) isEqualTo "" && { (_x select 13) isEqualTo [] } && { [_x select 12, _x select 14] isNotEqualTo ["", ""] } }
        };
        ["Logistics airfields: every contract has the 15-element format", _all isNotEqualTo [] && { _badFormat isEqualTo [] },
            format ["%1 contracts, %2 bad: %3", count _all, count _badFormat, _badFormat apply { [_x select 0, count _x, _x select [11, 4]] }]] call OTQA_fnc_check;
    }, 120]
]
