"""rock_arch.glb — arcada naturala de stanca peste sosea.
Brief: docs/asset_briefs/rock_arch.md · issue #C1

Singurul landmark din tot proiectul prin care TRECI, nu pe langa care treci.
Celelalte patru de pe Dunele (turnul de apa, benzinaria, moara, semnul Route 66)
au toate acelasi defect.

Cinci obiecte:
  Arch_L, Arch_R      picioarele (vizuale)
  Arch_Span           traversa
  Arch_L_col, Arch_R_col   proxy de coliziune, cate o cutie fiecare

NUMELE DE COLIZIUNE: brieful cere un singur obiect `Arch_col` cu doua cutii;
issue-ul cere perechile `Arch_L_col` / `Arch_R_col`. Codul decide, si e de partea
issue-ului: `scenes/tracks/track_cliffs.gd:291` face
`_extract(scene, node_name + "_col")`, deci convenția e `X` <-> `X_col`, per nod
vizual. Un `Arch_col` unic ar fi cerut cod nou pentru un caz special.

ORIGINEA E COMUNA. Brieful spune "originea la baza, centrata in XZ, pentru
fiecare din cele patru" SI "centrul XZ = mijlocul deschiderii". A doua e cea
corecta: daca fiecare piesa s-ar recentra pe bbox-ul ei, cele trei mase s-ar
suprapune in acelasi punct la instantiere si arcada s-ar prabusi intr-un morman.
Toate piesele impart originea din mijlocul deschiderii, la nivelul solului.

Axa deschiderii (directia drumului) e Y in Blender; picioarele sunt separate pe X.
"""

import math
from mathutils import Vector

# --- Cotele de gameplay, care sunt contract ----------------------------------
MIN_OPENING = 20.0        # deschidere libera intre picioare, la baza
MIN_CLEAR = 9.0           # degajare verticala pe toata deschiderea
ROAD_HALF = 7.0           # half_width al soselei; umerii ies dincolo

L_X, R_X = -16.4, 14.6    # centrele picioarelor
L_H, R_H = 11.6, 12.4     # inaltimi pana la nastere; picioarele TREBUIE sa
                          # intre in traversa, altfel arcada pluteste
SPAN_Z = 12.60            # centrul traversei
SPAN_HALF_H = 3.10
SKIRT = 1.20              # cat iese poala de grohotis peste amprenta. Era 1.34
                          # si manca 1.5 m din deschidere pe fiecare parte.

STRATA = (ROCK_LIGHT, ROCK_DARK, ROCK_LIGHT, SAND_SHADOW)

BEVEL = 0.15
# Masurat pe geometria asta, 438 de triunghiuri brute, la bevel 0.15:
#
#   prag 30° (implicit)   984   x2.25
#   prag 45°              790   x1.80
#   prag 55°              676   x1.54
#   prag 65°              630   x1.44
#   prag 75°              628   x1.43
#
# Multiplicatorul e 2.25, nu 3.67 ca pe cutii: `rock()` are multe muchii
# superficiale intre inele, pe care pragul implicit le sare deja. Deci si
# varianta cea mai generoasa ar fi incaput — dar 984 din 1000 nu e o marja, e o
# coincidenta care se strica la prima retusare de perturbatie. La 45° silueta e
# aceeasi (muchiile sarite in plus sunt tot cele dintre benzile de strat, care
# trebuie sa ramana nete oricum) si raman 210 de triunghiuri de rezerva.
BEVEL_ANGLE = 45.0


def leg(b, cx, foot_x, foot_y, height, seed, cap_frac=0.62):
    """Un picior din DOUA mase suprapuse plus poala de grohotis.

    Brieful cere 2-3 mase care se intrepatrund, nu o forma continua: o singura
    masa citeste ca o movila, iar intrepatrunderea e ce da silueta de stanca
    erodata (acelasi tipar ca la rock_cluster.glb).
    """
    b.rock((cx, 0.0, 0.0), (foot_x, foot_y, height), ROCK_LIGHT,
           seed=seed, segments=8, rings=5, taper=0.16, squash=0.94,
           flat_top=True, strata_slots=STRATA)
    # Masa a doua, decalata si mai zvelta: rupe conturul si continua
    # stratificarea. Decalajul e spre EXTERIOR (`copysign`) — prima versiune il
    # ducea spre +X pe amandoua, adica spre interior pe piciorul stang, unde
    # manca din deschidere.
    b.rock((cx + math.copysign(foot_x * 0.17, cx), foot_y * 0.10, height * cap_frac),
           (foot_x * 0.68, foot_y * 0.66, height * 0.58), ROCK_LIGHT,
           seed=seed + 13, segments=8, rings=2, taper=0.12, squash=0.97,
           flat_top=True, strata_slots=STRATA)
    # poala de grohotis: o treapta joasa in jurul bazei
    b.rock((cx, 0.0, 0.0), (foot_x * SKIRT, foot_y * (SKIRT - 0.04), 1.60), SAND_MID,
           seed=seed + 29, segments=8, rings=1, taper=0.55, squash=0.7)


