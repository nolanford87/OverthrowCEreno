#!/bin/sh
set -e
C=$(cd "$(dirname "$0")" && pwd)   # tools/officegen/drafting/molos
cd "$C/../.."
python compound_gen.py Molos | grep -v "^wrote"
python tower_gen.py Molos | grep -v "^wrote"
python gate_gen.py Molos | grep -v "^wrote"
python props_gen.py Molos | grep -v "^wrote"
python $C/hand_posts.py
python garrison_gen.py Molos | grep -v "^wrote"
true
