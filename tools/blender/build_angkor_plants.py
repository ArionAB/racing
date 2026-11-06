"""Angkor -- val 4, grupul B: vegetatia mica (kit angkor_kit.md §1.7).

  angkor/plants/strangler_fig.glb     ficus care INFASOARA un zid de gresie de 5 m, ~10 m total
  angkor/plants/vine_strands.glb      6 suvite `Strand_0..5`, 3,0-4,5 m, originea in punctul de agatare
  angkor/plants/lotus_cluster.glb     lotusi pe apa, 1,5-3 m in plan, flori roz, <= 0,4 m peste apa
  angkor/plants/water_lily_pads.glb   nuferi cu crestatura, plati, <= 0,05 m peste apa

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_plants.py
`ANK_ONLY=<fig|vine|lotus|lily>` reface doar o piesa. Helperii portii-copac (`spline`,
`bx`, `wall_faces`) se INCARCA din `build_angkor_gates_w.py` (partea de dinaintea
`build_gopura`), nu se copiaza; `angkor_shapes.py` vine tot de acolo.

Axe: X latime, Y adancime, Z sus (Blender). Godot: Y = Z-ul de aici.

LISTA DE ELEMENTE, scrisa INAINTE de geometrie (decuparile din angkor_assets_v1):

strangler_fig -- ~10 m, zidul ~5 m:
  1. Zidul (Fig_Stone): corp 7,5 x 1,24 x 5,0 cu randuri de blocuri pe ambele fete si pe capete,
     capatul drept mai jos (3,3 m, ruina), cateva blocuri cazute la baza.
  2. Radacinile (Fig_Root, CORAL_SAND 19, AO cald): SECTIUNE ELIPTICA turtita (latime >> grosime)
     care urmareste PROFILUL zidului -- sol, fata -Y, coama, fata +Y, sol --, deci sunt lipite de
     zidit, nu tuburi. Putine si GROASE (3 pe fata din fata, 2 pe cea din spate), cateva SUBTIRI
     (legaturi laterale care trec de la una la alta), si radacini care se rasfira pe sol.
     Latimea si grosimea variaza pe traseu (evazate jos, ingustate spre varf).
  3. Trunchiul: sapte sfori impletite + miez, ridicandu-se de pe zid; 5 ramuri subtiri.
  4. Coronamentul (Fig_Leaves): mase de elipsoizi TROPICAL_GREEN 21 + ciorchini mai deschisi
     CACTUS_GREEN 12; cateva tufe pe coama zidului si pe sol (din crapaturi).

vine_strands -- sase radacini-nod, fiecare O SUVITA (un singur mesh), pe -Z, originea sus:
  Strand_0/2/4  lianele verzi: tulpina subtire + ciorchini de cate 1-3 frunze (romb pliat in V,
                8 triunghiuri, cu AMBELE fete) mai mari sus, mai mici spre varf
  Strand_1      doua radacini aeriene argintii RASUCITE una in alta, cu noduri
  Strand_3      o radacina argintie cu noduri si trei radacinite subtiri
  Strand_5      un evantai de trei fire argintii de lungimi diferite, cu un nod sus
  Bugetul: <= 300 tri pe suvita (vor fi ~150 de instante in MultiMesh).

lotus_cluster -- originea la cota apei:
  frunze rotunde asezate pe apa (disc usor concav, cu grosime), doua RIDICATE si inclinate pe
  tulpina; patru flori roz FLAMINGO_PINK 31 pe tulpini scurte (doua randuri de petale-romb pliate
  + capsula CACTUS_GREEN 12). Totul <= 0,4 m.

water_lily_pads -- 8 frunze plate, fiecare un disc cu CRESTATURA (pana decupata spre centru),
  centrul mai deschis (CACTUS_GREEN 12) si marginea TROPICAL_GREEN 21; <= 0,05 m.
"""

import math
import os
import bmesh
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
_gw = open(os.path.join(_here, "build_angkor_gates_w.py"), encoding="utf-8").read()
exec(compile(_gw[:_gw.index("def build_gopura")], "build_angkor_gates_w.py", "exec"))

ONLY = os.environ.get("ANK_ONLY", "")

PLANT_ROOT = CORAL_SAND         # 19: radacini, AO cald
ANK_ROOT = PLANT_ROOT
PLANT_GREEN = TROPICAL_GREEN    # 21
PLANT_LIGHT = CACTUS_GREEN      # 12
PLANT_PINK = FLAMINGO_PINK      # 31


# --- ajutoare comune ---------------------------------------------------------

def face_slot(b, verts, slot):
    f = b.bm.faces.new(verts)
    f[b.slot] = slot
    return f


def folded_leaf(b, base, direction, length, width, slot, fold=0.16, up=(0.0, 0.0, 1.0),
                belly=0.42, thick=0.012, fold_sign=1.0):
    """Frunza/petala: romb pliat in V, INCHIS (6 varfuri, 8 triunghiuri) deci se vede din
    ambele parti. Nervura (base->tip) e coama, marginile cad cu `fold * width`."""
    base = Vector(base)
    d = Vector(direction).normalized()
    side = d.cross(Vector(up))
    if side.length < 1e-4:
        side = d.cross(Vector((1.0, 0.0, 0.0)))
    side.normalize()
    n = d.cross(side).normalized() * fold_sign
    vein = base + d * (length * belly)
    drop = n * (-width * fold)
    B = b.bm.verts.new(base)
    T = b.bm.verts.new(base + d * length)
    L = b.bm.verts.new(vein + side * (width * 0.5) + drop)
    R = b.bm.verts.new(vein - side * (width * 0.5) + drop)
    Mt = b.bm.verts.new(vein + n * thick)
    Mb = b.bm.verts.new(vein - n * thick)
    for a, c in ((L, T), (T, R), (R, B), (B, L)):
        face_slot(b, (a, c, Mt), slot)
        face_slot(b, (c, a, Mb), slot)


