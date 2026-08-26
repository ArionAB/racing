"""Stromboli, kit de sat — magarul (brief village_kit, piesa 15).

  Donkey  stromboli/props/donkey.glb
          Donkey

1.4 m la greaban, STILIZAT si CHUNKY: proportii de jucarie (cap mare, picioare
groase), fara samar.

Brief-ul cere explicit "aceeasi familie cu husky-ul de sat din kitul Baikal",
si corectia din foaia de referinta e ca magarul de acolo a iesit prea realist.
Deci reteta e cea din `build_baikal_animals.build_husky`: cutii, doua volume de
corp (piept mai inalt, crupa mai joasa), picioare din doua segmente. Nimic
organic, nimic sculptat.

Ce face magarul sa fie magar si nu cal mic: **urechile lungi** (0.30 m, adica
un sfert din inaltimea la greaban), botul gri-deschis si crucea de pe spinare.

SCHELET SI ANIMATIE (aug 2026). Magarul sta pe un `PathMover` in Ginostra
(Track11, grupul "6)Ginostra"), adica se PLIMBA pe traseul desenat de mana —
si pana acum aluneca pe drum cu picioarele intepenite, ca o jucarie pe role.
Al treilea asset animat al proiectului si al doilea cu rig FACUT IN COD (dupa
testoasa, `build_sea_turtle.py`): 14 oase pe insulele Builder-ului.

  Walk (1 s): pasul de magar, mers in DOI TIMPI diagonali — fata-stanga cu
        spate-dreapta, apoi invers. E chiar mersul unui patruped la pas, si e
        singurul lucru care il deosebeste de o jucarie care isi flutura
        picioarele: perechile diagonale se misca impreuna. Capul da din el pe
        ritm (magarul isi balanseaza capul la fiecare pas), crupa se leagana
        usor, coada bate, urechile se clatina cu intarziere fata de cap.
        Ciclul e gandit pentru ~1.2 m/s — viteza unui magar la pas.
  Idle (3 s): pasunatul. Capul COBOARA la iarba si se ridica, urechile se
        rotesc pe rand (semnalul de magar in repaus), coada alunga mustele.
        PathMover il alege singur cand `speed` e 0.

Deplasarea pe drum NU e in animatie — PathMover misca nodul; root motion in
GLB s-ar bate cap in cap cu el (lectia din build_cow_animated.py). Consecinta:
viteza figurantului si lungimea pasului trebuie POTRIVITE de mana, altfel
copitele patineaza. Cifra se DERIVA, nu se alege din ochi:

    pas = 2 * L * sin(swing)     L = lungimea piciorului de la umar la copita
    avans pe ciclu = 2 * pas     (doua perechi diagonale intr-un ciclu)

Cu L = 0.78 m si swing = 16°, un ciclu de 1.04 s duce animalul 0.86 m, adica
0.83 m/s. In pista magarul e la `model_scale` 1.5, deci pasul creste odata cu
el: 1.29 m pe ciclu, adica **1.24 m/s**. De aia `donkeyPathMover` din
Track11.tscn are `speed = 1.2` (era 4.0, viteza implicita a lui PathMover —
un magar care ar fi acoperit 4.16 m pe ciclu cu pasi de 1.29 m, adica ar fi
alunecat de trei ori mai mult decat ar fi mers). 1.2 m/s e si viteza reala a
unui magar la pas, deci potrivirea nu costa nimic in credibilitate.

Rotatiile se scriu in spatiul armaturii ("ridica piciorul", "du-l inainte"),
nu pe axele locale ale osului — asa nu conteaza roll-ul, iar simetria
stanga-dreapta e un semn, nu doua rig-uri.

CULORILE, corectie din aceeasi trecere: botul, coama si crucea de pe spinare
stateau pe `ROCK_DARK` (slotul 4). E maroul de DESERT al canionului, si pe o
insula vulcanica iese rugina — greseala prinsa deja pe trei assets Stromboli
la rand (crater_bowl, strombolicchio, observatory_terrace; vezi memoria
"ROCK_DARK nu pe bazalt"). Semnele magarului trec pe `LOG_DARK` (28), maroul
inchis al lemnului de Baikal: e maro adevarat, nu ruginiu, si la 0.42
luminanta relativa fata de 0.63 a corpului da contrastul cerut de brief
("crucea se vede de la 25 m") fara sa schimbe familia de culoare a pistei.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_donkey.py
"""

import math
from mathutils import Matrix, Vector

AO_DONKEY = dict(samples=20, dist=1.6, gradient="vertical",
                 low=0.58, high=1.00, power=0.9, floor=0.34)

