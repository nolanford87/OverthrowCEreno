# Strongholds: pass 1, round 6 report (answering pass1_check5.md)

Branch `layouts/strongholds`. Every draft passes `tl.check()`. `python tools/officegen/drafting/strongholds.py`
rebuilds the drafts and prints the closure per tier and per ring.

## Counts per tier (things / guards / statics)

| Town | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Kavala (hospital) | 0 / 0 / 0 | 9 / 0 / 0 | 58 / 0 / 0 | 113 / 0 / 0 | 134 / 0 / 0 |
| Pyrgos | 0 / 0 / 0 | 11 / 0 / 0 | 35 / 0 / 0 | 96 / 0 / 0 | 106 / 0 / 0 |
| Athira | 0 / 0 / 0 | 5 / 0 / 0 | 19 / 0 / 0 | 52 / 0 / 0 | 56 / 0 / 0 |
| Zaros | 0 / 0 / 0 | 4 / 0 / 0 | 26 / 0 / 0 | 64 / 0 / 0 | 68 / 0 / 0 |

Pyrgos, Athira and Zaros are unchanged and done.

## Kavala: the two HBarrier_5 at (-39.5, -10.5) and (-39.5, -15.8)

- **T3's west line**, beside the helipad block's west end, moved 0.5 m out, from x -39.5 to x -40.
- **T5's Mil west line** stays at x -39.5. Its 0.6 m thinner walls didn't clip there.
- **To keep the rings apart:**
  - T4's line along the west road's east edge moved from x -41.3 to x -41.6. It is now 0.2 m off T3's line, on the
    road's shoulder as before.
  - T3's two corner lines at the block's west end (the south line, y -24.3, and the line along the block's north
    face, y -2) now stop short of T4's line.
- **Closure (my check, from your start (13.1, -6.1)):** T3, T4 and T5 closed, with everything standing and with
  each ring on its own. T1 and T2 come out open.

## Pass 1 for the strongholds

| Town | T3 | T4 | T5 |
|---|---|---|---|
| Kavala | closed (game, round 5; my check, round 6) | closed (game; my check) | closed (game; my check) |
| Pyrgos | closed (my check; the tower can't be walked) | closed (my check) | closed (my check) |
| Athira | closed (game) | closed (game) | closed (game) |
| Zaros | closed (game) | closed (game) | closed (game) |

What carries into passes 2-4 (`tools/officegen/drafting/strongholds.py`):
- **`closure()`:** the flood check, per tier and per ring.
- **`SOFT`:** the neighbours the game walks through: Athira's House_Small_02, and the hospital's plan and wings.
- **`TALL_WALLS`:** the canal walls, the only probed walls that are real barriers.
- **`run()` and `upgrade=True`:** `run()` puts a junction wherever a run crosses a low wall; `upgrade=True` lets a
  run stand into a low wall along its length.
- **Stop-short ends** against the office. The House_Big_01 offices reach 1-2 m past their probed plan on the
  veranda side.
- **The guard, static, tower and checkpoint helpers** from the rounds before pass 1, kept for pass 3.
