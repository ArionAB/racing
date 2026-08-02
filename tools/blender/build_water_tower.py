"""water_tower.glb — turn de apa. Brief: docs/asset_briefs/water_tower.md

Buget: <= 900 triunghiuri. Piesa "hero": silueta mare, zero detaliu fin.

De ce exista fisierul asta (#A3): turnul a fost singurul hero produs de un agent
Blender extern direct din brief, cu GLB-ul comis fara sursa. Adica exact piesa
care se autodeclara sablon pentru toate celelalte era singura care nu respecta
regula din assets/blender/README.md — "sursa reala e scriptul, nu .blend-ul".
Practic, nimeni nu-l putea modifica, iar #D2 era blocat.

Contract de reproducere, fiindca Godot il incarca deja:
  - nodul se numeste `water_tower`, cu litere mici, ca in fisierul vechi
  - inaltimea ramane 9.50 m
  - amprenta ramane sub raza de 2.4 m din `_LANDMARKS` (track.gd) — raza aia NU
    e o masuratoare, e o decizie: vrem sa lovesti picioarele, nu un cilindru
    gras care inghite spatiul dintre ele

Scara si pasarela NU intra aici: sunt scopul lui #D2, iar `dio_lib.ladder()`
exista de la #A1, deci nu mai e nimic de inventat acolo.
"""

import math

# --------------------------------------------------------------------- cote
LEG_TOP = 5.70                    # de unde incepe rezervorul
# 2.28, nu 2.30: bevel-ul umfla fata exterioara a piciorului cu ~11 cm, iar
# `_LANDMARKS` din track.gd da turnului un colizor cilindric de raza 2.4. La 2.30
# picioarele ies 1 cm in afara colizorului. (Modelul vechi iesea 3.9 cm, si era
# si decentrat cu 7 cm pe X.)
FOOT_HALF = 2.28                  # amprenta la sol 4.56 x 4.56 m
HEAD_HALF = 1.40                  # 2.8 x 2.8 m sus — picioare evazate
LEG_T = 0.25

RING_Z = (2.00, 4.00)
RING_T = 0.18

TANK_BOT, TANK_TOP = 5.70, 8.00
TANK_R = 1.50
TANK_SEG = 12                     # brief: 12-14 laturi

ROOF_TOP = 9.20
EAVE_R = 1.70                     # streasina iese peste rezervor
ROOF_TIP_R = 0.20
ROOF_SEG = 10                     # acoperisul suporta mai putine laturi decat
                                  # rezervorul: e conic, deci muchiile lui cad pe
                                  # o panta, nu pe o silueta verticala

# 9.486, nu 9.50: bevel-ul adauga 1.4 cm peste varful finialului, iar contractul
# cu Godot e pe bbox-ul MASURAT, nu pe cota din cod (vezi comentariul din
# track.gd:1405 — inaltimile din tabel erau gresite tocmai fiindca nimeni nu
# compara numarul din dictionar cu geometria).
FINIAL_TOP = 9.486
FINIAL_R = 0.12

TOTAL_H = FINIAL_TOP


def leg_xy(sx, sy, z):
    """Pozitia unui picior la inaltimea z. Picioarele sunt drepte, doar inclinate:
    interpoleaza liniar intre amprenta de jos si cea de sus."""
    t = min(max(z / LEG_TOP, 0.0), 1.0)
    half = FOOT_HALF + (HEAD_HALF - FOOT_HALF) * t
    return (sx * half, sy * half)


CORNERS = ((-1, -1), (+1, -1), (+1, +1), (-1, +1))

clear_built("water_tower")
b = Builder()

# ----------------------------------------------------------------- picioare
for sx, sy in CORNERS:
    x0, y0 = leg_xy(sx, sy, 0.0)
    x1, y1 = leg_xy(sx, sy, LEG_TOP)
    b.beam(p1=(x0, y0, 0.0), p2=(x1, y1, LEG_TOP), thickness=LEG_T, slot=WOOD)

# ---------------------------------------------------- inele de legatura
# Doua inele orizontale, fiecare din patru grinzi intre picioare vecine.
# Metal, nu lemn: brieful pune inelele in aceeasi familie cu rezervorul.
for z in RING_Z:
    pts = [leg_xy(sx, sy, z) for sx, sy in CORNERS]
    for i in range(4):
        (ax, ay), (bx, by) = pts[i], pts[(i + 1) % 4]
        b.beam(p1=(ax, ay, z), p2=(bx, by, z), thickness=RING_T, slot=RUST)

# ------------------------------------------------------------- diagonale
# O SINGURA diagonala groasa per fata, nu ferma fina. style_bible §3: zabrelele
# subtiri dispar la 60 km/h si lasa in urma zgomot, nu structura.
for i in range(4):
    sx0, sy0 = CORNERS[i]
    sx1, sy1 = CORNERS[(i + 1) % 4]
    x0, y0 = leg_xy(sx0, sy0, 0.35)
    x1, y1 = leg_xy(sx1, sy1, LEG_TOP - 0.20)
    b.beam(p1=(x0, y0, 0.35), p2=(x1, y1, LEG_TOP - 0.20),
           thickness=0.20, slot=WOOD)

# ------------------------------------------------------------- rezervor
# `revolve`, nu `cylinder`, exact fiindca revolve inchide DOAR baza: capacul de
# sus al rezervorului ar sta oricum complet sub acoperis (raza 1.50 sub streasina
# de 1.70), deci sunt 37 de triunghiuri pe care nu le vede nimeni niciodata.
b.revolve(profile=[(TANK_R, TANK_BOT), (TANK_R, TANK_TOP)], slot=RUST,
          segments=TANK_SEG, cap_bottom=True)

# --------------------------------------------------------------- acoperis
# frustum, nu revolve: `revolve` inchide doar baza, deci varful conului ar fi
# ramas deschis si finialul ar fi stat peste o gaura (dio_lib.frustum, #A1).
b.frustum(center=(0.0, 0.0, (TANK_TOP + ROOF_TOP) * 0.5),
          r_bottom=EAVE_R, r_top=ROOF_TIP_R, depth=ROOF_TOP - TANK_TOP,
          slot=RUST, segments=ROOF_SEG)

# ---------------------------------------------------------------- finial
# 4 laturi, nu 6: la 0.24 m grosime si 9.2 m inaltime, a cincea latura e sub un
# pixel de la orice distanta de joc. Costa 30 de triunghiuri diferenta.
b.cylinder(center=(0.0, 0.0, (ROOF_TOP + FINIAL_TOP) * 0.5), radius=FINIAL_R,
           depth=FINIAL_TOP - ROOF_TOP, slot=RUST, segments=4)

obj = b.to_object("water_tower")
stats = finish(
    obj,
    bevel=0.08, bevel_angle=30.0,   # clasa "cladiri" din style_bible §3
    ao=dict(samples=48, dist=3.5, gradient="vertical",
            low=0.55, high=1.00, power=1.0, floor=0.30),
)

print("water_tower -> %d tris | AO %.2f..%.2f" % (stats["tris"], stats["ao_min"], stats["ao_max"]))
bb = [v.co for v in obj.data.vertices]
print("bbox MASURAT: %.3f x %.3f x %.3f m (tinta: 9.500 inaltime, <=2.400 raza)"
      % (max(v.x for v in bb) - min(v.x for v in bb),
         max(v.y for v in bb) - min(v.y for v in bb),
         max(v.z for v in bb) - min(v.z for v in bb)))
print("GLB:   %s (%d B)" % export_glb([obj], "water_tower.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "water_tower.blend"))
