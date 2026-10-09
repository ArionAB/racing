"""Okinawa v2 -- coasta (brief docs/asset_briefs/okinawa_kit_v2.md §1.2).

  okinawa/rocks/notch_rock_a.glb          stanca-ciuperca inalta si zvelta
  okinawa/rocks/notch_rock_b.glb          stanca-ciuperca lata si joasa
  okinawa/rocks/notch_rock_c.glb          stanca-ciuperca aplecata spre mare
  okinawa/rocks/heart_rock.glb            stanca-inima (doi lobi, varf in apa)
  okinawa/rocks/limestone_cliff_module.glb  faleza inlantuibila 12 m
  okinawa/buildings/cape_lighthouse.glb   farul, turn alb + casa paznicului
  okinawa/structures/coral_stone_wall.glb zid uscat din pietre rotunjite

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_okinawa_coast.py

Fara text, cifre sau logo-uri (regula 9). Variabila OK_ONLY=<piesa> reface doar
piesa respectiva. Vocabularul (inele fatetate, nisa de val, profil de ciuperca)
e in okinawa_shapes.py. Linia apei presupusa: vezi inventarul, per piesa.
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "okinawa_shapes.py")).read())

clear_built()

GRASS = TROPICAL_GREEN


def _ao(top, low=0.55):
    return dict(samples=20, dist=3.0, gradient="vertical", low=0.45, high=1.0,
                power=0.8, floor=0.22, z_range=(0.0, top))


def _mushroom(name, prof, notch, cap_mid, seed, tuft_seed, boulders, ratio=0.86,
              lean=0.0, lean_from=None, bite=None, tufts=3):
    lime, grass = Builder(), Builder()
    h = prof[-1][0]
    notch_rock(lime, grass, prof, seg=11, seed=seed, ratio=ratio, lean=lean,
               lean_from=lean_from, lean_to=cap_mid, notch=notch, bite=bite,
               tufts=tufts, tuft_seed=tuft_seed, shoulder_z=h - (h - cap_mid) * 0.12)
    foot_boulders(lime, boulders)
    return [to_obj_nr(lime, "Notch_Limestone"), to_obj_nr(grass, "Notch_Grass")], h


def to_obj_nr(b, name):
    """Builder -> obiect, cu normalele recalculate pe tot nodul."""
    return b.to_object(name)


def build_notch_rock_a():
    """Stanca-ciuperca A (`notch_rock_a`): inalta si zvelta.

    LISTA DE ELEMENTE (din decuparea `notch_rock_a.png` + contractul §1.2; cele
    trei variante au proportii DISTINCTE, corectura de coordonator):
      a) picior subtire: Ø ~3,0 m (r 1,5), poala evazata la sol (r 2,25)
      b) NISA de val de jur-imprejur, la baza: z 0,4..1,9 (~1,5 m), gatul r 1,05
         (mai ingust decat piciorul), banda SAND_SHADOW pe nisa
      c) cap fatetat, ~7 m lat (r 3,5), burta sub cap la z 5,0, umarul la z 6,3,
         cupola usor turtita; inaltime totala ~8,6 m  (h/l ~1,2)
      d) iarba pe crestet (invelis `Notch_Grass`, TROPICAL_GREEN 21) + 3 tufe joase
      e) 4 bolovani la picior (calcar)
      f) fara nisip, fara apa (le pune terenul)
    Noduri: Notch_Limestone (MARBLE_GREY 29 + nisa SAND_SHADOW 2), Notch_Grass.
    """
    prof = notch_profile(7.5, 1.5, 0.85, 3.5, (0.4, 1.9), 4.4, 5.5, flat=1.0)
    boulders = [(2.7, -1.3, (1.5, 1.2, 1.0), 11), (-2.5, 1.3, (1.7, 1.4, 1.2), 12),
                (0.6, 2.9, (1.1, 0.9, 0.8), 13), (-1.1, -2.7, (1.2, 1.0, 0.9), 14)]
    return _mushroom("a", prof, (0.4, 1.9), 5.5, 21, 5, boulders, ratio=0.88)


def build_notch_rock_b():
    """Stanca-ciuperca B (`notch_rock_b`): lata si joasa, ca o masa.

    LISTA DE ELEMENTE:
      a) picior SCURT SI GROS: r 2,1 (Ø 4,2), poala r 3,15
      b) NISA: z 0,3..1,3 (~1 m), gatul r 1,6, banda SAND_SHADOW
      c) cap ca o MASA: ~9 m lat (r 4,5), fata de sus larga si aproape plata
         (flat 3), burta la z 2,3, umarul la z 3,1; inaltime totala 5,0 m
         (h/l ~0,55)
      d) iarba pe crestet + 3 tufe joase (mai late)
      e) 5 bolovani la picior
    """
    prof = notch_profile(4.1, 2.1, 1.3, 4.5, (0.3, 1.3), 2.0, 2.7, flat=3.0)
    boulders = [(3.6, -1.6, (1.8, 1.5, 1.2), 31), (-3.4, 1.8, (2.0, 1.6, 1.3), 32),
                (1.2, 3.8, (1.3, 1.1, 0.9), 33), (-1.8, -3.5, (1.5, 1.2, 1.0), 34),
                (4.0, 1.9, (1.0, 0.9, 0.7), 35)]
    return _mushroom("b", prof, (0.3, 1.3), 2.7, 22, 6, boulders, ratio=0.84,
                     tufts=3)


def build_notch_rock_c():
    """Stanca-ciuperca C (`notch_rock_c`): aplecata spre mare (+X).

    LISTA DE ELEMENTE:
      a) picior Ø ~2,7 (r 1,35), poala r 2,0, urca drept pana la z ~1,7
      b) NISA roasa mai adanc pe partea dinspre mare (+X): z 0,4..1,7, gatul
         r 0,95, muscata 30% pe +X, banda SAND_SHADOW
      c) capul DEPLASAT ~2,0 m pe +X fata de picior (smoothstep intre z 1,7 si
         umarul de la z 4,8), cap ~6 m lat (r 3,0), burta la z 3,8; inaltime
         6,5 m (h/l ~1,0)
      d) iarba pe crestet + 3 tufe
      e) 4 bolovani la picior, doi sub surplomb
    """
    prof = notch_profile(5.4, 1.35, 0.8, 3.0, (0.4, 1.7), 3.1, 4.0, flat=1.6)
    boulders = [(-2.4, -1.2, (1.4, 1.1, 1.0), 41), (-2.0, 1.9, (1.5, 1.2, 1.1), 42),
                (2.2, 2.0, (1.1, 0.9, 0.8), 43), (1.5, -2.5, (1.2, 1.0, 0.9), 44)]
    return _mushroom("c", prof, (0.4, 1.7), 4.0, 23, 7, boulders, ratio=0.86,
                     lean=2.0, lean_from=1.7, bite=(0.4, 1.7, 0.22, 0.0))


def build_heart_rock():
    """Stanca-inima (`heart_rock`).

    LISTA DE ELEMENTE (din decuparea `heart_rock.png` + contractul §1.2):
      a) DOI LOBI rotunjiti, fatetati (r 2,4 la burta, ~7 m inalt stanga, 6,6 m
         dreapta — dreapta putin mai joasa, ca pe planșa), fiecare aplecat spre
         exterior cu 2,3 m (cx ~ t^1,1) in plan XZ
      b) se unesc jos intr-un VARF subtire (r 0,45) la z = 0, infipt in apa;
         linia apei presupusa la z ~ 0,9 (banda SAND_SHADOW la z 0,3..1,2 =
         zona de spalare a valului)
      c) inima se citeste din +Y si din -Y (lobii sunt asezati pe X; siluetele
         din fata si din spate sunt identice ca forma)
      d) 4 bolovani mici in jur (pe colturi, in afara X-ului inimii)
      e) fara apa, fara nisip (le pune terenul)
    Nod: Heart_Limestone (MARBLE_GREY 29 + banda SAND_SHADOW 2). Cote tinta
    ~7 m inalt, ~8 m lat, h/l ~0,9.
    """
    lime = Builder()
    seg = 11
    for sgn, h, seed in ((-1, 7.0, 51), (1, 6.6, 52)):
        prof = lobe_profile(h, 2.3)
        rings = []
        for (z, r) in prof:
            t = z / h
            rings.append((z, r, r * 0.86, sgn * 2.6 * (t ** 1.05), 0.0))
        pts, _ = ring_points(rings, seg, seed, 0.11)
        faceted_shell(lime, pts, OK_LIMESTONE,
                      lambda k, z: OK_NICHE if 0.25 <= z <= 1.25 else OK_LIMESTONE)
    foot_boulders(lime, [(-3.3, -2.4, (2.2, 1.8, 1.4), 61), (3.0, -2.6, (1.7, 1.4, 1.1), 62),
                         (3.4, 2.4, (2.3, 1.9, 1.5), 63), (-2.9, 2.6, (1.5, 1.2, 1.0), 64)])
    return [lime.to_object("Heart_Limestone")], 7.0


# statii (y, d, nd, top): d = iesirea fetei, nd = adancimea nisei, top = cota
# crestei; bombarile fetei (6 niveluri) vin din `_bulge`, nule la capete
CLIFF_STATIONS = [
    (-6.0, 0.00, 1.20, 13.6),   # capat: profil P0
    (-3.6, 0.45, 1.60, 14.0),
    (-1.7, -0.25, 1.00, 13.2),
    (0.9, 0.50, 1.80, 14.0),
    (3.1, -0.10, 1.30, 13.4),
    (4.7, 0.35, 1.50, 13.8),
    (6.0, 0.00, 1.20, 13.6),    # capat: IDENTIC cu primul
]


def _bulge(si, lvl, last):
    if si == 0 or si == last:
        return 0.0
    return 0.5 * math.sin(si * 1.9 + lvl * 2.3 + 0.7)


def cliff_profile(si, last, d, nd, top):
    """Sectiunea XZ a falezei (x = spre mare = +X). Spatele plat, poala, NISA
    de val (z 0,5..2,6, adancime nd), buza, fata cu 6 bombari (trepte de
    bolovani) si creasta. Aceleasi 17 puncte la fiecare statie."""
    bl = [_bulge(si, k, last) for k in range(6)]
    return [
        (-2.5, 0.0), (2.2 + d, 0.0), (2.2 + d, 0.5),
        (2.2 + d - 0.45 * nd, 1.1), (2.2 + d - nd, 1.8), (2.2 + d - 0.8 * nd, 2.6),
        (2.35 + d, 3.2), (2.5 + d + bl[0], 4.8), (2.4 + d + bl[1], 6.6),
        (2.55 + d + bl[2], 8.4), (2.3 + d + bl[3], 10.2), (2.4 + d + bl[4], top - 2.4),
        (2.1 + d + bl[5], top - 1.2), (1.7 + d * 0.5, top), (-0.2, top + 0.35),
        (-2.0, top - 0.1), (-2.5, top - 0.5),
    ]


def _stations_loft(b, profiles, ys, slot_of_edge, slot):
    """Loft prin statii: profile (liste (x, z) cu acelasi numar de puncte) la
    cotele `ys` (pe Y). Capete plane la ys[0] si ys[-1], triunghiulate."""
    V = [[b.bm.verts.new((x, y, z)) for (x, z) in prof] for prof, y in zip(profiles, ys)]
    n = len(profiles[0])
    for k in range(len(V) - 1):
        for i in range(n):
            j = (i + 1) % n
            f = b.bm.faces.new([V[k][i], V[k][j], V[k + 1][j], V[k + 1][i]])
            f[b.slot] = slot_of_edge(i)
    caps = []
    for ring in (V[0], list(reversed(V[-1]))):
        f = b.bm.faces.new(ring)
        f[b.slot] = slot
        caps.append(f)
    bmesh.ops.triangulate(b.bm, faces=caps)


def build_cliff():
    """Modulul de faleza (`limestone_cliff_module`).

    LISTA DE ELEMENTE (din decuparea `limestone_cliff_module.png` + §1.2):
      a) bloc de calcar 12 m (Y) x ~5,5 m (X) x ~14 m (Z); fata de mare pe +X,
         spatele plat pe -X; loft prin 7 statii pe Y => 6 FATETE verticale late
         de 1,3..2,8 m (planșa: ~5-6 fete mari)
      b) NISA de val la baza, ~2 m inalta (z 0,5..2,6), adanca 1,0..1,8 m,
         banda SAND_SHADOW pe nisa, buza iesita deasupra
      c) fata cu bombari usoare (m1..m3) si cresta cu cote diferite 13,2..14,0
      d) capete PLANE si IDENTICE la y = +-6,0 (aceeasi statie P0): se inlantuie
      e) creastet cu iarba (`Cliff_Grass`) + 4 tufe joase de iarba
      f) fara copaci/arbusti inalti (nu se lipeste vegetatie de faleza)
    Nod: Cliff_Limestone (MARBLE_GREY 29 + nisa SAND_SHADOW 2), Cliff_Grass
    (TROPICAL_GREEN 21).
    """
    lime, grass = Builder(), Builder()
    profs = [cliff_profile(i, len(CLIFF_STATIONS) - 1, *st[1:]) for i, st in enumerate(CLIFF_STATIONS)]
    ys = [st[0] for st in CLIFF_STATIONS]
    _stations_loft(lime, profs, ys, lambda i: OK_NICHE if i in (2, 3, 4, 5) else OK_LIMESTONE,
                   OK_LIMESTONE)
    gprofs = []
    for P in profs:
        a, c, d_, e = P[-4], P[-3], P[-2], P[-1]
        gprofs.append([(a[0] + 0.12, a[1] - 0.35), (a[0], a[1] + 0.22), (c[0], c[1] + 0.22),
                       (d_[0], d_[1] + 0.2), (d_[0] - 0.3, d_[1] - 0.2),
                       (d_[0] - 0.3, d_[1] - 0.5), (a[0] - 0.1, a[1] - 0.9)])
    _stations_loft(grass, gprofs, ys, lambda i: GRASS, GRASS)
    # tufe joase de iarba pe creasta (nu la capete: modulele se inlantuie)
    for (y, x, sx, sh, sd) in ((-3.4, 0.6, 2.2, 1.0, 71), (-0.5, -0.4, 2.6, 1.2, 72),
                               (2.4, 0.5, 2.3, 1.0, 73), (4.1, -0.6, 1.9, 0.9, 74)):
        lime_top = 14.0
        grass.boulder((x, y, lime_top + 0.1), (sx * 1.2, sx * 1.4, sh * 1.2), GRASS, seed=sd,
                      segments=7, rings=3, deviation=0.14)
    return [lime.to_object("Cliff_Limestone"), grass.to_object("Cliff_Grass")], 14.6


def build_lighthouse():
    """Farul de pe cap (`cape_lighthouse`).

    LISTA DE ELEMENTE (din decuparea `cape_lighthouse.png` + contractul §1.2):
      a) soclu de calcar: inel jos r 3,3 (z 0..0,5) + corp r 2,7->2,5 (z 0,5..2,0)
         = ~2 m
      b) TURN ALB conic (Lighthouse_Plaster): z 2,0..16,0, Ø 3,6 la baza ->
         2,6 sus, 16 laturi; 3 ferestre inguste negre pe +Y (z 6,0 / 9,5 / 13,0)
      c) galerie: guler evazat (z 16,0..16,5), placa de metal r 2,2 (z 16,5..16,75),
         BALUSTRADA: 12 stalpi + 2 rame circulare (`segments` 12), 0,95 m inalta
      d) felinar: cilindru de sticla `Lighthouse_Lamp` (FOAM_WHITE, 12 laturi,
         Ø 2,0, z 16,95..18,55), 6 montanti de metal
      e) CUPOLA alba (revolutie, 12 laturi) z 18,55..19,7 + varf de metal pana la
         ~20,2 m
      f) casa paznicului 6 x 5 x 3,5 m (Lighthouse_Plaster) la +X/+Y, pe placa de
         calcar (0,45 m), acoperis PLAT cu placa de calcar si buza; usa + 2
         ferestre negre pe +Y, o fereastra pe +X
      g) NU intra: stancile din jur, tufele (le pune decorul)
    Noduri: Lighthouse_Plaster (FOAM_WHITE 22), Lighthouse_Limestone
    (MARBLE_GREY 29), Lighthouse_Metal (VOLCANIC_BLACK 20: ferestre, usa,
    galerie, balustrada, montanti, varf), Lighthouse_Lamp (FOAM_WHITE 22).
    Originea: axa turnului pe XY, baza pe Z=0.
    """
    pl, lime, met, lamp = Builder(), Builder(), Builder(), Builder()
    W, M = FOAM_WHITE, VOLCANIC_BLACK
    # soclu
    lime.frustum((0, 0, 0.25), 3.3, 3.2, 0.5, OK_LIMESTONE, segments=12)
    lime.frustum((0, 0, 1.25), 2.7, 2.5, 1.5, OK_LIMESTONE, segments=12)
    # turn
    # inele intermediare: AO-ul se coace pe vertex, iar la un frustum doar cu doua
    # inele normalele netezite ale capacelor intuneca tot turnul
    pl.revolve([(1.8, 2.0), (1.8 - 0.5 * 4.0 / 14.0, 6.0), (1.8 - 0.5 * 8.0 / 14.0, 10.0),
                (1.8 - 0.5 * 12.0 / 14.0, 14.0), (1.3, 16.0)], W, segments=16)
    for zw in (6.0, 9.5, 13.0):
        r = 1.8 - 0.5 * (zw - 2.0) / 14.0
        met.box((0, r - 0.03, zw), (0.5, 0.22, 0.95), M)
    # galerie
    pl.frustum((0, 0, 16.25), 1.3, 2.0, 0.5, W, segments=16)
    met.frustum((0, 0, 16.625), 2.25, 2.25, 0.25, M, segments=12)
    for i in range(12):
        a = 2 * math.pi * i / 12
        met.cylinder((2.1 * math.cos(a), 2.1 * math.sin(a), 17.2), 0.05, 0.95, M, segments=4)
    met.torus((0, 0, 17.65), 2.1, 0.06, M, major_seg=12, minor_seg=4)
    met.torus((0, 0, 17.15), 2.1, 0.05, M, major_seg=12, minor_seg=4)
    # felinar
    lamp.cylinder((0, 0, 17.75), 1.0, 1.6, W, segments=12)
    for i in range(6):
        a = 2 * math.pi * (i + 0.5) / 6
        met.box((1.02 * math.cos(a), 1.02 * math.sin(a), 17.75), (0.1, 0.1, 1.6), M,
                rotation=Matrix.Rotation(a, 3, "Z"))
    pl.revolve([(1.3, 18.55), (1.28, 18.75), (1.05, 19.2), (0.65, 19.55), (0.25, 19.7),
                (0.0, 19.72)], W, segments=12, cap_bottom=True)
    met.frustum((0, 0, 19.95), 0.14, 0.0, 0.5, M, segments=6)
    # casa paznicului
    hx, hy = 6.0, 1.2
    lime.box((hx, hy, 0.5), (6.4, 5.4, 1.0), OK_LIMESTONE)
    pl.box((hx, hy, 1.0 + 1.75), (6.0, 5.0, 3.5), W)
    lime.box((hx, hy, 4.5 + 0.15), (6.4, 5.4, 0.3), OK_LIMESTONE)
    for (bx, by, sx, sy) in ((hx, hy + 2.6, 6.4, 0.25), (hx, hy - 2.6, 6.4, 0.25),
                             (hx + 3.1, hy, 0.25, 5.0), (hx - 3.1, hy, 0.25, 5.0)):
        lime.box((bx, by, 4.8 + 0.15), (sx, sy, 0.3), OK_LIMESTONE)
    yf = hy + 2.5
    met.box((hx - 1.0, yf + 0.0, 1.0 + 1.0), (1.1, 0.16, 2.0), M)
    for wx in (hx + 1.0, hx + 2.1):
        met.box((wx, yf + 0.0, 1.0 + 2.0), (0.8, 0.16, 0.8), M)
    met.box((hx + 3.0, hy, 1.0 + 2.0), (0.16, 0.8, 0.8), M)
    return [to_obj_nr(pl, "Lighthouse_Plaster"), to_obj_nr(lime, "Lighthouse_Limestone"),
            to_obj_nr(met, "Lighthouse_Metal"), to_obj_nr(lamp, "Lighthouse_Lamp")], 20.5


def build_coral_wall():
    """Zidul de corali (`coral_stone_wall`).

    LISTA DE ELEMENTE (din decuparea `coral_stone_wall.png`, CORECTATA de
    coordonator: pietre ROTUNJITE si neregulate, nu blocuri dreptunghiulare):
      a) modul 4,0 m (Y) x 0,8 m (X) x 1,2 m (Z), capete taiate plan la y = +-2,0
      b) 3 randuri de pietre-elipsoid: jos 6, la mijloc 5 (decalate), SUS 8
         (rand de 7-9 pietre: face conturul); marimi si inaltimi neregulate
      c) miez intunecat SAND_SHADOW 2 in spatele pietrelor = rosturile (fara
         mortar); nu iese in contur
      d) fara vegetatie, fara mortar. Mesh compact (segments 6, rings 3)
    Nod: Coral_Wall_Coral (CORAL_SAND 19 + rosturi SAND_SHADOW 2).
    """
    b = Builder()
    rnd = _ok_rand(91)
    rows = ((6, 0.30, 0.74, 0.74), (5, 0.62, 0.70, 0.70), (8, 0.88, 0.62, 0.64))
    sd = 100
    for ri, (n, zc, hz, wx) in enumerate(rows):
        ws = [0.7 + rnd() * 0.6 for _ in range(n)]
        tot = sum(ws)
        ws = [w / tot * 4.3 for w in ws]
        y = -2.15
        for w in ws:
            yc = y + w * 0.5
            y += w
            sd += 1
            b.boulder((rnd() * 0.08 - 0.04, yc, zc + (rnd() - 0.5) * 0.06),
                      (wx * (0.92 + rnd() * 0.16), w * 1.42, hz * (0.9 + rnd() * 0.25)),
                      CORAL_SAND, seed=sd, segments=6, rings=3, deviation=0.13)
    b.box((0.0, 0.0, 0.45), (0.3, 3.96, 0.9), SAND_SHADOW)
    for v in b.bm.verts:
        v.co.y = max(-2.0, min(2.0, v.co.y))
    return [b.to_object("Coral_Wall_Coral")], 1.3


ONLY = os.environ.get("OK_ONLY", "")


def _want(name):
    return not ONLY or ONLY == name


def _drop(objs):
    """Scoate nodurile dupa export, ca urmatoarea piesa sa-si pastreze numele
    (altfel Blender adauga .001)."""
    for o in objs:
        bpy.data.objects.remove(o, do_unlink=True)


def _emit_rock(name, fn, budget, smooth=None):
    objs, h = fn()
    emit_ok(objs, "rocks/%s.glb" % name, _ao(h + 0.5), keep_xy=True, bevel=0.0,
            smooth_angle=smooth, budget=budget)
    _drop(objs)


if _want("notch_rock_a"):
    _emit_rock("notch_rock_a", build_notch_rock_a, 2000)
if _want("notch_rock_b"):
    _emit_rock("notch_rock_b", build_notch_rock_b, 2000)
if _want("notch_rock_c"):
    _emit_rock("notch_rock_c", build_notch_rock_c, 2000)

if _want("heart_rock"):
    _emit_rock("heart_rock", build_heart_rock, 2500)

if _want("limestone_cliff_module"):
    _emit_rock("limestone_cliff_module", build_cliff, 3500)

if _want("cape_lighthouse"):
    objs, h = build_lighthouse()
    emit_ok(objs, "buildings/cape_lighthouse.glb", _ao(h, 0.88), keep_xy=True, bevel=0.0,
            smooth_angle=50.0, budget=6000)
    _drop(objs)

if _want("coral_stone_wall"):
    objs, h = build_coral_wall()
    emit_ok(objs, "structures/coral_stone_wall.glb",
            dict(samples=16, dist=1.2, gradient="vertical", low=0.7, high=1.0,
                 power=0.8, floor=0.3, z_range=(0.0, 1.3)),
            keep_xy=True, bevel=0.0, smooth_angle=60.0, budget=1500)
    _drop(objs)

report_ok()
