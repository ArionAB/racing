"""start_gate.glb — poarta de start/sosire. Brief: docs/asset_briefs/start_gate.md · issue #B3

Inlocuieste `start_arch.glb`, arcada de jucarie din tema abandonata "lada de
nisip". Apare pe TOATE pistele, fara verificare de tema, si e primul lucru pe
care il vezi la countdown — deci si cel mai vizibil asset gresit din joc.

COTELE SUNT CONTRACT: 22.800 x 8.700 m. Godot are patru numere derivate din
bbox-ul modelului, hardcodate in track.gd:1499-1511, si zero citiri de AABB. Un
model de alta marime se scaleaza gresit si isi pierde coliziunea, in tacere.

Fata (partea pe care ar scrie START) priveste spre +Y in Blender = -Z in Godot.

Buget: 950 de triunghiuri, si aici s-a dat toata bataia. Vezi NOTA DE BUGET.
"""

import math
from mathutils import Vector

# --- Cotele care sunt contract -----------------------------------------------
HALF_WIDTH = 11.40                # marginea exterioara a pastilelor de beton
TOTAL_H = 8.70                    # varful montantilor

PAD = 2.40                        # latura pastilei de beton
PAD_H = 0.50
PYLON_X = HALF_WIDTH - PAD * 0.5  # = 10.20; pastila e cea care atinge ±11.400

# Turn evazat: amprenta 1.8 x 1.8 la sol, 1.1 x 1.1 sus. Pastila ramane mai lata
# decat baza turnului — asa se citeste ca fundatie, nu ca prelungire.
FOOT, TOPW = 0.90, 0.55
# Brieful cere montanti de ~0.20 m. La prima captura din unghi de sofer (34 m) au
# iesit tije: turnul citea a schela, nu a structura care tine o traversa de 20 m.
# Grosimea nu costa NICIUN triunghi — o cutie are 12 fete indiferent cat e de
# groasa — deci singurul motiv sa fii zgarcit aici ar fi estetic, si e invers.
POST_T = 0.32
CAP_H = 0.34                      # capacul care leaga cei patru montanti sus

# Montantii urca pana la inaltimea totala si trec DINCOLO de traversa cu 0.65 m.
# Brieful cerea in schimb un finial peste fiecare turn; vezi abaterile.
BEAM_LO, BEAM_HI = 7.20, 8.05     # traversa

PANEL_W, PANEL_H, PANEL_T = 9.00, 2.20, 0.25
PANEL_BOTTOM = 5.30               # degajarea sub panou — MINIMUL absolut
PANEL_Z = PANEL_BOTTOM + PANEL_H * 0.5
BAND_H = 0.70

SIDE_W, SIDE_H, SIDE_T = 2.50, 1.60, 0.22
SIDE_X = 7.20                     # intre pilon si panoul central

BEVEL = 0.05
POST_TOP = TOTAL_H


def snap_bbox(obj, target_x, target_z):
    """Forteaza bbox-ul pe cotele contractuale si intoarce corectia aplicata.

    Bevel-ul cu `miter_outer = MITER_ARC` umfla varfurile cu cativa milimetri
    peste fata plana: constructia la 8.700 iese 8.707. Turnul de apa rezolva asta
    cu doua constante ajustate de mana (`build_water_tower.py`, FINIAL_TOP =
    9.486), si e o solutie fragila — epsilonul depinde de latimea bevel-ului, de
    unghi si de geometria din jur, deci se strica tacut la prima retusare. Aici
    cotele sunt CONTRACT (track.gd are patru numere hardcodate derivate din ele),
    asa ca se masoara si se corecteaza, in loc sa se ghiceasca.

    Corectia e de ordinul 0.03% — sub grosimea unui bevel.
    """
    me = obj.data
    out = []
    for axis, target in ((0, target_x), (2, target_z)):
        vals = [v.co[axis] for v in me.vertices]
        span = max(vals) - min(vals)
        s = target / span
        for v in me.vertices:
            v.co[axis] *= s
        out.append((span, s))
    return out


# --- NOTA DE BUGET ------------------------------------------------------------
# Brieful cere turnuri zabrelite: 4 montanti de colt + DOUA inele orizontale +
# o diagonala pe fiecare fata. Masurat, la bevel 0.05:
#
#   brief integral (4 stalpi + 2 inele + 4 diagonale)   492 brut -> 1804
#   2 inele, 2 diagonale                                444 brut -> 1628
#   1 inel,  2 diagonale                                348 brut -> 1276
#   1 inel,  0 diagonale                                300 brut -> 1100
#   0 inele, 0 diagonale                                204 brut ->  748
#
# Multiplicatorul e 3.67x, constant pe toate cele cinci — acelasi numar masurat
# pe plansa de ajutoare din #46, si nu e o coincidenta: un cub de 12 triunghiuri
# beveluit pe toate muchiile da 6 fete (12) + 12 quad-uri de muchie (24) + 8
# triunghiuri de colt = 44.
#
# Brieful e deci cu 90% peste buget, si NICI MACAR un singur inel nu incape.
# Bugetul brut util e 950 / 3.67 = 258 de triunghiuri — cam 21 de cutii pentru
# toata poarta. Repartitia finala, 252 brut:
#
#   2 piloni x (4 montanti + 2 diagonale + pastila + capac) 192
#   traversa                                                 12
#   panou central + banda                                    24
#   2 panouri laterale                                       24
#
# Ce am pastrat din zabrele: montantii de colt si DOUA diagonale per pilon (fata
# si spate). Diagonalele au fost preferate inelelor pentru ca inelele sunt
# orizontale, adica paralele cu traversa si cu panoul, deci nu adauga nicio
# directie noua in silueta; diagonala e singura linie inclinata din tot obiectul
# si e cea care spune "structura", nu "gard".


