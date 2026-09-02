"""Cappadocia — SATUL si FIGURANTII (plansa, grupurile 10, 11, 13).

  cappadocia/buildings/cave_house_{a,b,c}.glb  conuri locuite 8-12 m
  cappadocia/buildings/dovecote.glb            porumbar sapat, vopsit alb
  cappadocia/buildings/farmhouse.glb           ferma din vale (POI E)
  cappadocia/props/carpet_terrace.glb          terasa cu covoare si perne
  cappadocia/props/pottery_cart.glb            caruta cu oale (POI A)
  cappadocia/props/pot_stack.glb               stiva de oale
  cappadocia/props/chevron_post.glb            stalp de chevron — REUSE, vezi mai jos
  cappadocia/plants/poplar_{a,b}.glb           plopi 12-16 m
  cappadocia/plants/vine_row.glb               rand de vie pe araci, 10 m
  cappadocia/plants/shrub_dry.glb              tufa uscata
  cappadocia/plants/pigeon.glb                 porumbel (decor, POI B)

**Casa de tuf NU e o casa, e un horn in care s-a sapat.** Diferenta se vede in
constructie: nu exista pereti, doar un con caruia i s-au taiat goluri si i s-au
lipit lucruri de om (o scara, un balcon de lemn, o usa cu tocul iesit). Daca ar
fi construita ca o casa cu acoperis conic, ar citi ca o coliba africana — alta
lume. Regula e din brief §1: "ferestrele sunt gauri in con, nu cladiri".

**`chevron_post` e REUSE, nu piesa noua** (plansa, grupul 13 zice explicit
"reuse"). Exista deja `assets/models/signs/chevron_post.glb` din kitul
Chongqing. Il regeneram aici DOAR daca lipseste; altfel scriptul il sare si
spune de unde se ia. Motivul e din CLAUDE.md: un asset nou pentru ceva ce
exista adauga un material la buget fara sa adauge nimic pe ecran.

Porumbeii sunt **decor**, decizie explicita din brief §8 (respinsi ca
obstructie de vizibilitate: "pedeapsa fara decizie"). Deci un porumbel e o
piesa de 40 tri care sta pe porumbar; zborul il face codul cu `Area3D`.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_cappadocia_village.py
"""

import math
import os
from mathutils import Matrix, Vector

AO_HOUSE = dict(samples=24, dist=6.0, gradient="vertical",
                low=0.40, high=1.00, power=0.88, floor=0.13)
AO_PROP = dict(samples=26, dist=2.2, gradient="vertical",
               low=0.46, high=1.00, power=0.9, floor=0.17)
AO_TREE = dict(samples=16, dist=6.0, gradient="vertical",
               low=0.52, high=1.00, power=0.85, floor=0.22)
AO_SMALL = dict(samples=20, dist=1.2, gradient="vertical",
                low=0.54, high=1.00, power=0.9, floor=0.24)

TUFF = CORAL_SAND
TUFF_MID = SAND_MID
TUFF_SH = SAND_SHADOW
CAP = VOLCANIC_BLACK
HOLE = ROCK_DARK
WHITEWASH = FOAM_WHITE     # varul de pe porumbare
WOODW = WOOD
TIMBER = LOG_DARK
CLAY = RUST                # lut ars (oale)
CARPET_A = KERB_RED
CARPET_B = TILE_TERRACOTTA
CARPET_C = LARCH_RUST
VINE = CACTUS_GREEN
POPLAR = TROPICAL_GREEN
DRY = DRY_VEGETATION
STONE = ROCK_LIGHT
BIRD = MARBLE_GREY


def cone_body(b, height, r_base, r_top, seed, segments=9, steps=7):
    """Corpul de con al unei case sapate — acelasi profil ca hornurile, ca sa
    se citeasca drept ACEEASI geologie. Daca satul ar avea alta forma de con
    decat padurea de hornuri, lumea s-ar rupe in doua.
    """
    rand = _lcg(seed)
    prof = []
    for i in range(steps):
        t = i / (steps - 1.0)
        r = r_base + (r_top - r_base) * (t ** 0.62)
        r *= 1.0 + (rand() - 0.5) * 0.11
        prof.append((r, height * t))
    faces = b.revolve(prof, TUFF, segments=segments)
    b.retag(faces, TUFF_SH, where=lambda c, n: c.z < height * 0.18)
    b.retag(faces, TUFF_MID,
            where=lambda c, n: height * 0.46 < c.z < height * 0.62)
    return faces, prof


