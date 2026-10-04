# Towns: round 2 critique

Tested in the game (all 11, tiers 1-4): `round2/measurements.md` and the screenshots in `round2/`.

## Verdict
Clear progress: the statics are off the balcony and most fire properly now, and tier 4 reads as a fort in the
pictures (Charkia: H-barrier compound, the tower, the hedgehog belt; Molos too). What's left:

## Measured
- **Tower men can't see (view 1 m or less)**: the marksman/rifleman on the Land_BagBunker_Tower_F in Chalkeia, Paros,
  Sofia (and the "marksman 1 m" lines elsewhere): your 2.7 m platform guess puts them inside the tower's sandbag
  walls. The next check logs the tower's real standing positions (building positions, model coordinates) in
  `measurements.md` ("Where a man stands on a placed object"); until then, the vanilla Land_BagBunker_Tower_F's
  platform is the place to aim for. Use those positions turned with the tower.
- **Balcony MG gunner still blind at 1.0 m in nearly every town** (Agios Dionysios, Charkia, Kalochori, Molos,
  Neochori, Panochori, Paros, Rodopoli): something on that balcony (its awning posts or the roof edge) blocks eye level
  whatever way he faces. Give up that post: put the MG gunner on the tower or at a ground-floor window/the veranda
  with a clear front.
- **Window/veranda riflemen at 1.0-1.4 m** (Agios Dionysios, Chalkeia, Charkia, Kalochori, Therisa): same story.
- **Blocked statics**: Kalochori HMG 3.2 / GMG 3.9, Therisa HMG 2.5, Rodopoli GMG 4.3, Neochori HMG 10, Panochori GMG
  14.4.
- **AT gun "floating" 0.3-0.7 m** (Agios Dionysios, Kalochori, Neochori, Panochori): this may be the AT tripod's
  shape fooling the measurement (it reads the same in every group); the lead will confirm by eye. Keep placing it on
  level ground.
- Charkia: one rifleman pushed 1.4 m off his post (he stood in geometry).

## Next
Fix those and this group is close to ready for the user's review in the editor.
