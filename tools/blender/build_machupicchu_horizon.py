"""Machu Picchu — FUNDALUL (plansa de inventar, randul 11; brief §1.6).

  machupicchu/rocks/gorge_far_wall.glb        arc de 200 m x 80 m, concav spre drum
  machupicchu/rocks/machu_picchu_mountain.glb muntele de sud, 60 m x 150 m baza

DOUA PIESE, AMANDOUA SILUETE. Nu se vad niciodata de aproape: peretele
defileului sta la 200-250 m, in ceata, iar muntele la 150+ m. Ce conteaza e
CONTURUL pe cer si benzile mari de valoare — nu detaliul, care oricum se
topeste in mipmap si in ceata la distantele alea.

De aceea, si e o decizie nu o scapare:
  - fara terase pe munte (brief §1.6 o cere explicit: "nu se vede de aproape,
    plansa le are degeaba")
  - benzile de culoare sunt RETAG pe fete, zero triunghiuri (memoria
    `munte-flanc-nu-fundal`: trei etaje de culoare pe un corp unic)
  - `cast_shadow` se stinge la integrare (memoria `caster-departat-fura-umbra`:
    siluete mari si departate sting directionala)

BUGETUL E UN PLAFON, NU O TINTA. Un perete de 200 m randat cu 500 de
triunghiuri e un paravan neted, si exact asta a trebuit refacut la valul 1. La
200 m, ce se vede e silueta CRESTEI: ea are nevoie de varfuri destule ca sa nu
fie o linie dreapta, plus mase verticale care sa dea adancime defileului.

ORIGINE: `base_axis` la amandoua. XY-ul e construit intentionat necentrat
(arcul se infasoara in jurul drumului, muntele isi are varful decalat fata de
baza), deci `origin="base"` — care centreaza pe bbox — ar muta piesele fata de
punctul in care integrarea le aseaza. verify le cere cu `--origin=assembly`,
care verifica doar ca ANSAMBLUL atinge solul.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_machupicchu_horizon.py
"""

import math
from mathutils import Matrix, Vector

# `dist` se scaleaza CU PIESA: pe un perete de 80 m o raza de raycast de 5 m
# n-ar gasi nimic de ocluzat si AO-ul ar iesi constant 1.0 — adica exact
# "prop-ul plat" din docs/blender_export.md §2. `samples` scade in schimb:
# piesele astea au multe varfuri si AO-ul e oricum o masa mare, nu detaliu.
AO_FAR = dict(samples=10, dist=42.0, gradient="vertical",
              low=0.46, high=1.00, power=0.82, floor=0.18)
AO_PEAK = dict(samples=10, dist=34.0, gradient="vertical",
               low=0.44, high=1.00, power=0.85, floor=0.16)

FOREST = TROPICAL_GREEN      # padure de nori pe flancuri
FOREST_DARK = LOG_DARK       # umbra adanca de padure (fetele dinspre umbra)
SCRUB = CACTUS_GREEN         # tufaris de creasta, verde mai deschis
GRANITE = MARBLE_GREY        # fetele de granit in soare
GRANITE_SH = ROCK_LIGHT      # granit in umbra
EARTH = SAND_SHADOW          # pamant ocru la poale


# --- gorge_far_wall ----------------------------------------------------------
#
# Peretele OPUS al defileului: un arc de 200 m lungime si 80 m inaltime,
# CONCAV spre drum. Concav inseamna ca drumul sta in interiorul arcului, deci
# peretele infasoara camera — memoria `perete-paralel-nu-se-vede`: un perete
# drept, paralel cu drumul, nu se citeste ca defileu; doar curbura spre
# interior il face sa inconjoare.
#
# Constructia: o PANZA CUSUTA pe arc (vezi `build_gorge_far_wall`), nu un sir
# de mase. Nici `mesa`, nici `rock`: la 200 m buzele de mesa dispar si raman
# butoaie hexagonale (memoria `mesa-la-40m-da-butoaie`), iar masele de `rock`
# se despart pe verticala si dau palisada — masurat pe patru incercari.

