/*
    Description:
    Probes every mayor's office candidate building (all four maps) on Altis, for the office
    templates: moves the host to open, flat ground on the main airfield away from the occupier's
    men, then for each class spawns it, maps it to the RPT and deletes it before the next. Run as
    the "offices" QA suite. Lines start "OTPROBE2|", all in the building's own coordinates:
        OTPROBE2|START|class|bbox min|bbox max
        OTPROBE2|DOORS|class|count|[[x,y,z], ...]           (Door_N_trigger memory points)
        OTPROBE2|POS|class|count|[[x,y,z], ...]             (building positions)
        OTPROBE2|LEVELS|class|[z, ...]                      (floor heights, from the building positions)
        OTPROBE2|ROW|class|level z|y|row                    (1 m cells: '#' wall, '.' floor, ' ' nothing)
        OTPROBE2|END|class

    Returns: ARRAY - [[name, code, seconds]] (one test, so the QA runner can run it as a suite)
*/

OTQA_probeOffices_classes = [
    // Altis and Malden (Malden's coloured versions checked against the plain ones)
    "Land_i_Stone_HouseBig_V1_F", "Land_i_House_Big_02_V1_F", "Land_u_House_Big_02_V1_F", "Land_i_House_Big_01_V1_F",
    "Land_u_House_Big_01_V1_F", "Land_i_Shop_01_V1_F", "Land_u_Shop_01_V1_F", "Land_i_Shop_02_V1_F", "Land_u_Shop_02_V1_F",
    "Land_Research_HQ_F", "Land_Offices_01_V1_F", "Land_Hospital_main_F", "Land_Supermarket_01_malden_F",
    "Land_i_House_Big_01_b_blue_F", "Land_i_House_Big_02_b_blue_F", "Land_i_Shop_02_b_blue_F",
    // Tanoa
    "Land_House_Big_01_F", "Land_House_Small_01_F", "Land_House_Small_04_F", "Land_School_01_F", "Land_House_Big_04_F",
    "Land_House_Big_03_F", "Land_Hotel_01_F", "Land_Hotel_02_F", "Land_House_Big_02_F", "Land_Shop_City_04_F",
    "Land_MultistoryBuilding_01_F",
    // Livonia
    "Land_House_1W11_F", "Land_House_1W07_F", "Land_House_2W01_F", "Land_House_2B02_F", "Land_House_1B01_F",
    "Land_House_2B03_F", "Land_PoliceStation_01_F", "Land_HealthCenter_01_F"
];

[
    ["Probe the mayor's office candidate buildings", {
        // The main airfield: the airport nearest Altis's main runway, a flat open spot 500-1500 m from
        // its centre with no occupier men within 300 m
        private _airport = OT_airportData apply { [(_x select 0) distance2D [14600, 16700, 0], _x select 0] };
        _airport sort true;
        private _centre = (_airport param [0, [0, [14600, 16700, 0]]]) select 1;
        private _spot = [];
        for "_r" from 500 to 1500 step 100 do {
            for "_d" from 0 to 345 step 15 do {
                private _p = _centre getPos [_r, _d];
                if (surfaceIsWater _p) then { continue };
                if ((_p isFlatEmpty [30, -1, 0.15, 30, 0, false, objNull]) isEqualTo []) then { continue };
                if (((_p nearEntities ["CAManBase", 300]) findIf { (side group _x) isEqualTo blufor }) > -1) then { continue };
                _spot = _p;
                break;
            };
            if (_spot isNotEqualTo []) then { break };
        };
        if (_spot isEqualTo []) exitWith { ["Probe: an open flat spot on the airfield", false, str _centre] call OTQA_fnc_check };
        player allowDamage false;
        player setCaptive true;
        private _stand = (_spot getPos [90, 0]) findEmptyPosition [0, 40, "CAManBase"];
        if (_stand isEqualTo []) then { _stand = _spot getPos [90, 0] };
        player setPosATL _stand;
        sleep 3;
        { _x hideObjectGlobal true } forEach (nearestTerrainObjects [_spot, [], 60, false]);
        diag_log format ["OTPROBE2|SITE|%1|%2", _spot apply { round _x }, _centre apply { round _x }];

        private _done = 0;
        {
            private _cls = _x;
            if !(isClass (configFile >> "CfgVehicles" >> _cls)) then { diag_log format ["OTPROBE2|MISSING|%1", _cls]; continue };
            private _b = createVehicle [_cls, _spot, [], 0, "CAN_COLLIDE"];
            _b setDir 0;
            _b setPosATL [_spot select 0, _spot select 1, 0];
            sleep 2;
            (boundingBoxReal _b) params ["_min", "_max"];
            diag_log format ["OTPROBE2|START|%1|%2|%3", _cls, _min apply { (round (_x * 10)) / 10 }, _max apply { (round (_x * 10)) / 10 }];
            private _doors = [];
            for "_i" from 1 to (getNumber ((configOf _b) >> "numberOfDoors")) do {
                private _p = _b selectionPosition [format ["Door_%1_trigger", _i], "Memory"];
                if (_p isNotEqualTo [0, 0, 0]) then { _doors pushBack (_p apply { (round (_x * 10)) / 10 }) };
            };
            diag_log format ["OTPROBE2|DOORS|%1|%2|%3", _cls, count _doors, _doors];
            private _positions = (_b buildingPos -1) apply { (_b worldToModel _x) apply { (round (_x * 10)) / 10 } };
            diag_log format ["OTPROBE2|POS|%1|%2|%3", _cls, count _positions, _positions];
            // Floor heights: the building positions' heights, within 1 m counted as one
            private _zs = _positions apply { _x select 2 };
            _zs sort true;
            private _levels = [];
            { if (_levels isEqualTo [] || { (_x - (_levels select -1)) > 1 }) then { _levels pushBack _x } } forEach _zs;
            diag_log format ["OTPROBE2|LEVELS|%1|%2", _cls, _levels];
            {
                private _lz = _x;
                for "_y" from (floor (_max select 1)) to (ceil (_min select 1)) step -1 do {
                    private _row = "";
                    for "_xx" from (ceil (_min select 0)) to (floor (_max select 0)) step 1 do {
                        private _w = _b modelToWorldWorld [_xx, _y, _lz];
                        private _wall = lineIntersectsSurfaces [_w vectorAdd [0, 0, 0.4], _w vectorAdd [0, 0, 1.7], objNull, objNull, true, 1, "GEOM", "NONE"];
                        private _floor = lineIntersectsSurfaces [_w vectorAdd [0, 0, 0.4], _w vectorAdd [0, 0, -0.6], objNull, objNull, true, 1, "GEOM", "NONE"];
                        _row = _row + (call {
                            if ((_wall findIf { (_x select 2) isEqualTo _b }) > -1) exitWith { "#" };
                            if ((_floor findIf { (_x select 2) isEqualTo _b }) > -1) exitWith { "." };
                            " "
                        });
                    };
                    diag_log format ["OTPROBE2|ROW|%1|%2|%3|%4", _cls, _lz, _y, _row];
                };
            } forEach _levels;
            diag_log format ["OTPROBE2|END|%1", _cls];
            deleteVehicle _b;
            _done = _done + 1;
            sleep 1;
        } forEach OTQA_probeOffices_classes;
        ["Probe: candidate buildings mapped", _done isEqualTo (count OTQA_probeOffices_classes), format ["%1 of %2", _done, count OTQA_probeOffices_classes]] call OTQA_fnc_check;
    }, 1800]
];
