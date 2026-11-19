"""knock_carrara.glb — kitul de recuzita LOVIBILA din cariera de marmura de la Carrara.

Trei piese mici de santier care stau langa drum si zboara cand le loveste o masina:

  SiteCone      HULL  0.40 x 0.75 x 0.40  con de santier portocaliu, doua benzi albe,
                                          talpa patrata neagra
  CableReel     CYL   Ø0.70 x 0.44        tambur de lemn culcat pe o flansa (axa
                                          verticala), miez Ø0.30 cu cablu inchis
                                          infasurat pe el
  MarbleOffcut  BOX   0.50 x 0.42 x 0.46  rest de marmura alba: o fata taiata curat,
                                          colturi ciobite, vinisoare gri doar din sloturi

Contractul (din kitul de recuzita lovibila, valul 3):
  - fiecare piesa = un nod RADACINA cu numele de mai sus, toate exportate la (0,0,0)
  - originea la centrul bazei, scara aplicata, culoarea DOAR din atlas (UV pe
    centrul slotului) + AO copt in vertex colors
  - CYL primeste un colizor cilindric din AABB (raza = flansele), HULL o
    infasuratoare convexa, BOX o cutie: AABB strans
  - max 320 de triunghiuri pe piesa

Sloturile vin din paleta pe care o foloseste deja cariera (census pe
assets/models/carrara): LAVA_ORANGE 30 (singurul portocaliu saturat din paleta;
cariera il are deja pe marble_block_b / marble_block_hooked), FOAM_WHITE 22
(benzile conului si fata taiata proaspat), VOLCANIC_BLACK 20 (talpa conului,
cablul), WOOD 9 + LOG_DARK 28 (tamburul si gaura butucului), CORAL_SAND 19 +
MARBLE_GREY 29 (marmura si vinisoarele ei, ca la blocurile de marmura din lume).

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_carrara.py
"""

import math
import bmesh
import bpy
from mathutils import Vector

KEY = "carrara"
GLB_PATH = "carrara/props/knock_carrara.glb"
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

ORANGE = LAVA_ORANGE    # 30
WHITE = FOAM_WHITE      # 22
BLACK = VOLCANIC_BLACK  # 20
REEL_WOOD = WOOD        # 9
HUB = LOG_DARK          # 28
CABLE = VOLCANIC_BLACK  # 20
MARBLE = CORAL_SAND     # 19 marmura alba, usor calda
VEIN = MARBLE_GREY      # 29
SAWN = FOAM_WHITE       # 22 fata taiata, mai alba si mai rece


def chamfer_rect(hx, hy, c):
    """Dreptunghi cu colturile tesite, 8 puncte in sens trigonometric."""
    return [(hx, -hy + c), (hx, hy - c), (hx - c, hy), (-hx + c, hy),
            (-hx, hy - c), (-hx, -hy + c), (-hx + c, -hy), (hx - c, -hy)]


def cone(b):
    # Talpa patrata cu colturile tesite + con strunjit. Benzile albe sunt doar
    # schimbari de slot pe inelele conului: zero triunghiuri in plus.
    base = [
        (chamfer_rect(0.192, 0.192, 0.05), 0.000, BLACK),
        (chamfer_rect(0.200, 0.200, 0.05), 0.010, BLACK),
        (chamfer_rect(0.200, 0.200, 0.05), 0.036, BLACK),
        (chamfer_rect(0.188, 0.188, 0.05), 0.046, BLACK),
    ]
    loft(b, base, bottom=BLACK, top=BLACK)

    def r_at(z):
        return 0.170 - (0.170 - 0.040) * (z - 0.040) / (0.715 - 0.040)

    prof = [
        (0.176, 0.040, ORANGE),
        (r_at(0.300), 0.300, WHITE),
        (r_at(0.405), 0.405, ORANGE),
        (r_at(0.500), 0.500, WHITE),
        (r_at(0.585), 0.585, ORANGE),
        (0.040, 0.715, ORANGE),
        (0.022, 0.750, ORANGE),
    ]
    lathe(b, prof, 12, bottom=ORANGE, top=ORANGE)


def reel(b):
    # Tambur culcat: flansa de jos, cablu infasurat (doua straturi umflate, ca
    # spirele sa se citeasca la viteza), flansa de sus cu gaura butucului.
    prof = [
        (0.350, 0.000, REEL_WOOD),
        (0.350, 0.034, REEL_WOOD),
        (0.334, 0.044, REEL_WOOD),
        (0.244, 0.044, CABLE),
        (0.258, 0.130, CABLE),
        (0.244, 0.220, CABLE),
        (0.258, 0.310, CABLE),
        (0.244, 0.396, REEL_WOOD),
        (0.334, 0.396, REEL_WOOD),
        (0.350, 0.406, REEL_WOOD),
        (0.350, 0.440, REEL_WOOD),
        (0.075, 0.440, HUB),
        (0.052, 0.424, HUB),
    ]
    lathe(b, prof, 12, bottom=REEL_WOOD, top=HUB)


