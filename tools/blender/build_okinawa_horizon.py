"""Okinawa v2 -- FUNDAL (brief docs/asset_briefs/okinawa_kit_v2.md §1.7).

  okinawa/effects/okinawa_horizon.glb   4 siluete, fiecare UN nod copil direct al radacinii:
    IeIsland_A   insula Ie: platou jos ~120 x 60 x 8 m cu UN singur con abrupt
                 (~45 m inaltime totala), excentric
    Kerama_A/B/C insule joase, impadurite, cu faleze palide: 40-90 m lungime,
                 12-25 m inaltime

CONSUMATORUL (`Track._build_horizon`, `horizon_model` in tema `okinawa`) pastreaza
UN nod dupa nume exact si il recentreaza pe `-kept.position`, deci:
  - cate un nod pe silueta, ORIGINEA LA BAZA: XY centrat pe bbox-ul nodului, Z min = 0
    (rotatia pe Y roteste silueta pe loc);
  - VOLUME INCHISE citibile din orice azimut (cate un corp inchis per lob);
  - fatete MARI (la 190-340 m si scara 1,3-2,4x detaliul fin e zgomot; memoria
    `silueta-inainte-de-umbrire`); umbrire plata (`flat_ao`);
  - fara coliziune, `cast_shadow` OFF la integrare (memoria `caster-departat-fura-umbra`).
Sloturi: TROPICAL_GREEN 21 (padure), MARBLE_GREY 29 (falezele palide), cateva
fatete CACTUS_GREEN 12 (al doilea ton de verde, deterministe).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_okinawa_horizon.py
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "okinawa_shapes.py")).read())

clear_built()

FOREST, FOREST2, CLIFF = TROPICAL_GREEN, CACTUS_GREEN, MARBLE_GREY
AO_FAR = dict(samples=12, dist=25.0, gradient="vertical", low=0.6, high=1.0,
              power=0.85, floor=0.3)


def _hash01(x, y, z, seed):
    h = math.sin(x * 12.9898 + y * 78.233 + z * 37.719 + seed * 4.1) * 43758.5453
    return h - math.floor(h)


def speckle(b, slot, prob, z_lo, z_hi, seed, only_slot=None):
    """Re-coloreaza determinist o fractie din fetele dintre z_lo si z_hi (al doilea
    ton de verde / pete de stanca), fara geometrie in plus."""
    for f in b.bm.faces:
        c = f.calc_center_median()
        if not (z_lo <= c.z <= z_hi):
            continue
        if only_slot is not None and f[b.slot] != only_slot:
            continue
        if _hash01(c.x, c.y, c.z, seed) < prob:
            f[b.slot] = slot


def lobe(b, cx, cy, L, H, seed, aspect=0.36, base_z=0.0, cliff_top=0.22, jag=0.13, seg=12,
         tilt=0.0):
    """Insula joasa = un corp inchis din 5 inele: faleza palida verticala (primele
    doua benzi, MARBLE_GREY), apoi povarnisul impadurit (TROPICAL_GREEN) pana la
    un varf. `L` lungime (X), latimea = aspect * L, `H` inaltime."""
    rx0 = L * 0.5
    ry0 = L * aspect
    prof = [(0.0, 1.0), (cliff_top * 0.55, 0.97), (cliff_top, 0.82), (0.58, 0.46), (0.82, 0.19)]
    rings = [(base_z + H * t, rx0 * f, ry0 * f, cx + tilt * H * t, cy) for t, f in prof]
    pts, _ = ring_points(rings, seg, seed, jag)
    faceted_shell(b, pts, FOREST, slot_of=lambda k, z: CLIFF if k < 2 else FOREST,
                  top_pt=Vector((cx + tilt * H, cy, base_z + H)))


def settle(b, name):
    """Muta corpul: bbox centrat pe XY, baza la z=0 (originea nodului la baza)."""
    vs = b.bm.verts
    xs = [v.co.x for v in vs]; ys = [v.co.y for v in vs]; zs = [v.co.z for v in vs]
    d = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5, -min(zs)))
    for v in vs:
        v.co += d
    return b.to_object(name)


# ---------------------------------------------------------------------------

def build_ie():
    """`ie_island` (decuparea `ie_island.png`; contractul de cote castiga: platou
    jos + UN con) -- LISTA DE ELEMENTE:

    1) PLATOU jos: 120 x 60 m, 8 m inaltime, 22 laturi, 4 inele: banda de jos
       (0..2,5 m) FALEZA palida MARBLE_GREY, deasupra padure TROPICAL_GREEN cu
       ~20% fatete de al doilea verde; capac plat sus.
    2) UN SINGUR CON abrupt, excentric (cu 20 m spre -X si 4 m spre +Y fata de
       centrul platoului): baza ~40 x 36 m la cota 7,5, varful la 45 m total
       (37 m de con), 12 laturi, 6 inele (profil usor concav spre varf); ~28%
       fatete de al doilea ton, ~14% pete de stanca MARBLE_GREY pe flancul de jos
       (coastele din decupare). Varful usor deplasat (+1,5 m) fata de axa.
    Fara coliziune; origine la baza, XY centrat pe bbox.
    """
    b = Builder()
    pl = [(0.0, 60.0, 30.0, 0.0, 0.0), (2.5, 59.0, 29.2, 0.0, 0.0), (6.0, 56.0, 27.5, 0.0, 0.0),
          (8.0, 50.0, 24.0, 0.0, 0.0)]
    pts, _ = ring_points(pl, 22, 31, 0.05)
    faceted_shell(b, pts, FOREST, slot_of=lambda k, z: CLIFF if k == 0 else FOREST)
    speckle(b, FOREST2, 0.2, 2.5, 7.9, 3, only_slot=FOREST)
    cx, cy = -20.0, 4.0
    cone = [(7.5, 20.0, 18.0, cx, cy), (15.0, 16.0, 14.5, cx, cy), (23.0, 12.0, 11.0, cx + 0.3, cy),
            (31.0, 8.0, 7.6, cx + 0.8, cy), (38.0, 4.6, 4.3, cx + 1.2, cy), (43.0, 2.0, 1.9, cx + 1.5, cy)]
    pts, _ = ring_points(cone, 12, 17, 0.12)
    faceted_shell(b, pts, FOREST, cap_bottom=False, top_pt=Vector((cx + 1.5, cy, 45.0)))
    speckle(b, FOREST2, 0.28, 9.0, 44.0, 5, only_slot=FOREST)
    speckle(b, CLIFF, 0.14, 9.0, 22.0, 9, only_slot=FOREST)
    return settle(b, "IeIsland_A")


def build_kerama_a():
    """`kerama_islands` (insula mare din stanga-centru a decuparii) -- LISTA:
    DOI LOBI suprapusi pe o fundatie comuna: lob 1 (50 m lung, 25 m inalt, cx -19),
    lob 2 (44 m lung, 19 m inalt, cx +22); fiecare 5 inele x 12 laturi: faleza
    palida (banda de jos), povarnis impadurit, doua varfuri (creasta in doua
    cocoase). ~90 m lungime totala, ~25 m inaltime. 18% fatete de al doilea verde."""
    b = Builder()
    lobe(b, -19.0, 0.0, 50.0, 25.0, 41)
    lobe(b, 22.0, 2.0, 44.0, 19.0, 42, tilt=0.05)
    speckle(b, FOREST2, 0.18, 4.0, 40.0, 11, only_slot=FOREST)
    return settle(b, "Kerama_A")


def build_kerama_b():
    """`kerama_islands` (insula din dreapta, cu falezele rosietice la baza) --
    LISTA: un lob principal (60 m lung, 18 m inalt, varf usor aplecat spre +X) +
    un umar mai jos (24 m lung, 11 m inalt, cx +20) pe partea scurta; faleza
    palida pe jumatatea de jos a lobului, povarnis impadurit. 60 m x 18 m."""
    b = Builder()
    lobe(b, -6.0, 0.0, 48.0, 18.0, 51, tilt=0.12, cliff_top=0.26)
    lobe(b, 22.0, 3.0, 24.0, 11.0, 52)
    speckle(b, FOREST2, 0.18, 3.0, 30.0, 12, only_slot=FOREST)
    return settle(b, "Kerama_B")


def build_kerama_c():
    """`kerama_islands` (insulele mici din spate) -- LISTA: doua mamelonuri joase
    (30 m x 12 m si 22 m x 9 m) unite la baza, creasta lunga si joasa, falezele
    palide mai inalte (cliff_top 0,42), ~46 m lungime, 12 m inaltime."""
    b = Builder()
    lobe(b, -6.0, 0.0, 30.0, 12.0, 61, cliff_top=0.28)
    lobe(b, 14.0, -1.5, 22.0, 9.0, 62, cliff_top=0.28)
    speckle(b, FOREST2, 0.18, 2.0, 20.0, 13, only_slot=FOREST)
    return settle(b, "Kerama_C")


objs = [build_ie(), build_kerama_a(), build_kerama_b(), build_kerama_c()]
emit_ok_placed(objs, "effects/okinawa_horizon.glb", AO_FAR, budget=3000, flat_ao=True)
report_ok()
