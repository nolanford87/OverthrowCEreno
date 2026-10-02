// A legal hunter's hunting rifle outside towns doesn't count (OT_fnc_isLegalHunter)
if ([_this] call OT_fnc_isLegalHunter) exitWith { false };
([secondaryWeapon _this, handgunWeapon _this] isNotEqualTo ["", ""]) || !(primaryWeapon _this in ["ACE_FakePrimaryWeapon", ""]);
