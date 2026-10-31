"""Carrara -- piesele LIPSA din decor (cererea dezvoltatorului, carrara_stare_poi.md punctul 6).

  carrara/buildings/stone_tower.glb       turnul patrat de cariera, zidarie de piatra, 3,6 x 3,6 m, 8,1 m
  carrara/buildings/tin_shed.glb          magazia cu acoperis de tabla, 6 x 4,4 m + sopron lipit, coama 3,7 m
  carrara/plants/chestnut_tree_a.glb      castan (Castanea sativa), coroana lata rotunda, 10,5 m
  carrara/plants/chestnut_tree_b.glb      castan batran, aplecat, cu o craca rupta, 9 m
  carrara/plants/ginestra_fiorita.glb     ginestra INFLORITA (Spartium junceum), 1,7 m, galbena sus

Referinta: docs/track_briefs/img/bar_carrara/bara_poi_A.png (turnul in stanga, magazia in
mijloc) si bara_poi_G.png (castanii si ginestra galbena pe versant).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_crr_kit_a_lipsa.py
Variabila de mediu CRR_KIT_ONLY=<piesa> reface doar piesa respectiva.

Axe: X latime, Y adancime (fata spre +Y in Blender = -Z in Godot), Z sus. Piesele se
construiesc DIRECT fata de originea lor (centrul amprentei la cladiri, BAZA TRUNCHIULUI
la copaci), baza la z = 0; exportul nu muta nimic (memoria `finish-recentreaza-fiecare-
nod-separat`), deci un castan aplecat ramane cu originea pe trunchi, nu pe mijlocul
coroanei (coliziunea `trunk` sta pe axa modelului).

Un nod = un rol / o clasa (kit §0 regula 6). Numele de noduri sunt PREFIXATE cu piesa
(`StoneTower_`, `TinShed_`, `GinestraBloom_`), nu generice: maparile din `prop_classes()`
sunt GLOBALE si pe prefix (memoria `nume-noduri-nu-sunt-unice`) -- un `Tower_Stone` ar fi
dat peste maparea Jodhpur, iar un `Ginestra_*` peste `macchia` de la Stromboli.

  StoneTower_Stone   MARBLE_GREY 29   zidaria -> clasa `carrara_marble` (turnul e cladit din
                                      marmura carierei; `tf_stone` iesea ALBASTRU pe tema asta,
                                      captura de joc, tenta clasei (0,67, 0,77, 0,96))
  StoneTower_Marble  CORAL_SAND 19    pietrele de colt, braul, cornisa, ancadramentele: raman pe
                                      ATLAS, crem curat peste zidaria cu vine
  StoneTower_Wood    WOOD 9 / LOG_DARK 28   usa, curelele, grinda cu scripete
  StoneTower_Void    VOLCANIC_BLACK 20      fundul golurilor
  TinShed_Wall       MARBLE_GREY 29 (tabla cutata) + CONCRETE 8 (soclul)    atlas
  TinShed_Roof       PAINTED 11 (tabla) + RUST 10 (doua foi ruginite)       atlas
  TinShed_Wood       WOOD 9 / LOG_DARK 28   usile, sina usii glisante
  TinShed_Void       VOLCANIC_BLACK 20      ferestrele
  Chestnut_Bark      LOG_DARK 28      trunchi gros, brazdat in spirala
  Chestnut_Leaves    CACTUS_GREEN 12  coroana -> clasa `macchia`; oliv-ul vine din tenta
                                      coapta in vertex color (`_leaf_tint`), masurata in joc
                                      (vezi CLASSES_CARRARA in world_prop.gd)
  GinestraBloom_Stems    TROPICAL_GREEN 21  tijele (clasa `macchia`, ca ginestra Stromboli)
  GinestraBloom_Flowers  DRY_VEGETATION 13  florile, pe ATLAS: slotul 13 iese galben-auriu
                                            sub soarele temei (ca vopseaua excavatorului)
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))

# Uneltele satului Colonnata (Openings, quoins, solve_pitch, steps, join, emit_keep) stau in
# build_crr_buildings.py, care n-are garda `__main__`: se incarca cu CRR_ONLY pe o piesa
# inexistenta, deci nu construieste si nu exporta nimic (doar clear_built + un raport gol).
_prev_only = os.environ.get("CRR_ONLY")
os.environ["CRR_ONLY"] = "__doar_unelte__"
exec(open(os.path.join(_here, "build_crr_buildings.py"), encoding="utf-8").read())
if _prev_only is None:
    del os.environ["CRR_ONLY"]
else:
    os.environ["CRR_ONLY"] = _prev_only
exec(open(os.path.join(_here, "tf_shapes_nature.py"), encoding="utf-8").read())

KIT_ONLY = os.environ.get("CRR_KIT_ONLY", "")


def _want(name):
    return not KIT_ONLY or KIT_ONLY == name


def emit_post(objs, path, ao, post=None):
    """Ca `emit_keep` (finish fara mutare + export in carrara/), dar cu un pas `post(obj)`
    DUPA finish: tenta de frunzis (`tint_gradient`) se inmulteste peste AO-ul copt, iar
    bake_ao sterge orice culoare pusa inainte -- ordinea e o constrangere."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    if abs(min(zs)) > 1e-4:
        raise RuntimeError("%s: baza la z %.4f, nu la 0" % (path, min(zs)))
    total, per_node = 0, {}
    for o in objs:
        st = finish(o, bevel=0.0, bevel_angle=30.0, ao=ao, origin=None, smooth_angle=None)
        if post is not None:
            post(o)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    print("%s: bbox X %.2f..%.2f  Y %.2f..%.2f  Z %.2f..%.2f" % (
        path, min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
    _, sz = export_glb(objs, "carrara/" + path)
    CRR_RESULTS.append((path, total, dims, per_node, sz / 1024.0))
    return total


def retag_builder(b, slot):
    for f in b.bm.faces:
        f[b.slot] = slot


# ---------------------------------------------------------------------------
# stone_tower
# ---------------------------------------------------------------------------

TW = 1.8          # semi-latura corpului (3,6 m)
TW_H = 7.2        # cota cornisei
TW_FLOOR = 3.1    # braul de la etaj


def _ashlar_blocks(b, rnd, openings, face, at, half, z0, z1):
    """Blocuri de piatra iesite 2,5-5 cm din perete, pe asize (randuri de 0,36-0,44 m),
    ca zidaria sa se citeasca TAIATA GROSOLAN si de aproape (decuparea: blocuri inegale).
    Ocolesc golurile (`openings` = [(c, w, z0, z1)] pe fata asta, cu 0,22 m margine),
    colturile (pietrele de colt ocupa 0,7 m) si braul."""
    z = z0
    row = 0
    while z < z1 - 0.3:
        h = 0.36 + 0.08 * rnd()
        a = -half + 0.72 + (0.35 if row % 2 else 0.0) * rnd()
        while a < half - 0.95:
            w = 0.55 + 0.45 * rnd()
            c = a + w * 0.5
            zc = z + h * 0.5
            free = rnd() < 0.65 and not (abs(zc - TW_FLOOR) < 0.45)
            for (oc, ow, oz0, oz1) in openings:
                if abs(c - oc) < (w + ow) * 0.5 + 0.22 and zc + h * 0.5 > oz0 - 0.32 \
                        and zc - h * 0.5 < oz1 + 0.36:
                    free = False
            if free:
                prot = 0.025 + 0.025 * rnd()
                box_face(b, face, at, c, prot * 0.5 - 0.02, zc, w - 0.05, prot + 0.04,
                         h - 0.05, V_STONE)
            a += w + 0.04
        z += h + 0.03
        row += 1


def build_stone_tower():
    """Turnul de cariera (`stone_tower`): turn PATRAT vechi, zidarie de piatra.

    LISTA DE ELEMENTE (decuparea din bara_poi_A.png, stanga; scrisa INAINTE de geometrie):
     1. CORP 3,6 x 3,6 m, pereti drepti pana la cornisa de la 7,2 m (doua niveluri si
        ceva: in bara turnul e de ~2,2 ori mai inalt decat lat).
     2. FATA +Y (spre drum): USA joasa 1,0 x 2,1 m cu buiandrug de marmura si o treapta;
        deasupra DOUA FERESTRE MICI una sub alta (0,55 x 0,85 m), ca in bara.
     3. CELELALTE FETE: ferestre mici si fante (turnul nu e orb din alt azimut).
     4. PIETRE DE COLT alternante, de marmura crem, iesite 4 cm; un BRAU de marmura la
        etaj (3,1 m) -- cele doua niveluri se citesc de la 40 m.
     5. ZIDARIE TAIATA GROSOLAN: blocuri iesite 2,5-5 cm pe asize, nu un perete neted
        (clasa `tf_stone` da rosturile, blocurile dau relief si umbra).
     6. VARF PLAT: cornisa de marmura iesita 0,18 m, PARAPET de piatra de 0,6 m cu
        coronament de marmura si un GURGUI de scurgere; camera de joc (10 m sus) vede
        acoperisul, deci podeaua dintre parapeti e o placa, nu un gol.
     7. O GRINDA DE LEMN cu scripete iesita sub cornisa pe +X (turnul de cariera ridica
        unelte) -- da silueta, altfel e o cutie.
    Noduri: StoneTower_Stone, StoneTower_Marble, StoneTower_Wood, StoneTower_Void."""
    rnd = _rnd(2310)
    void, wood, marble, stone_x = Builder(), Builder(), Builder(), Builder()
    op = Openings(void, wood, marble)
    body = Builder()
    body.box((0.0, 0.0, TW_H * 0.5), (2 * TW, 2 * TW, TW_H), V_STONE)

    # 2-3. golurile: (fata, at, [(c, w, z0, z1, kind)])
    plan = {
        "+Y": [(0.0, 1.0, 0.15, 2.25, "door"), (0.0, 0.55, 3.55, 4.40, "window"),
               (0.0, 0.55, 5.45, 6.30, "window")],
        "+X": [(0.35, 0.50, 3.70, 4.45, "window"), (0.35, 0.28, 1.40, 2.20, "window"),
               (-0.40, 0.50, 5.55, 6.30, "window")],
        "-X": [(0.0, 0.50, 5.45, 6.20, "window"), (0.0, 0.26, 2.30, 3.05, "window")],
        "-Y": [(0.30, 0.55, 4.50, 5.35, "window"), (-0.45, 0.26, 1.60, 2.35, "window")],
    }
    at = {"+Y": TW, "-Y": -TW, "+X": TW, "-X": -TW}
    for face, items in plan.items():
        for (c, w, z0, z1, kind) in items:
            op.add("body", face, at[face], c, w, z0, z1, kind=kind, cross=False)
    steps(marble, 0.0, TW, 1.5, 0.55, 1, 0.15)

    # 5. zidaria grosolana, pe fiecare fata, intre soclu si cornisa
    for face, items in plan.items():
        ops = [(c, w, z0, z1) for (c, w, z0, z1, _k) in items]
        _ashlar_blocks(stone_x, rnd, ops, face, at[face], TW, 0.25, TW_H - 0.35)

    # 4. pietrele de colt + braul
    quoins(marble, -TW, TW, -TW, TW, 0.0, TW_H - 0.25, h=0.42, long_=0.66, short=0.38,
           slot=CRR_MARBLE)
    marble.box((0.0, 0.0, TW_FLOOR), (2 * TW + 0.10, 2 * TW + 0.10, 0.16), CRR_MARBLE)

    # 6. cornisa, parapetul, coronamentul, gurguiul
    CO = 0.18
    marble.box((0.0, 0.0, TW_H + 0.11), (2 * (TW + CO), 2 * (TW + CO), 0.22), CRR_MARBLE)
    marble.box((0.0, 0.0, TW_H - 0.12), (2 * TW + 0.16, 2 * TW + 0.16, 0.16), CRR_MARBLE)
    PT, PH = 0.38, 0.62
    zp0 = TW_H + 0.22
    for s in (-1, 1):
        stone_x.box((0.0, s * (TW - PT * 0.5), zp0 + PH * 0.5), (2 * TW, PT, PH), V_STONE)
        stone_x.box((s * (TW - PT * 0.5), 0.0, zp0 + PH * 0.5), (PT, 2 * TW - 2 * PT, PH), V_STONE)
    for s in (-1, 1):
        marble.box((0.0, s * (TW - PT * 0.5), zp0 + PH + 0.05), (2 * TW + 0.08, PT + 0.08, 0.10),
                   CRR_MARBLE)
        marble.box((s * (TW - PT * 0.5), 0.0, zp0 + PH + 0.05), (PT + 0.08, 2 * TW - 2 * PT, 0.10),
                   CRR_MARBLE)
    # gurguiul pe -Y, la nivelul podelei
    marble.box((0.9, -TW - 0.30, zp0 + 0.10), (0.18, 0.62, 0.14), CRR_MARBLE)

    # 7. grinda cu scripete pe +X, sub cornisa
    zb = TW_H - 0.55
    wood.box((TW + 0.55, 0.0, zb), (1.30, 0.20, 0.22), V_DARK)
    wood.box((TW + 0.12, 0.0, zb - 0.45), (0.14, 0.14, 0.7), V_DARK)          # contrafisa
    wood.cylinder((TW + 1.05, 0.0, zb - 0.22), 0.16, 0.08, V_DARK, segments=8, axis="Y")
    wood.beam((TW + 1.05, 0.0, zb - 0.30), (TW + 1.05, 0.0, zb - 1.6), 0.03, V_DARK)
    wood.box((TW + 1.05, 0.0, zb - 1.66), (0.10, 0.06, 0.14), V_DARK)          # carligul

    retag_builder(marble, CRR_MARBLE)
    stone = join([op.apply("body", Builder.to_object(body, "TowerBody")),
                  Builder.to_object(stone_x, "TowerAshlar")], "StoneTower_Stone")
    print("stone_tower: goluri %d" % len(op.log))
    return [stone, Builder.to_object(marble, "StoneTower_Marble"),
            Builder.to_object(wood, "StoneTower_Wood"), to_obj(void, "StoneTower_Void")]


# ---------------------------------------------------------------------------
# tin_shed
# ---------------------------------------------------------------------------

SH_X0, SH_X1, SH_Y0, SH_Y1 = -3.6, 2.4, -2.2, 2.2    # corpul mare, 6,0 x 4,4
SH_ZW, SH_H = 2.7, 3.7
AN_X1, AN_Y0, AN_Y1 = 5.0, -1.8, 1.9                 # sopronul lipit pe +X, 2,6 x 3,7
AN_ZHI, AN_ZLO = 2.55, 2.05
SH_PLINTH = 0.35
RIB_STEP = 0.42                                      # pasul nervurilor (style_bible §3: >= 0,4 m)


def _wall_ribs(b, face, at, a0, a1, z0, ztop, step=RIB_STEP, skip=()):
    """Nervurile verticale ale tablei cutate pe o fata: sipci de 9 cm iesite 4 cm, de la
    soclu pana la `ztop(a)` (sub streasina sau sub panta frontonului). `skip` =
    [(a_lo, a_hi, z_lo, z_hi)] golurile, peste care nervura se taie."""
    a = a0 + step * 0.5
    while a < a1 - 0.05:
        zt = ztop(a) - 0.04
        segs = [(z0, zt)]
        for (lo, hi, zl, zh) in skip:
            if lo - 0.06 < a < hi + 0.06:
                nxt = []
                for (s0, s1) in segs:
                    if s0 < zl:
                        nxt.append((s0, min(s1, zl - 0.02)))
                    if s1 > zh:
                        nxt.append((max(s0, zh + 0.02), s1))
                segs = nxt
        for (s0, s1) in segs:
            if s1 - s0 > 0.12:
                box_face(b, face, at, a, 0.01, (s0 + s1) * 0.5, 0.09, 0.06, s1 - s0, V_STONE)
        a += step


def build_tin_shed():
    """Magazia de cariera (`tin_shed`): sopron jos, pereti de tabla, acoperis de tabla.

    LISTA DE ELEMENTE (decuparea din bara_poi_A.png, mijloc; scrisa INAINTE de geometrie):
     1. CORPUL MARE 6,0 (X) x 4,4 (Y) m, pereti 2,7 m, acoperis in DOUA APE de tabla cu
        coama pe X la 3,7 m; streasina 0,35 m, iesirea peste fronton 0,25 m.
     2. SOPRONUL lipit pe +X: 2,6 x 3,7 m, o singura apa coborand spre +X (2,55 -> 2,05 m),
        mai jos decat streasina corpului mare -- silueta in trepte din bara.
     3. PERETII: tabla cutata GRI, nervuri verticale la 0,42 m (sub 0,4 devine moar,
        style_bible §3), pe un SOCLU de beton de 0,35 m iesit 6 cm.
     4. FATA +Y: USA GLISANTA LATA de lemn 2,4 x 2,3 m cu sina deasupra; o fereastra mica
        langa; sopronul are o usa simpla. Frontonul -X: o fereastra.
     5. ACOPERISUL: tabla gri-albastruie (PAINTED 11) cu nervuri la 0,40 m; DOUA FOI
        RUGINITE pe apa dinspre +Y (RUST 10) -- cariera e prafuita si veche.
     6. NU intra: bidoanele, lazile, roata din bara (sunt piese separate ale decorului).
    Noduri: TinShed_Wall, TinShed_Roof, TinShed_Wood, TinShed_Void."""
    void, wood, roof, wall_x, junk = Builder(), Builder(), Builder(), Builder(), Builder()
    op = Openings(void, wood, junk)
    half = (SH_Y1 - SH_Y0) * 0.5
    ROOF = dict(thick=0.08, rib_h=0.045, rib_w=0.10, step=0.40, cap=(0.30, 0.08))
    t, z_eave = solve_pitch(SH_H, SH_ZW, half, thick=ROOF["thick"], ov=0.35, cap=ROOF["cap"])
    R = tin_roof(roof, (SH_X0 + SH_X1) * 0.5, 0.0, (SH_X1 - SH_X0) * 0.5 + 0.25, half + 0.35,
                 z_eave, math.degrees(math.atan(t)), PAINTED, kind="gable", axis="X", **ROOF)
    body = Builder()
    body.box(((SH_X0 + SH_X1) * 0.5, 0.0, SH_ZW * 0.5), (SH_X1 - SH_X0, SH_Y1 - SH_Y0, SH_ZW),
             V_STONE)
    zr = R["under"]((SH_X0 + SH_X1) * 0.5, 0.0) - 0.02
    prism_x(body, [(SH_Y0, SH_ZW - 0.1), (SH_Y1, SH_ZW - 0.1), (SH_Y1, SH_ZW), (0.0, zr),
                   (SH_Y0, SH_ZW)], SH_X0, SH_X1, V_STONE)

    # 2. sopronul: corp + acoperis intr-o apa (muchia de sus la -v = spre corpul mare)
    an_hy = (AN_X1 - SH_X1) * 0.5
    an_t = (AN_ZHI - AN_ZLO) / (AN_X1 - SH_X1)
    annex = Builder()
    an_cx = (SH_X1 + AN_X1) * 0.5
    annex.box((an_cx, (AN_Y0 + AN_Y1) * 0.5, AN_ZLO * 0.5), (AN_X1 - SH_X1 + 0.1, AN_Y1 - AN_Y0, AN_ZLO),
              V_STONE)
    prism_face(annex, "+Y", 0.0, [(SH_X1 - 0.1, AN_ZLO - 0.1), (AN_X1, AN_ZLO - 0.1), (AN_X1, AN_ZLO),
                                  (SH_X1 - 0.1, AN_ZHI)], AN_Y0, AN_Y1, V_STONE)
    # Apa sopronului, facuta de mana: `tin_roof(kind="shed")` pune streasina pe +v, iar cu
    # axis="Y" +v cade spre -X (spre corpul mare) -- invers. Aici streasina e la x = AN_X1.
    sec = math.sqrt(1.0 + an_t * an_t)
    xa, xb = SH_X1 - 0.02, AN_X1 + 0.18           # muchia de sus (sub streasina mare), streasina
    za = AN_ZHI + 0.02 + 0.08 * sec
    zb_ = za - (xb - xa) * an_t
    ya, yb = AN_Y0 - 0.22, AN_Y1 + 0.22
    n_sh = Vector((an_t, 0.0, 1.0)).normalized()
    _slab(roof, [Vector((xb, ya, zb_)), Vector((xb, yb, zb_)), Vector((xa, yb, za)),
                 Vector((xa, ya, za))], n_sh, 0.08, PAINTED)
    y = ya + 0.20
    while y < yb - 0.1:
        off = n_sh * 0.0225
        roof.beam(Vector((xb, y, zb_)) + off, Vector((xa, y, za)) + off, (0.10, 0.045), PAINTED,
                  up=n_sh)
        y += 0.40

    # 4. golurile
    op.add("body", "+Y", SH_Y1, -1.2, 2.4, 0.05, 2.30, kind="door", surround=False, depth=0.16)
    op.add("body", "+Y", SH_Y1, 1.35, 0.85, 1.25, 1.95, surround=False, cross=False, depth=0.14)
    op.add("body", "-X", SH_X0, 0.0, 0.85, 1.25, 1.95, surround=False, cross=False, depth=0.14)
    op.add("body", "-Y", SH_Y0, 0.8, 0.85, 1.25, 1.95, surround=False, cross=False, depth=0.14)
    op.add("annex", "+Y", AN_Y1, 3.85, 0.95, 0.05, 1.95, kind="door", surround=False, depth=0.14)
    # sina usii glisante + rama de tabla a usii (LOG_DARK)
    wood.box((-1.2 - 0.6, SH_Y1 + 0.07, 2.42), (3.8, 0.10, 0.12), V_DARK)
    for x in (-1.2 - 1.24, -1.2 + 1.24):
        wood.box((x, SH_Y1 + 0.03, 1.17), (0.08, 0.08, 2.30), V_DARK)

    # 3. nervurile tablei pe toate fetele (ocolesc golurile) + soclul
    zt_body = lambda a: SH_ZW
    gable = lambda a: min(SH_ZW + (half - abs(a)) * t, zr) if abs(a) < half else SH_ZW
    _wall_ribs(wall_x, "+Y", SH_Y1, SH_X0, SH_X1, SH_PLINTH, zt_body,
               skip=[(-2.4, 0.0, 0.0, 2.32), (0.92, 1.78, 1.25, 1.95)])
    _wall_ribs(wall_x, "-Y", SH_Y0, SH_X0, SH_X1, SH_PLINTH, zt_body,
               skip=[(0.37, 1.23, 1.25, 1.95)])
    _wall_ribs(wall_x, "-X", SH_X0, SH_Y0, SH_Y1, SH_PLINTH, gable,
               skip=[(-0.43, 0.43, 1.25, 1.95)])
    an_top = lambda a: AN_ZHI - (a - SH_X1) * an_t
    _wall_ribs(wall_x, "+Y", AN_Y1, SH_X1 + 0.05, AN_X1, SH_PLINTH, an_top,
               skip=[(3.37, 4.33, 0.0, 1.97)])
    _wall_ribs(wall_x, "-Y", AN_Y0, SH_X1 + 0.05, AN_X1, SH_PLINTH, an_top)
    _wall_ribs(wall_x, "+X", AN_X1, AN_Y0, AN_Y1, SH_PLINTH, lambda a: AN_ZLO)
    # frontonul +X al corpului mare, deasupra sopronului
    _wall_ribs(wall_x, "+X", SH_X1, SH_Y0, SH_Y1, AN_ZHI + 0.05, gable)
    for (cx, cy, sx, sy) in (((SH_X0 + SH_X1) * 0.5, 0.0, SH_X1 - SH_X0, SH_Y1 - SH_Y0),
                             (an_cx, (AN_Y0 + AN_Y1) * 0.5, AN_X1 - SH_X1, AN_Y1 - AN_Y0)):
        wall_x.box((cx, cy, SH_PLINTH * 0.5), (sx + 0.12, sy + 0.12, SH_PLINTH), CONCRETE)
    # pragul de beton al usii mari (iesit in fata, peste soclu)
    wall_x.box((-1.2, SH_Y1 + 0.35, 0.04), (2.8, 0.7, 0.08), CONCRETE)

    # 5. doua foi ruginite pe apa dinspre +Y a corpului mare
    roof.retag(list(roof.bm.faces), RUST,
               where=lambda c, n: c.y > 0.3 and ((-2.75 < c.x < -1.95) or (0.85 < c.x < 1.65))
               and c.z > 2.4)

    wall_body = op.apply("body", Builder.to_object(body, "ShedBody"), slot=V_STONE)
    annex_body = op.apply("annex", Builder.to_object(annex, "AnnexBody"), slot=V_STONE)
    walls = join([wall_body, annex_body, Builder.to_object(wall_x, "ShedRibs")], "TinShed_Wall")
    print("tin_shed: panta %.1f grade, coama %.2f, streasina %.2f; sopron %.1f grade" % (
        math.degrees(math.atan(t)), R["ridge_z"], z_eave, math.degrees(math.atan(an_t))))
    return [walls, Builder.to_object(roof, "TinShed_Roof"), Builder.to_object(wood, "TinShed_Wood"),
            to_obj(void, "TinShed_Void")]


# ---------------------------------------------------------------------------
# chestnut_tree_a / _b
# ---------------------------------------------------------------------------

CN_BARK = LOG_DARK        # 28: scoarta gri-bruna, inchisa
CN_LEAF = CACTUS_GREEN    # 12: verde-oliv (TROPICAL_GREEN 21 e verde de brocoli)


def _spiral_ridges(bark, base_r, top_z, n=6, turns=0.35, seed=0):
    """Coaste de scoarta rasucite: castanul batran are brazde adanci care urca in SPIRALA
    (semnul lui, fata de fagul neted). Tuburi subtiri lipite de trunchi, de la sol la
    ramificare; de aproape dau umbra in dungi oblice, de departe ingroasa trunchiul."""
    r = _rnd(seed)
    for i in range(n):
        a0 = 2.0 * math.pi * (i + 0.3 * r()) / n
        pts, rad = [], []
        for k in range(5):
            f = k / 4.0
            a = a0 + turns * 2.0 * math.pi * f
            rr = base_r * (1.0 - 0.28 * f) * (1.04 if k == 0 else 0.97)
            pts.append(Vector((math.cos(a) * rr, math.sin(a) * rr, 0.05 + f * (top_z - 0.15))))
            rad.append(0.11 - 0.05 * f)
        bark.taper_sweep(pts, rad, CN_BARK, segments=4)


def _cn_flare(bark, r0, seed, n=5):
    r = _rnd(seed)
    for i in range(n):
        a = 2.0 * math.pi * (i + 0.25 * r()) / n
        d = Vector((math.cos(a), math.sin(a), 0.0))
        bark.taper_sweep([d * (r0 * 0.3) + Vector((0, 0, 0.9)), d * (r0 * 0.95) + Vector((0, 0, 0.25)),
                          d * (r0 * 1.6) + Vector((0, 0, 0.0))],
                         [r0 * 0.55, r0 * 0.40, r0 * 0.10], CN_BARK, segments=5)


def _clamp_floor(b):
    """Inelele de capat ale pintenilor sunt perpendiculare pe directia lor, deci intra
    cativa cm sub sol: se taie la z = 0 (talpa plana, baza modelului exact pe origine)."""
    for v in b.bm.verts:
        if v.co.z < 0.0:
            v.co.z = 0.0


def _leaf_tint(obj):
    """Coroana pe clasa `macchia` (verde H ~115 in joc): verdele se TAIE spre oliv inchis.
    Multiplicativ peste AO, liniar (FLOAT_COLOR): G si B scad, rosul ramane, deci nuanta
    coboara spre ~80 si saturatia scade. Masurat in joc (--vitrina pe Carrara, coroana):
    (0,55/0,25/0,25 -> 1/0,50/0,42) a dat H 78 S 0,61 V50 0,15 (prea inchis); valorile de
    acum dau H 84 S 0,57 V50 0,16, langa bara_poi_G.png (H ~70, S ~0,40, V ~0,18)."""
    tint_gradient(obj, base=(0.70, 0.34, 0.34), tip=(1.0, 0.56, 0.52), power=0.9)


def build_chestnut_tree_a():
    """Castanul A (`chestnut_tree_a`): Castanea sativa, ~10,5 m inalt, coroana ~11 m.

    LISTA DE ELEMENTE (bara_poi_G.png, padurea de pe flancul Colonnatei; scrisa INAINTE
    de geometrie):
     a) TRUNCHI SCURT si FOARTE GROS (O 1,0 m la baza), pinteni de radacina, COASTE DE
        SCOARTA RASUCITE in spirala (semnul castanului batran), ramificare JOASA la 2,6 m.
     b) 4 BRATE GROASE in evantai, aproape orizontale spre capete, care intra in coroana
        la ~3,6-4 m de axa -- se vad sub coroana, intre sol si frunzis.
     c) COROANA LATA si ROTUNDA, mai lata decat inalta (h coroana / l ~0,75): un DOM
        din 9 MASE grupate -- 5 jos pe capetele bratelor (inel larg), 3 la mijloc, 1 sus
        turtita; ciorchini MARI si NODUROSI (castanul se citeste "bulbucat", nu neted).
     d) GOLURI in partea de jos a coroanei, intre masele inelului, prin care se vad
        bratele (in bara: lumina printre coroane).
     e) CULOAREA: verde-OLIV inchis (CACTUS_GREEN 12), varfurile maselor spre galben-oliv
        (tenta in vertex color), baza umbrita -- nu verdele saturat al fagului.
    Noduri: Chestnut_Bark (LOG_DARK 28), Chestnut_Leaves (CACTUS_GREEN 12)."""
    bark, lv = Builder(), Builder()
    bark.taper_sweep([(0, 0, 0.0), (0.03, 0.02, 1.3), (0.06, 0.03, 2.8)], [0.50, 0.44, 0.40],
                     CN_BARK, segments=9)
    _cn_flare(bark, 0.58, 7, n=5)
    _spiral_ridges(bark, 0.50, 2.7, n=6, turns=0.30, seed=11)
    fork = Vector((0.06, 0.03, 2.6))
    ring = []
    for k, az in enumerate((10.0, 82.0, 158.0, 230.0, 300.0)):
        a = math.radians(az)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        reach = 3.6 + 0.5 * ((k * 37) % 3) / 2.0
        end = d * reach + Vector((0.0, 0.0, 4.5 + 0.25 * (k % 2)))
        mid = fork.lerp(end, 0.45) + Vector((0.0, 0.0, 0.35))
        if k < 4:
            branch(bark, [fork, mid, end], 0.27, 0.12, CN_BARK, seg=7)
        ring.append(((end.x * 1.05, end.y * 1.05, end.z + 0.4), (2.6, 2.6, 1.8)))
    mid_m = [((1.6, 1.3, 7.0), (2.6, 2.6, 2.0)), ((-1.9, 0.9, 7.1), (2.5, 2.5, 1.9)),
             ((0.2, -2.0, 6.9), (2.6, 2.6, 2.0))]
    top = [((0.0, 0.1, 8.7), (3.0, 3.0, 1.6))]
    _limbs_to(bark, (0.06, 0.03, 3.0), mid_m, frac=0.55, r0=0.17, r1=0.08, seed=13)
    for i, (c, rad) in enumerate(ring):
        crown_mass(lv, c, rad, CN_LEAF, seed=500 + i * 7, n=8, clump_size=2.1, el_lo=-0.15,
                   squash=0.75, core_scale=0.62)
    for i, (c, rad) in enumerate(mid_m + top):
        crown_mass(lv, c, rad, CN_LEAF, seed=560 + i * 7, n=8, clump_size=2.2, el_lo=-0.30,
                   squash=0.72, core_scale=0.72)
    _clamp_floor(bark)
    return [bark.to_object("Chestnut_Bark"), lv.to_object("Chestnut_Leaves")]


def build_chestnut_tree_b():
    """Castanul B (`chestnut_tree_b`): castan BATRAN de margine, ~9 m, coroana ~10 m.

    LISTA DE ELEMENTE (alta silueta decat A, ca padurea sa nu fie clone):
     a) TRUNCHI si mai GROS si mai SCURT (O 1,15 m), coaste rasucite mai tare, aplecat
        ~6 grade spre +X (spre lumina, marginea padurii).
     b) Ramificare la 2,2 m in TREI conducatori; unul spre -X e RUPT (ciot gol, fara
        frunzis) -- castanii batrani din Apuani au aproape toti o craca moarta.
     c) COROANA ASIMETRICA, turtita, mai multa masa pe +X: 7 mase, una joasa iesita spre
        +X (aproape pana la 3 m de sol), sus o masa lata.
     d) Culoarea ca la A (oliv inchis, varfuri galben-oliv).
    Noduri: Chestnut_Bark (LOG_DARK 28), Chestnut_Leaves (CACTUS_GREEN 12)."""
    bark, lv = Builder(), Builder()
    bark.taper_sweep([(0, 0, 0.0), (0.02, 0.0, 1.2), (0.05, 0.0, 2.3)], [0.58, 0.50, 0.45],
                     CN_BARK, segments=9)
    _cn_flare(bark, 0.66, 19, n=6)
    _spiral_ridges(bark, 0.57, 2.2, n=7, turns=0.42, seed=23)
    fork = Vector((0.05, 0.0, 2.2))
    lead1 = [fork, Vector((1.3, 0.3, 3.4)), Vector((2.9, 0.4, 4.6))]
    lead2 = [fork, Vector((0.1, -1.0, 3.8)), Vector((0.4, -2.0, 5.6))]
    lead3 = [fork, Vector((-0.6, 1.0, 3.9)), Vector((-0.9, 1.6, 5.9))]
    stub = [fork, Vector((-1.2, -0.2, 3.0)), Vector((-2.0, -0.3, 3.5))]   # craca rupta
    for p in (lead1, lead2, lead3):
        branch(bark, p, 0.30, 0.15, CN_BARK, seg=7)
    branch(bark, stub, 0.24, 0.13, CN_BARK, seg=6)
    bark.taper_sweep([Vector((-2.0, -0.3, 3.5)), Vector((-2.25, -0.32, 3.62))], [0.13, 0.0],
                     CN_BARK, segments=6)
    m = [((3.4, 0.5, 4.9), (2.6, 2.4, 1.7)), ((1.8, -1.6, 6.3), (2.5, 2.4, 1.8)),
         ((2.0, 1.7, 6.4), (2.4, 2.4, 1.8)), ((0.5, -2.4, 5.8), (2.2, 2.1, 1.6)),
         ((-1.0, 1.9, 6.6), (2.3, 2.2, 1.7)), ((-1.3, -0.6, 7.2), (2.2, 2.2, 1.6)),
         ((0.7, 0.2, 7.9), (3.0, 2.8, 1.5))]
    _limbs_to(bark, lead1[1], m[:3], frac=0.55, r0=0.14, r1=0.07, seed=29)
    _limbs_to(bark, lead3[1], m[4:6], frac=0.55, r0=0.13, r1=0.07, seed=31)
    for i, (c, rad) in enumerate(m):
        crown_mass(lv, c, rad, CN_LEAF, seed=640 + i * 7, n=8, clump_size=2.1,
                   el_lo=-0.2 if i else -0.05, squash=0.74, core_scale=0.66)
    _shear([bark, lv], 6.0)
    _clamp_floor(bark)
    return [bark.to_object("Chestnut_Bark"), lv.to_object("Chestnut_Leaves")]


def _shear(builders, lean_deg, axis=(1.0, 0.0)):
    """Aplecarea arborelui (ca la fagul B): x += z * tan(lean); baza ramane pe origine."""
    k = math.tan(math.radians(lean_deg))
    for b in builders:
        for v in b.bm.verts:
            v.co.x += v.co.z * k * axis[0]
            v.co.y += v.co.z * k * axis[1]


def _limbs_to(bark, start, masses, frac=0.72, r0=0.17, r1=0.07, seed=0):
    """Cate un brat din `start` spre centrul fiecarei mase (ca la fag): se vad prin goluri."""
    r = _rnd(seed)
    s = Vector(start)
    for (c, _rad) in masses:
        c = Vector(c)
        mid = s.lerp(c, 0.45) + Vector(((r() - 0.5) * 0.4, (r() - 0.5) * 0.4, -0.3))
        branch(bark, [s, mid, s.lerp(c, frac)], r0, r1, CN_BARK, seg=6)


# ---------------------------------------------------------------------------
# ginestra_fiorita
# ---------------------------------------------------------------------------

GN_STEM = TROPICAL_GREEN     # 21: tijele (clasa `macchia`)
GN_FLOWER = DRY_VEGETATION   # 13: florile (atlas, galben-auriu sub soarele temei)


def build_ginestra_fiorita():
    """Ginestra INFLORITA (`ginestra_fiorita`), varianta Carrara a lui `ginestra_bush`.

    De ce o piesa noua si nu doar remaparea: pe `ginestra_bush` florile sunt UN segment
    scurt in varful fiecarei tije (13-14% din arie); chiar intoarse pe atlas (ruptura de
    accente pe tema, world_prop.gd) tufa ramane un manunchi de bete verzi cu varfuri
    ocru. In bara (bara_poi_G.png) ginestra e o MASA GALBENA rotunjita: Spartium junceum
    inflorit are jumatatea de sus a tijelor imbracata in flori.

    LISTA DE ELEMENTE:
     a) 20 de TIJE verzi (TROPICAL_GREEN 21) care pornesc dintr-un mănunchi strans si se
        ARCUIESC in afara ca o fantana (tufa e mai lata sus decat jos): 1,1-1,7 m.
     b) FLORILE: pe jumatatea de sus a fiecarei tije, un SPIC galben (DRY_VEGETATION 13)
        care urmeaza arcul tijei, plus un ciorchine la jumatate pe fiecare a doua tija --
        de sus (camera de joc) tufa e o CUPOLA GALBENA din spice, din lateral se vad
        tijele verzi dedesubt.
     c) Dimensiuni: ~1,7 m inalta, ~1,9 m lata.
    Noduri: GinestraBloom_Stems, GinestraBloom_Flowers."""
    rnd = _rnd(887)
    stems, flw = Builder(), Builder()
    N = 20
    for k in range(N):
        a = 2.0 * math.pi * k / N + rnd() * 0.3
        r0 = 0.08 + 0.12 * rnd()
        h = 1.15 + 0.5 * rnd()
        out = 0.45 + 0.45 * rnd()
        d = Vector((math.cos(a), math.sin(a), 0.0))
        p0 = d * r0
        p1 = d * (r0 + out * 0.35) + Vector((0, 0, h * 0.55))
        p2 = d * (r0 + out) + Vector((0, 0, h))
        stems.taper_sweep([p0, p1, p2], [0.05, 0.04, 0.025], GN_STEM, segments=4)
        # Florile: un MANSON galben pe jumatatea de sus a tijei (spicul inflorit, 0,13 ->
        # 0,07 m), urmand arcul ei, cu 2 cm de tija verde lasata libera in varf. Runda 1
        # avea 3 boabe rotunde pe tija: de aproape iesea „popcorn pe bete", cu acadele la
        # capete. Spicul se citeste matura; ciorchinele de la jumatate ingroasa masa.
        sleeve = [p1.lerp(p2, u) + d * 0.02 for u in (0.0, 0.35, 0.7, 0.93)]
        flw.taper_sweep(sleeve, [0.13, 0.13, 0.10, 0.06], GN_FLOWER, segments=5)
        if k % 2 == 0:
            q = p1.lerp(p2, 0.45) + d * 0.08
            s = 0.30 + 0.10 * rnd()
            flw.boulder(tuple(q), (s, s, s * 0.75), GN_FLOWER, seed=k * 13,
                        segments=5, rings=2, deviation=0.18)
    # un capac de flori in centru, ca cupola sa nu aiba gol in mijloc
    for j in range(3):
        a = 2.0 * math.pi * j / 3 + 0.4
        flw.boulder((0.20 * math.cos(a), 0.20 * math.sin(a), 1.10 + 0.12 * (j % 2)),
                    (0.45, 0.45, 0.32), GN_FLOWER, seed=300 + j, segments=5, rings=2,
                    deviation=0.18)
    _clamp_floor(stems)
    return [stems.to_object("GinestraBloom_Stems"), flw.to_object("GinestraBloom_Flowers")]


# ---------------------------------------------------------------------------

clear_built()
if _want("stone_tower"):
    emit_post(build_stone_tower(), "buildings/stone_tower.glb", ao_for(8.2))
    clear_built()
if _want("tin_shed"):
    emit_post(build_tin_shed(), "buildings/tin_shed.glb", ao_for(3.9))
    clear_built()
if _want("chestnut_tree_a"):
    emit_post(build_chestnut_tree_a(), "plants/chestnut_tree_a.glb",
              dict(samples=24, dist=1.6, gradient="vertical", low=0.42, high=1.0,
                   power=0.7, floor=0.30, z_range=(-0.01, 10.5)),
              post=lambda o: _leaf_tint(o) if o.name == "Chestnut_Leaves" else None)
    clear_built()
if _want("chestnut_tree_b"):
    emit_post(build_chestnut_tree_b(), "plants/chestnut_tree_b.glb",
              dict(samples=24, dist=1.6, gradient="vertical", low=0.42, high=1.0,
                   power=0.7, floor=0.30, z_range=(-0.01, 9.0)),
              post=lambda o: _leaf_tint(o) if o.name == "Chestnut_Leaves" else None)
    clear_built()
if _want("ginestra_fiorita"):
    emit_post(build_ginestra_fiorita(), "plants/ginestra_fiorita.glb",
              dict(samples=16, dist=0.5, gradient="vertical", low=0.55, high=1.0,
                   power=0.8, floor=0.40, z_range=(0.0, 1.7)))
    clear_built()
report_crr()
