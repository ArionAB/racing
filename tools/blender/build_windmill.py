"""windmill.glb — moara de ferma cu roata rotibila. Brief: docs/asset_briefs/windmill.md

Doua obiecte in acelasi GLB:
  Windmill — turn + cap + coada (static)
  Blades   — roata de pale, nod SEPARAT, pivot in centrul butucului

Godot roteste nodul "Blades" pe axa lui locala +Z (vezi scenes/props/windmill.gd).
Roata e construita in planul XZ Blender, care devine planul XY in Godot — deci
axa de rotatie iese exact pe +Z, fara wobble.

Buget: <= 1200 triunghiuri total, din care roata ~300-400.
"""

import math
from mathutils import Matrix, Vector

# Inaltimea totala tinta e 11 m (style_bible §2 si titlul brief-ului). Cifrele de
# detaliu din brief (turn 8.5 m, butuc 8.75 m) dau doar ~10.05 m; am scalat turnul
# ca sa iasa cota agreata de ambele documente, pastrand proportiile.
TOWER_H = 9.40
BASE_HALF = 1.30      # amprenta la sol 2.6 x 2.6 m
TOP_HALF = 0.40       # sus 0.8 x 0.8 m
BEAM = 0.15

HEAD_Z = TOWER_H + 0.25
HUB_Z = TOWER_H + 0.25
HUB_Y = 0.45          # +Y in Blender = -Z in Godot (roata in fata)
WHEEL_R = 1.30        # diametru 2.6 m
N_BLADES = 12
PITCH = math.radians(15.0)

CORNERS = [(1, 1), (1, -1), (-1, -1), (-1, 1)]


def leg_xy(i, z):
    """Pozitia piciorului `i` la inaltimea z (picioare evazate: interpolare liniara)."""
    t = min(max(z / TOWER_H, 0.0), 1.0)
    half = BASE_HALF + (TOP_HALF - BASE_HALF) * t
    cx, cy = CORNERS[i]
    return (cx * half, cy * half, z)


# ---------------------------------------------------------------- turn + cap
clear_built("Windmill")
clear_built("Blades")

b = Builder()

for i in range(4):
    b.beam(leg_xy(i, 0.0), leg_xy(i, TOWER_H), BEAM, WOOD)

# TREI inele orizontale. Comentariul de aici spunea "doua (brief: 2-3), trei ar
# depasi bugetul dupa bevel" — al treilea e chiar ce cere #D3, si e cea mai
# ieftina imbunatatire din issue: turnul devine mai dens spre baza, ceea ce e si
# corect structural, fiindca acolo sunt fortele.
for z in (TOWER_H * 0.16, TOWER_H * 0.42, TOWER_H * 0.72):
    for i in range(4):
        b.beam(leg_xy(i, z), leg_xy((i + 1) % 4, z), BEAM * 0.85, WOOD)

# O singura diagonala groasa per fata — NU ferma fina de zabrele
for i in range(4):
    b.beam(leg_xy(i, 0.30), leg_xy((i + 1) % 4, TOWER_H - 0.30), BEAM * 0.8, WOOD)

# Cap / carcasa angrenajului
b.box(center=(0.0, 0.0, HEAD_Z), size=(0.60, 0.60, 0.50), slot=RUST)

# Coada: brat + vana de directie, spre -Y Blender = +Z Godot (in spate)
b.beam((0.0, -0.25, HEAD_Z), (0.0, -1.05, HEAD_Z), 0.12, RUST)
b.box(center=(0.0, -1.55, HEAD_Z), size=(0.06, 1.60, 0.90), slot=PAINTED,
      rotation=Matrix.Rotation(math.radians(9.0), 3, "Y"))

