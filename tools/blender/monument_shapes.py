"""Vocabular de forme pentru kitul Monument Valley (Track19).

Lectia Kyoto/Jodhpur: fara vocabular, constructorul reinventeaza forma din
cutii. Monument Valley are TREI etaje (brief §0.1): grohotis in trepte cu
bolovani jos, perete vertical cu COLOANE la mijloc, calota subtire si palida
sus. Functiile de aici le fac pe toate trei:

  wall_columns   perete din coloane verticale late de 1-3 m, fiecare cu inaltime
                 si iesire proprie, frontul in V (doua fatete), talpa evazata
  cap_slab       calota palida: o placa continua pe conturul coloanelor
  scree_ribs     fusta de grohotis cu coaste radiale + 2 praguri slabe
  boulder        bolovan colturos (icosfera jitterata)
  tapered_spire  deget/turla in segmente cu praguri, varf bont
  to_obj         bmesh -> obiect FARA recalc de normale (infasurarea e a noastra)

Se incarca cu exec, dupa dio_lib (vezi build_monument_*.py). Axe: X latime,
Y adancime (fata spre +Y in Blender = -Z in Godot), Z sus.
"""

import math
from mathutils import Vector, Matrix


def _face(b, verts, slot):
    """Fata din vertecsi noi; `slot` poate fi int sau functie(normala)->int
    (fetele din umbra pe alt slot, decise din normala)."""
    vs = [b.bm.verts.new(p) for p in verts]
    f = b.bm.faces.new(vs)
    f.normal_update()
    if callable(slot):
        n = f.normal if f.normal.length > 0 else Vector((0, 0, 1))
        f[b.slot] = slot(n)
    else:
        f[b.slot] = slot
    return f


def to_obj(b, name):
    """Ca `Builder.to_object`, dar FARA recalc_face_normals: fetele au vertecsi
    proprii (insule), iar recalc le-ar putea intoarce la intamplare. Orientarea
    spre exterior o garanteaza infasurarea din `loft`/`scree_skirt`."""
    me = bpy.data.meshes.new(name)
    b.bm.to_mesh(me)
    b.bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return obj


def loft(b, bottom, z0, top, z1, slot, cap_bottom=True):
    """Prisma convexa intre doua contururi cu acelasi numar de puncte, in plan,
    ANTIORAR vazut de sus. `bottom`/`top` = liste (x, y)."""
    n = len(bottom)
    for i in range(n):
        j = (i + 1) % n
        _face(b, [(bottom[i][0], bottom[i][1], z0),
                  (bottom[j][0], bottom[j][1], z0),
                  (top[j][0], top[j][1], z1),
                  (top[i][0], top[i][1], z1)], slot)
    _face(b, [(p[0], p[1], z1) for p in top], slot)
    if cap_bottom:
        _face(b, [(p[0], p[1], z0) for p in reversed(bottom)], slot)


def shade_by_x(lit, shade, thr=-0.35):
    """Fetele cu normala spre -X (sub `thr`) pe slotul din umbra."""
    return lambda n: shade if n.x < thr else lit


def chamfer(poly, c, skip=()):
    """Teseste fiecare colt al unui contur 2D antiorar: fiecare varf devine 3
    puncte (inceput de teseala, mijloc impins spre colt, sfarsit), deci 2
    fatete pe colt. `c` = cat se taie pe fiecare latura (cel mult 40% din ea).
    `skip` = indici de colturi lasate ascutite (un singur punct): capetele plane
    ale modulelor inlantuibile."""
    n = len(poly)
    out = []
    for i in range(n):
        if i in skip:
            out.append((poly[i][0], poly[i][1]))
            continue
        P = Vector(poly[i])
        e1 = Vector(poly[i - 1]) - P
        e2 = Vector(poly[(i + 1) % n]) - P
        l1, l2 = e1.length or 1.0, e2.length or 1.0
        a = P + e1 / l1 * min(c, l1 * 0.4)
        bp = P + e2 / l2 * min(c, l2 * 0.4)
        m = (a + bp) * 0.5
        m = m + (P - m) * 0.5
        out += [(a.x, a.y), (m.x, m.y), (bp.x, bp.y)]
    return out


