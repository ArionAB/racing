"""Baikal — kitul de gheata (planşa, pozitia 12).

  ice_kit.glb (props/)   Toros_A/B/C, IceSlabCracked, IceRoadMarker,
                         IceRoadSign, IceHole, FisherTent_Green,
                         FisherTent_Orange, IceBlockStack, FrozenBoat,
                         IceShards

Piesele de aici nu sunt decor pur — trei dintre ele sunt MECANICA:
  - `Toros_*`   creste de gheata folosite ca mici rampe (kicker), deci profilul
                lor pe directia de mers conteaza: panta de urcare lina, muchia
                de desprindere neteda. O creasta cu perete vertical n-ar lansa
                masina, ar opri-o.
  - `IceSlabCracked` e corpul placii care se inclina (`IceSlabHazard`), deci e
                o placa PLANA cu fete curate — se roteste in joc, iar orice
                neregularitate pe fata de sus s-ar citi ca tremurat.
  - `IceRoadMarker` marcheaza banda pe gheata: singurul lucru care spune unde e
                pista pe lac. Steagulet ROSU, cea mai vizibila culoare pe
                turcoaz si alb.

Gheata foloseste sloturile noi: ICE_TURQUOISE (fete la lumina), ICE_DEEP
(adancime, umbra), ICE_CRACK (fisuri, apa neagra).

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_baikal_ice.py
"""

import math
from mathutils import Matrix, Vector

AO_ICE = dict(samples=24, dist=4.0, gradient="vertical",
              low=0.58, high=1.00, power=0.8, floor=0.28)
AO_PROP = dict(samples=22, dist=3.0, gradient="vertical",
               low=0.48, high=1.00, power=0.9, floor=0.15)

# Steguletul de traseu si indicatorul rutier folosesc KERB_RED (7), nu CAR_RED
# (14). Sloturile de masina raman ale masinilor (style_bible §1) — iar bataia
# regulii se vede aici mai clar decat oriunde: bete de marcaj sunt ZECI pe
# autostrada de gheata, la fiecare 20 m. Ar fi fost cea mai mare suprafata de
# rosu pur din pista, pe fundal turcoaz si alb, adica fix competitia vizuala pe
# care regula o previne. KERB_RED e oricum rosul "de semnalizare" al paletei.


def _drop_to_zero(objs):
    bpy.context.view_layer.update()
    lo = min(min((o.matrix_world @ Vector(c)).z for c in o.bound_box)
             for o in objs)
    for o in objs:
        o.location.z -= lo


def _slab_plate(b, outline, thickness, slot, z0=0.0):
    """Placa ORIZONTALA dintr-un contur poligonal (x, y), groasa `thickness`.

    Exista fiindca `Builder.prism` extrudeaza un contur XZ pe Y — potrivit
    pentru panouri verticale, gresit pentru lespezi. Aici conturul e in planul
    XY si extrudarea e pe Z.

    Se construieste ca evantai de triunghiuri din centru: conturul poate fi
    concav fara ca fata sa iasa degenerata, iar cele cateva triunghiuri in plus
    fata de un ngon nu conteaza la o piesa unica.
    """
    import bmesh as _bm
    bm = b.bm
    top = [bm.verts.new((x, y, z0 + thickness)) for x, y in outline]
    bot = [bm.verts.new((x, y, z0)) for x, y in outline]
    ct = bm.verts.new((0.0, 0.0, z0 + thickness))
    cb = bm.verts.new((0.0, 0.0, z0))
    n = len(outline)
    faces = []
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((ct, top[i], top[j])))
        faces.append(bm.faces.new((cb, bot[j], bot[i])))
        faces.append(bm.faces.new((bot[i], bot[j], top[j], top[i])))
    return b._tag(top + bot + [ct, cb], slot)


