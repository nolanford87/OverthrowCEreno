# Villages: round 6 report (answer to round5.md)

Commit `6648a01`. All 15 drafts pass `tl.check()`. All ten tier 3 rings pass the closure check (a flood fill for a
man 0.4 m across the shoulders). The script's clip test (the game's rays across each piece's measured box) flags
nothing. `python tools/officegen/drafting/villages.py --audit --views [--map] [town]` gives every number below.

## Counts (things / guards / statics)

| Town | T1 | T2 | T3 |
|---|---|---|---|
| Alikampos | 7 / 3 / 0 | 16 / 6 / 0 | 48 / 13 / 2 |
| Dorida | 7 / 3 / 0 | 16 / 6 / 0 | 48 / 13 / 2 |
| Gravia | 7 / 3 / 0 | 16 / 6 / 0 | 47 / 13 / 2 |
| Kore | 7 / 3 / 0 | 16 / 6 / 0 | 49 / 13 / 2 |
| Lakka | 7 / 3 / 0 | 16 / 6 / 0 | 56 / 13 / 2 |
| Neri | 7 / 3 / 0 | 16 / 6 / 0 | 49 / 13 / 2 |
| Poliakko | 7 / 3 / 0 | 16 / 6 / 0 | 51 / 13 / 2 |
| Selakano | 7 / 3 / 0 | 14 / 6 / 0 | 58 / 13 / 2 |
| Stavros | 7 / 3 / 0 | 15 / 6 / 0 | 46 / 13 / 2 |
| Telos | 7 / 3 / 0 | 16 / 6 / 0 | 55 / 13 / 2 |
| Abdera, Agios Konstantinos, Galati, Nifi | 7 / 3 / 0 | 16 / 6 / 0 | – |
| Topolia | 7 / 3 / 0 | 12 / 6 / 0 | – |

## Design

### Stavros T3
Stavros' yard is already tight, so I walled in the house where it stands rather than redrawing the ring. It found a
bug: the script counted the open back porch as part of the house's wall, so it laid no line behind the porch.
That was the gap at the back.

- The script now counts only the house's walls and front steps as closing a line, not the porch.
- **Back line:** laid again behind the porch, unbroken from the tower to the neighbour.
- **Left line (the road side):** both guns used to sit in round sandbags set into the line, which broke it into
  short stubs. Stavros now has no sandbags in the line (`gun_bags` off). Each gun stands 1.6 m inside an unbroken
  1-high line and fires over it.
  - The HMG is at (-6.4, -2.5), estimated field of fire 45 m.
  - The GMG is at (-6.4, 4.0), 26 m.
  - Both are kept 3 m from the HMG post you measured at 6.6 m. Something the probe doesn't list stands about
    6.6 m west of it.
- **Front:** the gate is on the front door's axis.
- **Right side:** the house and the neighbour close it.
- **Tower:** stays on the left line by the road corner.

### Selakano T3
- **Road front (the gate line):** 1-high pieces may now step up to 0.8 m in off the road's edge and slide up to
  0.6 m back over the piece before. That puts longer pieces either side of the gate where it fits.
  - North of the gate, the line runs on to the garage.
  - South of it, the HMG sits close to the gate. The ground between them only takes 1-high pieces, and they now
    overlap without gaps.
- **North side, between the annex and the tree:** the slit was a 0.57 m gap between a 1-high piece and the GMG's
  sandbags. The fill could never back up into it; now a piece slides back to close it. The GMG itself has not
  moved.
- **All sides:** every side now gets its 2-high pass before any side gets its 1-high fill, so one side's fill
  can't take the corner from the next side's 2-high pieces. Selakano gained 2-high length: 13.7 m on the road
  side opposite the gate, 8.5 m north.

### Alikampos T3
- One 1-high piece now ties the tower to the house's south-east corner: an HBarrier_1 at (6.0, -7.6), turned 55°,
  through the new `ties` setting.

### Every tier 3
- The gate pair is placed before the lines, so the line stays 1-high in front of the two men. They stand at least
  0.9 m from any other man. Dorida's pair had ended up 0.5 m apart on the same side.

## Measured items
- **Dorida GMG (12.6, 9.4):** that post is now avoided. The gun moved to the right line at (16.2, 5.2), estimated
  21.5 m.
- **Lakka HMG (2.5, -12.5):** avoided. It moved to the right line at (9.2, -7.7), 45 m.
- **Stavros HMG (-7.3, 0.9):** avoided within 3 m (see Stavros above).
- **Telos tower:**
  - It now straddles the right line at (9.5, 1.6), 4.1 m from the house.
  - The rule now keeps a tower's centre 2.7 m clear of the house box; 2.6 m clipped this round, 2.8 m was clean.
  - Its platform view drops to an estimated 22.8 m. Further toward the road corner, the old city wall and the
    road leave no room for it.