def _perimeter(half_x, half_y, n=4.0, samples=400):
    """Conturul superelipsei (half_x, half_y) esantionat dens, cu lungimea
    cumulata: intoarce (puncte, lungimi_cumulate, lungime_totala). Parcurs
    ANTIORAR."""
    pts = [_super_pt(half_x, half_y, 2 * math.pi * i / samples - math.pi * 0.5, n)
           for i in range(samples + 1)]
    cum = [0.0]
    for i in range(1, len(pts)):
        cum.append(cum[-1] + math.hypot(pts[i][0] - pts[i - 1][0],
                                        pts[i][1] - pts[i - 1][1]))
    return pts, cum, cum[-1]


def _at(pts, cum, s):
    """Punctul de pe contur la distanta cumulata `s`."""
    lo, hi = 0, len(cum) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if cum[mid] <= s:
            lo = mid
        else:
            hi = mid
    t = (s - cum[lo]) / max(cum[hi] - cum[lo], 1e-9)
    return (pts[lo][0] + (pts[hi][0] - pts[lo][0]) * t,
            pts[lo][1] + (pts[hi][1] - pts[lo][1]) * t)


def wall_columns(b, half_x, half_y, h, lit, shade, seed=0, flare_h=5.8,
                 foot=1.4, vfront=0.5, taper=0.10, ledges=(0.0, 0.03, 0.05),
                 chamfer_c=0.45, wmin=2.0, wmax=4.0, recess=(0.8, 1.2),
                 prot=0.6, h_var=0.3):
    """Perete din coloane pe TOT conturul (patru fete, colturi rotunjite).

    Planul e o superelipsa rotunjita (half_x, half_y); conturul se imparte in
    coloane late de `wmin`..`wmax` m (lungime de arc), fiecare un sector cu
    marginea exterioara in V. Fiecare coloana are iesirea ei: unele ies cu
    pana la `prot`, ~30% stau in recese de `recess` m (goluri intunecate
    intre coloane). Coloanele inchid colturile (2-3 pe colt, din arc).

    h        inaltimea (fiecare coloana: h - rnd*h_var)
    taper    cat se ingusteaza peretele pe toata inaltimea (ambele axe, fractie)
    ledges   retragerea (fractie din scara) a segmentelor 1/2/3: praguri la ~1/3
             si ~2/3 din inaltime
    foot     cat iese talpa evazata (ultimele `flare_h` m), radial
    chamfer_c teseala verticala a muchiilor (2 fatete pe colt)

    Intoarce lista de dict {h, outer} (outer = conturul exterior al capului
    coloanei, puncte antiorar, pentru calota)."""
    rnd = _lcg(seed)
    pts, cum, L = _perimeter(half_x, half_y)
    ws = []
    while sum(ws) < L:
        ws.append(wmin + (wmax - wmin) * rnd())
    k = L / sum(ws)
    ws = [w * k for w in ws]
    sl = shade_by_x(lit, shade)

    def out_dir(p):
        d = Vector((p[0] / (half_x * half_x), p[1] / (half_y * half_y)))
        return d.normalized() if d.length > 0 else Vector((1, 0))

    def at(s, off):
        p = _at(pts, cum, s % L)
        d = out_dir(p)
        return (p[0] + d.x * off, p[1] + d.y * off)

    cols = []
    s0 = 0.0
    for w in ws:
        s1 = s0 + w
        sm = s0 + w * (0.35 + 0.3 * rnd())
        if rnd() < 0.3:
            off = -(recess[0] + (recess[1] - recess[0]) * rnd())
        else:
            off = -0.2 + (prot + 0.2) * rnd()
        vf = vfront * (0.6 + 0.8 * rnd())
        hc = h - rnd() * h_var

        def plan(extra, scale):
            o0, om, o1 = at(s0, off + extra), at(sm, off + extra + vf), at(s1, off + extra)
            i1 = at(s1, -half_x * 0.45)
            i0 = at(s0, -half_x * 0.45)
            return [(p[0] * scale, p[1] * scale) for p in (o0, om, o1, i1, i0)]
        b1 = hc * (0.30 + 0.08 * rnd())
        b2 = hc * (0.62 + 0.08 * rnd())
        zs = [0.0, b1, b2, hc]
        led = [ledges[0], ledges[1] * (0.6 + 0.8 * rnd()), ledges[2] * (0.6 + 0.8 * rnd())]
        top = None
        for kk in range(3):
            sb = (1.0 - taper * zs[kk] / hc) * (1.0 - led[kk])
            st = (1.0 - taper * zs[kk + 1] / hc) * (1.0 - led[kk])
            loft(b, chamfer(plan(0.0, sb), chamfer_c), zs[kk],
                 chamfer(plan(0.0, st), chamfer_c), zs[kk + 1], sl)
            top = plan(0.0, st)
        # talpa evazata (ultimii ~5-6 m): iese radial
        fh = min(flare_h * (0.85 + 0.3 * rnd()), hc * 0.25)
        loft(b, chamfer(plan(foot, 1.0), chamfer_c), 0.0,
             chamfer(plan(foot * 0.08, 1.0), chamfer_c), fh, sl)
        cols.append(dict(h=hc, outer=top[:3]))
        s0 = s1
    return cols


