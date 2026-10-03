// Overthrow CE QA tools - optional addon, only loaded when added to the mod list.
// Adds "Overthrow QA" to the Zeus Enhanced right-click menu to run the automated QA test suites.
// Gives every player Zeus while it's loaded (OTQA_fnc_autoZeus).
// Can also be run from the debug console: ["current"] spawn OTQA_fnc_run; (or "archive")

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
            class autoZeus { postInit = 1; }; // Every player gets Zeus while the QA addon is loaded
            // Current QA tests (new changes) and archived QA tests (everything that passed before)
            class testsCurrent {};
            class testsArchive {};
            class testsIntel {};
            class testsFOB {};
            class testsDLCVehicles {};
            class testsPace {};
            class testsHunting {};
            class testsFishing {};
            class testsLogistics {};
            class testsLogisticsAirfields {};
            class testsSmuggling {};
            class testsHijacks {};
            class testsFisherman {};
            class testsPoachers {};
            class testsAirdropEscort {};
            class testsCounterattacks {};
            class testsBodies {};
            class testsFOBVirtual {};
            class testsDrugsGanja {};
            class testsDrugsBlow {};
            class testsDrugRaids {};
            class testsDrugTurf {};
            class check {};
            class manual {};
            class spawnWarehouse {}; // Zeus helper
            class dumpFactions {}; // Archived (no Zeus entry): creator DLC factions to the RPT, [] spawn OTQA_fnc_dumpFactions
            class probeBuilding {}; // Zeus helper: a building's floor plan to the RPT
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
        class OTQA_current {
            displayName = "Run current QA tests";
            statement = "['current'] spawn OTQA_fnc_run";
        };
        class OTQA_archive {
            displayName = "Run archived QA tests";
            statement = "['archive'] spawn OTQA_fnc_run";
        };
        class OTQA_probeShed {
            displayName = "Map the industrial shed's floor plan to RPT";
            statement = "['Land_i_Shed_Ind_F'] spawn OTQA_fnc_probeBuilding";
        };
        class OTQA_spawnWarehouse {
            displayName = "Spawn my warehouse here";
            statement = "[[AGLToASL screenToWorld getMousePosition, _position] select !isNil '_position', player] remoteExecCall ['OTQA_fnc_spawnWarehouse', 2]";
        };
    };
};
