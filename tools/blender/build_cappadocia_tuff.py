"""Cappadocia — TUFF KIT A: formatiunile de piatra (plansa, grupul 9).

  cappadocia/rocks/chimney_{a,b,c,d}.glb   hornuri de zana, 10-18 m, palarie de bazalt
  cappadocia/rocks/chimney_mushroom.glb    hornul-ciuperca (palarie mult mai lata ca gatul)
  cappadocia/rocks/chimney_triple.glb      hornul cu trei palarii (Pasabag)
  cappadocia/rocks/cliff_band_module.glb   felie de faleza in benzi roz-rosu, 20 m
  cappadocia/rocks/rock_church_facade.glb  fatada de biserica rupestra, sapata in con

De ce hornul NU e un simplu con (brief §0.1, 55% din pista e geologie de tuf):
silueta reala are TREI parti, si toate trei se vad de la 40 m —

  1. **gatul** care se subtiaza neuniform (tuful se erodeaza in trepte, nu
     liniar), deci `revolve` cu un profil in care raza scade cu paliere;
  2. **palaria de bazalt**, mereu MAI LATA decat gatul de sub ea si cu buza
     care iese in consola — asta e ce face conul sa citeasca drept "horn de
     zana" si nu drept "movila de nisip". `VOLCANIC_BLACK` peste crem;
  3. **umbra proprie lunga** la soare de 13° — vine din geometrie, nu din
     asset, dar de-aia gatul e inalt si subtire.

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
DOOR_WOOD = WOOD


def chimney_profile(height, r_base, r_neck, seed, steps=5):
    """Profilul (raza, z) al gatului: o SCARA CRESTATA, nu un taper neted.

    Runda 2 a picat aici la trei critici din patru, in aceleasi cuvinte:
    taperul neted cu jitter de +-6.5% pe raza e INVIZIBIL la 40 m (masurat:
    orice perturbatie sub ~10% dispare in silueta). Un strat de tuf se citeste
    doar daca arunca propria linie de umbra, adica daca are o fata de sus
    ORIZONTALA care iese in consola peste stratul de dedesubt.

    Deci profilul e construit din `steps` segmente stivuite, fiecare cu 8-12%
    mai ingust decat cel de sub el. Fiecare imbinare emite DOUA inele la
    ACEEASI cota: raza larga, apoi raza ingusta. Perechea aia nu e o risipa de
    geometrie — e exact fata orizontala tare de 0.30 m adancime (diferenta de
    raza) pe care cade lumina razanta de zori. `revolve` interpoleaza intre
    inele, deci fara perechea la aceeasi cota treapta redevine o tesitura.

    Nu se tesesc buzele: o consola tesita citeste tot ca taper (capcana rundei
    17 — detaliul care nu taie silueta nu exista).
    """
    rand = _lcg(seed)
    # Buza are adancime FIXA de 0.30 m (cifra din verdicte). Restul ingustarii
    # o face peretele segmentului, ca profilul sa ajunga totusi la `r_neck`:
    # din caderea totala de raza, `steps-1` buze iau 0.30 m fiecare, iar ce
    # ramane se imparte pe pereti. Daca buzele ar lua tot, gatul ar iesi gros.
    LIP = 0.30
    drop = r_base - r_neck
    lip_total = LIP * (steps - 1)
    # peretii preiau restul; daca buzele depasesc caderea totala, hornul e prea
    # scurt pentru 5 trepte de 0.30 — atunci se reduce numarul de trepte.
    while lip_total > drop * 0.80 and steps > 3:
        steps -= 1
        lip_total = LIP * (steps - 1)
    wall_drop = (drop - lip_total) / float(steps)

    prof = []
    r = r_base
    for i in range(steps):
        z0 = height * (i / float(steps))
        z1 = height * ((i + 1) / float(steps))
        # peretele: aproape vertical, cu o pierdere mica de raza; jitterul
        # determinist ramane doar ca sa nu fie toate treptele identice, dar el
        # NU mai poarta citirea — buza o poarta.
        wob = 1.0 + (rand() - 0.5) * 0.10
        r_top = max(r_neck, r - wall_drop * wob)
        prof.append((r, z0))
        prof.append((r_top, z1 - 0.001))
        if i < steps - 1:
            # BUZA: doua inele la ACEEASI cota => fata orizontala tare de
            # 0.30 m, in consola peste segmentul de deasupra.
            prof.append((r_top, z1))
            r = max(r_neck, r_top - LIP)
            prof.append((r, z1))
        else:
            r = r_top
    prof.append((r, height))
    return prof


def basalt_cap(b, z, r_neck, r_cap, thickness, seed=0, segments=9):
    """Palaria de bazalt: disc mai LAT decat gatul, cu buza in consola.

    Consola e tot ce conteaza: fara ea palaria citeste ca un varf de con si
    hornul dispare in "stanca oarecare". Doua inele (buza dreapta + varf
    tesit) ca sa se vada si din profil, si de sus.
    """
    rand = _lcg(seed + 91)
    wob = 1.0 + (rand() - 0.5) * 0.10
    # gatul subtire imediat sub palarie (partea protejata de eroziune)
    b.frustum((0.0, 0.0, z - thickness * 0.30), r_neck * 1.02, r_cap * wob,
              thickness * 0.60, CAP, segments=segments)
    # corpul palariei + tesitura de sus
    b.frustum((0.0, 0.0, z + thickness * 0.35), r_cap * wob, r_cap * 0.74 * wob,
              thickness * 0.75, CAP, segments=segments)
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
    spec = [
        (10.5, 2.30, 0.95, 1.25, 7),      # a — scund si indesat
        (13.8, 2.05, 0.78, 1.15, 23),     # b — clasicul zvelt
        (16.4, 2.60, 0.86, 1.45, 41),     # c — inalt, palarie grea
        (12.6, 2.45, 1.05, 1.20, 59),     # d — locuit, cu ferestre
    ][variant]
    H, R_BASE, R_NECK, CAP_T, SEED = spec

    prof = chimney_profile(H, R_BASE, R_NECK, SEED)
    faces = b.revolve(prof, TUFF, segments=9)

    # Variatie de valoare fara niciun triunghi: fetele de sub 35% din inaltime
    # primesc tuf umbrit, o banda de mijloc primeste tuf mediu. style_bible §4
    # ("fetele de sus decolorate") aplicat invers — jos e mai murdar.
    b.retag(faces, TUFF_SH, where=lambda c, n: c.z < H * 0.22)
    b.retag(faces, TUFF_MID, where=lambda c, n: H * 0.45 < c.z < H * 0.63)

    r_cap = basalt_cap(b, H, R_NECK, R_NECK * 2.05, CAP_T, seed=SEED)
    # umbra proprie sub consola: inel de tuf umbrit imediat sub palarie
    b.frustum((0.0, 0.0, H - 0.55), R_NECK * 1.06, R_NECK * 1.02, 1.0,
              TUFF_SH, segments=9)

    if variant == 3:
        # hornul locuit: usa la baza + trei ferestre pe fata (spre +Y = -Z Godot)
        _ = r_cap
        carve_window(b, 0.0, R_BASE * 0.90, 1.05, 1.05, 1.85, 0.55, (0, 1, 0),
                     slot=DOOR_WOOD)
        for (fz, fa, fw) in ((4.4, 8.0, 0.62), (6.9, -34.0, 0.55),
                             (8.8, 26.0, 0.50)):
            t = fz / H
            r = (R_BASE + (R_NECK - R_BASE) * (t ** 0.62)) * 0.94
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
    H, R_BASE, R_NECK = 11.2, 2.15, 0.62
    prof = chimney_profile(H, R_BASE, R_NECK, 103, steps=8)
    # gatul se stranguleaza suplimentar in treimea de sus (eroziunea reala)
    prof = [(r * (0.80 if 0.62 * H < z < 0.93 * H else 1.0), z) for r, z in prof]
    faces = b.revolve(prof, TUFF, segments=9)
    b.retag(faces, TUFF_SH, where=lambda c, n: c.z < H * 0.20)
    b.retag(faces, TUFF_MID, where=lambda c, n: H * 0.50 < c.z < H * 0.70)
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
    b.rock((0.0, 0.0, 0.0), (8.0, 6.2, 3.2), TUFF_SH, seed=311, segments=9,
           rings=3, flat_top=True, taper=0.30)

    stems = [(-1.85, -0.45, 12.8, 1.55, 0.62, 1.05, 17),
             (0.95, 0.75, 15.6, 1.70, 0.70, 1.20, 53),
             (2.55, -1.15, 9.4, 1.35, 0.58, 0.90, 89)]
    for (x, y, h, rb, rn, ct, seed) in stems:
        prof = chimney_profile(h, rb, rn, seed)
        base_z = 2.15
        faces = b.revolve(prof, TUFF, segments=8, origin=(x, y, base_z))
        b.retag(faces, TUFF_MID,
                where=lambda c, n, h=h, bz=base_z: bz + h * 0.45 < c.z < bz + h * 0.65)
        # palaria, mutata pe axa fiecarui gat
        rand = _lcg(seed + 91)
        wob = 1.0 + (rand() - 0.5) * 0.10
        r_cap = rn * 2.00 * wob
        b.frustum((x, y, base_z + h - ct * 0.30), rn * 1.02, r_cap, ct * 0.60,
                  CAP, segments=8)
        b.frustum((x, y, base_z + h + ct * 0.35), r_cap, r_cap * 0.74, ct * 0.75,
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
    b.retag(faces, TUFF_SH, where=lambda c, n: c.z < H * 0.18)
    b.retag(faces, TUFF_MID, where=lambda c, n: H * 0.42 < c.z < H * 0.58)
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