# ================================================== #D3: imbogatire la baza
# Rezervor. O moara de apa fara rezervor n-are ce pompa — asta e detaliul care
# leaga obiectul de functia lui, si lipsea complet.
TANK_R, TANK_H = 0.85, 1.15
TANK_X, TANK_Y = 1.50, 0.20
b.revolve(profile=[(TANK_R, 0.0), (TANK_R, TANK_H)], slot=RUST, segments=10,
          origin=(TANK_X, TANK_Y, 0.0), cap_bottom=True)
# Capacul de sus: `revolve` inchide doar baza, iar rezervorul se vede de sus de
# la inaltimea camerei de urmarire — deci aici capacul chiar se vede, spre
# deosebire de cel al turnului de apa, care sta sub streasina.
b.revolve(profile=[(TANK_R, TANK_H), (0.0, TANK_H + 0.16)], slot=RUST,
          segments=10, origin=(TANK_X, TANK_Y, 0.0), cap_bottom=False)
for z in (0.30, 0.85):
    b.torus(center=(TANK_X, TANK_Y, z), major_r=TANK_R + 0.04, minor_r=0.06,
            slot=RUST, major_seg=10, minor_seg=4)

# Jgheab de la rezervor spre exterior, si o pata de umezeala in jurul lui.
# Jgheabul merge spre +Y, nu spre -X: pe X orice iesire mareste amprenta, iar pe
# +Y mai e loc pana la coada morii, care iese oricum in spate cu 2.35 m.
b.beam((TANK_X - TANK_R * 0.3, TANK_Y + 0.55, 0.62),
       (TANK_X - 0.30, TANK_Y + 1.05, 0.34), (0.32, 0.22), WOOD)
trough = b.box(center=(TANK_X - 0.32, TANK_Y + 1.20, 0.22),
               size=(0.95, 0.58, 0.44), slot=WOOD)
# `retag` pe fetele de sus ale jgheabului: apa, zero triunghiuri.
b.retag(trough, SAND_SHADOW, where="up")

# Scara pe un picior, pana sub cap. `ladder` impune grosimile minime — la 0.4 m
# latime, treapta nu poate cobori sub 3.6 cm, deci nu poate iesi sarma.
LAD_OFF = 0.22 / math.sqrt(2.0)
lx0, ly0, _ = leg_xy(0, 1.10)
lx1, ly1, _ = leg_xy(0, TOWER_H - 0.55)
b.ladder(base=(lx0 + LAD_OFF, ly0 + LAD_OFF, 1.10),
         top=(lx1 + LAD_OFF, ly1 + LAD_OFF, TOWER_H - 0.55),
         width=0.40, rung_step=0.36, rail_t=0.06, rung_r=0.045,
         slot=RUST, side=(1.0, -1.0, 0.0))

tower = b.to_object("Windmill")
tower_stats = finish(
    tower,
    bevel=0.08, bevel_angle=30.0,
    ao=dict(samples=28, dist=3.0, gradient="vertical",
            low=0.55, high=1.00, power=1.0, floor=0.14),
    # pe axa turnului, nu pe centrul bbox-ului: coada iese mult in spate si ar
    # trage originea de sub moara
    origin="base_axis",
)

# ----------------------------------------------------------------- roata
# Construita in jurul originii: pivotul obiectului CADE exact in centrul butucului.
w = Builder()
w.cylinder(center=(0, 0, 0), radius=0.18, depth=0.26, slot=RUST, segments=8, axis="Y")

blade_len = WHEEL_R - 0.18
for k in range(N_BLADES):
    a = 2.0 * math.pi * k / N_BLADES
    u = Vector((math.cos(a), 0.0, math.sin(a)))        # axa radiala (lungimea palei)
    v0 = Vector((-math.sin(a), 0.0, math.cos(a)))      # tangential (latimea)
    w0 = Vector((0.0, 1.0, 0.0))                       # grosimea, pe axa rotii
    v = v0 * math.cos(PITCH) + w0 * math.sin(PITCH)    # pitch ~15° in jurul razei
    n = -v0 * math.sin(PITCH) + w0 * math.cos(PITCH)
    rot = Matrix((u, v, n)).transposed()
    w.box(center=u * (0.18 + blade_len * 0.5),
          size=(blade_len, 0.15, 0.04), slot=RUST, rotation=rot)

