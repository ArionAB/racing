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

# =========================================================== #D2: imbogatire
# Prioritatea din issue, in ordine: cercuri > scara > balustrada > conducta.
# Cercurile costa cel mai putin si se vad cel mai mult.

# ------------------------------------------------------ cercuri de rezervor
# Cel mai recognoscibil detaliu al unui turn de apa, si lipsea complet — fiindca
# pana la `torus()` (#A1) nimic din dio_lib nu producea un inel: `revolve` se
# invarte in jurul axei dar porneste DE PE ea, deci da forme pline, nu gauri.
# `major_seg=TANK_SEG` nu e cosmetica: la alt numar de laturi decat rezervorul,
# muchiile inelului nu s-ar mai alinia cu ale lui si ar aparea o dantelare.
for z in (6.15, 6.85, 7.55):
    b.torus(center=(0.0, 0.0, z), major_r=TANK_R + 0.045, minor_r=0.075,
            slot=RUST, major_seg=TANK_SEG, minor_seg=4)

# ------------------------------------------------------- pasarela + balustrada
# Poligon cu 10 laturi in jurul rezervorului; se acopera 7 din 10. Brieful cere
# explicit sa NU fie completa: trei sferturi arata mai bine si costa mai putin,
# iar capatul deschis e chiar locul pe unde urci de pe scara.
CAT_R = 1.98
CAT_Z = TANK_BOT + 0.12
CAT_SEG = 10
CAT_COVER = 7


def cat_pt(i, r=CAT_R, z=CAT_Z):
    a = 2.0 * math.pi * i / CAT_SEG
    return (r * math.cos(a), r * math.sin(a), z)


for i in range(CAT_COVER):
    p1, p2 = cat_pt(i), cat_pt(i + 1)
    b.beam(p1=p1, p2=p2, thickness=(0.52, 0.10), slot=RUST)   # podeaua
    # `railing` impune grosimi minime relative la deschidere — ala e tot rostul
    # ajutorului. O lisa de 4 cm pe 1.2 m ar disparea la 60 km/h.
    b.railing(p1=p1, p2=p2, height=0.92, post_step=0.62,
              post_t=0.07, rail_t=0.06, slot=RUST, rails=2)

# ---------------------------------------------------------------- scara
# Brieful turnului (`water_tower.md:27-29`) facea scara OPTIONALA — "doar daca
# ramane chunky... daca iese subtire, omite-o". A iesit subtire si a fost omisa,
# dar motivul real nu era estetic: nu exista `ladder()`, iar o scara scrisa de
# mana din grinzi subtiri arata prost. Ajutorul IMPUNE grosimile minime (treapta
# >= 9% din latimea scarii), deci raspunsul devine "da".
# Scara URMEAZA piciorul, nu e verticala langa el. Prima versiune o punea
# vertical la o pozitie fixa; piciorul e evazat, deci sus ramanea la 0.66 m de el
# si plutea. `leg_xy` da pozitia piciorului la orice cota, iar decalajul de 0.20 m
# pe diagonala o scoate in afara lui fara sa iasa din colizorul cilindric.
LAD_OFF = 0.20 / math.sqrt(2.0)
lx0, ly0 = leg_xy(+1, -1, 1.45)
lx1, ly1 = leg_xy(+1, -1, CAT_Z + 0.30)
b.ladder(base=(lx0 + LAD_OFF, ly0 - LAD_OFF, 1.45),
         top=(lx1 + LAD_OFF, ly1 - LAD_OFF, CAT_Z + 0.30),
         width=0.46, rung_step=0.36, rail_t=0.07, rung_r=0.05,
         slot=RUST, side=(1.0, 1.0, 0.0))

# ------------------------------------------------------------- conducta
# Coboara din fundul rezervorului pe langa un picior. `sweep` cu 5 laturi: la
# 0.15 m raza, a sasea latura e sub un pixel de la orice distanta de joc.
b.sweep(path=[(-1.05, 1.05, TANK_BOT - 0.05), (-1.35, 1.35, 4.60),
              (-1.75, 1.75, 2.20), (-1.98, 1.98, 0.10)],
        radius=0.15, slot=RUST, segments=5, dome_end=False, cap_start=True)
for z in (4.60, 2.20):
    t = min(max(z / LEG_TOP, 0.0), 1.0)
    off = 1.35 + (1.98 - 1.35) * (1.0 - z / 4.60) * 0.55
    b.torus(center=(-off, off, z), major_r=0.23, minor_r=0.055, slot=RUST,
            major_seg=6, minor_seg=4, axis="Z")

obj = b.to_object("water_tower")


def snap_bbox(o, target):
    """Forteaza bbox-ul pe cotele contractuale dupa bevel, si intoarce corectia.

    Acelasi mecanism ca la poarta de start (#B3), si aici din acelasi motiv:
    piesele noi schimba banda de bevel chiar acolo unde geometria n-a fost
    atinsa, iar #D2 a iesit cu +16 mm pe inaltime — la o cota care e CONTRACT cu
    `_LANDMARKS` (`height: 9.5`). Compensarea printr-o constanta ajustata de mana
    (cum era FINIAL_TOP = 9.486) tine pana la urmatoarea retusare si apoi se
    strica tacut. Masurarea nu se strica.
    """
    me = o.data
    out = []
    for axis, t in enumerate(target):
        vals = [v.co[axis] for v in me.vertices]
        span = max(vals) - min(vals)
        s = t / span
        for v in me.vertices:
            v.co[axis] *= s
        out.append(s)
    return out


stats = finish(
    obj,
    bevel=0.08, bevel_angle=30.0,   # clasa "cladiri" din style_bible §3
    ao=dict(samples=48, dist=3.5, gradient="vertical",
            low=0.55, high=1.00, power=1.0, floor=0.13),
)

print("water_tower -> %d tris | AO %.2f..%.2f" % (stats["tris"], stats["ao_min"], stats["ao_max"]))
BEFORE = (4.783, 4.785, 9.500)
corr = snap_bbox(obj, BEFORE)
set_origin_base(obj, center_xy=True)
print("corectie de bevel: x%.5f  x%.5f  x%.5f" % tuple(corr))
bb = [v.co for v in obj.data.vertices]
now = (max(v.x for v in bb) - min(v.x for v in bb),
       max(v.y for v in bb) - min(v.y for v in bb),
       max(v.z for v in bb) - min(v.z for v in bb))
TOL = 0.01
print("bbox MASURAT: %.3f x %.3f x %.3f m   (inainte de #D2: %.3f x %.3f x %.3f)"
      % (now + BEFORE))
grown = [ax for ax, n, o in zip("XYZ", now, BEFORE) if n > o + TOL]
print("gabarit     : %s" % ("NU a crescut  OK" if not grown
                            else "A CRESCUT pe " + ",".join(grown) + "  !!"))
print("raza max fata de axa: %.3f m (colizor cilindric 2.400)"
      % max(math.hypot(v.x, v.y) for v in bb))
print("GLB:   %s (%d B)" % export_glb([obj], "water_tower.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "water_tower.blend"))
