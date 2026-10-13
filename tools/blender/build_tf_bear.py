"""Transfagarasan (Track21) — URSUL BRUN animat, hazardul unic al pistei.

    assets/models/transfagarasan/animals/brown_bear.glb
    clipuri: Idle (bucla), Walk (bucla, pas greu), Stand (se ridica si tine poza)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_tf_bear.py

**Sursa geometriei: mesh propriu, rig scris in cod** (reteta elefantului si a
testoasei, memoria `elefant-mesh-importat-rig-per-vertex`). In
`D:/GameDev/downloaded assets/Animals/` nu exista un urs brun utilizabil:
  - `191 animals pack` are doar `Polar_Bear_Low_Poly` (in animalpack.blend /
    .obj). Pachetul NU are fisier de licenta (doar capturi de ecran in
    `Yeni klasor`), iar silueta de urs polar e alta: gat lung, cap mic si
    plat, fara cocoasa de umeri — exact trasatura dupa care se citeste ursul
    brun pe decupare;
  - `Ultimate Animated Animals` (Quaternius, CC0) are Wolf/Husky/Bull ca
    schelete de patruped, dar mesh-urile lor sunt lup/caine/taur; rig-ul de
    lup nu se ridica in doua labe fara oase de coloana pe care sa le
    controlam, iar mesh-ul ar fi trebuit refacut oricum;
  - `Farm Animal Pack` si pachetul ithappy pentru Godot nu au urs.
Decuparea e un urs cu FATETE MARI (triunghiuri plate, fara netezire): forma
asta iese direct din sectiuni transversale putine, unite in fasii de
triunghiuri si umbrite plat. Licenta: geometria e a proiectului.

**Lista de elemente (kit §0.1 pasul 1), scrisa inainte de primul vertex.**

`brown_bear_walk.png` (urs in patru labe, din 3/4 fata-dreapta):
  1. corpul: o masa, CU COCOASA de umeri (cel mai inalt punct, deasupra
     labelor din fata), saua usor coborata in spatele ei si crupa rotunda,
     putin mai joasa decat cocoasa (~0,87 din inaltime);
  2. capul: lat in obraji, fruntea plata, botul scurt si conic spre +Y, tinut
     MAI JOS decat cocoasa (crestetul ~0,85 din inaltime); gatul nu se vede ca
     gat, capul iese direct din piept;
  3. 2 urechi mici, rotunde, sus si lateral pe crestet;
  4. 2 ochi mici, inchisi; nasul inchis la varful botului;
  5. 4 picioare groase, cu coapsa lata la picioarele din spate; labele mari,
     plate (plantigrad), cu 4 gheare inchise la varf fiecare;
  6. coada: practic invizibila (nu se modeleaza);
  7. culoare: blana maro-roscata UNIFORMA (contract revizuit: LARCH_RUST
     dominant, ~75%), mai inchisa jos (LOG_DARK pe gambe, labe, burta, sub
     barbie, in trepte pe fatete), varful botului mai deschis (SAND_MID),
     nasul si ghearele aproape negre.
 Contract revizuit (coordonator, dupa prima serie): cocoasa 0,15-0,20 m peste
 crupa, corp rotund si adanc (~0,8 din greaban), picioare groase, cap mare;
 ridicat: para lata jos, brate departate 12-15 grade, genunchi usor indoiti,
 capul intors 10-15 grade.
`brown_bear_stand.png` (ridicat, aproape din fata):
  8. trunchiul aproape vertical, picioarele din spate drepte sub el, talpile
     intregi pe sol;
  9. labele din fata ATARNA in fata pieptului (antebratul spre inainte-jos,
     laba moale in jos), departate de corp, NU ridicate, NU gesturi umane;
 10. capul sta direct pe umeri, fara gat vizibil, botul inainte, usor in jos
     (corectura kitului: „capul jos intre umeri");
 11. cocoasa de umeri devine spatele lat din spatele capului.

**Cote (kit §1.6):** 2,6 m lung in patru labe (bot-crupa), greabanul 1,4 m,
3,0 m ridicat. Originea la baza, centrata; fata spre +Y (-Z in Godot), ca
`face_travel` sa mearga.

**Contractul cu `SlidingHazard`:** clipurile se numesc exact `Idle`, `Walk`,
`Stand` (`ANIM_REST`, `ANIM_WALK`, `ANIM_STAND`). Fara root motion: hazardul
misca nodul. `Stand` se joaca o data pe durata telegrafului (1,2 s), deci
clipul dureaza ~1,17 s si se termina in poza tinuta; `Idle` si `Walk` se pun
pe bucla la runtime (`_hook_animation`), aici doar se inchid cu primul cadru.

**Schelet (13 oase):** Hips (radacina, pivot la articulatia soldului) ->
Chest (pivot in mijlocul spatelui) -> Head (pivot la baza gatului); fiecare
picior are 3 oase (sus, jos, laba). Greutatea e RIGIDA pe piese: fiecare
piesa e o insula proprie, cu toate varfurile pe un singur os (un urs de
jucarie cu fatete nu se indoaie). Piesele se suprapun la incheieturi, ca o
rotatie sa nu deschida o gaura. Scheletul ramane la identitate pe nodul
armaturii (nimic de aplicat): totul se construieste direct la scara metrica.

**AO = gradient vertical** pe poza de repaus (blana se misca; raycast-ul ar
lipi umbre de ea). **Fara sange, rana sau cadere** (brief §8).
"""

