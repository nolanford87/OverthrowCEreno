/*
    Description:
    Whether a vehicle config is an armed plane. Jets DLC fighters and Apex VTOLs have a low
    'threat' value, so it can't be used for them. A plane is armed when it has weapon pylons
    or weapons in a turret (other than laser designators).

    Parameters:
        _this: CONFIG - CfgVehicles class

    Usage: (configFile >> "CfgVehicles" >> "I_Plane_Fighter_04_F") call OT_fnc_isArmedPlane;

    Returns: BOOL
*/

private _cfg = _this;
if !((configName _cfg) isKindOf "Plane") exitWith { false };
if (isClass (_cfg >> "Components" >> "TransportPylonsComponent")) exitWith { true };

private _armed = false;
{
    if ((getArray (_x >> "weapons")) findIf { !("laserdesignator" in toLowerANSI _x) } > -1) exitWith { _armed = true };
} forEach ("true" configClasses (_cfg >> "Turrets"));
_armed;
