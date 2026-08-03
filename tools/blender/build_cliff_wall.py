"""cliff_wall.glb — 6 sectiuni modulare de faleza. Brief: docs/asset_briefs/cliff_wall.md

Peretii de canion care inlocuiesc zidul rosu de pe marginea soselei. Se aseaza
cap la cap, la pas de 14 m, cu suprapunere de 1 m.

Buget: <= 550 triunghiuri per sectiune vizuala (10x6 smooth, issue #94).
Sloturi: rock_light (corp), rock_dark (baza/crapaturi), sand_light (coama).

DOUA obiecte per varianta:
  Cliff_X      — mesh-ul vizual
  Cliff_X_col  — cutie de coliziune simplificata (8 varfuri)

De ce cutie si nu hull din mesh-ul vizual: o sectiune cu varf plat si spate in
trepte are un convex hull care umfla baza spre exterior, si mai ales creeaza
colturi intre sectiuni vecine in care Jolt agata masina. Cutia urmareste doar
FATA dinspre drum, unde se produce de fapt contactul.
"""

import math
import bpy

# Latimea unei sectiuni. Pasul de asezare in Godot e 14 m, deci sectiunile se
# suprapun 1 m — fara suprapunere raman fisuri, si vizuale, si de coliziune.
WIDTH = 15.0
# Fatete late, nu detaliu de frecventa inalta (style_bible §3). Cifrele sunt
# strans legate de buget: bevel-ul de stanca (0.15) adauga o banda de geometrie
# la FIECARE muchie, deci corpul principal se plateste de doua ori.
#
# Istoric: 6x4 (~195 tris/sectiune) pe vremea plafonului de 80k — o prisma
# hexagonala flat-shaded, sursa principala a aspectului "coltoros" reclamat la
# toate pistele. La 10x6 + shade smooth silueta ramane low-poly dar lumina
# curge continuu (issue #94); bugetul real e alarma de 150k din probe_decor,
# iar pistele stau la 21-65k.
SIDES = 10
STRATA = 6          # inele orizontale = straturi de roca sedimentara


def cliff_body(b, height, depth, seed):
    """Corpul falezei: o masa de roca lata si joasa, cu straturi orizontale.

    Fata dinspre drum (Y negativ in Blender) e aproape verticala; spatele cade in
    trepte. Asa silueta citeste ca perete de canion din masina, dar nu costa
    triunghiuri pe partea care nu se vede niciodata.
    """
    # Corpul principal, retezat sus: silueta de mesa (style_bible §3).
    #
    # O singura masa, nu corp + poala la baza. Poala ar fi ascuns linia de contact
    # cu nisipul, dar costa ~55 tris per sectiune (a treia parte din buget) pentru
    # ceva ce AO-ul de teren rezolva gratis: terenul se intuneca in jurul bazei
    # falezei si da aceeasi senzatie de "infipt in sol".
    #
    # Inelul de jos primeste slotul inchis prin AO, nu prin geometrie separata.
    b.rock((0.0, 0.0, -0.4), (WIDTH, depth, height + 0.4), ROCK_LIGHT,
           seed=seed, segments=SIDES, rings=STRATA, flat_top=True,
           # taper mic + perete vertical pe -Y: fata dinspre drum sta dreapta
           # (75-85°, ca in brief), spatele se retrage. Cu taper mare iesea o
           # movila conica, nu un perete de canion.
           taper=0.16, squash=0.88, wall_axis="y",
           # Strate sedimentare pe inele: variatia de VALOARE la scara de ~2 m,
           # pe care stratul de detaliu triplanar (fin, ~0.7 m) n-o poate da.
           # Cele doua lucreaza impreuna — banda mare din geometrie, textura
           # fina din material. Ordinea urca de la inchis la deschis: roca
           # veche jos, expusa sus. Sase intrari pentru sase inele, ca
           # progresia sa nu se reia de la capat la mijlocul peretelui.
           strata_slots=(ROCK_DARK, ROCK_DARK, ROCK_LIGHT, SAND_SHADOW,
                         ROCK_LIGHT, ROCK_LIGHT))


