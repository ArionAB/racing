"""coral_rock.glb — stanci de calcar coraligen (Okinawa), opt marimi.

Referinta: assets/okinawa_inspiration/, randul CORAL ROCKS (CORAL_ROCK_01..08,
0.4 -> 4.0 m). Nu sunt bolovani: sunt PLACI suprapuse cu streasina, ca un recif
ridicat si erodat pe dedesubt. Diferenta conteaza — un elipsoid perturbat
citeste "desert", un teanc de placi cu umbra sub fiecare citeste "coasta".

NUMELE NODURILOR SUNT CONTRACT, nu preferinta. `track_decor._add_coral_rock`
cauta `Coral_Rock_%02d` cu indici 1..8 (`scenes/tracks/track_decor.gd:359`).
Prima versiune a acestui fisier exporta `CoralRock_04`/`CoralRock_06`: Godot
nu gasea nimic, cadea tacut pe cutii colorate si testele ramaneau verzi —
exact regresia invizibila descrisa in docs/blender_export.md. Daca redenumesti
ceva aici, cauta intai in GDScript.

Material: clasa `coral_rock`, TRIPLANAR in spatiul lumii — deci UV-urile raman
colapsate pe sloturi si placile vecine isi continua tiparul una in alta, exact
mecanica falezelor din canion. Stancile nu se misca, deci proiectia de lume e
cea corecta (style_bible §4).
"""

import math
from mathutils import Matrix

# Placile alterneaza intre bazalt si un gri de asfalt. Sub clasa triplanara
# culoarea vine din textura, dar sloturile TOT conteaza — si aici s-a vazut de
# ce: prima versiune folosea `ROCK_DARK` (#67421F, gresia canionului) ca strat
# de mijloc, iar cand `track_decor` a pus din greseala materialul lumii in loc
# de clasa, stancile de recif au iesit cu peretii PORTOCALII. Cu ASPHALT_EDGE
# (#696765) chiar si esecul arata a piatra de coasta.
STRATA = (VOLCANIC_BLACK, ASPHALT_EDGE, VOLCANIC_BLACK)


def slab(b, center, size, seed, yaw=0.0):
    """O placa: pereti aproape verticali (taper mic) si capac plat.

    `taper` 0.05 in loc de 0.35: la valoarea implicita iese o movila, si tocmai
    muchia dreapta de sub capac face umbra care vinde streasina.
    """
    # 7 segmente, nu 9: pe 97 de stanci pe tur, cele doua fatete in plus
    # costau 11 000 de triunghiuri si nu se vad — style_bible §3 cere oricum
    # fatete LATE, nu detaliu de frecventa inalta.
    faces = b.rock(center, size, VOLCANIC_BLACK, seed=seed, segments=7,
                   rings=3, flat_top=True, taper=0.05, squash=0.98,
                   strata_slots=STRATA)
    if yaw:
        rot = Matrix.Rotation(math.radians(yaw), 4, "Z")
        pivot = Matrix.Translation(center) @ rot @ Matrix.Translation(
            (-center[0], -center[1], -center[2]))
        verts = set()
        for f in faces:
            verts.update(f.verts)
        for v in verts:
            v.co = pivot @ v.co
    return faces


