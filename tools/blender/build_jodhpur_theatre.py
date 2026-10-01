"""Jodhpur -- teatrul mobil, val 4 grupa C (brief §1.6, docs/asset_briefs/jodhpur_kit.md).

  jodhpur/animals/baraat_horse.glb   calul alb al mirelui, cu mirele calare;
                                     schelet + actiunile `Walk` si `Idle`
  jodhpur/props/baraat_band.glb      fanfara: 4 figuri statice pe un rand de 4 m
  jodhpur/props/zipline_rider.glb    omul de pe tiroliana, ORIGINEA IN SCRIPETE

Decuparile de lucru: docs/track_briefs/img/jodhpur_assets_v1/{baraat_horse,
baraat_band,zipline_rider}.png. Lista de elemente a fiecarei piese e in
docstring-ul functiei ei de build (brief §0.1 pasul 1), scrisa INAINTE de
geometrie.

Conventii (brief §0):
  - "inainte" = +Y in Blender (-Z in Godot) la toate trei;
  - figurile umane sunt low-poly de diorama: membre din `taper_sweep` cu 5-6
    segmente, capete din trunchiuri de con, fara degete; ce trebuie sa se
    CITEASCA din camera de joc sunt siluetele si petele de culoare (turbanul
    rosu, pelerina, toba, trompeta galbena, casca galbena, hamul);
  - piele `SAND_MID`, barbi/par `LOG_DARK`, haine albe `FOAM_WHITE`, pantofi
    `VOLCANIC_BLACK`. Accentele saturate (turbane, veste, valtrap, casca,
    bluza) sunt pe sloturile de masina 14-16 -- de aceea toate nodurile care
    le poarta sunt declarate in `verify_jodhpur.sh` cu `--allow-car-slots`.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_jodhpur_theatre.py
"""

import math
from mathutils import Vector, Matrix

SKIN = SAND_MID
HAIR = LOG_DARK
CLOTH = FOAM_WHITE
SHOE = VOLCANIC_BLACK

AO_FIG = dict(samples=12, dist=0.8, gradient="vertical",
              low=0.62, high=1.00, power=0.9, floor=0.35)
AO_HORSE = dict(samples=20, dist=1.4, gradient="vertical",
                low=0.60, high=1.00, power=0.9, floor=0.34)

results = []


# ---------------------------------------------------------------------------
# utilitare
# ---------------------------------------------------------------------------

def _verts(faces):
    return {v for f in faces for v in f.verts}


def _squash(faces, sx=1.0, sy=1.0, sz=1.0, center=(0.0, 0.0, 0.0)):
    """Turteste o piesa deja pusa in Builder (sectiunea de `taper_sweep` e
    cerc; un trunchi de cal e mai inalt decat lat, un gat de cal e o lama)."""
    c = Vector(center)
    for v in _verts(faces):
        d = v.co - c
        v.co = c + Vector((d.x * sx, d.y * sy, d.z * sz))
    return faces


def _rotz(deg):
    return Matrix.Rotation(math.radians(deg), 3, "Z")


def _rotx(deg):
    return Matrix.Rotation(math.radians(deg), 3, "X")


def _roty(deg):
    return Matrix.Rotation(math.radians(deg), 3, "Y")


def _obj_or_none(b, name):
    obj = b.to_object(name)
    if len(obj.data.vertices) == 0:
        me = obj.data
        bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.meshes.remove(me)
        return None
    return obj


def _all_coords(objs):
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x)
            ys.append(v.co.y)
            zs.append(v.co.z)
    return xs, ys, zs


def _finish_assembly(objs, ao, bevel=0.0, smooth_angle=50.0, place=None):
    """Offsetul de origine se calculeaza O DATA pe ansamblu si se aplica
    identic tuturor nodurilor (memoria finish-recentreaza-fiecare-nod-separat).
    `place=None`: baza la z=0, centrat pe XY. Altfel se aplica vectorul dat
    (tiroliana: zero, originea e deja in scripete)."""
    objs = [o for o in objs if o is not None]
    if place is None:
        xs, ys, zs = _all_coords(objs)
        place = Vector((-(min(xs) + max(xs)) * 0.5,
                        -(min(ys) + max(ys)) * 0.5, -min(zs)))
    tris = {}
    for o in objs:
        st = finish(o, bevel=bevel, ao=ao, origin=None, smooth_angle=smooth_angle)
        for v in o.data.vertices:
            v.co += place
        tris[o.name] = st["tris"]
    return place, tris


def _report(path, objs, tris, budget=None):
    xs, ys, zs = _all_coords([o for o in objs if o is not None and o.type == "MESH"])
    dims = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
    total = sum(tris.values())
    results.append((path, total, tris, dims, (min(zs), max(zs)), budget))


# ---------------------------------------------------------------------------
# figura umana, low-poly (fanfara + mirele + tiroliana)
# ---------------------------------------------------------------------------

def _limb(b, pts, radii, slot, seg=5):
    return b.taper_sweep([Vector(p) for p in pts], radii, slot, segments=seg)


def _head(b, c, slot_skin=SKIN, beard=True, face_dir=(0.0, 1.0, 0.0), size=1.0):
    """Cap: trunchi de con cu 6 fete (fata mai ingusta jos -> barbie), barba
    `LOG_DARK` pe partea din fata. `face_dir` = incotro priveste."""
    c = Vector(c)
    s = size
    b.frustum(c, 0.095 * s, 0.105 * s, 0.24 * s, slot_skin, segments=6)
    if beard:
        f = Vector(face_dir).normalized()
        yaw = math.degrees(math.atan2(-f.x, f.y))
        b.box(c + f * 0.08 * s + Vector((0, 0, -0.095 * s)),
              (0.12 * s, 0.05 * s, 0.05 * s), HAIR, rotation=_rotz(yaw))


def _turban(b, top_of_head, slot=CAR_RED, crest=True, size=1.0):
    """Turban rajasthani: bulb mai lat decat capul (latimea maxima sus), plus
    motul (`kalgi`) de pe crestet -- pe decupare fiecare turban are un varf."""
    z = Vector(top_of_head)
    s = size
    # bulbul: se umfla peste frunte si se rotunjeste sus (profil de
    # revolutie), nu un cilindru evazat -- ala citea fes.
    b.revolve([(0.11 * s, 0.0), (0.145 * s, 0.06 * s), (0.14 * s, 0.12 * s),
               (0.09 * s, 0.17 * s), (0.0, 0.185 * s)], slot, segments=8,
              origin=tuple(z + Vector((0, 0, -0.07 * s))))
    if crest:
        b.frustum(z + Vector((0, -0.02 * s, 0.13 * s)), 0.045 * s, 0.0,
                  0.09 * s, slot, segments=4)


# ---------------------------------------------------------------------------
# 1. baraat_horse
# ---------------------------------------------------------------------------