def cap_slab(b, cols, slot, z0, z1, ox, oy):
    """Calota: O SINGURA placa care urmareste conturul exterior al coloanelor
    (antiorar), largita cu `ox`/`oy` m (negativ = retrasa), de la z0 la z1.
    Fata de sus e un n-gon concav, triangulat aici."""
    pts = []
    for c in cols:
        pts += list(c["outer"])
    hx = max(abs(p[0]) for p in pts)
    hy = max(abs(p[1]) for p in pts)
    pts = [(p[0] * (1 + ox / hx), p[1] * (1 + oy / hy)) for p in pts]
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        if abs(pts[i][0] - pts[j][0]) + abs(pts[i][1] - pts[j][1]) < 1e-6:
            continue
        _face(b, [(pts[i][0], pts[i][1], z0), (pts[j][0], pts[j][1], z0),
                  (pts[j][0], pts[j][1], z1), (pts[i][0], pts[i][1], z1)], slot)
    f = _face(b, [(p[0], p[1], z1) for p in pts], slot)
    bmesh.ops.triangulate(b.bm, faces=[f])


def _super_pt(a, bb, th, n=3.0):
    c, s = math.cos(th), math.sin(th)
    e = 2.0 / n
    return (a * math.copysign(abs(c) ** e, c), bb * math.copysign(abs(s) ** e, s))


def skirt_d(x, y, half_x, half_y, n=3.0):
    """Cel mai mic d pentru care (x, y) e in superelipsa (half_x+d, half_y+d)."""
    lo, hi = -min(half_x, half_y) + 0.01, 80.0
    for _ in range(40):
        d = (lo + hi) * 0.5
        v = (abs(x) / (half_x + d)) ** n + (abs(y) / (half_y + d)) ** n
        if v > 1.0:
            lo = d
        else:
            hi = d
    return (lo + hi) * 0.5


# inele (s, nr. praguri): s=0 exterior (pe sol), s=1 langa perete. Doua praguri
# concentrice slabe = inelele duble de la 0,45 si 0,78 (riser vertical).
SKIRT_RINGS = [(0.0, 0), (0.12, 0), (0.25, 0), (0.38, 0), (0.45, 0), (0.45, 1),
               (0.58, 1), (0.70, 1), (0.78, 1), (0.78, 2), (0.90, 2), (1.0, 2)]


def _rib_z(s, cnt, crest, h_top, ledge, gully, power=1.25):
    fc = 1.0 if crest else gully
    fcr = 1.0 - (1.0 - fc) * (1.0 - s * s)
    return (h_top * s ** power + ledge * cnt) * fcr


def scree_ribs(b, half_x, half_y, D, h_top, slots, seed=0, pts=56, inner=1.2,
               ledge=0.3, gully=0.55):
    """Fusta de grohotis cu COASTE RADIALE (ca faldurile unei fuste): `pts`
    puncte pe unghi, alternand vale (par) si creasta (impar), deci pts/2
    coaste care coboara de la baza peretelui spre exterior; doua praguri
    concentrice slabe (`ledge` m). Inaltimea maxima ~ h_top + 2*ledge, langa
    perete. Slotul alterneaza pe fata coastei (dreapta/stanga a crestei)."""
    rnd = _lcg(seed + 7)
    off = [(rnd() - 0.5) * 0.8 for _ in range(pts)]

    def ring_pts(s, cnt):
        out = []
        for i in range(pts):
            d = D - (D - inner) * s + off[i] * (1.0 - s)
            th = 2 * math.pi * i / pts
            x, y = _super_pt(half_x + d, half_y + d, th)
            out.append((x, y, _rib_z(s, cnt, i % 2 == 1, h_top, ledge, gully)))
        return out
    rings = [ring_pts(s, c) for (s, c) in SKIRT_RINGS]
    # inel ascuns sub perete, la cota ultimului inel
    last = rings[-1]
    inside = []
    for i in range(pts):
        th = 2 * math.pi * i / pts
        x, y = _super_pt(half_x - 1.5, half_y - 1.5, th)
        inside.append((x, y, last[i][2]))
    rings.append(inside)
    for r in range(len(rings) - 1):
        A, B = rings[r], rings[r + 1]
        for i in range(pts):
            k = (i + 1) % pts
            _face(b, [A[i], A[k], B[k], B[i]], slots[i % 2])


