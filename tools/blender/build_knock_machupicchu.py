"""knock_machupicchu.glb — kitul de piese LOVIBILE de pe marginea drumului, Machu Picchu.

Terasele de piatra inca si poteca de trekking: ce lasa carausii si drumetii pe marginea
traseului, si care se imprastie cand le loveste masina.

  ClayJar      CYL  Ø0.46 x H0.60       vas inca (aryballo) cu talpa PLATA si stabila, gat
                                        evazat, banda geometrica pictata (doar sloturi);
                                        urechiusele stau in raza corpului
  WovenBasket  CYL  Ø0.50 x H0.38       cos impletit acoperit cu o manta in dungi aprinse
  Backpack     BOX  0.40 x 0.62 x 0.30  rucsac de trekking in picioare, saltea rulata sus
                                        (in interiorul cutiei)

Contractul comun al kiturilor lovibile (cerut de coordonator):
  - un GLB, cate un nod-RADACINA per piesa, toate exportate in (0,0,0), scara aplicata
  - originea la centrul bazei (min Y = 0 in glTF), centrata in plan
  - CYL primeste cilindrul DIN bounding box: vasul si cosul sunt de revolutie, nimic nu iese
    din corpul rotund (urechiusele vasului stau pe umar, mult sub raza maxima; marginea
    mantalei atarna la 2 mm de peretele cosului)
  - BOX primeste cutia din bounding box: salteaua si bretelele stau inauntru
  - culoarea doar din ATLAS (UV pe centre de slot), AO copt in vertex colors (finish/bake_ao)
  - <= 320 de triunghiuri pe piesa; rotundele cu >= 10 laturi

Sloturile: TILE_TERRACOTTA 23 (lutul, deja pe corturile pistei), CORAL_SAND 19 + LOG_DARK 28
banda geometrica; SAND_MID 1 / WOOD 9 impletitura; mantaua andina in KERB_RED 7,
SAND_LIGHT 0, TROPICAL_GREEN 21 (frunzisul pistei) si ICE_DEEP 25; rucsacul LAVA_ORANGE 30
cu garnituri LOG_DARK 28 si salteaua ICE_DEEP 25 (complementar, se citeste pe verdele pantei).

Axe (Blender): X = latimea, Y = adancimea, Z = sus. Godot: (x, z_bl, -y_bl).

Rulare (din radacina checkout-ului):
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_machupicchu.py
Verificare:
    python tools/blender/verify_glb.py assets/models/machupicchu/props/knock_machupicchu.glb 320
"""

import math
import bmesh
import bpy
from mathutils import Matrix, Vector

OUT = "machupicchu/props/knock_machupicchu.glb"
TRI_BUDGET = 320


# ============================================================ ajutoare (locale kitului)
def lathe(b, profile, segs, slot_fn, radial=None, phase=0.0, shape=None):
    """Suprafata de revolutie INCHISA, cu slot pe fiecare fata.

    profile: [(r, z)] de jos in sus. r == 0 pe primul punct = pol jos (evantai), pe
    ultimul = varf (evantai); altfel capac ngon. Profilul poate cobori (gura unui vas:
    buza, apoi peretele interior pana la un fund intunecat) — suprafata ramane inchisa.
    slot_fn(band, seg): banda k e intre profile[k] si profile[k+1]; capacul de jos cere
    banda -1, cel de sus banda len(profile) - 1.
    radial(i, k): multiplicator de raza pe varf (coaste); shape(a): (cx, cy) in loc de
    (cos, sin) — sectiuni ovale sau patratoase.
    Cost: 2 * segs pe banda de quad-uri, segs pe evantai, segs - 2 pe capac.
    """
    bm = b.bm
    rings = []
    for k, (r, z) in enumerate(profile):
        if r <= 1e-6:
            rings.append([bm.verts.new((0.0, 0.0, z))])
            continue
        ring = []
        for i in range(segs):
            a = phase + 2.0 * math.pi * i / segs
            cx, cy = shape(a) if shape else (math.cos(a), math.sin(a))
            m = radial(i, k) if radial else 1.0
            ring.append(bm.verts.new((r * m * cx, r * m * cy, z)))
        rings.append(ring)
    for k, (lo, hi) in enumerate(zip(rings, rings[1:])):
        for i in range(segs):
            j = (i + 1) % segs
            if len(lo) == 1:
                f = bm.faces.new((lo[0], hi[j], hi[i]))
            elif len(hi) == 1:
                f = bm.faces.new((lo[i], lo[j], hi[0]))
            else:
                f = bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
            f[b.slot] = slot_fn(k, i)
    if len(rings[0]) > 1:
        f = bm.faces.new(tuple(reversed(rings[0])))
        f[b.slot] = slot_fn(-1, 0)
    if len(rings[-1]) > 1:
        f = bm.faces.new(tuple(rings[-1]))
        f[b.slot] = slot_fn(len(profile) - 1, 0)


