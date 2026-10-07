#!/bin/sh
set -e
C=/c/Users/nolan/AppData/Local/Temp/claude/C--Users-nolan/9e22c7f3-aac1-4e9a-8953-51e91b75bfeb/scratchpad/opus/chalk
cd /p/OT_chalkeia/tools/officegen
(cd $C && python -c "import areas; areas.write()")
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
