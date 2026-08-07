"""wave_surge.glb — valul care spala digul de pe Okinawa (WAVE_SURGE, 30 m).

Referinta: assets/okinawa_inspiration/, randul HAZARD OBJECTS. Modelul pentru
hazardul de pe digul de start (#106): un val care trece lateral peste sosea, cu
creasta care se rastoarna si spuma in fata.

NUMELE `Wave`, `Wave_Foam` SI `Wave_Spray` SUNT CONTRACT, ca `Blades` la moara:
`scenes/hazards/wave_surge.gd` cauta nodurile dupa nume ca sa le anime separat —
corpul se leagana, spuma pulseaza, stropii sar. Daca unul lipseste, valul merge
fara piesa aia in loc sa crape.

## O SINGURA BUCATA DE 30 M, si de ce s-a schimbat

Prima versiune era de 6 m, iar pista o repeta de cinci ori ca sa acopere drumul.
Din masina se vedea exact ce era: cinci valuri identice unul langa altul, cu
cusaturi. Repetitia e buna pentru pietre si tufe, unde ochiul n-are cu ce sa
compare — un val e o LINIE CONTINUA, si orice ritm in ea se citeste instantaneu
ca sablon.

Deci valul se construieste intreg, si isi permite ce nu-si permitea o bucata
repetata: varfuri de inaltimi diferite, o portiune deja SPARTA (joasa, plata,
plina de spuma) langa una care inca se rastoarna, si o linie de creasta care
serpuieste in loc sa fie trasa cu rigla. Astea trei sunt tot ce desparte un val
de o dune de nisip albastra.

Costa ~2.5k triunghiuri intr-o singura instanta, fata de 2.5k in cinci — acelasi
pret pentru ceva ce nu mai citeste ca un sirag.

## Forma

Creasta care se rastoarna: peretele din fata e mai ABRUPT decat spatele si
varful se apleaca inainte. Cheia e ca buza sta mai in FATA decat scobitura de
sub ea — asa iese o consola reala, adica un val care se sparge. Prima versiune
avea creasta doar impinsa inainte, fara scobitura, si — cu netezire pe 55° peste
ea — se randa ca o cupola turcoaz neteda. Silueta de val vine din CONCAVITATEA
de sub buza, nu din inaltime.

Aceeasi lectie ca la tornada (`build_typhoon.py`: „o suprafata de revolutie
invartita in jurul propriei axe e identica cu ea insasi"): forma trebuie sa
poarte miscarea, altfel miscarea nu se vede.

## Cote

30.0 m lungime (doua latimi de sosea, cat cere `Track._build_wave_surge`),
3.0 m in varful cel mai inalt, 4.5 m grosime pe directia de inaintare. Inaltimea
NU e de gust: `ChaseCamera` sta la 10 m deasupra masinii si priveste in jos, deci
un obiect jos dispare sub botul masinii cu mult inainte sa ajungi la el. La 3.0 m
creasta ramane peste linia capotei de la ~15 m, adica exact fereastra in care mai
ai ce decide (vezi tabelul de incadrare din `build_typhoon.py`).

Raportul lungime/inaltime e 1:10, si asta e o alegere, nu o scapare: un val care
spala un dig E lung si jos. Ce-l face sa citeasca a val nu e proportia, ci
RULOUL ALB de pe buza — prima varianta punea spuma la baza, unde o ascunde chiar
corpul valului, si iesea o panglica verde cu pietricele albe pe nisip.

## Sloturi

REEF_SHALLOW pentru corp (turcoazul de peste recif), FOAM_WHITE pentru creasta,
spuma si stropi. Fara textura de clasa: apa isi ia aspectul din shaderul pistei,
iar stratul de detaliu e o textura de ROCA — pe apa face noroi (style_bible §4).
"""

import math
from mathutils import Vector

LENGTH = 30.00       # de-a lungul soselei
HEIGHT = 3.00        # varful cel mai inalt
DEPTH = 4.50         # cat de "gros" e valul pe directia de inaintare
SPANS = 41           # sectiuni pe lungime


