"""knock_transfagarasan.glb — kitul de recuzita LOVIBILA de la stana (Transfagarasan).

Trei piese mici care stau langa drum si zboara cand le loveste o masina:

  MilkChurn    CYL  Ø0.34 x 0.62  bidon de lapte din aluminiu (umar + capac)
  CheeseWheel  CYL  Ø0.50 x 0.16  roata de cascaval, coaja galbena + banda de ceara
  HayBale      BOX  0.90 x 0.45 x 0.45  balot mic de fan cu doua sfori

Contractul (din kitul de recuzita lovibila, valul 3):
  - fiecare piesa = un nod RADACINA cu numele de mai sus, toate exportate la (0,0,0)
  - originea la centrul bazei, scara aplicata, culoarea DOAR din atlas (UV pe
    centrul slotului) + AO copt in vertex colors
  - CYL primeste un colizor cilindric calculat din AABB, pe axa verticala: nimic
    nu iese din corpul rotund cu mai mult de 3 cm (manerele bidonului stau in
    raza corpului, sub umar)
  - max 320 de triunghiuri pe piesa

Sloturile sunt cele pe care lumea le foloseste deja (census pe
assets/models/transfagarasan): MARBLE_GREY 29 (aluminiu), ASPHALT_EDGE 6
(cercuri, manere, buza capacului), SAND_LIGHT 0 / KERB_RED 7
(cascavalul), DRY_VEGETATION 13 + LOG_DARK 28 (fanul si sfoara).

Corpurile rotunde sunt STRUNJITE dintr-un profil (`lathe`) cu tesiturile
desenate in profil, nu cu bevel: pe un corp de revolutie bevel-ul ar dubla
fiecare inel de muchie, iar bugetul de 320 nu duce asta. Cutiile primesc
bevel-ul obisnuit (style_bible §3: 0.04 la prop-uri).

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_transfagarasan.py
"""

import math
import bpy
from mathutils import Vector

KEY = "transfagarasan"
GLB_PATH = "transfagarasan/props/knock_transfagarasan.glb"
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

ALU = MARBLE_GREY       # 29 aluminiu
ALU_DARK = ASPHALT_EDGE  # 6  cercuri laminate, manere
LID = MARBLE_GREY       # 29 capacul, acelasi aluminiu; buza lui e inchisa
RIND = SAND_LIGHT       # 0  coaja de cascaval
WAX = KERB_RED          # 7  banda de ceara rosie (ca la cascavalul din comert)
HAY = DRY_VEGETATION    # 13
HAY_END = SAND_LIGHT    # 0  capetele taiate ale balotului, mai deschise
TWINE = LOG_DARK        # 28


def churn_body(b):
    # Profil de bidon: talpa tesita, cerc laminat jos, corp drept, cerc laminat
    # sub umar, umar conic, gat, capac-ciuperca. Raza maxima 0.170 = Ø0.34.
    prof = [
        (0.156, 0.000, ALU_DARK),
        (0.170, 0.050, ALU),
        (0.166, 0.350, ALU_DARK),
        (0.170, 0.365, ALU_DARK),
        (0.170, 0.395, ALU),
        (0.103, 0.470, ALU),
        (0.094, 0.512, ALU_DARK),
        (0.118, 0.524, ALU_DARK),
        (0.118, 0.550, LID),
        (0.084, 0.588, LID),
        (0.036, 0.618, LID),
    ]
    lathe(b, prof, 12, bottom=ALU_DARK, top=LID)


def churn_handles(b):
    # Doua manere-chinga pe laturi, de la gat la umar. Raza exterioara 0.164:
    # raman in cercul corpului (0.170), deci colizorul nu se lateste.
    for s in (-1.0, 1.0):
        p0 = Vector((s * 0.092, 0.0, 0.492))
        p1 = Vector((s * 0.152, 0.0, 0.468))
        p2 = Vector((s * 0.152, 0.0, 0.418))
        b.beam(p0, p1, (0.024, 0.040), ALU_DARK, up=(0, 1, 0))
        b.beam(p1 + Vector((0, 0, 0.010)), p2, (0.024, 0.040), ALU_DARK, up=(0, 1, 0))


def cheese(b):
    # Roata de cascaval: muchii rotunjite, banda de ceara pe mijlocul flancului,
    # fata de sus usor bombata.
    prof = [
        (0.222, 0.000, RIND),
        (0.243, 0.016, RIND),
        (0.250, 0.046, WAX),
        (0.250, 0.112, RIND),
        (0.243, 0.142, RIND),
        (0.222, 0.157, RIND),
        (0.120, 0.162, RIND),
    ]
    lathe(b, prof, 16, bottom=RIND, top=RIND)