import bpy
import bmesh
import math
from mathutils import Matrix, Vector

OUT = "transfagarasan/animals/brown_bear.glb"

# Contract revizuit (verdictul coordonatorului): blana DOMINANTA e LARCH_RUST
# (maro-roscat, ~65-75% din arie), LOG_DARK doar jos (gambe, labe, burta, sub
# barbie), varful botului SAND_MID, nasul si ghearele VOLCANIC_BLACK.
FUR, TIP, SHADE, MUZZLE, DARK = LARCH_RUST, LARCH_RUST, LOG_DARK, SAND_MID, VOLCANIC_BLACK
DARK_BELOW = 0.58        # sub scorul asta (inaltime + 0,22 x normala.z) blana e LOG_DARK (picioare)
BELLY_BELOW = 0.0        # fara fasie inchisa pe burta: ridicat citea ca o esarfa (decizia coordonatorului)
FPS = 24
AO_FLOOR = 0.60          # talpile; 1,0 pe spinare

# Articulatiile (spatiul armaturii = spatiul lumii; armatura la identitate).
HIP_Z = 0.94
HIP_Y = -0.88
HIND_X = 0.28
FRONT_X = 0.27
SHO_Y = 0.40
SHO_Z = 1.00
CHEST_PIVOT = (0.0, -0.30, 0.98)
NECK = (0.0, 0.70, 1.04)

# Poza ridicata (Stand, s = 1). Unghiurile se aduna pe lant (copilul se roteste
# in cadrul parintelui), toate in jurul lui X: + = botul in sus.
ST_HIPS = 60.0           # crupa se lasa, trunchiul se ridica din sold
ST_CHEST = 18.0          # inca putin din mijlocul spatelui -> trunchi ~78 grade (aplecat usor inainte, ca pe decupare)
ST_HEAD_TOTAL = -8.0     # capul ramane aproape orizontal, botul usor in jos
ST_HEAD_SINK = 0.05      # capul intra intre umeri (pe axa spatelui)
ST_STRETCH = 0.27        # spatele se intinde (suprapunerea crupa/piept e 0,38 m)
ST_ARM = 6.0            # bratul atarna usor in fata pieptului
ST_FOREARM = 46.0        # antebratul spre inainte-jos, din cot
ST_ABDUCT = 15.0         # bratele departate de corp (contract revizuit: 12-15 grade)
ST_KNEE = 12.0           # genunchii usor indoiti, talpa plata
ST_HEAD_YAW = 12.0       # capul intors spre stanga ursului, ca pe decupare
ST_PAW = -62.0           # laba moale, in jos (unghiul ei total fata de orizontala)


# Deplasarea care pune originea la baza, centrata (calculata pe mesh, aplicata
# si oaselor).
OFFSET = [0.0, 0.0, 0.0]

# ----------------------------------------------------------------- geometrie

class Bear:
    """Acumuleaza insule: varfuri, triunghiuri, slotul fiecarei fete, osul
    fiecarei insule."""

    def __init__(self):
        self.verts = []
        self.faces = []
        self.face_slot = []
        self.face_piece = []
        self.vert_bone = []
        self.pieces = []

    def _add(self, pts, tris, bone, slot, piece):
        base = len(self.verts)
        self.verts += [tuple(p) for p in pts]
        self.vert_bone += [bone] * len(pts)
        for t in tris:
            self.faces.append(tuple(base + i for i in t))
            self.face_slot.append(slot)
            self.face_piece.append(piece)
        self.pieces.append(piece)

    def loft(self, piece, bone, slot, rings, seed, jitter=0.022, caps=(0.06, 0.06)):
        """Fasie de triunghiuri prin inele cu acelasi numar de puncte. Diagonalele
        alterneaza, ca fatetele sa iasa triunghiuri neregulate (ca pe decupare),
        nu benzi. Capetele: evantai spre un varf impins in afara cu `caps`."""
        rnd = _lcg(seed)
        n = len(rings[0])
        pts = []
        for ring in rings:
            for p in ring:
                pts.append(Vector(p) + Vector(((rnd() - 0.5) * 2 * jitter,
                                               (rnd() - 0.5) * 2 * jitter,
                                               (rnd() - 0.5) * 2 * jitter)))
        tris = []
        for r in range(len(rings) - 1):
            a0, b0 = r * n, (r + 1) * n
            for k in range(n):
                k1 = (k + 1) % n
                p00, p01, p10, p11 = a0 + k, a0 + k1, b0 + k, b0 + k1
                if (k + r) % 2 == 0:
                    tris += [(p00, p01, p11), (p00, p11, p10)]
                else:
                    tris += [(p00, p01, p10), (p01, p11, p10)]
        # capete
        c_first = sum((pts[i] for i in range(n)), Vector()) / n
        c_last = sum((pts[(len(rings) - 1) * n + i] for i in range(n)), Vector()) / n
        axis = (c_last - c_first).normalized()
        cf = len(pts)
        pts.append(c_first - axis * caps[0])
        cl = len(pts)
        pts.append(c_last + axis * caps[1])
        last = (len(rings) - 1) * n
        for k in range(n):
            k1 = (k + 1) % n
            tris.append((cf, k1, k))
            tris.append((cl, last + k, last + k1))
        self._add(pts, tris, bone, slot, piece)

    def blob(self, piece, bone, slot, center, size, seed=0):
        """Piesa mica (ochi, gheara): octaedru turtit."""
        cx, cy, cz = center
        sx, sy, sz = size
        pts = [(cx + sx, cy, cz), (cx - sx, cy, cz), (cx, cy + sy, cz),
               (cx, cy - sy, cz), (cx, cy, cz + sz), (cx, cy, cz - sz)]
        tris = [(0, 2, 4), (2, 1, 4), (1, 3, 4), (3, 0, 4),
                (2, 0, 5), (1, 2, 5), (3, 1, 5), (0, 3, 5)]
        self._add(pts, tris, bone, slot, piece)


