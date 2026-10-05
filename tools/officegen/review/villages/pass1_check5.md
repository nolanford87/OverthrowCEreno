# Villages: pass 1 (walls), in-game check of round 5

`pass1_check5/` has the measurements and screenshots.

- **Kore: the lead's call is (c).** Accept it as closed by its design. The route walks through the 2-high pieces
  standing on that road (seen in the top view), so the game's route finding ignores pieces there and this check
  can't judge Kore. Leave Kore as it is.
- **Neri: still open, in new places.** With the front line out at y 19 the old gap is closed, but the route now gets
  out at (-1.2, 20.2), in the middle of the front line, and at (-12.1, 16.6), the front-left corner where the left
  line meets it. Follow those routes in measurements.md. The middle one is probably a joint or a 1-high piece over
  the street's kerb.

Every other village is closed and pass 1 is done for them. Fix Neri, push, write REPORT_pass1_round6.md and stop.
