/*
    Description:
    A farm's goat, sheep or hen was killed (Killed event, server): it counts against the farm until it
    comes back (OT_fnc_huntingAvailable), and if a player killed it outside a hunting spot, the nearest
    town loses 1 resistance support.

    Parameters:
        _this # 0: OBJECT - The animal
        _this # 1: OBJECT - Killer
        _this # 2: OBJECT - Instigator

    Usage: (Killed event handler)
*/

params ["_animal", "_killer", "_instigator"];

[_animal getVariable ["OT_huntKey", ""], -1] call OT_fnc_huntingAvailable;

private _shooter = [_killer, _instigator] select (!isNull _instigator);
if (!isNull _shooter && { !(_shooter isKindOf "CAManBase") }) then { _shooter = effectiveCommander _shooter };
if (isNull _shooter || { !isPlayer _shooter }) exitWith {};
if (((getPosATL _animal) call OT_fnc_inHuntingSpot) > -1) exitWith {}; // Fair game in a hunting spot

private _town = _animal call OT_fnc_nearestTown;
[_town, -1, format ["Killed a farmer's livestock near %1", _town], _shooter] call OT_fnc_support;
