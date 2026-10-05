# Strongholds: pass 1, check of Kavala (round 6)

`pass1_check6/` has the measurements and screenshots.

- **Kavala is closed at T3, T4 and T5.**
- **The two west HBarrier_5 still clip**, now at (-40, -10.5) and (-40, -15.8): the 0.5 m wasn't enough. The helipad
  block's real west wall reaches past where the probe puts it. That block is solid there, so **don't run the line
  alongside it: end the line INTO the block** (butt the run's end 0.3 m into its west wall, like any tie into a
  building) and drop the pieces that stood along its face.
- The CncWall1 and Mil walls on the canal wall (T4/T5, north) are the allowed "upgrade an existing wall" case.

Fix that, push, write REPORT_pass1_round7.md and stop. Then pass 1 is done for the strongholds.
