private _idx = lbCurSel 1500;
private _cls = lbData [1500, _idx];
private _cost = cost getVariable [_cls, []];
private _blueprints = server getVariable ["GEURblueprints", []];
if (_cost isNotEqualTo [] && !(_cls in _blueprints)) then {
    _blueprints pushBack _cls;
    server setVariable ["GEURblueprints", _blueprints, true];
    closeDialog 0;
    "Item is now available for production" call OT_fnc_notifyMinor;

    if (!(_cls isKindOf "Bag_Base") && _cls isKindOf "AllVehicles") then {
        private _veh = OT_factoryPos nearestObject _cls;
        deleteVehicle _veh;
    } else {
        // A weapon in the player's hands isn't removed by removeItem
        call {
            if ((primaryWeapon player) call BIS_fnc_baseWeapon == _cls) exitWith { player removeWeapon (primaryWeapon player) };
            if ((secondaryWeapon player) call BIS_fnc_baseWeapon == _cls) exitWith { player removeWeapon (secondaryWeapon player) };
            if ((handgunWeapon player) call BIS_fnc_baseWeapon == _cls) exitWith { player removeWeapon (handgunWeapon player) };
            player removeItem _cls;
        };
    };
} else {
    "Cannot reverse-engineer this item, please contact Overthrow Devs on Discord" call OT_fnc_notifyMinor;
};
