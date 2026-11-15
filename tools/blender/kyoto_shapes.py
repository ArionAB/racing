"""Vocabular de forme japoneze, pentru kitul Kyoto (Track18).

Lectia Jodhpur: fara vocabular, constructorul reinventeaza forma din cutii si
iese altceva decat planșa. Aici sunt formele care definesc Kyoto-ul si pe care
`dio_lib.Builder` nu le are: **acoperisul in patru ape cu streasina curbata in
sus si cu nervuri de tigla** (yosemune), inelele de la varful pagodei, frunzisul
de arțar in ciorchini turtiti.

Se incarca cu exec, dupa dio_lib (vezi build_kyoto_*.py). Functiile primesc un
`Builder` si intorc fetele noi.

Axe: X latime, Y adancime (fata spre +Y in Blender = -Z in Godot), Z sus.
"""

import math
from mathutils import Vector, Matrix


def _lerp(a, b, t):
    return a + (b - a) * t


def hip_roof(b, cx, cy, ze, hx, hy, rise, slot, ridge_half=0.0, lift=0.9,
             thick=0.28, under_slot=None, fascia_slot=None, tile_step=0.8,
             rib=0.05, sag=1.6, rings=(0.0, 0.35, 0.7, 1.0), swell=0.0):
    """Acoperis in patru ape (yosemune), cu streasina concava si colturile
    ridicate. Pagoda: `ridge_half=0` (piramida). Sala/poarta: `ridge_half>0`
    (creasta pe X).

    cx, cy        centrul in plan
    ze            cota streasinii (la mijlocul laturii, partea de sus)
    hx, hy        semi-latimile streasinii
    rise          cat urca creasta/varful peste `ze`
    lift          cat se ridica colturile streasinii fata de mijlocul laturii
    thick         grosimea lemnului de sub tigla (fateta streasinii)
    tile_step     distanta intre nervurile de tigla (m), +/- `rib` pe z
    sag           exponentul concavitatii: >1 = concav (profil japonez)
    swell         cat ies colturile in afara in plan (streasina "zboara")

    Sloturile: `slot` pe fata de tigla, `fascia_slot` pe fateta streasinii
    (implicit slot), `under_slot` pe fata de dedesubt (implicit fascia_slot).
    Intoarce multimea fetelor.
    """
    fascia_slot = slot if fascia_slot is None else fascia_slot
    under_slot = fascia_slot if under_slot is None else under_slot
    # perimetrul streasinii: puncte ordonate antiorar, cu parametrul u pe latura
    per = []
    for side, (ax, ay, dx, dy, ln) in enumerate((
            (hx, -hy, 0.0, 1.0, 2 * hy),     # dreapta, de jos in sus
            (hx, hy, -1.0, 0.0, 2 * hx),      # sus, de la dreapta la stanga
            (-hx, hy, 0.0, -1.0, 2 * hy),     # stanga
            (-hx, -hy, 1.0, 0.0, 2 * hx))):   # jos
        n = max(int(round(ln / tile_step)), 4)
        n += n % 2
        for k in range(n):
            t = k / n
            u = abs(2 * t - 1.0)               # 1 la colt, 0 la mijloc
            per.append((ax + dx * ln * t, ay + dy * ln * t, u ** 3, side, k))
    m = len(per)

    def ridge_pt(x, y):
        return (max(-ridge_half, min(ridge_half, x)), 0.0)

    def profile(s):
        return (1.0 - s) ** sag

    bm = b.bm
    faces = []
    # ringuri: pe fiecare coloana i, punctele (s) de la creasta la streasina
    cols = []
    for i, (px, py, f, side, k) in enumerate(per):
        qx, qy = ridge_pt(px, py)
        col = []
        for s in rings:
            sx = _lerp(qx, px, s)
            sy = _lerp(qy, py, s)
            # colturile zboara in afara
            if swell:
                sx += math.copysign(swell * f * s, px) if abs(px) > 1e-9 else 0.0
                sy += math.copysign(swell * f * s, py) if abs(py) > 1e-9 else 0.0
            z = ze + rise * profile(s) + lift * f * s * s
            if s > 0.2 and (i % 2 == 1):
                z += rib * min(1.0, s)
            col.append((cx + sx, cy + sy, z))
        cols.append(col)

    vcache = {}

    def V(p):
        key = (round(p[0], 5), round(p[1], 5), round(p[2], 5))
        v = vcache.get(key)
        if v is None:
            v = bm.verts.new(p)
            vcache[key] = v
        return v

    def face(pts, slot_):
        vs = []
        for p in pts:
            v = V(p)
            if not vs or vs[-1] is not v:
                vs.append(v)
        if len(vs) > 1 and vs[0] is vs[-1]:
            vs.pop()
        if len(set(vs)) < 3:
            return None
        try:
            f_ = bm.faces.new(vs)
        except ValueError:
            return None
        f_[b.slot] = slot_
        faces.append(f_)
        return f_

    nr = len(rings)
    # fata de sus (tigla)
    for i in range(m):
        j = (i + 1) % m
        for r in range(nr - 1):
            face((cols[i][r], cols[j][r], cols[j][r + 1], cols[i][r + 1]), slot)
    # fateta streasinii + fata de jos
    low = []
    for i in range(m):
        top = cols[i][-1]
        low.append((top[0], top[1], top[2] - thick))
    inner = []
    for i in range(m):
        top = cols[i][-1]
        qx, qy = ridge_pt(per[i][0], per[i][1])
        px, py = per[i][0], per[i][1]
        ix = cx + _lerp(px, qx, 0.55)
        iy = cy + _lerp(py, qy, 0.55)
        inner.append((ix, iy, ze - thick * 0.2 + 0.0))
    for i in range(m):
        j = (i + 1) % m
        face((cols[i][-1], low[i], low[j], cols[j][-1]), fascia_slot)
        face((low[i], inner[i], inner[j], low[j]), under_slot)
    # capac de jos (inchide volumul)
    ring_pts = [inner[i] for i in range(m)]
    vs = []
    for p in reversed(ring_pts):
        v = V(p)
        if not vs or vs[-1] is not v:
            vs.append(v)
    if len(set(vs)) >= 3:
        try:
            f_ = bm.faces.new(vs)
            f_[b.slot] = under_slot
            faces.append(f_)
        except ValueError:
            pass
    # capac de sus, daca nu exista creasta/varf (nu e cazul: ringul 0 e varful)
    return set(faces)


