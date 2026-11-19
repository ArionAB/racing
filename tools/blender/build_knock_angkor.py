"""knock_angkor.glb — kitul de piese LOVIBILE de pe marginea drumului, Angkor.

Templele din jungla Cambodgiei: tarabele de la marginea drumului dintre ruine (nuci de
cocos de baut, cosuri cu orez, vase de apa) care se imprastie cand le loveste masina.

  Coconut     SPHERE  Ø0.30 x H0.32   nuca de cocos verde, de baut, usor ovala, trei muchii
                                      line si varful taiat in con (coaja alba)
  RiceBasket  CYL     Ø0.52 x H0.36   cos impletit, adanc, cu o bolta de orez alb
  WaterJar    CYL     Ø0.46 x H0.58   vas khmer de apa, glazurat inchis, cu umeri si gura mica

Contractul comun al kiturilor lovibile (cerut de coordonator):
  - un GLB, cate un nod-RADACINA per piesa, toate exportate in (0,0,0), scara aplicata
  - originea la centrul bazei (min Y = 0 in glTF), centrata in plan
  - CYL / SPHERE primesc colizor cilindric / sferic DIN bounding box: toate trei sunt de
    revolutie, nimic nu iese din corpul rotund (nuca sta pe un punct: e voie la sfera)
  - culoarea doar din ATLAS (UV pe centre de slot), AO copt in vertex colors (finish/bake_ao)
  - <= 320 de triunghiuri pe piesa; rotundele cu >= 10 laturi (sfera >= 10 x 6)

Sloturile: CACTUS_GREEN 12 (verdele-galbui al nucii tinere; frunzisul pistei e pe 12/21) cu
conul taiat din varf CORAL_SAND 19 (coaja alba, ca pe nucile de baut de pe taraba); cosul SAND_MID 1 / WOOD 9 cu orez FOAM_WHITE 22; vasul glazurat LOG_DARK 28
cu talpa nesmaltuita TILE_TERRACOTTA 23, glazura subtiata pe umar SAND_SHADOW 2 si gura
ICE_CRACK 26 (cel mai inchis slot legal: pe glazura aproape neagra, VOLCANIC_BLACK iesea un
capac gri, nu un gol).

Axe (Blender): X = latimea, Y = adancimea, Z = sus. Godot: (x, z_bl, -y_bl).

Rulare (din radacina checkout-ului):
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_angkor.py
Verificare:
    python tools/blender/verify_glb.py assets/models/angkor/props/knock_angkor.glb 320
"""

import math
import bmesh
import bpy
from mathutils import Matrix, Vector

OUT = "angkor/props/knock_angkor.glb"
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


def fit_round(segs):
    """Cu 14 laturi niciun varf nu cade pe 90 de grade, deci adancimea masurata iese cu
    2,5 % sub latime si colizorul (din bounding box) n-ar mai fi rotund. Intinde Y cu
    exact cat lipseste: diferenta nu se vede, cutia iese patrata in plan."""
    m = max(abs(math.sin(2.0 * math.pi * i / segs)) for i in range(segs))
    return lambda a: (math.cos(a), math.sin(a) / m)


# ============================================================ Coconut (SPHERE Ø0.30 x 0.32)
CN_R, CN_H = 0.15, 0.32
CN_SEGS = 14
CN_LATS = [-90.0 + 180.0 * (k + 1) / 8.0 for k in range(7)]      # 7 inele


def _cn_profile():
    c = CN_H * 0.5
    prof = [(0.0, 0.0)]
    for lat in CN_LATS:
        la = math.radians(lat)
        s = math.sin(la)
        # varful se ascute usor (nuca tanara), baza ramane plina; inelul de sus e mai
        # strans: acolo coaja e taiata in con, ca la nucile de baut de pe taraba
        r = CN_R * math.cos(la) * (1.0 - 0.10 * max(0.0, s))
        if lat > 60.0:
            r *= 0.80
        prof.append((r, c + c * s))
    prof.append((0.0, CN_H))
    return prof


def coconut(b):
    prof = _cn_profile()
    last = len(prof) - 2                    # evantaiul din varf

    def slot(k, i):
        # conul taiat din varf: coaja alba de sub pielea verde. Prima trecere avea doar
        # caliciul maro si nuca se citea ca o minge verde (lime, mar)
        return CORAL_SAND if k >= last - 1 else CACTUS_GREEN
    # trei muchii line pe lungime (nuca de cocos are sectiunea usor triunghiulara)
    lathe(b, prof, CN_SEGS, slot, shape=fit_round(CN_SEGS),
          radial=lambda i, k: 1.0 + 0.035 * math.cos(3.0 * 2.0 * math.pi * i / CN_SEGS))


# ============================================================ RiceBasket (CYL Ø0.52 x 0.36)
RB = [(0.200, 0.000), (0.222, 0.018), (0.245, 0.110), (0.258, 0.200), (0.260, 0.232),
      (0.260, 0.254), (0.240, 0.262), (0.232, 0.250), (0.195, 0.300), (0.135, 0.336),
      (0.065, 0.355), (0.000, 0.360)]


def rice_basket(b):
    def slot(k, i):
        if k <= 3:                                 # impletitura
            return SAND_MID if (i + max(k, 0)) % 2 == 0 else WOOD
        if k in (4, 5, 6):                         # buza infasurata
            return WOOD
        return FOAM_WHITE                          # orezul
    lathe(b, RB, 14, slot, shape=fit_round(14))


# ============================================================ WaterJar (CYL Ø0.46 x 0.58)
WJ = [(0.140, 0.000), (0.160, 0.014), (0.172, 0.062), (0.205, 0.170), (0.230, 0.330),
      (0.210, 0.420), (0.152, 0.488), (0.088, 0.526), (0.072, 0.544), (0.086, 0.580),
      (0.058, 0.580), (0.000, 0.548)]


def water_jar(b):
    def slot(k, i):
        if k <= 1:                                 # talpa nesmaltuita (si fundul)
            return TILE_TERRACOTTA
        if k == 4:                                 # glazura subtiata pe umar
            return SAND_SHADOW
        if k >= 10:                                # gura: cel mai inchis slot legal (gol)
            return ICE_CRACK
        return LOG_DARK                            # glazura inchisa
    lathe(b, WJ, 14, slot, shape=fit_round(14))


# ============================================================ build + export
def build():
    clear_built()
    objs = []
    ok = True

    cn = assemble("Coconut", [(coconut, 0.0, 40.0, 60.0)], AO)
    ok &= report(cn, (0.30, 0.32, 0.30))
    objs.append(cn)

    rb = assemble("RiceBasket", [(rice_basket, 0.0, 40.0, 50.0)], AO)
    ok &= report(rb, (0.52, 0.36, 0.52))
    objs.append(rb)

    wj = assemble("WaterJar", [(water_jar, 0.0, 40.0, 55.0)], AO)
    ok &= report(wj, (0.46, 0.58, 0.46))
    objs.append(wj)

    for o in objs:
        o.location = (0.0, 0.0, 0.0)
    print("GLB:", export_glb(objs, OUT))
    print("KNOCK VERDICT:", "OK" if ok else "ABATERI — vezi mai sus")


build()
