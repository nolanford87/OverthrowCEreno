"""Road-framed areas: python frame.py Town theta  -> roads in the frame (along, across) near the HQ"""
import sys, math
import os; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
import blocklib as bl
def frame(b, th):
    u = (math.sin(math.radians(th)), math.cos(math.radians(th))); n = (-u[1], u[0])
    O = b.pos
    to = lambda p: ((p[0]-O[0])*u[0]+(p[1]-O[1])*u[1], (p[0]-O[0])*n[0]+(p[1]-O[1])*n[1])
    back = lambda a, c: [round(O[0]+u[0]*a+n[0]*c, 2), round(O[1]+u[1]*a+n[1]*c, 2)]
    return to, back
if __name__ == '__main__':
    b = bl.load()[sys.argv[1]]; th = float(sys.argv[2])
    to, back = frame(b, th)
    for r in b.roads:
        A, Z = to(r['beg']), to(r['end'])
        if min(abs(A[0]), abs(Z[0])) < 80 and min(abs(A[1]), abs(Z[1])) < 80:
            print(r['width'], [round(v,1) for v in A], [round(v,1) for v in Z])
    for t in b.buildings:
        a = to(t.pos)
        if abs(a[0]) < 60 and abs(a[1]) < 60:
            print('B', t.model[:30], [round(v,1) for v in a])
