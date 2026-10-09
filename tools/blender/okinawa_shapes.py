"""Vocabular de forme pentru kitul Okinawa v2 (Track20).

Contract: docs/asset_briefs/okinawa_kit_v2.md. Lectia Kyoto/Monument Valley:
fara vocabular comun, fiecare constructor reinventeaza acoperisul din cutii.
Aici stau formele care se repeta intre poarta, palat, case si refugiu:

  HipRoof        acoperis de olane in patru ape (yosemune): panta concava,
                 streasina RIDICATA la colturi, olane in relief (coloane
                 alternante), grosime reala. `build()` da doua noduri:
                 olanele (TILE_TERRACOTTA) si mortarul (FOAM_WHITE: coama,
                 muchiile de colt si rosturi in relief). `z(x, y)` = cota
                 suprafetei, ca stalpii si ornamentele sa stea pe ea.
  lacquer_pillar stalp lacuit usor conic, cu inel de capat
  bracket        consola in trepte (dougong simplificat) sub streasina
  stone_plinth   soclu de piatra: talpa evazata + placa de capat
  gold_finial    ornament de coama (soclu + bila + flacara), CAR_YELLOW
  limestone_wall zid de calcar cu TALUS (grosimea scade cu inaltimea),
                 asize vizibile ca trepte, creasta rotunjita; capete plane,
                 pentru modulele inlantuibile gusuku
  emit           export per nod, offset de origine calculat o data pe ansamblu

Se incarca cu exec, dupa dio_lib (vezi build_okinawa_*.py). Axe: X latime,
Y adancime (fata spre +Y in Blender = -Z in Godot), Z sus. Reutilizeaza
`loft`, `chamfer`, `_face` din monument_shapes.py.
"""

import math
from mathutils import Vector, Matrix

_here_os = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here_os, "monument_shapes.py")).read())

# --- sloturile pe roluri (kit v2 §0, tabelul de sloturi) ---------------------
OK_LIMESTONE = MARBLE_GREY      # 29: calcarul Ryukyu; clasa ok_limestone da porii
OK_LACQUER = KERB_RED           # 7: lacul rosu; clasa ok_lacquer daca iese "plastic"
OK_TILE = TILE_TERRACOTTA       # 23: olane; clasa roof_tiles pe *_Roof
OK_MORTAR = FOAM_WHITE          # 22: coame si rosturi albe
OK_GOLD = CAR_YELLOW            # 16: puncte mici (--allow-car-slots=*_Gold)
OK_NICHE = SAND_SHADOW          # 2: nise inguste in calcar


# ---------------------------------------------------------------------------
# acoperis in patru ape
# ---------------------------------------------------------------------------

