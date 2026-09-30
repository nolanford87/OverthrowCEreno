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
