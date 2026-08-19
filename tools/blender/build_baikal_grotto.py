"""Baikal — grota de gheata + biserica din Khuzhir (planşa, pozitiile 5 si 6).

  IceGrottoArch  structures/ice_grotto_arch.glb
                 Grotto_Rock / Grotto_Ice / Icicle_A..D
  KhuzhirChurch  buildings/khuzhir_church.glb
                 Church_Body / Church_Roof / Church_Dome

Grota (POI D, fractia 0.55) e un TUNEL SCURT prin care trece pista: 12 m
deschidere, 9 m inaltime, 25 m adancime. Ca si la tunelul feroviar, ce se vede
e interiorul — dar aici, spre deosebire de tunel, si silueta EXTERIOARA conteaza
(e capul stancos al insulei, vazut de pe gheata de la distanta), deci arcada are
volum real, nu doar captuseala.

Cei 4 turturi detasabili (`Icicle_A..D`) sunt piese separate fiindca pista ii
foloseste ca obstacol care CADE la trecere (brief §3) — trebuie sa fie noduri
independente, nu geometrie lipita de arcada.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_baikal_grotto.py
"""

import math
from mathutils import Matrix, Vector

AO_ROCK = dict(samples=30, dist=7.0, gradient="vertical",
               low=0.32, high=1.00, power=0.95, floor=0.08)
AO_ICE = dict(samples=24, dist=4.0, gradient="vertical",
              low=0.55, high=1.00, power=0.8, floor=0.25)
AO_BUILD = dict(samples=28, dist=5.0, gradient="vertical",
                low=0.45, high=1.00, power=0.9, floor=0.12)

GROTTO_W = 12.0      # deschidere libera
GROTTO_H = 9.0       # inaltime la cheie
GROTTO_D = 25.0      # adancime


def _icicle(b, anchor, length, radius, slot=ICE_TURQUOISE, segments=6,
            taper=0.10):
    """Turture: con ingust care atarna din `anchor` in jos."""
    return b.frustum((anchor[0], anchor[1], anchor[2] - length * 0.5),
                     radius, radius * taper, length, slot, segments=segments)


