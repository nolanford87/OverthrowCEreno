/*
    Description:
    Maps a building's floor plan to the RPT, to place things inside it: spawns one 60 m in front of the
    host on open ground, then for every 0.5 m cell of its footprint checks for walls / objects at
    standing height (0.4 m to 1.9 m above its floor) and prints a map, row by row ('#' blocked, '.'
    open floor, ' ' outside), plus its bounding box and building positions, all in the building's own
    coordinates (x across, y along). Lines start "OTPROBE|". The building is deleted afterwards.

    Parameters:
        _this # 0: STRING - Building class, default "Land_i_Shed_Ind_F"

    Usage: ["Land_i_Shed_Ind_F"] spawn OTQA_fnc_probeBuilding;
*/

params [["_cls", "Land_i_Shed_Ind_F"]];

private _pos = (player getPos [60, getDir player]) findEmptyPosition [0, 100, _cls];
if (_pos isEqualTo []) exitWith { hint "Probe: no room for the building here" };
private _b = createVehicle [_cls, _pos, [], 0, "CAN_COLLIDE"];
_b setDir 0;
_b setPosATL [_pos select 0, _pos select 1, 0];
sleep 2;

(boundingBoxReal _b) params ["_min", "_max"];
diag_log format ["OTPROBE|START|%1|bbox %2 %3", _cls, _min, _max];
private _positions = (_b buildingPos -1) apply { (_b worldToModel _x) apply { (round (_x * 10)) / 10 } };
diag_log format ["OTPROBE|POSITIONS|%1", _positions];

// The floor: the model's ground level at its centre
private _floorZ = (_b modelToWorldWorld [0, 0, _min select 2]) select 2;
for "_y" from (_max select 1) to (_min select 1) step -0.5 do {
    private _row = "";
    for "_x" from (_min select 0) to (_max select 0) step 0.5 do {
        private _w = _b modelToWorldWorld [_x, _y, 0];
        private _low = [_w select 0, _w select 1, _floorZ + 0.4];
        private _high = [_w select 0, _w select 1, _floorZ + 1.9];
        private _hit = lineIntersectsSurfaces [_low, _high, objNull, objNull, true, 1, "GEOM", "NONE"];
        // Under its roof: something above at 2-12 m
        private _roof = lineIntersectsSurfaces [_high, _high vectorAdd [0, 0, 12], objNull, objNull, true, 1, "GEOM", "NONE"];
        private _char = " ";
        if (_hit isNotEqualTo []) then { _char = "#" } else { if (_roof isNotEqualTo []) then { _char = "." } };
        _row = _row + _char;
    };
    diag_log format ["OTPROBE|ROW|%1|%2", (round (_y * 10)) / 10, _row];
};
diag_log format ["OTPROBE|DONE|%1", _cls];
deleteVehicle _b;
hint format ["Probe: %1 mapped to the RPT", _cls];
