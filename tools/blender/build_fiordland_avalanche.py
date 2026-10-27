"""Fiordland — Avalansa de copaci (brief §1.5, val 3 din
docs/asset_briefs/fiordland_kit.md).

  fiordland/effects/tree_avalanche.glb   4 noduri Boulder_A..D

Contractul e al `AvalancheHazard` (scenes/hazards/avalanche_hazard.gd), NU al
plansei: hazardul cauta nodurile DUPA NUME EXACT (`Boulder_A`, `Boulder_B`,
`Boulder_C`, `Boulder_D`), rescaleaza fiecare ca max(X,Z) sa cada intre 1.0 si
2.8 m, si le ROSTOGOLESTE in jurul centrului cu o sfera de coliziune de 0.82 x
raza. Consecinte directe:

  1. Originea in CENTRUL volumului, nu la baza (`finish(origin="center")`).
  2. Fiecare nod COMPACT: raport de laturi <= 1.5:1 pe orice pereche de axe —
     un bulgan lung s-ar rostogoli ca o elice, cu sfera de coliziune lovind
     in gol (avertismentul explicit din brief). Plafonul lasa STUBURI sa
     iasa 0.25-0.45 din marimea nodului (contractul e pe volum, nu pe
     silueta) — sfera de coliziune ramane mai mica decat bbox-ul, exact ca
     un bolovan real cu crengi prinse.

REVIZUIRE COORDONATOR (val 3, a doua trecere): prima versiune avea trunchiuri
subtiri (0.075-0.105*BASE raza) si scurte (<=0.3*BASE), asa ca la orice
distanta de joc citeau ca "nubs" pe o minge de piatra — nu ca lemn. Fix:
STUBURILE domina silueta. Diametru 0.22-0.30 din marimea nodului, ies
0.25-0.45 din marime dincolo de roca pe cel putin 2 laturi, capete RUPTE
(splinter cu 3-4 varfuri, nu con neted). Mixul difera REAL pe piesa, nu doar
prin fractie de fete: A = bolovan strapuns de 2 bustene; B = bolovan cu 3;
C = 3 bustene incrucisati care PRIND un bolovan mic; D = un ghem de 3-4
bustene incrucisati, piatra doar o pana mica infipta, plus o TALPA DE
RADACINI (disc turtit cu 5-6 brate radiale) la un capat de bustean. Bevelul
se opreste pe bustene (unghi mare/dezactivat pe partea de lemn — vezi
`_log_segment`): fatetele de prisma hexagonal/pentagonal raman taiate, doar
bolovanul primeste rotunjirea de bevel.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_avalanche.py
"""

import bpy
import math
from mathutils import Vector

# Sloturile legale pe Fiordland (brief §0.4). ROCK_DARK/ROCK_LIGHT interzise.
BOULDER_ROCK = VOLCANIC_BLACK
ROCK_ALT = ASPHALT_EDGE
LOG = LOG_DARK
MOSS = TROPICAL_GREEN

# Scara comuna de referinta (m) — hazardul rescaleaza fiecare nod la
# max(X,Z) din contract (1.0-2.8), deci geometria de aici poate fi construita
# la o singura scara convenabila, nu la patru marimi diferite.
BASE = 2.0


