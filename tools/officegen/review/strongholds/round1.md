# Strongholds: round 1 critique

Tested in the game (Altis, Kavala, Pyrgos, Athira, Zaros, tiers 1-5): `round1/measurements.md` and the screenshots
beside it. Note: the top-down pictures of Kavala and Pyrgos were taken too low (48 m, only about 20 m above the
tower's roof), so they show the roof and little of the ground; the checker now takes them from 40 m above the roof.

## Verdict
The guard counts are on the ladder (3 / 6 / 12 / 20 / 37-39) and the design ideas are right (lobby pocket, bagged
corridors, forward yard with corner bunkers, checkpoints, roof weapons). But the weapons and many of the posts don't
work in the game yet, and from the street the outside doesn't read as a fort (T4) or an absolute stronghold (T5):
much of the added strength is inside or on the roof. The street view of tier 5 must make a player think twice.

## The weapons (fix first)
- **Pyrgos: almost every static is blocked**: GMG 1.4 m (from T3), HMGs 7.2 m and 1.4 m (T4) and 3.8 m (T5). The
  roof guns face the roof's parapet; the ground ones face walls. Each static needs a clear field down its approach.
  On the roof, put the gun right at the parapet facing out (and check it can depress onto the street), or use the
  roof for riflemen and marksmen and put the heavy weapons on the ground at embrasures.
- **Kavala: the mortar is boxed in (7.4 m)**: a mortar fires upward so a short cone isn't fatal, but give it an
  open pit away from walls.
- **Athira**: GMG 11.6 m, HMG 2.6 m; **Zaros**: HMGs 1.9 m and 9.5 m.
- **Floating**: Pyrgos T5 has a round sandbag 3 m in the air (probably meant for the roof); Athira's AT gun 0.3 m,
  Zaros's GMG 0.3 m.

## The posts
- **Guards at 0-0.3 m view are inside something**: Kavala's autorifleman and rifleman (T3 on), Pyrgos's two
  autoriflemen (T4 on), Athira's T5 interior men (three at 0 m), Zaros's rifleman 0.4 m. Probably standing inside a
  barricade or furniture, or against an interior wall: leave 0.8-1.5 m behind cover and face the room's door.
- **Lobby gendarme facing a wall 2.8 m away** (Kavala, Pyrgos, every tier), Zaros's door gendarme 2.4 m; MG gunners
  2.9 m (Kavala, Pyrgos T5). Turn them to the door or along the approach.

## Make it read from the street
- Tier 4 = a fort: a continuous perimeter you can see, 2-high on the faces toward the roads (Land_HBarrier_Big_F /
  HBarrierWall; `townlib.MEASURED` has the real sizes), towers or bunkers at the corners (a guard may now stand on a
  placed tower anywhere), the chicane at the gate.
- Tier 5 = an absolute stronghold: the checkpoints on each approach road must be obvious (H-barrier blocks across the
  road, a bunker, wire), plus more outer mass; the inside kill zone stays.

## Notes
- Merge `origin/feat/office-town-layouts` for MEASURED, the overlap rule and the tower rule.

Iterate, check, push to `layouts/strongholds`, and report the per-town counts and what changed.
