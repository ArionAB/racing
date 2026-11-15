"""Vocabular de forme pentru vegetatia San Francisco (val 2, inventar §5.4: V1, V3, V4, N2).

Se incarca cu exec, DUPA dio_lib (vezi build_sf_plants.py). Aduce, prin exec, si
`kyoto_shapes.py` (fara sa-l modifice): de acolo vin `card_post` si `CORE_SHADE`, adica
CONTRACTUL cu `assets/shaders/leaf_cards.gdshader` (coroana punctata, Palette.CROWN_PREFIX).
Un arbore punctat are patru noduri: `*_Trunk` (atlas), `*_Crown` (infatisarea de departe,
ascunsa de WorldProp), `*_Core` (miezul neluminat) si `*_Leaves` (cardurile punctate).

Ce adauga fisierul asta, si de ce nu ajungea ce exista:
  - `twisted_trunk`: trunchi cu CANELURI care se rasucesc pe lungime (sectiune cu lobi
    rotiti de-a lungul traseului) si dungi deschise pe creste. Chiparosul de Monterey se
    citeste prin trunchiul gros si rasucit; un `taper_sweep` rotund e un tub de plastic.
  - `root_flare`: contraforturi de radacina care intra in pamant (varf la z = 0).
  - `pad_mass` / `core_lens`: masa unui ciorchine TURTIT (perna orizontala), ieftina
    (48 / 14 triunghiuri), in locul `leaf_pad` (280) si al icosferei din `leaf_core` (80):
    chiparosul are 12-15 ciorchini, iar bugetul e ~2k pe arbore.
  - `sf_leaf_cards`: varianta lui `leaf_cards` in care lumina si culoarea cardului vin
    din CIORCHINELE lui, nu din centrul coroanei. La artari (o coroana-dom) normala
    radiala din centru era corecta; la chiparos ar topi straturile orizontale intr-un
    singur glob luminat de sus. Aici fiecare perna are crestetul luminat si burta umbrita,
    deci straturile raman straturi. Contractul cu shaderul e IDENTIC (aceleasi straturi
    card_o / card_s / card_n / card_c, aceeasi `card_post`).

Axe (Blender): X = directia vantului (vine din -X, merge spre +X), Y adancime (+Y Blender =
-Z Godot), Z sus. Originea = baza trunchiului.
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py"), encoding="utf-8").read())

# Ciorchinele (pad) e mereu tuplul lui leaf_cards: (cx, cy, cz, ax, ay, az_sus, az_jos).


def twisted_trunk(b, path, radii, dark, light, segments=10, flutes=4, depth=0.13,
                  turns=0.7, crest=0.55, cap_start=True, cap_end=True, phase=0.0,
                  flat_start=True):
    """Tub cu raza variabila si CANELURI rasucite.

    Raza inelului pe unghiul a, la fractia s din lungime:
        r * (1 + depth * cos(flutes * a + 2 pi * turns * s + phase))
    deci crestele urca in spirala. Fetele de pe creste (cos > `crest`) iau slotul
    `light`, restul `dark`: fibra rasucita se vede si in culoare, nu doar in umbra.
    Triunghiuri: 2 * segments * (inele - 1) + capace."""
    pts = [Vector(p) for p in path]
    frames = b._frames(pts)
    if flat_start:
        # primul inel ORIZONTAL (talpa pe sol): perpendicular pe un trunchi aplecat, jumatate
        # din el ar intra sub z = 0, iar coborarea ansamblului ar ridica tot arborele
        frames[0] = (Vector((0.0, 0.0, 1.0)), Vector((1.0, 0.0, 0.0)), Vector((0.0, 1.0, 0.0)))
    n = len(pts)
    lens = [0.0]
    for i in range(1, n):
        lens.append(lens[-1] + (pts[i] - pts[i - 1]).length)
    total = max(lens[-1], 1e-6)
    bm = b.bm
    rings, crest_of = [], []
    for i, (p, (_t, x, y), r) in enumerate(zip(pts, frames, radii)):
        s = lens[i] / total
        ring, cr = [], []
        for k in range(segments):
            a = 2.0 * math.pi * k / segments
            c = math.cos(flutes * a + 2.0 * math.pi * turns * s + phase)
            rr = r * (1.0 + depth * c)
            ring.append(bm.verts.new(p + x * (rr * math.cos(a)) + y * (rr * math.sin(a))))
            cr.append(c)
        rings.append(ring)
        crest_of.append(cr)
    faces = []
    for i in range(n - 1):
        lo, hi = rings[i], rings[i + 1]
        for k in range(segments):
            j = (k + 1) % segments
            f = bm.faces.new((lo[k], lo[j], hi[j], hi[k]))
            c = (crest_of[i][k] + crest_of[i][j] + crest_of[i + 1][k] + crest_of[i + 1][j]) * 0.25
            f[b.slot] = light if c > crest else dark
            faces.append(f)
    if cap_start:
        f = bm.faces.new(tuple(reversed(rings[0])))
        f[b.slot] = dark
        faces.append(f)
    if cap_end:
        f = bm.faces.new(tuple(rings[-1]))
        f[b.slot] = dark
        faces.append(f)
    return set(faces)


def limb(b, pts, r0, r1, slot, segments=6, cap_end=True):
    """Creanga: tub conic de la r0 la r1 pe polilinie (raza interpolata pe lungime)."""
    pts = [Vector(p) for p in pts]
    lens = [0.0]
    for i in range(1, len(pts)):
        lens.append(lens[-1] + (pts[i] - pts[i - 1]).length)
    total = max(lens[-1], 1e-6)
    radii = [r0 + (r1 - r0) * (l / total) for l in lens]
    return b.taper_sweep(pts, radii, slot, segments=segments, cap_start=True, cap_end=cap_end)


def root_flare(b, base_r, n, slot, seed=0, height=0.95, reach=1.55, thick=0.36,
               segments=6, skip=()):
    """`n` contraforturi de radacina in jurul bazei: pleaca din trunchi la `height`
    si intra in pamant la `reach * base_r`, cu varful exact la z = 0 (raza 0)."""
    rnd = _lcg(seed * 131 + 7)
    out = set()
    for k in range(n):
        if k in skip:
            continue
        a = 2.0 * math.pi * k / n + (rnd() - 0.5) * 0.5
        ca, sa = math.cos(a), math.sin(a)
        rr = reach * (0.85 + 0.3 * rnd())
        th = thick * (0.8 + 0.4 * rnd())
        p0 = Vector((ca * base_r * 0.35, sa * base_r * 0.35, height * (0.8 + 0.3 * rnd())))
        p1 = Vector((ca * base_r * 0.9, sa * base_r * 0.9, height * 0.38))
        p2 = Vector((ca * base_r * rr, sa * base_r * rr, 0.0))
        out |= b.taper_sweep([p0, p1, p2], [th, th * 0.82, 0.0], slot, segments=segments,
                             cap_start=True, cap_end=False)
    return out


def pad_mass(b, pad, slot, seg=8, seed=0, lobe=0.14):
    """Masa unui ciorchine turtit: crestet bombat, ecuator cu lobi (margine de smocuri),
    burta plata. 48 de triunghiuri la seg=8. Elipsoidul e cel al cardurilor."""
    rnd = _lcg(seed * 17 + 3)
    cx, cy, cz, ax, ay, azu, azd = pad
    bm = b.bm
    yaw = rnd() * 2.0 * math.pi
    eq, up, lo = [], [], []
    for k in range(seg):
        a = yaw + 2.0 * math.pi * k / seg
        ca, sa = math.cos(a), math.sin(a)
        m = 1.0 + lobe * (1.0 if k % 2 == 0 else -0.6) * (0.7 + 0.6 * rnd())
        eq.append(bm.verts.new((cx + ca * ax * m, cy + sa * ay * m, cz + azu * 0.05)))
        up.append(bm.verts.new((cx + ca * ax * 0.72, cy + sa * ay * 0.72, cz + azu * 0.78)))
        lo.append(bm.verts.new((cx + ca * ax * 0.70, cy + sa * ay * 0.70, cz - azd * 0.75)))
    top = bm.verts.new((cx, cy, cz + azu))
    bot = bm.verts.new((cx, cy, cz - azd))
    for k in range(seg):
        j = (k + 1) % seg
        bm.faces.new((top, up[k], up[j]))
        bm.faces.new((up[k], eq[k], eq[j], up[j]))
        bm.faces.new((eq[k], lo[k], lo[j], eq[j]))
        bm.faces.new((bot, lo[j], lo[k]))
    return b._tag([top, bot] + eq + up + lo, slot)


def core_lens(b, pads, slot, shrink=0.66, seg=7):
    """MIEZUL de sub carduri, ieftin: o lentila (bicon) in fiecare ciorchine, la
    `shrink` din raza lui. 14 triunghiuri la seg=7. `card_post` il intuneca (CORE_SHADE),
    iar in joc e neluminat (Palette.core_material)."""
    bm = b.bm
    verts = []
    for (cx, cy, cz, ax, ay, azu, azd) in pads:
        ring = []
        for k in range(seg):
            a = 2.0 * math.pi * k / seg
            ring.append(bm.verts.new((cx + math.cos(a) * ax * shrink,
                                      cy + math.sin(a) * ay * shrink, cz)))
        top = bm.verts.new((cx, cy, cz + azu * shrink))
        bot = bm.verts.new((cx, cy, cz - azd * shrink))
        for k in range(seg):
            j = (k + 1) % seg
            bm.faces.new((top, ring[k], ring[j]))
            bm.faces.new((bot, ring[j], ring[k]))
        verts += ring + [top, bot]
    return b._tag(verts, slot)


def core_blob(b, center, rx, ry, rz, slot, subdiv=2):
    """Miez ROTUND pentru o coroana-glob (arborele de strada): o icosfera turtita, 80 de
    triunghiuri la subdiv=2 (in Blender 5, subdiv=1 e icosaedrul de 20). Inlocuieste lentilele per ciorchine acolo unde muchiile lor
    drepte se vad printre carduri."""
    res = bmesh.ops.create_icosphere(b.bm, subdivisions=subdiv, radius=1.0)
    cx, cy, cz = center
    for v in res["verts"]:
        v.co = Vector((cx + v.co.x * rx, cy + v.co.y * ry, cz + v.co.z * rz))
    return b._tag(res["verts"], slot)


def sf_leaf_cards(b, pads, slot, count, base_hex, accent_hex=None, seed=0,
                  size=(0.85, 1.15), shell=(0.80, 1.10), spray=0.06, below=0.18,
                  accent=0.22, radial=0.15, shade_lo=0.46, size_by_pad=False):
    """Cardurile punctate, cu lumina PE CIORCHINE (vezi docstringul modulului).

    Diferente fata de `leaf_cards` (kyoto_shapes):
      - normala masei = gradientul elipsoidului ciorchinelui, amestecat doar cu
        `radial` (implicit 0,15, la Kyoto 0,45) din directia fata de centrul coroanei;
      - valoarea culorii = crestetul ciorchinelui (uz local) mai mult decat inaltimea in
        coroana: crestetele luminate, burtile umbrite, pe FIECARE strat;
      - `below` mic: burta pernei are putine carduri (dedesubtul plat si intunecat al
        chiparosului e miezul, nu frunzisul);
      - culoarea umbrei trage spre albastru-verde (rece), nu spre rosu: verdele adanc
        si putin rece din brief, care ramane lizibil in lumina calda a apusului.
    Restul (straturile per varf, ingroparea, inclinarea minima a normalei) e identic."""
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
    made = 0
    min_tilt = math.sin(math.radians(6.0))
    verts = []
    ax_max = max(p[3] for p in pads)
    for k, (cx, cy, cz, ax, ay, azu, azd) in enumerate(pads):
        want = int(round(count * weights[k] / wsum))
        got = 0
        tries = 0
        while got < want and tries < want * 14:
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
                s = shell[1] + rnd() * 0.18
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
            nm = (grad * (1.0 - radial) + rad * radial).normalized()
            hz = math.hypot(nm.x, nm.y)
            if hz < min_tilt:
                a = 2.0 * math.pi * rnd()
                sz = 1.0 if nm.z >= 0.0 else -1.0
                nm = Vector((math.cos(a) * min_tilt, math.sin(a) * min_tilt,
                             sz * math.sqrt(1.0 - min_tilt * min_tilt)))
            hw = (size[0] + rnd() * (size[1] - size[0])) * 0.5 * (0.6 if is_spray else 1.0)
            if size_by_pad:     # ciorchinii mici (coada politei) au carduri mai mici
                hw *= max(0.55, min(1.0, (ax / ax_max) ** 0.6))
            hh = hw * (0.85 + rnd() * 0.3)
            tg = min(1.0, max(0.0, (p.z - z_lo) / z_span))
            tl = 0.5 + 0.5 * uz
            depth = min(1.0, max(0.0, (s - shell[0]) / (shell[1] - shell[0])))
            t = 0.65 * tl + 0.35 * tg
            v = (shade_lo + (1.0 - shade_lo) * t ** 0.9) * (0.84 + 0.16 * depth) * (0.88 + 0.12 * rnd())
            v = min(1.0, max(0.28, v))
            # umbra rece: rosul cade mai repede decat verdele si albastrul
            col = Vector((base[0] * v * (0.72 + 0.28 * v), base[1] * v, base[2] * v * (0.92 + 0.08 * v)))
            if acc is not None and rnd() < accent * (0.15 + 1.6 * tl * tl * tl):
                v2 = max(v, 0.86)
                col = acc * v2
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


def mop_head(b, center, r, slot, seg=8, seed=0, jag=0.10, flat=0.78):
    """Floarea de hortensie (mophead): dom bombat, usor turtit, cu varfurile impinse
    aleator (granulatia florilor mici). Burta e un singur con scurt, ascuns in tufa.
    seg + 2*seg + seg = 4*seg triunghiuri (32 la seg=8)."""
    rnd = _lcg(seed * 41 + 5)
    cx, cy, cz = center
    bm = b.bm
    r1, r2 = [], []
    for k in range(seg):
        a = 2.0 * math.pi * (k + 0.5 * rnd()) / seg
        ca, sa = math.cos(a), math.sin(a)
        j1 = 1.0 + jag * (rnd() - 0.5) * 2.0
        j2 = 1.0 + jag * (rnd() - 0.5) * 2.0
        r1.append(bm.verts.new((cx + ca * r * 0.62 * j1, cy + sa * r * 0.62 * j1, cz + r * flat * 0.78)))
        r2.append(bm.verts.new((cx + ca * r * 1.0 * j2, cy + sa * r * 1.0 * j2, cz + r * flat * 0.10)))
    top = bm.verts.new((cx, cy, cz + r * flat * (1.0 + jag * 0.5)))
    bot = bm.verts.new((cx, cy, cz - r * 0.55))
    for k in range(seg):
        j = (k + 1) % seg
        bm.faces.new((top, r1[k], r1[j]))
        bm.faces.new((r1[k], r2[k], r2[j], r1[j]))
        bm.faces.new((bot, r2[j], r2[k]))
    return b._tag([top, bot] + r1 + r2, slot)


def fold_leaf(b, base, azim_deg, length, width, rise, slot, droop=0.10, under=True):
    """Frunza lata cu nervura ridicata (V intors): 4 triunghiuri pe fata de sus, alte 4
    pe dedesubt daca `under` (frunza se vede si din lateral). Varful se lasa cu `droop`."""
    a = math.radians(azim_deg)
    d = Vector((math.cos(a), math.sin(a), 0.0))
    s = Vector((-math.sin(a), math.cos(a), 0.0))
    p0 = Vector(base)
    tip = p0 + d * length + Vector((0, 0, rise - droop))
    mid = p0 + d * (length * 0.48) + Vector((0, 0, rise * 0.75))
    rib = mid + Vector((0, 0, width * 0.16))
    left = mid + s * (width * 0.5)
    right = mid - s * (width * 0.5)
    bm = b.bm
    vs = [bm.verts.new(p) for p in (p0, left, tip, right, rib)]
    v0, vl, vt, vr, vrib = vs
    for tri in ((v0, vrib, vl), (vl, vrib, vt), (v0, vr, vrib), (vrib, vr, vt)):
        bm.faces.new(tri)
    if under:
        off = Vector((0, 0, -0.03))
        us = [bm.verts.new(p + off) for p in (p0, left, tip, right)]
        u0, ul, ut, ur = us
        bm.faces.new((u0, ul, ut))
        bm.faces.new((u0, ut, ur))
        vs += us
    return b._tag(vs, slot)


def ball_head(b, center, r, slot, seg=6, seed=0, jag=0.09):
    """Floarea de hortensie ca BILA (r1 a plansei: domurile `mop_head` pe tufa citeau
    ciuperci): poli + trei inele (+55, +15, -30 de grade), varfuri impinse aleator
    (granulatia florilor mici). 6*seg triunghiuri (36 la seg=6); cu umbrire neteda."""
    rnd = _lcg(seed * 43 + 9)
    cx, cy, cz = center
    bm = b.bm
    rings = []
    for k_el, el in enumerate((55.0, 15.0, -30.0)):
        e = math.radians(el)
        ring = []
        for k in range(seg):
            a = 2.0 * math.pi * (k + 0.5 * (k_el % 2)) / seg + rnd() * 0.25
            j = 1.0 + jag * (rnd() - 0.5) * 2.0
            ring.append(bm.verts.new((cx + math.cos(a) * math.cos(e) * r * j,
                                      cy + math.sin(a) * math.cos(e) * r * j,
                                      cz + math.sin(e) * r * 0.92 * j)))
        rings.append(ring)
    top = bm.verts.new((cx, cy, cz + r * 0.95))
    bot = bm.verts.new((cx, cy, cz - r * 0.75))
    for k in range(seg):
        j = (k + 1) % seg
        bm.faces.new((top, rings[0][k], rings[0][j]))
        for r0, r1 in ((rings[0], rings[1]), (rings[1], rings[2])):
            bm.faces.new((r0[k], r1[k], r1[j], r0[j]))
        bm.faces.new((bot, rings[2][j], rings[2][k]))
    return b._tag([top, bot] + [v for rg in rings for v in rg], slot)


def oval_leaf(b, base, azim_deg, length, width, rise, slot):
    """Frunza LATA si OVALA (varf rotunjit), cu nervura ridicata: evantai de 6 triunghiuri
    din centrul nervurii. Doar fata de sus: tufa se vede de sus (camera e la 10 m)."""
    a = math.radians(azim_deg)
    d = Vector((math.cos(a), math.sin(a), 0.0))
    s = Vector((-math.sin(a), math.cos(a), 0.0))
    p0 = Vector(base)
    up = Vector((0, 0, 1))
    pts = [p0,
           p0 + d * (length * 0.30) + s * (width * 0.46) + up * (rise * 0.5),
           p0 + d * (length * 0.75) + s * (width * 0.36) + up * (rise * 0.7),
           p0 + d * length + up * (rise * 0.4),
           p0 + d * (length * 0.75) - s * (width * 0.36) + up * (rise * 0.7),
           p0 + d * (length * 0.30) - s * (width * 0.46) + up * (rise * 0.5)]
    bm = b.bm
    vs = [bm.verts.new(p) for p in pts]
    c = bm.verts.new(p0 + d * (length * 0.48) + up * (rise * 0.95 + width * 0.10))
    for k in range(6):
        j = (k + 1) % 6
        bm.faces.new((c, vs[j], vs[k]))
    return b._tag(vs + [c], slot)


def drop_ground_faces(b, eps=1e-3):
    """Scoate fetele de jos care stau pe sol (z ~ 0, normala in jos): nu se vad niciodata."""
    bm = b.bm
    bm.normal_update()
    dead = [f for f in bm.faces
            if f.normal.z < -0.99 and all(v.co.z < eps for v in f.verts)]
    bmesh.ops.delete(bm, geom=dead, context="FACES_ONLY")

# ---------------------------------------------------------------------------
# emit -- origine pe BAZA TRUNCHIULUI (XY pastrat), coborare pe Z o data pe ansamblu
# ---------------------------------------------------------------------------

RESULTS = []


def emit_sf(objs, path, ao, smooth=None, budget=None, post=None, blend=None):
    """Finish pe fiecare nod + export in assets/models/sanfrancisco/<path>.

    XY se pastreaza asa cum a fost construit (originea = baza trunchiului, nu centrul
    cutiei: coroana chiparosului e aplecata, deci cutia NU e centrata pe trunchi), iar
    Z coboara o data pe ansamblu ca cel mai jos punct sa fie la 0. `smooth` = dict
    sufix-de-nume -> unghi (None = fatete). AO-ul se coace cu `z_range` pe tot
    ansamblul, ca gradientul vertical sa fie acelasi pe trunchi si pe coroana."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    dz = -min(zs)
    for o in objs:
        for v in o.data.vertices:
            v.co.z += dz
    top = max(zs) + dz
    total = 0
    per_node = {}
    for o in objs:
        ang = None
        if smooth:
            for suf, a in smooth.items():
                if o.name.endswith(suf):
                    ang = a
        aod = dict(ao)
        aod.setdefault("z_range", (0.0, top))
        st = finish(o, bevel=0.0, ao=aod, origin=None, smooth_angle=ang)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    if post is not None:
        post(objs)
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    if blend:
        save_blend(objs, blend)
    _, sz = export_glb(objs, "sanfrancisco/" + path)
    RESULTS.append((path, total, dims, budget, per_node, sz / 1024.0))
    return total


def report_sf():
    print()
    bad = 0
    for path, tris, dims, budget, per_node, kb in RESULTS:
        flag = ""
        if budget is not None:
            flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
            bad += tris > budget
        print("%-36s tris=%6d%s  %.2f x %.2f x %.2f m  %.0f kB" %
              (path, tris, flag, dims.x, dims.y, dims.z, kb))
        print("    noduri:", per_node)
    return bad
