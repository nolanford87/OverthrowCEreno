#!/bin/sh
set -e
S=/c/Users/nolan/AppData/Local/Temp/claude/C--Users-nolan/9e22c7f3-aac1-4e9a-8953-51e91b75bfeb/scratchpad/opus
cd /p/OT_rodo_opus/tools/officegen
python $S/areas.py --write
python compound_gen.py Rodopoli
[ -f $S/hand_walls.py ] && python $S/hand_walls.py
python tower_gen.py Rodopoli
[ -f $S/hand_towers.py ] && python $S/hand_towers.py
python gate_gen.py Rodopoli
python props_gen.py Rodopoli
[ -f $S/hand_props.py ] && python $S/hand_props.py
python garrison_gen.py Rodopoli
[ -f $S/hand_garrison.py ] && python $S/hand_garrison.py
for t in 3 4; do $S/png.sh $PWD/compounds/Rodopoli_T${t}_garrison.svg 990; done
