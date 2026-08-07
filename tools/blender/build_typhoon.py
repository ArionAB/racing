"""typhoon.glb — palnia de mini-typhoon care matura soseaua (TOTAL 18.0 m).

Hazardul de pe Okinawa: o trâmbă de apa si nisip care traverseaza pista lateral,
ridica masina prinsa in ochi si o lasa inapoi pe asfalt cateva zeci de metri mai
incolo. Mecanica e in `scenes/hazards/typhoon_hazard.gd`; aici e doar silueta.

NUMELE `Typhoon` SI `Typhoon_Debris` SUNT CONTRACT, ca `Wave`/`Wave_Foam` la val
si `Blades` la moara: scriptul cauta nodurile dupa nume ca sa le roteasca la
viteze DIFERITE. Daca lipseste al doilea, palnia se invarte fara gulerul de
moloz de la baza in loc sa crape.

## De ce EXACT 18 m, si de ce cifra asta nu e de stil

Inaltimea unui hazard vertical nu se alege, se DERIVA din camera. `ChaseCamera`
sta la 12.5 m in spate si 10.0 m deasupra masinii, si priveste in jos cu 28.75°
(`_pitch_tan` = (10.0 - 0.40) / (12.5 + 5.0)). Cu FOV-ul vertical de 68° in
repaus, raza de SUS a frustumului urca deci doar 34 - 28.75 = **5.25° peste
orizontala** — o camera inclinata in jos are foarte putin cer in cadru.

De acolo iese plafonul: la `D` metri de camera intra in cadru doar ce e sub
`10.0 + D * tan(5.25°)`. Masurat in `tools/probe_typhoon.gd`:

    m in fata masinii |  repaus (68°) | 50% viteza (72°) | viteza max (76°)
                   40 |        14.8 m |           16.7 m |           18.6 m
                   60 |        16.7 m |           19.2 m |           21.8 m
                   80 |        18.5 m |           21.8 m |           25.1 m
                  100 |        20.3 m |           24.3 m |           28.3 m

18.0 m inseamna: palnia INTREAGA e in cadru de la ~37 m in fata la viteza de
varf (FOV 76°) si de la ~75 m in cea mai stramta stare a camerei. Adica o vezi
toata exact cat timp mai ai ce decide, si abia in ultima secunda incepe sa-ti
iasa varful din cadru — ceea ce e bine, nu rau: atunci trebuie sa se simta ca te
inghite, nu sa incapa politicos in poza.

Cifra tine pe TOT garajul: formula de incadrare a camerei pastreaza unghiul
constant (28.6° la autobuz, 28.9° la kart), deci nu exista masina din care sa se
vada altfel.

## Forma

Un tornado modelat ca un con neted se randeaza ca un con: rotatia nu se vede,
fiindca o suprafata de revolutie invartita in jurul propriei axe e identica cu
ea insasi. Aceeasi lectie ca la val (`build_wave_surge.py`: „silueta de val vine
din CONCAVITATEA de sub buza"). De aia palnia are trei BRAIE ELICOIDALE infasurate
pe ea — ele sunt tot ce face invartirea vizibila, si tot ele dau granulatia care
citeste ca moloz ridicat de vant.

Profilul are un GAT: cel mai ingust punct e la 3.2 m, nu la sol. Fara el iese o
palnie de gramofon; cu el, silueta se citeste ca tornada de la 150 m.

## Culori

Rampa verticala de valoare vine din SLOTURI, nu din AO — patru benzi retaguite
pe inaltime pe aceeasi geometrie (trucul de la creasta valului, costa zero
triunghiuri): nisip in soare la baza, gri cald la mijloc, gri inchis mai sus,
bazalt in gulerul de nor. Toate sunt sloturi care exista deja pe Okinawa, deci
asset-ul nu adauga niciun material.
"""

import math
from mathutils import Vector

# Inaltimea totala, IDENTICA cu TyphoonHazard.FUNNEL_HEIGHT. Se rescrie acolo
# fiindca din ea ies zona de prindere si plafonul de aruncare.
HEIGHT = 18.00

