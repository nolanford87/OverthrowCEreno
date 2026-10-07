/*
    Description:
    Block probe (the "blockprobe" QA survey): the data to pick and build each town's occupier compound away from
    the game (tools/officegen/COMPOUND_PLAN.md), out to OTQA_blockReach m (150) round today's office. Lines,
    positions ASL, directions in degrees:
        OTBLOCK|town|HEAD|office class|[x,y,z]|direction|reach
        OTBLOCK|town|ROAD|type|width|[begin x,y,z]|[end x,y,z]  every road segment
        OTBLOCK|town|BLD|model or class|[x,y,z]|direction|[min x,min y,max x,max y,min z,max z]|[[door x,y], ...]|exits
            every building: its box (model coordinates), its doors (model x, y of each Door_N_trigger) and the
            number of its exits (buildingExit), 0 for one nobody can enter
        OTBLOCK|town|WALL|model or class|[x,y,z]|direction|[min x,min y,max x,max y,min z,max z]  walls and fences
        OTBLOCK|town|H|row|[height,...] the ground (ASL) every 3 m from -reach to reach (world axes: row j is
            y = office y + 3 * (j - half), the values x = office x + 3 * (i - half))
        OTBLOCK|town|END
        OTBLOCK|town|SHOT|height|fov|[width, height] a screenshot straight down, north up, height m above the office
    run-qa.ps1 -Suite blockprobe -Only "town,..." (else every town with an office layout).

    Returns: ARRAY - [[name, code, seconds]]
*/

[
    ["Block probe", {
        [""] call OT_fnc_officeLayout;
        private _only = missionNamespace getVariable ["OTQA_only", []];
        private _towns = if (_only isNotEqualTo []) then { _only } else { keys OT_officeLayouts };
        _towns = _towns select { _x in OT_officeLayouts };
        private _reach = missionNamespace getVariable ["OTQA_blockReach", 150];
        private _n = { params ["_v", ["_d", 2]]; format ["[%1]", (_v apply { _x toFixed _d }) joinString ","] };
        private _box = {
            params ["_o"];
            (boundingBoxReal _o) params ["_min", "_max"];
            [[_min select 0, _min select 1, _max select 0, _max select 1, _min select 2, _max select 2], 2] call _n
        };
        private _label = { [typeOf _this, (getModelInfo _this) select 0] select ((typeOf _this) isEqualTo "") };
        private _done = 0;
        {
            private _town = _x;
            (([_town] call OT_fnc_officeLayout) select 0) params ["_class", "_opos", "_odir"];
            private _pos = ASLToAGL _opos;
            // The area streamed in round the host
            player setPosASL (_opos vectorAdd [0, 0, 50]);
            sleep 3;
            diag_log format ["OTBLOCK|%1|HEAD|%2|%3|%4|%5", _town, _class, [_opos, 3] call _n, _odir toFixed 2, _reach];
            {
                (getRoadInfo _x) params ["_type", "_width", "", "", "", "", "_beg", "_end"];
                diag_log format ["OTBLOCK|%1|ROAD|%2|%3|%4|%5", _town, _type, _width toFixed 1, [_beg, 2] call _n, [_end, 2] call _n];
            } forEach (_pos nearRoads _reach);
            {
                private _b = _x;
                private _doors = [];
                for "_d" from 1 to 30 do {
                    private _p = _b selectionPosition [format ["Door_%1_trigger", _d], "Memory"];
                    if (_p isNotEqualTo [0, 0, 0]) then { _doors pushBack ([[_p select 0, _p select 1], 1] call _n) };
                };
                private _exits = 0;
                for "_e" from 0 to 9 do { if ((_b buildingExit _e) isNotEqualTo [0, 0, 0]) then { _exits = _exits + 1 } };
                diag_log format ["OTBLOCK|%1|BLD|%2|%3|%4|%5|[%6]|%7", _town, _b call _label, [getPosASL _b, 2] call _n, (getDir _b) toFixed 1, [_b] call _box, _doors joinString ",", _exits];
            } forEach ((nearestTerrainObjects [_pos, ["BUILDING", "HOUSE", "CHURCH", "CHAPEL", "FUELSTATION", "HOSPITAL", "RUIN", "BUNKER", "FORTRESS", "VIEW-TOWER", "LIGHTHOUSE", "TRANSMITTER", "WATERTOWER", "TOURISM"], _reach, false, true]) select { !isObjectHidden _x });
            {
                diag_log format ["OTBLOCK|%1|WALL|%2|%3|%4|%5", _town, _x call _label, [getPosASL _x, 2] call _n, (getDir _x) toFixed 1, [_x] call _box];
            } forEach ((nearestTerrainObjects [_pos, ["WALL", "FENCE"], _reach, false, true]) select { !isObjectHidden _x });
            private _half = ceil (_reach / 3);
            for "_j" from 0 to 2 * _half do {
                private _row = [];
                for "_i" from 0 to 2 * _half do {
                    _row pushBack ((getTerrainHeightASL [(_opos select 0) + 3 * (_i - _half), (_opos select 1) + 3 * (_j - _half)]) toFixed 1);
                };
                diag_log format ["OTBLOCK|%1|H|%2|[%3]", _town, _j, _row joinString ","];
            };
            diag_log format ["OTBLOCK|%1|END", _town];
            // A picture straight down on the office, north up, from a known height (OTB_<town>_top.png in the
            // profile's Screenshots folder), to set against the probe's map (tools/officegen/blocklib.py)
            private _cam = "camera" camCreate (ASLToAGL (_opos vectorAdd [0, 0, 120]));
            _cam setVectorDirAndUp [[0, 0, -1], [0, 1, 0]];
            _cam camSetFov 0.75;
            _cam cameraEffect ["INTERNAL", "BACK"];
            showCinemaBorder false;
            cameraEffectEnableHUD false;
            sleep 8; // The ground and the objects streamed in
            screenshot format ["OTB_%1_top.png", (_town splitString " ") joinString "_"];
            diag_log format ["OTBLOCK|%1|SHOT|120|0.75|%2", _town, getResolution select [0, 2]];
            sleep 1;
            _cam cameraEffect ["TERMINATE", "BACK"];
            camDestroy _cam;
            _done = _done + 1;
        } forEach _towns;
        ["Block probe: towns probed", _done isEqualTo (count _towns), format ["%1 (OTBLOCK lines in the RPT)", _towns]] call OTQA_fnc_check;
    }, 1800]
]
