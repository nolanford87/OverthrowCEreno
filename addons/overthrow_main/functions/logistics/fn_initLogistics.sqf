/*
    Description:
    Starts freight on the server: picks (or loads) the freight brokers (OT_fnc_logisticsBrokers),
    registers a spawner for each (OT_fnc_spawnBroker) and puts them on everyone's map.

    Usage: [] spawn OT_fnc_initLogistics; (server)
*/

if (!isServer) exitWith {};
waitUntil { sleep 1; !isNil "OT_economyLoadDone" };

private _brokers = [] call OT_fnc_logisticsBrokers;
// Offers saved from an earlier session are stale (serverTime starts again at 0)
{ server setVariable [format ["logisticsOffers%1", _x select 0], [], true] } forEach _brokers;
// A civilian car icon where the game has one, a plain box otherwise
private _type = "ot_Broker"; // A box truck, in the shops' style; sized with zoom like them (OT_fnc_mapHandler)
{
    _x params ["_id", "_name", "_pos"];
    [_pos, OT_fnc_spawnBroker, [_id]] call OT_fnc_registerSpawner;

    private _mrkName = format ["logistics_%1", _id];
    deleteMarker _mrkName;
    private _mrk = createMarkerLocal [_mrkName, _pos];
    _mrk setMarkerShapeLocal "ICON";
    _mrk setMarkerTypeLocal _type;
    _mrk setMarkerColorLocal "ColorWhite";
    _mrk setMarkerTextLocal "Freight broker";
    _mrk setMarkerAlpha 0.8; // The last, global command sends it to everyone
} forEach _brokers;

OT_logisticsInitDone = true;
publicVariable "OT_logisticsInitDone";
