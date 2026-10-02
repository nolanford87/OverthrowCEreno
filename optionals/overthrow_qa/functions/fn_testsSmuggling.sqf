/*
    Description:
    Logistics, illegal freight (OT_fnc_logisticsIllegalOffers, OT_fnc_logisticsStart,
    OT_fnc_logisticsSettle, OT_fnc_logisticsSearchContraband, OT_fnc_logisticsImpound): smuggling
    contracts and add-ons only with a gang, paying more than legal work; contraband crates tagged;
    the job's illegal state in OT_logisticsJobs; cash, vehicle and reputation collateral settled on
    delivery and failure; a search with contraband blowing cover; a deposit left over from a loaded
    game paid back. Part of the current QA tests. Run it as the host. A test gang (id 990001, "QA
    Gang") is made at the first broker for each test and taken away after; contracts are made by hand
    near the player and their crates deleted afterwards.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Smuggling: at a freight broker with a gang on the map, the board sometimes shows an 'ILLEGAL: smuggle ...' contract and '+ illegal option' on legal ones; the header names the gang" call OTQA_fnc_manual;
"Smuggling: accepting illegal work asks for collateral (cash deposit, an owned vehicle within 60 m, gang reputation), then own vehicle or rental; the task text says it's illegal, for whom, and the collateral" call OTQA_fnc_manual;
"Smuggling: through a NATO checkpoint with contraband crates loaded: 'What's in these crates?! Contraband!', cover blown (wanted); with legal freight still 'Freight checked, move along'" call OTQA_fnc_manual;
"Smuggling: after a vehicle was impounded, 'Impound lot' at an owned warehouse or resistance base lists it with its fee; paying puts it by the garage" call OTQA_fnc_manual;

OTQA_smug_gangId = 990001;

// A test gang with its camp at the first broker (the nearest gang to it), in that broker's town's gang list
OTQA_smug_gangUp = {
    private _broker = (server getVariable ["logisticsBrokers", []]) param [0, []];
    private _pos = _broker param [3, getPosATL player];
    private _town = _pos call OT_fnc_nearestTown;
    OT_civilians setVariable [format ["gang%1", OTQA_smug_gangId], [[], -1, _town, "", _pos, [], 0, 1, "QA Gang"], true];
    private _gangs = OT_civilians getVariable [format ["gangs%1", _town], []];
    _gangs pushBackUnique OTQA_smug_gangId;
    OT_civilians setVariable [format ["gangs%1", _town], _gangs, true];
    OTQA_smug_gangTown = _town;
    player setVariable [format ["gangrep%1", OTQA_smug_gangId], 0, true];
};
OTQA_smug_gangDown = {
    if (isNil "OTQA_smug_gangTown") exitWith {};
    private _gangs = OT_civilians getVariable [format ["gangs%1", OTQA_smug_gangTown], []];
    _gangs = _gangs - [OTQA_smug_gangId];
    OT_civilians setVariable [format ["gangs%1", OTQA_smug_gangTown], _gangs, true];
    OT_civilians setVariable [format ["gang%1", OTQA_smug_gangId], nil, true];
    player setVariable [format ["gangrep%1", OTQA_smug_gangId], nil, true];
};
OTQA_smug_rep = { player getVariable [format ["gangrep%1", OTQA_smug_gangId], 0] };

// A 15-element contract near the host: legal (kind "") or smuggling, with an optional add-on
OTQA_smug_contract = {
    params ["_id", "_crates", "_pay", ["_kind", "smuggle"], ["_contraband", "drugs"], ["_addon", []]];
    private _from = ((getPosATL player) getPos [25, getDir player]) findEmptyPosition [0, 60, "C_Truck_02_box_F"];
    if (_from isEqualTo []) then { _from = getPosATL player };
    private _to = ((getPosATL player) getPos [120, (getDir player) + 180]) findEmptyPosition [0, 80, "C_Truck_02_box_F"];
    if (_to isEqualTo []) then { _to = (getPosATL player) getPos [60, (getDir player) + 180] };
    private _gang = [OTQA_smug_gangId, ""] select (_kind isEqualTo "" && { _addon isEqualTo [] });
    [_id, _from, "QA yard", _to, "QA drop-off", _crates, ["van", "truck"] select (_crates > 2), _pay, 600, 0.2, "qa",
        _kind, [_contraband, ""] select (_kind isEqualTo ""), _addon, _gang]
};

OTQA_smug_cleanup = {
    params ["_objects"];
    { if (!isNull _x) then { detach _x; deleteVehicle _x } } forEach _objects;
    player setVariable ["OT_logisticsActive", "", true];
};

// Money after a remoteExec'd payment lands
OTQA_smug_waitMoney = {
    params ["_from"];
    private _timeout = time + 5;
    waitUntil { sleep 0.3; (player getVariable ["money", 0]) isNotEqualTo _from || { time > _timeout } };
    player getVariable ["money", 0]
};

[
    ["Smuggling: illegal offers only with a gang, paying more, add-ons on some legal offers", {
        if (isNil "OT_fnc_logisticsIllegalOffers") exitWith { ["Smuggling: OT_fnc_logisticsIllegalOffers exists", false, "missing"] call OTQA_fnc_check };
        private _broker = (server getVariable ["logisticsBrokers", []]) param [0, []];
        if (_broker isEqualTo []) exitWith { ["Smuggling: a freight broker to test with", false, "no brokers"] call OTQA_fnc_check };
        private _legal = [_broker select 0] call OT_fnc_logisticsOffers;
        ["Smuggling: the broker has legal offers to work with", _legal isNotEqualTo [], str count _legal] call OTQA_fnc_check;

        // No gang anywhere: nothing illegal
        private _stash = OT_allTowns apply { [_x, OT_civilians getVariable [format ["gangs%1", _x], []]] };
        { OT_civilians setVariable [format ["gangs%1", _x], []] } forEach OT_allTowns;
        private _none = 0;
        private _addonsNone = 0;
        for "_i" from 1 to 15 do {
            private _offers = +_legal;
            { _x resize 11 } forEach _offers; // As slice 1 made them
            _none = _none + count ([_broker, _offers] call OT_fnc_logisticsIllegalOffers);
            _addonsNone = _addonsNone + ({ (_x param [13, []]) isNotEqualTo [] } count _offers);
        };
        { OT_civilians setVariable [format ["gangs%1", _x select 0], _x select 1] } forEach _stash;
        ["Smuggling: no gang, no smuggling contracts or add-ons", _none isEqualTo 0 && { _addonsNone isEqualTo 0 }, format ["%1 contracts, %2 add-ons in 15 boards", _none, _addonsNone]] call OTQA_fnc_check;

        // With the test gang next to the broker
        call OTQA_smug_gangUp;
        private _smuggling = [];
        private _addons = [];
        private _padded = true;
        for "_i" from 1 to 20 do {
            private _offers = +_legal;
            { _x resize 11 } forEach _offers; // As slice 1 made them
            _smuggling append ([_broker, _offers] call OT_fnc_logisticsIllegalOffers);
            if ((_offers findIf { (count _x) isNotEqualTo 15 }) > -1) then { _padded = false };
            _addons append (_offers select { (_x select 13) isNotEqualTo [] });
        };
        ["Smuggling: legal offers padded to 15 elements", _padded, ""] call OTQA_fnc_check;
        ["Smuggling: smuggling contracts on some boards (about half)", (count _smuggling) > 2 && { (count _smuggling) < 19 }, format ["%1 in 20 boards", count _smuggling]] call OTQA_fnc_check;
        ["Smuggling: add-ons on some legal offers (about 35%)", (count _addons) > 2, format ["%1 of %2 legal offers", count _addons, 20 * count _legal]] call OTQA_fnc_check;
        private _bad = _smuggling select {
            (count _x) isNotEqualTo 15 || { (_x select 11) isNotEqualTo "smuggle" } || { !((_x select 12) in ["drugs", "weapons", "turtles"]) }
            || { (_x select 14) isNotEqualTo OTQA_smug_gangId } || { (_x select 13) isNotEqualTo [] } || { (_x select 10) isNotEqualTo (_broker select 0) }
        };
        ["Smuggling: smuggling contracts are for the nearest gang, contraband set", _bad isEqualTo [], str (_bad select [0, 2])] call OTQA_fnc_check;
        private _cheap = _smuggling select { (_x select 7) <= ((([_x select 1, _x select 3, _x select 5] call OT_fnc_logisticsPay) select 0) * 1.9) };
        ["Smuggling: smuggling pays at least about twice the legal rate", _cheap isEqualTo [], str (_cheap apply { [_x select 7, ([_x select 1, _x select 3, _x select 5] call OT_fnc_logisticsPay) select 0] })] call OTQA_fnc_check;
        private _badAddons = _addons select {
            (_x select 11) isNotEqualTo "" || { (_x select 14) isNotEqualTo OTQA_smug_gangId } || {
                (_x select 13) params ["_c", "_n", "_extra"];
                !(_c in ["drugs", "weapons", "turtles"]) || { !(_n in [1, 2]) } || { _extra <= 0 }
            }
        };
        ["Smuggling: add-ons are [contraband, 1-2 crates, extra pay] for the gang, the contract stays legal", _badAddons isEqualTo [], str (_badAddons select [0, 2])] call OTQA_fnc_check;
        call OTQA_smug_gangDown;
    }, 60],

    ["Smuggling: cash collateral taken, back on delivery, kept on failure; crates tagged; job state", {
        if (isNil "OT_fnc_logisticsSettle") exitWith { ["Smuggling: OT_fnc_logisticsSettle exists", false, "missing"] call OTQA_fnc_check };
        call OTQA_smug_gangUp;
        private _uid = getPlayerUID player;

        // Delivered
        private _id = format ["qasmug%1", round (random 100000)];
        private _contract = [_id, 2, 2000, "smuggle", "weapons"] call OTQA_smug_contract;
        private _deposit = 1000;
        if ((player getVariable ["money", 0]) < _deposit) then { player setVariable ["money", _deposit + 100, true] };
        private _money = player getVariable ["money", 0];
        [-_deposit] call OT_fnc_money; // As accepting does
        ([_contract, player, false, false, "cash", objNull, _deposit] call OT_fnc_logisticsStart) params [["_crates", []]];
        ["Smuggling: every crate of a smuggling load is tagged contraband", (count _crates) isEqualTo 2 && { (_crates findIf { (_x getVariable ["OT_contraband", ""]) isNotEqualTo "weapons" }) isEqualTo -1 },
            str (_crates apply { _x getVariable ["OT_contraband", ""] })] call OTQA_fnc_check;
        private _job = (missionNamespace getVariable ["OT_logisticsJobs", createHashMap]) getOrDefault [_id, []];
        ["Smuggling: OT_logisticsJobs has the job [kind, contraband, collateral, gang, add-on crates, uid, deposit, vehicle, rep stake, crates, add-on pay]",
            (_job select [0, 7]) isEqualTo ["smuggle", "weapons", "cash", OTQA_smug_gangId, 0, _uid, _deposit] && { (_job select 9) isEqualTo _crates }, str _job] call OTQA_fnc_check;
        ["Smuggling: the deposit is listed in the saved logisticsDeposits", ((server getVariable ["logisticsDeposits", []]) findIf { _x isEqualTo [_uid, _deposit, _id] }) > -1,
            str (server getVariable ["logisticsDeposits", []])] call OTQA_fnc_check;
        ["Smuggling: the deposit was taken", (player getVariable ["money", 0]) <= (_money - _deposit) + 50, format ["%1 -> %2", _money, player getVariable ["money", 0]]] call OTQA_fnc_check;
        private _before = player getVariable ["money", 0];
        private _rep = call OTQA_smug_rep;
        [_contract, _uid, "delivered"] call OT_fnc_logisticsSettle;
        private _after = [_before] call OTQA_smug_waitMoney;
        ["Smuggling: delivered, the deposit comes back", (_after - _before) >= _deposit && { (_after - _before) < _deposit + 500 }, format ["+%1", _after - _before]] call OTQA_fnc_check;
        ["Smuggling: delivered, +5 rep with the gang", (call OTQA_smug_rep) isEqualTo (_rep + 5), format ["%1 -> %2", _rep, call OTQA_smug_rep]] call OTQA_fnc_check;
        ["Smuggling: job and deposit cleared", !(_id in (missionNamespace getVariable ["OT_logisticsJobs", createHashMap])) && { ((server getVariable ["logisticsDeposits", []]) findIf { (_x select 2) isEqualTo _id }) isEqualTo -1 }, ""] call OTQA_fnc_check;
        ["Smuggling: settling it again does nothing", !([_contract, _uid, "lost"] call OT_fnc_logisticsSettle) && { (call OTQA_smug_rep) isEqualTo (_rep + 5) }, ""] call OTQA_fnc_check;
        [_crates] call OTQA_smug_cleanup;

        // Late, lost: the deposit is kept
        {
            private _result = _x;
            private _id = format ["qasmug%1", round (random 100000)];
            private _contract = [_id, 1, 1000, "smuggle", "drugs"] call OTQA_smug_contract;
            if ((player getVariable ["money", 0]) < 500) then { player setVariable ["money", 600, true] };
            [-500] call OT_fnc_money;
            ([_contract, player, false, false, "cash", objNull, 500] call OT_fnc_logisticsStart) params [["_crates", []]];
            sleep 0.5;
            private _before = player getVariable ["money", 0];
            private _rep = call OTQA_smug_rep;
            [_contract, _uid, _result] call OT_fnc_logisticsSettle;
            sleep 2;
            [format ["Smuggling: %1, the deposit is kept, -5 rep", _result], ((player getVariable ["money", 0]) - _before) < 100 && { (call OTQA_smug_rep) isEqualTo (_rep - 5) }
                && { ((server getVariable ["logisticsDeposits", []]) findIf { (_x select 2) isEqualTo _id }) isEqualTo -1 } && { !(_id in OT_logisticsJobs) },
                format ["money %1 -> %2, rep %3 -> %4", _before, player getVariable ["money", 0], _rep, call OTQA_smug_rep]] call OTQA_fnc_check;
            [_crates] call OTQA_smug_cleanup;
        } forEach ["late", "lost"];
        call OTQA_smug_gangDown;
    }, 60],

    ["Smuggling: an add-on on a legal job, reputation collateral", {
        if (isNil "OT_fnc_logisticsSettle") exitWith {};
        call OTQA_smug_gangUp;
        private _id = format ["qaaddon%1", round (random 100000)];
        private _contract = [_id, 2, 800, "", "", ["turtles", 2, 600]] call OTQA_smug_contract;
        ([_contract, player, false, true, "rep", objNull, 0] call OT_fnc_logisticsStart) params [["_crates", []]];
        ["Smuggling: add-on taken, 2 + 2 crates, only the add-on's tagged", (count _crates) isEqualTo 4 && { (_crates apply { _x getVariable ["OT_contraband", ""] }) isEqualTo ["", "", "turtles", "turtles"] },
            str (_crates apply { _x getVariable ["OT_contraband", ""] })] call OTQA_fnc_check;
        private _job = OT_logisticsJobs getOrDefault [_id, []];
        ["Smuggling: add-on job state (kind '', 2 add-on crates, 15 rep at stake, add-on pay)", (_job param [0, "x"]) isEqualTo "" && { (_job param [2, ""]) isEqualTo "rep" } && { (_job param [4, 0]) isEqualTo 2 } && { (_job param [8, 0]) isEqualTo 15 } && { (_job param [10, 0]) isEqualTo 600 }, str _job] call OTQA_fnc_check;
        private _rep = call OTQA_smug_rep;
        [_contract, getPlayerUID player, "hijacked"] call OT_fnc_logisticsSettle;
        ["Smuggling: failed with reputation collateral: -20 rep", (call OTQA_smug_rep) isEqualTo (_rep - 20), format ["%1 -> %2", _rep, call OTQA_smug_rep]] call OTQA_fnc_check;
        [_crates] call OTQA_smug_cleanup;

        // Declined: a plain legal job, nothing illegal kept
        private _id2 = format ["qaaddon%1", round (random 100000)];
        private _contract2 = [_id2, 2, 800, "", "", ["drugs", 1, 300]] call OTQA_smug_contract;
        ([_contract2, player, false, false, "", objNull, 0] call OT_fnc_logisticsStart) params [["_crates2", []]];
        ["Smuggling: add-on declined, a legal job (2 crates, none tagged, no job state)", (count _crates2) isEqualTo 2 && { (_crates2 findIf { (_x getVariable ["OT_contraband", ""]) isNotEqualTo "" }) isEqualTo -1 } && { !(_id2 in OT_logisticsJobs) },
            str (_crates2 apply { _x getVariable ["OT_contraband", ""] })] call OTQA_fnc_check;
        ["Smuggling: settling a legal job does nothing", !([_contract2, getPlayerUID player, "lost"] call OT_fnc_logisticsSettle), ""] call OTQA_fnc_check;
        [_crates2] call OTQA_smug_cleanup;
        call OTQA_smug_gangDown;
    }, 40],

    ["Smuggling: vehicle collateral impounded on failure, recovered for a fee", {
        if (isNil "OT_fnc_logisticsImpound") exitWith { ["Smuggling: OT_fnc_logisticsImpound exists", false, "missing"] call OTQA_fnc_check };
        call OTQA_smug_gangUp;
        private _uid = getPlayerUID player;
        private _pos = ((getPosATL player) getPos [15, (getDir player) + 90]) findEmptyPosition [0, 60, "C_Offroad_01_F"];
        private _car = createVehicle ["C_Offroad_01_F", _pos, [], 0, "NONE"];
        [_car, _uid] call OT_fnc_setOwner;
        _car addItemCargoGlobal ["FirstAidKit", 3];
        private _id = format ["qasmug%1", round (random 100000)];
        private _contract = [_id, 1, 1500, "smuggle", "drugs"] call OTQA_smug_contract;
        ([_contract, player, false, false, "vehicle", _car, 0] call OT_fnc_logisticsStart) params [["_crates", []]];
        ["Smuggling: the collateral vehicle is marked", (_car getVariable ["OT_collateral", ""]) isEqualTo _id && { ((OT_logisticsJobs getOrDefault [_id, []]) param [7, objNull]) isEqualTo _car }, ""] call OTQA_fnc_check;
        ["Smuggling: a collateral vehicle can't be stored in the garage", !([_car, player, player] call OT_fnc_garageStore) && { !isNull _car }, ""] call OTQA_fnc_check;
        private _rep = call OTQA_smug_rep;
        private _count = count (server getVariable ["logisticsImpound", []]);
        [_contract, _uid, "seized"] call OT_fnc_logisticsSettle;
        sleep 3;
        private _records = (server getVariable ["logisticsImpound", []]) select { (_x select 1) isEqualTo _uid && { (_x select 2) isEqualTo "C_Offroad_01_F" } };
        private _record = _records param [(count _records) - 1, []];
        ["Smuggling: failed, the vehicle is impounded (gone, listed with a fee of $500+)", isNull _car && { _record isNotEqualTo [] } && { (_record select 3) >= 500 },
            format ["car %1, impound %2 -> %3: %4", _car, _count, count (server getVariable ["logisticsImpound", []]), _record select [0, 4]]] call OTQA_fnc_check;
        ["Smuggling: failed with a vehicle up: -5 rep only", (call OTQA_smug_rep) isEqualTo (_rep - 5), format ["%1 -> %2", _rep, call OTQA_smug_rep]] call OTQA_fnc_check;
        [_crates] call OTQA_smug_cleanup;
        if (_record isEqualTo []) exitWith { call OTQA_smug_gangDown };

        // Recovered (at the player, standing in for a garage): paid, back, theirs, its cargo too
        _record params ["_impoundId", "", "", "_price"];
        player setVariable ["money", (player getVariable ["money", 0]) + _price, true];
        private _money = player getVariable ["money", 0];
        private _back = [_impoundId, player, player] call OT_fnc_logisticsImpoundRecover;
        private _after = [_money] call OTQA_smug_waitMoney;
        sleep 3;
        ["Smuggling: recovered from the impound lot, the player's again, fee paid, off the list",
            !isNull _back && { (_back getVariable ["owner", ""]) isEqualTo _uid } && { (_money - _after) >= _price - 50 } && { ((server getVariable ["logisticsImpound", []]) findIf { (_x select 0) isEqualTo _impoundId }) isEqualTo -1 },
            format ["%1, owner %2, paid %3 of %4", _back, if (isNull _back) then { "-" } else { _back getVariable ["owner", ""] }, _money - _after, _price]] call OTQA_fnc_check;
        ["Smuggling: its cargo came back", !isNull _back && { "FirstAidKit" in ((getItemCargo _back) select 0) }, if (isNull _back) then { "" } else { str getItemCargo _back }] call OTQA_fnc_check;
        deleteVehicle _back;
        call OTQA_smug_gangDown;
    }, 60],

    ["Smuggling: a search finding contraband blows cover, legal freight doesn't", {
        if (isNil "OT_fnc_logisticsSearchContraband") exitWith { ["Smuggling: OT_fnc_logisticsSearchContraband exists", false, "missing"] call OTQA_fnc_check };
        call OTQA_smug_gangUp;
        private _uid = getPlayerUID player;
        private _home = getPosATL player;

        // Legal freight in a rental
        private _idL = format ["qahaul%1", round (random 100000)];
        private _legal = [_idL, 2, 500, "", ""] call OTQA_smug_contract;
        ([_legal, player, true] call OT_fnc_logisticsStart) params [["_cratesL", []], ["_vehL", objNull]];
        player moveInDriver _vehL;
        sleep 1;
        player setCaptive true;
        ["Smuggling: searched with legal freight: nothing found, still undercover", !([player] call OT_fnc_logisticsSearchContraband) && { captive player }, ""] call OTQA_fnc_check;
        moveOut player;
        sleep 1;
        [_cratesL + [_vehL]] call OTQA_smug_cleanup;
        sleep 1;

        // Contraband in a rental
        private _id = format ["qasmug%1", round (random 100000)];
        private _contract = [_id, 2, 1500, "smuggle", "drugs"] call OTQA_smug_contract;
        ([_contract, player, true, false, "rep", objNull, 0] call OT_fnc_logisticsStart) params [["_crates", []], ["_veh", objNull]];
        player moveInDriver _veh;
        sleep 1;
        player setCaptive true;
        ["Smuggling: searched in a vehicle with contraband loaded: found, cover blown", ([player] call OT_fnc_logisticsSearchContraband) && { !captive player }, format ["captive %1", captive player]] call OTQA_fnc_check;
        ["Smuggling: the search doesn't take the crates", (_crates findIf { isNull _x || { !(_x in (_veh getVariable ["ace_cargo_loaded", []])) } }) isEqualTo -1, ""] call OTQA_fnc_check;

        // On foot next to the vehicle
        moveOut player;
        sleep 1;
        player setPosATL (_veh modelToWorld [4, 0, 0]);
        player setCaptive true;
        ["Smuggling: searched on foot by their vehicle with contraband: found", [player] call OT_fnc_logisticsSearchContraband, ""] call OTQA_fnc_check;

        [_contract, _uid, "lost"] call OT_fnc_logisticsSettle;
        [_crates + [_veh]] call OTQA_smug_cleanup;
        player setPosATL _home;
        player setCaptive true;
        call OTQA_smug_gangDown;
    }, 40],

    ["Smuggling: a deposit whose job is gone (a loaded game) is paid back", {
        if (isNil "OT_fnc_logisticsSettle") exitWith {};
        private _uid = getPlayerUID player;
        private _deposits = server getVariable ["logisticsDeposits", []];
        _deposits pushBack [_uid, 321, "qaGoneJob"];
        server setVariable ["logisticsDeposits", _deposits, true];
        private _money = player getVariable ["money", 0];
        [player] call OT_fnc_savePlayerData;
        ["Smuggling: paid back on the next player save, off the list", ((player getVariable ["money", 0]) - _money) isEqualTo 321 && { ((server getVariable ["logisticsDeposits", []]) findIf { (_x select 2) isEqualTo "qaGoneJob" }) isEqualTo -1 },
            format ["+%1", (player getVariable ["money", 0]) - _money]] call OTQA_fnc_check;
        ["Smuggling: the saved money includes it", (([_uid, "money", 0] call OT_fnc_getOfflinePlayerAttribute)) isEqualTo (player getVariable ["money", 0]), ""] call OTQA_fnc_check;
    }, 20]
]
