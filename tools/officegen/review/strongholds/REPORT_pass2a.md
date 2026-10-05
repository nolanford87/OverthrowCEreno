# Strongholds, pass 2a: the gates (Kavala, Athira, Zaros)

Script: `tools/officegen/drafting/strongholds_pass2a.py`. Drafts: `tools/officegen/layouts/drafts/{Kavala,Athira,Zaros}.txt`.
Each town starts from `tl.baseline(town)`. Only the gates change it: pieces taken out of a line, the line's ends re-fitted
at the opening, a `tl.gate()` marker at the gap's middle (the marker's direction is the line's run). There is one gate
per ring and no second gates. Positions are model [x, y] ("south" is -y). Widths are the clear gap between the pieces' measured ends.

## Kavala (the hospital)
The main door is at (2.9, 16.4), facing west onto the forecourt. The main road (the only `ROAD` in the probe) meets the west
track at (-45, 10-15).

| Tier | Ring | Gate [x, y] | Width | Faces / why | Pieces removed / added |
|---|---|---|---|---|---|
| 3 | the user's ring (forecourt side) | [-11.4, 16.0] | 3.7 m | The forecourt line, straight opposite the main door. It faces the forecourt plaza, which vehicles reach from the west road, so it is vehicle width. | out: HB5 (-11.40, 15.49). Added: HB1 (-11.40, 13.48), re-fitting the line's end 0.3 m into the HB5 at y 10.18. The opening runs y 14.18..17.90. Also out: the T2 long bag (-8.9, 16.5), which stood 1.4 m behind the opening, across the way in. |
| 4 | inner (H) | [-11.4, 16.0] | 3.7 m | T3's gate, kept. | the same as T3, in T4's forecourt line, and the same bag |
| 4 | outer (Mil) | [-41.6, 5.6] | 3.3 m | The west road's edge, facing the main road's junction. It is 10 m south of the inner gate and 30 m west of it, so anyone coming in crosses the whole forecourt under the forecourt line. | out: Mil (-41.60, 5.61). The opening runs y 3.98..7.24 between whole pieces. |
| 5 | inner (Mil) | [-11.4, 17.4] | 3.2 m | T4's inner gate, in the Mil line. The pieces fall 1.4 m north of the H line's opening. | out: Mil (-11.40, 17.43), giving the opening y 15.81..19.05. Also out: the bag (-8.9, 16.5). |
| 5 | outer (Mil) | [-41.6, 5.6] | 3.3 m | T4's outer gate, kept. | out: Mil (-41.60, 5.61) |

The west slope (the helipad block's west face) is left as the baseline has it: no wall added, no gate.

## Athira
The main door is at (-3.3, -7.3), facing south. The approach is the open lane south of the house, between House_Small_01 and
House_Big_02 (SE), which runs down to the track that rings the block.

| Tier | Ring | Gate [x, y] | Width | Faces / why | Pieces removed / added |
|---|---|---|---|---|---|
| 3 | the ring | [-0.1, -10.75] | 2.0 m | The south line, in front of the main door, at the open east end of the T2 screen. It is a man's gate: the yard inside is 2.4 m deep. The H pieces' sizes give 2.0 m, not 1.5. | out: HB5 (-1.66, -10.75). Added: HB3 (-2.94, -10.75), from the low city wall's joint (0.35 m into the HB3 at -6.19) to the gate. The opening runs x -1.14..0.91. |
| 4 | inner (H) | [-6.8, -8.05] | 1.7 m | **Moved** to the west line, at the veranda's south end, facing the west lot. At T4 the south line stands only 0.85 m clear of the outer south wall, so T3's south gate would open into a slot rather than onto ground between the rings. | out: HB5 (-6.80, -7.44). Added: HB1 (-6.80, -9.60) on the corner, and HB1s (-6.80, -6.50) and (-6.80, -5.40), the last 0.31 m into the HB5 at -2.11. The opening runs y -8.9..-7.2. T3's south opening is closed again at T4 (the baseline's pieces). |
| 4 | outer (Mil) | [-10.1, -13.0] | 3.3 m | The south face at the west lot's mouth, onto the lane south (vehicle width for the compound's way in). It is about 6 m from the inner gate and at right angles to it: a man comes in heading north, then turns east across the west lot to the inner gate. | out: Mil (-10.06, -13.00). The opening runs x -11.72..-8.40. |
| 5 | outer (Mil) | [-10.1, -13.0] | 3.3 m | T4's outer gate, kept. The user's T5 has no inner ring. | out: Mil (-10.06, -13.00) |

