# Villages: pass 1, round 8 report (walls; answering pass1_check7.md)

Commit `75c2e8d` on `layouts/villages`. Only `Neri.txt` changed. Every other draft, Kore's included, is byte-identical
to round 7. All 15 drafts pass `tl.check()`, and all ten tier 3 rings come out closed in the script's flood fill.

## Neri: the last way out

check7.md quotes the **tier 2** route: porch → (-1.2, -8.3) → (-6.6, -7.3) → (-12.1, -7). Tier 2 has no ring (it's the
sandbags on the house), so that route is expected.

The **tier 3** route in measurements.md is different: (-0.9, -12.2) → (-6.8, -12.7) → (-12.3, -11) → (-16.5, -7.4) →
away. It **starts** at (-0.9, -12.2), beyond the back line at y -10.5, so it never crosses the ring. That's the
house's way out of the back door: its path down the porch steps ends at about y -12.2. This is what happened at
Alikampos, Selakano and Stavros in round 3, and their notches closed them.

## The fix

The back line steps out round that point, as those three towns' notches do:
- from (-5.4, -10.5) down to y -13.5, across to x 0.3, and back up to the back line;
- 1-high pieces, with inner faces at y -12.65 and x -0.55;
- the notch is 5.7 m wide;
- the exit point is 0.45 m inside the bottom line and 0.35 m inside the east side.

It stops short of the house behind (u_House_Big_01). Its roof's nearest corner is at about (0.5, -13.7) in the top
view. Its probe box reaches (2, -12), well outside its walls, so the ring doesn't rely on it.
- The two pieces at the notch's east end go in with drop, because they reach into that box.
- The corner piece (HB1 at (0.65, -13.5)) may brush the roof's corner, over 0.6 m at most, at the eaves.

Everything else is as round 7: the front line at y 13.2 off the track, and the shop outside with its south side shut
off.

The script also had a bug in the line audit: a building left open (`walls` None) shifted the neighbour names after
it. Fixing it only changes the names the audit prints; no draft changes.

## Counts (things per tier) and line audit, Neri

T1 0. T2 2 (1 BagLong, 1 BagShort). T3 37: 1 BagLong, 1 BagShort, 5 HBBig, 2 HB5, 7 HB3, 21 HB1.

Polygon (-10, -10.5) → (-5.4, -10.5) → (-5.4, -13.5) → (0.3, -13.5) → (0.3, -10.5) → (9.6, -10.5) → (9.6, -7.8) →
(15.3, -7.8) → (15.3, -0.85) → (5.5, -0.85) → (5.5, 13.2) → (-10, 13.2). Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -10.5 (back, left) | -10.0..-5.3 | 4.7 | 4.7 | corner / corner | 1.2 / 1.2 | – |
| x -5.4 (notch) | -13.5..-10.4 | 3.1 | 3.1 | corner / corner | 0.8 / 0.8 | – |
| y -13.5 (notch) | -5.4..0.4 | 5.8 | 5.8 | corner / corner | 0.9 / 1.0 | – |
| x 0.3 (notch) | -13.5..-10.4 | 3.1 | 3.1 | corner / corner | 0.8 / 0.8 | – |
| y -10.5 (back, right) | 0.3..9.7 | 9.4 | 9.4 | corner / corner | 0.9 / 0.9 | – |
| x 9.6 (step) | -10.5..-7.7 | 2.8 | 2.8 | corner / corner | 0.8 / 0.8 | – |
| y -7.8 (round the planter) | 9.6..15.4 | 5.8 | 5.8 | corner / corner | 0.9 / 1.0 | – |
| x 15.3 (right) | -7.8..-0.7 | 7.1 | 7.1 | corner / corner | 0.8 / 0.7 | – |
| y -0.85 (shop's south side) | 5.5..15.4 | 9.9 | 9.8 | house's wall / corner | – / 1.2 | – |
| x 5.5 (house's and shop's walls) | -0.8..13.2 | – | walls | house / shop / front line | – | – |
| y 13.2 (front) | -10.0..5.6 | 15.6 | 15.6 | corner / shop's corner | 0.9 / 1.6 | – |
| x -10 (left) | -10.5..10.9 | 21.4 | 21.4 | corner / city wall | 0.8 / 3.6 | – |
| x -10 (left) | 11.4..13.3 | 1.9 | 1.9 | city wall / corner | 4.1 / 1.2 | – |

One joint is over 0.6 m: HB3 (10.5, -7.8) × HB1 (9.6, -8.7), at the planter step, as before.

## What to check in the game

1. **Neri's tier 3 closure.**
2. **The notch's corner piece at (0.65, -13.5)** against the house behind.
