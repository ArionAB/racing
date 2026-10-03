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


def _gate(P):
    """Poarta cu doua etaje, comuna Niomon/Romon; parametrii dau ce le
    deosebeste. Intoarce (wood, roof, plaster) -- trei Builder."""
    wood, roof, plaster = Builder(), Builder(), Builder()
    xi, xo, pd = P["x_in"], P["x_out"], P["post_d"]   # stalpi: interior/exterior, adancime
    pw = P["post_w"]
    zp = P["post_h"]                                    # varful stalpilor parterului
    zg = P["gallery_z"]
    zu = P["upper_h"]                                   # inaltimea etajului 2
    ze = P["eave_z"]

    # --- parter: stalpi pe socluri de piatra -------------------------------
    for sx in (-1, 1):
        for x in (xi, xo):
            for sy in (-1, 1):
                px, py = sx * x, sy * pd
                wood.box((px, py, 0.25), (pw + 0.3, pw + 0.3, 0.5), STONE)
                wood.box((px, py, 0.5 + (zp - 0.5) * 0.5), (pw, pw, zp - 0.5), VERM)
                # cap de stalp: kasagi sub grinda
                wood.box((px, py, zp - 0.2), (pw + 0.18, pw + 0.18, 0.4), VERM)
    # grinzi transversale (peste gol): kamoi + nuki, doar peste fata si spatele
    for sy in (-1, 1):
        wood.box((0, sy * pd, zp + 0.2), (2 * xo + pw + 0.6, 0.9, 0.6), BEAM)    # kasagi negru
        wood.box((0, sy * pd, zp - 0.6), (2 * xi, 0.7, 0.55), VERM)               # peste gol
        for sx in (-1, 1):
            wood.box((sx * (xi + xo) * 0.5, sy * pd, zp - 0.55),
                     (xo - xi, 0.45, 0.42), VERM)
            wood.box((sx * (xi + xo) * 0.5, sy * pd, 1.1), (xo - xi, 0.4, 0.3), VERM)
    # grinzi pe adancime (leaga randul din fata de cel din spate)
    for sx in (-1, 1):
        for x in (xi, xo):
            wood.box((sx * x, 0, zp + 0.05), (0.5, 2 * pd, 0.5), VERM)

    # --- panouri albe + usi cu zabrele in cele doua travee laterale --------
    bay_c = (xi + xo) * 0.5
    bay_w = xo - xi - pw
    for sx in (-1, 1):
        for sy in (-1, 1):
            plaster.box((sx * bay_c, sy * (pd + 0.02), 0.5 + (zp - 1.5) * 0.5 + 0.35),
                        (bay_w, 0.14, zp - 1.7), PLASTER)
            # rame pe panou
            wood.box((sx * bay_c, sy * (pd + 0.1), 1.0), (bay_w, 0.1, 0.18), VERM)
            wood.box((sx * bay_c, sy * (pd + 0.1), zp - 1.4), (bay_w, 0.1, 0.18), VERM)
        if P.get("side_lattice", True):
            # usa cu zabrele pe partea dinspre drum a travei (in planul stalpului
            # interior, in afara golului)
            wx = sx * (xi + pw * 0.5 + 0.06)
            wood.box((wx, 0, 0.5 + (zp - 1.6) * 0.5 + 0.2), (0.1, 2 * pd - pw, zp - 1.6), BEAM)
            for k in range(-3, 4):
                wood.box((wx + sx * 0.06, k * (pd - pw) / 3.5, 0.5 + (zp - 1.6) * 0.5 + 0.2),
                         (0.08, 0.14, zp - 1.5), VERM)

    # --- galeria etajului 2 ----------------------------------------------
    gx, gy = P["gallery_hx"], P["gallery_hy"]
    wood.box((0, 0, zg - 0.18), (2 * gx, 2 * gy, 0.36), TIMBER)
    frame_ring(wood, 0, 0, zg - 1.15, gx - 0.15, gy - 0.15, 0.95, 0.7, VERM)
    # console sub galerie
    for sy in (-1, 1):
        wood.pickets((-gx + 0.6, sy * (gy - 0.55), zg - 1.25),
                     (gx - 0.6, sy * (gy - 0.55), zg - 1.25), 1.25,
                     (0.4, 0.4, 0.75), VERM, endpoints=True)
    sides = P.get("gallery_sides", True)
    rh = 1.0
    wood.railing((-gx + 0.2, gy - 0.2, zg), (gx - 0.2, gy - 0.2, zg), rh, 1.3, 0.16, 0.14, VERM, rails=2)
    wood.railing((-gx + 0.2, -gy + 0.2, zg), (gx - 0.2, -gy + 0.2, zg), rh, 1.3, 0.16, 0.14, VERM, rails=2)
    if sides:
        wood.railing((gx - 0.2, -gy + 0.2, zg), (gx - 0.2, gy - 0.2, zg), rh, 1.3, 0.16, 0.14, VERM, rails=2)
        wood.railing((-gx + 0.2, -gy + 0.2, zg), (-gx + 0.2, gy - 0.2, zg), rh, 1.3, 0.16, 0.14, VERM, rails=2)

    # --- etajul 2: miez alb, stalpi vermilion, ferestre intunecate ---------
    ux, uy = P["upper_hx"], P["upper_hy"]
    uh = zu - zg
    plaster.box((0, 0, zg + uh * 0.5), (2 * ux, 2 * uy, uh), PLASTER)
    wood.box((0, 0, zg + 0.18), (2 * ux + 0.4, 2 * uy + 0.4, 0.36), VERM)          # talpa
    wood.box((0, 0, zu - 0.2), (2 * ux + 0.5, 2 * uy + 0.5, 0.4), VERM)            # centura sus
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

    # --- console sub streasina ---------------------------------------------
    frame_ring(wood, 0, 0, ze - 0.95, ux + 0.55, uy + 0.55, 0.36, 0.5, VERM)
    frame_ring(wood, 0, 0, ze - 0.55, ux + 1.2, uy + 1.2, 0.3, 0.5, VERM)
    for sy in (-1, 1):
        wood.pickets((-ux - 0.5, sy * (uy + 0.6), ze - 1.15),
                     (ux + 0.5, sy * (uy + 0.6), ze - 1.15), P["bracket_step"],
                     (0.36, 0.36, 0.55), VERM, endpoints=True)
    for sx in (-1, 1):
        wood.pickets((sx * (ux + 0.6), -uy - 0.5, ze - 1.15),
                     (sx * (ux + 0.6), uy + 0.5, ze - 1.15), 1.6,
                     (0.36, 0.36, 0.55), VERM, endpoints=True)

    # --- acoperis in patru ape (irimoya simplificat), creasta pe X ----------
    hip_roof(roof, 0, 0, ze, P["roof_hx"], P["roof_hy"], P["roof_rise"], TILE,
             ridge_half=P["ridge_half"], lift=P["roof_lift"], thick=0.22,
             fascia_slot=BEAM, tile_step=0.85, rib=0.06, sag=P["roof_sag"],
             swell=0.25)
    top = ze + P["roof_rise"]
    rh_ = P["ridge_half"]
    roof.box((0, 0, top + 0.12), (2 * rh_ + 0.9, 0.55, 0.5), BEAM)                  # creasta
    for sx in (-1, 1):                                                              # onigawara
        roof.box((sx * (rh_ + 0.35), 0, top + 0.3), (0.45, 0.6, 0.55), BEAM)
        roof.box((sx * (rh_ + 0.5), 0, top + 0.7), (0.35, 0.45, 0.3), BEAM)
    return wood, roof, plaster


