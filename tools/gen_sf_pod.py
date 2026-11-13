#!/usr/bin/env python3
"""Genereaza tools/SondaSfPod*.tscn: strada SINTETICA a sondei 1d San Francisco
(brief docs/track_briefs/san_francisco.md §7 pasul 1d) — PODUL ROSU CAROSABIL,
dus-intors pe acelasi tablier, cu DESPARTITORUL MOBIL intre sensuri
(`scenes/hazards/movable_median_hazard.gd`). NU e Track25.

Intrebarea: un rand de blocuri de beton pe care un camion lent il muta pe
diagonala (banda ta se ingusteaza la ~8,4 m sau se largeste la ~15,4 m dupa unde
e camionul) se poate conduce de pluton fara [blocaj], fara treceri peste
despartitor si fara ejectari de pe pod — cu un AI care citeste culoarul liber
CURENT, nu faza?

Bucla (TrackFromPath cere bucla inchisa) e un „os de caine": doua benzi paralele
pe acelasi coridor, cu bucle-balon la capete (malul de start si malul celalalt):
  - banda DUS (+X) pe z = +LANE_Z, banda INTORS (-X) pe z = -LANE_Z (circulatie
    pe dreapta); axele la 2*LANE_Z = 12,4 m >= 2 * HW (ProbeLayout);
  - pornirea la x = 72 pe banda dus, 60 m de elan plat la cota Y0;
  - RAMPA de acces: racord 24 m, urcare la GRADE (11,5%), racord 24 m (+11 m);
  - palier 36 m, TABLIERUL (DECK m, implicit 300) la Y_D ~ +23 peste apa (0),
    palier 36 m;
  - balonul de intoarcere pe malul celalalt: viraj la dreapta THETA la raza R,
    viraj la stanga 180 + 2*THETA la raza R, viraj la dreapta THETA — raza de
    ax R = 20 m (sonda serpentinelor: R8 pica, R16 cu 9 m trece);
  - intoarcerea pe aceeasi cale, pe banda intors, si al doilea balon pe malul
    de start, apoi dreapta de grila.

Tablierul: benzile de pe pod au `custom_width_segments` HW_DECK = HW + OFFSET +
semilatimea blocului (9,8 m): fiecare banda trebuie sa fie „pe drum" pana la
fata barierei cand ea sta pe partea cealalta (altfel `is_on_road` ar taxa
latimea castigata ca iarba, 45%). Deci pe pod cele doua sosele SE SUPRAPUN la
mijloc (7,6 m), despartite fizic de bariera; ProbeLayout masoara pe HW-ul de
baza (6,0) si trece, dar suprapunerea e voita si declarata aici. Marginea de
afara a soselei late iese 3,8 m dincolo de parapet (un pervaz pe care nu ajunge
nimeni); parapetul exterior e un perete vertical de 1,2 m la |z| = 12,2.
Golul: rapa-viaduct pe ambele treceri (apa la 0 = marea temei), plasa
viaductului sub tablier si SeaRespawn sub apa.

Despartitorul FIX (cutii statice la axa) merge de la gatul balonului de start
pana la palier, si continua in nodul hazardului (care face palierele + podul).

  python tools/gen_sf_pod.py                       # SondaSfPod.tscn (mobil, AI citeste)
  SUFIX=Fix FIX=1 python tools/gen_sf_pod.py       # bariera fixa la axa, fara camion
  SUFIX=Orb AI=0 python tools/gen_sf_pod.py        # SABOTAJ: AI-ul orb la bariera
  SUFIX=Static STATIC=1 python tools/gen_sf_pod.py # SABOTAJ: citeste bariera de la t=0
  SUFIX=Cap PHASE=0.25 python tools/gen_sf_pod.py  # faza pentru captura

Variabile: DECK (300), OFFSET (3.5), TRANS (30), TAPER (30), TRUCK_SPEED (4.0),
DWELL (6.0), PHASE (0.0), R (20), GRADE (0.115), Y0 (12), FIX, AI (1), STATIC, SUFIX.
"""
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

