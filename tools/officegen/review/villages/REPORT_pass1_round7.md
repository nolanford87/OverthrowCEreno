# Villages: pass 1, round 7 report (walls; answering pass1_check6.md)

Commit `d8da49a` on `layouts/villages`. Only `Neri.txt` changed. Every other draft, Kore's included, is byte-identical
to round 6. All 15 drafts pass `tl.check()`, and all ten tier 3 rings come out closed in the script's flood fill.

## Neri: why the old fixes didn't hold

The front line isn't leaking at a joint or a 1-high piece. **The man walks through the track in front, as he does at
Kore.**

1. **The routes didn't move between rounds 5 and 6.** In check 5 and check 6 they're the same, point for point:
   (-2.8, 14.2) → (-1.2, 19.3) → (1.7, 23.7), and (-2.8, 14.2) → (-8.1, 16.6) → (-14.1, 16.6). Yet round 6 changed
   two things:
   - it moved the front line 1.2 m out and onto the ground;
   - it replaced the 1-high pieces at the corner with a 2-high HBarrier_Big.

   The game planned the same way out through different pieces both times.
2. **Both crossings are in the middle of an HBarrier_Big.** The front one is 1.7 m from the nearest joint, and the
   corner one is 5.4 m from the nearest end, so neither is at a joint.
3. **Every crossing in rounds 4-6 is on the probe's track.** The track's centre runs along y 20 from x -8.3 to 27, and
   it's 10 m wide.
   - Round 4: (9.3, 15.5) → (12.8, 19.3) and (5.3, 18.8) → (-0.5, 18.4).
   - Rounds 5-6: x ≈ -1.2 around y 20 at the front, and (-10, 16.6) at the corner, 3.8 m from the track's end at
     (-8.3, 20).
   - Nothing crossed off the track in those rounds.

   That's what your Kore call says too: the game's route finding ignores pieces on the road. My round 6 theory, that
   only the dropped pieces failed, was wrong. The ground pieces on the track failed the same way.

## The fix: nothing on the track

- **The front line comes in to y 13.2** (outer face 14.5, so it's off the track's band, which starts at y 15).
  - Two HBarrier_Big (2-high) and two HBarrier_1 run from the left line (x -10) to the shop's front-left corner
    (5.6, 12.2).
  - They pass 0.1 m clear of the annex's front (11.8).
  - They go in with drop, onto the ground under them, as the annex's and shop's probe boxes reach that far.
- **The front-left corner is now (-10, 13.2).** That's 6.6 m from the track's end, and the old corner crossing at
  y 16.6 is outside the ring.
- **The shop is outside the ring again.** Taking the shop in was what pushed the front line onto the track: its front
  steps run to about y 17.
  - Its south side, where rounds 2-4 walked in, is shut off by a line at y -0.85: an HBarrier_Big, x 5.6..14.0, its
    face 0.05 m off the shop's south wall, then HBarrier_1 to the right line.
  - That line meets the house's east wall (x 5.3). The house's wall and the shop's west wall (x 5.6) then close the
    ring up to the front line, with 0.3 m between them, which is too narrow for a man.
- **The right line (x 15.3) now runs only from -7.8 to -0.85,** all 1-high. The back line is as round 6.
- **The ring has no plug pieces this round** (`plug` False). The one the script added would have cut 0.45 m into
  the shop.

## Counts (things per tier) and line audit, Neri

T1 0. T2 2 (1 BagLong, 1 BagShort). T3 29: 1 BagLong, 1 BagShort, 5 HBBig, 3 HB5, 5 HB3, 14 HB1.

Polygon (-10, -10.5) → (9.6, -10.5) → (9.6, -7.8) → (15.3, -7.8) → (15.3, -0.85) → (5.5, -0.85) → (5.5, 13.2) →
(-10, 13.2). Flood fill: closed.

| Line | Gap (m along it) | Width | Run over it | Ties into (start / end) | Run past the ends | Open > 0.3 m |
|---|---|---|---|---|---|---|
| y -10.5 (back) | -10.0..9.7 | 19.7 | 19.7 | corner / corner | 1.2 / 0.9 | – |
| y -7.8 (round the planter) | 9.6..15.4 | 5.8 | 5.8 | corner / corner | 0.9 / 1.0 | – |
| y -0.85 (shop's south side) | 5.5..15.4 | 9.9 | 9.8 | house's wall / corner | – / 1.2 | – |
| y 13.2 (front) | -10.0..5.6 | 15.6 | 15.6 | corner / shop's corner | 0.9 / 1.6 | – |
| x -10 (left) | -10.5..10.9 | 21.4 | 21.4 | corner / city wall | 0.8 / 3.6 | – |
| x -10 (left) | 11.4..13.3 | 1.9 | 1.9 | city wall / corner | 4.1 / 1.2 | – |
| x 5.5 (house's and shop's walls) | -0.8..13.2 | – | walls | house / shop / front line | – | – |
| x 9.6 (step) | -10.5..-7.7 | 2.8 | 2.8 | corner / corner | 0.8 / 0.8 | – |
| x 15.3 (right) | -7.8..-0.7 | 7.1 | 7.1 | corner / corner | 0.8 / 0.7 | – |

Per line, 2-high / 1-high:

| Line | 2-high | 1-high |
|---|---|---|
| front | 15.5 m | 0.1 m |
| left | 17.5 m | 5.8 m |
| shop's south side | 8.5 m | 1.3 m |
| right | – | 7.1 m |
| back | 1.2 m | 18.5 m |

One joint is over 0.6 m: HB3 (10.5, -7.8) × HB1 (9.6, -8.7), at the planter step, as before.

## What to check in the game

1. **Neri's closure.**
   - If a route still gets out, check whether it goes between the house's east wall and the shop (0.3 m by the top
     view) or through a door on the shop's west wall.
   - A crossing off the track would also disprove the road explanation above.
