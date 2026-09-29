/*
    Description:
    Batch 5 (fix/save-load-persistence): checks on the loaded save. Run after loading a save
    (not on a brand new game) for the checks to mean something.

    Returns: ARRAY - [[name, code], ...] run by OTQA_fnc_run
*/

"Load a save where a gang joined the resistance: no script errors, and a new gang can form in that town later" call OTQA_fnc_manual;
"Watch the weather over a few hours in game: Cloudy sometimes lasts more than one weather change" call OTQA_fnc_manual;
"Dedicated server: players without a home building rejoin at their last position, not the map corner" call OTQA_fnc_manual;

[
    ["Base flags owned by their builder", {
        private _bases = server getVariable ["bases", []];
        if (_bases isEqualTo []) exitWith {
            "Base owner test skipped: no forward bases in this save" call OTQA_fnc_manual;
        };
        private _wrong = [];
        {
            _x params ["_pos", "_name", ["_owner", ""]];
            if (_owner isEqualTo "") then { continue }; // Older saves don't store the owner
            private _flag = (_pos nearObjects [OT_flag_IND, 20]) param [0, objNull];
            if (isNull _flag || { (_flag call OT_fnc_getOwner) isNotEqualTo _owner }) then {
                _wrong pushBack _name;
            };
        } forEach _bases;
        ["Base flags owned by their builder", _wrong isEqualTo [], format ["%1 bases, wrong owner or missing flag: %2", count _bases, _wrong]] call OTQA_fnc_check;
    }],

    ["Leased buildings have positions", {
        private _bad = [];
        private _count = 0;
        {
            {
                _x params ["_id", "", ["_pos", []]];
                _count = _count + 1;
                if !(_pos isEqualType [] && { count _pos >= 2 }) then { _bad pushBack _id };
            } forEach (_x getVariable ["leasedata", []]);
        } forEach (allPlayers - (entities "HeadlessClient_F"));
        if (_count isEqualTo 0) exitWith {
            "Lease position test skipped: no leased buildings" call OTQA_fnc_manual;
        };
        ["Leased buildings have positions", _bad isEqualTo [], format ["%1 leased, without a position: %2", _count, _bad]] call OTQA_fnc_check;
    }],

    ["No empty gang records", {
        private _bad = [];
        {
            private _gangs = OT_civilians getVariable [format ["gangs%1", _x], []];
            {
                private _gang = OT_civilians getVariable [format ["gang%1", _x], []];
                if (_gang isEqualTo []) then { _bad pushBack _x };
            } forEach _gangs;
        } forEach OT_allTowns;
        ["No empty gang records", _bad isEqualTo [], format ["gang ids listed in a town without a record: %1", _bad]] call OTQA_fnc_check;
    }]
]
