/*
    Description:
    The fight for a place once the occupier's forces are on their way (split from OT_fnc_NATOQRF so
    the town counter-attacks, OT_fnc_NATOCounterTown, can send their own forces and use the same
    fight). After 10 minutes for the forces to get there, the occupier's soldiers within 200 m count
    against the resistance's (players twice) every 5 seconds until one side reaches 1500 points, or the
    occupier wins after 30 minutes if it's ahead. The occupier winning calls _success, losing _fail.

    Parameters:
        _this # 0: ARRAY - Position fought over
        _this # 1: NUMBER - Strength the occupier has left (half of it comes back if it wins, losing
            leaves it that much in debt)
        _this # 2: CODE - Called with _params when the occupier wins
        _this # 3: CODE - Called with _params when the resistance wins
        _this # 4: ARRAY - Parameters for _success / _fail
        _this # 5: STRING - Garrison the occupier's surviving attackers join if it wins

    Usage: [_pos, _strength, _success, _fail, _params, _town] call OT_fnc_NATOQRFfight; (scheduled)

    Returns: BOOL - Did the occupier win
*/

params ["_pos", "_strength", "_success", "_fail", "_params", "_garrison"];

private _start = round (time);
server setVariable ["QRFpos", _pos, true];
["OT_QRFstart", []] call CBA_fnc_globalEvent;
server setVariable ["QRFprogress", 0, true];

// OT_QRFsetupTime is set only by the QA tests
waitUntil { (time - _start) > (missionNamespace getVariable ["OT_QRFsetupTime", 600]) };

private _timeout = time + 800; // ~13 minutes
private _maxTime = time + 1800; // 30 minutes

private _over = false;
private _progress = 0;

while {
    sleep 5;
    !_over;
} do {
    private _alive = 0;
    private _enemy = 0;

    private _unitsAO = [_pos, 200, 200, 0, false] nearEntities [["CAManBase"], false, true, true] select { !(_x getVariable ["ace_isunconscious", false]) };
    _alive = blufor countSide _unitsAO;
    {
        if (side _x isEqualTo independent || captive _x) then {
            // Players count twice
            _enemy = _enemy + ([1, 2] select (isPlayer _x));
        };
    } forEach _unitsAO;

    if (_alive isEqualTo 0) then { _enemy = _enemy * 8 }; //If no NATO present, cap it faster

    if (time > _timeout && { _alive isEqualTo 0 && _enemy isEqualTo 0 }) then { _enemy = 1 };

    _progress = _progress + ((-20 max (_alive - _enemy)) min 10);

    // Set only by the QA tests: 1 ends the fight as an occupier win, -1 as a resistance win
    private _forced = missionNamespace getVariable ["OT_QRFforceResult", 0];
    if (_forced isNotEqualTo 0) then {
        OT_QRFforceResult = nil;
        _progress = 1500 * _forced;
    };

    private _progressPercent = 0;
    if (_progress isNotEqualTo 0) then { _progressPercent = _progress / 1500 };
    server setVariable ["QRFprogress", _progressPercent, true];

    if ((abs _progress) >= 1500 || time > _maxTime) then {
        //Someone has won
        _over = true;
    };
};

if (_progress > 0) then {
    //Nato has won
    _params call _success;

    //Recover half of the unspent strength. Add to what NATO has, it kept earning during the QRF
    server setVariable ["NATOresources", (server getVariable ["NATOresources", 0]) + round ((_strength max 0) * 0.5), true];
    {
        if (side _x isEqualTo blufor) then {
            if ((units _x) isNotEqualTo []) then {
                private _lead = (units _x) select 0;
                private _g = (_lead getVariable ["garrison", ""]);
                if !(_g isEqualType "") then { _g = "HQ" };
                if (_g isEqualTo "HQ" && { (_lead getVariable ["OT_fob", []]) isEqualTo [] }) then {
                    if (!isNull objectParent _lead) then {
                        [objectParent _lead] call OT_fnc_cleanup;
                    } else {
                        if ([_lead] call OT_fnc_inSpawnDistance) then {
                            {
                                _x setVariable ["garrison", _garrison, true];
                            } forEach (units _x);
                        } else {
                            [_x] call OT_fnc_cleanup;
                        };
                    };
                };
            } else {
                deleteGroup _x;
            };
        };
    } forEach (groups blufor);
    {
        if (side _x isEqualTo blufor) then {
            if (_x getVariable ["garrison", ""] isEqualTo "HQ" && { (_x getVariable ["OT_fobVehicle", []]) isEqualTo [] }) then {
                [_x] call OT_fnc_cleanup;
            };
        };
    } forEach (vehicles);
} else {
    _params call _fail;

    //Nato gets pushed back
    server setVariable ["NATOresourceGain", 0, true];
    server setVariable ["NATOresources", -(_strength max 0), true];
};
server setVariable ["NATOlastattack", time, true]; //Ensures NATO takes some time after a QRF to recover (even if they win)
server setVariable ["QRFpos", nil, true];
["OT_QRFend", []] call CBA_fnc_globalEvent;
server setVariable ["QRFprogress", nil, true];
server setVariable ["NATOattacking", "", true];

_progress > 0;
