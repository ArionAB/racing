"""Baikal — figurantii animati: cainele husky si nerpa (planşa, poz. 11 si 12).

  husky_dog.glb (props/)   Husky_Dog (armatura, 9 oase) + Husky_Dog_Mesh
                           actiuni: Idle (2 s), Walk (1 s), Run (0.6 s)
  nerpa_seal.glb (props/)  Nerpa_Seal (armatura, 4 oase) + Nerpa_Seal_Mesh
                           actiuni: Idle (2.5 s), Dive (1 s)

Amandoi sunt FIGURANTI pe `PathMover` / trigger de proximitate, deci numele
actiunilor sunt CONTRACT cu Godot (la fel ca la vaca si testoasa): PathMover
cauta "Walk" / "Idle". Nerpa are in plus "Dive", pe care pista o declanseaza
cand masina se apropie de copca (brief §3).

Rig-ul e facut in cod, ca la testoasa: mesh-ul se construieste din insule
separate (`mesh_islands`), fiecare insula se leaga de osul ei cu greutatea care
curge spre radacina (`weight_ramp`). Fara rampa, articulatia se rupe vizibil.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_baikal_animals.py
"""

import math
from mathutils import Matrix, Vector

AO_ANIMAL = dict(samples=20, dist=2.0, gradient="vertical",
                 low=0.52, high=1.00, power=0.85, floor=0.22)


def _euler_matrix(rx, ry, rz):
    """Matrice 3x3 din unghiuri in GRADE, in spatiul armaturii.

    `pose_rotate` cere o Matrix 3x3 (rotatie in jurul capului osului, cu axele
    lumii), nu un triplet de unghiuri — de aici conversia. Ordinea XYZ e
    arbitrara dar consecventa: pozele astea sunt mici (sub 40 grade), deci
    ordinea nu produce diferente vizibile.
    """
    return (Matrix.Rotation(math.radians(rz), 3, "Z")
            @ Matrix.Rotation(math.radians(ry), 3, "Y")
            @ Matrix.Rotation(math.radians(rx), 3, "X"))


def _key_pose(arm, frame, pose):
    """Scrie o poza: dict(nume_os -> ((rx, ry, rz) grade, (dx, dy, dz)))."""
    for bone_name, spec in pose.items():
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            continue
        rot, loc = spec
        pose_rotate(pb, _euler_matrix(*rot))
        if loc != (0.0, 0.0, 0.0):
            pose_move(pb, loc)
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        pb.keyframe_insert("location", frame=frame)


def _clear_animals(prefix):
    """Sterge mesh-urile, ARMATURILE si ACTIUNILE lasate de o rulare anterioara.

    `clear_built` sterge doar mesh-uri. Actiunile si armaturile sunt datablock-uri
    GLOBALE in Blender, deci supravietuiesc: la a doua constructie din aceeasi
    sesiune, "Idle" exista deja si noua actiune devine "Idle.001", iar
    `stash_actions` pune in NLA ce gaseste. Consecinta masurata pe nerpa —
    GLB-ul ei plecase cu cinci actiuni, dintre care `Walk` si `Run` erau ale
    CAINELUI. Godot ar fi gasit un `Walk` valid pe o foca.
    """
    clear_built(prefix)
    for arm in list(bpy.data.objects):
        if arm.type == "ARMATURE" and arm.name.startswith(prefix):
            bpy.data.objects.remove(arm, do_unlink=True)
    for ad in list(bpy.data.armatures):
        if ad.users == 0:
            bpy.data.armatures.remove(ad)
    # Actiunile NU se filtreaza pe prefix: numele lor sunt Idle/Walk/Run, comune
    # tuturor animalelor. Se sterg toate cele orfane plus cele cu nume de ciclu.
    for act in list(bpy.data.actions):
        if act.users == 0 or act.name.split(".")[0] in ("Idle", "Walk", "Run",
                                                        "Dive"):
            bpy.data.actions.remove(act)