def scree_height(x, y, half_x, half_y, D, h_top, inner=1.2, ledge=0.3,
                 gully=0.55, pts=56):
    """Cota suprafetei fustei in (x, y) (aceeasi regula ca `scree_ribs`, fara
    jitterul fin), cu valea/creasta dupa unghiul punctului."""
    d = skirt_d(x, y, half_x, half_y)
    if d > D:
        return 0.0
    a, bb = half_x + d, half_y + d
    c = math.copysign((abs(x) / a) ** 1.5, x)
    sn = math.copysign((abs(y) / bb) ** 1.5, y)
    th = math.atan2(sn, c) % (2 * math.pi)
    u = th / (2 * math.pi / pts)
    fi = u - math.floor(u)
    k = int(math.floor(u)) % 2
    crestness = fi if k == 0 else 1.0 - fi
    s = max(0.0, min(1.0, (D - d) / (D - inner)))
    zs = []
    for (sr, cnt) in SKIRT_RINGS:
        zg = _rib_z(sr, cnt, False, h_top, ledge, gully)
        zc = _rib_z(sr, cnt, True, h_top, ledge, gully)
        zs.append((sr, zg + (zc - zg) * crestness))
    z = zs[-1][1]
    for j in range(len(zs) - 1):
        s0, z0 = zs[j]
        s1, z1 = zs[j + 1]
        if s0 <= s <= s1 and s1 > s0:
            z = z0 + (z1 - z0) * (s - s0) / (s1 - s0)
            break
    return z


def boulder(b, center, size, slot, seed=0, jag=0.28, tilt=True):
    """Bolovan colturos: icosfera (80 triunghiuri), scalata pe `size`
    (x, y, z), fiecare varf impins radial aleator, rotit si usor inclinat."""
    rnd = _lcg(seed)
    res = bmesh.ops.create_icosphere(b.bm, subdivisions=1, radius=1.0)
    rz = rnd() * math.pi * 2
    rx = (rnd() - 0.5) * 0.7 if tilt else 0.0
    ry = (rnd() - 0.5) * 0.7 if tilt else 0.0
    rot = (Matrix.Rotation(rz, 3, "Z") @ Matrix.Rotation(rx, 3, "X")
           @ Matrix.Rotation(ry, 3, "Y"))
    cx, cy, cz = center
    for v in res["verts"]:
        k = 1.0 - jag * 0.5 + rnd() * jag
        p = Vector((v.co.x * size[0] * 0.5 * k, v.co.y * size[1] * 0.5 * k,
                    v.co.z * size[2] * 0.5 * k))
        v.co = rot @ p + Vector((cx, cy, cz))
    lo = min(v.co.z for v in res["verts"])
    if lo < 0.0:                     # niciun bolovan sub cota 0 (ar cobori ansamblul)
        for v in res["verts"]:
            v.co.z -= lo
    return b._tag(res["verts"], slot)


def _oct(cx, cy, hw, hd, rnd):
    """Octogon (8 puncte antiorar) cu semi-latimile hw/hd, usor neregulat."""
    out = []
    k0 = math.cos(math.radians(22.5))
    for k in range(8):
        a = math.radians(22.5 + 45 * k)
        r = 1.0 + (rnd() - 0.5) * 0.06
        out.append((cx + hw * math.cos(a) / k0 * r, cy + hd * math.sin(a) / k0 * r))
    return out