def _splinter_cap(b, center, axis, radius, slot, seed, segments):
    """Varf de bustean RUPT: nu un con neted, ci 3-4 tepi ASIMETRICI care
    ies din inelul de capat — un splinter real, nu o forma de piatra de
    ascutit. `axis` e directia de-a lungul busteanului (spre exterior).

    Construit ca variatie de raza PE INEL: fiecare varf al inelului final se
    trage spre exterior pe axa cu o lungime si o latime proprii (nu radial
    uniform), deci capacul iese INEGAL — semnatura unei rupturi, nu a unei
    taieri curate.
    """
    rand = _lcg(seed)
    axis = axis.normalized()
    ref = Vector((0, 0, 1)) if abs(axis.z) < 0.9 else Vector((1, 0, 0))
    x = ref.cross(axis).normalized()
    y = axis.cross(x)
    n_spikes = 3 if segments <= 5 else 4
    picks = sorted(rand() for _ in range(n_spikes))
    faces = set()
    ring_verts = []
    for i in range(segments):
        a = 2.0 * math.pi * i / segments
        base = center + (x * math.cos(a) + y * math.sin(a)) * radius
        ring_verts.append((i, base))
    # alege n_spikes indici de inel (fara duplicate) sa ii tragem in afara
    idxs = sorted(set(int(p * segments) % segments for p in picks))
    spike_len = radius * 1.3
    tips = {}
    for idx in idxs:
        i, base = ring_verts[idx]
        stretch = spike_len * (0.6 + rand() * 0.7)
        lateral = (rand() - 0.5) * radius * 0.5
        tip = base + axis * stretch + x * lateral * math.cos(2 * i) \
            + y * lateral * math.sin(2 * i)
        tips[idx] = b.bm.verts.new(tip)
    verts = [b.bm.verts.new(p) for _, p in ring_verts]
    for i in range(segments):
        j = (i + 1) % segments
        vi, vj = verts[i], verts[j]
        if i in tips or j in tips:
            # un tep intre i si j: triunghi in loc de a inchide direct
            tip = tips.get(i) or tips.get(j)
            f = b.bm.faces.new((vi, vj, tip))
            f[b.slot] = slot
            faces.add(f)
        else:
            # inchidere directa la centru (fara tep pe segmentul asta)
            c = b.bm.verts.new(center)
            f = b.bm.faces.new((vi, vj, c))
            f[b.slot] = slot
            faces.add(f)
    return faces


def _log_segment(b, root, tip, radius, slot, seed, segments=6, splinter=True,
                 splinter_root=False):
    """Bustean RUPT, GROS si SCURT: prisma cu `segments` laturi (6 implicit —
    hexagonal, fatete mari si vizibile, nu un cilindru neted), capat de
    radacina retezat drept, capat liber cu SPLINTER (3-4 tepi asimetrici).
    `splinter_root=True` pune splinter si la capatul `root` (bustean care
    STRAPUNGE bolovanul si iese vizibil pe ambele parti, nu doar una).

    Diametrul e mare fata de bolovan (contract coordonator: 0.22-0.30 din
    marimea nodului) — asta il face SA CITEASCA drept lemn de la distanta,
    nu doar sa existe geometric.

    Bevelul se OPRESTE pe bustean: `finish()` ruleaza pe nodul intreg mai
    tarziu, dar bustenii sunt construiti cu fatete DEJA taiate (segments
    mic), deci un `bevel_angle` ridicat la emit() sare peste unghiurile lor
    (60-72 grade intre fatete vecine la 5-6 laturi) si rotunjeste doar
    bolovanul, unde conteaza.
    """
    rand = _lcg(seed)
    root, tip = Vector(root), Vector(tip)
    axis = (tip - root)
    length = axis.length
    if length < 1e-5:
        return set()
    axis_n = axis.normalized()
    # usoara cotitura la mijloc — un bustean rupt nu e niciodata perfect drept
    mid = root.lerp(tip, 0.5)
    perp = Vector((-axis_n.y, axis_n.x, 0.0))
    if perp.length < 1e-5:
        perp = Vector((1, 0, 0))
    mid += perp * (rand() - 0.5) * length * 0.12

    faces = set()
    faces |= b.taper_sweep([root, mid, tip], [radius, radius * 0.94, radius * 0.8],
                           slot, segments=segments,
                           cap_start=not splinter_root, cap_end=False)
    if splinter_root:
        faces |= _splinter_cap(b, root, -axis_n, radius, slot,
                              seed=seed + 700, segments=segments)
    if splinter:
        faces |= _splinter_cap(b, tip, axis_n, radius * 0.8, slot,
                              seed=seed + 900, segments=segments)
    else:
        # capat retezat simplu (radacina ingropata in gramada, nu se vede)
        faces |= b.taper_sweep([tip, tip + axis_n * 0.01], [radius * 0.8] * 2,
                               slot, segments=segments, cap_start=False,
                               cap_end=True)
    return faces