# Profilul palniei: (z, raza), de jos in sus.
#
# ULTIMELE PUNCTE COBOARA, si asta e intentionat. Palnia trebuie INCHISA sus:
# camera sta la 10 m, tromba are 18, deci te uiti in sus la ea si un inel deschis
# ar arata prin toata palnia — fetele dinspre tine sunt spatele peretelui opus,
# adica taiate de backface culling. Un tub gol, nu o tromba.
#
# Prima versiune inchidea cu un DISC: profil urcator pana la raza maxima, apoi
# apex la 18.0. Randat, iesea o ciuperca — un capac negru, plat, lat de 14 m,
# asezat peste palnie ca o palarie. Cauza e geometrica si evidenta dupa ce o vezi:
# ca sa inchizi o raza de 7 m in 1 m de inaltime, panta capacului e aproape
# orizontala, deci prinde lumina ca o masa si citeste ca suprafata solida.
#
# Acum profilul se RASUCESTE peste buza: urca la raza maxima la 18.0, apoi se
# intoarce in jos si inauntru si se inchide pe la 16.2 m, ASCUNS SUB guler.
# `revolve` accepta asta fara nimic special — z-ul n-are nevoie sa fie monoton,
# fetele se leaga tot inel cu inel, iar suprafata exterioara se continua peste
# buza si devine burta gulerului. Acelasi truc ca la consola valului
# (`build_wave_surge.py`): silueta vine din CONCAVITATE, nu din inaltime.
#
# JUMATATEA DE JOS E MAI GROASA DECAT PARE „CORECT" PENTRU O TROMBA, si e o
# decizie de gameplay, nu de stil. Prima versiune avea gatul la 1.30 m raza si
# talpa la 3.40. Randata din masina (`snapshot --gamecam`), iesea o franghie
# rasucita: coloana vizibila la nivelul soselei avea vreo 3 m latime, in timp ce
# zona care te ridica are 14 m diametru (CATCH_RADIUS = 7 m). Adica hazardul
# prindea la 6 m de un obiect care arata lat de un metru si jumatate — exact
# felul de nepotrivire pe care jucatorul o citeste ca hitbox nedrept, si pe care
# n-are cum s-o invete din ce vede.
#
# Silueta de sus, unde nu atinge pe nimeni, a ramas asa cum era.
PROFILE = [
    (0.00, 4.40),   # talpa de praf, pe sol
    (0.90, 3.10),
    (2.10, 2.15),
    (3.30, 1.80),   # GATUL — cel mai ingust punct, semnatura siluetei
    (5.60, 1.92),
    (8.20, 2.15),
    (10.60, 2.45),
    (12.60, 2.85),
    (14.10, 3.35),
    (15.30, 4.05),
    (16.30, 4.95),
    (17.20, 5.80),
    (18.00, 6.30),  # buza gulerului, cea mai lata: 12.6 m
    (17.65, 5.80),  # de aici in jos: BURTA gulerului, intoarsa sub el
    (17.10, 4.60),
    (16.60, 3.00),
    (16.30, 1.40),
    (16.20, 0.00),  # apex, ascuns sub guler — nu se vede de nicaieri de pe sosea
]

## Laturi pe circumferinta palniei.
##
## 20, nu 8-12 ca la restul prop-urilor, si din doua motive care se aduna. Intai,
## tromba e un obiect de 18 m pe care il vezi din fata, aproape, in centrul
## cadrului — la 12 laturi conturul ei citea poligonal. Al doilea motiv e mai
## putin evident: granita ondulata de culoare (`_scallop`) se evalueaza PER FATA,
## deci numarul de laturi e rezolutia ei unghiulara. La 12 laturi si sin(3*theta),
## unda iesea in trepte dreptunghiulare — mai rau decat inelele drepte pe care
## trebuia sa le repare. Rezolutia benzii nu poate fi mai fina decat mesh-ul.
SEGMENTS = 20

