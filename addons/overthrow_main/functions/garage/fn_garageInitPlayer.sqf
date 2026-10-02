/*
    Description:
    Sets up the virtual garage (HR Garage) for the local player: "Open Garage" and "Store vehicle"
    actions near owned warehouses and resistance bases, and the hooks that give Overthrow's data
    (cargo, owner, lock...) back to a vehicle taken out. Run for every player body (setupPlayer).

    Usage: call OT_fnc_garageInitPlayer;
*/

if (!hasInterface) exitWith {};

// Once per machine: HR Garage hooks, and the check for a garage nearby
if (isNil "OT_garageHooked") then {
    OT_garageHooked = true;
    OT_garageNear = objNull;
    OT_garageSelection = [-1, -1, ""];

    // Read by HR Garage while placing a vehicle, it doesn't define it itself
    if (isNil "HR_Garage_core_keys_battleMenu") then { HR_Garage_core_keys_battleMenu = false };

    // Our versions of HR Garage's hooks. Applied again whenever the garage opens, HR Garage resets
    // them if its server setup runs again (possible on a listen host)
    OT_garageApplyHooks = {
        // HR Garage closes the garage (and cancels placing) when the player "can't fight", which it takes
        // as captive, but in Overthrow being undercover is being captive. Close only when dead, unconscious
        // or too far from the garage
        HR_Garage_CP_closeCnd = {
            !alive player
            || { player getVariable ["ACE_isUnconscious", false] }
            || { !isNull HR_Garage_accessPoint && { (player distance HR_Garage_accessPoint) > 25 } }
        };

        // HR Garage clears the selection before the vehicle is placed, keep it
        HR_Garage_onCloseEvent = { OT_garageSelection = +HR_Garage_SelectedVehicles };
        // Called for the vehicle HR Garage created (and any statics loaded on it)
        HR_Garage_fnc_vehInit = {
            { _x addCuratorEditableObjects [[_this], false] } forEach allCurators;
            OT_garageSelection params ["", ["_vehUID", -1], ["_class", ""]];
            if (_vehUID isEqualType 0 && { _vehUID > -1 } && { (typeOf _this) isEqualTo _class }) then {
                [_this, _vehUID, player] remoteExecCall ["OT_fnc_garageRestore", 2];
                OT_garageSelection = [-1, -1, ""];
            };
        };
    };
    call OT_garageApplyHooks;

    [] spawn {
        while { true } do {
            OT_garageNear = player call OT_fnc_garageAccessPoint;
            sleep 2;
        };
    };
};

player addAction [
    "Open Garage",
    {
        call OT_garageApplyHooks;
        HR_Garage_accessPoint = OT_garageNear;
        HR_Garage_accessPoint setVariable ["HR_Garage_Garage_ModuleArguments", createHashMapFromArray [["accessAir", true], ["accessNaval", true], ["accessArmor", true]]];
        createDialog "HR_Garage_VehicleSelect";
    },
    nil, 1.4, false, true, "",
    "!isNull OT_garageNear && { isNull objectParent _this } && { isNil 'HR_Garage_Placing' || { !HR_Garage_Placing } }"
];

player addAction [
    "Store vehicle in garage",
    {
        [cursorObject, player] remoteExecCall ["OT_fnc_garageStore", 2];
    },
    nil, 1.3, false, true, "",
    "!isNull OT_garageNear && { isNull objectParent _this } && { (cursorObject isKindOf 'LandVehicle') || { cursorObject isKindOf 'Air' } || { cursorObject isKindOf 'Ship' } } && { !(cursorObject isKindOf 'StaticWeapon') } && { (_this distance cursorObject) < 10 } && { alive cursorObject } && { (cursorObject getVariable ['owner', '']) isEqualTo getPlayerUID _this || { call OT_fnc_playerIsGeneral } }"
];

// Vehicles the occupier impounded (smuggling collateral, OT_fnc_logisticsImpound): back for a fee
player addAction [
    "Impound lot",
    {
        params ["", "_caller"];
        private _mine = (server getVariable ["logisticsImpound", []]) select { (_x select 1) isEqualTo getPlayerUID _caller };
        private _options = [format ["<t align='center' size='1.2'>Impound lot</t><br/><br/><t align='center' size='0.8'>%1 kept these after failed smuggling jobs. Pay the fees and the vehicle is brought to this garage.</t>", OT_NATO_name]];
        {
            _x params ["_impoundId", "", "_class", "_price"];
            _options pushBack [
                format ["%1: $%2", _class call OT_fnc_vehicleGetName, [_price, 1, 0, true] call CBA_fnc_formatNumber],
                { [_this, player] remoteExecCall ["OT_fnc_logisticsImpoundRecover", 2] },
                _impoundId
            ];
        } forEach (_mine select [0, 5]);
        _options pushBack ["Cancel", {}];
        _options call OT_fnc_playerDecision;
    },
    nil, 1.2, false, true, "",
    "!isNull OT_garageNear && { isNull objectParent _this } && { ((server getVariable ['logisticsImpound', []]) findIf { (_x select 1) isEqualTo getPlayerUID _this }) > -1 }"
];
