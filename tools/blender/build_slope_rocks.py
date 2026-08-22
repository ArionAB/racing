"""Stromboli, kit de flanc — zidurile si rocile (brief slope_kit, piesele 7-12).

Sase fisiere, acelasi script (impart deciziile de cost si de imbinare):

  terrace_wall.glb        Terrace_Wall_A / _B / _Corner
  vine_row.glb            Vine_Row
  basalt_boulder.glb      Basalt_A / _B / _C
  scoria_rock.glb         Scoria_A / _B / _C
  lava_slab_broken.glb    Lava_Slab_A / _B / _C
  coast_cliff_basalt.glb  Coast_Cliff_A / _B

**CAPETELE PLANE SUNT CONTRACT.** Zidul, randul de vita si faleza se insiruie
pe sute de metri pe serpentine; un capat strambatit face un rost vizibil la
fiecare modul. De-asta modulele NU folosesc `rock`/`boulder` pe capete —
sectiunea de imbinare e o cutie curata, iar neregularitatea se adauga doar in
INTERIORUL modulului.

Bazalt vs scorie, diferenta care conteaza:
  - bazaltul are fatete MARI si PLANE (piatra sparta): `rock` cu segments mic
  - scoria e mai ZDRENTUITA, cu scobituri concave: deviation mai mare si
    volume scazute lipite pe corp

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_slope_rocks.py
"""

import math
from mathutils import Matrix, Vector

AO_ROCK = dict(samples=18, dist=2.4, gradient="vertical",
               low=0.55, high=1.00, power=0.9, floor=0.30)
AO_WALL = dict(samples=18, dist=2.0, gradient="vertical",
               low=0.50, high=1.00, power=0.9, floor=0.28)

BASALT = VOLCANIC_BLACK
SHADED = ROCK_DARK           # fete stratificate/umbrite (brief cere slot 4)
SCORIA = ROCK_DARK
SCOOP = VOLCANIC_BLACK
WOOD_S = WOOD
LEAF = TROPICAL_GREEN

WALL_LEN, WALL_THK, WALL_H = 3.0, 0.5, 1.2


