/*
    Description:
    Gang turf (drugs slice 3b): a gang's turf (1.5 km round its camp, OT_fnc_drugTurfGang), a drug
    operation on it angering the gang when it makes or sells (OT_fnc_drugTurf: anger and rep loss with
    the amount, blow double, half for a friend of the gang, the warning), street sales on it
    (OT_fnc_drugTurfStreet, three times), the raid on the operation when the anger is up
    (OT_fnc_drugTurfAttack / OT_fnc_drugTurfSquad: the warning, 3 of the gang's men with its gear, the
    loot, the cooldown, the squad deleted once nobody is near), the simulated raid out of spawn
    distance, the ambush on a dealer and calling it off, the deal (OT_fnc_drugTurfDeal: the fee, no
    anger, the cut out of dispensary sales, lab batches and street sales, the business info) and its
    end. A test gang with its camp 600 m from the first dispensary is made for it and removed after;
    other gangs whose turf it would be are moved away and back. Run it as the host (a general: the
    dispensary is bought if the resistance doesn't own it, and stays bought). The host can't be hurt
    while the squads are out, and is moved about and back. Part of the current QA tests.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Turf: in play, talk to a gang member or leader: 'Can we talk about your turf? (our drug business there)' shows their turf, our operations on it and their mood or the deal; 'Pay their cut: $2,500 now and 20% of everything we make on their turf' takes the fee and announces the deal; with a deal, 'End the deal'" call OTQA_fnc_manual;
"Turf: in play, the resistance screen's business info of a dispensary or lab on a gang's turf reads 'On <gang>'s turf (camp N m away)' and the deal (green, what's been paid) or 'No deal: they're ... about it' (red)" call OTQA_fnc_manual;
"Turf: in play, sell ganja to civilians near a gang's camp without a deal: after a few, 'X don't like you dealing on their turf', then 'X are coming for you': 3 of their men come and open fire within 100 m; with a deal, each sale shows 'X's cut: -$N'" call OTQA_fnc_manual;
"Turf: in play, a raid: 3 gang members walk up to the operation, open fire within 150 m of you, take up to 10 ganja and 5 blow from its containers and head back to their camp" call OTQA_fnc_manual;

OTQA_turf = createHashMap; // The test's state: the gang, the dispensary, what to put back

// A test gang with its camp at a position, at the end of a town's list (the gang loop keeps minding the town's own)
OTQA_turf_makeGang = {
    params ["_town", "_camp"];
    private _gangid = (OT_civilians getVariable ["autogangid", -1]) + 1;
    OT_civilians setVariable ["autogangid", _gangid];
    private _vest = selectRandom OT_allProtectiveVests;
    private _weapon = selectRandom (OT_CRIM_Weapons + OT_allCheapRifles);
    private _loadout = [format ["gang%1", _gangid], OT_CRIMBaseLoadout, [[_weapon]]] call OT_fnc_getRandomLoadout;
    (_loadout # 4) set [0, _vest];
    OT_civilians setVariable [format ["gang%1", _gangid], [[], -1, _town, _vest, [_camp select 0, _camp select 1, 0], _loadout, 0, 1, "QA Turf Gang"], true];
    private _gangs = OT_civilians getVariable [format ["gangs%1", _town], []];
    _gangs pushBack _gangid;
    OT_civilians setVariable [format ["gangs%1", _town], _gangs, true];
    spawner setVariable [format ["gangspawn%1", _gangid], createGroup [opfor, true], true];
    _gangid
};
OTQA_turf_setCamp = {
    params ["_gangid", "_camp"];
    private _gang = OT_civilians getVariable [format ["gang%1", _gangid], []];
    if ((count _gang) isNotEqualTo 9) exitWith {};
    _gang set [4, [_camp select 0, _camp select 1, 0]];
    OT_civilians setVariable [format ["gang%1", _gangid], _gang, true];
};
// Every other gang within reach of a place is moved off the map (and put back by the cleanup)
OTQA_turf_claim = {
    params ["_pos"];
    private _mine = OTQA_turf getOrDefault ["gang", -1];
    private _moved = OTQA_turf getOrDefault ["others", []];
    {
        {
            private _id = _x;
            private _g = OT_civilians getVariable [format ["gang%1", _id], []];
            if (_id isNotEqualTo _mine && { (count _g) isEqualTo 9 } && { ((_g select 4) distance2D _pos) < (OT_drugTurfRadius + 200) }) then {
                if ((_moved findIf { (_x select 0) isEqualTo _id }) < 0) then { _moved pushBack [_id, +(_g select 4)] };
                [_id, [-20000, -20000, 0]] call OTQA_turf_setCamp;
            };
        } forEach (OT_civilians getVariable [format ["gangs%1", _x], []]);
    } forEach OT_allTowns;
    OTQA_turf set ["others", _moved];
};
// The gang's anger record set by hand: the anger, and when it last attacked (long ago by default)
OTQA_turf_setAnger = {
    params ["_gangid", "_anger", ["_lastAttack", -1000000]];
    private _state = [_gangid] call OT_fnc_drugTurfState;
    _state set [1, _anger];
    _state set [3, _lastAttack];
    _state set [4, _anger >= OT_drugTurfWarnAt]; // Warned only if already past the warning (a fresh start otherwise)
    _state set [5, 0]; // No rep loss carried over from earlier tests
    [_gangid, _state] call OT_fnc_drugTurfState;
};
OTQA_turf_count = {
    params ["_box", "_cls"];
    if (isNull _box) exitWith { 0 };
    private _n = 0;
    { if ((_x select 0) isEqualTo _cls) then { _n = _n + (_x select 1) } } forEach (_box call OT_fnc_unitStock);
    _n
};
// Empties the drugs out of the containers round a place
OTQA_turf_clearAround = {
    params ["_pos"];
    { private _b = _x; { [_b, _x, 1000] call OT_fnc_removeFromCargo } forEach ["OT_Ganja", "OT_Blow"] } forEach (nearestObjects [_pos, [OT_item_CargoContainer], 50]);
};
// Whether the host has been shown a notification with this in it (OT_notifyHistory, emptied by the tests as they go)
OTQA_turf_notified = {
    params ["_text"];
    (OT_notifyHistory findIf { _text in _x }) > -1
};
// A dry spot on land at least _dist from _pos (the host stands there)
OTQA_turf_landAway = {
    params ["_pos", "_dist"];
    private _found = [];
    for "_dir" from 0 to 330 step 30 do {
        private _p = _pos getPos [_dist, _dir];
        if ((_p select 0) < 50 || { (_p select 1) < 50 } || { (_p select 0) > worldSize - 50 } || { (_p select 1) > worldSize - 50 }) then { continue };
        if (surfaceIsWater _p) then { continue };
        _p = _p findEmptyPosition [0, 60, "CAManBase"];
        if (_p isNotEqualTo [] && { !surfaceIsWater _p }) exitWith { _found = _p };
    };
    _found
};
// The host on foot at a position (somewhere free near it)
OTQA_turf_standAt = {
    params ["_p"];
    if (!isNull objectParent player) then { moveOut player; sleep 1 };
    private _e = _p findEmptyPosition [0, 30, "CAManBase"];
    if (_e isEqualTo []) then { _e = _p };
    player setPosATL [_e select 0, _e select 1, 0];
};
// The host back where they were, able to be hurt, undercover again (a squad's fire costs their cover)
OTQA_turf_home = {
    player setPosASL (OTQA_turf getOrDefault ["home", getPosASL player]);
    player allowDamage true;
    player setCaptive true;
};
OTQA_turf_op = {
    private _name = OTQA_turf getOrDefault ["name", ""];
    private _ops = server getVariable ["drugOps", []];
    _ops param [_ops findIf { (_x select 0) isEqualTo _name }, []]
};
OTQA_turf_squad = {
    (missionNamespace getVariable ["OT_drugTurfSquads", createHashMap]) getOrDefault [OTQA_turf getOrDefault ["gang", -1], grpNull]
};

[
    ["Turf: setup, a test gang with its camp 600 m from the dispensary", {
        ["Turf: the functions are there", !isNil "OT_fnc_drugTurf" && { !isNil "OT_fnc_drugTurfStreet" } && { !isNil "OT_fnc_drugTurfDeal" } && { !isNil "OT_fnc_drugTurfAttack" } && { !isNil "OT_fnc_drugTurfInfo" } && { !isNil "OT_fnc_drugTurfMenu" }, ""] call OTQA_fnc_check;
        ["Turf: the numbers: 1.5 km turf, ganja 1 / blow 2 anger a unit, street x3, warn at 20, attack at 40, 3 men, 20% cut, $2,500 fee",
            OT_drugTurfRadius isEqualTo 1500 && { (OT_drugTurfAnger get "ganja") isEqualTo 1 } && { (OT_drugTurfAnger get "blow") isEqualTo 2 } && { OT_drugTurfStreetMult isEqualTo 3 } && { OT_drugTurfWarnAt isEqualTo 20 } && { OT_drugTurfAttackAt isEqualTo 40 } && { OT_drugTurfSquad isEqualTo 3 } && { OT_drugTurfCut isEqualTo 0.2 } && { OT_drugTurfDealFee isEqualTo 2500 },
            format ["%1 m, %2, x%3, warn %4, attack %5, %6 men, cut %7, fee %8", OT_drugTurfRadius, OT_drugTurfAnger, OT_drugTurfStreetMult, OT_drugTurfWarnAt, OT_drugTurfAttackAt, OT_drugTurfSquad, OT_drugTurfCut, OT_drugTurfDealFee]] call OTQA_fnc_check;

        private _name = OT_dispensaries param [0, ""];
        if (_name isEqualTo "") exitWith { ["Turf: a dispensary to test with", false, "none on this map"] call OTQA_fnc_check };
        private _pos = (_name call OT_fnc_getBusinessData) select 0;
        private _town = _pos call OT_fnc_nearestTown;
        OTQA_turf set ["name", _name];
        OTQA_turf set ["pos", _pos];
        OTQA_turf set ["town", _town];
        OTQA_turf set ["home", getPosASL player];
        OTQA_turf set ["money", player getVariable ["money", 0]];
        OTQA_turf set ["funds", [] call OT_fnc_resistanceFunds];
        OTQA_turf set ["deals", +(server getVariable ["drugTurfDeals", []])];
        OTQA_turf set ["anger", +(server getVariable ["drugTurfAnger", []])];

        // The dispensary: the resistance's (a general buys it) and a drug operation
        if !(_name in (server getVariable ["GEURowned", []])) then {
            if !(call OT_fnc_playerIsGeneral) exitWith {};
            [_pos] call OTQA_turf_standAt;
            [(_name call OT_fnc_getBusinessPrice) + 1000] call OT_fnc_resistanceFunds;
            sleep 1;
            call OT_fnc_buyBusiness;
            sleep 2;
            player setPosASL (OTQA_turf get "home");
        };
        if !(_name in (server getVariable ["GEURowned", []])) exitWith { ["Turf: the dispensary is the resistance's (run as a general to buy it)", false, _name] call OTQA_fnc_check };
        [_name] call OT_fnc_dispensaryRegister;
        ["Turf: the dispensary is a drug operation", (call OTQA_turf_op) isNotEqualTo [], _name] call OTQA_fnc_check;

        // The test gang, its camp 600 m from the dispensary (on land when there is some); other gangs near it moved away
        private _camp = [_pos, 600] call OTQA_turf_landAway;
        if (_camp isEqualTo []) then { _camp = _pos getPos [600, 0] };
        private _gangid = [_town, _camp] call OTQA_turf_makeGang;
        OTQA_turf set ["gang", _gangid];
        OTQA_turf set ["camp", _camp];
        OTQA_turf set ["rep", player getVariable [format ["gangrep%1", _gangid], 0]];
        player setVariable [format ["gangrep%1", _gangid], 0, true];
        [_pos] call OTQA_turf_claim;
        private _found = [_pos] call OT_fnc_drugTurfGang;
        ["Turf: the dispensary is on the test gang's turf (the nearest camp within 1.5 km)", (_found param [0, -1]) isEqualTo _gangid && { ((_found param [1, []]) param [8, ""]) isEqualTo "QA Turf Gang" }, format ["gang %1 (%2 others moved away)", _found param [0, -1], count (OTQA_turf get "others")]] call OTQA_fnc_check;
        ["Turf: the camp and 1.4 km from it are its turf, 1.6 km isn't", (([_camp] call OT_fnc_drugTurfGang) param [0, -1]) isEqualTo _gangid && { (([_camp getPos [1400, 90]] call OT_fnc_drugTurfGang) param [0, -1]) isEqualTo _gangid } && { (([_camp getPos [1600, 90]] call OT_fnc_drugTurfGang) param [0, -1]) isNotEqualTo _gangid },
            format ["%1 / %2 / %3", ([_camp] call OT_fnc_drugTurfGang) param [0, -1], ([_camp getPos [1400, 90]] call OT_fnc_drugTurfGang) param [0, -1], ([_camp getPos [1600, 90]] call OT_fnc_drugTurfGang) param [0, -1]]] call OTQA_fnc_check;
        ["Turf: no anger, no deal to start with", ([_gangid] call OT_fnc_drugTurfAngerOf) isEqualTo 0 && { ([_gangid] call OT_fnc_drugTurfDealOf) isEqualTo [] } && { ([0] call OT_fnc_drugTurfMood) isEqualTo "not bothered" }, ""] call OTQA_fnc_check;
    }, 60],

    ["Turf: off its turf nothing happens; on it anger and rep loss grow with the amount, blow double, half for a friend", {
        private _gangid = OTQA_turf getOrDefault ["gang", -1];
        if (_gangid < 0) exitWith { ["Turf: the test gang", false, "no setup"] call OTQA_fnc_check };
        private _name = OTQA_turf get "name";
        private _pos = OTQA_turf get "pos";
        private _camp = OTQA_turf get "camp";
        private _repKey = format ["gangrep%1", _gangid];
        OT_notifyHistory = [];

        // Off turf: the camp 3 km away
        [_gangid, _pos getPos [3000, 0]] call OTQA_turf_setCamp;
        private _res = [_name, "ganja", 6] call OT_fnc_drugTurf;
        ["Turf: with the camp 3 km away a sale is nobody's business", _res isEqualTo [] && { ([_gangid] call OT_fnc_drugTurfAngerOf) isEqualTo 0 } && { (player getVariable [_repKey, 0]) isEqualTo 0 }, format ["%1, anger %2", _res, [_gangid] call OT_fnc_drugTurfAngerOf]] call OTQA_fnc_check;
        ["Turf: the business info says nothing about turf then", (_name call OT_fnc_drugTurfInfo) isEqualTo "", _name call OT_fnc_drugTurfInfo] call OTQA_fnc_check;

        // On turf: 6 ganja = 6 anger, the rep loss carried over (10 points a rep)
        [_gangid, _camp] call OTQA_turf_setCamp;
        _res = [_name, "ganja", 6] call OT_fnc_drugTurf;
        private _anger = [_gangid] call OT_fnc_drugTurfAngerOf;
        ["Turf: on its turf 6 ganja sold = 6 anger, no whole rep point lost yet (10 points a rep)", (_res param [0, -1]) isEqualTo _gangid && { (abs (_anger - 6)) < 0.2 } && { (player getVariable [_repKey, 0]) isEqualTo 0 }, format ["%1, anger %2, rep %3", _res, _anger, player getVariable [_repKey, 0]]] call OTQA_fnc_check;
        ["Turf: under 20 anger no warning", !(["angry about"] call OTQA_turf_notified), str OT_notifyHistory] call OTQA_fnc_check;
        // 7 blow = 14 more (double): 20 in all, 2 rep lost, the warning
        _res = [_name, "blow", 7] call OT_fnc_drugTurf;
        sleep 0.5;
        _anger = [_gangid] call OT_fnc_drugTurfAngerOf;
        ["Turf: 7 blow = 14 anger (double), 20 in all: -2 rep for the host", (abs (_anger - 20)) < 0.3 && { (player getVariable [_repKey, 0]) isEqualTo -2 }, format ["anger %1, rep %2", _anger, player getVariable [_repKey, 0]]] call OTQA_fnc_check;
        ["Turf: at 20 anger they warn everyone: 'QA Turf Gang are angry about our dispensary ... pay their cut'", ["QA Turf Gang are angry about our dispensary"] call OTQA_turf_notified, str OT_notifyHistory] call OTQA_fnc_check;
        ["Turf: the business info says whose turf it's on and that they're angry", "On QA Turf Gang's turf" in (_name call OT_fnc_drugTurfInfo) && { (format ["No deal: they're %1", ([_gangid] call OT_fnc_drugTurfAngerOf) call OT_fnc_drugTurfMood]) in (_name call OT_fnc_drugTurfInfo) }, _name call OT_fnc_drugTurfInfo] call OTQA_fnc_check;
        OT_notifyHistory = [];
        _res = [_name, "ganja", 2] call OT_fnc_drugTurf;
        sleep 0.5;
        ["Turf: they warn once (until it has blown over)", !(["angry about"] call OTQA_turf_notified), str OT_notifyHistory] call OTQA_fnc_check;

        // A friend of the gang (+20 rep): half the offence
        player setVariable [_repKey, OT_drugGangRep, true];
        _res = [_name, "ganja", 10] call OT_fnc_drugTurf;
        _anger = [_gangid] call OT_fnc_drugTurfAngerOf;
        ["Turf: with +20 rep (a friend of the gang) 10 ganja anger them only 5 (half) and cost no rep", (abs (_anger - 27)) < 0.5 && { (player getVariable [_repKey, 0]) isEqualTo OT_drugGangRep }, format ["anger %1, rep %2", _anger, player getVariable [_repKey, 0]]] call OTQA_fnc_check;
        ["Turf: the anger is forgotten at half a point a minute", (abs ((((server getVariable ["drugTurfAnger", []]) select { (_x select 0) isEqualTo _gangid }) param [0, []]) param [1, 0]) - _anger) < 0.2 && { OT_drugTurfDecay isEqualTo 0.5 }, str ((server getVariable ["drugTurfAnger", []]) select { (_x select 0) isEqualTo _gangid })] call OTQA_fnc_check;
        player setVariable [_repKey, 0, true];
    }, 60],

    ["Turf: street selling on its turf angers them three times as much, off it not at all", {
        private _gangid = OTQA_turf getOrDefault ["gang", -1];
        if (_gangid < 0) exitWith { ["Turf: the test gang", false, "no setup"] call OTQA_fnc_check };
        private _pos = OTQA_turf get "pos";
        private _repKey = format ["gangrep%1", _gangid];
        [_gangid, 10] call OTQA_turf_setAnger;
        player setVariable [_repKey, 0, true];
        OT_notifyHistory = [];

        private _res = [player, _pos, "OT_Ganja", 1, 60] call OT_fnc_drugTurfStreet;
        private _anger = [_gangid] call OT_fnc_drugTurfAngerOf;
        ["Turf: 1 ganja sold on the street on their turf = 3 anger (13 now)", (_res param [0, -1]) isEqualTo _gangid && { (abs (_anger - 13)) < 0.3 }, format ["%1, anger %2", _res, _anger]] call OTQA_fnc_check;
        _res = [player, _pos, "OT_Blow", 2, 300] call OT_fnc_drugTurfStreet;
        sleep 0.5;
        _anger = [_gangid] call OT_fnc_drugTurfAngerOf;
        ["Turf: 2 blow on the street = 12 anger (25 now), -1 rep (the rest carried over), the seller warned", (abs (_anger - 25)) < 0.4 && { (player getVariable [_repKey, 0]) isEqualTo -1 } && { ["don't like you dealing on their turf"] call OTQA_turf_notified }, format ["anger %1, rep %2, %3", _anger, player getVariable [_repKey, 0], OT_notifyHistory]] call OTQA_fnc_check;
        _res = [player, _pos getPos [3000, 180], "OT_Ganja", 1, 60] call OT_fnc_drugTurfStreet;
        ["Turf: a street sale 3 km away doesn't bother them", (_res param [0, -1]) isNotEqualTo _gangid && { (abs (([_gangid] call OT_fnc_drugTurfAngerOf) - 25)) < 0.5 }, format ["%1, anger %2", _res, [_gangid] call OT_fnc_drugTurfAngerOf]] call OTQA_fnc_check;
        player setVariable [_repKey, 0, true];
    }, 60],

    ["Turf: enough anger sends 3 of their men to the operation with a warning; they take their cut and go; gone once nobody is near", {
        private _gangid = OTQA_turf getOrDefault ["gang", -1];
        if (_gangid < 0) exitWith { ["Turf: the test gang", false, "no setup"] call OTQA_fnc_check };
        private _name = OTQA_turf get "name";
        private _pos = OTQA_turf get "pos";
        private _container = [_pos] call OT_fnc_dispensaryContainer;
        [_pos] call OTQA_turf_clearAround;
        _container addItemCargoGlobal ["OT_Ganja", 12];
        _container addItemCargoGlobal ["OT_Blow", 7];
        OT_notifyHistory = [];

        // The host at the dispensary (in spawn distance), unhurt while they're about
        [_pos] call OTQA_turf_standAt;
        player allowDamage false;
        [_gangid, OT_drugTurfAttackAt - 1] call OTQA_turf_setAnger;
        private _res = [_name, "ganja", 1] call OT_fnc_drugTurf;
        sleep 0.5;
        private _group = call OTQA_turf_squad;
        private _units = units _group;
        ["Turf: at 40 anger the anger is spent and a squad of 3 sets off", (_res param [1, -1]) isEqualTo 0 && { !isNull _group } && { (count _units) isEqualTo 3 } && { (_units findIf { !alive _x }) isEqualTo -1 }, format ["%1, %2 units", _res, count _units]] call OTQA_fnc_check;
        ["Turf: everyone is warned: 'QA Turf Gang are sending men to our dispensary ... pay their cut ... or defend it'", ["QA Turf Gang are sending men to our dispensary"] call OTQA_turf_notified, str OT_notifyHistory] call OTQA_fnc_check;
        private _weapon = (((OT_civilians getVariable [format ["gang%1", _gangid], []]) param [5, []]) param [0, []]) param [0, ""];
        ["Turf: they're the gang's men with its gear, opfor, 150-500 m from the operation", _units isNotEqualTo [] && { side _group isEqualTo opfor } && { (_units findIf { (_x getVariable ["OT_gangid", -2]) isNotEqualTo _gangid || { _weapon isNotEqualTo "" && { ((primaryWeapon _x) call BIS_fnc_baseWeapon) isNotEqualTo (_weapon call BIS_fnc_baseWeapon) } } || { (_x distance2D _pos) < 150 } || { (_x distance2D _pos) > 500 } }) isEqualTo -1 },
            format ["gang gun %1: %2", _weapon, _units apply { [_x getVariable ["OT_gangid", -2], primaryWeapon _x, round (_x distance2D _pos)] }]] call OTQA_fnc_check;

        // At the operation (moved there, nobody waits for them to walk): their cut by force
        { _x setPosATL (_pos getPos [8, _forEachIndex * 120]) } forEach _units;
        private _timeout = time + 20;
        waitUntil { sleep 1; ([_container, "OT_Ganja"] call OTQA_turf_count) < 12 || { time > _timeout } };
        sleep 0.5;
        private _ganja = [_container, "OT_Ganja"] call OTQA_turf_count;
        private _blow = [_container, "OT_Blow"] call OTQA_turf_count;
        ["Turf: at the operation they take up to 10 ganja and 5 blow out of its container", _ganja isEqualTo 2 && { _blow isEqualTo 2 }, format ["%1 ganja, %2 blow left", _ganja, _blow]] call OTQA_fnc_check;
        ["Turf: everyone is told: 'QA Turf Gang raided our dispensary ... and took 10 ... and 5 ...'", ["raided our dispensary"] call OTQA_turf_notified && { ["took 10"] call OTQA_turf_notified } && { ["and 5"] call OTQA_turf_notified }, str OT_notifyHistory] call OTQA_fnc_check;

        // No second attack within 20 minutes of the last: the anger just builds, capped at 80
        [_gangid, OT_drugTurfAttackAt + 5, serverTime] call OTQA_turf_setAnger;
        _res = [_name, "ganja", 50] call OT_fnc_drugTurf;
        ["Turf: within 20 minutes of their last attack the anger only builds (capped at 80), no second squad", (_res param [1, 0]) isEqualTo (OT_drugTurfAttackAt * 2) && { (call OTQA_turf_squad) isEqualTo _group }, str _res] call OTQA_fnc_check;

        // Gone once no player is within 400 m: the host moves 1 km off
        private _away = [_pos, 1000] call OTQA_turf_landAway;
        if (_away isEqualTo []) then {
            "Turf: no dry land 1 km from the dispensary to check the squad is deleted once nobody is near; in play, leave a raid behind and come back later: they're gone" call OTQA_fnc_manual;
            { deleteVehicle _x } forEach _units;
        } else {
            player setPosATL [_away select 0, _away select 1, 0];
            _timeout = time + 40;
            waitUntil { sleep 1; (_units findIf { !isNull _x }) isEqualTo -1 || { time > _timeout } };
            sleep 1.5;
            ["Turf: with no player within 400 m the squad is deleted and the gang free to send another", (_units findIf { !isNull _x }) isEqualTo -1 && { isNull (call OTQA_turf_squad) }, format ["%1 left, squad %2", { !isNull _x } count _units, call OTQA_turf_squad]] call OTQA_fnc_check;
        };
        call OTQA_turf_home;
    }, 120],

    ["Turf: a raid on an operation out of spawn distance is simulated after the delay", {
        private _gangid = OTQA_turf getOrDefault ["gang", -1];
        if (_gangid < 0) exitWith { ["Turf: the test gang", false, "no setup"] call OTQA_fnc_check };
        private _name = OTQA_turf get "name";
        private _pos = OTQA_turf get "pos";
        private _container = [_pos] call OT_fnc_dispensaryContainer;
        private _away = [_pos, OT_spawnDistance + 300] call OTQA_turf_landAway;
        if (_away isEqualTo []) exitWith { "Turf: no dry land 1.5 km from the dispensary to check a raid out of spawn distance is simulated; in play, far from an operation being raided, 'raided our dispensary' comes 3 minutes after the warning" call OTQA_fnc_manual };
        if (!isNull objectParent player) then { moveOut player; sleep 1 };
        player setPosATL [_away select 0, _away select 1, 0];
        sleep 0.5;
        if ([_pos] call OT_fnc_inSpawnDistance) exitWith {
            "Turf: something keeps the dispensary in spawn distance with the host 1.5 km off (a tracked unit near it?): the simulated raid wasn't checked" call OTQA_fnc_manual;
            call OTQA_turf_home;
        };
        [_pos] call OTQA_turf_clearAround;
        _container addItemCargoGlobal ["OT_Ganja", 4];
        private _delay = OT_drugTurfAttackDelay;
        OT_drugTurfAttackDelay = 2;
        OT_notifyHistory = [];

        [_gangid, OT_drugTurfAttackAt] call OTQA_turf_setAnger;
        private _res = [_name, "ganja", 1] call OT_fnc_drugTurf;
        sleep 0.5;
        ["Turf: out of spawn distance nobody is spawned, but everyone is warned", (_res param [1, -1]) isEqualTo 0 && { isNull (call OTQA_turf_squad) } && { ["sending men to our dispensary"] call OTQA_turf_notified }, format ["%1, squad %2, %3", _res, call OTQA_turf_squad, OT_notifyHistory]] call OTQA_fnc_check;
        private _timeout = time + 15;
        waitUntil { sleep 1; ([_container, "OT_Ganja"] call OTQA_turf_count) isEqualTo 0 || { time > _timeout } };
        ["Turf: after the delay (2 s for the test, 3 min in play) the raid is simulated: the 4 ganja are gone, 'raided our dispensary ... took 4'", ([_container, "OT_Ganja"] call OTQA_turf_count) isEqualTo 0 && { ["raided our dispensary"] call OTQA_turf_notified } && { ["took 4"] call OTQA_turf_notified } && { isNull (call OTQA_turf_squad) }, format ["%1 ganja left, %2", [_container, "OT_Ganja"] call OTQA_turf_count, OT_notifyHistory]] call OTQA_fnc_check;
        OT_drugTurfAttackDelay = _delay;
        call OTQA_turf_home;
    }, 60],

    ["Turf: street dealing with enough anger brings an ambush on the dealer; called off, they go home", {
        private _gangid = OTQA_turf getOrDefault ["gang", -1];
        if (_gangid < 0) exitWith { ["Turf: the test gang", false, "no setup"] call OTQA_fnc_check };
        private _pos = OTQA_turf get "pos";
        [_pos] call OTQA_turf_standAt;
        player allowDamage false;
        OT_notifyHistory = [];
        [_gangid, OT_drugTurfAttackAt - 1] call OTQA_turf_setAnger;
        private _res = [player, getPosATL player, "OT_Ganja", 1, 60] call OT_fnc_drugTurfStreet;
        sleep 0.5;
        private _group = call OTQA_turf_squad;
        private _units = units _group;
        ["Turf: at 40 anger 3 of their men come for the dealer, 150-400 m off, with the warning 'QA Turf Gang are coming for you'", (_res param [1, -1]) isEqualTo 0 && { !isNull _group } && { (count _units) isEqualTo 3 } && { (_units findIf { (_x distance2D player) < 150 || { (_x distance2D player) > 400 } }) isEqualTo -1 } && { ["QA Turf Gang are coming for you"] call OTQA_turf_notified },
            format ["%1, %2 units at %3, %4", _res, count _units, _units apply { round (_x distance2D player) }, OT_notifyHistory]] call OTQA_fnc_check;
        ["Turf: they're the gang's men", _units isNotEqualTo [] && { (_units findIf { (_x getVariable ["OT_gangid", -2]) isNotEqualTo _gangid }) isEqualTo -1 } && { side _group isEqualTo opfor }, str (_units apply { _x getVariable ["OT_gangid", -2] })] call OTQA_fnc_check;

        // Called off (as when the deal is made): home, and deleted once no player is within 400 m
        _group setVariable ["OT_drugTurfEnd", true];
        private _away = [_pos, 1000] call OTQA_turf_landAway;
        if (_away isEqualTo []) then {
            "Turf: no dry land 1 km from the dispensary to check an ambush called off is deleted once nobody is near" call OTQA_fnc_manual;
            { deleteVehicle _x } forEach _units;
        } else {
            player setPosATL [_away select 0, _away select 1, 0];
            private _timeout = time + 40;
            waitUntil { sleep 1; (_units findIf { !isNull _x }) isEqualTo -1 || { time > _timeout } };
            sleep 1.5;
            ["Turf: called off (OT_drugTurfEnd) and nobody within 400 m, the ambush is deleted", (_units findIf { !isNull _x }) isEqualTo -1 && { isNull (call OTQA_turf_squad) }, format ["%1 left", { !isNull _x } count _units]] call OTQA_fnc_check;
        };
        call OTQA_turf_home;
    }, 120],

    ["Turf: the deal: the fee, no more anger, their cut out of dispensary sales, lab batches and street sales, the business info", {
        private _gangid = OTQA_turf getOrDefault ["gang", -1];
        if (_gangid < 0) exitWith { ["Turf: the test gang", false, "no setup"] call OTQA_fnc_check };
        private _name = OTQA_turf get "name";
        private _pos = OTQA_turf get "pos";
        private _town = OTQA_turf get "town";
        private _camp = OTQA_turf get "camp";
        private _uid = getPlayerUID player;
        private _repKey = format ["gangrep%1", _gangid];

        player setVariable ["money", 100, true];
        private _ok = [_gangid, _uid, true] call OT_fnc_drugTurfDeal;
        ["Turf: the deal needs the $2,500 fee", !_ok && { ([_gangid] call OT_fnc_drugTurfDealOf) isEqualTo [] }, str _ok] call OTQA_fnc_check;

        player setVariable ["money", 10000, true];
        player setVariable [_repKey, 0, true];
        [_gangid, 30] call OTQA_turf_setAnger;
        OT_notifyHistory = [];
        _ok = [_gangid, _uid, true] call OT_fnc_drugTurfDeal;
        sleep 1;
        private _deal = [_gangid] call OT_fnc_drugTurfDealOf;
        ["Turf: the deal is made: $2,500 paid, +5 rep, the anger forgotten, everyone told", _ok && { (player getVariable ["money", 0]) isEqualTo 7500 } && { (player getVariable [_repKey, 0]) isEqualTo 5 } && { ([_gangid] call OT_fnc_drugTurfAngerOf) isEqualTo 0 } && { _deal isEqualTo [_gangid, _uid, 0, 0, 0] } && { ["Deal with QA Turf Gang"] call OTQA_turf_notified },
            format ["%1, money %2, rep %3, anger %4, deal %5, %6", _ok, player getVariable ["money", 0], player getVariable [_repKey, 0], [_gangid] call OT_fnc_drugTurfAngerOf, _deal, OT_notifyHistory]] call OTQA_fnc_check;
        ["Turf: no second deal with the same gang", !([_gangid, _uid, true] call OT_fnc_drugTurfDeal) && { (player getVariable ["money", 0]) isEqualTo 7500 }, ""] call OTQA_fnc_check;

        // A dispensary sale: a fifth of its worth out of resistance funds a second later, no anger
        private _price = [_town, "OT_Ganja"] call OT_fnc_getDrugPrice;
        private _cut = round (6 * _price * OT_drugTurfCut);
        server setVariable ["money", 50000, true];
        OT_notifyHistory = [];
        private _res = [_name, "ganja", 6] call OT_fnc_drugTurf;
        private _funds = [] call OT_fnc_resistanceFunds;
        sleep 1.5;
        ["Turf: a dispensary sale of 6 ganja with a deal: no anger, their cut (20% of its worth at the town's price) out of resistance funds a second later", _res isEqualTo [_gangid, 0, _cut] && { _funds isEqualTo 50000 } && { ([] call OT_fnc_resistanceFunds) isEqualTo (50000 - _cut) } && { ([_gangid] call OT_fnc_drugTurfAngerOf) isEqualTo 0 },
            format ["%1 (cut $%2 of 6 x $%3), funds %4 then %5, anger %6", _res, _cut, _price, _funds, [] call OT_fnc_resistanceFunds, [_gangid] call OT_fnc_drugTurfAngerOf]] call OTQA_fnc_check;
        ["Turf: the cut is noted: 'QA Turf Gang's cut of our dispensary ...: $N'", ["QA Turf Gang's cut of our dispensary"] call OTQA_turf_notified, str OT_notifyHistory] call OTQA_fnc_check;

        // A street sale: a fifth of the money out of the seller's
        _res = [player, _pos, "OT_Ganja", 1, 100] call OT_fnc_drugTurfStreet;
        sleep 1;
        ["Turf: a street sale for $100 with a deal: $20 to the gang out of the seller's money, no anger", _res isEqualTo [_gangid, 0, 20] && { (player getVariable ["money", 0]) isEqualTo 7480 } && { ([_gangid] call OT_fnc_drugTurfAngerOf) isEqualTo 0 }, format ["%1, money %2", _res, player getVariable ["money", 0]]] call OTQA_fnc_check;

        // What's been paid, in the deal and the business info
        _deal = [_gangid] call OT_fnc_drugTurfDealOf;
        private _info = _name call OT_fnc_drugTurfInfo;
        ["Turf: the deal keeps the totals (cash, blow) and the rep carried over (+1 per $1,000 paid)", (_deal select 2) isEqualTo (_cut + 20) && { (_deal select 3) isEqualTo 0 } && { (player getVariable [_repKey, 0]) isEqualTo (5 + floor ((_cut + 20) / OT_drugTurfRepPerPaid)) }, format ["%1, rep %2", _deal, player getVariable [_repKey, 0]]] call OTQA_fnc_check;
        ["Turf: the business info shows the deal and what's been paid", "Deal: they take 20%" in _info && { (format ["$%1 and 0 blow paid so far", [_cut + 20, 1, 0, true] call CBA_fnc_formatNumber]) in _info }, _info] call OTQA_fnc_check;

        // A lab batch: a fifth of the blow out of the lab's container
        private _site = (missionNamespace getVariable ["OT_drugLabSites", []]) param [0, []];
        if (_site isEqualTo []) then {
            "Turf: no lab site on this map to check the cut of a lab batch (a fifth of the blow out of its container)" call OTQA_fnc_manual;
        } else {
            _site params ["_labId", "_labName", "_labPos"];
            private _wasOn = ((server getVariable ["drugOps", []]) findIf { (_x select 0) isEqualTo _labId }) > -1;
            _labName call OT_fnc_drugLabRegister;
            private _box = _labName call OT_fnc_drugLabContainer;
            // The test gang's camp by the lab for this (other gangs there moved away)
            [_gangid, _labPos getPos [300, 0]] call OTQA_turf_setCamp;
            [_labPos] call OTQA_turf_claim;
            private _had = [_box, "OT_Blow"] call OTQA_turf_count;
            _box addItemCargoGlobal ["OT_Blow", 10];
            _res = [_labId, "blow", 10] call OT_fnc_drugTurf;
            _deal = [_gangid] call OT_fnc_drugTurfDealOf;
            ["Turf: a lab batch of 10 blow with a deal: 2 blow (a fifth) out of the lab's container, booked on the deal, no anger", _res isEqualTo [_gangid, 0, 2] && { ([_box, "OT_Blow"] call OTQA_turf_count) isEqualTo (_had + 8) } && { (_deal select 3) isEqualTo 2 } && { ([_gangid] call OT_fnc_drugTurfAngerOf) isEqualTo 0 },
                format ["%1, blow %2 -> %3, deal %4", _res, _had, [_box, "OT_Blow"] call OTQA_turf_count, _deal]] call OTQA_fnc_check;
            ["Turf: the lab's business info shows the deal too", "Deal: they take 20%" in (_labName call OT_fnc_drugTurfInfo), _labName call OT_fnc_drugTurfInfo] call OTQA_fnc_check;
            [_box, "OT_Blow", 8] call OT_fnc_removeFromCargo;
            [_gangid, _camp] call OTQA_turf_setCamp;
            if (!_wasOn) then { server setVariable ["drugOps", (server getVariable ["drugOps", []]) select { (_x select 0) isNotEqualTo _labId }, true] };
        };
    }, 90],

    ["Turf: ending the deal; a gang that's gone takes its deal with it; cleanup", {
        private _gangid = OTQA_turf getOrDefault ["gang", -1];
        if (_gangid < 0) exitWith { ["Turf: the test gang", false, "no setup"] call OTQA_fnc_check };
        private _name = OTQA_turf get "name";
        private _pos = OTQA_turf get "pos";
        private _town = OTQA_turf get "town";
        private _uid = getPlayerUID player;
        OT_notifyHistory = [];

        private _ok = [_gangid, _uid, false] call OT_fnc_drugTurfDeal;
        sleep 0.5;
        ["Turf: the deal ended: gone from the deals, everyone told, nothing back", _ok && { ([_gangid] call OT_fnc_drugTurfDealOf) isEqualTo [] } && { ["The deal with QA Turf Gang is off"] call OTQA_turf_notified } && { (player getVariable ["money", 0]) isEqualTo 7480 }, format ["%1, %2", _ok, OT_notifyHistory]] call OTQA_fnc_check;
        private _res = [_name, "ganja", 6] call OT_fnc_drugTurf;
        ["Turf: without the deal a sale angers them again", (_res param [0, -1]) isEqualTo _gangid && { (_res param [1, 0]) > 5.5 }, str _res] call OTQA_fnc_check;
        ["Turf: ending it again does nothing", !([_gangid, _uid, false] call OT_fnc_drugTurfDeal), ""] call OTQA_fnc_check;

        // A deal with a gang that's gone ends by itself; its turf is nobody's
        player setVariable ["money", 10000, true];
        [_gangid, _uid, true] call OT_fnc_drugTurfDeal;
        sleep 0.5;
        private _hadDeal = ([_gangid] call OT_fnc_drugTurfDealOf) isNotEqualTo [];
        OT_civilians setVariable [format ["gang%1", _gangid], nil, true];
        private _gangs = OT_civilians getVariable [format ["gangs%1", _town], []];
        _gangs = _gangs - [_gangid];
        OT_civilians setVariable [format ["gangs%1", _town], _gangs, true];
        ["Turf: a gang that's gone takes its deal with it, and its turf is nobody's", _hadDeal && { ([_gangid] call OT_fnc_drugTurfDealOf) isEqualTo [] } && { (([_pos] call OT_fnc_drugTurfGang) param [0, -1]) isNotEqualTo _gangid } && { (([_name, "ganja", 6] call OT_fnc_drugTurf) param [0, -1]) isNotEqualTo _gangid },
            format ["deal before %1, after %2, turf %3", _hadDeal, [_gangid] call OT_fnc_drugTurfDealOf, ([_pos] call OT_fnc_drugTurfGang) param [0, -1]]] call OTQA_fnc_check;

        // Cleanup: the other gangs' camps back, the test gang's spawn group and any squad gone, the records and the host as they were
        { [_x select 0, _x select 1] call OTQA_turf_setCamp } forEach (OTQA_turf getOrDefault ["others", []]);
        private _spawnGroup = spawner getVariable [format ["gangspawn%1", _gangid], grpNull];
        if (!isNull _spawnGroup) then { { deleteVehicle _x } forEach (units _spawnGroup); deleteGroup _spawnGroup };
        spawner setVariable [format ["gangspawn%1", _gangid], nil, true];
        private _squad = call OTQA_turf_squad;
        if (!isNull _squad) then { { deleteVehicle _x } forEach (units _squad) };
        server setVariable ["drugTurfDeals", OTQA_turf getOrDefault ["deals", []], true];
        server setVariable ["drugTurfAnger", OTQA_turf getOrDefault ["anger", []], true];
        server setVariable ["money", OTQA_turf getOrDefault ["funds", 0], true];
        player setVariable ["money", OTQA_turf getOrDefault ["money", 0], true];
        player setVariable [format ["gangrep%1", _gangid], OTQA_turf getOrDefault ["rep", 0], true];
        call OTQA_turf_home;
        ["Turf: cleaned up: the test gang gone, the other gangs' camps back, the records as they were", (OT_civilians getVariable [format ["gang%1", _gangid], []]) isEqualTo [] && { !(_gangid in (OT_civilians getVariable [format ["gangs%1", _town], []])) } && { ((OTQA_turf getOrDefault ["others", []]) findIf { ((OT_civilians getVariable [format ["gang%1", _x select 0], []]) param [4, []]) isNotEqualTo (_x select 1) }) isEqualTo -1 } && { ((server getVariable ["drugTurfAnger", []]) findIf { (_x select 0) isEqualTo _gangid }) isEqualTo -1 },
            format ["%1 others put back", count (OTQA_turf getOrDefault ["others", []])]] call OTQA_fnc_check;
    }, 60]
]
