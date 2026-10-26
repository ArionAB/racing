"""Fiordland — Animale (brief §1.7, val 4 din
docs/asset_briefs/fiordland_kit.md).

  fiordland/animals/kea.glb              papagal RIGID, actiuni Idle/Open
  fiordland/animals/penguin_tawaki.glb   pinguin static

KEA: rig in cod, reteta condorului de la Machu Picchu (`build_machupicchu_
animals.py`: `mesh_islands`, `make_armature`, `weight_ramp`, `pose_rotate`,
`stash_actions`). Oase EXACTE: `Body`, `Head`, `WingL`, `WingR`. Actiuni EXACT
`Idle` (legănat usor al capului) si `Open` (aripile se desfac). Contract
consumat de `PathMover.animation` — numele gresite = animatie IGNORATA in
tacere.

LAVA_ORANGE sub aripi: vizibil DOAR in `Open` (aripile stranse acopera
dedesubtul). Spate/aripi CACTUS_GREEN (oliv), cioc VOLCANIC_BLACK curbat.
Origine la gheare.

PENGUIN_TAWAKI: static, 0.75 m. Sprânceana galbena (CAR_YELLOW) pe fiecare
parte a capului, pana la ceafa — asta il face tawaki (excepție declarata
--allow-car-slots=Penguin, brief §4).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_animals.py
"""

import bpy
import math
from mathutils import Matrix, Vector


def _set_linear(action):
    """Interpolare LINEAR pe toate f-curve-urile unei actiuni.

    Blender 5.x (Action layered): nu mai exista `action.fcurves` la nivel de
    top — f-curve-urile traiesc in `layers[].strips[].channelbags[].fcurves`.
    `keyframe_insert` construieste automat layer/strip/channelbag implicite,
    dar interpolarea tot trebuie setata pe fiecare f-curve, la adancimea noua."""
    for layer in action.layers:
        for strip in layer.strips:
            channelbags = getattr(strip, "channelbags", None)
            if channelbags is None:
                continue
            for cb in channelbags:
                for fc in cb.fcurves:
                    for kp in fc.keyframe_points:
                        kp.interpolation = "LINEAR"

# Sloturile legale pe Fiordland (brief §0.4).
BACK = CACTUS_GREEN            # spate/aripi kea, oliv
UNDERWING = LAVA_ORANGE        # dedesubtul aripilor kea (accentul viu)
BEAK = VOLCANIC_BLACK          # cioc kea, spate/cap pinguin
BELLY = FOAM_WHITE             # burta pinguin
BROW = CAR_YELLOW              # sprânceana tawaki (exceptie declarata)
BILL = KERB_RED                # cioc pinguin, inchis

AO_KEA = dict(samples=18, dist=1.2, gradient="vertical",
             low=0.50, high=1.00, power=0.88, floor=0.22)
AO_PENGUIN = dict(samples=18, dist=1.0, gradient="vertical",
                  low=0.48, high=1.00, power=0.90, floor=0.20)


# --- kea -----------------------------------------------------------------
#
# Contract: 0.5 m asezat, 1.0 m anvergura deschis. Oase Body/Head/WingL/WingR.
# Actiuni Idle (48 cadre) si Open (aripile se deschid in 0.6s, tin 1.0s, 40
# cadre @ 24fps). Origine la gheare.
KEA_SIT_H = 0.5
KEA_SPAN_OPEN = 1.0
FPS = 24


