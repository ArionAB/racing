"""gas_station.glb — benzinarie de sosea. Brief: docs/asset_briefs/gas_station.md

Piesa "hero": silueta mare, zero detaliu fin.
Fata cu pompele spre -Z in Godot (= +Y in Blender).

#D1 (valul 3) o imbogateste PE LOC. Contractul e invers fata de valurile 1-2:
nu se creeaza fisier nou, ci se suprascrie — deci

  * nodul ramane `GasStation`
  * bbox-ul NU are voie sa creasca. Poate scadea.

`_LANDMARKS` din `scenes/tracks/track.gd:1359` hardcodeaza colizorul
(`size = Vector3(8.0, 5.0, 6.0)`), iar silueta e deja plasata pe pista. Orice
crestere ar scoate geometrie prin colizor fara nicio eroare. Scriptul masoara
bbox-ul la fiecare rulare si il compara cu cel de dinaintea imbogatirii.

#128 (texturi de clasa) o sparge pe CLASA DE SUPRAFATA. Contractul de mai sus
NU se schimba: geometria e identica, doar imprastiata pe patru noduri, iar
bbox-ul se masoara acum pe ansamblu.

  Gas_Wood     -> clasa `wood`      peretii cladirii, stalpii copertinei, lada
  Gas_Rust     -> clasa `rust_metal` acoperisul, copertina, aerisirile, butoaiele
  Gas_Concrete -> clasa `concrete`  dala, insula pompelor, corpurile lor, cosul
  Gas_Trim     -> ATLAS             ferestrele, panoul, steaua, fascia, cauciucurile

Ce ramane pe atlas ramane din motive, nu din lene: geamurile traiesc din slotul
CEL MAI INCHIS (adancimea falsa a lui `window()` se sprijina pe el), iar panoul,
fascia rosie si steaua sunt accente de culoare — o textura le-ar sterge exact
lucrul pentru care exista. Vezi style_bible §4.
"""

import math
from mathutils import Matrix

SLAB_T = 0.20
WALL_TOP = 3.20
ROOF_PITCH = math.radians(18.0)   # style_bible §3: panta 18°, regula de coerenta

BLD_X, BLD_Y = -1.30, -1.00       # centrul cladirii pe dala
BLD_W, BLD_D = 5.00, 4.00
OVERHANG = 0.30

# Panta de 18° peste jumatatea de adancime + streasina da coama la ~3.95 m.
# (Brief-ul spune "coama la ~4.6 m", dar asta ar cere 35° si ar rupe regula de
# panta din style bible. Am pastrat panta; nota in raport.)
ROOF_HALF = BLD_D * 0.5 + OVERHANG
ROOF_RISE = ROOF_HALF * math.tan(ROOF_PITCH)
RIDGE_Z = WALL_TOP + ROOF_RISE
SLOPE_LEN = ROOF_HALF / math.cos(ROOF_PITCH)

CANOPY_X, CANOPY_Y = 0.50, 1.80
CANOPY_W, CANOPY_D = 4.50, 2.80
CANOPY_Z = 3.60


# `star_outline` traia aici; a urcat in dio_lib fiindca #C4 (gas_pole_sign) il
# refoloseste. Valorile implicite sunt neschimbate, deci benzinaria se
# regenereaza identic.

FRONT_Y = BLD_Y + BLD_D * 0.5
SIDE_X = BLD_X + BLD_W * 0.5
PANEL_Z = RIDGE_Z + 0.55
CHIM_X = BLD_X - BLD_W * 0.5 + 0.42

# Metri per repetitie, PE CLASA — aceleasi cifre ca la celelalte assets.
UV_WOOD = 1.2
UV_RUST = 2.2
UV_CONCRETE = 2.2


def gas_wood(b):
    """Peretii cladirii, stalpii copertinei, lada de langa pompe."""
    b.box(center=(BLD_X, BLD_Y, (SLAB_T + WALL_TOP) * 0.5),
          size=(BLD_W, BLD_D, WALL_TOP - SLAB_T), slot=WOOD)
    for dx in (-1.90, 1.90):
        b.box(center=(CANOPY_X + dx, CANOPY_Y + CANOPY_D * 0.5 - 0.30,
                      (SLAB_T + CANOPY_Z) * 0.5),
              size=(0.26, 0.26, CANOPY_Z - SLAB_T), slot=WOOD)
    b.box(center=(-3.05, 1.70, SLAB_T + 0.32), size=(0.90, 0.70, 0.64), slot=WOOD,
          rotation=Matrix.Rotation(math.radians(14.0), 3, "Z"))


