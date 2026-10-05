---
name: office-walls
description: Design the walls round a town's mayor's office in Overthrow CE (pass 1 of the office layouts) - tier-by-tier rings of sandbags, H-barriers and high walls that close the office's compound, drafted with tools/officegen/townlib.py and checked in the game for closure and clipping. Use when drafting or fixing an office layout's walls for any town or map.
---

# Walls round a mayor's office

Each town's mayor's office (Overthrow CE, Arma 3) is fortified by the occupier in tiers 1-5. Its layout is data: per
tier, a full snapshot of every piece in world coordinates, written by a Python drafting script as OTLAYOUT lines,
merged into the mod and tested in the real game by the lead. This skill is **pass 1: the walls**. The later passes
are 2 (entrances and towers), 3 (garrison), and 4 (obstacles and props). Leave their parts out until then.

Read first: `CLAUDE.md`, `tools/officegen/DESIGN_BRIEF.md` (its passes section), and the docstrings of
`tools/officegen/townlib.py`.

## The ladder (the user's, fixed)
| Tier | What | Materials |
|---|---|---|
| 1 | No cover at all. The tier is empty. | - |
| 2 | Sandbags against the main building only, so those inside can bunker down: doors, porch, ground-floor windows. Nothing in the yard. | `Land_BagFence_Long_F` `_Short_F` `_Round_F` `_Corner_F` `_End_F` |
| 3 | A small but **fully closed** ring tight round the office and what's attached to it. No opening at all (entrances come in pass 2). | H-barriers: `Land_HBarrier_1_F` `_3_F` `_5_F`, `Land_HBarrier_Big_F`; 1- or 2-high |
| 4 | A **sizeable outer perimeter of high walls** round the whole compound (its yards and the cluster of buildings round the office). Keep the T3 ring as the inner line. A hard take for the player. | `Land_Mil_WallBig_4m_F` (+ corner), `Land_HBarrierWall4_F` `Wall6_F` `Wall_corner_F`, `Land_CncWall4_F` `CncWall1_F`; H-barriers to fill |
| 5 | An absolute walled garden, a Fort Knox: T4 plus the T3 ring raised to high walls too, so there are two complete high-walled rings with ground between them. | as T4 |

- A town only goes up to its own top tier: its population bracket + 1, as the probe gives it
  (`OTTOWN|town|HEAD|...|population|bracket|cap`). Populations are rolled anew each game, so the bracket is
  **locked at the probe's** (`merge_layouts.py` writes it into the data, `OT_fnc_officeBracket` reads it): author up
  to the probe's cap, no further.
- **At T4 every wall is upgraded to high walls**: the perimeter, and the existing walls the ring ties into (raised or
  lined with high walls), not only the new outer line. (The user's rule, set after Altis.)
- Snapshots are full, but a tier **may drop pieces of the one below** (e.g. T2's door bags where the T3 ring stands).
  `tl.check()` allows it.

## The rules
- **Gates (pass 2) on future maps: agents choose, a script cuts.** On Altis the towns agent re-laid whole wall runs
  round its gates and the user's reviewed layouts had to be rolled back. So the agent only places `tl.gate()`
  markers (where, how wide, why), and the lead cuts them with `tools/officegen/cut_gates.py` (it takes out only the
  pieces across each opening and refills their leftover length with same-kind pieces), then `add_gates.py` puts in
  the open gates. Ways out the in-game check still finds are marked for the user with a red arrow
  (`Sign_Arrow_Large_F`) in that tier, not fixed by moving their walls.
- **Later passes change only what they're for (the user, after pass 2a).** A pass on top of reviewed walls (gates,
  towers) removes, shortens or moves only the pieces right at its feature: the opening and the piece either side,
  within about 6 m. Never re-lay a run "evenly", move a wall over, or tidy joints elsewhere. A way out found later is
  closed by adding pieces only, tied into the user's.
- **Room to move inside the walls.** From T3 to T5, don't hug the building: take up space so the defenders (and
  the player who breaks in) can move round inside the rings easily. A tight ring that leaves only narrow slots is
  worse than a wider one. (The user, after reviewing Altis.)
- **A wall reads as one line to the eye.** Closed isn't enough: a ring the path check passes can still look
  disjointed (a large visible gap covered only by something behind it). Close the line visibly.
- **Closed means closed in the game.** The lead's check walks a man (the engine's own path finding) from inside the
  office to 8 points 60 m out. Every tier 3+ must come back "closed: no way out".
- **Only real barriers close a line.** These count:
  - full-height city walls (about 2 m or more);
  - solid buildings' real walls;
  - cliffs.

  These don't count:
  - railings, pillars, pipe and net fences, low garden or stone field walls, tin walls;
  - damaged walls and ruins, boulders;
  - **any building a man can walk through**: a neighbour with doors on both sides, a shop, an open ground floor.

  Line the ones that don't count, or go round them.
