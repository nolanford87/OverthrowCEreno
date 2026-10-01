/*
    Description:
    Original real-time pace (OT_fnc_timePace, 4 / time speed): job time limits in real time (15 real
    minutes per game hour), taxes and leases at 1.5x the original rate per real hour, businesses,
    factory, propaganda and stability drift at the original rate. Part of the current QA tests.

    Returns: ARRAY - [[name, code], ...]
*/

"Pace: a new job's 'Expires in' shows real time, 15 minutes per game hour of its limit (Kill NATO 30 min, 6 h jobs 1 h 30 min, 24 h jobs 6 h), and counts down by real minutes" call OTQA_fnc_manual;
"Pace: at 24x tax income comes every 15 minutes at a quarter of the amount it used to be, leases too" call OTQA_fnc_manual;

[
    ["Pace: 4 / time speed", {
        private _pace = call OT_fnc_timePace;
        ["Pace: 4 / the current time speed", abs (_pace - (4 / (timeMultiplier max 1))) < 0.001, format ["time speed %1, pace %2", timeMultiplier, _pace]] call OTQA_fnc_check;
    }],
    ["Pace: income, businesses and propaganda accumulate", {
        // Each hourly system adds the pace every game hour and runs when it reaches 1
        private _start = time;
        private _hour = date select 3;
        waitUntil { sleep 1; (date select 3) isNotEqualTo _hour || { time > _start + 200 } };
        sleep 12; // The loops run every 5-10 s
        private _business = missionNamespace getVariable ["OT_paceBusiness", -1];
        private _propaganda = missionNamespace getVariable ["propaganda_pace", -1];
        ["Pace: businesses and propaganda keep their share of an hour", _business >= 0 && { _business < 1 } && { _propaganda >= 0 } && { _propaganda < 1 },
            format ["businesses %1, propaganda %2 (time speed %3)", _business, _propaganda, timeMultiplier]] call OTQA_fnc_check;
    }, 240]
]
