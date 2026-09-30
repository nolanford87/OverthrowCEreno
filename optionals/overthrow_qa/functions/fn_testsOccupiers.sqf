/*
    Description:
    Occupier QA tests: goes through every "Occupying faction" lobby option, applies it and checks its
    template (classes exist, infantry to spawn, crews fight as BLUFOR). Options whose mod isn't loaded
    are listed as manual. Puts the save's own occupier back at the end.

    Returns: ARRAY - [[name, code], ...] run by OTQA_fnc_run
*/

"Start a new game with a non-NATO occupier (e.g. CSAT): bases fly its flag, its soldiers and vehicles garrison them, messages use its name" call OTQA_fnc_manual;
"Save and reload that game with a different lobby choice: it keeps the occupier it was started with" call OTQA_fnc_manual;
"With CSAT occupying: NATO can have a faction rep, CSAT can't" call OTQA_fnc_manual;

OTQA_occ_isClass = {
    isClass (configFile >> "CfgVehicles" >> _this)
    || { isClass (configFile >> "CfgWeapons" >> _this) }
    || { isClass (configFile >> "CfgMagazines" >> _this) }
    || { isClass (configFile >> "CfgGlasses" >> _this) }
};

// Every string in the occupier's class lists
OTQA_occ_missing = {
    private _missing = [];
    private _collect = {
        if (_this isEqualType "") exitWith {
            if (_this isNotEqualTo "" && { !(_this call OTQA_occ_isClass) }) then { _missing pushBackUnique _this };
        };
        if (_this isEqualType []) then { { _x call _collect } forEach _this };
    };
    private _prefixes = ["ot_nato_vehicle", "ot_nato_unit", "ot_nato_staticgarrison", "ot_nato_hmg", "ot_nato_mortar"];
    {
        private _var = _x;
        if (_prefixes findIf { (_var select [0, count _x]) isEqualTo _x } > -1) then { (missionNamespace getVariable _var) call _collect };
    } forEach (allVariables missionNamespace);
    _missing;
};

[
    ["Occupying factions", {
        private _saveChoice = OT_occupierChoice;
        private _texts = getArray (missionConfigFile >> "Params" >> "ot_enemy_faction" >> "texts");
        private _values = getArray (missionConfigFile >> "Params" >> "ot_enemy_faction" >> "values");
        private _grp = createGroup blufor;

        {
            private _value = _x;
            private _label = _texts param [_forEachIndex, str _value];
            private _applied = [_value] call OT_fnc_applyOccupier;

            if (_applied isNotEqualTo _value) then {
                format ["%1: its faction isn't loaded (falls back to the map's own)", _label] call OTQA_fnc_manual;
                continue;
            };

            // Faction and names
            [format ["%1: faction exists", _label], isClass (configFile >> "CfgFactionClasses" >> OT_faction_NATO), format ["%1 (%2)", OT_faction_NATO, OT_NATO_name]] call OTQA_fnc_check;
            [format ["%1: map marker and flag exist", _label], isClass (configFile >> "CfgMarkers" >> OT_NATO_markerFlag) && { isClass (configFile >> "CfgVehicles" >> OT_flag_NATO) }, format ["%1, %2", OT_NATO_markerFlag, OT_flag_NATO]] call OTQA_fnc_check;

            // Classes
            private _missing = call OTQA_occ_missing;
            [format ["%1: all classes exist", _label], _missing isEqualTo [], format ["missing: %1", _missing]] call OTQA_fnc_check;

            // Infantry: groups in CfgGroups (like initNATO), or soldiers to build squads from
            private _groups = 0;
            {
                _groups = _groups + ({ count ("true" configClasses _x) > 5 } count ("true" configClasses _x));
            } forEach ("'infantry' in toLower (configName _x)" configClasses (configFile >> "CfgGroups" >> OT_NATO_groupSide >> OT_faction_NATO));
            private _soldiers = { getNumber (_x >> "scope") isEqualTo 2 } count (format ["getText (_x >> 'faction') == '%1' && { (configName _x) isKindOf 'CAManBase' }", OT_faction_NATO] configClasses (configFile >> "CfgVehicles"));
            [format ["%1: has infantry", _label], _groups > 0 || { _soldiers > 3 }, format ["%1 infantry groups, %2 soldiers", _groups, _soldiers]] call OTQA_fnc_check;

            // Weapons for supply crates
            [format ["%1: has weapons for supply crates", _label], OT_allBLURifles isNotEqualTo [] && { OT_allBLURifleMagazines isNotEqualTo [] }, format ["%1 rifles", count OT_allBLURifles]] call OTQA_fnc_check;

            // A crewed vehicle fights as BLUFOR, whatever the faction's own side
            private _vehCls = selectRandom OT_NATO_Vehicles_GroundSupport;
            private _veh = createVehicle [_vehCls, [worldSize - 150, 150 + 20 * _forEachIndex, 0], [], 0, "CAN_COLLIDE"];
            private _crewGroup = [_veh, _grp] call OT_fnc_createNATOCrew;
            private _sides = (crew _veh) apply { side group _x };
            [format ["%1: vehicle crew is BLUFOR", _label], _sides isNotEqualTo [] && { _sides findIf { _x isNotEqualTo blufor } isEqualTo -1 }, format ["%1: %2", _vehCls, _sides]] call OTQA_fnc_check;
            { deleteVehicle _x } forEach (crew _veh);
            deleteVehicle _veh;

            // A soldier of the faction in a BLUFOR group keeps its own uniform
            private _unit = _grp createUnit [OT_NATO_Unit_SquadLeader, [worldSize - 150, 100, 0], [], 0, "CAN_COLLIDE"];
            [format ["%1: squad leader spawns as BLUFOR", _label], side group _unit isEqualTo blufor && { uniform _unit isNotEqualTo "" }, format ["%1, uniform %2", OT_NATO_Unit_SquadLeader, uniform _unit]] call OTQA_fnc_check;
            deleteVehicle _unit;
        } forEach _values;

        deleteGroup _grp;
        [_saveChoice] call OT_fnc_applyOccupier;
        ["Save's own occupier is back", OT_occupierChoice isEqualTo _saveChoice, format ["%1 (%2)", OT_NATO_name, OT_faction_NATO]] call OTQA_fnc_check;
    }]
]