- **Pieces overlap only at their ends**: 0.3-0.6 m into each other, a wall or a building. Never mid-piece. The one
  exception is upgrading an existing wall (T3+): H-barriers may stand along or on a real wall to reinforce it. Say
  which pieces do that in the audit.
- **A map object in the way can be removed** (a fence, a low or ruined wall, a shed, a tree, junk):
  `tl.hide(town, x, y)` makes a "hide" item for the probed object nearest model (x, y). The game hides it while
  the tier stands, and `tl.check()` and the in-game checks treat it as gone. An object removed at a tier stays
  removed at every tier above it. Don't remove buildings people live in, and say why in the audit. The user's own
  layouts may already remove some (their "hide" items): those objects are gone, so don't tie a line into them.
- **Every door of the office must open inside the ring.** A line may end on the office's own wall only on a face with
  no door, or the man walks in one door and out another.
- **Don't close a main road.** A line may stand on a road's edge or cross a track or a dead-end lane.
- **Stack a second H-barrier layer only on a piece of the same line** (or use the 2-high classes). A piece with
  nothing under it floats.

## Pitfalls from pass 1 (each cost a round)
- **The probe's boxes are bigger than many buildings** (House_Big_02's runs ±12 m, its walls -6.5..7.5). A line that
  ends on a box edge stops short of the real wall, and the man walks round the end. Where the floor plan exists
  (`tools/officegen/probe_offices.txt`), use the real walls; otherwise overlap well into the building.
- **Steps and porches leak.** A line whose END stands over a building's steps lets a man walk down them. Put a
  piece's MIDDLE over the steps, or a piece on the steps.
- **Narrow slots between two buildings** (the office and a neighbour) are a way through unless filled.
- **Routes go through houses.** A neighbour used as part of a ring is only a wall if it has no door on the
  outside.
- **Pieces on some roads are ignored by the game's path finding** (Kore: 2-high pieces on the road east of the house
  were walked straight through). If the route goes through pieces the top view shows standing, say so; the lead
  accepts the ring by eye.
- **Big offices**: an office of several pieces (Kavala's hospital with its wings) has boxes and a plan far past the
  real building. `tl.check()` lets pieces stand in them and the in-game clip check judges them. Its probe reaches
  farther (`OTTOWN|town|REACH|m`).
- **Tall offices can't be walked** (`Land_Offices_01`, Pyrgos): closure there rests on your own audit.

## How to work
1. `tl.load()["<town>"]` gives the probed site: the office, its doors and floors, buildings, walls, trees and rocks
   within the reach, roads, and a 2 m height grid. `python tools/officegen/townlib.py show "<town>"` prints a map.
2. Draft in your group's script under `tools/officegen/drafting/`. Build items with `tl.obj(town, cls, x, y,
   mdir=...)` in the office's MODEL coordinates (x right, y forward of the office). Write with `tl.write(town,
   tiers)`, which runs `tl.check()` first and refuses a draft with problems.
3. Fit every line to the gap it closes:
   - find what each end ties into, measure the gap, and lay pieces by their measured lengths (`tl.MEASURED`) with
     0.3-0.6 m joints;
   - print an audit per ring: each gap's width, the run that closes it, the pieces, the joints, and what each end
     ties into.
4. Check closure yourself before handing in: a flood fill from inside the office for a 0.5 m man, treating only
   real barriers as blocking. Worked versions to reuse (on the `layouts/towns`, `layouts/villages` and
   `layouts/strongholds` branches), each written against the game's results:
   - `closure()` and the line-fitting `fill()` method in `drafting/strongholds.py`;
   - `closed_audit()` in `drafting/villages.py`;
   - `Site.game_rays()` in `drafting/villages.py`, a copy of the game's clip test.
5. Hand in: commit the script and drafts, push, then `tools/officegen/review/<group>/REPORT_*.md` with the counts per
   tier and the audit. Stop.

## Reading the lead's results
`tools/officegen/review/<group>/<round>/measurements.md` and screenshots, per tier:
- **ways out**, each with a route from inside the office (every ~5 m) and a "gap" marker. The marker is only where
  the route last passed within 3 m of a piece; **the crossing is where the route goes from inside your ring to
  outside**, so follow the route. "closed" means no way out. "unknown (n of 8 not computed)" with no ways out counts
  as closed.
- **clips**: a piece's middle in a building, wall, rock or the office, with the piece's [x, y].
- **floating**: a piece with a gap under it (a stacked piece with nothing below).
- The closure walk starts at `OTPATHSTART`. If that's outside your ring (behind the house, inside a neighbour's
  box), every route is false. Say so and ask for a start inside; the lead can fix it per town.
