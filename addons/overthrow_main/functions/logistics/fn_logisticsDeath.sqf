/*
    Description:
    What a freight player's death does to their haul (OT_fnc_logisticsTrack): killed by a gang
    member, the gang takes the cargo ("hijacked"); killed while wanted by anyone else, the occupier
    seizes it ("seized"); any other death leaves the job running (""). A gang member is a unit with a
    gang id (OT_gangid, gang camps and OT_fnc_logisticsHijack) or a criminal / gang leader.

    Parameters:
        _this # 0: OBJECT - Killer (as OT_fnc_deathHandler worked it out), objNull if none
        _this # 1: BOOL - The player was wanted (not captive) when they died

    Usage: [_killer, _wanted] call OT_fnc_logisticsDeath;

    Returns: STRING - "hijacked", "seized" or "" (the job goes on)
*/

params [["_killer", objNull], ["_wanted", false]];

if (!isNull _killer && { !isPlayer _killer } && {
    ((_killer getVariable ["OT_gangid", -1]) isEqualType 0 && { (_killer getVariable ["OT_gangid", -1]) > -1 })
    || { _killer getVariable ["criminal", false] }
    || { _killer getVariable ["crimleader", false] }
}) exitWith { "hijacked" };
if (_wanted) exitWith { "seized" };
""
