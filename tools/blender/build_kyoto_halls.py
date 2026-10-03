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
