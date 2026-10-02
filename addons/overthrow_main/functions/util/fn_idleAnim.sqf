/*
    Description:
    Keeps a standing NPC (freight broker, fisherman) idling in place: loops small standing idle
    animations, a random one each time the last ends, played for everyone (also players joining
    later). The unit doesn't move or react (its AI's animation and movement are off).

    Parameters:
        _this # 0: OBJECT - Unit (local, i.e. created on the server)
        _this # 1: ARRAY - (Optional) Animations to pick from

    Usage: [_unit] call OT_fnc_idleAnim;
*/

params ["_unit", ["_anims", ["HubStandingUA_idle1", "HubStandingUA_idle2", "HubStandingUA_idle3", "HubStandingUC_idle1", "HubStandingUC_idle2", "HubStandingUC_idle3"]]];

_unit disableAI "MOVE";
_unit disableAI "ANIM";
_unit setVariable ["OT_idleAnims", _anims];
[_unit, selectRandom _anims] remoteExec ["switchMove", 0, _unit];
_unit addEventHandler ["AnimDone", {
    params ["_unit"];
    if (!alive _unit) exitWith {};
    [_unit, selectRandom (_unit getVariable ["OT_idleAnims", []])] remoteExec ["switchMove", 0, _unit];
}];
