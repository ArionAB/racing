"""Kyoto (Track18) -- shishi-odoshi, hazardul-semnatura (brief kyoto.md §3, §5.2).

  kyoto/structures/shishi_odoshi.glb
      Frame        cadrul de piatra: doi stalpi de granit + axa de lemn
      Tube         bambusul de 16 m, O 1,8, cu 4 noduri; gura taiata oblic
      Kakei        jgheabul care toarna in gura cand tubul e sus
      StrikeStone  piatra pe care bate coada la revenire ("TOC")

CONTRACTUL e scris in `scenes/hazards/shishi_odoshi_hazard.gd` (nu in brief --
daca difera, codul castiga):

  - originea modelului = AXA PIVOTULUI. Modelul sta in `Pivot`, la 6,6 m
    deasupra soselei, deci solul e la Y = -6.6 in coordonate de model.
  - `Tube` se roteste pe X (`rotation.x = unghi`, + = gura in sus). Axa lui e Z:
    gura pe -Z (brat de 12 m), coada pe +Z (4 m). Cilindrul de coliziune al
    hazardului e centrat la z = -4, lung de 16 m, raza 0,9 -- adica tubul
    ocupa EXACT z in [-12, +4].
  - Blender: glTF converteste (x, y, z)_blender -> (x, z, -y)_godot, deci gura
    pe -Z Godot = +Y Blender, iar solul = Z = -6.6 in Blender.
  - NU se foloseste `finish(origin="base")` (ar muta pivotul): toate nodurile
    ies cu originea la (0,0,0) = axa. verify_glb `--origin=waterline`
    (geometria incaleca Y=0) e verificarea potrivita.

Piatra de lovire: la +35 deg (revenirea) capatul cozii coboara pana la
z = -3.03 (in model); piatra are fata de sus la -3.05, deci coada "bate" pe ea
(calculul e in comentariul de la `STONE_TOP`).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_kyoto_shishi.py
"""

import math
from mathutils import Vector, Matrix

# --- Sloturi (brief §4): bambus = 21 + 13; piatra = 29 + 8; lemn = 28 -------
GREEN = TROPICAL_GREEN      # 21 -- doar accent (coada), runda 2
DRY = DRY_VEGETATION        # 13 -- paie, trunchiul
STRAW = SAND_LIGHT          # 0  -- internoduri alternante, mai deschise
NODE = LOG_DARK             # 28 -- nodurile, lemn intunecat
OPEN = CORAL_SAND           # 19 -- buza si interiorul gurii (citeste „deschis")
ROPE = KERB_RED              # 7  -- legatura de langa gura (carmin; CAR_RED 14 e rezervat masinilor in verify)
WATER = FOAM_WHITE          # 22 -- firul de apa din jgheab
GRANITE = MARBLE_GREY       # 29 (la integrare capata clasa `granite`)
GRANITE_B = CONCRETE        # 8  -- a doua nuanta, ca blocurile sa nu iasa unul
DARK = LOG_DARK             # 28

PIVOT_H = 6.6               # cota pivotului din hazard (`pivot_height`)
GROUND = -PIVOT_H
R_COL = 0.9                 # raza de COLIZIUNE (tube_diameter / 2) -- nu se atinge
R_TUBE = 1.1                # raza VIZUALA: +0.2 m ca bara sa se citeasca de la 120 m
ARM = 12.0                  # tube_length - tail_length
TAIL = 4.0
SEG = 12                    # laturi pe tub (8-12 conform sarcinii)

# Capatul cozii la +35 deg (fill_start_deg), colt de jos al capacului:
#   z' = y sin a + z cos a,  y = -TAIL, z = -R  ->  -4*0.5736 - 0.9*0.8192
FILL_START = math.radians(35.0)
TAIL_LOW = -TAIL * math.sin(FILL_START) - R_TUBE * math.cos(FILL_START)  # cu raza vizuala
STONE_TOP = round(TAIL_LOW - 0.02, 3)   # 2 cm sub colt: se ating dupa bevel


def _ring(b, y_of_theta, r, n=SEG):
    """Inel de `n` varfuri in jurul axei Y; `y_of_theta(theta)` permite taierea
    oblica (aceeasi functie da si planul gurii)."""
    ring = []
    for k in range(n):
        t = 2.0 * math.pi * k / n
        ring.append(b.bm.verts.new((r * math.cos(t), y_of_theta(t), r * math.sin(t))))
    return ring


