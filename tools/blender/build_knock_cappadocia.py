"""knock_cappadocia.glb — kitul de piese LOVIBILE de pe marginea drumului, Cappadocia.

Orasul olarilor dintre cosurile zanelor (Avanos): piese mici, singure, care se imprastie cand
le loveste masina. `pot_stack.glb` e teancul mare, static; aici sunt bucatile care zboara.

  ClayPot     CYL     Ø0.44 x H0.54   oala de lut cu gat si o banda pictata (doar slot)
  Pumpkin     SPHERE  Ø0.50 x H0.38   dovleac cu coaste (singura sfera mai lata decat inalta)
  AppleCrate  BOX     0.60 x 0.34 x 0.40 (L x H x A)   lada cu sipci, plina cu mere

Contractul comun al kiturilor lovibile (cerut de coordonator):
  - un GLB, cate un nod-RADACINA per piesa, toate exportate in (0,0,0), scara aplicata
  - originea la centrul bazei (min Y = 0 in glTF), centrata in plan
  - CYL / SPHERE primesc colizor cilindric / sferic DIN bounding box: piesele sunt de
    revolutie (strung), nimic nu iese din corpul rotund
  - BOX primeste cutia din bounding box: nimic subtire nu iese din ea
  - culoarea doar din ATLAS (UV pe centre de slot), AO copt in vertex colors (finish/bake_ao)
  - <= 320 de triunghiuri pe piesa; rotundele cu >= 10 laturi (sferele >= 10 x 6)

Sloturile sunt alese din ce foloseste deja lumea Cappadociei (cave houses, pot_stack,
pottery_cart): TILE_TERRACOTTA 23, CORAL_SAND 19 (tuful crem), WOOD 9, LOG_DARK 28, plus
LAVA_ORANGE 30 (deja accentul torcelor si al cosului de balon) pentru dovleac.

Axe (Blender): X = latimea, Y = adancimea, Z = sus. Godot: (x, z_bl, -y_bl).

Rulare (din radacina checkout-ului):
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_cappadocia.py
Verificare:
    python tools/blender/verify_glb.py assets/models/cappadocia/props/knock_cappadocia.glb 320
"""

import math
import bmesh
import bpy
from mathutils import Matrix, Vector

OUT = "cappadocia/props/knock_cappadocia.glb"
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
INSIDE = LOG_DARK           # 28


# ============================================================ ClayPot (CYL Ø0.44 x 0.54)
POT = [(0.135, 0.000), (0.158, 0.014), (0.200, 0.090), (0.220, 0.200), (0.218, 0.290),
       (0.190, 0.370), (0.130, 0.430), (0.112, 0.470), (0.140, 0.520), (0.145, 0.540),
       (0.118, 0.540), (0.098, 0.500), (0.000, 0.470)]


def clay_pot(b):
    def slot(k, i):
        if k == 4:                       # banda pictata pe umar
            return CREAM
        if k >= 10:                      # gura: peretele interior + fundul
            return INSIDE
        return CLAY
    lathe(b, POT, 12, slot)


# ============================================================ Pumpkin (SPHERE Ø0.50 x 0.38)
PK_SEGS = 20                 # 10 coaste: varf pe coasta, varf in sant
PK_PHASE = 9.0               # coastele la 9 + 36k grade: bbox egal pe X si pe Y
PK_LATS = [-90.0 + 180.0 * (k + 1) / 7.0 for k in range(6)]   # 6 inele
# raza aleasa ca diametrul MASURAT (cel mai lat inel, pe coasta) sa iasa 0,50
PK_R = 0.25 / (math.cos(math.radians(PK_LATS[3])) ** 0.75 * math.cos(math.radians(PK_PHASE)))
PK_STEM_ABOVE = 0.035        # cat iese codita peste ultimul inel (cerut: <= 4 cm)
PK_C = (0.38 - PK_STEM_ABOVE) / (2.0 * math.sin(math.radians(PK_LATS[-1])))
PK_GROOVE = 0.90


def _pk_profile():
    prof = [(0.0, PK_C - PK_C * math.sin(math.radians(PK_LATS[-1])) + 0.035)]
    for lat in PK_LATS:
        la = math.radians(lat)
        prof.append((PK_R * math.cos(la) ** 0.75, PK_C + PK_C * math.sin(la)))
    # polul de sus coboara in gropita din care iese codita
    prof.append((0.0, PK_C + PK_C * math.sin(math.radians(PK_LATS[-1])) - 0.030))
    return prof


