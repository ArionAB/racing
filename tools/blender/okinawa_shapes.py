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


def _split_all_edges(o):
    """Fiecare fata isi are vertecsii ei (umbrire PLATA): AO-ul copt pe vertex
    nu mai curge intre fete vecine."""
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.split_edges(bm, edges=bm.edges[:])
    bm.to_mesh(o.data)
    bm.free()
    o.data.update()


def _flatten_ao(o):
    """Dupa coacere: AO-ul fiecarei fete = media vertecsilor ei (o singura
    valoare pe fata, ca facetele sa se citeasca drept plane)."""
    me = o.data
    ca = me.color_attributes["AO"]
    for poly in me.polygons:
        vs = list(poly.vertices)
        v = sum(ca.data[i].color[0] for i in vs) / len(vs)
        for i in vs:
            ca.data[i].color = (v, v, v, 1.0)


def emit_ok(objs, path, ao, keep_xy=False, bevel=0.0, smooth_angle=None,
            budget=None, bevel_angle=30.0, bevels=None, flat_ao=False):
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
        if flat_ao:
            _split_all_edges(o)
        st = finish(o, bevel=bw, bevel_angle=bevel_angle, ao=ao,
                    origin=None, smooth_angle=smooth_angle)
        if flat_ao:
            _flatten_ao(o)
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


# ---------------------------------------------------------------------------
# vegetatie Ryukyu (kit v2 §1.3, ok-c): coloana de frunzis, perne, evantai,
# frunza dintata, trunchi cu inele
# ---------------------------------------------------------------------------

def foliage_column(b, H, W, slot, n, z0=0.8, tip="round", seed=1, sat=3,
                   sat_scale=0.34, wobble=0.04, seg=10, rings=5):
    """Fukugi: STALP dens de frunzis (corectura de coordonator, nu coroana
    rotunda de pe planse). `n` mase elipsoidale suprapuse pe verticala intre
    cotele `z0` (unde incepe frunzisul, ~0,8 m: sub el se vede doar ciotul) si
    `H`; fiecare masa poarta `sat` ciorchini mici pe margine, care umplu
    conturul pana la raza W/2 -- laturile ies aproape drepte, cu valuri usoare
    (`wobble`: masele pare/impare alterneaza +-). `tip`: "round" = varf
    rotunjit, "sharp" = ultimele mase se ingusteaza si cea de sus e inalta.
    Masele sunt `boulder` (elipsoid inchis), NU `rock` (con: lectia banyanului).
    Returneaza lista (cz, rz, raza_orizontala) a maselor, pentru piese care
    adauga mase laterale."""
    half = W * 0.5
    S = H - z0
    rz = 1.38 * S / (n + 1)
    rnd = _lcg(seed)
    prof = [1.0] * n
    rzs = [rz] * n
    prof[0] = 0.9
    if tip == "round":
        prof[-1] = 0.78
        if n > 2:
            prof[-2] = 0.97
    else:  # sharp
        prof[-1] = 0.40
        rzs[-1] = rz * 1.45
        if n > 2:
            prof[-2] = 0.66
        if n > 3:
            prof[-3] = 0.88
    cs = []
    for i in range(n):
        if i == 0:
            cs.append(z0 + rzs[0])
        elif i == n - 1:
            cs.append(H - rzs[i])
        else:
            lo, hi = cs[0], H - rzs[-1]
            cs.append(lo + (hi - lo) * i / (n - 1))
    out = []
    for i in range(n):
        wob = 1.0 + wobble * (1.0 if i % 2 else -1.0)
        rx = half * 0.90 * prof[i] * wob
        cz = cs[i]
        b.boulder((0.0, 0.0, cz), (2 * rx, 2 * rx * 0.95, 2 * rzs[i]), slot,
                  seed=seed * 31 + i * 7, segments=seg, rings=rings,
                  deviation=0.13)
        s = sat_scale * W
        base = rnd() * 6.28
        for k in range(sat):
            a = base + k * 2 * math.pi / sat + (rnd() - 0.5) * 0.8
            dz = rzs[i] * (rnd() * 1.5 - 0.75)
            surf = rx * math.sqrt(max(0.0, 1.0 - (dz / rzs[i]) ** 2))
            r = max(0.0, surf - s * 0.12) * prof[i] ** 0.0
            sz = s * (0.85 + 0.35 * rnd())
            b.boulder((math.cos(a) * r, math.sin(a) * r, cz + dz),
                      (sz, sz * 0.92, sz * 0.78), slot,
                      seed=seed * 53 + i * 11 + k, segments=7, rings=2,
                      deviation=0.15)
        out.append((cz, rzs[i], rx))
    return out


def foliage_pillow(b, center, w, d, h, slot, seed=0, bumps=2, seg=9, rings=4,
                   tilt_deg=0.0, tilt_azim_deg=0.0):
    """Perna de frunzis turtita (pin Ryukyu, bonsai): elipsoid lat si plat, cu
    `bumps` umflaturi pe fata de sus ca sa nu iasa lentila. Inclinata cu
    `tilt_deg` spre azimutul dat. Aceeasi familie ca `boulder`."""
    rnd = _lcg(seed * 17 + 5)
    faces = b.boulder((0, 0, 0), (w, d, h), slot, seed=seed, segments=seg,
                      rings=rings, deviation=0.15)
    verts = {v for f in faces for v in f.verts}
    for k in range(bumps):
        a = rnd() * 6.28
        r = rnd() * 0.28 * w
        bf = b.boulder((math.cos(a) * r, math.sin(a) * r * d / w, h * 0.22),
                       (w * 0.42, d * 0.42, h * 0.8), slot, seed=seed + 3 + k,
                       segments=7, rings=3, deviation=0.14)
        verts |= {v for f in bf for v in f.verts}
    a = math.radians(tilt_azim_deg)
    axis = Vector((-math.sin(a), math.cos(a), 0.0))
    rot = Matrix.Rotation(math.radians(tilt_deg), 3, axis)
    for v in verts:
        v.co = rot @ v.co + Vector(center)


def ring_trunk(b, path, radii, slot, slot_ring, ring_every=0.35, seg=7,
               ring_grow=1.25, ring_h=0.14):
    """Trunchi cu INELE in geometrie (palmier-evantai, cicada): `taper_sweep`
    plus, la fiecare `ring_every` metri pe traseu, un inel (frustum scurt, mai
    gros cu `ring_grow`) in `slot_ring`. Traseul se interpoleaza liniar pe
    segmente pentru raza si pozitie."""
    b.taper_sweep(path, radii, slot, segments=seg)
    pts = [Vector(p) for p in path]
    lens = [(pts[i + 1] - pts[i]).length for i in range(len(pts) - 1)]
    total = sum(lens)
    s = ring_every * 0.5
    while s < total - 0.1:
        acc = 0.0
        for i, L in enumerate(lens):
            if acc + L >= s:
                t = (s - acc) / L
                p = pts[i].lerp(pts[i + 1], t)
                r = radii[i] + (radii[i + 1] - radii[i]) * t
                b.frustum((p.x, p.y, p.z), r * ring_grow, r * ring_grow * 0.97,
                          ring_h, slot_ring, segments=seg)
                break
            acc += L
        s += ring_every