# ============================================================ Grota de gheata
def build_grotto():
    clear_built()
    half = GROTTO_W * 0.5
    spring = GROTTO_H - half * 0.75      # bolta usor turtita, nu semicerc

    # --- masa de stanca ----------------------------------------------------
    # Peretii sunt volume de roca reale (se vad si din afara), cu golul lasat
    # intre ei. Boltta de deasupra leaga cei doi pereti.
    b = Builder()
    # Peretii: blocuri de roca suprapuse. `rock` cu taper mic lateste inelele
    # de la baza, iar la piese asezate direct pe sol asta iese ca o ARIPA
    # turtita in jurul lor (vizibil in prima randare de control). Le ingropam
    # cu 0.6 m sub zero si le dam taper mai mare: partea evazata ramane sub
    # pamant, la vedere ramane doar peretele.
    for sx in (-1, 1):
        for i in range(4):
            t = i / 3.0
            w = 6.4 - 2.0 * t
            b.rock((sx * (half + w * 0.5 - 0.5), GROTTO_D * 0.5,
                    spring * t * 0.92 - 0.6),
                   (w, GROTTO_D * (1.02 - 0.05 * i), spring * 0.48),
                   MARBLE_GREY, seed=1500 + i * 37 + (0 if sx < 0 else 91),
                   segments=7, rings=3, taper=0.42, squash=0.9)
    # bolta: blocuri de roca pe arc, rotite pe tangenta (aceeasi regula ca la
    # viaduct — unghiul polar, nu complementul lui)
    n = 11
    for i in range(n):
        a = math.pi * (i + 0.5) / n
        cx = -math.cos(a) * (half + 1.1)
        cz = spring + math.sin(a) * (half * 0.75 + 1.1)
        rot = Matrix.Rotation(a, 3, "Y")
        b.box((cx, GROTTO_D * 0.5, cz), (2.2, GROTTO_D,
                                         (math.pi * half / n) * 1.15),
              MARBLE_GREY, rotation=rot)
    # creasta de deasupra: da silueta de cap stancos vazut de pe lac
    rand = _lcg(6060)
    for i in range(5):
        b.rock((-4.0 + i * 2.2 + rand() * 1.5, GROTTO_D * (0.2 + rand() * 0.6),
                spring + half * 0.75 + 0.5),
               (5.0 + rand() * 3.0, 6.0 + rand() * 4.0, 2.0 + rand() * 3.5),
               MARBLE_GREY, seed=700 + i * 53, segments=7, rings=3,
               taper=0.40, squash=0.85)
    rock = b.to_object("Grotto_Rock")
    finish(rock, bevel=0.08, ao=AO_ROCK, origin=None)

    # --- gheata: draperii pe pereti + turturi mici la intrados -------------
    # "Draperiile" sunt ce face grota sa fie de GHEATA, nu o pestera oarecare:
    # valuri verticale inghetate pe perete, late si neregulate.
    b = Builder()
    rand = _lcg(3131)
    for i in range(30):
        yy = 1.0 + rand() * (GROTTO_D - 2.0)
        sx = -1 if rand() > 0.5 else 1
        h = 2.0 + rand() * (spring * 0.85)
        w = 0.7 + rand() * 1.6
        # Draperia sta pe FATA INTERIOARA a peretelui (x = half - 0.5),
        # iesind spre gol cu jumatate din latimea ei. Prima versiune o punea
        # la half - 0.25, adica 25 cm in INTERIORUL rocii: gheata exista in
        # numaratoare, dar nu se vedea nicaieri — grota iesea o arcada de
        # piatra seaca, adica exact ce nu e.
        b.frustum((sx * (half - 0.5 - w * 0.30), yy, h * 0.5),
                  w * 0.80, w * 0.45, h, ICE_TURQUOISE, segments=6)
    # turturi mici (fixe) la intrados, deasupra benzii de rulare
    for i in range(16):
        a = math.pi * (0.15 + 0.7 * rand())
        ix = -math.cos(a) * half * 0.92
        iz = spring + math.sin(a) * half * 0.62
        _icicle(b, (ix, 0.8 + rand() * (GROTTO_D - 1.6), iz),
                length=0.5 + rand() * 1.4, radius=0.07 + rand() * 0.07)
    # gheata pe podea, la marginile golului
    for i in range(10):
        b.rock((( -1 if rand() > 0.5 else 1) * (half - 0.8 - rand() * 1.5),
                rand() * GROTTO_D, 0.0),
               (1.6 + rand() * 1.4, 2.0 + rand() * 2.5, 0.35 + rand() * 0.5),
               ICE_DEEP, seed=210 + i * 29, segments=6, rings=2, taper=0.6,
               squash=0.7)
    ice = b.to_object("Grotto_Ice")
    finish(ice, bevel=0.03, ao=AO_ICE, origin=None)

    # --- cei 4 turturi DETASABILI (obstacol care cade) ---------------------
    # Noduri separate: pista ii desprinde la trecerea masinii (brief §3).
    # Origine la VARFUL de sus (punctul de agatare), ca sa poata fi rotiti in
    # cadere in jurul prinderii, nu in jurul mijlocului.
    drops = []
    for k, (dx, dy, length) in enumerate((
            (-2.6, 6.0, 2.6), (1.8, 11.0, 3.1),
            (-1.2, 16.5, 2.2), (2.9, 21.0, 2.8))):
        b = Builder()
        _icicle(b, (0.0, 0.0, 0.0), length, radius=0.20, segments=7)
        obj = b.to_object("Icicle_%s" % "ABCD"[k])
        finish(obj, bevel=0.02, ao=AO_ICE, origin=None)
        # originea la agatare (z=0), varful in jos
        set_origin_at(obj, Vector((0.0, 0.0, 0.0)))
        obj.location = Vector((dx, dy, spring + 2.0))
        drops.append(obj)

    objs = [rock, ice] + drops
    _drop_to_zero(objs)
    print("IceGrottoArch: %d tris (%s)"
          % (sum(tri_count(o) for o in objs),
             ", ".join("%s %d" % (o.name, tri_count(o)) for o in objs)))
    export_glb(objs, "structures/ice_grotto_arch.glb")
    save_blend(objs, "baikal_ice_grotto.blend")
    return objs


