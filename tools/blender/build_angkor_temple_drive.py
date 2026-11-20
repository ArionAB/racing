"""Angkor Wat PRIN CARE SE TRECE (Track24, B, 19 nov 2026).

  angkor/structures/angkor_wat_drive.glb   templul intreg, vizual (fara coliziune)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_temple_drive.py
Garda:   ... run_build.py -- measure_angkor_drive.py [-- --sabotaj=<nume>]
Randari: ... run_build.py -- preview_angkor_drive.py

De ce: verdictul dezvoltatorului ("for a map that the main attraction is the temple we
are not even going through the temple"). Soseaua intra pe axa de vest, merge pe o nava,
coteste la stanga printr-o sala curba lipita de piciorul turnului central si iese pe nava
de nord. TOATA coliziunea (peretii pe marginea soselei, tavanul, ramele portalurilor,
aripile) vine dintr-un tub construit in Godot (`TunelTemplu`, ascuns); modelul de aici il
IMBRACA. Sursa de adevar: `tools/data/angkor_temple_shell.json`, exportat din joc.

CADRUL: cadrul HARTII (X Blender = est, Y = nord, Z sus, metri), originea pe axa turnului
central la z = 0. GLB-ul sta in Godot in origine cu transformarea identitate, deci toate
pozitiile sunt absolute. Gazonul e la ~3,65, soseaua din templu la 4,0; sub 3,6 e ingropat.

TUBUL (clasa `Tube`): sectiunile se refac EXACT ca `track.gd::_build_tunnel` (capac la
0,3 m in afara primului / ultimului punct copt, apoi o sectiune la mijlocul fiecarui segment
copt; latimea max(6, hw), tavanul 10 + 5 * clamp((w - 6) / 2)). Peretele de coliziune intre
doua sectiuni e interpolarea liniara a punctelor c + s * w, deci orice „lespede de tub"
(`sweep`) cu varfuri pe TOATE sectiunile dintre capetele ei sta paralel cu el. Coordonate de
tub: m = metri pe drum (ca in JSON: 0 la primul punct copt, capacul de vest la -0,3, cel de
nord la +93,6), side = +1 dreapta sensului / -1 stanga, e = cat sta IN SPATELE planului de
coliziune (e < 0 = in culoar), h = inaltimea peste asfalt.

CE E UNDE (dimensiunile care difera de brief, cu motivul):
  * planurile fatadelor de portal: x = -51,66 (V) si y = +54,5 (N), nu +-52: acolo sunt
    capacele tubului in JSON (pavilioanele de intrare ies din galeria exterioara pana la ele);
    pavilioanele false (E, S) sunt oglinda lor, deci templul e simetric fata de origine;
  * golul portalurilor = rama de coliziune: 12,0 x 10,0 m (rama din `_tun_frame` foloseste
    `tunnel_half_width` = 6, nu latimea soselei de 12,9 m) -- vezi raportul garzii, linia NOTA;
  * cele patru „bolti" ale navelor (grupurile `GROUPS`): tavanul de coliziune urca de la 11,1 m
    la portal la 15 m in sala, deci nasterea boltii urca in trepte (12,5 / 14,3 / 15,1 / 13,6 /
    12,1 m peste asfalt), iar acoperisurile o urmeaza: galeria urca spre sanctuar;
  * turnul central: varful la +36 ca inainte, dar etajele rotunde pornesc de la +22,3: sala
    (tavan 15 m = z 19, bolta pana la 21,7) trece la 3,7 m de axa lui, deci piciorul turnului
    sta pe acoperisul salii pe partea de NV (solutia din brief: turn purtat de acoperis);
  * peretele EXTERIOR al salii e o arcada (golfurile 6..12, m 28 .. 61; golul 9 pe axa gongului):
    balustrada pe planul de coliziune pana la ~1,7 m, apoi gol liber de 3,1 m pe cel putin 8,8 m.
    In spatele ei: ambulatoriul (e 2,0 .. 6,8, podea +3,9, tavan +14,8) cu al doilea sir de
    stalpi si nise inalte cu candele in zidul din spate, deschis in mijloc spre camera de sub
    turnul central (19 x 19 pana la +15, boltita in consola pana la +19,8);
  * coloana razei din joc (r 2,0 la z 22 .. r 4,4 la z 4, pe axa turnului) e libera: trunchi de con
    scobit de la +13,5 la +22 (si din zidurile/boltile salii de langa el), apoi putul cilindric
    r 2,4 (4,8 m) pana la +30. Discul de pardoseala r 4,6 si soclul-lotus sunt palide (AO 0,97).
    Gongul (RUST_METAL, singurul bronz, cu cupele candelelor) pe soclu, in origine;
  * ferestrele reale (zid subtire 0,25 .. 0,9, panou retras pe exterior) doar unde intra soarele
    jos de VSV: peretele de SUD al navei de vest si cel de VEST al navei de nord; in rest oarbe;
  * trei nise adanci (pana la e = 3,0, scobite in terasa) pe peretele interior al salii;
  * fetele ingropate in alte solide se scot la sfarsit (`cull_hidden`), deci nodul _Stone nu mai
    e format din solide inchise (normalele raman cele calculate inainte).

CONTRACT: sloturile kitului (gresie 3, lichen 30 / 12, dare 20) + RUST_METAL 10 pentru bronz;
AO in culori de varf; noduri TempleDrive_Stone / _Lichen / _Streak / _Bronze; fara coliziune.
Interiorul se intuneca spre bolta prin AO-ul copt (`_interior_shade`, peste AO-ul de raze).
"""

import bisect
import json
import math
import os
import bmesh
import bpy
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
_old_only = os.environ.get("ANK_ONLY")
os.environ["ANK_ONLY"] = "none"          # doar ajutoarele, fara sa refaca piesele
exec(open(os.path.join(_here, "build_angkor_gates_w.py"), encoding="utf-8").read())
_NG = dict(globals())                    # kitul naga, in spatiul lui de nume (are `S`, `tube`)
exec(compile(open(os.path.join(_here, "build_angkor_naga.py"), encoding="utf-8").read(),
             "build_angkor_naga.py", "exec"), _NG)
if _old_only is None:
    os.environ.pop("ANK_ONLY", None)
else:
    os.environ["ANK_ONLY"] = _old_only
ANK_RESULTS.clear()

FAST = os.environ.get("DRIVE_FAST", "") == "1"   # iteratie: AO cu 4 raze

ST = ANK_STONE
BRONZE = LARCH_RUST            # 27: bronzul (buza, butonul si inelul gongului, cupele candelelor)
GOLD = CAR_YELLOW              # 16: fata gongului, acelasi auriu ca gongurile-hazard din sala
EMBER = LAVA_ORANGE            # 30: jarul din cupele candelelor (accentul atlasului pentru ce arde)
ROAD_Z = 4.0
FACE = 0.03                    # fata vizibila a peretelui, in spatele planului de coliziune
WALL_T = 2.2                   # grosimea peretilor de tub (spatele lor, e = 2,2)
E_K = 1.5                      # taietorul: ce e in afara tubului se taie pana la e = 1,5
VR, VT = 1.2, 1.5              # bolta: cofrajul de la nastere + 1,2 pana la + 1,5
KTOP = 20.7                    # ... si pana la z = 20,7 (peste toate boltile: 4 + 15,05 + 1,5)
TOP_C, TOP_K = 36.0, 30.0
CORNER = 26.0
Z_L1, Z_T2, Z_CEN = 3.0, 8.0, 14.0
HALF = 52.0
SHAFT_C = (0.0, 0.0)
SHAFT_R = 2.4
SHAFT_TOP = 30.0
CHAMBER = 9.5
DEEP_E = 3.0                   # fundul nischelor adanci (in spatele peretelui interior al salii)
BLK = 11.5                     # blocul sanctuarului (baza patrata a turnului central)

AO_DRIVE = dict(samples=4 if FAST else 16, dist=2.0, gradient="vertical", low=0.60, high=1.0,
                power=0.85, floor=0.30, strength=1.3, z_range=(0.0, TOP_C))


# =============================================================================
# tubul din JSON
# =============================================================================

SHELL = json.load(open(os.path.join(PROJECT, "tools", "data", "angkor_temple_shell.json")))


class Tube:
    """Sectiuni (c, s, w, m, ceil) + interpolare liniara intre ele (ca fasiile tubului)."""

    def __init__(self, c, s, w, m, ceil):
        self.c, self.s, self.w, self.m, self.ceil = c, s, w, m, ceil
        self.n = len(c)

    def seg(self, m):
        ms = self.m
        k = bisect.bisect_right(ms, m) - 1
        k = min(max(k, 0), self.n - 2)
        return k, (m - ms[k]) / (ms[k + 1] - ms[k])

    def P(self, m, side, e, h, f=1.0):
        """Punctul de la `e` in spatele peretelui `side`, la `h` peste asfalt. `f` scaleaza
        lateralul (f = 0: axa) -- pentru acoperisuri care urca spre coama."""
        k, t = self.seg(m)
        a = self.c[k] + self.s[k] * (side * f * (self.w[k] + e))
        b = self.c[k + 1] + self.s[k + 1] * (side * f * (self.w[k + 1] + e))
        p = a + (b - a) * t
        return Vector((p.x, p.y, p.z + h))

    def lerp(self, arr, m):
        k, t = self.seg(m)
        return arr[k] + (arr[k + 1] - arr[k]) * t

    def W(self, m):
        return self.lerp(self.w, m)

    def C(self, m):
        return self.lerp(self.ceil, m)

    def Cmax(self, m0, m1):
        v = [self.C(m0), self.C(m1)] + [c for mm, c in zip(self.m, self.ceil) if m0 < mm < m1]
        return max(v)

    def samples(self, m0, m1):
        return [m0] + [mm for mm in self.m if m0 + 1e-4 < mm < m1 - 1e-4] + [m1]

    def tangent(self, m):
        a, b = self.P(m - 0.25, 0, 0, 0, 0.0), self.P(m + 0.25, 0, 0, 0, 0.0)
        d = b - a
        d.z = 0.0
        return d.normalized()

    def normal(self, m, side):
        """Normala spre EXTERIORUL peretelui `side` (dinspre culoar spre zid)."""
        k, t = self.seg(m)
        s = self.s[k].lerp(self.s[k + 1], t)
        s.z = 0.0
        return (s * side).normalized()

    def locate(self, x, y):
        """(m, L, e) ale punctului din plan: m pe axa, L lateral cu semn (+ dreapta),
        e = |L| - w. Dincolo de capace intoarce e = +inf."""
        best = None
        for k in range(self.n - 1):
            ax, ay = self.c[k].x, self.c[k].y
            bx_, by_ = self.c[k + 1].x, self.c[k + 1].y
            dx, dy = bx_ - ax, by_ - ay
            ll = dx * dx + dy * dy
            traw = ((x - ax) * dx + (y - ay) * dy) / ll
            t = min(max(traw, 0.0), 1.0)
            qx, qy = ax + dx * t, ay + dy * t
            d2 = (x - qx) ** 2 + (y - qy) ** 2
            if best is None or d2 < best[0]:
                best = (d2, k, t, traw, qx, qy)
        _, k, t, traw, qx, qy = best
        if (k == 0 and traw < 0.0) or (k == self.n - 2 and traw > 1.0):
            return None
        m = self.m[k] + (self.m[k + 1] - self.m[k]) * t
        s = self.s[k].lerp(self.s[k + 1], t)
        L = (x - qx) * s.x + (y - qy) * s.y
        w = self.w[k] + (self.w[k + 1] - self.w[k]) * t
        return m, L, abs(L) - w


def build_tube():
    road = SHELL["road"]
    tube = SHELL["tube"]
    i0 = [k for k, r in enumerate(road) if abs(r["m"]) < 1e-6][0]
    acc, j = 0.0, i0
    while acc < tube["length"]:
        acc += (Vector(road[j + 1]["p"]) - Vector(road[j]["p"])).length
        j += 1
    iw = j
    hw0 = tube["half_width"]
    P_ = [Vector(r["p"]) for r in road]
    S_ = [Vector((r["side"][0], r["side"][1], 0.0)) for r in road]
    te = (P_[i0 + 1] - P_[i0]).normalized()
    tw = (P_[iw] - P_[iw - 1]).normalized()
    c, s, w, m = [P_[i0] - te * 0.3], [S_[i0]], [road[i0]["hw"]], [road[i0]["m"] - 0.3]
    for k in range(i0, iw):
        c.append((P_[k] + P_[k + 1]) * 0.5)
        s.append(S_[k])
        w.append((road[k]["hw"] + road[k + 1]["hw"]) * 0.5)
        m.append((road[k]["m"] + road[k + 1]["m"]) * 0.5)
    c.append(P_[iw] + tw * 0.3)
    s.append(S_[iw - 1])
    w.append(road[iw]["hw"])
    m.append(road[iw]["m"] + 0.3)
    w = [max(hw0, x) for x in w]
    hmax = max(w)
    ceil = [tube["ceiling"] + (tube["hall_ceiling"] - tube["ceiling"]) *
            min(max((x - hw0) / (hmax - hw0), 0.0), 1.0) for x in w]
    return Tube(c, s, w, m, ceil)


