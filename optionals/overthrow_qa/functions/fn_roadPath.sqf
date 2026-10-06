/*
    Description:
    Road path experiment (the "roadpath" QA survey): why the engine's path finding walks through office layout
    pieces standing on a road (Kore, Selakano), and what stops it. For each town (run-qa.ps1 -Only, else Kore and
    Selakano), its top tier is put up, then each variant is tried in turn and taken off again, nothing kept:
        behaviour   the walks planned in "safe" (the layout check's), "aware", "combat", "stealth"
        simulation  the layout's pieces simulated (they're made without)
        roadsHidden the road segments under the pieces hidden (out of the road network?)
        invisible   an invisible barrier on each piece that stands on a road
        roadsHidden+combat
    Each plans 8 walks out (the office to 60 m out) and 8 in, and counts those that get there and those not
    through one of the tier's gates. Then live men (in "safe", then "combat") are ordered out to the 8 points and
    followed for 90 s: do they get out through a gate, through a wall, round a gap, or stick? Lines:
        OTROAD|town|tier|variant|out: planned, reached, not through a gate|in: the same|example crossing
        OTROADMAN|town|tier|behaviour|bearing|out/stuck|through a gate/by a gap|the piece it walked through (inside
            its footprint), if any|where it left the walls [x, y]|where it ended [x, y]
    The behaviour and other variants above run only with OTQA_roadVariants = true.

    Returns: ARRAY - [[name, code, seconds]]
*/