def gas_rust(b):
    """Acoperisul, copertina, aerisirile, butoaiele — tot ce e tabla."""
    # Acoperis in doua ape, coama pe X, cu streasina
    for sign in (+1, -1):
        b.box(center=(BLD_X, BLD_Y + sign * ROOF_HALF * 0.5,
                      WALL_TOP + ROOF_RISE * 0.5),
              size=(BLD_W + 2 * OVERHANG, SLOPE_LEN, 0.16), slot=RUST,
              rotation=Matrix.Rotation(-sign * ROOF_PITCH, 3, "X"))
    b.box(center=(BLD_X, BLD_Y, RIDGE_Z),
          size=(BLD_W + 2 * OVERHANG, 0.22, 0.14), slot=RUST)

    b.box(center=(CANOPY_X, CANOPY_Y, CANOPY_Z),
          size=(CANOPY_W, CANOPY_D, 0.22), slot=RUST)

    # Linia acoperisului era perfect dreapta pe toata deschiderea. Trei
    # accidente mici o rup — si toate stau SUB 4.93 m, cota maxima a bbox-ului
    # actual (data de panoul de deasupra coamei), ca sa nu creasca gabaritul.
    for dx, dy in ((-1.55, -0.55), (0.55, -0.75)):
        b.box(center=(BLD_X + dx, BLD_Y + dy, RIDGE_Z - 0.34),
              size=(0.42, 0.42, 0.40), slot=RUST)
    # turbinat de ventilatie
    b.frustum(center=(BLD_X + 1.45, BLD_Y - 0.35, RIDGE_Z - 0.10), r_bottom=0.16,
              r_top=0.30, depth=0.46, slot=RUST, segments=8)
    b.box(center=(BLD_X + 1.45, BLD_Y - 0.35, RIDGE_Z + 0.16),
          size=(0.70, 0.70, 0.08), slot=RUST)
    b.box(center=(CHIM_X, BLD_Y - 1.05, 4.44), size=(0.62, 0.62, 0.16), slot=RUST)

    # Doua butoaie langa pompe. `retag`-ul de capac ramane in cod desi sub
    # textura de clasa nu se mai vede: e o schimbare de SLOT, iar piesa nu mai
    # citeste atlasul. Rugina isi aduce propria variatie in loc.
    for (cx, cy) in ((2.90, 0.55), (3.35, 1.35)):
        faces = b.revolve(
            profile=[(0.28, 0.0), (0.31, 0.10), (0.31, 0.78), (0.28, 0.88)],
            slot=RUST, segments=8, origin=(cx, cy, SLAB_T))
        for z in (0.26, 0.62):
            b.torus(center=(cx, cy, SLAB_T + z), major_r=0.325, minor_r=0.035,
                    slot=RUST, major_seg=8, minor_seg=4)
        b.retag(faces, SAND_SHADOW, where="up")


def gas_concrete(b):
    """Dala, pragul, insula si corpurile pompelor, cosul."""
    slab_faces = b.box(center=(0.0, 0.0, SLAB_T * 0.5), size=(8.0, 6.0, SLAB_T),
                       slot=CONCRETE)
    b.box(center=(BLD_X - 1.30, FRONT_Y + 0.06, SLAB_T * 0.5 + 0.04),
          size=(1.26, 0.34, 0.14), slot=CONCRETE)   # pragul usii
    b.box(center=(CANOPY_X, CANOPY_Y, SLAB_T + 0.075),
          size=(2.80, 0.90, 0.15), slot=CONCRETE)
    for dx in (-0.90, 0.90):
        b.box(center=(CANOPY_X + dx, CANOPY_Y, SLAB_T + 0.15 + 0.60),
              size=(0.60, 0.40, 1.20), slot=CONCRETE)
    # Cos pe latura dinspre -X. Se opreste la 4.30 m; palaria lui e la rugina.
    b.box(center=(CHIM_X, BLD_Y - 1.05, (SLAB_T + 4.30) * 0.5),
          size=(0.46, 0.46, 4.30 - SLAB_T), slot=CONCRETE)
    # `retag` pe fetele de sus ale dalei: praful se aseaza pe orizontale
    # (style_bible §4). Inert sub textura de clasa, pastrat ca sursa de adevar.
    b.retag(slab_faces, SAND_MID, where="up")


