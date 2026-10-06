/*
    Description:
    The occupier compounds' closed gates worked by the occupier (OT_fnc_officeSpawnItems registers each locked
    one, shut): a gate swings open for the occupier's men and vehicles within 12 m of it, and for those within
    40 m going somewhere (the engine's path finding plans no way through a shut gate, so a man inside ordered
    out, or a truck outside ordered in, would never come up to it), and shuts again 10 s after the last; players can't open it (it stays locked, OT_fnc_officeBreach blows it open). A gate
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
            private _theirs = ((_g nearEntities [["CAManBase", "LandVehicle"], 40]) findIf {
                alive _x && { (side _x) isEqualTo blufor } && {
                    (_x distance _g) < 12 || { (speed _x) > 1 } || { (((expectedDestination _x) select 0) distance2D _x) > 5 && { ((expectedDestination _x) select 1) isNotEqualTo "DoNotPlan" } }
                }
            }) > -1;
            private _open = _g getVariable ["OT_gateOpen", false];
            if (_theirs) then { _g setVariable ["OT_gateUntil", time + 10] };
            if (_theirs isNotEqualTo _open && { _theirs || { time > (_g getVariable ["OT_gateUntil", 0]) } }) then {
                _g setVariable ["OT_gateOpen", _theirs];
                { if ("sound_source" in toLower _x) then { _g animateSource [_x, [0, 1] select _theirs] } } forEach (("true" configClasses (configOf _g >> "AnimationSources")) apply { configName _x });
            };
        } forEach OT_officeGates;
    }, 1] call CBA_fnc_addPerFrameHandler;
};
if (!isNull _gate) then {
    { if ("sound_source" in toLower _x) then { _gate animateSource [_x, 0, true] } } forEach (("true" configClasses (configOf _gate >> "AnimationSources")) apply { configName _x });
    OT_officeGates pushBackUnique _gate;
};