def _strip(b, lo, hi, slot, flip=False):
    n = len(lo)
    for k in range(n):
        j = (k + 1) % n
        quad = (lo[k], lo[j], hi[j], hi[k])
        f = b.bm.faces.new(tuple(reversed(quad)) if flip else quad)
        f[b.slot] = slot


def _cap(b, ring, slot, flip=False):
    f = b.bm.faces.new(tuple(reversed(ring)) if flip else tuple(ring))
    f[b.slot] = slot


# ---------------------------------------------------------------- Tube ------

def build_tube():
    b = Builder()
    const = lambda y: (lambda t: y)
    # Taiere oblica la 45 deg: marginea de jos (z = -R) ajunge la y = ARM, cea
    # de sus (z = +R) e cu 2R mai in spate. Deschiderea priveste in sus si spre
    # inainte -- exact ce primeste apa din jgheab.
    oblique = lambda t: ARM - (R_TUBE * math.sin(t) + R_TUBE)

    # Statii (y, raza, slot-ul fasiei care PORNESTE de la statia anterioara).
    nodes = [-2.3, 1.5, 4.9, 7.2]           # centrele celor 4 noduri de bambus
    col_r, col_w = R_TUBE + 0.1, 0.11       # inel ingrosat: +10 cm, ~44 cm lat
    stations = [(-TAIL, 0.85, None), (-TAIL + 0.14, R_TUBE, GREEN)]   # capac tesit
    # Runda 3: corp verde inchis (contrast de luminanta pe ceata deschisa), nod de
    # lemn intunecat, banda carmin LA FIECARE NOD (semn care se vede si pe padure).
    for i, y in enumerate(nodes):
        stations.append((y - 0.45, R_TUBE, GREEN))
        stations.append((y - 0.40, R_TUBE + 0.04, ROPE))
        stations.append((y - 0.15, R_TUBE + 0.04, ROPE))
        stations.append((y - col_w, col_r, NODE))
        stations.append((y + col_w, col_r, NODE))
        stations.append((y + 0.20, R_TUBE, NODE))
    # Legatura rosie, ~1 m lata, chiar in spatele gurii (semn pe varful tubului).
    # Raza +0.06 fata de tub: doar vizual, colizorul nu o vede.
    stations.append((8.1, R_TUBE, GREEN))
    stations.append((8.18, R_TUBE + 0.06, ROPE))
    stations.append((9.18, R_TUBE + 0.06, ROPE))
    stations.append((9.26, R_TUBE, ROPE))
    stations.append((9.5, R_TUBE, GREEN))   # ultimul internod, pana la taietura
    rings = []
    for y, r, _slot in stations:
        rings.append(_ring(b, const(y), r))
    _cap(b, rings[0], DARK, flip=True)      # coada inchisa: capac de lemn intunecat
    for i in range(1, len(rings)):
        _strip(b, rings[i - 1], rings[i], stations[i][2])

    # Gura: ultimul inel al corpului -> inelul oblic exterior -> buza -> interior.
    ro = _ring(b, oblique, R_TUBE)
    _strip(b, rings[-1], ro, GREEN)
    ri = _ring(b, oblique, R_TUBE - 0.2)
    _strip(b, ro, ri, OPEN, flip=False)      # grosimea peretelui, vizibila
    depth_y = 7.4
    rf = _ring(b, const(depth_y), R_TUBE - 0.2)
    _strip(b, ri, rf, OPEN, flip=True)      # peretele interior, deschis la culoare
    _cap(b, rf, DRY, flip=False)            # fundul
    return b.to_object("Tube")


# ---------------------------------------------------------------- Frame -----

def _stone_block(b, cx, cy, z0, z1, sx, sy, slot, yaw=0.0):
    rot = Matrix.Rotation(math.radians(yaw), 3, "Z") if yaw else None
    b.box((cx, cy, (z0 + z1) * 0.5), (sx, sy, z1 - z0), slot, rotation=rot)


