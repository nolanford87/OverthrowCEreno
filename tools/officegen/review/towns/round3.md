# Towns: round 3 critique (with the tower fix, 43e34cd5)

Tested in the game (all 11): `round3/measurements.md` and the screenshots in `round3/`. Every item spawned, and the
tower men are fine on the platform. Flagged items come with their [x, y] in the office's model coordinates. Note:
"hmg" blocked at the same spot as a floating B_static_AT_F is the AT gun (the role lookup called it hmg; fixed on the
main branch).

## Design: tier 4 isn't a fort yet, and tier 3 hugs the house
Look at Chalkeia's and Molos' T3/T4 street views:
- T3 is a wall of H-barriers along the porch front with a bar gate. The sides of the house are open. A "defended
  compound" closes the open sides with lines to the neighbouring buildings and walls, so the only way in is the
  controlled one.
- T4 adds a tower standing on the plaza right in front of the door, plus concrete blocks and hedgehogs dotted about
  the open plaza, each on its own. That isn't an obstacle belt. A fort has a continuous perimeter (the house's yard and
  the neighbours tied into one closed ring), towers at its corners (not in the entry's face), a gated chicane entry, and
  obstacles in belts in front of the lines, covered by a gun.
- Molos T4 closes the north side well. The south (porch) and east sides are still open.

## Measured problems
- **Pipe-fence gate inside the office** (every town, T2 on): Land_PipeFence_03_m_gate_r_F's middle is in the office's
  walls or pillars. Move it clear of the porch.
- **Blind**: an interior rifleman (3.8, -5.3) 1 m (Agios Dionysios, Kalochori: the same post); Charkia rifleman
  (10.7, 4.3) 1.2 m; Paros marksman (14.5, 11.8) 0 m and MG gunner (11.9, 9.2) 1.5 m (T4).
- **Kalochori MG gunner (2.6, -13) pushed 1 m off his post.**
- **Statics blocked**: Kalochori HMG (-2.2, -10.1) 4 m and GMG (-7.5, -11.8) 3.9 m; Rodopoli HMG (-8.7, 7.5) 4.2 m
  (T3) and GMG (-15.1, -13) 4.3 m (T4); Neochori AT (2, -13.8) 10 m; Therisa AT (16, -10.7) 7 m; Panochori GMG
  (-9.1, -4) 14.6 m.
- **AT gun floating** 0.3-0.7 m: Agios Dionysios (9.6, -11.4), Charkia (-1.2, -11.6), Kalochori (11.4, -12.7),
  Neochori (2, -13.8), Panochori (7.4, 7.4), Therisa (16, -10.7). Probably the tripod's shape; keep them on level
  ground.
- **Clipping mid-piece** (not the allowed end overlap):
  - **Kalochori**: five HBarrier_1 into stone walls and pillars, and the bar gate into a wall.
  - **Charkia and Chalkeia**: HBarrier_3 and HBarrier_1 into stone walls and a wire fence.
  - **Therisa**: four HBarrier_1 into city walls.
  - **Molos**: two HBarrier_1 into a city wall.
  - **Agios Dionysios**: BagFence_Short and HBarrier_3 into a tin wall.
  - **Rodopoli**: HBarrierWall6 into a house.
  - **Neochori**: a tower into a city wall.
  - **Paros and Panochori**: HBarrier_3 and HBarrier_1 into the office itself.
- Sofia and Therisa: the screenshots came out dark (dusk; fixed for the next run).

Fix these, keep tl.check() passing, push, and report.
