private _blueprints = server getVariable ["GEURblueprints", []];
if (_blueprints isEqualTo []) then {
    _blueprints = OT_item_DefaultBlueprints;
    server setVariable ["GEURblueprints", _blueprints, true];
};
//Keeps track of all entities that should trigger the spawner
private _nextMinute = time + 15; // Real time (OT_fnc_GUERLoop)
private _nextBusiness = time + 900;
server setVariable ["OT_nextBusinessAt", serverTime + 900, true];
private _currentProduction = "";
private _stabcounter = 0;
private _trackcounter = 0;

GUER_faction_loop_data = [_nextMinute, _nextBusiness, _currentProduction, _stabcounter, _trackcounter];

["GUER_faction_loop", "_counter % 5 isEqualTo 0", "call OT_fnc_GUERLoop"] call OT_fnc_addActionLoop;