SH = 1.40                    # inaltime la greaban
BODY = MARBLE_GREY           # corp gri (brief: u = 0.921875 -> slot 29)
# Semnele magarului (bot, coama, cruce, interiorul urechii). NU ROCK_DARK —
# vezi antetul: pe Stromboli slotul ala citeste rugina.
MUZZLE = LOG_DARK
HOOF = VOLCANIC_BLACK

body_z = SH * 0.70

# Cotele picioarelor, o singura data: le folosesc si geometria, si scheletul.
# (semn X, Y-ul soldului/umarului, eticheta perechii)
LEGS = [(-1, 0.40, "FL"), (1, 0.40, "FR"), (-1, -0.52, "RL"), (1, -0.52, "RR")]
LEG_X = 0.17
UPPER_Z = body_z - 0.30      # centrul segmentului de sus
LOWER_Z = body_z - 0.62      # centrul segmentului de jos
HOOF_Z = body_z - 0.82


def build(b):
    """Geometria. Neschimbata fata de versiunea statica, in afara de sloturi:
    fiecare piesa ramane o insula separata, ceea ce e chiar cheia rig-ului."""
    # --- corp: doua volume, ca la husky ------------------------------------
    # Pieptul mai inalt si mai lat decat crupa: un singur volum ar da butoi.
    b.box((0.0, 0.22, body_z + 0.04), (0.46, 0.62, 0.50), BODY)
    b.box((0.0, -0.36, body_z - 0.02), (0.42, 0.56, 0.44), BODY)

    # crucea de pe spinare — semnul magarului. Costa doua cutii si e
    # singurul lucru care il deosebeste de un ponei gri.
    b.box((0.0, -0.02, body_z + 0.27), (0.09, 1.10, 0.05), MUZZLE)
    b.box((0.0, 0.26, body_z + 0.27), (0.40, 0.09, 0.05), MUZZLE)

    # --- gat + cap ----------------------------------------------------------
    # Gatul urca inclinat spre fata; capul e MARE (proportie de jucarie).
    b.box((0.0, 0.62, body_z + 0.34), (0.26, 0.30, 0.44), BODY,
          rotation=Matrix.Rotation(math.radians(-22.0), 3, "X"))
    b.box((0.0, 0.84, body_z + 0.52), (0.27, 0.38, 0.30), BODY)
    # botul, mai ingust si mai deschis
    b.box((0.0, 1.04, body_z + 0.42), (0.19, 0.22, 0.19), MUZZLE)
    # narile
    b.box((0.0, 1.15, body_z + 0.40), (0.15, 0.04, 0.10), HOOF)
    # ochii
    for sx in (-1, 1):
        b.box((sx * 0.115, 0.96, body_z + 0.60), (0.035, 0.035, 0.035), HOOF)

    # --- urechile: LUNGI, semnatura magarului -------------------------------
    for sx in (-1, 1):
        b.box((sx * 0.09, 0.80, body_z + 0.82), (0.09, 0.11, 0.30), BODY,
              rotation=Matrix.Rotation(math.radians(sx * 13.0), 3, "Y"))
        # interiorul urechii, mai inchis
        b.box((sx * 0.11, 0.79, body_z + 0.84), (0.045, 0.07, 0.22), MUZZLE,
              rotation=Matrix.Rotation(math.radians(sx * 13.0), 3, "Y"))

    # coama, intre urechi si greaban
    b.box((0.0, 0.70, body_z + 0.62), (0.09, 0.42, 0.13), MUZZLE,
          rotation=Matrix.Rotation(math.radians(-26.0), 3, "X"))

    # --- picioare: GROASE, doua segmente ------------------------------------
    for sx, hy, _tag in LEGS:
        fy = 1 if hy > 0 else -1
        b.box((sx * LEG_X, hy, UPPER_Z), (0.17, 0.21, 0.42), BODY)
        b.box((sx * LEG_X, hy + (0.02 * fy), LOWER_Z), (0.14, 0.16, 0.36), BODY)
        # copita
        b.box((sx * LEG_X, hy + (0.02 * fy), HOOF_Z), (0.15, 0.17, 0.09), HOOF)

    # --- coada --------------------------------------------------------------
    b.box((0.0, -0.66, body_z + 0.06), (0.07, 0.09, 0.34), BODY,
          rotation=Matrix.Rotation(math.radians(16.0), 3, "X"))
    b.box((0.0, -0.72, body_z - 0.20), (0.09, 0.10, 0.16), MUZZLE)