def _radius_at(prof, z):
    """Raza conului la cota z, interpoland profilul — ca sa lipim usi si
    ferestre EXACT pe suprafata, nu plutind sau ingropate."""
    for (r0, z0), (r1, z1) in zip(prof, prof[1:]):
        if z0 <= z <= z1:
            t = (z - z0) / max(z1 - z0, 1e-6)
            return r0 + (r1 - r0) * t
    return prof[-1][0]


def carve(b, prof, z, a_deg, w, h, depth=0.45, slot=HOLE, lip=True):
    """Gaura sapata pe suprafata conului (fereastra sau usa)."""
    a = math.radians(a_deg)
    r = _radius_at(prof, z) * 0.95
    rot = Matrix.Rotation(a, 3, "Z")
    b.box((r * math.cos(a), r * math.sin(a), z), (depth, w, h), slot,
          rotation=rot)
    if lip:
        rl = r + 0.10
        b.box((rl * math.cos(a), rl * math.sin(a), z + h * 0.5 + 0.09),
              (depth * 0.85, w * 1.22, 0.17), TUFF_SH, rotation=rot)


def build_cave_house(variant):
    """Trei case locuite. Ce le diferentiaza sunt LUCRURILE DE OM lipite pe con:
    (a) usa cu toc si o fereastra, (b) scara exterioara si un balcon de lemn,
    (c) doua niveluri de ferestre si o terasa cu parapet.
    """
    b = Builder()
    H, RB, RT = ((9.0, 3.10, 1.35), (11.5, 3.45, 1.20), (10.2, 3.90, 1.55))[variant]
    faces, prof = cone_body(b, H, RB, RT, seed=(131, 179, 233)[variant])
    _ = faces

    # usa: mereu spre +Y (= -Z Godot, adica spre camera in conventia briefurilor)
    carve(b, prof, 1.30, 90.0, 1.55, 2.45, 0.60, slot=WOODW)
    # tocul iesit, care spune "aici s-a construit ceva, nu doar sapat"
    rr = _radius_at(prof, 1.30) + 0.16
    b.box((rr * math.cos(math.radians(90)), rr * math.sin(math.radians(90)), 1.15),
          (0.34, 2.00, 2.90), TUFF_MID, rotation=Matrix.Rotation(math.radians(90), 3, "Z"))

    if variant == 0:
        carve(b, prof, 4.10, 55.0, 0.95, 1.20)
        carve(b, prof, 5.60, -40.0, 0.85, 1.05)
    elif variant == 1:
        carve(b, prof, 4.60, 30.0, 1.00, 1.28)
        carve(b, prof, 7.10, -20.0, 0.88, 1.10)
        # scara exterioara, lipita de con
        a = math.radians(160.0)
        n = 9
        for k in range(n):
            t = (k + 0.5) / n
            z = 0.30 + 4.10 * t
            r = _radius_at(prof, z) + 0.42
            aa = a + math.radians(26.0 * t)     # scara urca in spirala
            b.box((r * math.cos(aa), r * math.sin(aa), z),
                  (1.35, 0.95, 0.22), STONE, rotation=Matrix.Rotation(aa, 3, "Z"))
        # balconul de lemn la capatul scarii
        z_b = 4.55
        r_b = _radius_at(prof, z_b) + 0.75
        ab = a + math.radians(26.0)
        rot = Matrix.Rotation(ab, 3, "Z")
        b.box((r_b * math.cos(ab), r_b * math.sin(ab), z_b), (1.7, 2.1, 0.16),
              WOODW, rotation=rot)
        for k in (-1, 1):
            off = k * 0.95
            px = r_b * math.cos(ab) - off * math.sin(ab)
            py = r_b * math.sin(ab) + off * math.cos(ab)
            b.beam((px, py, z_b), (px, py, z_b + 0.95), 0.09, TIMBER)
        b.box((r_b * math.cos(ab), r_b * math.sin(ab), z_b + 0.92),
              (1.75, 2.15, 0.10), TIMBER, rotation=rot)
        carve(b, prof, z_b + 0.95, math.degrees(ab), 0.85, 1.65, 0.5, slot=HOLE)
    else:
        for (z, ang) in ((3.90, 62.0), (4.05, -18.0), (6.35, 120.0),
                         (6.50, 25.0), (8.10, -70.0)):
            carve(b, prof, z, ang, 0.90, 1.14)
        # terasa taiata in con, cu parapet scund
        z_t = 5.20
        r_t = _radius_at(prof, z_t)
        at = math.radians(-100.0)
        rot = Matrix.Rotation(at, 3, "Z")
        b.box(((r_t + 0.55) * math.cos(at), (r_t + 0.55) * math.sin(at), z_t),
              (2.2, 3.0, 0.28), TUFF_MID, rotation=rot)
        b.box(((r_t + 1.45) * math.cos(at), (r_t + 1.45) * math.sin(at),
               z_t + 0.42), (0.30, 3.0, 0.60), TUFF, rotation=rot)

    # palaria de bazalt, ca la hornuri — casele sunt hornuri locuite
    b.frustum((0.0, 0.0, H - 0.25), RT * 1.02, RT * 1.70, 0.60, CAP, segments=9)
    b.frustum((0.0, 0.0, H + 0.45), RT * 1.70, RT * 1.25, 0.70, CAP, segments=9)
    # un cos de soba: singurul semn ca inauntru e cald
    b.cylinder((RT * 0.45, RT * 0.30, H + 1.15), 0.20, 1.00, STONE, segments=7)
    return b.to_object("Cave_House_" + "ABC"[variant])


