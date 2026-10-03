/*
    Description:
    A client's drug labs (OT_fnc_initPlayerLocal, after initVar): the numbers (OT_fnc_drugLabsVars)
    and, once the server has picked them (OT_fnc_drugLabSites, before it finishes starting), the labs
    as businesses here too (OT_fnc_drugLabsAdd). The server and a host have them already.

    Usage: [] spawn OT_fnc_drugLabsLocal; (client)
*/

if (isServer) exitWith {};
call OT_fnc_drugLabsVars;
OT_drugLabs = [];
waitUntil { sleep 1; !isNil "OT_serverInitDone" || { (server getVariable ["drugLabSites", []]) isNotEqualTo [] } };
[server getVariable ["drugLabSites", []]] call OT_fnc_drugLabsAdd;
