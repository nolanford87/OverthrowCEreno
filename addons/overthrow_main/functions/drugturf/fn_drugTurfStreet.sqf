/*
    Description:
    A player sold drugs on the street (server; OT_fnc_talkToCiv, after each sale to a civilian). On a
    gang's turf (within OT_drugTurfRadius of its camp, OT_fnc_drugTurfGang) the gang wants its cut:
    - with a deal (OT_fnc_drugTurfDeal) it takes OT_drugTurfCut (a fifth) of the money, out of the
      seller's (OT_fnc_money on their machine); the dealmaker earns rep for it (OT_fnc_drugTurfPay);
    - without, it gets angry (OT_drugTurfAnger per unit, OT_drugTurfStreetMult times: it's under
      their noses), the seller loses rep with it, it warns them, and in the end ambushes them
      (OT_fnc_drugTurfAdd).

    Parameters:
        _this # 0: OBJECT - The seller
        _this # 1: ARRAY - Where
        _this # 2: STRING - Drug class
        _this # 3: NUMBER - Units sold (default: 1)
        _this # 4: NUMBER - Money made (default: 0)

    Usage: [player, getPosATL player, "OT_Ganja", 1, 60] remoteExec ["OT_fnc_drugTurfStreet", 2, false];

    Returns: ARRAY - [gang id, anger now, cut taken], [] when it's on no gang's turf
*/

params ["_player", "_pos", "_cls", ["_qty", 1], ["_paid", 0]];

if (!isServer || { isNull _player } || { _qty <= 0 }) exitWith { [] };
([_pos] call OT_fnc_drugTurfGang) params [["_gangId", -1], ["_gang", []]];
if (_gangId < 0) exitWith { [] };

if (([_gangId] call OT_fnc_drugTurfDealOf) isNotEqualTo []) exitWith {
    private _cut = round (_paid * OT_drugTurfCut);
    if (_cut > 0) then {
        [-_cut, format ["%1's cut", _gang select 8]] remoteExec ["OT_fnc_money", _player, false];
        [_gangId, "cash", _cut, _cut] call OT_fnc_drugTurfPay;
    };
    [_gangId, 0, _cut]
};

private _kind = ["ganja", "blow"] select (_cls isEqualTo "OT_Blow");
private _points = _qty * (OT_drugTurfAnger getOrDefault [_kind, 1]) * OT_drugTurfStreetMult;
private _anger = [_gangId, _points, [_player], ["street", _player]] call OT_fnc_drugTurfAdd;
[_gangId, _anger, 0]