NIOMON = dict(x_in=6.6, x_out=8.7, post_d=2.7, post_w=1.0, post_h=5.0,
              gallery_z=5.5, gallery_hx=8.9, gallery_hy=4.5, gallery_sides=True,
              upper_h=8.3, upper_hx=7.8, upper_hy=2.5, upper_posts=7, windows=3,
              window_span=3.6, eave_z=8.4, roof_hx=10.2, roof_hy=6.3,
              roof_rise=4.3, ridge_half=5.0, roof_lift=0.95, roof_sag=1.7,
              bracket_step=1.25)

ROMON = dict(x_in=6.4, x_out=8.0, post_d=2.3, post_w=0.95, post_h=4.8,
             gallery_z=5.1, gallery_hx=8.3, gallery_hy=3.9, gallery_sides=False,
             upper_h=7.8, upper_hx=7.2, upper_hy=2.3, upper_posts=6, windows=4,
             window_span=4.0, eave_z=7.9, roof_hx=9.0, roof_hy=5.6,
             roof_rise=3.9, ridge_half=3.0, roof_lift=1.15, roof_sag=2.0,
             bracket_step=1.0, side_lattice=False)


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

    - retea de stalpi patrati de lemn, 3 randuri pe adancime x 4 coloane pe
      latime, de la sol la punte (~15 m); la sol blocuri-talpa.
    - 4 niveluri de grinzi orizontale (la 3.5, 6.5, 9.5, 12.5 m), pe ambele
      directii, ale căror capete ies putin din stalp (bloc intunecat).
    - sus o punte de scanduri si, pe cele doua laturi lungi, o balustrada
      (stalpisori + 2 lise); capetele la ±3 m deschise.
    - Inlantuire: capetele (x = ±3) sunt PLANE: stalpii de capat stau lipiti
      de plan (jumatatea lor interioara), grinzile si lisele ajung exact la ±3.
    Cote: 6 m lat, 6 m adanc, 16 m inalt (cu balustrada).
    """
    b = Builder()
    L = 3.0                                   # semilatime modul (X)
    D = 3.0                                   # semiadancime (Y)
    pw = 0.62
    deck_z = 14.5
    cols = [-L + pw / 2, -L / 3 + 0.0, L / 3, L - pw / 2]
    rows = [-D + pw / 2, 0.0, D - pw / 2]
    # stalpi + talpi
    for x in cols:
        for y in rows:
            b.box((x, y, 0.25), (pw + 0.3 if abs(x) < L - 0.4 else pw, pw + 0.3 if abs(y) < D - 0.4 else pw, 0.5), STONE)
            b.box((x, y, 0.5 + (deck_z - 0.5) * 0.5), (pw, pw, deck_z - 0.5), TIMBER)
    # grinzi orizontale
    for zb in (3.5, 6.5, 9.5, 12.5):
        for y in rows:                       # pe X, capete exact la ±L
            b.box((0, y, zb), (2 * L - 0.06, 0.5, 0.55), BEAM)
        for x in cols:                       # pe Y, intre randuri
            b.box((x, 0, zb + 0.05), (0.5, 2 * D - 0.06, 0.55), BEAM)
    # punte
    b.box((0, 0, deck_z + 0.2), (2 * L, 2 * D, 0.4), TIMBER)
    b.box((0, 0, deck_z - 0.15), (2 * L, 2 * D - 0.6, 0.3), BEAM)
    # balustrada pe laturile lungi (X), capete deschise
    rz0 = deck_z + 0.4
    for sy in (-1, 1):
        y = sy * (D - 0.14)
        b.box((0, y, rz0 + 0.95), (2 * L, 0.14, 0.14), TIMBER)
        b.box((0, y, rz0 + 0.5), (2 * L, 0.12, 0.12), TIMBER)
        for k in range(5):
            x = -L + 0.09 + (2 * L - 0.18) * k / 4.0
            b.box((x, y, rz0 + 0.5), (0.18, 0.18, 1.0), TIMBER)
    return (b.to_object("Scaffold_Wood"),)


def build_kiyomizu_hondo():
    """`kiyomizu_hondo.png` -- lista de elemente (inainte de modelare):

    - un acoperis mare in patru ape (creasta lunga), gri-inchis, streasina larga
      si curbata; el domina silueta (~45% din inaltime).
    - sub el, trupul sălii: pereti albi cu stalpi bruni, in mijloc 3 travee
      deschise (intunecate, shoji); veranda de lemn pe tot perimetrul, la
      ~3,8 m, ridicata pe piloni (stilts) cu grinzi de legatura.
    - fata (+Y): o scara de lemn lata, cu balustrade inclinate, coboara din
      veranda in stanga; balustrada pe veranda, goala la scara; stalpi de
      streasina pe marginea verandei.
    - in dreapta, fata: un portic mic cu acoperis propriu in patru ape; in
      stanga o anexa joasa cu acoperis mic.
    Cote: ~30 lat, ~21 adanc, ~14 inalt (cu veranda pe piloni).
    """
    wood, roof, plaster = Builder(), Builder(), Builder()
    zd = 3.0                          # cota verandei
    bx, by0, by1 = 11.0, -7.0, 4.4    # trupul: x +-12, y de la by0 la by1
    vx, vy0, vy1 = 12.6, -8.4, 5.6    # veranda
    ze, rise = 7.9, 5.6
    # piloni sub veranda + grinzi de legatura
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
            wood.box((x, (vy0 + vy1) * 0.5, zb), (0.34, vy1 - vy0 - 0.4, 0.4), BEAM)
    # puntea verandei
    wood.box((0, (vy0 + vy1) * 0.5, zd - 0.2), (2 * vx, vy1 - vy0, 0.4), TIMBER)
    frame_ring(wood, 0, (vy0 + vy1) * 0.5, zd - 0.75, vx - 0.1,
               (vy1 - vy0) * 0.5 - 0.1, 0.5, 0.45, BEAM)
    # balustrada verandei (goala la scara, x in [-7.6, -2.4])
    cy_v = (vy0 + vy1) * 0.5
    wood.railing((-vx + 0.15, vy0 + 0.15, zd), (vx - 0.15, vy0 + 0.15, zd), 1.0, 1.4, 0.2, 0.16, TIMBER)
    wood.railing((-vx + 0.15, vy0 + 0.15, zd), (-vx + 0.15, vy1 - 0.15, zd), 1.0, 1.4, 0.2, 0.16, TIMBER)
    wood.railing((vx - 0.15, vy0 + 0.15, zd), (vx - 0.15, vy1 - 0.15, zd), 1.0, 1.4, 0.2, 0.16, TIMBER)
    wood.railing((vx - 0.15, vy1 - 0.15, zd), (-1.2, vy1 - 0.15, zd), 1.0, 1.4, 0.2, 0.16, TIMBER)
    wood.railing((-7.8, vy1 - 0.15, zd), (-vx + 0.15, vy1 - 0.15, zd), 1.0, 1.4, 0.2, 0.16, TIMBER)
    # trupul: pereti albi, stalpi, travee deschise in mijloc (fata)
    wh = ze - 0.4 - zd
    plaster.box((0, (by0 + by1) * 0.5, zd + wh * 0.5), (2 * bx, by1 - by0, wh), PLASTER)
    wood.box((0, (by0 + by1) * 0.5, zd + 0.15), (2 * bx + 0.5, by1 - by0 + 0.5, 0.3), BEAM)   # talpa
    wood.box((0, (by0 + by1) * 0.5, zd + wh - 0.2), (2 * bx + 0.7, by1 - by0 + 0.7, 0.4), BEAM)  # centura
    nb = 10
    for k in range(nb + 1):
        x = -bx + 2 * bx * k / nb
        wood.box((x, by1 + 0.05, zd + wh * 0.5), (0.5, 0.4, wh), TIMBER)
        wood.box((x, by0 - 0.05, zd + wh * 0.5), (0.5, 0.4, wh), TIMBER)
    for y in (by0, -2.0, by1):
        for sx in (-1, 1):
            wood.box((sx * (bx + 0.05), y, zd + wh * 0.5), (0.4, 0.5, wh), TIMBER)
    # 3 travee deschise la mijloc (fata): gol intunecat + rama
    for k in (-1, 0, 1):
        x = k * 2.4
        wood.box((x, by1 + 0.12, zd + wh * 0.45), (1.9, 0.14, wh * 0.78), BEAM)
        wood.box((x, by1 + 0.2, zd + wh * 0.45), (0.1, 0.12, wh * 0.78), TIMBER)
    # feronerii laterale: ferestre pe laturi
    for sx in (-1, 1):
        for y in (-5.0, 1.0):
            wood.box((sx * (bx + 0.12), y, zd + wh * 0.5), (0.12, 2.0, wh * 0.6), BEAM)
    # stalpi de streasina pe marginea verandei (liberi la scara)
    for x in xs:
        if -7.8 < x < -1.2:
            continue
        wood.box((x, vy1 - 0.45, zd + (ze - 0.9 - zd) * 0.5), (0.55, 0.55, ze - 0.9 - zd), VERM if False else TIMBER)
    for y in (-4.5, -1.0, 2.5):
        for sx in (-1, 1):
            wood.box((sx * (vx - 0.45), y, zd + (ze - 0.9 - zd) * 0.5), (0.55, 0.55, ze - 0.9 - zd), TIMBER)
    # console sub streasina
    frame_ring(wood, 0, -1.5, ze - 1.0, vx + 0.4, 9.1, 0.4, 0.55, BEAM)
    frame_ring(wood, 0, -1.5, ze - 0.55, vx + 1.1, 9.1 + 0.4, 0.3, 0.55, BEAM)
    # scara de lemn (la stanga, coboara spre +Y)
    sxc, sw, n = -4.5, 6.6, 12
    run, rise_s = 0.42, zd / 12
    for i in range(n):
        top = zd - (i + 1) * rise_s + 0.02
        wood.box((sxc, vy1 + (i + 0.5) * run, top * 0.5), (sw, run, max(top, 0.05)), TIMBER)
    y_end = vy1 + n * run
    for sx in (-1, 1):
        x = sxc + sx * (sw * 0.5 + 0.1)
        wood.beam((x, vy1, zd + 1.0), (x, y_end, 1.0), 0.2, TIMBER)
        wood.beam((x, vy1, zd + 0.55), (x, y_end, 0.55), 0.15, TIMBER)
        for k in range(0, n + 1, 3):
            yk = vy1 + k * run
            zk = zd - k * rise_s
            wood.box((x, yk, zk * 0.5 + 0.5), (0.2, 0.2, zk + 1.0), TIMBER)
        wood.box((x, vy1, zd * 0.5), (0.35, 0.35, zd), TIMBER)
    # acoperisul principal
    hip_roof(roof, 0, -1.5, ze, 14.2, 8.8, rise, TILE, ridge_half=7.4, lift=1.2,
             thick=0.3, fascia_slot=BEAM, tile_step=0.85, rib=0.06, sag=1.9, swell=0.3)
    top = ze + rise
    roof.box((0, -1.5, top + 0.1), (2 * 7.4 + 1.0, 0.6, 0.5), BEAM)
    for sx in (-1, 1):
        roof.box((sx * 7.9, -1.5, top + 0.4), (0.5, 0.7, 0.7), BEAM)
    # portic mic in dreapta, fata
    px, py = 7.4, 3.2
    ze2 = 6.3
    for dx in (-3.0, 3.0):
        for dy in (-2.2, 2.2):
            wood.box((px + dx, py + dy + 1.0, zd + (ze2 - 0.7 - zd) * 0.5), (0.5, 0.5, ze2 - 0.7 - zd), TIMBER)
    wood.box((px, py + 1.0, ze2 - 0.9), (6.6, 4.8, 0.4), BEAM)
    hip_roof(roof, px, py + 1.0, ze2, 4.3, 3.3, 2.7, TILE, ridge_half=1.6, lift=0.7,
             thick=0.25, fascia_slot=BEAM, tile_step=0.8, rib=0.05, sag=1.8, swell=0.2)
    # anexa joasa in stanga
    ax, ay = -12.9, 1.5
    wood.box((ax, ay, zd + 1.0), (3.4, 4.2, 2.0), BEAM)
    plaster.box((ax, ay, zd + 1.2), (3.2, 4.0, 2.4), PLASTER)
    hip_roof(roof, ax, ay, 5.0, 3.5, 3.1, 1.7, TILE, ridge_half=1.0, lift=0.6,
             thick=0.25, fascia_slot=BEAM, tile_step=0.8, rib=0.05, sag=1.8, swell=0.2)
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
