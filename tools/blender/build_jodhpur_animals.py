"""Jodhpur -- animalele, val 4 grupa B (brief §1.6, docs/asset_briefs/jodhpur_kit.md).

  jodhpur/animals/zebu_cow.glb         vaca zebu, RIG + Stand/LieDown/Lie/GetUp/Walk
  jodhpur/animals/black_kite_bird.glb  uliul negru, RIG + Fly (32 cadre, bucla)
  jodhpur/animals/peacock_closed.glb   paunul cu trena stransa, static
  jodhpur/animals/peacock_fanned.glb   paunul cu evantaiul deschis, static
  jodhpur/animals/langur.glb           maimuta langur asezata, static

Toate din primitivele `Builder` (tuburi cu raza variabila, elipsoizi, placi),
FARA bevel: o piesa Builder = o insula, iar fiecare insula poarta in atributul
de fata `part` osul pe care il urmeaza. Asa greutatile nu se ghicesc dupa
pozitie (capcana elefantului din Serengeti, memoria
`elefant-mesh-importat-rig-per-vertex`): se scriu la constructie.

AO pe piesele animate: DOAR gradient vertical (`strength=0`), ca la vaca
Quaternius -- un AO copt prin raycast ar picta umbre lipite de blana care
raman pe loc cand scheletul se misca (memoria `asset-animat-pipeline`).

Axe: capul spre +Y in Blender (= -Z in Godot). Rotatiile de poza sunt in
spatiul armaturii (`pose_rotate`): R_x(+a) duce un picior care atarna (-Z)
spre +Y, adica INAINTE; R_y(+a) ridica varful aripii STANGI (-X).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_jodhpur_animals.py
"""

import math
from mathutils import Matrix, Vector

FPS = 24

# AO pe piesele cu schelet: gradient vertical bland, fara ocluzie geometrica.
AO_RIG = dict(samples=4, dist=0.5, gradient="vertical", low=0.70, high=1.00,
              power=0.8, floor=0.45, strength=0.0)
# AO pe piesele statice: raycast real, moderat (animalele sunt netede pe
# plansa, un AO dur le-ar murdari).
AO_STATIC = dict(samples=16, dist=0.6, gradient="vertical", low=0.72,
                 high=1.00, power=0.8, floor=0.40, strength=0.55)

results = []


# ---------------------------------------------------------------------------
# Unelte comune
# ---------------------------------------------------------------------------

def new_builder():
    """Builder cu un al doilea strat de fata, `part`: indicele intrarii din
    `b.parts` (os, os-radacina, functie de rampa) al fiecarei primitive."""
    b = Builder()
    b.part = b.bm.faces.layers.int.new("part")
    b.parts = []
    return b


def bone(b, faces, name, root=None, fn=None, lo=0.0, hi=1.0):
    """Leaga fetele unei primitive de un os. Cu `fn`, greutatea curge de la
    `root` (fn <= lo) la `name` (fn >= hi) -- `dio_lib.weight_ramp`."""
    idx = len(b.parts)
    b.parts.append((name, root or name, fn, lo, hi))
    for f in faces:
        f[b.part] = idx
    return faces


def xform(faces, mat, pivot=(0.0, 0.0, 0.0), offset=(0.0, 0.0, 0.0)):
    """Roteste (Matrix 3x3) varfurile unei primitive in jurul lui `pivot`,
    apoi le muta cu `offset`."""
    pv = Vector(pivot)
    off = Vector(offset)
    for v in {v for f in faces for v in f.verts}:
        v.co = pv + mat @ (v.co - pv) + off
    return faces


def scale_axis(faces, axis, k, about=0.0):
    for v in {v for f in faces for v in f.verts}:
        v.co[axis] = about + (v.co[axis] - about) * k
    return faces


def rot(x=0.0, y=0.0, z=0.0):
    """Rotatie in grade, aplicata X apoi Y apoi Z (in axele lumii)."""
    return (Matrix.Rotation(math.radians(z), 3, "Z")
            @ Matrix.Rotation(math.radians(y), 3, "Y")
            @ Matrix.Rotation(math.radians(x), 3, "X"))


def ell(b, c, size, slot, seg=8, rings=5, r=None):
    """Elipsoid inchis (boulder fara perturbatie), optional rotit."""
    faces = b.boulder(c, size, slot, seed=0, segments=seg, rings=rings,
                      deviation=0.0)
    if r is not None:
        xform(faces, r, pivot=c)
    return faces


def disc(b, c, normal, r, depth, slot, seg=10, squash=1.0):
    """Disc (cilindru scurt) cu axa pe `normal`. `squash` < 1 il face oval."""
    faces = b.cylinder((0, 0, 0), r, depth, slot, segments=seg)
    if squash != 1.0:
        scale_axis(faces, 1, squash)
    q = Vector((0, 0, 1)).rotation_difference(Vector(normal).normalized())
    return xform(faces, q.to_matrix(), offset=c)


def plate(b, outline, tvec, slot):
    """Placa groasa dintr-un contur 3D plan; grosimea e vectorul `tvec`."""
    t = Vector(tvec) * 0.5
    lo = [b.bm.verts.new(Vector(p) - t) for p in outline]
    hi = [b.bm.verts.new(Vector(p) + t) for p in outline]
    b.bm.faces.new(hi)
    b.bm.faces.new(list(reversed(lo)))
    n = len(outline)
    for i in range(n):
        j = (i + 1) % n
        b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    return b._tag(lo + hi, slot)


def shell(b, fn, ni, nj, thick, slot):
    """Suprafata-grila cu grosime: `fn(i, j) -> (punct, normala)`, i pe
    [0, ni], j pe [0, nj]. Fata, spatele si cele patru margini."""
    front, back = {}, {}
    for i in range(ni + 1):
        for j in range(nj + 1):
            p, n = fn(i, j)
            p, n = Vector(p), Vector(n).normalized()
            front[i, j] = b.bm.verts.new(p + n * thick * 0.5)
            back[i, j] = b.bm.verts.new(p - n * thick * 0.5)
    for i in range(ni):
        for j in range(nj):
            b.bm.faces.new((front[i, j], front[i + 1, j],
                            front[i + 1, j + 1], front[i, j + 1]))
            b.bm.faces.new((back[i, j + 1], back[i + 1, j + 1],
                            back[i + 1, j], back[i, j]))
    rim = ([(i, 0) for i in range(ni)] + [(ni, j) for j in range(nj)]
           + [(i, nj) for i in range(ni, 0, -1)] + [(0, j) for j in range(nj, 0, -1)])
    for k in range(len(rim)):
        a, c = rim[k], rim[(k + 1) % len(rim)]
        b.bm.faces.new((front[a], back[a], back[c], front[c]))
    return b._tag(list(front.values()) + list(back.values()), slot)


def to_obj(b, name):
    return b.to_object(name)