def build_frame():
    b = Builder()
    post_x = 1.75
    top = 0.65
    for sgn in (-1.0, 1.0):
        x = sgn * post_x
        # Soclu lat, apoi blocuri suprapuse, putin decalate si rotite: granit
        # cioplit grosolan, nu un stalp strunjit.
        _stone_block(b, x, 0.0, GROUND - 0.3, GROUND + 0.75, 1.7, 2.1, GRANITE_B, yaw=3)
        _stone_block(b, x, 0.0, GROUND + 0.75, GROUND + 3.0, 1.2, 1.5, GRANITE, yaw=-2)
        _stone_block(b, x + sgn * 0.03, 0.02, GROUND + 3.0, GROUND + 5.3, 1.1, 1.35, GRANITE_B, yaw=2)
        _stone_block(b, x, 0.0, GROUND + 5.3, top - 0.35, 1.0, 1.25, GRANITE, yaw=-1)
        # Capul stalpului + lagarul de lemn pe care sta axa
        _stone_block(b, x, 0.0, top - 0.35, top, 1.2, 1.45, GRANITE_B)
        b.box((sgn * 1.4, 0.0, 0.05), (0.55, 0.8, 0.42), DARK)
    # Axa: grinda de lemn intunecat, trece prin tub (marginile ies in exterior).
    b.cylinder((0.0, 0.0, 0.0), 0.17, 4.3, DARK, segments=8, axis="X")
    # Capetele axei: doua dopuri mai groase, ca o cuie de fixare
    for sgn in (-1.0, 1.0):
        b.cylinder((sgn * 2.2, 0.0, 0.0), 0.26, 0.18, DARK, segments=8, axis="X")
    return b.to_object("Frame")


# ---------------------------------------------------------------- Kakei -----

def _trough(b, p1, p2, r_out, r_in, slot_out, slot_in, n=7):
    """Jgheab in U (semicilindru deschis in sus) intre doua puncte.

    Profil: arc exterior (de jos, 180 deg) + arc interior; capetele sunt poligoane
    in semiluna. Interiorul primeste alt slot (mai inchis) ca sa se citeasca
    deschis, nu ca o teava plina."""
    p1, p2 = Vector(p1), Vector(p2)
    d = (p2 - p1).normalized()
    s = d.cross(Vector((0, 0, 1))).normalized()
    u = s.cross(d).normalized()          # "sus" in planul sectiunii
    if u.z < 0:
        u = -u
    def prof(r, k):
        a = math.pi * k / n               # 0..pi, de la o buza la cealalta
        return s * (r * math.cos(a)) - u * (r * math.sin(a))
    ends = []
    for p in (p1, p2):
        outer = [b.bm.verts.new(p + prof(r_out, k)) for k in range(n + 1)]
        inner = [b.bm.verts.new(p + prof(r_in, k)) for k in range(n + 1)]
        ends.append((outer, inner))
    (o1, i1), (o2, i2) = ends
    for k in range(n):
        f = b.bm.faces.new((o1[k], o1[k + 1], o2[k + 1], o2[k]))
        f[b.slot] = slot_out
        f = b.bm.faces.new((i1[k + 1], i1[k], i2[k], i2[k + 1]))
        f[b.slot] = slot_in
    # buzele
    for k in (0, n):
        f = b.bm.faces.new((o1[k], i1[k], i2[k], o2[k]) if k == n
                           else (i1[k], o1[k], o2[k], i2[k]))
        f[b.slot] = slot_out
    # capete (semiluna)
    f = b.bm.faces.new(tuple(o1) + tuple(reversed(i1)))
    f[b.slot] = slot_out
    f = b.bm.faces.new(tuple(reversed(o2)) + tuple(i2))
    f[b.slot] = slot_out


def _collar(b, c, d, r, depth, slot, seg=8):
    """Inel scurt (cilindru) cu axa pe directia `d`: nod de bambus pe jgheab."""
    mat = Matrix.Translation(c) @ d.to_track_quat("Z", "Y").to_matrix().to_4x4()
    res = bmesh.ops.create_cone(b.bm, cap_ends=True, cap_tris=False, segments=seg,
                                radius1=r, radius2=r, depth=depth, matrix=mat)
    return b._tag(res["verts"], slot)


