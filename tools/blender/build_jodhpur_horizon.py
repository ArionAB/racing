"""Jodhpur -- Fundalul (brief §1.7, val 5 grupa fundal,
docs/asset_briefs/jodhpur_kit.md).

  jodhpur/rocks/jodhpur_horizon.glb
      UmaidBhawan_A                 palatul cu cupola, 60 x 30 x 35 m
      FarCity_A                     banda de case albastre, 150 x 20 x 12 m
        +-- FarCity_A_Beige         (copil) casele bej + rezervoarele negre
        +-- FarCity_A_Glow          (copil) geamurile, VOLCANIC_BLACK
      DesertRidge_A, DesertRidge_B  dealuri joase de riolit, 200 x 60 x 30 m

UN SINGUR fisier, ca `fiordland_horizon.glb` (conventia gasita la celelalte
piste, vezi inventarul). Consumatorul e `Track._build_horizon`
(scenes/tracks/track.gd:4848):
  - ia nodul DUPA NUME EXACT, copil direct al radacinii
    (`_extract_glb_node`), cu tot subarborele lui -- deci copiii
    `FarCity_A_Beige`/`FarCity_A_Glow` pleaca impreuna cu `FarCity_A`;
  - il recentreaza (`container.position = -kept.position`), deci pozitia
    nodului in GLB nu conteaza; toate stau la origine, ca la Fiordland;
  - il ingroapa 4 m sub teren, ii da YAW ALEATOR si il scaleaza pe inel;
  - ii stinge umbra aruncata (`_fara_umbra_aruncata`, memoria
    caster-departat-fura-umbra) -- deci aici nu e nimic de facut pentru asta.
Consecinte de geometrie: fiecare nod e un VOLUM INCHIS, lizibil din orice
azimut, originea la baza, iar primii 4 m de jos nu se vad (nimic important
sub z = 4).

Clase la integrare (nu le fac eu): peretii albastri sunt pe `FOAM_WHITE`
(alb x tenta `blue_lime_light`, brief §0.4) in nodul `FarCity_A`; casele bej
si rezervoarele stau in copilul `FarCity_A_Beige`, pe atlas, ca o clasa pusa
pe `FarCity_A` sa nu le vopseasca albastru (`Palette._class_for` alege
prefixul cel mai LUNG, deci `{"FarCity_A": "blue_lime_light",
"FarCity_A_Beige": ""}` le separa). Fara clasa (`horizon_class: ""`), casele
albastre ies ALBE -- de stiut la integrare.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_jodhpur_horizon.py
"""

import math
import bmesh
from mathutils import Vector

STONE = ROCK_LIGHT        # gresia palatului (brief §0.4)
STONE_LIGHT = SAND_MID    # cupolele si cornisele: treapta mai deschisa
WALL = FOAM_WHITE         # peretii albastri (tenta blue_lime_light)
WALL_BEIGE = SAND_LIGHT   # casele bej din dioramă
TANK = LOG_DARK           # rezervoarele negre de pe acoperis
GLOW = VOLCANIC_BLACK     # geamurile, ziua goluri inchise (regula 7)
RHYOLITE = ROCK_DARK      # riolitul (corect aici, nu bazalt)
SCREE = SAND_SHADOW       # pantele domoale, cu praf
APRON = SAND_MID          # poalele nisipoase

BURY = 4.0                # cat ingroapa `_build_horizon`

AO_PALACE = dict(samples=16, dist=8.0, gradient="vertical",
                 low=0.55, high=1.00, power=0.85, floor=0.22)
AO_CITY = dict(samples=12, dist=5.0, gradient="vertical",
               low=0.55, high=1.00, power=0.85, floor=0.22)
AO_RIDGE = dict(samples=12, dist=30.0, gradient="vertical",
                low=0.50, high=1.00, power=0.85, floor=0.20)


def _face(b, verts, slot, want):
    """Fata cu normala dorita (verifica si intoarce ordinea), pe slotul dat."""
    f = b.bm.faces.new(verts)
    f.normal_update()
    if f.normal.dot(Vector(want)) < 0.0:
        f.normal_flip()
    f[b.slot] = slot
    return f


def _to_object_raw(b, name):
    """Ca `Builder.to_object`, dar FARA recalc_face_normals: placile de geam
    sunt quad-uri izolate, iar recalcularea pe o fata deschisa poate intoarce
    normala spre interiorul casei (backface culling in Godot = geam invizibil).
    Orientarea e deja pusa corect de `_face`."""
    me = bpy.data.meshes.new(name)
    b.bm.to_mesh(me)
    b.bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return obj


