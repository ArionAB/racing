"""Jodhpur -- Cetatea, val 2a (brief §1.2, docs/asset_briefs/jodhpur_kit.md).

  jodhpur/structures/fort_wall_segment.glb   modul de zid inlantuibil
  jodhpur/structures/fort_wall_turret.glb    turnul patrat de la capetele tronsonului
  jodhpur/structures/fort_bastion.glb        burjul rotund
  jodhpur/structures/fort_gate_jai.glb       poarta Jai Pol (cea mai inalta)
  jodhpur/structures/fort_gate_fateh.glb     poarta Fateh Pol (chhatri peste arc)
  jodhpur/structures/fort_gate_loha.glb      poarta Loha Pol (cea mai joasa)
  jodhpur/structures/palace_facade_a.glb     Moti Mahal -- fatada lunga
  jodhpur/structures/palace_facade_b.glb     fatada simetrica cu cupola centrala
  jodhpur/props/rampart_cannon.glb           tunul de pe metereze

Urmeaza patronul pilotului acceptat (`build_jodhpur_pilot.py`, v3): vocabular
din `jodhpur_shapes.py`, sloturi din tabelul §0.4, `_finish_or_none` pentru
Builder-ele GLOW care pot ramane goale, `emit()` cu origine calculata o data
pe ansamblu.

**Orientare (gasita empiric, ca in pilot):** un test cu doua cutii lungi
(una cu lungimea pe X, fata mare spre +Y; alta cu lungimea pe Y, fata mare
spre +X), randate cu EXACT camera din `compare()` (azimut 35, elevatie 18),
a aratat ca varianta cu **lungimea pe Y si fata principala spre +X** se
citeste ca "fatada lunga vazuta din fata" -- cealalta (lungime pe X) se vede
oblic, foarte scurtata. Confirma si testul de cub colorat pe fete din pilot
(+X = fata dominanta a camerei). De-aici, toate piesele alungite de aici
(zid, poarta, fatade de palat) au **lungimea pe Y, fata principala pe +X**.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_jodhpur_fort.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "jodhpur_shapes.py")).read())

# Sloturile legale pe Jodhpur (brief §0.4).
STONE = ROCK_LIGHT       # gresia fortului -> clasa red_sandstone la integrare
DOOR_WOOD = WOOD         # canaturile de lemn (Jai, Fateh)
DOOR_IRON = PAINTED      # canaturile de fier (Loha)
STUD = VOLCANIC_BLACK    # tepii canaturilor, geometrie mica
GLOW = VOLCANIC_BLACK    # ferestrele inchise ziua (Palace_Glow, brief regula 7), runda 2
CANNON_METAL = VOLCANIC_BLACK
CANNON_WOOD = WOOD

AO_STONE = dict(samples=24, dist=6.0, gradient="vertical",
                low=0.42, high=1.00, power=0.85, floor=0.16)
AO_PROP = dict(samples=16, dist=2.5, gradient="vertical",
               low=0.5, high=1.0, power=0.85, floor=0.2)
AO_DOOR = dict(samples=12, dist=0.6, gradient="vertical",
               low=0.72, high=1.0, power=0.85, floor=0.45)

# rotatie care duce fata implicita +Y a lui `chajja`/`arch_opening` pe +X
# (fata principala catre camera, vezi nota de orientare de mai sus)
ROT_YTOX = Matrix.Rotation(math.radians(-90.0), 3, "Z")
ROT_YTONX = Matrix.Rotation(math.radians(90.0), 3, "Z")


def _finish_or_none(obj):
    """Ca in pilot: un Builder care a ramas gol (fara varfuri) se sterge in
    loc sa mearga la `finish` (crapa pe bbox gol la set_origin_base)."""
    if obj is None:
        return None
    if len(obj.data.vertices) == 0:
        name = obj.name
        me = obj.data
        bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.meshes.remove(me)
        return None
    return obj



# =============================================================================
# facade -- perete PLAN cu goluri retrase (runda fort3)
# =============================================================================
#
# De ce (verdictul liderului pe fort2): portile si fatadele de palat erau
# construite din `arch_opening` cu panou propriu per gol -- fiecare fereastra
# iesea ca o "rama" lipita pe o cutie, iar fatada A ramasese "o cutie joasa cu
# cateva nise". Acelasi diagnostic ca la casele albastre (runda 3 a orasului):
# peretele trebuie sa fie o GRILA -- coloane la marginile golurilor x randuri
# la praguri/buiandrugi, fiecare celula plina sau gol, iar timpanele arcelor
# lipite pe aceleasi varfuri. Golurile raman retrase, cu placa GLOW in fund.
#
# COPIE a helper-ului `facade()` din build_jodhpur_city.py (acelasi autor,
# runda 3 a orasului), nu import: `jodhpur_shapes.py` e vocabular comun si
# constructorul orasului lucreaza IN PARALEL pe build_jodhpur_city.py, deci
# nici promovarea in vocabular, nici exec pe fisierul lui nu sunt sigure acum.
# Diferente fata de original: `fill="none"` (gol strapuns, fara fund -- gura
# portii), `fill="jali"` (placa GLOW + grila de piatra 3 x 4 in fata ei,
# brief §1.2 palace_facade_a), `point` per gol (arc ascutit turtit), si
# `facade_bays` care sparge un perete lung in travee (grila unei singure
# bucati propaga fiecare coloana de gol pe toata inaltimea -- mii de celule).
#
# Promovarea in jodhpur_shapes.py e de facut la integrarea ramurilor.

def _fx(p0, u, n):
    P0 = Vector(p0)
    U = Vector(u).normalized()
    N = Vector(n).normalized()

    def W(uu, z, d):
        return P0 + U * uu + N * d + Vector((0.0, 0.0, z))
    return W


def _lbox(b, W, u0, u1, z0, z1, d0, d1, slot):
    """Cutie inchisa in coordonatele locale (u, z, d) ale unei fete."""
    if u1 - u0 < 1e-4 or z1 - z0 < 1e-4 or abs(d1 - d0) < 1e-5:
        return []
    vs = {}
    for iu, uu in enumerate((u0, u1)):
        for iz, z in enumerate((z0, z1)):
            for idd, d in enumerate((d0, d1)):
                vs[(iu, iz, idd)] = b.bm.verts.new(W(uu, z, d))

    def v(a, c, e):
        return vs[(a, c, e)]
    quads = [
        (v(0, 0, 0), v(0, 0, 1), v(0, 1, 1), v(0, 1, 0)),
        (v(1, 0, 0), v(1, 1, 0), v(1, 1, 1), v(1, 0, 1)),
        (v(0, 0, 0), v(1, 0, 0), v(1, 0, 1), v(0, 0, 1)),
        (v(0, 1, 0), v(0, 1, 1), v(1, 1, 1), v(1, 1, 0)),
        (v(0, 0, 0), v(0, 1, 0), v(1, 1, 0), v(1, 0, 0)),
        (v(0, 0, 1), v(1, 0, 1), v(1, 1, 1), v(0, 1, 1)),
    ]
    faces = [b.bm.faces.new(q) for q in quads]
    for f in faces:
        f[b.slot] = slot
    return faces


def _lprism(b, W, poly, d0, d1, slot):
    """Prisma inchisa dintr-un poligon simplu (u, z), extrudata pe normala."""
    clean = []
    for p in poly:
        if not clean or math.hypot(p[0] - clean[-1][0], p[1] - clean[-1][1]) > 1e-5:
            clean.append(p)
    if len(clean) > 2 and math.hypot(clean[0][0] - clean[-1][0],
                                     clean[0][1] - clean[-1][1]) <= 1e-5:
        clean.pop()
    if len(clean) < 3:
        return []
    fr = [b.bm.verts.new(W(uu, z, d1)) for uu, z in clean]
    bk = [b.bm.verts.new(W(uu, z, d0)) for uu, z in clean]
    faces = []
    for i0, i1, i2 in _ear_clip(clean):
        faces.append(b.bm.faces.new((fr[i0], fr[i1], fr[i2])))
        faces.append(b.bm.faces.new((bk[i2], bk[i1], bk[i0])))
    m = len(clean)
    for i in range(m):
        j = (i + 1) % m
        faces.append(b.bm.faces.new((fr[i], bk[i], bk[j], fr[j])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _lband(b, W, pts, width, d0, d1, slot, closed=False, outward=True):
    """Banda de sectiune dreptunghiulara de-a lungul unei polilinii (u, z) --
    rama. Polilinia merge in sensul golului, stanga sensului = in afara lui."""
    n = len(pts)
    if n < 2:
        return []
    nseg = n if closed else n - 1
    segn = []
    for i in range(nseg):
        a, c = pts[i], pts[(i + 1) % n]
        dx, dz = c[0] - a[0], c[1] - a[1]
        ln = math.hypot(dx, dz) or 1e-9
        segn.append((-dz / ln, dx / ln))
    sgn = 1.0 if outward else -1.0
    offs = []
    for i in range(n):
        if closed:
            n0, n1 = segn[i - 1], segn[i % nseg]
        else:
            n0 = segn[max(i - 1, 0)]
            n1 = segn[min(i, nseg - 1)]
        mx, mz = n0[0] + n1[0], n0[1] + n1[1]
        ml = math.hypot(mx, mz) or 1e-9
        mx, mz = mx / ml, mz / ml
        cosv = max(mx * n0[0] + mz * n0[1], 0.35)
        offs.append((pts[i][0] + sgn * mx * width / cosv,
                     pts[i][1] + sgn * mz * width / cosv))
    ring = []
    for i in range(n):
        ring.append([b.bm.verts.new(W(pts[i][0], pts[i][1], d1)),
                     b.bm.verts.new(W(offs[i][0], offs[i][1], d1)),
                     b.bm.verts.new(W(offs[i][0], offs[i][1], d0)),
                     b.bm.verts.new(W(pts[i][0], pts[i][1], d0))])
    faces = []
    for i in range(nseg):
        A, B = ring[i], ring[(i + 1) % n]
        for k in range(4):
            k2 = (k + 1) % 4
            faces.append(b.bm.faces.new((A[k], B[k], B[k2], A[k2])))
    if not closed:
        faces.append(b.bm.faces.new(tuple(ring[0])))
        faces.append(b.bm.faces.new(tuple(reversed(ring[-1]))))
    for f in faces:
        f[b.slot] = slot
    return faces


def _opening_contour(o, steps=8):
    uc, z, w, h = o["u"], o["z"], o["w"], o["h"]
    hw = w * 0.5
    if o.get("arch"):
        pier = o.get("pier", h - hw)
        pts = arch_hole_contour(o.get("style", "round"), w, h, pier, steps,
                                point=o.get("point", 0.2))
        return [(uc + x, z + zz) for x, zz in pts]
    return [(uc - hw, z), (uc - hw, z + h), (uc + hw, z + h), (uc + hw, z)]


def facade(b, bglow, btrim, p0, u, n, width, height, thick, openings, slot,
           glow_slot, trim_slot, frame_slot=None, steps=8, bframe=None,
           cap_left=True, cap_right=True, cap_top=True):
    """Perete plan `width` x `height`, coltul stanga-jos al FETEI in `p0`,
    `u` = spre dreapta vazut din afara, `n` = normala exterioara, gros `thick`
    spre interior. Gol: dict cu u (centru), z (prag), w, h; optional
    arch=True, style, pier, point; fill="glow"|"wood"|"shutter"|"open"|
    "none"|"jali"; frame (0 = fara), frame_out, sill, step, reveal."""
    frame_slot = frame_slot if frame_slot is not None else slot
    bf = bframe if bframe is not None else b
    W = _fx(p0, u, n)
    wall, frame, glow, trim = [], [], [], []
    ops = [dict(o) for o in openings]
    for o in ops:
        o["_hw"] = o["w"] * 0.5
        o["_pier"] = o.get("pier", o["h"] - o["_hw"]) if o.get("arch") else o["h"]

    def key(x):
        return round(x, 5)
    us, zs = {0.0, width}, {0.0, height}
    for o in ops:
        us |= {o["u"] - o["_hw"], o["u"] + o["_hw"]}
        zs |= {o["z"], o["z"] + o["h"]}
        if o.get("arch"):
            us.add(o["u"])
            zs.add(o["z"] + o["_pier"])
    us = sorted({key(min(max(x, 0.0), width)) for x in us})
    zs = sorted({key(min(max(x, 0.0), height)) for x in zs})
    nu, nz = len(us) - 1, len(zs) - 1

    def cell(i, j):
        if i < 0 or j < 0 or i >= nu or j >= nz:
            return "out"
        um, zm = (us[i] + us[i + 1]) * 0.5, (zs[j] + zs[j + 1]) * 0.5
        for o in ops:
            if abs(um - o["u"]) < o["_hw"] and o["z"] < zm < o["z"] + o["h"]:
                if o.get("arch") and zm > o["z"] + o["_pier"]:
                    return "rise"
                return "hole"
        return "solid"

    V = {}

    def gv(i, j, layer):
        k = (i, j, layer)
        if k not in V:
            V[k] = b.bm.verts.new(W(us[i], zs[j], 0.0 if layer == 0 else -thick))
        return V[k]

    def quad(a, c, d, e):
        f = b.bm.faces.new((a, c, d, e))
        f[b.slot] = slot
        wall.append(f)

    for i in range(nu):
        for j in range(nz):
            if cell(i, j) != "solid":
                continue
            quad(gv(i, j, 0), gv(i + 1, j, 0), gv(i + 1, j + 1, 0), gv(i, j + 1, 0))
            quad(gv(i, j + 1, 1), gv(i + 1, j + 1, 1), gv(i + 1, j, 1), gv(i, j, 1))
            for di, dj, e0, e1 in ((-1, 0, (i, j), (i, j + 1)), (1, 0, (i + 1, j + 1), (i + 1, j)),
                                   (0, -1, (i + 1, j), (i, j)), (0, 1, (i, j + 1), (i + 1, j + 1))):
                nb = cell(i + di, j + dj)
                if nb in ("solid", "rise"):
                    continue
                if nb == "out":
                    if di == -1 and not cap_left:
                        continue
                    if di == 1 and not cap_right:
                        continue
                    if dj == 1 and not cap_top:
                        continue
                a0, a1 = gv(e0[0], e0[1], 0), gv(e1[0], e1[1], 0)
                b0, b1 = gv(e0[0], e0[1], 1), gv(e1[0], e1[1], 1)
                quad(a0, b0, b1, a1)

    for o in ops:
        if not o.get("arch"):
            continue
        uc, hw = o["u"], o["_hw"]
        zp, top = o["z"] + o["_pier"], o["z"] + o["h"]
        rise = top - zp
        prof = _arch_profile(o.get("style", "round"), hw, rise, steps, point=o.get("point", 0.2))
        left = [p for p in prof if p[0] <= 1e-9]
        if abs(left[-1][0]) > 1e-6:
            left.append((0.0, rise))
        iu0, iuc, iu1 = us.index(key(uc - hw)), us.index(key(uc)), us.index(key(uc + hw))
        jz0, jz1 = zs.index(key(zp)), zs.index(key(top))
        for side in (-1, 1):
            arc = [(uc - side * x, zp + zz) for x, zz in left[1:-1]]
            outer_i = iu0 if side < 0 else iu1
            front = [gv(outer_i, jz0, 0)] + [b.bm.verts.new(W(p[0], p[1], 0.0)) for p in arc] + \
                    [gv(iuc, jz1, 0), gv(outer_i, jz1, 0)]
            back = [gv(outer_i, jz0, 1)] + [b.bm.verts.new(W(p[0], p[1], -thick)) for p in arc] + \
                   [gv(iuc, jz1, 1), gv(outer_i, jz1, 1)]
            poly = [(us[outer_i], zs[jz0])] + arc + [(uc, top), (us[outer_i], top)]
            for i0, i1, i2 in _ear_clip(poly):
                wall.append(b.bm.faces.new((front[i0], front[i1], front[i2])))
                wall.append(b.bm.faces.new((back[i2], back[i1], back[i0])))
            m = len(front) - 1
            for k in range(m - 1):
                wall.append(b.bm.faces.new((front[k], back[k], back[k + 1], front[k + 1])))
        for f in wall:
            if f.is_valid:
                f[b.slot] = slot

    for o in ops:
        uc, z0, w, h = o["u"], o["z"], o["w"], o["h"]
        hw, pier = o["_hw"], o["_pier"]
        fill = o.get("fill", "glow")
        reveal = o.get("reveal", thick * 0.6)
        cont = _opening_contour(o, steps)
        fw = o.get("frame", 0.07)
        fo = o.get("frame_out", 0.04)
        door_like = z0 <= 1e-6
        if fw > 0.0:
            frame += _lband(bf, W, cont, fw, -0.01, fo, frame_slot, closed=not door_like)
        if o.get("sill"):
            frame += _lbox(bf, W, uc - hw - fw - 0.06, uc + hw + fw + 0.06,
                           z0 - 0.12, z0, -0.02, fo + 0.10, frame_slot)
        if fill == "none":
            continue
        if fill == "open":
            glow += _lprism(bglow, W, cont, -thick - 0.30, -thick - 0.26, glow_slot)
            continue
        if fill == "wood":
            trim += _lprism(btrim, W, cont, -reveal - 0.04, -reveal, trim_slot)
            continue
        glow += _lprism(bglow, W, cont, -reveal - 0.03, -reveal, glow_slot)
        if fill == "jali":
            # grila de piatra 3 x 4 in fata placii GLOW (brief §1.2: "fete
            # retrase cu grila de 3 x 4 gauri"): 2 montanti + 3 traverse,
            # sub nasterea arcului
            bt = 0.07
            dj0, dj1 = -reveal + 0.01, -reveal + 0.10
            for k in (1, 2):
                uu = uc - hw + w * k / 3.0
                frame += _lbox(bf, W, uu - bt * 0.5, uu + bt * 0.5, z0, z0 + pier,
                               dj0, dj1, frame_slot)
            for k in (1, 2, 3):
                zz = z0 + pier * k / 4.0
                frame += _lbox(bf, W, uc - hw, uc + hw, zz - bt * 0.5, zz + bt * 0.5,
                               dj0, dj1, frame_slot)
    return {"wall": wall, "frame": frame, "glow": glow, "trim": trim}


def facade_bays(b, bglow, btrim, p0, u, n, width, height, thick, openings, slot,
                glow_slot, trim_slot, pad=0.35, **kw):
    """`facade` pe un perete LUNG, spart in travee: golurile se grupeaza pe
    intervalele lor laterale (plus rama), iar peretele se taie la mijlocul
    spatiului dintre grupuri. Fiecare bucata e un `facade` propriu, cu
    capetele interioare deschise (cap_left/right=False, coplanare), deci
    coloanele unui gol nu mai taie tot peretele in felii."""
    ivs = sorted(((o["u"] - o["w"] * 0.5 - pad, o["u"] + o["w"] * 0.5 + pad) for o in openings))
    groups = []
    for a0, a1 in ivs:
        if groups and a0 <= groups[-1][1]:
            groups[-1][1] = max(groups[-1][1], a1)
        else:
            groups.append([a0, a1])
    cuts = [0.0]
    for g0, g1 in zip(groups, groups[1:]):
        c = (g0[1] + g1[0]) * 0.5
        if 0.05 < c < width - 0.05:
            cuts.append(c)
    cuts.append(width)
    U = Vector(u).normalized()
    out = {"wall": [], "frame": [], "glow": [], "trim": []}
    for k in range(len(cuts) - 1):
        s0, s1 = cuts[k], cuts[k + 1]
        ops = []
        for o in openings:
            if s0 <= o["u"] < s1:
                o2 = dict(o)
                o2["u"] = o["u"] - s0
                ops.append(o2)
        res = facade(b, bglow, btrim, Vector(p0) + U * s0, u, n, s1 - s0, height, thick,
                     ops, slot, glow_slot, trim_slot,
                     cap_left=(k == 0) and kw.get("cap_left", True),
                     cap_right=(k == len(cuts) - 2) and kw.get("cap_right", True),
                     cap_top=kw.get("cap_top", True), steps=kw.get("steps", 8),
                     frame_slot=kw.get("frame_slot"), bframe=kw.get("bframe"))
        for kk in out:
            out[kk] += res[kk]
    return out


def _kangura_outline(w, h):
    hw = w * 0.5
    return [(-hw, 0.0), (hw, 0.0), (hw, 0.52 * h), (0.43 * w, 0.70 * h),
            (0.30 * w, 0.83 * h), (0.14 * w, 0.93 * h), (0.0, h),
            (-0.14 * w, 0.93 * h), (-0.30 * w, 0.83 * h), (-0.43 * w, 0.70 * h),
            (-hw, 0.52 * h)]


def _kangura_on(b, W, uc, z, w, h, d0, d1, slot):
    """Merlon kangura pe o fata oarecare (cadrul local W): baza la z, centrat
    pe uc, grosimea de la d0 la d1 pe normala fetei."""
    return _lprism(b, W, [(uc + x, z + zz) for x, zz in _kangura_outline(w, h)],
                   d0, d1, slot)


def _oct_ring(cx, cy, apothem, z):
    """Octogon regulat cu o FATA spre +X (fata 0), varfurile la 22,5 + 45k."""
    r = apothem / math.cos(math.radians(22.5))
    return [(cx + r * math.cos(math.radians(22.5 + 45.0 * k)),
             cy + r * math.sin(math.radians(22.5 + 45.0 * k)), z) for k in range(8)]


def _oct_frustum(b, cx, cy, a0, a1, z0, z1, slot, cap_bottom=True, cap_top=True):
    """Trunchi de piramida octogonal (apotema a0 jos, a1 sus), fete plane --
    turnurile portilor sunt OCTOGONALE usor conice pe decupare, nu cilindri."""
    bm = b.bm
    lo = [bm.verts.new(p) for p in _oct_ring(cx, cy, a0, z0)]
    hi = [bm.verts.new(p) for p in _oct_ring(cx, cy, a1, z1)]
    faces = []
    if cap_bottom:
        faces.append(bm.faces.new(tuple(reversed(lo))))
    if cap_top:
        faces.append(bm.faces.new(tuple(hi)))
    for k in range(8):
        k2 = (k + 1) % 8
        faces.append(bm.faces.new((lo[k], lo[k2], hi[k2], hi[k])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _oct_facet_frame(cx, cy, apothem, k):
    """Cadrul local (u, z, d) al fetei k a octogonului: u spre dreapta vazut
    din afara, d pe normala exterioara, originea in centrul fetei, la z=0."""
    phi = math.radians(45.0 * k)
    n = (math.cos(phi), math.sin(phi), 0.0)
    u = (-math.sin(phi), math.cos(phi), 0.0)
    p0 = (cx + apothem * n[0], cy + apothem * n[1], 0.0)
    return _fx(p0, u, n)


# =============================================================================
# fort_wall_segment -- modul de zid inlantuibil
# =============================================================================
#
# ESCALADARE OPUS (runda 3; rundele 1-2 respinse: modulul singur, 12 x 14 m,
# citea ca o PLACA patrata cu o coroana de "dinti" rotunzi la 1,2 m).
#
# LISTA DE ELEMENTE (decuparea fort_wall_segment.png, citita inainte de
# primul vertex; vedere frontala, tronson de ~3 module intre doua turnuri):
#   1. Soclu ingust la baza, usor tesit (iese putin din fata zidului).
#   2. Corp de zid drept, plin, inalt -- rosturile de blocuri sunt TEXTURA
#      (brief regula 5), nu geometrie.
#   3. 2 fante de tragere inalte si inguste pe tronson, la ~65% din
#      inaltimea zidului -> aici 1 pe modul (3 pe tronsonul de 3 module; decuparea
#      are 2 -- abatere de +1 asumata: un modul inlantuibil nu poate avea
#      "o fanta la 1,5 module").
#   4. Un brau subtire, usor iesit, la baza crenelurilor (linia de umbra
#      de sub merloane).
#   5. Merloane "kangura" (dreptunghi + umeri rotunjiti + varf), cu un punct
#      intunecat in mijloc: 14 pe tronsonul de ~3 module -> 5 pe modul, pas
#      2,4 m, ~1,95 x 2,5 m, cu goluri inguste intre ele. NU "~1 la 1,2 m"
#      (cifra rundei 2, contrazisa de decupare). Brief-ul scrie "creneluri
#      dreptunghiulare" -- decuparea arata kangura; forma vine din planse
#      (§0.1), deci kangura.
#   6. Pe spate: drum de straja la cota brâului si un parapet interior jos
#      (silueta din spate si din capat, nevazut pe decupare).
#   Capete PLANE la y = +-6 (inlantuire cap la cap / langa turn): merloanele
#   la y = 0, +-2,4, +-4,8, deci golul de la capat e jumatate din golul
#   dintre merloane si ritmul continua peste rost.
#   Ce iese din contur: doar merloanele.
#
# Lungimea pe Y, fata principala (fante, merloane) spre +X.
WS_LEN = 12.0
WS_THICK = 3.0
WS_H = 14.0
WS_MERLONS = 5
WS_MERLON_W = 1.95
WS_MERLON_H = 2.5
WS_MERLON_T = 0.7


def build_fort_wall_segment():
    b = Builder()
    bg = Builder()
    hl = WS_LEN * 0.5
    ht = WS_THICK * 0.5

    # 1. soclu tesit: profil in X-Z extrudat pe toata lungimea (capete plane)
    plinth = [(-ht - 0.30, 0.0), (ht + 0.30, 0.0), (ht + 0.30, 0.35),
              (ht + 0.05, 0.9), (-ht - 0.05, 0.9), (-ht - 0.30, 0.35)]
    bm = b.bm
    fa = [bm.verts.new((x, -hl, z)) for x, z in plinth]
    fb = [bm.verts.new((x, hl, z)) for x, z in plinth]
    bm.faces.new(tuple(fa))
    bm.faces.new(tuple(reversed(fb)))
    for i in range(len(plinth)):
        j = (i + 1) % len(plinth)
        bm.faces.new((fa[i], fb[i], fb[j], fa[j]))
    for f in bm.faces:
        f[b.slot] = STONE

    # 2. corpul zidului
    walk_z = WS_H - WS_MERLON_H - 0.45     # drumul de straja / baza braului
    b.box((0.0, 0.0, (0.9 + walk_z) * 0.5), (WS_THICK, WS_LEN, walk_z - 0.9), STONE)

    # 3. fanta de tragere: una pe modul, la mijloc, flush + inchisa (lectia
    # val 2a: relieful de piatra nu se citeste ca fanta, culoarea da)
    # decupare: fanta ~1 x 3 m la ~65% din inaltimea zidului (masurat in px
    # pe tronson); aici 0,6 x 2,4 (1 pe modul, nu 2 pe 3 module)
    slit_z = walk_z * 0.62
    bg.box((ht + 0.01, 0.0, slit_z), (0.04, 0.6, 2.4), GLOW)

    # 4. brau la baza merloanelor, iesit 0,15 m in fata
    b.box((0.15, 0.0, walk_z + 0.225), (WS_THICK + 0.3, WS_LEN, 0.45), STONE)
    merlon_z = walk_z + 0.45

    # 5. merloane kangura pe muchia din fata, cu punct intunecat
    pitch = WS_LEN / WS_MERLONS
    mx = ht - WS_MERLON_T * 0.5
    for i in range(WS_MERLONS):
        y = -hl + pitch * (i + 0.5)
        kangura_merlon(b, (mx, y, merlon_z), WS_MERLON_W, WS_MERLON_H, WS_MERLON_T,
                       STONE, facing="X")
        bg.box((ht + 0.01, y, merlon_z + WS_MERLON_H * 0.46), (0.04, 0.3, 0.3), GLOW)

    # 6. parapet interior jos, pe muchia din spate
    b.box((-ht + 0.2, 0.0, merlon_z + 0.5), (0.4, WS_LEN, 1.0), STONE)

    densify_for_ao(b, max_len=3.0)
    stone_obj = b.to_object("Wall_Stone")
    glow_obj = _finish_or_none(bg.to_object("Wall_Glow"))
    return stone_obj, glow_obj


# =============================================================================
# fort_wall_turret -- turnul de la capatul tronsonului
# =============================================================================
#
# Contract (brief §1.2): 4,5 x 4,5 m, 17 m inalt -- piesa NOUA, desprinsa din
# fort_wall_segment (nu are decupare proprie; se compara cu turnurile de capat
# din fort_wall_segment.png, in preview-ul "chain").
#
# REVIZUIRE runda fort3 (verdictul liderului: "inca ingust fata de turnurile
# late din decupare; fantele nu se vad din unghiul camerei"):
#   - LATIME: masurat pe decupare, turnul de capat are 160 px, iar zidul
#     325 px inaltime pentru 14 m => ~6,9 m, nu 4,5. Brief-ul scrisese 4,5
#     fara sa masoare; turnul are acum 6,8 x 6,8 m (colturi tesite 1,1 m).
#     Abatere de la cota brief-ului, motivata de decupare (§0.1: plansa e
#     sursa de forma); piesa e decor, fara contract de cod.
#   - FANTELE erau INGROPATE: cutia de 3 cm statea la x = hs - 0,03, adica
#     in intregime SUB fata de la x = hs -- geometrie corecta in bbox, dar
#     invizibila din orice unghi. Acum ies 4 cm din fata (ca la porti).
#   - soclu mai inalt (1,4 m, tesit), ca pe decupare.
#
# Lista de elemente, de jos in sus:
#   1. Soclu tesit la baza, mai lat.
#   2. Corp patrat cu colturile TESITE (octogon neregulat), fata lata spre +X.
#   3. O fanta VERTICALA ingusta pe fiecare fata mare (+X, -X, +-Y), in treimea
#      de sus a corpului (pe decupare, 1 pe fata vizibila).
#   4. Brau subtire sub coronament.
#   5. Merloni KANGURA, stilul zidului (3 pe fata mare, 1 pe tesitura).
WT_SIDE = 6.8
WT_H = 17.0
WT_CHAMFER = 1.1


def _octagon_outline(hs, chamfer):
    """Conturul (x, y) al unui patrat de semi-latura `hs` cu colturile taiate
    cu `chamfer` -- 8 laturi, fetele principale raman late WT_SIDE, colturile
    citesc ca fatete, nu ca muchii ascutite (silueta mai lata pe decupare)."""
    c = chamfer
    return [(-hs + c, -hs), (hs - c, -hs), (hs, -hs + c), (hs, hs - c),
            (hs - c, hs), (-hs + c, hs), (-hs, hs - c), (-hs, -hs + c)]


def _octagon_prism(b, outline, z0, z1, slot):
    bm = b.bm
    fa = [bm.verts.new((x, y, z0)) for x, y in outline]
    fb = [bm.verts.new((x, y, z1)) for x, y in outline]
    n = len(outline)
    faces = [bm.faces.new(tuple(reversed(fa))), bm.faces.new(tuple(fb))]
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((fa[i], fb[i], fb[j], fa[j])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _kangura_merlon_rotated(b, center, w, h, t, slot, angle):
    """Ca `kangura_merlon` (acelasi contur: dreptunghi + umeri rotunjiti +
    varf ascutit), dar orientat cu `angle` (radiani, in jurul lui Z) in loc
    de axis-aligned X/Y -- necesar pe fetele oblice ale unui octogon (colturi
    taiate la 45 de grade), unde `kangura_merlon` (fara parametru `rotation`)
    nu se poate alinia. `center` = mijlocul BAZEI, `w` de-a lungul directiei
    `angle`, grosimea `t` perpendicular pe ea."""
    cx, cy, cz = center
    hw = w * 0.5
    outline = [(-hw, 0.0), (hw, 0.0), (hw, 0.52 * h), (0.43 * w, 0.70 * h),
               (0.30 * w, 0.83 * h), (0.14 * w, 0.93 * h), (0.0, h),
               (-0.14 * w, 0.93 * h), (-0.30 * w, 0.83 * h), (-0.43 * w, 0.70 * h),
               (-hw, 0.52 * h)]
    along = (math.cos(angle), math.sin(angle))
    perp = (math.cos(angle + math.radians(90.0)), math.sin(angle + math.radians(90.0)))
    bm = b.bm
    fa, fb = [], []
    for u, z in outline:
        fa.append(bm.verts.new((cx + along[0] * u - perp[0] * t * 0.5,
                                cy + along[1] * u - perp[1] * t * 0.5, cz + z)))
        fb.append(bm.verts.new((cx + along[0] * u + perp[0] * t * 0.5,
                                cy + along[1] * u + perp[1] * t * 0.5, cz + z)))
    n = len(outline)
    faces = [bm.faces.new(tuple(fa)), bm.faces.new(tuple(reversed(fb)))]
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((fa[i], fb[i], fb[j], fa[j])))
    for f in faces:
        f[b.slot] = slot
    return faces


def build_fort_wall_turret():
    b = Builder()
    bg = Builder()
    faces = []
    hs = WT_SIDE * 0.5

    plinth_h = 1.4
    faces += _octagon_prism(b, _octagon_outline(hs + 0.35, WT_CHAMFER + 0.15), 0.0,
                            plinth_h - 0.35, STONE)
    faces += _octagon_prism(b, _octagon_outline(hs + 0.18, WT_CHAMFER + 0.07),
                            plinth_h - 0.35, plinth_h, STONE)

    body_outline = _octagon_outline(hs, WT_CHAMFER)
    wall_top_z = WT_H - WS_MERLON_H - 0.42
    faces += _octagon_prism(b, body_outline, plinth_h, wall_top_z, STONE)

    # 3. fantele: cutii INCHISE care ies 4 cm din fata (nu ingropate)
    slit_z = plinth_h + (wall_top_z - plinth_h) * 0.66
    for nx, ny in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        W = _fx((nx * hs, ny * hs, 0.0), (-ny, nx, 0.0), (nx, ny, 0.0))
        _lbox(bg, W, -0.2, 0.2, slit_z - 1.0, slit_z + 1.0, -0.08, 0.04, GLOW)

    # 4. brau sub coronament, apoi parapetul plin pe care stau merlonii
    faces += _octagon_prism(b, _octagon_outline(hs + 0.12, WT_CHAMFER + 0.05),
                            wall_top_z, wall_top_z + 0.3, STONE)
    crenel_z = wall_top_z + 0.3
    faces += _octagon_prism(b, body_outline, crenel_z, crenel_z + 0.12, STONE)
    crenel_z += 0.12

    # 5. merloni kangura pe conturul octogonului, cu punct intunecat pe fata
    sides = list(zip(body_outline, body_outline[1:] + body_outline[:1]))
    for (x0, y0), (x1, y1) in sides:
        seg_len = math.hypot(x1 - x0, y1 - y0)
        n_m = max(int(round(seg_len / 1.5)), 1)
        pitch = seg_len / n_m
        ang = math.atan2(y1 - y0, x1 - x0)
        ux, uy = (x1 - x0) / seg_len, (y1 - y0) / seg_len
        nx, ny = uy, -ux                       # normala exterioara (contur CCW)
        for i in range(n_m):
            t = (i + 0.5) / n_m
            mx = x0 + (x1 - x0) * t - nx * WS_MERLON_T * 0.5
            my = y0 + (y1 - y0) * t - ny * WS_MERLON_T * 0.5
            faces += _kangura_merlon_rotated(b, (mx, my, crenel_z), pitch * 0.84,
                                             WS_MERLON_H, WS_MERLON_T, STONE, ang)
            W = _fx((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, 0.0), (ux, uy, 0.0), (nx, ny, 0.0))
            _lbox(bg, W, -0.15, 0.15, crenel_z + WS_MERLON_H * 0.40,
                  crenel_z + WS_MERLON_H * 0.40 + 0.3, -0.02, 0.03, GLOW)

    stone_obj = b.to_object("Turret_Stone")
    for f in faces:
        if f.is_valid:
            f[b.slot] = STONE
    glow_obj = _finish_or_none(bg.to_object("Turret_Glow"))
    return stone_obj, glow_obj


# =============================================================================
# fort_bastion -- burjul rotund
# =============================================================================
#
# Contract (brief §1.2): Ø18 m baza, Ø16 m sus, 13 m inalt, h/l 0,66, segments 24.
# Lista de elemente (dupa Read fort_bastion.png), de jos in sus:
#
#   1. Baza usor evazata (teasa), aproape cilindrica.
#   2. Corp tronconic (frustum), usor mai ingust sus decat jos -- asize
#      orizontale (textura).
#   3. Un rand de guri de tragere mici, dreptunghiulare, pe circumferinta,
#      sub cornisa (numarate pe decupare: ~8-10).
#   4. Un brau/cornisa in consola aproape de varf.
#   5. Creneluri ROTUNJITE la varf (crestate DIFERIT de ziduri -- capete
#      semicilindrice, nu drepte), dese pe tot cercul.
BA_R_BOTTOM = 9.0
BA_R_TOP = 8.0
BA_H = 13.0
BA_SEG = 24


def build_fort_bastion():
    b = Builder()
    faces = []

    plinth_h = 0.8
    faces += list(b.frustum((0.0, 0.0, plinth_h * 0.5), BA_R_BOTTOM + 0.4, BA_R_BOTTOM + 0.05,
                            plinth_h, STONE, segments=BA_SEG, axis="Z"))

    body_h = BA_H - plinth_h - 1.4
    faces += list(b.frustum((0.0, 0.0, plinth_h + body_h * 0.5), BA_R_BOTTOM, BA_R_TOP,
                            body_h, STONE, segments=BA_SEG, axis="Z"))
    body_top_z = plinth_h + body_h
    # raza la inaltimea gurilor de tragere (interpolare liniara pe frustum)
    t_slit = 0.60
    r_slit = BA_R_BOTTOM + (BA_R_TOP - BA_R_BOTTOM) * t_slit
    slit_z = plinth_h + body_h * t_slit

    # 2 RANDURI de guri de tragere clar vizibile -- REVIZUIRE runda 2
    # (critica: "add 2 rows of CLEARLY visible dark arrow slits"). Flush cu
    # suprafata (nu r_slit+0,05, care iesea in AFARA razei reale la acea
    # inaltime -- relief bump) SI colorate STUD (VOLCANIC_BLACK).
    n_slits = 10
    for row_t2 in (0.45, 0.72):
        r_row = BA_R_BOTTOM + (BA_R_TOP - BA_R_BOTTOM) * row_t2
        z_row = plinth_h + body_h * row_t2
        for i in range(n_slits):
            a = 2.0 * math.pi * (i + 0.5) / n_slits
            sx, sy = math.cos(a) * (r_row - 0.06), math.sin(a) * (r_row - 0.06)
            rot = Matrix.Rotation(a, 3, "Z") @ Matrix.Rotation(math.radians(90.0), 3, "X")
            faces += list(b.box((sx, sy, z_row), (0.05, 0.7, 1.0), STUD, rotation=rot))

    # brau/cornisa aproape de varf
    faces += list(balcony_band(b, (0.0, 0.0, body_top_z), BA_R_TOP - 0.35, BA_R_TOP + 0.20,
                               0.28, STONE, segments=BA_SEG))
    parapet_base_z = body_top_z + 0.28
    parapet_h = BA_H - parapet_base_z - 0.55
    faces += list(b.frustum((0.0, 0.0, parapet_base_z + parapet_h * 0.5),
                            BA_R_TOP - 0.15, BA_R_TOP - 0.25, parapet_h, STONE,
                            segments=BA_SEG, axis="Z"))
    crenel_z = parapet_base_z + parapet_h

    # creneluri ROTUNJITE (distincte de zid: crenel_merlon style="rounded"),
    # CONTINUE -- REVIZUIRE runda 2 (critica: "a continuous ring of rounded
    # merlons (~24 around)"). Numarul crescut la ~24, latimea calculata sa
    # aproape atinga vecinii (continuu, nu spatiati).
    n_merlon = 24
    circumference = 2.0 * math.pi * (BA_R_TOP - 0.5)
    merlon_w = (circumference / n_merlon) * 0.98
    for i in range(n_merlon):
        a = 2.0 * math.pi * (i + 0.5) / n_merlon
        gx, gy = math.cos(a) * (BA_R_TOP - 0.5), math.sin(a) * (BA_R_TOP - 0.5)
        rot = Matrix.Rotation(a, 3, "Z")
        faces += list(crenel_merlon(b, (gx, gy, crenel_z + 0.6), 1.2, STONE,
                                    width=merlon_w, depth=0.65, style="rounded", rotation=rot))

    stone_obj = b.to_object("Bastion_Stone")
    for f in faces:
        if f.is_valid:
            f[b.slot] = STONE
    return stone_obj


# =============================================================================
# fort_gate_jai / fateh / loha -- portile cetatii (runda fort3, rescrise)
# =============================================================================
#
# VERDICTUL LIDERULUI pe fort2 (plansa jodhpur_fidelity_fort2.png): turnuri
# CILINDRICE netede in loc de octogonale, fante ORIZONTALE, merloni ca niste
# bule, turnuri disproportionat de mari si SUPRAPUSE peste poarta, canaturi
# care abia se vad. Refacute de la zero dupa decupari, masurate in pixeli pe
# jodhpur_assets_v1/fort_gate_*.png (x3, 1500 px latime):
#
# LISTA DE ELEMENTE (comuna; diferentele mai jos), stanga -> dreapta:
#   1. DOUA turnuri OCTOGONALE (o fata spre camera, 3 fete vizibile), usor
#      conice (325 px la baza, ~300 sus). Fiecare, de jos in sus:
#      a. soclu octogonal mai lat, 18% din inaltime, cu muchia de sus TESITA;
#      b. corp conic, cu un brau subtire la ~45% si UN rand de fante
#         VERTICALE inguste (~0,35 x 1,9 m), una pe fiecare fata (3 vizibile),
#         la ~54% din inaltime;
#      c. cornisa in consola (dedesubt inclinat), apoi parapet octogonal
#         putin mai lat decat corpul;
#      d. coroana de merloni KANGURA (umeri rotunjiti + varf), 2 pe fata,
#         cu un punct intunecat.
#   2. Zid-cortina intre turnuri (52% din latime intre muchiile turnurilor),
#      PLAN, cu turnurile NEsuprapuse peste arc.
#   3. In mijloc, un cadru dreptunghiular in relief (pishtaq: doi pilastri +
#      buiandrug) pana sub brau, iar in el ARCUL: ascutit turtit (nasterea la
#      ~78% din cheie), gol strapuns prin toata grosimea, cu arhivolta.
#   4. Nise arcuite INTUNECATE mici pe zidul dintre cadru si turn:
#      Jai/Loha una pe fiecare parte (la ~2/3 din inaltime); Fateh DOUA pe
#      fiecare parte, suprapuse, fiecare intr-un panou cu rama.
#   5. Brau iesit la coronament, apoi merloni kangura pe toata cortina
#      (11 pe Jai/Loha; 12 pe Fateh, 6 + 6 de o parte si de alta a
#      chhatri-ului), cu punct intunecat.
#   6. Canaturi de lemn (Loha: fier) cu tinte, 3 x 5, pe 5 benzi de fier,
#      deschise spre interior, vizibile in gura arcului.
#   7. DOAR Fateh: chhatri cu cupola centrat deasupra arcului, pe un soclu,
#      iesind peste linia merlonilor.
#
# COTE. Contractul (brief §1.2) e golul LIBER 7,0 m pana la 2,0 m cu
# canaturile deschise si cheia >= 9 m (masurata >= 9,15 in fort2 -- nu are voie
# sa regreseze). Pe decupare arcul de piatra e 390 px din 1305 (30%) si are
# canaturile IN el: golul liber de 7 m e ce ramane intre canaturi, nu arcul.
# Arcul de piatra: 9,4 m. Scara orizontala 9,4/390 = 0,0241 m/px => turn 7,8 m
# (apotema 3,9), cortina vizibila 16,3 m, latime totala ~32 m. Scara
# verticala din cheie (9,4 m / 345 px) = 0,0272 m/px => Jai 16,3 m (brief 16).
# Abatere: latimea totala iese ~32 m, nu "~26": la 26 m arcul ar fi 7,7 m
# cu cheia 9,4 (raport 1,22 fata de 0,92 pe decupare) -- adica exact
# "turnuri prea mari fata de poarta" din verdict. Cotele de contract (gol,
# cheie) sunt cele de mai sus; latimea nu e cota de cod.
#
# Canaturile: balamaua la |y| = 4,6 (in arcul de 9,4), canat 4,55 m, deschis
# 78 grade spre interior (cat de putin deschis se poate, ca fata cu tinte sa
# se vada din fata). Extrema spre ax: 4,6 - 4,55 cos 78 - 0,17 sin 78 ~ 3,49
# pe coltul tintei de sus; MASURAT cu measure_opening pe GLB: gol liber
# 7,156 m > 7,0 (la 80 grade: 7,456). Canatul se intinde 4,45 m in adancime
# -- de aici grosimea cortinei (5,05 m, un corp de poarta, nu un zid subtire).
GATE_GAP_W = 7.0          # contract: gol LIBER pana la 2,0 m, cu canaturile
GATE_KEY_MIN = 9.0        # contract (masurat >= 9,15 in fort2)
GATE_ARCH_W = 9.4         # arcul de piatra, cu canaturile in el
GATE_ARCH_H = 9.45        # cheia geometrica; masurata pe fereastra 0,3 => ~9,40
GATE_ARCH_PIER = 6.9      # nasterea arcului (~75% din cheie, ca pe decupare)
GATE_FRAME_W = 10.5       # cadrul pishtaq (435 px / 390 px x arcul)
GATE_SIDE = 2.9           # zidul vizibil intre cadru si turn (120 px)
GATE_WALL_T = 5.05        # corpul portii (canatul deschis sta in el)
GATE_XF = 1.3             # fata cortinei; turnurile ies 2,6 m in fata ei
DOOR_ANGLE = 78.0

GATE_VARIANTS = {
    # tower: inaltimea totala a turnului; plinth/cornice/parapet/merlon h;
    # wall_top: coronamentul cortinei (sub brau); band; cmerlon: merlonii
    # cortinei; niches: 1 sau 2 pe fiecare parte
    "jai":   dict(tower=16.3, plinth=3.0, cornice=0.55, parapet=1.35, merlon=1.8,
                  wall_top=11.0, band=0.4, cmerlon=1.9, niches=1, a0=3.9, a1=3.72),
    "fateh": dict(tower=15.2, plinth=2.8, cornice=0.5, parapet=1.3, merlon=1.75,
                  wall_top=11.0, band=0.4, cmerlon=1.8, niches=2, a0=3.9, a1=3.72),
    "loha":  dict(tower=14.2, plinth=2.5, cornice=0.45, parapet=1.2, merlon=1.5,
                  wall_top=10.4, band=0.3, cmerlon=1.45, niches=1, a0=3.9, a1=3.72),
}


def _gate_tower(b, bg, cx, cy, v):
    """Turnul octogonal conic (elementul 1 din lista)."""
    a0, a1 = v["a0"], v["a1"]
    ph = v["plinth"]
    crown = v["cornice"] + v["parapet"] + v["merlon"]
    zt = v["tower"] - crown                      # varful corpului
    # a. soclu mai lat, cu tesitura sus
    _oct_frustum(b, cx, cy, a0 + 0.42, a0 + 0.42, 0.0, ph - 0.42, STONE, cap_top=False)
    _oct_frustum(b, cx, cy, a0 + 0.42, a0, ph - 0.42, ph, STONE, cap_bottom=False)
    # b. corp conic
    _oct_frustum(b, cx, cy, a0, a1, ph, zt, STONE, cap_bottom=False, cap_top=False)

    def ap(z):
        return a0 + (a1 - a0) * (z - ph) / (zt - ph)
    zb = ph + (zt - ph) * 0.40
    _oct_frustum(b, cx, cy, ap(zb) + 0.09, ap(zb) + 0.09, zb, zb + 0.22, STONE)
    zs = ph + (zt - ph) * 0.62
    for k in range(8):
        W = _oct_facet_frame(cx, cy, ap(zs), k)
        _lbox(bg, W, -0.17, 0.17, zs - 0.95, zs + 0.95, -0.08, 0.05, GLOW)
    # c. cornisa in consola (dedesubt inclinat) + parapet
    zc = zt + v["cornice"] * 0.65
    _oct_frustum(b, cx, cy, a1, a1 + 0.42, zt, zc, STONE, cap_bottom=False, cap_top=False)
    _oct_frustum(b, cx, cy, a1 + 0.42, a1 + 0.42, zc, zt + v["cornice"], STONE, cap_bottom=False)
    zp = zt + v["cornice"]
    ap_par = a1 + 0.30
    _oct_frustum(b, cx, cy, ap_par, ap_par, zp, zp + v["parapet"], STONE, cap_bottom=False)
    # d. merloni kangura, 2 pe fata
    zm = zp + v["parapet"]
    side = 2.0 * ap_par * math.tan(math.radians(22.5))
    mw = side * 0.5 * 0.88
    for k in range(8):
        W = _oct_facet_frame(cx, cy, ap_par, k)
        for uc in (-side * 0.25, side * 0.25):
            _kangura_on(b, W, uc, zm, mw, v["merlon"], -0.5, 0.0, STONE)
            _lbox(bg, W, uc - 0.13, uc + 0.13, zm + v["merlon"] * 0.34,
                  zm + v["merlon"] * 0.34 + 0.26, -0.03, 0.03, GLOW)


def _gate_doors(b, xh, yh, leaf_l, leaf_h, theta_deg, slot, iron_slot):
    """Doua canaturi deschise spre interior cu `theta_deg` fata de pozitia
    inchisa, balamaua in (xh, +-yh). Fata EXTERIOARA a canatului (cea cu
    benzile si tintele, spre +X cand e inchis) priveste, deschis, spre axul
    portii si spre camera. 5 benzi de fier x 3 tinte = 3 x 5 (brief)."""
    th = math.radians(theta_deg)
    t = 0.16
    faces = []
    for s in (-1.0, 1.0):
        R = Matrix.Rotation(-s * th, 3, "Z")
        hinge = Vector((xh, s * yh, 0.0))
        d = Vector((-math.sin(th), -s * math.cos(th), 0.0))
        outer = R @ Vector((1.0, 0.0, 0.0))
        c = hinge + d * (leaf_l * 0.5)
        faces += list(b.box((c.x, c.y, 0.05 + leaf_h * 0.5), (t, leaf_l, leaf_h), slot,
                            rotation=R))
        # Randurile de tinte NU trec prin centrul canatului: dupa bevel,
        # `finish` reatribuie slotul fiecarei fete dupa fata ORIGINALA cea mai
        # apropiata de centrul ei -- cu banda din mijloc exact peste centrul
        # fetei mari (coplanara cu ea), toata fata canatului lua slotul de
        # fier (masurat: o fata mare pe STUD pe fiecare canat, canatul negru).
        for iz in range(5):
            zc = 0.05 + leaf_h * ((iz + 0.5) / 5.0 + 0.06)
            sc = c + outer * (t * 0.5 + 0.015)
            faces += list(b.box((sc.x, sc.y, zc), (0.03, leaf_l * 0.94, 0.13), iron_slot,
                                rotation=R))
            for off in (-leaf_l * 0.32, 0.0, leaf_l * 0.32):
                p = c + d * off + outer * (t * 0.5 + 0.07)
                faces += list(b.box((p.x, p.y, zc), (0.09, 0.15, 0.15), iron_slot,
                                    rotation=R))
    return faces


def _build_gate(kind, door_slot, name_prefix):
    v = GATE_VARIANTS[kind]
    b = Builder()        # *_Stone
    bg = Builder()       # *_Glow: fante, nise, punctele merlonilor
    bd = Builder()       # *_Doors
    ty = GATE_FRAME_W * 0.5 + GATE_SIDE + v["a0"]    # axul turnurilor pe Y
    for s in (-1.0, 1.0):
        _gate_tower(b, bg, 0.0, s * ty, v)

    # 2-4. cortina: UN perete-grila de la axul unui turn la celalalt (capetele
    # intra in turnuri), cu gura portii strapunsa si nisele retrase
    xf, T = GATE_XF, GATE_WALL_T
    W = _fx((xf, -ty, 0.0), (0.0, 1.0, 0.0), (1.0, 0.0, 0.0))
    wall_top = v["wall_top"]
    niche_u = GATE_FRAME_W * 0.5 + GATE_SIDE * 0.5
    ops = [dict(u=ty, z=0.0, w=GATE_ARCH_W, h=GATE_ARCH_H, arch=True, style="pointed",
                pier=GATE_ARCH_PIER, point=0.85, fill="none", frame=0.38, frame_out=0.16)]
    if v["niches"] == 1:
        nz = [(5.7, 1.9)]
    else:
        nz = [(1.6, 1.9), (5.6, 1.9)]
    for s in (-1.0, 1.0):
        for z0, h in nz:
            ops.append(dict(u=ty + s * niche_u, z=z0, w=0.72, h=h, arch=True,
                            style="pointed", pier=h - 0.5, fill="glow", reveal=0.35,
                            frame=0.09, frame_out=0.06, sill=True))
    facade(b, bg, bg, (xf, -ty, 0.0), (0.0, 1.0, 0.0), (1.0, 0.0, 0.0), 2.0 * ty,
           wall_top, T, ops, STONE, GLOW, GLOW, steps=10)
    # 3. cadrul pishtaq in relief
    fh = GATE_FRAME_W * 0.5
    for s in (-1.0, 1.0):
        u0 = ty + s * fh
        _lbox(b, W, min(u0, u0 - s * 0.5), max(u0, u0 - s * 0.5), 0.0, wall_top, -0.01, 0.26, STONE)
    _lbox(b, W, ty - fh, ty + fh, wall_top - 0.5, wall_top, -0.01, 0.26, STONE)
    # Fateh: panou cu rama in jurul fiecarei nise
    if v["niches"] == 2:
        for s in (-1.0, 1.0):
            for z0, h in nz:
                uc = ty + s * niche_u
                rect = [(uc - 0.75, z0 - 0.45), (uc - 0.75, z0 + h + 0.4),
                        (uc + 0.75, z0 + h + 0.4), (uc + 0.75, z0 - 0.45)]
                _lband(b, W, rect, 0.12, -0.01, 0.10, STONE, closed=True, outward=False)
    # 5. brau (placa de acoperis pe toata adancimea, iesita 0,25 in fata)
    span = fh + GATE_SIDE + 0.6
    _lbox(b, W, ty - span, ty + span, wall_top, wall_top + v["band"], -T, 0.25, STONE)
    zm = wall_top + v["band"]
    # parapet jos pe muchia din spate (silueta din spatele portii)
    _lbox(b, W, ty - span, ty + span, zm, zm + 1.0, -T, -T + 0.45, STONE)
    ms = fh + GATE_SIDE - 0.15
    n_m = 11 if kind != "fateh" else 13
    pitch = 2.0 * ms / n_m
    for i in range(n_m):
        uc = ty - ms + pitch * (i + 0.5)
        if kind == "fateh" and abs(uc - ty) < 1.2:
            continue
        mw = pitch * 0.80
        _kangura_on(b, W, uc, zm, mw, v["cmerlon"], -0.55, 0.12, STONE)
        _lbox(bg, W, uc - 0.12, uc + 0.12, zm + v["cmerlon"] * 0.34,
              zm + v["cmerlon"] * 0.34 + 0.24, 0.10, 0.15, GLOW)
    # 7. Fateh: chhatri pe soclu, centrat pe cheia arcului
    if kind == "fateh":
        _lbox(b, W, ty - 1.75, ty + 1.75, zm, zm + 0.6, -2.9, 0.15, STONE)
        chhatri(b, b, (xf - 1.35, 0.0, zm + 0.6), 6, 1.35, 1.75, STONE, STONE,
                col_r=0.14, dome_radius=1.05, arch_style="round", chajja_out=0.35,
                segments_dome=12)

    # 6. canaturile
    _gate_doors(bd, xf - 0.45, GATE_ARCH_W * 0.5 - 0.1, 4.55, GATE_ARCH_PIER - 0.15,
                DOOR_ANGLE, door_slot, STUD)

    densify_for_ao(b, max_len=2.5)
    stone_obj = b.to_object(name_prefix + "_Stone")
    doors_obj = _finish_or_none(bd.to_object(name_prefix + "_Doors"))
    glow_obj = _finish_or_none(bg.to_object(name_prefix + "_Glow"))
    return stone_obj, doors_obj, glow_obj


# --- emit ------------------------------------------------------------------

clear_built()
results = []


def emit(objs, path, ao, origin="base", bevel=0.03, smooth_angle=45.0,
         budget=None, allow_car_slots=None, bevel_angle=30.0):
    """Identic cu `emit` din build_jodhpur_pilot.py: offsetul de origine se
    calculeaza O DATA pe ansamblu si se aplica identic tuturor nodurilor."""
    objs = [o for o in objs if o is not None]
    solo = len(objs) == 1
    place = Vector((0.0, 0.0, 0.0))
    if not solo:
        xs, ys, zs = [], [], []
        for o in objs:
            for v in o.data.vertices:
                xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
        place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5,
                        -min(zs)))
    total_tris = 0
    ao_lo, ao_hi = 1.0, 0.0
    for o in objs:
        # `ao` poate fi un dict {sufix_nume: parametri} (runda fort3):
        # canaturile portii, cu AO-ul pietrei (gradient vertical + tinte),
        # ieseau la AO mediu 0,40 -- aproape negre in gura arcului.
        o_ao = ao
        if isinstance(ao, dict) and "samples" not in ao:
            o_ao = next((v for k, v in ao.items() if o.name.endswith(k)), ao.get("*"))
        st = finish(o, bevel=bevel, bevel_angle=bevel_angle, ao=o_ao,
                    origin=(origin if solo else None), smooth_angle=smooth_angle)
        if not solo:
            for v in o.data.vertices:
                v.co += place
        total_tris += st["tris"]
        ao_lo = min(ao_lo, st["ao_min"])
        ao_hi = max(ao_hi, st["ao_max"])
    _, sz = export_glb(objs, "jodhpur/" + path)
    results.append((path, total_tris, sz / 1024.0, ao_lo, ao_hi, budget))
    return total_tris


# fort_wall_segment
wall_stone, wall_glow = build_fort_wall_segment()
emit([wall_stone, wall_glow], "structures/fort_wall_segment.glb", AO_STONE,
     origin="assembly", bevel=0.03, budget=3000)

# fort_wall_turret -- acum 2 noduri (Turret_Stone, Turret_Glow) ca zidul,
# origine COMUNA (fantele Turret_Glow nu ating solul separat).
turret_stone, turret_glow = build_fort_wall_turret()
emit([turret_stone, turret_glow], "structures/fort_wall_turret.glb", AO_STONE,
     origin="assembly", bevel=0.03, budget=5500)

# fort_bastion
bastion_stone = build_fort_bastion()
emit([bastion_stone], "structures/fort_bastion.glb", AO_STONE, bevel=0.03, budget=9000)

# fort_gate_jai / fateh / loha -- 3 noduri (*_Stone, *_Doors, *_Glow), origine
# COMUNA pe ansamblu, apoi re-centrata pe axul golului (y = 0 prin simetrie).
for kind, slot_d, pref, path in (("jai", DOOR_WOOD, "GateJai", "fort_gate_jai"),
                                 ("fateh", DOOR_WOOD, "GateFateh", "fort_gate_fateh"),
                                 ("loha", DOOR_IRON, "GateLoha", "fort_gate_loha")):
    g_stone, g_doors, g_glow = _build_gate(kind, slot_d, pref)
    emit([g_stone, g_doors, g_glow], "structures/%s.glb" % path,
         {"_Doors": AO_DOOR, "*": AO_STONE},
         origin="assembly", bevel=0.03, budget=None)
    for o in (g_stone, g_doors, g_glow):
        if o is not None:
            me = o.data
            bpy.data.objects.remove(o, do_unlink=True)
            bpy.data.meshes.remove(me)


# =============================================================================
# palace_facade_a / b (runda fort3, rescrise pe perete-grila)
# =============================================================================
#
# Verdictul liderului pe fort2: A "aproape goala: o cutie joasa cu cateva
# nise si un bloc central"; B "ferestre mici si rare fata de decupare".
# Cauza comuna: golurile erau `arch_opening` cu panou propriu, lipite pe o
# cutie plina, iar ritmul fatadei (brauri, pilastri, rame, balcoane) lipsea.
# Acum: peretele din fata e `facade_bays` (grila cu goluri retrase), ritmul
# vine din brauri/cornise pe toata lungimea, iar fiecare element al listei
# are pozitia MASURATA pe decupare (x3, px -> m, scara din lungimea brief-ului).


def _oct_pavilion(b, bg, cx, cy, a, z0, h, arch_w, dome_r, chajja_out=0.4):
    """Pavilion octogonal cu cupola (turnurile de colt ale palatului B,
    chhatri-urile de colt ale lui A): 8 fete-grila, fiecare cu un arc retras
    intunecat, streasina pe tot conturul si cupola emisferica pe tambur.
    Inlocuieste `chhatri()` aici: arcele lui deschise (`_arch_band`) randau
    ca niste sarme curbe, iar cupola "onion" turtita citea ca o farfurie --
    pe decupare pavilionul are pile pline intre arce si cupola inalta."""
    side = 2.0 * a * math.tan(math.radians(22.5))
    for k in range(8):
        phi = math.radians(45.0 * k)
        n = Vector((math.cos(phi), math.sin(phi), 0.0))
        u = Vector((-math.sin(phi), math.cos(phi), 0.0))
        p0 = Vector((cx, cy, z0)) + n * a - u * (side * 0.5)
        facade(b, bg, bg, p0, u, n, side, h, 0.28,
               [dict(u=side * 0.5, z=0.0, w=arch_w, h=h - 0.25, arch=True, style="pointed",
                     pier=h - 0.25 - arch_w * 0.6, fill="glow", reveal=0.2, frame=0.0)],
               STONE, GLOW, GLOW, steps=6)
    zt = z0 + h
    _oct_frustum(b, cx, cy, a, a + chajja_out, zt, zt + 0.18, STONE, cap_bottom=True,
                 cap_top=False)
    _oct_frustum(b, cx, cy, a + chajja_out, a + chajja_out, zt + 0.18, zt + 0.28, STONE,
                 cap_bottom=False)
    dome(b, (cx, cy, zt + 0.28), dome_r, STONE, drum_h=dome_r * 0.22, profile="hemisphere",
         segments=12, ribs=8, lotus_ring=True, finial=True, finial_h=dome_r * 0.55)


def _xprofile(b, x_face, y0, y1, poly, slot):
    """Prisma cu profilul (iesire din fata, z) extrudata pe Y de la y0 la y1 --
    streasina (chajja), acoperisul bangla, consola de sub balcon, brauri."""
    W = _fx((x_face, y0, 0.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0))
    return _lprism(b, W, poly, 0.0, y1 - y0, slot)


def _chajja_x(b, x_face, y0, y1, z, out, h=0.32):
    """Streasina subtire, cu fata de sus inclinata spre exterior."""
    return _xprofile(b, x_face, y0, y1,
                     [(-0.05, z), (out, z - 0.02), (out, z + 0.10), (-0.05, z + h)], STONE)


def _band_x(b, x_face, y0, y1, z, out, h):
    return _xprofile(b, x_face, y0, y1, [(-0.05, z), (out, z), (out, z + h), (-0.05, z + h)], STONE)


def _bangla_x(b, x_face, y0, y1, z, out, h):
    """Acoperisul curbat al jharokha-ului (profil bombat, streasina adanca)."""
    return _xprofile(b, x_face, y0, y1,
                     [(-0.05, z + 0.12), (out, z), (out, z + 0.14), (out * 0.72, z + h * 0.62),
                      (out * 0.40, z + h * 0.90), (-0.05, z + h)], STONE)


def _corbel_x(b, x_face, y0, y1, z, out, h):
    """Consola in trepte sub un balcon (piramida intoarsa, in profil)."""
    return _xprofile(b, x_face, y0, y1,
                     [(-0.05, z - h), (out * 0.35, z - h), (out * 0.35, z - h * 0.55),
                      (out, z - h * 0.2), (out, z), (-0.05, z)], STONE)


def _jharokha(b, bg, x_face, yc, z0, width, out, arch_h, n_arch, roof="bangla"):
    """Balcon inchis in consola: consola dedesubt, cutie cu `n_arch` arce
    (goluri retrase, GLOW) si balustrada in ele, acoperis bangla deasupra."""
    y0, y1 = yc - width * 0.5, yc + width * 0.5
    xf = x_face + out
    _corbel_x(b, x_face, y0 + 0.15, y1 - 0.15, z0, out, 0.7)
    ops = []
    aw = width / n_arch * 0.66
    for i in range(n_arch):
        ops.append(dict(u=width * (i + 0.5) / n_arch, z=0.12, w=aw, h=arch_h, arch=True,
                        style="pointed", pier=arch_h - aw * 0.55, fill="glow", reveal=0.30,
                        frame=0.06, frame_out=0.04))
    facade(b, bg, bg, (xf, y0, z0), (0.0, 1.0, 0.0), (1.0, 0.0, 0.0), width,
           arch_h + 0.35, out + 0.05, ops, STONE, GLOW, GLOW, steps=8)
    # balustrada joasa in golurile arcelor
    balustrade(b, (xf - 0.14, y0 + 0.1, z0 + 0.12), (xf - 0.14, y1 - 0.1, z0 + 0.12), 0.75,
               STONE, merlon_w=0.10, merlon_gap=0.10)
    zt = z0 + arch_h + 0.35
    if roof == "bangla":
        _bangla_x(b, x_face, y0 - 0.25, y1 + 0.25, zt, out + 0.45, 0.85)
    else:
        _chajja_x(b, x_face, y0 - 0.25, y1 + 0.25, zt, out + 0.45)
    return zt


def _win(u, z, w, h, kind="a", **kw):
    """Fereastra pe fatada: a = arcuita cu rama si glaf, j = jali (grila
    3 x 4), s = mica dreptunghiulara, n = ingusta arcuita."""
    o = dict(u=u, z=z, w=w, h=h, fill="glow", reveal=0.24, frame=0.10, frame_out=0.06,
             sill=True)
    if kind in ("a", "n", "j"):
        o.update(arch=True, style="pointed", pier=h - w * 0.62)
    if kind == "j":
        o.update(fill="jali")
    o.update(kw)
    return o


# -----------------------------------------------------------------------------
# palace_facade_a -- Moti Mahal
# -----------------------------------------------------------------------------
#
# LISTA DE ELEMENTE (palace_facade_a.png x3, 1715 px de fatada = 40 m, deci
# 0,0233 m/px; y = -20 + (px - 190) x s, z = (580 - py) x s). h/l masurat pe
# decupare: 485/1715 = 0,28 la parapet, 0,31 cu chhatri -> inaltimea iese din
# decupare, 11,3 m la parapet (nu 14: brief-ul spune "proportia plansei
# castiga"). De jos in sus:
#   1. Soclu/parter jos (0-2,6 m) cu brau la 2,6.
#   2. Etajul 1 (ferestre 3,15-5,25 m): stanga 1 arcuita + jharokha + 2 jali;
#      dreapta 2 jali, 1 arcuita pe pilastrul-turn, 1 arcuita, jharokha,
#      1 arcuita; o usa mica sub jharokha din dreapta.
#   3. Brau lat la 6,75 m.
#   4. Etajul 2 (ferestre 7,35-9,0 m): stanga 3 arcuite + 1 mica patrata
#      (pe pilastru) + jali + ingusta + arcuita; dreapta 2 jali + patrata +
#      arcuita + 2 arcuite + ingusta + arcuita. ~7 pe fiecare aripa.
#   5. Cornisa la 9,3 m, banda simpla, parapet la 11,3 m.
#   6. Doi pilastri-turn iesiti (px 400-490 si 1415-1505), pana la 11,9 m.
#   7. Corp central iesit 1,5 m (px 770-1165, 9,2 m): 2 etaje x 3 arce mari
#      pe coloane, balustrade pe ambele etaje (sus pe balcon in consola),
#      streasini la 4,9 si 9,3 m, bloc de atic in stanga lui pana la 12,6 m.
#   8. Doua jharokha laterale (px 355-510 si 1640-1760) cu 3 arce, balustrada
#      si acoperis bangla; o streasina mica pe pilastrul din dreapta.
#   9. Doua chhatri mici pe colturile acoperisului (px 250 si 1605).
PA_LEN = 40.0
PA_DEPTH = 6.0
PA_H = 11.3
PA_S = 40.0 / 1715.0


def _pa_y(px):
    return -20.0 + (px - 190.0) * PA_S


def build_palace_facade_a():
    b = Builder()
    bg = Builder()
    hd = PA_DEPTH * 0.5
    wt = 0.6
    # corpul din spatele fatadei
    b.box((-hd * 0.5 + (hd - wt) * 0.5 - 0.0, 0.0, 5.5),
          (PA_DEPTH - wt, PA_LEN, 11.0), STONE)

    f1z, f1h = 3.15, 2.1
    f2z, f2h = 7.35, 1.65
    wins = []
    # etajul 2
    for px, k in ((265, "a"), (360, "a"), (510, "a"), (605, "j"), (665, "n"), (725, "a"),
                  (1215, "j"), (1340, "j"), (1545, "a"), (1685, "a"), (1740, "n"), (1810, "a")):
        w = 0.62 if k == "n" else 1.0
        wins.append(_win(_pa_y(px) + 20.0, f2z, w, f2h, k))
    # etajul 1
    for px, k in ((270, "a"), (605, "j"), (720, "j"), (1215, "j"), (1340, "j"), (1560, "a"),
                  (1810, "a")):
        wins.append(_win(_pa_y(px) + 20.0, f1z, 1.05, f1h, k))
    # usa mica sub jharokha din dreapta
    wins.append(dict(u=_pa_y(1690) + 20.0, z=0.0, w=1.1, h=1.9, arch=True, style="pointed",
                     pier=1.3, fill="glow", reveal=0.3, frame=0.12, frame_out=0.06))
    facade_bays(b, bg, bg, (hd, -20.0, 0.0), (0.0, 1.0, 0.0), (1.0, 0.0, 0.0), PA_LEN,
                PA_H, wt, wins, STONE, GLOW, GLOW, steps=8)
    W = _fx((hd, -20.0, 0.0), (0.0, 1.0, 0.0), (1.0, 0.0, 0.0))
    # panouri dreptunghiulare in relief in jurul ferestrelor jali
    for o in wins:
        if o.get("fill") == "jali":
            uc, z0, h = o["u"], o["z"], o["h"]
            rect = [(uc - 0.85, z0 - 0.35), (uc - 0.85, z0 + h + 0.3),
                    (uc + 0.85, z0 + h + 0.3), (uc + 0.85, z0 - 0.35)]
            _lband(b, W, rect, 0.10, -0.01, 0.07, STONE, closed=True, outward=False)

    # 1, 3, 5. brauri si cornisa pe toata lungimea
    _band_x(b, hd, -20.0, 20.0, 2.45, 0.16, 0.22)
    _band_x(b, hd, -20.0, 20.0, 6.55, 0.28, 0.30)
    _chajja_x(b, hd, -20.0, 20.0, 9.25, 0.42)
    _band_x(b, hd, -20.0, 20.0, PA_H - 0.05, 0.14, 0.18)
    # pilastri de colt
    for s in (-1.0, 1.0):
        y0 = s * 20.0
        _lbox(b, W, (y0 + 20.0) - (0.7 if s > 0 else 0.0), (y0 + 20.0) + (0.0 if s > 0 else 0.7),
              0.0, PA_H, -0.01, 0.18, STONE)

    # 6. pilastrii-turn iesiti, cu ferestrele lor
    for px0, px1, pw in ((400, 490, [dict(u=0.0, z=f2z + 0.35, w=0.6, h=0.9, fill="glow",
                                          reveal=0.2, frame=0.08, frame_out=0.05, sill=True)]),
                         (1415, 1505, [dict(u=0.0, z=f2z + 0.35, w=0.6, h=0.9, fill="glow",
                                            reveal=0.2, frame=0.08, frame_out=0.05, sill=True),
                                       _win(0.0, f1z, 1.0, f1h, "a")])):
        y0, y1 = _pa_y(px0), _pa_y(px1)
        wdt = y1 - y0
        ops = []
        for o in pw:
            o2 = dict(o)
            o2["u"] = wdt * 0.5
            ops.append(o2)
        facade(b, bg, bg, (hd + 0.35, y0, 0.0), (0.0, 1.0, 0.0), (1.0, 0.0, 0.0), wdt, 11.9,
               0.4, ops, STONE, GLOW, GLOW, steps=8)
        _band_x(b, hd + 0.35, y0 - 0.1, y1 + 0.1, 11.9, 0.12, 0.2)
    # streasina mica pe pilastrul din dreapta (deasupra ferestrei de la etajul 1)
    _bangla_x(b, hd + 0.35, _pa_y(1400), _pa_y(1520), 5.55, 0.7, 0.75)

    # 8. jharokha-urile laterale, la etajul 1
    _jharokha(b, bg, hd, _pa_y(432), 2.25, _pa_y(515) - _pa_y(350), 1.15, 2.6, 3)
    _jharokha(b, bg, hd, _pa_y(1700), 2.25, _pa_y(1765) - _pa_y(1635), 1.0, 2.6, 3)

    # 7. corpul central iesit, 2 etaje x 3 arce mari
    cy0, cy1 = _pa_y(770), _pa_y(1165)
    cw = cy1 - cy0
    cout = 1.5
    xc = hd + cout
    ops = []
    for i, du in enumerate((-2.55, 0.0, 2.55)):
        ops.append(dict(u=cw * 0.5 + du, z=0.45, w=2.2, h=3.85, arch=True, style="round",
                        pier=2.75, fill="glow", reveal=1.1, frame=0.12, frame_out=0.08))
        ops.append(dict(u=cw * 0.5 + du, z=5.45, w=2.2, h=3.4, arch=True, style="round",
                        pier=2.3, fill="glow", reveal=1.1, frame=0.12, frame_out=0.08))
    facade(b, bg, bg, (xc, cy0, 0.0), (0.0, 1.0, 0.0), (1.0, 0.0, 0.0), cw, PA_H + 0.1,
           cout + 0.3, ops, STONE, GLOW, GLOW, steps=10)
    # balustrada de jos, in arce; balconul de sus in consola cu balustrada
    balustrade(b, (xc - 0.2, cy0 + 0.3, 0.45), (xc - 0.2, cy1 - 0.3, 0.45), 0.9, STONE,
               merlon_w=0.12, merlon_gap=0.12)
    _chajja_x(b, xc, cy0 - 0.2, cy1 + 0.2, 4.72, 0.75, 0.3)
    _band_x(b, xc, cy0, cy1, 5.05, 0.55, 0.4)
    balustrade(b, (xc + 0.45, cy0 + 0.1, 5.45), (xc + 0.45, cy1 - 0.1, 5.45), 1.0, STONE,
               merlon_w=0.12, merlon_gap=0.12)
    _chajja_x(b, xc, cy0 - 0.3, cy1 + 0.3, 9.25, 0.85, 0.38)
    _band_x(b, xc, cy0, cy1, PA_H + 0.05, 0.14, 0.18)
    # atic: blocul inalt din stanga corpului central (px 775-870)
    ay0, ay1 = _pa_y(775), _pa_y(870)
    b.box((xc - 1.2, (ay0 + ay1) * 0.5, (PA_H + 12.6) * 0.5), (2.4, ay1 - ay0, 12.6 - PA_H),
          STONE)
    _band_x(b, xc, ay0 - 0.05, ay1 + 0.05, 12.45, 0.1, 0.18)

    # 9. chhatri-urile mici de colt, pe acoperis
    for px in (252, 1607):
        _oct_pavilion(b, bg, hd - 0.8, _pa_y(px), 0.6, PA_H + 0.12, 0.95, 0.35, 0.55,
                      chajja_out=0.18)
        b.box((hd - 0.8, _pa_y(px), PA_H + 0.06), (1.5, 1.5, 0.12), STONE)

    densify_for_ao(b, max_len=3.0)
    stone_obj = b.to_object("Palace_Stone")
    glow_obj = _finish_or_none(bg.to_object("Palace_Glow"))
    return stone_obj, glow_obj


# -----------------------------------------------------------------------------
# palace_facade_b -- fatada simetrica cu cupola centrala
# -----------------------------------------------------------------------------
#
# LISTA DE ELEMENTE (palace_facade_b.png x3; 1725 px = 44 m, 0,0255 m/px;
# z = (585 - py) x s). Brief: "Simetrica" -- decuparea are mici asimetrii
# (dreapta 3 edicule, stanga 2; o cupola in dreapta in loc de jharokha);
# le simetrizam dupa latura DREAPTA (cea mai completa) si dupa jharokha din
# stanga. h/l: 585/1725 = 0,34 cu cupola, 0,24 la parapet -- cupola la
# ~15 m, nu 19 (proportia plansei castiga, ca la A).
#   1. Doua turnuri de colt (4,85 m lat), iesite ~1 m: soclu mai lat, fus
#      fatetat cu brau la 5,2 m si 2 fante sus, balcon in consola la 8,7 m,
#      chhatri cu arce deschise si cupola pana la ~14,4 m.
#   2. Parter: 3 + 3 edicule iesite (pilastri + streasina + nisa arcuita
#      adanca) si 2 nise oarbe (rama arcuita, fara gol) intre ele.
#   3. Brau la 5,2 m.
#   4. Etaj: rand DES de ferestre (arcuite late alternand cu inguste),
#      5 pe fiecare parte a pavilionului + jharokha.
#   5. Parapet crenelat 8,8-10,6 m, cu brau dedesubt.
#   6. Doua jharokha-uri cu cupola pe etaj (la +-9,3 m), cupola peste parapet.
#   7. Pavilion central (7,6 m) iesit 1,5 m: parter cu 3 arce (mijlocul mai
#      mare), balcon in consola cu balustrada si 3 arce sus, streasina la
#      10,6 m, soclu in trepte si CUPOLA MARE nervurata (r 2,7) cu finial.
PB_LEN = 44.0
PB_DEPTH = 6.0
PB_H = 10.6
PB_S = 44.0 / 1725.0
PB_TOWER_A = 2.42     # apotema turnului de colt (4,85 m lat)


def build_palace_facade_b():
    b = Builder()
    bg = Builder()
    hd = PB_DEPTH * 0.5
    wt = 0.6
    ty = PB_LEN * 0.5 - PB_TOWER_A           # axul turnurilor de colt
    inner = ty - PB_TOWER_A                  # muchia interioara a turnului
    b.box(((hd - wt) * 0.5 - hd * 0.5, 0.0, 4.7), (PB_DEPTH - wt, 2.0 * ty, 9.4), STONE)

    # 4. etaj: rand des (offseturi masurate pe latura dreapta, fata de ax)
    wins = []
    for off, k in ((4.95, "a"), (6.76, "n"), (11.48, "a"), (13.16, "n"), (14.96, "a"),
                   (16.4, "n")):
        for s in (-1.0, 1.0):
            w = 0.5 if k == "n" else 0.92
            wins.append(_win(inner + s * off, 6.3, w, 1.5, k, reveal=0.22))
    # 2. parter: edicule (nisa adanca) si nise oarbe
    ed = (5.07, 11.48, 15.0)
    for off in ed:
        for s in (-1.0, 1.0):
            wins.append(dict(u=inner + s * off, z=0.65, w=1.25, h=2.6, arch=True,
                             style="pointed", pier=1.85, fill="glow", reveal=0.45,
                             frame=0.10, frame_out=0.06, sill=True))
    facade_bays(b, bg, bg, (hd, -inner, 0.0), (0.0, 1.0, 0.0), (1.0, 0.0, 0.0), 2.0 * inner,
                8.8, wt, wins, STONE, GLOW, GLOW, steps=8)
    W = _fx((hd, -inner, 0.0), (0.0, 1.0, 0.0), (1.0, 0.0, 0.0))
    for off in ed:
        for s in (-1.0, 1.0):
            uc = inner + s * off
            for du in (-0.95, 0.95):
                _lbox(b, W, uc + du - 0.14, uc + du + 0.14, 0.2, 3.55, -0.01, 0.34, STONE)
            _lbox(b, W, uc - 1.2, uc + 1.2, 0.0, 0.2, -0.01, 0.42, STONE)
            _chajja_x(b, hd, -inner + uc - 1.3, -inner + uc + 1.3, 3.55, 0.7, 0.35)
            _bangla_x(b, hd, -inner + uc - 1.0, -inner + uc + 1.0, 3.9, 0.45, 0.55)
    # nise oarbe: doar rama arcuita in relief
    for s in (-1.0, 1.0):
        uc = inner + s * 8.3
        cont = [(uc + x, 0.7 + z) for x, z in arch_hole_contour("pointed", 1.2, 2.5, 1.8, 8)]
        _lband(b, W, cont, 0.12, -0.01, 0.08, STONE)
    # 3, 5. brauri, parapet crenelat
    _band_x(b, hd, -inner, inner, 0.0, 0.18, 0.45)
    _band_x(b, hd, -inner, inner, 5.05, 0.25, 0.3)
    _band_x(b, hd, -inner, inner, 5.75, 0.12, 0.14)
    _band_x(b, hd, -inner, inner, 8.6, 0.22, 0.25)
    b.box((hd - 0.25, 0.0, 8.8 + 0.8 * 0.5 + 0.0), (0.5, 2.0 * inner, 0.8), STONE)
    crenellation(b, (hd - 0.25, -inner + 0.3, 9.6), (hd - 0.25, inner - 0.3, 9.6), 0.6, STONE,
                 width=0.42, gap=0.30, style="rectangular")

    # 6. jharokha cu cupola la +-9,3
    for s in (-1.0, 1.0):
        yc = s * 9.3
        zt = _jharokha(b, bg, hd, yc, 5.95, 2.7, 1.0, 2.1, 3, roof="flat")
        b.box((hd + 0.15, yc, zt + 0.95), (1.9, 2.3, 1.5), STONE)
        dome(b, (hd + 0.15, yc, zt + 1.7), 1.05, STONE, drum_h=0.25, profile="hemisphere",
             segments=12, ribs=8, lotus_ring=True, finial=True, finial_h=0.4)

    # 1. turnurile de colt
    tx = hd - 1.4
    for s in (-1.0, 1.0):
        yc = s * ty
        _oct_frustum(b, tx, yc, PB_TOWER_A + 0.3, PB_TOWER_A + 0.3, 0.0, 1.1, STONE, cap_top=False)
        _oct_frustum(b, tx, yc, PB_TOWER_A + 0.3, PB_TOWER_A, 1.1, 1.4, STONE, cap_bottom=False,
                     cap_top=False)
        _oct_frustum(b, tx, yc, PB_TOWER_A, PB_TOWER_A - 0.1, 1.4, 8.7, STONE, cap_bottom=False)
        _oct_frustum(b, tx, yc, PB_TOWER_A + 0.02, PB_TOWER_A + 0.02, 5.1, 5.35, STONE)
        for zb in (8.7,):
            _oct_frustum(b, tx, yc, PB_TOWER_A - 0.1, PB_TOWER_A + 0.35, zb, zb + 0.25, STONE,
                         cap_bottom=False, cap_top=False)
            _oct_frustum(b, tx, yc, PB_TOWER_A + 0.35, PB_TOWER_A + 0.35, zb + 0.25, zb + 0.45,
                         STONE, cap_bottom=False)
        # balustrada balconului (parapet plin jos pe tot conturul)
        _oct_frustum(b, tx, yc, PB_TOWER_A + 0.3, PB_TOWER_A + 0.3, 9.15, 9.75, STONE,
                     cap_bottom=False, cap_top=True)
        for k in (7, 0, 1):
            Wk = _oct_facet_frame(tx, yc, PB_TOWER_A - 0.05, k)
            for du in (-0.5, 0.5):
                _lbox(bg, Wk, du - 0.1, du + 0.1, 6.4, 7.5, -0.08, 0.06, GLOW)
        _oct_pavilion(b, bg, tx, yc, PB_TOWER_A - 0.25, 9.75, 2.2, 1.0, 1.75, chajja_out=0.5)

    # 7. pavilionul central
    pw = 7.6
    pout = 1.5
    xc = hd + pout
    ops = []
    for du, w, h in ((-2.0, 1.2, 2.7), (0.0, 1.75, 3.0), (2.0, 1.2, 2.7)):
        ops.append(dict(u=pw * 0.5 + du, z=0.95, w=w, h=h, arch=True, style="pointed",
                        pier=h - w * 0.6, fill="glow", reveal=0.9, frame=0.12, frame_out=0.08))
    for du, w, h in ((-2.1, 1.3, 2.8), (0.0, 1.9, 3.1), (2.1, 1.3, 2.8)):
        ops.append(dict(u=pw * 0.5 + du, z=6.3, w=w, h=h, arch=True, style="pointed",
                        pier=h - w * 0.6, fill="glow", reveal=0.9, frame=0.12, frame_out=0.08))
    facade(b, bg, bg, (xc, -pw * 0.5, 0.0), (0.0, 1.0, 0.0), (1.0, 0.0, 0.0), pw, 10.4,
           pout + 0.3, ops, STONE, GLOW, GLOW, steps=10)
    _band_x(b, xc, -pw * 0.5 - 0.3, pw * 0.5 + 0.3, 0.0, 0.3, 0.55)
    _band_x(b, xc, -pw * 0.5, pw * 0.5, 3.9, 0.3, 0.3)
    _corbel_x(b, xc, -pw * 0.5 + 0.3, pw * 0.5 - 0.3, 6.0, 0.7, 1.1)
    _band_x(b, xc, -pw * 0.5 - 0.1, pw * 0.5 + 0.1, 6.0, 0.75, 0.3)
    balustrade(b, (xc + 0.6, -pw * 0.5 + 0.1, 6.3), (xc + 0.6, pw * 0.5 - 0.1, 6.3), 1.05,
               STONE, merlon_w=0.13, merlon_gap=0.12)
    _chajja_x(b, xc, -pw * 0.5 - 0.35, pw * 0.5 + 0.35, 10.35, 0.9, 0.4)
    # soclul cupolei in trepte + cupola mare nervurata
    dc = xc - 3.0
    b.box((dc, 0.0, 11.05), (6.0, 7.2, 0.7), STONE)
    _oct_frustum(b, dc, 0.0, 3.1, 2.95, 11.4, 12.1, STONE)
    dome(b, (dc, 0.0, 12.1), 2.7, STONE, drum_h=0.3, profile="hemisphere", segments=20, ribs=16,
         lotus_ring=True, finial=True, finial_h=0.7)

    densify_for_ao(b, max_len=3.0)
    stone_obj = b.to_object("Palace_Stone")
    glow_obj = _finish_or_none(bg.to_object("Palace_Glow"))
    return stone_obj, glow_obj


pa_stone, pa_glow = build_palace_facade_a()
emit([pa_stone, pa_glow], "structures/palace_facade_a.glb", AO_STONE, origin="assembly",
     bevel=0.0, budget=None)
# ambele fatade folosesc acelasi nume de nod ("Palace_Stone", contract §1.2)
# -- daca obiectul din facade_a ramane in scena, Blender redenumeste al
# doilea "Palace_Stone.001" la crearea lui, iar acel nume NU se potriveste
# cu cheia din COMPARE_SPECS["palace_facade_b"] (bug gasit la primul
# --compare: piesa iesea complet gri/netintata, cazuta pe atlas_material()
# implicit). Sterge obiectele dupa export, inainte de al doilea build.
pa_mesh = pa_stone.data
bpy.data.objects.remove(pa_stone, do_unlink=True)
bpy.data.meshes.remove(pa_mesh)
if pa_glow is not None:
    pa_glow_mesh = pa_glow.data
    bpy.data.objects.remove(pa_glow, do_unlink=True)
    bpy.data.meshes.remove(pa_glow_mesh)

pb_stone, pb_glow = build_palace_facade_b()
emit([pb_stone, pb_glow], "structures/palace_facade_b.glb", AO_STONE, origin="assembly",
     bevel=0.0, budget=None)


# =============================================================================
# rampart_cannon
# =============================================================================
#
# Contract (brief §1.2): teava 3,2 m, total 3,6 x 1,6 x 1,5, h/l 0,42.
# ESCALADARE OPUS (runda 3; rundele 1-2 respinse: teava un cilindru drept
# NEINCLINAT -- `cylinder(axis="X")` nu primea inclinarea, doar centrul
# mutat pe axa inclinata -- cu o bila uriasa in spate, roti ca discuri
# plate, obraji ca placi drepte, negru mort in preview).
#
# LISTA DE ELEMENTE (decuparea rampart_cannon.png, citita inainte de primul
# vertex; vedere din stanga-fata, gura in dreapta cadrului, putin spre noi):
#   1. Teava lunga, CONICA (culata ~1,6x gura), gri inchis, ridicata ~10 grd.
#   2. 3 inele in relief: inelul de baza la culata, unul la tunari, unul
#      spre gura; gura EVAZATA (buza), cu gaura neagra vizibila.
#   3. Buton (cascabel) mic in spatele culatei.
#   4. Tunarii (fusurile laterale) sprijiniti pe obraji.
#   5. Afet de lemn roscat: 2 obraji cu profil IN TREPTE (inalti in fata,
#      sub tunari, coborand in trepte spre spate), cu coada inclinata pana
#      aproape de sol.
#   6. 2 roti MARI cu spite in fata, sub tunari: janta groasa, butuc,
#      ~12 spite (decuparea; brief-ul scrie 8 -- forma vine din planse).
#   7. 2 roti MICI pline la coada (rotile de spate ale afetului de
#      metereza, stanga-jos pe decupare).
#   Ce iese din contur: gura tevii (dreapta-sus), rotile.
#
# Axe: teava spre +X (fata principala, ca restul cetatii), rotile pe +-Y.
CN_BARREL_LEN = 3.2
CN_TILT = 10.0
CN_TRUNNION = (0.25, 0.0, 1.0)   # (x, y, z) al tunarilor
CN_TRUNNION_T = 1.3              # tunarii la 1,3 m de fata culatei (~40%)
CN_WHEEL_R = 0.62
CN_REAR_R = 0.25


def _lathe(b, profile, origin, axis, slot, segments=14, closed=False):
    """Suprafata de revolutie in jurul unei axe OARECARE: `profile` = lista
    (r, t) de-a lungul axei (t in m de la `origin`); r = 0 la capete da un
    varf inchis. Solid inchis daca profilul incepe si se termina la r = 0."""
    o = Vector(origin)
    a = Vector(axis).normalized()
    ref = Vector((0.0, 0.0, 1.0)) if abs(a.z) < 0.9 else Vector((1.0, 0.0, 0.0))
    u = a.cross(ref).normalized()
    v = a.cross(u).normalized()
    bm = b.bm
    rings = []
    for r, t in profile:
        c = o + a * t
        if r <= 1e-6:
            rings.append([bm.verts.new(c)])
        else:
            rings.append([bm.verts.new(c + (u * math.cos(2 * math.pi * k / segments)
                                            + v * math.sin(2 * math.pi * k / segments)) * r)
                          for k in range(segments)])
    faces = []
    pairs = list(zip(rings, rings[1:]))
    if closed:  # profil inchis (janta): ultimul inel se leaga de primul
        pairs.append((rings[-1], rings[0]))
    for ra, rb in pairs:
        if len(ra) == 1 and len(rb) == 1:
            continue
        for k in range(segments):
            k2 = (k + 1) % segments
            if len(ra) == 1:
                faces.append(bm.faces.new((ra[0], rb[k], rb[k2])))
            elif len(rb) == 1:
                faces.append(bm.faces.new((ra[k], rb[0], ra[k2])))
            else:
                faces.append(bm.faces.new((ra[k], rb[k], rb[k2], ra[k2])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _plate_xz(b, outline, y0, y1, slot):
    """Placa (prisma pe Y) dintr-un contur CONCAV in planul XZ -- capace prin
    ear-clipping (vocabularul), laturi quad. Solid manifold."""
    bm = b.bm
    fa = [bm.verts.new((x, y0, z)) for x, z in outline]
    fb = [bm.verts.new((x, y1, z)) for x, z in outline]
    faces = []
    for i0, i1, i2 in _ear_clip(outline):
        faces.append(bm.faces.new((fa[i0], fa[i1], fa[i2])))
        faces.append(bm.faces.new((fb[i2], fb[i1], fb[i0])))
    n = len(outline)
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((fa[i], fb[i], fb[j], fa[j])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _spoked_wheel(b, center, r, width, spokes, slot):
    """Roata cu janta (inel gros), butuc si spite -- pe axa Y."""
    cx, cy, cz = center
    # janta: inel inchis (profil dreptunghiular revolut in jurul lui Y)
    rim_in = r * 0.84
    hw = width * 0.5
    faces = _lathe(b, [(rim_in, -hw), (r, -hw), (r, hw), (rim_in, hw)],
                   (cx, cy, cz), (0, 1, 0), slot, segments=14, closed=True)
    # butucul
    b.cylinder((cx, cy, cz), r * 0.17, width * 1.9, slot, segments=10, axis="Y")
    # spitele
    for k in range(spokes):
        ang = 2 * math.pi * (k + 0.5) / spokes
        d = Vector((math.cos(ang), 0.0, math.sin(ang)))
        p1 = Vector(center) + d * (r * 0.15)
        p2 = Vector(center) + d * (rim_in + 0.02)
        b.beam(p1, p2, (0.055, width * 0.55), slot, up=(0, 1, 0))
    return faces


def build_rampart_cannon():
    b = Builder()     # Cannon_Metal
    bw = Builder()    # Cannon_Wood

    tilt = math.radians(CN_TILT)
    axis = Vector((math.cos(tilt), 0.0, math.sin(tilt)))
    trun = Vector(CN_TRUNNION)
    breech = trun - axis * CN_TRUNNION_T

    # 1-3. teava: un singur profil revolut (r, t) de la butonul cascabelului
    # la fundul gurii -- culata 0,25, gura 0,155 (raport 1,6), buza 0,19
    L = CN_BARREL_LEN
    prof = [
        (0.0, -0.30), (0.075, -0.28), (0.095, -0.21), (0.075, -0.14),   # buton
        (0.05, -0.10), (0.05, -0.06), (0.17, -0.03), (0.23, 0.0),       # gat + culata
        (0.265, 0.02), (0.265, 0.16), (0.245, 0.18),                      # inel de baza
        (0.215, CN_TRUNNION_T - 0.08), (0.235, CN_TRUNNION_T - 0.06),     # inel la tunari
        (0.235, CN_TRUNNION_T + 0.06), (0.205, CN_TRUNNION_T + 0.08),
        (0.18, 2.20), (0.20, 2.22), (0.20, 2.32), (0.175, 2.34),          # inelul gurii
        (0.155, L - 0.26), (0.19, L - 0.14), (0.195, L),                  # buza evazata
        (0.095, L), (0.095, L - 0.22), (0.0, L - 0.22),                   # gaura
    ]
    _lathe(b, prof, breech, axis, CANNON_METAL, segments=12)
    # 4. tunarii (fusuri pe Y)
    b.cylinder((trun.x, trun.y, trun.z), 0.075, 0.74, CANNON_METAL, segments=10, axis="Y")

    # 5. obrajii afetului: profil in trepte, coada pana aproape de sol
    cheek = [(0.62, 0.40), (0.62, 0.93), (0.36, 0.93), (0.33, 1.0), (0.17, 1.0),
             (0.14, 0.93), (0.02, 0.93), (0.02, 0.80), (-0.36, 0.80), (-0.36, 0.66),
             (-0.74, 0.66), (-1.42, 0.36), (-1.42, 0.14), (-0.70, 0.26), (0.10, 0.38)]
    for s in (-1.0, 1.0):
        y0, y1 = s * 0.28, s * 0.40
        _plate_xz(bw, cheek, min(y0, y1), max(y0, y1), CANNON_WOOD)
    # traversele dintre obraji (fata, mijloc, coada) + pana de sub culata
    bw.box((0.45, 0.0, 0.52), (0.26, 0.58, 0.22), CANNON_WOOD)
    bw.box((-0.45, 0.0, 0.42), (0.30, 0.58, 0.18), CANNON_WOOD)
    bw.box((-1.20, 0.0, 0.30), (0.30, 0.58, 0.18), CANNON_WOOD)
    bw.box((-0.62, 0.0, 0.64), (0.46, 0.30, 0.16), CANNON_WOOD)

    # 6. rotile mari cu spite, sub tunari, pe osie
    ax_x = CN_TRUNNION[0]
    bw.cylinder((ax_x, 0.0, CN_WHEEL_R), 0.065, 1.42, CANNON_WOOD, segments=8, axis="Y")
    for s in (-1.0, 1.0):
        _spoked_wheel(bw, (ax_x, s * 0.60, CN_WHEEL_R), CN_WHEEL_R, 0.11, 12, CANNON_WOOD)

    # 7. rotile mici pline de la coada
    for s in (-1.0, 1.0):
        bw.cylinder((-1.18, s * 0.48, CN_REAR_R), CN_REAR_R, 0.12, CANNON_WOOD,
                    segments=12, axis="Y")
        bw.cylinder((-1.18, s * 0.48, CN_REAR_R), CN_REAR_R * 0.35, 0.18, CANNON_WOOD,
                    segments=8, axis="Y")
    bw.cylinder((-1.18, 0.0, CN_REAR_R), 0.05, 1.04, CANNON_WOOD, segments=8, axis="Y")

    metal_obj = b.to_object("Cannon_Metal")
    wood_obj = bw.to_object("Cannon_Wood")
    return metal_obj, wood_obj


cannon_metal, cannon_wood = build_rampart_cannon()
emit([cannon_metal, cannon_wood], "props/rampart_cannon.glb", AO_PROP, origin="assembly",
     bevel=0.012, budget=4200)


print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-42s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL cetate (val 2a): %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([o for o in (wall_stone, wall_glow, turret_stone, turret_glow, bastion_stone,
                        pb_stone, pb_glow,
                        cannon_metal, cannon_wood) if o is not None],
          "jodhpur_fort.blend")
