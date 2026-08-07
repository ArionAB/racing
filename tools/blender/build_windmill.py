"""windmill.glb — moara de ferma cu roata rotibila. Brief: docs/asset_briefs/windmill.md

PATRU obiecte in acelasi GLB, sparte pe CLASA de suprafata (#129):
  Mill_Wood  — turn: picioare, inele, diagonale          -> clasa `wood`
  Mill_Metal — cap, coada, rezervor, cercuri, scara      -> clasa `rust_metal`
  Mill_Trim  — vana de directie + jgheabul cu apa        -> ramane pe ATLAS
  Blades     — roata de pale, nod SEPARAT                -> clasa `rust_metal`

De ce sparta asa: moara e lemn SI metal, deci nu poate primi o singura clasa
"pe tot subarborele" ca turnul de apa. Numele sunt CONTRACTUL cu Godot —
`_LANDMARKS` id 2 mapeaza prefixele pe clase, iar ce nu e mapat cade pe atlas.

De ce cube_uvs si nu triplanar de lume, desi turnul sta pe loc: `Blades` se
ROTESTE, iar proiectia de lume i-ar face textura sa "inoate" pe pale
(style_bible §4). Odata ce roata cere UV-uri reale, le primeste toata moara —
o clasa cu doua mecanisme de proiectie pe acelasi obiect ar arata cu doua
granulatii diferite la imbinarea cap/turn.

`Mill_Trim` ramane pe atlas din doua motive concrete: vana e PAINTED (albastru
rece, singurul accent de culoare al morii — o textura de rugina l-ar sterge),
iar jgheabul isi ia apa dintr-un `retag` la SAND_SHADOW, care e o schimbare de
SLOT, deci invizibila sub o textura de clasa.

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

TANK_R, TANK_H = 0.85, 1.15
TANK_X, TANK_Y = 1.50, 0.20

# Metri per repetitie de textura, PE CLASA (nu pe piesa). `rust_metal` pastreaza
# 2.2 m, adica exact scara triplanara cu care merg deja turnul de apa,
# excavatorul si conducta — asa rugina de pe moara arata ca rugina de pe ele.
# Lemnul la 1.2 m: sursa are ~6 scanduri pe dala, deci scandura iese la ~20 cm,
# cat o scandura adevarata pe o grinda de 15 cm.
UV_WOOD = 1.2
UV_RUST = 2.2


def leg_xy(i, z):
    """Pozitia piciorului `i` la inaltimea z (picioare evazate: interpolare liniara)."""
    t = min(max(z / TOWER_H, 0.0), 1.0)
    half = BASE_HALF + (TOP_HALF - BASE_HALF) * t
    cx, cy = CORNERS[i]
    return (cx * half, cy * half, z)


# ------------------------------------------------------------ piesele
def mill_wood(b):
    """Scheletul de lemn: picioare, inele, diagonale."""
    for i in range(4):
        b.beam(leg_xy(i, 0.0), leg_xy(i, TOWER_H), BEAM, WOOD)

    # TREI inele orizontale. Comentariul de aici spunea "doua (brief: 2-3), trei
    # ar depasi bugetul dupa bevel" — al treilea e chiar ce cere #D3, si e cea
    # mai ieftina imbunatatire din issue: turnul devine mai dens spre baza, ceea
    # ce e si corect structural, fiindca acolo sunt fortele.
    for z in (TOWER_H * 0.16, TOWER_H * 0.42, TOWER_H * 0.72):
        for i in range(4):
            b.beam(leg_xy(i, z), leg_xy((i + 1) % 4, z), BEAM * 0.85, WOOD)

    # O singura diagonala groasa per fata — NU ferma fina de zabrele
    for i in range(4):
        b.beam(leg_xy(i, 0.30), leg_xy((i + 1) % 4, TOWER_H - 0.30), BEAM * 0.8,
               WOOD)


def mill_metal(b):
    """Tot ce e metal ruginit: cap, bratul cozii, rezervor, cercuri, scara."""
    # Cap / carcasa angrenajului
    b.box(center=(0.0, 0.0, HEAD_Z), size=(0.60, 0.60, 0.50), slot=RUST)
    # Bratul cozii, spre -Y Blender = +Z Godot (in spate)
    b.beam((0.0, -0.25, HEAD_Z), (0.0, -1.05, HEAD_Z), 0.12, RUST)

    # Rezervor. O moara de apa fara rezervor n-are ce pompa — asta e detaliul
    # care leaga obiectul de functia lui.
    b.revolve(profile=[(TANK_R, 0.0), (TANK_R, TANK_H)], slot=RUST, segments=10,
              origin=(TANK_X, TANK_Y, 0.0), cap_bottom=True)
    # Capacul de sus: `revolve` inchide doar baza, iar rezervorul se vede de sus
    # de la inaltimea camerei de urmarire — deci aici capacul chiar se vede,
    # spre deosebire de cel al turnului de apa, care sta sub streasina.
    b.revolve(profile=[(TANK_R, TANK_H), (0.0, TANK_H + 0.16)], slot=RUST,
              segments=10, origin=(TANK_X, TANK_Y, 0.0), cap_bottom=False)
    for z in (0.30, 0.85):
        b.torus(center=(TANK_X, TANK_Y, z), major_r=TANK_R + 0.04, minor_r=0.06,
                slot=RUST, major_seg=10, minor_seg=4)

    # Scara pe un picior, pana sub cap. `ladder` impune grosimile minime — la
    # 0.4 m latime, treapta nu poate cobori sub 3.6 cm, deci nu poate iesi sarma.
    lad_off = 0.22 / math.sqrt(2.0)
    lx0, ly0, _ = leg_xy(0, 1.10)
    lx1, ly1, _ = leg_xy(0, TOWER_H - 0.55)
    b.ladder(base=(lx0 + lad_off, ly0 + lad_off, 1.10),
             top=(lx1 + lad_off, ly1 + lad_off, TOWER_H - 0.55),
             width=0.40, rung_step=0.36, rail_t=0.06, rung_r=0.045,
             slot=RUST, side=(1.0, -1.0, 0.0))


def mill_trim(b):
    """Ce ramane pe ATLAS: vana de directie (accent de culoare) si jgheabul
    (apa lui e un slot, nu o textura)."""
    b.box(center=(0.0, -1.55, HEAD_Z), size=(0.06, 1.60, 0.90), slot=PAINTED,
          rotation=Matrix.Rotation(math.radians(9.0), 3, "Y"))
    # Jgheab de la rezervor spre exterior. Merge spre +Y, nu spre -X: pe X orice
    # iesire mareste amprenta, iar pe +Y mai e loc pana la coada morii, care iese
    # oricum in spate cu 2.35 m.
    b.beam((TANK_X - TANK_R * 0.3, TANK_Y + 0.55, 0.62),
           (TANK_X - 0.30, TANK_Y + 1.05, 0.34), (0.32, 0.22), WOOD)
    trough = b.box(center=(TANK_X - 0.32, TANK_Y + 1.20, 0.22),
                   size=(0.95, 0.58, 0.44), slot=WOOD)
    # `retag` pe fetele de sus ale jgheabului: apa, zero triunghiuri.
    b.retag(trough, SAND_SHADOW, where="up")


def mill_blades(w):
    """Roata: butuc + 12 pale, construita in jurul ORIGINII, ca pivotul
    obiectului sa cada exact in centrul butucului."""
    w.cylinder(center=(0, 0, 0), radius=0.18, depth=0.26, slot=RUST, segments=8,
               axis="Y")
    blade_len = WHEEL_R - 0.18
    for k in range(N_BLADES):
        a = 2.0 * math.pi * k / N_BLADES
        u = Vector((math.cos(a), 0.0, math.sin(a)))     # radial (lungimea palei)
        v0 = Vector((-math.sin(a), 0.0, math.cos(a)))   # tangential (latimea)
        w0 = Vector((0.0, 1.0, 0.0))                    # grosimea, pe axa rotii
        v = v0 * math.cos(PITCH) + w0 * math.sin(PITCH)  # pitch ~15° pe raza
        n = -v0 * math.sin(PITCH) + w0 * math.cos(PITCH)
        rot = Matrix((u, v, n)).transposed()
        w.box(center=u * (0.18 + blade_len * 0.5),
              size=(blade_len, 0.15, 0.04), slot=RUST, rotation=rot)


# --------------------------------------------------------------- build
# (nume nod, umplere, bevel, spec AO, marime UV cub sau None = ramane pe atlas)
#
# AO-ul se coace acum PE PIESA, nu pe turnul intreg. Diferenta reala: piesele nu
# se mai umbresc una pe alta (BVH-ul lui bake_ao e per obiect), deci scara nu mai
# lasa umbra pe picior. E acelasi compromis acceptat la pilotul village_house, si
# e mic aici fiindca moara e o structura DESCHISA — aproape nimic nu ocluza
# altceva nici inainte.
AO_TOWER = dict(samples=28, dist=3.0, gradient="vertical",
                low=0.55, high=1.00, power=1.0, floor=0.14)
AO_BLADES = dict(samples=24, dist=1.2, gradient="radial", radial_axis="Y",
                 low=0.55, high=1.00, power=0.8, floor=0.40)

STATIC_PARTS = [
    ("Mill_Wood", mill_wood, 0.08, UV_WOOD),
    ("Mill_Metal", mill_metal, 0.08, UV_RUST),
    ("Mill_Trim", mill_trim, 0.08, None),
]

for _name, _f, _b, _u in STATIC_PARTS:
    clear_built(_name)
clear_built("Blades")
clear_built("Windmill")  # numele vechi al turnului nesparte

built = []
total = 0
for name, fill, bevel, uv_size in STATIC_PARTS:
    b = Builder()
    fill(b)
    obj = b.to_object(name)
    # Din vertecsi, nu din bound_box: bound_box-ul unui obiect proaspat creat
    # poate fi inca nesincronizat cu depsgraph-ul.
    min_z = min(v.co.z for v in obj.data.vertices)
    stats = finish(
        obj, bevel=bevel, bevel_angle=30.0, ao=AO_TOWER,
        # pe axa turnului, nu pe centrul bbox-ului: coada iese mult in spate si
        # ar trage originea de sub moara
        origin="base_axis",
    )
    # finish() coboara baza piesei la z=0 (corect pentru assets de sine
    # statatoare); aici piesele sunt UN ansamblu, deci cota se restaureaza.
    obj.location.z = min_z
    if uv_size is not None:
        cube_uvs(obj, uv_size)
    total += stats["tris"]
    built.append(obj)
    print("%-12s %4d tris | AO %.2f..%.2f | uv=%s"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             "cub %.1f m" % uv_size if uv_size else "atlas"))

w = Builder()
mill_blades(w)
blades = w.to_object("Blades")
blades_stats = finish(
    blades,
    # Fara bevel: palele au 0.04 m grosime, iar un bevel de 0.04 s-ar clampa la
    # nimic si ar produce sliveri. Cost mare, castig zero.
    bevel=0.0,
    # AO radial, nu vertical: roata se invarte, deci nu poate avea AO directional.
    ao=AO_BLADES,
    origin=None,
)
cube_uvs(blades, UV_RUST)
# Pivotul obiectului e deja in centrul butucului (geometria a fost construita in
# jurul originii); il asezam in fata capului, la cota butucului.
blades.location = (0.0, HUB_Y, HUB_Z)
built.append(blades)
total += blades_stats["tris"]

# O SINGURA coborare pe tot ansamblul, ca baza morii sa cada exact la z=0.
# `finish(origin="base_axis")` ridica FIECARE piesa pe baza EI, deci fara pasul
# asta piesele se desincronizeaza pe verticala; restaurarea de mai sus le pune
# inapoi in coordonatele de constructie, iar aici coboara tot ansamblul deodata.
# (Picioarele evazate au capul taiat perpendicular pe directia lor, deci coltul
# de jos intra 1.4 cm sub zero — de acolo vine deplasarea.)
assembly_base = min(o.location.z + min(v.co.z for v in o.data.vertices)
                    for o in built)
for o in built:
    o.location.z -= assembly_base
print("%-12s %4d tris | AO %.2f..%.2f | uv=cub %.1f m"
      % ("Blades", blades_stats["tris"], blades_stats["ao_min"],
         blades_stats["ao_max"], UV_RUST))

# --- contractele, separate dupa cat de tari sunt ---------------------------
#
# TARI, si se verifica: inaltimea si pivotul lui `Blades`. Pe astea Godot chiar
# se bazeaza (`_LANDMARKS` height, si `windmill.gd:16` care cauta nodul dupa nume
# si ii animeaza rotatia). Spargerea pe patru piese NU are voie sa le miste.
#
# AMPRENTA CRESTE fata de moara dinainte de #D3, si e o abatere ASUMATA: un
# rezervor la baza nu poate sta INAUNTRUL turnului.
#
# BEFORE e acum bbox-ul MASURAT pe GLB-ul dinaintea spargerii (post-#D3), nu cel
# pre-#D3: referinta trebuie sa fie ce e in joc azi, altfel verificarea compara
# cu o moara care nu mai exista.
BEFORE = (3.806, 4.040, 10.950)   # X, Y, Z in Blender, MASURATE pe GLB-ul dinainte
allv = []
for o in built:
    off = Vector(o.location)
    allv += [v.co + off for v in o.data.vertices]
now = tuple(max(v[a] for v in allv) - min(v[a] for v in allv) for a in range(3))
rad = max(math.hypot(v.x, v.y) for v in allv)
print("bbox: %.3f x %.3f x %.3f   (inainte de split: %.3f x %.3f x %.3f)"
      % (now + BEFORE))
print("  inaltime : %.3f m  (%+.3f m fata de GLB-ul dinainte)  %s"
      % (now[2], now[2] - BEFORE[2],
         "OK" if abs(now[2] - BEFORE[2]) < 0.02 else "PESTE TOLERANTA !!"))
print("  raza max fata de axa: %.2f m  (`_LANDMARKS` radius 1.6, decizie nu masuratoare)"
      % rad)
# Pivotul urca de la 9.650 la 9.664 fata de GLB-ul dinainte de spargere, si asta
# e o REPARATIE, nu o abatere: varianta monolitica ridica turnul pe baza lui
# (+1.4 cm) fara sa compenseze si roata, deci roata statea cu 1.4 cm mai jos
# decat capul in care se infige. Nimic din Godot nu citeste cota — windmill.gd
# cauta nodul dupa NUME.
print("pivot Blades: (%.3f, %.3f, %.3f)  [windmill.gd:16 cauta NUMELE, nu cota]"
      % tuple(blades.location))
print("TOTAL    -> %4d tris (buget 1200)" % total)

print("GLB:   %s (%d B)" % export_glb(built, "buildings/windmill.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "windmill.blend"))