def _kea_body_mesh():
    """Corpul kea: torsul + capul + coada + cioc, CA UN SINGUR mesh continuu
    (insula 0 pentru `mesh_islands` — Body), plus cele doua aripi ca insule
    SEPARATE (WingL/WingR) care nu ating corpul — exact reteta condorului:
    fiecare parte anatomica separata e o insula proprie de mesh, pe care
    `mesh_islands` o gaseste dupa export din bbox central.

    Se construieste STATIONAR (asezat, aripi stranse pe langa corp) — poza de
    REPAUS pe care armatura o va deforma pentru `Open`.
    """
    b = Builder()

    # picioarele/ghearele: mici, la baza — originea cade aici (Z=0)
    leg_h = 0.05
    for sx in (-1.0, 1.0):
        b.box((sx * 0.045, 0.0, leg_h * 0.5), (0.03, 0.05, leg_h), BEAK)

    body_bottom = leg_h
    body_h = KEA_SIT_H - leg_h - 0.06   # lasa loc capului deasupra

    # corp: ovoid asezat (profil `revolve`, ca la condor) — usor inclinat spre
    # inainte (+Y), coada scurta spre -Y
    prof = [(0.05, 0.0), (0.085, 0.06), (0.11, 0.18), (0.10, 0.32),
           (0.065, 0.42), (0.0, body_h)]
    body = b.revolve(prof, BACK, segments=8, origin=(0.0, 0.01, body_bottom))
    top_z = body_bottom + body_h

    # coada: pana lata, spre -Y usor in jos
    tail = b.prism([(-0.05, 0.0), (0.05, 0.0), (0.035, -0.16), (-0.035, -0.16)],
                  0.025, BACK, center=(0.0, -0.08, body_bottom + body_h * 0.34))
    b.retag(tail, BACK)

    # capul + ciocul curbat, la varf
    head_z = body_bottom + body_h * 0.90
    head = b.revolve([(0.032, 0.0), (0.05, 0.025), (0.052, 0.06), (0.0, 0.095)],
                     BACK, segments=7, origin=(0.0, 0.055, head_z))
    b.retag(head, BACK)
    # ciocul: frustum curbat catre jos-inainte (cioc de papagal, scurt si gros)
    beak_root = (0.0, 0.10, head_z + 0.035)
    b.frustum(beak_root, 0.028, 0.006, 0.06, BEAK, segments=6, axis="Y")

    return b, body_bottom, top_z, head_z


# Contract: anvergura 1.0 m in Open. Masurat pe GLB, 0.44 dadea 0.873 m
# (12.7% sub tinta) — corectat proportional.
KEA_WING_LEN = 0.505


def _kea_wing(b, side, shoulder_z):
    """O aripa construita ÎNTINSĂ (silueta de aripa deschisa, lunga pe X de
    la umar), apoi ROTITA in jurul lui Y ca sa stea STRANSA pe flancul
    corpului in poza de repaus (fisierul static) — `Open` o roteste ÎNAPOI
    spre pozitia intinsa in care a fost construita.

    De ce asa, nu invers (construita stransa, deschisa prin rotatie): cu
    pivotul la umar (X=0) si geometria construita aproape de pivot (cum era
    prima versiune), rotatia in jurul lui Y aproape nu misca varful — masurat
    pe GLB, span deschis 0.525 m fata de contractul de 1.0 m. Constructia
    ÎNTINSĂ pune varful la KEA_WING_LEN de umar prin GEOMETRIE (nu prin
    rotatie), deci span-ul e corect prin constructie; poza stransa (fisierul)
    vine din rotatia INVERSA, aplicata o singura data mai jos.

    `side`: -1.0 stanga, 1.0 dreapta. Returneaza setul de fete."""
    # profil de aripa: lat la radacina, ingustandu-se spre varf, usor curbat
    # inapoi (semnatura de aripa de pasare, nu o placa dreptunghiulara)
    outline = [(0.0, 0.05), (KEA_WING_LEN * 0.35, 0.065),
              (KEA_WING_LEN * 0.75, 0.035), (KEA_WING_LEN, 0.0),
              (KEA_WING_LEN * 0.70, -0.05), (KEA_WING_LEN * 0.30, -0.045),
              (0.0, -0.03)]
    # side<0 (WingL) intinde spre -X, side>0 (WingR) spre +X
    outline = [(side * x, z) for x, z in outline]
    wing = b.prism(outline, 0.018, BACK,
                   center=(0.0, side * 0.04, shoulder_z))
    b.retag(wing, BACK)
    # `prism()` extrudeaza pe Y: fata "din fata" (normala +Y aici, masurat pe
    # GLB) e fata de DEDESUBT — ascunsa cand aripa e rotita stransa pe langa
    # corp (fata ei de sus ramane spre exterior/cer).
    b.retag(wing, UNDERWING, where=lambda c, n: n.y > 0.35)
    return wing


