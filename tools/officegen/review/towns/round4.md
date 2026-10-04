# Towns: round 4 critique (191b1de0)

Tested in the game (all 11): `round4/measurements.md` and the screenshots in `round4/` (the top view now from 55 m).
Every item spawned. A big step: Chalkeia's and Molos' tier 4 read as forts (a closed front, towers on the corners, a
chicane box, hedgehog belts), and the tier 3 fronts are real walled compounds now (Chalkeia T3 street view).

## Design
- **The old walls you tie into must be real barriers.** Kalochori's T4 is mostly the old yard walls plus a tower and
  two hedgehog belts. From above, those walls look like the low garden walls with railings that the strongholds group
  found a man can step over. Use an old wall only if it's at least about 2 m high (the probe's wall classes:
  `city_*`, `stone_*` vary; `*_pillar`, `pipe_fence`, railings and low garden walls don't count). Otherwise line it
  with H-barriers.
- Kalochori's T4 needs to read as a fort from the street: 2-high faces, its own towers, the chicane in front of the
  gate.

## Measured problems (office model [x, y])
- **Statics blocked** (a gun needs 15 m of open ground ahead; "hmg" at the same spot as an AT gun is the AT gun):
  - **Chalkeia**: HMG (-10, 8.9) 3 m (T3 on), HMG (-6.5, 9.1) 0.8 m (T4).
  - **Agios Dionysios**: HMG (-1.1, -13.2) 5.6 m (T3 on).
  - **Charkia**: AT (-0.9, -12.6) 6 m and GMG (2.1, -9.9) 2.8 m (T4).
  - **Panochori**: HMGs (10.9, -9.7) 4.6 m and (10.9, -12.7) 3.5 m.
  - **Neochori**: HMG (7.4, -15.2) 13.4 m (T3), HMG (1.7, 11.9) 9.3 m (T4).
  - **Paros**: GMG (11.1, 9.4) 3.2 m.
  - **Therisa**: GMG (9.6, -15.2) 1.6 m.
  Your sight check now counts walls, but these are still short: check what's in front of each (sandbags of the gun's
  own gap? the line beyond?).
- **The ground-floor riflemen at (3.8, ±4..7)** are pushed 1-1.7 m off their posts in most towns (Chalkeia, Molos,
  Neochori, Panochori, Paros, Rodopoli, Sofia, Agios Dionysios), and blind at Rodopoli and Chalkeia. It's the same
  posts in the same office class: they stand inside the wall or furniture. Move them 0.6 m into the room, or drop
  them.
- **Blind**:
  - **Agios Dionysios**: autorifleman (-4.1, -14.6) 0 m (T4).
  - **Kalochori**: rifleman (-1.9, -1.5) 0 m (T2), inside the house.
  - **Paros**: rifleman (12.6, 12) 0.2 m.
  - **Rodopoli**: rifleman (10.3, 9.9) 0 m.
  - **Therisa**: the T1 gendarme (-2.1, -3.5) 0 m.
- **Clipping mid-piece**:
  - **Agios Dionysios and Chalkeia**: the sandbags outside the side door (BagFence_Long) cut into the office (T2 on).
    Move them 0.5 m out.
  - **Panochori**: two HBarrier_1 and the bar gate cut into the office (T3 on).
  - **Therisa**: two hedgehogs cut into a tree planter (treebin_f.p3d), which the probe may not list.
- **AT guns "floating" 0.3-0.7 m**: the tripod's shape. Ignore it at 0.5 m or so.

Fix these, keep tl.check() passing, push, and write REPORT_round5.md.
