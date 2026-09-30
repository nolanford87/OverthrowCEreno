params ["_unit", "_town"];

private _identity = call OT_fnc_randomLocalIdentity;
_identity set [1, ""]; // Retain original gendarme clothes
_identity set [3, ""]; // No glasses for gendarme
_identity pushBack (selectRandom OT_voices_local);
[_unit, _identity] call OT_fnc_applyIdentity;

_unit setVariable ["garrison", _town, false];

_unit addEventHandler [
    "HandleDamage",
    {
        private _src = _this select 3;
        if (captive _src) then {
            if (!isNull objectParent _src || (_src call OT_fnc_unitSeenNATO)) then {
                _src setCaptive false;
            };
        };
    }
];

// Increase skill levels for heavy units to simulate training
if (toLowerANSI (typeOf _unit) in ([OT_NATO_Unit_PoliceCommander_Heavy, OT_NATO_Unit_Police_Heavy, OT_NATO_Unit_PoliceMedic_Heavy] apply { toLowerANSI _x })) then {
    _unit setRank "SERGEANT";
    _unit setSkill ["courage", 0.7];
    _unit setSkill ["commanding", 0.7];
    _unit setSkill ["spotTime", 0.7];
};

if ((random 100) < 75 && OT_randomizeLoadouts) then {
    _unit setUnitLoadout [_unit call OT_fnc_getRandomLoadout, true];
};

_unit addEventHandler ["Dammaged", OT_fnc_EnemyDamagedHandler];
