/*
    Description:
    Virtual garage (HR Garage + Overthrow's cargo/ownership layer). Part of the review and DLC
    QA tests (OTQA_fnc_testsFollowups).

    Returns: ARRAY - [[name, code], ...]
*/

"Garage: while undercover, open the garage and take a vehicle out: the garage stays open and placing works" call OTQA_fnc_manual;
"Garage: at an owned warehouse or base flag, store a damaged, half-fuelled vehicle with cargo, take it out: same damage, fuel, ammo, cargo, ACE cargo and lock" call OTQA_fnc_manual;
"Garage: a vehicle with a workshop weapon comes back with the weapon attached" call OTQA_fnc_manual;
"Garage: save, restart and load: stored vehicles are still in the garage" call OTQA_fnc_manual;

// Cargo as a sorted list of text, to compare two containers
OTQA_garage_cargoText = {
    params ["_cargo"];
    _cargo params ["_items", "_weapons", "_magazines", "_backpacks", "_containers"];
    private _list = [];
    { _list pushBack format ["item %1 x%2", _x, (_items select 1) select _forEachIndex] } forEach (_items select 0);
    { _list pushBack format ["weapon %1", _x] } forEach _weapons;
    { _list pushBack format ["mag %1", _x] } forEach _magazines;
    { _list pushBack format ["pack %1 x%2", _x, (_backpacks select 1) select _forEachIndex] } forEach (_backpacks select 0);
    { _list pushBack format ["in %1: %2", _x select 0, [_x select 1] call OTQA_garage_cargoText] } forEach _containers;
    _list sort true;
    _list;
};

OTQA_garage_fill = {
    params ["_box"];
    clearItemCargoGlobal _box;
    clearWeaponCargoGlobal _box;
    clearMagazineCargoGlobal _box;
    clearBackpackCargoGlobal _box;
    _box addWeaponWithAttachmentsCargoGlobal [["arifle_MX_F", "muzzle_snds_H", "acc_pointer_IR", "optic_Hamr", ["30Rnd_65x39_caseless_mag", 17], [], ""], 1];
    _box addMagazineAmmoCargo ["30Rnd_65x39_caseless_mag", 1, 9];
    _box addItemCargoGlobal ["FirstAidKit", 3];
    _box addBackpackCargoGlobal ["B_AssaultPack_rgr", 1];
    private _pack = (everyBackpack _box) select 0;
    clearItemCargoGlobal _pack;
    clearMagazineCargoGlobal _pack;
    _pack addItemCargoGlobal ["ToolKit", 1];
    _pack addMagazineAmmoCargo ["30Rnd_65x39_caseless_mag", 1, 4];
};

[
    ["Garage cargo round trip", {
        private _pos = player getPos [6, getDir player];
        private _a = createVehicle ["Box_NATO_Ammo_F", _pos, [], 0, "CAN_COLLIDE"];
        private _b = createVehicle ["Box_NATO_Ammo_F", _pos getPos [3, 90], [], 0, "CAN_COLLIDE"];
        [_a] call OTQA_garage_fill;
        private _cargo = _a call OT_fnc_getCargo;
        [_b, _cargo] call OT_fnc_setCargo;
        private _before = [_cargo] call OTQA_garage_cargoText;
        private _after = [_b call OT_fnc_getCargo] call OTQA_garage_cargoText;
        ["Cargo is copied exactly (attachments, partial magazines, backpack contents)", _before isEqualTo _after, format ["%1 / %2", _before, _after]] call OTQA_fnc_check;
        deleteVehicle _a;
        deleteVehicle _b;
    }],

    ["Garage store and restore", {
        if (isNil "HR_Garage_fnc_addVehicle") exitWith { "Garage test skipped: HR Garage isn't loaded" call OTQA_fnc_manual };
        // A resistance base flag next to the player is a garage
        private _flag = createVehicle [OT_flag_IND, player getPos [8, (getDir player) + 180], [], 0, "CAN_COLLIDE"];
        private _cls = "C_Offroad_01_F";
        private _pos = (player getPos [12, getDir player]) findEmptyPosition [0, 60, _cls];
        if (_pos isEqualTo []) exitWith { deleteVehicle _flag; "Garage test skipped: no room for a vehicle near you" call OTQA_fnc_manual };
        private _veh = createVehicle [_cls, _pos, [], 0, "NONE"];
        [_veh, getPlayerUID player] call OT_fnc_setOwner;
        _veh setVariable ["OT_locked", true, true];
        _veh setVariable ["name", "OTQA garage test", true];
        [_veh] call OTQA_garage_fill;
        private _cargoBefore = [_veh call OT_fnc_getCargo] call OTQA_garage_cargoText;
        _veh setFuel 0.4;

        [_veh, player] call OT_fnc_garageStore;
        sleep 0.5; // Deleting the vehicle takes a frame
        private _vehUID = HR_Garage_UID;
        private _cat = [_cls] call HR_Garage_fnc_getCatIndex;
        private _entry = (HR_Garage_Vehicles select _cat) getOrDefault [_vehUID, []];
        ["Vehicle goes into the garage", isNull _veh && { _entry isNotEqualTo [] }, format ["id %1, entry %2", _vehUID, _entry param [1, "none"]]] call OTQA_fnc_check;
        ["Locked vehicle is locked to its owner in the garage", (_entry param [2, ""]) isEqualTo getPlayerUID player, ""] call OTQA_fnc_check;
        private _extra = OT_garageExtra getOrDefault [_vehUID, []];
        ["Overthrow's data is kept for it", _extra isNotEqualTo [], ""] call OTQA_fnc_check;

        // Taking it out: HR Garage creates the vehicle on the player's machine, then Overthrow restores the rest
        private _out = createVehicle [_cls, _pos, [], 0, "NONE"];
        [_out, _vehUID, player] call OT_fnc_garageRestore;
        ["Owner comes back", (_out call OT_fnc_getOwner) isEqualTo getPlayerUID player, ""] call OTQA_fnc_check;
        ["Lock and name come back", (_out getVariable ["OT_locked", false]) && { (_out getVariable ["name", ""]) isEqualTo "OTQA garage test" }, ""] call OTQA_fnc_check;
        private _cargoAfter = [_out call OT_fnc_getCargo] call OTQA_garage_cargoText;
        ["Cargo comes back exactly", _cargoBefore isEqualTo _cargoAfter, format ["%1 / %2", _cargoBefore, _cargoAfter]] call OTQA_fnc_check;
        ["Its data is used up", !(_vehUID in OT_garageExtra), ""] call OTQA_fnc_check;

        // Clean up: take it out of the garage pool again
        (HR_Garage_Vehicles select _cat) deleteAt _vehUID;
        deleteVehicle _out;
        deleteVehicle _flag;
    }],

    ["Garage stays open while undercover", {
        if (isNil "HR_Garage_CP_closeCnd") exitWith { "Garage undercover test skipped: HR Garage isn't loaded" call OTQA_fnc_manual };
        call OT_garageApplyHooks;
        private _flag = createVehicle [OT_flag_IND, player getPos [8, (getDir player) + 180], [], 0, "CAN_COLLIDE"];
        private _wasCaptive = captive player;
        private _was = HR_Garage_accessPoint;
        HR_Garage_accessPoint = _flag;
        player setCaptive true;
        ["Undercover (captive) doesn't close the garage", !(call HR_Garage_CP_closeCnd), ""] call OTQA_fnc_check;
        player setCaptive _wasCaptive;
        HR_Garage_accessPoint = _was;
        deleteVehicle _flag;
    }]
]
