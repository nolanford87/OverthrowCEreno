# Strongholds: round 5 critique (30313171)

Tested in the game: `round5/measurements.md` and the screenshots in `round5/` (the top view now from 55 m above the
roof, so the whole compound is in frame). Every item spawned. The measured, gap-finding lines worked.

## Design
- **Kavala T5 now reads as a fort**: the west-yard bastion, the street front, the north yard with its tower, the
  north-east line. Keep it.
- **Zaros T4**: the road front is now a continuous 2-high line with its gate, but the **west yard is still open**:
  between the office's north-west corner and the west house there's a ~10 m mouth onto the road with nothing in it
  (top view: left of the road line). Close it 2-high, tied into the west house. Then check the south yard's openings
  through the low wall.
- **Athira T5**: the courtyard's north-south 2-high line reads well. From above I can't see what closes the east
  side between the two eastern buildings: check that gap in your audit and say what closes it.
- **Pyrgos T5**: the north line along the fence is good. The trees hide the west side; your audit says it's closed.

## Measured problems (office model [x, y])
- **Tower men pushed off their platform (1.3-2 m)**: Kavala T4/T5 marksmen (-4.2, -17.3), (-3.3, 14.7) and the
  autorifleman (-2.4, 15.4). These towers' men aren't on the measured spot (3.4 m up, 0.3 m forward of the centre,
  facing the tower's +y). Check how those two towers are turned and where their men are put relative to them.
- **Blind (0 m)**: Pyrgos tower marksmen (1.4, -23) and (15.4, -24.4) at T4/T5, facing into something. Riflemen
  (11.1, -31.7) and (-31.8, -11.1) at T5, probably checkpoint men facing their own blocks.
- **Statics blocked**:
  - Athira's GMG (3.3, -10.4) at 0 m (T3).
  - Athira's AT gun (-15.8, -6.7) at 13.8 m (labelled hmg).
  - Kavala's GMG (15.2, -28.3) at 9.9 m (T5).
  - Athira's mortar (6.8, -1.4) has something 5 m in front.
- **Athira T5 rifleman (5.1, 5.2)**: pushed 1.3 m.
- **Clipping mid-piece**:
  - **Kavala**: the bar gate into a city wall (T3 on); BagFence_Long and CncBarrierMedium4 into House_Big_02 (T5).
  - **Pyrgos**: the tower into a pipe fence (T4 on).
- **"Floating" 0.3-0.5 m**: AT guns at Kavala (19.2, -15.9), Athira (-15.8, -6.7) and Zaros (11.4, -23); Zaros'
  GMG (10.6, 12.3). Kavala's 1.4 m is fixed. A steady 0.5 m on the AT tripod is its shape, so ignore that unless
  it's more.

Fix these, keep tl.check() passing, push, and write REPORT_round6.md.