def _drop_to_zero(objs):
    """Coboara grupul ca minimul comun sa cada la z=0, pastrand pozitiile relative."""
    bpy.context.view_layer.update()
    lo = min(min((o.matrix_world @ Vector(c)).z for c in o.bound_box)
             for o in objs)
    for o in objs:
        o.location.z -= lo


# ============================================================ Biserica
# 9x7 m corp, turla 12 m, cupola albastra cu cruce. POI-ul de sosire (fractia
# 1.00) — se vede din fata, de pe ulita satului, deci fata "de prezentare" e
# spre +Y in Blender (= -Z in Godot), ca la toate cladirile din proiect.

def build_church():
    clear_built()

    # --- corpul: nava de barne + pridvor -----------------------------------
    b = Builder()
    # nava: 9 m pe X, 7 m pe Y. Zid de barne orizontale — randurile se vad,
    # asa se deosebeste o casa siberiana de o cutie tencuita.
    _log_wall(b, center=(0.0, -1.0, 0.0), size=(9.0, 7.0, 4.2), seed=41)
    # fronton + acoperis in doua ape, cu streasina generoasa (zapada)
    b.prism([(-4.5, 4.2), (0.0, 6.4), (4.5, 4.2)], 7.0, LOG_DARK,
            center=(0.0, -1.0, 0.0))
    _roof(b, half_w=4.5, eave_z=4.2, ridge_z=6.4, depth=7.0, y_center=-1.0,
          slot=VOLCANIC_BLACK, overhang=0.65)
    # pridvorul din fata (+Y)
    b.box((0.0, 3.1, 1.35), (3.4, 1.6, 2.7), LOG_DARK)
    _roof(b, half_w=1.9, eave_z=2.7, ridge_z=3.5, depth=1.9, y_center=3.1,
          slot=VOLCANIC_BLACK, overhang=0.35)
    # soclu de piatra
    b.box((0.0, -1.0, 0.18), (9.4, 7.4, 0.36), MARBLE_GREY)
    body = b.to_object("Church_Body")
    finish(body, bevel=0.04, ao=AO_BUILD, origin=None)

    # --- turnul + acoperisul lui -------------------------------------------
    b = Builder()
    tower_y = 1.6
    _log_wall(b, center=(0.0, tower_y, 0.0), size=(3.4, 3.4, 8.4), seed=88)
    # cornisa de sub cupola
    b.box((0.0, tower_y, 8.55), (4.0, 4.0, 0.3), FOAM_WHITE)
    roof = b.to_object("Church_Roof")
    finish(roof, bevel=0.04, ao=AO_BUILD, origin=None)

    # --- cupola de ceapa + cruce -------------------------------------------
    # Silueta de ceapa e semnatura bisericii ruse. Se face cu `revolve` pe un
    # profil: umflatura la ~35% din inaltime, apoi gat ingust si varf.
    b = Builder()
    # ATENTIE: `revolve` se OPRESTE la prima raza <= 0 si o transforma in apex.
    # Profilul trebuie deci sa inceapa cu o raza POZITIVA (baza cupolei) si sa
    # aiba zero-ul doar la SFARSIT. Prima versiune incepea cu (0.00, 0.00) —
    # apexul se crea imediat, bucla se rupea la primul punct si din cupola
    # iesea un disc plat, cu crucea plutind detasata deasupra. Se vedea in
    # randarea de control; numaratoarea de triunghiuri (292) trecea nestingher.
    prof = [(0.55, 0.00), (0.95, 0.30), (1.35, 0.85), (1.30, 1.45),
            (0.95, 2.05), (0.45, 2.50), (0.16, 2.80), (0.00, 3.00)]
    b.revolve(prof, PAINTED, segments=10, origin=(0.0, tower_y, 8.7))
    # tamburul de sub cupola
    b.cylinder((0.0, tower_y, 8.85 - 0.15), 1.05, 0.5, FOAM_WHITE, segments=10)
    # crucea ortodoxa: bara verticala + doua traverse (a treia, oblica, e
    # detaliul care o face ortodoxa si nu latina)
    cz = 8.7 + 3.0
    b.box((0.0, tower_y, cz + 0.55), (0.07, 0.07, 1.1), PAINTED)
    b.box((0.0, tower_y, cz + 0.92), (0.46, 0.07, 0.07), PAINTED)
    b.box((0.0, tower_y, cz + 0.45), (0.62, 0.07, 0.07), PAINTED)
    b.box((0.0, tower_y, cz + 0.16), (0.44, 0.07, 0.07), PAINTED,
          rotation=Matrix.Rotation(math.radians(22.0), 3, "Y"))
    dome = b.to_object("Church_Dome")
    finish(dome, bevel=0.02, ao=AO_BUILD, origin=None)

    objs = [body, roof, dome]
    _drop_to_zero(objs)
    print("KhuzhirChurch: %d tris (%s)"
          % (sum(tri_count(o) for o in objs),
             ", ".join("%s %d" % (o.name, tri_count(o)) for o in objs)))
    export_glb(objs, "buildings/khuzhir_church.glb")
    save_blend(objs, "baikal_khuzhir_church.blend")
    return objs


