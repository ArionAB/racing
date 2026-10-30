"""Carrara -- satul Colonnata si blocul-semn (brief docs/asset_briefs/carrara_kit.md §1.4), grupa crr-e.

  carrara/buildings/colonnata_church.glb    biserica de piatra cu clopotnita (14 m)
  carrara/buildings/colonnata_house_a.glb   casa A: 9 x 7, doua niveluri, coama 8 m (streasina spre +Y)
  carrara/buildings/colonnata_house_b.glb   casa B: 7 x 8, coama 8,5 m, FRONTONUL spre +Y, horn mare
  carrara/buildings/colonnata_house_c.glb   casa C: 10 x 7, coama 7,5 m, scara exterioara + terasa
  carrara/props/quarry_sign_block.glb       blocul-semn 3 x 2 x 2 m cu o fata slefuita pe +Y

Colturile muzeului (`museum_set_*`) sunt ale grupei crr-d, nu de aici.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_crr_buildings.py
Variabila de mediu CRR_ONLY=<piesa> reface doar piesa respectiva.

Axe: X latime, Y adancime (fata spre +Y in Blender = -Z in Godot), Z sus. Piesele
se construiesc DIRECT fata de originea lor (centrul corpului principal, baza la
z = 0); exportul nu muta nimic (`emit_keep`), deci offsetul e acelasi pe toate
nodurile prin constructie (memoria `finish-recentreaza-fiecare-nod-separat`).

Un nod = un rol / o clasa (kit §0 regula 6, brief §4):
  *_Stone   MARBLE_GREY 29   zidaria (clasa `tf_stone` la integrare): pereti,
                             pietre de colt, ancadramente, cosuri, trepte
  *_Roof    TILE_TERRACOTTA 23  tigla (clasa de tigla la integrare)
  *_Wood    WOOD_WEATHERED 9 usile; LOG_DARK 28 curelele usilor, montantii,
                             crucea, balustrada
  *_Shutter CACTUS_GREEN 12  obloanele verzi (doar casele)
  *_Void    VOLCANIC_BLACK 20 fundul golurilor (ferestre, clopotnita, oculi)
  Sign_Marble / Sign_MarbleBase  CORAL_SAND 19 / MARBLE_GREY 29 (regula 8)

Golurile sunt GOLURI reale (tiparul `build_tf_buildings.Openings`): corpul plin
e taiat boolean `OPEN_D` in adanc, iar fundul golului e acoperit, 2 mm in fata,
de placa neagra din `*_Void` (sau de canatul usii in `*_Wood`). Ancadramentele de
piatra si pietrele de colt ies 4-8 cm din perete: la 120-160 m (brief §2, randul
G) nu se vad, dar dau umbra pe planșa si pe drum aproape. Ce se citeste de
departe e SILUETA (masele, acoperisurile, clopotnita, hornul, scara), deci
fiecare casa are alta silueta (contract §1.4).

Acoperisurile: `tin_roof` din transfagarasan_shapes cu nervurile folosite ca
RANDURI DE OLANE (canale de 24 cm la pasul de 0,55 m, pe panta), placa de 24 cm.
Fara text, fara vegetatie lipita (corecturile coordonatorului).
"""

import math
import os
import random
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "carrara_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("CRR_ONLY", "")

# --- sloturile pe roluri (kit §0, tabelul de sloturi; brief §4) ---------------
V_STONE = MARBLE_GREY       # 29: piatra satului (*_Stone, clasa tf_stone)
V_ROOF = TILE_TERRACOTTA    # 23: tigla (*_Roof)
V_WOOD = WOOD               # 9:  usile (WOOD_WEATHERED)
V_DARK = LOG_DARK           # 28: lemnaria umbrita, crucea de fier, balustrada
V_SHUT = CACTUS_GREEN       # 12: obloanele verzi
V_VOID = VOLCANIC_BLACK     # 20: golurile

OPEN_D = 0.24               # adancimea golurilor
GAP = 0.002                 # distanta dintre straturi (anti-furt de slot)
ARCH_SEG = 8                # laturi pe semicerc (16 pe cerc intreg: kit, 8-16)
ROUND_SEG = 12              # oculii
OV = 0.35                   # streasina (pe panta)
VERGE = 0.25                # iesirea acoperisului peste fronton
ROOF_T = 0.24               # grosimea placii de tigla (runda 2: 0,18 -> 0,24, streasina groasa ca pe decupari)
CAP = (0.36, 0.17)          # coama (latime, inaltime)
# Randurile de olane: canale de 24 cm la pasul de 0,55 m. Runda 1 avea 13 cm la
# 0,34 m si citea TABLA CUTATA, nu tigla (decuparile: ~15 randuri pe 9 m).
ROOF_KW = dict(thick=ROOF_T, rib_h=0.10, rib_w=0.24, step=0.55, cap=CAP)


def ao_for(top):
    return dict(samples=16, dist=1.6, gradient="vertical", low=0.66, high=1.0,
                power=0.8, floor=0.38, z_range=(0.0, top))


# ---------------------------------------------------------------------------
# unelte: puncte pe o fata, prisme, goluri, boolean
# ---------------------------------------------------------------------------

def _fp(face, at, a, out, z):
    """Punctul (de-a lungul fetei `a`, iesire din fata `out`, cota z) pe fata
    `face` ('+X', '-X', '+Y', '-Y') aflata la coordonata absoluta `at`."""
    s = 1.0 if face[0] == "+" else -1.0
    if face[1] == "Y":
        return Vector((a, at + s * out, z))
    return Vector((at + s * out, a, z))


def prism_face(b, face, at, outline, out0, out1, slot):
    """Prisma dintr-un contur (a, z) al fetei, intre iesirile out0 si out1.
    Normalele le reface `Builder.to_object` (carcasa inchisa)."""
    n = len(outline)
    v0 = [b.bm.verts.new(_fp(face, at, a, out0, z)) for a, z in outline]
    v1 = [b.bm.verts.new(_fp(face, at, a, out1, z)) for a, z in outline]
    for ring in (v0, list(reversed(v1))):
        f = b.bm.faces.new(ring)
        f[b.slot] = slot
    for i in range(n):
        j = (i + 1) % n
        f = b.bm.faces.new((v0[i], v0[j], v1[j], v1[i]))
        f[b.slot] = slot


def box_face(b, face, at, a, out, z, sa, so, sz, slot):
    """Cutie cu centrul (a, out, z) pe fata, dimensiunile (de-a lungul, iesire, sus)."""
    size = (sa, so, sz) if face[1] == "Y" else (so, sa, sz)
    b.box(_fp(face, at, a, out, z), size, slot)


