"""knock_baikal.glb — kitul de recuzita LOVIBILA din tabara de pescari de pe Baikal.

Trei piese mici care stau langa drumul de gheata si zboara cand le loveste o masina:

  IceBlock   BOX  0.60 x 0.48 x 0.50  bloc de gheata taiat din lac, fata de sus mai deschisa
  FishCrate  BOX  0.60 x 0.30 x 0.40  lada de lemn cu pesti argintii inghetati deasupra
  FuelDrum   CYL  Ø0.58 x 0.88        butoi de combustibil vopsit, doua cercuri, caciula de zapada

Contractul (din kitul de recuzita lovibila, valul 3):
  - fiecare piesa = un nod RADACINA cu numele de mai sus, toate exportate la (0,0,0)
  - originea la centrul bazei, scara aplicata, culoarea DOAR din atlas (UV pe
    centrul slotului) + AO copt in vertex colors
  - CYL primeste un colizor cilindric calculat din AABB, pe axa verticala;
    BOX un colizor-cutie, deci AABB strans (pestii stau in amprenta lazii)
  - max 320 de triunghiuri pe piesa

Sloturile vin din paleta Baikal deja folosita de lume (census pe
assets/models/baikal): ICE_TURQUOISE 24 / ICE_DEEP 25 / FOAM_WHITE 22 (gheata si
zapada), WOOD 9 + LOG_DARK 28 (lada), PAINTED 11 + MARBLE_GREY 29 (pestii),
KERB_RED 7 + VOLCANIC_BLACK 20 (butoiul: rosu pe alb e accentul care se vede de
la 30 m pe lac, iar ice_road_marker foloseste deja 7).

Zapada de pe capacul butoiului are cel mult 4 cm peste capac (cerinta kitului).

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_baikal.py
"""

import math
import bpy
from mathutils import Matrix, Vector

KEY = "baikal"
GLB_PATH = "baikal/props/knock_baikal.glb"
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

ICE = ICE_TURQUOISE     # 24
ICE_LOW = ICE_DEEP      # 25 stratul de jos al blocului, gheata groasa
FROST = FOAM_WHITE      # 22 fata de sus (zapada / chiciura) si caciula de pe butoi
WOOD_C = WOOD           # 9
DARK_W = LOG_DARK       # 28 rostul dintre scanduri, interiorul lazii
FISH_BACK = PAINTED     # 11 spinarea pestelui, albastru-gri
FISH_BELLY = MARBLE_GREY  # 29 burta argintie
DRUM = KERB_RED         # 7
DRUM_DARK = VOLCANIC_BLACK  # 20 cercurile si buzele butoiului


def chamfer_rect(hx, hy, c):
    """Dreptunghi cu colturile tesite, 8 puncte in sens trigonometric."""
    return [(hx, -hy + c), (hx, hy - c), (hx - c, hy), (-hx + c, hy),
            (-hx, hy - c), (-hx, -hy + c), (-hx + c, -hy), (hx - c, -hy)]


def ice_block(b):
    # Bloc taiat cu ferastraul: sectiuni tesite, putin neregulate (varfurile
    # se misca determinist), stratul de jos mai adanc la culoare si fata de sus
    # alba de chiciura. Tesitura e desenata in sectiuni, nu bevel.
    hx, hy = 0.300, 0.250
    secs = [
        (chamfer_rect(hx - 0.025, hy - 0.025, 0.05), 0.000, ICE_LOW),
        (chamfer_rect(hx, hy, 0.06), 0.028, ICE_LOW),
        (chamfer_rect(hx, hy, 0.06), 0.085, ICE),
        (chamfer_rect(hx, hy, 0.06), 0.440, ICE),
        (chamfer_rect(hx - 0.028, hy - 0.028, 0.05), 0.480, ICE),
    ]
    faces = loft(b, secs, bottom=ICE_LOW, top=FROST)
    rnd = _lcg(31)
    seen = set()
    for f in faces:
        for v in f.verts:
            if v in seen:
                continue
            seen.add(v)
            v.co.x += (rnd() - 0.5) * 0.020
            v.co.y += (rnd() - 0.5) * 0.020
            if v.co.z > 0.01:                 # talpa ramane plata
                v.co.z += (rnd() - 0.5) * 0.012
    # Muchiile verticale tesite prind lumina ca sticla: chiciura (22) pe ele,
    # ca blocul sa citeasca gheata taiata, nu cutie vopsita. Zero triunghiuri.
    b.retag(faces, FROST, where=lambda c, n: abs(n.z) < 0.5 and abs(n.x) > 0.35
            and abs(n.y) > 0.35 and c.z > 0.03)