def tapered_spire(b, cx, cy, segs, lit, shade, seed=0):
    """Turla/deget: sir de segmente (z0, hw0, hd0, z1, hw1, hd1), fiecare un
    loft de octogoane (fetele din umbra pe -X). Pragul dintre segmente = hw1
    al unuia mai mare decat hw0 al urmatorului; ultimele segmente ingustate
    fac varful bont."""
    sl = shade_by_x(lit, shade)
    for n, (z0, hw0, hd0, z1, hw1, hd1) in enumerate(segs):
        sd = seed * 1000 + n
        loft(b, _oct(cx, cy, hw0, hd0, _lcg(sd)), z0,
             _oct(cx, cy, hw1, hd1, _lcg(sd)), z1, sl)


# ---------------------------------------------------------------------------
# Grupa mv-a: arc, bloc cu contraforturi, perete de masa inlantuibil
# ---------------------------------------------------------------------------

def prism_xz(b, poly, y0, y1, slot):
    """Prisma inchisa: conturul `poly` (x, z) extrudat pe Y intre y0 si y1.
    Orientarea fetelor se decide analitic (normala exterioara a laturii), deci
    merge si pe contururi concave (intradosul unui arc)."""
    n = len(poly)
    area = sum(poly[i][0] * poly[(i + 1) % n][1] - poly[(i + 1) % n][0] * poly[i][1]
               for i in range(n)) * 0.5
    sg = 1.0 if area > 0 else -1.0
    for i in range(n):
        j = (i + 1) % n
        dx, dz = poly[j][0] - poly[i][0], poly[j][1] - poly[i][1]
        if abs(dx) + abs(dz) < 1e-7:
            continue
        f = _face(b, [(poly[i][0], y0, poly[i][1]), (poly[j][0], y0, poly[j][1]),
                      (poly[j][0], y1, poly[j][1]), (poly[i][0], y1, poly[i][1])], slot)
        want = Vector((dz * sg, 0.0, -dx * sg))
        if f.normal.dot(want) < 0:
            bmesh.ops.reverse_faces(b.bm, faces=[f])
    for yy, ny in ((y1, 1.0), (y0, -1.0)):
        f = _face(b, [(p[0], yy, p[1]) for p in poly], slot)
        res = bmesh.ops.triangulate(b.bm, faces=[f], quad_method="BEAUTY", ngon_method="EAR_CLIP")
        for t in res["faces"]:
            t.normal_update()
            if t.normal.y * ny < 0:
                bmesh.ops.reverse_faces(b.bm, faces=[t])


def buttress(b, cx, y_face, w, d, h, lit, shade, seed=0, foot=0.9):
    """Contrafort: stalp lat de `w` m care iese `d` m din fata peretelui (y_face),
    inalt de `h`, evazat jos, in 4 segmente care se ingusteaza spre varf."""
    rnd = _lcg(seed)
    sl = shade_by_x(lit, shade)
    j1, j2 = 0.35 * (0.6 + 0.8 * rnd()), 0.35 * (0.6 + 0.8 * rnd())

    def plan(sc, grow):
        hw = w * 0.5 * sc + grow
        y_out = y_face + d * sc + grow * 0.6
        y_in = y_face - 1.5
        return [(cx - hw, y_in), (cx + hw, y_in), (cx + hw * 0.92, y_out),
                (cx + hw * 0.35, y_out + j1), (cx - hw * 0.35, y_out + j2),
                (cx - hw * 0.92, y_out)]
    zs = [0.0, h * 0.30, h * 0.62, h * 0.88, h]
    scs = [1.0, 0.94, 0.88, 0.80, 0.55]
    loft(b, chamfer(plan(1.0, foot), 0.35), 0.0, chamfer(plan(1.0, 0.0), 0.35),
         min(4.0, h * 0.2), sl)
    for k in range(4):
        loft(b, chamfer(plan(scs[k], 0.0), 0.35), zs[k],
             chamfer(plan(scs[k + 1], 0.0), 0.35), zs[k + 1], sl)


