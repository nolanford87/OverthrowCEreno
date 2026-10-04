# Strongholds: pass 1 (walls), in-game round 2

Tested in the game: `pass1_round2/measurements.md` (each way out with its route) and the screenshots in
`pass1_round2/`. Kavala's shots are from farther out for the hospital (the camera now scales with the office's size).

## Design
- **Athira, Zaros and Pyrgos: much better.** T4 now takes in the compound: Athira's high walls close the courtyard
  and its buildings, Zaros' wall takes in the back yard and the shed, and Pyrgos' runs along the fence lines. Keep
  this direction.
- **Kavala (the hospital) isn't walled in yet.** From above and from the street (T4, T5), the high walls box the
  planter on the west forecourt and stand in a few places on the east and south-east. There's no ring round the
  hospital, and its south and west fronts face the street open. The site helps: the rock cliff closes the east side
  of the service yard and the road bounds the north. So:
  - **T3**: a tight H-barrier ring round the building and its wings.
  - **T4**: high walls along the forecourt's street edges (west and south) to the cliff, tied into the rocks
    (rocks count where they're cliff, not boulders), taking in the forecourt and the service yard.
  - **T5**: the T3 ring raised to high walls.

## Closure (routes from inside the office; the gap is where the route last passes within 3 m of a piece)
- **Zaros T4 and T5**: closed.
- **Athira T3**: out at (8.1, 11.5) and (-9.8, 3.8).
- **Kavala T4/T5**: out at (14, -28.9), (-38.5, -22.5) and (-30.1, 2.2).
- **Not reliable** (the route got out without passing near any piece, so the start was outside the ring): Athira
  T4/T5, Zaros T3 and Kavala T3. Your audit carries those.
- **Pyrgos**: can't be checked (the Offices_01 tower). Your audit carries it.

## Pieces
- **Zaros**: the sandbags and the HBarrier_3/5 still cut into the office (T2 on). At T5 there are also two CncWall1
  and two Mil walls in it.
- **Athira T5**: a Mil wall cuts into the office. Move them clear.

Fix, push, write REPORT_pass1_round3.md and stop.