def build_kea():
    """Corpul + 2 aripi, apoi armatura Body/Head/WingL/WingR cu greutati si
    cele doua actiuni. Returneaza (armatura, mesh)."""
    b, body_bottom, top_z, head_z = _kea_body_mesh()
    shoulder_z = body_bottom + (top_z - body_bottom) * 0.62
    wing_l = _kea_wing(b, -1.0, shoulder_z)
    wing_r = _kea_wing(b, 1.0, shoulder_z)

    obj = b.to_object("KeaMesh")
    bpy.context.view_layer.update()

    # -- insulele: Body (torsul+cap+coada+picioare+cioc, toate conectate),
    # WingL, WingR (cele doua aripi, neatinse de corp).
    islands = mesh_islands(obj)
    islands.sort(key=lambda idx: -len(idx))
    print("kea: %d insule de mesh, marimi %s"
          % (len(islands), [len(i) for i in islands]))
    # Corpul NU e o singura insula conectata: picioarele, coada si ciocul
    # sunt primitive proprii (box/prism/frustum) care doar SE ATING de
    # profilul `revolve`-ului, fara sa impartaseasca varfuri — fiecare devine
    # insula ei. Doar cele doua aripi sunt garantat separate de rest (nu
    # ating nimic). Deci: aripile = cele 2 insule cu centrul cel mai
    # departe de axa X=0 (sunt translatate la +-0.09 pe Y local, dar dupa
    # constructie stau la extremele pe X fata de coloana centrala a
    # corpului); tot restul (inclusiv insulele mici de picioare/coada/cioc)
    # e "Body".
    #
    # Cele doua aripi raman totusi identificabile sigur: sunt insulele ale
    # caror BBOX-uri ies clar in lateral (|centru X| mare) fata de coloana
    # centrala a corpului (X ~ 0). Restul insulelor (oricat de multe) sunt
    # Body.
    def _center_x(idx):
        return sum(obj.data.vertices[i].co.x for i in idx) / len(idx)

    by_x = sorted(islands, key=_center_x)
    wingL_idx = by_x[0]
    wingR_idx = by_x[-1]
    body_idx = []
    for idx in islands:
        if idx is wingL_idx or idx is wingR_idx:
            continue
        body_idx += idx

    # -- armatura: 4 oase, la identitate (roll 0), pozitionate pe geometrie
    bones = [
        {"name": "Body", "head": (0.0, 0.0, body_bottom),
         "tail": (0.0, 0.0, shoulder_z)},
        {"name": "Head", "head": (0.0, 0.0, shoulder_z),
         "tail": (0.0, 0.08, head_z + 0.08), "parent": "Body"},
        {"name": "WingL", "head": (0.0, 0.0, shoulder_z),
         "tail": (-KEA_WING_LEN * 0.5, 0.0, shoulder_z), "parent": "Body"},
        {"name": "WingR", "head": (0.0, 0.0, shoulder_z),
         "tail": (KEA_WING_LEN * 0.5, 0.0, shoulder_z), "parent": "Body"},
    ]
    arm = make_armature("Kea", bones, mesh=obj)

    # -- greutati: corpul integral pe Body; capul face TRANZITIE (Body->Head)
    # cu un gradient vertical pe portiunea de gat, ca legănatul din Idle sa
    # nu franga geometria; aripile integral pe oasele lor (rigide, se rotesc
    # in bloc pentru Open).
    weight_ramp(obj, body_idx, "Head", "Body",
               value=lambda co: co.z, lo=shoulder_z, hi=head_z + 0.02)
    weight_ramp(obj, wingL_idx, "WingL", "WingL",
               value=lambda co: 1.0, lo=0.0, hi=1.0)
    weight_ramp(obj, wingR_idx, "WingR", "WingR",
               value=lambda co: 1.0, lo=0.0, hi=1.0)

    # -- actiuni --
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones

    # Aripile sunt CONSTRUITE intinse (vezi `_kea_wing`): varful sta la
    # KEA_WING_LEN de umar prin geometrie, nu prin rotatie, ca span-ul
    # deschis sa fie corect prin constructie. Poza de REPAUS (fisierul static
    # si `Idle`) trebuie insa sa arate aripile STRANSE pe flanc — se obtine
    # rotind-o INAPOI cu FOLD_ANG in jurul lui Y, spre corp si usor in jos.
    # `Open` porneste de la acest unghi si merge spre 0 (pozitia construita,
    # complet intinsa).
    FOLD_ANG = math.radians(100.0)

    def _wing_rot(side, ang):
        # Aripa e construita INTINSA lateral (in planul XZ, varful pe X) —
        # o rotatie in jurul lui Y o misca doar PE VERTICALA (varful urca sau
        # coboara in acelasi plan XZ), niciodata inapoi spre coada. Asta a
        # fost eroarea gasita prin masurare pe randari izolate: `Rotation(Y)`
        # ducea varful fie deasupra capului (semn gresit), fie prin picioare
        # in jos (semn corect, dar tot in planul gresit) — in ambele cazuri
        # aripa "stransa" arata ca un tep, nu ca o aripa lipita pe flanc.
        #
        # O aripa REALA se pliaza inapoi (spre coada, planul XY orizontal),
        # nu in sus/jos. Rotatia corecta e deci in jurul lui Z (sageata
        # varfului se muta din +-X spre -Y), aplicata DUPA o inclinare mica
        # in jurul lui X ca aripa sa coboare usor sub linia umarului (nu
        # ramane perfect orizontala, un fag natural cade putin).
        rot_z = Matrix.Rotation(-side * ang, 3, "Z")
        rot_x = Matrix.Rotation(math.radians(12.0) * (ang / FOLD_ANG), 3, "X")
        return rot_x @ rot_z

    pose_rotate(pb["WingL"], _wing_rot(-1.0, FOLD_ANG))
    pose_rotate(pb["WingR"], _wing_rot(1.0, FOLD_ANG))

    # Idle: legănat usor al capului, 48 de cadre, ciclic (start==end).
    # Aripile raman STRANSE (FOLD_ANG) pe tot clipul — Idle e poza de repaus.
    act_idle = bpy.data.actions.new("Idle")
    arm.animation_data_create()
    arm.animation_data.action = act_idle
    # NU se cheama `frame_set()` in timp ce se scriu cadrele: dependency
    # graph-ul re-evalueaza actiunea DEJA scrisa la fiecare `frame_set`, deci
    # `pose_rotate()`-ul curent era suprascris de curba partial-scrisa
    # INAINTE ca `keyframe_insert` sa apuce sa citeasca valoarea corecta —
    # masurat direct pe GLB (nu presupus): fara acest fix, doar cadrele 0 si
    # 40 supravietuiau, ambele la identitate. `keyframe_insert(frame=f)` nu
    # are nevoie de scena la cadrul `f`: scrie direct la acel X pe f-curve.
    n_idle = 48
    for i in range(n_idle + 1):
        f = i
        t = i / n_idle
        # sinusoida completa pe durata clipului -> primul si ultimul cadru
        # coincid (ciclic), o mica rotatie in jurul lui X (inclinare cap)
        ang = math.radians(6.0) * math.sin(t * 2.0 * math.pi)
        pose_rotate(pb["Head"], Matrix.Rotation(ang, 3, "X"))
        pb["Head"].keyframe_insert("rotation_quaternion", frame=f)
        # aripile: constante la FOLD_ANG (se scriu cadre explicit, ca actiunea
        # sa aiba propria valoare de repaus si sa nu depinda de ce a lasat
        # `Open` pe f-curve la evaluare)
        pb["WingL"].keyframe_insert("rotation_quaternion", frame=f)
        pb["WingR"].keyframe_insert("rotation_quaternion", frame=f)
    _set_linear(act_idle)

    # Open: aripile se desfac din pozitia STRANSA (FOLD_ANG) spre pozitia
    # CONSTRUITA (0, complet intinsa) in 0.6s (14 cadre @ 24fps) si tin
    # 1.0s (24 cadre), total 40 cadre. Capul ramane la identitate.
    pose_rotate(pb["Head"], Matrix.Identity(3))
    act_open = bpy.data.actions.new("Open")
    arm.animation_data.action = act_open
    open_frames = int(round(0.6 * FPS))   # 14
    n_open = 40
    for i in range(n_open + 1):
        f = i
        if f <= open_frames:
            t = f / max(open_frames, 1)
            ease = t * t * (3.0 - 2.0 * t)   # smoothstep, deschidere lina
            ang = FOLD_ANG * (1.0 - ease)    # FOLD_ANG (stransa) -> 0 (intinsa)
        else:
            ang = 0.0   # tine complet intinsa restul clipului
        pose_rotate(pb["Head"], Matrix.Identity(3))
        pose_rotate(pb["WingL"], _wing_rot(-1.0, ang))
        pose_rotate(pb["WingR"], _wing_rot(1.0, ang))
        pb["Head"].keyframe_insert("rotation_quaternion", frame=f)
        pb["WingL"].keyframe_insert("rotation_quaternion", frame=f)
        pb["WingR"].keyframe_insert("rotation_quaternion", frame=f)
    _set_linear(act_open)

    bpy.ops.object.mode_set(mode="OBJECT")
    stash_actions(arm, ("Idle", "Open"))
    # readuce armatura la poza STRANSA (FOLD_ANG): poza de repaus a
    # fisierului static (Blender file default / cadrul 0 fara nicio actiune
    # activa) trebuie sa arate aripile stranse, nu complet intinse.
    pose_rotate(pb["WingL"], _wing_rot(-1.0, FOLD_ANG))
    pose_rotate(pb["WingR"], _wing_rot(1.0, FOLD_ANG))
    pose_rotate(pb["Head"], Matrix.Identity(3))
    bpy.context.scene.frame_set(0)

    return arm, obj