# --- UmaidBhawan_A ------------------------------------------------------------

def build_umaid_bhawan():
    """Palatul Umaid Bhawan, silueta de orizont. 60 (X) x 30 (Y) x 35 (Z) m.

    Nu are decupare pe plansa; referinta e diorama (`jodhpur_diorama_v02.jpg`,
    palatul de pe dealul din fundal, decupat in
    docs/track_briefs/img/jodhpur_horizon_ref/umaid_bhawan.png) plus contractul
    din brief: "cupola centrala inalta, turnurile laterale, aripile in
    trepte". Lista de elemente, scrisa inainte de geometrie:

      1. soclu/terasa pe toata amprenta, 60 x 30, 6 m (4 m ingropati: raman
         2 m de terasa vizibila);
      2. corpul central 18 x 26 m, pana la 22 m, cu cornisa;
      3. tamburul cupolei: cilindru cu 12 laturi, r 6,2, 22 -> 26,5 m, cu
         brau (inel iesit) sus;
      4. CUPOLA CENTRALA INALTA, mai inalta decat emisfera (profil
         Indo-Deco, umar larg, varf strans), r 6,6, 27 -> 33,6 m;
      5. lanterna + finial pana la 35 m (varful bbox-ului);
      6. DOUA TURNURI LATERALE ZVELTE, 4 x 4 m, de o parte si de alta a
         corpului central (x = +-12,4), pana la 26,5 m, cu cornisa, cupola
         mica (r 2) si finial -> ~31 m: cele doua "turle" ale siluetei din
         dioramă (acolo mai inalte decat corpul, subtiri);
      7. aripile in TREPTE, simetrice: aripa interioara 10 x 24 m pana la
         18 m, aripa exterioara 11 x 20 m pana la 13 m (trei trepte de
         inaltime de la centru spre capete: 22 -> 18 -> 13), fiecare cu
         cornisa;
      8. 4 chhatri mici (cupolite pe tambur) pe colturile aripilor
         exterioare -- zimtii mici de la capetele siluetei;
      9. portic in fata corpului central (10 x 2 m, pana la 12 m).
    Culori: corpul `ROCK_LIGHT` (gresia), cupolele si cornisele `SAND_MID`
    (treapta mai deschisa, prinde lumina de apus). Fara geamuri: la 200+ m
    un gol de 1 m e sub un pixel; noaptea palatul ramane silueta."""
    b = Builder()

    def block(x0, x1, y0, y1, z0, z1, cornice=0.0):
        b.box(((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
              (x1 - x0, y1 - y0, z1 - z0), STONE)
        if cornice > 0.0:
            b.box(((x0 + x1) * 0.5, (y0 + y1) * 0.5, z1 - 0.35),
                  (x1 - x0 + 2 * cornice, y1 - y0 + 2 * cornice, 0.7),
                  STONE_LIGHT)

    # 1. soclul (o treapta mica deasupra, ca terasa sa aiba muchie)
    block(-30.0, 30.0, -15.0, 15.0, 0.0, 5.4)
    block(-29.0, 29.0, -14.0, 14.0, 5.4, 6.0)
    # 7. aripile (exterioare, apoi interioare), simetrice
    for s in (-1.0, 1.0):
        xa, xb = sorted((s * 18.6, s * 28.6))
        block(xa, xb, -10.0, 10.0, 6.0, 13.0, cornice=0.6)
        xa, xb = sorted((s * 8.6, s * 18.8))
        block(xa, xb, -12.0, 12.0, 6.0, 18.0, cornice=0.6)
    # 2. corpul central
    block(-9.0, 9.0, -13.0, 13.0, 6.0, 22.0, cornice=0.7)
    # 9. porticul din fata
    block(-5.0, 5.0, -14.6, -13.0, 6.0, 12.0, cornice=0.4)

    # 3. tamburul + braul
    b.cylinder((0.0, 0.0, 24.25), 6.2, 4.5, STONE, segments=12)
    b.cylinder((0.0, 0.0, 26.8), 6.8, 0.6, STONE_LIGHT, segments=12)
    # 4. cupola centrala (profil (raza, z) de la baza la varf)
    z0 = 27.1
    prof = [(6.6, 0.0), (6.7, 1.3), (6.4, 2.8), (5.6, 4.1), (4.2, 5.2),
            (2.4, 6.1), (1.2, 6.5), (0.0, 6.6)]
    b.revolve(prof, STONE_LIGHT, segments=12, origin=(0.0, 0.0, z0))
    # 5. lanterna + finial
    b.cylinder((0.0, 0.0, z0 + 6.5 + 0.45), 1.2, 0.9, STONE_LIGHT, segments=8)
    b.frustum((0.0, 0.0, z0 + 6.95 + 0.475), 0.9, 0.0, 0.95, STONE_LIGHT,
              segments=8)

    # 6. turnurile laterale
    for s in (-1.0, 1.0):
        x = s * 12.4
        block(x - 2.0, x + 2.0, -2.0, 2.0, 18.0, 26.5, cornice=0.5)
        b.cylinder((x, 0.0, 27.0), 1.7, 1.0, STONE, segments=8)
        b.revolve([(2.0, 0.0), (1.9, 1.0), (1.4, 1.9), (0.6, 2.6), (0.0, 2.8)],
                  STONE_LIGHT, segments=8, origin=(x, 0.0, 27.5))
        b.frustum((x, 0.0, 30.3 + 0.5), 0.35, 0.0, 1.0, STONE_LIGHT, segments=6)

    # 8. chhatri pe colturile aripilor exterioare
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            cx, cy = sx * 26.8, sy * 8.2
            b.cylinder((cx, cy, 13.9), 1.2, 1.8, STONE, segments=8)
            b.revolve([(1.5, 0.0), (1.35, 0.8), (0.8, 1.45), (0.0, 1.8)],
                      STONE_LIGHT, segments=8, origin=(cx, cy, 14.8))

    return b.to_object("UmaidBhawan_A")


# --- FarCity_A ------------------------------------------------------------------

def _house(bw, bgl, x0, x1, y0, y1, h, side, cols, floors, slot):
    """Cutie INCHISA de casa, cu geamuri retrase 0,15 m pe fata exterioara
    (`side` = +1: fata y1, normala +Y; -1: fata y0). Fata cu geamuri e o
    grila: randuri pline (n-gon pe toata latimea) alternand cu benzi de geam
    (bucati pline + goluri). Fetele laterale/sus/jos includ toti vertecsii de
    pe muchia comuna, deci fara T-uri. Geamul (placa `GLOW`) sta in `bgl`, la
    fundul golului (regula 7: fata retrasa, nu coplanara).

    `cols`: lista de (u0, u1) pe X; `floors`: lista de (z0, z1)."""
    yf = y1 if side > 0 else y0
    yb = y0 if side > 0 else y1
    n_out = Vector((0.0, side, 0.0))
    us = [x0] + [u for c in cols for u in c] + [x1]
    zs = [0.0] + [z for f in floors for z in f] + [h]
    bm = bw.bm
    g = {}
    for i, u in enumerate(us):
        for j, z in enumerate(zs):
            g[(i, j)] = bm.verts.new((u, yf, z))
    ni, nj = len(us) - 1, len(zs) - 1
    DEPTH = 0.15
    for j in range(nj):
        if j % 2 == 0:  # rand plin, pe toata latimea
            ring = [g[(i, j)] for i in range(ni + 1)] + \
                   [g[(i, j + 1)] for i in range(ni, -1, -1)]
            _face(bw, ring, slot, n_out)
            continue
        for i in range(ni):
            a, c = g[(i, j)], g[(i + 1, j)]
            d, e = g[(i + 1, j + 1)], g[(i, j + 1)]
            if i % 2 == 0:
                _face(bw, (a, c, d, e), slot, n_out)
                continue
            # gol: 4 fete de intrados, spre interior
            ins = [bm.verts.new(v.co - n_out * DEPTH) for v in (a, c, d, e)]
            ia, ic, idd, ie = ins
            _face(bw, (a, c, ic, ia), slot, (0, 0, 1))     # pervaz
            _face(bw, (e, d, idd, ie), slot, (0, 0, -1))   # buiandrug
            _face(bw, (a, e, ie, ia), slot, (1, 0, 0))     # stanga
            _face(bw, (c, d, idd, ic), slot, (-1, 0, 0))   # dreapta
            # placa de geam, in nodul Glow
            gv = [bgl.bm.verts.new(v.co - n_out * DEPTH) for v in (a, c, d, e)]
            _face(bgl, gv, GLOW, n_out)
    # restul cutiei
    top = nj
    b0 = bm.verts.new((x0, yb, 0.0))
    b1 = bm.verts.new((x1, yb, 0.0))
    t0 = bm.verts.new((x0, yb, h))
    t1 = bm.verts.new((x1, yb, h))
    _face(bw, (b0, b1, t1, t0), slot, -n_out)                        # spate
    _face(bw, [g[(0, j)] for j in range(nj + 1)] + [t0, b0], slot,
          (-1, 0, 0))                                                 # capat x0
    _face(bw, [g[(ni, j)] for j in range(nj + 1)] + [t1, b1], slot,
          (1, 0, 0))                                                  # capat x1
    _face(bw, [g[(i, top)] for i in range(ni + 1)] + [t1, t0], slot,
          (0, 0, 1))                                                  # acoperis
    _face(bw, [g[(i, 0)] for i in range(ni + 1)] + [b1, b0], slot,
          (0, 0, -1))                                                 # talpa


CITY_LEN, CITY_DEPTH, CITY_H = 150.0, 20.0, 12.0


def build_far_city():
    """Banda de case albastre si bej, 150 (X) x 20 (Y) x 12 (Z) m.

    Referinta: marginea de sus a orasului albastru din dioramă (decupata in
    docs/track_briefs/img/jodhpur_horizon_ref/far_city.png): cuburi
    albastre de 2-3 etaje, lipite, cu acoperis plat, cate o casa bej printre
    ele, rezervoare negre pe acoperisuri si cutii de scara. Elemente:

      1. DOUA RANDURI de case spate in spate (fata spre -Y si fata spre +Y),
         ca banda sa fie volum inchis vazuta din orice azimut; fiecare casa e
         o cutie intreaga, de la y = 0 pana la fata exterioara;
      2. latimi 5-9 m, adancimi 8,5-10 m (fatadele nealiniate, +-1,5 m);
      3. inaltimi 6,6-11 m de la baza (dupa ingroparea de 4 m: 2,6-7 m, adica
         1-2 etaje vizibile) -- LINIA ZIMTATA a acoperisurilor vine din
         saltul de inaltime intre vecini si din volumele retrase de sus;
      4. ~28% din case BEJ (`SAND_LIGHT`, in copilul `FarCity_A_Beige`);
      5. volum retras pe ~40% din acoperisuri (jumatate din latime, 2,6 m,
         spre interiorul benzii: etajul in trepte din dioramă) si
         REZERVOARE NEGRE (cilindri cu 5 laturi, r 0,75, 1,3 m) pe ~40%, fara
         sa treaca de 12 m;
      6. geamuri pe fata exterioara, doar peste z = 4 (partea vizibila):
         1 geam pe etaj la casele sub 6,5 m latime, 2 peste; 0,9 x 1,3 m,
         retrase 0,15 m, placa in `FarCity_A_Glow` (se aprind noaptea)."""
    rnd = _lcg(1707)
    bw, bb, bg = Builder(), Builder(), Builder()
    half = CITY_LEN * 0.5
    for side in (-1.0, 1.0):
        x = -half
        while x < half - 0.1:
            w = 5.0 + rnd() * 4.0
            if half - (x + w) < 4.0:   # ultima casa inchide banda exact la capat
                w = half - x
            depth = CITY_DEPTH * 0.5 - rnd() * 1.5
            y0, y1 = (0.0, depth) if side > 0 else (-depth, 0.0)
            h = 6.6 + rnd() * 4.4
            beige = rnd() < 0.28
            slot = WALL_BEIGE if beige else WALL
            bwall = bb if beige else bw
            n_cols = 1 if w < 6.5 else 2
            cols = []
            for k in range(n_cols):
                uc = x + w * (k + 1) / (n_cols + 1)
                cols.append((uc - 0.45, uc + 0.45))
            floors = []
            z = BURY + 0.8
            while z + 1.3 < h - 0.7:
                floors.append((z, z + 1.3))
                z += 3.1
            _house(bwall, bg, x, x + w, y0, y1, h, side, cols, floors, slot)
            # acoperisul: cutie de scara si/sau rezervor, sub plafonul de 12 m
            yin = (y0 + y1) * 0.5 + side * 1.2
            # volum retras deasupra (etajul in trepte din dioramă): jumatate
            # din latime, spre interiorul benzii, ca fatada sa urce in trepte
            if rnd() < 0.40 and h + 2.6 <= CITY_H:
                sw, sd = w * 0.5, depth * 0.45
                bwall.box((x + w * 0.3, side * sd * 0.5, h + 1.3),
                          (sw, sd, 2.6), slot)
            if rnd() < 0.40 and h + 1.3 <= CITY_H:
                bb.cylinder((x + w * 0.72, yin, h + 0.65), 0.75, 1.3, TANK,
                            segments=5)
            x += w
    return (bw.to_object("FarCity_A"), bb.to_object("FarCity_A_Beige"),
            _to_object_raw(bg, "FarCity_A_Glow"))


# --- DesertRidge_A / DesertRidge_B --------------------------------------------

RIDGE_LEN, RIDGE_DEPTH, RIDGE_H = 200.0, 60.0, 30.0


def build_desert_ridge(seed, name, summits):
    """Deal jos de riolit, 200 (X) x 60 (Y) x 30 (Z) m.

    Referinta: dealurile din spatele orasului in dioramă (decupate in
    docs/track_briefs/img/jodhpur_horizon_ref/desert_ridge.png) -- creste
    lungi si JOASE, cu umeri rotunzi si cate un varf mai marcat, pierdute in
    ceata calda. Nu munte: raportul inaltime/lungime ~0,15. Elemente:

      1. creasta lunga pe X, din 24 de coloane cusute, cu inaltimea urcand
         spre `summits` (1 varf la A, 2 varfuri cu sa la B) si un zgomot
         mic aditiv (nu sinusoida -- dinte de fierastrau regulat, lectia
         Fiordland);
      2. sectiunea cu 7 puncte: poale, umar jos, umar sus, creasta -- pante
         asimetrice intre +Y si -Y (o fata mai abrupta);
      3. 2-3 pinteni pe fiecare parte (latime locala marita), ca planta sa
         nu fie un trunchi de toblerone;
      4. capetele coboara la ~20% din inaltime, volumul e inchis (talpa +
         doua capace);
      5. culoare in trei etaje, prin retag (zero triunghiuri): poalele
         `SAND_MID` sub 7 m (3 m vizibili dupa ingropare), fetele domoale
         (n.z > 0,78) `SAND_SHADOW` (praf pe pante), restul riolit
         `ROCK_DARK`."""
    b = Builder()
    rnd = _lcg(seed)
    COLS = 24
    half = RIDGE_LEN * 0.5
    xs = [-half + RIDGE_LEN * i / (COLS - 1.0) for i in range(COLS)]

    # inaltimea: suma de clopote pe varfuri + zgomot aditiv netezit
    crest = []
    for x in xs:
        hsum = 0.0
        for (sx, sh, sw) in summits:
            hsum = max(hsum, sh * math.exp(-((x - sx) / sw) ** 2))
        crest.append(hsum)
    noise = [(rnd() - 0.5) * 4.0 for _ in xs]
    for _ in range(2):
        noise = [noise[0]] + [(noise[i - 1] + 2 * noise[i] + noise[i + 1]) * 0.25
                              for i in range(1, COLS - 1)] + [noise[-1]]
    crest = [max(6.0, c + n) for c, n in zip(crest, noise)]
    crest[0] = crest[-1] = RIDGE_H * 0.2
    top = max(crest)
    crest = [c * RIDGE_H / top for c in crest]

    # latimea de baza, independenta de inaltime, plus pinteni
    base = []
    walk = 50.0
    for _ in xs:
        walk = max(40.0, min(54.0, walk + (rnd() - 0.5) * 8.0))
        base.append(walk)

    def spurs():
        bonus = [0.0] * COLS
        for _ in range(2 + (1 if rnd() > 0.5 else 0)):
            ci = int(3 + rnd() * (COLS - 6))
            amp = 4.0 + rnd() * 4.0
            for di in (-2, -1, 0, 1, 2):
                k = ci + di
                if 0 <= k < COLS:
                    bonus[k] = max(bonus[k], amp * (1.0 - abs(di) / 3.0))
        return bonus

    sp_p, sp_m = spurs(), spurs()
    steep_p = 0.55 + rnd() * 0.1   # +Y mai abrupta: umerii mai departe de ax
    steep_m = 0.40 + rnd() * 0.1

    cols = []
    for i, x in enumerate(xs):
        h = crest[i]
        taper = 0.55 + 0.45 * math.sin(math.pi * i / (COLS - 1.0))
        yp = (base[i] * 0.5 + sp_p[i]) * taper
        ym = (base[i] * 0.5 + sp_m[i]) * taper
        cols.append([
            Vector((x, -ym, 0.0)),
            Vector((x, -ym * (0.55 + steep_m * 0.2), h * 0.32)),
            Vector((x, -ym * (0.18 + steep_m * 0.15), h * 0.82)),
            Vector((x, (rnd() - 0.5) * 3.0, h)),
            Vector((x, yp * (0.18 + steep_p * 0.15), h * 0.82)),
            Vector((x, yp * (0.55 + steep_p * 0.2), h * 0.32)),
            Vector((x, yp, 0.0)),
        ])
    # latimea totala adusa exact la contract (pintenii o scot din calcul)
    y_lo = min(p.y for col in cols for p in col)
    y_hi = max(p.y for col in cols for p in col)
    ky = RIDGE_DEPTH / (y_hi - y_lo)
    for col in cols:
        for p in col:
            p.y *= ky
    vs = [[b.bm.verts.new(p) for p in col] for col in cols]
    nr = len(cols[0])
    faces = []
    for i in range(COLS - 1):
        for r in range(nr - 1):
            f = b.bm.faces.new((vs[i][r], vs[i + 1][r], vs[i + 1][r + 1], vs[i][r + 1]))
            f[b.slot] = RHYOLITE
            faces.append(f)
        f = b.bm.faces.new((vs[i][0], vs[i][-1], vs[i + 1][-1], vs[i + 1][0]))
        f[b.slot] = APRON
        faces.append(f)
    for cap in (tuple(reversed(vs[0])), tuple(vs[-1])):
        f = b.bm.faces.new(cap)
        f[b.slot] = RHYOLITE
        faces.append(f)

    b.retag(faces, SCREE, where=lambda c, n: n.z > 0.78)
    b.retag(faces, APRON, where=lambda c, n: c.z < BURY + 3.0)
    return b.to_object(name)


# --- emit ------------------------------------------------------------------------

clear_built()
results = []


def emit(obj, ao, origin="base", smooth_angle=35.0):
    st = finish(obj, bevel=0.0, ao=ao, origin=origin, smooth_angle=smooth_angle)
    results.append((obj.name, st["tris"]))
    return obj


palace = emit(build_umaid_bhawan(), AO_PALACE, smooth_angle=40.0)

# FarCity_A + copiii: origine COMUNA (memoria finish-recentreaza-fiecare-nod-
# separat). Banda e construita deja centrata pe XY si cu talpa la z = 0;
# offsetul se masoara totusi pe ansamblu si se aplica identic tuturor.
city_parts = build_far_city()
xs, ys, zs = [], [], []
for o in city_parts:
    for v in o.data.vertices:
        xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5, -min(zs)))