def build_dovecote():
    """Porumbarul: con mic, plin de gauri mici, cu var alb in jurul lor.

    Varul e ce il face sa se recunoasca de la 40 m (asa arata cele reale din
    Cappadocia: pete albe pe tuf crem). Gaurile sunt mici (22 cm) si multe —
    la scara asta o gaura "pictata" e chiar corecta, nici nu incape alta.
    """
    b = Builder()
    H, RB, RT = 6.4, 2.35, 1.10
    faces, prof = cone_body(b, H, RB, RT, seed=317, steps=6)
    _ = faces
    # panoul de var: o banda lata, aplicata ca retag pe fetele de la mijloc
    rand = _lcg(419)
    for k in range(34):
        z = 1.9 + 3.6 * (k % 9) / 8.0
        a = math.radians(-70.0 + 200.0 * ((k * 7) % 34) / 34.0)
        r = _radius_at(prof, z)
        rot = Matrix.Rotation(a, 3, "Z")
        # placa de var, apoi gaura in ea
        b.box(((r + 0.03) * math.cos(a), (r + 0.03) * math.sin(a), z),
              (0.16, 0.52, 0.52), WHITEWASH, rotation=rot)
        b.box(((r - 0.06) * math.cos(a), (r - 0.06) * math.sin(a), z),
              (0.32, 0.24, 0.24), HOLE, rotation=rot)
    # usa de acces jos
    carve(b, prof, 1.05, 90.0, 0.85, 1.75, 0.5, slot=WOODW)
    b.frustum((0.0, 0.0, H - 0.20), RT * 1.02, RT * 1.60, 0.50, CAP, segments=9)
    b.frustum((0.0, 0.0, H + 0.38), RT * 1.60, RT * 1.20, 0.60, CAP, segments=9)
    return b.to_object("Dovecote")


