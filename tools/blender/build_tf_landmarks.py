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


# ---------------------------------------------------------------------------
# stanca de sist: trepte + blocuri pe foliatie (vocabularul tf_shapes_nature)
# ---------------------------------------------------------------------------

def _rr(seed):
    return _rnd(seed)          # LCG din tf_shapes_nature (nu consuma random-ul global)


def se_point(a, b, t, p=3.0):
    """Punct pe superelipsa |x/a|^p + |y/b|^p = 1 (dreptunghi rotunjit, convex)."""
    c, s = math.cos(t), math.sin(t)
    x = a * math.copysign(abs(c) ** (2.0 / p), c)
    y = b * math.copysign(abs(s) ** (2.0 / p), s)
    return Vector((x, y))


def se_normal(a, b, t, p=3.0):
    q = se_point(a, b, t, p)
    gx = math.copysign(abs(q.x / a) ** (p - 1), q.x) / a
    gy = math.copysign(abs(q.y / b) ** (p - 1), q.y) / b
    return Vector((gx, gy)).normalized()


def se_ring(a, b, z, n=24, p=3.0, jit=0.0, seed=0, c=(0.0, 0.0)):
    r = _rr(seed)
    out = []
    for i in range(n):
        q = se_point(a, b, 2.0 * math.pi * i / n, p) * (1.0 + jit * (2.0 * r() - 1.0))
        out.append(Vector((q.x + c[0], q.y + c[1], z)))
    return out


def rock_tier(b, bot, top, seed, n=24, p=3.0, jit=0.03, c=(0.0, 0.0), tilt=0.0, tilt_az=0.0,
              p_top=None):
    """O treapta a stancii: invelitoarea convexa intre inelul de jos si cel de
    sus (a, b, z); peretii abrupti, fata de sus PLATA (aici se aseaza iarba /
    zidurile)."""
    pts = se_ring(*bot, n=n, p=p, jit=jit, seed=seed, c=c)
    tp = se_ring(top[0], top[1], top[2], n=n, p=p_top or p, jit=jit * 0.6, seed=seed + 1, c=c)
    for q in tp:              # varful treptei inclinat (fara inele orizontale "de tort")
        q.z += tilt * math.cos(math.atan2(q.y - c[1], q.x - c[0]) - tilt_az)
    return hull(b, pts + tp, TF_SCHIST)


def tier_blocks(b, fr, a, bb, z0, z1, n, seed, dip=35.0, sink=1.2, out=(0.45, 1.1),
                top_clamp=None, top_drop=(0.2, 1.6), p=3.0, thin=None, c=(0.0, 0.0),
                fill=0.86, skip=None):
    """Blocurile de sist de pe peretele unei trepte: `n` mase pe perimetrul
    superelipsei (a, bb), intre z0 si z1, cu ROSTURI verticale intre ele (umbra,
    ca pe planșa). Fata de sus a fiecarui bloc e PLANUL DE FOLIATIE: coboara cu
    `dip` grade pe directia `fr.d` a cadrului -- aceeasi pe toata piesa (kit,
    regula 7), deci pe o latura vezi lamele de sus, pe cealalta capetele lor.
    Fata din afara e usor inclinata (iese mai mult jos), cu o coama la mijloc
    (2-3 fatete mari). `thin(normala)` -> True: blocul iese doar 0,15 m."""
    r = _rr(seed)
    k = math.tan(math.radians(dip))
    per = 0.0
    prev = se_point(a, bb, 0.0, p)
    for i in range(1, 97):
        q = se_point(a, bb, 2.0 * math.pi * i / 96, p)
        per += (q - prev).length
        prev = q
    faces = []
    for i in range(n):
        t = 2.0 * math.pi * (i + 0.5 + 0.25 * (r() - 0.5)) / n
        if skip and skip(t):
            for _ in range(14):
                r()
            continue
        P2 = se_point(a, bb, t, p) + Vector(c)
        N2 = se_normal(a, bb, t, p)
        T2 = Vector((-N2.y, N2.x))
        w = per / n * fill * (0.8 + 0.3 * r())
        d_out = out[0] + (out[1] - out[0]) * r()
        if thin and thin(N2):
            d_out = 0.15
        ztop = z1 - (top_drop[0] + (top_drop[1] - top_drop[0]) * r())
        pts = []
        for sw in (-0.5, 0.5):
            for dd, zz in ((-sink, None), (d_out, None)):
                Q = P2 + T2 * (sw * w * (0.92 + 0.08 * r())) + N2 * dd
                zb = max(0.0, z0 - 0.15)
                zt = ztop + k * ((Q - P2).dot(fr.d.to_2d()))
                if top_clamp is not None:
                    zt = min(zt, top_clamp)
                zt = max(zt, z0 + 0.8)
                ins = 0.4 * d_out if dd > 0 else 0.0      # fata din afara: mai retrasa sus
                Qt = Q - N2 * ins
                pts.append((Q.x, Q.y, zb))
                pts.append((Qt.x, Qt.y, zt))
        # coama: fata din afara are o muchie verticala la mijloc
        R = P2 + T2 * ((r() - 0.5) * w * 0.3) + N2 * (d_out + 0.18)
        zm = z0 + (ztop - z0) * (0.35 + 0.3 * r())
        pts.append((R.x, R.y, zm))
        faces += hull(b, pts, TF_SCHIST)
    return faces


