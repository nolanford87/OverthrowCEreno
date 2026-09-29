// Overthrow CE QA tools - optional addon, only loaded when added to the mod list.
// Adds "Overthrow QA" to the Zeus Enhanced right-click menu to run automated checks for each fix batch.
// Can also be run from the debug console: ["all"] spawn OTQA_fnc_run;

class CfgPatches {
    class OT_Overthrow_QA {
        name = "Overthrow CE - QA tools";
        author = "nolanford87";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.18;
        requiredAddons[] = {"OT_Overthrow_Main", "cba_main"};
    };
};

class CfgFunctions {
    class OTQA {
        class QA {
            file = "\OT\addons\overthrow_qa\functions";
            class run {};
            class check {};
            class manual {};
            class testsCommon {};
            class testsBatch1 {};
            class testsBatch2 {};
            class testsBatch3 {};
            class testsBatch4 {};
            class testsBatch5 {};
            class testsBatch6 {};
            class testsBatch7 {};
            class testsBatch8 {};
        };
    };
};

class zen_context_menu_actions {
    class OTQA {
        displayName = "Overthrow QA";
        condition = "isServer";
        priority = 1;
        class OTQA_all {
            displayName = "Run all tests";
            statement = "['all'] spawn OTQA_fnc_run";
        };
        class OTQA_common {
            displayName = "Run common checks";
            statement = "['common'] spawn OTQA_fnc_run";
        };
        class OTQA_batch1 {
            displayName = "Run batch 1 tests (economy)";
            statement = "['1'] spawn OTQA_fnc_run";
        };
        class OTQA_batch2 {
            displayName = "Run batch 2 tests (NATO)";
            statement = "['2'] spawn OTQA_fnc_run";
        };
        class OTQA_batch3 {
            displayName = "Run batch 3 tests (jobs)";
            statement = "['3'] spawn OTQA_fnc_run";
        };
        class OTQA_batch4 {
            displayName = "Run batch 4 tests (spawning)";
            statement = "['4'] spawn OTQA_fnc_run";
        };
        class OTQA_batch5 {
            displayName = "Run batch 5 tests (save / load)";
            statement = "['5'] spawn OTQA_fnc_run";
        };
        class OTQA_batch6 {
            displayName = "Run batch 6 tests (player setup / waypoints)";
            statement = "['6'] spawn OTQA_fnc_run";
        };
        class OTQA_batch7 {
            displayName = "Run batch 7 tests (wanted / search)";
            statement = "['7'] spawn OTQA_fnc_run";
        };
        class OTQA_batch8 {
            displayName = "Run batch 8 tests (warehouse / items)";
            statement = "['8'] spawn OTQA_fnc_run";
        };
    };
};
