"""Jodhpur -- stanca, plantele si candelele, val 5 grupa natura (brief §1.7,
docs/asset_briefs/jodhpur_kit.md).

  jodhpur/rocks/rhyolite_boulder_a.glb   bolovan de riolit 3,0 x 2,4 x 2,0 m
  jodhpur/rocks/rhyolite_boulder_b.glb   bolovan de riolit 3,5 x 2,2 x 1,8 m
  jodhpur/rocks/rhyolite_boulder_c.glb   bolovan de riolit 2,5 x 2,0 x 1,6 m
  jodhpur/rocks/rock_slab.glb            lespede joasa 4,0 x 2,5 x 0,8 m
  jodhpur/plants/euphorbia.glb           euforbia-candelabru 2,2 m, <= 300 tri
  jodhpur/plants/neem_tree.glb           neem 7 m, Trunk + Crown, <= 400 tri
  jodhpur/plants/khejri_tree.glb         khejri 6 m, Trunk + Crown, <= 400 tri
  jodhpur/props/diya.glb                 candela de lut, O SINGURA plasa, <= 24 tri
  jodhpur/props/floating_diya.glb        candela pe frunza, O SINGURA plasa, <= 40 tri

Fundalul (`rocks/jodhpur_horizon.glb`) NU e aici: `build_jodhpur_horizon.py`.

**Stancile sunt ANVELOPE CONVEXE**, nu elipsoide perturbate. Planșa le deseneaza
cu fatete mari, plate si muchii drepte (brief: "nu rotunjite"); `rock()`/
`boulder()` din dio_lib dau inele orizontale, adica benzi, nu fatete. Anvelopa
convexa a ~25 de puncte asezate de mana (talpa, brau, umar, varf) da exact
fatetele planșei, iar numarul de triunghiuri e ~2V-4 (sub 60). Fara bevel si
cu umbrire plata: bevel-ul ar rotunji muchiile si ar tripla cifra.

**Candelele au o singura plasa** (brief §1.7): le consuma `FlockProp`
(`scenes/props/flock.gd::_mesh_of`), care ia PRIMUL `MeshInstance3D` din GLB si
ignora restul. Deci un singur obiect Blender, cu toate sloturile in el
(materialul e oricum `Palette.world_material()` pe tot MultiMesh-ul).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_jodhpur_nature.py
"""

import math
from mathutils import Vector, Matrix

# Sloturile (brief §0.4)
RHYOLITE = ROCK_DARK        # riolit: corect aici (nu bazalt), clasa `rhyolite`
LEAF = CACTUS_GREEN         # coroane, euforbia
LEAF_TOP = TROPICAL_GREEN   # fetele de sus ale coroanelor / capacele coloanelor
BARK = LOG_DARK
BARK_LIGHT = WOOD
SOIL = ROCK_DARK            # movila de pamant de sub euforbie (brun-roscat)
CLAY = TILE_TERRACOTTA      # lut ars: corect pe candela (brief §1.7)
OIL = RUST                  # interiorul candelei, lut ars mai inchis / ulei
LEAF_PLATE = TROPICAL_GREEN  # talgerul de frunza al candelei plutitoare

AO_ROCK = dict(samples=24, dist=1.6, gradient="vertical",
               low=0.62, high=1.00, power=0.9, floor=0.30)
AO_TREE = dict(samples=16, dist=3.0, gradient="vertical",
               low=0.55, high=1.00, power=0.85, floor=0.25)
AO_SMALL = dict(samples=16, dist=0.8, gradient="vertical",
                low=0.60, high=1.00, power=0.9, floor=0.28)
AO_TINY = dict(samples=8, dist=0.05, gradient="vertical",
               low=0.70, high=1.00, power=0.9, floor=0.45)

results = []


# ---------------------------------------------------------------------------
# Unelte
# ---------------------------------------------------------------------------

