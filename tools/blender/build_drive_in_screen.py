"""drive_in_screen.glb — ecran de cinema in aer liber, abandonat.
Brief: docs/asset_briefs/drive_in_screen.md · issue #C3

Buget: <= 900 triunghiuri. Landmark cu cel mai bun raport impact/triunghi din
lot: o silueta imensa si plata pe cer, adica un dreptunghi cu schelet.
Fata ecranului spre -Z in Godot (= +Y in Blender, vezi nota de axe din dio_lib).
"""

import math

# --------------------------------------------------------------------- cote
SCREEN_W = 20.0          # brief: 18-22 m
SCREEN_H = 9.60          # brief: 9-11 m
SCREEN_T = 0.50          # brief: 0.4-0.6 m — trebuie sa aiba corp din unghi

BASE_H = 0.90            # fundatia de beton pe care sta ecranul
BASE_T = 2.60            # adancimea fundatiei: tine si scheletul din spate
TOP_Z = BASE_H + SCREEN_H  # 10.50 m

PANELS = 5               # panouri verticale: seams reale + tinta pentru retag
PANEL_W = SCREEN_W / PANELS

# Ecranul e mai scund decat stalpul cu stea din #C4 (13.2 m) — ala trebuie sa
# ramana cel mai inalt lucru construit de pe pista, ca accent vertical unic.

# Scheletul din spate sta pe -Y (in spatele fetei) si se departeaza de ecran
# spre baza, ca la un panou publicitar real.
TRUSS_Y = -1.05          # planul montantilor
TRUSS_FOOT_Y = -2.20     # unde ating solul picioarele inclinate

clear_built("DriveIn")
b = Builder()

# ------------------------------------------------------------------ fundatie
b.box(center=(0.0, -0.55, BASE_H * 0.5),
      size=(SCREEN_W + 0.60, BASE_T, BASE_H), slot=CONCRETE)

# -------------------------------------------------------------------- ecran
# Cinci panouri in loc de o placa: dau imbinari verticale reale (asa se
# construieste un ecran de drive-in, din tabla nituita), imi lasa fiecare panou
# ca tinta separata pentru retag, si permit taierea coltului rupt fara boolean.
#
# Inaltimile difera cu cativa centimetri: marginea de sus nu mai e o linie
# perfecta, deci silueta pe cer nu citeste ca placeholder.
PANEL_TOP = [TOP_Z, TOP_Z + 0.08, TOP_Z + 0.04, TOP_Z, TOP_Z - 1.35]
# ultimul panou e retezat cu 1.35 m: coltul din dreapta-sus lipseste

# Corpul panourilor sta pe SAND_MID: laterale si spate raman calde si mai
# inchise, deci grosimea de 0.5 m se citeste ca umbra proprie din unghi.
panels = []
for i in range(PANELS):
    x = -SCREEN_W * 0.5 + PANEL_W * (i + 0.5)
    top = PANEL_TOP[i]
    f = b.box(center=(x, 0.0, (BASE_H + top) * 0.5),
              size=(PANEL_W - 0.04, SCREEN_T, top - BASE_H), slot=SAND_MID)
    panels.append(f)

# Bucata lipsa din margine: un ciob triunghiular sub retezatura, ca ruptura sa
# arate a metal smuls, nu a taietura de ferastrau.
CHIP_X = SCREEN_W * 0.5 - PANEL_W
chip = b.prism([(0.0, 0.0), (PANEL_W - 0.04, 0.0), (PANEL_W - 0.04, 0.95)],
               SCREEN_T, SAND_MID,
               center=(CHIP_X, 0.0, PANEL_TOP[4]))

# Fata spre +Y = cea mai deschisa suprafata din scena, ca sa se decupeze pe cer.
#
# Brieful lasa la alegere SAND_LIGHT (0) sau CONCRETE (8); am ales CONCRETE
# dupa randare. SAND_LIGHT e din aceeasi familie cu terenul, deci fata ecranului
# se topea in nisipul de sub el; CONCRETE e singurul deschis NEUTRU din paleta si
# se decupeaza si pe cerul albastru, si pe nisip. E si adevarul obiectului: un
# ecran de drive-in e vopsit alb, nu culoarea desertului.
front = (lambda c, n: n.y > 0.5)
for f in panels:
    b.retag(f, CONCRETE, where=front)
