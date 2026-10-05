# Strongholds, pass 2a round 3: Athira's gates on the west side, and a start inside the ring

Kavala and Zaros are unchanged. Athira only.

## 1. Did T3's west side leak? No: the start was on the wall
The fallback start (-6.7, 1.5) is on the T3 west line itself. The H-barriers there stand at x -6.8, from x -7.65 to -5.95 deep:
the HB5 at y -2.11 (-5.01..0.79) and the HB3 at y 2.12 (0.32..3.92). So the man was put down outside the line, at
(-8.6, 1) where every route starts. The "gaps" at (-9.5, 2.6), (-8.9, -0.3) and (-9.6, -2.8) are the last points
within 3 m of that same line on his way west. He never crossed it.

The T3 ring doesn't rely on the low city wall. That wall runs south from the house's south-west corner at x -4.4, inside the
ring, and the ring's lines don't use it. The west line closes on its own: x -6.8 from the south line's corner up to y 3.9,
capped into the house's north room at y 2.6.

The same goes for pass 1: its Athira "closed" results came from (-3.3, -8.8), which you've now found doesn't get out even on
the bare site. So Athira's T3-T5 closure gets its first real test in this round.

## 2. The gates, where the bare-site walk gets out
Round 2's bare-site routes leave from the west of the house, going west, north up the lane and south down the lane past
the west lot. The east side (the courtyard, the house's east strip) is a dead end in the game. So the gates are back on the west and
south, the way the bare-site walk goes, and round 2's east gates are closed again (the baseline's pieces). Every opening is
3.5 m or wider:

| Tier | Ring | Gate [x, y] | Width | Faces / why | Pieces |
|---|---|---|---|---|---|
| 3 | the ring | [-6.8, -6.95] | 3.9 m | The west line, facing the west lot, onto the house's south-west corner and the veranda's open west side. The main door is at the veranda's south end. | out: HB5 (-6.80, -7.44). Added: HB1 (-6.80, -9.60) on the corner with the south line. The opening runs y -8.9..-5.01. Also out: the T2 veranda bag (-5.3, -4.2), which stood 0.65 m inside the line, behind the opening's north edge. |
| 4 | inner (H) | [-6.8, -6.95] | 3.9 m | T3's gate, kept. | the same as T3 |
| 4 | outer (Mil) | [-10.04, -13.0] | 3.6 m | The south face at the west lot's mouth, onto the lane south that the bare-site routes take (through (-11.7, -10.3) and (-13.2, -16)). It is 7 m from the inner gate and at right angles to it: a man comes in heading north and turns east across the west lot to the inner gate. | out: Mil (-10.06, -13). Neighbours eased apart within their joints: Mil (-13.77) to (-13.87), its end in the corner with the west face; Mil (-6.35) to (-6.20), 0.62 m into the Mil at -2.72. The opening runs x -11.82..-8.25. |
| 5 | outer (Mil) | [-10.04, -13.0] | 3.6 m | T4's gate, kept. The user's T5 has no inner ring. | the same as T4 |

Nothing stands just behind either gate. Behind the inner one: the pocket south-west of the house and the veranda's open
side. Behind the outer one: the west lot's open ground, 6 m to the inner ring's corner.

## 3. The start: (-5.5, -6.6)
**Please start Athira at model [-5.5, -6.6].** It is inside the T3 ring, right in front of the inner gate, 0.9 m off the house's west
line and clear of the low wall (x -4.4, south of y -7.5). It is inside the T4 and T5 outer rings too. With no layout it is in the open
west of the house, a metre and a half from the spot (-6.7, 1.5) whose routes your bare-site test found getting out
west, north and south.

## My closure check (`strongholds_pass2a.py`, from (-5.5, -6.6))
| Tier | Gates shut | Gates open |
|---|---|---|
| 3 | closed | out through [-6.8, -6.95] |
| 4 | closed | out through both gates |
| 5 | closed with House_Small_02 solid (your round 2 check had T5 closed: it didn't leak there) | out through [-10.04, -13.0] |
