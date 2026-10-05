/*
    Description:
    Mayor's office layout check (the "layoutcheck" QA survey): puts each town's layout up tier by tier
    (OT_fnc_officeApplyLayout, placeholder guards) in daylight and measures it, for the layout designers'
    critique (tools/qa/layout-review.py turns the lines and screenshots into the review):
        OTCHECK|town|tier|items|guards|objects|statics|missing|clips|floating|moved|blind|blocked|views
            items: in the layout; missing: items not made (a class that doesn't exist)
            clips: [[class, what it cuts into, [x, y]], ...] a prop or fortification with a building, wall, rock or the
                office's own walls running through it (two rays across its footprint)
            floating: [[class, gap m, [x, y]], ...] standing more than 0.3 m above whatever is under it
            moved: [[role, m, [x, y]], ...] guards more than 1 m from their post after settling (pushed out of geometry)
            blind: [[role, m, [x, y]], ...] guards whose view (a 80 degree cone round their facing, at eye height) ends
                within 4 m: facing a wall
            blocked: [[role, m, [x, y]], ...] statics whose field of fire (a 60 degree cone, 40 m) ends within 15 m
            views: the guards' median clear view in metres
        OTPATH|town|tier|bearing|[x, y]|[[x, y], ...] a way out: a man's route (the engine's path finding) from the
            office's door to a point 60 m out at that bearing from the office's front, [x, y] where it last passes
            within 3 m of a fortification (the gap), and the route every ~5 m out to 45 m; OTPATH|town|tier|closed
            when every route was computed and none gets out, "unknown (...)" when some weren't computed
        OTCLASS|class|[length, depth, height] the real size of every class the layouts use (once)
    and two screenshots per tier (the profile's Screenshots folder): OTL_<town>_T<tier>_top.png from 60 m
    above, OTL_<town>_T<tier>_street.png from 35 m out on the street side, 20 m up (the first bearing with a clear view); both farther out for a big
    office, by OT_fnc_officeRadius against 30 m.
    run-qa.ps1 -Suite layoutcheck -Only "town,..." checks those towns (else every town with a layout);
    OTQA_layoutShots = false skips the screenshots.

    Returns: ARRAY - [[name, code, seconds]]
*/

