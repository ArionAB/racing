"""Stromboli, kit de sat — casa A (brief docs/asset_briefs/stromboli_village_kit.md, piesa 1).

  AeolianHouseA  stromboli/buildings/aeolian_house_a.glb
                 House_A

Casa cubica de baza a satului: 7 x 6 x 4 m, acoperis-terasa cu parapet
rotunjit, usa + doua ferestre cu obloane, pergola mica peste intrare.

**Identitatea kitului e BEVELUL.** Varul gros nu are colturi vii — 0.10 m pe
tot corpul. E singura piesa de stil care tine kitul impreuna, si de-asta e
scumpa: bevelul tripleaza triunghiurile (masurat pe tot proiectul). Bugetul de
900 e calculat cu asta in minte.

**Golurile nu se taie.** Usa si ferestrele sunt panouri retrase — dar aici,
spre deosebire de biserica, retragerea chiar functioneaza fiindca panourile
stau IN FATA peretelui, la 0.15 m in interiorul unei rame care iese. Vezi
build_stromboli_church.py pentru cazul in care nu merge (panou impins intr-un
solid = invizibil).

Fatada e spre -Z_godot = +Y_blender.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_aeolian_house_a.py
"""

import math
from mathutils import Matrix, Vector

AO_HOUSE = dict(samples=26, dist=4.0, gradient="vertical",
                low=0.68, high=1.00, power=0.9, floor=0.32)

W, D, H = 7.0, 6.0, 4.0        # latime (X), adancime (Y), inaltime
FACADE = D * 0.5               # planul fatadei, +Y
PARAPET = 0.55

LIME = FOAM_WHITE
SHUTTER = SEA_DEEP             # albastru profund (vezi biserica: PAINTED e
                               # prea deschis pe var; masurat acolo)
VOID = ASPHALT
WOOD_S = WOOD


def _shuttered(b, center, w, h, normal_y=1.0):
    """Gol cu obloane: panou intunecat retras + doua canaturi in fata lui.

    Obloanele sunt ce se VEDE de la 5-20 m; golul intunecat din spatele lor da
    adancimea. Impreuna costa 3 cutii = ~130 de triunghiuri dupa bevel.
    """
    cx, cy, cz = center
    ny = normal_y
    # golul, retras 0.16 in perete
    b.box((cx, cy - ny * 0.16, cz), (w, 0.12, h), VOID)
    # UN singur panou de oblon, nu doua canaturi.
    #
    # Doua canaturi costa 88 de triunghiuri pe fereastra si difera de unul
    # singur printr-o dunga de 4 cm intre ele — sub un pixel la 20 m, si
    # aproape invizibila si la 5. Cu trei ferestre pe casa, diferenta e 132 de
    # triunghiuri, adica 15% din buget pentru o linie.
    b.box((cx, cy + ny * 0.03, cz), (w * 0.98, 0.07, h * 0.96), SHUTTER)


if __name__ == "__main__":
    clear_built()
    b = Builder()

    # corpul cubic
    b.box((0.0, 0.0, H * 0.5), (W, D, H), LIME)

    # Acoperis-terasa cu parapet: o rama joasa pe conturul acoperisului, nu un
    # capac plin. Parapetul e ce face casa eoliana sa citeasca "terasa", nu
    # "cutie" — de la 5-20 m silueta lui de sus e tot ce se vede din acoperis.
    pz = H + PARAPET * 0.5
    # Parapet pe TREI laturi: fata, spate si latura -X (cea care se vede din
    # ulita). Latura +X sta lipita de vecin in POI. Economie: o cutie.
    for sy in (-1, 1):
        b.box((0.0, sy * (D * 0.5 - 0.14), pz), (W, 0.28, PARAPET), LIME)
    b.box((-(W * 0.5 - 0.14), 0.0, pz), (0.28, D - 0.56, PARAPET), LIME)
    # Placa terasei NU se modeleaza: parapetul de 0.55 m o ascunde complet de
    # la nivelul drumului, iar de sus casa nu se vede (camera priveste in jos
    # doar in crater). O cutie = 44 de triunghiuri pentru zero pixeli.
    # Capacul corpului tine loc de pardoseala.

    # usa: panou albastru retras, cu prag
    door_w, door_h = 1.1, 2.1
    # Usa iese IN AFARA planului fatadei (fata la +0.03), nu ingropata.
    # Prima versiune o retragea la -0.07 si punea peste ea un "ancadrament"
    # care era o CUTIE PLINA de 1.36 x 2.32 — adica un capac. In randare usa
    # iesea alba. Aceeasi greseala ca la trim-ul bisericii.
    b.box((0.0, FACADE - 0.04, door_h * 0.5), (door_w, 0.16, door_h), SHUTTER)
    # Ancadramentul e o RAMA din trei bucati, langa gol, nu peste el.
    for sx in (-1, 1):
        b.box((sx * (door_w * 0.5 + 0.07), FACADE + 0.02, door_h * 0.5 + 0.07),
              (0.14, 0.10, door_h + 0.14), LIME)

    # Doua ferestre cu obloane pe fatada, si cate una pe fiecare latura lunga.
    # Pe fatada stau LATERAL de pergola (x = +-2.35), altfel grinzile le taie.
    for sx in (-1, 1):
        _shuttered(b, (sx * 2.35, FACADE - 0.02, 2.45), 0.95, 1.15)
    # O SINGURA fereastra laterala, pe latura -X. Inventarul de cutii (fiecare
    # 44 de triunghiuri dupa bevel) spune ca doua laturi costa 264, iar bugetul
    # de 900 nu le cuprinde. Casele se aseaza in ulita cu o latura spre camera
    # si cealalta lipita de vecin, deci a doua nu se vede niciodata.
    cx = -(W * 0.5 - 0.02)
    b.box((cx + 0.16, 0.6, 2.45), (0.12, 0.95, 1.15), VOID)
    b.box((cx - 0.03, 0.6, 2.45), (0.07, 0.94, 1.10), SHUTTER)

    # Pergola peste intrare: doua grinzi + trei sipci. Nu e umbrar plin —
    # brief-ul cere "2 grinzi + umbra", adica exact atat cat sa arunce dungi.
    py = FACADE + 0.95
    for sx in (-1, 1):
        b.box((sx * 1.25, py - 0.5, 1.35), (0.14, 0.14, 2.70), WOOD_S)
    for gy in (py - 0.9, py - 0.1):
        b.box((0.0, gy, 2.78), (3.0, 0.13, 0.13), WOOD_S)
    # Doua sipci, nu trei: 44 de triunghiuri fiecare, si a treia nu adauga
    # nimic la dungile de umbra pe care le arunca pergola.
    for gx in (-0.75, 0.75):
        b.box((gx, py - 0.5, 2.86), (0.10, 0.95, 0.10), WOOD_S)

    house = b.to_object("House_A")
    stats = finish(house, bevel=0.10, ao=AO_HOUSE, origin="base")
    print("House_A %4d tris  (buget 900)  AO %.2f..%.2f"
          % (stats["tris"], stats["ao_min"], stats["ao_max"]))
    path, size = export_glb([house], "stromboli/buildings/aeolian_house_a.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