def grass_ledge(g, a_in, b_in, a_out, b_out, z, n, seed, frac=0.6, p=3.0, c=(0.0, 0.0),
                slot=TROPICAL_GREEN, th=0.14):
    """Petice de iarba / muschi pe o treapta: `n` bucati scurte de inel (fiecare
    convexa) intre superelipsa interioara si cea exterioara, groase `th`, cu
    fata de sus la z + th (3 cm peste stanca: fara fete coplanare)."""
    r = _rr(seed)
    for i in range(n):
        t0 = 2.0 * math.pi * (i + 0.5 * r()) / n
        t1 = t0 + 2.0 * math.pi / n * frac * (0.6 + 0.6 * r())
        pts = []
        for t in (t0, (t0 + t1) * 0.5, t1):
            for (aa, bb_, kk) in ((a_in, b_in, 0.0), (a_out, b_out, 1.0)):
                q = se_point(aa, bb_, t, p) * (1.0 - 0.04 * kk * r()) + Vector(c)
                pts.append((q.x, q.y, z - 0.25))
                pts.append((q.x, q.y, z + 0.03 + th * (0.6 + 0.4 * r())))
        hull(g, pts, slot)


# ---------------------------------------------------------------------------
# poenari_ruin
# ---------------------------------------------------------------------------

PZ = 18.0            # platoul stancii (baza zidurilor)
AO_POENARI = dict(samples=20, dist=2.6, gradient="vertical", low=0.58, high=1.0,
                  power=0.8, floor=0.30, z_range=(0.0, 28.0))


def _wall_piece(br, st, p0, p1, thick, z_base, h, stone_h, seed, crenel=False,
                window=None, jag=0.35):
    """Bucata de zid intre p0 si p1 (centrul zidului, 2D), de la z_base pana la
    PZ + h: talpa de PIATRA (pana la PZ + stone_h, iese 0,12 m pe fiecare parte)
    si CARAMIDA deasupra, cu fata de sus rupta (colturile la cote diferite, +-
    `jag`). `window` = (u0, u1, sill, lintel) -> gol real in caramida.
    `crenel` -> creneluri (merloni de 0,8 m cu goluri de 0,6) pe creasta."""
    r = _rr(seed)
    p0, p1 = Vector(p0), Vector(p1)
    d = (p1 - p0)
    L = d.length
    d.normalize()
    nrm = Vector((-d.y, d.x))
    hs = min(h, stone_h)
    ht = PZ + h

    def slab(u0, u1, za, zb, b_, slot, widen=0.0, tops=None):
        pts = []
        for u in (u0, u1):
            for s in (-1.0, 1.0):
                q = p0 + d * u + nrm * (s * (thick * 0.5 + widen))
                pts.append((q.x, q.y, za))
                zt = zb if tops is None else tops[(0 if u == u0 else 1) * 2 + (0 if s < 0 else 1)]
                pts.append((q.x, q.y, zt))
        return hull(b_, pts, slot)

    if stone_h > 0.0:
        slab(0.0, L, z_base, PZ + hs, st, MARBLE_GREY, widen=0.02)
        if h <= stone_h + 0.05:
            return
        zb = PZ + hs - 0.02
    else:
        zb = z_base               # caramida porneste direct din stanca (ingropata)
    tops = [ht - jag * r() for _ in range(4)]
    if window:
        u0, u1, sill, lintel = window
        u0, u1 = u0 * L, u1 * L
        slab(0.0, u0, zb, ht, br, TILE_TERRACOTTA, tops=[tops[0], tops[1], ht, ht])
        slab(u1, L, zb, ht, br, TILE_TERRACOTTA, tops=[ht, ht, tops[2], tops[3]])
        slab(u0, u1, zb, PZ + sill, br, TILE_TERRACOTTA)
        if PZ + lintel < ht - 0.3:
            slab(u0, u1, PZ + lintel, ht, br, TILE_TERRACOTTA)
    else:
        slab(0.0, L, zb, ht, br, TILE_TERRACOTTA, tops=tops)
    if crenel:
        u = 0.25
        while u + 0.8 <= L - 0.2:
            slab(u, u + 0.8, ht - 0.1, ht + 0.9, br, TILE_TERRACOTTA, widen=-0.05)
            u += 1.4


