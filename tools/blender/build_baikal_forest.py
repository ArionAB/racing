"""Baikal — kitul de padure si mal (planşa, pozitia 13).

  UN FISIER PE COPAC (baikal/trees/): larch_winter_a/b/c.glb,
                                      birch_winter_a/b/c.glb,
                                      pine_siberian_a/b.glb
  shore_kit.glb  (props/)  ShrubSnow, GrassTuftDry, BoulderLichen_A/B/C,
                           CliffFaceOlkhon, HuntingCabin, ShoreStaircase

Cele trei specii se deosebesc prin STRATEGII DIFERITE de constructie, fiindca
arata fundamental diferit iarna:

  larice   — foioasa care si-a pierdut acele: raman doar ramurile ruginii.
             Silueta e o retea rara de crengi, deci se face din BEAM-uri
             (ramuri reale), nu din conuri. Costa mai mult per copac, dar un
             con verde ar fi o minciuna: laricele iarna e transparent.
  mesteacan— trunchi ALB cu dungi negre (semnatura absoluta) + coroana de
             crengi violacee. Trunchiul e ce se vede; coroana e o masa rara.
  pin      — singurul care ramane VERDE si opac iarna: conuri etajate, cu
             zapada pe "palme". Aici modelul de con e corect.

Bugetul din brief e ~120k pentru padure cu 3 planuri pe copac. Masuram, nu
presupunem — cifrele reale se printeaza la build.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_baikal_forest.py
"""

import math
from mathutils import Matrix, Vector

AO_TREE = dict(samples=18, dist=3.0, gradient="vertical",
               low=0.34, high=1.00, power=0.9, floor=0.12)
AO_ROCK = dict(samples=24, dist=4.0, gradient="vertical",
               low=0.38, high=1.00, power=0.95, floor=0.10)
AO_BUILD = dict(samples=24, dist=4.5, gradient="vertical",
                low=0.45, high=1.00, power=0.9, floor=0.12)
AO_PROP = dict(samples=20, dist=2.5, gradient="vertical",
               low=0.48, high=1.00, power=0.9, floor=0.15)

GLASS = ASPHALT


def _drop_to_zero(objs):
    bpy.context.view_layer.update()
    lo = min(min((o.matrix_world @ Vector(c)).z for c in o.bound_box)
             for o in objs)
    for o in objs:
        o.location.z -= lo


def _tapered_trunk(b, height, r_base, r_top, slot, segments=7, lean=0.0,
                   bends=3, seed=0):
    """Trunchi din cateva tronsoane, cu o inclinare usoara si o indoitura.

    Un cilindru drept citeste ca un stalp. Doua-trei tronsoane cu deviatii de
    cativa centimetri sunt destule ca sa para crescut, si costa aproape nimic.
    Intoarce lista de puncte pe axa, ca ramurile sa poata pleca de pe ea.
    """
    rand = _lcg(seed)
    pts = []
    x = y = 0.0
    for i in range(bends + 1):
        t = i / float(bends)
        z = height * t
        x += lean * height / bends + (rand() - 0.5) * height * 0.02
        y += (rand() - 0.5) * height * 0.02
        pts.append(Vector((x, y, z)))
    for i in range(bends):
        t0, t1 = i / float(bends), (i + 1) / float(bends)
        r0 = r_base + (r_top - r_base) * t0
        r1 = r_base + (r_top - r_base) * t1
        b.taper_sweep([pts[i], pts[i + 1]], [r0, r1], slot, segments=segments,
                      cap_start=(i == 0))
    return pts


def _axis_point(pts, t):
    """Punct pe axa trunchiului la fractiunea t din inaltime."""
    n = len(pts) - 1
    f = max(0.0, min(0.999, t)) * n
    i = int(f)
    return pts[i].lerp(pts[i + 1], f - i)