# ---------------------------------------------------------------------------
# Scheletul. Cotele de mai sus sunt in sistemul in care e CONSTRUIT magarul;
# `finish` muta geometria (origine la baza, centrat XY), asa ca toate trec prin
# `P()`, care adauga deplasarea masurata pe bbox inainte/dupa.
# ---------------------------------------------------------------------------

def rig(obj, shift):
    """Oasele + greutatile.

    14 oase: Body (radacina), Neck, Head, doua urechi, Tail, si cate doua
    segmente pe fiecare din cele patru picioare.

    Fiecare piesa a Builder-ului e o insula (`mesh_islands`), iar insula se
    recunoaste dupa bbox-ul ei in coordonate CONSTRUITE (dupa ce scadem
    `shift`). Ordinea testelor conteaza: picioarele se prind primele, fiindca
    testul lor e cel mai strans (|x| ~ 0.17 SI z sub corp), iar restul cade pe
    cap/gat/coada dupa Y.
    """
    def P(x, y, z):
        return Vector((x, y, z)) + shift

    bones = [
        # Radacina, de-a lungul corpului: crupa -> greaban.
        dict(name="Body", head=P(0.0, -0.45, body_z), tail=P(0.0, 0.40, body_z)),
        # Gatul urca inclinat; capul continua spre bot. Doua oase, nu unul:
        # la pasunat gatul se indoaie de la greaban, iar capul se orizontalizeaza
        # separat — cu un singur os magarul ar bage botul in pamant cu gatul drept.
        dict(name="Neck", parent="Body",
             head=P(0.0, 0.48, body_z + 0.22), tail=P(0.0, 0.74, body_z + 0.52)),
        dict(name="Head", parent="Neck",
             head=P(0.0, 0.74, body_z + 0.52), tail=P(0.0, 1.12, body_z + 0.40)),
        dict(name="Tail", parent="Body",
             head=P(0.0, -0.62, body_z + 0.16), tail=P(0.0, -0.74, body_z - 0.28)),
    ]
    for sx, side in ((-1.0, "L"), (1.0, "R")):
        # Urechea se roteste din baza ei, adica de pe crestet.
        bones.append(dict(name="Ear" + side, parent="Head",
                          head=P(sx * 0.09, 0.80, body_z + 0.68),
                          tail=P(sx * 0.13, 0.80, body_z + 0.97)))
    for sx, hy, tag in LEGS:
        # Osul de sus porneste din articulatia cu corpul (umar/sold) si
        # coboara pana la genunchi/jaret; cel de jos, de acolo pana in copita.
        bones.append(dict(name="Leg" + tag, parent="Body",
                          head=P(sx * LEG_X, hy, body_z - 0.09),
                          tail=P(sx * LEG_X, hy, body_z - 0.44)))
        bones.append(dict(name="Shin" + tag, parent="Leg" + tag,
                          head=P(sx * LEG_X, hy, body_z - 0.44),
                          tail=P(sx * LEG_X, hy, body_z - 0.87)))
    arm = make_armature("Donkey", bones, mesh=obj)

    def cz(co):
        return co.z - shift.z

    def neg_cz(co):
        return -(co.z - shift.z)

    def cy(co):
        return co.y - shift.y

    def neg_cy(co):
        return -(co.y - shift.y)

    counts = {}
    for island in mesh_islands(obj):
        lo, hi = island_bbox(obj, island)
        c = (lo + hi) * 0.5 - shift
        size = hi - lo
        name = None
        root = "Body"
        value, v_lo, v_hi = None, 0.0, 1.0
        if c.z < body_z - 0.12 and abs(abs(c.x) - LEG_X) < 0.10:
            # PICIOR. Perechea dupa semnele lui x/y; segmentul dupa z.
            tag = ("F" if c.y > 0 else "R") + ("L" if c.x < 0 else "R")
            if c.z > body_z - 0.46:
                # Coapsa: greutatea curge la corp spre umar, ca sa nu se rupa
                # muchia unde piciorul intra in trunchi.
                name, root = "Leg" + tag, "Body"
                value, v_lo, v_hi = neg_cz, -(body_z - 0.10), -(body_z - 0.34)
            else:
                # Fluierul si copita: intregi pe osul de jos. Copita e piesa
                # rigida prin definitie, iar fluierul se indoaie din genunchi.
                name, root = "Shin" + tag, "Shin" + tag
        elif c.z > body_z + 0.60 and c.y > 0.6 and size.z > 0.15:
            # URECHE (inclusiv captuseala inchisa): sus, in fata, inalta.
            name, root = "Ear" + ("L" if c.x < 0 else "R"), "Head"
            value, v_lo, v_hi = cz, body_z + 0.66, body_z + 0.80
        elif c.y > 0.90:
            # Bot, nari, ochi, cutia capului: tot ce e in fata de gat.
            name, root = "Head", "Head"
        elif c.y > 0.52:
            # Gatul si coama: greutatea curge din Body in Neck pe Y, ca gatul
            # sa se INDOAIE de la greaban in loc sa se franga la o muchie.
            name, root = "Neck", "Body"
            value, v_lo, v_hi = cy, 0.44, 0.72
        elif c.y < -0.55 and size.x < 0.22:
            # Coada (cele doua cutii inguste din spate).
            name, root = "Tail", "Body"
            value, v_lo, v_hi = neg_cy, 0.56, 0.70
        else:
            name, root = "Body", "Body"
        weight_ramp(obj, island, name, root, value, v_lo, v_hi)
        counts[name] = counts.get(name, 0) + 1

    expect = {"Body", "Neck", "Head", "Tail", "EarL", "EarR"}
    for _sx, _hy, tag in LEGS:
        expect.add("Leg" + tag)
        expect.add("Shin" + tag)
    assert set(counts) == expect, "piese nerecunoscute/lipsa: %r" % counts
    print("  insule pe oase:", counts)
    return arm


