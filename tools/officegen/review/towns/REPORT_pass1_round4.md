# Towns: pass 1, round 4 report (answering pass1_check3.md)

The drafts and the script are pushed (13d491e). All 11 drafts pass `tl.check()` and the script's own checks. Only
Paros changed this round. Nothing in this round has been in the game yet. Coordinates are office model [x, y].

## Paros: the east house's door steps

Every route goes out of the side door to (6, 5.2), then into the east house and out of its south side.
- On the top-down screenshot, the east house's door steps sit right in the corner by the office's side door, at
  about x 5.6-7.2, y 3.7-3.9. They are against the house's north wall, so its door opens into the same small
  corner as the office's side door.
- Round 3's run along the house's north wall (eh) ended there: its free end, 0.2 m off the office, stood over the
  steps.
- This is the same as Neochori's round 2 steps: a piece's end over the steps, and the route goes down them.
  Kalochori, where a piece's middle stands in front of the office's own steps, held.

**The fix:** eh now starts 0.15 m off the office's wall with a whole HBarrier_5 (x 5.76 to 11.16). Its middle,
which the checks measure (x 6.4 to 10.6), stands over the steps. The run goes on to x 14.8, so it takes two
HBarrier_5; the second sticks 2.3 m out past the east face (ne1, x 12.5), into open yard outside the ring.

The side door still opens into the corner above eh, which is closed by the office, eh, ne1 and the north face.

**If Paros still leaks there:** the side door and the east house's door open into the same 1.6 m corner. A
ring with the side door inside it can only keep the house out with something on the house's steps or landing.
The other way is to take the whole east house inside, and with it the block of walk-through houses south of
it (the routes go on from the house through Land_i_House_Big_02_V1_F). Say which you'd rather.

## Neochori: the routes start in the wall

This round's check starts Neochori's routes at **[-6.7, 1.5]**. Round 2 started them at [-0.7, -0.5], inside the
office, and the other ten towns still start inside it. That spot is:
- outside the office, 2 m off its north-west room's west wall (x -4.7);
- on the 2.5 m strip between the office and the main road;
- **inside the west face's band**: west_n stands at x -6.3, so its band is x -7.18 to -5.42.

Every route's first point is (-8.3, 1.9), just outside that band. From there the routes run along the road,
north at x ≈ -14 and south at x ≈ -7.5. That south leg is where both your gaps come from: (-7.3, -11.7) at T3
and (-7.5, -16.7) at T4. So none of them is a gap in the ring: a man started inside the wall and walked away.

I can't move the line clear of that spot. A line between the spot and the office would leave the spot outside
the ring. A line west of it, with its band 0.5 m clear (x -8.1 or further out), would stand 1.8 m into the main
road's paved core. Round 3 found the core already stops the face at x -7.0 in front of the veranda.

**Neochori is unchanged.** Please re-run it with the start inside the office, as for the other towns. If the
start has to stay at [-6.7, 1.5], say so: the west face would then go out into the road, narrowing it.

## Counts (things per tier; each tier keeps the one below)

Only Paros changed. Its line is below; the others are as in REPORT_pass1_round3.md.

| Town | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Paros | 0 | 4 (1 bagL, 3 bagS) | 20 (2 HB1, 2 HB3, 12 HB5, 1 bagL, 3 bagS) | 50 (9 C1, 2 HB1, 2 HB3, 12 HB5, 21 W4, 1 bagL, 3 bagS) |

## Line audit (Paros T3)

The north face, ne1 and eh. The other runs are as in REPORT_pass1_round3.md.

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| north | T3 | 21.98 | run west / corner (a run ties into it) | 5: HB5 + HB5 + HB3 + HB5 + HB5 | 24.8 | 0.59 / 0.14 | 0.52, 0.52, 0.52, 0.52 |
| eh | T3 | 9.88 | free / corner (a run ties into it) | 2: HB5 + HB5 | 10.8 | 0.04 / 0.29 | 0.59 |
| ne1 | T3 | 2.60 | run north / run eh | 2: HB3 + HB1 | 4.3 | 0.59 / 0.59 | 0.52 |
