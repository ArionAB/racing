"""Monument Valley -- drum, gard si semne (brief docs/asset_briefs/monumentvalley_kit.md §1.4).

  monumentvalley/props/cattle_guard.glb        grila PLATA de bare peste drum, 14 x 2.4 m
  monumentvalley/props/open_range_sign.glb     romb galben cu cal in relief, stalp 2.6 m
  monumentvalley/structures/telegraph_pole.glb stalp 8 m, traversa 2 m, 3 izolatori (fara fire)
  monumentvalley/structures/wire_fence.glb     segment inlantuibil 4 m (Y), 1.2 m
  monumentvalley/structures/windmill_pump.glb  turn 9 m, rotor pe nod propriu, jgheab
  monumentvalley/structures/water_tower.glb    rezervor cu doage, capac conic, turn in X, scara
  monumentvalley/structures/corral.glb         tarc 10 x 8 m, 3 bare, o poarta
  monumentvalley/structures/shade_ramada.glb   5 x 4 x 3 m, acoperis de barne cu goluri, masa

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_monument_road.py

Fara text, cifre sau logo-uri (brief §0 pct. 9). Fata = +Y in Blender.
Primitive rotunde cu segmente explicite (8-12).
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "monument_shapes.py")).read())

# Sloturi (brief monumentvalley_kit §0 "Sloturi pe roluri")
STEEL = CONCRETE            # otelul (8)
RUSTY = RUST                # rugina (10)
TIMBER = WOOD               # lemnul (9)
TIMBER_OLD = LOG_DARK       # lemnul vechi / umbrit (28)
HAZ_YELLOW = SAND_LIGHT     # galben de avertizare FARA slot de masina (0)
HAZ_BLACK = VOLCANIC_BLACK  # negru (20)

clear_built()


# ---------------------------------------------------------------------------
# ajutoare locale
# ---------------------------------------------------------------------------

def sq_loft(b, cx, cy, hw0, z0, hw1, z1, slot):
    """Stalp cu sectiune patrata care se subtiaza (loft de doua patrate)."""
    bot = [(cx - hw0, cy - hw0), (cx + hw0, cy - hw0), (cx + hw0, cy + hw0), (cx - hw0, cy + hw0)]
    top = [(cx - hw1, cy - hw1), (cx + hw1, cy - hw1), (cx + hw1, cy + hw1), (cx - hw1, cy + hw1)]
    loft(b, bot, z0, top, z1, slot)


def _extrude(b, pts3_front, pts3_back, slot):
    """Placa din doua contururi 3D (fata si spate, aceeasi ordine): n-gon fata,
    n-gon spate, laterale; fetele concave se triunghiulaza."""
    n = len(pts3_front)
    fv = [b.bm.verts.new(p) for p in pts3_front]
    bv = [b.bm.verts.new(p) for p in pts3_back]
    faces = [b.bm.faces.new(fv), b.bm.faces.new(list(reversed(bv)))]
    for i in range(n):
        j = (i + 1) % n
        faces.append(b.bm.faces.new((bv[i], bv[j], fv[j], fv[i])))
    for f in faces:
        f[b.slot] = slot
    bmesh.ops.triangulate(b.bm, faces=faces[:2])


def extrude_xz(b, pts, y0, y1, slot, mirror=True, off=(0.0, 0.0), scale=1.0):
    """Silueta data in coordonate de ECRAN (sx spre dreapta, z in sus), vazuta
    din +Y (fata): ecranul-dreapta e -X in lume, deci `mirror` rastoarna sx.
    Extrudata intre y0 si y1."""
    p = [((-sx if mirror else sx) * scale + off[0], z * scale + off[1]) for sx, z in pts]
    _extrude(b, [(x, y1, z) for x, z in p], [(x, y0, z) for x, z in p], slot)


def extrude_yz(b, pts, x0, x1, slot):
    """Placa subtire in planul YZ (pts = (y, z)), extrudata intre x0 si x1."""
    _extrude(b, [(x1, y, z) for y, z in pts], [(x0, y, z) for y, z in pts], slot)


# emit local: ca `emit` din monument_shapes, dar nodurile cu pivot propriu
# (rotorul morii) isi pastreaza `location`; offsetul pe Z se aplica pe pivot.
def emit_road(objs, path, ao, budget=None, keep_xy=True):
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            p = v.co + o.location
            xs.append(p.x); ys.append(p.y); zs.append(p.z)
    place = Vector((0.0 if keep_xy else -(min(xs) + max(xs)) * 0.5,
                    0.0 if keep_xy else -(min(ys) + max(ys)) * 0.5,
                    -min(zs)))
    total, per_node = 0, {}
    for o in objs:
        if o.location.length > 1e-9:
            o.location += place
        else:
            for v in o.data.vertices:
                v.co += place
        a = dict(ao)
        if o.get("ao_radial_y"):
            a.update(gradient="radial", radial_axis="Y")
        st = finish(o, bevel=0.0, ao=a, origin=None, smooth_angle=None)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            p = v.co + o.location
            xs.append(p.x); ys.append(p.y); zs.append(p.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "monumentvalley/" + path)
    RESULTS.append((path, total, dims, budget, per_node, sz / 1024.0))
    print("   %s: x %.3f..%.3f  y %.3f..%.3f  z %.3f..%.3f" %
          (path, min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
    return total


AO_OPEN = dict(samples=16, dist=1.2, gradient="vertical",
               low=0.62, high=1.0, power=0.8, floor=0.30)


# ---------------------------------------------------------------------------
# 1. cattle_guard
# ---------------------------------------------------------------------------

def build_cattle_guard():
    """`cattle_guard.png`, CORECTAT de coordonator: PLAT (nu rampa in trepte).
    Lista de elemente (numarata pe decupare, apoi adaptata):
    - 11 bare tubulare de otel (decupare: ~9-10 bare, contract 10-12), culcate
      pe X (14 m), distribuite pe Y (pas 0,19 m), varful la <= 0,15 m;
    - 2 sine de rama pe lungime (y = +-1,13) si 7 traverse sub bare (rugina);
    - 2 capete de rama galben-negru (decupara: cadre galbene inclinate la
      capetele grilei -> aici plate, 6 blocuri alternante de 0,4 m);
    - 2 stalpi scurti galben-negru la x = +-7,3, 1,2 m, 6 benzi alternante.
    Noduri: Guard_Steel (CONCRETE + RUST), Guard_Posts (galben + negru).
    """
    s = Builder()
    for k in range(11):
        y = -0.95 + 0.19 * k
        s.cylinder((0.0, y, 0.098), 0.05, 14.0, STEEL, segments=8, axis="X")
    for sy in (-1.13, 1.13):
        s.box((0.0, sy, 0.065), (14.0, 0.14, 0.13), RUSTY)
    for tx in (-6.8, -4.5, -2.25, 0.0, 2.25, 4.5, 6.8):
        s.box((tx, 0.0, 0.035), (0.14, 2.26, 0.07), RUSTY)

    p = Builder()
    for sx in (-1, 1):
        # capul de rama: peste ultima traversa, galben-negru in blocuri de 0,4 m
        for k in range(6):
            y = -1.0 + 0.4 * k
            p.box((sx * 7.1, y, 0.07), (0.2, 0.4, 0.14), HAZ_YELLOW if k % 2 == 0 else HAZ_BLACK)
        # stalpul scurt de capat
        for k in range(6):
            p.box((sx * 7.3, 0.0, 0.1 + 0.2 * k), (0.25, 0.25, 0.2),
                  HAZ_YELLOW if k % 2 == 0 else HAZ_BLACK)
    return [s.to_object("Guard_Steel"), p.to_object("Guard_Posts")]


# ---------------------------------------------------------------------------
# 2. open_range_sign
# ---------------------------------------------------------------------------

HORSE_BODY = [(-0.36, 0.05), (-0.35, 0.11), (-0.29, 0.18), (-0.27, 0.26), (-0.24, 0.18),
              (-0.20, 0.17), (-0.12, 0.13), (-0.04, 0.09), (0.12, 0.07), (0.21, 0.09), (0.26, 0.03),
              (0.24, -0.07), (0.10, -0.07), (-0.10, -0.07), (-0.15, -0.03), (-0.20, 0.05),
              (-0.28, 0.04)]
HORSE_LEGS = [
    [(-0.15, -0.05), (-0.105, -0.05), (-0.12, -0.29), (-0.165, -0.29)],
    [(-0.09, -0.05), (-0.045, -0.05), (-0.01, -0.29), (-0.055, -0.29)],
    [(0.12, -0.05), (0.17, -0.05), (0.15, -0.29), (0.105, -0.29)],
    [(0.19, -0.05), (0.24, -0.05), (0.29, -0.29), (0.245, -0.29)],
]
HORSE_TAIL = [(0.23, 0.08), (0.27, 0.05), (0.31, -0.10), (0.30, -0.22), (0.27, -0.22), (0.26, -0.08)]


def build_open_range_sign():
    """`open_range_sign.png`:
    - STALP: 1 stalp drept de lemn 0,12 m, 2,6 m, cu un varf mic care iese
      deasupra rombului;
    - ROMB: 1 placa galbena in picioare (diagonala 1,27 m, latura 0,9 m), centrul
      la 1,95 m, ancorata pe stalp, cu chenar subtire de lemn pe cele 4 laturi;
    - CAL: siluet negru in relief (corp+gat+cap cu 2 urechi, 4 picioare, coada),
      orientat spre stanga ecranului, ocupa ~65% din latimea rombului, FARA text.
    Noduri: Sign_Post (stalp + chenar), Sign_Face (CAR_YELLOW), Sign_Horse (relief).
    """
    cz, fy = 1.95, 0.06
    post = Builder()
    sq_loft(post, 0.0, 0.0, 0.06, 0.0, 0.055, 2.62, TIMBER)
    R = 0.66
    corners = [(0.0, R), (R, 0.0), (0.0, -R), (-R, 0.0)]
    for i in range(4):
        a, c = corners[i], corners[(i + 1) % 4]
        post.beam((a[0], fy + 0.02, cz + a[1]), (c[0], fy + 0.02, cz + c[1]), (0.07, 0.09), TIMBER_OLD,
                  up=(0, 1, 0))

    face = Builder()
    face.prism([(0.0, 0.64), (0.64, 0.0), (0.0, -0.64), (-0.64, 0.0)], 0.05, CAR_YELLOW,
               center=(0.0, fy, cz))

    horse = Builder()
    off = (-0.02, cz + 0.05)
    y0, y1 = fy + 0.025, fy + 0.075
    extrude_xz(horse, HORSE_BODY, y0, y1, TIMBER_OLD, off=off, scale=1.0)
    for leg in HORSE_LEGS:
        extrude_xz(horse, leg, y0, y1, TIMBER_OLD, off=off, scale=1.0)
    extrude_xz(horse, HORSE_TAIL, y0, y1, TIMBER_OLD, off=off, scale=1.0)
    return [post.to_object("Sign_Post"), face.to_object("Sign_Face"), horse.to_object("Sign_Horse")]


# ---------------------------------------------------------------------------
# 3. telegraph_pole
# ---------------------------------------------------------------------------

def build_telegraph_pole():
    """`telegraph_pole.png`:
    - STALP: 1 stalp de lemn cu sectiune patrata care se subtiaza (0,30 -> 0,20 m),
      7,84 m, drept;
    - TRAVERSA: 1 grinda de 2,0 m x 0,14 m la 7,2 m, perpendiculara pe linia
      stalpilor, trece prin stalp;
    - 2 SPRIJINE oblice (V) de la stalp (6,3 m) la traversa (+-0,55 m);
    - 3 IZOLATORI: 2 la capetele traversei, 1 in varf (decupara: 2 pe traversa
      + stalpul continua putin deasupra).
    Fara fire (le face codul). Noduri: Pole_Wood, Pole_Insulators.
    """
    w = Builder()
    sq_loft(w, 0.0, 0.0, 0.16, 0.0, 0.105, 7.84, TIMBER)
    w.box((0.0, 0.0, 7.2), (2.0, 0.2, 0.2), TIMBER)
    for sx in (-1, 1):
        w.beam((sx * 0.06, 0.0, 6.25), (sx * 0.62, 0.0, 7.16), (0.08, 0.09), TIMBER_OLD, up=(0, 1, 0))
    ins = Builder()
    for (ix, iz) in ((-0.9, 7.3), (0.9, 7.3), (0.0, 7.84)):
        ins.frustum((ix, 0.0, iz + 0.05), 0.11, 0.08, 0.10, FOAM_WHITE, segments=8)
        ins.frustum((ix, 0.0, iz + 0.15), 0.07, 0.05, 0.10, FOAM_WHITE, segments=8)
    return [w.to_object("Pole_Wood"), ins.to_object("Pole_Insulators")]


# ---------------------------------------------------------------------------
# 4. wire_fence
# ---------------------------------------------------------------------------

def build_wire_fence():
    """`wire_fence.png`:
    - 2 STALPI de lemn la capete (0,18 x 0,18 m, 1,2 m), cu fetele exterioare
      FLUSH la y = +-2,0 (modul inlantuibil: capetele plane);
    - 4 FIRE intinse intre stalpi (decupara: 4 randuri, la 0,28 / 0,55 / 0,82 /
      1,08 m), pe fata +X a stalpilor, taiate plan la y = +-2,0;
    - 4 TEPI (noduri mici in diamant) pe fiecare fir.
    Contractul spune 3 fire, decupara 4: aleg decupara (numarul de elemente de
    pe planse castiga). Noduri: Fence_Posts, Fence_Wire.
    """
    p = Builder()
    for sy in (-1.91, 1.91):
        p.box((0.0, sy, 0.6), (0.18, 0.18, 1.2), TIMBER)
    w = Builder()
    rnd = _lcg(5)
    for zi, wz in enumerate((0.28, 0.55, 0.82, 1.08)):
        w.beam((0.12, -2.0, wz), (0.12, 2.0, wz), (0.045, 0.045), RUSTY, up=(1, 0, 0))
        for k in range(4):
            y = -1.2 + 0.8 * k + (rnd() - 0.5) * 0.15
            w.box((0.12, y, wz), (0.085, 0.085, 0.085), RUSTY,
                  rotation=Matrix.Rotation(math.radians(45), 3, "Y"))
    return [p.to_object("Fence_Posts"), w.to_object("Fence_Wire")]


# ---------------------------------------------------------------------------
# 5. windmill_pump
# ---------------------------------------------------------------------------

MILL_TOP = 8.7
MILL_BASE_HALF = 1.1
MILL_TOP_HALF = 0.28
HUB = (0.0, 0.55, 9.0)
ROTOR_R = 1.25
TROUGH_Y = 2.15
CORNERS = [(1, 1), (1, -1), (-1, -1), (-1, 1)]


def _leg(i, z):
    t = z / MILL_TOP
    h = MILL_BASE_HALF + (MILL_TOP_HALF - MILL_BASE_HALF) * t
    cx, cy = CORNERS[i]
    return Vector((cx * h, cy * h, z))


def build_windmill_pump():
    """`windmill_pump.png`:
    - TURN: lattice de otel cu 4 picioare evazate (baza 1,8 m, varf 0,56 m),
      9 m (capul la 8,7 m), 4 centuri orizontale (1,8 / 3,9 / 5,9 / 7,6 m) si
      X in fiecare din cele 4 deschideri pe fiecare dintre cele 4 fete;
    - CAP: cutie de angrenaj + bara de transmisie centrala (tija pompei) pe tot
      turnul; carcasa pompei la baza cu un jgheab de scurgere spre trough;
    - COADA: bratul spre -Y (2,4 m) + vana verticala trapezoidala, lata la capat;
    - ROTOR: Ø 2,5 m, ~18 pale pitched, 2 inele (r 0,6 si 1,2), butuc; NOD
      SEPARAT `Windmill_Rotor`, pivot in centrul butucului, axa de rotatie =
      axa Y Blender (= Z local Godot);
    - JGHEAB: rotund, Ø 3 m, 0,6 m inalt, 10 laturi, perete gros cu apa pe
      interior, in fata turnului (+Y).
    Noduri: Mill_Steel, Mill_Trough, Windmill_Rotor.
    """
    s = Builder()
    for i in range(4):
        s.beam(_leg(i, 0.0), _leg(i, MILL_TOP), 0.09, STEEL)
    levels = [1.8, 3.9, 5.9, 7.6]
    for z in levels:
        for i in range(4):
            s.beam(_leg(i, z), _leg((i + 1) % 4, z), 0.06, STEEL)
    zs = [0.0] + levels
    for z0, z1 in zip(zs, zs[1:]):
        for i in range(4):
            j = (i + 1) % 4
            s.beam(_leg(i, z0), _leg(j, z1), 0.05, RUSTY)
            s.beam(_leg(j, z0), _leg(i, z1), 0.05, RUSTY)
    # cap + tija + coada
    s.box((0.0, 0.1, 8.85), (0.36, 0.8, 0.32), STEEL)
    s.box((0.0, 0.0, 8.62), (0.7, 0.7, 0.08), RUSTY)
    s.beam((0.0, 0.0, 0.5), (0.0, 0.0, 8.6), 0.06, RUSTY)
    s.box((0.0, 0.0, 0.5), (0.3, 0.3, 0.9), STEEL)
    s.beam((0.0, 0.1, 0.85), (0.0, 1.55, 0.7), 0.1, RUSTY)
    s.beam((0.0, -0.3, 8.95), (0.0, -2.4, 8.95), 0.07, STEEL)
    extrude_yz(s, [(-0.9, 9.1), (-2.55, 9.75), (-2.55, 8.6), (-0.9, 8.85)], -0.025, 0.025, RUSTY)

    t = Builder()
    t.revolve([(1.45, 0.0), (1.5, 0.06), (1.5, 0.6), (1.38, 0.6), (1.36, 0.1)], STEEL,
              segments=10, origin=(0.0, TROUGH_Y, 0.0), cap_bottom=True)
    t.cylinder((0.0, TROUGH_Y, 0.22), 1.38, 0.44, ASPHALT, segments=10)

    r = Builder()
    r.cylinder((0.0, 0.0, 0.0), 0.17, 0.2, RUSTY, segments=8, axis="Y")
    n = 18
    for k in range(n):
        th = 2 * math.pi * k / n
        c = 0.78                                   # centrul radial al palei
        rot = (Matrix.Rotation(th, 3, "Y") @ Matrix.Rotation(math.radians(18), 3, "Z"))
        pos = Vector((math.sin(th) * c, 0.0, math.cos(th) * c))
        r.box(pos, (0.2, 0.04, 0.95), STEEL, rotation=rot)
    r.torus((0, 0, 0), 0.62, 0.03, RUSTY, major_seg=18, minor_seg=4, axis="Y")
    r.torus((0, 0, 0), 1.2, 0.03, RUSTY, major_seg=18, minor_seg=4, axis="Y")

    steel = s.to_object("Mill_Steel")
    trough = t.to_object("Mill_Trough")
    rotor = r.to_object("Windmill_Rotor")
    rotor.location = Vector(HUB)
    rotor["ao_radial_y"] = True
    return [steel, trough, rotor]


# ---------------------------------------------------------------------------
# 6. water_tower
# ---------------------------------------------------------------------------

def _staves(r, notch=0.04, n=12):
    """Contur de rezervor cu doage: n fete plate cu cate un V (rost) la fiecare
    colt; 3 puncte pe colt (antiorar)."""
    pts = []
    for k in range(n):
        a = 2 * math.pi * (k + 0.5) / n
        for d, rr in ((-math.radians(2.5), r), (0.0, r - notch), (math.radians(2.5), r)):
            pts.append((rr * math.cos(a + d), rr * math.sin(a + d)))
    return pts


def build_water_tower():
    """`water_tower.png`:
    - REZERVOR: cilindru de lemn Ø 3,2 m, 3,2 m inalt (6,3 -> 9,5), 12 laturi cu
      doaga fata si un rost V la fiecare colt, 4 cercuri de otel (rugina);
    - CAPAC: con din doage (12 laturi + rosturi), 1,25 m, cu un varf mic;
    - PLATFORMA: inel de 12 laturi Ø 3,9 m, gros 0,3 m (z 6,0..6,3);
    - TURN: 4 picioare de lemn groase (0,28 m) evazate (baza +-2,1 -> varf +-1,35
      la 6 m), 2 centuri orizontale (3,0 / 5,8 m) si X in fiecare dintre cele 2
      deschideri pe fiecare dintre cele 4 fete (decupara: un X vizibil + un arc
      jos -> aici X-uri);
    - SCARA: 1 scara de lemn pe fata +Y, de la sol la platforma.
    Noduri: Tower_Timber (WOOD + LOG_DARK), Tank_Wood, Tank_Hoops (rugina).
    """
    BASE, TOPH, PZ = 2.1, 1.35, 6.0

    def leg(i, z):
        h = BASE + (TOPH - BASE) * (z / PZ)
        cx, cy = CORNERS[i]
        return Vector((cx * h, cy * h, z))

    f = Builder()
    for i in range(4):
        f.beam(leg(i, 0.0), leg(i, PZ), 0.28, TIMBER)
    for z in (3.0, 5.8):
        for i in range(4):
            f.beam(leg(i, z), leg((i + 1) % 4, z), 0.2, TIMBER)
    zs = [0.0, 3.0, 5.8]
    for z0, z1 in zip(zs, zs[1:]):
        for i in range(4):
            j = (i + 1) % 4
            f.beam(leg(i, z0), leg(j, z1), 0.14, TIMBER_OLD)
            f.beam(leg(j, z0), leg(i, z1), 0.14, TIMBER_OLD)
    ring = [(1.95 * math.cos(math.radians(15 + 30 * k)) / math.cos(math.radians(15)),
             1.95 * math.sin(math.radians(15 + 30 * k)) / math.cos(math.radians(15))) for k in range(12)]
    loft(f, ring, PZ, ring, PZ + 0.3, TIMBER_OLD)
    f.ladder((0.0, 2.55, 0.0), (0.0, 1.8, PZ + 0.1), 0.55, 0.4, 0.07, 0.05, TIMBER_OLD,
             side=(1, 0, 0))

    tk = Builder()
    st = _staves(1.6)
    loft(tk, st, PZ + 0.3, st, 9.5, TIMBER)
    lid_b = _staves(1.78, notch=0.05)
    lid_t = [(x * 0.06, y * 0.06) for x, y in lid_b]
    loft(tk, lid_b, 9.5, lid_t, 10.75, TIMBER, cap_bottom=False)
    tk.cylinder((0.0, 0.0, 10.88), 0.07, 0.25, TIMBER, segments=8)

    h = Builder()
    for hz in (6.65, 7.6, 8.55, 9.3):
        outer = [(1.64 * 1.0 * math.cos(math.radians(15 + 30 * k)) / math.cos(math.radians(15)) * 1.0,
                  1.64 * math.sin(math.radians(15 + 30 * k)) / math.cos(math.radians(15))) for k in range(12)]
        outer = [(x * 1.03, y * 1.03) for x, y in outer]
        loft(h, outer, hz - 0.06, outer, hz + 0.06, RUSTY)
    return [f.to_object("Tower_Timber"), tk.to_object("Tank_Wood"), h.to_object("Tank_Hoops")]


# ---------------------------------------------------------------------------
# 7. corral
# ---------------------------------------------------------------------------

def build_corral():
    """`corral.png`:
    - PERIMETRU: dreptunghi 10 x 8 m din stalpi de lemn 0,2 x 0,2 x 1,5 m, la
      ~2-2,5 m (decupara: ~10 stalpi pe laturile vizibile), cate 3 bare
      orizontale rotunde (Ø 0,13 m, la 0,55 / 0,95 / 1,35 m) intre stalpi;
    - POARTA: o deschidere de 2 m pe fata +Y, cu un panou de 3 bare + 2 montanti +
      diagonala (lemn vechi), 2 stalpi de poarta;
    Noduri: Corral_Wood, Corral_Gate.
    """
    w = Builder()
    sx = [-4.9, -2.45, 0.0, 2.45, 4.9]
    sy = [-3.9, -1.95, 0.0, 1.95, 3.9]
    front = [-4.9, -3.0, -1.0, 1.0, 3.0, 4.9]
    posts = set()
    for x in sx:
        posts.add((x, -3.9))
    for y in sy:
        posts.add((-4.9, y)); posts.add((4.9, y))
    for x in front:
        posts.add((x, 3.9))
    for (x, y) in sorted(posts):
        w.box((x, y, 0.75), (0.26, 0.26, 1.5), TIMBER)
    for z in (0.55, 0.95, 1.35):
        w.cylinder((0.0, -3.9, z), 0.085, 9.8, TIMBER, segments=8, axis="X")
        for x in (-4.9, 4.9):
            w.cylinder((x, 0.0, z), 0.085, 7.8, TIMBER, segments=8, axis="Y")
        w.cylinder((-2.95, 3.9, z), 0.085, 3.8, TIMBER, segments=8, axis="X")
        w.cylinder((2.95, 3.9, z), 0.085, 3.8, TIMBER, segments=8, axis="X")
    g = Builder()
    for z in (0.5, 0.95, 1.4):
        g.box((0.0, 3.9, z), (1.8, 0.09, 0.12), TIMBER_OLD)
    for x in (-0.84, 0.84):
        g.box((x, 3.9, 0.75), (0.12, 0.09, 1.5), TIMBER_OLD)
    g.beam((-0.84, 3.9, 0.5), (0.84, 3.9, 1.4), (0.1, 0.07), TIMBER_OLD, up=(0, 1, 0))
    return [w.to_object("Corral_Wood"), g.to_object("Corral_Gate")]


# ---------------------------------------------------------------------------
# 8. shade_ramada
# ---------------------------------------------------------------------------

def build_shade_ramada():
    """`shade_ramada.png`:
    - 6 STALPI de lemn (3 pe fiecare latura lunga, x = -2,3 / 0 / +2,3, y = +-1,75),
      0,18 m, 2,6 m (decupara: 4 vizibili);
    - 2 GRINZI lungi pe X (y = +-1,75, z 2,62..2,78) si 4 SPRIJINE oblice la
      colturi (decupara: console in colturi);
    - ACOPERIS: 10 CHIRPICI pe Y (lungimi 3,9-4,2 m, nu toate egale, pas 0,51 m,
      goluri de ~0,38 m intre ele) + 7 PANE pe X deasupra, subtiri, scurte/lungi
      alternand, vizibile ca barne si crengi cu goluri;
    - MASA: blat 1,8 x 0,75 m, 4 picioare in A, + 2 BANCI 1,8 x 0,25 m la
      y = +-0,7, fiecare pe 2 picioare.
    Noduri: Ramada_Frame (stalpi, grinzi, sprijine, masa, banci), Ramada_Roof.
    """
    f = Builder()
    for x in (-2.3, 0.0, 2.3):
        for y in (-1.75, 1.75):
            f.box((x, y, 1.39), (0.18, 0.18, 2.78), TIMBER)
    for y in (-1.75, 1.75):
        f.box((0.0, y, 2.7), (5.0, 0.2, 0.16), TIMBER_OLD)
    for sx in (-1, 1):
        for sy in (-1, 1):
            f.beam((sx * 2.3, sy * 1.75, 2.0), (sx * 1.6, sy * 1.75, 2.64), (0.09, 0.09), TIMBER_OLD,
                   up=(0, 1, 0))
    # masa
    f.box((0.0, 0.0, 0.75), (2.1, 0.95, 0.07), TIMBER)
    for lx in (-0.8, 0.8):
        for ly in (-1, 1):
            f.beam((lx, ly * 0.5, 0.0), (lx, ly * 0.2, 0.72), (0.09, 0.09), TIMBER_OLD, up=(1, 0, 0))
    # banci
    for by in (-0.82, 0.82):
        f.box((0.0, by, 0.46), (2.1, 0.28, 0.06), TIMBER)
        for lx in (-0.85, 0.85):
            for ly in (-1, 1):
                f.beam((lx, by + ly * 0.15, 0.0), (lx, by + ly * 0.05, 0.43), (0.06, 0.06), TIMBER_OLD,
                       up=(1, 0, 0))

    r = Builder()
    rnd = _lcg(21)
    for k in range(17):
        x = -2.35 + k * 0.29 + (rnd() - 0.5) * 0.1
        ln = 3.8 + rnd() * 0.5
        sh = (rnd() - 0.5) * 0.2
        z = 2.84 + (rnd() - 0.5) * 0.05
        r.cylinder((x, sh, z), 0.05 + rnd() * 0.02, ln, TIMBER if k % 2 == 0 else TIMBER_OLD,
                   segments=8, axis="Y")
    for k in range(10):
        y = -1.85 + k * 0.41 + (rnd() - 0.5) * 0.1
        ln = 4.4 + rnd() * 0.6
        sh = (rnd() - 0.5) * 0.35
        r.cylinder((sh, y, 2.95 + rnd() * 0.03), 0.04 + rnd() * 0.015, ln,
                   TIMBER_OLD if k % 2 == 0 else TIMBER, segments=8, axis="X")
    return [f.to_object("Ramada_Frame"), r.to_object("Ramada_Roof")]


# ---------------------------------------------------------------------------
# rulare
# ---------------------------------------------------------------------------

PIECES = [
    ("props/cattle_guard.glb", build_cattle_guard, dict(AO_OPEN, dist=0.6), 2500),
    ("props/open_range_sign.glb", build_open_range_sign, dict(AO_OPEN, dist=0.6), 1500),
    ("structures/telegraph_pole.glb", build_telegraph_pole, dict(AO_OPEN, dist=0.8), 1500),
    ("structures/wire_fence.glb", build_wire_fence, dict(AO_OPEN, dist=0.5), 1500),
    ("structures/windmill_pump.glb", build_windmill_pump, dict(AO_OPEN, dist=1.5), 4000),
    ("structures/water_tower.glb", build_water_tower, dict(AO_OPEN, dist=2.0), 4000),
    ("structures/corral.glb", build_corral, dict(AO_OPEN, dist=0.8), 5000),
    ("structures/shade_ramada.glb", build_shade_ramada, dict(AO_OPEN, dist=1.0), 4000),
]

import sys as _sys
_only = None
if "--only" in _sys.argv:
    _only = _sys.argv[_sys.argv.index("--only") + 1].split(",")

for _path, _fn, _ao, _bud in PIECES:
    if _only and os.path.basename(_path)[:-4] not in _only:
        continue
    clear_built()
    emit_road(list(_fn()), _path, _ao, budget=_bud)
report()