def hull_rock(b, pts, slot, size, FLARE=1.12):
    """Anvelopa convexa a punctelor `pts` (coordonate NORMALIZATE, bbox
    aproximativ [-0.5,0.5]^2 x [0,1]), scalata exact pe `size` = (X, Y, Z).
    Fatetele raman plate (triunghiuri coplanare se contopesc in poligoane
    mari prin dissolve_limit), deci muchiile sunt drepte, ca pe planșa."""
    # Fara surplomba: fiecare punct isi lasa proiectia pe sol (cu o evazare
    # mica), deci flancurile coboara vertical sau se lasa in afara -- bolovanul
    # sta ASEZAT, cum e pe planșa, nu pe o talpa mai ingusta decat braul.
    pts = list(pts) + [(p[0] * FLARE, p[1] * FLARE, 0.0) for p in pts if p[2] > 0.0]
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]; zs = [p[2] for p in pts]
    cx, cy = (min(xs) + max(xs)) * 0.5, (min(ys) + max(ys)) * 0.5
    sx = size[0] / (max(xs) - min(xs))
    sy = size[1] / (max(ys) - min(ys))
    sz = size[2] / (max(zs) - min(zs))
    z0 = min(zs)
    verts = [b.bm.verts.new(((p[0] - cx) * sx, (p[1] - cy) * sy, (p[2] - z0) * sz))
             for p in pts]
    res = bmesh.ops.convex_hull(b.bm, input=verts, use_existing_faces=False)
    kill = list({g for g in res["geom_interior"] + res["geom_unused"]
                 if isinstance(g, bmesh.types.BMVert) and not g.link_faces})
    if kill:
        bmesh.ops.delete(b.bm, geom=kill, context="VERTS")
    faces = [g for g in res["geom"] if isinstance(g, bmesh.types.BMFace) and g.is_valid]
    bmesh.ops.dissolve_limit(b.bm, angle_limit=math.radians(2.0),
                             verts=[v for v in b.bm.verts],
                             edges=[e for e in b.bm.edges])
    for f in b.bm.faces:
        f[b.slot] = slot
    return set(b.bm.faces)


def ring(n, rx, ry, z, phase=0.0, jitter=None, shift=(0.0, 0.0)):
    """n puncte pe o elipsa la cota z; `jitter` = lista de factori de raza."""
    out = []
    for i in range(n):
        a = phase + 2.0 * math.pi * i / n
        k = jitter[i % len(jitter)] if jitter else 1.0
        out.append((shift[0] + math.cos(a) * rx * k,
                    shift[1] + math.sin(a) * ry * k, z))
    return out


def top_faces_to(b, from_slot, to_slot, nz=0.55):
    """Fetele orientate in sus (normala z > nz) de pe `from_slot` trec pe
    `to_slot` -- brief §0.4: coroanele CACTUS_GREEN, fetele de sus
    TROPICAL_GREEN."""
    b.bm.normal_update()
    n = 0
    for f in b.bm.faces:
        if f[b.slot] == from_slot and f.normal.z > nz:
            f[b.slot] = to_slot
            n += 1
    return n


def emit(objs, path, ao, bevel=0.0, smooth_angle=None, budget=None):
    """Ca `emit` din build_jodhpur_bazaar.py: pe piesele cu mai multe noduri
    offsetul de origine se calculeaza O DATA pe ansamblu (memoria
    finish-recentreaza-fiecare-nod-separat) si se aplica identic."""
    objs = [o for o in objs if o is not None]
    solo = len(objs) == 1
    place = Vector((0.0, 0.0, 0.0))
    if not solo:
        xs, ys, zs = [], [], []
        for o in objs:
            for v in o.data.vertices:
                xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
        place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5,
                        -min(zs)))
    total = 0
    for o in objs:
        if not solo:
            # origine comuna INAINTE de AO, ca gradientul vertical sa porneasca
            # de la solul real al ansamblului
            for v in o.data.vertices:
                v.co += place
        st = finish(o, bevel=bevel, ao=ao, origin=("base" if solo else None),
                    smooth_angle=smooth_angle)
        total += st["tris"]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    per_node = {o.name: tri_count(o) for o in objs}
    _, sz = export_glb(objs, "jodhpur/" + path)
    results.append((path, total, dims, budget, per_node, sz / 1024.0))
    return total


# ===========================================================================
# 1. STANCA DE RIOLIT
# ===========================================================================