T = build_tube()
M_W, M_N = T.m[0], T.m[-1]                 # capacele: -0,3 si 93,6
NB = 20                        # 20 golfuri de 4,7 m: un golf al arcadei cade in dreptul gongului
PITCH = (M_N - M_W) / NB
PIER = [M_W + PITCH * j for j in range(NB + 1)]
# grupurile de bolta (bay-uri [j0, j1)): nasterea = tavanul maxim al grupului + 5 cm
GROUPS = [(0, 2), (2, 4), (4, 16), (16, 18), (18, 20)]
G_CB = []
for (j0, j1) in GROUPS:
    G_CB.append(T.Cmax(PIER[j0], PIER[j1]) + 0.05)
R_ROOF = [2.6, 2.6, 1.6, 2.6, 2.6]


def group_of(j):
    for g, (j0, j1) in enumerate(GROUPS):
        if j0 <= j < j1:
            return g
    return len(GROUPS) - 1


def cb_at(m):
    for g, (j0, j1) in enumerate(GROUPS):
        if PIER[j0] - 1e-6 <= m <= PIER[j1] + 1e-6:
            return G_CB[g]
    return G_CB[-1]


def in_K(x, y, z):
    """Volumul pastrat liber pentru tub (culoar + pereti pana la e = E_K, pana la KTOP)."""
    if z < ROAD_Z - 0.55 or z > KTOP:
        return False
    r = T.locate(x, y)
    return r is not None and r[2] < E_K


def side_sign_frame(m, side):
    """Unghiul de yaw al normalei exterioare (pentru `streak`)."""
    n = T.normal(m, side)
    return math.degrees(math.atan2(-n.x, n.y))


# =============================================================================
# ajutoare de geometrie
# =============================================================================

def sweep(B, tube, m0, m1, prof, slot=ST):
    """Prisma inchisa: profilul (side, e, h[, f]) purtat pe toate sectiunile dintre m0 si m1."""
    if m1 - m0 < 1e-3:
        return
    ms = tube.samples(m0, m1)
    rings = []
    for m in ms:
        ring = []
        for q in prof:
            side, e, h = q[0], q[1], q[2]
            f = q[3] if len(q) > 3 else 1.0
            ring.append(B.bm.verts.new(tube.P(m, side, e, h, f)))
        rings.append(ring)
    n = len(prof)
    for r0, r1 in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            B.bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
    B.bm.faces.new(rings[0])
    B.bm.faces.new(list(reversed(rings[-1])))
    B._tag([v for r in rings for v in r], slot)


def slab(B, side, m0, m1, e0, e1, h0, h1, slot=ST, tube=None):
    sweep(B, tube or T, m0, m1, [(side, e0, h0), (side, e1, h0), (side, e1, h1), (side, e0, h1)], slot)


def span(B, m0, m1, eL, eR, h0, h1, slot=ST, tube=None):
    """Lespede de la peretele stang (e = eL) la cel drept (e = eR)."""
    sweep(B, tube or T, m0, m1, [(-1, eL, h0), (1, eR, h0), (1, eR, h1), (-1, eL, h1)], slot)


def thull(B, pts, slot=ST):
    hull(B, pts, slot)


def local(tube, m, side):
    """Punct local pe perete: (u de-a lungul lui, e in spate, h sus)."""
    return lambda u, e, h: tube.P(m + u, side, e, h)


def copy_bm(src_bm, src_slot, dst, keep=None, slot=None, xform=None):
    """Copiaza fetele din `src_bm` in builder-ul `dst`, pe insule (componente conexe);
    `keep(list_of_Vector)` poate respinge o insula intreaga."""
    src_bm.verts.ensure_lookup_table()
    seen = set()
    for f0 in src_bm.faces:
        if f0.index in seen:
            continue
        # insula
        stack, faces = [f0], []
        seen.add(f0.index)
        while stack:
            f = stack.pop()
            faces.append(f)
            for e in f.edges:
                for g in e.link_faces:
                    if g.index not in seen:
                        seen.add(g.index)
                        stack.append(g)
        verts = {v for f in faces for v in f.verts}
        cos = [(xform @ v.co) if xform else v.co.copy() for v in verts]
        if keep is not None:
            pts = list(cos)
            for f in faces:
                for e in f.edges:
                    a = (xform @ e.verts[0].co) if xform else e.verts[0].co
                    b = (xform @ e.verts[1].co) if xform else e.verts[1].co
                    nseg = int((b - a).length / 0.45)
                    for i in range(1, nseg + 1):
                        pts.append(a.lerp(b, i / (nseg + 1)))
            if not keep(pts):
                continue
        vmap = {}
        for v, co in zip(verts, cos):
            vmap[v] = dst.bm.verts.new(co)
        for f in faces:
            try:
                nf = dst.bm.faces.new([vmap[v] for v in f.verts])
            except ValueError:
                continue
            nf[dst.slot] = slot if slot is not None else (f[src_slot] if src_slot is not None else ST)


def outside_K(pts):
    return not any(in_K(p.x, p.y, p.z) for p in pts)


def filtered(dst, fn):
    """Construieste `fn(builder)` separat si pastreaza doar insulele care nu intra in K."""
    tmp = Builder()
    fn(tmp)
    tmp.bm.faces.index_update()
    copy_bm(tmp.bm, tmp.slot, dst, keep=outside_K)
    tmp.bm.free()


# --- taietorii (boolean) ------------------------------------------------------
# CUT_COLL   tot: banda tubului, camera sanctuarului cu bolta, ambulatoriul, coloana razei
# CHAMB_COLL camera + bolta ei + coloana razei (pentru ambulatoriu: acoperisul si zidul din spate)
# BEAM_COLL  doar coloana razei (pentru zidurile salii de langa turn)

CUT_COLL = CHAMB_COLL = BEAM_COLL = None
AMB_E = (2.0, 6.8)            # adancimea ambulatoriului in spatele peretelui exterior al salii


def make_cutters():
    global CUT_COLL, CHAMB_COLL, BEAM_COLL
    CUT_COLL = bpy.data.collections.new("_DriveCutters")
    CHAMB_COLL = bpy.data.collections.new("_DriveChamber")
    BEAM_COLL = bpy.data.collections.new("_DriveBeam")
    for c in (CUT_COLL, CHAMB_COLL, BEAM_COLL):
        bpy.context.scene.collection.children.link(c)

    def add(builder, name, colls):
        bmesh.ops.recalc_face_normals(builder.bm, faces=builder.bm.faces[:])
        me = bpy.data.meshes.new(name)
        builder.bm.to_mesh(me)
        builder.bm.free()
        ob = bpy.data.objects.new(name, me)
        for c in colls:
            c.objects.link(ob)
        ob.hide_render = True

    ALL, CH, BM = (CUT_COLL,), (CUT_COLL, CHAMB_COLL), (CUT_COLL, CHAMB_COLL, BEAM_COLL)
    # banda tubului: de la 1 cm in fata capacului de vest la 1 cm dupa cel de nord
    b = Builder()
    ext = Tube([T.c[0] - (T.c[1] - T.c[0]).normalized() * 0.01] + T.c[1:-1] +
               [T.c[-1] + (T.c[-1] - T.c[-2]).normalized() * 0.01],
               T.s, T.w, T.m, T.ceil)
    sweep(b, ext, M_W, M_N, [(-1, E_K, -0.55), (1, E_K, -0.55),
                             (1, E_K, KTOP - ROAD_Z), (-1, E_K, KTOP - ROAD_Z)])
    add(b, "_cut_band", ALL)
    # ambulatoriul din spatele arcadei (podea la +3,9, tavan la +14,8)
    b = Builder()
    slab(b, 1, AMB_M[0], AMB_M[1], AMB_E[0], AMB_E[1], -0.1, 10.8)
    add(b, "_cut_amb", ALL)
    # nisele adanci de pe peretele interior al salii (scot terasa din spatele lor)
    for j in DEEP:
        b = Builder()
        a, b_ = PIER[j] + 0.6 + 0.42, PIER[j + 1] - 0.6 - 0.42
        slab(b, -1, a, b_, 1.3, DEEP_E + 0.01, -0.1, 4.6)
        add(b, "_cut_deep%d" % j, ALL)
    # sanctuarul: camera, bolta in consola (fiecare cutie un obiect: taietori manifold)
    b = Builder()
    bx(b, -CHAMBER, CHAMBER, -CHAMBER, CHAMBER, 3.9, 15.0)
    add(b, "_cut_chamber", CH)
    hh, z = CHAMBER, 15.0
    for i in range(6):
        hh -= 0.9
        b = Builder()
        bx(b, -hh, hh, -hh, hh, z - 0.01, z + 0.8)
        add(b, "_cut_corbel%d" % i, CH)
        z += 0.8
    # coloana razei (jocul pune o raza aditiva pe axa turnului: r 2,0 la z 22 .. r 4,4 la z 4):
    # trunchi de con de la +13,5 la +22, apoi putul cilindric r 2,4 pana la +30
    b = Builder()
    b.frustum((0.0, 0.0, (13.5 + 22.1) * 0.5), 3.25, 2.15, 22.1 - 13.5, ST, segments=16)
    add(b, "_cut_beam", BM)
    b = Builder()
    b.frustum((0.0, 0.0, (21.9 + SHAFT_TOP) * 0.5), SHAFT_R, SHAFT_R, SHAFT_TOP - 21.9, ST, segments=16)
    add(b, "_cut_shaft", BM)


