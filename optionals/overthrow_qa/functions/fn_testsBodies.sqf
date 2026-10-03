/*
    Description:
    Bodies (OT_fnc_cleanDistantDead): bodies far from every player that have been dead a while are
    removed, near or fresh ones stay; a save with over 300 bodies removes the distant ones and goes
    ahead instead of refusing. Part of the current QA tests. Run it as the host; spawns and kills
    units well away from the host.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

// _n dead units around a position (civilians, out of the way)
OTQA_bodies_make = {
    params ["_pos", "_n"];
    private _grp = createGroup civilian;
    private _made = [];
    for "_i" from 1 to _n do {
        private _u = _grp createUnit ["C_man_1", _pos getPos [random 30, random 360], [], 0, "CAN_COLLIDE"];
        _u setDamage 1;
        _made pushBack _u;
    };
    _made
};

// Somewhere on land at least 1.5 km from the host
OTQA_bodies_far = {
    private _towns = OT_allTowns select { ((server getVariable _x) distance2D player) > 1500 };
    server getVariable (selectRandom _towns)
};

[
    ["Bodies far away and dead a while are removed, the rest stay", {
        private _far = [call OTQA_bodies_far, 3] call OTQA_bodies_make;
        private _near = [(getPosATL player) getPos [40, random 360], 2] call OTQA_bodies_make;
        private _fresh = [call OTQA_bodies_far, 2] call OTQA_bodies_make;
        sleep 1;
        // The far ones dead 11 minutes, the near and fresh ones just now
        { _x setVariable ["OT_deadSince", time - 660] } forEach (_far + _near);
        { _x setVariable ["OT_deadSince", time] } forEach _fresh;
        private _removed = [800, 600] call OT_fnc_cleanDistantDead;
        sleep 1;
        ["Bodies: far and dead 10+ minutes, removed", (_far findIf { !isNull _x }) isEqualTo -1, format ["%1 of 3 left, %2 removed in all", { !isNull _x } count _far, _removed]] call OTQA_fnc_check;
        ["Bodies: near a player, kept", (_near findIf { isNull _x }) isEqualTo -1, format ["%1 of 2 left", { !isNull _x } count _near]] call OTQA_fnc_check;
        ["Bodies: dead under 10 minutes, kept", (_fresh findIf { isNull _x }) isEqualTo -1, format ["%1 of 2 left", { !isNull _x } count _fresh]] call OTQA_fnc_check;
        { if (!isNull _x) then { deleteVehicle _x } } forEach (_near + _fresh);
    }, 30],

    ["Over 300 bodies: the save clears the distant ones and goes ahead", {
        private _need = (305 - (count allDeadMen)) max 0;
        private _pos = call OTQA_bodies_far;
        for "_i" from 1 to ceil (_need / 50) do { [_pos, 50 min _need] call OTQA_bodies_make; _need = _need - 50; sleep 0.5 };
        sleep 1;
        private _before = count allDeadMen;
        private _mark = str (round (random 1000000));
        server setVariable ["OTQA_saveMark", _mark, true];
        [objNull, true] call OT_fnc_saveGame;
        private _timeout = time + 30;
        waitUntil { sleep 0.5; !(missionNamespace getVariable ["OT_saving", false]) || { time > _timeout } };
        private _data = missionProfileNamespace getVariable [OT_saveName, []];
        private _saved = ((_data select { (_x select 0) == "OTQA_saveMark" }) param [0, ["", ""]]) select 1;
        ["Bodies: over 300 before the save", _before > 300, format ["%1", _before]] call OTQA_fnc_check;
        ["Bodies: the distant ones went", (count allDeadMen) < 300, format ["%1 -> %2", _before, count allDeadMen]] call OTQA_fnc_check;
        ["Bodies: the save went ahead", _saved isEqualTo _mark, format ["saved mark %1, expected %2", _saved, _mark]] call OTQA_fnc_check;
    }, 90]
];