# Cotele calului, o singura data (geometria SI scheletul le folosesc).
BODY_Z = 0.98            # axa trunchiului
LEG_X = 0.13
FRONT_Y, REAR_Y = 0.40, -0.50
HIP_Z = 0.92             # articulatia umar/sold (in trunchi)
KNEE_F, HOCK_R = 0.46, 0.50
SEAT_Y, SEAT_Z = -0.02, 1.34   # sezutul mirelui pe sa
# Calul se construieste pe cotele de mai sus (~2,1 m de la coada la bot) si
# apoi se INTINDE pe Y cu SY, ca lungimea sa iasa 2,4 m (brief §1.6) fara sa
# creasca inaltimea: raportul h/l al decuparii e al unui cal lung si scund,
# iar primul export, la scara 1, iesea 2,09 m lung la 2,42 m inalt (h/l
# 1,16 fata de 0,77). Mirele NU se intinde; scheletul trece prin acelasi SY.
SY = 1.15


def build_baraat_horse():
    """baraat_horse -- lista de elemente de pe decupare (baraat_horse.png):

    CALUL (alb, FOAM_WHITE), vazut din profil, capul la DREAPTA, la pas:
      - trunchi rotunjit, mai inalt decat lat, crupa rotunda;
      - gat gros, ridicat ~45 grade, cap lung cu botul in jos-inainte;
      - 2 urechi drepte; coama crem (CORAL_SAND) scurta, pe muchia gatului,
        plus motul din frunte;
      - 4 picioare subtiri, cu copite NEGRE (4 pete negre la sol);
      - coada lunga, impletita cu 5 panglici colorate (roz, galben, verde,
        rosu, roz) care atarna pana sub genunchi -- iese din contur in spate.
    PODOABE (nodul Saddle):
      - VALTRAPUL: panou dreptunghiular pe flanc, pana la jumatatea burtii:
        chenar ROSU, camp ALBASTRU, tiv GALBEN jos si pe laturi, franjuri /
        ciucuri colorati (roz, verde) sub tiv -- 6 pe flanc;
      - sa rosie cu oblancul din fata GALBEN (auriu), scara neagra sub talpa;
      - acoperamantul crupei: panza crem cu tiv galben si 5 ciucuri
        portocalii pe marginea de jos;
      - capastrul: curele ROSII (nasar, frontal, obrazare), fraiele VERZI
        pana in mainile mirelui, 3 ciucuri rosii sub falca, colier de ciucuri
        colorati (roz/verde/galben) la baza gatului, panas rosu-portocaliu
        intre urechi.
    MIRELE (nodul Rider), calare, spre dreapta:
      - turban ROSU inalt cu varf (kalgi) si o bijuterie galbena in fata;
      - barba neagra, fata/maini piele;
      - PELERINA ROSIE pe umeri si pe spate, cade peste sa pe flanc;
      - haina (sherwani) si pantalonii ALBI/crem, genunchii in fata;
      - bratele inainte, mainile tin fraiele deasupra greabanului;
      - pantofi negri in scari.
    Proportii: lungime cal ~ 2,4 m, inaltime totala (turban) ~ 2,4 m;
    greabanul ~ 1,35 m, adica mirele adauga ~ 1,05 m peste sa.
    """
    hb = Builder()   # Horse
    sb = Builder()   # Saddle (podoabe, valtrap, capastru, panglici)
    rb = Builder()   # Rider (mirele)
    W = FOAM_WHITE

    # --- trunchiul: tub cu raza variabila, turtit lateral -----------------
    ys = [-0.80, -0.66, -0.36, 0.00, 0.34, 0.58]
    rs = [0.14, 0.28, 0.31, 0.29, 0.31, 0.22]
    zs = [BODY_Z + 0.04, BODY_Z + 0.03, BODY_Z, BODY_Z - 0.02, BODY_Z + 0.02,
          BODY_Z + 0.10]
    trunk = hb.taper_sweep([Vector((0, y, z)) for y, z in zip(ys, zs)], rs, W,
                           segments=10)
    _squash(trunk, sx=0.80, center=(0, 0, BODY_Z))

    # --- gatul (lama groasa, ridicata) + capul ---------------------------
    neck = hb.taper_sweep([Vector((0, 0.44, 1.12)), Vector((0, 0.62, 1.42)),
                           Vector((0, 0.76, 1.66))], [0.22, 0.16, 0.12], W,
                          segments=8)
    _squash(neck, sx=0.62, center=(0, 0.6, 1.4))
    head = hb.taper_sweep([Vector((0, 0.72, 1.76)), Vector((0, 0.86, 1.62)),
                           Vector((0, 1.02, 1.44)), Vector((0, 1.08, 1.36))],
                          [0.11, 0.105, 0.08, 0.0], W, segments=8)
    _squash(head, sx=0.78, center=(0, 0.9, 1.55))
    # urechile
    for sx in (-1, 1):
        hb.taper_sweep([Vector((sx * 0.05, 0.73, 1.83)),
                        Vector((sx * 0.065, 0.71, 1.97))], [0.035, 0.0], W,
                       segments=4)
    # ochii
    for sx in (-1, 1):
        hb.box((sx * 0.083, 0.86, 1.67), (0.03, 0.05, 0.04), VOLCANIC_BLACK)
    # coama crem: 4 smocuri pe muchia gatului + motul din frunte
    # (o singura lama pe muchia gatului, nu smocuri: smocurile separate
    # citeau ca vertebre de cutie in prima comparatie)
    mane = hb.taper_sweep([Vector((0, 0.38, 1.30)), Vector((0, 0.52, 1.52)),
                           Vector((0, 0.64, 1.68)), Vector((0, 0.72, 1.80))],
                          [0.07, 0.085, 0.075, 0.05], CORAL_SAND, segments=6)
    _squash(mane, sx=0.5, center=(0, 0.55, 1.55))
    hb.box((0, 0.80, 1.83), (0.06, 0.07, 0.07), CORAL_SAND, rotation=_rotx(-30))

    # --- picioarele: doua segmente + copita, drepte in poza de repaus ----
    for sx in (-1, 1):
        for y0, knee, fore in ((FRONT_Y, KNEE_F, True), (REAR_Y, HOCK_R, False)):
            x = sx * LEG_X
            if fore:
                upper = [Vector((x, y0, HIP_Z)), Vector((x, y0 + 0.01, knee))]
                ur = [0.10, 0.062]
            else:
                # coapsa din spate mai groasa, jaretul usor inapoi
                upper = [Vector((x, y0, HIP_Z)), Vector((x, y0 - 0.05, knee))]
                ur = [0.13, 0.065]
            hb.taper_sweep(upper, ur, W, segments=6)
            ky = y0 + (0.01 if fore else -0.05)
            hb.taper_sweep([Vector((x, ky, knee)), Vector((x, y0, 0.10))],
                           [0.056, 0.05], W, segments=6)
            hb.frustum((x, y0 + 0.01, 0.05), 0.07, 0.058, 0.10,
                       VOLCANIC_BLACK, segments=6)

    # --- coada: coada de par (alba) + 5 panglici colorate ----------------
    hb.taper_sweep([Vector((0, -0.80, 1.14)), Vector((0, -0.90, 1.02)),
                    Vector((0, -0.94, 0.80))], [0.055, 0.06, 0.035], W,
                   segments=6)
    ribbons = [(-0.07, FLAMINGO_PINK), (-0.035, CAR_YELLOW),
               (0.0, TROPICAL_GREEN), (0.035, CAR_RED), (0.07, FLAMINGO_PINK)]
    for i, (dx, slot) in enumerate(ribbons):
        # evantai: fata lata a panglicii spre lateral (se vede din profil),
        # capetele se rasfira inapoi ca pe decupare
        top = Vector((dx * 0.5, -0.86, 1.10))
        bot = Vector((dx * 1.4, -0.93 - 0.03 * i, 0.50 + 0.05 * (i % 3)))
        sb.beam(top, bot, (0.085, 0.016), slot, up=(1, 0, 0))

    # --- VALTRAPUL -------------------------------------------------------
    cloth_y0, cloth_y1 = -0.34, 0.26       # capetele valtrapului pe Y
    cy = (cloth_y0 + cloth_y1) * 0.5
    ln = cloth_y1 - cloth_y0
    # placa de sus (sub sa), pe spinare
    sb.box((0, cy, 1.255), (0.46, ln, 0.04), CAR_RED)
    for sx in (-1, 1):
        tilt = _roty(sx * -8.0)
        # panoul lateral: chenarul rosu
        sb.box((sx * 0.265, cy, 1.02), (0.035, ln, 0.46), CAR_RED, rotation=tilt)
        # campul albastru, iesit 1 cm
        sb.box((sx * 0.282, cy, 1.04), (0.02, ln - 0.14, 0.28), CAR_BLUE,
               rotation=tilt)
        # banda verde brodata in camp
        sb.box((sx * 0.288, cy, 1.04), (0.02, ln - 0.20, 0.05), TROPICAL_GREEN,
               rotation=tilt)
        # tivul galben: jos + cele doua laturi
        sb.box((sx * 0.252, cy, 0.79), (0.045, ln + 0.02, 0.06), CAR_YELLOW,
               rotation=tilt)
        for yy in (cloth_y0, cloth_y1):
            sb.box((sx * 0.27, yy, 1.02), (0.045, 0.045, 0.46), CAR_YELLOW,
                   rotation=tilt)
        # ciucurii de sub tiv
        for k in range(6):
            t = (k + 0.5) / 6.0
            slot = FLAMINGO_PINK if k % 2 == 0 else TROPICAL_GREEN
            sb.frustum((sx * 0.245, cloth_y0 + ln * t, 0.715), 0.022, 0.012,
                       0.10, slot, segments=4)
    # sa: perna rosie + oblancul auriu in fata + cel din spate
    sb.box((0, SEAT_Y, 1.30), (0.34, 0.44, 0.07), CAR_RED)
    sb.box((0, SEAT_Y + 0.25, 1.35), (0.26, 0.08, 0.14), CAR_YELLOW,
           rotation=_rotx(-15))
    sb.box((0, SEAT_Y - 0.24, 1.35), (0.28, 0.07, 0.12), CAR_YELLOW,
           rotation=_rotx(15))

    # --- acoperamantul crupei: panza crem, tiv galben, ciucuri portocalii
    rump_y0, rump_y1 = -0.80, -0.36
    ry = (rump_y0 + rump_y1) * 0.5
    rl = rump_y1 - rump_y0
    # panza e o COAJA peste crupa (trunchiul reluat cu +2,5 cm), lasata sa
    # atarne: varfurile de sub axa se duc la latimea maxima si nu coboara
    # sub tiv. Prima varianta (cutie) statea pe crupa ca o lada.
    shell_y = [rump_y0 - 0.02, -0.66, rump_y1]
    shell_r = [0.20, 0.305, 0.335]
    shell = sb.taper_sweep([Vector((0, y, BODY_Z + 0.03)) for y in shell_y],
                           shell_r, CORAL_SAND, segments=10, cap_start=False,
                           cap_end=False)
    _squash(shell, sx=0.80, center=(0, 0, BODY_Z))
    hem_z = BODY_Z - 0.02
    for v in _verts(shell):
        if v.co.z < BODY_Z + 0.03:
            v.co.x = math.copysign(max(abs(v.co.x), 0.24), v.co.x or 1.0)
            v.co.z = max(v.co.z, hem_z)
    for sx in (-1, 1):
        sb.box((sx * 0.255, ry + 0.02, hem_z + 0.02), (0.03, rl - 0.04, 0.045),
               CAR_YELLOW)
        for k in range(5):
            t = (k + 0.5) / 5.0
            sb.frustum((sx * 0.255, rump_y0 + 0.04 + (rl - 0.06) * t,
                        hem_z - 0.05), 0.02, 0.01, 0.09, LAVA_ORANGE, segments=4)
        # motivul auriu brodat pe panza
        sb.box((sx * 0.27, ry + 0.02, BODY_Z + 0.14), (0.015, 0.16, 0.10),
               CAR_YELLOW, rotation=_roty(sx * -20))

    # --- capastrul, fraiele, ciucurii, colierul, panasul -----------------
    # nasarul: inel rosu in jurul botului (4 laturi)
    nz, ny = 1.43, 1.00
    sb.box((0, ny, nz + 0.075), (0.15, 0.05, 0.025), CAR_RED)
    sb.box((0, ny - 0.02, nz - 0.075), (0.13, 0.05, 0.025), CAR_RED)
    for sx in (-1, 1):
        sb.box((sx * 0.075, ny, nz), (0.025, 0.05, 0.15), CAR_RED)
        # obrazarul: de la nasar la ceafa
        sb.beam((sx * 0.08, ny - 0.02, nz + 0.05), (sx * 0.075, 0.76, 1.78),
                (0.025, 0.03), CAR_RED)
    # frontalul
    sb.box((0, 0.80, 1.78), (0.17, 0.04, 0.03), CAR_RED)
    # panasul intre urechi: con rosu cu varf portocaliu
    sb.frustum((0, 0.74, 1.90), 0.035, 0.05, 0.12, CAR_RED, segments=5)
    sb.frustum((0, 0.74, 2.00), 0.05, 0.0, 0.10, LAVA_ORANGE, segments=5)
    # ochiul impodobit (pata rosie pe tampla, ca pe decupare)
    for sx in (-1, 1):
        sb.box((sx * 0.086, 0.82, 1.71), (0.02, 0.04, 0.035), CAR_RED)
    # 3 ciucuri rosii sub falca / pe gat
    for k, (y, z) in enumerate([(0.86, 1.36), (0.78, 1.34), (0.70, 1.33)]):
        sb.frustum((0, y, z - 0.07), 0.028, 0.012, 0.14, CAR_RED, segments=4)
    # colierul de la baza gatului: 8 ciucuri colorati pe o curea rosie
    sb.box((0, 0.56, 1.16), (0.36, 0.05, 0.04), CAR_RED, rotation=_rotx(-35))
    col_slots = [FLAMINGO_PINK, TROPICAL_GREEN, CAR_YELLOW, FLAMINGO_PINK]
    for sx in (-1, 1):
        for k in range(4):
            y = 0.50 + 0.035 * k
            z = 1.10 - 0.04 * k
            sb.frustum((sx * (0.18 - 0.02 * k), y + 0.03, z - 0.08), 0.025,
                       0.012, 0.12, col_slots[k], segments=4)
    # fraiele: din nasar pana in mainile mirelui (verzi)
    hands_y, hands_z = 0.30, 1.62
    for sx in (-1, 1):
        sb.beam((sx * 0.08, ny + 0.02, nz), (sx * 0.07, hands_y, hands_z),
                (0.02, 0.02), TROPICAL_GREEN)
    # scarile (negre) sub talpile mirelui
    for sx in (-1, 1):
        sb.box((sx * 0.32, SEAT_Y + 0.14, 0.80), (0.08, 0.14, 0.03),
               VOLCANIC_BLACK)
        sb.beam((sx * 0.25, SEAT_Y + 0.02, 1.26), (sx * 0.32, SEAT_Y + 0.14, 0.81),
                (0.015, 0.02), VOLCANIC_BLACK)

    # --- MIRELE ----------------------------------------------------------
    hip = Vector((0, SEAT_Y, SEAT_Z + 0.06))
    # bazinul + coapsele: calare, genunchii in fata si pe laturi
    rb.box(hip, (0.34, 0.26, 0.14), CLOTH)
    for sx in (-1, 1):
        knee = Vector((sx * 0.30, SEAT_Y + 0.26, 1.22))
        ankle = Vector((sx * 0.31, SEAT_Y + 0.12, 0.88))
        _limb(rb, [Vector((sx * 0.12, SEAT_Y + 0.02, hip.z)), knee],
              [0.09, 0.075], CLOTH, seg=6)
        _limb(rb, [knee, ankle], [0.07, 0.055], CLOTH, seg=6)
        rb.box((sx * 0.32, SEAT_Y + 0.17, 0.84), (0.10, 0.22, 0.08), SHOE)
    # trunchiul: haina alba, drept, usor aplecat in fata
    torso = rb.taper_sweep([Vector((0, SEAT_Y, 1.42)),
                            Vector((0, SEAT_Y + 0.02, 1.68)),
                            Vector((0, SEAT_Y + 0.04, 1.92))],
                           [0.16, 0.15, 0.17], CLOTH, segments=8)
    _squash(torso, sy=0.70, center=(0, SEAT_Y, 1.7))
    # pelerina rosie: pe umeri + pe spate, cade peste sa pe crupa
    # pelerina: guler rotund pe umeri + panza care se muleaza pe spate si
    # cade peste sa (tub turtit care infasoara trunchiul pe jumatate)
    collar = rb.taper_sweep([Vector((0, SEAT_Y + 0.02, 1.86)),
                             Vector((0, SEAT_Y + 0.02, 1.97))],
                            [0.21, 0.13], CAR_RED, segments=8)
    _squash(collar, sy=0.72, center=(0, SEAT_Y + 0.02, 1.9))
    cape = rb.taper_sweep([Vector((0, SEAT_Y - 0.05, 1.88)),
                           Vector((0, SEAT_Y - 0.08, 1.60)),
                           Vector((0, SEAT_Y - 0.13, 1.30))],
                          [0.19, 0.20, 0.23], CAR_RED, segments=8)
    _squash(cape, sy=0.62, center=(0, SEAT_Y - 0.08, 1.6))
    # jumatatea din fata a pelerinei se taie inapoi pana la pieptul hainei:
    # ramane o panza care imbraca spatele si umerii, iar fata alba se vede
    for v in _verts(cape):
        v.co.y = min(v.co.y, SEAT_Y - 0.02 + 0.10 * (v.co.z - 1.3))
    # bratele: umar -> cot -> mana, inainte, tin fraiele
    for sx in (-1, 1):
        sh = Vector((sx * 0.20, SEAT_Y + 0.02, 1.88))
        el = Vector((sx * 0.22, SEAT_Y + 0.16, 1.66))
        ha = Vector((sx * 0.08, hands_y, hands_z + 0.02))
        # maneca de sus rosie (pelerina/haina rosie pe umar, ca pe decupare),
        # antebratul alb
        _limb(rb, [sh, el], [0.065, 0.055], CAR_RED, seg=5)
        _limb(rb, [el, ha], [0.05, 0.045], CLOTH, seg=5)
        rb.box(ha + Vector((0, 0.03, 0)), (0.07, 0.08, 0.07), SKIN)
    # gatul + capul + barba
    rb.frustum((0, SEAT_Y + 0.05, 1.99), 0.05, 0.05, 0.08, SKIN, segments=6)
    _head(rb, (0, SEAT_Y + 0.05, 2.12))
    # turbanul rosu inalt, cu bijuteria galbena in fata
    _turban(rb, (0, SEAT_Y + 0.05, 2.23), size=1.05)
    rb.box((0, SEAT_Y + 0.18, 2.32), (0.05, 0.02, 0.06), CAR_YELLOW)

    horse = hb.to_object("Horse")
    saddle = sb.to_object("Saddle")
    rider = rb.to_object("Rider")
    return horse, saddle, rider


