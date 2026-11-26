"""Ha Long — grota marina ca PIESA INTREAGA: masivul de carst si tunelul prin el.

  halong/structures/grotto_massif.glb   masiv ~88 x 64 m, 46 m inalt, cu tunelul
                                        sapat pe axa REALA a soselei (frac
                                        0,297 -> 0,338, ~85 m)

Rulare (dupa ce axa a fost scrisa din joc):
    godot --headless --path . --script res://tools/dump_road_span.gd -- \
        --track=22 --from=0.26 --to=0.375 --out=tools/data/halong_grotto_axis.json
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_halong_grotto.py

DE CE O PIESA INTREAGA, NU O GURA
---------------------------------
`grotto_portal.glb` (gura 9 x 7 m, "spatele plat se lipeste de turn") a fost
refacut de patru ori si a esuat de fiecare data — sopron, dolmen, cutie neagra
(memoria `gaura-in-perete-cere-perete`). Cauza nu era modelarea: o GAURA cere un
PERETE in jur, iar pe Ha Long peretele nu exista si nici nu poate creste din
teren (`_lift_peaks` stinge masivele langa sosea, PEAK_ROAD_CLEAR 6 m). Deci
peretele vine din kit: masivul E piesa, gura e doar locul unde tunelul iese din
el. Decizia dezvoltatorului dupa primul drum la volan (oct 2026): „grota s-o
facem in Blender".

TUNELUL URMEAZA DRUMUL, NU O DREAPTA
------------------------------------
Axa se citeste din joc (`tools/data/halong_grotto_axis.json`), cu punctele coapte
ale soselei, latimea si latura. La frac ~0,30 drumul coteste ~17 grade; un tunel
drept ar fi intrat in carosabil pe interiorul cotei. Piesa e construita in
coordonate RELATIVE la punctul de ancora (axa la frac ANCHOR_FRAC), deci in
Track22.tscn nodul se aseaza in ancora, cu rotatie IDENTITATE.

  Blender (x, y, z) = (gx - ax, -(gz - az), gy - ay)
  glTF exporta Y-up: Godot = (bx, bz, -by)  ->  inapoi (gx - ax, gy - ay, gz - az)

GABARITUL TUNELULUI (contract, masurat in Godot de ProbeLaneClear/ProbeCameraSolid)
--------------------------------------------------------------------------------
  - carosabilul are 12 m (`custom_width_segments` 0,299-0,336 = 6 m semi-latime);
  - peretii stau la +-8,6 m de axa pana la 4 m inaltime: 2,6 m de umar pe
    fiecare parte, iar zgomotul de roca impinge DOAR in afara, niciodata spre drum;
  - bolta urca la 11 m = `ceiling` din `CameraGrota` (frac 0,297-0,338). Camera
    stie sa coboare sub un tavan de 11 m; altul ar cere alta zona;
  - stalactitele atarna doar pana la 8,5 m.

COLIZIUNE: `mesh` (WorldProp.PROP_COLLISION), ca `ice_grotto_arch` si
`railway_tunnel_portal`. Un hull convex ar fi un bloc plin peste sosea.
"""

import os
import math
import json

_here_gr = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here_gr, "okinawa_shapes.py")).read())

import bmesh
from mathutils import Vector, Matrix

exec(open(os.path.join(_here_gr, "halong_karst_shapes.py"), encoding="utf-8").read())

clear_built()

HL_ROCK = MARBLE_GREY        # 29: calcar (corpul si interiorul — AO-ul face umbra)
HL_SCRUB = TROPICAL_GREEN    # 21: vegetatia de pe creasta si perete

AXIS_PATH = os.path.join(PROJECT, "tools", "data", "halong_grotto_axis.json")
F0, F1 = 0.297, 0.338        # CameraGrota in Track22.tscn
ANCHOR_FRAC = 0.3175

TUNNEL_HALF = 8.6            # perete la +-8,6 m pana la WALL_H
WALL_H = 4.0
CEILING = 11.0               # = CameraGrota.ceiling
FLOOR = -3.0                 # taietura coboara sub carosabil: masivul nu-l acopera
# 9,5, nu 8,5: prima captura de joc arata stalactitele de 8,5 m ca un sir de
# DINTI albi la inaltimea camerei (care coboara sub tavan in CameraGrota), in
# fata masinii. Mai sus si doar pe buza gurii, se citesc ca margine de bolta.
DRIP_MIN_H = 9.5

raw = json.load(open(AXIS_PATH))["points"]
anchor = min(raw, key=lambda p: abs(p[6] - ANCHOR_FRAC))
AX, AY, AZ = anchor[0], anchor[1], anchor[2]


def to_b(gx, gy, gz):
    return Vector((gx - AX, -(gz - AZ), gy - AY))


# Axa in Blender: (pozitie, latura orizontala unitara, semi-latime, frac).
AXIS = []
for p in raw:
    side = Vector((p[4], -p[5], 0.0))
    side.normalize()
    AXIS.append((to_b(p[0], p[1], p[2]), side, p[3], p[6]))


