/*
    Description:
    The economy runs on real time, at Overthrow's original 4x pace, whatever the time speed (which
    only sets the day/night cycle and weather): taxes and leases every 15 minutes (a quarter of the
    full amount, influence rounded up), businesses and propaganda every 15 minutes, the resistance's
    per-minute work (factory, stability drift) every 15 seconds, job time limits 15 minutes per game
    hour, scheduled convoys 30 minutes after being ordered. Part of the current QA tests.

    Returns: ARRAY - [[name, code], ...]
*/

"Real time: a new job's 'Expires in' shows real time, 15 minutes per game hour of its limit (Kill NATO 30 min, 6 h jobs 1 h 30 min, 24 h jobs 6 h), and counts down by real minutes" call OTQA_fnc_manual;
"Real time: tax income comes every 15 minutes at a quarter of the old amount, also after changing the time speed lobby setting" call OTQA_fnc_manual;
"Real time: a business's info shows 'Next cycle: in N min'" call OTQA_fnc_manual;

[
    ["Real time: the economy's timers", {
        GUER_faction_loop_data params ["_nextMinute", "_nextBusiness"];
        private _now = time;
        ["Real time: tax income within the next 15 minutes", (income_system_next - _now) > -10 && { (income_system_next - _now) <= 900 }, format ["in %1 s", round (income_system_next - _now)]] call OTQA_fnc_check;
        ["Real time: propaganda within the next 15 minutes", (propaganda_system_next - _now) > -15 && { (propaganda_system_next - _now) <= 900 }, format ["in %1 s", round (propaganda_system_next - _now)]] call OTQA_fnc_check;
        ["Real time: businesses within the next 15 minutes", (_nextBusiness - _now) > -10 && { (_nextBusiness - _now) <= 900 }, format ["in %1 s", round (_nextBusiness - _now)]] call OTQA_fnc_check;
        ["Real time: per-minute work within the next 15 seconds", (_nextMinute - _now) > -10 && { (_nextMinute - _now) <= 15 }, format ["in %1 s", round (_nextMinute - _now)]] call OTQA_fnc_check;

        // Doubling the time speed doesn't bring them sooner
        private _speed = timeMultiplier;
        setTimeMultiplier ((_speed * 2) min 120);
        sleep 20;
        GUER_faction_loop_data params ["_nextMinute2", "_nextBusiness2"];
        ["Real time: a faster clock doesn't bring the next payment sooner", income_system_next isEqualTo (income_system_next max 0) && { (_nextBusiness2 isEqualTo _nextBusiness) || { _nextBusiness2 >= _now + 880 } },
            format ["time speed %1 -> %2, businesses in %3 s", _speed, timeMultiplier, round (_nextBusiness2 - time)]] call OTQA_fnc_check;
        setTimeMultiplier _speed;
    }, 60],
    ["Real time: a scheduled convoy counts down in real seconds", {
        private _schedule = server getVariable ["NATOschedule", []];
        private _fresh = _schedule select { count _x > 5 };
        if (_fresh isEqualTo []) exitWith { "Real time: no convoy scheduled right now, the countdown wasn't checked" call OTQA_fnc_manual };
        private _before = (_fresh select 0) select 5;
        sleep 25;
        private _after = (_fresh select 0) select 5;
        ["Real time: the convoy countdown goes down with real time", (_before - _after) >= 15 && { (_before - _after) <= 35 }, format ["%1 s -> %2 s in 25 s", round _before, round _after]] call OTQA_fnc_check;
    }, 60]
]
