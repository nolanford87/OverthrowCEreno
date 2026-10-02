/*
    Description:
    What a search leaves alone on a legal hunter (OT_fnc_isLegalHunter): their hunting rifle (also its
    base class, as searches list it), its attachments and its ammunition. Nothing for anyone else.

    Parameters:
        _this: OBJECT - Unit searched

    Usage: private _legal = _unit call OT_fnc_huntingLegalItems;

    Returns: ARRAY - Classes
*/

if !([_this] call OT_fnc_isLegalHunter) exitWith { [] };
private _rifle = primaryWeapon _this;
[_rifle, _rifle call BIS_fnc_baseWeapon] + ((primaryWeaponItems _this) select { _x isNotEqualTo "" }) + (compatibleMagazines _rifle)
