"""Kyoto -- gradina si padurea de bambus (brief docs/asset_briefs/kyoto_kit.md §1.8).

  kyoto/props/shiba_fence.glb          gard de nuiele, modul 3 m, capete identice
  kyoto/plants/karikomi_shrub_a/_b.glb tufe tunse rotund, fatetate
  kyoto/rocks/garden_rock_a/_b/_c.glb  pietre de gradina; a si c cu `Rock_Moss`
  kyoto/rocks/stepping_stones.glb      3 placi octogonale joase
  kyoto/rocks/moss_mound.glb           movila de muschi cu pietre iesite
  kyoto/props/leaf_pile.glb            gramada de frunze (placute mici)
  kyoto/plants/moso_culm.glb           o tulpina de 20 m, 6 segmente (MultiMesh)
  kyoto/plants/bamboo_crown.glb        tufa de 12 tulpini cu frunze

Formele sunt FATETATE (fete mari, plate), nu sfere: planșa e low-poly pictat.
Rocile sunt invelitori convexe din ~11 puncte (fete mari neregulate), colorate
pe fata dupa normala (sus bej, lateral gri, umbra gri-inchis) -- decuparea
castiga contractul. Primitivele rotunde au `segments` setat.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_kyoto_garden.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py")).read())

MOSS = TROPICAL_GREEN          # -> clasa `moss` pe nodurile *_Moss
STALK = CACTUS_GREEN
NODE_RING = DRY_VEGETATION
LEAF_BAMBOO = CACTUS_GREEN
SHRUB_TOP = CACTUS_GREEN
SHRUB_SIDE = TROPICAL_GREEN

AO_SMALL = dict(gradient="vertical", samples=20, dist=1.6, low=0.62, high=1.0,
                power=0.8, floor=0.40)
AO_TALL = dict(gradient="vertical", samples=12, dist=2.0, low=0.72, high=1.0,
               power=0.6, floor=0.55)

clear_built()


# ---------------------------------------------------------------------------
# primitive locale
# ---------------------------------------------------------------------------

def _dome(b, center, rx, ry, rz, rings, segs, jag, seed, slot_fn, lift=0.0):
    """Cupola fatetata: `rings` inele (ecuator -> apex), `segs` segmente pe inel,
    fiecare varf impins aleator. Baza (z = cz) e plata si inchisa. slot_fn(nz, rnd)
    alege slotul fetei dupa normala."""
    rnd = _lcg(seed)
    cx, cy, cz = center
    ring_v = []
    for k in range(rings):
        e = (math.pi / 2) * (k / float(rings))
        ring = []
        for i in range(segs):
            a = 2 * math.pi * (i + (rnd() - 0.5) * 0.35) / segs
            kk = 1.0 + (rnd() - 0.5) * 2 * jag
            r = math.cos(e) * kk
            z = math.sin(e) * rz * (1.0 + (rnd() - 0.5) * jag) + (lift if k > 0 else 0.0)
            ring.append(b.bm.verts.new((cx + math.cos(a) * rx * r,
                                        cy + math.sin(a) * ry * r, cz + z)))
        ring_v.append(ring)
    apex = b.bm.verts.new((cx + (rnd() - 0.5) * rx * 0.2, cy + (rnd() - 0.5) * ry * 0.2,
                           cz + rz * (1.0 + (rnd() - 0.5) * jag)))
    faces = []
    for lo, hi in zip(ring_v, ring_v[1:]):
        for i in range(segs):
            j = (i + 1) % segs
            faces.append(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])))
    top = ring_v[-1]
    for i in range(segs):
        j = (i + 1) % segs
        faces.append(b.bm.faces.new((top[i], top[j], apex)))
    base = b.bm.faces.new(tuple(reversed(ring_v[0])))
    faces.append(base)
    for f in faces:
        f.normal_update()
        n = f.normal
        # normala geometrica brut-orientata (recalc la to_object); aproximam cu
        # directia dinspre centru pentru alegerea slotului
        c = f.calc_center_median() - Vector(center)
        nv = c.normalized() if c.length > 1e-6 else Vector((0, 0, 1))
        if f is base:
            nv = Vector((0, 0, -1))
        f[b.slot] = slot_fn(nv, rnd)
    return set(faces)


def _hull_rock(b, size, seed, slot_fn, center=(0, 0, 0), base_r=(0.50, 0.46),
               mid=(0.45, 0.50), top=(0.95, 0.20), nbase=6, nmid=6, ntop=3,
               yaw=0.0, merge_deg=4.0):
    """Piatra cu fete MARI: invelitoarea convexa a ~11 puncte (inel de baza plat,
    inel de mijloc, cateva puncte sus), apoi fetele coplanare se topesc. size =
    (sx, sy, sz); `mid` = (cota relativa, raza relativa); `top` = (cota, raza)."""
    rnd = _lcg(seed)
    sx, sy, sz = size
    cx, cy, cz = center
    pts = []

    def ring(n, z_rel, r_rel, off, zj):
        for i in range(n):
            a = yaw + 2 * math.pi * (i + off + (rnd() - 0.5) * 0.55) / n
            k = r_rel * (0.78 + 0.44 * rnd())
            z = z_rel * sz * (1.0 + (rnd() - 0.5) * zj)
            pts.append((cx + math.cos(a) * sx * k, cy + math.sin(a) * sy * k, cz + z))

    ring(nbase, 0.0, base_r[0] + 0.0, 0.0, 0.0)
    ring(nmid, mid[0], mid[1], 0.5, 0.35)
    ring(ntop, top[0], top[1], 0.3, 0.08)
    verts = [b.bm.verts.new(p) for p in pts]
    res = bmesh.ops.convex_hull(b.bm, input=verts)
    dead = res.get("geom_interior", []) + res.get("geom_unused", [])
    bmesh.ops.delete(b.bm, geom=list({g for g in dead if isinstance(g, bmesh.types.BMVert)}),
                     context="VERTS")
    faces = [f for f in b.bm.faces if all(v in verts for v in f.verts)]
    bmesh.ops.dissolve_limit(b.bm, angle_limit=math.radians(merge_deg),
                             verts=[v for v in verts if v.is_valid],
                             edges=list({e for f in faces if f.is_valid for e in f.edges}))
    out = set()
    cen = Vector((cx, cy, cz + sz * 0.4))
    for f in b.bm.faces:
        if not f.is_valid or not all(v in verts for v in f.verts):
            continue
        c = f.calc_center_median() - cen
        n = c.normalized()
        f[b.slot] = slot_fn(n, c.z, rnd)
        out.add(f)
    return out


def _plate(b, center, normal, spin, length, width, thick, slot):
    """Placuta romboidala cu grosime (frunza): 12 triunghiuri."""
    n = Vector(normal).normalized()
    u = Vector(spin) - n * Vector(spin).dot(n)
    if u.length < 1e-5:
        u = n.cross(Vector((1, 0, 0)))
    u.normalize()
    v = n.cross(u)
    c = Vector(center)
    L, W, T = length * 0.5, width * 0.5, thick * 0.5
    ring = [(L, 0), (0, W), (-L, 0), (0, -W)]
    top = [b.bm.verts.new(c + u * a + v * w + n * T) for a, w in ring]
    bot = [b.bm.verts.new(c + u * a + v * w - n * T) for a, w in ring]
    fs = [b.bm.faces.new(tuple(top)), b.bm.faces.new(tuple(reversed(bot)))]
    for i in range(4):
        j = (i + 1) % 4
        fs.append(b.bm.faces.new((top[i], bot[i], bot[j], top[j])))
    for f in fs:
        f[b.slot] = slot
    return set(fs)


def _stone_slot(n, z, rnd):
    """Culoarea pe fata, ca pe decupare: sus bej, lateral gri deschis, partea
    din umbra (dreapta in cadrul implicit, azimut 125) gri-inchis."""
    if n.z > 0.62:
        return CONCRETE
    shade = n.x * (-0.82) + n.y * (-0.57)
    if shade > 0.38:
        return ASPHALT_EDGE
    return MARBLE_GREY if rnd() < 0.55 else CONCRETE


def _moss_pad(b, x, y, rx, ry, rz, seed, z0=-0.03):
    return _dome(b, (x, y, z0), rx, ry, rz, 2, 7, 0.22, seed,
                 lambda n, rnd: MOSS)


# ---------------------------------------------------------------------------
# gardul de nuiele
# ---------------------------------------------------------------------------

def build_shiba_fence():
    """`shiba_fence.png` -- lista de elemente (inainte de primul vertex):

    - 2 stalpi de capat GROSI (0,26 x 0,16 m) si inalti (1,1 m), cate o
      jumatate (0,13 m) pe fiecare capat: doua module lipite fac un stalp
      intreg, capetele sunt identice si plane la y = +-1,5;
    - 3 stalpi intermediari SUBTIRI (0,07 m) care trec de lisa de sus cu
      ~0,2 m (nasturii din decupare), la y = -0,75 / 0 / +0,75;
    - 2 lise orizontale subtiri (cote 0,28 si 0,70) pe ambele fete;
    - 8 nuiele verticale GROASE (hexagon Ø 0,22 m, h 0,80) intre stalpi, cu
      goluri de ~0,14 m intre ele, alternand verde-inchis / verde-olive;
    - lemn portocaliu-ocru (SAND_MID); nuiele TROPICAL_GREEN / CACTUS_GREEN.
    Cote: 3,0 x 0,18 x 1,1 m, lungimea pe Y.
    """
    b = Builder()
    wood, cap, g1, g2 = SAND_MID, WOOD, TROPICAL_GREEN, CACTUS_GREEN
    for sgn in (-1, 1):
        b.box((0.0, sgn * 1.435, 0.55), (0.16, 0.13, 1.1), wood)
        b.box((0.0, sgn * 1.435, 1.1), (0.16, 0.13, 0.03), cap)
    for y in (-0.75, 0.0, 0.75):
        b.box((0.0, y, 0.47), (0.08, 0.07, 0.94), wood)
        b.box((0.0, y, 0.94), (0.08, 0.07, 0.03), cap)
    ys = [-1.16, -0.92, -0.58, -0.34, 0.34, 0.58, 0.92, 1.16]
    ys = [-1.18, -0.95, -0.53, -0.3, 0.3, 0.53, 0.95, 1.18]
    for k, y in enumerate(ys):
        b.cylinder((0.0, y, 0.42), 0.105, 0.80, g1 if k % 2 == 0 else g2, segments=6)
    for z in (0.28, 0.70):
        for xs in (0.07, -0.07):
            b.box((xs, 0.0, z), (0.05, 2.76, 0.06), wood)
    return [b.to_object("Shiba_Fence")]


# ---------------------------------------------------------------------------
# tufele karikomi
# ---------------------------------------------------------------------------

def _shrub(name, rx, ry, rz, seed, segs=11):
    """Dom fatetat: 3 inele x `segs` segmente + apex; varfuri impinse tare, ca sa
    iasa fete mari NEREGULATE. Fetele spre lumina (stanga-sus) pe CACTUS_GREEN,
    cele din umbra (dreapta) pe TROPICAL_GREEN, """
    b = Builder()

    def slot_fn(n, rnd):
        shade = n.x * (-0.82) + n.y * (-0.57)
        if shade < -0.15:
            return SHRUB_SIDE
        return SHRUB_TOP if (shade > 0.1 or n.z > 0.6) else SHRUB_SIDE

    _dome(b, (0, 0, 0), rx, ry, rz, 3, segs, 0.2, seed, slot_fn)
    return [b.to_object(name)]


def build_karikomi_a():
    """`karikomi_shrub_a.png`: dom rotund fatetat (nu sfera): ~36 fete mari,
    baza plata, fete de sus mai luminoase. Ø 1,6 m, h 0,95 m."""
    return _shrub("Karikomi_A", 0.8, 0.8, 0.82, 21)


def build_karikomi_b():
    """`karikomi_shrub_b.png`: dom mai JOS si mai lat, usor asimetric, (fetele ruginii
    discrete din decupare nu s-au modelat). Ø 2,0 m, h 0,9 m."""
    return _shrub("Karikomi_B", 1.0, 0.8, 0.9, 34, segs=12)


# ---------------------------------------------------------------------------
# pietrele de gradina
# ---------------------------------------------------------------------------

def _rock(name, size, seed, moss_pads=(), **kw):
    b = Builder()
    _hull_rock(b, size, seed, _stone_slot, **kw)
    objs = [b.to_object(name + "_Stone")]
    if moss_pads:
        m = Builder()
        for (x, y, rx, ry, rz, s) in moss_pads:
            _moss_pad(m, x, y, rx, ry, rz, s)
        objs.append(m.to_object(name + "_Moss"))
    return objs


def build_rock_a():
    """`garden_rock_a.png`: masiv lat, 5-6 fete mari (sus bej, fata lumina,
    fata dreapta in umbra) + o piatra mai mica sprijinita in stanga-fata;
    musche GROS la baza in fata si in stanga. 1,6 x 1,25 x 1,0 m."""
    b = Builder()
    _hull_rock(b, (1.5, 1.25, 1.0), 14, _stone_slot, center=(0.12, 0.0, 0),
               base_r=(0.5, 0.5), mid=(0.52, 0.5), top=(0.97, 0.3), ntop=4)
    _hull_rock(b, (0.85, 0.65, 0.5), 19, _stone_slot, center=(-0.7, 0.3, 0),
               base_r=(0.5, 0.5), mid=(0.55, 0.5), top=(0.95, 0.3), ntop=3)
    m = Builder()
    for (x, y, rx, ry, rz, sd) in ((-0.2, 0.62, 0.5, 0.3, 0.26, 3), (0.35, 0.58, 0.4, 0.26, 0.22, 4),
                                   (-0.9, 0.0, 0.3, 0.28, 0.22, 5)):
        _moss_pad(m, x, y, rx, ry, rz, sd)
    return [b.to_object("Rock_Stone"), m.to_object("Rock_Moss")]


def build_rock_b():
    """`garden_rock_b.png`: bolovan LUNG si jos (fara muschi), cu creasta
    dreapta (2 puncte sus) si doua benzi de fete paralele pe versantul din
    fata; fata din dreapta in umbra. 1,3 x 0,8 x 0,7 m."""
    return _rock("RockB", (1.4, 0.85, 0.62), 7, (), base_r=(0.5, 0.5), nbase=8, nmid=8,
                 mid=(0.55, 0.52), top=(0.97, 0.3), ntop=2, yaw=-0.94)


def build_rock_c():
    """`garden_rock_c.png`: bloc cu VARF LAT PLAT (5 puncte sus), pereti aproape
    verticali, fata din dreapta in umbra; muschi lat la baza in fata (doua
    petice mari) si unul mic in dreapta-fata. 1,2 x 1,1 x 0,95 m."""
    b = Builder()
    _hull_rock(b, (1.2, 1.1, 0.95), 25, _stone_slot, base_r=(0.5, 0.5), nbase=7,
               mid=(0.5, 0.5), nmid=7, top=(0.97, 0.45), ntop=5)
    m = Builder()
    for (x, y, rx, ry, rz, sd) in ((-0.4, 0.45, 0.34, 0.3, 0.26, 8), (-0.05, 0.56, 0.3, 0.22, 0.22, 9),
                                   (0.4, 0.5, 0.22, 0.2, 0.15, 10)):
        _moss_pad(m, x, y, rx, ry, rz, sd)
    return [b.to_object("RockC_Stone"), m.to_object("RockC_Moss")]


# ---------------------------------------------------------------------------
# pietrele de pas
# ---------------------------------------------------------------------------

def build_stepping_stones():
    """`stepping_stones.png`: 3 placi octogonale GROASE (grosime ~25% din
    diametru), laminate: doua straturi suprapuse (cel de sus usor rotit si
    mai mic) cu guler teșit; sus gri-mov deschis, lateral gri, partea din
    umbra (dreapta) gri-inchis. Una mare, una mijlocie, una mica, in zigzag
    pe Y, ~2,6 m total. Nod unic `Stepping_Stone`."""
    b = Builder()
    for (x, y, r, h, yaw) in ((0.1, -0.8, 0.62, 0.24, 8.0),
                              (-0.5, 0.15, 0.42, 0.18, 20.0),
                              (0.35, 1.0, 0.34, 0.15, -6.0)):
        layers = ((0.0, h * 0.5, r, yaw, False), (h * 0.5, h * 0.5, r * 0.95, yaw + 9.0, True))
        for (z0, dh, rr, yw, chamfer) in layers:
            rot = Matrix.Rotation(math.radians(yw), 4, "Z")
            parts = [(z0 + dh * (0.4 if chamfer else 0.5), rr, rr, dh * (0.8 if chamfer else 1.0))]
            if chamfer:
                parts = [(z0 + dh * 0.35, rr, rr, dh * 0.7), (z0 + dh * 0.85, rr, rr * 0.88, dh * 0.3)]
            for (z, rb, rt, dd) in parts:
                fs = b.frustum((0, 0, z), rb, rt, dd, MARBLE_GREY, segments=8)
                vs = {v for f in fs for v in f.verts}
                for v in vs:
                    p = rot @ Vector(v.co)
                    v.co = Vector((p.x + x, p.y + y, p.z))
                for f in fs:
                    f.normal_update()
                    nrm = f.normal
                    shade = nrm.x * (-0.82) + nrm.y * (-0.57)
                    if nrm.z > 0.5:
                        f[b.slot] = MARBLE_GREY
                    elif shade > 0.3:
                        f[b.slot] = ASPHALT_EDGE
                    else:
                        f[b.slot] = CONCRETE if rb != rt else MARBLE_GREY
    return [b.to_object("Stepping_Stone")]


# ---------------------------------------------------------------------------
# movila de muschi
# ---------------------------------------------------------------------------

def build_moss_mound():
    """`moss_mound.png`: movila lunga si joasa de muschi (3 x 2,4 x 1 m) cu
    margine neregulata; din ea ies 5 pietre MARI fatetate: una lata pe creasta
    (bej cu fata de umbra), doua mijlocii spre dreapta, doua mici in stanga-fata.
    Noduri `Moss_Mound` (`TROPICAL_GREEN`, clasa `moss`) si `Moss_Stone`."""
    m = Builder()
    mound = lambda n, rnd: MOSS
    _dome(m, (0, 0, 0), 1.5, 1.15, 0.5, 3, 12, 0.10, 41, mound)
    _dome(m, (-0.3, 0.1, 0), 1.0, 0.9, 0.62, 3, 9, 0.12, 42, mound)
    _dome(m, (0.8, -0.1, 0), 0.8, 0.7, 0.5, 3, 9, 0.12, 43, mound)
    s = Builder()
    for k, (x, y, sx, sy, h, z0, yaw) in enumerate((
            (-0.2, 0.05, 1.5, 1.0, 0.62, 0.34, 20), (0.7, -0.5, 0.9, 0.6, 0.42, 0.18, 50),
            (1.15, 0.2, 0.62, 0.5, 0.36, 0.12, 10), (-1.05, -0.35, 0.6, 0.5, 0.36, 0.06, 30),
            (0.2, 0.6, 0.55, 0.42, 0.3, 0.1, 70))):
        _hull_rock(s, (sx, sy, h), 60 + k, _stone_slot, center=(x, y, z0),
                   yaw=math.radians(yaw), base_r=(0.5, 0.5), top=(0.97, 0.4), ntop=4)
    return [m.to_object("Moss_Mound"), s.to_object("Moss_Stone")]


# ---------------------------------------------------------------------------
# gramada de frunze
# ---------------------------------------------------------------------------

def build_leaf_pile():
    """`leaf_pile.png`: gramada joasa (Ø 1,6 x 0,5 m) din placute mici
    romboidale rosu-portocalii, asezate pe suprafata unui con rotunjit, cu
    cateva imprastiate pe margine; inauntru un miez de dom ca sa nu se vada
    prin goluri. Nod unic `Leaf_Pile`; culori: LAVA_ORANGE / LARCH_RUST /
    KERB_RED (dupa decupare; clasa `leaf_litter` le va uniformiza)."""
    b = Builder()
    rnd = _lcg(77)
    R, H = 0.85, 0.42
    _dome(b, (0, 0, -0.02), R * 0.85, R * 0.85, H * 0.75, 3, 8, 0.05, 5,
          lambda n, r: LARCH_RUST)

    def surf(r):
        return H * max(0.0, 1.0 - (r / R) ** 2.0) ** 0.75

    mix = (LAVA_ORANGE, KERB_RED, LAVA_ORANGE, KERB_RED, LARCH_RUST)
    for k in range(190):
        r = R * (0.97 * math.sqrt(rnd()) if k < 165 else 0.95 + 0.1 * rnd())
        a = 2 * math.pi * rnd()
        x, y = r * math.cos(a), r * math.sin(a)
        z = surf(r)
        eps = 0.02
        dzdr = (surf(r + eps) - surf(max(r - eps, 0.0))) / (2 * eps)
        n = Vector((-dzdr * math.cos(a), -dzdr * math.sin(a), 1.0))
        n += Vector(((rnd() - 0.5) * 0.5, (rnd() - 0.5) * 0.5, 0.0))
        n.z += 0.8
        spin = Vector((math.cos(2 * math.pi * rnd()), math.sin(2 * math.pi * rnd()), 0.1))
        _plate(b, (x, y, z + 0.02), n, spin, 0.22 + 0.08 * rnd(), 0.14 + 0.05 * rnd(),
               0.022, mix[int(rnd() * 5) % 5])
    return [b.to_object("Leaf_Pile")]


# ---------------------------------------------------------------------------
# bambusul
# ---------------------------------------------------------------------------

def _culm(cb, base, height, r0, r1, step, lean=(0.0, 0.0), node_h=0.07, node_dr=0.028):
    """Tulpina pe un traseu fara capac de sus: puncte la fiecare nod (~`step`),
    raza se subtiaza de la r0 la r1, nodurile = inele scurte `NODE_RING`. Intoarce
    lista de puncte ale traseului."""
    n = max(2, int(height / step))
    pts, radii = [], []
    for i in range(n + 1):
        t = i / float(n)
        z = height * t
        k = t * t                                # inclinarea creste spre varf
        pts.append(Vector((base[0] + lean[0] * k * height,
                           base[1] + lean[1] * k * height, base[2] + z)))
        radii.append(r0 + (r1 - r0) * t)
    cb.taper_sweep(pts, radii, STALK, segments=6, cap_start=True, cap_end=True)
    for p, r in zip(pts[1:-1], radii[1:-1]):
        cb.cylinder(p, r + node_dr, node_h, NODE_RING, segments=6)
    return pts, radii


def _spray(lb, base, azim_deg, count, length, width, droop=0.3, spread=34.0, slot=None):
    for k in range(count):
        a = azim_deg + (k - (count - 1) / 2.0) * spread
        leaf_vfold(lb, base, a, length * (0.9 + 0.2 * ((k * 37) % 5) / 5.0), width,
                   0.18 * length, slot if slot is not None else LEAF_BAMBOO,
                   fold_deg=22.0, stations=3, thick=0.02, droop=droop)


def _culm_lod(cb, base, height, r0, r1, nodes, lean=(0.0, 0.0), band_dr=0.03,
              cap_start=False, stalk=None):
    """Tulpina ieftina pentru MultiMesh: UN tub de 6 laturi cu doua inele la
    fiecare nod, putin mai late; fetele dintre ele (banda nodului) trec pe
    `NODE_RING`. Fara inele separate. tri = 12 * (2*nodes + 1) + 4. Intoarce
    punctele traseului (ultimul = varful)."""
    zs = [0.0]
    for k in range(1, nodes + 1):
        zc = height * k / (nodes + 0.6)
        zs += [zc - 0.04, zc + 0.04]
    zs.append(height)
    pts, radii = [], []
    for i, z in enumerate(zs):
        t = z / height
        kk = t * t
        pts.append(Vector((base[0] + lean[0] * kk * height,
                           base[1] + lean[1] * kk * height, base[2] + z)))
        r = r0 + (r1 - r0) * t
        radii.append(r + (band_dr if (i % 2 == 1 or (i % 2 == 0 and 0 < i < len(zs) - 1)) else 0.0))
    faces = cb.taper_sweep(pts, radii, STALK if stalk is None else stalk, segments=6,
                           cap_start=cap_start, cap_end=True)
    for f in faces:
        zc = f.calc_center_median().z - base[2]
        for k in range(1, nodes + 1):
            zn = height * k / (nodes + 0.6)
            if abs(zc - zn) < 0.045 and abs(f.normal.z) < 0.5:
                f[cb.slot] = NODE_RING
    return pts


def _fan(lb, base, azim_deg, count, length, width, rise, slot, spread=38.0):
    """Evantai de `count` placi late, ridicate si cazand la varf (3 statii)."""
    for k in range(count):
        a = math.radians(azim_deg + (k - (count - 1) / 2.0) * spread)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        bs = Vector(base)
        path = [bs, bs + d * (length * 0.5) + Vector((0, 0, rise)),
                bs + d * length + Vector((0, 0, rise * 0.4))]
        lb.blade(path, [0.12 * width, width, 0.0], 0.03, slot, up=(0, 0, 1))


def build_moso_culm():
    """`moso_culm.png` (runda 5, pentru MultiMesh cu mii de instante, <= 300 tri):
    tulpina dreapta de 19,2 m, Ø 0,26 -> 0,15, 6 laturi, 10 noduri (la ~1,8 m)
    facute ca benzi usor mai late pe tub, `DRY_VEGETATION` (verde-galbui de la
    distanta), fara inele separate; la varf 3 placi de frunza in trei directii.
    Un nod `Moso_Culm`; originea la baza, XY pe axa."""
    b = Builder()
    pts = _culm_lod(b, (0, 0, 0), 19.2, 0.13, 0.075, 10)
    top = pts[-1]
    for k, az in enumerate((20.0, 140.0, 260.0)):
        a = math.radians(az)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        bs = Vector((0.0, 0.0, 18.9 + 0.25 * k))
        b.blade([bs, bs + d * 1.5 + Vector((0, 0, 0.25))], [0.5, 0.0], 0.02, LEAF_BAMBOO,
                up=(0, 0, 1))
    return [b.to_object("Moso_Culm")]


def build_bamboo_crown():
    """`bamboo_crown.png` (runda 5, <= 2500 tri, MultiMesh): 9 tulpini groase
    (Ø 0,34 -> 0,22) pe o baza ~2,6 x 1,8 m, inalte 6,8-8,8 m, 5 noduri facute
    ca benzi pe tub; frunzele sunt EVANTAIE MARI (3 placi late de ~1,9 m): unul
    in varf si unul pe treimea de sus pe fiecare tulpina, deschise la culoare
    (`CACTUS_GREEN`, cel mai deschis verde din atlas; 3 evantaie de varf pe
    `DRY_VEGETATION`, cel mai aproape de lime in RGB dar prea galben pe toate). Latime totala ~6,4 m pentru ~8,8 m => h/l ~1,4.
    Noduri `Bamboo_Culms`, `Bamboo_Leaves`."""
    cb, lb = Builder(), Builder()
    rnd = _lcg(5)
    spots = [(-1.3, 0.4), (-0.8, -0.55), (-0.3, 0.6), (0.2, -0.3), (0.6, 0.6),
             (1.0, -0.6), (1.3, 0.1), (-1.0, 0.0), (0.2, 0.2)]
    for i, (x, y) in enumerate(spots):
        h = 6.8 + 2.0 * rnd()
        pts = _culm_lod(cb, (x, y, 0), h, 0.17, 0.11, 5,
                        lean=((rnd() - 0.5) * 0.04, (rnd() - 0.5) * 0.04),
                        band_dr=0.035, stalk=TROPICAL_GREEN)
        az0 = math.degrees(math.atan2(y, x)) if (x or y) else 0.0
        lime = DRY_VEGETATION if i % 3 == 0 else CACTUS_GREEN
        _fan(lb, pts[-1], az0 + (rnd() - 0.5) * 60, 3, 1.9, 0.9, 0.45, lime)
        low = pts[int(len(pts) * 0.72)]
        _fan(lb, low, az0 + 180.0 + (rnd() - 0.5) * 60, 3, 1.6, 0.8, 0.35,
             CACTUS_GREEN)
    return [cb.to_object("Bamboo_Culms"), lb.to_object("Bamboo_Leaves")]


# ---------------------------------------------------------------------------
# export
# ---------------------------------------------------------------------------

def _emit(fn, path, ao, budget, keep_xy=False, **kw):
    clear_built()
    objs = fn()
    (emit_keep_xy if keep_xy else emit)(objs, path, ao, budget=budget,
                                        smooth_angle=None, **kw)


_emit(build_shiba_fence, "props/shiba_fence.glb", AO_SMALL, 700)
_emit(build_karikomi_a, "plants/karikomi_shrub_a.glb", AO_SMALL, 200)
_emit(build_karikomi_b, "plants/karikomi_shrub_b.glb", AO_SMALL, 200)
_emit(build_rock_a, "rocks/garden_rock_a.glb", AO_SMALL, 400)
_emit(build_rock_b, "rocks/garden_rock_b.glb", AO_SMALL, 250)
_emit(build_rock_c, "rocks/garden_rock_c.glb", AO_SMALL, 400)
_emit(build_stepping_stones, "rocks/stepping_stones.glb", AO_SMALL, 300)
_emit(build_moss_mound, "rocks/moss_mound.glb", AO_SMALL, 700)
_emit(build_leaf_pile, "props/leaf_pile.glb", AO_SMALL, 2800)
_emit(build_moso_culm, "plants/moso_culm.glb", AO_TALL, 300, keep_xy=True)
_emit(build_bamboo_crown, "plants/bamboo_crown.glb", AO_TALL, 2500)
report()