def all_bbox(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for v in o.data.vertices:
            lo = Vector(map(min, lo, v.co))
            hi = Vector(map(max, hi, v.co))
    return lo, hi


def place_offset(objs, mode):
    """Offsetul de origine, calculat O DATA pe ansamblu (memoria
    `finish-recentreaza-fiecare-nod-separat`)."""
    lo, hi = all_bbox(objs)
    c = (lo + hi) * 0.5
    if mode == "center":
        return -c
    return Vector((-c.x, -c.y, -lo.z))


def finish_all(objs, mode, ao, smooth=48.0):
    """finish fara bevel si fara origine per nod, apoi offsetul comun."""
    off = place_offset(objs, mode)
    tris = 0
    for o in objs:
        for v in o.data.vertices:
            v.co += off
    lo, hi = all_bbox(objs)
    ao = dict(ao)
    if ao.get("gradient") == "vertical":
        ao["z_range"] = (lo.z, hi.z)
    for o in objs:
        st = finish(o, bevel=0.0, ao=ao, origin=None, smooth_angle=smooth)
        tris += st["tris"]
    return off, tris


def part_indices(obj):
    """{index de part: [varfuri]} din atributul de fata `part`."""
    attr = obj.data.attributes.get("part")
    out = {}
    for poly in obj.data.polygons:
        k = attr.data[poly.index].value
        out.setdefault(k, set()).update(poly.vertices)
    return out


def skin(obj, parts, off):
    """Greutatile din `parts` (scrise la constructie). Functiile de rampa
    primesc coordonate CONSTRUITE (scadem offsetul de origine)."""
    for k, idx in part_indices(obj).items():
        name, root, fn, lo, hi = parts[k]
        value = None
        if fn is not None:
            value = (lambda f: (lambda co: f(co - off)))(fn)
        weight_ramp(obj, sorted(idx), name, root, value, lo, hi)
    obj.data.attributes.remove(obj.data.attributes["part"])


def drop_part_attr(obj):
    a = obj.data.attributes.get("part")
    if a is not None:
        obj.data.attributes.remove(a)


def key_pose(arm, frame, pose, bones):
    """Cheie pe TOATE oasele (implicit identitate): Godot nu reseteaza
    pistele lipsa intre clipuri -- un os necheiat in `Stand` ar ramane indoit
    cum l-a lasat `Lie`."""
    for name in bones:
        pb = arm.pose.bones[name]
        ops = pose.get(name, [])
        if not isinstance(ops, list):
            ops = [ops]
        r = Matrix.Identity(3)
        mv = Vector((0, 0, 0))
        for kind, val in ops:
            if kind == "rot":
                r = val
            else:
                mv = Vector(val)
        pose_rotate(pb, r)
        pose_move(pb, mv)
        # cadrele se numara de la 1 in cod, dar cheia se pune la frame-1: un
        # clip care incepe la 1 iese in glTF cu un cadru mort la t=0 (masurat
        # in Godot: Fly 1.375 s in loc de 1.333), adica o sacadare la bucla
        pb.keyframe_insert("rotation_quaternion", frame=frame - 1)
        pb.keyframe_insert("location", frame=frame - 1)


def reset_pose(arm):
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)


def report(path, objs, tris):
    lo, hi = all_bbox(objs)
    d = hi - lo
    results.append((path, tris, d))
    print("  %-34s %5d tri  X %.2f  Y %.2f  Z %.2f   (y %.2f..%.2f z %.2f..%.2f)"
          % (path, tris, d.x, d.y, d.z, lo.y, hi.y, lo.z, hi.z))


# ===========================================================================
# 1. VACA ZEBU
# ===========================================================================
#
# Cote (constructie, inainte de centrare): botul la y ~ +1.38, crupa la
# y ~ -1.24, smocul cozii la ~ -1.36. Cocoasa 1.50 m, spinarea 1.32 m.

COW_BODY = FOAM_WHITE
COW_DARK = VOLCANIC_BLACK
COW_HORN = LAVA_ORANGE
COW_GARLAND = LAVA_ORANGE
COW_UDDER = FLAMINGO_PINK

FRONT_Y, REAR_Y = 0.50, -0.82
LEG_X = 0.165
SHOULDER_Z = 0.92      # articulatia umarului (sus pe picior)
HIP_Z = 0.98


