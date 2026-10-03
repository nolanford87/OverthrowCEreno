/*
    Description:
    How a drug operation is named in gang turf messages: "our dispensary (Kavala Dispensary)", "our
    lab (Kavala Lab)" (a lab's id on drugOps is turned into its name, OT_fnc_drugLabData).

    Parameters:
        _this # 0: ARRAY - Its drugOps entry [id, type, position, town, level]

    Usage: private _label = [_op] call OT_fnc_drugTurfOpLabel;

    Returns: STRING
*/

params ["_op"];

_op params [["_id", ""], ["_type", ""]];
private _name = _id;
if (_type isEqualTo "lab") then {
    private _site = _id call OT_fnc_drugLabData;
    if (_site isNotEqualTo []) then { _name = _site select 1 };
};
format ["our %1 (%2)", _type, _name]