def rig_horse(horse, saddle, rider, place):
    """Scheletul (reteta build_donkey.py): Body (radacina), Neck, Head, Tail
    si cate doua segmente pe fiecare picior. Mirele si valtrapul sunt pe
    Body (se leagana cu calul), capastrul pe Head, panglicile pe Tail."""
    def P(x, y, z):
        return Vector((x, y * SY, z)) + place

    bones = [
        dict(name="Body", head=P(0, -0.55, BODY_Z), tail=P(0, 0.45, BODY_Z)),
        dict(name="Neck", parent="Body", head=P(0, 0.46, 1.18),
             tail=P(0, 0.74, 1.66)),
        dict(name="Head", parent="Neck", head=P(0, 0.74, 1.74),
             tail=P(0, 1.06, 1.40)),
        dict(name="Tail", parent="Body", head=P(0, -0.82, 1.12),
             tail=P(0, -0.94, 0.70)),
    ]
    for sx, y0, knee, tag in ((-1, FRONT_Y, KNEE_F, "FL"), (1, FRONT_Y, KNEE_F, "FR"),
                              (-1, REAR_Y, HOCK_R, "RL"), (1, REAR_Y, HOCK_R, "RR")):
        x = sx * LEG_X
        bones.append(dict(name="Leg" + tag, parent="Body",
                          head=P(x, y0, HIP_Z), tail=P(x, y0, knee)))
        bones.append(dict(name="Shin" + tag, parent="Leg" + tag,
                          head=P(x, y0, knee), tail=P(x, y0, 0.0)))
    arm = make_armature("BaraatHorse", bones, mesh=horse)
    for m in (saddle, rider):
        m.parent = arm
        mod = m.modifiers.new("Armature", "ARMATURE")
        mod.object = arm

    counts = {}

    def put(mesh, island, name, root="Body", value=None, lo=0.0, hi=1.0):
        weight_ramp(mesh, island, name, root, value, lo, hi)
        counts[name] = counts.get(name, 0) + 1

    # coordonatele de CONSTRUCTIE (inainte de SY si de `place`)
    cy = lambda co: (co.y - place.y) / SY
    ncz = lambda co: -(co.z - place.z)
    ncy = lambda co: -(co.y - place.y) / SY

    def center(mesh, island):
        lo, hi = island_bbox(mesh, island)
        c = (lo + hi) * 0.5 - place
        size = hi - lo
        return Vector((c.x, c.y / SY, c.z)), Vector((size.x, size.y / SY, size.z)), hi.z - place.z

    for island in mesh_islands(horse):
        c, size, top = center(horse, island)
        if c.z < 0.80 and abs(abs(c.x) - LEG_X) < 0.08 and top < 0.99:
            tag = ("F" if c.y > 0 else "R") + ("L" if c.x < 0 else "R")
            if c.z > 0.60:
                # coapsa/antebratul: greutatea curge din Body spre Leg
                put(horse, island, "Leg" + tag, "Body", ncz,
                    -(HIP_Z - 0.02), -(HIP_Z - 0.20))
            else:
                put(horse, island, "Shin" + tag, "Shin" + tag)
        elif c.y > 0.68:
            put(horse, island, "Head", "Head")        # cap, urechi, ochi, mot
        elif c.y > 0.40 and c.z > 1.05:
            # gat + coama: se indoaie de la greaban
            put(horse, island, "Neck", "Body", cy, 0.46, 0.66)
        elif c.y < -0.82:
            put(horse, island, "Tail", "Body", ncy, 0.80, 0.90)
        else:
            put(horse, island, "Body", "Body")

    for island in mesh_islands(saddle):
        c, size, top = center(saddle, island)
        if c.y < -0.84 and c.z < 1.0:
            put(saddle, island, "Tail", "Body", ncy, 0.84, 0.92)  # panglicile
        elif size.y > 0.4 and size.z > 0.2 and c.y > 0.35 and c.z > 1.3:
            # fraiele: de la mainile mirelui (Body) pana in nasar (Head)
            put(saddle, island, "Head", "Body", cy, 0.45, 0.95)
        elif c.y > 0.66 and c.z > 1.25:
            put(saddle, island, "Head", "Head")     # capastru, panas, ciucuri
        elif c.y > 0.46 and c.z > 0.95:
            put(saddle, island, "Neck", "Body", cy, 0.46, 0.66)  # colierul
        else:
            put(saddle, island, "Body", "Body")
    for island in mesh_islands(rider):
        put(rider, island, "Body", "Body")
    print("  insule pe oase:", counts)
    return arm


