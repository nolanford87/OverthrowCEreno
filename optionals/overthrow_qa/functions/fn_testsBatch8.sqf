/*
    Description:
    Batch 8 (fix/warehouse-helpers): taking items from containers inside cargo, warehouse lookups and
    guards, garrison units not taking warehouse gear on the server. Game state isn't preserved.

    Returns: ARRAY - [[name, code], ...], part of the bug fix QA tests (OTQA_fnc_testsBugFixes)
*/

"Put crafting ingredients inside a backpack in the ammobox and craft: the ingredients are used up" call OTQA_fnc_manual;
"Salvage a wreck and use the salvage action again while it runs: only one payout" call OTQA_fnc_manual;
"Buy a business as general: it has 2 employees and produces straight away" call OTQA_fnc_manual;
"Dedicated server: buying a garrison or police with gear from the warehouse takes that gear from the warehouse" call OTQA_fnc_manual;

[
    ["Items are taken from backpacks in cargo", {
        private _box = createVehicle ["Box_NATO_Support_F", player getPos [4, getDir player], [], 0, "CAN_COLLIDE"];
        clearItemCargoGlobal _box;
        clearMagazineCargoGlobal _box;
        clearWeaponCargoGlobal _box;
        clearBackpackCargoGlobal _box;
        _box addBackpackCargoGlobal ["B_AssaultPack_rgr", 1];
        sleep 0.5;
        private _pack = (everyContainer _box) param [0, ["", objNull]] select 1;
        _pack addItemCargoGlobal ["FirstAidKit", 3];
        sleep 0.5;

        private _counted = ((_box call OT_fnc_unitStock) select { (_x select 0) isEqualTo "FirstAidKit" }) param [0, ["", 0]] select 1;
        private _removed = [_box, "FirstAidKit", 2] call OT_fnc_removeFromCargo;
        private _left = { _x isEqualTo "FirstAidKit" } count (itemCargo _pack);
        ["Stock counts items inside a backpack", _counted isEqualTo 3, format ["counted %1", _counted]] call OTQA_fnc_check;
        ["Items are removed from inside the backpack", _removed isEqualTo 2 && { _left isEqualTo 1 }, format ["removed %1, left in backpack %2", _removed, _left]] call OTQA_fnc_check;

        deleteVehicle _box;
    }],

    ["Warehouse lookups without a warehouse", {
        // Far from any warehouse
        private _far = [10, 10];
        ["Nearest warehouse at an empty spot is null", isNull ([_far] call OT_fnc_nearestWarehouse), ""] call OTQA_fnc_check;
        private _qty = "FirstAidKit" call OT_fnc_qtyInWarehouse;
        ["Warehouse quantity is always a number", _qty isEqualType 0, format ["qtyInWarehouse returned %1", _qty]] call OTQA_fnc_check;

        // A cached entry that isn't an owned warehouse must not be returned
        OT_warehouseLocationCache set [_far, player];
        ["Stale warehouse cache entry is ignored", ([_far] call OT_fnc_nearestWarehouse) isNotEqualTo player, ""] call OTQA_fnc_check;
    }],

    ["Making the shared warehouse global again is refused", {
        player setVariable ["money", 20000, true];
        private _result = [[10, 10], player] call OT_fnc_makeWarehouseGlobal;
        private _money = player getVariable ["money", 0];
        ["No warehouse to share is refused without charging", !_result && { _money isEqualTo 20000 }, format ["result %1, money %2", _result, _money]] call OTQA_fnc_check;
    }],

    ["Garrison units don't take warehouse gear on the server", {
        private _warehouse = [player] call OT_fnc_nearestWarehouse;
        if (isNull _warehouse) exitWith {
            "Garrison warehouse test skipped: stand within 2 km of an owned warehouse" call OTQA_fnc_manual;
        };
        private _soldier = ((OT_Recruitables select 0) select 0) call OT_fnc_getSoldier;
        private _items = (_soldier select 4) call BIS_fnc_consolidateArray;
        private _before = _items apply { (_x select 0) call OT_fnc_qtyInWarehouse };
        ["OTQA_BASE", player getPos [30, 0], _soldier, false] call OT_fnc_createGarrisonUnit;
        sleep 1;
        private _after = _items apply { (_x select 0) call OT_fnc_qtyInWarehouse };
        ["Creating a garrison unit on the server takes nothing from the warehouse", _before isEqualTo _after, format ["%1 item types checked", count _items]] call OTQA_fnc_check;
        { deleteVehicle _x } forEach (units (spawner getVariable ["resgarrisonOTQA_BASE", grpNull]));
    }]
]
