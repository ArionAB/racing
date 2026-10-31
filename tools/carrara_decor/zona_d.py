# Decorul POI-ului D pe Track23 (Carrara), citit de tools/gen_carrara_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/carrara_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track23.tscn
# se regenereaza, nu se editeaza de mana.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("D_...")
#   glb      relativ la res://assets/models/carrara/ sau cale res:// completa (reuse din alte kituri)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale: "along" (m inainte), "scale" (uniform), "tilt" (urmeaza panta
#            drumului in lung), "coliziune" ("hull" implicit / "mesh" / "trunk" / "none"), "y" (cota
#            absoluta, altfel KIT_Y sau cota drumului - 0.3)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `ProbeCarraraMontaj.tscn -- --decor`. O piesa fara cota masurata sta la cota drumului - 0.3.
#
# CE EXISTA IN D (31 oct 2026, citit din generator si din Track.gd, nu din brief):
#   - un singur tub (`TunelGalerie`, Track._build_tunnel) de la portalul de jos (0.400, +3) la cel de sus
#     (0.592, +45): 8 m latime = EXACT latimea drumului (peretii sunt marginea asfaltului, fara umar),
#     tavan 9 m, `CameraZone` pe tot intervalul (darkness 0.5, tavan 9);
#   - NU exista sala de 16 m / 18 m de la 0.46-0.50, nici stalpii de pe carosabil, nici blocul basculat
#     (RockfallHazard): brieful le cere (par.2 D, par.3), dar builderul tunelului n-are latime pe interval.
#     Decizie de dezvoltator (vezi raportul POI D). Decorul nu inventeaza sala.
# Deci in tub nu incape nimic pe sol: tot ce e inauntru e lipit de perete si FANTOMA (coliziune "none").

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


def _world(name, glb, x, z, yaw_world=None, yaw_rel=0.0, lo=0.38, hi=0.41, **opt):
    """Piesa la (x, z) in lume. `yaw_world`: directia (grade, atan2(z, x)) in care sa arate -Z al piesei;
    altfel `yaw_rel` fata de drum."""
    fr, lat, along, head = _w(x, z, lo, hi)
    yaw = (head - yaw_world) if yaw_world is not None else yaw_rel
    opt["along"] = round(along, 2)
    return (name, glb, fr, round(lat, 2), round(yaw, 1), opt)


def _road_y(fr):
    """Cota drumului la fractia data (randul copt cel mai apropiat)."""
    return min(_ROWS, key=lambda r: abs(r[4] - fr))[1]


# ---- 1. GURA DE JOS (0.393-0.400): aripile portalului si piciorul peretilor.
# Portalul de jos are fata la x 290.14 (z 36), drumul merge spre +X, dreapta = +Z. Aripile din cod
# (`Track._tun_frame`, acum pe marmura si cu muchia in panta, `frame_class` / `wing_end_height_m`) pleaca
# din peretele tubului (lat +-4) si se deschid pana la +-7.5 pe 14 m (x 290 -> 276). Bara (bara_poi_D):
# molozul la piciorul peretelui taiat, blocuri, utilajul. Molozul se sprijina pe SPATELE aripilor, ca
# aripa sa citeasca zid de sprijin care tine grohotisul, nu scandura infipta in fata portalului.
# Totul e FANTOMA: in spatele aripii nu intra nicio masina pe linie, iar marginea dreapta e locul
# ejectarii rare in rama (0.398, deschisa) -> niciun corp nou pe dreapta.
# Geometria aripii (Track._tun_frame): din (x0, lat +-4) inapoi pe 14 m pana la lat +-7.5, grosime 0.5 spre
# exterior, deci la ~14 grade de axa; muchia de sus coboara de la 2.5 la 1.1 m (`wing_end_height_m`).


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