def _axis_rot(x=0.0, y=0.0, z=0.0):
    return (Matrix.Rotation(math.radians(z), 3, "Z")
            @ Matrix.Rotation(math.radians(y), 3, "Y")
            @ Matrix.Rotation(math.radians(x), 3, "X"))


def _key_pose(arm, frame, pose):
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


SWING = 16.0
STANCE = 0.62


def _walk_leg(phase, hind):
    """(swing, knee) pentru un picior la faza data. Sprijin liniar inainte ->
    inapoi, balans cu genunchiul/jaretul indoit (copita se duce INAPOI si
    sus, la ambele perechi -- de aici semnul negativ)."""
    t = phase % 1.0
    if t < STANCE:
        u = t / STANCE
        return SWING - 2.0 * SWING * u, -2.0 - 3.0 * u
    u = (t - STANCE) / (1.0 - STANCE)
    swing = -SWING + 2.0 * SWING * u
    knee = -5.0 - (38.0 if not hind else 30.0) * math.sin(math.pi * u)
    return swing, knee


# Pasul calului e in PATRU timpi laterali: spate-stanga, fata-stanga,
# spate-dreapta, fata-dreapta, la cate un sfert de ciclu (nu in diagonala,
# ca magarul din build_donkey.py -- aia e reteta trapului).
WALK_PHASE = {"RL": 0.0, "FL": 0.25, "RR": 0.5, "FR": 0.75}


