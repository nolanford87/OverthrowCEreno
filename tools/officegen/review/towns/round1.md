# Towns: round 1 critique

Tested in the game (Altis, all 11 towns, tiers 1-4): `round1/measurements.md` and the screenshots beside it
(`<town>_T<tier>_top.jpg` from above, `<town>_T<tier>_street.jpg` from the street side).

## Verdict
The best of the first round: the tiers read in the pictures (Charkia: walls at T3, then the hedgehog belt, more
walls and the corner bunkers at T4), the perimeters close, the counts are on the ladder (2 / 6 / 12 / 20). Two things
to fix: a set of positions that fail the same way in every town (they come from the shared ladder, so one fix covers
all 11), and tier 4 should read more clearly as a FORT.

## Positions that fail in every town (fix once in the ladder)
- **Balcony GMG: blocked at about 2 m in almost every town** (Agios Dionysios 2.0, Chalkeia 1.9, Charkia 2.6,
  Kalochori 2.7, Molos 1.9, Neochori 1.9, Rodopoli 1.9, Therisa 2.7): the balcony's walls/rail box it in. Statics on
  that balcony don't work; put the GMG on the ground in a wall embrasure or on a raised post (a Land_BagBunker_Tower_F
  is now allowed anywhere: a guard may stand on a placed tower, see townlib).
- **Balcony-corner MG gunner: facing a wall about 1 m away** (every town at T4). Turn him out over the rail along the
  approach, or move him.
- **The veranda rifleman (about 1.6 m) and a window rifleman (about 2.1 m) face walls** in most towns. Use
  `t.plan().windows` to stand window men AT a real window facing out, and turn the veranda man along the open side.
- **AT gun floating 0.3-0.6 m** (Agios Dionysios, Charkia, Panochori): it stands on a slope or a ledge edge; flag it
  on the ground (`z=None`) where it's outside, or move it onto level ground.

## Town-specific
- Blocked HMGs: Kalochori 2.5 m, Sofia 2.8 m, Therisa 2.3 m, Neochori 10.2 m. Each needs a clear field down its
  approach (aim for 30 m).
- Blind: Rodopoli's autorifleman 3.5 m, Therisa and Paros riflemen 3.8-3.9 m, Sofia's marksman 1.4 m.

## Make tier 4 a fort
From the street, tier 4 reads as a walled yard with obstacles. Per the ladder it's a FORT: add a raised post or two
(Land_BagBunker_Tower_F at the corner covering the main approach), make the line facing the main road 2-high
(Land_HBarrier_Big_F or HBarrierWall pieces; `townlib.MEASURED` has the real sizes) and keep the gate's chicane.

## Notes
- Real sizes: `townlib.MEASURED`; merge `origin/feat/office-town-layouts` for it and the tower rule.

Iterate, check, push to `layouts/towns`, and report the per-town counts and what changed.
