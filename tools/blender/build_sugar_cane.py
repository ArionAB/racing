"""sugar_cane_clump.glb — trestie de zahar (sectorul 7, "Trestia de zahar").

Referinta: assets/okinawa_inspiration/, SUGARCANE_BUNDLE — dar aia e o legatura
TAIATA, culcata. Aici e trestia IN PICIOARE, care face banda de pe marginea
drumului: tulpini inalte de 2.5-3.2 m cu frunze lungi care cad in arc.

De ce conteaza pentru gameplay, nu doar pentru decor: e singurul lucru de pe
pista mai INALT decat masina care nu blocheaza vederea — o perdea prin care
intrezaresti virajul urmator. De-aia tulpinile sunt rare (12-16 pe smoc) si
frunzele inguste; un zid verde compact ar fi ascuns traseul si ar fi facut
sectorul un tunel.

Trei smocuri, ca banda sa nu se citeasca repetata:
  Cane_Clump_A  14 tulpini, 3.0 m — smocul standard
  Cane_Clump_B  10 tulpini, 2.5 m — mai rar, pentru marginea benzii
  Cane_Clump_C  17 tulpini, 3.2 m — dens, pentru spatele benzii

Ramane pe atlasul de paleta (CACTUS_GREEN pentru tulpini — verdele-oliv sters
e exact culoarea trestiei coapte, TROPICAL_GREEN pentru frunze). Fara bevel:
tulpini si lamele, aceeasi decizie ca la cactus si la frunzele de palmier.
"""

import math
from mathutils import Vector

STALK_R = 0.030
LEAVES_PER_STALK = 4


def stalk(b, x, y, height, lean_a, lean_r, seed):
    """O tulpina: usor inclinata, cu noduri si cu frunze din varf.

    Nodurile (inelele ingrosate din 40 in 40 cm) sunt semnatura trestiei — fara
    ele, tulpina e o sarma verde. Costa doua inele in plus fiecare.
    """
    rnd = _lcg(seed)
    d = Vector((math.cos(lean_a), math.sin(lean_a), 0.0))
    base = Vector((x, y, 0.0))
    top = base + d * lean_r + Vector((0, 0, height))
    # Statii dese ca sa iasa noduri: raza alterneaza subtire/ingrosat.
    stations, radii = [], []
    n = max(int(height / 0.40), 4)
    for i in range(n + 1):
        t = i / float(n)
        stations.append(base.lerp(top, t) + Vector((0, 0, 0.0)))
        radii.append(STALK_R * (1.22 if i % 2 else 0.98) * (1.0 - t * 0.28))
    b.taper_sweep(stations, radii, CACTUS_GREEN, segments=5)

    # Frunzele: pleaca de sub varf, urca putin si cad in arc.
    for k in range(LEAVES_PER_STALK):
        a = rnd() * math.tau
        ld = Vector((math.cos(a), math.sin(a), 0.0))
        length = 0.85 + rnd() * 0.55
        start = base.lerp(top, 0.72 + 0.09 * k / LEAVES_PER_STALK)
        path, widths = [], []
        for i in range(5):
            t = i / 4.0
            dz = 0.34 * math.sin(t * 1.6) - 1.05 * t ** 2.3
            path.append(start + ld * (length * t) + Vector((0, 0, dz)))
            widths.append(0.0 if i == 4 else max(0.026, 0.070 * math.sin(math.pi * t ** 0.6)))
        b.blade(path, widths, 0.018, TROPICAL_GREEN, up=(0, 0, 1))


def clump(b, count, height, seed):
    rnd = _lcg(seed)
    for k in range(count):
        # Distributie in disc, nu pe cerc: un inel de tulpini ar fi lasat un gol
        # in mijloc, vizibil exact cand treci pe langa.
        a = rnd() * math.tau
        r = 0.62 * math.sqrt(rnd())
        h = height * (0.80 + rnd() * 0.32)
        stalk(b, math.cos(a) * r, math.sin(a) * r, h,
              rnd() * math.tau, (0.05 + rnd() * 0.16) * h, seed + k * 7)


AO_SPEC = dict(samples=20, dist=1.8, gradient="vertical",
               low=0.50, high=1.0, power=0.9, floor=0.20)

CLUMPS = [
    ("Cane_Clump_A", 14, 3.00, 23),
    ("Cane_Clump_B", 10, 2.50, 37),
    ("Cane_Clump_C", 17, 3.20, 53),
]

clear_built("Cane_Clump_")
built = []
for i, (name, count, h, seed) in enumerate(CLUMPS):
    b = Builder()
    clump(b, count, h, seed)
    obj = b.to_object(name)
    stats = finish(obj, bevel=0.0, ao=AO_SPEC)
    built.append(obj)
    d = obj.dimensions
    print("%-16s %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))

print("TOTAL: %d tris" % sum(tri_count(o) for o in built))
print("GLB:  %s (%d B)" % export_glb(built, "sugar_cane_clump.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "sugar_cane_clump.blend"))
for i, o in enumerate(built):
    o.location = (i * 2.5, 0.0, 0.0)
