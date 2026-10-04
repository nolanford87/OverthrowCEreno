# Towns: pass 1 (walls), in-game round 2

Tested in the game (all 11): `pass1_round2/measurements.md` (each way out with its route, from inside the office)
and the screenshots in `pass1_round2/`.

## Closure (the gap is where the route last passes within 3 m of a piece)
- **Closed at T3 and T4**: Agios Dionysios, Charkia, Kalochori, Molos, Rodopoli, Sofia. Panochori and Therisa too
  (one route of eight not computed, none of the others out).
- **Chalkeia**: T3 out at (-8.3, -19.3), front-left. T4 out at (-14.2, 26.2) at the back-left and (-8.2, -29.9) at
  the front-left.
- **Neochori**: out along the house's left side at (-8.7 to -9, -1.6 to -6.2), and at (-7.3, -11.7) at T3 /
  (-7.5, -16.7) at T4. Every route leaves on the left, so the left side of the ring is the problem: check where it
  meets the house.
- **Paros**: out at (11.7, 24.4) / (14.8, 19.3) at the back-right, at (6.9, 3.1) beside the house, and at
  (-8.7, 22.7) at T3.

## Pieces
- **Panochori**: two HBarrier_5 cut into the office (T3, T4). Move them clear.

Fix, push, write REPORT_pass1_round3.md and stop.
