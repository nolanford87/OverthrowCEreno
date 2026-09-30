params ["_pos", "_upgrades"];

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
        [_v] call OT_fnc_createNATOCrew;

        sleep 0.3;

        _p = _pos getPos [10, 45];
        _v = OT_NATO_Sandbag_Curved createVehicle _p;
        _v setDir 225;

        _p = _pos getPos [8.5, 135];
        _v = _gun createVehicle _p;
        _v setDir 135;
        [_v] call OT_fnc_createNATOCrew;

        sleep 0.3;

        _p = _pos getPos [10, 135];
        _v = OT_NATO_Sandbag_Curved createVehicle _p;
        _v setDir 315;

        _p = _pos getPos [8.5, 225];
        _v = _gun createVehicle _p;
        _v setDir 225;
        [_v] call OT_fnc_createNATOCrew;

        sleep 0.3;

        _p = _pos getPos [10, 225];
        _v = OT_NATO_Sandbag_Curved createVehicle _p;
        _v setDir 45;

        _p = _pos getPos [8.5, 315];
        _v = _gun createVehicle _p;
        _v setDir 315;
        [_v] call OT_fnc_createNATOCrew;

        sleep 0.3;

        _p = _pos getPos [10, 315];
        _v = OT_NATO_Sandbag_Curved createVehicle _p;
        _v setDir 135;
    };
    if (_x isEqualTo "Mortar") then {
        private _p = _pos findEmptyPosition [3, 50, OT_NATO_Mortar];
        private _v = OT_NATO_Mortar createVehicle _p;
        [_v] call OT_fnc_createNATOCrew;

        private _g = grpNull;
        {
            _x disableAI "AUTOTARGET";
            _x disableAI "FSM";
            _x disableAI "AUTOCOMBAT";
            _x setVariable ["NOAI", true, false];
            _g = group _x;
        } forEach (crew _v);
        _g setCombatMode "BLUE";
        [_v, _g] spawn OT_fnc_NATOMortar;
    };
    if (_x isEqualTo "Vehicle") then {
        // A light armed car from the occupier's ground support (no tanks), crewed, patrols the FOB
        private _cars = OT_NATO_Vehicles_GroundSupport select { (_x isKindOf "Car") && { !(_x isKindOf "Tank") } };
        private _cls = selectRandom ([_cars, OT_NATO_Vehicles_GroundSupport] select (_cars isEqualTo []));
        private _p = _pos findEmptyPosition [12, 60, _cls];
        if (_p isEqualTo []) then { _p = _pos getPos [20, random 360] };
        private _v = createVehicle [_cls, _p, [], 0, "NONE"];
        _v setDir (random 360);
        _v setVariable ["OT_fobVehicle", _pos];
        _v addEventHandler ["Killed", { [_this select 0] call OT_fnc_NATOreleaseFOBVehicle }];
        _v addEventHandler ["GetIn", {
            params ["_veh", "", "_unit"];
            if (isPlayer _unit) then { [_veh] call OT_fnc_NATOreleaseFOBVehicle };
        }];
        private _g = [_v] call OT_fnc_createNATOCrew;
        { _x setVariable ["garrison", "HQ", false] } forEach (crew _v);
        { _x addCuratorEditableObjects [[_v], true] } forEach allCurators;
        [_g, _v, _pos] spawn OT_fnc_NATOvehiclePatrol;
    };

    sleep 0.3;
} forEach (_upgrades);
