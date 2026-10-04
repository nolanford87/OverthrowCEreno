# Towns: pass 1 (walls), in-game round 1 (e467ad22)

Tested in the game (all 11): `pass1_round1/measurements.md` and the screenshots in `pass1_round1/` (top view from 55 m).
Every piece spawned. The walls look the part: Molos' T4 is a clean double ring (a tight H-barrier ring inside a 4 m
wall), and Kalochori's T4 reads as a fortress from the street.

## Closure (the engine's route from the office's door to 8 points 60 m out)
This run logged the routes in an older one-line format that got cut off, so the full routes aren't in
measurements.md. The gaps are below (office model [x, y], where the route last passes within 3 m of a piece).
- **Closed at T3 and T4**: Agios Dionysios, Kalochori, Molos, Panochori, Rodopoli. Charkia at T4.
- **Chalkeia**: T3 out at (-15.5, -4.7) (the west side, by the rocks: rocks and the ruin don't close a line), at
  (-6, -6.7) by the house, and at (11.4, 0.8). T4 out at (-15.5, -4.7) and through (-8.2, -29) at the south-west
  corner, where the high wall meets the building.
- **Charkia T3**: out at (10.1-11, 0.5-0.8) on the east side, and at (-13.3, -14.3).
- **Neochori**: T3 and T4 out at (-7.9, -4.3) and (-7.1, -5.7), right beside the house, and at (7.5, 2.8). T4 also
  at (26.9, -3.7).
- **Paros**: out at (11-11.1, 18.8-19.8) and (11.9, 3.6). T4 also at (-5.9, -17.7).
- **Sofia**: out at (18, -2.5) and (20.1, 4). T4 also at (-9.3, -19.5) and (29.2, -9.5).
- **Therisa**: T3 out at (-5.8, -6.5) beside the house and at (7.9, 7.7). T4 out at (-24.4, -9.9).

Gaps right beside the house (Neochori, Therisa, Chalkeia's (-6, -6.7)): the route either squeezes past where a line
meets the office, or goes in one door and out another. A line may end on the office's wall only on a face with no
door, overlapping it. Otherwise take the line round the house.

## Pieces
- **The side-door sandbags still cut into the office** at Agios Dionysios and Chalkeia (T2 on), and Panochori's
  HBarrier_5 and HBarrier_3 cut into it (T3 on). Move them out until clear.

## Against the brief's newer points (pull them)
- **Upgrade the existing walls**: from T3 on, H-barriers may stand on or into a real wall along its length to
  reinforce it. That's worth doing where your rings cross stone walls: line them rather than cutting across.
- **Wall in the compound**: T4 should take in the office's cluster (the annexes, the neighbours across the yard).
  Molos does; check the others take in what clusters with the office.

Fix the gaps and the pieces, push, write REPORT_pass1_round2.md. The next run logs the full routes per way out.
