params ["_unit", "_id", "_uid", "_name"]; // HandleDisconnect parameters

private _highCommandModule = missionNamespace getVariable [format ["%1_hc_module", _uid], objNull];

deleteVehicle _highCommandModule;
missionNamespace setVariable [format ["%1_hc_module", _uid], objNull, true];