def dish(b, center, R, slot_out, slot_in=None, rim_up=0.0, thick=0.02, seg=14, notch=0.0,
         notch_at=0.0, rot=None, wave=0.0, phase=0.0):
    """Disc usor concav, cu GROSIME (corp inchis): `rim_up` = cat sta marginea peste centru
    (negativ = cade), `notch` (grade) = pana decupata pana la centru, cu axa la `notch_at`.
    Inelul interior (0,55 R) poate avea alt slot (`slot_in`): centrul mai deschis."""
    slot_in = slot_out if slot_in is None else slot_in
    rot = Matrix.Identity(3) if rot is None else rot
    c0 = Vector(center)
    open_arc = notch > 0.5
    if open_arc:
        angs = [math.radians(notch_at + notch * 0.5 + (360.0 - notch) * k / seg) for k in range(seg + 1)]
    else:
        angs = [2.0 * math.pi * k / seg for k in range(seg)]
    n = len(angs)

    def pt(r, a, top):
        zt = rim_up * (r / R) ** 2 + wave * math.sin(3.0 * a + phase) * (r / R) ** 2
        z = zt if top else zt - thick * (1.0 - 0.45 * r / R)
        return c0 + rot @ Vector((r * math.cos(a), r * math.sin(a), z))

    V = b.bm.verts
    Ct, Cb = V.new(pt(0.0, 0.0, True)), V.new(pt(0.0, 0.0, False))
    rin = [V.new(pt(0.55 * R, a, True)) for a in angs]
    rout = [V.new(pt(R, a, True)) for a in angs]
    bin_ = [V.new(pt(0.55 * R, a, False)) for a in angs]
    bout = [V.new(pt(R, a, False)) for a in angs]
    last = n - 1 if open_arc else n
    for i in range(last):
        j = (i + 1) % n
        face_slot(b, (Ct, rin[i], rin[j]), slot_in)
        face_slot(b, (rin[i], rout[i], rout[j], rin[j]), slot_out)
        face_slot(b, (Cb, bin_[j], bin_[i]), slot_out)
        face_slot(b, (bin_[i], bin_[j], bout[j], bout[i]), slot_out)
        face_slot(b, (rout[i], bout[i], bout[j], rout[j]), slot_out)
    if open_arc:
        for k in (0, n - 1):
            face_slot(b, (Ct, Cb, bin_[k], rin[k]), slot_out)
            face_slot(b, (rin[k], bin_[k], bout[k], rout[k]), slot_out)


def tube(b, pts, radii, slot, segments=5):
    b.taper_sweep([tuple(p) for p in pts], radii, slot, segments=segments)


def lerp_path(pts, t):
    """Punct pe polilinia `pts` la fractia de lungime `t` (0..1)."""
    pts = [Vector(p) for p in pts]
    ls = [(pts[i + 1] - pts[i]).length for i in range(len(pts) - 1)]
    target = t * sum(ls)
    for i, ln in enumerate(ls):
        if target <= ln or i == len(ls) - 1:
            u = 0.0 if ln < 1e-9 else min(target / ln, 1.0)
            return pts[i].lerp(pts[i + 1], u)
        target -= ln
    return pts[-1]