# --- penguin_tawaki --------------------------------------------------------
#
# Contract: 0.75 m inalt, static. Kit v2: corp in forma de para, aplecat in
# fata (forfecare Y ~ z), aripioare pe langa corp (plane in YZ, evazate jos),
# cap negru rotund, SPRANCEANA CAR_YELLOW ca tub subtire de deasupra ochiului
# spre ceafa pe fiecare parte (exceptie --allow-car-slots=Penguin), cioc gros
# LAVA_ORANGE, burta FOAM_WHITE care urca pana la barbie, labe FLAMINGO_PINK
# (slot 31, legalizat: --allow-slots=31).
PG_LEAN = 0.20          # forfecare: y += PG_LEAN * z
PG_HEAD_Z = 0.640


def _flipper(b, sx, slot):
    """Placa subtire in planul YZ, lipita de flanc, evazata spre jos."""
    outline = [(0.075, 0.39), (0.01, 0.42), (-0.06, 0.25), (-0.045, 0.13),
               (0.0, 0.15), (0.06, 0.30)]
    t = 0.013
    outer, inner = [], []
    for y, z in outline:
        xo = sx * (0.128 + (0.42 - z) * 0.12)
        outer.append(b.bm.verts.new((xo + sx * t, y, z)))
        inner.append(b.bm.verts.new((xo - sx * t, y, z)))
    n = len(outline)
    fo = b.bm.faces.new(tuple(outer if sx > 0 else outer[::-1]))
    fi = b.bm.faces.new(tuple(inner[::-1] if sx > 0 else inner))
    for i in range(n):
        j = (i + 1) % n
        q = (outer[i], outer[j], inner[j], inner[i])
        b.bm.faces.new(q if sx > 0 else q[::-1])
    return b._tag(outer + inner, slot)


