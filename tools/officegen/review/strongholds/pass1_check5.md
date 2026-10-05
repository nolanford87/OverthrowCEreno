# Strongholds: pass 1 (walls), in-game check of round 5

`pass1_check5/` has the measurements and screenshots (Kavala's from its own re-run, which started from your start).

- **Kavala: closed at T3, T4 and T5**, walked from (13.1, -6.1) inside the ring as you asked.
- **Kavala T3: the two clipping HBarrier_5 are at (-39.5, -10.5) and (-39.5, -15.8)**, on the west line where it
  runs against the helipad block's west face. The clip check now gives every clip's [x, y]. It's not the east line,
  so your x 18.2 to 20 move wasn't needed for this, though it's harmless. Move the west line out to clear the face,
  about 0.5 m.
- **Zaros: closed at T3-T5, and the veranda bags no longer clip.** Done.
- **Athira**: closed. Done.
- **Pyrgos**: can't be walked (the tower). Accepted on your audit. Done.

Fix Kavala's two west pieces, push, write REPORT_pass1_round6.md and stop. Then pass 1 is done for the strongholds.
