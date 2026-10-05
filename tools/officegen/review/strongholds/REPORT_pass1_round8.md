# Strongholds: pass 1, round 8 report (answering pass1_check7.md)

Branch `layouts/strongholds`. Every draft passes `tl.check()`. The counts are unchanged: Kavala 0/9/55/110/134,
Pyrgos 0/11/35/96/106, Athira 0/5/19/52/56, Zaros 0/4/26/64/68.

## Kavala: the clip at (-10.5, -0.4)

The piece was the south end of T3's forecourt line. That line runs from side1 down to the south block at x -10.5. Its
east face (x -9.65) cut the step in the hospital's wall where side2 joins the main block. The probed plan puts that
wall at x -10..-8, y -4..-1.

- **The fix:** the whole forecourt line moves 0.9 m west, to x -11.4. The H-barriers' east face is now at x -10.55
  and the Mil walls' at -10.85.
- **Lines that follow it:**
  - the north line's west end, round side1, now stops at x -11.4 minus the half depth;
  - the line along the south block's north face (y -2) now starts at x -11.4.
- **Lines left as they were:** the stubs into the helipad block, the south and east lines, and T4.
- **T5 too:** the same line in Mil walls had the same clip at (-10.5, -0.9). The move clears it as well.
- **T4:** carried the T3 piece over, so its clip goes too.

**Closure from (13.1, -6.1)**, with the block's west end solid (the model that matched your round 7 walk): T3, T4 and
T5 closed, both with everything standing and with each ring on its own. T1 and T2 come out open.

## Left in your round 7 measurements (not changed)

- **T5, (-39.5, -11.3):** a `Mil_WallBig_4m` on T5's line along the helipad block's west face clips the office. This
  is the same wall that T3's H-barriers cut there before round 7. If you want T5 clear as well, the fix is the T3
  one: stubs into the block's north and south faces at x -36.
- **T4 and T5:** the `CncWall1` pieces at x -15.2..-12.3 (y 60.5) and the Mil walls at (-0.2, 57.9), (3.5, 56.8),
  (16.4, 52.9) and (20.1, 51.8) stand into the canal walls. I left these as they were.