b.retag(chip, CONCRETE, where=front)

# Decolorare neuniforma: doua panouri raman pe SAND_MID si pe fata. Zero
# triunghiuri (dio_lib.retag), dar rupe suprafata de 190 m² care altfel citeste
# ca plastic (style_bible §4 — culorile plate, nu poligonajul, sunt problema).
b.retag(panels[1], SAND_MID, where=front)
b.retag(panels[4], SAND_MID, where=front)

# Rama de sus: o lisa care da muchie ecranului si ascunde capetele panourilor.
# Se opreste inainte de panoul retezat — de acolo a plecat bucata lipsa.
b.box(center=(-PANEL_W * 0.5, 0.0, TOP_Z + 0.20),
      size=(SCREEN_W - PANEL_W, SCREEN_T + 0.16, 0.28), slot=RUST)

# ------------------------------------------------------------------ schelet
# Ce scoate obiectul din "dreptunghi lipit pe cer": la trecerea pe langa el,
# cadrul se schimba si apare structura. E jumatatea de asset pe care o vezi
# doar din trei sferturi.

# Montanti verticali, exact aliniati (tilt_jitter=0): un panou publicitar
# stramb ar arata a greseala de constructie, nu a vechime.
b.pickets(p1=(-SCREEN_W * 0.5 + 1.6, TRUSS_Y, 0.0),
          p2=(SCREEN_W * 0.5 - 1.6, TRUSS_Y, 0.0),
          count_or_step=3, size=(0.34, 0.34, TOP_Z - 0.6), slot=RUST)

# Doua traverse orizontale care leaga montantii de ecran
for z in (3.10, 7.40):
    b.box(center=(0.0, TRUSS_Y * 0.5, z),
          size=(SCREEN_W - 2.2, 0.26, 0.26), slot=RUST)

# Diagonalele — semnatura panoului publicitar. Grinzi groase, un singur X pe
# toata latimea: style_bible §3 interzice ferma fina, care s-ar transforma in
# zgomot la 60 km/h.
for sign in (+1, -1):
    b.beam(p1=(sign * (SCREEN_W * 0.5 - 1.8), TRUSS_Y, TOP_Z - 1.2),
           p2=(-sign * (SCREEN_W * 0.5 - 1.8), TRUSS_FOOT_Y, 0.35),
           thickness=0.30, slot=RUST)

# ------------------------------------------------------------------ difuzoare
# Doi stalpi de difuzor in fata. Brief-ul ii da optionali ("se pierd, sunt
# aproape de sol") — ii tin fiindca dau scara: doi stalpi de 1.3 m in fata unui
# perete de 10.5 m spun cat de mare e peretele. Fara ei, ecranul poate fi orice.
for dx in (-4.6, 5.2):
    # 0.22 m grosime, nu 0.16: sub atat citeste ca sarma si intra in
    # "detaliu de frecventa inalta" interzis de style_bible §3
    b.box(center=(dx, 3.40, 0.60), size=(0.22, 0.22, 1.20), slot=WOOD)
    b.box(center=(dx, 3.40, 1.32), size=(0.38, 0.28, 0.32), slot=RUST)

obj = b.to_object("DriveInScreen")
stats = finish(
    obj,
    bevel=0.08, bevel_angle=30.0,   # clasa "cladiri" din style_bible §3
    # 64 de esantioane, nu 32: peretele are 190 m² de suprafata continua, iar la
    # 32 zgomotul de raycast se vede ca stropi sub traverse (masurat in randare)
    # Gradient vertical slab (0.72, nu 0.55 ca la turnuri): un perete plat n-are
    # ce sa-si ocluzeze la baza, iar cu gradient tare fata inceta sa mai fie cea
    # mai deschisa suprafata din cadru — adica exact rostul obiectului.
    ao=dict(samples=64, dist=4.0, gradient="vertical",
            low=0.72, high=1.00, power=1.0, floor=0.18),
)

print("DriveInScreen -> %d tris | AO %.2f..%.2f" % (stats["tris"], stats["ao_min"], stats["ao_max"]))
print("ecran %.1f x %.1f m, grosime %.2f | varf la %.2f m"
      % (SCREEN_W, SCREEN_H, SCREEN_T, TOP_Z + 0.34))
print("GLB:   %s (%d B)" % export_glb([obj], "drive_in_screen.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "drive_in_screen.blend"))
