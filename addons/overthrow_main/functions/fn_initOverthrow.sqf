if (!isServer) exitWith {};

if !(isClass (configFile >> "CfgPatches" >> "OT_Overthrow_Main")) exitWith {
    diag_log "Overthrow addon not detected, you must add @Overthrow to your -mod commandline";
    "Overthrow addon not detected, you must add @Overthrow to your -mod commandline" call OT_fnc_notifyStart;
};

if (isDedicated) then {
    server_dedi = true;
} else {
    server_dedi = false;
};
publicVariable "server_dedi";

missionNamespace setVariable ["OT_varInitDone", false, true];

// This is a saved namespace, this is persistent.
server = true call CBA_fnc_createNamespace;
publicVariable "server";

// This is not a saved namespace, this is not persistent.
server_nosave = true call CBA_fnc_createNamespace;
publicVariable "server_nosave";

players_NS = true call CBA_fnc_createNamespace;
publicVariable "players_NS";
cost = true call CBA_fnc_createNamespace;
publicVariable "cost";

// This namespace contains a list of warehouses -
// instead of warehouse contents like in OT+
warehouse = true call CBA_fnc_createNamespace;
publicVariable "warehouse";

warehouse_shared = true call CBA_fnc_createNamespace;
publicVariable "warehouse_shared";

spawner = true call CBA_fnc_createNamespace;
publicVariable "spawner";
templates = true call CBA_fnc_createNamespace;
publicVariable "templates";
owners = true call CBA_fnc_createNamespace;
publicVariable "owners";
buildingpositions = true call CBA_fnc_createNamespace;
publicVariable "buildingpositions";
OT_civilians = true call CBA_fnc_createNamespace;
publicVariable "OT_civilians";

OT_centerPos = getArray (configFile >> "CfgWorlds" >> worldName >> "centerPosition");

// Init basic variables
[OT_fnc_initBaseVar] call CBA_fnc_directCall;
call compileScript ["initVar.sqf", false];

// Occupying faction from the lobby before final variable init & detection takes place,
// a loaded game switches to the one stored in its save (see below)
[["ot_enemy_faction", 0] call BIS_fnc_getParamValue] call OT_fnc_applyOccupier;

// Dedicated servers need a separate definition for mission params
if (isDedicated) then {
    OT_factoryProductionMulti = (["ot_factoryproductionmulti", 0] call BIS_fnc_getParamValue) * 0.01;
    OT_gangMemberCap = ["ot_gangmembercap", 0] call BIS_fnc_getParamValue;
    OT_gangResourceCap = ["ot_gangresourcecap", 0] call BIS_fnc_getParamValue;
};

// Call final variable init
[OT_fnc_initVar] call CBA_fnc_directCall;

diag_log "Overthrow: Server Pre-Init";
server setVariable ["StartupType", "", true];
call OT_fnc_initVirtualization;

OT_tpl_checkpoint = [] call compileScript ["data\templates\NATOcheckpoint.sqf", true];