def boulder_a():
    """`rhyolite_boulder_a.png` -- lista de elemente (inainte de modelare):

      - 1 bolovan, ~15-20 de fatete MARI, plate, muchii drepte
      - talpa LATA, pe sol, fara retragere (sta asezat, nu e o minge)
      - stanga: capatul jos (~0,25 H), apoi o PANTA LUNGA care urca spre varf
      - VARFUL e unul singur, putin la dreapta centrului (~55% din latime)
      - din varf, o fata de sus INCLINATA coboara spre umarul din dreapta
        (~0,75 H), apoi flancul drept cade aproape VERTICAL la sol
      - fata spre privitor: 3-4 plane mari
      - culoare uniforma (riolit), fatetele se despart doar prin lumina
      - h/l 0,69 (brief), cote 3,0 x 2,4 x 2,0 m
    Axe: lungimea pe Y (-Y = stanga in comparatie; camera sta pe +X).
    """
    b = Builder()
    pts = ring(7, 0.5, 0.5, 0.0, phase=0.25, jitter=[1.0, 0.94, 1.0, 0.97, 0.92, 1.0, 0.96])
    pts += [
        (0.22, -0.50, 0.26), (-0.20, -0.50, 0.22),      # capatul stang, jos
        (0.40, -0.26, 0.50), (-0.32, -0.20, 0.55),      # panta lunga
        (0.46, -0.36, 0.36), (0.44, 0.24, 0.56),        # fatete pe fata
        (0.12, 0.06, 1.00), (-0.16, 0.12, 0.95),        # varful
        (0.30, 0.30, 0.66), (-0.18, 0.36, 0.70),        # fata de sus inclinata
        (0.36, 0.47, 0.45), (-0.26, 0.48, 0.50),        # flancul drept, vertical
        (0.08, 0.50, 0.18),
        (0.50, 0.08, 0.35), (0.48, -0.12, 0.18),        # fata spre privitor
    ]
    hull_rock(b, pts, RHYOLITE, (2.4, 3.0, 2.0))
    return b.to_object("Rhyolite_Boulder_A")


def boulder_b():
    """`rhyolite_boulder_b.png` -- lista de elemente:

      - 1 bolovan LAT si jos, ~18-22 de fatete mari
      - talpa lata, pe sol
      - stanga: un LOB jos (~0,4 H), separat de corp printr-o treapta
      - corpul principal: varful in stanga centrului (~40%), cu o creasta
        scurta, plata
      - dreapta: fata de sus coboara spre un umar (~0,7 H), apoi flancul
        drept cade abrupt
      - h/l 0,53, cote 3,5 x 2,2 x 1,8 m
    """
    b = Builder()
    pts = ring(8, 0.5, 0.5, 0.0, phase=0.15, jitter=[1.0, 0.95, 1.0, 0.93, 0.97, 1.0, 0.94, 1.0])
    pts += [
        (0.30, -0.50, 0.30), (-0.20, -0.50, 0.26),      # capatul stang
        (0.42, -0.36, 0.44), (-0.28, -0.34, 0.46),      # lobul stang
        (0.30, -0.24, 0.78), (-0.25, -0.20, 0.80),      # urcusul spre varf
        (0.08, -0.06, 1.00), (-0.10, 0.02, 0.98),       # varful, scurt
        (0.28, 0.28, 0.62), (-0.20, 0.30, 0.64),        # umarul drept
        (0.46, 0.14, 0.52), (0.46, -0.20, 0.30),        # fatete pe fata
        (0.30, 0.48, 0.42), (-0.22, 0.49, 0.45),        # flancul drept
        (0.50, 0.05, 0.40), (0.48, 0.30, 0.22),         # fata spre privitor
    ]
    hull_rock(b, pts, RHYOLITE, (2.2, 3.5, 1.8))
    return b.to_object("Rhyolite_Boulder_B")


def boulder_c():
    """`rhyolite_boulder_c.png` -- lista de elemente:

      - 1 bolovan compact, ~15-18 fatete mari
      - talpa lata, pe sol
      - stanga: flanc ABRUPT, aproape vertical pana la ~0,6 H
      - sus: o creasta plata, larga, de la stanga-centru la centru
      - dreapta: panta LUNGA si domoala pana jos (~0,35 H la capat)
      - h/l 0,63, cote 2,5 x 2,0 x 1,6 m
    """
    b = Builder()
    pts = ring(7, 0.5, 0.5, 0.0, phase=0.4, jitter=[1.0, 0.95, 1.0, 0.96, 0.93, 1.0, 0.97])
    pts += [
        (0.30, -0.50, 0.55), (-0.25, -0.48, 0.60),      # flancul stang abrupt
        (0.22, -0.32, 0.95), (-0.20, -0.28, 0.97),      # muchia de sus-stanga
        (0.18, 0.06, 1.00), (-0.18, 0.10, 0.98),        # creasta plata
        (0.34, 0.34, 0.62), (-0.24, 0.36, 0.64),        # panta dreapta
        (0.20, 0.50, 0.34), (-0.14, 0.50, 0.36),        # capatul drept, jos
        (0.50, -0.10, 0.45),                            # fata spre privitor
    ]
    hull_rock(b, pts, RHYOLITE, (2.0, 2.5, 1.6))
    return b.to_object("Rhyolite_Boulder_C")