def _shape(u):
    """Cotele profilului la fractiunea u pe lungime (0..1).

    Intoarce (inaltime, curl, wobble):
      `curl`   cat de tare se rastoarna creasta acolo. 1 = consola plina,
               0 = deja sparta, adica o limba plata de spuma.
      `wobble` cat de mult iese sectiunea in fata fata de linia de baza. Fara el
               creasta e un segment de dreapta, si nimic din lume nu e.

    Cele trei varfuri au inaltimi si faze diferite DELIBERAT: doua sinusoide cu
    perioade necomensurabile (2.3 si 1.4 lungimi de val pe piesa), exact trucul
    prin care marea din `water.gdshader` nu se repeta.
    """
    # Capetele coboara, dar lent: pe 30 m un `sin` simplu ar face din val o
    # lentila. Exponentul mic tine corpul plin si stinge doar ultimii metri.
    fade = math.sin(math.pi * u) ** 0.22
    # Variatia e mica INTENTIONAT. Prima incercare mergea intre 0.20 si 1.04 din
    # inaltime, ca sa aiba „varfuri diferite" — a iesit o panglica plata cu o
    # cocoasa. Un val e un ZID cu inaltime inegala, nu un lant de dealuri: sub
    # ~60% din inaltime nu mai citeste ca perete de apa, ci ca movila.
    swell = (0.80
             + 0.13 * math.sin(u * math.tau * 1.15 - 0.7)
             + 0.07 * math.sin(u * math.tau * 2.30 + 1.9))
    h = HEIGHT * fade * swell
    # Portiunea sparta: `curl` cade aproape la zero pe o treime din lungime,
    # unde valul a cedat deja. Acolo spuma se ingroasa (vezi `foam`).
    curl = max(0.0, math.sin(u * math.tau * 1.15 - 0.7)) ** 1.4
    wobble = 0.45 * math.sin(u * math.tau * 0.85 + 2.1) \
        + 0.22 * math.sin(u * math.tau * 2.7)
    return h, curl, wobble


def wave(b):
    """Corpul valului: sapte puncte per sectiune, de la baza din spate pana la
    baza din fata, trecand PE SUB buza crestei.
    """
    rings = []
    for i in range(SPANS):
        u = i / float(SPANS - 1)
        h, curl, wobble = _shape(u)
        x = (u - 0.5) * LENGTH
        # y negativ = spre directia in care merge valul (fata).
        ring = [
            (x, DEPTH * 0.50 + wobble * 0.4, 0.0),                    # coada
            (x, DEPTH * 0.14 + wobble, h * 0.45),                     # panta lina
            (x, -DEPTH * 0.05 + wobble, h * 0.88),                    # umar
            (x, -DEPTH * (0.15 + 0.30 * curl) + wobble, h),           # buza
            (x, -DEPTH * (0.05 + 0.11 * curl) + wobble, h * 0.60),    # scobitura
            (x, -DEPTH * 0.30 + wobble, h * 0.24),                    # perete
            (x, -DEPTH * 0.50 + wobble * 0.4, 0.0),                   # baza fata
        ]
        rings.append([b.bm.verts.new(p) for p in ring])

    new_verts = [v for r in rings for v in r]
    for lo, hi in zip(rings, rings[1:]):
        for k in range(len(lo) - 1):
            b.bm.faces.new((lo[k], lo[k + 1], hi[k + 1], hi[k]))
    # Fundul: valul e vazut si de sus, din camera de urmarire, deci nu poate fi
    # o coaja deschisa — s-ar vedea prin el (backface culling).
    for lo, hi in zip(rings, rings[1:]):
        b.bm.faces.new((lo[-1], hi[-1], hi[0], lo[0]))
    b.bm.faces.new(tuple(rings[0]))
    b.bm.faces.new(tuple(reversed(rings[-1])))
    faces = b._tag(new_verts, REEF_SHALLOW)
    # Creasta alba: retag pe fetele de sus, in loc de geometrie noua. Costa zero
    # triunghiuri si e exact ce face `strata_slots` la stanci. Pragul e RELATIV
    # la inaltimea locala, nu absolut: cu un prag fix, portiunile joase ale
    # valului ar fi ramas turcoaz pana in varf si spargerea nu s-ar fi vazut.
    def _crown(c, n):
        u = c.x / LENGTH + 0.5
        h, _curl, _w = _shape(min(max(u, 0.0), 1.0))
        return c.z > h * 0.62 and n.z > -0.2
    b.retag(faces, FOAM_WHITE, where=_crown)


