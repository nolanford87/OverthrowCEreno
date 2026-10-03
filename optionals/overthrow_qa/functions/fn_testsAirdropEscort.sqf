/*
    Description:
    Airdrop changes: the armed Blackfish comes in from off the map when the occupier holds no airfield
    (OT_fnc_NATOoffMapPoint), and a tank airdrop (OT_fnc_NATOdeliverHeavy) is escorted by the occupier's
    attack helicopter (OT_fnc_NATOattackHelicopter, OT_fnc_NATOairdropEscort) while it holds an airfield.
    Real deliveries to the occupier base nearest the host, with the airfields it holds forced
    (OT_testAirfields: none, one or two of the map's airfields, held or not). Part of the current QA tests.
    1. The off-map point: outside the map, 1.5 km beyond a random edge (or the nearest one)
    2. No airfield: the Blackfish starts off the map, no escort
    3. One airfield: the Blackfish starts over it, the helicopter on the ground there and takes off,
       gets to the drop zone before the drop, follows the tank, leaves when it's delivered and goes once
       no player is within 2 km (the host is moved away for that)
    4. Two airfields: the helicopter starts flying over the nearest; shot down, the delivery carries on
    5. No escort for a FOB vehicle's airdrop (OT_fnc_NATOairdropVehicle on its own) nor a convoy
    6. No attack helicopter in the occupier's template: no escort; the class picked otherwise
    The QA runner makes deliveries set off at once (OT_deliveryDelay 0): the Blackfish then sets off once
    the helicopter's head start is up. The host is undercover and can't be hurt while they run.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Airdrop escort: with no airfield held, the Blackfish comes in over a map edge and flies back out over the nearest edge after the drop" call OTQA_fnc_manual;
"Airdrop escort: holding one airfield, the attack helicopter starts up and takes off cleanly from a helipad / open spot at it (not inside a hangar or on a parked aircraft)" call OTQA_fnc_manual;
"Airdrop escort: the helicopter circles the drop zone and fires on resistance (not undercover) there before the drop, then circles over the tank on its drive and fires on threats near it; a reported airdrop's task mentions it" call OTQA_fnc_manual;

// The occupier base nearest the host that it still holds: [position, name]
OTQA_esc_base = {
    private _abandoned = server getVariable ["NATOabandoned", []];
    private _bases = (OT_objectiveData + OT_airportData) select { !((_x select 1) in _abandoned) };
    if (_bases isEqualTo []) exitWith { [] };
    private _base = ([_bases, [], { (_x select 0) distance2D player }, "ASCEND"] call BIS_fnc_sortBy) select 0;
    [_base select 0, _base select 1];
};

// The _count airfields of the map nearest a position (held or not) as [[position, name], ...], the
// nearest one again under another name when the map has fewer
OTQA_esc_airfields = {
    params ["_pos", "_count"];
    private _sorted = [OT_airportData, [], { (_x select 0) distance2D _pos }, "ASCEND"] call BIS_fnc_sortBy;
    private _list = (_sorted select [0, _count]) apply { [_x select 0, _x select 1] };
    while { (count _list) < _count && { _list isNotEqualTo [] } } do {
        _list pushBack [(_list select 0) select 0, format ["%1 (QA %2)", (_list select 0) select 1, count _list]];
    };
    _list;
};

// The occupier base nearest the host that a convoy can reach (by OT_fnc_NATOdeliverHeavy's rules)
OTQA_esc_convoyBase = {
    private _abandoned = server getVariable ["NATOabandoned", []];
    private _sources = [];
    if !(OT_NATO_HQ in _abandoned) then { _sources pushBack [OT_NATO_HQPos, OT_NATO_HQ] };
    if !("Factory" in (server getVariable ["GEURowned", []])) then { _sources pushBack [OT_factoryPos, "Factory"] };
    { if !((_x select 1) in _abandoned) then { _sources pushBack [_x select 0, _x select 1] } } forEach (OT_objectiveData + OT_airportData + OT_commsData);
    private _bases = (OT_objectiveData + OT_airportData) select {
        private _basePos = _x select 0;
        private _baseName = _x select 1;
        !(_baseName in _abandoned) && {
            _sources findIf {
                (_x select 1) isNotEqualTo _baseName && { ((_x select 0) distance2D _basePos) >= 4000 } && { [_x select 0, _basePos] call OT_fnc_regionIsConnected } && { ((_x select 0) nearRoads 50) isNotEqualTo [] }
            } > -1
        }
    };
    if (_bases isEqualTo []) exitWith { [] };
    private _base = ([_bases, [], { (_x select 0) distance2D player }, "ASCEND"] call BIS_fnc_sortBy) select 0;
    [_base select 0, _base select 1];
};

// Escort helicopters / Blackfish / delivered tanks for a base
OTQA_esc_helis = { params ["_baseName"]; vehicles select { (_x getVariable ["OT_escortFor", ""]) isEqualTo _baseName } };
OTQA_esc_planes = { params ["_baseName"]; vehicles select { (_x getVariable ["OT_airdropFor", ""]) isEqualTo _baseName } };
OTQA_esc_tanks = { params ["_baseName", "_type"]; vehicles select { (_x getVariable ["vehgarrison", ""]) isEqualTo _baseName && { typeOf _x isEqualTo _type } } };

// A tank delivery to a base with the airfields held forced: [script, base position, base name, tank class,
// helicopters, Blackfish and tanks there before], [] when there's no base or no tank
OTQA_esc_start = {
    params ["_method", "_airfields", ["_base", []], ["_chance", 0]];
    if (_base isEqualTo []) then { _base = call OTQA_esc_base };
    if (_base isEqualTo [] || { OT_NATO_Vehicles_TankSupport isEqualTo [] }) exitWith { [] };
    _base params ["_basePos", "_baseName"];
    private _type = selectRandom OT_NATO_Vehicles_TankSupport;
    // On the base's list first, like a trade (OT_fnc_NATOupgradeHeavyGarrisons)
    private _list = server getVariable [format ["vehgarrison%1", _baseName], []];
    _list pushBack _type;
    server setVariable [format ["vehgarrison%1", _baseName], _list, true];
    OT_testAirfields = _airfields;
    OT_deliveryIntelChance = _chance;
    private _before = ([_baseName] call OTQA_esc_helis) + ([_baseName] call OTQA_esc_planes) + ([_baseName, _type] call OTQA_esc_tanks);
    private _script = [_type, _baseName, _basePos, _method] spawn OT_fnc_NATOdeliverHeavy;
    sleep 2;
    OT_deliveryIntelChance = nil;
    [_script, _basePos, _baseName, _type, _before];
};

// Waits for a new vehicle from a list: the vehicle, objNull if none in time
OTQA_esc_waitFor = {
    params ["_code", "_args", "_before", "_seconds"];
    private _found = objNull;
    private _timeout = time + _seconds;
    waitUntil {
        sleep 1;
        _found = ((_args call _code) - _before) param [0, objNull];
        !isNull _found || { time > _timeout }
    };
    _found;
};

// Removes a vehicle and its crew (and a parachute it hangs from)
OTQA_esc_delete = {
    params ["_v"];
    if (isNull _v) exitWith {};
    private _g = group driver _v;
    { deleteVehicle _x } forEach (crew _v);
    { detach _x; deleteVehicle _x } forEach (attachedObjects _v);
    if (!isNull attachedTo _v) then { deleteVehicle (attachedTo _v) };
    deleteVehicle _v;
    if (!isNull _g) then { deleteGroup _g };
};

// Removes a test delivery: the script, the new helicopters, Blackfish and tanks for the base, its entry
// on the base's list; the airfields held back to the real ones
OTQA_esc_cleanup = {
    params ["_script", "_baseName", "_type", "_before"];
    terminate _script;
    {
        [_x] call OTQA_esc_delete;
    } forEach ((([_baseName] call OTQA_esc_helis) + ([_baseName] call OTQA_esc_planes) + ([_baseName, _type] call OTQA_esc_tanks) + (vehicles select { (_x getVariable ["OT_escort", ""]) isEqualTo _baseName })) - _before);
    private _list = server getVariable [format ["vehgarrison%1", _baseName], []];
    private _index = _list find _type;
    if (_index > -1) then { _list deleteAt _index };
    server setVariable [format ["vehgarrison%1", _baseName], _list, true];
    OT_testAirfields = nil;
};

// The host undercover and unhurt while a test runs (the helicopter attacks the resistance it sees)
OTQA_esc_protect = {
    OTQA_esc_wasCaptive = captive player;
    OTQA_esc_home = getPosATL player;
    player setCaptive true;
    player allowDamage false;
};
OTQA_esc_unprotect = {
    player setPosATL OTQA_esc_home;
    player setCaptive OTQA_esc_wasCaptive;
    player allowDamage true;
};

// Outside the map
OTQA_esc_outside = {
    params ["_p"];
    private _w = worldSize;
    (_p select 0) < 0 || { (_p select 0) > _w } || { (_p select 1) < 0 } || { (_p select 1) > _w }
};

[
    ["Escort 1: the off-map point", {
        OT_testAirfields = nil;
        private _w = worldSize;
        private _bad = [];
        for "_i" from 1 to 40 do {
            private _p = [[random _w, random _w]] call OT_fnc_NATOoffMapPoint;
            // 1.5 km beyond one edge, level with the map on the other axis
            private _beyond = (((-(_p select 0)) max ((_p select 0) - _w)) max (-(_p select 1))) max ((_p select 1) - _w);
            private _along = [_p select 1, _p select 0] select (((_p select 0) >= 0) && { (_p select 0) <= _w });
            if !((_beyond > 1400) && { _beyond < 1600 } && { _along >= 0 } && { _along <= _w }) then { _bad pushBack _p };
        };
        ["Off-map point: 1.5 km beyond a map edge, along the map", _bad isEqualTo [], format ["map %1 m, %2 bad: %3", _w, count _bad, _bad select [0, 3]]] call OTQA_fnc_check;
        private _nearest = [[300, _w * 0.6], true] call OT_fnc_NATOoffMapPoint;
        ["Off-map point: the nearest edge from near the west edge is the west edge", (_nearest select 0) < 0 && { abs ((_nearest select 1) - _w * 0.6) < 1 }, str _nearest] call OTQA_fnc_check;
    }, 30],

    ["Escort 2: no airfield: the Blackfish from off the map, no escort", {
        call OTQA_esc_protect;
        private _run = ["airdrop", []] call OTQA_esc_start;
        if (_run isEqualTo []) exitWith { OT_testAirfields = nil; call OTQA_esc_unprotect; "Escort 2 skipped: no occupier base or no tanks" call OTQA_fnc_manual };
        _run params ["_script", "_basePos", "_baseName", "_type", "_before"];
        private _plane = [OTQA_esc_planes, [_baseName], _before, 60] call OTQA_esc_waitFor;
        private _origin = [];
        if (!isNull _plane) then { _origin = _plane getVariable ["OT_airdropOrigin", []] };
        ["No airfield: the Blackfish starts outside the map", _origin isNotEqualTo [] && { [_origin] call OTQA_esc_outside },
            format ["origin %1, map %2 m, %3 m from the base", _origin, worldSize, [round (_origin distance2D _basePos), -1] select (_origin isEqualTo [])]] call OTQA_fnc_check;
        sleep 15;
        private _helis = ([_baseName] call OTQA_esc_helis) - _before;
        ["No airfield: no escort helicopter", _helis isEqualTo [], str (_helis apply { typeOf _x })] call OTQA_fnc_check;
        [_script, _baseName, _type, _before] call OTQA_esc_cleanup;
        call OTQA_esc_unprotect;
    }, 120],

    ["Escort 3: one airfield: take-off, scouting, escort, leaving", {
        call OTQA_esc_protect;
        private _base = call OTQA_esc_base;
        if (_base isEqualTo []) exitWith { call OTQA_esc_unprotect; "Escort 3 skipped: no occupier base" call OTQA_fnc_manual };
        private _airfields = [_base select 0, 1] call OTQA_esc_airfields;
        if (_airfields isEqualTo []) exitWith { call OTQA_esc_unprotect; "Escort 3 skipped: the map has no airfield" call OTQA_fnc_manual };
        if ((call OT_fnc_NATOattackHelicopter) isEqualTo "") exitWith { call OTQA_esc_unprotect; "Escort 3 skipped: the occupier has no attack helicopter" call OTQA_fnc_manual };
        private _airfieldPos = (_airfields select 0) select 0;
        private _run = ["airdrop", _airfields, _base, 100] call OTQA_esc_start;
        if (_run isEqualTo []) exitWith { OT_testAirfields = nil; call OTQA_esc_unprotect; "Escort 3 skipped: no tanks" call OTQA_fnc_manual };
        _run params ["_script", "_basePos", "_baseName", "_type", "_before"];
        private _label = format ["%1 from %2", _baseName, (_airfields select 0) select 1];

        // On the ground at the airfield, crewed, engine running
        private _heli = [OTQA_esc_helis, [_baseName], _before, 30] call OTQA_esc_waitFor;
        private _vanilla = ["O_Heli_Attack_02_dynamicLoadout_F", "B_Heli_Attack_01_dynamicLoadout_F", "I_Heli_light_03_dynamicLoadout_F"];
        ["One airfield: the occupier's attack helicopter escorts it", !isNull _heli && { (typeOf _heli) isKindOf "Helicopter" } && { ((typeOf _heli) in OT_NATO_Vehicles_AirSupport) || { (typeOf _heli) in _vanilla } } && { side group driver _heli isEqualTo blufor },
            format ["%1 (template %2), %3", typeOf _heli, OT_NATO_Vehicles_AirSupport, _label]] call OTQA_fnc_check;
        if (isNull _heli) exitWith { [_script, _baseName, _type, _before] call OTQA_esc_cleanup; call OTQA_esc_unprotect };
        private _startPos = _heli getVariable ["OT_escortStartPos", [0, 0, 999]];
        ["One airfield: it starts on the ground at the airfield, engine on", (_heli getVariable ["OT_escortStart", ""]) isEqualTo "ground" && { (_startPos select 2) < 3 } && { (_startPos distance2D _airfieldPos) < 700 } && { isEngineOn _heli },
            format ["%1 m up, %2 m from the airfield, engine %3", round (_startPos select 2), round (_startPos distance2D _airfieldPos), isEngineOn _heli]] call OTQA_fnc_check;

        // It takes off
        private _timeout = time + 120;
        waitUntil { sleep 1; !alive _heli || { ((getPosATL _heli) select 2) > 20 } || { time > _timeout } };
        ["One airfield: it takes off", alive _heli && { ((getPosATL _heli) select 2) > 20 }, format ["%1 m up after %2 s", round ((getPosATL _heli) select 2), round (time - (_timeout - 120))]] call OTQA_fnc_check;

        // The Blackfish, later, from the same airfield
        private _plane = [OTQA_esc_planes, [_baseName], _before, 600] call OTQA_esc_waitFor;
        private _origin = [];
        if (!isNull _plane) then { _origin = _plane getVariable ["OT_airdropOrigin", []] };
        ["One airfield: the Blackfish starts over the airfield", _origin isNotEqualTo [] && { (_origin distance2D _airfieldPos) < 50 },
            format ["%1 m from the airfield", [round (_origin distance2D _airfieldPos), -1] select (_origin isEqualTo [])]] call OTQA_fnc_check;
        if (isNull _plane) exitWith { [_script, _baseName, _type, _before] call OTQA_esc_cleanup; call OTQA_esc_unprotect };
        sleep 5;
        private _taskId = _plane getVariable ["OT_interceptTask", ""];
        ["One airfield: the intelligence report mentions the escort", _taskId isNotEqualTo "" && { ((str (_taskId call BIS_fnc_taskDescription)) find "scout the drop zone") > -1 },
            format ["task %1", _taskId]] call OTQA_fnc_check;

        // At the drop zone before the drop
        _timeout = time + 900;
        waitUntil { sleep 2; !alive _plane || { (_plane getVariable ["OT_dropTime", -1]) >= 0 } || { time > _timeout } };
        private _dropTime = _plane getVariable ["OT_dropTime", -1];
        private _atLZ = _heli getVariable ["OT_escortAtLZ", -1];
        ["One airfield: the helicopter reaches the drop zone before the Blackfish drops", _dropTime >= 0 && { _atLZ >= 0 } && { _atLZ < _dropTime },
            format ["at the drop zone %1 s before the drop", [round (_dropTime - _atLZ), "never"] select (_atLZ < 0)]] call OTQA_fnc_check;

        // Over the tank after the drop
        private _tank = _plane getVariable ["OT_deliveryCargo", objNull];
        _timeout = time + 240;
        waitUntil { sleep 2; !alive _heli || { (_heli getVariable ["OT_escortPhase", ""]) isEqualTo "escort" } || { time > _timeout } };
        sleep 40;
        ["One airfield: it escorts the tank after the drop", alive _tank && { alive _heli } && { (_heli getVariable ["OT_escortPhase", ""]) isEqualTo "escort" } && { (_heli distance2D _tank) < 700 },
            format ["phase %1, %2 m from the tank", _heli getVariable ["OT_escortPhase", ""], round (_heli distance2D _tank)]] call OTQA_fnc_check;
        if (!alive _tank || { !alive _heli }) exitWith { [_script, _baseName, _type, _before] call OTQA_esc_cleanup; call OTQA_esc_unprotect };

        // Delivered (moved next to the base): it leaves
        private _near = _basePos findEmptyPosition [20, 150, _type];
        if (_near isEqualTo []) then { _near = _basePos };
        _tank setPosATL _near;
        _timeout = time + 60;
        waitUntil { sleep 2; !alive _heli || { (_heli getVariable ["OT_escortPhase", ""]) isEqualTo "leave" } || { time > _timeout } };
        ["One airfield: the tank delivered, the helicopter leaves", alive _heli && { (_heli getVariable ["OT_escortPhase", ""]) isEqualTo "leave" }, _heli getVariable ["OT_escortPhase", ""]] call OTQA_fnc_check;

        // Gone once no player is within 2 km: the host moved 3 km from it and the base
        private _away = [];
        {
            private _p = _heli getPos [3500, _x];
            if (!surfaceIsWater _p && { !([_p] call OTQA_esc_outside) } && { (_p distance2D _basePos) > 3000 }) exitWith { _away = _p };
        } forEach [0, 45, 90, 135, 180, 225, 270, 315];
        if (_away isEqualTo []) then { _away = _heli getPos [3500, 0] };
        private _spot = _away findEmptyPosition [0, 100, "CAManBase"];
        if (_spot isEqualTo []) then { _spot = _away };
        player setPosATL _spot;
        _timeout = time + 40;
        waitUntil { sleep 1; isNull _heli || { time > _timeout } };
        ["One airfield: once no player is near, it's removed", isNull _heli, format ["still there, %1 m from the host", round (_heli distance2D player)]] call OTQA_fnc_check;

        [_script, _baseName, _type, _before] call OTQA_esc_cleanup;
        call OTQA_esc_unprotect;
    }, 1500],

    ["Escort 4: two airfields: starts flying; shot down, the delivery carries on", {
        call OTQA_esc_protect;
        private _base = call OTQA_esc_base;
        if (_base isEqualTo []) exitWith { call OTQA_esc_unprotect; "Escort 4 skipped: no occupier base" call OTQA_fnc_manual };
        private _airfields = [_base select 0, 2] call OTQA_esc_airfields;
        if (_airfields isEqualTo []) exitWith { call OTQA_esc_unprotect; "Escort 4 skipped: the map has no airfield" call OTQA_fnc_manual };
        if ((call OT_fnc_NATOattackHelicopter) isEqualTo "") exitWith { call OTQA_esc_unprotect; "Escort 4 skipped: the occupier has no attack helicopter" call OTQA_fnc_manual };
        private _run = ["airdrop", _airfields, _base] call OTQA_esc_start;
        if (_run isEqualTo []) exitWith { OT_testAirfields = nil; call OTQA_esc_unprotect; "Escort 4 skipped: no tanks" call OTQA_fnc_manual };
        _run params ["_script", "_basePos", "_baseName", "_type", "_before"];

        // Flying over one of them
        private _heli = [OTQA_esc_helis, [_baseName], _before, 30] call OTQA_esc_waitFor;
        if (isNull _heli) exitWith {
            ["Two airfields: an escort helicopter", false, "none"] call OTQA_fnc_check;
            [_script, _baseName, _type, _before] call OTQA_esc_cleanup;
            call OTQA_esc_unprotect;
        };
        private _startPos = _heli getVariable ["OT_escortStartPos", [0, 0, 0]];
        private _alt = _startPos select 2;
        private _fromNearest = selectMin (_airfields apply { (_x select 0) distance2D _startPos });
        ["Two airfields: it starts flying over an airfield", (_heli getVariable ["OT_escortStart", ""]) isEqualTo "air" && { _alt > 50 } && { _fromNearest < 700 },
            format ["%1 m up, %2 m from the airfield", round _alt, round _fromNearest]] call OTQA_fnc_check;

        // Shot down: the Blackfish still comes and drops the tank, which drives off for the base
        _heli setDamage 1;
        private _plane = [OTQA_esc_planes, [_baseName], _before, 600] call OTQA_esc_waitFor;
        ["Shot down escort: the Blackfish still sets off", !isNull _plane, ""] call OTQA_fnc_check;
        if (isNull _plane) exitWith { [_script, _baseName, _type, _before] call OTQA_esc_cleanup; call OTQA_esc_unprotect };
        private _timeout = time + 900;
        waitUntil { sleep 2; !alive _plane || { !isNull (_plane getVariable ["OT_deliveryCargo", objNull]) } || { time > _timeout } };
        private _tank = _plane getVariable ["OT_deliveryCargo", objNull];
        _timeout = time + 200;
        waitUntil { sleep 1; !alive _tank || { ((getPosATL _tank) select 2) < 3 && { alive driver _tank } } || { time > _timeout } };
        private _landing = getPosATL _tank;
        _timeout = time + 120;
        waitUntil { sleep 2; !alive _tank || { (_tank distance2D _landing) > 100 } || { time > _timeout } };
        ["Shot down escort: the tank is dropped and drives for the base", alive _tank && { (_tank distance2D _landing) > 100 } && { (_tank distance2D _basePos) < (_landing distance2D _basePos) },
            format ["%1 m from the landing, %2 m from the base", round (_tank distance2D _landing), round (_tank distance2D _basePos)]] call OTQA_fnc_check;

        // The wreck goes too
        { deleteVehicle _x } forEach (crew _heli);
        deleteVehicle _heli;
        [_script, _baseName, _type, _before] call OTQA_esc_cleanup;
        call OTQA_esc_unprotect;
    }, 1200],

    ["Escort 5: no escort for a FOB vehicle drop or a convoy", {
        call OTQA_esc_protect;
        private _base = call OTQA_esc_base;
        if (_base isEqualTo []) exitWith { call OTQA_esc_unprotect; "Escort 5 skipped: no occupier base" call OTQA_fnc_manual };
        OT_testAirfields = [_base select 0, 2] call OTQA_esc_airfields;

        // A FOB vehicle's airdrop (OT_fnc_NATOairdropVehicle on its own, as OT_fnc_NATOdeliverFOBVehicle does)
        private _cars = OT_NATO_Vehicles_GroundSupport select { _x isKindOf "Car" };
        private _cls = selectRandom ([_cars, OT_NATO_Vehicles_GroundSupport] select (_cars isEqualTo []));
        private _drop = (player getPos [1500, random 360]) findEmptyPosition [0, 300, _cls];
        if (_drop isEqualTo []) then { _drop = player getPos [1500, random 360] };
        private _helisBefore = vehicles select { (_x getVariable ["OT_escortFor", ""]) isNotEqualTo "" };
        private _planesBefore = vehicles select { typeOf _x isEqualTo "B_T_VTOL_01_armed_F" };
        private _fobScript = [_cls, _drop] spawn OT_fnc_NATOairdropVehicle;
        private _plane = [{ vehicles select { typeOf _x isEqualTo "B_T_VTOL_01_armed_F" } }, [], _planesBefore, 20] call OTQA_esc_waitFor;
        sleep 15;
        private _helis = (vehicles select { (_x getVariable ["OT_escortFor", ""]) isNotEqualTo "" }) - _helisBefore;
        ["FOB vehicle drop: a Blackfish, no escort helicopter", !isNull _plane && { _helis isEqualTo [] }, format ["Blackfish %1, helicopters %2", !isNull _plane, _helis apply { typeOf _x }]] call OTQA_fnc_check;
        terminate _fobScript;
        [_plane] call OTQA_esc_delete;
        OT_testAirfields = nil;

        // A convoy
        private _convoyBase = call OTQA_esc_convoyBase;
        if (_convoyBase isEqualTo []) exitWith { call OTQA_esc_unprotect; "Escort 5 (convoy) skipped: no base a convoy can reach" call OTQA_fnc_manual };
        private _run = ["convoy", [_convoyBase select 0, 2] call OTQA_esc_airfields, _convoyBase] call OTQA_esc_start;
        if (_run isEqualTo []) exitWith { OT_testAirfields = nil; call OTQA_esc_unprotect; "Escort 5 (convoy) skipped: no tanks" call OTQA_fnc_manual };
        _run params ["_script", "_basePos", "_baseName", "_type", "_before"];
        private _tank = [OTQA_esc_tanks, [_baseName, _type], _before, 20] call OTQA_esc_waitFor;
        sleep 15;
        private _convoyHelis = ([_baseName] call OTQA_esc_helis) - _before;
        private _escorts = vehicles select { (_x getVariable ["OT_escort", ""]) isEqualTo _baseName };
        ["Convoy: ground escorts, no escort helicopter", !isNull _tank && { _escorts isNotEqualTo [] } && { _convoyHelis isEqualTo [] },
            format ["tank %1, %2 ground escorts, helicopters %3", !isNull _tank, count _escorts, _convoyHelis apply { typeOf _x }]] call OTQA_fnc_check;
        [_script, _baseName, _type, _before] call OTQA_esc_cleanup;
        call OTQA_esc_unprotect;
    }, 180],

    ["Escort 6: the helicopter class; none in the template, no escort", {
        private _saved = +OT_NATO_Vehicles_AirSupport;
        private _cls = call OT_fnc_NATOattackHelicopter;
        ["Class: the occupier's attack helicopter", (_saved isEqualTo [] && { _cls isEqualTo "" }) || { _cls in _saved && { _cls isKindOf "Helicopter" } }
            || { (_saved findIf { isClass (configFile >> "CfgVehicles" >> _x) }) isEqualTo -1 && { _cls isKindOf "Helicopter" } },
            format ["%1 from %2", _cls, _saved]] call OTQA_fnc_check;
        OT_NATO_Vehicles_AirSupport = ["OTQA_NotAHelicopter"];
        private _fallback = call OT_fnc_NATOattackHelicopter;
        ["Class: not in the game, a vanilla one for the occupier's side", isClass (configFile >> "CfgVehicles" >> _fallback) && { _fallback isKindOf "Helicopter" },
            format ["%1 (side %2)", _fallback, missionNamespace getVariable ["OT_NATO_factionSide", -1]]] call OTQA_fnc_check;
        OT_NATO_Vehicles_AirSupport = [];
        ["Class: none in the template, none", (call OT_fnc_NATOattackHelicopter) isEqualTo "", ""] call OTQA_fnc_check;

        call OTQA_esc_protect;
        private _base = call OTQA_esc_base;
        private _run = [];
        if (_base isNotEqualTo []) then { _run = ["airdrop", [_base select 0, 1] call OTQA_esc_airfields, _base] call OTQA_esc_start };
        OT_NATO_Vehicles_AirSupport = _saved; // The delivery has decided; other occupier air support needs it
        if (_run isEqualTo []) exitWith {
            OT_testAirfields = nil;
            call OTQA_esc_unprotect;
            "Escort 6 (delivery) skipped: no occupier base or no tanks" call OTQA_fnc_manual;
        };
        _run params ["_script", "_basePos", "_baseName", "_type", "_before"];
        // No head start to wait for: the Blackfish sets off at once
        private _plane = [OTQA_esc_planes, [_baseName], _before, 30] call OTQA_esc_waitFor;
        sleep 10;
        private _helis = ([_baseName] call OTQA_esc_helis) - _before;
        ["No attack helicopter: the Blackfish sets off at once, no escort", !isNull _plane && { _helis isEqualTo [] }, format ["Blackfish %1, helicopters %2", !isNull _plane, _helis apply { typeOf _x }]] call OTQA_fnc_check;
        [_script, _baseName, _type, _before] call OTQA_esc_cleanup;
        call OTQA_esc_unprotect;
    }, 120]
]
