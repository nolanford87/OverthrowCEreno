/*
    Description:
    Mayor's office static weapons by role, so a layout keeps working whichever occupier faction is in play:
    a static weapon's role from its class (by the engine's base classes), or the occupier's static for a
    role (its mortar, else the first of its garrison statics of that kind, else the vanilla NATO one).
    Roles: "hmg", "gmg", "at", "aa", "mortar". Any machine (after the occupier is set up, for a class).

    Parameters:
        _this # 0: STRING or OBJECT - A role (gives the class), or a static weapon or its class (gives the role)

    Usage: private _class = ["gmg"] call OT_fnc_officeStatic; private _role = [_static] call OT_fnc_officeStatic;

    Returns: STRING - The occupier's class for a role, or the role of a static ("" for something else)
*/

params [["_what", "", ["", objNull]]];

private _roles = ["hmg", "gmg", "at", "aa", "mortar"];
private _bases = ["StaticMGWeapon", "StaticGrenadeLauncher", "StaticATWeapon", "StaticAAWeapon", "StaticMortar"];
if (_what isEqualType objNull) then { _what = typeOf _what };

// Does a static's main gun fire bullets (an "hmg"; the vanilla AT static is a kind of StaticMGWeapon too)
private _bullets = {
    private _weapon = (getArray (configFile >> "CfgVehicles" >> _this >> "Turrets" >> "MainTurret" >> "weapons")) param [0, ""];
    private _mag = (getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines")) param [0, ""];
    (getText (configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _mag >> "ammo") >> "simulation")) isEqualTo "shotBullet"
};
private _i = _roles find _what;
if (_i < 0) exitWith {
    // A class: its role (the machine gun last: the AT and other statics are kinds of StaticMGWeapon too)
    private _j = [2, 3, 1, 4, 0] select { _what isKindOf (_bases select _x) };
    if (_j isEqualTo []) exitWith { "" };
    // A machine gun's kind that fires no bullets is the vanilla AT static's
    if ((_j select 0) isEqualTo 0 && { !(_what call _bullets) }) exitWith { "at" };
    _roles select (_j select 0)
};

if (_what isEqualTo "mortar") exitWith { missionNamespace getVariable ["OT_NATO_Mortar", "B_Mortar_01_F"] };
private _base = _bases select _i;
private _all = (missionNamespace getVariable ["OT_NATO_StaticGarrison_LevelThree", []]) + (missionNamespace getVariable ["OT_NATO_StaticGarrison_LevelTwo", []]) + (missionNamespace getVariable ["OT_NATO_StaticGarrison_LevelOne", []]);
// Of that kind; an "hmg" one whose main gun fires bullets
private _k = _all findIf { _x isKindOf _base && { _what isNotEqualTo "hmg" || { _x call _bullets } } };
if (_k > -1) exitWith { _all select _k };
["B_HMG_01_high_F", "B_GMG_01_high_F", "B_static_AT_F", "B_static_AA_F"] select _i
