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

SAGE = CACTUS_GREEN        # 12 gri-verde
JUNI = TROPICAL_GREEN      # 21
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
    """`sagebrush.png` -- elemente numarate pe decupare, inainte de modelare:

    - 7 smocuri (cel mult 8) gri-verzi, FIECARE un ciorchine ridicat, alungit,
      cu contur festonat (ca o frunza de stejar): se inclina spre exterior din
      centru, cele din fata mai joase, cel din mijloc cel mai inalt;
    - tufa rotunjita, mai lata decat inalta (h/l ~0,7), cu varful neregulat;
    - la baza: tulpini scurte, subtiri, portocalii-uscate (DRY) care se vad intre
      smocuri, plus cateva frunzulite uscate intinse pe sol, in jurul bazei;
    - culoare: gri-verde palid, fara contrast intre smocuri, umbra la baza.
    Cote: 1,0 m inalt, 1,4 m lat."""
    b = Builder()
    tufts = [(0.00, 0, 0.58, 0.80, 4), (0.34, 25, 0.48, 0.76, 16),
             (0.52, 85, 0.40, 0.62, 28), (0.56, 145, 0.34, 0.54, 34),
             (0.56, 205, 0.36, 0.56, 34), (0.52, 265, 0.40, 0.62, 28),
             (0.46, 320, 0.44, 0.70, 22), (0.62, 115, 0.28, 0.42, 44)]
    for k, (r, a, z, h, tilt) in enumerate(tufts):
        c0 = polar(r, a, z)
        # smocul = un ciorchine: tulpina mare + 2 lobi laterali (contur festonat)
        lump(b, c0, (0.34, 0.28, h), SAGE, 10 + k, tilt_deg=tilt, azim_deg=a,
             segments=6, rings=3, deviation=0.22)
        lump(b, c0 + polar(0.17, a + 90, h * 0.10), (0.22, 0.20, h * 0.55), SAGE,
             30 + k, tilt_deg=tilt + 12, azim_deg=a + 90, deviation=0.22)
        lump(b, c0 + polar(0.17, a - 90, h * 0.20), (0.22, 0.20, h * 0.5), SAGE,
             50 + k, tilt_deg=tilt + 12, azim_deg=a - 90, deviation=0.22)
    # tulpini scurte la baza (portocaliu uscat)
    for k in range(9):
        a = k * 40 + 10
        stem(b, [polar(0.04, a, 0.0), polar(0.20, a, 0.20),
                 polar(0.34, a, 0.30)], 0.028, 0.016, DRY, segments=4)
    # frunzulite uscate pe sol
    for k in range(6):
        a = k * 60 + 25
        b.blade([polar(0.28, a, 0.03), polar(0.50, a, 0.05), polar(0.66, a, 0.03)],
                [0.0, 0.07, 0.0], 0.015, DRY)
    return [b.to_object("Sagebrush")]


