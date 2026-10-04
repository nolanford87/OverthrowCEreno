/*
    Description:
    Automated QA runs (postInit): when the game was launched by the QA runner script, which sets
    uiNamespace "OTQA_autoRun" to a suite name from the -init command line before starting the
    mission, this starts a new game with the default settings (skipping the start dialogs), waits
    for the occupier to finish setting up and for the player to be ready, then runs that suite
    (OTQA_fnc_run). The runner reads the RPT for "OT_QA ===== DONE" and closes the game.
    Does nothing in a normal game.

    Usage: automatic (CfgFunctions postInit)
*/

if (!hasInterface || { !isServer }) exitWith {};
private _suite = uiNamespace getVariable ["OTQA_autoRun", ""];
if (_suite isEqualTo "") exitWith {};
uiNamespace setVariable ["OTQA_autoRun", ""]; // Only this once, not the next mission
// Items a survey suite is limited to (run-qa.ps1 -Only), e.g. building classes for the office probe
OTQA_only = uiNamespace getVariable ["OTQA_autoOnly", []];
uiNamespace setVariable ["OTQA_autoOnly", []];

[_suite] spawn {
    params ["_suite"];
    diag_log format ["OT_QA AUTORUN: started for '%1'", _suite];
    // The start dialog (OT_fnc_initPlayerLocal) once it's up, then a new game with the defaults
    waitUntil { sleep 0.5; !isNull (findDisplay 46) && { !isNil "OT_varInitDone" } && { OT_varInitDone } };
    private _timeout = time + 60;
    waitUntil { sleep 0.5; dialog || { (server getVariable ["StartupType", ""]) isNotEqualTo "" } || { time > _timeout } };
    if ((server getVariable ["StartupType", ""]) isEqualTo "") then {
        closeDialog 0;
        server setVariable ["generals", [getPlayerUID player], true];
        server setVariable ["OT_difficulty", 1, true];
        server setVariable ["OT_fastTravelType", 1, true];
        server setVariable ["OT_fastTravelRules", 1, true];
        [] remoteExec ["OT_fnc_newGame", 2, false];
        diag_log "OT_QA AUTORUN: new game started";
    };
    // The occupier set up and the player in the game
    _timeout = time + 600;
    waitUntil { sleep 1; (!isNil "OT_NATOInitDone" && { player getVariable ["OT_loaded", false] }) || { time > _timeout } };
    while { dialog } do { closeDialog 0; sleep 0.2 };
    sleep 10; // Let the world settle (spawners, the first loops)
    diag_log format ["OT_QA AUTORUN: running '%1' (NATO ready %2, player loaded %3)", _suite, !isNil "OT_NATOInitDone", player getVariable ["OT_loaded", false]];
    [_suite] call OTQA_fnc_run;
    diag_log "OT_QA AUTORUN: finished";
};
