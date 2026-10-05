# Strongholds: pass 1, round 7 report (answering pass1_check6.md)

Branch `layouts/strongholds`. Every draft passes `tl.check()`.

## Counts per tier (things / guards / statics)

| Town | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Kavala (hospital) | 0 / 0 / 0 | 9 / 0 / 0 | 55 / 0 / 0 | 110 / 0 / 0 | 134 / 0 / 0 |
| Pyrgos | 0 / 0 / 0 | 11 / 0 / 0 | 35 / 0 / 0 | 96 / 0 / 0 | 106 / 0 / 0 |
| Athira | 0 / 0 / 0 | 5 / 0 / 0 | 19 / 0 / 0 | 52 / 0 / 0 | 56 / 0 / 0 |
| Zaros | 0 / 0 / 0 | 4 / 0 / 0 | 26 / 0 / 0 | 64 / 0 / 0 | 68 / 0 / 0 |

Only Kavala's T3 and T4 changed. T4 lost the three pieces it had carried over from T3's dropped west line.

## Kavala T3: tied into the helipad block's west end

- **Pieces dropped:** the H-barriers that ran along the block's west face, at x -39.5 and then at x -40. Both times,
  two cut it at y -10.5 and y -15.8.
- **The new tie:**
  - two `HBarrier_3` stubs at x -36, square to the block's faces;
  - the north stub (y -2.2..-5.8) comes down from T3's line along the block's north side (y -2) and ends 0.3 m
    into the block's north face (y -5.5);
  - the south stub (y -24.8..-21.2) comes up from T3's south line (y -24.3) and ends 0.3 m into its south face
    (y -21.5);
  - between them, the block's west wall closes the ring.
- **Why x -36:** that's where the probe's floor plan has wall cells at the block's north-west and south-west
  corners. Further west (x -39..-37) the plan shows nothing at the corners, though the block's wall in between
  reaches x -39 and beyond (your clips).
- **T3's other lines** at that end now stop at the stubs.
- **Unchanged:** T5's Mil line along the face (x -39.5), which never clipped, and T4's west road-edge line (x -41.6).

**Closure (my check, from your start (13.1, -6.1)):**
- **With the block's west end solid** (its probed plan solid, as you found in the game): T3, T4 and T5 closed, both
  with everything standing and with each ring on its own. T1 and T2 come out open.
- **With the whole hospital as open ground** (my default model for Kavala since round 4, from round 2's walk through
  its ground floor): T4 and T5 closed. T3 shows open, as it must: it now closes on the block's wall.
- **For the game:** the block's ground floor is open on the north side (round 2's walk came out at about
  (-12, -3)). So the tie holds only if the block's west wall and its north-west and south-west corners are solid
  from x -39 to x -36. If the walk gets out at T3, it will be there.
- **Fix:** `site_grid()` now scans the office's plan over its whole extent. The hospital's plan runs west past the
  main block's box, under side2, and was missed before.

## What to check in the game

1. **Kavala T3:** closed from (13.1, -6.1)? And no clip from the two stubs (x -36, ends 0.3 m into the block's
   north and south faces).