def rock_slab():
    """`rock_slab.png` -- lista de elemente:

      - 1 lespede JOASA si lunga, ~20 de fatete
      - flancuri VERTICALE pe ~55% din inaltime, cu 2-3 plane pe latura lunga
      - MARGINI TESITE: o banda de fatete inclinate intre flancuri si fata
        de sus, de jur imprejur
      - fata de sus aproape plana, fatetata in 3-4 plane
      - capatul stang TEȘIT-bont, cel drept ASCUTIT (plan de romb alungit)
      - h/l 0,33 la unghiul planșei, cote 4,0 x 2,5 x 0,8 m
    """
    b = Builder()
    # romb alungit, colturi nete: capatul stang bont (-Y), cel drept ascutit
    outline = [(0.10, -0.50), (0.44, -0.30), (0.50, 0.12), (0.10, 0.50),
               (-0.40, 0.22), (-0.46, -0.26), (-0.12, -0.50)]
    pts = []
    for x, y in outline:
        pts.append((x, y, 0.58))
        pts.append((x * 0.72, y * 0.82, 0.93))
    pts += [(0.10, -0.20, 1.0), (-0.08, 0.10, 0.99), (0.14, 0.18, 0.97)]
    hull_rock(b, pts, RHYOLITE, (2.5, 4.0, 0.8), FLARE=1.03)
    return b.to_object("Rock_Slab")


# ===========================================================================
# 2. PLANTELE
# ===========================================================================

def euphorbia():
    """`euphorbia.png` -- lista de elemente:

      - movila mica de pamant brun-roscat la baza, cat manunchiul de coloane
      - trunchi SCURT, ascuns in manunchi: toate coloanele pleaca din acelasi
        loc, stranse la sol (~0,3 m), nu din brate orizontale
      - 8 COLOANE muchiate (5 fete), capete bonte, verzi, care se DESFAC
        LIN din manunchi (cot moale, nu in unghi drept) si apoi urca drept:
          * centru, usor in stanga: cea mai inalta (2,2 m)
          * stanga: 3 -- una exterioara joasa, cea mai departata (~1,5 m),
            una medie (~1,75 m), una scurta in fata (~1,2 m)
          * dreapta: 3 -- una inalta (~1,9 m), una exterioara (~1,6 m),
            una joasa in fata (~1,35 m)
          * 1 in spate (~1,45 m), intre centru si dreapta
      - latimea totala ~0,9 din inaltime (h/l 1,13)
      - capacele coloanelor pe TROPICAL_GREEN (fetele de sus)
      - ce NU e geometrie: tepii, nervurile si ramurelele mici laterale
    Buget: <= 300 tri (brief, piesa multiplicata).
    """
    b = Builder()
    b.taper_sweep([(0, 0, -0.02), (0, 0, 0.06)], [0.36, 0.22], SOIL, segments=6,
                  cap_start=False, cap_end=True)
    # (dx, dy, cot_z, h, raza): dx pe X (spre camera), dy pe Y (stanga -/dreapta +)
    cols = [
        (0.00, -0.06, 0.20, 2.20, 0.135),   # centrul, cea mai inalta
        (0.05, -0.80, 0.45, 1.50, 0.105),   # stanga exterior
        (-0.10, -0.46, 0.32, 1.78, 0.115),  # stanga medie
        (0.20, -0.26, 0.24, 1.20, 0.105),   # stanga scurta, in fata
        (-0.05, 0.36, 0.28, 1.92, 0.12),    # dreapta inalta
        (0.10, 0.74, 0.42, 1.60, 0.105),    # dreapta exterior
        (0.22, 0.52, 0.32, 1.34, 0.105),    # dreapta joasa, in fata
        (-0.30, 0.12, 0.30, 1.46, 0.11),    # spate
    ]
    for dx, dy, elbow, h, r in cols:
        dy *= 1.15   # h/l masurat pe randare 1,35 fata de 1,18 pe decupare
        base = Vector((dx * 0.18, dy * 0.18, 0.0))
        bend = Vector((dx * 0.78, dy * 0.78, elbow))
        up = Vector((dx, dy, elbow + 0.22))
        h -= 0.08   # cota totala masurata 2,29 cu h nominal: movila + capac
        b.taper_sweep([base, bend, up, Vector((dx, dy, h))],
                      [r * 1.1, r, r, r * 0.82], LEAF, segments=5,
                      cap_start=False, cap_end=True)
    top_faces_to(b, LEAF, LEAF_TOP, nz=0.8)
    return b.to_object("Euphorbia")


