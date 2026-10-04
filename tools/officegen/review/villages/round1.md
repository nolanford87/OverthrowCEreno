# Villages: round 1 critique

Tested in the game (Altis, all 15 towns): `round1/measurements.md` and the screenshots beside it
(`<town>_T<tier>_top.jpg` from above, `<town>_T<tier>_street.jpg` from the street side). Alikampos, Poliakko and
Selakano were only checked to tier 2 this round (a checker limit, fixed: their tier 3 is checked next round).

## Verdict
The ladder is right in principle (police -> held doors -> compound; 3 / 6 / 12 guards) and the research shows. But
**the steps don't read**. Tier 2 is a few bags at the door, hard to see from the street; tier 3 is meant to be "a
large difference, a defended compound", and in most towns it reads as a short line of barriers in front of the door
(Dorida, Telos, Kore, Stavros) rather than a fortified site. **Lakka is the model**: a closed H-barrier ring round the
house with the gate in it; that's what every tier 3 should look like at a glance.

## Fix
1. **Tier 3 = a compound you can see from the street.** Close the yard all round (the neighbours and old walls close
   their sides; H-barrier lines close the rest, overlapping slightly so the line is unbroken). Use taller pieces where
   the line faces a road or open ground (Land_HBarrierWall4_F / Wall6_F, 2-high); add one raised post (a
   Land_BagBunker_Tower_F or a bag bunker at the corner covering the main approach). The gate (bar gate) square with
   the way in, covered by the nest and a static.
2. **Tier 2 must be noticeable from the street**: more mass at the way in (an H-barrier blast wall shielding the
   nest's flank, a short wire run), not only a C of bags.
3. **Statics with no field of fire** (measured: the cone ahead ends at)
   - Gravia HMG 1.6 m, Dorida GMG 3.3 m, Neri HMG 8.3 m: they face into walls or buildings. Every static needs a
     clear field down an approach (aim for 30 m or more); turn or move them to the line's open side.
4. **Blind guards**: the door gendarme in Alikampos, Kore, Poliakko and Selakano faces a wall 3.2 m away; Gravia,
   Lakka and Neri each have a rifleman 1.6 m from a wall; Kore's MG gunner 2.3 m. Face them out over their cover or
   along the approach.
5. Clips: H-barriers into a tree bin (Dorida), a stone wall and a wire fence (Lakka), a city wall (Neri) are fine
   under the overlap rule if slight; the map board and flag "office" clips are false positives (wall-mounted).

## Notes
- Real sizes: `townlib.MEASURED` (merge `origin/feat/office-town-layouts`) has the in-game bounding boxes (upper
  bounds). Land_HBarrierWall6_F is about 8.5 m long, not 6.5.
- Statics are spawned uncrewed in this check; in play the occupier crews them.

Iterate, check, push to `layouts/villages`, and report the per-town counts again.