STEP = 12.0
LANE_Z = 6.2
HW = 6.0
DECK = float(os.environ.get("DECK", "300"))
OFFSET = float(os.environ.get("OFFSET", "3.5"))
TRANS = float(os.environ.get("TRANS", "30"))
TAPER = float(os.environ.get("TAPER", "30"))
BLOCK_W = 0.6
HW_DECK = HW + OFFSET + BLOCK_W * 0.5 + 0.0   # 9.8: fata barierei de pe partea cealalta
DECK_HALF = LANE_Z + HW                        # 12.2: fata interioara a parapetului
TRUCK_SPEED = float(os.environ.get("TRUCK_SPEED", "4.0"))
DWELL = float(os.environ.get("DWELL", "6.0"))
PHASE = float(os.environ.get("PHASE", "0.0"))
R = float(os.environ.get("R", "20"))
# raza viraielor de racord (dreapta THETA) ale balonului: larga, ca masina care
# iese din balon sa nu fie aruncata spre capul despartitorului fix
R_IN = float(os.environ.get("R_IN", "40"))
# Intre balon si coridorul cu doua sensuri benzile se DESPART: fiecare se muta
# SPLIT_D m spre exterior pe SPLIT_L m (doua arce in S, raza ~114 m). Masurat in
# runda 1-2: cu balonul lipit de capul despartitorului, iesirea din ultimul viraj
# (trasa de cursa: apex in interior, iesire spre exterior = spre despartitor)
# arunca masinile in capul lui sau PE SENSUL OPUS (3 „treceri" pe 16 seed-uri,
# toate venite pe langa cap, si 4 ejectari pe latura lui, la fel cu bariera fixa).
SPLIT_D = float(os.environ.get("SPLIT_D", "8"))
SPLIT_L = float(os.environ.get("SPLIT_L", "60"))
# capul despartitorului fix la gatul fiecarui balon: atenuator de impact (corp
# MOALE, `soft_hit_crush`), nu zid de beton cu fata spre trafic
CUSHION = 6.0
GRADE = float(os.environ.get("GRADE", "0.115"))
Y0 = float(os.environ.get("Y0", "12"))
EASE = 24.0
CLIMB = 72.0
LANDING = 36.0
X_START = 48.0
FLAT_RUN = 36.0           # elan plat de la start la piciorul rampei
FIX = os.environ.get("FIX", "0") == "1"
AI = os.environ.get("AI", "1") == "1"
STATIC = os.environ.get("STATIC", "0") == "1"
SUFIX = os.environ.get("SUFIX", "")

# Segmentele drepte, in ordinea benzii DUS: (lungime, panta)
SEGS = [
    (FLAT_RUN, 0.0),
    (EASE, GRADE * 0.5),
    (CLIMB, GRADE),
    (EASE, GRADE * 0.5),
    (LANDING, 0.0),
    (DECK, 0.0),
    (LANDING, 0.0),
]
X_RAMP = X_START + FLAT_RUN
Y_D = Y0 + sum(l * g for l, g in SEGS)
X_D0 = X_START + sum(l for l, _ in SEGS[:5])
X_D1 = X_D0 + DECK
X_F = X_D1 + LANDING
X_LAND0 = X_D0 - LANDING


def y_of_x(x):
    """Cota soselei (ambele benzi) la abscisa x."""
    y = Y0
    x0 = X_START
    for length, g in SEGS:
        if x <= x0:
            return y
        if x <= x0 + length:
            return y + (x - x0) * g
        y += length * g
        x0 += length
    return y


class Turtle:
    """0 = +X, dreapta (spre +Z) = theta creste (ca gen_sf_sonda.py)."""

    def __init__(self, x, z, th):
        self.x, self.z, self.th = x, z, th
        self.pts = [(x, z)]

    def straight(self, length):
        n = max(1, int(round(length / STEP)))
        for k in range(1, n + 1):
            t = k / n
            self.pts.append((self.x + math.cos(self.th) * length * t,
                             self.z + math.sin(self.th) * length * t))
        self.x += math.cos(self.th) * length
        self.z += math.sin(self.th) * length

    def arc(self, radius, angle_deg, right):
        sgn = 1.0 if right else -1.0
        cx = self.x + math.cos(self.th + sgn * math.pi / 2) * radius
        cz = self.z + math.sin(self.th + sgn * math.pi / 2) * radius
        a0 = math.atan2(self.z - cz, self.x - cx)
        total = math.radians(angle_deg) * sgn
        npts = max(3, int(round(abs(total) * radius / 10.0)) + 1)
        for k in range(1, npts):
            a = a0 + total * k / (npts - 1)
            self.pts.append((cx + math.cos(a) * radius, cz + math.sin(a) * radius))
        a1 = a0 + total
        self.x = cx + math.cos(a1) * radius
        self.z = cz + math.sin(a1) * radius
        self.th += total