def _log_wall(b, center, size, seed, slot=LOG_DARK, log_h=0.42):
    """Zid de barne orizontale: randuri de cilindri turtiti, cu capete iesite.

    Randul de barne E identitatea arhitecturii siberiene si singurul lucru care
    deosebeste casele de aici de niste cutii maro. Se face din cutii, nu din
    cilindri: la 40 cm diametru si distanta de joc, sectiunea rotunda nu se
    citeste, dar ar tripla triunghiurile.
    """
    cx, cy, cz = center
    sx, sy, sz = size
    rows = max(int(sz / log_h), 1)
    h = sz / rows
    rand = _lcg(seed)
    for i in range(rows):
        z = cz + h * (i + 0.5)
        # fiecare barna iese cu cativa cm — umbra dintre randuri le desparte
        d = 0.04 + rand() * 0.05
        b.box((cx, cy, z), (sx + d, sy + d, h * 0.93), slot)
    # capetele incrucisate la colturi (imbinarea "in coada de randunica")
    for i in range(0, rows, 2):
        z = cz + h * (i + 0.5)
        b.box((cx, cy, z), (sx + 0.55, sy * 0.16, h * 0.9), slot)
        b.box((cx, cy, z), (sx * 0.16, sy + 0.55, h * 0.9), slot)


def _roof(b, half_w, eave_z, ridge_z, depth, y_center, slot, overhang=0.6,
          thickness=0.18, snow=True):
    """Doua placi de acoperis cu streasina, plus stratul de zapada de deasupra."""
    rise = ridge_z - eave_z
    ang = math.atan2(rise, half_w)
    slope = math.hypot(half_w + overhang, rise * (1.0 + overhang / half_w))
    length = slope + 0.4
    for sgn in (-1.0, 1.0):
        rot = Matrix.Rotation(sgn * ang, 3, "Y")
        t = length * 0.5 - 0.2
        mx = sgn * t * math.cos(ang)
        mz = ridge_z - t * math.sin(ang) + thickness * 0.35
        b.box((mx, y_center, mz), (length, depth + 2 * overhang, thickness),
              slot, rotation=rot)
        if snow:
            # Zapada e un strat SUBTIRE peste placa, retras de la streasina:
            # zapada care ajunge fix pana in marginea acoperisului arata ca o
            # a doua placa vopsita alb.
            b.box((mx, y_center, mz + thickness * 0.75),
                  (length * 0.93, depth + 2 * overhang * 0.82, thickness * 0.55),
                  FOAM_WHITE, rotation=rot)


if __name__ == "__main__":
    build_grotto()
    build_church()
