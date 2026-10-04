/*
    Description:
    The other pieces of a mayor's office building made of several map objects (the Altis hospital's
    two wings): where each stands relative to the main building, as the office probe read them off
    the real one on the map. The templates of such buildings are in the main building's coordinates
    and cover every piece. Any machine.

    Parameters:
        _this # 0: STRING - Template key (OT_fnc_officeTemplateKey)

    Usage: { _x params ["_class", "_offset", "_dir"]; ... } forEach (["Hospital_main_F"] call OT_fnc_officeParts);

    Returns: ARRAY - [[class, [x, y, z] in the main building's model coordinates, direction relative to it], ...], [] for a single-piece building
*/

params [["_key", "", [""]]];

private _parts = createHashMapFromArray [
    ["Hospital_main_F", [["Land_Hospital_side1_F", [4.7, 32.6, -8.21], 0], ["Land_Hospital_side2_F", [-28.03, -10.03, -8.23], 0]]]
];

_parts getOrDefault [_key, []]