def cow_mesh():
    """Vaca zebu IN PICIOARE (poza de repaus). Lista de elemente, citita pe
    `zebu_cow_stand.png` (§0.1 pasul 1), inainte de primul varf:

      - corp ALB, lung; spinarea dreapta care coboara usor spre crupa;
        crupa unghiulara (soldurile ies), coapsele pline
      - COCOASA clara deasupra umerilor (1), cel mai inalt punct al corpului
      - 4 picioare subtiri, ALBE, copite NEGRE (4); piciorul din spate cu
        jaretul indoit inapoi, cel din fata drept
      - cap alungit, fata inclinata in jos-inainte (~60 grade), BOT NEGRU,
        ochi negri (2), urechi ORIZONTALE, laterale, sub coarne (2)
      - COARNE PORTOCALII (2): groase la baza, urca din crestet, se deschid
        in afara si se intorc cu varfurile spre interior (lira); cam 1/4 din
        inaltimea la greaban
      - GHIRLANDA de galbenele portocalie: bucla de la ceafa, pe gat, pana
        in piept, unde atarna CLOPOTELUL GALBEN (1)
      - SALBA (pielea de sub gat), intre gat si piept, partial sub ghirlanda
      - uger ROZ mic intre picioarele din spate
      - COADA subtire, atarna de la crupa, SMOC NEGRU la capat, la inaltimea
        jaretului
    """
    b = new_builder()     # corpul
    bb = new_builder()    # clopotelul (nod separat, exceptia de slot)

    # --- trunchiul: tub pe Y, turtit lateral -------------------------------
    body = b.taper_sweep(
        [(0, -1.22, 1.05), (0, -1.08, 1.02), (0, -0.70, 0.97), (0, -0.20, 0.95),
         (0, 0.30, 1.02), (0, 0.62, 1.03), (0, 0.80, 1.05)],
        [0.12, 0.30, 0.38, 0.41, 0.40, 0.34, 0.18], COW_BODY, segments=10)
    scale_axis(body, 0, 0.80)
    bone(b, body, "Body")
    # soldurile / crupa unghiulara
    bone(b, ell(b, (0, -0.88, 1.13), (0.50, 0.52, 0.34), COW_BODY), "Body")
    # pieptul si umerii, mai adanci decat burta
    bone(b, ell(b, (0, 0.56, 0.98), (0.54, 0.58, 0.70), COW_BODY), "Body")
    # COCOASA peste umeri, inclinata spre spate
    bone(b, ell(b, (0, 0.40, 1.24), (0.36, 0.70, 0.52), COW_BODY,
                r=rot(x=-14)), "Body")
    # ugerul
    bone(b, ell(b, (0, -0.55, 0.57), (0.24, 0.26, 0.16), COW_UDDER, seg=8, rings=4),
         "Body")

    # --- gatul (rampa Body -> Neck) ----------------------------------------
    neck = b.taper_sweep([(0, 0.62, 1.12), (0, 0.86, 1.22), (0, 1.02, 1.32),
                          (0, 1.10, 1.38)],
                         [0.24, 0.20, 0.16, 0.13], COW_BODY, segments=10)
    scale_axis(neck, 0, 0.85)
    bone(b, neck, "Neck", "Body", lambda co: co.y, 0.66, 0.90)

    # SALBA: placa atarnata sub gat, de la gat pana in piept
    dew = plate(b, [(0, 1.02, 1.12), (0, 0.98, 0.98), (0, 0.90, 0.86),
                    (0, 0.78, 0.76), (0, 0.66, 0.72), (0, 0.66, 0.92),
                    (0, 0.84, 1.10)], (0.09, 0, 0), COW_BODY)
    bone(b, dew, "Neck", "Body", lambda co: co.y, 0.70, 0.95)

    # --- capul -------------------------------------------------------------
    head = b.taper_sweep([(0, 1.06, 1.44), (0, 1.14, 1.36), (0, 1.23, 1.18),
                          (0, 1.29, 1.04), (0, 1.31, 0.98)],
                         [0.13, 0.15, 0.125, 0.10, 0.06], COW_BODY, segments=8)
    bone(b, head, "Head")
    bone(b, ell(b, (0, 1.31, 0.99), (0.21, 0.15, 0.14), COW_DARK, seg=8, rings=4),
         "Head")                                             # bot
    for sx in (-1, 1):
        bone(b, ell(b, (sx * 0.135, 1.20, 1.30), (0.045, 0.06, 0.05), COW_DARK,
                    seg=6, rings=3), "Head")                 # ochi
        # urechea: lob orizontal, lateral, usor lasat
        bone(b, ell(b, (sx * 0.25, 1.10, 1.35), (0.30, 0.09, 0.14), COW_BODY,
                    seg=6, rings=4, r=rot(y=sx * 14)), "Head")
        # CORNUL: gros la baza, lira (afara, apoi varful spre interior)
        bone(b, b.taper_sweep(
            [(sx * 0.09, 1.07, 1.46), (sx * 0.24, 1.04, 1.52),
             (sx * 0.33, 1.04, 1.64), (sx * 0.31, 1.07, 1.78),
             (sx * 0.20, 1.11, 1.88)],
            [0.08, 0.068, 0.052, 0.033, 0.0], COW_HORN, segments=8), "Head")

    # --- ghirlanda (margele pe o bucla in jurul gatului) ------------------
    # Bucla: sus la ceafa (dupa coarne), jos in piept, unde atarna clopotelul.
    top = Vector((0, 0.96, 1.46))
    bot = Vector((0, 0.92, 0.88))
    mid = (top + bot) * 0.5
    axis = (top - bot) * 0.5
    n_beads = 24
    for k in range(n_beads):
        t = 2.0 * math.pi * k / n_beads
        # latimea buclei urmeaza gatul: mai lata jos (piept), mai stransa sus
        half_w = 0.18 + 0.06 * (1.0 - math.cos(t)) * 0.5
        p = mid + axis * math.cos(t) + Vector((half_w * math.sin(t), 0, 0))
        # bucla se lipeste de fata gatului: jos iese in fata pieptului
        p.y += 0.10 * (1.0 - math.cos(t)) * 0.5
        bone(b, ell(b, tuple(p), (0.13, 0.13, 0.12), COW_GARLAND,
                    seg=6, rings=3), "Neck")
    # CLOPOTELUL: nod separat "Bell", pe CAR_YELLOW (exceptie declarata)
    bell_top = bot + Vector((0, 0.10, -0.03))
    bone(bb, bb.cylinder(tuple(bell_top + Vector((0, 0, -0.03))), 0.015, 0.07,
                         CAR_YELLOW, segments=6), "Neck")
    bone(bb, bb.revolve([(0.080, -0.25), (0.088, -0.22), (0.068, -0.15),
                         (0.052, -0.09), (0.030, -0.06), (0.0, -0.05)],
                        CAR_YELLOW, segments=10, origin=tuple(bell_top)), "Neck")

    # --- picioarele ----------------------------------------------------------
    for sx in (-1, 1):
        side = "L" if sx < 0 else "R"
        x = sx * LEG_X
        # FATA: antebrat (rampa din corp), fluier + copita pe Shin
        bone(b, b.taper_sweep([(x, FRONT_Y, 0.98), (x, FRONT_Y + 0.01, 0.66),
                               (x, FRONT_Y + 0.02, 0.44)],
                              [0.13, 0.10, 0.075], COW_BODY, segments=8),
             "LegF" + side, "Body", lambda co: -co.z, -0.95, -0.82)
        bone(b, b.taper_sweep([(x, FRONT_Y + 0.02, 0.46), (x, FRONT_Y + 0.03, 0.14),
                               (x, FRONT_Y + 0.04, 0.09)],
                              [0.07, 0.058, 0.06], COW_BODY, segments=8),
             "ShinF" + side)
        bone(b, b.frustum((x, FRONT_Y + 0.05, 0.05), 0.075, 0.062, 0.10,
                          COW_DARK, segments=8), "ShinF" + side)
        # SPATE: coapsa plina (rampa), gamba spre jaretul dus inapoi
        xr = sx * (LEG_X + 0.01)
        bone(b, ell(b, (xr, REAR_Y, 0.88), (0.24, 0.46, 0.56), COW_BODY,
                    r=rot(x=12)),
             "LegR" + side, "Body", lambda co: -co.z, -1.00, -0.72)
        bone(b, b.taper_sweep([(xr, REAR_Y + 0.02, 0.80), (xr, REAR_Y - 0.08, 0.62),
                               (xr, REAR_Y - 0.14, 0.46)],
                              [0.12, 0.09, 0.07], COW_BODY, segments=8),
             "LegR" + side)
        bone(b, b.taper_sweep([(xr, REAR_Y - 0.14, 0.48), (xr, REAR_Y - 0.08, 0.14),
                               (xr, REAR_Y - 0.07, 0.09)],
                              [0.065, 0.056, 0.058], COW_BODY, segments=8),
             "ShinR" + side)
        bone(b, b.frustum((xr, REAR_Y - 0.06, 0.05), 0.072, 0.06, 0.10,
                          COW_DARK, segments=8), "ShinR" + side)

    # --- coada ---------------------------------------------------------------
    bone(b, b.taper_sweep([(0, -1.16, 1.24), (0, -1.27, 1.18), (0, -1.31, 0.98),
                           (0, -1.31, 0.72), (0, -1.30, 0.58)],
                          [0.045, 0.035, 0.028, 0.024, 0.02], COW_BODY, segments=6),
         "Tail", "Body", lambda co: -co.y, 1.16, 1.26)
    bone(b, ell(b, (0, -1.30, 0.50), (0.10, 0.10, 0.24), COW_DARK, seg=6, rings=4),
         "Tail")

    return b, bb