class HipRoof:
    """Acoperis de olane in patru ape cu coama.

    `hu` = semilungimea pe axa lunga a streasinii, `hv` = semilatimea; `swap`
    pune axa lunga pe Y (altfel pe X). `R` = semilungimea coamei (0 = piramida).
    `z0` = cota streasinii (inainte de ridicare), `rise` = inaltimea pana la
    coama. `lift` = cat se ridica COLTURILE streasinii (curbura in sus a
    streasinii de poarta/palat). `th` = grosimea placii de olane.

    Panta e concava: aproape plata la streasina, abrupta spre coama
    (s = t**curve, curve > 1) — silueta de acoperis chinezesc/ryukyu, nu de
    piramida dreapta.
    """

    def __init__(self, cx, cy, hu, hv, z0, rise, R=None, swap=False, lift=0.5,
                 th=0.16, curve=1.35, tile_step=0.3, tile_amp=0.06):
        self.cx, self.cy, self.hu, self.hv = cx, cy, hu, hv
        self.z0, self.rise, self.swap = z0, rise, swap
        self.R = max(0.0, hu - hv * 0.9) if R is None else R
        self.lift, self.th, self.curve = lift, th, curve
        self.tile_step, self.tile_amp = tile_step, tile_amp

    # coordonate locale (u pe axa lunga, v pe cea scurta) <-> lume
    def to_world(self, u, v):
        return (self.cx + v, self.cy + u) if self.swap else (self.cx + u, self.cy + v)

    def to_local(self, x, y):
        return (y - self.cy, x - self.cx) if self.swap else (x - self.cx, y - self.cy)

    def _t(self, u, v):
        tv = (self.hv - abs(v)) / self.hv
        tu = (self.hu - abs(u)) / max(self.hu - self.R, 1e-6)
        return max(0.0, min(1.0, tv, tu)), tv <= tu

    def z_local(self, u, v):
        t, _ = self._t(u, v)
        corner = (abs(u) / self.hu * abs(v) / self.hv) ** 4.0
        return (self.z0 + self.rise * t ** self.curve
                + self.lift * corner * (1.0 - t) ** 2)

    def z(self, x, y):
        """Cota fetei de sus (fara ondularea olanelor)."""
        u, v = self.to_local(x, y)
        u = max(-self.hu, min(self.hu, u))
        v = max(-self.hv, min(self.hv, v))
        return self.z_local(u, v)

    @property
    def ridge_z(self):
        return self.z0 + self.rise

    def build(self, rb, mb, slot_tile=OK_TILE, slot_mortar=OK_MORTAR,
              seams=True, border=True):
        """Adauga olanele in `rb` si mortarul in `mb` (doua Builder)."""
        nu = max(4, 2 * int(round(self.hu / self.tile_step)))
        nv = max(4, 2 * int(round(self.hv / self.tile_step)))
        top, bot = {}, {}
        for i in range(nu + 1):
            u = -self.hu + 2 * self.hu * i / nu
            for j in range(nv + 1):
                v = -self.hv + 2 * self.hv * j / nv
                z = self.z_local(u, v)
                t, side = self._t(u, v)
                par = (i % 2) if side else (j % 2)
                edge = (i in (0, nu)) or (j in (0, nv))
                amp = 0.0 if edge else self.tile_amp * par
                x, y = self.to_world(u, v)
                top[(i, j)] = rb.bm.verts.new((x, y, z + amp))
                bot[(i, j)] = rb.bm.verts.new((x, y, z - self.th))

        def quad(a, b_, c, d, slot):
            f = rb.bm.faces.new([a, b_, c, d])
            f[rb.slot] = slot

        for i in range(nu):
            for j in range(nv):
                quad(top[(i, j)], top[(i + 1, j)], top[(i + 1, j + 1)], top[(i, j + 1)], slot_tile)
                quad(bot[(i, j + 1)], bot[(i + 1, j + 1)], bot[(i + 1, j)], bot[(i, j)], slot_tile)
        for i in range(nu):
            quad(top[(i, 0)], bot[(i, 0)], bot[(i + 1, 0)], top[(i + 1, 0)], slot_tile)
            quad(top[(i + 1, nv)], bot[(i + 1, nv)], bot[(i, nv)], top[(i, nv)], slot_tile)
        for j in range(nv):
            quad(top[(0, j + 1)], bot[(0, j + 1)], bot[(0, j)], top[(0, j)], slot_tile)
            quad(top[(nu, j)], bot[(nu, j)], bot[(nu, j + 1)], top[(nu, j + 1)], slot_tile)

        # --- mortar: coama + 4 muchii de colt + rosturi albe in relief
        lift_z = 0.10
        def lay(points, w, h):
            for a, c in zip(points, points[1:]):
                mb.beam(a, c, (w, h), slot_mortar)

        def on_surface(u, v, dz=lift_z):
            x, y = self.to_world(u, v)
            return (x, y, self.z_local(u, v) + self.tile_amp + dz)

        R = self.R
        ridge = [on_surface(u, 0.0, 0.12) for u in
                 [(-R + 2 * R * k / 8) for k in range(9)]] if R > 0 else []
        if ridge:
            lay(ridge, 0.42, 0.34)
        for su in (-1, 1):
            for sv in (-1, 1):
                pts = []
                n = 8
                for k in range(n + 1):
                    f = k / n
                    pts.append(on_surface(su * (self.hu + (R - self.hu) * f),
                                          sv * self.hv * (1 - f), 0.08))
                lay(pts, 0.34, 0.26)
        if border:
            # bordura alba a streasinii (singurul alb de pe panta, cu coama si muchiile)
            nb = max(6, int(2 * self.hu / 0.5))
            mb_ = max(4, int(2 * self.hv / 0.5))
            for sv in (-1, 1):
                lay([on_surface(-self.hu + 2 * self.hu * k / nb, sv * self.hv, 0.02)
                     for k in range(nb + 1)], 0.2, 0.16)
            for su in (-1, 1):
                lay([on_surface(su * self.hu, -self.hv + 2 * self.hv * k / mb_, 0.02)
                     for k in range(mb_ + 1)], 0.2, 0.16)
        if seams:
            # rosturi albe (olane de rand): benzi inguste de la streasina la coama
            step = 2.1
            k = 1
            while k * step < R - 0.2:
                for su in (-1, 1):
                    u = su * k * step
                    for sv in (-1, 1):
                        pts = [on_surface(u, sv * self.hv * (1 - f / 6.0), 0.05)
                               for f in range(6)]
                        lay(pts, 0.09, 0.08)
                k += 1
        return (rb, mb)


# ---------------------------------------------------------------------------
# stalpi, socluri, console, ornamente
# ---------------------------------------------------------------------------

def lacquer_pillar(b, x, y, z0, z1, r, slot=OK_LACQUER, seg=10, taper=0.88):
    """Stalp lacuit usor conic (mai gros jos), cu inel de capat. `seg` rotund
    explicit (regula 10)."""
    zc = (z0 + z1) * 0.5
    b.frustum((x, y, zc), r, r * taper, z1 - z0, slot, segments=seg)
    b.frustum((x, y, z1 - 0.12), r * taper * 1.22, r * taper * 1.22, 0.24, slot, segments=seg)
    b.frustum((x, y, z0 + 0.12), r * 1.18, r * 1.18, 0.24, slot, segments=seg)