def prism_x(b, outline_yz, x0, x1, slot):
    """Prisma dintr-un contur (y, z) extrudat pe X (frontoane pe capetele X)."""
    prism_face(b, "+X", 0.0, outline_yz, x0, x1, slot)


def prism_y(b, outline_xz, y0, y1, slot):
    """Prisma dintr-un contur (x, z) extrudat pe Y (frontoane pe capetele Y)."""
    prism_face(b, "+Y", 0.0, outline_xz, y0, y1, slot)


def outline_rect(c, w, z0, z1):
    return [(c - w * 0.5, z0), (c + w * 0.5, z0), (c + w * 0.5, z1), (c - w * 0.5, z1)]


def outline_arch(c, w, z0, z1):
    """Dreptunghi cu semicerc deasupra; z1 = crestetul arcului."""
    r = w * 0.5
    zs = z1 - r
    pts = [(c - r, z0), (c + r, z0)]
    for k in range(ARCH_SEG + 1):
        a = math.pi * k / ARCH_SEG
        pts.append((c + r * math.cos(a), zs + r * math.sin(a)))
    return pts


def outline_round(c, zc, r, seg=ROUND_SEG):
    return [(c + r * math.cos(2 * math.pi * k / seg), zc + r * math.sin(2 * math.pi * k / seg))
            for k in range(seg)]


def shrink(outline, d):
    """Contur convex strans spre centroid cu ~d (placi de fund, canate)."""
    n = len(outline)
    ca = sum(p[0] for p in outline) / n
    cz = sum(p[1] for p in outline) / n
    out = []
    for a, z in outline:
        da, dz = a - ca, z - cz
        L = math.hypot(da, dz)
        k = max(0.0, (L - d) / L) if L > 1e-9 else 0.0
        out.append((ca + da * k, cz + dz * k))
    return out


def ring_stones(b, face, at, c, zs, r_in, band, a0, a1, n, prot, slot, key_extra=0.0):
    """Bolțari (n) pe un arc de la unghiul a0 la a1 (radiani), iesiti `prot`
    din fata; cheia (mijlocul) mai inalta cu `key_extra`."""
    g = 0.035 / max(r_in, 0.2)
    for k in range(n):
        u0 = a0 + (a1 - a0) * k / n + g * 0.5
        u1 = a0 + (a1 - a0) * (k + 1) / n - g * 0.5
        ro = r_in + band + (key_extra if k == n // 2 else 0.0)
        pts = []
        for u in (u0, u1):
            for r in (r_in, ro):
                for out in (-0.03, prot):
                    pts.append(_fp(face, at, c + r * math.cos(u), out, zs + r * math.sin(u)))
        _hull(b, pts, slot)


class Openings:
    """Golurile unei piese: cutiile de taiere (pe CORP, dupa cheie), placile
    negre de fund (`void`), canatele usilor si montantii (`wood`), ancadramentele
    de piatra (`trim`, nod de piatra, NETAIAT) si obloanele (`shutter`)."""

    def __init__(self, void_b, wood_b, trim_b, shutter_b=None):
        self.cut = {}
        self.void = void_b
        self.wood = wood_b
        self.trim = trim_b
        self.shutter = shutter_b
        self.log = []

    def add(self, key, face, at, c, w, z0, z1, kind="window", shape="rect",
            shutters=False, surround=True, cross=True, depth=OPEN_D, sill=True):
        """Gol pe fata `face` a corpului `key`, fata la coordonata `at`, centrul
        la `c` de-a lungul fetei, latimea `w`, de la z0 la z1 (la arc: crestetul;
        la `round`: z0..z1 e diametrul)."""
        if shape == "rect":
            ol = outline_rect(c, w, z0, z1)
        elif shape == "arch":
            ol = outline_arch(c, w, z0, z1)
        else:
            ol = outline_round(c, (z0 + z1) * 0.5, w * 0.5)
        cb = self.cut.setdefault(key, Builder())
        prism_face(cb, face, at, ol, 0.3, -depth, 0)
        if kind == "door":
            # canatul de lemn, retras; doua curele LOG_DARK pe el
            prism_face(self.wood, face, at, shrink(ol, 0.012), -depth + GAP, -depth + 0.07, V_WOOD)
            for zz in (z0 + 0.45, z0 + min(1.75, (z1 - z0) * 0.62)):
                box_face(self.wood, face, at, c, -depth + 0.085, zz, w - 0.16, 0.03, 0.10, V_DARK)
            box_face(self.wood, face, at, c, -depth + 0.085, (z0 + z1) * 0.45, 0.05, 0.03,
                     (z1 - z0) * 0.8, V_DARK)
        else:
            prism_face(self.void, face, at, shrink(ol, 0.003), -depth + GAP, -depth + GAP + 0.02, V_VOID)
            if cross and shape == "rect" and w >= 0.6:
                ins = -depth * 0.45
                box_face(self.wood, face, at, c, ins, (z0 + z1) * 0.5, 0.05, 0.04, z1 - z0 - 0.01, V_DARK)
                box_face(self.wood, face, at, c, ins, z0 + (z1 - z0) * 0.62, w - 0.01, 0.04, 0.05, V_DARK)
        if surround:
            self._surround(face, at, c, w, z0, z1, kind, shape, sill)
        if shutters and self.shutter is not None:
            # doua canate deschise, lipite de perete (3 cm in fata lui)
            sw = w * 0.5 + 0.03
            for s in (-1, 1):
                ac = c + s * (w * 0.5 + 0.10 + sw * 0.5)
                box_face(self.shutter, face, at, ac, 0.045, (z0 + z1) * 0.5, sw, 0.05,
                         z1 - z0 + 0.04, V_SHUT)
        self.log.append((key, face, kind, shape, round(w, 2), round(z1 - z0, 2)))

    def _surround(self, face, at, c, w, z0, z1, kind, shape, sill=True):
        t = self.trim
        if shape == "round":
            ring_stones(t, face, at, c, (z0 + z1) * 0.5, w * 0.5, 0.13, 0.0, 2 * math.pi,
                        ROUND_SEG, 0.04, V_STONE)
            return
        if shape == "arch":
            r = w * 0.5
            zs = z1 - r
            band = 0.28 if kind == "door" else 0.16
            ring_stones(t, face, at, c, zs, r, band, 0.0, math.pi, 9 if kind == "door" else 7,
                        0.05, V_STONE, key_extra=0.06)
            if kind == "door":
                # pietrele de toc, de la prag la nastere
                for s in (-1, 1):
                    box_face(t, face, at, c + s * (r + band * 0.5), 0.01, (z0 + zs) * 0.5,
                             band, 0.08, zs - z0 - 0.02, V_STONE)
                self._threshold(face, at, c, w + 2 * band + 0.3, z0)
            elif sill:
                box_face(t, face, at, c, 0.05, z0 - 0.04, w + 0.2, 0.14, 0.08, V_STONE)
            return
        # dreptunghi: buiandrug de piatra + pervaz (fereastra) / prag (usa)
        box_face(t, face, at, c, 0.015, z1 + 0.09, w + 0.26, 0.07, 0.18, V_STONE)
        if kind == "window":
            if sill:
                box_face(t, face, at, c, 0.05, z0 - 0.04, w + 0.2, 0.14, 0.08, V_STONE)
        else:
            self._threshold(face, at, c, w + 0.4, z0)

    def _threshold(self, face, at, c, w, z0):
        """Pragul de piatra al usii: de la z0 - 0,14 (dar nu sub sol) la z0,
        iesit 0,4 m in fata peretelui."""
        za = max(0.0, z0 - 0.14)
        if z0 - za > 0.02:
            box_face(self.trim, face, at, c, 0.10, (za + z0) * 0.5, w, 0.6, z0 - za, V_STONE)

    def apply(self, key, obj, slot=V_STONE):
        """Taie golurile corpului `key` (boolean EXACT) si pune corpul pe `slot`."""
        if key in self.cut:
            cutter = Builder.to_object(self.cut[key], "Cutter_" + key)
            bool_apply(obj, cutter, "DIFFERENCE")
            bpy.data.objects.remove(cutter, do_unlink=True)
        retag_all(obj, slot)
        return obj


def bool_apply(obj, cutter, op):
    mod = obj.modifiers.new("Bool", "BOOLEAN")
    mod.operation = op
    mod.object = cutter
    mod.solver = "EXACT"
    mod.use_self = True
    mod.use_hole_tolerant = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)


