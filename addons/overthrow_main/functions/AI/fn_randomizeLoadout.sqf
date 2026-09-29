// Weapons (and with _swapGear, vests and helmets) come from the pool picked by the lobby setting
// "ot_randomloadoutpool" (OT_randomLoadoutPool, see initVar). Pass nil to use the pool for a slot.
// A slot whose pool is empty keeps its weapon.
params [
    "_loadout",
    ["_rifles", OT_randomLoadoutPool get "rifles"],
    ["_glRifles", OT_randomLoadoutPool get "glRifles"],
    ["_machineGuns", OT_randomLoadoutPool get "machineGuns"],
    ["_sniperRifles", OT_randomLoadoutPool get "sniperRifles"],
    ["_launchers", OT_randomLoadoutPool get "launchers"],
    ["_handguns", OT_randomLoadoutPool get "handguns"],
    ["_swapGear", false]
];

private _cfgWeapons = configFile >> "CfgWeapons";
private _cfgMagazines = configFile >> "CfgMagazines";

//helper functions
private _removeMagazines = {
    params ["_newloadout", "_forcls"];
    private _hasVest = (_newloadout select 4) isNotEqualTo [];
    private _hasBackpack = (_newloadout select 5) isNotEqualTo [];
    private _magazines = compatibleMagazines _forcls; // All muzzles, including magazine wells
    //from uniform
    private _items = (_newloadout select 3) select 1;
    {
        _x params ["_cls"];
        if (_cls in _magazines) then { _x set [1, 0] };
    } forEach (_items);

    //from vest
    if (_hasVest) then {
        _items = (_newloadout select 4) select 1;
        {
            _x params ["_cls"];
            if (_cls in _magazines) then { _x set [1, 0] };
        } forEach (_items);
    };

    if (_hasBackpack) then {
        //from backpack
        _items = (_newloadout select 5) select 1;
        {
            _x params ["_cls"];
            if (_cls in _magazines) then { _x set [1, 0] };
        } forEach (_items);
    };
};

// Magazines of one muzzle ("this" for the main one), including magazine wells (mods and creator DLC weapons)
private _muzzleMagazines = {
    params ["_wpn", ["_muzzle", "this"]];
    private _cfg = [_cfgWeapons >> _wpn >> _muzzle, _cfgWeapons >> _wpn] select (_muzzle isEqualTo "this");
    private _magazines = getArray (_cfg >> "magazines");
    {
        {
            _magazines append getArray _x;
        } forEach (configProperties [configFile >> "CfgMagazineWells" >> _x, "isArray _x"]);
    } forEach (getArray (_cfg >> "magazineWell"));
    _magazines select { getNumber (_cfgMagazines >> _x >> "scope") > 1 };
};

// Armor of a vest (chest) or helmet (head)
private _armor = {
    params ["_cls", "_hitpoint"];
    getNumber (_cfgWeapons >> _cls >> "ItemInfo" >> "HitpointsProtectionInfo" >> _hitpoint >> "armor");
};

// A random item from the pool with about the same armor, or the item itself if there is none
private _similarArmor = {
    params ["_cls", "_pool", "_hitpoint"];
    private _own = [_cls, _hitpoint] call _armor;
    private _matching = _pool select { abs (([_x, _hitpoint] call _armor) - _own) <= 4 };
    if (_matching isEqualTo []) exitWith { _cls };
    selectRandom _matching;
};

private _newloadout = +_loadout; //clone the loadout

//get some basic info about the loadout
private _hasVest = (_newloadout select 4) isNotEqualTo [];
private _hasBackpack = (_newloadout select 5) isNotEqualTo [];
private _hasPrimary = (_newloadout select 0) isNotEqualTo [];
private _hasLauncher = (_newloadout select 1) isNotEqualTo [] && { _launchers isNotEqualTo [] };
private _hasHandgun = (_newloadout select 2) isNotEqualTo [] && { _handguns isNotEqualTo [] };