def ring_stack(b, cx, cy, z0, radius_list, step, thick, slot, segments=10):
    """Gramada de discuri subtiri (kurinrin / sorin): raza per disc, pas
    vertical `step`, grosimea `thick`."""
    faces = set()
    for i, r in enumerate(radius_list):
        faces |= b.cylinder((cx, cy, z0 + i * step + thick * 0.5), r, thick,
                            slot, segments=segments)
    return faces


def frame_ring(b, cx, cy, z, hx, hy, h, t, slot):
    """Inel dreptunghiular gol (patru grinzi) -- brau de console, talpa."""
    f = set()
    f |= b.box((cx, cy + hy - t * 0.5, z + h * 0.5), (2 * hx, t, h), slot)
    f |= b.box((cx, cy - hy + t * 0.5, z + h * 0.5), (2 * hx, t, h), slot)
    f |= b.box((cx + hx - t * 0.5, cy, z + h * 0.5), (t, 2 * hy - 2 * t, h), slot)
    f |= b.box((cx - hx + t * 0.5, cy, z + h * 0.5), (t, 2 * hy - 2 * t, h), slot)
    return f


def leaf_cluster(b, center, rx, ry, rz, slot, lobes=8, seed=0, top_slot=None,
                 notch=0.68):
    """Ciorchine de frunze de arțar: o lentila groasa cu ecuatorul in lobi
    (`lobes` varfuri, `notch` = raza crestaturilor fata de varfuri), bombata
    sus, mai plata jos. Nu e glob: raza varie pe unghi, iar ciorchinii se
    suprapun in coroana. ~8*lobes triunghiuri.
    """
    rnd = _lcg(seed)
    cx, cy, cz = center
    n = lobes * 2
    eq, up, lo = [], [], []
    for i in range(n):
        a = 2 * math.pi * i / n + (rnd() - 0.5) * 0.12
        tip = (i % 2 == 0)
        r = (1.0 if tip else notch) * (0.9 + 0.2 * rnd())
        ca, sa = math.cos(a), math.sin(a)
        eq.append(b.bm.verts.new((cx + ca * rx * r, cy + sa * ry * r,
                                  cz + rz * (0.0 + 0.12 * (rnd() - 0.5)))))
        ru = 0.74 if tip else 0.62
        up.append(b.bm.verts.new((cx + ca * rx * r * ru, cy + sa * ry * r * ru,
                                  cz + rz * 0.5)))
        rl = 0.72 if tip else 0.6
        lo.append(b.bm.verts.new((cx + ca * rx * r * rl, cy + sa * ry * r * rl,
                                  cz - rz * 0.5)))
    apex = b.bm.verts.new((cx, cy, cz + rz * 0.78))
    base = b.bm.verts.new((cx, cy, cz - rz * 0.72))
    ts = top_slot if top_slot is not None else slot
    faces = []
    for i in range(n):
        j = (i + 1) % n
        for quad, sl in (((eq[i], eq[j], up[j], up[i]), ts),
                         ((lo[i], lo[j], eq[j], eq[i]), slot)):
            f = b.bm.faces.new(quad)
            f[b.slot] = sl
            faces.append(f)
        f = b.bm.faces.new((up[i], up[j], apex)); f[b.slot] = ts; faces.append(f)
        f = b.bm.faces.new((lo[j], lo[i], base)); f[b.slot] = slot; faces.append(f)
    return set(faces)