def retag_all(obj, slot):
    """Dupa boolean, fetele noi n-au slot (ar cadea pe 0): tot corpul pe `slot`."""
    me = obj.data
    a = me.attributes.get("slot")
    if a is None or a.domain != "FACE":
        if a is not None:
            me.attributes.remove(a)
        a = me.attributes.new("slot", "INT", "FACE")
    for i in range(len(me.polygons)):
        a.data[i].value = slot


def join(objs, name):
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    objs[0].name = name
    objs[0].data.name = name
    return objs[0]


def quoins(b, x0, x1, y0, y1, z0, z1, corners=None, h=0.40, gap=0.035,
           long_=0.62, short=0.36, prot=0.04, slot=V_STONE):
    """Pietre de colt alternante (lungi / scurte), iesite `prot` pe ambele fete
    ale coltului; `corners` = lista de (sx, sy), implicit toate patru."""
    n = int((z1 - z0) / (h + gap))
    for sx, sy in (corners or ((1, 1), (1, -1), (-1, 1), (-1, -1))):
        xe = x1 if sx > 0 else x0
        ye = y1 if sy > 0 else y0
        for k in range(n):
            za = z0 + k * (h + gap)
            lx, ly = (long_, short) if k % 2 == 0 else (short, long_)
            xa, xb = xe + sx * prot, xe - sx * lx
            ya, yb = ye + sy * prot, ye - sy * ly
            b.box(((xa + xb) * 0.5, (ya + yb) * 0.5, za + h * 0.5),
                  (abs(xa - xb), abs(ya - yb), h), slot)


def solve_pitch(H, zw, half, thick=ROOF_T, ov=OV, cap=CAP):
    """Panta (tan) pentru care capacul coamei ajunge la H cand peretele de sub
    streasina se opreste la zw (ecuatia lui tin_roof, rezolvata prin bisectie).
    Intoarce (tan, z_eave)."""
    lo, hi = 0.05, 3.0
    for _ in range(60):
        t = (lo + hi) * 0.5
        sec = math.sqrt(1.0 + t * t)
        z_eave = zw + 0.02 + thick * sec - ov * t
        top = z_eave + (half + ov) * t + cap[1] - 0.02
        if top > H:
            hi = t
        else:
            lo = t
    t = (lo + hi) * 0.5
    sec = math.sqrt(1.0 + t * t)
    return t, zw + 0.02 + thick * sec - ov * t


def gable_roof(roof_b, cx, cy, length, half, zw, H, axis):
    """Acoperis in doua ape de tigla: coama pe `axis`, lung `length` (fara
    streasina de fronton), jumatatea de deschidere `half` (perete-axa), peretele
    se opreste la zw, capacul coamei la H. Intoarce dict-ul lui tin_roof + pitch."""
    t, z_eave = solve_pitch(H, zw, half)
    R = tin_roof(roof_b, cx, cy, length * 0.5 + VERGE, half + OV, z_eave,
                 math.degrees(math.atan(t)), V_ROOF, kind="gable", axis=axis, **ROOF_KW)
    R["pitch"] = math.degrees(math.atan(t))
    return R


def chimney(stone_b, void_b, x, y, z0, z_top, sx=0.8, sy=0.8):
    """Cos de piatra cu coronament (placa iesita) si gura neagra."""
    stone_b.box((x, y, (z0 + z_top) * 0.5), (sx, sy, z_top - z0), V_STONE)
    stone_b.box((x, y, z_top + 0.07), (sx + 0.18, sy + 0.18, 0.14), V_STONE)
    stone_b.box((x, y, z_top + 0.22), (sx * 0.45, sy * 0.45, 0.16), V_STONE)
    void_b.box((x, y, z_top + 0.30 + GAP), (sx * 0.30, sy * 0.30, 0.01), V_VOID)


