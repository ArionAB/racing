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
#   - SALA (31 oct 2026, decizia dezvoltatorului dupa valul 2): pe dreapta de dupa ac soseaua se
#     lateste la 16 m (`HALL` mai jos), iar tubul o urmeaza (`TunnelSignalHazard.hall_*`) cu tavanul
#     urcand la 16 m. In sala: doi stalpi de marmura PE carosabil, blocul basculat (RockfallHazard),
#     lampi de santier. In afara salii tubul ramane de 8 m, deci acolo tot ce e inauntru e lipit de
#     perete si FANTOMA (coliziune "none").

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
# inalt, 6 m) cu axa la lat +3.9: tevile (0.4 m) ies 0.5 m in banda, suportii intra in perete (la +4.25
# se vedeau doar varfurile suportilor, un sir de cuie). Fantoma: o masina lipita
# de perete trece prin 50 cm de teava, nu se agata (memoria `obstacol-pe-drum-poate-fi-gimmick`).
# Pe dreptele tubului, nu in ac: in ac un modul drept de 6 m ar iesi din peretele curb. Pas 6 m
# (0.0029 din tur de 2070 m), inclinat cu panta (11%), cota = drumul - 3 cm.
# ---- 3. SALA (brief par.2 POI D: „16 m latime, tavan inalt, doi stalpi de marmura lasati in picioare PE
# carosabil, decalati — alegi stanga sau dreapta fiecaruia”). Fractii pe INDEX (randurile din carrara_baked.csv,
# ~2,07 m pe rand), pe dreapta de dupa ac (iesirea din arc la ~0.472, rampa spre portalul de sus la 0.580).
#
# Latimea se declara O DATA, ca sector de drum de semilatime `hw` pe [f0, f1] (gen_carrara_route.py, intre doua
# sectoare de 4 m, intr-o fereastra de curgere): curgerea (panta 1/15) face trecerea 4 -> 8 m pe ~60 m de fiecare
# parte, IN sector, deci latimea plina tine ~0.505-0.543 (~80 m). Tubul citeste latimea drumului
# (`Track._build_tunnel`), nu o copiaza; tavanul urca proportional pana la `ceil`.
#
# Stalpii (3 x 3 m, `structures/gallery_pillar.glb`, coliziune hull) stau la -1.5 si +1.5 m de axa, 33 m unul
# de altul: pe la mijloc se trece doar in slalom (dreapta lui 1, stanga lui 2); lipit de un perete se trece
# drept (stanga: fanta de 5 m la 1, de 8 m la 2; dreapta: 8 m la 1, 5 m la 2). AI-ul nu vede decorul static
# (memoria `obstacol-pe-drum-poate-fi-gimmick`): sectorul `bias` il tine pe MARGINE, pe malul lui de
# personalitate (`custom_lane_bias`, Track.lane_bias_at, si podea TARE dupa ocolire: Track.lane_floor_at) —
# 0.70 din semilatime = 5,6 m in sala: 1,6 m de aer intre caroserie si stalpul de pe partea lui, 1,4 m pana
# la perete. Cu 0.62 (0,96 m de aer) ramaneau 3 ejectari in stalpul 2 pe 16 seed-uri (ProbeRace).
#
# Blocul basculat (RockfallHazard cu traseu, generatorul): se desprinde de pe patul de moloz de la peretele din
# DREAPTA, la `block_f`, 13 m inaintea primului stalp, si se rostogoleste pe banda dreapta pana la `block_lat`.
HALL = dict(f0=0.4758, f1=0.5716, hw=8.0, ceil=16.0, bias=(0.4932, 0.5340, 0.70),
            block_f=0.5077, block_lat=0.5)
