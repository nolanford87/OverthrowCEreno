/*
    Description:
    A raid the occupier wins (OT_fnc_drugRaid) seizes a drug operation's stock: every ganja, blow and
    blow precursor in the containers within 50 m of it (the ones its cycle sells from or cooks from)
    is removed.

    Parameters:
        _this # 0: STRING - Operation id

    Usage: ([_opId] call OT_fnc_drugRaidSeize) params ["_ganja", "_blow", "_precursors"]; (server)

    Returns: ARRAY - [ganja, blow, precursors] seized
*/

params ["_opId"];

private _ops = server getVariable ["drugOps", []];
private _i = _ops findIf { (_x select 0) isEqualTo _opId };
if (_i < 0) exitWith { [0, 0, 0] };
private _pos = (_ops select _i) select 2;

private _goods = ["OT_Ganja", "OT_Blow", "OT_Precursors"];
private _seized = [0, 0, 0];
{
    private _c = _x;
    {
        _x params ["_cls", "_amt"];
        private _k = _goods find _cls;
        if (_k > -1) then { _seized set [_k, (_seized select _k) + ([_c, _cls, _amt] call OT_fnc_removeFromCargo)] };
    } forEach (_c call OT_fnc_unitStock);
} forEach (nearestObjects [_pos, [OT_item_CargoContainer], 50]);
_seized
