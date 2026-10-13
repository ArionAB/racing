"""Transfagarasan -- barajul si reperele (brief docs/asset_briefs/transfagarasan_kit.md §1.2).

  transfagarasan/structures/vidraru_dam.glb       barajul: Dam_Module / Dam_Tower / Dam_PowerHouse
  transfagarasan/buildings/poenari_ruin.glb       ruina pe stanca de sist
  transfagarasan/props/prometheus_statue.glb      Prometeu pe soclul de stanca

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_tf_landmarks.py
Variabila de mediu TF_ONLY=<piesa> reface doar piesa respectiva.

Axe ca in tot kitul: X latime (dreapta), Y adancime (+Y Blender = -Z Godot =
"inainte"), Z sus. Fara text, cifre sau logo-uri (regula 9). Brief §8: fara
Dracula -- fara turle, tepi, lilieci, steaguri, acoperisuri pe ruina.
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "transfagarasan_shapes.py")).read())
exec(open(os.path.join(_here, "tf_shapes_nature.py")).read())

clear_built()


def emit_roots(roots, path, smooth_angle=35.0):
    """GLB cu mai multe noduri-radacina: fiecare radacina e un Empty la origine
    (scala 1, rotatie 0) cu nodurile ei de un singur material drept copii.
    NIMIC nu se muta: piesele sunt construite deja fata de originea ceruta
    (la baraj: cota drumului, pe axa). `roots` = lista (nume, [(obj, bevel)], ao)."""
    out, total, per_node = [], 0, {}
    lo = Vector((1e9,) * 3)
    hi = Vector((-1e9,) * 3)
    for root, items, ao in roots:
        emp = bpy.data.objects.new(root, None)
        bpy.context.collection.objects.link(emp)
        out.append(emp)
        for o, bw in items:
            if o is None or len(o.data.vertices) == 0:
                continue
            st = finish(o, bevel=bw, bevel_angle=30.0, ao=ao, origin=None,
                        smooth_angle=smooth_angle)
            total += st["tris"]
            per_node[o.name] = st["tris"]
            o.parent = emp
            for v in o.data.vertices:
                lo = Vector((min(lo[i], v.co[i]) for i in range(3)))
                hi = Vector((max(hi[i], v.co[i]) for i in range(3)))
            out.append(o)
    _, sz = export_glb(out, "transfagarasan/" + path)
    TF_RESULTS.append((path, total, hi - lo, per_node, sz / 1024.0))
    print("%s: bbox X %.2f..%.2f  Y %.2f..%.2f  Z %.2f..%.2f" % (
        path, lo.x, hi.x, lo.y, hi.y, lo.z, hi.z))
    return total


# ---------------------------------------------------------------------------
# vidraru_dam
# ---------------------------------------------------------------------------

DAM_L = 16.0          # modulul pe Y
DAM_H = 40.0          # coronament -> piciorul din aval
DECK_Z = -0.08        # fata de sus a coronamentului (asfaltul din cod e la 0)
CORN_Z = -2.2         # buza de jos a cornisei coronamentului (banda de ~2,1 m)
GROOVE = 0.15         # rostul vertical: 0,15 pe fiecare capat = 0,30 intre module
FLARE_TOP = -25.0     # de aici fata din aval se largeste (ultimii 15 m)
FLARE_W = 9.0
STEPS = (-8.0, -15.0, -22.0)     # cele 3 benzi de cofraj (trepte de 5 cm)
FACE_X = 6.4          # fata panoului, sub cornisa (cornisa iese 0,6 m, pana la 7,0)
AO_DAM = dict(samples=20, dist=3.0, gradient="vertical", low=0.58, high=1.0,
              power=0.8, floor=0.32, z_range=(-DAM_H, 8.0))


def dam_face_x(z):
    """Fata panoului din aval (x) la cota z: verticala sus, 3 trepte de 5 cm
    (iesite in jos), apoi CONCAVA in ultimii 15 m (x creste cu patratul)."""
    x = FACE_X + 0.05 * sum(1 for s in STEPS if z < s - 1e-9)
    if z < FLARE_TOP:
        t = (FLARE_TOP - z) / (DAM_H + FLARE_TOP)
        x += FLARE_W * t * t
    return x


def dam_face_profile(off=0.0, z_top=CORN_Z):
    """Punctele (x, z) ale fetei din aval de JOS in SUS, decalate cu `off` pe X."""
    pts = []
    n = 12
    for i in range(n + 1):           # zona concava, de la baza la FLARE_TOP
        z = -DAM_H + (DAM_H + FLARE_TOP) * i / n
        pts.append((dam_face_x(z) + off, z))
    for s in sorted(STEPS):          # treptele: doua puncte la aceeasi cota
        pts.append((dam_face_x(s - 1e-6) + off, s))
        pts.append((dam_face_x(s + 1e-6) + off, s))
    pts.append((dam_face_x(z_top) + off, z_top))
    return pts


def build_vidraru_dam():
    """Barajul Vidraru (`vidraru_dam`), kit §1.2.

    LISTA DE ELEMENTE (decuparea `transfagarasan_assets_v1/vidraru_dam.png`,
    scrisa INAINTE de geometrie):
      1) un ZID lung de beton bej-gri, plin, fara ferestre, vazut pe fata din
         aval; la capatul din stanga se vede o usoara largire la baza
      2) ROSTURI verticale: fata e impartita in ~7 PANOURI egale (ploturile),
         cu caneluri inguste intre ele
      3) CORNISA coronamentului: o banda continua iesita in afara fetei, ~1/12
         din inaltimea zidului, sub parapet
      4) PARAPETUL: jos, deschis la culoare, cu DUNGI ROSII scurte, distantate
         (~6 vizibile pe lungime)
      5) drumul inchis la culoare pe coronament (NU intra: asfaltul e din cod)
      6) TURNUL la capatul din dreapta: masiv, ridicat ~1/4 din inaltimea
         zidului peste coronament, cu 3 ferestre sus si o cornisa-capac
      7) un pilastru gros la capatul din stanga, cu ceva mic pe el (abutment;
         NU intra: modulul e repetabil, capetele barajului le da terenul)
    CORECTURI (kit, suprascriu decuparea):
      * coronamentul DREPT in plan (decuparea are o curba usoara in plan):
        arcul se citeste pe VERTICALA -- fata din aval verticala sus, CONCAVA
        in ultimii 15 m (se largeste cu 9 m spre baza);
      * rosturile: o caneluri de 0,15 m la FIECARE capat al modulului (0,30 m
        intre doua module), nu 7 panouri intr-o piesa: un modul = un plot;
      * 3 benzi orizontale de cofraj, trepte de 5 cm (la -8 / -15 / -22 m);
      * parapetul ca pe serpentine: blocuri de 4 m alternand beton / rosu
        (`KERB_RED`), 1,1 m, pe 6,25 <= |x| <= 7,0, ambele parti;
      * turnul de priza e pe partea LACULUI (-X), CILINDRU (12 segmente) cu
        cabina vanelor sus si ferestre, +8 m peste coronament, legat cu o
        pasarela de 6 m de coronament (nu e lipit de capatul zidului);
      * centrala de la picior (nu e pe decupare; din diorama): cutie de beton
        14 x 9 x 8 m, ferestre inalte, iesirea apei ca gol negru la baza.
    Cote (tabel): modul 16 m pe Y, coronament 14 m (|x| <= 7), 40 m pe aval,
    9 m vizibili pe amonte (fundul lacului la -9 m; fata de amonte coboara si
    sub el, ingropata in teren). Originea FIECARUI nod la cota drumului, pe axa;
    totul atarna sub Y = 0 (in afara parapetului si a turnului); nimic peste
    -0,05 in |x| <= 6,0 (coronamentul e la -0,08).
    Noduri: Dam_Module -> Dam_Module_Concrete (CONCRETE 8), Dam_Rail
    (KERB_RED 7); Dam_Tower -> Dam_Tower_Concrete, Dam_Tower_Void
    (VOLCANIC_BLACK 20); Dam_PowerHouse -> Dam_PowerHouse_Concrete,
    Dam_PowerHouse_Void.
    """
    h = DAM_L * 0.5
    # --- modulul: corpul (sectiunea trasa pe Y, fata din aval retrasa cu GROOVE)
    body = Builder()
    sec = [(-7.0, -DAM_H)]
    sec += dam_face_profile(off=-GROOVE)
    sec += [(7.0, CORN_Z), (7.0, DECK_Z), (-7.0, DECK_Z)]
    extrude_xz(body, sec, -h, h, TF_CONCRETE)
    # panoul plotului: fata reala din aval, intre rosturile de la capete;
    # intra 2 cm in corp si in cornisa (fara fete coplanare)
    front = dam_face_profile(off=0.0, z_top=CORN_Z + 0.02)
    back = list(reversed(dam_face_profile(off=-GROOVE - 0.02, z_top=CORN_Z + 0.02)))
    extrude_xz(body, front + back, -h + GROOVE, h - GROOVE, TF_CONCRETE)
    # parapetul: 4 blocuri de 4 m pe fiecare parte, beton / rosu alternativ
    rail = Builder()
    for sx in (-1.0, 1.0):
        for k in range(4):
            y0 = -h + 4.0 * k + 0.02
            bb = rail if k % 2 == 1 else body
            slot = KERB_RED if k % 2 == 1 else TF_CONCRETE
            bb.box((sx * 6.625, y0 + 1.98, (DECK_Z + 1.1) * 0.5 + 0.0),
                   (0.75, 3.96, 1.1 - DECK_Z), slot)
    module = [(Builder.to_object(body, "Dam_Module_Concrete"), 0.05),
              (Builder.to_object(rail, "Dam_Rail"), 0.03)]

    # --- turnul de priza, pe partea lacului (-X), legat cu pasarela
    tw, tv = Builder(), Builder()
    TX = -16.3
    tw.cylinder((TX, 0.0, -5.3), 2.5, 9.4, TF_CONCRETE, segments=12)        # putul, -10 .. -0,6
    tw.cylinder((TX, 0.0, -0.35), 3.1, 0.5, TF_CONCRETE, segments=12)       # galeria
    tw.cylinder((TX, 0.0, 2.5), 2.8, 5.4, TF_CONCRETE, segments=12)         # cabina vanelor -0,2 .. 5,2
    tw.cylinder((TX, 0.0, 5.5), 3.3, 0.6, TF_CONCRETE, segments=12)         # placa acoperisului
    tw.cylinder((TX, 0.0, 6.6), 1.9, 1.6, TF_CONCRETE, segments=12)         # casa troliului
    tw.cylinder((TX, 0.0, 7.7), 2.2, 0.6, TF_CONCRETE, segments=12)         # capacul, pana la +8
    # ferestrele cabinei: pe 6 fatete din 12 (fatetele cilindrului sunt plane),
    # 2 cm in fata fatetei; usa spre pasarela (+X)
    apo = 2.8 * math.cos(math.pi / 12)
    for i in range(12):
        a = 2 * math.pi * (i + 0.5) / 12.0     # mijlocul fatetei i
        if i % 2:
            continue
        rot = Matrix.Rotation(a, 3, "Z")
        c = Vector((TX, 0.0, 0.0)) + rot @ Vector((apo + 0.01, 0.0, 3.1))
        tv.box(tuple(c), (0.06, 0.95, 2.2), TF_VOID, rotation=rot)
    # usa: fateta 0 si 11 incadreaza +X; pun usa pe directia exacta +X
    tv.box((TX + 2.8 + 0.02, 0.0, 1.0), (0.06, 1.2, 2.1), TF_VOID)
    # ferestrele casei troliului: 4 fante
    apo2 = 1.9 * math.cos(math.pi / 12)
    for i in (1, 4, 7, 10):
        a = 2 * math.pi * (i + 0.5) / 12.0
        rot = Matrix.Rotation(a, 3, "Z")
        c = Vector((TX, 0.0, 0.0)) + rot @ Vector((apo2 + 0.01, 0.0, 6.6))
        tv.box(tuple(c), (0.06, 0.7, 0.9), TF_VOID, rotation=rot)
    # pasarela: de la cabina (x = TX + 2,8) pana la fata exterioara a parapetului
    x0, x1 = TX + 2.7, -7.0
    tw.box(((x0 + x1) * 0.5, 0.0, DECK_Z - 0.35), (x1 - x0, 2.4, 0.7), TF_CONCRETE)
    for sy in (-1.0, 1.0):
        tw.box(((x0 + x1) * 0.5, sy * 1.12, DECK_Z + 0.5), (x1 - x0, 0.16, 1.0), TF_CONCRETE)
    # consola pasarelei: o grinda sub ea, spre put
    tw.beam((TX + 2.4, 0.0, -3.0), (x1 - 0.3, 0.0, DECK_Z - 0.7), (0.7, 1.4), TF_CONCRETE)
    tower = [(Builder.to_object(tw, "Dam_Tower_Concrete"), 0.05),
             (Builder.to_object(tv, "Dam_Tower_Void"), 0.0)]

    # --- centrala de la picior, pe partea haului (+X)
    ph, pv = Builder(), Builder()
    X0, X1, Z0, Z1 = 16.2, 25.2, -DAM_H, -DAM_H + 8.0
    YH = 7.0
    ph.box(((X0 + X1) * 0.5, 0.0, (Z0 + Z1) * 0.5), (X1 - X0, 2 * YH, Z1 - Z0), TF_CONCRETE)
    ph.box(((X0 + X1) * 0.5 + 0.15, 0.0, Z1 + 0.2), (X1 - X0 + 0.9, 2 * YH + 0.6, 0.4), TF_CONCRETE)
    ph.box(((X0 + X1) * 0.5 + 0.15, 0.0, Z1 + 0.55), (X1 - X0 + 0.5, 2 * YH + 0.2, 0.3), TF_CONCRETE)
    # fata spre vale (+X): 2 iesiri de apa la baza, cu copertina de beton,
    # 5 pilastri si 4 ferestre inalte intre ei
    for y in (-3.6, 3.6):
        pv.box((X1 + 0.02, y, Z0 + 1.15), (0.06, 3.0, 2.3), TF_VOID)
        ph.box((X1 + 0.45, y, Z0 + 2.45), (0.9, 3.8, 0.3), TF_CONCRETE)
    for y in (-6.5, -3.25, 0.0, 3.25, 6.5):
        ph.box((X1 + 0.15, y, (Z0 + 2.6 + Z1) * 0.5), (0.3, 0.55, Z1 - Z0 - 2.6), TF_CONCRETE)
    for y in (-4.875, -1.625, 1.625, 4.875):
        pv.box((X1 + 0.02, y, Z0 + 5.2), (0.06, 1.4, 4.2), TF_VOID)
    # laturile (+-Y): cate 3 ferestre inalte
    for sy in (-1.0, 1.0):
        for x in (18.3, 20.7, 23.1):
            pv.box((x, sy * (YH + 0.02), Z0 + 4.4), (1.2, 0.06, 4.6), TF_VOID)
    power = [(Builder.to_object(ph, "Dam_PowerHouse_Concrete"), 0.05),
             (Builder.to_object(pv, "Dam_PowerHouse_Void"), 0.0)]
    return [("Dam_Module", module, AO_DAM), ("Dam_Tower", tower, AO_DAM),
            ("Dam_PowerHouse", power, AO_DAM)]


ONLY = os.environ.get("TF_ONLY", "")


def _want(name):
    """Curata scena inainte de fiecare piesa (altfel nume `*.001`)."""
    if ONLY and ONLY != name:
        return False
    clear_built()
    for o in list(bpy.data.objects):
        if o.type == "EMPTY":
            bpy.data.objects.remove(o, do_unlink=True)
    return True


if _want("vidraru_dam"):
    emit_roots(build_vidraru_dam(), "structures/vidraru_dam.glb", smooth_angle=None)

report_tf()
