"""Vocabular de NATURA pentru kitul Transfagarasan (Track21) -- grupa tf-b
(stanci si plante). Contract: docs/asset_briefs/transfagarasan_kit.md §0 (regulile
7 si 8), §1.4, §1.5.

Se incarca DUPA `transfagarasan_shapes.py` (care aduce dio_lib, monument_shapes si
sloturile TF_*):

    exec(open(os.path.join(_here, "transfagarasan_shapes.py")).read())
    exec(open(os.path.join(_here, "tf_shapes_nature.py")).read())

Fisier NOU, separat de `transfagarasan_shapes.py`, ca sa nu se calce cu tf-a (care
are in shapes stub-ul `schist_blade` si o lama minima pentru portalul de stanca).
La integrare, `schist_blade` din shapes se unifica pe `schist_slab` de aici:
numele sunt DIFERITE intentionat, ca un build care incarca ambele fisiere sa nu
primeasca in tacere alta semnatura.

=== SIST (regulile 7 si 8) ===================================================

Sistul se citeste pe LAME (foliatia, toate in aceeasi directie pe o piesa) si pe
DOUA TONURI: suprafata (nodul *_Schist, MARBLE_GREY 29 -> clasa tf_schist) si
FISURILE dintre lame (nod separat *_Crack, VOLCANIC_BLACK 20, benzi inguste).
Fisura NU poate sta in nodul *_Schist: clasa e material_override si sterge
sloturile (memoria clase-pe-piese-de-kit). ROCK_DARK e interzis (rugina).

  SchistFrame(origin, axis_deg)
        cadrul unei piese: s = directia ORIZONTALA in care coboara fata lunga a
        lamelor (sensul foliatiei), v = grosimea lamei (normala orizontala,
        v = +90 grade fata de s), z sus. `.w(s, v, z)` -> Vector in lume.
        Toate lamele unei piese folosesc ACELASI cadru => aceeasi directie.

  slab_profile(foot_s, height, back_lean=6, dip=52, tip_cut=0.25, belly=0.0,
               tip_w=0.0)
        conturul (s, z) al unei lame, convex: piciorul fetei abrupte (spatele) la
        foot_s, fata abrupta aplecata `back_lean` grade fata de verticala pana la
        varf, varful TESIT (`tip_cut` m pe ambele fete), fata lunga (planul de
        foliatie vazut din lateral) coborand la `dip` grade FATA DE ORIZONTALA
        pana la sol; `belly` umfla mijlocul fetei lungi (ramane convex).
        Latimea pe s = height*tan(back_lean) + height/tan(dip).
        `tip_w` > 0: varful e o FATA RUPTA plana de cel putin tip_w m (decuparea
        are capete tesite, nu varf de cutit), iar `height` e cota fetei rupte.

  foliation_stack(s0, dip, specs, gap=0.15, tip_cut=0.2, tip_w=0.0)
                  -> (profiles, cracks)
        STIVA "CARTI APLECATE" (folosita de toate trei aflorimentele): placi
        paralele cu foliatia (`dip` fata de orizontala), asezate una PESTE alta
        pe normala planului; specs = [(h, t, back_lean), ...], placa 0 e pana de
        baza (slab_profile), urmatoarele au grosimea t si varful la h. Varfurile
        coboara in trepte; fiecare iese ~t/cos(dip) peste fata celei de dinainte.
        Intoarce conturul (s, z) al fiecarei placi si conturul fisurii DIAGONALE
        de sub fiecare placa (de la fata ei abrupta pana la sol). Latimea pe s
        creste cu (t + gap)/sin(dip) per placa -- de aici dip-ul abrupt la a.

  crack_strip(bc, fr, poly, v_a, v_b, slot=TF_CRACK)
        extrudeaza pe v o fisura din `foliation_stack` (intre v_a si v_b, putin
        in interiorul fetelor -> rost adancit, nu dunga pictata).

  schist_slab(b, fr, prof, v0, thick, slot=TF_SCHIST, ridge=0.10, taper=0.35,
              seed=0, jit=0.05, back_taper=0.0, v_drop=0.0)
        LAMA: invelitoare convexa (fete plane, mari) a conturului extrudat pe v
        intre v0 (fata din fata) si v0+thick (spatele). Spatele e PLAN = planul de
        foliatie pe care se sprijina lama urmatoare si fisura. Fata din fata se
        subtiaza spre varf (`taper` x thick) si are o COAMA pe axa lamei (iese
        `ridge` m) -> 2-3 fatete mari, ca pe plansa. Jitter-ul merge doar spre +v
        (nu inchide fisura). `back_taper` > 0 subtiaza si spatele spre varf, iar
        `v_drop` coboara conturul de pe spate (lama e pana din lateral, nu
        cutie); ramai la 0 cand alta lama sta lipita in spatele ei.
        Intoarce fetele.

  crack_between(bc, fr, prof_front, prof_back, v_plane, gap, grow=0.16,
                slot=TF_CRACK)
        FISURA dintre doua lame stivuite pe v (lama din fata se termina la
        v_plane, cea din spate incepe la v_plane+gap): placa subtire in golul
        dintre ele, pe INTERSECTIA contururilor, cu conturul lamei din fata
        CRESCUT cu `grow` -> pe fata lamei din spate apare o banda inchisa de
        `grow` m de-a lungul muchiei lamei din fata (umbra de rost), iar in gol se
        vede negru. Placa sta intre v_plane-0,04 si v_plane+0,6*gap (nu atinge
        coama lamei din spate). Benzi INGUSTE, nu suprafata mare (regula 8).

  crack_hull(bc, fr, pts_svz, slot=TF_CRACK)
        fisura cu forma data explicit (puncte (s, v, z)), pentru crapaturi care nu
        sunt intre lame stivuite (acul `schist_outcrop_c`, crapat pe lung).

  schist_chip(b, fr, s, v, size, dip=40, yaw=0, seed=0, slot=TF_SCHIST, sink=0.25)
        bloc de picior / piatra de grohotis: lespede PLATA (L x W x T) cu fata
        mare inclinata pe foliatie (`dip` pe s, plus `yaw` in plan), colturi
        jitter-ate, ingropata `sink` x T si taiata plat la z = 0.

  slab_stone(b, center, size, normal=(0,0,1), spin=0, seed=0, slot=TF_SCHIST,
             zmin=0.0, ymin=None)
        piatra PLATA de grohotis culcata pe panta (axa subtire pe `normal`),
        taiata la sol (z >= zmin) si la perete (y >= ymin).

  cut_profile(poly, s_max, lean_deg=20)
        taie un contur (s, z) cu o fractura abrupta la capatul din aval
        (creste lungi pe foliatie culcata, `schist_outcrop_b`).

  foot_rubble(b, fr, foot_sv, n, seed=0, size=(0.3, 1.2), slot=TF_SCHIST,
              out=(-0.15, 0.25))
        MOLOZ la piciorul stancii: n lespezi de marimi diferite pe perimetrul
        amprentei (puncte (s, v)), iesite in afara, aplecate spre afara, pe
        jumatate ingropate -- stanca nu mai pare infipta in sol.

  hull(b, pts, slot)
        invelitoarea convexa a unor puncte, pe un slot (baza tuturor de mai sus).

=== PLANTE ==================================================================

  clump(b, c, size, slot, seed=0, seg=6, rings=3, dev=0.18, yaw=None, tilt=0.3)
        ciorchine fatetat (elipsoid inchis, perturbat, rotit aleator): unitatea
        de frunzis. 2*seg*rings triunghiuri (36 la 6x3).
  branch(b, pts, r0, r1, slot, seg=6)
        ramura / trunchi conic pe traseu (taper_sweep cu raze interpolate).
  needle_pad(b, base, azim_deg, length, width, height, slot, seed=0, teeth=3,
             pitch=6, ridge=0.05, roll=0, notch=0.62)
        PERNA DE ACE de jneapan: PLACA PLATA alungita pe ramura (ca o frunza de
        feriga), margine zimtata pe lung, capete ascutite, fata de sus bombata,
        capatul ridicat cu `pitch` grade. 4*(4*teeth+2) tri (56 la teeth=3).
  crown_mass(b, center, radii, slot, seed=0, n=9, clump_size=1.4, el_lo=-0.25,
             core=True, squash=1.0, core_scale=0.88)
        MASA DE COROANA de foios: miez elipsoidal (88%) + n ciorchini mari pe
        suprafata lui (doar deasupra elevatiei `el_lo`), conturul zimtat de
        ciorchini fatetati, ca pe plansa fagului; `squash` < 1 turteste
        ciorchinii (lobi mai lati decat inalti, nu bule); `core_scale` mai mic
        (si ridicat) lasa goluri pe dedesubt prin care se vad bratele.

Axe ca in tot kitul: X latime, Y adancime (fata spre +Y in Blender = -Z in
Godot), Z sus.
"""

