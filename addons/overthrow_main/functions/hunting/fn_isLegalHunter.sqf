/*
    Description:
    Is a player hunting legally: a valid hunting licence (OT_fnc_buyHuntingLicence), outside towns,
    and the only weapon is a hunting rifle (OT_huntingWeapons) - no handgun or launcher. Such a player
    keeps their cover while carrying it (OT_fnc_hasWeaponEquipped) and searches leave it alone.

    Parameters:
        _this # 0: OBJECT - Unit
        _this # 1: NUMBER - (Optional) Extra metres around towns that still count as in town (gunfire
            is heard from further away)

    Usage: [player] call OT_fnc_isLegalHunter;

    Returns: BOOL
*/

params ["_unit", ["_extra", 0]];

isPlayer _unit
&& { (_unit getVariable ["OT_huntLicence", 0]) > 0 }
&& { (primaryWeapon _unit) in OT_huntingWeapons || { ((primaryWeapon _unit) call BIS_fnc_baseWeapon) in OT_huntingWeapons } }
&& { secondaryWeapon _unit isEqualTo "" }
&& { handgunWeapon _unit isEqualTo "" }
&& { !([getPosATL _unit, _extra] call OT_fnc_isInTown) }
