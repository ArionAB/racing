"""Atelierul din ecranul de GARAJ (brief: docs/asset_briefs/garage_bay.md).

  GarageBay        interiors/garage_bay.glb         20 x 14 x 7 m    1320 tri
  GarageDoor       interiors/garage_door.glb        6 x 0.3 x 5 m     328 tri
  GarageBench      interiors/garage_bench.glb       3.2 x 0.8 x 2.2   748 tri
  GarageToolbox    interiors/garage_toolbox.glb     1.1 x 0.6 x 1.4   764 tri
  GarageTireStack  interiors/garage_tire_stack.glb  0.9 x 0.9 x 1.1   832 tri
  GarageBarrel     interiors/garage_barrel.glb      0.6 x 0.6 x 0.9   368 tri
  GarageCrate      interiors/garage_crate.glb       0.9 x 0.9 x 0.7   264 tri

Total 4624 triunghiuri, UN material per piesa. Cifrele de mai sus sunt
MASURATE, nu plafoane: piesele se instantiaza o data intr-un ecran de meniu,
iar style_bible §2 cere ca bugetul sa se scaleze cu numarul de INSTANTE.
Plafonul din `GUARD` de mai jos e un prag de SURPRIZA (o primitiva lasata la
rezolutia implicita sare cu zeci de mii dintr-un foc), nu o tinta.

Cutia e de 20 x 14 x 7 m fiindca atat se VEDE, masurat prin camera vitrinei
(fov 38°, la ~9.7 m de centru): la planul podiumului cadrul are 11.8 x 6.7 m,
la 16 m in spate 19.2 x 10.8 m. O hala mai mare ar fi geometrie care nu intra
niciodata in cadru.

Atelierul e FUNDAL, nu subiect: nimic nu are voie sa fie mai saturat decat
caroseria (sloturile 14-16 sunt interzise aici) si podeaua nu coboara sub
ASPHALT, care ramane cea mai inchisa suprafata continua din joc.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_garage_bay.py
Verificare:
    python tools/blender/verify_glb.py assets/models/interiors/garage_bay.glb 2500
"""

import math
from mathutils import Matrix, Vector

# Cutia. In GODOT camera priveste dinspre +Z si masina sta la origine, deci
# peretele din fund trebuie sa ajunga la z negativ.
#
# ATENTIE LA AXE: exportul e Y-up, adica **+Y din Blender devine -Z in Godot**.
# Prima versiune construia fundul la y=-8 "ca sa fie la z=-8" si el a aterizat
# la z=+8 — fix in spatele camerei, care sta la z=+9. De-aia cutia parea sa
# lipseasca si se vedea doar podeaua. Aici fundul e la +Y.
BAY_HALF_X = 10.0
BAY_BACK_Z = 8.0        # peretele din fund (-> z=-8 in Godot)
BAY_FRONT_Z = -6.0      # peretele din spatele camerei (-> z=+6 in Godot)
BAY_H = 7.0
WALL_T = 0.3

# Deschiderea usii, in peretele din fund: pe acolo intra lumina si se vede ca
# exista o lume dincolo. Centrata pe x=0 — e singurul lucru din cadru care are
# voie sa fie simetric, fiindca e sursa de lumina.
DOOR_HALF_W = 3.0
DOOR_H = 5.0

# Betonul podelei merge pe ASPHALT_EDGE (#696765), nu pe ASPHALT (#4B4B4D):
# regula de citire din style_bible cere ca asfaltul sa ramana cea mai inchisa
# suprafata continua din joc. O podea de garaj la fel de inchisa ca soseaua ar
# fi mancat linia de curs in orice captura comparativa.
FLOOR = ASPHALT_EDGE
WALL = CONCRETE
TRIM = PAINTED


def plate(b, center, size, slot):
    """Placa subtire (podea, perete, tavan) ca o cutie turtita."""
    return b.box(center, size, slot)


# ============================================================== GarageBay

