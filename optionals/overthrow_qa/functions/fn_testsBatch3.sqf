/*
    Description:
    Batch 3 (fix/jobs-locality): accepting and assigning jobs, job completion bookkeeping.
    Uses fake jobs whose success is controlled by the test. Game state isn't preserved.

    Returns: ARRAY - [[name, code], ...] run by OTQA_fnc_run
*/

"MP: a non-host player requests 'Recon of <base>' at a faction rep and completes it (it used to never complete or expire)" call OTQA_fnc_manual;
"Accept a gang drug or weapon run and let the delivery person die: you lose gang reputation" call OTQA_fnc_manual;
"Deliver faction weapons or medical supplies, get out of the vehicle before it's checked: you still get paid" call OTQA_fnc_manual;

// A job that succeeds once OTQA_jobDone is set, and records that its end code ran
OTQA_b3_makeJob = {
    params ["_title"];
    [
        [_title, "QA test job"],
        getPos player,
        { OTQA_jobSetupRan = true; true },
        { false },
        { !isNil "OTQA_jobDone" },
        { OTQA_jobEnded = true },
        []
    ]
};
OTQA_b3_waitEnd = {
    private _timeout = time + 20;
    waitUntil { sleep 0.5; !isNil "OTQA_jobEnded" || { time > _timeout } };
    !isNil "OTQA_jobEnded";
};

[
    ["Accepting a job", {
        OTQA_jobDone = nil;
        OTQA_jobEnded = nil;
        OTQA_jobSetupRan = nil;
        OT_jobShowingID = "OTQA_ACCEPTED";
        OT_jobShowing = ["QA accepted job"] call OTQA_b3_makeJob;
        OT_jobShowingExpiry = 10;
        call OT_fnc_acceptJob;

        ["Job setup runs when accepting", !isNil "OTQA_jobSetupRan", ""] call OTQA_fnc_check;
        ["Accepted job is listed as active", "OTQA_ACCEPTED" in (spawner getVariable ["OT_activeJobIds", []]), ""] call OTQA_fnc_check;

        // The job checks start 5 seconds after it starts
        sleep 6;
        OTQA_jobDone = true;
        ["Accepted job completes", call OTQA_b3_waitEnd, ""] call OTQA_fnc_check;
        sleep 1;
        ["Completed job leaves the active list", !("OTQA_ACCEPTED" in (spawner getVariable ["OT_activeJobIds", []])), ""] call OTQA_fnc_check;
    }],

    ["Job offered by the job loop is removed once done", {
        OTQA_jobDone = nil;
        OTQA_jobEnded = nil;
        // A global job the job loop always offers: name, target, condition, code, repeat, chance, expiry, requestable
        private _jobdef = ["OTQA_ASSIGNED", "global", { true }, { ["QA assigned job"] call OTQA_b3_makeJob }, 1, 100, 10, false];
        OT_allJobs pushBack _jobdef;
        job_system_counter = 11;
        private _timeout = time + 20;
        waitUntil { sleep 0.5; ("OTQA_ASSIGNED" in (spawner getVariable ["OT_activeJobIds", []])) || { time > _timeout } };
        OT_allJobs deleteAt (OT_allJobs find _jobdef);

        private _count = { _x isEqualTo "OTQA_ASSIGNED" } count (spawner getVariable ["OT_activeJobIds", []]);
        ["Job loop lists the job once", _count isEqualTo 1, format ["listed %1 times", _count]] call OTQA_fnc_check;

        sleep 6;
        OTQA_jobDone = true;
        ["Assigned job completes", call OTQA_b3_waitEnd, ""] call OTQA_fnc_check;
        sleep 1;
        ["Assigned job leaves the active list, so it can be offered again", !("OTQA_ASSIGNED" in (spawner getVariable ["OT_activeJobIds", []])), ""] call OTQA_fnc_check;
    }]
]
