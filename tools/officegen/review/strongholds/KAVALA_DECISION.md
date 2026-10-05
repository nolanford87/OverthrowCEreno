# Kavala: your decision (a) and (b), both done

From REPORT_pass1_round3.md's question. The lead's call is both:
- **(a)** `tl.check()` no longer holds pieces out of the parts' boxes or off the plan for an office made of several
  pieces (the hospital). The in-game clip check judges pieces near it: anything that really runs into the building
  is reported, with its [x, y].
- **(b)** Kavala is re-probed out to **72 m** (the probe's reach now scales with the office's size;
  OTTOWN|Kavala|REACH|72). The height grid covers it too, and `tl.check()`'s distance limit follows the town's reach.
  The wings' outlines aren't in the probe; the in-game clips stand in for them.

So build your design: T3 H-barriers 1.5 m round the whole complex, T4 high walls along the south and west road edges
into the cliff, T5 the T3 ring in high walls.

Closure starts: Athira's walk now starts at (-3.3, -8.8) and Zaros' at (-5, 2.5), as you asked. Kavala's and
Pyrgos' still come from the search (Kavala's last start: (13.1, -6.1)).
