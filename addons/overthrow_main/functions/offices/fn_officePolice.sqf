/*
    Description:
    The resistance's police station at a town's mayor's office (the user's, 2026-10-30): there's no police station
    building to place any more; once the town is the resistance's, its police station is unlocked at the mayor's
    office for the old station's price ($2,500, the player's money), bringing its first 2 police
    (OT_fnc_initPoliceStation at the office), and then managed there (OT_fnc_policeDialog). The main menu's
    building button does it while the player stands in the office's area (OT_fnc_officeArea). Local, a player.

    Parameters:
        _this # 0: STRING - "near": the town whose office of ours the player is at, or ""; "use": unlock or
            manage it

    Usage: if ((["near"] call OT_fnc_officePolice) isNotEqualTo "") then { ["use"] call OT_fnc_officePolice };

    Returns: STRING for "near", nothing for "use"
*/

params [["_mode", "near", [""]]];

private _price = 2500;
private _town = player call OT_fnc_nearestTown;
private _office = ([_town] call OT_fnc_officeLayout) param [0, []];
private _at = _office isNotEqualTo [] && { _town in (server getVariable ["NATOabandoned", []]) }
    && { [player, [_town] call OT_fnc_officeArea, ASLToAGL (_office select 1)] call OT_fnc_officeInArea };
if (_mode isEqualTo "near") exitWith { ["", _town] select _at };
if (!_at) exitWith {};

if ((server getVariable [format ["policepos%1", _town], []]) isNotEqualTo []) exitWith { [] call OT_fnc_policeDialog };
if ((player getVariable ["money", 0]) < _price) exitWith {
    format ["You need $%1 to set up a police station here", [_price, 1, 0, true] call CBA_fnc_formatNumber] call OT_fnc_notifyMinor;
};
[-_price] call OT_fnc_money;
[ASLToAGL (_office select 1), objNull] remoteExec ["OT_fnc_initPoliceStation", 2];
format ["Police station set up at the mayor's office in %1", _town] call OT_fnc_notifyGood;