def ring_y(y, cx, cz, hw, up, dn, n=8, power=0.85, flat_top=1.0):
    """Inel transversal pe Y (corp, cap, labe): latime +-hw, sus `up`, jos `dn`."""
    out = []
    for k in range(n):
        a = 2 * math.pi * k / n + math.pi / n
        c, s = math.cos(a), math.sin(a)
        cc = math.copysign(abs(c) ** power, c)
        ss = math.copysign(abs(s) ** power, s)
        h = up * flat_top if s > 0 else dn
        out.append((cx + hw * cc, y, cz + h * ss))
    return out


def ring_z(z, cx, cy, hw, fwd, back, n=8, power=0.85):
    """Inel orizontal pe Z (picioare): latime +-hw, in fata `fwd`, in spate `back`."""
    out = []
    for k in range(n):
        a = 2 * math.pi * k / n + math.pi / n
        c, s = math.cos(a), math.sin(a)
        cc = math.copysign(abs(c) ** power, c)
        ss = math.copysign(abs(s) ** power, s)
        d = fwd if s > 0 else back
        out.append((cx + hw * cc, cy + d * ss, z))
    return out


def build_mesh():
    b = Bear()
    # 1. Crupa (Hips): rotunda (sectiuni aproape circulare, nu cutie), spinarea
    #    COBOARA spre coada: 1,22 m, cu 0,18 m sub cocoasa (contract revizuit).
    #    Lata ~1,06 m: ridicat, crupa e baza „perei".
    b.loft("Rump", "Hips", FUR, [
        ring_y(-1.26, 0, 0.86, 0.16, 0.14, 0.16, power=1.0),
        ring_y(-1.16, 0, 0.86, 0.37, 0.30, 0.36, power=1.0),
        ring_y(-0.98, 0, 0.86, 0.50, 0.33, 0.42, power=1.0),
        ring_y(-0.70, 0, 0.86, 0.56, 0.35, 0.44, power=1.0),
        ring_y(-0.40, 0, 0.86, 0.56, 0.37, 0.47, power=1.0),
        ring_y(-0.05, 0, 0.87, 0.54, 0.40, 0.49, power=1.0),
    ], seed=11, caps=(0.03, 0.05))
    # 1. Pieptul (Chest) cu COCOASA de umeri: cel mai inalt punct (1,40 m), chiar
    #    deasupra labelor din fata; adanc (burta la ~0,34 m, ~0,75 din greaban) si
    #    lat (~1,1 m la umeri).
    b.loft("Chest", "Chest", FUR, [
        ring_y(-0.40, 0, 0.86, 0.50, 0.37, 0.46, power=1.0),
        ring_y(-0.10, 0, 0.88, 0.56, 0.44, 0.52, power=1.0),
        ring_y(0.22, 0, 0.91, 0.55, 0.49, 0.57, power=1.0),
        ring_y(0.48, 0, 0.94, 0.50, 0.43, 0.54, power=1.0),
        ring_y(0.66, 0, 0.98, 0.41, 0.33, 0.45, power=1.0),
        ring_y(0.80, 0, 1.00, 0.29, 0.22, 0.31, power=1.0),
    ], seed=23, caps=(0.03, 0.03))
    # 2. Capul (Head): MARE (~0,56 m lat, ~0,60 m de la ceafa la nas), fruntea
    #    lata si bombata, botul se ingusteaza treptat; gatul gros si scurt
    #    (ceafa ascunsa in piept); crestetul ~1,29 m, sub linia cocoasei.
    b.loft("Head", "Head", FUR, [
        ring_y(0.60, 0, 1.02, 0.31, 0.25, 0.31, power=1.0),
        ring_y(0.78, 0, 1.04, 0.29, 0.25, 0.27, power=1.0),
        ring_y(0.92, 0, 1.04, 0.28, 0.24, 0.22, power=1.0),
        ring_y(1.04, 0, 1.00, 0.21, 0.17, 0.17, power=1.0),
        ring_y(1.16, 0, 0.95, 0.14, 0.11, 0.11, power=1.0),
        ring_y(1.26, 0, 0.93, 0.09, 0.07, 0.07, power=1.0),
    ], seed=37, jitter=0.014, caps=(0.03, 0.03))
    # 3. Urechile: discuri scurte si rotunde, sus-lateral pe crestet.
    for sx in (-1, 1):
        b.loft("Ear", "Head", FUR, [
            ring_z(1.20, sx * 0.21, 0.82, 0.095, 0.06, 0.05, n=6, power=1.0),
            ring_z(1.29, sx * 0.215, 0.815, 0.095, 0.055, 0.045, n=6, power=1.0),
            ring_z(1.34, sx * 0.22, 0.81, 0.06, 0.035, 0.03, n=6, power=1.0),
        ], seed=41 + sx, jitter=0.006, caps=(0.0, 0.015))
    # 4. Ochii (inchisi), pe fata, la radacina botului.
    for sx in (-1, 1):
        b.blob("Eye", "Head", DARK, (sx * 0.15, 1.02, 1.12), (0.028, 0.016, 0.024))
    # 5. Picioarele GROASE (decuparea: ~0,4 m latime la umar): sus / jos / laba.
    for side, sx in (("L", -1), ("R", 1)):
        fx, hx = sx * FRONT_X, sx * HIND_X
        # fata: bratul (in piept) -> antebratul -> laba lata
        b.loft("ArmF", "LegFU_" + side, FUR, [
            ring_z(1.04, fx, 0.36, 0.22, 0.25, 0.27, power=1.0),
            ring_z(0.78, fx, 0.40, 0.21, 0.22, 0.23, power=1.0),
            ring_z(0.55, fx, 0.42, 0.19, 0.18, 0.18, power=1.0),
            ring_z(0.42, fx, 0.42, 0.18, 0.16, 0.16, power=1.0),
        ], seed=51 + sx, caps=(0.02, 0.03))
        b.loft("ForeF", "LegFL_" + side, FUR, [
            ring_z(0.54, fx, 0.42, 0.18, 0.16, 0.16, power=1.0),
            ring_z(0.32, fx, 0.43, 0.17, 0.15, 0.15, power=1.0),
            ring_z(0.15, fx, 0.44, 0.165, 0.14, 0.135, power=1.0),
        ], seed=61 + sx, caps=(0.02, 0.02))
        b.loft("PawF", "PawF_" + side, FUR, [
            ring_y(0.28, fx, 0.10, 0.17, 0.08, 0.10),
            ring_y(0.44, fx, 0.085, 0.175, 0.09, 0.085),
            ring_y(0.58, fx, 0.06, 0.165, 0.06, 0.06),
        ], seed=71 + sx, jitter=0.012, caps=(0.02, 0.04))
        for gx in (-0.09, -0.03, 0.03, 0.09):
            b.blob("ClawF", "PawF_" + side, DARK, (fx + gx, 0.625, 0.022), (0.016, 0.03, 0.018))
        # spate: coapsa lata (in crupa) -> gamba -> talpa lunga
        b.loft("ThighH", "LegHU_" + side, FUR, [
            ring_z(1.10, hx, HIP_Y, 0.25, 0.34, 0.32, power=1.0),
            ring_z(0.84, hx, HIP_Y + 0.02, 0.24, 0.30, 0.28, power=1.0),
            ring_z(0.58, hx, HIP_Y + 0.04, 0.19, 0.19, 0.18, power=1.0),
            ring_z(0.45, hx, HIP_Y + 0.02, 0.18, 0.16, 0.16, power=1.0),
        ], seed=81 + sx, caps=(0.02, 0.03))
        b.loft("ShinH", "LegHL_" + side, FUR, [
            ring_z(0.53, hx, HIP_Y + 0.02, 0.18, 0.16, 0.16, power=1.0),
            ring_z(0.31, hx, HIP_Y - 0.02, 0.17, 0.15, 0.15, power=1.0),
            ring_z(0.15, hx, HIP_Y - 0.04, 0.165, 0.14, 0.14, power=1.0),
        ], seed=91 + sx, caps=(0.02, 0.02))
        b.loft("PawH", "PawH_" + side, FUR, [
            ring_y(HIP_Y - 0.19, hx, 0.085, 0.16, 0.07, 0.085),
            ring_y(HIP_Y - 0.02, hx, 0.08, 0.17, 0.08, 0.08),
            ring_y(HIP_Y + 0.15, hx, 0.06, 0.165, 0.055, 0.06),
        ], seed=101 + sx, jitter=0.012, caps=(0.02, 0.04))
        for gx in (-0.09, -0.03, 0.03, 0.09):
            b.blob("ClawH", "PawH_" + side, DARK, (hx + gx, HIP_Y + 0.195, 0.022), (0.016, 0.03, 0.018))
    return b