def cutter_boxes(coll):
    out = []
    for ob in coll.objects:
        xs = [v.co.x for v in ob.data.vertices]
        ys = [v.co.y for v in ob.data.vertices]
        zs = [v.co.z for v in ob.data.vertices]
        out.append((min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
    return out


def islands(bm):
    bm.faces.index_update()
    seen, out = set(), []
    for f0 in bm.faces:
        if f0.index in seen:
            continue
        stack, faces = [f0], []
        seen.add(f0.index)
        while stack:
            f = stack.pop()
            faces.append(f)
            for e in f.edges:
                for g in e.link_faces:
                    if g.index not in seen:
                        seen.add(g.index)
                        stack.append(g)
        out.append(faces)
    return out


def _boolean_copy(src_builder, dst, coll, slot):
    """Obiect temporar din builder, DIFFERENCE cu colectia, rezultatul copiat in dst."""
    ob = src_builder.to_object("_carve_tmp")
    mod = ob.modifiers.new("cut", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.operand_type = "COLLECTION"
    mod.collection = coll
    mod.solver = "EXACT"
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    me = ev.to_mesh()
    bm = bmesh.new()
    bm.from_mesh(me)
    ev.to_mesh_clear()
    bm.faces.index_update()
    copy_bm(bm, None, dst, slot=slot)
    bm.free()
    old = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    bpy.data.meshes.remove(old)


def _bb_hit(co, boxes):
    bb = (min(c.x for c in co), max(c.x for c in co), min(c.y for c in co), max(c.y for c in co),
          min(c.z for c in co), max(c.z for c in co))
    return any(not (bb[1] < cb[0] or bb[0] > cb[1] or bb[3] < cb[2] or bb[2] > cb[3] or
                    bb[5] < cb[4] or bb[4] > cb[5]) for cb in boxes)


def carved(dst, fn, slot=ST, coll=None):
    """Construieste `fn(builder)` (solide inchise), scade taietorii, copiaza in `dst`."""
    coll = coll or CUT_COLL
    tmp = Builder()
    fn(tmp)
    co = [v.co for v in tmp.bm.verts]
    if not co:
        tmp.bm.free()
        return
    if not _bb_hit(co, cutter_boxes(coll)):
        tmp.bm.faces.index_update()
        copy_bm(tmp.bm, tmp.slot, dst, slot=slot)
        tmp.bm.free()
        return
    _boolean_copy(tmp, dst, coll, slot)


def carve_islands(dst, src, coll):
    """Fiecare insula (solid inchis) din builder-ul `src`: daca atinge taietorii colectiei,
    trece singura prin boolean; altfel se copiaza ca atare (cu slotul ei)."""
    boxes = cutter_boxes(coll)
    for faces in islands(src.bm):
        verts = list({v for f in faces for v in f.verts})
        if not _bb_hit([v.co for v in verts], boxes):
            vmap = {v: dst.bm.verts.new(v.co) for v in verts}
            for f in faces:
                try:
                    nf = dst.bm.faces.new([vmap[v] for v in f.verts])
                except ValueError:
                    continue
                nf[dst.slot] = f[src.slot]
            continue
        one = Builder()
        vmap = {v: one.bm.verts.new(v.co) for v in verts}
        slot = faces[0][src.slot]
        for f in faces:
            try:
                one.bm.faces.new([vmap[v] for v in f.verts])
            except ValueError:
                pass
        _boolean_copy(one, dst, coll, slot)
    src.bm.free()


def cull_hidden(b):
    """Scoate fetele ingropate in alte solide (raza din fata, de-a lungul normalei, loveste
    intai DOSUL unei fete = punctul e inauntrul unui solid). Fata se scoate doar daca TOATE
    probele ei (centrul, colturile si mijloacele laturilor, trase spre centru) sunt ingropate."""
    from mathutils.bvhtree import BVHTree as _BVH
    bm = b.bm
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.normal_update()
    bvh = _BVH.FromBMesh(bm)
    kill = []
    for f in bm.faces:
        n = f.normal
        if n.length < 0.5 or f.calc_area() < 1e-6:
            continue
        c = f.calc_center_median()
        pts = [c] + [v.co.lerp(c, 0.06) for v in f.verts] + \
              [((e.verts[0].co + e.verts[1].co) * 0.5).lerp(c, 0.06) for e in f.edges]
        buried = True
        for p in pts:
            hit = bvh.ray_cast(p + n * 0.015, n, 400.0)
            if hit[0] is None or hit[1].dot(n) <= 0.0:
                buried = False
                break
        if buried:
            kill.append(f)
    n0 = len(bm.faces)
    bmesh.ops.delete(bm, geom=kill, context="FACES")
    print("  fete ingropate scoase: %d din %d" % (len(kill), n0))


def to_object_keep(b, name):
    """Ca `Builder.to_object`, dar FARA recalcularea normalelor (dupa `cull_hidden` solidele
    nu mai sunt inchise, iar orientarea e deja cea buna)."""
    me = bpy.data.meshes.new(name)
    b.bm.to_mesh(me)
    b.bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return obj


# =============================================================================
# piese mici
# =============================================================================

def baluster(B, base, h, r=0.12, slot=ST, seg=6):
    """Baluster strunjit (khmer): inele si burti suprapuse pe verticala."""
    x, y, z = base
    prof = [(1.25, 0.0), (1.25, 0.08), (0.80, 0.22), (1.32, 0.50), (0.80, 0.78), (1.25, 0.92),
            (1.25, 1.0)]
    B.revolve([(r * a, h * t) for (a, t) in prof] + [(0.0, h)], slot, segments=seg, origin=(x, y, z))


def lamp(B, G, p, scale=1.0):
    """Candela de piatra: soclu in trepte, fus, cupa de bronz."""
    x, y, z = p
    s = scale
    oct_prism(B, x, y, z, z + 0.16 * s, 0.30 * s, 0.09 * s)
    oct_prism(B, x, y, z + 0.16 * s, z + 0.28 * s, 0.22 * s, 0.065 * s)
    B.frustum((x, y, z + 0.28 * s + 0.45 * s), 0.10 * s, 0.07 * s, 0.9 * s, ST, segments=8)
    B.frustum((x, y, z + 1.18 * s + 0.05 * s), 0.12 * s, 0.20 * s, 0.10 * s, ST, segments=8)
    G.frustum((x, y, z + 1.28 * s + 0.07 * s), 0.12 * s, 0.28 * s, 0.14 * s, BRONZE, segments=10)
    G.frustum((x, y, z + 1.42 * s + 0.05 * s), 0.11 * s, 0.0, 0.10 * s, EMBER, segments=3)   # jar: 4 tri


def apsara(B, L, u0, e_back, h0, scale=1.0, pose=0, depth=0.14):
    """Dansatoare in relief (apsara), FARA fata (doar silueta): fusta evazata, bust, brate
    ridicate, cap, tiara cu trei varfuri. `L(u, e, h)` = punct local; relieful iese de la
    e_back spre culoar cu `depth` (dar ramane in spatele planului peretelui)."""
    s = scale
    ef, eb = e_back - depth, e_back + 0.01

    def part(pts2d, d=1.0):
        pts = []
        for (u, h) in pts2d:
            pts.append(L(u0 + u * s, eb, h0 + h * s))
            pts.append(L(u0 + u * s * 0.92, e_back - depth * d, h0 + h * s))
        thull(B, pts)
    lean = 0.06 if pose == 0 else -0.06
    part([(-0.36, 0.0), (0.36, 0.0), (-0.20, 0.95), (0.20, 0.95)], 0.7)                 # fusta
    part([(-0.10, 0.0), (0.10, 0.0), (-0.07, 0.05), (0.07, 0.05)], 0.5)
    part([(-0.17 + lean, 0.92), (0.17 + lean, 0.92), (-0.11 + lean, 1.25), (0.11 + lean, 1.25),
          (-0.19 + lean, 1.55), (0.19 + lean, 1.55)], 1.0)                                 # bust
    part([(-0.09 + lean, 1.55), (0.09 + lean, 1.55), (-0.10 + lean, 1.78), (0.10 + lean, 1.78),
          (lean, 1.82)], 1.0)                                                             # cap
    for k, du in enumerate((-0.09, 0.0, 0.09)):                                          # tiara
        part([(lean + du - 0.035, 1.80), (lean + du + 0.035, 1.80), (lean + du, 2.02 + (0.06 if k == 1 else 0.0))], 0.8)
    for sg in (-1, 1):                                                                   # brate
        part([(sg * 0.15 + lean, 1.50), (sg * 0.20 + lean, 1.44), (sg * 0.42 + lean, 1.62),
              (sg * 0.44 + lean, 1.70)], 0.6)
        part([(sg * 0.42 + lean, 1.62), (sg * 0.44 + lean, 1.70), (sg * 0.30 + lean, 1.98),
              (sg * 0.26 + lean, 1.95)], 0.6)
    knee = 0.30 if pose == 0 else -0.30                                                  # picior indoit
    part([(knee * 0.3, 0.35), (knee, 0.45), (knee * 1.1, 0.55), (knee * 0.5, 0.60)], 0.5)


def naga_body(B, path, r=0.24, slot=ST):
    _NG["tube"](B, path, r, slot, groove=0.12, period=0.5)


# =============================================================================
# interiorul: pereti, bolta, acoperis (pe tub)
# =============================================================================

# Arcada peretelui exterior al salii: golfurile 6..12 (m 28 .. 61), golul 9 centrat pe axa
# gongului (punctul peretelui cel mai apropiat de origine e la m ~ 43,6-44,3).
ARCADE = set(range(6, 13))
AMB_M = (PIER[6] + 0.8, PIER[13] - 0.8)
# Nise adanci (cu candele mari) pe peretele interior al salii, care sta in umbra.
DEEP = (7, 9, 11)
# Ferestrele reale: doar pe peretii in care intra soarele jos de VSV -- peretele de SUD al navei
# de vest (golfurile 2..5; 0..1 sunt in pavilion) si peretele de VEST al navei de nord (14..17;
# 18..19 sunt in pavilion). Sunt subtiri (0,25 .. 0,9 m), ca raza oblica sa treaca prin ele.
WIN_S = set(range(2, 6))
WIN_N = set(range(14, 18))
WIN_T = 0.9
# Gongurile atarnate de coordonator in sala (m, lateral): fara rozete de bolta deasupra lor.
HUNG = ((28.0, 0.0), (66.0, 4.6), (74.0, -3.6), (74.0, 3.6), (87.0, 2.2))


def bay_kind(j, side):
    """(jos, sus): jos in relief/nisa/nisa adanca/arcada, sus in fereastra/oarba/plin."""
    if side == 1 and j in ARCADE:
        return "arcade", "plain"
    if side == -1 and j in DEEP:
        lower = "deep"
    else:
        lower = "relief" if (j + (0 if side > 0 else 1)) % 2 == 0 else "niche"
    if (side == 1 and j in WIN_S) or (side == -1 and j in WIN_N):
        upper = "window"
    elif side == -1 and group_of(j) == 2 and j % 2 == 0:
        upper = "window"             # sala, spre curtea de NV: lumina de cer
    else:
        upper = "blind" if j % 2 == 1 else "plain"
    return lower, upper


def window_heights(cb):
    if cb > 14.6:
        return 8.6, 12.6
    return 6.3, cb - 1.4


def build_interior(S_, G_, Br):
    lamps = []
    for side in (-1, 1):
        # soclul continuu (talpa pana la -0,5, mulura sus): pe planul peretelui
        slab(S_, side, M_W, M_N, 0.10, WALL_T, -0.5, 0.62)
        slab(S_, side, M_W, M_N, FACE, WALL_T, 0.62, 0.80)
        # stalpii
        for j in range(NB + 1):
            m = PIER[j]
            arc = side == 1 and ((j in ARCADE) or (j - 1 in ARCADE))
            pw = 0.8 if arc else 0.6
            ga, gb = group_of(max(j - 1, 0)), group_of(min(j, NB - 1))
            top = max(G_CB[ga], G_CB[gb])
            a, b = max(m - pw, M_W), min(m + pw, M_N)
            slab(S_, side, a, b, 0.07, WALL_T, 0.8, top)
            slab(S_, side, max(m - pw - 0.15, M_W), min(m + pw + 0.15, M_N), FACE, WALL_T, 0.8, 1.35)
            slab(S_, side, a, b, FACE, WALL_T, 4.95, 5.6)                   # inel la friza
            for (dw, h0, h1) in ((0.12, top - 1.15, top - 0.75), (0.26, top - 0.75, top - 0.38),
                                 (0.40, top - 0.38, top)):                    # capitel in trepte
                slab(S_, side, max(m - pw - dw, M_W), min(m + pw + dw, M_N), FACE, WALL_T, h0, h1)
        # golurile dintre stalpi
        for j in range(NB):
            cb = G_CB[group_of(j)]
            pa = 0.8 if (side == 1 and ((j in ARCADE) or (j - 1 in ARCADE))) else 0.6
            pb = 0.8 if (side == 1 and ((j in ARCADE) or (j + 1 in ARCADE))) else 0.6
            a, b = PIER[j] + pa, PIER[j + 1] - pb
            lower, upper = bay_kind(j, side)
            L = local(T, 0.0, side)
            mid = (a + b) * 0.5
            if lower == "arcade":
                # balustrada pe planul peretelui (soclul tine 0,3 m), apoi golul spre sanctuar
                u = a + 0.25
                while u < b - 0.2:
                    S_.box(tuple(T.P(u, side, 0.22, 1.15)), (0.18, 0.18, 0.70), ST,
                           rotation=Matrix.Rotation(math.atan2(T.tangent(u).y, T.tangent(u).x), 3, "Z"))
                    u += 0.42
                slab(S_, side, a, b, FACE, 0.45, 1.50, 1.72)
                slab(S_, side, a, b, 0.05, 0.40, 0.80, 0.86)
                top_open = 10.0             # golul liber pe toata latimea pana la 8,8 m
                for k, (inset, h0, h1) in enumerate(((0.0, top_open, cb), (0.35, top_open - 0.6, top_open),
                                                     (0.70, top_open - 1.2, top_open - 0.6))):
                    if inset == 0.0:
                        slab(S_, side, a, b, 0.25, WALL_T, h0, h1)
                    else:
                        slab(S_, side, a, a + inset, 0.25, WALL_T, h0, h1)
                        slab(S_, side, b - inset, b, 0.25, WALL_T, h0, h1)
                slab(S_, side, a, b, 0.12, WALL_T, top_open, top_open + 0.45)
                slab(S_, side, a, b, 0.10, WALL_T, cb - 0.45, cb)
                continue
            # --- registrul de jos (0,8 .. 5,0) ---
            if lower == "relief":
                slab(S_, side, a, b, 0.25, WALL_T, 0.8, 1.1)
                slab(S_, side, a, b, 0.25, WALL_T, 4.7, 5.0)
                slab(S_, side, a, a + 0.22, 0.25, WALL_T, 1.1, 4.7)
                slab(S_, side, b - 0.22, b, 0.25, WALL_T, 1.1, 4.7)
                slab(S_, side, a + 0.22, b - 0.22, 0.50, WALL_T, 1.1, 4.7)
                n_f = 3
                wpan = (b - a - 0.44)
                for k in range(n_f):
                    uc = a + 0.22 + wpan * (k + 0.5) / n_f
                    apsara(S_, lambda u, e, h: T.P(u, side, e, h), uc, 0.50, 1.55,
                           scale=1.25, pose=(k + j) % 2, depth=0.14)
                # brau de lotusi sub registru
                for k in range(6):
                    uc = a + 0.22 + wpan * (k + 0.5) / 6
                    thull(S_, [T.P(uc + du, side, e, h) for du in (-0.16, 0.16)
                               for (e, h) in ((0.51, 1.15), (0.42, 1.25), (0.51, 1.42), (0.44, 1.35))])
            elif lower == "deep":
                # nisa adanca: trece de zid in terasa (taietor `_cut_deep`), cu fund, pereti si
                # capac proprii, prag, bolta in consola si o candela mare
                na, nb_ = a + 0.42, b - 0.42
                slab(S_, side, a, na, 0.25, WALL_T, 0.8, 5.0)
                slab(S_, side, nb_, b, 0.25, WALL_T, 0.8, 5.0)
                slab(S_, side, na, nb_, 0.25, WALL_T, 4.55, 5.0)
                for k, (ins, h0, h1) in enumerate(((0.2, 4.05, 4.55), (0.42, 3.6, 4.05))):
                    slab(S_, side, na, na + ins, 0.25, DEEP_E, h0, h1)
                    slab(S_, side, nb_ - ins, nb_, 0.25, DEEP_E, h0, h1)
                slab(S_, side, na, nb_, DEEP_E, DEEP_E + 0.3, -0.6, 4.6)          # fund
                slab(S_, side, na - 0.3, na, WALL_T - 0.05, DEEP_E + 0.3, -0.6, 4.9)
                slab(S_, side, nb_, nb_ + 0.3, WALL_T - 0.05, DEEP_E + 0.3, -0.6, 4.9)
                slab(S_, side, na - 0.3, nb_ + 0.3, WALL_T - 0.05, DEEP_E + 0.3, 4.55, 5.0)   # capac
                slab(S_, side, na, nb_, WALL_T - 0.05, DEEP_E, -0.6, 0.8)          # pardoseala
                slab(S_, side, na - 0.1, nb_ + 0.1, 0.18, 0.25, 0.8, 0.95)         # prag
                lamps.append((tuple(T.P(mid, side, 1.6, 0.80)), 1.6))
                for du in (-0.75, 0.75):
                    lamps.append((tuple(T.P(mid + du, side, 2.3, 0.80)), 0.9))
            else:
                na, nb_ = a + 0.62, b - 0.62
                slab(S_, side, a, na, 0.25, WALL_T, 0.8, 5.0)
                slab(S_, side, nb_, b, 0.25, WALL_T, 0.8, 5.0)
                slab(S_, side, na, nb_, 0.25, WALL_T, 4.2, 5.0)
                slab(S_, side, na, nb_, 1.30, WALL_T, 0.8, 4.2)
                for k, (ins, h0, h1) in enumerate(((0.18, 3.75, 4.2), (0.36, 3.35, 3.75))):
                    slab(S_, side, na, na + ins, 0.25, 1.30, h0, h1)
                    slab(S_, side, nb_ - ins, nb_, 0.25, 1.30, h0, h1)
                slab(S_, side, na - 0.1, nb_ + 0.1, 0.18, 0.25, 0.8, 0.95)       # prag
                lamps.append((tuple(T.P(mid, side, 0.80, 0.80)), 1.0))
            # friza si cornisa de sub bolta
            slab(S_, side, a, b, 0.12, WALL_T, 5.0, 5.55)
            u = a + 0.3
            while u < b - 0.2:                                           # rozete pe friza
                thull(S_, [T.P(u + du, side, e, h) for du in (-0.11, 0.11) for (e, h) in
                           ((0.13, 5.16), (0.13, 5.40), (0.08, 5.22), (0.08, 5.34))])
                u += 0.8
            slab(S_, side, a, b, 0.10, WALL_T, cb - 0.45, cb)
            # --- registrul de sus (5,55 .. cb - 0,45) ---
            if upper in ("window", "blind"):
                w0, w1 = window_heights(cb)
                wa, wb = a + 0.38, b - 0.38
                et = WIN_T if upper == "window" else WALL_T
                slab(S_, side, a, wa, 0.25, et, 5.55, cb - 0.45)
                slab(S_, side, wb, b, 0.25, et, 5.55, cb - 0.45)
                slab(S_, side, wa, wb, 0.25, et, 5.55, w0)
                slab(S_, side, wa, wb, 0.25, et, w1, cb - 0.45)
                slab(S_, side, wa - 0.12, wb + 0.12, 0.15, 0.25, w0 - 0.2, w0)   # pervaz
                slab(S_, side, wa - 0.12, wb + 0.12, 0.15, 0.25, w1, w1 + 0.25)  # buiandrug
                eb = 0.58 if upper == "window" else 0.75
                if upper == "blind":
                    slab(S_, side, wa, wb, 1.10, WALL_T, w0, w1)
                nbal = 5
                for k in range(nbal):
                    uc = wa + (wb - wa) * (k + 0.5) / nbal
                    baluster(S_, tuple(T.P(uc, side, eb, w0)), w1 - w0, r=0.13)
                if upper == "window":
                    # rama exterioara a ferestrei, pe fata zidului subtire (panou retras afara)
                    slab(S_, side, wa - 0.3, wa, WIN_T, WIN_T + 0.2, w0 - 0.3, w1 + 0.3)
                    slab(S_, side, wb, wb + 0.3, WIN_T, WIN_T + 0.2, w0 - 0.3, w1 + 0.3)
                    slab(S_, side, wa, wb, WIN_T, WIN_T + 0.2, w1, w1 + 0.3)
                    slab(S_, side, wa, wb, WIN_T, WIN_T + 0.25, w0 - 0.3, w0)
            else:
                slab(S_, side, a, b, 0.25, WALL_T, 5.55, cb - 0.45)
                hm = (5.55 + cb - 0.45) * 0.5
                slab(S_, side, a, b, 0.19, 0.25, hm - 0.15, hm + 0.15)
    for p, sc in lamps:
        lamp(S_, Br, p, scale=sc)

    # --- bolta in consola (3 trepte), nervuri, rozete, diafragme ---
    for g, (j0, j1) in enumerate(GROUPS):
        cb = G_CB[g]
        m0, m1 = PIER[j0], PIER[j1]
        for side in (-1, 1):
            for i in range(3):
                slab(S_, side, m0, m1, -(i + 1) * 0.75, WALL_T, cb + i * 0.4, cb + (i + 1) * 0.4)
        span(S_, m0, m1, WALL_T, WALL_T, cb + VR, cb + VT)
        for j in range(j0 + 1, j1):
            span(S_, PIER[j] - 0.3, PIER[j] + 0.3, -2.25, -2.25, cb + 0.8, cb + VR)
        for j in range(j0, j1):
            mm = (PIER[j] + PIER[j + 1]) * 0.5
            if any(abs(mm - hm_) < 2.4 for hm_, _ in HUNG):
                continue
            c = T.P(mm, 0, 0, cb + VR - 0.09, 0.0)
            S_.frustum(tuple(c), 0.55, 0.85, 0.18, ST, segments=8)
            S_.frustum(tuple(c - Vector((0, 0, 0.12))), 0.22, 0.45, 0.10, ST, segments=8)
    for g in range(len(GROUPS) - 1):
        mb = PIER[GROUPS[g][1]]
        lo, hi = min(G_CB[g], G_CB[g + 1]), max(G_CB[g], G_CB[g + 1])
        span(S_, mb - 0.3, mb + 0.3, WALL_T, WALL_T, lo + VR, hi + VT)
    # timpanele de deasupra portalurilor, pe dinauntru
    for (ma, mb, mc) in ((M_W, M_W + 0.5, M_W + 0.5), (M_N - 0.5, M_N, M_N - 0.5)):
        cb = cb_at(mc)
        span(S_, ma, mb, 0.1, 0.1, T.Cmax(ma, mb) + 0.03, cb + VR)


def build_nave_exterior(S_, G_, streaks, tube=None, groups=None, cbs=None, roofs=None, piers=None,
                        solid=False):
    """Peretii exteriori (pilastri, cornisa) si acoperisul in doua trepte al unei nave, ca la
    galeriile khmere: o streasina joasa (pe zid) si, peste ea, acoperisul mare de tigla curbata
    cu coama; nervuri de tigla si antefixe pe amandoua. Pe nava falsa (`solid`), si miezul plin."""
    tube = tube or T
    groups = groups or [(PIER[j0], PIER[j1]) for (j0, j1) in GROUPS]
    cbs = cbs or G_CB
    roofs = roofs or R_ROOF
    piers = piers or PIER
    gs = (0.25, 0.5, 0.75, 0.92)
    for (m0, m1), cb, rr in zip(groups, cbs, roofs):
        top = cb + VT                         # fata de sus a boltii
        if solid:
            span(S_, m0, m1, WALL_T, WALL_T, -0.6, top, tube=tube)
        # treapta de jos: de la streasina (e 2,75) pana peste zid (e 0,2)
        RL, b1, t1, i1 = 2.75, top - 0.15, top + 0.25, top + 1.05
        for side in (-1, 1):
            sweep(S_, tube, m0, m1, [(side, RL, b1), (side, RL, t1), (side, 0.2, i1), (side, 0.2, b1)])
        # acoperisul mare: streasina la e 0,9, coama pe axa
        RE, b2, t2 = 0.9, top + 0.75, top + 1.2
        hgt = lambda g_, t2=t2, rr=rr: t2 + rr * (1.0 - (1.0 - g_) ** 2)
        prof = [(-1, RE, b2), (1, RE, b2), (1, RE, t2)]
        for g_ in gs:
            prof.append((1, RE, hgt(g_), 1.0 - g_))
        prof.append((1, RE, hgt(1.0) + 0.14, 0.03))
        prof.append((-1, RE, hgt(1.0) + 0.14, 0.03))
        for g_ in reversed(gs):
            prof.append((-1, RE, hgt(g_), 1.0 - g_))
        prof.append((-1, RE, t2))
        sweep(S_, tube, m0, m1, prof)
        for side in (-1, 1):
            # cornisa sub streasina si brau
            slab(S_, side, m0, m1, WALL_T, WALL_T + 0.40, top - 0.55, top - 0.15, tube=tube)
            slab(S_, side, m0, m1, WALL_T, WALL_T + 0.18, cb - 0.25, cb + 0.05, tube=tube)
            # nervuri de tigla (acoperisul mare si treapta de jos)
            mm = m0 + 0.75
            while mm < m1 - 0.5:
                W_ = tube.W(mm)
                f_eave = (W_ + RE) / (W_ + RE)
                pts_line = [(1.0, t2)] + [(1.0 - g_, hgt(g_)) for g_ in gs] + [(0.06, hgt(1.0))]
                for (fa, ha), (fb, hb) in zip(pts_line[:-1], pts_line[1:]):
                    pts = []
                    for (f_, h_) in ((fa, ha), (fb, hb)):
                        for du in (-0.09, 0.09):
                            pts.append(tube.P(mm + du, side, RE, h_ - 0.02, f_))
                            pts.append(tube.P(mm + du, side, RE, h_ + 0.08, f_))
                    thull(S_, pts)
                pts = []
                for (e_, h_) in ((RL, t1), (0.95, top + 0.83)):
                    for du in (-0.09, 0.09):
                        pts.append(tube.P(mm + du, side, e_, h_ - 0.02))
                        pts.append(tube.P(mm + du, side, e_, h_ + 0.08))
                thull(S_, pts)
                mm += 2.0
            # antefixe pe ambele streasini
            mm = m0 + 0.6
            while mm < m1 - 0.3:
                for (e0_, h0_) in ((RL, t1), (RE, t2)):
                    thull(S_, [tube.P(mm + du, side, e, h) for du in (-0.13, 0.13)
                               for (e, h) in ((e0_ - 0.25, h0_ - 0.05), (e0_ + 0.02, h0_ - 0.05),
                                              (e0_ - 0.12, h0_ + 0.38), (e0_ - 0.02, h0_ + 0.30))])
                mm += 2.0
            streaks.append((tube, side, m0 + 0.5, m1 - 0.5, WALL_T + 0.40, top - 0.55, 6, 0.4, 1.3))
            streaks.append((tube, side, m0 + 0.5, m1 - 0.5, WALL_T + 0.18, cb - 0.25, 4, 0.6, 1.8))
    for side in (-1, 1):
        for m in piers:
            m0_, m1_ = max(m - 0.5, piers[0]), min(m + 0.5, piers[-1])
            cbm = max(cb for (g0, g1), cb in zip(groups, cbs) if g0 - 1e-6 <= m <= g1 + 1e-6)
            slab(S_, side, m0_, m1_, WALL_T, WALL_T + 0.22, -0.5, cbm + VT - 0.55, tube=tube)


# =============================================================================
# exteriorul: masivul, galeriile-inel, terasele, pavilioanele, turnurile
# =============================================================================

def fr_of(k, o=(0.0, 0.0)):
    return Frame((o[0], o[1], 0.0), 90.0 * k)


def rbox(b, k, u0, u1, w0, w1, z0, z1, slot=ST):
    fr = fr_of(k)
    p, q = fr.p(u0, w0), fr.p(u1, w1)
    bx(b, p.x, q.x, p.y, q.y, z0, z1, slot)


def rcol(b, k, u, w, z0, z1, cw=0.6):
    p = fr_of(k).p(u, w)
    column(b, p.x, p.y, z0, z1, w=cw)


def rhull(b, k, pts, slot=ST):
    fr = fr_of(k)
    hull(b, [fr.p(u, w, z) for (u, w, z) in pts], slot)


def rgable(b, k, uc, w0, w1, z0, hw, zapex):
    fr = fr_of(k)
    pts = []
    for w in (w0, w1):
        pts += [fr.p(uc - hw, w, z0), fr.p(uc + hw, w, z0), fr.p(uc, w, zapex)]
    hull(b, pts, ST)


ARM_HALF = 9.1                    # jumatatea navelor false + pilastri (pentru goluri)


def forbidden(k, cu, w0, w1, z):
    """Intervalele de u pe latura k unde fasia (w0..w1) a unui inel intra in tub (sau in
    navele false E / S, unde inelul se opreste in zidul lor)."""
    fr = fr_of(k)
    bad = []
    u = -cu
    while u <= cu + 1e-6:
        hit = False
        for w in (w0, (w0 + w1) * 0.5, w1):
            p = fr.p(u, w)
            if in_K(p.x, p.y, z):
                hit = True
        if k in (2, 3) and abs(u) < ARM_HALF:
            hit = True
        if hit:
            bad.append(u)
        u += 0.2
    segs = []
    if not bad:
        return [(-cu, cu)]
    lo, hi = min(bad) - 0.5, max(bad) + 0.5
    # un singur gol pe latura (inelele sunt traversate o data)
    if lo > -cu + 0.5:
        segs.append((-cu, lo))
    if hi < cu - 0.5:
        segs.append((hi, cu))
    return segs


def ring_gallery(S_, G_, sites, streaks, half_axis, wall0, wall1, colw, z0, zc, prof, shr,
                 col_step, corner, seed, gap_half=None):
    cu = half_axis - corner
    for k in range(4):
        segs = forbidden(k, cu, wall0 - 0.5, colw + 1.4, z0 + 1.0)
        if gap_half is not None:
            segs2 = []
            for (a, b) in segs:
                if a < -gap_half and b > gap_half:
                    segs2 += [(a, -gap_half), (gap_half, b)]
                elif b <= -gap_half or a >= gap_half:
                    segs2.append((a, b))
                elif a < -gap_half:
                    segs2.append((a, -gap_half))
                elif b > gap_half:
                    segs2.append((gap_half, b))
            segs = segs2
        wmid = (wall0 + colw) * 0.5
        for (ua, ub) in segs:
            if ub - ua < 1.0:
                continue
            rbox(S_, k, ua, ub, wall0 - 0.5, colw + 1.3, z0, z0 + 0.35)
            rbox(S_, k, ua, ub, wall0, wall1, z0 + 0.35, zc)
            fr = fr_of(k)
            p, q = fr.p(ua, wall0), fr.p(ub, wall1)
            wall_faces(S_, min(p.x, q.x), max(p.x, q.x), min(p.y, q.y), max(p.y, q.y), z0 + 0.35, zc,
                       [{0: "+y", 1: "-x", 2: "-y", 3: "+x"}[k], {0: "-y", 1: "+x", 2: "+y", 3: "-x"}[k]],
                       ch=1.5, bw=3.6, seed=seed + k)
            u = ua + 1.2
            while u < ub - 0.5:
                rcol(S_, k, u, colw, z0 + 0.35, zc, cw=0.72)
                u += col_step
            rbox(S_, k, ua, ub, colw - 0.6, colw + 0.6, zc - 0.45, zc)
            pts = []
            for (hy, zz), s_ in zip(prof, shr):
                for u_ in (ua, ub):
                    at_corner = abs(abs(u_) - cu) < 0.05
                    ue = u_ - math.copysign(s_ * 0.5, u_) if at_corner else u_
                    for sgn in (-1, 1):
                        pts.append((ue, wmid + sgn * hy, zc + zz))
            rhull(S_, k, pts)
            u = ua + 1.0
            while u < ub - 0.8:
                for sgn in (-1, 1):
                    for j in (1, 3):
                        (ya_, za_), (yb_, zb_) = prof[j], prof[j + 1]
                        seg = []
                        for (yy, zz) in ((ya_, za_), (yb_, zb_)):
                            for du in (-0.1, 0.1):
                                seg.append((u + du, wmid + sgn * yy, zc + zz))
                                seg.append((u + du, wmid + sgn * (yy + 0.08), zc + zz + 0.08))
                        rhull(S_, k, seg)
                u += 3.2
            u = ua + 1.0
            while u < ub - 0.5:
                p = fr_of(k).p(u, wmid + prof[0][0] - 0.1, zc + 0.35)
                S_.box((p.x, p.y, p.z), (0.3, 0.3, 0.38), ST,
                       rotation=Matrix.Rotation(math.radians(90.0 * k), 3, "Z"))
                u += 2.0
            streaks.append(("w", k, ua + 0.6, ub - 0.6, colw + 0.6, zc, 6, 0.25, 0.6))
            streaks.append(("w", k, ua + 0.6, ub - 0.6, wall1, zc, 6, 0.5, 1.4))
            p, q = fr.p(ua, colw + 0.4), fr.p(ub, colw + 1.25)
            sites.append((min(p.x, q.x), max(p.x, q.x), min(p.y, q.y), max(p.y, q.y), z0 + 0.35))


def tower(S_, cx, cy, z0, base_half, base_h, tiers, top, bud_r, gables=3, cut=False):
    """Turn-boboc (ca `build_angkor_temple.tower`): baza patrata cu blocuri, etaje rotunde,
    frontonase pe primele etaje, boboc cu finial. `cut`: etajele trec prin taietori (putul)."""
    def base(b):
        bx(b, cx - base_half, cx + base_half, cy - base_half, cy + base_half, z0, z0 + base_h)
    if cut:
        carved(S_, base)
    else:
        base(S_)
    wall_faces(S_, cx - base_half, cx + base_half, cy - base_half, cy + base_half, z0, z0 + base_h,
               ["+y", "-y", "+x", "-x"], ch=0.8, bw=2.2, seed=int(abs(cx) * 7 + abs(cy) * 3 + 11))
    z = z0 + base_h
    for i, (r, h) in enumerate(tiers):
        if i < gables:
            for k in range(4):
                fr = Frame((cx, cy, 0.0), 90.0 * k)
                pts = []
                for w, ww in ((r * 0.90, 1.0), (r + 0.18, 0.5)):
                    pts += [fr.p(-0.75 * ww * r / 3.0, w, z + 0.1), fr.p(0.75 * ww * r / 3.0, w, z + 0.1)]
                pts += [fr.p(0.0, r * 0.90, z + h * 0.78), fr.p(0.0, r + 0.18, z + h * 0.7)]
                hull(S_, pts, ST)
        zz = z
        if cut and zz < SHAFT_TOP:
            carved(S_, lambda b, zz=zz, r=r, h=h: round_tier(b, cx, cy, zz, h, r))
            z = zz + h + 0.09
        else:
            z = round_tier(S_, cx, cy, z, h, r)
    lotus_bud(S_, cx, cy, z, top - z, bud_r, ST, petals=8, segments=14)


def pavilion(S_, G_, sites, streaks, k, front, drive):
    """Pavilionul de intrare pe axa laturii k (fata la `front` de origine): corp, cornisa,
    rama usii, fronton; pe axele false (drive=False) o usa oarba sculptata."""
    fr = fr_of(k)
    back = HALF - 7.4
    PH = 12.5
    ZB, ZT = 3.4, 16.0

    def body(b):
        rbox(b, k, -PH, PH, back, front, ZB, ZT)
    carved(S_, body)
    # blocuri pe fata, pe flancuri (in afara ramei)
    def courses(b):
        for (ua, ub) in ((-PH, -8.6), (8.6, PH)):
            p, q = fr.p(ua, back), fr.p(ub, front)
            wall_faces(b, min(p.x, q.x), max(p.x, q.x), min(p.y, q.y), max(p.y, q.y), ZB, ZT,
                       [{0: "+y", 1: "-x", 2: "-y", 3: "+x"}[k]], ch=1.0, bw=2.2, seed=300 + k, proud=0.05)
    # (blocurile ies 5 cm: planul fatadei ramane la 0,05 de capac)
    filtered(S_, courses)
    # pilastri si ferestre oarbe pe flancuri (ies in fata fatadei doar peste 2,6 m)
    for sg in (-1, 1):
        for uc in (9.4, 12.0):
            rbox(S_, k, sg * uc - 0.45, sg * uc + 0.45, front, front + 0.25, 6.6, ZT)
        uc = sg * 10.7
        rbox(S_, k, uc - 0.9, uc + 0.9, front, front + 0.18, 8.0, 8.25)
        rbox(S_, k, uc - 0.9, uc + 0.9, front, front + 0.18, 12.4, 12.7)
        for i in range(3):
            p = fr.p(uc - 0.6 + 0.6 * i, front + 0.12)
            baluster(S_, (p.x, p.y, 8.25), 4.15, r=0.11)
    # cornisa si atic in trepte (taiate si ele: trec peste bolta navei)
    carved(S_, lambda b: rbox(b, k, -PH - 0.3, PH + 0.3, back, front + 0.4, ZT, ZT + 0.5))
    carved(S_, lambda b: rbox(b, k, -PH + 0.6, PH - 0.6, back + 0.6, front - 0.2, ZT + 0.5, ZT + 1.6))
    carved(S_, lambda b: rbox(b, k, -PH + 1.4, PH - 1.4, back + 1.2, front - 0.8, ZT + 1.6, ZT + 2.4))
    sites.append(tuple(sorted((fr.p(-PH, front).x, fr.p(PH, front + 0.4).x))) +
                 tuple(sorted((fr.p(-PH, front).y, fr.p(PH, front + 0.4).y))) + (ZT + 0.5,))
    for sg in (-1, 1):
        for uc in (PH - 0.2,):
            p = fr.p(sg * uc, front + 0.2)
            hull(S_, [Vector((p.x + dx, p.y + dy, ZT + 0.5 + dz)) for dx in (-0.25, 0.25) for dy in (-0.25, 0.25)
                      for dz in (0.0,)] + [Vector((p.x, p.y, ZT + 1.6))], ST)
    streaks.append(("w", k, -PH + 0.5, -8.8, front, ZT, 5, 0.6, 1.8))
    streaks.append(("w", k, 8.8, PH - 0.5, front, ZT, 5, 0.6, 1.8))
    # --- rama usii: montantii stau EXACT pe rama de coliziune (6,0 .. 6,8, 1,2 in afara capacului)
    Z0 = ROAD_Z
    for sg in (-1, 1):
        rbox(S_, k, sg * 6.02, sg * 6.82, front, front + 1.19, Z0 - 0.5, Z0 + 10.02)
        rbox(S_, k, sg * 6.82, sg * 8.6, front, front + 0.55, Z0 - 0.5, Z0 + 10.02)
        rbox(S_, k, sg * 6.82, sg * 8.75, front, front + 0.7, Z0 - 0.5, Z0 + 0.35)   # talpa
        # colonete octogonale in fata montantilor
        p = fr.p(sg * 7.25, front + 0.80)
        oct_prism(S_, p.x, p.y, Z0 + 0.35, Z0 + 0.6, 0.36, 0.1)
        oct_prism(S_, p.x, p.y, Z0 + 0.6, Z0 + 9.4, 0.27, 0.08)
        for zr in (2.4, 4.7, 7.0):
            oct_prism(S_, p.x, p.y, Z0 + zr, Z0 + zr + 0.22, 0.33, 0.1)
        oct_prism(S_, p.x, p.y, Z0 + 9.4, Z0 + 10.0, 0.36, 0.1)
    # buiandrugul (peste 10 m: poate iesi), cornisa, frontonul
    rbox(S_, k, -8.6, 8.6, front, front + 1.35, Z0 + 10.02, Z0 + 11.9)
    for i in range(9):
        uc = -6.4 + 1.6 * i
        p = fr.p(uc, front + 1.38)
        hull(S_, [Vector((p.x, p.y, Z0 + 10.95)) + fr.rot @ Vector((du, dw, 0.0)) + Vector((0, 0, dz))
                  for du in (-0.32, 0.32) for dw in (-0.05, 0.08) for dz in (-0.32, 0.32)], ST)
    rbox(S_, k, -9.2, 9.2, front, front + 1.65, Z0 + 11.9, Z0 + 12.4)
    zb, za = Z0 + 12.4, Z0 + 20.2
    rgable(S_, k, 0.0, front, front + 1.15, zb, 9.4, za)
    # flacarile de pe marginea frontonului (dinti ascutiti, ca la frontoanele khmere)
    for sg in (-1, 1):
        d = Vector((-sg * 9.4, za - zb)).normalized()
        n = Vector((d.y, -d.x)) * (-sg if d.y * sg < 0 else sg)
        if n.y < 0:
            n = -n
        for i in range(1, 8):
            t = i / 8.0
            u0, z0 = sg * 9.4 * (1.0 - t), zb + (za - zb) * t
            base = []
            for du in (-0.28, 0.28):
                for w in (front + 0.2, front + 0.95):
                    q = fr.p(u0 + d.x * du, w)
                    base.append(Vector((q.x, q.y, z0 + d.y * du)))
            q = fr.p(u0 + n.x * 0.75 - d.x * 0.15, front + 0.6)
            hull(S_, base + [Vector((q.x, q.y, z0 + n.y * 0.75 - d.y * 0.15))], ST)
    rgable(S_, k, 0.0, front + 1.15, front + 1.4, zb + 0.4, 8.0, za - 1.2)
    rgable(S_, k, 0.0, front + 1.4, front + 1.55, zb + 1.3, 5.6, za - 2.9)
    p = fr.p(0.0, front + 1.6)
    S_.cylinder((p.x, p.y, zb + 2.8), 1.1, 0.25, ST, segments=12, axis="Y" if k % 2 == 0 else "X")
    S_.cylinder((p.x, p.y, zb + 2.8), 0.55, 0.45, ST, segments=10, axis="Y" if k % 2 == 0 else "X")
    for sg in (-1, 1):            # capete de naga intoarse la baza frontonului
        p = fr.p(sg * 9.5, front + 0.9)
        hull(S_, [Vector((p.x, p.y, zb)) + fr.rot @ Vector((du, dw, 0.0)) + Vector((0, 0, dz))
                  for du in (-0.35, 0.35) for dw in (-0.3, 0.3) for dz in (0.0, 0.4)] +
             [Vector((p.x, p.y, zb + 1.5)) + fr.rot @ Vector((sg * 0.5, 0.0, 0.0))], ST)
    p = fr.p(0.0, front + 0.6)
    hull(S_, [Vector((p.x, p.y, za)) + fr.rot @ Vector((du, dw, 0.0)) for du in (-0.3, 0.3)
              for dw in (-0.3, 0.3)] + [Vector((p.x, p.y, za + 1.6))], ST)
    if not drive:
        # usa oarba: canaturi sculptate in golul ramei
        rbox(S_, k, -6.02, 6.02, front - 0.2, front + 0.5, Z0 - 0.5, Z0 + 10.02)
        for sg in (-1, 1):
            for r_ in range(5):
                for c_ in range(2):
                    uc = sg * (1.5 + 2.6 * c_)
                    zc_ = Z0 + 1.2 + 1.85 * r_
                    rbox(S_, k, uc - 1.0, uc + 1.0, front + 0.5, front + 0.62, zc_ - 0.75, zc_ + 0.75)
                    p = fr.p(uc, front + 0.66)
                    S_.cylinder((p.x, p.y, zc_), 0.32, 0.12, ST, segments=8,
                                axis="Y" if k % 2 == 0 else "X")
        rbox(S_, k, -0.12, 0.12, front + 0.5, front + 0.75, Z0, Z0 + 10.0)


def wings_and_naga(S_, L_):
    """Aripile portalurilor ca balustrade de piatra cu trup de naga, si capul cu sapte capete
    la capatul departat. Fata dinspre drum = fata aripii de coliziune (2 cm in spate)."""
    out = []
    for (k_cap, kn) in ((0, 1), (T.n - 1, T.n - 2)):
        c = T.c[k_cap]
        outward = (c - T.c[kn])
        outward.z = 0.0
        outward.normalize()
        s = T.s[k_cap]
        c2 = c + outward * 1.2
        far = c2 + outward * 14.0
        for sg in (-1, 1):
            a0 = c2 + s * (sg * 6.0)
            b0 = far + s * (sg * 9.5)
            axis = (b0 - a0)
            axis.z = 0.0
            Lw = axis.length
            ax = axis / Lw
            nrm = Vector((-ax.y, ax.x, 0.0))
            if nrm.dot(s * sg) < 0:
                nrm = -nrm                       # normala spre exteriorul aripii (dinspre drum)

            def W(u, e, h, a0=a0, ax=ax, nrm=nrm):
                p = a0 + ax * u + nrm * e
                return Vector((p.x, p.y, ROAD_Z + h))

            def top(u, Lw=Lw):
                return 2.5 + (1.1 - 2.5) * (u / Lw)
            # miez, soclu, mana curenta, montanti, balustri -- toate in spatele fetei de coliziune
            def prism(u0, u1, e0, e1, h0t, h1t, slot=ST):
                pts = []
                for u in (u0, u1):
                    hb = h0t(u) if callable(h0t) else h0t
                    ht = h1t(u) if callable(h1t) else h1t
                    for e in (e0, e1):
                        pts += [W(u, e, hb), W(u, e, ht)]
                hull(S_, pts, slot)
            prism(0.0, Lw, 0.34, 0.5, -0.5, top)                            # miezul
            prism(0.0, Lw, 0.02, 0.5, -0.5, 0.40)                           # soclul
            prism(0.0, Lw, 0.02, 0.5, lambda q: top(q) - 0.28, top)         # mana curenta
            u = 0.0
            while u < Lw - 0.1:
                u1 = min(u + 1.75, Lw)
                prism(u, min(u + 0.36, Lw), 0.02, 0.5, 0.40, lambda q: top(q) - 0.28)
                b = u + 0.58
                while b < u1 - 0.2:
                    prism(b - 0.07, b + 0.07, 0.16, 0.34, 0.40, lambda q: top(q) - 0.28)
                    b += 0.3
                u = u1
            prism(Lw - 0.36, Lw, 0.02, 0.5, 0.40, lambda q: top(q) - 0.28)
            out.append((W, top, Lw, ax, nrm))
    return out


def wings_detail(S_, wings):
    for (W, top, Lw, ax, nrm) in wings:
        # trupul naga pe muchie: centrul la e = 0,27 (iese cel mult pana la e = 0,03)
        path = []
        n = int(Lw / 0.25)
        for i in range(n + 1):
            u = Lw * i / n
            path.append(W(u, 0.27, top(u) + 0.18))
        # capatul: trupul coteste in spate spre capul cu sapte capete
        hd = W(Lw - 0.5, 1.05, 0.0)
        naga_body(S_, path[:-2] + [W(Lw - 1.6, 0.6, top(Lw - 1.6) + 0.15)], r=0.24)
        # capul din kit (evantai de 7 capete, ~2,5 m) scalat 1,3, cu fata in sensul aripii
        objs = _NG["build_head"]()
        rot = Matrix(((nrm.x, ax.x, 0.0), (nrm.y, ax.y, 0.0), (0.0, 0.0, 1.0)))
        xf = Matrix.Translation(Vector((hd.x, hd.y, ROAD_Z - 0.05))) @ rot.to_4x4() @ Matrix.Diagonal((1.3, 1.3, 1.3, 1.0))
        for ob in objs:
            if not ob.name.startswith("Naga_Stone"):
                old = ob.data
                bpy.data.objects.remove(ob, do_unlink=True)
                bpy.data.meshes.remove(old)
                continue
            bm = bmesh.new()
            bm.from_mesh(ob.data)
            bm.faces.index_update()
            # cat iese evantaiul spre drum: se impinge in spate pana sta la 0,08 m dupa fata aripii
            a0 = W(0.0, 0.0, 0.0)
            e_min = min((xf @ v.co - a0).dot(nrm) for v in bm.verts)
            if e_min < 0.08:
                xf = Matrix.Translation(nrm * (0.08 - e_min)) @ xf
            copy_bm(bm, None, S_, slot=ST, xform=xf)
            bm.free()
            old = ob.data
            bpy.data.objects.remove(ob, do_unlink=True)
            bpy.data.meshes.remove(old)


def false_arm_tube(k):
    """Nava falsa (E: k = 3, S: k = 2) ca tub drept, oglinda navei reale de pe aceeasi linie."""
    pts = []
    if k == 3:
        x = 51.66
        while x > BLK - 2.5:
            pts.append(max(x, BLK))
            x -= 2.5
        c = [Vector((x_, 0.0, ROAD_Z)) for x_ in pts]
        s = [Vector((0.0, 1.0, 0.0))] * len(pts)
        m = [51.66 - x_ - 0.3 for x_ in pts]
        w = [T.W(mm) if mm < 22.0 else 8.0 for mm in m]
    else:
        y = -54.5
        while y < -BLK + 2.5:
            pts.append(min(y, -BLK))
            y += 2.5
        c = [Vector((0.0, y_, ROAD_Z)) for y_ in pts]
        s = [Vector((-1.0, 0.0, 0.0))] * len(pts)
        m = [54.5 + y_ for y_ in pts]          # 0 la fatada
        w = [T.W(M_N - mm) if mm < 26.0 else 8.0 for mm in m]
    return Tube(c, s, w, m, [0.0] * len(c))


def build_false_arm(S_, G_, streaks, k):
    tb = false_arm_tube(k)
    mlen = tb.m[-1]
    if k == 3:     # oglinda navei de vest
        cuts = [tb.m[0], PIER[2], PIER[4], mlen]
        cbs = G_CB[0:3]
        rr = R_ROOF[0:3]
    else:          # oglinda navei de nord, numarat de la fatada
        cuts = [tb.m[0], M_N - PIER[18], M_N - PIER[16], mlen]
        cbs = [G_CB[4], G_CB[3], G_CB[2]]
        rr = [R_ROOF[4], R_ROOF[3], R_ROOF[2]]
    groups = list(zip(cuts[:-1], cuts[1:]))
    piers = []
    mm = tb.m[0]
    while mm < mlen - 0.5:
        piers.append(mm)
        mm += PITCH
    piers.append(mlen)
    build_nave_exterior(S_, G_, streaks, tube=tb, groups=groups, cbs=cbs, roofs=rr, piers=piers, solid=True)
    # ferestre oarbe cu balustri pe exterior, intre pilastri
    for side in (-1, 1):
        for ib, (a_, b_) in enumerate(zip(piers[:-1], piers[1:])):
            if ib % 2:
                continue
            cbm = max(cb for (g0, g1), cb in zip(groups, cbs) if g0 - 1e-6 <= (a_ + b_) * 0.5 <= g1 + 1e-6)
            wa, wb = a_ + 1.0, b_ - 1.0
            if wb - wa < 1.2:
                continue
            w0, w1 = 6.3, cbm - 1.4
            slab(S_, side, wa - 0.2, wa, WALL_T, WALL_T + 0.3, w0 - 0.25, w1 + 0.25, tube=tb)
            slab(S_, side, wb, wb + 0.2, WALL_T, WALL_T + 0.3, w0 - 0.25, w1 + 0.25, tube=tb)
            slab(S_, side, wa, wb, WALL_T, WALL_T + 0.3, w1, w1 + 0.25, tube=tb)
            slab(S_, side, wa, wb, WALL_T, WALL_T + 0.35, w0 - 0.25, w0, tube=tb)
            for i in range(3):
                uc = wa + (wb - wa) * (i + 0.5) / 3
                baluster(S_, tuple(tb.P(uc, side, WALL_T + 0.16, w0)), w1 - w0, r=0.12)


def in_amb(x, y, pad=0.0):
    """Punctul din plan cade in ambulatoriu (spatele arcadei, e 2 .. 7,6)?"""
    r = T.locate(x, y)
    return (r is not None and r[1] > 0 and AMB_M[0] - 0.7 - pad < r[0] < AMB_M[1] + 0.7 + pad and
            r[2] < AMB_E[1] + 0.9 + pad)


def build_ambulatory(S_, Br):
    """Ambulatoriul din spatele arcadei: zidul din spate cu nise inalte si candele, peretii de
    capat, tavanul si acoperisul in panta; inauntru, al doilea sir de stalpi. Zidul, capetele si
    acoperisul trec prin taietorii camerei (unde ambulatoriul da in camera de sub turn, e deschis)."""
    m0, m1 = AMB_M
    e0, e1 = AMB_E
    tmp = Builder()
    lamps = []
    for j in sorted(ARCADE):
        a, b = max(PIER[j], m0), min(PIER[j + 1], m1)
        mid = (PIER[j] + PIER[j + 1]) * 0.5
        na, nb = mid - 1.15, mid + 1.15
        slab(tmp, 1, a, na, e1, e1 + 0.8, -0.6, 10.8)
        slab(tmp, 1, nb, b, e1, e1 + 0.8, -0.6, 10.8)
        slab(tmp, 1, na, nb, e1, e1 + 0.8, 8.3, 10.8)
        slab(tmp, 1, na, nb, e1 + 0.6, e1 + 0.8, -0.6, 8.3)            # fundul nisei
        slab(tmp, 1, na, nb, e1, e1 + 0.6, -0.6, 0.45)                  # pragul
        for (ins, h0, h1) in ((0.25, 7.75, 8.3), (0.5, 7.2, 7.75)):    # bolta nisei, in consola
            slab(tmp, 1, na, na + ins, e1, e1 + 0.6, h0, h1)
            slab(tmp, 1, nb - ins, nb, e1, e1 + 0.6, h0, h1)
        lamps.append(tuple(T.P(mid, 1, e1 + 0.3, 0.45)))
        if m0 < PIER[j] < m1:                                           # pilastru pe zidul din spate
            slab(tmp, 1, PIER[j] - 0.45, PIER[j] + 0.45, e1 - 0.22, e1, -0.1, 10.8)
    for (ma, mb) in ((m0 - 0.6, m0), (m1, m1 + 0.6)):
        slab(tmp, 1, ma, mb, e0, e1 + 0.8, -0.6, 11.7)
    sweep(tmp, T, m0 - 0.6, m1 + 0.6, [(1, e0, 10.8), (1, e1 + 0.9, 10.8), (1, e1 + 0.9, 11.6),
                                       (1, e0, 12.7)])
    carve_islands(S_, tmp, CHAMB_COLL)
    for p in lamps:
        lamp(S_, Br, p, scale=1.3)
    # al doilea sir de stalpi, la mijlocul ambulatoriului (in dreptul stalpilor arcadei)
    for j in range(min(ARCADE), max(ARCADE) + 2):
        m = PIER[j]
        if not (m0 + 0.6 < m < m1 - 0.6):
            continue
        slab(S_, 1, m - 0.5, m + 0.5, 4.0, 5.0, -0.1, 10.8)
        slab(S_, 1, m - 0.65, m + 0.65, 3.85, 5.15, -0.1, 0.5)
        slab(S_, 1, m - 0.65, m + 0.65, 3.85, 5.15, 10.25, 10.8)
        slab(S_, 1, m - 0.58, m + 0.58, 3.92, 5.08, 5.0, 5.4)


def sanctuary(S_, Br, sites):
    """Camera de sub turnul central: decor pe peretii scobiti, discul palid, soclul-lotus si
    gongul de bronz. Nicio statuie (regula casei)."""
    Zf = 3.9
    # discul palid sub raza (r 4,6 ~ baza razei din joc, 4,4); spre NV intra sub soclul arcadei
    S_.cylinder((0.0, 0.0, Zf + 0.03), 4.6, 0.06, ST, segments=32)
    S_.cylinder((0.0, 0.0, Zf + 0.07), 3.2, 0.04, ST, segments=32)
    # soclul-lotus in origine
    oct_prism(S_, 0.0, 0.0, Zf, Zf + 0.35, 1.9, 0.5)
    oct_prism(S_, 0.0, 0.0, Zf + 0.35, Zf + 0.65, 1.6, 0.42)
    S_.frustum((0.0, 0.0, Zf + 0.85), 1.25, 1.45, 0.40, ST, segments=16)
    for i in range(16):
        a = 2.0 * math.pi * (i + 0.5) / 16
        ca, sa = math.cos(a), math.sin(a)
        tx, ty = -sa, ca
        pts = []
        for (r, z, w) in ((1.25, Zf + 0.66, 0.24), (1.62, Zf + 0.95, 0.30), (1.50, Zf + 1.22, 0.02)):
            for sg in (-1, 1):
                pts.append(Vector((ca * r + tx * sg * w, sa * r + ty * sg * w, z)))
        hull(S_, pts, ST)
    oct_prism(S_, 0.0, 0.0, Zf + 1.05, Zf + 1.35, 1.35, 0.36)
    # cadrul gongului: doi stalpi sculptati si o grinda cu capete de naga intoarse
    d = Vector((-1.0, 1.0, 0.0)).normalized()        # gongul priveste spre sala
    t = Vector((d.y, -d.x, 0.0))
    zt = Zf + 1.35
    for sg in (-1, 1):
        p = t * (sg * 1.75)
        oct_prism(S_, p.x, p.y, zt, zt + 0.3, 0.30, 0.09)
        oct_prism(S_, p.x, p.y, zt + 0.3, zt + 3.9, 0.17, 0.05)
        for zr in (1.2, 2.4):
            oct_prism(S_, p.x, p.y, zt + zr, zt + zr + 0.16, 0.24, 0.07)
    beam_z = zt + 3.9
    S_.beam(tuple(t * -2.3 + Vector((0, 0, beam_z + 0.15))), tuple(t * 2.3 + Vector((0, 0, beam_z + 0.15))),
            (0.32, 0.30), ST, up=(0, 0, 1))
    for sg in (-1, 1):
        q = t * (sg * 2.3) + Vector((0, 0, beam_z + 0.15))
        hull(S_, [q + Vector((0, 0, dz)) + t * (sg * du) + d * dd for du in (0.0, 0.2) for dz in (-0.15, 0.15)
                  for dd in (-0.13, 0.13)] + [q + t * (sg * 0.35) + Vector((0, 0, 0.75))], ST)
    # gongul (bronz): disc, buza, butonul din mijloc, doua snururi
    gc = Vector((0, 0, zt + 2.05))
    rot = Matrix.Rotation(math.atan2(d.y, d.x), 4, "Z") @ Matrix.Rotation(math.radians(90), 4, "Y")
    # fata aurie (disc), buza de bronz (mai subtire: se vede doar pe margine), inelul de bronz de pe
    # fata (cilindru mai gros r 0,78, acoperit in mijloc de un disc auriu r 0,70)
    for (r, th, sl) in ((1.18, 0.10, GOLD), (1.26, 0.06, BRONZE), (0.78, 0.14, BRONZE), (0.70, 0.15, GOLD)):
        res = bmesh.ops.create_cone(Br.bm, cap_ends=True, cap_tris=False, segments=24, radius1=r,
                                    radius2=r, depth=th, matrix=Matrix.Translation(gc) @ rot)
        Br._tag(res["verts"], sl)
    for (r, th) in ((0.34, 0.26), (0.18, 0.38)):
        res = bmesh.ops.create_cone(Br.bm, cap_ends=True, cap_tris=False, segments=12, radius1=r,
                                    radius2=r * 0.8, depth=th, matrix=Matrix.Translation(gc) @ rot)
        Br._tag(res["verts"], BRONZE)
    for sg in (-1, 1):
        Br.beam(tuple(gc + t * (sg * 0.8) + Vector((0, 0, 0.85))), tuple(t * (sg * 0.9) + Vector((0, 0, beam_z))),
                (0.05, 0.05), BRONZE)
    # pilastri si brau pe peretii camerei (doar unde peretele nu e zidul salii)
    for k in range(4):
        fr = fr_of(k)
        for u in (-6.0, -3.0, 0.0, 3.0, 6.0):
            p = fr.p(u, CHAMBER - 0.25)
            if in_K(p.x, p.y, 6.0) or in_amb(p.x, p.y, 0.6) or \
                    (T.locate(p.x, p.y) is not None and T.locate(p.x, p.y)[2] < WALL_T + 0.4):
                continue
            rbox(S_, k, u - 0.4, u + 0.4, CHAMBER - 0.28, CHAMBER + 0.05, Zf, 14.6)
            rbox(S_, k, u - 0.55, u + 0.55, CHAMBER - 0.4, CHAMBER + 0.05, 14.2, 14.6)
            if abs(u) == 3.0:
                p = fr.p(u, CHAMBER - 1.0)
                lamp(S_, Br, (p.x, p.y, Zf), scale=1.2)
    # inelele boltii au muchii vii din boolean; un brau sub nasterea boltii
    for k in range(4):
        fr = fr_of(k)
        for (ua, ub) in ((-CHAMBER, -2.0), (-2.0, 2.0), (2.0, CHAMBER)):
            pa = fr.p(ua, CHAMBER - 0.2)
            pb = fr.p(ub, CHAMBER - 0.2)
            okk = all(not in_K(q.x, q.y, 10.0) and not in_amb(q.x, q.y, 0.6) and
                      (T.locate(q.x, q.y) is None or T.locate(q.x, q.y)[2] > WALL_T + 0.3)
                      for q in (pa, pb, (pa + pb) * 0.5))
            if okk:
                rbox(S_, k, ua, ub, CHAMBER - 0.3, CHAMBER + 0.02, 11.0, 11.5)


# =============================================================================
# asamblarea
# =============================================================================

def scatter(L_, sites, n_orange, n_green, seed):
    """`scatter_lichen` cu filtru: nicio pata in tub."""
    rnd = lcg(seed)
    areas = [max((s[1] - s[0]) * (s[3] - s[2]), 1e-6) for s in sites]
    tot = sum(areas)
    kinds = ["o"] * n_orange + ["g"] * n_green
    for i in range(len(kinds) - 1, 0, -1):
        j = int(rnd() * (i + 1))
        kinds[i], kinds[j] = kinds[j], kinds[i]
    for i, kind in enumerate(kinds):
        r, acc, site = rnd() * tot, 0.0, sites[-1]
        for s, a in zip(sites, areas):
            acc += a
            if r <= acc:
                site = s
                break
        x0, x1, y0, y1, z = site
        w, d = x1 - x0, y1 - y0
        rw = min(d * 0.40, 0.09 + 0.14 * rnd())
        ru = min(w * 0.40, rw * (1.6 + 1.8 * rnd()), 0.5)
        if kind == "g":
            ru, rw = min(ru * 1.15, w * 0.42), min(rw * 1.1, d * 0.42)
        mx, my = ru * 1.15, rw * 1.15
        if w < 2 * mx or d < 2 * my:
            continue
        cx = x0 + mx + (w - 2 * mx) * rnd()
        cy = y0 + my + (d - 2 * my) * rnd()
        if in_K(cx, cy, z) or in_K(cx + ru, cy, z) or in_K(cx - ru, cy, z) or in_K(cx, cy + rw, z) or in_K(cx, cy - rw, z):
            continue
        slot = ANK_LICHEN_ORANGE if kind == "o" else ANK_LICHEN_GREEN
        lichen_spot(L_, (cx, cy, z), ru, rw, 0.028, slot, yaw_deg=0.0, seed=seed + i)


def _tris(b):
    return sum(len(f.verts) - 2 for f in b.bm.faces)


def build_temple():
    S_, L_, G_, Br = Builder(), Builder(), Builder(), Builder()
    tally = [0]

    def stage(name):
        t = _tris(S_)
        print("  triunghiuri %-28s %7d" % (name, t - tally[0]))
        tally[0] = t
    sites, streaks, tube_lich = [], [], []
    make_cutters()

    # --- 1. masivul ingropat (z 0..3) + talpile pavilioanelor de N / S ----------------
    bx(S_, -HALF, HALF, -HALF, HALF, 0.0, Z_L1)
    bx(S_, -13.0, 13.0, HALF - 0.1, 54.6, 0.0, Z_L1)
    bx(S_, -13.0, 13.0, -54.6, -HALF + 0.1, 0.0, Z_L1)
    # stilobatul vizibil (3,4 .. 4,1) pe tot conturul, in doua trepte
    def stylobate(b):
        bx(b, -HALF, HALF, -HALF, HALF, 3.35, 3.75)
        bx(b, -HALF + 0.6, HALF - 0.6, -HALF + 0.6, HALF - 0.6, 3.75, 4.1)
    carved(S_, stylobate)
    # curtea dintre galeria exterioara si terasa a doua: dale (sub cota soselei)
    for (x0, x1, y0, y1) in ((-44.6, 44.6, 36.0, 44.6), (-44.6, 44.6, -44.6, -36.0),
                             (-44.6, -36.0, -36.0, 36.0), (36.0, 44.6, -36.0, 36.0)):
        bx(S_, x0, x1, y0, y1, 3.55, 3.72)

    stage('masiv+stilobat+curte')
    # --- 2. galeria exterioara (inel, axa 47,5) cu pavilioanele de intrare --------------
    PROF1 = [(3.7, 0.20), (3.8, 0.62), (2.9, 1.40), (2.0, 2.05), (1.0, 2.55), (0.35, 2.75)]
    SHR1 = [0.0, 0.1, 0.8, 1.5, 2.1, 2.5]
    ring_gallery(S_, G_, sites, streaks, 47.5, 45.0, 46.5, 50.0, 4.1, 8.6, PROF1, SHR1, 3.3, 3.6, 100,
                 gap_half=12.4)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx_, cy_ = sx * 47.5, sy * 47.5
            bx(S_, cx_ - 3.4, cx_ + 3.4, cy_ - 3.4, cy_ + 3.4, 4.1, 9.0)
            wall_faces(S_, cx_ - 3.4, cx_ + 3.4, cy_ - 3.4, cy_ + 3.4, 4.1, 9.0, ["+y", "-y", "+x", "-x"],
                       ch=1.2, bw=2.4, seed=77 + sx + 2 * sy)
            bx(S_, cx_ - 3.6, cx_ + 3.6, cy_ - 3.6, cy_ + 3.6, 9.0, 9.45)
            for i, hh in enumerate((2.6, 1.8, 1.1, 0.5)):
                bx(S_, cx_ - hh, cx_ + hh, cy_ - hh, cy_ + hh, 9.45 + 1.1 * i, 9.45 + 1.1 * (i + 1))
            sites.append((cx_ - 3.6, cx_ + 3.6, cy_ - 3.6, cy_ + 3.6, 9.45))
    # pavilioanele: fata pe capacele tubului (V, N) si oglinda lor (E, S)
    front_w = -T.c[0].x                  # 51,66
    front_n = T.c[-1].y                  # 54,5
    pavilion(S_, G_, sites, streaks, 1, front_w, True)
    pavilion(S_, G_, sites, streaks, 0, front_n, True)
    pavilion(S_, G_, sites, streaks, 3, front_w, False)
    pavilion(S_, G_, sites, streaks, 2, front_n, False)

    stage('galeria ext.+pavilioane')
    # --- 3. terasa a doua (z 3 .. 8, +-36) ----------------------------------------------
    t2 = [(Z_L1, 4.7, 36.0), (4.7, 6.4, 34.9), (6.4, Z_T2, 33.8)]
    for i, (z0, z1, h) in enumerate(t2):
        carved(S_, lambda b, z0=z0, z1=z1, h=h: bx(b, -h, h, -h, h, z0, z1))
        filtered(S_, lambda b, z0=z0, z1=z1, h=h, i=i: wall_faces(
            b, -h, h, -h, h, max(z0, 3.6), z1, ["+y", "-y", "+x", "-x"], ch=0.85, bw=2.8, seed=40 + i, proud=0.05))
        nxt = t2[i + 1][2] if i + 1 < len(t2) else 30.6
        for (x0, x1, y0, y1) in ((-h, h, nxt, h), (-h, h, -h, -nxt), (-h, -nxt, -nxt, nxt), (nxt, h, -nxt, nxt)):
            sites.append((x0 + 0.1, x1 - 0.1, y0 + 0.1, y1 - 0.1, z1))

    stage('terasa a doua')
    # --- 4. galeria de sus (inel, axa 26) si turnurile de colt ---------------------------
    PROF2 = [(4.1, 0.20), (4.15, 0.65), (3.15, 1.35), (2.2, 1.95), (1.15, 2.40), (0.4, 2.6)]
    SHR2 = [0.0, 0.1, 0.7, 1.3, 1.8, 2.1]
    ring_gallery(S_, G_, sites, streaks, CORNER, 24.4, 25.8, 29.4, Z_T2, Z_T2 + 3.4, PROF2, SHR2, 2.5, 4.9, 200)
    ZCP = Z_T2 + 4.2
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx_, cy_ = sx * CORNER, sy * CORNER
            bx(S_, cx_ - 4.9, cx_ + 4.9, cy_ - 4.9, cy_ + 4.9, Z_T2, ZCP)
            wall_faces(S_, cx_ - 4.9, cx_ + 4.9, cy_ - 4.9, cy_ + 4.9, Z_T2, ZCP, ["+y", "-y", "+x", "-x"],
                       ch=1.1, bw=2.4, seed=90 + sx + 2 * sy)
            bx(S_, cx_ - 5.15, cx_ + 5.15, cy_ - 5.15, cy_ + 5.15, ZCP, ZCP + 0.4)
            sites.append((cx_ - 5.1, cx_ + 5.1, cy_ - 5.1, cy_ + 5.1, ZCP + 0.4))
            for dx in (-1, 1):
                for dy in (-1, 1):
                    c = Vector((cx_ + dx * 4.95, cy_ + dy * 4.95, ZCP + 0.4))
                    pts = [c + Vector((a * 0.25, b_ * 0.25, 0.0)) for a in (-1, 1) for b_ in (-1, 1)]
                    pts += [c + Vector((a * 0.12, b_ * 0.12, 1.0)) for a in (-1, 1) for b_ in (-1, 1)]
                    hull(S_, pts, ST)
            tower(S_, cx_, cy_, ZCP + 0.4, 4.75, 1.2,
                  [(5.25, 2.9), (4.6, 2.7), (4.0, 2.5), (3.4, 2.3), (2.75, 2.1)], TOP_K, 2.25)

    stage('galeria de sus+turnuri colt')
    # --- 5. platforma centrala, blocul sanctuarului, turnul central -----------------------
    cen = [(Z_T2, 10.0, 16.0), (10.0, 12.0, 14.6), (12.0, Z_CEN, 13.2)]
    for i, (z0, z1, h) in enumerate(cen):
        carved(S_, lambda b, z0=z0, z1=z1, h=h: bx(b, -h, h, -h, h, z0, z1))
        filtered(S_, lambda b, z0=z0, z1=z1, h=h, i=i: wall_faces(
            b, -h, h, -h, h, z0, z1, ["+y", "-y", "+x", "-x"], ch=1.0, bw=2.6, seed=120 + i))
    sites.append((-16.0, 16.0, -16.0, -14.7, 10.0))
    sites.append((14.7, 16.0, -14.7, 14.7, 10.0))
    carved(S_, lambda b: bx(b, -BLK, BLK, -BLK, BLK, Z_CEN, KTOP))
    filtered(S_, lambda b: wall_faces(b, -BLK, BLK, -BLK, BLK, Z_CEN, KTOP - 0.6, ["+y", "-y", "+x", "-x"],
                                      ch=1.1, bw=2.4, seed=140))
    carved(S_, lambda b: bx(b, -BLK - 0.4, BLK + 0.4, -BLK - 0.4, BLK + 0.4, KTOP - 0.6, KTOP))
    # porticuri cu fronton pe fetele de S si E ale blocului (V si N sunt in sala)
    for k in (2, 3):
        rbox(S_, k, -4.6, 4.6, BLK, BLK + 1.0, KTOP - 0.2, KTOP + 0.35)
        rgable(S_, k, 0.0, BLK - 0.4, BLK + 0.9, KTOP + 0.35, 4.8, KTOP + 4.6)
        rgable(S_, k, 0.0, BLK + 0.9, BLK + 1.15, KTOP + 0.35, 3.9, KTOP + 3.7)
    carved(S_, lambda b: bx(b, -BLK - 0.6, BLK + 0.6, -BLK - 0.6, BLK + 0.6, KTOP, KTOP + 0.5))
    sites.append((-BLK - 0.5, BLK + 0.5, -BLK - 0.5, -BLK + 0.6, KTOP + 0.5))
    sites.append((BLK - 0.6, BLK + 0.5, -BLK + 0.6, BLK - 0.6, KTOP + 0.5))
    tower(S_, 0.0, 0.0, KTOP + 0.5, 7.6, 0.8,
          [(7.4, 2.3), (6.6, 2.15), (5.8, 2.0), (5.0, 1.9), (4.2, 1.8)], TOP_C, 2.5, gables=3, cut=True)

    stage('platforma+bloc+turn central')
    # --- 6. navele (interior + exterior), navele false, sanctuarul, aripile ---------------
    Ti = Builder()
    build_interior(Ti, G_, Br)
    carve_islands(S_, Ti, BEAM_COLL)
    stage("interior (pereti+bolti)")
    Te = Builder()
    build_nave_exterior(Te, G_, streaks)
    carve_islands(S_, Te, BEAM_COLL)
    stage("navele: exterior+acoperis")
    build_ambulatory(S_, Br)
    stage("ambulatoriu")
    build_false_arm(S_, G_, streaks, 3)
    build_false_arm(S_, G_, streaks, 2)
    stage("navele false")
    sanctuary(S_, Br, sites)
    stage("sanctuar")
    wings = wings_and_naga(S_, L_)
    wings_detail(S_, wings)
    stage("aripi+naga")

    # --- 7. lichen si dare ------------------------------------------------------------------
    scatter(L_, sites, 95, 55, seed=41)
    rnd = lcg(53)
    for (tb, side, m0, m1, e, h, n, lmin, lmax) in [s for s in streaks if s[0] != "w"]:
        for _ in range(n):
            m = m0 + (m1 - m0) * rnd()
            p = tb.P(m, side, e, h)
            streak(G_, (p.x, p.y, p.z - 0.02), side_sign_frame_t(tb, m, side), 0.18 + 0.12 * rnd(),
                   lmin + (lmax - lmin) * rnd(), 0.025, ANK_STREAK)
    for (_, k, u0, u1, w, z_top, n, lmin, lmax) in [s for s in streaks if s[0] == "w"]:
        fr = fr_of(k)
        for _ in range(n):
            u = u0 + (u1 - u0) * rnd()
            p = fr.p(u, w, 0.0)
            if in_K(p.x, p.y, z_top - 0.5):
                continue
            streak(G_, (p.x, p.y, z_top - 0.02), 90.0 * k, 0.16 + 0.10 * rnd(),
                   lmin + (lmax - lmin) * rnd(), 0.025, ANK_STREAK)
    rl = lcg(77)
    for (tb, side, m0, m1, e0, e1, h) in tube_lich:
        nspots = int((m1 - m0) / 3.0)
        for _ in range(nspots):
            m = m0 + (m1 - m0) * rl()
            p = tb.P(m, side, (e0 + e1) * 0.5, h)
            lichen_spot(L_, (p.x, p.y, p.z), 0.12 + 0.2 * rl(), 0.10, 0.028,
                        ANK_LICHEN_GREEN if rl() < 0.6 else ANK_LICHEN_ORANGE,
                        yaw_deg=math.degrees(math.atan2(tb.tangent(m).y, tb.tangent(m).x)), seed=int(m * 10))

    for ob in list(CUT_COLL.objects):
        me = ob.data
        bpy.data.objects.remove(ob, do_unlink=True)
        bpy.data.meshes.remove(me)
    for c in (CUT_COLL, CHAMB_COLL, BEAM_COLL):
        bpy.data.collections.remove(c)
    print("  triunghiuri inainte de curatare: %d" % _tris(S_))
    cull_hidden(S_)
    print("  triunghiuri dupa curatare:       %d" % _tris(S_))
    return [to_object_keep(S_, "TempleDrive_Stone"), L_.to_object("TempleDrive_Lichen"),
            G_.to_object("TempleDrive_Streak"), Br.to_object("TempleDrive_Bronze")]


def side_sign_frame_t(tb, m, side):
    n = tb.normal(m, side)
    return math.degrees(math.atan2(-n.x, n.y))


# --- AO: peste AO-ul de raze, interiorul se intuneca spre bolta --------------------------
_bake_ao_rays = bake_ao


def _interior_shade(obj):
    me = obj.data
    ca = me.color_attributes.get("AO")
    if ca is None:
        return
    for i, v in enumerate(me.vertices):
        x, y, z = v.co
        f = 1.0
        if -60.0 < x < 12.0 and -12.0 < y < 62.0 and ROAD_Z - 0.6 < z < 26.0:
            r = T.locate(x, y)
            if r is not None and (r[2] < 1.6 or (r[1] > 0 and AMB_M[0] - 0.7 < r[0] < AMB_M[1] + 0.7
                                                and r[2] < AMB_E[1] + 0.9 and z < ROAD_Z + 11.0)):
                m = r[0]
                cb = cb_at(min(max(m, M_W), M_N))
                h = z - ROAD_Z
                t = min(max(h / (cb + VR), 0.0), 1.0)
                f = 0.95 - 0.40 * t ** 0.85
        rr = math.hypot(x, y)
        if rr < 4.7 and z < 5.4 and obj.name.endswith("_Stone") and (
                T.locate(x, y) is None or T.locate(x, y)[2] > WALL_T + 0.1):
            ca.data[i].color = (0.97, 0.97, 0.97, 1.0)      # discul si soclul: palide sub raza
            continue
        if f == 1.0 and abs(x) < CHAMBER + 0.1 and abs(y) < CHAMBER + 0.1 and z < SHAFT_TOP:
            f = 0.85 - 0.30 * min(max((z - 4.0) / 16.0, 0.0), 1.0)
        if f != 1.0:
            c = ca.data[i].color
            ca.data[i].color = (c[0] * f, c[1] * f, c[2] * f, 1.0)


def bake_ao(obj, **kw):
    r = _bake_ao_rays(obj, **kw)
    _interior_shade(obj)
    return r


def emit_drive():
    objs = build_temple()
    emit_angkor(objs, "structures/angkor_wat_drive.glb", AO_DRIVE, bevel=0.0,
                bevels={"_Lichen": 0.0, "_Streak": 0.0}, smooth_angle=55.0, anchor=(0.0, 0.0))
    clear_built()


print("tub: %d sectiuni, m %.2f .. %.2f; nasterile boltilor %s; arcada %s" %
      (T.n, M_W, M_N, ["%.2f" % c for c in G_CB], sorted(ARCADE)))
emit_drive()
report_angkor()
