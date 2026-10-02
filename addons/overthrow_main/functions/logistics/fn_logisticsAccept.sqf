/*
    Description:
    Accepting a freight contract from a broker's board (OT_fnc_logisticsMenu), one step at a time, each
    step calling this again with the choice made:
    1. A legal contract with a contraband add-on: take the add-on (illegal) or legal freight only.
    2. Illegal work (a smuggling contract, or the add-on taken): the gang's collateral. A cash deposit of
       half the illegal pay (taken now, back on delivery), a vehicle you own within 60 m (impounded by
       the occupier if the job fails, OT_fnc_logisticsImpound) or your reputation with the gang (-15
       more if it fails). A failed illegal job always costs 5 reputation with the gang as well. A gang
       that hates you (reputation below -9) won't deal with you.
    3. Your own vehicle or the broker's rental (van $150 for up to 2 crates, truck $400 for more), then
       the server takes the contract (OT_fnc_logisticsClaim). Rental fee and deposit are taken here,
       paid back if the contract is gone.

    Parameters:
        _this # 0: ARRAY - Contract (OT_fnc_logisticsOffers, OT_fnc_logisticsIllegalOffers)
        _this # 1: NUMBER - Add-on: -1 not chosen yet, 0 declined, 1 taken (default: -1)
        _this # 2: STRING - Collateral: "" not chosen yet, "cash", "vehicle" or "rep" (default: "")
        _this # 3: OBJECT - The vehicle put up as collateral (default: objNull)
        _this # 4: NUMBER - Rental: -1 not chosen yet, 0 own vehicle, 1 rental (default: -1)

    Usage: [_contract] call OT_fnc_logisticsAccept; (client)
*/

params ["_contract", ["_addon", -1], ["_collateral", ""], ["_collVeh", objNull], ["_rental", -1]];

private _kind = _contract param [11, ""];
private _offer = _contract param [13, []];
private _gangId = _contract param [14, ""];
private _gangName = "The gang";
if (_gangId isEqualType 0) then { _gangName = (OT_civilians getVariable [format ["gang%1", _gangId], []]) param [8, "The gang"] };
private _names = createHashMapFromArray [["drugs", "drugs"], ["weapons", "weapons and ammo"], ["turtles", "turtles and other poached goods"]];
private _crates = _contract select 5;

// 1. The add-on
if (_offer isNotEqualTo [] && { _kind isEqualTo "" } && { _addon < 0 }) exitWith {
    _offer params ["_contraband", "_addonCrates", "_extra"];
    [
        format [
            "<t align='center' size='1.2'>An extra for %1</t><br/><br/><t align='center' size='0.8'>%1 will pay $%2 on top to hide %3 crate%4 of %5 in this load, for the same drop-off.<br/><br/><t color='#ff8080'>Illegal:</t> a search that finds it blows your cover, and if you are killed while wanted it is seized. A failed job costs reputation with %1 and the collateral you put up.</t>",
            _gangName, _extra, _addonCrates, ["", "s"] select (_addonCrates > 1), _names getOrDefault [_contraband, "contraband"]
        ],
        [format ["Take the extra crates (illegal, +$%1)", _extra], OT_fnc_logisticsAccept, [_contract, 1]],
        ["Legal freight only", OT_fnc_logisticsAccept, [_contract, 0]],
        ["Cancel", {}]
    ] call OT_fnc_playerDecision;
};

private _illegal = _kind isEqualTo "smuggle" || { _addon isEqualTo 1 && { _offer isNotEqualTo [] } };
private _illegalPay = [0, _contract select 7] select (_kind isEqualTo "smuggle");
if (_kind isNotEqualTo "smuggle" && { _illegal }) then {
    _illegalPay = _offer select 2;
    _crates = _crates + (_offer select 1);
};
private _deposit = [0, round (_illegalPay * 0.5)] select _illegal;