def make_object(b):
    me = bpy.data.meshes.new("BrownBear_Mesh")
    me.from_pydata(b.verts, [], b.faces)
    me.validate()
    # normalele spre exterior, insula cu insula (ordinea inelelor nu garanteaza
    # sensul; cu normalele intoarse, „fetele de sus" ar fi iesit burta)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    me.update()
    obj = bpy.data.objects.new("BrownBear_Mesh", me)
    bpy.context.collection.objects.link(obj)
    # originea la baza, centrata in plan: tot mesh-ul si scheletul se muta cu
    # acelasi OFFSET (oasele il primesc in bones_spec)
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    lo = min(v.co.z for v in me.vertices)
    OFFSET[:] = [-(min(xs) + max(xs)) / 2, -(min(ys) + max(ys)) / 2, -lo]
    for v in me.vertices:
        v.co += Vector(OFFSET)
    me.update()
    for p in me.polygons:
        p.use_smooth = False  # fatete mari, ca pe decupare
    return obj


def paint(obj, b):
    """Sloturi pe fete (UV colapsat pe centrul slotului) + AO gradient vertical."""
    me = obj.data
    slots = []
    zoff, yoff = OFFSET[2], OFFSET[1]
    for i, (p, slot, piece) in enumerate(zip(me.polygons, b.face_slot, b.face_piece)):
        c, n = p.center, p.normal
        if slot != FUR:
            slots.append(slot)  # ochi, gheare: raman VOLCANIC_BLACK
            continue
        # Blana: LARCH_RUST dominant; LOG_DARK jos (gambe, labe, burta, sub
        # barbie). Granita e un prag pe INALTIME + NORMALA, cu un zgomot
        # determinist per fata: urmeaza fatetele in trepte, nu o linie dreapta.
        jit = ((i * 2654435761) % 1000) / 1000.0 - 0.5
        score = (c.z - zoff) + 0.22 * n.z + 0.08 * jit
        s = TIP
        if piece in ("Rump", "Chest"):
            # doar fasia de sub burta: ridicat, burta e fata ursului spre
            # camera, iar pe decupare ea are aceeasi blana ca restul
            s = SHADE if score < BELLY_BELOW else TIP
        elif piece in ("ArmF", "ThighH"):
            s = SHADE if score < DARK_BELOW else TIP
        elif piece in ("PawH", "ShinH"):
            s = SHADE  # gamba si laba din spate: stau pe sol si ridicat
        elif piece == "PawF":
            # talpa inchisa; dosul labei din fata are blana corpului: ridicat,
            # labele atarna in fata pieptului (pe decupare nu sunt „manusi")
            s = SHADE if n.z < 0.2 else TIP
        elif piece == "ForeF":
            s = SHADE if score < 0.36 else TIP
        if piece == "Head":
            if c.y - yoff > 1.265:
                s = DARK            # nasul
            elif c.y - yoff > 1.17 and n.z > -0.05:
                s = MUZZLE          # varful botului, mai deschis (suprafata mica)
            elif n.z < -0.70:
                s = SHADE           # sub barbie
            else:
                s = TIP
        slots.append(s)
    uv = me.uv_layers.new(name="UVMap")
    for p, s in zip(me.polygons, slots):
        for li in p.loop_indices:
            uv.data[li].uv = (slot_u(s), 0.5)
    zs = [v.co.z for v in me.vertices]
    z0, z1 = min(zs), max(zs)
    ao = me.color_attributes.new(name="AO", type="FLOAT_COLOR", domain="CORNER")
    for p in me.polygons:
        for li in p.loop_indices:
            z = me.vertices[me.loops[li].vertex_index].co.z
            t = max(0.0, min(1.0, (z - z0) / max(z1 - z0, 1e-6)))
            v = AO_FLOOR + (1.0 - AO_FLOOR) * t ** 0.7
            ao.data[li].color = (v, v, v, 1.0)
    me.color_attributes.active_color = ao
    me.materials.clear()
    me.materials.append(atlas_material())
    area = {}
    for p, s in zip(me.polygons, slots):
        area[s] = area.get(s, 0.0) + p.area
    tot = sum(area.values())
    print("  arie pe sloturi: " + ", ".join("%d=%.1f%%" % (k, 100 * v / tot)
                                            for k, v in sorted(area.items())))