def animate_horse(arm):
    """Walk (24 cadre = 1 s) si Idle (72 cadre = 3 s).

    Potrivirea cu PathMover (fara root motion, nodul il misca PathMover):
      piciorul de la articulatie la copita L ~ 0,96 m, balans +/-16 grade
      -> maturarea copitei pe sol = 2 L sin(16) = 0,53 m, facuta in faza de
      sprijin (62% din ciclu). Corpul trece peste copita cu 0,53 / 0,62 =
      0,85 m pe ciclu, deci la animation_speed 1 viteza fara patinaj e
      **~0,85 m/s** (pasul unei procesiuni de nunta). Pe `model_scale` s,
      viteza creste cu s.
    """
    scene = bpy.context.scene
    scene.render.fps = 24
    if arm.animation_data is None:
        arm.animation_data_create()

    walk = bpy.data.actions.new("Walk")
    arm.animation_data.action = walk
    for frame in range(1, 26, 2):
        t = (frame - 1) / 24.0
        pose = {}
        for tag, ph in WALK_PHASE.items():
            sw, kn = _walk_leg(ph + t, tag.startswith("R"))
            pose["Leg" + tag] = ("rot", _axis_rot(x=sw))
            pose["Shin" + tag] = ("rot", _axis_rot(x=kn))
        # capul da din el de doua ori pe ciclu (o data pe fiecare pereche)
        pose["Neck"] = ("rot", _axis_rot(x=4.0 * math.sin(2.0 * math.tau * t)))
        pose["Head"] = ("rot", _axis_rot(x=-3.0 * math.sin(2.0 * math.tau * t)))
        # trunchiul (si mirele pe el) se leagana si salta usor
        pose["Body"] = [
            ("rot", _axis_rot(y=1.8 * math.sin(math.tau * t),
                              z=1.2 * math.sin(math.tau * t))),
            ("move", Vector((0, 0, 0.012 * math.cos(2.0 * math.tau * t)))),
        ]
        pose["Tail"] = ("rot", _axis_rot(x=2.0 * math.sin(math.tau * t),
                                         y=6.0 * math.sin(math.tau * t + 0.8)))
        _key_pose(arm, frame, pose)

    idle = bpy.data.actions.new("Idle")
    arm.animation_data.action = idle
    #  cadru  gat  cap  coada(yaw)
    phases = [(1, 0.0, 0.0, 0.0), (19, 6.0, 8.0, 10.0), (37, 2.0, -4.0, -8.0),
              (55, -3.0, 2.0, 6.0), (73, 0.0, 0.0, 0.0)]
    for frame, neck, head, tail in phases:
        pose = {"Neck": ("rot", _axis_rot(x=neck)),
                "Head": ("rot", _axis_rot(x=head)),
                "Tail": ("rot", _axis_rot(y=tail))}
        for tag in WALK_PHASE:
            pose["Leg" + tag] = ("rot", _axis_rot())
            pose["Shin" + tag] = ("rot", _axis_rot())
        _key_pose(arm, frame, pose)

    stash_actions(arm, ("Walk", "Idle"))
    for pb in arm.pose.bones:
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)