def offcut_section(hx, hy, chamf, rnd, jit, sawn_hy=None):
    """Perimetrul restului de marmura: 16 puncte, cate 4 pe latura, colturi
    tesite cu marimi diferite (ciobiturile). Latura +Y e fata TAIATA: dreapta,
    fara zgomot, la y = sawn_hy."""
    corners = [Vector((hx, -hy)), Vector((hx, hy)), Vector((-hx, hy)), Vector((-hx, -hy))]
    pts = []
    for k in range(4):
        a, bb = corners[k], corners[(k + 1) % 4]
        d = (bb - a).normalized()
        nrm = Vector((d.y, -d.x))                  # spre exterior (CCW)
        ca, cb = chamf[k], chamf[(k + 1) % 4]
        sawn = (k == 1)
        for t in (0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0):
            p = a + d * ca + (bb - d * cb - (a + d * ca)) * t
            if sawn and sawn_hy is not None:
                p = Vector((p.x, sawn_hy))
            elif 0.0 < t < 1.0:
                p = p + nrm * ((rnd() - 0.5) * 2.0 * jit)
            pts.append((p.x, p.y))
    return pts


def offcut(b):
    hx, hy = 0.241, 0.226
    rnd = _lcg(53)
    # colturi in ordinea (+x,-y), (+x,+y), (-x,+y), (-x,-y); cele doua de pe
    # fata taiata (+Y) sunt muchii curate, celelalte ciobite.
    ch = [0.065, 0.016, 0.016, 0.045]
    secs = []
    for z, inset, cmul, jit in ((0.000, 0.018, 1.0, 0.004), (0.030, 0.0, 1.0, 0.010),
                                (0.200, 0.0, 1.15, 0.012), (0.370, 0.0, 0.9, 0.010),
                                (0.412, 0.032, 1.3, 0.006)):
        c = [max(0.012, x * cmul) for x in ch]
        pts = offcut_section(hx - inset, hy - inset, c, rnd, jit,
                             sawn_hy=hy - inset * 0.3)
        secs.append((pts, z, MARBLE))
    faces = loft(b, secs, bottom=MARBLE, top=MARBLE)
    verts = {v for f in faces for v in f.verts}
    # Fata de sus: nu e lustruita, se misca putin pe z (talpa ramane plata).
    for v in sorted(verts, key=lambda v: (round(v.co.z, 3), v.co.x, v.co.y)):
        if v.co.z > 0.40:
            v.co.z += (rnd() - 0.5) * 0.016
    # Coltul cel mai ciobit (+x,-y,sus) mai coboara o treapta: o aschie rupta.
    for v in verts:
        if v.co.z > 0.36 and v.co.x > 0.17 and v.co.y < -0.15:
            v.co.z -= 0.035
    b.retag(faces, SAWN, where=lambda c, n: n.y > 0.85)
    # Vinisoare: doua benzi oblice si INGUSTE prin tot blocul. Fetele mari ale
    # blocului ar da pete, nu vine (prima incercare arata ca o usa), deci fiecare
    # vena se taie intai in geometrie cu doua plane paralele (bisect, ~2 cm
    # intre ele), iar banda dintre ele primeste slotul gri. Culoarea vine tot
    # numai din slot; costul e doar taietura.
    mid = Vector((0.0, 0.0, 0.21))
    # Venele merg in acelasi sens (aproape paralele, cum curg in marmura):
    # doua vene care se incruciseaza pe fata taiata citeau a cutie legata cu banda.
    for nrm, d, w in ((Vector((0.78, 0.22, 0.58)).normalized(), 0.05, 0.010),
                      (Vector((0.66, 0.36, 0.66)).normalized(), -0.11, 0.007)):
        for off in (d - w, d + w):
            geom = list(b.bm.verts) + list(b.bm.edges) + list(b.bm.faces)
            bmesh.ops.bisect_plane(b.bm, geom=geom, dist=1e-5,
                                   plane_co=mid + nrm * off, plane_no=nrm)
        b.retag(list(b.bm.faces), VEIN, where=lambda c, n, nrm=nrm, d=d, w=w:
                abs(nrm.dot(c - mid) - d) < w)


# ============================================================ build
clear_built("SiteCone")
clear_built("CableReel")
clear_built("MarbleOffcut")

SPECS = [
    ("SiteCone", "HULL", (0.40, 0.75, 0.40),
     [(cone, 0.0, 30.0, 40.0)]),
    ("CableReel", "CYL", (0.70, 0.44, 0.70),
     [(reel, 0.0, 30.0, 50.0)]),
    ("MarbleOffcut", "BOX", (0.50, 0.42, 0.46),
     [(offcut, 0.0, 30.0, 25.0)]),
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