def bale_outline(grow=0.0, inset=1.0):
    """Sectiunea balotului in planul (y, z): dreptunghi cu colturi tesite si
    flancuri usor umflate (12 puncte). `grow` il umfla spre exterior (sfoara),
    `inset` il strange spre centru (tesitura capetelor). Talpa ramane la z >= 0."""
    hy, hz, c, zc = 0.215, 0.220, 0.050, 0.220
    pts = [(0.0, -hz), (hy - c, -hz), (hy, -hz + c), (hy + 0.006, 0.0),
           (hy, hz - c), (hy - c, hz), (0.0, hz + 0.004), (-hy + c, hz),
           (-hy, hz - c), (-hy - 0.006, 0.0), (-hy, -hz + c), (-hy + c, -hz)]
    out = []
    for i, (y, zz) in enumerate(pts):
        # normala de varf = media normalelor celor doua laturi vecine
        py, pz = pts[i - 1]
        ny_, nz_ = pts[(i + 1) % len(pts)]
        e1 = Vector((y - py, zz - pz)).normalized()
        e2 = Vector((ny_ - y, nz_ - zz)).normalized()
        nrm = Vector((e1.y + e2.y, -(e1.x + e2.x)))
        nrm = nrm.normalized() if nrm.length > 1e-6 else Vector((0.0, 0.0))
        if nrm.dot(Vector((y, zz))) < 0.0:
            nrm = -nrm
        y2, z2 = y * inset + nrm.x * grow, zz * inset + nrm.y * grow
        out.append((y2, max(z2 + zc, 0.0) if grow > 0 else z2 + zc))
    return out


def bale(b):
    # Balotul se strunjeste PE LUNGIME (x): sectiunile de mai sus, puse la
    # cotele de mai jos. Sforile sunt doua inele ale aceluiasi corp, umflate cu
    # 1.2 cm — nu cutii lipite deasupra, deci nicio fata ascunsa si colizorul de
    # cutie ramane strans. Doua sfori in jurul taliei, ca la balotul de jucarie.
    T = 0.012
    stations = [
        (-0.440, 0.0, 0.88, HAY), (-0.405, 0.0, 1.0, HAY),
        (-0.245, 0.0, 1.0, TWINE), (-0.245, T, 1.0, TWINE),
        (-0.205, T, 1.0, TWINE), (-0.205, 0.0, 1.0, HAY),
        (0.205, 0.0, 1.0, TWINE), (0.205, T, 1.0, TWINE),
        (0.245, T, 1.0, TWINE), (0.245, 0.0, 1.0, HAY),
        (0.405, 0.0, 1.0, HAY), (0.440, 0.0, 0.88, HAY),
    ]
    secs = []
    for x, grow, inset, slot in stations:
        secs.append((bale_outline(grow, inset), x, slot))
    first = len(b.bm.verts)
    faces = loft(b, secs, bottom=HAY_END, top=HAY_END)
    b.bm.verts.ensure_lookup_table()
    # loft-ul a construit (y, z, x) in (x, y, z): permutare ciclica -> (x, y, z)
    for v in b.bm.verts[first:]:
        y, zz, x = v.co.x, v.co.y, v.co.z
        v.co = Vector((x, y, zz))
    # Fanul nu e o cutie de plastic: varfurile se misca putin, determinist.
    # Talpa (z ~ 0) si sforile nu se ating, ca balotul sa stea drept.
    rnd = _lcg(17)
    twine_verts = {v for f in faces if f[b.slot] == TWINE for v in f.verts}
    for v in b.bm.verts[first:]:
        if v in twine_verts or v.co.z < 0.01:
            continue
        v.co.x += (rnd() - 0.5) * 0.014
        v.co.y += (rnd() - 0.5) * 0.010
        v.co.z += (rnd() - 0.5) * 0.010


# ============================================================ build
clear_built("MilkChurn")
clear_built("CheeseWheel")
clear_built("HayBale")

SPECS = [
    ("MilkChurn", "CYL", (0.34, 0.62, 0.34),
     [(churn_body, 0.0, 30.0, 40.0), (churn_handles, 0.0, 40.0, 40.0)]),
    ("CheeseWheel", "CYL", (0.50, 0.16, 0.50),
     [(cheese, 0.0, 30.0, 40.0)]),
    ("HayBale", "BOX", (0.90, 0.45, 0.45),
     [(bale, 0.0, 30.0, 35.0)]),
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
