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


def to_obj_nr(b, name):
    """Builder -> obiect, cu normalele recalculate pe tot nodul."""
    return b.to_object(name)


def _mushroom(spec):
    lime, grass = Builder(), Builder()
    top = notch_cluster_rock(lime, grass, spec)
    return [to_obj_nr(lime, "Notch_Limestone"), to_obj_nr(grass, "Notch_Grass")], top


def build_notch_rock_a():
    """Stanca-ciuperca A (`notch_rock_a`): inalta si zvelta. RUNDA 4 (blocuri).

    LISTA DE ELEMENTE (decuparea `notch_rock_a.png` + contractul §1.2; cele trei
    variante au proportii DISTINCTE; runda 4: aglomerare de blocuri, nu revolutie):
      a) CAP din 12 bolovani fatetati suprapusi: 7 in stratul de jos (burta,
         fatete de ~2-3 m), 4 sus, 1 in centru; contur neregulat cu lobi; ~7,3 m lat
      b) PICIOR cu sectiune neregulata (7 laturi, jag 0,16), ~3,5 m la gat (r 1,75),
         cu NISA = scobitura sub burta capului, z 0,4..1,9, banda SAND_SHADOW
      c) FUSTA: 7 bolovani + 2 liberi la baza, din care iese piciorul
      d) iarba: 9 ciorchini de smocuri (0,8-1,4 m) pe crestet, cei de la margine
         revarsati peste buza; 2 tonuri (TROPICAL_GREEN 21 / CACTUS_GREEN 12)
      e) umbrire plata (AO mediat pe fata); inaltime totala ~8,5-9 m (h/l ~1,2)
    Noduri: Notch_Limestone (MARBLE_GREY 29 + nisa SAND_SHADOW 2), Notch_Grass.
    """
    return _mushroom(dict(
        seed=21, neck=(0.4, 1.9), tufts=9,
        stem=[(0, 2.3), (0.8, 2.0), (1.15, 1.85), (2.0, 1.8), (3.2, 1.9), (4.4, 2.1), (5.0, 2.3)],
        cap=dict(n_lo=7, rho_lo=2.1, lo_z=5.4, lo_h=2.6, sx_lo=3.3,
                 n_hi=4, rho_hi=1.2, hi_z=7.0, hi_h=2.0, sx_hi=2.4, center=(7.2, 1.8, 2.4)),
        skirt=dict(n=7, rad=2.9, sx=1.9, h=1.7, loose=2)))


def build_notch_rock_b():
    """Stanca-ciuperca B (`notch_rock_b`): lata si joasa, ca o masa. RUNDA 4.

    LISTA DE ELEMENTE:
      a) CAP LAT ~9 m din 13 bolovani: 8 jos (rho 3,0), 4 sus, 1 centru; joase
         si late (h/l ~0,55)
      b) PICIOR scurt si gros, sectiune neregulata, gat r ~2,15 (4,3 m) cu nisa
         z 0,3..1,4; stratul de jos al capului se lasa pe picior (o singura masa,
         piciorul se largeste in cap, nu e desprins)
      c) FUSTA: 8 bolovani + 2 liberi
      d) iarba: 9 ciorchini pe crestet, 2 tonuri, revarsati peste buza
    Noduri: Notch_Limestone, Notch_Grass.
    """
    return _mushroom(dict(
        seed=22, neck=(0.3, 1.4), tufts=9,
        stem=[(0, 2.6), (0.7, 2.3), (1.0, 2.05), (1.6, 2.1), (2.2, 2.5), (2.8, 2.8)],
        cap=dict(n_lo=8, rho_lo=3.0, lo_z=3.2, lo_h=1.7, sx_lo=3.3,
                 n_hi=4, rho_hi=1.6, hi_z=3.9, hi_h=1.4, sx_hi=3.0, center=(4.0, 1.3, 3.0)),
        skirt=dict(n=7, rad=3.2, sx=2.0, h=1.1, loose=2)))