def cow_bones(P):
    """Scheletul: 13 oase. Body (radacina) sta pe crupa -> greaban, ca
    tangajul "in genunchi" sa pivoteze pe solduri, cum se culca o vaca."""
    bones = [
        dict(name="Body", head=P(0, REAR_Y, HIP_Z), tail=P(0, 0.55, 1.02)),
        dict(name="Neck", parent="Body", head=P(0, 0.62, 1.14), tail=P(0, 1.06, 1.38)),
        dict(name="Head", parent="Neck", head=P(0, 1.08, 1.40), tail=P(0, 1.32, 0.98)),
        dict(name="Tail", parent="Body", head=P(0, -1.18, 1.24), tail=P(0, -1.30, 0.50)),
    ]
    for sx, side in ((-1, "L"), (1, "R")):
        x = sx * LEG_X
        xr = sx * (LEG_X + 0.01)
        bones += [
            dict(name="LegF" + side, parent="Body",
                 head=P(x, FRONT_Y, SHOULDER_Z), tail=P(x, FRONT_Y + 0.02, 0.45)),
            dict(name="ShinF" + side, parent="LegF" + side,
                 head=P(x, FRONT_Y + 0.02, 0.45), tail=P(x, FRONT_Y + 0.05, 0.0)),
            dict(name="LegR" + side, parent="Body",
                 head=P(xr, REAR_Y, HIP_Z - 0.10), tail=P(xr, REAR_Y - 0.14, 0.47)),
            dict(name="ShinR" + side, parent="LegR" + side,
                 head=P(xr, REAR_Y - 0.14, 0.47), tail=P(xr, REAR_Y - 0.06, 0.0)),
        ]
    return bones


COW_BONES = ["Body", "Neck", "Head", "Tail", "LegFL", "ShinFL", "LegRL",
             "ShinRL", "LegFR", "ShinFR", "LegRR", "ShinRR"]


def _legs(fl, fr, rl, rr):
    """(upper, lower[, splay]) per picior, unghiuri de tangaj LOCALE in grade."""
    out = {}
    for tag, spec in (("FL", fl), ("FR", fr), ("RL", rl), ("RR", rr)):
        up, low = spec[0], spec[1]
        splay = spec[2] if len(spec) > 2 else 0.0
        sgn = 1.0 if tag.endswith("L") else -1.0
        kind = "LegF" if tag[0] == "F" else "LegR"
        shin = "ShinF" if tag[0] == "F" else "ShinR"
        out[kind + tag[1]] = ("rot", rot(x=up, y=sgn * splay))
        out[shin + tag[1]] = ("rot", rot(x=low))
    return out


def cow_pose_stand():
    return {}


def cow_pose_kneel():
    """Primul timp al culcarii: genunchii din fata la pamant, crupa inca sus
    (vaca se lasa intai in fata). Body pivoteaza pe solduri."""
    p = {"Body": ("rot", rot(x=-17))}
    # antebratul ramane vertical in lume (+17 anuleaza tangajul corpului),
    # fluierul se pliaza inapoi pe sol
    p.update(_legs((17, -88), (17, -88), (17, 0), (17, 0)))
    p["Neck"] = ("rot", rot(x=-10))
    return p


def cow_pose_half():
    """Al doilea timp: crupa coboara, picioarele din spate se strang."""
    p = {"Body": [("rot", rot(x=-6)), ("move", (0, 0, -0.38))]}
    p.update(_legs((55, -150), (55, -150), (40, -110, 8), (40, -110, 8)))
    p["Neck"] = ("rot", rot(x=-4))
    p["Tail"] = ("rot", rot(x=-20))
    return p


def cow_pose_lie():
    """Culcata, ca pe `zebu_cow_lie.png`: burta pe sol, antebratele stranse
    sub piept (genunchii in fata, fluierele pliate inapoi), picioarele din
    spate stranse lateral cu copitele iesind in spate, capul SUS, coada pe
    sol in spate."""
    p = {"Body": ("move", (0, 0, -0.60))}
    p.update(_legs((58, -150), (58, -150), (72, -168, 16), (72, -168, 16)))
    p["Neck"] = ("rot", rot(x=14))
    p["Head"] = ("rot", rot(x=-6))
    p["Tail"] = ("rot", rot(x=-22, z=40))
    return p


def cow_animate(arm):
    scene = bpy.context.scene
    scene.render.fps = FPS
    if arm.animation_data is None:
        arm.animation_data_create()

    def action(name):
        act = bpy.data.actions.new(name)
        arm.animation_data.action = act
        return act

    # STAND (2 s, bucla): coada alunga mustele, capul se intoarce putin.
    action("Stand")
    for f in range(1, 50, 4):
        t = (f - 1) / 48.0
        s = math.sin(math.tau * t)
        key_pose(arm, f, {
            "Tail": ("rot", rot(x=-4 * s, y=12 * math.sin(math.tau * t * 2))),
            "Head": ("rot", rot(z=5 * s, x=2 * math.sin(math.tau * t * 2))),
            "Neck": ("rot", rot(x=1.5 * s)),
        }, COW_BONES)

    # WALK (1 s, bucla): pas in doi timpi diagonali (reteta magarului).
    action("Walk")
    phase = {"FL": 0.0, "RR": 0.0, "FR": 180.0, "RL": 180.0}

    def leg_at(ph):
        t = (ph % 360.0) / 360.0
        if t < 0.6:
            u = t / 0.6
            return 15.0 - 30.0 * u, 2.0 + 4.0 * u
        u = (t - 0.6) / 0.4
        return -15.0 + 30.0 * u, 6.0 + 30.0 * math.sin(math.pi * u)

    for f in range(1, 26, 3):
        t = (f - 1) / 24.0
        pose = {}
        for tag, ph in phase.items():
            sw, kn = leg_at(ph + t * 360.0)
            kind = "LegF" if tag[0] == "F" else "LegR"
            shin = "ShinF" if tag[0] == "F" else "ShinR"
            # jaretul din spate se indoaie invers fata de genunchiul din fata
            pose[kind + tag[1]] = ("rot", rot(x=sw))
            pose[shin + tag[1]] = ("rot", rot(x=kn if tag[0] == "F" else -kn * 0.6))
        pose["Neck"] = ("rot", rot(x=3 * math.sin(2 * math.tau * t)))
        pose["Head"] = ("rot", rot(x=-2 * math.sin(2 * math.tau * t)))
        pose["Body"] = ("rot", rot(y=1.8 * math.sin(math.tau * t),
                                   z=1.2 * math.sin(math.tau * t)))
        pose["Tail"] = ("rot", rot(y=6 * math.sin(math.tau * t + 0.7)))
        key_pose(arm, f, pose, COW_BONES)

    # LIEDOWN (2 s): picioare -> genunchi -> crupa jos -> culcata
    action("LieDown")
    for f, pose in ((1, cow_pose_stand()), (18, cow_pose_kneel()),
                    (34, cow_pose_half()), (49, cow_pose_lie())):
        key_pose(arm, f, pose, COW_BONES)

    # LIE (2 s, bucla): culcata, rumega -- capul se misca abia perceptibil
    action("Lie")
    base = cow_pose_lie()
    for f in (1, 13, 25, 37, 49):
        t = (f - 1) / 48.0
        pose = dict(base)
        pose["Head"] = ("rot", rot(z=4 * math.sin(math.tau * t),
                                   x=-6 + 1.5 * math.sin(2 * math.tau * t)))
        key_pose(arm, f, pose, COW_BONES)

    # GETUP (2 s): crupa se ridica intai (vaca se scoala din spate), apoi
    # picioarele din fata
    action("GetUp")
    for f, pose in ((1, cow_pose_lie()), (16, cow_pose_half()),
                    (30, cow_pose_kneel()), (49, cow_pose_stand())):
        key_pose(arm, f, pose, COW_BONES)

    stash_actions(arm, ("Stand", "Walk", "LieDown", "Lie", "GetUp"))
    reset_pose(arm)


