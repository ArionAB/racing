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

SCHELET SI ANIMATIE (aug 2026): pe PathMover testoasa ALUNECA pe drum cu
lopetile teapene — un bolovan verde pe role. Primul asset animat construit de
noi (vaca e importata gata skinnuita): 7 oase — Body, Head, Tail si cele patru
lopeti — puse pe insulele Builder-ului (fiecare piesa e o insula, vezi
`mesh_islands`), cu greutatea care curge la radacina (`weight_ramp`), ca lopata
sa se INDOAIE de sub carapace, nu sa se franga la o muchie.

  Walk (1 s): tarasul de testoasa de mare pe uscat, cu lopetile din fata
        SINCRON (broasca verde: intinde amandoua inainte, le infige si se trage
        pe ele, corpul se ridica pe stroke si cade la loc), cele din spate in
        contratimp, capul da din cap cu efortul, coada bate usor. Miscarea pe
        drum NU e in animatie — PathMover/SlidingHazard misca nodul; ciclul e
        gandit pentru ~4 m/s (viteza implicita de PathMover), la 1.0 speed.
  Idle (2 s): respiratie — capul se uita in jur, lopetile din fata abia se
        ridica, coada se misca. PathMover o alege singur la speed 0.

Rotatiile se scriu in spatiul armaturii ("ridica varful", "du-l inainte"),
nu pe axele locale ale osului — asa nu conteaza roll-ul si simetria stanga-
dreapta e un semn, nu doua rig-uri.
"""

import math
from mathutils import Vector, Matrix

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

# ---------------------------------------------------------------------------
# Scheletul. Cotele de mai jos sunt in sistemul in care e CONSTRUITA testoasa
# (cel al functiilor de sus); `finish` muta geometria (origine la baza, centrat
# XY), asa ca toate trec prin `P()`, care adauga deplasarea masurata.
# ---------------------------------------------------------------------------

def _bbox(obj):
    return island_bbox(obj, range(len(obj.data.vertices)))


def rig(obj, shift):
    """Oasele + greutatile. Fiecare piesa se recunoaste dupa insula ei
    (bbox-ul insulei in coordonate CONSTRUITE, adica dupa ce scadem `shift`):
      |cx| > 0.75            -> lopata (fata/spate dupa semnul lui cy, stanga/
                                dreapta dupa semnul lui cx)
      cy > 0.9               -> gat, cap, cioc, ochi
      cy < -1.0 si ingusta   -> coada
      restul                 -> corp (carapace, plastron, creasta)
    """
    def P(x, y, z):
        return Vector((x, y, z)) + shift

    bones = [
        dict(name="Body", head=P(0.0, -0.5, 0.30), tail=P(0.0, 0.5, 0.30)),
        dict(name="Head", head=P(0.0, 1.05, 0.50), tail=P(0.0, 2.0, 0.45),
             parent="Body"),
        dict(name="Tail", head=P(0.0, -1.30, 0.38), tail=P(0.0, -1.76, 0.24),
             parent="Body"),
    ]
    for sx, side in ((-1.0, "L"), (1.0, "R")):
        # Capul osului sta la RADACINA lopetii (sub carapace); varful, la
        # varful lamelei — asa rotatia se face de unde iese lopata, ca la o
        # articulatie de umar.
        bones.append(dict(name="FlipperF" + side, parent="Body",
                          head=P(sx * 0.62, 0.76, 0.40),
                          tail=P(sx * 1.75, 0.24, 0.13)))
        bones.append(dict(name="FlipperR" + side, parent="Body",
                          head=P(sx * 0.60, -0.90, 0.36),
                          tail=P(sx * 1.20, -1.50, 0.12)))
    arm = make_armature("Sea_Turtle", bones, mesh=obj)

    def cx_abs(co):
        return abs(co.x - shift.x)

    def cy(co):
        return co.y - shift.y

    def neg_cy(co):
        return -(co.y - shift.y)

    counts = {}
    for island in mesh_islands(obj):
        lo, hi = island_bbox(obj, island)
        c = (lo + hi) * 0.5 - shift
        size = hi - lo
        if abs(c.x) > 0.75:
            name = "Flipper" + ("F" if c.y > 0 else "R") + ("L" if c.x < 0 else "R")
            # Rampa pe |x|: pana la marginea carapacei greutatea e a corpului
            # (partea aia e ascunsa), dincolo de ea lopata urmeaza osul.
            lo_x, hi_x = (0.80, 1.20) if c.y > 0 else (0.65, 1.00)
            weight_ramp(obj, island, name, "Body", cx_abs, lo_x, hi_x)
        elif c.y > 0.9:
            name = "Head"
            weight_ramp(obj, island, name, "Body", cy, 1.10, 1.40)
        elif c.y < -1.0 and size.x < 0.5:
            name = "Tail"
            weight_ramp(obj, island, name, "Body", neg_cy, 1.45, 1.65)
        else:
            name = "Body"
            weight_ramp(obj, island, "Body", "Body", None, 0.0, 1.0)
        counts[name] = counts.get(name, 0) + 1
    expect = {"Body", "Head", "Tail", "FlipperFL", "FlipperFR", "FlipperRL",
              "FlipperRR"}
    assert set(counts) == expect, "piese nerecunoscute/lipsa: %r" % counts
    print("  insule pe oase:", counts)
    return arm


# Rotatii in spatiul armaturii, in grade. `forward` = varful lopetii spre bot
# (semnul se intoarce pentru partea stanga, ca aceeasi cifra sa insemne
# acelasi gest pe ambele parti); `up` = varful ridicat de la sol.
Z_AXIS = Vector((0.0, 0.0, 1.0))


def _flipper_rot(pb, forward, up, side):
    d = (pb.bone.tail_local - pb.bone.head_local)
    d.z = 0.0
    d.normalize()
    pitch = Matrix.Rotation(math.radians(up), 3, d.cross(Z_AXIS))
    yaw = Matrix.Rotation(math.radians(forward * side), 3, Z_AXIS)
    return yaw @ pitch


def _axis_rot(x=0.0, y=0.0, z=0.0):
    return (Matrix.Rotation(math.radians(z), 3, "Z")
            @ Matrix.Rotation(math.radians(y), 3, "Y")
            @ Matrix.Rotation(math.radians(x), 3, "X"))


def _key_pose(arm, frame, pose):
    """`pose`: dict os -> ("rot", Matrix) / ("move", Vector) / lista din ele."""
    for name, ops in pose.items():
        pb = arm.pose.bones[name]
        if not isinstance(ops, list):
            ops = [ops]
        for kind, val in ops:
            if kind == "rot":
                pose_rotate(pb, val)
                pb.keyframe_insert("rotation_quaternion", frame=frame)
            else:
                pose_move(pb, val)
                pb.keyframe_insert("location", frame=frame)


def _flippers(arm, front, rear):
    """(forward, up) pentru fata si spate — pe amandoua partile, sincron."""
    out = {}
    for sx, side in ((-1.0, "L"), (1.0, "R")):
        pbf = arm.pose.bones["FlipperF" + side]
        pbr = arm.pose.bones["FlipperR" + side]
        out["FlipperF" + side] = ("rot", _flipper_rot(pbf, front[0], front[1], sx))
        out["FlipperR" + side] = ("rot", _flipper_rot(pbr, rear[0], rear[1], sx))
    return out


def _body(lift, pitch):
    return [("move", Vector((0.0, 0.0, lift))), ("rot", _axis_rot(x=pitch))]


def _key_cycle(arm, phases):
    for frame, front, rear, body, head_r, tail_yaw in phases:
        pose = _flippers(arm, front, rear)
        pose["Body"] = _body(*body)
        pose["Head"] = ("rot", _axis_rot(x=head_r[0], z=head_r[1]))
        pose["Tail"] = ("rot", _axis_rot(z=tail_yaw))
        _key_pose(arm, frame, pose)


def animate(arm):
    """Cele doua actiuni. Cadrele-cheie inchid ciclul (ultimul = primul), ca
    bucla LOOP_LINEAR din Godot sa nu sara."""
    scene = bpy.context.scene
    scene.render.fps = 24
    if arm.animation_data is None:
        arm.animation_data_create()

    # WALK — 24 de cadre = 1 s. Patru faze: intins inainte / infipt / tras
    # inapoi (stroke) / ridicat pentru recuperare.
    walk = bpy.data.actions.new("Walk")
    arm.animation_data.action = walk
    #   cadru  fata(inainte,sus)  spate(inainte,sus)  corp(ridic,tangaj)  cap(tangaj,yaw)  coada
    phases = [
        (1,  (28.0, 18.0), (-12.0, -4.0), (0.00, -1.0), (-4.0, 0.0), 0.0),
        (7,  (20.0, -6.0), (-2.0, 12.0), (0.02, 0.5), (-1.0, 3.0), 8.0),
        (13, (-22.0, -4.0), (14.0, 8.0), (0.07, 2.5), (6.0, 0.0), 0.0),
        (19, (-8.0, 22.0), (6.0, -6.0), (0.03, 0.5), (1.0, -3.0), -8.0),
    ]
    phases.append((25,) + phases[0][1:])
    _key_cycle(arm, phases)

    # IDLE — 48 de cadre = 2 s. Aproape nemiscata: capul se uita in jur.
    idle = bpy.data.actions.new("Idle")
    arm.animation_data.action = idle
    phases = [
        (1,  (0.0, 0.0), (0.0, 0.0), (0.00, 0.0), (-3.0, 5.0), 0.0),
        (13, (2.0, 4.0), (0.0, 1.0), (0.01, 0.3), (1.0, 0.0), 4.0),
        (25, (0.0, 1.0), (0.0, 0.0), (0.00, 0.0), (4.0, -5.0), 0.0),
        (37, (2.0, 3.0), (0.0, 1.0), (0.01, 0.3), (0.0, 0.0), -4.0),
    ]
    phases.append((49,) + phases[0][1:])
    _key_cycle(arm, phases)

    stash_actions(arm, ("Walk", "Idle"))
    # Poza de repaus in fisier: fara actiune activa, oasele la zero.
    for pb in arm.pose.bones:
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)


clear_built("Sea_Turtle")
b = Builder()
shell(b)
keel(b)
head(b)
flippers(b)
tail(b)
obj = b.to_object("Sea_Turtle_Mesh")
lo0, hi0 = _bbox(obj)
stats = finish(obj, bevel=0.035, origin="base", ao=AO_SPEC)
lo1, hi1 = _bbox(obj)
# Cat a mutat `finish` geometria (bevel-ul schimba bbox-ul cu < 1 cm — sub
# orice prag de greutate de mai sus).
shift = Vector((((lo1 + hi1) - (lo0 + hi0)).x * 0.5,
                ((lo1 + hi1) - (lo0 + hi0)).y * 0.5,
                lo1.z - lo0.z))
print("  deplasarea din finish: %.3f %.3f %.3f" % tuple(shift))
arm = rig(obj, shift)
animate(arm)

bpy.context.view_layer.update()
d = obj.dimensions
print("sea_turtle.glb  %d tris  AO %.2f..%.2f"
      % (stats["tris"], stats["ao_min"], stats["ao_max"]))
print("  %.2f m lungime (Z in Godot), %.2f m latime, %.2f m inaltime"
      % (d.y, d.x, d.z))
print("GLB:  %s (%d B)" % export_glb([arm, obj], "props/sea_turtle.glb",
                                       animations=True))
print("BLEND: %s (%d B)" % save_blend([arm, obj], "sea_turtle.blend",
                                        compress=True))