def leaf_blob(b, center, rx, ry, rz, slot, subdiv=2, jag=0.24, seed=0):
    """Ciorchine VOLUMINOS de frunze de arțar: icosfera (subdiv 1-2) turtita
    pe Z la `rz/rx`, cu fiecare varf impins radial aleator (+/- `jag`), deci
    margine zimtata si fete mari neregulate, nu disc si nu glob neted. Se
    suprapune cu vecinii. 80 (subdiv 1) / 320 (subdiv 2) triunghiuri."""
    rnd = _lcg(seed)
    cx, cy, cz = center
    res = bmesh.ops.create_icosphere(b.bm, subdivisions=subdiv, radius=1.0)
    faces = set()
    verts = res["verts"]
    for v in verts:
        k = (1.0 - jag * 0.6) + rnd() * jag * 1.6
        v.co = Vector((cx + v.co.x * rx * k, cy + v.co.y * ry * k,
                       cz + v.co.z * rz * (0.5 + 0.5 * k)))
    return b._tag(verts, slot)


def leaf_pad(b, center, rx, ry, rz, slot, lobes=7, seg_per_lobe=5, rings=5,
             base=0.60, droop=0.45, seed=0):
    """Ciorchine de arțar cu CONTUR LOBAT: perna turtita a carei margine e o
    stea cu `lobes` varfuri ascutite (ca frunza de arțar), lasate usor in jos.
    Inlocuieste `leaf_blob` pe arțari: icosfera zimtata aleator se citea glob
    din camera de joc (oct 2026) -- conturul, nu textura, spune „arțar".

    Inele de la polul de sus la cel de jos; raza orizontala a fiecarui inel e
    inmultita cu profilul de lobi m(theta), plin la ecuator si stins spre poli,
    deci lobii sunt creste care coboara din crestet spre varfurile ascutite.
    Dedesubtul e mai plat decat crestetul. Triunghiuri: 2*S*(rings-1), cu
    S = lobes*seg_per_lobe (7x5, 5 inele -> 280, sub icosfera subdiv 3 de 320)."""
    rnd = _lcg(seed)
    cx, cy, cz = center
    S = lobes * seg_per_lobe
    yaw = rnd() * 2.0 * math.pi
    half = math.pi / lobes * 1.05
    lob = []
    for k in range(lobes):
        # varful lobului cade EXACT pe un varf de inel (k*seg_per_lobe), deci
        # ramane ascutit; varietatea vine din yaw si din lungimea lobului
        lob.append((2.0 * math.pi * k / lobes, 1.0 + (rnd() - 0.3) * 0.22))

    def m_of(th):
        best = base
        for (c, ln) in lob:
            d = (th - c + math.pi) % (2.0 * math.pi) - math.pi
            u = abs(d) / half
            if u < 1.0:
                best = max(best, base + (ln - base) * (1.0 - u) ** 1.25)
        return best + 0.035 * math.sin(th * lobes * 3.0)   # dinti fini

    bm = b.bm
    top = bm.verts.new((cx, cy, cz + rz))
    rows = []
    for i in range(1, rings):
        phi = math.pi * i / rings
        sp, cp = math.sin(phi), math.cos(phi)
        zr = cp * (rz if cp > 0 else rz * 0.45)          # burta mai plata
        row = []
        for j in range(S):
            th = 2.0 * math.pi * j / S
            m = m_of(th)
            w = sp ** 1.5
            k = 1.0 + (m - 1.0) * w
            tip = max(0.0, (m - base) / (1.0 - base + 1e-6))
            z = zr - droop * rz * tip * sp * sp
            a = th + yaw
            row.append(bm.verts.new((cx + math.cos(a) * rx * sp ** 0.8 * k,
                                     cy + math.sin(a) * ry * sp ** 0.8 * k,
                                     cz + z)))
        rows.append(row)
    bot = bm.verts.new((cx, cy, cz - rz * 0.45))
    for j in range(S):
        j2 = (j + 1) % S
        bm.faces.new((top, rows[0][j], rows[0][j2]))
        for r in range(len(rows) - 1):
            a0, a1 = rows[r][j], rows[r][j2]
            b0, b1 = rows[r + 1][j], rows[r + 1][j2]
            bm.faces.new((a0, b0, b1))
            bm.faces.new((a0, b1, a1))
        bm.faces.new((bot, rows[-1][j2], rows[-1][j]))
    verts = [top, bot] + [v for row in rows for v in row]
    return b._tag(verts, slot)


