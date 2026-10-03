/*
    Description:
    Town survey for the mayor's office design (run as the "towns" QA suite, or [] call
    OTQA_fnc_dumpTowns): for every town, a line with its population, stability and flags, and the
    enterable buildings near its centre, biggest first. Lines start "OTTOWN|":
        OTTOWN|TOWN|name|population|stability|capital|sprawling|priority|houses within 300 m
        OTTOWN|BLD|town|class|positions|footprint m2|height|distance from the centre
    Then the classes of enterable buildings near town centres across the map, with counts:
        OTTOWN|CLASS|class|count|positions|footprint m2|height|towns
    Buildings: within 500 m with 4+ building positions (the distance is logged, so nearer cut-offs can be applied afterwards).

    Returns: ARRAY - [[name, code], ...] (one test, so the QA runner can run it as a suite)
*/

[
    ["Town survey for the mayor's office", {
        private _classes = createHashMap;
        {
            private _town = _x;
            private _pos = server getVariable [_town, [0, 0, 0]];
            private _pop = server getVariable [format ["population%1", _town], 0];
            private _stab = server getVariable [format ["stability%1", _town], 0];
            private _big = _town in (OT_capitals + OT_sprawling);
            private _houses = count (nearestTerrainObjects [_pos, ["HOUSE", "BUILDING"], 300, false]);
            diag_log format ["OTTOWN|TOWN|%1|%2|%3|%4|%5|%6|%7", _town, _pop, _stab, _town in OT_capitals, _town in OT_sprawling, _town in OT_NATO_priority, _houses];
            private _found = [];
            {
                private _b = _x;
                private _n = count (_b buildingPos -1);
                if (_n < 4) then { continue };
                (boundingBoxReal _b) params ["_min", "_max"];
                private _area = round (((_max select 0) - (_min select 0)) * ((_max select 1) - (_min select 1)));
                private _height = round ((_max select 2) - (_min select 2));
                _found pushBack [_area, typeOf _b, _n, _height, round (_b distance2D _pos)];
                private _c = _classes getOrDefault [typeOf _b, [0, _n, _area, _height, []]];
                _c set [0, (_c select 0) + 1];
                (_c select 4) pushBackUnique _town;
                _classes set [typeOf _b, _c];
            } forEach (nearestObjects [_pos, ["House", "Building"], 500]);
            _found sort false;
            {
                _x params ["_area", "_cls", "_n", "_height", "_dist"];
                diag_log format ["OTTOWN|BLD|%1|%2|%3|%4|%5|%6", _town, _cls, _n, _area, _height, _dist];
            } forEach _found;
        } forEach OT_allTowns;
        {
            _y params ["_count", "_n", "_area", "_height", "_towns"];
            diag_log format ["OTTOWN|CLASS|%1|%2|%3|%4|%5|%6", _x, _count, _n, _area, _height, count _towns];
        } forEach _classes;
        ["Towns surveyed", true, format ["%1 towns on %2", count OT_allTowns, worldName]] call OTQA_fnc_check;
    }, 120]
];
