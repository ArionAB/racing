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

AO_PORTAL = dict(samples=16, dist=2.4, gradient="vertical", low=0.62, high=1.0,
                 power=0.8, floor=0.34, z_range=(0.0, 11.0))


def build_tunnel_portal_balea():
    """Portalul tunelului de la Balea (`tunnel_portal_balea`), PILOT.

    LISTA DE ELEMENTE (din decuparea `transfagarasan_assets_v1/tunnel_portal_balea.png`
    si din contractul §1.1 + corectura `snow_wall`; scrisa INAINTE de geometrie;
    fasia din piesa vecina de la marginea stanga a decuparii se ignora):
      a) frontispiciu: placa plata de beton, dreptunghiulara, 22 m lat x 11 m inalt
         (cornisa inclusa), 3,2 m grosime de corp; fara text, fara placuta
      b) cornisa SIMPLA in sus: o placa + un filet sub ea, iesite pe fata si pe
         spate (~0,4 / 0,2 m), nu iese pe lateral (zapada se lipeste de zid)
      c) gura: UNA, centrata, cu arc TURTIT (segmental) si 10 fatete; jamburi
         verticale pana la 7,2 m, sageata 1,35 m (cheia la 8,55 m); in decupare
         umerii arcului sunt tesiti (poligonal) -- arcul facetat il reda
      d) rama plata in jurul gurii (0,45 m latime, iesita 0,12 m) pe fata si spate:
         decuparea arata un cant tesit / buza in jurul golului
      e) doi pilastri laterali = restul frontispiciului (4,25 m fiecare parte)
      f) DOUA contraforturi joase pe fiecare fata (fata + spate = 4): 1,8 m lat,
         0,4 m iesite, 4,3 m inalte, capat in panta; stau pe pilastri (contract: doua)
      g) captuseala de umbra a gurii (`Portal_Void`): 3 m adancime, pe jamburi si
         arc, retrasa 3 cm, fara capace (golul ramane liber)
      h) pereti de zapada lipiti, pe AMBELE parti: 6 m spre exterior la baza, 4 m
         inalti, 4 straturi cu trepte de 0,3 m pe fetele taiate +-Y (contractul
         corecteaza blocurile fatetate din decupare), dungi de praf pe fetele
         spre drum (nod `Portal_Dust`, slot CONCRETE), baza murdara, muchia de
         sus rotunjita si ondulata. Lungime 8 m pe Y (rev. 2: 6 m citea subtire) (decizie: contractul da doar
         6 m pe X si 4 m pe Z)
      i) NU intra: asfaltul si marcajele din decupare, stanca fundalului,
         vegetatia (fara vegetatie lipita)

    Contract (golul, MASURAT pe GLB cu measure_gap): >= 13,0 m lateral pe banda
    caroseriei 0-2 m, >= 7,0 m inaltime libera. Aici: jamburi la +-6,75 m, captuseala
    retrasa 0,03 m -> ~13,44 m; jamburile urca la 7,2 m (minimul inaltimii libere).

    Cote tinta: 22,0 m lat betonul (34,0 m cu zapada), 4,0 m adanc (corp 3,2 +
    contraforturi), 11,0 m inalt; h/l ~0,5 (fara zapada).
    Noduri: Portal_Concrete (CONCRETE 8), Portal_Snow (FOAM_WHITE 22),
    Portal_Dust (CONCRETE 8, dungile), Portal_Void (VOLCANIC_BLACK 20).
    """
    HX = 11.0          # semilatimea betonului
    BY = 1.6           # semiadancimea corpului (3,2 m)
    JX = 6.75          # jamburile gurii
    ZS = 7.2           # cota la care incepe arcul (minimul inaltimii libere)
    RISE = 1.35        # sageata arcului
    ZB = 10.35         # sub cornisa
    ZT = 11.0          # varful cornisei
    N_ARCH = 10

    conc, snow, dust = Builder(), Builder(), Builder()
    void = Builder()

    # --- a/c/e) corpul: contur concav cu gura, extrudat pe adancime -------------
    arc, R, zc = segmental_arch(JX, ZS, RISE, N_ARCH)
    outline = [(-HX, 0.0), (-JX, 0.0)] + arc + [(JX, 0.0), (HX, 0.0), (HX, ZB), (-HX, ZB)]
    extrude_xz(conc, outline, -BY, BY, TF_CONCRETE)

    # --- b) cornisa
    concrete_cornice(conc, HX, BY, ZB, ZT)

    # --- d) rama gurii, pe fata si pe spate
    for sy in (-1, 1):
        arch_band(conc, JX, ZS, RISE, 0.45, sy * BY, 0.12, n=N_ARCH)

    # --- f) contraforturi: 2 pe fiecare fata
    for sy in (-1, 1):
        prof = [(BY, 0.0), (BY + 0.4, 0.0), (BY + 0.4, 3.4), (BY, 4.3)]
        if sy < 0:
            prof = [(-y, z) for y, z in reversed(prof)]
        for sx in (-1, 1):
            x0, x1 = sorted((sx * 7.95, sx * 9.75))
            prism_yz(conc, prof, x0, x1, TF_CONCRETE)

    # --- g) captuseala de umbra
    mouth_lining(void, JX, ZS, RISE, 1.5, inset=0.03, n=N_ARCH)

    # --- h) zapada, pe ambele parti
    for sx in (-1, 1):
        snow_layers(snow, dust, sx, HX, seed=0.7 + (0.0 if sx > 0 else 2.3))

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
            bevel=0.0, bevels={"_Concrete": 0.05}, smooth_angle=48.0)

report_tf()
