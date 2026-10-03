/*
    Description:
    Blow (drugs slice 2): the numbers for drug labs, blow precursors made by industrial businesses and
    the gangs' chemical convoys. Every machine: the server from OT_fnc_drugLabSites (before the
    economy loads), clients from OT_fnc_drugLabsLocal.

    Usage: call OT_fnc_drugLabsVars;
*/

// Labs: a run-down industrial shed by a road (OT_fnc_drugLabSite), bought like a business
OT_drugLabShed = ["Land_i_Shed_Ind_F", "Land_u_Shed_Ind_F"] select (isClass (configFile >> "CfgVehicles" >> "Land_u_Shed_Ind_F"));
OT_drugLabBasePrice = 60000; // Plus the usual instability markup (OT_fnc_getBusinessPrice)
OT_drugLabPerCook = 1; // Precursors each employee cooks per business cycle (OT_fnc_drugLabCycle)
OT_drugLabCap = 6; // Precursors cooked per cycle at most, however many employees
OT_drugLabYield = 3; // Blow per precursor

// Industrial businesses switched to make precursors as well (OT_fnc_drugPrecursorCycle)
OT_precursorPerEmployees = 2; // 1 precursor per 2 employees (rounded up) each cycle
OT_precursorMax = 4; // At most this many per cycle
OT_precursorCost = 60; // Paid from resistance funds for each one (the chemicals)
private _industrial = ["Mine", "Lumber", "Sawmill", "Power Plant", "Factory", "Quarry"];
private _goods = ["OT_Steel", "OT_Wood", "OT_Lumber", "OT_Plastic"];
OT_precursorBusinesses = [];
{
    _x params ["", "_name", ["_input", ""], ["_output", ""]];
    if (_name in (missionNamespace getVariable ["OT_fisheries", []]) || { _output isEqualTo "OT_Blow" }) then { continue };
    if ((_industrial findIf { _x in _name }) > -1 || { _output in _goods }) then { OT_precursorBusinesses pushBack _name };
} forEach OT_economicData;

// Gang chemical convoys (OT_fnc_drugConvoyTick): one at a time, every 30-60 real minutes, from the camp
// of a gang with a player within 2 km of it
OT_drugConvoyWait = [1800, 3600];
OT_drugConvoyRange = 2000;
OT_drugConvoyEscortChance = 30; // % of runs with an occupier police car as escort
OT_drugConvoyLoad = [6, 10]; // Precursors in the truck
OT_drugConvoyTimeout = 1800; // A run is over after 30 minutes wherever it is
OT_drugConvoyIntelRep = 10; // Gang rep for word of their runs, wherever the player is
OT_drugConvoyIntelRange = 2500; // Or this close to where it sets off
