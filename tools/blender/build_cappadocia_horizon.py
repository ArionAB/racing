"""Cappadocia — FUNDAL (plansa, grupul 12; brief §5.4 `horizon_class`).

  cappadocia/rocks/uchisar_castle.glb  stanca-castel de fundal, 60 m, la 200+ m
  cappadocia/rocks/erciyes.glb         silueta vulcanului cu zapada
  cappadocia/rocks/balloon_far.glb     balon simplificat pentru MultiMesh

**Cotele de fundal sunt LEGATE, nu alese** (memoria `efecte-de-fundal-cote-legate`):
inelul de fundal < `fog_end` < `FAR_PLANE` (380 m). Brief §4 pune `fog_end` la
~300 m, deci:
  - `uchisar_castle` sta la **200-250 m** — in ceata, dar inca deasupra ei ca
    silueta; la 60 m inaltime si 250 m distanta subintinde 13.5°, adica ocupa
    o cincime din inaltimea cadrului. Se vede.
  - `erciyes` sta la **290-300 m**, chiar sub `fog_end`: e ultimul lucru
    vizibil, si trebuie sa fie ULTIMUL. Mai departe ar disparea complet
    (`horizon_class` gol pastreaza atlasul, dar nu inventeaza vizibilitate).
  - dincolo de 300 m nu se pune nimic. Un asset la 320 m e munca aruncata.

Piesele de fundal sunt **siluete**, deci regula lor e inversa fata de restul
kitului: zero detaliu care nu se vede in profil. Ce conteaza e **profilul**:
linia de creasta si linia zapezii. Alea se citesc.

**Numarul de segmente NU se alege "mic fiindca e departe".** Comentariul de
aici a spus pana in runda 34 ca "la 300 m un segment subintinde sub un pixel",
si de la cifra aia au iesit 12 segmente si UV-uri colapsate. Cifra e falsa, si
a costat 13 runde de reglaje de lumina pe un obiect care nu avea geometrie.
Socoteala, cu camera reala (ChaseCamera.BASE_FOV = 68 VERTICAL, 1280x720, deci
fov orizontal 100.3 grade => 12.76 px/grad pe orizontala, 10.59 px/grad pe
verticala):

    erciyes, H=180 R=145, la scara 0.95-1.35 si 190-290 m (`horizon_rings`)
      inaltime pe ecran ..... 375-480 px din 720   (52-67% din cadru)
      UN segment din 12 ..... 16.9-23.8 grade = 216-304 PIXELI

Nu sub un pixel: **peste doua sute**. Un segment e a 12-a parte dintr-un con cu
raza de 145 m, nu un detaliu mic pe ceva departat.

Criteriul corect e eroarea de SILUETA (sagitta): un con cu n laturi se abate de
la cerc cu R*(1-cos(pi/n)). La 12 segmente asta e 18-20 px de contur zimtat; la
32 de segmente scade sub 3 px, adica sub pragul vizibil. Al doilea criteriu e
UMBRIREA: cu 12 segmente flancul vizibil are 6 fatete, deci gradientul de la
lumina la umbra are 6 trepte de 30 grade — plati. La 32 sunt 16 trepte de 11
grade.

DAR — si de asta erciyes.glb n-a fost regenerat in runda 34 — geometria nu e
constrangerea activa pe pista asta. Masurat cu tools/ProbeMunte.tscn din cadrul
de sofer la POI B: TOTI pixelii de Erciyes din cadru sunt intre 260 si 420 m,
adica 87-100% inghititi de ceata (`fog_end` 300), iar 24 din 254 de raze cad
dincolo de ChaseCamera.FAR_PLANE (380 m). Vezi memoria
`efecte-de-fundal-cote-legate`: inel < fog_end < FAR_PLANE. Pe Cappadocia lantul
e rupt, si pana nu se repara, orice segment in plus se randeaza in aceeasi
culoare de ceata.

`balloon_far` e o piesa de **MultiMesh** (30-40 in vale + 10 sus, brief §5.4),
deci trebuie sa fie sub 100 tri: forma de balon fara cusaturi, fara cos, un
singur slot. La 80+ m, un balon e o pata colorata cu silueta de para.
**Atentie la oglindire:** instantele cu `scale.x = -1` sunt culled in MultiMesh
(memoria `multimesh-oglindire-culling`) — varietatea se face prin rotatie pe Z
si prin scara neuniforma pozitiva, nu prin oglindire.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_cappadocia_horizon.py
"""