def _srgb_hex_to_linear(hx):
    out = []
    for i in (0, 2, 4):
        c = int(hx[i:i + 2], 16) / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return Vector(out)


def leaf_cards(b, pads, slot, count, base_hex, accent_hex=None, seed=0, size=(0.95, 1.40),
               shell=(0.80, 1.12), spray=0.08, below=0.30, accent=0.20):
    """FRUNZIS DIN CARDURI PUNCTATE: `count` carduri presarate pe coaja
    ciorchinilor. Fiecare card e 2 triunghiuri, se intoarce spre camera si e
    decupat in ~14 puncte rotunde de `assets/shaders/leaf_cards.gdshader` --
    tusele din art of rally (cererea dezvoltatorului, 13 nov 2026).

    Prima incercare (`leaf_dabs`, o pata = un quad cu orientare fixa) cerea
    1200 de quad-uri pe arbore, dubla triunghiurile din valea de artari si tot
    iesea rara si colturoasa. Aici punctele sunt in shader, nu in geometrie.

    De aproape, sub carduri sta doar un miez mic si intunecat (`leaf_core`), deci
    silueta e a cardurilor: stau intre `shell[0]` si `shell[1]` din raza
    ciorchinelui, iar `spray` din ele zboara mai departe, mai mici. Coroana
    plina (`*_Crown`) ramane infatisarea de departe (memoria
    coroana-e-masa-nu-frunze).

    pads: (cx, cy, cz, ax, ay, az_sus, az_jos) -- elipsoidul fiecarui ciorchine.
    Cardurile ingropate adanc in alt ciorchine se arunca.

    CONTRACTUL CU SHADERUL (straturi per varf, scrise in mesh de `card_post`):
      pozitia  coltul cardului, in planul perpendicular pe normala masei:
               centru + t1 * ox + t2 * oy, cu t1 = sus x n, t2 = n x t1.
               Geometrie reala, nu 4 varfuri in acelasi punct: prima varianta
               (degenerata) isi pierdea cardurile in LOD-urile importerului.
      card_o   (ox, oy), coltul fata de centru, in metri  -> UV2
      card_s   samanta cardului, aceeasi pe 4 colturi     -> UV
      card_n   normala MASEI (elipsoid + radial din centrul coroanei),
               aplecata la cel putin 6 grade de verticala: din ea reface
               shaderul planul cardului, iar sus x n nu are voie sa fie zero
      card_c   culoarea ABSOLUTA, liniara: `base_hex` (sau `accent_hex` pe o
               parte din cardurile de sus) x gradient jos-sus x variatie;
               umbra trage spre rosu, nu spre gri."""
    rnd = _lcg(seed * 7919 + 13)
    bm = b.bm
    lay = {}
    for name in ("card_o", "card_s", "card_n", "card_c"):
        lay[name] = bm.verts.layers.float_vector.get(name) or bm.verts.layers.float_vector.new(name)
    base = _srgb_hex_to_linear(base_hex)
    acc = _srgb_hex_to_linear(accent_hex) if accent_hex else None
    z_lo = min(p[2] - p[6] for p in pads)
    z_hi = max(p[2] + p[5] for p in pads)
    z_span = max(z_hi - z_lo, 1e-6)
    cc = Vector((sum(p[0] for p in pads) / len(pads), sum(p[1] for p in pads) / len(pads),
                 (z_lo + z_hi) * 0.5))
    weights = [p[3] * p[4] + p[3] * p[5] + p[4] * p[5] for p in pads]
    wsum = sum(weights)
    verts = []
    made = 0
    min_tilt = math.sin(math.radians(6.0))
    for k, (cx, cy, cz, ax, ay, azu, azd) in enumerate(pads):
        want = int(round(count * weights[k] / wsum))
        got = 0
        tries = 0
        while got < want and tries < want * 12:
            tries += 1
            uz = 2.0 * rnd() - 1.0
            ph = 2.0 * math.pi * rnd()
            ur = math.sqrt(max(0.0, 1.0 - uz * uz))
            ux, uy = ur * math.cos(ph), ur * math.sin(ph)
            if uz < -0.15 and rnd() > below:
                continue
            is_spray = rnd() < spray
            s = shell[0] + rnd() * (shell[1] - shell[0])
            if is_spray:
                s = shell[1] + rnd() * 0.22
            az = azu if uz >= 0.0 else azd
            p = Vector((cx + ax * ux * s, cy + ay * uy * s, cz + az * uz * s))
            buried = False
            for j, q in enumerate(pads):
                if j == k:
                    continue
                qz = q[5] if p.z >= q[2] else q[6]
                e = ((p.x - q[0]) / q[3]) ** 2 + ((p.y - q[1]) / q[4]) ** 2 + ((p.z - q[2]) / qz) ** 2
                if e < 0.55:
                    buried = True
                    break
            if buried:
                continue
            grad = Vector((ux / ax, uy / ay, uz / az)).normalized()
            rad = (p - cc).normalized()
            nm = (grad * 0.55 + rad * 0.45).normalized()
            hz = math.hypot(nm.x, nm.y)
            if hz < min_tilt:      # aproape verticala: aplecata intr-o directie oarecare
                a = 2.0 * math.pi * rnd()
                sz = 1.0 if nm.z >= 0.0 else -1.0
                nm = Vector((math.cos(a) * min_tilt, math.sin(a) * min_tilt,
                             sz * math.sqrt(1.0 - min_tilt * min_tilt)))
            hw = (size[0] + rnd() * (size[1] - size[0])) * 0.5 * (0.6 if is_spray else 1.0)
            hh = hw * (0.85 + rnd() * 0.3)
            t = min(1.0, max(0.0, (p.z - z_lo) / z_span))
            depth = min(1.0, max(0.0, (s - shell[0]) / (shell[1] - shell[0])))
            v = (0.58 + 0.42 * t ** 0.8) * (0.82 + 0.18 * depth) * (0.88 + 0.12 * rnd())
            v = min(1.0, max(0.30, v))
            col = Vector((base[0] * v, base[1] * v * (0.80 + 0.20 * v), base[2] * v * (0.70 + 0.30 * v)))
            if acc is not None and rnd() < accent * (0.25 + 1.5 * t * t):
                v = max(v, 0.88)
                col = acc * v
            sd = Vector((rnd(), rnd(), 0.0))
            t1 = Vector((0, 0, 1)).cross(nm).normalized()
            t2 = nm.cross(t1)
            quad = []
            for (sa, sb) in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                bv = bm.verts.new(p + t1 * (hw * sa) + t2 * (hh * sb))
                bv[lay["card_o"]] = Vector((hw * sa, hh * sb, 0.0))
                bv[lay["card_s"]] = sd
                bv[lay["card_n"]] = nm
                bv[lay["card_c"]] = col
                quad.append(bv)
            bm.faces.new(quad)
            verts.extend(quad)
            got += 1
        made += got
    b._tag(verts, slot)
    return made


