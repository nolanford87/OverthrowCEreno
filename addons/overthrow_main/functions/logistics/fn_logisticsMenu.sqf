/*
    Description:
    A freight broker's contracts (talking to him, OT_fnc_talkToCiv): his 3 offers (OT_fnc_logisticsOffers),
    then whether to bring your own vehicle or rent his (van $150 for up to 2 crates, truck $400 for
    more). The server takes the contract off the board and starts the haul (OT_fnc_logisticsClaim,
    OT_fnc_logisticsStart). One contract at a time.

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
private _name = [(_broker select 0) select 1, "Freight"] select (_broker isEqualTo []);

"Checking the freight board..." call OT_fnc_notifyMinor;
private _offers = [_brokerId] call OT_fnc_logisticsOffers;
if (_offers isEqualTo []) exitWith { "No freight contracts right now, come back later" call OT_fnc_notifyMinor };

private _options = [format ["<t align='center' size='2'>%1</t><br/><br/><t align='center' size='0.8'>Freight contracts, new ones every 15 minutes", _name]];
{
    _x params ["", "_fromPos", "", "_toPos", "_toName", "_crates", "_size", "_pay", "_time"];
    _options pushBack [
        format [
            "Haul %1 crate%2 to %3 (%4 km): $%5, %6 min [%7]",
            _crates, ["", "s"] select (_crates > 1), _toName,
            round ((_fromPos distance2D _toPos) / 1000), _pay, ceil (_time / 60), _size
        ],
        {
            params ["_contract"];
            private _fee = [400, 150] select ((_contract select 6) isEqualTo "van");
            private _vehicle = ["truck", "van"] select ((_contract select 6) isEqualTo "van");
            private _accept = {
                params ["_contract", "_rental", "_fee"];
                if ((player getVariable ["OT_logisticsActive", ""]) isNotEqualTo "") exitWith {
                    "Finish your current freight contract first" call OT_fnc_notifyMinor;
                };
                if (_rental && { (player getVariable ["money", 0]) < _fee }) exitWith {
                    "You cannot afford the rental" call OT_fnc_notifyMinor;
                };
                if (_rental) then { [-_fee] call OT_fnc_money };
                [_contract select 10, _contract select 0, player, _rental, [0, _fee] select _rental] remoteExec ["OT_fnc_logisticsClaim", 2];
            };
            [
                format ["<t align='center' size='1.2'>%1 crate%2 to %3</t><br/><br/><t align='center' size='0.8'>$%4 on delivery, %5 minutes", _contract select 5, ["", "s"] select ((_contract select 5) > 1), _contract select 4, _contract select 7, ceil ((_contract select 8) / 60)],
                ["Use your own vehicle", _accept, [_contract, false, 0]],
                [format ["Rent a %1 ($%2)", _vehicle, _fee], _accept, [_contract, true, _fee]],
                ["Cancel", {}]
            ] call OT_fnc_playerDecision;
        },
        [_x]
    ];
} forEach _offers;
_options pushBack ["Cancel", {}];
_options call OT_fnc_playerDecision;
