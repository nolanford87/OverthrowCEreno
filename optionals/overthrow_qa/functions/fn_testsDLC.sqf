/*
    Description:
    DLC compatibility fixes (fix/dlc-compat): classnames, weapon and aircraft classification, houses.
    Run on each map to cover its own class lists (Altis, Malden, Tanoa, Livonia).

    Returns: ARRAY - [[name, code], ...], part of the review and DLC QA tests (OTQA_fnc_testsFollowups)
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
        // FIA and CTRG weapons that used to leak in (only when NATO occupies, other occupiers carry some of them)
        if !(toUpperANSI OT_faction_NATO in ["BLU_F", "BLU_T_F", "BLU_W_F"]) then {
            format ["NATO weapon pool leak check skipped: %1 occupies, not NATO", OT_NATO_name] call OTQA_fnc_manual;
        } else {
            private _leaked = _all arrayIntersect ["arifle_TRG21_F", "arifle_TRG20_F", "arifle_Mk20_F", "arifle_AKM_F", "launch_RPG32_F", "hgun_PDW2000_F"];
            ["NATO weapon pools only hold NATO weapons", _leaked isEqualTo [], format ["found: %1", _leaked]] call OTQA_fnc_check;
        };
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
    }],

    ["Randomized loadout pools", {
        // Goes through both lobby options, then puts the lobby choice back
        private _inUse = OT_randomLoadoutPool;
        private _names = [format ["Faction random (%1)", OT_NATO_name], "Fully random"];
        private _cls = OT_NATO_Units_LevelOne param [0, "B_Soldier_F"];
        private _loadout = getUnitLoadout (configFile >> "CfgVehicles" >> _cls);
        private _armor = { getNumber (configFile >> "CfgWeapons" >> (_this select 0) >> "ItemInfo" >> "HitpointsProtectionInfo" >> (_this select 1) >> "armor") };
        private _grp = createGroup blufor;

        {
            private _name = _names select _forEachIndex;
            OT_randomLoadoutPool = _x;

            private _counts = ["rifles", "glRifles", "machineGuns", "sniperRifles", "launchers", "handguns", "smgs", "vests", "helmets"] apply { [_x, count (OT_randomLoadoutPool get _x)] };
            [format ["%1: pool is set up", _name], (_counts select { _x select 1 > 0 }) isNotEqualTo [], format ["%1", _counts]] call OTQA_fnc_check;

            // A NATO rifleman, randomized like initNATO does it
            private _new = [_loadout, nil, nil, nil, nil, nil, nil, true] call OT_fnc_randomizeLoadout;
            private _primary = (_new select 0) param [0, ""];
            private _rifles = (OT_randomLoadoutPool get "rifles") + (OT_randomLoadoutPool get "glRifles") + (OT_randomLoadoutPool get "machineGuns") + (OT_randomLoadoutPool get "sniperRifles");
            [format ["%1: primary comes from the pool", _name], _primary in _rifles || { _primary isEqualTo ((_loadout select 0) param [0, ""]) }, format ["%1 (%2)", _primary, _cls]] call OTQA_fnc_check;
            private _mag = (_new select 0) param [4, []];
            [format ["%1: primary has a magazine", _name], _mag isNotEqualTo [] && { (toLowerANSI (_mag select 0)) in ((compatibleMagazines _primary) apply { toLowerANSI _x }) }, format ["%1", _mag]] call OTQA_fnc_check;

            private _oldVest = (_loadout select 4) param [0, ""];
            private _newVest = (_new select 4) param [0, ""];
            [format ["%1: vest keeps about the same armor", _name], abs (([_oldVest, "Chest"] call _armor) - ([_newVest, "Chest"] call _armor)) <= 4, format ["%1 -> %2", _oldVest, _newVest]] call OTQA_fnc_check;
            [format ["%1: uniform stays", _name], ((_new select 3) param [0, ""]) isEqualTo ((_loadout select 3) param [0, ""]), ""] call OTQA_fnc_check;

            // Put it on a spawned soldier to see the game accepts it
            private _unit = _grp createUnit [_cls, [worldSize - 100, 100 + 10 * _forEachIndex, 0], [], 0, "CAN_COLLIDE"];
            _unit setUnitLoadout [_new, true];
            [format ["%1: soldier wears the loadout", _name], primaryWeapon _unit isEqualTo _primary && { vest _unit isEqualTo _newVest } && { uniform _unit isNotEqualTo "" },
                format ["weapon %1, vest %2, helmet %3", primaryWeapon _unit, vest _unit, headgear _unit]] call OTQA_fnc_check;
            deleteVehicle _unit;
        } forEach OT_randomLoadoutPools;

        deleteGroup _grp;
        OT_randomLoadoutPool = _inUse;
    }],

    ["Occupier loadout choice", {
        private _mode = server getVariable ["OT_randomLoadoutMode", -1];
        private _names = ["Standard", "Faction random", "Fully random"];
        ["Loadout choice is saved with the game", _mode in [0, 1, 2], format ["%1", _names param [_mode, _mode]]] call OTQA_fnc_check;
        ["Soldiers use the saved choice", OT_randomizeLoadouts isEqualTo (_mode > 0) && { OT_randomLoadoutPool isEqualTo (OT_randomLoadoutPools select (_mode isEqualTo 2)) }, format ["randomize %1", OT_randomizeLoadouts]] call OTQA_fnc_check;
    }]
]