def build_poenari_ruin():
    """Cetatea Poenari, RUINA (`poenari_ruin`), kit §1.2; brief §8: fara Dracula.

    LISTA DE ELEMENTE (decuparea `transfagarasan_assets_v1/poenari_ruin.png`,
    scrisa INAINTE de geometrie; fasia de zapada din piesa vecina, la dreapta,
    se ignora):
      1) STANCA: movila masiva gri, mai lata decat inalta, ~2/3 din inaltimea
         totala, pereti abrupti din ~12-16 BLOCURI MARI unghiulare, cu fete
         plane si fisuri verticale inchise intre ele; 2 praguri (trepte)
         vizibile pe flanc
      2) MUSCHI si IARBA verde pe umerii stancii, pe trepte si pe creștet (pete
         mari, nu fire)
      3) creștetul plat, pe care sta ruina
      4) RUINA de CARAMIDA (terracotta): incinta dreptunghiulara alungita,
         ziduri RUPTE la inaltimi diferite, cu muchii in trepte
      5) un TURN inalt (~1,5 x zidurile) in spate-stanga, gol pe dinauntru, cu
         2-3 ferestre, varful rupt
      6) al doilea turn in dreapta (pe planșa tot rectangular, mai scund)
      7) ~6 FERESTRE (goluri inchise la culoare) in ziduri si turnuri
      8) o banda de PIATRA gri la baza zidurilor, pe alocuri
      9) moloz de caramida in curte; verde pe creasta zidurilor
     10) FARA acoperisuri, turle, steaguri
    CORECTURI (kit, suprascriu decuparea):
      * al doilea turn e SEMICIRCULAR (ca ruina reala), pe latura scurta -X,
        iesit in afara peste marginea stancii; turnul rectangular in coltul
        +X/-Y (spate-stanga in 3/4 din fata);
      * creneluri DOAR pe 2 bucati de zid; brese pana la talpa de piatra;
      * fara verde pe ziduri (corectura "fara vegetatie lipita"); iarba si
        muschiul DOAR pe stanca (treptele si creștetul), ca parte din silueta;
      * pe flancul nevazut (-Y): SCARA in zig-zag, 4 rampe, doar ca forma.
    CONTRACT REVIZUIT (coordonatorul, dupa val 2: stanca citea "tort cu doua
    etaje"; ruina ramane), lista pentru STANCA:
      a) MIEZ CONIC in 3 straturi neregulate: baza 33 x 25 (rotunda, p 2,6),
         creștetul 25 x 15 (dreptunghi rotunjit, p 5: tine incinta), 18 m
      b) 6 MASE (contraforturi) de 6,5-10 m pe flancuri, pana la 7 / 8,5 / 11 /
         13 / 15,5 / 17,4 m; fiecare e o pana in trepte: jos lata, fata din
         afara la ~60 grade, sus o masa mai ingusta la ~72 grade; amprenta
         ajunge la ~36 x 28 m (39,6 x 30,7 cu molozul)
      c) 4 RAVENE intre mase (85 / 35 / 350 / 145 grade), unde se vede miezul
         2-4 m mai in spate; fara blocuri mici in ele
      d) MUCHIA creștetului rupta de 13 blocuri care ies 0,3-1,1 m peste ea;
         iarba: covor RETRAS 0,6 m de la muchie (fara inel), LIMBI care coboara
         8-12 m pe ravene, petice pe varful a 3 mase
      e) talpa zidurilor SUBTIRE si DISCONTINUA (0,3-0,7 m, doar pe jumatate
         din bucati); restul zidurilor porneste direct din stanca, ingropat 0,3 m;
         turnul semicircular sta pe masa de la -X, fara talpa
      f) molozul de la picior ramane (16 lespezi)
    Cote: stanca 18 m, zidurile 10 m peste creștet (turnul), incinta 22 x 12 m.
    Foliatia: cadrul `SchistFrame` la 25 grade, toate blocurile au fata de sus
    pe planul de foliatie -- aceeasi directie pe toata stanca.
    Noduri: Poenari_Schist (MARBLE_GREY 29), Poenari_Brick (TILE_TERRACOTTA 23),
    Poenari_Stone (MARBLE_GREY 29: talpa zidurilor, scara, moloz de piatra),
    Poenari_Grass (TROPICAL_GREEN 21)."""
    sch, br, st, gr = Builder(), Builder(), Builder(), Builder()
    fr = SchistFrame((0.0, 0.0, 0.0), 25.0)
    # --- STANCA (contract revizuit, runda 4): MOVILA conica, nu tambur.
    # miezul: 3 straturi neregulate care se strang spre creștet (25 x 15)
    CORE = [((16.5, 12.5, 0.0), (15.0, 10.7, 6.5), 2.6, 0.6),
            ((15.0, 10.6, 6.0), (13.8, 9.1, 12.5), 3.4, 0.0),
            ((13.8, 9.0, 12.0), (12.5, 7.5, PZ), 5.0, 0.0)]
    for k, (bot, top, pp, tl) in enumerate(CORE):
        rock_tier(sch, bot, top, seed=11 + 7 * k, n=16, p=pp, jit=0.04, tilt=tl, tilt_az=2.2)

    def core_pt(t, z):
        """Punct pe fata miezului (fara jitter) la unghiul t si cota z."""
        for (bot, top, pp, _tl) in reversed(CORE):
            if z >= bot[2] or bot[2] == 0.0:
                f = max(0.0, min(1.0, (z - bot[2]) / (top[2] - bot[2])))
                aa = bot[0] + (top[0] - bot[0]) * f
                bb_ = bot[1] + (top[1] - bot[1]) * f
                return se_point(aa, bb_, t, pp)
        return se_point(15.0, 11.0, t, 3.0)

    # contraforturile: 6 mase de 6,5-10 m, pana la cote diferite; intre ele
    # raman 4 RAVENE (unde se vede miezul, 2-4 m mai in spate)
    BUTT = [  # (unghi grade, latime, cota varfului, iesire la baza, iesire sus)
        (110.0, 9.0, 13.0, 0.6, 1.6),
        (62.0, 7.0, 8.5, 0.4, 1.8),
        (8.0, 8.0, 15.5, 0.8, 1.4),
        (180.0, 10.0, 17.4, 1.2, 2.0),
        (215.0, 7.0, 7.0, 0.3, 1.6),
        (330.0, 6.5, 11.0, 0.5, 1.5),
    ]
    RAVINES = (85.0, 35.0, 350.0, 145.0)
    kf = math.tan(math.radians(32.0))      # foliatia pe varful maselor
    rb = _rr(91)
    tops_g = []
    for bi, (ang, w, ht, ob, ot) in enumerate(BUTT):
        t = math.radians(ang)
        N2 = se_normal(18.0, 14.0, t, 3.0)
        T2 = Vector((-N2.y, N2.x))
        base_out = core_pt(t, 0.0) + N2 * (1.6 + ob)
        zk = ht * 0.5                       # cota "genunchiului" (schimbarea de panta)

        def outer_at(zz):
            """Fata din afara: ~60 grade sub genunchi, ~72 peste; niciodata in miez."""
            if zz <= zk:
                o = base_out - N2 * (zz / math.tan(math.radians(60.0)))
            else:
                o = (base_out - N2 * (zk / math.tan(math.radians(60.0)))
                     - N2 * ((zz - zk) / math.tan(math.radians(72.0))))
            cp_ = core_pt(t, zz)
            if (o - cp_).dot(N2) < ot * 0.6:
                o = cp_ + N2 * (ot * 0.6)
            return o
        for part, (z0, z1, wf, sh) in enumerate(((0.0, zk + 0.6, 1.0, 0.0),
                                                 (zk - 0.6, ht, 0.62, 0.2 * (1 if bi % 2 else -1)))):
            pts = []
            for zz, outer_w in ((z0, wf), (z1, wf * 0.8)):
                cp = core_pt(t, zz)
                outer = outer_at(zz)
                inner = cp - N2 * 1.4
                for sw in (-0.5, 0.5):
                    off = T2 * ((sw + sh) * w * outer_w * (0.9 + 0.15 * rb()))
                    for q in (inner + off, outer + off * 0.92):
                        z = zz
                        if zz == z1:
                            z = ht + kf * (off.dot(fr.d.to_2d())) * 0.5 - 0.6 * rb()
                            z = min(z, PZ + 1.3 if bi == 3 else ht + 0.8)
                            z = max(z, z0 + 1.0)
                        pts.append((q.x, q.y, z))
            # coama pe fata din afara (2-3 fatete mari)
            zm = z0 + (z1 - z0) * (0.4 + 0.2 * rb())
            cm = core_pt(t, zm)
            om = outer_at(zm) + N2 * 0.6 + T2 * ((rb() - 0.5) * w * 0.3)
            pts.append((om.x, om.y, zm))
            hull(sch, pts, TF_SCHIST)
            if part == 1:
                tops_g.append((t, w * 0.66, ht, N2, T2, sh, ot))
    # blocuri mai mici pe fata miezului (textura), NU in ravene
    in_rav = lambda t: any(abs(((math.degrees(t) - r_) + 180.0) % 360.0 - 180.0) < 12.0 for r_ in RAVINES)
    thin = lambda N: N.y < -0.6           # flancul scarii: blocuri lipite de perete
    tier_blocks(sch, fr, 15.9, 11.8, 0.0, 6.5, 14, seed=31, top_clamp=7.0, thin=thin,
                out=(0.4, 1.0), top_drop=(0.2, 2.5), skip=in_rav)
    tier_blocks(sch, fr, 14.4, 9.9, 6.0, 12.5, 12, seed=47, top_clamp=13.0, thin=thin,
                out=(0.3, 0.8), top_drop=(0.2, 2.0), p=3.5, skip=in_rav)
    # muchia creștetului RUPTA: blocuri care ies 0,4-1,6 m peste ea, intre
    # ziduri si margine (ruina e ingropata in ele pe alocuri)
    re_ = _rr(29)
    for i in range(13):
        t = 2.0 * math.pi * (i + 0.2 + 0.6 * re_()) / 13
        e = core_pt(t, PZ)
        N2 = se_normal(12.5, 7.5, t, 5.0)
        T2 = Vector((-N2.y, N2.x))
        wb = 2.6 + 1.8 * re_()
        up = 0.3 + 0.8 * re_()
        pts = []
        for sw in (-0.5, 0.5):
            for dd in (-1.1, 0.5 + 0.4 * re_()):
                q = e + T2 * (sw * wb) + N2 * dd
                pts.append((q.x, q.y, PZ - 2.5))
                pts.append((q.x, q.y, PZ + up * (0.6 + 0.4 * re_()) + kf * 0.5 * (T2 * sw * wb).dot(fr.d.to_2d())
                            - (0.5 if dd > 0 else 0.0)))
        hull(sch, pts, TF_SCHIST)
    foot = [(q.x, q.y) for q in se_ring(18.4, 14.4, 0.0, n=20)]
    foot_rubble(sch, fr, [((Vector((x, y)) - fr.o.to_2d()).dot(fr.d.to_2d()),
                           (Vector((x, y)) - fr.o.to_2d()).dot(fr.n.to_2d())) for x, y in foot],
                16, seed=83, size=(0.7, 2.6))
    # --- iarba: covorul creștetului (retras 0,6 m de la muchie: nu face inel),
    # LIMBI care coboara pe ravene, petice pe varful a 4 contraforturi
    hull(gr, [(q.x, q.y, PZ - 0.2) for q in se_ring(11.9, 6.9, 0.0, n=20, p=5.0)]
         + [(q.x, q.y, PZ + 0.05) for q in se_ring(11.9, 6.9, 0.0, n=20, p=5.0)]
         + [(q.x, q.y, PZ + 0.10) for q in se_ring(10.0, 5.5, 0.0, n=12, p=5.0)], TROPICAL_GREEN)
    rt = _rr(37)
    for ang in RAVINES:
        t = math.radians(ang)
        drop = 8.0 + 4.0 * rt()
        steps = 5
        for j in range(steps):               # limba pe bucati (urmareste fata)
            za = PZ + 0.1 - drop * j / steps
            zb2 = PZ + 0.1 - drop * (j + 1) / steps
            pts = []
            for zz, hw in ((za, 2.4 - 1.4 * j / steps), (zb2, 2.4 - 1.4 * (j + 1) / steps)):
                c0 = core_pt(t, min(zz, PZ))
                N2 = se_normal(13.0, 8.5, t, 4.0)
                T2 = Vector((-N2.y, N2.x))
                for sw in (-1.0, 1.0):
                    q = c0 + T2 * (sw * hw * (0.8 + 0.3 * rt()))
                    pts.append((q.x - N2.x * 0.4, q.y - N2.y * 0.4, zz))
                    pts.append((q.x + N2.x * 0.12, q.y + N2.y * 0.12, zz))
            hull(gr, pts, TROPICAL_GREEN)
    for (t, wg, ht, N2, T2, sh, ot) in tops_g:
        if ht > PZ - 1.0 or ht < 8.0:
            continue                          # sub turn / prea jos: fara petic
        c0 = core_pt(t, ht) + N2 * (ot * 0.5) + T2 * (sh * wg)
        pts = []
        for k in range(6):
            a_ = 2 * math.pi * k / 6
            q = c0 + T2 * (math.cos(a_) * wg * 0.35) + N2 * (math.sin(a_) * 1.0)
            pts += [(q.x, q.y, ht - 0.9), (q.x, q.y, ht + 0.45)]
        hull(gr, pts, TROPICAL_GREEN)
    # --- incinta 22 x 12 (centrul zidurilor la x = +-10,4, y = +-5,4; groase 1,2)
    X, Y, TH = 10.4, 5.4, 1.2
    zb = PZ - 0.3
    walls = [
        # (p0, p1, [(u0, u1, h, crenel, window(u0,u1,sill,lintel) in fractii din bucata)])
        ((-X, Y), (X, Y), [(0.00, 0.16, 6.5, False, None), (0.16, 0.32, 5.2, False, (0.3, 0.7, 2.6, 4.4)),
                           (0.32, 0.43, 1.6, False, None), (0.43, 0.62, 4.6, True, None),
                           (0.62, 0.80, 6.2, False, (0.35, 0.65, 3.0, 5.0)), (0.80, 1.00, 7.6, False, None)]),
        ((5.0, -Y), (-X, -Y), [(0.00, 0.28, 8.0, False, (0.35, 0.6, 4.0, 6.2)), (0.28, 0.52, 6.6, False, None),
                               (0.52, 0.72, 2.8, False, None), (0.72, 1.00, 7.2, True, None)]),
        ((X, -0.4), (X, Y), [(0.0, 0.5, 7.0, False, None), (0.5, 1.0, 5.6, False, (0.25, 0.75, 2.8, 4.6))]),
        ((-X, -Y), (-X, Y), [(0.0, 0.25, 6.0, False, None), (0.25, 0.75, 2.4, False, None),
                             (0.75, 1.0, 5.0, False, None)]),
    ]
    s_i = 0
    for p0, p1, pieces in walls:
        p0, p1 = Vector(p0), Vector(p1)
        for (u0, u1, h, cren, win) in pieces:
            a = p0.lerp(p1, u0)
            b_ = p0.lerp(p1, u1)
            s_i += 1
            _wall_piece(br, st, a, b_, TH, zb, h, (0.3 + 0.4 * ((s_i * 37) % 5) / 4.0) if s_i % 2 else 0.0,
                        seed=100 + s_i,
                        crenel=cren, window=win)
    # --- turnul rectangular (6 x 6, gol, 10 m), coltul +X/-Y, varful rupt in trepte
    tx0, tx1, ty0, ty1, tt = 5.0, 11.0, -6.4, -0.4, 1.0
    tw = [((tx0, ty0 + tt * 0.5), (tx1, ty0 + tt * 0.5), [(0.0, 0.55, 10.0, None), (0.55, 1.0, 8.8, (0.2, 0.7, 4.5, 6.6))]),
          ((tx1 - tt * 0.5, ty0), (tx1 - tt * 0.5, ty1), [(0.0, 1.0, 9.4, (0.35, 0.65, 5.0, 7.0))]),
          ((tx1, ty1 - tt * 0.5), (tx0, ty1 - tt * 0.5), [(0.0, 0.5, 8.2, (0.4, 0.8, 3.6, 5.6)), (0.5, 1.0, 9.6, None)]),
          ((tx0 + tt * 0.5, ty1), (tx0 + tt * 0.5, ty0), [(0.0, 1.0, 7.4, None)])]
    for p0, p1, pieces in tw:
        p0, p1 = Vector(p0), Vector(p1)
        for (u0, u1, h, win) in pieces:
            s_i += 1
            _wall_piece(br, st, p0.lerp(p1, u0), p0.lerp(p1, u1), tt, zb, h, 0.5 if s_i % 3 == 0 else 0.0,
                        seed=200 + s_i,
                        window=win, jag=0.5)
    # --- turnul semicircular pe latura -X, iesit peste marginea stancii; sta pe
    # contrafortul de la -X (varful la ~17,4), ingropat 0,3 m in el, fara talpa
    cx, R = -X - 0.2, 3.0
    hs = [5.2, 7.0, 6.4, 4.2, 3.0, 5.6]
    for i in range(6):
        a0 = math.pi * 0.5 + math.pi * i / 6.0
        a1 = math.pi * 0.5 + math.pi * (i + 1) / 6.0
        p0 = Vector((cx + R * math.cos(a0), R * math.sin(a0)))
        p1 = Vector((cx + R * math.cos(a1), R * math.sin(a1)))
        win = (0.3, 0.75, 3.0, 4.6) if i == 2 else None
        _wall_piece(br, st, p0, p1, 1.0, 16.6, hs[i], 0.0, seed=300 + i, window=win,
                    jag=0.4)
    # --- moloz in curte: caramizi si pietre cazute
    r = _rr(77)
    for k in range(9):
        x = -7.0 + 14.0 * r()
        y = -3.6 + 7.2 * r()
        s = 0.5 + 0.7 * r()
        sb = br if k % 3 else st
        faceted_block(sb, (x, y, PZ - 0.05), (s * 1.4, s, s * 0.6), TILE_TERRACOTTA if k % 3 else MARBLE_GREY,
                      seed=400 + k, jag=0.4)
    # --- scara in zig-zag pe flancul -Y: 4 rampe de trepte (forma, nu detaliu)
    def face_y(z):
        """Fata -Y a miezului la cota z (pe axa x ~ 0)."""
        return core_pt(-math.pi * 0.5, z).y
    flights = [((-9.0, 0.2), (7.0, 4.4)), ((7.0, 4.4), (-7.0, 8.8)),
               ((-7.0, 8.8), (7.0, 13.6)), ((7.0, 13.6), (-5.0, PZ))]
    for (xa, za), (xb, zb_) in flights:
        n = max(4, int(round((zb_ - za) / 0.32)))
        for i in range(n):
            x0 = xa + (xb - xa) * i / n
            x1 = xa + (xb - xa) * (i + 1) / n
            ztop = za + (zb_ - za) * (i + 1) / n
            yi = face_y(ztop) + 0.35
            st.box(((x0 + x1) * 0.5, yi - 0.75, ztop - 0.55),
                   (abs(x1 - x0) + 0.02, 1.5, 1.1), MARBLE_GREY)
        # parapetul scund de pe marginea din afara
        st.beam((xa, face_y(za) - 1.3, za + 0.5), (xb, face_y(zb_) - 1.3, zb_ + 0.5), (0.25, 0.5),
                MARBLE_GREY, up=(0, 1, 0))
    return [sch.to_object("Poenari_Schist"), br.to_object("Poenari_Brick"),
            st.to_object("Poenari_Stone"), gr.to_object("Poenari_Grass")]


