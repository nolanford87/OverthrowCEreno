// Overthrow CE QA tools - optional addon, only loaded when added to the mod list.
// Adds "Overthrow QA" to the Zeus Enhanced right-click menu to run the automated QA test suites.
// Can also be run from the debug console: ["bugfixes"] spawn OTQA_fnc_run;

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
            class spawnWarehouse {}; // Zeus helper
            // Bug fix QA tests: the suite, and the tests for each fix batch it's made of
            class testsBugFixes {};
            class testsCommon {};
            class testsBatch1 {};
            class testsBatch2 {};
            class testsBatch3 {};
            class testsBatch4 {};
            class testsBatch5 {};
            class testsBatch6 {};
            class testsBatch7 {};
            class testsBatch8 {};
            class testsBatch9 {};
            // Review and DLC QA tests: the suite for the fixes made after the nine batches
            class testsFollowups {};
            class testsReview {};
            class testsDLC {};
            class testsGarage {};
            // Occupier QA tests: every "Occupying faction" lobby option
            class testsOccupiers {};
        };
    };
};

class zen_context_menu_actions {
    class OTQA {
        displayName = "Overthrow QA";
        condition = "isServer";
        priority = 1;
        class OTQA_bugfixes {
            displayName = "Run bug fix QA tests";
            statement = "['bugfixes'] spawn OTQA_fnc_run";
        };
        class OTQA_followups {
            displayName = "Run review and DLC QA tests";
            statement = "['followups'] spawn OTQA_fnc_run";
        };
        class OTQA_occupiers {
            displayName = "Run occupier QA tests";
            statement = "['occupiers'] spawn OTQA_fnc_run";
        };
        class OTQA_spawnWarehouse {
            displayName = "Spawn my warehouse here";
            statement = "[[AGLToASL screenToWorld getMousePosition, _position] select !isNil '_position', player] remoteExecCall ['OTQA_fnc_spawnWarehouse', 2]";
        };
    };
};