def build_farmhouse():
    """Ferma din vale (POI E): cutie de piatra cu acoperis plat si scara.

    Contrast deliberat cu satul de sus: asta e CONSTRUITA (blocuri, colturi
    drepte, acoperis plat cu parapet), fiindca in vale nu e tuf de sapat. Cele
    doua tipuri de locuire pe aceeasi pista sunt jumatate din povestea locului.
    """
    b = Builder()
    W, D, H = 7.2, 5.6, 3.4
    b.box((0.0, 0.0, H * 0.5), (W, D, H), TUFF_MID)
    # asize de piatra: trei benzi orizontale de valoare, zero triunghiuri in plus
    for z in (0.85, 1.95, 2.95):
        b.box((0.0, 0.0, z), (W + 0.06, D + 0.06, 0.22), TUFF)
    # acoperis plat cu parapet (se doarme pe el vara)
    b.box((0.0, 0.0, H + 0.14), (W + 0.45, D + 0.45, 0.28), TUFF_SH)
    for (sx, sy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        c = (sx * (W * 0.5 + 0.16), sy * (D * 0.5 + 0.16), H + 0.62)
        size = (0.26, D + 0.75, 0.68) if sx else (W + 0.75, 0.26, 0.68)
        b.box(c, size, TUFF_MID)
    # usa si doua ferestre pe fata (+Y)
    b.box((0.0, D * 0.5 - 0.14, 1.05), (1.15, 0.45, 2.10), WOODW)
    for sx in (-1.0, 1.0):
        b.box((sx * 2.15, D * 0.5 - 0.14, 2.10), (0.85, 0.45, 0.90), HOLE)
        b.box((sx * 2.15, D * 0.5 + 0.05, 2.62), (1.05, 0.20, 0.16), TIMBER)
    # scara exterioara spre acoperis
    for k in range(7):
        t = (k + 0.5) / 7.0
        b.box((W * 0.5 + 0.55, -D * 0.5 + D * t, 0.24 + (H - 0.1) * t),
              (1.25, D / 7.0 * 1.02, 0.20), STONE)
    # grinzile iesite din perete (semnatura de casa de vale)
    for k in range(5):
        y = -D * 0.5 + D * (k + 0.5) / 5.0
        b.beam((-W * 0.5 - 0.30, y, H - 0.35), (-W * 0.5 + 0.2, y, H - 0.35),
               0.16, TIMBER)
    return b.to_object("Farmhouse")


def build_carpet_terrace():
    """Terasa cu covoare si perne, la start (POI A).

    Covoarele sunt placi de 6 cm cu franjuri sugerati de o banda mai inchisa la
    capete. Culoarea lor e singurul rosu saturat din piata — de-aia se vede.
    """
    b = Builder()
    # platforma de tuf
    b.box((0.0, 0.0, 0.14), (6.0, 4.2, 0.28), TUFF_MID)
    b.box((0.0, 0.0, 0.30), (5.6, 3.8, 0.08), TUFF)
    # trei covoare suprapuse, la unghiuri diferite
    for (px, py, w, d, ang, slot) in ((-1.15, 0.35, 2.6, 1.8, 4.0, CARPET_A),
                                      (1.25, -0.45, 2.9, 2.0, -7.0, CARPET_B),
                                      (0.15, 1.05, 2.2, 1.4, 14.0, CARPET_C)):
        rot = Matrix.Rotation(math.radians(ang), 3, "Z")
        b.box((px, py, 0.37), (w, d, 0.06), slot, rotation=rot)
        # franjurii: doua benzi inchise la capete
        for sx in (-1.0, 1.0):
            b.box((px + sx * w * 0.5 * math.cos(math.radians(ang)),
                   py + sx * w * 0.5 * math.sin(math.radians(ang)), 0.36),
                  (0.18, d * 0.96, 0.05), TUFF_SH, rotation=rot)
    # perne pe margine
    for (px, py, ang) in ((-2.15, -1.35, 20.0), (-0.55, -1.55, -10.0),
                          (2.05, 1.35, 35.0), (0.95, 1.65, -25.0)):
        rot = Matrix.Rotation(math.radians(ang), 3, "Z")
        b.box((px, py, 0.52), (0.85, 0.60, 0.26),
              CARPET_A if px < 0 else CARPET_C, rotation=rot)
    # masuta joasa cu ceainic
    b.cylinder((1.55, 0.15, 0.62), 0.52, 0.10, WOODW, segments=9)
    b.cylinder((1.55, 0.15, 0.46), 0.14, 0.24, TIMBER, segments=6)
    b.revolve([(0.10, 0.0), (0.19, 0.10), (0.16, 0.26), (0.08, 0.32)], CLAY,
              segments=8, origin=(1.55, 0.15, 0.67))
    return b.to_object("Carpet_Terrace")


def _pot(b, cx, cy, cz, scale, slot=CLAY, segments=6):
    """Un ulcior. Profilul e de amfora din Avanos: gat ingust, umar larg, baza
    mica. Se repeta de zeci de ori, deci sta intr-o functie.

    `segments=6` si patru inele, deliberat: caruta poarta 14 oale si stiva 10,
    deci fiecare triunghi se inmulteste cu 24. La 8 segmente si 6 inele
    caruta iesise la 5.700 tri — mai scumpa decat casa de langa ea, pentru un
    obiect de 3.6 m care sta pe marginea drumului. Cu 6 si 4, silueta de
    amfora se pastreaza (umarul si gatul sunt inca acolo) la ~40% din cost.
    """
    prof = [(0.14, 0.00), (0.30, 0.22), (0.20, 0.50), (0.13, 0.68)]
    b.revolve([(r * scale, z * scale) for (r, z) in prof], slot,
              segments=segments, origin=(cx, cy, cz))


def build_pot_stack():
    """Stiva de oale: gramada de ulcioare, decor de piata."""
    b = Builder()
    rand = _lcg(521)
    # randul de jos, sase oale
    for k in range(6):
        a = 2.0 * math.pi * k / 6.0
        _pot(b, 0.44 * math.cos(a), 0.44 * math.sin(a), 0.0,
             0.95 + rand() * 0.2, CLAY if k % 2 else TUFF_MID)
    # randul de sus, trei
    for k in range(3):
        a = 2.0 * math.pi * k / 3.0 + 0.5
        _pot(b, 0.26 * math.cos(a), 0.26 * math.sin(a), 0.62,
             0.82 + rand() * 0.18, TUFF_MID if k % 2 else CLAY)
    # una singura in varf
    _pot(b, 0.0, 0.0, 1.12, 0.75, CLAY)
    return b.to_object("Pot_Stack")


def build_pottery_cart():
    """Caruta cu oale (POI A): decor STATIC CU COLIZIUNE, lasa o fanta de 4 m.

    Deci gabaritul conteaza: 3.6 m lungime x 1.9 m latime. Brief §3 o da ca
    "`world_prop`, zero cod" — adica tot ce trebuie sa fie corect e forma si
    faptul ca sta stabil pe sol.
    """
    b = Builder()
    L, W = 3.6, 1.9
    # platforma si loitrele
    b.box((0.0, 0.0, 0.86), (L, W, 0.14), WOODW)
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * W * 0.5, 1.12), (L, 0.10, 0.52), WOODW)
        for k in range(5):
            x = -L * 0.5 + L * (k + 0.5) / 5.0
            b.beam((x, sy * W * 0.5, 0.92), (x, sy * W * 0.5, 1.40), 0.07, TIMBER)
    b.box((-L * 0.5, 0.0, 1.16), (0.10, W, 0.60), WOODW)
    # rotile: doua, cu spite
    for sy in (-1.0, 1.0):
        cy = sy * (W * 0.5 + 0.10)
        b.torus((0.55, cy, 0.62), 0.62, 0.09, TIMBER, major_seg=12, minor_seg=5,
                axis="Y")
        b.cylinder((0.55, cy, 0.62), 0.14, 0.16, WOODW, segments=8, axis="Y")
        for k in range(6):
            a = 2.0 * math.pi * k / 6.0
            b.beam((0.55, cy, 0.62),
                   (0.55 + 0.56 * math.cos(a), cy, 0.62 + 0.56 * math.sin(a)),
                   0.055, WOODW)
    # osia si oistea
    b.beam((0.55, -W * 0.5 - 0.10, 0.62), (0.55, W * 0.5 + 0.10, 0.62), 0.11,
           TIMBER)
    b.beam((-L * 0.5, 0.0, 0.80), (-L * 0.5 - 1.35, 0.0, 0.55), 0.10, TIMBER)
    # incarcatura: oale in doua randuri + paie
    rand = _lcg(631)
    for k in range(7):
        x = -L * 0.42 + L * 0.80 * (k / 6.0)
        for sy in (-0.42, 0.42):
            _pot(b, x, sy + (rand() - 0.5) * 0.12, 0.93, 0.88 + rand() * 0.2,
                 CLAY if (k + (sy > 0)) % 2 else TUFF_MID)
    for k in range(5):
        b.box((-L * 0.3 + rand() * L * 0.6, (rand() - 0.5) * W * 0.7, 0.95),
              (0.7, 0.16, 0.06), DRY,
              rotation=Matrix.Rotation(rand() * 3.0, 3, "Z"))
    return b.to_object("Pottery_Cart")


