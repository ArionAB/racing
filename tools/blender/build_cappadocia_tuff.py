"""Cappadocia — TUFF KIT A: formatiunile de piatra (plansa, grupul 9).

  cappadocia/rocks/chimney_{a,b,c,d}.glb   hornuri de zana, 10-18 m, palarie de bazalt
  cappadocia/rocks/chimney_mushroom.glb    hornul-ciuperca (palarie mult mai lata ca gatul)
  cappadocia/rocks/chimney_triple.glb      hornul cu trei palarii (Pasabag)
  cappadocia/rocks/cliff_band_module.glb   felie de faleza in benzi roz-rosu, 20 m
  cappadocia/rocks/rock_church_facade.glb  fatada de biserica rupestra, sapata in con

De ce hornul NU e un simplu con (brief §0.1, 55% din pista e geologie de tuf):
silueta reala are TREI parti, si toate trei se vad de la 40 m —

  1. **conul** care se subtiaza CONTINUU, ca un cort: fara umar la baza si
     fara portiune dreapta la mijloc (vezi `CONE_EXP`). Prima versiune avea
     exponent subunitar, si asta o facea sa citeasca drept cos de fabrica;
  2. **palaria de bazalt**, putin mai lata decat gatul (1.3x) si ASCUTITA,
     ca sa continue linia conului. Peste ~2x cu fata plata redevine palarie
     de cos de fum. `VOLCANIC_BLACK` peste crem;
  3. **umbra proprie lunga** la soare de 13° — vine din geometrie, nu din
     asset, si e singura variatie de valoare de pe corp: benzile orizontale
     pictate faceau piesa sa iasa vargata.

Buget: brief §6 cere `chimney_*` sub 600 tri fiecare, fiindca sunt ~40 pe
pista. `segments=9` + 7-8 inele de profil intra fix: 9*7*2 = 126 tri corp +
palarie. Ferestrele (doar pe `chimney_d`) sunt gauri INFUNDATE (cutii intrate
in corp cu slot intunecat), nu bool-uri — o gaura reala ar cere ca interiorul
sa fie modelat si ar dubla costul pentru ceva ce se vede de la 15 m ca o pata
intunecata. Vezi memoria `decor-manual-din-cod`: gaura pictata bate gaura
reala la scara asta.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_cappadocia_tuff.py
"""

import math
from mathutils import Matrix, Vector

# AO: hornurile sunt corpuri mari si convexe, deci ocluzia geometrica e aproape
# nula — gradientul vertical face toata munca (baza infipta in pamant, varful
# in soare). `dist` mare fiindca piesele au 10-18 m.
AO_CHIMNEY = dict(samples=20, dist=8.0, gradient="vertical",
                  low=0.42, high=1.00, power=0.85, floor=0.14)
AO_CLIFF = dict(samples=18, dist=10.0, gradient="vertical",
                low=0.46, high=1.00, power=0.80, floor=0.16)
AO_FACADE = dict(samples=26, dist=5.0, gradient="vertical",
                 low=0.40, high=1.00, power=0.90, floor=0.12)

TUFF = CORAL_SAND          # crem de tuf in soare — dominanta pistei
TUFF_MID = SAND_MID        # tuf mediu, banda de variatie de valoare
TUFF_SH = SAND_SHADOW      # tuf umbrit, la baza si sub consola palariei
CAP = VOLCANIC_BLACK       # palaria de bazalt
BAND_RED = TILE_TERRACOTTA  # banda lata rosie (Valea Rosie)
BAND_RUST = LARCH_RUST     # banda ingusta ruginie
HOLE = ROCK_DARK           # ferestre si usi sapate (gaura "pictata")

# Exponentul siluetei conului. >1 = raza tine latimea jos si cedeaza spre varf
# (con continuu); <1 = fus cu piciorul evazat, adica silueta de cos industrial.
# Constanta fiindca `build_chimney` are nevoie de ea si ca sa aseze ferestrele
# pe suprafata: scrisa de doua ori, se desincronizeaza.
CONE_EXP = 1.35
DOOR_WOOD = WOOD


