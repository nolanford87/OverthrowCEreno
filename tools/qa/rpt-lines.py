"""
Prints the lines of an Arma RPT worth sending back from a QA run: the suite START/DONE lines, every
OT_QA FAIL and MANUAL, and the OTFEEDBACK lines (the template review's votes). The rest (engine and
mod noise, passes) is left out.

Usage: python tools/qa/rpt-lines.py [rpt] [--pass] [--probe] [-o out.txt]
    rpt      the RPT file; the newest one in %LOCALAPPDATA%\\Arma 3 when left out
    --pass   also the OT_QA PASS lines
    --probe  also the OTPROBE2 lines (the building probe's data, a lot of them)
    -o FILE  write to FILE instead of the screen
"""
import glob
import os
import re
import sys

args = sys.argv[1:]
want_pass = "--pass" in args
want_probe = "--probe" in args
out = None
if "-o" in args:
    out = args[args.index("-o") + 1]
paths = [a for a in args if not a.startswith("-") and a != out]
if paths:
    rpt = paths[0]
else:
    found = glob.glob(os.path.join(os.environ.get("LOCALAPPDATA", ""), "Arma 3", "*.rpt"))
    if not found:
        sys.exit("no RPT given and none found in %LOCALAPPDATA%\\Arma 3")
    rpt = max(found, key=os.path.getmtime)

keep = ["OT_QA ===== ", "OT_QA FAIL", "OT_QA MANUAL", "OTFEEDBACK|"]
if want_pass:
    keep.append("OT_QA PASS")
if want_probe:
    keep.append("OTPROBE2|")

lines = []
for line in open(rpt, encoding="utf-8", errors="replace"):
    m = re.search(r'"((?:OT_QA|OTFEEDBACK|OTPROBE2).*)"\s*$', line)
    if m and m.group(1).startswith(tuple(keep)):
        lines.append(line.rstrip("\r\n"))

text = "\n".join(lines) + "\n"
if out:
    open(out, "w", encoding="utf-8").write(text)
    print(f"{len(lines)} lines from {rpt} -> {out}")
else:
    print(f"# {rpt}")
    print(text, end="")
