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
                 cap_over=0.08):
    """Soclu de piatra: corp cu talpa evazata (se ingusteaza cu `flare` spre
    varf) si placa de capat usor iesita. Taiat la colturi ca sa nu iasa cutie."""
    bot = chamfer([(cx - hx, cy - hy), (cx + hx, cy - hy),
                   (cx + hx, cy + hy), (cx - hx, cy + hy)], 0.12)
    top = chamfer([(cx - hx + flare, cy - hy + flare), (cx + hx - flare, cy - hy + flare),
                   (cx + hx - flare, cy + hy - flare), (cx - hx + flare, cy + hy - flare)], 0.12)
    loft(b, bot, 0.0, top, h - cap_h, slot)
    capp = [(p[0], p[1]) for p in chamfer(
        [(cx - hx + flare - cap_over, cy - hy + flare - cap_over),
         (cx + hx - flare + cap_over, cy - hy + flare - cap_over),
         (cx + hx - flare + cap_over, cy + hy - flare + cap_over),
         (cx - hx + flare - cap_over, cy + hy - flare + cap_over)], 0.1)]
    loft(b, capp, h - cap_h, capp, h, slot)


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