def _cycle(arm, action_name, frames):
    """O actiune ciclica. `frames` = [(cadru, {os: (rot, loc)}), ...].

    Ultimul cadru repeta primul, ca bucla LOOP_LINEAR din Godot sa nu sara —
    aceeasi regula ca la testoasa.
    """
    act = bpy.data.actions.new(action_name)
    arm.animation_data.action = act
    for frame, pose in frames:
        # reset inainte de fiecare cadru: pose_rotate compune, nu seteaza
        for pb in arm.pose.bones:
            pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
            pb.location = (0.0, 0.0, 0.0)
        _key_pose(arm, frame, pose)
    return act


# ============================================================ Husky
# 0.6 m la greaban. Alb-gri, cu masca faciala mai inchisa, coada stufoasa
# incolacita — semnatura rasei. Botul spre -Y in Godot => +Y in Blender.

def build_husky():
    _clear_animals("Husky")
    b = Builder()

    SH = 0.60                    # inaltime la greaban
    body_z = SH * 0.72

    # corpul: doua volume (piept mai inalt, crupa mai joasa) — un singur
    # cilindru ar da un butoi pe picioare
    b.box((0.0, 0.10, body_z + 0.02), (0.24, 0.42, 0.26), FOAM_WHITE)
    b.box((0.0, -0.24, body_z - 0.01), (0.22, 0.34, 0.24), FOAM_WHITE)
    # spinarea gri (husky au mantie inchisa pe spate si flancuri albe)
    b.box((0.0, -0.04, body_z + 0.13), (0.20, 0.70, 0.08), ASPHALT_EDGE)

    # gatul + capul
    b.box((0.0, 0.34, body_z + 0.10), (0.17, 0.16, 0.19), FOAM_WHITE)
    b.box((0.0, 0.46, body_z + 0.16), (0.16, 0.17, 0.16), FOAM_WHITE)
    # botul, mai ingust
    b.box((0.0, 0.58, body_z + 0.12), (0.09, 0.12, 0.09), FOAM_WHITE)
    # masca faciala inchisa — fara ea e un caine alb generic
    b.box((0.0, 0.47, body_z + 0.22), (0.165, 0.15, 0.055), ASPHALT_EDGE)
    # urechile triunghiulare, drepte (husky nu are urechi cazute)
    for sx in (-1, 1):
        b.prism([(0.0, 0.0), (0.055, 0.0), (0.028, 0.11)], 0.03,
                ASPHALT_EDGE, center=(sx * 0.055, 0.44, body_z + 0.24))
    # ochii
    for sx in (-1, 1):
        b.box((sx * 0.048, 0.535, body_z + 0.185), (0.022, 0.02, 0.022),
              VOLCANIC_BLACK)
    # nasul
    b.box((0.0, 0.638, body_z + 0.115), (0.045, 0.03, 0.035), VOLCANIC_BLACK)

    # patru picioare, fiecare din doua segmente (coapsa + fluier)
    for sx, side in ((-1, "L"), (1, "R")):
        for sy, which in ((1, "F"), (-1, "R")):
            hx = sx * 0.10
            hy = 0.26 if sy > 0 else -0.32
            b.box((hx, hy, body_z - 0.14), (0.075, 0.10, 0.16), FOAM_WHITE)
            b.box((hx, hy + (0.01 if sy > 0 else -0.01), body_z - 0.30),
                  (0.06, 0.07, 0.18), FOAM_WHITE)
            b.box((hx, hy + (0.02 if sy > 0 else -0.02), 0.025),
                  (0.07, 0.11, 0.05), ASPHALT_EDGE)     # laba

    # coada stufoasa, incolacita peste crupa — al doilea semn al rasei
    tail = [(0.0, -0.44, body_z + 0.02), (0.05, -0.54, body_z + 0.14),
            (0.02, -0.50, body_z + 0.26), (-0.04, -0.38, body_z + 0.28)]
    for i in range(len(tail) - 1):
        b.beam(tail[i], tail[i + 1], 0.075 - i * 0.008, FOAM_WHITE)

    obj = b.to_object("Husky_Dog_Mesh")
    finish(obj, bevel=0.012, ao=AO_ANIMAL, origin="base")

    # --- rig ----------------------------------------------------------------
    # Oase: corp (radacina), cap, coada, si cate unul pe picior. La 0.6 m,
    # segmentarea mai fina n-ar produce nicio diferenta vizibila din masina.
    bz = body_z
    bones = [dict(name="Body", head=(0.0, -0.30, bz), tail=(0.0, 0.30, bz))]
    bones.append(dict(name="Head", parent="Body",
                      head=(0.0, 0.32, bz + 0.08), tail=(0.0, 0.60, bz + 0.14)))
    bones.append(dict(name="Tail", parent="Body",
                      head=(0.0, -0.42, bz), tail=(-0.04, -0.40, bz + 0.28)))
    for sx, side in ((-1, "L"), (1, "R")):
        for sy, which in ((1, "F"), (-1, "R")):
            hy = 0.26 if sy > 0 else -0.32
            bones.append(dict(name="Leg%s%s" % (which, side), parent="Body",
                              head=(sx * 0.10, hy, bz - 0.06),
                              tail=(sx * 0.10, hy, 0.02)))
    arm = make_armature("Husky_Dog", bones, mesh=obj)

    # greutati pe insule: fiecare bucata merge la osul cel mai apropiat
    counts = {}
    for island in mesh_islands(obj):
        lo, hi = island_bbox(obj, island)
        c = (lo + hi) * 0.5
        if c.y > 0.30 and c.z > bz - 0.05:
            name, ramp, a, bnd = "Head", (lambda co: co.y), 0.30, 0.40
        elif c.y < -0.40:
            name, ramp, a, bnd = "Tail", (lambda co: -co.y), 0.40, 0.50
        elif c.z < bz - 0.08:
            which = "F" if c.y > 0 else "R"
            side = "L" if c.x < 0 else "R"
            name = "Leg%s%s" % (which, side)
            ramp, a, bnd = (lambda co: bz - co.z), 0.04, 0.14
        else:
            name, ramp, a, bnd = "Body", None, 0.0, 1.0
        weight_ramp(obj, island, name, "Body", ramp, a, bnd)
        counts[name] = counts.get(name, 0) + 1
    print("  husky, insule pe oase:", counts)

    # --- actiuni ------------------------------------------------------------
    scene = bpy.context.scene
    scene.render.fps = 24
    if arm.animation_data is None:
        arm.animation_data_create()

    def legs(fl, fr, rl, rr):
        return {"LegFL": ((fl, 0, 0), (0, 0, 0)),
                "LegFR": ((fr, 0, 0), (0, 0, 0)),
                "LegRL": ((rl, 0, 0), (0, 0, 0)),
                "LegRR": ((rr, 0, 0), (0, 0, 0))}

    # IDLE (2 s): stand, capul se uita in jur, coada se misca lene.
    _cycle(arm, "Idle", [
        (1, dict(legs(0, 0, 0, 0), Head=((0, 0, -8), (0, 0, 0)),
                 Tail=((-4, 0, 0), (0, 0, 0)))),
        (13, dict(legs(0, 0, 0, 0), Head=((3, 0, 2), (0, 0, 0)),
                  Tail=((2, 0, 10), (0, 0, 0)))),
        (25, dict(legs(0, 0, 0, 0), Head=((0, 0, 9), (0, 0, 0)),
                  Tail=((-3, 0, 0), (0, 0, 0)))),
        (37, dict(legs(0, 0, 0, 0), Head=((2, 0, 1), (0, 0, 0)),
                  Tail=((2, 0, -10), (0, 0, 0)))),
        (49, dict(legs(0, 0, 0, 0), Head=((0, 0, -8), (0, 0, 0)),
                  Tail=((-4, 0, 0), (0, 0, 0)))),
    ])

    # WALK (1 s): mers in diagonala (trap) — piciorul stang fata cu dreptul
    # spate. Asa merg patrupedele; miscarea in "pereche pe aceeasi parte" ar
    # arata ca o jucarie stricata.
    _cycle(arm, "Walk", [
        (1, dict(legs(22, -18, -18, 22), Body=((1.5, 0, 0), (0, 0, 0)),
                 Head=((-2, 0, 0), (0, 0, 0)), Tail=((6, 0, 0), (0, 0, 0)))),
        (7, dict(legs(0, 0, 0, 0), Body=((0, 0, 0), (0, 0, 0.012)),
                 Head=((0, 0, 0), (0, 0, 0)), Tail=((0, 0, 8), (0, 0, 0)))),
        (13, dict(legs(-18, 22, 22, -18), Body=((-1.5, 0, 0), (0, 0, 0)),
                  Head=((2, 0, 0), (0, 0, 0)), Tail=((6, 0, 0), (0, 0, 0)))),
        (19, dict(legs(0, 0, 0, 0), Body=((0, 0, 0), (0, 0, 0.012)),
                  Head=((0, 0, 0), (0, 0, 0)), Tail=((0, 0, -8), (0, 0, 0)))),
        (25, dict(legs(22, -18, -18, 22), Body=((1.5, 0, 0), (0, 0, 0)),
                  Head=((-2, 0, 0), (0, 0, 0)), Tail=((6, 0, 0), (0, 0, 0)))),
    ])

    # RUN (0.6 s = 14 cadre): galop — perechile fata/spate lucreaza impreuna,
    # spinarea se arcuieste. Husky-ul e caine de sanie; alergarea e postura in
    # care se recunoaste cel mai bine.
    _cycle(arm, "Run", [
        (1, dict(legs(-34, -30, 30, 34), Body=((-6, 0, 0), (0, 0, 0.02)),
                 Head=((-6, 0, 0), (0, 0, 0)), Tail=((16, 0, 0), (0, 0, 0)))),
        (5, dict(legs(28, 32, -26, -22), Body=((7, 0, 0), (0, 0, 0.05)),
                 Head=((4, 0, 0), (0, 0, 0)), Tail=((10, 0, 0), (0, 0, 0)))),
        (9, dict(legs(34, 30, -30, -34), Body=((2, 0, 0), (0, 0, 0.01)),
                 Head=((2, 0, 0), (0, 0, 0)), Tail=((14, 0, 0), (0, 0, 0)))),
        (15, dict(legs(-34, -30, 30, 34), Body=((-6, 0, 0), (0, 0, 0.02)),
                  Head=((-6, 0, 0), (0, 0, 0)), Tail=((16, 0, 0), (0, 0, 0)))),
    ])

    stash_actions(arm, ("Idle", "Walk", "Run"))
    for pb in arm.pose.bones:
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)

    print("HuskyDog: %d tris" % tri_count(obj))
    export_glb([arm, obj], "props/husky_dog.glb", animations=True)
    save_blend([arm, obj], "baikal_husky_dog.blend", compress=True)
    return [arm, obj]