def box_mm(b, x0, x1, y0, y1, z0, z1, slot):
    return b.box(((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
                 (x1 - x0, y1 - y0, z1 - z0), slot)


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


def assemble(name, groups, ao):
    """groups = [(fn(b), bevel, bevel_angle, smooth_angle[, post(obj)])]: fiecare grup isi
    primeste bevel-ul, apoi totul se uneste, originea se aseaza O DATA pe ansamblu (baza,
    centrat) si AO-ul se coace pe tot (lantul din `finish`, desfacut pe grupuri).
    `post` ruleaza pe grup inainte de bevel (ex. orientarea normalelor unei suprafete
    deschise, pe care `recalc_face_normals` o poate intoarce)."""
    parts = []
    for k, g in enumerate(groups):
        fn, bev, ang, smooth = g[:4]
        b = Builder()
        fn(b)
        o = b.to_object("%s_part%d" % (name, k))
        if len(g) > 4 and g[4] is not None:
            g[4](o)
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
    bake_ao(obj, **ao)
    return obj


def slots_of(obj):
    uv = obj.data.uv_layers.active.data
    return sorted({int(uv[p.loop_indices[0]].uv[0] * SLOTS) for p in obj.data.polygons})


def ao_scale_verts(obj, pred, k):
    """Inmulteste AO-ul copt pe varfurile alese (santurile coastelor: ocluzie pe care
    raycast-ul n-o prinde pe un santier atat de putin adanc)."""
    ca = obj.data.color_attributes["AO"]
    for i, v in enumerate(obj.data.vertices):
        if pred(v):
            c = ca.data[i].color[0] * k
            ca.data[i].color = (c, c, c, 1.0)


def report(obj, spec):
    """Masoara in cotele GODOT (L = x, H = z_bl, A = y_bl) si compara cu cererea (±5 %)."""
    vs = obj.data.vertices
    ext = [(min(v.co[a] for v in vs), max(v.co[a] for v in vs)) for a in range(3)]
    w, d, h = (ext[0][1] - ext[0][0], ext[1][1] - ext[1][0], ext[2][1] - ext[2][0])
    tris = tri_count(obj)
    ok = tris <= TRI_BUDGET and abs(ext[2][0]) < 1e-4
    for got, want in zip((w, h, d), spec):
        ok = ok and abs(got - want) <= want * 0.05
    print("KNOCK %-11s %3d tris | %.3f x %.3f x %.3f m (cerut %.2f x %.2f x %.2f) | "
          "sloturi %s | %s" % (obj.name, tris, w, h, d, spec[0], spec[1], spec[2],
                              ",".join(map(str, slots_of(obj))), "OK" if ok else "!! ABATERE"))
    return ok


AO = dict(samples=32, dist=0.35, gradient="vertical", low=0.72, high=1.0, power=0.8,
          floor=0.35)

CLAY = TILE_TERRACOTTA      # 23
CREAM = CORAL_SAND          # 19
DARK = LOG_DARK             # 28
WEAVE_A, WEAVE_B = SAND_MID, WOOD        # 1, 9 (DRY_VEGETATION 13 iesea verzui)


# ============================================================ ClayJar (CYL Ø0.46 x 0.60)
JAR = [(0.130, 0.000), (0.155, 0.016), (0.205, 0.110), (0.230, 0.235), (0.224, 0.315),
       (0.182, 0.405), (0.105, 0.470), (0.090, 0.510), (0.128, 0.585), (0.134, 0.600),
       (0.108, 0.600), (0.082, 0.560), (0.000, 0.530)]


def clay_jar(b):
    def slot(k, i):
        # banda geometrica: doua randuri in sah pe burta si umar -> romburi / trepte
        if k == 3:
            return CREAM if i % 2 == 0 else DARK
        if k == 4:
            return DARK if i % 2 == 0 else CREAM
        if k >= 10:                          # gura
            return DARK
        return CLAY
    lathe(b, JAR, 12, slot)
    # urechiusele de pe umar (nodul de prindere al aryballo-ului), in raza corpului
    for sx in (-1, 1):
        b.box((sx * 0.158, 0.0, 0.432), (0.050, 0.060, 0.036), CLAY)


# ============================================================ WovenBasket (CYL Ø0.50 x 0.38)
WB_R = 0.248
WB_TOP = 0.300
CLOTH_R = 0.250
CLOTH_N = 6
STRIPES = (KERB_RED, SAND_LIGHT, KERB_RED, TROPICAL_GREEN, KERB_RED, ICE_DEEP)


def basket_body(b):
    prof = [(0.205, 0.000), (0.228, 0.018), (0.240, 0.090), (WB_R, 0.170),
            (WB_R, 0.245), (0.236, WB_TOP)]
    # impletitura: sah pe benzi (fasiile late de rachita), peste tot corpul
    lathe(b, prof, 16, lambda k, i: WEAVE_A if (i + max(k, 0)) % 2 == 0 else WEAVE_B)


def basket_cloth(b):
    """Mantaua: grila 6 x 6 pe patrat, dusa pe disc (maparea eliptica), boltita peste
    continut, cu marginea lasata pe peretele cosului. Dungile merg pe COLOANELE grilei,
    deci raman paralele (pe un strung ar iesi cercuri concentrice: tinta, nu manta)."""
    bm = b.bm
    n = CLOTH_N
    grid = {}
    for r in range(n + 1):
        for c in range(n + 1):
            u, v = -1.0 + 2.0 * c / n, -1.0 + 2.0 * r / n
            x = u * math.sqrt(1.0 - v * v / 2.0)
            y = v * math.sqrt(1.0 - u * u / 2.0)
            rho = min(math.hypot(x, y), 1.0)
            # bolta cu doua umflaturi (continutul de sub manta), determinist
            lump = 0.012 * math.cos(3.0 * x + 1.0) * math.cos(2.5 * y)
            z = WB_TOP + 0.076 * (1.0 - rho * rho) ** 0.65 + lump * (1.0 - rho)
            grid[r, c] = bm.verts.new((x * CLOTH_R, y * CLOTH_R, z))
    for r in range(n):
        for c in range(n):
            f = bm.faces.new((grid[r, c], grid[r, c + 1], grid[r + 1, c + 1], grid[r + 1, c]))
            f[b.slot] = STRIPES[c]
    # marginea: conturul grilei (pe cerc), lasat in jos pe peretele cosului
    loop = ([(0, c) for c in range(n)] + [(r, n) for r in range(n)]
            + [(n, c) for c in range(n, 0, -1)] + [(r, 0) for r in range(n, 0, -1)])
    low = {}
    for key in loop:
        v = grid[key]
        low[key] = bm.verts.new((v.co.x * 1.008, v.co.y * 1.008, WB_TOP - 0.075))
    for a, bb in zip(loop, loop[1:] + loop[:1]):
        f = bm.faces.new((grid[a], low[a], low[bb], grid[bb]))
        c = min(a[1], bb[1]) if a[0] == bb[0] else a[1]
        f[b.slot] = STRIPES[min(c, n - 1)]


def cloth_outward(obj):
    """Suprafata e DESCHISA: `recalc_face_normals` din Builder nu are interior dupa care sa
    se orienteze. Normalele trebuie sa iasa in afara (sus pe bolta, spre exterior pe
    margine), altfel Godot taie fata vazuta (backface culling)."""
    me = obj.data
    me.update()
    up = sum(p.normal.z * p.area for p in me.polygons if p.center.z > WB_TOP + 0.02)
    if up < 0.0:
        for p in me.polygons:
            p.flip()
        me.update()


# ============================================================ Backpack (BOX 0.40 x 0.62 x 0.30)
BP_W, BP_H, BP_D = 0.40, 0.62, 0.30
MAT_R = 0.050
PACK = LAVA_ORANGE           # 30
MAT = ICE_DEEP               # 25


def pack_shell(b):
    box_mm(b, -0.180, 0.180, -0.120, 0.120, 0.000, 0.480, PACK)          # sacul
    box_mm(b, -0.186, 0.186, -0.126, 0.126, 0.000, 0.070, DARK)          # fundul intarit
    box_mm(b, -0.188, 0.188, -0.124, 0.138, 0.440, 0.520, DARK)          # capacul


def pack_straps(b):
    box_mm(b, -0.125, 0.125, 0.118, 0.150, 0.110, 0.330, DARK)           # buzunarul din fata
    box_mm(b, -0.110, 0.110, 0.146, 0.150, 0.250, 0.290, PACK)           # fermoarul buzunarului
    for sx in (-1, 1):                                                   # bretelele (spate)
        xs = sorted((sx * 0.065, sx * 0.120))
        box_mm(b, xs[0], xs[1], -0.150, -0.118, 0.100, 0.470, DARK)


def pack_mat(b):
    zc = BP_H - MAT_R
    b.cylinder((0.0, 0.0, zc), MAT_R, BP_W, MAT, segments=10, axis="X")
    for x in (-0.115, 0.115):                                            # chingile saltelei
        b.cylinder((x, 0.0, zc), MAT_R + 0.006, 0.032, DARK, segments=10, axis="X")


# ============================================================ build + export
def build():
    clear_built()
    objs = []
    ok = True

    jar = assemble("ClayJar", [(clay_jar, 0.0, 40.0, 50.0)], AO)
    ok &= report(jar, (0.46, 0.60, 0.46))
    objs.append(jar)

    bk = assemble("WovenBasket", [(basket_body, 0.0, 40.0, 50.0),
                                  (basket_cloth, 0.0, 40.0, 70.0, cloth_outward)], AO)
    ok &= report(bk, (0.50, 0.38, 0.50))
    objs.append(bk)

    bp = assemble("Backpack", [(pack_shell, 0.022, 40.0, 40.0),
                               (pack_straps, 0.0, 40.0, 40.0),
                               (pack_mat, 0.0, 40.0, 50.0)], AO)
    ok &= report(bp, (BP_W, BP_H, BP_D))
    objs.append(bp)

    for o in objs:
        o.location = (0.0, 0.0, 0.0)
    print("GLB:", export_glb(objs, OUT))
    print("KNOCK VERDICT:", "OK" if ok else "ABATERI — vezi mai sus")


build()