def build_bay():
    b = Builder()
    span_z = abs(BAY_FRONT_Z - BAY_BACK_Z)
    mid_z = (BAY_FRONT_Z + BAY_BACK_Z) * 0.5

    # --- podea ---
    plate(b, (0.0, mid_z, -WALL_T * 0.5),
          (BAY_HALF_X * 2.0, span_z, WALL_T), FLOOR)
    # Doua rosturi de dilatare: linii de beton care dau SCARA podelei. Fara
    # ele, 20 m de gri continuu n-au cu ce sa fie masurati de ochi.
    for zx in (3.0, -1.5):
        plate(b, (0.0, zx, 0.012), (BAY_HALF_X * 2.0, 0.09, 0.03), ASPHALT)

    # --- peretele din fund, construit ca MASE cu gol intre ele ---
    # Golul usii e spatiu intre doi stalpi, nu o taietura boolean (lectia de la
    # mine_portal: taieturile lasa muchii care nu se beveleaza curat).
    side_w = BAY_HALF_X - DOOR_HALF_W
    for sx in (-1.0, 1.0):
        cx = sx * (DOOR_HALF_W + side_w * 0.5)
        plate(b, (cx, BAY_BACK_Z, BAY_H * 0.5),
              (side_w, WALL_T, BAY_H), WALL)
    # buiandrugul peste usa
    lintel_h = BAY_H - DOOR_H
    plate(b, (0.0, BAY_BACK_Z, DOOR_H + lintel_h * 0.5),
          (DOOR_HALF_W * 2.0, WALL_T, lintel_h), WALL)
    # Rama usii: doi montanti + prag, in metal vopsit. Rupe cei 20 m de beton
    # exact acolo unde se uita ochiul (lumina vine de acolo).
    for sx in (-1.0, 1.0):
        plate(b, (sx * DOOR_HALF_W, BAY_BACK_Z - 0.02, DOOR_H * 0.5),
              (0.22, WALL_T + 0.08, DOOR_H), TRIM)
    plate(b, (0.0, BAY_BACK_Z - 0.02, DOOR_H),
          (DOOR_HALF_W * 2.0 + 0.22, WALL_T + 0.08, 0.22), TRIM)

    # --- pereti laterali ---
    # Cel din dreapta (+X) e in afara cadrului la distanta podiumului, dar se
    # construieste oricum: costa ~100 de triunghiuri si apare daca se schimba
    # raportul de ecran.
    for sx in (-1.0, 1.0):
        plate(b, (sx * BAY_HALF_X, mid_z, BAY_H * 0.5),
              (WALL_T, span_z, BAY_H), WALL)
    # Pilastri: lezene verticale pe peretele din stanga, la 4 m. Ii dau ritm si
    # prind umbra directionalei (care bate din stanga-sus).
    for z in (5.5, 1.5, -2.5):
        plate(b, (-BAY_HALF_X + 0.28, z, BAY_H * 0.5),
              (0.3, 0.55, BAY_H), WALL)

    # --- tavan, cu LUMINATOR ---
    #
    # Golul din tavan nu e decor: fara el masina n-are lumina directa deloc.
    # Masurat: soarele (elevatie 42°, azimut 135°) intra pe usa, dar raza care
    # trece pe sub buiandrug (y=5, z=-8) atinge podeaua abia la z=-4.08 — iar
    # masina sta la z=0, adica in umbra buiandrugului. De-aia nu avea umbra
    # proprie: nu primea soare.
    #
    # Pozitia e calculata, nu aleasa: in GODOT, de la tavan (y=7) la podea,
    # raza se deplaseaza +5.49 pe z si -5.49 pe x. Deci golul trebuie sa stea
    # la (x=+5.49, z=-5.5) in GODOT, ca pata sa cada peste masina la (0, 0).
    #
    # Aici construim in BLENDER, unde +Y devine -Z: deci sky_y = +5.5. Prima
    # versiune a pus -5.5 "fiindca z trebuie sa fie -5.5" si golul a aterizat
    # la z=+5.5 in Godot, cu pata de soare la z=+11 — in spatele camerei.
    # Exact capcana care intorsese si cutia (vezi BAY_BACK_Z).
    sky_x, sky_z = 5.49, 5.5
    sky_half = 2.1
    # tavanul, ca patru benzi in jurul golului (mase cu gol intre ele, nu o
    # taietura boolean — muchiile de taietura nu se beveleaza curat)
    for sx in (-1.0, 1.0):
        w_side = BAY_HALF_X - sky_half if sx > 0 else BAY_HALF_X + sky_x - sky_half
        cx = sky_x + sx * (sky_half + w_side * 0.5)
        plate(b, (cx, mid_z, BAY_H), (w_side, span_z, WALL_T), WALL)
    for sy in (-1.0, 1.0):
        d_side = abs(BAY_FRONT_Z - sky_z) - sky_half if sy < 0             else abs(BAY_BACK_Z - sky_z) - sky_half
        cz = sky_z + sy * (sky_half + d_side * 0.5)
        plate(b, (sky_x, cz, BAY_H), (sky_half * 2.0, d_side, WALL_T), WALL)
    # rama luminatorului
    for sx in (-1.0, 1.0):
        plate(b, (sky_x + sx * sky_half, sky_z, BAY_H),
              (0.18, sky_half * 2.0, WALL_T + 0.12), TRIM)
    for sy in (-1.0, 1.0):
        plate(b, (sky_x, sky_z + sy * sky_half, BAY_H),
              (sky_half * 2.0, 0.18, WALL_T + 0.12), TRIM)
    # Patru grinzi transversale. Nu se vad intregi din camera (privirea e
    # coborata 18°), dar capetele lor inchid cadrul sus si impiedica senzatia
    # de "cutie fara capac".
    for z in (6.0, 2.5, -1.0, -4.5):
        b.box((0.0, z, BAY_H - 0.45),
              (BAY_HALF_X * 2.0 - 0.2, 0.34, 0.62), TRIM)

    # --- banda de uzura pe pereti ---
    # O dunga mai inchisa la 1.2 m, cat ajunge noroiul si cauciucul. Semnal de
    # scara: spune cat de inalta e incaperea fara sa pui un om in ea.
    for sx in (-1.0, 1.0):
        b.box((sx * (BAY_HALF_X - 0.16), mid_z, 1.2),
              (0.06, span_z - 0.4, 0.5), ASPHALT)
    for sx in (-1.0, 1.0):
        cx = sx * (DOOR_HALF_W + side_w * 0.5)
        b.box((cx, BAY_BACK_Z - 0.16, 1.2), (side_w - 0.3, 0.06, 0.5), ASPHALT)

    return b


