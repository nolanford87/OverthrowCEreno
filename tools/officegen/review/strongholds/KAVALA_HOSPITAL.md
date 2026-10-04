# Kavala's office is now the hospital (the user's choice)

Kavala's mayor's office moves from the Offices_01 tower to Kavala's hospital, a unique landmark: Land_Hospital_main_F
at [3760.45, 12990.06] (direction 359), about 225 m east of the old tower. The main block is 32 x 45 m with 5 doors,
plus its two side wings (Land_Hospital_side1_F and side2_F), which are part of the same building.

- tools/officegen/probes/Altis_towns.txt now has Kavala probed round the hospital (HEAD, BOX, the doors, the
  buildings, walls, roads and the height grid within 45 m). tl.load()["Kavala"] gives it.
- Kavala's old layout is gone. Redo Kavala from scratch on the new site, as pass 1 (walls), to the same ladder:
  - **T1:** empty.
  - **T2:** sandbags on the building.
  - **T3:** a tight closed H-barrier ring.
  - **T4:** a sizeable high-wall perimeter round the compound.
  - **T5:** both rings high-walled.
  It's the biggest building in the game: the T3 ring wraps the whole hospital (wings included), and T4 takes in its
  grounds.
- A plus: the closure check couldn't start inside the Offices_01 tower, but the hospital should work with it.
