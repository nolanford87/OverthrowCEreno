"""
Turns a "layoutcheck" QA run (OTCHECK / OTCLASS lines in the RPT, OTL_*.png in the profile's Screenshots folder)
into review material for the layout designers: per group, tools/officegen/review/<group>/round<N>/measurements.md
and the screenshots shrunk to JPEGs beside it. The groups are in tools/officegen/review/groups.json
({group: [town, ...]}). The written critique (round<N>.md) is added by hand.

Usage (from the repository root):
    python tools/qa/layout-review.py --watch            (in the background while the check runs: shrinks and
                                                         moves the screenshots as they come, until Arma closes)
    python tools/qa/layout-review.py <round> [rpt] [--group name] [--keep]
        rpt      the RPT; the newest one when left out
        --group  only this group
        --keep   leave the PNGs in the Screenshots folder (they're deleted once copied by default)
"""
import ctypes
import ctypes.wintypes
import glob
import json
import os
import re
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REVIEW = os.path.join(ROOT, "tools", "officegen", "review")


def documents():
    buf = ctypes.create_unicode_buffer(ctypes.wintypes.MAX_PATH)
    ctypes.windll.shell32.SHGetFolderPathW(None, 5, None, 0, buf)  # CSIDL_PERSONAL: Documents (may be redirected)
    return buf.value


INCOMING = os.path.join(REVIEW, "_incoming")


def watch():
    """While Arma runs a layout check: each OTL_*.png it writes, once it's finished, shrunk to a JPEG in
    tools/officegen/review/_incoming and the PNG deleted (Arma stops saving past 250 MB in its Screenshots folder,
    and its PNGs are about 23 MB each)."""
    import subprocess
    import time
    shots = os.path.join(documents(), "Arma 3", "Screenshots")
    os.makedirs(INCOMING, exist_ok=True)
    idle = 0
    while True:
        done = 0
        for src in glob.glob(os.path.join(shots, "OTL_*.png")):
            if time.time() - os.path.getmtime(src) < 2:
                continue
            try:
                im = Image.open(src).convert("RGB")
                im.thumbnail((1280, 1280))
                im.save(os.path.join(INCOMING, os.path.basename(src)[4:-4] + ".jpg"), "JPEG", quality=72)
                im.close()
                os.remove(src)
                done += 1
            except OSError:
                pass
        running = "arma3_x64.exe" in subprocess.run(["tasklist"], capture_output=True, text=True).stdout.lower()
        idle = 0 if (done or running) else idle + 1
        if idle >= 3:
            break
        time.sleep(3)


def main(argv):
    if "--watch" in argv:
        return watch()
    only = argv[argv.index("--group") + 1] if "--group" in argv else None
    args = [a for a in argv if not a.startswith("--") and a != only]
    rnd = int(args[0])
    rpt = args[1] if len(args) > 1 else max(glob.glob(os.path.join(os.environ["LOCALAPPDATA"], "Arma 3", "*.rpt")), key=os.path.getmtime)
    groups = json.load(open(os.path.join(REVIEW, "groups.json"), encoding="utf-8"))
    checks, classes, bpos = {}, {}, {}
    for line in open(rpt, encoding="utf-8", errors="replace"):
        m = re.search(r'"(OT(CHECK|CLASS|BPOS)\|.*)"\s*$', line)
        if not m:
            continue
        f = m.group(1).replace('""', '"').split("|")
        if f[0] == "OTBPOS":
            bpos[f[1]] = f[2]
        elif f[0] == "OTCHECK":
            checks.setdefault(f[1], {})[int(f[2])] = f[3:]
        else:
            classes[f[1]] = f[2]
    shots = os.path.join(documents(), "Arma 3", "Screenshots")
    for group, towns in groups.items():
        if only and group != only:
            continue
        mine = [t for t in towns if t in checks]
        if not mine:
            continue
        out = os.path.join(REVIEW, group, f"round{rnd}")
        os.makedirs(out, exist_ok=True)
        md = [f"# {group}: round {rnd} measurements (in-game, Altis)", "",
              "Per tier: items in the layout / guards / props / statics / items not made (class missing); then the problems found.",
              "clips = a building, wall, rock or the office's walls runs through it; floating = gap under it (m); moved = a guard pushed",
              "more than 1 m off his post (stuck in geometry); blind = a guard's view ends within 4 m (facing a wall); blocked = a",
              "static's field of fire ends within 15 m; view = the guards' median clear view (m). A flagged item's [x, y] is where",
              "it stood in the office's model coordinates (your drafts' own). Screenshots beside this file:",
              "<town>_T<tier>_top.jpg (from 48 m above, north up) and <town>_T<tier>_street.jpg (from 35 m out on the street side, 20 m up).", ""]
        for town in mine:
            md.append(f"## {town}")
            for tier in sorted(checks[town]):
                items, guards, props, statics, missing, clips, floating, moved, blind, blocked, view = checks[town][tier]
                md.append(f"- **Tier {tier}**: {items} items / {guards} guards / {props} props / {statics} statics / {missing} missing; median view {view} m")
                for name, val in (("clips", clips), ("floating", floating), ("moved", moved), ("blind", blind), ("blocked", blocked)):
                    if val not in ("[]", ""):
                        md.append(f"  - {name}: {val}")
                for view_name in ("top", "street"):
                    name = f"{'_'.join(town.split(' '))}_T{tier}_{view_name}"
                    dst = os.path.join(out, name + ".jpg")
                    staged = os.path.join(INCOMING, name + ".jpg")
                    src = os.path.join(shots, f"OTL_{name}.png")
                    if os.path.exists(staged):
                        os.replace(staged, dst)
                    elif os.path.exists(src):
                        im = Image.open(src).convert("RGB")
                        im.thumbnail((1280, 1280))
                        im.save(dst, "JPEG", quality=72)
                        if "--keep" not in argv:
                            os.remove(src)
            md.append("")
        used = sorted(c for c in classes)
        md += ["## Real sizes of the classes used ([length, depth, height] m, boundingBoxReal)", ""] + [f"- {c}: {classes[c]}" for c in used]
        if bpos:
            md += ["", "## Where a man stands on a placed object (its building positions, MODEL coordinates [x, y, z] from its origin)",
                   "Put a tower's or bunker's guard exactly there (turned with the object) instead of guessing a height.", ""]
            md += [f"- {c}: {bpos[c]}" for c in sorted(bpos)]
        open(os.path.join(out, "measurements.md"), "w", encoding="utf-8", newline="\n").write("\n".join(md) + "\n")
        print(f"{group}: {len(mine)} towns -> {os.path.relpath(out, ROOT)}")


if __name__ == "__main__":
    main(sys.argv[1:])