def span(b):
    """Traversa: un LANT de mase inchise, nu o singura forma.

    `boulder()` (adaugat la #B2 pentru bolovanul rostogolitor) e primitiva
    potrivita si `rock()` nu e: `rock()` inchide cu doua capace plate, iar
    capacul de jos ar fi insemnat un intrados PLAT de 25 m — exact ce brieful
    interzice, fiindca o traversa cu fund drept citeste a pod de beton.

    Dar UN singur elipsoid intins pe 36 m e la fel de gresit, si asta s-a vazut
    abia la render: iese o lentila cu varfuri ascutite la capete, adica o
    farfurie zburatoare asezata pe doua cutii de conserva. Trei mase suprapuse
    dau o grinda neregulata, cu capetele ingropate in picioare — si rezolva
    totodata cererea brieului ca traversa sa fie mai groasa la nasteri decat la
    cheie, fiindca masele de la capete stau mai jos si se contopesc cu turnurile.
    """
    mid = (L_X + R_X) * 0.5
    reach = (R_X - L_X) * 0.5
    faces = set()
    for k, (fx, sx, sy, sz, dz, seed) in enumerate((
            (-0.84, 18.0, 9.4, 6.6, -0.55, 907),   # nastere stanga, mai jos
            (0.02, 23.0, 10.2, 5.9, 0.35, 941),    # cheia, mai subtire si mai sus
            (0.86, 16.5, 8.6, 6.4, -0.40, 977))):  # nastere dreapta
        faces |= b.boulder((mid + fx * reach, 0.0, SPAN_Z + dz), (sx, sy, sz),
                           ROCK_LIGHT, seed=seed, segments=7, rings=3,
                           deviation=0.17, strata_slots=STRATA)
    # Intradosul: fetele orientate in jos primesc slotul cel mai inchis dintre
    # cele de stanca. Umbra de sub arcada e ce o face sa para GREA, si nu se
    # poate obtine din AO copt — razele trase in jos de sub traversa nu
    # intalnesc nimic, deci ocluzia geometrica acolo e practic zero.
    b.retag(faces, SAND_SHADOW, where="down")
    return faces


def col_box(name, cx, size_x, size_y, height):
    """Proxy de coliziune: o cutie, deliberat mai mica decat vizualul.

    Tiparul e din build_cliff_wall.py:94-107. Mai mica cu ~0.4 m pe latura:
    masina trebuie sa se opreasca in stanca, nu in poala de grohotis care iese
    din ea. Inaltime pana la 8 m — peste atat nu ajunge nicio masina, iar
    traversa NU primeste coliziune deloc: o forma concava acolo e o capcana.
    """
    b = Builder()
    b.box((cx, 0.0, height * 0.5), (size_x, size_y, height), ROCK_LIGHT)
    return b, name


clear_built("Arch_")

bL, bR, bS = Builder(), Builder(), Builder()
leg(bL, L_X, 9.4, 7.2, L_H, seed=101)                 # gros si eroziat
leg(bR, R_X, 6.2, 5.4, R_H, seed=223, cap_frac=0.66)  # mai zvelt
span_faces = span(bS)

VISUALS = [("Arch_L", bL), ("Arch_R", bR), ("Arch_Span", bS)]
COLS = [col_box("Arch_L_col", L_X, 8.6, 6.4, 8.0),
        col_box("Arch_R_col", R_X, 5.4, 4.6, 8.0)]


def inner_edges(builders):
    """Marginile dinspre drum ale picioarelor, sub plafonul de degajare."""
    lo, hi = -1e9, 1e9
    for b in builders:
        for v in b.bm.verts:
            if v.co.z > MIN_CLEAR or abs(v.co.y) > ROAD_HALF + 4.0:
                continue
            if v.co.x < (L_X + R_X) * 0.5:
                lo = max(lo, v.co.x)
            else:
                hi = min(hi, v.co.x)
    return lo, hi


