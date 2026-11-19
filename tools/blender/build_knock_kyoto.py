"""knock_kyoto.glb — kitul de recuzita LOVIBILA din orasul-templu Kyoto, toamna.

Trei piese mici care stau langa drum si zboara cand le loveste o masina:

  SakeBarrel  CYL     Ø0.56 x 0.56  butoi de sake infasurat in paie (komodaru), franghii,
                                    disc rosu simplu pe fata (fara scris, fara caractere)
  WoodBucket  CYL     Ø0.36 x 0.30  galeata de lemn din doage, doua cercuri, fara toarta
  Daruma      SPHERE  Ø0.40 x 0.44  papusa rosie rotunda, talpa turtita, fata palida cu
                                    doi ochi inchisi (fara scris)

Contractul (din kitul de recuzita lovibila, valul 3):
  - fiecare piesa = un nod RADACINA cu numele de mai sus, toate exportate la (0,0,0)
  - originea la centrul bazei, scara aplicata, culoarea DOAR din atlas (UV pe
    centrul slotului) + AO copt in vertex colors
  - CYL / SPHERE primesc un colizor calculat din AABB pe axa verticala, deci
    nimic nu iese din corpul rotund: discul rosu, fata si ochii papusii stau
    lipiti pe corp, sub raza lui maxima
  - max 320 de triunghiuri pe piesa

Fata e spre +Y in Blender = -Z in Godot (nota de axe din dio_lib).

Sloturile vin din ce foloseste deja lumea Kyoto (census pe assets/models/kyoto):
SAND_LIGHT 0 (paiele aurii si lemnul taiat de pe buza), SAND_SHADOW 2 (franghia), WOOD 9 (capac, doage),
LARCH_RUST 27 (doagele alternante), LOG_DARK 28 (cercuri, fundul galetii),
KERB_RED 7 (discul, papusa),
FOAM_WHITE 22 (fata), ICE_CRACK 26 (ochii — cel mai inchis slot, ca la
paper_lantern).

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_kyoto.py
"""

import math
import bpy
from mathutils import Matrix, Vector

KEY = "kyoto"
GLB_PATH = "kyoto/props/knock_kyoto.glb"
MAX_TRIS = 320

# ============================================================ ajutoare (locale)
# Fiecare build_knock_*.py e de sine statator (contractul permite doar fisierul
# propriu), deci ajutoarele de mai jos se repeta identic in cele cinci kituri.


def circle(r, n, sx=1.0, sy=1.0, phase=0.0):
    """Puncte (x, y) pe un cerc (sau elipsa) cu n laturi."""
    return [(r * sx * math.cos(phase + 2.0 * math.pi * i / n),
             r * sy * math.sin(phase + 2.0 * math.pi * i / n)) for i in range(n)]


def loft(b, sections, bottom=None, top=None):
    """Suprafata prin sectiuni orizontale succesive, cu slot PE BANDA.

    sections: [(pts2d, z, slot_banda_de_deasupra)], toate cu acelasi numar de
    puncte; o sectiune cu UN punct e varf (evantai). Slotul benzii poate fi un
    tuplu: alterneaza pe segmente (doage de butoi, fara niciun triunghi in plus).
    bottom / top: slotul capacului de jos / sus (ngon), sau None = deschis.
    Fetele se eticheteaza direct, nu prin `_tag` (care ar recoloara si vecinii).
    """
    rings = []
    for pts, z, _slot in sections:
        rings.append([b.bm.verts.new((x, y, z)) for x, y in pts])
    out = []

    def put(f, slot):
        f[b.slot] = slot
        out.append(f)

    for k in range(len(rings) - 1):
        lo, hi = rings[k], rings[k + 1]
        slot = sections[k][2]
        n = max(len(lo), len(hi))
        for i in range(n):
            j = (i + 1) % n
            s = slot[i % len(slot)] if isinstance(slot, tuple) else slot
            if len(hi) == 1:
                put(b.bm.faces.new((lo[i], lo[j], hi[0])), s)
            elif len(lo) == 1:
                put(b.bm.faces.new((lo[0], hi[j], hi[i])), s)
            else:
                put(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])), s)
    if bottom is not None and len(rings[0]) > 2:
        put(b.bm.faces.new(tuple(reversed(rings[0]))), bottom)
    if top is not None and len(rings[-1]) > 2:
        put(b.bm.faces.new(tuple(rings[-1])), top)
    return out


def lathe(b, profile, n, bottom=None, top=None, sx=1.0, sy=1.0, phase=0.0):
    """Corp de revolutie din profil [(r, z, slot_banda_de_deasupra)].
    r == 0 la un capat = varf."""
    secs = []
    for r, z, slot in profile:
        pts = [(0.0, 0.0)] if r <= 1e-6 else circle(r, n, sx, sy, phase)
        secs.append((pts, z, slot))
    return loft(b, secs, bottom, top)


def _join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    return obj