for o in city_parts:
    for v in o.data.vertices:
        v.co += place
    emit(o, AO_CITY, origin=None, smooth_angle=30.0)
city, city_beige, city_glow = city_parts
for child in (city_beige, city_glow):
    child.parent = city
    child.matrix_parent_inverse = child.matrix_parent_inverse.Identity(4)

ridge_a = emit(build_desert_ridge(1711, "DesertRidge_A",
                                  [(-22.0, 30.0, 40.0), (40.0, 19.0, 45.0)]),
               AO_RIDGE, smooth_angle=45.0)
ridge_b = emit(build_desert_ridge(1733, "DesertRidge_B",
                                  [(-48.0, 27.0, 30.0), (38.0, 30.0, 32.0),
                                   (-5.0, 17.0, 30.0)]),
               AO_RIDGE, smooth_angle=45.0)

built = [palace, city, city_beige, city_glow, ridge_a, ridge_b]
_, sz = export_glb(built, "jodhpur/rocks/jodhpur_horizon.glb")
print("export: jodhpur/rocks/jodhpur_horizon.glb (%.0f KB)" % (sz / 1024.0))

total = sum(t for _, t in results)
print()
for name, tris in results:
    o = bpy.data.objects[name]
    xs_ = [v.co.x for v in o.data.vertices]
    ys_ = [v.co.y for v in o.data.vertices]
    zs_ = [v.co.z for v in o.data.vertices]
    print("%-16s tris=%5d  %.1f x %.1f x %.1f m" % (
        name, tris, max(xs_) - min(xs_), max(ys_) - min(ys_), max(zs_) - min(zs_)))
print("TOTAL horizon: %d tris  %s" % (total, "OK" if total <= 5000 else "DEPASIT (5000)"))

# separate in .blend, ca sa nu se suprapuna la editare (dupa export)
city.location.x = 120.0
ridge_a.location.x = 300.0
ridge_b.location.x = 520.0
save_blend(built, "jodhpur_horizon.blend")