def chimney_profile(height, r_base, r_neck, seed, steps=7):
    """Profilul (raza, z) al gatului: CON continuu, cu paliere de eroziune.

    Exponentul e ce decide daca piesa citeste "horn de zana" sau "cos de
    fabrica", si prima versiune l-a pus pe dos. Cu `t ** 0.62` raza pierde 25%
    in primul sfert de inaltime si pe urma sta aproape pe loc — masurat pe
    chimney_b: 100% -> 74% -> 60% -> 48% -> 38%. Adica un FUS aproape cilindric
    cu piciorul evazat, exact silueta unui cos industrial. Critica oarba a
    numit-o din prima ("machined smokestacks") si avea dreptate: retusul de
    culoare din prima runda a rezolvat nuanta si a lasat silueta neatinsa.

    Referinta (v3, grupul B) are conuri care se subtiaza CONTINUU, ca niste
    corturi: fara umar la baza si fara portiune dreapta la mijloc. Aia cere
    exponent SUPRAUNITAR — raza tine latimea jos si cedeaza tot mai repede spre
    varf. Cu 1.35: 100% -> 90% -> 76% -> 58% -> 38%, deci fiecare sfert ia mai
    mult decat cel de dinainte si conturul e o curba, nu o linie franta.

    Palierele raman (tuful chiar se erodeaza in trepte), dar la jumatate din
    amplitudine: pe un con continuu perturbatia de +-13% redevenea o serie de
    umeri orizontali — al doilea motiv pentru care piesa iesea in dungi.
    """
    rand = _lcg(seed)
    prof = []
    for i in range(steps):
        t = i / (steps - 1.0)
        r = r_base + (r_neck - r_base) * (t ** CONE_EXP)
        r *= 1.0 + (rand() - 0.5) * 0.065     # paliere de eroziune, discrete
        prof.append((r, height * t))
    return prof


def basalt_cap(b, z, r_neck, r_cap, thickness, seed=0, segments=9):
    """Palaria de bazalt: con TURTIT asezat pe gat, cu consola mica.

    A treia cauza pentru care piesa citea industrial. Consola exista in
    natura, dar prima versiune o umflase la 2.05x raza gatului si o pusese ca
    DISC cu fata dreapta — adica fix profilul unei palarii de cos de fum. Pe
    referinta palaria sta pe con ca o caciula: iese putin (1.2-1.4x), si e
    ascutita, nu plata, deci varful continua linia conului in loc s-o taie.

    De-aia inelul de sus se stange acum la 0.30 din raza (era 0.74, adica un
    disc cu buza teszita) si consola vine din apelanti, nu de aici.
    `chimney_mushroom` isi pastreaza palaria enorma: acolo consola larga e
    chiar subiectul piesei (Pasabag), nu un accident.
    """
    rand = _lcg(seed + 91)
    wob = 1.0 + (rand() - 0.5) * 0.10
    # buza: iese peste gat, dar putin — inel scurt, nu disc
    b.frustum((0.0, 0.0, z - thickness * 0.22), r_neck * 1.02, r_cap * wob,
              thickness * 0.44, CAP, segments=segments)
    # corpul palariei: se stange spre varf, ca sa continue conul
    b.frustum((0.0, 0.0, z + thickness * 0.30), r_cap * wob, r_cap * 0.30 * wob,
              thickness * 0.85, CAP, segments=segments)
    return r_cap * wob


def carve_window(b, cx, cy, cz, w, h, depth, normal, slot=HOLE):
    """Fereastra "sapata": cutie intrata in corp, tag-uita intunecat.

    NU e o gaura reala. La 15 m distanta (cea mai apropiata pozitie in care
    hornurile de langa banda se vad — brief §2.0) o cavitate de 0.6 m citeste
    identic cu o pata intunecata cu buza in umbra, si costa 12 tri in loc de
    ~90 plus un interior.
    """
    n = Vector(normal).normalized()
    ang = math.atan2(n.y, n.x)
    rot = Matrix.Rotation(ang, 3, "Z")
    c = Vector((cx, cy, cz)) - n * (depth * 0.35)
    b.box(tuple(c), (depth, w, h), slot, rotation=rot)
    # buza de sus: praguri de sapare, prind lumina razanta de zori
    lip = Vector((cx, cy, cz + h * 0.5 + 0.06)) + n * 0.05
    b.box(tuple(lip), (depth * 0.9, w * 1.12, 0.10), TUFF_SH, rotation=rot)