def emit_plain(objs, path, ao_for, smooth=60.0, tint=None, anchor=None):
    """Finish pe fiecare nod si export, FARA recentrare: originea ramane unde a construit-o
    piesa (suvite: punctul de agatare; lotus: cota apei). `anchor` (x, y, z) o muta."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    if anchor is not None:
        for o in objs:
            for v in o.data.vertices:
                v.co -= Vector(anchor)
    total, per = 0, {}
    for o in objs:
        st = finish(o, bevel=0.0, ao=ao_for(o), origin=None, smooth_angle=smooth)
        for suf, t in (tint or {}).items():
            if o.name.endswith(suf):
                ca = o.data.color_attributes["AO"]
                for d in ca.data:
                    v = d.color[0]
                    d.color = (v ** t[0], v ** t[1], v ** t[2], 1.0)
        total += st["tris"]
        per[o.name] = st["tris"]
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "angkor/" + path)
    ANK_RESULTS.append((path, total, dims, per, sz / 1024.0))
    return total


# =============================================================================
# 1. strangler_fig
# =============================================================================

FIG_T = 0.67        # jumatatea grosimii zidului, cu blocurile in relief
FIG_H = 5.0
FIG_X0 = 0.3        # axa trunchiului pe zid

AO_FIG = dict(samples=16, dist=1.6, gradient="vertical", low=0.52, high=1.0,
              power=0.9, floor=0.28, strength=1.3, z_range=(0.0, 10.6))


class WallProfile:
    """Profilul transversal al zidului in (y, z): sol -Y, racord concav, fata -Y, colt
    rotunjit, coama, colt, fata +Y, racord, sol +Y. Fiecare esantion poarta lungimea de arc
    `s` si normala spre exterior; radacinile se descriu in (x, s) si se lipesc de el."""

    def __init__(self, T=FIG_T, H=FIG_H, r=0.26, g=4.2, f=0.34, step=0.05):
        P = []

        def line(p0, p1, nrm):
            ln = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
            k = max(1, int(ln / step))
            for i in range(k):
                u = i / float(k)
                P.append((p0[0] + (p1[0] - p0[0]) * u, p0[1] + (p1[1] - p0[1]) * u, nrm[0], nrm[1]))

        def arc(cy, cz, rad, a0, a1, concave):
            k = max(3, int(abs(a1 - a0) * rad / step))
            for i in range(k):
                a = math.radians(a0 + (a1 - a0) * i / float(k))
                ca, sa = math.cos(a), math.sin(a)
                nrm = (-ca, -sa) if concave else (ca, sa)
                P.append((cy + rad * ca, cz + rad * sa, nrm[0], nrm[1]))

        line((-T - g, 0.0), (-T - f, 0.0), (0.0, 1.0))
        arc(-T - f, f, f, -90.0, 0.0, True)
        line((-T, f), (-T, H - r), (-1.0, 0.0))
        arc(-T + r, H - r, r, 180.0, 90.0, False)
        line((-T + r, H), (T - r, H), (0.0, 1.0))
        arc(T - r, H - r, r, 90.0, 0.0, False)
        line((T, H - r), (T, f), (1.0, 0.0))
        arc(T + f, f, f, 180.0, 270.0, True)
        line((T + f, 0.0), (T + g, 0.0), (0.0, 1.0))
        P.append((T + g, 0.0, 0.0, 1.0))
        self.P = P
        self.S = [0.0]
        for a, c in zip(P[:-1], P[1:]):
            self.S.append(self.S[-1] + math.hypot(c[0] - a[0], c[1] - a[1]))

    def s_of(self, y, z):
        best, bs = 1e9, 0.0
        for p, s in zip(self.P, self.S):
            d = (p[0] - y) ** 2 + (p[1] - z) ** 2
            if d < best:
                best, bs = d, s
        return bs

    def at(self, s):
        s = max(0.0, min(s, self.S[-1]))
        lo, hi = 0, len(self.S) - 1
        while hi - lo > 1:
            mid = (lo + hi) // 2
            if self.S[mid] <= s:
                lo = mid
            else:
                hi = mid
        u = (s - self.S[lo]) / max(self.S[hi] - self.S[lo], 1e-9)
        a, c = self.P[lo], self.P[hi]
        ny, nz = a[2] + (c[2] - a[2]) * u, a[3] + (c[3] - a[3]) * u
        ln = math.hypot(ny, nz) or 1.0
        return (a[0] + (c[0] - a[0]) * u, a[1] + (c[1] - a[1]) * u, ny / ln, nz / ln)


def fig_root(b, prof, ctrl, widths, thicks, sub=5, segments=8, seed=0, sink=0.30):
    """Radacina TURTITA lipita de zid. `ctrl` = [(x, y, z)] puncte PE profil; sectiunea e o
    elipsa (semi-axa mare `w` PE suprafata, mica `h` spre exterior), centrul la `sink * h`
    deasupra suprafetei. Latimea si grosimea vin din `widths` / `thicks` (spline)."""
    rnd = lcg(seed + 5)
    p2 = [(x, prof.s_of(y, z), 0.0) for (x, y, z) in ctrl]
    path, ww = spline(p2, widths, sub)
    _, hh = spline(p2, thicks, sub)
    centers, norms = [], []
    for (x, s, _), w, h in zip(path, ww, hh):
        y, z, ny, nz = prof.at(s)
        off = sink * h + 0.02 * (rnd() - 0.5)
        centers.append(Vector((x, y + ny * off, z + nz * off)))
        norms.append(Vector((0.0, ny, nz)))
    n = len(centers)
    rings = []
    for i in range(n):
        t = (centers[min(i + 1, n - 1)] - centers[max(i - 1, 0)])
        if t.length < 1e-6:
            t = Vector((1.0, 0.0, 0.0))
        t.normalize()
        side = t.cross(norms[i])
        if side.length < 1e-4:
            side = Vector((1.0, 0.0, 0.0))
        side.normalize()
        nn = side.cross(t).normalized()
        if nn.dot(norms[i]) < 0:
            nn = -nn
        w, h = max(ww[i], 0.004), max(hh[i], 0.004)
        ring = []
        for k in range(segments):
            a = 2.0 * math.pi * k / segments
            ring.append(b.bm.verts.new(centers[i] + side * (w * math.cos(a)) + nn * (h * math.sin(a))))
        rings.append(ring)
    for lo, hi in zip(rings, rings[1:]):
        for i in range(segments):
            j = (i + 1) % segments
            b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    b.bm.faces.new(tuple(reversed(rings[0])))
    b.bm.faces.new(tuple(rings[-1]))
    for ring in rings:
        for v in ring:
            for f in v.link_faces:
                f[b.slot] = PLANT_ROOT


def build_fig():
    S, R, C = Builder(), Builder(), Builder()
    rnd = lcg(91)
    prof = WallProfile()
    T, H = 0.62, FIG_H

    # --- 1. zidul: corpul principal + capatul drept ruinat -----------------------
    bx(S, -3.75, 2.7, -T, T, 0.0, H)
    wall_faces(S, -3.75, 2.7, -T, T, 0.0, H, ["+y", "-y", "-x"], ch=0.7, bw=1.05, seed=3)
    bx(S, 2.7, 3.75, -T, T, 0.0, 3.3)
    wall_faces(S, 2.7, 3.75, -T, T, 0.0, 3.3, ["+y", "-y", "+x"], ch=0.7, bw=0.9, seed=9)
    # trepte ruinate pe capatul drept (blocuri lipsa pe coama)
    bx(S, 3.0, 3.75, -T, T, 3.3, 3.75)
    bx(S, 3.45, 3.75, -T + 0.1, T - 0.1, 3.75, 4.15)
    # blocuri cazute la baza, in afara radacinilor
    for (cx, cy, sz, yaw) in ((3.5, 1.3, (0.9, 0.7, 0.55), 24), (3.9, -1.2, (0.8, 0.65, 0.5), -30),
                              (-3.9, 1.5, (0.8, 0.6, 0.45), 40), (-4.2, -1.1, (0.7, 0.55, 0.42), 12),
                              (3.2, -2.1, (0.6, 0.5, 0.4), 55), (-3.4, 2.2, (0.65, 0.5, 0.38), -22)):
        S.box((cx, cy, sz[2] * 0.5), sz, ANK_STONE, rotation=Matrix.Rotation(math.radians(yaw), 3, "Z"))

    # --- 2. radacinile turtite, lipite de zid -----------------------------------
    TT = FIG_T          # fata zidului (cu blocuri)
    x0 = FIG_X0

    def face_root(side, pts, ww, hh, seed, sub=5):
        sg = 1.0 if side > 0 else -1.0
        ctrl = []
        for (x, kind, v) in pts:
            if kind == "top":      # v = y pe coama
                ctrl.append((x, sg * v, H))
            elif kind == "face":   # v = z pe fata
                ctrl.append((x, sg * TT, v))
            else:                  # "ground": v = distanta de zid
                ctrl.append((x, sg * (TT + v), 0.0))
        k = 0.52 if ww[0] > 0.4 else 1.0
        fig_root(R, prof, ctrl, [w * k for w in ww], hh, sub=sub, seed=seed)
        if ww[0] > 0.4:        # fratii mai subtiri, decalati: fasciculul de radacini din desen
            for j, dx in enumerate((-0.32, 0.30)):
                c2 = [(x + dx * (0.6 + 0.4 * (i > 2)), y, z) for i, (x, y, z) in enumerate(ctrl)]
                fig_root(R, prof, c2, [w * 0.30 for w in ww], [h * 0.75 for h in hh], sub=sub, seed=seed + 20 + j)

    # fata +Y (spre drum): trei groase, legaturi subtiri
    face_root(1, [(x0, "top", 0.0), (0.7, "top", 0.5), (0.95, "face", 4.3), (1.25, "face", 3.2), (1.15, "face", 2.0),
                  (1.55, "face", 0.9), (2.1, "ground", 0.7), (2.8, "ground", 1.9), (3.3, "ground", 3.1)],
              [0.95, 0.80, 0.70, 0.66, 0.62, 0.64, 0.52, 0.26, 0.07],
              [0.30, 0.24, 0.20, 0.18, 0.17, 0.17, 0.14, 0.09, 0.03], 1)
    face_root(1, [(x0 - 0.1, "top", 0.0), (-0.15, "top", 0.5), (-0.45, "face", 4.4), (-0.7, "face", 3.1),
                  (-0.95, "face", 1.8), (-1.5, "face", 0.7), (-2.0, "ground", 0.8), (-2.6, "ground", 2.0),
                  (-3.0, "ground", 3.0)],
              [0.85, 0.74, 0.64, 0.60, 0.56, 0.56, 0.42, 0.22, 0.06],
              [0.28, 0.22, 0.19, 0.17, 0.16, 0.15, 0.12, 0.08, 0.03], 2)
    face_root(1, [(x0 + 0.1, "top", 0.0), (0.3, "top", 0.45), (0.35, "face", 4.5), (0.5, "face", 3.0),
                  (0.35, "face", 1.7), (0.55, "face", 0.8), (0.5, "ground", 0.8), (0.55, "ground", 2.0),
                  (0.8, "ground", 3.2)],
              [0.50, 0.42, 0.36, 0.34, 0.34, 0.40, 0.34, 0.18, 0.05],
              [0.20, 0.16, 0.14, 0.13, 0.13, 0.14, 0.11, 0.07, 0.025], 3)
    # legaturi laterale subtiri (trec de la o radacina groasa la alta)
    face_root(1, [(-0.8, "face", 3.0), (-0.2, "face", 2.75), (0.4, "face", 2.9), (1.0, "face", 2.4)],
              [0.12, 0.10, 0.10, 0.08], [0.06, 0.05, 0.05, 0.04], 4, sub=6)
    face_root(1, [(-1.2, "face", 1.5), (-0.5, "face", 1.2), (0.45, "face", 1.45), (1.1, "face", 1.0)],
              [0.10, 0.09, 0.09, 0.07], [0.05, 0.045, 0.045, 0.035], 5, sub=6)
    # radacini subtiri la capete, de pe coama spre colturi
    face_root(1, [(-1.4, "top", 0.2), (-1.9, "face", 4.4), (-2.1, "face", 3.0), (-2.45, "face", 1.4),
                  (-2.9, "ground", 0.6), (-3.4, "ground", 1.8)],
              [0.30, 0.26, 0.22, 0.20, 0.14, 0.05], [0.12, 0.10, 0.09, 0.08, 0.06, 0.025], 6)
    face_root(1, [(1.6, "top", 0.2), (2.0, "face", 4.4), (2.15, "face", 2.9), (2.3, "face", 1.2),
                  (2.9, "ground", 0.6), (3.3, "ground", 1.5)],
              [0.28, 0.24, 0.2, 0.18, 0.12, 0.05], [0.11, 0.09, 0.08, 0.07, 0.05, 0.025], 7)
    # fata -Y (spatele): doua groase + subtiri
    face_root(-1, [(x0 + 0.2, "top", 0.0), (0.6, "top", 0.5), (0.9, "face", 4.4), (0.7, "face", 3.0),
                   (1.0, "face", 1.7), (1.5, "face", 0.8), (1.9, "ground", 0.8), (2.4, "ground", 2.0),
                   (2.7, "ground", 3.0)],
              [0.80, 0.70, 0.62, 0.58, 0.60, 0.56, 0.44, 0.22, 0.06],
              [0.26, 0.21, 0.18, 0.17, 0.17, 0.15, 0.12, 0.08, 0.03], 8)
    face_root(-1, [(x0 - 0.2, "top", 0.0), (-0.2, "top", 0.5), (-0.6, "face", 4.4), (-0.4, "face", 3.0),
                   (-0.9, "face", 1.6), (-1.3, "face", 0.7), (-1.6, "ground", 0.7), (-2.3, "ground", 1.9),
                   (-2.7, "ground", 3.0)],
              [0.75, 0.66, 0.58, 0.54, 0.54, 0.50, 0.40, 0.20, 0.06],
              [0.25, 0.20, 0.17, 0.16, 0.16, 0.14, 0.11, 0.07, 0.03], 9)
    face_root(-1, [(-1.0, "face", 2.6), (-0.2, "face", 2.2), (0.6, "face", 2.5), (1.4, "face", 1.7)],
              [0.11, 0.10, 0.10, 0.08], [0.055, 0.05, 0.05, 0.04], 10, sub=6)
    face_root(-1, [(1.8, "top", 0.2), (2.2, "face", 4.4), (2.2, "face", 3.0), (2.5, "face", 1.2), (3.0, "ground", 0.6)],
              [0.26, 0.22, 0.18, 0.14, 0.05], [0.1, 0.09, 0.08, 0.06, 0.025], 11)
    # clamp la sol: partea din spate a elipsei nu coboara sub cota 0
    for v in R.bm.verts:
        v.co.z = max(v.co.z, 0.0)

    # --- 3. trunchiul: sapte sfori impletite + miez, plecand de pe coama zidului ---
    zs_ = [H + 0.05, H + 0.95, H + 2.0, H + 3.0, H + 3.9]
    rr_ = [0.85, 0.72, 0.56, 0.40, 0.26]
    tr_ = [0.40, 0.36, 0.32, 0.26, 0.20]
    core, core_r = spline([(x0, 0.0, H - 0.1), (x0 + 0.05, 0.0, H + 1.5), (x0 + 0.1, 0.0, H + 3.0), (x0 + 0.1, 0.0, H + 3.9)],
                          [0.9, 0.75, 0.55, 0.3], sub=3)
    R.taper_sweep([tuple(p) for p in core], core_r, ANK_ROOT, segments=10)
    for k in range(7):
        a0 = 2.0 * math.pi * (k + 0.2 * (k % 2)) / 7.0
        pts = []
        for i in range(5):
            a = a0 + 0.22 * i
            pts.append((x0 + 0.02 * i + rr_[i] * math.cos(a) * 1.1, rr_[i] * math.sin(a) * 0.9, zs_[i]))
        pp, rr2 = spline(pts, tr_, sub=3)
        R.taper_sweep([tuple(p) for p in pp], rr2, ANK_ROOT, segments=8)
    # soclul evazat: piciorul trunchiului se aseaza pe coama
    R.frustum((x0, 0.0, H + 0.25), 0.82, 0.62, 0.5, ANK_ROOT, segments=12)
    top = (x0 + 0.1, 0.0, H + 3.8)
    branches = [([top, (x0 + 0.6, 0.4, H + 4.0), (x0 + 1.0, 0.6, H + 4.2)], [0.2, 0.14, 0.07]),
                ([top, (x0 - 0.6, -0.3, H + 4.0), (x0 - 1.0, -0.5, H + 4.2)], [0.2, 0.14, 0.07]),
                ([top, (x0 + 0.3, -0.6, H + 4.0), (x0 + 0.5, -0.9, H + 4.1)], [0.18, 0.12, 0.06]),
                ([top, (x0 - 0.2, 0.6, H + 4.0), (x0 - 0.4, 1.0, H + 4.1)], [0.18, 0.12, 0.06]),
                ([top, (x0 + 0.1, 0.0, H + 4.2), (x0 + 0.2, 0.1, H + 4.4)], [0.18, 0.12, 0.06])]
    for pts, rr3 in branches:
        pp, rr2 = spline(pts, rr3, sub=3)
        R.taper_sweep([tuple(p) for p in pp], rr2, ANK_ROOT, segments=7)

    # --- 4. coronamentul + tufele ------------------------------------------------
    ident = Matrix.Identity(3)
    zc = H + 2.7
    masses = [(x0 + 0.1, 0.0, zc + 0.9, 1.9, 1.7, 0.85, 0), (x0 + 1.5, 0.8, zc + 0.3, 1.3, 1.2, 0.7, 0),
              (x0 - 1.4, -0.6, zc + 0.4, 1.3, 1.2, 0.7, 0), (x0 + 0.7, -1.3, zc + 0.1, 1.1, 1.0, 0.6, 0),
              (x0 - 0.6, 1.4, zc + 0.2, 1.1, 1.0, 0.6, 0), (x0 + 0.2, 0.2, zc + 1.4, 1.2, 1.1, 0.6, 1),
              (x0 + 1.1, -0.2, zc + 1.0, 0.8, 0.8, 0.5, 1), (x0 - 0.9, 0.2, zc + 1.0, 0.8, 0.8, 0.5, 1),
              (x0 + 2.0, 0.3, zc - 0.2, 0.7, 0.7, 0.4, 1)]
    for (mx, my, mz, ru, rv, rz, light) in masses:
        for j in range(3):
            ox, oy, oz = (rnd() - 0.5) * ru * 0.9, (rnd() - 0.5) * rv * 0.9, (rnd() - 0.4) * rz * 0.8
            s = 0.6 + 0.25 * rnd()
            ellipsoid(C, (mx + ox, my + oy, mz + oz), (ru * s * 0.85, rv * s * 0.85, rz * s * 0.7),
                      PLANT_LIGHT if light else PLANT_GREEN, ident, 10, 6)
    # tufe din crapaturi: pe coama zidului (departe de trunchi) si la baza radacinilor
    tufts = [(-2.6, 0.1, H, 0.55, 0.45), (-1.2, -0.2, H, 0.4, 0.32), (2.0, 0.15, H, 0.45, 0.35),
             (3.45, 0.1, 3.3, 0.45, 0.36), (-3.2, 0.9, 0.0, 0.5, 0.4), (-2.2, -2.4, 0.0, 0.45, 0.36),
             (3.0, 2.2, 0.0, 0.5, 0.4), (1.6, 3.0, 0.0, 0.4, 0.32), (-0.4, -3.1, 0.0, 0.45, 0.35),
             (1.9, -2.9, 0.0, 0.4, 0.3)]
    for (tx, ty, tz, rr, rz) in tufts:
        for j in range(3):
            s = 0.7 + 0.3 * rnd()
            ellipsoid(C, (tx + (rnd() - 0.5) * rr, ty + (rnd() - 0.5) * rr, tz + rz * 0.35),
                      (rr * s * 1.1, rr * s * 1.1, rz * s * 0.6), PLANT_LIGHT if j == 1 else PLANT_GREEN, ident, 8, 5)
    return [S.to_object("Fig_Stone"), R.to_object("Fig_Root"), C.to_object("Fig_Leaves")]


def emit_fig():
    objs = build_fig()
    emit_angkor(objs, "plants/strangler_fig.glb", AO_FIG, bevel=0.0, smooth_angle=60.0,
                anchor=(0.0, 0.0), ao_tint={"_Root": (1.0, 1.3, 1.7)})
    clear_built()


# =============================================================================
# 2. vine_strands
# =============================================================================

def liana(b, L, seed, clusters, leaf_len, sway=0.05, hmix=0.38):
    """Tulpina subtire cu ciorchini de frunze: `clusters` = [(t, n)] (fractia de lungime, nr)."""
    rnd = lcg(seed)
    ph = rnd() * 6.28
    n = 9
    pts = []
    for i in range(n):
        t = i / float(n - 1)
        pts.append(Vector((sway * math.sin(t * 5.0 + ph) * t ** 0.6, sway * 0.7 * math.cos(t * 4.2 + ph * 1.3) * t, -L * t)))
    rad = [0.030, 0.028, 0.026, 0.024, 0.022, 0.019, 0.016, 0.011, 0.0]
    tube(b, pts, rad, PLANT_GREEN, segments=4)
    for (t, cnt) in clusters:
        base = lerp_path(pts, t)
        az0 = rnd() * 6.28
        for j in range(cnt):
            az = az0 + j * 2.0 * math.pi / cnt + (rnd() - 0.5) * 0.7
            ll = leaf_len * (1.0 - 0.5 * t) * (0.85 + 0.3 * rnd())
            d = Vector((math.cos(az) * hmix, math.sin(az) * hmix, -0.8 + 0.2 * rnd()))
            folded_leaf(b, base, d, ll, ll * 0.95, PLANT_GREEN, fold=0.22, belly=0.45)


def knotted_path(L, step, amp, ph, offset=(0.0, 0.0)):
    n = max(3, int(round(L / step)) + 1)
    pts = []
    for i in range(n):
        t = i / float(n - 1)
        pts.append(Vector((offset[0] + amp * math.sin(t * 6.0 + ph) * t ** 0.5,
                           offset[1] + amp * 0.8 * math.cos(t * 5.0 + ph * 1.7) * t, -L * t)))
    return pts


def knot_radii(n, r0, knot_every=3, knot_gain=1.6, flare=1.5, phase=1):
    out = []
    for i in range(n):
        t = i / float(n - 1)
        r = r0 * (1.0 - 0.45 * t)
        if i % knot_every == phase:
            r *= knot_gain
        if i == 0:
            r = r0 * flare
        if i == n - 1:
            r = 0.0
        out.append(r)
    return out


def silver_twist(b, L, seed):
    """Doua radacini aeriene rasucite una in alta, cu noduri."""
    rnd = lcg(seed)
    ph = rnd() * 6.28
    n = int(round(L / 0.28)) + 1
    for sgn in (1.0, -1.0):
        pts = []
        for i in range(n):
            t = i / float(n - 1)
            th = t * L * 2.6 + (0.0 if sgn > 0 else math.pi)
            cx = 0.03 * math.sin(t * 5.0 + ph) * t ** 0.5
            cy = 0.02 * math.cos(t * 4.0 + ph)
            rr = 0.05 * (1.0 - 0.5 * t) * min(1.0, t * 6.0)
            pts.append(Vector((cx + rr * math.cos(th), cy + rr * math.sin(th), -L * t)))
        tube(b, pts, knot_radii(n, 0.026, 3, 1.7, 1.3, 1 if sgn > 0 else 2), PLANT_ROOT, segments=5)


def silver_branched(b, L, seed):
    """O radacina cu noduri si trei radacinite subtiri care atarna din ea."""
    rnd = lcg(seed)
    ph = rnd() * 6.28
    pts = knotted_path(L, 0.3, 0.05, ph)
    tube(b, pts, knot_radii(len(pts), 0.040, 3, 1.55, 1.5), PLANT_ROOT, segments=6)
    for k, t in enumerate((0.22, 0.48, 0.7)):
        base = lerp_path(pts, t)
        az = rnd() * 6.28 + k * 2.1
        ln = 0.7 + 0.35 * rnd()
        sub = []
        for i in range(4):
            u = i / 3.0
            sub.append(base + Vector((math.cos(az) * 0.14 * math.sin(u * 2.0), math.sin(az) * 0.14 * math.sin(u * 2.0), -ln * u)))
        tube(b, sub, [0.016, 0.014, 0.01, 0.0], PLANT_ROOT, segments=3)


def silver_fan(b, L, seed):
    """Trei fire argintii de lungimi diferite dintr-un nod de sus."""
    rnd = lcg(seed)
    b.frustum((0.0, 0.0, -0.045), 0.06, 0.04, 0.09, PLANT_ROOT, segments=6)
    for k, (dx, frac) in enumerate(((-0.07, 0.82), (0.0, 1.0), (0.08, 0.62))):
        ph = rnd() * 6.28
        pts = knotted_path(L * frac, 0.34, 0.035, ph, offset=(dx, 0.0))
        pts[0] = Vector((dx * 0.4, 0.0, -0.06))
        tube(b, pts, knot_radii(len(pts), 0.022, 3, 1.7, 1.2, k % 3), PLANT_ROOT, segments=4)


VINE_SPEC = [
    ("Strand_0", "liana", 4.4, dict(seed=11, clusters=[(0.05, 3), (0.12, 3), (0.19, 3), (0.26, 3), (0.34, 3), (0.42, 2),
                                                      (0.51, 2), (0.60, 2), (0.70, 2), (0.80, 1)], leaf_len=0.40)),
    ("Strand_1", "twist", 3.8, dict(seed=21)),
    ("Strand_2", "liana", 3.4, dict(seed=31, clusters=[(0.10, 3), (0.22, 3), (0.34, 2), (0.48, 2), (0.62, 2)],
                                    leaf_len=0.38, sway=0.07)),
    ("Strand_3", "branched", 4.5, dict(seed=41)),
    ("Strand_4", "liana", 3.0, dict(seed=51, clusters=[(0.08, 2), (0.20, 3), (0.32, 2), (0.46, 2), (0.60, 2), (0.74, 1)],
                                    leaf_len=0.36, sway=0.06)),
    ("Strand_5", "fan", 3.6, dict(seed=61)),
]


def build_vine():
    objs = []
    for name, kind, L, kw in VINE_SPEC:
        b = Builder()
        if kind == "liana":
            liana(b, L, **kw)
        elif kind == "twist":
            silver_twist(b, L, **kw)
        elif kind == "branched":
            silver_branched(b, L, **kw)
        else:
            silver_fan(b, L, **kw)
        objs.append(b.to_object(name))
    return objs


def emit_vine():
    objs = build_vine()
    emit_plain(objs, "plants/vine_strands.glb",
               lambda o: dict(samples=12, dist=0.45, gradient="vertical", low=0.42, high=1.0, power=0.8,
                              floor=0.3, strength=1.0, z_range=(-4.6, 0.0)),
               smooth=60.0)
    clear_built()


# =============================================================================
# 3. lotus_cluster
# =============================================================================

AO_LOTUS = dict(samples=12, dist=0.5, gradient="vertical", low=0.62, high=1.0, power=0.8,
                floor=0.35, strength=1.0, z_range=(-0.06, 0.4))


def pack_discs(rnd, n, rmin, rmax, span, keep_out=(), gap=0.04, tries=400):
    """n discuri (x, y, r) in disc de raza `span`, fara suprapunere prea mare; `keep_out` =
    [(x, y, r)] zone libere (locurile florilor)."""
    placed = []
    for _ in range(tries):
        if len(placed) >= n:
            break
        r = rmin + (rmax - rmin) * rnd()
        a = rnd() * 6.2832
        d = (span - r) * math.sqrt(rnd())
        x, y = d * math.cos(a), d * math.sin(a)
        if any(math.hypot(x - px, y - py) < r + pr + gap for (px, py, pr) in placed):
            continue
        if any(math.hypot(x - kx, y - ky) < r + kr for (kx, ky, kr) in keep_out):
            continue
        placed.append((x, y, r))
    return placed


def lotus_flower(b, base, height, rnd, slot_petal=PLANT_PINK, scale=1.0):
    """Floare: doua randuri de petale-romb pliate (cate 6) in jurul unei capsule. `base` e
    varful tulpinii; `height` = cat de inalta e floarea de la baza."""
    base = Vector(base)
    n_out, n_in = 7, 6
    a0 = rnd() * 6.28
    for ring, (cnt, tilt, ln, wd) in enumerate(((n_out, 58.0, 0.17, 0.10), (n_in, 30.0, 0.15, 0.085))):
        for k in range(cnt):
            a = a0 + (k + 0.5 * ring) * 2.0 * math.pi / cnt + (rnd() - 0.5) * 0.15
            t = math.radians(tilt + (rnd() - 0.5) * 8.0)
            d = Vector((math.cos(a) * math.sin(t), math.sin(a) * math.sin(t), math.cos(t)))
            folded_leaf(b, base + Vector((math.cos(a) * 0.012, math.sin(a) * 0.012, 0.0)), d,
                        ln * scale, wd * scale, slot_petal, fold=0.22, belly=0.5, up=(0.0, 0.0, 1.0),
                        thick=0.008, fold_sign=-1.0)
    b.frustum(base + Vector((0.0, 0.0, 0.035)), 0.032 * scale, 0.04 * scale, 0.05, PLANT_LIGHT, segments=7)


def build_lotus():
    rnd = lcg(131)
    LF, FL = Builder(), Builder()
    # locurile florilor (x, y, z_baza, inaltime tulpina)
    stems = [(-0.40, 0.30, 0.12), (0.30, -0.15, 0.14), (0.05, 0.65, 0.10), (-0.10, -0.55, 0.13)]
    keep = [(x, y, 0.22) for (x, y, h) in stems]
    for (x, y, h) in stems:
        top = Vector((x, y, h))
        lean = Vector(((rnd() - 0.5) * 0.08, (rnd() - 0.5) * 0.08, 0.0))
        pts = [Vector((x, y, 0.0)), Vector((x, y, h * 0.5)) + lean, top + lean * 1.5]
        tube(FL, pts, [0.016, 0.013, 0.012], PLANT_GREEN, segments=5)
        lotus_flower(FL, top + lean * 1.5, 0.2, rnd, scale=1.7 + 0.25 * rnd())
    raised = [(-0.9, 0.5, 0.40), (0.85, 0.55, 0.36)]      # frunze ridicate pe tulpina (x, y, R)
    keep2 = keep + [(x, y, r) for (x, y, r) in raised]
    flat = pack_discs(rnd, 10, 0.30, 0.58, 1.25, keep_out=keep2, gap=-0.14, tries=3000)
    for k, (x, y, r) in enumerate(flat):
        ang = rnd() * 360.0
        dish(LF, (x, y, 0.032 + 0.004 * (k % 4)), r, PLANT_GREEN if k % 2 == 0 else PLANT_LIGHT, PLANT_LIGHT,
             rim_up=0.012 + 0.02 * rnd(), thick=0.02, seg=14, notch=(26.0 if k % 3 == 0 else 0.0),
             notch_at=ang, wave=0.006, phase=rnd() * 6.0)
    for k, (x, y, r) in enumerate(raised):
        tilt = math.radians(14.0 + 8.0 * k)
        az = math.radians(40.0 + 120.0 * k)
        axis = Vector((-math.sin(az), math.cos(az), 0.0))
        rot = Matrix.Rotation(tilt, 3, axis)
        zc = 0.11 + 0.03 * k
        dish(LF, (x, y, zc), r, PLANT_GREEN, PLANT_LIGHT, rim_up=0.07, thick=0.022, seg=14, rot=rot,
             wave=0.008, phase=rnd() * 6.0)
        tube(FL, [Vector((x + 0.02, y, 0.0)), Vector((x + 0.01, y, zc * 0.6)), Vector((x, y, zc - 0.012))],
             [0.014, 0.012, 0.012], PLANT_GREEN, segments=5)
    for bb in (LF, FL):       # nimic sub cota apei (tulpinile pornesc din ea)
        for v in bb.bm.verts:
            v.co.z = max(v.co.z, 0.0)
    return [LF.to_object("Lotus_Leaves"), FL.to_object("Lotus_Flowers")]


def emit_lotus():
    objs = build_lotus()
    emit_plain(objs, "plants/lotus_cluster.glb", lambda o: AO_LOTUS, smooth=60.0)
    clear_built()


# =============================================================================
# 4. water_lily_pads
# =============================================================================

AO_LILY = dict(samples=8, dist=0.4, gradient="none", floor=0.45, strength=0.8)


def build_lily():
    rnd = lcg(177)
    LP = Builder()
    pads = pack_discs(rnd, 10, 0.34, 0.58, 1.30, gap=-0.12, tries=3000)
    for k, (x, y, r) in enumerate(pads):
        lvl = 0.014 + 0.0055 * (k % 4)
        dish(LP, (x, y, lvl), r, PLANT_GREEN, PLANT_LIGHT if k % 2 == 0 else PLANT_GREEN,
             rim_up=0.010 + 0.006 * rnd(), thick=0.012, seg=14, notch=24.0 + 10.0 * rnd(),
             notch_at=rnd() * 360.0, wave=0.0, phase=0.0)
    return [LP.to_object("Lily_Pads")]


def emit_lily():
    objs = build_lily()
    emit_plain(objs, "plants/water_lily_pads.glb", lambda o: AO_LILY, smooth=60.0)
    clear_built()


if not ONLY or ONLY == "fig":
    emit_fig()
if not ONLY or ONLY == "vine":
    emit_vine()
if not ONLY or ONLY == "lotus":
    emit_lotus()
if not ONLY or ONLY == "lily":
    emit_lily()
report_angkor()