# --- originea comuna ----------------------------------------------------------
# Se calculeaza o SINGURA data si se aplica la toate piesele; `finish(origin=
# "base")` per piesa ar recentra fiecare masa pe ea insasi si arcada s-ar
# prabusi intr-un morman la instantiere.
#
# Pe X se centreaza pe DESCHIDERE, nu pe gabarit. Cu picioare asimetrice — si
# asimetria e ceruta de brief — cele doua sunt lucruri diferite: prima versiune
# centra pe gabarit si golul iesea decalat cu 2 m fata de origine, adica drumul
# ar fi trecut lipit de piciorul din dreapta.
il0, ir0 = inner_edges([bL, bR])
allv = [v.co for _, b in VISUALS for v in b.bm.verts]
ys = [p.y for p in allv]; zs = [p.z for p in allv]
SHIFT = Vector((-(il0 + ir0) * 0.5, -(min(ys) + max(ys)) * 0.5, -min(zs)))
for _, b in VISUALS + [(n, b) for b, n in COLS]:
    for v in b.bm.verts:
        v.co += SHIFT

objs = []
for name, b in VISUALS:
    obj = b.to_object(name)
    stats = finish(
        obj, bevel=BEVEL, bevel_angle=BEVEL_ANGLE, origin="none",
        ao=dict(samples=28, dist=6.0, gradient="vertical",
                low=0.45, high=1.00, power=0.8, floor=0.13))
    print("%-10s %4d tris | AO %.2f..%.2f" % (name, stats["tris"],
                                              stats["ao_min"], stats["ao_max"]))
    objs.append(obj)

col_objs = []
for b, name in COLS:
    obj = b.to_object(name)
    finish(obj, bevel=0.0, origin="none",
           ao=dict(samples=4, dist=0.5, gradient="none"))
    col_objs.append(obj)

vis_total = sum(tri_count(o) for o in objs)
col_total = sum(tri_count(o) for o in col_objs)
print("VIZUAL: %d tris (buget 1000) %s | COLIZIUNE: %d (buget 24) %s"
      % (vis_total, "OK" if vis_total <= 1000 else "DEPASIT",
         col_total, "OK" if col_total <= 24 else "DEPASIT"))


# --- garda de gameplay --------------------------------------------------------
# Deschiderea si degajarea sunt cote de care depinde daca pista e jucabila, deci
# se MASOARA pe geometria exportata, nu se deduc din constantele de constructie:
# `rock()` perturba razele, asa ca amprenta reala nu e cea ceruta.
def measure_gate():
    legs = [o for o in objs if o.name != "Arch_Span"]
    sp = next(o for o in objs if o.name == "Arch_Span")

    # deschiderea: cel mai ingust gol dintre picioare, pe orice inaltime sub
    # plafonul de degajare (peste atat nu mai conteaza, masina nu ajunge)
    inner_l, inner_r = -1e9, 1e9
    for o in legs:
        for v in o.data.vertices:
            if v.co.z > MIN_CLEAR or abs(v.co.y) > ROAD_HALF + 4.0:
                continue
            if v.co.x < 0.0:
                inner_l = max(inner_l, v.co.x)
            else:
                inner_r = min(inner_r, v.co.x)
    opening = inner_r - inner_l

    # degajarea: cel mai jos punct al traversei, pe deschidere
    lowest, lowest_x = 1e9, 0.0
    for v in sp.data.vertices:
        if abs(v.co.x) <= opening * 0.5 and abs(v.co.y) <= ROAD_HALF + 2.0:
            if v.co.z < lowest:
                lowest, lowest_x = v.co.z, v.co.x
    return opening, inner_l, inner_r, lowest, lowest_x


opening, il, ir, clear, cx = measure_gate()
print("  deschidere : %.2f m  (intre x=%+.2f si x=%+.2f) [minim %.1f] %s"
      % (opening, il, ir, MIN_OPENING, "OK" if opening >= MIN_OPENING else "PREA INGUST"))
print("  degajare   : %.2f m  (cel mai jos punct al traversei, la x=%+.2f) [minim %.1f] %s"
      % (clear, cx, MIN_CLEAR, "OK" if clear >= MIN_CLEAR else "PREA JOS"))

allo = objs + col_objs
ext = [(min(v.co[a] for o in allo for v in o.data.vertices),
        max(v.co[a] for o in allo for v in o.data.vertices)) for a in range(3)]
print("  gabarit    : %.2f x %.2f x %.2f m, baza la z=%.3f"
      % (ext[0][1] - ext[0][0], ext[1][1] - ext[1][0], ext[2][1] - ext[2][0], ext[2][0]))

for o in allo:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(allo, "rocks/rock_arch.glb"))
print("BLEND: %s (%d B)" % save_blend(allo, "rock_arch.blend"))
