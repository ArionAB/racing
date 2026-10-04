"""Monument Valley -- plantele (brief docs/asset_briefs/monumentvalley_kit.md §1.3).

  monumentvalley/plants/sagebrush.glb     salvie 1,0 x 1,4 m   (Sagebrush)
  monumentvalley/plants/juniper.glb       ienupar 4 m          (Juniper_Trunk, Juniper_Crown)
  monumentvalley/plants/yucca.glb         yucca 1,2 m          (Yucca)
  monumentvalley/plants/rabbitbrush.glb   tufa cu flori 1,2 m  (Rabbitbrush, Rabbitbrush_Bloom)
  monumentvalley/plants/tumbleweed.glb    bila de crengute, diametru 0,9 m (Tumbleweed)

Plantele mici se vor pune pe MultiMesh: un mesh compact, cat mai putine noduri
(un nod per material cand materialul cere nod: floarea rabbitbrush, trunchiul
ienuparului). Toate primitivele rotunde au segmente setate (CLAUDE.md).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_monument_plants.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "monument_shapes.py")).read())

SAGE = CACTUS_GREEN        # 12 oliv (varfuri / smocuri interioare)
PALE = MARBLE_GREY         # 29 gri-verde palid (corpul smocurilor)
COPPER = LARCH_RUST        # 27 arama (tumbleweed)
JUNI = CACTUS_GREEN        # 12 oliv (decis pe randarea masurata)
BARK = WOOD                # 9
DRY = DRY_VEGETATION       # 13
BLOOM = CAR_YELLOW         # 16 (--allow-car-slots=Rabbitbrush_Bloom)

AO_PLANT = dict(samples=16, dist=0.6, gradient="vertical",
                low=0.55, high=1.0, power=0.9, floor=0.30)
AO_TREE = dict(samples=16, dist=2.5, gradient="vertical",
               low=0.50, high=1.0, power=0.85, floor=0.25)

clear_built()


def lump(b, center, size, slot, seed, tilt_deg=0.0, azim_deg=0.0,
         segments=6, rings=3, deviation=0.18):
    """Bulgare (boulder inchis) turtit/alungit, apoi INCLINAT cu `tilt_deg` spre
    azimutul `azim_deg` (varful se apleaca spre exterior)."""
    faces = b.boulder((0, 0, 0), size, slot, seed=seed, segments=segments,
                      rings=rings, deviation=deviation)
    verts = {v for f in faces for v in f.verts}
    a = math.radians(azim_deg)
    # axa de rotatie orizontala, perpendiculara pe directia de inclinare
    axis = Vector((-math.sin(a), math.cos(a), 0.0))
    rot = Matrix.Rotation(math.radians(tilt_deg), 3, axis)
    for v in verts:
        v.co = rot @ v.co + Vector(center)
    return faces


def stem(b, pts, r0, r1, slot, segments=4):
    n = len(pts)
    radii = [r0 + (r1 - r0) * i / (n - 1) for i in range(n)]
    b.taper_sweep(pts, radii, slot, segments=segments, cap_start=False,
                  cap_end=True)


def polar(r, az_deg, z):
    a = math.radians(az_deg)
    return Vector((r * math.cos(a), r * math.sin(a), z))


# ---------------------------------------------------------------------------
def build_sagebrush():
    """`sagebrush.png` -- elemente numarate pe decupare (revizia 3, dupa verdictul
    coordonatorului: identitatea e GRI-VERDE PALID si textura fina):

    - 15 smocuri mici, verticale, usor in forma de flacara (alungite, ingustate
      spre varf), pe TULPINI LEMNOASE scurte care se ramifica (WOOD, 5 tulpini
      de la baza, cate 3 smocuri pe tulpina), nu 5 bulgari rotunzi;
    - culoare: gri-verde palid (MARBLE_GREY 29) pe cea mai mare parte a
      smocurilor; CACTUS_GREEN 12 doar pe varfuri (calota mica a fiecarui smoc)
      si pe smocurile din interior;
    - domul tufei 1,0 x 1,4 m, cu GOLURI intre smocuri prin care se vad tulpinile;
    - la baza: cateva frunzulite uscate pe sol.
    Cote: 1,0 m inalt, 1,4 m lat."""
    b = Builder()
    for i in range(5):
        a = i * 72 + 15
        base = polar(0.04, a, 0.0)
        fork = polar(0.14, a, 0.30)
        stem(b, [base, polar(0.08, a, 0.15), fork], 0.032, 0.022, BARK, segments=5)
        for j, da in enumerate((-38, 0, 38)):
            aa = a + da
            outer = 0.50 if j != 1 else 0.30
            top_z = 0.64 if j != 1 else 0.88
            top_z -= 0.14 * (i % 2)
            end = polar(outer + 0.06 * (i % 3), aa, top_z)
            stem(b, [fork, (fork + end) * 0.5 + Vector((0, 0, 0.03)),
                     end - Vector((0, 0, 0.22))], 0.020, 0.012, BARK, segments=4)
            inner = ((i + j) % 2 == 0)
            body = SAGE if inner else PALE
            h = 0.46 if j != 1 else 0.52
            tilt = 20 if j != 1 else 6
            c0 = end - Vector((0, 0, 0.02))
            lump(b, c0, (0.23, 0.18, h * 0.92), body, 10 + 4 * i + j, tilt_deg=tilt,
                 azim_deg=aa, segments=6, rings=3, deviation=0.20)
            if True:   # varful: calota mica pe culoarea opusa
                lump(b, c0 + Vector((0, 0, h * 0.30)), (0.13, 0.11, 0.20), PALE if inner else SAGE,
                     60 + 4 * i + j, tilt_deg=tilt, azim_deg=aa, segments=5,
                     rings=2, deviation=0.18)
    for k in range(6):
        a = k * 60 + 25
        b.blade([polar(0.28, a, 0.03), polar(0.50, a, 0.05), polar(0.66, a, 0.03)],
                [0.0, 0.07, 0.0], 0.015, DRY)
    return [b.to_object("Sagebrush")]


# ---------------------------------------------------------------------------
def build_juniper():
    """`juniper.png` -- elemente numarate pe decupare (revizia 3):

    - TRUNCHI: NOROS, 3 tulpini rasucite care pornesc din pamant impreuna (baza
      comuna ingusta), se desfac jos si se ramifica la 0,9-1,4 m; maro-rosietic
      (WOOD), cu 2 ramuri joase aproape orizontale spre laturi;
    - CROANE: 8 ciorchini TURTITI la inaltimi diferite (2 joase pe laturi, 3 la
      mijloc, 3 sus), fiecare 5 bulgari, goluri de cer intre ei; oliv
      (CACTUS_GREEN 12, fetele de jos inchise de AO);
    - silueta: latime ~ inaltime (h/l ~0,9), varfuri neregulate.
    Cote: 4 m inalt, ~4,5 m lat."""
    t = Builder()
    c = Builder()
    ends = []     # (punct, azimut, scara ciorchinelui)

    def twisted(a, lean, top_z, r0, r1, phase):
        pts = []
        n = 6
        for i in range(n):
            u = i / (n - 1.0)
            ang = a + 55 * u * math.sin(phase + u)           # rasucire
            rad = 0.22 + lean * u * u
            pts.append(polar(rad, ang, top_z * u))
        stem(t, pts, r0, r1, BARK, segments=7)
        return pts

    stems = [(15, 0.55, 1.40, 0.0), (135, 0.60, 1.15, 2.1), (255, 0.50, 1.50, 4.0)]
    for k, (a, lean, tz, ph) in enumerate(stems):
        pts = twisted(a, lean, tz, 0.20, 0.12, ph)
        top = pts[-1]
        for sgn, (dr, dz, scl) in zip((1, -1), ((0.95, 1.25 + 0.4 * k, 1.0),
                                                (0.7, 1.0 + 0.5 * k, 0.9))):
            aa = a + 50 * sgn
            end = top + polar(dr, aa, dz)
            stem(t, [top, top + polar(0.5 * dr, aa + 15 * sgn, 0.4 * dz), end],
                 0.11, 0.045, BARK, segments=5)
            ends.append((end, aa, scl))
    # doua ramuri joase, aproape orizontale, spre laturi
    for a, dr, z0 in ((190, 1.30, 0.55), (335, 1.40, 0.70)):
        p0 = polar(0.35, a, z0)
        end = polar(dr + 0.35, a, z0 + 0.55)
        stem(t, [p0, polar(0.9, a + 10, z0 + 0.15), end], 0.12, 0.05, BARK,
             segments=5)
        ends.append((end, a, 0.85))

    for k, (p, a, scl) in enumerate(ends):
        R = 0.74 * scl + 0.1
        for j, (da, dr, dz, sz) in enumerate(
                [(0, 0.0, 0.10, 1.0), (80, 0.55, -0.02, 0.72),
                 (190, 0.55, -0.04, 0.70), (290, 0.50, 0.16, 0.62),
                 (140, 0.30, 0.42, 0.55)]):
            cen = p + polar(dr * R, a + da, dz * R + 0.10)
            lump(c, cen, (R * 1.30 * sz, R * 1.15 * sz, R * 0.85 * sz), JUNI,
                 seed=50 + 7 * k + j, tilt_deg=5, azim_deg=a,
                 segments=7, rings=3, deviation=0.30)
    return [t.to_object("Juniper_Trunk"), c.to_object("Juniper_Crown")]


# ---------------------------------------------------------------------------
def build_yucca():
    """`yucca.png` -- elemente numarate pe decupare, inainte de modelare:

    - ROZETA: ~30 de frunze lanceolate, rigide, in evantai: cele din mijloc
      aproape verticale si lungi (spini), cele de jos ies lateral si cad usor;
    - frunzele sunt verde-olive cu varfuri galbene-uscate la cele de jos;
    - CIOT scurt si gros la baza, ascuns de frunze, cateva frunze moarte
      portocalii intinse pe sol;
    - silueta: tufa conica, inalta ~ cat latimea (h/l ~1,1).
    Cote: 1,2 m inalt, ~1,1 m lat."""
    b = Builder()
    stump_top = 0.22
    stem(b, [Vector((0, 0, 0)), Vector((0, 0, 0.12)), Vector((0, 0, stump_top))],
         0.11, 0.08, DRY, segments=6)
    rnd = _lcg(5)
    n = 34
    for k in range(n):
        t = k / float(n - 1)              # 0 = exterior/jos, 1 = centru/sus
        a = k * 137.5
        tilt = math.radians(80 - 72 * t)
        L = 0.58 + 0.38 * t + (rnd() - 0.5) * 0.06
        w = 0.10 + 0.03 * (1 - t)
        d = Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0))
        pos = Vector((0.0, 0.0, stump_top + 0.02))
        path = [pos.copy()]
        for i in range(1, 5):
            u = i / 4.0
            ang = tilt + 0.9 * (1 - t) * u      # frunzele de jos se curbeaza in jos
            seg = L / 4.0
            pos = pos + d * (seg * math.sin(ang)) + Vector((0, 0, seg * math.cos(ang)))
            path.append(pos.copy())
        widths = [w * 0.5, w * 0.95, w, w * 0.65, 0.0]
        if t < 0.25:    # frunzele de jos: ultima treime galben-uscat
            b.blade(path[:4], widths[:4], 0.012, SAGE, up=(0, 0, 1))
            b.blade(path[3:], widths[3:], 0.012, DRY, up=(0, 0, 1))
        else:
            b.blade(path, widths, 0.012, SAGE, up=(0, 0, 1))
    # frunze moarte pe sol
    for k in range(5):
        a = k * 72 + 20
        b.blade([polar(0.12, a, 0.04), polar(0.45, a, 0.06), polar(0.72, a, 0.02)],
                [0.04, 0.07, 0.0], 0.012, DRY)
    return [b.to_object("Yucca")]


# ---------------------------------------------------------------------------
def build_rabbitbrush():
    """`rabbitbrush.png` -- elemente numarate pe decupare (revizia 3: o PERNA,
    nu un buchet):

    - CUPOLA DENSA de ~48 ciorchini galbeni (CAR_YELLOW), fiecare 2 bulgarasi,
      impachetati strans pe suprafata cupolei, pe treimile de sus si de mijloc;
    - INEL de frunzis verde-oliv (CACTUS_GREEN 12) vizibil dedesubt: ~18
      frunzulite alungite, inclinate spre exterior, in jurul bazei cupolei;
    - tulpinile (DRY) aproape ascunse: cateva scurte, sub cupola;
    - silueta: perna joasa, mai lata decat inalta (h/l ~0,85).
    Cote: 1,2 m inalt, 1,4 m lat."""
    s = Builder()
    f = Builder()
    N = 48
    for i in range(N):
        tt = (i + 0.5) / N
        cth = 1.0 - 0.78 * tt            # de la varf (cos=1) spre cos=0,22
        sth = math.sqrt(1.0 - cth * cth)
        a = i * 137.5
        pos = Vector((0.64 * sth * math.cos(math.radians(a)),
                      0.64 * sth * math.sin(math.radians(a)), 0.36 + 0.74 * cth))
        for q, (da, dr, dz, sz) in enumerate([(0, 0.0, 0.0, 1.0),
                                              (140, 0.10, -0.05, 0.75)]):
            lump(f, pos + polar(dr, a + da, dz), (0.26 * sz, 0.24 * sz, 0.21 * sz),
                 BLOOM, seed=100 + i * 3 + q, segments=5, rings=2, deviation=0.25)
    for k in range(8):
        a = k * 45 + 10
        stem(s, [polar(0.02, a, 0.0), polar(0.20, a, 0.22), polar(0.34, a, 0.42)],
             0.024, 0.016, DRY, segments=4)
    for k in range(18):
        a = k * 20 + 6
        r = 0.46 + 0.10 * (k % 3)
        lump(s, polar(r, a, 0.20 + 0.04 * (k % 2)), (0.10, 0.07, 0.36), SAGE,
             200 + k, tilt_deg=48 + 8 * (k % 2), azim_deg=a, segments=5, rings=2,
             deviation=0.2)
    return [s.to_object("Rabbitbrush"), f.to_object("Rabbitbrush_Bloom")]


# ---------------------------------------------------------------------------
def build_tumbleweed():
    """`tumbleweed.png` -- elemente numarate pe decupare, inainte de modelare:

    - RETEA DESCHISA de crengute subtiri, aproape sferica; goluri mari prin
      care se vede fundalul (NU bila plina);
    - ~18 bucle subtiri care se intretaie, fiecare un arc de cerc cu raza usor
      diferita si inclinare diferita;
    - capete libere de crengute care ies din contur (silueta zimtata);
    - un singur ton: arama (LARCH_RUST 27), crengute de ~1-1,5 cm.
    Cote: diametru 0,9 m, aproximativ sferic (h/l ~0,9)."""
    b = Builder()
    rnd = _lcg(21)
    R = 0.40
    cz = 0.46
    for k in range(20):
        u = rnd() * 2 - 1
        ph = rnd() * 2 * math.pi
        sq = math.sqrt(1 - u * u)
        nrm = Vector((sq * math.cos(ph), sq * math.sin(ph), u))
        ref = Vector((0, 0, 1)) if abs(nrm.z) < 0.9 else Vector((1, 0, 0))
        e1 = nrm.cross(ref).normalized()
        e2 = nrm.cross(e1).normalized()
        r0 = R * (0.72 + 0.28 * rnd())
        off = Vector(((rnd() - 0.5) * 0.12, (rnd() - 0.5) * 0.12, (rnd() - 0.5) * 0.12))
        a0 = rnd() * 2 * math.pi
        span = math.radians(230 + 110 * rnd())
        npts = 17
        pts = []
        for i in range(npts):
            a = a0 + span * i / (npts - 1)
            wob = 1.0 + 0.16 * math.sin(3.1 * a + k) + (0.22 if i == npts - 1 else 0.0)
            p = (e1 * math.cos(a) + e2 * math.sin(a)) * (r0 * wob) \
                + nrm * (0.05 * math.sin(2.3 * a + k * 1.7)) + off
            pts.append(Vector((p.x, p.y, p.z + cz)))
        stem(b, pts, 0.011, 0.005, COPPER, segments=4)
    # cateva crengute drepte care ies din bila
    for k in range(7):
        u = rnd() * 2 - 1
        ph = rnd() * 2 * math.pi
        sq = math.sqrt(1 - u * u)
        d = Vector((sq * math.cos(ph), sq * math.sin(ph), u))
        jit = Vector(((rnd() - 0.5) * 0.06,) * 3)
        c0 = Vector((0, 0, cz))
        stem(b, [d * (R * 0.6) + c0, d * R + c0, d * (R * 1.12) + jit + c0],
             0.009, 0.004, COPPER, segments=4)
    return [b.to_object("Tumbleweed")]


if __name__ == "__main__" or True:
    emit(build_sagebrush(), "plants/sagebrush.glb", AO_PLANT,
         keep_xy=True, smooth_angle=55.0, budget=4000)
    emit(build_juniper(), "plants/juniper.glb", AO_TREE,
         keep_xy=True, smooth_angle=55.0, budget=6000)
    emit(build_yucca(), "plants/yucca.glb", AO_PLANT,
         keep_xy=True, smooth_angle=None, budget=3000)
    emit(build_rabbitbrush(), "plants/rabbitbrush.glb", AO_PLANT,
         keep_xy=True, smooth_angle=55.0, budget=4000)
    emit(build_tumbleweed(), "plants/tumbleweed.glb", AO_PLANT,
         keep_xy=True, smooth_angle=55.0, budget=3000)
    report()
