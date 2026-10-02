/*
    Description:
    Settles the illegal side of a freight job as it ends (server, from OT_fnc_logisticsTrack, which pays
    the contract itself, the add-on's pay included). Legal jobs (not in OT_logisticsJobs) are left alone.
    - "delivered": the cash deposit back, +5 reputation with the gang for a smuggling contract, +3 for
      an add-on.
    - Anything else ("late", "lost", "seized", "hijacked"): -5 reputation with the gang, and the
      collateral is lost: the deposit kept, the vehicle impounded by the occupier (OT_fnc_logisticsImpound,
      recoverable at a garage for a big fee) or -15 more reputation.
    The job is taken out of OT_logisticsJobs, so settling it again does nothing.

    The deposit is also kept in the saved server variable "logisticsDeposits" ([UID, $, job id]) while
    the job runs. A player away when their job is delivered gets it back when next online, and so does
    one whose game was saved and loaded mid-job (jobs don't survive a load, the crates and the job are
    gone): OT_fnc_savePlayerData pays back any deposit whose job no longer runs. The gang reputation and
    vehicle aren't at stake after a load.

    Parameters:
        _this # 0: ARRAY - Contract (only its id is used)
        _this # 1: STRING - UID of the player who took it
        _this # 2: STRING - How it ended: "delivered", "late", "lost", "seized" or "hijacked"

    Usage: [_contract, _uid, _result] call OT_fnc_logisticsSettle; (server)

    Returns: BOOL - An illegal job was settled
*/

params ["_contract", "_uid", "_result"];

if (!isServer || { isNil "OT_logisticsJobs" }) exitWith { false };
private _id = _contract select 0;
private _job = OT_logisticsJobs getOrDefault [_id, []];
if (_job isEqualTo []) exitWith { false };
OT_logisticsJobs deleteAt _id;
_job params ["_kind", "_contraband", "_collateral", "_gangId", "_addonCrates", "", "_deposit", "_veh", "_repStake"];

private _player = (allPlayers select { (getPlayerUID _x) isEqualTo _uid }) param [0, objNull];
private _gangName = "The gang";
if (_gangId isEqualType 0) then { _gangName = (OT_civilians getVariable [format ["gang%1", _gangId], []]) param [8, "The gang"] };

// Gang reputation, also for a player who is away (their saved data)
private _addRep = {
    params ["_amount", "_reason"];
    if !(_gangId isEqualType 0) exitWith {};
    if (!isNull _player) exitWith { [_player, _gangId, _amount, _reason] call OT_fnc_gangRep };
    private _key = format ["gangrep%1", _gangId];
    [_uid, _key, ([_uid, _key, 0] call OT_fnc_getOfflinePlayerAttribute) + _amount] call OT_fnc_setOfflinePlayerAttribute;
};

private _deposits = server getVariable ["logisticsDeposits", []];
private _idx = _deposits findIf { (_x select 2) isEqualTo _id };

if (_result isEqualTo "delivered") then {
    // Deposit back now; for a player who is away it stays listed, paid back when they're next online
    if (_idx > -1 && { !isNull _player }) then {
        [(_deposits select _idx) select 1, "Deposit returned"] remoteExec ["OT_fnc_money", _player, false];
        _deposits deleteAt _idx;
    };
    [[3, 5] select (_kind isEqualTo "smuggle"), "contraband delivered"] call _addRep;
} else {
    if (_idx > -1) then { _deposits deleteAt _idx };
    private _lost = "";
    if (_collateral isEqualTo "cash") then { _lost = format [", they keep your $%1 deposit", _deposit] };
    if (_collateral isEqualTo "vehicle") then {
        _lost = [", your vehicle was already gone", format [", %1 impounded your vehicle (recover it at a garage)", OT_NATO_name]] select ([_veh, _uid] call OT_fnc_logisticsImpound);
    };
    if (_collateral isEqualTo "rep") then { _lost = ", and it costs you their trust" };
    [-(5 + _repStake), "contraband lost"] call _addRep;
    if (!isNull _player) then {
        format ["%1 lost their contraband%2", _gangName, _lost] remoteExec ["OT_fnc_notifyBad", _player, false];
    };
};
server setVariable ["logisticsDeposits", _deposits, true];
if (!isNull _veh) then { _veh setVariable ["OT_collateral", nil, true] };
true;