def bracket(b, x, y, z, w, slot=OK_LACQUER, layers=3, step=0.18, grow=0.34):
    """Consola in trepte care sustine streasina: `layers` blocuri late tot mai
    mult, pe lung (X) si pe adancime (Y) usor diferit. Baza la `z`."""
    for k in range(layers):
        s = w * (1.0 + grow * k * 1.4)
        b.box((x, y, z + step * (k + 0.5)), (s, w * (1.0 + 0.5 * k), step), slot)
    return z + step * layers


def stone_plinth(b, cx, cy, hx, hy, h, slot=OK_LIMESTONE, flare=0.12, cap_h=0.16,
                 cap_over=0.08, z0=0.0):
    """Soclu de piatra: corp cu talpa evazata (se ingusteaza cu `flare` spre
    varf) si placa de capat usor iesita. Taiat la colturi ca sa nu iasa cutie.
    `z0` = cota talpii (implicit 0; adaugat de ok-a pentru socluri pe platforma)."""
    bot = chamfer([(cx - hx, cy - hy), (cx + hx, cy - hy),
                   (cx + hx, cy + hy), (cx - hx, cy + hy)], 0.12)
    top = chamfer([(cx - hx + flare, cy - hy + flare), (cx + hx - flare, cy - hy + flare),
                   (cx + hx - flare, cy + hy - flare), (cx - hx + flare, cy + hy - flare)], 0.12)
    loft(b, bot, z0, top, z0 + h - cap_h, slot)
    capp = [(p[0], p[1]) for p in chamfer(
        [(cx - hx + flare - cap_over, cy - hy + flare - cap_over),
         (cx + hx - flare + cap_over, cy - hy + flare - cap_over),
         (cx + hx - flare + cap_over, cy + hy - flare + cap_over),
         (cx - hx + flare - cap_over, cy + hy - flare + cap_over)], 0.1)]
    loft(b, capp, z0 + h - cap_h, capp, z0 + h, slot)


def gold_finial(b, x, y, z, s=1.0, slot=OK_GOLD):
    """Ornament de coama: soclu conic, bila, flacara. ~0,75*s inaltime."""
    b.frustum((x, y, z + 0.22 * s), 0.26 * s, 0.17 * s, 0.44 * s, slot, segments=8)
    res = bmesh.ops.create_uvsphere(b.bm, u_segments=8, v_segments=6, radius=1.0,
                                    matrix=Matrix.Translation((x, y, z + 0.56 * s))
                                    @ Matrix.Diagonal(Vector((0.22 * s, 0.22 * s, 0.22 * s, 1.0))))
    b._tag(res["verts"], slot)
    b.frustum((x, y, z + 0.86 * s), 0.12 * s, 0.0, 0.40 * s, slot, segments=6)


# ---------------------------------------------------------------------------
# zid de calcar cu talus
# ---------------------------------------------------------------------------

def limestone_wall(b, p0, p1, h, t_base, t_top, slot=OK_LIMESTONE, courses=3,
                   ledge=0.07, crest=0.30, z0=0.0):
    """Zid de calcar drept intre `p0` si `p1` (puncte 2D la sol), inalt de `h`.

    TALUS: grosimea scade de la `t_base` (jos) la `t_top` (creasta), liniar —
    zidul gusuku se inclina spre interior. `courses` asize se citesc ca TREPTE
    (fiecare rand cu o muchie `ledge` mai retrasa decat cel de dedesubt), iar
    creasta se rotunjeste in doua tesituri (`crest` inaltime). Capetele sunt
    PLANE si perpendiculare pe axa, deci doua module cap-la-cap se imbina.
    Return: lista de nivele (z, semigrosime) — pentru teste si capete.
    """
    d = Vector((p1[0] - p0[0], p1[1] - p0[1]))
    L = d.length
    d.normalize()
    nrm = Vector((-d.y, d.x))
    body = h - crest
    levels = []
    for k in range(courses):
        za, zb = body * k / courses, body * (k + 1) / courses
        ta = (t_base + (t_top - t_base) * za / h) * 0.5
        tb = (t_base + (t_top - t_base) * zb / h) * 0.5 - ledge
        levels.append((za, ta, zb, tb))

    def ring(half):
        return [(p0[0] - nrm.x * half, p0[1] - nrm.y * half),
                (p1[0] - nrm.x * half, p1[1] - nrm.y * half),
                (p1[0] + nrm.x * half, p1[1] + nrm.y * half),
                (p0[0] + nrm.x * half, p0[1] + nrm.y * half)]

    for za, ta, zb, tb in levels:
        loft(b, ring(ta), z0 + za, ring(tb), z0 + zb, slot, cap_bottom=(za == 0.0))
    t_c = (t_base + (t_top - t_base) * body / h) * 0.5 - ledge
    t_mid = t_c - crest * 0.35
    t_hi = max(0.05, t_c - crest * 1.0)
    loft(b, ring(t_c), z0 + body, ring(t_mid), z0 + body + crest * 0.55, slot, cap_bottom=False)
    loft(b, ring(t_mid), z0 + body + crest * 0.55, ring(t_hi), z0 + h, slot, cap_bottom=False)
    return [(za, ta) for za, ta, _, _ in levels]