def crate(b):
    # Lada deschisa: pereti din doua scanduri (rost inchis la mijloc), buza de
    # sus, interior intunecat in care stau pestii. Un singur corp continuu.
    hx, hy = 0.300, 0.200
    secs = [
        (chamfer_rect(hx - 0.012, hy - 0.012, 0.02), 0.000, WOOD_C),
        (chamfer_rect(hx, hy, 0.02), 0.014, WOOD_C),
        (chamfer_rect(hx, hy, 0.02), 0.100, DARK_W),
        (chamfer_rect(hx - 0.006, hy - 0.006, 0.02), 0.112, WOOD_C),
        (chamfer_rect(hx, hy, 0.02), 0.124, WOOD_C),
        (chamfer_rect(hx, hy, 0.02), 0.220, WOOD_C),
        (chamfer_rect(hx - 0.030, hy - 0.030, 0.02), 0.220, DARK_W),
        (chamfer_rect(hx - 0.030, hy - 0.030, 0.02), 0.175, DARK_W),
    ]
    loft(b, secs, bottom=WOOD_C, top=DARK_W)


def fish(b, x, z, tilt_deg, head_sign, length=0.36):
    """Peste culcat pe o parte: sectiuni romboidale pe lungime (Y), coada lata
    si plata la un capat, bot ascutit la celalalt. Spinarea (+X) albastru-gri,
    burta (-X) argintie: doua culori din `loft` cu slot alternant, zero tris."""
    L = length * 0.5
    #        y           latime  grosime
    st = [(-L,          0.058, 0.007),
          (-L + 0.055,  0.014, 0.012),
          (-L + 0.080,  0.020, 0.018),
          (0.010,       0.058, 0.032),
          (L,           0.0,   0.0)]
    secs = []
    for y, w, h in st:
        pts = [(0.0, 0.0)] if w <= 0 else [(w, 0.0), (0.0, h), (-w, 0.0), (0.0, -h)]
        secs.append((pts, y, (FISH_BACK, FISH_BELLY, FISH_BELLY, FISH_BACK)))
    first = len(b.bm.verts)
    loft(b, secs, bottom=FISH_BACK)
    b.bm.verts.ensure_lookup_table()
    rot = Matrix.Rotation(math.radians(tilt_deg), 3, "Y")
    for v in b.bm.verts[first:]:
        # loft-ul pune (latime, grosime, lungime) in (x, y, z): le duc in
        # (x = latime, y = lungime, z = grosime), apoi inclin si asez.
        w_, h_, l_ = v.co.x, v.co.y, v.co.z
        p = rot @ Vector((w_, l_ * head_sign, h_))
        v.co = Vector((x + p.x, p.y, z + p.z))


def crate_fish(b):
    # Cinci pesti de-a curmezisul gurii lazii, alternand capul, usor ingramaditi
    # spre mijloc. Totul ramane in amprenta lazii (0.60 x 0.40).
    for x, z, tilt, hs in ((-0.222, 0.226, 16.0, 1), (-0.112, 0.246, -10.0, -1),
                           (0.000, 0.266, 6.0, 1), (0.112, 0.248, -12.0, -1),
                           (0.222, 0.228, -14.0, 1)):
        fish(b, x, z, tilt, hs)


def drum(b):
    # Butoi de 200 l: buze rasfrante sus si jos, doua cercuri de rulare, capac
    # adancit sub buza si umplut de o caciula de zapada (max 4 cm peste capac,
    # capacul nominal e la 0.842). Raza maxima 0.290 = Ø0.58, aceeasi la buze si
    # la cercuri, deci colizorul cilindric e exact corpul.
    prof = [
        (0.274, 0.000, DRUM_DARK),
        (0.290, 0.022, DRUM),
        (0.282, 0.044, DRUM),
        (0.284, 0.272, DRUM_DARK),
        (0.288, 0.300, DRUM),
        (0.284, 0.570, DRUM_DARK),
        (0.288, 0.598, DRUM),
        (0.282, 0.808, DRUM_DARK),
        (0.290, 0.826, DRUM_DARK),
        (0.290, 0.846, DRUM_DARK),
        (0.268, 0.852, FROST),
        (0.232, 0.872, FROST),
        (0.110, 0.880, FROST),
    ]
    lathe(b, prof, 12, bottom=DRUM_DARK, top=FROST)


# ============================================================ build
clear_built("IceBlock")
clear_built("FishCrate")
clear_built("FuelDrum")

SPECS = [
    ("IceBlock", "BOX", (0.60, 0.48, 0.50),
     [(ice_block, 0.0, 30.0, 20.0)]),
    ("FishCrate", "BOX", (0.60, 0.30, 0.40),
     [(crate, 0.0, 30.0, 30.0), (crate_fish, 0.0, 30.0, 50.0)]),
    ("FuelDrum", "CYL", (0.58, 0.88, 0.58),
     [(drum, 0.0, 30.0, 40.0)]),
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
