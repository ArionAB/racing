"""miner_shack.glb — baraca minerului, landmark id 7.
Brief: docs/asset_briefs/miner_shack.md · issue #150

Ansamblu pe TREI piese, fiindca fiecare are alta clasa de suprafata:
  Shack_Wood   scanduri decolorate      -> clasa `wood`     (UV cub 1.2 m)
  Shack_Roof   tabla ondulata ruginita  -> clasa `rust_metal` (UV cub 2.2 m)
  Shack_Trim   usa, geam, prag          -> ATLAS

Trim-ul ramane pe atlas dinadins: usa si geamul sunt GAURI, adica cele mai
inchise suprafate din obiect, si tocmai contrastul lor cu lemnul spalat de
soare face silueta sa se citeasca de la 60 m. O textura de lemn peste ele le-ar
aduce la aceeasi valoare cu peretele si baraca ar deveni o cutie.

Piesele se exporta ca UN ansamblu (origin="base_axis" + restaurarea cotei),
la fel ca la casa de sat — altfel `finish` ar aseza fiecare piesa separat pe
podea si acoperisul ar cadea pe fundatie.
"""

import math
from mathutils import Matrix

W, D, H = 4.0, 3.0, 2.35     # corpul barcii
ROOF_RISE = 0.72             # cat urca acoperisul intr-o apa
ROOF_OVER = 0.28             # streasina
ROOF_T = 0.10
POST = 0.13

DOOR_W, DOOR_H = 0.95, 1.85
WIN_W, WIN_H = 0.80, 0.62


def wood(b):
    """Peretii + stalpii de colt + o scandura desprinsa.

    Peretii NU sunt o cutie dreapta: varfurile de sus se ridica spre spate, deci
    cutia devine un ic si urmeaza panta acoperisului. Fara asta, o apa pe o
    cutie dreapta lasa un pinion DESCHIS in spate si pe laturi — la prima
    randare acoperisul plutea deasupra barcii cu 30 cm de cer intre ele. Panta
    din varfuri costa ZERO triunghiuri; un pinion construit din piese ar fi
    costat patru.
    """
    # Scandurile individuale ar fi insemnat 20 de cutii pentru un detaliu care
    # la 40 m se topeste intr-o suprafata (style_bible §3).
    body = b.box(center=(0.0, 0.0, H * 0.5), size=(W, D, H), slot=WOOD)
    b.retag(body, SAND_SHADOW, where="down")
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box(center=(sx * (W * 0.5 - POST * 0.4),
                          sy * (D * 0.5 - POST * 0.4), H * 0.5 + 0.02),
                  size=(POST, POST, H + 0.04), slot=WOOD)
    # Icul: tot ce e sus urca liniar spre -Y (spate). Se aplica DUPA stalpi, ca
    # sa urce si ei odata cu coama.
    for v in b.bm.verts:
        if v.co.z > H * 0.9:
            v.co.z = H + ROOF_RISE * (0.5 - v.co.y / D)
    # Scandura desprinsa, sprijinita de perete: singurul detaliu „narativ" —
    # spune ca baraca e parasita, si costa o cutie.
    # Grosimea e 0.10, nu 0.04: sub 5 cm scandura dispare la 40 m si lasa in
    # silueta o zgarietura, nu un obiect (style_bible §3).
    rot = Matrix.Rotation(math.radians(-24.0), 3, "Y")
    b.box(center=(W * 0.5 + 0.30, D * 0.22, 0.62), size=(0.18, 0.10, 1.35),
          slot=WOOD, rotation=rot)