def build_kakei():
    b = Builder()
    # Capatul de varsare, deasupra gurii in prima jumatate a umplerii. La +35 deg
    # gura (deschiderea) acopera y in [7.8, 10.4]; la +8 deg, in [10.0, 12.0].
    # y = 10.0 prinde ambele. Calculat din unghiurile hazardului, nu ghicit.
    spout = Vector((0.0, 10.0, 8.7))
    start = Vector((2.7, -0.4, 11.2))
    _trough(b, start, spout, 0.42, 0.32, GREEN, DARK)
    # Firul de apa: scurt, din varf in jos. Tubul se invarte, deci un fir pana in
    # gura ar trece prin el la unghiuri mici; la +35 deg gura e chiar dedesubt.
    b.box((0.0, 10.0, 7.7), (0.16, 0.16, 2.0), WATER)
    # noduri de bambus pe jgheab
    for t in (0.18, 0.5, 0.82):
        c = start.lerp(spout, t)
        d = (spout - start).normalized()
        _collar(b, c, d, 0.42, 0.16, DRY)
    # Catargul de lemn (de pe mal) si doua contrafise inclinate
    mx, my = 2.7, -0.4
    b.box((mx, my, (GROUND + 11.2) * 0.5 - 0.1), (0.5, 0.5, 11.2 - GROUND + 0.5), DARK)
    for sgn in (-1.0, 1.0):
        b.beam((mx, my, 4.5), (mx + 1.2, my + sgn * 3.6, GROUND), (0.4, 0.4), DARK)
    b.beam((mx, my, 9.2), (mx, my + 1.4, 11.2), (0.32, 0.32), DARK)
    # Bloc de piatra la baza catargului
    b.box((mx, my, GROUND + 0.35), (1.5, 1.5, 0.9), GRANITE_B)
    return b.to_object("Kakei")


# ---------------------------------------------------------------- Stone -----

def build_stone():
    b = Builder()
    # Piatra de lovire: coloana de trei blocuri, de la sol pana la lespedea plata
    # a carei fata de sus e la STONE_TOP. Centrata sub capatul cozii (y' ~ -2.9).
    cy = -2.9
    top = STONE_TOP
    _stone_block(b, 0.0, cy, GROUND - 0.3, GROUND + 1.5, 3.1, 3.3, GRANITE_B, yaw=5)
    _stone_block(b, 0.0, cy, GROUND + 1.5, top - 0.6, 2.6, 2.8, GRANITE, yaw=-4)
    _stone_block(b, 0.0, cy, top - 0.6, top, 2.4, 2.7, GRANITE_B, yaw=2)
    return b.to_object("StrikeStone")


# ---------------------------------------------------------------- emit ------

clear_built()
tube = build_tube()
frame = build_frame()
kakei = build_kakei()
stone = build_stone()

def _ao(z_lo, z_hi):
    # Gradientul se intinde pe inaltimea PIESEI (nu a ansamblului de 18 m): altfel
    # piatra de 3,5 m din jos iese cu AO <= 0.63 pe fata de sus.
    return dict(samples=24, dist=3.0, gradient="vertical", low=0.50, high=1.0,
                power=0.9, floor=0.2, z_range=(z_lo, z_hi))


AO_FRAME = _ao(GROUND - 0.6, 1.0)
AO_KAKEI = _ao(GROUND - 0.6, 11.9)
AO_STONE = _ao(GROUND - 0.6, STONE_TOP + 0.3)
# Tubul se invarte: un gradient vertical copt in model ar ajunge pe partea
# gresita dupa 35 de grade. Doar ocluzia geometrica (noduri, interior).
AO_TUBE = dict(samples=24, dist=1.2, gradient="none", floor=0.3)

stats = {}
stats["Tube"] = finish(tube, bevel=0.02, bevel_angle=50.0, ao=AO_TUBE, origin=None,
                       smooth_angle=40.0)
stats["Frame"] = finish(frame, bevel=0.04, ao=AO_FRAME, origin=None, smooth_angle=None)
stats["Kakei"] = finish(kakei, bevel=0.02, bevel_angle=50.0, ao=AO_KAKEI, origin=None,
                        smooth_angle=40.0)
stats["StrikeStone"] = finish(stone, bevel=0.05, ao=AO_STONE, origin=None,
                              smooth_angle=None)

for o in (tube, frame, kakei, stone):
    o.location = (0.0, 0.0, 0.0)

path, size = export_glb([frame, tube, kakei, stone], "kyoto/structures/shishi_odoshi.glb")
save_blend([frame, tube, kakei, stone], "kyoto_shishi_odoshi.blend")
print("== shishi_odoshi ==", path, "%.1f KB" % (size / 1024.0))
for k, v in stats.items():
    print("  %-12s tris=%d ao=[%.2f..%.2f]" % (k, v["tris"], v["ao_min"], v["ao_max"]))
print("  total tris:", sum(v["tris"] for v in stats.values()), "| STONE_TOP=%.3f" % STONE_TOP)