def _root_plate(b, center, axis, plate_r, slot, seed, prongs=6):
    """Talpa de radacini: disc TURTIT cu `prongs` brate radiale ascutite spre
    exterior — capatul unui bustean smuls din pamant, cu radacinile inca
    prinse de el. `axis` e directia busteanului (talpa sta perpendicular pe
    ea, la capatul opus splinter-ului).
    """
    rand = _lcg(seed)
    axis = axis.normalized()
    ref = Vector((0, 0, 1)) if abs(axis.z) < 0.9 else Vector((1, 0, 0))
    x = ref.cross(axis).normalized()
    y = axis.cross(x)
    faces = set()
    hub = b.bm.verts.new(center)
    ring = []
    for i in range(prongs):
        a = 2.0 * math.pi * i / prongs
        ring.append(center + (x * math.cos(a) + y * math.sin(a)) * plate_r * 0.35)
    ring_v = [b.bm.verts.new(p) for p in ring]
    tips = []
    for i in range(prongs):
        a = 2.0 * math.pi * (i + 0.5) / prongs + (rand() - 0.5) * 0.3
        len_r = plate_r * (0.85 + rand() * 0.3)
        tip = center + (x * math.cos(a) + y * math.sin(a)) * len_r \
            + axis * plate_r * 0.12 * (rand() - 0.5)
        tips.append(b.bm.verts.new(tip))
    for i in range(prongs):
        j = (i + 1) % prongs
        f1 = b.bm.faces.new((hub, ring_v[i], tips[i]))
        f2 = b.bm.faces.new((tips[i], ring_v[j], hub))
        f1[b.slot] = slot
        f2[b.slot] = slot
        faces.add(f1)
        faces.add(f2)
    return faces


def _hash01(c):
    """Pseudo-aleator determinist pe pozitie (pentru variatia de slot pe fete)."""
    v = math.sin(c.x * 12.9898 + c.y * 78.233 + c.z * 37.719) * 43758.5453
    return v - math.floor(v)


def _rock(b, center, size, seed, segments=7, rings=3, dev=0.18):
    """Bolovan fatetat: fete pe doua grii + petice de muschi pe cele de sus."""
    faces = b.boulder(center, size, BOULDER_ROCK, seed=seed, segments=segments,
                      rings=rings, deviation=dev)

    def pick(c, n):
        h = _hash01(c)
        if n.z > 0.35 and h < 0.62:
            return True
        return False
    moss = b.retag(faces, MOSS, where=lambda c, n: pick(c, n))
    rest = [f for f in faces if f.is_valid and f not in moss]
    b.retag(rest, ROCK_ALT, where=lambda c, n: _hash01(c * 1.7) < 0.35)
    return faces


