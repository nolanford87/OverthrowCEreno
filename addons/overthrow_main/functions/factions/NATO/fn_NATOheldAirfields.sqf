/*
    Description:
    The airfields the occupier still holds (OT_airportData, those not abandoned). The QA tests can set
    OT_testAirfields ([[position, name], ...]) to stand in for them.

    Usage: private _airfields = call OT_fnc_NATOheldAirfields;

    Returns: ARRAY - [[position, name, ...], ...], [] when it holds none
*/

private _test = missionNamespace getVariable "OT_testAirfields"; // Set only by the QA tests
if (!isNil "_test") exitWith { _test };

private _abandoned = server getVariable ["NATOabandoned", []];
OT_airportData select { !((_x select 1) in _abandoned) };
