/*
    Description:
    A boat casts its net (server): every fish within reach of the boat (15 m, 20 m for the fishing boat,
    OT_fishingBoats) is caught into the boat's cargo as its item (OT_fishItems) - fishing-ground fish
    count against the ground until they come back (OT_fnc_huntingAvailable). Wild fish nearby count too.
    The player is told what was caught.

    Parameters:
        _this # 0: OBJECT - The boat
        _this # 1: OBJECT - Player casting

    Usage: [vehicle player, player] remoteExec ["OT_fnc_castNet", 2];

    Returns: ARRAY - Items caught (also when called directly)
*/

params ["_boat", "_player"];

if (!isServer || { isNull _boat }) exitWith { [] };
private _reach = OT_fishingBoats getOrDefault [typeOf _boat, 0];
if (_reach <= 0 || { !surfaceIsWater (getPosATL _boat) }) exitWith { [] };

private _caught = [];
{
    private _item = OT_fishItems getOrDefault [typeOf _x, ""];
    if (_item isEqualTo "" || { !alive _x }) then { continue };
    private _key = _x getVariable ["OT_huntKey", ""];
    if (_key isNotEqualTo "") then { [_key, -1] call OT_fnc_huntingAvailable };
    deleteVehicle _x;
    _boat addItemCargoGlobal [_item, 1];
    _caught pushBack _item;
} forEach (nearestObjects [_boat, ["Fish_Base_F", "Turtle_F"], _reach]);

private _text = "The net came up empty";
if (_caught isNotEqualTo []) then {
    private _counts = [];
    {
        private _item = _x;
        private _n = { _x isEqualTo _item } count _caught;
        _counts pushBack format ["%1 %2", _n, getText (configFile >> "CfgWeapons" >> _item >> "displayName")];
    } forEach (_caught arrayIntersect _caught);
    _text = format ["Caught: %1 (in the boat's cargo)", _counts joinString ", "];
};
if (!isNull _player) then { _text remoteExec ["OT_fnc_notifyMinor", _player, false] };
_caught;