# ============================================================ Torosuri (kicker)
def _toros(name, length, height, seed, width=2.6):
    """Creasta de gheata sparta: placi impinse una peste alta.

    E si RAMPA (brief §3: "kicker-e naturale"), deci geometria e constransa de
    fizica, nu doar de aspect: fata dinspre -Y urca in panta continua (masina
    intra pe ea), varful e o muchie scurta, iar fata din spate poate fi abrupta.
    Placile individuale se inclina spre varf, ca torosurile reale, dar niciuna
    nu iese peste profilul de rampa — altfel roata ar lovi o treapta.
    """
    b = Builder()
    rand = _lcg(seed)
    n = max(int(length / 0.85), 4)
    for i in range(n):
        t = i / (n - 1.0)
        x = -length * 0.5 + length * t
        # profilul rampei: urcare lina pana la 70% din lungime, apoi coborare
        if t < 0.70:
            prof = (t / 0.70) ** 0.85
        else:
            prof = 1.0 - ((t - 0.70) / 0.30) ** 1.35 * 0.86
        h = max(height * prof, 0.10)
        # placa: turtita, inclinata spre varf; unghiul creste cu panta
        tilt = math.radians(18.0 + 30.0 * (1.0 - abs(t - 0.70) / 0.70))
        w = width * (0.55 + rand() * 0.5)
        slot = ICE_TURQUOISE if rand() > 0.32 else ICE_DEEP
        b.box((x, (rand() - 0.5) * width * 0.30, h * 0.52),
              (0.55 + rand() * 0.35, w, h * 1.05), slot,
              rotation=Matrix.Rotation(tilt * (1.0 if t < 0.7 else -1.0), 3,
                                       "Y"))
    # cioburi la baza, pe ambele parti — ascund linia unde creasta atinge solul
    for i in range(int(n * 0.8)):
        x = (rand() - 0.5) * length
        sy = -1 if rand() > 0.5 else 1
        b.box((x, sy * (width * 0.45 + rand() * 0.35), 0.10 + rand() * 0.12),
              (0.30 + rand() * 0.30, 0.24 + rand() * 0.26, 0.20 + rand() * 0.20),
              FOAM_WHITE if rand() > 0.6 else ICE_TURQUOISE,
              rotation=Matrix.Rotation(rand() * 3.14, 3, "Z"))
    obj = b.to_object(name)
    finish(obj, bevel=0.03, ao=AO_ICE, origin="base")
    return obj


