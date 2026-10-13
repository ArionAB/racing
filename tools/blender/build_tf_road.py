"""Transfagarasan -- drumul (brief docs/asset_briefs/transfagarasan_kit.md §1.1).

  transfagarasan/structures/tunnel_portal_balea.glb   portalul tunelului Balea  (PILOT)

Restul pieselor grupei (rock_tunnel_portal, snow_wall, retaining_wall_*,
snow_pole, road_works, level_crossing, bear_warning_sign) vin in valul 1.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_tf_road.py

Fara text, cifre sau logo-uri (regula 9). Fata = +Y in Blender (= -Z in Godot);
piesa e simetrica fata-spate, acelasi GLB la ambele guri. Originea: pe axa
drumului (x = 0, y = 0), baza pe Z = 0. Variabila de mediu TF_ONLY=<piesa> reface
doar piesa respectiva.
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "transfagarasan_shapes.py")).read())

clear_built()

AO_PORTAL = dict(samples=16, dist=2.6, gradient="vertical", low=0.62, high=1.0,
                 power=0.8, floor=0.34, z_range=(0.0, 13.5))


def build_tunnel_portal_balea():
    """Portalul tunelului de la Balea (`tunnel_portal_balea`), PILOT, REV. 2
    (contract nou al coordonatorului: placa masiva, gura teșita, zapada care
    INVELUIE portalul; planșa bate corectura `snow_wall` pentru piesa asta).

    LISTA DE ELEMENTE (din decuparea `transfagarasan_assets_v1/tunnel_portal_balea.png`
    si din contractul nou; scrisa INAINTE de geometrie; fasia din piesa vecina
    de la marginea stanga a decuparii se ignora):
      a) PLACA de beton: bloc masiv 26 m (X) x 11 m (Z) x 6 m (Y), muchii vii,
         FARA cornisa, contraforturi sau rama iesita; fata din fata (+Y) usor
         inclinata inapoi (~5 grade); pe planșa latura vizibila e ~1/4 din latime
         (6/26 = 0,23). Fata e DOAR pe +Y; spatele (-Y) intra in munte
      b) GURA dreptunghiulara cu umeri TESITI (nu arc): 15 m la baza (+-7,5),
         stalpi verticali pana la 6,5 m, tesituri la 45 grade de 2 m, buiandrug
         drept la 8,5 m (~58% din latime, ca pe planșa)
      c) `Portal_Void`: captuseala pe pereti si tavan, pe toata grosimea placii
         si 4 m in spate (10 m, y -10..0), fara podea, fara capace; in preview
         (NU in GLB) un plan negru la y = -12
      d) MOVILA DE ZAPADA pe laturi: 8 blocuri mari, fatetate, unghiulare pe
         fiecare parte (planșa: 5-6 vizibile), 9-10 m langa placa, coborand la
         ~4 m la 11 m spre exterior; incep de la |x| >= 13 (nimic in banda
         drumului), fata blocurilor ~0,5 m in spatele fetei placii (placa iese
         ~1 m in fata zapezii la baza)
      e) CALOTA de zapada peste placa si in spatele ei, 3 randuri x 4-5 blocuri neregulate:
         urca spre -Y pana la ~13 m, la 10 m in spate; pe deasupra tubului
         sta de la 8,55 m in sus (peste captuseala), deci golul ramane liber
      f) 2 blocuri interioare in spatele placii (|x| 7,6..13) care inchid
         peretii tubului
      g) PRAFUL `Portal_Dust`: 3 bucati scurte, inclinate, NEregulate, pe
         blocurile de jos din fata, pe fiecare parte
      h) NU intra: asfaltul, marcajele, vegetatia

    Contract (golul, MASURAT pe GLB): >= 13,0 m lateral pe 0-2 m, >= 7,0 m
    inaltime libera in fereastra |x| <= 6,5 (aici ~14,9 m si ~7,5 m).
    Noduri: Portal_Concrete (CONCRETE 8), Portal_Snow (FOAM_WHITE 22),
    Portal_Dust (CONCRETE 8), Portal_Void (VOLCANIC_BLACK 20). Origine pe
    axa drumului, la fata placii (y = 0 la baza), baza la z = 0.
    """
    HX, DEP, H = 13.0, 6.0, 11.0
    TAN = math.tan(math.radians(5.0))
    conc, snow, dust, void = Builder(), Builder(), Builder(), Builder()

    mouth = [(-7.5, 0.0), (-7.5, 6.5), (-5.5, 8.5), (5.5, 8.5), (7.5, 6.5), (7.5, 0.0)]
    outline = [(-HX, 0.0)] + mouth + [(HX, 0.0), (HX, H), (-HX, H)]
    extrude_xz(conc, outline, -DEP, 0.0, TF_CONCRETE)
    tilt_front(conc, 0.0, TAN)

    tube_lining(void, mouth, -DEP - 4.0, 0.0, TAN)

    import random
    rr = random.Random(2026)
    sxs = (1, -1)
    snow_faces_pool = {1: [], -1: []}

    # --- movila-POTCOAVA pe laturi: arc de elipsa in plan (centru y = -8), 7
    # pozitii pe unghi 14 -> -52 grade, doua inele (interior inalt, exterior mai
    # jos), blocuri stivuite pe 1-3 niveluri
    def hgt(th, k):
        t = (14.0 - th) / 55.0                 # 0 la placa, 1 la capete
        return k * (10.0 - 6.0 * t)
    angs = [14.0, 5.0, -4.0, -13.0, -22.0, -31.0, -41.0]
    for sx in sxs:
        for ring, (ea, eb, hk, rad) in enumerate(((16.2, 10.5, 1.0, 3.1), (20.4, 13.6, 0.62, 2.8))):
            for i, th in enumerate(angs):
                x = sx * ea * math.cos(math.radians(th)) + rr.uniform(-0.5, 0.5)
                y = -8.0 + eb * math.sin(math.radians(th)) + rr.uniform(-0.5, 0.5)
                h = hgt(th, hk)
                nlev = int((h - 2.8) / 2.2 + 0.35) + 1
                for lv in range(nlev):
                    inward = 0.35 * lv
                    cx = x - sx * inward * rr.uniform(0.3, 1.0) + rr.uniform(-0.4, 0.4)
                    cy = y + inward * rr.uniform(0, 1) * (1 if th > -20 else -1) * 0.3 + rr.uniform(-0.4, 0.4)
                    rl = rad * rr.uniform(0.9, 1.15) * (1.0 - 0.07 * lv)
                    cz = 1.25 + 2.1 * lv
                    bulgar(snow, (cx, cy, cz), rl, TF_SNOW, seed=1000 + sx * 7 + ring * 97 + i * 13 + lv,
                           base=0.0 if lv == 0 else None, zk=0.95)
        # interior: umple spatele placii langa tub (|x| 7,9..13), pana la 9 m
        for (cx, cy, nl) in ((10.9, -7.2, 4), (10.9, -11.0, 4), (11.3, -14.8, 2)):
            for lv in range(nl):
                bulgar(snow, (sx * (cx + rr.uniform(-0.3, 0.3)), cy + rr.uniform(-0.4, 0.4), 1.3 + 2.1 * lv),
                       2.9 * rr.uniform(0.9, 1.1), TF_SNOW, seed=2000 + sx * 5 + cx * 3 + lv + nl * 17,
                       base=0.0 if lv == 0 else None, zk=0.95)

    # --- calota: bulgari mari (3-4 m raza) peste placa si peste tub, 3 randuri
    rows = [(-5.2, 9.8, 12.5, 3.5), (-9.8, 8.55, 13.3, 3.7),
            (-14.4, 8.55, 12.6, 3.5)]
    for r, (cy, zb, top, rad) in enumerate(rows):
        n = 7
        for i in range(n):
            cx = -12.5 + 25.0 * (i + 0.5) / n + rr.uniform(-1.0, 1.0)
            ycn = cy + rr.uniform(-0.9, 0.9)
            hz = (top - zb) * 0.5
            bulgar(snow, (cx, ycn, zb + hz), rad * rr.uniform(0.9, 1.1), TF_SNOW,
                   seed=3000 + r * 31 + i, base=zb, zk=hz / (rad * 0.75))

    # nicio zapada in fata planului y = -2,5 (placa iese 2,5 m din zapada)
    for v in snow.bm.verts:
        if v.co.y > -2.5:
            v.co.y = -2.5

    # --- praful: fete (nu volume) din blocurile de jos, 5 pe parte, seed fix
    snow.bm.faces.ensure_lookup_table()
    for sx in sxs:
        pool = []
        for f in snow.bm.faces:
            c = f.calc_center_median()
            if (c.x * sx > 12.0 and c.z < 3.8 and f.normal.z < 0.55
                    and f.calc_area() > 1.0 and c.y > -13.0
                    and f.normal.y * 0.8 + f.normal.x * sx * 0.5 > 0.15):
                pool.append(f)
        random.Random(7 + sx).shuffle(pool)
        faces_to_dust(snow, dust, pool[:5])

    return [Builder.to_object(conc, "Portal_Concrete"),
            Builder.to_object(snow, "Portal_Snow"),
            Builder.to_object(dust, "Portal_Dust"),
            to_obj(void, "Portal_Void")]


ONLY = os.environ.get("TF_ONLY", "")


def _want(name):
    return not ONLY or ONLY == name


if _want("tunnel_portal_balea"):
    objs = build_tunnel_portal_balea()
    emit_tf(objs, "structures/tunnel_portal_balea.glb", AO_PORTAL, keep_xy=True,
            bevel=0.0, smooth_angle=None)

report_tf()
