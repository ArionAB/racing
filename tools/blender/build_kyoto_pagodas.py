"""Kyoto -- pagodele (brief docs/asset_briefs/kyoto_kit.md §1.1).

  kyoto/structures/yasaka_pagoda.glb      pagoda Yasaka, 5 etaje, 24 m   (PILOT)
  (urmeaza: sanjunoto_pagoda, koyasu_pagoda)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_kyoto_pagodas.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py")).read())

# Sloturi (brief kyoto_kit §0.4)
TILE = ASPHALT_EDGE        # tigla kawara: gri neutru #696765 (VOLCANIC_BLACK #55535A iese violet pe randare)
BEAM = LOG_DARK            # grinzi, console, fateta streasinii
POST = RUST                # stalpi/pereti etaje: lemn rosu-maroniu
VERM = LAVA_ORANGE         # vermilion: console, rame, stalpii parterului
PLASTER = FOAM_WHITE       # panouri de var
DARK = LOG_DARK            # goluri de fereastra (maro foarte inchis)
GOLD = CAR_YELLOW          # sorin (exceptie --allow-car-slots=Pagoda_Spire)
STONE = CONCRETE           # soclul, piatra deschisa

AO_PAGODA = dict(samples=12, dist=3.5, gradient="vertical",
                 low=0.72, high=1.0, power=0.8, floor=0.30)

clear_built()


def _tier_walls(bb, bw, i, cx, cy, z0, z1, w, plaster, posts):
    """Corpul unui etaj: miez, stalpi, brauri, ferestre pe patru fete."""
    h = z1 - z0
    core_slot = BEAM if plaster else POST
    bb.box((cx, cy, z0 + h * 0.5), (2 * w, 2 * w, h), core_slot)
    # brau sus si jos (nuki) iesit 0.12
    for zz, hh in ((z0 + 0.12, 0.24), (z1 - 0.22, 0.44)):
        frame_ring(bb, cx, cy, zz - hh * 0.5, w + 0.12, w + 0.12, hh, 0.22,
                   VERM if plaster else BEAM)
    # stalpi: 4 de colt + 2 pe latura
    pw = 0.30 if i else 0.36
    offs = [-w, -w / 3.0, w / 3.0, w]
    for sgn in (-1, 1):
        for o in offs:
            for (px, py) in ((cx + o, cy + sgn * w), (cx + sgn * w, cy + o)):
                bb.box((px, py, z0 + h * 0.5), (pw, pw, h), VERM if plaster else POST)
    if plaster:
        # panouri de var intre stalpi (parter), proeminente 3 cm
        for side in range(4):
            ang = side * math.pi / 2
            c, s_ = math.cos(ang), math.sin(ang)
            for o in ((-2 * w / 3.0, 2 * w / 3.0) if side == 0 else (-w / 2.0, w / 2.0)):
                lx, ly = o, w + 0.03
                bb.box((cx + lx * c - ly * s_, cy + lx * s_ + ly * c, z0 + h * 0.5),
                       ((2 * w / 3.0 - 0.45) if side % 2 == 0 else 0.07,
                        0.07 if side % 2 == 0 else (2 * w / 3.0 - 0.45), h * 0.8), PLASTER)
    if plaster:
        # usa inchisa la mijloc, pe fata din fata (+Y)
        bb.box((cx, cy + w + 0.05, z0 + h * 0.4), (w * 0.62, 0.12, h * 0.72), VERM)
        bb.box((cx, cy + w + 0.1, z0 + h * 0.4), (w * 0.5, 0.1, h * 0.62), POST)
    for side in range(0 if not plaster else 4, 4):
        ang = side * math.pi / 2
        c, s = math.cos(ang), math.sin(ang)
        for k, o in enumerate((-2 * w / 3.0, 0.0, 2 * w / 3.0)):
            lx, ly = o, w + 0.04     # in planul fetei locale +Y
            px = cx + lx * c - ly * s
            py = cy + lx * s + ly * c
            ww = w / 3.0 * 0.62
            wh = h * (0.55 if not plaster else 0.5)
            zc = z0 + h * (0.5 if not plaster else 0.55)
            if plaster and side == 0 and k == 1:
                wh = h * 0.72
                zc = z0 + wh * 0.5 + 0.1
                ww = w / 3.0 * 0.8
            sx = ww if side % 2 == 0 else 0.12
            sy = 0.12 if side % 2 == 0 else ww
            bw.box((px, py, zc), (sx, sy, wh), DARK)
            # montant central subtire (grila)
            bw.box((px, py, zc), (0.07 if side % 2 == 0 else 0.16,
                                  0.16 if side % 2 == 0 else 0.07, wh * 1.02), POST)


def build_yasaka_pagoda():
    """`yasaka_pagoda.png` -- lista de elemente (inainte de modelare):

    - 5 acoperisuri in patru ape, gri-inchis, cu colturile ridicate; latimea
      scade spre varf (raport streasini ~1 : .91 : .81 : .71 : .60).
    - Sub fiecare acoperis un brau de console (rand dublu, brun inchis) care
      iese mai mult decat peretele.
    - Peretii: 5 trupuri patrate; cel de jos e mai inalt, cu var alb + 3
      goluri pe fata si usa pe fata din fata (+Y); cele 4 de sus brun-roscat
      cu 3 ferestre/grile pe fiecare fata si balustrada joasa.
    - Soclu scund de piatra.
    - Varful: acoperisul de sus mai inalt (varf ascutit), apoi sorin aurit:
      bol rasturnat, sfera, stalp cu ~9 inele, flacara de apa; ~17% din
      inaltimea totala (spire).
    - Iese din contur: sorin, colturile acoperisurilor ridicate.
    Cote: 24 m total, streasina de jos 16 m latime.
    """
    roof = Builder()
    body = Builder()
    glow = Builder()      # goluri (DARK) -- nod separat, clasele nu le sterg
    spire = Builder()

    plinth_h = 0.55
    eave_hw = [5.5, 5.05, 4.55, 4.0, 3.4]
    wall_hw = [2.9, 2.65, 2.4, 2.1, 1.8]
    eave_z = [4.5, 7.6, 10.7, 13.8, 16.9]
    rise = [0.95, 0.95, 0.9, 0.9, 2.6]
    lift = [0.65, 0.62, 0.6, 0.58, 0.55]

    # soclu
    body.box((0, 0, plinth_h * 0.5), (2 * 3.9, 2 * 3.9, plinth_h), STONE)

    for i in range(5):
        base_z = plinth_h if i == 0 else eave_z[i - 1] + 0.85
        top_z = eave_z[i] - 0.15
        _tier_walls(body, glow, i, 0.0, 0.0, base_z, top_z, wall_hw[i],
                    plaster=(i == 0), posts=True)
        # console sub streasina: doua trepte
        w = wall_hw[i]
        frame_ring(body, 0, 0, eave_z[i] - 0.75, w + 0.45, w + 0.45, 0.32, 0.45, VERM)
        frame_ring(body, 0, 0, eave_z[i] - 0.43, w + 0.85, w + 0.85, 0.28, 0.45, VERM)
        # capete de console ("tokyo"): blocuri intunecate sub streasina
        cw = w + 0.5
        for sgn in (-1, 1):
            body.pickets((-cw, sgn * cw, eave_z[i] - 0.95), (cw, sgn * cw, eave_z[i] - 0.95),
                         0.95, (0.34, 0.34, 0.5), VERM, endpoints=True)
            body.pickets((sgn * cw, -cw, eave_z[i] - 0.95), (sgn * cw, cw, eave_z[i] - 0.95),
                         0.95, (0.34, 0.34, 0.5), VERM, endpoints=True)
        hip_roof(roof, 0, 0, eave_z[i], eave_hw[i], eave_hw[i], rise[i], TILE,
                 lift=lift[i], thick=0.18, fascia_slot=BEAM, tile_step=0.85,
                 rib=0.05, swell=0.3)

    # sorin
    apex = eave_z[4] + rise[4]
    sp = spire
    sp.frustum((0, 0, apex + 0.22), 0.62, 0.42, 0.44, GOLD, segments=8)    # bol
    sp.frustum((0, 0, apex + 0.62), 0.34, 0.5, 0.36, GOLD, segments=8)
    sp.frustum((0, 0, apex + 0.98), 0.5, 0.0, 0.4, GOLD, segments=8)       # sfera/ou
    sp.cylinder((0, 0, apex + 2.6), 0.11, 4.0, GOLD, segments=6)           # stalp
    radii = [0.40 - 0.02 * k for k in range(9)]
    ring_stack(sp, 0, 0, apex + 1.55, radii, 0.26, 0.10, GOLD, segments=8)
    sp.frustum((0, 0, apex + 4.1), 0.26, 0.0, 0.7, GOLD, segments=6)       # flacara
    return (roof.to_object("Pagoda_Roof"), body.to_object("Pagoda_Body"),
            glow.to_object("Pagoda_Windows"), sp.to_object("Pagoda_Spire"))


# ---------------------------------------------------------------------------
# Pagodele vermilion cu 3 etaje (sanjunoto, koyasu). Refolosesc vocabularul
# pilotului (hip_roof, frame_ring, ring_stack, corp retras ~0,5 din streasina,
# banda de console vermilion, colturi ridicate); yasaka_pagoda NU se atinge.
# ---------------------------------------------------------------------------

def _roof_z(ze, rise, eave, r, lift=0.0, f=0.0, sag=1.6):
    """Cota suprafetei acoperisului `hip_roof` la raza `r` (f=0 mijloc de
    latura, f=1 colt) -- ca sa stea corpul si balustrada pe tigla."""
    s = min(1.0, r / eave)
    return ze + rise * (1.0 - s) ** sag + lift * f * s * s


def _pt(side, lx, ly, cx=0.0, cy=0.0):
    ang = side * math.pi / 2
    c, s_ = math.cos(ang), math.sin(ang)
    return cx + lx * c - ly * s_, cy + lx * s_ + ly * c


def _pagoda_spire(sp, apex, length, rings, cfg_r0=0.44):
    """Sorin aurit: bol rasturnat, ou, stalp cu `rings` inele care se subtiaza,
    flacara de apa. `length` = inaltimea totala a sorin-ului."""
    k_ = cfg_r0 / 0.44
    sp.frustum((0, 0, apex + 0.22), 0.62 * k_, 0.42 * k_, 0.44, GOLD, segments=8)
    sp.frustum((0, 0, apex + 0.62), 0.34 * k_, 0.5 * k_, 0.36, GOLD, segments=8)
    sp.frustum((0, 0, apex + 0.98), 0.5 * k_, 0.0, 0.4, GOLD, segments=8)
    sp.cylinder((0, 0, apex + length * 0.5), 0.12 * k_, length, GOLD, segments=6)
    z0 = apex + 1.35
    step = (length - 1.35 - 0.9) / max(rings, 1)
    radii = [cfg_r0 - 0.5 * cfg_r0 * k / max(rings - 1, 1) for k in range(rings)]
    ring_stack(sp, 0, 0, z0, radii, step, min(0.12, step * 0.45), GOLD, segments=8)
    sp.frustum((0, 0, apex + length - 0.45), 0.26, 0.0, 0.9, GOLD, segments=6)


def _arch_window(bw, bd, side, o, ly, zc, ww, hh, ring):
    """Fereastra rotunjita (arc sus) cu INEL ALB gros: `bw` primeste inelul
    (PLASTER), `bd` golul intunecat. ww x hh = golul; inelul adauga `ring`."""
    def shape(b, x_off, wd, ht, slot, dep, lyy):
        R = wd * 0.5
        # parte dreapta (jos) + semicerc sus
        cx_, cy_ = _pt(side, x_off, lyy)
        bx = (wd, dep) if side % 2 == 0 else (dep, wd)
        zb = zc - ht * 0.5
        b.box((cx_, cy_, zb + (ht - R) * 0.5), (bx[0], bx[1], ht - R), slot)
        b.cylinder((cx_, cy_, zb + ht - R), R, dep, slot, segments=10,
                   axis="Y" if side % 2 == 0 else "X")
    shape(bw, o, ww + 2 * ring, hh + 2 * ring, PLASTER, 0.12, ly)
    shape(bd, o, ww, hh, DARK, 0.12, ly + 0.06)


def _verm_pagoda(cfg):
    """Corpul comun al pagodelor vermilion cu 3 etaje. Intoarce nodurile
    (roof, body, windows, spire)."""
    roof, body, glow, sp = Builder(), Builder(), Builder(), Builder()
    n = 3
    eave_hw, eave_z, rise, lift = cfg["eave_hw"], cfg["eave_z"], cfg["rise"], cfg["lift"]
    wall_hw = [e * cfg["wall_k"] for e in eave_hw]
    ph = cfg["plinth_h"]
    body.box((0, 0, ph * 0.5), (2 * cfg["plinth_hw"], 2 * cfg["plinth_hw"], ph),
             cfg["plinth_slot"])
    body.box((0, 0, ph + 0.12), (2 * (cfg["plinth_hw"] - 0.3), 2 * (cfg["plinth_hw"] - 0.3), 0.24),
             cfg["plinth_slot"])
    for i in range(n):
        w = wall_hw[i]
        if i == 0:
            base_z = ph + 0.2
        else:
            base_z = _roof_z(eave_z[i - 1], rise[i - 1], eave_hw[i - 1], w + 0.05) - 0.06
        top_z = eave_z[i] - 0.15
        h = top_z - base_z
        body.box((0, 0, base_z + h * 0.5), (2 * w, 2 * w, h), cfg["wall_slot"])
        # brau de lemn sus (sub console) si jos
        frame_ring(body, 0, 0, top_z - 0.5, w + 0.1, w + 0.1, 0.5, 0.2, cfg["band_slot"])
        frame_ring(body, 0, 0, base_z, w + 0.1, w + 0.1, 0.3, 0.2, cfg["band_slot"])
        # stalpi de colt (iesiti); fetele raman pline (vermilion), ca pe planșa
        for sx in (-1, 1):
            for sy in (-1, 1):
                body.box((sx * w, sy * w, base_z + h * 0.5), (0.4, 0.4, h), cfg["post_slot"])
        if i == 0:
            # brau alb de var jos pe parter
            for side in range(4):
                px, py = _pt(side, 0.0, w + 0.03)
                sx_, sy_ = (2 * w - 0.5, 0.07) if side % 2 == 0 else (0.07, 2 * w - 0.5)
                body.box((px, py, base_z + 0.3), (sx_, sy_, 0.4), PLASTER)
        # ferestre rotunjite cu inel alb gros: 3 pe fiecare fata (pe fata din
        # fata a parterului: usa la mijloc, flancata de doua)
        cell = 2 * w / 3.0
        ring = cfg.get("ring", 0.17)
        wh = h * cfg["win_h"]
        zc = base_z + h * cfg["win_zc"]
        for side in range(4):
            for k, o in enumerate((-cell, 0.0, cell)):
                if i == 0 and side == 0 and k == 1:
                    dw, dh = cell * 0.62, h * 0.62
                    px, py = _pt(side, 0.0, w + 0.04)
                    bx = (dw + 0.3, 0.1) if side % 2 == 0 else (0.1, dw + 0.3)
                    body.box((px, py, base_z + 0.2 + dh * 0.5), (bx[0], bx[1], dh + 0.3), VERM)
                    qx, qy = _pt(side, 0.0, w + 0.10)
                    gx = (dw, 0.1) if side % 2 == 0 else (0.1, dw)
                    glow.box((qx, qy, base_z + 0.2 + dh * 0.5), (gx[0], gx[1], dh), DARK)
                    continue
                _arch_window(body, glow, side, o, w + 0.04, zc, cell * cfg["win_w"], wh, ring)
        # console: doua inele + blocuri pe fiecare latura (varianta joasa
        # `low_console` NU acopera ferestrele: un singur inel si blocuri mici)
        cw = w + 0.45
        if cfg.get("low_console"):
            frame_ring(body, 0, 0, eave_z[i] - 0.5, w + 0.5, w + 0.5, 0.3, 0.4, VERM)
            for sgn in (-1, 1):
                body.pickets((-cw, sgn * cw, eave_z[i] - 0.72), (cw, sgn * cw, eave_z[i] - 0.72),
                             0.95, (0.3, 0.3, 0.22), VERM, endpoints=True)
                body.pickets((sgn * cw, -cw, eave_z[i] - 0.72), (sgn * cw, cw, eave_z[i] - 0.72),
                             0.95, (0.3, 0.3, 0.22), VERM, endpoints=True)
        else:
            frame_ring(body, 0, 0, eave_z[i] - 0.75, w + 0.4, w + 0.4, 0.32, 0.45, VERM)
            frame_ring(body, 0, 0, eave_z[i] - 0.43, w + 0.8, w + 0.8, 0.28, 0.45, VERM)
            for sgn in (-1, 1):
                body.pickets((-cw, sgn * cw, eave_z[i] - 0.95), (cw, sgn * cw, eave_z[i] - 0.95),
                             0.95, (0.34, 0.34, 0.5), VERM, endpoints=True)
                body.pickets((sgn * cw, -cw, eave_z[i] - 0.95), (sgn * cw, cw, eave_z[i] - 0.95),
                             0.95, (0.34, 0.34, 0.5), VERM, endpoints=True)
        # galerie: sort plin vermilion lat pe tigla + lisa sus (etajele 2-3)
        if cfg["rail"] and i > 0:
            R = w + 0.6
            rz = _roof_z(eave_z[i - 1], rise[i - 1], eave_hw[i - 1], R) - 0.15
            body.box((0, 0, rz + 0.45), (2 * R, 2 * R, 0.9), cfg["rail_slot"])
            frame_ring(body, 0, 0, rz + 0.8, R + 0.12, R + 0.12, 0.2, 0.3, cfg["rail_slot"])
            for sx in (-1, 1):
                for sy in (-1, 1):
                    body.box((sx * R, sy * R, rz + 0.55), (0.3, 0.3, 1.1), cfg["rail_slot"])
        hip_roof(roof, 0, 0, eave_z[i], eave_hw[i], eave_hw[i], rise[i], TILE,
                 lift=lift[i], thick=0.18, fascia_slot=BEAM, tile_step=0.85,
                 rib=0.05, swell=cfg.get("swell", 0.3))
    apex = eave_z[n - 1] + rise[n - 1]
    _pagoda_spire(sp, apex, cfg["spire_len"], cfg["spire_rings"], cfg["spire_r"])
    return (roof.to_object("Pagoda_Roof"), body.to_object("Pagoda_Body"),
            glow.to_object("Pagoda_Windows"), sp.to_object("Pagoda_Spire"))


def build_sanjunoto_pagoda():
    """`sanjunoto_pagoda.png` -- lista de elemente (inainte de modelare):

    - 3 etaje, fiecare cu acoperis in patru ape gri-inchis, colturi ridicate;
      acoperisurile sunt LARGI si aproape egale (1 : .93 : .85); cel de sus
      e o piramida inalta.
    - Corpuri vermilion retrase (~0,55 din streasina), cu o BANDA de console
      vermilion sub fiecare streasina si ferestre cu rama ALBA (3 pe fata),
      gol intunecat; pe parter usa intunecata la mijloc pe fata din fata.
    - Etajele 2-3 au balustrada vermilion in jurul corpului, pe tigla.
    - Soclu ALB larg, scund, cu o treapta; var alb jos pe parter.
    - Sorin aurit LUNG (~27% din inaltime), cu multe inele care se subtiaza.
    Cote: ~18 m total, streasina de jos ~8,8 m.
    """
    return _verm_pagoda(dict(
        eave_hw=[4.7, 4.35, 4.0], eave_z=[3.7, 7.2, 10.5], rise=[1.1, 1.1, 3.0],
        lift=[0.65, 0.65, 0.6], wall_k=0.55, plinth_h=0.5, plinth_hw=3.7,
        plinth_slot=PLASTER, wall_slot=VERM, band_slot=BEAM, post_slot=VERM,
        rail=True, rail_slot=VERM, win_h=0.42, win_w=0.5, win_zc=0.45, ring=0.27,
        spire_len=4.5, spire_rings=12, spire_r=0.55))


def build_koyasu_pagoda():
    """`koyasu_pagoda.png` -- lista de elemente (inainte de modelare):

    - 3 etaje mai INGUSTE si mai apropiate decat sanjunoto (raport streasini
      1 : .85 : .70), acoperisuri gri foarte inchise, colturi ridicate; cel de
      sus piramida inalta.
    - Corpuri portocaliu-vermilion retrase (~0,55), banda de console, ferestre
      cu rama alba, galerie JOASA inchisa la culoare (balustrada LOG_DARK) la
      baza etajelor 2-3; nuki intunecate.
    - Soclu scund de piatra, usa intunecata pe parter.
    - Sorin aurit lung (~26%), subtire.
    Cote: 14 m total, streasina de jos ~6,8 m.
    """
    return _verm_pagoda(dict(
        eave_hw=[3.7, 3.65, 3.55], eave_z=[2.9, 5.7, 8.3], rise=[0.8, 0.8, 2.4],
        lift=[0.7, 0.7, 0.8], swell=0.5, wall_k=0.5, plinth_h=0.4, plinth_hw=2.8,
        plinth_slot=PLASTER, wall_slot=VERM, band_slot=BEAM, post_slot=VERM,
        rail=True, rail_slot=VERM, win_h=0.38, win_w=0.46, win_zc=0.40, ring=0.24,
        low_console=True, spire_len=3.4, spire_rings=12, spire_r=0.5))


if __name__ == "__main__" or True:
    r, b_, g_, s_ = build_yasaka_pagoda()
    emit([r, b_, g_, s_], "structures/yasaka_pagoda.glb", AO_PAGODA,
         bevel=0.0, smooth_angle=None, budget=7700)
    for fn, name, bud in ((build_sanjunoto_pagoda, "sanjunoto_pagoda", 7300),
                          (build_koyasu_pagoda, "koyasu_pagoda", 6800)):
        clear_built()
        emit(list(fn()), "structures/%s.glb" % name, AO_PAGODA,
             bevel=0.0, smooth_angle=None, budget=bud)
    report()
