"""Transfagarasan -- animalele statice (brief docs/asset_briefs/transfagarasan_kit.md §1.6).

  transfagarasan/animals/sheepdog.glb   ciobanesc romanesc (mioritic / carpatin)

Ursul (`brown_bear`, animat) e in build_tf_bear.py (val 1, tf-c). Oaia NU se
genereaza: `monumentvalley/animals/sheep.glb` (kit §1.9).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_tf_animals.py

CONTRACTUL TURMEI (scenes/hazards/herd_hazard.gd): cainele intra in `HerdHazard`
ca `alt_model`, langa oaie. Turma ia PRIMUL MeshInstance3D gasit (DFS din
`_animal_mesh_from`) si il pune intr-un MultiMesh, deci:
  * UN SINGUR nod cu mesh (`Sheepdog`), cu toate sloturile in el -- aici
    contractul turmei bate regula „un nod = un slot” (atlasul e oricum un
    singur material);
  * originea la sol, -Z inainte in Godot = +Y in Blender;
  * picioarele sub ~0,45 m: shader-ul de galop leagana varfurile cu
    y < leg_top (implicit 0,55, reglat la integrare) in antifaza dupa semnul
    lui z (Godot), deci originea sta INTRE perechea din fata si cea din spate
    (labele la y = +0,43 si -0,45), iar burta (si franjurii ei) raman peste 0,45 m.
Static, fara schelet. Fara oglindire prin scala (memoria
multimesh-oglindire-culling): partea -X e construita, nu scalata cu -1.
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "transfagarasan_shapes.py"), encoding="utf-8").read())
exec(open(os.path.join(_here, "tf_shapes_nature.py"), encoding="utf-8").read())   # clump

ONLY = os.environ.get("TF_ONLY", "")
hull = _hull

FUR = CORAL_SAND        # 19, blana alb-crem (kit §0, sloturi pe roluri)
DARK_PATCH = ASPHALT_EDGE   # 6, petele, masca, urechile (rev. 2; rev. 1 era MARBLE_GREY)
NOSE = VOLCANIC_BLACK   # 20, nasul, ochii

AO_DOG = dict(samples=20, dist=0.35, gradient="vertical", low=0.70, high=1.0,
              power=0.8, floor=0.50, z_range=(0.0, 1.32))


def _lump(b, c, size, slot, seed, seg=8, rings=5, dev=0.10, rot=None):
    """Bulgare de blana: elipsoid inchis, perturbat (Builder.boulder), rotit."""
    faces = b.boulder(tuple(c), tuple(size), slot, seed=seed, segments=seg, rings=rings,
                      deviation=dev)
    if rot is not None:
        cv = Vector(c)
        vs = set()
        for f in faces:
            vs.update(f.verts)
        for v in vs:
            v.co = cv + rot @ (v.co - cv)
    return faces


def _rx(deg):
    return Matrix.Rotation(math.radians(deg), 3, "X")


def _leg(b, top, knee, foot, r_top, r_knee, r_foot, slot):
    """Picior: tub conic in doua segmente (sold/umar -> genunchi/jaret -> laba)."""
    b.taper_sweep([top, knee, foot], [r_top, r_knee, r_foot], slot, segments=6)


def build_sheepdog():
    """Ciobanescul (`sheepdog`): ciobanesc romanesc mioritic / carpatin, static.
    REV. 2, pe contractul revizuit de coordonator (kit §1.6): rev. 1 citea
    „oaie palida” / „capra pe picioroange” din camera de joc.

    LISTA DE ELEMENTE (din decuparea `transfagarasan_assets_v1/sheepdog.png`
    si din contractul revizuit; scrisa INAINTE de geometrie):
      1) TRUNCHI masiv si adanc: 1,15 m umar -> crupa, spinarea la ~1,02 m,
         burta la 0,46-0,47 m (pieptul adanc 0,55 din greaban); burta ramane
         PESTE leg_top = 0,45
      2) COAMA latoasa pe gat si piept: 1 masa pe gat, 1 jabou, 2 smocuri pe
         laturile pieptului -> fata mai LATA decat crupa (decuparea: idem)
      3) PATA inchisa pe umar/spate, coborand pe flanc (decuparea: una mare,
         gri-inchis) + o dunga mica inchisa la radacina cozii (decuparea: da)
         -> bulgari intregi pe ASPHALT_EDGE 6, margini pe fatete
      4) CAP MARE (~0,40 m lat), inchis (ASPHALT_EDGE), cu dunga alba pe frunte,
         bot SCURT si LAT alb, nas negru, 2 ochi negri (decuparea: idem)
      5) 2 urechi ATARNATE, inchise (decuparea: idem)
      6) 4 picioare SCURTE si GROASE (>= 0,18 m sus), labe late (decuparea: 4,
         drepte in fata, jaret in spate)
      7) „PANTALONI” de blana pe coapsele din spate: conturul se largeste la
         coapsa (decuparea: da) + franjuri dupa picioarele din fata
      8) COADA: smoc mare stufos, curbat in sus, ca masa aproape cat capul
         (decuparea: panas mare, curbat)
      9) contur LATOS: `clump` (tf_shapes_nature) pe piept, gat, pantaloni,
         coada, spinare; fara cutii cu muchii drepte
     10) NU: zgarda, pete pe picioare

    Cote: greaban ~1,0 m, trunchi 1,15 m. Un singur nod `Sheepdog` (FUR
    CORAL_SAND 19, DARK ASPHALT_EDGE 6, NOSE VOLCANIC_BLACK 20).
    """
    b = Builder()
    DARK = ASPHALT_EDGE

    def tuft(c, size, slot, seed, yaw=0.0, tilt=0.25, dev=0.20, seg=6, rings=3):
        return clump(b, c, size, slot, seed=seed, seg=seg, rings=rings, dev=dev, yaw=yaw,
                     tilt=tilt)

    # --- 1) trunchiul: loft continuu (inele de 12), umar +0,56 -> crupa -0,59
    #        y      wx    zb    zt
    prof = [(-0.66, 0.16, 0.66, 0.92), (-0.59, 0.25, 0.53, 1.00), (-0.40, 0.29, 0.48, 1.02),
            (-0.15, 0.30, 0.47, 1.01), (0.10, 0.31, 0.465, 1.01), (0.34, 0.32, 0.465, 1.03),
            (0.52, 0.29, 0.50, 1.05), (0.62, 0.18, 0.60, 1.03)]
    rings = []
    for i, (y, wx, zb, zt) in enumerate(prof):
        zc, hz = (zb + zt) * 0.5, (zt - zb) * 0.5
        ring = []
        for k in range(12):
            a = 2.0 * math.pi * k / 12.0
            j = 1.0 + 0.05 * _wob(i * 1.7, k * 2.3, 3.0)
            ring.append((wx * math.cos(a) * j, y + 0.03 * _wob(k, i, 7.0),
                         zc + hz * math.sin(a) * min(j, 1.0)))
        rings.append(ring)
    ring_stack(b, rings, FUR)
    # spinarea latoasa: smocuri pe linia de sus si pe flancuri
    for k, y in enumerate((-0.48, -0.28, 0.32)):
        tuft((0.0, y, 0.98), (0.40, 0.24, 0.16), FUR, 100 + k)
    # franjurii burtii (jos pe flanc, talpa la ~0,46 m: peste leg_top)
    for sx in (-1.0, 1.0):
        for k, y in enumerate((-0.30, -0.02, 0.26)):
            tuft((sx * 0.17, y, 0.53), (0.22, 0.30, 0.13), FUR, 110 + k + int(sx) * 5, tilt=0.1)
    # --- 2) coama: gat, jabou, laturile pieptului (fata mai lata decat crupa)
    tuft((0.0, 0.56, 1.02), (0.56, 0.40, 0.50), FUR, 21, tilt=0.15)
    tuft((0.0, 0.66, 0.74), (0.40, 0.26, 0.46), FUR, 22, tilt=0.15)
    for sx in (-1.0, 1.0):
        tuft((sx * 0.22, 0.54, 0.80), (0.26, 0.30, 0.44), FUR, 23 + int(sx))
    # --- 3) pata inchisa pe umar/spate (bulgari intregi) + dunga la coada
    tuft((0.0, 0.10, 0.975), (0.52, 0.48, 0.12), DARK, 31, tilt=0.05, dev=0.12)
    for sx in (-1.0, 1.0):
        tuft((sx * 0.27, 0.12, 0.86), (0.09, 0.42, 0.30), DARK, 32 + int(sx), tilt=0.05, dev=0.12)
    tuft((0.0, -0.58, 0.98), (0.22, 0.12, 0.10), DARK, 35, tilt=0.1)
    # --- 4) capul mare, inchis; dunga alba; botul scurt si lat; nas, ochi
    _lump(b, (0.0, 0.76, 1.15), (0.40, 0.34, 0.34), DARK, 51, seg=8, rings=5, dev=0.07)
    tuft((0.0, 0.895, 1.17), (0.08, 0.06, 0.16), FUR, 52, tilt=0.0, dev=0.08)
    _lump(b, (0.0, 0.93, 1.06), (0.25, 0.20, 0.18), FUR, 53, seg=8, rings=4, dev=0.06)
    _lump(b, (0.0, 1.03, 1.10), (0.08, 0.05, 0.06), NOSE, 54, seg=6, rings=3, dev=0.04)
    for sx in (-1.0, 1.0):
        _lump(b, (sx * 0.10, 0.905, 1.20), (0.035, 0.025, 0.035), NOSE, 55 + int(sx), seg=6,
              rings=3, dev=0.02)
        # --- 5) urechile atarnate
        tuft((sx * 0.215, 0.74, 1.10), (0.07, 0.16, 0.26), DARK, 57 + int(sx), tilt=0.1, dev=0.10)
    # --- 6) picioarele scurte si groase, labele late
    for sx in (-1.0, 1.0):
        _leg(b, (sx * 0.16, 0.40, 0.62), (sx * 0.16, 0.41, 0.28), (sx * 0.16, 0.40, 0.07),
             0.115, 0.095, 0.09, FUR)
        _leg(b, (sx * 0.17, -0.42, 0.62), (sx * 0.17, -0.53, 0.25), (sx * 0.17, -0.47, 0.07),
             0.125, 0.09, 0.09, FUR)
        for y in (0.43, -0.45):
            _lump(b, (sx * 0.16, y, 0.055), (0.19, 0.23, 0.11), FUR, 61 + int(y * 10) + int(sx),
                  seg=7, rings=3, dev=0.05)
        # --- 7) pantalonii (coapsa) si franjurii dupa picioarele din fata
        tuft((sx * 0.19, -0.48, 0.55), (0.24, 0.34, 0.40), FUR, 71 + int(sx), tilt=0.15)
        tuft((sx * 0.18, -0.56, 0.38), (0.18, 0.22, 0.24), FUR, 73 + int(sx), tilt=0.2)
        tuft((sx * 0.16, 0.33, 0.42), (0.14, 0.14, 0.26), FUR, 75 + int(sx), tilt=0.2)
    # --- 8) coada: smoc mare, curbat in sus
    # panas pe arc: iese inapoi din crupa, apoi se curbeaza in sus; bulgari
    # mari, suprapusi >= 40 % (masa continua, nu coloana)
    for k, (c, sz) in enumerate((((0.0, -0.68, 0.93), (0.28, 0.26, 0.26)),
                                 ((0.0, -0.82, 0.96), (0.34, 0.30, 0.32)),
                                 ((0.0, -0.93, 1.04), (0.34, 0.28, 0.32)),
                                 ((0.0, -0.96, 1.16), (0.28, 0.24, 0.26)),
                                 ((0.0, -0.90, 1.24), (0.20, 0.20, 0.16)))):
        tuft(c, sz, FUR, 81 + k, dev=0.22)
    return [b.to_object("Sheepdog")]


clear_built()
if not ONLY or ONLY == "sheepdog":
    emit_tf(build_sheepdog(), "animals/sheepdog.glb", AO_DOG, keep_xy=True, bevel=0.0,
            smooth_angle=32.0)
    clear_built()
report_tf()