def build_ice_kit():
    clear_built()
    objs = []

    # --- trei torosuri, 4-10 m, 0.6-1.5 m inaltime (brief) -----------------
    objs.append(_toros("Toros_A", 4.0, 0.65, seed=101, width=2.2))
    objs.append(_toros("Toros_B", 7.0, 1.05, seed=202, width=2.8))
    objs.append(_toros("Toros_C", 10.0, 1.45, seed=303, width=3.4))

    # --- placa crapata 7x7x0.8 (corpul hazardului) -------------------------
    # Placa e POLIGONALA, nu patrata: gheata se sparge in poligoane neregulate,
    # si asta o deosebeste de o dala de beton. Fata de sus ramane PLANA (se
    # roteste in joc), variatia e doar in contur si in muchii.
    b = Builder()
    rand = _lcg(7007)
    n = 7
    outline = []
    for i in range(n):
        a = 2.0 * math.pi * i / n
        r = 3.5 * (0.86 + rand() * 0.28)
        outline.append((r * math.cos(a), r * math.sin(a)))
    # ATENTIE la axa: `prism` primeste un contur in planul XZ si extrudeaza pe
    # Y. Un contur ORIZONTAL (x, y) dat direct lui prism iese in PICIOARE — asa
    # a si iesit prima versiune, o lespede de 7 m inaltime in loc de o placa de
    # gheata. Placa se construieste in schimb ca sector-uri de disc: un
    # ventilator de triunghiuri extrudat pe Z, adica exact ce e nevoie aici.
    _slab_plate(b, outline, thickness=0.8, slot=ICE_TURQUOISE)
    # muchia de sus: banda de gheata alba sparta pe contur
    for i in range(n):
        x0, y0 = outline[i]
        x1, y1 = outline[(i + 1) % n]
        for pt in _span_points((x0, y0, 0.78), (x1, y1, 0.78), 0.75,
                               endpoints=False):
            b.box((pt.x * 0.985, pt.y * 0.985, 0.80),
                  (0.42 + rand() * 0.3, 0.42 + rand() * 0.3, 0.12),
                  FOAM_WHITE, rotation=Matrix.Rotation(rand() * 3.14, 3, "Z"))
    # fata de jos, in apa neagra
    _slab_plate(b, [(x * 0.97, y * 0.97) for x, y in outline], thickness=0.12,
                slot=ICE_CRACK, z0=-0.02)
    slab = b.to_object("IceSlabCracked")
    finish(slab, bevel=0.03, ao=AO_ICE, origin="base")
    objs.append(slab)

    # --- batul cu steguletul rosu, 1.5 m -----------------------------------
    # Marcheaza banda pe gheata la fiecare 20 m. E singurul indiciu de traseu
    # pe lac, deci trebuie sa se vada de departe: steag mare pe bat subtire.
    b = Builder()
    b.frustum((0.0, 0.0, 0.72), 0.045, 0.035, 1.44, WOOD, segments=6)
    # baza inghetata in gheata
    b.rock((0.0, 0.0, -0.02), (0.42, 0.42, 0.16), FOAM_WHITE, seed=9,
           segments=6, rings=2, taper=0.5, squash=0.7)
    # steguletul: triunghi rigid (inghetat), nu fasie moale
    b.prism([(0.0, 0.0), (0.46, -0.12), (0.0, -0.30)], 0.02, KERB_RED,
            center=(0.05, 0.0, 1.30))
    marker = b.to_object("IceRoadMarker")
    finish(marker, bevel=0.01, ao=AO_PROP, origin="base_axis")
    objs.append(marker)

    # --- indicatorul rutier in bloc de gheata, 2 m -------------------------
    b = Builder()
    b.rock((0.0, 0.0, 0.0), (0.85, 0.85, 0.52), ICE_TURQUOISE, seed=44,
           segments=7, rings=2, taper=0.35, squash=0.8)
    b.frustum((0.0, 0.0, 1.15), 0.055, 0.05, 1.5, RUST, segments=6)
    # discul: cerc alb cu inel rosu (indicator rusesc, fara cifre)
    b.cylinder((0.0, 0.03, 1.86), 0.40, 0.05, KERB_RED, segments=12, axis="Y")
    b.cylinder((0.0, 0.055, 1.86), 0.31, 0.04, FOAM_WHITE, segments=12,
               axis="Y")
    sign = b.to_object("IceRoadSign")
    finish(sign, bevel=0.015, ao=AO_PROP, origin="base_axis")
    objs.append(sign)

    # --- copca cu undita si scaunel ----------------------------------------
    b = Builder()
    # gaura: disc negru, cu buza de gheata scoasa in jur
    b.cylinder((0.0, 0.0, 0.02), 0.26, 0.04, ICE_CRACK, segments=10)
    rand = _lcg(515)
    for i in range(9):
        a = 2.0 * math.pi * i / 9
        r = 0.36 + rand() * 0.16
        b.rock((r * math.cos(a), r * math.sin(a), 0.0),
               (0.26 + rand() * 0.16, 0.24 + rand() * 0.14, 0.10 + rand() * 0.10),
               FOAM_WHITE, seed=60 + i * 7, segments=6, rings=2, taper=0.5,
               squash=0.7)
    # scaunelul
    b.box((0.62, 0.0, 0.30), (0.32, 0.30, 0.05), WOOD)
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.beam((0.62 + sx * 0.12, sy * 0.11, 0.0),
                   (0.62 + sx * 0.12, sy * 0.11, 0.28), 0.035, WOOD)
    # undita, sprijinita spre copca
    b.beam((0.55, 0.10, 0.34), (0.10, 0.02, 0.55), 0.022, WOOD)
    hole = b.to_object("IceHole")
    finish(hole, bevel=0.01, ao=AO_PROP, origin="base")
    objs.append(hole)

    # --- doua corturi de pescuit, 2x2x1.8 ----------------------------------
    # Cortul e o PIRAMIDA, si se construieste ca atare: `revolve` cu 4 segmente
    # pe un profil (raza la baza -> 0 la varf). Prima versiune incerca sa
    # compuna cele patru fete din cutii rotite, alegand axa de rotatie dupa
    # care coordonata a mijlocului e mai mare — logica s-a incurcat si a iesit
    # o stea cu brate, nu un cort (vizibil imediat in randarea de control).
    # `revolve` face fetele inclinate corect prin constructie.
    for name, slot, seed in (("FisherTent_Green", TROPICAL_GREEN, 11),
                             ("FisherTent_Orange", KERB_RED, 22)):
        b = Builder()
        rand = _lcg(seed)
        h = 1.8
        half = 1.05
        # profilul: piramida usor bombata (panza intinsa intre tarusi se umfla)
        prof = [(half, 0.0), (half * 0.86, h * 0.32), (half * 0.55, h * 0.66),
                (0.0, h)]
        faces = b.revolve(prof, slot, segments=4)
        # rotita 45 grade: cu fetele spre axe, cortul citeste mai bine din
        # masina (o muchie spre camera, nu o fata plata)
        for v in {v for f in faces for v in f.verts}:
            x, y = v.co.x, v.co.y
            v.co.x = x * 0.7071 - y * 0.7071
            v.co.y = x * 0.7071 + y * 0.7071
        # capacul de zapada pe varf
        b.rock((0.0, 0.0, h - 0.30), (0.50, 0.50, 0.26), FOAM_WHITE, seed=seed,
               segments=6, rings=2, taper=0.5, squash=0.8)
        # hornul de soba, iesind printr-o fata
        b.cylinder((0.40, -0.34, h * 0.62), 0.05, 0.85, RUST, segments=6)
        b.cylinder((0.40, -0.34, h * 0.62 + 0.47), 0.08, 0.09, RUST,
                   segments=6)
        # usa: fanta mai inchisa pe fata +Y, urmand panta panzei
        b.box((0.0, half * 0.62, 0.48), (0.46, 0.06, 0.86), ASPHALT_EDGE,
              rotation=Matrix.Rotation(math.radians(-16.0), 3, "X"))
        # tarusi la colturi
        for k in range(4):
            a = math.radians(45.0 + k * 90.0)
            b.beam((math.cos(a) * half * 1.12, math.sin(a) * half * 1.12, 0.0),
                   (math.cos(a) * half * 0.96, math.sin(a) * half * 0.96, 0.22),
                   0.035, WOOD)
        obj = b.to_object(name)
        finish(obj, bevel=0.02, ao=AO_PROP, origin="base")
        objs.append(obj)

    # --- blocuri de gheata taiate, stivuite --------------------------------
    b = Builder()
    rand = _lcg(838)
    for r in range(3):
        cnt = 3 - r
        for c in range(cnt):
            x = -(cnt - 1) * 0.55 + c * 1.10
            b.box((x + (rand() - 0.5) * 0.08, (rand() - 0.5) * 0.12,
                   0.25 + r * 0.52),
                  (1.0, 1.0, 0.5),
                  ICE_TURQUOISE if rand() > 0.35 else ICE_DEEP,
                  rotation=Matrix.Rotation(math.radians((rand() - 0.5) * 12.0),
                                           3, "Z"))
    stack = b.to_object("IceBlockStack")
    finish(stack, bevel=0.025, ao=AO_ICE, origin="base")
    objs.append(stack)

    # --- barca prinsa in gheata, 5 m ---------------------------------------
    b = Builder()
    # coca: prisma cu contur de barca, pe jumatate ingropata
    hull = [(2.5, 0.0), (1.6, 0.72), (-1.4, 0.80), (-2.1, 0.55),
            (-2.1, -0.55), (-1.4, -0.80), (1.6, -0.72)]
    b.prism(hull, 0.95, WOOD, center=(0.0, 0.0, 0.48))
    # bordajul, un ton mai inchis
    b.prism([(x * 1.02, y * 1.06) for x, y in hull], 0.16, LOG_DARK,
            center=(0.0, 0.0, 0.90))
    # banchete
    for x in (-1.0, 0.2, 1.3):
        b.box((x, 0.0, 0.80), (0.20, 1.30, 0.08), WOOD)
    # zapada in barca si in jurul ei
    b.prism([(x * 0.88, y * 0.80) for x, y in hull], 0.14, FOAM_WHITE,
            center=(0.0, 0.0, 0.60))
    rand = _lcg(626)
    for i in range(7):
        a = 2.0 * math.pi * i / 7
        b.rock((math.cos(a) * (2.0 + rand()), math.sin(a) * (1.1 + rand() * 0.6),
                0.0),
               (1.3 + rand(), 0.9 + rand() * 0.6, 0.22 + rand() * 0.22),
               FOAM_WHITE, seed=170 + i * 11, segments=6, rings=2, taper=0.5,
               squash=0.7)
    boat = b.to_object("FrozenBoat")
    finish(boat, bevel=0.025, ao=AO_PROP, origin="base")
    objs.append(boat)

    # --- cioburi de gheata (set mic, pentru marginile placilor) ------------
    b = Builder()
    rand = _lcg(939)
    for i in range(14):
        a = 2.0 * math.pi * rand()
        r = 0.3 + rand() * 1.5
        b.box((math.cos(a) * r, math.sin(a) * r, 0.08 + rand() * 0.14),
              (0.22 + rand() * 0.40, 0.18 + rand() * 0.32, 0.16 + rand() * 0.28),
              (ICE_TURQUOISE, FOAM_WHITE, ICE_DEEP)[i % 3],
              rotation=Matrix.Rotation(rand() * 3.14, 3, "Z")
                       @ Matrix.Rotation(math.radians((rand() - 0.5) * 50.0),
                                         3, "Y"))
    shards = b.to_object("IceShards")
    finish(shards, bevel=0.015, ao=AO_ICE, origin="base")
    objs.append(shards)

    # asezate pe un rand
    x = 0.0
    for o in objs:
        o.location.x = x
        x += 9.0
    _drop_to_zero(objs)
    print("IceKit: %d tris (%s)"
          % (sum(tri_count(o) for o in objs),
             ", ".join("%s %d" % (o.name, tri_count(o)) for o in objs)))
    export_glb(objs, "props/ice_kit.glb")
    save_blend(objs, "baikal_ice_kit.blend")
    return objs


if __name__ == "__main__":
    build_ice_kit()
