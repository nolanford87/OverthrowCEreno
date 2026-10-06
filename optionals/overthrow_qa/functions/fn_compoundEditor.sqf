/*
    Description:
    Occupier compound editor (the "compounds" QA suite, by hand; tools/officegen/COMPOUND_PLAN.md): each town's
    compound areas shown for the host to shape with Zeus. Every vertex is an arrow (T3 green, T4 yellow, T5 red)
    to drag; the edges are drawn between them (3D and on the map, labelled T3.0, T3.1, ... in order round the
    area). Actions (out of Zeus):
        Compound: add a vertex where you look   (on the nearest edge of any tier)
        Compound: delete the vertex you look at
        Compound: save this town                (logged; tells you of a lower tier's vertex outside the next)
        Compound: confirm, next town / skip to the next town / back to the previous town / finished
    Saved lines, merged with tools/officegen/merge_compounds.py:
        OTCOMPOUND|world|town|tier|[[x,y],...]
        OTCOMPOUND|world|town|CONFIRMED
    run-qa.ps1 -Suite compounds -Only "town,..." (else every town with an area).

    Returns: ARRAY - [[name, code, seconds]]
*/

OTQA_compound = createHashMap;
OTQA_compound_classes = ["Sign_Arrow_Large_Green_F", "Sign_Arrow_Large_Yellow_F", "Sign_Arrow_Large_F"] apply { [_x, "Sign_Arrow_Large_F"] select !(isClass (configFile >> "CfgVehicles" >> _x)) };
OTQA_compound_colours = [[0.1, 0.9, 0.2, 1], [1, 0.85, 0, 1], [1, 0.15, 0.1, 1]];
OTQA_compound_markerColours = ["ColorGreen", "ColorYellow", "ColorRed"];

OTQA_compound_busy = { !scriptDone (OTQA_compound getOrDefault ["busy", scriptNull]) };
OTQA_compound_run = {
    params ["_code", ["_args", []]];
    if (call OTQA_compound_busy) exitWith { hint "Compound: wait, still setting up" };
    OTQA_compound set ["busy", _args spawn _code];
};

// The arrows of the town shown, per tier (3, 4, 5): [[objects in order], ...]
OTQA_compound_clear = {
    { { deleteVehicle _x } forEach _x } forEach (OTQA_compound getOrDefault ["verts", [[], [], []]]);
    OTQA_compound set ["verts", [[], [], []]];
    { deleteMarkerLocal format ["OTQA_compound_T%1", _x] } forEach [3, 4, 5];
};
OTQA_compound_arrow = {
    params ["_tier", "_xy"];
    private _o = createVehicle [OTQA_compound_classes select (_tier - 3), [0, 0, 0], [], 0, "CAN_COLLIDE"];
    _o setPosATL [_xy select 0, _xy select 1, 0];
    private _curator = getAssignedCuratorLogic player;
    if (!isNull _curator) then { _curator addCuratorEditableObjects [[_o], false] };
    _o
};
OTQA_compound_show = {
    params ["_town"];
    call OTQA_compound_clear;
    OTQA_compound set ["town", _town];
    [""] call OT_fnc_officeLayout;
    (((OT_officeLayouts getOrDefault [_town, []]) param [0, []]) param [1, [0, 0, 0]]) params ["_ox", "_oy"];
    private _verts = [[], [], []];
    {
        private _tier = _x;
        private _own = ((OT_officeCompounds getOrDefault [_town, []]) param [_tier - 3, []]);
        { (_verts select (_tier - 3)) pushBack ([_tier, _x] call OTQA_compound_arrow) } forEach _own;
    } forEach [3, 4, 5];
    OTQA_compound set ["verts", _verts];
    // The host south of the office, the Zeus camera high above it looking down
    player setPosATL [_ox, _oy - 30, 0];
    if (!isNull curatorCamera) then {
        curatorCamera setPosASL [_ox, _oy - 45, (getTerrainHeightASL [_ox, _oy]) + 70];
        curatorCamera setVectorDirAndUp [[0, 0.55, -0.83], [0, 0.83, 0.55]];
    };
    private _towns = OTQA_compound get "towns";
    hint format ["Compound: %1 (%2 of %3)\nDrag the arrows with Zeus (T3 green, T4 yellow, T5 red). Add or delete vertices and save with your actions (out of Zeus).", _town, (_towns find _town) + 1, count _towns];
};