def roof(b):
    """O singura apa, inclinata spre fata (+Y jos, -Y sus).

    O SINGURA placa inclinata, plus trei nervuri pe ea. Prima incercare a facut
    trei placi separate, fiecare rotita in jurul centrului EI si toate la
    aceeasi cota — adica trei trepte plutind peste baraca, nu o panta. Cand
    piesele trebuie sa formeze un plan, planul se face intai si se imparte dupa,
    nu invers.

    Ondulatia se citeste din umbra dintre nervuri; douazeci de coaste reale ar
    fi zgomot platit cu triunghiuri (style_bible §3).
    """
    slab_w = W + ROOF_OVER * 2.0
    slab_d = D + ROOF_OVER * 2.0
    # Panta se ia peste ADANCIMEA PERETILOR (D), nu peste placa cu tot cu
    # streasina: placa trebuie sa aiba exact inclinarea icului de sub ea,
    # altfel se aseaza pe el doar intr-un punct.
    tilt = math.atan2(ROOF_RISE, D)
    rot = Matrix.Rotation(-tilt, 3, "X")
    z_mid = H + ROOF_RISE * 0.5 + ROOF_T * 0.5 / math.cos(tilt)
    b.box(center=(0.0, 0.0, z_mid), size=(slab_w, slab_d, ROOF_T),
          slot=RUST, rotation=rot)
    # Nervurile merg PE PANTA (de-a lungul lui Y), asa cum curge apa pe o tabla
    # ondulata. Stau pe aceeasi rotatie, deci raman lipite de placa.
    for i in (-1, 0, 1):
        b.box(center=(i * slab_w * 0.28, 0.0, z_mid + ROOF_T * 0.72),
              size=(0.14, slab_d - 0.06, ROOF_T * 0.6),
              slot=RUST, rotation=rot)
    # Cosul, aproape de coama (partea inalta). Baza intra in placa: cota se
    # calculeaza din ecuatia planului, nu se ghiceste — pe o panta, „pe la
    # ochi" inseamna ori teava suspendata, ori teava injumatatita.
    y_ch = -D * 0.24
    z_ch = z_mid - y_ch * math.tan(tilt) + 0.38
    crot = Matrix.Rotation(math.radians(9.0), 3, "Y")
    b.box(center=(-W * 0.28, y_ch, z_ch), size=(0.26, 0.26, 1.0),
          slot=RUST, rotation=crot)


def trim(b):
    """Usa, geamul si pragul — raman pe atlas (vezi antetul).

    Fata cu usa e cea dinspre **+Y in Blender**, adica -Z in Godot: acolo
    priveste modelul dupa conversia glTF, si acolo il intoarce `_build_landmark`
    cand il aseaza cu fata la sosea. Prima versiune le pusese pe -Y, deci baraca
    ar fi aratat drumului peretele din spate.
    """
    yf = D * 0.5 + 0.015
    # Usa: o placa INCHISA lipita de perete, nu o gaura decupata. Un decupaj
    # real ar fi cerut sa spargem peretele in patru cutii; la 40 m diferenta
    # dintre o gaura si o pata inchisa nu exista.
    b.box(center=(-W * 0.18, yf, DOOR_H * 0.5), size=(DOOR_W, 0.05, DOOR_H),
          slot=ASPHALT)
    # Rama usii, din lemn mai deschis: fara ea usa e o pata, cu ea e o usa.
    b.box(center=(-W * 0.18, yf + 0.01, DOOR_H + 0.06),
          size=(DOOR_W + 0.12, 0.06, 0.12), slot=SAND_LIGHT)
    # Geamul, pe aceeasi fata.
    b.box(center=(W * 0.24, yf, 1.42), size=(WIN_W, 0.05, WIN_H),
          slot=ASPHALT)
    b.box(center=(W * 0.24, yf + 0.01, 1.42),
          size=(WIN_W + 0.10, 0.06, 0.07), slot=SAND_LIGHT)
    # Pragul de beton, in fata usii.
    b.box(center=(-W * 0.18, yf + 0.28, 0.07), size=(DOOR_W + 0.3, 0.62, 0.14),
          slot=CONCRETE)


AO_SPEC = dict(samples=28, dist=2.2, gradient="vertical",
               low=0.45, high=1.0, power=0.8, floor=0.15)

# (nume nod, functie, bevel, marime UV cub sau None = ramane pe atlas)
# Numele sunt CONTRACTUL cu Godot: `_LANDMARKS[7]["classes"]` mapeaza
# Shack_Wood/Shack_Roof pe clase; Shack_Trim nu e mapat si cade pe atlas.
PARTS = [
    ("Shack_Wood", wood, 0.04, 1.2),
    ("Shack_Roof", roof, 0.04, 2.2),
    ("Shack_Trim", trim, 0.03, None),
]

clear_built("Shack_")
built = []
total = 0
for name, fill, bevel, uv_size in PARTS:
    b = Builder()
    fill(b)
    obj = b.to_object(name)
    min_z = min(v[2] for v in obj.bound_box)
    stats = finish(obj, bevel=bevel, ao=AO_SPEC, origin="base_axis")
    # finish() coboara baza piesei la z=0, corect pentru un asset de sine
    # statator. Aici piesele sunt UN ansamblu, deci cota se restaureaza.
    obj.location.z = min_z
    if uv_size is not None:
        cube_uvs(obj, uv_size)
    total += stats["tris"]
    built.append(obj)
    print("%-12s %4d tris  AO %.2f..%.2f  uv=%s"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             "cub %.1f" % uv_size if uv_size else "atlas"))

print("TOTAL: %d tris (buget 1500)" % total)
print("GLB:   %s (%d B)" % export_glb(built, "buildings/miner_shack.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "miner_shack.blend"))
