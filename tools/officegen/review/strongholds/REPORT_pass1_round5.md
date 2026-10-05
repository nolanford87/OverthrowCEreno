# Strongholds: pass 1, round 5 report (answering pass1_check4.md)

Branch `layouts/strongholds`. Every draft passes `tl.check()`. `python tools/officegen/drafting/strongholds.py`
rebuilds the drafts and prints the closure per tier and per ring.

## Counts per tier (things / guards / statics)

| Town | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Kavala (hospital) | 0 / 0 / 0 | 9 / 0 / 0 | 58 / 0 / 0 | 113 / 0 / 0 | 134 / 0 / 0 |
| Pyrgos (unchanged) | 0 / 0 / 0 | 11 / 0 / 0 | 35 / 0 / 0 | 96 / 0 / 0 | 106 / 0 / 0 |
| Athira (unchanged) | 0 / 0 / 0 | 5 / 0 / 0 | 19 / 0 / 0 | 52 / 0 / 0 | 56 / 0 / 0 |
| Zaros | 0 / 0 / 0 | 4 / 0 / 0 | 26 / 0 / 0 | 64 / 0 / 0 | 68 / 0 / 0 |

## The two fixes

- **Kavala T3: the two HBarrier_5 cutting the main block.** At T5 the same lines in Mil walls, 0.6 m thinner, didn't
  clip. So the cut is on T3's east line at x 18.2, where the H-barriers' inner face (x 17.35) ran 0.15 m into side1's
  box and close along the main strip.
  - **Moved:** the H-barrier east line now stands at x 20. Its inner face is at x 19.15, 1.8 m further from the
    building, and the line also clears the net fence that ends at x 18.9.
  - **Unchanged:** T5's Mil east line stays at x 18.2, where the game found no clip. T3's south and north lines
    run 1.8 m further east to meet the moved line.
  - **Still to confirm in the game:** these two were the only T3 office clips the game reported, and my
    measurements don't say which pieces they were. If they weren't on the east line, the next most likely are the
    south line (y -24.3) and the line along the south block's north face (y -2). Their [x, y] would settle it.
- **Zaros: the veranda BagFence_Long.**
  - At T2 both veranda bags stand at x -7.6, 3.1 m off the probed wall. A full metre further out than round 4, and
    1 m clear of where any piece has clipped (the house reaches about 2 m past its probe on that side).
  - From T3 on they're dropped, which the brief allows. The T3 ring stands just outside them at x -8.6, and they
    would have been in its way.

## Closure (my check)

| Town | T3 | T4 | T5 | Start |
|---|---|---|---|---|
| Kavala | closed, ring closed | closed, ring closed | closed, ring closed | (13.1, -6.1), your walk's |
| Zaros | closed, ring closed | closed, ring closed | closed, ring closed | (-5, 2.5), the veranda |
| Athira | closed (game) | closed (game) | closed (game) | |
| Pyrgos | closed, ring closed | closed, ring closed | closed, ring closed | 1.5 m out of the main door |

T1 and T2 come out open in every town, so the walker isn't boxed in at the start.

- **Kavala T3, your "one route of eight":** it starts at (0, -24.4). That spot is on my T3 south line (y -24.3),
  so it's outside or inside the ring itself, not a way through. From (13.1, -6.1), between the main strip and the
  east line, my check finds T3 closed, both with everything standing and with T3 on its own. **Please start
  Kavala's T3 walk at (13.1, -6.1).**

## What to check in the game

1. **Kavala T3:** no office clips left; and if one remains, its [x, y].
2. **Zaros T2:** the veranda bags at x -7.6 clear of the house.
