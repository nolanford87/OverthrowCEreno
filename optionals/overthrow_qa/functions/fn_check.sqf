/*
    Description:
    Records one QA result.

    Parameters:
        _this # 0: STRING - Name of the check
        _this # 1: BOOL - Did it pass
        _this # 2: STRING - Details (expected/actual values)

    Usage: ["Scramble cost", _cost isEqualTo 250, format ["cost %1", _cost]] call OTQA_fnc_check;

    Returns: BOOL - The result
*/

params ["_name", "_ok", ["_detail", ""]];

if !(_ok isEqualType true) then {
    _detail = format ["check returned %1 instead of true/false. %2", _ok, _detail];
    _ok = false;
};

OTQA_results pushBack [_name, _ok, _detail];
diag_log format ["OT_QA %1 [%2] %3 | %4", ["FAIL", "PASS"] select _ok, OTQA_currentGroup, _name, _detail];

_ok;
