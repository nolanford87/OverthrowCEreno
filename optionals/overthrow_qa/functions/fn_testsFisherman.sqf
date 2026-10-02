/*
    Description:
    The fishery's fisherman buys the player's catch (OT_fnc_sellFishToFishery): fish on the player and
    in their own boat nearby, 10% over a general store; turtles stay. Part of the current QA tests.
    Run it as the host; it spawns a stand-in fisherman and a boat by the host and removes them.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

"Fisherman: talk to a fishery's fisherman with fish on you: 'Sell your catch' pays for them" call OTQA_fnc_manual;

[
    ["Fisherman: buys the catch on the player and in their boat", {
        if (isNil "OT_fnc_sellFishToFishery") exitWith { ["Fisherman: OT_fnc_sellFishToFishery exists", false, "missing"] call OTQA_fnc_check };
        private _pos = (getPosATL player) getPos [4, getDir player];
        private _grp = createGroup civilian;
        private _civ = _grp createUnit ["C_man_1", _pos, [], 0, "CAN_COLLIDE"];
        _civ setVariable ["OT_fishery", "QA Fishery", true];
        private _boat = createVehicle ["C_Boat_Civil_01_F", (getPosATL player) getPos [15, (getDir player) + 90], [], 0, "NONE"];
        [_boat, getPlayerUID player] call OT_fnc_setOwner;
        clearItemCargoGlobal _boat;
        _boat addItemCargoGlobal ["OT_Fish_Tuna", 2];
        _boat addItemCargoGlobal ["OT_Fish_Salema", 3];
        if (isNull (unitBackpack player)) then { player addBackpack "B_Carryall_cbr" };
        player addItem "OT_Fish_Mackerel";
        player addItem "OT_Turtle";
        sleep 0.5;

        private _town = (getPosATL _civ) call OT_fnc_nearestTown;
        private _expect = 0;
        { _x params ["_cls", "_n"]; _expect = _expect + _n * round (([_town, _cls, 0] call OT_fnc_getSellPrice) * 1.1) } forEach [["OT_Fish_Tuna", 2], ["OT_Fish_Salema", 3], ["OT_Fish_Mackerel", 1]];
        private _money = player getVariable ["money", 0];
        [_civ] call OT_fnc_sellFishToFishery;
        sleep 1;

        ["Fisherman: paid 10% over a store for all 6 fish", ((player getVariable ["money", 0]) - _money) isEqualTo _expect,
            format ["+%1, expected +%2", (player getVariable ["money", 0]) - _money, _expect]] call OTQA_fnc_check;
        ["Fisherman: the boat's fish and the player's are gone", ((itemCargo _boat) findIf { _x in OT_fishSellItems }) isEqualTo -1 && { ((items player) findIf { _x in OT_fishSellItems }) isEqualTo -1 },
            format ["boat %1, player %2", itemCargo _boat, (items player) select { _x in OT_fishSellItems }]] call OTQA_fnc_check;
        ["Fisherman: turtles aren't his trade, the player keeps them", "OT_Turtle" in (items player), ""] call OTQA_fnc_check;

        _money = player getVariable ["money", 0];
        [_civ] call OT_fnc_sellFishToFishery;
        sleep 0.5;
        ["Fisherman: nothing to sell, nothing paid", (player getVariable ["money", 0]) isEqualTo _money, ""] call OTQA_fnc_check;

        player removeItem "OT_Turtle";
        deleteVehicle _civ;
        deleteGroup _grp;
        deleteVehicle _boat;
    }, 30]
];
