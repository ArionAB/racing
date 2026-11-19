"""knock_jodhpur.glb — kitul de piese LOVIBILE de pe marginea drumului, Jodhpur.

Orasul albastru, piata de condimente de sub ceasul Ghanta Ghar: cosuri, oale de apa si
saci care stau pe marginea ulitei si se imprastie cand le loveste masina.

  SpiceBasket  CYL     Ø0.56 x H0.30       cos lat si scund, cu un con de turmeric
  Matka        SPHERE  Ø0.46 x H0.46       oala rotunda de apa, gat scurt (in conturul sferei)
  SpiceSack    BOX     0.46 x 0.62 x 0.36  sac de iuta in picioare, gura rulata in afara,
                                           plin cu ardei iuti rosii

Contractul comun al kiturilor lovibile (cerut de coordonator):
  - un GLB, cate un nod-RADACINA per piesa, toate exportate in (0,0,0), scara aplicata
  - originea la centrul bazei (min Y = 0 in glTF), centrata in plan
  - CYL / SPHERE primesc colizor cilindric / sferic DIN bounding box: cosul si oala sunt de
    revolutie, nimic nu iese din corpul rotund
  - BOX primeste cutia din bounding box: sacul e un strung cu sectiune patratoasa
    (superelipsa) intins exact pe 0,46 x 0,36, fara nimic in afara
  - culoarea doar din ATLAS (UV pe centre de slot), AO copt in vertex colors (finish/bake_ao)
  - <= 320 de triunghiuri pe piesa; rotundele cu >= 10 laturi

Sloturile: FLAMINGO_PINK 31 (rozul pistei) e interzis in kit, iar accentele de masina 14-16
pe care le folosesc sacii statici ai pietei NU sunt voie aici. Turmericul ia SAND_LIGHT 0
(singurul galben al decorului) pe un cos inchis (WOOD 9 / SAND_SHADOW 2, buza LOG_DARK 28),
ca sa nu se lipeasca galbenul de impletitura; matka e RUST 10 cu brau de var CORAL_SAND 19;
sacul SAND_MID 1 (ca sacii din spice_sacks.glb), gura rulata CORAL_SAND 19, ardeii KERB_RED 7
pe RUST 10.

Axe (Blender): X = latimea, Y = adancimea, Z = sus. Godot: (x, z_bl, -y_bl).

Rulare (din radacina checkout-ului):
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_jodhpur.py
Verificare:
    python tools/blender/verify_glb.py assets/models/jodhpur/props/knock_jodhpur.glb 320
"""

import math
import bmesh
import bpy
from mathutils import Matrix, Vector

OUT = "jodhpur/props/knock_jodhpur.glb"
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

INSIDE = LOG_DARK           # 28


def fit_round(segs):
    """Cu 14 laturi niciun varf nu cade pe 90 de grade, deci adancimea masurata iese cu
    2,5 % sub latime si colizorul (din bounding box) n-ar mai fi rotund. Intinde Y cu
    exact cat lipseste: diferenta nu se vede, cutia iese patrata in plan."""
    m = max(abs(math.sin(2.0 * math.pi * i / segs)) for i in range(segs))
    return lambda a: (math.cos(a), math.sin(a) / m)


# ============================================================ SpiceBasket (CYL Ø0.56 x 0.30)
SB = [(0.215, 0.000), (0.240, 0.018), (0.268, 0.080), (0.280, 0.122), (0.280, 0.150),
      (0.258, 0.160), (0.246, 0.142), (0.185, 0.186), (0.112, 0.240), (0.046, 0.284),
      (0.000, 0.300)]


def spice_basket(b):
    def slot(k, i):
        if k <= 2:                                  # impletitura (si fundul)
            return WOOD if (i + max(k, 0)) % 2 == 0 else SAND_SHADOW
        if k in (3, 4, 5):                          # buza infasurata
            return INSIDE
        return SAND_LIGHT                           # conul de turmeric
    lathe(b, SB, 14, slot, shape=fit_round(14))


# ============================================================ Matka (SPHERE Ø0.46 x 0.46)
MATKA = [(0.070, 0.000), (0.145, 0.030), (0.205, 0.095), (0.230, 0.190), (0.225, 0.270),
         (0.190, 0.345), (0.130, 0.395), (0.098, 0.416), (0.118, 0.448), (0.122, 0.460),
         (0.094, 0.460), (0.000, 0.425)]


def matka(b):
    def slot(k, i):
        if k == 5:                                  # braul de var de pe umar
            return CORAL_SAND
        if k >= 10:                                 # gura
            return INSIDE
        return RUST
    lathe(b, MATKA, 14, slot, shape=fit_round(14))


# ============================================================ SpiceSack (BOX 0.46 x 0.62 x 0.36)
SS_W, SS_H, SS_D = 0.46, 0.62, 0.36
SS_ASPECT = SS_D / SS_W


def _squircle(a, n=3.2):
    c, s = math.cos(a), math.sin(a)
    return (math.copysign(abs(c) ** (2.0 / n), c),
            math.copysign(abs(s) ** (2.0 / n), s) * SS_ASPECT)


SACK = [(0.196, 0.000), (0.222, 0.030), (0.230, 0.140), (0.224, 0.300), (0.206, 0.420),
        (0.200, 0.468), (0.221, 0.500), (0.230, 0.538), (0.220, 0.570), (0.194, 0.578),
        (0.184, 0.556), (0.120, 0.596), (0.000, 0.620)]


def spice_sack(b):
    def slot(k, i):
        if k in (6, 7, 8):                          # gura rulata (iuta vazuta pe dos)
            return CORAL_SAND
        if k >= 10:                                 # ardeii: rosu aprins / rosu uscat
            return KERB_RED if (i + k) % 3 else RUST
        return SAND_MID

    def radial(i, k):
        if k in (2, 3):                             # faldurile sacului burdusit
            return 0.965 if i % 3 == 1 else 1.0
        if k == 11:                                 # ardeii: gramada cocoloasa
            return 1.12 if i % 2 == 0 else 0.86
        return 1.0
    lathe(b, SACK, 12, slot, radial=radial, shape=_squircle)


# ============================================================ build + export
def build():
    clear_built()
    objs = []
    ok = True

    sb = assemble("SpiceBasket", [(spice_basket, 0.0, 40.0, 50.0)], AO)
    ok &= report(sb, (0.56, 0.30, 0.56))
    objs.append(sb)

    mk = assemble("Matka", [(matka, 0.0, 40.0, 55.0)], AO)
    ok &= report(mk, (0.46, 0.46, 0.46))
    objs.append(mk)

    ss = assemble("SpiceSack", [(spice_sack, 0.0, 40.0, 50.0)], AO)
    ok &= report(ss, (SS_W, SS_H, SS_D))
    objs.append(ss)

    for o in objs:
        o.location = (0.0, 0.0, 0.0)
    print("GLB:", export_glb(objs, OUT))
    print("KNOCK VERDICT:", "OK" if ok else "ABATERI — vezi mai sus")


build()
