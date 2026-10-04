# Overthrow CE (nolanford87/OverthrowCEreno)

Arma 3 mod written in SQF, built with HEMTT (see BUILDING.md: `hemtt release`, then copy into
`P:\OverthrowCEreno\releases\@Overthrow-Community-Edition`). The mod is pre-1.0: saves and test state don't
matter, so don't caveat changes about them.

## Mayor's office defence templates

- The templates in `addons/overthrow_main/functions/offices/templates/fn_officeTpl_*.sqf` are generated. Never
  edit them by hand: change `tools/officegen/officegen_lib.py` (the rules) or the SPECS in
  `tools/officegen/gen_templates.py` (per building), then run `python tools/officegen/gen_templates.py`.
- `python tools/officegen/gen_templates.py --check` checks and renders without writing; it must report 0 PROBLEM
  lines. `--only <class>` limits it to one building.
- The generator reads `tools/officegen/probe_offices.txt` (OTPROBE2 lines from the in-game probe).
  `tools/qa/merge-probe.py <rpt> <probe file>` merges a new probe run into it.
- Template format: five tiers, each a list of `[kind, what, [x,y,z], dir, extra]`. Kind is `guard`, `object` or
  `doorway` (a marker only, skipped by `fn_officeApplyTemplate.sqf`).
- The review rules are in the header of `officegen_lib.py` (door defences square with the doorway, a C-nest 3 m
  out from the main door, every fortification covers a guard, a guard 0.8 m behind cover, the tier 5 gate on the
  main door's axis, office furniture in the largest room, the tier 4 MG gunner on a balcony, window posts at real
  windows). Guard totals per tier are 2/4/6/8/10 for small buildings, 3-11 for medium and 4-12 for large.
- Reviewer feedback lines (OTFEEDBACK) are kept in `tools/officegen/feedback/`.

## QA

- The QA addon is `optionals/overthrow_qa`. `tools\qa\run-qa.ps1 [-Suite current|archive|offices|officereview]
  [-World Altis] [-Only "a,b"] [-Stop]` launches Arma, starts a new game and runs the suite.
- Results appear in the RPT as `OT_QA PASS/FAIL/MANUAL` and finish with `OT_QA ===== DONE`.
- `python tools/qa/rpt-lines.py [rpt] [--pass] [--probe] [-o file]` pulls just the START/DONE, FAIL, MANUAL and
  OTFEEDBACK lines out of an RPT (the newest one when none is given): send that instead of the whole RPT.
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
