"""Machu Picchu, POI B — gura de tunel in stanca (brief machu_picchu_tunel.md).

  RockTunnel   machupicchu/structures/rock_tunnel.glb
               Rock_Tunnel

Singurul element din decupajul barei care lipsea de pe POI B, dupa ce valul 4
a livrat 314 piese acolo. Criticul rundei 3 l-a cerut pe nume, iar
constructorul a refuzat corect sa-l improvizeze din `inca_wall_*`: "un arc din
trei lespezi nu citeste a tunel, citeste a poarta prabusita, si POI C are deja
poarta".

CONTRACTUL, din brief (docs/asset_briefs/machu_picchu_tunel.md §2):

  lungime (pe directia de mers)   12.0 m   sub 15 m, clip tolerabil
  gol liber pe latime            >=13.2 m  12.64 m carosabil + 0.28 marja
  gol liber pe inaltime           >=6.0 m  brief-ul pistei §2
  grosime perete/bolta           1.2-2.0 m ca sa citeasca a roca, nu carton

**Golul se masoara pe fereastra pe care o ocupa masina**, nu la baza si nu sub
cheia boltii. Lectia e platita pe `main_gate`, unde trei cifre diferite
(8.39 / 8.12 / 7.42 m) pareau o contradictie si erau trei taieturi prin aceeasi
piesa trapezoidala. Aici arcul se strange cu inaltimea prin constructie, deci
in fereastra y 0.15-1.80 (gabaritul caroseriei) golul trebuie sa ramana peste
13.2 m. Verificarea: tools/ProbeMpHGate.tscn, pe piesa exportata.

DE CE ARCUL E DIN BLOCURI, nu o gaura neteda. Silueta ceruta de bara e o
TAIETURA IN PERETE, cu bolta din blocuri de granit potrivite fara mortar —
aceeasi zidarie ca restul cetatii. Blocurile se vad individual, trapezoidale
spre cheie. Fara ele piesa ar citi ca un portal turnat.

DE CE RACORDUL DE ROCA. Piesa nu se termina intr-o muchie dreapta: de o parte
si de alta se pierde in roca neregulata, altfel se vede imbinarea cu peretele
stratificat pe care l-a construit POI B in valul 4.

COLIZIUNE: `none` pe mesh, si motivul conteaza. Masina trece PRIN tunel — un
colizor pe bolta ar fi exact capcana pe care brief-ul o evita cerand "sub 15 m
lungime". Peretii laterali sunt deja peretele de stanca al lui POI B, care are
coliziunea lui. Piesa asta e FANTOMA: geometrie care se vede, nu corp care
opreste (memoria coliziune-none-e-fantoma-nu-stearsa).

ORIGINEA e la baza, CENTRATA PE GOLUL DE TRECERE, nu pe AABB-ul intregii
piese: racordul de roca e asimetric intentionat, si un `origin="base"` naiv ar
muta axul tunelului fata de axul drumului (memoriile
origin-base-ridica-tot-obiectul si finish-recentreaza-fiecare-nod-separat).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_machupicchu_tunnel.py
"""

# AXE (dio_lib): `prism` ia conturul in planul **XZ** si extrudeaza pe **Y**;
# `box` ia center/size ca (x, ADANCIME, INALTIME). Blender e Z-up, iar exportul
# GLB converteste singur la Y-up al lui Godot. Prima versiune a tratat conturul
# ca XY si a iesit un tunel de 12,8 m INALTIME si 13,2 m lungime — exact pe dos.
import math

AO_TUNNEL = dict(samples=26, dist=3.2, gradient="vertical",
                 low=0.42, high=1.00, power=1.1, floor=0.20)

## Golul de trecere. LATIME e cota de contract: 13.2 m in fereastra masinii.
##
## Construit la 13.44, nu la 13.2: bevel-ul de 5 cm rotunjeste muchia fiecarei
## pile si mananca ~6 cm de fiecare parte. Masurat pe GLB-ul exportat, la SPAN
## 13.2 golul in fereastra y 0.15-1.80 iesea **13.08** — sub contract.
## Compensarea se face AICI, la sursa, nu coborand pragul din brief.
SPAN = 13.44
## Inaltimea peretelui drept, pana unde incepe bolta. Peste 1.80 (gabaritul
## caroseriei) ca arcul sa nu stranga golul in fereastra care conteaza.
PIER_H = 3.6
## Sageata boltii peste PIER_H. 3.6 + 2.6 = 6.2 m sub cheie, peste cei 6 ceruti.
RISE = 2.6
## Lungimea tunelului, pe directia de mers (-Z in Godot = "inainte").
LENGTH = 12.0
## Grosimea zidariei si a masei de roca din jur.
WALL = 1.6
## Cate blocuri are arcul pe fiecare jumatate (fara cheia de bolta).
ARCH_BLOCKS = 7
## Cate asize are pieptul drept al pilei.
PIER_COURSES = 6