ITEMS = wing_fill("D", 290.14, 36.0, 0.38, 0.41)
ITEMS += [
    # stanga (lat -): podeaua plata -4 .. -12, peretele urca de la -12
    _world("D_StivaS", "rocks/block_stack_b.glb", 284.0, 25.2, yaw_rel=88.0, coliziune="none"),
    _world("D_MosorS", "props/cable_reel.glb", 275.0, 27.0, yaw_rel=30.0, coliziune="none"),
    # cablurile spre galerie: doua module de conducta la piciorul peretelui stang
    _world("D_TeviS1", "props/pipe_run.glb", 265.0, 25.0, yaw_rel=0.0, coliziune="none"),
    _world("D_TeviS2", "props/pipe_run.glb", 271.0, 25.0, yaw_rel=0.0, coliziune="none"),
    # dreapta (lat +): podeaua plata +4 .. +11, peretele urca de la +12
    _world("D_InformeD", "rocks/block_informe_b.glb", 281.0, 46.6, yaw_rel=25.0, coliziune="none"),
]

# ---- 2. IN TUB: conducta de serviciu lipita de peretele din DREAPTA (interiorul acului, peretele pe care
# masinile il ating mai rar decat pe cel de la iesirea larga din ac). Modulul `pipe_run` (0.8 lat, 1.52
# inalt, 6 m) cu axa la lat +4.25: intra 0.15 m in banda, restul e in perete. Fantoma: o masina lipita
# de perete trece prin 15 cm de teava, nu se agata (memoria `obstacol-pe-drum-poate-fi-gimmick`).
# Pe dreptele tubului, nu in ac: in ac un modul drept de 6 m ar iesi din peretele curb. Pas 6 m
# (0.0029 din tur de 2070 m), inclinat cu panta (11%), cota = drumul - 3 cm.
def _pipe_run(prefix, f0, n):
    """`n` module la rand de la fractia f0: aceeasi fractie, `along` = 6 m * k (fractia pe rand ar sari cu
    ~2 m, cat pasul axei coapte). Cota = drumul interpolat in lungul axei la pozitia modulului - 3 cm."""
    i0 = min(range(len(_ROWS)), key=lambda k: abs(_ROWS[k][4] - f0))
    out = []
    for k in range(n):
        d, i = 6.0 * k, i0
        while d > 0.0:
            seg = _math.dist(_ROWS[i][:3], _ROWS[i + 1][:3])
            if d <= seg:
                break
            d -= seg
            i += 1
        t = d / _math.dist(_ROWS[i][:3], _ROWS[i + 1][:3])
        y = _ROWS[i][1] + (_ROWS[i + 1][1] - _ROWS[i][1]) * t
        out.append((f"{prefix}{k + 1}", "props/pipe_run.glb", _ROWS[i0][4], 4.25, 0.0,
                    {"along": 6.0 * k, "tilt": True, "coliziune": "none", "y": round(y - 0.03, 2)}))
    return out


ITEMS += _pipe_run("D_TeavaA", 0.4045, 6)     # dreapta de la portalul de jos spre ac
ITEMS += _pipe_run("D_TeavaB", 0.4800, 8)     # rampa de dupa ac
ITEMS += _pipe_run("D_TeavaC", 0.5400, 6)     # rampa spre portalul de sus

KIT_Y = {
    # terenul minim de sub amprenta - 3 cm (`ProbeCarraraMontaj -- --decor --no-manual-batch`: piesele
    # fantoma se coc in MultiMesh si nu apar fara flag). Conductele din tub isi iau cota din drum ("y").
    "D_MolozAripaS1": 2.87, "D_MolozAripaS2": 2.83, "D_MolozAripaS3": 3.01,
    "D_MolozAripaD1": 2.86, "D_MolozAripaD2": 2.70, "D_MolozAripaD3": 2.66,
    "D_StivaS": 3.81, "D_MosorS": 2.93, "D_InformeD": 2.86,
    "D_TeviS1": 2.82, "D_TeviS2": 3.12,
}
