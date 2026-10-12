"""Okinawa v2 -- coasta (brief docs/asset_briefs/okinawa_kit_v2.md §1.2).

  okinawa/rocks/notch_rock_a.glb          stanca-ciuperca inalta si zvelta
  okinawa/rocks/notch_rock_b.glb          stanca-ciuperca lata si joasa
  okinawa/rocks/notch_rock_c.glb          stanca-ciuperca aplecata spre mare
  okinawa/rocks/heart_rock.glb            stanca-inima (doi lobi, varf in apa)
  okinawa/rocks/limestone_cliff_module.glb  faleza inlantuibila 12 m (varianta A)
  okinawa/rocks/limestone_cliff_module_b.glb  varianta B (aceleasi capete, alt interior)
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


def _mushroom(spec, zscale=1.0):
    """`zscale`: compresia pe Z (dupa construire) ca inaltimea TOTALA (cu iarba)
    sa intre in cota din contract; orizontalele (cap, gat) raman neatinse."""
    lime, grass = Builder(), Builder()
    top = mushroom_rock(lime, grass, spec)
    objs = [to_obj_nr(lime, "Notch_Limestone"), to_obj_nr(grass, "Notch_Grass")]
    if zscale != 1.0:
        for o in objs:
            for v in o.data.vertices:
                v.co.z *= zscale
    return objs, top * zscale


def build_notch_rock_a():
    """Stanca-ciuperca A (`notch_rock_a`): inalta si zvelta. RUNDA 5 (ok-g):
    SILUETA intai (profil de ciuperca), abia apoi fatetarea.

    LISTA DE ELEMENTE (decuparea `notch_rock_a.png` + verdictul de la runda 4):
      a) GAT zvelt: r 1,4 (Ø 2,8 m) intre z 3,0 si 3,9, cu poala EVAZATA la baza
         (r 3,3 la z 0 -> 1,4 la z 3,0)
      b) NISA concava sub buza: raza creste de la 1,4 (z 3,9) la 3,9 (z 6,9)
         dupa o curba de trompeta (banda SAND_SHADOW z 4,9..6,4)
      c) CAP: buza la z 6,9, r 3,9 (Ø ~7,8 m), surplomba ~2,5 m pe toate partile;
         grosime ~2 m; cupola turtita pana la z 8,5; 9 bolovani de 2,4 m pe
         buza + 4 pe cupola (fatete de 1-2 m, umbrire plata)
      d) FUSTA: 7 bolovani + 2 liberi la baza
      e) iarba: piele joasa pe cupola + 10 ciorchini pe 2 tonuri (21 / 12),
         cei de la margine revarsati peste buza
      f) cap/gat = 7,8 / 2,8 = 2,8
    Noduri: Notch_Limestone (MARBLE_GREY 29 + nisa SAND_SHADOW 2), Notch_Grass.
    """
    return _mushroom(dict(
        seed=21, neck=(4.7, 6.0), rim_z=6.7, rim_r=3.9, top_z=8.55, tufts=10,
        prof=[(0, 3.3), (0.6, 2.7), (1.4, 2.0), (2.2, 1.55), (3.0, 1.4), (3.9, 1.4), (4.6, 1.5),
              (5.1, 1.85), (5.5, 2.5), (5.85, 3.2), (6.2, 3.7), (6.6, 3.9), (7.2, 3.9),
              (7.7, 3.6), (8.1, 2.9), (8.4, 1.9), (8.55, 0.9)],
        rim_n=9, rim_size=2.6, top_n=4,
        skirt=dict(n=7, rad=3.4, sx=1.9, h=1.7, loose=2)), zscale=0.88)


def build_notch_rock_b():
    """Stanca-ciuperca B (`notch_rock_b`): lata si joasa, ca o masa. RUNDA 5.

    LISTA DE ELEMENTE:
      a) GAT scurt: r 2,0 (Ø 4 m) la z ~2, baza evazata r 3,9
      b) NISA concava sub buza (z 2,4..3,3), raza 2,0 -> 4,5
      c) CAP LAT: buza la z 3,5, r 4,5 (Ø 9 m), surplomba 2,5 m, cupola joasa
         pana la z 4,65; 10 bolovani de 2,8 m pe buza + 4 pe cupola
      d) FUSTA: 8 bolovani + 2 liberi
      e) iarba: piele + 9 ciorchini, 2 tonuri
      f) cap/gat = 9 / 4 = 2,25
    Noduri: Notch_Limestone, Notch_Grass.
    """
    return _mushroom(dict(
        seed=22, neck=(2.2, 3.0), rim_z=3.5, rim_r=4.5, top_z=4.7, tufts=9,
        prof=[(0, 3.3), (0.5, 2.6), (1.1, 2.15), (1.7, 2.0), (2.1, 2.05), (2.4, 2.4),
              (2.7, 3.2), (3.0, 4.0), (3.3, 4.4), (3.7, 4.5), (4.1, 4.3), (4.4, 3.5),
              (4.6, 2.4), (4.7, 1.1)],
        rim_n=10, rim_size=2.4, top_n=4,
        skirt=dict(n=5, rad=3.0, sx=1.5, h=0.8, loose=1)), zscale=0.86)


def build_notch_rock_c():
    """Stanca-ciuperca C (`notch_rock_c`): aplecata spre mare (+X). RUNDA 5.

    LISTA DE ELEMENTE:
      a) GAT aplecat: r 1,3 (Ø 2,6 m), axa se deplaseaza spre +X intre z 1,8 si
         4,8 (smoothstep), baza evazata r 2,8
      b) NISA concava sub buza (z 3,9..4,9), raza 1,3 -> 3,3
      c) CAP: buza la z 5,0, r 3,3 (Ø ~6,5 m), DEPLASAT 2,0 m pe +X fata de axa
         bazei; cupola pana la z 5,9; 8 bolovani de 2,1 m pe buza + 3 pe cupola
      d) FUSTA: 6 bolovani + 2 liberi
      e) iarba: piele + 8 ciorchini
    Noduri: Notch_Limestone, Notch_Grass.
    """
    return _mushroom(dict(
        seed=23, neck=(3.4, 4.2), rim_z=4.7, rim_r=3.6, top_z=5.75, tufts=8,
        lean=2.0, lean_from=1.5, lean_to=4.4,
        prof=[(0, 2.6), (0.5, 2.2), (1.0, 1.75), (1.5, 1.4), (2.2, 1.3), (2.9, 1.3),
              (3.4, 1.4), (3.7, 1.8), (4.0, 2.6), (4.3, 3.3), (4.6, 3.6), (5.0, 3.6),
              (5.35, 3.1), (5.6, 2.2), (5.75, 1.0)],
        rim_n=8, rim_size=2.3, top_n=3,
        skirt=dict(n=5, rad=2.4, sx=1.5, h=1.1, loose=1)), zscale=0.93)


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


def _row(y0, y1, widths, gap=0.22):
    """Centrele coloanelor puse cap la cap de la y0 la y1 (latimi `widths`,
    crapaturi `gap`), scalate sa umple intervalul. Returneaza (centre, latimi,
    centrele crapaturilor)."""
    tot = sum(widths) + gap * (len(widths) - 1)
    k = (y1 - y0) / tot
    y, cs, cracks = y0, [], []
    for i, w in enumerate(widths):
        cs.append(y + w * k * 0.5)
        y += w * k
        if i < len(widths) - 1:
            cracks.append(y + gap * k * 0.5)
            y += gap * k
    return cs, [w * k for w in widths], cracks


def _cliff(seed, stations, lw, lz, lx, lk, uw, uz, ux, uk, rz):
    """Treapta de jos (`lw` latimi, `lz` varfuri, `lx` pozitii x, `lk` cotituri),
    treapta de sus (`uw`...), coloane din spate in crapaturile treptei de sus."""
    lime, grass = Builder(), Builder()
    cs, ws, _ = _row(-3.9, 3.9, lw, gap=0.1)
    lower = [(cs[i], ws[i], lx[i], lz[i], lk[i][0], lk[i][1]) for i in range(len(cs))]
    cs, ws, cracks = _row(-3.9, 3.9, uw, gap=0.3)
    upper = [(cs[i], ws[i], ux[i], uz[i], uk[i][0], uk[i][1]) for i in range(len(cs))]
    rear = [(cracks[i], 1.5 + 0.3 * ((i + seed) % 2), -0.2, rz[i], 0.12, 0.0)
            for i in range(len(cracks))]
    top = cliff_columns_module(lime, grass, seed, stations, lower, upper, rear)
    return [lime.to_object("Cliff_Limestone"), grass.to_object("Cliff_Grass")], top


# capetele (y = +-6) sunt IDENTICE in ambele variante: top 13,4, nisa 1,0 x 3,0
_END = (13.4, 1.0, 3.0)


def build_cliff():
    """Modulul de faleza (`limestone_cliff_module`), varianta A. RUNDA 5 (ok-g).

    LISTA DE ELEMENTE (decuparea `limestone_cliff_module.png` + verdictul de la
    runda 4: coloane care formeaza SUPRAFATA, nu oua pe o placa):
      a) masa din spate: loft pe 9 statii (pas 1,5 m), perete retras la x 0,4;
         NISA de val NEREGULATA: adancime 0,75..1,35 m, tavan la z 2,4..3,5 m,
         variaza de la o statie la alta; capete PLANE si IDENTICE la y = +-6
      b) DOUA TREPTE de coloane prismatice (hexagoane/heptagoane neregulate, jag
         0,3): jos 4 coloane late de 1,6-2,4 m, varfuri la z 6,4..8,8, care ies
         peste nisa; sus 3 coloane de 2,4-2,7 m (z 11,4..14), retrase, cu crapaturi
         care NU se aliniaza cu cele de jos; cotitura la mijloc = prag
      c) 2 coloane din spate in crapaturile treptei de sus (z 9,8 / 10,4)
      d) 2 stive de coloane de CAPAT identice in A si B (y = +-5,0, jag 0,04,
         doua trepte)
      e) iarba: banda pe masa din spate + cate o placa de iarba pe fiecare coloana
         (+ ciorchini pe 2 tonuri)
      f) fara arbori; umbrire plata
    Noduri: Cliff_Limestone (MARBLE_GREY 29 + nisa SAND_SHADOW 2), Cliff_Grass
    (TROPICAL_GREEN 21 + CACTUS_GREEN 12).
    """
    st = [(-6.0,) + _END, (-4.5, 13.9, 1.25, 2.6), (-3.0, 14.2, 0.8, 3.4), (-1.5, 13.6, 1.3, 2.4),
          (0.0, 14.0, 0.9, 3.2), (1.5, 13.5, 1.35, 2.7), (3.0, 14.1, 0.75, 3.5),
          (4.5, 13.7, 1.15, 2.9), (6.0,) + _END]
    return _cliff(55, st, [2.2, 1.7, 2.4, 1.6], [7.4, 8.8, 6.4, 8.2], [1.7, 1.5, 1.9, 1.4],
                  [(0.2, 0.1), (-0.2, 0.0), (0.25, -0.1), (-0.15, 0.1)],
                  [2.6, 2.4, 2.7], [13.6, 11.4, 14.0], [0.7, 0.5, 0.8],
                  [(0.25, 0.1), (-0.2, 0.0), (0.2, -0.1)], [9.8, 10.4])


def build_cliff_b():
    """Modulul de faleza, varianta B (`limestone_cliff_module_b`): aceleasi capete
    plane la +-6 m, aceeasi sectiune de capat si aceleasi coloane de capat ca A,
    alt interior (RUNDA 5, ok-g).

    LISTA DE ELEMENTE:
      a) masa din spate: 9 statii cu alta nisa (adancime 0,75..1,35, tavan z
         2,4..3,6) si alta creasta
      b) treapta de jos: 4 coloane (1,6-2,6 m) cu alt ritm (2,6 m la a doua),
         varfuri 6,6..8,6; treapta de sus: 4 coloane de ~2 m (11,6..14), cotituri
         inverse fata de A
      c) 3 coloane din spate; coloanele de capat identice cu A
      d) iarba ca la A; fara arbori; umbrire plata
    Noduri: Cliff_Limestone, Cliff_Grass.
    """
    st = [(-6.0,) + _END, (-4.5, 13.8, 0.9, 3.3), (-3.0, 13.5, 1.35, 2.5), (-1.5, 14.2, 0.75, 3.6),
          (0.0, 13.7, 1.25, 2.6), (1.5, 14.1, 0.85, 3.3), (3.0, 13.6, 1.3, 2.4),
          (4.5, 14.0, 1.0, 3.1), (6.0,) + _END]
    return _cliff(61, st, [1.7, 2.6, 1.6, 2.3], [8.6, 6.6, 8.0, 7.2], [1.4, 1.9, 1.5, 1.8],
                  [(-0.2, 0.1), (0.2, 0.0), (-0.25, -0.1), (0.2, 0.1)],
                  [1.9, 2.2, 1.8, 2.0], [11.6, 14.0, 12.4, 13.4], [0.5, 0.8, 0.6, 0.7],
                  [(-0.25, 0.1), (0.2, -0.1), (-0.15, 0.0), (0.25, 0.0)], [9.6, 10.6, 9.2])


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
    _emit_rock("limestone_cliff_module", build_cliff, 4500)

if _want("limestone_cliff_module_b"):
    _emit_rock("limestone_cliff_module_b", build_cliff_b, 4500)

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
