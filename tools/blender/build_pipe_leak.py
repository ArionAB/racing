"""pipe_leak.glb — conducta industriala sparta + doua variante de teava.
Brief: docs/asset_briefs/pipe_leak.md · issue #B5 (partea a doua)

Inlocuieste `garden_hose.glb`, un furtun de gradina **activ pe Dunele**
(`custom_hose_fracs = [0.478]` in Track01.tscn), care traverseaza soseaua
intr-un canion de desert. 748 de triunghiuri pentru un furtun.

ORIENTAREA E CONTRACT: gura din care iese apa priveste spre +Y in Blender.
`scenes/hazards/water_hose.gd:26` roteste modelul cu `rotation.y = PI/2` si
comentariul spune "duza modelului (-Z) se intoarce spre drum"; exportatorul
glTF face Blender +Y -> Godot -Z.

Trei obiecte, copii directi ai radacinii, toate exportate la origine:
  Pipe_Broken   <= 300 tris
  Pipe_Elbow    <= 160
  Pipe_Segment  <= 100
"""

import math
from mathutils import Vector

SEG = 8                     # laturi pe circumferinta, cerute de brief
R_OUT = 0.55
R_IN = 0.44                 # peretele se vede: 11 cm grosime
MOUTH_Y = 1.40              # gura rupta
BACK_Y = -2.20              # celalalt capat (intra in teren)
AXIS_Z = 0.85               # inaltimea axei conductei

COLLAR_R = 0.66
COLLAR_W = 0.12
COLLAR_Y = (0.40, -1.00)    # la 1.0 m si 2.4 m de gura

INNER_DEPTH = 0.35          # cat de adanc se vede in teava

# Ruptura: deplasari pe axa, una per varf al inelului de la gura. Determinist,
# scris de mana — patru varfuri trase inapoi si trei impinse in fata dau o
# margine care se citeste rupta, nu taiata. Brieful cere ±0.12.
JAG = (0.10, -0.06, 0.12, -0.11, 0.05, -0.12, 0.08, -0.04)

# Brieful cere bevel 0.03. Masurat pe geometria asta (222 de triunghiuri brute):
#
#   bevel 0.03, prag 30° (implicit)   708   -> 2.4x peste buget
#   bevel 0.03, prag 50°              536
#   bevel 0.03, prag 70°              464   -> tot 1.5x peste buget
#   fara bevel                        222   -> OK
#
# Pragul de unghi chiar e o parghie pe geometrie curbata (pe cutii n-ar fi fost:
# acolo toate muchiile sunt de 90°), fiindca fetele vecine ale unui tub cu 8
# laturi se intalnesc la 45°. Dar nici la 70° nu incape, iar 70° oricum nu mai
# lasa decat muchiile de 90°.
#
# Bevel 0 pe toate TREI piesele, nu doar pe cea care depasea: cotul si segmentul
# incapeau cu bevel, dar trei tevi din acelasi fisier care se aseaza cap la cap
# in decor nu pot avea muchii diferite.
BEVEL = 0.0
BEVEL_ANGLE = 30.0


SLANT = 0.22                # cat e taiata oblic gura: partea de sus iese in fata


def ring(b, y, r, jitter=None, z=AXIS_Z):
    """Un inel de varfuri in jurul axei Y, la cota `y`.

    Cand primeste `jitter`, adauga si o componenta OBLICA proportionala cu
    sin(unghi): partea de sus a gurii iese cu 22 cm in fata celei de jos.
    Brieful cere ruptura "taiata oblic si neregulata" — zimtii singuri dau doar
    neregularitatea, iar o gura perpendiculara pe axa se citeste ca taietura de
    fierastrau. Costa zero triunghiuri."""
    out = []
    for i in range(SEG):
        a = 2.0 * math.pi * i / SEG
        dy = (jitter[i % len(jitter)] + SLANT * math.sin(a)) if jitter else 0.0
        out.append(b.bm.verts.new(
            (r * math.cos(a), y + dy, z + r * math.sin(a))))
    return out