[
    ["Road path experiment", {
        [""] call OT_fnc_officeLayout;
        private _towns = missionNamespace getVariable ["OTQA_only", []];
        if (_towns isEqualTo []) then { _towns = ["Kore", "Selakano"] };
        _towns = _towns select { _x in OT_officeLayouts };
        player allowDamage false;
        player setCaptive true;
        player hideObjectGlobal true;
        private _home = getPosASL player;

        private _route = {
            params ["_from", "_to", "_behaviour"];
            OTQA_pathDone = nil;
            private _agent = calculatePath ["man", _behaviour, _from, _to];
            _agent addEventHandler ["PathCalculated", { OTQA_pathDone = _this select 1 }];
            private _t = time + 30;
            waitUntil { sleep 0.2; !isNil "OTQA_pathDone" || { time > _t } };
            missionNamespace getVariable ["OTQA_pathDone", []]
        };
        // A route filled in every metre
        private _dense = {
            private _out = [_this select 0];
            for "_i" from 1 to (count _this) - 1 do {
                private _a = _this select (_i - 1);
                private _c = _this select _i;
                private _n = ceil (_a distance2D _c);
                for "_k" from 1 to _n do { _out pushBack (_a vectorAdd ((_c vectorDiff _a) vectorMultiply (_k / _n))) };
            };
            _out
        };
        private _r1 = { (round (_this * 10)) / 10 };
        private _invisible = ["Land_InvisibleBarrier_F"] select { isClass (configFile >> "CfgVehicles" >> _x) };

        {
            private _town = _x;
            private _layout = [_town] call OT_fnc_officeLayout;
            private _tier = 0;
            { if (_x isNotEqualTo []) then { _tier = _forEachIndex + 1 } } forEach (_layout select 1);
            (_layout select 0) params ["_class", "_pos"];
            player setPosASL (_pos getPos [80, 0]);
            sleep 3;
            private _b = (nearestObjects [ASLToAGL _pos, [_class], 3, true]) param [0, objNull];
            if (isNull _b) then { diag_log format ["OTROAD|%1|no office", _town]; continue };
            private _model = { ((_b worldToModel _this) select [0, 2]) apply { _x call _r1 } };
            // From the office's lowest floor nearest its middle, to 8 points 60 m out (on a road where one is near)
            private _start = ([_b buildingPos -1, [], { _x distance2D _b }, "ASCEND"] call BIS_fnc_sortBy) param [0, getPosATL _b];
            private _aways = [0, 45, 90, 135, 180, 225, 270, 315] apply {
                private _a = (getPosATL _b) getPos [60, (getDir _b) + _x];
                private _road = (_a nearRoads 25) param [0, objNull];
                [_a, getPosATL _road] select (!isNull _road)
            };
            private _gates = (((_layout select 1) select (_tier - 1)) select { (_x select 0) isEqualTo "gate" }) apply { [ASLToAGL (_x select 2), parseNumber (_x select 1)] };
            private _viaGate = { params ["_path"]; (_gates findIf { _x params ["_g", "_w"]; (_path findIf { (_x distance2D _g) <= (_w / 2 + 1) }) > -1 }) > -1 };

            // The walks of one variant: [out [planned, reached, not via a gate], in [...], an example crossing]
            private _walks = {
                params ["_behaviour", "_pieces"];
                private _result = [];
                private _example = [];
                {
                    private _dir = _x;
                    private _planned = 0; private _reached = 0; private _off = 0;
                    {
                        private _away = _x;
                        private _path = if (_dir isEqualTo "out") then { [_start, _away, _behaviour] call _route } else { [_away, _start, _behaviour] call _route };
                        if (_path isNotEqualTo []) then {
                            _planned = _planned + 1;
                            private _end = [_away, _start] select (_dir isEqualTo "in");
                            if (((_path select -1) distance2D _end) < 4) then {
                                _reached = _reached + 1;
                                private _d = _path call _dense;
                                if !([_d] call _viaGate) then {
                                    _off = _off + 1;
                                    if (_example isEqualTo []) then {
                                        // Where it goes through a piece: the first point within 0.5 m of one's middle line
                                        private _i = _d findIf { private _p = _x; (_pieces findIf { (_x distance2D _p) < 1.2 }) > -1 };
                                        if (_i > -1) then { _example = (_d select _i) call _model };
                                    };
                                };
                            };
                        };
                    } forEach _aways;
                    _result pushBack [_planned, _reached, _off];
                } forEach ["out", "in"];
                _result + [_example]
            };

            private _variants = [
                ["safe", "safe", {}, {}],
                ["aware", "aware", {}, {}],
                ["combat", "combat", {}, {}],
                ["stealth", "stealth", {}, {}],
                ["simulation", "safe", { { _x enableSimulationGlobal true } forEach _objects }, { { _x enableSimulationGlobal false } forEach _objects }],
                ["roadsHidden", "safe", { { _x hideObjectGlobal true } forEach _roads }, { { _x hideObjectGlobal false } forEach _roads }],
                ["invisible", "safe", {
                    OTQA_roadInvisible = [];
                    if (_invisible isEqualTo []) exitWith {};
                    {
                        private _o = createVehicle [_invisible select 0, [0, 0, 0], [], 0, "CAN_COLLIDE"];
                        _o setPosASL getPosASL _x;
                        _o setVectorDirAndUp [vectorDir _x, vectorUp _x];
                        OTQA_roadInvisible pushBack _o;
                    } forEach _onRoad;
                }, { { deleteVehicle _x } forEach OTQA_roadInvisible }],
                ["roadsHidden+combat", "combat", { { _x hideObjectGlobal true } forEach _roads }, { { _x hideObjectGlobal false } forEach _roads }]
            ];

            ([_town, _tier, west, true] call OT_fnc_officeApplyLayout) params ["_office", "_objects", "_guards"];
            sleep 3;
            private _barriers = _objects select { !("_gate" in toLower typeOf _x) };
            // The pieces on a road, and the road segments under any piece
            private _onRoad = _barriers select { (_x nearRoads 4) isNotEqualTo [] };
            private _roads = [];
            { { _roads pushBackUnique _x } forEach (_x nearRoads 6) } forEach _barriers;
            private _pieces = _onRoad apply { getPosATL _x };
            diag_log format ["OTROADINFO|%1|%2|%3 pieces, %4 on a road, %5 road segments under them, invisible barrier class %6", _town, _tier, count _barriers, count _onRoad, count _roads, _invisible];

            {
                _x params ["_name", "_behaviour", "_on", "_off"];
                call _on;
                sleep 2;
                ([_behaviour, _barriers apply { getPosATL _x }] call _walks) params ["_out", "_in", "_example"];
                diag_log format ["OTROAD|%1|%2|%3|out %4|in %5|%6", _town, _tier, _name, _out, _in, _example];
                call _off;
                sleep 1;
            } forEach ([[], _variants] select (missionNamespace getVariable ["OTQA_roadVariants", false]));

            // Live men, ordered out to the 8 points (in "safe", then "combat"), followed every half second: through a
            // gate, through a piece (inside its footprint: walking through a wall), or round a piece's end (a gap)
            private _inPiece = {
                params ["_p"];
                private _hit = "";
                {
                    private _l = _x worldToModel (ASLToAGL (AGLToASL _p));
                    (boundingBoxReal _x) params ["_mn", "_mx"];
                    if ((_l select 0) > (_mn select 0) + 0.25 && { (_l select 0) < (_mx select 0) - 0.25 } && { (_l select 1) > (_mn select 1) + 0.15 } && { (_l select 1) < (_mx select 1) - 0.15 } && { abs (_l select 2) < 3 }) exitWith {
                        _hit = format ["%1 %2", typeOf _x, (getPosATL _x) call _model];
                    };
                } forEach _barriers;
                _hit
            };
            private _liveVariants = [
                ["base", {}, {}],
                ["simulation", { { _x enableSimulationGlobal true } forEach _objects }, { { _x enableSimulationGlobal false } forEach _objects }],
                ["roadsHidden", { { _x hideObjectGlobal true } forEach _roads }, { { _x hideObjectGlobal false } forEach _roads }],
                ["both", { { _x enableSimulationGlobal true } forEach _objects; { _x hideObjectGlobal true } forEach _roads }, { { _x enableSimulationGlobal false } forEach _objects; { _x hideObjectGlobal false } forEach _roads }]
            ];
            {
              _x params ["_variant", "_on", "_off"];
              call _on;
              sleep 2;
              {
                private _behaviour = _x;
                private _clips = [];
                private _gaps = 0; private _gated = 0; private _stuck = 0;
                private _men = _aways apply {
                    private _g = createGroup [independent, true];
                    private _u = _g createUnit ["I_soldier_F", _start, [], 0, "CAN_COLLIDE"];
                    _u allowDamage false;
                    _u setCaptive true;
                    _g setBehaviour toUpper _behaviour;
                    _g setCombatMode "BLUE";
                    _u doMove _x;
                    [_u, _x, [getPosATL _u], ""]
                };
                for "_s" from 1 to ([180, 300] select (_behaviour isEqualTo "combat")) do {
                    sleep 0.5;
                    {
                        private _p = getPosATL (_x select 0);
                        (_x select 2) pushBack _p;
                        if ((_x select 3) isEqualTo "") then { _x set [3, [_p] call _inPiece] };
                    } forEach _men;
                };
                {
                    _x params ["_u", "_to", "_trail", "_clip"];
                    private _reached = (_u distance2D _to) < 8;
                    private _gate = [_trail] call _viaGate;
                    // Where it left the walls: the last trail point within 2.5 m of a piece
                    private _left = [];
                    { private _p = _x; if ((_barriers findIf { (_x distance2D _p) < 2.5 }) > -1) then { _left = _p } } forEach _trail;
                    if (_clip isNotEqualTo "") then { _clips pushBack _clip };
                    if (!_reached) then { _stuck = _stuck + 1 } else { if (_gate) then { _gated = _gated + 1 } else { _gaps = _gaps + 1 } };
                    diag_log format ["OTROADMAN|%1|%2|%3|%4|%5|%6|%7|%8|%9", _town, _tier, _variant + " " + _behaviour, [0, 45, 90, 135, 180, 225, 270, 315] select _forEachIndex,
                        ["stuck", "out"] select _reached,
                        ["", ["by a gap", "through a gate"] select _gate] select _reached,
                        ["", _clip] select (_clip isNotEqualTo ""),
                        [[], _left call _model] select (_left isNotEqualTo []), (getPosATL _u) call _model];
                } forEach _men;
                { deleteVehicle (_x select 0) } forEach _men;
                diag_log format ["OTROADSUM|%1|%2|%3|%4|out by a gate %5, by a gap %6, not out %7|walked through a piece: %8 %9", _town, _tier, _variant, _behaviour, _gated, _gaps, _stuck, count _clips, _clips];
                sleep 1;
              } forEach ["safe", "combat"];
              call _off;
              sleep 1;
            } forEach _liveVariants;

            [_office] call OT_fnc_officeClearTemplate;
            [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeHide;
            sleep 2;
        } forEach _towns;

        player hideObjectGlobal false;
        player setPosASL _home;
        player allowDamage true;
        ["Road path experiment: towns tried", true, format ["%1 (OTROAD lines in the RPT)", _towns]] call OTQA_fnc_check;
    }, 3600]
]