# ---------------------------------------------------------------------------
# 2. baraat_band
# ---------------------------------------------------------------------------

def _band_body(b, cx, stride=0.0, cape=False, lean=0.0):
    """Corpul comun al unui muzicant (1,8 m cu turbanul): pantofi, picioare,
    kurta lunga pana la genunchi (se evazeaza jos), cap cu barba, turban cu
    mot. Intoarce cotele umerilor si ale capului pentru brate/instrument."""
    # picioarele: `stride` > 0 = stangul (+X) inainte (pas de mars)
    for sx in (-1, 1):
        fy = stride * (1 if sx > 0 else -1)
        hipp = Vector((cx + sx * 0.09, 0.0, 0.92))
        foot = Vector((cx + sx * 0.11, fy, 0.10))
        _limb(b, [hipp, foot], [0.085, 0.07], CLOTH, seg=5)
        b.box((cx + sx * 0.11, fy + 0.05, 0.04), (0.10, 0.25, 0.08), SHOE)
    # kurta: fusta evazata pana la genunchi, piept, umeri
    k = b.taper_sweep([Vector((cx, 0.0, 0.56)), Vector((cx, 0.0, 0.95)),
                       Vector((cx, lean * 0.3, 1.28)),
                       Vector((cx, lean, 1.46))],
                      [0.25, 0.19, 0.20, 0.21], CLOTH, segments=8)
    _squash(k, sy=0.72, center=(cx, 0.0, 1.0))
    # cap MARE, de jucarie: pe decupare capul + turbanul fac ~ 1/4 din
    # inaltime; la scara 1 figurile ieseau filiforme
    head_c = Vector((cx, lean + 0.01, 1.58))
    _head(b, head_c, size=1.2)
    _turban(b, head_c + Vector((0, 0, 0.13)), size=1.2)
    shoulders = (Vector((cx - 0.21, lean, 1.42)), Vector((cx + 0.21, lean, 1.42)))
    if cape:
        # pelerina rosie: de pe umeri, in spate, pana la genunchi, evazata
        c = b.taper_sweep([Vector((cx, lean - 0.10, 1.46)),
                           Vector((cx, -0.16, 1.00)),
                           Vector((cx, -0.22, 0.58))],
                          [0.20, 0.25, 0.29], CAR_RED, segments=6)
        _squash(c, sy=0.30, center=(cx, -0.16, 1.0))
    return shoulders, head_c


def build_baraat_band():
    """baraat_band -- lista de elemente de pe decupare (baraat_band.png):

    4 figuri pe un rand, fata spre privitor (+Y), cam 1 m intre ele,
    TOATE cu: turban ROSU cu mot in varf, barba neagra, kurta ALBA/crem
    lunga pana la genunchi, pantaloni albi, pantofi NEGRI.
    De la stanga la dreapta pe decupare:
      1. TOBOSARUL CU DHOL MARE: in pas (piciorul din fata inainte),
         PELERINA ROSIE pe umeri si in spate pana la genunchi, dhol-ul
         culcat pe burta (butoi de lemn MARO, doua fete ALBE, ~0,55 m
         diametru), o mana cu bata pe fata tobei;
      2. TROMPETISTUL: drept, trompeta GALBENA (aurie) la gura, inainte si
         usor in sus, palnia larga; esarfa rosie la gat, curea MARO cu
         catarama galbena;
      3. TOBOSARUL CU TOBA MICA: pelerina rosie, toba mica (maro, fata
         alba, ~0,35 m) la brau, inclinata spre privitor, mainile pe ea;
      4. AL PATRULEA: drept, stola ROSIE pe umeri in V, curea maro, mainile
         la sold (brau), impreunate in fata pe un obiect mic maro.
    Iese din contur: dhol-ul (lateral), trompeta (inainte), pelerinele.
    Cote: rand de 4 m, figuri de 1,8 m, <= 400 tri fiecare.
    """
    nodes = []
    # ordinea pe decupare de la stanga la dreapta; camera de comparatie sta
    # pe +Y, deci stanga imaginii e +X.
    X = [1.5, 0.5, -0.5, -1.5]

    # 1. dhol -------------------------------------------------------------
    b = Builder()
    cx = X[0]
    sh, hc = _band_body(b, cx, stride=0.20, cape=True, lean=0.03)
    drum_c = Vector((cx - 0.02, 0.30, 1.00))
    # dhol-ul culcat, axa pe X rotita 25 grade: fata +X se intoarce spre
    # privitor, ca pe decupare. Butoiul de lemn e mai scurt; cilindrul alb,
    # mai lung, iese din el la ambele capete = cele doua fete ale tobei.
    faces = b.cylinder((0, 0, 0), 0.28, 0.34, WOOD, segments=8, axis="X")
    faces |= b.cylinder((0, 0, 0), 0.255, 0.42, CLOTH, segments=8, axis="X")
    m = Matrix.Translation(drum_c) @ _rotz(25.0).to_4x4()
    for v in _verts(faces):
        v.co = m @ v.co
    face_p = m @ Vector((0.22, 0.0, 0.02))      # centrul fetei +X
    back_p = m @ Vector((-0.22, 0.0, 0.08))
    # bratul stang (+X) cu bata pe fata tobei, dreptul pe cealalta fata
    _limb(b, [sh[1], Vector((cx + 0.30, 0.10, 1.20)), face_p + Vector((0.04, 0.02, 0.10))],
          [0.055, 0.05, 0.045], CLOTH)
    b.box(face_p + Vector((0.04, 0.02, 0.10)), (0.07, 0.07, 0.07), SKIN)
    b.beam(face_p + Vector((0.04, 0.02, 0.10)), face_p + Vector((0.02, 0.04, -0.08)),
           0.025, WOOD)
    _limb(b, [sh[0], Vector((cx - 0.28, 0.12, 1.20)), back_p + Vector((-0.02, 0.0, 0.0))],
          [0.055, 0.05, 0.045], CLOTH)
    b.box(back_p + Vector((-0.02, 0.0, 0.0)), (0.07, 0.07, 0.07), SKIN)
    nodes.append(("Band_Dhol", b))

    # 2. trompetist ------------------------------------------------------
    b = Builder()
    cx = X[1]
    sh, hc = _band_body(b, cx)
    # esarfa rosie: doua capete in fata
    for sx in (-1, 1):
        b.box((cx + sx * 0.07, 0.11, 1.26), (0.07, 0.03, 0.34), CAR_RED,
              rotation=_roty(sx * 8))
    # cureaua maro + catarama galbena
    b.box((cx, 0.0, 0.98), (0.36, 0.26, 0.06), WOOD)
    b.box((cx, 0.135, 0.98), (0.07, 0.02, 0.08), CAR_YELLOW)
    # trompeta: tubul din gura spre inainte-sus, palnia larga
    mouth = hc + Vector((0, 0.10, -0.04))
    bell = mouth + Vector((0.05, 0.40, 0.14))
    b.taper_sweep([mouth, bell], [0.02, 0.03], CAR_YELLOW, segments=5)
    d = (bell - mouth).normalized()
    b.taper_sweep([bell - d * 0.02, bell + d * 0.12], [0.03, 0.10], CAR_YELLOW,
                  segments=8, cap_start=False)
    # bratele ridicate la trompeta
    for sx, t in ((-1, 0.35), (1, 0.65)):
        p = mouth.lerp(bell, t) + Vector((0, 0, -0.04))
        _limb(b, [sh[0] if sx < 0 else sh[1],
                  Vector((cx + sx * 0.24, 0.10, 1.26)), p],
              [0.055, 0.05, 0.045], CLOTH)
        b.box(p, (0.07, 0.07, 0.07), SKIN)
    nodes.append(("Band_Trumpet", b))

    # 3. toba mica ---------------------------------------------------------
    b = Builder()
    cx = X[2]
    sh, hc = _band_body(b, cx, cape=True)
    tc = Vector((cx + 0.02, 0.27, 1.00))
    tilt = _rotx(-35.0)
    faces = b.cylinder((0, 0, 0), 0.18, 0.22, WOOD, segments=8, axis="Z")
    faces |= b.cylinder((0, 0, 0.012), 0.165, 0.225, CLOTH, segments=8, axis="Z")
    m = Matrix.Translation(tc) @ tilt.to_4x4()
    for v in _verts(faces):
        v.co = m @ v.co
    for sx in (-1, 1):
        hand = tc + Vector((sx * 0.17, -0.02, 0.06))
        _limb(b, [sh[0] if sx < 0 else sh[1],
                  Vector((cx + sx * 0.24, 0.02, 1.16)), hand],
              [0.055, 0.05, 0.045], CLOTH)
        b.box(hand, (0.07, 0.07, 0.07), SKIN)
    nodes.append(("Band_SmallDrum", b))

    # 4. mainile la brau ---------------------------------------------------
    b = Builder()
    cx = X[3]
    sh, hc = _band_body(b, cx)
    # stola rosie in V: doua benzi de pe umeri pana la brau, in fata
    for sx in (-1, 1):
        b.beam((cx + sx * 0.13, 0.08, 1.44), (cx + sx * 0.05, 0.14, 0.96),
               (0.08, 0.025), CAR_RED)
    b.box((cx, 0.0, 0.98), (0.36, 0.26, 0.06), WOOD)
    # mainile impreunate in fata, pe un obiect mic maro (la brau)
    obj_c = Vector((cx, 0.20, 1.02))
    b.box(obj_c, (0.20, 0.10, 0.10), WOOD)
    for sx in (-1, 1):
        hand = obj_c + Vector((sx * 0.10, 0.02, 0.02))
        _limb(b, [sh[0] if sx < 0 else sh[1],
                  Vector((cx + sx * 0.24, 0.02, 1.16)), hand],
              [0.055, 0.05, 0.045], CLOTH)
        b.box(hand, (0.07, 0.07, 0.07), SKIN)
    nodes.append(("Band_Hands", b))

    objs = []
    for name, bb in nodes:
        objs.append(bb.to_object(name))
    return objs