AO = dict(samples=32, dist=0.35, gradient="vertical", low=0.66, high=1.0,
          power=0.8, floor=0.35)


def assemble(name, groups, ao=None):
    """groups = [(fn(b), bevel, bevel_angle, smooth_angle)]. Fiecare grup isi ia
    bevel-ul lui (snapshot -> bevel -> smooth -> UV pe sloturi), apoi totul se
    uneste, originea se aseaza O DATA pe ansamblu si AO-ul se coace pe tot."""
    parts = []
    for k, (fn, bev, ang, smooth) in enumerate(groups):
        b = Builder()
        fn(b)
        if not b.bm.faces:
            b.bm.free()
            continue
        o = b.to_object("%s_part%d" % (name, k))
        snap = snapshot_slots(o)
        apply_bevel(o, bev, segments=1, angle_deg=ang)
        apply_smooth(o, smooth)
        assign_uvs(o, snap)
        parts.append(o)
    obj = _join(parts, name)
    if "slot" in obj.data.attributes:
        obj.data.attributes.remove(obj.data.attributes["slot"])
    set_origin_base(obj, center_xy=True)
    obj.data.materials.clear()
    obj.data.materials.append(atlas_material())
    bake_ao(obj, **(ao or AO))
    return obj


def used_slots(obj):
    uv = obj.data.uv_layers.active
    return sorted({int(round(uv.data[p.loop_indices[0]].uv[0] * 32 - 0.5))
                   for p in obj.data.polygons})


def check(obj, kind, spec):
    """Masoara AABB-ul in cotele GODOT (W = x, H = z_bl, D = y_bl) si il compara
    cu specificatia (+-5 %). Pentru CYL verifica si ca nimic nu iese din cercul
    colizorului (raza = max(W, D) / 2, pe axa prin origine)."""
    me = obj.data
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    w, d, h = max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)
    problems = []
    for label, got, want in (("W", w, spec[0]), ("H", h, spec[1]), ("D", d, spec[2])):
        if abs(got - want) > want * 0.05:
            problems.append("%s %.3f vs %.3f" % (label, got, want))
    if abs(min(zs)) > 1e-4:
        problems.append("baza la z=%.4f" % min(zs))
    if kind in ("CYL", "SPHERE"):
        r_col = max(w, d) * 0.5
        r_max = max(math.hypot(v.co.x, v.co.y) for v in me.vertices)
        if r_max > r_col + 0.03:
            problems.append("iese din colizor: r %.3f > %.3f" % (r_max, r_col))
    if kind == "SPHERE":
        if max(w, h, d) > min(w, h, d) * 1.12 and abs(h - spec[1]) > spec[1] * 0.05:
            problems.append("sfera neuniforma")
    tris = tri_count(obj)
    if tris > MAX_TRIS:
        problems.append("%d tris > %d" % (tris, MAX_TRIS))
    print("KNOCK %-13s %-6s %.3f x %.3f x %.3f m | %3d tris | sloturi %s | %s"
          % (obj.name, kind, w, h, d, tris, ",".join(str(s) for s in used_slots(obj)),
             "OK" if not problems else "PROBLEME: " + "; ".join(problems)))
    return not problems


# ============================================================ piesele

STRAW = SAND_LIGHT      # 0  paie aurii (19 iesea alb, citea a cutie de vopsea)
ROPE = SAND_SHADOW      # 2  franghie de paie rasucita, mai inchisa
LID_W = WOOD            # 9  capacul de lemn al butoiului
DISC = KERB_RED         # 7
STAVE_A, STAVE_B = WOOD, LARCH_RUST   # 9 / 27 doage alternante
HOOP = LOG_DARK         # 28
END_GRAIN = SAND_LIGHT  # 0  buza taiata a doagelor
INSIDE = SAND_SHADOW    # 2  peretele interior, in umbra
RED = KERB_RED          # 7
FACE = FOAM_WHITE       # 22
EYE = ICE_CRACK         # 26

SEG = 12
# Faza care pune o FATA (nu o muchie) a poligonului cu 12 laturi exact pe +Y:
# varfurile la 75° si 105° -> faza 15°. Discul si fata se lipesc de ea plat.
FRONT_PHASE = math.radians(15.0)
# Cu faza asta AABB-ul poligonului e 2*r*cos(15°) pe ambele axe, adica 3.4% sub
# diametrul nominal. Razele din profil se scot cu factorul asta, ca AABB-ul
# (din care se calculeaza colizorul) sa iasa pe cota din brief.
K = 1.0 / math.cos(math.radians(15.0))