# ---------------------------------------------------------------------------
# emit -- comun tuturor build-urilor Okinawa v2
# ---------------------------------------------------------------------------

OK_RESULTS = []


def emit_ok(objs, path, ao, keep_xy=False, bevel=0.0, smooth_angle=None,
            budget=None, bevel_angle=30.0, bevels=None):
    """Finish pe fiecare nod + export in assets/models/okinawa/<path>.

    Offsetul de origine se calculeaza O DATA pe ansamblu (memoria finish-
    recentreaza-fiecare-nod-separat): `keep_xy=False` centreaza bbox-ul
    ansamblului pe XY, baza ansamblului la Z=0. `bevels` = {sufix_nod: latime}
    suprascrie `bevel` pe nodurile al caror nume se termina cu sufixul."""
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
        bw = bevel
        for suf, w in (bevels or {}).items():
            if o.name.endswith(suf):
                bw = w
        st = finish(o, bevel=bw, bevel_angle=bevel_angle, ao=ao,
                    origin=None, smooth_angle=smooth_angle)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "okinawa/" + path)
    OK_RESULTS.append((path, total, dims, budget, per_node, sz / 1024.0))
    return total


def report_ok():
    print()
    for path, tris, dims, budget, per_node, kb in OK_RESULTS:
        print("%-38s tris=%6d  %.2f x %.2f x %.2f m  %.0f kB" %
              (path, tris, dims.x, dims.y, dims.z, kb))
        print("    noduri:", per_node)


# ===========================================================================
# val 1, ok-a: castelul (palat, ziduri gusuku, poarta boltita)
# ===========================================================================
#
#  inset_convex      contur convex antiorar, retras cu `d` (colturi cu miter)
#  banded_prism      prisma de piatra pe contur: asize cu talus + placa de capat
#  slab_grid         placa de olane pe grila, cu grosime (ca HipRoof, pozitie libera)
#  karahafu          frontonul curbat peste intrare (olane + panou + bordura alba)
#  gold_dragon       ornament de coama in forma de dragon (CAR_YELLOW)
#  gusuku_wall       zid de calcar curb/drept: miez cu sectiune identica la capete +
#                    blocuri fasonate (perne cu rosturi in relief), creasta plata
#  gusuku_n          cota laterala a fetelor la inaltimea z (bolti, bolțari)
#  arch_blocks       bolțari + sambure pentru poarta boltita


def inset_convex(poly, d):
    """Contur convex ANTIORAR retras cu `d` spre interior (miter la colturi).
    Pastreaza numarul de puncte, deci merge cu `loft` intre doua retrageri."""
    n = len(poly)
    out = []
    for i in range(n):
        P = Vector(poly[i])
        e1 = (P - Vector(poly[i - 1]))
        e2 = (Vector(poly[(i + 1) % n]) - P)
        if e1.length < 1e-9 or e2.length < 1e-9:
            out.append((P.x, P.y))
            continue
        e1.normalize()
        e2.normalize()
        n1 = Vector((-e1.y, e1.x))
        n2 = Vector((-e2.y, e2.x))
        m = n1 + n2
        k = 1.0 + n1.dot(n2)
        q = P + m * (d / max(k, 0.2))
        out.append((q.x, q.y))
    return out


def banded_prism(b, outline, z0, h, courses=3, batter=0.05, groove=0.06,
                 cap_h=0.2, cap_over=0.10, slot=OK_LIMESTONE):
    """Soclu/platforma de piatra pe un contur convex antiorar: `courses` asize
    suprapuse. Fiecare asiza porneste usor retrasa (rost de `groove`) si se
    lateste spre varf (se citeste ca perna), iar talusul retrage tot corpul cu
    `batter` m pe metru de inaltime. Deasupra: placa de capat iesita `cap_over`.
    Capatul de sus e la z0 + h. Return: retragerea corpului la cota de sus."""
    body = h - cap_h
    hc = body / courses
    for k in range(courses):
        za, zb = z0 + k * hc, z0 + (k + 1) * hc
        ia = batter * (k * hc) + (groove if k else 0.0)
        ib = batter * ((k + 1) * hc) - 0.02
        loft(b, inset_convex(outline, ia), za, inset_convex(outline, ib), zb, slot,
             cap_bottom=(k == 0))
    ic = batter * body - 0.02 - cap_over
    cap = inset_convex(outline, ic)
    loft(b, cap, z0 + body, cap, z0 + h, slot, cap_bottom=False)
    return batter * body - 0.02


