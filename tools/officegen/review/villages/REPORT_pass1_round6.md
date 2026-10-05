# Villages: pass 1, round 6 report (walls; answering pass1_check5.md)

Commit `a779d88` on `layouts/villages`. Only `Neri.txt` changed.
- Every other draft is byte-identical to round 5.
- Kore is left as it is (your call (c)).
- All 15 drafts pass `tl.check()`, and all ten tier 3 rings come out closed in the script's flood fill.

## Neri: the two ways out, and the fix

Both routes leave the office by its front door, go through the front annex (Addon_04) to (-2.8, 14.2), then split.

- **Middle of the front line, (-1.2, 19.3) → (1.7, 23.7).**
  - The man crossed the front line at x ≈ -1.2. The piece there was the HBarrier_Big spanning x -2.95..5.45.
  - It had gone in with drop, because its middle reached into the shop's probe box, which runs to y 19.3.
  - That's the third round in which a dropped piece in Neri's front line didn't hold: rounds 2, 4 and 5 all
    crossed at one. Whether it's buried, moved or not seen, a dropped piece there doesn't hold.
- **Front-left corner, (-8.1, 16.6) → (-14.1, 16.6).**
  - The left line reached the corner as 1-high pieces: HB3 at y 13.8..17.4 and HB1 at 16.8..18.2.
  - They met the end of the 2-high front line at y 18.6, and the man crossed there.

**The fix:**
- **The front line moves to y 20.2,** just past the shop's probe box (to 19.3, with townlib's 0.1 m padding). So
  every front piece stands on the ground:
  - three HBarrier_Big across, x -10.9..13.4, then three HBarrier_1 to the right corner;
  - 0.45 m joints;
  - no dropped pieces left in Neri's ring.
- **The left line now reaches the corner 2-high.** An HBarrier_Big runs y 11.1..19.5 at x -10, butting into the
  front line's 2-high corner piece (y 19.0..21.4).
- **The rest is as round 5:**
  - the right line at x 15.3, 2-high up to y 16.9, then 1-high to the corner;
  - the back line at y -10.5, stepping round the planter at (9.6, -7.8);
  - the shop is inside the ring, and its front steps (to about y 17) are behind the line.

**The street.** The front line at y 20.2 stands on the middle of the probe's street (centre y 20, `road_margin`
0), with its outer face at y 21.4. The routes' way along the street runs at y 23.6-23.7, so the street's far side
stays open, though narrowed. Selakano's and Stavros' notches stand on their roads the same way, and both closed.
If you'd rather keep more of the street, the alternative is the old y 19 line with ground pieces only where the
shop's box allows, which leaves the 8.7 m over the shop's front to drop again.

## Counts (things per tier) and line audit, Neri

T1 0. T2 2 (1 BagLong, 1 BagShort; no window bag, as it clipped the shop). T3 27: 1 BagLong, 1 BagShort, 9 HBBig,
4 HB5, 2 HB3, 10 HB1.

Polygon (-10, -10.5) → (9.6, -10.5) → (9.6, -7.8) → (15.3, -7.8) → (15.3, 20.2) → (-10, 20.2). Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -10.5 (back) | -10.0..9.7 | 19.7 | 19.7 | corner / corner | 1.2 / 0.9 | – |
| y -7.8 (round the planter) | 9.6..15.4 | 5.8 | 5.8 | corner / corner | 0.9 / 1.1 | – |
| y 20.2 (front) | -10.0..15.4 | 25.4 | 25.4 | corner / corner | 1.1 / 0.9 | – |
| x -10 (left) | -10.5..10.9 | 21.4 | 21.4 | corner / city wall | 0.8 / 4.1 | – |
| x -10 (left) | 11.4..20.3 | 8.9 | 8.9 | city wall / corner | 4.1 / 1.2 | – |
| x 9.6 (step) | -10.5..-7.7 | 2.8 | 2.8 | corner / corner | 0.8 / 0.8 | – |
| x 15.3 (right) | -7.8..20.2 | 28.0 | 28.0 | corner / corner | – | – |

Per line, 2-high / 1-high:
- front: 23.5 / 1.9 m;
- left: 25.2 / 5.1 m;
- right: 23.9 / 3.8 m;
- back: 1.2 / 18.5 m (1-high before the porch, where the steps zone keeps 2-high pieces out).

One joint is over 0.6 m: HB5 (11.6, -7.8) × HB1 (9.6, -8.7), at the planter step.

## What to check in the game

1. **Neri's closure:** the front line at y 20.2 and the front-left corner.