def _log(b, root, tip, r_root, r_tip, seed, seg=7, flare=False, broken=True,
         branches=0, roots=0):
    """Bustean scurt: taiat/rupt la capete, cu evazare + radacini la `root`
    (talpa de radacini smulsa) si cu cateva ramuri-ciot."""
    rand = _lcg(seed)
    root, tip = Vector(root), Vector(tip)
    ax = (tip - root)
    length = ax.length
    axn = ax.normalized()
    ref = Vector((0, 0, 1)) if abs(axn.z) < 0.9 else Vector((1, 0, 0))
    px = ref.cross(axn).normalized()
    py = axn.cross(px)
    bend = (px * (rand() - 0.5) + py * (rand() - 0.5)) * length * 0.16
    pts, rads = [], []
    if flare:
        pts += [root, root + axn * length * 0.10, root + axn * length * 0.24]
        rads += [r_root * 1.85, r_root * 1.30, r_root * 1.04]
    else:
        pts += [root, root + axn * length * 0.24]
        rads += [r_root, r_root * 1.02]
    pts += [root + axn * length * 0.55 + bend, root + axn * length * 0.88 + bend * 0.6, tip]
    rads += [(r_root + r_tip) * 0.5, r_tip * 1.05, r_tip]
    b.taper_sweep(pts, rads, LOG, segments=seg, cap_start=True, cap_end=not broken)
    if broken:
        _splinter_cap(b, tip, axn, r_tip, LOG, seed + 3, seg)
    if flare:
        # muschi pe talpa de radacini
        b.retag([f for f in b.bm.faces if f.is_valid], MOSS,
                where=lambda c, n: (c - root).length < length * 0.17 and _hash01(c) < 0.8)
    for i in range(roots):
        a = 2.0 * math.pi * (i + 0.3 * rand()) / roots
        dirv = (px * math.cos(a) + py * math.sin(a))
        p0 = root + axn * length * 0.03 + dirv * r_root * 1.3
        p1 = p0 + dirv * r_root * 0.8 - axn * r_root * 0.45
        p2 = p1 + dirv * r_root * 0.7 - axn * r_root * 0.8
        faces = b.taper_sweep([p0, p1, p2], [r_root * 0.50, r_root * 0.38, r_root * 0.12], LOG,
                              segments=5, cap_start=False, cap_end=True)
        b.retag(list(faces), MOSS, where=lambda c, n: _hash01(c) < 0.25)
    for i in range(branches):
        f = 0.35 + 0.5 * rand()
        base = root + axn * length * f
        sd = (px * (rand() - 0.5) * 2.0 + py * (rand() - 0.5) * 2.0).normalized()
        d = (sd * 0.85 + axn * 0.35).normalized()
        blen = 0.30 + 0.22 * rand()
        b.taper_sweep([base - d * r_root * 0.3, base + d * blen * 0.5 + Vector((0, 0, 0.04)),
                       base + d * blen + Vector((0, 0, 0.10))],
                      [r_root * 0.36, r_root * 0.28, r_root * 0.14], LOG,
                      segments=5, cap_start=False, cap_end=True)


def _tangle_A(seed):
    """A: mai mult roca. Bolovan mare, apucat jos de un bustean cu talpa de
    radacini si strapuns sus de unul rupt, cu ciot de ramura."""
    b = Builder()
    _rock(b, (0.1, 0.0, 0.05), (1.8, 1.65, 1.5), seed + 1)
    _log(b, (-1.05, -0.35, -0.40), (0.55, -0.05, -0.30), 0.23, 0.17, seed + 10,
         flare=True, broken=False, branches=1, roots=5)
    _log(b, (0.45, 0.75, -0.60), (0.80, 0.55, 0.80), 0.20, 0.15, seed + 20,
         broken=True, branches=1)
    return b.to_object("Boulder_A")


def _tangle_B(seed):
    """B: bolovan mijlociu, doua trunchiuri rupte il incrucisea, unul cu
    talpa de radacini."""
    b = Builder()
    _rock(b, (-0.1, 0.05, -0.1), (1.35, 1.25, 1.15), seed + 1, dev=0.2)
    _log(b, (0.95, -0.55, -0.45), (-0.55, 0.25, 0.20), 0.24, 0.17, seed + 10,
         flare=True, broken=False, branches=1, roots=5)
    _log(b, (-0.60, 0.75, -0.15), (0.50, 0.15, 0.95), 0.18, 0.13, seed + 20,
         broken=True, branches=2)
    _log(b, (-0.85, -0.55, -0.25), (-0.15, -0.20, 0.45), 0.15, 0.11, seed + 30,
         broken=True)
    return b.to_object("Boulder_B")


def _tangle_C(seed):
    """C: trei trunchiuri scurte prind un bolovan mic; lemnul domina."""
    b = Builder()
    _rock(b, (0.0, 0.05, -0.05), (0.85, 0.8, 0.75), seed + 1, segments=6, rings=3)
    _log(b, (-1.00, -0.30, -0.35), (0.85, 0.25, 0.15), 0.25, 0.18, seed + 10,
         flare=True, broken=True, branches=2, roots=6)
    _log(b, (0.45, 0.85, -0.50), (-0.20, -0.65, 0.85), 0.19, 0.14, seed + 20,
         broken=True, branches=1)
    _log(b, (0.50, -0.70, 0.55), (-0.45, 0.50, -0.55), 0.16, 0.12, seed + 30,
         broken=True)
    return b.to_object("Boulder_C")


