"""Transfagarasan -- drumul (brief docs/asset_briefs/transfagarasan_kit.md §1.1).

  transfagarasan/structures/tunnel_portal_balea.glb   portalul tunelului Balea  (PILOT)

Restul pieselor grupei (rock_tunnel_portal, snow_wall, retaining_wall_*,
snow_pole, road_works, level_crossing, bear_warning_sign) vin in valul 1.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_tf_road.py

Fara text, cifre sau logo-uri (regula 9). Fata = +Y in Blender (= -Z in Godot);
piesa e simetrica fata-spate, acelasi GLB la ambele guri. Originea: pe axa
drumului (x = 0, y = 0), baza pe Z = 0. Variabila de mediu TF_ONLY=<piesa> reface
doar piesa respectiva.
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "transfagarasan_shapes.py")).read())

clear_built()

AO_PORTAL = dict(samples=16, dist=2.6, gradient="vertical", low=0.62, high=1.0,
                 power=0.8, floor=0.34, z_range=(0.0, 13.5))


def build_tunnel_portal_balea():
    """Portalul tunelului de la Balea (`tunnel_portal_balea`), PILOT, REV. 2
    (contract nou al coordonatorului: placa masiva, gura teșita, zapada care
    INVELUIE portalul; planșa bate corectura `snow_wall` pentru piesa asta).

    LISTA DE ELEMENTE (din decuparea `transfagarasan_assets_v1/tunnel_portal_balea.png`
    si din contractul nou; scrisa INAINTE de geometrie; fasia din piesa vecina
    de la marginea stanga a decuparii se ignora):
      a) PLACA de beton: bloc masiv 26 m (X) x 11 m (Z) x 6 m (Y), muchii vii,
         FARA cornisa, contraforturi sau rama iesita; fata din fata (+Y) usor
         inclinata inapoi (~5 grade); pe planșa latura vizibila e ~1/4 din latime
         (6/26 = 0,23). Fata e DOAR pe +Y; spatele (-Y) intra in munte
      b) GURA dreptunghiulara cu umeri TESITI (nu arc): 15 m la baza (+-7,5),
         stalpi verticali pana la 6,5 m, tesituri la 45 grade de 2 m, buiandrug
         drept la 8,5 m (~58% din latime, ca pe planșa)
      c) `Portal_Void`: captuseala pe pereti si tavan, pe toata grosimea placii
         si 4 m in spate (10 m, y -10..0), fara podea, fara capace; in preview
         (NU in GLB) un plan negru la y = -12
      d) MOVILA DE ZAPADA pe laturi: 8 blocuri mari, fatetate, unghiulare pe
         fiecare parte (planșa: 5-6 vizibile), 9-10 m langa placa, coborand la
         ~4 m la 11 m spre exterior; incep de la |x| >= 13 (nimic in banda
         drumului), fata blocurilor ~0,5 m in spatele fetei placii (placa iese
         ~1 m in fata zapezii la baza)
      e) CALOTA de zapada peste placa si in spatele ei, 4 randuri x 4-5 blocuri neregulate:
         urca spre -Y pana la ~13 m, la 10 m in spate; pe deasupra tubului
         sta de la 8,55 m in sus (peste captuseala), deci golul ramane liber
      f) 2 blocuri interioare in spatele placii (|x| 7,6..13) care inchid
         peretii tubului
      g) PRAFUL `Portal_Dust`: 3 bucati scurte, inclinate, NEregulate, pe
         blocurile de jos din fata, pe fiecare parte
      h) NU intra: asfaltul, marcajele, vegetatia

    Contract (golul, MASURAT pe GLB): >= 13,0 m lateral pe 0-2 m, >= 7,0 m
    inaltime libera in fereastra |x| <= 6,5 (aici ~14,9 m si ~7,5 m).
    Noduri: Portal_Concrete (CONCRETE 8), Portal_Snow (FOAM_WHITE 22),
    Portal_Dust (CONCRETE 8), Portal_Void (VOLCANIC_BLACK 20). Origine pe
    axa drumului, la fata placii (y = 0 la baza), baza la z = 0.
    """
    HX, DEP, H = 13.0, 6.0, 11.0
    TAN = math.tan(math.radians(5.0))
    conc, snow, dust, void = Builder(), Builder(), Builder(), Builder()

    mouth = [(-7.5, 0.0), (-7.5, 6.5), (-5.5, 8.5), (5.5, 8.5), (7.5, 6.5), (7.5, 0.0)]
    outline = [(-HX, 0.0)] + mouth + [(HX, 0.0), (HX, H), (-HX, H)]
    extrude_xz(conc, outline, -DEP, 0.0, TF_CONCRETE)
    tilt_front(conc, 0.0, TAN)

    tube_lining(void, mouth, -DEP - 4.0, 0.0, TAN)

    # --- movila pe laturi: (cx, cy, h, sx, sy) pe partea +X; oglindita pe -X cu
    # alt seed ca sa nu fie copie
    side = [
        (15.8, -3.2, 9.6, 5.6, 5.4), (15.8, -8.6, 9.2, 5.6, 5.4),
        (16.0, -13.8, 7.0, 5.8, 5.0),
        (20.4, -3.0, 6.8, 5.0, 5.0), (20.6, -8.2, 6.6, 5.2, 5.6),
        (20.8, -13.6, 5.0, 4.8, 5.0),
        (22.4, -3.4, 4.2, 3.4, 4.2), (22.4, -9.0, 4.0, 3.4, 5.0),
        (10.4, -9.0, 9.6, 5.6, 6.0),     # interior, in spatele placii (|x| 7,6..13)
        (10.6, -14.0, 7.0, 5.6, 5.0),
    ]
    for sx in (1, -1):
        for k, (cx, cy, h, bx, by) in enumerate(side):
            faceted_block(snow, (sx * cx, cy, 0.0), (bx, by, h), TF_SNOW,
                          seed=100 + k * 7 + (0 if sx > 0 else 53))

    # --- calota: 4 randuri x 4-5 blocuri neregulate deasupra placii si a tubului
    import random
    rr = random.Random(77)
    rows = [(-3.6, 10.3, 1.9, 5.0, 12.2), (-6.6, 8.55, 3.8, 5.6, 12.7),
            (-10.6, 8.55, 4.4, 5.6, 13.1), (-14.2, 8.55, 4.2, 5.0, 12.4)]
    for r, (cy, zb, hh, by, top) in enumerate(rows):
        n = 5 if r else 4
        for i in range(n):
            cx = -12.0 + 24.0 * (i + 0.5) / n + (rr.random() - 0.5) * 2.2
            wx = 5.8 + rr.random() * 3.2
            ht = top - zb + (rr.random() - 0.5) * 1.2
            faceted_block(snow, (cx, cy + (rr.random() - 0.5) * 0.8, zb - (0.0 if r else 0.0)),
                          (wx, by + rr.random() * 1.2, ht), TF_SNOW,
                          seed=300 + r * 11 + i, jag=0.42)
    # --- praf: bucati scurte, inclinate, neregulate, pe blocurile de jos din fata
    patches = [(14.4, -0.5, 1.3, 2.1, 14.0), (18.2, -0.4, 3.0, 1.6, -19.0),
               (21.0, -0.6, 2.2, 2.4, 9.0)]
    for sx in (1, -1):
        for (x, y, z, ln, ang) in patches:
            dust_patch(dust, (sx * (x + (0.7 if sx < 0 else 0.0)), y - 0.38, z), ln * 1.3, sx * ang, height=0.3)

    return [Builder.to_object(conc, "Portal_Concrete"),
            Builder.to_object(snow, "Portal_Snow"),
            Builder.to_object(dust, "Portal_Dust"),
            to_obj(void, "Portal_Void")]


AO_SNOW_WALL = dict(samples=16, dist=1.2, gradient="vertical", low=0.70, high=1.0,
                    power=0.7, floor=0.45)


def emit_tf_variants(variants, path, smooth_angle=35.0):
    """GLB cu VARIANTE: fiecare varianta e o radacina goala (Empty, scala 1, la
    origine) cu nodurile ei de un singur material ca copii (`SnowWall_A` ->
    `SnowWall_A_Snow`, `SnowWall_A_Dust`). Godot alege varianta dupa numele
    copilului DIRECT al radacinii GLB (docs/blender_export.md), iar clasa se
    pune pe sufixul nodului copil. Toate variantele stau la origine (regula 1
    din blender_export.md); baza fiecareia e deja la z = 0, XY pe axa.
    `variants` = lista (nume_radacina, [obiecte], ao)."""
    out, total, per_node = [], 0, {}
    lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
    for root, objs, ao in variants:
        objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
        emp = bpy.data.objects.new(root, None)
        bpy.context.collection.objects.link(emp)
        for o in objs:
            st = finish(o, bevel=0.0, ao=ao, origin=None, smooth_angle=smooth_angle)
            total += st["tris"]
            per_node[o.name] = st["tris"]
            o.parent = emp
            for v in o.data.vertices:
                lo = Vector((min(lo[i], v.co[i]) for i in range(3)))
                hi = Vector((max(hi[i], v.co[i]) for i in range(3)))
        out += [emp] + objs
    _, sz = export_glb(out, "transfagarasan/" + path)
    TF_RESULTS.append((path, total, hi - lo, per_node, sz / 1024.0))
    return total


def build_snow_wall():
    """Peretele de zapada veche de langa asfalt (`snow_wall`), kit §1.1.

    LISTA DE ELEMENTE (decuparea `transfagarasan_assets_v1/snow_wall.png`,
    scrisa INAINTE de geometrie):
      1) un perete lung si drept, h/l ~0,5 pe fata lunga, grosimea ~1/3 din
         inaltime la capat
      2) fata lunga din ~7 COLOANE x 3 RANDURI de blocuri fatetate (~21), fiecare
         bloc cu fata impartita in 4 fatete ca o piramida joasa
      3) muchia de sus neregulata: blocurile de sus au inaltimi diferite, unul la
         mijloc e retezat oblic
      4) capatul din dreapta vizibil, fatetat ca fata lunga
      5) culoare: alb cu umbre albastrui pe fatetele intoarse
    CORECTURA coordonatorului (suprascrie decuparea, kit "Corecturi"): NU cuburi
    albe curate, ci zapada veche de iulie. Lista urmeaza corectura:
      a) fata spre drum (-X) taiata VERTICAL de plug, cu 4 STRATURI (A) / 3 (B)
         in loc de cele 3 randuri de blocuri; intre straturi TREPTE de 0,22-0,30 m
         (fata se retrage la fiecare prag), buza fiecarui strat rotunjita
      b) cele ~7 coloane ale decuparii devin 7 SCOBITURI de freza pe fata taiata
         (celule concave de 1,14 m, adanci 0,11 m, cu muchii verticale intre ele):
         pastreaza ritmul vertical al desenului fara rosturi de cuburi
      c) dungile de praf: PETE (fete mutate pe `*_Dust`, CONCRETE 8) in banda de
         la baza fiecarui strat si pe praguri, neregulate pe lungime; baza murdara
         (banda de 0,3 m, cea mai acoperita), si o banda rara la baza fetei din spate
      d) fata dinspre versant (+X) rotunjita: umar convex, 2,5 m gros la baza,
         1,2 m sus
      e) muchia de sus topita: rotunjita si ondulata (+-0,1 m pe lungime)
      f) capete plane, IDENTICE la +-4 m pe Y: toata variatia (cote de strat,
         trepte, ondulare, praf) e periodica pe 8 m, scobiturile au cuspida la capete
    Cote: modul 8 m (Y), A 4 m / B 3 m inaltime, 2,5 m la baza, 1,2 m sus.
    Noduri: radacinile `SnowWall_A`, `SnowWall_B` (Empty), copiii
    `SnowWall_<v>_Snow` (FOAM_WHITE 22) si `SnowWall_<v>_Dust` (CONCRETE 8)."""
    variants = []
    for v, H, seed in (("A", 4.0, 0.0), ("B", 3.0, 2.4)):
        snow, dust = Builder(), Builder()
        nd = snow_wall_module(snow, dust, H, L=8.0, seed=seed)
        print("snow_wall %s: %d fete de praf" % (v, nd))
        ao = dict(AO_SNOW_WALL, z_range=(0.0, H))
        variants.append(("SnowWall_" + v,
                         [to_obj(snow, "SnowWall_%s_Snow" % v), to_obj(dust, "SnowWall_%s_Dust" % v)],
                         ao))
    return variants


AO_ROCK = dict(samples=16, dist=2.4, gradient="vertical", low=0.62, high=1.0,
               power=0.8, floor=0.32, z_range=(0.0, 13.0))


def bool_apply(obj, cutter, op):
    """Boolean EXACT aplicat (op = DIFFERENCE / INTERSECT / UNION); `use_self`:
    piesele sunt hull-uri care se intrepatrund."""
    mod = obj.modifiers.new("Bool", "BOOLEAN")
    mod.operation = op
    mod.object = cutter
    mod.solver = "EXACT"
    mod.use_self = True
    mod.use_hole_tolerant = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)


def retag_all(obj, slot):
    """Dupa boolean, fetele noi n-au slot (ar cadea pe 0, SAND_LIGHT): totul pe `slot`."""
    me = obj.data
    a = me.attributes.get("slot")
    if a is None or a.domain != "FACE":
        if a is not None:
            me.attributes.remove(a)
        a = me.attributes.new("slot", "INT", "FACE")
    for i in range(len(me.polygons)):
        a.data[i].value = slot


def split_faces(obj, pred, name, slot):
    """Muta fetele care satisfac `pred(BMFace)` intr-un nod nou (acelasi contur,
    alt material); infasurarea se pastreaza, deci nodul se face fara recalc."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    nb = Builder()
    sel = [f for f in bm.faces if pred(f)]
    for f in sel:
        nf = nb.bm.faces.new([nb.bm.verts.new(v.co.copy()) for v in f.verts])
        nf[nb.slot] = slot
    bmesh.ops.delete(bm, geom=sel, context="FACES")
    bm.to_mesh(obj.data)
    bm.free()
    return to_obj(nb, name), len(sel)


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    objs[0].name = name
    objs[0].data.name = name
    return objs[0]