def scree_boulders(b, half_x, half_y, D, h_top, slots, n_big, n_small, zmax,
                   seed=0, pts=56, cx=0.0, skip=None):
    """Bolovanii fustei de grohotis (aceeasi regula ca la West Mitten): mari
    pe margine si in vai, mici imprastiati dincolo de margine. `skip(x, y)`
    -> True exclude pozitia (ex. golul unui arc). `cx` = deplasarea fustei."""
    rnd = _lcg(seed)
    nb = 0
    tries = 0
    while nb < n_big and tries < 6000:
        tries += 1
        i = 2 * int(rnd() * pts / 2)
        th = 2 * math.pi * (i + (rnd() - 0.5) * 0.8) / pts
        d = 1.5 + (D - 1.0) * (rnd() ** 0.55)
        x, y = _super_pt(half_x + d, half_y + d, th)
        if abs(x) < half_x + 1.0 and abs(y) < half_y + 1.5:
            continue
        if skip and skip(x + cx, y):
            continue
        sz = 1.2 + rnd() * 2.2
        z = scree_height(x, y, half_x, half_y, D, h_top, pts=pts)
        if z + sz * 0.75 > zmax:
            continue
        boulder(b, (x + cx, y, z + sz * 0.12), (sz * 1.2, sz, sz * 0.8),
                slots[nb % 2], seed=seed * 7 + 100 + nb)
        nb += 1
    ns = 0
    while ns < n_small:
        th = rnd() * 2 * math.pi
        d = D - 0.5 + rnd() * 3.2
        x, y = _super_pt(half_x + d, half_y + d, th)
        if skip and skip(x + cx, y):
            continue
        sz = 0.35 + rnd() * 0.55
        z = scree_height(x, y, half_x, half_y, D, h_top, pts=pts)
        boulder(b, (x + cx, y, z + sz * 0.15), (sz * 1.3, sz, sz * 0.7),
                slots[ns % 2], seed=seed * 7 + 300 + ns)
        ns += 1


def mesa_run(b, half_l, xf, xb, h, lit, shade, seed=0, n_mid=3, w_end=2.0,
             taper=0.07, ledges=(0.0, 0.03, 0.05), prot=0.5, recess=(0.5, 0.9),
             chamfer_c=0.35, foot=0.8, flare_h=3.0, vfront=0.35, h_var=0.3):
    """Perete de masa INLANTUIBIL pe Y (de la -half_l la +half_l): coloane
    verticale, fata (+X) si spatele (-X) in V. Cele doua coloane de capat sunt
    IDENTICE (acelasi plan, aceeasi inaltime, aceleasi praguri), cu capetele
    plane la y = +-half_l si fara teseala pe colturile de capat, deci doua
    module puse cap la cap se imbina fara fisura. Taperul/pragurile scaleaza
    doar X. Intoarce (x_min, x_max) al iesirilor (cu talpa), pentru calota."""
    rnd = _lcg(seed)
    L = 2 * half_l
    mids = [1.0 + rnd() * 0.6 for _ in range(n_mid)]
    k = (L - 2 * w_end) / sum(mids)
    mids = [m * k for m in mids]
    sl = shade_by_x(lit, shade)

    def pick():
        if rnd() > 0.3:
            return -0.1 + prot * rnd()
        return -(recess[0] + (recess[1] - recess[0]) * rnd())

    def params(is_end):
        return dict(fo=pick(), bo=pick(), vf=vfront * (0.6 + 0.8 * rnd()),
                    vb=vfront * (0.5 + 0.6 * rnd()),
                    hc=h - (0.15 if is_end else rnd() * h_var),
                    b1=0.30 + 0.08 * rnd(), b2=0.62 + 0.08 * rnd(),
                    led=[ledges[0], ledges[1] * (0.6 + 0.8 * rnd()),
                         ledges[2] * (0.6 + 0.8 * rnd())],
                    fh=min(flare_h * (0.85 + 0.3 * rnd()), h * 0.25))
    end_p = params(True)
    plist = ([(w_end, end_p, "L")] + [(w, params(False), "M") for w in mids]
             + [(w_end, end_p, "R")])
    xmin, xmax = 1e9, -1e9
    s0 = -half_l
    for w, P, kind in plist:
        s1 = s0 + w
        sm = (s0 + s1) * 0.5
        F = xf + P["fo"]
        B = xb - P["bo"]
        xmin, xmax = min(xmin, B - P["vb"]), max(xmax, F + P["vf"])
        skip = (5, 0) if kind == "L" else ((2, 3) if kind == "R" else ())

        def plan(sx, extra=0.0, F=F, B=B, P=P, s0=s0, s1=s1, sm=sm):
            raw = [(F + extra, s0), (F + P["vf"] + extra, sm), (F + extra, s1),
                   (B - extra, s1), (B - P["vb"] - extra, sm), (B - extra, s0)]
            return [(x * sx, y) for x, y in raw]
        hc = P["hc"]
        zs = [0.0, hc * P["b1"], hc * P["b2"], hc]
        for kk in range(3):
            sb = (1.0 - taper * zs[kk] / hc) * (1.0 - P["led"][kk])
            st = (1.0 - taper * zs[kk + 1] / hc) * (1.0 - P["led"][kk])
            loft(b, chamfer(plan(sb), chamfer_c, skip), zs[kk],
                 chamfer(plan(st), chamfer_c, skip), zs[kk + 1], sl)
        loft(b, chamfer(plan(1.0, foot), chamfer_c, skip), 0.0,
             chamfer(plan(1.0, foot * 0.08), chamfer_c, skip), P["fh"], sl)
        s0 = s1
    return xmin - foot, xmax + foot


