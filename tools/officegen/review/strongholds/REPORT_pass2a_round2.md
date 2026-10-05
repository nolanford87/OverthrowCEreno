# Strongholds, pass 2a round 2: Athira's gates widened and moved

Round 1's in-game check: Kavala and Zaros are fine and unchanged. Athira came back "unknown (1 of 8 routes not computed)"
at every tier, **T2 included**. T2 has no ring, so the walk's start was at fault, not only the gates.

## The walk's start: please move it
(-3.3, -8.8) is in a slot 1.3-1.6 m wide. The house front is north of it, the T2 screen 0.4 m south (a long bag at
(-2.4, -9.4)) and the low city wall at x -4.4 just west. That is too narrow for the engine at any tier. It is inside the
T3 ring, but no good. **Please start Athira at (6.5, -0.4).** That point is east of the house, between the house (x 5.0)
and the inner east line (its inner face x 7.95), between the T2 bags at the east window (to y -3.7) and the side door
(from y 2.85), and just inside the new east gate. At T2 the way east is open.

## The gates (Athira only; every one at least 3.5 m wide, nothing standing behind)
Both gates are now on the east side. That is the occupier's way in from the east track (x ~30, the nearest road):
through the outer ring's x 22 line, the strip north of the courtyard, the courtyard's own opening (between the pillars
(12.3, 7.0) and (17.1, 5.8), 4.9 m), then the courtyard, to the inner ring's east line.
Round 1's south gate is gone, its pieces back as in the baseline. The T2 screen stood 0.5 m behind it, and the yard was
2.4 m deep. T4's west gate is gone too: it opened into a pocket between the low wall and the veranda's bags.

| Tier | Ring | Gate [x, y] | Width | Faces / why | Pieces |
|---|---|---|---|---|---|
| 3 | the ring | [8.8, -0.35] | 3.9 m | The east line onto the courtyard, between the side door's bag and the east window's bag. Behind the opening there are 2.9 m to the house and 6.5 m clear along it. | out: HB5 (8.80, -0.90). Added: HB1 (8.80, -3.01), 0.3 m into the HB1 at y -4.11. The opening runs y -2.31..1.61. |
| 4 | inner (H) | [8.8, -0.35] | 3.9 m | T3's gate, kept. | the same as T3 |
| 4 | outer (Mil) | [22.0, 5.45] | 4.0 m | The x 22 line, facing the east track 8 m out. It is 13 m east and 6 m north of the inner gate: a man comes in heading west and has to go through the courtyard's opening and across the courtyard to the inner gate, under both rings. The slanting courtyard wall meets the line at y 3.3, the opening's south edge. | out: Mil (22.00, 5.44). Mil (22.00, 9.14) moved to (22.00, 9.54), its end in the corner with the cap at y 11.33. The opening runs y 3.4..7.49. |
| 5 | outer (Mil) | [22.0, 5.7] | 3.6 m | T4's gate, kept. The user's CncWall1 on the joint at (22.06, 3.25) stays, so the opening starts at y 3.9. | the same as T4 |

T4 and T5 lose the outer south gate at x -10.06: the Mil is back.

## My closure check (`strongholds_pass2a.py`, from (6.5, -0.4))
| Tier | Gates shut | Gates open |
|---|---|---|
| 3 | closed | out through [8.8, -0.35] |
| 4 | closed | out through both gates |
| 5 | closed with House_Small_02 solid; open through it as pass 1 modelled it | out through [22.0, 5.7] |

T5's possible leak through House_Small_02 comes from the user's T5 (no inner ring, and its north side closes on that house),
as in round 1's report. Your round 1 check never got that far, so it is still to be seen. The x 22 line's T5 CncWall1 clips
the city wall there (`[22.1, 3.3]`, the user's piece). I left it.
