/*
    Description:
    Class probe (the "classprobe" QA survey): the real size of every gate-like class the game has (CfgVehicles,
    "gate" in the name, scope 1+), for fitting gates into the office layouts' openings; or of the classes given
    with -Only (towers for the compounds' lookouts). Each is made away from everything, measured and taken off
    again. Lines:
        OTMEASURE|class|[length x, depth y, height z]|[centre x, centre y] the box's middle off the model's
            origin|[door animation sources]|[animation names]
        OTFLOORS|class|[[model x, model y, [heights above the model's base a man can stand on]], ...] on a 1 m
            grid over the box (the surfaces a line down meets, highest first)

    Returns: ARRAY - [[name, code, seconds]]
*/

[
    ["Class probe: gates", {
        private _classes = missionNamespace getVariable ["OTQA_only", []];
        if (_classes isEqualTo []) then {
            _classes = ("toLower configName _x find 'gate' > -1 && { getNumber (_x >> 'scope') >= 1 }" configClasses (configFile >> "CfgVehicles")) apply { configName _x };
        };
        private _spot = [1000, 1000, 0];
        private _done = 0;
        {
            private _o = createVehicle [_x, _spot, [], 0, "CAN_COLLIDE"];
            if (isNull _o) then { continue };
            _o setDir 0;
            _o setPosATL _spot;
            (boundingBoxReal _o) params ["_mn", "_mx"];
            private _sources = ("true" configClasses (configOf _o >> "AnimationSources")) apply { configName _x };
            diag_log format ["OTMEASURE|%1|%2|%3|%4|%5", _x,
                [(_mx select 0) - (_mn select 0), (_mx select 1) - (_mn select 1), (_mx select 2) - (_mn select 2)] apply { (round (_x * 100)) / 100 },
                [((_mx select 0) + (_mn select 0)) / 2, ((_mx select 1) + (_mn select 1)) / 2] apply { (round (_x * 100)) / 100 },
                _sources, animationNames _o];
            if ((missionNamespace getVariable ["OTQA_only", []]) isNotEqualTo []) then {
                // The floors: every surface a line straight down meets, on a 1 m grid
                private _base = (getPosASL _o) select 2;
                private _floors = [];
                for "_gx" from floor (_mn select 0) to ceil (_mx select 0) do {
                    for "_gy" from floor (_mn select 1) to ceil (_mx select 1) do {
                        private _top = _o modelToWorldWorld [_gx, _gy, (_mx select 2) + 1];
                        private _hits = lineIntersectsSurfaces [_top, _top vectorAdd [0, 0, -((_mx select 2) - (_mn select 2)) - 2], objNull, objNull, true, 10, "GEOM", "NONE"];
                        private _h = (_hits select { (_x select 2) isEqualTo _o && { ((_x select 1) select 2) > 0.7 } }) apply { (round ((((_x select 0) select 2) - _base) * 100)) / 100 };
                        if (_h isNotEqualTo []) then { _floors pushBack [_gx, _gy, _h] };
                    };
                };
                diag_log format ["OTFLOORS|%1|%2", _x, _floors];
            };
            deleteVehicle _o;
            _done = _done + 1;
            sleep 0.05;
        } forEach _classes;
        ["Class probe: gates measured", _done > 0, format ["%1 of %2 classes (OTMEASURE lines in the RPT)", _done, count _classes]] call OTQA_fnc_check;
    }, 600]
]