def build_zebu_cow():
    clear_built()
    b, bb = cow_mesh()
    body = to_obj(b, "Cow_Body")
    bell = to_obj(bb, "Bell")
    parts_body, parts_bell = b.parts, bb.parts
    off, tris = finish_all([body, bell], "base", AO_RIG, smooth=50.0)

    def P(x, y, z):
        return Vector((x, y, z)) + off

    arm = make_armature("ZebuCow", cow_bones(P), mesh=body)
    bell.parent = arm
    mod = bell.modifiers.new("Armature", "ARMATURE")
    mod.object = arm
    skin(body, parts_body, off)
    skin(bell, parts_bell, off)
    cow_animate(arm)
    bpy.context.view_layer.update()
    report("animals/zebu_cow.glb", [body, bell], tris)
    export_glb([arm, body, bell], "jodhpur/animals/zebu_cow.glb", animations=True)
    save_blend([arm, body, bell], "jodhpur_zebu_cow.blend", compress=True)


# ===========================================================================
# 2. ULIUL NEGRU (black kite)
# ===========================================================================

KITE = LOG_DARK
KITE_LIGHT = WOOD
KITE_BEAK = CAR_YELLOW
WING_DIHEDRAL = 8.0


def kite_mesh():
    """Uliul in zbor, aripile deschise. Elemente din `black_kite_bird.png`:

      - corp MARO-INCHIS fusiform, cap mic in fata, CIOC GALBEN curbat (1)
      - 2 aripi lungi deschise, in V usor ridicat; bordul de atac cu
        incheietura marcata, marginea de fuga dreapta
      - varfurile aripilor DESFACUTE IN PENE-„DEGETE" (5 pe fiecare aripa),
        rasfirate in evantai
      - acoperitoarele de pe aripa (banda) usor mai deschise decat penele
      - coada lunga, in FURCA scurta
    """
    b = new_builder()
    bone(b, ell(b, (0, -0.02, 0), (0.17, 0.46, 0.15), KITE), "Body")
    bone(b, ell(b, (0, 0.24, 0.025), (0.105, 0.14, 0.10), KITE), "Body")
    beak = b.frustum((0, 0.325, 0.012), 0.024, 0.004, 0.055, KITE_BEAK,
                     segments=6, axis="Y")
    xform(beak, rot(x=-20), pivot=(0, 0.30, 0.02))
    bone(b, beak, "Body")
    # coada in furca
    bone(b, plate(b, [(-0.05, -0.20, -0.01), (-0.13, -0.52, -0.01),
                      (-0.05, -0.47, -0.01), (0.0, -0.44, -0.01),
                      (0.05, -0.47, -0.01), (0.13, -0.52, -0.01),
                      (0.05, -0.20, -0.01)], (0, 0, 0.022), KITE),
         "Tail", "Body", lambda co: -co.y, 0.22, 0.30)

    for sx in (-1, 1):
        side = "L" if sx < 0 else "R"
        dih = rot(y=-sx * WING_DIHEDRAL)
        pivot = (sx * 0.05, 0, 0)

        def W(x, y, z=0.0):
            return (sx * x, y, z)

        wing = plate(b, [W(0.03, 0.10), W(0.20, 0.13), W(0.36, 0.10),
                         W(0.50, 0.055), W(0.56, 0.035), W(0.56, -0.10),
                         W(0.42, -0.16), W(0.25, -0.20), W(0.10, -0.19),
                         W(0.03, -0.12)], (0, 0, 0.028), KITE)
        xform(wing, dih, pivot)
        bone(b, wing, "WingTip" + side, "Wing" + side,
             lambda co, sx=sx: abs(co.x), 0.30, 0.44)
        # acoperitoarele, banda mai deschisa pe dosul aripii
        cov = plate(b, [W(0.08, 0.085, 0.017), W(0.34, 0.075, 0.017),
                        W(0.44, 0.03, 0.017), W(0.30, 0.0, 0.017),
                        W(0.08, 0.0, 0.017)], (0, 0, 0.01), KITE_LIGHT)
        xform(cov, dih, pivot)
        bone(b, cov, "WingTip" + side, "Wing" + side,
             lambda co, sx=sx: abs(co.x), 0.30, 0.44)
        # 5 pene-degete, rasfirate
        for k in range(5):
            y0 = 0.025 - k * 0.030
            ang = math.radians(14.0 - k * 11.0)
            ln = 0.20 + 0.03 * (1.0 - abs(k - 1.5) / 2.5)
            p0 = Vector(W(0.53, y0))
            d = Vector((sx * math.cos(ang), math.sin(ang), 0))
            path = [p0, p0 + d * ln * 0.5 + Vector((0, 0, 0.01)), p0 + d * ln]
            f = b.blade([tuple(p) for p in path], [0.050, 0.044, 0.012], 0.014,
                        KITE, up=(0, 0, 1))
            xform(f, dih, pivot)
            bone(b, f, "WingTip" + side)
    return b


