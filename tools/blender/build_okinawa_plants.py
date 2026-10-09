"""Okinawa v2 -- plantele (brief docs/asset_briefs/okinawa_kit_v2.md §1.3).

  okinawa/plants/fukugi_tree_a.glb   stalp de frunzis 7 m x 2,8 m   (Fukugi_Bark, Fukugi_Leaves)
  okinawa/plants/fukugi_tree_b.glb   8,5 m x 3 m, mai zvelt, varf ascutit
  okinawa/plants/fukugi_tree_c.glb   5,5 m x 2,6 m, plin, o masa laterala
  okinawa/plants/ryukyu_pine.glb     pin bonsai 9 m x 9 m              (Pine_Bark, Pine_Leaves)
  okinawa/plants/cycad.glb           cicada 2,2 m x 2,6 m              (Cycad_Bark, Cycad_Leaves)
  okinawa/plants/fan_palm.glb        palmier-evantai 6 m               (Palm_Bark, Palm_Leaves)
  okinawa/plants/bougainvillea.glb   tufa cu spatele plat 1,6 x 2,4 m  (Bougainvillea_Leaves, Bougainvillea_Bloom)

Plantele merg pe MultiMesh: UN mesh compact per material, origine la baza
trunchiului (la bougainvillea: la baza peretelui de care se lipeste), scala
aplicata pe radacini. Primitive rotunde cu `segments` setat (6-10).
Vocabularul (`foliage_column`, `foliage_pillow`, `ring_trunk`, `pleated_fan`,
`serrated_frond`) e la finalul `okinawa_shapes.py`.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_okinawa_plants.py
Variabila de mediu OK_ONLY=<piesa> reface doar piesa respectiva.

Fara text, cifre sau logo-uri (regula 9).
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "okinawa_shapes.py")).read())

clear_built()

LEAF = TROPICAL_GREEN      # 21
LEAF2 = CACTUS_GREEN       # 12 (cicada, palmier)
DRY = DRY_VEGETATION       # 13
BARK = WOOD                # 9
BARK_D = LOG_DARK          # 28
BLOOM = FLAMINGO_PINK      # 31 (--allow-slots=31)


def _norm(o):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(o.data)
    bm.free()


def _stub(b, h=1.25, r0=0.30):
    """Ciotul de trunchi al fukugi: ~0,8 m se vad sub frunzis, restul intra in
    el. Doua tronsoane (baza WOOD, partea umbrita LOG_DARK). Primele puncte au
    acelasi xy (lectia banyanului: primul inel al unui sweep inclinat intra
    sub sol)."""
    b.taper_sweep([(0, 0, 0.0), (0, 0, 0.30), (0.02, 0.0, 0.62)],
                  [r0 * 1.15, r0 * 0.9, r0 * 0.8], BARK, segments=7)
    b.taper_sweep([(0.02, 0.0, 0.62), (0.04, 0.02, 1.0), (0.04, 0.03, h)],
                  [r0 * 0.85, r0 * 0.7, r0 * 0.55], BARK_D, segments=7)


# ---------------------------------------------------------------------------
# fukugi -- piesa critica (stalp de frunzis, NU coroana rotunda de pe planse)
# ---------------------------------------------------------------------------

def build_fukugi(variant):
    """Fukugi (Garcinia subelliptica), 3 variante.

    LISTA DE ELEMENTE (urmeaza CORECTURA de coordonator din kit §0.1/sus, nu
    decuparea: pe planse sunt foioase cu coroana rotunda, trunchi la vedere,
    verde deschis, toate trei la fel -- GRESIT; din decupare iau doar textura
    vizuala a frunzisului: mase fatetate cu ciorchini mici pe margine):
      a) 7,0 x 2,8 m (h/l 2,5): 6 mase de frunzis suprapuse pe verticala (elipsoizi
         ~1,8 m inalti, pas ~0,9 m), fiecare cu 3 ciorchini pe margine; laturile
         aproape drepte cu valuri de +-7% intre mase pare/impare; varf ROTUNJIT
         (ultima masa la 68% din raza); frunzisul incepe la 0,8 m de sol
      b) 8,5 x 3,0 m (h/l 2,8): 7 mase, mai zvelt; ultimele trei se ingusteaza
         (88/66/40%), masa de sus inalta (x1,45) -> varf ASCUTIT
      c) 5,5 x 2,6 m (h/l 2,1): 5 mase PLINE (ciorchini 4 per masa, mai mari),
         coloana de ~2,1 m + O MASA LATERALA iesita spre +X la ~2,3 m inaltime
         (asimetric, bbox ajunge la 2,6 m)
      d) trunchi: DOAR un ciot de ~0,8 m vizibil (WOOD jos, LOG_DARK sus), r 0,3 m
      e) fara flori/fructe; fara vegetatie lipita; verde inchis lucios: slotul 21
         e mai deschis decat tinta #2E5A2C, tenta de clasa il intuneca la integrare
    Noduri: Fukugi_Bark (WOOD 9 / LOG_DARK 28), Fukugi_Leaves (TROPICAL_GREEN 21).
    """
    spec = {
        "a": dict(H=7.0, W=2.6, n=6, tip="round", seed=11, sat=7, sat_scale=0.27),
        "b": dict(H=8.5, W=2.85, n=7, tip="sharp", seed=23, sat=7, sat_scale=0.26),
        "c": dict(H=5.5, W=2.0, n=5, tip="round", seed=37, sat=7, sat_scale=0.30,
                  wobble=0.05),
    }[variant]
    bark, leaves = Builder(), Builder()
    _stub(bark, r0=0.20 if variant != "b" else 0.18)
    # H se corecteaza usor in sus: polii boulder-ului scad cativa cm din cota
    spec = dict(spec)
    spec["H"] = spec["H"] + {"a": 0.10, "b": 0.12, "c": 0.08}[variant]
    cols = foliage_column(leaves, slot=LEAF, **spec)
    if variant == "c":
        # masa laterala iesita (asimetric): elipsoid + ciorchini, spre +X
        cx, cz = 0.80, 2.45
        leaves.boulder((cx, 0.0, cz), (1.5, 1.4, 1.5), LEAF, seed=401,
                       segments=9, rings=4, deviation=0.14)
        for k, (dx, dz) in enumerate(((0.35, -0.35), (0.25, 0.4), (-0.1, 0.1))):
            leaves.boulder((cx + dx, (k - 1) * 0.35, cz + dz), (0.9, 0.8, 0.7), LEAF,
                           seed=410 + k, segments=7, rings=3, deviation=0.15)
    return [leaves.to_object("Fukugi_Leaves"), bark.to_object("Fukugi_Bark")]


# ---------------------------------------------------------------------------
# pinul Ryukyu
# ---------------------------------------------------------------------------

def build_pine():
    """Pin Ryukyu (bonsai urias), `ryukyu_pine`.

    LISTA DE ELEMENTE (din decuparea `ryukyu_pine.png` + contractul §1.3):
      a) 1 trunchi gros, rasucit si aplecat, 6 puncte pe traseu, r 0,75 -> 0,2,
         radacina evazata la baza
      b) 4 brate: stanga-jos (cel mai lung, orizontal, se ridica la capat),
         dreapta-mijloc, spate/fata la ~5,9 m, plus lider vertical spre varf
      c) 7 PERNE de frunzis turtite (h/l ~0,3) cu goluri intre ele: cate una la
         capatul fiecaruia dintre cele 3 brate laterale + una mica deasupra
         celei din stanga, 2 pe varf (coroana, cu gol intre ele) -- nu glob
      d) FARA stanci, tufe si nisip de la baza (nu intra in GLB, kit §0.1)
    Cote tinta: 9 m x ~9 m. Noduri: Pine_Bark (WOOD 9, LOG_DARK 28 pe brate
    umbrite), Pine_Leaves (TROPICAL_GREEN 21).
    """
    bark, leaves = Builder(), Builder()
    trunk = [(0, 0, 0.0), (0, 0, 0.35), (0.9, 0.3, 1.3), (1.6, 0.0, 2.6),
             (1.0, -0.4, 4.0), (1.3, 0.1, 5.4), (0.7, 0.0, 6.6)]
    bark.taper_sweep(trunk, [0.80, 0.74, 0.64, 0.52, 0.44, 0.36, 0.28], BARK,
                     segments=8)
    # radacina evazata: pinteni scurti la baza
    for k in range(4):
        a = 0.8 + k * 1.6
        d = Vector((math.cos(a), math.sin(a), 0.0))
        bark.taper_sweep([d * 0.55, d * 0.55 + Vector((0, 0, 0.12)),
                          d * 0.95 + Vector((0, 0, 0.05)),
                          d * 1.35 + Vector((0, 0, 0.0))],
                         [0.26, 0.24, 0.16, 0.0], BARK, segments=5)
    # lider spre varf
    bark.taper_sweep([(0.7, 0.0, 6.5), (0.6, 0.0, 7.3), (0.5, 0.0, 8.2)],
                     [0.28, 0.2, 0.12], BARK_D, segments=6)
    arms = [
        # (puncte, raze, perna: centru, w, d, h, tilt)
        ([(1.6, 0.0, 2.5), (0.3, 0.7, 3.3), (-1.6, 0.9, 3.9), (-2.9, 0.8, 4.4)],
         [0.30, 0.24, 0.17, 0.11]),
        ([(1.0, -0.4, 3.9), (1.9, -0.3, 3.9), (2.7, -0.4, 4.1)],
         [0.26, 0.19, 0.12]),
        ([(1.3, 0.1, 5.3), (1.0, -1.3, 5.6), (0.55, -2.4, 5.9)],
         [0.22, 0.17, 0.11]),
        ([(-1.6, 0.9, 3.9), (-1.8, 0.6, 4.8), (-1.5, 0.3, 5.6)],
         [0.14, 0.11, 0.08]),
    ]
    for pts, rad in arms:
        bark.taper_sweep([Vector(p) for p in pts], rad, BARK_D, segments=6)
    pillows = [
        ((-3.0, 0.8, 4.95), 3.8, 3.3, 1.4, 5.0, 200),     # stanga-jos
        ((-1.4, 0.3, 6.25), 2.8, 2.5, 1.2, -4.0, 210),    # stanga-sus (mica)
        ((2.7, -0.4, 4.7), 3.4, 3.0, 1.4, -6.0, 220),     # dreapta
        ((0.55, -2.4, 6.5), 3.1, 2.9, 1.3, 5.0, 230),     # spate
        ((0.6, 0.1, 7.7), 4.6, 4.0, 1.7, 0.0, 240),       # coroana
        ((0.7, 0.2, 8.5), 2.6, 2.3, 1.0, 4.0, 250),       # varf
        ((-0.6, 1.9, 5.5), 2.4, 2.1, 1.0, 3.0, 260),      # fata, jos
    ]
    for c, w, d, h, tilt, seed in pillows:
        foliage_pillow(leaves, c, w, d, h, LEAF, seed=seed, bumps=2,
                       tilt_deg=tilt, tilt_azim_deg=seed)
    # ramura scurta pana la pernita din fata
    bark.taper_sweep([Vector((1.0, -0.4, 3.9)), Vector((0.2, 1.0, 4.6)),
                      Vector((-0.5, 1.8, 5.0))], [0.17, 0.12, 0.08], BARK_D,
                     segments=6)
    return [leaves.to_object("Pine_Leaves"), bark.to_object("Pine_Bark")]


# ---------------------------------------------------------------------------
# cicada
# ---------------------------------------------------------------------------

def build_cycad():
    """Cicada (sotetsu), `cycad`.

    LISTA DE ELEMENTE (din decuparea `cycad.png`):
      a) trunchi scurt si gros (0,7 m, r 0,36), usor bombat
      b) solzi in geometrie: 3 randuri x 8 bulgari (decalate cu 22 grade intre
         randuri -> model in romburi), ca ananasul de pe planse
      c) rozeta de 16 frunze rigide penate arcuite, in 3 etaje: 6 interioare
         abrupte (urca la ~2,2 m), 6 intermediare, 4 exterioare joase cu varful
         lasat; fiecare cu 9 statii, marginea dintata (alternanta de latime)
      d) FARA stanci/nisip de la baza
    Cote tinta: 2,2 m x 2,6 m. Noduri: Cycad_Bark (WOOD 9 / LOG_DARK 28),
    Cycad_Leaves (CACTUS_GREEN 12 + TROPICAL_GREEN 21).
    """
    bark, leaves = Builder(), Builder()
    bark.taper_sweep([(0, 0, 0.0), (0, 0, 0.12), (0, 0, 0.55), (0, 0, 1.05)],
                     [0.40, 0.38, 0.34, 0.26], BARK_D, segments=8)
    for row, z in enumerate((0.22, 0.50, 0.78)):
        r = 0.40 - row * 0.045
        off = math.radians(22.5) * (row % 2)
        for k in range(8):
            a = off + k * math.pi / 4
            bark.boulder((math.cos(a) * r, math.sin(a) * r, z),
                         (0.30, 0.30, 0.26), BARK, seed=500 + row * 8 + k,
                         segments=6, rings=3, deviation=0.14)
    tiers = [  # (n, elev, length, droop, start_z, base_r)
        (5, 72.0, 1.30, 0.25, 1.00, 0.08),
        (5, 52.0, 1.45, 0.45, 0.96, 0.14),
        (4, 32.0, 1.40, 0.70, 0.88, 0.22),
    ]
    rnd = _lcg(77)
    fi = 0
    for ti, (n, elev, L, droop, z0, br) in enumerate(tiers):
        for k in range(n):
            az = 360.0 * k / n + ti * 31.0 + (rnd() - 0.5) * 14.0
            ar = math.radians(az)
            base = (math.cos(ar) * br, math.sin(ar) * br, z0)
            slot = LEAF2 if fi % 2 else LEAF
            serrated_frond(leaves, base, az, L * (0.93 + 0.14 * rnd()), 0.30,
                           elev + (rnd() - 0.5) * 8.0, slot, droop=droop,
                           stations=11, tooth=0.62)
            fi += 1
    return [leaves.to_object("Cycad_Leaves"), bark.to_object("Cycad_Bark")]


# ---------------------------------------------------------------------------
# palmier-evantai
# ---------------------------------------------------------------------------

def build_fan_palm():
    """Palmier-evantai (Livistona), `fan_palm` -- NU cocotier.

    LISTA DE ELEMENTE (din decuparea `fan_palm.png`):
      a) trunchi drept, usor subtiat (r 0,25 -> 0,17), 4,9 m, cu INELE in geometrie
         la fiecare 0,36 m (14 inele), baza usor evazata
      b) coroana de 11 frunze in EVANTAI ROTUND PLISAT (disc cu 7 pliuri, margine
         dintata, raza ~1,05 m) pe petioli arcuiti, in 2 etaje: 5 ridicate
         (intre 35 si 62 grade) + 6 mai plate si mai largi
      c) 3 frunze USCATE atarnate sub coroana (DRY_VEGETATION 13), mai mici
      d) FARA stanci/nisip la baza
    Cote tinta: 6 m inalt, coroana ~4 m. Noduri: Palm_Bark (WOOD 9 / LOG_DARK 28
    pe inele), Palm_Leaves (TROPICAL_GREEN 21 + CACTUS_GREEN 12 + DRY 13).
    """
    bark, leaves = Builder(), Builder()
    TH = 4.3
    ring_trunk(bark, [(0, 0, 0.0), (0, 0, 0.3), (0.05, 0.0, 2.4), (0.0, 0.05, TH)],
               [0.30, 0.25, 0.21, 0.16], BARK, BARK_D, ring_every=0.30, seg=7,
               ring_grow=1.18, ring_h=0.13)
    top = Vector((0.0, 0.05, TH))
    rnd = _lcg(91)

    def petiole_fan(az_deg, elev_deg, plen, R, slot, spread_n_tilt, drop=0.0):
        a = math.radians(az_deg)
        dh = Vector((math.cos(a), math.sin(a), 0.0))
        e = math.radians(elev_deg)
        u = (dh * math.cos(e) + Vector((0, 0, math.sin(e)))).normalized()
        end = top + u * plen + Vector((0, 0, -drop))
        mid = top + u * plen * 0.5 + Vector((0, 0, plen * 0.14))
        bark.taper_sweep([top, mid, end], [0.055, 0.045, 0.035], BARK_D, segments=4)
        # normala evantaiului: perpendiculara pe u, spre sus si spre interior
        side = Vector((-dh.y, dh.x, 0.0))
        n = u.cross(side).normalized() * -1.0
        if n.z < 0:
            n = -n
        pleated_fan(leaves, end, u, n, R, slot, pleats=7, span_deg=250.0,
                    depth=0.06)

    # etajul inalt: 5 frunze
    for k in range(5):
        az = 360.0 * k / 5 + 12.0 + (rnd() - 0.5) * 16.0
        petiole_fan(az, 38.0 + 22.0 * rnd(), 0.9, 1.05, LEAF if k % 2 else LEAF2, 0)
    # etajul plat: 6 frunze, mai largi, mai jos
    for k in range(6):
        az = 360.0 * k / 6 + 40.0 + (rnd() - 0.5) * 16.0
        petiole_fan(az, 6.0 + 16.0 * rnd(), 1.1, 1.15, LEAF2 if k % 2 else LEAF, 0)
    # 3 frunze uscate care atarna
    for k in range(3):
        az = 360.0 * k / 3 + 70.0
        a = math.radians(az)
        dh = Vector((math.cos(a), math.sin(a), 0.0))
        start = top + Vector((0, 0, -0.1))
        end = start + dh * 0.35 + Vector((0, 0, -0.55))
        bark.taper_sweep([start, start + dh * 0.28 + Vector((0, 0, -0.1)), end],
                         [0.05, 0.04, 0.03], BARK_D, segments=4)
        u = Vector((dh.x * 0.25, dh.y * 0.25, -1.0)).normalized()
        n = dh
        pleated_fan(leaves, end, u, n, 0.6, DRY, pleats=5, span_deg=170.0,
                    depth=0.04)
    return [leaves.to_object("Palm_Leaves"), bark.to_object("Palm_Bark")]


# ---------------------------------------------------------------------------
# bougainvillea
# ---------------------------------------------------------------------------

def build_bougainvillea():
    """Bougainvillea, varianta cu spatele plat (se lipeste de zid), `bougainvillea`.

    LISTA DE ELEMENTE (din decuparea `bougainvillea.png`; fara nisipul de la
    baza):
      a) tufa joasa si lata, 2,4 x 1,6 m, spatele TAIAT PLAT in planul y = 0
         (peretele); adancimea ~0,9 m
      b) ~8 mase de frunzis (TROPICAL_GREEN 21), dedesubt si printre flori, ca
         ciorchinii sa stea PESTE frunzis, nu in loc
      c) ~30 de ciorchini de flori magenta (FLAMINGO_PINK 31) pe fata dinspre +Y,
         care domina: acopera ~85% din suprafata vizibila
      d) 4 ciorchini care se REVARSA spre sol pe margini (curtina de jos)
    Noduri: Bougainvillea_Leaves (21), Bougainvillea_Bloom (31,
    --allow-slots=31). Origine: la baza peretelui, centrata pe X.
    """
    leaves, bloom = Builder(), Builder()
    rnd = _lcg(133)
    HW, HZ = 1.2, 1.55

    def shell_y(x, z):
        v = 1.0 - (x / (HW * 1.05)) ** 2 - ((z - 0.15) / (HZ * 1.1)) ** 2
        return 0.78 * math.sqrt(max(0.04, v))

    for k in range(10):
        x = -0.85 + 1.7 * k / 9.0 + (rnd() - 0.5) * 0.2
        z = 0.35 + 0.8 * rnd() * (1.0 - abs(x) / 1.3)
        leaves.boulder((x, 0.30, z), (0.95, 0.7, 0.8), LEAF, seed=600 + k,
                       segments=8, rings=4, deviation=0.16)
    centers = []
    for k in range(44):
        for _try in range(30):
            x = (rnd() * 2 - 1) * 0.92
            zmax = 0.30 + 1.2 * math.sqrt(max(0.0, 1.0 - (x / 1.12) ** 2))
            z = 0.22 + rnd() * (zmax - 0.1)
            if all((x - cx) ** 2 + (z - cz) ** 2 > 0.07 for cx, cz in centers):
                break
        centers.append((x, z))
        s = 0.36 + 0.16 * rnd()
        bloom.boulder((x, shell_y(x, z) - 0.06, z), (s, s * 0.9, s * 0.8), BLOOM,
                      seed=700 + k, segments=7, rings=3, deviation=0.17)
    # curtina: se revarsa spre sol pe margini
    for k, (x, z) in enumerate(((-1.0, 0.30), (0.98, 0.34), (-0.8, 0.18),
                                (0.76, 0.2))):
        bloom.boulder((x, 0.38, z), (0.38, 0.34, 0.38), BLOOM, seed=800 + k,
                      segments=7, rings=3, deviation=0.17)
    objs = [leaves.to_object("Bougainvillea_Leaves"),
            bloom.to_object("Bougainvillea_Bloom")]
    # spatele plat: taie tot ce trece de planul peretelui (y < 0)
    for o in objs:
        for v in o.data.vertices:
            v.co.z *= 0.91
            v.co.x *= 0.95
            if v.co.y < 0.0:
                v.co.y = 0.0
    return objs


# ---------------------------------------------------------------------------
# export
# ---------------------------------------------------------------------------

ONLY = os.environ.get("OK_ONLY", "")


def _want(name):
    return not ONLY or ONLY == name


AO_FUKUGI = dict(samples=22, dist=1.3, gradient="vertical", low=0.45, high=1.0,
                 power=0.8, floor=0.22)
AO_PINE = dict(samples=22, dist=2.0, gradient="vertical", low=0.55, high=1.0,
               power=0.8, floor=0.25)
AO_SMALL = dict(samples=22, dist=0.9, gradient="vertical", low=0.55, high=1.0,
                power=0.85, floor=0.25)


def _emit(objs, path, ao, zmax):
    for o in objs:
        _norm(o)
    ao = dict(ao, z_range=(0.0, zmax))
    emit_ok(objs, path, ao, keep_xy=True, bevel=0.0, smooth_angle=48.0)
    # numele de noduri trebuie sa ramana curate (fara .001) intre piese
    for o in objs:
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.meshes.remove(me)


for v, zmax in (("a", 7.2), ("b", 8.7), ("c", 5.7)):
    if _want("fukugi_tree_" + v):
        _emit(build_fukugi(v), "plants/fukugi_tree_%s.glb" % v, AO_FUKUGI, zmax)
if _want("ryukyu_pine"):
    _emit(build_pine(), "plants/ryukyu_pine.glb", AO_PINE, 9.2)
if _want("cycad"):
    _emit(build_cycad(), "plants/cycad.glb", AO_SMALL, 2.4)
if _want("fan_palm"):
    _emit(build_fan_palm(), "plants/fan_palm.glb", AO_PINE, 6.2)
if _want("bougainvillea"):
    _emit(build_bougainvillea(), "plants/bougainvillea.glb", AO_SMALL, 1.7)

report_ok()