# Lungimea e CONTRACT (brief §1.6: arc de 200 m) si se masoara pe bbox, adica
# pe panza din SPATE — cea mai departata de centrul arcului. Coarda ceruta aici
# e deci a panzei din fata, iar bbox-ul iese mai lat cu raportul razelor:
#   R_spate / R_fata = (150 + 14 + 40) / 150 = 1.36
# Masurat: cu 196 m coarda de fata a iesit 259.7 m bbox (1.325x). Coarda se
# imparte la raportul masurat, nu la cel teoretic.
GW_LEN = 196.0 / 1.325
# Inaltimea CERUTA e 80 m si e acum cota crestei celei mai inalte, direct: fara
# `rock(flat_top=True)` nu se mai retine nimic din varf (cu el, 80 ceruti
# ieseau 64.8 — FLAT_TOP_FRAC = 0.82).
GW_H = 80.0
GW_RADIUS = 150.0            # raza arcului: cu cat e mai mica, cu atat mai concav


def build_gorge_far_wall():
    """Arc de 200 m x 80 m, concav spre drum (drumul e spre -Y, in interior).

    O SINGURA SUPRAFATA CUSUTA, nu un sir de mase.

    Asta e a patra constructie a piesei si singura care citeste. Celelalte trei
    au fost variatii pe aceeasi idee gresita — N bucati de `rock()` asezate pe
    arc — si au esuat identic, desi cifrele treceau de fiecare data:
      1. 13 mase inguste, taper 0.16, flat_top  -> sir de cioturi
      2. creasta ridicata la 0.90 din maxim     -> cioturi de inaltime egala
      3. 9 mase late, taper 0.08, flat_top      -> lespezi cu capace-disc
      4. fara flat_top, taper 0.30              -> stalpi cu varfuri oblice
    De fiecare data masurarea spunea "creasta continua" (raport 0.82-0.84) si
    plansa spunea "palisada". Cauza e structurala, nu de reglaj: `rock()`
    construieste un corp care se INGUSTEAZA cu cota, deci doua mase care se
    ating la baza se despart inevitabil mai sus, si exact acolo se uita ochiul
    — la contur. Niciun parametru nu repara asta; trebuia schimbata
    constructia (memoria `capcana-parametrului-care-doar-aduna`).

    Aici peretele e o panza de quad-uri cusuta: inele verticale de-a lungul
    arcului, fiecare coloana cu profilul ei. Nu exista imbinari fiindca nu
    exista bucati. Variatia de silueta vine din cota crestei si din retragerea
    fetei, nu din obiecte separate — acelasi tipar ca `_ledge_section` din
    build_machupicchu_hero.py.
    """
    b = Builder()
    rnd = _lcg(4101)

    # Unghiul total al arcului se DERIVA din coarda ceruta si raza aleasa, nu
    # se alege: altfel piesa nu iese de 200 m si contractul din brief cade.
    # coarda = 2 * R * sin(span/2)  =>  span = 2 * asin(coarda / (2R))
    span = 2.0 * math.asin(min(GW_LEN / (2.0 * GW_RADIUS), 0.999))

    # --- panza cusuta: COLS coloane pe arc x ROWS inele pe verticala ---
    #
    # Fiecare coloana isi are cota de creasta si retragerea ei, deci silueta e
    # neregulata; dar toate coloanele fac parte din ACEEASI panza, deci nu
    # exista fante intre ele indiferent de cota. Amplitudinea crestei poate fi
    # acum MARE (0.55..1.0 din inaltime) tocmai fiindca o coloana joasa nu mai
    # lasa o gaura, ci o sa — la versiunile cu mase separate, orice variatie
    # de cota deschidea cer intre bucati, deci trebuia tinuta artificial mica.
    # ROWS=7: cu 5 inele, coloanele vecine de inaltimi diferite produceau
    # TREPTE dreptunghiulare vizibile pe capatul din stanga — panza n-avea
    # destule diviziuni ca sa curbeze intre doua cote. Inelele sunt ieftine
    # (COLS quad-uri fiecare) si sunt singurul lucru care face silueta sa
    # CURGA in loc sa sara.
    COLS, ROWS = 26, 7
    crest_h = []
    for i in range(COLS):
        t = i / (COLS - 1.0)
        f = (0.80 + 0.13 * math.sin(t * 4.3 + 0.6)
             + 0.07 * math.sin(t * 9.7 + 2.1)) * (0.94 + rnd() * 0.12)
        crest_h.append(GW_H * max(0.55, min(1.0, f)))
    # Capetele se ridica inapoi spre creasta (nu cad): un perete de defileu
    # continua dincolo de cadru, nu se termina intr-o pana. Masurat pe plansa,
    # ultimele cinci coloane cadeau la 48 m din 76 si capatul citea ca un bloc
    # taiat. Netezim si profilul, ca sa nu ramana salturi intre vecini.
    for _pass in range(2):
        sm = list(crest_h)
        for i in range(1, COLS - 1):
            crest_h[i] = (sm[i - 1] + 2.0 * sm[i] + sm[i + 1]) * 0.25
    # Retragerea fetei per coloana: cat se trage peretele inapoi spre +Y. Ea da
    # pinteni si scobituri pe fata verticala — la 200 m, diferenta dintre
    # "stanca" si "panza de cort" intinsa.
    setback = [rnd() * 14.0 for _ in range(COLS)]

    def _sheet(extra_r):
        """Un strat de panza (fata sau spate), ca grila de varfuri."""
        out = []
        for iz in range(ROWS + 1):
            tz = iz / float(ROWS)
            row = []
            for i in range(COLS):
                t = i / (COLS - 1.0)
                a = -span * 0.5 + span * t
                # peretele se retrage cu cota (un perete taiat in stanca se
                # apleaca in spate)
                back = setback[i] * (0.35 + 0.65 * tz) + extra_r
                r = GW_RADIUS + back
                row.append(b.bm.verts.new(
                    (math.sin(a) * r,
                     GW_RADIUS - math.cos(a) * r,
                     crest_h[i] * tz)))
            out.append(row)
        return out

    front = _sheet(0.0)
    # Spatele: a doua panza, ca peretele sa fie un CORP, nu o foaie. Fara ea se
    # vede PRIN el (backface culling) si la capete se vede ca are grosime zero.
    back = _sheet(40.0)

    wall_faces = []
    for iz in range(ROWS):
        for i in range(COLS - 1):
            wall_faces.append(b.bm.faces.new(
                (front[iz][i], front[iz][i + 1],
                 front[iz + 1][i + 1], front[iz + 1][i])))
            wall_faces.append(b.bm.faces.new(
                (back[iz][i + 1], back[iz][i],
                 back[iz + 1][i], back[iz + 1][i + 1])))
    # creasta: leaga fata de spate
    for i in range(COLS - 1):
        wall_faces.append(b.bm.faces.new(
            (front[ROWS][i], front[ROWS][i + 1],
             back[ROWS][i + 1], back[ROWS][i])))
    # capetele
    for iz in range(ROWS):
        wall_faces.append(b.bm.faces.new(
            (front[iz][0], front[iz + 1][0], back[iz + 1][0], back[iz][0])))
        wall_faces.append(b.bm.faces.new(
            (back[iz][COLS - 1], back[iz + 1][COLS - 1],
             front[iz + 1][COLS - 1], front[iz][COLS - 1])))
    for f in wall_faces:
        f[b.slot] = GRANITE_SH

    # Punctele de creasta, pentru vegetatia de mai jos.
    crest = []
    for i in range(COLS):
        t = i / (COLS - 1.0)
        a = -span * 0.5 + span * t
        r = GW_RADIUS + setback[i]
        crest.append((math.sin(a) * r, GW_RADIUS - math.cos(a) * r,
                      crest_h[i], 40.0, 200.0 / COLS))

    # --- benzile orizontale de verde, ca RETAG (zero triunghiuri) ---
    # Brief §1.6: "benzi orizontale de verde (TROPICAL_GREEN / LOG_DARK /
    # CACTUS_GREEN) ca retag, doua fete de granit MARBLE_GREY".
    #
    # Se aplica pe TOATE fetele deodata, dupa ce masele exista: benzile trebuie
    # sa se alinieze intre mase vecine (aceeasi cota = aceeasi culoare), altfel
    # fiecare bloc are dungile lui si peretele citeste ca un gard de scanduri.
    # Ordinea conteaza — ultimul retag castiga.
    allf = list(b.bm.faces)
    # poalele: pamant ocru, sub 12% din inaltime
    b.retag(allf, EARTH, where=lambda c, n: c.z < GW_H * 0.12)
    # fata verticala dinspre drum primeste granitul deschis pe pinteni
    b.retag(allf, GRANITE,
            where=lambda c, n: n.y < -0.55 and c.z > GW_H * 0.45)
    # padurea de nori: banda larga pe mijloc
    b.retag(allf, FOREST,
            where=lambda c, n: GW_H * 0.12 <= c.z < GW_H * 0.52)
    # o banda mai deschisa peste ea (tufaris) — rupe masa verde in doua valori
    b.retag(allf, SCRUB,
            where=lambda c, n: GW_H * 0.34 <= c.z < GW_H * 0.44)
    # umbra adanca de padure pe fetele care privesc in jos / spre -X
    b.retag(allf, FOREST_DARK,
            where=lambda c, n: (GW_H * 0.12 <= c.z < GW_H * 0.52
                                and n.z < -0.1))
    # creasta: granit descoperit peste 52%
    b.retag(allf, GRANITE,
            where=lambda c, n: c.z >= GW_H * 0.52)
    # doua fete mari de granit in umbra, ca treimea de sus sa nu fie uniforma
    b.retag(allf, GRANITE_SH,
            where=lambda c, n: c.z >= GW_H * 0.52 and n.x < -0.35)
    # vegetatie agatata pe fetele de sus ale crestei (unde se aduna apa)
    b.retag(allf, FOREST_DARK,
            where=lambda c, n: c.z >= GW_H * 0.60 and n.z > 0.55)

    # --- masele de vegetatie pe creasta: VOLUM, nu doar culoare ---
    # Fara ele conturul peretelui pe cer e o linie de piatra curata. Padurea de
    # nori se vede exact ca niste umflaturi neregulate pe creasta.
    # Masele de vegetatie pe creasta: UNA per bloc, lata, asezata sa ACOPERE
    # imbinarea dintre doua mase vecine. Doua bulgarasi mici per bloc citeau ca
    # pietricele pe capacul plat (aceeasi greseala ca "negii" de pe bolovanii
    # cu muschi) si nu ascundeau deloc discul de sus, care e ce tradeaza
    # peretele ca sir de cilindri.
    # FARA volume de vegetatie pe creasta.
    #
    # Trei incercari, toate judecate pe plansa, toate gresite in acelasi fel:
    #   1. doi bulgari mici pe capacul fiecarei mase  -> invizibili (sub creasta)
    #   2. o masa lata pe muchia de sus               -> sir de DALE pe muchie
    #   3. mase "ingropate" cu 40% sub muchie         -> lespezi care PLUTESC,
    #      cu gauri sub ele si bucati atarnand sub linia crestei
    #
    # A treia e cea care explica tot: peretele e o PANZA (doua foi cusute), nu
    # un corp plin. "A ingropa" ceva intr-o panza nu exista — obiectul trece
    # prin ea si iese pe dedesubt, iar golul dintre foi devine vizibil. Acelasi
    # tipar ca la bolovanii cu muschi si la flancul muntelui: orice corp inchis
    # alaturat unei suprafete isi pastreaza silueta proprie si citeste ca un
    # obiect lipit, nu ca vegetatie crescuta din ea.
    #
    # Peretele citeste ca rampart continuu FARA ele (asta era si scopul
    # rescrierii), iar padurea de pe el ramane ce cere brief-ul de fapt: benzi
    # orizontale de verde ca RETAG, aplicate mai sus, care nu costa niciun
    # triunghi si nu pot pluti. Volumul de vegetatie pe creasta ramane o
    # problema deschisa pentru integrare (scatter de copaci pe teren, unde
    # exista sol in care sa intre), nu pentru GLB-ul de fundal.
    # cativa pinteni de stanca la baza, spre drum: dau adancime peretelui si
    # ascund linia dreapta unde masele intra in teren
    for k in range(5):
        t = k / 4.0
        a = -span * 0.5 + span * t
        x = math.sin(a) * (GW_RADIUS - 18.0)
        y = GW_RADIUS - math.cos(a) * (GW_RADIUS - 18.0)
        s = 14.0 + rnd() * 10.0
        b.rock((x + (rnd() - 0.5) * 12.0, y - rnd() * 8.0, 0.0),
               (s, s * 0.8, s * (0.5 + rnd() * 0.5)), GRANITE_SH,
               seed=4300 + k, segments=5, rings=2, taper=0.30,
               strata_slots=(GRANITE_SH, EARTH, GRANITE_SH))
    return b.to_object("Gorge_Far_Wall")


