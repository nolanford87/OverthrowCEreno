# Villages: round 5 critique (3f58d513)

Tested in the game (all 15; seven reshot because the weather fogged them): `round5/measurements.md` and the
screenshots in `round5/`. Every item spawned. A big step: the map boards, the flag and nearly every barrier clip are
fixed, and your clip model held up. Kore, Poliakko, Gravia and Telos now read as closed compounds from above.

## Design
- **Stavros T3** is the weak one: separate H-barrier pieces round a small house, with gaps between them on the road
  side and at the back; it doesn't read as a ring. If the yard's too small for a ring, wall the house itself in
  (pieces against its walls, overlapping at the corners) and put the gate on the door.
- **Selakano T3**: the west and south are closed. The road front is short pieces with gaps either side of the gate,
  and there's a gap between the white annex and the tree on the north side. Close both.
- **Alikampos T3**: acceptable (the house front is the line, with the gate at the door), but the street-side tower
  stands alone; tie a line from it to the house corner.

## Measured problems (office model [x, y])
- **Dorida GMG** (12.6, 9.4): blocked at 0 m, something stands right in front of or on it.
- **Lakka HMG** (2.5, -12.5): 1.9 m.
- **Stavros HMG** (-7.3, 0.9): 6.6 m.
- **Telos' tower cuts into the office** (T3): your tower at the front-right road corner overlaps the house. The top
  view shows no tower anywhere, so it's buried in the building. Move it out to the corner proper.
- **Neri's tower cuts into a tree planter** (treebin_f.p3d, T3): the probe may not list planters as obstacles. Shift
  it clear.
- **Topolia's BagFence_Long still cuts into the office** (T2): move it a further 0.5 m out.
- **The interior gendarme at (-2.8, -5.4)** (Neri and Stavros, the same office class): pushed exactly 1 m off his
  post, at every tier. Marginal, but move him 0.5 m into the room.

Fix these, keep tl.check() passing, push, and write REPORT_round6.md.
