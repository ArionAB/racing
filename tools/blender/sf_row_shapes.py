"""Vocabularul de forme al kitului de case de rand victoriene (San Francisco).

Contractul e `docs/asset_briefs/sf_painted_row_kit.md` (§1-§10). Fisierul asta
nu construieste nicio casa: da piesele din care `build_sf_row.py` le compune pe
toate sapte (pilotul e `sf_row_b_canted`). Se incarca prin `exec` dupa dio_lib
(acelasi tipar ca jodhpur_shapes.py), deci vede `snapshot_slots`, `apply_bevel`,
`assign_uvs`, `apply_smooth`, `atlas_material`, `slot_u` si sloturile.

Axe (dio_lib, nota de antet): Blender +Y = Godot -Z. Fatada casei sta deci pe
Blender **Y = +6.0** si priveste spre +Y; spatele e la Y = -6.0; X e acelasi in
ambele; Z (Blender) = Y (Godot), sus. Originea e centrul amprentei la cota
podelei parterului: NIMIC nu se re-centreaza la export (fusta coboara la -2.4).

De ce nu `Builder` din dio_lib: `Builder.to_object` cheama
`recalc_face_normals`, care pe fete izolate (un geam, o banda de fronton, o fata
de perete fara spate) poate intoarce normala pe dos. Aici fiecare fata isi
primeste orientarea explicit (`out`), iar piesele inchise o deduc din centroid.
Asta ne lasa sa NU construim fetele ascunse (spatele ramelor lipite de perete,
talpa fustei), adica triunghiurile care nu se vad niciodata.

Grupuri: fiecare nod (Row_Wall / Row_Trim) are doua grupuri de geometrie,
`flat` (fara bevel: ferestre, panouri, tot ce e lipit de perete) si `bev`
(bevel 0.08 pe muchiile de silueta: cornisele, bovindoul, bordura frontonului,
acoperisul). Bevelul costa ~3.7x pe o cutie, deci se pune doar unde face silueta
(brief §7-§8).
"""

import bmesh  # noqa: F401  (pastrat pentru consumatori care lucreaza pe bmesh)
import bpy
import math
from mathutils import Vector
from mathutils.bvhtree import BVHTree

# --- Cotele comune (brief §3.1) ----------------------------------------------
HX = 3.5            # semi-latimea amprentei (X de la -3.5 la +3.5)
YF = 6.0            # planul fatadei (Godot Z = -6.0)
YB = -6.0           # spatele (Godot Z = +6.0)
# Peretele din spate sta cu 5 cm in interior, ca ferestrele plate si banda de
# streasina din spate sa nu treaca de Godot Z = +6.0 (casele se lipesc spate
# in spate la 12,0 m, inventarul §1.2); acoperisul ramane la -6.0.
YBW = YB + 0.05
LEVEL = 3.2         # inaltimea unui nivel
EAVE = 9.6          # streasina
SKIRT = -2.4        # fundul fustei
BEVEL_W = 0.08      # bevel de cladire (blender_export.md §5, brief §7)

# sloturi folosite de kit (brief §5); numele locale ca sa nu depinda de alias-uri
S_WALL = 19         # coral_sand: scandura, nodul Row_Wall (tenta o da jocul)
S_WHITE = 22        # foam_white: ancadramente, cornise, console, brau, colturi
S_DARK = 20         # volcanic_black: acoperis, sticla
S_STONE = 8         # concrete: fusta, parterul de piatra, treptele
S_GARAGE = 9        # wood_weathered: usa de garaj
S_NICHE = 28        # log_dark: usa de intrare, interiorul nisei

UP = Vector((0.0, 0.0, 1.0))
XP = Vector((1.0, 0.0, 0.0))
YP = Vector((0.0, 1.0, 0.0))


def V(x, y, z):
    return Vector((x, y, z))


def _newell(pts):
    n = Vector((0.0, 0.0, 0.0))
    for i, p in enumerate(pts):
        q = pts[(i + 1) % len(pts)]
        n.x += (p.y - q.y) * (p.z + q.z)
        n.y += (p.z - q.z) * (p.x + q.x)
        n.z += (p.x - q.x) * (p.y + q.y)
    return n


class Part:
    """Geometrie in curs pentru UN grup (nod x bevel). Fiecare piesa isi are
    varfurile ei (piesele nu se sudeaza intre ele), deci bevelul vede doar
    muchiile piesei, iar AO-ul pe colturi nu se amesteca intre piese."""

    def __init__(self, bevel=False):
        self.verts = []
        self.faces = []
        self.slots = []
        self.bevel = bevel

    def piece(self, verts, faces, slot, outs=None, center=None):
        """Piesa cu varfuri comune. `outs[k]` = directia spre exterior a fetei
        k; fara `outs`, orientarea se deduce din centroidul piesei (corect doar
        pentru piese convexe)."""
        vs = [Vector(v) for v in verts]
        c = Vector(center) if center is not None else sum(vs, Vector()) / len(vs)
        base = len(self.verts)
        for k, f in enumerate(faces):
            pts = [vs[i] for i in f]
            n = _newell(pts)
            if outs is not None:
                ref = Vector(outs[k])
            else:
                ref = sum(pts, Vector()) / len(pts) - c
            f = list(f)
            if n.dot(ref) < 0.0:
                f.reverse()
            self.faces.append([base + i for i in f])
            self.slots.append(slot[k] if isinstance(slot, (list, tuple)) else slot)
        self.verts.extend(vs)

    def face(self, pts, slot, out):
        self.piece(pts, [list(range(len(pts)))], slot, outs=[out])

    def rect(self, o, u, v, a0, a1, b0, b1, slot, out):
        """Dreptunghi in planul (o, u, v): u in [a0, a1], v in [b0, b1]."""
        self.face([o + u * a0 + v * b0, o + u * a1 + v * b0,
                   o + u * a1 + v * b1, o + u * a0 + v * b1], slot, out)

    def obox(self, c, u, v, w, hu, hv, hw, slot, skip=()):
        """Cutie orientata pe axele (u, v, w), semi-dimensiuni (hu, hv, hw).
        `skip` = fetele de omis, numite '+u','-u','+v','-v','+w','-w' (fata
        lipita de perete nu se construieste)."""
        c = Vector(c)
        vs = []
        for i in range(8):
            su = 1 if i & 1 else -1
            sv = 1 if i & 2 else -1
            sw = 1 if i & 4 else -1
            vs.append(c + u * (su * hu) + v * (sv * hv) + w * (sw * hw))
        named = {"+u": [1, 3, 7, 5], "-u": [0, 4, 6, 2], "+v": [2, 6, 7, 3],
                 "-v": [0, 1, 5, 4], "+w": [4, 5, 7, 6], "-w": [0, 2, 3, 1]}
        faces = [f for k, f in named.items() if k not in skip]
        self.piece(vs, faces, slot, center=c)

    def box(self, lo, hi, slot, skip=()):
        """Cutie pe axe intre colturile lo/hi. skip cu nume de axe: '+X','-Y'..."""
        lo, hi = Vector(lo), Vector(hi)
        c = (lo + hi) * 0.5
        h = (hi - lo) * 0.5
        m = {"+X": "+u", "-X": "-u", "+Y": "+v", "-Y": "-v", "+Z": "+w", "-Z": "-w"}
        self.obox(c, XP, YP, UP, h.x, h.y, h.z, slot, skip=[m[s] for s in skip])

    def prism(self, outline, e, slot, cap0=True, cap1=True, skip_sides=()):
        """Prisma convexa: conturul `outline` (puncte 3D intr-un plan) extrus cu
        vectorul `e`. `skip_sides` = indicii laturilor omise (latura i merge de
        la punctul i la i+1)."""
        e = Vector(e)
        n = len(outline)
        bot = [Vector(p) for p in outline]
        top = [p + e for p in bot]
        vs = bot + top
        faces = []
        if cap0:
            faces.append(list(range(n)))
        if cap1:
            faces.append(list(range(n, 2 * n)))
        for i in range(n):
            if i in skip_sides:
                continue
            j = (i + 1) % n
            faces.append([i, j, n + j, n + i])
        self.piece(vs, faces, slot)

    def to_object(self, name):
        """Mesh nou, cu stratul int `slot` pe fete (citit de snapshot_slots).
        Varfurile nefolosite (fetele omise) se scot, ca sa nu ramana puncte."""
        used = sorted({i for f in self.faces for i in f})
        remap = {old: new for new, old in enumerate(used)}
        verts = [tuple(self.verts[i]) for i in used]
        faces = [[remap[i] for i in f] for f in self.faces]
        me = bpy.data.meshes.new(name)
        me.from_pydata(verts, [], faces)
        attr = me.attributes.new("slot", "INT", "FACE")
        for k, s in enumerate(self.slots):
            attr.data[k].value = s
        me.update()
        obj = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(obj)
        return obj