def pleated_fan(b, c, u, n, R, slot, pleats=7, span_deg=250.0, depth=0.07,
                th=0.035, valley=0.80):
    """Frunza de palmier-evantai: disc plisat (nu frunza penata). Pornind din
    `c` (capatul petiolului) se desface in evantai cu centrul pe directia `u`,
    in planul normal la `n`; `pleats` pliuri (creasta/vale alternante, cu
    marginea dintata: valea e la `valley`*R). Corp INCHIS cu grosime `th`
    (backface culling: o frunza dintr-un singur strat dispare de dedesubt).
    Cost: ~100 tri la 7 pliuri."""
    c = Vector(c)
    u = Vector(u).normalized()
    n = Vector(n)
    n = (n - u * n.dot(u)).normalized()
    v = n.cross(u)
    M = pleats * 2
    span = math.radians(span_deg)

    def pt(i, rf, off):
        a = -span * 0.5 + span * i / M
        ridge = (i % 2 == 0)
        r = R * rf * (1.0 if ridge else valley)
        o = depth * R * (1.0 if ridge else -1.0) * min(1.0, rf * 1.6)
        return c + (u * math.cos(a) + v * math.sin(a)) * r + n * (o + off)

    layers = []
    for off in (th * 0.5, -th * 0.5):
        cen = b.bm.verts.new(c + n * off)
        mid = [b.bm.verts.new(pt(i, 0.5, off)) for i in range(M + 1)]
        out = [b.bm.verts.new(pt(i, 1.0, off)) for i in range(M + 1)]
        layers.append((cen, mid, out))
    (ct, mt, ot), (cb, mb, ob) = layers
    for i in range(M):
        b.bm.faces.new((ct, mt[i], mt[i + 1]))
        b.bm.faces.new((mt[i], ot[i], ot[i + 1], mt[i + 1]))
        b.bm.faces.new((cb, mb[i + 1], mb[i]))
        b.bm.faces.new((mb[i], mb[i + 1], ob[i + 1], ob[i]))
        b.bm.faces.new((ot[i], ob[i], ob[i + 1], ot[i + 1]))
    for i in (0, M):
        poly = [ct, mt[i], ot[i], ob[i], mb[i], cb]
        if i == 0:
            poly = list(reversed(poly))
        b.bm.faces.new(poly)
    b._tag([ct, cb] + mt + ot + mb + ob, slot)


def serrated_frond(b, base, azim_deg, length, width, elev_deg, slot,
                   stations=9, droop=0.45, fold_deg=18.0, thick=0.025,
                   tooth=0.35):
    """Frunza rigida penata (cicada): doua jumatati de lama V-pliate (ca
    `leaf_vfold`), dar cu latimea ALTERNAND mare/mica pe statii -- marginea
    dintata citeste ca foliole fara sa platim 12 lame per frunza. Pleaca din
    `base` sub `elev_deg` fata de orizontala spre `azim_deg` si cade sub
    greutate (`droop` * L * t^2). Cost: 2 * (4*(stations-1) + 2) tri."""
    a = math.radians(azim_deg)
    e = math.radians(elev_deg)
    dh = Vector((math.cos(a), math.sin(a), 0.0))
    path, widths = [], []
    for i in range(stations):
        t = i / float(stations - 1)
        path.append(Vector(base) + dh * (length * t * math.cos(e)) + Vector(
            (0, 0, length * t * math.sin(e) - droop * length * t * t)))
        if i == stations - 1:
            widths.append(0.0)
        elif i == 0:
            widths.append(width * 0.10)
        else:
            env = width * (0.30 + 0.70 * math.sin(math.pi * min(1.0, 0.12 + t * 0.88)) ** 0.7)
            widths.append(env * (1.0 if i % 2 else tooth))
    for sign in (1.0, -1.0):
        up = Matrix.Rotation(math.radians(fold_deg) * sign, 4, dh) @ Vector((0.0, 0.0, 1.0))
        b.blade(path, widths, thick, slot, up=up, side_bias=sign)


# ---------------------------------------------------------------------------
# runda 4 (cerere coordonator): frunzis din CIORCHINI fatetati
# ---------------------------------------------------------------------------

def column_ellipsoids(H, W, n, z0=0.8, tip="round", seed=1, wobble=0.04, fill=0.86):
    """Aceeasi schema ca `foliage_column` (n mase pe verticala intre z0 si H,
    varf rotunjit/ascutit), dar intoarce doar elipsoizii ca lista
    (cx, cy, cz, rx, ry, rz): anvelopa pe care o acopera `foliage_clumps`.
    `fill` = cat din W/2 ocupa masa (restul il dau ciorchinii care ies)."""
    half = W * 0.5
    S = H - z0
    rz = 1.38 * S / (n + 1)
    prof = [1.0] * n
    rzs = [rz] * n
    prof[0] = 0.9
    if tip == "round":
        prof[-1] = 0.78
        if n > 2:
            prof[-2] = 0.97
    else:
        prof[-1] = 0.40
        rzs[-1] = rz * 1.45
        if n > 2:
            prof[-2] = 0.66
        if n > 3:
            prof[-3] = 0.88
    cs = []
    for i in range(n):
        if i == 0:
            cs.append(z0 + rzs[0])
        elif i == n - 1:
            cs.append(H - rzs[i])
        else:
            lo, hi = cs[0], H - rzs[-1]
            cs.append(lo + (hi - lo) * i / (n - 1))
    out = []
    for i in range(n):
        rx = half * fill * prof[i] * (1.0 + wobble * (1.0 if i % 2 else -1.0))
        out.append((0.0, 0.0, cs[i], rx, rx * 0.95, rzs[i]))
    return out


def ellipsoid_anchors(ells, per, seed, el_lo=-0.6, el_hi=1.0, bury=0.9, max_n=None):
    """Puncte pe suprafata unor elipsoizi (lista (cx,cy,cz,rx,ry,rz)), cu
    normala lor; cele ingropate in alt elipsoid (`bury` = fractiunea razei) se
    arunca. `per` candidati per elipsoid, elevatie aleatoare in [el_lo, el_hi]
    (sinus), azimut pe spirala aurie + zgomot. `max_n` taie lista (determinist)."""
    rnd = _lcg(seed * 13 + 1)
    out = []
    for ei, (cx, cy, cz, rx, ry, rz) in enumerate(ells):
        ph = rnd() * 6.28
        for k in range(per):
            s = el_lo + (el_hi - el_lo) * ((k + rnd() * 0.8) / per)
            c = math.sqrt(max(0.0, 1.0 - s * s))
            th = ph + k * 2.399963 + rnd() * 0.5
            d = Vector((rx * c * math.cos(th), ry * c * math.sin(th), rz * s))
            p = Vector((cx, cy, cz)) + d
            hidden = False
            for j, (jx, jy, jz, jrx, jry, jrz) in enumerate(ells):
                if j == ei:
                    continue
                q = ((p.x - jx) / jrx) ** 2 + ((p.y - jy) / jry) ** 2 + ((p.z - jz) / jrz) ** 2
                if q < bury * bury:
                    hidden = True
                    break
            if hidden:
                continue
            nrm = Vector((d.x / rx ** 2, d.y / ry ** 2, d.z / rz ** 2)).normalized()
            out.append((p, nrm))
    if max_n and len(out) > max_n:
        keyed = sorted(range(len(out)), key=lambda i: _lcg(seed * 7 + i)())
        keep = sorted(keyed[:max_n])
        out = [out[i] for i in keep]
    return out


