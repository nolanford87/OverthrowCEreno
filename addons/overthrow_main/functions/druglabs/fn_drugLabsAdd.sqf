/*
    Description:
    Makes the drug labs businesses on this machine: each one goes into OT_economicData as
    [position, name, "OT_Precursors", "OT_Blow"] (bought, staffed and paid like any business) and its
    name into OT_drugLabs. Sites from OT_fnc_drugLabSites (server variable "drugLabSites").

    Parameters:
        _this # 0: ARRAY - Lab sites [id, name, position, shed position, shed direction, road position]

    Usage: [_sites] call OT_fnc_drugLabsAdd;
*/

params ["_sites"];

OT_drugLabSites = _sites;
OT_drugLabs = [];
{
    _x params ["", "_name", "_pos"];
    if ((OT_economicData findIf { (_x select 1) isEqualTo _name }) isEqualTo -1) then {
        OT_economicData pushBack [_pos, _name, "OT_Precursors", "OT_Blow"];
    };
    OT_drugLabs pushBack _name;
} forEach _sites;
