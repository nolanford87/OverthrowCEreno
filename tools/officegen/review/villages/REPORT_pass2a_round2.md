# Villages: pass 2a, round 2

No drafts changed. Alikampos, Dorida, Gravia, Lakka, Poliakko, Stavros and Telos passed in round 1. Neri is on hold
for the user's decision about the city wall. Selakano and Kore are the road problem (the game's path finding
ignores pieces standing on a road): every way out that misses the gate passes through the middle of a piece on a
road, not round a joint. The agent's flood fill from the house's doors finds both rings closed apart from the gate.

## Selakano (bearings 45, 90, 135)
- The route (0.1, -7.3) -> (4.4, -10.8) -> (10, -11.6) passes through the HBarrier_1 at (4.4, -11.3), the notch's
  east side where it meets the back line's 2-high piece at (8.2, -10.3). The joint overlaps about 1.2 m by 1.0 m.
- That piece is 2.5 m from the track's centre line; pass 1 put the notch on the track. The gap marker (17.5, -12.7)
  is where the route passes the ring's back-east corner outside, not the crossing.
- The top view shows the line whole there. The gate cut (x -4.6..-1.0) didn't touch this corner.
- A real fix would move the notch's east half off the track (a line at y -10.3 from x 8.2 to about 0.6, with a short
  side down to the gate): a change to a reviewed ring, left for the lead's / user's call.

## Kore (7 routes not through the gate)
The probe lists no roads for Kore at all.
- East (45, 90, 135): pass 1's accepted route, through the right line's 2-high piece at (17.5, -9.4) across the
  main road's west half. Top and street views show the line whole.
- Front-left (0, 315): new, as this round starts inside the house. Through the middle of the 2-high piece at
  (-11.0, 10.8); the corner joint with the HBarrier_1 at (-15.2, 10.5) overlaps about 0.8 m by 1.7 m. It's under a
  tree in the top view: check it from the street side or in the editor.
- 180: pass 1's route on this bearing, across the same road east of the house.
- 225 goes through the gate as meant.

(Written by the villages agent; saved by the lead.)