# ============================================================ Larice de iarna
def _larch(name, height, seed):
    """Larice fara ace: retea rara de ramuri ruginii pe un trunchi conic.

    Ramurile pleaca aproape ORIZONTAL si se lasa la varf — asa arata laricele,
    si asta il deosebeste de un brad. Fiecare ramura e un lant de doua
    beam-uri (nu unul singur): franta la mijloc, ca sa se citeasca lasarea.
    """
    b = Builder()
    rand = _lcg(seed)
    r_base = height * 0.022
    axis = _tapered_trunk(b, height, r_base, r_base * 0.16, LARCH_RUST,
                          segments=6, lean=(rand() - 0.5) * 0.02, bends=3,
                          seed=seed)
    # Ramurile incep de la 35% din inaltime: sub asta laricele si-a pierdut
    # crengile de jos (padure deasa).
    whorls = 9
    for i in range(whorls):
        t = 0.35 + 0.62 * (i / (whorls - 1.0))
        base = _axis_point(axis, t)
        # lungimea scade spre varf; cea mai lunga e la ~45% din inaltime
        span = height * 0.30 * (1.0 - abs(t - 0.45) * 0.95)
        cnt = 7 if i % 2 == 0 else 6
        for k in range(cnt):
            a = math.radians(k * (360.0 / cnt) + i * 47.0 + rand() * 22.0)
            d = Vector((math.cos(a), math.sin(a), 0.0))
            L = span * (0.70 + rand() * 0.55)
            mid = base + d * (L * 0.55) + Vector((0, 0, L * 0.10))
            tip = base + d * L + Vector((0, 0, -L * 0.22))
            b.beam(base, mid, r_base * 0.30, LARCH_RUST)
            b.beam(mid, tip, r_base * 0.17, LARCH_RUST)
            # trei ramificatii pe ramura: cu doua, laricele iesea un
            # schelet de umbrela. Ce se citeste la specia asta iarna e
            # DENSITATEA de crengute fine pe orizontala.
            for s in (0.35, 0.62, 0.85):
                p = mid.lerp(tip, s)
                a2 = a + math.radians((rand() - 0.5) * 90.0)
                d2 = Vector((math.cos(a2), math.sin(a2), 0.0))
                b.beam(p, p + d2 * (L * 0.24) + Vector((0, 0, -L * 0.06)),
                       r_base * 0.11, LARCH_RUST)
    obj = b.to_object(name)
    finish(obj, bevel=0.012, bevel_angle=40.0, ao=AO_TREE, origin="none",
           smooth_angle=50.0)
    return obj


# ============================================================ Mesteacan
def _birch(name, height, seed):
    """Mesteacan de iarna: trunchi alb cu dungi negre + coroana rara violacee.

    Dungile negre sunt SEMNATURA speciei si singurul motiv pentru care un
    mesteacan se recunoaste de la 60 m. Se fac ca inele scurte de slot inchis
    pe trunchi — cost zero in triunghiuri fata de trunchiul simplu, si e exact
    genul de detaliu care nu poate veni din textura (UV-urile sunt colapsate).
    """
    b = Builder()
    rand = _lcg(seed)
    r_base = height * 0.018
    axis = _tapered_trunk(b, height, r_base, r_base * 0.20, FOAM_WHITE,
                          segments=7, lean=(rand() - 0.5) * 0.03, bends=3,
                          seed=seed)
    # dungile negre: inele turtite, la inaltimi neregulate, mai dese jos
    for i in range(11):
        t = 0.05 + 0.72 * (i / 10.0) ** 1.25
        p = _axis_point(axis, t)
        r = (r_base + (r_base * 0.20 - r_base) * t) * 1.06
        b.box((p.x, p.y, p.z), (r * 2.0, r * 2.0, height * (0.006 + rand() * 0.010)),
              VOLCANIC_BLACK, rotation=Matrix.Rotation(rand() * 3.14, 3, "Z"))
    # coroana: ramuri care urca in evantai (mesteacanul are coroana inalta,
    # ingusta si "maturoasa"), din PAINTED — violaceul crengilor de iarna
    for i in range(7):
        t = 0.52 + 0.44 * (i / 6.0)
        base = _axis_point(axis, t)
        cnt = 4
        for k in range(cnt):
            a = math.radians(k * 90.0 + i * 41.0 + rand() * 30.0)
            d = Vector((math.cos(a), math.sin(a), 0.0))
            L = height * 0.16 * (0.7 + rand() * 0.6)
            # ramura URCA (evantai), spre deosebire de larice care se lasa
            tip = base + d * L + Vector((0, 0, L * (0.55 + rand() * 0.5)))
            b.beam(base, tip, r_base * 0.16, PAINTED)
            for s in (0.5, 0.82):
                p = base.lerp(tip, s)
                a2 = a + math.radians((rand() - 0.5) * 70.0)
                d2 = Vector((math.cos(a2), math.sin(a2), 0.0))
                b.beam(p, p + d2 * (L * 0.3) + Vector((0, 0, L * 0.35)),
                       r_base * 0.09, PAINTED)
    # putina zapada pe ramurile groase
    obj = b.to_object(name)
    finish(obj, bevel=0.010, bevel_angle=40.0, ao=AO_TREE, origin="none",
           smooth_angle=50.0)
    return obj


