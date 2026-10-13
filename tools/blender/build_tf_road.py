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
      e) CALOTA de zapada peste placa si in spatele ei, 4 randuri x 4-5 blocuri neregulate:
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

    # --- movila pe laturi: (cx, cy, h, sx, sy) pe partea +X; oglindita pe -X cu
    # alt seed ca sa nu fie copie
    side = [
        (15.8, -3.2, 9.6, 5.6, 5.4), (15.8, -8.6, 9.2, 5.6, 5.4),
        (16.0, -13.8, 7.0, 5.8, 5.0),
        (20.4, -3.0, 6.8, 5.0, 5.0), (20.6, -8.2, 6.6, 5.2, 5.6),
        (20.8, -13.6, 5.0, 4.8, 5.0),
        (22.4, -3.4, 4.2, 3.4, 4.2), (22.4, -9.0, 4.0, 3.4, 5.0),
        (10.4, -9.0, 9.6, 5.6, 6.0),     # interior, in spatele placii (|x| 7,6..13)
        (10.6, -14.0, 7.0, 5.6, 5.0),
    ]
    for sx in (1, -1):
        for k, (cx, cy, h, bx, by) in enumerate(side):
            faceted_block(snow, (sx * cx, cy, 0.0), (bx, by, h), TF_SNOW,
                          seed=100 + k * 7 + (0 if sx > 0 else 53))

    # --- calota: 4 randuri x 4-5 blocuri neregulate deasupra placii si a tubului
    import random
    rr = random.Random(77)
    rows = [(-3.6, 10.3, 1.9, 5.0, 12.2), (-6.6, 8.55, 3.8, 5.6, 12.7),
            (-10.6, 8.55, 4.4, 5.6, 13.1), (-14.2, 8.55, 4.2, 5.0, 12.4)]
    for r, (cy, zb, hh, by, top) in enumerate(rows):
        n = 5 if r else 4
        for i in range(n):
            cx = -12.0 + 24.0 * (i + 0.5) / n + (rr.random() - 0.5) * 2.2
            wx = 5.8 + rr.random() * 3.2
            ht = top - zb + (rr.random() - 0.5) * 1.2
            faceted_block(snow, (cx, cy + (rr.random() - 0.5) * 0.8, zb - (0.0 if r else 0.0)),
                          (wx, by + rr.random() * 1.2, ht), TF_SNOW,
                          seed=300 + r * 11 + i, jag=0.42)
    # --- praf: bucati scurte, inclinate, neregulate, pe blocurile de jos din fata
    patches = [(14.4, -0.5, 1.3, 2.1, 14.0), (18.2, -0.4, 3.0, 1.6, -19.0),
               (21.0, -0.6, 2.2, 2.4, 9.0)]
    for sx in (1, -1):
        for (x, y, z, ln, ang) in patches:
            dust_patch(dust, (sx * (x + (0.7 if sx < 0 else 0.0)), y - 0.38, z), ln * 1.3, sx * ang, height=0.3)

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