def foam(b):
    """Rolul alb care calareste buza, plus limba de spuma din fata.

    Doua siruri, si amandoua conteaza:
      - RULOUL de pe buza (z ~ inaltimea locala) e ce face valul sa citeasca a
        val de la distanta. Prima versiune punea spuma la BAZA valului, la 10-20%
        din inaltime — adica exact unde n-o vezi din masina, fiindca o ascunde
        corpul valului. In randare se vedeau niste pietricele albe pe nisip.
      - APRONUL din fata, turtit, e apa deja varsata pe drum. El leaga valul de
        pelicula pe care o deseneaza `WaterHazard`, ca sa nu para ca valul
        pluteste peste o balta straina.

    Bucatile se SUPRAPUN (pas 0.85 m, lungime ~1.9 m): un sirag cu goluri intre
    piese se citeste ca margele, nu ca spuma. Piesa e separata de corp ca sa
    poata fi pulsata de script — telegrafierea hazardului (#106) e un puls de
    spuma, nu o miscare de val.
    """
    rnd = _lcg(29)
    n_roll = 34
    for k in range(n_roll):
        u = (k + 0.5) / n_roll
        h, curl, wobble = _shape(u)
        x = (u - 0.5) * LENGTH
        s = 0.42 + rnd() * 0.22
        # Pe portiunea inca in picioare ruloul sta pe buza si e impins in fata;
        # unde valul a cedat, se lasa mai jos si se latteste.
        b.boulder((x + (rnd() - 0.5) * 0.35,
                   -DEPTH * (0.16 + 0.26 * curl) + wobble + (rnd() - 0.5) * 0.3,
                   h * (0.88 + 0.10 * curl) + (rnd() - 0.5) * 0.16),
                  (s * 2.3, s * 1.5, s * 1.4), FOAM_WHITE,
                  seed=29 + k * 11, segments=6, rings=3, deviation=0.26)
    rnd2 = _lcg(83)
    n_apron = 22
    for k in range(n_apron):
        u = (k + 0.5) / n_apron
        h, curl, wobble = _shape(u)
        x = (u - 0.5) * LENGTH
        broken = 1.0 - curl
        s = (0.50 + rnd2() * 0.30) * (0.60 + 0.80 * broken)
        b.boulder((x + (rnd2() - 0.5) * 0.9,
                   -DEPTH * (0.52 + rnd2() * 0.26) + wobble,
                   0.10 + rnd2() * 0.16),
                  (s * 2.1, s * 1.4, s * 0.40), FOAM_WHITE,
                  seed=83 + k * 7, segments=6, rings=3, deviation=0.24)


def spray(b):
    """Stropii aruncati de buza, deasupra portiunilor care INCA se rastoarna.

    Piesa proprie fiindca se anima altfel decat spuma: spuma pulseaza pe loc,
    stropii sar. Fara ei, creasta e o suprafata neteda si valul citeste ca
    plastic — aceeasi problema pe care la tornada o rezolva braiele elicoidale.
    """
    rnd = _lcg(47)
    n = 30
    for k in range(n):
        u = (k + 0.5) / n
        h, curl, wobble = _shape(u)
        if curl < 0.18:
            continue # unde valul e deja spart nu mai sare nimic, doar clabuceste
        x = (u - 0.5) * LENGTH
        s = (0.14 + rnd() * 0.16) * (0.5 + curl)
        b.boulder((x + (rnd() - 0.5) * 1.6,
                   -DEPTH * (0.14 + rnd() * 0.26) + wobble,
                   h * (1.00 + rnd() * 0.34)),
                  (s * 1.5, s * 1.2, s * 1.2), FOAM_WHITE,
                  seed=47 + k * 13, segments=5, rings=2, deviation=0.30)


# Fara gradient vertical: apa nu se intuneca spre baza, s-ar citi ca murdarie.
# Dar OCLUZIA GEOMETRICA ramane pornita, si e singurul lucru care face consola
# de sub buza sa se vada — un val cu AO uniform e o cupola colorata.
AO_SPEC = dict(samples=24, dist=2.2, gradient="none", floor=0.52)

clear_built("Wave")
built = []
for name, fill in (("Wave", wave), ("Wave_Foam", foam), ("Wave_Spray", spray)):
    b = Builder()
    fill(b)
    obj = b.to_object(name)
    # Fara bevel: suprafata de apa n-are muchii de tesit, iar creasta trebuie sa
    # ramana ascutita — bevel-ul ar rotunji exact silueta care telegrafiaza.
    # `smooth_angle=20` din acelasi motiv: la 55° (implicit) buza crestei se
    # topea in umar si tot valul se randa ca o cupola neteda.
    #
    # `origin="keep"` la piesele animate: `Wave_Foam` si `Wave_Spray` sunt scalate
    # si ridicate de script fata de originea VALULUI. Coborate fiecare pe propria
    # baza, ar fi sarit din loc la prima pulsatie.
    stats = finish(obj, bevel=0.0,
                   origin="base_axis" if name == "Wave" else "keep",
                   ao=AO_SPEC, smooth_angle=20.0)
    built.append(obj)
    d = obj.dimensions
    print("%-12s %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))

print("TOTAL: %d tris" % sum(tri_count(o) for o in built))
print("GLB:  %s (%d B)" % export_glb(built, "wave_surge.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "wave_surge.blend"))