# ============================================================ Pin siberian
def _pine(name, height, seed):
    """Pin siberian: conuri etajate verzi cu zapada pe fiecare etaj.

    Singurul copac OPAC din kit — iarna pinul e masa intunecata care da
    profunzime padurii de siluete. Etajele se suprapun (0.34 din inaltimea
    etajului), altfel intre conuri raman inele de trunchi gol si copacul
    citeste ca o stiva de palarii — problema deja rezolvata la kitul alpin.

    Iese in TREI obiecte (trunchi / coroana / zapada), nu unul: coroana ia
    clasa triplanara `pine_needles` si zapada clasa `snow`, iar
    `apply_class_materials` mapeaza pe NUME de nod — intr-un singur mesh,
    acele pictate ar imbraca si trunchiul, si zapada (BAIKAL_CLASSES in
    track_decor.gd, acelasi model ca pinii alpini / PINE_CLASSES).
    Toate trei se construiesc in acelasi spatiu si se exporta impreuna,
    deci impart originea de la baza trunchiului — un ansamblu, ca biserica.
    """
    suffix = name.rsplit("_", 1)[1]
    bt = Builder()
    bc = Builder()
    bs = Builder()
    rand = _lcg(seed)
    trunk_h = height * 0.22
    r_base = height * 0.020
    _tapered_trunk(bt, trunk_h * 1.25, r_base, r_base * 0.7, LOG_DARK,
                   segments=6, bends=1, seed=seed)
    tiers = 6
    canopy = height - trunk_h
    tier_h = canopy / (tiers - 0.34 * (tiers - 1))
    z = trunk_h
    for i in range(tiers):
        t = i / float(tiers - 1)
        r_bot = height * 0.16 * (1.0 - 0.46 * t)
        r_top = r_bot * (0.0 if i == tiers - 1 else 0.32)
        segs = 12 if i % 2 == 0 else 10
        bc.frustum((0.0, 0.0, z + tier_h * 0.5), r_bot, r_top, tier_h,
                   TROPICAL_GREEN, segments=segs)
        # Zapada pe "palme": inel turtit asezat PE UMARUL etajului, adica pe
        # cota de jos a conului (z), unde creanga e orizontala si zapada chiar
        # se aduna. Prima versiune il punea la z + tier_h*0.16 — adica in
        # interiorul conului, sub suprafata: la randarea de control pinii
        # ieseau complet verzi, fara nicio urma de zapada, desi geometria
        # exista si triunghiurile se numarau.
        #
        # Inelul e mai LAT decat conul la baza (1.02), nu mai ingust: zapada
        # sta pe varful crengii si depaseste conturul acelor.
        if i < tiers - 1:
            bs.frustum((0.0, 0.0, z + tier_h * 0.03), r_bot * 1.02,
                       r_bot * 0.70, tier_h * 0.16, FOAM_WHITE, segments=segs)
        z += tier_h * 0.66
    parts = [bt.to_object(name),
             bc.to_object("PineCrown_" + suffix),
             bs.to_object("PineSnow_" + suffix)]
    for obj in parts:
        finish(obj, bevel=0.02, bevel_angle=40.0, ao=AO_TREE, origin="none",
               smooth_angle=50.0)
    return parts