[
    ["Office layout check", {
        call OTQA_fnc_officeReview;
        call OTQA_fnc_townLayout;
        [""] call OT_fnc_officeLayout;
        private _only = missionNamespace getVariable ["OTQA_only", []];
        private _towns = if (_only isNotEqualTo []) then { _only select { _x in OT_officeLayouts } } else { (keys OT_officeLayouts) select { _x in OT_allTowns } };
        _towns sort true;
        private _shots = missionNamespace getVariable ["OTQA_layoutShots", true];

        // Daylight and a clear sky for the pictures; the host out of them and out of harm's way
        skipTime ((12.5 - daytime + 24) % 24);
        0 setOvercast 0; 0 setRain 0; 0 setFog [0, 0, 0]; 0 setLightnings 0; forceWeatherChange;
        999999 setOvercast 0; 999999 setRain 0; 999999 setFog 0; // And it stays so
        sleep 3;
        player allowDamage false;
        player setCaptive true;
        player hideObjectGlobal true;
        private _home = getPosASL player;
        private _cam = objNull;
        if (_shots) then {
            _cam = "camera" camCreate (getPosATL player);
            _cam cameraEffect ["INTERNAL", "BACK"];
            showCinemaBorder false;
            cameraEffectEnableHUD false;
        };

        private _terrainTypes = ["BUILDING", "HOUSE", "CHURCH", "CHAPEL", "FUELSTATION", "HOSPITAL", "RUIN", "BUNKER", "FORTRESS", "VIEW-TOWER", "LIGHTHOUSE", "QUAY", "TRANSMITTER", "WATERTOWER", "WALL", "FENCE", "ROCK", "ROCKS"];
        private _sizes = createHashMap;
        // The furthest clear distance over a cone of rays from a point (ASL) round a direction
        // A man's route (the engine's path finding) between two points, [] when it isn't computed in 30 s
        private _route = {
            params ["_from", "_to"];
            OTQA_pathDone = nil;
            private _agent = calculatePath ["man", "safe", _from, _to];
            _agent addEventHandler ["PathCalculated", { OTQA_pathDone = _this select 1 }];
            private _t = time + 30;
            waitUntil { sleep 0.2; !isNil "OTQA_pathDone" || { time > _t } };
            missionNamespace getVariable ["OTQA_pathDone", []]
        };
        private _cone = {
            params ["_from", "_dir", "_spread", "_steps", "_len", "_ignore"];
            private _best = 0;
            for "_i" from 0 to _steps do {
                private _d = _dir - _spread / 2 + _spread * _i / (_steps max 1);
                private _to = _from vectorAdd [_len * sin _d, _len * cos _d, 0];
                private _hit = lineIntersectsSurfaces [_from, _to, _ignore, objNull, true, 1, "VIEW", "FIRE"];
                private _clear = if (_hit isEqualTo []) then { _len } else { _from distance ((_hit select 0) select 0) };
                _best = _best max _clear;
            };
            _best
        };
        private _r1 = { (round (_this * 10)) / 10 };

        {
            private _town = _x;
            private _layout = [_town] call OT_fnc_officeLayout;
            (_layout select 0) params ["_class", "_pos", "_dir", ["_spawned", false]];
            player setPosASL ((_pos vectorAdd [0, 0, 0]) getPos [60, 0]);
            sleep 2; // The area streamed in
            skipTime ((12.5 - daytime + 24) % 24); // Still midday (a long run reaches dusk)
            0 setOvercast 0; 0 setRain 0; 0 setFog [0, 0, 0]; forceWeatherChange; // And clear (the weather system brings the fog back)
            // Where the closure routes start: the first spot from which a man gets 60 m out on the bare site, before
            // anything of the layout stands. Inside the office first (its lowest positions: inside any ring round it,
            // where a spot by a door may be outside a line run tight across the front), then its exits and sides
            private _start = [];
            private _site = (nearestObjects [ASLToAGL _pos, [_class], 3, true]) param [0, objNull];
            // Where the search lands outside the rings (behind the house, inside a neighbour's box), a fixed start by
            // the main door (office model [x, y], the designers' word)
            private _fixed = (createHashMapFromArray [["Athira", [-3.3, -8.8]], ["Zaros", [-5, 2.5]], ["Neochori", [-0.7, -0.5]], ["Kavala", [13.1, -6.1]], ["Paros", [0.7, 5.8]]]) getOrDefault [_town, []];
            if (!isNull _site && { _fixed isNotEqualTo [] }) then {
                _start = _site modelToWorld (_fixed + [0]);
                _start set [2, 0];
            };
            if (!isNull _site && { _start isEqualTo [] }) then {
                (boundingBoxReal _site) params ["_mn", "_mx"];
                private _spots = [_site buildingPos -1, [], { _x select 2 }, "ASCEND"] call BIS_fnc_sortBy;
                _spots = _spots select [0, 4];
                for "_i" from 0 to 5 do { private _e = _site buildingExit _i; if (_e isNotEqualTo [0, 0, 0]) then { _spots pushBack _e } };
                // 1.5 m out from its real walls (a ray in from each side; the box can be far bigger than the walls)
                private _wallSpots = 0;
                {
                    private _out = _site modelToWorldWorld (_x vectorMultiply 60);
                    private _in = _site modelToWorldWorld [0, 0, 0];
                    _out set [2, (getTerrainHeightASL _out) + 1]; _in set [2, (getTerrainHeightASL _in) + 1];
                    private _hit = (lineIntersectsSurfaces [_out, _in, objNull, objNull, true, 8, "GEOM", "NONE"]) select { ((_x select 2) isEqualTo _site) || { (_x select 3) isEqualTo _site } };
                    if (_hit isNotEqualTo []) then { _wallSpots = _wallSpots + 1; _spots pushBack (ASLToATL (((_hit select 0) select 0) vectorAdd ((vectorNormalized (_out vectorDiff _in)) vectorMultiply 1.5))) };
                } forEach [[0, 1, 0], [0, -1, 0], [1, 0, 0], [-1, 0, 0]];
                { _spots pushBack (_site modelToWorld _x) } forEach [[0, (_mx select 1) + 2, 0], [0, (_mn select 1) - 2, 0], [(_mx select 0) + 2, 0, 0], [(_mn select 0) - 2, 0, 0]];
                // Out to any of 8 points 60 m away (one may be unreachable: the sea, a walled lot)
                private _aways = [0, 45, 90, 135, 180, 225, 270, 315] apply {
                    private _a = (getPosATL _site) getPos [60, (getDir _site) + _x];
                    private _road = (_a nearRoads 25) param [0, objNull];
                    [_a, getPosATL _road] select (!isNull _road)
                };
                diag_log format ["OTPATHSPOTS|%1|%2 spots (%3 by the real walls)", _town, count _spots, _wallSpots];
                // Every spot that gets out, then the one nearest the office's centre (the same from run to run: the
                // first that happened to work wandered, landing outside a ring behind the house)
                private _ok = _spots select {
                    private _from = _x;
                    if ((_from select 2) < 0.5) then { _from set [2, 0] };
                    (_aways findIf { private _p = [_from, _x] call _route; _p isNotEqualTo [] && { ((_p select -1) distance2D _x) < 4 } }) > -1
                };
                if (_ok isNotEqualTo []) then { _start = ([_ok, [], { _x distance2D _site }, "ASCEND"] call BIS_fnc_sortBy) select 0 };
            };
            diag_log format ["OTPATHSTART|%1|%2", _town, if (_start isEqualTo [] || { isNull _site }) then { "none" } else { ((_site worldToModel _start) select [0, 2]) apply { _x call _r1 } }];

            // Every tier the layout has (a town's highest tier in play follows its population, which a new game changes)
            private _b = objNull;
            for "_tier" from 1 to 5 do {
                private _items = (_layout select 1) param [_tier - 1, []];
                if (_items isEqualTo []) then { continue };
                ([_town, _tier, west, true] call OT_fnc_officeApplyLayout) params ["_office", "_objects", "_guards"];
                _b = _office;
                sleep 3; // Settled
                private _parts = [[_b] call OT_fnc_officeTemplateKey, _b] call OTQA_officeReview_realParts;
                private _terrain = (nearestTerrainObjects [getPosATL _b, _terrainTypes, 70, false, true]) - _parts;
                private _statics = _objects select { _x isKindOf "StaticWeapon" };
                private _props = _objects - _statics;

                // Where a flagged thing stands: [x, y] in the office's model coordinates (the drafts' own)
                private _at = { ((_b worldToModel (ASLToAGL (getPosASL _this))) select [0, 2]) apply { _x call _r1 } };

                // Clipping: a building, wall, rock or the office's walls through a thing's footprint
                private _clips = [];
                {
                    private _o = _x;
                    (boundingBoxReal _o) params ["_mn", "_mx"];
                    private _z = ((_mn select 2) + 0.35) min (((_mn select 2) + (_mx select 2)) / 2);
                    // Barrier pieces (walls, fences, H-barriers, gates, wire, bags) may overlap a little to make one
                    // unbroken line: only their middle counts (0.6 m off each end, half their depth)
                    private _barrier = (["Wall", "Fence", "HBarrier", "Barrier", "Gate", "Razorwire", "BagFence", "Cnc", "Hedgehog"] findIf { _x in (typeOf _o) }) > -1;
                    private _ix = [0.4 * ((_mx select 0) - (_mn select 0)), (0.5 * ((_mx select 0) - (_mn select 0)) - 0.6) max 0.1] select _barrier;
                    private _iy = [0.4 * ((_mx select 1) - (_mn select 1)), 0.25 * ((_mx select 1) - (_mn select 1))] select _barrier;
                    private _cx = ((_mn select 0) + (_mx select 0)) / 2;
                    private _cy = ((_mn select 1) + (_mx select 1)) / 2;
                    {
                        _x params ["_a", "_c"];
                        private _hits = lineIntersectsSurfaces [_o modelToWorldWorld [_cx + (_a select 0) * _ix, _cy + (_a select 1) * _iy, _z], _o modelToWorldWorld [_cx + (_c select 0) * _ix, _cy + (_c select 1) * _iy, _z], _o, objNull, true, 3, "GEOM", "NONE"];
                        // A hit's object: its parent (a building's proxy part) or the object itself; terrain has neither
                        private _of = { private _h = _this select 3; if (isNull _h) then { _h = _this select 2 }; _h };
                        private _bad = _hits select { private _h = _x call _of; !isNull _h && { (_h in _terrain) || { _h isEqualTo _b } || { _h in _parts } } };
                        if (_bad isNotEqualTo []) exitWith {
                            private _h = (_bad select 0) call _of;
                            _clips pushBack [typeOf _o, [(getModelInfo _h) select 0, "office"] select (_h isEqualTo _b || { _h in _parts }), _o call _at];
                        };
                    } forEach [[[-1, -1], [1, 1]], [[-1, 1], [1, -1]]];
                } forEach (_props + _statics);

                // Floating: the gap under a thing's base
                private _floating = [];
                {
                    private _o = _x;
                    (boundingBoxReal _o) params ["_mn", "_mx"];
                    private _base = _o modelToWorldWorld [((_mn select 0) + (_mx select 0)) / 2, ((_mn select 1) + (_mx select 1)) / 2, _mn select 2];
                    private _hit = lineIntersectsSurfaces [_base vectorAdd [0, 0, 0.05], _base vectorAdd [0, 0, -3], _o, objNull, true, 1, "GEOM", "NONE"];
                    private _gap = if (_hit isEqualTo []) then { 3 } else { (_base select 2) - (((_hit select 0) select 0) select 2) };
                    if (_gap > 0.3) then { _floating pushBack [typeOf _o, _gap call _r1, _o call _at] };
                    if !((typeOf _o) in _sizes) then {
                        _sizes set [typeOf _o, [((_mx select 0) - (_mn select 0)) call _r1, ((_mx select 1) - (_mn select 1)) call _r1, ((_mx select 2) - (_mn select 2)) call _r1]];
                        // Where a man stands on it (a tower's platform, a bunker's inside): its building positions, model coordinates
                        private _bp = (_o buildingPos -1) apply { (_o worldToModel _x) apply { _x call _r1 } };
                        if (_bp isNotEqualTo []) then { diag_log format ["OTBPOS|%1|%2", typeOf _o, _bp] };
                        // A tall object's floors (a tower's platform, a bunker's roof): every surface of it hit by a
                        // ray straight down at its centre and 0.6 m off it each way, model height above its base
                        if (((_mx select 2) - (_mn select 2)) > 2.2) then {
                            private _surf = [];
                            {
                                private _px = ((_mn select 0) + (_mx select 0)) / 2 + (_x select 0);
                                private _py = ((_mn select 1) + (_mx select 1)) / 2 + (_x select 1);
                                private _hits = lineIntersectsSurfaces [_o modelToWorldWorld [_px, _py, (_mx select 2) + 0.5], _o modelToWorldWorld [_px, _py, (_mn select 2) - 0.2], objNull, objNull, true, 8, "GEOM", "NONE"];
                                private _zs = (_hits select { ((_x select 2) isEqualTo _o) || { (_x select 3) isEqualTo _o } }) apply { (((_o worldToModel (ASLToAGL (_x select 0))) select 2) - (_mn select 2)) call _r1 };
                                _surf pushBack [_px call _r1, _py call _r1, _zs];
                            } forEach [[0, 0], [0.6, 0], [-0.6, 0], [0, 0.6], [0, -0.6]];
                            diag_log format ["OTSURF|%1|%2|base z %3", typeOf _o, _surf, (_mn select 2) call _r1];
                        };
                    };
                } forEach (_props + _statics);

                // Guards: pushed off their post, facing a wall; their views
                private _moved = [];
                private _blind = [];
                private _views = [];
                {
                    private _g = _x;
                    private _item = (_g getVariable ["OT_officeItem", []]) param [3, []];
                    private _off = (getPosASL _g) distance (_item param [2, getPosASL _g]);
                    if (_off > 1) then { _moved pushBack [_item param [1, "?"], _off call _r1, _g call _at] };
                    private _view = [eyePos _g, getDir _g, 80, 8, 30, _g] call _cone;
                    _views pushBack _view;
                    if (_view < 4) then { _blind pushBack [_item param [1, "?"], _view call _r1, _g call _at] };
                } forEach _guards;
                _views sort true;

                // Statics: their field of fire
                private _blocked = [];
                {
                    private _s = _x;
                    private _fire = [(getPosASL _s) vectorAdd [0, 0, 1.1], getDir _s, 60, 6, 40, _s] call _cone;
                    if (_fire < 15) then { _blocked pushBack [[_s] call OT_fnc_officeStatic, _fire call _r1, _s call _at] };
                } forEach _statics;

                diag_log format ["OTCHECK|%1|%2|%3|%4|%5|%6|%7|%8|%9|%10|%11|%12|%13", _town, _tier, count _items, count _guards, count _props, count _statics,
                    (count _items) - (count _objects) - (count _guards), _clips, _floating, _moved, _blind, _blocked, (_views param [floor ((count _views) / 2), 0]) call _r1];

                // Closure: can a man walk out? The engine's own route from the office's door to 8 points 60 m out
                // (on a road where there's one). A route that gets there is a way out; where it passes closest to the
                // layout's fortifications is the gap
                // From the spot found on the bare site (none: the closure can't be checked here)
                private _exit = +_start;
                private _none = 0; // Routes the engine didn't compute at all (a bad start), not "closed"
                private _ways = [];
                {
                    private _to = (getPosATL _b) getPos [60, (getDir _b) + _x];
                    private _road = (_to nearRoads 25) param [0, objNull];
                    if (!isNull _road) then { _to = getPosATL _road };
                    private _path = if (_exit isEqualTo []) then { [] } else { [_exit, _to] call _route };
                    if (_path isEqualTo []) then { _none = _none + 1 };
                    private _out = _path isNotEqualTo [] && { ((_path select -1) distance2D _to) < 4 };
                    if (_out) then {
                        // The route as waypoints far apart: filled in every metre, so a leg crossing a line is seen
                        private _dense = [_path select 0];
                        for "_i" from 1 to (count _path) - 1 do {
                            private _a = _path select (_i - 1);
                            private _c = _path select _i;
                            private _n = ceil (_a distance2D _c);
                            for "_k" from 1 to _n do { _dense pushBack (_a vectorAdd ((_c vectorDiff _a) vectorMultiply (_k / _n))) };
                        };
                        _path = _dense;
                        // The gap: the last point of the route that passes within 3 m of a fortification (where it
                        // leaves the outermost line); the route itself every ~5 m out to 45 m, to follow it
                        private _gap = [];
                        private _trace = [];
                        {
                            private _p = _x;
                            if ((_p distance2D _b) < 45) then {
                                if ((_props findIf { (_x distance2D _p) < 3 }) > -1) then { _gap = _p };
                                if (_trace isEqualTo [] || { ((_trace select -1) distance2D _p) > 5 }) then { _trace pushBack _p };
                            };
                        } forEach _path;
                        private _model = { ((_b worldToModel _this) select [0, 2]) apply { _x call _r1 } };
                        _ways pushBack [_x, if (_gap isEqualTo []) then { [] } else { _gap call _model }, _trace apply { _x call _model }];
                    };
                } forEach [0, 45, 90, 135, 180, 225, 270, 315];
                // One line per way out (an RPT line is cut at about 1 KB)
                { diag_log format ["OTPATH|%1|%2|%3|%4|%5", _town, _tier, _x select 0, _x select 1, _x select 2] } forEach _ways;
                if (_ways isEqualTo []) then { diag_log format ["OTPATH|%1|%2|%3", _town, _tier, ["closed", format ["unknown (%1 of 8 routes not computed)", _none]] select (_none > 0)] };

                // The pictures: from above, and from out along the way to the street
                if (_shots) then {
                    // Farther out for a big office (Kavala's hospital): by its radius against a house's 30 m
                    private _scale = (([_town] call OT_fnc_officeRadius) / 30) ^ 1.5; // About twice as far for the hospital
                    private _name = (_town splitString " ") joinString "_";
                    private _c = getPosASL _b;
                    _cam camPrepareTarget (ASLToAGL (_c vectorAdd [0, 0.5, 0]));
                    // 55 m above the ground, or 55 m above the roof of a tall office (the Offices_01 tower)
                    (boundingBoxReal _b) params ["", "_top"];
                    _cam camPreparePos (ASLToAGL (_c vectorAdd [0, 0, (55 max ((_top select 2) + 55)) * _scale]));
                    _cam camPrepareFOV 0.75;
                    _cam camCommitPrepared 0;
                    sleep 1.5;
                    screenshot format ["OTL_%1_T%2_top.png", _name, _tier];
                    sleep 0.5;
                    // From the street side, 35 m out and 20 m up: the first bearing (from the way to the street round
                    // both ways) with a clear view of the office (nothing but the office in the way)
                    ([_b, _parts, _town] call OTQA_townLayout_front) params ["_stand"];
                    private _front = _b getDir _stand;
                    private _aim = _c vectorAdd [0, 0, 3];
                    private _eye = [];
                    {
                        private _p = _c getPos [35 * _scale, _front + _x];
                        private _e = [_p select 0, _p select 1, ((getTerrainHeightASL _p) max (_c select 2)) + 20 * _scale];
                        private _hits = lineIntersectsSurfaces [_e, _aim, objNull, objNull, true, 1, "VIEW", "FIRE"];
                        if (_hits isEqualTo [] || { (((_hits select 0) select 2) isEqualTo _b) || { ((_hits select 0) select 3) isEqualTo _b } }) exitWith { _eye = _e };
                    } forEach [0, 30, -30, 60, -60, 90, -90, 135, -135, 180];
                    if (_eye isEqualTo []) then { private _p = _c getPos [35 * _scale, _front]; _eye = [_p select 0, _p select 1, ((getTerrainHeightASL _p) max (_c select 2)) + 26 * _scale] };
                    _cam camPrepareTarget (ASLToAGL _c);
                    _cam camPreparePos (ASLToAGL _eye);
                    _cam camPrepareFOV 0.7;
                    _cam camCommitPrepared 0;
                    sleep 1.5;
                    screenshot format ["OTL_%1_T%2_street.png", _name, _tier];
                    sleep 0.5;
                };
                [_b] call OT_fnc_officeClearTemplate;
                sleep 1.5;
            };
            if (_spawned && { !isNull _b }) then { deleteVehicle _b };
        } forEach _towns;

        { diag_log format ["OTCLASS|%1|%2", _x, _y] } forEach _sizes;
        if (!isNull _cam) then {
            _cam cameraEffect ["TERMINATE", "BACK"];
            camDestroy _cam;
        };
        player hideObjectGlobal false;
        player setPosASL _home;
        player allowDamage true;
        ["Office layout check: towns checked", true, format ["%1 towns (OTCHECK lines in the RPT%2)", count _towns, [")", ", OTL_*.png in the Screenshots folder)"] select _shots]] call OTQA_fnc_check;
    }, 7200]
]