def pumpkin_body(b):
    lathe(b, _pk_profile(), PK_SEGS, lambda k, i: LAVA_ORANGE,
          radial=lambda i, k: 1.0 if i % 2 == 0 else PK_GROOVE,
          phase=math.radians(PK_PHASE))


def pumpkin_stem(b):
    top_ring = PK_C + PK_C * math.sin(math.radians(PK_LATS[-1]))
    z0 = top_ring - 0.035
    z1 = top_ring + PK_STEM_ABOVE
    b.frustum((0.0, 0.0, (z0 + z1) * 0.5), 0.036, 0.024, z1 - z0, CACTUS_GREEN, segments=6)


# ============================================================ AppleCrate (BOX 0.60 x 0.34 x 0.40)
CR_W, CR_D, CR_H = 0.60, 0.40, 0.34
APPLE_R = 0.066


def crate_wood(b):
    # doua sipci late pe tot conturul; intre ele se vede miezul intunecat = rostul
    for z0, z1 in ((0.000, 0.108), (0.128, 0.236)):
        box_mm(b, -CR_W / 2, CR_W / 2, -CR_D / 2, CR_D / 2, z0, z1, WOOD)


def crate_core(b):
    box_mm(b, -CR_W / 2 + 0.025, CR_W / 2 - 0.025, -CR_D / 2 + 0.025, CR_D / 2 - 0.025,
           0.004, 0.226, INSIDE)


def crate_apples(b):
    # movila de dedesubt: umple golurile dintre mere, in rosul merelor, cu inelul din
    # mijloc boltit pe sarite (merele din stratul de jos). Prima trecere a avut mozaic
    # rosu/verde (petic de triunghiuri), a doua RUST (se lipea de lemn: parea pamant).
    def oval(a):
        return (math.cos(a) * 0.270 / 0.17, math.sin(a))
    lathe(b, [(0.170, 0.222), (0.112, 0.282), (0.0, 0.300)], 8,
          lambda k, i: KERB_RED, shape=oval,
          radial=lambda i, k: (1.0 if i % 2 == 0 else 0.86) if k == 1 else 1.0)
    zc = CR_H - APPLE_R + 0.003
    for k, (x, y, z, slot) in enumerate((
            (-0.190, -0.060, zc - 0.012, KERB_RED),
            (-0.070, 0.075, zc - 0.004, TROPICAL_GREEN),
            (0.020, -0.075, zc, KERB_RED),
            (0.140, 0.060, zc - 0.006, KERB_RED),
            (0.205, -0.070, zc - 0.018, TROPICAL_GREEN))):
        b.boulder((x, y, z), (APPLE_R * 2, APPLE_R * 2, APPLE_R * 1.9), slot,
                  seed=31 + k * 7, segments=6, rings=3, deviation=0.04)


# ============================================================ build + export
def build():
    clear_built()
    objs = []
    ok = True

    pot = assemble("ClayPot", [(clay_pot, 0.0, 40.0, 50.0)], AO)
    ok &= report(pot, (0.44, 0.54, 0.44))
    objs.append(pot)

    pk = assemble("Pumpkin", [(pumpkin_body, 0.0, 40.0, 60.0),
                              (pumpkin_stem, 0.0, 40.0, 40.0)], AO)
    # santurile dintre coaste: varfurile de raza mica (coaste impare) mai umbrite
    step = 2.0 * math.pi / PK_SEGS

    def groove(v):
        if math.hypot(v.co.x, v.co.y) < 0.06:      # polii si codita
            return False
        idx = round((math.atan2(v.co.y, v.co.x) - math.radians(PK_PHASE)) / step)
        return idx % 2 == 1
    ao_scale_verts(pk, groove, 0.72)
    ok &= report(pk, (0.50, 0.38, 0.50))
    objs.append(pk)

    cr = assemble("AppleCrate", [(crate_wood, 0.012, 40.0, 40.0),
                                 (crate_core, 0.0, 40.0, 40.0),
                                 (crate_apples, 0.0, 40.0, 85.0)], AO)
    ok &= report(cr, (0.60, 0.34, 0.40))
    objs.append(cr)

    for o in objs:
        o.location = (0.0, 0.0, 0.0)
    print("GLB:", export_glb(objs, OUT))
    print("KNOCK VERDICT:", "OK" if ok else "ABATERI — vezi mai sus")


build()
