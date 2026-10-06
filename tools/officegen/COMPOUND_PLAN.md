# Occupier compounds: the plan

The mayor's office becomes the **occupier compound**: not one building with a wall round it, but a piece of the
town (a block, its yards and buildings) the occupier has taken over and walled in. Tiers 1 and 2 are untouched by
this. Tiers 3, 4 and 5 are compounds, and **each tier expands the compound**.

## The two editors (the names used everywhere)
- **Compound editor** (QA suite `compounds`): shaping the virtual border lines of each tier's compound area
  (coloured arrows at the vertices, lines along the edges).
- **Layout editor** (QA suite `townlayout`): reviewing and editing the actual objects placed at each tier (walls,
  gates, sandbags...).

## What a compound is
- **Its area, per tier:** a polygon of vertices (world x, y). They're nested: T3 inside T4 inside T5. A town only has
  the tiers it can reach (villages T3, towns T3-T4, strongholds T3-T5).
- **Its headquarters (HQ):** one building inside, usually today's office. The layouts are stored against it, and
  it's the capture's hold point.
- **Its walls follow the area's edges.** Where an existing wall, fence or yard boundary lies along an edge, it's
  hidden and our **2-high H-barrier** goes up on its line, so it looks like the occupier took the place over and
  hardened it. Elsewhere the edge gets new 2-high H-barrier. Buildings standing on an edge are part of the wall only
  where they have no door to the outside; otherwise the line goes round them.
- **Gates** where roads or tracks cross an edge: at least 3.5 m, a road's width on a road, open vehicle gates.
- **Capture works as today, in the compound's area:** at stability 0, clear the area (the current tier's polygon)
  and hold the HQ.

## Phase 1: designate every compound (all 25)
Every place with a tier 3 or above: 4 strongholds (Kavala, Athira, Zaros, Pyrgos), 11 towns (Agios Dionysios,
Chalkeia, Charkia, Kalochori, Molos, Neochori, Panochori, Paros, Rodopoli, Sofia, Therisa), 10 villages (Alikampos,
Dorida, Gravia, Kore, Lakka, Neri, Poliakko, Selakano, Stavros, Telos). Hamlets are out (they top out at T2).

1. **Block probe** (one Arma run, the QA addon): for each town, out to about 150 m from today's office, the roads
   (every segment, its width), every building's footprint and doors, the walls and fences, and the ground.
2. **Proposals, offline (the lead):** per town and tier, a polygon:
   - T5 / the town's top tier: the city block today's office stands in (bounded by roads), trimmed to a size for
     its group along building faces;
   - each lower tier a smaller area inside it, round the HQ and its yard;
   - edges beside roads, 1-2 m off them, never on them (the AI walks through pieces on roads);
   - 6-12 vertices, on building corners, wall ends and road verges where possible;
   - the HQ, and gate candidates where roads meet an edge.
3. **Review in the compound editor (the user):** each town's border lines:
   - each vertex an editable marker (a coloured arrow per tier: T3 green, T4 yellow, T5 red) to drag with Zeus;
   - the edges drawn as lines in the 3D view and on the map;
   - actions: add a vertex (splits the nearest edge), delete one, save the town's compounds, confirm and go on.

   Saves go to `tools/officegen/compounds/<world>.txt` (merged from the RPT like the layouts) and the mod's data.

Strongholds first (Pyrgos's corporate park is nearly a ready-made compound), then towns, then villages; review in
batches by group.

## Phase 2: build the layouts (strongholds, then towns, then villages)
1. **Generate (the lead's scripts, not agents piece by piece):** from each compound's polygons:
   - the existing walls and fences on each edge hidden and rebuilt as 2-high H-barrier on their line; the rest of
     the edge new 2-high H-barrier, measured joints, every pair on the ground;
   - lines tied into buildings without outside doors, round the others;
   - gates where roads cross, map junk in the way hidden;
   - T1-T2 kept as they are.
2. **Check in the game** before the user sees it: the layout check in combat, walking in and out (helper agents
   deleted, so long runs are trustworthy); every way in and out through a gate.
3. **Review in the layout editor (the user):** free edits; anything a script or agent does afterwards changes only what
   it's for, and leaks are closed by adding pieces, never by moving the user's.

Each group goes through 1-3 before the next starts.

## The rules learnt so far (keep them)
- No `Land_HBarrier_Big_F` (AI walks through it); stacked H-barrier pieces, each pair on the ground.
- No barrier on a road: a gate there instead. Relaxed (safe-mode) AI walks through pieces on roads; office AI
  isn't left in safe mode (pass 3).
- Gates at least 3.5 m (the path finding can't use narrower).
- A map object removed at a tier stays removed above it.
- Later steps touch only their feature; leaks are closed by adding pieces.

## Open questions
- T4/T5 walls: 2-high H-barrier throughout, or high walls (Mil) for the T5 perimeter?
- The existing pass 1-2 layouts (T3-T5): replaced by the generated compounds, with the user's favourite touches
  carried over by hand in review?