def build_forest_kit():
    clear_built()
    objs = []
    # brief: larice 10-16 m, mesteacan 8-14 m, pin 12-18 m
    for k, h in enumerate((10.0, 13.0, 16.0)):
        objs.append(_larch("LarchWinter_%s" % "ABC"[k], h, seed=1100 + k * 37))
    for k, h in enumerate((8.0, 11.0, 14.0)):
        objs.append(_birch("BirchWinter_%s" % "ABC"[k], h, seed=2200 + k * 41))
    # Pinul iese in trei parti (trunchi/coroana/zapada, vezi _pine) — in
    # liste, ca partile unui copac sa ramana impreuna la export si in .blend.
    pines = []
    for k, h in enumerate((12.0, 18.0)):
        pines.append(_pine("PineSiberian_%s" % "AB"[k], h, seed=3300 + k * 53))

    # UN FISIER PE COPAC, ca la cladirile de sat.
    #
    # Copacii se imprastie statistic (spre deosebire de case), deci ar fi fost
    # candidatii naturali pentru un GLB multi-nod. Ii spargem oricum, din doua
    # motive practice:
    #   - sunt de trei SPECII cu siluete complet diferite, iar decorul alege
    #     specia dupa zona (larice pe deal, mesteacan in padure, pin la umbra);
    #     cu fisiere separate, alegerea e calea, nu un filtru de noduri.
    #   - laricele are 13.140 de triunghiuri, pinul 874 — de 15 ori mai putin.
    #     Intr-un GLB comun, orice incarcare a unui pin aducea in memorie si
    #     cele trei larice, adica ~40k de triunghiuri nefolositi.
    #
    # Piesele se exporta DIN ORIGINE: fiecare fisier isi are originea la baza
    # trunchiului. Asezarea pe rand se face DUPA export, doar pentru .blend.
    files = {
        "LarchWinter_A": "baikal/trees/larch_winter_a.glb",
        "LarchWinter_B": "baikal/trees/larch_winter_b.glb",
        "LarchWinter_C": "baikal/trees/larch_winter_c.glb",
        "BirchWinter_A": "baikal/trees/birch_winter_a.glb",
        "BirchWinter_B": "baikal/trees/birch_winter_b.glb",
        "BirchWinter_C": "baikal/trees/birch_winter_c.glb",
        "PineSiberian_A": "baikal/trees/pine_siberian_a.glb",
        "PineSiberian_B": "baikal/trees/pine_siberian_b.glb",
    }
    for o in objs:
        export_glb([o], files[o.name])
    for parts in pines:
        export_glb(parts, files[parts[0].name])
        objs.extend(parts)
    print("ForestKit: %d tris in %d fisiere (%s)"
          % (sum(tri_count(o) for o in objs), len(objs) - len(pines) * 2,
             ", ".join("%s %d" % (o.name, tri_count(o)) for o in objs)))

    # .blend-ul ramane comun, cu copacii pe un rand ca sa fie lizibil.
    # Partile unui pin se muta IMPREUNA — sunt acelasi copac.
    x = 0.0
    for o in objs:
        if o.name.startswith(("PineCrown", "PineSnow")):
            o.location.x = x - 8.0  # acelasi x ca trunchiul dinaintea lor
            continue
        o.location.x = x
        x += 8.0
    save_blend(objs, "baikal_forest_kit.blend")
    return objs


