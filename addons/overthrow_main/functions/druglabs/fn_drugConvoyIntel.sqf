/*
    Description:
    Intel on a gang chemical convoy for this player (OT_fnc_drugConvoyStart): a rough marker on the
    truck (somewhere within 150 m of it, moved every 20 seconds) and one where it's going, until the
    run is over (OT_drugConvoyOver_<id>) or the truck is gone.

    Parameters:
        _this # 0: STRING - Convoy id
        _this # 1: OBJECT - Its truck
        _this # 2: ARRAY - Where it's going

    Usage: [_id, _truck, _toPos] remoteExec ["OT_fnc_drugConvoyIntel", _player];
*/

params ["_id", "_truck", "_toPos"];

if (!hasInterface) exitWith {};
[_id, _truck, _toPos] spawn {
    params ["_id", "_truck", "_toPos"];
    private _mrk = createMarkerLocal [format ["drugconvoy_%1", _id], (getPosATL _truck) getPos [random 150, random 360]];
    _mrk setMarkerShapeLocal "ICON";
    _mrk setMarkerTypeLocal "mil_warning";
    _mrk setMarkerColorLocal "ColorOPFOR";
    _mrk setMarkerTextLocal "Chemical shipment";
    private _to = createMarkerLocal [format ["drugconvoy_%1_to", _id], _toPos];
    _to setMarkerShapeLocal "ICON";
    _to setMarkerTypeLocal "mil_end";
    _to setMarkerColorLocal "ColorOPFOR";
    _to setMarkerTextLocal "Shipment's destination";
    private _next = time + 20;
    waitUntil {
        sleep 2;
        if (time > _next && { !isNull _truck }) then {
            _next = time + 20;
            _mrk setMarkerPosLocal ((getPosATL _truck) getPos [random 150, random 360]);
        };
        (missionNamespace getVariable [format ["OT_drugConvoyOver_%1", _id], false]) || { isNull _truck } || { !alive _truck }
    };
    deleteMarkerLocal _mrk;
    deleteMarkerLocal _to;
};
