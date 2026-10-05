# Towns: pass 2a round 3

Commit 311de18a. Only Paros and Sofia changed, both at T4. In the agent's walk every tier 3 and 4 is closed with the
gates shut and gets out through every gate; `tl.check()` passes.

- **Paros T4, north way out (baseline, the road effect):** the track runs on north through the north wall. Second
  gate: north wall (-10.3, 23.0), marked 5.8 m (the road's width), 5.45 m open (its east edge is round 2's wall up the
  track, x -7.3). Out: C1 (-13.21, 23.00), W4 (-11.34, 23.00), W4 (-7.99, 23.10). Reason: a through road the
  occupier's vehicles use.
- **Sofia T4 (both in the baseline):**
  - Bearing 45, from the side door's yard east through the big east house: the user's T3 H-barriers closing that
    yard go back at T4 as at T3: HB5 (7.96, 8.17), (13.34, 8.14), (15.54, 4.69), (15.67, 1.29).
  - Bearing 90, along the track and out its east end: second gate, east wall (30.0, -10.9), 7.1 m (the road's width).
    Out: W4 (30.00, -14.98 / -11.81 / -8.63); in 3 C1. Reason: the occupier's road through the town.

Unchanged since round 2 (clean in the game): Agios Dionysios, Chalkeia, Charkia, Kalochori, Neochori, Panochori,
Rodopoli (3.1 m gate kept), Therisa, Paros T3, Sofia T3.

(Written by the towns agent; saved by the lead.)
