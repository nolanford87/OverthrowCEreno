/*
    Description:
    A drug operation made or sold drugs (server; the end of OT_fnc_drugHeat, after every dispensary
    sale and lab batch). On a gang's turf (within OT_drugTurfRadius of its camp, OT_fnc_drugTurfGang)
    the gang wants its cut:
    - with a deal (OT_fnc_drugTurfDeal) it takes OT_drugTurfCut (a fifth): of a dispensary's sale in
      cash from resistance funds (the sale's worth at the town's drug price, deducted a second later,
      once the cycle has banked the income it adds after this hook), of a lab's batch in blow out of
      the lab's container; the dealmaker earns rep for it (OT_fnc_drugTurfPay);
    - without, it gets angry (OT_drugTurfAnger per unit: ganja 1, blow 2), every player loses rep with
      it, it warns, and in the end raids the operation (OT_fnc_drugTurfAdd).

    Parameters:
        _this # 0: STRING - Operation id (a dispensary's business name, a lab's id, as on drugOps)
        _this # 1: STRING - "ganja" or "blow"
        _this # 2: NUMBER - Units sold or made

    Usage: [_opId, "ganja", 6] call OT_fnc_drugTurf; (server)

    Returns: ARRAY - [gang id, anger now, cut taken (cash or blow)], [] when it's on no gang's turf
*/

params ["_opId", "_kind", "_qty"];

if (!isServer || { _qty <= 0 }) exitWith { [] };
private _ops = server getVariable ["drugOps", []];
private _op = _ops param [_ops findIf { (_x select 0) isEqualTo _opId }, []];
if (_op isEqualTo []) exitWith { [] };
_op params ["", "_type", "_pos", "_town"];
([_pos] call OT_fnc_drugTurfGang) params [["_gangId", -1], ["_gang", []]];
if (_gangId < 0) exitWith { [] };

private _cls = ["OT_Ganja", "OT_Blow"] select (_kind isEqualTo "blow");
if (([_gangId] call OT_fnc_drugTurfDealOf) isNotEqualTo []) exitWith {
    // Their cut
    private _cut = 0;
    private _price = [_town, _cls] call OT_fnc_getDrugPrice;
    if (_type isEqualTo "lab") then {
        _cut = round (_qty * OT_drugTurfCut);
        if (_cut > 0) then {
            _cut = [_opId call OT_fnc_drugLabContainer, _cls, _cut] call OT_fnc_removeFromCargo;
            if (_cut > 0) then {
                [_gangId, "blow", _cut, _cut * _price] call OT_fnc_drugTurfPay;
                format ["%1's cut of %2: %3 blow", _gang select 8, [_op] call OT_fnc_drugTurfOpLabel, _cut] remoteExec ["OT_fnc_notifyMinor", 0, false];
            };
        };
    } else {
        _cut = round (_qty * _price * OT_drugTurfCut);
        if (_cut > 0) then {
            // Once the cycle has banked the sale (it adds the income after this hook)
            [{ [-(_this select 0)] call OT_fnc_resistanceFunds }, [_cut], 1] call CBA_fnc_waitAndExecute;
            [_gangId, "cash", _cut, _cut] call OT_fnc_drugTurfPay;
            format ["%1's cut of %2: $%3", _gang select 8, [_op] call OT_fnc_drugTurfOpLabel, _cut] remoteExec ["OT_fnc_notifyMinor", 0, false];
        };
    };
    [_gangId, 0, _cut]
};

private _points = _qty * (OT_drugTurfAnger getOrDefault [_kind, 1]);
private _anger = [_gangId, _points, allPlayers - (entities "HeadlessClient_F"), ["op", _op]] call OT_fnc_drugTurfAdd;
[_gangId, _anger, 0]