def emit_keep(objs, path, ao):
    """Finish pe fiecare nod FARA sa mute nimic (piesele sunt construite cu
    baza la z = 0 si originea pe centrul corpului principal) + export."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    if abs(min(zs)) > 1e-4:
        raise RuntimeError("%s: baza la z %.4f, nu la 0" % (path, min(zs)))
    total, per_node = 0, {}
    for o in objs:
        st = finish(o, bevel=0.0, bevel_angle=30.0, ao=ao, origin=None, smooth_angle=None)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    print("%s: bbox X %.2f..%.2f  Y %.2f..%.2f  Z %.2f..%.2f" % (
        path, min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
    _, sz = export_glb(objs, "carrara/" + path)
    CRR_RESULTS.append((path, total, dims, per_node, sz / 1024.0))
    return total


def gable_body(b, x0, x1, y0, y1, zw, R, axis):
    """Corpul plin al unei case: peretii pana la zw plus podul (prisma
    triunghiulara) pana sub tigla; podul incepe 0,1 m sub zw (volume suprapuse,
    nu fete coplanare, pentru boolean)."""
    b.box(((x0 + x1) * 0.5, (y0 + y1) * 0.5, zw * 0.5), (x1 - x0, y1 - y0, zw), V_STONE)
    if axis == "X":
        yc = (y0 + y1) * 0.5
        zr = R["under"](0.5 * (x0 + x1), yc) - 0.02
        prism_x(b, [(y0, zw - 0.1), (y1, zw - 0.1), (y1, zw), (yc, zr), (y0, zw)], x0, x1, V_STONE)
    else:
        xc = (x0 + x1) * 0.5
        zr = R["under"](xc, 0.5 * (y0 + y1)) - 0.02
        prism_y(b, [(x0, zw - 0.1), (x1, zw - 0.1), (x1, zw), (xc, zr), (x0, zw)], y0, y1, V_STONE)


def steps(b, x, y, w, d, n, rise, face="+Y"):
    """`n` trepte de piatra in fata unei usi (fata `face`), fiecare de `rise`."""
    for k in range(n):
        dd = d * (n - k) / n
        if face == "+Y":
            b.box((x, y + dd * 0.5, rise * (k + 0.5)), (w, dd, rise), V_STONE)
        elif face == "+X":
            b.box((x + dd * 0.5, y, rise * (k + 0.5)), (dd, w, rise), V_STONE)
        elif face == "-X":
            b.box((x - dd * 0.5, y, rise * (k + 0.5)), (dd, w, rise), V_STONE)
        else:
            b.box((x, y - dd * 0.5, rise * (k + 0.5)), (w, dd, rise), V_STONE)


# ---------------------------------------------------------------------------
# colonnata_church
# ---------------------------------------------------------------------------

CH_NAVE = (-4.0, 4.0, -7.0, 7.0)    # 8 x 14 m
CH_ZW = 7.4
CH_H = 10.0
CH_ANNEX = (-3.2, 3.2, 7.0, 10.8)
CH_ANNEX_ZW, CH_ANNEX_H = 4.5, 6.5
CH_WING = (-7.6, -3.2, 1.0, 7.4)
CH_WING_ZW, CH_WING_H = 4.3, 6.2
CH_TOWER = (4.0, 8.0, 3.4, 7.4)     # 4 x 4 m, iesita 0,4 m in fata navei
CH_SHAFT = 11.0
CH_APEX = 13.05
CH_TOTAL = 14.0


def build_colonnata_church():
    """LISTA DE ELEMENTE (decuparea `colonnata_church.png`, scrisa INAINTE de
    primul vertex; cotele din kit §1.4, corecturile kitului bat decuparea).
    Decuparea e 3/4 din fata-stanga: fata cu usa (+Y) in stanga, latura -X in
    dreapta, clopotnita in stanga (deci pe +X).

     1. NAVA 8 x 14 m (X x Y), pereti 7,4 m, acoperis in DOUA APE cu coama pe Y,
        capacul coamei la 10,0 m; frontonul spre +Y; streasina 0,35, iesirea
        peste fronton 0,25.
     2. PRONAOSUL (corpul jos din fata, cu usa): 6,4 x 3,8 m, pereti 4,5,
        coama 6,5, fronton spre +Y. USA ARCUITA 1,5 x 3,0 m cu 9 BOLȚARI (cheia
        mai inalta), pietre de toc si prag; deasupra o fereastra mica si un
        OCULUS in fronton; o fereastra mica pe latura -X; DOUA TREPTE in fata.
     3. ANEXA LATERALA (sacristia, corpul jos din dreapta decuparii): pe -X,
        4,4 x 6,4 m, pereti 4,3, coama 6,2 pe X, frontonul spre -X cu un OCULUS
        si o FEREASTRA INALTA ARCUITA; o fereastra mica pe +Y.
     4. CLOPOTNITA 4 x 4 m pe +X, lipita de nava in fata (y 3..7): ferestre-
        fanta (2 pe +Y, 2 pe +X, 1 pe -Y), BRAU la 9,3 m (runda 2: 8,6), CLOPOTNITA cu 2
        FERESTRE ARCUITE pe FIECARE fata (8; decuparea arata 2 pe fata vazuta),
        cornisa la 11 m, ACOPERIS PIRAMIDAL de tigla pana la 13,05 m, CRUCE de
        fier (LOG_DARK) pana la 14,0 m. Runda 2: ferestrele clopotnitei 0,74 x
        1,77 m (erau 1,10 inalte: decuparea le are cat o noua parte din turn),
        braul coborat la 8,6 m, streasina piramidei 0,45 m (era 0,30).
     5. NAVA, golurile: frontonul +Y (deasupra pronaosului) o fereastra si un
        oculus (decuparea: oculus sus, fereastra dedesubt); laturile cate 2
        ferestre inalte; spatele (-Y) o fereastra si un oculus.
     6. PIETRE DE COLT alternante, iesite 4 cm, pe colturile libere ale navei,
        pronaosului, anexei si clopotnitei (decuparea: colturi din blocuri).
     7. NU intra: chiparosii, tufele, bolovanii si dalele din fata (corectura
        de kit); clopotul (nu se vede din cauza fundului negru al golului).
    Noduri: Church_Stone (29), Church_Roof (23), Church_Wood (9 usa + 28
    curelele, montantii, crucea), Church_Void (20)."""
    roof, void, wood, trim = Builder(), Builder(), Builder(), Builder()
    op = Openings(void, wood, trim)
    nx0, nx1, ny0, ny1 = CH_NAVE

    # --- 1. nava ----------------------------------------------------------------
    nave_b = Builder()
    R_n = gable_roof(roof, 0.0, 0.0, ny1 - ny0, (nx1 - nx0) * 0.5, CH_ZW, CH_H, "Y")
    gable_body(nave_b, nx0, nx1, ny0, ny1, CH_ZW, R_n, "Y")
    # 5. golurile navei
    op.add("nave", "+Y", ny1, 0.0, 0.75, 6.75, 7.65)                       # deasupra pronaosului
    op.add("nave", "+Y", ny1, 0.0, 0.72, 8.25, 8.97, shape="round")        # oculusul
    for y in (-1.6, -5.0):
        op.add("nave", "-X", nx0, y, 0.72, 4.6, 6.2)
        op.add("nave", "+X", nx1, y, 0.72, 4.6, 6.2)
    op.add("nave", "-Y", ny0, 0.0, 0.9, 3.4, 5.4, shape="arch")
    op.add("nave", "-Y", ny0, 0.0, 0.72, 8.25, 8.97, shape="round")

    # --- 2. pronaosul -------------------------------------------------------------
    ax0, ax1, ay0, ay1 = CH_ANNEX
    annex_b = Builder()
    R_a = gable_roof(roof, 0.0, (ay0 + ay1) * 0.5 - 0.15, ay1 - ay0 + 0.3, (ax1 - ax0) * 0.5,
                     CH_ANNEX_ZW, CH_ANNEX_H, "Y")
    gable_body(annex_b, ax0, ax1, ay0 - 0.3, ay1, CH_ANNEX_ZW, R_a, "Y")
    op.add("annex", "+Y", ay1, 0.0, 1.5, 0.30, 3.30, kind="door", shape="arch")
    op.add("annex", "+Y", ay1, 0.0, 0.5, 3.95, 4.55, cross=False)
    op.add("annex", "+Y", ay1, 0.0, 0.48, 5.12, 5.60, shape="round")
    op.add("annex", "-X", ax0, 9.0, 0.55, 1.6, 2.5, cross=False)
    steps(trim, 0.0, ay1, 2.9, 1.0, 2, 0.15)

    # --- 3. anexa laterala (sacristia) -------------------------------------------
    wx0, wx1, wy0, wy1 = CH_WING
    wing_b = Builder()
    # tigla de la frontonul -X (cu iesirea VERGE) pana in peretele pronaosului
    wr0, wr1 = wx0 - VERGE, -3.1
    R_w = gable_roof(roof, (wr0 + wr1) * 0.5, (wy0 + wy1) * 0.5, wr1 - wr0 - 2 * VERGE,
                     (wy1 - wy0) * 0.5, CH_WING_ZW, CH_WING_H, "X")
    gable_body(wing_b, wx0, wx1, wy0, wy1, CH_WING_ZW, R_w, "X")
    op.add("wing", "-X", wx0, (wy0 + wy1) * 0.5, 0.8, 1.5, 3.35, shape="arch")
    op.add("wing", "-X", wx0, (wy0 + wy1) * 0.5, 0.44, 4.55, 4.99, shape="round")
    op.add("wing", "+Y", wy1, -5.6, 0.55, 2.0, 2.85, cross=False)

    # --- 4. clopotnita ------------------------------------------------------------
    tx0, tx1, ty0, ty1 = CH_TOWER
    tcx, tcy = (tx0 + tx1) * 0.5, (ty0 + ty1) * 0.5
    tower_b = Builder()
    tower_b.box((tcx, tcy, CH_SHAFT * 0.5), (tx1 - tx0, ty1 - ty0, CH_SHAFT), V_STONE)
    # brau si cornisa (in nodul de piatra, netaiate)
    trim.box((tcx, tcy, 8.62), (tx1 - tx0 + 0.16, ty1 - ty0 + 0.16, 0.22), V_STONE)
    trim.box((tcx, tcy, CH_SHAFT - 0.12), (tx1 - tx0 + 0.26, ty1 - ty0 + 0.26, 0.24), V_STONE)
    # acoperisul piramidal: hip cu hx = hy (coama de lungime zero)
    half = (tx1 - tx0) * 0.5
    t_t, ze_t = solve_pitch(CH_APEX, CH_SHAFT - 0.02, half, ov=0.45)
    R_t = tin_roof(roof, tcx, tcy, half + 0.45, half + 0.45, ze_t, math.degrees(math.atan(t_t)),
                   V_ROOF, kind="hip", **ROOF_KW)
    # crucea de fier
    z_ap = R_t["ridge_z"]
    wood.box((tcx, tcy, (z_ap + CH_TOTAL) * 0.5), (0.10, 0.10, CH_TOTAL - z_ap), V_DARK)
    wood.box((tcx, tcy, CH_TOTAL - 0.30), (0.10, 0.52, 0.09), V_DARK)
    # golurile: fante pe trunchi, 2 ferestre arcuite pe fiecare fata a clopotnitei
    for (face, at, c) in (("+Y", ty1, tcx), ("-Y", ty0, tcx), ("+X", tx1, tcy), ("-X", tx0, tcy)):
        for s in (-1, 1):
            op.add("tower", face, at, c + s * 0.85, 0.74, 8.95, 10.72, shape="arch")
    for (face, at, c, zz) in (("+Y", ty1, tcx, 5.2), ("+Y", ty1, tcx, 7.6),
                              ("+X", tx1, tcy, 3.4), ("+X", tx1, tcy, 6.6),
                              ("-Y", ty0, tcx, 7.6)):
        op.add("tower", face, at, c, 0.26, zz, zz + 0.75, cross=False)

    # --- 6. pietrele de colt -------------------------------------------------------
    quoins(trim, nx0, nx1, ny0, ny1, 0.25, CH_ZW, corners=((1, -1), (-1, -1)))
    quoins(trim, nx0, nx1, ny0, ny1, CH_WING_H, CH_ZW, corners=((-1, 1),))
    quoins(trim, ax0, ax1, ay0, ay1, 0.25, CH_ANNEX_ZW, corners=((1, 1), (-1, 1)))
    quoins(trim, wx0, wx1, wy0, wy1, 0.25, CH_WING_ZW, corners=((-1, 1), (-1, -1)))
    quoins(trim, tx0, tx1, ty0, ty1, 0.25, 9.1, corners=((1, 1), (1, -1), (-1, 1)))

    bodies = [op.apply("nave", Builder.to_object(nave_b, "NaveBody")),
              op.apply("annex", Builder.to_object(annex_b, "AnnexBody")),
              op.apply("wing", Builder.to_object(wing_b, "WingBody")),
              op.apply("tower", Builder.to_object(tower_b, "TowerBody"))]
    stone = join(bodies + [Builder.to_object(trim, "ChurchTrim")], "Church_Stone")
    print("colonnata_church: nava panta %.1f, pronaos %.1f, anexa %.1f, turn %.1f; varf %.2f; goluri %d"
          % (R_n["pitch"], R_a["pitch"], R_w["pitch"], math.degrees(math.atan(t_t)), z_ap,
             len(op.log)))
    return [stone, Builder.to_object(roof, "Church_Roof"), Builder.to_object(wood, "Church_Wood"),
            to_obj(void, "Church_Void")]


# ---------------------------------------------------------------------------
# colonnata_house_a / _b / _c
# ---------------------------------------------------------------------------

def _house_nodes(op, body_keys, trim, roof, wood, shutter, void):
    bodies = [op.apply(k, Builder.to_object(b, "Body_" + k)) for k, b in body_keys]
    stone = join(bodies + [Builder.to_object(trim, "HouseTrim")], "House_Stone")
    return [stone, Builder.to_object(roof, "House_Roof"), Builder.to_object(wood, "House_Wood"),
            Builder.to_object(shutter, "House_Shutter"), to_obj(void, "House_Void")]


def build_colonnata_house_a():
    """Casa A (`colonnata_house_a`), kit §1.4: 9 x 7 m, doua niveluri, coama 8 m.

    LISTA DE ELEMENTE (decuparea `colonnata_house_a.png`, scrisa INAINTE de
    primul vertex). Decuparea e 3/4 din dreapta-fata: frontonul cu usa in
    stanga, latura lunga in dreapta -> latura lunga e fata bogata +Y, frontonul
    cu usa e +X; camera de comparatie pe azimutul 55.
     1. CORP de piatra 9 (X) x 7 (Y), pereti 5,5 m (doua niveluri), acoperis in
        DOUA APE de tigla cu coama pe X, capacul la 8,0 m; streasina 0,35.
     2. LATURA LUNGA +Y: 2 ferestre sus + 2 jos, una sub alta, toate cu
        OBLOANE VERZI (decuparea: 4 ferestre cu obloane, in jumatatea dinspre
        -X), cu pervaz si buiandrug de piatra; o treapta lata de piatra la
        coltul -X (decuparea: platforma cu trepte in dreapta jos).
     3. FRONTONUL +X: USA ARCUITA 1,2 x 2,5 m cu bolțari si toc de piatra, o
        fereastra cu obloane la etaj, o fereastra mica de pod in fronton.
     4. SPATELE si frontonul -X: 2 + 1 ferestre (nu se vad pe decupare, ca sa
        nu fie oarbe din alte azimuturi).
     5. HORN de piatra mic pe coama, spre +X (decuparea: hornul langa fronton).
     6. PIETRE DE COLT alternante pe toate cele 4 colturi.
     7. NU intra: chiparosii, tufele, bolovanii (corectura de kit).
    SILUETA: corpul lung, culcat, cu acoperisul jos in doua ape si un horn mic
    (B e inalt cu fronton si horn mare; C are scara si terasa).
    Noduri: House_Stone, House_Roof, House_Wood, House_Shutter, House_Void."""
    roof, void, wood, trim, shutter = Builder(), Builder(), Builder(), Builder(), Builder()
    op = Openings(void, wood, trim, shutter)
    X0, X1, Y0, Y1, ZW, H = -4.5, 4.5, -3.5, 3.5, 5.5, 8.0
    body = Builder()
    R = gable_roof(roof, 0.0, 0.0, X1 - X0, (Y1 - Y0) * 0.5, ZW, H, "X")
    gable_body(body, X0, X1, Y0, Y1, ZW, R, "X")
    for x in (1.3, -2.1):
        op.add("body", "+Y", Y1, x, 0.85, 1.0, 2.2, shutters=True)
        op.add("body", "+Y", Y1, x, 0.85, 3.5, 4.7, shutters=True)
    op.add("body", "+X", X1, 0.0, 1.2, 0.12, 2.6, kind="door", shape="arch")
    op.add("body", "+X", X1, 0.0, 0.85, 3.5, 4.7, shutters=True)
    op.add("body", "+X", X1, 0.0, 0.45, 6.05, 6.55, cross=False)
    for x in (2.0, -2.0):
        op.add("body", "-Y", Y0, x, 0.85, 3.5, 4.7, shutters=True)
    op.add("body", "-Y", Y0, -2.0, 0.85, 1.0, 2.2)
    op.add("body", "-X", X0, 0.0, 0.85, 3.5, 4.7, shutters=True)
    steps(trim, X1, 0.0, 2.2, 0.8, 1, 0.12, face="+X")
    steps(trim, -3.4, Y1, 1.8, 1.1, 2, 0.14)
    chimney(trim, void, 3.1, -0.45, ZW - 0.4, R["ridge_z"] + 0.75, sx=0.7, sy=0.6)
    quoins(trim, X0, X1, Y0, Y1, 0.25, ZW)
    print("colonnata_house_a: panta %.1f, coama %.2f, goluri %d" % (R["pitch"], R["ridge_z"], len(op.log)))
    return _house_nodes(op, [("body", body)], trim, roof, wood, shutter, void)


def build_colonnata_house_b():
    """Casa B (`colonnata_house_b`), kit §1.4: 8 x 7 m, coama 8,5 m, ALTA SILUETA.

    LISTA DE ELEMENTE (decuparea `colonnata_house_b.png`, scrisa INAINTE de
    primul vertex). Decuparea e 3/4 din stanga-fata: frontonul in stanga, latura
    lunga in dreapta; kitul cere FRONTONUL spre +Y -> frontonul e +Y, latura
    lunga vazuta e -X; camera de comparatie pe azimutul 125.
     1. CORP mai INALT si mai adunat: 7 (X, frontonul) x 8 (Y), pereti 5,9 m,
        acoperis in DOUA APE cu coama pe Y (fronton spre +Y), capacul la 8,5 m.
     2. HORN MARE de piatra pe coama, la frontonul +Y, 1,1 x 0,9 m, cu ~1,3 m
        peste coama (decuparea: hornul gros din stanga) -> silueta „turn cu
        horn", diferita de A.
     3. FRONTONUL +Y: USA ARCUITA 1,2 x 2,6 m (bolțari, toc, prag) putin spre
        stanga, o fereastra la etaj, o fereastra mica de pod; fara obloane pe
        fronton (decuparea: ferestre goale cu rama).
     4. LATURA -X: 2 ferestre cu OBLOANE VERZI sus, jos o a DOUA USA ARCUITA si
        o fereastra mica (decuparea).
     5. LATURA +X si SPATELE: 2 + 2 ferestre cu obloane (din alte azimuturi).
     6. PIETRE DE COLT alternante pe toate colturile.
     7. NU intra: chiparosii, tufele (corectura de kit).
    Noduri: House_Stone, House_Roof, House_Wood, House_Shutter, House_Void."""
    roof, void, wood, trim, shutter = Builder(), Builder(), Builder(), Builder(), Builder()
    op = Openings(void, wood, trim, shutter)
    X0, X1, Y0, Y1, ZW, H = -3.5, 3.5, -4.0, 4.0, 5.9, 8.5
    body = Builder()
    R = gable_roof(roof, 0.0, 0.0, Y1 - Y0, (X1 - X0) * 0.5, ZW, H, "Y")
    gable_body(body, X0, X1, Y0, Y1, ZW, R, "Y")
    op.add("body", "+Y", Y1, 0.35, 1.2, 0.12, 2.7, kind="door", shape="arch")
    op.add("body", "+Y", Y1, 0.0, 0.85, 3.7, 4.9)
    op.add("body", "+Y", Y1, 0.0, 0.40, 6.45, 6.95, cross=False)
    for y in (1.8, -1.5):
        op.add("body", "-X", X0, y, 0.85, 3.7, 4.9, shutters=True)
    op.add("body", "-X", X0, 1.0, 1.2, 0.12, 2.6, kind="door", shape="arch")
    op.add("body", "-X", X0, -2.2, 0.6, 1.3, 2.1, cross=False)
    for y in (1.8, -1.5):
        op.add("body", "+X", X1, y, 0.85, 3.7, 4.9, shutters=True)
    op.add("body", "+X", X1, 0.0, 0.85, 1.1, 2.2, shutters=True)
    for x in (1.6, -1.6):
        op.add("body", "-Y", Y0, x, 0.85, 3.7, 4.9, shutters=True)
    steps(trim, 0.35, Y1, 2.0, 0.9, 2, 0.13)
    steps(trim, X0, 1.0, 1.9, 0.7, 1, 0.12, face="-X")
    z_r = R["ridge_z"]
    chimney(trim, void, 0.0, Y1 - 0.75, ZW - 0.6, z_r + 1.25, sx=1.1, sy=0.9)
    quoins(trim, X0, X1, Y0, Y1, 0.25, ZW)
    print("colonnata_house_b: panta %.1f, coama %.2f, goluri %d" % (R["pitch"], z_r, len(op.log)))
    return _house_nodes(op, [("body", body)], trim, roof, wood, shutter, void)


def build_colonnata_house_c():
    """Casa C (`colonnata_house_c`), kit §1.4: 10 x 7 m, coama 7,5 m, ALTA SILUETA.

    LISTA DE ELEMENTE (decuparea `colonnata_house_c.png`, scrisa INAINTE de
    primul vertex). Decuparea e 3/4 din dreapta-fata: frontonul in stanga, latura
    lunga cu scara in dreapta -> scara pe fata bogata +Y, frontonul vazut e +X;
    camera de comparatie pe azimutul 55. Pe latura +Y, capatul din DREAPTA
    decuparii e -X: scara urca spre -X, terasa si hornul sunt la -X.
     1. CORP lung si mai jos: 10 (X) x 7 (Y), pereti 5,2 m, acoperis in DOUA APE
        cu coama pe X, capacul la 7,5 m.
     2. SCARA EXTERIOARA DE PIATRA pe latura +Y: 10 trepte de 0,28 m, 1,1 m
        lata, lipita de perete, urca de la x = +2,0 spre -X pana la etaj
        (2,8 m) -> pana pe TERASA.
     3. TERASA mica la capatul -X al laturii +Y: 3,0 x 1,8 m, pe un soclu plin de
        piatra cu o gura de pivnita arcuita in fata, pardoseala de piatra iesita,
        BALUSTRADA de lemn (stalpi LOG_DARK, doua rigle) pe fata si pe capat;
        o USA de lemn la etaj, din terasa in casa.
     4. LATURA +Y, restul: 2 ferestre cu obloane verzi la etaj (decuparea: una cu
        obloane, una fara -> amandoua cu obloane, din departe obloanele sunt
        singura culoare de pe fatada); jos, sub scara, nimic.
     5. FRONTONUL +X: fereastra mica de pod, o fereastra cu obloane la etaj, o
        fereastra mai mare cu obloane jos (decuparea).
     6. SPATELE si frontonul -X: 2 + 1 ferestre si o usa in spate.
     7. HORN de piatra pe coama, la capatul -X (decuparea: hornul din dreapta).
     8. PIETRE DE COLT alternante pe toate colturile.
     9. NU intra: chiparosii, tufele (corectura de kit).
    SILUETA: casa joasa si lunga cu o PANA de scara si un cub de terasa lipite pe
    o latura (A e corp simplu culcat; B e inalta cu fronton si horn mare).
    Noduri: House_Stone, House_Roof, House_Wood, House_Shutter, House_Void."""
    roof, void, wood, trim, shutter = Builder(), Builder(), Builder(), Builder(), Builder()
    op = Openings(void, wood, trim, shutter)
    X0, X1, Y0, Y1, ZW, H = -5.0, 5.0, -3.5, 3.5, 5.2, 7.5
    FL = 2.8                                   # etajul / terasa
    body = Builder()
    R = gable_roof(roof, 0.0, 0.0, X1 - X0, (Y1 - Y0) * 0.5, ZW, H, "X")
    gable_body(body, X0, X1, Y0, Y1, ZW, R, "X")
    # --- 3. terasa: soclu plin, pardoseala, balustrada
    TX0, TX1, TY0, TY1 = -4.8, -1.8, Y1, Y1 + 1.8
    terr = Builder()
    terr.box(((TX0 + TX1) * 0.5, (TY0 + TY1) * 0.5 - 0.05, (FL - 0.2) * 0.5),
             (TX1 - TX0, TY1 - TY0 + 0.1, FL - 0.2), V_STONE)
    trim.box(((TX0 + TX1) * 0.5, (TY0 + TY1) * 0.5 + 0.02, FL - 0.1), (TX1 - TX0 + 0.12, TY1 - TY0 + 0.1, 0.2),
             V_STONE)
    op.add("terr", "+Y", TY1, (TX0 + TX1) * 0.5, 1.0, 0.0, 1.85, shape="arch", depth=0.5,
           sill=False)
    rh = 0.95
    for p0, p1 in (((TX0 + 0.06, TY1 - 0.04), (TX1 - 0.04, TY1 - 0.04)),
                   ((TX0 + 0.06, TY0 + 0.05), (TX0 + 0.06, TY1 - 0.04))):
        for zz, th in ((FL + rh - 0.04, 0.08), (FL + 0.45, 0.06)):
            wood.beam((p0[0], p0[1], zz), (p1[0], p1[1], zz), (th, th), V_WOOD, up=(0, 0, 1))
    for (x, y) in ((TX0 + 0.06, TY1 - 0.04), (TX0 + 1.06, TY1 - 0.04), (TX0 + 2.06, TY1 - 0.04),
                   (TX1 - 0.04, TY1 - 0.04), (TX0 + 0.06, TY0 + 0.9)):
        wood.box((x, y, FL + rh * 0.5), (0.11, 0.11, rh + 0.04), V_DARK)
    op.add("body", "+Y", Y1, -3.3, 1.0, FL, FL + 2.1, kind="door")
    # --- 2. scara: 10 trepte pline, urca de la x = +2,0 spre -X pana la terasa
    n = 10
    rise = FL / n
    run = (2.0 - TX1) / n
    for k in range(n):
        xa = 2.0 - run * (k + 1)
        xb = 2.0 - run * k
        trim.box(((xa + xb) * 0.5 - 0.02, Y1 + 0.55, rise * (k + 1) * 0.5),
                 (xb - xa + 0.04, 1.1, rise * (k + 1)), V_STONE)
    # --- 4-6. golurile
    for x in (-0.4, 2.6):
        op.add("body", "+Y", Y1, x, 0.85, 3.25, 4.35, shutters=True)
    op.add("body", "+X", X1, 0.0, 0.45, 5.6, 6.05, cross=False)
    op.add("body", "+X", X1, 0.0, 0.85, 3.25, 4.35, shutters=True)
    op.add("body", "+X", X1, 0.0, 1.0, 0.75, 2.15, shutters=True)
    for x in (2.6, -1.0):
        op.add("body", "-Y", Y0, x, 0.85, 3.25, 4.35, shutters=True)
    op.add("body", "-Y", Y0, -3.4, 0.95, 0.12, 2.25, kind="door")
    op.add("body", "-X", X0, 0.0, 0.85, 3.25, 4.35, shutters=True)
    steps(trim, -3.4, -Y1, 1.6, 0.6, 1, 0.12, face="-Y")
    chimney(trim, void, -3.8, 0.4, ZW - 0.4, R["ridge_z"] + 0.7, sx=0.7, sy=0.7)
    quoins(trim, X0, X1, Y0, Y1, 0.25, ZW)
    print("colonnata_house_c: panta %.1f, coama %.2f, goluri %d" % (R["pitch"], R["ridge_z"], len(op.log)))
    return _house_nodes(op, [("body", body), ("terr", terr)], trim, roof, wood, shutter, void)


# ---------------------------------------------------------------------------
# quarry_sign_block
# ---------------------------------------------------------------------------

def build_quarry_sign_block():
    """LISTA DE ELEMENTE (decuparea `quarry_sign_block.png`, scrisa INAINTE de
    primul vertex; cotele din kit §1.4):
     1. UN BLOC de marmura 3 (X) x 2 (Y) x 2 (Z) m, taiat drept, muchii vii
        (regula 7: fara tesire). Decuparea arata un rost orizontal la jumatate
        (doua blocuri suprapuse); kitul cere UN bloc cu o fata slefuita intr-un
        singur plan -> fara rost (abatere notata).
     2. FATA SLEFUITA pe +Y: un singur plan, dreptunghiul intreg 3 x 2 m, fara
        colturi sparte, fara vene modelate (venele le da clasa), FARA TEXT. Si
        patina nu urca pe ea: fasia de jos a fetei e in `Sign_Marble`, 2 cm
        groasa, coplanara cu restul fetei.
     3. CELELALTE FETE taiate cu fir, cu DOUA COLTURI SPARTE sus, in spate
        (fatete mari, plane: coltul -X la 0,40 m, coltul +X la 0,25 m).
     4. PATINA: treimea de jos a laturilor si a spatelui pe MARBLE_GREY
        (`Sign_MarbleBase`, regula 8), restul crem (`Sign_Marble`, CORAL_SAND).
    Noduri: Sign_Marble (19), Sign_MarbleBase (29)."""
    marble, base = Builder(), Builder()
    hx, hy, H = 1.5, 1.0, 2.0
    zb = H / 3.0
    face_t = 0.02
    # 4. patina: treimea de jos, oprita la 2 cm de fata slefuita
    _hull(base, [Vector((sx * hx, y, z)) for sx in (-1, 1) for y in (-hy, hy - face_t)
                 for z in (0.0, zb)], CRR_MARBLE_BASE)
    # 2. fasia de jos a fetei slefuite (coplanara cu restul fetei, y = +hy)
    _hull(marble, [Vector((sx * hx, y, z)) for sx in (-1, 1) for y in (hy - face_t, hy)
                   for z in (0.0, zb)], CRR_MARBLE)
    # 1 + 3. partea de sus, cu doua colturi sparte in spate
    chips = {(-1, -1): 0.40, (1, -1): 0.25}
    pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for z in (zb, H):
                c = chips.get((sx, sy), 0.0) if z == H else 0.0
                if c > 0.0:
                    x, y = sx * hx, sy * hy
                    pts += [Vector((x - sx * c, y, z)), Vector((x, y - sy * c, z)),
                            Vector((x, y, z - c))]
                else:
                    pts.append(Vector((sx * hx, sy * hy, z)))
    _hull(marble, pts, CRR_MARBLE)
    return [marble.to_object("Sign_Marble"), base.to_object("Sign_MarbleBase")]


# ---------------------------------------------------------------------------

def _want(name):
    return not ONLY or ONLY == name


clear_built()
if _want("colonnata_church"):
    emit_keep(build_colonnata_church(), "buildings/colonnata_church.glb", ao_for(CH_TOTAL))
    clear_built()
if _want("colonnata_house_a"):
    emit_keep(build_colonnata_house_a(), "buildings/colonnata_house_a.glb", ao_for(8.8))
    clear_built()
if _want("colonnata_house_b"):
    emit_keep(build_colonnata_house_b(), "buildings/colonnata_house_b.glb", ao_for(9.8))
    clear_built()
if _want("colonnata_house_c"):
    emit_keep(build_colonnata_house_c(), "buildings/colonnata_house_c.glb", ao_for(8.2))
    clear_built()
if _want("quarry_sign_block"):
    emit_keep(build_quarry_sign_block(), "props/quarry_sign_block.glb",
              dict(samples=16, dist=1.2, gradient="vertical", low=0.70, high=1.0,
                   power=0.8, floor=0.45, z_range=(0.0, 2.0)))
    clear_built()
report_crr()