def drop(o):
    bpy.data.objects.remove(o, do_unlink=True)


def rock_bore_path():
    """Conturul golului (stanga jos -> sus -> dreapta jos), in (x, z). Pereti la
    |x| >= 7,75 pe banda 0-2 m, bolta neregulata: elipsa (a 7,95, b 5,5, centru
    la 4,3) + jitter DOAR spre exterior, asimetric stanga-dreapta (roca taiata,
    nu arc zidit). La |x| = 6,5 bolta e la >= 7,4 m."""
    import random
    rr = random.Random(21)
    left = [(-7.75, 0.0), (-7.85, 1.4), (-7.80, 2.9), (-7.98, 4.3)]
    right = [(7.98, 4.3), (7.85, 2.8), (7.92, 1.5), (7.75, 0.0)]
    arch = []
    n = 13
    for i in range(1, n):
        t = math.pi * (1.0 - i / n)
        out = 0.10 + 0.45 * rr.random()
        ax, bz = 7.95 + out, 5.5 + out
        arch.append((ax * math.cos(t), 4.3 + bz * math.sin(t)))
    return left + arch + right


ROCK_MOUND = [(13.0, 0.0), (13.2, 3.0), (12.6, 5.6), (11.6, 7.8), (10.2, 9.8), (8.4, 11.2),
              (5.8, 12.1), (2.5, 12.6), (0.0, 12.7), (-2.8, 12.5), (-6.0, 11.9), (-8.6, 10.9),
              (-10.4, 9.4), (-11.8, 7.4), (-12.7, 5.0), (-13.2, 2.6), (-13.0, 0.0)]


