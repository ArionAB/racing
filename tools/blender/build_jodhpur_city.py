"""Jodhpur -- Orasul albastru, val 3a (brief §1.4, docs/asset_briefs/jodhpur_kit.md).

  jodhpur/buildings/blue_house_b.glb    3 volume in trepte, rezervor + planta
  jodhpur/buildings/blue_house_c.glb    cub simplu, usa in arc, rezervor
  jodhpur/buildings/blue_house_d.glb    terasa cu balustrada pe tot perimetrul
  jodhpur/buildings/blue_house_e.glb    volum in L, scara pe fata
  jodhpur/buildings/haveli_facade.glb   casa bogata: arcade + balcoane de piatra
  jodhpur/props/rooftop_tank.glb        rezervor negru, nervuri orizontale
  jodhpur/props/rooftop_clutter.glb     placa de terasa cu rufe + oale

Reuseste vocabularul din jodhpur_shapes.py (arch_opening, chajja, solid_stair,
balustrade, railing_on_brackets) si constructia lui blue_house_a (pilot,
ACCEPTATA -- brief spune explicit "reuse its construction"): miez retras pe
fata cu goluri + benzi late pe restul peretelui, ca `arch_opening` sa se
lipeasca flush fara sa z-fighteze cu o cutie plina alaturata.

**Camera:** testul cu cub colorat pe fete al pilotului (v3, blue_house_a) a
gasit ca +X e fata DOMINANTA a camerei `compare()` la azimut/elevatie implicit
(35/18) -- pastram aceeasi conventie pe toate casele astea (aproape cubice, ca
pilotul, nu alungite ca cetatea): fatada principala (usa/scara/arcade) pe +X.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_jodhpur_city.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "jodhpur_shapes.py")).read())

# Sloturile legale pe Jodhpur (brief §0.4) -- identice cu pilotul.
WALL = FOAM_WHITE        # peretele albastru (alb x tenta blue_lime_light/indigo)
TRIM_WOOD = WOOD         # usi
GLOW = VOLCANIC_BLACK    # goluri de geam/usa, ziua inchise
RAIL_WHITE = FOAM_WHITE  # balustrada, FARA tenta (nod separat de perete)
TANK_DARK = LOG_DARK     # rezervoarele negre de pe acoperis
PLANT_GREEN = CACTUS_GREEN
LAUNDRY_YELLOW = CAR_YELLOW
LAUNDRY_PINK = FLAMINGO_PINK

# `low` ridicat fata de pilot (0.46 -> 0.58, runda de corectii): masurat cu
# --compare, fetele SOARE-LUMINATE ale caselor pe 2-3 etaje (blue_house_c/d/e,
# haveli) ieseau la ~55-85% din hex-ul tinta (pilotul blue_house_a atinge
# ~97%) -- aceeasi formula AO, dar volumele mai inalte/mai ingropate (chajja,
# balustrade, tank pe fiecare etaj) se auto-umbresc mai mult pe fetele mari.
# `low` mai ridicat pastreaza gradientul (colturile/firidele tot mai
# inchise), dar nu mai trage fetele plate spre gri-indigo ("iese
# indigo-cenusiu inchis in loc de albastru deschis" -- verdictul liderului).
AO_HOUSE = dict(samples=20, dist=4.0, gradient="vertical",
                low=0.58, high=1.00, power=0.88, floor=0.24)
AO_PROP = dict(samples=16, dist=2.0, gradient="vertical",
               low=0.50, high=1.00, power=0.85, floor=0.20)


# --- facade: perete PLAN cu goluri distribuite (runda 3 de corectii) ---------
#
# De ce (verdictul liderului pe b/c/e/haveli): `arch_opening` pe goluri
# izolate pune fiecare gol intr-un PANOU propriu care iese din perete
# ("arcade in rame iesite"), iar fata ramasa era o nisa cu varfuri doar in
# colturi -- AO-ul copt pe varf o innegrea toata ("albastru-marin"). Aici
# peretele e o GRILA: coloane la marginile golurilor x randuri la pragurile/
# buiandrugii lor; fiecare celula e plina sau gol. Fata, spatele si firidele
# golurilor partajeaza varfurile (fara fete interne => fara rosturi de bevel
# intre "cutii"), timpanele arcelor se lipesc de aceleasi varfuri. Rama e o
# banda SUBTIRE care iese 4-5 cm, nu un panou. Golurile raman retrase (brief
# §1.4), cu placa GLOW / lemn in fund.
#
# Helperul sta AICI, nu in jodhpur_shapes.py: fisierul de vocabular e comun cu
# constructorul cetatii, care lucreaza in paralel pe alta ramura.

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
    """Banda de sectiune dreptunghiulara de-a lungul unei polilinii (u, z), cu
    imbinari in unghi -- rama. Polilinia merge in sensul golului (stanga-jos
    -> sus -> dreapta-jos), deci stanga sensului = in afara golului."""
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
        pts = arch_hole_contour(o.get("style", "round"), w, h, pier, steps)
        return [(uc + x, z + zz) for x, zz in pts]
    return [(uc - hw, z), (uc - hw, z + h), (uc + hw, z + h), (uc + hw, z)]


def facade(b, bglow, btrim, p0, u, n, width, height, thick, openings, slot,
           glow_slot, trim_slot, frame_slot=None, steps=8, bframe=None,
           cap_left=True, cap_right=True, cap_top=True):
    """Perete plan `width` x `height`, coltul stanga-jos al FETEI in `p0`,
    `u` = spre dreapta vazut din afara, `n` = normala exterioara, gros `thick`
    spre interior. `cap_left/right`: inchide capatul (False cand capatul se
    lipeste coplanar de peretele vecin -- altfel bevel-ul face un rost).

    Gol: dict cu u (centru), z (prag), w, h; optional arch=True, style,
    pier; fill="glow"|"wood"|"shutter"|"open"; frame (0 = fara), frame_out,
    sill, step, reveal. Intoarce {"wall", "frame", "glow", "trim"}."""
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
        """'solid', 'hole' sau 'rise' (gol in banda arcului: timpanul il
        umple o prisma separata, deci nu se fac firide pe muchiile ei)."""
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
            # laturi spre gol / capete
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

    # timpanele arcelor, lipite de varfurile grilei
    for o in ops:
        if not o.get("arch"):
            continue
        uc, hw = o["u"], o["_hw"]
        zp, top = o["z"] + o["_pier"], o["z"] + o["h"]
        rise = top - zp
        prof = _arch_profile(o.get("style", "round"), hw, rise, steps)
        left = [p for p in prof if p[0] <= 1e-9]
        if abs(left[-1][0]) > 1e-6:
            left.append((0.0, rise))
        iu0, iuc, iu1 = us.index(key(uc - hw)), us.index(key(uc)), us.index(key(uc + hw))
        jz0, jz1 = zs.index(key(zp)), zs.index(key(top))
        for side in (-1, 1):
            arc = [(uc - side * x, zp + zz) for x, zz in left[1:-1]]
            outer_i = iu0 if side < 0 else iu1
            # poligon: picior -> arc -> cheie -> colt de sus -> (inapoi la picior)
            front = [gv(outer_i, jz0, 0)] + [b.bm.verts.new(W(p[0], p[1], 0.0)) for p in arc] + \
                    [gv(iuc, jz1, 0), gv(outer_i, jz1, 0)]
            back = [gv(outer_i, jz0, 1)] + [b.bm.verts.new(W(p[0], p[1], -thick)) for p in arc] + \
                   [gv(iuc, jz1, 1), gv(outer_i, jz1, 1)]
            poly = [(us[outer_i], zs[jz0])] + arc + [(uc, top), (us[outer_i], top)]
            for i0, i1, i2 in _ear_clip(poly):
                wall.append(b.bm.faces.new((front[i0], front[i1], front[i2])))
                wall.append(b.bm.faces.new((back[i2], back[i1], back[i0])))
            # intradosul: doar de-a lungul arcului (picior -> cheie)
            m = len(front) - 1          # indicele ultimului punct al arcului = cheia
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
                           z0 - 0.10, z0, -0.02, fo + 0.08, frame_slot)
        if o.get("step"):
            frame += _lbox(bf, W, uc - hw - 0.3, uc + hw + 0.3, 0.0, 0.14, -0.02,
                           0.42, frame_slot)
        if fill == "open":
            glow += _lprism(bglow, W, cont, -thick - 0.30, -thick - 0.26, glow_slot)
            continue
        if fill == "wood":
            trim += _lprism(btrim, W, cont, -reveal - 0.04, -reveal, trim_slot)
            trim += _lbox(btrim, W, uc - 0.03, uc + 0.03, z0 + 0.02, z0 + pier - 0.05,
                          -reveal, -reveal + 0.025, trim_slot)
            continue
        glow += _lprism(bglow, W, cont, -reveal - 0.03, -reveal, glow_slot)
        if fill == "shutter":
            tw = max(0.08, w * 0.22)
            trim += _lband(btrim, W, cont, tw, -reveal, -reveal + 0.04, trim_slot,
                           closed=True, outward=False)
            trim += _lbox(btrim, W, uc - tw * 0.4, uc + tw * 0.4, z0, z0 + pier,
                          -reveal, -reveal + 0.035, trim_slot)
    return {"wall": wall, "frame": frame, "glow": glow, "trim": trim}



def _finish_or_none(obj):
    """Vezi build_jodhpur_pilot.py -- un Builder GLOW poate ramane gol."""
    if len(obj.data.vertices) == 0:
        name = obj.name
        me = obj.data
        bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.meshes.remove(me)
        return None
    return obj


def _cheap_arch_opening(b, bg, center, w, h, pier_frac, wall_t, slot, glow_slot,
                        rotation=None, open=False):
    """Gol arcuit IEFTIN pentru piese cu buget mic (haveli, <=900 tri total):
    un dreptunghi cu cele DOUA colturi de sus TAIATE (octogon simplificat),
    in loc de profilul de arc cu `steps` segmente al lui `arch_opening`. La
    30 m in joc un colt tesit citeste ca un arc rotunjit (brief regula 5:
    geometria conteaza doar daca schimba silueta/umbra la acea distanta) --
    fara sa coste cele ~40-60 de fete per gol ale versiunii complete.

    `open=True`: doar o BANDA subtire (jgheab) pe conturul golului, fara
    panou (arcada deschisa a parterului). `open=False`: panou plin in jurul
    golului + firida + placa GLOW retrasa (fereastra inchisa).

    Contur (in planul local XZ, Y=0): octogon cu 6 varfuri -- 2 la baza,
    2 la mijlocul inaltimii (unde incepe taierea), 2 la varf (taiate)."""
    cx, cy, cz = center
    hw = w * 0.5
    pier_h = h * pier_frac
    chamfer = min(hw, h - pier_h)

    def rot_pt(x, y, z):
        p = Vector((x, y, z))
        if rotation is not None:
            m = rotation.to_matrix() if hasattr(rotation, "to_matrix") else rotation
            p = m @ p
        return (cx + p.x, cy + p.y, cz + p.z)

    hole = [(-hw, 0.0), (-hw, pier_h), (-hw + chamfer * 0.5, h),
           (hw - chamfer * 0.5, h), (hw, pier_h), (hw, 0.0)]

    if open:
        band_w = wall_t * 0.4
        faces = []
        n = len(hole)
        for i in range(n):
            x0, z0 = hole[i]
            x1, z1 = hole[(i + 1) % n] if i < n - 1 else hole[i]
            if i == n - 1:
                break
            dx, dz = x1 - x0, z1 - z0
            ln = math.hypot(dx, dz) or 1e-6
            nx, nz = -dz / ln, dx / ln
            a0 = (x0 - nx * band_w * 0.5, z0 - nz * band_w * 0.5)
            a1 = (x0 + nx * band_w * 0.5, z0 + nz * band_w * 0.5)
            b0 = (x1 - nx * band_w * 0.5, z1 - nz * band_w * 0.5)
            b1 = (x1 + nx * band_w * 0.5, z1 + nz * band_w * 0.5)
            for y_val, flip in ((wall_t * 0.5, False), (-wall_t * 0.5, True)):
                quad = (a0, b0, b1, a1) if not flip else (a1, b1, b0, a0)
                pts = [rot_pt(x, y_val, z) for x, z in quad]
                faces.append(b.bm.faces.new(tuple(b.bm.verts.new(p) for p in pts)))
        for f in faces:
            if f.is_valid:
                f[b.slot] = slot
        return faces

    # NOTA cost: varianta ieftina renunta la inelul de firida separat
    # (reveal) fata de `arch_opening` -- glow-ul sta chiar la fata peretelui
    # (fara adancime de firida), ceea ce economiseste 5 fete/gol (x6 ferestre
    # = 30 fete, semnificativ la un buget de 900). La aceasta scara (ferestre
    # mici, etaj superior) diferenta vizuala e minora -- golul tot citeste
    # inchis la culoare (VOLCANIC_BLACK), doar fara umbra de adancime.
    panel_w, panel_h = w * 2.0, h * 1.25
    hw_panel = panel_w * 0.5
    hole_x0, hole_x1 = -hw, hw
    hole_z0, hole_z1 = 0.0, h
    inner_edge, back_edge = wall_t * 0.5, -wall_t * 0.5
    faces = []

    def flat_rect(x0, x1, z0, z1, y_val, flip):
        if x1 - x0 < 1e-6 or z1 - z0 < 1e-6:
            return None
        pts = [(x0, y_val, z0), (x1, y_val, z0), (x1, y_val, z1), (x0, y_val, z1)]
        if flip:
            pts = list(reversed(pts))
        return b.bm.faces.new(tuple(b.bm.verts.new(rot_pt(*p)) for p in pts))

    def panel_fill(y_val, flip):
        out = []
        f = flat_rect(-hw_panel, hw_panel, hole_z1, panel_h, y_val, flip)
        if f:
            out.append(f)
        f = flat_rect(-hw_panel, hole_x0, hole_z0, hole_z1, y_val, flip)
        if f:
            out.append(f)
        f = flat_rect(hole_x1, hw_panel, hole_z0, hole_z1, y_val, flip)
        if f:
            out.append(f)
        return out

    faces += panel_fill(inner_edge, False)
    faces += panel_fill(back_edge, True)
    for f in faces:
        if f.is_valid:
            f[b.slot] = slot

    glow_outline = [(x * 0.85, z if z < 1e-6 else z * 0.94 + hole_z0 * 0.06) for x, z in hole]
    glow_edge = inner_edge - wall_t * 0.3   # usor retras fata de fata peretelui
    gpts = [rot_pt(x, glow_edge, z) for x, z in glow_outline]
    gf = bg.bm.faces.new(tuple(bg.bm.verts.new(p) for p in gpts))
    if gf.is_valid:
        gf[bg.slot] = glow_slot
    return faces


def _rooftop_tank(b, center, radius=0.6, height=1.4, slot=TANK_DARK, n_ribs=4):
    """Rezervor: cilindru negru cu nervuri orizontale + capac usor bombat.
    Folosit atat ca piesa de sine statatoare (props/rooftop_tank.glb) cat si
    inline pe fiecare casa (blue_house_b/c). `segments` 12 (brief §1.4)."""
    cx, cy, cz = center
    faces = list(b.cylinder((cx, cy, cz + height * 0.5), radius, height, slot,
                            segments=12, axis="Z"))
    rib_h = 0.05
    for i in range(1, n_ribs):
        rz = cz + height * i / n_ribs
        faces += list(b.frustum((cx, cy, rz), radius * 1.04, radius * 1.04,
                                rib_h, slot, segments=12, axis="Z"))
    # capac usor bombat (frustum ingust + disc mic)
    faces += list(b.frustum((cx, cy, cz + height + 0.05), radius * 1.02,
                            radius * 0.55, 0.10, slot, segments=12, axis="Z"))
    faces += list(b.cylinder((cx, cy, cz + height + 0.14), radius * 0.55, 0.08,
                             slot, segments=12, axis="Z"))
    return faces


# --- blue_house_b ------------------------------------------------------------
#
# Contract (brief §1.4): 7x6 m, 3 etaje IN TREPTE, 9,5 m, h/l 1,09, tenta
# light, planta verde in coltul terasei de jos, balustrada pe terasa din
# mijloc, rezervor pe cel mai inalt.
#
# Element list (decupare blue_house_b.png, marire x4 -- runda 3 de corectii,
# "golurile inghesuite in coltul de jos al unei singure fete"). Vazuta din
# colt, az ~46: fata STANGA = +X (7 m pe Y), fata DREAPTA = +Y (6 m pe X).
#
#   PARTER (corp plin pe toata amprenta, ~3,6 m, cornisa de jur imprejur):
#     +X: USA dreptunghiulara de lemn spre capatul STANG (Y ~ -2,6), cu
#         PLANTA (tufa verde bogata) pe cornisa chiar deasupra ei; o FEREASTRA
#         mica dreptunghiulara, inchisa, cu rama subtire, spre colt (Y ~ +1,4).
#     +Y: USA dreptunghiulara de lemn, putin la dreapta mijlocului (X ~ -0,2).
#   ETAJ 1, doua volume pe terasa parterului, in trepte:
#     - volumul STANG-SPATE (X 0,75..3, Y -3,5..-1), un etaj, cu cate o
#       FEREASTRA mica pe fiecare fata vizibila (+X si +Y) si BALUSTRADA
#       alba de fier pe acoperisul lui (terasa din mijloc).
#     - TURNUL (X -2,75..0,75, Y -3,5..1,2), doua etaje peste parter, cu USA
#       de lemn pe fata +Y la nivelul terasei (spre stanga fetei) si o
#       fereastra mica sus pe fata +X; cornisa la nivelul acoperisului
#       volumului stang, rezervor NEGRU lat si scund pe varf.
#   TERASA DIN FATA (parterul ramas liber, spre +Y si +X): parapet scund cu
#   coama alba si un stalp la colt.
HB_W, HB_D = 7.0, 6.0     # W pe Y, D pe X
HB_H = 9.2                # varful peretilor turnului (+ rezervorul ~0,7)


def _blob(b, center, r, slot):
    """Bulgare de frunzis: icosfera cu subdivisions 1 (80 tri)."""
    res = bmesh.ops.create_icosphere(b.bm, subdivisions=1, radius=r)
    for v in res["verts"]:
        v.co += Vector(center)
    return list(b._tag(res["verts"], slot))


def _parapet(b, br, p1, p2, h, t, slot, coping_slot):
    """Parapet plin scund (b) cu coama alba (br) intre p1 si p2 (baze)."""
    a, c = Vector(p1), Vector(p2)
    d = c - a
    L = d.length
    rot = Matrix.Rotation(math.atan2(d.y, d.x), 3, "Z")
    mid = (a + c) * 0.5
    b.box((mid.x, mid.y, a.z + h * 0.5), (L, t, h), slot, rotation=rot)
    br.box((mid.x, mid.y, a.z + h + 0.04), (L + 0.06, t + 0.08, 0.08), coping_slot,
           rotation=rot)


def build_blue_house_b():
    b = Builder()
    bg = Builder()
    bglow = Builder()
    br = Builder()
    T = 0.3
    hx, hy = HB_D * 0.5, HB_W * 0.5          # 3.0, 3.5
    g_h = 3.6
    rail = RAIL_WHITE

    # --- parter
    b.box((-T * 0.5, -T * 0.5, g_h * 0.5), (HB_D - T, HB_W - T, g_h), WALL)
    b.box((0.0, 0.0, 0.13), (HB_D + 0.1, HB_W + 0.1, 0.26), WALL)
    facade(b, bglow, bg, (hx, -hy, 0.0), (0, 1, 0), (1, 0, 0), HB_W, g_h, T,
           openings=[dict(u=0.9, z=0.0, w=1.0, h=2.15, fill="wood", frame=0.09),
                     dict(u=4.9, z=1.45, w=0.7, h=0.95, fill="glow", frame=0.07, sill=True)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD)
    facade(b, bglow, bg, (hx - T, hy, 0.0), (-1, 0, 0), (0, 1, 0), HB_D - T, g_h, T,
           openings=[dict(u=2.8, z=0.0, w=1.1, h=2.2, fill="wood", frame=0.1)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD, cap_left=False)
    for nx, ny, w in ((0, 1, HB_D + 0.5), (0, -1, HB_D + 0.5), (1, 0, HB_W + 0.5), (-1, 0, HB_W + 0.5)):
        rot = Matrix.Rotation(math.atan2(-nx, ny), 3, "Z")
        chajja(b, (nx * hx, ny * hy, g_h), w, 0.35, WALL, thickness=0.12, slope=0.5,
               rotation=rot)

    # planta: tufa bogata pe cornisa, deasupra usii de pe +X
    plant = []
    for (dx, dy, dz, r) in ((0.15, -2.75, 0.35, 0.42), (0.05, -2.25, 0.25, 0.34),
                            (0.3, -3.1, 0.15, 0.30), (-0.1, -2.6, 0.7, 0.30),
                            (0.35, -2.45, -0.15, 0.26)):
        plant += _blob(b, (hx + dx, dy, g_h + dz), r, PLANT_GREEN)

    # --- volumul stang-spate (un etaj peste parter)
    lx0, lx1, ly0, ly1 = 0.75, hx, -hy, -1.0
    l_h = 3.0
    b.box(((lx0 + lx1 - T) * 0.5, (ly0 + ly1 - T) * 0.5, g_h + l_h * 0.5),
          (lx1 - lx0 - T, ly1 - ly0 - T, l_h), WALL)
    facade(b, bglow, bg, (lx1, ly0, g_h), (0, 1, 0), (1, 0, 0), ly1 - ly0, l_h, T,
           openings=[dict(u=1.15, z=1.05, w=0.6, h=0.8, fill="glow", frame=0.06, sill=True)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD)
    facade(b, bglow, bg, (lx1 - T, ly1, g_h), (-1, 0, 0), (0, 1, 0), lx1 - T - lx0, l_h, T,
           openings=[dict(u=0.85, z=1.05, w=0.6, h=0.8, fill="glow", frame=0.06, sill=True)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD, cap_left=False)
    top_l = g_h + l_h
    b.box(((lx0 + lx1) * 0.5, (ly0 + ly1) * 0.5, top_l + 0.07), (lx1 - lx0 + 0.2, ly1 - ly0 + 0.2, 0.14), WALL)
    # balustrada alba de fier pe acoperisul volumului stang (+X si +Y)
    rz = top_l + 0.14
    br.railing((lx1 - 0.08, ly0 + 0.1, rz), (lx1 - 0.08, ly1 - 0.08, rz), 0.9, 0.7, 0.06, 0.05, rail, rails=2)
    br.railing((lx1 - 0.08, ly1 - 0.08, rz), (lx0 + 0.1, ly1 - 0.08, rz), 0.9, 0.7, 0.06, 0.05, rail, rails=2)

    # --- turnul (doua etaje peste parter)
    tx0, tx1, ty0, ty1 = -hx + 0.25, 0.75, -hy, 1.2
    t_h = HB_H - g_h
    b.box(((tx0 + tx1 - T) * 0.5, (ty0 + ty1 - T) * 0.5, g_h + t_h * 0.5),
          (tx1 - tx0 - T, ty1 - ty0 - T, t_h), WALL)
    facade(b, bglow, bg, (tx1, ty0, g_h), (0, 1, 0), (1, 0, 0), ty1 - ty0, t_h, T,
           openings=[dict(u=3.55, z=3.9, w=0.5, h=0.7, fill="glow", frame=0.05)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD)
    facade(b, bglow, bg, (tx1 - T, ty1, g_h), (-1, 0, 0), (0, 1, 0), tx1 - T - tx0, t_h, T,
           openings=[dict(u=1.35, z=0.0, w=0.95, h=2.1, fill="wood", frame=0.08)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD, cap_left=False)
    tcx, tcy = (tx0 + tx1) * 0.5, (ty0 + ty1) * 0.5
    for z_c, out in ((top_l, 0.22), (HB_H, 0.3)):
        for nx, ny, w in ((0, 1, tx1 - tx0 + 2 * out), (0, -1, tx1 - tx0 + 2 * out),
                          (1, 0, ty1 - ty0 + 2 * out), (-1, 0, ty1 - ty0 + 2 * out)):
            rot = Matrix.Rotation(math.atan2(-nx, ny), 3, "Z")
            cx = tcx + nx * (tx1 - tx0) * 0.5
            cy = tcy + ny * (ty1 - ty0) * 0.5
            chajja(b, (cx, cy, z_c), w, out, WALL, thickness=0.12, slope=0.5, rotation=rot)
    b.box((tcx, tcy, HB_H + 0.2), (tx1 - tx0, ty1 - ty0, 0.28), WALL)
    _rooftop_tank(b, (tcx + 0.2, tcy - 0.3, HB_H + 0.34), radius=0.8, height=0.65, n_ribs=2)

    # --- terasa din fata: parapet scund cu coama alba + stalp la colt
    pz = g_h + 0.12
    _parapet(b, br, (-hx + 0.25, hy - 0.12, pz), (hx - 0.12, hy - 0.12, pz), 0.5, 0.22, WALL, rail)
    _parapet(b, br, (hx - 0.12, hy - 0.12, pz), (hx - 0.12, ly1, pz), 0.5, 0.22, WALL, rail)
    br.box((hx - 0.14, hy - 0.14, pz + 0.45), (0.28, 0.28, 0.9), rail)

    densify_for_ao(b, max_len=2.5)
    wall_obj = b.to_object("House_Wall")
    trim_obj = _finish_or_none(bg.to_object("House_Trim"))
    glow_obj = _finish_or_none(bglow.to_object("House_Glow"))
    rail_obj = _finish_or_none(br.to_object("House_Rail"))
    return wall_obj, trim_obj, glow_obj, rail_obj


# --- blue_house_c ------------------------------------------------------------
#
# Contract (brief §1.4): 7x7 m, 2 etaje, 6,5 m, h/l 0,88, tenta light.
#
# Element list (decupare blue_house_c.png, masurata pe marirea x4 -- runda 3
# de corectii, dupa verdictul "cub prea mare, golurile minuscule in colt").
# Decuparea e vazuta din colt: fata DREAPTA (+Y aici) e cea frontala (455 px
# latime aparenta), fata STANGA (+X) e in fuga (240 px) -- camera az ~62.
# Scara verticala: peretele + cornisa ~505 px pentru ~6,8 m => ~74 px/m.
#
#   fata +Y (dreapta, frontala):
#     1. USA de lemn in ARC rotund, aproape CENTRATA (centrul la ~3,4 m din
#        coltul stang al fetei), ~1,5 x 2,9 m -- mare: pragul la sol, cheia la
#        ~45% din inaltimea peretelui. Rama de var mai deschisa, in relief,
#        de jur imprejur (~0,15 m) + treapta de piatra in fata.
#     2. o FEREASTRA dreptunghiulara, sus-DREAPTA (centrul la ~5,9 m), ~1,0 x
#        1,6 m, pragul la ~3,2 m (deasupra cheii usii): toc de lemn maro,
#        geam inchis, rama subtire + glaf.
#   fata +X (stanga, in fuga):
#     3. DOUA ferestre dreptunghiulare identice cu 2., la aceeasi inaltime,
#        la ~2,2 m si ~5,3 m de colt -- distribuite pe fata, nu lipite.
#   acoperis:
#     4. cornisa (streasina subtire) la baza parapetului, parapet plin cu
#        coama mai deschisa, terasa retrasa in el.
#     5. rezervor NEGRU pe terasa, spre mijloc/spate.
# h/l: corpul pana la coama parapetului 6,5 m (brief), 7 x 7.
HC_SIDE = 7.0
HC_WALL = 6.5


def build_blue_house_c():
    b = Builder()
    bg = Builder()
    bglow = Builder()
    hs = HC_SIDE * 0.5
    T = 0.35                   # grosimea peretilor cu goluri
    body_h = 5.6               # corpul pana sub cornisa

    # miezul plin, retras cu T doar pe fetele care primesc `facade`
    b.box((-T * 0.5, -T * 0.5, body_h * 0.5), (HC_SIDE - T, HC_SIDE - T, body_h), WALL)
    b.box((0.0, 0.0, 0.15), (HC_SIDE + 0.12, HC_SIDE + 0.12, 0.30), WALL)   # soclu

    win = dict(w=1.1, h=1.7, z=3.1, fill="shutter", frame=0.08, sill=True)
    # fata +Y: usa in arc aproape centrata + fereastra sus-dreapta
    facade(b, bglow, bg, (hs - T, hs, 0.0), (-1, 0, 0), (0, 1, 0), HC_SIDE - T, body_h, T,
           cap_left=False, openings=
           [dict(u=3.4, z=0.0, w=1.7, h=2.9, arch=True, pier=2.05, fill="wood",
                 frame=0.16, frame_out=0.05, step=True),
            dict(win, u=5.85)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD)
    # fata +X: doua ferestre distribuite
    facade(b, bglow, bg, (hs, -hs, 0.0), (0, 1, 0), (1, 0, 0), HC_SIDE, body_h, T,
           [dict(win, u=1.7), dict(win, u=4.8)],
           WALL, GLOW, TRIM_WOOD)

    # cornisa + parapet cu coama + terasa retrasa
    for nx, ny, w in ((0, 1, HC_SIDE + 0.5), (0, -1, HC_SIDE + 0.5),
                      (1, 0, HC_SIDE + 0.5), (-1, 0, HC_SIDE + 0.5)):
        rot = Matrix.Rotation(math.atan2(-nx, ny), 3, "Z")
        chajja(b, (nx * hs, ny * hs, body_h), w, 0.4, WALL, thickness=0.12,
               slope=0.5, rotation=rot)
    par_z0, par_z1 = body_h + 0.12, HC_WALL - 0.08
    pt = 0.3
    for (cx, cy, sx, sy) in ((0.0, hs - pt * 0.5, HC_SIDE, pt), (0.0, -hs + pt * 0.5, HC_SIDE, pt),
                             (hs - pt * 0.5, 0.0, pt, HC_SIDE - 2 * pt),
                             (-hs + pt * 0.5, 0.0, pt, HC_SIDE - 2 * pt)):
        b.box((cx, cy, (par_z0 + par_z1) * 0.5), (sx, sy, par_z1 - par_z0), WALL)
    for (cx, cy, sx, sy) in ((0.0, hs - pt * 0.5, HC_SIDE + 0.1, pt + 0.1),
                             (0.0, -hs + pt * 0.5, HC_SIDE + 0.1, pt + 0.1),
                             (hs - pt * 0.5, 0.0, pt + 0.1, HC_SIDE - 2 * pt),
                             (-hs + pt * 0.5, 0.0, pt + 0.1, HC_SIDE - 2 * pt)):
        b.box((cx, cy, HC_WALL - 0.04), (sx, sy, 0.08), WALL)          # coama
    b.box((0.0, 0.0, body_h + 0.2), (HC_SIDE - 2 * pt, HC_SIDE - 2 * pt, 0.16), WALL)  # terasa

    _rooftop_tank(b, (-0.6, -0.4, body_h + 0.28), radius=0.6, height=1.3)
    densify_for_ao(b, max_len=2.5)

    wall_obj = b.to_object("House_Wall")
    trim_obj = _finish_or_none(bg.to_object("House_Trim"))
    glow_obj = _finish_or_none(bglow.to_object("House_Glow"))
    return wall_obj, trim_obj, glow_obj


# --- blue_house_d ------------------------------------------------------------
#
# Contract (brief §1.4): 7x7 m, 2 etaje + camera pe acoperis, 8,5 m, h/l
# 0,88, tenta INDIGO. Element list (decupare blue_house_d.png), de jos in
# sus:
#
#   1. Cub (7x7, 2 etaje, h~6.0) cu usa mare in arc pe fata +X, aproape
#      centrata, cu 2-3 trepte de piatra in fata usii.
#   2. O fereastra mica sus-stanga pe fata +X.
#   3. Terasa cu BALUSTRADA (grilaj negru, nu alba -- decuparea arata un
#      parapet inchis la culoare) pe TOT PERIMETRUL acoperisului.
#   4. Camera mica de pe acoperis, RETRASA spre spate (Y negativ) -- CORECTIE:
#      decuparea (rezasata) arata clar 1 usa (stanga) + 1 fereastra (dreapta)
#      pe fata ei din fata; comentariul vechi "fara geamuri" era o citire
#      gresita a plansei.
HD_SIDE = 7.0
HD_WALL = 6.0
HD_TOTAL = 8.5


def build_blue_house_d():
    b = Builder()
    bg = Builder()
    bglow = Builder()
    br = Builder()
    wall_faces, rail_faces = [], []
    hs = HD_SIDE * 0.5
    WALL_T = 0.5
    h_wall = HD_WALL

    core_hw = hs - WALL_T * 0.5
    wall_faces += list(b.box((0.0, 0.0, h_wall * 0.5), (core_hw * 2, core_hw * 2, h_wall), WALL))
    band = hs - core_hw
    wall_faces += list(b.box((-(hs - band * 0.5), 0.0, h_wall * 0.5), (band, core_hw * 2, h_wall), WALL))
    wall_faces += list(b.box((0.0, (hs - band * 0.5), h_wall * 0.5), (HD_SIDE, band, h_wall), WALL))
    wall_faces += list(b.box((0.0, -(hs - band * 0.5), h_wall * 0.5), (HD_SIDE, band, h_wall), WALL))
    wall_faces += list(b.box((0.0, 0.0, 0.18), (HD_SIDE + 0.18, HD_SIDE + 0.18, 0.36), WALL))

    # usa mare in arc, aproape centrata
    door_rot = Matrix.Rotation(math.radians(-90.0), 3, "Z")
    door_w, door_h = 1.6, 2.8
    door_y = 0.1
    res_door = arch_opening(b, bg, (hs, door_y, 0.0), door_w, door_h,
                            door_h * 0.90, WALL_T, WALL, GLOW, style="round",
                            rotation=door_rot, glass=True, reveal=0.12, glass_depth=0.09,
                            panel_w=2.6, panel_h=door_h * 1.35)
    wall_faces += res_door["stone"]
    for f in res_door["glass"]:
        if f.is_valid:
            f[bg.slot] = TRIM_WOOD
    # 2-3 trepte de piatra in fata usii
    for i, s in enumerate((0.9, 0.6, 0.3)):
        step_y0 = door_y - door_w * 0.5 * s - 0.1
        wall_faces += list(b.box((hs + 0.15 + i * 0.16, door_y, 0.05 + i * 0.0),
                                 (0.16, door_w + 0.4 + i * 0.3, 0.10), WALL))

    # fereastra mica sus-stanga
    win_rot = door_rot
    res_w = arch_opening(b, bglow, (hs, -1.7, h_wall * 0.62 - h_wall * 0.5), 0.7, 1.0,
                         0.32, WALL_T, WALL, GLOW, style="round", rotation=win_rot,
                         glass=True, reveal=0.10, panel_w=1.35, panel_h=1.45)
    wall_faces += res_w["stone"]

    # balustrada NEAGRA (grilaj) pe tot perimetrul acoperisului
    rail_h = 1.0
    rz = h_wall
    corners = [(-hs + 0.15, -hs + 0.15), (hs - 0.15, -hs + 0.15),
              (hs - 0.15, hs - 0.15), (-hs + 0.15, hs - 0.15)]
    for i in range(4):
        p1 = (corners[i][0], corners[i][1], rz)
        p2 = (corners[(i + 1) % 4][0], corners[(i + 1) % 4][1], rz)
        rail_faces += list(railing_on_brackets(br, p1, p2, rail_h, GLOW,
                                               bracket_step=1.4, bracket_out=0.0))

    # camera de pe acoperis, retrasa spre spate (-Y), CU 1 usa (stanga) + 1
    # fereastra (dreapta) pe fata ei din fata (+X) -- corectie: comentariul
    # vechi zicea gresit "fara geamuri", decuparea le arata clar pe amandoua.
    rc_w, rc_d, rc_h = 3.4, 2.8, 2.5
    rc_hw, rc_hd = rc_w * 0.5, rc_d * 0.5
    rc_cy = -hs + rc_d * 0.5 + 0.4
    rc_core_hw = rc_hw - WALL_T * 0.5
    wall_faces += list(b.box((-(rc_hw - rc_core_hw), rc_cy, h_wall + rc_h * 0.5),
                             (rc_core_hw * 2, rc_d, rc_h), WALL))
    wall_faces += list(b.box((0.0, rc_cy, h_wall + 0.05), (rc_w + 0.10, rc_d + 0.10, 0.10), WALL))
    wall_faces += list(b.box((0.0, rc_cy, h_wall + rc_h + 0.06), (rc_w + 0.14, rc_d + 0.14, 0.12), WALL))

    rc_door_w, rc_door_h = 0.8, 1.9
    res_rc_door = arch_opening(b, bg, (rc_hw, rc_cy - 0.6, h_wall), rc_door_w, rc_door_h,
                               rc_door_h * 0.94, WALL_T, WALL, GLOW, style="round",
                               rotation=door_rot, glass=True, reveal=0.09, glass_depth=0.07,
                               panel_w=rc_d * 0.5, panel_h=rc_h)
    wall_faces += res_rc_door["stone"]
    for f in res_rc_door["glass"]:
        if f.is_valid:
            f[bg.slot] = TRIM_WOOD
    res_rc_win = arch_opening(b, bglow, (rc_hw, rc_cy + 0.7, h_wall + 0.4), 0.55, 0.85,
                              0.28, WALL_T, WALL, GLOW, style="round", rotation=door_rot,
                              glass=True, reveal=0.09, panel_w=rc_d * 0.5, panel_h=rc_h * 0.7)
    wall_faces += res_rc_win["stone"]

    wall_obj = b.to_object("House_Wall")
    for f in wall_faces:
        if f.is_valid:
            f[b.slot] = WALL
    trim_obj = _finish_or_none(bg.to_object("House_Trim"))
    glow_obj = _finish_or_none(bglow.to_object("House_Glow"))
    for f in rail_faces:
        if f.is_valid:
            f[br.slot] = GLOW
    rail_obj = _finish_or_none(br.to_object("House_Rail"))

    return wall_obj, trim_obj, glow_obj, rail_obj


# --- blue_house_e ------------------------------------------------------------
#
# Contract (brief §1.4): 7x6 m, 2+1 etaje, 8,5 m, h/l 0,83, tenta light,
# volum in L, scara exterioara pe fata care urca pana la terasa de jos.
#
# Element list (decupare blue_house_e.png, marire x4 -- runda 3 de corectii:
# "ferestre-arcade inghesuite; scara plina alba trebuie sa se citeasca").
# Vazuta din colt, az ~48: fata STANGA = +X, fata DREAPTA = +Y.
#
#   CORPUL MARE (2 etaje, 6 m; X -3,5..1,8, Y -3..2):
#     +Y (dreapta): USA dreptunghiulara de lemn la parter, la mijlocul fetei;
#         deasupra ei, la etaj, o FEREASTRA mica dreptunghiulara de lemn cu
#         glaf; o banda orizontala subtire intre etaje.
#     +X (stanga, in spatele scarii): USA de lemn la ETAJ (z 3), care da pe
#         terasa aripii scunde, chiar in capul scarii.
#     cornisa + parapet; balustrada alba pe marginea +X a acoperisului, in
#     fata camerei de sus.
#   ARIPA SCUNDA (1 etaj, 3 m; in fata fetei +X, capatul -Y): o FEREASTRA
#     mica, inchisa, pe fata ei +X; balustrada alba pe marginea terasei.
#   SCARA PLINA (in fata fetei +X, X 1,8..2,9): masa albastra plina pana la
#     sol (obrazul triunghiular albastru se vede din stanga), TREPTE ALBE
#     (calcai + contratrepte), PARAPET ALB inclinat pe latura exterioara;
#     coboara spre +Y (spre dreapta-jos pe ecran), de pe terasa aripii pana
#     langa coltul corpului mare.
#   CAMERA DE SUS (etajul 3, 2,5 m, retrasa; X -2,8..0,9, Y -0,8..1,7):
#     USA de lemn pe +X, FEREASTRA de lemn pe +Y.
HE_W, HE_D = 7.0, 6.0
HE_TOTAL = 8.5


def _white_stair(b, br, p0, axis, perp, width, run_len, rise_total, n_steps,
                 slot, white):
    """Scara PLINA pe o fata: masa (b, `slot`) in trepte pana la sol, cu
    calcaiele si contratreptele ALBE (br) si un parapet alb inclinat pe
    latura +perp. `p0` = mijlocul muchiei de jos a primei trepte (la sol),
    `axis` = directia de urcare in plan."""
    W = _fx(p0, axis, perp)
    r = run_len / n_steps
    h = rise_total / n_steps
    hw = width * 0.5
    # masa: UN singur solid cu profil in trepte (nu cate o cutie pe treapta --
    # cutiile alaturate lasau rosturi verticale de bevel pe obrazul albastru)
    prof = [(0.0, 0.0)]
    for k in range(n_steps):
        prof += [(k * r, (k + 1) * h), ((k + 1) * r, (k + 1) * h)]
    prof += [(run_len, 0.0)]
    _lprism(b, W, prof, -hw, hw, slot)
    for k in range(n_steps):
        _lbox(br, W, k * r - 0.03, (k + 1) * r + 0.01, (k + 1) * h - 0.02,
              (k + 1) * h + 0.05, -hw - 0.02, hw + 0.02, white)              # calcai
        _lbox(br, W, k * r - 0.03, k * r + 0.02, k * h, (k + 1) * h,
              -hw - 0.02, hw + 0.02, white)                                  # contratreapta
    # parapetul alb, inclinat, pe latura exterioara (+perp)
    L = run_len
    _lprism(br, W, [(-0.05, 0.0), (L, rise_total), (L, rise_total + 0.75),
                    (-0.05, 0.75)], hw, hw + 0.16, white)


def build_blue_house_e():
    b = Builder()
    bg = Builder()
    bglow = Builder()
    br = Builder()
    T = 0.3
    rail = RAIL_WHITE

    # --- corpul mare
    mx0, mx1, my0, my1 = -3.5, 1.8, -3.0, 2.0
    m_h = 6.0
    b.box(((mx0 + mx1 - T) * 0.5, (my0 + my1 - T) * 0.5, m_h * 0.5),
          (mx1 - mx0 - T, my1 - my0 - T, m_h), WALL)
    b.box(((mx0 + mx1) * 0.5, (my0 + my1) * 0.5, 0.13), (mx1 - mx0 + 0.1, my1 - my0 + 0.1, 0.26), WALL)
    facade(b, bglow, bg, (mx1, my0, 0.0), (0, 1, 0), (1, 0, 0), my1 - my0, m_h, T,
           openings=[dict(u=2.1, z=3.0, w=0.85, h=2.0, fill="wood", frame=0.08)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD)
    wy = mx1 - T - mx0
    facade(b, bglow, bg, (mx1 - T, my1, 0.0), (-1, 0, 0), (0, 1, 0), wy, m_h, T,
           openings=[dict(u=2.6, z=0.0, w=1.15, h=2.25, fill="wood", frame=0.1),
                     dict(u=2.6, z=3.75, w=0.65, h=0.9, fill="shutter", frame=0.07, sill=True)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD, cap_left=False)
    # banda subtire intre etaje pe +Y
    b.box(((mx0 + mx1) * 0.5, my1 + 0.04, 3.0), (mx1 - mx0, 0.1, 0.12), WALL)
    mcx, mcy = (mx0 + mx1) * 0.5, (my0 + my1) * 0.5
    for nx, ny, w in ((0, 1, mx1 - mx0 + 0.6), (0, -1, mx1 - mx0 + 0.6),
                      (1, 0, my1 - my0 + 0.6), (-1, 0, my1 - my0 + 0.6)):
        rot = Matrix.Rotation(math.atan2(-nx, ny), 3, "Z")
        chajja(b, (mcx + nx * (mx1 - mx0) * 0.5, mcy + ny * (my1 - my0) * 0.5, m_h),
               w, 0.3, WALL, thickness=0.12, slope=0.5, rotation=rot)
    b.box((mcx, mcy, m_h + 0.2), (mx1 - mx0, my1 - my0, 0.28), WALL)
    # balustrada alba pe marginea +X a acoperisului, in fata camerei
    rz = m_h + 0.34
    br.railing((mx1 - 0.12, my0 + 0.1, rz), (mx1 - 0.12, -0.8, rz), 0.85, 0.7, 0.06, 0.05, rail, rails=2)

    # --- aripa scunda, in fata fetei +X, capatul -Y
    lx0, lx1, ly0, ly1 = mx1, 3.5, my0, -0.6
    l_h = 3.0
    b.box(((lx0 + lx1 - T) * 0.5, (ly0 + ly1) * 0.5, l_h * 0.5), (lx1 - lx0 - T, ly1 - ly0, l_h), WALL)
    facade(b, bglow, bg, (lx1, ly0, 0.0), (0, 1, 0), (1, 0, 0), ly1 - ly0, l_h, T,
           openings=[dict(u=0.95, z=0.85, w=0.45, h=0.9, fill="glow", frame=0.05)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD)
    b.box(((lx0 + lx1) * 0.5 + 0.05, (ly0 + ly1) * 0.5, l_h + 0.06), (lx1 - lx0 + 0.1, ly1 - ly0 + 0.1, 0.12), WALL)
    rz = l_h + 0.12
    br.railing((lx1 - 0.06, ly0 + 0.1, rz), (lx1 - 0.06, ly1 - 0.05, rz), 0.85, 0.6, 0.06, 0.05, rail, rails=2)

    # --- scara plina alba: urca spre -Y pana pe terasa aripii
    st_w = 1.35
    sx = mx1 + st_w * 0.5
    n_steps = 13
    run_len = n_steps * 0.27
    _white_stair(b, br, (sx, ly1 + run_len, 0.0), (0, -1, 0), (1, 0, 0), st_w, run_len,
                 l_h, n_steps, WALL, rail)

    # --- camera de sus
    rx0, rx1, ry0, ry1 = -2.8, 0.9, -0.8, 1.7
    r_h = HE_TOTAL - m_h - 0.14
    z0 = m_h + 0.34
    b.box(((rx0 + rx1 - T) * 0.5, (ry0 + ry1 - T) * 0.5, z0 + r_h * 0.5), (rx1 - rx0 - T, ry1 - ry0 - T, r_h), WALL)
    facade(b, bglow, bg, (rx1, ry0, z0), (0, 1, 0), (1, 0, 0), ry1 - ry0, r_h, T,
           openings=[dict(u=1.0, z=0.0, w=0.7, h=1.85, fill="wood", frame=0.07)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD)
    facade(b, bglow, bg, (rx1 - T, ry1, z0), (-1, 0, 0), (0, 1, 0), rx1 - T - rx0, r_h, T,
           openings=[dict(u=2.0, z=0.35, w=0.75, h=1.3, fill="shutter", frame=0.07)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD, cap_left=False)
    b.box(((rx0 + rx1) * 0.5, (ry0 + ry1) * 0.5, z0 + r_h + 0.07), (rx1 - rx0 + 0.25, ry1 - ry0 + 0.25, 0.14), WALL)

    densify_for_ao(b, max_len=2.5)
    wall_obj = b.to_object("House_Wall")
    trim_obj = _finish_or_none(bg.to_object("House_Trim"))
    glow_obj = _finish_or_none(bglow.to_object("House_Glow"))
    rail_obj = _finish_or_none(br.to_object("House_Rail"))
    return wall_obj, trim_obj, glow_obj, rail_obj


# --- haveli_facade -------------------------------------------------------------
#
# Contract (brief §1.4): 10x6 m, 3 etaje, 11 m, h/l 0,92, <=900 tri, casa
# bogata: arcade pe parter, balcoane de piatra, ferestre in arc, balustrada pe
# terasa.
#
# Element list (decupare haveli_facade.png, marire x4 -- runda 3 de corectii:
# "albastru-marin in loc de deschis, usi maro in loc de geamuri, arcade in
# Y"). Vazuta aproape din fata, az ~60: fata LATA (10 m) = +Y, frontala;
# latura de 6 m = +X, in fuga, la stanga. Pozitiile pe fata +Y sunt date ca
# u = metri de la coltul STANG (X = +5).
#
#   PARTER (0..3,8 m), de la stanga la dreapta:
#     1. fereastra ARCUITA inchisa (u 1,7, ~1 x 2 m), rama subtire;
#     2. doua ARCADE ROTUNDE mari, deschise, cu usi de lemn in fund (u 3,95 si
#        6,3, ~1,6 x 2,8 m) -- arce adevarate, nu bare in Y;
#     3. fereastra ARCUITA (u 8,5), pereche cu 1.; pilastri subtiri intre
#        travee; cornisa peste parter.
#   ETAJUL 1 (3,8..8,2 m):
#     4. JHAROKHA centrala (u 3,2..8,1): cutie iesita ~0,8 m pe console, cu
#        3 ARCE pe fata (cel din mijloc mai lat), BALCON cu balustrada cu
#        baluștri in fata lor si streasina lata deasupra;
#     5. cate o fereastra ARCUITA inchisa de o parte si de alta (u 1,6 / 8,55).
#   TERASA (8,2..9,6 m): cornisa, parapet cu baluștri deschisi intre stalpi
#     cu varf; CHHATRI mic (pavilion pe 4 stalpi cu cupolita) pe coltul
#     stanga-fata.
#   LATURA +X: fereastra arcuita la parter, doua ferestre inalte la etaj si
#     un balconas iesit sub ele.
#   Culoare: decuparea e albastru DESCHIS (#7896DE pe fata luminata), nu
#     indigo -- vezi nota din inventar (tenta la integrare).
#
# BUGET: brief-ul cere <= 900 tri. Lista de elemente de mai sus NU incape in
# 900: doar cele 9 goluri arcuite cu rame costa ~1400. Construit corect,
# cifra si motivul in verify_jodhpur.sh -- liderul decide.
HV_W, HV_D = 10.0, 6.0
HV_H = 11.0
HV_BUDGET = 4900


def _baluster_run(b, W, u0, u1, z, h, d0, d1, slot, step=0.28):
    """Balustrada cu baluștri in coordonatele unei fete: soclu, baluștri
    patrati, mana curenta."""
    faces = _lbox(b, W, u0, u1, z, z + 0.14, d0, d1, slot)
    n = max(int((u1 - u0) / step), 1)
    t = (d1 - d0) * 0.45
    dm = (d0 + d1) * 0.5
    for i in range(n):
        uc = u0 + (u1 - u0) * (i + 0.5) / n
        faces += _lbox(b, W, uc - 0.06, uc + 0.06, z + 0.14, z + h - 0.1, dm - t * 0.5, dm + t * 0.5, slot)
    faces += _lbox(b, W, u0, u1, z + h - 0.1, z + h, d0 - 0.02, d1 + 0.02, slot)
    return faces


def build_haveli_facade():
    b = Builder()
    bg = Builder()
    bglow = Builder()
    # fata lata e +Y: latimea de 10 m pe X, adancimea de 6 m pe Y
    hx, hy = HV_W * 0.5, HV_D * 0.5
    T = 0.35
    g_h, f1_h = 3.8, 8.2
    ter_z = f1_h + 0.2

    # miezul, retras pe +Y si +X (fetele cu goluri)
    b.box((-T * 0.5, -T * 0.5, ter_z * 0.5), (HV_W - T, HV_D - T, ter_z), WALL)
    b.box((0.0, 0.0, 0.15), (HV_W + 0.14, HV_D + 0.14, 0.3), WALL)

    arch_w = dict(arch=True, style="round", fill="glow", frame=0.08, frame_out=0.05)
    # --- fata +Y (lata), u de la X=+5-T spre -X
    WY0 = (hx - T, hy, 0.0)
    ground = [dict(arch_w, u=1.7 - T, z=0.45, w=1.0, h=2.1, pier=1.6, sill=True),
              dict(u=3.95 - T, z=0.0, w=1.6, h=2.9, arch=True, style="round", pier=2.1,
                   fill="wood", frame=0.12, frame_out=0.06, reveal=0.3),
              dict(u=6.3 - T, z=0.0, w=1.7, h=2.95, arch=True, style="round", pier=2.1,
                   fill="wood", frame=0.12, frame_out=0.06, reveal=0.3),
              dict(arch_w, u=8.5 - T, z=0.45, w=1.0, h=2.1, pier=1.6, sill=True)]
    facade(b, bglow, bg, WY0, (-1, 0, 0), (0, 1, 0), HV_W - T, g_h, T, openings=ground,
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD, steps=6, cap_left=False)
    first = [dict(arch_w, u=1.6 - T, z=1.1, w=1.0, h=2.0, pier=1.5, sill=True),
             dict(arch_w, u=8.65 - T, z=1.1, w=0.95, h=2.0, pier=1.5, sill=True)]
    facade(b, bglow, bg, (hx - T, hy, g_h), (-1, 0, 0), (0, 1, 0), HV_W - T, ter_z - g_h, T,
           openings=first, slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD, steps=6, cap_left=False)
    WY = _fx(WY0, (-1, 0, 0), (0, 1, 0))
    # pilastri subtiri intre travee (parter) + cornisa peste parter
    for pu in (2.75, 5.15, 7.45):
        _lbox(b, WY, pu - 0.14 - T, pu + 0.14 - T, 0.3, g_h - 0.1, 0.0, 0.1, WALL)
    chajja(b, (0.0, hy, g_h - 0.05), HV_W + 0.2, 0.35, WALL, thickness=0.14, slope=0.5)

    # --- jharokha centrala (etaj 1)
    ju0, ju1 = 3.1 - T, 7.7 - T
    jd = 0.85
    j_z0, j_z1 = g_h + 0.15, 7.3
    jx0, jx1 = hx - T - ju1, hx - T - ju0          # in X
    # console sub planseu
    for cu in (ju0 + 0.3, (ju0 + ju1) * 0.5, ju1 - 0.3):
        cxw = hx - T - cu
        b.beam((cxw, hy, j_z0 - 0.7), (cxw, hy + jd, j_z0 - 0.02), (0.2, 0.2), WALL)
    _lbox(b, WY, ju0 - 0.1, ju1 + 0.1, j_z0 - 0.2, j_z0, 0.0, jd + 0.15, WALL)     # planseul balconului
    # fata jharokha-ei: 3 arce (mijlocul mai lat)
    JW0 = (jx1, hy + jd, j_z0)
    jw = ju1 - ju0
    facade(b, bglow, bg, JW0, (-1, 0, 0), (0, 1, 0), jw, j_z1 - j_z0, 0.25,
           openings=[dict(arch_w, u=0.85, z=0.95, w=0.85, h=2.0, pier=1.45),
                     dict(arch_w, u=jw * 0.5, z=0.95, w=1.3, h=2.15, pier=1.45),
                     dict(arch_w, u=jw - 0.85, z=0.95, w=0.85, h=2.0, pier=1.45)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD, steps=6)
    # laturile jharokha-ei
    b.box((jx0 + 0.12, hy + jd * 0.5, (j_z0 + j_z1) * 0.5), (0.24, jd, j_z1 - j_z0), WALL)
    b.box((jx1 - 0.12, hy + jd * 0.5, (j_z0 + j_z1) * 0.5), (0.24, jd, j_z1 - j_z0), WALL)
    # balconul cu baluștri in fata arcelor
    WJ = _fx(JW0, (-1, 0, 0), (0, 1, 0))
    _baluster_run(b, WJ, -0.05, jw + 0.05, 0.0, 0.85, 0.02, 0.17, WALL, step=0.42)
    # streasina lata peste jharokha + mic parapet
    chajja(b, ((jx0 + jx1) * 0.5, hy + jd, j_z1), jw + 0.5, 0.55, WALL, thickness=0.16, slope=0.5)
    _lbox(b, WY, ju0 - 0.15, ju1 + 0.15, j_z1 + 0.16, j_z1 + 0.5, 0.0, jd + 0.2, WALL)

    # --- latura +X (6 m), u de la Y=-3 spre +Y
    WX0 = (hx, -hy, 0.0)
    facade(b, bglow, bg, WX0, (0, 1, 0), (1, 0, 0), HV_D, g_h, T,
           openings=[dict(arch_w, u=3.3, z=0.45, w=0.95, h=2.1, pier=1.6, sill=True)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD, steps=6)
    facade(b, bglow, bg, (hx, -hy, g_h), (0, 1, 0), (1, 0, 0), HV_D, ter_z - g_h, T,
           openings=[dict(u=2.4, z=1.4, w=0.6, h=1.8, fill="glow", frame=0.06),
                     dict(u=4.1, z=1.4, w=0.6, h=1.8, fill="glow", frame=0.06)],
           slot=WALL, glow_slot=GLOW, trim_slot=TRIM_WOOD, steps=6)
    chajja(b, (hx, 0.0, g_h - 0.05), HV_D + 0.2, 0.35, WALL, thickness=0.14, slope=0.5,
           rotation=Matrix.Rotation(math.radians(-90), 3, "Z"))
    WX = _fx(WX0, (0, 1, 0), (1, 0, 0))
    _lbox(b, WX, 1.9, 4.6, g_h + 0.25, g_h + 0.45, 0.0, 0.6, WALL)                 # balconas
    _baluster_run(b, WX, 1.9, 4.6, g_h + 0.45, 0.7, 0.45, 0.6, WALL, step=0.5)

    # --- cornisa de sus + terasa cu baluștri intre stalpi cu varf
    for nx, ny, w in ((0, 1, HV_W + 0.6), (0, -1, HV_W + 0.6), (1, 0, HV_D + 0.6), (-1, 0, HV_D + 0.6)):
        rot = Matrix.Rotation(math.atan2(-nx, ny), 3, "Z")
        chajja(b, (nx * hx, ny * hy, ter_z - 0.2), w, 0.4, WALL, thickness=0.18, slope=0.5,
               rotation=rot)
    pz = ter_z
    WYt = _fx((hx, hy, pz), (-1, 0, 0), (0, 1, 0))
    WXt = _fx((hx, -hy, pz), (0, 1, 0), (1, 0, 0))
    WMY = _fx((-hx, -hy, pz), (1, 0, 0), (0, -1, 0))
    WMX = _fx((-hx, hy, pz), (0, -1, 0), (-1, 0, 0))
    piers_y = [0.0, 3.3, 6.6, HV_W]
    for Wt, L, piers in ((WYt, HV_W, piers_y), (WXt, HV_D, [0.0, HV_D]),
                         (WMY, HV_W, [0.0, HV_W]), (WMX, HV_D, [0.0, HV_D])):
        for pa, pb in zip(piers, piers[1:]):
            _baluster_run(b, Wt, pa + 0.2, pb - 0.2, 0.0, 1.0, -0.3, -0.05, WALL, step=0.45)
        for pu in piers:
            _lbox(b, Wt, pu - 0.22, pu + 0.22, 0.0, 1.35, -0.4, 0.04, WALL)
            _lbox(b, Wt, pu - 0.14, pu + 0.14, 1.35, 1.6, -0.32, -0.04, WALL)

    # --- chhatri mic pe coltul stanga-fata
    cx, cy = hx - 1.3, hy - 1.0
    ch_h = 1.7
    for sx in (-0.55, 0.55):
        for sy in (-0.45, 0.45):
            b.box((cx + sx, cy + sy, pz + ch_h * 0.5), (0.18, 0.18, ch_h), WALL)
    WC = _fx((cx + 0.64, cy + 0.45, pz), (-1, 0, 0), (0, 1, 0))
    # arc pe fata chhatri-ului (banda de arc intre stalpii din fata)
    _lband(b, WC, _opening_contour(dict(u=0.64, z=0.0, w=0.92, h=ch_h - 0.05, arch=True,
                                        pier=ch_h - 0.5), 6), 0.08, -0.12, 0.0, WALL)
    chajja(b, (cx, cy + 0.45, pz + ch_h), 1.5, 0.3, WALL, thickness=0.12, slope=0.5)
    b.box((cx, cy, pz + ch_h + 0.06), (1.4, 1.2, 0.12), WALL)
    dome(b, (cx, cy, pz + ch_h + 0.12), 0.5, WALL, segments=8, lotus_ring=False,
         finial=True, finial_h=0.4)

    densify_for_ao(b, max_len=3.0)
    wall_obj = b.to_object("House_Wall")
    trim_obj = _finish_or_none(bg.to_object("House_Trim"))
    glow_obj = _finish_or_none(bglow.to_object("House_Glow"))
    return wall_obj, trim_obj, glow_obj


# --- props/rooftop_tank --------------------------------------------------------
#
# Contract (brief §1.4): Ø1,2 x 1,4 m, tenta -- (nod unic). Element list
# (decupare rooftop_tank.png): un singur cilindru negru cu nervuri
# orizontale (3-4 vizibile) si un capac usor bombat -- fara alt detaliu.
def build_rooftop_tank():
    b = Builder()
    faces = _rooftop_tank(b, (0.0, 0.0, 0.0), radius=0.6, height=1.1, n_ribs=4)
    obj = b.to_object("Tank_Body")
    for f in faces:
        if f.is_valid:
            f[b.slot] = TANK_DARK
    return (obj,)


# --- props/rooftop_clutter ------------------------------------------------------
#
# Contract (brief §1.4): placa 3x2,5 m, stalpi 1,8 m, tenta light. Element
# list (decupare rooftop_clutter.png), de jos in sus:
#
#   1. Placa de terasa (albastra, WALL) 3x2,5 m.
#   2. Rezervor mic negru in coltul STANGA-SPATE al placii.
#   3. Doua gramezi de oale/lucruri (culoare piatra/lemn) langa rezervor,
#      spre mijloc/dreapta.
#   4. 2 stalpi de lemn, unul langa altul pe latura din SPATE, cu o sfoara
#      intinsa intre ei -- 2 rufe atarnate: una GALBENA (stanga), una ROZ
#      (dreapta).
RC_W, RC_D = 3.0, 2.5
RC_POST_H = 1.8


def build_rooftop_clutter():
    b = Builder()
    bl = Builder()  # rufele (culori saturate, sloturi de accent, allow-car-slots)
    # NOTA fix (bug real gasit la primul --compare al valului 3): fetele nu
    # se mai aduna intr-o singura lista `faces` pictata orbeste WALL la
    # final -- placa, rezervorul, oalele si stalpii/sfoara sunt pe sloturi
    # DIFERITE (WALL, TANK_DARK, WOOD, LOG_DARK), dar overwrite-ul vechi
    # (`f[b.slot] = WALL` pe toata lista) le picta pe toate albastru,
    # exact ce a aratat comparatia (rezervor + oale + stalpi, toate
    # albastre in loc de negru/lemn). Acum fiecare grup isi pastreaza
    # slotul propriu, scris o singura data.
    hw, hd = RC_W * 0.5, RC_D * 0.5

    # placa de terasa
    plate_faces = list(b.box((0.0, 0.0, 0.08), (RC_W, RC_D, 0.16), WALL))

    # rezervor mic negru, colt stanga-spate (X negativ, Y negativ).
    # segments 12->8, n_ribs 3->2 (buget: masurat izolat 476->336 tri --
    # asta e piesa DECORATIVA de fundal, nu props/rooftop_tank.glb propriu-
    # zis, care ramane la 12 segmente; brief §1 cere doar 8-16, nu maxim)
    tank_faces = _rooftop_tank(b, (-hw + 0.5, -hd + 0.5, 0.16), radius=0.35, height=0.55,
                               n_ribs=2, )

    # 2 gramezi de oale (piatra/lemn), spre mijloc/dreapta (segments 8->6,
    # buget: minor dar consistent cu restul reducerilor din piesa asta)
    pot_faces = []
    for i, (px, py) in enumerate(((0.1, -hd + 0.5), (0.65, -hd + 0.55))):
        for k in range(3):
            r = 0.16 - k * 0.02
            pot_faces += list(b.cylinder((px + k * 0.05, py, 0.16 + r + k * 0.06), r,
                                         0.14, WOOD, segments=6, axis="Z"))

    # 2 stalpi pe latura din spate (Y negativ e "spate" fata de +X camera;
    # dar rufele trebuie sa fie vizibile din fata -- le punem pe latura din
    # FATA/+Y, ca sa fie clar vizibile in comparatie, la fel ca decuparea
    # care arata rufele in prim-plan). segments 8->6 (stalpi subtiri,
    # diferenta de silueta nula la aceasta raza).
    post_x0, post_x1 = -hw + 0.3, hw - 0.3
    post_y = hd - 0.25
    post_faces = list(b.cylinder((post_x0, post_y, 0.16 + RC_POST_H * 0.5), 0.06, RC_POST_H,
                                 LOG_DARK, segments=6, axis="Z"))
    post_faces += list(b.cylinder((post_x1, post_y, 0.16 + RC_POST_H * 0.5), 0.06, RC_POST_H,
                                  LOG_DARK, segments=6, axis="Z"))
    # sfoara (fir subtire) intre stalpi
    post_faces += list(b.box((0.0, post_y, 0.16 + RC_POST_H - 0.02), (post_x1 - post_x0, 0.02, 0.02), LOG_DARK))

    # 2 rufe atarnate pe sfoara: galben (stanga), roz (dreapta) -- panza
    # opaca cu usoara lasare (blade pe un traseu in catenara aproximativa).
    # segs 4->2 (buget: jumatate din geometria panzei, lasarea tot se
    # citeste ca o usoara curba pe o piesa de 0.55x0.7m la distanta jocului)
    def _cloth(cx, color):
        w = 0.55
        h = 0.7
        sag = 0.05
        path = [(cx - w * 0.5, post_y, 0.16 + RC_POST_H - 0.02 - sag * t * (1 - t) * 4)
               for t in (0.0, 0.5, 1.0)]
        # panza plata verticala: folosim box-uri suprapuse in loc de sweep,
        # mai simplu si suficient pentru o piesa mica -- placa unica usor
        # curbata (2 segmente) atarnand de sfoara
        segs = 2
        cf = []
        for k in range(segs):
            t0, t1 = k / segs, (k + 1) / segs
            y0 = post_y - 0.02 - t0 * 0.01
            y1 = post_y - 0.02 - t1 * 0.01
            z0 = 0.16 + RC_POST_H - 0.02 - h * t0
            z1 = 0.16 + RC_POST_H - 0.02 - h * t1
            cf += list(bl.box((cx, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
                              (w, 0.02, h / segs + 0.01), color))
        return cf
    laundry_faces = []
    laundry_faces += _cloth(post_x0 + (post_x1 - post_x0) * 0.28, LAUNDRY_YELLOW)
    laundry_faces += _cloth(post_x0 + (post_x1 - post_x0) * 0.72, LAUNDRY_PINK)

    obj = b.to_object("Clutter_Base")
    for f in plate_faces:
        if f.is_valid:
            f[b.slot] = WALL
    for f in tank_faces:
        if f.is_valid:
            f[b.slot] = TANK_DARK
    for f in pot_faces:
        if f.is_valid:
            f[b.slot] = WOOD
    for f in post_faces:
        if f.is_valid:
            f[b.slot] = LOG_DARK
    laundry_obj = _finish_or_none(bl.to_object("Clutter_Laundry"))
    return obj, laundry_obj


# --- emit ----------------------------------------------------------------------

clear_built()
results = []


def emit(objs, path, ao, origin="base", bevel=0.03, smooth_angle=45.0,
         budget=None, allow_car_slots=None, bevel_angle=30.0):
    """Identic cu `emit` din build_jodhpur_pilot.py."""
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
        st = finish(o, bevel=bevel, bevel_angle=bevel_angle, ao=ao,
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


hb = build_blue_house_b()
emit(list(hb), "buildings/blue_house_b.glb", AO_HOUSE, bevel=0.025, budget=6000)

hc = build_blue_house_c()
emit(list(hc), "buildings/blue_house_c.glb", AO_HOUSE, bevel=0.025, budget=3800)

hd_ = build_blue_house_d()
emit(list(hd_), "buildings/blue_house_d.glb", AO_HOUSE, bevel=0.025, budget=6500)

he = build_blue_house_e()
emit(list(he), "buildings/blue_house_e.glb", AO_HOUSE, bevel=0.025, budget=6500)

hv = build_haveli_facade()
# bevel 0 pe haveli (runda 3): bevel-ul de 2 cm tripla cifra (3908 -> 11502
# masurat) pe o piesa plina de baluștri si rame mici, invizibil la 30 m.
emit(list(hv), "buildings/haveli_facade.glb", AO_HOUSE, bevel=0.0, budget=HV_BUDGET)

tank = build_rooftop_tank()
emit(list(tank), "props/rooftop_tank.glb", AO_PROP, bevel=0.02, budget=700)

clutter = build_rooftop_clutter()
emit(list(clutter), "props/rooftop_clutter.glb", AO_PROP, bevel=0.02, budget=1400)

print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-40s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL orasul: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([o for pieces in (hb, hc, hd_, he, hv, tank, clutter) for o in pieces if o is not None],
          "jodhpur_city.blend")
