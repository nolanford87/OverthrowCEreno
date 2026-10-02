/*
    Description:
    Puts a hunting spot on everyone's map: a yellow-green area 400 m across (OT_ColorHunting).

    Parameters:
        _this # 0: NUMBER - Spot index

    Usage: [_index] call OT_fnc_huntingRevealMarker; (server)
*/

params ["_index"];
private _pos = (server getVariable ["huntingSpots", []]) param [_index, []];
if (_pos isEqualTo []) exitWith {};
private _name = format ["huntspot%1", _index];
deleteMarker _name;
private _mrk = createMarkerLocal [_name, _pos];
_mrk setMarkerShapeLocal "ELLIPSE";
_mrk setMarkerSizeLocal [200, 200];
_mrk setMarkerBrushLocal "SolidBorder";
_mrk setMarkerColorLocal "OT_ColorHunting";
_mrk setMarkerAlpha 0.45; // The last, global command sends it to everyone