def foliage_clumps(b_main, b_tip, anchors, size, slot_main, slot_tip, seed,
                   tip_frac=0.28, push=0.10, flat=0.5, seg=6, rings=3,
                   xform=None, jitter=0.35, size_var=0.25, deviation=0.18):
    """ENVELOPA de ciorchini: pe fiecare ancora (pozitie, normala) se pune un
    ciorchine fatetat TURTIT (boulder `size` x ~`size` x `size*flat`, grosimea
    pe normala), cu spin aleator in jurul normalei si normala usor zdruncinata
    (`jitter`) -> conturul iese zimtat, cu umbra intre ciorchini. Ciorchinii cu
    normala cea mai in sus (~`tip_frac`, ordonati dupa n.z + zgomot) merg in
    `b_tip` pe `slot_tip` (al doilea ton); restul in `b_main`. `xform`
    (Matrix 4x4) muta ancorele (ex. perna inclinata). Intoarce (n_main, n_tip)."""
    rnd = _lcg(seed * 7 + 3)
    items = []
    for pos, nrm in anchors:
        if xform is not None:
            pos = xform @ pos
            nrm = (xform.to_3x3() @ nrm).normalized()
        items.append((pos, nrm))
    order = sorted(range(len(items)), key=lambda i: -(items[i][1].z + (rnd() - 0.5) * 0.5))
    n_tip = int(round(len(items) * tip_frac)) if b_tip is not None else 0
    tips = set(order[:n_tip])
    cm = ct = 0
    for i, (pos, nrm) in enumerate(items):
        bld, slot = (b_tip, slot_tip) if i in tips else (b_main, slot_main)
        s = size * (1.0 + size_var * (rnd() * 2 - 1))
        faces = bld.boulder((0, 0, 0), (s, s * (0.85 + 0.3 * rnd()), s * flat), slot,
                            seed=seed * 101 + i, segments=seg, rings=rings,
                            deviation=deviation)
        verts = {v for f in faces for v in f.verts}
        nj = (nrm + Vector((rnd() - 0.5, rnd() - 0.5, rnd() - 0.5)) * jitter).normalized()
        rot = Matrix.Rotation(rnd() * 6.28, 3, nj) @ Vector((0, 0, 1)).rotation_difference(nj).to_matrix()
        for v in verts:
            v.co = rot @ v.co + pos + nj * (push * s)
        if i in tips:
            ct += 1
        else:
            cm += 1
    return cm, ct


def pinnate_frond(b, base, azim_deg, length, width, elev_deg, slot, stations=41,
                  droop=0.6, roll_deg=25.0, thick=0.02, tooth=0.10):
    """Frunza penata de cicada: O nervura arcuita (cade spre varf cu `droop`),
    o singura lama a carei latime ALTERNEAZA mare/mica pe `stations` statii ->
    foliole inguste, dese, ca un pieptene pe ambele parti (~stations/2 perechi),
    pentru ~4*stations triunghiuri. `roll_deg` inclina planul lamei."""
    a = math.radians(azim_deg)
    e = math.radians(elev_deg)
    dh = Vector((math.cos(a), math.sin(a), 0.0))
    path, widths = [], []
    for i in range(stations):
        t = i / float(stations - 1)
        path.append(Vector(base) + dh * (length * t * math.cos(e)) + Vector(
            (0, 0, length * t * math.sin(e) - droop * length * t * t)))
        env = width * min(1.0, t * 7.0 + 0.15) * (1.0 - t ** 2.3)
        if i == stations - 1:
            widths.append(0.0)
        else:
            widths.append(env if i % 2 else env * tooth)
    up = Matrix.Rotation(math.radians(roll_deg), 4, dh) @ Vector((0.0, 0.0, 1.0))
    b.blade(path, widths, thick, slot, up=up, side_bias=0.0)

# calcar roas de val: corp fatetat din inele (ok-b, coasta)
# ---------------------------------------------------------------------------
# Vocabular comun pentru stancile-ciuperca, stanca-inima si faleza: un corp din
# INELE cu profil (z, raza), centru deplasabil (aplecare) si zgomot determinist.
# Inelele alterneaza decalate cu jumatate de pas unghiular, iar fetele sunt
# TRIUNGHIURI: iese suprafata fatetata (low-poly), nu cilindru neted.

