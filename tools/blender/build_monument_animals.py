"""Monument Valley -- animale (brief docs/asset_briefs/monumentvalley_kit.md §1.7).

  monumentvalley/animals/horse_bay.glb     cal murg, FARA sa si calaret; Pose_Stand + Pose_Walk
  monumentvalley/animals/horse_pinto.glb   cal pinto (alb cu pete mari maro); idem
  monumentvalley/animals/horse_black.glb   cal negru; idem
  monumentvalley/animals/sheep.glb         oaie alba, fata si picioare inchise; idem
  monumentvalley/animals/raven.glb         corb cu aripile deschise; nod Raven_Wings

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_monument_animals.py [-- --only horse_bay]

CAII au schelet + animatii Walk/Idle (oct 2026, monument_horse_rig.py); restul
(oaie, corb) ramane static. v1 STATICE (tiparul Serengeti): cele doua poze sunt noduri separate in acelasi
GLB (`Pose_Stand`, `Pose_Walk`), integrarea alege. Cei trei cai ies din ACEEASI
functie de corp (`build_horse`), parametrizata pe model de culoare si poza, deci
silueta si proportiile sunt identice si difera doar culoarea. Fata = +Y in
Blender (= -Z in Godot). Primitive rotunde cu segmente explicite (4-10).
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "monument_shapes.py")).read())

clear_built()

AO_ANIMAL = dict(samples=20, dist=1.2, gradient="vertical",
                 low=0.55, high=1.0, power=0.9, floor=0.30)

WITHERS_Z = 1.60        # inaltimea la greaban (contract)
HOOF_H = 0.10           # inaltimea copitei (frustum)


# ---------------------------------------------------------------------------
# ajutoare
# ---------------------------------------------------------------------------

def _verts(faces):
    return {v for f in faces for v in f.verts}


def _squash_x(faces, sx, cx=0.0):
    """Sectiunea unui `taper_sweep` e cerc; trunchiul si gatul calului sunt mai
    inalte decat late. Turtim pe X in jurul axei piesei (`cx`)."""
    for v in _verts(faces):
        v.co.x = cx + (v.co.x - cx) * sx
    return faces


def curve(stations, per=2):
    """Statii (y, z, r) -> puncte (Vector, raza) interpolate Catmull-Rom, cu
    `per` puncte intre statii: curbura gatului/trunchiului vine din interpolare,
    nu din multe statii scrise de mana."""
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
    pts = [Vector((0.0, v[0], v[1])) for v in out]
    return pts, [max(v[2], 0.0) for v in out]


def tube(b, stations, slot, segments=8, sx=1.0, per=2, cx=0.0, caps=(True, True)):
    pts, rs = curve(stations, per)
    if cx:
        pts = [p + Vector((cx, 0.0, 0.0)) for p in pts]
    f = b.taper_sweep(pts, rs, slot, segments=segments,
                      cap_start=caps[0], cap_end=caps[1])
    if sx != 1.0:
        _squash_x(f, sx, cx)
    return f


def leg_points(x, hip_y, hip_z, lens, angles, ground=None):
    """Lant de segmente in planul YZ. `angles` in grade, masurate de la verticala
    in jos, pozitiv = INAINTE (+Y). `ground` (z-ul ultimului punct, pe sol):
    scaleaza lungimile ca piciorul de sprijin sa atinga exact solul."""
    drop = sum(l * math.cos(math.radians(a)) for l, a in zip(lens, angles))
    f = 1.0 if ground is None else (hip_z - ground) / drop
    pts = [Vector((x, hip_y, hip_z))]
    for l, a in zip(lens, angles):
        r = math.radians(a)
        pts.append(pts[-1] + Vector((0.0, math.sin(r) * l * f, -math.cos(r) * l * f)))
    return pts


# ---------------------------------------------------------------------------
# 1-3. calul: o singura functie de corp, trei modele de culoare, doua poze
# ---------------------------------------------------------------------------

# Cotele calului. Lungimea totala 2,4 m (bot -> varful cozii), greaban 1,6 m.
# Parametrii de poza: unghiurile segmentelor (grade, + = inainte) pe picior.
# fata: [brat, antebrat/fluier, pastern]; spate: [pulpa, fluier, pastern].
LEG_STAND = {
    "F": ([0, 0, 14], True), "H": ([-12, 10, 18], True),
}
# mers: o pereche diagonala INAINTE (stanga-fata + dreapta-spate), cealalta
# INAPOI (dreapta-fata + stanga-spate); piciorul care trece inainte e ridicat.
LEG_WALK = {
    ("F", -1): ([30, -22, 8], False),    # stanga-fata, inainte, ridicat
    ("F", +1): ([-22, -8, 14], True),    # dreapta-fata, inapoi, pe sol
    ("H", +1): ([2, 30, 30], False),     # dreapta-spate, inainte, ridicat
    ("H", -1): ([-30, -6, 22], True),    # stanga-spate, inapoi, pe sol
}

# model de culoare: slot corp, slot burta (fete in jos), slot partea de jos,
# coama, coada, copite
COATS = {
    "bay":   dict(body=LARCH_RUST, belly=WOOD, dark=LOG_DARK,
                  mane=LOG_DARK, tail=LOG_DARK, hoof=LOG_DARK,
                  socks=True),
    "pinto": dict(body=FOAM_WHITE, belly=MARBLE_GREY, dark=LOG_DARK,
                  mane=LOG_DARK, tail=VOLCANIC_BLACK, hoof=LOG_DARK,
                  socks=False),
    "black": dict(body=LOG_DARK, belly=LOG_DARK, dark=LOG_DARK,
                  mane=LOG_DARK, tail=LOG_DARK, hoof=LOG_DARK, socks=False),
}

# petele calului pinto (pe partea +X = dreapta calului, cea vazuta pe decupare):
# (parte, y, z, raza_y, raza_z, raza_x) ; parte 0 = ambele, +1/-1 = o singura.
PINTO_PATCHES = [
    (+1, -0.12, 1.44, 0.50, 0.19, 0.5),    # sa mare pe spinare
    (0, -0.88, 1.30, 0.30, 0.42, 0.6),     # crupa, peste ambele parti
    (+1, 0.52, 1.36, 0.16, 0.24, 0.5),     # umar
    (+1, 0.78, 1.64, 0.32, 0.32, 0.5),     # gatul, brun
    (+1, 0.12, 1.12, 0.16, 0.10, 0.5),     # pata mica pe burta
    (-1, 0.05, 1.42, 0.55, 0.20, 0.5),     # partea stanga, alta forma
    (-1, 0.70, 1.60, 0.30, 0.30, 0.5),
]


def _in_patch(c, patch):
    side, py, pz, ry, rz, rx = patch
    if side != 0 and (c.x * side) < 0.0:
        return False
    return (((c.y - py) / ry) ** 2 + ((c.z - pz) / rz) ** 2
            + (c.x * 0.0) ** 2) < 1.0


def build_horse(coat, pose):
    """cal murg/pinto/negru -- lista de elemente (numarata pe decuparile
    horse_bay / horse_pinto / horse_black, inainte de primul vertex):

    SILUETA (profil, capul spre +Y, vazut din partea dreapta a calului):
      - trunchi lung si adanc: piept inalt, spinare dreapta, crupa rotunda,
        burta la ~0,95 m (60% din greaban);
      - gat lung ARCUIT (convex spre sus), ridicat la ~55 grade, se subtiaza spre
        ceafa; cap lung, ingust, indreptat in jos-inainte, bot mai subtire,
        2 urechi ascutite drepte in sus;
      - coama: sir de smocuri pe creasta gatului, cazuta pe o parte, plus un
        smoc in frunte; coada lunga ATARNATA din crupa pana sub jaret;
      - 4 picioare subtiri: antebrat, fluier, pastern, copita (frustum, 6
        laturi); picioarele din spate cu jaret (unghi spre inapoi);
      - ochi: un punct negru pe fiecare parte a capului, bot negru (murg);
      - FARA sa, FARA calaret, FARA frau.
    CULOARE (din decupare): murg = corp maro-rosiatic, burta mai inchisa,
      picioare de la genunchi in jos NEGRE, coama/coada/copite negre;
      pinto = alb cu 6 pete mari maro (spinare, crupa, umar, baza gatului,
      cap maro cu dunga alba pe fata), coada neagra; negru = corp gri-inchis
      cald, coama/coada mai inchise.
    POZE: stand = toate 4 picioare drepte pe sol; walk = o pereche diagonala
      inainte (fata-stanga + spate-dreapta, ridicate), cealalta inapoi, pe sol.
    Cote: 2,4 m lung (bot -> coada), greaban 1,6 m, fata = +Y.
    """
    C = COATS[coat]
    b = Builder()
    body = C["body"]
    parts = {}

    # --- trunchiul (tub cu raza variabila, turtit lateral) ---------------
    parts["trunk"] = tube(b, [(-0.96, 1.30, 0.12), (-0.84, 1.31, 0.28),
                              (-0.52, 1.27, 0.36), (-0.12, 1.24, 0.37),
                              (0.22, 1.25, 0.375), (0.52, 1.28, 0.35),
                              (0.72, 1.32, 0.25)],
                          body, segments=12, sx=0.70, per=4)
    # --- gatul arcuit + capul -------------------------------------------
    parts["neck"] = tube(b, [(0.44, 1.38, 0.30), (0.60, 1.55, 0.24),
                             (0.73, 1.74, 0.20), (0.85, 1.89, 0.17),
                             (0.97, 1.97, 0.14)],
                         body, segments=10, sx=0.62, per=3, caps=(False, False))
    parts["head"] = tube(b, [(0.96, 1.97, 0.14), (1.06, 1.82, 0.145),
                             (1.16, 1.63, 0.11), (1.23, 1.52, 0.09),
                             (1.255, 1.47, 0.0)],
                         body, segments=7, sx=0.72, per=1, caps=(False, True))
    parts["muzzle"] = tube(b, [(1.18, 1.58, 0.09), (1.23, 1.52, 0.085),
                               (1.26, 1.47, 0.0)],
                           C["dark"] if coat == "bay" else body, segments=7,
                           sx=0.72, per=1, caps=(False, True))
    for s in (-1, 1):
        b.taper_sweep([Vector((s * 0.05, 0.96, 2.02)), Vector((s * 0.06, 0.92, 2.16))],
                      [0.04, 0.0], body, segments=4)
        b.box((s * 0.082, 1.09, 1.86), (0.03, 0.05, 0.04), VOLCANIC_BLACK)
    # --- coama: lama pe creasta gatului, cazuta inapoi/pe o parte ---------
    parts["mane"] = tube(b, [(0.46, 1.62, 0.06), (0.58, 1.76, 0.085),
                             (0.70, 1.92, 0.085), (0.82, 2.06, 0.075),
                             (0.92, 2.14, 0.05)],
                         C["mane"], segments=6, sx=0.9, per=2, cx=0.06)
    b.box((0, 1.04, 2.06), (0.07, 0.09, 0.14), C["mane"],
          rotation=Matrix.Rotation(math.radians(-25), 3, "X"))      # smocul din frunte
    # --- coada: atarna din crupa pana sub jaret --------------------------
    parts["tail"] = tube(b, [(-0.90, 1.46, 0.05), (-0.97, 1.34, 0.085),
                             (-1.02, 1.06, 0.10), (-1.01, 0.76, 0.075),
                             (-0.97, 0.52, 0.0)],
                         C["tail"], segments=6, sx=0.55, per=2)

    # --- picioarele ------------------------------------------------------
    legs = {}
    for s in (-1, 1):
        for kind in ("F", "H"):
            ang, stance = (LEG_STAND[kind] if pose == "stand"
                           else LEG_WALK[(kind, s)])
            if kind == "F":
                hip_y, hip_z, x = 0.50, 1.08, s * 0.16
                lens = [0.50, 0.42, 0.12]
                radii = [0.13, 0.08, 0.055, 0.052]
            else:
                hip_y, hip_z, x = -0.70, 1.12, s * 0.17
                lens = [0.58, 0.42, 0.12]
                radii = [0.19, 0.09, 0.055, 0.052]
            pts = leg_points(x, hip_y, hip_z, lens, ang,
                             ground=HOOF_H if stance else None)
            mid = pts[1] + (pts[2] - pts[1]) * 0.45
            top = b.taper_sweep([pts[0], pts[1], mid], [radii[0], radii[1], 0.07], body,
                                segments=6, cap_start=False, cap_end=False)
            low_slot = C["dark"] if C["socks"] else body
            low = b.taper_sweep([mid] + pts[2:], [0.07] + radii[2:], low_slot, segments=6,
                                cap_start=False, cap_end=True)
            ph = pts[-1]
            hoof = b.frustum((ph.x, ph.y, ph.z - HOOF_H * 0.5 + 0.01), 0.07, 0.056,
                             HOOF_H, C["hoof"], segments=6)
            legs[(kind, s)] = dict(top=top, low=low, hoof=hoof)
    parts["legs"] = legs

    # --- culoarea pe model -------------------------------------------------
    belly_where = lambda c, n: n.z < -0.35
    for k in ("trunk", "neck", "head"):
        b.retag(parts[k], C["belly"], where=belly_where)
    for lg in legs.values():
        b.retag(lg["top"], C["belly"], where=lambda c, n: n.z < -0.5)
    if coat == "pinto":
        for k in ("trunk", "neck"):
            for p in PINTO_PATCHES:
                b.retag(parts[k], LARCH_RUST, where=lambda c, n, p=p: _in_patch(c, p))
        b.retag(parts["head"], LARCH_RUST)                                # capul maro
        b.retag(parts["muzzle"], LARCH_RUST)
        b.retag(parts["head"], FOAM_WHITE,
                where=lambda c, n: abs(c.x) < 0.045 and n.y > -0.2 and c.z > 1.56)   # dunga
        for (kind, s), lg in legs.items():
            if kind == "F" and s == -1:                                    # un brat pe jumatate maro
                b.retag(lg["top"], LARCH_RUST)
            if kind == "H":
                b.retag(lg["top"], LARCH_RUST, where=lambda c, n: c.z > 0.85)
    return b


# ---------------------------------------------------------------------------
# 4. oaia
# ---------------------------------------------------------------------------

def build_sheep(pose):
    """sheep.png -- lista de elemente de pe decupare:
    - CORP: o masa de lana crem, rotunjita, usor mai lunga decat inalta, cu
      spinare convexa si piept rotund (bulgarii de lana de pe contur NU sunt
      modelati: conurile incercate citeau ca ghimpi);
    - GAT scurt invelit in lana, capul mai jos decat spinarea, spre dreapta;
    - CAP: ovoid ingust, intunecat (maro foarte inchis), bot rotunjit, doua
      urechi lateral-inapoi, intunecate; fara coarne;
    - 4 PICIOARE scurte, subtiri, intunecate, cu copita; coada mica de lana;
    - culori: lana FOAM_WHITE, cap/urechi/picioare LOG_DARK.
    POZE: stand = drepte; walk = o pereche diagonala inainte.
    Cote: 1,3 m lung (bot -> coada), ~0,85 m la cap.
    """
    b = Builder()
    wool, dark = CORAL_SAND, LOG_DARK
    tube(b, [(-0.58, 0.60, 0.10), (-0.46, 0.60, 0.25), (-0.15, 0.58, 0.31),
             (0.22, 0.58, 0.31), (0.42, 0.62, 0.26), (0.54, 0.66, 0.12)],
         wool, segments=9, sx=0.86, per=3)                                       # lana: corp rotunjit
    tube(b, [(0.36, 0.66, 0.22), (0.48, 0.76, 0.17), (0.56, 0.80, 0.13)],
         wool, segments=8, sx=0.85, per=2, caps=(False, True))                   # gatul in lana
    b.rock((0.0, -0.58, 0.52), (0.18, 0.2, 0.22), wool, seed=8, segments=6, rings=3, taper=0.5)   # coada
    # cap
    head = tube(b, [(0.50, 0.80, 0.11), (0.58, 0.80, 0.12), (0.66, 0.72, 0.10),
                    (0.71, 0.66, 0.0)], dark, segments=7, sx=0.78, per=1,
                caps=(False, True))
    for s in (-1, 1):
        b.taper_sweep([Vector((s * 0.07, 0.52, 0.86)), Vector((s * 0.19, 0.49, 0.80))],
                      [0.045, 0.0], dark, segments=4)
    # picioare
    for s in (-1, 1):
        for kind in ("F", "H"):
            ang = ([0, 0] if pose == "stand" else
                   {("F", -1): [26, -14], ("F", 1): [-18, -4],
                    ("H", 1): [4, 24], ("H", -1): [-24, -2]}[(kind, s)])
            stance = pose == "stand" or (kind, s) in (("F", 1), ("H", -1))
            hip_y = 0.30 if kind == "F" else -0.30
            pts = leg_points(s * 0.13, hip_y, 0.40, [0.19, 0.19], ang,
                             ground=0.05 if stance else None)
            b.taper_sweep(pts, [0.05, 0.036, 0.034], dark, segments=5,
                          cap_start=False, cap_end=True)
            p = pts[-1]
            b.frustum((p.x, p.y, 0.025), 0.045, 0.036, 0.05, dark, segments=5)
    for v in b.bm.verts:                  # 1,41 -> 1,3 m lungime (contract)
        v.co.y *= 0.92
    return b


# ---------------------------------------------------------------------------
# 5. corbul
# ---------------------------------------------------------------------------

def plate(b, outline, thick, slot, place):
    """Placa subtire dintr-un contur 2D (x, y) in planul orizontal; `place`
    mapeaza (x, y, z) in lume (dihedru, oglindire). Fata de sus/jos se
    triangulaza cu ear-clip (conturul e concav, cu varfuri de pene)."""
    top = [b.bm.verts.new(place(x, y, thick * 0.5)) for x, y in outline]
    bot = [b.bm.verts.new(place(x, y, -thick * 0.5)) for x, y in outline]
    n = len(outline)
    ft = b.bm.faces.new(tuple(top))
    fb = b.bm.faces.new(tuple(reversed(bot)))
    sides = [b.bm.faces.new((bot[i], bot[(i + 1) % n], top[(i + 1) % n], top[i]))
             for i in range(n)]
    bmesh.ops.triangulate(b.bm, faces=[ft, fb], quad_method="BEAUTY", ngon_method="EAR_CLIP")
    for f in b.bm.faces:
        f[b.slot] = slot
    return sides


# aripa dreapta in plan (x = spre varf, y = inainte), CONTUR cu 4 pene primare
# in evantai si marginea secundarelor usor festonata
WING_OUTLINE = [(0.04, 0.09), (0.20, 0.11), (0.38, 0.08), (0.52, 0.00), (0.43, -0.05),
                (0.51, -0.17), (0.38, -0.12), (0.46, -0.30), (0.32, -0.19),
                (0.37, -0.36), (0.26, -0.23), (0.22, -0.28), (0.14, -0.24),
                (0.04, -0.16)]
TAIL_OUTLINE = [(-0.05, -0.15), (0.05, -0.15), (0.12, -0.33), (0.10, -0.43),
                (0.04, -0.40), (0.0, -0.45), (-0.04, -0.40), (-0.10, -0.43),
                (-0.12, -0.33)]


def build_raven():
    """raven.png -- lista de elemente de pe decupare (corb in zbor, aripile
    larg deschise, camera dintr-o parte si putin de sus):
    - CORP: ovoid alungit, negru, usor inclinat (cap mai sus), piept bombat;
    - CAP: mic, cu cioc GROS, portocaliu-ruginiu (RUST_METAL);
    - 2 ARIPI mari deschise in V, intinse in spate, ca placi cu 4 pene
      primare late departate in evantai la varf si margine festonata la
      secundare; aripa din dreapta ridicata abrupt, cea din stanga mai joasa;
    - COADA in evantai, cu varful festonat;
    - 2 GHEARE mici stranse sub corp;
    - culoare: totul VOLCANIC_BLACK, doar ciocul pe RUST_METAL.
    Cote: anvergura 1,0 m; nod Raven_Wings = ambele aripi (pentru animatie).
    """
    body, wings = Builder(), Builder()
    K = VOLCANIC_BLACK
    tube(body, [(-0.20, -0.02, 0.04), (-0.08, -0.01, 0.085), (0.06, 0.00, 0.09),
                (0.16, 0.03, 0.065), (0.22, 0.06, 0.045)],
         K, segments=8, sx=0.9, per=2, caps=(True, False))
    body.rock((0.0, 0.215, 0.03), (0.09, 0.13, 0.10), K, seed=2, segments=6, rings=3)   # cap
    body.taper_sweep([Vector((0.0, 0.275, 0.065)), Vector((0.0, 0.345, 0.035))],
                     [0.03, 0.0], RUST, segments=4)                                    # cioc
    plate(body, TAIL_OUTLINE, 0.02, K, lambda x, y, z: Vector((x, y, -0.03 + z + y * 0.12)))
    for s in (-1, 1):                                                                   # gheare
        body.taper_sweep([Vector((s * 0.035, 0.03, -0.06)), Vector((s * 0.035, 0.055, -0.13))],
                         [0.016, 0.011], K, segments=4)
    for s in (-1, 1):
        th = math.radians(48 if s > 0 else 24)           # dihedru: dreapta abrupt, stanga jos
        R = Matrix.Rotation(-th, 3, "Y")

        def place(x, y, z, s=s, R=R):
            v = R @ Vector((x, 0.0, z))
            return Vector((s * v.x, y, v.z + 0.07))
        plate(wings, [(x * 1.25, y) for x, y in WING_OUTLINE], 0.018, K, place)
    return body, wings


# ---------------------------------------------------------------------------
# rulare
# ---------------------------------------------------------------------------

def _two_poses(make):
    """`make(pose)` -> Builder; intoarce nodurile Pose_Stand + Pose_Walk."""
    return [make("stand").to_object("Pose_Stand"), make("walk").to_object("Pose_Walk")]


# Caii (din oct 2026) ies cu schelet si animatii Walk/Idle: vezi
# monument_horse_rig.py. `Pose_Stand` ramane static (caii de decor), iar
# `Pose_Walk` e armatura calului in poza de stand. Marcajul "rig" cere
# emisia speciala (`emit_horse_rigged`) in loc de `emit`.
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "monument_horse_rig.py")).read())

PIECES = [
    ("animals/horse_bay.glb", ("rig", "bay"), 3200),
    ("animals/horse_pinto.glb", ("rig", "pinto"), 3200),
    ("animals/horse_black.glb", ("rig", "black"), 3200),
    ("animals/sheep.glb", lambda: _two_poses(build_sheep), 2400),
    ("animals/raven.glb", lambda: [o for o, n in zip(
        (lambda bw: (bw[0].to_object("Raven_Body"), bw[1].to_object("Raven_Wings")))(build_raven()),
        ("Raven_Body", "Raven_Wings"))], 1800),
]

import sys as _sys
_only = None
if "--only" in _sys.argv:
    _only = _sys.argv[_sys.argv.index("--only") + 1].split(",")

for _path, _fn, _bud in PIECES:
    if _only and os.path.basename(_path)[:-4] not in _only:
        continue
    clear_built()
    if isinstance(_fn, tuple) and _fn[0] == "rig":
        emit_horse_rigged(_path, _fn[1], AO_ANIMAL, budget=_bud)
        continue
    emit(list(_fn()), _path, AO_ANIMAL, keep_xy=False, bevel=0.0,
         smooth_angle=None, budget=_bud)
report()