// The polygon of a tier from its arrows, world [x, y]
OTQA_compound_poly = { params ["_tier"]; ((OTQA_compound get "verts") select (_tier - 3)) apply { (getPosATL _x) select [0, 2] } };

OTQA_compound_addVertex = {
    private _aim = screenToWorld [0.5, 0.5];
    private _best = [1e9, -1, -1];
    {
        private _arr = _x;
        private _ti = _forEachIndex;
        private _n = count _arr;
        if (_n < 2) then { continue };
        for "_i" from 0 to _n - 1 do {
            private _a = getPosATL (_arr select _i);
            private _b = getPosATL (_arr select ((_i + 1) mod _n));
            private _ab = _b vectorDiff _a; _ab set [2, 0];
            private _ap = _aim vectorDiff _a; _ap set [2, 0];
            private _l2 = (_ab vectorDotProduct _ab) max 0.01;
            private _t = 0 max (1 min ((_ap vectorDotProduct _ab) / _l2));
            private _d = (_a vectorAdd (_ab vectorMultiply _t)) distance2D _aim;
            if (_d < (_best select 0)) then { _best = [_d, _ti, _i] };
        };
    } forEach (OTQA_compound get "verts");
    _best params ["_d", "_ti", "_i"];
    if (_ti < 0 || { _d > 15 }) exitWith { hint "Compound: look at a spot within 15 m of an edge" };
    private _arr = (OTQA_compound get "verts") select _ti;
    _arr insert [_i + 1, [[_ti + 3, _aim] call OTQA_compound_arrow]];
    hint format ["Compound: vertex added to T%1 after T%1.%2", _ti + 3, _i];
};
OTQA_compound_deleteVertex = {
    private _aim = screenToWorld [0.5, 0.5];
    private _best = [1e9, -1, -1];
    {
        private _ti = _forEachIndex;
        { private _d = _x distance2D _aim; if (_d < (_best select 0)) then { _best = [_d, _ti, _forEachIndex] } } forEach _x;
    } forEach (OTQA_compound get "verts");
    _best params ["_d", "_ti", "_i"];
    if (_ti < 0 || { _d > 4 }) exitWith { hint "Compound: look at a vertex (within 4 m)" };
    private _arr = (OTQA_compound get "verts") select _ti;
    if ((count _arr) <= 3) exitWith { hint "Compound: an area needs 3 vertices at least" };
    deleteVehicle (_arr deleteAt _i);
    hint format ["Compound: T%1 vertex deleted", _ti + 3];
};
OTQA_compound_save = {
    private _town = OTQA_compound get "town";
    private _warn = [];
    {
        private _poly = [_x] call OTQA_compound_poly;
        if ((count _poly) >= 3) then {
            diag_log format ["OTCOMPOUND|%1|%2|%3|[%4]", worldName, _town, _x, (_poly apply { format ["[%1,%2]", (_x select 0) toFixed 2, (_x select 1) toFixed 2] }) joinString ","];
            // Tiers expand the compound: this tier's vertices inside the next one up
            private _up = [_x + 1] call OTQA_compound_poly;
            if ((count _up) >= 3) then {
                private _out = { !((_x + [0]) inPolygon (_up apply { _x + [0] })) } count _poly;
                if (_out > 0) then { _warn pushBack format ["%1 T%2 vertices outside T%3", _out, _x, _x + 1] };
            };
        };
    } forEach [3, 4, 5];
    hint format ["Compound: %1 saved%2", _town, ["", "\n" + (_warn joinString "\n")] select (_warn isNotEqualTo [])];
};
OTQA_compound_step = {
    params ["_by"];
    private _towns = OTQA_compound get "towns";
    private _i = ((_towns find (OTQA_compound get "town")) + _by + count _towns) mod (count _towns);
    [_towns select _i] call OTQA_compound_show;
};
OTQA_compound_confirm = {
    call OTQA_compound_save;
    diag_log format ["OTCOMPOUND|%1|%2|CONFIRMED", worldName, OTQA_compound get "town"];
    [1] call OTQA_compound_step;
};