# ----------------------------------------------------------------- schelet

def bones_spec():
    bones = [
        dict(name="Hips", head=(0, HIP_Y, HIP_Z), tail=(0, -0.35, HIP_Z + 0.04)),
        dict(name="Chest", head=CHEST_PIVOT, tail=(0, 0.60, 1.02), parent="Hips"),
        dict(name="Head", head=NECK, tail=(0, 1.30, 0.94), parent="Chest"),
    ]
    for side, sx in (("L", -1), ("R", 1)):
        fx, hx = sx * FRONT_X, sx * HIND_X
        bones += [
            dict(name="LegFU_" + side, head=(fx, SHO_Y, SHO_Z), tail=(fx, 0.42, 0.48), parent="Chest"),
            dict(name="LegFL_" + side, head=(fx, 0.42, 0.48), tail=(fx, 0.44, 0.14), parent="LegFU_" + side),
            dict(name="PawF_" + side, head=(fx, 0.44, 0.14), tail=(fx, 0.62, 0.05), parent="LegFL_" + side),
            dict(name="LegHU_" + side, head=(hx, HIP_Y, HIP_Z), tail=(hx, HIP_Y + 0.02, 0.48), parent="Hips"),
            dict(name="LegHL_" + side, head=(hx, HIP_Y + 0.02, 0.48), tail=(hx, HIP_Y - 0.04, 0.14), parent="LegHU_" + side),
            dict(name="PawH_" + side, head=(hx, HIP_Y - 0.04, 0.14), tail=(hx, HIP_Y + 0.18, 0.05), parent="LegHL_" + side),
        ]
    return bones


def rig(obj, b):
    off = Vector(OFFSET)
    spec = bones_spec()
    for bone in spec:
        bone["head"] = tuple(Vector(bone["head"]) + off)
        bone["tail"] = tuple(Vector(bone["tail"]) + off)
    arm = make_armature("BrownBear", spec, mesh=obj)
    groups = {}
    for i, name in enumerate(b.vert_bone):
        groups.setdefault(name, []).append(i)
    for name, idx in groups.items():
        vg = obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
        vg.add(idx, 1.0, "REPLACE")
    missing = {bb.name for bb in arm.data.bones} - set(groups)
    assert not missing, "oase fara varfuri: %r" % missing
    print("  varfuri pe oase:", {k: len(v) for k, v in sorted(groups.items())})
    return arm


# ----------------------------------------------------------------- animatie

def _rot(x=0.0, y=0.0, z=0.0):
    return (Matrix.Rotation(math.radians(z), 3, "Z")
            @ Matrix.Rotation(math.radians(y), 3, "Y")
            @ Matrix.Rotation(math.radians(x), 3, "X"))