def split(t, out):
    """S-ul dintre coridor si balon: `out` = banda se departeaza de axa (spre
    dreapta ei), altfel se apropie. Doua arce egale, deplasare SPLIT_D pe SPLIT_L."""
    alpha = 2.0 * math.atan2(SPLIT_D, SPLIT_L)
    rad = SPLIT_L / (2.0 * math.sin(alpha))
    t.arc(rad, math.degrees(alpha), out)
    t.arc(rad, math.degrees(alpha), not out)


def balloon(t):
    """Intoarcere pe stanga intre doua benzi la 2*W (W = LANE_Z + SPLIT_D):
    dreapta THETA la R_IN, stanga 180+2*THETA la R, dreapta THETA la R_IN."""
    w = LANE_Z + SPLIT_D
    dx = math.sqrt((R + R_IN) ** 2 - (w + R_IN) ** 2)
    theta = 90.0 - math.degrees(math.atan2(w + R_IN, dx))
    t.arc(R_IN, theta, True)
    t.arc(R, 180.0 + 2.0 * theta, False)
    t.arc(R_IN, theta, True)
    return theta


def build():
    t = Turtle(X_START, LANE_Z, 0.0)
    for length, _ in SEGS:
        t.straight(length)
    split(t, True)
    theta = balloon(t)
    split(t, False)
    assert abs(t.x - X_F) < 0.05 and abs(t.z + LANE_Z) < 0.05, (t.x, t.z)
    for length, _ in reversed(SEGS):
        t.straight(length)
    t.straight(X_START)                     # pana la capul coridorului (x = 0)
    split(t, True)
    balloon(t)
    split(t, False)
    assert abs(t.x) < 0.05 and abs(t.z - LANE_Z) < 0.05, (t.x, t.z)
    t.straight(X_START)                     # dreapta de grila
    last = t.pts.pop()
    assert abs(last[0] - X_START) < 0.05 and abs(last[1] - LANE_Z) < 0.05, last
    pts = [(x, y_of_x(min(max(x, 0.0), X_F)), z) for x, z in t.pts]
    return pts, theta


def curve_data(points, closed=True):
    flat = []
    for p in points:
        flat += [0, 0, 0, 0, 0, 0, p[0], p[1], p[2]]
    txt = ", ".join(("%.3f" % v).rstrip("0").rstrip(".") for v in flat)
    tilts = ", ".join("0" for _ in points)
    return (("closed = true\n" if closed else "") +
            '_data = {\n"points": PackedVector3Array(%s),\n'
            '"tilts": PackedFloat32Array(%s)\n}\npoint_count = %d\n' % (txt, tilts, len(points)))


def cumul(pts):
    cum = [0.0]
    for a, b in zip(pts, pts[1:] + pts[:1]):
        cum.append(cum[-1] + math.dist(a, b))
    return cum


def frac_of(pts, cum, x, lane_sign):
    """Fractia (pe lungimea poligonului) la abscisa x pe banda data (+1 dus, -1 intors)."""
    best, bi = 1e9, 0
    for i, p in enumerate(pts):
        if (p[2] > 0) != (lane_sign > 0) or abs(abs(p[2]) - LANE_Z) > 0.05:
            continue
        d = abs(p[0] - x)
        if d < best:
            best, bi = d, i
    # interpolare pe segmentul drept
    p = pts[bi]
    return (cum[bi] + (x - p[0]) * (1.0 if lane_sign > 0 else -1.0)) / cum[-1]


