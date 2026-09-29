/*
    Description:
    Batch 1 (fix/economy-exploits): forced income tick, inventory transfer between boxes.
    Game state isn't preserved (the test save is disposable).

    Returns: ARRAY - [[name, code], ...], part of the bug fix QA tests (OTQA_fnc_testsBugFixes)
*/

"Business with two cargo containers nearby takes its input once per hour; fertilized farms make 1.5x output" call OTQA_fnc_manual;
"Factory vehicle with a blocked spawn road stays queued and is built once the road is clear" call OTQA_fnc_manual;
"Refuel at a pump after driving around: you pay for the fuel added, you're never paid" call OTQA_fnc_manual;

[
    ["Income tick pays out", {
        private _money = player getVariable ["money", 0];
        private _tax = (call OT_fnc_getTaxIncome) select 0;
        private _leases = count (player getVariable ["leasedata", []]);

        // Jump to 06:00, the income loop pays at 00:00, 06:00, 12:00 and 18:00
        private _date = date;
        income_system_lasthour = -1;
        setDate [_date select 0, _date select 1, _date select 2, 6, 0];
        private _timeout = time + 10;
        waitUntil { sleep 0.5; income_system_lasthour isEqualTo 6 || { time > _timeout } };
        ["Income loop runs", income_system_lasthour isEqualTo 6, format ["income_system_lasthour %1", income_system_lasthour]] call OTQA_fnc_check;

        sleep 2;
        private _gained = (player getVariable ["money", 0]) - _money;
        if (_tax > 0 || { _leases > 0 }) then {
            ["Income is paid to the player", _gained > 0, format ["money +%1 (town income %2, %3 leased buildings)", _gained, _tax, _leases]] call OTQA_fnc_check;
        } else {
            "Income payout not checked: no town income or leased buildings yet" call OTQA_fnc_manual;
        };
    }],

    ["Transfer moves inventory", {
        private _cls = "30Rnd_65x39_caseless_mag";
        private _boxes = [];
        {
            private _box = createVehicle ["Box_NATO_Ammo_F", player getPos [4, (getDir player) + _x], [], 0, "CAN_COLLIDE"];
            clearItemCargoGlobal _box;
            clearMagazineCargoGlobal _box;
            clearWeaponCargoGlobal _box;
            clearBackpackCargoGlobal _box;
            _boxes pushBack _box;
        } forEach [60, 120];
        _boxes params ["_from", "_to"];
        _from addMagazineAmmoCargo [_cls, 1, 5];
        _from addMagazineAmmoCargo [_cls, 1, 30];

        [_from, _to] call OT_fnc_transferHelper;
        sleep 8;

        // Magazines may be refilled on transfer, that's accepted behaviour
        private _moved = { _x isEqualTo _cls } count (magazineCargo _to);
        ["Transfer moves all magazines", _moved isEqualTo 2, format ["magazines in destination: %1", magazinesAmmoCargo _to]] call OTQA_fnc_check;
        ["Source box is emptied", (magazineCargo _from) isEqualTo [], format ["left in source: %1", magazinesAmmoCargo _from]] call OTQA_fnc_check;

        { deleteVehicle _x } forEach _boxes;
    }]
]
