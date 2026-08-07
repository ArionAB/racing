"""gas_pole_sign.glb — stalpul inalt cu stea, in stil benzinarie americana '50.
Brief: docs/asset_briefs/gas_pole_sign.md · issue #C4

Buget: <= 700 triunghiuri. Obiect subtire; nu are nevoie de mai mult.
Fata panoului spre -Z in Godot (= +Y in Blender, vezi nota de axe din dio_lib).

Rolul lui e diferit de al celorlalte landmark-uri: e INALT si SUBTIRE, un semn
de exclamare pe orizont. Benzinaria, moara si turnul de apa sunt toate mase joase
si late; ala e motivul pentru care obiectul asta exista.
"""

import math

# --------------------------------------------------------------------- cote
BASE_W, BASE_H = 2.00, 0.55       # fundatia de beton
POLE_BOT, POLE_TOP = 0.30, 12.25
POLE_R_BOT, POLE_R_TOP = 0.24, 0.16   # diametru 0.48 -> 0.32 m (brief: 0.35-0.5)

PANEL_W, PANEL_H, PANEL_T = 3.80, 2.40, 0.30
PANEL_Z = 9.90                    # panoul: 8.70 .. 11.10, adica treimea de sus

STAR_R, STAR_T = 1.35, 0.28
STAR_Z = 12.40                    # varful de sus al stelei ajunge la 13.75 m

TOTAL_H = STAR_Z + STAR_R         # 13.75 m — mai inalt decat moara (10.1) si
                                  # decat turnul de apa (9.5), cum cere brieful.
# Steaua sta DEASUPRA panoului, cu 0.16 m de cer intre ele si o bucata de stalp
# vizibila: lipite, cele doua citesc ca o singura pata la 200 m, si tocmai
# silueta e testul obiectului.

TILT_DEG = 2.0                    # inclinare spre spate, vezi mai jos
TILT_FROM_Z = BASE_H + 0.05       # fundatia ramane PLANA pe sol

clear_built("GasPole")
b = Builder()

# ----------------------------------------------------------------- fundatie
b.box(center=(0.0, 0.0, BASE_H * 0.5), size=(BASE_W, BASE_W, BASE_H), slot=CONCRETE)

# --------------------------------------------------------------------- stalp
# frustum, nu cylinder: un stalp care se subtiaza spre varf capata directie —
# citeste ca "arata in sus", ceea ce e tot rostul unui accent vertical.
# 8 laturi ajung: la 0.4 m diametru, a 12-a latura e sub un pixel de la 50 m.
b.frustum(center=(0.0, 0.0, (POLE_BOT + POLE_TOP) * 0.5),
          r_bottom=POLE_R_BOT, r_top=POLE_R_TOP,
          depth=POLE_TOP - POLE_BOT, slot=RUST, segments=8)

# Ancore de tensionare: trei contrafise groase, la 120°. Cabluri reale ar fi
# detaliu de frecventa inalta (style_bible §3 — "NU balustrade subtiri"), asa ca
# le citim ca grinzi de 0.20 m, care se vad si de la 60 km/h.
for i in range(3):
    a = math.radians(90.0 + i * 120.0)
    b.beam(p1=(math.cos(a) * 0.92, math.sin(a) * 0.92, BASE_H - 0.10),
           p2=(math.cos(a) * 0.24, math.sin(a) * 0.24, 2.60),
           thickness=0.20, slot=RUST)

# --------------------------------------------------------------------- panou
# Panoul e centrat pe axa stalpului, deci nu are nevoie de brate de sustinere:
# stalpul trece prin spatele lui si imbinarea se rezolva singura.
b.box(center=(0.0, 0.0, PANEL_Z), size=(PANEL_W, PANEL_T, PANEL_H), slot=KERB_RED)

# Aici ar scrie GAS. NU modelam litere: dispar la viteza si style_bible §3 le
# interzice. O banda deschisa peste mijlocul panoului citeste ca text de la
# 200 m si costa 12 triunghiuri inainte de bevel.
b.box(center=(0.0, 0.0, PANEL_Z), size=(PANEL_W - 0.55, PANEL_T + 0.06, 0.62),
      slot=CONCRETE)

# Coaste de rigidizare pe spatele panoului. Aliniate perfect (tilt_jitter=0):
# pe un panou de firma, stramb ar citi ca greseala de constructie, nu ca uzura.
b.pickets(p1=(-PANEL_W * 0.5 + 0.5, -PANEL_T * 0.5 - 0.06, PANEL_Z - PANEL_H * 0.5),
          p2=(PANEL_W * 0.5 - 0.5, -PANEL_T * 0.5 - 0.06, PANEL_Z - PANEL_H * 0.5),
          count_or_step=3, size=(0.16, 0.14, PANEL_H), slot=RUST)

# ---------------------------------------------------------------------- stea
# Elementul memorabil. star_outline() vine din dio_lib (mutat din
# build_gas_station.py). Implicit are un varf in JOS — bun pentru accentul mic
# de pe benzinarie, gresit aici: cu varful in jos silueta de pe orizont are o
# VALE in varf, adica exact opusul semnului de exclamare pe care il vrem.
#
# rotation=90 pune varful in sus. Imbinarea cu stalpul se rezolva singura:
# steaua are atunci o vale in partea de jos, in care intra capatul stalpului,
# flancat de cele doua varfuri inferioare. Costa +0.26 m inaltime, gratis.
b.prism(star_outline(STAR_R, rotation=90.0), STAR_T, KERB_RED,
        center=(0.0, 0.0, STAR_Z))

# ------------------------------------------------------- inclinarea stalpului
# Un semn perfect vertical intr-un desert abandonat arata intretinut. Rotim tot
# ce e DEASUPRA fundatiei in jurul bazei stalpului; fundatia ramane plana pe sol,
# fiindca betonul nu se inclina, pamantul de sub stalp da.
#
# Frustum-ul are varfuri doar pe cele doua inele, deci se inclina curat: inelul
# de jos sta, cel de sus pleaca. Fara discontinuitati de rezolvat.
rot = Matrix.Rotation(math.radians(TILT_DEG), 3, "X")
for v in b.bm.verts:
    if v.co.z > TILT_FROM_Z:
        v.co = rot @ v.co

obj = b.to_object("GasPoleSign")
stats = finish(
    obj,
    bevel=0.06, bevel_angle=30.0,   # intre prop (0.04) si cladire (0.08)
    # origin="base_axis": originea trebuie sa cada pe AXA STALPULUI, nu pe
    # centrul bounding box-ului. Cu stalpul inclinat, centrarea pe bbox ar muta
    # fundatia cu ~23 cm fata de punctul in care o aseaza Godot.
    origin="base_axis",
    ao=dict(samples=48, dist=3.0, gradient="vertical",
            low=0.62, high=1.00, power=1.0, floor=0.15),
)

print("GasPoleSign -> %d tris | AO %.2f..%.2f" % (stats["tris"], stats["ao_min"], stats["ao_max"]))
print("inaltime totala %.2f m | panou %.1f x %.1f la z=%.2f | inclinare %.1f°"
      % (TOTAL_H, PANEL_W, PANEL_H, PANEL_Z, TILT_DEG))
print("GLB:   %s (%d B)" % export_glb([obj], "signs/gas_pole_sign.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "gas_pole_sign.blend"))