def sake_barrel(b):
    # Komodaru: corp de paie, rulouri de franghie jos si sus, o franghie in
    # jurul taliei, capac de lemn adancit sub rulou. Raza maxima 0.280 (rulourile).
    prof = [
        (0.258, 0.000, ROPE),
        (0.280, 0.026, ROPE),
        (0.280, 0.062, STRAW),
        (0.273, 0.080, STRAW),
        (0.274, 0.150, ROPE),
        (0.274, 0.182, STRAW),
        (0.273, 0.478, ROPE),
        (0.280, 0.496, ROPE),
        (0.280, 0.530, ROPE),
        (0.246, 0.560, ROPE),
        (0.226, 0.548, LID_W),
    ]
    lathe(b, prof, SEG, bottom=ROPE, top=LID_W, phase=FRONT_PHASE, sx=K, sy=K)
    # Discul rosu, plat pe fata dinspre +Y, intre franghia taliei si ruloul de
    # sus. Fata poligonului e la r*cos(15°); discul iese 7 mm peste ea, deci
    # ramane in cercul colizorului (0.280).
    y_face = 0.2735 * K * math.cos(math.radians(15.0))
    b.cylinder((0.0, y_face + 0.001, 0.330), 0.082, 0.014, DISC, segments=12, axis="Y")


def bucket(b):
    # Oke: doage (slot alternant 9/27 = doage fara niciun triunghi in plus),
    # doua cercuri inchise, buza de lemn taiat, interior in umbra si fund inchis.
    staves = (STAVE_A, STAVE_B)
    prof = [
        (0.160, 0.000, staves),
        (0.170, 0.014, HOOP),
        (0.172, 0.040, staves),
        (0.174, 0.070, staves),
        (0.177, 0.200, HOOP),
        (0.179, 0.232, staves),
        (0.180, 0.300, END_GRAIN),
        (0.158, 0.300, INSIDE),
        (0.152, 0.045, INSIDE),
    ]
    lathe(b, prof, SEG, bottom=staves[0], top=HOOP)


def ellipse_plate(b, cx, cz, rx, rz, y_back, y_front, slot, n):
    """Placa eliptica in planul XZ, intre y_back si y_front (fata spre +Y)."""
    back, front = [], []
    for i in range(n):
        a = 2.0 * math.pi * i / n
        x, z = cx + rx * math.cos(a), cz + rz * math.sin(a)
        back.append(b.bm.verts.new((x, y_back, z)))
        front.append(b.bm.verts.new((x, y_front, z)))
    faces = [b.bm.faces.new(tuple(front)), b.bm.faces.new(tuple(reversed(back)))]
    for i in range(n):
        j = (i + 1) % n
        faces.append(b.bm.faces.new((back[i], back[j], front[j], front[i])))
    for f in faces:
        f[b.slot] = slot
    return faces


Y_FACE = 0.168     # planul fetei papusii (corpul e turtit pana aici)


def daruma(b):
    # Corp de ou, talpa plata (r 0.11), cel mai lat la 0.18. Raza maxima 0.200.
    prof = [
        (0.110, 0.000, RED),
        (0.166, 0.034, RED),
        (0.196, 0.105, RED),
        (0.200, 0.180, RED),
        (0.191, 0.258, RED),
        (0.165, 0.332, RED),
        (0.118, 0.395, RED),
        (0.058, 0.430, RED),
        (0.000, 0.440, RED),
    ]
    faces = lathe(b, prof, SEG, bottom=RED, phase=FRONT_PHASE, sx=K, sy=K)
    # Fata daruma-ului e o zona turtita: varfurile din fata, intre 0.17 si 0.36,
    # se trag inapoi pe planul Y_FACE. Silueta nu se schimba (e in interiorul
    # cercului), iar placa fetei se aseaza plat, fara fanta pe margini.
    for v in {v for f in faces for v in f.verts}:
        if v.co.y > Y_FACE and 0.15 < v.co.z < 0.37:
            v.co.y = Y_FACE


def daruma_face(b):
    ellipse_plate(b, 0.0, 0.268, 0.104, 0.080, Y_FACE - 0.012, Y_FACE + 0.006, FACE, 12)
    for x in (-0.046, 0.046):
        b.cylinder((x, Y_FACE + 0.008, 0.282), 0.024, 0.012, EYE, segments=8, axis="Y")


# ============================================================ build
clear_built("SakeBarrel")
clear_built("WoodBucket")
clear_built("Daruma")

SPECS = [
    ("SakeBarrel", "CYL", (0.56, 0.56, 0.56),
     [(sake_barrel, 0.0, 30.0, 40.0)]),
    ("WoodBucket", "CYL", (0.36, 0.30, 0.36),
     [(bucket, 0.0, 30.0, 40.0)]),
    ("Daruma", "SPHERE", (0.40, 0.44, 0.40),
     [(daruma, 0.0, 30.0, 50.0), (daruma_face, 0.0, 30.0, None)]),
]

objs, ok = [], True
for name, kind, spec, groups in SPECS:
    o = assemble(name, groups)
    ok = check(o, kind, spec) and ok
    objs.append(o)

for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(objs, GLB_PATH))
print("KNOCK VERDICT %s: %s" % (KEY, "OK" if ok else "PROBLEME"))