def leaf_core(b, pads, slot, shrink=0.68):
    """MIEZUL de sub carduri: cate o icosfera mica (80 de triunghiuri) in fiecare
    ciorchine, la `shrink` din raza lui. Nu e coroana -- e doar ce opreste
    privirea sa treaca prin arbore intre puncte, si ce ascunde cardurile de pe
    partea cealalta (mai putini pixeli desenati de doua ori). `card_post` il
    intuneca."""
    for (cx, cy, cz, ax, ay, azu, azd) in pads:
        res = bmesh.ops.create_icosphere(b.bm, subdivisions=1, radius=1.0)
        verts = res["verts"]
        for v in verts:
            az = azu if v.co.z >= 0.0 else azd
            v.co = Vector((cx + v.co.x * ax * shrink, cy + v.co.y * ay * shrink,
                           cz + v.co.z * az * shrink))
        b._tag(verts, slot)


# Umbra din interiorul coroanei: calda si inchisa, nu o a doua suprafata luminata.
CORE_SHADE = (0.50, 0.38, 0.38)


def card_post(objs):
    """Dupa finish(): muta straturile lui `leaf_cards` in atributele pe care le
    citeste shaderul (culoare, normala, UV = samanta, UV2 = colt) si incalzeste
    umbra coapta a masei de coroana. Arborii fara carduri (pinul niwaki) trec
    neatinsi, cu tot cu coroana."""
    if not any(o.data.attributes.get("card_o") is not None for o in objs):
        return
    for o in objs:
        me = o.data
        if me.attributes.get("card_o") is None:
            # Masa coroanei: AO-ul copt e gri (v, v, v). Umbra ei trebuie sa traga
            # spre aceeasi nuanta ca umbra cardurilor. Trunchiul ramane gri.
            if o.name.endswith("_Crown"):
                ca = me.color_attributes.get("AO")
                for d in ca.data:
                    v = d.color[0]
                    d.color = (v, v * (0.80 + 0.20 * v), v * (0.70 + 0.30 * v), 1.0)
            elif o.name.endswith("_Core"):
                ca = me.color_attributes.get("AO")
                for d in ca.data:
                    v = d.color[0]
                    d.color = (v * CORE_SHADE[0], v * CORE_SHADE[1], v * CORE_SHADE[2], 1.0)
            continue
        n = len(me.vertices)
        off = [Vector(me.attributes["card_o"].data[i].vector) for i in range(n)]
        sd = [Vector(me.attributes["card_s"].data[i].vector) for i in range(n)]
        nor = [Vector(me.attributes["card_n"].data[i].vector).normalized() for i in range(n)]
        col = [Vector(me.attributes["card_c"].data[i].vector) for i in range(n)]
        for name in ("card_o", "card_s", "card_n", "card_c"):
            me.attributes.remove(me.attributes[name])
        ca = me.color_attributes.get("AO")
        for i in range(n):
            ca.data[i].color = (col[i][0], col[i][1], col[i][2], 1.0)
        uv1 = me.uv_layers.get("UVMap") or me.uv_layers.new(name="UVMap")
        uv2 = me.uv_layers.get("UV2") or me.uv_layers.new(name="UV2")
        for lp in me.loops:
            i = lp.vertex_index
            uv1.data[lp.index].uv = (sd[i][0], sd[i][1])
            # Exportatorul glTF intoarce V (v -> 1 - v); il intoarcem inainte, ca
            # in joc UV2.y sa fie chiar coltul, cu semn.
            uv2.data[lp.index].uv = (off[i][0], 1.0 - off[i][1])
        me.uv_layers.active = uv1
        me.normals_split_custom_set_from_vertices(nor)
        me.update()