//replace primary weapon
if (_hasPrimary) then {
    private _primaryWpn = (_loadout select 0) select 0;
    private _base = [_primaryWpn] call BIS_fnc_baseWeapon;

    // The same kind of weapon
    private _pool = _base call {
        if (_this in _glRifles) exitWith { _glRifles };
        if (_this in _sniperRifles) exitWith { _sniperRifles };
        if (_this in _machineGuns) exitWith { _machineGuns };
        _rifles;
    };
    if (_pool isEqualTo []) exitWith {};

    //remove magazines for primary weapon
    [_newloadout, _primaryWpn] call _removeMagazines;

    //replace primary weapon
    private _wpn = selectRandom _pool;

    // Remove all incompatible attachments.
    private _compatItems = compatibleItems _wpn;
    {
        if !(_x in _compatItems) then { (_newloadout # 0) set [_forEachIndex + 1, ""] };
    } forEach [((_newloadout # 0) # 1), ((_newloadout # 0) # 2), ((_newloadout # 0) # 3)];
    if !(((_newloadout # 0) # 6) in _compatItems) then { (_newloadout # 0) set [6, ""] }; // Bipod

    (_newloadout select 0) set [0, _wpn];

    private _mag = selectRandom ([_wpn] call _muzzleMagazines);
    if (isNil "_mag") then { _mag = "" };

    private _count = getNumber (_cfgMagazines >> _mag >> "count");
    (_newloadout select 0) set [4, [[_mag, _count], []] select (_mag isEqualTo "")];

    //add mags to vest
    if (_hasVest && { _mag isNotEqualTo "" }) then {
        ((_newloadout select 4) select 1) pushBack [_mag, 6, _count];
    };

    //get secondary mags (grenade rounds etc)

    private _secondmags = [];
    {
        if !(toLowerANSI _x in ["this", "safe"]) then {
            _secondmags append ([_wpn, _x] call _muzzleMagazines);
        };
    } forEach (getArray (_cfgWeapons >> _wpn >> "muzzles"));
    if (_secondmags isNotEqualTo []) then {
        if (_hasBackpack) then {
            //add all of them to backpack
            {
                private _count = getNumber (_cfgMagazines >> _x >> "count");
                ((_newloadout select 5) select 1) pushBack [_x, 4, _count];
            } forEach (_secondmags);
        } else {
            //add the first one to vest
            if (_hasVest) then {
                _mag = _secondmags select 0;
                private _count = getNumber (_cfgMagazines >> _mag >> "count");
                ((_newloadout select 4) select 1) pushBack [_mag, 6, _count];
            };
        };
    };
};

//replace secondary weapon (launcher)
if (_hasLauncher) then {
    [_newloadout, (_newloadout select 1) select 0] call _removeMagazines;
    private _wpn = selectRandom _launchers;
    //we always want the primary mag
    (_newloadout select 1) set [0, _wpn];
    private _magazines = getArray (_cfgWeapons >> _wpn >> "magazines");
    private _mag = _magazines param [0, ""];
    private _count = getNumber (_cfgMagazines >> _mag >> "count");
    private _scope = getNumber (_cfgMagazines >> _mag >> "scope");
    (_newloadout select 1) set [4, [[_mag, _count], []] select (_mag isEqualTo "")];

    if (_hasBackpack && { _mag isNotEqualTo "" }) then {
        if (_scope < 2) then {
            //single-use launcher, remove backpack
            _newloadout set [5, []];
        } else {
            (_newloadout select 5) set [1, []]; //Clear backpack
            //add more primary mags
            ((_newloadout select 5) select 1) pushBack [_mag, 2, _count];

            //add 2 other random ones
            private _c = 0;
            {
                if (_forEachIndex > 0) then {
                    private _count = getNumber (_cfgMagazines >> _x >> "count");
                    ((_newloadout select 5) select 1) pushBack [_x, 1, _count];
                    _c = _c + 1;
                };
                if (_c isEqualTo 2) exitWith {};
            } forEach (_magazines call BIS_fnc_arrayShuffle);
        };
    };
};

//replace handgun
if (_hasHandgun) then {
    [_newloadout, ((_newloadout select 2) select 0)] call _removeMagazines;
    private _wpn = selectRandom _handguns;
    (_newloadout select 2) set [0, _wpn];
    //we always want the primary mag
    private _mag = ([_wpn] call _muzzleMagazines) param [0, ""];
    private _count = getNumber (_cfgMagazines >> _mag >> "count");
    (_newloadout select 2) set [4, [[_mag, _count], []] select (_mag isEqualTo "")];
    //add 2 mags to vest
    if (_hasVest && { _mag isNotEqualTo "" }) then {
        ((_newloadout select 4) select 1) pushBack [_mag, 2, _count];
    };
};

// Vest and helmet with about the same protection, the uniform stays so NATO is recognisable
if (_swapGear) then {
    if (_hasVest) then {
        (_newloadout select 4) set [0, [(_newloadout select 4) select 0, OT_randomLoadoutPool get "vests", "Chest"] call _similarArmor];
    };
    private _helmet = _newloadout select 6;
    if (_helmet isNotEqualTo "") then {
        _newloadout set [6, [_helmet, OT_randomLoadoutPool get "helmets", "Head"] call _similarArmor];
    };
};

_newloadout;
