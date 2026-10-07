/*
    Description:
    The occupier compounds' closed gates worked by the occupier (OT_fnc_officeSpawnItems registers each locked
    one, shut): a gate swings open for the occupier's men and vehicles within 12 m of it, and for those within
    40 m going somewhere (the engine's path finding plans no way through a shut gate, so a man inside ordered
    out, or a truck outside ordered in, would never come up to it), and shuts again 10 s after the last (while it's
    open, one standing waiting plans his way again: one planned while it was shut stops at it); never
    for the compound's own garrison (its patrol stays inside the walls, even chasing someone; one that's ended up
    outside it does get back in), the town's
    gendarmerie (it comes to the gate from the street) or a static weapon's crew; players can't open it (it stays locked, OT_fnc_officeBreach blows it open). A gate
    unlocked (breached, or the town taken: OT_fnc_officeDoors) is left alone. One check a second for all of
    them (OT_officeGates). Server.

    Parameters:
        _this # 0: OBJECT - (Optional) A gate to work; none just starts the check

    Usage: [_gate] call OT_fnc_officeGates;

    Returns: Nothing
*/

params [["_gate", objNull, [objNull]]];

if (isNil "OT_officeGates") then {
    OT_officeGates = [];
    [{
        OT_officeGates = OT_officeGates select { !isNull _x };
        {
            private _g = _x;
            if !(_g getVariable ["OT_officeGate", false]) then { continue };
            // The occupier's men and vehicles that may open it: not the compound's own garrison (its patrol hunts
            // inside the walls only, OT_fnc_officeGarrison), the town's gendarmerie (it comes to the gate from the
            // street) or a static weapon's crew
            private _near = (_g nearEntities [["CAManBase", "LandVehicle"], 40]) select {
                private _who = [_x, effectiveCommander _x] select (_x isKindOf "LandVehicle");
                alive _x && { (side _x) isEqualTo blufor } && { !(_x isKindOf "StaticWeapon") } && { !isNull _who }
                    && { (_who getVariable ["garrison", ""]) isEqualTo "" }
                    && {
                        // A compound guard only to come back in, if he's ended up outside his compound
                        private _home = _who getVariable ["OT_compoundGuard", ""];
                        _home isEqualTo "" || { [getPosATL _who, server getVariable [format ["compoundarea%1", _home], []]] call OT_fnc_officeOutside }
                    }
            };
            private _theirs = (_near findIf {
                (_x distance _g) < 12 || { (speed _x) > 1 } || { (((expectedDestination _x) select 0) distance2D _x) > 5 && { ((expectedDestination _x) select 1) isNotEqualTo "DoNotPlan" } }
            }) > -1;
            private _open = _g getVariable ["OT_gateOpen", false];
            if (_theirs) then { _g setVariable ["OT_gateUntil", time + 10] };
            if (_theirs isNotEqualTo _open && { _theirs || { time > (_g getVariable ["OT_gateUntil", 0]) } }) then {
                _g setVariable ["OT_gateOpen", _theirs];
                { if ("sound_source" in toLower _x) then { _g animateSource [_x, [0, 1] select _theirs] } } forEach (("true" configClasses (configOf _g >> "AnimationSources")) apply { configName _x });
            };
            // While it's open, one standing waiting with somewhere to go plans his way again (once every 8 s): a way
            // planned while it was shut, or half shut, stops at it
            if (_open) then {
                {
                    private _m = effectiveCommander _x;
                    private _to = (expectedDestination _m) select 0;
                    if ((speed _x) < 0.5 && { (_to distance2D _m) > 5 } && { ((expectedDestination _m) select 1) isNotEqualTo "DoNotPlan" } && { time > (_m getVariable ["OT_gateReplanAt", 0]) }) then {
                        _m setVariable ["OT_gateReplanAt", time + 8];
                        private _grp = group _m;
                        if (_m isEqualTo leader _grp && { (count waypoints _grp) > (currentWaypoint _grp) } && { (currentWaypoint _grp) > 0 }) then {
                            _grp setCurrentWaypoint [_grp, currentWaypoint _grp];
                        } else {
                            _m doMove _to;
                        };
                    };
                } forEach _near;
            };
        } forEach OT_officeGates;
    }, 1] call CBA_fnc_addPerFrameHandler;
};
if (!isNull _gate) then {
    { if ("sound_source" in toLower _x) then { _gate animateSource [_x, 0, true] } } forEach (("true" configClasses (configOf _gate >> "AnimationSources")) apply { configName _x });
    OT_officeGates pushBackUnique _gate;
};
