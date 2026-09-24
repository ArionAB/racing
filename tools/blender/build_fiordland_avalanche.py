"""Fiordland — Avalansa de copaci (brief §1.5, val 3 din
docs/asset_briefs/fiordland_kit.md).

  fiordland/effects/tree_avalanche.glb   4 noduri Boulder_A..D

Contractul e al `AvalancheHazard` (scenes/hazards/avalanche_hazard.gd), NU al
plansei: hazardul cauta nodurile DUPA NUME EXACT (`Boulder_A`, `Boulder_B`,
`Boulder_C`, `Boulder_D`), rescaleaza fiecare ca max(X,Z) sa cada intre 1.0 si
2.8 m, si le ROSTOGOLESTE in jurul centrului cu o sfera de coliziune de 0.82 x
raza. Consecinte directe:

  1. Originea in CENTRUL volumului, nu la baza (`finish(origin="center")`).
  2. Fiecare nod COMPACT: raport de laturi <= 1.5:1 pe orice pereche de axe —
     un bulgan lung s-ar rostogoli ca o elice, cu sfera de coliziune lovind
     in gol (avertismentul explicit din brief).

Fiecare forma e un GHEM: un bolovan MARBLE_GREY prins in 2-4 trunchiuri
scurte rupte (LOG_DARK, capete zimtate), cu radacini si muschi TROPICAL_GREEN.
A = mai multa roca ... D = mai mult lemn (brief). Scara comuna ~2 m (hazardul
o rescaleaza oricum la constructie).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_avalanche.py
"""

import math
from mathutils import Vector

# Sloturile legale pe Fiordland (brief §0.4). ROCK_DARK/ROCK_LIGHT interzise.
BOULDER_ROCK = MARBLE_GREY
LOG = LOG_DARK
MOSS = TROPICAL_GREEN

# Scara comuna de referinta (m) — hazardul rescaleaza fiecare nod la
# max(X,Z) din contract (1.0-2.8), deci geometria de aici poate fi construita
# la o singura scara convenabila, nu la patru marimi diferite.
BASE = 2.0


def _jagged_stub(b, root, tip, r0, r1, slot, seed, kinks=2):
    """Ciot de trunchi RUPT: un `taper_sweep` cu cateva puncte intermediare
    usor deviate (nu o linie dreapta) si raza care se ingusteaza spre capat,
    plus capatul insusi RETEZAT (nu ascutit) — capatul de sus al taper-ului
    ramane cu o raza mica dar nenula, ca sa citeasca "rupt", nu "ascutit ca
    un creion".

    NU foloseste `_beech_trunk`/`sweep`: acela e neted si continuu (o ramura
    vie), aici trebuie o bucata SCURTA si franta, prinsa in bolovan la o
    capat si rupta liber la celalalt.
    """
    rand = _lcg(seed)
    root, tip = Vector(root), Vector(tip)
    pts = [root]
    radii = [r0]
    n = max(kinks, 1)
    for i in range(1, n + 1):
        t = i / (n + 1)
        p = root.lerp(tip, t)
        # deviatie laterala mica, perpendiculara pe axa generala — franturile
        # unui trunchi rupt nu sunt coliniare
        perp = Vector((-(tip - root).y, (tip - root).x, 0.0))
        if perp.length > 1e-5:
            perp.normalize()
        p += perp * (rand() - 0.5) * (tip - root).length * 0.22
        p += Vector((0, 0, (rand() - 0.5) * (tip - root).length * 0.15))
        pts.append(p)
        radii.append(r0 + (r1 - r0) * t)
    pts.append(tip)
    radii.append(max(r1, 0.03))  # capat RETEZAT, nu ascutit (raza nenula)
    # segments=4: un ciot de 3 puncte la 4 laturi (tub patrat rotunjit) e
    # suficient la scara de camera de joc — bugetul (300 tri/nod) nu are loc
    # pentru cilindri de 5-8 laturi pe 2-4 ciorchini plus radacini.
    return b.taper_sweep(pts, radii, slot, segments=4, cap_start=True, cap_end=True)


