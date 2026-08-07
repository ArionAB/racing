"""sea_turtle.glb — broasca testoasa de mare (SEA_TURTLE, ~3.7 m).

Inlocuieste sabani ca `hazard_model` pe Okinawa manual: in loc de o barca targ ita
peste drum, o testoasa uriasa care traverseaza soseaua. Aceeasi mecanica
(SlidingHazard), alt personaj — si unul care apartine insulei mai bine decat o
barca aflata la 40 m de apa.

CE DECIDE FORMA, in ordinea in care se vede din masina la 25 m:
  1. SILUETA IN PLAN. O testoasa de mare se recunoaste dupa lopetile din fata,
     nu dupa carapace: sunt mai late decat cochilia (3.5 m fata de 2.1 m) si sunt
     singurul lucru care o deosebeste de un bolovan turtit. De aia sunt `blade`
     (lamele plate cu grosime), nu tuburi.
  2. MARGINEA CARAPACEI. Un dom maro pe un drum de nisip se pierde in fundal —
     inelul de scuturi marginale in DRY_VEGETATION taie silueta de fundal la
     orice unghi. E acelasi truc ca la kerbs: o dunga clara pe conturul obiectului.
  3. CREASTA. Cele cinci noduri de pe linia mediana dau domului o DIRECTIE; fara
     ele carapacea e o calota simetrica si nu se citeste incotro merge animalul.

DE CE NU E RUPTA PE CLASE DE MATERIAL (spre deosebire de sabani, care are coca
pe clasa `wood`): nicio clasa din Palette.CLASS_TEXTURES nu e o carapace, iar a
inventa una ar insemna +1 material pe o pista care sta la 22 din 38. Detaliul de
suprafata vine din geometrie (scuturi marginale evazate, noduri de creasta) si
din AO copt — adica gratis. Tot obiectul sta pe atlas, deci in Godot ii ajunge
`Palette.apply_world_material` (SlidingHazard il face singur cand `model_classes`
si `model_tri_class` sunt goale).

ORIENTARE: construita cu botul spre +Y in Blender, adica spre -Z in Godot — fata
nodului. Track._build_hazard roteste hazardul pe directia de maturare
(`hazard_face_travel`), deci testoasa merge INCOTRO se uita, nu de-a latul.
"""

import math
from mathutils import Vector

SHELL_LEN = 2.60     # Y — lungimea carapacei
SHELL_WID = 2.20     # X — latimea ei maxima
DOME = 0.52          # cat urca domul peste marginea carapacei
RIM_Z = 0.46         # cota marginii carapacei (sub ea: plastronul)
SEG = 14             # segmente in jurul carapacei


def _ring(sx, sy, z):
    """Un inel de carapace: elipsa ingustata in fata, latita in spate.

    `w` face conturul in forma de inima — cel mai lat punct cade INAPOIA
    mijlocului, ca la o testoasa reala. Fara el iese o migdala simetrica, adica
    exact silueta unui bolovan turtit.
    """
    pts = []
    for i in range(SEG):
        a = 2.0 * math.pi * i / SEG          # 0 = spre bot (+Y)
        w = 1.0 - 0.16 * math.cos(a)
        pts.append((SHELL_WID * 0.5 * math.sin(a) * w * sx,
                    SHELL_LEN * 0.5 * math.cos(a) * sy,
                    z))
    return pts


def _dome_levels():
    """Cotele domului.

    Doua exponenti fac toata forma, si prima versiune i-a avut pe amandoi gresit:
      - `sy` scade mult mai INCET decat `sx` (0.30 fata de 0.80), deci inelul de
        sus ramane un OVAL LUNG, nu un punct: carapacea se termina intr-o creasta
        pe linia mediana, nu intr-un varf de con.
      - inaltimea creste cu sin^1.5, nu sin^0.9. Cu exponent sub 1, jumatate din
        inaltime se castiga in prima treime a domului, iar peretii ies aproape
        VERTICALI langa margine: capturile de control aratau o paine, nu o
        carapace. Peste 1, suprafata pleaca aproape orizontal din margine si se
        curbeaza dupa aceea — profilul unei testoase de mare.
    """
    out = []
    for v in (0.0, 0.32, 0.58, 0.80, 0.94):
        c = math.cos(v * math.pi * 0.5)
        out.append((c ** 0.80, c ** 0.30,
                    RIM_Z + DOME * math.sin(v * math.pi * 0.5) ** 1.5))
    return out


# De jos in sus: fundul plastronului, plastronul, marginea evazata, domul.
# Slotul e al BENZII dintre inelul curent si urmatorul.
PLASTRON = [
    ((0.30, 0.30, RIM_Z - 0.44), CORAL_SAND),
    ((0.66, 0.66, RIM_Z - 0.40), CORAL_SAND),
    ((0.94, 0.94, RIM_Z - 0.30), CORAL_SAND),
    ((1.10, 1.07, RIM_Z - 0.20), DRY_VEGETATION),   # scuturile marginale
]


