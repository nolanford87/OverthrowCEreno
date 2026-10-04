# Strongholds: round 4 critique (910b1594)

Tested in the game: `round4/measurements.md` and the screenshots in `round4/`. Every item spawned (none missing).
Flagged items now come with their [x, y] in the office's model coordinates. Note: "hmg" blocked at the same spot as
a floating B_static_AT_F was the AT gun (the role lookup called it hmg; fixed on the main branch).

## Still not a fort: compare your description with the top views
- **Zaros T4**: the top view looks almost like round 3. Your T4 has 13 barrier pieces in all, and each "line" closing
  a gap is ONE piece (an HBarrier_3 is 3.6 m, an HBarrier_5 5.8 m) standing alone: (10.5, -4.8 / -1.6 / 1.5) is the
  only real run; (-16.8, 3.4), (3.0, 17.6), (-15.4, 24.0), (-26.3, 12.6), (-19.6, -12.4), (-20.6, -18.5),
  (11.4, -18.4), (9.8, -21.4) are single pieces with open ground either side. The west yard and the road side are
  open. Measure each gap you mean to close and fill it end to end (pieces overlapping 0.3-0.6 m), 2-high where it faces
  a road. Do the same audit for every town: print each line's length against the gap it closes.
- **Kavala T5**: the west yard is a good fort. The east yard shows one tower and nothing else; the line "up the
  street's edge outside the low garden wall" is not visible in the top view. Check it's really in the T5 snapshot.
- **Athira T5**: much better: the courtyard's north side is closed.

## Measured problems
- **Blind**: Athira T5 rifleman (25, 9.3) 0 m and autorifleman (25.1, 10.5) 0 m; rifleman (-3.7, 1.9) 1 m inside
  the office (Athira T5 and Zaros T5: the same interior post, facing a wall). The door gendarme at Kavala and Pyrgos
  (-14.7, 5.9) still sees only 2.8 m.
- **Statics**: Athira HMG (11.9, -10.3) 11 m; Athira mortar (7.8, -3.9) has something 0.3 m in front (a mortar needs
  open sky above it, not a field, but not a wall in its face either). The roof GMG still cuts into the office at Kavala
  and Pyrgos (T3 on), and Pyrgos' roof AT gun (T5).
- **AT gun floating**: Kavala (19, -16.2) 1.4 m at T5 (0.5 m at T4): real, it's on a slope or a step. Athira
  (-22.4, -5.1) 0.7 m.
- **Clipping mid-piece**: Kavala T5 BagBunker_Small into the big house, HBarrier_3 into the small house; Pyrgos wire
  through a pipe fence, a hedgehog into a city wall, BagBunker_Small into a pipe fence; Zaros BagFence_Short into the
  office.

Fix these, keep tl.check() passing, push, and report.