# --- machu_picchu_mountain ---------------------------------------------------
#
# Muntele de sud: 60 m inalt, 150 m baza, UMAR ROTUNJIT. Poarta Soarelui sta pe
# umarul lui (brief §1.6), deci umarul nu e decorativ — e o cota pe care se
# aseaza altceva.
#
# FARA TERASE: brief-ul o cere explicit. Piesa se vede de la 150+ m, unde o
# terasa de 2 m e sub un pixel.
#
# Corpul se construieste din inele proprii (nu `rock()` direct) din acelasi
# motiv ca Huayna Picchu la valul 1: varful trebuie sa fie DECALAT fata de axa
# bazei si sa aiba un umar lateral, iar `rock()` centreaza fiecare inel pe
# aceeasi axa — ar iesi un con simetric, adica o movila.

# Inaltimea e CONTRACT (brief §1.6: 60 m). `MP_H` e cota varfului peste
# origine, dar bbox-ul masurat iesea 64 m: bevel-ul de 0.30 si masele de
# padure asezate pe flanc adauga peste apex. Cota se scade cu diferenta
# masurata, ca GLB-ul sa cada pe 60.
MP_H = 56.5                  # inaltimea utila (+ bevel/mase = 60 m bbox)
MP_BASE = 150.0              # diametrul bazei
MP_BURY = 4.0                # cat coboara sub origine (se ingroapa in teren)
MP_SHOULDER = 0.42           # fractia de cota la care iese umarul
MP_LEAN = 12.0               # decalajul varfului fata de axa bazei