# ---------------------------------------------------------------------------
# 3. zipline_rider
# ---------------------------------------------------------------------------

def build_zipline_rider():
    """zipline_rider -- lista de elemente de pe decupare (zipline_rider.png):

    Vazut din lateral, mergand spre DREAPTA (inainte = +Y):
      - SCRIPETELE: carucior rotund gri pe cablu (cablul NU e in GLB), doua
        roti mici in tandem intre doua flancuri rotunde, sub el o bucla si
        o carabiniera;
      - LONJA (chinga scurta) coboara aproape vertical din scripete pana la
        ham; AMBELE MAINI o prind sus, una peste alta, la ~0,4 m sub
        scripete, coatele indoite in fata;
      - CASCA GALBENA pe cap, capul in spatele lonjei (-Y), putin sub maini;
        par/barba scurta inchisa sub casca;
      - trunchiul inclinat pe spate (~30 grade), BLUZA ROSIE cu maneci lungi;
      - HAMUL negru: centura la talie, bretele peste umeri, bucle pe coapse;
      - picioarele INAINTE: coapsele aproape orizontale spre +Y, gambele in
        jos-inainte; pantaloni ALBASTRI (blugi -> PAINTED), bocanci MARO;
      - talpile sunt cel mai jos punct, ~1,65 m sub scripete (masurat pe
        GLB; brief-ul initial cerea 2,2 m, vezi mai jos).
    Originea = punctul in care cablul atinge rotita (varful scripetelui), ca
    `PathMover` cu `stick_to_ground = false` sa-l aseze exact pe curba.
    """
    pb = Builder()   # scripetele + lonja (metal, chinga)
    rb = Builder()   # omul
    METAL = MARBLE_GREY
    # scripetele = caruciorul ROTUND de pe decupare: doua roti mici in
    # tandem pe cablu (varful lor = origine), prinse intre doua flancuri
    # rotunde (discuri), cu axele iesite. Prima varianta era o cutie.
    for wy in (-0.055, 0.055):
        pb.cylinder((0, wy, -0.035), 0.035, 0.03, VOLCANIC_BLACK, segments=10,
                    axis="X")
        pb.cylinder((0, wy, -0.035), 0.012, 0.10, METAL, segments=6, axis="X")
    for sx in (-1, 1):
        pb.cylinder((sx * 0.03, 0, -0.10), 0.10, 0.018, METAL, segments=12,
                    axis="X")
    # bucla de sub carucior + carabiniera
    pb.box((0, 0, -0.215), (0.07, 0.03, 0.05), METAL)
    pb.box((0, 0, -0.28), (0.02, 0.06, 0.09), METAL)
    # POZA E CEA DE PE DECUPARE: omul STA in ham ca pe un scaun -- trunchiul
    # lasat pe spate ~35 grade, coapsele INAINTE si putin in sus (genunchii
    # mai sus decat soldul), un picior cu gamba in jos, celalalt mai
    # intins. Prima varianta (trunchi aproape vertical, picioare atarnand
    # la 45 grade) citea om spanzurat, nu tiroliana. Pe decupare figura e
    # desenata mai mare decat 1,7 m fata de lonja; aici figura are 1,7 m
    # (brief), iar lonja are lungimea de pe decupare (vezi hip_c).
    # Lonja SCURTA, ca pe decupare: mainile prind chingile la ~0,45 m sub
    # roata, capul e la o lungime de brat sub ea. Cota initiala din brief
    # (2,2 m pana la talpi) cerea o lonja de ~1,4 m care se citea ca o
    # prajina -- planșa castiga, nicio dependenta in cod (verdictul liderului).
    hip_c = Vector((0, 0.0, -1.17))
    sh_c = hip_c + Vector((0, -0.30, 0.43))       # umerii, lasati pe spate
    harness_pt = hip_c + Vector((0, 0.10, 0.08))
    # lonja: de la carabiniera pana la ham (in fata taliei)
    pb.beam((0, 0.0, -0.32), harness_pt, (0.045, 0.012), LOG_DARK)

    # --- omul -------------------------------------------------------------
    torso = rb.taper_sweep([hip_c + Vector((0, 0.02, -0.04)), hip_c.lerp(sh_c, 0.5),
                            sh_c + Vector((0, -0.01, 0.04))],
                           [0.15, 0.15, 0.17], CAR_RED, segments=8)
    _squash(torso, sx=1.0, sy=0.72, center=hip_c.lerp(sh_c, 0.5))
    # capul in casca, deasupra umerilor, privind inainte
    head_c = sh_c + Vector((0, 0.03, 0.21))
    rb.frustum(head_c + Vector((0, 0, -0.14)), 0.05, 0.05, 0.08, SKIN, segments=6)
    _head(rb, head_c, face_dir=(0, 1, 0.2), beard=True)
    # casca galbena: calota + borul
    rb.revolve([(0.125, 0.0), (0.12, 0.05), (0.09, 0.11), (0.0, 0.14)],
               CAR_YELLOW, segments=8, origin=tuple(head_c + Vector((0, 0, 0.06))))
    rb.cylinder(head_c + Vector((0, 0.02, 0.065)), 0.135, 0.02, CAR_YELLOW,
                segments=8)
    # bratele: umar -> cot (in fata) -> mainile pe lonja, una peste alta, la
    # inaltimea capului
    lan = lambda z: Vector((0, 0.0, -0.32)).lerp(
        harness_pt, (z + 0.32) / (harness_pt.z + 0.32))
    grips = (lan(hip_c.z + 0.70), lan(hip_c.z + 0.58))
    for sx, grip in ((1, grips[0]), (-1, grips[1])):
        shp = sh_c + Vector((sx * 0.19, 0, 0))
        elbow = shp.lerp(grip, 0.5) + Vector((sx * 0.08, 0.10, -0.08))
        _limb(rb, [shp, elbow, grip + Vector((sx * 0.03, -0.02, 0))],
              [0.055, 0.05, 0.045], CAR_RED)
        rb.box(grip + Vector((sx * 0.02, 0, 0)), (0.07, 0.07, 0.08), SKIN)
    # picioarele: coapse inainte si putin in sus, gambe in jos, bocanci
    legs = {
        1: (hip_c + Vector((0.12, 0.43, 0.08)), Vector((0, 0.12, -0.42))),
        -1: (hip_c + Vector((-0.12, 0.40, 0.02)), Vector((0, 0.30, -0.31))),
    }
    for sx in (-1, 1):
        hipp = hip_c + Vector((sx * 0.10, 0.02, 0))
        knee, shin = legs[sx]
        ankle = knee + shin
        _limb(rb, [hipp, knee], [0.085, 0.07], PAINTED, seg=6)
        _limb(rb, [knee, ankle], [0.065, 0.055], PAINTED, seg=6)
        tilt = -math.degrees(math.atan2(shin.y, -shin.z)) * 0.6
        rb.box(ankle + Vector((0, 0.05, -0.06)), (0.11, 0.24, 0.12), WOOD,
               rotation=_rotx(tilt))
    # hamul: centura, bretele, bucle pe coapse (negre)
    belt = rb.taper_sweep([hip_c + Vector((0, 0.0, 0.04)),
                           hip_c + Vector((0, -0.03, 0.12))],
                          [0.165, 0.165], LOG_DARK, segments=8)
    _squash(belt, sy=0.74, center=hip_c)
    for sx in (-1, 1):
        rb.beam(hip_c + Vector((sx * 0.08, 0.12, 0.10)),
                sh_c + Vector((sx * 0.10, 0.11, 0.02)), (0.04, 0.02), LOG_DARK)
        a2 = hip_c + Vector((sx * 0.10, 0.02, 0))
        k = legs[sx][0]
        loop_c = a2.lerp(k, 0.3)
        rb.taper_sweep([loop_c - (k - a2).normalized() * 0.03,
                        loop_c + (k - a2).normalized() * 0.03],
                       [0.095, 0.095], LOG_DARK, segments=6)
    pulley = pb.to_object("Zip_Pulley")
    rider = rb.to_object("Zip_Rider")
    return pulley, rider


