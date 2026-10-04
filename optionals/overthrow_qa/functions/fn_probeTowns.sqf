/*
    Description:
    Town office probe (the "townprobe" QA survey): for each town whose mayor's office layout isn't done (or
    the towns asked for), the data to draft its layout away from the game (tools/officegen/townlib.py).
    The office is the layout editor's (OTQA_townLayout_guess: the bracket's candidate standing in the town,
    else one spawned near the centre, at a spot recorded here and taken away again). Lines, positions ASL:
        OTTOWN|town|HEAD|template key|class|[x,y,z]|direction|spawned|population|bracket|highest tier
        OTTOWN|town|BOX|[min x,min y,max x,max y,min z,max z] the office's bounding box, model coordinates
        OTTOWN|town|DOOR|main/back/side|[x,y,z]|outward direction|width (the template's doorway markers)
        OTTOWN|town|BPOS|[[x,y,z],...] the office's building positions (floors), ten to a line
        OTTOWN|town|OBJ|building/wall/tree/rock/part|model|[x,y,z]|direction|[min x,min y,max x,max y,min z,max z]
            every terrain object of those kinds within 45 m of the office (a part: the office's other pieces)
        OTTOWN|town|ROAD|type|width|[begin x,y,z]|[end x,y,z]  every road segment within 60 m
        OTTOWN|town|H|row|[height,...] the ground (ASL) every 2 m from -44 to 44 m round the office (world axes:
            row j is y = office y + 2 * (j - 22), the values x = office x + 2 * (i - 22))
        OTTOWN|town|END
    run-qa.ps1 -Suite townprobe -Only "town,..." probes those towns only (done or not).

    Returns: ARRAY - [[name, code, seconds]]
*/

[
    ["Town office probe", {
        call OTQA_fnc_officeReview;
        call OTQA_fnc_townLayout;
        private _only = missionNamespace getVariable ["OTQA_only", []];
        private _towns = if (_only isNotEqualTo []) then { _only select { _x in OT_allTowns } } else { OT_allTowns select { [_x] call OTQA_townLayout_unfinished } };
        private _kinds = [
            ["building", ["BUILDING", "HOUSE", "CHURCH", "CHAPEL", "FUELSTATION", "HOSPITAL", "RUIN", "BUNKER", "FORTRESS", "VIEW-TOWER", "LIGHTHOUSE", "QUAY", "TRANSMITTER", "WATERTOWER", "POWERSOLAR", "POWERWIND", "SHIPWRECK", "STACK", "TOURISM"]],
            ["wall", ["WALL", "FENCE"]],
            ["tree", ["TREE"]],
            ["rock", ["ROCK", "ROCKS"]]
        ];
        private _n = { params ["_v", ["_d", 2]]; format ["[%1]", (_v apply { _x toFixed _d }) joinString ","] };
        private _box = {
            params ["_o"];
            (boundingBoxReal _o) params ["_min", "_max"];
            [[_min select 0, _min select 1, _max select 0, _max select 1, _min select 2, _max select 2], 2] call _n
        };
        private _done = 0;
        {
            private _town = _x;
            private _layout = [_town] call OT_fnc_officeLayout;
            private _b = objNull;
            private _parts = [];
            private _spawned = false;
            if (_layout isNotEqualTo []) then {
                (_layout select 0) params ["_class", "_pos", "_dir", ["_wasSpawned", false]];
                _b = (nearestObjects [ASLToAGL _pos, [_class], 3, true]) param [0, objNull];
                if (isNull _b) then { _b = createVehicle [_class, [0, 0, 0], [], 0, "CAN_COLLIDE"]; _b setDir _dir; _b setPosASL _pos };
                _spawned = _wasSpawned;
                _parts = [[_b] call OT_fnc_officeTemplateKey, _b] call OTQA_officeReview_realParts;
            } else {
                ([_town] call OTQA_townLayout_guess) params ["_g", "_gParts", "_gSpawned"];
                _b = _g;
                _parts = _gParts;
                _spawned = _gSpawned;
            };
            if (isNull _b) then { diag_log format ["OTTOWN|%1|NONE", _town]; continue };
            private _key = [_b] call OT_fnc_officeTemplateKey;
            private _pos = getPosASL _b;
            diag_log format ["OTTOWN|%1|HEAD|%2|%3|%4|%5|%6|%7|%8|%9", _town, _key, typeOf _b, [_pos, 3] call _n, (getDir _b) toFixed 2, _spawned,
                server getVariable [format ["population%1", _town], 0], [_town] call OTQA_townLayout_bracket, [_town] call OTQA_townLayout_cap];
            diag_log format ["OTTOWN|%1|BOX|%2", _town, [_b] call _box];
            {
                {
                    if ((_x select 0) isEqualTo "doorway") then {
                        _x params ["", "_role", "_p", "_d", ["_extra", []]];
                        diag_log format ["OTTOWN|%1|DOOR|%2|%3|%4|%5", _town, _role, [AGLToASL (_b modelToWorld _p), 2] call _n, ((getDir _b) + _d) toFixed 1, (_extra param [0, 0]) toFixed 2];
                    };
                } forEach _x;
            } forEach ([_key] call OT_fnc_officeTemplate);
            private _bpos = (_b buildingPos -1) apply { AGLToASL _x };
            for "_i" from 0 to (count _bpos - 1) step 10 do {
                diag_log format ["OTTOWN|%1|BPOS|[%2]", _town, ((_bpos select [_i, 10]) apply { [_x, 2] call _n }) joinString ","];
            };
            { diag_log format ["OTTOWN|%1|OBJ|part|%2|%3|%4|%5", _town, typeOf _x, [getPosASL _x, 2] call _n, (getDir _x) toFixed 1, [_x] call _box] } forEach _parts;
            {
                _x params ["_label", "_types"];
                {
                    if (_x isNotEqualTo _b && { !(_x in _parts) } && { !isObjectHidden _x }) then {
                        private _model = (getModelInfo _x) select 0;
                        diag_log format ["OTTOWN|%1|OBJ|%2|%3|%4|%5|%6", _town, _label, [typeOf _x, _model] select ((typeOf _x) isEqualTo ""), [getPosASL _x, 2] call _n, (getDir _x) toFixed 1, [_x] call _box];
                    };
                } forEach (nearestTerrainObjects [_pos, _types, 45, false, true]);
            } forEach _kinds;
            {
                (getRoadInfo _x) params ["_type", "_width", "", "", "", "", "_beg", "_end"];
                diag_log format ["OTTOWN|%1|ROAD|%2|%3|%4|%5", _town, _type, _width toFixed 1, [_beg, 2] call _n, [_end, 2] call _n];
            } forEach (_pos nearRoads 60);
            for "_j" from 0 to 44 do {
                private _row = [];
                for "_i" from 0 to 44 do {
                    _row pushBack ((getTerrainHeightASL [(_pos select 0) + 2 * (_i - 22), (_pos select 1) + 2 * (_j - 22)]) toFixed 2);
                };
                diag_log format ["OTTOWN|%1|H|%2|[%3]", _town, _j, _row joinString ","];
            };
            diag_log format ["OTTOWN|%1|END", _town];
            if (_spawned) then { { deleteVehicle _x } forEach ([_b] + _parts) };
            _done = _done + 1;
            sleep 0.05;
        } forEach _towns;
        ["Town office probe: towns probed", _done isEqualTo (count _towns), format ["%1 of %2 (OTTOWN lines in the RPT)", _done, count _towns]] call OTQA_fnc_check;
    }, 1800]
]
