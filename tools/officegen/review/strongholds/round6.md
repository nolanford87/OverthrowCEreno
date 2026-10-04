# Strongholds: round 6 critique (3ba90c80)

Tested in the game: `round6/measurements.md` and the screenshots in `round6/`. Every item spawned. The design now
reads right: Zaros' west yard is closed (top view), and Kavala's street front is a fortress (T4 street view). Nearly
done. What's left is mostly men on towers.

## The tower men (the one real problem left)
Every tower with TWO men has both pushed 1.1-1.8 m: Kavala's four towers, Pyrgos (-10.4, -28.6), (-11.9, -31.2) and
(-26.2, -30.7), Athira (13.1, -4.2) and (12.2, -4.3), Zaros (-6.2, -20.3) and (-6.3, -19.4). The hamlets put ONE man
per tower at the measured spot (3.4 m up, 0.3 m forward of the centre, no drop) and theirs are clean in every run.
The platform's level part is only about 1.2 m across, so two men don't fit.
- **One man per tower**, at exactly the hamlets' spot, without the +0.5 m drop (the drop counts toward "moved" too).
- Put the second man elsewhere: a sandbag post at the tower's foot, or the next window.

## Measured problems (office model [x, y])
- **GMG blocked at 0 m**: Athira (4.1, -10.1) (back at its round-4 spot, which also failed) and Zaros (12.2, 14.1).
  Something stands on or right in front of each; move each at least 3 m to a new spot.
- **Kavala GMG** (15.7, -28.4): 9.7 m (T5).
- **Athira AT** (-16.5, -6.7): 7.6 m (T3, labelled hmg).
- **Pyrgos' roof AT gun cuts into the office** (T4), and its roof GMG (-14.5, -5.5) floats 0.3 m (on a roof divider?).
- **Pushed about 1 m**: Athira T5 riflemen (5.4, 5.1) and (3.2, -5.6); Zaros marksman (3.8, 4.5) (T4). Move each
  0.5 m.
- **Athira's shop corner**: I can't measure whether a man fits through the 4.4 m you left before the shop's real
  wall. If the shop's box blocks you, end the line with a sandbag or wire piece (small enough to fit), or close it
  from the inside.

Fix these, keep tl.check() passing, push, and write REPORT_round7.md.
