# Towns: pass 1, round 5 report (answering pass1_check5.md)

The drafts and the script are pushed (51d51c1). All 11 drafts pass `tl.check()` and the script's own checks. Only
Paros changed. Nothing in this round has been in the game yet. Coordinates are office model [x, y].

## Paros: a sandbag on the east house's steps

As you picked: pieces on the steps, not the whole east house.

- **On the steps**: a Land_BagFence_Long_F lies across the east house's door steps at (7.2, 3.75), lengthwise
  along the house's north wall (x 5.65 to 8.75).
  - Its west end is 0.05 m off the office's east wall, below the side door.
  - It is placed 1.4 m above the ground there with the "drop" flag, so in the game it settles onto the treads
    (the ray reaches down to 0.1 m below the ground, so it lands on the ground if the steps are lower than
    expected).
  - On round 1's screenshot the steps are at about x 5.6-7.2, y 3.5-4.0, so the bag covers their whole width with
    room to spare east.
- **The run along the house's north wall (eh)** now starts at x 8.0, east of the steps, and its HBarrier_5
  overlaps the bag's end by 0.8 m. It then runs on to the east face as before.
- **The side door** opens into the corner above the bag. The door's outside point (6, 5.2) is now 1.2 m clear of
  the bag and 2 m clear of eh. In round 4 it was inside eh's band, and a route starting inside a band seems to go
  straight through it (as with Neochori's steps in round 2, and its start spot in round 4).
- The script's own walk counts the bag only as part of the tier (a piece set on a surface isn't a ground piece
  for it). Its closure therefore rests on the east house's wall, so the game check is the test here.

**If it still leaks**, the next step is a second bag stacked on this one, or an HBarrier_1 on the landing at the
door's head. The bag stands about 0.9 m high.

## Counts (things per tier; each tier keeps the one below)

Only Paros changed.

| Town | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Paros | 0 | 4 (1 bagL, 3 bagS) | 21 (2 HB1, 3 HB3, 11 HB5, 2 bagL, 3 bagS) | 51 (9 C1, 2 HB1, 3 HB3, 11 HB5, 21 W4, 2 bagL, 3 bagS) |

## Line audit (Paros T3: the runs by the east house)

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| eh | T3 | 7.68 | free / corner (a run ties into it) | 2: HB5 + HB3 | 8.6 | 0.04 / 0.29 | 0.59 |
| ne1 | T3 | 2.60 | run north / run eh | 2: HB3 + HB1 | 4.3 | 0.59 / 0.59 | 0.52 |