## Zaros
The main door opens against the shop. The house's door to the outside is the side door (4.9, 5.6), facing east onto the main
road (x 16). The user's T4 and T5 have one ring each (the outer walls only).

| Tier | Ring | Gate [x, y] | Width | Faces / why | Pieces removed / added |
|---|---|---|---|---|---|
| 3 | the ring | [13.2, 5.7] | 4.0 m | The east line on the main road's shoulder, straight opposite the side door. The yard inside is 7 m wide (the wreck there is already hidden by the user). | out: HB5 (13.20, 6.02). Added: HB1 (13.20, 8.39), 0.3 m into the HB5 at y 11.69. The opening runs y 3.72..7.69. |
| 4 | the ring (Mil) | [15.0, 6.0] | 3.1 m | T3's gate kept, in the east face on the road. | out: Mil (15.00, 5.96). The opening runs y 4.39..7.53. |
| 5 | the ring (Mil) | [15.0, 6.0] | 3.1 m | the same | out: Mil (15.00, 5.96) |

## Closure, my own check
`closure()` from `drafting/strongholds.py`, every barrier taken as standing on the ground. Two tests per tier:
- **gates shut:** a wall across each opening. The man must not get out.
- **gates open:** he must get out, and through a gate.

Each test runs twice: once with the neighbours the in-game walk crossed in pass 1 taken as open ground (`strongholds.SOFT`,
as pass 1 modelled the site), and once with them taken as solid.

| Town | Tier | Shut / open (pass 1's model) | Shut / open (neighbours solid) |
|---|---|---|---|
| Kavala | 3 | **open** through the hospital / out via [-11.4, 16.0] | closed / out via [-11.4, 16.0] |
| Kavala | 4 | **open** through the north canal-wall gap / out via [-41.6, 5.6] | closed / out via both gates |
| Kavala | 5 | closed / out via both gates | closed / out via both gates |
| Athira | 3 | closed / out via [-0.1, -10.75] | closed / same |
| Athira | 4 | closed / out via both gates | closed / same |
| Athira | 5 | **open** through House_Small_02 / out via [-10.1, -13.0] | closed / same |
| Zaros | 3-5 | closed / out via its gate | (no neighbours in SOFT) |

The three **open** results are not leaks the gates made. They come from the baseline's walls as the user left them:
- **Kavala T3.** The user's T3 has no south line and no east line: the hospital's own walls stand in for them. The in-game walk
  crossed the hospital's ground floor in pass 1, so it may get out south or east. Also, the lead's walk start (13.1, -6.1) is
  east of the main strip, outside the user's T3 ring. Please start T3's walk in the main door's yard, e.g. (-9.85, 9.0).
- **Kavala T4.** The user's T4 lacks the four Mil fills between the north canal walls that T5 (and pass 1's T4) has: (-0.16, 57.91),
  (3.46, 56.84), (16.44, 52.94), (20.06, 51.81). That leaves 7 m gaps at about x 1.6 and x 18. If they were dropped by
  mistake, they're T5's items, ready to copy back. I left them out, since they're the user's call.
- **Athira T5.** The user's T5 has no inner ring and no HB3 down to the house's north face (T4's (4.25, 9.29)). Its north side
  closes on House_Small_02, which the pass 1 walk crossed.

I didn't change any of these: no walls of the user's were added back.

## Notes for the lead
- The baseline's T3/T4 in Kavala and Zaros, and T5 in Athira, were saved without the "ground" flag. I kept them as they are.
  The pieces I added carry "ground".
- Zaros' baseline fails `tl.check()` on its own: 4 "hide" items per tier name map objects the probe doesn't list (the wreck,
  the city gate, a garbage container, a bush). The script lets exactly those baseline problems through and nothing else.
- The in-game check counts a gate only within 45 m of the office. Kavala's outer gate is 42 m out.
