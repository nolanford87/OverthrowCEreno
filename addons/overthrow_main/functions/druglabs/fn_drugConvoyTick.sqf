/*
    Description:
    Whether to send a gang chemical convoy (OT_fnc_initDrugLabs, every 30 seconds): none running, and
    its time has come (OT_drugConvoyNext: 30-60 real minutes after the last one set off, 15-30 after
    the server started). The gang is one with a player within OT_drugConvoyRange (2 km) of its camp,
    picked at random; with none, it waits until there is one.

    Usage: [] call OT_fnc_drugConvoyTick; (server)

    Returns: BOOL - A convoy set off
*/

if ((missionNamespace getVariable ["OT_drugConvoy", []]) isNotEqualTo []) exitWith { false };
if (time < (missionNamespace getVariable ["OT_drugConvoyNext", 0])) exitWith { false };

private _players = allPlayers - (entities "HeadlessClient_F");
private _gangs = [];
{
    {
        private _g = OT_civilians getVariable [format ["gang%1", _x], []];
        if ((count _g) isEqualTo 9) then {
            private _camp = _g select 4;
            if ((_players findIf { (_x distance2D _camp) < OT_drugConvoyRange }) > -1) then { _gangs pushBack _x };
        };
    } forEach (OT_civilians getVariable [format ["gangs%1", _x], []]);
} forEach OT_allTowns;
if (_gangs isEqualTo []) exitWith { false };

private _started = [selectRandom _gangs] call OT_fnc_drugConvoyStart;
OT_drugConvoyWait params ["_min", "_max"];
OT_drugConvoyNext = time + _min + (random (_max - _min));
_started isNotEqualTo [];