blades = w.to_object("Blades")
blades_stats = finish(
    blades,
    # Fara bevel: palele au 0.04 m grosime, iar un bevel de 0.04 s-ar clampa la
    # nimic si ar produce sliveri. Cost mare, castig zero.
    bevel=0.0,
    # AO radial, nu vertical: roata se invarte, deci nu poate avea AO directional.
    ao=dict(samples=24, dist=1.2, gradient="radial", radial_axis="Y",
            low=0.55, high=1.00, power=0.8, floor=0.40),
    origin=None,
)
# Pivotul obiectului e deja in centrul butucului (geometria a fost construita in
# jurul originii); il asezam in fata capului, la cota butucului.
blades.location = (0.0, HUB_Y, HUB_Z)

# Contract: bbox-ul nu creste, nodurile nu se redenumesc. `Blades` e cel critic —
# `scenes/props/windmill.gd:16` il cauta dupa nume si ii animeaza rotatia; daca
# lipseste, roata ramane statica cu un push_warning.
# --- contractele, separate dupa cat de tari sunt ---------------------------
#
# TARI, si se verifica: inaltimea si pivotul lui `Blades`. Pe astea Godot chiar
# se bazeaza (`_LANDMARKS` height, si `windmill.gd:16` care cauta nodul dupa nume
# si ii animeaza rotatia).
#
# AMPRENTA CRESTE, si e o abatere ASUMATA, nu o scapare. Issue-ul cere doua
# lucruri care nu incap impreuna: "rezervor la baza" si "bbox-ul nu creste". Un
# rezervor la baza nu poate sta INAUNTRUL turnului — deci amprenta creste, si
# singurul lucru cinstit e s-o masor si s-o raportez, nu s-o ascund. Am
# minimizat-o: rezervorul a scazut de la R=1.05 la 0.85 si s-a apropiat, iar
# jgheabul a fost mutat pe +Y, unde coada morii iese oricum mai mult.
BEFORE = (2.74, 3.72, 10.95)   # X, Y, Z in Blender, MASURATE pe GLB-ul dinainte
tb = [v.co for v in tower.data.vertices]
wb = [v.co + blades.location for v in blades.data.vertices]
allv = tb + wb
now = tuple(max(v[a] for v in allv) - min(v[a] for v in allv) for a in range(3))
rad = max(math.hypot(v.x, v.y) for v in allv)
print("bbox: %.2f x %.2f x %.2f   (inainte de #D3: %.2f x %.2f x %.2f)" % (now + BEFORE))
print("  inaltime : %.3f m  %s  [contract]"
      % (now[2], "neschimbata OK" if abs(now[2] - BEFORE[2]) < 0.01 else "SCHIMBATA !!"))
print("  amprenta : +%.2f m pe X — crestere ASUMATA, vezi nota. Raza max fata de axa: %.2f m"
      % (now[0] - BEFORE[0], rad))
print("  `_LANDMARKS` are radius 1.6; turnul singur avea deja 1.84 la colturi, "
      "acum e %.2f" % rad)
print("pivot Blades: (%.3f, %.3f, %.3f)  [neschimbat = contract cu windmill.gd:16]"
      % tuple(blades.location))
print("Windmill -> %4d tris | AO %.2f..%.2f" % (tower_stats["tris"], tower_stats["ao_min"], tower_stats["ao_max"]))
print("Blades   -> %4d tris | AO %.2f..%.2f" % (blades_stats["tris"], blades_stats["ao_min"], blades_stats["ao_max"]))
print("TOTAL    -> %4d tris" % (tower_stats["tris"] + blades_stats["tris"]))

print("GLB:   %s (%d B)" % export_glb([tower, blades], "windmill.glb"))
print("BLEND: %s (%d B)" % save_blend([tower, blades], "windmill.blend"))
