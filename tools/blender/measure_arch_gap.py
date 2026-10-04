"""Masoara GOLUL arcului din GLB-ul exportat (memoria cota-de-contract-se-
masoara-ca-gol): proiectie pe planul XZ (X = latimea drumului, Z = sus; drumul
merge pe Y), TOATE nodurile (roca + grohotis + calota), grila de 5 cm. Un gol e
o regiune libera de la sol in sus, conectata la axa drumului.

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- measure_arch_gap.py

Raporteaza:
  * latimea golului pe fereastra caroseriei (h 0-2 m): MINIMUL pe randuri;
  * inaltimea libera pe fereastra |x| <= 1,1 m (jumatate din latimea masinii):
    cea mai joasa cota ocupata deasupra solului pe orice coloana din fereastra;
  * latimea golului la h = 2, 4, 6, 7,5 m (pentru intuitie).
"""
import os
import sys
import bpy
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(os.path.dirname(HERE))
GLB = os.path.join(PROJ, "assets", "models", "monumentvalley", "rocks", "sandstone_arch.glb")
CELL = 0.05
XMIN, XMAX, ZMAX = -30.0, 30.0, 20.0

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.import_scene.gltf(filepath=GLB)
bpy.context.view_layer.update()

NX, NZ = int((XMAX - XMIN) / CELL), int(ZMAX / CELL)
occ = np.zeros((NZ, NX), dtype=bool)


def mark(px, pz):
    i = int((px - XMIN) / CELL)
    k = int(pz / CELL)
    if 0 <= i < NX and 0 <= k < NZ:
        occ[k, i] = True


tris = 0
for o in bpy.data.objects:
    if o.type != "MESH":
        continue
    me = o.data
    me.calc_loop_triangles()
    mw = o.matrix_world
    vs = [mw @ v.co for v in me.vertices]
    for t in me.loop_triangles:
        p = [(vs[i].x, vs[i].z) for i in t.vertices]
        tris += 1
        # arii proiectate ~0 (fete paralele cu Y): doar muchiile
        for a in range(3):
            (x0, z0), (x1, z1) = p[a], p[(a + 1) % 3]
            n = max(2, int(max(abs(x1 - x0), abs(z1 - z0)) / (CELL * 0.4)))
            for s in range(n + 1):
                mark(x0 + (x1 - x0) * s / n, z0 + (z1 - z0) * s / n)
        xs = [q[0] for q in p]
        zs = [q[1] for q in p]
        i0, i1 = int((min(xs) - XMIN) / CELL), int((max(xs) - XMIN) / CELL) + 1
        k0, k1 = int(min(zs) / CELL), int(max(zs) / CELL) + 1
        i0, k0 = max(i0, 0), max(k0, 0)
        i1, k1 = min(i1, NX - 1), min(k1, NZ - 1)
        if i1 < i0 or k1 < k0:
            continue
        gx, gz = np.meshgrid(XMIN + (np.arange(i0, i1 + 1) + 0.5) * CELL,
                             (np.arange(k0, k1 + 1) + 0.5) * CELL)
        (ax, az), (bx, bz), (cx, cz) = p
        den = (bz - cz) * (ax - cx) + (cx - bx) * (az - cz)
        if abs(den) < 1e-12:
            continue
        w1 = ((bz - cz) * (gx - cx) + (cx - bx) * (gz - cz)) / den
        w2 = ((cz - az) * (gx - cx) + (ax - cx) * (gz - cz)) / den
        inside = (w1 >= 0) & (w2 >= 0) & (1 - w1 - w2 >= 0)
        occ[k0:k1 + 1, i0:i1 + 1] |= inside


def col(x):
    return int((x - XMIN) / CELL)


def row(z):
    return int(z / CELL)


def gap_width(k):
    """Latimea regiunii libere din randul k, conectata la x = 0."""
    c = col(0.0)
    if occ[k, c]:
        return 0.0
    i = c
    while i > 0 and not occ[k, i - 1]:
        i -= 1
    j = c
    while j < NX - 1 and not occ[k, j + 1]:
        j += 1
    return (j - i + 1) * CELL


car_rows = range(row(0.05), row(2.0) + 1)
w_car = min(gap_width(k) for k in car_rows)
# inaltimea libera pe fereastra |x| <= 1,1: prima celula ocupata deasupra solului
clear = 1e9
for x in np.arange(-1.1, 1.1001, CELL):
    c = col(x)
    ks = np.nonzero(occ[row(0.05):, c])[0]
    h = (ks[0] + row(0.05)) * CELL if len(ks) else ZMAX
    clear = min(clear, h)
print("== GOL ARC (proiectie XZ, grila %.2f m, %d triunghiuri) ==" % (CELL, tris))
print("latime gol, fereastra h 0-2 m (minim pe randuri): %.2f m  (contract >= 14)" % w_car)
print("inaltime libera, fereastra |x|<=1.1 m: %.2f m  (contract >= 7.5)" % clear)
for h in (0.5, 2.0, 4.0, 6.0, 7.5):
    print("  latimea golului la h=%.1f m: %.2f m" % (h, gap_width(row(h))))
ok = w_car >= 14.0 and clear >= 7.5
print("VERDICT GOL:", "OK" if ok else "SUB CONTRACT")

if "--rows" in sys.argv:
    for z in (0.1, 0.3, 0.6, 1.0, 1.5, 2.0):
        k = row(z)
        c = col(0.0)
        i = c
        while i > 0 and not occ[k, i - 1]:
            i -= 1
        j = c
        while j < NX - 1 and not occ[k, j + 1]:
            j += 1
        print("  z=%.1f gol x %.2f .. %.2f" % (z, XMIN + i * CELL, XMIN + (j + 1) * CELL))