# ---------------------------------------------------------------------------
# prometheus_statue
# ---------------------------------------------------------------------------

AO_STATUE = dict(samples=20, dist=0.9, gradient="vertical", low=0.62, high=1.0,
                 power=0.8, floor=0.34, z_range=(0.0, 9.0))


def _ell_hull(b, c, r3, slot, n=7, rings=3, seed=0, jit=0.06):
    """Masa fatetata: invelitoarea convexa a unor puncte pe un elipsoid."""
    rr = _rr(seed)
    pts = [(c[0], c[1], c[2] - r3[2]), (c[0], c[1], c[2] + r3[2])]
    for k in range(1, rings + 1):
        el = -math.pi * 0.5 + math.pi * k / (rings + 1)
        for i in range(n):
            a = 2 * math.pi * (i + 0.5 * (k % 2)) / n
            j = 1.0 + jit * (2 * rr() - 1)
            pts.append((c[0] + r3[0] * math.cos(el) * math.cos(a) * j,
                        c[1] + r3[1] * math.cos(el) * math.sin(a) * j,
                        c[2] + r3[2] * math.sin(el) * j))
    return hull(b, pts, slot)


def _limb(b, pts, radii, slot, seg=6):
    return b.taper_sweep([Vector(p) for p in pts], list(radii), slot, segments=seg)