# ---------------------------------------------------------------------------
# emit -- comun tuturor build-urilor Kyoto
# ---------------------------------------------------------------------------

RESULTS = []


def emit(objs, path, ao, origin="base", bevel=0.0, smooth_angle=None,
         budget=None, bevel_angle=30.0, post=None):
    """Finish pe fiecare nod + export. Pe piesele cu mai multe noduri offsetul
    de origine se calculeaza O DATA pe ansamblu si se aplica identic (memoria
    finish-recentreaza-fiecare-nod-separat). `path` e relativ la
    assets/models/kyoto/ (ex. "structures/yasaka_pagoda.glb")."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    solo = len(objs) == 1
    place = Vector((0.0, 0.0, 0.0))
    if not solo:
        xs, ys, zs = [], [], []
        for o in objs:
            for v in o.data.vertices:
                xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
        place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5,
                        -min(zs)))
    total = 0
    per_node = {}
    for o in objs:
        if not solo:
            for v in o.data.vertices:
                v.co += place
        st = finish(o, bevel=bevel, bevel_angle=bevel_angle, ao=ao,
                    origin=("base" if solo else None), smooth_angle=smooth_angle)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    if post is not None:       # dupa finish, inainte de export (vezi card_post)
        post(objs)
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "kyoto/" + path)
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


# --- Orasul (build_kyoto_town.py): origine pe AXA constructiei -----------------

def emit_keep_xy(objs, path, ao, bevel=0.0, smooth_angle=None, budget=None,
                 bevel_angle=30.0):
    """Ca `emit`, dar PASTREAZA XY asa cum a fost construit si coboara doar pe Z
    (offset calculat o data pe ansamblu). Pentru piesele a caror origine trebuie
    sa fie axa constructiei, nu centrul bbox-ului: casa cu streasina fata mai
    lunga decat spatele, stalpul cu brat al felinarului (origine la stalp)."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    dz = -min(zs)
    total = 0
    per_node = {}
    for o in objs:
        for v in o.data.vertices:
            v.co.z += dz
        st = finish(o, bevel=bevel, bevel_angle=bevel_angle, ao=ao,
                    origin=None, smooth_angle=smooth_angle)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "kyoto/" + path)
    RESULTS.append((path, total, dims, budget, per_node, sz / 1024.0))
    return total


def tri_prism_x(b, x0, x1, pts_yz, slot):
    """Prisma triunghiulara/poligonala cu conturul in planul YZ, extrudata pe X
    intre x0 si x1 (timpanul unui fronton)."""
    n = len(pts_yz)
    a = [b.bm.verts.new((x0, y, z)) for (y, z) in pts_yz]
    c = [b.bm.verts.new((x1, y, z)) for (y, z) in pts_yz]
    b.bm.faces.new(tuple(reversed(a)))
    b.bm.faces.new(tuple(c))
    for i in range(n):
        j = (i + 1) % n
        b.bm.faces.new((a[i], a[j], c[j], c[i]))
    return b._tag(a + c, slot)
