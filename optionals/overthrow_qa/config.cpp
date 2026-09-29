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
            class testsBatch7 {};
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
        class OTQA_batch7 {
            displayName = "Run batch 7 tests (wanted / search)";
            statement = "['7'] spawn OTQA_fnc_run";
        };
    };
};