def _bolt(b, base, axis_deg, length, width, seed=0, plane="XZ"):
    """Fulgerul in zig-zag: 3 segmente plate, groase 0,12 m, ultimul ascutit.
    Linia de mijloc Q0..Q3 in (u lungul axei, w lateral), rotita cu `axis_deg`
    in planul XZ, cu centrul (punctul de prindere) in `base`."""
    Q = [(0.0, 0.0), (0.40, 0.30), (0.50, -0.10), (1.0, 0.22)]
    a = math.radians(axis_deg)
    U = Vector((math.cos(a), 0.0, math.sin(a)))
    W = Vector((-math.sin(a), 0.0, math.cos(a)))
    Y = Vector((0.0, 0.06, 0.0))
    c = Vector(base) - U * (length * 0.5)
    for i in range(3):
        u0, w0 = Q[i]
        u1, w1 = Q[i + 1]
        p0 = c + U * (u0 * length) + W * (w0 * length)
        p1 = c + U * (u1 * length) + W * (w1 * length)
        d = (p1 - p0).normalized()
        nn = Vector((-d.z, 0.0, d.x))       # perpendicular in planul XZ
        hw0 = width * (0.5 if i < 2 else 0.45)
        hw1 = 0.0 if i == 2 else width * 0.45
        e0 = p0 - d * width * 0.25
        e1 = p1 + d * (width * 0.25 if i < 2 else 0.0)
        pts = []
        for (p, hw) in ((e0, hw0), (e1, hw1)):
            for s in (-1.0, 1.0):
                for sy in (-1.0, 1.0):
                    pts.append(p + nn * (s * hw) + Y * sy)
        hull(b, pts, CAR_YELLOW)


