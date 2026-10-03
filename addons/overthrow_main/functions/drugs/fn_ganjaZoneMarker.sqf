/*
    Description:
    Puts a revealed wild ganja zone on everyone's map: a green area 80 m across.

    Parameters:
        _this # 0: NUMBER - Zone id

    Usage: [_id] call OT_fnc_ganjaZoneMarker; (server)
*/

params ["_id"];
private _zones = server getVariable ["ganjaZones", []];
private _index = _zones findIf { (_x select 0) isEqualTo _id };
if (_index < 0) exitWith {};
private _name = format ["ganjazone%1", _id];
deleteMarker _name;
private _mrk = createMarkerLocal [_name, (_zones select _index) select 1];
_mrk setMarkerShapeLocal "ELLIPSE";
_mrk setMarkerSizeLocal [OT_ganjaZoneRadius, OT_ganjaZoneRadius];
_mrk setMarkerBrushLocal "SolidBorder";
_mrk setMarkerColorLocal "ColorGreen";
_mrk setMarkerAlpha 0.6; // The last, global command sends it to everyone