def _apply(arm, pose, hips_dz=0.0):
    for pb in arm.pose.bones:
        rot, loc = pose.get(pb.name, (None, None))
        loc = Vector(loc) if loc is not None else Vector((0, 0, 0))
        if pb.name == "Hips":
            loc = loc + Vector((0, 0, hips_dz))
        pose_rotate(pb, rot if rot is not None else Matrix.Identity(3))
        pose_move(pb, loc)


def _min_z(obj):
    deps = bpy.context.evaluated_depsgraph_get()
    deps.update()
    ev = obj.evaluated_get(deps)
    me = ev.to_mesh()
    z = min((ev.matrix_world @ v.co).z for v in me.vertices)
    ev.to_mesh_clear()
    return z


def _ground(arm, obj, pose):
    """Cat trebuie ridicat/coborat Hips ca punctul cel mai de jos sa atinga
    solul (talpa din sprijin pe y = 0, nici infipta, nici in aer). Se masoara
    FARA actiune activa: cu o actiune pe armatura, evaluarea ar rescrie poza
    manuala cu fcurve-urile ei."""
    arm.animation_data.action = None
    _apply(arm, pose)
    return -_min_z(obj)


def _key_clip(arm, obj, name, keys):
    """Cheie pe TOATE oasele la fiecare cadru: un os necheiat intr-o actiune ar
    mosteni poza din actiunea anterioara in Godot (blend-ul dintre clipuri)."""
    solved = [(f, pose, _ground(arm, obj, pose)) for f, pose in keys]
    act = bpy.data.actions.new(name)
    arm.animation_data.action = act
    # Cadrele din cod sunt numerotate de la 1, dar cheile pleaca de la 0:
    # exportatorul glTF scrie timpul = cadru / fps, iar un clip care incepe la
    # 1/24 s ar sta un cadru pe loc la fiecare bucla (si Stand ar iesi 1,21 s,
    # peste telegraful de 1,2 s).
    for frame, pose, dz in solved:
        _apply(arm, pose, dz)
        for pb in arm.pose.bones:
            pb.keyframe_insert("rotation_quaternion", frame=frame - 1)
            pb.keyframe_insert("location", frame=frame - 1)
    print("  %s: corectie de sol pe chei: %s" % (
        name, ", ".join("f%d %+.3f" % (f, d) for f, _, d in solved)))


# Mersul: secventa laterala in patru timpi (HL, FL, HR, FR), ca la ursul real;
# fiecare laba e PE SOL 65% din ciclu, deci mereu sunt cel putin doua jos.
WALK_FRAMES = 28         # 1,167 s
WALK_DUTY = 0.65
WALK_REACH = 0.37        # laba se pune la +R in fata umarului/soldului, pleaca la -R
WALK_LIFT = {"F": 0.14, "H": 0.12}
WALK_PHASE = {"HL": 0.0, "FL": 0.25, "HR": 0.5, "FR": 0.75}
LEG_REST = {   # (umar/sold, cot/genunchi, incheietura) in (y, z), repaus
    "F": ((SHO_Y, SHO_Z), (0.42, 0.48), (0.44, 0.14)),
    "H": ((HIP_Y, HIP_Z), (HIP_Y + 0.02, 0.48), (HIP_Y - 0.04, 0.14)),
}


def _phi(dy, dz):
    """Unghiul unui segment fata de verticala-in-jos, pozitiv spre +Y (inainte):
    exact rotatia in jurul lui X care duce (0,0,-1) pe directia lui."""
    return math.degrees(math.atan2(dy, -dz))


def _ik(kind, shoulder_dz, target):
    """IK in doua segmente in planul sagital. Cotul/genunchiul iese IN FATA
    liniei umar-laba, deci segmentul de jos se strange inapoi (ca la un
    genunchi). Intoarce rotatiile locale (sus, jos) fata de repaus."""
    (sy, sz), (ey, ez), (wy, wz) = LEG_REST[kind]
    sz += shoulder_dz
    l1 = math.hypot(ey - LEG_REST[kind][0][0], ez - LEG_REST[kind][0][1])
    l2 = math.hypot(wy - ey, wz - ez)
    phi1_rest = _phi(ey - LEG_REST[kind][0][0], ez - LEG_REST[kind][0][1])
    phi2_rest = _phi(wy - ey, wz - ez)
    vy, vz = target[0] - sy, target[1] - sz
    d = max(abs(l1 - l2) + 1e-3, min(0.999 * (l1 + l2), math.hypot(vy, vz)))
    beta = _phi(vy, vz)
    alpha = math.degrees(math.acos(max(-1.0, min(1.0, (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)))))
    phi1 = beta + alpha
    ey2 = sy + l1 * math.sin(math.radians(phi1))
    ez2 = sz - l1 * math.cos(math.radians(phi1))
    phi2 = _phi(target[0] - ey2, target[1] - ez2)
    r1 = phi1 - phi1_rest
    r2 = (phi2 - phi2_rest) - r1
    return r1, r2


def _foot(tau):
    """Pozitia labei pe ciclu: (deplasare pe Y fata de repaus, ridicare, u-zbor
    sau None in sprijin). In sprijin laba merge inapoi LINIAR (viteza constanta
    = fara patinare); in zbor revine cu easing si urca pe un arc."""
    r = WALK_REACH
    if tau < WALK_DUTY:
        return r - 2 * r * tau / WALK_DUTY, 0.0, None
    u = (tau - WALK_DUTY) / (1 - WALK_DUTY)
    return -r + 2 * r * (0.5 - 0.5 * math.cos(math.pi * u)), math.sin(math.pi * u), u