def slab_grid(rb, nu, nv, pos, th, slot):
    """Placa cu grosime pe grila (nu x nv): `pos(i, j)` -> (x, y, z_sus); `i` creste
    pe X, `j` pe Y. Fata de sus, cea de jos si cantul pe acelasi slot."""
    top, bot = {}, {}
    for i in range(nu + 1):
        for j in range(nv + 1):
            x, y, z = pos(i, j)
            top[(i, j)] = rb.bm.verts.new((x, y, z))
            bot[(i, j)] = rb.bm.verts.new((x, y, z - th))

    def quad(a, b_, c, d):
        f = rb.bm.faces.new([a, b_, c, d])
        f[rb.slot] = slot
    for i in range(nu):
        for j in range(nv):
            quad(top[(i, j)], top[(i + 1, j)], top[(i + 1, j + 1)], top[(i, j + 1)])
            quad(bot[(i, j + 1)], bot[(i + 1, j + 1)], bot[(i + 1, j)], bot[(i, j)])
    for i in range(nu):
        quad(top[(i, 0)], bot[(i, 0)], bot[(i + 1, 0)], top[(i + 1, 0)])
        quad(top[(i + 1, nv)], bot[(i + 1, nv)], bot[(i, nv)], top[(i, nv)])
    for j in range(nv):
        quad(top[(0, j + 1)], bot[(0, j + 1)], bot[(0, j)], top[(0, j)])
        quad(top[(nu, j)], bot[(nu, j)], bot[(nu, j + 1)], top[(nu, j + 1)])