def _boulder_tangle(seed, rock_frac, name):
    """Un ghem: bolovan central + 2-4 ciorchini de trunchi rupt agatati de
    el, radacini scurte, muschi pe suprafata de sus. `rock_frac` (0..1) e
    fractia de rock vs. wood — A=mare (mai multa roca), D=mic (mai mult lemn).

    COMPACT prin constructie: bolovanul e sfera usor turtita (nu alungita),
    iar trunchiurile pornesc DIN bolovan si se opresc la <= 0.6*BASE distanta
    — nimic nu iese suficient de departe ca sa strice raportul de laturi.
    """
    b = Builder()
    rand = _lcg(seed)

    rock_r = BASE * (0.34 + 0.14 * rock_frac)   # A (rock_frac mare) -> bolovan mai mare
    # bolovan usor neregulat, turtit BLAND (nu disc) — ramane rotund pe toate
    # axele, exact ce cere raportul de laturi <=1.5:1. segments/rings reduse
    # (6x3, nu 8x4): bugetul de 300 tri/nod nu are loc pentru un bolovan de
    # 128 tri brut plus 2-4 ciorchini plus radacini.
    b.boulder((0.0, 0.0, 0.0),
             (rock_r * 2.0 * (0.92 + rand() * 0.14),
              rock_r * 2.0 * (0.92 + rand() * 0.14),
              rock_r * 2.0 * (0.85 + rand() * 0.12)),
             BOULDER_ROCK, seed=seed + 1, segments=6, rings=3, deviation=0.16)

    # 2 (mult rock) .. 3 (mult lemn) ciorchini — bugetul nu are loc pentru 4
    # ciorchini de taper_sweep plus radacini plus bolovan sub 300 tri.
    n_stubs = 2 + int(round((1.0 - rock_frac)))
    # capetele NU ies dincolo de ~0.42*BASE de la centru (nu 0.58): la 0.58
    # aspectul masurat a iesit 1.48-1.85:1, peste plafonul de 1.5. Ciotul
    # ramane vizibil scurt si RUPT (contractul), doar mai aproape de bolovan.
    stub_len_max = BASE * 0.30
    for i in range(n_stubs):
        a = 2.0 * math.pi * (i + rand() * 0.5) / n_stubs
        el = math.radians(-25.0 + rand() * 55.0)  # inaltime variata, unele coboara
        dirv = Vector((math.cos(a) * math.cos(el),
                       math.sin(a) * math.cos(el),
                       math.sin(el)))
        root = dirv * rock_r * (0.55 + rand() * 0.15)   # radacina, INTRA in bolovan
        stub_len = stub_len_max * (0.6 + rand() * 0.4)
        tip = dirv * (rock_r * 0.55 + stub_len)
        r0 = BASE * (0.075 + rand() * 0.03)
        r1 = r0 * (0.35 + rand() * 0.2)
        _jagged_stub(b, root, tip, r0, r1, LOG, seed=seed + 20 + i * 7, kinks=1)

    # radacini scurte, mai subtiri, agatate de partea de jos a bolovanului —
    # citesc ca smocul de radacini ramas dupa ce copacul a fost smuls. O
    # singura radacina (nu 2-3): C/D (mai mult lemn, 3 ciorchini) ies peste
    # bugetul de 300 tri cu oricare a doua — masurat. Accent, nu al doilea
    # rand de ciorchini.
    n_roots = 1
    for i in range(n_roots):
        a = 2.0 * math.pi * (i + 0.5 + rand() * 0.4) / n_roots
        dirv = Vector((math.cos(a), math.sin(a), -0.55 - rand() * 0.25)).normalized()
        root = dirv * rock_r * 0.6
        tip = dirv * rock_r * (0.82 + rand() * 0.18)
        r0 = BASE * 0.026
        _jagged_stub(b, root, tip, r0, r0 * 0.3, LOG, seed=seed + 60 + i * 5, kinks=1)

    # muschi: retag pe fetele de sus ale bolovanului (style_bible: AO/muschi
    # pe suprafetele orizontale) — cost zero triunghiuri
    all_faces = [f for f in b.bm.faces if f.is_valid]
    b.retag(all_faces, MOSS, where=lambda c, n: n.z > 0.55 and c.z > rock_r * 0.15)

    return b.to_object(name)