def _need_drop(kind, dy):
    """Cat trebuie sa coboare umarul ca laba sa ajunga la `dy` pe sol."""
    (sy, sz), _, (wy, wz) = LEG_REST[kind]
    l1 = math.hypot(LEG_REST[kind][1][0] - sy, LEG_REST[kind][1][1] - sz)
    l2 = math.hypot(wy - LEG_REST[kind][1][0], wz - LEG_REST[kind][1][1])
    reach = 0.985 * (l1 + l2)
    h_rest = sz - wz
    y = (wy + dy) - sy
    return max(0.0, h_rest - math.sqrt(max(0.0, reach * reach - y * y)))


def walk_pose(t):
    """Pas greu: corpul coboara cu cat laba din sprijin e mai departe de
    verticala (greutatea „cade" pe fiecare pas), umerii se leagana dupa labele
    din fata, capul da din cap la fiecare pas din fata."""
    feet = {leg: _foot((t - ph) % 1.0) for leg, ph in WALK_PHASE.items()}
    drop = {"F": 0.0, "H": 0.0}
    for leg, (dy, lift, u) in feet.items():
        if u is None:
            kind = leg[0]
            drop[kind] = max(drop[kind], _need_drop(kind, dy))
    pose = {}
    pf = 2 * math.pi * (t - WALK_PHASE["FL"])
    ph = 2 * math.pi * (t - WALK_PHASE["HL"])
    pose["Hips"] = (_rot(y=-1.2 * math.sin(ph), z=1.5 * math.sin(ph)), Vector((0, 0, -drop["H"])))
    pose["Chest"] = (_rot(y=1.8 * math.sin(pf), z=-1.5 * math.sin(pf)),
                     Vector((0, 0, -(drop["F"] - drop["H"]))))
    pose["Head"] = (_rot(x=-4.0 + 3.5 * math.cos(2 * pf), z=-3.0 * math.sin(pf)), None)
    for leg, (dy, lift, u) in feet.items():
        kind, side = leg[0], leg[1]
        (sy, sz), _, (wy, wz) = LEG_REST[kind]
        target = (wy + dy, wz + WALK_LIFT[kind] * lift)
        r1, r2 = _ik(kind, -drop[kind], target)
        if u is None:
            paw = 0.0  # talpa plata pe sol
        elif kind == "F":
            paw = -50.0 * math.sin(math.pi * min(1.0, u / 0.7))  # laba atarna, apoi se intinde
        else:
            paw = -20.0 * math.sin(math.pi * u)  # calcaiul se ridica primul
        up, lo, pw = ("LegFU_", "LegFL_", "PawF_") if kind == "F" else ("LegHU_", "LegHL_", "PawH_")
        pose[up + side] = (_rot(x=r1), None)
        pose[lo + side] = (_rot(x=r2), None)
        pose[pw + side] = (_rot(x=paw - (r1 + r2)), None)
    return pose


def idle_pose(t):
    """Respira si adulmeca: pieptul se umfla (1 grad, cu umerii tinuti pe loc,
    ca labele din fata sa nu intre in sol), capul coboara spre iarba si se
    intoarce putin."""
    p = 2 * math.pi * t
    br = 1.0 * math.sin(p)
    # umarul e la ~0,70 m in fata pivotului pieptului: il tinem la aceeasi cota
    lift = -0.70 * math.sin(math.radians(br))
    sniff = -9.0 * (0.5 - 0.5 * math.cos(p))
    pose = {"Chest": (_rot(x=br), Vector((0, 0, lift))),
            "Head": (_rot(x=sniff - br, z=7.0 * math.sin(p)), None)}
    for side in ("L", "R"):
        pose["LegFU_" + side] = (_rot(x=-br), None)
    return pose


def stand_pose(s, crouch=0.0):
    """s = 0 in patru labe, 1 ridicat. `crouch` = pregatirea: capul coboara si
    adulmeca inainte de ridicare. NU se inclina corpul in jos: labele din fata
    ar intra in sol, iar corectia de sol ar ridica talpile din spate in aer."""
    hips = ST_HIPS * s
    chest = ST_CHEST * s
    body = hips + chest
    head = (ST_HEAD_TOTAL * s) - body - 10.0 * crouch
    arm = -body + ST_ARM * s
    fore = ST_FOREARM * s
    paw = ST_PAW * s - (ST_ARM * s + fore)
    pose = {
        "Hips": (_rot(x=hips), None),
        # spatele se intinde cand se ridica (coloana iese din arcuirea de patruped)
        "Chest": (_rot(x=chest), Vector((0, ST_STRETCH * s, 0))),
        # scufundat pe axa spatelui (in cadrul de repaus al pieptului = -Y)
        # rotatia pe Y-ul pieptului = in jurul verticalei cand ursul e ridicat
        "Head": (_rot(x=head, y=ST_HEAD_YAW * s), Vector((0, -ST_HEAD_SINK * s, -0.02 * s))),
    }
    for side, sgn in (("L", -1.0), ("R", 1.0)):
        # Z-ul local al bratului ~ -Y in lume cand pieptul e ridicat: +z duce
        # bratul spre +X, deci stangul primeste -ST_ABDUCT
        pose["LegFU_" + side] = (_rot(x=arm, z=sgn * ST_ABDUCT * s), None)
        pose["LegFL_" + side] = (_rot(x=fore), None)
        pose["PawF_" + side] = (_rot(x=paw), None)
        # picioarele din spate: aproape verticale, genunchiul usor indoit, talpa plata
        pose["LegHU_" + side] = (_rot(x=-hips + ST_KNEE * s), None)
        pose["LegHL_" + side] = (_rot(x=-2 * ST_KNEE * s), None)
        pose["PawH_" + side] = (_rot(x=ST_KNEE * s), None)
    return pose