def _tangle_D(seed):
    """D: ghem de lemn: patru trunchiuri si doua talpi de radacini, piatra doar
    o pana mica."""
    b = Builder()
    _rock(b, (0.1, 0.0, -0.25), (0.65, 0.6, 0.5), seed + 1, segments=6, rings=2)
    _log(b, (-1.00, -0.30, -0.15), (0.90, 0.15, 0.25), 0.25, 0.17, seed + 10,
         flare=True, broken=True, branches=2, roots=6)
    _log(b, (0.80, -0.70, -0.55), (-0.30, 0.85, 0.50), 0.22, 0.15, seed + 20,
         flare=True, broken=True, branches=1, roots=5)
    _log(b, (-0.40, 0.70, -0.60), (0.55, -0.10, 0.85), 0.17, 0.12, seed + 30,
         broken=True, branches=2)
    _log(b, (0.30, -0.15, 0.80), (-0.35, 0.10, -0.80), 0.14, 0.10, seed + 40,
         broken=True)
    return b.to_object("Boulder_D")


# --- emit ----------------------------------------------------------------

clear_built()
results = []

AO_TANGLE = dict(samples=20, dist=1.6, gradient="vertical",
                 low=0.48, high=1.00, power=0.88, floor=0.20)


def _bbox(obj):
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def _aspect_report(obj, name):
    (x0, x1), (y0, y1), (z0, z1) = _bbox(obj)
    sx, sy, sz = x1 - x0, y1 - y0, z1 - z0
    dims = {"X": sx, "Y": sy, "Z": sz}
    pairs = [("X/Y", sx / max(sy, 1e-6)), ("X/Z", sx / max(sz, 1e-6)),
             ("Y/Z", sy / max(sz, 1e-6))]
    worst = max(max(r, 1.0 / r) for _, r in pairs)
    # fractia de varfuri din afara sferei de 0.82 * jumatate din max(X,Z) —
    # aceeasi formula pe care hazardul o foloseste pentru sfera de coliziune
    # (HULL_FRACTION = 0.82), centrata pe originea (0,0,0) a nodului (center).
    half_max_xz = max(sx, sz) * 0.5
    hull_r = half_max_xz * 0.82
    verts = obj.data.vertices
    outside = sum(1 for v in verts if v.co.length > hull_r)
    frac_outside = outside / max(len(verts), 1)
    print("  %-10s dims X=%.2f Y=%.2f Z=%.2f  aspect max=%.2f:1  "
          "hull(r=%.2f) varfuri-afara=%.0f%%"
          % (name, sx, sy, sz, worst, hull_r, 100.0 * frac_outside))
    return worst, frac_outside


def emit_avalanche(objs):
    # bevel_angle mare (78, nu implicitul 30 si mai mare decat 70-ul din
    # prima trecere): bustenii sunt acum prisme de 6 laturi cu unghiuri de
    # 60 grade intre fatete vecine (180 - 360/6) — un prag de 70 tot le
    # rotunjea usor, stergand exact taietura ceruta ("fatetele de prisma
    # raman taiate"). La 78 grade doar bolovanul (curbura mult mai lina intre
    # inele) mai primeste bevel vizibil; bustenii raman fatetati.
    # scara v1 (max X,Z): A 2.6 / B 1.9 / C 1.6 / D 1.5 m — hazardul rescaleaza
    # oricum la 1.0-2.8, dar diferenta de marime intre noduri ramane.
    targets = {"Boulder_A": 2.6, "Boulder_B": 1.9, "Boulder_C": 1.6, "Boulder_D": 1.5}
    for o in objs:
        xs = [v.co.x for v in o.data.vertices]
        zs = [v.co.z for v in o.data.vertices]
        cur = max(max(xs) - min(xs), max(zs) - min(zs))
        k = targets[o.name] / cur
        for v in o.data.vertices:
            v.co *= k
    for o in objs:
        finish(o, bevel=0.02, bevel_angle=78.0, ao=AO_TANGLE, origin="center",
              smooth_angle=40.0)
    path, size = export_glb(objs, "fiordland/effects/tree_avalanche.glb")
    print("export:", path, "(%.1f KB)" % (size / 1024.0))
    return path, size


