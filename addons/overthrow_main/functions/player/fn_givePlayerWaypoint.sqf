params ["_target", "_destpos", ["_txt", ""], ["_radius", 5]];

while { (waypoints group _target) isNotEqualTo [] } do {
    deleteWaypoint ((waypoints group _target) select 0);
};
(group _target) addWaypoint [ASLToAGL (getPosASL player), 0];
private _wp = (group player) addWaypoint [_destpos, 15];
OT_missionMarker = _destpos;
OT_missionMarkerText = _txt;

// Only the watcher for the latest waypoint clears it, so an older one can't remove a newer waypoint
OT_waypointToken = (missionNamespace getVariable ["OT_waypointToken", 0]) + 1;
[_target, _radius, _wp, OT_waypointToken] spawn {
    params ["_target", "_radius", "_wp", "_token"];
    waitUntil {
        sleep 1;
        OT_waypointToken isNotEqualTo _token || { (player distance (waypointPosition _wp)) <= _radius };
    };
    if (OT_waypointToken isEqualTo _token) then {
        while { (waypoints group _target) isNotEqualTo [] } do {
            deleteWaypoint ((waypoints group _target) select 0);
        };
        OT_missionMarker = nil;
    };
};

_wp;