import math
from mathutils import Matrix, Vector

# AO pe fundal: aproape plat. La 250 m ocluzia geometrica nu se citeste, dar
# gradientul vertical inca ajuta (baza in ceata, varful in lumina).
AO_FAR = dict(samples=8, dist=25.0, gradient="vertical",
              low=0.52, high=1.00, power=0.75, floor=0.24)
AO_PEAK = dict(samples=8, dist=40.0, gradient="vertical",
               low=0.56, high=1.00, power=0.70, floor=0.28)
AO_BALLOON = dict(samples=8, dist=6.0, gradient="vertical",
                  low=0.68, high=1.00, power=0.7, floor=0.40)

TUFF = CORAL_SAND
TUFF_MID = SAND_MID
TUFF_SH = SAND_SHADOW
CAP = VOLCANIC_BLACK
HOLE = ROCK_DARK
BAND_RED = TILE_TERRACOTTA
BAND_RUST = LARCH_RUST
GREY = MARBLE_GREY         # roca inalta a vulcanului
SNOW = FOAM_WHITE
B_RED, B_BLUE, B_YELLOW = CAR_RED, CAR_BLUE, CAR_YELLOW


def build_uchisar_castle():
    """Stanca-castel de la Uchisar: 60 m, gaurita ca un fagure.

    ATENTIE (runda 34): piesa asta e construita si exportata, dar **nu e
    instantiata nicaieri**. Zero referinte la `uchisar_castle` in .gd/.tscn/.tres
    din tot repo-ul: nu e in `horizon_picks` (alea cer doar "Erciyes"), nu e in
    DecorManual-ul din Track13. 3.986 de triunghiuri care nu ajung pe ecran.
    Ori se aseaza pe platou (brief §5.4 o cere ca ecou de fundal al gimmick-ului
    `hollow_rock`), ori se scoate din build.

    Socoteala ei de rezolutie, spre deosebire de cea a lui erciyes, e CORECTA:
    57 m la 200-250 m subintinde 12.8-15.9 grade = 136-168 px = 19-23% din
    inaltimea cadrului, adica exact "o cincime" cat zice comentariul de sus.
    Cu segments=10/9/9 pe raza 25 m, un segment are 46-51 px — mare, dar de
    zece ori mai mic decat cei 216-304 px ai lui erciyes. Defectul de la linia
    20 NU se repeta aici.

    E ecoul de fundal al gimmick-ului (`hollow_rock`): jucatorul vede de pe
    platou o stanca IDENTICA ca tip la orizont, si intelege ca aia din care a
    iesit e acelasi lucru. De aia are aceeasi silueta de bloc cu varf tesit,
    doar mai inalta si mai zvelta.

    Fagurele e ce o face sa nu fie o stanca oarecare: ~40 de gauri, dar toate
    ca `box` intrate in corp (nu gauri reale) — la 200 m sunt pete, si nici
    macar pete individuale, ci o TEXTURA de pete. 40 de cutii = 480 tri, si
    scapam de 40 de tunele.
    """
    b = Builder()
    H = 60.0
    # corpul: trei corpuri de stanca suprapuse, tot mai inguste — silueta de
    # castel natural, cu umeri, nu con
    f1 = b.rock((0.0, 0.0, 0.0), (44.0, 38.0, 26.0), TUFF, seed=1409,
                segments=10, rings=4, flat_top=True, taper=0.22)
    f2 = b.rock((2.5, -1.5, 22.0), (30.0, 26.0, 22.0), TUFF, seed=1511,
                segments=9, rings=4, flat_top=True, taper=0.30)
    f3 = b.rock((-1.0, 2.0, 40.0), (18.0, 16.0, 20.0), TUFF, seed=1613,
                segments=9, rings=4, flat_top=True, taper=0.45)
    b.retag(f3, TUFF_MID, where="up")

    # Benzile de culoare pe inaltime, ca falezele — ca `retag` pe fetele
    # EXISTENTE ale celor trei corpuri, nu ca lespezi noi. Prima versiune le
    # facea din `box`-uri de latimea corpului: la randarea de control ieseau
    # patru placi care depaseau silueta, adica o PAGODA, nu o stanca. Lectia e
    # aceeasi ca la hornuri: variatia de valoare nu are voie sa adauge volum.
    allf = list(f1) + list(f2) + list(f3)
    for (z0, z1, slot) in ((0.0, 7.0, TUFF_SH), (10.0, 16.0, BAND_RED),
                           (25.0, 31.0, BAND_RUST), (43.0, 49.0, TUFF_MID)):
        b.retag(allf, slot, where=lambda c, n, z0=z0, z1=z1: z0 <= c.z < z1)
    rand = _lcg(1721)

    # fagurele: gauri pe toata fata, mai dese la mijloc
    for k in range(46):
        a = 2.0 * math.pi * rand()
        t = rand()
        z = 6.0 + 46.0 * t
        # raza aproximativa la cota z (corpul se ingusteaza)
        # raza corpului la cota z: cele trei stanci suprapuse se ingusteaza
        # in trepte, deci se interpoleaza pe ele, nu pe o formula globala
        if z < 24.0:
            r = 20.5 - 3.0 * (z / 24.0)
        elif z < 42.0:
            r = 14.0 - 3.5 * ((z - 24.0) / 18.0)
        else:
            r = 8.6 - 3.0 * ((z - 42.0) / 18.0)
        s = 0.9 + rand() * 1.5
        b.box((r * math.cos(a), r * math.sin(a) * 0.88, z),
              (2.2, s, s * 1.25), HOLE, rotation=Matrix.Rotation(a, 3, "Z"))
    # varful: o creasta de blocuri, ca sa nu fie o cupola neteda
    for k in range(5):
        a = 2.0 * math.pi * k / 5.0 + 0.4
        b.box((3.2 * math.cos(a), 3.2 * math.sin(a), H - 5.5),
              (3.8, 3.2, 5.0), TUFF_MID, rotation=Matrix.Rotation(a, 3, "Z"))
    # moloz la baza, care o leaga de platou
    for k in range(12):
        a = 2.0 * math.pi * rand()
        s = 1.8 + rand() * 3.2
        b.rock((22.0 * math.cos(a), 19.0 * math.sin(a), 0.0),
               (s * 2.2, s * 1.9, s), TUFF_SH, seed=int(rand() * 900),
               segments=5, rings=3, taper=0.5)
    return b.to_object("Uchisar_Castle")


