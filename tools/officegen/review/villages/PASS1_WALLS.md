# Pass 1: walls (start here)

The user has split the layout work into passes (see the end of tools/officegen/DESIGN_BRIEF.md, "The work is now
split into passes"). This replaces the round-by-round critiques for now. Pass 1 is walls only.

1. Read the new section of the brief closely: the tier-by-tier ladder for walls and the materials per tier.
2. Strip every tier of your drafts down to walls, H-barriers and sandbags (no guards, statics, towers, wire,
   hedgehogs, gates, flag or furniture), then rebuild each tier to the new ladder:
   - **T1:** empty.
   - **T2:** sandbags on the building.
   - **T3:** a tight, fully closed H-barrier ring with no opening.
   - **T4:** an outer high-wall perimeter round the T3 ring.
   - **T5:** both rings high-walled.
   Reuse your existing rings and your line-fitting code; most of the geometry carries over.
3. From your latest critique (round5.md), only the wall items still apply: pieces cutting into walls, buildings or the
   office, low old walls, gaps. Ignore its guard and static items for now.
4. Closure is now tested in the game: the engine's own path finding walks a man from the office's door to 8 points
   60 m out. It found a real gap in a ring the drafting scripts judged closed (Kore T3: out round the back of the
   house at about (-13, 13)). Tiers 3-5 must come back "closed: no way out".

Hand in as before: drafts and script pushed, then REPORT_pass1.md (the line audit per ring, the counts per tier).
The lead's in-game results come back as pass1_round1.md.
