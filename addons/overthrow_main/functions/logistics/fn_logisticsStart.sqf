/*
    Description:
    Starts a freight haul (server): a player accepted a broker's contract (OT logistics, part A).
    Spawns the job's wooden crates at the broker's loading spot, ACE-loadable (size 1 each) and tagged
    with the job id (OT_haul), and a rented box van or box truck next to them, the crates already
    loaded in it, if one was paid for (owned by the player, its ACE cargo space fits the crates, tagged OT_haulRental). Gives the
    player a task to the drop-off (pay and time limit in its text) and a pickup marker, then tracks
    the job until it ends (OT_fnc_logisticsTrack).

    Delivered: every crate that still exists is on the ground (not loaded in a vehicle, not carried)
    within 30 m of the drop-off. Late: -10% of the pay per full 5 minutes over the time limit, failed
    (no pay) at twice the time limit or when every crate is lost.

    Illegal work (OT_fnc_logisticsIllegalOffers): a smuggling contract's crates are all contraband, a
    taken add-on adds its crates to the load (same drop-off); contraband crates are tagged OT_contraband
    (drugs, weapons or turtles) for searches (OT_fnc_logisticsSearchContraband). The tracker gets the
    contract with the add-on in it (crates and pay). The job's illegal side is kept on the server in
    OT_logisticsJobs (job id: [kind, contraband, collateral, gang id, add-on crates, player UID, cash
    deposit, collateral vehicle, reputation at stake, contraband crates, add-on pay]) and a cash deposit
    also in the saved "logisticsDeposits" ([UID, $, job id]); settled when the job ends
    (OT_fnc_logisticsSettle).

    Parameters:
        _this # 0: ARRAY - Contract [id, fromPos, fromName, toPos, toName, crates, size, pay, timeLimit, danger, brokerId,
            kind, contraband, add-on, gang id] (the last 4 optional)
        _this # 1: OBJECT - Player who accepted it
        _this # 2: BOOL - A rental vehicle was paid for (default: false)
        _this # 3: BOOL - The contraband add-on was taken (default: false)
        _this # 4: STRING - Collateral for illegal work: "cash", "vehicle", "rep" (default: "")
        _this # 5: OBJECT - Vehicle put up as collateral (default: objNull)
        _this # 6: NUMBER - Cash deposit taken ($) (default: 0)

    Usage: [_contract, player, _rental, _addon, _collateral, _collVeh, _deposit] remoteExec ["OT_fnc_logisticsStart", 2];

    Returns: ARRAY - [crates, rental vehicle (objNull if none), task id], [] if not started
*/

params ["_contract", "_player", ["_rental", false], ["_addon", false], ["_collateral", ""], ["_collVeh", objNull], ["_deposit", 0]];

if (!isServer || { isNull _player }) exitWith { [] };
_contract params ["_id", "_fromPos", "_fromName", "_toPos", "_toName", "_count", "_size", "_pay", "_timeLimit"];
// The same contract twice (a double click): one job only
if ((_player getVariable ["OT_logisticsActive", ""]) isEqualTo _id) exitWith { [] };

_fromPos = [_fromPos select 0, _fromPos select 1, 0];
// Illegal: the whole load (smuggling) or the add-on's crates on top
private _kind = _contract param [11, ""];
private _offer = _contract param [13, []];
private _gangId = _contract param [14, ""];
private _contraband = "";
private _addonCrates = 0;
private _extraPay = 0;
if (_kind isEqualTo "smuggle") then { _contraband = _contract param [12, ""] };
if (_kind isNotEqualTo "smuggle" && { _addon } && { _offer isNotEqualTo [] }) then {
    _offer params ["_addonContraband", "_addonCount", "_extra"];
    _contraband = _addonContraband;
    _addonCrates = _addonCount;
    _extraPay = _extra;
};
private _illegal = _contraband isNotEqualTo "";
private _legalCount = _count;
if (_illegal && { _addonCrates > 0 }) then {
    _count = _count + _addonCrates;
    _pay = _pay + _extraPay;
    // The tracker counts and pays the whole load
    _contract = +_contract;
    _contract set [5, _count];
    _contract set [7, _pay];
};

// Crates and rentals line up on the road in front of the broker's shed (its direction, OT_fnc_logisticsBrokers)
private _brokerId = _contract param [10, ""];
private _roadDir = ((server getVariable ["logisticsBrokers", []]) select { (_x select 0) isEqualTo _brokerId }) param [0, []] param [6, -1];

