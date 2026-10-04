# Villages: round 5 report (answer to round4.md)

Commits: `c353a52` (round 5) and `07822a8` (stricter closure check). All 15 drafts pass `tl.check()`.
`python tools/officegen/drafting/villages.py --audit [--views] [--map] [town]` reproduces every number below.

## Counts per town and tier (things / guards / statics)

| Town | T1 | T2 | T3 |
|---|---|---|---|
| Alikampos | 7 / 3 / 0 | 16 / 6 / 0 | 47 / 13 / 2 |
| Dorida | 7 / 3 / 0 | 16 / 6 / 0 | 50 / 13 / 2 |
| Gravia | 7 / 3 / 0 | 16 / 6 / 0 | 53 / 13 / 2 |
| Kore | 7 / 3 / 0 | 16 / 6 / 0 | 52 / 13 / 2 |
| Lakka | 7 / 3 / 0 | 16 / 6 / 0 | 54 / 13 / 2 |
| Neri | 7 / 3 / 0 | 16 / 6 / 0 | 47 / 13 / 2 |
| Poliakko | 7 / 3 / 0 | 16 / 6 / 0 | 52 / 13 / 2 |
| Selakano | 7 / 3 / 0 | 14 / 6 / 0 | 62 / 13 / 2 |
| Stavros | 7 / 3 / 0 | 15 / 6 / 0 | 50 / 13 / 2 |
| Telos | 7 / 3 / 0 | 16 / 6 / 0 | 54 / 13 / 2 |
| Abdera | 7 / 3 / 0 | 16 / 6 / 0 | – |
| Agios Konstantinos | 7 / 3 / 0 | 16 / 6 / 0 | – |
| Galati | 7 / 3 / 0 | 16 / 6 / 0 | – |
| Nifi | 7 / 3 / 0 | 16 / 6 / 0 | – |
| Topolia | 7 / 3 / 0 | 12 / 6 / 0 | – |

## What changed

### The measured items
- **Map board (every village, every tier):** moved from x -4.25 to -3.7. The upstairs west wall's inside face
  is at -4.5 (where the floor grid ends), and the board's real box is 1.0 m deep, so its back now stands 0.3 m off
  the wall.
- **Kore GMG (-15.5, 0.5):** moved to the back line at (-13.0, -13.2), facing out over the road side (model -y).
  The old post is kept on Kore's avoid list. Estimated field of fire 22.5 m; the HMG covers the same side from
  (7.7, -13.2), so their fields cross in front of the gate.
- **Poliakko gendarme (3.9, 2.8):** this was the upstairs east-window post, (4.3, 2.9), not the door. Poliakko
  now puts no one at that window on any tier (`no_window`). The tier 1 gendarme is on the back balcony
  (-0.6, -5.3, estimated 17.6 m). The tier 2 marksman, who also used to pick the window, now stands on the back
  balcony at (0.6, -5.3), estimated 45 m.
- **Alikampos flag:** moved 0.9 m further out, from (-0.7, -8.1) to (-0.7, -9.0) (`flag_a` 2.4). I couldn't model
  why only Alikampos' flag clipped: the same spot was clean in the other villages, so it is probably the porch
  steps on that slope. The other flags are unchanged.
- **H-barriers cutting walls mid-piece:** the drafting script now replays the game's own clip test. It casts
  rays across each piece's measured box (a barrier's middle only: 0.6 m off each end, half its depth) against
  the probed walls, buildings, rocks and the house. On round 4's drafts this test reproduces every clip the game
  reported: Alikampos, Dorida, Lakka, Neri, Selakano, Stavros and Telos. On the new drafts it finds none.
  - **Stavros:** no piece runs along the house any more. The ring's right side is the house wall and the
    neighbour, so no line is laid there. That removes the five HBarrier_1 that stood inside the office.
  - **Stavros tower:** round 4 also flagged it cutting into the office. It now stands on the left line by the
    road corner (see Stavros below).
  - **Every ground piece:** its measured footprint must stay clear of the house walls (x ±5.3, y -5.0 to 5.8).
- **Topolia BagFence_Long:** moved 0.5 m in, onto the porch floor at (1.4, -5.8). Its two men moved 0.5 m in
  too, to (0.8, -4.8) and (2.0, -4.8).
- **Left alone:** Nifi's gendarme and Selakano's GMG are in exactly their round 4 positions.

### Tier 3 against Kore: the ring builder
- **2-high pieces go in first.** On each side that faces a road or open ground, HBarrier_Big pieces are laid
  first, wherever one fits. Each can step up to 1.2 m inside the line to clear an old wall. 1-high pieces then
  fill what is still open, each starting 0.3 m into the piece before it. In round 4 one greedy pass tiled the
  side in a single sweep, so a 2-high piece that couldn't start exactly where the last piece ended became a
  1-high one.
- **1-high only where men fire over it.** A line stays 1-high only by the gate, by the guns, and across the
  3 m line of sight of each man outside who fires over it. Round 4 kept a 12 m stretch 1-high in front of the
  second door, whether or not anyone looked over it.