IDLE_FRAMES = 48     # 2 s
STAND_FRAMES = 28    # 1,167 s (< telegraful de 1,2 s)


def animate(arm, obj):
    scene = bpy.context.scene
    scene.render.fps = FPS
    if arm.animation_data is None:
        arm.animation_data_create()
    _key_clip(arm, obj, "Idle", [(1 + int(round(k / 8.0 * IDLE_FRAMES)), idle_pose((k / 8.0) % 1.0))
                                 for k in range(9)])
    _key_clip(arm, obj, "Walk", [(1 + k, walk_pose((k / WALK_FRAMES) % 1.0))
                                 for k in range(WALK_FRAMES + 1)])
    # pregatire -> ridicare -> depasire mica -> poza tinuta
    _key_clip(arm, obj, "Stand", [(f, stand_pose(sv, cr)) for f, sv, cr in (
        (1, 0.0, 0.0), (6, 0.0, 1.0), (13, 0.45, 0.5),
        (20, 0.92, 0.0), (24, 1.03, 0.0), (STAND_FRAMES + 1, 1.0, 0.0))])


def measure(arm, obj, action, frames):
    """Gabaritul mesh-ului EVALUAT (cu scheletul aplicat) pe cadrele date."""
    arm.animation_data.action = bpy.data.actions[action]
    out = []
    deps = bpy.context.evaluated_depsgraph_get()
    for f in frames:
        bpy.context.scene.frame_set(f - 1)
        deps.update()
        ev = obj.evaluated_get(deps)
        me = ev.to_mesh()
        ws = [ev.matrix_world @ v.co for v in me.vertices]
        ev.to_mesh_clear()
        lo = Vector((min(w.x for w in ws), min(w.y for w in ws), min(w.z for w in ws)))
        hi = Vector((max(w.x for w in ws), max(w.y for w in ws), max(w.z for w in ws)))
        out.append((f, lo, hi))
    return out


def foot_speed(arm, obj, bone="PawF_L"):
    """Viteza naturala a ciclului Walk: cat de repede se duce laba din sprijin
    inapoi (m/s la ritm 1), doar intre cadre consecutive in care varful labei
    e pe sol. E cifra pentru WALK_CYCLE_SPEED_BY_MODEL."""
    arm.animation_data.action = bpy.data.actions["Walk"]
    pb = arm.pose.bones[bone]
    samples = []
    for f in range(1, WALK_FRAMES + 2):
        bpy.context.scene.frame_set(f - 1)
        bpy.context.view_layer.update()
        tip = arm.matrix_world @ pb.head  # incheietura: jos in sprijin, sus in zbor
        samples.append((f, tip.y, tip.z))
    z_floor = min(s[2] for s in samples)
    dy = dt = 0.0
    for (f0, y0, z0), (f1, y1, z1) in zip(samples, samples[1:]):
        if z0 < z_floor + 0.012 and z1 < z_floor + 0.012:
            dy += y0 - y1
            dt += (f1 - f0) / FPS
    lift = max(s[2] for s in samples) - z_floor
    return (dy / dt if dt else 0.0), dt * FPS, lift


def build():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)
    b = build_mesh()
    obj = make_object(b)
    paint(obj, b)
    arm = rig(obj, b)
    animate(arm, obj)

    # --- masuratori pe GLB-ul de dinainte de export (se repeta pe fisier)
    rest = measure(arm, obj, "Idle", [1])[0]
    lo, hi = rest[1], rest[2]
    print("  repaus (Idle f1): lung %.2f (Y), lat %.2f (X), inalt %.2f (Z); "
          "centru XY (%.3f, %.3f), baza %.3f"
          % (hi.y - lo.y, hi.x - lo.x, hi.z - lo.z, (lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    for f, l, h in measure(arm, obj, "Stand", [1, 13, 20, 24, 29]):
        print("  Stand f%-2d: inalt %.2f, baza %.3f, Y [%.2f, %.2f]" % (f, h.z - l.z, l.z, l.y, h.y))
    for f, l, h in measure(arm, obj, "Walk", [1, 5, 9, 13, 17, 21, 25, 29]):
        print("  Walk  f%-2d: inalt %.2f, baza %.3f" % (f, h.z - l.z, l.z))
    for bone in ("PawF_L", "PawH_R"):
        v, nf, lift = foot_speed(arm, obj, bone)
        print("  Walk %s: laba in sprijin %.2f m/s pe %d cadre, ridicata max %.2f m"
              % (bone, v, nf, lift))

    stash_actions(arm, ("Idle", "Walk", "Stand"))
    for pb in arm.pose.bones:
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)
    bpy.context.scene.frame_set(1)
    print("  tris:", tri_count(obj), "| oase:", len(arm.data.bones))
    return arm, obj


arm, obj = build()
path, size = export_glb([arm, obj], OUT, animations=True)
print("export: %s (%.0f KB)" % (path, size / 1024))