def kite_bones(P):
    bones = [
        dict(name="Body", head=P(0, -0.20, 0), tail=P(0, 0.26, 0)),
        dict(name="Tail", parent="Body", head=P(0, -0.20, 0), tail=P(0, -0.48, -0.01)),
    ]
    for sx, side in ((-1, "L"), (1, "R")):
        bones += [
            dict(name="Wing" + side, parent="Body",
                 head=P(sx * 0.05, 0, 0), tail=P(sx * 0.36, -0.02, 0.04)),
            dict(name="WingTip" + side, parent="Wing" + side,
                 head=P(sx * 0.36, -0.02, 0.04), tail=P(sx * 0.74, -0.04, 0.10)),
        ]
    return bones


KITE_BONES = ["Body", "Tail", "WingL", "WingTipL", "WingR", "WingTipR"]
KITE_FLY_FRAMES = 32


def kite_fly_pose(t):
    """Bataie lenta: aripa intre -8 si +30 grade, varful cu intarziere."""
    s = math.sin(math.tau * t)
    wing = 11.0 + 19.0 * s
    tip = 9.0 * math.sin(math.tau * t - 0.9)
    return {
        "Body": [("rot", rot(x=1.5 * s)), ("move", (0, 0, -0.03 * s))],
        "Tail": ("rot", rot(x=-3.0 * math.sin(math.tau * t - 0.5))),
        "WingL": ("rot", rot(y=wing)),
        "WingTipL": ("rot", rot(y=tip)),
        "WingR": ("rot", rot(y=-wing)),
        "WingTipR": ("rot", rot(y=-tip)),
    }


def purge_actions():
    """Exportatorul (mod ACTIONS) ia TOATE actiunile cu fake user care se
    potrivesc pe schelet -- fara asta, uliul pleca si cu cele 5 clipuri ale
    vacii (gasit pe GLB: Fly + GetUp/Lie/LieDown/Stand/Walk)."""
    for act in list(bpy.data.actions):
        bpy.data.actions.remove(act)


def build_black_kite():
    clear_built()
    purge_actions()
    b = kite_mesh()
    obj = to_obj(b, "Kite")
    parts = b.parts
    off, tris = finish_all([obj], "center", AO_RIG, smooth=40.0)

    def P(x, y, z):
        return Vector((x, y, z)) + off

    arm = make_armature("KiteRig", kite_bones(P), mesh=obj)
    skin(obj, parts, off)
    bpy.context.scene.render.fps = FPS
    arm.animation_data_create()
    arm.animation_data.action = bpy.data.actions.new("Fly")
    # 32 de cadre, bucla: cheile 1..33 (ultima = prima)
    for f in range(1, KITE_FLY_FRAMES + 2, 2):
        key_pose(arm, f, kite_fly_pose((f - 1) / float(KITE_FLY_FRAMES)), KITE_BONES)
    stash_actions(arm, ("Fly",))
    reset_pose(arm)
    bpy.context.view_layer.update()
    report("animals/black_kite_bird.glb", [obj], tris)
    export_glb([arm, obj], "jodhpur/animals/black_kite_bird.glb", animations=True)
    save_blend([arm, obj], "jodhpur_black_kite.blend", compress=True)


# ===========================================================================
# 3. PAUNII
# ===========================================================================

PEA_BLUE = CAR_BLUE
PEA_TRAIN = TROPICAL_GREEN
PEA_WING = DRY_VEGETATION
PEA_PRIMARY = SAND_MID
PEA_LEG = SAND_MID
PEA_EYE_RING = CAR_YELLOW
PEA_EYE = CAR_BLUE


def _pea_legs(b, y=0.10, top=0.36):
    for sx in (-1, 1):
        x = sx * 0.05
        b.taper_sweep([(x, y - 0.03, top), (x, y, 0.18), (x, y + 0.02, 0.03)],
                      [0.024, 0.016, 0.014], PEA_LEG, segments=6)
        for ang in (-25, 0, 25):
            d = Vector((math.sin(math.radians(ang)), math.cos(math.radians(ang)), 0))
            p0 = Vector((x, y + 0.02, 0.012))
            b.beam(tuple(p0), tuple(p0 + d * 0.09), 0.014, PEA_LEG)
        b.beam((x, y + 0.02, 0.012), (x, y - 0.05, 0.012), 0.014, PEA_LEG)


def _pea_head(b, base, lean=0.0):
    """Gat albastru in S, cap mic, cioc, dunga alba la ochi, MOTUL (6 tije
    cu varf albastru-verzui). `base` = punctul de plecare al gatului."""
    bx, by, bz = base
    neck = [(0, by, bz), (0, by + 0.08 + lean, bz + 0.12),
            (0, by + 0.08 + lean, bz + 0.25), (0, by + 0.11 + lean, bz + 0.35)]
    b.taper_sweep(neck, [0.10, 0.068, 0.055, 0.048], PEA_BLUE, segments=8)
    hx, hy, hz = 0, by + 0.15 + lean, bz + 0.39
    ell(b, (hx, hy, hz), (0.078, 0.125, 0.085), PEA_BLUE, seg=8, rings=4)
    for sx in (-1, 1):
        ell(b, (sx * 0.036, hy + 0.02, hz + 0.012), (0.012, 0.055, 0.016),
            FOAM_WHITE, seg=6, rings=3)
    b.frustum((0, hy + 0.08, hz - 0.012), 0.018, 0.003, 0.05, MARBLE_GREY,
              segments=6, axis="Y")
    for k in range(6):
        a = math.radians(-30 + k * 12)
        top = Vector((0.0, hy - 0.01 + 0.06 * math.sin(a), hz + 0.09 + 0.015 * math.cos(a)))
        top.x = 0.03 * (k - 2.5) / 2.5
        b.beam((0, hy - 0.01, hz + 0.04), tuple(top), 0.006, MARBLE_GREY)
        ell(b, tuple(top), (0.022, 0.018, 0.022), PEA_BLUE, seg=6, rings=3)
    return (hx, hy, hz)


def _train_point(path, radii, u):
    """Punct + raza pe o polilinie, la fractia u din lungime (liniar pe
    portiuni, exact ca `taper_sweep`)."""
    pts = [Vector(p) for p in path]
    lens = [(pts[i + 1] - pts[i]).length for i in range(len(pts) - 1)]
    total = sum(lens)
    d = u * total
    for i, ln in enumerate(lens):
        if d <= ln or i == len(lens) - 1:
            f = min(d / ln, 1.0)
            p = pts[i].lerp(pts[i + 1], f)
            r = radii[i] + (radii[i + 1] - radii[i]) * f
            t = (pts[i + 1] - pts[i]).normalized()
            return p, r, t
        d -= ln


def _eye(b, c, n, r=0.045, squash=1.25):
    """Ochiul de pe trena: disc GALBEN, peste el disc ALBASTRU mai mic."""
    n = Vector(n).normalized()
    disc(b, tuple(Vector(c) + n * 0.004), n, r, 0.012, PEA_EYE_RING, seg=10,
         squash=squash)
    disc(b, tuple(Vector(c) + n * 0.012), n, r * 0.5, 0.010, PEA_EYE, seg=8,
         squash=squash)