// Crates: wooden crates, the support box on a game without them (it's emptied)
private _crateClass = ["Box_NATO_Support_F", "Land_WoodenCrate_01_F"] select (isClass (configFile >> "CfgVehicles" >> "Land_WoodenCrate_01_F"));
private _crates = [];
for "_i" from 1 to _count do {
    private _pos = [];
    if (_roadDir >= 0) then {
        // In a row along the road, from the loading spot on
        _pos = _fromPos getPos [(_i - 1) * 2, _roadDir];
    } else {
        // Spread around the loading spot so they don't collide
        private _near = _fromPos getPos [2 + (_i * 1.5), _i * 47];
        _pos = _near findEmptyPosition [0, 25, _crateClass];
        if (_pos isEqualTo [] || { surfaceIsWater _pos }) then { _pos = _fromPos getPos [random 6, random 360] };
    };
    private _crate = createVehicle [_crateClass, _pos, [], 0, "CAN_COLLIDE"];
    _crate setPosATL [_pos select 0, _pos select 1, 0];
    _crate allowDamage false; // No cargo damage (only losing the vehicle loses the load); wooden crates break easily
    clearWeaponCargoGlobal _crate;
    clearMagazineCargoGlobal _crate;
    clearItemCargoGlobal _crate;
    clearBackpackCargoGlobal _crate;
    // setSize also adds the ACE "Load" action on every machine
    [_crate, 1] call ace_cargo_fnc_setSize;
    _crate setVariable ["ace_cargo_canLoad", true, true];
    if (!isNil "ace_dragging_fnc_setDraggable") then { [_crate, true] call ace_dragging_fnc_setDraggable };
    _crate setVariable ["OT_haul", _id, true];
    // Contraband: all of a smuggling load, the add-on's crates (the last ones) otherwise
    if (_illegal && { _kind isEqualTo "smuggle" || { _i > _legalCount } }) then { _crate setVariable ["OT_contraband", _contraband, true] };
    _crates pushBack _crate;
};

// Rental: a box van or box truck, the player's for the job
private _veh = objNull;
if (_rental) then {
    private _vehClass = ["C_Van_01_box_F", "C_Truck_02_box_F"] select (_size isEqualTo "truck");
    private _pos = [];
    if (_roadDir >= 0) then {
        // On the road behind the crates, facing along it
        _pos = _fromPos getPos [-9, _roadDir];
    } else {
        _pos = (_fromPos getPos [12, random 360]) findEmptyPosition [0, 60, _vehClass];
        if (_pos isEqualTo []) then { _pos = _fromPos findEmptyPosition [5, 100, _vehClass] };
        if (_pos isEqualTo []) then { _pos = _fromPos getPos [15, random 360] };
    };
    _veh = createVehicle [_vehClass, _pos, [], 0, ["NONE", "CAN_COLLIDE"] select (_roadDir >= 0)];
    if (_roadDir >= 0) then { _veh setDir _roadDir };
    [_veh, getPlayerUID _player] call OT_fnc_setOwner;
    clearWeaponCargoGlobal _veh;
    clearMagazineCargoGlobal _veh;
    clearItemCargoGlobal _veh;
    clearBackpackCargoGlobal _veh;
    // Room for every crate (and a little more), whatever ACE gives the class
    private _need = 0;
    { _need = _need + (_x getVariable ["ace_cargo_size", 1]) } forEach _crates;
    [_veh, (_need + 2) max (_veh getVariable ["ace_cargo_space", 0])] call ace_cargo_fnc_setSpace;
    _veh setVariable ["OT_haulRental", _id, true];
    // The crates come loaded; if ACE turns any away, more room and again
    { [_x, _veh, true] call ace_cargo_fnc_loadItem } forEach _crates;
    private _out = _crates select { !(_x in (_veh getVariable ["ace_cargo_loaded", []])) };
    if (_out isNotEqualTo []) then {
        diag_log format ["Overthrow: freight rental %1 took %2 of %3 crates (space %4), making room", typeOf _veh, (count _crates) - (count _out), count _crates, _veh getVariable ["ace_cargo_space", 0]];
        [_veh, (_veh getVariable ["ace_cargo_space", 0]) + (count _out) * 2 + _need] call ace_cargo_fnc_setSpace;
        { [_x, _veh, true] call ace_cargo_fnc_loadItem } forEach _out;
    };
};