# ---------------------------------------------------------------------------
# Pozele. Toate rotatiile in spatiul armaturii, in grade.
# ---------------------------------------------------------------------------

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


def _leg_pose(tag, swing, knee):
    """Un picior: `swing` = unghiul din umar/sold (pozitiv = inainte),
    `knee` = indoirea genunchiului (pozitiv = calcaiul se duce inapoi).

    Rotatia e in jurul lui X in spatiul armaturii pentru amandoua: piciorul se
    misca in planul de mers (YZ), iar semnul e acelasi pe stanga si pe dreapta
    — un patruped nu isi departeaza picioarele ca sa mearga.
    """
    return {
        "Leg" + tag: ("rot", _axis_rot(x=swing)),
        "Shin" + tag: ("rot", _axis_rot(x=knee)),
    }


def _walk_frame(phase_deg):
    """Un picior la faza data din ciclu, ca (swing, knee).

    Un pas are doua jumatati: SPRIJIN (piciorul e pe pamant, deci se duce
    inapoi cu viteza constanta — corpul trece peste el) si BALANS (piciorul se
    ridica, genunchiul se indoaie si il aduce repede in fata). Amplitudinea e
    mica dinadins (18°): un magar la pas nu galopeaza, iar un ciclu prea larg
    pe un figurant care merge cu 1.2 m/s citeste ca patinaj.
    """
    t = (phase_deg % 360.0) / 360.0
    if t < 0.6:
        # sprijin: din +16 in -16, liniar
        u = t / 0.6
        return 16.0 - 32.0 * u, 2.0 + 4.0 * u
    # balans: inapoi in fata, cu genunchiul indoit la mijloc
    u = (t - 0.6) / 0.4
    swing = -16.0 + 32.0 * u
    knee = 6.0 + 30.0 * math.sin(math.pi * u)
    return swing, knee


# Mersul la pas al unui patruped: perechile DIAGONALE se misca impreuna.
# Fata-stanga cu spate-dreapta la faza 0, cealalta pereche la 180°.
WALK_PHASE = {"FL": 0.0, "RR": 0.0, "FR": 180.0, "RL": 180.0}