def build_machu_picchu_mountain():
    """60 m x 150 m cu umar rotunjit, varf decalat, benzi de culoare ca retag."""
    b = Builder()
    rnd = _lcg(4401)
    segments, rings = 10, 7

    # Perturbatie MARE per coloana: la o piesa de 150 m, diferenta dintre doua
    # coloane vecine trebuie sa fie de metri, nu de centimetri, altfel se pierde
    # inainte sa ajunga pe ecran (aceeasi aritmetica ca la Huayna Picchu).
    col_dev = [0.80 + rnd() * 0.22 for _ in range(segments)]
    col_dev2 = [0.86 + rnd() * 0.16 for _ in range(segments)]

    rings_v = []
    for k in range(rings + 1):
        t = k / rings
        z = -MP_BURY + (MP_H + MP_BURY) * t
        frac = max(0.0, z / MP_H)
        # Profilul: UMARUL e o inflexiune, nu o panta constanta. Sub umar
        # muntele se ingusteaza lent (poale largi), peste el repede (varf).
        # Un profil de o singura putere ar da un con, adica exact ce nu vrem.
        if frac < MP_SHOULDER:
            u = frac / MP_SHOULDER
            radius_scale = 1.0 - 0.34 * (u ** 1.25)
        else:
            u = (frac - MP_SHOULDER) / max(1.0 - MP_SHOULDER, 1e-6)
            radius_scale = 0.66 * (1.0 - 0.88 * (u ** 1.05))
        ring_dev = 0.92 + rnd() * 0.10
        # varful se apleaca pe X si pe Y: fara componenta pe Y piesa ramane
        # simetrica fata de planul XZ si citeste tot ca un con
        lean_x = MP_LEAN * (frac ** 1.7)
        lean_y = MP_LEAN * 0.38 * (frac ** 2.1)
        ring = []
        for i in range(segments):
            a = 2.0 * math.pi * i / segments
            ca, sa = math.cos(a), math.sin(a)
            d = col_dev[i] * (1.0 - t) + col_dev2[i] * t
            r = radius_scale * ring_dev * d
            ring.append(b.bm.verts.new((lean_x + ca * r * MP_BASE * 0.5,
                                        lean_y + sa * r * MP_BASE * 0.5,
                                        z)))
        rings_v.append(ring)

    body = []
    for lo, hi in zip(rings_v, rings_v[1:]):
        for i in range(segments):
            j = (i + 1) % segments
            body.append(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])))
    base_face = b.bm.faces.new(tuple(reversed(rings_v[0])))
    # varf ASCUTIT: un apex peste ultimul inel. Un inel plat sus ar da un capac
    # poligonal care straluceste in soare la 150 m.
    apex = b.bm.verts.new((MP_LEAN * 1.10, MP_LEAN * 0.38, MP_H))
    tip = []
    for i in range(segments):
        j = (i + 1) % segments
        tip.append(b.bm.faces.new((rings_v[-1][i], rings_v[-1][j], apex)))

    for f in body + tip:
        f[b.slot] = FOREST
    base_face[b.slot] = EARTH

    # --- etajele de culoare, ca RETAG (zero triunghiuri) ---
    allf = body + tip
    b.retag(allf, EARTH, where=lambda c, n: c.z < MP_H * 0.10)
    b.retag(allf, FOREST,
            where=lambda c, n: MP_H * 0.10 <= c.z < MP_H * 0.58)
    b.retag(allf, SCRUB,
            where=lambda c, n: MP_H * 0.40 <= c.z < MP_H * 0.50)
    b.retag(allf, GRANITE, where=lambda c, n: c.z >= MP_H * 0.58)
    # umbra adanca de padure pe flancul dinspre -Y
    b.retag(allf, FOREST_DARK,
            where=lambda c, n: (MP_H * 0.10 <= c.z < MP_H * 0.58
                                and n.y < -0.38))
    # fete mari de granit in umbra in coroana
    b.retag(allf, GRANITE_SH,
            where=lambda c, n: c.z >= MP_H * 0.58 and n.x < -0.32)

    # --- UMARUL: o masa lipita pe flanc, la cota de asezare a Portii Soarelui ---
    # Brief §1.6: "Poarta Soarelui sta pe umarul lui". Umarul e deci o
    # platforma reala, nu o inflexiune de profil — se vede in silueta ca o
    # treapta pe flancul drept.
    sh_z = MP_H * MP_SHOULDER
    b.rock((MP_BASE * 0.22, -MP_BASE * 0.10, sh_z * 0.52),
           (MP_BASE * 0.34, MP_BASE * 0.30, sh_z * 0.86), GRANITE_SH,
           seed=4501, segments=7, rings=3, taper=0.22, flat_top=True,
           strata_slots=(GRANITE_SH, FOREST, GRANITE_SH))

    # --- masele de padure pe flancuri: VOLUM pe silueta ---
    # Conturul unui con perturbat e tot un contur neted. Umflaturile de padure
    # sunt ce face muntele sa citeasca "padure de nori" de la 150 m.
    # 6 mase, mai MARI: in plansa, 9 bulgari mici pe flanc citeau ca niste negi
    # pe o movila neteda. O masa de padure trebuie sa rupa CONTURUL muntelui ca
    # sa se vada de la 150 m, deci putine si late, nu multe si marunte.
    for k in range(6):
        a = 2.0 * math.pi * k / 6 + rnd() * 0.7
        t = 0.16 + rnd() * 0.40
        z = MP_H * t
        # raza corpului la cota z (aceeasi formula ca profilul de mai sus)
        if t < MP_SHOULDER:
            u = t / MP_SHOULDER
            rs = 1.0 - 0.34 * (u ** 1.25)
        else:
            u = (t - MP_SHOULDER) / max(1.0 - MP_SHOULDER, 1e-6)
            rs = 0.66 * (1.0 - 0.88 * (u ** 1.05))
        r = rs * MP_BASE * 0.5 * 0.86
        s = 22.0 + rnd() * 14.0
        b.boulder((math.cos(a) * r + MP_LEAN * (t ** 1.7),
                   math.sin(a) * r + MP_LEAN * 0.38 * (t ** 2.1), z),
                  (s, s * 0.88, s * 0.46),
                  FOREST if k % 3 else FOREST_DARK,
                  seed=4520 + k, segments=6, rings=3, deviation=0.18)
    return b.to_object("Machu_Picchu_Mountain")