# ---------------------------------------------------------------------------
def build_juniper():
    """`juniper.png` -- elemente numarate pe decupare, inainte de modelare:

    - TRUNCHI: gros si scurt la baza (evazat), RASUCIT, se desparte la ~1/4 din
      inaltime in 4 brate (3 mari + unul mai subtire), brate ondulate care
      urca si se deschid spre exterior; maro-rosietic (WOOD);
    - CROANE: 8 ciorchini de frunzis (nu glob): cate 4 bulgari mici turtiti
      fiecare, asezati la capetele bratelor si pe crengi laterale, GOLURI de
      cer intre ciorchini prin care se vad crengile; verde oliv saturat;
    - silueta: latime ~ inaltime (h/l ~0,9);
    - ramuri subtiri (4) care duc la ciorchinii mici de pe laturi.
    Cote: 4 m inalt, ~4,5 m lat."""
    t = Builder()
    c = Builder()

    # trunchi rasucit: spirala usoara, raza 0,46 la baza -> 0,22 la furca
    trunk = [Vector((0.10 * math.cos(1.5 * z), 0.10 * math.sin(1.5 * z), z))
             for z in (0.0, 0.3, 0.6, 0.85, 1.1)]
    trunk[0] = Vector((0, 0, -0.05))
    stem(t, trunk, 0.50, 0.26, BARK, segments=8)
    fork = trunk[-1]
    # radacini evazate (3 lobi mici la sol)
    for a in (30, 150, 270):
        stem(t, [polar(0.1, a, 0.15), polar(0.42, a, 0.14), polar(0.62, a, 0.0)],
             0.17, 0.05, BARK, segments=6)

    arms = [  # azimut, raza finala, cota finala, grosime
        (195, 1.60, 2.30, 0.15),
        (330, 1.70, 2.45, 0.15),
        (85, 1.20, 1.85, 0.13),
        (25, 0.55, 3.15, 0.12)]
    ends = []
    for k, (a, r, z, th) in enumerate(arms):
        p0 = fork
        p1 = p0 + polar(0.35 * r, a + 14, 0.35)
        p2 = polar(0.75 * r, a - 10, fork.z + 0.55 * (z - fork.z))
        p3 = polar(r, a, z)
        pts = [p0, p1, p2, (p2 + p3) * 0.5 + Vector((0.05, 0.05, 0)), p3]
        stem(t, pts, 0.24 - 0.02 * k, th * 0.7, BARK, segments=6)
        ends.append((p3, a, 1.0))
        # doua ramuri laterale spre ciorchini mai mici
        mid = pts[2]
        for sgn, up in ((1, 0.55), (-1, 1.00)):
            side_a = a + 60 * sgn
            end2 = mid + polar(0.95, side_a, up)
            stem(t, [mid, mid + polar(0.40, side_a, 0.30 * up), end2], 0.07,
                 0.03, BARK, segments=5)
            ends.append((end2, side_a, 0.62))

    # ciorchini (NU placi): 12, cate 4-5 bulgari rotunjiti, cu goluri intre ei
    for k, (p, a, scl) in enumerate(ends):
        R = 0.78 * scl + 0.1
        for j, (da, dr, dz, sz) in enumerate(
                [(0, 0.0, 0.10, 1.0), (80, 0.55, -0.02, 0.72),
                 (190, 0.55, -0.04, 0.70), (290, 0.50, 0.18, 0.62),
                 (140, 0.30, 0.50, 0.55)]):
            cen = p + polar(dr * R, a + da, dz * R + 0.10)
            lump(c, cen, (R * 1.15 * sz, R * 1.0 * sz, R * 0.85 * sz), JUNI,
                 seed=50 + 7 * k + j, tilt_deg=6, azim_deg=a,
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
    """`rabbitbrush.png` -- elemente numarate pe decupare, inainte de modelare:

    - TULPINI: ~14 tulpini subtiri (DRY) pornite dintr-un punct de la sol, in
      evantai deschis, curbate spre exterior;
    - FLORI: ~18 ciorchini galbeni (CAR_YELLOW), fiecare 2-3 bulgarasi, asezati
      deasupra si pe laturile cupolei, la capetele tulpinilor, desprinsi unii
      de altii (se vad tulpinile intre ei);
    - frunzulite subtiri la baza;
    - silueta: cupola joasa, mai lata decat inalta (h/l ~0,85).
    Cote: 1,2 m inalt, 1,4 m lat."""
    s = Builder()
    f = Builder()
    rnd = _lcg(8)
    n = 16
    for k in range(n):
        a = k * 137.5
        t = k / float(n - 1)              # 0 = exterior, 1 = central
        reach = 0.70 * (1.0 - 0.85 * t) + 0.04
        h = 0.68 + 0.52 * t * (1.0 - 0.3 * t) + (rnd() - 0.5) * 0.06
        p0 = polar(0.02, a, 0.0)
        p1 = polar(reach * 0.35, a, h * 0.38)
        p2 = polar(reach * 0.78, a, h * 0.74)
        p3 = polar(reach, a, h)
        stem(s, [p0, p1, p2, p3], 0.020, 0.012, DRY, segments=4)
        # 3 ciorchini pe fiecare tulpina (varf, 2/3, 1/3), fiecare 3 lobi
        for (pc, scl) in ((p3, 1.0), (p2, 0.85)):
            for q, (da, dr, dz, sz) in enumerate(
                    [(0, 0.0, 0.03, 1.0), (110, 0.09, -0.03, 0.8),
                     (230, 0.09, 0.01, 0.8)]):
                lump(f, pc + polar(dr * scl, a + da, dz),
                     (0.21 * sz * scl, 0.19 * sz * scl, 0.17 * sz * scl),
                     BLOOM, seed=100 + k * 11 + q + int(scl * 7), segments=5,
                     rings=3, deviation=0.25)
    # frunze subtiri la baza
    for k in range(6):
        a = k * 60 + 15
        s.blade([polar(0.1, a, 0.03), polar(0.35, a, 0.12), polar(0.58, a, 0.05)],
                [0.0, 0.06, 0.0], 0.010, DRY)
    return [s.to_object("Rabbitbrush"), f.to_object("Rabbitbrush_Bloom")]


# ---------------------------------------------------------------------------
def build_tumbleweed():
    """`tumbleweed.png` -- elemente numarate pe decupare, inainte de modelare:

    - RETEA DESCHISA de crengute subtiri, aproape sferica; goluri mari prin
      care se vede fundalul (NU bila plina);
    - ~18 bucle subtiri care se intretaie, fiecare un arc de cerc cu raza usor
      diferita si inclinare diferita;
    - capete libere de crengute care ies din contur (silueta zimtata);
    - un singur ton: brun-auriu uscat (DRY), crengute de ~1-1,5 cm.
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
        stem(b, pts, 0.011, 0.005, DRY, segments=4)
    # cateva crengute drepte care ies din bila
    for k in range(7):
        u = rnd() * 2 - 1
        ph = rnd() * 2 * math.pi
        sq = math.sqrt(1 - u * u)
        d = Vector((sq * math.cos(ph), sq * math.sin(ph), u))
        jit = Vector(((rnd() - 0.5) * 0.06,) * 3)
        c0 = Vector((0, 0, cz))
        stem(b, [d * (R * 0.6) + c0, d * R + c0, d * (R * 1.12) + jit + c0],
             0.009, 0.004, DRY, segments=4)
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
