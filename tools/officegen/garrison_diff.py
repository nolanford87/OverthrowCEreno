import sys, collections
sys.path.insert(0, 'P:/OT_troops/tools/officegen')
import merge_layouts as ml
before = ml.parse(open(sys.argv[1], encoding='utf-8').read().splitlines())['Altis']
after = ml.load_saved('Altis')
for town in ('Rodopoli', 'Paros', 'Chalkeia'):
    for tier in (3, 4):
        b, a = before[town]['tiers'][tier], after[town]['tiers'][tier]
        keep = lambda it: not (it[0] == 'guard' and 'garrison' in it[4]) and 'post' not in str(it[4]).split(',')
        kb = collections.Counter(tuple(it) for it in b if keep(it)); ka = collections.Counter(tuple(it) for it in a if keep(it))
        rb = collections.Counter(it[1] for it in b if it[0] == 'guard'); ra = collections.Counter(it[1] for it in a if it[0] == 'guard')
        posts = sum(1 for it in a if 'post' in str(it[4]).split(','))
        print(f"{town} T{tier}: other items before {sum(kb.values())} after {sum(ka.values())} identical {kb == ka}; guards {sum(rb.values())} -> {sum(ra.values())} {dict(ra)}; post pieces {posts}")
        if kb != ka:
            print('   only before:', list((kb - ka).elements())[:5]); print('   only after:', list((ka - kb).elements())[:5])