def stack(target_h, width, seed, plates):
    """Genereaza teancul de placi pentru o cota ceruta.

    Cotele din foaia de referinta merg de la 0.4 la 4.0 m, adica de zece ori;
    a scrie opt teancuri de mana ar fi insemnat opt ocazii de a gresi o cota.
    Aici forma e o FUNCTIE de inaltime: placile se subtiaza spre varf, se
    ingusteaza cu ~12% pe treapta si se decaleaza lateral alternativ, ca teancul
    sa iasa in consola intr-o parte si in alta — nu un turn de clatite centrate.

    Placile se aseaza cu `Builder.flat_top_z`: `flat_top` reteaza varful la 82%
    din inaltimea ceruta, iar o grila derivata din cota NOMINALA lasa fante prin
    care se vede interiorul stancii (nota din dio_lib).

    DE-AIA GROSIMILE SE NORMALIZEAZA la final. Cei 82% se compun pe fiecare
    treapta, deci prima versiune, care alegea grosimile direct din `target_h`,
    scotea 0.19 m pentru 0.4 ceruti si 2.32 pentru 2.6 — cu cat teancul avea mai
    putine placi, cu atat ratarea era mai mare. Se genereaza intai formele, se
    masoara cat iese, si abia apoi se scaleaza toate grosimile cu raportul.
    """
    rnd = _lcg(seed)
    shapes = []
    w = width
    for i in range(plates):
        # Placa de jos e cea mai groasa; spre varf se subtiaza.
        h = (0.30 - 0.030 * i) * (0.88 + rnd() * 0.28)
        off = (0.24 + rnd() * 0.20) * w * (1.0 if i % 2 else -1.0)
        shapes.append([h, off * 0.72, off * -0.55, w, w * 0.79,
                       seed + i * 13, (rnd() - 0.5) * 60.0])
        w *= 0.88 - rnd() * 0.05

    raw_top = 0.0
    for s in shapes:
        raw_top = Builder.flat_top_z(raw_top, s[0])
    k = target_h / max(raw_top, 1e-6)

    out, z = [], 0.0
    for (h, x, y, sx, sy, s, yaw) in shapes:
        h *= k
        out.append((x, y, z + h * 0.5, sx, sy, h, s, yaw))
        z = Builder.flat_top_z(z, h)
    return out


# (nume, inaltime tinta, latimea placii de baza, seed, cate placi)
#
# Cotele sunt cele din foaia de referinta. Numarul de placi creste cu marimea:
# o piatra de 0.4 m e o singura lespede, una de 4 m e un recif in trepte.
#
# Latimile NU cresc proportional cu inaltimea: o lespede de 0.4 m e mai lata
# decat inalta de doua ori si jumatate (asa arata un recif ras de valuri), pe
# cand teancul de 4 m e cam la fel de lat pe cat e de inalt. Latimea data aici e
# a placii de baza; bbox-ul final iese cu ~15% mai mare din decalajele laterale.
SHAPES = [
    ("Coral_Rock_01", 0.40, 0.95, 11, 2),
    ("Coral_Rock_02", 0.80, 1.35, 23, 2),
    ("Coral_Rock_03", 1.20, 1.75, 31, 2),
    ("Coral_Rock_04", 1.60, 2.30, 43, 3),
    ("Coral_Rock_05", 2.00, 2.60, 47, 3),
    ("Coral_Rock_06", 2.60, 3.20, 53, 4),
    ("Coral_Rock_07", 3.20, 3.70, 61, 4),
    ("Coral_Rock_08", 4.00, 4.30, 71, 5),
]

# AO: `dist` mare (3 m) fiindca ce trebuie prins e umbra DINTRE placi, iar
# streasina de sus e la un metru de fata de dedesubt. Cu raza mica ies placi
# la fel de luminate si teancul se aplatizeaza intr-o singura masa.
AO_SPEC = dict(samples=32, dist=3.0, gradient="vertical",
               low=0.44, high=1.0, power=0.9, floor=0.14)

clear_built("Coral_Rock_")
built = []
for i, (name, target_h, width, seed, plates) in enumerate(SHAPES):
    b = Builder()
    for (x, y, z, sx, sy, sz, s, yaw) in stack(target_h, width, seed, plates):
        slab(b, (x, y, z), (sx, sy, sz), s, yaw)
    obj = b.to_object(name)
    # Bevel mic si prag de netezire jos (25° in loc de 55°): pe restul familiei
    # de stanci netezirea larga e ce le tine rotunjite, dar aici muchia dintre
    # placi E asset-ul. La 55° fatetele se topeau una in alta si teancul iesea
    # un bolovan de rau — verificat in preview inainte de a schimba cifra.
    stats = finish(obj, bevel=min(0.06, target_h * 0.05), ao=AO_SPEC,
                   smooth_angle=25.0)
    obj.location = (i * 7.0, 0.0, 0.0)
    built.append(obj)
    d = obj.dimensions
    print("%-14s %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m (tinta %.1f)"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z, target_h))

print("TOTAL: %d tris" % sum(tri_count(o) for o in built))
for o in built:
    o.location = (0.0, 0.0, 0.0)
print("GLB:  %s (%d B)" % export_glb(built, "rocks/coral_rock.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "coral_rock.blend"))
for i, o in enumerate(built):
    o.location = (i * 7.0, 0.0, 0.0)