def pylon(b, cx):
    """Un turn evazat. `at()` interpoleaza amprenta pe inaltime, deci montantii
    sunt inclinati, nu verticali — evazarea e ce da portii greutate la baza."""
    corners = [(-1, -1), (1, -1), (1, 1), (-1, 1)]

    def at(sx, sy, z):
        w = FOOT + (TOPW - FOOT) * (z / POST_TOP)
        return (cx + sx * w, sy * w, z)

    for sx, sy in corners:
        b.beam(at(sx, sy, 0.0), at(sx, sy, POST_TOP), POST_T, RUST)

    # Diagonale doar pe fetele dinspre ±Y: alea sunt fetele pe care le vezi cand
    # treci pe sub poarta. Fetele dinspre ±X se vad din muchie de la nivelul
    # soferului, deci o diagonala acolo ar costa 88 de triunghiuri pentru cativa
    # pixeli.
    for k in (0, 2):
        a, c = corners[k], corners[(k + 1) % 4]
        b.beam(at(a[0], a[1], 0.55), at(c[0], c[1], POST_TOP - 0.55),
               POST_T * 0.85, RUST)

    b.box((cx, 0.0, PAD_H * 0.5), (PAD, PAD, PAD_H), CONCRETE)

    # Capacul. Prima captura din unghi de sofer a aratat problema pe care nota de
    # buget o crease: fara inele, cei patru montanti se citeau ca patru bete
    # separate, iar varfurile ramaneau cioturi peste traversa. Capacul le leaga
    # sus cu o singura cutie — 12 triunghiuri fac ce 96 (un inel) n-ar fi incaput
    # sa faca. Plata: panourile laterale au coborat de la doua casete la una.
    cap_w = 2.0 * TOPW + POST_T * 1.6
    b.box((cx, 0.0, POST_TOP - CAP_H * 0.5), (cap_w, cap_w, CAP_H), RUST)


clear_built("StartGate")
b = Builder()

for cx in (-PYLON_X, PYLON_X):
    pylon(b, cx)

# Traversa: se opreste in axele turnurilor, nu le traverseaza.
b.box((0.0, 0.0, (BEAM_LO + BEAM_HI) * 0.5),
      (2.0 * PYLON_X, 0.45, BEAM_HI - BEAM_LO), RUST)

# Panoul central.
b.box((0.0, 0.0, PANEL_Z), (PANEL_W, PANEL_T, PANEL_H), SAND_LIGHT)
# Banda: o cutie subtire iesita in FATA (+Y), nu un retag. Un retag ar fi costat
# zero, dar fata din fata a panoului e UN SINGUR quad — n-are ce sa fie
# re-etichetat pe jumatate. Iesirea de 8 cm isi plateste triunghiurile: face
# umbra proprie, deci banda se citeste si cand soarele bate din spatele portii.
b.box((0.0, (PANEL_T + 0.08) * 0.5, PANEL_Z), (PANEL_W, 0.16, BAND_H), KERB_RED)

# Panourile laterale. Brieful cere 4x3 patrate alternante per panou, adica 12
# quad-uri coplanare; masurat, asta inseamna 24 de casete = 288 brut = 1057 dupa
# bevel — mai mult decat toata poarta. `corrugate` parea iesirea ieftina si nu
# e: un panou costa 52 brut (doua ngon-uri de capac cat toata suprafata utila).
#
# Ce a incaput: o singura caseta per panou. Ritmul de culoare peste tot ansamblul
# ramane rosu | deschis-cu-banda-rosie | rosu — alternanta se citeste, doar ca la
# scara panourilor, nu a patratelor. Un sah de 4x3 pe 2.5 m inseamna patrate de
# 0.6 m, adica exact detaliul de frecventa inalta pe care style_bible §3 il
# interzice: la 100 m se topeste intr-o pata oricum.
for sx in (-1.0, 1.0):
    b.box((sx * SIDE_X, 0.0, PANEL_Z), (SIDE_W, SIDE_T, SIDE_H), KERB_RED)

obj = b.to_object("StartGate")
stats = finish(
    obj,
    bevel=BEVEL, bevel_angle=30.0,
    ao=dict(samples=28, dist=3.0, gradient="vertical",
            low=0.52, high=1.00, power=0.9, floor=0.14),
)

corr = snap_bbox(obj, 2.0 * HALF_WIDTH, TOTAL_H)
set_origin_base(obj, center_xy=True)   # snap-ul se face pe bbox, deci re-centram
print("  corectie de bevel    : X %.4f m -> x%.5f | Z %.4f m -> x%.5f"
      % (corr[0][0], corr[0][1], corr[1][0], corr[1][1]))

me = obj.data
ext = [(min(v.co[a] for v in me.vertices), max(v.co[a] for v in me.vertices))
       for a in range(3)]
w, d, h = (ext[a][1] - ext[a][0] for a in range(3))
print("StartGate  %d tris (buget 950) | AO %.2f..%.2f"
      % (stats["tris"], stats["ao_min"], stats["ao_max"]))
print("  latime   (Blender X) : %.4f m  [contract 22.8000]  %s"
      % (w, "OK" if abs(w - 22.8) < 1e-4 else "ABATERE"))
print("  inaltime (Blender Z) : %.4f m  [contract  8.7000]  %s"
      % (h, "OK" if abs(h - 8.7) < 1e-4 else "ABATERE"))
print("  adancime (Blender Y) : %.3f m" % d)
print("  degajare sub panou   : %.3f m   [minim 5.300]" % PANEL_BOTTOM)
print("  degajare sub traversa: %.3f m" % BEAM_LO)

obj.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb([obj], "start_gate.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "start_gate.blend"))