_player setVariable ["OT_logisticsActive", _id, true];

// The illegal side of the job, for settling it (OT_fnc_logisticsSettle), the tracker and hijackers
if (_illegal) then {
    if (isNil "OT_logisticsJobs") then { OT_logisticsJobs = createHashMap };
    if (_collateral isEqualTo "vehicle" && { !isNull _collVeh }) then { _collVeh setVariable ["OT_collateral", _id, true] };
    private _contrabandCrates = _crates select { (_x getVariable ["OT_contraband", ""]) isNotEqualTo "" };
    // Job and deposit together: a deposit without its job is paid back (OT_fnc_savePlayerData)
    isNil {
        OT_logisticsJobs set [_id, [
            _kind, _contraband, _collateral, _gangId, _addonCrates, getPlayerUID _player, _deposit,
            [objNull, _collVeh] select (_collateral isEqualTo "vehicle"), [0, 15] select (_collateral isEqualTo "rep"),
            _contrabandCrates, _extraPay
        ]];
        if (_deposit > 0) then {
            private _deposits = server getVariable ["logisticsDeposits", []];
            _deposits pushBack [getPlayerUID _player, _deposit, _id];
            server setVariable ["logisticsDeposits", _deposits, true];
        };
    };
};
// "Unload delivery cargo" at the drop-off
[_id, _toPos] remoteExec ["OT_fnc_logisticsUnloadAction", _player];

// Pickup marker (removed once the crates are loaded) and the task to the drop-off
private _marker = createMarker [format ["OT_haulPickup_%1", _id], _fromPos];
_marker setMarkerTypeLocal "mil_pickup";
_marker setMarkerColorLocal "ColorCivilian";
_marker setMarkerText format ["Freight pickup: %1 crates", _count];

private _illegalText = "";
if (_illegal) then {
    private _gangName = (OT_civilians getVariable [format ["gang%1", _gangId], []]) param [8, "a gang"];
    private _what = createHashMapFromArray [["drugs", "drugs"], ["weapons", "weapons and ammo"], ["turtles", "turtles and poached goods"]] getOrDefault [_contraband, "contraband"];
    private _stake = "your reputation with them (-15)";
    if (_collateral isEqualTo "cash") then { _stake = format ["a $%1 deposit, paid back on delivery", _deposit] };
    if (_collateral isEqualTo "vehicle") then { _stake = format ["your %1, impounded by %2 if the job fails", (typeOf _collVeh) call OT_fnc_vehicleGetName, OT_NATO_name] };
    _illegalText = format [
        "<br/><br/><font color='#ff8080'>Illegal, for %1:</font> %2 of the crates hold %3. If a search finds them your cover is blown; if you are killed while wanted they are seized. Collateral: %4. A failed job also costs 5 reputation with %1.",
        _gangName, [format ["%1", _addonCrates], "all"] select (_kind isEqualTo "smuggle"), _what, _stake
    ];
};
private _taskId = format ["OT_haul_%1", _id];
private _minutes = round (_timeLimit / 60);
[
    _player, _taskId,
    [
        format [
            "Haul %1 crates from %2 to %3.<br/><br/>Load them into a vehicle at the pickup marker (ACE: Load into vehicle), drive them to %3 and unload them there (Unload delivery cargo, by the vehicle): delivered when every crate is on the ground within 30 m of the drop-off.<br/><br/>Pay: $%4. Time limit: %5 minutes, then -10%6 of the pay per 5 minutes late; nothing after %7 minutes.%8",
            _count, _fromName, _toName, [_pay, 1, 0, true] call CBA_fnc_formatNumber, _minutes, "%", _minutes * 2,
            ["", "<br/><br/>A rented vehicle is parked at the pickup with the crates already loaded."] select _rental
        ] + _illegalText,
        format ["Haul %1 crates to %2", _count, _toName],
        _taskId
    ],
    _toPos, "ASSIGNED", 1, true, "truck", true
] call BIS_fnc_taskCreate;

format ["Freight: %1 crates waiting at %2 for %3, %4 minutes", _count, _fromName, _toName, _minutes] remoteExec ["OT_fnc_notifyMinor", _player, false];

[_contract, getPlayerUID _player, _crates, _veh, _taskId, _marker, time] spawn OT_fnc_logisticsTrack;

[_crates, _veh, _taskId]