def build_poplar(variant):
    """Plopul: coloana ingusta de frunzis. Silueta e TOT — un plop lat e un
    stejar. Raportul inaltime/latime e 6:1 (masurat pe fotografii de Cappadocia).

    Frunzisul e un `revolve` cu profil ascutit, cu doua sloturi de verde ca sa
    nu iasa o pana uniforma.
    """
    b = Builder()
    H = (12.5, 15.5)[variant]
    R = H / 6.2 * 0.5
    b.taper_sweep([(0.0, 0.0, 0.0), (0.0, 0.0, H * 0.22), (0.0, 0.0, H * 0.5)],
                  [0.30, 0.20, 0.13], TIMBER, segments=7)
    prof = [(0.18, H * 0.12), (R * 0.72, H * 0.26), (R, H * 0.46),
            (R * 0.92, H * 0.66), (R * 0.58, H * 0.84), (0.0, H)]
    faces = b.revolve(prof, POPLAR, segments=8, cap_bottom=False)
    # jumatatea de jos mai inchisa: volum fara triunghiuri
    b.retag(faces, DRY, where=lambda c, n: c.z < H * 0.30)
    b.retag(faces, CACTUS_GREEN, where=lambda c, n: H * 0.34 < c.z < H * 0.58)
    return b.to_object("Poplar_" + "AB"[variant])


