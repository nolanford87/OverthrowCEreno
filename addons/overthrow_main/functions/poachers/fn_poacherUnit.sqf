/*
    Description:
    One poacher, in the given (OPFOR) group. Base game gear only, whatever this install has of it:
    - "hunter" (the patrol): looks like a civilian hunter - hunting clothes or old civilian clothes, a
      boonie hat or cap, a bandolier, a hunting shotgun or rifle
    - "bandit" (the backup): an armed bandit - guerrilla clothes, a balaclava or bandanna, a chest rig
      or vest, a carbine or SMG
    Not a gang member (no gang id, no "criminal"): killing one pays OT_poacherBounty
    (OT_fnc_deathHandler, the "OT_poacher" variable) and leaves gang rep alone. Their gear is lootable.

    Parameters:
        _this # 0: GROUP - Group
        _this # 1: ARRAY - Position
        _this # 2: NUMBER - Hunting spot index
        _this # 3: STRING - (Optional) Look: "hunter" or "bandit" (default: "hunter")

    Usage: [_group, _pos, _index, "bandit"] call OT_fnc_poacherUnit; (server)

    Returns: OBJECT - The poacher
*/

params ["_group", "_pos", "_index", ["_look", "hunter"]];

// A random one of the classes this install has ("" counts as "none")
private _pick = {
    params ["_list", "_cfg"];
    private _ok = _list select { _x isEqualTo "" || { isClass (configFile >> _cfg >> _x) } };
    if (_ok isEqualTo []) exitWith { "" };
    selectRandom _ok
};

private _bandit = _look isEqualTo "bandit";
private _uniform = [[
    ["U_C_HunterBody_grn", "U_C_HunterBody_grn", "U_C_HunterBody_brn", "U_C_Poor_1", "U_C_Poor_2", "U_C_WorkerCoveralls", "U_C_Poloshirt_tricolour"],
    ["U_BG_Guerilla1_1", "U_BG_Guerilla2_1", "U_BG_Guerilla2_3", "U_BG_Guerilla3_1", "U_BG_leader", "U_IG_Guerilla1_1", "U_C_HunterBody_grn", "U_C_Poor_2"]
] select _bandit, "CfgWeapons"] call _pick;
private _headgear = [[
    ["H_Booniehat_khk", "H_Booniehat_oli", "H_Booniehat_tan", "H_Cap_oli", "H_Cap_blk", "H_Hat_brown", ""],
    ["H_Bandanna_khk", "H_Bandanna_cbr", "H_Watchcap_blk", "H_Watchcap_khk", "H_Cap_blk", "H_Shemag_olive", ""]
] select _bandit, "CfgWeapons"] call _pick;
private _vest = [[
    ["V_BandollierB_khk", "V_BandollierB_oli", "V_BandollierB_cbr", ""],
    ["V_TacVest_blk", "V_TacVest_khk", "V_Chestrig_khk", "V_Chestrig_oli", "V_HarnessO_brn", "V_BandollierB_blk"]
] select _bandit, "CfgWeapons"] call _pick;
private _goggles = [[
    ["", "", "", "G_Aviator", "G_Bandanna_khk"],
    ["G_Balaclava_blk", "G_Balaclava_oli", "G_Balaclava_combat", "G_Bandanna_blk", "G_Bandanna_khk", "G_Bandanna_shades"]
] select _bandit, "CfgGlasses"] call _pick;

// The weapon: theirs, else a hunting rifle or a cheap rifle the mod knows, else the TRG
private _weapons = ([
    ["sgun_HunterShotgun_01_F", "sgun_HunterShotgun_01_F", "srifle_DMR_06_hunter_F"],
    ["arifle_TRG20_F", "arifle_TRG21_F", "arifle_Mk20C_plain_F", "arifle_Mk20_plain_F", "arifle_Katiba_C_F", "SMG_01_F", "SMG_02_F"]
] select _bandit) select { isClass (configFile >> "CfgWeapons" >> _x) };
if (_weapons isEqualTo []) then { _weapons = +([OT_huntingWeapons, OT_allCheapRifles] select _bandit) };
if (_weapons isEqualTo []) then { _weapons = ["arifle_TRG20_F"] };
private _weapon = selectRandom _weapons;
private _mags = (compatibleMagazines [_weapon, "this"]) select { isClass (configFile >> "CfgMagazines" >> _x) };
private _mag = _mags param [0, ""];
if ("2Rnd_12Gauge_Slug" in _mags) then { _mag = "2Rnd_12Gauge_Slug" };

private _cls = ["C_man_1", "C_man_hunter_1_F"] select (isClass (configFile >> "CfgVehicles" >> "C_man_hunter_1_F"));
private _unit = _group createUnit [_cls, _pos, [], 5, "NONE"];
[_unit] joinSilent _group;
_unit setVariable ["OT_poacher", _index, true];
_unit setVariable ["OT_poacherLook", _look, true];
_unit setSkill (0.3 + random 0.3);

removeAllWeapons _unit;
removeAllItems _unit;
removeAllAssignedItems _unit;
removeUniform _unit;
removeVest _unit;
removeBackpack _unit;
removeHeadgear _unit;
removeGoggles _unit;

// A local face and name in these clothes
private _identity = call OT_fnc_randomLocalIdentity;
_identity set [1, _uniform];
_identity set [3, _goggles];
[_unit, _identity] call OT_fnc_applyIdentity;
if (_vest isNotEqualTo "") then { _unit addVest _vest };
if (_headgear isNotEqualTo "") then { _unit addHeadgear _headgear };
_unit linkItem "ItemMap";
_unit linkItem "ItemCompass";
_unit linkItem "ItemWatch";
_unit addItem "FirstAidKit";

if (_mag isNotEqualTo "") then {
    // Enough rounds for a fight: twelve shotgun shells, four or five magazines otherwise
    private _rounds = getNumber (configFile >> "CfgMagazines" >> _mag >> "count");
    _unit addMagazines [_mag, [4 + (floor random 2), 6] select (_rounds < 5)];
};
_unit addWeapon _weapon;
_unit selectWeapon _weapon;

{ _x addCuratorEditableObjects [[_unit], false] } forEach allCurators;
_unit
