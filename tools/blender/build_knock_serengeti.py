"""knock_serengeti.glb — kitul de piese LOVIBILE de pe marginea drumului, Serengeti.

Tabara de safari si drumul de pamant: bidoanele, lazile si canistrele care stau langa
Land Rover si cortul de tabara, si care se imprastie cand le loveste masina.

  OilDrum      CYL  Ø0.58 x H0.88       butoi de otel vopsit kaki-oliv, doua cercuri rulate
  SupplyCrate  BOX  0.62 x 0.42 x 0.44  lada de provizii: lemn, sipci pe colturi, manere de
                                        franghie (in interiorul cutiei)
  Jerrycan     BOX  0.36 x 0.48 x 0.18  canistra clasica: X-ul presat pe flancuri, manerul cu
                                        trei bare sus (in interiorul cutiei)

Contractul comun al kiturilor lovibile (cerut de coordonator):
  - un GLB, cate un nod-RADACINA per piesa, toate exportate in (0,0,0), scara aplicata
  - originea la centrul bazei (min Y = 0 in glTF), centrata in plan
  - CYL primeste cilindrul DIN bounding box: butoiul e de revolutie si cercurile lui SUNT
    diametrul (ies 1,4 cm peste corp), deci colizorul cade pe cercuri, cum se rostogoleste
  - BOX primeste cutia din bounding box: manerele, franghiile si X-ul stau inauntru
  - culoarea doar din ATLAS (UV pe centre de slot), AO copt in vertex colors (finish/bake_ao)
  - <= 320 de triunghiuri pe piesa; rotundele cu >= 10 laturi

Sloturile: CACTUS_GREEN 12 si DRY_VEGETATION 13 (acaciile, iarba savanei) dau oliv-kaki-ul
butoiului; SAND_LIGHT 0 / WOOD 9 lada (cortul de tabara e pe 1-2); CORAL_SAND 19 franghia;
KERB_RED 7 + RUST 10 canistra (accentul de culoare al taberei); VOLCANIC_BLACK 20 manerele.

Axe (Blender): X = latimea, Y = adancimea, Z = sus. Godot: (x, z_bl, -y_bl).

Rulare (din radacina checkout-ului):
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_serengeti.py
Verificare:
    python tools/blender/verify_glb.py assets/models/serengeti/props/knock_serengeti.glb 320
"""

import math
import bmesh
import bpy
from mathutils import Matrix, Vector

OUT = "serengeti/props/knock_serengeti.glb"
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

OLIVE = CACTUS_GREEN        # 12
KHAKI = DRY_VEGETATION      # 13
ROPE = CORAL_SAND           # 19
DARK = VOLCANIC_BLACK       # 20


# ============================================================ OilDrum (CYL Ø0.58 x 0.88)
DR_R, DR_HOOP, DR_H = 0.276, 0.290, 0.880


def _hoop(z):
    # cerc RULAT: o creasta, nu o banda lipita. Netezit, citeste ca tubul presat in tabla.
    return [(DR_R, z - 0.042), (DR_HOOP, z), (DR_R, z + 0.042)]


DRUM = ([(0.266, 0.000), (0.282, 0.020), (DR_R, 0.052)]          # buza de jos (falt)
        + _hoop(0.295) + _hoop(0.585)
        + [(DR_R, 0.828), (0.282, 0.860), (0.268, DR_H),          # buza de sus
           (0.250, DR_H - 0.012)])                                # capacul, adancit


def oil_drum(b):
    n = len(DRUM)

    def slot(k, i):
        # corpul kaki, cercurile, falturile si capacul in oliv inchis: prima trecere (corp
        # oliv, cercuri kaki) iesea un butoi verde-crud cu dungi subtiri
        if k in (2, 5, 8):
            return KHAKI
        return OLIVE
    lathe(b, DRUM, 12, slot)


# ============================================================ SupplyCrate (BOX 0.62 x 0.42 x 0.44)
SC_W, SC_H, SC_D = 0.62, 0.42, 0.44
SC_BAT = 0.065                # latura sipcii de colt
SC_IN = 0.02                  # cat ies sipcile peste panouri


