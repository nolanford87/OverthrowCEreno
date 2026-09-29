/*
    Description:
    Batch 9 (fix/misc-low): classname and classification fixes, helpers that changed the caller's data,
    dialog ids.

    Returns: ARRAY - [[name, code], ...], part of the bug fix QA tests (OTQA_fnc_testsBugFixes)
*/

"Buy a magazine with a full inventory: you aren't charged" call OTQA_fnc_manual;
"Order a recruit to open the arsenal of a box 15 m away: they walk to it first" call OTQA_fnc_manual;

[
    ["Recruit loadout classes exist", {
        private _bad = [];
        {
            _x params ["_cls", "_loadout"];
            {
                if (_x isEqualType "" && { _x isNotEqualTo "" } && { !isClass (configFile >> "CfgWeapons" >> _x) }) then { _bad pushBackUnique _x };
            } forEach (_loadout param [9, []]);
        } forEach OT_Recruitables;
        ["Recruit linked items all exist", _bad isEqualTo [], format ["unknown classes: %1", _bad]] call OTQA_fnc_check;
    }],

    ["NATO machine guns are classified", {
        ["NATO machine guns are found", OT_allBLUMachineGuns isNotEqualTo [], format ["%1 machine guns", count OT_allBLUMachineGuns]] call OTQA_fnc_check;
    }],

    ["Helpers don't change the caller's data", {
        private _pos = [1000, 1000];
        _pos call OT_fnc_nearestTown;
        ["nearestTown leaves the position alone", (count _pos) isEqualTo 2, format ["position is now %1", _pos]] call OTQA_fnc_check;

        private _matrix = [[1, 0, 0], [0, 1, 0], [0, 0, 1]];
        [_matrix, [1, 2, 3]] call OT_fnc_matrixRotate;
        ["matrixRotate leaves the matrix alone", (count _matrix) isEqualTo 3 && { (count (_matrix select 0)) isEqualTo 3 }, format ["matrix is now %1", _matrix]] call OTQA_fnc_check;
    }],

    ["Sell dialog buttons have their own ids", {
        private _controls = configFile >> "OT_dialog_sell" >> "controls";
        private _sell = getNumber (_controls >> "RscButton_1600" >> "idc");
        private _sellAll = getNumber (_controls >> "RscButton_1602" >> "idc");
        ["Sell and Sell All buttons have different ids", _sell isNotEqualTo _sellAll, format ["Sell %1, Sell All %2", _sell, _sellAll]] call OTQA_fnc_check;
    }]
]