def peacock_closed_mesh():
    """Paunul cu trena STRANSA, din profil. Elemente din `peacock_closed.png`:

      - gat si piept ALBASTRU intens, gatul in S, cap mic cu cioc deschis
        la culoare si DUNGI ALBE la ochi (2), MOTUL pe crestet (evantai mic
        de tije cu varf albastru)
      - aripa stransa pe flanc, VERDE-GALBUIE (acoperitoarele), cu partea
        de jos-spate CAFENIU-PORTOCALIE (remigele)
      - 2 picioare subtiri, bej-maro, cu degete
      - TRENA lunga, VERDE, pornita din crupa, care coboara in panta pana
        la sol si se termina in varf zdrentuit
      - OCHII trenei ca puncte (disc galben + centru albastru), ~14, pe
        fata de sus si pe flancul vazut
    """
    b = new_builder()
    _pea_legs(b, top=0.32)
    ell(b, (0, 0.02, 0.47), (0.30, 0.56, 0.34), PEA_BLUE, seg=10, rings=6,
        r=rot(x=14))
    for sx in (-1, 1):
        ell(b, (sx * 0.10, -0.04, 0.51), (0.13, 0.46, 0.25), PEA_WING,
            seg=8, rings=5, r=rot(x=10))
        ell(b, (sx * 0.105, -0.21, 0.44), (0.11, 0.26, 0.14), PEA_PRIMARY,
            seg=8, rings=4, r=rot(x=6))
    _pea_head(b, (0, 0.22, 0.52))

    path = [(0, -0.24, 0.50), (0, -0.55, 0.43), (0, -0.95, 0.30),
            (0, -1.28, 0.16), (0, -1.50, 0.06)]
    radii = [0.10, 0.14, 0.16, 0.14, 0.05]
    tr = b.taper_sweep(path, radii, PEA_TRAIN, segments=10)
    SX = 1.25
    scale_axis(tr, 0, SX)
    # pene care ies din flancurile trenei, in jos-spate: rup silueta de
    # "carnat" si dau marginea zdrentuita de pe decupare
    for k in range(9):
        u = 0.18 + k * 0.09
        p, r, t = _train_point(path, radii, u)
        for sx in (-1, 1):
            a = math.radians(-35 if k % 2 else -55)
            base = p + Vector((sx * math.cos(a) * r * SX, 0, math.sin(a) * r))
            d = (t * 0.8 + Vector((sx * 0.25, 0, -0.35))).normalized()
            ln = 0.20 + 0.03 * (k % 3)
            # varful nu coboara sub talpi: altfel originea la baza ridica
            # tot paunul (masurat: 1.17 m in loc de 1.02)
            if base.z + d.z * ln < 0.02:
                d.z = (0.02 - base.z) / ln
                d.normalize()
            b.blade([tuple(base), tuple(base + d * ln * 0.55), tuple(base + d * ln)],
                    [0.08, 0.07, 0.01], 0.018, PEA_TRAIN, up=(sx * 0.6, 0, 0.8))
    # varful zdrentuit: pene care ies din capatul trenei
    for k in range(7):
        a = math.radians(-45 + k * 15)
        p0 = Vector((0, -1.40, 0.10))
        d = Vector((math.sin(a) * 0.6, -math.cos(a), -0.05)).normalized()
        b.blade([tuple(p0), tuple(p0 + d * 0.14), tuple(p0 + d * 0.26)],
                [0.10, 0.08, 0.01], 0.02, PEA_TRAIN, up=(0, 0, 1))
    # ochii: 3 randuri decalate pe fata de sus + flancuri
    n_eyes = 0
    rows = [(0.18, (70, 110)), (0.33, (50, 90, 130)), (0.48, (70, 110)),
            (0.62, (50, 90, 130)), (0.76, (70, 110)), (0.88, (90,))]
    for u, angs in rows:
        p, r, t = _train_point(path, radii, u)
        up = (Vector((0, 0, 1)) - t * t.z).normalized()
        for a_deg in angs:
            a = math.radians(a_deg)
            surf = p + Vector((math.cos(a) * r * SX, 0, 0)) + up * (math.sin(a) * r)
            nrm = Vector((math.cos(a) / SX, 0, 0)) + up * math.sin(a)
            _eye(b, surf, nrm, r=0.040)
            n_eyes += 1
    print("  paun inchis: %d ochi pe trena" % n_eyes)
    return b


def peacock_fanned_mesh():
    """Paunul cu EVANTAIUL deschis, din fata. Elemente din `peacock_fanned.png`:

      - EVANTAI VERDE mare, in semicerc larg (mai lat decat inalt), cu
        marginea FESTONATA de varfurile penelor, putin cauc spre fata
      - OCHII pe evantai in 3 randuri concentrice (disc galben + centru
        albastru), 20 in total: 10 pe margine, 7 la mijloc, 3 spre centru
      - in fata evantaiului: corpul si gatul ALBASTRU, capul mic cu motul,
        dungile albe la ochi, ciocul
      - aripile stranse pe flancuri, cafeniu-portocalii, la baza evantaiului
      - 2 picioare bej-maro, cu degete
    """
    b = new_builder()
    _pea_legs(b, y=0.02, top=0.26)
    ell(b, (0, 0.0, 0.40), (0.30, 0.32, 0.38), PEA_BLUE, seg=10, rings=6,
        r=rot(x=8))
    for sx in (-1, 1):
        ell(b, (sx * 0.12, -0.05, 0.44), (0.09, 0.24, 0.20), PEA_PRIMARY,
            seg=8, rings=4, r=rot(y=-sx * 18))
    _pea_head(b, (0, 0.06, 0.50), lean=-0.05)

    # evantaiul: elipsa (semi-axa orizontala RX, verticala RZ) centrata in
    # spatele crupei, deschisa pe ~210 grade, cu marginea festonata
    C = Vector((0, -0.16, 0.34))
    RX, RZ = 0.80, 0.62
    A0, A1 = math.radians(-105), math.radians(105)   # 0 = sus
    NF = 21                                          # pene (festoane)

    def rim(a):
        k = (a - A0) / (A1 - A0) * NF
        return 1.0 - 0.07 * abs(math.sin(math.pi * k))

    def fan_pt(s, a):
        rr = s * rim(a)
        x = math.sin(a) * RX * rr
        z = math.cos(a) * RZ * rr
        y = 0.12 * rr * rr          # cauc: marginea vine spre fata
        return C + Vector((x, y, z))

    NI, NJ = 6, 84

    def fn(i, j):
        s = 0.08 + 0.92 * i / NI
        a = A0 + (A1 - A0) * j / NJ
        p = fan_pt(s, a)
        eps = 1e-3
        dp_s = fan_pt(s + eps, a) - p
        dp_a = fan_pt(s, a + eps) - p
        n = dp_a.cross(dp_s)
        if n.y < 0:
            n = -n
        return p, n

    shell(b, fn, NI, NJ, 0.03, PEA_TRAIN)

    n_eyes = 0
    for s, cnt in ((0.88, 10), (0.64, 7), (0.40, 3)):
        span = (A1 - A0) * (0.92 if cnt > 3 else 0.45)
        for k in range(cnt):
            a = -span / 2 + span * (k + 0.5) / cnt if cnt > 1 else 0.0
            p, n = fn(0, 0)  # doar ca sa avem tipul; recalculam mai jos
            p = fan_pt(s, a)
            eps = 1e-3
            n = (fan_pt(s, a + eps) - p).cross(fan_pt(s + eps, a) - p)
            if n.y < 0:
                n = -n
            n.normalize()
            _eye(b, tuple(p + n * 0.015), n, r=0.058 if s > 0.5 else 0.05,
                 squash=1.3)
            n_eyes += 1
    print("  paun deschis: %d ochi pe evantai" % n_eyes)
    return b


