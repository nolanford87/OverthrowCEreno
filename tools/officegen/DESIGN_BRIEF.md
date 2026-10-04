# Mayor's office defences: design brief for the layout designers

You design the occupier's defences round each town's mayor's office in Overthrow CE (an Arma 3 insurgency mod on
Altis). The player's resistance has to take the office to take the town; the occupier fortifies it in tiers as it
spends money. Your layouts are tested in the real game by the lead (Claude, on the user's PC): spawned tier by tier,
measured (placement, sight lines, fields of fire) and screenshotted, and you get the critique back to iterate.

The first drafts (tools/officegen/drafting/*.py, merged into tools/officegen/layouts/Altis.txt) were judged by the
user as: **not tactically sensible, wrong amounts per tier, and not looking like a real defence**. Start again from
the design up; reuse code from those scripts only where it helps.

## The tier ladder: nearly exponential (superseded for now by the passes below)
Each tier is a FULL snapshot that keeps everything of the tier before and adds to it.
- **Tier 1: a police presence.** 2-3 gendarmes, the office furniture (desk, chair, map board), the flag. Barely
  defended.
- **Tier 2: noticeable.** A clear step up: the doors are held, firing positions with real cover at the entrances,
  men at the upper windows. About 5-6 guards.
- **Tier 3: a large difference.** A defended compound: the approaches are covered, the open sides are closed
  (walls, H-barriers), the way in is controlled, 1-2 static weapons with real fields of fire, overwatch. About
  10-14 guards.
- **Tier 4: a fort.** A continuous perimeter (H-barrier/wall line closing the compound, using the neighbouring
  buildings as part of it), towers or bunkers at the corners, a controlled entry point (a chicane/gate), obstacle
  belts (wire, hedgehogs) on the approaches, 3-4 statics with interlocking fields of fire, posts on the roof/upper
  floor. About 18-24 guards.
- **Tier 5: an absolute stronghold, and a slaughterhouse once the player breaks in.** Everything of tier 4, plus an
  outer layer (manned checkpoints/roadblocks on every approach road, bunkers), mortar and AT, and the INSIDE of the
  office turned into a kill zone: every room held, sandbag positions inside covering the doors, stairs and corridors,
  an MG covering the entrance hall, barricades channelling anyone who gets in. About 30-40 guards.

A town only goes up to its own highest tier (its population bracket + 1: hamlets 2, small towns 3, towns 4, the
biggest 5), but every tier means the same thing everywhere: a hamlet's tier 2 is the same "noticeable" step.

## Make it a real defence
- Think like the occupier's engineer. Research it: Arma 3 compositions (Steam Workshop FOB / checkpoint /
  outpost compositions, Antistasi / Liberation / ALiVE base layouts, the vanilla showcase bases), and real doctrine
  (layered defence, interlocking and overlapping fields of fire, entry control points with serpentines,
  HESCO/H-barrier perimeters, overwatch, obstacle belts covered by fire, final protective lines, urban strongpoints).
  Use the web (search and fetch) freely; cite what you used in your report.
- Every fortification has a job: it covers a guard, blocks an approach a guard watches, or channels attackers into
  a kill zone. No decoration scatter.
- Guards stand 0.8-1.5 m behind their cover facing out over it, or at windows/doorways inside. Statics sit behind
  cover with a field of fire down an approach (a road, a gap, an open field), not into a wall.
- Use the real site: roads (where attackers come from, vehicles too), the gaps between buildings, neighbouring walls,
  high ground. The neighbouring buildings are part of the defence (they close sides of the compound; the occupier
  can put posts in gaps between them).
- Lines must be unbroken: walls, fences, H-barriers, concrete barriers, gates, wire and sandbags may (and should)
  overlap each other, the neighbouring buildings and existing walls slightly, so a perimeter is one continuous wall
  with no gaps a man can slip through. The checks only look at the middle of such pieces (0.6 m off each end, half
  their depth).
- Keep the office's way in: a defended, controlled route from the street to the main door (that's where the player
  has to fight through).
- Performance: at most ~200 things at tier 5, ~40 guards.

## Your tools (all in this repo)
- `tools/officegen/townlib.py`: read its docstrings. `tl.load()` gives every probed town (`tools/officegen/probes/
  Altis_towns.txt`: the office, its doors and floors, the buildings, walls, trees and rocks within 45 m, the roads
  within 60 m, a 2 m height grid). `tl.guard / tl.obj / tl.static` make items in the office's MODEL coordinates,
  `tl.check()` checks a draft, `tl.write()` writes it as OTLAYOUT lines (tools/officegen/layouts/drafts/<town>.txt).
  `python tools/officegen/townlib.py show "<town>"` prints a town's summary and map.
- The office's floor plans: `t.plan()` is an `officegen_lib.Building` (tools/officegen/officegen_lib.py) with a 1 m
  grid per floor level (`rows[level][y]`, '#' wall, '.' floor), `levels`, `positions`, and `windows` (real window
  openings: [x, y, level z, outward dir, width]) for interior and window posts.
- `tl.CLASSES`: the object classes with their footprint [length, depth]. You may ADD vanilla Arma 3 classes you
  find in your research (vanilla or its free platform data only, no creator DLC or mods), with a best-guess size; the
  in-game test reports every class that doesn't exist and every real bounding box, so guesses get corrected.
- Statics by role only (`tl.static`: hmg gmg at aa mortar); the game uses the occupier faction's own.
- Guards by role (`tl.guard`: gendarme rifleman autorifleman marksman at mg_gunner officer).
- The user's own hand-made layout: `python tools/officegen/townlib.py reference` (Aggelochori). It was made before
  this brief's ladder; treat it as a site-use example, not as the target.

## How you work and hand in
- Work on your own branch, made from `feat/office-town-layouts`: `layouts/<your group>`. Commit and push it.
- One drafting script for your group: `tools/officegen/drafting/<your group>.py`, writing every town of your group
  (tl.write). Don't edit other files except `tools/officegen/townlib.py` CLASSES (adding classes) and your drafts.
- Every draft must pass `tl.check()`.
- Your final message: per town and tier, the counts (things, guards, statics) and the design in a few lines; the
  research you drew on; what you'd want checked in the game.
- Critique comes back as `tools/officegen/review/<your group>/round<N>.md` on your branch (with screenshots beside it,
  top-down and street-level per tier, and measurements). Pull, read it, iterate, push, report again.

## The work is now split into passes (user, 2026-10-04): this replaces the ladder above

Each pass gets one part right on every tier before the next starts. The critiques judge only that pass.

1. **Walls** (NOW): the materials and the placement of the cover. Nothing else.
2. **Entrances and sentry**: cut sensible entries (gates, chicanes) into the finished walls, and pick strategic vantage
   points where a tower could go.
3. **Garrison**: guards and static weapons, placed against the final walls and towers.
4. **Obstacles and props**: wire, hedgehogs, the flag, the office furniture. Flavour may come later.

### Pass 1: walls
**In the drafts:** only walls, H-barriers and sandbags. Take everything else out of every tier for this pass: guards,
statics, towers, wire, hedgehogs, gates, the flag and the furniture. They come back in their own passes. Tiers are
still full snapshots, each keeping the tier below.

**The ladder:**
- **Tier 1: no cover at all.** The tier is empty in this pass.
- **Tier 2: sandbags on the main building**, so those inside can bunker down. Sandbag positions at the doors, the
  porch and the ground-floor windows, against the office itself. Nothing out in the yard. Material: sandbags only
  (`Land_BagFence_Long_F`, `_Short_F`, `_Round_F`, `_Corner_F`, `_End_F`).
- **Tier 3: a small but fully secured perimeter.** A tight ring round the office and its yard, tied into the
  neighbouring buildings and walls, with NO opening at all (the entrances come in pass 2). Material: H-barriers
  (`Land_HBarrier_1_F`, `_3_F`, `_5_F`, `Land_HBarrier_Big_F`), 1- or 2-high.
- **Tier 4: a sizeable outer perimeter of high walls**, giving cover all round, keeping the tier 3 ring as the inner
  line. A challenging take for the player. Material: high walls (`Land_Mil_WallBig_4m_F` and its corner,
  `Land_HBarrierWall4_F`, `Land_HBarrierWall6_F`, `Land_HBarrierWall_corner_F`, `Land_CncWall4_F`, `Land_CncWall1_F`),
  with H-barriers to fill.
- **Tier 5: an absolute walled garden, a Fort Knox.** Everything of tier 4, plus the inner ring raised to high walls
  too, so there are two complete high-walled rings. No face of either ring lower than 2-high.

**The rules for walls:**
- **Closed means closed in the game.** The in-game check walks a man (the engine's own route finding) from the
  office's door to 8 points 60 m out. `measurements.md` lists every way out with the gap's [x, y]. Tiers 3-5 must
  say "closed: no way out".
- **Existing walls count only if they're real barriers**, about 2 m or higher (city and stone walls of full height).
  Railings, pillars, pipe fences and low garden walls don't count: line them.
- **Pieces overlap only at their ends** (0.3-0.6 m into each other, a wall or a building), never mid-piece.
- **Don't close a main road.** A ring may cross a track or a dead-end lane.
- **Materials as listed per tier.** Other vanilla classes only if one of these can't do the job, and say why.
- **Upgrade the existing walls (tier 3 and up).** Where a real wall already runs along the line, H-barriers may stand
  ON or INTO it along its length, so the old wall looks reinforced. That's the one place a piece may overlap
  mid-piece. Say in the audit which pieces do it; the lead discounts those clips.
- **Tiers don't have to keep everything below.** Full snapshots still, but a tier may drop pieces of the tier
  below where that's better (e.g. tier 2's sandbags at a door that tier 3's ring makes pointless, or that would sit
  in the way).
- **Wall in the compound, not just the house.** The office usually stands in a small cluster of buildings (an annex,
  the neighbours across a yard or a lane). As the tiers rise the perimeter should take in that cluster as one
  compound: tier 3 tight round the office and what's attached to it, tier 4 out round the whole cluster, tier 5
  hardened.

**Hand-in for pass 1:** your report's line audit per ring (each gap's width, the run that closes it, what each end
ties into), and the counts per tier.