# ============================================================= GarageDoor

def build_door():
    """Usa rulou, STRANSA SUS intr-un sul. E deschisa — rolul ei e sa explice
    de unde vine lumina, nu sa inchida cadrul."""
    b = Builder()
    # sulul
    b.cylinder((0.0, 0.0, 0.0), 0.42, DOOR_HALF_W * 2.0, TRIM,
               segments=12, axis="X")
    # cateva lamele atarnate sub sul, ca sa se citeasca drept rulou
    for i in range(3):
        b.box((0.0, 0.0, -0.45 - i * 0.17),
              (DOOR_HALF_W * 2.0 - 0.1, 0.1, 0.13), TRIM)
    # consolele de capat
    for sx in (-1.0, 1.0):
        b.box((sx * (DOOR_HALF_W - 0.05), 0.0, 0.0), (0.16, 0.52, 0.52), ASPHALT)
    return b


# ============================================================ GarageBench

def build_bench():
    """Banc de lucru cu panou de scule. Sta pe peretele din STANGA, fiindca
    lumina vine din stanga-sus: isi arunca umbra spre interiorul cadrului si
    da adancime. Pe dreapta ar fi fost o pata plata."""
    b = Builder()
    top_z = 0.92
    # blat
    b.box((0.0, 0.0, top_z), (3.2, 0.76, 0.1), WOOD)
    # cadru si picioare
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.beam((sx * 1.45, sy * 0.3, 0.0), (sx * 1.45, sy * 0.3, top_z - 0.06),
                   0.09, TRIM)
    b.box((0.0, 0.0, 0.3), (3.0, 0.62, 0.06), TRIM)   # polita de jos
    # Lazi sub banc: umplu golul si rup linia orizontala a politei.
    b.box((-0.85, 0.0, 0.52), (0.72, 0.5, 0.42), WOOD)
    b.box((0.95, 0.0, 0.48), (0.6, 0.46, 0.34), RUST)

    # panou de scule pe perete
    panel_z = top_z + 0.72
    b.box((0.0, 0.33, panel_z), (3.0, 0.06, 1.2), TRIM)
    # Siluete de scule: dreptunghiuri subtiri de marimi diferite. La 456 px
    # inaltime de vitrina nu se citeste ce unealta e — se citeste ca "perete cu
    # scule". Formele mici si egale ar fi devenit o textura de zgomot.
    tools = [(-1.15, 0.44, 0.09, 0.52), (-0.72, 0.30, 0.07, 0.40),
             (-0.30, 0.50, 0.12, 0.30), (0.18, 0.36, 0.08, 0.46),
             (0.66, 0.46, 0.14, 0.26), (1.12, 0.28, 0.07, 0.38)]
    for tx, tz_off, tw, th in tools:
        b.box((tx, 0.28, panel_z + tz_off - 0.25), (tw, 0.05, th), ASPHALT)
    # trusa rosie pe blat: SINGURUL accent cald saturat din atelier (§4 — cel
    # mult 2% din suprafata, altfel fundalul incepe sa tipe)
    b.box((1.02, 0.0, top_z + 0.17), (0.52, 0.3, 0.24), KERB_RED)
    b.box((1.02, 0.0, top_z + 0.31), (0.2, 0.05, 0.06), ASPHALT)  # manerul
    return b