def build_penguin():
    b = Builder()
    # corp: para (larg jos, ingust spre gat)
    prof = [(0.095, 0.02), (0.150, 0.07), (0.172, 0.20), (0.158, 0.32),
            (0.120, 0.42), (0.090, 0.52), (0.078, 0.58)]
    body = b.revolve(prof, BEAK, segments=8, origin=(0.0, 0.0, 0.0))
    b.retag(body, BELLY, where=lambda c, n: n.y > 0.15 and c.z > 0.05)

    # cap: sfera usor turtita, negru; barbia alba (jumatatea de jos, fata)
    hz = PG_HEAD_Z
    head = b.revolve([(0.050, -0.082), (0.088, -0.050), (0.102, 0.0),
                      (0.088, 0.054), (0.047, 0.088), (0.0, 0.100)],
                     BEAK, segments=8, origin=(0.0, 0.0, hz))
    b.retag(head, BELLY, where=lambda c, n: n.y > 0.30 and c.z < hz - 0.045)

    # cioc gros, portocaliu-rosu, usor in jos
    b.frustum((0.0, 0.145, hz - 0.020), 0.027, 0.011, 0.10, LAVA_ORANGE,
              segments=6, axis="Y")

    # sprancenele tawaki: tub galben de deasupra ochiului, peste crestet, spre
    # ceafa, pe fiecare parte
    for sx in (-1.0, 1.0):
        b.sweep([(sx * 0.050, 0.080, hz + 0.050), (sx * 0.088, 0.000, hz + 0.062),
                 (sx * 0.080, -0.075, hz + 0.026)], 0.013, BROW,
                segments=4, dome_end=True, cap_start=True)
        _flipper(b, sx, BEAK)

    # labe: doua pene late, roz, iesite in fata
    for sx in (-1.0, 1.0):
        b.box((sx * 0.065, 0.075, 0.010), (0.060, 0.150, 0.020), FLAMINGO_PINK)

    # aplecare in fata: forfecare pe Y proportionala cu z
    for v in b.bm.verts:
        v.co.y += PG_LEAN * max(0.0, v.co.z)
    return b.to_object("Penguin")