- **The house counts as part of the line.** Where a ring line runs within 1 m of the house, the house's own wall
  closes it and no pieces are laid. Before this, Telos had jersey barriers and an H-barrier pressed against its
  front door and through the tier 2 sandbag screen.
- **Closure check.** Every ring is now checked with a flood fill for a man 0.4 m across the shoulders, and holes
  are filled until none is left. All ten tier 3 rings are closed.
- **Telos:** the tower is now at the front-right road corner, (8.0, 2.0), inside the old city wall. Its platform
  overlooks the main road and the junction at (12, 13), estimated view 45 m. The back line is 2-high for 8.5 m;
  the rest is 1-high around the gate and the GMG. The right line is 2-high for 13.5 m. The left side is the old
  2 m city wall, with H-barriers inside it and in its gaps. The front is the house, the neighbour and the old
  walls, with short H-barrier runs at both corners.
- **Stavros:** the yard is too tight for the tower anywhere near the house. It now stands on the left line at
  (-9.0, -5.0), by the road corner, with a 28.8 m view. The HMG (45 m) and GMG (25 m) stand at (-7.2, 0) and
  (-7.2, 4) on the same open left side. Their spacing is eased to 4 m (`gun_gap`): the post measured blocked in
  round 3, at (-7.5, 7.5), leaves no room further apart.
- **Other knock-on moves:**
  - Neri's tower is now at (7.6, -10.1). My clip model is more cautious there than the game was.
  - Each town's tier 3 line autorifleman has shifted with its line.

## Line audit (tier 3)
**How to read it.** Each side runs corner to corner and is cut into gaps: the stretches between the things that
already close it (a neighbour, an old wall or the house within 1.2 m of the line, or the next side at a corner).
For each side the table gives what closes it, in metres. It then lists each gap's length against the pieces
covering it, and how far those pieces run past the gap's ends onto what they tie into. Any open stretch over
0.3 m is listed, but every ring passes the flood fill: what remains open on the line is backed by something
within reach.

| Town | Side | 2-high | 1-high | Low (concrete, bags) | Gate | Tower | Neighbours | Gaps: length → covered (past the ends) |
|---|---|---|---|---|---|---|---|---|
| Kore | back | – | 20.9 | 4.0 | 5.1 | 3.2 | – | 33.6 → 33.2 (0.7, 0.8), 0.4 m open at the HMG's bags |
| | front | 23.6 | 8.2 | – | – | – | 1.8 | 31.8 → 31.8 (1.0, 1.2) |
| | left | 16.2 | 7.2 | – | – | – | 2.7 | 23.4 → 23.4 (0.7, 2.7) |
| | right | 23.2 | – | – | – | 2.9 | – | 26.1 → 26.1 (1.1, 1.1) |
| Telos | back | 8.5 | 15.4 | 2.1 | 5.1 | – | – | 31.1 → 31.1 (0.8, 1.1) |
| | front | – | 6.4 | 3.6 | – | – | 20.9 | 5.5 → 5.5; 4.7 → 4.5 |
| | left | 0.3 | 11.8 | 0.4 | – | – | 9.2 (city wall) | 3.8 → 3.8; 6.1 → 6.1; 2.6 → 2.6 |
| | right | 13.5 | 4.1 | – | – | 3.5 | 0.5 | 19.1 → 19.0; 2.1 → 2.1 |
| Lakka | back | – | 10.0 | 2.1 | 5.1 | 2.9 | – | 20.1 → 20.1 (0.9, 1.1) |
| | front | 3.6 | 9.5 | 2.1 | – | – | 4.9 | 13.6 → 13.6; 1.6 → 1.6 |
| | left | 15.2 | 8.5 | – | – | – | 2.4 | 5.9 → 5.9; 17.8 → 17.8 |
| | right | 17.2 | 5.5 | – | – | 3.2 | 0.2 | 18.9 → 18.9; 7.0 → 7.0 |
| Poliakko | back | 7.7 | 9.1 | – | 5.1 | 3.5 | – | 25.4 → 25.4 (1.4, 1.1) |
| | front | – | 19.2 | – | – | – | 6.2 | 19.2 → 19.2 |
| | left | 14.3 | 3.7 | – | – | 3.5 | 3.6 | 21.5 → 21.5 |
| | right | 8.5 | 12.5 | 4.0 | – | – | – | 25.1 → 25.0 |
| Dorida | back | – | 16.1 | 2.1 | – | – | 17.3 | 7.3 → 7.3; 4.1 → 4.1; 5.6 → 5.0; 1.8 → 1.8 |
| | front | – | 13.8 | 2.1 | 5.1 | 3.5 | 11.2 | 3.7 → 3.5; 21.2 → 21.0 |
| | left | – | 2.4 | – | – | – | 18.2 | 2.8 → 2.4 |
| | right | 15.5 | 2.0 | – | – | 3.5 | – | 21.0 → 21.0 |
| Selakano | back | – | 14.0 | 6.2 | 4.0 | – | 8.9 | 20.4 → 20.4; 3.8 → 3.8 |
| | front | 11.3 | 9.5 | 1.7 | – | 3.5 | 6.9 | 2.3 → 2.3; 21.2 → 21.0; 2.7 → 2.7 |
| | left | 4.8 | 4.1 | 0.4 | – | – | 11.8 | 1.9 → 1.8; 8.0 → 7.5 |
| | right | 7.8 | 7.9 | 1.9 | – | – | 3.1 | 2.6 → 2.6; 16.0 → 15.0 |
| Gravia | back | – | 8.1 | – | 5.1 | 3.5 | 1.4 | 16.7 → 16.7 |
| | front | 8.5 | 7.5 | 2.1 | – | – | – | 18.1 → 18.1 |
| | left | – | 12.5 | – | – | – | 11.8 | 0.5, 5.1, 3.6, 3.3: all covered |
| | right | 1.2 | 2.8 | 1.4 | – | – | 18.9 | 2.8 → 2.8; 2.6 → 2.6 |
| Alikampos | back | – | 5.0 | 5.3 | 4.3 | 3.5 | – | 18.1 → 18.1 |
| | front | – | 17.3 | – | – | – | 0.8 | 14.3 → 14.3; 3.0 → 3.0 |
| | left | – | 5.8 | 0.5 | – | – | 15.8 | 2.5 → 2.5; 3.8 → 3.8 |
| | right | 6.5 | 9.4 | 2.1 | – | 3.5 | – | 22.1 → 21.5, 0.6 m open by the HMG |
| Neri | back | – | 3.5 | 4.3 | 5.1 | 2.5 | 4.7 | 9.8 → 9.8; 5.6 → 5.6 |
| | front | – | – | – | – | – | 20.1 | – |
| | left | – | 18.9 | 4.6 | – | – | 0.5 | 23.4 → 22.8; 0.7 → 0.7 |
| | right | – | 9.1 | – | – | 1.8 | 13.7 | 1.5 → 1.5; 9.4 → 9.4 |
| Stavros | back | – | 0.1 | 1.5 | – | 0.8 | 10.9 | 2.6 → 2.3 |
| | front | – | 6.7 | – | 5.1 | – | 1.8 | 1.2 → 1.2; 10.6 → 10.6 |
| | left | – | 9.9 | 4.2 | – | 3.5 | 1.6 | 16.8 → 16.4; 1.2 → 1.2 |
| | right | – | – | – | – | – | 19.6 (house, neighbour) | – |