def cliff_cap(b, height, depth, seed):
    """Coama: o lespede subtire pe varf, in nisip deschis.

    Vinde "varful ars de soare" fara sa coste: la 4 laturi si un inel, e cea mai
    ieftina piesa care rupe silueta.
    """
    # Asezata ca sa se INTERSECTEZE cu corpul (nu deasupra lui): la varf lat de
    # perete, o lespede care doar atinge muchia pluteste vizibil.
    b.rock((0.0, -depth * 0.10, height * 0.72),
           (WIDTH * 0.80, depth * 0.70, height * 0.20),
           SAND_LIGHT, seed=seed + 313, segments=4, rings=1, flat_top=True,
           taper=0.25)


def build_visual(name, height, depth, seed):
    b = Builder()
    cliff_body(b, height, depth, seed)
    cliff_cap(b, height, depth, seed)
    obj = b.to_object(name)
    stats = finish(
        obj,
        bevel=0.15,           # style_bible §3: bevel de stanca
        # 62°: la 10 laturi fatetele se intalnesc la 36°, dar treptele spatelui
        # si racordul cu lespedea urca peste 40° — pragul de roca le topeste pe
        # toate si lasa sharp doar buza de mesa (~90°).
        smooth_angle=62.0,
        # AO puternic la baza: falezele n-au umbre dinamice in joc (decizie de
        # buget mobil), deci tot volumul vine de aici. Fara AO agresiv arata ca
        # un decal plat lipit langa drum.
        ao=dict(samples=28, dist=3.2, gradient="vertical",
                low=0.42, high=1.0, power=0.75, floor=0.28),
        origin="base",
    )
    return obj, stats


def build_collision(name, height, depth):
    """Cutie simpla care acopera fata dinspre drum.

    Deliberat mai ingusta decat mesh-ul vizual pe Y: masina trebuie sa se opreasca
    in PERETE, nu in poala care iese din el. Si deliberat putin mai lata pe X decat
    pasul de asezare, ca sa se suprapuna cu vecinele.
    """
    b = Builder()
    b.box((0.0, -depth * 0.18, height * 0.5),
          (WIDTH * 1.02, depth * 0.5, height), ROCK_LIGHT)
    obj = b.to_object(name)
    finish(obj, bevel=0.0, ao=dict(samples=4, dist=0.5, gradient="none"),
           origin="base")
    return obj


# (nume, inaltime, adancime, seed). Inaltimile acopera intervalul 6.5-11.5 m din
# style_bible §2; Godot alege varianta cu inaltimea nominala cea mai apropiata si
# scaleaza cel mult ±18% (peste atat se vede intinderea straturilor).
CLIFFS = [
    ("Cliff_A", 6.5, 5.0, 11),
    ("Cliff_B", 8.0, 6.0, 27),
    ("Cliff_C", 9.5, 6.5, 43),
    ("Cliff_D", 11.0, 7.5, 61),
    ("Cliff_E", 7.5, 5.5, 79),
    ("Cliff_F", 10.0, 7.0, 97),
]

clear_built("Cliff_")
built = []
total_vis = 0
for i, (name, h, d, seed) in enumerate(CLIFFS):
    obj, stats = build_visual(name, h, d, seed)
    col = build_collision(name + "_col", h, d)
    total_vis += stats["tris"]
    obj.location = (i * 17.0, 0.0, 0.0)   # doar pentru viewport
    col.location = (i * 17.0, 0.0, 0.0)
    built.extend([obj, col])
    print("%-10s h=%5.2f  vizual %3d tris  coliziune %2d tris | AO %.2f..%.2f"
          % (name, h, stats["tris"], tri_count(col),
             stats["ao_min"], stats["ao_max"]))

print("TOTAL vizual: %d tris (10x6 smooth; era 1170 la 6x4 flat)" % total_vis)

# La export toate pleaca din origine: Godot le instantiaza individual.
for o in built:
    o.location = (0.0, 0.0, 0.0)
print("GLB:  %s (%d B)" % export_glb(built, "cliff_wall.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "cliff_wall.blend"))
for i, o in enumerate(built):
    o.location = ((i // 2) * 17.0, 0.0, 0.0)