def box(sub, nodes, key, name, parent, size, xform, mesh=True, coll=True, mat="Mat_gri"):
    sid = "Box_%s" % key
    if sid not in sub:
        sub[sid] = '[sub_resource type="BoxShape3D" id="%s"]\nsize = Vector3(%.3f, %.3f, %.3f)\n' % (
            sid, size[0], size[1], size[2])
        sub["Mesh_" + key] = ('[sub_resource type="BoxMesh" id="Mesh_%s"]\nsize = Vector3(%.3f, %.3f, %.3f)\n'
                              'material = SubResource("%s")\n' % (key, size[0], size[1], size[2], mat))
    tx = "transform = Transform3D(%s)\n" % ", ".join("%.5f" % v for v in xform)
    if coll:
        nodes.append('[node name="%s" type="CollisionShape3D" parent="%s"]\n%sshape = SubResource("%s")\n' % (
            name, parent, tx, sid))
    if mesh:
        nodes.append('[node name="%sM" type="MeshInstance3D" parent="%s"]\n%smesh = SubResource("Mesh_%s")\n' % (
            name, parent if not coll else parent, tx, key))


def xf_pitch(cx, cy, cz, pitch):
    """Basis cu rotatie in jurul lui Z (panta in planul XY), pozitie (cx, cy, cz)."""
    c, s = math.cos(pitch), math.sin(pitch)
    # coloane: X = (c, s, 0), Y = (-s, c, 0), Z = (0, 0, 1)
    return (c, s, 0, -s, c, 0, 0, 0, 1, cx, cy, cz)