def gas_trim(b):
    """Ce ramane pe ATLAS: geamurile, accentele de culoare, cauciucurile."""
    # Usa si ferestrele. Erau trei placi intunecate LIPITE de perete (0.12
    # grosime, la 2 cm de fata), adica vopsea, nu deschideri. `window()` face
    # diferenta cu rama si cu geamul retras: retragerea e cea care produce umbra
    # proprie, deci senzatia de gol. Ala e tot rostul ajutorului, si benzinaria
    # era exemplul citat in docstring-ul lui.
    #
    # Raman pe atlas fiindca adancimea falsa se sprijina pe slotul CEL MAI
    # INCHIS din lume; orice textura acolo adauga detaliu, adica transforma
    # golul in suprafata.
    b.window(center=(BLD_X - 1.30, FRONT_Y, SLAB_T + 1.08), w=0.98, h=2.16,
             frame_t=0.13, depth=0.18, glass_slot=ASPHALT, frame_slot=WOOD,
             mullions=(0, 1))                   # usa: un traversant, ca la tocarie
    b.window(center=(BLD_X + 0.10, FRONT_Y, SLAB_T + 1.90), w=1.46, h=1.26,
             frame_t=0.11, depth=0.16, glass_slot=ASPHALT, frame_slot=WOOD,
             mullions=(1, 0))
    b.window(center=(BLD_X + 1.70, FRONT_Y, SLAB_T + 1.90), w=1.06, h=1.26,
             frame_t=0.11, depth=0.16, glass_slot=ASPHALT, frame_slot=WOOD,
             mullions=(1, 0))
    # Vitrina, pe peretele lateral dinspre pompe (+X). `window()` primeste o
    # rotatie, deci acelasi ajutor serveste si peretii care nu privesc spre +Y.
    b.window(center=(SIDE_X, BLD_Y - 0.20, SLAB_T + 1.62), w=2.10, h=1.70,
             frame_t=0.13, depth=0.18, glass_slot=ASPHALT, frame_slot=WOOD,
             mullions=(1, 0), rotation=Matrix.Rotation(math.radians(-90.0), 3, "Z"))

    # Fascia: dunga de accent pe muchia din fata a copertinei, ca sa se citeasca
    # de departe. Era o cutie plata; acum e tabla ondulata. E cea mai mare
    # schimbare de senzatie de suprafata din tot asset-ul, pe o piesa care sta
    # la nivelul ochiului si prinde lumina razanta. 5 nervuri pe 4.5 m dau un
    # pas de 0.45 m — peste pragul de 0.4 m sub care `corrugate` avertizeaza ca
    # devine moar la viteza. Centrul e retras cu exact `depth`, ca varful
    # nervurilor sa cada unde era fata cutiei vechi. Fara asta gabaritul creste
    # cu 5 cm pe Z — prins de garda de mai jos la prima rulare, si genul de
    # crestere pe care nimeni n-ar observa-o intr-un render, dar care scoate
    # geometrie prin colizorul hardcodat.
    b.corrugate(center=(CANOPY_X, CANOPY_Y + CANOPY_D * 0.5 - 0.05,
                        CANOPY_Z - 0.16),
                size=(CANOPY_W, 0.14, 0.30), slot=KERB_RED, ribs=5, depth=0.05)

    # Capetele pompelor si ciocurile
    for dx in (-0.90, 0.90):
        px = CANOPY_X + dx
        base = SLAB_T + 0.15
        b.box(center=(px, CANOPY_Y, base + 1.26), size=(0.62, 0.42, 0.12),
              slot=PAINTED)
        # ciocul: bloc scurt, NU tub subtire (se pierde la viteza)
        b.box(center=(px, CANOPY_Y + 0.30, base + 0.95), size=(0.16, 0.22, 0.16),
              slot=PAINTED)

    # Panoul "GAS STATION"
    for dx in (-0.85, 0.85):
        b.box(center=(BLD_X + dx, FRONT_Y - 0.35, RIDGE_Z - 0.10),
              size=(0.12, 0.12, 1.00), slot=PAINTED)
    b.box(center=(BLD_X, FRONT_Y - 0.40, PANEL_Z), size=(2.60, 0.12, 0.86),
          slot=KERB_RED)
    b.box(center=(BLD_X, FRONT_Y - 0.30, PANEL_Z), size=(2.40, 0.10, 0.70),
          slot=CONCRETE)
    # Stea de accent. NU galben: sloturile 14-16 sunt rezervate masinilor
    # (style_bible §1).
    b.prism(star_outline(0.42), 0.12, KERB_RED,
            center=(BLD_X + 1.90, FRONT_Y - 0.35, PANEL_Z + 0.10))

    # Teanc de cauciucuri: negrul curat E cauciucul.
    for k, z in enumerate((0.14, 0.40, 0.66)):
        b.torus(center=(-2.60 + 0.06 * k, 2.35, SLAB_T + z), major_r=0.36,
                minor_r=0.13, slot=ASPHALT, major_seg=8, minor_seg=5)


