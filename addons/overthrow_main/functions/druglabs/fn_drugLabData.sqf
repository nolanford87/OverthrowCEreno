/*
    Description:
    A drug lab's site (OT_fnc_drugLabSites) from its business name or its id.

    Parameters:
        _this: STRING - Lab name ("Kavala Lab") or id ("lab0")

    Usage: private _site = "Kavala Lab" call OT_fnc_drugLabData;

    Returns: ARRAY - [id, name, position, shed position, shed direction, road position], [] if none
*/

private _key = _this;
private _sites = missionNamespace getVariable ["OT_drugLabSites", []];
private _i = _sites findIf { (_x select 0) isEqualTo _key || { (_x select 1) isEqualTo _key } };
if (_i < 0) exitWith { [] };
_sites select _i;