def axis_at(f):
    """Punctul de axa cel mai apropiat de fractia `f`."""
    return min(AXIS, key=lambda a: abs(a[3] - f))


def _smooth(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


# ---------------------------------------------------------------------------
# Profilul tunelului: (lateral, vertical, normala exterioara) — perete drept,
# apoi bolta eliptica pana la CEILING.
# ---------------------------------------------------------------------------

def tunnel_profile():
    pts = [(-TUNNEL_HALF, FLOOR, (-1.0, 0.0)), (-TUNNEL_HALF, WALL_H * 0.5, (-1.0, 0.0))]
    a, b = TUNNEL_HALF, CEILING - WALL_H
    n = 12
    for i in range(n + 1):
        th = math.pi - math.pi * i / n          # stanga -> apex -> dreapta
        s, h = a * math.cos(th), WALL_H + b * math.sin(th)
        nrm = Vector((math.cos(th) * b, math.sin(th) * a))
        nrm.normalize()
        pts.append((s, h, (nrm.x, nrm.y)))
    pts.append((TUNNEL_HALF, WALL_H * 0.5, (1.0, 0.0)))
    pts.append((TUNNEL_HALF, FLOOR, (1.0, 0.0)))
    return pts


def build_cutter():
    """Tubul de taiere, inchis la capete. Se intinde 0,02 dincolo de F0/F1 ca
    sa iasa curat din masiv; spre capete profilul se EVAZEAZA (gura de pestera,
    nu teava extrudata). Zgomotul de roca e doar spre exterior."""
    prof = tunnel_profile()
    rnd = _ok_rand(4401)
    col = [rnd() * 0.7 for _ in prof]            # dungi continue pe lungime
    cut = [a for a in AXIS if F0 - 0.02 <= a[3] <= F1 + 0.02]
    b = Builder()
    rings = []
    for k, (pos, side, hw, f) in enumerate(cut):
        # evazare: 0 in interior, 1 la ~6 m inaintea gurii si dincolo de ea
        flare = max(_smooth((F0 + 0.004 - f) / 0.006),
                    _smooth((f - (F1 - 0.004)) / 0.006))
        ring = []
        for j, (s, h, nrm) in enumerate(prof):
            out = col[j] + rnd() * 0.35
            if h <= FLOOR + 0.01:
                out = 0.0                            # podeaua ramane dreapta
            sc = 1.0 + 0.45 * flare
            ss = s * sc + nrm[0] * out
            hh = (h * (1.0 + 0.25 * flare) if h > 0 else h) + nrm[1] * out
            ring.append(b.bm.verts.new(pos + side * ss + Vector((0, 0, hh))))
        rings.append(ring)
    m = len(prof)
    for k in range(len(rings) - 1):
        lo, hi = rings[k], rings[k + 1]
        for j in range(m):
            jj = (j + 1) % m
            f = b.bm.faces.new([lo[j], lo[jj], hi[jj], hi[j]])
            f[b.slot] = HL_ROCK
    for ring, rev in ((rings[0], True), (rings[-1], False)):
        f = b.bm.faces.new(list(reversed(ring)) if rev else ring)
        f[b.slot] = HL_ROCK
    return b.to_object("GrottoCutter")


# ---------------------------------------------------------------------------
# Masivul: un turn de carst ALUNGIT pe directia tunelului, asezat pe uscat.
# ---------------------------------------------------------------------------

# Profil de USCAT: fara nisa de val (masivul sta pe nisipul insulei, nu in apa),
# perete drept, umar rotunjit sub creasta. Fractiile sunt din raza de mijloc.
MASSIF_PROFILE = [
    (-0.10, 0.99),
    (0.00, 0.98),
    (0.08, 0.95),
    (0.16, 1.00),
    (0.45, 1.00),
    (0.68, 0.97),
    (0.82, 0.90),
    (0.91, 0.78),
    (0.97, 0.58),
    (1.00, 0.36),
]
MASSIF_H = 46.0


def _plan_dist_to_axis(c):
    """Distanta in plan de la `c` la cel mai apropiat punct al axei soselei."""
    best = 1e9
    for pos, _side, _hw, _f in AXIS:
        dx, dy = c.x - pos.x, c.y - pos.y
        best = min(best, dx * dx + dy * dy)
    return math.sqrt(best)


def build_massif():
    """V2 (26 nov 2026): acelasi generator ca turnurile din kit
    (halong_karst_shapes.py — lobi, caneluri, creasta zimtata, mantie de
    jungla), pe profilul de USCAT si alungit pe directia tunelului. V1 era o
    prisma de 22 de coloane, fatetata, cu doua caciuli de roca si 16 tufe-
    bolovan: langa turnurile noi si banda de orizont citea "simplu si
    colturos" (verdictul dezvoltatorului)."""
    p0, p1 = axis_at(F0)[0], axis_at(F1)[0]
    chord = (p1 - p0)
    chord.z = 0.0
    half_len = chord.length * 0.5
    yaw = math.atan2(chord.y, chord.x)
    center = (p0 + p1) * 0.5
    center.z = 0.0
    # Raza pe lungime: gurile cad pe F0/F1 la cota tunelului (profil ~0,95-1,0).
    rx = half_len * 1.02
    ry = 32.0
    xform = Matrix.Translation(center) @ Matrix.Rotation(yaw, 4, "Z")

    def skip(c, r):
        # Nimic agatat deasupra soselei, la gurile tunelului: acolo e buza
        # boltii (si stalactitele), iar camera coboara sub tavanul de 11 m.
        return c.z < 19.0 and _plan_dist_to_axis(c) < 13.0 + r

    spec = dict(seed=4402, h=MASSIF_H, r_mid=rx, ratio=ry / rx, prof=MASSIF_PROFILE,
                seg=64, rings=30, lobe=0.10, flute=0.05, ledge=0.03,
                crest=0.12, twin=0.5, crown=2.6, wall_veg=0.6,
                names=("Grotto_Rock", "Grotto_Scrub"), xform=xform, veg_skip=skip)
    rock, scrub, _top = karst_body(spec)
    print("  masiv: %d coroane" % spec["_crowns"])
    return rock, scrub, spec


def build_drips():
    """Stalactite scurte la cele doua guri, varfurile la >= DRIP_MIN_H."""
    b = Builder()
    rnd = _ok_rand(4460)
    for f in (F0 + 0.003, F1 - 0.003):
        pos, side, hw, _ = axis_at(f)
        for i in range(3):
            s = (rnd() - 0.5) * 9.0
            # sub bolta: inaltimea boltii la lateralul s
            t = max(0.0, 1.0 - (s / TUNNEL_HALF) ** 2)
            roof = WALL_H + (CEILING - WALL_H) * math.sqrt(t)
            ln = 0.8 + 0.7 * rnd()
            tip = max(DRIP_MIN_H, roof - ln)
            ln = roof - tip + 0.6
            if ln < 0.8:
                continue
            c = pos + side * s
            r = 0.35 + 0.3 * rnd()
            b.frustum((c.x, c.y, tip + ln * 0.5), 0.0, r, ln, HL_ROCK, segments=5)
    return b.to_object("Grotto_Drips")


def boolean_difference(target, cutter):
    mod = target.modifiers.new("cut", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.object = cutter
    mod.solver = "EXACT"
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(target.evaluated_get(dg))
    target.modifiers.remove(mod)
    old = target.data
    target.data = me
    bpy.data.meshes.remove(old)
    # Slotul pe fete: boolean-ul poate pierde atributul; toate fetele sunt calcar.
    if "slot" not in me.attributes:
        me.attributes.new("slot", "INT", "FACE")
    attr = me.attributes["slot"]
    for i in range(len(me.polygons)):
        attr.data[i].value = HL_ROCK


cutter = build_cutter()
rock, scrub, mspec = build_massif()
boolean_difference(rock, cutter)
bpy.data.objects.remove(cutter, do_unlink=True)
drips = build_drips()

objs = [rock, scrub, drips]
total = 0
for o in objs:
    # V2: roca NETEDA (62 de grade, ca turnurile), vegetatia si stalactitele plate.
    if o is not rock:
        _split_all_edges(o)
    # AO: raza mare, ca tunelul sa iasa intunecat din geometria lui (tavanul
    # acopera emisfera), nu dintr-un slot inchis — slotul 2 a iesit portocaliu
    # sub soarele de ora de aur (inelul de la nisa turnurilor).
    st = finish(o, bevel=0.0, ao=dict(samples=24, dist=14.0, gradient="vertical",
                                      low=0.5, high=1.0, power=0.8, floor=0.18),
                origin=None, smooth_angle=62.0 if o is rock else None)
    if o is not rock:
        _flatten_ao(o)
    if o is rock:
        # masivul sta pe uscat: fara banda uda de la linia apei
        tint_rock(o, MASSIF_H, mspec["r_mid"] * 0.6, mspec["seed"], wet_band=False)
    elif o is scrub:
        tint_veg(o, 14.0, mspec["seed"])
    total += st["tris"]
    print("  %-14s %6d tri  ao %.2f-%.2f" % (o.name, st["tris"], st["ao_min"], st["ao_max"]))

xs = [v.co.x for v in rock.data.vertices]
ys = [v.co.y for v in rock.data.vertices]
zs = [v.co.z for v in rock.data.vertices]
_, sz = export_glb(objs, "halong/structures/grotto_massif.glb")
print("=== grotto_massif.glb: %d tri, %.0f x %.0f x %.0f m, %.0f kB, ancora Godot (%.2f, %.2f, %.2f) frac %.4f ==="
      % (total, max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs), sz / 1024.0,
         AX, AY, AZ, anchor[6]))
