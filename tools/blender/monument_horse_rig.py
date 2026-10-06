"""Monument Valley -- calul cu schelet si animatii (Walk, Idle).

Se executa din `build_monument_animals.py` (aceleasi globale: `build_horse`,
`leg_points`, `LEG_STAND`, `HOOF_H`, `Builder`, `finish`, `AO_ANIMAL`, ...).

CONTRACTUL cu jocul (cerut de dezvoltator: "caii doar gliseaza"):
  - GLB-ul pastreaza DOUA noduri-poza, ca inainte: `Pose_Stand` (static,
    folosit de caii de decor) si `Pose_Walk`. Cel de-al doilea e acum
    ARMATURA calului (nodul se numeste tot `Pose_Walk`, fiindca cele 4 markere
    `CalC1/C2/G1/G2` din Track19 il aleg cu `model_node = "Pose_Walk"`), cu
    mesh-ul skinnuit pe ea, in poza de STAND (picioare drepte).
  - Animatiile se numesc `Walk` si `Idle` (conventia SlidingHazard, vezi
    build_cow_animated.py). Gallop lipseste: caii traverseaza la 2 m/s.
  - Geometria, culorile (sloturile), scara, orientarea (fata = +Y in Blender)
    si ORIGINEA sunt cele vechi: offsetul de origine se calculeaza pe uniunea
    celor doua poze vechi (stand + walk), exact ca `emit`.

SCHELETUL (16 oase): Body (radacina), Neck, Head, Tail, si pe fiecare din cele
4 picioare Upper (sold/umar -> genunchi/jaret), Lower (genunchi -> varful
copitei, adica pasternul) si Hoof (copita; contra-rotita in stance ca sa ramana
PLATA pe sol, altfel calcaiul se ridica cand fluierul se inclina).

GREUTATI, pe INSULE (fiecare piesa Builder e o insula conexa), cu rampe unde
doua oase impart o piesa — altfel articulatia s-ar deschide:
  trunchi -> Body; gat/coama -> rampa Body->Neck la baza; cap/bot/urechi/ochi/
  smoc de frunte -> Head (capul are rampa Neck->Head la ceafa, ca sa nu se
  desprinda de gat); coada -> rampa Body->Tail la radacina;
  piciorul "top" (sold -> sub genunchi) -> trei oase: Body langa sold (rampa),
  Upper pe mijloc, Lower sub genunchi (rampa); "low" si copita -> Lower.
  Rampa de la genunchi se termina INAINTE de cusatura top/low, unde ambele
  insule sunt 100% Lower: cusatura e rigida, nu se desface.

MERSUL se calculeaza cu IK in planul YZ al piciorului (nu cu unghiuri
inghetate): talpa tinta sta pe sol si se misca cu viteza corpului in stance,
deci NU patineaza daca viteza reala = WALK_STRIDE_SPEED (1,5 m/s =
SlidingHazard.WALK_CYCLE_SPEED, iar jocul scaleaza ritmul cu viteza reala).
Mers in 4 timpi, secventa laterala: spate-stanga, fata-stanga, spate-dreapta,
fata-dreapta, la 1/4 de ciclu distanta.
"""

import math
import mathutils

WALK_FPS = 30
WALK_FRAMES = 24                       # 0,8 s / ciclu
WALK_STRIDE_SPEED = 1.5                # m/s la speed_scale 1 (WALK_CYCLE_SPEED)
WALK_STRIDE = WALK_STRIDE_SPEED * WALK_FRAMES / WALK_FPS    # 1,2 m / ciclu
STANCE_FRAC = 0.60                     # cat din ciclu sta talpa pe sol
# Picioarele de stand sunt INTINSE (lungimea = inaltimea soldului), deci un pas de
# +-0,36 m nu e atins fara sa ridice talpa de pe sol. In mers corpul coboara cu
# atat si genunchii se indoaie (ca la un cal adevarat, care nu merge cu
# picioarele blocate).
WALK_CROUCH = 0.07
SWING_LIFT = 0.11                      # inaltimea copitei la trecere (m)
IDLE_FRAMES = 90                       # 3 s

