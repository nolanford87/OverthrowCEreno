/*
    Description:
    The wait before a delivery to a base sets off (8 real minutes, OT_deliveryDelay changes it for the
    QA tests). Meanwhile the base doesn't spawn the vehicle itself: it's on the base's list already
    but still to come (OT_pendingDeliveries, read by OT_fnc_spawnNATOObjective).

    Parameters:
        _this # 0: STRING - Base name
        _this # 1: STRING - Vehicle class
        _this # 2: STRING - "vehgarrison" (a ground vehicle) or "airpatrol" (an aircraft)
        _this # 3: NUMBER - Seconds to wait

    Usage: [_name, _type, "vehgarrison", _delay] call OT_fnc_NATOdeliveryWait;
*/

params ["_name", "_type", "_list", "_delay"];

if (isNil "OT_pendingDeliveries") then { OT_pendingDeliveries = [] };
private _entry = [_name, _type, _list];
OT_pendingDeliveries pushBack _entry;
sleep _delay;
OT_pendingDeliveries deleteAt (OT_pendingDeliveries find _entry);
