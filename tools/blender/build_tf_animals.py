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
    (labele la y = +-0,27), iar burta (si franjurii ei) raman peste 0,50 m.
Static, fara schelet. Fara oglindire prin scala (memoria
multimesh-oglindire-culling): partea -X e construita, nu scalata cu -1.
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "transfagarasan_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("TF_ONLY", "")
hull = _hull

FUR = CORAL_SAND        # 19, blana alb-crem (kit §0, sloturi pe roluri)
PATCH = MARBLE_GREY     # 29, petele gri
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

    LISTA DE ELEMENTE (din decuparea `transfagarasan_assets_v1/sheepdog.png`,
    scrisa INAINTE de geometrie):
      1) trunchi masiv, adanc in piept, spatele drept, alb-crem, cu fatete mari
         (decuparea: low-poly fatetat) -> o singura masa continua (loft)
      2) blana LUNGA si latoasa: decuparea arata smocuri pe contur -> 1 coama
         la gat, 1 jabou pe piept, smocuri pe conturul burtii (jitter pe
         inelele de jos, peste 0,46 m), 2 „pantaloni” pe coapsele din spate
      3) PATA GRI mare pe spate (saua), de la umar la crupa, coborand pe flanc
         pana la jumatate (decuparea: una, pe partea vizibila, gri-inchis)
      4) capul: craniu lat, bot scurt alb, nasul negru (decuparea: idem)
      5) urechi CAZUTE, triunghiulare, gri (decuparea: 2, gri-inchis)
      6) masca gri in jurul ochilor, cu dunga alba pe mijlocul fruntii
         (decuparea: gri pe cap, alb pe bot si pe dunga) + 2 ochi negri
      7) 4 picioare drepte, groase, cu labe mari albe (decuparea: 4, din fata
         drepte, din spate cu jaret)
      8) coada STUFOASA: decuparea arata un panas mare, atarnand si curbat in
         sus la capat -> 4 bulgari descrescatori pe arc
      9) NU: zgarda, pete pe picioare (decuparea nu are)

    Cote: 1,0 m la greaban, 1,3 m lung = TRUNCHIUL (varful umarului -> varful
    crupei, masura chinologica), ~1,9 m de la nas la coada; vezi inventarul. Un singur nod
    `Sheepdog` (FUR CORAL_SAND 19, PATCH MARBLE_GREY 29, NOSE VOLCANIC_BLACK 20).
    """
    b = Builder()
    # --- 1) trunchiul: UN loft continuu din inele de 12 puncte (nu bulgari
    # insirati: runda 2 citea „omida”), umar -> crupa = 1,30 m, burta >= 0,47 m.
    # Blana latoasa = jitter determinist pe raza, mai mare pe jumatatea de jos
    # (smocuri pe conturul burtii, ca pe decupare)
    #        y      wx    zb    zt
    prof = [(-0.74, 0.15, 0.68, 0.90), (-0.66, 0.23, 0.55, 0.99), (-0.44, 0.26, 0.50, 1.00),
            (-0.20, 0.27, 0.49, 0.985), (0.06, 0.27, 0.48, 0.99), (0.30, 0.28, 0.47, 1.01),
            (0.50, 0.27, 0.46, 1.03), (0.64, 0.21, 0.52, 1.04), (0.72, 0.13, 0.62, 1.00)]
    rings = []
    for i, (y, wx, zb, zt) in enumerate(prof):
        zc, hz = (zb + zt) * 0.5, (zt - zb) * 0.5
        ring = []
        for k in range(12):
            a = 2.0 * math.pi * k / 12.0
            ca, sa = math.cos(a), math.sin(a)
            j = 1.0 + 0.05 * _wob(i * 1.7, k * 2.3, 3.0)
            if sa < -0.2:
                j += 0.07 * (0.5 + 0.5 * math.sin(k * 2.1 + i * 1.3))
            ring.append((wx * ca * j, y + 0.03 * _wob(k, i, 7.0), zc + hz * sa * j))
        rings.append(ring)
    ring_stack(b, rings, FUR)
    # --- 2) blana lunga: coama, jabou, franjuri, pantaloni
    _lump(b, (0.0, 0.60, 0.98), (0.46, 0.36, 0.48), FUR, 21, rot=_rx(-30))   # coama la gat
    _lump(b, (0.0, 0.62, 0.70), (0.38, 0.22, 0.40), FUR, 22, dev=0.14)        # jaboul
    for sx in (-1.0, 1.0):
        _lump(b, (sx * 0.16, -0.50, 0.60), (0.18, 0.26, 0.32), FUR, 41 + int(sx), seg=7,
              rings=4, dev=0.14, rot=_rx(12))                             # pantalonii
    # --- 4) capul: craniul, botul, nasul
    _lump(b, (0.0, 0.78, 1.20), (0.32, 0.30, 0.29), FUR, 51, seg=8, rings=5, dev=0.06)
    _lump(b, (0.0, 0.92, 1.12), (0.18, 0.19, 0.15), FUR, 52, seg=7, rings=4, dev=0.05)
    b.box((0.0, 1.015, 1.14), (0.07, 0.04, 0.055), NOSE)
    # --- 5) urechile cazute (gri), lipite de craniu pe laterale
    for sx in (-1.0, 1.0):
        hull(b, [Vector((sx * 0.13, 0.72, 1.30)), Vector((sx * 0.13, 0.84, 1.30)),
                 Vector((sx * 0.185, 0.75, 1.10)), Vector((sx * 0.185, 0.81, 1.11)),
                 Vector((sx * 0.165, 0.78, 1.29)), Vector((sx * 0.20, 0.78, 1.08))], PATCH)
    # --- 6) ochii (pe masca gri)
    for sx in (-1.0, 1.0):
        b.box((sx * 0.08, 0.905, 1.235), (0.025, 0.02, 0.025), NOSE)
    # --- 7) picioarele: fata drepte, spate cu jaret; labele
    for sx in (-1.0, 1.0):
        _leg(b, (sx * 0.14, 0.47, 0.64), (sx * 0.14, 0.48, 0.30), (sx * 0.14, 0.47, 0.06),
             0.11, 0.085, 0.075, FUR)
        _leg(b, (sx * 0.15, -0.46, 0.64), (sx * 0.15, -0.58, 0.27), (sx * 0.15, -0.52, 0.06),
             0.12, 0.08, 0.075, FUR)
        for y in (0.50, -0.50):
            _lump(b, (sx * 0.14, y, 0.05), (0.15, 0.19, 0.10), FUR, 61 + int(y * 10) + int(sx),
                  seg=6, rings=3, dev=0.05)
    # --- 8) coada stufoasa: 4 bulgari pe arc (atarna, varful se ridica)
    tail = [((0.0, -0.70, 0.88), (0.26, 0.24, 0.26)), ((0.0, -0.80, 0.78), (0.26, 0.22, 0.28)),
            ((0.0, -0.85, 0.66), (0.24, 0.20, 0.24)), ((0.0, -0.82, 0.57), (0.18, 0.16, 0.15))]
    for k, (c, sz) in enumerate(tail):
        _lump(b, c, sz, FUR, 71 + k, seg=7, rings=4, dev=0.16)

    # --- 3) + 6) petele gri, re-etichetate pe fetele existente (zero triunghiuri)
    def saddle(c, n):
        # saua: de la umar la crupa, pe spate si pana la jumatatea flancului
        return -0.40 <= c.y <= 0.24 and c.z > 0.80
    def mask(c, n):
        on_head = c.y > 0.64 and c.z > 1.13
        blaze = abs(c.x) < 0.045 and c.y > 0.66
        muzzle = c.y > 0.84 and c.z < 1.20
        return on_head and not blaze and not muzzle and abs(c.x) > 0.03
    allf = [f for f in b.bm.faces if f[b.slot] == FUR]
    b.retag(allf, PATCH, where=saddle)
    b.retag([f for f in b.bm.faces if f[b.slot] == FUR], PATCH, where=mask)
    return [b.to_object("Sheepdog")]


clear_built()
if not ONLY or ONLY == "sheepdog":
    emit_tf(build_sheepdog(), "animals/sheepdog.glb", AO_DOG, keep_xy=True, bevel=0.0,
            smooth_angle=32.0)
    clear_built()
report_tf()
