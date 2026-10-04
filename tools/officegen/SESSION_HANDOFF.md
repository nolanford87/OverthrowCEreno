# Session handoff: mayor's office templates (cloud session, 2026-10-04)

For a local Claude session picking this up. Branch: `claude/affectionate-hopper-1trtxv` (head `0e82e10`). It
contains everything on `claude/busy-shannon-k8hpzi` (the earlier cloud session, ending `04e3d17`) plus the
commits below. No PR is open; `master` is untouched. Delete this file once read; it is not part of the mod.

## State

- Last in-game run (`-Suite current -World Altis`, build 2.7.0.0): **250 passed, 0 failed, 0 manual**.
- `python tools/officegen/gen_templates.py --check` reports 0 PROBLEM lines. The eight templates in
  `addons/overthrow_main/functions/offices/templates/` are regenerated from it (never edit them by hand).
- The OTFEEDBACK lines in that run are the test suite's own placeholder votes ("the desk floats"). There is no
  real reviewer feedback for the current templates yet.

## What changed this session (all in `tools/officegen/officegen_lib.py` unless noted)

1. `04e3d17` (earlier session): the tier 5 marksman no longer loses his turn to the gate's AT man.
2. `7e2162a` tier 3: `nest_wings` adds two `Land_HBarrier_3_F` either side of the main-door nest; the first tier 3
   guard is a sandbagged window post where there's room. Also added `CLAUDE.md`.
3. `1ddae5b`, `4b358a7` tier 5 "reinforced rooms": `reinforce_office` puts a pair of short bags 2 m inside each door
   within 7 m of the desk, towards the desk, square with the door. The door axis comes from the probe's fine
   `DOORGRID` via `Building.doorway(i, d)` (axis with a gap of 2 m or less and the wall line at the door point). Bags
   near a guard are skipped (rule 4). The Stone House has no door points, so it gets none; the Hospital's doors are
   all beyond 7 m of its desk.
4. `0129fa2` fixes for the first full in-game run (11 failures):
   - `SIZES`: H-barrier depths were 1.2 m; the game measures about 1.76 m (HBarrier_3 and _5) and about 1.56 m
     (HBarrier_1). `gate_guard` had 1.2 hardcoded; it now uses `size_of`.
   - `GATE_OUT` 19 to 17, and `check_tiers` now uses the in-game perimeter (bounding box + 18 m).
   - Map board offset 0.35 to 0.25 (it was inside Big_01's wall).
   - `optionals/overthrow_qa/functions/fn_testsOfficeTemplates.sqf`: the rule 4 check skips cover more than 1.5 m
     away vertically (a marksman upstairs was measured against a sandbag a storey below). The Python check
     already did this.
5. `05fb62e`:
   - `ring_rect` widens the ring so the 6 m gate gap fits on the main door's axis (Big_02's gate was clamped 0.37 m
     off it).
   - `addons/overthrow_main/functions/offices/fn_officeApplyTemplate.sqf`: items flagged `gate` get
     `setVectorUp [0,0,1]` like flags. This was a guess (a gate tilted to the slope landed about 0.4 m off its
     mark in Offices_01); the run after it passed, but it is unproven as the cause.
6. `0e82e10` `tools/qa/rpt-lines.py`: prints only START/DONE, FAIL, MANUAL and OTFEEDBACK lines from an RPT
   (`--pass`, `--probe`, `-o file`). Prefer it to pasting a whole RPT.

## Findings worth knowing

- The probe's coarse `ROW` grid has almost no `#` walls around interior doors (rooms merge through them), so
  `Building.rooms()` rooms are connected areas, not single rooms. The fine `DOORGRID` is the reliable wall data.
- The tier 4 MG gunner "unbagged" gap is moot on the eight Altis buildings: the cell in front of him is air past a
  balcony rail, so there is nothing to bag. I tried a fallback for floor cells and reverted it.
- Still open from the spec: the C-nest on every door or only the main one, the upgrade catalogue, resistance
  fortification prices, HVT rewards, which map comes next. Also: Shop 01 and Research HQ have no windows (no
  window posts), and the P9 network-traffic audit is unstarted.

## To test locally

```powershell
git fetch origin claude/affectionate-hopper-1trtxv
git checkout claude/affectionate-hopper-1trtxv
# hemtt release, copy into P:\OverthrowCEreno\releases\@Overthrow-Community-Edition
powershell -File tools\qa\run-qa.ps1 -Suite current -World Altis
python tools\qa\rpt-lines.py -o current.txt
# then the real review walk, flagging anything wrong with "Issue:" actions
powershell -File tools\qa\run-qa.ps1 -Suite officereview -World Altis
python tools\qa\rpt-lines.py -o review.txt
```

Look especially at the tier 3 barrier wings, the tier 5 door bags and the gate guards.

## Conventions

See `CLAUDE.md`. The user prefers the least new code, no caveats about saves (pre-1.0), manual in-game checks
added silently, and branches merged with "Merge <branch>" commits. Don't send credentials or tokens anywhere.
