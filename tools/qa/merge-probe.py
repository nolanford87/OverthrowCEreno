"""
Merges office probe results (OTPROBE2 lines) from an RPT into the saved probe data: the classes in the
new run replace their old lines, everything else is kept. Used after a run-qa.ps1 -Suite offices -Only.

Usage: python tools/qa/merge-probe.py <rpt> <saved probe file>
"""
import re
import sys

rpt, saved = sys.argv[1], sys.argv[2]
new = []
for line in open(rpt, encoding="utf-8", errors="replace"):
    m = re.search(r'"(OTPROBE2\|.*)"\s*$', line)
    if m:
        new.append(m.group(1) + "\n")
probed = {l.split("|")[2] for l in new if l.split("|")[1] in ("START", "PARTS", "MISSING", "NOPARTS")}
try:
    old = open(saved, encoding="utf-8").readlines()
except FileNotFoundError:
    old = []
kept = [l for l in old if len(l.split("|")) < 3 or l.split("|")[2] not in probed]
open(saved, "w", encoding="utf-8").writelines(kept + new)
print(f"merged {len(probed)} classes: {sorted(probed)}; {len(kept)} old lines kept")