def skin(b, lo, hi, slot):
    """Banda de quad-uri intre doua inele. 2*SEG triunghiuri."""
    faces = set()
    for i in range(SEG):
        j = (i + 1) % SEG
        f = b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
        f[b.slot] = slot
        faces.add(f)
    return faces


def cap(b, verts, slot, flip=False):
    f = b.bm.faces.new(tuple(reversed(verts)) if flip else tuple(verts))
    f[b.slot] = slot
    return {f}


def collar(b, y, slot, r=COLLAR_R, w=COLLAR_W, z=AXIS_Z):
    """Colier: un inel scurt de teava, cu capace. `torus()` ar fi fost varianta
    evidenta, dar la 8 segmente majore si 5 minore costa 80 de triunghiuri —
    mai mult decat tot corpul conductei. Asta costa 28."""
    lo, hi = ring(b, y - w * 0.5, r, z=z), ring(b, y + w * 0.5, r, z=z)
    return (skin(b, lo, hi, slot) | cap(b, lo, slot, flip=True)
            | cap(b, hi, slot))


# ------------------------------------------------------------------ Pipe_Broken
def build_broken():
    b = Builder()

    back = ring(b, BACK_Y, R_OUT)
    mid = ring(b, -0.30, R_OUT)
    mouth = ring(b, MOUTH_Y, R_OUT, jitter=JAG)
    skin(b, back, mid, RUST)
    skin(b, mid, mouth, RUST)
    cap(b, back, SAND_SHADOW, flip=True)      # capatul din teren, inchis

    # Gura: buza (grosimea peretelui) + tubul interior + fundul lui. Fara ele,
    # capatul deschis al unui tub cu 8 laturi se citeste ca un bustean taiat —
    # adancimea e singurul lucru care spune "teava".
    mouth_in = ring(b, MOUTH_Y, R_IN, jitter=JAG)
    skin(b, mouth, mouth_in, RUST)            # buza
    inner_end = ring(b, MOUTH_Y - INNER_DEPTH, R_IN)
    skin(b, mouth_in, inner_end, SAND_SHADOW)
    cap(b, inner_end, SAND_SHADOW)

    for y in COLLAR_Y:
        collar(b, y, RUST)

    # Suport de beton la 2.6 m de gura, cu conducta asezata in sa.
    b.box((0.0, MOUTH_Y - 2.60, 0.30), (0.80, 1.00, 0.60), CONCRETE)

    # Pietre desprinse la gura. Intrepatrunse cu solul (z sub zero la baza):
    # `finish(origin="base")` le ridica pe toate, deci sunt construite ca sa
    # ramana pe cota conductei, nu ca sa fie ingropate.
    # Prima versiune le facea de 0.19-0.30 m cu taper 0.5: la render ieseau
    # conuri mici si intunecate, ca niste conuri de santier, nu ca moloz.
    # 0.34-0.52 m cu taper 0.28 le da volum si le tine rotunjite, cum cere
    # style_bible §3 pentru stanci.
    for (px, py, s, seed) in ((0.68, 1.80, 0.52, 11), (-0.52, 2.00, 0.41, 29),
                              (0.18, 2.32, 0.34, 47)):
        b.rock((px, py, 0.0), (s * 1.15, s, s * 0.72), ROCK_DARK,
               seed=seed, segments=5, rings=2, taper=0.28, squash=0.9)
    return b