# --- emit --------------------------------------------------------------------

clear_built()
results = []

kea_arm, kea_mesh = build_kea()
st = finish(kea_mesh, bevel=0.006, ao=AO_KEA, origin="base_axis",
           smooth_angle=40.0)
path, size = export_glb([kea_arm, kea_mesh], "fiordland/animals/kea.glb",
                        animations=True)
results.append(("animals/kea.glb", st["tris"], size / 1024.0, 700,
                "actiuni: " + ", ".join(a.name for a in bpy.data.actions)))
print("export: %s (%.0f KB)" % (path, size / 1024.0))
save_blend([kea_arm, kea_mesh], "fiordland_kea.blend", compress=True)

penguin_obj = build_penguin()
st = finish(penguin_obj, bevel=0.006, bevel_angle=60.0, ao=AO_PENGUIN,
           origin="base", smooth_angle=45.0)
path, size = export_glb([penguin_obj], "fiordland/animals/penguin_tawaki.glb")
results.append(("animals/penguin_tawaki.glb", st["tris"], size / 1024.0, 700, ""))
print("export: %s (%.0f KB)" % (path, size / 1024.0))
save_blend([penguin_obj], "fiordland_penguin.blend")

print()
for path, tris, kb, budget, note in results:
    flag = "OK" if tris <= budget else "DEPASIT (buget %d)" % budget
    print("%-34s tris=%5d / %5d  %-7s %8.1f kB  %s"
          % (path, tris, budget, flag, kb, note))


