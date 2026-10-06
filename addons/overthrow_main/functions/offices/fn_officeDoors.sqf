/*
    Description:
    The doors that lead out of a town's occupier compound locked at a tier (its area, OT_fnc_officeCompound):
    every door of a building standing across the area's line (a door's place doesn't say which side it opens
    onto), and of a building inside it each door whose nearest side of the building faces out (1.5 m past it is
    outside the area or within 1 m of the line). The engine's door
    lock ("bis_disabled_Door_<n>"), which the game's and ACE's door actions keep to; the building keeps its
    locked doors in "OT_lockedDoors" for the lockpick (OT_fnc_officeLockNear). A lock opened by a lockpick or
    a charge (OT_fnc_officeUnlock, OT_fnc_officeBreach) comes back when the tier is put up again. None while
    the resistance holds the office or the town, or for tier 0. Kept per town in OT_officeLocked. Called
    with the hides (OT_fnc_officeHide): when the game starts and by OT_fnc_officeApplyLayout. Server.

    Parameters:
        _this # 0: STRING - Town
        _this # 1: NUMBER - Defence tier, 1 to 5; 0 for none

    Usage: [_town, [_town] call OT_fnc_officeTier] call OT_fnc_officeDoors;

    Returns: ARRAY - The doors locked now, [[building, door], ...]
*/

params [["_town", "", [""]], ["_tier", 0, [0]]];

if (isNil "OT_officeLocked") then { OT_officeLocked = createHashMap };
private _theirs = !(server getVariable [format ["officeheld%1", _town], false]) && { !(_town in (server getVariable ["NATOabandoned", []])) };
private _area = if (_theirs) then { ([_town, _tier] call OT_fnc_officeCompound) apply { [_x select 0, _x select 1, 0] } } else { [] };
private _now = [];
if (_area isNotEqualTo []) then {
    private _n = count _area;
    private _centre = [0, 0, 0];
    { _centre = _centre vectorAdd _x } forEach _area;
    _centre = _centre vectorMultiply (1 / _n);
    // How far a point is from the area's line
    private _toEdge = {
        params ["_p"];
        private _d = 1e9;
        for "_i" from 0 to _n - 1 do {
            private _a = _area select _i;
            private _ab = (_area select ((_i + 1) mod _n)) vectorDiff _a;
            private _l = (vectorMagnitude _ab) max 0.01;
            private _t = 0 max (_l min (((_p vectorDiff _a) vectorDotProduct _ab) / _l));
            _d = _d min ((_a vectorAdd (_ab vectorMultiply (_t / _l))) distance2D _p);
        };
        _d
    };
    {
        private _b = _x;
        private _doors = getNumber (configOf _b >> "numberOfDoors");
        if (_doors < 1 || { isObjectHidden _b } || { !isNil { _b getVariable "OT_officeItem" } }) then { continue };
        (boundingBoxReal _b) params ["_mn", "_mx"];
        private _corners = [[_mn select 0, _mn select 1], [_mx select 0, _mn select 1], [_mx select 0, _mx select 1], [_mn select 0, _mx select 1]] apply {
            private _w = _b modelToWorld [_x select 0, _x select 1, 0];
            [_w select 0, _w select 1, 0]
        };
        private _in = { _x inPolygon _area } count _corners;
        if (_in isEqualTo 0) then { continue };
        for "_d" from 1 to _doors do {
            private _lock = _in < 4;
            private _rel = _b selectionPosition [format ["Door_%1_trigger", _d], "Memory"];
            if (!_lock && { _rel isNotEqualTo [0, 0, 0] }) then {
                _rel params ["_dx", "_dy"];
                // Where the door opens onto: 1.5 m past the building's side nearest it
                private _sides = [[_dx - (_mn select 0), [(_mn select 0) - 1.5, _dy]], [(_mx select 0) - _dx, [(_mx select 0) + 1.5, _dy]], [_dy - (_mn select 1), [_dx, (_mn select 1) - 1.5]], [(_mx select 1) - _dy, [_dx, (_mx select 1) + 1.5]]];
                _sides sort true;
                private _w = _b modelToWorld (((_sides select 0) select 1) + [0]);
                _w = [_w select 0, _w select 1, 0];
                _lock = !(_w inPolygon _area) || { ([_w] call _toEdge) < 1 };
            };
            if (_lock) then { _now pushBack [_b, _d] };
        };
    } forEach (nearestObjects [_centre, ["House"], (selectMax (_area apply { _x distance2D _centre })) + 30, true]);
};

private _was = OT_officeLocked getOrDefault [_town, []];
{ _x params ["_b", "_d"]; if (!isNull _b) then { _b setVariable [format ["bis_disabled_Door_%1", _d], 0, true] } } forEach (_was - _now);
{ _x params ["_b", "_d"]; _b setVariable [format ["bis_disabled_Door_%1", _d], 1, true] } forEach _now;
private _buildings = (_was + _now) apply { _x select 0 };
{
    private _b = _x;
    if (!isNull _b) then { _b setVariable ["OT_lockedDoors", (_now select { (_x select 0) isEqualTo _b }) apply { _x select 1 }, true] };
} forEach (_buildings arrayIntersect _buildings);
OT_officeLocked set [_town, _now];
// The town's gates unlocked and swung open once it's the resistance's (OT_fnc_officeGates)
if (!_theirs) then {
    { if ((((_x getVariable ["OT_officeItem", []]) param [0, ""]) isEqualTo _town) && { _x getVariable ["OT_officeGate", false] }) then { [_x, -1, true] call OT_fnc_officeUnlock } } forEach (missionNamespace getVariable ["OT_officeGates", []]);
};
_now
