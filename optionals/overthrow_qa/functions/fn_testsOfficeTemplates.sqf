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

    // The items: their shape, roles and classes
    private _bad = [];
    private _all = []; // [tier, index, item]
    {
        private _tier = _forEachIndex + 1;
        {
            if ((count _x) isNotEqualTo 5 || { !((_x select 0) in ["guard", "object"]) } || { !((_x select 2) isEqualType []) } || { (count (_x select 2)) isNotEqualTo 3 } || { !((_x select 3) isEqualType 0) } || { !((_x select 4) isEqualType []) }) then {
                _bad pushBack [_tier, _forEachIndex, _x];
            } else {
                if ((_x select 0) isEqualTo "guard" && { !((_x select 1) in OTQA_officeTest_roles) }) then { _bad pushBack [_tier, _forEachIndex, _x] };
                if ((_x select 0) isEqualTo "object" && { !(isClass (configFile >> "CfgVehicles" >> (_x select 1))) }) then { _bad pushBack [_tier, _forEachIndex, _x] };
            };
            _all pushBack [_tier, _forEachIndex, _x];
        } forEach _x;
    } forEach _tiers;
    [format ["Office templates: %1 items are [kind, class or role, pos, dir, extra] with known roles and classes", _key], _bad isEqualTo [], str _bad] call OTQA_fnc_check;

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
        _kind isEqualTo "guard" && { !("outside" in _extra) } && { (_positions findIf { abs ((_x select 2) - (_pos select 2)) < 1 && { (_x distance2D _pos) < 0.8 } }) isEqualTo -1 }
    };
    [format ["Office templates: %1 guards inside at building positions (%2 positions)", _key, count _positions], _guardsOff isEqualTo [], str (_guardsOff apply { [_x select 0, _x select 1, (_x select 2) select 1, (_x select 2) select 2] })] call OTQA_fnc_check;

    ([_b, 5, west, _parts] call OT_fnc_officeApplyTemplate) params ["_objects", "_guards"];
    sleep 1;
    private _wantObjects = { ((_x select 2) select 0) isEqualTo "object" } count _all;
    private _wantGuards = { ((_x select 2) select 0) isEqualTo "guard" } count _all;
    [format ["Office templates: %1 tier 5 applied makes every item", _key], (count _objects) isEqualTo _wantObjects && { (count _guards) isEqualTo _wantGuards } && { (_objects findIf { isNull _x }) isEqualTo -1 } && { (_guards findIf { isNull _x || { !alive _x } }) isEqualTo -1 },
        format ["%1 of %2 objects, %3 of %4 guards", count _objects, _wantObjects, count _guards, _wantGuards]] call OTQA_fnc_check;

    // Everything where the template says, turned with the building; the things outside on the ground
    private _misplaced = [];
    private _floating = [];
    private _inWall = [];
    {
        private _o = _x;
        (_o getVariable ["OT_officeItem", ["", 0, -1, ["", "", [0, 0, 0], 0, []]]]) params ["", "_tier", "_index", "_item"];
        _item params ["_kind", "_what", "_pos", "", "_extra"];
        private _model = _b worldToModel (getPosATL _o);
        private _outside = "outside" in _extra;
        private _off = if (_outside) then { _model distance2D _pos } else { _model distance _pos };
        if (_off > 0.35) then { _misplaced pushBack [_tier, _index, _what, _pos, _model apply { round (_x * 100) / 100 }] };
        if (_outside) then {
            if (abs ((getPosATL _o) select 2) > 0.5) then { _floating pushBack [_tier, _index, _what, (getPosATL _o) select 2] };
        } else {
            // A floor of the building just under it, and nothing of the building through it
            private _asl = getPosASL _o;
            private _below = lineIntersectsSurfaces [_asl vectorAdd [0, 0, 0.3], _asl vectorAdd [0, 0, -0.8], _o, objNull, true, 1, "GEOM", "NONE"];
            if ((_below findIf { (_x select 2) in _pieces }) isEqualTo -1) then { _floating pushBack [_tier, _index, _what, _pos] };
            if (_kind isEqualTo "object") then {
                private _through = lineIntersectsSurfaces [_asl vectorAdd [0, 0, 0.4], _asl vectorAdd [0, 0, 1.5], _o, objNull, true, 1, "GEOM", "NONE"];
                if ((_through findIf { (_x select 2) in _pieces }) > -1) then { _inWall pushBack [_tier, _index, _what, _pos] };
            };
        };
    } forEach (_objects + _guards);
    [format ["Office templates: %1 everything placed where the template says, turned with the building", _key], _misplaced isEqualTo [], str _misplaced] call OTQA_fnc_check;
    [format ["Office templates: %1 everything on a floor or on the ground (not floating or sunk)", _key], _floating isEqualTo [], str _floating] call OTQA_fnc_check;
    [format ["Office templates: %1 no object inside a wall or under a floor", _key], _inWall isEqualTo [], str _inWall] call OTQA_fnc_check;

    // Away again
    private _group = if (_guards isEqualTo []) then { grpNull } else { group (_guards select 0) };
    { deleteVehicle _x } forEach (_objects + _guards);
    { deleteVehicle _x } forEach _pieces;
    sleep 1; // Deleted things are null only at the end of the frame, and the group goes once it's empty
    if (!isNull _group) then { deleteGroup _group; sleep 0.5 };
    [format ["Office templates: %1 deletes cleanly", _key], ((_objects + _guards + _pieces) findIf { !isNull _x }) isEqualTo -1 && { isNull _group }, ""] call OTQA_fnc_check;
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
_tests pushBack ["Office templates: the host back from the airfield", {
    { _x hideObjectGlobal false } forEach (OTQA_officeTest getOrDefault ["hidden", []]);
    private _home = OTQA_officeTest getOrDefault ["home", []];
    if (_home isNotEqualTo []) then { player setPosASL _home };
    player allowDamage true;
    player setCaptive true;
    ["Office templates: the host is back where they were", _home isEqualTo [] || { (getPosASL player) distance _home < 5 }, str _home] call OTQA_fnc_check;
}];
_tests