# =========================================================== GarageToolbox

def build_toolbox():
    """Dulap de scule pe rotile: trei sertare si o dunga rosie."""
    b = Builder()
    body_z = 0.72
    b.box((0.0, 0.0, body_z * 0.5 + 0.12), (1.06, 0.56, body_z), TRIM)
    b.box((0.0, 0.0, body_z + 0.18), (1.12, 0.6, 0.08), ASPHALT)  # blatul
    # sertare: franturi orizontale, cu manere
    for i in range(3):
        z = 0.22 + i * 0.21
        b.box((0.0, -0.29, z), (0.96, 0.03, 0.16), ASPHALT_EDGE)
        b.box((0.0, -0.32, z), (0.34, 0.04, 0.04), ASPHALT)
    b.box((0.0, -0.29, 0.86), (1.0, 0.02, 0.05), KERB_RED)  # dunga de accent
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.cylinder((sx * 0.42, sy * 0.2, 0.06), 0.07, 0.06, ASPHALT,
                       segments=8, axis="Z")
    return b


# ========================================================= GarageTireStack

def build_tire_stack():
    """Teanc de patru cauciucuri, usor decalate. Segmente setate EXPLICIT:
    un tor la rezolutia implicita ar fi adus mii de triunghiuri pentru o forma
    care se vede ca un inel (nota de primitive din CLAUDE.md)."""
    b = Builder()
    for i in range(4):
        z = 0.12 + i * 0.22
        # decalaj mic si rotatie: un teanc perfect aliniat citeste ca o eroare
        ox = 0.035 * math.cos(i * 2.1)
        oy = 0.035 * math.sin(i * 1.7)
        b.cylinder((ox, oy, z), 0.44, 0.2, ASPHALT, segments=12, axis="Z")
        # janta: un disc mai deschis in mijloc, altfel teancul e o masa neagra
        b.cylinder((ox, oy, z + 0.005), 0.19, 0.21, ASPHALT_EDGE,
                   segments=10, axis="Z")
    return b


# ============================================================ GarageBarrel

def build_barrel():
    b = Builder()
    b.cylinder((0.0, 0.0, 0.45), 0.29, 0.9, RUST, segments=12, axis="Z")
    # doua nervuri: dau volum unui cilindru care altfel e o conserva
    for z in (0.3, 0.6):
        b.cylinder((0.0, 0.0, z), 0.31, 0.07, ASPHALT_EDGE, segments=12, axis="Z")
    b.cylinder((0.0, 0.0, 0.9), 0.3, 0.05, ASPHALT_EDGE, segments=12, axis="Z")
    return b


# ============================================================= GarageCrate