# (parte, os) in ordinea secventei laterale + faza la care incepe stance-ul.
LEG_PHASE = {("H", -1): 0.00, ("F", -1): 0.25, ("H", +1): 0.50, ("F", +1): 0.75}
SIDE_NAME = {-1: "L", +1: "R"}


# ---------------------------------------------------------------------------
# geometria picioarelor in poza de stand (aceeasi formula ca build_horse)
# ---------------------------------------------------------------------------

def _stand_leg(kind, s):
    """(hip, genunchi/jaret, talpa) in coordonatele de CONSTRUCTIE (pre-place)."""
    ang, _ = LEG_STAND[kind]
    if kind == "F":
        hip_y, hip_z, x, lens = 0.50, 1.08, s * 0.16, [0.50, 0.42, 0.12]
    else:
        hip_y, hip_z, x, lens = -0.70, 1.12, s * 0.17, [0.58, 0.42, 0.12]
    pts = leg_points(x, hip_y, hip_z, lens, ang, ground=HOOF_H)
    return pts[0], pts[1], pts[3], pts[2]


# ---------------------------------------------------------------------------
# clasificarea insulelor in piese
# ---------------------------------------------------------------------------

def _classify_islands(obj):
    """-> lista de (piesa, indici, lo, hi). Piese: trunk, neck, mane, head_part
    (cap/bot/ureche/ochi/frunte), tail, leg_top(kind,s), leg_low(kind,s),
    leg_hoof(kind,s). Cheia e geometria insulei, in coordonate pre-place."""
    out = []
    for isl in mesh_islands(obj):
        lo, hi = island_bbox(obj, isl)
        c = (lo + hi) * 0.5
        sz = hi - lo
        if abs(c.x) > 0.1 and c.z < 1.2:                     # picior
            kind = "F" if c.y > 0.0 else "H"
            s = 1 if c.x > 0.0 else -1
            if hi.z < 0.2:
                part = ("leg_hoof", kind, s)
            elif hi.z > 0.80:
                part = ("leg_top", kind, s)
            else:
                part = ("leg_low", kind, s)
        elif sz.y > 1.5:
            part = ("trunk",)
        elif c.y < -0.85 and abs(c.x) < 0.1:
            part = ("tail",)
        elif sz.z > 0.8 and sz.y > 0.6 and abs(c.x) < 0.02:
            part = ("neck",)
        elif sz.z > 0.5 and sz.y > 0.4 and c.x > 0.02:
            part = ("mane",)             # coama e decalata cu cx=0.06
        else:
            part = ("head_part",)
        if os.environ.get('RIG_DEBUG'):
            print('   isl', part, len(isl), tuple(round(x,2) for x in lo), tuple(round(x,2) for x in hi))
        out.append((part, isl, lo, hi))
    return out


