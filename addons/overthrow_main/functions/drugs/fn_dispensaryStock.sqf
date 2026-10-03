/*
    Description:
    Hands the player's ganja (and blow, once the back room is open) to a dispensary's budtender: it
    goes in the dispensary's container, to be sold (OT_fnc_dispensaryCycle). Nobody pays for it now,
    and it costs no cover: it's a legal shop.

    Parameters:
        _this # 0: STRING - Dispensary (business name)

    Usage: [_name] call OT_fnc_dispensaryStock;

    Returns: NUMBER - Items handed over
*/

params ["_name"];

private _data = _name call OT_fnc_getBusinessData;
if (_data isEqualTo []) exitWith { 0 };
private _level = _name call OT_fnc_dispensaryLevel;
if (_level < 1) exitWith { "This dispensary isn't open, the resistance has to buy it first" call OT_fnc_notifyMinor; 0 };
private _drugs = [["OT_Ganja"], ["OT_Ganja", "OT_Blow"]] select (_level >= 2);

private _container = [_data select 0] call OT_fnc_dispensaryContainer;
private _given = 0;
{
    private _cls = _x;
    private _n = { _x isEqualTo _cls } count (items player);
    for "_i" from 1 to _n do { player removeItem _cls };
    if (_n > 0) then { _container addItemCargoGlobal [_cls, _n] };
    _given = _given + _n;
} forEach _drugs;

if (_given isEqualTo 0) exitWith {
    (["You have no ganja to stock the shelves with", "You have no ganja or blow to stock the shelves with"] select (_level >= 2)) call OT_fnc_notifyMinor;
    0
};
format ["Handed over %1 for the shelves (in the dispensary's container)", _given] call OT_fnc_notifyMinor;
_given
