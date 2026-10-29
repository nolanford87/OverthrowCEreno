# Overthrow CE (nolanford87/OverthrowCEreno)

Arma 3 mod written in SQF, built with HEMTT (see BUILDING.md: `hemtt release`, then copy into
`P:\OverthrowCEreno\releases\@Overthrow-Community-Edition`). The mod is pre-1.0: saves and test state don't
matter, so don't caveat changes about them.

## Mayor's office layouts

- Each town's office is a hand-authored layout: per defence tier, a full snapshot of everything standing there, in
  world coordinates. The data is `addons/overthrow_main/functions/offices/layouts/fn_officeLayouts_<world>.sqf`
  (read by `OT_fnc_officeLayout`) and the compound areas `.../offices/compounds/fn_officeCompounds_<world>.sqf`.
  Never edit those by hand: `tools/officegen/merge_layouts.py` writes them from `tools/officegen/layouts/<world>.txt`
  and `merge_compounds.py` from `tools/officegen/compounds/<world>.txt`.
- Drafting and generating them is in `tools/officegen` (`townlib.py`, `compound_gen.py` and the other `*_gen.py`,
  per-town scripts in `drafting/`); the walls skill is `.claude/skills/office-walls`. In the game, the `townlayout`
  suite (the layout editor) and the `compounds` suite (the area editor) edit them with Zeus.
- The office buildings' floor plans come from `tools/officegen/probe_offices.txt` (OTPROBE2 lines from the
  `offices` probe; `tools/qa/merge-probe.py <rpt> <probe file>` merges a new run into it), read by
  `tools/officegen/officegen_lib.py`. Their real entrances are in `optionals/overthrow_qa/functions/fn_officeDoorways.sqf`.

## QA

- The QA addon is `optionals/overthrow_qa`. `tools\qa\run-qa.ps1 [-Suite current|archive|townlayout|compounds|layoutcheck|...]
  [-World Altis] [-Only "a,b"] [-Stop]` launches Arma, starts a new game and runs the suite.
- Results appear in the RPT as `OT_QA PASS/FAIL/MANUAL` and finish with `OT_QA ===== DONE`.
- `python tools/qa/rpt-lines.py [rpt] [--pass] [--probe] [-o file]` pulls just the START/DONE, FAIL and MANUAL
  lines out of an RPT (the newest one when none is given): send that instead of the whole RPT.
- The suite registry is in `optionals/overthrow_qa/functions/fn_run.sqf`.
- Passed tests are archived. Manual in-game checks are deferred to a pure-QA phase: add new ones silently and
  don't list them in reports.

## Conventions

- Write the least new code: reuse what exists. Never trim validation, save safety, MP locality or QA tests.
- No `//` comments inside addActionLoop strings: HEMTT misses it.
- Branches are merged with "Merge <branch>" commits. Don't create pull requests unless asked, and don't touch
  `master` directly.
- Design decisions already made (don't re-propose): solo-first (no P10), stealth captures are kept, no G6/G10.
  The mayor's-office spec supersedes G8.