# --- emit --------------------------------------------------------------------

clear_built()
results = []


def emit(obj, path, ao, origin="base_axis", bevel=0.3, smooth_angle=55.0):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin,
                smooth_angle=smooth_angle)
    _, sz = export_glb([obj], "machupicchu/" + path)
    results.append((path, st["tris"], sz / 1024.0, st["ao_min"], st["ao_max"]))
    return obj


# smooth_angle mic: fetele de stanca trebuie sa ramana TAIOASE. Pragul implicit
# de 55° ar netezi peretele intr-o panza continua, si la 200 m ochiul n-ar mai
# gasi niciun plan — exact ce s-a intamplat cu varful la valul 1.
built = [
    emit(build_gorge_far_wall(), "rocks/gorge_far_wall.glb", AO_FAR,
         bevel=0.35, smooth_angle=26.0),
    emit(build_machu_picchu_mountain(), "rocks/machu_picchu_mountain.glb",
         AO_PEAK, bevel=0.30, smooth_angle=26.0),
]

# .blend-ul, cu piesele departate ca sa nu se suprapuna (au 200 si 150 m)
built[1].location.x = 280.0
print("BLEND: %s (%d B)" % save_blend(built, "machupicchu_horizon.blend"))

print()
for path, tris, kb, ao_lo, ao_hi in results:
    print("%-44s tris=%6d %8.1f kB  AO %.2f..%.2f"
          % (path, tris, kb, ao_lo, ao_hi))
print("TOTAL fundal: %d tris" % sum(t for _, t, _, _, _ in results))