def build_chimney(variant):
    """Cele patru hornuri de baza. Variantele difera prin PROPORTIE, nu prin
    detaliu: brief §2.0 cere 10-18 m langa banda, iar la vitezele de acolo
    silueta e singurul lucru care se citeste."""
    b = Builder()
    # (inaltime, raza baza, raza gat, grosime palarie, seed)
    # Bazele s-au LATIT: la 2*r/H = 0.30-0.44 piesele erau turnuri, iar pe
    # referinta conurile sunt indesate (corturi). Inaltimea ramane in
    # 10-18 m ceruta de brief §2.0 si de plafonul derivat din camera.
    spec = [
        (10.5, 3.35, 0.62, 1.05, 7),      # a — scund si indesat
        (13.8, 3.65, 0.58, 1.00, 23),     # b — clasicul zvelt
        (16.4, 4.30, 0.66, 1.20, 41),     # c — inalt, palarie grea
        (12.6, 3.80, 0.72, 1.05, 59),     # d — locuit, cu ferestre
    ][variant]
    H, R_BASE, R_NECK, CAP_T, SEED = spec

    prof = chimney_profile(H, R_BASE, R_NECK, SEED)
    faces = b.revolve(prof, TUFF, segments=9)

    # O SINGURA calcare de valoare, jos, si fara muchie orizontala.
    #
    # Prima versiune punea doua benzi (sub 0.22H umbrit, intre 0.45H si 0.63H
    # mediu). Pe un fus aproape drept aia dadea exact ce a numit critica:
    # dungi orizontale echidistante, adica santier, nu geologie. Nici retusul
    # de nuanta din runda 1 n-avea cum s-o repare — problema era ca sunt
    # DUNGI, nu ce culoare au dungile.
    #
    # Ramane doar praful de la baza, si acela taiat pe o cota NEregulata
    # (variaza cu unghiul in jurul axei) ca sa nu iasa un inel perfect. Banda
    # de mijloc dispare complet: pe un con continuu variatia de valoare o face
    # deja lumina razanta de 13°, care e chiar identitatea POI-ului.
    # Praga NEregulata pe circumferinta: `revolve` da inele de fete, deci un
    # prag CONSTANT coloreaza un inel intreg si iese exact dunga pe care o
    # eliminam. O armonica pe unghi rupe marginea si se citeste ca poala de
    # praf. A doua armonica s-a incercat si s-a scos: cu amplitudine mare
    # pragul sarea peste un inel intreg pe un sector, si in loc de dunga iesea
    # un PETIC dreptunghiular pe fata conului — mai rau decat banda.
    b.retag(faces, TUFF_SH,
            where=lambda c, n, h=H: c.z < h * (0.15 + 0.055 * math.sin(
                math.atan2(c.y, c.x) * 3.0)))

    # Palarie stransa: 1.30x gatul, nu 2.05x (vezi `basalt_cap`).
    r_cap = basalt_cap(b, H, R_NECK, R_NECK * 1.30, CAP_T, seed=SEED)
    # Inelul de umbra de sub consola a fost SCOS. Era un cilindru de 1 m de
    # TUFF_SH lipit sub palarie, adica inca o dunga orizontala — si cea mai
    # vizibila, fiind pe muchia de silueta. Cu consola stransa la 1.30x nu mai
    # are ce sa umbreasca: ocluzia de sub buza o face acum AO_CHIMNEY.

    if variant == 3:
        # hornul locuit: usa la baza + trei ferestre pe fata (spre +Y = -Z Godot)
        _ = r_cap
        carve_window(b, 0.0, R_BASE * 0.90, 1.05, 1.05, 1.85, 0.55, (0, 1, 0),
                     slot=DOOR_WOOD)
        for (fz, fa, fw) in ((4.4, 8.0, 0.62), (6.9, -34.0, 0.55),
                             (8.8, 26.0, 0.50)):
            t = fz / H
            # Exponentul TREBUIE sa fie cel din `chimney_profile`: era scris de
            # mana ca 0.62 si, dupa trecerea la con, ferestrele ar fi plutit
            # langa piesa (la 8.8 m raza reala e cu ~0.5 m mai mare).
            r = (R_BASE + (R_NECK - R_BASE) * (t ** CONE_EXP)) * 0.94
            a = math.radians(90.0 + fa)
            carve_window(b, r * math.cos(a), r * math.sin(a), fz,
                         fw, fw * 1.25, 0.45, (math.cos(a), math.sin(a), 0))

    return b.to_object("Chimney_" + "ABCD"[variant])