import math
from mathutils import Vector, Matrix

TF_CRACK = VOLCANIC_BLACK      # 20: fisurile dintre lame (regula 8), nod *_Crack
TF_BARK_GREY = MARBLE_GREY     # 29: scoarta neteda, gri, a fagului
TF_LEAF = TROPICAL_GREEN       # 21: coroana fagului, frunzisul bujorului / afinului
TF_NEEDLES = LOG_DARK          # 28: acele jneapanului (clasa pine_needles, *_Needles)
TF_WOOD = WOOD                 # 9:  ramurile jneapanului
TF_BLOOM = FLAMINGO_PINK       # 31: florile bujorului (--allow-slots=31)
TF_BERRY = ICE_DEEP            # 25: bobitele de afin


def _rnd(seed):
    """LCG determinist (nu consuma random-ul global)."""
    state = [(int(seed) * 1103515245 + 12345) & 0x7FFFFFFF]

    def r():
        state[0] = (state[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return state[0] / float(0x7FFFFFFF)
    return r


def hull(b, pts, slot):
    """Invelitoarea convexa a punctelor `pts`, toate fetele pe `slot`."""
    vs = [b.bm.verts.new(Vector(p)) for p in pts]
    res = bmesh.ops.convex_hull(b.bm, input=vs)
    junk = {g for g in list(res["geom_interior"]) + list(res["geom_unused"])
            if isinstance(g, bmesh.types.BMVert) and g.is_valid}
    if junk:
        bmesh.ops.delete(b.bm, geom=list(junk), context="VERTS")
    out = []
    for f in res["geom"]:
        if isinstance(f, bmesh.types.BMFace) and f.is_valid:
            f[b.slot] = slot
            out.append(f)
    return out


# ---------------------------------------------------------------------------
# sist
# ---------------------------------------------------------------------------

class SchistFrame:
    """Cadrul (s, v, z) al unei piese de sist; vezi docstring-ul modulului."""

    def __init__(self, origin=(0.0, 0.0, 0.0), axis_deg=0.0):
        a = math.radians(axis_deg)
        self.o = Vector(origin)
        self.d = Vector((math.cos(a), math.sin(a), 0.0))
        self.n = Vector((-math.sin(a), math.cos(a), 0.0))

    def w(self, s, v, z):
        return self.o + self.d * s + self.n * v + Vector((0.0, 0.0, z))


def _tip_len(u_back, u_long, tip_cut, tip_w):
    """Cat se taie din varf pe fiecare fata ca fata rupta (coarda t1-t2) sa aiba
    cel putin `tip_w` m. u_back / u_long = directiile din varf in jos pe cele
    doua fete (unitare)."""
    ch = (u_long - u_back).length
    return max(tip_cut, tip_w / ch) if ch > 1e-6 else tip_cut


def slab_profile(foot_s, height, back_lean=6.0, dip=52.0, tip_cut=0.25, belly=0.0,
                 tip_w=0.0):
    bl, dl = math.radians(back_lean), math.radians(dip)
    u_back = Vector((-math.sin(bl), -math.cos(bl)))
    u_long = Vector((math.cos(dl), -math.sin(dl)))
    d = _tip_len(u_back, u_long, tip_cut, tip_w)
    # cota ceruta (`height`) e a FETEI RUPTE, nu a varfului teoretic
    height = height + d * min(math.cos(bl), math.sin(dl)) if tip_w > 0 else height
    tip_cut = d
    tip = Vector((foot_s + height * math.tan(math.radians(back_lean)), height))
    end = Vector((tip.x + height / math.tan(math.radians(dip)), 0.0))
    foot = Vector((foot_s, 0.0))
    up = (tip - foot).normalized()
    down = (end - tip).normalized()
    t1 = tip - up * tip_cut
    t2 = tip + down * tip_cut
    pts = [foot, t1, t2]
    if belly:
        mid = (t2 + end) * 0.5
        nrm = Vector((-down.y, down.x))          # normala exterioara (sus-dreapta)
        if nrm.y < 0:
            nrm = -nrm
        pts.append(mid + nrm * belly)
    pts.append(end)
    return [(p.x, p.y) for p in pts]


def foliation_stack(s0, dip, specs, gap=0.15, tip_cut=0.2, tip_w=0.0):
    """STIVA DE LAME pe foliatie ("carti aplecate"): lame-placi PARALELE cu
    planul de foliatie (inclinat `dip` grade fata de orizontala, coborand spre
    +s), asezate una PESTE alta pe normala planului, fiecare taiata de o fata
    abrupta in spate, varfurile coborand in trepte spre +s. Fisurile ies
    DIAGONALE, paralele cu fetele lungi (ca pe plansa).

    `specs` = [(h, t, back_lean), ...]: lama 0 e PANA DE BAZA (de la s0, varf la
    h0, t ignorat), lamele 1.. stau pe ea, fiecare groasa de `t` m (pe normala
    planului), cu varful la `h`. Intre lame: `gap` m.
    Intoarce (profiles, cracks): conturul (s, z) al fiecarei lame si conturul
    fiecarei fisuri (fasia de gol de sub lama k, de la fata ei abrupta la sol,
    ingropata 0,04 m in ambele lame). Pentru extrudare pe v: `schist_slab` si
    `crack_hull`/`crack_strip`.
    `tip_w` > 0: fiecare varf e TESIT (fata rupta, plana) de cel putin tip_w m,
    iar `h` din specs e cota fetei rupte (varful teoretic se ridica)."""
    dl = math.radians(dip)
    sd, cd = math.sin(dl), math.cos(dl)
    h0, _t0, bl0 = specs[0]
    prof0 = slab_profile(s0, h0, back_lean=bl0, dip=dip, tip_cut=tip_cut, tip_w=tip_w)
    b0 = math.radians(bl0)
    d0 = _tip_len(Vector((-math.sin(b0), -math.cos(b0))), Vector((cd, -sd)), tip_cut, tip_w)
    if tip_w > 0:
        h0 = h0 + d0 * min(math.cos(b0), sd)
    s_tip0 = s0 + h0 * math.tan(math.radians(bl0))
    U = s_tip0 * sd + h0 * cd                   # planul de sus al lamei 0
    profiles, cracks = [prof0], []
    for (h, t, bl) in specs[1:]:
        c = U + gap
        U2 = c + t
        bb = math.radians(bl)
        down = Vector((-math.sin(bb), -math.cos(bb)))
        dk = _tip_len(down, Vector((cd, -sd)), tip_cut, tip_w)
        if tip_w > 0:
            h = h + dk * min(math.cos(bb), sd)
        B = Vector(((U2 - h * cd) / sd, h))
        cosdb = math.cos(dl - bb)

        def on_back(plane):
            lam = (U2 - plane) / cosdb
            p = B + down * lam
            if p.y < 0.0:                       # fata abrupta atinge solul inainte
                lam = B.y / math.cos(bb)
                p = B + down * lam
            return p
        E = on_back(c)
        up = -down
        dn = Vector((math.cos(dl), -math.sin(dl)))
        t1 = B - up * dk
        t2 = B + dn * dk
        C = Vector((U2 / sd, 0.0))
        D = Vector((c / sd, 0.0))
        prof = [E, t1, t2, C]
        if E.y > 1e-4:
            prof.append(D)
        else:
            prof = [Vector((E.x, 0.0)), t1, t2, C]
        profiles.append([(p.x, p.y) for p in prof])
        # fisura: fasia dintre planul U (lama de dedesubt) si c, sub lama curenta
        lo, hi = U - 0.04, c + 0.04
        F_lo, F_hi = on_back(lo), on_back(hi)
        poly = [F_lo, F_hi, Vector((hi / sd, 0.0)), Vector((lo / sd, 0.0))]
        cracks.append([(p.x, max(p.y, 0.0)) for p in poly])
        U = U2
    return profiles, cracks


def cut_profile(poly, s_max, lean_deg=20.0):
    """Taie un contur (s, z) cu o fata abrupta la capatul din aval: pastreaza
    s <= s_max - z*tan(lean) (fractura de capat, aplecata spre corpul piesei).
    Pentru creste lungi pe foliatie culcata, unde fata lunga a ultimei lame ar
    cobori prea departe."""
    k = math.tan(math.radians(lean_deg))
    out = _clip_half(poly, -1.0, -k, s_max)
    return out if len(out) >= 3 else []


def crack_strip(bc, fr, poly, v_a, v_b, slot=TF_CRACK):
    """Extrudeaza pe v (intre v_a si v_b) conturul (s, z) al unei fisuri din
    `foliation_stack`. v_a/v_b se aleg putin IN INTERIORUL fetelor lamelor
    (0,06 m), ca fisura sa se vada ca rost adancit, nu ca dunga pictata."""
    pts = []
    for (s, z) in poly:
        pts.append(fr.w(s, v_a, z))
        pts.append(fr.w(s, v_b, z))
    return hull(bc, pts, slot)


def schist_slab(b, fr, prof, v0, thick, slot=TF_SCHIST, ridge=0.10, taper=0.35,
                seed=0, jit=0.05, back_taper=0.0, v_drop=0.0):
    """Vezi docstring-ul modulului. `back_taper` (implicit 0 = spate PLAN, cerut
    cand o lama sta lipita in spatele ei) subtiaza si spatele spre varf;
    `v_drop` coboara conturul de pe spate cu acea fractie (varful e mai inalt
    in fata decat in spate) -> din lateral lama e o pana, nu o cutie."""
    r = _rnd(seed)
    zs = [p[1] for p in prof]
    zlo, zhi = min(zs), max(zs)
    span = max(zhi - zlo, 1e-6)
    # ATENTIE: coama iese spre -v; daca in fata lamei sta alta lama la distanta
    # `gap`, tine ridge < gap (altfel coama strapunge lama din fata).
    pts = []
    for (s, z) in prof:
        t = (z - zlo) / span
        pts.append(fr.w(s, v0 + thick * taper * t + jit * r(), z))
        zb = zlo + (z - zlo) * (1.0 - v_drop)
        tb = (zb - zlo) / span
        pts.append(fr.w(s, v0 + thick - thick * back_taper * tb, zb))
    # axa lamei: de la mijlocul bazei la varf
    base_pts = [p for p in prof if p[1] <= zlo + 1e-6]
    bs = sum(p[0] for p in base_pts) / len(base_pts)
    top = max(prof, key=lambda p: p[1])
    for f in (0.30, 0.66):
        s = bs + (top[0] - bs) * f
        z = zlo + span * f
        pts.append(fr.w(s, v0 + thick * taper * f - ridge, z))
    return hull(b, pts, slot)


def _clip_half(poly, a, b_, c):
    """Sutherland-Hodgman: pastreaza a*s + b*z + c >= 0."""
    out = []
    n = len(poly)
    for i in range(n):
        p, q = poly[i], poly[(i + 1) % n]
        fp = a * p[0] + b_ * p[1] + c
        fq = a * q[0] + b_ * q[1] + c
        if fp >= 0:
            out.append(p)
        if (fp >= 0) != (fq >= 0):
            t = fp / (fp - fq)
            out.append((p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
    return out


def _ccw(poly):
    area = 0.0
    for i in range(len(poly)):
        x0, y0 = poly[i]
        x1, y1 = poly[(i + 1) % len(poly)]
        area += x0 * y1 - x1 * y0
    return poly if area > 0 else list(reversed(poly))


def _clip_convex(subject, clip):
    """Intersectia a doua poligoane convexe (s, z)."""
    clip = _ccw(clip)
    out = list(subject)
    for i in range(len(clip)):
        p, q = clip[i], clip[(i + 1) % len(clip)]
        # stanga muchiei p->q (CCW) = interior
        a = -(q[1] - p[1])
        b_ = q[0] - p[0]
        c = -(a * p[0] + b_ * p[1])
        out = _clip_half(out, a, b_, c)
        if len(out) < 3:
            return []
    return out


def _offset_convex(poly, d):
    """Deplaseaza fiecare muchie a unui poligon convex cu `d` spre exterior
    (d < 0: spre interior); colturile prin intersectia muchiilor vecine."""
    poly = _ccw(poly)
    n = len(poly)
    lines = []
    for i in range(n):
        p, q = Vector(poly[i]), Vector(poly[(i + 1) % n])
        e = (q - p).normalized()
        nrm = Vector((e.y, -e.x))               # exterior pentru CCW
        lines.append((p + nrm * d, e))
    out = []
    for i in range(n):
        (p0, e0), (p1, e1) = lines[i - 1], lines[i]
        den = e0.x * e1.y - e0.y * e1.x
        if abs(den) < 1e-9:
            out.append((p1.x, p1.y))
            continue
        t = ((p1.x - p0.x) * e1.y - (p1.y - p0.y) * e1.x) / den
        x = p0 + e0 * t
        out.append((x.x, x.y))
    return out


def crack_between(bc, fr, prof_front, prof_back, v_plane, gap, grow=0.16,
                  slot=TF_CRACK):
    poly = _clip_convex(_offset_convex(prof_front, grow), _offset_convex(prof_back, -0.05))
    if len(poly) < 3:
        return []
    poly = _clip_half(poly, 0.0, 1.0, -0.02)    # z >= 0,02
    if len(poly) < 3:
        return []
    pts = []
    for (s, z) in poly:
        pts.append(fr.w(s, v_plane - 0.04, z))
        pts.append(fr.w(s, v_plane + gap * 0.6, z))
    return hull(bc, pts, slot)


def crack_hull(bc, fr, pts_svz, slot=TF_CRACK):
    return hull(bc, [fr.w(s, v, z) for (s, v, z) in pts_svz], slot)


def schist_chip(b, fr, s, v, size, dip=40.0, yaw=0.0, seed=0, slot=TF_SCHIST,
                sink=0.25):
    r = _rnd(seed)
    L, W, T = size
    rot = (Matrix.Rotation(math.radians(yaw), 3, "Z")
           @ Matrix.Rotation(math.radians(dip), 3, "Y"))
    # cadrul piesei: s pe d, v pe n
    to_world = Matrix(((fr.d.x, fr.n.x, 0.0), (fr.d.y, fr.n.y, 0.0), (0.0, 0.0, 1.0)))
    loc = []
    for ix in (-1, 1):
        for iy in (-1, 1):
            for iz in (-1, 1):
                k = 0.78 + 0.22 * r()
                loc.append(Vector((ix * L * 0.5 * k, iy * W * 0.5 * (0.8 + 0.2 * r()),
                                   iz * T * 0.5 * (0.85 + 0.15 * r()))))
    # doua puncte de mijloc pe fata de sus: fatete
    loc.append(Vector(((r() - 0.5) * L * 0.4, (r() - 0.5) * W * 0.4, T * 0.62)))
    loc.append(Vector(((r() - 0.5) * L * 0.5, W * 0.52, (r() - 0.5) * T * 0.3)))
    pts = [to_world @ (rot @ p) for p in loc]
    zmin = min(p.z for p in pts)
    lift = -zmin - T * sink
    base = fr.w(s, v, 0.0)
    out = []
    for p in pts:
        q = p + base + Vector((0.0, 0.0, lift))
        q.z = max(q.z, 0.0)
        out.append(q)
    return hull(b, out, slot)


def slab_stone(b, center, size, normal=(0.0, 0.0, 1.0), spin=0.0, seed=0,
               slot=TF_SCHIST, zmin=0.0, ymin=None):
    """Piatra PLATA de sist (grohotis): lespede L x W x T cu colturi jitter-ate,
    culcata pe o panta -- axa ei subtire pe `normal`, rotita `spin` grade in
    jurul normalei -- cu centrul in `center`. Taiata plat la z >= zmin si, daca
    `ymin` e dat, la y >= ymin (latura lipita de peretele de stanca)."""
    r = _rnd(seed)
    L, W, T = size
    loc = []
    for ix in (-1, 1):
        for iy in (-1, 1):
            for iz in (-1, 1):
                k = 0.72 + 0.28 * r()
                loc.append(Vector((ix * L * 0.5 * k, iy * W * 0.5 * (0.75 + 0.25 * r()),
                                   iz * T * 0.5 * (0.8 + 0.2 * r()))))
    loc.append(Vector(((r() - 0.5) * L * 0.5, (r() - 0.5) * W * 0.5, T * 0.6)))
    nz = Vector(normal).normalized()
    q = Vector((0.0, 0.0, 1.0)).rotation_difference(nz)
    rot = q.to_matrix() @ Matrix.Rotation(math.radians(spin), 3, "Z")
    c = Vector(center)
    pts = []
    for p in loc:
        w = c + rot @ p
        w.z = max(w.z, zmin)
        if ymin is not None:
            w.y = max(w.y, ymin)
        pts.append(w)
    return hull(b, pts, slot)


def _hull2d(pts):
    pts = sorted(set((round(x, 4), round(y, 4)) for x, y in pts))
    if len(pts) < 3:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, hi = [], []
    for p in pts:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0:
            lo.pop()
        lo.append(p)
    for p in reversed(pts):
        while len(hi) >= 2 and cross(hi[-2], hi[-1], p) <= 0:
            hi.pop()
        hi.append(p)
    return lo[:-1] + hi[:-1]


def foot_rubble(b, fr, foot_sv, n, seed=0, size=(0.3, 1.2), slot=TF_SCHIST, out=(-0.15, 0.25)):
    """MOLOZ la piciorul unei stanci (memoria patru-defecte-de-diorama: obiectul
    nu are voie sa para infipt in sol): `n` lespezi de marimi DIFERITE (size =
    (min, max) pe latura lunga), asezate de jur imprejurul amprentei (`foot_sv`
    = puncte (s, v) ale bazei), cate una pe un arc egal al perimetrului, la
    `out` m de muchie (negativ = sprijinite pe stanca), aplecate spre afara
    15-40 grade, BLOCURI (grosimea 45-70% din latura) ingropate ~20%. Marimile
    alterneaza mare / mediu / mic ca sa nu iasa un sirag."""
    r = _rnd(seed)
    poly = _hull2d(foot_sv)
    m = len(poly)
    segs = []
    tot = 0.0
    for i in range(m):
        a, c = Vector(poly[i]), Vector(poly[(i + 1) % m])
        segs.append((a, c, tot))
        tot += (c - a).length
    cs = sum((Vector(p) for p in poly), Vector((0.0, 0.0))) / m
    faces = []
    for k in range(n):
        t = (k + 0.2 + 0.6 * r()) / n * tot
        for (a, c, t0) in segs:
            L = (c - a).length
            if t0 <= t <= t0 + L:
                p = a.lerp(c, (t - t0) / max(L, 1e-6))
                break
        outv = (p - cs).normalized()
        # marimi alternate: mare / mediu / mic (nu un sirag de pietre egale)
        tier = (0.65 + 0.35 * r(), 0.3 + 0.25 * r(), 0.05 + 0.2 * r())[k % 3]
        Ls = size[0] + (size[1] - size[0]) * tier
        q = p + outv * (out[0] + (out[1] - out[0]) * r() + Ls * 0.15)
        w = fr.w(q.x, q.y, 0.0)
        o3 = fr.d * outv.x + fr.n * outv.y
        # sprijinite de stanca: fata de sus privind in afara 15-40 grade
        tilt = math.radians(15.0 + 25.0 * r())
        nrm = Vector((0.0, 0.0, math.cos(tilt))) + o3 * math.sin(tilt)
        # BLOCURI, nu dale: grosimea 45-70% din latura lunga
        sz = (Ls, Ls * (0.6 + 0.25 * r()), Ls * (0.45 + 0.25 * r()))
        faces += slab_stone(b, w + Vector((0.0, 0.0, sz[2] * 0.32)), sz, nrm,
                            spin=r() * 180.0, seed=seed * 50 + k, slot=slot)
    return faces


# ---------------------------------------------------------------------------
# plante
# ---------------------------------------------------------------------------

def clump(b, c, size, slot, seed=0, seg=6, rings=3, dev=0.18, yaw=None, tilt=0.3):
    r = _rnd(seed + 7)
    faces = b.boulder(tuple(c), tuple(size), slot, seed=seed, segments=seg, rings=rings,
                      deviation=dev)
    verts = set()
    for f in faces:
        verts.update(f.verts)
    a = r() * 2.0 * math.pi if yaw is None else math.radians(yaw)
    rot = (Matrix.Rotation(a, 3, "Z")
           @ Matrix.Rotation((r() - 0.5) * tilt, 3, "X")
           @ Matrix.Rotation((r() - 0.5) * tilt, 3, "Y"))
    cv = Vector(c)
    for v in verts:
        v.co = cv + rot @ (v.co - cv)
    return faces


def branch(b, pts, r0, r1, slot, seg=6):
    n = len(pts)
    radii = [r0 + (r1 - r0) * (i / float(n - 1)) for i in range(n)]
    return b.taper_sweep(pts, radii, slot, segments=seg)


def needle_pad(b, base, azim_deg, length, width, height, slot, seed=0, teeth=3,
               pitch=6.0, ridge=0.05, roll=0.0, notch=0.62):
    """PERNA DE ACE de jneapan: PLACA PLATA alungita pe directia ramurii, ca o
    frunza de feriga (decuparea), cu marginea ZIMTATA pe lung (`teeth` dinti pe
    fiecare parte), capetele ascutite, groasa `height` (0,15-0,25 m), fata de
    sus usor bombata (`ridge`). Culcata aproape orizontal, capatul ridicat cu
    `pitch` grade; `roll` o inclina in jurul axei ei; `notch` = adancimea
    scobiturilor dintre dinti (fractie din semilatime; mai mic = zimti mai
    adanci). Centrul in `base`.

    Topologie: contur stelat de N = 4*teeth + 2 puncte, evantai sus si jos din
    centru + banda laterala -> 4N triunghiuri (56 la teeth=3). Asa ies multe
    perne mari si putine triunghiuri (jneapanul merge pe MultiMesh)."""
    r = _rnd(seed)
    L, W, T = length, width, height
    outline = [(L * 0.5, 0.0)]
    # partea +w, de la varf spre coada, apoi partea -w inapoi
    for side in (1.0, -1.0):
        pts = []
        for i in range(teeth):
            u0 = 0.5 - (i + 0.25) / (teeth + 0.5)
            u1 = 0.5 - (i + 0.75) / (teeth + 0.5)
            env0 = math.sin(math.pi * (u0 + 0.5)) ** 0.6
            env1 = math.sin(math.pi * (u1 + 0.5)) ** 0.6
            pts.append((L * u0, side * W * 0.5 * env0 * (0.95 + 0.1 * r())))   # dinte
            pts.append((L * u1, side * W * 0.5 * env1 * notch))                 # scobitura
        if side < 0:
            pts = list(reversed(pts))
        outline += pts
        if side > 0:
            outline.append((-L * 0.5, 0.0))
    # outline: varf(+u) -> latura +w -> coada -> latura -w -> inapoi la varf
    a = math.radians(azim_deg)
    rot = (Matrix.Rotation(a, 3, "Z") @ Matrix.Rotation(-math.radians(pitch), 3, "Y")
           @ Matrix.Rotation(math.radians(roll), 3, "X"))
    c = Vector(base)

    def P(u, w, z):
        return b.bm.verts.new(c + rot @ Vector((u, w, z)))
    top = [P(u, w, T * 0.5) for (u, w) in outline]
    bot = [P(u * 0.92, w * 0.85, -T * 0.5) for (u, w) in outline]
    ct = P(0.0, 0.0, T * 0.5 + ridge)
    cb = P(0.0, 0.0, -T * 0.5)
    n = len(outline)
    faces = []
    for i in range(n):
        j = (i + 1) % n
        faces.append(b.bm.faces.new((ct, top[i], top[j])))
        faces.append(b.bm.faces.new((cb, bot[j], bot[i])))
        faces.append(b.bm.faces.new((top[i], bot[i], bot[j], top[j])))
    for f in faces:
        f[b.slot] = slot
    return faces


def crown_mass(b, center, radii, slot, seed=0, n=9, clump_size=1.4, el_lo=-0.25,
               core=True, squash=1.0, core_scale=0.88):
    r = _rnd(seed)
    c = Vector(center)
    rx, ry, rz = radii
    faces = []
    if core:
        k0 = core_scale
        faces += clump(b, c + Vector((0.0, 0.0, rz * (0.88 - k0) * 0.8)),
                       (2 * rx * k0, 2 * ry * k0, 2 * rz * k0), slot,
                       seed=seed, seg=8, rings=4, dev=0.08, tilt=0.15)
    ga = math.pi * (3.0 - math.sqrt(5.0))
    k = 0
    i = 0
    while k < n and i < n * 4:
        zz = 1.0 - (i + 0.5) / (n * 1.6)
        i += 1
        if zz < el_lo:
            continue
        rr = math.sqrt(max(0.0, 1.0 - zz * zz))
        ang = ga * i + seed
        dirv = Vector((rr * math.cos(ang), rr * math.sin(ang), zz))
        p = c + Vector((dirv.x * rx, dirv.y * ry, dirv.z * rz)) * (0.86 + 0.08 * r())
        s = clump_size * (0.8 + 0.4 * r())
        faces += clump(b, p, (s, s, s * (0.78 + 0.2 * r()) * squash), slot,
                       seed=seed * 31 + k, seg=7, rings=3, dev=0.22, tilt=0.35)
        k += 1
    return faces
