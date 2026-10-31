# Decorul POI-ului H pe Track23 (Carrara), citit de tools/gen_carrara_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/carrara_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track23.tscn
# se regenereaza, nu se editeaza de mana.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("H_...")
#   glb      relativ la res://assets/models/carrara/ sau cale res:// completa (reuse din alte kituri)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale: "along" (m inainte), "scale" (uniform), "tilt" (urmeaza panta
#            drumului in lung), "coliziune" ("hull" implicit / "mesh" / "trunk" / "none"), "y" (cota
#            absoluta, altfel KIT_Y sau cota drumului - 0.3)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `ProbeCarraraMontaj.tscn -- --decor`. O piesa fara cota masurata sta la cota drumului - 0.3.
#
# CE EXISTA IN H (31 oct 2026): tubul `TunelMarmifera` (Track._build_tunnel, 8 m, tavan 7 m, 0.951-0.974)
# cu movila lui de 40 m, portalul `marmifera_portal.glb` la ambele guri (zidarie pe `tf_stone`), masivul
# `MasivMarmifera` (TerrainPeak). Drumul din tub e acum pe PRAF ca restul turului (generatorul,
# `dirt`): asfaltul inchis cu linie alba de mijloc citea sosea de oras.
# Bara (bara_poi_H): portal de zidarie intr-o panta stancoasa cu vegetatie, o stiva de blocuri si un
# excavator in fata. La noi portalul sta intr-o sa de teren plata (cota +27..28 pe +-14 m), deci panta
# stancoasa o fac molozul de pe spatele aripilor si castanii / ginestra de pe movila.

import csv as _csv
import math as _math
import os as _os

_ROWS = [tuple(map(float, r.values())) for r in _csv.DictReader(open(
    _os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "..", "data", "carrara_baked.csv"),
    encoding="utf-8"))]


def _w(x, z, lo, hi):
    """Lume (x, z Godot) -> (frac, lateral, along, directia drumului in grade) pe randul copt cel mai apropiat."""
    i = min((k for k in range(len(_ROWS)) if lo <= _ROWS[k][4] <= hi),
            key=lambda k: (_ROWS[k][0] - x) ** 2 + (_ROWS[k][2] - z) ** 2)
    j, k = min(i + 1, len(_ROWS) - 1), max(i - 1, 0)
    dx, dz = _ROWS[j][0] - _ROWS[k][0], _ROWS[j][2] - _ROWS[k][2]
    l_ = _math.hypot(dx, dz)
    fx, fz = dx / l_, dz / l_
    ox, oz = x - _ROWS[i][0], z - _ROWS[i][2]
    return _ROWS[i][4], ox * -fz + oz * fx, ox * fx + oz * fz, _math.degrees(_math.atan2(fz, fx))


def _world(name, glb, x, z, yaw_world=None, yaw_rel=0.0, lo=0.93, hi=0.952, **opt):
    """Piesa la (x, z) in lume. `yaw_world`: directia (grade, atan2(z, x)) in care sa arate -Z al piesei;
    altfel `yaw_rel` fata de drum."""
    fr, lat, along, head = _w(x, z, lo, hi)
    yaw = (head - yaw_world) if yaw_world is not None else yaw_rel
    opt["along"] = round(along, 2)
    return (name, glb, fr, round(lat, 2), round(yaw, 1), opt)


# Gura de intrare: fata portalului la x -250.30 (z -105), drumul spre +X, dreapta = +Z. Aripile din cod
# (marmura, muchia in panta) se deschid de la lat +-4 la +-7.5 pe 14 m (x -250 -> -264).
def wing_fill(prefix, x0, z0, lo, hi):
    """Molozul de pe spatele celor doua aripi ale unui portal cu fata la (x0, z0), drumul spre +X, dreapta = +Z
    (Galeria jos si Marmifera intrare au aceeasi orientare). Trei gramezi pe aripa, descrescand cu ea: la
    radacina (2.5 m) cea mai mare. Marginea dinspre drum a fiecarei gramezi sta la 15 cm DINCOLO de spatele
    aripii (lat 4.5 + 3.5 t), deci nimic nu iese prin aripa in banda. (Conul de grohotis a fost incercat si
    scos: e o jumatate de con fara fata pe latura plana, deci privit dinspre drum e invizibil.)"""
    out = []
    for side, sgn in (("S", -1.0), ("D", 1.0)):
        for k, (t, sc, glb, yaw) in enumerate(((0.10, 1.6, "rocks/rubble_pile_a.glb", 20.0),
                                                (0.45, 1.4, "rocks/rubble_pile_b.glb", -40.0),
                                                (0.80, 1.1, "rocks/rubble_pile_a.glb", 75.0))):
            r_ = 2.0 * sc if glb.endswith("_a.glb") else 1.5 * sc
            lat = 4.5 + 3.5 * t + 0.15 + r_
            out.append(_world(f"{prefix}_MolozAripa{side}{k + 1}", glb, round(x0 - 14.0 * t, 2), round(z0 + sgn * lat, 2),
                              yaw_rel=yaw * sgn, lo=lo, hi=hi, scale=sc, coliziune="none"))
    return out


ITEMS = wing_fill("H", -250.30, -105.0, 0.93, 0.952)
ITEMS += [
    # vegetatia de pe movila de deasupra portalului (castani, ginestra), ca in bara
    _world("H_CastanS", "plants/chestnut_tree_a.glb", -244.0, -116.0, yaw_rel=30.0, coliziune="none"),
    _world("H_CastanD", "plants/chestnut_tree_b.glb", -241.0, -92.5, yaw_rel=-60.0, coliziune="none"),
    _world("H_GinestraS", "plants/ginestra_fiorita.glb", -248.0, -119.5, yaw_rel=0.0, scale=1.3, coliziune="none"),
    _world("H_GinestraD", "plants/ginestra_fiorita.glb", -247.0, -90.0, yaw_rel=90.0, scale=1.3, coliziune="none"),
    # in fata, pe dreapta: stiva de blocuri, un bloc si excavatorul parcat (bara), departe de banda (lat >= 11)
    _world("H_Stiva", "rocks/block_stack_a.glb", -261.0, -93.8, yaw_rel=6.0, coliziune="none"),
    _world("H_Bloc", "rocks/marble_block_c.glb", -265.5, -92.0, yaw_rel=-12.0, coliziune="none"),
    _world("H_Excavator", "vehicles/quarry_excavator.glb", -256.5, -90.5, yaw_rel=-150.0),
]

KIT_Y = {
    # terenul minim de sub amprenta - 3 cm (`ProbeCarraraMontaj -- --decor --no-manual-batch`: piesele
    # fantoma se coc in MultiMesh si nu apar fara flag).
    "H_MolozAripaS1": 26.62, "H_MolozAripaS2": 26.89, "H_MolozAripaS3": 27.32,
    "H_MolozAripaD1": 26.62, "H_MolozAripaD2": 26.81, "H_MolozAripaD3": 26.98,
    "H_CastanS": 26.97, "H_CastanD": 29.71, "H_GinestraS": 30.38, "H_GinestraD": 29.17,
    "H_Stiva": 27.01, "H_Bloc": 27.22, "H_Excavator": 27.10,
}