def neem_tree():
    """`neem_tree.png` -- lista de elemente:

      TRUNK
      - trunchi gros, scurt, maro mediu (WOOD), cu talpa evazata pe sol
      - se desface la ~1/3 din inaltime (~2,1 m) in 3 CRENGI principale:
        stanga, dreapta si una spre spate, toate in V, intra in coroana;
        se vad sub coroana
      CROWN
      - coroana PLINA, ROTUNDA, un singur nor compact, FARA goluri de cer
      - o masa centrala + 7 umflaturi pe contur (5-7 volume in silueta):
        2 laterale joase, 1 in fata, 2 in spate, 2 sus (varful e cocoasat,
        nu o calota neteda)
      - baza coroanei la ~37% din inaltime pe margini (trunchiul se vede
        ~2,5 m), latimea coroanei ~1,2 x inaltimea ei (h/l total 0,81)
      - verde plin; fetele de sus TROPICAL_GREEN
    Cote: 7 m inaltime, ~8,6 m latime. Buget <= 400 tri.
    """
    bt = Builder()
    bt.taper_sweep([(0, 0, -0.05), (0, 0, 0.45), (0.05, 0.0, 2.2)],
                   [0.66, 0.42, 0.36], BARK_LIGHT, segments=6, cap_start=False,
                   cap_end=False)
    fork = Vector((0.05, 0.0, 2.05))
    for tip in ((0.30, -2.0, 3.7), (0.25, 1.9, 3.6), (-1.5, 0.2, 3.9)):
        bt.taper_sweep([fork, Vector(tip)], [0.28, 0.15], BARK_LIGHT, segments=5,
                       cap_start=False, cap_end=False)
    trunk = bt.to_object("Trunk")

    bc = Builder()
    # masa centrala: tine coroana PLINA (nicio gaura intre umflaturi)
    bc.boulder((0.0, 0.0, 5.0), (7.0, 7.2, 3.9), LEAF, seed=701,
               segments=8, rings=5, deviation=0.06)
    bumps = [  # (centru, marime)
        ((0.4, -3.0, 4.0), (3.2, 2.8, 2.9)),      # stanga, jos
        ((0.3, 3.0, 4.0), (3.2, 2.8, 2.9)),       # dreapta, jos
        ((2.6, 0.2, 4.6), (2.8, 3.4, 2.6)),       # fata
        ((-2.3, -1.6, 4.9), (3.0, 3.0, 2.8)),     # spate-stanga
        ((-2.2, 1.8, 4.8), (3.0, 3.0, 2.8)),      # spate-dreapta
        ((0.6, -1.3, 6.0), (3.2, 3.0, 1.9)),      # sus-stanga
        ((0.2, 1.5, 6.1), (3.0, 3.0, 1.8)),       # sus-dreapta
    ]
    for k, (c, s) in enumerate(bumps):
        bc.boulder(c, s, LEAF, seed=733 + k * 13, segments=6, rings=3,
                   deviation=0.10)
    top_faces_to(bc, LEAF, LEAF_TOP, nz=0.8)
    crown = bc.to_object("Crown")
    return [trunk, crown]