def main():
    pts, theta = build()
    cum = cumul(pts)
    total = cum[-1]
    mean_y = sum((a[1] + b[1]) * 0.5 * math.dist(a, b) for a, b in zip(pts, pts[1:] + pts[:1])) / total
    sea_offset = round(0.0 - mean_y, 3)
    f = lambda x, s: frac_of(pts, cum, x, s)
    # fractiile tablierului pe cele doua treceri (pe DUS x creste, pe INTORS scade)
    o_d0, o_d1 = f(X_D0, 1), f(X_D1, 1)
    r_d1, r_d0 = f(X_D1, -1), f(X_D0, -1)
    # rapa: putin inauntrul tablierului (racordul RAVINE_FADE_FRAC iese in afara)
    o_r0, o_r1 = f(X_D0 + 10.0, 1), f(X_D1 - 10.0, 1)
    r_r0, r_r1 = f(X_D1 - 10.0, -1), f(X_D0 + 10.0, -1)
    # latimea: rampa de 30 m (Track.WIDTH_RAMP_M) INAUNTRUL sectorului
    o_w0, o_w1 = f(X_D0 - 30.0, 1), f(X_D1 + 30.0, 1)
    r_w0, r_w1 = f(X_D1 + 30.0, -1), f(X_D0 - 30.0, -1)
    name = "SondaSfPod" + SUFIX
    depth = Y_D + 9.0

    sub = {}
    nodes = []
    # despartitorul fix pe pamant: de la gatul balonului de start (x 0) pana la
    # palier (X_LAND0), pe segmentele de 12 m ale rampei
    nodes.append('[node name="DespartitorFixRampa" type="StaticBody3D" parent="Static"]\n')
    xs = [CUSHION]
    x = CUSHION
    while x < X_LAND0 - 0.01:
        # rupturi la capetele segmentelor de panta
        nxt = min(x + STEP, X_LAND0)
        for xb in (X_RAMP, X_RAMP + EASE, X_RAMP + EASE + CLIMB):
            if x + 0.01 < xb < nxt - 0.01:
                nxt = xb
        xs.append(nxt)
        x = nxt
    bh, bw = 0.95, BLOCK_W
    for k, (xa, xb) in enumerate(zip(xs, xs[1:])):
        ya, yb = y_of_x(xa), y_of_x(xb)
        L = math.hypot(xb - xa, yb - ya)
        pitch = math.atan2(yb - ya, xb - xa)
        cx, cy = (xa + xb) * 0.5, (ya + yb) * 0.5
        # centrul cutiei la bh/2 deasupra drumului (pe normala), scufundat 5 cm
        nx, ny = -math.sin(pitch), math.cos(pitch)
        off = bh * 0.5 - 0.05
        box(sub, nodes, "fix%d" % int(round(L * 100)), "F%d" % k, "Static/DespartitorFixRampa",
            (L + 0.1, bh, bw), xf_pitch(cx + nx * off, cy + ny * off, 0.0, pitch))
    nodes.append('[node name="Atenuator" type="StaticBody3D" parent="Static"]\nmetadata/soft_hit_crush = 1.0\n')
    yc = y_of_x(CUSHION * 0.5)
    box(sub, nodes, "cushion", "Cap", "Static/Atenuator", (CUSHION, 0.95, 0.9),
        (1, 0, 0, 0, 1, 0, 0, 0, 1, CUSHION * 0.5, yc + 0.425, 0.0), mat="Mat_galben")
    # parapetele exterioare (perete vertical 1,2 m), pe tablier + 12 m, cu capetele
    # EVAZATE spre exterior (20 grade pe 10 m): un capat de zid cu fata spre trafic
    # ejecta masinile impinse spre margine la start (masurat, 2 ejectari / 16 seed-uri)
    nodes.append('[node name="Parapet" type="StaticBody3D" parent="Static"]\n')
    pa, pb = X_D0 - 12.0, X_D1 + 12.0
    par_len = pb - pa
    flare_l, flare_a = 10.0, math.radians(20.0)
    for side, nm in ((1, "Dus"), (-1, "Intors")):
        zc = side * (DECK_HALF + 0.25)
        box(sub, nodes, "parapet", "Parapet" + nm, "Static/Parapet", (par_len, 1.2, 0.5),
            (1, 0, 0, 0, 1, 0, 0, 0, 1, (pa + pb) * 0.5, Y_D + 0.55, zc))
        for end, xe in (("A", pa), ("B", pb)):
            dx = -1.0 if end == "A" else 1.0
            cxf = xe + dx * math.cos(flare_a) * flare_l * 0.5
            czf = zc + side * math.sin(flare_a) * flare_l * 0.5
            # axa X a cutiei pe directia (dx*cos, side*sin) in planul XZ; Basis(UP, yaw)
            # duce X in (cos yaw, 0, -sin yaw)
            yaw = math.atan2(-side * math.sin(flare_a), dx * math.cos(flare_a))
            c_, s_ = math.cos(yaw), math.sin(yaw)
            box(sub, nodes, "flare", "Evazare%s%s" % (nm, end), "Static/Parapet", (flare_l, 1.2, 0.5),
                (c_, 0, -s_, 0, 1, 0, s_, 0, c_, cxf, y_of_x(xe) + 0.55, czf))
    # turnurile podului: portaluri, picioarele in afara tablierului, traversa la +10 si +36
    nodes.append('[node name="Turnuri" type="StaticBody3D" parent="Static"]\n')
    tower_h = 45.0
    leg_z = DECK_HALF + 2.3
    for ti, xt in enumerate((X_D0 + DECK * 0.25, X_D0 + DECK * 0.75)):
        for side in (1, -1):
            box(sub, nodes, "leg", "T%dPicior%d" % (ti, side + 1), "Static/Turnuri", (3.0, tower_h + 8.0, 3.0),
                (1, 0, 0, 0, 1, 0, 0, 0, 1, xt, Y_D + tower_h * 0.5 - 4.0, side * leg_z), mat="Mat_rosu")
        for bi, yb in enumerate((Y_D + 10.0, Y_D + tower_h - 6.0)):
            box(sub, nodes, "beam", "T%dTraversa%d" % (ti, bi), "Static/Turnuri", (2.4, 2.4, 2 * leg_z + 3.0),
                (1, 0, 0, 0, 1, 0, 0, 0, 1, xt, yb, 0.0), coll=False, mat="Mat_rosu")

    meta = {
        "x_d0": X_D0, "x_d1": X_D1, "x_land0": X_LAND0, "x_f": X_F, "y_deck": Y_D, "y0": Y0,
        "lane_z": LANE_Z, "deck_half": DECK_HALF, "hw": HW, "hw_deck": HW_DECK,
        "o_deck": [o_d0, o_d1], "r_deck": [r_d1, r_d0],
    }
    meta_txt = "{" + ", ".join(
        '"%s": %s' % (k, ("Vector2(%.5f, %.5f)" % tuple(v)) if isinstance(v, list) else ("%.4f" % v))
        for k, v in meta.items()) + "}"
    head = [
        "[gd_scene format=3]", "",
        '[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]',
        '[ext_resource type="PackedScene" path="res://scenes/hazards/MovableMedian.tscn" id="2_median"]', "",
        '[sub_resource type="Curve3D" id="Curve3D_route"]\n' + curve_data(pts), "",
        '[sub_resource type="StandardMaterial3D" id="Mat_gri"]\nalbedo_color = Color(0.62, 0.62, 0.6, 1)\n',
        '[sub_resource type="StandardMaterial3D" id="Mat_rosu"]\nalbedo_color = Color(0.72, 0.22, 0.14, 1)\n',
        '[sub_resource type="StandardMaterial3D" id="Mat_galben"]\nalbedo_color = Color(0.85, 0.72, 0.2, 1)\n',
    ]
    head += [v for v in sub.values()]
    scene = head + [
        '[node name="%s" type="Node3D"]' % name,
        'script = ExtResource("1_track")',
        'custom_name = "Sonda SF pod%s"' % (" " + SUFIX if SUFIX else ""),
        'custom_theme = "sanfrancisco"',
        'custom_world_seed_name = "sonda_sf_pod"',
        "custom_half_width = %.1f" % HW,
        'custom_gate_model = "none"',
        "custom_sea_level_offset = %.3f" % sea_offset,
        "custom_ravines = Array[Vector4]([Vector4(%.5f, %.5f, %.1f, 0), Vector4(%.5f, %.5f, %.1f, 0)])" % (
            o_r0, o_r1, depth, r_r0, r_r1, depth),
        "custom_viaduct_ravines = Array[int]([0, 1])",
        "custom_viaduct_net_margin = 12.0",
        "custom_width_segments = Array[Vector3]([Vector3(%.5f, %.5f, %.2f), Vector3(%.5f, %.5f, %.2f)])" % (
            o_w0, o_w1, HW_DECK, r_w0, r_w1, HW_DECK),
        "custom_sun_rotation_deg = Vector3(-28, -102, 0)",
        "metadata/sf_pod = %s" % meta_txt,
        "",
        '[node name="Path" type="Path3D" parent="."]',
        'curve = SubResource("Curve3D_route")', "",
        '[node name="Hazarduri" type="Node3D" parent="."]', "",
        '[node name="Despartitor" parent="Hazarduri" instance=ExtResource("2_median")]',
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, 0)" % (X_D0, Y_D),
        "deck_length = %.1f" % DECK,
        "offset_m = %.2f" % OFFSET,
        "transition_m = %.1f" % TRANS,
        "taper_m = %.1f" % TAPER,
        "approach_m = %.1f" % LANDING,
        "deck_half_width = %.2f" % DECK_HALF,
        "cushion_far_m = %.1f" % CUSHION,
        "truck_speed = %.2f" % TRUCK_SPEED,
        "truck_dwell_s = %.2f" % DWELL,
        "phase = %.4f" % PHASE,
        "static_center = %s" % ("true" if FIX else "false"),
        "truck_enabled = %s" % ("false" if FIX else "true"),
        "ai_reads_corridor = %s" % ("true" if AI else "false"),
        "ai_static_read = %s" % ("true" if STATIC else "false"),
        "",
        '[node name="Static" type="Node3D" parent="."]', "",
    ] + nodes
    out = os.path.join(ROOT, "tools", name + ".tscn")
    open(out, "w", newline="\n").write("\n".join(scene))
    s_lo = TAPER + TRANS * 0.5
    s_hi = DECK - TAPER - TRANS * 0.5
    cyc = 2.0 * ((s_hi - s_lo) / TRUCK_SPEED + DWELL)
    print("scris %s: bucla %d puncte, %.0f m; balon R%.0f theta %.1f; Y0 %.1f -> tablier %.2f "
          "(x %.0f..%.0f, %.0f m), apa la 0 (sea_offset %.3f, media %.2f); camion %.1f m/s, "
          "naveta %.0f m, ciclu %.1f s; fractii dus %.4f-%.4f intors %.4f-%.4f" % (
              os.path.relpath(out, ROOT), len(pts), total, R, theta, Y0, Y_D, X_D0, X_D1, DECK,
              sea_offset, mean_y, TRUCK_SPEED, s_hi - s_lo, cyc, o_d0, o_d1, r_d1, r_d0))


if __name__ == "__main__":
    sys.exit(main())
