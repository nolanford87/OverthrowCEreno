/*
    Description:
    Occupier compound editor (the "compounds" QA suite, by hand; tools/officegen/COMPOUND_PLAN.md): each town's
    compound areas shown for the host to shape with Zeus. Every vertex is an arrow (T3 green, T4 yellow, T5 red)
    to drag; the edges are drawn between them (3D and on the map, labelled T3.0, T3.1, ... in order round the
    area). Actions (out of Zeus):
        Compound: add a vertex where you look   (on the nearest edge of any tier)
        Compound: delete the vertex you look at
        Compound: save this town                (logged; tells you of a lower tier's vertex outside the next)
        Compound: confirm this tier             (a town opens on T3 alone; each tier confirmed shows the next
                                                 with the ones inside it; all confirmed shows every tier)
        Compound: show tier N only / show the tiers for this step   (a filter; edits stay for the session)
        Compound: confirm the town, next town / skip to the next town / back to the previous town / finished
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

// The tiers a town has an area for
OTQA_compound_tiers = { params ["_town"]; [3, 4, 5] select { ((OT_officeCompounds getOrDefault [_town, []]) param [_x - 3, []]) isNotEqualTo [] } };
// The town shown's arrows kept as its areas for the rest of the session (OT_officeCompounds), so its edits stay
OTQA_compound_keep = {
    private _town = OTQA_compound getOrDefault ["town", ""];
    if (_town isEqualTo "") exitWith {};
    private _kept = +(OT_officeCompounds getOrDefault [_town, [[], [], []]]);
    { private _poly = [_x] call OTQA_compound_poly; if ((count _poly) >= 3) then { _kept set [_x - 3, _poly] } } forEach [3, 4, 5];
    OT_officeCompounds set [_town, _kept];
};
// The tiers shown: the others' arrows hidden and out of Zeus
OTQA_compound_setVisible = {
    params ["_tiers"];
    OTQA_compound set ["visible", _tiers];
    private _curator = getAssignedCuratorLogic player;
    {
        private _on = (_forEachIndex + 3) in _tiers;
        { _x hideObjectGlobal !_on } forEach _x;
        if (!isNull _curator) then {
            if (_on) then { _curator addCuratorEditableObjects [_x, false] } else { _curator removeCuratorEditableObjects [_x, false] };
        };
    } forEach (OTQA_compound get "verts");
};
OTQA_compound_visible = { params ["_tier"]; _tier in (OTQA_compound getOrDefault ["visible", [3, 4, 5]]) };
// The tiers to show for where the town's review is: the confirmed ones and the next (T3 alone at first), all when done
OTQA_compound_stageTiers = {
    private _town = OTQA_compound get "town";
    private _has = [_town] call OTQA_compound_tiers;
    private _done = (OTQA_compound get "confirmed") getOrDefault [_town, []];
    private _next = _has select { !(_x in _done) };
    if (_next isEqualTo []) exitWith { _has };
    _has select { _x <= (_next select 0) }
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
    call OTQA_compound_keep;
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
    [call OTQA_compound_stageTiers] call OTQA_compound_setVisible;
    // The host south of the office, the Zeus camera high above it looking down
    player setPosATL [_ox, _oy - 30, 0];
    if (!isNull curatorCamera) then {
        curatorCamera setPosASL [_ox, _oy - 45, (getTerrainHeightASL [_ox, _oy]) + 70];
        curatorCamera setVectorDirAndUp [[0, 0.55, -0.83], [0, 0.83, 0.55]];
    };
    private _towns = OTQA_compound get "towns";
    hint format ["Compound: %1 (%2 of %3)\nShowing T%4. Drag the arrows with Zeus (T3 green, T4 yellow, T5 red); add or delete vertices, confirm each tier and filter with your actions (out of Zeus).", _town, (_towns find _town) + 1, count _towns, (OTQA_compound get "visible") joinString ", T"];
};

// The polygon of a tier from its arrows, world [x, y]
OTQA_compound_poly = { params ["_tier"]; ((OTQA_compound getOrDefault ["verts", [[], [], []]]) param [_tier - 3, []]) apply { (getPosATL _x) select [0, 2] } };

OTQA_compound_addVertex = {
    private _aim = screenToWorld [0.5, 0.5];
    private _best = [1e9, -1, -1];
    {
        private _arr = _x;
        private _ti = _forEachIndex;
        private _n = count _arr;
        if (_n < 2 || { !([_ti + 3] call OTQA_compound_visible) }) then { continue };
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
        if !([_ti + 3] call OTQA_compound_visible) then { continue };
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
    call OTQA_compound_keep;
    hint format ["Compound: %1 saved%2", _town, ["", "\n" + (_warn joinString "\n")] select (_warn isNotEqualTo [])];
};
OTQA_compound_step = {
    params ["_by"];
    private _towns = OTQA_compound get "towns";
    private _i = ((_towns find (OTQA_compound get "town")) + _by + count _towns) mod (count _towns);
    [_towns select _i] call OTQA_compound_show;
};
// The next tier to confirm in the town shown, 0 when all are
OTQA_compound_nextTier = {
    private _town = OTQA_compound get "town";
    private _done = (OTQA_compound get "confirmed") getOrDefault [_town, []];
    (([_town] call OTQA_compound_tiers) select { !(_x in _done) }) param [0, 0]
};
OTQA_compound_confirmTier = {
    private _tier = call OTQA_compound_nextTier;
    if (_tier isEqualTo 0) exitWith {};
    private _town = OTQA_compound get "town";
    call OTQA_compound_save;
    private _done = (OTQA_compound get "confirmed") getOrDefault [_town, []];
    _done pushBackUnique _tier;
    (OTQA_compound get "confirmed") set [_town, _done];
    [call OTQA_compound_stageTiers] call OTQA_compound_setVisible;
    private _next = call OTQA_compound_nextTier;
    hint format ["Compound: %1 T%2 confirmed. %3", _town, _tier, ["Now T" + str _next + ", with the tiers inside it.", "Every tier confirmed: confirm the town to go on."] select (_next isEqualTo 0)];
};
OTQA_compound_confirm = {
    if ((call OTQA_compound_nextTier) isNotEqualTo 0) exitWith { hint "Compound: confirm each tier first" };
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
        OTQA_compound set ["confirmed", createHashMap];
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
                if !([_ti + 3] call OTQA_compound_visible) then { continue };
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
                    if ((count _poly) >= 2 && { [_x] call OTQA_compound_visible }) then {
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
            player addAction ["<t color='#80ff80'>Compound: confirm this tier</t>", { [OTQA_compound_confirmTier] call OTQA_compound_run }, nil, 1.98, false, true, "", _free + " && { (call OTQA_compound_nextTier) > 0 }"],
            player addAction ["<t color='#80ff80'>Compound: confirm the town, next town</t>", { [OTQA_compound_confirm] call OTQA_compound_run }, nil, 1.97, false, true, "", _free + " && { (call OTQA_compound_nextTier) isEqualTo 0 }"],
            player addAction ["<t color='#c0c0ff'>Compound: show tier 3 only</t>", { [[3]] call OTQA_compound_setVisible }, nil, 1.85, false, true, "", _free + " && { 3 in ([OTQA_compound get 'town'] call OTQA_compound_tiers) }"],
            player addAction ["<t color='#c0c0ff'>Compound: show tier 4 only</t>", { [[4]] call OTQA_compound_setVisible }, nil, 1.84, false, true, "", _free + " && { 4 in ([OTQA_compound get 'town'] call OTQA_compound_tiers) }"],
            player addAction ["<t color='#c0c0ff'>Compound: show tier 5 only</t>", { [[5]] call OTQA_compound_setVisible }, nil, 1.83, false, true, "", _free + " && { 5 in ([OTQA_compound get 'town'] call OTQA_compound_tiers) }"],
            player addAction ["<t color='#c0c0ff'>Compound: show the tiers for this step</t>", { [call OTQA_compound_stageTiers] call OTQA_compound_setVisible }, nil, 1.82, false, true, "", _free],
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