[] spawn {
    if (false /*isDedicated && profileNamespace getVariable ["OT_autoload",false]*/ ) then {
        diag_log "== OVERTHROW == Mission autoloaded as per settings. Toggle in the options menu in-game to disable.";
        diag_log "== OVERTHROW == Waiting for a player to connect!";
        waitUntil {
            sleep 1;
            ([] call CBA_fnc_players) isNotEqualTo [];
        };
        [] spawn OT_fnc_loadGame;
    };

    waitUntil {
        sleep 0.1;
        server getVariable ["StartupType", ""] != "";
    };

    // The occupier is stored with the save: a new game takes the lobby choice, a loaded game keeps
    // its own (saves from before this have none, they take the lobby choice too). Clients follow it.
    private _occupier = server getVariable ["OT_occupier", -1];
    if (_occupier isEqualTo -1) then { _occupier = ["ot_enemy_faction", 0] call BIS_fnc_getParamValue };
    if (_occupier isNotEqualTo OT_occupierChoice) then { [_occupier] call OT_fnc_applyOccupier };
    server setVariable ["OT_occupier", _occupier, true];

    // Occupier loadouts: picked on the new game screen, a loaded game keeps its own (older saves: the lobby's)
    server setVariable ["OT_randomLoadoutMode", [server getVariable ["OT_randomLoadoutMode", -1]] call OT_fnc_setLoadoutMode, true];

    private _initStart = diag_tickTime;

    // Lobby parameters override the defaults from initVar (only the server sets the time multiplier)
    OT_timeMultiplierDay = ["ot_timemultiplierday", OT_timeMultiplierDay] call BIS_fnc_getParamValue;
    OT_timeMultiplierNight = ["ot_timemultipliernight", OT_timeMultiplierNight] call BIS_fnc_getParamValue;

    if (OT_fastTime) then {
        // The income loop only switches speed at 07:00 and 19:00, so start at the right one for the loaded hour
        setTimeMultiplier ([OT_timeMultiplierNight, OT_timeMultiplierDay] select ((date select 3) >= 7 && { (date select 3) < 19 }));
    };

    //Init factions
    (selectRandom OT_loadingMessages) remoteExec ['OT_fnc_notifyStart', 0];
    [OT_fnc_initNATO] call CBA_fnc_directCall; // directCall is way faster, but won't show script errors, so switch to a normal call for debug!
    (selectRandom OT_loadingMessages) remoteExec ['OT_fnc_notifyStart', 0];
    [] call OT_fnc_factionNATO;
    (selectRandom OT_loadingMessages) remoteExec ['OT_fnc_notifyStart', 0];
    [] call OT_fnc_factionGUER;
    (selectRandom OT_loadingMessages) remoteExec ['OT_fnc_notifyStart', 0];
    [] call OT_fnc_factionCRIM;
    (selectRandom OT_loadingMessages) remoteExec ['OT_fnc_notifyStart', 0];

    [OT_fnc_initEconomyLoad] call CBA_fnc_directCall; // [] call OT_fnc_initEconomyLoad;
    (selectRandom OT_loadingMessages) remoteExec ['OT_fnc_notifyStart', 0];

    //Game systems
    [] call OT_fnc_weatherSystem;
    (selectRandom OT_loadingMessages) remoteExec ['OT_fnc_notifyStart', 0];
    [] call OT_fnc_incomeSystem;
    (selectRandom OT_loadingMessages) remoteExec ['OT_fnc_notifyStart', 0];
    [] call OT_fnc_jobSystem;
    [] spawn OT_fnc_propagandaSystem; // Must be spawned due to delay

    // Declare systems done
    OT_SystemInitDone = true;
    publicVariable "OT_SystemInitDone";

    //Init virtualization
    waitUntil { !isNil "OT_economyLoadDone" };
    [] spawn OT_fnc_runVirtualization;
    [] spawn OT_fnc_initHunting; // Hunting spots, livestock

    //ACE3 Arsenal default loadouts
    {
        _x params ["_cls", "_loadout"];
        [_cls call OT_fnc_vehicleGetName, _loadout] call ace_arsenal_fnc_addDefaultLoadout;
    } forEach (OT_Recruitables);
    ["Police", OT_Loadout_Police] call ace_arsenal_fnc_addDefaultLoadout;

    //Subscribe to events
    addMissionEventHandler ["PlayerConnected", OT_fnc_playerConnectHandler];
    addMissionEventHandler ["HandleDisconnect", OT_fnc_playerDisconnectHandler];
    ["Building", "Dammaged", OT_fnc_buildingDamagedHandler] call CBA_fnc_addClassEventHandler;

    //ACE3 events
    ["ace_cargoLoaded", OT_fnc_cargoLoadedHandler] call CBA_fnc_addEventHandler;
    ["ace_common_setFuel", OT_fnc_refuelHandler] call CBA_fnc_addEventHandler;
    ["ace_explosives_place", OT_fnc_explosivesPlacedHandler] call CBA_fnc_addEventHandler;
    ["ace_tagCreated", OT_fnc_taggedHandler] call CBA_fnc_addEventHandler;
    ["ace_repair_setWheelHitPointDamage", OT_fnc_wheelStateHandler] call CBA_fnc_addEventHandler;
    ["ace_treatmentSucceded", OT_fnc_healedHandler] call CBA_fnc_addEventHandler;

    //Overthrow events
    ["OT_QRFstart", OT_fnc_QRFStartHandler] call CBA_fnc_addEventHandler;
    ["OT_QRFend", OT_fnc_QRFEndHandler] call CBA_fnc_addEventHandler;

    addMissionEventHandler ["EntityKilled", OT_fnc_deathHandler];

    ["OT_autosave_loop"] call OT_fnc_addActionLoop;
    [
        "OT_civilian_cleanup_crew",
        "time > OT_cleanup_civilian_loop",
        "
            OT_cleanup_civilian_loop = time + (5 * 60);
            private _totalcivs = { !captive _x } count (units civilian);
            if (_totalcivs < 50) exitWith {};
            {
                if (!(isPlayer _x) && !(_x getVariable ['shopcheck', false]) && { ({ side _x isEqualTo civilian } count (_x nearEntities ['CAManBase', 150])) > round (150 * OT_spawnCivPercentage) }) then {
                    private _unit = _x;
                    [_unit] call OT_fnc_cleanupUnit;
                };
            } forEach (units civilian);
        "
    ] call OT_fnc_addActionLoop;

    OT_serverInitDone = true;
    publicVariable "OT_serverInitDone";
    diag_log "Overthrow: Server Pre-Init Done";

    private _initFinish = diag_tickTime;
    private _initTime = _initFinish - _initStart;
    diag_log format ["Overthrow: server init finished in %1", _initTime];
};