### Where a tier 3 still falls short of Kore, and why
- **Alikampos, front:** the line is 18 m long. The door gendarme's 3 m line of sight splits it into two
  stretches, 7.7 m and 7.9 m, and a 2-high piece needs 8.4 m, so the whole front is 1-high.
- **Neri, left:** both guns stand on the open left side, 11 m apart, so their 1-high stretches cover the whole
  line.
- **Stavros:** a 13.5 × 19.5 m yard. One side is the gate, one is the guns, one is the house and the neighbour.
- **Gravia, Dorida, Neri:** most of their open sides are neighbours and old walls, so the pieces only fill
  short gaps.
- **Every ring is closed** and has a gate (Kore-style bar gate on the door's axis) and a tower; nine of the ten
  towers stand at a corner or on a side line.

## What to check in the game
1. Telos tier 3, top and street views against Kore: the tower at (8.0, 2.0) behind the city wall, and whether
   its marksman really sees over the wall to the junction. Also the HMG pit at (6.5, 6.8), between the old wall
   and the road.
2. Stavros tier 3:
   - the tower at (-9.0, -5.0) by the road corner;
   - the GMG at (-7.2, 4.0), measured from 3.5 m off round 3's blocked post at (-7.5, 7.5);
   - nothing clipping the house.
3. Kore: the GMG at (-13.0, -13.2), facing 180.
4. The re-measured items:
   - the map board (0.3 m off the wall) everywhere;
   - Alikampos' flag at (-0.7, -9.0);
   - Topolia's porch bags at (1.4, -5.8) and their men at y -4.8;
   - Poliakko's balcony gendarme (-0.6, -5.3) and marksman (0.6, -5.3).
5. Any H-barrier or tower still reported in a wall or the office. That would tell me where my clip model is
   still wrong; it was calibrated only on round 4's results.
6. Gaps: a man getting through any ring, especially:
   - Stavros' back-left corner, by the porch (filled this round);
   - the 0.4–0.6 m stretches the audit lists beside the guns' round bags (Kore back, Alikampos right).

## Research used
- **Entry control:** UFC 4-022-02, *Selection and Application of Vehicle Barriers*
  ([WBDG](https://www.wbdg.org/FFC/DOD/UFC/ufc_4_022_02_2009_c1.pdf)). Passive barriers on a perimeter, and an
  entry control point that forces a vehicle to slow. The bar gate and chicane at each gate follow this, and so
  does keeping the road-facing house front as the line instead of a row of jersey barriers on the pavement.
- **Perimeter walls:** perimeter HESCO is stacked two high, about 2.2 m, as a wall above a man's or a vehicle
  roof's reach, with lower sections where defenders fire over
  ([summary](https://dev.asburyseminary.edu/manual/what-are-the-key-features-and-specifications-of-hesco-level-dmeo.html)).
  That is the rule here: 2-high by default, 1-high only where a gun or a man fires over the line.