class House:
    """O casa in lucru: doua noduri x doua grupuri. Toate functiile de forma de
    mai jos primesc o `House` si scriu in grupul potrivit."""

    def __init__(self, name, hx=HX):
        self.name = name
        self.hx = hx                           # semi-latimea (3,5; colt 4,5)
        self.wall = Part(bevel=False)          # scandura: niciodata bevel
        self.trim = Part(bevel=False)          # atlas, fara bevel
        self.trim_bev = Part(bevel=True)       # atlas, cu bevel de silueta
        self.notes = []


# --- Primitive de fatada -----------------------------------------------------

def frame_ring(p, c, u, n, z0, w, h, fw, proud, slot=S_WHITE, back=0.012, open_bottom=False):
    """Rama de fereastra/usa: inel cu fata, laturi exterioare si glaf interior
    (glaful coboara pana la planul geamului, `back` in fata peretelui). Fara
    spate (e lipita de perete). 24 de triunghiuri."""
    xo, xi = w * 0.5, w * 0.5 - fw
    zo0, zo1 = z0, z0 + h
    zi0, zi1 = (z0 if open_bottom else z0 + fw), z0 + h - fw

    def P(x, y, z):
        return c + u * x + n * y + UP * z

    yf = proud
    # fata ramei (4 trapeze)
    if not open_bottom:
        p.face([P(-xo, yf, zo0), P(xo, yf, zo0), P(xi, yf, zi0), P(-xi, yf, zi0)], slot, n)
    p.face([P(xo, yf, zo0), P(xo, yf, zo1), P(xi, yf, zi1), P(xi, yf, zi0)], slot, n)
    p.face([P(xo, yf, zo1), P(-xo, yf, zo1), P(-xi, yf, zi1), P(xi, yf, zi1)], slot, n)
    p.face([P(-xo, yf, zo1), P(-xo, yf, zo0), P(-xi, yf, zi0), P(-xi, yf, zi1)], slot, n)
    # laturile exterioare (din perete pana la fata ramei)
    if not open_bottom:
        p.face([P(-xo, 0, zo0), P(xo, 0, zo0), P(xo, yf, zo0), P(-xo, yf, zo0)], slot, -UP)
    p.face([P(-xo, 0, zo1), P(xo, 0, zo1), P(xo, yf, zo1), P(-xo, yf, zo1)], slot, UP)
    p.face([P(-xo, 0, zo0), P(-xo, 0, zo1), P(-xo, yf, zo1), P(-xo, yf, zo0)], slot, -u)
    p.face([P(xo, 0, zo0), P(xo, 0, zo1), P(xo, yf, zo1), P(xo, yf, zo0)], slot, u)
    # glaful interior (umbra proprie a golului)
    if not open_bottom:
        p.face([P(-xi, back, zi0), P(xi, back, zi0), P(xi, yf, zi0), P(-xi, yf, zi0)], slot, UP)
    p.face([P(-xi, back, zi1), P(xi, back, zi1), P(xi, yf, zi1), P(-xi, yf, zi1)], slot, -UP)
    p.face([P(-xi, back, zi0), P(-xi, back, zi1), P(-xi, yf, zi1), P(-xi, yf, zi0)], slot, u)
    p.face([P(xi, back, zi0), P(xi, back, zi1), P(xi, yf, zi1), P(xi, yf, zi0)], slot, -u)