# ---------------------------------------------------------------------------

if __name__ == "__main__":
    clear_built()

    # 1. calul ---------------------------------------------------------------
    horse, saddle, rider = build_baraat_horse()
    for o in (horse, saddle):
        for v in o.data.vertices:
            v.co.y *= SY
    objs = [horse, saddle, rider]
    place, tris = _finish_assembly(objs, AO_HORSE, bevel=0.0, smooth_angle=50.0)
    print("  deplasarea ansamblului: %.3f %.3f %.3f" % tuple(place))
    arm = rig_horse(horse, saddle, rider, place)
    animate_horse(arm)
    bpy.context.view_layer.update()
    _report("animals/baraat_horse.glb", objs, tris)
    print("GLB:  ", export_glb([arm] + objs, "jodhpur/animals/baraat_horse.glb",
                               animations=True))
    print("BLEND:", save_blend([arm] + objs, "jodhpur_baraat_horse.blend",
                               compress=True))

    # 2. fanfara -------------------------------------------------------------
    band = build_baraat_band()
    _, tris = _finish_assembly(band, AO_FIG, bevel=0.0, smooth_angle=50.0)
    # inaltimea contractului e 1,8 m: capul mare de jucarie + motul
    # turbanului ies ~1,92 m; se comprima doar pe Z (6%), ca randul sa
    # ramana de ~3,6 m + instrumente
    _, _, bz = _all_coords(band)
    kz = 1.80 / max(bz)
    for o in band:
        for v in o.data.vertices:
            v.co.z *= kz
    _report("props/baraat_band.glb", band, tris, budget=400)
    print("GLB:  ", export_glb(band, "jodhpur/props/baraat_band.glb"))

    # 3. tiroliana -----------------------------------------------------------
    zip_objs = list(build_zipline_rider())
    _, tris = _finish_assembly(zip_objs, AO_FIG, bevel=0.0, smooth_angle=50.0,
                               place=Vector((0, 0, 0)))
    _report("props/zipline_rider.glb", zip_objs, tris)
    print("GLB:  ", export_glb(zip_objs, "jodhpur/props/zipline_rider.glb"))

    save_blend(band + zip_objs, "jodhpur_theatre.blend")

    print()
    for path, total, tr, dims, zr, budget in results:
        print("%-32s %6d tri  %s" % (path, total,
              ", ".join("%s=%d" % kv for kv in tr.items())))
        print("    %.2f (X) x %.2f (Y) x %.2f (Z) m, z %.3f..%.3f"
              % (dims[0], dims[1], dims[2], zr[0], zr[1]))
        if budget:
            over = [k for k, v in tr.items() if v > budget]
            print("    buget %d/figura: %s" % (budget, "DEPASIT " + str(over)
                                               if over else "OK"))