def _smooth(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def _set_weights(obj, indices, fn):
    """fn(co) -> dict os -> greutate (suma 1)."""
    for i in indices:
        for bone, w in fn(obj.data.vertices[i].co).items():
            if w > 1e-5:
                vg = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
                vg.add([i], w, "REPLACE")


def _bones(place):
    """Lista de oase (spatiul placed)."""
    P = lambda v: Vector(v) + place
    bones = [
        dict(name="Body", head=P((0.0, -0.90, 1.25)), tail=P((0.0, 0.50, 1.25))),
        dict(name="Neck", head=P((0.0, 0.50, 1.38)), tail=P((0.0, 0.96, 1.97)),
             parent="Body"),
        dict(name="Head", head=P((0.0, 0.96, 1.97)), tail=P((0.0, 1.25, 1.47)),
             parent="Neck"),
        dict(name="Tail", head=P((0.0, -0.90, 1.46)), tail=P((0.0, -0.97, 0.52)),
             parent="Body"),
    ]
    for (kind, s) in LEG_PHASE:
        hip, knee, foot, _ = _stand_leg(kind, s)
        n = "%s_%s" % (kind, SIDE_NAME[s])
        bones.append(dict(name=n + "_Upper", head=P(hip), tail=P(knee), parent="Body"))
        bones.append(dict(name=n + "_Lower", head=P(knee), tail=P(foot),
                          parent=n + "_Upper"))
        bones.append(dict(name=n + "_Hoof", head=P(foot),
                          tail=P(foot - Vector((0.0, 0.0, 0.09))),
                          parent=n + "_Lower"))
    return bones


def _weigh(obj):
    """Vertex groups pe insule (coordonate pre-place). Intoarce numaratoarea."""
    counts = {}
    for part, isl, lo, hi in _classify_islands(obj):
        key = part[0] if len(part) == 1 else "%s_%s%s" % (part[0], part[1],
                                                          SIDE_NAME[part[2]])
        counts[key] = counts.get(key, 0) + 1
        name = part[0]
        if name == "trunk":
            _set_weights(obj, isl, lambda co: {"Body": 1.0})
        elif name in ("neck", "mane"):
            # Body (y<=0.50, in trunchi) -> Neck (y>=0.75), smoothstep.
            def f(co):
                w = _smooth((co.y - 0.50) / 0.25)
                return {"Body": 1.0 - w, "Neck": w}
            _set_weights(obj, isl, f)
        elif name == "head_part":
            # Capul propriu-zis: rampa Neck -> Head la ceafa (cusatura gat/cap
            # e la y=0.96-0.97). Urechile/ochii/frunta (y<0.97) stau pe Head
            # intregi: sunt lipite de cap, nu de gat.
            if hi.z - lo.z < 0.3 and hi.y - lo.y < 0.3:   # ureche/ochi/frunte/bot
                _set_weights(obj, isl, lambda co: {"Head": 1.0})
            else:
                # distanta proiectata pe axa capului, de la pivot (0,0.96,1.97)
                ax = Vector((1.255 - 0.96, 1.47 - 1.97)).normalized()
                def f(co, ax=ax):
                    t = (co.y - 0.96) * ax.x + (co.z - 1.97) * ax.y
                    w = _smooth(t / 0.12)
                    return {"Neck": 1.0 - w, "Head": w}
                _set_weights(obj, isl, f)
        elif name == "tail":
            def f(co):
                w = _smooth((1.46 - co.z) / 0.16)
                return {"Body": 1.0 - w, "Tail": w}
            _set_weights(obj, isl, f)
        else:
            kind, s = part[1], part[2]
            hip, knee, foot, _ = _stand_leg(kind, s)
            n = "%s_%s" % (kind, SIDE_NAME[s])
            if name == "leg_top":
                mid_z = hi.z - 0.0    # nefolosit; limitele vin din cote
                top_end = lo.z        # capatul de jos al insulei = cusatura
                def f(co, hip=hip, knee=knee, top_end=top_end, n=n):
                    wb = 1.0 - _smooth((hip.z - co.z) / 0.25)       # sold
                    # rampa genunchiului: de la 0.10 deasupra genunchiului pana
                    # la cusatura (unde top e 100% Lower, ca insula "low").
                    wl = _smooth((knee.z + 0.10 - co.z) /
                                 max(knee.z + 0.10 - top_end, 1e-4))
                    wl = min(wl, 1.0 - wb)
                    return {"Body": wb, n + "_Upper": 1.0 - wb - wl,
                            n + "_Lower": wl}
                _set_weights(obj, isl, f)
            elif name == "leg_hoof":
                _set_weights(obj, isl, lambda co, n=n: {n + "_Hoof": 1.0})
            else:
                # fluier+pastern: ultimii 8 cm (pana la cusatura cu copita)
                # trec in Hoof, ca pasternul sa se indoaie lin si copita sa
                # se poata contra-roti fara sa lase o crapatura.
                def f(co, foot=foot, n=n):
                    w = _smooth((foot.z + 0.08 - co.z) / 0.08)
                    return {n + "_Lower": 1.0 - w, n + "_Hoof": w}
                _set_weights(obj, isl, f)
    return counts


# ---------------------------------------------------------------------------
# IK planar 2 oase + animatia
# ---------------------------------------------------------------------------

def _phi(v):
    """Unghiul unui vector (y, z) in planul YZ; rotatia pozitiva in jurul lui
    X creste acest unghi (y -> z), deci un picior in jos se duce INAINTE."""
    return math.atan2(v[1], v[0])


def _wrap(a):
    while a > math.pi:
        a -= 2 * math.pi
    while a < -math.pi:
        a += 2 * math.pi
    return a


class _LegIK:
    """Doua oase in planul YZ al armaturii (coordonate placed)."""

    def __init__(self, kind, s, place):
        hip, knee, foot, _ = _stand_leg(kind, s)
        self.kind, self.s = kind, s
        self.hip = (hip.y + place.y, hip.z + place.z)
        self.knee = (knee.y + place.y, knee.z + place.z)
        self.foot = (foot.y + place.y, foot.z + place.z)
        self.u0 = (self.knee[0] - self.hip[0], self.knee[1] - self.hip[1])
        self.l0 = (self.foot[0] - self.knee[0], self.foot[1] - self.knee[1])
        self.L1 = math.hypot(*self.u0)
        self.L2 = math.hypot(*self.l0)
        self.bend = +1.0 if kind == "F" else -1.0   # genunchi inainte / jaret inapoi

    def solve(self, dy, dz, bob):
        """Talpa tinta = talpa de repaus + (dy, dz); corpul (si soldul) urca cu
        `bob`. -> (unghi Upper, unghi Lower relativ la Upper), radiani."""
        hip = (self.hip[0], self.hip[1] + bob)
        T = (self.foot[0] + dy, self.foot[1] + dz)
        d = (T[0] - hip[0], T[1] - hip[1])
        dist = math.hypot(*d)
        reach = self.L1 + self.L2 - 1e-3
        if dist > reach:                      # inextensibil: talpa se ridica un pic
            d = (d[0] * reach / dist, d[1] * reach / dist)
            dist = reach
            T = (hip[0] + d[0], hip[1] + d[1])
        cos_a = (self.L1 ** 2 + dist ** 2 - self.L2 ** 2) / (2 * self.L1 * dist)
        alpha = math.acos(max(-1.0, min(1.0, cos_a)))
        base = math.atan2(d[1], d[0])
        up_dir = base + self.bend * alpha
        K = (hip[0] + math.cos(up_dir) * self.L1, hip[1] + math.sin(up_dir) * self.L1)
        low_dir = math.atan2(T[1] - K[1], T[0] - K[0])
        th_u = _wrap(up_dir - _phi(self.u0))
        th_l_abs = _wrap(low_dir - _phi(self.l0))
        return th_u, _wrap(th_l_abs - th_u)


def _foot_path(p):
    """p in [0,1) (0 = atingerea solului). -> (dy, dz) fata de talpa de repaus."""
    D = WALK_STRIDE * STANCE_FRAC
    if p < STANCE_FRAC:
        return D * 0.5 - D * (p / STANCE_FRAC), 0.0
    u = (p - STANCE_FRAC) / (1.0 - STANCE_FRAC)
    s = u * u * (3.0 - 2.0 * u)
    return -D * 0.5 + D * s, SWING_LIFT * math.sin(math.pi * u) ** 0.85


def _rotx(deg_or_rad_rad):
    return mathutils.Matrix.Rotation(deg_or_rad_rad, 3, "X")


def _rot(x=0.0, y=0.0, z=0.0):
    """grade."""
    return (mathutils.Matrix.Rotation(math.radians(z), 3, "Z")
            @ mathutils.Matrix.Rotation(math.radians(y), 3, "Y")
            @ mathutils.Matrix.Rotation(math.radians(x), 3, "X"))


def _key(pb, frame, rot=None, move=None):
    if rot is not None:
        pose_rotate(pb, rot)
        pb.keyframe_insert("rotation_quaternion", frame=frame)
    if move is not None:
        pose_move(pb, move)
        pb.keyframe_insert("location", frame=frame)


def _animate_horse(arm, place):
    scene = bpy.context.scene
    scene.render.fps = WALK_FPS
    if arm.animation_data is None:
        arm.animation_data_create()
    pbs = arm.pose.bones
    legs = {k: _LegIK(k[0], k[1], place) for k in LEG_PHASE}

    # ---- WALK -----------------------------------------------------------
    walk = bpy.data.actions.new("Walk")
    arm.animation_data.action = walk
    for fr in range(WALK_FRAMES + 1):
        t = (fr / WALK_FRAMES)                       # 0..1, ultimul = primul
        bob = -WALK_CROUCH + 0.012 * math.sin(2 * math.pi * 2 * t + 0.6)   # 2 ghionturi / ciclu
        _key(pbs["Body"], fr + 1, rot=_rot(x=0.8 * math.sin(2 * math.pi * 2 * t),
                                           y=1.2 * math.sin(2 * math.pi * t)),
             move=Vector((0.0, 0.0, bob)))
        for key, ik in legs.items():
            p = (t - LEG_PHASE[key]) % 1.0
            dy, dz = _foot_path(p)
            th_u, th_l = ik.solve(dy, dz, bob)
            n = "%s_%s" % (key[0], SIDE_NAME[key[1]])
            _key(pbs[n + "_Upper"], fr + 1, rot=_rotx(th_u))
            _key(pbs[n + "_Lower"], fr + 1, rot=_rotx(th_l))
            # copita: plata pe sol in stance (rotatie absoluta 0), urmeaza
            # fluierul in zbor (varful atarna) -- g: 0 la sol, 1 la jumatatea
            # fazei de zbor.
            if p < STANCE_FRAC:
                g = 0.0
            else:
                g = math.sin(math.pi * (p - STANCE_FRAC) / (1.0 - STANCE_FRAC)) ** 0.6
            _key(pbs[n + "_Hoof"], fr + 1, rot=_rotx(-(th_u + th_l) * (1.0 - g)))
        # capul se leagana o data pe ciclu (calul isi "da" capul la mers)
        _key(pbs["Neck"], fr + 1, rot=_rot(x=2.5 * math.sin(2 * math.pi * t + 1.2)))
        _key(pbs["Head"], fr + 1, rot=_rot(x=-2.0 * math.sin(2 * math.pi * t + 1.9)))
        _key(pbs["Tail"], fr + 1, rot=_rot(x=3.0 * math.sin(2 * math.pi * t),
                                           y=7.0 * math.sin(2 * math.pi * t + 0.8)))
    walk.use_fake_user = True

    # ---- IDLE -----------------------------------------------------------
    idle = bpy.data.actions.new("Idle")
    arm.animation_data.action = idle
    for fr in range(0, IDLE_FRAMES + 1, 3):
        t = fr / IDLE_FRAMES
        w = 2 * math.pi * t
        _key(pbs["Body"], fr + 1, rot=_rot(x=0.5 * math.sin(w)),
             move=Vector((0.0, 0.0, 0.005 * math.sin(w))))        # respiratia
        _key(pbs["Neck"], fr + 1, rot=_rot(x=-5.0 - 4.0 * math.sin(w - 0.4),
                                           z=4.0 * math.sin(2 * w)))
        _key(pbs["Head"], fr + 1, rot=_rot(x=-3.0 * math.sin(w + 0.5),
                                           z=3.0 * math.sin(2 * w + 1.0)))
        _key(pbs["Tail"], fr + 1, rot=_rot(x=3.0 * math.sin(2 * w),
                                           y=12.0 * math.sin(2 * w + 0.3)))
        for key in LEG_PHASE:        # picioarele raman in stand (rotatii zero)
            n = "%s_%s" % (key[0], SIDE_NAME[key[1]])
            _key(pbs[n + "_Upper"], fr + 1, rot=_rotx(0.0))
            _key(pbs[n + "_Lower"], fr + 1, rot=_rotx(0.0))
            _key(pbs[n + "_Hoof"], fr + 1, rot=_rotx(0.0))
    idle.use_fake_user = True

    stash_actions(arm, ("Walk", "Idle"))
    for pb in arm.pose.bones:                       # poza de repaus in fisier
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)


