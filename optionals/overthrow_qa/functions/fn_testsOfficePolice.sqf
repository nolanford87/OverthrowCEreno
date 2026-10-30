/*
    Description:
    The police station set up at a captured town's mayor's office (OT_fnc_officePolice, the user's): no police
    station in the build menu any more; at the office of a town of ours the main menu's button sets it up for
    $2,500 (2 police, the station at the office), then manages it; not at the office, nor in a town of theirs.
    Part of the archived QA tests. Moves the host there and back; the town, the money and the police put back.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

call OTQA_fnc_testsOfficeHelpers;
"Office police: in play, take a town, stand in its mayor's office, open the main menu: the building panel says Mayor's Office and the button reads Police ($2,500), then Manage" call OTQA_fnc_manual;

[
    ["Office: the police station set up at a captured mayor's office", {
        private _town = ([] call OTQA_og_towns) param [0, ""];
        if (_town isEqualTo "") exitWith { ["Office police: a town with an office", false, "none"] call OTQA_fnc_check };
        private _saved = [_town] call OTQA_og_save;
        private _from = getPosASL player;
        private _money = player getVariable ["money", 0];
        player allowDamage false;

        ["Office police: no police station in the build menu", (OT_Buildables findIf { (_x select 0) isEqualTo "Police Station" }) < 0, ""] call OTQA_fnc_check;

        private _office = _town call OTQA_og_officePos;
        player setPosATL (_office vectorAdd [0, 0, 0.5]);
        sleep 2;
        private _theirs = ["near"] call OT_fnc_officePolice;
        server setVariable ["NATOabandoned", (server getVariable ["NATOabandoned", []]) + [_town], true];
        private _ours = ["near"] call OT_fnc_officePolice;
        player setPosATL ((_office getPos [200, 0]) vectorAdd [0, 0, 0.5]);
        sleep 1;
        private _away = ["near"] call OT_fnc_officePolice;
        ["Office police: offered at the office of a town of ours only", _theirs isEqualTo "" && { _ours isEqualTo _town } && { _away isEqualTo "" },
            format ["%1: theirs '%2', ours '%3', 200 m off '%4'", _town, _theirs, _ours, _away]] call OTQA_fnc_check;

        player setPosATL (_office vectorAdd [0, 0, 0.5]);
        sleep 1;
        player setVariable ["money", 3000, true];
        ["use"] call OT_fnc_officePolice;
        sleep 3;
        private _pos = server getVariable [format ["policepos%1", _town], []];
        private _police = server getVariable [format ["police%1", _town], -1];
        ["Office police: set up for $2,500, 2 police, the station at the office",
            (player getVariable ["money", 0]) isEqualTo 500 && { _police isEqualTo 2 } && { _pos isNotEqualTo [] && { (_pos distance2D _office) < 1 } },
            format ["money left %1, police %2, station %3 m from the office", player getVariable ["money", 0], _police, if (_pos isEqualTo []) then { -1 } else { round (_pos distance2D _office) }]] call OTQA_fnc_check;

        ["use"] call OT_fnc_officePolice;
        sleep 1;
        private _dialog = !isNull (findDisplay 9000);
        closeDialog 0;
        ["Office police: then the button manages it (the police dialog), no second charge", _dialog && { (player getVariable ["money", 0]) isEqualTo 500 }, format ["dialog %1", _dialog]] call OTQA_fnc_check;

        { deleteVehicle _x } forEach (allUnits select { (_x getVariable ["polgarrison", ""]) isEqualTo _town });
        server setVariable [format ["police%1", _town], nil, true];
        server setVariable [format ["policepos%1", _town], nil, true];
        deleteMarker format ["%1-police", _town];
        [_town, _saved] call OTQA_og_restore;
        player setVariable ["money", _money, true];
        player setPosASL _from;
        player allowDamage true;
    }, 60]
]