# --- braiele elicoidale ---------------------------------------------------
RIBS = 3
RIB_FROM, RIB_TO = 0.35, 16.40
RIB_STEPS = 22
## Cate ture face un braț pe toata inaltimea. La 2+ iese un arc de ceas, la sub 1
## nu se mai citeste ca spirala din nicio pozitie: 1.35 e cat trebuie ca ochiul
## sa prinda directia de rotatie dintr-o privire.
RIB_TURNS = 1.35

# --- sloturi de paleta (indicii din scripts/palette.gd) -------------------
SAND_MID = 1
SAND_SHADOW = 2
ASPHALT_EDGE = 6
CONCRETE = 8
CORAL_SAND = 19
VOLCANIC_BLACK = 20
FOAM_WHITE = 22

## Benzile de culoare pe inaltime: (z_pana_la, slot). Ultima prinde tot restul.
BANDS = [(3.50, SAND_MID), (9.50, CONCRETE), (14.00, ASPHALT_EDGE),
         (1e9, VOLCANIC_BLACK)]


def funnel_radius(z):
    """Raza palniei la cota z, interpolata liniar pe PROFILE.

    Braiele trebuie sa stea PE suprafata, nu langa ea, iar suprafata nu e o
    formula — e o lista de puncte. Interpolarea e singurul mod de a le lipi fara
    sa dublez profilul in doua locuri.
    """
    if z <= PROFILE[0][0]:
        return PROFILE[0][1]
    for (z0, r0), (z1, r1) in zip(PROFILE, PROFILE[1:]):
        if z <= z1:
            t = (z - z0) / max(z1 - z0, 1e-6)
            return r0 + (r1 - r0) * t
    return PROFILE[-1][1]


# ############################################################################
# GRANITELE DE CULOARE SUNT ORIZONTALE, si asta e o decizie, nu lene.
#
# Inelele drepte imi pareau prea regulate, asa ca am incercat o granita
# ONDULATA: limita benzii plus `A * sin(k*theta)`, evaluata per fata in `retag`.
# Ideea era ca undele se invart odata cu palnia si adauga un semnal de rotatie
# pe langa braie. Randat, a iesit mai rau decat problema: o scara de
# dreptunghiuri, nu o unda.
#
# Motivul e ca rezolutia granitei nu e data de numarul de LATURI, cum crezusem
# (de aia am si urcat SEGMENTS de la 12 la 20), ci de INELELE PROFILULUI. `retag`
# lucreaza pe fete intregi, iar o fata isi ia z-ul din inelul pe care sta —
# inelele sunt la 1.0-2.5 m distanta pe verticala, deci o unda de +/-1 m nu poate
# muta granita decat cu inele intregi, adica in trepte. Ca sa iasa neted ar fi
# trebuit un profil de zeci de inele — adica sa platesc geometrie pentru un
# detaliu care la 60 m e de doi pixeli.
#
# SEGMENTS a ramas 20 fiindca acolo castigul era real (conturul), nu pentru unda.
# ############################################################################


