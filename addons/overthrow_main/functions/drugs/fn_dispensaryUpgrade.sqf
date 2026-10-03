/*
    Description:
    Opens a dispensary's back room (level 2, OT_dispensaryUpgradeCost from resistance funds, generals
    only): from the next cycle it also sells blow from its stock (OT_fnc_dispensaryCycle).

    Parameters:
        _this # 0: STRING - Dispensary (business name)

    Usage: [_name] call OT_fnc_dispensaryUpgrade;

    Returns: BOOL - Upgraded
*/

params ["_name"];

if !(call OT_fnc_playerIsGeneral) exitWith { "Only a general can do that" call OT_fnc_notifyMinor; false };
if !(_name in (server getVariable ["GEURowned", []])) exitWith { "The resistance doesn't own this dispensary" call OT_fnc_notifyMinor; false };
if ((_name call OT_fnc_dispensaryLevel) >= 2) exitWith { "The back room is already open" call OT_fnc_notifyMinor; false };
if (([] call OT_fnc_resistanceFunds) < OT_dispensaryUpgradeCost) exitWith { "The resistance cannot afford this" call OT_fnc_notifyMinor; false };

[-OT_dispensaryUpgradeCost] call OT_fnc_resistanceFunds;
if (isServer) then { [_name, 2] call OT_fnc_dispensaryRegister } else { [_name, 2] remoteExec ["OT_fnc_dispensaryRegister", 2] };
format ["%1 has opened its back room: it sells blow from its stock too", _name] remoteExec ["OT_fnc_notifyMinor", 0, false];
true
