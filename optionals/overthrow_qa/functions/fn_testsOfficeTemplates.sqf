/*
    Description:
    Mayor's office defence templates (Altis): the class to key mapping (variants fold onto one
    template, OT_fnc_officeTemplateKey), and for every key with a template, its five tiers: the item
    format and classes, cumulative guard counts within the tier ranges (2-4, 4-6, 6-8, 8-10, 10-12)
    and no fortification at tier 1, then on a copy of the building spawned on the main airfield
    (facing 137, so the placing is checked turned): OT_fnc_officeApplyTemplate at tier 5 makes every
    item where the template says (modelToWorld), no object within 1.2 m of a door, everything within
    the perimeter, objects on a floor (not floating or sunk) and guards at building positions, and
    it all deletes cleanly. A key without a template yet is noted as a manual check and skipped. The
    host is moved to the airfield for it and back after. Part of the current QA tests.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

OTQA_officeTest = createHashMap; // The site on the airfield and the host's place

// Every Altis office class and the key it should map to
OTQA_officeTest_classes = [
    ["Land_i_Stone_HouseBig_V1_F", "i_Stone_HouseBig_V1_F"], ["Land_i_Stone_HouseBig_V2_F", "i_Stone_HouseBig_V1_F"], ["Land_i_Stone_HouseBig_V3_F", "i_Stone_HouseBig_V1_F"],
    ["Land_i_House_Big_02_V1_F", "i_House_Big_02_V1_F"], ["Land_i_House_Big_02_V2_F", "i_House_Big_02_V1_F"], ["Land_i_House_Big_02_V3_F", "i_House_Big_02_V1_F"],
    ["Land_u_House_Big_02_V1_F", "i_House_Big_02_V1_F"], ["Land_i_House_Big_02_b_blue_F", "i_House_Big_02_V1_F"], ["Land_i_House_Big_02_b_whiteblue_F", "i_House_Big_02_V1_F"],
    ["Land_i_House_Big_01_V1_F", "i_House_Big_01_V1_F"], ["Land_i_House_Big_01_V2_F", "i_House_Big_01_V1_F"], ["Land_i_House_Big_01_V3_F", "i_House_Big_01_V1_F"],
    ["Land_u_House_Big_01_V1_F", "i_House_Big_01_V1_F"], ["Land_i_House_Big_01_b_pink_F", "i_House_Big_01_V1_F"],
    ["Land_i_Shop_01_V1_F", "i_Shop_01_V1_F"], ["Land_i_Shop_01_V2_F", "i_Shop_01_V1_F"], ["Land_i_Shop_01_V3_F", "i_Shop_01_V1_F"], ["Land_u_Shop_01_V1_F", "i_Shop_01_V1_F"],
    ["Land_i_Shop_02_V1_F", "i_Shop_02_V1_F"], ["Land_i_Shop_02_V2_F", "i_Shop_02_V1_F"], ["Land_i_Shop_02_V3_F", "i_Shop_02_V1_F"], ["Land_u_Shop_02_V1_F", "i_Shop_02_V1_F"],
    ["Land_i_Shop_02_b_yellow_F", "i_Shop_02_V1_F"],
    ["Land_Research_HQ_F", "Research_HQ_F"], ["Land_Offices_01_V1_F", "Offices_01_V1_F"], ["Land_Hospital_main_F", "Hospital_main_F"]
];
OTQA_officeTest_keys = (OTQA_officeTest_classes apply { _x select 1 }) arrayIntersect (OTQA_officeTest_classes apply { _x select 1 });
OTQA_officeTest_roles = ["gendarme", "rifleman", "autorifleman", "marksman", "at", "mg_gunner", "officer"];
OTQA_officeTest_fortifications = ["Land_BagFence", "Land_HBarrier", "Land_Razorwire", "Land_CncBarrier", "Land_CzechHedgehog", "Land_BagBunker", "Land_Mil_Wall", "Land_SandbagBarricade"];

// The checks on one key's template
OTQA_officeTest_one = {
    params ["_key"];
    private _tiers = [_key] call OT_fnc_officeTemplate;
    if (_tiers isEqualTo []) exitWith {
        format ["Office templates: %1 has no template yet, not checked", _key] call OTQA_fnc_manual;
    };

    // The items: their shape, roles and classes; the doorway markers (the real entrances, for the checks) apart
    private _bad = [];
    private _all = []; // [tier, index, item], the guards and objects
    private _doorways = []; // [role, [x, y, z], outward dir, width]
    {
        private _tier = _forEachIndex + 1;
        {
            if ((count _x) isNotEqualTo 5 || { !((_x select 0) in ["guard", "object", "doorway"]) } || { !((_x select 2) isEqualType []) } || { (count (_x select 2)) isNotEqualTo 3 } || { !((_x select 3) isEqualType 0) } || { !((_x select 4) isEqualType []) }) then {
                _bad pushBack [_tier, _forEachIndex, _x];
            } else {
                if ((_x select 0) isEqualTo "guard" && { !((_x select 1) in OTQA_officeTest_roles) }) then { _bad pushBack [_tier, _forEachIndex, _x] };
                if ((_x select 0) isEqualTo "object" && { !(isClass (configFile >> "CfgVehicles" >> (_x select 1))) }) then { _bad pushBack [_tier, _forEachIndex, _x] };
                if ((_x select 0) isEqualTo "doorway") then {
                    if ((_x select 1) in ["main", "back", "side"] && { (count (_x select 4)) isEqualTo 2 }) then {
                        _doorways pushBack [_x select 1, _x select 2, _x select 3, (_x select 4) select 0];
                    } else {
                        _bad pushBack [_tier, _forEachIndex, _x];
                    };
                };
            };
            if ((_x select 0) in ["guard", "object"]) then { _all pushBack [_tier, _forEachIndex, _x] };
        } forEach _x;
    } forEach _tiers;
    [format ["Office templates: %1 items are [kind, class or role, pos, dir, extra] with known roles and classes", _key], _bad isEqualTo [], str _bad] call OTQA_fnc_check;
    private _mainDoor = _doorways select { (_x select 0) isEqualTo "main" };
    ["Office templates: %1 marks its real entrances, one of them the main one", (count _mainDoor) isEqualTo 1 && { (_doorways findIf { (_x select 3) < 0.6 || { (_x select 3) > 4.5 } }) isEqualTo -1 }, str _doorways] call OTQA_fnc_check;
    // How far a point is off a doorway's axis (sideways, facing out of it)
    private _offAxis = {
        params ["_p", "_dw"];
        _dw params ["", "_c", "_d"];
        abs (((_p select 0) - (_c select 0)) * cos _d - ((_p select 1) - (_c select 1)) * sin _d)
    };
    // Rule 1: the door kits (the nest's front, the pairs, the posts' bags, the stoppers, the gate) square with an entrance
    private _askew = [];
    {
        _x params ["_tier", "_index", "_item"];
        _item params ["_kind", "_what", "_pos", "", "_extra"];
        if (_kind isEqualTo "object" && { "axis" in _extra }) then {
            private _best = 9;
            { _best = _best min ([_pos, _x] call _offAxis) } forEach _doorways;
            if (_best > 0.5) then { _askew pushBack [_tier, _index, _what, _pos, round (_best * 100) / 100] };
        };
    } forEach _all;
    [format ["Office templates: %1 door defences square with an entrance (within 0.5 m of its axis)", _key], _askew isEqualTo [] && { ({ "axis" in ((_x select 2) select 4) } count _all) > 0 }, str _askew] call OTQA_fnc_check;

    // Guards per tier (cumulative), no fortification at tier 1
    private _counts = [];
    private _n = 0;
    { _n = _n + ({ (_x select 0) isEqualTo "guard" } count _x); _counts pushBack _n } forEach _tiers;
    private _ranges = [[2, 4], [4, 6], [6, 8], [8, 10], [10, 12]];
    private _inRange = true;
    { if ((_counts select _forEachIndex) < (_x select 0) || { (_counts select _forEachIndex) > (_x select 1) }) then { _inRange = false } } forEach _ranges;
    [format ["Office templates: %1 guards per tier within 2-4/4-6/6-8/8-10/10-12", _key], _inRange, str _counts] call OTQA_fnc_check;
    private _t1Forts = (_tiers select 0) select { (_x select 0) isEqualTo "object" && { private _c = _x select 1; (OTQA_officeTest_fortifications findIf { (_c find _x) isEqualTo 0 }) > -1 } };
    [format ["Office templates: %1 tier 1 has no fortifications", _key], _t1Forts isEqualTo [], str (_t1Forts apply { _x select 1 })] call OTQA_fnc_check;

    // A copy on the airfield, turned, with tier 5 on it
    private _site = OTQA_officeTest getOrDefault ["site", []];
    if (_site isEqualTo []) exitWith {
        format ["Office templates: %1 not placed, no site on the airfield", _key] call OTQA_fnc_manual;
    };
    ([_key, _site, 137] call OTQA_fnc_officeSpawn) params ["_b", "_parts"];
    if (isNull _b) exitWith { [format ["Office templates: %1 spawns on the airfield", _key], false, "Land_" + _key] call OTQA_fnc_check };
    private _pieces = [_b] + _parts;
    sleep 1;
    private _doors = [];
    private _positions = [];
    {
        private _o = _x;
        for "_i" from 1 to (getNumber ((configOf _o) >> "numberOfDoors")) do {
            private _p = _o selectionPosition [format ["Door_%1_trigger", _i], "Memory"];
            if (_p isNotEqualTo [0, 0, 0]) then { _doors pushBack (_b worldToModel (_o modelToWorld _p)) };
        };
        _positions append ((_o buildingPos -1) apply { _b worldToModel _x });
    } forEach _pieces;
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

    private _nearDoor = _all select {
        _x params ["", "", "_item"];
        _item params ["_kind", "", "_pos"];
        _kind isEqualTo "object" && { (_doors findIf { abs ((_x select 2) - 1 - (_pos select 2)) < 2.5 && { (_x distance2D _pos) < 1.2 } }) > -1 }
    };
    [format ["Office templates: %1 no object within 1.2 m of a door (%2 doors)", _key, count _doors], _nearDoor isEqualTo [], str (_nearDoor apply { [_x select 0, _x select 1, (_x select 2) select 1, (_x select 2) select 2] })] call OTQA_fnc_check;
    private _margin = 18; // The tier 5 perimeter: up to about 16 m outside the bounding box where a door's approach needs the room
    private _outsideRing = _all select {
        private _p = (_x select 2) select 2;
        (_p select 0) < (_min select 0) - _margin || { (_p select 0) > (_max select 0) + _margin } || { (_p select 1) < (_min select 1) - _margin } || { (_p select 1) > (_max select 1) + _margin }
    };
    [format ["Office templates: %1 everything within the perimeter (bounding box + %2 m)", _key, _margin], _outsideRing isEqualTo [], str (_outsideRing apply { [_x select 0, _x select 1, (_x select 2) select 1, (_x select 2) select 2] })] call OTQA_fnc_check;
    private _guardsOff = _all select {
        _x params ["", "", "_item"];
        _item params ["_kind", "", "_pos", "", "_extra"];
        _kind isEqualTo "guard" && { !("outside" in _extra) } && { !("free" in _extra) } && { (_positions findIf { abs ((_x select 2) - (_pos select 2)) < 1 && { (_x distance2D _pos) < 0.8 } }) isEqualTo -1 }
    };
    [format ["Office templates: %1 guards inside at building positions (%2 positions; balcony and window spots apart)", _key, count _positions], _guardsOff isEqualTo [], str (_guardsOff apply { [_x select 0, _x select 1, (_x select 2) select 1, (_x select 2) select 2] })] call OTQA_fnc_check;

    ([_b, 5, west, _parts] call OT_fnc_officeApplyTemplate) params ["_objects", "_guards"];
    sleep 1;
    private _wantObjects = { ((_x select 2) select 0) isEqualTo "object" } count _all;
    private _wantGuards = { ((_x select 2) select 0) isEqualTo "guard" } count _all;
    private _itemOf = { (_this getVariable ["OT_officeItem", ["", 0, -1, ["", "", [0, 0, 0], 0, []]]]) params ["", "_t", "_i", "_it"]; [_t, _i, _it select 1, _it select 2] };
    private _gone = (_objects select { isNull _x }) + (_guards select { isNull _x || { !alive _x } });
    [format ["Office templates: %1 tier 5 applied makes every item", _key], (count _objects) isEqualTo _wantObjects && { (count _guards) isEqualTo _wantGuards } && { _gone isEqualTo [] },
        format ["%1 of %2 objects, %3 of %4 guards, null or dead: %5", count _objects, _wantObjects, count _guards, _wantGuards, _gone apply { if (isNull _x) then { "null" } else { _x call _itemOf } }]] call OTQA_fnc_check;

    // Everything where the template says, turned with the building (a guard settles up to 0.75 m, a prop is
    // let down onto its floor); the things outside on the ground; props on a floor, the ground or a table,
    // with nothing of the building through them
    private _misplaced = [];
    private _floating = [];
    private _inWall = [];
    private _placed = _objects + _guards;
    // What a ray hit, for the detail: [what, how far above the thing's origin, where in the building's coordinates]
    private _hitList = {
        params ["_asl", "_hits"];
        _hits apply { [if (isNull (_x select 2)) then { "terrain" } else { typeOf (_x select 2) }, round ((((_x select 0) select 2) - (_asl select 2)) * 100) / 100, (_b worldToModel (ASLToATL (_x select 0))) apply { round (_x * 100) / 100 }] }
    };
    {
        private _o = _x;
        (_o getVariable ["OT_officeItem", ["", 0, -1, ["", "", [0, 0, 0], 0, []]]]) params ["", "_tier", "_index", "_item"];
        _item params ["_kind", "_what", "_pos", "", "_extra"];
        // getPosATL is the thing's origin, its foot (modelToWorld [0, 0, 0] would be its bounding centre, up a pole)
        private _model = _b worldToModel (getPosATL _o);
        private _outside = "outside" in _extra;
        private _ok = if (_kind isEqualTo "guard") then {
            if (_outside) then { (_model distance2D _pos) <= 0.75 } else { (_model distance _pos) <= 0.75 }
        } else {
            // A prop settles onto its floor: down to 1.3 m (the template's heights are the building positions'), or up to
            // 0.6 m where the ground floor's terrain rises away from the building's origin
            (_model distance2D _pos) <= 0.35 && { _outside || { ((_model select 2) - (_pos select 2)) < 0.6 && { ((_model select 2) - (_pos select 2)) > -1.3 } } }
        };
        if (!_ok) then { _misplaced pushBack [_tier, _index, _what, _pos, _model apply { round (_x * 100) / 100 }] };
        if (_outside) then {
            if (abs ((getPosATL _o) select 2) > 0.5) then { _floating pushBack [_tier, _index, _what, (getPosATL _o) select 2] };
        } else {
            private _asl = getPosASL _o;
            private _below = lineIntersectsSurfaces [_asl vectorAdd [0, 0, 0.3], _asl vectorAdd [0, 0, -0.8], _o, objNull, true, 3, "GEOM", "NONE"];
            if ((_below findIf { isNull (_x select 2) || { (_x select 2) in _pieces } || { (_x select 2) in _placed } }) isEqualTo -1) then {
                _floating pushBack [_tier, _index, _what, _pos, [_asl, _below] call _hitList];
            };
            if (_kind isEqualTo "object") then {
                private _through = lineIntersectsSurfaces [_asl vectorAdd [0, 0, 0.4], _asl vectorAdd [0, 0, 1.5], _o, objNull, true, 3, "GEOM", "NONE"];
                private _wall = _through select { (_x select 2) in _pieces };
                if (_wall isNotEqualTo []) then {
                    _inWall pushBack [_tier, _index, _what, _pos, [_asl, _wall] call _hitList];
                };
            };
        };
    } forEach _placed;
    [format ["Office templates: %1 everything placed where the template says, turned with the building", _key], _misplaced isEqualTo [], str _misplaced] call OTQA_fnc_check;
    [format ["Office templates: %1 everything on a floor, the ground or a table (not floating or sunk)", _key], _floating isEqualTo [], str _floating] call OTQA_fnc_check;
    [format ["Office templates: %1 no object inside a wall or under a floor", _key], _inWall isEqualTo [], str _inWall] call OTQA_fnc_check;

    // Rule 4: a guard at least 0.8 m behind (or in front of) any fortification he stands at, in the piece's own
    // coordinates: within its width, his distance from its face
    private _tooClose = [];
    private _forts = _objects select { private _c = toLower typeOf _x; (OTQA_officeTest_fortifications findIf { (_c find toLower _x) isEqualTo 0 }) > -1 };
    {
        private _g = _x;
        private _gItem = _g call _itemOf;
        {
            private _f = _x;
            if ((_f distance _g) < 4 && { abs (((getPosATL _f) select 2) - ((getPosATL _g) select 2)) < 1.5 }) then { // a storey apart is no cover
                (boundingBoxReal _f) params ["_bmin", "_bmax"];
                private _halfX = ((_bmax select 0) - (_bmin select 0)) / 2;
                private _halfY = ((_bmax select 1) - (_bmin select 1)) / 2;
                private _local = _f worldToModel (getPosATL _g);
                if (abs (_local select 0) <= _halfX + 0.2 && { (abs (_local select 1)) - _halfY < 0.75 }) then {
                    _tooClose pushBack [_gItem, _f call _itemOf, round (((abs (_local select 1)) - _halfY) * 100) / 100];
                };
            };
        } forEach _forts;
    } forEach _guards;
    [format ["Office templates: %1 every guard stands at least 0.8 m from the face of his cover", _key], _tooClose isEqualTo [], str _tooClose] call OTQA_fnc_check;

    // Rule 5: the perimeter's gate on the main entrance's axis, with a gate in a clear gap
    private _gates = _objects select { "gate" in ((_x getVariable ["OT_officeItem", ["", 0, -1, ["", "", [0, 0, 0], 0, []]]]) select 3 select 4) };
    private _gateOk = false;
    private _gateDetail = "no gate";
    if ((count _gates) isEqualTo 1 && { _mainDoor isNotEqualTo [] }) then {
        private _gate = _gates select 0;
        private _gatePos = _b worldToModel (getPosATL _gate);
        private _off = [_gatePos, _mainDoor select 0] call _offAxis;
        private _ring = _objects select { (toLower typeOf _x) find "land_hbarrier" isEqualTo 0 && { (_x distance _gate) < 2.8 } };
        _gateOk = _off <= 0.5 && { _ring isEqualTo [] } && { (toLower typeOf _gate) isEqualTo "land_bargate_f" };
        _gateDetail = format ["%1 at %2, %3 m off the main axis, %4 fence pieces within 2.8 m", typeOf _gate, _gatePos apply { round (_x * 10) / 10 }, round (_off * 100) / 100, count _ring];
    };
    [format ["Office templates: %1 the perimeter's gate is a bar gate on the main entrance's axis in a clear gap", _key], _gateOk, _gateDetail] call OTQA_fnc_check;

    // Away again: the template's things (OT_fnc_officeClearTemplate: the guards first, the rest a moment later,
    // and a hidden retry for anything that stays), then the building. A few House objects (the Offices_01
    // block and its gate bunkers) ignore deleteVehicle until they're hidden; what's left after the first pass
    // is logged with its state and hidden before the second
    private _group = if (_guards isEqualTo []) then { grpNull } else { group (_guards select 0) };
    [_b] call OT_fnc_officeClearTemplate;
    sleep 1;
    { deleteVehicle _x } forEach _pieces;
    sleep 1;
    private _firstPass = (_objects + _guards + _pieces) select { !isNull _x };
    if (_firstPass isNotEqualTo []) then {
        diag_log format ["OT_QA office templates: %1 left after the first delete pass: %2", _key, _firstPass apply { [typeOf _x, (_x getVariable ["OT_officeItem", []]) param [1, "building"], getPosATL _x, local _x, simulationEnabled _x, isObjectHidden _x, alive _x, damage _x, attachedTo _x, count attachedObjects _x, _x distance player, isTouchingGround _x, dynamicSimulationEnabled _x, getModelInfo _x] }];
        { _x hideObjectGlobal true; deleteVehicle _x } forEach _firstPass;
        sleep 3;
    };
    private _left = (_objects + _guards + _pieces) select { !isNull _x };
    [format ["Office templates: %1 deletes cleanly", _key], _left isEqualTo [] && { isNull _group }, format ["left: %1 (a second pass, hidden first, was needed for %2), group %3 (%4 units)", _left apply { typeOf _x }, _firstPass apply { typeOf _x }, _group, if (isNull _group) then { 0 } else { count units _group }]] call OTQA_fnc_check;
};

private _tests = [
    ["Office templates: every Altis office class maps to its template key", {
        private _wrong = OTQA_officeTest_classes select { ([_x select 0] call OT_fnc_officeTemplateKey) isNotEqualTo (_x select 1) };
        ["Office templates: the Altis office classes and their variants map to their keys", _wrong isEqualTo [], str (_wrong apply { [_x select 0, [_x select 0] call OT_fnc_officeTemplateKey] })] call OTQA_fnc_check;
        ["Office templates: a class that isn't an office maps to no key", (["Land_i_Shed_Ind_F"] call OT_fnc_officeTemplateKey) isEqualTo "" && { (["Land_Cargo_House_V3_F"] call OT_fnc_officeTemplateKey) isEqualTo "" }, ""] call OTQA_fnc_check;
        ["Office templates: a key with no template gives []", (["Nothing_F"] call OT_fnc_officeTemplate) isEqualTo [] && { ([""] call OT_fnc_officeTemplate) isEqualTo [] }, ""] call OTQA_fnc_check;
        private _parts = ["Hospital_main_F"] call OT_fnc_officeParts;
        ["Office templates: the hospital's two wings are its parts, a house has none", (count _parts) isEqualTo 2 && { (_parts apply { _x select 0 }) isEqualTo ["Land_Hospital_side1_F", "Land_Hospital_side2_F"] } && { (["i_House_Big_01_V1_F"] call OT_fnc_officeParts) isEqualTo [] }, str _parts] call OTQA_fnc_check;
        private _classes = OTQA_officeTest_roles apply { [_x] call OT_fnc_officeGuardClass };
        ["Office templates: every guard role has an occupier unit class", (_classes findIf { !(isClass (configFile >> "CfgVehicles" >> _x)) }) isEqualTo -1 && { (_classes select 0) isEqualTo OT_NATO_Unit_Police }, str _classes] call OTQA_fnc_check;
    }],
    ["Office templates: a site on the main airfield", {
        // Open flat ground 400-1500 m from the main airfield's centre with no occupier men within 300 m, the host there
        private _airport = OT_airportData apply { [(_x select 0) distance2D [14600, 16700, 0], _x select 0] };
        _airport sort true;
        private _centre = (_airport param [0, [0, [14600, 16700, 0]]]) select 1;
        private _spot = [];
        for "_r" from 400 to 1500 step 100 do {
            for "_d" from 0 to 345 step 15 do {
                private _p = _centre getPos [_r, _d];
                if (surfaceIsWater _p) then { continue };
                if ((_p isFlatEmpty [-1, -1, 0.2, 40, 0, false, objNull]) isEqualTo []) then { continue };
                if (((_p nearEntities ["CAManBase", 300]) findIf { (side group _x) isEqualTo blufor }) > -1) then { continue };
                _spot = _p;
                break;
            };
            if (_spot isNotEqualTo []) then { break };
        };
        ["Office templates: an open flat spot on the main airfield", _spot isNotEqualTo [], str _centre] call OTQA_fnc_check;
        if (_spot isEqualTo []) exitWith {};
        OTQA_officeTest set ["site", _spot];
        OTQA_officeTest set ["home", getPosASL player];
        if (!isNull objectParent player) then { moveOut player; sleep 1 };
        player allowDamage false;
        player setCaptive true;
        private _stand = (_spot getPos [80, 0]) findEmptyPosition [0, 40, "CAManBase"];
        if (_stand isEqualTo []) then { _stand = _spot getPos [80, 0] };
        player setPosATL [_stand select 0, _stand select 1, 0];
        { _x hideObjectGlobal true } forEach (nearestTerrainObjects [_spot, [], 60, false]);
        OTQA_officeTest set ["hidden", nearestTerrainObjects [_spot, [], 60, false]];
        sleep 2;
    }]
];
{
    _tests pushBack [format ["Office templates: %1", _x], compile format ["['%1'] call OTQA_officeTest_one", _x], 90];
} forEach OTQA_officeTest_keys;
_tests pushBack ["Office review: the vote, issue and tier check paths, the actions and the site", {
    // The review's code paths without the reviewer: its functions defined (OTQA_fnc_officeReview returns its test
    // and defines them), one tier 2 copy of the first building with a template on the airfield with the review's
    // actions on everything, then the vote, the issue note and the tier check called as the actions call them
    private _site = OTQA_officeTest getOrDefault ["site", []];
    if (_site isEqualTo []) exitWith { "Office review: the vote and tier check paths not checked, no site on the airfield" call OTQA_fnc_manual };
    call OTQA_fnc_officeReview;
    private _key = (OTQA_officeTest_keys select { ([_x] call OT_fnc_officeTemplate) isNotEqualTo [] }) param [0, ""];
    if (_key isEqualTo "") exitWith { "Office review: the vote and tier check paths not checked, no template yet" call OTQA_fnc_manual };
    OTQA_officeReview set ["keys", [_key]];
    OTQA_officeReview set ["key", _key];
    OTQA_officeReview set ["votes", []];
    OTQA_officeReview set ["done", []];
    OTQA_officeReview set ["width", 40];
    ([_key, _site, 0] call OTQA_fnc_officeSpawn) params ["_b", "_parts"];
    private _pieces = [_b] + _parts;
    ([_b, 2, west, _parts, true] call OT_fnc_officeApplyTemplate) params ["_objects", "_guards"];
    { _x enableSimulationGlobal true; [_x] call OTQA_officeReview_actions } forEach _objects;
    { [_x] call OTQA_officeReview_actions } forEach _guards;
    OTQA_officeReview set ["copies", [[_b, _parts, _objects, _guards, 2, _site, 10]]];
    sleep 0.5;
    private _obj = _objects param [0, objNull];
    private _guard = _guards param [0, objNull];
    ["Office review: a copy with placeholders to vote on", !isNull _obj && { !isNull _guard } && { _guard getVariable ["OT_placeholder", false] } && { alive _guard } && { (weapons _guard) isEqualTo [] }, format ["%1 objects, %2 guards", count _objects, count _guards]] call OTQA_fnc_check;
    if (isNull _obj || { isNull _guard }) exitWith {};

    (_obj getVariable ["OT_officeItem", ["", 0, -1, ["", "", [0, 0, 0]]]]) params ["", "_tier", "_index", "_item"];
    ["Office review: nothing is flagged until an issue is", !([_obj] call OTQA_officeReview_isReported), ""] call OTQA_fnc_check;
    private _line = [["the bags float"], [_obj]] call OTQA_officeReview_issueConfirm;
    private _want = format ["OTFEEDBACK|%1|%2|%3|%4|%5|issue|the bags float", _key, _tier, _index, _item select 1, _item select 2];
    ["Office review: an issue logs the thing's key, tier, index, class, position and note", _line isEqualTo _want && { (OTQA_officeReview get "votes") isEqualTo [[_key, _tier, _index, _item select 1, "issue", "the bags float"]] }, format ["%1 / wanted %2", _line, _want]] call OTQA_fnc_check;
    // The same item in a higher tier's copy (tiers add up): already flagged there too
    private _twin = createVehicle ["Land_CanisterFuel_F", _site getPos [25, 90], [], 0, "CAN_COLLIDE"];
    _twin setVariable ["OT_officeItem", _obj getVariable "OT_officeItem"];
    ["Office review: an issue flagged on one copy covers the same item in the higher tiers' copies", [_obj] call OTQA_officeReview_isReported && { [_twin] call OTQA_officeReview_isReported }, ""] call OTQA_fnc_check;
    deleteVehicle _twin;
    (_guard getVariable ["OT_officeItem", ["", 0, -1, ["", "", [0, 0, 0]]]]) params ["", "_gTier", "_gIndex", "_gItem"];
    _line = [[""], [_guard]] call OTQA_officeReview_issueConfirm;
    _want = format ["OTFEEDBACK|%1|%2|%3|%4|%5|issue|", _key, _gTier, _gIndex, _gItem select 1, _gItem select 2];
    ["Office review: an issue on a guard placeholder logs his role and position", _line isEqualTo _want && { (_gItem select 1) in OTQA_officeTest_roles }, format ["%1 / wanted %2", _line, _want]] call OTQA_fnc_check;
    ["Office review: an issue on something that isn't the template's logs nothing", ([player, "issue"] call OTQA_officeReview_vote) isEqualTo "" && { (count (OTQA_officeReview get "votes")) isEqualTo 2 }, ""] call OTQA_fnc_check;

    // The actions: the issue action on each thing (before and after it's flagged; a unit carries the mod's
    // own as well), named after it, only while the player looks at it
    private _label = format ["%1 (Tier %2, #%3)", _item select 1, _tier, _index];
    private _gLabel = format ["%1 (Tier %2, #%3)", _gItem select 1, _gTier, _gIndex];
    private _params = ((actionIDs _obj) apply { _obj actionParams _x }) select { _label in (_x select 0) };
    private _gParams = ((actionIDs _guard) apply { _guard actionParams _x }) select { _gLabel in (_x select 0) };
    private _mine = _params + _gParams;
    ["Office review: each thing has only its issue action (and its already-reported form), named after it, for the thing under the cursor only", (count _params) isEqualTo 2 && { (count _gParams) isEqualTo 2 } && { (_mine findIf { !("cursorObject isEqualTo _target" in (_x select 7)) }) isEqualTo -1 } && { (_mine findIf { (_x select 8) isNotEqualTo 6 }) isEqualTo -1 } && { (_mine findIf { ("Good" in (_x select 0)) || { "Bad" in (_x select 0) } }) isEqualTo -1 },
        format ["%1 on the thing, %2 on the guard: %3", count _params, count _gParams, _mine apply { [_x select 0, _x select 7, _x select 8] }]] call OTQA_fnc_check;

    // The tier check: at the copy (the host is 80 m off, so by the copy's position) it's offered, once marked it isn't, logged, in the list's data
    private _home = getPosATL player;
    player setPosATL [_site select 0, _site select 1, 0];
    private _offeredBefore = [2] call OTQA_officeReview_atTier;
    _line = [player, player, -1, [2]] call OTQA_officeReview_tierAction;
    private _offeredAfter = [2] call OTQA_officeReview_atTier;
    player setPosATL _home;
    ["Office review: marking a tier reviewed logs it and takes the action away for that tier only", _offeredBefore && { !_offeredAfter } && { _line isEqualTo format ["OTFEEDBACK|TIERDONE|%1|2", _key] } && { [2] call OTQA_officeReview_tierIsDone } && { !([1] call OTQA_officeReview_tierIsDone) } && { (OTQA_officeReview get "done") isEqualTo [[_key, 2]] } && { ([2] call OTQA_officeReview_tierDone) isEqualTo "" },
        format ["offered %1 then %2, %3", _offeredBefore, _offeredAfter, _line]] call OTQA_fnc_check;

    // The review's site: the north-east side of the main airfield, five flat spots along the row
    private _airport = OT_airportData apply { [(_x select 0) distance2D [14600, 16700, 0], _x select 0] };
    _airport sort true;
    private _centre = (_airport param [0, [0, [14600, 16700, 0]]]) select 1;
    private _width = 60;
    private _row = [_width] call OTQA_officeReview_site;
    private _flat = _row isNotEqualTo [];
    if (_flat) then {
        _row params ["_base", "_rowDir"];
        for "_i" from 0 to 4 do {
            private _c = _base getPos [_i * _width, _rowDir];
            if (surfaceIsWater _c || { (_c isFlatEmpty [-1, -1, 0.2, 30, 0, false, objNull]) isEqualTo [] }) exitWith { _flat = false };
        };
    };
    private _bearing = if (_row isEqualTo []) then { -1 } else { _centre getDir (_row select 0) };
    ["Office review: the site is on the main airfield's north-east side and its row of five is flat", _row isNotEqualTo [] && { _bearing >= 0 && { _bearing <= 90 } } && { _flat },
        format ["site %1, row %2, %3 m at %4 degrees from the airport centre %5", _row param [0, []], _row param [1, 0], if (_row isEqualTo []) then { 0 } else { round (_centre distance2D (_row select 0)) }, round _bearing, _centre apply { round _x }]] call OTQA_fnc_check;

    // Away again
    [_b] call OT_fnc_officeClearTemplate;
    sleep 1;
    { deleteVehicle _x } forEach _pieces;
    sleep 1;
    { if (!isNull _x) then { _x hideObjectGlobal true; deleteVehicle _x } } forEach (_objects + _guards + _pieces);
    OTQA_officeReview = createHashMap;
}, 90];
_tests pushBack ["Office templates: the host back from the airfield", {
    { _x hideObjectGlobal false } forEach (OTQA_officeTest getOrDefault ["hidden", []]);
    private _home = OTQA_officeTest getOrDefault ["home", []];
    if (_home isNotEqualTo []) then { player setPosASL _home };
    player allowDamage true;
    player setCaptive true;
    ["Office templates: the host is back where they were", _home isEqualTo [] || { (getPosASL player) distance _home < 5 }, str _home] call OTQA_fnc_check;
}];
_tests