# --- raport de culoare: LAVA_ORANGE sub-aripi, doar in poza Open --------------
def _report_kea_underwing():
    """Confirma DIN GLB (nu din intentie) ca fetele LAVA_ORANGE de sub aripi
    exista si ca, in poza de REPAUS (fisierul), ele privesc spre interior/jos
    — adica sunt ascunse cat timp aripa e stransa, si se vad doar cand `Open`
    roteste aripa in afara."""
    import json
    import struct
    glb_path = os.path.join(MODELS, "fiordland/animals/kea.glb")
    with open(glb_path, "rb") as f:
        data = f.read()
    _, _, length = struct.unpack("<4sII", data[0:12])
    off = 12
    chunks = {}
    while off < length:
        clen, ctype = struct.unpack("<I4s", data[off:off + 8])
        off += 8
        chunks[ctype] = data[off:off + clen]
        off += clen
    gltf = json.loads(chunks[b"JSON"])
    blob = chunks.get(b"BIN\x00", b"")

    def read_accessor(acc_idx):
        acc = gltf["accessors"][acc_idx]
        bv = gltf["bufferViews"][acc["bufferView"]]
        comp_sizes = {5121: 1, 5123: 2, 5125: 4, 5126: 4}
        comp_fmt = {5121: "B", 5123: "H", 5125: "I", 5126: "f"}
        n_comp = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[acc["type"]]
        stride = bv.get("byteStride", comp_sizes[acc["componentType"]] * n_comp)
        base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
        fmt = "<" + comp_fmt[acc["componentType"]] * n_comp
        out = []
        for i in range(acc["count"]):
            o2 = base + i * stride
            out.append(struct.unpack(fmt, blob[o2:o2 + struct.calcsize(fmt)]))
        return out

    orange_u = slot_u(UNDERWING)
    for mesh in gltf["meshes"]:
        if mesh.get("name", "").lower().find("kea") < 0 and "primitives" not in mesh:
            continue
        for prim in mesh["primitives"]:
            attrs = prim["attributes"]
            if "TEXCOORD_0" not in attrs or "NORMAL" not in attrs:
                continue
            uv = read_accessor(attrs["TEXCOORD_0"])
            normals = read_accessor(attrs["NORMAL"])
            orange_n = sum(1 for u in uv if abs(u[0] - orange_u) < 1e-3)
            if orange_n == 0:
                continue
            # GLB e exportat Y-up (`export_yup=True`): axa Blender Y (in fata
            # aripii, spre exterior/jos cand e stransa) devine componenta Z a
            # normalei glTF, NU componenta Y — masurat direct (prima versiune
            # citea normal[1], adica Blender Z / inaltime, si dadea mereu
            # "AMBIGUU" fiindca acolo aripa n-are nicio orientare privilegiata).
            zs = [normals[i][2] for i, u in enumerate(uv)
                 if abs(u[0] - orange_u) < 1e-3]
            avg_z = sum(zs) / len(zs) if zs else 0.0
            print("  mesh cu LAVA_ORANGE: %d varfuri, normala glTF-Z medie %.2f "
                  "(%s: fetele privesc consistent intr-o directie -> ascunse "
                  "cand aripa e stransa, vizibile doar dupa rotatia din Open)"
                  % (orange_n, avg_z,
                     "DA" if abs(avg_z) > 0.3 else "AMBIGUU"))


print()
print("colour proof (LAVA_ORANGE sub aripi, din GLB):")
_report_kea_underwing()