def build_rock_tunnel_portal():
    """Tunelul scurt prin pintenul de sist de pe malul Vidraru (`rock_tunnel_portal`).

    LISTA DE ELEMENTE (decuparea `transfagarasan_assets_v1/rock_tunnel_portal.png`,
    scrisa INAINTE de geometrie; asfaltul si marcajele din decupare se ignora):
      1) o movila de stanca in forma de dom, h/l ~0,6 pe decupare, mai joasa la
         capete (~1/4 din inaltime la margini), din ~12-14 BLOCURI unghiulare mari
         vizibile pe fata, cu fete plane, gri-cald
      2) gura: arc semicircular pe pereti verticali, ~45% din latime, interior
         intunecat care se pierde in adanc
      3) INELUL DE ZIDARIE: ~13 bolțari in jurul gurii + 2 stalpi zidiți
      4) muschi galben-verde pe fetele de sus ale blocurilor, peste tot
      5) bolovani mici la picior, pe ambele parti
    CORECTURA coordonatorului (suprascrie decuparea): stanca BRUTA, FARA inelul
    de zidarie (3 cade); pinten INTREG strapuns, deschis la ambele capete; lame
    de sist inclinate in ACEEASI directie pe toata piesa; iarba DOAR pe crestet
    (strat subtire, pentru 2-3 fagi la integrare), deci muschiul de pe toate
    blocurile (4) se reduce la crestet. Lista urmeaza corectura:
      a) MASA: profil de dom ascutit, umeri inalti, 26 m (X) x ~12,7 m (Z) extrudat pe 13 m (y +-6,5),
         cu gura taiata; capetele acoperite de lamele de la b)
      b) FETELE DE CAPAT (+-Y): ~13 benzi de sist inclinate la 40 grade (urca
         spre +X), fiecare rupta in blocuri de 5-9 m, iesite inegal din fata
         (y 6,2..8,0) -> blocurile unghiulare din 1), dar asezate pe foliatie
      c) FLANCURILE si CRESTETUL: ~25 de lame pe aceeasi foliatie, iesite din
         masa, ca silueta sa fie zimtata (dinti de sist), pana la ~13 m
      d) GURA NEREGULATA: bolta din 12 fatete pe o elipsa cu jitter spre exterior,
         asimetrica; pereti la |x| >= 7,75; fara inel, fara stalpi
      e) `Rock_Void`: captuseala VOLCANIC_BLACK doar in primii 2 m la fiecare capat
      f) `Rock_Grass`: fetele de sus ale crestetului (normala > 0,8, z > 11,4),
         TROPICAL_GREEN; pe crestet (|x| < 4) doar lame joase, iarba ramane in
         petice intre ele (loc pentru 2-3 fagi)
      g) bolovanii de la picior (5): NU, ii pune integrarea (`canyon_rocks`),
         ca sa nu intre in banda drumului
    Contract (golul, MASURAT CA GOL pe tot pintenul): >= 15,0 m pe banda 0-2 m,
    >= 7,0 m inaltime libera in |x| <= 6,5. Noduri: `Rock_Schist` (MARBLE_GREY 29,
    clasa tf_schist), `Rock_Grass` (TROPICAL_GREEN 21), `Rock_Void` (VOLCANIC_BLACK
    20; nod separat, altfel clasa de sist ar sterge negrul -- memoria
    clase-pe-piese-de-kit). Origine pe axa drumului, la mijlocul pintenului, baza 0."""
    import random
    rr = random.Random(1997)
    DIP = 40.0
    HL = 8.0
    mound = ROCK_MOUND
    bore = rock_bore_path()

    # a) masa: dom extrudat, cu gura (contur concav, antiorar in XZ)
    core = Builder()
    extrude_xz(core, [(-13.0, 0.0)] + bore + [(13.0, 0.0)] + mound[1:-1], -6.5, 6.5, TF_SCHIST)
    core_o = Builder.to_object(core, "RockCore")

    # b) fetele de capat: benzi la 40 grade, rupte in blocuri
    ends = Builder()
    dp = math.radians(DIP)
    dvec = Vector((math.cos(dp), math.sin(dp)))
    nvec = Vector((-math.sin(dp), math.cos(dp)))
    k = 0
    for sy in (-1, 1):
        off = -9.2
        while off < 13.5:
            t = 1.8 + 1.2 * rr.random()
            mid = off + t * 0.5
            u = -24.0 + rr.random() * 3.0
            while u < 24.0:
                w = 3.5 + 3.5 * rr.random()
                c2 = nvec * mid + dvec * (u + w * 0.5)
                out = HL - 1.8 * rr.random() ** 0.7
                depth = 3.4
                schist_blade(ends, (c2.x, sy * (out - depth * 0.5), c2.y), (depth, w + 0.3, t + 0.15),
                             dip_deg=DIP, seed=5000 + k, jag=0.10, lip=0.35)
                u += w
                k += 1
            off += t
    ends_o = Builder.to_object(ends, "RockEnds")
    clip = Builder()
    extrude_xz(clip, [(-13.0, -0.5), (13.0, -0.5)] + mound[1:-1], -HL - 0.01, HL + 0.01, TF_SCHIST)
    clip_o = Builder.to_object(clip, "RockClip")
    bool_apply(ends_o, clip_o, "INTERSECT")
    drop(clip_o)

    # c) flancurile si crestetul: lame pe aceeasi foliatie, iesite din masa
    blades = Builder()
    pts = mound[1:-1]
    k = 0
    for i in range(len(pts) - 1):
        (x0, z0), (x1, z1) = pts[i], pts[i + 1]
        for f in (0.25, 0.75):
            x, z = x0 + (x1 - x0) * f, z0 + (z1 - z0) * f
            low = abs(x) < 4.0 and z > 11.5     # crestet: lame joase, iarba intre ele (fagii)
            nrm = Vector((z1 - z0, -(x1 - x0))).normalized()
            if nrm.dot(Vector((x, z - 4.0))) < 0:
                nrm = -nrm
            push = (0.1 + 0.3 * rr.random()) if low else (0.6 + 0.8 * rr.random())
            px, pz = x + nrm.x * (push - 1.0), z + nrm.y * (push - 1.0)
            ln = 4.0 + 3.5 * rr.random()
            cy = (rr.random() - 0.5) * (2 * HL - ln) * 0.9
            schist_blade(blades, (px, cy, pz), (ln, 3.2 + 1.8 * rr.random(), 1.6 + 0.9 * rr.random()),
                         dip_deg=DIP + (rr.random() - 0.5) * 6.0, seed=7000 + k, jag=0.14)
            k += 1
    blades_o = Builder.to_object(blades, "RockBlades")
    box = Builder()
    box.box((0.0, 0.0, 6.5), (26.6, 2 * HL, 13.0), TF_SCHIST)   # latimea de contract 26 m (+-0,3)
    box_o = Builder.to_object(box, "RockBox")
    bool_apply(blades_o, box_o, "INTERSECT")
    drop(box_o)

    rock = join([core_o, ends_o, blades_o], "Rock_Schist")

    # d) gura: taie golul prin tot pintenul; apoi nimic sub cota 0
    cut = Builder()
    extrude_xz(cut, [(bore[0][0], -1.0)] + bore + [(bore[-1][0], -1.0)], -HL - 3.0, HL + 3.0, TF_SCHIST)
    cut_o = Builder.to_object(cut, "RockCut")
    bool_apply(rock, cut_o, "DIFFERENCE")
    drop(cut_o)
    floor = Builder()
    floor.box((0.0, 0.0, -5.0), (60.0, 40.0, 10.0), TF_SCHIST)
    floor_o = Builder.to_object(floor, "RockFloor")
    bool_apply(rock, floor_o, "DIFFERENCE")
    drop(floor_o)
    retag_all(rock, TF_SCHIST)

    # f) iarba pe crestet
    grass, ng = split_faces(rock, lambda f: f.normal.z > 0.80 and f.calc_center_median().z > 11.4,
                            "Rock_Grass", TROPICAL_GREEN)
    print("rock_tunnel_portal: %d fete de iarba" % ng)

    # e) captuseala neagra, doar primii 2 m la fiecare capat
    void = Builder()
    tube_lining(void, bore, HL - 2.0, HL, 0.0)
    tube_lining(void, bore, -HL, -HL + 2.0, 0.0)
    return [rock, grass, to_obj(void, "Rock_Void")]


ONLY = os.environ.get("TF_ONLY", "")


def _want(name):
    return not ONLY or ONLY == name


if _want("tunnel_portal_balea"):
    objs = build_tunnel_portal_balea()
    emit_tf(objs, "structures/tunnel_portal_balea.glb", AO_PORTAL, keep_xy=True,
            bevel=0.0, smooth_angle=None)

if _want("rock_tunnel_portal"):
    emit_tf(build_rock_tunnel_portal(), "structures/rock_tunnel_portal.glb", AO_ROCK,
            keep_xy=True, bevel=0.0, smooth_angle=None)

if _want("snow_wall"):
    emit_tf_variants(build_snow_wall(), "structures/snow_wall.glb")

report_tf()