def khejri_tree():
    """`khejri_tree.png` -- lista de elemente:

      TRUNK
      - trunchi RASUCIT, scurt (~1,6 m), maro mediu, talpa evazata
      - se desface JOS in 2 BRATE mari in V larg; fiecare brat se mai
        desface -> 5 crengi care urca oblic in placile coroanei; crengile
        se VAD printre placi si sub ele
      CROWN
      - coroana RARA, TURTITA, in UMBRELA: 5 PLACI late de frunzis, la cote
        diferite, cu CERUL VIZIBIL printre ele (spre deosebire de neem)
      - placa din mijloc cea mai sus; cele laterale mai jos (streasina
        umbrelei); coroana mult mai lata decat groasa
      - baza coroanei la ~55% din inaltime; trunchiul si bratele se vad pe
        ~3,3 m
      - verde (acelasi slot ca la neem; diferenta e silueta)
    Cote: 6 m inaltime, ~7,4 m latime (h/l 0,81). Buget <= 400 tri.
    """
    bt = Builder()
    # trunchiul rasucit: S usor pe Y si X
    bt.taper_sweep([(0, 0, -0.05), (0.10, -0.12, 0.6), (-0.08, 0.06, 1.15),
                    (0.05, 0.0, 1.6)], [0.44, 0.30, 0.27, 0.25], BARK_LIGHT,
                   segments=6, cap_start=False, cap_end=False)
    fork = Vector((0.05, 0.0, 1.55))
    arm_l = Vector((0.2, -1.5, 3.2))
    arm_r = Vector((0.0, 1.45, 3.1))
    bt.taper_sweep([fork, arm_l], [0.24, 0.17], BARK_LIGHT, segments=5,
                   cap_start=False, cap_end=False)
    bt.taper_sweep([fork, arm_r], [0.24, 0.17], BARK_LIGHT, segments=5,
                   cap_start=False, cap_end=False)
    plates = [  # (centru, marime) -- placi late, turtite
        ((0.0, 0.1, 5.3), (4.2, 3.8, 1.3)),       # mijloc, sus
        ((0.3, -2.2, 4.55), (3.8, 3.4, 1.2)),     # stanga
        ((0.1, 2.2, 4.6), (3.8, 3.4, 1.2)),       # dreapta
        ((1.9, -0.5, 4.25), (3.4, 3.0, 1.1)),     # fata
        ((-1.9, 0.6, 4.5), (3.4, 3.0, 1.1)),      # spate
    ]
    for c, s in plates:
        if c[1] < -1.0:
            src = arm_l
        elif c[1] > 1.0:
            src = arm_r
        else:
            src = arm_l if c[0] > 0.5 else arm_r
        tip = Vector((c[0] * 0.8, c[1] * 0.8, c[2] - s[2] * 0.2))
        bt.taper_sweep([src, tip], [0.15, 0.08], BARK_LIGHT, segments=5,
                       cap_start=False, cap_end=False)
    trunk = bt.to_object("Trunk")

    bc = Builder()
    for k, (c, s) in enumerate(plates):
        bc.boulder(c, s, LEAF, seed=811 + k * 17, segments=8, rings=3,
                   deviation=0.12)
    top_faces_to(bc, LEAF, LEAF_TOP, nz=0.8)
    crown = bc.to_object("Crown")
    return [trunk, crown]


# ===========================================================================
# 3. CANDELELE
# ===========================================================================

def _diya_bowl(b, cx, cy, cz, scale, closed_bottom=True):
    """Castronelul de lut, 6 laturi: talpa (4 tri), flancuri (12), interior
    in palnie cu centrul coborat (6) = 22 tri. Rimul are un CIOC (varful de pe
    +Y tras in afara): acolo sta fitilul. Flacara o face shaderul `diya_flame`
    (brief §1.8), nu geometria."""
    n = 6
    r_bot, r_rim, h, depth = 0.034 * scale, 0.050 * scale, 0.050 * scale, 0.022 * scale
    bot, rim = [], []
    for i in range(n):
        a = math.pi * 0.5 + 2.0 * math.pi * i / n     # i=0 pe +Y (ciocul)
        rr = r_rim * (1.25 if i == 0 else 1.0)
        rz = h * (1.06 if i == 0 else 1.0)            # ciocul usor ridicat
        bot.append(b.bm.verts.new((cx + math.cos(a) * r_bot, cy + math.sin(a) * r_bot, cz)))
        rim.append(b.bm.verts.new((cx + math.cos(a) * rr, cy + math.sin(a) * rr, cz + rz)))
    centre = b.bm.verts.new((cx, cy, cz + h - depth))
    side, inner = [], []
    for i in range(n):
        j = (i + 1) % n
        side.append(b.bm.faces.new((bot[i], bot[j], rim[j], rim[i])))
        inner.append(b.bm.faces.new((rim[i], rim[j], centre)))
    if closed_bottom:
        side.append(b.bm.faces.new(tuple(reversed(bot))))
    for f in side:
        f[b.slot] = CLAY
    for f in inner:
        f[b.slot] = OIL
    return side + inner