# ============================================================ Mal si teren
def build_shore_kit():
    clear_built()
    objs = []

    # --- tufa sub zapada, 1 m ----------------------------------------------
    b = Builder()
    rand = _lcg(1357)
    for i in range(11):
        a = 2.0 * math.pi * rand()
        r = rand() * 0.32
        base = Vector((math.cos(a) * r, math.sin(a) * r, 0.0))
        L = 0.55 + rand() * 0.45
        a2 = a + (rand() - 0.5) * 1.2
        tip = base + Vector((math.cos(a2) * L * 0.42, math.sin(a2) * L * 0.42,
                             L))
        b.beam(base, tip, 0.022, DRY_VEGETATION)
    # caciula de zapada peste tufa
    b.rock((0.0, 0.0, 0.52), (0.85, 0.80, 0.34), FOAM_WHITE, seed=17,
           segments=7, rings=2, taper=0.55, squash=0.65)
    shrub = b.to_object("ShrubSnow")
    finish(shrub, bevel=0.012, ao=AO_PROP, origin="base")
    objs.append(shrub)

    # --- smoc de iarba galbena, 0.4 m --------------------------------------
    b = Builder()
    rand = _lcg(2468)
    for i in range(14):
        a = 2.0 * math.pi * rand()
        r = rand() * 0.10
        base = Vector((math.cos(a) * r, math.sin(a) * r, 0.0))
        L = 0.26 + rand() * 0.20
        lean = 0.30 + rand() * 0.45
        tip = base + Vector((math.cos(a) * L * lean, math.sin(a) * L * lean, L))
        b.beam(base, tip, (0.016, 0.005), DRY_VEGETATION)
    tuft = b.to_object("GrassTuftDry")
    finish(tuft, bevel=0.006, ao=AO_PROP, origin="base")
    objs.append(tuft)

    # --- trei bolovani cu licheni si capac de zapada -----------------------
    for k, size in enumerate(((1.2, 1.0, 0.9), (2.2, 1.8, 1.5),
                              (3.2, 2.6, 2.1))):
        b = Builder()
        b.boulder((0.0, 0.0, 0.0), size, MARBLE_GREY, seed=400 + k * 61,
                  segments=8, rings=4)
        # capacul de zapada: pe fata de SUS, o calota turtita retrasa de la
        # margine (zapada aluneca de pe flancuri, ramane pe platou)
        b.rock((0.0, 0.0, size[2] * 0.62), (size[0] * 0.78, size[1] * 0.78,
                                            size[2] * 0.30),
               FOAM_WHITE, seed=500 + k * 13, segments=7, rings=2, taper=0.6,
               squash=0.55)
        obj = b.to_object("BoulderLichen_%s" % "ABC"[k])
        finish(obj, bevel=0.04, ao=AO_ROCK, origin="base")
        _tint_lichen(obj)
        objs.append(obj)

    # --- modul de faleza, 15-30 m ------------------------------------------
    # Roca stratificata gri-brun cu gheata scursa pe ea. `wall_axis="y"` tine
    # fata dinspre -Y verticala: e peretele pe care il vede soferul, restul
    # cade in trepte si economiseste triunghiuri pe partea nevazuta.
    b = Builder()
    b.rock((0.0, 0.0, 0.0), (18.0, 9.0, 15.0), MARBLE_GREY, seed=6161,
           segments=9, rings=6, taper=0.12, wall_axis="y",
           strata_slots=(MARBLE_GREY, ROCK_DARK, MARBLE_GREY, ASPHALT_EDGE))
    # gheata scursa pe fata: fasii verticale inguste, de sus in jos
    rand = _lcg(717)
    for i in range(9):
        x = -7.5 + rand() * 15.0
        top = 6.0 + rand() * 7.0
        h = top * (0.45 + rand() * 0.5)
        b.box((x, -4.4, top - h * 0.5), (0.35 + rand() * 0.5, 0.30, h),
              ICE_TURQUOISE)
    cliff = b.to_object("CliffFaceOlkhon")
    finish(cliff, bevel=0.06, ao=AO_ROCK, origin="base")
    objs.append(cliff)

    # --- cabana de vanatoare, 5x4x3.5 --------------------------------------
    b = Builder()
    _log_wall_local(b, (0.0, 0.0, 0.0), (5.0, 4.0, 2.5), seed=808)
    b.prism([(-2.5, 2.5), (0.0, 3.5), (2.5, 2.5)], 4.0, LOG_DARK)
    _gable_local(b, 2.5, 2.5, 3.5, 4.0, 0.0)
    b.box((0.0, 0.0, 0.14), (5.3, 4.3, 0.28), MARBLE_GREY)
    # veranda: doi stalpi + acoperis mic in fata (+Y)
    for sx in (-1, 1):
        b.frustum((sx * 1.7, 2.75, 1.15), 0.13, 0.11, 2.3, WOOD, segments=7)
    b.box((0.0, 2.55, 2.38), (4.4, 1.6, 0.14), VOLCANIC_BLACK)
    b.box((0.0, 2.55, 2.50), (4.2, 1.5, 0.10), FOAM_WHITE)
    b.box((0.0, 2.02, 0.10), (4.2, 1.5, 0.20), WOOD)         # podeaua verandei
    b.box((0.6, 2.02, 1.15), (0.80, 0.10, 1.95), WOOD)       # usa
    b.box((-1.1, 2.02, 1.55), (0.62, 0.10, 0.62), GLASS)     # fereastra
    b.box((-1.1, 2.05, 1.55), (0.76, 0.08, 0.78), PAINTED)
    b.box((-1.6, -0.8, 3.9), (0.42, 0.42, 1.2), ASPHALT_EDGE)  # horn
    cabin = b.to_object("HuntingCabin")
    finish(cabin, bevel=0.03, ao=AO_BUILD, origin="base")
    objs.append(cabin)

    # --- scara de lemn de pe faleza la gheata, 12 m ------------------------
    # Coboara in doua rampe cu un podest la mijloc — o scara dreapta de 12 m
    # ar fi o rampa, nu o scara, si n-ar sta pe niciun mal real.
    b = Builder()
    _stairs_flight(b, start=Vector((0.0, 0.0, 6.0)),
                   end=Vector((0.0, 4.6, 3.1)), width=1.3, seed=91)
    b.box((0.0, 5.3, 3.05), (1.5, 1.5, 0.16), WOOD)          # podest
    for sx in (-1, 1):
        b.beam((sx * 0.65, 5.3, 3.05), (sx * 0.65, 5.3, 4.05), 0.09, WOOD)
    _stairs_flight(b, start=Vector((0.0, 6.0, 3.0)),
                   end=Vector((0.0, 10.4, 0.05)), width=1.3, seed=92)
    stairs = b.to_object("ShoreStaircase")
    finish(stairs, bevel=0.02, ao=AO_PROP, origin="base")
    objs.append(stairs)

    # Exportul se face DIN ORIGINE (asezarea pe rand vine dupa), altfel
    # offsetul de prezentare ar intra in fiecare fisier.
    _drop_to_zero(objs)
    print("ShoreKit: %d tris in %d fisiere (%s)"
          % (sum(tri_count(o) for o in objs), len(objs),
             ", ".join("%s %d" % (o.name, tri_count(o)) for o in objs)))
    # UN FISIER PE PIESA — piesele kitului sunt obiecte independente,
    # nu partile unui ansamblu. Vezi nota din build_baikal_village.py.
    # Fiecare piesa in CATEGORIA ei, nu toate in props/: bolovanii si faleza
    # la rocks/, tufele la plants/, cabana la buildings/, scara la structures/.
    files = {
        "ShrubSnow": "baikal/plants/shrub_snow.glb",
        "GrassTuftDry": "baikal/plants/grass_tuft_dry.glb",
        "BoulderLichen_A": "baikal/rocks/boulder_lichen_a.glb",
        "BoulderLichen_B": "baikal/rocks/boulder_lichen_b.glb",
        "BoulderLichen_C": "baikal/rocks/boulder_lichen_c.glb",
        "CliffFaceOlkhon": "baikal/rocks/cliff_face_olkhon.glb",
        "HuntingCabin": "baikal/buildings/hunting_cabin.glb",
        "ShoreStaircase": "baikal/structures/shore_staircase.glb",
    }
    for o in objs:
        export_glb([o], files[o.name])

    # .blend-ul ramane comun, cu piesele pe un rand ca sa fie lizibil.
    x = 0.0
    for o in objs:
        o.location.x = x
        x += 10.0
    save_blend(objs, "baikal_shore_kit.blend")
    return objs


