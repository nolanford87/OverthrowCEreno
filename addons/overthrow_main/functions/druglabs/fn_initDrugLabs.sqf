/*
    Description:
    Starts blow (drugs slice 2) on the server once the economy has loaded. The lab sites were picked
    and made businesses before the economy loaded (OT_fnc_drugLabSites); here their sheds go up (every
    session: they aren't saved, OT_fnc_drugLabSite), the saved lists "drugOps" (drug operations, shared
    with the dispensaries) and "precursorsAt" (industrial businesses making precursors) are made if
    missing, and a loop runs every 30 seconds: owned labs on drugOps with a container
    (OT_fnc_drugLabRegister, OT_fnc_drugLabContainer), and the gangs' chemical convoys
    (OT_fnc_drugConvoyTick). Labs cook and businesses make precursors in the business cycle
    (OT_fnc_GUERLoop: OT_fnc_drugLabCycle, OT_fnc_drugPrecursorCycle).

    Usage: [] spawn OT_fnc_initDrugLabs; (server)
*/

if (!isServer) exitWith {};
waitUntil { sleep 1; !isNil "OT_economyLoadDone" };
if (isNil "OT_drugLabSites") then { [] call OT_fnc_drugLabSites }; // Picked before the economy loaded (OT_fnc_initOverthrow)

if (isNil { server getVariable "drugOps" }) then { server setVariable ["drugOps", [], true] };
if (isNil { server getVariable "precursorsAt" }) then { server setVariable ["precursorsAt", [], true] };

OT_drugLabSheds = createHashMap;
{ OT_drugLabSheds set [_x select 0, _x call OT_fnc_drugLabSite] } forEach OT_drugLabSites;

OT_drugConvoy = [];
OT_drugConvoyNext = time + ((OT_drugConvoyWait select 0) / 2) + (random ((OT_drugConvoyWait select 0) / 2));

OT_drugLabsInitDone = true;
publicVariable "OT_drugLabsInitDone";

while { true } do {
    sleep 30;
    private _owned = server getVariable ["GEURowned", []];
    {
        if (_x in _owned) then {
            _x call OT_fnc_drugLabRegister;
            _x call OT_fnc_drugLabContainer;
        };
    } forEach OT_drugLabs;
    [] call OT_fnc_drugConvoyTick;
};
