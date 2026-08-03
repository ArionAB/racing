"""cliff_wall.glb — 12 sectiuni modulare de faleza. Brief: docs/asset_briefs/cliff_wall.md

Peretii de canion care inlocuiesc zidul rosu de pe marginea soselei. Se aseaza
cap la cap, la pas de 14 m, cu suprapunere de 1 m.

12 variante, nu 6 (august 2026, upgrade-ul grafic): cu 6 mesh-uri x ±18%
scalare la ~130 de instante pe Dunele, ochiul prindea repetitia siluetei in
cateva secunde. Variantele noi difera in SILUETA, nu doar in inaltime: sa in
coama (G), treapta dubla (H), surplomba (I), varf tesit asimetric (J),
crestatura (K), coama dubla joasa (L). Cu oglindirea din Godot ies 24 de
siluete distincte.

Buget: <= 350 triunghiuri per sectiune vizuala (style_bible §3, ridicat de la
200 odata cu plafonul de pista 300k).
Sloturi: rock_light (corp), rock_dark (baza/crapaturi), sand_light (coama).
Cateva variante (G, I, L) folosesc un mix mai inchis — variatie de culoare
coapta in GLB, gratis (aceleasi sloturi de atlas, zero materiale noi).

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
# la FIECARE muchie, deci corpul principal se plateste de doua ori. La 6 laturi
# si 4 straturi iese ~195 tris/sectiune; la 7x5 sarea la 310.
SIDES = 6
STRATA = 4          # inele orizontale = straturi de roca sedimentara


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
           # veche jos, expusa sus.
           strata_slots=(ROCK_DARK, ROCK_LIGHT, SAND_SHADOW, ROCK_LIGHT))


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
        # AO puternic la baza: falezele n-au umbre dinamice in joc (decizie de
        # buget mobil), deci tot volumul vine de aici. Fara AO agresiv arata ca
        # un decal plat lipit langa drum.
        ao=dict(samples=28, dist=3.2, gradient="vertical",
                low=0.42, high=1.0, power=0.75, floor=0.12),
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


# --- Siluetele noi (G-L). Toate refolosesc cliff_body/rock cu wall_axis="y",
# deci fata dinspre drum ramane verticala si contractul de asezare nu se
# schimba. Diferenta e in COAMA — partea pe care o vezi pe cer din masina.

# Mixuri de strate: cel standard si unul mai inchis (variatie de culoare
# coapta, zero materiale noi).
STRATA_STD = (ROCK_DARK, ROCK_LIGHT, SAND_SHADOW, ROCK_LIGHT)
STRATA_DARK = (ROCK_DARK, ROCK_DARK, ROCK_LIGHT, SAND_SHADOW)


def _mass(b, x_frac, w_frac, height, depth, seed, strata=STRATA_STD,
          rings=STRATA, d_frac=1.0):
    """O masa de roca partiala pe latimea sectiunii, cu fata la drum."""
    b.rock((WIDTH * x_frac, 0.0, -0.4),
           (WIDTH * w_frac, depth * d_frac, height + 0.4), ROCK_LIGHT,
           seed=seed, segments=SIDES, rings=rings, flat_top=True,
           taper=0.16, squash=0.88, wall_axis="y", strata_slots=strata)


def build_saddle(b, height, depth, seed):
    """G: sa in coama — doua mase inegale, creasta cade intre ele."""
    _mass(b, -0.22, 0.62, height, depth, seed, strata=STRATA_DARK)
    _mass(b, 0.26, 0.55, height * 0.72, depth, seed + 7,
          strata=STRATA_DARK, rings=3, d_frac=0.9)
    cliff_cap(b, height, depth, seed)


def build_stacked(b, height, depth, seed):
    """H: treapta dubla — mesa pe mesa, cea mai inalta silueta din familie."""
    _mass(b, 0.0, 1.0, height * 0.58, depth, seed)
    # etajul de sus: mai ingust, retras spre spate (+Y), cu propriile strate
    b.rock((WIDTH * 0.08, depth * 0.16, height * 0.50),
           (WIDTH * 0.55, depth * 0.62, height * 0.50), ROCK_LIGHT,
           seed=seed + 13, segments=SIDES, rings=3, flat_top=True,
           taper=0.18, squash=0.9, wall_axis="y", strata_slots=STRATA_STD)
    b.rock((WIDTH * 0.08, depth * 0.13, height * 0.93),
           (WIDTH * 0.38, depth * 0.42, height * 0.10),
           SAND_LIGHT, seed=seed + 313, segments=4, rings=1,
           flat_top=True, taper=0.25)


def build_overhang(b, height, depth, seed):
    """I: surplomba usoara — lespede mai LATA decat varful, iesita spre drum."""
    _mass(b, 0.0, 1.0, height, depth, seed, strata=STRATA_DARK)
    # lespedea depaseste corpul spre -Y (drumul): umbra proprie + silueta in
    # ciuperca plata, fara nicio geometrie pe partea nevazuta
    b.rock((0.0, -depth * 0.20, height * 0.78),
           (WIDTH * 0.94, depth * 0.85, height * 0.16),
           SAND_LIGHT, seed=seed + 313, segments=5, rings=1,
           flat_top=True, taper=0.12)


def build_tilted(b, height, depth, seed):
    """J: varf tesit asimetric — lespedea de coama sta inclinata."""
    _mass(b, 0.0, 1.0, height, depth, seed)
    b.box((0.0, -depth * 0.05, height * 0.80),
          (WIDTH * 0.85, depth * 0.62, height * 0.14), SAND_LIGHT,
          rotation=Matrix.Rotation(math.radians(7.0), 3, "Y"))


def build_notch(b, height, depth, seed):
    """K: crestatura — doua mase aproape egale cu un gol ingust intre ele."""
    _mass(b, -0.27, 0.52, height, depth, seed)
    _mass(b, 0.29, 0.50, height * 0.92, depth, seed + 31, rings=3)
    cliff_cap(b, height * 0.96, depth, seed)


def build_twin(b, height, depth, seed):
    """L: joasa si lata, cu doua coame mici — respiro intre sectiunile inalte."""
    _mass(b, 0.0, 1.0, height * 0.75, depth, seed, strata=STRATA_DARK)
    b.rock((-WIDTH * 0.20, 0.0, height * 0.55),
           (WIDTH * 0.34, depth * 0.6, height * 0.35), SAND_LIGHT,
           seed=seed + 5, segments=5, rings=2, flat_top=True, taper=0.3)
    b.rock((WIDTH * 0.24, depth * 0.05, height * 0.58),
           (WIDTH * 0.26, depth * 0.5, height * 0.28), SAND_LIGHT,
           seed=seed + 11, segments=5, rings=2, flat_top=True, taper=0.3)


def build_visual_kind(name, height, depth, seed, kind):
    if kind == "mesa":
        return build_visual(name, height, depth, seed)
    b = Builder()
    {"saddle": build_saddle, "stacked": build_stacked,
     "overhang": build_overhang, "tilted": build_tilted,
     "notch": build_notch, "twin": build_twin}[kind](b, height, depth, seed)
    obj = b.to_object(name)
    stats = finish(
        obj,
        bevel=0.15,
        ao=dict(samples=28, dist=3.2, gradient="vertical",
                low=0.42, high=1.0, power=0.75, floor=0.12),
        origin="base",
    )
    return obj, stats


# (nume, inaltime, adancime, seed, silueta). Inaltimile acopera 6.0-12.5 m;
# Godot alege varianta cu inaltimea nominala cea mai apropiata si scaleaza cel
# mult ±18% (peste atat se vede intinderea straturilor).
CLIFFS = [
    ("Cliff_A", 6.5, 5.0, 11, "mesa"),
    ("Cliff_B", 8.0, 6.0, 27, "mesa"),
    ("Cliff_C", 9.5, 6.5, 43, "mesa"),
    ("Cliff_D", 11.0, 7.5, 61, "mesa"),
    ("Cliff_E", 7.5, 5.5, 79, "mesa"),
    ("Cliff_F", 10.0, 7.0, 97, "mesa"),
    ("Cliff_G", 9.0, 6.2, 113, "saddle"),
    ("Cliff_H", 12.5, 8.0, 131, "stacked"),
    ("Cliff_I", 7.0, 5.8, 149, "overhang"),
    ("Cliff_J", 10.5, 7.2, 167, "tilted"),
    ("Cliff_K", 8.5, 6.0, 181, "notch"),
    ("Cliff_L", 6.0, 5.2, 199, "twin"),
]

clear_built("Cliff_")
built = []
total_vis = 0
over_budget = []
for i, (name, h, d, seed, kind) in enumerate(CLIFFS):
    obj, stats = build_visual_kind(name, h, d, seed, kind)
    col = build_collision(name + "_col", h, d)
    total_vis += stats["tris"]
    if stats["tris"] > 350:
        over_budget.append((name, stats["tris"]))
    obj.location = (i * 17.0, 0.0, 0.0)   # doar pentru viewport
    col.location = (i * 17.0, 0.0, 0.0)
    built.extend([obj, col])
    print("%-10s h=%5.2f %-9s vizual %3d tris  coliziune %2d tris | AO %.2f..%.2f"
          % (name, h, kind, stats["tris"], tri_count(col),
             stats["ao_min"], stats["ao_max"]))

print("TOTAL vizual: %d tris (buget 12 x 350 = 4200)" % total_vis)
if over_budget:
    print("PESTE BUGET: %s" % over_budget)

# La export toate pleaca din origine: Godot le instantiaza individual.
for o in built:
    o.location = (0.0, 0.0, 0.0)
print("GLB:  %s (%d B)" % export_glb(built, "cliff_wall.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "cliff_wall.blend"))
for i, o in enumerate(built):
    o.location = ((i // 2) * 17.0, 0.0, 0.0)
