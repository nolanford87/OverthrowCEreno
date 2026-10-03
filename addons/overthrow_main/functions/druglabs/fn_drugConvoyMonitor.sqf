/*
    Description:
    Watches a gang chemical convoy (OT_fnc_drugConvoyStart), every 2 seconds. They turn on the
    attackers (OT_fnc_drugConvoyHostile) once someone not with them fires within about 70 m of one
    of them, one of them is killed, knocked out or hurt, or a vehicle of theirs is damaged.
    The run is over once the truck is gone or wrecked, the crew are all dead, it reaches where it was
    going, after OT_drugConvoyTimeout (30 min), or after 5 minutes with no player within 3 km. Then
    the intel markers go, and everything is deleted once no player is within 500 m
    (OT_fnc_drugConvoyCleanup); a truck a player took is left alone.

    Parameters:
        _this # 0: HASHMAP - The convoy

    Usage: [_convoy] spawn OT_fnc_drugConvoyMonitor; (server)
*/

params ["_convoy"];

private _id = _convoy get "id";
private _group = _convoy get "group";
// Shots near any of them (FiredNear: on the server, where they're local)
{
    _x addEventHandler ["FiredNear", {
        params ["_unit", "_firer"];
        if (!isNull _firer && { (group _firer) isNotEqualTo (group _unit) }) then { _unit setVariable ["OT_drugConvoyShotAt", true] };
    }];
} forEach (_convoy get "units");

private _lastNear = time;
while { !(_convoy get "over") } do {
    sleep 2;
    if (_convoy get "cleaned") exitWith {};
    private _units = _convoy get "units";
    private _alive = _units select { alive _x };
    private _truck = _convoy get "truck";
    private _vehicles = [_truck, _convoy get "escort"] select { !isNull _x };

    if !(_convoy get "hostile") then {
        private _attacked = (count _alive) < (count _units)
            || { (_alive findIf { (_x getVariable ["OT_drugConvoyShotAt", false]) || { (damage _x) > 0.1 } || { _x getVariable ["ACE_isUnconscious", false] } }) > -1 }
            || { (_vehicles findIf { !alive _x || { (damage _x) > 0.05 } || { (selectMax (((getAllHitPointsDamage _x) param [2, []]) + [0])) > 0.1 } }) > -1 };
        if (_attacked) then { [_convoy] call OT_fnc_drugConvoyHostile };
    };

    if ((allPlayers findIf { (_x distance2D _truck) < 3000 }) > -1) then { _lastNear = time };
    private _reason = call {
        if (isNull _truck || { !alive _truck }) exitWith { "wrecked" };
        if (_alive isEqualTo []) exitWith { "crew dead" };
        if ((_truck distance2D (_convoy get "to")) < 60) exitWith { "arrived" };
        if ((time - (_convoy get "started")) > OT_drugConvoyTimeout) exitWith { "timed out" };
        if ((time - _lastNear) > 300) exitWith { "nobody near" };
        ""
    };
    if (_reason isNotEqualTo "") then {
        _convoy set ["over", true];
        _convoy set ["reason", _reason];
    };
};
missionNamespace setVariable [format ["OT_drugConvoyOver_%1", _id], true, true];
diag_log format ["Overthrow: chemical convoy %1 over (%2)", _id, _convoy get "reason"];

// Gone once nobody is near
waitUntil { sleep 10; [_convoy] call OT_fnc_drugConvoyCleanup };
