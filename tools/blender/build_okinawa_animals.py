"""Okinawa v2 -- animale statice (brief docs/asset_briefs/okinawa_kit_v2.md §1.6).

  okinawa/animals/water_buffalo.glb   bivol de apa; Pose_Stand + Pose_Walk
  okinawa/animals/egret.glb           starc alb; Pose_Stand + Pose_Fly

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_okinawa_animals.py

Tiparul Serengeti / Monument Valley (caii statici): cele doua poze sunt noduri
SEPARATE in acelasi GLB, integrarea alege. Originea: piciorul de sprijin pe
z=0, XY centrat pe corp (fara offset pe ansamblu: pozele ar sari una fata de
alta). `Pose_Fly` e ridicata la ~1 m (zboara), deci verify cu `--origin=assembly`.
Fata = +Y Blender (= -Z Godot). Primitive rotunde cu segmente explicite.
Variabila OK_ONLY=<piesa> reface doar piesa respectiva.
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "okinawa_shapes.py")).read())

clear_built()

AO_ANIMAL = dict(samples=18, dist=1.0, gradient="vertical", low=0.6, high=1.0,
                 power=0.9, floor=0.3)


# --- ajutoare (aceleasi ca la caii Monument Valley) --------------------------

def curve(stations, per=2):
    """Statii (y, z, r) -> puncte (Vector) si raze, interpolate Catmull-Rom."""
    out = []
    n = len(stations)
    for i in range(n - 1):
        p0 = stations[max(i - 1, 0)]
        p1, p2 = stations[i], stations[i + 1]
        p3 = stations[min(i + 2, n - 1)]
        for k in range(per):
            t = k / per
            vals = []
            for c in range(3):
                a0, a1, a2, a3 = p0[c], p1[c], p2[c], p3[c]
                vals.append(0.5 * ((2 * a1) + (-a0 + a2) * t
                                   + (2 * a0 - 5 * a1 + 4 * a2 - a3) * t * t
                                   + (-a0 + 3 * a1 - 3 * a2 + a3) * t ** 3))
            out.append(vals)
    out.append(list(stations[-1]))
    return [Vector((0.0, v[0], v[1])) for v in out], [max(v[2], 0.0) for v in out]


def tube(b, stations, slot, segments=8, sx=1.0, per=2, cx=0.0, caps=(True, True)):
    pts, rs = curve(stations, per)
    if cx:
        pts = [p + Vector((cx, 0.0, 0.0)) for p in pts]
    f = b.taper_sweep(pts, rs, slot, segments=segments, cap_start=caps[0], cap_end=caps[1])
    if sx != 1.0:
        for v in {v for fc in f for v in fc.verts}:
            v.co.x = cx + (v.co.x - cx) * sx
    return f


def leg_points(x, hip_y, hip_z, lens, angles, ground=None):
    drop = sum(l * math.cos(math.radians(a)) for l, a in zip(lens, angles))
    f = 1.0 if ground is None else (hip_z - ground) / drop
    pts = [Vector((x, hip_y, hip_z))]
    for l, a in zip(lens, angles):
        r = math.radians(a)
        pts.append(pts[-1] + Vector((0.0, math.sin(r) * l * f, -math.cos(r) * l * f)))
    return pts


# ---------------------------------------------------------------------------
# 1. BIVOLUL DE APA
# ---------------------------------------------------------------------------

BODY, HORN, DARK = LOG_DARK, MARBLE_GREY, VOLCANIC_BLACK
BUF_HOOF = 0.10
BUF_STAND = {"F": [0, 0, 8], "H": [-8, 8, 12]}
BUF_WALK = {("F", -1): [26, -18, 6], ("F", 1): [-20, -6, 10],
            ("H", 1): [4, 26, 22], ("H", -1): [-24, -4, 16]}


def build_buffalo(pose):
    """`water_buffalo` (decuparea `water_buffalo.png` + contractul §1.6; RUNDA 2, ceruta
    de coordonator: capul orizontal, bot scurt si lat, coarne in semiluna, picioare
    scurte) -- LISTA DE ELEMENTE:

    TRUNCHI: butoi masiv, 7 statii, r ~0,40-0,45, greaban la ~1,5 m (cocoasa peste
      umeri), crupa mai joasa, BURTA LA ~0,72 m de sol; latime ~0,9 m.
    GAT scurt si gros, orizontal; CAP tinut ORIZONTAL, la nivelul greabanului sau
      putin sub (z ~1,2), BOT SCURT SI LAT (capat bont), 2 narine, 2 ochi, 2 URECHI.
    2 COARNE in SEMILUNA (~1,2 m), groase la baza (r 0,12): pleaca LATERAL din cap,
      se curbeaza in SUS si inapoi (C vazut din fata), varf ascutit; MARBLE_GREY.
    4 PICIOARE SCURTE SI GROASE (brat / fluier / pastern, r 0,18..0,09) + copita neagra.
    COADA subtire pana sub jaret, cu smoc.
    CULORI: corp VOLCANIC_BLACK 20 (gri-ardezie; LOG_DARK iesea maro), partea de jos a
      picioarelor si botul LOG_DARK 28, coarne MARBLE_GREY 29. POZE: `Pose_Stand` =
      4 picioare drepte; `Pose_Walk` = o pereche diagonala inainte.
    Cote: 2,8 m bot -> crupa, greaban 1,5 m, fata = +Y.
    """
    b = Builder()
    SLATE = VOLCANIC_BLACK
    tube(b, [(-1.05, 1.02, 0.16), (-0.92, 1.05, 0.34), (-0.5, 1.10, 0.41), (-0.05, 1.12, 0.43),
             (0.4, 1.14, 0.45), (0.78, 1.14, 0.40), (0.98, 1.14, 0.26)], SLATE, segments=8, sx=1.0, per=3)
    tube(b, [(0.75, 1.15, 0.36), (0.98, 1.18, 0.31), (1.15, 1.18, 0.28)], SLATE, segments=8, sx=1.0,
         per=2, caps=(False, False))
    tube(b, [(1.1, 1.18, 0.29), (1.3, 1.16, 0.27), (1.48, 1.10, 0.23), (1.60, 1.05, 0.19)],
         SLATE, segments=8, sx=1.0, per=2, caps=(False, False))
    tube(b, [(1.55, 1.07, 0.21), (1.62, 1.04, 0.19), (1.65, 1.03, 0.0)], BODY, segments=8, sx=1.0, per=1,
         caps=(False, True))                                                    # botul scurt si lat
    for s in (-1, 1):
        base = [(0.24, 1.10, 1.26), (0.46, 1.08, 1.26), (0.66, 1.04, 1.30), (0.80, 0.98, 1.42),
                (0.84, 0.92, 1.60), (0.76, 0.88, 1.78), (0.62, 0.86, 1.90)]
        pts = [Vector((s * x, y, z)) for x, y, z in base]
        b.taper_sweep(pts, [0.14, 0.13, 0.115, 0.09, 0.065, 0.035, 0.0], HORN, segments=6,
                      cap_start=True, cap_end=True)
        b.box((s * 0.36, 1.0, 1.24), (0.22, 0.13, 0.07), SLATE,
              rotation=Matrix.Rotation(math.radians(-s * 25), 3, "Z"))        # ureche
        b.box((s * 0.24, 1.30, 1.30), (0.05, 0.05, 0.05), DARK)               # ochi
        b.box((s * 0.09, 1.66, 1.07), (0.06, 0.05, 0.045), DARK)              # narina
    for s in (-1, 1):
        for kind in ("F", "H"):
            ang = BUF_STAND[kind] if pose == "stand" else BUF_WALK[(kind, s)]
            stance = pose == "stand" or (kind, s) in (("F", 1), ("H", -1))
            if kind == "F":
                hip_y, hip_z, lens, rad = 0.52, 0.92, [0.36, 0.24, 0.12], [0.19, 0.14, 0.10, 0.09]
            else:
                hip_y, hip_z, lens, rad = -0.68, 0.94, [0.38, 0.24, 0.12], [0.21, 0.15, 0.10, 0.09]
            pts = leg_points(s * 0.27, hip_y, hip_z, lens, ang, ground=BUF_HOOF if stance else None)
            mid = pts[1] + (pts[2] - pts[1]) * 0.4
            b.taper_sweep([pts[0], pts[1], mid], [rad[0], rad[1], 0.105], SLATE, segments=6,
                          cap_start=False, cap_end=False)
            b.taper_sweep([mid] + pts[2:], [0.105] + rad[2:], BODY, segments=6, cap_start=False, cap_end=True)
            p = pts[-1]
            b.frustum((p.x, p.y, p.z - BUF_HOOF * 0.5 + 0.01), 0.105, 0.09, BUF_HOOF, DARK, segments=6)
    tube(b, [(-1.04, 1.0, 0.04), (-1.12, 0.86, 0.04), (-1.14, 0.58, 0.035), (-1.10, 0.36, 0.0)],
         SLATE, segments=5, sx=1.0, per=2)
    b.box((0.0, -1.10, 0.34), (0.1, 0.1, 0.22), DARK)
    k = 2.8 / 2.70                        # lungimea de contract (bot -> crupa)
    for v in b.bm.verts:
        v.co.y *= k
    return b


# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# 2. STARCUL
# ---------------------------------------------------------------------------

def build_egret(pose):
    """`egret` (decuparea `egret.png` + contractul §1.6) -- LISTA DE ELEMENTE:

    CORP: picatura alba, turtita pe X (0,7), piept inainte, coada ascutita in spate
      (7 statii). GAT in S: 5 statii, urca din piept, se arcuieste inapoi si iar
      inainte spre cap; CAP mic cu ochi negru si CIOC lung, galben (CAR_YELLOW 16,
      0,22 m, usor in jos) -- `Pose_*` poarta `--allow-car-slots=Pose_`.
    PICIOARE: 2, lungi si subtiri, NEGRE (VOLCANIC_BLACK 20), cu genunchiul usor
      inapoi, laba = 3 degete (cutii) pe sol.
    `Pose_Stand`: in picioare, 0,9 m inalt (varful capului). `Pose_Fly`: gat strans
      in S, picioare intinse in urma, 2 ARIPI deschise (lamele cu grosime, 5 puncte,
      latimea creste spre mijloc si scade spre varf), anvergura 1,4 m; ridicata la
      0,9 m deasupra solului.
    Culori: corp/aripi FOAM_WHITE 22.
    """
    b = Builder()
    W, Y, BK = FOAM_WHITE, CAR_YELLOW, VOLCANIC_BLACK
    if pose == "stand":
        tube(b, [(-0.30, 0.44, 0.0), (-0.18, 0.49, 0.10), (0.0, 0.55, 0.16), (0.14, 0.58, 0.15),
                 (0.22, 0.63, 0.07)], W, segments=7, sx=0.7, per=3)
        tube(b, [(0.20, 0.62, 0.06), (0.27, 0.71, 0.05), (0.22, 0.79, 0.042), (0.27, 0.855, 0.036),
                 (0.31, 0.89, 0.04)], W, segments=6, sx=1.0, per=3, caps=(False, False))
        tube(b, [(0.28, 0.885, 0.04), (0.36, 0.89, 0.04), (0.40, 0.88, 0.0)], W, segments=6, per=1,
             caps=(False, True))
        tube(b, [(0.38, 0.885, 0.03), (0.50, 0.865, 0.02), (0.60, 0.845, 0.0)], Y, segments=5,
             per=1, caps=(False, True))
        b.box((0.035, 0.34, 0.895), (0.02, 0.025, 0.025), BK)
        b.box((-0.035, 0.34, 0.895), (0.02, 0.025, 0.025), BK)
        for s in (-1, 1):
            pts = [Vector((s * 0.035, -0.02, 0.50)), Vector((s * 0.035, 0.0, 0.27)),
                   Vector((s * 0.035, 0.03, 0.03))]
            b.taper_sweep(pts, [0.016, 0.012, 0.012], BK, segments=4, cap_start=False, cap_end=True)
            b.box((s * 0.035, 0.08, 0.012), (0.02, 0.17, 0.024), BK)             # laba
            b.box((s * 0.035 + s * 0.05, 0.06, 0.012), (0.02, 0.12, 0.024), BK,
                  rotation=Matrix.Rotation(math.radians(s * -20), 3, "Z"))
    else:
        z0 = 0.9                                         # zboara, ridicat
        tube(b, [(-0.28, z0 + 0.0, 0.0), (-0.16, z0 + 0.02, 0.07), (0.0, z0 + 0.03, 0.11),
                 (0.14, z0 + 0.05, 0.10), (0.22, z0 + 0.07, 0.05)], W, segments=7, sx=0.7, per=3)
        tube(b, [(0.20, z0 + 0.06, 0.05), (0.27, z0 + 0.10, 0.045), (0.31, z0 + 0.06, 0.04),
                 (0.37, z0 + 0.08, 0.04)], W, segments=6, per=3, caps=(False, False))
        tube(b, [(0.36, z0 + 0.08, 0.04), (0.43, z0 + 0.08, 0.036), (0.46, z0 + 0.07, 0.0)], W,
              segments=6, per=1, caps=(False, True))
        tube(b, [(0.44, z0 + 0.075, 0.03), (0.54, z0 + 0.06, 0.02), (0.64, z0 + 0.05, 0.0)], Y,
             segments=5, per=1, caps=(False, True))
        for s in (-1, 1):
            pts = [Vector((s * 0.03, -0.20, z0 - 0.01)), Vector((s * 0.03, -0.42, z0 - 0.06)),
                   Vector((s * 0.03, -0.62, z0 - 0.10))]
            b.taper_sweep(pts, [0.015, 0.012, 0.01], BK, segments=4, cap_start=False, cap_end=True)
            w = [Vector((s * 0.06, 0.04, z0 + 0.06)), Vector((s * 0.30, 0.02, z0 + 0.15)),
                 Vector((s * 0.50, -0.04, z0 + 0.20)), Vector((s * 0.64, -0.10, z0 + 0.16)),
                 Vector((s * 0.70, -0.16, z0 + 0.10))]
            b.blade(w, [0.22, 0.30, 0.26, 0.16, 0.02], 0.03, W, up=(0, 0, 1))
    return b


# ---------------------------------------------------------------------------

ONLY = os.environ.get("OK_ONLY", "")


def _want(name):
    return not ONLY or ONLY == name


def _poses(make, names):
    return [make(p).to_object(n) for p, n in names]


def _drop(objs):
    for o in objs:
        bpy.data.objects.remove(o, do_unlink=True)


if _want("water_buffalo"):
    objs = _poses(build_buffalo, [("stand", "Pose_Stand"), ("walk", "Pose_Walk")])
    emit_ok_placed(objs, "animals/water_buffalo.glb", AO_ANIMAL, budget=3000)
    _drop(objs)

if _want("egret"):
    objs = _poses(build_egret, [("stand", "Pose_Stand"), ("fly", "Pose_Fly")])
    emit_ok_placed(objs, "animals/egret.glb", AO_ANIMAL, budget=1500)
    _drop(objs)

report_ok()
