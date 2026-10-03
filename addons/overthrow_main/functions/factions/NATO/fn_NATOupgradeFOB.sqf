/*
    Description:
    Builds a FOB's upgrades: barriers, HMGs with their sandbags, a mortar, its vehicle. The guns are
    built empty, their crews are part of the FOB's virtualized garrison (OT_fnc_spawnNATOFOB): if the
    FOB is spawned they're crewed once built.

    Parameters:
        _this # 0: ARRAY - FOB position
        _this # 1: ARRAY - Upgrades to build
        _this # 2: BOOL - (Optional) Bought now: the vehicle is delivered (drives in / parachuted),
                   a loaded game has it at the FOB. Default false

    Usage: [_pos, ["HMG"]] spawn OT_fnc_NATOupgradeFOB;
*/

params ["_pos", "_upgrades", ["_deliver", false]];

{
    if (_x isEqualTo "Barriers") then {
        private _p = _pos getPos [8, 0];
        private _v = OT_NATO_Barrier_Small createVehicle _p;
        _v setDir 180;

        sleep 0.3;

        _p = _pos getPos [8, 180];
        _v = OT_NATO_Barrier_Small createVehicle _p;
        _v setDir 0;

        sleep 0.3;

        _p = _pos getPos [7, 270];
        _v = OT_NATO_Barrier_Large createVehicle _p;
        _v setDir 270;

        sleep 0.3;

        _p = _pos getPos [7, 90];
        _v = OT_NATO_Barrier_Large createVehicle _p;
        _v setDir 90;
    };
    if (_x isEqualTo "HMG") then {
        private _gun = OT_NATO_StaticGarrison_LevelOne select 0;

        private _p = _pos getPos [8.5, 45];
        private _v = _gun createVehicle _p;
        _v setDir 45;
        _v setVariable ["OT_fobStatic", _pos];

        sleep 0.3;

        _p = _pos getPos [10, 45];
        _v = OT_NATO_Sandbag_Curved createVehicle _p;
        _v setDir 225;

        _p = _pos getPos [8.5, 135];
        _v = _gun createVehicle _p;
        _v setDir 135;
        _v setVariable ["OT_fobStatic", _pos];

        sleep 0.3;

        _p = _pos getPos [10, 135];
        _v = OT_NATO_Sandbag_Curved createVehicle _p;
        _v setDir 315;

        _p = _pos getPos [8.5, 225];
        _v = _gun createVehicle _p;
        _v setDir 225;
        _v setVariable ["OT_fobStatic", _pos];

        sleep 0.3;

        _p = _pos getPos [10, 225];
        _v = OT_NATO_Sandbag_Curved createVehicle _p;
        _v setDir 45;

        _p = _pos getPos [8.5, 315];
        _v = _gun createVehicle _p;
        _v setDir 315;
        _v setVariable ["OT_fobStatic", _pos];

        sleep 0.3;

        _p = _pos getPos [10, 315];
        _v = OT_NATO_Sandbag_Curved createVehicle _p;
        _v setDir 135;
    };
    if (_x isEqualTo "Mortar") then {
        private _p = _pos findEmptyPosition [3, 50, OT_NATO_Mortar];
        private _v = OT_NATO_Mortar createVehicle _p;
        _v setVariable ["OT_fobStatic", _pos];
    };
    if (_x isEqualTo "Vehicle") then {
        [_pos, _deliver] spawn OT_fnc_NATOdeliverFOBVehicle;
    };

    sleep 0.3;
} forEach (_upgrades);

// Crews for the new guns if the FOB is spawned (a player near)
if ((_upgrades findIf { _x in ["HMG", "Mortar"] }) > -1) then {
    private _id = OT_fobSpawners getOrDefault [_pos, ""];
    if (_id in OT_allSpawned) then { [_pos, _id] spawn OT_fnc_spawnNATOFOB };
};
