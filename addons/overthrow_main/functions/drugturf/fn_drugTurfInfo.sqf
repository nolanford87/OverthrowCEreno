/*
    Description:
    The gang turf lines of a drug operation's business info (OT_fnc_showBusinessInfo): whose turf it's
    on (OT_fnc_drugTurfGang), the deal with them (their cut, what's been paid) or how they feel about
    it (OT_fnc_drugTurfMood).

    Parameters:
        _this: STRING - Business name (a dispensary or lab)

    Usage: _text = _text + (_name call OT_fnc_drugTurfInfo);

    Returns: STRING - Structured text lines, "" when it's on no gang's turf
*/

private _name = _this;
private _data = _name call OT_fnc_getBusinessData;
if (_data isEqualTo []) exitWith { "" };
private _pos = _data select 0;
([_pos] call OT_fnc_drugTurfGang) params [["_gangId", -1], ["_gang", []]];
if (_gangId < 0) exitWith { "" };

private _deal = [_gangId] call OT_fnc_drugTurfDealOf;
private _text = format ["<t size='0.65'>On %1's turf (camp %2 m away)</t><br/>", _gang select 8, round ((_gang select 4) distance2D _pos)];
if (_deal isNotEqualTo []) then {
    _text = _text + format ["<t size='0.65' color='#a0ffa0'>Deal: they take %1 of what it makes ($%2 and %3 blow paid so far)</t><br/>", (str (round (OT_drugTurfCut * 100))) + "%", [_deal select 2, 1, 0, true] call CBA_fnc_formatNumber, _deal select 3];
} else {
    _text = _text + format ["<t size='0.65' color='#ffa0a0'>No deal: they're %1 about it; talk to them to pay their cut</t><br/>", [[_gangId] call OT_fnc_drugTurfAngerOf] call OT_fnc_drugTurfMood];
};
_text
