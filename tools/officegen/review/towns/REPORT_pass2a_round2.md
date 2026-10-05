# Towns: pass 2a round 2

Script `tools/officegen/drafting/towns_pass2a.py`, drafts re-written (3f1f6523). All gates are now at least 3.6 m
wide, apart from Rodopoli's (3.1 m, the yard's real gap, which the game walks through). Kalochori, Neochori, Charkia,
Panochori and Paros T3 are unchanged. In the agent's walk every tier 3 and 4 is closed with the gates shut and gets
out through every gate with them open; `tl.check()` passes apart from the baseline's three known problems.

- **Agios Dionysios (the agent's cut):** both gates widened to 3.6 m: T3 west face (-13.0, -5.7), T4 west wall
  (-20.0, -4.9), the lines re-laid evenly beside them.
- **Chalkeia:**
  - T3 closed (the agent's cut): its 1-high piece narrowed the opening with the veranda's west steps right behind.
    Now the HB in front of the door bay comes out whole: a 4.25 m opening at (-7.0, -6.1).
  - T4 west, through the garage (baseline): the garage has doors at both ends. A new high wall along the track's
    west verge, x -17.7, from the garage's north-east corner (y -4.9) to the south wall (y -28.4), 7 walls. The garage
    and two shops are now outside.
  - T4 south, down x -8.3 (baseline): the track runs on south through the south wall (the probe's road stops
    short), and walls on a road don't stop the path finding. **Second gate**: south wall (-10.0, -28.0), 6.6 m, the
    road's width: the occupier's vehicles use the road both ways.
  - T4 north: the north gate widened to the road's width, (-12.9, 24.0), 6.9 m.
- **Paros T4 (baseline):** the user's T4 dropped the T3 ring's west and north faces, opening the side yard and north
  yard east, and round the big north house (a door on the north yard). Closed on the T3 north face's line as high
  walls: x -7.3 from y 8.4 to the north wall (5 walls); y 8.8 from x -7.7 to 16.2 (8 walls); x 16.2 from y 9.2 to
  2.3 (2 walls). Some joints overlap 0.8-0.9 m. Gates unchanged.
- **Rodopoli T4 (baseline):** the way out ran up the lane behind the house and out its north end over the tracks;
  the user's T4 dropped the T3 runs closing the lane. Those 10 H-barriers go back at T4 as they stand at T3.
- **Sofia T3 (the agent's cut):** every game route leaves the veranda down its west steps, never by its south end,
  so the T3 gate moves to the west face in front of the steps: a 4.45 m opening at (-8.6, -4.8). T4's gate widened
  to 3.6 m at (-8.6, -15.0).
- **Therisa T4 (baseline):** the way out ran through the shop west of the house (doors both sides). The user's T3
  west face goes back on its line as high walls: x -14.6 from y -17.6 to -5.2, 4 walls. Gates unchanged.

**Open point:** Rodopoli's gate is 3.1 m (2.95 open), the yard's real south gap. Widening it means hiding part of
the old city wall.

(Written by the towns agent; saved by the lead.)