def build_chimney_mushroom():
    """Hornul-ciuperca: gatul ROADE pana aproape de nimic sub o palarie enorma.

    Proportia e tot: palaria are 3.1x raza gatului. Sub 2.5x arata ca un horn
    obisnuit cu capac; masurat pe randarea de control, 2.4x inca citea drept
    "capac", nu drept palarie de ciuperca. Piesa asta e "citatul" din Pasabag pe care il pui langa drum ca
    reper de POI.
    """
    b = Builder()
    # baza latita ca la restul familiei (vezi `build_chimney`): ciuperca statea
    # pe 2.15 m si iesea un pai cu palarie, langa conuri de 3.3-4.3 m
    H, R_BASE, R_NECK = 11.2, 3.20, 0.62
    prof = chimney_profile(H, R_BASE, R_NECK, 103, steps=8)
    # gatul se stranguleaza suplimentar in treimea de sus (eroziunea reala)
    prof = [(r * (0.80 if 0.62 * H < z < 0.93 * H else 1.0), z) for r, z in prof]
    faces = b.revolve(prof, TUFF, segments=9)
    # aceleasi doua motive ca la `build_chimney`: fara banda de mijloc, si
    # praful de la baza taiat pe o cota neregulata (ciuperca e cea mai numeroasa
    # piesa de langa banda, deci dungile ei se vedeau cel mai des)
    b.retag(faces, TUFF_SH,
            where=lambda c, n, h=H: c.z < h * (0.14 + 0.050 * math.sin(
                math.atan2(c.y, c.x) * 3.0 + 0.9)))
    basalt_cap(b, H, R_NECK * 0.80, R_NECK * 3.10, 1.55, seed=103, segments=10)
    return b.to_object("Chimney_Mushroom")


def build_chimney_triple():
    """Trei hornuri crescuti din acelasi soclu — silueta din Valea Calugarilor.

    Un soclu comun (nu trei piese separate): asa se planteaza intr-un singur
    world_prop si coliziunea e una singura. Inaltimile sunt DIFERITE si
    neregulate, altfel citeste ca o furculita.
    """
    b = Builder()
    # soclul comun, o movila joasa
    # Soclul s-a LATIT odata cu gaturile: cu bazele conice de 2.1-2.7 m raza,
    # cel mai departat ajunge la x=+5.7, deci pe 8 m latime picioarele ar fi
    # atarnat in aer. Masurat pe extentele reale ale celor trei, nu pe AABB.
    b.rock((0.0, 0.0, 0.0), (12.4, 8.4, 3.2), TUFF_SH, seed=311, segments=9,
           rings=3, flat_top=True, taper=0.30)

    stems = [(-2.60, -0.60, 12.8, 2.45, 0.48, 0.95, 17),
             (1.35, 1.05, 15.6, 2.70, 0.52, 1.05, 53),
             (3.60, -1.60, 9.4, 2.10, 0.44, 0.82, 89)]
    for (x, y, h, rb, rn, ct, seed) in stems:
        prof = chimney_profile(h, rb, rn, seed)
        base_z = 2.15
        faces = b.revolve(prof, TUFF, segments=8, origin=(x, y, base_z))
        # fara banda de mijloc: aceeasi dunga orizontala ca la `build_chimney`
        # palaria, mutata pe axa fiecarui gat
        rand = _lcg(seed + 91)
        wob = 1.0 + (rand() - 0.5) * 0.10
        # aceeasi proportie ca la `basalt_cap`: consola stransa, varf ascutit
        r_cap = rn * 1.30 * wob
        b.frustum((x, y, base_z + h - ct * 0.22), rn * 1.02, r_cap, ct * 0.44,
                  CAP, segments=8)
        b.frustum((x, y, base_z + h + ct * 0.30), r_cap, r_cap * 0.30, ct * 0.85,
                  CAP, segments=8)
    return b.to_object("Chimney_Triple")


