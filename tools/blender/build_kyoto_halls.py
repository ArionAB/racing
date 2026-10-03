"""Kyoto -- sala, scena si portile (brief docs/asset_briefs/kyoto_kit.md §1.3).

  kyoto/structures/niomon_gate.glb          poarta Niomon, 2 etaje, ~21 x 13 m
  kyoto/structures/inari_romon.glb          poarta-turn Romon, ~18 x 12 m
  kyoto/structures/kakezukuri_scaffold.glb  modul de schela de lemn 6 x 16 m
  kyoto/structures/kiyomizu_hondo.glb       sala principala, acoperis in patru ape

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_kyoto_halls.py

Directia de mers prin poarta e Y Blender (= -Z Godot); golul se masoara cu
`tools/blender/measure_gap.py` (proiectie pe plan, nu AABB).
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py")).read())

TILE = VOLCANIC_BLACK      # tigla kawara (din atlas, nervuri in geometrie)
BEAM = LOG_DARK            # kasagi, fateta streasinii, goluri
VERM = LAVA_ORANGE         # vermilion sacru
PLASTER = FOAM_WHITE
STONE = CONCRETE
TIMBER = WOOD              # podele, schela

AO_GATE = dict(samples=10, dist=4.0, gradient="vertical",
               low=0.74, high=1.0, power=0.8, floor=0.32)

clear_built()


def _prism_x(b, outline, x0, x1, slot):
    """Prisma extrudata pe X dintr-un contur (y, z) -- profilul frontonului."""
    bm = b.bm
    f0 = [bm.verts.new((x0, y, z)) for (y, z) in outline]
    f1 = [bm.verts.new((x1, y, z)) for (y, z) in outline]
    n = len(outline)
    faces = [bm.faces.new(tuple(reversed(f0))), bm.faces.new(tuple(f1))]
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((f0[i], f0[j], f1[j], f1[i])))
    for f in faces:
        f[b.slot] = slot
    return set(faces)


def _gate(P):
    """Poarta cu doua etaje, comuna Niomon/Romon; parametrii dau ce le
    deosebeste. Travei laterale masive inchise (stalpi grosi, panouri albe),
    gol liber la mijloc, acoperis irimoya (hip jos + fronton triunghiular
    vermilion pe laturile scurte). Intoarce (wood, roof, plaster)."""
    wood, roof, plaster = Builder(), Builder(), Builder()
    xi, xm, xo, pd = P["x_in"], P["x_mid"], P["x_out"], P["post_d"]
    pw = P["post_w"]
    zp, zg, zu, ze = P["post_h"], P["gallery_z"], P["upper_h"], P["eave_z"]

    # --- parter: stalpi grosi pe socluri de piatra ---------------------------
    for sx in (-1, 1):
        for x, w_ in ((xi, pw), (xm, pw * 0.8), (xo, pw)):
            for sy in (-1, 1):
                px, py = sx * x, sy * pd
                wood.box((px, py, 0.25), (w_ + 0.3, w_ + 0.3, 0.5), STONE)
                wood.box((px, py, 0.5 + (zp - 0.5) * 0.5), (w_, w_, zp - 0.5), VERM)
                wood.box((px, py, zp - 0.2), (w_ + 0.18, w_ + 0.18, 0.4), VERM)
    for sy in (-1, 1):
        wood.box((0, sy * pd, zp + 0.2), (2 * xo + pw + 0.6, 0.9, 0.6), BEAM)    # kasagi negru
        wood.box((0, sy * pd, zp - 0.6), (2 * xi, 0.7, 0.55), VERM)               # peste gol
        for sx in (-1, 1):
            cx_ = sx * (xi + xo) * 0.5
            L_ = xo - xi
            wood.box((cx_, sy * pd, zp - 0.6), (L_, 0.7, 0.55), VERM)              # nuki sus
            wood.box((cx_, sy * pd, zp - 2.2), (L_, 0.6, 0.45), VERM)              # nuki mijloc
            wood.box((cx_, sy * pd, 1.0), (L_, 0.6, 0.45), VERM)                   # talpa jos
            wood.box((cx_, sy * pd, zp * 0.5 - 0.3), (L_, 0.6, 0.4), VERM)         # nuki median
    for sx in (-1, 1):
        for x in (xi, xm, xo):
            wood.box((sx * x, 0, zp + 0.05), (0.55, 2 * pd, 0.55), VERM)           # grinzi pe adancime
    # --- panouri albe in travei (jos si sus), pe fata, spate si latura ----------
    for sx in (-1, 1):
        for (xa, xb) in ((xi, xm), (xm, xo)):
            cxp = sx * (xa + xb) * 0.5
            wp = (xb - xa) - (pw + 0.2)
            for sy in (-1, 1):
                yy = sy * (pd + 0.02)
                plaster.box((cxp, yy, (1.25 + zp - 2.45) * 0.5 + 0.0), (wp, 0.16, zp - 3.7), PLASTER)
                plaster.box((cxp, yy, zp - 1.45), (wp, 0.16, 0.95), PLASTER)
        plaster.box((sx * (xo + 0.02), 0, (1.25 + zp - 0.9) * 0.5), (0.16, 2 * pd - pw - 0.3, zp - 2.2), PLASTER)
        if P.get("side_lattice", True):
            wx = sx * (xi + pw * 0.5 + 0.06)
            wood.box((wx, 0, (0.5 + zp - 1.8) * 0.5 + 0.2), (0.1, 2 * pd - pw, zp - 1.8), BEAM)
            for k in range(-3, 4):
                wood.box((wx + sx * 0.06, k * (pd - pw) / 3.5, (0.5 + zp - 1.8) * 0.5 + 0.2),
                         (0.08, 0.14, zp - 1.7), VERM)

    # --- galeria etajului 2 ----------------------------------------------
    gx, gy = P["gallery_hx"], P["gallery_hy"]
    wood.box((0, 0, zg - 0.18), (2 * gx, 2 * gy, 0.36), TIMBER)
    frame_ring(wood, 0, 0, zg - 1.15, gx - 0.15, gy - 0.15, 0.95, 0.7, VERM)
    for sy in (-1, 1):
        wood.pickets((-gx + 0.6, sy * (gy - 0.55), zg - 1.25),
                     (gx - 0.6, sy * (gy - 0.55), zg - 1.25), 1.0,
                     (0.4, 0.4, 0.75), VERM, endpoints=True)
    rh = 1.0
    wood.railing((-gx + 0.2, gy - 0.2, zg), (gx - 0.2, gy - 0.2, zg), rh, 1.3, 0.16, 0.14, VERM, rails=2)
    wood.railing((-gx + 0.2, -gy + 0.2, zg), (gx - 0.2, -gy + 0.2, zg), rh, 1.3, 0.16, 0.14, VERM, rails=2)
    if P.get("gallery_sides", True):
        wood.railing((gx - 0.2, -gy + 0.2, zg), (gx - 0.2, gy - 0.2, zg), rh, 1.3, 0.16, 0.14, VERM, rails=2)
        wood.railing((-gx + 0.2, -gy + 0.2, zg), (-gx + 0.2, gy - 0.2, zg), rh, 1.3, 0.16, 0.14, VERM, rails=2)

    # --- etajul 2: miez alb cu stalpi vermilion, ferestre intunecate -------
    ux, uy = P["upper_hx"], P["upper_hy"]
    uh = zu - zg
    plaster.box((0, 0, zg + uh * 0.5), (2 * ux, 2 * uy, uh), PLASTER)
    wood.box((0, 0, zg + 0.18), (2 * ux + 0.4, 2 * uy + 0.4, 0.36), VERM)
    wood.box((0, 0, zu - 0.2), (2 * ux + 0.5, 2 * uy + 0.5, 0.4), VERM)
    nposts = P["upper_posts"]
    for sy in (-1, 1):
        for k in range(nposts + 1):
            x = -ux + 2 * ux * k / nposts
            wood.box((x, sy * (uy + 0.05), zg + uh * 0.5), (0.85, 0.4, uh), VERM)
    for sx in (-1, 1):
        for y in (-uy, 0, uy):
            wood.box((sx * (ux + 0.05), y, zg + uh * 0.5), (0.4, 0.85, uh), VERM)
    nwin = P["windows"]
    wx0, wx1 = -P["window_span"], P["window_span"]
    for sy in (-1, 1):
        for k in range(nwin):
            x = wx0 + (wx1 - wx0) * (k + 0.5) / nwin
            ww = (wx1 - wx0) / nwin * 0.62
            wood.box((x, sy * (uy + 0.12), zg + uh * 0.55), (ww, 0.12, uh * 0.68), BEAM)
            wood.box((x, sy * (uy + 0.17), zg + uh * 0.55), (0.1, 0.12, uh * 0.68), VERM)
    for sx in (-1, 1):
        wood.box((sx * (ux + 0.12), 0, zg + uh * 0.55), (0.12, 2.2, uh * 0.5), BEAM)

    # --- banda densa de console vermilion cu accente albe sub streasina -------
    frame_ring(wood, 0, 0, ze - 1.05, ux + 0.55, uy + 0.55, 0.4, 0.55, VERM)
    frame_ring(wood, 0, 0, ze - 0.6, ux + 1.4, uy + 1.4, 0.3, 0.55, VERM)
    stp = P["bracket_step"]
    for sy in (-1, 1):
        wood.pickets((-ux - 0.5, sy * (uy + 0.65), ze - 1.25),
                     (ux + 0.5, sy * (uy + 0.65), ze - 1.25), stp, (0.42, 0.42, 0.62), VERM, endpoints=True)
        plaster.pickets((-ux - 0.5 + stp * 0.5, sy * (uy + 0.62), ze - 1.15),
                        (ux + 0.5 - stp * 0.5, sy * (uy + 0.62), ze - 1.15), stp,
                        (0.3, 0.3, 0.3), PLASTER, endpoints=True)
    for sx in (-1, 1):
        wood.pickets((sx * (ux + 0.65), -uy - 0.5, ze - 1.25),
                     (sx * (ux + 0.65), uy + 0.5, ze - 1.25), 1.0,
                     (0.42, 0.42, 0.62), VERM, endpoints=True)

    # --- acoperis irimoya: hip jos (streasina curba) + fronton vermilion sus --
    Rh = P["ridge_half"]
    hip_roof(roof, 0, 0, ze, P["roof_hx"], P["roof_hy"], P["roof_rise"], TILE,
             ridge_half=Rh, lift=P["roof_lift"], thick=0.22, fascia_slot=BEAM,
             tile_step=0.85, rib=0.06, sag=P["roof_sag"], swell=0.25)
    w = P["gable_w"]
    z0 = ze + P["gable_z"]
    r2 = P["gable_rise"]
    Rg = Rh + P["gable_out"]
    zb = ze - 0.6
    pent = [(-w, zb), (w, zb), (w, z0), (0.0, z0 + r2), (-w, z0)]
    for sx in (-1, 1):
        _prism_x(wood, pent, sx * Rg - 0.25, sx * Rg + 0.25, VERM)
        plaster.box((sx * (Rg + 0.27), 0, z0 + r2 * 0.3), (0.1, w * 0.9, r2 * 0.45), PLASTER)
    th = math.atan2(r2, w)
    Ls = math.hypot(w, r2) + 0.9
    plate_t = 0.35
    ov = P["gable_ov"]
    for sy in (-1, 1):
        mid_y = sy * (w * 0.5 + 0.2)
        mid_z = z0 + r2 * 0.5 - 0.2
        nrm = Vector((0, sy * math.sin(th), math.cos(th)))
        c = Vector((0, mid_y, mid_z)) + nrm * (plate_t * 0.5)
        rot = Matrix.Rotation(-sy * th, 3, 'X')
        roof.box(c, (2 * (Rg + ov), Ls, plate_t), TILE, rotation=rot)
        c2 = Vector((0, mid_y, mid_z)) - nrm * 0.02
        roof.box(c2, (2 * (Rg + ov) + 0.1, Ls - 0.1, 0.12), BEAM, rotation=rot)
    top = ze + P["roof_rise"]
    roof.box((0, 0, top + 0.12), (2 * Rh + 0.8, 0.6, 0.45), BEAM)                  # creasta
    for sx in (-1, 1):                                                              # onigawara
        roof.box((sx * (Rh + 0.3), 0, top + 0.5), (0.5, 0.7, 0.7), BEAM)
    return wood, roof, plaster


NIOMON = dict(x_in=7.8, x_mid=10.8, x_out=13.8, post_d=2.7, post_w=1.0, post_h=8.0,
              gallery_z=8.8, gallery_hx=14.5, gallery_hy=4.5, gallery_sides=True,
              upper_h=12.2, upper_hx=13.2, upper_hy=2.5, upper_posts=11, windows=3,
              window_span=4.6, eave_z=12.6, roof_hx=15.0, roof_hy=6.8,
              roof_rise=5.2, ridge_half=9.0, roof_lift=1.1, roof_sag=2.2,
              bracket_step=0.7, gable_w=3.6, gable_z=0.7, gable_rise=3.4,
              gable_out=1.2, gable_ov=1.0)

ROMON = dict(x_in=7.7, x_mid=10.1, x_out=12.5, post_d=2.3, post_w=0.95, post_h=8.4,
             gallery_z=9.2, gallery_hx=13.2, gallery_hy=3.9, gallery_sides=False,
             upper_h=13.0, upper_hx=11.7, upper_hy=2.3, upper_posts=10, windows=4,
             window_span=5.2, eave_z=13.4, roof_hx=14.0, roof_hy=6.0,
             roof_rise=5.0, ridge_half=6.5, roof_lift=1.3, roof_sag=2.3,
             bracket_step=0.6, gable_w=3.4, gable_z=0.7, gable_rise=3.2,
             gable_out=1.2, gable_ov=1.0, side_lattice=False)


def build_niomon_gate():
    """`niomon_gate.png` -- lista de elemente (inainte de modelare):

    - parter: 2 x 2 stalpi vermilion pe socluri de piatra (4 in fata, 4 in
      spate), travee laterala stanga si dreapta cu panou alb in rame vermilion
      si o usa cu zabrele; la mijloc un GOL larg (>= 11 m), cu kasagi negru si
      grinda vermilion deasupra.
    - etaj 2: galerie cu balustrada vermilion pe toate laturile, pe console
      (rand de blocuri sub ea); trup alb cu stalpi vermilion, 3 ferestre
      intunecate pe fiecare fata lunga.
    - acoperis mare gri-inchis in patru ape, streasina larga si curbata in
      sus la colturi, creasta lunga cu onigawara la capete; console vermilion
      sub streasina.
    Cote: ~21 m lat, 13 m inalt, gol >= 11 m, inaltime libera sub grinda ~4,4 m.
    """
    w, r, p = _gate(NIOMON)
    return (w.to_object("Gate_Wood"), r.to_object("Gate_Roof"),
            p.to_object("Gate_Plaster"))


def build_inari_romon():
    """`inari_romon.png` -- lista de elemente (inainte de modelare):

    - parter: stalpi vermilion pe socluri de piatra, travee laterale cu panou
      alb si zabrele vermilion, gol larg la mijloc (>= 11 m).
    - etaj 2 mai inalt si mai ingust decat la Niomon: galerie cu balustrada doar
      pe fata si spate, 4 ferestre intunecate pe fata, trup alb cu stalpi
      vermilion, console dese sub streasina.
    - acoperis gri-inchis in patru ape, creasta SCURTA, panta mai abrupta,
      colturi foarte ridicate; onigawara la capete.
    Cote: ~18 m lat, 12 m inalt, gol >= 11 m.
    """
    w, r, p = _gate(ROMON)
    return (w.to_object("Gate_Wood"), r.to_object("Gate_Roof"),
            p.to_object("Gate_Plaster"))


if __name__ == "__main__" or True:
    objs = build_niomon_gate()
    emit(list(objs), "structures/niomon_gate.glb", AO_GATE, bevel=0.0,
         smooth_angle=None, budget=14000)
    clear_built()
    objs = build_inari_romon()
    emit(list(objs), "structures/inari_romon.glb", AO_GATE, bevel=0.0,
         smooth_angle=None, budget=14000)
    report()


# ---------------------------------------------------------------------------
# kakezukuri_scaffold: modul de schela (lemn), 6 m lat (X) x 6 adanc (Y) x 16 m
# ---------------------------------------------------------------------------

def build_kakezukuri_scaffold():
    """`kakezukuri_scaffold.png` -- lista de elemente (inainte de modelare):

    - retea de stalpi drepti de lemn deschis: 3 randuri pe adancime x 4
      coloane pe latime, de la sol la punte (~14,5 m), talpi de piatra.
    - 4 niveluri de grinzi orizontale (nuki, la 3.5/6.5/9.5/12.5 m), mai
      inchise la culoare, care TREC CONTINUU prin toti stalpii pe toata
      latimea modulului si ies ~0,4 m dincolo de stalpii de capat; pe
      adancime la fel (ies 0,4 m in fata si in spate).
    - sus o punte de scanduri si, pe laturile lungi, o balustrada.
    - Inlantuire: stalpii de capat sunt JUMATATI (0,31 m, lipiti de planul
      x = +-3) deci doua module alaturate dau un stalp intreg 0,62 m; grinzile
      se suprapun peste cusatura (aceeasi culoare, acelasi profil).
    Cote: 6 m lat (stalpi/punte), 6 m adanc (+0,8 grinzi), ~16 m inalt.
    """
    b = Builder()
    L = 3.0
    D = 3.0
    pw = 0.62
    deck_z = 14.5
    POSTS = LARCH_RUST          # stalpi: lemn deschis
    NUKI = WOOD                 # grinzi: lemn putin mai inchis
    rows = [-D + pw / 2, 0.0, D - pw / 2]
    cols = [-L + pw / 4, -L / 3, L / 3, L - pw / 4]      # capetele: jumatati
    for ix, x in enumerate(cols):
        half = ix in (0, 3)
        w_ = pw * 0.5 if half else pw
        xc = x
        for y in rows:
            b.box((xc, y, 0.25), (w_ + 0.3, pw + 0.3, 0.5), STONE)
            b.box((xc, y, 0.5 + (deck_z - 0.5) * 0.5), (w_, pw, deck_z - 0.5), POSTS)
    for zb in (3.5, 6.5, 9.5, 12.5):
        for y in rows:                       # pe X, continue, ies 0,4 m in afara capetelor
            b.box((0, y, zb), (2 * L + 0.8, 0.78, 0.6), NUKI)
        for x in cols[1:3]:                  # pe Y, ies 0,4 m in fata/spate
            b.box((x, 0, zb + 0.05), (0.78, 2 * D + 0.8, 0.6), NUKI)
    # punte
    b.box((0, 0, deck_z + 0.2), (2 * L, 2 * D, 0.4), POSTS)
    b.box((0, 0, deck_z - 0.15), (2 * L, 2 * D - 0.6, 0.3), NUKI)
    rz0 = deck_z + 0.4
    for sy in (-1, 1):
        y = sy * (D - 0.14)
        b.box((0, y, rz0 + 0.95), (2 * L, 0.14, 0.14), POSTS)
        b.box((0, y, rz0 + 0.5), (2 * L, 0.12, 0.12), POSTS)
        for k in range(5):
            x = -L + 0.09 + (2 * L - 0.18) * k / 4.0
            b.box((x, y, rz0 + 0.5), (0.18, 0.18, 1.0), POSTS)
    return (b.to_object("Scaffold_Wood"),)


def _gable_y(roof, wood, gx, ya, yb, z0, w, rise, zb, ov=0.9, front_ov=1.0):
    """Acoperis transversal (creasta pe Y) cu fronton triunghiular de lemn la
    y = yb (spre +Y). Planuri de tigla rotite in jurul lui Y."""
    th = math.atan2(rise, w)
    Ls = math.hypot(w, rise) + ov
    t = 0.35
    ylen = (yb - ya) + front_ov
    yc = (ya + yb + front_ov) * 0.5
    for sx in (-1, 1):
        mx = gx + sx * (w * 0.5 + 0.2)
        mz = z0 + rise * 0.5 - 0.2
        nrm = Vector((sx * math.sin(th), 0, math.cos(th)))
        c = Vector((mx, yc, mz)) + nrm * (t * 0.5)
        rot = Matrix.Rotation(sx * th, 3, 'Y')
        roof.box(c, (Ls, ylen, t), TILE, rotation=rot)
        c2 = Vector((mx, yc, mz)) - nrm * 0.02
        roof.box(c2, (Ls - 0.1, ylen + 0.1, 0.12), BEAM, rotation=rot)
    roof.box((gx, yc, z0 + rise + 0.28), (0.6, ylen + 0.4, 0.5), BEAM)
    outline = [(gx - w, zb), (gx + w, zb), (gx + w, z0), (gx, z0 + rise), (gx - w, z0)]
    wood.prism(outline, 0.45, TIMBER, center=(0, yb, 0))
    # grinda si montanti pe fronton (lemn inchis)
    wood.box((gx, yb + 0.25, z0 + 0.35), (2 * w, 0.2, 0.3), BEAM)
    wood.box((gx, yb + 0.25, z0 + rise * 0.35), (0.3, 0.2, rise * 0.7), BEAM)


def build_kiyomizu_hondo():
    """`kiyomizu_hondo.png` -- lista de elemente (inainte de modelare):

    - acoperis principal MARE si abrupt (ridica ~7 m), concav pronuntat, coama
      inalta si lunga, gri-inchis; domina silueta.
    - la dreapta-fata un ACOPERIS TRANSVERSAL cu fronton triunghiular de lemn
      spre fata, deasupra unui portic pe verandă; la mijloc-fata un FRONTON
      MAI MIC pe acoperisul principal.
    - in stanga un acoperis-fusta mai jos (anexa), jur-imprejur streasina.
    - fatada: pereti ALBI cu stalpi bruni, 3 travee deschise intunecate la
      mijloc, peretii aproape de marginea verandei (vizibili sub streasina).
    - veranda de lemn pe piloni, balustrada; SCARA LATA (~1/3 din fatada) si
      joasa in stanga, cu trepte late.
    Cote: ~30 lat, ~21 adanc, ~14 inalt.
    """
    wood, roof, plaster = Builder(), Builder(), Builder()
    zd = 3.0
    bx, by0, by1 = 10.8, -7.0, 5.0       # trupul
    vx, vy0, vy1 = 12.4, -8.4, 6.0       # veranda
    cy_v = (vy0 + vy1) * 0.5
    # piloni sub veranda + grinzi
    xs = [-vx + 0.4 + k * (2 * vx - 0.8) / 8 for k in range(9)]
    ys = [vy0 + 0.4, -4.5, -1.0, 2.5, vy1 - 0.4]
    for x in xs:
        for y in ys:
            wood.box((x, y, 0.2), (0.95, 0.95, 0.4), STONE)
            wood.box((x, y, zd * 0.5 - 0.1), (0.6, 0.6, zd - 0.2), TIMBER)
    for zb in (1.2, 2.3):
        for y in ys:
            wood.box((0, y, zb), (2 * vx - 0.4, 0.34, 0.4), BEAM)
        for x in xs:
            wood.box((x, cy_v, zb), (0.34, vy1 - vy0 - 0.4, 0.4), BEAM)
    wood.box((0, cy_v, zd - 0.2), (2 * vx, vy1 - vy0, 0.4), TIMBER)
    frame_ring(wood, 0, cy_v, zd - 0.75, vx - 0.1, (vy1 - vy0) * 0.5 - 0.1, 0.5, 0.45, BEAM)
    # portic dreapta-fata: platforma extinsa + piloni
    pxc, pw_ = 7.0, 4.9
    wood.box((pxc, 7.7, zd - 0.2), (2 * pw_, 3.4, 0.4), TIMBER)
    for dx in (-pw_ + 0.4, 0.0, pw_ - 0.4):
        wood.box((pxc + dx, 9.1, zd * 0.5 - 0.1), (0.6, 0.6, zd - 0.2), TIMBER)
        wood.box((pxc + dx, 9.1, 0.2), (0.95, 0.95, 0.4), STONE)
    # balustrade veranda (golita la scara si la portic)
    st_x0, st_x1 = -9.9, -1.1
    R = dict(height=1.0, post_step=1.4, post_t=0.2, rail_t=0.16, slot=TIMBER)

    def rail(p1, p2):
        wood.railing(p1, p2, R["height"], R["post_step"], R["post_t"], R["rail_t"], R["slot"])

    rail((-vx + 0.15, vy0 + 0.15, zd), (vx - 0.15, vy0 + 0.15, zd))
    rail((-vx + 0.15, vy0 + 0.15, zd), (-vx + 0.15, vy1 - 0.15, zd))
    rail((vx - 0.15, vy0 + 0.15, zd), (vx - 0.15, vy1 - 0.15, zd))
    rail((st_x0 - 0.0, vy1 - 0.15, zd), (-vx + 0.15, vy1 - 0.15, zd))
    rail((st_x1, vy1 - 0.15, zd), (2.0, vy1 - 0.15, zd))
    rail((pxc + pw_ - 0.15, vy1 - 0.15, zd), (pxc + pw_ - 0.15, 9.3, zd))
    rail((pxc + pw_ - 0.15, 9.3, zd), (pxc - pw_ + 0.15, 9.3, zd))
    rail((pxc - pw_ + 0.15, 9.3, zd), (pxc - pw_ + 0.15, vy1 - 0.15, zd))
    # trupul: pereti albi in plan avansat, stalpi bruni
    ze = 7.0
    wh = ze - 0.2 - zd
    plaster.box((0, (by0 + by1) * 0.5, zd + wh * 0.5), (2 * bx, by1 - by0, wh), PLASTER)
    wood.box((0, (by0 + by1) * 0.5, zd + 0.15), (2 * bx + 0.5, by1 - by0 + 0.5, 0.3), BEAM)
    wood.box((0, (by0 + by1) * 0.5, zd + wh - 0.2), (2 * bx + 0.7, by1 - by0 + 0.7, 0.4), BEAM)
    wood.box((0, (by0 + by1) * 0.5, zd + wh * 0.5 + 0.2), (2 * bx + 0.5, by1 - by0 + 0.5, 0.25), BEAM)   # brau median
    nb = 9
    for k in range(nb + 1):
        x = -bx + 2 * bx * k / nb
        wood.box((x, by1 + 0.05, zd + wh * 0.5), (0.55, 0.45, wh), TIMBER)
        wood.box((x, by0 - 0.05, zd + wh * 0.5), (0.55, 0.45, wh), TIMBER)
    for y in (by0, -2.0, by1):
        for sx in (-1, 1):
            wood.box((sx * (bx + 0.05), y, zd + wh * 0.5), (0.45, 0.55, wh), TIMBER)
    # 3 travee deschise la mijloc (fata)
    for k in (-1, 0, 1):
        wood.box((k * 2.4, by1 + 0.12, zd + wh * 0.42), (1.8, 0.14, wh * 0.72), BEAM)
        wood.box((k * 2.4, by1 + 0.2, zd + wh * 0.42), (0.1, 0.12, wh * 0.72), TIMBER)
    for sx in (-1, 1):
        for y in (-5.0, 1.0):
            wood.box((sx * (bx + 0.12), y, zd + wh * 0.5), (0.12, 2.0, wh * 0.6), BEAM)
    # stalpi de streasina pe marginea verandei
    for x in xs:
        if st_x0 - 0.2 < x < st_x1 + 0.2 or x > pxc - pw_ - 0.2:
            continue
        wood.box((x, vy1 - 0.3, zd + (ze - 0.9 - zd) * 0.5), (0.5, 0.5, ze - 0.9 - zd), TIMBER)
    for y in (-4.5, -1.0, 2.5):
        for sx in (-1, 1):
            wood.box((sx * (vx - 0.35), y, zd + (ze - 0.9 - zd) * 0.5), (0.5, 0.5, ze - 0.9 - zd), TIMBER)
    # console sub streasina principala
    frame_ring(wood, 0, -1.5, ze - 0.95, bx + 1.4, 8.4, 0.4, 0.55, BEAM)
    frame_ring(wood, 0, -1.5, ze - 0.5, bx + 2.0, 8.9, 0.3, 0.55, BEAM)
    # scara LATA si joasa (cu palier jos)
    sxc, sw, n = -5.5, 8.4, 10
    run, rise_s = 0.45, zd / 10
    for i in range(n):
        top = zd - (i + 1) * rise_s + 0.02
        wood.box((sxc, vy1 + (i + 0.5) * run, top * 0.5), (sw, run, max(top, 0.05)), TIMBER)
    y_end = vy1 + n * run
    wood.box((sxc, y_end + 0.6, 0.1), (sw, 1.2, 0.2), STONE)                  # palier
    for sx in (-1, 1):
        x = sxc + sx * (sw * 0.5 + 0.1)
        wood.beam((x, vy1, zd + 1.0), (x, y_end, 1.0), 0.2, TIMBER)
        wood.beam((x, vy1, zd + 0.55), (x, y_end, 0.55), 0.15, TIMBER)
        for k in range(0, n + 1, 2):
            yk = vy1 + k * run
            zk = zd - k * rise_s
            wood.box((x, yk, zk * 0.5 + 0.5), (0.2, 0.2, zk + 1.0), TIMBER)
    # acoperisul principal: mare, abrupt, concav
    ze_r, rise = 7.0, 6.4
    hip_roof(roof, 0, -1.5, ze_r, 13.0, 8.5, rise, TILE, ridge_half=6.2, lift=1.5,
             thick=0.3, fascia_slot=BEAM, tile_step=0.85, rib=0.06, sag=2.5, swell=0.4)
    top = ze_r + rise
    roof.box((0, -1.5, top + 0.1), (2 * 6.2 + 1.0, 0.6, 0.5), BEAM)
    for sx in (-1, 1):
        roof.box((sx * 6.7, -1.5, top + 0.45), (0.5, 0.7, 0.8), BEAM)
    # acoperis transversal cu fronton (dreapta-fata) deasupra porticului
    for dx in (-pw_ + 0.3, pw_ - 0.3):
        wood.box((pxc + dx, 9.1, zd + (6.2 - zd) * 0.5), (0.5, 0.5, 6.2 - zd), TIMBER)
    wood.box((pxc, 9.1, 6.0), (2 * pw_, 0.5, 0.4), BEAM)
    _gable_y(roof, wood, pxc, 0.0, 9.1, 6.4, pw_ - 0.2, 3.7, 5.3, front_ov=0.9)
    # fronton mai mic pe acoperisul principal, la mijloc-fata
    _gable_y(roof, wood, -0.5, 0.5, 6.6, 8.3, 2.5, 2.1, 7.4, front_ov=0.7)
    # anexa joasa (acoperis-fusta) in stanga
    ax, ay = -13.6, -1.5
    plaster.box((ax, ay, zd + 1.3), (3.4, 6.0, 2.6), PLASTER)
    wood.box((ax, ay, zd + 0.2), (3.8, 6.4, 0.4), BEAM)
    hip_roof(roof, ax, ay, 5.4, 4.6, 5.4, 2.4, TILE, ridge_half=1.0, lift=0.9,
             thick=0.25, fascia_slot=BEAM, tile_step=0.8, rib=0.05, sag=2.0, swell=0.3)
    return (wood.to_object("Hondo_Wood"), roof.to_object("Hondo_Roof"),
            plaster.to_object("Hondo_Plaster"))


if True:
    clear_built()
    emit(list(build_kakezukuri_scaffold()), "structures/kakezukuri_scaffold.glb",
         dict(samples=8, dist=3.0, gradient="vertical", low=0.7, high=1.0,
              power=0.8, floor=0.3), bevel=0.0, smooth_angle=None, budget=3000)
    clear_built()
    emit(list(build_kiyomizu_hondo()), "structures/kiyomizu_hondo.glb",
         dict(samples=8, dist=5.0, gradient="vertical", low=0.82, high=1.0,
              power=0.8, floor=0.3), bevel=0.0, smooth_angle=None, budget=14000)
    report()