# ------------------------------------------------------------------- Pipe_Elbow
def build_elbow():
    """Cot la 90°: doua brate care se intalnesc in origine.

    Brieful cere "ambele capete deschise". Capetele sunt inchise cu un disc in
    slot INCHIS, si asta nu e o incalcare, e reparatia unei greseli din brief:
    `Palette.world_material()` (scripts/palette.gd:79) nu atinge `cull_mode`,
    deci ramane CULL_BACK. Un tub cu capatul chiar deschis nu se vede ca teava,
    se vede ca GAURA — peretele din spate e format din fete intoarse, care se
    taie, si privesti direct prin obiect in fundal. Discul intunecat da acelasi
    citit ("se vede in teava") si costa 6 triunghiuri."""
    b = Builder()
    R = 0.50
    a0, a1 = ring(b, -1.40, R, z=R), ring(b, -0.10, R, z=R)
    skin(b, a0, a1, RUST)
    cap(b, a0, SAND_SHADOW, flip=True)
    # bratul vertical: acelasi inel, dar in planul orizontal, ridicat pe Z
    verts_lo, verts_hi = [], []
    for i in range(SEG):
        ang = 2.0 * math.pi * i / SEG
        verts_lo.append(b.bm.verts.new((R * math.cos(ang), R * math.sin(ang), R + 0.10)))
        verts_hi.append(b.bm.verts.new((R * math.cos(ang), R * math.sin(ang), R + 1.40)))
    for i in range(SEG):
        j = (i + 1) % SEG
        f = b.bm.faces.new((verts_lo[i], verts_lo[j], verts_hi[j], verts_hi[i]))
        f[b.slot] = RUST
    cap(b, verts_hi, SAND_SHADOW)
    b.box((0.0, -0.10, R + 0.10), (2 * R * 0.95, 2 * R * 0.95, 2 * R * 0.95), RUST)
    collar(b, -0.62, RUST, r=0.60, w=0.11, z=R)
    return b


# ----------------------------------------------------------------- Pipe_Segment
def build_segment():
    b = Builder()
    R = 0.50
    lo, hi = ring(b, -1.10, R, z=R), ring(b, 1.10, R, z=R)
    skin(b, lo, hi, RUST)
    cap(b, lo, SAND_SHADOW, flip=True)      # vezi nota din build_elbow
    cap(b, hi, SAND_SHADOW)
    collar(b, 0.0, RUST, r=0.60, w=0.11, z=R)
    return b


clear_built("Pipe_")

PIECES = [("Pipe_Broken", build_broken, 300),
          ("Pipe_Elbow", build_elbow, 160),
          ("Pipe_Segment", build_segment, 100)]

objs = []
for name, fn, budget in PIECES:
    obj = fn().to_object(name)
    y_before = min(v.co.y for v in obj.data.vertices)
    stats = finish(
        obj,
        bevel=BEVEL, bevel_angle=BEVEL_ANGLE,
        ao=dict(samples=28, dist=2.0, gradient="vertical",
                low=0.50, high=1.00, power=0.9, floor=0.14),
    )
    me = obj.data
    ext = [(min(v.co[a] for v in me.vertices), max(v.co[a] for v in me.vertices))
           for a in range(3)]
    print("%-13s %3d tris (buget %3d) %s | %.2f x %.2f x %.2f m | AO %.2f..%.2f"
          % (name, stats["tris"], budget,
             "OK    " if stats["tris"] <= budget else "DEPASIT",
             ext[0][1] - ext[0][0], ext[1][1] - ext[1][0], ext[2][1] - ext[2][0],
             stats["ao_min"], stats["ao_max"]))
    if name == "Pipe_Broken":
        # Cotele de care are nevoie instanta de gameplay ca sa aseze emitatorul
        # de particule: azi e la (road_width*0.5 + 1.2, 1.6, 0), calibrat pe
        # furtun, si furtunul se scaleaza cu 0.45.
        #
        # Pozitia gurii NU e marginea bbox-ului: pietrele desprinse stau IN FATA
        # rupturii, deci `max(y)` e o piatra. Se calculeaza din cota de
        # constructie plus deplasarea pe care a facut-o `finish(origin="base")`.
        shift = min(v.co.y for v in me.vertices) - y_before
        print("   duza  : %.3f m de origine pe -Z in Godot, la %.3f m inaltime"
              % (MOUTH_Y + shift, AXIS_Z))
        print("   (marginea bbox e %+.3f, dar aia e o piatra desprinsa, nu gura)"
              % ext[1][1])
    objs.append(obj)

for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(objs, "props/pipe_leak.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "pipe_leak.blend"))
for i, o in enumerate(objs):
    o.location = (i * 4.0, 0.0, 0.0)