def diya():
    """Candela de lut (fara decupare pe planșa -- brief §1.7 o descrie):

      - castronel de lut ars, O 0,10 m, 0,05 m inaltime, gura mai lata ca talpa
      - un cioc (fitilul) pe o latura, spre +Y
      - interiorul mai inchis (ulei), in palnie
      - flacara NU (shaderul `diya_flame`)
      - O SINGURA plasa (FlockProp), <= 24 tri
    """
    b = Builder()
    _diya_bowl(b, 0.0, 0.0, 0.0, 1.0)
    return b.to_object("Diya")


def floating_diya():
    """Candela plutitoare (fara decupare pe planșa):

      - talger de FRUNZA, O 0,25 m, verde (TROPICAL_GREEN), marginea usor
        ridicata (talger, nu disc plat), cu varful frunzei spre +Y
      - pe mijloc, aceeasi candela de lut ca `diya`, putin mai mica
      - O SINGURA plasa, <= 40 tri
    """
    b = Builder()
    n = 8
    rim = []
    for i in range(n):
        a = math.pi * 0.5 + 2.0 * math.pi * i / n
        k = 1.12 if i == 0 else (0.94 if i == n // 2 else 1.0)  # varful frunzei
        rim.append(b.bm.verts.new((math.cos(a) * 0.118 * k,
                                   math.sin(a) * 0.118 * k, 0.020)))
    top_c = b.bm.verts.new((0.0, 0.0, 0.010))
    bot_c = b.bm.verts.new((0.0, 0.0, 0.0))
    leaf = []
    for i in range(n):
        j = (i + 1) % n
        leaf.append(b.bm.faces.new((rim[i], rim[j], top_c)))
        leaf.append(b.bm.faces.new((rim[j], rim[i], bot_c)))
    for f in leaf:
        f[b.slot] = LEAF_PLATE
    _diya_bowl(b, 0.0, -0.01, 0.009, 0.85, closed_bottom=True)
    return b.to_object("Floating_Diya")


# ===========================================================================

def run(fn, path, ao, blend, budget, smooth_angle=None):
    clear_built()
    made = fn()
    objs = made if isinstance(made, list) else [made]
    emit(objs, path, ao, smooth_angle=smooth_angle, budget=budget)
    save_blend(objs, blend)


if __name__ == "__main__":
    # stanca: umbrire plata (fatetele planșei), fara bevel
    run(boulder_a, "rocks/rhyolite_boulder_a.glb", AO_ROCK, "jodhpur_rhyolite_boulder_a.blend", 200)
    run(boulder_b, "rocks/rhyolite_boulder_b.glb", AO_ROCK, "jodhpur_rhyolite_boulder_b.blend", 200)
    run(boulder_c, "rocks/rhyolite_boulder_c.glb", AO_ROCK, "jodhpur_rhyolite_boulder_c.blend", 200)
    run(rock_slab, "rocks/rock_slab.glb", AO_ROCK, "jodhpur_rock_slab.blend", 200)
    # plantele: coloanele raman muchiate (unghi mic), coroanele netede
    run(euphorbia, "plants/euphorbia.glb", AO_SMALL, "jodhpur_euphorbia.blend", 300,
        smooth_angle=30.0)
    run(neem_tree, "plants/neem_tree.glb", AO_TREE, "jodhpur_neem_tree.blend", 400,
        smooth_angle=65.0)
    run(khejri_tree, "plants/khejri_tree.glb", AO_TREE, "jodhpur_khejri_tree.blend", 400,
        smooth_angle=65.0)
    run(diya, "props/diya.glb", AO_TINY, "jodhpur_diya.blend", 24)
    run(floating_diya, "props/floating_diya.glb", AO_TINY, "jodhpur_floating_diya.blend", 40)

    print("== Jodhpur natura ==")
    bad = 0
    for path, tris, d, budget, per_node, kb in results:
        flag = "OK" if budget is None or tris <= budget else "DEPASIT"
        if flag != "OK":
            bad += 1
        nodes = ", ".join("%s=%d" % kv for kv in per_node.items())
        print("  %-32s %4d / %4s tri %-8s %.2f x %.2f x %.2f m  [%s]"
              % (path, tris, budget, flag, d.x, d.y, d.z, nodes))
    print("  bugete depasite:", bad)