# --- emit ----------------------------------------------------------------

clear_built()
results = []

AO_TANGLE = dict(samples=20, dist=1.6, gradient="vertical",
                 low=0.48, high=1.00, power=0.88, floor=0.20)


def _bbox(obj):
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def _aspect_report(obj, name):
    (x0, x1), (y0, y1), (z0, z1) = _bbox(obj)
    sx, sy, sz = x1 - x0, y1 - y0, z1 - z0
    dims = {"X": sx, "Y": sy, "Z": sz}
    pairs = [("X/Y", sx / max(sy, 1e-6)), ("X/Z", sx / max(sz, 1e-6)),
             ("Y/Z", sy / max(sz, 1e-6))]
    worst = max(max(r, 1.0 / r) for _, r in pairs)
    # fractia de varfuri din afara sferei de 0.82 * jumatate din max(X,Z) —
    # aceeasi formula pe care hazardul o foloseste pentru sfera de coliziune
    # (HULL_FRACTION = 0.82), centrata pe originea (0,0,0) a nodului (center).
    half_max_xz = max(sx, sz) * 0.5
    hull_r = half_max_xz * 0.82
    verts = obj.data.vertices
    outside = sum(1 for v in verts if v.co.length > hull_r)
    frac_outside = outside / max(len(verts), 1)
    print("  %-10s dims X=%.2f Y=%.2f Z=%.2f  aspect max=%.2f:1  "
          "hull(r=%.2f) varfuri-afara=%.0f%%"
          % (name, sx, sy, sz, worst, hull_r, 100.0 * frac_outside))
    return worst, frac_outside


def emit_avalanche(objs):
    # bevel_angle mare (70, nu implicitul 30): pe geometrie curbata (bolovan,
    # ciorchini de taper_sweep) un prag jos testeste aproape orice muchie —
    # masurat: la 30 grade nodurile ieseau 360-420 tri, peste bugetul de 300.
    # Vezi nota de cost din apply_bevel: rotunjimea tubului o da poligonul
    # (segments), nu tesitura — bugetul se recupereaza ridicand pragul, nu
    # taind geometrie.
    for o in objs:
        finish(o, bevel=0.02, bevel_angle=70.0, ao=AO_TANGLE, origin="center",
              smooth_angle=40.0)
    path, size = export_glb(objs, "fiordland/effects/tree_avalanche.glb")
    print("export:", path, "(%.1f KB)" % (size / 1024.0))
    return path, size


specs = [
    ("Boulder_A", 5601, 0.85),   # mai multa roca
    ("Boulder_B", 5611, 0.55),
    ("Boulder_C", 5621, 0.35),
    ("Boulder_D", 5631, 0.10),   # mai mult lemn
]

objs = []
for name, seed, rock_frac in specs:
    objs.append(_boulder_tangle(seed, rock_frac, name))

emit_avalanche(objs)

print()
total = 0
for o in objs:
    tris = tri_count(o)
    total += tris
    flag = "OK" if tris <= 300 else "DEPASIT (buget 300)"
    print("%-12s tris=%4d  %s" % (o.name, tris, flag))
print("TOTAL tree_avalanche: %d tris" % total)
print()
for o in objs:
    _aspect_report(o, o.name)

save_blend(objs, "fiordland_avalanche.blend")
