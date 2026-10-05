# Villages: pass 1, round 5 report (walls; answering pass1_check4.md)

Commit `12758ec` on `layouts/villages`. Only `Neri.txt` changed this round.
- All 15 drafts pass `tl.check()`.
- All ten tier 3 rings come out closed in the script's flood fill.
- The seven villages the game closed are byte-identical to round 4: Alikampos, Dorida, Gravia, Lakka, Poliakko,
  Selakano and Stavros.
- Telos is unchanged too; its one route at 270 never passes a piece.

## Do Kore.txt and Neri.txt change between rounds?

The md5 of each committed draft:

| Commit (round) | Neri.txt | Kore.txt |
|---|---|---|
| `00529c2` (round 2) | 7ace6ca2 | 6996b8bc |
| `0b2f53a` (round 3) | a4f5bf4e | 91207d85 |
| `ce06d5c` (round 4) | f58bb5ca | 91207d85 |
| `12758ec` (round 5) | ab7a2bf7 | 91207d85 |

- **Neri changed every round.** Its top views show each round's ring.
- **Kore didn't change after round 3, on purpose:** I've held it for your call on its road since round 2 (see
  below). Its round 3 change was two small corner pieces from the gap plugger.

## Neri: why the same gap three times, and the fix

The routes all go one way: from the porch (3.5, -5.6) east, into the shop next door (u_Shop_01) by its south side
at about (6.3, -0.7), through it at (9.7, 3.2) and (12.3, 7.7), and out of its front door at (8.4, 11) to
(9.5, 16.2). The gaps you list, (8.3-15.4, 17-17.5), are where they leave its front steps.

- **The shop's front steps.**
  - Its roof in the top view puts the building at x 4.7..13.7, y 1.8..12.0. Its front door and steps face +y,
    towards the street.
  - In round 3 a piece dropped from 1.5 m up at (9.2, 14.6) landed on something instead of hanging, so a landing
    stands about 1.4 m up there.
  - The front line at y 14.6 stood on those steps. The man walked down them over it, as at the office porches in
    round 2.
  - The pieces at y 14.6 aren't visible in this round's top view, which fits them standing under the steps.
- **The fix.** The ring takes in the whole shop, and the front line moves to y 19.0, past the foot of its steps
  (the routes leave by y 17-17.5).
  - That puts the line on the street's near half (`road_margin` 0.5). It doesn't close the street.
  - Selakano's and Stavros' back notches stand on their roads the same way, and both closed this round.
  - The line's pieces inside the shop's probe box (to y 19.4) go in with drop at the terrain's height, which
    doesn't float (round 4).
- The rest of Neri's ring is as round 4.

## Kore: still not something I can fix with a ring (your call, third time asked)

- **Kore's tier 3 routes are its tier 2 routes.** This round, 5 of its 6 tier 3 routes are identical, point for
  point, to tier 2's, where nothing stands. Every other village's tier 3 routes differ from its tier 2 ones,
  Neri's included.
- **The pieces are there.** Both ways out cross 2-high pieces that the top view shows standing on the
  north-south road east of the house, and the route walks straight through them:
  - (13.8, -9.1) → (19.5, -9.1) through the north line;
  - (2.3, -10.9) → (2.3, -16.3) through the east line.
- **The road isn't in the probe** (no roads within 60 m of Kore). Selakano's and Stavros' notches on probe roads
  did block this round, so this isn't every road. It's this one, perhaps a different kind of road.
- **The porch has no room to the road.** The road's west edge is at the porch's edge, and the shop next door has a
  back door onto it too (street view). So a ring that takes in the porch has to stand on or across that road. The
  game's path search treats pieces there as not there.

What I'd need from you, one of:
- (a) **A quick test:** spawn one HBarrier_Big across Kore's road at (17.5, -9.1) on the bare site and see whether
  the route goes through it. If it does, Kore can't pass this closure check, whatever the ring.
- (b) **Close the porch itself:** pieces on the porch floor, plus one before the shop's back door. That's on the
  road too, so (a) first.
- (c) **Accept Kore** as closed by its design and leave its check open.

## Counts (things per tier, T3)

Unchanged from REPORT_pass1_round4.md except Neri: T1 0, T2 2 (1 BagLong, 1 BagShort), T3 28 (1 BagLong,
1 BagShort, 8 HBBig, 4 HB5, 4 HB3, 10 HB1).

## Line audit, Neri (tier 3)

Polygon (-10, -10.5) → (9.6, -10.5) → (9.6, -7.8) → (15.3, -7.8) → (15.3, 19) → (-10, 19). The flood fill finds it
closed.
- The front line runs corner to corner at y 19, 25.3 m of 2-high and 1-high pieces with 0.45 m joints. The pieces
  inside the shop's probe box (x 4.7..14.3) go in with drop at the terrain's height.
- The left line runs from (-10, -10.5) to (-10, 19), crossing the city wall at y ≈ 11 (pieces butt into it from
  both sides).
- The right line runs from (15.3, -7.8) to (15.3, 19), clear of the garage and shops beyond it.
- The back is as round 4: y -10.5, 1-high before the porch, stepping round the planter at (9.6, -7.8).
- One joint is over 0.6 m: the front line's west corner, HBBig (-6.7, 18.6) × HB1 (-10, 17.5), 1.6 m along the
  first and 0.8 m along the second.

## What to check in the game

1. **Neri's closure:** the front line at y 19, past the shop's steps.
2. **Kore:** option (a) above.