def build_vine_row():
    """Rand de vie pe araci, 10 m — **suprafata lenta cu geometrie** (brief §2
    POI E): se trece PRIN ea, deci geometria trebuie sa fie joasa (1.5 m) si
    fara nimic solid la inaltimea barei de protectie.

    Aracii sunt subtiri si rari (2 m pas) tocmai ca sa nu citeasca drept gard.
    """
    b = Builder()
    L = 10.0
    # aracii + sarma
    for k in range(6):
        x = -L * 0.5 + L * k / 5.0
        b.beam((x, 0.0, 0.0), (x, 0.0, 1.45), 0.075, TIMBER)
    for z in (0.85, 1.30):
        b.beam((-L * 0.5, 0.0, z), (L * 0.5, 0.0, z), 0.035, TIMBER)
    # butucii si frunzisul: cate o tufa turtita intre araci
    rand = _lcg(733)
    for k in range(5):
        x = -L * 0.5 + L * (k + 0.5) / 5.0
        b.taper_sweep([(x, 0.0, 0.0), (x + (rand() - 0.5) * 0.1, 0.0, 0.55)],
                      [0.13, 0.09], TIMBER, segments=5)
        for j in range(3):
            zz = 0.70 + j * 0.32
            w = 1.55 - j * 0.18
            b.box((x + (rand() - 0.5) * 0.25, (rand() - 0.5) * 0.30, zz),
                  (w, 0.85, 0.30), VINE if j % 2 else CACTUS_GREEN,
                  rotation=Matrix.Rotation((rand() - 0.5) * 0.4, 3, "Z"))
    return b.to_object("Vine_Row")


def build_shrub_dry():
    """Tufa uscata: manunchi de nuiele. Piesa de scatter, deci ieftina."""
    b = Builder()
    rand = _lcg(821)
    for k in range(9):
        a = 2.0 * math.pi * rand()
        ln = 0.55 + rand() * 0.65
        lean = 0.35 + rand() * 0.45
        b.taper_sweep([(0.0, 0.0, 0.02),
                       (ln * lean * 0.4 * math.cos(a), ln * lean * 0.4 * math.sin(a), ln * 0.55),
                       (ln * lean * math.cos(a), ln * lean * math.sin(a), ln)],
                      [0.05, 0.035, 0.0], DRY, segments=4)
    return b.to_object("Shrub_Dry")