# ============================================================ Nerpa
# 1.3 m, foca de Baikal: corp rotund gri-argintiu, OCHI MARI (semnatura ei),
# fara urechi externe. Sta pe gheata langa copca si se scufunda cand vii.

def build_nerpa():
    _clear_animals("Nerpa")
    b = Builder()

    # Corpul: fusiform, mai gros la umeri. Nerpa e vestita ca fiind GRASA si
    # rotunda — daca iese zvelta, nu e nerpa, e o foca oarecare.
    body = [(0.62, 0.00), (0.55, 0.20), (0.30, 0.55), (0.10, 0.72)]
    for i, (r, _y) in enumerate(body):
        pass
    # o construim ca lant de frustum-uri pe axa Y (botul spre +Y)
    stations = [(-0.62, 0.07), (-0.40, 0.17), (-0.12, 0.21), (0.16, 0.20),
                (0.40, 0.155), (0.56, 0.105), (0.65, 0.055)]
    for i in range(len(stations) - 1):
        y0, r0 = stations[i]
        y1, r1 = stations[i + 1]
        b.frustum((0.0, (y0 + y1) * 0.5, 0.19), r0, r1, abs(y1 - y0),
                  ASPHALT_EDGE, segments=9, axis="Y")
    # Burta mai deschisa: separa silueta de gheata in contralumina. Ingusta
    # (0.17) si joasa — prima versiune avea 0.26 latime pe un corp de raza
    # maxima 0.21, deci coltii cutiei IESEAU prin flancuri si prin gheata, ca
    # doua aripioare albe. Se vedea in randarea de control.
    b.box((0.0, -0.02, 0.055), (0.17, 0.80, 0.07), FOAM_WHITE)

    # capul: bot scurt si rotund
    b.frustum((0.0, 0.70, 0.20), 0.085, 0.055, 0.10, ASPHALT_EDGE,
              segments=8, axis="Y")
    # OCHII MARI, negri — trasatura care o face recognoscibila si simpatica
    for sx in (-1, 1):
        b.cylinder((sx * 0.055, 0.635, 0.245), 0.036, 0.02, VOLCANIC_BLACK,
                   segments=8, axis="Y")
    # nasul + mustatile sugerate ca o pata mai inchisa
    b.box((0.0, 0.755, 0.205), (0.045, 0.03, 0.032), VOLCANIC_BLACK)

    # lopetile din fata, lipite de corp
    for sx in (-1, 1):
        b.box((sx * 0.175, 0.40, 0.09), (0.13, 0.22, 0.045), ASPHALT_EDGE,
              rotation=Matrix.Rotation(math.radians(sx * -26.0), 3, "Z"))
    # coada in V (doua lopeti unite)
    for sx in (-1, 1):
        b.box((sx * 0.09, -0.70, 0.11), (0.10, 0.20, 0.045), ASPHALT_EDGE,
              rotation=Matrix.Rotation(math.radians(sx * 22.0), 3, "Z"))

    obj = b.to_object("Nerpa_Seal_Mesh")
    finish(obj, bevel=0.012, ao=AO_ANIMAL, origin="base")

    # --- rig: 4 oase (corp, cap, doua lopeti) ------------------------------
    bones = [
        dict(name="Body", head=(0.0, -0.60, 0.19), tail=(0.0, 0.45, 0.19)),
        dict(name="Head", parent="Body", head=(0.0, 0.48, 0.20),
             tail=(0.0, 0.78, 0.21)),
        dict(name="FlipperL", parent="Body", head=(-0.09, 0.42, 0.11),
             tail=(-0.26, 0.34, 0.08)),
        dict(name="FlipperR", parent="Body", head=(0.09, 0.42, 0.11),
             tail=(0.26, 0.34, 0.08)),
    ]
    arm = make_armature("Nerpa_Seal", bones, mesh=obj)

    counts = {}
    for island in mesh_islands(obj):
        lo, hi = island_bbox(obj, island)
        c = (lo + hi) * 0.5
        if abs(c.x) > 0.12 and c.y > 0.25:
            name = "FlipperL" if c.x < 0 else "FlipperR"
            weight_ramp(obj, island, name, "Body", (lambda co: abs(co.x)),
                        0.12, 0.20)
        elif c.y > 0.55:
            weight_ramp(obj, island, "Head", "Body", (lambda co: co.y),
                        0.48, 0.62)
            name = "Head"
        else:
            weight_ramp(obj, island, "Body", "Body", None, 0.0, 1.0)
            name = "Body"
        counts[name] = counts.get(name, 0) + 1
    print("  nerpa, insule pe oase:", counts)

    scene = bpy.context.scene
    scene.render.fps = 24
    if arm.animation_data is None:
        arm.animation_data_create()

    # IDLE (2.5 s = 60 cadre): sta si se uita. Capul se roteste incet, corpul
    # respira. Asta e postura in care o vede jucatorul cel mai des.
    _cycle(arm, "Idle", [
        (1, dict(Head=((0, 0, -12), (0, 0, 0)), Body=((0, 0, 0), (0, 0, 0)),
                 FlipperL=((0, 0, 0), (0, 0, 0)),
                 FlipperR=((0, 0, 0), (0, 0, 0)))),
        (16, dict(Head=((4, 0, -2), (0, 0, 0)),
                  Body=((0, 0, 0), (0, 0, 0.006)),
                  FlipperL=((0, 0, 4), (0, 0, 0)),
                  FlipperR=((0, 0, -4), (0, 0, 0)))),
        (31, dict(Head=((-2, 0, 13), (0, 0, 0)), Body=((0, 0, 0), (0, 0, 0)),
                  FlipperL=((0, 0, 0), (0, 0, 0)),
                  FlipperR=((0, 0, 0), (0, 0, 0)))),
        (46, dict(Head=((3, 0, 2), (0, 0, 0)),
                  Body=((0, 0, 0), (0, 0, 0.006)),
                  FlipperL=((0, 0, -3), (0, 0, 0)),
                  FlipperR=((0, 0, 3), (0, 0, 0)))),
        (61, dict(Head=((0, 0, -12), (0, 0, 0)), Body=((0, 0, 0), (0, 0, 0)),
                  FlipperL=((0, 0, 0), (0, 0, 0)),
                  FlipperR=((0, 0, 0), (0, 0, 0)))),
    ])

    # DIVE (1 s): se ridica, se arcuieste si PLONJEAZA in copca — corpul
    # coboara sub nivelul gheții pe ultimele cadre. NU e ciclica (se joaca o
    # data, la trigger), dar ultimul cadru o lasa ascunsa sub gheata, ca pista
    # sa poata stinge nodul fara sa se vada disparitia.
    _cycle(arm, "Dive", [
        (1, dict(Head=((0, 0, 0), (0, 0, 0)), Body=((0, 0, 0), (0, 0, 0)),
                 FlipperL=((0, 0, 0), (0, 0, 0)),
                 FlipperR=((0, 0, 0), (0, 0, 0)))),
        (7, dict(Head=((-16, 0, 0), (0, 0, 0)),
                 Body=((-9, 0, 0), (0, 0, 0.05)),
                 FlipperL=((0, 0, 16), (0, 0, 0)),
                 FlipperR=((0, 0, -16), (0, 0, 0)))),
        (14, dict(Head=((28, 0, 0), (0, 0, 0)),
                  Body=((22, 0, 0), (0, 0, -0.10)),
                  FlipperL=((0, 0, -10), (0, 0, 0)),
                  FlipperR=((0, 0, 10), (0, 0, 0)))),
        (24, dict(Head=((40, 0, 0), (0, 0, 0)),
                  Body=((34, 0, 0), (0, 0, -0.75)),
                  FlipperL=((0, 0, -4), (0, 0, 0)),
                  FlipperR=((0, 0, 4), (0, 0, 0)))),
    ])

    stash_actions(arm, ("Idle", "Dive"))
    for pb in arm.pose.bones:
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)

    print("NerpaSeal: %d tris" % tri_count(obj))
    export_glb([arm, obj], "props/nerpa_seal.glb", animations=True)
    save_blend([arm, obj], "baikal_nerpa_seal.blend", compress=True)
    return [arm, obj]


if __name__ == "__main__":
    build_husky()
    build_nerpa()
