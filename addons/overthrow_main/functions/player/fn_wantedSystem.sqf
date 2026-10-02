private _unit = _this;

_unit setCaptive true;
_unit setVariable ["OT_hiding", 0, true];
_unit setVariable ["OT_wantedTimer", 0, true];

_unit addEventHandler [
    "Take",
    {
        params ["_me", "_container"];

        if (captive _me) then {
            //Looting dead bodies is illegal
            if (!alive _container && { typeOf _container isKindOf ["CAManBase", configFile >> "CfgVehicles"] }) then {
                if (!(_container call OT_fnc_hasOwner) && (_me call OT_fnc_unitSeen)) then {
                    _me setCaptive false;
                    [_me] call OT_fnc_revealToNATO;
                    [_me] call OT_fnc_revealToCRIM;
                };
            };
        };

        //Looting NATO supply cache
        private _supplycache = _container getVariable ["NATOsupply", false];
        if (_supplycache isEqualType "") then {
            if (_me call OT_fnc_unitSeenNATO) then {
                _me setCaptive false;
                [_me] call OT_fnc_revealToNATO;
            };
            //Make sure box doesnt spawn at this base again (this session)
            spawner setVariable [format ["NATOsupply%1", _supplycache], false, true];
        };
    }
];

_unit addEventHandler [
    "Fired",
    {
        params ["_me", "_weaponFired"];
        // A legal hunter firing their hunting rifle out of earshot of towns (400 m beyond them)
        if (captive _me && { !(_weaponFired isEqualTo primaryWeapon _me && { [_me, 400] call OT_fnc_isLegalHunter }) }) then {
            //See if anyone heard the shots
            private _range = 800;
            (_me weaponAccessories (currentMuzzle _me)) params [["_silencer", ""]];
            if (_silencer isNotEqualTo "") then {
                //Shot was suppressed
                _range = 50;
            };

            if ((allGroups findIf { side _x in [blufor, opfor] && { (leader _x distance _me) < _range } }) isNotEqualTo -1) exitWith {
                _me setCaptive false;
                [_me, _range] call OT_fnc_revealToNATO;
            };
        };
    }
];

// Poachers: a shot (from a vehicle's gun too) in a hunting spot heats it up (OT_fnc_poacherShot)
_unit addEventHandler [
    "FiredMan",
    {
        params ["_me", "_weapon"];
        if (_weapon in ["Throw", "Put"]) exitWith {};
        private _index = (getPosATL _me) call OT_fnc_inHuntingSpot;
        if (_index > -1) then { [_index] remoteExec ["OT_fnc_poacherShot", 2] };
    }
];

if ((isPlayer _unit) && isNil "OT_ACEunconsciousChangedEHId") then {
    OT_ACEunconsciousChangedEHId = [
        "ace_unconscious",
        {
            params ["_unit", "_state"];

            if (!local _unit || { !alive _unit } || { !_state } || { !isPlayer _unit }) exitWith {};

            _unit setCaptive false;

            // inform other players
            if (count (allPlayers - (entities "HeadlessClient_F")) > 1) then {
                [
                    format [
                        "%1 has fallen unconscious and is waiting for assistance at GRIDREF: %2",
                        name player,
                        mapGridPosition player
                    ]
                ] remoteExec ["systemChat", [0, -2] select isDedicated];
            };

            //Look for a medic, counting only the medics sent for this time going unconscious
            _unit setVariable ["OT_informedMedics", 0];
            private _havepi = "ACE_epinephrine" in (items player);
            private _nearbyUnits = player nearEntities ["CAManBase", 50];
            {
                if (!isPlayer _x
                    && { isNull objectParent _x }
                    && { (side _x isEqualTo independent) || captive _x }
                    && { _unit isNotEqualTo _x }
                    && { _havepi || { ("ACE_epinephrine" in (items _x)) } }
                ) exitWith {
                    systemChat format ["%1: On my way to help you", name _x];
                    _unit setVariable ["OT_informedMedics", (_unit getVariable ["OT_informedMedics", 0]) + 1];
                    [_x, _unit] call OT_fnc_orderRevivePlayer;
                };
            } forEach (_nearbyUnits);

            if ((_unit getVariable ["OT_informedMedics", 0]) isEqualTo 0) then {
                [_unit] call OT_fnc_unconsciousNoHelpPossible;
            };
        }
    ] call CBA_fnc_addEventHandler;
};

[
    OT_fnc_wantedLoop,
    [_unit],
    3
] call CBA_fnc_waitAndExecute;
