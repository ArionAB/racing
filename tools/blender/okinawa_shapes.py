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