def _ok_rand(seed):
    state = [(seed * 1103515245 + 12345) & 0x7FFFFFFF]

    def rand():
        state[0] = (state[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return state[0] / 0x7FFFFFFF
    return rand


def ring_points(rings, seg, seed=0, jag=0.06, bite=None):
    """Punctele inelelor. `rings` = lista de (z, rx, ry, cx, cy). Returneaza
    (puncte[k][i] ca Vector, centre[k]). Zgomotul: o deviatie per coloana
    (continua pe verticala, ca fetele sa fie late) x una per inel. `bite` =
    (z0, z1, adancime, unghi_rad): in intervalul de z, raza scade pana la
    `adancime` (fractie) pe directia `unghi` (nisa roasa dintr-o parte)."""
    rnd = _ok_rand(seed)
    col = [1.0 + (rnd() * 2 - 1) * jag for _ in range(seg)]
    pts, cents = [], []
    for k, (z, rx, ry, cx, cy) in enumerate(rings):
        rd = 1.0 + (rnd() * 2 - 1) * jag * 0.7
        off = 0.5 if k % 2 else 0.0
        ring = []
        for i in range(seg):
            a = 2.0 * math.pi * (i + off) / seg
            s = col[i] * rd
            if bite is not None and bite[0] <= z <= bite[1]:
                w = 0.5 * (1.0 + math.cos(a - bite[3]))
                tz = (z - bite[0]) / max(bite[1] - bite[0], 1e-6)
                s *= 1.0 - bite[2] * w * math.sin(math.pi * tz)
            ring.append(Vector((cx + math.cos(a) * rx * s,
                                cy + math.sin(a) * ry * s, z)))
        pts.append(ring)
        cents.append(Vector((cx, cy, z)))
    return pts, cents


def faceted_shell(b, pts, slot, slot_of=None, cap_top=True, cap_bottom=True,
                  top_pt=None):
    """Triunghiuri intre inelele `pts` (decalate cu jumatate de pas pe randuri
    alternante) + capace. Vertecsii sunt SUDATI (un vertex per punct). `slot_of
    (k, z)` -> slot pentru banda k (intre inelele k si k+1); implicit `slot`.
    Normalele se recalculeaza la `to_object`."""
    def sl(k, z):
        return slot_of(k, z) if slot_of else slot

    V = [[b.bm.verts.new(p) for p in ring] for ring in pts]

    def tri(a, c, d, s):
        f = b.bm.faces.new([a, c, d])
        f[b.slot] = s

    for k in range(len(pts) - 1):
        lo, hi = V[k], V[k + 1]
        n = len(lo)
        s = sl(k, (pts[k][0].z + pts[k + 1][0].z) * 0.5)
        for i in range(n):
            j = (i + 1) % n
            if k % 2 == 0:   # hi decalat cu +0.5: hi[i] intre lo[i], lo[i+1]
                tri(lo[i], lo[j], hi[i], s)
                tri(hi[i], lo[j], hi[j], s)
            else:            # lo decalat: lo[i] intre hi[i], hi[i+1]
                tri(lo[i], lo[j], hi[j], s)
                tri(lo[i], hi[j], hi[i], s)
    if cap_top:
        top = V[-1]
        c = b.bm.verts.new(top_pt if top_pt is not None
                           else sum(pts[-1], Vector()) / len(pts[-1]))
        s = sl(len(pts) - 2, pts[-1][0].z)
        for i in range(len(top)):
            tri(top[i], top[(i + 1) % len(top)], c, s)
    if cap_bottom:
        bot = V[0]
        c = b.bm.verts.new(sum(pts[0], Vector()) / len(pts[0]))
        s = sl(0, pts[0][0].z)
        for i in range(len(bot)):
            tri(bot[(i + 1) % len(bot)], bot[i], c, s)


def notch_profile(h, stem_r, neck_r, cap_r, notch, cap_under, cap_mid, flat=0.55):
    """Profilul (z, raza) al unei stanci-ciuperca: poala evazata -> NISA roasa
    de val (`notch` = (z0, z1), gatul `neck_r`) -> picior -> burta capului ->
    umarul `cap_r` la `cap_mid` -> cupola turtita (`flat` = cat de lata ramane
    fata superioara)."""
    n0, n1 = notch
    nm = 0.5 * (n0 + n1)
    return [
        (0.0, stem_r * 1.40),
        (n0 * 0.55, stem_r * 1.22),
        (n0, stem_r * 1.0),
        (nm, neck_r),
        (n1, neck_r * 1.12),
        (n1 + (cap_under - n1) * 0.55, stem_r * 0.98),
        (cap_under, stem_r * 1.22),
        (cap_under + (cap_mid - cap_under) * 0.30, cap_r * 0.62),
        (cap_under + (cap_mid - cap_under) * 0.65, cap_r * 0.88),
        (cap_mid, cap_r),
        (cap_mid + (h - cap_mid) * 0.42, cap_r * 0.96),
        (h - (h - cap_mid) * 0.12, cap_r * (0.50 + 0.12 * flat)),
        (h, cap_r * 0.20 * flat + 0.05),
    ]


def notch_rock(lime, grass, prof, seg=10, seed=1, ratio=0.86, lean=0.0,
               lean_from=None, lean_to=None, notch=None, bite=None, jag=0.10,
               tufts=3, tuft_seed=3, shoulder_z=None, rock_slot=OK_LIMESTONE,
               niche_slot=OK_NICHE, grass_slot=21, grass_lift=0.2):
    """Stanca-ciuperca fatetata: corp de calcar in `lime` (banda nisei pe
    `niche_slot`), invelis de iarba pe creastet in `grass` (+ `tufts` tufe
    joase). `prof` = notch_profile; `lean` = deplasarea capului pe +X intre
    `lean_from` si `lean_to` (smoothstep). Returneaza (z_varf, inaltimea
    umarului)."""
    rings = []
    for (z, r) in prof:
        c = 0.0
        if lean and lean_from is not None:
            t = max(0.0, min(1.0, (z - lean_from) / max(lean_to - lean_from, 1e-6)))
            c = lean * t * t * t
        rings.append((z, r, r * ratio, c, 0.0))
    pts, cents = ring_points(rings, seg, seed, jag, bite)

    def slot_of(k, z):
        if notch and notch[0] - 0.05 <= z <= notch[1] + 0.15:
            return niche_slot
        return rock_slot
    faceted_shell(lime, pts, rock_slot, slot_of)

    # invelisul de iarba: inelele de la umar in sus, impinse spre exterior si in sus
    k0 = 0
    for k, (z, _) in enumerate(prof):
        if shoulder_z is not None and z >= shoulder_z - 1e-6:
            k0 = k
            break
    gp = []
    for k in range(k0, len(pts)):
        ring = []
        for p in pts[k]:
            d = Vector((p.x - cents[k].x, p.y - cents[k].y, 0.0))
            ring.append(Vector((p.x + d.x * 0.0, p.y + d.y * 0.0,
                                p.z + grass_lift + (0.16 if k == len(pts) - 1 else 0.0))))
        gp.append(ring)
    faceted_shell(grass, gp, grass_slot, cap_bottom=True)
    top_z = pts[-1][0].z + grass_lift + 0.16
    rnd = _ok_rand(tuft_seed)
    cx_top = cents[-1].x
    cap_r = max(r for _, r in prof)
    for i in range(tufts):
        a = 2.0 * math.pi * (i + rnd() * 0.6) / max(tufts, 1) + 0.4
        rr = cap_r * (0.28 + 0.22 * rnd())
        sx = 1.5 + rnd() * 0.9
        sh = 0.85 + rnd() * 0.45
        grass.boulder((cx_top + math.cos(a) * rr, math.sin(a) * rr * ratio,
                       top_z - 0.08 + sh * 0.18), (sx, sx * 0.85, sh), grass_slot,
                      seed=tuft_seed * 7 + i, segments=7, rings=3, deviation=0.14)
    return top_z, pts[k0][0].z


def foot_boulders(lime, specs, slot=OK_LIMESTONE):
    """Bolovani la picior: `specs` = [(x, y, marime, seed)], marime = (sx, sy, sz).
    Se infig 30% in sol (baza ingropata nu se vede)."""
    for (x, y, size, seed) in specs:
        lime.boulder((x, y, size[2] * 0.2), size, slot, seed=seed, segments=7,
                     rings=3, deviation=0.16)


def lobe_profile(h, R, r0=0.45, shoulder=0.62):
    """Profil de lob rotunjit (stanca-inima): varf subtire jos, burta larga
    la `shoulder`, cupola sus. Lista (z, raza)."""
    out = []
    n = 11
    for k in range(n + 1):
        t = k / n
        if t <= shoulder:
            r = r0 + (R - r0) * (t / shoulder) ** 1.15
        else:
            u = (t - shoulder) / (1.0 - shoulder)
            r = R * math.sqrt(max(0.0, 1.0 - u * u)) + 0.05
        out.append((h * t, r))
    return out


# ---------------------------------------------------------------------------
# rocile din AGLOMERARI DE BLOCURI (runda 4, ceruta de coordonator)
# ---------------------------------------------------------------------------

def chunk(b, c, size, seed, slot, seg=7, nr=4, jag=0.16, yaw=None, tilt=0.30,
          slot_of=None):
    """Bolovan fatetat (elipsoid low-res, rotit aleator): `nr` inele fara poli,
    capace plate. `size` = (sx, sy, sz) pe elipsoidul teoretic (varful real
    iese ~0,75 din semi-inaltime). Umbrire plata la export (flat_ao)."""
    rnd = _ok_rand(seed)
    yv = rnd() * 2.0 * math.pi if yaw is None else yaw
    tx, ty = (rnd() - 0.5) * 2.0 * tilt, (rnd() - 0.5) * 2.0 * tilt
    R = Matrix.Rotation(yv, 3, "Z") @ Matrix.Rotation(tx, 3, "X") @ Matrix.Rotation(ty, 3, "Y")
    rings = []
    for k in range(nr):
        t = -1.0 + 2.0 * (k + 0.5) / nr
        rr = math.sqrt(max(0.0, 1.0 - t * t))
        rings.append((t * size[2] * 0.5, rr * size[0] * 0.5, rr * size[1] * 0.5, 0.0, 0.0))
    pts, _ = ring_points(rings, seg, seed + 7, jag)
    cv = Vector(c)
    pts = [[R @ p + cv for p in ring] for ring in pts]
    faceted_shell(b, pts, slot, slot_of)


def grass_clusters(grass, cx, cap_r, top_z, edge_z, n, seed, slot_a=21, slot_b=12,
                   spill=0.25):
    """Ciorchini de smocuri (0,6..1,3 m) pe crestetul unui cap: `n` ciorchini
    de 2 bolovani, ~1/3 pe CACTUS_GREEN (12), restul TROPICAL_GREEN (21), cei
    de la margine se revarsa peste buza (`spill`). `top_z` = cota fetei de sus
    la centru, `edge_z` = la margine."""
    rnd = _ok_rand(seed)
    for i in range(n):
        ang = 2.0 * math.pi * (i + rnd() * 0.5) / n * 1.0 + 0.7 * i
        rho = cap_r * (0.12 + 0.86 * math.sqrt(rnd()))
        z = top_z - (top_z - edge_z) * (rho / cap_r) ** 2
        if rho > 0.74 * cap_r:
            rho += spill
            z -= spill
        s = 0.6 + rnd() * 0.5
        sl = slot_b if i % 3 == 2 else slot_a
        x, y = cx + math.cos(ang) * rho, math.sin(ang) * rho
        chunk(grass, (x, y, z + s * 0.25), (s * 1.3, s * 1.15, s * 0.95), seed * 13 + i, sl,
              seg=6, nr=3, jag=0.18)
        chunk(grass, (x + math.cos(ang + 1.9) * s * 0.7, y + math.sin(ang + 1.9) * s * 0.7,
                      z + s * 0.1), (s * 0.8, s * 0.8, s * 0.6), seed * 17 + i, slot_a,
              seg=6, nr=3, jag=0.18)


def notch_cluster_rock(lime, grass, spec):
    """Stanca-ciuperca din blocuri: picior cu sectiune neregulata (7 laturi,
    jag) + NISA (scobitura sub cap) + cap din 7..12 bolovani fatetati in doua
    straturi + fusta de bolovani la baza + ciorchini de iarba. `spec` e un dict
    (vezi build_okinawa_coast.py). Returneaza cota varfului (cu iarba)."""
    sd = spec["seed"]
    lean = spec.get("lean", 0.0)
    lf = spec.get("lean_from", 0.0)
    ztop_stem = spec["stem"][-1][0]
    rings = []
    for (z, r) in spec["stem"]:
        t = max(0.0, min(1.0, (z - lf) / max(ztop_stem - lf, 1e-6))) if lean else 0.0
        rings.append((z, r, r * 0.92, lean * t * t, 0.0))
    nz = spec["neck"]
    pts, _ = ring_points(rings, 7, sd, 0.16, spec.get("bite"))
    faceted_shell(lime, pts, OK_LIMESTONE,
                  lambda k, z: OK_NICHE if nz[0] <= z <= nz[1] else OK_LIMESTONE,
                  cap_top=True, cap_bottom=True)
    rnd = _ok_rand(sd + 3)
    cp = spec["cap"]
    # strat inferior (burta) + superior + centru
    n = cp["n_lo"]
    for i in range(n):
        a = 2.0 * math.pi * (i + rnd() * 0.5) / n
        rho = cp["rho_lo"] * (0.88 + rnd() * 0.24)
        sx = cp["sx_lo"] * (0.85 + rnd() * 0.3)
        chunk(lime, (lean + math.cos(a) * rho, math.sin(a) * rho * 0.92,
                     cp["lo_z"] + (rnd() - 0.5) * 0.5),
              (sx, sx * 0.9, cp["lo_h"] * (0.85 + rnd() * 0.3)), sd * 31 + i, OK_LIMESTONE,
              seg=6, nr=3, jag=0.2)
    n = cp["n_hi"]
    for i in range(n):
        a = 2.0 * math.pi * (i + rnd() * 0.5) / n + 0.5
        rho = cp["rho_hi"] * (0.8 + rnd() * 0.4)
        sx = cp["sx_hi"] * (0.85 + rnd() * 0.3)
        chunk(lime, (lean + math.cos(a) * rho, math.sin(a) * rho * 0.92,
                     cp["hi_z"] + (rnd() - 0.5) * 0.4),
              (sx, sx * 0.9, cp["hi_h"] * (0.85 + rnd() * 0.3)), sd * 37 + i, OK_LIMESTONE,
              seg=6, nr=3, jag=0.2)
    cz, ch, csx = cp["center"]
    chunk(lime, (lean, 0.0, cz), (csx, csx * 0.9, ch), sd * 41, OK_LIMESTONE, seg=6, nr=3, jag=0.2)
    # fusta de bolovani
    sk = spec["skirt"]
    for i in range(sk["n"]):
        a = 2.0 * math.pi * (i + rnd() * 0.5) / sk["n"]
        rho = sk["rad"] * (0.85 + rnd() * 0.3)
        sx = sk["sx"] * (0.8 + rnd() * 0.45)
        chunk(lime, (math.cos(a) * rho, math.sin(a) * rho * 0.92, sk["h"] * 0.28),
              (sx, sx * (0.7 + rnd() * 0.3), sk["h"] * (0.75 + rnd() * 0.5)), sd * 43 + i,
              OK_LIMESTONE, seg=6, nr=3, jag=0.2)
    for i in range(sk.get("loose", 2)):
        a = 2.0 * math.pi * (i + 0.3) / 2.0 + sd
        rho = sk["rad"] * 1.3
        chunk(lime, (math.cos(a) * rho, math.sin(a) * rho, 0.3), (1.3, 1.1, 0.9), sd * 47 + i,
              OK_LIMESTONE, seg=6, nr=3)
    top_z = cz + ch * 0.4
    lo_top = cp["lo_z"] + cp["lo_h"] * 0.35
    cap_r = cp["rho_lo"] + cp["sx_lo"] * 0.5
    grass_clusters(grass, lean, cap_r * 0.85, top_z, lo_top, spec.get("tufts", 11), sd + 5)
    return top_z + 1.0

# ====================================================================

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

# ---------------------------------------------------------------------------
# runda 5 (ok-g): SILUETA intai. Stanca-ciuperca dintr-un profil clar, coloane
# prismatice pentru faleza, solzi in romb pentru trunchiul de palmier.
# ---------------------------------------------------------------------------

def mushroom_rock(lime, grass, spec):
    """Stanca-ciuperca cu SILUETA clara: un singur corp (profil gat zvelt, baza
    evazata, NISA concava sub buza capului, cap lat in surplomba) + bolovani pe
    buza capului si la baza + iarba in ciorchini. `spec`:
      seed, prof = [(z, r)] (profilul corpului), neck = (z0, z1) banda nisei,
      rim_z / rim_r (buza capului), top_z (cota creastetului), lean = deplasarea
      capului pe +X intre lean_from si lean_to, ratio (y/x), seg, jag,
      rim_n / rim_size (bolovani pe buza), top_n, skirt = dict(n, rad, sx, h),
      tufts. Returneaza cota varfului (cu iarba)."""
    sd = spec["seed"]
    lean, lf, lt = spec.get("lean", 0.0), spec.get("lean_from", 0.0), spec.get("lean_to", 1.0)
    ratio = spec.get("ratio", 0.9)
    rings = []
    for (z, r) in spec["prof"]:
        t = max(0.0, min(1.0, (z - lf) / max(lt - lf, 1e-6))) if lean else 0.0
        t = t * t * (3.0 - 2.0 * t)
        rings.append((z, r, r * ratio, lean * t, 0.0))
    pts, cents = ring_points(rings, spec.get("seg", 12), sd, spec.get("jag", 0.10))
    nz = spec["neck"]
    faceted_shell(lime, pts, OK_LIMESTONE,
                  lambda k, z: OK_NICHE if nz[0] <= z <= nz[1] else OK_LIMESTONE)
    rnd = _ok_rand(sd + 11)
    rim_z, rim_r, top_z = spec["rim_z"], spec["rim_r"], spec["top_z"]
    cx = lean
    # bolovani pe buza capului (doua straturi): fac conturul "de bolovani"
    n = spec.get("rim_n", 9)
    rs = spec.get("rim_size", 2.4)
    for i in range(n):
        a = 2.0 * math.pi * (i + rnd() * 0.4) / n
        rho = rim_r - rs * 0.30
        s = rs * (0.9 + rnd() * 0.3)
        chunk(lime, (cx + math.cos(a) * rho, math.sin(a) * rho * ratio,
                     rim_z + (rnd() - 0.5) * 0.4),
              (s, s * 0.92, s * 0.9), sd * 31 + i, OK_LIMESTONE, seg=6, nr=3, jag=0.2)
    n2 = max(3, n - 2)
    for i in range(n2):
        a = 2.0 * math.pi * (i + 0.5 + rnd() * 0.3) / n2
        rho = rim_r * 0.74
        s = rs * (0.85 + rnd() * 0.25)
        chunk(lime, (cx + math.cos(a) * rho, math.sin(a) * rho * ratio,
                     rim_z + 0.95 + (rnd() - 0.5) * 0.3),
              (s, s * 0.92, s * 0.8), sd * 33 + i, OK_LIMESTONE, seg=6, nr=3, jag=0.2)
    tn = spec.get("top_n", 4)
    for i in range(tn):
        a = 2.0 * math.pi * (i + rnd() * 0.5) / tn + 0.6
        rho = rim_r * (0.25 + 0.2 * rnd())
        s = rs * 0.75
        chunk(lime, (cx + math.cos(a) * rho, math.sin(a) * rho * ratio,
                     top_z - 0.7 + (rnd() - 0.5) * 0.3), (s, s * 0.9, s * 0.65),
              sd * 37 + i, OK_LIMESTONE, seg=6, nr=3, jag=0.2)
    # fusta de bolovani la baza
    sk = spec["skirt"]
    for i in range(sk["n"]):
        a = 2.0 * math.pi * (i + rnd() * 0.5) / sk["n"]
        rho = sk["rad"] * (0.85 + rnd() * 0.3)
        sx = sk["sx"] * (0.8 + rnd() * 0.45)
        chunk(lime, (math.cos(a) * rho, math.sin(a) * rho * 0.92, sk["h"] * 0.28),
              (sx, sx * (0.7 + rnd() * 0.3), sk["h"] * (0.75 + rnd() * 0.5)), sd * 43 + i,
              OK_LIMESTONE, seg=6, nr=3, jag=0.2)
    for i in range(sk.get("loose", 2)):
        a = 2.0 * math.pi * (i + 0.3) / 2.0 + sd
        rho = sk["rad"] * 1.3
        chunk(lime, (math.cos(a) * rho, math.sin(a) * rho, 0.3), (1.3, 1.1, 0.9), sd * 47 + i,
              OK_LIMESTONE, seg=6, nr=3)
    # iarba: piele pe cupola (doar sub 80% din raza buzei, ca piatra sa se vada
    # pana la margine) + ciorchini MARI care se revarsa peste buza
    k0 = len(pts) - 2
    for k, (z, r) in enumerate(spec["prof"]):
        if z > rim_z + 0.2 and r <= 0.82 * rim_r:
            k0 = k
            break
    gp = []
    for k in range(k0, len(pts)):
        gp.append([Vector((p.x, p.y, p.z + 0.12 + (0.14 if k == len(pts) - 1 else 0.0)))
                   for p in pts[k]])
    faceted_shell(grass, gp, 12, cap_bottom=True)
    nt = spec.get("tufts", 10)
    zk = pts[k0][0].z
    for i in range(nt):
        ang = 2.0 * math.pi * (i + rnd() * 0.4) / nt + 0.5
        edge = (i % 2 == 0)
        rho = rim_r * (0.80 + 0.18 * rnd()) if edge else rim_r * (0.15 + 0.5 * rnd())
        z = (zk - 0.1 - 0.35 * (rho / rim_r - 0.78) * 4.0) if edge else top_z + 0.1 - 0.9 * (rho / rim_r) ** 2
        sz = 1.0 + rnd() * 0.6
        x, y = cx + math.cos(ang) * rho, math.sin(ang) * rho * ratio
        chunk(grass, (x, y, z + sz * 0.35), (sz * 1.5, sz * 1.3, sz * 1.15), sd * 53 + i,
              12 if i % 3 == 2 else 21, seg=6, nr=3, jag=0.2)
        chunk(grass, (x + math.cos(ang + 2.0) * sz * 0.7, y + math.sin(ang + 2.0) * sz * 0.7,
                      z + sz * 0.15), (sz * 0.95, sz * 0.9, sz * 0.7), sd * 59 + i,
              21 if i % 3 == 2 else 12, seg=6, nr=3, jag=0.2)
    return top_z + 1.4


def column_prism(b, c, size, z0, z1, seed, slot, sides=6, jag=0.16, kink=(0.0, 0.0),
                 lean=(0.0, 0.0), peak=0.35, rot=None, taper=0.82, top_s=1.0):
    """Coloana prismatica fatetata: sectiune de `sides` laturi cu coltul
    neregulat, capete teșite, o COTITURA la mijloc (`kink` = deplasare x,y a
    jumatatii de sus: face un prag) si varf in acoperis (`peak`). `size` =
    (rx, ry) semi-extinderi. Inelele raman aliniate: fete verticale late, nu
    romburi (cf. faceted_shell)."""
    rnd = _ok_rand(seed)
    off = rnd() * 2.0 * math.pi / sides if rot is None else rot
    col = [1.0 + (rnd() * 2 - 1) * jag for _ in range(sides)]
    H = z1 - z0
    prof = [(0.0, taper, 0.0), (0.05, 1.0, 0.0), (0.48, 1.0, 0.0), (0.56, 1.02, 1.0),
            (0.95, 0.98, 1.0), (1.0, taper, 1.0)]
    cv = Vector(c)
    V = []
    for (t, s, kk) in prof:
        ring = []
        for i in range(sides):
            a = off + 2.0 * math.pi * i / sides
            s = s * (1.0 - (1.0 - top_s) * t)
            x = math.cos(a) * size[0] * s * col[i] + kink[0] * kk + lean[0] * t
            y = math.sin(a) * size[1] * s * col[i] + kink[1] * kk + lean[1] * t
            ring.append(b.bm.verts.new(cv + Vector((x, y, z0 + H * t))))
        V.append(ring)
    for k in range(len(V) - 1):
        for i in range(sides):
            j = (i + 1) % sides
            f = b.bm.faces.new([V[k][i], V[k][j], V[k + 1][j], V[k + 1][i]])
            f[b.slot] = slot
    top = V[-1]
    ap = b.bm.verts.new(cv + Vector((kink[0] + lean[0] + (rnd() - 0.5) * size[0] * 0.6,
                                     kink[1] + lean[1] + (rnd() - 0.5) * size[1] * 0.6,
                                     z1 + peak)))
    for i in range(sides):
        f = b.bm.faces.new([top[i], top[(i + 1) % sides], ap])
        f[b.slot] = slot
    bot = V[0]
    cb = b.bm.verts.new(cv + Vector((0, 0, z0 - 0.05)))
    for i in range(sides):
        f = b.bm.faces.new([bot[(i + 1) % sides], bot[i], cb])
        f[b.slot] = slot


def cliff_section(top, nd, nt):
    """Sectiunea XZ a masei din spate (x = spre mare): poala, NISA de val cu
    adancimea `nd` (m) si tavanul la cota `nt`, perete retras la x 0,4
    (suprafata o fac coloanele), creasta. 12 puncte."""
    xn = 1.6 - nd
    return [
        (-2.5, 0.0), (1.6, 0.0), (1.6, 0.45),
        (xn + 0.25, 0.45 + (nt - 0.45) * 0.30), (xn, 0.45 + (nt - 0.45) * 0.65),
        (xn + 0.1, nt), (0.4, nt + 0.9), (0.4, top - 1.0), (0.2, top),
        (-0.8, top + 0.2), (-2.2, top), (-2.5, top - 0.5),
    ]


def _loft_stations(b, profiles, ys, slot_of_edge, slot):
    V = [[b.bm.verts.new((x, y, z)) for (x, z) in prof] for prof, y in zip(profiles, ys)]
    n = len(profiles[0])
    for k in range(len(V) - 1):
        for i in range(n):
            j = (i + 1) % n
            f = b.bm.faces.new([V[k][i], V[k][j], V[k + 1][j], V[k + 1][i]])
            f[b.slot] = slot_of_edge(i)
    caps = []
    for ring in (V[0], list(reversed(V[-1]))):
        f = b.bm.faces.new(ring)
        f[b.slot] = slot
        caps.append(f)
    bmesh.ops.triangulate(b.bm, faces=caps)


def cliff_columns_module(lime, grass, seed, stations, lower, upper, rear, end_seed=7000):
    """Modul de faleza din COLOANE PRISMATICE pe DOUA TREPTE care formeaza
    suprafata (nu stau lipite pe o placa): masa din spate cu sectiune per statie
    (nisa de val NEREGULATA: adancime si inaltime variabile pe lungime), treapta
    de jos = coloane late (1,7-2,7 m) care ies peste nisa, treapta de sus =
    alta partitie, retrasa, cu crapaturi care NU se aliniaza cu cele de jos;
    coloane in crapaturi; coloanele de capat (ambele trepte) IDENTICE in orice
    varianta (capetele si sectiunea de capat sunt aceleasi la y = +-6).
    `stations` = [(y, top, nd, nt)], `lower` / `upper` / `rear` =
    [(yc, w, xc, z_varf, kink_x, kink_y)]. Returneaza cota maxima."""
    ys = [s_[0] for s_ in stations]
    profs = [cliff_section(t, nd, nt) for (_, t, nd, nt) in stations]
    _loft_stations(lime, profs, ys, lambda i: OK_NICHE if i in (2, 3, 4, 5) else OK_LIMESTONE,
                   OK_LIMESTONE)
    gprofs = []
    for P in profs:
        a, c_, d_ = P[-4], P[-3], P[-2]
        gprofs.append([(a[0] + 0.12, a[1] - 0.35), (a[0], a[1] + 0.22), (c_[0], c_[1] + 0.22),
                       (d_[0], d_[1] + 0.2), (d_[0] - 0.3, d_[1] - 0.2),
                       (d_[0] - 0.3, d_[1] - 0.5), (a[0] - 0.1, a[1] - 0.9)])
    _loft_stations(grass, gprofs, ys, lambda i: 21, 21)

    def nt_at(y):
        best = stations[0]
        for s_ in stations:
            if abs(s_[0] - y) < abs(best[0] - y):
                best = s_
        return best[3]

    rnd = _ok_rand(seed)
    zmax = 0.0
    # coloanele de capat: identice in toate variantele (seed fix, jag mic, rot 0)
    for sgn in (-1.0, 1.0):
        k = int(sgn + 1)
        column_prism(lime, (1.5, sgn * 5.0, 0.0), (1.1, 0.92), 3.0 - 0.15, 7.4, end_seed + k,
                     OK_LIMESTONE, sides=6, jag=0.04, rot=0.0, peak=0.2, top_s=0.95)
        column_prism(lime, (0.7, sgn * 5.0, 0.0), (1.05, 0.9), 6.2, 12.6, end_seed + 5 + k,
                     OK_LIMESTONE, sides=6, jag=0.04, rot=0.0, kink=(0.15, 0.0), peak=0.3,
                     top_s=0.9)
        chunk(grass, (0.7, sgn * 5.0, 12.9), (2.2, 1.8, 0.9), end_seed + 20 + k, 21, seg=6,
              nr=3, jag=0.1, yaw=0.0, tilt=0.0)
        zmax = max(zmax, 13.35)
    for i, (yc, w, xc, zt, kx, ky) in enumerate(lower):
        column_prism(lime, (xc, yc, 0.0), (1.6, w * 0.53), nt_at(yc) - 0.15, zt, seed * 7 + i,
                     OK_LIMESTONE, sides=6 + (i % 2), jag=0.3, kink=(kx, ky),
                     lean=((rnd() - 0.2) * 0.3, (rnd() - 0.5) * 0.3), peak=0.35, top_s=0.95)
        if i % 2 == 1:
            chunk(grass, (xc + 0.2, yc, zt + 0.35), (w * 0.9, w * 0.8, 0.6), seed * 19 + i, 12,
                  seg=6, nr=3, jag=0.2)
    for i, (yc, w, xc, z1, kx, ky) in enumerate(upper):
        column_prism(lime, (xc, yc, 0.0), (1.4, w * 0.53), 5.4, z1, seed * 11 + i,
                     OK_LIMESTONE, sides=6 + (i % 2), jag=0.28, kink=(kx, ky),
                     lean=((rnd() - 0.5) * 0.3, (rnd() - 0.5) * 0.3), peak=0.45, top_s=0.93)
        chunk(grass, (xc + kx, yc, z1 + 0.5), (w * 1.25, w * 1.15, 1.0), seed * 13 + i,
              21 if i % 3 != 1 else 12, seg=6, nr=3, jag=0.2)
        if i % 2 == 0:
            chunk(grass, (xc + kx - 0.4, yc + (rnd() - 0.5) * 0.6, z1 + 1.0),
                  (w * 0.8, w * 0.75, 0.8), seed * 17 + i, 12, seg=6, nr=3, jag=0.2)
        zmax = max(zmax, z1 + 1.4)
    for i, (yc, w, xc, z1, kx, ky) in enumerate(rear):
        column_prism(lime, (xc, yc, 0.0), (0.95, w * 0.5), 5.4, z1, seed * 3 + i,
                     OK_LIMESTONE, sides=6, jag=0.22, kink=(kx, ky), peak=0.3, top_s=0.88)
        chunk(grass, (xc, yc, z1 + 0.4), (w * 1.4, w * 1.2, 0.8), seed * 5 + i,
              12 if i % 2 else 21, seg=6, nr=3, jag=0.2)
        zmax = max(zmax, z1 + 0.9)
    return max(zmax, max(s_[1] for s_ in stations) + 1.0)


def rhomb_scales(b, r_of_z, z_rows, n_per_row, slot_a, slot_b, depth=0.07, cx=0.0, cy=0.0,
                 w=1.2, h=0.34):
    """Solzi IN ROMB cu muchii pe trunchi (bazele petiolilor vechi): fiecare
    solz e un romb ridicat (varf spre exterior, 4 fete). Randurile sunt
    decalate cu jumatate de pas (latice de romburi). `r_of_z` -> raza trunchiului."""
    for row, z in enumerate(z_rows):
        r = r_of_z(z)
        off = 0.5 * (row % 2)
        for k in range(n_per_row):
            a = 2.0 * math.pi * (k + off) / n_per_row
            half_a = math.pi / n_per_row * w
            nrm = Vector((math.cos(a), math.sin(a), 0.0))
            tang = Vector((-math.sin(a), math.cos(a), 0.0))
            C = Vector((cx, cy, z)) + nrm * (r - 0.01)
            apex = b.bm.verts.new(C + nrm * depth * 2.2)
            up = b.bm.verts.new(C + Vector((0, 0, h * 0.5)) + nrm * 0.005)
            dn = b.bm.verts.new(C - Vector((0, 0, h * 0.5)) + nrm * 0.005)
            lf = b.bm.verts.new(C - tang * r * math.sin(half_a) + nrm * 0.005)
            rt = b.bm.verts.new(C + tang * r * math.sin(half_a) + nrm * 0.005)
            sl = slot_a if (row + k) % 2 else slot_b
            for tri in ((up, lf, apex), (lf, dn, apex), (dn, rt, apex), (rt, up, apex)):
                f = b.bm.faces.new(tri)
                f[b.slot] = sl
            f = b.bm.faces.new((up, rt, dn, lf))
            f[b.slot] = sl


# ---------------------------------------------------------------------------
# ok-e (val 2): emit cu OFFSET EXPLICIT si, optional, nod-radacina cu copii.
# Vapoarele au originea la LINIA APEI (`--origin=waterline`): `emit_ok` aseaza
# baza ansamblului la z=0, ceea ce ar urca coca pe apa. Aici `place` e dat de
# apelant; `root` (nume) creeaza un Empty-parinte cu copiii reali, ca
# `LiftBridgeHazard._extract_ship` sa gaseasca nodul dupa nume (`ship_node`).
# ---------------------------------------------------------------------------

def emit_ok_placed(objs, path, ao, place=(0.0, 0.0, 0.0), root=None, bevel=0.0,
                   smooth_angle=None, budget=None, bevel_angle=30.0, flat_ao=False):
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    pl = Vector(place)
    total = 0
    per_node = {}
    for o in objs:
        for v in o.data.vertices:
            v.co += pl
        if flat_ao:
            _split_all_edges(o)
        st = finish(o, bevel=bevel, bevel_angle=bevel_angle, ao=ao,
                    origin=None, smooth_angle=smooth_angle)
        if flat_ao:
            _flatten_ao(o)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    exp = list(objs)
    holder = None
    if root:
        holder = bpy.data.objects.new(root, None)
        bpy.context.collection.objects.link(holder)
        for o in objs:
            o.parent = holder
        exp = [holder] + objs
    _, sz = export_glb(exp, "okinawa/" + path)
    if holder is not None:
        for o in objs:
            o.parent = None
        bpy.data.objects.remove(holder, do_unlink=True)
    OK_RESULTS.append((path, total, dims, budget, per_node, sz / 1024.0))
    return total