PARTS = [
    ("Gas_Wood", gas_wood, UV_WOOD),
    ("Gas_Rust", gas_rust, UV_RUST),
    ("Gas_Concrete", gas_concrete, UV_CONCRETE),
    ("Gas_Trim", gas_trim, None),
]

clear_built("GasStation")
clear_built("Gas_")

raw = []
for name, fill, uv_size in PARTS:
    bb = Builder()
    fill(bb)
    raw.append((name, bb.to_object(name), uv_size))

# Originea si gradientul de AO sunt proprietati ale ANSAMBLULUI, nu ale piesei
# (vezi `z_range` in dio_lib.bake_ao). Fara asta, dala de 20 cm si-ar coace
# singura un gradient complet, iar acoperisul ar iesi uniform luminat.
allv = [v.co for _, o, _ in raw for v in o.data.vertices]
lo = [min(v[a] for v in allv) for a in range(3)]
hi = [max(v[a] for v in allv) for a in range(3)]
shift = (-(lo[0] + hi[0]) * 0.5, -(lo[1] + hi[1]) * 0.5, -lo[2])
z_span = (lo[2] + shift[2], hi[2] + shift[2])

objs = []
total = 0
for name, obj, uv_size in raw:
    for v in obj.data.vertices:
        v.co.x += shift[0]
        v.co.y += shift[1]
        v.co.z += shift[2]
    stats = finish(
        obj,
        bevel=0.08, bevel_angle=30.0,
        ao=dict(samples=32, dist=3.5, gradient="vertical",
                low=0.55, high=1.00, power=1.0, floor=0.13, z_range=z_span),
        origin=None,
    )
    if uv_size is not None:
        cube_uvs(obj, uv_size)
    total += stats["tris"]
    objs.append(obj)
    print("  %-14s %4d tris | AO %.2f..%.2f | uv=%s"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             "cub %.1f m" % uv_size if uv_size else "atlas"))

# Bbox-ul se masoara DUPA bevel, pe toate piesele: BEFORE a fost luat asa, iar
# bevel-ul cu MITER_ARC misca varfurile cu cativa milimetri.
fin = [v.co for o in objs for v in o.data.vertices]
ext = [(min(v[a] for v in fin), max(v[a] for v in fin)) for a in range(3)]
# Bbox in coordonate GODOT (x, y, z) = (x_bl, z_bl, -y_bl), fiindca acolo se
# scrie colizorul. Cotele de referinta sunt cele masurate INAINTE de #D1.
BEFORE = (8.10, 4.93, 6.58)
now = (ext[0][1] - ext[0][0], ext[2][1] - ext[2][0], ext[1][1] - ext[1][0])
print("GasStation -> %d tris pe %d piese" % (total, len(objs)))
print("coama la %.2f m (panta %.0f°)" % (RIDGE_Z, math.degrees(ROOF_PITCH)))
print("bbox Godot X/Y/Z : %.2f x %.2f x %.2f   (inainte de #D1: %.2f x %.2f x %.2f)"
      % (now + BEFORE))
# Toleranta de 1 cm, si e argumentata, nu comoda: bevel-ul cu MITER_ARC misca
# varfurile cu cativa milimetri, iar interactiunea dintre piese noi si cele
# vechi schimba banda de bevel chiar acolo unde geometria n-a fost atinsa.
# Masurat aici: +4 mm, simetric pe ambele capete ale axei — semnatura zgomotului
# de bevel, nu a unei piese care iese. Peste 1 cm inseamna geometrie noua si
# garda trebuie sa pice.
TOL = 0.01
deltas = ["%s %+.3f" % (ax, n - o) for ax, n, o in zip("XYZ", now, BEFORE)]
grown = [ax for ax, n, o in zip("XYZ", now, BEFORE) if n > o + TOL]
print("delta gabarit    : %s  (toleranta %+.0f mm, zgomot de bevel)"
      % (", ".join(deltas), TOL * 1000))
print("gabarit          : %s" % ("NU a crescut  OK" if not grown
                                 else "A CRESCUT pe " + ",".join(grown) + "  !!"))
print("GLB:   %s (%d B)" % export_glb(objs, "buildings/gas_station.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "gas_station.blend"))