def _report_slot_fractions_from_glb(glb_path, log_slot=LOG, rock_slot=BOULDER_ROCK):
    """Citeste tree_avalanche.glb si raporteaza, per nod, procentul de fete
    (triunghiuri) pe LOG_DARK vs MARBLE_GREY — cerinta coordonatorului,
    "colour proof... din GLB", nu din intentia scriptului."""
    import json
    import struct
    with open(glb_path, "rb") as f:
        data = f.read()
    _, _, length = struct.unpack("<4sII", data[0:12])
    off = 12
    chunks = {}
    while off < length:
        clen, ctype = struct.unpack("<I4s", data[off:off + 8])
        off += 8
        chunks[ctype] = data[off:off + clen]
        off += clen
    gltf = json.loads(chunks[b"JSON"])
    blob = chunks.get(b"BIN\x00", b"")

    def read_accessor(acc_idx):
        acc = gltf["accessors"][acc_idx]
        bv = gltf["bufferViews"][acc["bufferView"]]
        comp_sizes = {5121: 1, 5123: 2, 5125: 4, 5126: 4}
        comp_fmt = {5121: "B", 5123: "H", 5125: "I", 5126: "f"}
        n_comp = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[acc["type"]]
        stride = bv.get("byteStride", comp_sizes[acc["componentType"]] * n_comp)
        base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
        fmt = "<" + comp_fmt[acc["componentType"]] * n_comp
        out = []
        for i in range(acc["count"]):
            o2 = base + i * stride
            out.append(struct.unpack(fmt, blob[o2:o2 + struct.calcsize(fmt)]))
        return out

    log_u = slot_u(log_slot)
    rock_u = slot_u(rock_slot)
    print()
    print("colour proof (fractie de FETE, din UV exportat, LOG_DARK vs MARBLE_GREY):")
    for node in gltf.get("nodes", []):
        if "mesh" not in node:
            continue
        name = node.get("name", "?")
        mesh = gltf["meshes"][node["mesh"]]
        log_n, rock_n, other_n = 0, 0, 0
        for prim in mesh["primitives"]:
            attrs = prim["attributes"]
            if "TEXCOORD_0" not in attrs:
                continue
            idx = [i[0] for i in read_accessor(prim["indices"])] \
                if "indices" in prim else list(range(len(read_accessor(attrs["TEXCOORD_0"]))))
            uv = read_accessor(attrs["TEXCOORD_0"])
            for t in range(0, len(idx) - 2, 3):
                u = uv[idx[t]][0]
                if abs(u - log_u) < 1e-3:
                    log_n += 1
                elif abs(u - rock_u) < 1e-3:
                    rock_n += 1
                else:
                    other_n += 1
        total = log_n + rock_n + other_n
        if total == 0:
            continue
        print("  %-10s LOG_DARK %5.1f%%   MARBLE_GREY %5.1f%%   altele %5.1f%%  (%d tri)"
              % (name, 100.0 * log_n / total, 100.0 * rock_n / total,
                 100.0 * other_n / total, total))


specs = [
    ("Boulder_A", 5601, _tangle_A),
    ("Boulder_B", 5611, _tangle_B),
    ("Boulder_C", 5621, _tangle_C),
    ("Boulder_D", 5631, _tangle_D),
]

objs = []
for name, seed, builder_fn in specs:
    objs.append(builder_fn(seed))

path, size = emit_avalanche(objs)

print()
total = 0
for o in objs:
    tris = tri_count(o)
    total += tris
    flag = "OK" if tris <= 300 else "DEPASIT (buget 300)"
    print("%-12s tris=%4d  %s" % (o.name, tris, flag))
print("TOTAL tree_avalanche: %d tris" % total)
print()
for o in objs:
    _aspect_report(o, o.name)

_report_slot_fractions_from_glb(path)

save_blend(objs, "fiordland_avalanche.blend")