def crate_shell(b):
    hw, hd = SC_W / 2 - SC_IN, SC_D / 2 - SC_IN
    box_mm(b, -hw, hw, -hd, hd, 0.0, SC_H - 0.004, SAND_LIGHT)
    # rama capacului si talpa: benzi de lemn inchis pe tot conturul
    box_mm(b, -hw - 0.010, hw + 0.010, -hd - 0.010, hd + 0.010, SC_H - 0.060, SC_H, WOOD)
    box_mm(b, -hw - 0.010, hw + 0.010, -hd - 0.010, hd + 0.010, 0.0, 0.050, WOOD)


def crate_battens(b):
    for sx in (-1, 1):
        for sy in (-1, 1):
            xs = sorted((sx * SC_W / 2, sx * (SC_W / 2 - SC_BAT)))
            ys = sorted((sy * SC_D / 2, sy * (SC_D / 2 - SC_BAT)))
            box_mm(b, xs[0], xs[1], ys[0], ys[1], 0.0, SC_H, WOOD)


def crate_ropes(b):
    x_face = SC_W / 2 - SC_IN
    for sx in (-1, 1):
        x = sx * (x_face + 0.006)       # franghia (r 0,012) ramane sub fata sipcilor
        # doua tachete pe flanc (lemn) si bucla de franghie atarnata intre ele
        for y in (-0.085, 0.085):
            xs = sorted((sx * (x_face - 0.01), sx * (x_face + 0.014)))
            box_mm(b, xs[0], xs[1], y - 0.03, y + 0.03, 0.285, 0.335, WOOD)
        b.sweep([(x, -0.085, 0.300), (x, -0.060, 0.235), (x, 0.060, 0.235), (x, 0.085, 0.300)],
                0.012, ROPE, segments=5, dome_end=False, cap_start=True)


# ============================================================ Jerrycan (BOX 0.36 x 0.48 x 0.18)
JC_W, JC_H, JC_D = 0.36, 0.48, 0.18
JC_BODY_H = 0.415
JC_HW, JC_HD = 0.175, 0.080


def jerry_body(b):
    box_mm(b, -JC_HW, JC_HW, -JC_HD, JC_HD, 0.0, JC_BODY_H, KERB_RED)


def jerry_detail(b):
    # cordonul de sudura pe tot conturul, in planul de mijloc
    box_mm(b, -JC_W / 2, JC_W / 2, -0.012, 0.012, 0.004, JC_BODY_H + 0.006, RUST)
    # X-ul presat pe ambele flancuri (iese 1 cm: D = 0.18)
    for sy in (-1, 1):
        y = sy * (JC_HD + 0.005)
        for (x0, z0, x1, z1) in ((-0.125, 0.055, 0.125, 0.360), (0.125, 0.055, -0.125, 0.360)):
            b.beam((x0, y, z0), (x1, y, z1), (0.040, 0.012), RUST, up=(0, 1, 0))
    # manerul: doua console + trei bare paralele (pe X), cu golul pentru mana dedesubt
    z0, z1 = JC_BODY_H - 0.005, JC_H
    for xa, xb in ((-0.150, -0.118), (0.010, 0.042)):
        box_mm(b, xa, xb, -0.068, 0.068, z0, z1, DARK)
    for y in (-0.048, 0.0, 0.048):
        box_mm(b, -0.122, 0.014, y - 0.013, y + 0.013, z1 - 0.030, z1, DARK)
    # gura de umplere, pe coltul opus
    b.cylinder((0.118, 0.0, JC_BODY_H + 0.022), 0.034, 0.050, DARK, segments=10)


# ============================================================ build + export
def build():
    clear_built()
    objs = []
    ok = True

    drum = assemble("OilDrum", [(oil_drum, 0.0, 40.0, 50.0)], AO)
    ok &= report(drum, (0.58, 0.88, 0.58))
    objs.append(drum)

    crate = assemble("SupplyCrate", [(crate_shell, 0.012, 40.0, 40.0),
                                     (crate_battens, 0.0, 40.0, 40.0),
                                     (crate_ropes, 0.0, 40.0, 70.0)], AO)
    ok &= report(crate, (SC_W, SC_H, SC_D))
    objs.append(crate)

    jc = assemble("Jerrycan", [(jerry_body, 0.022, 40.0, 40.0),
                               (jerry_detail, 0.0, 40.0, 40.0)], AO)
    ok &= report(jc, (JC_W, JC_H, JC_D))
    objs.append(jc)

    for o in objs:
        o.location = (0.0, 0.0, 0.0)
    print("GLB:", export_glb(objs, OUT))
    print("KNOCK VERDICT:", "OK" if ok else "ABATERI — vezi mai sus")


build()