# ---------------------------------------------------------------------------
# emisia: Pose_Stand (static) + Pose_Walk (armatura + mesh skinnuit)
# ---------------------------------------------------------------------------

def emit_horse_rigged(path, coat, ao, budget=None):
    """Inlocuieste `emit` pentru cai. Intoarce numarul de triunghiuri."""
    clear_built()
    # `clear_built` sterge doar mesh-uri: armaturile si actiunile calului
    # anterior (aceeasi sesiune, 3 culori) ar sufixa numele (`Pose_Walk.001`,
    # `Walk.001`) si GLB-ul ar iesi cu noduri/animatii redenumite.
    for o in list(bpy.data.objects):
        if o.type == "ARMATURE":
            bpy.data.objects.remove(o, do_unlink=True)
    for ad in list(bpy.data.armatures):
        bpy.data.armatures.remove(ad)
    for act in list(bpy.data.actions):
        bpy.data.actions.remove(act)
    stand = build_horse(coat, "stand").to_object("Pose_Stand")
    walk_old = build_horse(coat, "walk").to_object("Pose_Walk_old")
    # Offsetul de origine: XY pe uniunea CELOR DOUA poze vechi (centrul ramane unde
    # era), dar Z pe poza STAND: ea e cea exportata, iar talpa trebuie sa ating solul
    # (verify_glb: 'ansamblul nu atinge solul'). Poza veche de mers cobora cu 2,7 cm
    # mai jos decat stand-ul, deci tot ansamblul coboara cu 2,7 cm fata de inainte.
    xs, ys, zs = [], [], []
    for o in (stand, walk_old):
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y)
    zs = [v.co.z for v in stand.data.vertices]
    place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5,
                    -min(zs)))
    bpy.data.objects.remove(walk_old, do_unlink=True)

    # Mesh-ul skinnuit = copie a pozei Stand; greutatile se pun INAINTE de
    # place/finish (indici de varfuri, coordonate de constructie).
    rig_mesh = stand.copy()
    rig_mesh.data = stand.data.copy()
    rig_mesh.name = "Pose_Walk_Mesh"
    bpy.context.collection.objects.link(rig_mesh)
    counts = _weigh(rig_mesh)
    expect = {"trunk": 1, "tail": 1, "neck": 1, "mane": 1, "head_part": 7}
    for k, v in expect.items():
        assert counts.get(k) == v, "insule %s: %r" % (k, counts)
    assert sum(1 for k in counts if k.startswith("leg_top")) == 4, counts
    assert sum(1 for k in counts if k.startswith("leg_low")) == 4, counts
    assert sum(1 for k in counts if k.startswith("leg_hoof")) == 4, counts
    print("  insule pe piese:", counts)

    total = 0
    for o in (stand, rig_mesh):
        nv = len(o.data.vertices)
        for v in o.data.vertices:
            v.co += place
        st = finish(o, bevel=0.0, ao=ao, origin=None, smooth_angle=None)
        assert len(o.data.vertices) == nv, "finish a schimbat numarul de varfuri"
        total += st["tris"]

    arm = make_armature("Pose_Walk", _bones(place), mesh=rig_mesh)
    # make_armature pune si modificatorul; fiecare varf trebuie sa aiba greutati.
    for v in rig_mesh.data.vertices:
        assert len(v.groups) > 0, "varf fara greutati"
    _animate_horse(arm, place)
    bpy.context.view_layer.update()

    xs, ys, zs = [], [], []
    for v in stand.data.vertices:
        xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb([stand, arm, rig_mesh], "monumentvalley/" + path,
                       animations=True)
    RESULTS.append((path, total, dims, budget,
                    {"Pose_Stand": total // 2, "Pose_Walk(rig)": total // 2},
                    sz / 1024.0))
    return total
