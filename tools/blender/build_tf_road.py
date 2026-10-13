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
    """Portalul tunelului de la Balea (`tunnel_portal_balea`), PILOT, REV. 4
    (zapada refacuta in valul 1; placa, gura si golul sunt cele din rev. 2)
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
      d) MOVILA DE ZAPADA (rev. 4, val 1 tf-a; decizia coordonatorului: vocabularul
         `snow_wall`, bulgari izotropi, masa continua, potcoava). Pe decupare:
         bulgari fatetati de ~2-2,5 m (cam 1/5 din inaltimea placii), ~25 pe un
         brat, lipiti unul de altul fara goluri, in potcoava; bratele vin in
         fata pana la linia fetei placii, inalte cat placa langa ea si mai joase
         spre capete. Aici: brate de la |x| 13 la 24, 10,8 m langa placa ->
         ~4,6 m la 11 m spre exterior, fata movilei la y = -1 langa placa
         (placa iese ~1 m) si inainte pana la y ~ +0,8 la capete
      e) CALOTA peste placa (de la y = -2,5, partea din fata a crestei placii
         ramane libera) si peste tub, urca la ~13 m la 8 m in spate; peste tub
         nimic sub 8,6 m (golul ramane liber pe ORICE y)
      f) spatele placii (|x| 7,75..13) umplut din sol, ca peretii tubului sa
         fie inchisi
      g) PRAFUL `Portal_Dust`: PETE, nu volume: 10 fete pe parte ale bulgarilor
         de jos din fata bratelor, mutate pe nodul de praf (vocabularul `snow_wall`)
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

    # --- ZAPADA (rev. 4, val 1 tf-a): masa continua din bulgari aproape izotropi,
    # in potcoava pe laturi + calota in spate. Campul de inaltime decide unde e
    # zapada; bulgarii il umplu pe o grila jitterata (pas 2,8 m, raza ~2,0 m ->
    # suprapunere 30% pe orizontala, 2,6 m pe verticala -> 35%). Se pastreaza
    # doar coaja (bulgarii acoperiti din toate partile nu se vad).
    import random
    rr = random.Random(2026)
    S, R0, DZ = 2.8, 2.0, 2.6

    def smooth(t):
        t = max(0.0, min(1.0, t))
        return t * t * (3.0 - 2.0 * t)

    def h_side(x, y):
        """Bratele potcoavei: |x| 13 -> 24, fata se trage inainte spre capete."""
        u = abs(x) - 13.0
        if u < -1.5 or u > 11.5:
            return 0.0
        vf = -1.0 + 0.16 * max(u, 0.0)          # fata movilei (placa iese ~1 m)
        if y > vf or y < -17.5:
            return 0.0
        h = 10.8 - 0.56 * max(u, 0.0)           # 10,8 langa placa -> ~4,6 la 11 m
        h *= math.sqrt(smooth((vf - y) / 1.8))  # fata abrupta, rotunjita sus
        h *= math.sqrt(smooth((11.5 - u) / 2.5))
        h *= math.sqrt(smooth((y + 17.5) / 3.0))
        return h

    def h_cal(x, y):
        """Calota: peste placa (de la y = -2,5) si peste tub, urca la ~13 m."""
        if abs(x) > 14.5 or y > -2.5 or y < -17.5:
            return 0.0
        h = 11.5 + 1.7 * smooth((-2.5 - y) / 6.0) - 0.006 * x * x
        h -= 2.0 * (1.0 - smooth((y + 17.5) / 3.5))
        return h

    def floor_at(x, y):
        return 11.0 if (abs(x) < 13.0 and y > -6.0) else 0.0

    cols = {}
    nx = int(26.0 / S) + 1
    ny = int(19.5 / S) + 1
    for i in range(-nx, nx + 1):
        for j in range(ny + 1):
            x = i * S + (rr.random() - 0.5) * 0.7 * S
            y = 1.6 - j * S + (rr.random() - 0.5) * 0.7 * S
            H = max(h_side(x, y), h_cal(x, y))
            if H < 1.2:
                continue
            f = floor_at(x, y)
            if H - f < 0.8:
                continue
            zs = []
            z = f + 0.55 * R0 + rr.random() * 0.6
            while z < H - 0.55 * R0:
                zs.append(z)
                z += DZ
            zs.append(H - 0.55 * R0)
            cols[(i, j)] = (x, y, f, H, zs)

    placed = kept = 0
    for (i, j), (x, y, f, H, zs) in cols.items():
        nbr = [cols.get((i + di, j + dj)) for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        for li, z in enumerate(zs):
            r = R0 * (0.92 + 0.18 * rr.random())
            ext = 1.1 * r
            # golul: nimic sub 8,6 m in |x| <= 7,75, la ORICE y (masuratoarea e pe proiectie)
            if abs(x) - ext < 7.8 and z - ext < 8.6:
                continue
            # nimic IN FATA fetei placii in banda ei (|x| < 13); in volumul placii
            # (y -6..0) zapada e ascunsa, deci calota poate sta lipita de creasta
            if y + ext > -0.9 and abs(x) - ext < 13.0:
                continue
            placed += 1
            top = li == len(zs) - 1
            interior = (not top and all(n is not None and n[3] >= z + 1.0 for n in nbr)
                        and z - f > 1.0)
            if interior:
                continue
            bulgar(snow, (x, y, z), r, TF_SNOW, seed=10000 + i * 131 + j * 17 + li,
                   base=f if (li == 0 and f == 0.0) else None)
            kept += 1
    print("portal Balea: %d bulgari in camp, %d in coaja" % (placed, kept))

    # --- praful: PETE pe fete (fete mutate pe Portal_Dust), pe bulgarii de jos
    # din fata bratelor, 6 pe parte
    bmesh.ops.recalc_face_normals(snow.bm, faces=snow.bm.faces[:])
    snow.bm.faces.ensure_lookup_table()
    for sx in (1, -1):
        pool = []
        for fc in snow.bm.faces:
            c = fc.calc_center_median()
            if (c.x * sx > 13.5 and c.z < 4.5 and fc.calc_area() > 0.8
                    and fc.normal.y * 0.8 + fc.normal.x * sx * 0.4 > 0.35 and fc.normal.z < 0.6):
                pool.append(fc)
        random.Random(7 + sx).shuffle(pool)
        faces_to_dust(snow, dust, pool[:10])

    return [Builder.to_object(conc, "Portal_Concrete"),
            to_obj(snow, "Portal_Snow"),
            to_obj(dust, "Portal_Dust"),
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


AO_WALL = dict(samples=16, dist=1.6, gradient="vertical", low=0.66, high=1.0,
               power=0.8, floor=0.38, z_range=(-5.0, 0.0))


def build_retaining_wall(curve=False):
    """Zidul de sprijin din piatra uscata de la acele de par
    (`retaining_wall_straight` / `retaining_wall_curve`), kit §1.1.

    LISTA DE ELEMENTE (decuparile `transfagarasan_assets_v1/retaining_wall_straight.png`
    si `retaining_wall_curve.png`, scrisa INAINTE de geometrie; fasia din piesa
    vecina din dreapta decuparii curbe se ignora):
      1) zid lung, h/l ~0,4 pe decupare (dreapta), ~0,45 (curba)
      2) RANDUL DE SUS: ~11 pietre de coronament dreptunghiulare, mai deschise,
         usor iesite din fata, cu rosturi vizibile
      3) CORPUL: ~40 de pietre rotunjite, neregulate, in 4-5 asize, cu rosturi
         inchise si putin verde in rosturi
      4) fata usor inclinata, capatul din dreapta vizibil (gros ~1/4 din inaltime)
      5) curba: aceeasi zidarie pe un arc, fata CONVEXA spre privitor
    CONTRACTUL kitului (suprascrie decuparea, regula 7 + tabelul §1.1): pietre
    individuale DOAR pe randul de sus, 7-9 pe modul (decuparea are ~11: urmez
    contractul, 8); corpul (3) e masa cu FETE MARI, piatra lui vine din clasa
    `stone_wall` la integrare; fara verde in rosturi (fara vegetatie lipita).
    Lista urmeaza contractul:
      a) corpul: 8 m (Y) x 5 m, spate vertical (x = 0, ingropat), fata spre vale
         (+X) de la 1,2 m sus la 2,0 m jos (talus ~9 grade), 4 randuri de fete
         mari cu jitter periodic
      b) randul de sus: 8 pietre/modul (7 intregi + 2 jumatati la capete care
         fac o piatra peste rost), fata de sus PLANA la z = 0, buza tesita,
         iesite 0,10-0,20 m din fata, inalte 0,62-0,86 m, rosturi de 5 cm
      c) capete plane la +-4 m, aceeasi sectiune la ambele capete si la ambele
         module (drept / curb)
      d) curba: acelasi zid pe arcul R = 23 m la marginea drumului (x = 0),
         coarda 8 m, fata convexa spre vale (+X)
    Nod: `Wall_Stone` (MARBLE_GREY 29). Origine pe marginea drumului (x = 0) la
    cota crestei (z = 0); geometria atarna sub 0 (`--origin=rim`)."""
    b = Builder()
    dry_stone_wall(b, L=8.0, H=5.0, top_w=1.2, base_w=2.0, stones=8, seed=3.0,
                   slot=MARBLE_GREY, bend_R=23.0 if curve else None)
    return [Builder.to_object(b, "Wall_Stone")]


def emit_rim(objs, path, ao):
    """Ca `emit_tf`, dar originea e pe COAMA: nu se muta nimic (geometria e
    construita cu creasta la z = 0 si atarna dedesubt)."""
    total, per_node = 0, {}
    for o in objs:
        st = finish(o, bevel=0.0, ao=ao, origin=None, smooth_angle=None)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    _, sz = export_glb(objs, "transfagarasan/" + path)
    TF_RESULTS.append((path, total, Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))),
                       per_node, sz / 1024.0))


AO_PROP = dict(samples=12, dist=0.6, gradient="vertical", low=0.78, high=1.0,
               power=0.8, floor=0.5)
POST_GREY = ASPHALT_EDGE          # 6, #696765: stalpi, capre, carcase


# --- 2D pe planul XZ (fata spre +Y) -----------------------------------------

def _ccw(pts):
    a = sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1]
            for i in range(len(pts)))
    return pts if a > 0 else list(reversed(pts))


def plate(b, pts, y0, y1, slot, ox=0.0, oz=0.0):
    """Placa din conturul 2D (u, t) -> (ox + u, z = oz + t), intre y0 si y1."""
    extrude_xz(b, _ccw([(ox + u, oz + t) for u, t in pts]), y0, y1, slot)


def seg2(p, q, w):
    p, q = Vector(p), Vector(q)
    d = (q - p).normalized()
    n = Vector((-d.y, d.x)) * (w * 0.5)
    return [tuple(p - n), tuple(q - n), tuple(q + n), tuple(p + n)]


def disk2(c, r, n=10):
    return [(c[0] + r * math.cos(2 * math.pi * i / n), c[1] + r * math.sin(2 * math.pi * i / n))
            for i in range(n)]


def clip_x(poly, lo, hi):
    """Sutherland-Hodgman pe benzi verticale lo <= u <= hi."""
    def cut(pts, keep, edge):
        out = []
        for i in range(len(pts)):
            a, b2 = pts[i - 1], pts[i]
            ia, ib = keep(a), keep(b2)
            if ib:
                if not ia:
                    out.append(edge(a, b2))
                out.append(b2)
            elif ia:
                out.append(edge(a, b2))
        return out

    def at(x):
        return lambda a, b2: (x, a[1] + (b2[1] - a[1]) * (x - a[0]) / (b2[0] - a[0]))
    poly = cut(poly, lambda p: p[0] >= lo, at(lo))
    return cut(poly, lambda p: p[0] <= hi, at(hi)) if poly else []


def warning_triangle(b, side, border, z_base, y_face, x0=0.0):
    """Semn triunghiular cu varful in sus, fata spre +Y: chenar KERB_RED (placa de
    3 cm), camp FOAM_WHITE iesit 5 mm, spatele de tabla gri. Intoarce (z_baza_campului, latura_campului,
    y_fata_campului) pentru pictograma, care se pune in relief peste camp."""
    h = side * math.sqrt(3) * 0.5
    plate(b, [(-side / 2, 0.0), (side / 2, 0.0), (0.0, h)], y_face - 0.03, y_face, KERB_RED, x0, z_base)
    # spatele: tabla gri (rost de 2 mm fata de placa rosie, vezi mai jos)
    plate(b, [(-side / 2, 0.0), (side / 2, 0.0), (0.0, h)], y_face - 0.037, y_face - 0.032,
          POST_GREY, x0, z_base)
    si = side - 2.0 * math.sqrt(3) * border
    # straturile NU sunt coplanare (rost de 2 mm): `assign_uvs` ia slotul fetei
    # celei mai apropiate, iar o fata lipita de alta ii fura culoarea
    plate(b, [(-si / 2, border), (si / 2, border), (0.0, border + si * math.sqrt(3) * 0.5)],
          y_face + 0.002, y_face + 0.007, FOAM_WHITE, x0, z_base)
    return z_base + border, si, y_face + 0.009


def emit_nodes(nodes, path, ao=AO_PROP, smooth_angle=None):
    """Noduri cu pivot propriu: fiecare obiect e construit cu baza lui la origine
    si se muta in pozitie prin `location` (translatia nodului in GLB), ca
    integrarea sa-l poata muta separat. Scala/rotatia raman 1/0."""
    total, per_node, out = 0, {}, []
    for obj, loc in nodes:
        st = finish(obj, bevel=0.0, ao=ao, origin=None, smooth_angle=smooth_angle)
        total += st["tris"]
        per_node[obj.name] = st["tris"]
        obj.location = Vector(loc)
        out.append(obj)
    bpy.context.view_layer.update()
    lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
    for o in out:
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            lo = Vector((min(lo[i], p[i]) for i in range(3)))
            hi = Vector((max(hi[i], p[i]) for i in range(3)))
    _, sz = export_glb(out, "transfagarasan/" + path)
    TF_RESULTS.append((path, total, hi - lo, per_node, sz / 1024.0))


def stones_at_base(b, r, seed, n=4, h=0.4):
    """Bolovanul de la piciorul unui stalp: unul mare (inalt `h`) + n-1 mici."""
    import random
    rr = random.Random(seed)
    faceted_block(b, (0.0, 0.0, 0.0), (r * 2.0, r * 1.7, h), MARBLE_GREY, seed=seed, jag=0.35)
    for i in range(n - 1):
        a = rr.random() * math.tau
        d = r * (0.9 + 0.4 * rr.random())
        s = r * (0.45 + 0.35 * rr.random())
        faceted_block(b, (d * math.cos(a), d * math.sin(a), 0.0), (s * 1.5, s * 1.3, s * 0.9),
                      MARBLE_GREY, seed=seed + 11 * (i + 1), jag=0.4)


# --- snow_pole -----------------------------------------------------------------

def build_snow_pole():
    """Stalpul de zapada (`snow_pole`), kit §1.1.

    LISTA DE ELEMENTE (decuparea `snow_pole.png`, INAINTE de geometrie):
      1) un stalp subtire, drept, cu DUNGI alternante rosu-alb: de sus rosu,
         alb, rosu, alb, rosu (5 dungi egale pe partea vizibila)
      2) la baza un MORMAN de 3-4 pietre gri (unul mare + mici), cu putin verde
      3) h/l foarte mare (stalp)
    Corecturi: fara verde pe pietre (fara vegetatie lipita). Cote din tabel:
    2,5 m, diametru 0,08 m (`segments` 8), bolovan de 0,4 m.
    Noduri: `Pole_Paint_Red` (KERB_RED, 3 dungi), `Pole_Paint_White` (FOAM_WHITE,
    2 dungi), `Pole_Stone` (MARBLE_GREY). Origine la baza stalpului."""
    red, white, stone = Builder(), Builder(), Builder()
    z_vis, z_top, r = 0.35, 2.5, 0.04
    seg = (z_top - z_vis) / 5.0
    for i in range(5):
        za = z_top - (i + 1) * seg
        zb = z_top - i * seg
        if i == 4:
            za = 0.05           # ultima dunga coboara in bolovan
        bb = red if i % 2 == 0 else white
        bb.cylinder((0.0, 0.0, (za + zb) * 0.5), r, zb - za, KERB_RED if i % 2 == 0 else FOAM_WHITE,
                    segments=8)
    stones_at_base(stone, 0.30, seed=41, n=4, h=0.40)
    return [(Builder.to_object(red, "Pole_Paint_Red"), (0, 0, 0)),
            (Builder.to_object(white, "Pole_Paint_White"), (0, 0, 0)),
            (Builder.to_object(stone, "Pole_Stone"), (0, 0, 0))]


# --- road_works ----------------------------------------------------------------

def _cone(b):
    b.box((0.0, 0.0, 0.02), (0.38, 0.38, 0.04), LAVA_ORANGE)
    b.frustum((0.0, 0.0, 0.04 + 0.355), 0.15, 0.025, 0.71, LAVA_ORANGE, segments=10)
    # doua benzi albe (frustum putin mai lat peste con)
    for t0, t1 in ((0.30, 0.42), (0.58, 0.68)):
        ra = 0.15 + (0.025 - 0.15) * t0 + 0.006
        rb = 0.15 + (0.025 - 0.15) * t1 + 0.006
        b.frustum((0.0, 0.0, 0.04 + 0.71 * (t0 + t1) * 0.5), ra, rb, 0.71 * (t1 - t0), FOAM_WHITE, segments=10)


def _worker_pictogram(b, t0, si, yf, oz):
    """Omul cu lopata, in relief de 1,5 cm, negru, pe campul alb; (u, t) de la
    baza campului, in coordonatele PRIVITORULUI (din fata, dreapta privitorului
    e -X, deci u se oglindeste): aplecat spre dreapta, lopata infipta in
    gramada din dreapta, ca pe decupare."""
    y0, y1 = yf, yf + 0.015
    k = si / 0.623
    P = lambda u, t: (-u * k, t * k)
    BK = VOLCANIC_BLACK
    plate(b, disk2(P(0.045, 0.30), 0.04 * k, 10), y0, y1, BK, 0.0, oz)          # capul
    plate(b, seg2(P(-0.07, 0.13), P(0.0, 0.235), 0.075 * k), y0, y1, BK, 0.0, oz)  # trunchiul aplecat
    plate(b, seg2(P(-0.07, 0.14), P(-0.13, 0.03), 0.05 * k), y0, y1, BK, 0.0, oz)  # piciorul din spate
    plate(b, seg2(P(-0.07, 0.14), P(-0.01, 0.03), 0.05 * k), y0, y1, BK, 0.0, oz)  # piciorul din fata
    plate(b, seg2(P(0.0, 0.225), P(0.075, 0.15), 0.04 * k), y0, y1, BK, 0.0, oz)   # bratul
    plate(b, seg2(P(-0.03, 0.245), P(0.125, 0.075), 0.022 * k), y0, y1, BK, 0.0, oz)  # coada lopetii
    plate(b, [P(0.105, 0.045), P(0.165, 0.03), P(0.17, 0.085), P(0.125, 0.10)], y0, y1, BK, 0.0, oz)
    pile = [P(0.15 + 0.095 * math.cos(math.pi * i / 8), 0.012 + 0.07 * math.sin(math.pi * i / 8))
            for i in range(9)]
    plate(b, pile, y0, y1, BK, 0.0, oz)                                           # gramada


def build_road_works():
    """Recuzita santierului din tunel (`road_works`), kit §1.1.

    LISTA DE ELEMENTE (decuparea `road_works.png`, INAINTE de geometrie):
      1) 3 conuri portocaliu-rosii, fiecare cu 2 BENZI albe (cea de sus mai
         ingusta) si talpa patrata
      2) o BARIERA: scandura lata cu DUNGI DIAGONALE rosu-alb (capetele albe),
         pe 2 CAPRE in A, gri inchis
      3) un SEMN triunghiular cu chenar rosu, camp alb, pictograma OMULUI CU
         LOPATA (aplecat, gramada in dreapta), pe 2 stalpi gri cu talpi
      4) fara text, fara semafor
    Tabelul cere 4 conuri (decuparea are 3): urmez tabelul. Cote: grup pe 6 x 2 m,
    conuri 0,75 m, bariera 3 m x 1,1 m, semnul (latura 1,2 m, ca semnul cu ursul;
    tabelul nu o da) cu varful la 2,4 m, pe doi stalpi ca pe decupare. Fiecare element e NOD SEPARAT cu pivotul la baza lui:
    `Works_Cone_1..4`, `Works_Barrier`, `Works_Sign`. Fata spre +Y."""
    nodes = []
    # vazut din fata (+Y), +X e in STANGA: semnul la -X iese in dreapta, ca pe decupare
    for i, (x, y) in enumerate(((2.55, 0.65), (1.0, 0.75), (-0.55, 0.6), (-1.75, 0.8))):
        c = Builder()
        _cone(c)
        nodes.append((Builder.to_object(c, "Works_Cone_%d" % (i + 1)), (x, y, 0.0)))

    bar = Builder()
    zb, zt, hl = 0.82, 1.10, 1.5
    k = 0
    u = -hl - 0.3
    while u < hl:
        poly = clip_x([(u, zb), (u + 0.3, zb), (u + 0.58, zt), (u + 0.28, zt)], -hl + 0.12, hl - 0.12)
        if len(poly) >= 3:
            plate(bar, poly, -0.025, 0.025, KERB_RED if k % 2 == 0 else FOAM_WHITE)
        u += 0.3
        k += 1
    for sx in (-1, 1):   # capetele albe
        plate(bar, [(sx * (hl - 0.12), zb), (sx * hl, zb), (sx * hl, zt), (sx * (hl - 0.12), zt)],
              -0.025, 0.025, FOAM_WHITE)
    for x in (-1.05, 1.05):        # caprele in A (picioarele desfacute pe Y)
        for sy in (-1, 1):
            bar.beam((x, sy * 0.32, 0.0), (x, sy * 0.04, zb), 0.06, POST_GREY)
        bar.beam((x, -0.22, 0.30), (x, 0.22, 0.30), 0.04, POST_GREY)
        bar.box((x, 0.0, zb - 0.03), (0.08, 0.12, 0.06), POST_GREY)
    nodes.append((Builder.to_object(bar, "Works_Barrier"), (1.0, -0.45, 0.0)))

    sg = Builder()
    side, border = 1.2, 0.10
    zs = 2.4 - side * math.sqrt(3) * 0.5     # varful triunghiului la 2,4 m
    post_top = zs + 0.45          # stalpii se opresc la jumatatea triunghiului
    for x in (-0.22, 0.22):
        sg.box((x, -0.04, post_top * 0.5), (0.06, 0.06, post_top), POST_GREY)
        sg.box((x, -0.04, 0.03), (0.22, 0.34, 0.06), POST_GREY)
    t0, si, yf = warning_triangle(sg, side, border, zs, 0.0)
    _worker_pictogram(sg, t0, si, yf, t0)
    nodes.append((Builder.to_object(sg, "Works_Sign"), (-2.3, -0.5, 0.0)))
    return nodes


# --- level_crossing ------------------------------------------------------------

def _crossing_post(b, lamp):
    """Stalpul cu crucea Sf. Andrei (2,8 m) si placa lampilor; lentilele in `lamp`."""
    b.box((0.0, 0.0, 0.04), (0.5, 0.5, 0.08), CONCRETE)
    b.box((0.0, 0.0, 1.4), (0.12, 0.12, 2.8 - 0.25), POST_GREY)
    zc = 2.8 - 0.36
    for ang in (45.0, -45.0):
        rot = Matrix.Rotation(math.radians(ang), 3, "Y")
        b.box((0.0, 0.10, zc), (1.0, 0.03, 0.17), KERB_RED, rotation=rot)
        b.box((0.0, 0.118, zc), (0.84, 0.01, 0.10), FOAM_WHITE, rotation=rot)
    # placa neagra a lampilor sub cruce, doua viziere
    zl = 1.85
    b.box((0.0, 0.08, zl), (0.82, 0.04, 0.38), VOLCANIC_BLACK)
    for x in (-0.22, 0.22):
        b.cylinder((x, 0.13, zl), 0.16, 0.06, VOLCANIC_BLACK, segments=10, axis="Y")
        b.box((x, 0.20, zl + 0.15), (0.32, 0.12, 0.02), VOLCANIC_BLACK)
        lamp.cylinder((x, 0.168, zl), 0.12, 0.02, KERB_RED, segments=10, axis="Y")


def _crossing_gate(b):
    b.box((0.0, 0.0, 0.04), (0.55, 0.5, 0.08), CONCRETE)
    b.box((0.0, 0.0, 0.55), (0.34, 0.30, 0.95), POST_GREY)
    b.box((0.0, 0.0, 1.05), (0.38, 0.34, 0.05), POST_GREY)


def _crossing_boom(b):
    """Bratul in poza RIDICATA: de la balama (originea nodului) in sus pe +Z,
    10 dungi de 0,75 m; contragreutatea scurta sub balama."""
    for i in range(10):
        b.box((0.0, 0.0, 0.10 + 0.75 * (i + 0.5)), (0.16, 0.10, 0.75),
              KERB_RED if i % 2 == 0 else FOAM_WHITE)
    b.box((0.0, 0.0, -0.18), (0.16, 0.12, 0.42), POST_GREY)
    b.cylinder((0.0, -0.07, 0.0), 0.07, 0.06, POST_GREY, segments=8, axis="Y")


def build_level_crossing():
    """Trecerea la nivel (`level_crossing`), kit §1.1.

    LISTA DE ELEMENTE (decuparea `level_crossing.png`, INAINTE de geometrie):
      1) doua ansambluri oglindite, cate unul pe fiecare parte a drumului
      2) fiecare: un STALP gri pe soclu, cu CRUCEA SF. ANDREI alb-rosie sus si
         sub ea o placa neagra cu DOUA LAMPI rotunde rosii (aprinse pe desen)
      3) fiecare: o CARCASA gri pe soclu, cu BRATUL BARIEREI dungat rosu-alb
         (~9-10 dungi), ridicat aproape vertical
      4) bratele intre stalpi (stalpii la exterior)
      5) fara text
    Cote din tabel: crucea la 2,8 m, bratul de 7,5 m peste o banda (drumul de
    14 m: bratul coborat ajunge de la balama, |x| 7,6, pana la axa).
    Noduri: `Crossing_Post_L/_R` (stalp + cruce + placa), `Crossing_Lamp_L/_R`
    (doar lentilele, KERB_RED, `segments` 10, ca integrarea sa le aprinda),
    `Crossing_Gate_L/_R` (carcasa), `Crossing_Boom_L/_R` (bratul, ORIGINEA
    NODULUI PE BALAMA, poza ridicata vertical). Coborare: _L se roteste +90
    grade in jurul +Y Blender (= -90 grade in jurul +Z Godot) si cade spre +X;
    _R invers. Origine pe axa drumului, baza la 0, fata spre +Y."""
    nodes = []
    for side, sx in (("L", -1), ("R", 1)):
        post, lamp = Builder(), Builder()
        _crossing_post(post, lamp)
        nodes.append((Builder.to_object(post, "Crossing_Post_" + side), (sx * 9.0, 0.0, 0.0)))
        nodes.append((Builder.to_object(lamp, "Crossing_Lamp_" + side), (sx * 9.0, 0.0, 0.0)))
        gate = Builder()
        _crossing_gate(gate)
        nodes.append((Builder.to_object(gate, "Crossing_Gate_" + side), (sx * 7.85, 0.0, 0.0)))
        boom = Builder()
        _crossing_boom(boom)
        nodes.append((Builder.to_object(boom, "Crossing_Boom_" + side), (sx * 7.6, 0.24, 0.92)))
    return nodes


# --- bear_warning_sign ---------------------------------------------------------

BEAR_2D = [(-0.17, 0.0), (-0.11, 0.0), (-0.10, 0.065), (0.06, 0.065), (0.07, 0.0), (0.125, 0.0),
           (0.135, 0.09), (0.17, 0.115), (0.225, 0.12), (0.235, 0.145), (0.195, 0.17),
           (0.18, 0.195), (0.16, 0.182), (0.12, 0.178), (0.02, 0.21), (-0.12, 0.188),
           (-0.19, 0.15), (-0.205, 0.08)]


def build_bear_warning_sign():
    """Semnul „nu hraniti ursii” (`bear_warning_sign`), kit §1.1.

    LISTA DE ELEMENTE (decuparea `bear_warning_sign.png`, INAINTE de geometrie;
    fasiile din piesele vecine de la margini se ignora):
      1) TRIUNGHI cu varful in sus, chenar ROSU lat, colturi usor rotunjite, camp alb
      2) pictograma: URSUL negru din profil, mergand spre stanga, cocoasa pe umeri
      3) STALP gri subtire sub triunghi
      4) la baza un MORMAN de pietre gri (unul mare + 4-5 mici), cu putin verde
    CORECTURA coordonatorului: pictograma e „NU HRANITI URSII”: ursul + o MANA
    cu mancare, taiate de BARA ROSIE (2 se completeaza); fara text; fara verde
    pe pietre (fara vegetatie lipita). Lista urmeaza corectura:
      a) triunghi cu latura 1,2 m, chenar KERB_RED de 0,1 m (placa de 3 cm),
         camp FOAM_WHITE iesit 5 mm
      b) ursul (VOLCANIC_BLACK, relief 1,5 cm), intors spre DREAPTA, spre mana
      c) mana cu un mar (antebrat, palma, degetul mare, marul rotund), dreapta-jos
      d) BARA ROSIE diagonala, stanga-sus -> dreapta-jos, peste pictograma (2 cm)
      e) stalp de 2,4 m (ASPHALT_EDGE), bolovan de ~0,35 m la baza
    Noduri: `BearSign_Plate` (rosu / alb / negru), `BearSign_Post`,
    `BearSign_Stone` (MARBLE_GREY). Origine la baza stalpului, fata spre +Y."""
    pl, post, stone = Builder(), Builder(), Builder()
    side, border, zs = 1.2, 0.10, 1.45
    post.box((0.0, -0.04, 1.25), (0.07, 0.07, 2.4), POST_GREY)
    t0, si, yf = warning_triangle(pl, side, border, zs, 0.0)
    y0, y1 = yf, yf + 0.015
    plate(pl, [(u - 0.06, t + 0.07) for u, t in BEAR_2D], y0, y1, VOLCANIC_BLACK, 0.0, t0)
    plate(pl, seg2((0.36, 0.02), (0.265, 0.085), 0.055), y0, y1, VOLCANIC_BLACK, 0.0, t0)   # antebratul
    plate(pl, [(0.215, 0.085), (0.29, 0.07), (0.30, 0.105), (0.225, 0.118)], y0, y1, VOLCANIC_BLACK, 0.0, t0)
    plate(pl, seg2((0.22, 0.10), (0.205, 0.135), 0.02), y0, y1, VOLCANIC_BLACK, 0.0, t0)    # degetul mare
    plate(pl, disk2((0.245, 0.158), 0.034, 10), y0, y1, VOLCANIC_BLACK, 0.0, t0)           # marul
    plate(pl, seg2((-0.21, 0.335), (0.30, 0.005), 0.055), yf + 0.017, yf + 0.025, KERB_RED, 0.0, t0)
    stones_at_base(stone, 0.26, seed=73, n=5, h=0.35)
    return [(Builder.to_object(pl, "BearSign_Plate"), (0, 0, 0)),
            (Builder.to_object(post, "BearSign_Post"), (0, 0, 0)),
            (Builder.to_object(stone, "BearSign_Stone"), (0, 0, 0))]


ONLY = os.environ.get("TF_ONLY", "")


def _want(name):
    """Si curata scena inainte de fiecare piesa: altfel doua piese cu acelasi nume
    de nod (`Wall_Stone` la zidul drept si la cel curb) ies `Wall_Stone.001` in
    al doilea GLB, iar Godot cauta nodurile dupa nume."""
    if ONLY and ONLY != name:
        return False
    clear_built()
    for o in list(bpy.data.objects):
        if o.type == "EMPTY":
            bpy.data.objects.remove(o, do_unlink=True)
    return True


if _want("tunnel_portal_balea"):
    objs = build_tunnel_portal_balea()
    emit_tf(objs, "structures/tunnel_portal_balea.glb", AO_PORTAL, keep_xy=True,
            bevel=0.0, smooth_angle=None)

if _want("rock_tunnel_portal"):
    emit_tf(build_rock_tunnel_portal(), "structures/rock_tunnel_portal.glb", AO_ROCK,
            keep_xy=True, bevel=0.0, smooth_angle=None)

if _want("retaining_wall_straight"):
    emit_rim(build_retaining_wall(False), "structures/retaining_wall_straight.glb", AO_WALL)

if _want("retaining_wall_curve"):
    emit_rim(build_retaining_wall(True), "structures/retaining_wall_curve.glb", AO_WALL)

for _n, _f in (("snow_pole", build_snow_pole), ("road_works", build_road_works),
               ("level_crossing", build_level_crossing),
               ("bear_warning_sign", build_bear_warning_sign)):
    if _want(_n):
        emit_nodes(_f(), "props/%s.glb" % _n)

if _want("snow_wall"):
    emit_tf_variants(build_snow_wall(), "structures/snow_wall.glb")

report_tf()
