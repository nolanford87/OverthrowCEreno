/*
    Description:
    Blocks or unblocks the local player's inventory during a NATO search. Runs on the searched player's
    machine, as InventoryOpened only fires where the unit is local. The handler is added when the search
    starts so it's the last one added, other mods' InventoryOpened handlers can otherwise override it.

    Parameters:
        _this # 0: BOOL - true to block, false to unblock

    Usage: [true] remoteExec ["OT_fnc_NATOsearchLockInventory", _target, false];
*/

params [["_lock", true, [true]]];

if (!hasInterface) exitWith {};

if (_lock) then {
    if (isNil "OT_searchInventoryEH") then {
        OT_searchInventoryEH = player addEventHandler [
            "InventoryOpened",
            {
                hint format ["%1 search is in progress, you cannot open your inventory", OT_NATO_name];
                true; //<-- inventory override
            }
        ];
    };
} else {
    if (!isNil "OT_searchInventoryEH") then {
        player removeEventHandler ["InventoryOpened", OT_searchInventoryEH];
        OT_searchInventoryEH = nil;
    };
};