def build_notch_rock_c():
    """Stanca-ciuperca C (`notch_rock_c`): aplecata spre mare (+X). RUNDA 4.

    LISTA DE ELEMENTE:
      a) CAP din 11 bolovani (7 jos + 3 sus + 1 centru), ~6,4 m lat, DEPLASAT
         2,0 m pe +X fata de picior
      b) PICIOR neregulat care se apleaca (cx ~ t^2 intre z 1,7 si 3,2), gat
         r ~1,6; NISA roasa mai adanc pe +X (bite 20%) z 0,4..1,7
      c) FUSTA: 6 bolovani + 2 liberi
      d) iarba: 8 ciorchini, 2 tonuri
    Noduri: Notch_Limestone, Notch_Grass.
    """
    return _mushroom(dict(
        seed=23, neck=(0.4, 1.7), tufts=8, lean=2.0, lean_from=1.7, bite=(0.4, 1.7, 0.2, 0.0),
        stem=[(0, 2.0), (0.8, 1.8), (1.15, 1.6), (1.7, 1.55), (2.6, 1.6), (3.2, 1.8)],
        cap=dict(n_lo=7, rho_lo=1.9, lo_z=4.0, lo_h=2.0, sx_lo=2.6,
                 n_hi=3, rho_hi=1.0, hi_z=5.2, hi_h=1.7, sx_hi=2.2, center=(5.4, 1.5, 2.2)),
        skirt=dict(n=6, rad=2.4, sx=1.6, h=1.4, loose=2)))


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
      d) 6 bolovani mici in jur (pe colturi, in afara X-ului inimii)
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
                         (3.4, 2.4, (2.3, 1.9, 1.5), 63), (-2.9, 2.6, (1.5, 1.2, 1.0), 64),
                         (0.3, -3.6, (1.3, 1.1, 0.9), 65), (-0.6, 3.7, (1.4, 1.2, 1.0), 66)])
    return [lime.to_object("Heart_Limestone")], 7.0


# statii (y, top): masa din spate are sectiune CONSTANTA (capete identice la
# y = +-6,0); doar cota crestei difera putin in interior
CLIFF_STATIONS = [(-6.0, 13.6), (-3.2, 14.0), (0.0, 13.4), (3.4, 13.9), (6.0, 13.6)]


