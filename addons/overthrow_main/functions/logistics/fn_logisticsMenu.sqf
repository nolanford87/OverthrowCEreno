/*
    Description:
    A freight broker's contracts (talking to him, OT_fnc_talkToCiv): his 3 offers (OT_fnc_logisticsOffers)
    and, when a gang works near him, sometimes a smuggling contract (OT_fnc_logisticsIllegalOffers),
    marked ILLEGAL, with the gang's name. Picking one goes through accepting it (OT_fnc_logisticsAccept):
    a contraband add-on if it has one, collateral for illegal work, then whether to bring your own
    vehicle or rent his (van $150 for up to 2 crates, truck $400 for more). One contract at a time.

    Parameters:
        _this # 0: STRING - Broker id

    Usage: [_brokerId] call OT_fnc_logisticsMenu; (client)
*/

params ["_brokerId"];

// The offers may have to come from the server: wait for them out of the menu's (unscheduled) call
if (!canSuspend) exitWith { _this spawn OT_fnc_logisticsMenu };

if ((player getVariable ["OT_logisticsActive", ""]) isNotEqualTo "") exitWith {
    "Finish your current freight contract first" call OT_fnc_notifyMinor;
};

private _broker = (server getVariable ["logisticsBrokers", []]) select { (_x select 0) isEqualTo _brokerId };
private _name = "Freight";
if (_broker isNotEqualTo []) then { _name = (_broker select 0) select 1 };

"Checking the freight board..." call OT_fnc_notifyMinor;
private _offers = [_brokerId] call OT_fnc_logisticsOffers;
if (_offers isEqualTo []) exitWith { "No freight contracts right now, come back later" call OT_fnc_notifyMinor };

private _contrabandNames = createHashMapFromArray [["drugs", "drugs"], ["weapons", "weapons"], ["turtles", "poached goods"]];
private _header = format ["<t align='center' size='2'>%1</t><br/><br/><t align='center' size='0.8'>Freight contracts, new ones every 15 minutes", _name];
// Illegal work on the board: whose it is
private _gangId = (_offers select { ((_x param [14, ""]) isEqualType 0) }) param [0, []] param [14, ""];
if (_gangId isEqualType 0) then {
    _header = _header + format ["<br/><t color='#ff8080'>%1 has illegal work going through here</t>", (OT_civilians getVariable [format ["gang%1", _gangId], []]) param [8, "A gang"]];
};
private _options = [_header];
{
    _x params ["", "_fromPos", "", "_toPos", "_toName", "_crates", "_size", "_pay", "_time"];
    private _km = round ((_fromPos distance2D _toPos) / 1000);
    private _text = "";
    if ((_x param [11, ""]) isEqualTo "smuggle") then {
        _text = format [
            "ILLEGAL: smuggle %1 crate%2 of %3 to %4 (%5 km): $%6, %7 min",
            _crates, ["", "s"] select (_crates > 1), _contrabandNames getOrDefault [_x param [12, ""], "contraband"],
            _toName, _km, _pay, ceil (_time / 60)
        ];
    } else {
        _text = format [
            "Haul %1 crate%2 to %3 (%4 km): $%5, %6 min [%7]%8",
            _crates, ["", "s"] select (_crates > 1), _toName, _km, _pay, ceil (_time / 60), _size,
            ["", " + illegal option"] select ((_x param [13, []]) isNotEqualTo [])
        ];
    };
    _options pushBack [_text, OT_fnc_logisticsAccept, [_x]];
} forEach (_offers select [0, 4]);
_options pushBack ["Cancel", {}];
_options call OT_fnc_playerDecision;