def _arch_outline(span, pier_h, rise, wall, steps=24):
    """Conturul 2D al FETEI tunelului: golul scobit dintr-un dreptunghi plin.

    Se intoarce (exterior, gol) ca liste de puncte (x, y), gata pentru `prism`.
    Bolta e un arc de cerc, nu o semi-elipsa: zidaria incasa lucreaza in
    blocuri radiale, iar un arc de cerc le da toate aceeasi forma.
    """
    hx = span * 0.5
    # exteriorul: masa de roca in care e taiat tunelul
    ex = hx + wall
    ey = pier_h + rise + wall
    exterior = [(-ex, 0.0), (ex, 0.0), (ex, ey), (-ex, ey)]

    # golul: pile drepte, apoi arcul
    gol = [(-hx, 0.0), (-hx, pier_h)]
    for i in range(steps + 1):
        t = i / steps
        a = math.pi * (1.0 - t)          # de la stanga (pi) la dreapta (0)
        gol.append((hx * math.cos(a), pier_h + rise * math.sin(a)))
    gol.append((hx, 0.0))
    return exterior, gol


if __name__ == "__main__":
    clear_built()
    b = Builder()

    exterior, gol = _arch_outline(SPAN, PIER_H, RISE, WALL)

    # --- masa de roca, cu golul scobit ------------------------------------
    # Se construieste ca inel: fasii intre conturul exterior si cel al golului.
    # Un `prism` plin plus o scadere booleana ar fi mai simplu, dar boolean-ul
    # sparge marcajul de slot pe fete (dio_lib tine slotul intr-un layer int,
    # nu intr-un material), si atunci toata piesa ar cadea pe un singur slot.
    n = len(gol)
    for i in range(n - 1):
        x0, y0 = gol[i]
        x1, y1 = gol[i + 1]
        # normala spre exterior, ca fasia sa iasa din gol
        nx, ny = (y1 - y0), -(x1 - x0)
        ln = math.hypot(nx, ny) or 1.0
        nx, ny = nx / ln * WALL, ny / ln * WALL
        quad = [(x0, y0), (x1, y1), (x1 + nx, y1 + ny), (x0 + nx, y0 + ny)]
        # conturul e in planul X-Z al lui Blender (lateral x inaltime); `prism`
        # il extrudeaza pe adancime, deci piesa se roteste la asezare
        # INTRADOSUL (fata dinspre gol) ia ROCK_LIGHT: e in umbra, si AO-ul
        # copt o adanceste. ROCK_DARK ar iesi ruginiu pe suprafata mare —
        # memoria rock-dark-nu-pe-bazalt.
        slot = ROCK_LIGHT if i % 3 else ROCK_DARK
        b.prism(quad, LENGTH, slot, center=(0, -LENGTH * 0.5, 0))

    # --- arcul de blocuri, pe fata de intrare -----------------------------
    # Blocurile se vad individual si se strang trapezoidal spre cheie: asta e
    # ce face piesa sa citeasca a zidarie incasa si nu a portal turnat.
    for side in (-1, 1):
        for k in range(ARCH_BLOCKS):
            t0 = k / (ARCH_BLOCKS * 2.0)
            t1 = (k + 1) / (ARCH_BLOCKS * 2.0)
            if side < 0:
                a0, a1 = math.pi * (1.0 - t0), math.pi * (1.0 - t1)
            else:
                a0, a1 = math.pi * t0, math.pi * t1
            hx = SPAN * 0.5
            p0 = (hx * math.cos(a0), PIER_H + RISE * math.sin(a0))
            p1 = (hx * math.cos(a1), PIER_H + RISE * math.sin(a1))
            nx0, ny0 = math.cos(a0), math.sin(a0) * (RISE / max(hx, 0.001))
            nx1, ny1 = math.cos(a1), math.sin(a1) * (RISE / max(hx, 0.001))
            g = 0.82                      # grosimea radiala a blocului
            quad = [p0, p1,
                    (p1[0] + nx1 * g, p1[1] + ny1 * g),
                    (p0[0] + nx0 * g, p0[1] + ny0 * g)]
            # pe AMBELE capete: masina intra pe unul si iese pe celalalt, iar
            # un tunel cu arc doar la intrare citeste a fatada lipita.
            for y_end in (0.28, -LENGTH + 0.28):
                b.prism(quad, 0.55, MARBLE_GREY, center=(0, y_end, 0))

    # cheia de bolta, putin mai iesita: e ce citeste ochiul primul
    for y_end in (0.30, -LENGTH + 0.30):
        b.box((0.0, y_end, PIER_H + RISE + 0.38), (0.95, 0.62, 0.78), MARBLE_GREY)

    # --- asizele pilelor, de o parte si de alta a golului -----------------
    for side in (-1, 1):
        for c in range(PIER_COURSES):
            h = PIER_H / PIER_COURSES
            y = h * (c + 0.5)
            # latimi inegale pe asiza, ca sa nu iasa caramidar
            w = 0.92 + 0.14 * ((c * 7) % 3)
            for y_end in (0.26, -LENGTH + 0.26):
                b.box((side * (SPAN * 0.5 + w * 0.5 - 0.06), y_end, y),
                      (w, 0.52, h * 0.86), MARBLE_GREY)

    # --- racordul de roca: piesa se pierde in perete, nu se taie drept ----
    # Asimetric intentionat (vezi antetul): pe stanga intra in faleza lui POI B,
    # pe dreapta se subtiaza spre defileu.
    # `rock`, nu `box`: cutiile drepte citeau ca placi lipite pe fatada
    # (vazut pe preview). Roca are nevoie de fatete neregulate ca sa se piarda
    # in peretele stratificat al lui POI B.
    # RACORDUL: blocuri STRATIFICATE, nu `rock`.
    #
    # Doua incercari cu `b.rock` au iesit CONURI care trec peste arc — forma
    # vine din generator (se ingusteaza in sus prin constructie), nu din
    # proportiile pe care i le dai. Aceeasi lectie ca `conul-e-casa-nu-stanca`.
    #
    # Peretele lui POI B e stratificat (straturi orizontale de roca), deci
    # racordul se face din lespezi late si joase, usor rotite — se leaga de
    # ce e deja acolo si ramane SUB coama boltii.
    TOP = PIER_H + RISE + WALL
    for side, bulk in ((-1, 5.2), (1, 3.0)):
        for k in range(5):
            t = k / 5.0
            w = bulk * (1.0 - t * 0.18) * (1.0 + 0.12 * ((k * 3) % 2))
            h = TOP * 0.17
            y = TOP * (0.09 + t * 0.62)
            if y + h * 0.5 > TOP * 0.86:
                continue
            b.box((side * (SPAN * 0.5 + WALL * 0.45 + w * 0.42),
                   -LENGTH * (0.16 + t * 0.34), y),
                  (w, LENGTH * 0.62, h), ROCK_LIGHT)

    # --- muschi pe asizele de jos, semnatura pistei ------------------------
    for side in (-1, 1):
        for k in range(4):
            b.box((side * (SPAN * 0.5 + 0.42), 0.54, 0.18 + k * 0.29),
                  (0.5 + 0.1 * (k % 2), 0.1, 0.16), CACTUS_GREEN)

    obj = b.to_object("Rock_Tunnel")
    # `base_axis`, NU `base`: coboara pe Z dar pastreaza XY asa cum a fost
    # construit, deci originea ramane pe axul GOLULUI (x = 0), nu pe centrul
    # AABB-ului. Racordul de roca e asimetric intentionat (3,4 m pe stanga fata
    # de 1,9 pe dreapta), deci `base` ar muta axul tunelului cu ~0,7 m fata de
    # axul drumului.
    stats = finish(obj, bevel=0.05, ao=AO_TUNNEL, origin="base_axis")
    print("Rock_Tunnel %4d tris  AO %.2f..%.2f"
          % (stats["tris"], stats["ao_min"], stats["ao_max"]))
    path, size = export_glb([obj], "machupicchu/structures/rock_tunnel.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