def mesa_scree(b, half_l, x_wall, side, D, h_top, slots, period=3.0, gully=0.55,
               ledge=0.2, ystep=0.75):
    """Grohotis de masa pe o parte a peretelui (side = +1 fata / -1 spate): coaste
    perpendiculare pe perete cu perioada `period` (care divide 2*half_l, deci
    profilul la y = -half_l si +half_l e identic: valea) si capete inchise plat."""
    ny = int(round(2 * half_l / ystep))
    ys = [-half_l + i * (2 * half_l / ny) for i in range(ny + 1)]
    grid = []
    for (s, cnt) in SKIRT_RINGS:
        xr = x_wall + side * (D * (1.0 - s) - 1.2 * s)
        row = []
        for y in ys:
            crest = 0.5 - 0.5 * math.cos(2 * math.pi * y / period)
            fc = gully + (1.0 - gully) * crest
            fcr = 1.0 - (1.0 - fc) * (1.0 - s * s)
            row.append((xr, y, (h_top * s ** 1.25 + ledge * cnt) * fcr))
        grid.append(row)
    flip = None
    for r in range(len(grid) - 1):
        for i in range(ny):
            quad = [grid[r][i], grid[r][i + 1], grid[r + 1][i + 1], grid[r + 1][i]]
            f = _face(b, quad, slots[i % 2])
            if flip is None and abs(f.normal.z) > 0.5:
                flip = f.normal.z < 0
            if flip:
                bmesh.ops.reverse_faces(b.bm, faces=[f])
    for i, ysg in ((0, -1.0), (ny, 1.0)):
        for r in range(len(grid) - 1):
            a, c = grid[r][i], grid[r + 1][i]
            f = _face(b, [a, c, (c[0], c[1], 0.0), (a[0], a[1], 0.0)], slots[0])
            if f.normal.y * ysg < 0:
                bmesh.ops.reverse_faces(b.bm, faces=[f])


# ---------------------------------------------------------------------------
# emit -- comun tuturor build-urilor Monument Valley
# ---------------------------------------------------------------------------

RESULTS = []


def emit(objs, path, ao, keep_xy=True, bevel=0.0, smooth_angle=None,
         budget=None, bevel_angle=30.0):
    """Finish pe fiecare nod + export. Offsetul de origine se calculeaza O DATA
    pe ansamblu si se aplica identic (memoria finish-recentreaza-fiecare-nod-
    separat). `keep_xy=True` (implicit pe monoliti): XY ramane cum a fost
    construit (originea la baza TURNULUI, nu la centrul bbox-ului cu fusta si
    deget) si se coboara doar pe Z; `keep_xy=False` centreaza bbox-ul
    ansamblului. `path` e relativ la assets/models/monumentvalley/."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    place = Vector((0.0 if keep_xy else -(min(xs) + max(xs)) * 0.5,
                    0.0 if keep_xy else -(min(ys) + max(ys)) * 0.5,
                    -min(zs)))
    total = 0
    per_node = {}
    for o in objs:
        for v in o.data.vertices:
            v.co += place
        st = finish(o, bevel=bevel, bevel_angle=bevel_angle, ao=ao,
                    origin=None, smooth_angle=smooth_angle)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "monumentvalley/" + path)
    RESULTS.append((path, total, dims, budget, per_node, sz / 1024.0))
    return total


def report():
    print()
    for path, tris, dims, budget, per_node, kb in RESULTS:
        flag = ""
        if budget is not None:
            flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
        print("%-42s tris=%6d%s  %.2f x %.2f x %.2f m  %.0f kB" %
              (path, tris, flag, dims.x, dims.y, dims.z, kb))
        print("    noduri:", per_node)