def build_erciyes():
    """Erciyes: stratovulcan de 3.900 m, redus la o silueta de ~180 m.

    Scara e o MINCIUNA deliberata si necesara: la 300 m distanta, un munte de
    3.900 m ar subintinde 85° — ar umple tot cerul si ar arata ca un perete.
    La 180 m inaltime subintinde 31°, adica exact "munte mare la orizont".
    Aceeasi decizie ca la muntele din Alpi (memoria `munte-flanc-nu-fundal`),
    doar ca acolo era flanc si aici e fundal curat.

    Trei etaje de culoare, in ordinea reala: poale intunecate (padure/lava
    veche), corp gri de roca, calota de zapada. Linia zapezii e la 68% din
    inaltime — sub 60% muntele arata alpin (alta lume), peste 80% pare o
    caciula.
    """
    b = Builder()
    H = 180.0
    R = 145.0
    SNOW_LINE = 0.68
    # conul, cu profil concav (stratovulcan: poale largi, varf abrupt)
    prof = []
    rand = _lcg(1907)
    n = 9
    for i in range(n + 1):
        t = i / n
        r = R * ((1.0 - t) ** 1.35)
        r *= 1.0 + (rand() - 0.5) * 0.06
        prof.append((r, H * t))
    faces = b.revolve(prof, GREY, segments=12)
    # poalele intunecate si calota
    b.retag(faces, TUFF_SH, where=lambda c, n: c.z < H * 0.20)
    b.retag(faces, SNOW, where=lambda c, n: c.z > H * SNOW_LINE)
    # limbi de zapada care coboara pe vai — asta rupe linia perfecta de zapada
    # si e singurul detaliu care merita triunghiuri la distanta asta
    for k in range(7):
        a = 2.0 * math.pi * k / 7.0 + 0.3
        z0 = H * (SNOW_LINE - 0.02)
        z1 = H * (SNOW_LINE - 0.16 - rand() * 0.08)
        r0 = R * ((1.0 - z0 / H) ** 1.35)
        r1 = R * ((1.0 - z1 / H) ** 1.35)
        b.taper_sweep([(r0 * math.cos(a), r0 * math.sin(a), z0),
                       (r1 * math.cos(a), r1 * math.sin(a), z1)],
                      [4.5, 0.0], SNOW, segments=5)
    # craterul: o scobitura in varf (se vede doar ca o tesitura de la distanta)
    b.frustum((0.0, 0.0, H - 2.5), 9.0, 12.5, 5.0, GREY, segments=10)
    # un varf secundar, ca silueta sa nu fie perfect simetrica
    b.revolve([(38.0, 0.0), (24.0, 22.0), (10.0, 45.0), (0.0, 58.0)], GREY,
              segments=9, origin=(R * 0.52, -R * 0.30, 0.0))
    return b.to_object("Erciyes")


