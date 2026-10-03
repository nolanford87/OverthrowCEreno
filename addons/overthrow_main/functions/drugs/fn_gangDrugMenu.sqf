/*
    Description:
    A gang member or leader's bulk drug deals (talking to them, OT_fnc_talkToCiv). With OT_drugGangRep
    or more rep with the gang: buy ganja or blow wholesale (OT_fnc_gangWholesaleBuy) or sell them all
    of yours in bulk (OT_fnc_gangBulkSell). Without it they tell the player to earn their trust.

    Parameters:
        _this # 0: OBJECT - Gang member
        _this # 1: NUMBER - Gang id

    Usage: [_civ, _gangid] call OT_fnc_gangDrugMenu;
*/

params ["_civ", "_gangid"];

private _rep = player getVariable [format ["gangrep%1", _gangid], 0];
if (_rep < OT_drugGangRep) exitWith {
    [
        player,
        _civ,
        ["Can we do business in bulk?", format ["We don't know you well enough for that. Do some work for us first (+%1 rep needed, you have %2)", OT_drugGangRep, _rep]],
        { OT_interactingWith setVariable ["OT_Talking", false, true] }
    ] call OT_fnc_doConversation;
};

private _options = [format ["<t align='center' size='1.4'>Bulk deals</t><br/><t align='center' size='0.8'>Your money: $%1</t>", [player getVariable ["money", 0], 1, 0, true] call CBA_fnc_formatNumber]];
{
    private _cls = _x;
    private _lot = OT_drugWholesaleLots getOrDefault [_cls, 0];
    private _each = [_gangid, _cls, "buy"] call OT_fnc_gangDrugPrice;
    _options pushBack [
        format ["Buy %1 %2 wholesale ($%3, $%4 each)", _lot, _cls call OT_fnc_weaponGetName, _lot * _each, _each],
        { _this call OT_fnc_gangWholesaleBuy },
        [_gangid, _cls]
    ];
} forEach ["OT_Ganja", "OT_Blow"];
_options pushBack [
    format [
        "Sell them all your ganja and blow ($%1 / $%2 each)",
        [_gangid, "OT_Ganja", "sell"] call OT_fnc_gangDrugPrice,
        [_gangid, "OT_Blow", "sell"] call OT_fnc_gangDrugPrice
    ],
    { _this call OT_fnc_gangBulkSell },
    [_gangid]
];
_options pushBack ["Cancel", {}];
_options call OT_fnc_playerDecision;