def wall_box(p, c, u, n, x0, x1, y0, y1, z0, z1, slot, skip_back=True):
    """Cutie lipita de un perete (planul (c, u)), in coordonate locale:
    x de-a lungul peretelui, y spre exterior, z absolut."""
    cx, cy, cz = (x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5
    center = c + u * cx + n * cy + UP * cz
    p.obox(center, u, n, UP, (x1 - x0) * 0.5, (y1 - y0) * 0.5, (z1 - z0) * 0.5, slot,
           skip=("-v",) if skip_back else ())


def window(h, c, u, n, z0, w, ht, fw=0.1, proud=0.1, sash=True, mullions=0,
           hood=True, sill=True, part=None):
    """Fereastra inalta victoriana: geam inchis (sticla, putin in fata
    peretelui), rama alba iesita `proud` (glaful ei da adancimea de 0.1 a
    golului, brief §3.1), traversa de ghilotina, montanti, cornisa mica si
    pervaz. Peretele ramane intreg sub ea: geamul sta INTRE perete si fata
    ramei, deci golul se citeste fara gaura in perete (zero triunghiuri de
    perete in plus). ~56 de triunghiuri cu cornisa si pervaz."""
    p = part or h.trim
    g = 0.012
    xi = w * 0.5 - fw
    # geamul
    p.rect(c + n * g, u, UP, -xi, xi, z0 + fw, z0 + ht - fw, S_DARK, n)
    frame_ring(p, c, u, n, z0, w, ht, fw, proud, back=g)
    if sash:
        zm = z0 + ht * 0.52
        wall_box(p, c, u, n, -xi, xi, g, g + 0.045, zm - 0.035, zm + 0.035, S_WHITE)
    for i in range(mullions):
        x = -xi + 2 * xi * (i + 1) / (mullions + 1)
        wall_box(p, c, u, n, x - 0.035, x + 0.035, g, g + 0.045, z0 + fw, z0 + ht - fw, S_WHITE)
    if hood:
        wall_box(p, c, u, n, -w * 0.5 - 0.08, w * 0.5 + 0.08, 0.0, proud + 0.08,
                 z0 + ht, z0 + ht + 0.18, S_WHITE)
    if sill:
        wall_box(p, c, u, n, -w * 0.5 - 0.05, w * 0.5 + 0.05, 0.0, proud + 0.05,
                 z0 - 0.07, z0, S_WHITE)


def flat_window(h, c, u, n, z0, w, ht):
    """Fereastra de spate: doua placi (ancadrament alb + geam), 4 triunghiuri.
    Spatele se vede doar de la 60+ m, prin rand (brief §2, §8)."""
    h.trim.rect(c + n * 0.01, u, UP, -w * 0.5, w * 0.5, z0, z0 + ht, S_WHITE, n)
    h.trim.rect(c + n * 0.02, u, UP, -w * 0.5 + 0.1, w * 0.5 - 0.1, z0 + 0.1, z0 + ht - 0.1,
                S_DARK, n)


# --- Volumul -----------------------------------------------------------------

def stone_base(h, niche=(-2.15, 1.4, 2.95), garage=(1.3, 2.6, 2.4), top=LEVEL,
               ground="clapboard"):
    """Fusta de beton (-2.4 -> 0) si parterul (0 -> `top`), o singura coaja la
    fata peretilor (nu iese nicaieri, brief §3.1), cu golul nisei (prin fusta,
    pana la fund) si golul garajului. Fara talpa (e sub teren) si fara capac
    (il acopera etajele).

    `ground` alege parterul:
      - "clapboard" (v2, implicit): fatada parterului e SCANDURA, pe `Row_Wall`
        (pastelul casei), ca la casele din cod ale testului de loc aprobat.
        Masurat pe v1 in joc: parterul de piatra lua 11,3 % din pixelii caselor
        si statul pastelului cadea la 17,5 %; plus ca fetele mari plate de
        piatra prind stratul triplanar al materialului de lume si fac valuri.
        Aici se scrie doar fatada; laturile si spatele parterului le face
        `upper_walls(side_z0=0)` dintr-o bucata cu etajele.
      - "stone" (v1): parterul in piatra bej (slot 8, `Row_Trim`), ca pe
        plansa de concept (decuparea arata parterul garajului in piatra).
    Fusta (sub 0) e beton in ambele moduri."""
    t = h.trim
    hx = h.hx
    clap = ground == "clapboard"
    nx, nw, ntop = niche
    n0, n1 = nx - nw * 0.5, nx + nw * 0.5
    if garage is None:          # colțul: fără garaj (`garage=None`)
        g0 = g1 = gh = None
    else:
        gx, gw, gh = garage
        g0, g1 = gx - gw * 0.5, gx + gw * 0.5
    o = V(0, YF, 0)

    def up(a, b, z0, z1):
        if clap:
            h.wall.rect(o, XP, UP, a, b, z0, z1, S_WALL, YP)
        else:
            t.rect(o, XP, UP, a, b, z0, z1, S_STONE, YP)

    cols = sorted({-hx, n0, n1, hx} | ({g0, g1} if g0 is not None else set()))
    for a, b in zip(cols[:-1], cols[1:]):
        if a >= n0 - 1e-6 and b <= n1 + 1e-6:
            if top > ntop:
                up(a, b, ntop, top)
        elif g0 is not None and a >= g0 - 1e-6 and b <= g1 + 1e-6:
            t.rect(o, XP, UP, a, b, SKIRT, 0.0, S_STONE, YP)
            if top > gh:
                up(a, b, gh, top)
        elif clap:
            t.rect(o, XP, UP, a, b, SKIRT, 0.0, S_STONE, YP)
            up(a, b, 0.0, top)
        else:
            t.rect(o, XP, UP, a, b, SKIRT, top, S_STONE, YP)
    # laturile si spatele: orbe (in modul scandura, doar fusta; restul il pune
    # upper_walls)
    zt = 0.0 if clap else top
    for sx in (-1, 1):
        t.rect(V(sx * hx, 0, 0), YP, UP, YBW, YF, SKIRT, zt, S_STONE, XP * sx)
    t.rect(V(0, YBW, 0), XP, UP, -hx, hx, SKIRT, zt, S_STONE, -YP)


def garage_door(h, gx=1.3, gw=2.6, gh=2.4, recess=0.12, boards=4):
    """Usa de garaj adancita 0.12 m, cu panouri orizontale in relief si
    ancadrament alb pe trei laturi (decuparea)."""
    t = h.trim
    g0, g1 = gx - gw * 0.5, gx + gw * 0.5
    yd = YF - recess
    # glafurile golului
    t.rect(V(g0, 0, 0), YP, UP, yd, YF, 0.0, gh, S_STONE, XP)
    t.rect(V(g1, 0, 0), YP, UP, yd, YF, 0.0, gh, S_STONE, -XP)
    t.rect(V(0, 0, gh), XP, YP, g0, g1, yd, YF, S_STONE, -UP)
    t.rect(V(0, 0, 0), XP, YP, g0, g1, yd, YF, S_STONE, UP)
    # foaia usii + panourile
    t.rect(V(0, yd, 0), XP, UP, g0, g1, 0.0, gh, S_GARAGE, YP)
    pitch = (gh - 0.1) / boards
    for i in range(boards):
        z0 = 0.08 + i * pitch
        t.box(V(g0 + 0.09, yd, z0), V(g1 - 0.09, yd + 0.045, z0 + pitch - 0.09), S_GARAGE,
              skip=("-Y",))
    # ancadramentul alb
    cw, pr = 0.14, 0.06
    t.box(V(g0 - cw, YF, 0.0), V(g0, YF + pr, gh + cw), S_WHITE, skip=("-Y", "-Z"))
    t.box(V(g1, YF, 0.0), V(g1 + cw, YF + pr, gh + cw), S_WHITE, skip=("-Y", "-Z"))
    t.box(V(g0, YF, gh), V(g1, YF + pr, gh + cw), S_WHITE, skip=("-Y",))


def entry_niche(h, nx=-2.15, nw=1.4, depth=1.0, ntop=2.95, steps=7, rise=0.3):
    """Intrarea adancita: nisa de `nw` x `depth` in fatada, cu usa (1.0 x 2.3)
    si fereastra deasupra in fundul ei, la cota 0, si scara de `steps` trepte
    care COBOARA in nisa, prin fusta (0 -> -2.1). Nimic nu iese pe trotuar
    (brief §3.1, corectura criticului de la pasul 0). Pilastri si antablament
    alb in jurul golului, iesiti doar 0.07 m."""
    t = h.trim
    n0, n1 = nx - nw * 0.5, nx + nw * 0.5
    yb = YF - depth
    # interiorul nisei deasupra podelei: log_dark (brief §5)
    t.rect(V(n0, 0, 0), YP, UP, yb, YF, 0.0, ntop, S_NICHE, XP)
    t.rect(V(n1, 0, 0), YP, UP, yb, YF, 0.0, ntop, S_NICHE, -XP)
    t.rect(V(0, 0, ntop), XP, YP, n0, n1, yb, YF, S_NICHE, -UP)
    t.rect(V(0, yb, 0), XP, UP, n0, n1, 0.0, ntop, S_NICHE, YP)
    # put ul scarii, taiat prin fusta: beton
    t.rect(V(n0, 0, 0), YP, UP, yb, YF, SKIRT, 0.0, S_STONE, XP)
    t.rect(V(n1, 0, 0), YP, UP, yb, YF, SKIRT, 0.0, S_STONE, -XP)
    # scara: contur in trepte (contratreapta spre +Y, treapta spre +Z)
    tread = depth / steps
    y, z = yb, 0.0
    for k in range(steps):
        t.rect(V(0, y, 0), XP, UP, n0, n1, z - rise, z, S_STONE, YP)       # contratreapta
        z -= rise
        t.rect(V(0, 0, z), XP, YP, n0, n1, y, y + tread, S_STONE, UP)     # treapta
        y += tread
    if z > SKIRT + 1e-6:
        t.rect(V(0, YF, 0), XP, UP, n0, n1, SKIRT, z, S_STONE, YP)
    # usa + fereastra de deasupra, in fundul nisei
    c = V(nx, yb, 0)
    dw, dh, trh = 1.0, 2.3, 0.4
    t.rect(c + YP * 0.012, XP, UP, -dw * 0.5, dw * 0.5, 0.0, dh, S_NICHE, YP)
    t.rect(c + YP * 0.012, XP, UP, -dw * 0.5, dw * 0.5, dh + 0.08, dh + 0.08 + trh, S_DARK, YP)
    fw = 0.1
    wall_box(t, c, XP, YP, -dw * 0.5 - fw, -dw * 0.5, 0, 0.06, 0.0, dh + 0.16 + trh, S_WHITE)
    wall_box(t, c, XP, YP, dw * 0.5, dw * 0.5 + fw, 0, 0.06, 0.0, dh + 0.16 + trh, S_WHITE)
    wall_box(t, c, XP, YP, -dw * 0.5, dw * 0.5, 0, 0.06, dh, dh + 0.08, S_WHITE)
    wall_box(t, c, XP, YP, -dw * 0.5, dw * 0.5, 0, 0.06, dh + 0.08 + trh, dh + 0.16 + trh, S_WHITE)
    # pilastrii si antablamentul de pe fatada (doar deasupra podelei)
    o = V(0, YF, 0)
    pw, pr = 0.15, 0.07
    wall_box(t, o, XP, YP, n0 - pw, n0, 0, pr, 0.0, ntop, S_WHITE)
    wall_box(t, o, XP, YP, n1, n1 + pw, 0, pr, 0.0, ntop, S_WHITE)
    wall_box(t, o, XP, YP, n0 - pw, n1 + pw, 0, pr, ntop, LEVEL, S_WHITE)


def belt_course(h, z=LEVEL, ht=0.25, proud=0.06):
    """Braul alb dintre parter si etajul 1 (brief §3.1). v1: 0,25; v2: 0,15."""
    h.trim_bev.box(V(-h.hx, YF, z), V(h.hx, YF + proud, z + ht), S_WHITE, skip=("-Y",))


def corner_boards(h, z0, z1, w=0.16, proud=0.05, sides=(-1, 1)):
    """Scandurile albe de colt, pe fata, la marginea X +-3.5 (nu ies lateral).
    v1: 0,16 lat; v2: 0,10. `sides`: colturile de pus (la colt, cel de sub
    turnulet lipseste)."""
    HX = h.hx
    for sx in sides:
        x0, x1 = (HX - w, HX) if sx > 0 else (-HX, -HX + w)
        h.trim.box(V(x0, YF, z0), V(x1, YF + proud, z1), S_WHITE, skip=("-Y",))


def upper_walls(h, bay_x0, bay_x1, z0=LEVEL, z_under_bay=3.95, gable_apex=None,
                gable_split=10.2, side_z0=None, corn_z=None, rows=None, side_top=EAVE,
                sides=(-1, 1), gable_ends=(True, True)):
    """Peretii de scandura (Row_Wall): fatada etajelor in afara bovindoului,
    banda de sub bovindou, laturile oarbe, spatele si frontoanele.

    Fatada e o grila, nu o placa: AO-ul e pe varfuri, iar cu o singura placa
    umbra de sub cornisa sau de langa bovindou s-ar intinde pe toti cei 6 m.
    Liniile de grila tin intunecarea in banda ei (brief §6: ~0.7 sub bovindou
    si cornisa, restul aproape alb). Peretele din spatele bovindoului nu
    exista (e inchis de bovindou).

    `side_z0`: de unde pornesc laturile si spatele (0 cand parterul e scandura,
    ca sa fie o singura fata pe toata inaltimea). `corn_z`: fundul cornisei
    principale; grila are o linie acolo si una cu 0,5 mai jos, ca AO-ul de sub
    cornisa sa stea intr-o banda ingusta (v1: linia la EAVE - 0,75).

    Pentru celelalte case: `rows` = liniile grilei fatadei date explicit (ultima =
    varful fatadei; Italianate urca pana la 10,0, sub coroana cornisei grele);
    `side_top` = varful laturilor si al spatelui (aticul plat: 10,3); `sides` =
    laturile oarbe de construit (la colt, -X e fatada a doua, cu grila ei);
    `gable_ends` = (fronton in fata, fronton in spate) — fatada falsa (C) are
    doar frontonul din spate, cel din fata e ascuns de atic."""
    w = h.wall
    HX = h.hx
    o = V(0, YF, 0)
    if rows is not None:
        rows = list(rows)
    elif corn_z is None:
        rows = [z0, z0 + 0.4, EAVE - 0.75, EAVE]
    else:
        rows = [z0, z0 + 0.4, corn_z - 0.5, corn_z, EAVE]
    sz0 = z0 if side_z0 is None else side_z0
    if bay_x0 > -HX + 0.01:
        cols = [-HX, -HX + 0.3, bay_x0 - 0.3, bay_x0]
        for a, b in zip(cols[:-1], cols[1:]):
            for c0, c1 in zip(rows[:-1], rows[1:]):
                w.rect(o, XP, UP, a, b, c0, c1, S_WALL, YP)
    if bay_x1 < HX - 0.01:
        for c0, c1 in zip(rows[:-1], rows[1:]):
            w.rect(o, XP, UP, bay_x1, HX, c0, c1, S_WALL, YP)
    # banda de sub bovindou (zona consolelor) si deasupra lui
    w.rect(o, XP, UP, bay_x0, bay_x1, z0, z_under_bay, S_WALL, YP)
    # laturile si spatele
    for sx in sides:
        w.rect(V(sx * HX, 0, 0), YP, UP, YBW, YF, sz0, side_top, S_WALL, XP * sx)
    w.rect(V(0, YBW, 0), XP, UP, -HX, HX, sz0, side_top, S_WALL, -YP)
    if gable_apex is not None:
        for (y, out), on in zip(((YF, YP), (YBW, -YP)), gable_ends):
            if not on:
                continue
            hs = HX * (gable_apex - gable_split) / (gable_apex - EAVE)
            w.face([V(-HX, y, EAVE), V(HX, y, EAVE), V(hs, y, gable_split),
                    V(-hs, y, gable_split)], S_WALL, out)
            w.face([V(-hs, y, gable_split), V(hs, y, gable_split), V(0, y, gable_apex)],
                   S_WALL, out)


# --- Bovindoul ----------------------------------------------------------------

def bay_outline(kind, xc, proj=0.8, front=2.6, width_sq=2.8):
    """Conturul bovindoului pe planul fatadei, de la stanga la dreapta:
    A (pe perete), ..., D (pe perete). 'canted' = trei fete, laturile la 45 de
    grade, fata `front`; 'square' = trei fete drepte, latimea `width_sq`."""
    y1 = YF + proj
    if kind == "canted":
        hf = front * 0.5
        return [V(xc - hf - proj, YF, 0), V(xc - hf, y1, 0), V(xc + hf, y1, 0),
                V(xc + hf + proj, YF, 0)]
    if kind == "square":
        hw = width_sq * 0.5
        return [V(xc - hw, YF, 0), V(xc - hw, y1, 0), V(xc + hw, y1, 0), V(xc + hw, YF, 0)]
    raise ValueError(kind)


def _seg(outline, i):
    a, b = outline[i], outline[i + 1]
    d = (b - a).normalized()
    nrm = Vector((-d.y, d.x, 0.0))  # spre exterior (conturul merge spre +X, bomba spre +Y)
    return a, b, d, nrm


def offset_outline(outline, dist):
    """Conturul deplasat spre exterior cu `dist` (imbinare in unghi), cu
    capetele alunecate pe planul fatadei (Y = YF)."""
    segs = [_seg(outline, i) for i in range(len(outline) - 1)]
    out = []
    a, b, d, nrm = segs[0]
    t = -(nrm.y * dist) / d.y if abs(d.y) > 1e-6 else 0.0
    out.append(a + nrm * dist + d * t)
    for i in range(1, len(segs)):
        n1, n2 = segs[i - 1][3], segs[i][3]
        out.append(outline[i] + (n1 + n2) * (dist / (1.0 + n1.dot(n2))))
    a, b, d, nrm = segs[-1]
    t = -(nrm.y * dist) / d.y if abs(d.y) > 1e-6 else 0.0
    out.append(b + nrm * dist + d * t)
    return out


def bay_band(h, outline, dist, z0, z1, part=None, slot=S_WHITE):
    """Banda (talpa, brau, cornisa) care urmeaza conturul bovindoului, iesita
    `dist`. Fara fata dinspre perete."""
    p = part or h.trim_bev
    ol = [V(q.x, q.y, z0) for q in offset_outline(outline, dist)]
    n = len(ol)
    p.prism(ol, (0, 0, z1 - z0), slot, skip_sides=(n - 1,))


def bay(h, outline, z_cons=3.3, z_slab=(3.7, 3.95), z_mid=(6.2, 6.45),
        z_corn=(8.95, 9.35), corn_out=0.1, windows=None, consoles=None,
        post_w=0.18, fw=0.13, win_rows=((4.23, 1.59), (6.88, 1.59)), corn_ao_row=False,
        cornice=True, post_top=None, hoods=None):
    """Bovindoul complet: console, talpa, peretii de scandura (cu fatete pe
    randuri pentru AO), braul dintre etaje, cornisa, montantii albi de pe muchii
    si ferestrele. `windows` = lista (latimea STICLEI, montanti) per fata;
    `win_rows` = (z-ul de jos al sticlei, inaltimea sticlei) pe etaj; rama de
    latime `fw` se pune IN JURUL sticlei, deci o rama mai subtire nu mareste
    geamul, ci elibereaza perete. `post_w` = latimea montantilor albi de pe
    muchii (v1 0,18). `consoles` = lista de X-uri (implicit: colturile + doua
    pe fata). `corn_ao_row`: o linie de grila cu 0,45 sub cornisa bovindoului,
    ca AO-ul de sub ea sa nu se intinda pe tot etajul 2.

    Italianate (A): `cornice=False` scoate cornisa bovindoului (peretii urca pana la
    `z_corn[0]`, sub cornisa grea a casei, care il inveleste), `post_top` opreste
    montantii sub friza, `hoods` = (inaltimea arcului, grosimea, iesirea) ->
    "sprancene" arcuite peste fiecare fereastra (`arched_hood`).

    Iesirea totala e 0.9 (brief §3.1): peretii la `proj`, cornisa cu `corn_out`
    peste ei, ca AABB-ul sa se opreasca exact la Godot Z = -6.9."""
    w = h.wall
    nseg = len(outline) - 1
    rows = [z_slab[1], z_mid[0], z_mid[1]] + ([z_corn[0] - 0.45] if corn_ao_row else []) \
        + [z_corn[0]]
    for i in range(nseg):
        a, b, d, nrm = _seg(outline, i)
        L = (b - a).length
        for c0, c1 in zip(rows[:-1], rows[1:]):
            w.rect(V(a.x, a.y, 0), d, UP, 0.0, L, c0, c1, S_WALL, nrm)
    # benzile albe
    bay_band(h, outline, 0.06, z_slab[0], z_slab[1])
    bay_band(h, outline, 0.05, z_mid[0], z_mid[1])
    # cornisa bovindoului in doua trepte: friza lipita + coroana iesita
    if cornice:
        zc = z_corn[0] + (z_corn[1] - z_corn[0]) * 0.45
        bay_band(h, outline, 0.03, z_corn[0], zc, part=h.trim)
        bay_band(h, outline, corn_out, zc, z_corn[1])
    # montantii de pe muchii (cate o scandura pe fiecare fata, la capete)
    sw, spr = post_w, 0.035
    for i in range(nseg):
        a, b, d, nrm = _seg(outline, i)
        L = (b - a).length
        c = V(a.x, a.y, 0)
        for x0, x1 in ((0.0, sw), (L - sw, L)):
            wall_box(h.trim, c, d, nrm, x0, x1, 0.0, spr, z_slab[1],
                     z_corn[0] if post_top is None else post_top, S_WHITE)
    # consolele: profil in trepte sub talpa, perpendicular pe perete
    if consoles is None:
        b_, c_ = outline[1], outline[-2]
        consoles = [b_.x + 0.12, b_.x + (c_.x - b_.x) / 3.0, b_.x + 2 * (c_.x - b_.x) / 3.0,
                    c_.x - 0.12]
    y_end = max(q.y for q in outline) + 0.02
    for x in consoles:
        prof = [V(x - 0.08, YF, z_slab[0]), V(x - 0.08, y_end, z_slab[0]),
                V(x - 0.08, y_end, z_slab[0] - 0.14), V(x - 0.08, YF, z_cons)]
        h.trim.prism(prof, (0.16, 0, 0), S_WHITE, skip_sides=(0, 3))
    # ferestrele, centrate pe fiecare fata, pe doua etaje
    if windows is None:
        windows = [(0.49, 0)] + [(1.74, 1)] * (nseg - 2) + [(0.49, 0)]
    for i in range(nseg):
        a, b, d, nrm = _seg(outline, i)
        mid = (a + b) * 0.5
        c = V(mid.x, mid.y, 0)
        gw, mul = windows[i]
        for gz, gh in win_rows:
            window(h, c, d, nrm, gz - fw, gw + 2 * fw, gh + 2 * fw, fw=fw, proud=0.08,
                   mullions=mul, hood=False, sill=False)
            if hoods:
                rise, thick, out = hoods
                arched_hood(h, c, d, nrm, gw + 2 * fw + 0.08, gz + gh + fw + 0.03, rise,
                            thick, out)


# --- Acoperisul cu fronton (fatada B, Queen Anne) ---------------------------------

def gable_roof(h, apex=12.6, thick=0.15, over_front=0.4, over_back=0.0, verge_h=0.42,
               bands=(9.75, 10.15, 10.55, 11.95), band_h=0.3, band_out=0.05,
               gable_window=(10.9, 0.9), band_part="wall"):
    # fatada falsa (C): acoperisul in doua ape ascuns de atic, fara bordura
    # (`verge_h=None`), fara solzi (`bands=()`) si fara ferestruica
    """Doua ape cu coama pe Y (Godot Z), fronton triunghiular spre strada.

    - apele: placi de ardezie de `thick` (vertical), cu streasina la +-3.5 (nu
      ies lateral, casele se lipesc) si iesite `over_front` peste fronton;
    - bordura alba (verge) pe muchiile inclinate din fata;
    - solzii: `bands` benzi-pana in relief (groase jos, la zero sus), ca
      randuri de sindrila mare: umbra de sub fiecare banda e linia care se
      citeste de la 30 m (brief §3.2: 3-4 benzi, nu solzi mici);
    - fereastra mica din fronton.
    Frontonul (peretele) il face `upper_walls(gable_apex=apex - thick)`.

    `band_part`: "wall" (v2) = benzile sunt SCANDURA (`Row_Wall`, pastelul casei),
    cu buza lor de umbra, deci campul frontonului se citeste pastel si doar
    bordura, rama si pervazul ferestrei mici raman albe; "trim" (v1) = benzi
    albe pe atlas (masurat: frontonul v1 era 72 % alb). `verge_h` = latimea
    bordurii (v1 0,42)."""
    HX = h.hx
    wall_apex = apex - thick
    yb, yf = YB - over_back, YF + over_front
    for sx in (-1, 1):
        e_bot, e_top = V(sx * HX, 0, EAVE), V(sx * HX, 0, EAVE + thick)
        r_bot, r_top = V(0, 0, wall_apex), V(0, 0, apex)
        vs = []
        for base in (e_bot, e_top, r_top, r_bot):
            vs.append(V(base.x, yb, base.z))
            vs.append(V(base.x, yf, base.z))
        # 0,1 eave-bot; 2,3 eave-top; 4,5 ridge-top; 6,7 ridge-bot (par = spate)
        faces = [[2, 3, 5, 4], [0, 6, 7, 1], [1, 7, 5, 3], [0, 2, 4, 6], [0, 1, 3, 2]]
        h.trim_bev.piece(vs, faces, S_DARK)  # centroidul real: placa e subtire
    # bordura frontonului
    run, rise = HX, apex - (EAVE + thick)
    L = math.hypot(run, rise)
    for sx in ((-1, 1) if verge_h else ()):
        top_e, top_r = V(sx * HX, 0, EAVE + thick), V(0, 0, apex)
        u = (top_r - top_e).normalized()
        wv = Vector((sx * rise, 0.0, run)).normalized()   # perpendicular, in sus-afara
        c = (top_e + top_r) * 0.5 - wv * (verge_h * 0.5)
        c.y = yf + 0.02
        h.trim_bev.obox(c, u, YP, wv, L * 0.5, 0.07, verge_h * 0.5, S_WHITE)
    # benzile de solzi
    span = wall_apex - EAVE

    def hw(z):
        return HX * (wall_apex - z) / span

    bp, bs = (h.wall, S_WALL) if band_part == "wall" else (h.trim, S_WHITE)
    for z0 in bands:
        z1 = z0 + band_h
        a0, a1 = hw(z0), hw(z1)
        bp.face([V(-a0, YF + band_out, z0), V(a0, YF + band_out, z0),
                 V(a1, YF + 0.004, z1), V(-a1, YF + 0.004, z1)], bs, YP + UP * 0.1)
        bp.face([V(-a0, YF, z0), V(a0, YF, z0), V(a0, YF + band_out, z0),
                 V(-a0, YF + band_out, z0)], bs, -UP)
    if gable_window:
        z0, s = gable_window
        window(h, V(0, YF, 0), XP, YP, z0, s, s, fw=0.1, proud=0.09, sash=False,
               hood=False, sill=True)


def eave_cornice(h, z_frieze=(9.0, 9.3), z_corn=(9.3, 9.6), proud=0.35, modillions=(),
                 x0=None, x1=None):
    """Friza + cornisa principala peste toata latimea fatadei (fara depasire
    laterala), cu console mici (modilioane) sub ea. `z_frieze=None` (v2) scoate
    placa de friza: sub cornisa ramane peretele (pastel), umbrit de ea. `x0`/`x1`:
    capetele (implicit +-latimea; la colt cornisa se opreste in turnulet)."""
    HX = h.hx
    if x0 is None:
        x0 = -HX
    if x1 is None:
        x1 = HX
    if z_frieze is not None:
        h.trim.box(V(x0, YF, z_frieze[0]), V(x1, YF + 0.04, z_frieze[1]), S_WHITE,
                   skip=("-Y",))
    h.trim_bev.box(V(x0, YF, z_corn[0]), V(x1, YF + proud, z_corn[1]), S_WHITE, skip=("-Y",))
    for x in modillions:
        h.trim.box(V(x - 0.07, YF, z_corn[0] - 0.16), V(x + 0.07, YF + proud - 0.06, z_corn[0]),
                   S_WHITE, skip=("-Y", "+Z"))


def back_face(h, xs=(-1.75, 1.75), rows=((1.0, 1.6), (4.1, 1.75), (6.95, 1.75)),
              eave_band=(9.35, 9.6)):
    """Spatele: ferestre plate (2 pe nivel) si o banda de streasina alba."""
    for z0, ht in rows:
        for x in xs:
            flat_window(h, V(x, YBW, 0), -XP, -YP, z0, 1.0, ht)
    h.trim.box(V(-h.hx, YB, eave_band[0]), V(h.hx, YBW, eave_band[1]), S_WHITE, skip=("+Y",))


# --- Fatada A (Italianate): sprancene, cornisa grea, acoperis plat ------------------

def arched_hood(h, c, u, n, w, z_base, rise, thick, proud, segs=6, part=None):
    """Sprancean Italianate: banda alba ARCUITA peste o fereastra, lata `w`, cu
    capetele la `z_base` si varful cu `rise` mai sus (arc parabolic in `segs`
    trepte), groasa `thick` pe verticala, iesita `proud` din perete. Fara spate
    (lipita de perete). 6 trepte = 40 de triunghiuri."""
    p = part or h.trim

    def P(x, y, z):
        return c + u * x + n * y + UP * z

    xs = [-w * 0.5 + w * i / segs for i in range(segs + 1)]
    zl = [z_base + rise * (1.0 - (2.0 * x / w) ** 2) for x in xs]
    for i in range(segs):
        x0, x1, a0, a1 = xs[i], xs[i + 1], zl[i], zl[i + 1]
        dx, dz = x1 - x0, a1 - a0
        up = u * (-dz) + UP * dx            # normala muchiei de sus a arcului
        p.face([P(x0, proud, a0), P(x1, proud, a1), P(x1, proud, a1 + thick),
                P(x0, proud, a0 + thick)], S_WHITE, n)
        p.face([P(x0, 0, a0 + thick), P(x1, 0, a1 + thick), P(x1, proud, a1 + thick),
                P(x0, proud, a0 + thick)], S_WHITE, up)
        p.face([P(x0, 0, a0), P(x1, 0, a1), P(x1, proud, a1), P(x0, proud, a0)], S_WHITE, -up)
    for x, a, out in ((xs[0], zl[0], -u), (xs[-1], zl[-1], u)):
        p.face([P(x, 0, a), P(x, proud, a), P(x, proud, a + thick), P(x, 0, a + thick)],
               S_WHITE, out)


def italianate_cornice(h, outline, z_bed=(9.6, 9.7), z_crown=(10.0, 10.3), proud=0.45,
                       bay_out=0.10, back=0.25, consoles=(), console_w=0.14,
                       console_d=0.38, bay_blocks=0.45):
    """Cornisa GREA Italianate (brief §3.2: 0,7 m inalta, iesita 0,45, peste +9,6):
    braul de jos (9,6 -> 9,7, alb, iesit 0,05; `z_bed=(z, z)` il scoate), friza (perete pastel, 9,7 -> 10,0, o
    face `upper_walls(rows=...)`), consolele albe in volute sub coroana, si coroana
    (10,0 -> 10,3) iesita `proud`, cu bevel. Peste bovindou coroana il inveleste la
    `bay_out` (0,10): iesirea totala ramane 0,9, ca AABB-ul sa se opreasca la Godot
    Z = -6,9; acolo friza e chiar peretele bovindoului urcat pana la 10,0.
    Coroana are si fata din spate (la `back` in interior): de sus, de pe camera de
    joc, se vede ca o placa alba groasa peste acoperisul plat."""
    hx = h.hx
    ax, dx = outline[0].x, outline[-1].x
    if z_bed[1] > z_bed[0]:
        for a, b in ((-hx, ax), (dx, hx)):
            if b - a > 0.01:
                h.trim.box(V(a, YF, z_bed[0]), V(b, YF + 0.05, z_bed[1]), S_WHITE,
                           skip=("-Y",))
        bay_band(h, outline, 0.05, z_bed[0], z_bed[1], part=h.trim)
    h.trim_bev.box(V(-hx, YF - back, z_crown[0]), V(hx, YF + proud, z_crown[1]), S_WHITE)
    bay_band(h, outline, bay_out, z_crown[0], z_crown[1])
    z0, z1 = z_bed[1], z_crown[0]
    for x in consoles:
        # profil in volute: plin sus (sub coroana), subtiat in trepte spre perete
        prof = [V(x - console_w * 0.5, YF, z1), V(x - console_w * 0.5, YF + console_d, z1),
                V(x - console_w * 0.5, YF + console_d, z1 - 0.12),
                V(x - console_w * 0.5, YF + 0.12, z0)]
        h.trim.prism(prof, (console_w, 0, 0), S_WHITE, skip_sides=(0, 3))
    # pe bovindou coroana iese doar 0,10: in locul consolelor, blocuri mici (0,12 x
    # 0,09) la `bay_blocks`, ca ritmul cornisei sa continue in jurul lui
    if bay_blocks:
        for i in range(len(outline) - 1):
            a, b, d, nrm = _seg(outline, i)
            L = (b - a).length
            n = max(1, int(round(L / bay_blocks)))
            for k in range(n):
                x = L * (k + 0.5) / n
                wall_box(h.trim, V(a.x, a.y, 0), d, nrm, x - 0.06, x + 0.06, 0.0, 0.09,
                         z0 + 0.1, z1, S_WHITE, )


def flat_roof(h, z_roof=10.0, z_top=10.3, t=0.15, y_front=YF - 0.25):
    """Acoperisul PLAT ascuns (A): placa de ardezie la `z_roof`, intre aticele
    laterale si din spate (groase `t`, varful la `z_top`, cat coroana cornisei).
    Fata exterioara a aticelor e chiar peretele lateral/din spate, urcat de
    `upper_walls(side_top=z_top)`; aici: fetele interioare (scandura, Row_Wall) si
    capacul lor (ardezie, ca acoperisul: de sus, intre case, nu face linii albe)."""
    hx = h.hx
    yb = YBW
    h.trim.rect(V(0, 0, z_roof), XP, YP, -hx + t, hx - t, yb + t, y_front, S_DARK, UP)
    for sx in (-1, 1):
        h.wall.rect(V(sx * (hx - t), 0, 0), YP, UP, yb + t, y_front, z_roof, z_top, S_WALL,
                    -XP * sx)
        a, b = (hx - t, hx) if sx > 0 else (-hx, -hx + t)
        h.trim.rect(V(0, 0, z_top), XP, YP, a, b, yb, y_front, S_DARK, UP)
    h.wall.rect(V(0, yb + t, 0), XP, UP, -hx + t, hx - t, z_roof, z_top, S_WALL, YP)
    h.trim.rect(V(0, 0, z_top), XP, YP, -hx + t, hx - t, yb, yb + t, S_DARK, UP)


# --- Fatada C (Stick): montanti verticali, fatada falsa -----------------------------

def stick_studs(h, xs, z0, z1, w=0.10, proud=0.04):
    """Montantii verticali albi in relief ai stilului Stick, pe planul fatadei."""
    for x in xs:
        h.trim.box(V(x - w * 0.5, YF, z0), V(x + w * 0.5, YF + proud, z1), S_WHITE,
                   skip=("-Y",))


def false_front(h, z0=EAVE, z_side=10.35, z_mid=10.8, mid=1.5, thick=0.12, cap_h=0.12,
                cap_out=0.10, studs=(), stud_w=0.10, stud_proud=0.04):
    """FATADA FALSA (brief §3.2, C): atic drept pe planul fatadei, de la `z0` in sus,
    cu o TREAPTA: marginile pana la `z_side`, mijlocul (|x| < `mid`) pana la `z_mid`
    (+10,8, varful casei). Peretele aticului e scandura (Row_Wall, pastel) pe ambele
    fete; capacele sunt albe, iesite `cap_out` in fata, cu bevel (silueta in trepte
    se citeste de la distanta: asta o deosebeste de cornisa plata A si de frontonul
    B). `studs` = X-urile montantilor albi care urca pe atic."""
    hx = h.hx
    w = h.wall
    yb = YF - thick
    zs, zm = z_side - cap_h, z_mid - cap_h
    for y, out in ((YF, YP), (yb, -YP)):
        w.rect(V(0, y, 0), XP, UP, -hx, hx, z0, zs, S_WALL, out)
        w.rect(V(0, y, 0), XP, UP, -mid, mid, zs, zm, S_WALL, out)
    for sx in (-1, 1):
        w.rect(V(sx * hx, 0, 0), YP, UP, yb, YF, z0, zs, S_WALL, XP * sx)
        w.rect(V(sx * mid, 0, 0), YP, UP, yb, YF, z_side, zm, S_WALL, XP * sx)
        a, b = sorted((sx * hx, sx * mid))
        h.trim_bev.box(V(a, yb, zs), V(b, YF + cap_out, z_side), S_WHITE)
    h.trim_bev.box(V(-mid - cap_out, yb, zm), V(mid + cap_out, YF + cap_out, z_mid), S_WHITE)
    for x in studs:
        top = zm if abs(x) < mid else zs
        h.trim.box(V(x - stud_w * 0.5, YF, z0), V(x + stud_w * 0.5, YF + stud_proud, top),
                   S_WHITE, skip=("-Y", "+Z"))


# --- Coltul: turnulet octogonal, acoperis in patru ape ------------------------------

def octagon(cx, cy, r):
    """Varfurile octogonului cu fetele pe axe si pe diagonale: varful k la unghiul
    22,5 + 45k grade; fata k (de la varful k la k+1) are normala la 45(k+1)."""
    return [V(cx + r * math.cos(math.radians(22.5 + 45.0 * k)),
              cy + r * math.sin(math.radians(22.5 + 45.0 * k)), 0.0) for k in range(8)]


def _line_hit_plane(p, d, plane):
    """Punctul liniei p + t*d pe planul ('x'|'y', valoare)."""
    ax, val = plane
    if ax == "x":
        return p + d * ((val - p.x) / d.x)
    return p + d * ((val - p.y) / d.y)


def offset_poly(pts, dist, planes):
    """Polilinia deschisa `pts` (convexa, parcursa in sens trigonometric: exteriorul
    e la dreapta) deplasata cu `dist` spre exterior, cu capetele alunecate pe
    planurile peretilor (`planes` = (planul capatului 0, planul capatului n),
    fiecare ('x'|'y', v)). Ca `offset_outline`, dar pentru un turnulet al carui
    capat sta pe ALT perete decat primul (colt)."""
    nrms = []
    for i in range(len(pts) - 1):
        d = (pts[i + 1] - pts[i]).normalized()
        nrms.append(Vector((d.y, -d.x, 0.0)))
    out = []
    d0 = (pts[1] - pts[0]).normalized()
    out.append(_line_hit_plane(pts[0] + nrms[0] * dist, d0, planes[0]))
    for i in range(1, len(pts) - 1):
        n1, n2 = nrms[i - 1], nrms[i]
        out.append(pts[i] + (n1 + n2) * (dist / (1.0 + n1.dot(n2))))
    d1 = (pts[-1] - pts[-2]).normalized()
    out.append(_line_hit_plane(pts[-1] + nrms[-1] * dist, d1, planes[1]))
    return out


def poly_band(p, pts, dist, planes, z0, z1, slot=S_WHITE):
    """Banda care urmeaza polilinia `pts` (deplasata `dist`), intre z0 si z1, fara
    latura dinspre casa (coarda dintre capete)."""
    ol = [V(q.x, q.y, z0) for q in offset_poly(pts, dist, planes)]
    p.prism(ol, (0, 0, z1 - z0), slot, skip_sides=(len(ol) - 1,))


def ring_band(p, ring, dist, z0, z1, slot=S_WHITE):
    """Inel inchis (octogonul intreg, deasupra acoperisului) deplasat `dist`."""
    c = sum(ring, Vector()) / len(ring)
    k = 1.0 + dist / ((ring[0] - c).length * math.cos(math.radians(22.5)))
    ol = [V(c.x + (q.x - c.x) * k, c.y + (q.y - c.y) * k, z0) for q in ring]
    p.prism(ol, (0, 0, z1 - z0), slot)


def turret(h, cx, cy, corner, planes, r=1.6, outward=5, z_cons=3.3,
           z_slab=(3.8, 3.95), z_mid=(6.25, 6.4), z_band=(9.35, 9.6), z_top=12.2,
           z_crown=(12.2, 12.5), cone_top=14.62, finial_top=15.0, crown_out=0.12,
           win_rows=((4.23, 1.59), (6.88, 1.59)), top_win=(10.35, 1.3), glass_w=0.5,
           fw=0.10, post_w=0.10):
    """TURNULETUL octogonal de pe colt (brief §3.2: diametru 3,2, de la +3,3 la +12,5,
    acoperis conic pana la +15,0). `r` = raza cercului circumscris (1,6); centrul
    e ales de apelant ca varfurile 0 si `outward` sa cada exact pe cele doua
    fatade (planurile `planes`), deci fetele 0..outward-1 sunt cele dinspre strada.
    `corner` = coltul casei pe care sta (spre el coboara consola).

    - sub acoperis (3,95 -> 9,6): doar fetele dinspre strada (celelalte sunt in
      casa), cu talpa alba, brau, banda de cornisa si montanti pe muchii, cate o
      fereastra pe fata si pe etaj;
    - dedesubt: o CONSOLA in trunchi de piramida intoarsa (3,3 -> 3,8), care
      coboara turnuletul spre coltul casei (nimic sub +3,3 nu iese din fatade);
    - deasupra acoperisului (9,6 -> 12,2): toate cele opt fete, cu ferestre (de pe
      camera de joc se vad si cele dinspre acoperis), coroana alba (12,2 -> 12,5);
    - acoperisul conic: piramida octogonala de ardezie, netezita (citeste con), cu
      streasina = coroana (`crown_out`), si un varf alb pana la +15,0."""
    ring = octagon(cx, cy, r)
    outer = ring[:outward + 1]
    wl = h.wall
    L = (ring[1] - ring[0]).length
    low_rows = [z_slab[1], z_mid[0], z_mid[1], z_band[0] - 0.45, z_band[0]]
    top_rows = [z_band[1], z_top - 0.45, z_top]
    for k in range(8):
        a, b = ring[k], ring[(k + 1) % 8]
        d = (b - a).normalized()
        nrm = Vector((d.y, -d.x, 0.0))
        c = V(a.x, a.y, 0)
        street = k < outward
        rows = (low_rows + [z_band[1]] + top_rows[1:]) if street else top_rows
        for c0, c1 in zip(rows[:-1], rows[1:]):
            wl.rect(c, d, UP, 0.0, L, c0, c1, S_WALL, nrm)
        for x0, x1 in ((0.0, post_w), (L - post_w, L)):
            if street:
                wall_box(h.trim, c, d, nrm, x0, x1, 0.0, 0.035, z_slab[1], z_band[0], S_WHITE)
            wall_box(h.trim, c, d, nrm, x0, x1, 0.0, 0.035, z_band[1], z_top, S_WHITE)
        mid = c + d * (L * 0.5)
        if street:
            for gz, gh in win_rows:
                window(h, mid, d, nrm, gz - fw, glass_w + 2 * fw, gh + 2 * fw, fw=fw,
                       proud=0.08, hood=False, sill=False)
        gz, gh = top_win
        window(h, mid, d, nrm, gz - fw, glass_w + 2 * fw, gh + 2 * fw, fw=fw, proud=0.08,
               hood=False, sill=False)
    # benzile de pe partea dinspre strada
    poly_band(h.trim_bev, outer, 0.06, planes, z_slab[0], z_slab[1])
    poly_band(h.trim, outer, 0.05, planes, z_mid[0], z_mid[1])
    poly_band(h.trim_bev, outer, 0.10, planes, z_band[0], z_band[1])
    # consola de sub turnulet: de la talpa (deplasata 0,06) spre coltul casei
    top = [V(q.x, q.y, z_slab[0]) for q in offset_poly(outer, 0.06, planes)]
    cc = V(corner.x, corner.y, z_cons)
    bot = [V(cc.x + (q.x - cc.x) * 0.3, cc.y + (q.y - cc.y) * 0.3, z_cons) for q in top]
    for i in range(len(top) - 1):
        d = (top[i + 1] - top[i]).normalized()
        out = Vector((d.y, -d.x, 0.0)) - UP * 0.6
        h.trim.face([top[i], top[i + 1], bot[i + 1], bot[i]], S_WHITE, out)
    h.trim.face(bot + [cc], S_WHITE, -UP)
    # coroana si conul
    ring_band(h.trim_bev, ring, crown_out, z_crown[0], z_crown[1])
    k = 1.0 + crown_out / (r * math.cos(math.radians(22.5)))
    base = [V(cx + (q.x - cx) * k, cy + (q.y - cy) * k, z_crown[1]) for q in ring]
    h.trim.piece(base + [V(cx, cy, cone_top)], [[i, (i + 1) % 8, 8] for i in range(8)],
                 S_DARK, center=V(cx, cy, z_crown[1] + 0.3))
    h.trim.face(list(reversed(base)), S_DARK, -UP)
    # varful: octaedru alungit, alb
    fr, fz0 = 0.13, cone_top - 0.12
    fzm = fz0 + (finial_top - fz0) * 0.4
    pts = [V(cx + fr * math.cos(a), cy + fr * math.sin(a), fzm)
           for a in (0.0, math.pi * 0.5, math.pi, math.pi * 1.5)]
    h.trim.piece(pts + [V(cx, cy, fz0), V(cx, cy, finial_top)],
                 [[i, (i + 1) % 4, 5] for i in range(4)] +
                 [[(i + 1) % 4, i, 4] for i in range(4)], S_WHITE, center=V(cx, cy, fzm))


def hip_roof(h, x0, x1, y0, y1, z, rise):
    """Acoperis in patru ape (coltul): coama pe Y (Godot Z), apele la 45 de grade in
    plan; fara streasina (cornisa alba de dedesubt da iesirea pe fatadele de
    strada, laturile spre vecini raman la fata peretelui). Corp inchis, cu bevel
    de silueta."""
    run = (x1 - x0) * 0.5
    xm = (x0 + x1) * 0.5
    vs = [V(x0, y0, z), V(x1, y0, z), V(x1, y1, z), V(x0, y1, z),
          V(xm, y0 + run, z + rise), V(xm, y1 - run, z + rise)]
    faces = [[0, 3, 5, 4], [1, 4, 5, 2], [3, 2, 5], [0, 4, 1]]
    h.trim_bev.piece(vs, faces, S_DARK, center=V(xm, (y0 + y1) * 0.5, z + rise * 0.3))


# --- Final: noduri, UV, AO -------------------------------------------------------

def _group_object(part, name):
    if not part.faces:
        return None
    obj = part.to_object(name)
    snap = snapshot_slots(obj)  # noqa: F821  (din dio_lib)
    if part.bevel:
        apply_bevel(obj, BEVEL_W, segments=1, angle_deg=30.0)  # noqa: F821
    assign_uvs(obj, snap)  # noqa: F821
    return obj


def _join(objs, name):
    objs = [o for o in objs if o is not None]
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


def _face_slot(me, uv, poly):
    u = uv.data[poly.loop_indices[0]].uv[0]
    return max(0, min(31, int(math.floor(u * 32))))


def bake_house_ao(nodes, wall_z=(LEVEL, 12.45), samples_wall=64, samples_trim=32,
                  dist=1.4, wall_ao="overhead"):
    """AO copt pe colturi (CORNER), cu ocluzia masurata pe TOATA casa (ambele
    noduri), nu pe nodul curent: cornisa (Trim) umbreste peretele (Wall).

    Reguli (brief §6), aplicate pe fata dupa slotul ei:
      - perete (19), `wall_ao="overhead"` (v2): gradient 0,78 la `wall_z[0]` ->
        1,0 la `wall_z[1]`, inmultit cu ocluzia DE DEASUPRA (doar razele care urca,
        dz > 0,15): asa se intuneca exact ce sta sub o streasina — sub bovindou,
        sub cornise, sub pervaze — pana la ~0,7 (podea 0,68), iar ocluzia
        laterala (peretele de langa bovindou, ramele) nu mai coboara planuri
        intregi. Masurat pe v1: podeaua de 0,62 cu ocluzie din toate directiile a
        dus V-ul fetelor cu spatele la soare de la 0,510 (casele din cod) la 0,427;
      - perete (19), `wall_ao="v1"`: gradient x (1 - 0,6 x ocluzia totala), podea
        0,62 (pilotul v1);
      - piatra/fusta (8): 0.70 la -2.4 -> 0.85 la 0 -> 0.92 la +3.2;
      - nisa si usa (28): ~0.55;
      - sticla (20, verticala): ~0.6; ardezia (20, inclinata): 0.85 -> 1.0;
      - alb (22), garaj (9): ocluzie geometrica pe gradient usor."""
    tris, verts = [], []
    for o in nodes:
        me = o.data
        me.calc_loop_triangles()
        base = len(verts)
        verts.extend(v.co.copy() for v in me.vertices)
        tris.extend(tuple(base + i for i in lt.vertices) for lt in me.loop_triangles)
    bvh = BVHTree.FromPolygons(verts, tris, all_triangles=True)
    stats = {}
    for o in nodes:
        me = o.data
        uv = me.uv_layers.active
        is_wall = o.name.endswith("Wall")
        dirs = _hemisphere_dirs(samples_wall if is_wall else samples_trim)  # noqa: F821
        for ca in list(me.color_attributes):
            me.color_attributes.remove(ca)
        ca = me.color_attributes.new(name="AO", type="FLOAT_COLOR", domain="CORNER")
        cache = {}
        vals = []
        for poly in me.polygons:
            slot = _face_slot(me, uv, poly)
            n = poly.normal.normalized()
            ref = Vector((0, 0, 1)) if abs(n.z) < 0.9 else Vector((1, 0, 0))
            tx = ref.cross(n).normalized()
            ty = n.cross(tx)
            for li in poly.loop_indices:
                vi = me.loops[li].vertex_index
                key = (vi, round(n.x, 2), round(n.y, 2), round(n.z, 2))
                co = me.vertices[vi].co
                sample = co
                if slot == S_WALL and wall_ao != "v1":
                    # Varful unei fete de perete sta des chiar pe muchia unei piese
                    # albe lipite (pilastru, brau, rama, ancadrament): razele de acolo
                    # lovesc piesa la distanta 0 si coltul iese negru, iar culoarea
                    # interpolata intuneca toata fata (asa ajunsese v1 la podea).
                    # Se masoara deci la ~0,3 m INAUNTRUL fetei (spre centrul ei), in
                    # primul punct neacoperit de o piesa lipita (raza pe normala
                    # libera 0,2 m): AO-ul pe varfuri se interpoleaza peste fete de
                    # 2-3 m, deci trebuie sa spuna cum arata zona de langa colt, nu
                    # muchia de 1 cm de sub o banda de 0,05 m. Sub cornisa (0,35) si
                    # sub bovindou (0,86) ocluzia ramane mare si la 0,3 m: ~0,7.
                    key = ("w", poly.index, li)
                    to_c = poly.center - co
                    lc = to_c.length
                    if lc > 1e-6:
                        for dd in (0.3, 0.6, 1.0, 1.5, 2.2):
                            sp = co + to_c * (min(dd, 0.9 * lc) / lc)
                            if bvh.ray_cast(sp + n * 0.004, n, 0.2)[0] is None:
                                sample = sp
                                break
                            if dd >= 0.9 * lc:
                                break
                hit_cache = cache.get(key)
                if hit_cache is None:
                    org = sample + n * 0.004
                    acc = acc_up = 0.0
                    n_up = 0
                    for d in dirs:
                        dv = tx * d.x + ty * d.y + n * d.z
                        hit = bvh.ray_cast(org, dv, dist)
                        o_ = 0.0 if hit[0] is None else 1.0 - min(hit[3] / dist, 1.0)
                        acc += o_
                        if dv.z > 0.15:
                            # "de deasupra" = lovitura cu cel putin 8 cm mai sus:
                            # fara prag, laturile montantilor si pilastrilor de
                            # langa punct (razant, la 1-4 cm) contau ca streasina
                            if hit[0] is not None and hit[0].z - org.z > 0.08:
                                acc_up += o_
                            n_up += 1
                    hit_cache = (acc / len(dirs), acc_up / n_up if n_up else 0.0)
                    cache[key] = hit_cache
                occ, occ_up = hit_cache
                z = co.z
                if slot == S_WALL:
                    t = max(0.0, min(1.0, (z - wall_z[0]) / (wall_z[1] - wall_z[0])))
                    if wall_ao == "v1":
                        val = max(0.62, (0.78 + 0.22 * t) * (1.0 - 0.6 * occ))
                    else:
                        val = max(0.68, (0.78 + 0.22 * t) * (1.0 - 0.5 * occ_up))
                elif slot == S_STONE:
                    if z <= 0.0:
                        g = 0.70 + 0.15 * (z - SKIRT) / (-SKIRT)
                    else:
                        g = 0.85 + 0.07 * min(1.0, z / LEVEL)
                    val = max(0.45, g * (1.0 - 0.9 * occ))
                elif slot == S_NICHE:
                    val = max(0.40, 0.62 * (1.0 - 0.6 * occ))
                elif slot == S_DARK and abs(n.z) < 0.35:
                    val = max(0.45, 0.66 * (1.0 - 0.5 * occ))
                elif slot == S_DARK:
                    t = max(0.0, min(1.0, (z - EAVE) / 3.0))
                    val = max(0.55, (0.85 + 0.15 * t) * (1.0 - 0.7 * occ))
                elif slot == S_GARAGE:
                    val = max(0.45, 0.82 * (1.0 - 0.8 * occ))
                else:  # alb si restul
                    t = max(0.0, min(1.0, (z - SKIRT) / (12.6 - SKIRT)))
                    val = max(0.5, (0.9 + 0.1 * t) * (1.0 - 0.9 * occ))
                val = min(1.0, val)
                ca.data[li].color = (val, val, val, 1.0)
                vals.append(val)
        me.color_attributes.active_color_index = 0
        me.color_attributes.render_color_index = 0
        stats[o.name] = (round(min(vals), 3), round(sum(vals) / len(vals), 3), round(max(vals), 3))
    return stats


def mirror_house(h):
    """Oglindeste casa in lucru fata de planul X = 0 (garajul trece pe -X,
    intrarea pe +X): x -> -x pe varfuri si ordinea fiecarei fete inversata, ca
    normalele sa ramana spre exterior. Se cheama INAINTE de `finish_house`, deci
    bevelul, UV-urile, netezirea si AO-ul se fac pe geometria deja oglindita, iar
    nodurile ies cu transformari identitate (determinant pozitiv).

    De ce o varianta pre-oglindita, nu `scale.x = -1` in joc: masurat la pasul 7,
    o instanta cu scala negativa intr-un MultiMesh se randeaza pe dos (cu fetele
    din spate), iar randurile din spate se instantiaza tocmai asa."""
    for p in (h.wall, h.trim, h.trim_bev):
        p.verts = [Vector((-v.x, v.y, v.z)) for v in p.verts]
        p.faces = [list(reversed(f)) for f in p.faces]


def finish_house(h, smooth_angle=55.0, wall_ao="overhead", wall_z=(LEVEL, 12.45)):
    """Grupuri -> bevel (doar pe `bev`) -> UV pe sloturi -> doua noduri ->
    AO -> material. Fara mutare de origine (fusta ramane la -2.4)."""
    wall = _join([_group_object(h.wall, "Row_Wall_g0")], "Row_Wall")
    trim = _join([_group_object(h.trim, "Row_Trim_g0"),
                  _group_object(h.trim_bev, "Row_Trim_g1")], "Row_Trim")
    for o in (wall, trim):
        apply_smooth(o, smooth_angle)  # noqa: F821
        if "slot" in o.data.attributes:
            o.data.attributes.remove(o.data.attributes["slot"])
        o.data.materials.clear()
        o.data.materials.append(atlas_material())  # noqa: F821
        o.location = (0.0, 0.0, 0.0)
        o.rotation_euler = (0.0, 0.0, 0.0)
        o.scale = (1.0, 1.0, 1.0)
    ao = bake_house_ao([wall, trim], wall_z=wall_z, wall_ao=wall_ao)
    return wall, trim, ao