def _stairs_flight(b, start, end, width, seed, step_rise=0.28):
    """O rampa de scara: trepte + doua coarde + balustrada.

    Numarul de trepte se DERIVA din diferenta de cota (nu se alege): la
    step_rise fix, o scara pe un mal de 3 m are exact atatea trepte cate incap,
    si asa arata corect indiferent pe ce cota o pui pista.
    """
    d = end - start
    n = max(int(abs(d.z) / step_rise), 2)
    for i in range(n):
        t = (i + 0.5) / n
        p = start + d * t
        b.box((p.x, p.y, p.z), (width, abs(d.y) / n * 0.92, 0.07), WOOD)
    # coardele laterale
    for sx in (-1, 1):
        b.beam((start.x + sx * width * 0.5, start.y, start.z - 0.10),
               (end.x + sx * width * 0.5, end.y, end.z - 0.10), 0.11, WOOD)
    # balustrada: stalpi la fiecare 4 trepte + mana curenta
    rand = _lcg(seed)
    posts = max(n // 4, 2)
    for sx in (-1, 1):
        for i in range(posts + 1):
            t = i / float(posts)
            p = start + d * t
            b.beam((p.x + sx * width * 0.5, p.y, p.z),
                   (p.x + sx * width * 0.5, p.y, p.z + 0.95), 0.07, WOOD)
        b.beam((start.x + sx * width * 0.5, start.y, start.z + 0.95),
               (end.x + sx * width * 0.5, end.y, end.z + 0.95), 0.07, WOOD)


def _log_wall_local(b, center, size, seed, slot=LOG_DARK, log_h=0.40):
    cx, cy, cz = center
    sx, sy, sz = size
    rows = max(int(sz / log_h), 1)
    h = sz / rows
    rand = _lcg(seed)
    for i in range(rows):
        z = cz + h * (i + 0.5)
        d = 0.03 + rand() * 0.05
        b.box((cx, cy, z), (sx + d, sy + d, h * 0.92), slot)
    for i in range(0, rows, 2):
        z = cz + h * (i + 0.5)
        b.box((cx, cy, z), (sx + 0.45, sy * 0.14, h * 0.88), slot)
        b.box((cx, cy, z), (sx * 0.14, sy + 0.45, h * 0.88), slot)


def _gable_local(b, half_w, eave_z, ridge_z, depth, y_center,
                 slot=VOLCANIC_BLACK, overhang=0.5, thickness=0.15):
    rise = ridge_z - eave_z
    ang = math.atan2(rise, half_w)
    slope = math.hypot(half_w + overhang, rise * (1.0 + overhang / half_w))
    length = slope + 0.3
    for sgn in (-1.0, 1.0):
        rot = Matrix.Rotation(sgn * ang, 3, "Y")
        t = length * 0.5 - 0.15
        mx = sgn * t * math.cos(ang)
        mz = ridge_z - t * math.sin(ang) + thickness * 0.35
        b.box((mx, y_center, mz), (length, depth + 2 * overhang, thickness),
              slot, rotation=rot)
        b.box((mx, y_center, mz + thickness * 0.78),
              (length * 0.94, depth + 2 * overhang * 0.8, thickness * 0.55),
              FOAM_WHITE, rotation=rot)


def _tint_lichen(obj, warm=(1.28, 0.74, 0.44)):
    """Licheni portocalii pe bolovani, ca tinta in vertex colors.

    Aceeasi reteta ca la Stanca Samanului (build_baikal_shaman._tint_lichen) si
    din acelasi motiv: un slot coloreaza FATA INTREAGA, deci pe fete de 1-3 m
    ar iesi dreptunghiuri curate — "stickere". Vertex colors interpoleaza, deci
    pata are margine moale.
    """
    me = obj.data
    ca = me.color_attributes.get("AO")
    if ca is None:
        return
    nrm = {}
    for poly in me.polygons:
        for vi in poly.vertices:
            nrm.setdefault(vi, []).append(poly.normal.copy())
    for v in me.vertices:
        ns = nrm.get(v.index)
        if not ns:
            continue
        ny = sum(n.y for n in ns) / len(ns)
        c = v.co
        n = (math.sin(c.x * 3.4 + c.z * 2.1)
             + math.cos(c.y * 2.9 - c.z * 2.6) * 0.8
             + math.sin((c.x + c.y) * 4.7) * 0.6)
        strength = 0.0
        if ny > 0.10:
            strength = max(0.0, min(1.0, (n - 0.70) / 0.85))
        if strength <= 0.0:
            continue
        col = ca.data[v.index].color
        ca.data[v.index].color = (
            col[0] * (1.0 + (warm[0] - 1.0) * strength),
            col[1] * (1.0 + (warm[1] - 1.0) * strength),
            col[2] * (1.0 + (warm[2] - 1.0) * strength),
            1.0)


if __name__ == "__main__":
    build_forest_kit()
    build_shore_kit()