def build_crate():
    """Lada de lemn cu scanduri inegale (nimic perfect cubic — §5)."""
    b = Builder()
    b.box((0.0, 0.0, 0.34), (0.88, 0.88, 0.68), WOOD)
    # ramele de colt, putin diferite ca grosime
    for i, sx in enumerate((-1.0, 1.0)):
        b.box((sx * 0.44, 0.0, 0.34), (0.06, 0.9, 0.66 - i * 0.03), ASPHALT_EDGE)
        b.box((0.0, sx * 0.44, 0.34), (0.9, 0.06, 0.64 + i * 0.03), ASPHALT_EDGE)
    b.box((0.0, 0.0, 0.69), (0.9, 0.9, 0.05), WOOD)
    return b


# ================================================================== export

# Pragul de surpriza: de cate ori peste cifra masurata e voie sa sara o piesa
# inainte sa fie semnalata. 2x prinde o primitiva uitata la rezolutia
# implicita (care sare cu un ordin de marime), fara sa ceara o ceremonie la
# fiecare bevel in plus.
GUARD = 2.0

# AO per piesa, nu o reteta pentru toate.
#
# Prima versiune dadea tuturor `gradient="vertical"` si incaperea a iesit
# aproape neagra: podeaua masura 18 din 255 acolo unde slotul ASPHALT_EDGE
# (#696765) cere ~103. Doua cauze care se ADUNA, amandoua reale:
#
#   1. Gradientul vertical inchide capatul de jos (low=0.40). Podeaua e TOATA
#      la z=0, deci lua integral capatul intunecat — un gradient "jos mai
#      inchis" n-are sens pe o suprafata plana orizontala.
#   2. Ocluzia geometrica intr-o incapere INCHISA gaseste pereti in aproape
#      toate directiile. Pe o pista, AO-ul se coace pe obiecte sub cer liber;
#      aici emisfera de raycast loveste mereu ceva.
#
# Plus efectul din CLAUDE.md: AO-ul copt si umbra dinamica se ADUNA (de-aia
# CLIFF_AO_STRENGTH a coborat 0.45 -> 0.22 cand s-au pornit umbrele). Vitrina
# are acum umbre reale, deci AO-ul trebuie sa lase loc.
AO_BAY = {"gradient": "none", "strength": 0.45, "floor": 0.55, "dist": 2.0}
AO_PROP = {"gradient": "vertical", "low": 0.72, "strength": 0.7,
           "floor": 0.5, "dist": 1.2}

PIECES = [
    ("GarageBay", build_bay, "interiors/garage_bay.glb", 1320, 0.08, "base_axis", AO_BAY),
    ("GarageDoor", build_door, "interiors/garage_door.glb", 328, 0.04, "base_axis", AO_PROP),
    ("GarageBench", build_bench, "interiors/garage_bench.glb", 748, 0.04, "base_axis", AO_PROP),
    ("GarageToolbox", build_toolbox, "interiors/garage_toolbox.glb", 764, 0.04, "base", AO_PROP),
    ("GarageTireStack", build_tire_stack, "interiors/garage_tire_stack.glb", 832, 0.04, "base", AO_PROP),
    ("GarageBarrel", build_barrel, "interiors/garage_barrel.glb", 368, 0.04, "base", AO_PROP),
    ("GarageCrate", build_crate, "interiors/garage_crate.glb", 264, 0.04, "base", AO_PROP),
]

clear_built()

total_tris = 0
for name, fn, path, baseline, bevel, origin, ao in PIECES:
    builder = fn()
    obj = builder.to_object(name)
    stats = finish(obj, bevel=bevel, origin=origin, ao=ao)
    out, size = export_glb([obj], path)
    total_tris += stats["tris"]
    flag = ""
    if stats["tris"] > baseline * GUARD:
        flag = "  <<< SARITURA (referinta %d) — primitiva la rezolutie implicita?" % baseline
    print("%-16s %5d tri  ao %.2f..%.2f  %6.1f KB  %s%s" % (
        name, stats["tris"], stats["ao_min"], stats["ao_max"],
        size / 1024.0, path, flag))
print("%-16s %5d tri  (referinta %d)" % (
    "TOTAL", total_tris, sum(p[3] for p in PIECES)))

save_blend([o for o in bpy.data.objects if o.name in [p[0] for p in PIECES]],
           "garage_bay.blend")
print("== garage_bay: gata ==")