def funnel(b):
    """Corpul palniei plus braiele elicoidale."""
    faces = b.revolve([(r, z) for z, r in PROFILE], SAND_MID,
                      segments=SEGMENTS, cap_bottom=True)
    # Rampa de valoare, retaguita pe inaltime. Geometrie noua: zero.
    # Banda 0 e deja pusa de `revolve`; pornim de la a doua.
    for i in range(1, len(BANDS)):
        lo = BANDS[i - 1][0]
        hi, slot = BANDS[i]
        b.retag(faces, slot, where=lambda c, n, lo=lo, hi=hi: lo <= c.z < hi)

    for k in range(RIBS):
        a0 = 2.0 * math.pi * k / RIBS
        path, radii = [], []
        for i in range(RIB_STEPS):
            t = i / float(RIB_STEPS - 1)
            z = RIB_FROM + (RIB_TO - RIB_FROM) * t
            fr = funnel_radius(z)
            # Grosimea creste cu palnia: un brat de aceeasi grosime pe toata
            # inaltimea arata ca o sarma infasurata pe un con.
            thick = min(max(fr * 0.17, 0.16), 0.78)
            # Capetele se sting in VARF (raza 0), altfel raman doua capace
            # poligonale care sclipesc in soare — vezi taper_sweep in dio_lib.
            if i == 0 or i == RIB_STEPS - 1:
                thick = 0.0
            a = a0 + t * RIB_TURNS * 2.0 * math.pi
            # Braiele stau PESTE suprafata, cu jumatate de grosime in afara ei.
            rr = fr + thick * 0.45
            path.append((rr * math.cos(a), rr * math.sin(a), z))
            radii.append(thick)
        rib = b.taper_sweep(path, radii, CORAL_SAND, segments=6,
                            cap_start=False, cap_end=False)
        # Sus, molozul devine stropi: alb de spuma peste gri de furtuna, altfel
        # bratele dispar exact acolo unde palnia e cea mai inchisa.
        b.retag(rib, FOAM_WHITE, where=lambda c, n: c.z > 10.0)


def debris(b):
    """Gulerul de moloz de la baza: ce smulge tromba de pe plaja.

    Piesa separata ca sa se poata invarti cu ALTA viteza decat palnia. Doua
    corpuri de revolutie rotite la unison arata ca un singur obiect rigid; la
    viteze diferite, ochiul citeste turbulenta. Acelasi motiv pentru care
    `Wave_Foam` e separata de `Wave`.
    """
    rnd = _lcg(71)
    n = 15
    for k in range(n):
        a = 2.0 * math.pi * k / n + rnd() * 0.4
        # Inelul incepe DINCOLO de talpa palniei: bucatile asezate peste ea se
        # pierdeau in silueta, fiindca aveau si acelasi slot. Marginea lui de
        # sus ajunge la ~7 m, adica FIX pe CATCH_RADIUS — inelul de moloz e
        # singurul lucru care deseneaza pe sol cat de larg prinde tromba, si de
        # aia cifra nu e „cat arata bine", e cea din hazard.
        rr = 4.4 + rnd() * 2.7
        z = 0.15 + rnd() * 2.6
        s = 0.6 + rnd() * 0.65
        b.boulder((rr * math.cos(a), rr * math.sin(a), z),
                  # Turtite si intinse pe tangenta: bucatile smulse de vant
                  # zboara culcate, nu se rostogolesc ca pietrele.
                  # Doua sloturi alternate — un inel monocrom citea ca o gulie
                  # zimtata in jurul bazei, nu ca moloz.
                  (s * 2.0, s * 1.05, s * 0.55),
                  SAND_SHADOW if k % 3 == 0 else SAND_MID,
                  seed=71 + k * 13, segments=6, rings=3, deviation=0.26)


# Fara gradient vertical: rampa de valoare o dau deja benzile de slot, iar un
# gradient peste ele ar inchide baza — adica exact partea care trebuie sa fie
# nisip in soare. Ramane ocluzia geometrica, singura care sapa umbra sub braie,
# si ea e tot ce face spirala sa aiba relief.
AO_SPEC = dict(samples=24, dist=2.4, gradient="none", floor=0.46)

clear_built("Typhoon")
built = []
for name, fill in (("Typhoon", funnel), ("Typhoon_Debris", debris)):
    b = Builder()
    fill(b)
    obj = b.to_object(name)
    # Bevel mic: o tromba n-are muchii tehnice, dar braiele au nevoie de o banda
    # de tesitura ca sa prinda lumina si sa se desprinda de corp.
    stats = finish(obj, bevel=0.03, origin="base_axis", ao=AO_SPEC,
                   smooth_angle=40.0)
    built.append(obj)
    d = obj.dimensions
    print("%-16s %5d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))

print("TOTAL: %d tris" % sum(tri_count(o) for o in built))
print("GLB:  %s (%d B)" % export_glb(built, "effects/typhoon.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "typhoon.blend"))