def animate(arm):
    """Cele doua actiuni. Cadrele-cheie inchid ciclul (ultimul = primul), ca
    bucla LOOP_LINEAR din Godot sa nu sara."""
    scene = bpy.context.scene
    scene.render.fps = 24
    if arm.animation_data is None:
        arm.animation_data_create()

    # WALK — 24 de cadre = 1 s, esantionat din 3 in 3 ca profilul rupt al
    # pasului (sprijin liniar / balans sinusoidal) sa nu fie netezit de
    # interpolarea dintre doua chei departate.
    walk = bpy.data.actions.new("Walk")
    arm.animation_data.action = walk
    for frame in range(1, 26, 3):
        t = (frame - 1) / 24.0
        pose = {}
        for tag, ph in WALK_PHASE.items():
            swing, knee = _walk_frame(ph + t * 360.0)
            pose.update(_leg_pose(tag, swing, knee))
        # Capul da din el pe ritm: doua batai pe ciclu (o bataie per pas
        # diagonal), si e cel mai vizibil semn ca animalul MERGE.
        pose["Neck"] = ("rot", _axis_rot(x=3.5 * math.sin(2.0 * math.tau * t)))
        pose["Head"] = ("rot", _axis_rot(x=-2.5 * math.sin(2.0 * math.tau * t)))
        # Crupa se leagana: o data pe ciclu, pe rulou si pe yaw.
        pose["Body"] = [("rot", _axis_rot(y=2.2 * math.sin(math.tau * t),
                                          z=1.6 * math.sin(math.tau * t)))]
        # Urechile clatina cu INTARZIERE fata de cap (un sfert de ciclu):
        # sincron ar citi ca o piesa rigida lipita de crestet.
        lag = math.sin(2.0 * math.tau * (t - 0.25))
        for side, sgn in (("L", -1.0), ("R", 1.0)):
            pose["Ear" + side] = ("rot", _axis_rot(x=5.0 * lag,
                                                   y=sgn * 3.0 * lag))
        pose["Tail"] = ("rot", _axis_rot(x=2.0 * math.sin(math.tau * t),
                                         y=4.0 * math.sin(math.tau * t + 0.7)))
        _key_pose(arm, frame, pose)

    # IDLE — 72 de cadre = 3 s. Pasunatul: capul coboara la iarba si se ridica.
    # Lung dinadins; un idle scurt pe un animal parcat langa drum citeste ca
    # tic nervos, nu ca liniste.
    idle = bpy.data.actions.new("Idle")
    arm.animation_data.action = idle
    #  cadru  gat(tangaj)  cap(tangaj)  ureche(L, R)  coada(yaw)
    phases = [
        (1,   0.0,   0.0,  (0.0, 0.0),   0.0),
        (13, 16.0,  22.0,  (4.0, -2.0),  5.0),   # coboara spre iarba
        (25, 22.0,  30.0,  (-3.0, 6.0), -4.0),   # paste
        (37, 20.0,  26.0,  (8.0, 0.0),   6.0),   # o ureche se roteste
        (49,  4.0,   6.0,  (0.0, -7.0), -5.0),   # ridica capul, cealalta ureche
        (61,  0.0,  -3.0,  (2.0, 2.0),   3.0),   # se uita in jur
    ]
    for frame, neck, head, ears, tail_yaw in phases:
        pose = {
            "Neck": ("rot", _axis_rot(x=neck)),
            "Head": ("rot", _axis_rot(x=head)),
            "EarL": ("rot", _axis_rot(x=ears[0], y=-abs(ears[0]) * 0.4)),
            "EarR": ("rot", _axis_rot(x=ears[1], y=abs(ears[1]) * 0.4)),
            "Tail": ("rot", _axis_rot(y=tail_yaw)),
        }
        # Picioarele stau: doar un transfer de greutate abia perceptibil.
        for tag in ("FL", "FR", "RL", "RR"):
            pose.update(_leg_pose(tag, 0.0, 2.0))
        _key_pose(arm, frame, pose)
    _key_pose(arm, 73, {
        "Neck": ("rot", _axis_rot()), "Head": ("rot", _axis_rot()),
        "EarL": ("rot", _axis_rot()), "EarR": ("rot", _axis_rot()),
        "Tail": ("rot", _axis_rot()),
    })

    stash_actions(arm, ("Walk", "Idle"))
    # Poza de repaus in fisier: fara actiune activa, oasele la zero.
    for pb in arm.pose.bones:
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)


def _bbox(obj):
    return island_bbox(obj, range(len(obj.data.vertices)))


if __name__ == "__main__":
    clear_built()
    b = Builder()
    build(b)
    obj = b.to_object("Donkey_Mesh")
    lo0, hi0 = _bbox(obj)
    stats = finish(obj, bevel=0.025, ao=AO_DONKEY, origin="base")
    lo1, hi1 = _bbox(obj)
    # Cat a mutat `finish` geometria (bevel-ul schimba bbox-ul cu < 1 cm — sub
    # orice prag de decizie din `rig`).
    shift = Vector((((lo1 + hi1) - (lo0 + hi0)).x * 0.5,
                    ((lo1 + hi1) - (lo0 + hi0)).y * 0.5,
                    lo1.z - lo0.z))
    print("  deplasarea din finish: %.3f %.3f %.3f" % tuple(shift))
    arm = rig(obj, shift)
    animate(arm)

    bpy.context.view_layer.update()
    d = obj.dimensions
    print("Donkey %4d tris  (buget 800)  AO %.2f..%.2f"
          % (stats["tris"], stats["ao_min"], stats["ao_max"]))
    print("  %.2f m lungime, %.2f m latime, %.2f m inaltime" % (d.y, d.x, d.z))
    print("GLB:   %s (%d B)" % export_glb([arm, obj],
                                          "stromboli/props/donkey.glb",
                                          animations=True))
    print("BLEND: %s (%d B)" % save_blend([arm, obj], "donkey.blend",
                                          compress=True))
