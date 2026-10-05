# Pass 2a for the towns

Your towns: Agios Dionysios, Chalkeia, Charkia, Kalochori, Neochori, Panochori, Paros, Rodopoli, Sofia, Therisa.

## The user's review of your pass 1
- Neochori 9/10 ("really cool") and Paros 9/10 ("cool design"): the references.
- Kalochori 7/10 ("interesting"): give more room to move inside the walls at T3-T4.
- Chalkeia: T3 4/10, T4 6/10. It was also the one town still getting out in the last check: fix that while cutting its gates.
- Agios Dionysios 5/10: "a large gap in the wall". Closed to a man, but visually disjointed: make the line read as one wall while you are there.
- Molos is out (its office moved to the chapel; the user comes back to it later). Do not touch it.

### Pass 2a: where the gates go
Pass 1's walls are done and reviewed by the user in the game: **build on the reviewed layouts** (`tl.baseline(town)`,
your town's tiers exactly as the user left them, map objects they removed included), never regenerate from your
pass 1 script. Pass 2 comes in steps, each reviewed before the next:
- **2a (this one): where the gates go**, cut into the walls with a plain gate in each.
- 2b: the entrance made to look right (the gate's surroundings, its look, the approach).
- 2c: lookouts and towers, per tier.

Still no guards, statics, wire, hedgehogs, flags or furniture.

**The gates (T3 and up):**
- **One gate per ring; two only for a real tactical reason.** Fewer is better: one way in is one place to defend.
  A second gate must earn its place (e.g. a back gate onto a second road the occupier's vehicles would use, or a
  sally port that lets defenders flank a gate under attack). Give the reason in your report.
- **Where:** where the occupier would come and go: facing the main approach road, leading to the office's main
  door. Not where the player's best approach is.
- **T4: the outer ring's gate offset from the inner ring's**, not in line with it, so anyone coming through crosses
  the ground between the rings under the walls. T5 keeps T4's gate positions.
- **A tier keeps the gates of the tier below** where its ring stands, unless moving one is a clear improvement.
- **The opening:** take pieces out of the line (or shorten them) to make a gap 3-4 m wide where it faces a road (a
  vehicle's width), a man's width (about 1.5 m) elsewhere. Leave it open, no gate piece yet (2b does the look),
  and mark it with **`tl.gate(town, x, y, width, mdir)`** at the gap's middle: a marker the game makes nothing
  for, which tells the check (and later passes) where your gates are. Re-fit the line's ends at the gap so they
  end cleanly (no half piece hanging into the opening).
- **Closure after cutting:** the in-game check walks a man out from inside the office. It reports each way out
  as "through the gate at [x, y] (meant)" or "NOT through a gate". Every tier 3+ must have only meant ways out,
  and at least one (a ring whose gate no man can walk through is wrong too).
- **Tools:** `tl.baseline(town)` gives the reviewed tiers to start from; `tl.write()` checks and writes as before.
  Read the `office-walls` skill: its rules still hold for the walls you touch.

**From the user's pass 1 review (keep these):**
- References: Neochori and Paros (9/10), Kore (8.5, a good tier 3), Gravia (7, a cramped site done well).
- Room to move inside the walls (T3-T5); a wall reads as one line to the eye, not just closed to a man's path.
- **Not in this pass:** Molos and Pyrgos (set aside for later). Kavala's west slope stays open as a deliberate
  weak spot: don't wall it up, and don't put a gate there.

**Hand-in:**
- Drafts and script pushed.
- REPORT_pass2a.md with, per town and tier: each gate's place (model [x, y]), its width, what it faces and why
  there, and the reason for any second gate; the pieces removed to cut it.

When done: commit, push, write REPORT_pass2a.md next to this file, and stop. The lead runs the in-game check and sends you its results.
