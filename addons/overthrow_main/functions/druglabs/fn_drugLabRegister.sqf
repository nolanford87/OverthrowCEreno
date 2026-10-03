/*
    Description:
    Puts a resistance-owned drug lab on the list of drug operations (server variable "drugOps", saved,
    shared with the dispensaries): [id, "lab", position, nearest town, level]. Once per lab; the list
    is made if there's none. Called when a lab is bought (OT_fnc_buyBusiness), each business cycle
    and every 30 seconds for owned labs (OT_fnc_initDrugLabs).

    Parameters:
        _this: STRING - Lab name or id

    Usage: "Kavala Lab" call OT_fnc_drugLabRegister; (server)

    Returns: ARRAY - Its drugOps entry, [] for no such lab
*/

private _site = _this call OT_fnc_drugLabData;
if (_site isEqualTo []) exitWith { [] };
_site params ["_id", "", "_pos"];

private _ops = server getVariable ["drugOps", []];
private _i = _ops findIf { (_x select 0) isEqualTo _id };
if (_i > -1) exitWith { _ops select _i };
private _entry = [_id, "lab", _pos, _pos call OT_fnc_nearestTown, 1];
_ops pushBack _entry;
server setVariable ["drugOps", _ops, true];
_entry;