def build_peacocks():
    for mesh_fn, path, blend in (
            (peacock_closed_mesh, "animals/peacock_closed.glb", "jodhpur_peacock_closed.blend"),
            (peacock_fanned_mesh, "animals/peacock_fanned.glb", "jodhpur_peacock_fanned.blend")):
        clear_built()
        b = mesh_fn()
        obj = to_obj(b, "Peacock")
        _, tris = finish_all([obj], "base", AO_STATIC, smooth=45.0)
        drop_part_attr(obj)
        report(path, [obj], tris)
        export_glb([obj], "jodhpur/" + path)
        save_blend([obj], blend)


# ===========================================================================
# 4. LANGURUL
# ===========================================================================

LANG_FUR = MARBLE_GREY
LANG_DARK = VOLCANIC_BLACK


def langur_mesh():
    """Langurul ASEZAT pe vine, ca pe `langur.png`:

      - blana GRI-DESCHIS; spatele arcuit, trunchiul aplecat in fata
      - cap rotund cu FATA NEAGRA (masca), franjuri gri in jurul fetei,
        arcada proeminenta
      - 2 brate lungi coborate drept pana la sol, MAINILE NEGRE sprijinite
        in fata talpilor
      - 2 picioare stranse, genunchii sus in fata pieptului, TALPILE NEGRE
      - COADA LUNGA (~1 m), subtire, pe sol: pleaca din spate, se curbeaza
        si se intoarce spre fata in carlig
    """
    b = new_builder()
    # bazinul pe sol si trunchiul aplecat in fata
    ell(b, (0, -0.06, 0.14), (0.24, 0.26, 0.22), LANG_FUR, seg=8, rings=5)
    b.taper_sweep([(0, -0.08, 0.16), (0, -0.04, 0.30), (0, 0.02, 0.42),
                   (0, 0.07, 0.50)], [0.14, 0.15, 0.135, 0.09], LANG_FUR,
                  segments=10)
    # capul, masca neagra, arcada, urechi
    hc = Vector((0, 0.11, 0.60))
    ell(b, tuple(hc), (0.18, 0.17, 0.19), LANG_FUR, seg=10, rings=6)
    # masca neagra: plata, cat toata fata, franjurile gri o inconjoara
    # capul intors spre privitor (ca pe decupare): masca rotita 40 grade
    turn = rot(z=-40)
    ell(b, tuple(hc + turn @ Vector((0, 0.062, -0.012))), (0.13, 0.06, 0.14),
        LANG_DARK, seg=10, rings=5, r=turn)
    ell(b, tuple(hc + turn @ Vector((0, 0.088, -0.05))), (0.06, 0.04, 0.045),
        LANG_DARK, seg=6, rings=3, r=turn)
    # picioarele: coapsa urca spre genunchi, gamba coboara, talpa neagra
    for sx in (-1, 1):
        x = sx * 0.085
        b.taper_sweep([(x * 0.8, -0.04, 0.12), (x, 0.08, 0.24), (x, 0.13, 0.27)],
                      [0.07, 0.06, 0.05], LANG_FUR, segments=8)
        b.taper_sweep([(x, 0.13, 0.27), (x, 0.13, 0.12), (x, 0.12, 0.04)],
                      [0.05, 0.04, 0.035], LANG_FUR, segments=8)
        ell(b, (x, 0.16, 0.02), (0.07, 0.15, 0.04), LANG_DARK, seg=8, rings=3)
    # bratele drepte pana la sol, mainile negre in fata talpilor
    for sx in (-1, 1):
        x = sx * 0.11
        b.taper_sweep([(x, 0.06, 0.46), (x * 1.05, 0.16, 0.26), (x * 1.1, 0.22, 0.10)],
                      [0.045, 0.037, 0.03], LANG_FUR, segments=8)
        b.taper_sweep([(x * 1.1, 0.22, 0.11), (x * 1.1, 0.24, 0.035)],
                      [0.03, 0.028], LANG_DARK, segments=6)
        ell(b, (x * 1.1, 0.27, 0.018), (0.06, 0.10, 0.035), LANG_DARK, seg=8, rings=3)
    # coada: ~1 m pe sol, din spate, curbata spre partea camerei (+X) si
    # intoarsa in fata, in carlig
    tail = [(0, -0.16, 0.08), (0.02, -0.34, 0.03), (0.10, -0.52, 0.025),
            (0.26, -0.60, 0.025), (0.42, -0.54, 0.025), (0.50, -0.38, 0.03),
            (0.47, -0.25, 0.05)]
    ln = sum((Vector(tail[i + 1]) - Vector(tail[i])).length for i in range(len(tail) - 1))
    print("  langur: coada %.2f m" % ln)
    b.taper_sweep(tail, [0.035, 0.028, 0.026, 0.024, 0.022, 0.02, 0.012],
                  LANG_FUR, segments=6)
    return b


def build_langur():
    clear_built()
    b = langur_mesh()
    obj = to_obj(b, "Langur")
    _, tris = finish_all([obj], "base", AO_STATIC, smooth=45.0)
    drop_part_attr(obj)
    report("animals/langur.glb", [obj], tris)
    export_glb([obj], "jodhpur/animals/langur.glb")
    save_blend([obj], "jodhpur_langur.blend")


# ===========================================================================

if __name__ == "__main__":
    # Curatenie totala: actiunile raman in bpy.data intre piese, iar
    # stash_actions le-ar lega pe toate de ultima armatura.
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)
    build_zebu_cow()
    build_black_kite()
    build_peacocks()
    build_langur()
    print("== Jodhpur animale ==")
    for path, tris, d in results:
        print("  %-34s %5d tri  %.2f x %.2f x %.2f m" % (path, tris, d.x, d.y, d.z))
