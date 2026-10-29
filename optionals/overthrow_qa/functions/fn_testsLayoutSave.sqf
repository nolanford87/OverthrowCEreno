/*
    Description:
    The layout editor's save (OTQA_townLayout_save) on a compound's layout: Stavros's T3 shown in the review and
    saved untouched gives back the very items it had, every flag kept (ground, drop, post, elevated, reserve:n,
    user); then a piece moved and one placed with Zeus come back as the user's ("user"), the moved one without its
    placement flags ("ground", "drop") but with the rest, and every other item as it was. Part of the archived QA
    tests. Moves the host to the town and back; the town's layout in play is left as it was.

    Returns: ARRAY - [[name, code, seconds], ...]
*/

[
    ["Office layouts: the editor's save keeps a compound's layout, the user's edits flagged", {
        call OTQA_fnc_townLayout;
        OTQA_townLayout set ["noProfile", true]; // The host's saved progress isn't touched
        private _town = "Stavros";
        private _tier = 3;
        private _from = getPosASL player;
        player allowDamage false;
        private _was = +(OT_officeLayouts get _town);
        private _tierItems = { (((OT_officeLayouts get _town) select 1) select (_tier - 1)) apply { str _x } };
        private _before = call _tierItems;

        // Shown in the review and saved untouched
        OTQA_townLayout set ["towns", [_town]];
        [_town] call OTQA_townLayout_show;
        [_tier] call OTQA_townLayout_reviewShow;
        sleep 3;
        call OTQA_townLayout_save;
        private _after = call _tierItems;
        private _lost = _before - _after;
        private _gained = _after - _before;
        ["Office layouts: a compound tier saved untouched comes back as it was, flags and all",
            _lost isEqualTo [] && { _gained isEqualTo [] } && { (count _after) isEqualTo (count _before) },
            format ["%1 items before, %2 after, %3 lost, %4 gained (first lost: %5; first gained: %6)", count _before, count _after, count _lost, count _gained, _lost param [0, ""], _gained param [0, ""]]] call OTQA_fnc_check;

        // A piece the layout dropped moved 1 m, one placed with Zeus, saved
        private _things = call OTQA_townLayout_live;
        private _moved = _things param [_things findIf {
            !(_x isKindOf "CAManBase") && { private _f = ((_x getVariable ["OT_officeItem", []]) param [3, []]) param [4, []]; "ground" in _f || { "drop" in _f } }
        }, objNull];
        private _movedItem = (_moved getVariable ["OT_officeItem", []]) param [3, []];
        _moved setPosASL ((getPosASL _moved) vectorAdd [1, 0, 0]);
        private _placed = createVehicle ["Land_BagFence_Short_F", (OTQA_townLayout get "building") getPos [15, 0], [], 0, "CAN_COLLIDE"];
        (OTQA_townLayout get "things") pushBack _placed;
        sleep 1;
        call OTQA_townLayout_save;
        private _items = ((OT_officeLayouts get _town) select 1) select (_tier - 1);
        private _at = { params ["_o", "_class"]; _items param [_items findIf { (_x select 1) isEqualTo _class && { ((_x select 2) distance2D (getPosASL _o)) < 0.01 } }, []] };
        private _m = [_moved, typeOf _moved] call _at;
        private _p = [_placed, "Land_BagFence_Short_F"] call _at;
        private _keep = (_movedItem param [4, []]) - ["ground", "drop"];
        private _changed = _before - (_items apply { str _x });
        ["Office layouts: a moved piece and a placed one saved as the user's, the rest as they were",
            !isNull _moved && { (count _items) isEqualTo ((count _before) + 1) } && { _changed isEqualTo [str _movedItem] }
            && { "user" in (_m param [4, []]) } && { !("ground" in (_m param [4, []])) } && { !("drop" in (_m param [4, []])) } && { (_keep findIf { !(_x in (_m param [4, []])) }) isEqualTo -1 }
            && { (_p param [4, []]) isEqualTo ["user"] },
            format ["%1 items (%2 + 1); moved %3 %4 -> %5; placed %6; changed besides the moved one: %7", count _items, count _before, typeOf _moved, _movedItem param [4, []], _m param [4, "not saved"], _p param [4, "not saved"], (count _changed) - 1]] call OTQA_fnc_check;

        OT_officeLayouts set [_town, _was];
        call OTQA_townLayout_clear;
        OTQA_townLayout deleteAt "town";
        sleep 2;
        player setPosASL _from;
        player allowDamage true;
    }, 120]
]