def cliff_profile(top):
    """Sectiunea XZ a masei din spate (x = spre mare = +X): spatele plat, poala,
    NISA de val (z 0,5..3,0, scobita 1,0 m, ~2,5 m inalta), fata verticala,
    creasta rotunjita. 13 puncte. Blocurile din fata se adauga separat."""
    return [
        (-2.5, 0.0), (1.6, 0.0), (1.6, 0.5), (0.9, 1.1), (0.55, 1.7), (0.7, 2.4),
        (1.0, 3.0), (1.7, 3.4), (1.6, top - 1.2), (1.2, top), (-0.2, top + 0.3),
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
    """Modulul de faleza (`limestone_cliff_module`). RUNDA 4 (blocuri verticale).

    LISTA DE ELEMENTE (din decuparea `limestone_cliff_module.png` + §1.2):
      a) masa din spate: loft pe 5 statii, sectiune constanta, 12 m (Y) x ~4,1 m
         x ~14 m; NISA de val la baza: z 0,5..3,0 (~2,5 m), scobita 1,0 m, banda
         SAND_SHADOW; capete PLANE si IDENTICE la y = +-6,0
      b) 6 COLOANE-BOLOVAN inalte in tierul de jos (z 2,8..9,2), care ies 0,8..1,5
         m din perete (centre x 0,8..1,5 + semi-latime 1,6), deasupra nisei
         (surplomba), cu crapaturi adanci intre ele (yc -4,5..+4,5, pas 1,8)
      c) 5 blocuri in tierul de sus (z 8,5..13,7), ies 0,6..1,1 m, decalate pe Y
      d) coloanele raman in |y| < 5,9: capetele modulului nu sunt atinse
      e) creastet cu iarba: banda `Cliff_Grass` pe masa din spate + 9 ciorchini de
         smocuri (2 tonuri) revarsati peste blocurile de sus
      f) fara copaci/arbusti inalti; umbrire plata
    Noduri: Cliff_Limestone (MARBLE_GREY 29 + nisa SAND_SHADOW 2), Cliff_Grass
    (TROPICAL_GREEN 21 + CACTUS_GREEN 12).
    """
    lime, grass = Builder(), Builder()
    profs = [cliff_profile(t) for (_, t) in CLIFF_STATIONS]
    ys = [y for (y, _) in CLIFF_STATIONS]
    _stations_loft(lime, profs, ys, lambda i: OK_NICHE if i in (2, 3, 4, 5) else OK_LIMESTONE,
                   OK_LIMESTONE)
    gprofs = []
    for P in profs:
        a, c, d_ = P[-4], P[-3], P[-2]
        gprofs.append([(a[0] + 0.12, a[1] - 0.35), (a[0], a[1] + 0.22), (c[0], c[1] + 0.22),
                       (d_[0], d_[1] + 0.2), (d_[0] - 0.3, d_[1] - 0.2),
                       (d_[0] - 0.3, d_[1] - 0.5), (a[0] - 0.1, a[1] - 0.9)])
    _stations_loft(grass, gprofs, ys, lambda i: GRASS, GRASS)
    rnd = _ok_rand(55)
    lo_y = (-4.5, -3.0, -1.2, 0.4, 2.3, 4.5)
    lo_x = (1.5, 0.8, 1.3, 0.9, 1.5, 1.1)
    for i, yc in enumerate(lo_y):
        edge = abs(yc) > 4.0
        sy = 2.5 if edge else 2.2 + rnd() * 1.0
        chunk(lime, (lo_x[i], yc + (0.0 if edge else (rnd() - 0.5) * 0.5),
                     6.0 + (rnd() - 0.5) * 1.4),
              (2.6 + rnd() * 1.0, sy, 5.0 + rnd() * 2.4), 300 + i, OK_LIMESTONE, seg=7, nr=5,
              jag=0.2, tilt=0.07, yaw=(rnd() - 0.5) * 1.0)
    hi_y = (-3.9, -2.2, -0.1, 1.9, 3.8)
    hi_x = (0.9, 0.6, 1.2, 0.7, 1.0)
    for i, yc in enumerate(hi_y):
        chunk(lime, (hi_x[i], yc + (rnd() - 0.5) * 0.6, 11.2 + (rnd() - 0.5) * 0.9),
              (2.6 + rnd() * 1.0, 2.0 + rnd() * 1.0, 4.4 + rnd() * 1.6), 320 + i, OK_LIMESTONE,
              seg=7, nr=5, jag=0.2, tilt=0.07, yaw=(rnd() - 0.5) * 1.0)
    for i, (yc, xc) in enumerate(((-4.4, 0.9), (-3.0, -0.5), (-1.6, 0.8), (-0.2, -0.6),
                                  (1.3, 0.9), (2.6, -0.3), (3.9, 0.8), (4.8, -0.5), (0.5, 1.4))):
        s = 1.1 + rnd() * 0.5
        chunk(grass, (xc, yc, 14.1 + s * 0.15), (s * 1.5, s * 1.3, s * 0.9), 340 + i,
              GRASS if i % 3 != 2 else CACTUS_GREEN, seg=6, nr=3, jag=0.18)
    return [lime.to_object("Cliff_Limestone"), grass.to_object("Cliff_Grass")], 14.9


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
         calcar (0,45 m), acoperis PLAT ROSU (`Lighthouse_Roof`, TILE_TERRACOTTA 23, placa 6,5 x 5,5 x 0,3, mica streasina); usa + 2
         ferestre negre pe +Y, o fereastra pe +X
      g) NU intra: stancile din jur, tufele (le pune decorul)
    Noduri: Lighthouse_Plaster (FOAM_WHITE 22), Lighthouse_Limestone
    (MARBLE_GREY 29), Lighthouse_Roof (TILE_TERRACOTTA 23), Lighthouse_Metal (VOLCANIC_BLACK 20: ferestre, usa,
    galerie, balustrada, montanti, varf), Lighthouse_Lamp (FOAM_WHITE 22).
    Originea: axa turnului pe XY, baza pe Z=0.
    """
    pl, lime, met, lamp, roof = Builder(), Builder(), Builder(), Builder(), Builder()
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
    roof.box((hx, hy, 4.5 + 0.15), (6.5, 5.5, 0.3), OK_TILE)
    yf = hy + 2.5
    met.box((hx - 1.0, yf + 0.0, 1.0 + 1.0), (1.1, 0.16, 2.0), M)
    for wx in (hx + 1.0, hx + 2.1):
        met.box((wx, yf + 0.0, 1.0 + 2.0), (0.8, 0.16, 0.8), M)
    met.box((hx + 3.0, hy, 1.0 + 2.0), (0.16, 0.8, 0.8), M)
    return [to_obj_nr(pl, "Lighthouse_Plaster"), to_obj_nr(lime, "Lighthouse_Limestone"),
            to_obj_nr(met, "Lighthouse_Metal"), to_obj_nr(lamp, "Lighthouse_Lamp"),
            to_obj_nr(roof, "Lighthouse_Roof")], 20.5


def build_coral_wall():
    """Zidul de corali (`coral_stone_wall`). RUNDA 4 (asize mici).

    LISTA DE ELEMENTE (decuparea `coral_stone_wall.png`, CORECTATA: pietre
    ROTUNJITE si neregulate, nu blocuri dreptunghiulare):
      a) modul 4,0 m (Y) x 0,8 m (X) x 1,2 m (Z), capete taiate plan la y = +-2,0
      b) 5 ASIZE de pietre mici (0,45-0,6 m pe Y, ~0,25 m inaltime), cate 8/8/8/8/7,
         decalate de la un rand la altul; RANDUL DE SUS are 7 pietre si face
         creasta (mai plata)
      c) pietre-pebble fatetate (6 laturi, 2 inele), umbrire plata; miez SAND_SHADOW
         subtire in spate (rosturile), fara mortar; fara vegetatie
      d) buget ~900 tri (se repeta de sute de ori)
    Nod: Coral_Wall_Coral (CORAL_SAND 19 + rosturi SAND_SHADOW 2).
    """
    b = Builder()
    rnd = _ok_rand(91)
    counts = (8, 8, 8, 8, 7)
    sd = 400
    for ri, n in enumerate(counts):
        ws = [0.8 + rnd() * 0.4 for _ in range(n)]
        tot = sum(ws)
        ws = [w / tot * 4.2 for w in ws]
        y = -2.1 + (0.12 if ri % 2 else 0.0)
        zc = 0.17 + 0.215 * ri
        for w in ws:
            yc = y + w * 0.5
            y += w
            sd += 1
            b.boulder((rnd() * 0.06 - 0.03, yc, zc + (rnd() - 0.5) * 0.04),
                      (0.70 + rnd() * 0.08, w * 1.12, 0.40 + rnd() * 0.08), CORAL_SAND,
                      seed=sd, segments=6, rings=2, deviation=0.14)
    b.box((0.0, 0.0, 0.5), (0.3, 3.96, 1.0), SAND_SHADOW)
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
            smooth_angle=smooth, budget=budget, flat_ao=True)
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
            keep_xy=True, bevel=0.0, smooth_angle=None, budget=1500, flat_ao=True)
    _drop(objs)

report_ok()