// 2. Collateral
if (_illegal && { _collateral isEqualTo "" }) exitWith {
    if ((player getVariable [format ["gangrep%1", _gangId], 0]) < -9) exitWith {
        format ["%1 won't work with you", _gangName] call OT_fnc_notifyMinor;
    };
    private _uid = getPlayerUID player;
    private _vehicles = (player nearEntities [["LandVehicle", "Air", "Ship"], 60]) select {
        alive _x
        && { !(_x isKindOf "StaticWeapon") }
        && { (_x getVariable ["owner", ""]) isEqualTo _uid }
        && { (_x getVariable ["OT_haulRental", ""]) isEqualTo "" }
        && { (_x getVariable ["OT_collateral", ""]) isEqualTo "" }
    };
    _vehicles = [_vehicles, [], { _x distance player }, "ASCEND"] call BIS_fnc_sortBy;
    private _danger = round ((_contract param [9, 0]) * 200); // 0-0.5 as 0-100%
    private _options = [
        format [
            "<t align='center' size='1.2'>Collateral for %1</t><br/><br/><t align='center' size='0.8'><t color='#ff8080'>Illegal work</t> for %1: $%2 for the contraband. Risk: %3%6 of the towns on the route are held by %4 or unstable; checkpoints and patrols search you.<br/>If the job fails you lose the collateral and 5 reputation with %1.%5</t>",
            _gangName, _illegalPay, _danger, OT_NATO_name,
            ["<br/>(Bring a vehicle you own within 60 m to put it up.)", ""] select (_vehicles isNotEqualTo []), "%"
        ],
        [format ["Cash deposit: $%1, back on delivery", _deposit], OT_fnc_logisticsAccept, [_contract, _addon, "cash"]]
    ];
    {
        _options pushBack [
            format ["Your %1 (impounded if it fails)", (typeOf _x) call OT_fnc_vehicleGetName],
            OT_fnc_logisticsAccept, [_contract, _addon, "vehicle", _x]
        ];
    } forEach (_vehicles select [0, 2]);
    _options pushBack [format ["Your reputation with %1 (-15 if it fails)", _gangName], OT_fnc_logisticsAccept, [_contract, _addon, "rep"]];
    _options pushBack ["Cancel", {}];
    _options call OT_fnc_playerDecision;
};

// 3. Own vehicle or rental
private _fee = [400, 150] select ((_contract select 6) isEqualTo "van");
if (_rental < 0) exitWith {
    private _vehicle = ["truck", "van"] select ((_contract select 6) isEqualTo "van");
    private _pay = (_contract select 7) + ([0, _illegalPay] select (_illegal && { _kind isNotEqualTo "smuggle" }));
    private _extra = "";
    if (_illegal) then {
        private _what = "your reputation";
        if (_collateral isEqualTo "cash") then { _what = format ["$%1 deposit", _deposit] };
        if (_collateral isEqualTo "vehicle") then { _what = format ["your %1", (typeOf _collVeh) call OT_fnc_vehicleGetName] };
        _extra = format ["<br/><t color='#ff8080'>Illegal, for %1.</t> Collateral: %2", _gangName, _what];
    };
    [
        format ["<t align='center' size='1.2'>%1 crate%2 to %3</t><br/><br/><t align='center' size='0.8'>$%4 on delivery, %5 minutes%6", _crates, ["", "s"] select (_crates > 1), _contract select 4, _pay, ceil ((_contract select 8) / 60), _extra],
        ["Use your own vehicle", OT_fnc_logisticsAccept, [_contract, _addon, _collateral, _collVeh, 0]],
        [format ["Rent a %1 ($%2)", _vehicle, _fee], OT_fnc_logisticsAccept, [_contract, _addon, _collateral, _collVeh, 1]],
        ["Cancel", {}]
    ] call OT_fnc_playerDecision;
};

// Accepted: pay what's due now and ask the server for the contract
if ((player getVariable ["OT_logisticsActive", ""]) isNotEqualTo "") exitWith {
    "Finish your current freight contract first" call OT_fnc_notifyMinor;
};
if (_collateral isEqualTo "vehicle" && { isNull _collVeh || { !alive _collVeh } }) exitWith {
    "That vehicle can't be put up any more" call OT_fnc_notifyMinor;
};
private _isRental = _rental isEqualTo 1;
private _cash = [0, _deposit] select (_collateral isEqualTo "cash");
private _due = ([0, _fee] select _isRental) + _cash;
if ((player getVariable ["money", 0]) < _due) exitWith {
    format ["You need $%1 for that", _due] call OT_fnc_notifyMinor;
};
if (_due > 0) then { [-_due] call OT_fnc_money };
[
    _contract select 10, _contract select 0, player, _isRental, [0, _fee] select _isRental,
    _addon isEqualTo 1, _collateral, _collVeh, _cash
] remoteExec ["OT_fnc_logisticsClaim", 2];
