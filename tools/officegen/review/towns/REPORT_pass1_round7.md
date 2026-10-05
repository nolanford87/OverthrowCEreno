# Towns: pass 1, round 7 report (answering pass1_check7.md)

The drafts and the script are pushed (0e6e319). All 11 drafts pass `tl.check()` and the script's own checks. Only
Paros changed. Nothing in this round has been in the game yet. Coordinates are office model [x, y].

## Paros: cx into the east house

The HBarrier_5 at (13.8, -10.6) was cx's first piece. It stood from y -7.9 to -13.3, alongside the east house, with
its middle cutting in. The cause was round 6's 2.4 m trim of the east house's south face (to y -8.0). At x 13.8 the
house's wall is at its box face (y -10.4): the trim was read off the porch further west.

- **Trim**: now 0.15 m, so the box face stands at y -10.25.
- **cx**: starts at y -10.0 and ties in, then runs to the corner with cs at y -15 as before. It is now two
  HBarrier_3 (y -10.11 to -13.31 and -12.8 to -16.0). Its end stands 0.29 m inside the house's box face, and its
  middle stays clear of the house.
- **T4**: cx and cs are still stacked 2-high as the outer line there.

cs, the sandbag on the east house's steps and the run along its north wall are unchanged. The walled-off stretch of
the alley is a little shorter (it starts at y -10 now instead of -8), and cx still crosses it from the house to the
lane's far side.

## Counts (each tier keeps the one below)

| Town | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Paros | 0 | 4 (1 bagL, 3 bagS) | 26 (3 HB1, 7 HB3, 11 HB5, 2 bagL, 3 bagS) | 61 (9 C1, 4 HB1, 11 HB3, 11 HB5, 21 W4, 2 bagL, 3 bagS) |

## Line audit (Paros T3: cx and cs)

| run | tier | gap | ends tie into | pieces | pieces' length | end overlaps | joints |
|---|---|---|---|---|---|---|---|
| cx | T3 | 5.63 | Land_i_House_Small_01_V1_F / corner (a run ties into it) | 2: HB3 + HB3 | 6.4 | 0.14 / 0.12 | 0.51 |
| cs | T3 | 5.80 | run cx / Land_i_House_Small_02_V1_F | 3: HB3 + HB3 + HB1 | 7.5 | 0.56 / 0.14 | 0.50, 0.50 |

With this, pass 1 is done for the towns.
