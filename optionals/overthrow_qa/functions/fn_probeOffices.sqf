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
        OTPROBE2|DOORGRID|class|door index|level z|j|row    (0.25 m cells round a door point: '#' wall; the
                                                             row j is 0.25 j north of it, cell k 0.25 k east, k -14..14)
        OTPROBE2|WINCELL|class|level z|x|y|dir|geom|view|across  (an outer wall cell: four samples 0.25 m apart
                                                             along the wall, '1' where there is wall at sill height,
                                                             none at window height and wall again above, i.e. a
                                                             window, facing dir; read three ways: up the wall's centre
                                                             line in the collision geometry, the same in the view
                                                             geometry, and across the wall in the view geometry)
        OTPROBE2|OPENSKY|class|level z|[[x,y], ...]         (floor cells with nothing of the building above:
                                                             balconies, terraces, roofs)
        OTPROBE2|END|class
    The doors are opened and the window glass broken first, so the ways through them read clear.
    Buildings made of several map objects (OTQA_probeOffices_parts: the Altis hospital's two wings)
    are read off the real one on the map first and spawned together:
        OTPROBE2|PARTS|class|[[part class, [x,y,z] in the main's coordinates, direction relative to it], ...]
    Their rows count all the parts, and positions/doors are the main object's plus each part's
    (moved into the main's coordinates).

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
    "Land_House_Big_03_F", "Land_Hotel_01_F", "Land_Hotel_02_F", "Land_House_Big_02_F", "Land_Shop_City_04_F", "Land_Shop_City_06_F",
    "Land_MultistoryBuilding_01_F",
    // Livonia
    "Land_House_1W11_F", "Land_House_1W07_F", "Land_House_2W01_F", "Land_House_2B02_F", "Land_House_1B01_F",
    "Land_House_2B03_F", "Land_PoliceStation_01_F", "Land_HealthCenter_01_F"
];

// Main class -> the classes of its other pieces (found within 60 m of a real one on this map)
OTQA_probeOffices_parts = createHashMapFromArray [
    ["Land_Hospital_main_F", ["Land_Hospital_side1_F", "Land_Hospital_side2_F"]]
];

[
    ["Probe the mayor's office candidate buildings", {
        // Where the parts of multi-piece buildings sit, from the real ones on the map
        private _layouts = createHashMap;
        {
            private _main = _x;
            private _partClasses = _y;
            private _real = [];
            { _real append (nearestObjects [server getVariable [_x, [0, 0, 0]], [_main], 1000]) } forEach OT_allTowns;
            if (_real isEqualTo []) then { diag_log format ["OTPROBE2|NOPARTS|%1", _main]; continue };
            private _m = _real select 0;
            private _layout = [];
            {
                private _cls = _x;
                private _part = ((nearestObjects [_m, [], 80]) select { (typeOf _x) isEqualTo _cls }) param [0, objNull];
                if (!isNull _part) then {
                    _layout pushBack [_cls, (_m worldToModel (getPosATL _part)) apply { (round (_x * 100)) / 100 }, ((getDir _part) - (getDir _m) + 360) % 360];
                };
            } forEach _partClasses;
            _layouts set [_main, _layout];
            diag_log format ["OTPROBE2|PARTS|%1|%2", _main, _layout];
        } forEach OTQA_probeOffices_parts;

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

        // Only the classes asked for (run-qa.ps1 -Only), else all of them
        private _classes = OTQA_probeOffices_classes;
        private _only = missionNamespace getVariable ["OTQA_only", []];
        if (_only isNotEqualTo []) then { _classes = _only };
        private _done = 0;
        {
            private _cls = _x;
            if !(isClass (configFile >> "CfgVehicles" >> _cls)) then { diag_log format ["OTPROBE2|MISSING|%1", _cls]; continue };
            private _b = createVehicle [_cls, _spot, [], 0, "CAN_COLLIDE"];
            _b setDir 0;
            _b setPosATL [_spot select 0, _spot select 1, 0];
            private _parts = [];
            {
                _x params ["_pcls", "_offset", "_pdir"];
                private _o = createVehicle [_pcls, _spot, [], 0, "CAN_COLLIDE"];
                _o setDir _pdir;
                _o setPosATL (_b modelToWorld _offset);
                _parts pushBack _o;
            } forEach (_layouts getOrDefault [_cls, []]);
            private _all = [_b] + _parts;
            sleep 2;
            // The doors open and the window glass broken, so the walls read as they are with the ways
            // through them and the windows clear (unbroken glass is in the collision geometry)
            {
                private _o = _x;
                for "_i" from 1 to (getNumber ((configOf _o) >> "numberOfDoors")) do {
                    { _o animateSource [format [_x, _i], 1, true] } forEach ["Door_%1_source", "Door_%1_sound_source"];
                };
                { if ("glass" in toLower _x) then { _o setHitPointDamage [_x, 1] } } forEach ((getAllHitPointsDamage _o) param [0, []]);
            } forEach _all;
            sleep 1;
            (boundingBoxReal _b) params ["_min", "_max"];
            {
                private _o = _x;
                (boundingBoxReal _o) params ["_omin", "_omax"];
                {
                    private _c = _b worldToModel (_o modelToWorld _x);
                    _min = [(_min select 0) min (_c select 0), (_min select 1) min (_c select 1), (_min select 2) min (_c select 2)];
                    _max = [(_max select 0) max (_c select 0), (_max select 1) max (_c select 1), (_max select 2) max (_c select 2)];
                } forEach [_omin, _omax, [_omin select 0, _omax select 1, _omin select 2], [_omax select 0, _omin select 1, _omin select 2]];
            } forEach _parts;
            diag_log format ["OTPROBE2|START|%1|%2|%3", _cls, _min apply { (round (_x * 10)) / 10 }, _max apply { (round (_x * 10)) / 10 }];
            private _doors = [];
            for "_i" from 1 to (getNumber ((configOf _b) >> "numberOfDoors")) do {
                private _p = _b selectionPosition [format ["Door_%1_trigger", _i], "Memory"];
                if (_p isNotEqualTo [0, 0, 0]) then { _doors pushBack (_p apply { (round (_x * 10)) / 10 }) };
            };
            diag_log format ["OTPROBE2|DOORS|%1|%2|%3", _cls, count _doors, _doors];
            private _positions = [];
            { private _o = _x; _positions append ((_o buildingPos -1) apply { (_b worldToModel _x) apply { (round (_x * 10)) / 10 } }) } forEach _all;
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
                            if ((_wall findIf { (_x select 2) in _all }) > -1) exitWith { "#" };
                            if ((_floor findIf { (_x select 2) in _all }) > -1) exitWith { "." };
                            " "
                        });
                    };
                    diag_log format ["OTPROBE2|ROW|%1|%2|%3|%4", _cls, _lz, _y, _row];
                };
            } forEach _levels;
            // Whether there is wall between two heights above a model point (in the collision geometry)
            private _wallAt = {
                params ["_m", "_from", "_to", ["_lod", "GEOM"]];
                private _w = _b modelToWorldWorld _m;
                private _hits = lineIntersectsSurfaces [_w vectorAdd [0, 0, _from], _w vectorAdd [0, 0, _to], objNull, objNull, true, 1, _lod, "NONE"];
                (_hits findIf { (_x select 2) in _all }) > -1
            };
            // Whether a ray across a wall (0.7 m either side of a model point, along the outward direction) at
            // a height meets it in a geometry: the view and fire geometries are thin surfaces that a vertical
            // ray through the cell's centre line can miss
            private _acrossAt = {
                params ["_m", "_h", "_dx", "_dy", "_lod"];
                private _w = _b modelToWorldWorld (_m vectorAdd [0, 0, _h]);
                private _hits = lineIntersectsSurfaces [_w vectorAdd [-_dx * 0.7, -_dy * 0.7, 0], _w vectorAdd [_dx * 0.7, _dy * 0.7, 0], objNull, objNull, true, 1, _lod, "NONE"];
                (_hits findIf { (_x select 2) in _all }) > -1
            };
            // Round each door: a 0.25 m grid of wall at standing height, for the doorway's real centre and width
            {
                private _door = _x;
                private _di = _forEachIndex;
                private _lz = _levels select 0;
                { if (abs (_x - ((_door select 2) - 1)) < abs (_lz - ((_door select 2) - 1))) then { _lz = _x } } forEach _levels;
                for "_j" from 14 to -14 step -1 do {
                    private _row = "";
                    for "_k" from -14 to 14 do {
                        _row = _row + (["#", " "] select !([[(_door select 0) + _k * 0.25, (_door select 1) + _j * 0.25, _lz], 0.4, 1.7] call _wallAt));
                    };
                    diag_log format ["OTPROBE2|DOORGRID|%1|%2|%3|%4|%5", _cls, _di, _lz, _j, _row];
                };
            } forEach _doors;
            // Windows along the outer walls and floor open to the sky (balconies, terraces, roofs), per level
            {
                private _lz = _x;
                private _cells = createHashMap;
                for "_y" from (floor (_max select 1)) to (ceil (_min select 1)) step -1 do {
                    for "_xx" from (ceil (_min select 0)) to (floor (_max select 0)) step 1 do {
                        _cells set [[_xx, _y], call {
                            if ([[_xx, _y, _lz], 0.4, 1.7] call _wallAt) exitWith { "#" };
                            if ([[_xx, _y, _lz], 0.4, -0.6] call _wallAt) exitWith { "." };
                            " "
                        }];
                    };
                };
                private _open = [];
                {
                    _x params ["_xx", "_y"];
                    private _c = _cells get _x;
                    if (_c isEqualTo ".") then {
                        if !([[_xx, _y, _lz], 0.4, 4.5] call _wallAt) then { _open pushBack [_xx, _y] };
                    };
                    if (_c isEqualTo "#") then {
                        {
                            _x params ["_dir", "_dx", "_dy"];
                            if ((_cells getOrDefault [[_xx + _dx, _y + _dy], " "]) isEqualTo " ") then {
                                // A window: wall under the sill, nothing to see through at window height and wall
                                // again above (a parapet or railing has none; a shuttered window stays solid). Read
                                // twice: in the view geometry (what the AI sees through, but some models have none)
                                // and in the fire geometry with the glass broken
                                // Three readings of "nothing at window height", each catching windows the others miss
                                // (frames and bars stop a ray across the wall, a ray up the wall's centre line slips past
                                // them, a geometry can lack the wall altogether): the collision geometry up the line, the
                                // view geometry up the line, the view geometry across the wall at 1.3 and 1.5 m
                                private _flagsGeom = "";
                                private _flagsView = "";
                                private _flagsAcross = "";
                                {
                                    private _m = [_xx + _x * _dy, _y + _x * _dx, _lz]; // along the wall: across the outward direction
                                    private _low = [_m, 0.3, 0.8] call _wallAt;
                                    private _top = [_m, 2.2, 2.7] call _wallAt;
                                    private _geom = [_m, 1.2, 1.6] call _wallAt;
                                    private _view = [_m, 1.2, 1.6, "VIEW"] call _wallAt;
                                    private _across = [_m, 1.3, _dx, _dy, "VIEW"] call _acrossAt || { [_m, 1.5, _dx, _dy, "VIEW"] call _acrossAt };
                                    _flagsGeom = _flagsGeom + (["0", "1"] select (_low && { !_geom } && { _top }));
                                    _flagsView = _flagsView + (["0", "1"] select (_low && { !_view } && { _top }));
                                    _flagsAcross = _flagsAcross + (["0", "1"] select (_low && { !_across } && { _top }));
                                } forEach [-0.375, -0.125, 0.125, 0.375];
                                // Every outer wall cell is logged, so the readers can tell a geometry that reads open everywhere
                                diag_log format ["OTPROBE2|WINCELL|%1|%2|%3|%4|%5|%6|%7|%8", _cls, _lz, _xx, _y, _dir, _flagsGeom, _flagsView, _flagsAcross];
                            };
                        } forEach [[0, 0, 1], [90, 1, 0], [180, 0, -1], [270, -1, 0]];
                    };
                } forEach (keys _cells);
                diag_log format ["OTPROBE2|OPENSKY|%1|%2|%3", _cls, _lz, _open];
            } forEach _levels;
            diag_log format ["OTPROBE2|END|%1", _cls];
            { deleteVehicle _x } forEach _all;
            _done = _done + 1;
            sleep 1;
        } forEach _classes;
        ["Probe: candidate buildings mapped", _done isEqualTo (count _classes), format ["%1 of %2", _done, count _classes]] call OTQA_fnc_check;
    }, 1800]
];