def build_balloon_far():
    """Balonul de fundal pentru MultiMesh: sub 100 tri, un singur corp.

    Fara cusaturi, fara cos (la 80+ m cosul e sub un pixel), fara inel de gura.
    8 segmente si 5 inele — silueta de para se pastreaza, si e tot ce se vede.
    Culoarea vine din instantiere, prin `retag`-ul de aici pe trei fasii; in
    MultiMesh varietatea reala se face din rotatie si scara (NU din oglindire:
    `scale.x = -1` e culled, vezi docstring-ul modulului).
    """
    b = Builder()
    H, R = 11.0, 4.3
    prof = []
    n = 5
    for i in range(n + 1):
        t = i / n
        if t < 0.60:
            u = t / 0.60
            r = 0.75 + (R - 0.75) * math.sin(u * math.pi * 0.5) ** 0.85
        else:
            u = (t - 0.60) / 0.40
            r = R * math.cos(u * math.pi * 0.5) ** 0.62
        prof.append((max(r, 0.0), H * t))
    faces = b.revolve(prof, B_RED, segments=8, cap_bottom=False)
    b.retag(faces, FOAM_WHITE, where=lambda c, nn: H * 0.30 < c.z < H * 0.55)
    b.retag(faces, B_BLUE, where=lambda c, nn: c.z < H * 0.22)
    # cosul: o singura cutie, 12 tri. Sub el nu se mai coboara.
    b.box((0.0, 0.0, -1.35), (1.5, 1.5, 1.4), DRY_VEGETATION)
    return b.to_object("Balloon_Far")


clear_built()

results = []


def emit(obj, path, ao, origin="base", bevel=0.10):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "cappadocia/" + path)
    results.append((path, st["tris"], sz / 1024.0))


emit(build_uchisar_castle(), "rocks/uchisar_castle.glb", AO_FAR, bevel=0.14)
emit(build_erciyes(), "rocks/erciyes.glb", AO_PEAK, bevel=0.25)
emit(build_balloon_far(), "rocks/balloon_far.glb", AO_BALLOON,
     origin="base_axis", bevel=0.03)

print()
for path, tris, kb in results:
    print("%-42s tris=%6d %8.1f kB" % (path, tris, kb))
print("TOTAL fundal: %d tris" % sum(t for _, t, _ in results))