def shell(b):
    """Carapacea + plastronul, dintr-un singur tub inchis de inele.

    Se scrie direct pe `b.bm` din acelasi motiv ca la coca sabani: `revolve` face
    sectiuni CIRCULARE, iar aici fiecare inel are alta forma in plan si alta
    proportie X/Y. Slotul se pune pe fata, nu prin `_tag`: inelele vecine impart
    varfuri, deci un tag prin varfuri ar scurge culoarea marginii in tot domul.
    """
    levels = [(pos, slot) for pos, slot in PLASTRON]
    levels += [((sx, sy, z), WOOD) for sx, sy, z in _dome_levels()]

    rings = [[b.bm.verts.new(p) for p in _ring(*pos)] for pos, _s in levels]
    for (lo, hi), (_pos, slot) in zip(zip(rings, rings[1:]), levels):
        for i in range(SEG):
            j = (i + 1) % SEG
            f = b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
            f[b.slot] = slot
    # Capacele. Fara ele carapacea e o coaja deschisa, iar fetele interioare sunt
    # backface — s-ar vedea drumul prin testoasa (capcana din antetul sabani).
    b.bm.faces.new(tuple(reversed(rings[0])))[b.slot] = CORAL_SAND
    b.bm.faces.new(tuple(rings[-1]))[b.slot] = WOOD


def keel(b):
    """Creasta de pe linia mediana: cinci noduri care se ATING.

    Prima versiune le-a lasat departate (0.22 lungime la pas de 0.275) si ieseau
    cinci nasturi lipiti pe carapace. Puse cap la cap, cu o suprapunere de 2 cm,
    devin o singura muchie crestata — adica exact ce da domului o directie.
    Stau pe capacul de sus, care e plan (inel de raza constanta), deci se aseaza
    la o cota fixa fara sa trebuiasca urmarita curbura.
    """
    top_z = _dome_levels()[-1][2]
    for k in range(5):
        b.box((0.0, (k - 2) * 0.26, top_z - 0.01), (0.28, 0.30, 0.09),
              DRY_VEGETATION)


def head(b):
    """Gat + cap + cioc + ochi. Capul e o CUTIE tesita, nu un tub: bevel-ul ii da
    rotunjimea, iar muchia de sus ramane — un cap de testoasa e turtit, nu sferic.

    Cotele sunt joase INTENTIONAT (capul sub cota marginii carapacei): la prima
    incercare statea la nivelul domului si arata ca o cutie care pluteste langa
    carapace, cu gatul ascuns in ea. Un cap de testoasa iese de sub cochilie.

    Gatul e mai SUBTIRE decat inaltimea capului (raza 0.17 la capat, fata de 0.34
    inaltimea cutiei). Invers — cum era la prima incercare — tubul iesea peste
    crestetul capului si citea ca o a doua piesa lipita in spatele lui."""
    b.taper_sweep([(0.0, 0.95, 0.50), (0.0, 1.44, 0.48)], [0.22, 0.17],
                  TROPICAL_GREEN, segments=8)
    b.box((0.0, 1.66, 0.47), (0.48, 0.58, 0.34), TROPICAL_GREEN)
    # Ciocul: singurul accent deschis pe cap, deci si singurul lucru care spune
    # in ce parte se uita animalul de la distanta.
    b.box((0.0, 1.94, 0.41), (0.24, 0.16, 0.15), CORAL_SAND)
    for sx in (-1.0, 1.0):
        b.box((sx * 0.20, 1.81, 0.55), (0.12, 0.12, 0.12), VOLCANIC_BLACK)


def flippers(b):
    """Lopetile. `up=(0,0,1)` tine lamela in plan ORIZONTAL: latimea creste
    perpendicular pe (vertical, traseu), deci paleta ramane plata cum sta o
    lopata de testoasa pe nisip, oricat s-ar curba traseul.

    Cele din fata masoara 1.75 m de la axa — mai LATE decat carapacea (1.10 m),
    si asta e tot rostul lor: silueta in plan e singurul lucru care deosebeste o
    testoasa de mare de un bolovan turtit. La prima incercare erau de 1.62 m si
    prea scurte fata de latimea lor, deci citeau a aripioare.
    """
    for sx in (-1.0, 1.0):
        b.blade([(sx * 0.58, 0.76, 0.42),
                 (sx * 1.22, 0.70, 0.30),
                 (sx * 1.75, 0.24, 0.13)],
                [0.48, 0.60, 0.24], 0.12, TROPICAL_GREEN, up=(0, 0, 1))
        b.blade([(sx * 0.54, -0.86, 0.38),
                 (sx * 0.95, -1.20, 0.24),
                 (sx * 1.20, -1.50, 0.12)],
                [0.42, 0.40, 0.18], 0.10, TROPICAL_GREEN, up=(0, 0, 1))


def tail(b):
    b.taper_sweep([(0.0, -1.18, 0.40), (0.0, -1.52, 0.30), (0.0, -1.74, 0.24)],
                  [0.15, 0.09, 0.0], TROPICAL_GREEN, segments=6)


# AO: gradient vertical pe TOT ansamblul (0 .. 1.2), ca burta si radacina
# lopetilor sa iasa inchise si domul luminat. `dist` mic (1.6 m): ocluzia care
# conteaza e sub carapace si intre noduri, nu la scara obiectului intreg.
AO_SPEC = dict(samples=28, dist=1.6, gradient="vertical",
               low=0.42, high=1.0, power=0.85, floor=0.16, z_range=(0.0, 1.20))

clear_built("Sea_Turtle")
b = Builder()
shell(b)
keel(b)
head(b)
flippers(b)
tail(b)
obj = b.to_object("Sea_Turtle")
stats = finish(obj, bevel=0.035, origin="base", ao=AO_SPEC)

bpy.context.view_layer.update()
d = obj.dimensions
print("sea_turtle.glb  %d tris  AO %.2f..%.2f"
      % (stats["tris"], stats["ao_min"], stats["ao_max"]))
print("  %.2f m lungime (Z in Godot), %.2f m latime, %.2f m inaltime"
      % (d.y, d.x, d.z))
print("GLB:  %s (%d B)" % export_glb([obj], "sea_turtle.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "sea_turtle.blend"))
