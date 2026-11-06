"""Angkor -- val 3, grupul A: templul Angkor Wat (kit angkor_kit.md §1.2).

  angkor/structures/angkor_wat_temple.glb   fundal: soclu 64 x 64, cinci turnuri-boboc

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_temple.py

Axe: X latime, Y adancime, Z sus. Scara si galeria PE +Y (fata bogata, regula
kitului; in joc coordonatorul il roteste cu fata spre vest). Originea: centrul
soclului, talpa la z = 0.

VOCABULARUL vine din build_angkor_gates_w.py (executat, nu copiat, cu
ANK_ONLY=none ca sa nu refaca poarta): `bx`, `wall_faces`, `column`,
`round_tier`/`lotus_tower`, `gable`, `scatter_lichen`. Lectiile rundelor
precedente: etajele sunt ROTUNDE si bombate (placile plate in trepte citesc
MAYASE) si turnurile NU au fete.

LISTA DE ELEMENTE (decuparea `angkor_wat_temple.png`, planse c; anvelopa din
`Machete/AW_*` a Track24 -- varfurile NU urca peste ea):
  1. Soclul 64 x 64: trei lespezi in trepte (z 0..3, jumatati 32 / 31,2 / 30,4)
     cu randuri de blocuri; scara axiala pe +Y (6 trepte, 10 m lat) cu
     balustrade de blocuri.
  2. Galeria de jos (inel, jumatati 24,6..30): zid interior cu blocuri,
     colonada exterioara, acoperis PANTAT (invelitoare convexa) cu antefixe;
     portice cu fronton ascutit pe -Y / +-X, gol pentru scara pe +Y; la colturi
     blocuri-pavilion cu movilite de blocuri (ca in decupare).
  3. Terasa a doua 44 x 44, tot in trepte pana la +8 (jumatati 23,6 / 22,8 / 22).
     Scara a doua (10 trepte) taie treptele pe axa.
  4. Galeria de sus (inel, jumatati 15,5..21): aceeasi gramatica, cu portice cu
     fronton ascutit si un portic de intrare pe +Y; pavilioane de colt de
     7 x 7 m din care cresc turnurile.
  5. Platforma centrala (jumatati 10,5 / 9,3 / 7,5 pana la z = 14) cu scara
     ei pe +Y.
  6. Cinci turnuri, in quincunx: baza patrata cu blocuri, 5-7 etaje ROTUNDE
     bombate (`round_tier`), mici frontonase ascutite pe cele patru axe ale
     primelor etaje, boboc de lotus cu finial. Centralul (0, 0): varf la +36;
     colturile (+-17, +-17): varf la +30. FARA fete.
  7. Lichen pe orizontale (lespezi, trepte, streasini), dare negre sub
     cornise si sub acoperisuri.
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
_old = os.environ.get("ANK_ONLY")
os.environ["ANK_ONLY"] = "none"          # incarca doar ajutoarele, nu reface poarta
exec(open(os.path.join(_here, "build_angkor_gates_w.py"), encoding="utf-8").read())
if _old is None:
    os.environ.pop("ANK_ONLY", None)
else:
    os.environ["ANK_ONLY"] = _old
ANK_RESULTS.clear()

TOP_C, TOP_K = 36.0, 30.0
CORNER = 17.0
Z_L1 = 3.0            # fata de sus a soclului de jos
Z_T2 = 8.0            # fata de sus a terasei a doua
Z_CEN = 14.0          # platforma centrala

AO_TEMPLE = dict(samples=16, dist=2.0, gradient="vertical", low=0.60, high=1.0,
                 power=0.85, floor=0.30, strength=1.3, z_range=(0.0, TOP_C))

# laturile: k = 0 (+Y, fata), 1 (-X), 2 (-Y), 3 (+X); `out` = fata de iesire in lume
_OUT = {0: "+y", 1: "-x", 2: "-y", 3: "+x"}
_IN = {0: "-y", 1: "+x", 2: "+y", 3: "-x"}


def fr_of(k):
    return Frame((0.0, 0.0, 0.0), 90.0 * k)


def rbox(b, k, u0, u1, w0, w1, z0, z1, slot=ANK_STONE):
    """Cutie in sistemul laturii k: u de-a lungul ei, w spre exterior."""
    fr = fr_of(k)
    p, q = fr.p(u0, w0), fr.p(u1, w1)
    bx(b, p.x, q.x, p.y, q.y, z0, z1, slot)


def rwall(b, k, u0, u1, w0, w1, z0, z1, local_faces, ch=0.9, bw=1.6, seed=0, proud=0.05):
    fr = fr_of(k)
    p, q = fr.p(u0, w0), fr.p(u1, w1)
    faces = []
    for f in local_faces:
        faces.append({"out": _OUT[k], "in": _IN[k]}.get(f))
    # fetele de capat (u0 / u1): nu se imbraca
    wall_faces(b, min(p.x, q.x), max(p.x, q.x), min(p.y, q.y), max(p.y, q.y), z0, z1,
               [f for f in faces if f], ch=ch, bw=bw, seed=seed, proud=proud)


def rcol(b, k, u, w, z0, z1, cw=0.6):
    p = fr_of(k).p(u, w)
    column(b, p.x, p.y, z0, z1, w=cw)


def rhull(b, k, pts, slot=ANK_STONE):
    fr = fr_of(k)
    hull(b, [fr.p(u, w, z) for (u, w, z) in pts], slot)


def rgable(b, k, uc, w0, w1, z0, hw, zapex):
    fr = fr_of(k)
    pts = []
    for w in (w0, w1):
        pts += [fr.p(uc - hw, w, z0), fr.p(uc + hw, w, z0), fr.p(uc, w, zapex)]
    hull(b, pts, ANK_STONE)


def stair(b, x0, x1, y_hi, y_lo, z_hi, n, slot=ANK_STONE, wall=0.0):
    """Scara pe +Y: `n` trepte de la (y_lo, 0) la (y_hi, z_hi); fiecare treapta e
    un bloc plin pana la sol (sub ea nu ramane gol)."""
    run = (y_lo - y_hi) / n
    rise = z_hi / n
    z_base = 0.0
    for i in range(n):
        ya = y_lo - run * (i + 1)
        yb = y_lo - run * i
        bx(b, x0, x1, ya, yb, z_base, rise * (i + 1), slot)


def pointed(b, k, r, z, hw, h, depth=0.14, slot=ANK_STONE):
    """Frontonas ascutit lipit pe un etaj rotund, pe cele 4 axe (pe raza r)."""
    fr = fr_of(k)
    pts = []
    for w, ww in ((r * 0.93, 1.0), (r + depth, 0.55)):
        pts += [fr.p(-hw * ww, w, z), fr.p(hw * ww, w, z)]
    c = [fr.p(0.0, r * 0.93, z + h), fr.p(0.0, r + depth, z + h * 0.9)]
    hull(b, pts + c, slot)


def tower(b, cx, cy, z0, base_half, base_h, tiers, top, bud_r, nbase_gables=True):
    """Turn-boboc: baza patrata cu blocuri, etaje rotunde, frontonase pe primele
    etaje, boboc cu finial. Intoarce cota de sus a etajelor."""
    bx(b, cx - base_half, cx + base_half, cy - base_half, cy + base_half, z0, z0 + base_h)
    wall_faces(b, cx - base_half, cx + base_half, cy - base_half, cy + base_half, z0, z0 + base_h,
               ["+y", "-y", "+x", "-x"], ch=0.8, bw=2.2, seed=int(abs(cx) * 7 + abs(cy) * 3 + 11))
    z = z0 + base_h
    # frontonase pe primele trei etaje (inainte de etaj: stiu cotele)
    for i, (r, h) in enumerate(tiers):
        if i < 3:
            for k in range(4):
                fr = Frame((cx, cy, 0.0), 90.0 * k)
                pts = []
                for w, ww in ((r * 0.90, 1.0), (r + 0.16, 0.5)):
                    pts += [fr.p(-0.75 * ww * r / 3.0, w, z + 0.1), fr.p(0.75 * ww * r / 3.0, w, z + 0.1)]
                pts += [fr.p(0.0, r * 0.90, z + h * 0.78), fr.p(0.0, r + 0.16, z + h * 0.7)]
                hull(b, pts, ANK_STONE)
        z = round_tier(b, cx, cy, z, h, r)
    lotus_bud(b, cx, cy, z, top - z, bud_r, ANK_STONE, petals=8, segments=14)
    return z


def build_temple():
    S, L, G = Builder(), Builder(), Builder()
    sites = []
    streaks = []            # (k, u0, u1, w, z_top, n, lmin, lmax)

    def strip_sites(half_o, half_i, z):
        """Patru fasii orizontale (inelul half_i..half_o) pentru lichen."""
        sites.extend([(-half_o, half_o, half_i, half_o, z), (-half_o, half_o, -half_o, -half_i, z),
                      (-half_o, -half_i, -half_i, half_i, z), (half_i, half_o, -half_i, half_i, z)])

    # --- 1. soclul de jos: trei lespezi, blocuri pe pereti -------------------------
    slabs = [(0.0, 1.0, 32.0), (1.0, 2.0, 31.2), (2.0, 3.0, 30.4)]
    for i, (z0, z1, h) in enumerate(slabs):
        bx(S, -h, h, -h, h, z0, z1)
        wall_faces(S, -h, h, -h, h, z0, z1, ["+y", "-y", "+x", "-x"], ch=1.0, bw=2.4, seed=5 + i, proud=0.06)
        nxt = slabs[i + 1][2] if i + 1 < len(slabs) else 29.6
        strip_sites(h - 0.1, nxt + 0.1, z1)
    # inelul de sus al soclului (z = 3, h 30,4 -> galeria)
    # scara axiala pe +Y: 6 trepte de la y = 32 la y = 28,6; balustrade de blocuri
    stair(S, -5.0, 5.0, 28.6, 32.0, Z_L1, 6)
    for sx in (-1, 1):
        x0, x1 = (5.0, 6.6) if sx > 0 else (-6.6, -5.0)
        bx(S, x0, x1, 28.6, 32.0, 0.0, 1.7)
        bx(S, x0 - 0.1, x1 + 0.1, 28.6, 29.4, 1.7, 2.4)
        bx(S, x0 - 0.1, x1 + 0.1, 30.9, 32.0, 0.0, 2.7)
    sites.append((-6.6, -5.0, 29.0, 31.0, 1.7)); sites.append((5.0, 6.6, 29.0, 31.0, 1.7))

    # --- 2. galeria de jos: inel half 24,6..30 pe z = 3 ----------------------------
    GA_I, GA_O = 24.6, 30.0
    WALL_W0, WALL_W1 = 25.4, 26.9            # zidul interior
    COL_W = 28.7                              # colonada exterioara
    Z0 = Z_L1
    ZC = Z0 + 3.2                             # sub arhitrava
    PROF = [(4.5, 0.20), (4.6, 0.70), (3.5, 1.45), (2.4, 2.05), (1.2, 2.55), (0.4, 2.75)]   # (dist. de axa, z peste ZC+0.4)
    SHR = [0.0, 0.1, 0.8, 1.5, 2.1, 2.5]

    def gallery_ring(half_axis, wall0, wall1, colw, z0, zc, gap_front, porticos, seed, roof_ribs=True,
                     col_step=2.6, corner=3.6, door=5.0, roof_prof=None, shr=None):
        """Un inel de galerie in jurul unui patrat cu axa la `half_axis`:
        zid interior (wall0..wall1), colonada la `colw`, arhitrava, acoperis pantat.
        Capetele de colt (|u| > corner_u) raman libere pentru pavilioane."""
        rp = roof_prof or PROF
        sh = shr or SHR
        cu = half_axis - corner                    # inceputul pavilionului de colt
        for k in range(4):
            front = (k == 0)
            # podeaua galeriei: dala subtire
            rbox(S, k, -cu, cu, wall0 - 0.5, colw + 1.3, z0, z0 + 0.35)
            # zid interior, intrerupt pe fata pentru scara
            segs = [(-cu, cu)]
            if front and gap_front:
                segs = [(-cu, -door), (door, cu)]
            for (ua, ub) in segs:
                rbox(S, k, ua, ub, wall0, wall1, z0 + 0.35, zc)
                rwall(S, k, ua, ub, wall0, wall1, z0 + 0.35, zc, ["out", "in"], ch=1.1, bw=2.6, seed=seed + k)
            # colonada exterioara
            u = -cu + 1.2
            while u < cu - 0.5:
                if not (front and gap_front and abs(u) < door + 0.2):
                    rcol(S, k, u, colw, z0 + 0.35, zc - 0.0, cw=0.62)
                u += col_step
            # arhitrava deasupra colonadei (intrerupta pe fata)
            for (ua, ub) in segs:
                rbox(S, k, ua, ub, colw - 0.55, colw + 0.55, zc - 0.4, zc)
            # acoperis pantat: invelitoare convexa pe fiecare latura
            zr = zc
            wmid = (wall0 + colw) * 0.5
            pts = []
            for (hy, zz), s_ in zip(rp, sh):
                for u_ in (-cu, cu):
                    ue = u_ - math.copysign(s_ * 0.5, u_)
                    for sgn in (-1, 1):
                        pts.append((ue, wmid + sgn * hy, zr + zz))
            rhull(S, k, pts)
            # nervuri de tigla (rare)
            if roof_ribs:
                u = -cu + 1.6
                while u < cu - 1.0:
                    if not (front and gap_front and abs(u) < door + 0.6):
                        for sgn in (-1, 1):
                            for j in (1, 3):
                                (ya_, za_), (yb_, zb_) = rp[j], rp[j + 1]
                                seg = []
                                for (yy, zz) in ((ya_, za_), (yb_, zb_)):
                                    for du in (-0.1, 0.1):
                                        seg.append((u + du, wmid + sgn * yy, zr + zz))
                                        seg.append((u + du, wmid + sgn * (yy + 0.08), zr + zz + 0.08))
                                rhull(S, k, seg)
                    u += 3.2
            # antefixe pe streasina exterioara
            u = -cu + 1.0
            while u < cu - 0.5:
                if not (front and gap_front and abs(u) < door + 0.5):
                    p = fr_of(k).p(u, wmid + rp[0][0] - 0.1, zr + 0.35)
                    S.box((p.x, p.y, p.z), (0.26, 0.26, 0.34), ANK_STONE)
                u += 2.0
            streaks.append((k, -cu + 0.6, cu - 0.6, colw + 0.55, zc, 6, 0.25, 0.5))
            streaks.append((k, -cu + 0.6, cu - 0.6, wall1, zc, 6, 0.5, 1.2))

    gallery_ring(27.4, WALL_W0, WALL_W1, COL_W, Z0, ZC, True, True, 100)

    # portice cu fronton ascutit pe -Y, +-X (axa laturii)
    for k in (1, 2, 3):
        rbox(S, k, -4.0, 4.0, COL_W - 0.5, COL_W + 1.2, Z0 - 0.0, Z0 + 0.35)
        rbox(S, k, -4.2, 4.2, WALL_W1 + 0.05, COL_W + 0.5, ZC, ZC + 0.4)
        rgable(S, k, 0.0, COL_W - 1.0, COL_W + 0.8, ZC + 0.4, 4.4, ZC + 0.4 + 3.6)
        rgable(S, k, 0.0, COL_W + 0.8, COL_W + 1.0, ZC + 0.4, 3.5, ZC + 0.4 + 2.9)
    for k in (1, 2, 3):
        for u in (-3.6, -1.2, 1.2, 3.6):
            rcol(S, k, u, COL_W + 0.3, Z0 + 0.35, ZC, cw=0.7)
    # portic de intrare pe +Y: doi stalpi mari + fronton peste gol
    for sx in (-1, 1):
        for w in (28.4, 29.2):
            p = fr_of(0).p(sx * 5.2, w)
            column(S, p.x, p.y, Z0, ZC + 0.4, w=0.9)
    rbox(S, 0, -5.8, 5.8, 27.8, 29.8, ZC, ZC + 0.4)
    rgable(S, 0, 0.0, 27.6, 29.5, ZC + 0.4, 5.9, ZC + 0.4 + 4.0)
    rgable(S, 0, 0.0, 29.5, 29.9, ZC + 0.4, 4.6, ZC + 0.4 + 3.2)

    # pavilioane de colt (galeria de jos): bloc de blocuri + movila + finialuri
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx_, cy_ = sx * 27.4, sy * 27.4
            bx(S, cx_ - 2.7, cx_ + 2.7, cy_ - 2.7, cy_ + 2.7, Z0, Z0 + 3.6)
            wall_faces(S, cx_ - 2.7, cx_ + 2.7, cy_ - 2.7, cy_ + 2.7, Z0, Z0 + 3.6, ["+y", "-y", "+x", "-x"],
                       ch=1.2, bw=2.4, seed=77 + sx + 2 * sy)
            bx(S, cx_ - 2.9, cx_ + 2.9, cy_ - 2.9, cy_ + 2.9, Z0 + 3.6, Z0 + 4.0)
            bx(S, cx_ - 2.0, cx_ + 2.0, cy_ - 2.0, cy_ + 2.0, Z0 + 4.0, Z0 + 5.2)
            bx(S, cx_ - 1.3, cx_ + 1.3, cy_ - 1.3, cy_ + 1.3, Z0 + 5.2, Z0 + 6.2)
            bx(S, cx_ - 0.6, cx_ + 0.6, cy_ - 0.6, cy_ + 0.6, Z0 + 6.2, Z0 + 7.0)
            sites.append((cx_ - 2.9, cx_ + 2.9, cy_ - 2.9, cy_ + 2.9, Z0 + 4.0))
    strip_sites(29.6, 24.6, Z_L1 + 0.02)

    # --- 3. terasa a doua: 44 x 44, trepte pana la +8 --------------------------------
    t2 = [(Z_L1, 4.7, 23.6), (4.7, 6.4, 22.8), (6.4, Z_T2, 22.0)]
    for i, (z0, z1, h) in enumerate(t2):
        bx(S, -h, h, -h, h, z0, z1)
        wall_faces(S, -h, h, -h, h, z0, z1, ["+y", "-y", "+x", "-x"], ch=1.1, bw=2.8, seed=40 + i, proud=0.05)
    sites.append((-22.0, 22.0, 15.0, 22.0, Z_T2)); sites.append((-22.0, 22.0, -22.0, -15.0, Z_T2))
    sites.append((-22.0, -15.0, -15.0, 15.0, Z_T2)); sites.append((15.0, 22.0, -15.0, 15.0, Z_T2))
    # scara a doua (taie treptele pe axa): de la y = 24,0 (z = 3) la y = 22 (z = 8)
    n2 = 10
    # blocuri pline: treapta i urca la 3 + 0,5 * (i + 1), adancime 2,4 / n
    for i in range(n2):
        yb = 24.2 - (2.6 / n2) * i
        ya = 24.2 - (2.6 / n2) * (i + 1)
        bx(S, -5.0, 5.0, ya, yb, Z_L1, Z_L1 + (Z_T2 - Z_L1) * (i + 1) / n2)
    for sx in (-1, 1):
        x0, x1 = (5.0, 6.4) if sx > 0 else (-6.4, -5.0)
        bx(S, x0, x1, 21.6, 24.4, Z_L1, Z_T2 + 0.5)
        bx(S, x0 - 0.1, x1 + 0.1, 21.6, 22.4, Z_T2 + 0.5, Z_T2 + 1.1)
    # --- 4. galeria de sus: inel pe z = 8 ----------------------------------------------
    Z8 = Z_T2
    U_W0, U_W1, U_COL = 16.2, 17.5, 19.6
    ZC2 = Z8 + 3.0
    PROF2 = [(3.9, 0.20), (3.95, 0.65), (3.0, 1.30), (2.1, 1.85), (1.1, 2.30), (0.4, 2.45)]
    SHR2 = [0.0, 0.1, 0.7, 1.3, 1.8, 2.1]
    gallery_ring(17.0, U_W0, U_W1, U_COL, Z8, ZC2, True, True, 200, col_step=2.4, corner=3.5,
                 door=5.0, roof_prof=PROF2, shr=SHR2)
    for k in range(4):
        # portic de axa: stalpi, buiandrug, fronton ascutit deasupra acoperisului
        for u in (-3.6, -1.2, 1.2, 3.6):
            rcol(S, k, u, U_COL + 0.3, Z8 + 0.35, ZC2, cw=0.65)
        rbox(S, k, -4.4, 4.4, U_COL - 0.6, U_COL + 1.0, ZC2, ZC2 + 0.4)
        rgable(S, k, 0.0, U_COL - 1.2, U_COL + 0.8, ZC2 + 0.4, 4.6, ZC2 + 0.4 + 4.0)
        rgable(S, k, 0.0, U_COL + 0.8, U_COL + 1.05, ZC2 + 0.4, 3.7, ZC2 + 0.4 + 3.2)
        rbox(S, k, -4.4, 4.4, U_COL - 0.5, U_COL + 1.1, Z8 + 0.0, Z8 + 0.35)
    # pe +Y portul ramane deschis la scara (stalpii de mai sus stau la |u| <= 3,6: se scot coloanele din gol)

    # pavilioane de colt: bloc 7 x 7 din care creste turnul, cu cornisa
    ZCP = Z8 + 3.4
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx_, cy_ = sx * CORNER, sy * CORNER
            bx(S, cx_ - 3.9, cx_ + 3.9, cy_ - 3.9, cy_ + 3.9, Z8, ZCP)
            wall_faces(S, cx_ - 3.9, cx_ + 3.9, cy_ - 3.9, cy_ + 3.9, Z8, ZCP, ["+y", "-y", "+x", "-x"],
                       ch=1.1, bw=2.4, seed=90 + sx + 2 * sy)
            bx(S, cx_ - 4.1, cx_ + 4.1, cy_ - 4.1, cy_ + 4.1, ZCP, ZCP + 0.4)
            sites.append((cx_ - 4.1, cx_ + 4.1, cy_ - 4.1, cy_ + 4.1, ZCP + 0.4))
            # finialuri de colt pe cornisa
            for dx in (-1, 1):
                for dy in (-1, 1):
                    c = Vector((cx_ + dx * 3.95, cy_ + dy * 3.95, ZCP + 0.4))
                    pts = [c + Vector((a * 0.2, b_ * 0.2, 0.0)) for a in (-1, 1) for b_ in (-1, 1)]
                    pts += [c + Vector((a * 0.1, b_ * 0.1, 0.8)) for a in (-1, 1) for b_ in (-1, 1)]
                    hull(S, pts, ANK_STONE)
    # turnurile de colt: baza z = ZCP + 0,4
    zk = ZCP + 0.4
    for sx in (-1, 1):
        for sy in (-1, 1):
            tower(S, sx * CORNER, sy * CORNER, zk, 3.8, 1.2,
                  [(4.2, 3.0), (3.7, 2.8), (3.2, 2.6), (2.7, 2.4), (2.2, 2.2)], TOP_K, 1.8)

    # --- 5. platforma centrala: trepte pana la Z_CEN, scara pe +Y -----------------------
    cen = [(Z8, 10.0, 10.5), (10.0, 12.0, 9.3), (12.0, Z_CEN, 8.2)]
    for i, (z0, z1, h) in enumerate(cen):
        bx(S, -h, h, -h, h, z0, z1)
        wall_faces(S, -h, h, -h, h, z0, z1, ["+y", "-y", "+x", "-x"], ch=1.2, bw=2.6, seed=120 + i)
    sites.append((-10.5, 10.5, 9.3, 10.5, 10.0)); sites.append((-10.5, 10.5, -10.5, -9.3, 10.0))
    sites.append((-9.3, 9.3, 7.5, 9.3, 12.0)); sites.append((-9.3, 9.3, -9.3, -7.5, 12.0))
    # scara centrala pe +Y: de la y = 15,2 (z = 8) la y = 10,3 (z = 14): 12 trepte
    n3 = 12
    for i in range(n3):
        yb = 15.2 - (4.9 / n3) * i
        ya = 15.2 - (4.9 / n3) * (i + 1)
        bx(S, -3.6, 3.6, ya, yb, Z8, Z8 + (Z_CEN - Z8) * (i + 1) / n3)
    for sx in (-1, 1):
        x0, x1 = (3.6, 5.0) if sx > 0 else (-5.0, -3.6)
        bx(S, x0, x1, 10.0, 15.4, Z8, Z8 + 3.4)
        bx(S, x0 - 0.1, x1 + 0.1, 10.0, 11.0, Z8 + 3.4, Z8 + 4.0)

    # turnul central (0, 0), varf la +36
    tower(S, 0.0, 0.0, Z_CEN, 6.2, 1.2,
          [(6.3, 3.0), (5.7, 2.9), (5.1, 2.8), (4.4, 2.7), (3.7, 2.6), (3.0, 2.5)], TOP_C, 2.3)

    # --- lichen si dare ------------------------------------------------------------------
    scatter_lichen(L, sites, 80, 36, seed=41)
    rnd = lcg(53)
    for (k, u0, u1, w, z_top, n, lmin, lmax) in streaks:
        fr = fr_of(k)
        for _ in range(n):
            u = u0 + (u1 - u0) * rnd()
            p = fr.p(u, w, 0.0)
            streak(G, (p.x, p.y, z_top - 0.02), 90.0 * k, 0.16 + 0.10 * rnd(),
                   lmin + (lmax - lmin) * rnd(), 0.025, ANK_STREAK)
    return [S.to_object("Temple_Stone"), L.to_object("Temple_Lichen"), G.to_object("Temple_Streak")]


def emit_temple():
    objs = build_temple()
    emit_angkor(objs, "structures/angkor_wat_temple.glb", AO_TEMPLE, bevel=0.0,
                bevels={"_Lichen": 0.0, "_Streak": 0.0}, smooth_angle=55.0, anchor=(0.0, 0.0))
    clear_built()


emit_temple()
report_angkor()