def build_pigeon():
    """Porumbelul: 40 cm, decor pur (brief §8 — respins ca mecanica).

    Sta pe porumbar sau pe o buza de stanca. La distanta e o pata gri cu cioc;
    de aproape trebuie totusi sa aiba silueta corecta, altfel citeste ca o
    piatra. Deci: corp-pana, cap rotund, coada plata, doua picioare.
    """
    b = Builder()
    b.revolve([(0.055, 0.0), (0.085, 0.055), (0.075, 0.115), (0.0, 0.145)],
              CLAY, segments=5, origin=(-0.03, 0.045, 0.0))
    b.revolve([(0.055, 0.0), (0.085, 0.055), (0.075, 0.115), (0.0, 0.145)],
              CLAY, segments=5, origin=(-0.03, -0.045, 0.0))
    # corpul
    b.rock((0.0, 0.0, 0.145), (0.30, 0.17, 0.17), BIRD, seed=7, segments=7,
           rings=4, taper=0.55)
    # capul si ciocul
    b.rock((0.13, 0.0, 0.26), (0.11, 0.10, 0.11), BIRD, seed=13, segments=6,
           rings=3, taper=0.7)
    b.taper_sweep([(0.17, 0.0, 0.27), (0.235, 0.0, 0.262)], [0.022, 0.0],
                  CLAY, segments=4)
    # coada plata
    b.box((-0.20, 0.0, 0.175), (0.17, 0.09, 0.022), BIRD,
          rotation=Matrix.Rotation(math.radians(-12.0), 3, "Y"))
    # aripile stranse: doua placi pe flancuri
    for sy in (-1.0, 1.0):
        b.box((-0.02, sy * 0.075, 0.175), (0.20, 0.03, 0.085), MARBLE_GREY,
              rotation=Matrix.Rotation(math.radians(sy * 5.0), 3, "X"))
    return b.to_object("Pigeon")


clear_built()

results = []
skipped = []


def emit(obj, path, ao, origin="base", bevel=0.03):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "cappadocia/" + path)
    results.append((path, st["tris"], sz / 1024.0))


for v in range(3):
    emit(build_cave_house(v), "buildings/cave_house_%s.glb" % "abc"[v],
         AO_HOUSE, bevel=0.045)
emit(build_dovecote(), "buildings/dovecote.glb", AO_HOUSE, bevel=0.035)
emit(build_farmhouse(), "buildings/farmhouse.glb", AO_HOUSE, bevel=0.035)
emit(build_carpet_terrace(), "props/carpet_terrace.glb", AO_PROP, bevel=0.02)
emit(build_pottery_cart(), "props/pottery_cart.glb", AO_PROP, bevel=0.018)
emit(build_pot_stack(), "props/pot_stack.glb", AO_PROP, bevel=0.015)
for v in range(2):
    emit(build_poplar(v), "plants/poplar_%s.glb" % "ab"[v], AO_TREE, bevel=0.03)
emit(build_vine_row(), "plants/vine_row.glb", AO_SMALL, origin="base_axis",
     bevel=0.02)
emit(build_shrub_dry(), "plants/shrub_dry.glb", AO_SMALL, bevel=0.012)
emit(build_pigeon(), "plants/pigeon.glb", AO_SMALL, bevel=0.008)

# chevron_post: REUSE din kitul existent (plansa, grupul 13). Nu se
# regenereaza; se raporteaza de unde se ia, ca integrarea sa nu-l caute in
# cappadocia/.
for cand in ("signs/chevron_post.glb", "chongqing/props/chevron_post.glb"):
    if os.path.exists(os.path.join(MODELS, cand)):
        skipped.append("chevron_post -> REUSE res://assets/models/" + cand)
        break
else:
    skipped.append("chevron_post -> LIPSESTE, trebuie generat separat")

print()
for path, tris, kb in results:
    print("%-42s tris=%6d %8.1f kB" % (path, tris, kb))
for s in skipped:
    print("   " + s)
print("TOTAL sat+figuranti: %d tris" % sum(t for _, t, _ in results))