def build_cliff_band_module():
    """Felie de faleza in BENZI, 20 m lungime — modul de cornisa si de canion.

    Benzile roz-rosu sunt cerinta explicita din brief §5.1: "benzile in textura
    de clasa, nu in geometrie". Aici sunt totusi geometrie SUBTIRE (straturi de
    0.8-1.6 m), din doua motive:
      - modulul e folosit si acolo unde nu ajunge clasa `tuff_banded` (capete,
        colturi), si trebuie sa citeasca la fel;
      - `retag` face benzile pe fetele EXISTENTE ale straturilor, deci costul e
        zero peste geometria oricum necesara.
    Ordinea benzilor e cea reala din Valea Rosie: crem jos, rosu lat la mijloc,
    ruginiu ingust, crem sus (partea de sub platou).

    `origin="base_axis"`: modulele se insiruie cap la cap pe X, deci bbox-ul
    NU se recentreaza (memoria `chongqing-assets-kit`, piesele modulare).
    """
    b = Builder()
    L, D = 20.0, 4.5
    # straturi: (grosime, slot, retragere fata de cel de dedesubt)
    layers = [(1.6, TUFF_SH, 0.00), (1.2, BAND_RED, 0.18), (0.8, BAND_RUST, 0.30),
              (1.5, BAND_RED, 0.42), (1.1, TUFF_MID, 0.66), (1.9, TUFF, 0.82),
              (1.4, BAND_RUST, 1.05), (2.2, TUFF, 1.20)]
    z = 0.0
    rand = _lcg(457)
    for (t, slot, back) in layers:
        d = D - back
        # fiecare strat e usor mai scurt si decalat -> profil erodat, nu scara
        jitter = (rand() - 0.5) * 0.35
        b.box((jitter, -back * 0.5, z + t * 0.5), (L, d, t), slot)
        z += t

    # buza de sus, in consola: ce se vede de pe cornisa privind in jos
    b.box((0.0, -1.20 * 0.5 + 0.15, z + 0.35), (L, D - 1.20, 0.70), TUFF)

    # moloz la baza — fusta care leaga faleza de fundul vaii
    for i in range(7):
        fx = -L * 0.5 + L * (rand() * 0.94 + 0.03)
        s = 0.55 + rand() * 0.85
        b.rock((fx, D * 0.5 + rand() * 0.8, 0.0), (s * 2.1, s * 1.7, s),
               TUFF_SH, seed=int(rand() * 900), segments=6, rings=3, taper=0.55)
    return b.to_object("Cliff_Band_Module")


def build_rock_church_facade():
    """Fatada de biserica rupestra: con de tuf cu portal sapat si cruce incizata.

    Piesa de POI, nu de statistica: se pune UNA pe pista (brief §1, Goreme).
    Portalul e un arc SAPAT (arcada in trepte, tag-uita intunecat), plus doua
    ferestre ogivale si o cruce in relief negativ. Tot pe "gaura pictata" —
    interiorul nu exista, fiindca nu se intra in el.
    """
    b = Builder()
    H, R_BASE, R_NECK = 14.0, 4.20, 1.55
    prof = chimney_profile(H, R_BASE, R_NECK, 601, steps=8)
    faces = b.revolve(prof, TUFF, segments=11)
    # idem pe fatada bisericii: e tot un con de tuf, langa drum
    b.retag(faces, TUFF_SH,
            where=lambda c, n, h=H: c.z < h * (0.13 + 0.045 * math.sin(
                math.atan2(c.y, c.x) * 3.0 + 2.4)))
    basalt_cap(b, H, R_NECK, R_NECK * 1.95, 1.45, seed=601, segments=10)

    y = R_BASE * 0.86
    # portalul: golul + arcada in trepte deasupra lui
    b.box((0.0, y - 0.35, 2.05), (0.90, 2.30, 4.10), HOLE)
    for i, (w, dz) in enumerate(((2.55, 4.20), (2.15, 4.62), (1.60, 4.96))):
        b.box((0.0, y - 0.10, dz), (0.55, w, 0.34), TUFF_SH if i else TUFF_MID)
    # doua ferestre ogivale, flancand portalul
    for sx in (-1.0, 1.0):
        carve_window(b, sx * 2.05, y * 0.92, 6.35, 0.68, 1.15, 0.45, (0, 1, 0))
    # crucea incizata deasupra portalului (doua bare intrate in corp)
    b.box((0.0, y - 0.12, 8.30), (0.30, 0.28, 1.60), HOLE)
    b.box((0.0, y - 0.12, 8.62), (0.30, 1.20, 0.28), HOLE)
    # pragul de intrare, iesit in fata
    b.box((0.0, y + 0.30, 0.12), (1.10, 2.80, 0.24), TUFF_MID)
    return b.to_object("Rock_Church_Facade")


clear_built()

results = []


def emit(obj, path, ao, origin="base", bevel=0.05):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "cappadocia/" + path)
    results.append((path, st["tris"], sz / 1024.0))


for v in range(4):
    emit(build_chimney(v), "rocks/chimney_%s.glb" % "abcd"[v], AO_CHIMNEY)
emit(build_chimney_mushroom(), "rocks/chimney_mushroom.glb", AO_CHIMNEY)
emit(build_chimney_triple(), "rocks/chimney_triple.glb", AO_CHIMNEY)
emit(build_cliff_band_module(), "rocks/cliff_band_module.glb", AO_CLIFF,
     origin="base_axis", bevel=0.06)
emit(build_rock_church_facade(), "rocks/rock_church_facade.glb", AO_FACADE)

print()
for path, tris, kb in results:
    print("%-40s tris=%6d %8.1f kB" % (path, tris, kb))
print("TOTAL tuff kit A: %d tris" % sum(t for _, t, _ in results))
