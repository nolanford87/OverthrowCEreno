# Hamlets: round 1 critique

Tested in the game (Altis, all 18 hamlets, both tiers): `round1/measurements.md` and the screenshots beside it
(`<town>_T<tier>_top.jpg` from above, `<town>_T<tier>_street.jpg` from the street side).

## Verdict
Clean work: nothing clips, nothing floats, no guard is blind or pushed off his post, every class exists. The ladder's
logic (held door, C nest, sentry bag, window marksman, landing rifleman) is sound and the guard counts (2 -> 6) are
right. **But tier 2 is not noticeable.** From above and from the street, tier 1 and tier 2 look almost the same
(compare `Agia_Triada_T1_top.jpg` with `Agia_Triada_T2_top.jpg`, or Kalithea's): a C of sandbags and a single bag
are lost in the scene. The user's ladder says tier 2 must be a clearly noticeable step even in a hamlet.

## Make tier 2 read at a glance (from 35 m)
- Give the held door some MASS: an H-barrier blast wall (Land_HBarrier_3_F / _5_F) shielding the way in or the nest's
  exposed flank, so the doorway sits in a fortified pocket, not behind a lone bag.
- Add one visible post covering the main approach (the nearest road, or the open side): a Land_BagBunker_Small_F or
  a sandbagged position of round bags, manned; this is what a passer-by notices first.
- Control the road where a road passes close (Kalithea, Koroni, Agios Petros, Feres...): a small roadside check (a
  few concrete barriers or a bar gate, a man) makes the occupier presence obvious.
- A short run of razor wire on the open flank is a cheap, very visible signal of a defended building.
- Keep it sensible for a hamlet: this is still tier 2 (about 6 guards), but the fortification footprint should
  roughly double or triple, and be visible from the street.

## Notes
- Real sizes: `townlib.MEASURED` (merge `origin/feat/office-town-layouts`) has the in-game bounding boxes of the
  classes used so far (upper bounds: they include some slack).
- Barrier pieces may overlap each other and the buildings slightly to make unbroken lines (the brief's new rule).
- Oreokastro: keep your fallback; the rock's probe box is indeed huge (we'll check walkability by hand later).

Iterate, check, push to `layouts/hamlets`, and report the per-town counts again.
