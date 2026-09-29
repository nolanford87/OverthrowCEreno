/*
    Description:
    DLC compatibility fixes (fix/dlc-compat): classnames, weapon and aircraft classification, houses.
    Run on each map to cover its own class lists (Altis, Malden, Tanoa, Livonia).

    Returns: ARRAY - [[name, code], ...], part of the bug fix QA tests (OTQA_fnc_testsBugFixes)
*/

OTQA_dlc_isClass = {
    isClass (configFile >> "CfgVehicles" >> _this)
    || { isClass (configFile >> "CfgWeapons" >> _this) }
    || { isClass (configFile >> "CfgMagazines" >> _this) }
    || { isClass (configFile >> "CfgGlasses" >> _this) }
};

[
    ["NATO classnames exist", {
        // Every string in the OT_NATO_* variables of this map's mission
        private _missing = [];
        private _collect = {
            if (_this isEqualType "") exitWith {
                if (_this isNotEqualTo "" && { !(_this call OTQA_dlc_isClass) }) then { _missing pushBackUnique _this };
            };
            if (_this isEqualType []) then { { _x call _collect } forEach _this };
        };
        // Only the class lists, other OT_NATO_ variables hold positions, group and place names
        private _prefixes = ["ot_nato_vehicle", "ot_nato_unit", "ot_nato_staticgarrison", "ot_nato_weapons", "ot_nato_barrier", "ot_nato_hmg", "ot_nato_mortar", "ot_nato_sandbag", "ot_nato_commtowers"];
        {
            private _var = _x;
            if (_prefixes findIf { (_var select [0, count _x]) isEqualTo _x } > -1) then { (missionNamespace getVariable _var) call _collect };
        } forEach (allVariables missionNamespace);
        ["All NATO classnames exist on " + worldName, _missing isEqualTo [], format ["missing: %1", _missing]] call OTQA_fnc_check;
    }],

    ["NATO supply crate magazines", {
        private _bad = OT_allBLURifleMagazines select { !isClass (configFile >> "CfgMagazines" >> _x) };
        ["NATO rifle magazines are found", OT_allBLURifleMagazines isNotEqualTo [] && { _bad isEqualTo [] },
            format ["%1 magazines, %2 invalid", count OT_allBLURifleMagazines, count _bad]] call OTQA_fnc_check;
    }],

    ["NATO weapon pools", {
        private _all = OT_allBLURifles + OT_allBLUGLRifles + OT_allBLUMachineGuns + OT_allBLUSniperRifles + OT_allBLULaunchers + OT_allBLUPistols + OT_allBLUSMG;
        // FIA and CTRG weapons that used to leak in
        private _leaked = _all arrayIntersect ["arifle_TRG21_F", "arifle_TRG20_F", "arifle_Mk20_F", "arifle_AKM_F", "launch_RPG32_F", "hgun_PDW2000_F"];
        ["NATO weapon pools only hold NATO weapons", _leaked isEqualTo [], format ["found: %1", _leaked]] call OTQA_fnc_check;
        ["Gendarmes have SMGs to pick from", OT_allBLUSMG isNotEqualTo [], format ["%1", OT_allBLUSMG]] call OTQA_fnc_check;
    }],

    ["Handgun list", {
        private _bad = OT_allHandGuns select {
            (compatibleMagazines _x) isEqualTo [] || { _x isKindOf ["hgun_Pistol_Signal_F", configFile >> "CfgWeapons"] }
        };
        ["No spectrum device or flare pistol in handguns", _bad isEqualTo [], format ["found: %1", _bad]] call OTQA_fnc_check;
    }],

    ["Armed aircraft", {
        private _jets = ["B_Plane_Fighter_01_F", "O_Plane_Fighter_02_F", "I_Plane_Fighter_04_F", "B_T_VTOL_01_armed_F"];
        private _notThreat = _jets select { !(_x in OT_allPlaneThreats) };
        ["Jets and the armed Blackfish are aircraft threats", _notThreat isEqualTo [], format ["missing: %1", _notThreat]] call OTQA_fnc_check;
        private _sold = (OT_helis apply { _x select 0 }) select { (configFile >> "CfgVehicles" >> _x) call OT_fnc_isArmedPlane };
        ["No armed planes at the aircraft dealer", _sold isEqualTo [], format ["sold: %1", _sold]] call OTQA_fnc_check;
        ["Civilian plane is still sold", "C_Plane_Civil_01_F" in (OT_helis apply { _x select 0 }), ""] call OTQA_fnc_check;
    }],

    ["Houses", {
        private _special = [OT_policeStation, OT_workshopBuilding, OT_refugeeCamp] select { _x in OT_allHouses };
        ["Police station, workshop and refugee camp aren't homes", _special isEqualTo [], format ["found: %1", _special]] call OTQA_fnc_check;
        ["Tanoa slums are low population homes", "Land_Slum_01_F" in OT_lowPopHouses, ""] call OTQA_fnc_check;
        ["Big Tanoa houses are high population", "Land_House_Big_01_F" in OT_highPopHouses, ""] call OTQA_fnc_check;
        ["Two storey Livonia houses are high population", "Land_House_2W01_F" in OT_highPopHouses, ""] call OTQA_fnc_check;
        private _tiers = [count OT_lowPopHouses, count OT_medPopHouses, count OT_highPopHouses, count OT_hugePopHouses];
        ["Every house tier has houses", _tiers findIf { _x isEqualTo 0 } isEqualTo -1, format ["low/med/high/huge: %1", _tiers]] call OTQA_fnc_check;
    }]
]