- **Neri tower:** moved to (9.0, -12.0), 0.3 m from its round 4 post, which measured clean.
- **Topolia BagFence_Long:**
  - The bag cut into the house both at y -6.3 (round 4) and at -5.8 (round 5), both times at x 1.4. So depth on
    the porch isn't the cause; something stands at the bag's east end.
  - I moved it 0.5 m along the porch toward its middle: (0.9, -5.8), its two men to (0.3, -4.8) and (1.5, -4.8).
  - I didn't take "further out" off the porch: the ground there is 0.73 m below the porch floor, so a bag on it
    gives the porch men no cover.
  - If it still clips, the next try is a short bag (BagFence_Short) in its place.
- **Interior gendarme at (-2.8, -5.4), Neri and Stavros:**
  - That reading is where he ended up: his post is the porch gendarme's, (-1.9, -5.8), and he was pushed off it.
  - His post moved 0.5 m into the house, to (-1.9, -5.3) (`porch_y`), at every tier.
- **Left alone:** Nifi's gendarme and Selakano's GMG are unchanged.

## Line audit (tier 3, metres along each side)
| Town | Side | 2-high | 1-high | Low | Gate | Tower | Neighbours |
|---|---|---|---|---|---|---|---|
| Kore | back / front / left / right | 1.2 / 24.4 / 23.4 / 23.2 | 19.1 / 7.4 / – / – | 5.0 / – / – / – | 5.1 | 3.2 / – / – / 2.9 | – / 1.8 / 2.7 / – |
| Telos | back / front / left / right | 9.8 / – / 0.3 / 8.5 | 13.3 / 8.3 / 12.2 / 9.2 | 2.9 / 1.9 / – / – | 5.1 | right 3.5 | – / 20.9 / 9.2 / 0.5 |
| Selakano | back / front / left / right | – / 13.7 / 4.8 / 8.5 | 13.6 / 7.3 / 4.7 / 8.1 | 6.6 / 1.7 / 0.4 / 1.9 | 4.0 | front 3.5 | 8.9 / 6.9 / 11.8 / 3.1 |
| Stavros | back / front / left / right | – | 9.9 / 6.7 / 14.5 / – | 2.9 / – / – / – | 5.1 | 0.8 / – / 3.5 / – | – / 1.8 / 1.6 / 19.6 |
| Lakka | back / front / left / right | – / 3.6 / 15.2 / 10.9 | 12.1 / 8.1 / 8.5 / 8.8 | – / 3.5 / – / 3.0 | 5.1 | 2.9 / – / – / 3.2 | – / 4.9 / 2.4 / 0.2 |
| Poliakko | back / front / left / right | 7.7 / – / 14.3 / 8.5 | 9.1 / 19.2 / 3.7 / 11.6 | – / – / – / 5.0 | 5.1 | 3.5 / – / 3.5 / – | – / 6.2 / 3.6 / – |
| Dorida | back / front / left / right | 1.2 / – / – / 8.5 | 14.3 / 16.3 / 2.8 / 7.0 | 3.3 / – / – / 2.0 | 5.1 | front 3.5, right 3.5 | 17.3 / 11.2 / 18.2 / – |
| Gravia | back / front / left / right | – / 8.5 / – / 1.2 | 8.1 / 6.5 / 12.5 / 2.8 | – / 3.1 / – / 1.4 | 5.1 | back 3.5 | 1.4 / – / 11.8 / 18.9 |
| Alikampos | back / front / left / right | – / – / – / 6.5 | 4.0 / 17.3 / 5.1 / 8.8 | 6.3 / – / 1.2 / 3.3 | 4.3 | 3.5 / – / – / 3.5 | – / 0.8 / 15.8 / – |
| Neri | back / front / left / right | – | 2.6 / – / 17.1 / 8.7 | 4.3 / – / 7.0 / – | 5.1 | 3.4 / – / – / 2.2 | 4.7 / 20.1 / 0.5 / 13.7 |

**Open stretches.** Over 0.3 m on any line: none. Round 5 had them at Alikampos, Dorida, Kore, Neri and Selakano.
The only remaining one is 0.1 m, on Selakano's north side.

**Changes from round 5 caused by the new placement order:**
- Kore's left side went from 16.2 m to 23.4 m of 2-high.
- Dorida's right side went from 15.5 m to 8.5 m, and Lakka's right from 17.2 m to 10.9 m, because their
  re-placed guns now stand on those lines.
- Telos' right side went from 13.5 m to 8.5 m because its tower now stands on that line.

## What to check in the game
1. Stavros T3 from above:
   - whether the house now reads as walled in;
   - the GMG at (-6.4, 4.0) and the HMG at (-6.4, -2.5), each firing over the 1-high line 1.6 m in front;
   - the back line behind the porch.
2. Selakano T3:
   - the road front either side of the gate;
   - the north side between the annex and the tree;
   - the GMG unchanged at (14.7, -0.5).
3. Telos' tower at (9.5, 1.6): no longer in the house, and what its marksman can see.
4. Neri's tower at (9.0, -12.0), clear of the planter.
5. Topolia's porch bags at (0.9, -5.8). If they still clip, I'll swap in a short bag.
6. Dorida's GMG (16.2, 5.2) and Lakka's HMG (9.2, -7.7), now on their right lines.
7. Whether the porch gendarme at (-1.9, -5.3) still gets pushed off his post in Neri and Stavros.
8. Alikampos' tie piece at (6.0, -7.6), between the house corner and the tower.
