/*
    Description:
    The mayor's office defence template key of a building class: the variants of one model (V2/V3
    colours, Land_u_ without doors, Malden's _b_<colour> versions) share the template of the plain
    Land_i_..._V1_F one. The key names the template function (OT_fnc_officeTpl_<key>, see
    OT_fnc_officeTemplate). Any machine.

    Parameters:
        _this # 0: STRING or OBJECT - Building class, or the building

    Usage: private _key = [typeOf _building] call OT_fnc_officeTemplateKey;

    Returns: STRING - The key (the model's class without "Land_", e.g. "i_House_Big_01_V1_F"), "" for a class with no template
*/

params [["_class", "", ["", objNull]]];

if (_class isEqualType objNull) then { _class = typeOf _class };

// The Altis office buildings (the templates are in functions/offices/templates)
private _keys = [
    "i_Stone_HouseBig_V1_F", "i_House_Big_02_V1_F", "i_House_Big_01_V1_F", "i_Shop_01_V1_F", "i_Shop_02_V1_F",
    "Research_HQ_F", "Offices_01_V1_F", "Hospital_main_F"
];

private _key = _class;
if ((_key select [0, 5]) isEqualTo "Land_") then { _key = _key select [5] };
if ((_key select [0, 2]) isEqualTo "u_") then { _key = "i_" + (_key select [2]) };
_key = _key regexReplace ["_b_[a-zA-Z]+_F$", "_V1_F"];
_key = _key regexReplace ["_V[23]_F$", "_V1_F"];

if (_key in _keys) exitWith { _key };
""