[
    ["Occupier compounds", {
        ["", 3] call OT_fnc_officeCompound; // OT_officeCompounds read
        private _towns = missionNamespace getVariable ["OTQA_only", []];
        if (_towns isEqualTo []) then { _towns = keys OT_officeCompounds; _towns sort true };
        _towns = _towns select { _x in OT_officeCompounds };
        if (_towns isEqualTo []) exitWith { ["Compound: towns with an area", false, "none"] call OTQA_fnc_check };
        OTQA_compound set ["towns", _towns];
        OTQA_compound set ["finished", false];
        player allowDamage false;
        player setCaptive true;
        private _until = time + 60;
        waitUntil { sleep 1; !isNull (getAssignedCuratorLogic player) || { time > _until } };
        [OTQA_compound_show, [_towns select 0]] call OTQA_compound_run;

        // The edges, in 3D (Zeus too) and on the map
        private _draw = addMissionEventHandler ["Draw3D", {
            {
                private _arr = _x;
                private _ti = _forEachIndex;
                private _col = OTQA_compound_colours select _ti;
                private _n = count _arr;
                {
                    private _a = (getPosATL _x) vectorAdd [0, 0, 1.5];
                    private _b = (getPosATL (_arr select ((_forEachIndex + 1) mod _n))) vectorAdd [0, 0, 1.5];
                    if (_n > 1) then { drawLine3D [ASLToAGL (ATLToASL _a), ASLToAGL (ATLToASL _b), _col] };
                    drawIcon3D ["", _col, ASLToAGL (ATLToASL ((getPosATL _x) vectorAdd [0, 0, 4])), 0, 0, 0, format ["T%1.%2", _ti + 3, _forEachIndex], 2, 0.045, "PuristaBold"];
                } forEach _arr;
            } forEach (OTQA_compound getOrDefault ["verts", []]);
        }];
        [] spawn {
            while { !(OTQA_compound getOrDefault ["finished", false]) } do {
                {
                    private _poly = [_x] call OTQA_compound_poly;
                    private _m = format ["OTQA_compound_T%1", _x];
                    if ((count _poly) >= 2) then {
                        if (markerShape _m isEqualTo "") then { createMarkerLocal [_m, [0, 0]]; _m setMarkerShapeLocal "POLYLINE"; _m setMarkerColorLocal (OTQA_compound_markerColours select (_x - 3)) };
                        private _line = [];
                        { _line append _x } forEach (_poly + [_poly select 0]);
                        _m setMarkerPolylineLocal _line;
                    } else { deleteMarkerLocal _m };
                } forEach [3, 4, 5];
                sleep 1;
            };
        };

        private _free = "!(call OTQA_compound_busy)";
        private _actions = [
            player addAction ["<t color='#c0ffc0'>Compound: save this town</t>", { [OTQA_compound_save] call OTQA_compound_run }, nil, 2, false, true, "", _free],
            player addAction ["<t color='#80ff80'>Compound: confirm, next town</t>", { [OTQA_compound_confirm] call OTQA_compound_run }, nil, 1.97, false, true, "", _free],
            player addAction ["<t color='#ffc080'>Compound: add a vertex where you look</t>", { call OTQA_compound_addVertex }, nil, 1.9, false, true, "", _free],
            player addAction ["<t color='#ff8080'>Compound: delete the vertex you look at</t>", { call OTQA_compound_deleteVertex }, nil, 1.89, false, true, "", _free],
            player addAction ["<t color='#80c0ff'>Compound: skip to the next town</t>", { [OTQA_compound_step, [1]] call OTQA_compound_run }, nil, 1.8, false, true, "", _free],
            player addAction ["<t color='#80c0ff'>Compound: back to the previous town</t>", { [OTQA_compound_step, [-1]] call OTQA_compound_run }, nil, 1.79, false, true, "", _free],
            player addAction ["<t color='#ffc080'>Compound: finished</t>", { OTQA_compound set ["finished", true] }, nil, 1.7, false, true, "", "true"]
        ];
        waitUntil { sleep 1; OTQA_compound getOrDefault ["finished", false] };
        { player removeAction _x } forEach _actions;
        removeMissionEventHandler ["Draw3D", _draw];
        call OTQA_compound_clear;
        player allowDamage true;
        ["Compound: finished by the author", true, "OTCOMPOUND lines in the RPT (merge with tools/officegen/merge_compounds.py)"] call OTQA_fnc_check;
    }, 1e7]
]