def _ogee(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def karahafu(rb, mb, fb, cx, y_front, y_back, z_e, w, hr, th=0.2, slope=0.18,
             step=0.28, panel_drop=0.55, slot_face=OK_LACQUER):
    """Fronton curbat (karahafu) peste intrare. Acoperis in doua ape cu coama pe
    Y; marginea din fata e o curba in S (ogee): concava spre streasina, convexa
    spre varf. `z_e` = cota streasinii (colturile), `hr` = inaltimea varfului,
    `w` = semilatimea. Panoul rosu de sub curba (`fb`), bordura alba (`mb`).
    Return: (x, y, z) al varfului din fata, pentru ornament."""
    nu = max(8, 2 * int(round(w / step)))
    nv = max(2, int(round((y_front - y_back) / 0.5)))

    def zt(x, y):
        return z_e + hr * _ogee(1.0 - abs(x) / w) + slope * (y_front - y)

    def pos(i, j):
        x = cx - w + 2.0 * w * i / nu
        y = y_back + (y_front - y_back) * j / nv
        return (x, y, zt(x - cx, y))
    slab_grid(rb, nu, nv, pos, th, OK_TILE)
    pts = []
    for i in range(nu + 1):
        x = -w + 2.0 * w * i / nu
        pts.append((cx + x, y_front, zt(x, y_front) + 0.06))
    for a, c in zip(pts, pts[1:]):
        mb.beam(a, c, (0.2, 0.22), OK_MORTAR)
    poly = []
    for i in range(nu + 1):
        x = -w + 2.0 * w * i / nu
        poly.append((cx + x, zt(x, y_front) - th - 0.02))
    poly.append((cx + w - 0.1, z_e - panel_drop))
    poly.append((cx - w + 0.1, z_e - panel_drop))
    prism_xz(fb, poly, y_front - 0.45, y_front - 0.12, slot_face)
    return (cx, y_front - 0.05, zt(0.0, y_front) + 0.04)


def gold_dragon(b, x, y, z, s=1.0, d=1.0, slot=OK_GOLD):
    """Dragon de coama (CAR_YELLOW): soclu, corp in S care urca si se arcuieste
    spre exterior (`d` = +1 capul spre +X, -1 spre -X), cap cu bot si coarne,
    coada rasucita spre interior, trei aripioare pe spate. ~1,6*s inaltime."""
    b.box((x, y, z + 0.14 * s), (0.9 * s, 0.6 * s, 0.28 * s), slot)

    def P(px, pz):
        return (x + px * d * s, y, z + pz * s)
    body = [P(-0.05, 0.25), P(-0.05, 0.65), P(0.10, 1.05), P(0.42, 1.38),
            P(0.82, 1.40), P(1.08, 1.18)]
    b.taper_sweep(body, [0.42 * s, 0.40 * s, 0.36 * s, 0.30 * s, 0.26 * s, 0.22 * s],
                  slot, segments=8, cap_start=False, cap_end=True)
    tail = [P(-0.10, 0.45), P(-0.50, 0.62), P(-0.78, 1.00), P(-0.66, 1.42),
            P(-0.34, 1.52), P(-0.16, 1.40)]
    b.taper_sweep(tail, [0.28 * s, 0.24 * s, 0.20 * s, 0.15 * s, 0.09 * s, 0.0],
                  slot, segments=6, cap_start=False, cap_end=True)
    b.frustum((x + 1.28 * d * s, y, z + 1.04 * s), 0.20 * s, 0.12 * s, 0.52 * s, slot,
              segments=8, axis="X")
    b.frustum((x + 1.52 * d * s, y, z + 0.98 * s), 0.12 * s, 0.07 * s, 0.30 * s, slot,
              segments=6, axis="X")
    for sy in (-1, 1):
        b.frustum((x + 1.02 * d * s, y + sy * 0.15 * s, z + 1.50 * s), 0.07 * s, 0.0,
                  0.46 * s, slot, segments=5)
    for k in range(3):
        px = 0.05 + 0.26 * k
        pz = 0.95 + 0.42 * k
        b.frustum((x + px * d * s, y, z + pz * s + 0.25 * s), 0.10 * s, 0.0, 0.5 * s,
                  slot, segments=5)


# ---------------------------------------------------------------------------
# zidul gusuku: sectiune trasa pe un traseu
# ---------------------------------------------------------------------------

GUSUKU = dict(h=8.0, t_base=2.5, t_top=1.6, b_out=0.75, b_in=0.15,
              z_crest=7.55, cap_over=0.10, n_courses=11)


def gusuku_n(z, sign, spec=GUSUKU):
    """Cota laterala (suprafata miezului, fara bombarea blocurilor) a fetei `sign`
    (+1 = exterioara, convexa, cu talus; -1 = interioara) la inaltimea z."""
    half = spec["t_base"] * 0.5
    bb = spec["b_out"] if sign > 0 else spec["b_in"]
    return sign * (half - bb * z / spec["h"])


def _lcg_f(seed):
    s = [seed & 0x7FFFFFFF]

    def r():
        s[0] = (s[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return s[0] / float(0x7FFFFFFF)
    return r


def gusuku_course_z(spec=GUSUKU):
    """Cotele asizelor (n+1 valori): 11 randuri de ~0,6-0,8 m, mai inalte jos."""
    n = spec["n_courses"]
    hs = [0.82 - 0.22 * k / (n - 1) for k in range(n)]
    sc = spec["z_crest"] / sum(hs)
    zs = [0.0]
    for h_ in hs:
        zs.append(zs[-1] + h_ * sc)
    return zs


def gusuku_wall(b, kind, length=12.0, R=None, chord=16.0, slot=OK_LIMESTONE,
                seed=7, spec=GUSUKU, ds=1.0, exclude=None, groove=0.05,
                proud=0.055, block_len=1.15, core=True, blocks=True):
    """Zid de calcar gusuku pe un traseu: 'straight' (pe Y, `length`, axa la x=0)
    sau 'arc' (raza `R`, coarda `chord` pe Y, burta spre +X, capetele la
    (0, +-chord/2)).

    MIEZUL = sectiune identica pe tot traseul (capete plane, perpendiculare pe
    tangenta, deci modulele se inlantuie): fata exterioara (+X) cu talus, fata
    interioara aproape verticala, creasta PLATA cu un rand de capac iesit
    `cap_over`. PESTE miez, pe ambele fete, blocuri fasonate (`n_courses` asize
    de ~0,7 m, blocuri de 0,8-1,5 m, decalate de la un rand la altul), fiecare
    o perna cu fete plate si rosturi in relief (`proud` m iesit, `groove` m
    rost). Randurile pare au blocurile de capat FARA rost spre capat: doua
    module vecine formeaza acolo un bloc continuu, cele impare au rost, deci
    imbinarea e decalata ca restul zidariei. `exclude(a0, a1, za, zb, sign)` ->
    True sare blocul (deschiderea de la poarta). Return: dict cu cadrele."""
    h = spec["h"]
    zc = spec["z_crest"]
    co = spec["cap_over"]
    if kind == "arc":
        phi0 = math.asin(chord * 0.5 / R)
        A = R * phi0
        cxr = -math.sqrt(R * R - (chord * 0.5) ** 2)

        def frame(a):
            ph = a / R
            return ((cxr + R * math.cos(ph), R * math.sin(ph)),
                    (math.cos(ph), math.sin(ph)))
    else:
        phi0 = 0.0
        A = length * 0.5

        def frame(a):
            return ((0.0, a), (1.0, 0.0))

    # --- miezul
    if core:
        n_o0, n_i0 = gusuku_n(0.0, +1, spec), gusuku_n(0.0, -1, spec)
        n_oc, n_ic = gusuku_n(zc, +1, spec), gusuku_n(zc, -1, spec)
        section = [(n_o0, 0.0), (n_oc, zc), (n_oc + co, zc), (n_oc + co, h),
                   (n_ic - co, h), (n_ic - co, zc), (n_ic, zc), (n_i0, 0.0)]
        n_u = max(2, int(math.ceil(2 * A / ds)))
        samples = [-A + 2 * A * i / n_u for i in range(n_u + 1)]
        made = []
        rings = []
        for a in samples:
            (px, py), (nx, ny) = frame(a)
            rings.append([b.bm.verts.new((px + nx * n, py + ny * n, z)) for (n, z) in section])
        m = len(section)
        for r in range(len(rings) - 1):
            for i in range(m):
                j = (i + 1) % m
                f = b.bm.faces.new([rings[r][i], rings[r][j], rings[r + 1][j], rings[r + 1][i]])
                f[b.slot] = slot
                made.append(f)
        for ring in (list(reversed(rings[0])), list(rings[-1])):
            f = b.bm.faces.new(ring)
            f[b.slot] = slot
            made.append(f)
        bmesh.ops.recalc_face_normals(b.bm, faces=made)

    # --- blocurile
    nblocks = 0
    if not blocks:
        return dict(A=A, blocks=0, courses=0, end_tangent_deg=math.degrees(phi0))
    rnd = _lcg_f(seed)
    zs = gusuku_course_z(spec)

    def pos(a, z, sign, off):
        (px, py), (nx, ny) = frame(a)
        n = gusuku_n(z, sign, spec) + sign * off
        return (px + nx * n, py + ny * n, z)

    def bounds(k):
        if k % 2 == 0:
            f0, f1 = 0.35 + rnd() * 0.45, 0.35 + rnd() * 0.45
        else:
            f0 = f1 = 0.0
        mid = 2 * A - f0 - f1
        nb = max(1, int(round(mid / block_len)))
        ws = [0.75 + rnd() * 0.5 for _ in range(nb)]
        sc = mid / sum(ws)
        out = [-A]
        if f0 > 0:
            out.append(-A + f0)
        for w_ in ws:
            out.append(out[-1] + w_ * sc)
        if f1 > 0:
            out.append(A)
        out[-1] = A
        return out

    nblocks = 0
    for k in range(len(zs) - 1):
        za, zb = zs[k], zs[k + 1]
        bd = bounds(k)
        flush = (k % 2 == 0)
        for i in range(len(bd) - 1):
            a0, a1 = bd[i], bd[i + 1]
            fl0 = flush and i == 0
            fl1 = flush and i == len(bd) - 2
            for sign in (+1, -1):
                if exclude and exclude(a0, a1, za, zb, sign):
                    continue
                jt = lambda: (rnd() - 0.5) * 0.03
                pr = proud * (0.7 + 0.6 * rnd())
                u0 = a0 + (0.0 if fl0 else groove + jt())
                u1 = a1 - (0.0 if fl1 else groove + jt())
                v0 = za + groove + jt()
                v1 = zb - groove + jt()
                base = [b.bm.verts.new(pos(a0, za, sign, 0)), b.bm.verts.new(pos(a1, za, sign, 0)),
                        b.bm.verts.new(pos(a1, zb, sign, 0)), b.bm.verts.new(pos(a0, zb, sign, 0))]
                top = [b.bm.verts.new(pos(u0, v0, sign, pr)), b.bm.verts.new(pos(u1, v0, sign, pr)),
                       b.bm.verts.new(pos(u1, v1, sign, pr)), b.bm.verts.new(pos(u0, v1, sign, pr))]
                (_, _), (nx, ny) = frame((a0 + a1) * 0.5)
                outd = Vector((sign * nx, sign * ny, 0.0))
                cen = sum((v.co for v in top), Vector()) / 4.0
                faces = [(top, 0)]
                for e in range(4):
                    if (e == 3 and fl0) or (e == 1 and fl1):
                        continue
                    j = (e + 1) % 4
                    faces.append(([base[e], base[j], top[j], top[e]], 1))
                for vl, kind_ in faces:
                    f = b.bm.faces.new(vl)
                    f[b.slot] = slot
                    f.normal_update()
                    if kind_ == 0:
                        want = outd
                    else:
                        fc = sum((v.co for v in vl), Vector()) / 4.0
                        want = fc - cen
                    if f.normal.dot(want) < 0:
                        f.normal_flip()
                nblocks += 1
    return dict(A=A, blocks=nblocks, courses=len(zs) - 1,
                end_tangent_deg=math.degrees(phi0))


def arch_blocks(b, cy, zs, r_in, r_out, n, slot=OK_LIMESTONE, key_extra=0.2,
                gap=0.014, proud=0.07, spec=GUSUKU, jamb_z=(0.0, 0.7, 1.4, 2.1),
                pil=0.05, shrink=0.88):
    """Bolta de piatra: `n` bolțari in semicerc (centru la y=cy, z=zs), cu cheia
    de bolta mai inalta, plus samburele (blocuri sub linia de nastere). Adancimea
    urmeaza talusul cu `proud` iesit pe fiecare fata; fiecare fata are aceeasi
    perna cu rost in relief ca zidaria (`pil` m, colturile trase spre centru cu
    `shrink`). Cutii inchise."""
    def xs(z):
        return (gusuku_n(z, -1, spec) - proud, gusuku_n(z, +1, spec) + proud)

    def block(corners):
        back, front, pb, pf = [], [], [], []
        cy_ = sum(c[0] for c in corners) / 4.0
        cz_ = sum(c[1] for c in corners) / 4.0
        for (y, z) in corners:
            xb, xf = xs(z)
            back.append(b.bm.verts.new((xb, y, z)))
            front.append(b.bm.verts.new((xf, y, z)))
            yy, zz = cy_ + (y - cy_) * shrink, cz_ + (z - cz_) * shrink
            pb.append(b.bm.verts.new((xb - pil, yy, zz)))
            pf.append(b.bm.verts.new((xf + pil, yy, zz)))
        allv = back + front + pb + pf
        cen = sum((v.co for v in allv), Vector()) / len(allv)
        lists = [pb, pf]
        for e in range(4):
            j = (e + 1) % 4
            lists.append([back[e], back[j], front[j], front[e]])
            lists.append([back[e], back[j], pb[j], pb[e]])
            lists.append([front[e], front[j], pf[j], pf[e]])
        for vl in lists:
            f = b.bm.faces.new(vl)
            f[b.slot] = slot
            f.normal_update()
            fc = sum((v.co for v in vl), Vector()) / len(vl)
            if f.normal.dot(fc - cen) < 0:
                f.normal_flip()

    for i in range(n):
        ta = math.pi * i / n + gap
        tb = math.pi * (i + 1) / n - gap
        ro = r_out + (key_extra if i == n // 2 else 0.0)
        block([(cy + r_in * math.cos(ta), zs + r_in * math.sin(ta)),
               (cy + r_in * math.cos(tb), zs + r_in * math.sin(tb)),
               (cy + ro * math.cos(tb), zs + ro * math.sin(tb)),
               (cy + ro * math.cos(ta), zs + ro * math.sin(ta))])
    zl = list(jamb_z) + [zs]
    for sg in (-1, 1):
        for k in range(len(zl) - 1):
            za, zb = zl[k] + 0.02, zl[k + 1] - 0.02
            ya, yb = cy + sg * r_in, cy + sg * r_out
            block([(ya, za), (ya, zb), (yb, zb), (yb, za)])


def prism_yz(b, poly, x0, x1, slot):
    """Prisma inchisa: conturul `poly` (y, z) extrudat pe X intre x0 si x1
    (omoloaga lui `prism_xz`); orientarea fetelor se decide din normala laturii."""
    n = len(poly)
    area = sum(poly[i][0] * poly[(i + 1) % n][1] - poly[(i + 1) % n][0] * poly[i][1]
               for i in range(n)) * 0.5
    sg = 1.0 if area > 0 else -1.0
    for i in range(n):
        j = (i + 1) % n
        dy, dz = poly[j][0] - poly[i][0], poly[j][1] - poly[i][1]
        if abs(dy) + abs(dz) < 1e-7:
            continue
        f = _face(b, [(x0, poly[i][0], poly[i][1]), (x0, poly[j][0], poly[j][1]),
                      (x1, poly[j][0], poly[j][1]), (x1, poly[i][0], poly[i][1])], slot)
        want = Vector((0.0, dz * sg, -dy * sg))
        if f.normal.dot(want) < 0:
            bmesh.ops.reverse_faces(b.bm, faces=[f])
    for xx, nx in ((x1, 1.0), (x0, -1.0)):
        f = _face(b, [(xx, p[0], p[1]) for p in poly], slot)
        res = bmesh.ops.triangulate(b.bm, faces=[f], quad_method="BEAUTY", ngon_method="EAR_CLIP")
        for t in res["faces"]:
            t.normal_update()
            if t.normal.x * nx < 0:
                bmesh.ops.reverse_faces(b.bm, faces=[t])


def wall_to_roof(b, roof, axis, c, a0, a1, z0, thick, slot=OK_LACQUER, step=0.8,
                 clearance=0.08):
    """Perete plin sub un acoperis in patru ape: marginea de sus urmeaza fata de
    JOS a placii de olane (`roof.z - roof.th`), deci nu ramane gol sub streasina
    si nu iese perete prin olane. `axis` = 'x': peretele merge pe X la y=c, intre
    a0 si a1; 'y': merge pe Y la x=c. `z0` = baza, `thick` = grosimea."""
    n = max(2, int(math.ceil(abs(a1 - a0) / step)))
    top = []
    for i in range(n + 1):
        a = a0 + (a1 - a0) * i / n
        x, y = (a, c) if axis == "x" else (c, a)
        top.append((a, roof.z(x, y) - roof.th + clearance))
    poly = [(a1, z0), (a0, z0)] + top
    if axis == "x":
        prism_xz(b, poly, c - thick * 0.5, c + thick * 0.5, OK_LACQUER if slot is None else slot)
    else:
        prism_yz(b, poly, c - thick * 0.5, c + thick * 0.5, OK_LACQUER if slot is None else slot)
