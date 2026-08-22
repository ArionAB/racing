"""Stromboli — dana Ginostra (brief docs/asset_briefs/stromboli_roadside.md, fisierul 3).

  GinostraPier  stromboli/props/ginostra_pier.glb
                Pier_Slab / Pier_Stairs / Pier_Fittings

Brief-ul corecteaza explicit foaia A (unde a iesit movila de stanca): forma
corecta e **dana de beton curata** din foaia B + scara alba taiata in stanca
neagra.

**Originea e la LINIA APEI**, ca la Strombolicchio: fata de sus a danei ajunge
la +0.8, picioarele coboara sub 0. Se aseaza cu `y = sea_level`.
`verify_glb --origin=waterline` verifica exact ca geometria incaleca Y=0.

Dana iese spre **-Z_godot = +Y_blender** (spre mare).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_ginostra_pier.py
"""

import math
from mathutils import Matrix, Vector

AO_CONC = dict(samples=22, dist=3.0, gradient="vertical",
               low=0.60, high=1.00, power=0.9, floor=0.35)
AO_LIME = dict(samples=22, dist=3.0, gradient="vertical",
               low=0.70, high=1.00, power=0.9, floor=0.42)
AO_FIT = dict(samples=18, dist=1.5, gradient="vertical",
              low=0.70, high=1.00, power=0.9, floor=0.45)

SLAB_L, SLAB_W = 8.0, 3.0     # 8 m spre mare (Y), 3 m lat (X)
SLAB_T = 0.8                  # grosime; fata de sus la +0.8
LIME = FOAM_WHITE
CONC = CONCRETE
ROCK = VOLCANIC_BLACK
METAL = RUST


def build_slab():
    """Placa de beton pe doua picioare scunde. Origine la linia apei."""
    b = Builder()
    # Placa: fata de sus la +SLAB_T, deci centrul la SLAB_T/2. Iese spre +Y.
    b.box((0.0, SLAB_L * 0.5, SLAB_T * 0.5), (SLAB_W, SLAB_L, SLAB_T), CONC)
    # Muchia dinspre mare, tesita: o pana subtire sub buza (brief).
    b.box((0.0, SLAB_L - 0.18, SLAB_T * 0.18),
          (SLAB_W, 0.36, SLAB_T * 0.36), CONC,
          rotation=Matrix.Rotation(math.radians(-18.0), 3, "X"))
    # Doua picioare scunde, sub apa: dana sta pe ele, nu pluteste.
    for fy in (SLAB_L * 0.28, SLAB_L * 0.78):
        b.box((0.0, fy, -0.55), (SLAB_W * 0.62, 0.9, 1.4), CONC)
    return b.to_object("Pier_Slab")


def build_stairs():
    """Scara alba pe pana de stanca neagra, la capatul dinspre uscat."""
    b = Builder()
    # Pana de stanca, IN SPATELE scarii, nu sub ea.
    #
    # Prima versiune o punea la y=-1.5 cu 2.6 m latime si 4.2 inaltime, iar
    # rampele urcau prin interiorul ei: in randare stanca plutea peste dana si
    # scara disparuse cu totul. E aceeasi greseala ca la biserica — geometrie
    # ingropata intr-o masa — doar ca aici masa era stanca.
    #
    # Corect: stanca se retrage la -Y, scara urca pe FATA ei dinspre dana.
    # Ingropata DELIBERAT: centrul la z=0.9 pe o inaltime de 6.4 duce baza la
    # -2.3, adica bine sub linia apei. `rock()` cu taper ingusteaza inelele de
    # jos, deci o pana asezata "exact" pe zero pare ca pluteste — se vede in
    # randarea laterala. Ce iese din apa e doar partea lata de sus.
    b.rock((0.0, -2.9, 0.9), (4.6, 3.4, 6.4), ROCK, seed=23, segments=7,
           rings=4, taper=0.22)

    # Doua rampe in zigzag pe fata stancii (y ~ -1.6), urcand de la dana la
    # +4 m. Zigzagul e pe X, ca sa incapa pe o fata de 4.2 m.
    w = 1.2
    runs = [((-1.1, -0.55, SLAB_T), (1.1, -1.15, 2.3)),
            ((1.1, -1.15, 2.3), (-0.9, -1.70, 4.0))]
    for (p0, p1) in runs:
        b.beam(p0, p1, (w, 0.22), LIME, up=(0, 0, 1))
        # muret scund pe exteriorul rampei (spre dana, adica +Y)
        b.beam((p0[0], p0[1] + w * 0.42, p0[2] + 0.30),
               (p1[0], p1[1] + w * 0.42, p1[2] + 0.30),
               (0.14, 0.42), LIME, up=(0, 0, 1))
    # podestul de la cotul zigzagului
    b.box((1.25, -1.15, 2.36), (1.3, 1.2, 0.24), LIME)

    return b.to_object("Pier_Stairs")


def build_fittings():
    """Doi bolarzi + un inel de acostare. Buget 150 — cel mai strans din set.

    Socoteala care a decis forma: 4 cilindri hexagonali (bolarzi cu capac) +
    un torus 6x4 = 128 de triunghiuri BRUTE, adica ~460 dupa bevel. Bugetul e
    150. Deci:
      - bevel 0 (piesele sunt metal turnat; muchia vie e corecta pentru ele)
      - bolardul e UN cilindru cu capacul putin mai lat facut din frustum, nu
        doua piese suprapuse
      - inelul de acostare e o cutie subtire, nu un torus: la 30 m (distanta
        din brief) un inel de 34 cm se citeste ca o pata, iar torusul costa
        48 de triunghiuri pentru forma lui exacta
    """
    b = Builder()
    # doi bolarzi, pe diagonala danei
    for (x, fy) in ((-(SLAB_W * 0.5 - 0.35), SLAB_L * 0.42),
                    (SLAB_W * 0.5 - 0.35, SLAB_L * 0.82)):
        # ciuperca dintr-o singura piesa: frustum care se lateste spre varf
        b.frustum((x, fy, SLAB_T + 0.19), 0.10, 0.155, 0.38, METAL,
                  segments=6)
    # inel de acostare pe muchia dinspre mare
    b.box((0.0, SLAB_L - 0.06, SLAB_T - 0.22), (0.34, 0.07, 0.30), METAL)
    return b.to_object("Pier_Fittings")


if __name__ == "__main__":
    clear_built()
    slab = build_slab()
    stairs = build_stairs()
    fit = build_fittings()

    # z_range comun: ansamblul urca de la -1.25 (picioare) la 4.3 (capul
    # scarii). Fiecare piesa si-ar coace altfel propriul gradient.
    zr = (-1.25, 4.3)
    specs = ((slab, AO_CONC, 0.06), (stairs, AO_LIME, 0.05),
             (fit, AO_FIT, 0.0))
    for obj, ao, bev in specs:
        snap = snapshot_slots(obj)
        apply_bevel(obj, bev, segments=1, angle_deg=30.0)
        apply_smooth(obj, 55.0)
        assign_uvs(obj, snap)
        obj.data.materials.clear()
        obj.data.materials.append(atlas_material())
        bake_ao(obj, z_range=zr, **ao)
        if "slot" in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes["slot"])

    objs = [slab, stairs, fit]
    for o in objs:
        print("%-16s %3d tris" % (o.name, tri_count(o)))
    print("TOTAL            %3d tris  (buget 700)"
          % sum(tri_count(o) for o in objs))
    path, size = export_glb(objs, "stromboli/props/ginostra_pier.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