PILLARS = (("D_StalpSala1", 0.5145, -1.5), ("D_StalpSala2", 0.5300, 1.5))
# Putul de lumina din tavanul salii (`TunnelSignalHazard.shaft_*`, generatorul): intre cei doi stalpi, ca
# raza sa cada pe drumul slalomului si sa-i lumineze din fata. `len_m` pe lungime, `lat` lateralul gaurii,
# ASIMETRIC (vezi nodul: un segment de tavan centrat pe axa e numarat gresit de ProbeBuried).
SHAFT = dict(f=round((PILLARS[0][1] + PILLARS[1][1]) * 0.5, 4), len_m=8.0, lat=(-3.5, 2.5))


def _pipe_run(prefix, f0, n, lat=3.9):
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
        out.append((f"{prefix}{k + 1}", "props/pipe_run.glb", _ROWS[i0][4], lat, 0.0,
                    {"along": 6.0 * k, "tilt": True, "coliziune": "none", "y": round(y - 0.03, 2)}))
    return out


ITEMS += _pipe_run("D_TeavaA", 0.4045, 6)     # dreapta de la portalul de jos spre ac
# In sala conducta merge pe peretele din dreapta al latimii pline (8 m), de la primul stalp incolo: inainte de el
# e patul de moloz al blocului. In trecerile de 60 m peretele se departeaza de axa (1/15), deci acolo nu se pune
# un modul drept de 6 m.
ITEMS += _pipe_run("D_TeavaB", 0.5145, 4, lat=HALL["hw"] - 0.1)
ITEMS += _pipe_run("D_TeavaC", HALL["f1"], 4)  # dupa sala, spre portalul de sus

# Stalpii: talpa la drum - 0.3 (panta de 10 % pe 3 m = +-0.15 m: nicio muchie nu pluteste); 18 m inalti, tavanul
# salii e la 16 m peste drum, deci varful intra in grosimea movilei (creasta e la tavan + 3,5).
ITEMS += [(nm, "structures/gallery_pillar.glb", f_, lat_, 0.0, {"y": round(_road_y(f_) - 0.3, 2)})
          for nm, f_, lat_ in PILLARS]
ITEMS += [
    # patul de moloz de sub blocul basculat, lipit de peretele din dreapta (fantoma: blocul isi are traseul lui)
    ("D_SalaPatMoloz", "rocks/rubble_pile_a.glb", HALL["block_f"], 7.2, 30.0,
     {"scale": 1.3, "coliziune": "none", "y": round(_road_y(HALL["block_f"]) - 0.3, 2)}),
    ("D_SalaInforme", "rocks/block_informe_b.glb", HALL["block_f"], 7.0, -20.0,
     {"along": -6.0, "coliziune": "none", "y": round(_road_y(HALL["block_f"]) - 0.6, 2)}),
    # lampile de santier, calde, la pereti: fantoma (stau pe asfalt, lipite de perete, ca teava)
    ("D_SalaLampa1", "props/work_lamp.glb", 0.5048, -7.2, 60.0,
     {"coliziune": "none", "y": round(_road_y(0.5048) - 0.3, 2)}),
    ("D_SalaLampa2", "props/work_lamp.glb", 0.5222, 7.2, -120.0,
     {"coliziune": "none", "y": round(_road_y(0.5222) - 0.3, 2)}),
    ("D_SalaLampa3", "props/work_lamp.glb", 0.5380, -7.2, 45.0,
     {"coliziune": "none", "y": round(_road_y(0.5380) - 0.3, 2)}),
]

KIT_Y = {
    # terenul minim de sub amprenta - 3 cm (`ProbeCarraraMontaj -- --decor --no-manual-batch`: piesele
    # fantoma se coc in MultiMesh si nu apar fara flag). Conductele din tub isi iau cota din drum ("y").
    "D_MolozAripaS1": 2.87, "D_MolozAripaS2": 2.83, "D_MolozAripaS3": 3.01,
    "D_MolozAripaD1": 2.86, "D_MolozAripaD2": 2.70, "D_MolozAripaD3": 2.66,
    "D_StivaS": 3.81, "D_MosorS": 2.93, "D_InformeD": 2.86,
    "D_TeviS1": 2.82, "D_TeviS2": 3.12,
}
