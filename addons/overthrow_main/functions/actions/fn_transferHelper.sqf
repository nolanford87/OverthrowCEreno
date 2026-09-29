_this spawn {
    params ["_source", "_dest"];

    private _supplycache = _source getVariable ["NATOsupply", false];
    if (_supplycache isEqualType "") then {
        private _me = driver _dest;
        if (_me call OT_fnc_unitSeenNATO) then {
            _me setCaptive false;
            [_me] call OT_fnc_revealToNATO;
        };
        //Make sure box doesnt spawn at this base again (this session)
        spawner setVariable [format ["NATOsupply%1", _supplycache], false, true];
    };

    private _veh = _dest;
    private _toname = (typeOf _veh) call OT_fnc_vehicleGetName;
    private _iswarehouse = false;
    if ((typeOf _veh) == OT_warehouse) then {
        _toname = "Warehouse";
        _iswarehouse = true;
    };

    private _target = _source;
    if (_target isEqualTo player) then {
        _target = OT_warehouseTarget;
    };

    disableUserInput true;
    [] spawn {
        sleep 10;
        disableUserInput false;
        //Fail safe for user input disabled.
    };
    format ["Transferring inventory to %1...", _toname] call OT_fnc_notifyMinor;
    [5, false] call OT_fnc_progressBar;
    private _end = time + 5;

    // Dummy CBA remove calls to strip weapons and replace with non-preset types
    [_target, "Bag_Base"] call CBA_fnc_removeBackpackCargo;
    [_target, "FakeWeapon"] call CBA_fnc_removeWeaponCargo;

    // Strip out preloaded missile dummies from inventory.
    // Only way to really clear them is a full magazine clear.
    // Keep the ammo count of each magazine, so partially used magazines aren't refilled.
    private _mags = (magazinesAmmoCargo _target) select { !((_x select 0) in OT_noCopyMags) };
    clearMagazineCargoGlobal _target;
    {
        _x params ["_cls", "_ammo"];
        _target addMagazineAmmoCargo [_cls, 1, _ammo];
    } forEach (_mags);

    if (_iswarehouse) then {
        private _warehouse = [player] call OT_fnc_nearestWarehouse;
        if (_warehouse == objNull) exitWith { hint "No warehouse near by!" };
        {
            _x params ["_cls", "_num"];
            private _d = _warehouse getVariable [format ["item_%1", _cls], [_cls, 0]];
            if (_d isEqualType []) then {
                private _in = _d select 1;
                _warehouse setVariable [format ["item_%1", _cls], [_cls, _in + _num], true];
            };
        } forEach (_target call OT_fnc_unitStock);
        clearMagazineCargoGlobal _target;
        clearWeaponCargoGlobal _target;
        clearBackpackCargoGlobal _target;
        clearItemCargoGlobal _target;
    } else {
        // Move magazines one by one with their ammo count, adding them by class would refill them.
        // Only the top level cargo, magazines inside backpacks etc. are still moved below
        private _canTakeAll = (_veh isKindOf "Truck_F" || _veh isKindOf "ReammoBox_F");
        private _mags = magazinesAmmoCargo _target;
        private _leftBehind = false;
        if (_mags isNotEqualTo []) then {
            clearMagazineCargoGlobal _target;
            {
                _x params ["_cls", "_ammo"];
                if (_canTakeAll || { _veh canAdd [_cls, 1] }) then {
                    _veh addMagazineAmmoCargo [_cls, 1, _ammo];
                } else {
                    _target addMagazineAmmoCargo [_cls, 1, _ammo];
                    _leftBehind = true;
                };
            } forEach _mags;
        };
        if (_leftBehind) then { hint "The vehicle is full, use a truck or ammobox for more storage" };

        {
            _x params [["_cls", ""], ["_max", 0]];
            private _count = 0;
            private _full = false;
            private _istruck = (_veh isKindOf "Truck_F" || _veh isKindOf "ReammoBox_F");

            while { _count < _max } do {
                if (!(_veh canAdd [_cls, 1]) && !_istruck) exitWith { _full = true };
                _count = _count + 1;
                call {
                    if (_cls isKindOf "Bag_Base") exitWith {
                        _cls = _cls call BIS_fnc_basicBackpack;
                        _veh addBackpackCargoGlobal [_cls, 1];
                    };
                    if (_cls isKindOf ["Rifle", configFile >> "CfgWeapons"]) exitWith {
                        _veh addWeaponCargoGlobal [_cls, 1];
                    };
                    if (_cls isKindOf ["Launcher", configFile >> "CfgWeapons"]) exitWith {
                        _veh addWeaponCargoGlobal [_cls, 1];
                    };
                    if (_cls isKindOf ["Pistol", configFile >> "CfgWeapons"]) exitWith {
                        _veh addWeaponCargoGlobal [_cls, 1];
                    };
                    if (_cls isKindOf ["Default", configFile >> "CfgMagazines"]) exitWith {
                        _veh addMagazineCargoGlobal [_cls, 1];
                    };
                    _veh addItemCargoGlobal [_cls, 1];
                };
            };
            call {
                //NVGoggles are also "Binocular" so check first
                if (_cls isKindOf ["NVGoggles", configFile >> "CfgWeapons"]) exitWith {
                    [_target, _cls, _count] call CBA_fnc_removeItemCargo;
                };
                //removeMagazineCargo does not work on Binocular so add check for binocular
                if (_cls isKindOf ["Binocular", configFile >> "CfgWeapons"]) exitWith {
                    [_target, _cls, _count] call CBA_fnc_removeWeaponCargo;
                };
                if (_cls isKindOf "Bag_Base") exitWith {
                    [_target, _cls, _count] call CBA_fnc_removeBackpackCargo;
                };
                if (_cls isKindOf ["Rifle", configFile >> "CfgWeapons"]) exitWith {
                    [_target, _cls, _count] call CBA_fnc_removeWeaponCargo;
                };
                if (_cls isKindOf ["Launcher", configFile >> "CfgWeapons"]) exitWith {
                    [_target, _cls, _count] call CBA_fnc_removeWeaponCargo;
                };
                if (_cls isKindOf ["Pistol", configFile >> "CfgWeapons"]) exitWith {
                    [_target, _cls, _count] call CBA_fnc_removeWeaponCargo;
                };
                if (_cls isKindOf ["Default", configFile >> "CfgMagazines"]) exitWith {
                    [_target, _cls, _count] call CBA_fnc_removeMagazineCargo;
                };
                [_target, _cls, _count] call CBA_fnc_removeItemCargo;
            };
            if (_full) exitWith { hint "The vehicle is full, use a truck or ammobox for more storage" };
        } forEach (_target call OT_fnc_unitStock);
    };

    waitUntil { time > _end };
    disableUserInput false;
    "Inventory Transfer done" call OT_fnc_notifyMinor;
};