def _lcg(seed):
    st = [seed & 0x7FFFFFFF]

    def nxt():
        st[0] = (st[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return st[0] / float(0x7FFFFFFF)
    return nxt


def _finish_all(objs, budget, bevel=0.05):
    total = 0
    for obj in objs:
        stats = finish(obj, bevel=bevel, ao=AO_ROCK, origin=None)
        print("  %-20s %3d tris" % (obj.name, stats["tris"]))
        total += stats["tris"]
    print("  TOTAL                %3d tris  (buget %d)" % (total, budget))
    return total


# ======================================================== 7. zid de terasa
def _wall_body(b, length, seed, gap=None):
    """Corp de zid sec: cutie de baza + blocuri decalate PE FETE.

    Capetele (x = +-length/2) raman PLANE: neregularitatea se adauga doar
    inspre interior. Asta e contractul de insiruire.
    """
    rnd = _lcg(seed)
    b.box((0.0, 0.0, WALL_H * 0.5), (length, WALL_THK, WALL_H), BASALT)
    # blocuri pe cele doua fete lungi, retrase de la capete
    for sy in (-1, 1):
        for k in range(3):
            t = (k + 0.5) / 3.0
            cx = -length * 0.5 + length * t
            if gap and abs(cx - gap[0]) < gap[1]:
                continue
            w = length / 3.0 * (0.6 + 0.25 * rnd())
            h = WALL_H * (0.34 + 0.3 * rnd())
            z = h * 0.5 + (WALL_H - h) * rnd() * 0.7
            out = 0.05 + 0.05 * rnd()
            b.box((cx, sy * (WALL_THK * 0.5 + out * 0.5), z),
                  (w, out * 2.0, h), SHADED if k % 2 else BASALT)
    # coronament denivelat: trei pietre pe muchia de sus
    for k in range(3):
        t = (k + 0.5) / 3.0
        cx = -length * 0.5 + length * t
        if gap and abs(cx - gap[0]) < gap[1]:
            continue
        b.box((cx, 0.0, WALL_H + 0.06 + rnd() * 0.05),
              (length / 3.0 * 0.82, WALL_THK * 0.92, 0.16), BASALT)


def build_terrace_wall():
    out = []
    b = Builder()
    _wall_body(b, WALL_LEN, 11)
    out.append(b.to_object("Terrace_Wall_A"))

    # varianta cu SURPARE: 0.8 m din coronament lipsesc, plus grohotis jos
    b = Builder()
    _wall_body(b, WALL_LEN, 23, gap=(0.6, 0.55))
    rnd = _lcg(29)
    for k in range(4):
        b.rock((0.35 + rnd() * 0.9, (rnd() - 0.5) * 0.9, 0.10 + rnd() * 0.1),
               (0.34, 0.30, 0.22), BASALT, seed=29 + k * 5,
               segments=6, rings=2, taper=0.5)
    out.append(b.to_object("Terrace_Wall_B"))

    # colt in L, cu aceeasi sectiune
    b = Builder()
    arm = WALL_LEN * 0.5
    b.box((-arm * 0.5, 0.0, WALL_H * 0.5), (arm, WALL_THK, WALL_H), BASALT)
    b.box((-WALL_THK * 0.25, arm * 0.5 + WALL_THK * 0.25, WALL_H * 0.5),
          (WALL_THK, arm, WALL_H), BASALT)
    b.box((-arm * 0.5, 0.0, WALL_H + 0.08), (arm * 0.9, WALL_THK * 0.92, 0.16),
          BASALT)
    out.append(b.to_object("Terrace_Wall_Corner"))
    return out


# ======================================================== 8. rand de vita
def build_vine_row():
    """Modul de 4 m: 4 butuci nodurosi pe araci, cu frunzis ca placi mici."""
    rnd = _lcg(53)
    b = Builder()
    LEN = 4.0
    for k in range(4):
        cx = -LEN * 0.5 + LEN * (k + 0.5) / 4.0
        # aracul
        b.box((cx, 0.0, 0.42), (0.06, 0.06, 0.84), WOOD_S)
        # butucul nodoros: doua volume mici, rasucite
        b.rock((cx, 0.0, 0.16), (0.20, 0.18, 0.32), WOOD_S, seed=53 + k * 7,
               segments=6, rings=2, taper=0.4)
        # frunzis: trei placi mici pe araci
        for f in range(3):
            fz = 0.42 + f * 0.16
            ang = rnd() * 2.0 * math.pi
            b.box((cx + 0.16 * math.cos(ang), 0.14 * math.sin(ang), fz),
                  (0.34, 0.22, 0.05), LEAF,
                  rotation=Matrix.Rotation(ang, 3, "Z"))
    # sarma dintre araci, la doua inaltimi
    for wz in (0.52, 0.76):
        b.box((0.0, 0.0, wz), (LEN, 0.03, 0.03), WOOD_S)
    return [b.to_object("Vine_Row")]


# ======================================================== 9. bolovani bazalt
def build_basalt():
    """Fatete MARI si PLANE: bazalt spart, nu piatra de rau."""
    out = []
    for (name, size, seed) in (("Basalt_A", 3.0, 71), ("Basalt_B", 2.0, 89),
                               ("Basalt_C", 1.0, 97)):
        b = Builder()
        # `boulder`, nu `rock`: rock() cu taper ingusteaza spre varf si scoate
        # un CON (se vede in prima randare — trei movile netede). Bazaltul
        # spart e o masa cu fatete late si plane, adica exact ce da boulder cu
        # segments mic si deviation moderata.
        b.boulder((0.0, 0.0, size * 0.32), (size, size * 0.86, size * 0.64),
                  BASALT, seed=seed, segments=6, rings=3, deviation=0.20)
        out.append(b.to_object(name))
    return out


# ======================================================== 10. scorie
def build_scoria():
    """Silueta mai zdrentuita + 2-3 scobituri concave (porozitate din FORMA)."""
    out = []
    for (name, size, seed) in (("Scoria_A", 2.0, 113), ("Scoria_B", 1.2, 127),
                               ("Scoria_C", 0.5, 139)):
        rnd = _lcg(seed)
        b = Builder()
        # deviation 0.30 (fata de 0.20 la bazalt): silueta ZDRENTUITA e ce
        # deosebeste scoria de bazaltul spart.
        # z * 0.32, nu 0.34: la 0.34 roca PLUTEA cu 18 mm (sonda). Brief-ul
        # cere rocile "usor ingropabile", deci mai bine cu putin sub sol.
        b.boulder((0.0, 0.0, size * 0.32), (size, size * 0.9, size * 0.68),
                  SCORIA, seed=seed, segments=7, rings=3, deviation=0.30)
        # scobiturile: volume mici pe slot deschis, lipite pe corp — la
        # distanta citesc ca goluri de porozitate. Brief: din FORMA, nu gauri.
        for k in range(3):
            a = 2.0 * math.pi * k / 3.0 + rnd()
            rr = size * 0.34
            b.boulder((rr * math.cos(a), rr * math.sin(a) * 0.9,
                       size * (0.30 + 0.28 * rnd())),
                      (size * 0.28, size * 0.26, size * 0.22), SCOOP,
                      seed=seed + k * 11, segments=6, rings=2, deviation=0.10)
        out.append(b.to_object(name))
    return out


# ======================================================== 11. placi de lava
def build_lava_slabs():
    """Placi de crusta rupta, ridicate in unghi mic, cu pliuri de funie."""
    out = []
    for (name, ln, seed, tilt) in (("Lava_Slab_A", 4.0, 151, 9.0),
                                   ("Lava_Slab_B", 3.0, 163, 14.0),
                                   ("Lava_Slab_C", 2.0, 179, 6.0)):
        rnd = _lcg(seed)
        b = Builder()
        thick = 0.30 + 0.2 * rnd()
        rot = Matrix.Rotation(math.radians(tilt), 3, "Y")
        b.box((0.0, 0.0, thick * 0.5 + ln * 0.04),
              (ln, ln * 0.62, thick), BASALT, rotation=rot)
        # pliuri de funie pe fata de sus: trei coame joase, pe directia lunga
        for k in range(3):
            oy = (k - 1) * ln * 0.17
            b.box((0.0, oy, thick + ln * 0.04 + 0.02),
                  (ln * 0.86, ln * 0.09, 0.09), SHADED, rotation=rot)
        out.append(b.to_object(name))
    return out


# ======================================================== 12. faleza
def build_cliffs():
    """Module de faleza STRATIFICATA, cu spatele retezat si capete plane."""
    out = []
    for (name, ln, h, seed) in (("Coast_Cliff_A", 15.0, 6.0, 191),
                                ("Coast_Cliff_B", 10.0, 4.0, 211)):
        rnd = _lcg(seed)
        b = Builder()
        # 4 benzi orizontale decalate pe adancime — asta e "stratificata".
        # Capetele raman la +-ln/2 (contract de insiruire), doar ADANCIMEA
        # variaza intre benzi.
        # Benzile au inaltimi INEGALE si fiecare e spart in 2-3 bucati pe
        # lungime, cu adancimi diferite. Prima versiune folosea benzi egale
        # dintr-o bucata si iesea zidarie de blocuri, nu faleza.
        # Capetele raman la +-ln/2: doar interiorul variaza.
        fracs = [0.32, 0.24, 0.26, 0.18]
        z0 = 0.0
        for k, fr in enumerate(fracs):
            bh = h * fr
            pieces = 2 if k % 2 else 3
            for p in range(pieces):
                pw = ln / pieces
                px = -ln * 0.5 + pw * (p + 0.5)
                depth = 2.0 + 1.3 * rnd()
                off = -0.14 * k - 0.10 * rnd()
                b.box((px, off, z0 + bh * 0.5),
                      (pw * (0.98 + 0.02 * rnd()), depth, bh),
                      SHADED if k % 2 else BASALT)
            z0 += bh
        # spatele retezat plat: o placa care inchide in urma (se ingroapa)
        b.box((0.0, -1.5, h * 0.5), (ln, 0.5, h), BASALT)
        out.append(b.to_object(name))
    return out


if __name__ == "__main__":
    jobs = [
        (build_terrace_wall, "stromboli/rocks/terrace_wall.glb", 700, 0.05),
        (build_vine_row, "stromboli/plants/vine_row.glb", 450, 0.02),
        (build_basalt, "stromboli/rocks/basalt_boulder.glb", 700, 0.06),
        (build_scoria, "stromboli/rocks/scoria_rock.glb", 600, 0.05),
        (build_lava_slabs, "stromboli/rocks/lava_slab_broken.glb", 600, 0.05),
        (build_cliffs, "stromboli/rocks/coast_cliff_basalt.glb", 1200, 0.08),
    ]
    for (fn, rel, budget, bev) in jobs:
        clear_built()
        objs = fn()
        print(rel)
        _finish_all(objs, budget, bevel=bev)
        export_glb(objs, rel)