def build_prometheus_statue():
    """Statuia lui Prometeu (`prometheus_statue`), kit §1.2.

    LISTA DE ELEMENTE (decuparea `transfagarasan_assets_v1/prometheus_statue.png`,
    scrisa INAINTE de geometrie; fasia de stanca din piesa vecina, la dreapta,
    se ignora):
      1) SOCLUL de stanca: tambur scund si lat (~1/3 din total), fete plane mari
         aproape verticale, 5-6 blocuri, cu CRESTETUL PLAT acoperit de iarba
         galben-verzuie; 4 bolovani separati la picior, putin muschi
      2) FIGURA masculina de BRONZ (maro-arama), musculoasa, cu fatete mari,
         in picioare, cu picioarele DEPARTATE (pas larg), trunchiul usor rasucit
      3) un BRAT ridicat drept in sus, cu FULGERUL mare galben in zig-zag tinut
         deasupra capului, in diagonala, spre exterior
      4) celalalt brat coborat langa corp, cu un FULGER MIC galben spre jos
      5) capul cu par strans (o creasta)
      6) fara inscriptie, fara text
    CORECTURI / cote (tabel): 9 m total = soclu 3 m (diametru ~4 m) + figura 6 m
    cu bratul ridicat; bratul ridicat e DREPTUL figurii (pe decupare e stangul:
    urmez tabelul); fulgerul mare are 3 segmente si 1,5 m (pe decupare e
    ramificat: urmez tabelul); fulgerul mic din mana coborata (0,7 m) e pe
    decupare si nu-l contrazice nimic, deci il pastrez. Figura e privita si din
    spate (drumul trece pe langa pinten): bratul si fulgerul ies din silueta
    pe orice azimut. Fata spre +Y (dreapta figurii = +X).
    Noduri: Statue_Bronze (LARCH_RUST 27, parul si panza de pe solduri LOG_DARK
    28), Statue_Bolt (CAR_YELLOW 16, --allow-car-slots=Statue_Bolt),
    Statue_Schist (soclul, MARBLE_GREY 29 -> tf_schist), Statue_Grass (iarba de pe
    creștet, DRY_VEGETATION 13: nod separat, fiindca clasa de pe *_Schist sterge
    sloturile -- abatere de la lista de noduri din tabel, cu motiv)."""
    bz, bo, sc, gr = Builder(), Builder(), Builder(), Builder()
    fr = SchistFrame((0.0, 0.0, 0.0), 40.0)
    Z0 = 3.0
    # --- soclul: tambur care se largeste la baza + blocuri pe foliatie + moloz
    rock_tier(sc, (2.3, 2.2, 0.0), (1.62, 1.52, Z0), seed=3, n=10, p=2.4, jit=0.05)
    tier_blocks(sc, fr, 2.0, 1.9, 0.0, Z0, 7, seed=17, dip=38.0, sink=0.6, out=(0.2, 0.5),
                top_clamp=Z0 + 0.1, top_drop=(0.1, 1.1), p=2.4, fill=0.9)
    foot = [(q.x, q.y) for q in se_ring(2.45, 2.35, 0.0, n=12, p=2.4)]
    foot_rubble(sc, fr, [((Vector(f) - fr.o.to_2d()).dot(fr.d.to_2d()),
                          (Vector(f) - fr.o.to_2d()).dot(fr.n.to_2d())) for f in foot],
                5, seed=29, size=(0.4, 1.0))
    # iarba: in INTERIORUL crestetului (nu iese peste muchie ca un capac)
    hull(gr, [(q.x, q.y, Z0 - 0.2) for q in se_ring(1.5, 1.4, 0.0, n=12, p=2.4, jit=0.06, seed=4)]
         + [(q.x, q.y, Z0 + 0.04) for q in se_ring(1.42, 1.32, 0.0, n=12, p=2.4, jit=0.06, seed=5)]
         + [(q.x, q.y, Z0 + 0.09) for q in se_ring(0.9, 0.8, 0.0, n=8, p=2.4)], DRY_VEGETATION)

    # --- figura: cotele peste crestet (z = Z0 + h). MASIVA: umeri de 1,7 m,
    # coapse groase, pas larg cu genunchii indoiti, ca pe decupare
    def P(x, y, h):
        return (x, y, Z0 + h)
    B, D = LARCH_RUST, LOG_DARK
    # picioarele: scurte si groase, genunchii indoiti in fata si spre afara
    _limb(bz, [P(0.3, 0.02, 2.05), P(0.66, 0.30, 1.05), P(0.86, 0.20, 0.22)], (0.42, 0.30, 0.17), B)
    _limb(bz, [P(-0.3, -0.02, 2.05), P(-0.62, 0.12, 1.05), P(-0.84, -0.25, 0.22)], (0.42, 0.30, 0.17), B)
    for (x, y, yaw) in ((0.88, 0.34, 0.25), (-0.86, -0.18, -0.2)):
        bz.box((x, y, Z0 + 0.11), (0.36, 0.7, 0.22), B, rotation=Matrix.Rotation(yaw, 3, "Z"))
    # bazinul cu panza (LOG_DARK)
    _ell_hull(bz, P(0.0, 0.02, 2.08), (0.54, 0.38, 0.3), D, n=8, rings=2, seed=1)
    # trunchiul in V, APLECAT in fata (pieptul +0,15 pe Y): talie, piept adanc,
    # umeri lati, trapezul gros
    hull(bz, [P(sx * 0.44, sy * 0.27, 2.28) for sx in (-1, 1) for sy in (-1, 1)]
         + [P(sx * 0.76, 0.52 if sy > 0 else -0.22, 3.12) for sx in (-1, 1) for sy in (-1, 1)]
         + [P(sx * 0.98, 0.12, 3.55) for sx in (-1, 1)]
         + [P(sx * 0.56, 0.12 + sy * 0.26, 3.76) for sx in (-1, 1) for sy in (-1, 1)]
         + [P(0.0, 0.6, 3.1), P(0.0, -0.3, 3.25)], B)
    # pieptul: o placa lata, iesita, si abdomenul
    hull(bz, [P(sx * 0.66, 0.48, 2.95) for sx in (-1, 1)] + [P(sx * 0.62, 0.48, 3.42) for sx in (-1, 1)]
         + [P(sx * 0.3, 0.64, 3.08) for sx in (-1, 1)] + [P(0.0, 0.66, 3.25), P(0.0, 0.3, 3.2)], B)
    hull(bz, [P(sx * 0.3, 0.32, 2.35) for sx in (-1, 1)] + [P(sx * 0.36, 0.48, 2.85) for sx in (-1, 1)]
         + [P(0.0, 0.52, 2.6), P(0.0, 0.1, 2.6)], B)
    for sx in (-1, 1):            # deltoizii
        _ell_hull(bz, P(sx * 0.95, 0.12, 3.55), (0.3, 0.29, 0.3), B, n=6, rings=2, seed=12 + sx)
    # gat scurt si gros, capul intre umeri, parul (creasta) inchis
    _limb(bz, [P(0.0, 0.15, 3.66), P(0.0, 0.2, 3.86)], (0.23, 0.2), B)
    _ell_hull(bz, P(0.0, 0.26, 4.0), (0.21, 0.24, 0.26), B, n=7, rings=3, seed=21)
    hull(bz, [P(sx * 0.2, y, 4.08) for sx in (-1, 1) for y in (0.06, 0.36)]
         + [P(0.0, 0.16, 4.33), P(0.0, 0.36, 4.28), P(0.1, 0.03, 4.22), P(-0.1, 0.03, 4.22)], D)
    # bratul DREPT (+X) ridicat, cotul in afara; fulgerul mare in diagonala
    # spre exterior, varful la ~9,0 m
    _limb(bz, [P(0.98, 0.12, 3.6), P(1.45, 0.18, 4.25), P(1.32, 0.2, 4.98)], (0.28, 0.22, 0.16), B)
    _ell_hull(bz, P(1.32, 0.2, 5.04), (0.19, 0.19, 0.2), B, n=6, rings=2, seed=31)
    _bolt(bo, P(1.58, 0.2, 5.3), 55.0, 1.5, 0.17)
    # bratul STANG (-X) coborat, cu fulgerul mic spre jos-afara
    _limb(bz, [P(-0.98, 0.12, 3.6), P(-1.28, 0.0, 2.85), P(-1.32, 0.25, 2.25)], (0.28, 0.22, 0.16), B)
    _ell_hull(bz, P(-1.33, 0.26, 2.15), (0.19, 0.19, 0.2), B, n=6, rings=2, seed=33)
    _bolt(bo, P(-1.55, 0.27, 1.82), -122.0, 0.8, 0.12)
    return [bz.to_object("Statue_Bronze"), bo.to_object("Statue_Bolt"),
            sc.to_object("Statue_Schist"), gr.to_object("Statue_Grass")]


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

if _want("poenari_ruin"):
    emit_tf(build_poenari_ruin(), "buildings/poenari_ruin.glb", AO_POENARI, keep_xy=True,
            bevel=0.0, bevels={"_Brick": 0.03, "_Stone": 0.03}, smooth_angle=None)

if _want("prometheus_statue"):
    emit_tf(build_prometheus_statue(), "props/prometheus_statue.glb", AO_STATUE, keep_xy=True,
            bevel=0.0, smooth_angle=None)

report_tf()
