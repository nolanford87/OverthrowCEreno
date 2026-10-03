/*
    Description:
    Talking to a gang member or leader about their turf (OT_fnc_talkToCiv): what their turf is, our
    drug operations on it (drugOps), the deal if there is one (what's been paid) or how they feel
    about it (OT_fnc_drugTurfMood), and the choice: pay their cut, OT_drugTurfDealFee now (the
    player's money) and OT_drugTurfCut of everything we make there from then on
    (OT_fnc_drugTurfDeal on the server), or end a standing deal.

    Parameters:
        _this # 0: OBJECT - Gang member
        _this # 1: NUMBER - Gang id

    Usage: [_civ, _gangid] call OT_fnc_drugTurfMenu;
*/

params ["_civ", "_gangId"];

private _gang = OT_civilians getVariable [format ["gang%1", _gangId], []];
if ((count _gang) isNotEqualTo 9) exitWith {};
private _name = _gang select 8;
private _deal = [_gangId] call OT_fnc_drugTurfDealOf;
private _ops = (server getVariable ["drugOps", []]) select { (([_x select 2] call OT_fnc_drugTurfGang) param [0, -1]) isEqualTo _gangId };
private _pct = (str (round (OT_drugTurfCut * 100))) + "%";

private _header = format ["<t align='center' size='1.4'>%1's turf</t><br/><t align='center' size='0.8'>%2 km round their camp. Our operations there: %3</t>", _name, OT_drugTurfRadius / 1000, if (_ops isEqualTo []) then { "none" } else { (_ops apply { _x select 0 }) joinString ", " }];
if (_deal isNotEqualTo []) then {
    _header = _header + format ["<br/><t align='center' size='0.8'>Deal: they take %1 of what we make there ($%2 and %3 blow so far)</t>", _pct, [_deal select 2, 1, 0, true] call CBA_fnc_formatNumber, _deal select 3];
} else {
    _header = _header + format ["<br/><t align='center' size='0.8'>No deal: they're %1 about drugs on their turf</t>", [[_gangId] call OT_fnc_drugTurfAngerOf] call OT_fnc_drugTurfMood];
};

private _options = [_header];
if (_deal isEqualTo []) then {
    _options pushBack [
        format ["Pay their cut: $%1 now and %2 of everything we make on their turf", [OT_drugTurfDealFee, 1, 0, true] call CBA_fnc_formatNumber, _pct],
        {
            params ["_civ", "_gangId", "_pct"];
            if ((player getVariable ["money", 0]) < OT_drugTurfDealFee) exitWith { "You cannot afford that" call OT_fnc_notifyMinor };
            [
                player,
                _civ,
                [format ["I'll pay your cut: $%1 now and %2 of what we make here", [OT_drugTurfDealFee, 1, 0, true] call CBA_fnc_formatNumber, _pct], "Deal. Keep paying and we'll leave your business alone"],
                {
                    params ["_gangId"];
                    [_gangId, getPlayerUID player, true] remoteExec ["OT_fnc_drugTurfDeal", 2, false];
                    OT_interactingWith setVariable ["OT_Talking", false, true];
                },
                [_gangId]
            ] call OT_fnc_doConversation;
        },
        [_civ, _gangId, _pct]
    ];
} else {
    _options pushBack [
        "End the deal (they'll want their turf respected again)",
        {
            params ["_gangId"];
            [_gangId, getPlayerUID player, false] remoteExec ["OT_fnc_drugTurfDeal", 2, false];
        },
        [_gangId]
    ];
};
_options pushBack ["Cancel", {}];
_options call OT_fnc_playerDecision;
