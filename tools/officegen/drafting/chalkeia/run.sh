#!/bin/sh
set -e
C=$(cd "$(dirname "$0")" && pwd)   # tools/officegen/drafting/chalkeia
cd "$C/../.."
# the areas are the user's (compound editor), merged from compounds/Chalkeia_user_areas.txt
python compound_gen.py Chalkeia | grep -v "^wrote"
[ -f $C/hand_walls.py ] && python $C/hand_walls.py
python tower_gen.py Chalkeia | grep -v "^wrote"
python $C/hand_towers.py
python gate_gen.py Chalkeia | grep -v "^wrote"
python props_gen.py Chalkeia | grep -v "^wrote"
[ -f $C/hand_props.py ] && python $C/hand_props.py
python garrison_gen.py Chalkeia | grep -v "^wrote"
[ -f $C/hand_garrison.py ] && python $C/hand_garrison.py
true
