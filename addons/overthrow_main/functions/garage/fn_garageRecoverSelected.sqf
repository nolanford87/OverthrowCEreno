/*
    Description:
    "Recover to Garage" button of the Vehicles screen (OT_dialog_logistics): recovers the selected vehicle.

    Usage: call OT_fnc_garageRecoverSelected;
*/

private _index = lbCurSel 1500;
if (_index < 0) exitWith {};
private _veh = (lbData [1500, _index]) call BIS_fnc_objectFromNetId;
if (isNull _veh) exitWith {};

closeDialog 0;
[_veh, player] remoteExecCall ["OT_fnc_garageRecover", 2];
