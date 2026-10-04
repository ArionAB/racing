"""Vocabular de forme pentru kitul Monument Valley (Track19).

Lectia Kyoto/Jodhpur: fara vocabular, constructorul reinventeaza forma din
cutii. Monument Valley are TREI etaje (brief §0.1): grohotis in trepte cu
bolovani jos, perete vertical cu COLOANE la mijloc, calota subtire si palida
sus. Functiile de aici le fac pe toate trei:

  wall_columns   perete din coloane verticale late de 1-3 m, fiecare cu inaltime
                 si iesire proprie, frontul in V (doua fatete), talpa evazata
  cap_steps      calota palida in trepte, pe coloanele inalte
  scree_skirt    fusta de grohotis: terase concentrice, riser vertical, fata de
                 sus usor inclinata pe puncte alternante (caneluri radiale)
  boulder        bolovan colturos (icosfera jitterata)
  spire          deget/turla: coloane cu inaltimi diferite, varf ingustat
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


def wall_columns(b, half_x, half_y, heights, lit, shade, seed=0, flare_h=6.0,
                 widths=None, jut=0.7, foot=0.8, draft=0.96, vfront=0.5, tier=0.035):
    """Perete de coloane pe latimea [-half_x, +half_x] (X), adancime +-half_y.

    heights   lista de inaltimi, una per coloana (numarul coloanelor = len)
    widths    latimi relative (implicit aleatoare 1.4..3.0, normalizate la
              2*half_x)
    jut       cat variaza iesirea frontului/spatelui per coloana (+-)
    foot      cat iese talpa evazata (z 0..flare_h) fata de coloana, doar pe Y
    draft     factorul pe Y al capului coloanei (peretele se ingusteaza usor)
    vfront    cat iese varful V-ului de pe fata fata de colturi

    Intoarce lista de dict {x0, x1, h, poly} pentru calota."""
    rnd = _lcg(seed)
    n = len(heights)
    if widths is None:
        widths = [1.4 + 1.6 * rnd() for _ in range(n)]
    tot = float(sum(widths))
    xs = [-half_x]
    for w in widths:
        xs.append(xs[-1] + w / tot * 2 * half_x)
    cols = []
    sl = shade_by_x(lit, shade)
    for i in range(n):
        x0, x1 = xs[i], xs[i + 1]
        xm = x0 + (x1 - x0) * (0.35 + 0.3 * rnd())
        yf0 = half_y + (rnd() - 0.5) * 2 * jut
        yf1 = half_y + (rnd() - 0.5) * 2 * jut
        yb0 = -half_y + (rnd() - 0.5) * 2 * jut
        yb1 = -half_y + (rnd() - 0.5) * 2 * jut
        ym = max(yf0, yf1) + vfront * (0.6 + 0.8 * rnd())
        bot = [(x0, yb0), (x1, yb1), (x1, yf1), (xm, ym), (x0, yf0)]
        h = heights[i]
        # TREPTE de perete: 3 segmente suprapuse, fiecare mai tras pe Y decat cel
        # de jos (prag/ledge vizibil, ca sirurile de roca din decupare)
        b1 = h * (0.36 + 0.14 * rnd())
        b2 = h * (0.66 + 0.14 * rnd())
        zs = [0.0, b1, b2, h]
        sc = [1.0, 1.0 - tier * (0.5 + rnd()), 1.0 - 2 * tier * (0.5 + rnd())]
        top = None
        for k in range(3):
            sb = [(x, y * sc[k]) for (x, y) in bot]
            st = sb if k < 2 else [(x, y * sc[k] * draft) for (x, y) in bot]
            loft(b, sb, zs[k], st, zs[k + 1], sl)
            top = st
        # talpa evazata: iese in Y, nu in X (nu intra in vecini)
        fh = min(flare_h * (0.7 + 0.6 * rnd()), h * 0.4)
        bot2 = [(x0, yb0 - foot), (x1, yb1 - foot), (x1, yf1 + foot),
                (xm, ym + foot), (x0, yf0 + foot)]
        top2 = [(x0, yb0 - foot * 0.2), (x1, yb1 - foot * 0.2),
                (x1, yf1 + foot * 0.2), (xm, ym + foot * 0.2),
                (x0, yf0 + foot * 0.2)]
        loft(b, bot2, 0.0, top2, fh, sl)
        cols.append(dict(x0=x0, x1=x1, h=h, poly=top))
    return cols


def cap_steps(b, cols, slot, top_h, t1=0.5, t2=0.4, inset=0.18, inset2=0.9,
              every=2):
    """Calota palida in doua trepte pe coloanele care ajung la `top_h`.
    Treapta 1 (`t1`) pe fiecare, treapta 2 (`t2`, mai ingusta) pe fiecare a
    `every`-a. Intoarce numarul de coloane acoperite."""
    k = 0
    for c in cols:
        if c["h"] < top_h - 1e-6:
            continue
        cx = sum(p[0] for p in c["poly"]) / len(c["poly"])
        cy = sum(p[1] for p in c["poly"]) / len(c["poly"])

        def shrink(poly, d):
            out = []
            for (x, y) in poly:
                vx, vy = cx - x, cy - y
                L = math.hypot(vx, vy) or 1.0
                out.append((x + vx / L * d, y + vy / L * d))
            return out
        p1 = shrink(c["poly"], inset)
        loft(b, p1, top_h, p1, top_h + t1, slot)
        if k % every == 0:
            p2 = shrink(c["poly"], inset2)
            loft(b, p2, top_h + t1, p2, top_h + t1 + t2, slot)
        k += 1
    return k


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


def skirt_levels(D, steps, h_top, inner):
    ds = [D - (D - inner) * j / max(steps - 1, 1) for j in range(steps)]
    hs = [h_top * (j + 1) / steps for j in range(steps)]
    return ds, hs


def scree_skirt(b, half_x, half_y, D, steps, h_top, slots, seed=0, pts=44,
                tilt=0.22, inner=1.2):
    """Fusta de grohotis in `steps` terase, de la d=D (exterior) la d=inner.

    Terasa j are inaltimea h_top*(j+1)/steps. Contururile sunt superelipse
    (half_x+d, half_y+d); punctele alterneaza +-`tilt` pe Z si +-0.25 m in d,
    deci fetele de sus sunt inclinate si apar caneluri radiale. Slotul
    alterneaza pe terasa. Ultima coroana se opreste sub perete (ascunsa)."""
    rnd = _lcg(seed + 7)
    ds, hs = skirt_levels(D, steps, h_top, inner)
    off = [(rnd() - 0.5) * 0.5 for _ in range(pts)]
    tl = [tilt * (1 if i % 2 else -1) * (0.6 + 0.8 * rnd()) for i in range(pts)]

    def xy(j, i, inset=None):
        th = 2 * math.pi * i / pts
        if inset is None:
            d = ds[j] + off[i] * (0.4 + 0.6 * j / steps) + (0.25 if i % 2 else -0.25)
            return _super_pt(half_x + d, half_y + d, th)
        return _super_pt(half_x - inset, half_y - inset, th)

    prev = 0.0
    for j in range(steps):
        sl = slots[j % len(slots)]
        zlo = [0.0 if prev == 0.0 else prev + tl[i] for i in range(pts)]
        zhi = [hs[j] + tl[i] for i in range(pts)]
        P = [xy(j, i) for i in range(pts)]
        for i in range(pts):
            k = (i + 1) % pts
            _face(b, [(P[i][0], P[i][1], zlo[i]), (P[k][0], P[k][1], zlo[k]),
                      (P[k][0], P[k][1], zhi[k]), (P[i][0], P[i][1], zhi[i])], sl)
        Q = [xy(j + 1, i) if j + 1 < steps else xy(j, i, inset=1.5)
             for i in range(pts)]
        for i in range(pts):
            k = (i + 1) % pts
            _face(b, [(P[i][0], P[i][1], zhi[i]), (P[k][0], P[k][1], zhi[k]),
                      (Q[k][0], Q[k][1], zhi[k]), (Q[i][0], Q[i][1], zhi[i])], sl)
        prev = hs[j]
    return list(zip(ds, hs))


def scree_height(x, y, half_x, half_y, D, steps, h_top, inner=1.2):
    """Cota suprafetei fustei in (x, y), aceeasi regula ca `scree_skirt`
    (fara inclinarea fina)."""
    d = skirt_d(x, y, half_x, half_y)
    if d > D:
        return 0.0
    ds, hs = skirt_levels(D, steps, h_top, inner)
    for j in range(steps):
        nxt = ds[j + 1] if j + 1 < steps else -99.0
        if d > nxt:
            return hs[j]
    return hs[-1]


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


def spire(b, parts, lit, shade, seed=0, draft=0.8):
    """Deget/turla din coloane verticale. `parts` = lista de
    (x0, x1, y0, y1, h): fiecare coloana e un loft cu 6 puncte, varful mai
    ingust cu `draft` (silueta de ac). Intoarce lista pentru calota (acelasi
    format ca `wall_columns`)."""
    rnd = _lcg(seed + 31)
    out = []
    sl = shade_by_x(lit, shade)
    for part in parts:
        x0, x1, y0, y1, h = part[:5]
        dr = part[5] if len(part) > 5 else draft
        xm = (x0 + x1) * 0.5
        ym = (y0 + y1) * 0.5

        def j():
            return (rnd() - 0.5) * 0.35
        bot = [(x0 + j(), y0), (xm + j(), y0 - 0.3), (x1 + j(), y0 + 0.2),
               (x1 + j(), y1 - 0.2), (xm + j(), y1 + 0.3), (x0 + j(), y1)]
        top = [(xm + (p[0] - xm) * dr, ym + (p[1] - ym) * dr) for p in bot]
        loft(b, bot, 0.0, top, h, sl)
        out.append(dict(x0=x0, x1=x1, h=h, poly=top))
    return out


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
