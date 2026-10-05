# Pass 2a for the towns: rolled back, gates cut by the lead

The user rolled the ten towns back to their reviewed walls: the drafts under `tools/officegen/layouts/drafts/` and
`drafting/towns_pass2a.py` re-laid whole wall runs round the gates, which the user didn't want. They are superseded:
don't build on them.

What stands now (`tl.baseline(town)`, from `tools/officegen/layouts/Altis.txt`): the user's walls, with the gates
cut in by `tools/officegen/cut_gates.py` at the positions this branch's markers chose (only the pieces across each
opening taken out, their leftover length refilled with same-kind pieces), open vehicle gates in them
(`add_gates.py`), and the user's own patches from the review.

The rule from now on (the office-walls skill): a later pass changes only the pieces right at its feature, and a
way out is closed by adding pieces only.
