params ["_vehicle", ["_chuteheight", 100]];

sleep 5; //Give the helicopter a chance to stop/slow Down

private _paras = assignedCargo _vehicle;
private _dir = direction _vehicle;

{
    _x setVariable ["OT_ejectLoadout", getUnitLoadout _x, false]; // Kept on the unit, getBuildID doesn't give units a unique id
    removeBackpackGlobal _x;
    _x disableCollisionWith _vehicle; // Sometimes units take damage when being ejected.
    _x addBackpackGlobal "B_parachute";
    unassignVehicle _x;
    moveOut _x;
    _x setDir (_dir + 90); // Exit the chopper at right angles.
    sleep 1;
} forEach _paras;

{
    [_x, _chuteheight] spawn {
        params ["_unit", "_chuteheight"];

        // land safe if player
        if (isPlayer _unit) then {
            [_unit, _chuteheight] spawn {
                params ["_paraPlayer", "_chuteheight"];
                waitUntil { (getPos _paraPlayer select 2) <= _chuteheight };
                _paraPlayer action ["openParachute", _paraPlayer];
            };
        };
        waitUntil { !(alive _unit) || isTouchingGround _unit || (getPos _unit select 2) < 20 };

        _unit allowDamage false; //So they dont hit trees or die on ground impact

        waitUntil { !(alive _unit) || isTouchingGround _unit || (getPos _unit select 2) < 1 };

        _unit action ["Eject", vehicle _unit];
        sleep 2;
        _unit setUnitLoadout (_unit getVariable ["OT_ejectLoadout", getUnitLoadout _unit]);
        _unit setVariable ["OT_ejectLoadout", nil, false];
        _unit allowDamage true;
    };
} forEach _paras;

_vehicle setVariable ["OT_deployedTroops", true, false];
