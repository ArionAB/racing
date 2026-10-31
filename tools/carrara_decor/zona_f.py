# Decorul POI-ului F pe Track23 (Carrara), citit de tools/gen_carrara_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/carrara_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track23.tscn
# se regenereaza, nu se editeaza de mana.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("F_...")
#   glb      relativ la res://assets/models/carrara/ sau cale res:// completa (reuse din alte kituri)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale: "along" (m inainte), "scale" (uniform), "tilt" (urmeaza panta
#            drumului in lung), "coliziune" ("hull" implicit / "mesh" / "trunk" / "none"), "y" (cota
#            absoluta, altfel KIT_Y sau cota drumului - 0.3)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `ProbeCarraraMontaj.tscn -- --decor`. O piesa fara cota masurata sta la cota drumului - 0.3.
#
# GAUNTLET POI F (31 oct 2026). Cheiul de sub Ponti di Vara, dupa ce rapa 0 a fost adancita in generator
# (adancimea 40 -> 400, vezi `ravines`): podeaua plata la +16,7 pe along -5 .. +9 fata de centrul
# viaductului (frac 0,7137, x -152,5), pe toata latimea din stanga (lat -8 .. -52) si pe o fasie ingusta
# in dreapta (lat +8 .. +12, apoi treapta E1 la +35,9). Malurile: +43,8..44,2 inainte (along <= -26),
# +41,7..42,1 dupa (along >= +18). Masurat cu `--scan=0.700,0.728,0.002,-56,20,4 --under`.
#
# Ce se vede de pe pod (camera de joc: 10 m sus, 12,5 m in spate): fundul cheiului la 26 m sub tablier,
# de ambele parti. Bara (bara_poi_F): castani si ginestra pe versanti, bolovani si torentul turcoaz. Pe
# podea: apa (generatorul) si bolovanii care ies din ea. Pe malurile din stanga (inainte si dupa pod)
# castanii (coroana verde-oliv, singura pata de verde dintre E si G) si ginestra galbena, cu coroanele
# peste gol. Pe dreapta inainte de pod nu se pune nimic: e dezvaluirea amfiteatrului (E).
# Sub tablier (|lat| < 8) nimic: nu se vede si ar intra in pile.
# Pe podea toate piesele sunt FANTOME: o masina cazuta acolo e deja in ViaductNet0 (plafonul la tablier -
# 1,6, 25 m adancime, +-12 m dincolo de tablier) sau in plasa apei; o piesa solida doar ar intarzia repunerea.

_FC = 0.7137
# probe_manual judeca pe sampler (`ground_y`), care nu modeleaza peretii cheiului (da fundul sau buza): cu
# metadata asta, cand sampler-ul si terenul randat difera cu > 1,5 m, se judeca pe raycast (ca ZonaB pe
# Transfagarasan). Stancile din perete sunt in plus `scufundat` (spatele in perete prin proiect; sonda
# cere ca varful sa iasa din teren).
ZONE_META = {"ref_teren_raycast": True}

# Profilul peretelui din AVAL al cheiului (cel care sta cu fata spre camera cand intri pe pod), masurat cu
# `--scan=0.703,0.724,0.001,-52,12,4 --under` (31 oct 2026): (along fata de centrul viaductului, cota).
# Constant pe lateral de la -52 la -8. Peretele cade ~70 de grade: o piesa pusa pe el se aseaza cu cota
# muchiei din AVAL a amprentei (`_y_perete(along - adanc/2)`): spatele intra in perete, nu atarna in aer.
_PERETE_AVAL = [(6.0, 16.7), (8.6, 16.7), (10.2, 19.7), (12.0, 25.6), (15.4, 36.4), (18.0, 42.0), (21.0, 42.0)]


def _y_perete(a):
    pts = _PERETE_AVAL
    if a <= pts[0][0]:
        return pts[0][1]
    for (a0, y0), (a1, y1) in zip(pts, pts[1:]):
        if a <= a1:
            return y0 + (y1 - y0) * (a - a0) / (a1 - a0)
    return pts[-1][1]


def _vegetatie_perete():
    """Peretele din aval al cheiului (cel vazut din camera cand intri pe pod), in TREPTE de stanca.

    Runda 1 a criticului orb pe F: "peretii sunt planuri gri netede, un sant de beton; in bara versantii
    sunt plini de ginestra si castani printre stanci, pana la apa". Runda 2, dupa o prima acoperire cu
    piese mici: "cateva tufe si pietre plutesc pe perete departe una de alta, ca niste abtibilduri". Deci
    acum: trei randuri de AFLORIMENTE (blocuri informi la 2,2-3x, 5-9 m, cu spatele in perete),
    decalate de la un rand la altul ca sa se suprapuna, si in "crapaturile" dintre ele tufe de ginestra
    lipite cate doua-trei si castani mici; jos, bolovani care intra in apa. Fantome, ca tot ce e in chei.
    """
    out = []
    k = 0
    # (along, lat0) per rand de stanca; laturile la 8 m, decalate cu 4 m de la un rand la altul
    randuri = [(10.6, -11.0), (13.3, -15.0), (16.1, -11.0)]
    for ri, (a, lat0) in enumerate(randuri):
        for li in range(6):
            lat = lat0 - 8.0 * li
            if lat < -52.0:
                continue
            if ri == 0 and li % 2 == 0:
                # Dupa runda 3 (iesire (c)): randul de jos ingropa apa ("doar pete turcoaz"); din el raman
                # doar stancile din doua in doua, iar in locul celorlalte, ginestra pana la apa (mai jos).
                continue
            glb = "rocks/block_informe_a.glb" if (li + ri) % 2 else "rocks/block_informe_b.glb"
            sc = [2.4, 2.8, 2.2, 2.6, 3.0, 2.3][(li + 2 * ri) % 6] * (0.8 if ri == 0 else 1.0)
            a_ = a + (0.5 if li % 2 else -0.4)
            # originea cu o treime din inaltimea stancii SUB peretele de la origine: spatele intra in perete,
            # varful iese cu ~2/3 din ea (probe_manual: `scufundat`, varful trebuie sa iasa cu >= 0,8 m).
            # Prima varianta (cota muchiei din aval, la 3-4x) ingropa tot randul de sus: varf -2 .. -16 m.
            h_ = (3.0 if glb.endswith("_a.glb") else 1.6) * sc
            y = _y_perete(a_) - 0.3 * h_
            out.append((f"F_Stanca{k:02d}", glb, _FC, lat, (li * 53 + ri * 97) % 360,
                        {"along": a_, "scale": sc, "coliziune": "none", "y": round(y, 2), "scufundat": True}))
            k += 1
    # tufele din crapaturi: intre stancile fiecarui rand si pe muchia de sus a randului de dedesubt
    k = 0
    for ri, (a, lat0) in enumerate(randuri):
        for li in range(6):
            lat = lat0 - 4.0 - 8.0 * li
            if lat < -52.0:
                continue
            a_ = a + 1.9
            if (li + ri) % 3 == 2:
                glb, sc = ("plants/chestnut_tree_a.glb" if li % 2 else "plants/chestnut_tree_b.glb"), 0.65
                out.append((f"F_PereteCastan{k:02d}", glb, _FC, lat, (li * 71) % 360,
                            {"along": a_, "scale": sc, "coliziune": "none", "y": round(_y_perete(a_) - 0.4, 2)}))
            else:
                for di, dl in enumerate((-1.1, 1.0)):
                    out.append((f"F_PereteGinestra{k:02d}{di}", "plants/ginestra_fiorita.glb", _FC, lat + dl,
                                (li * 37 + di * 120) % 360,
                                {"along": a_ + 0.3 * di, "scale": 2.3 + 0.2 * di, "coliziune": "none",
                                 "y": round(_y_perete(a_ + 0.3 * di) - 0.4, 2)}))
            k += 1
    # ginestra si castani mici pe malul apei, in golurile randului de jos (vegetatia pana la apa)
    for i, lat in enumerate([-11.0, -27.0, -43.0]):
        for di, dl in enumerate((-2.0, 0.5, 2.6)):
            if di == 1 and i != 1:
                out.append((f"F_MalCastan{i}", "plants/chestnut_tree_b.glb", _FC, lat + dl, (i * 97) % 360,
                            {"along": 9.6, "scale": 0.6, "coliziune": "none", "y": 16.7}))
                continue
            out.append((f"F_MalGinestra{i}{di}", "plants/ginestra_fiorita.glb", _FC, lat + dl, (i * 50 + di * 110) % 360,
                        {"along": 9.0 + 0.4 * di, "scale": 2.2, "coliziune": "none", "y": round(_y_perete(8.8) + 0.1, 2)}))
    # bolovanii din apa (podeaua +16,7, apa +17,05), la piciorul peretelui si spre mijlocul albiei
    for i, (lat, a, sc) in enumerate([(-19.0, 7.6, 1.4), (-35.0, 7.4, 1.5), (-51.0, 3.0, 1.8),
                                      (-50.5, -2.5, 2.0), (-17.0, 4.0, 1.3), (-29.0, 3.0, 1.5), (-43.0, 4.4, 1.4)]):
        glb = "rocks/block_informe_a.glb" if i % 2 else "rocks/block_informe_b.glb"
        out.append((f"F_Mal{i:02d}", glb, _FC, lat, (i * 61) % 360,
                    {"along": a, "scale": sc, "coliziune": "none", "y": 16.35}))
    return out

ITEMS = [
    # -X al modulului (panta) spre drum: pe dreapta yaw 0 (+X = dreapta), pe stanga 180. Usor deschise.
    # Capatul de E inainte de buza cheiului (la 0.7045 modulul de 6 m cadea 0.9 m pe lungime, la 0.7025 0.5 m).
    ("F_BermaE_D", "structures/safety_berm.glb", 0.7008, 8.2, -15.0, {"tilt": True}),
    ("F_BermaE_S", "structures/safety_berm.glb", 0.7008, -8.2, 195.0, {"tilt": True}),
    ("F_BermaV_D", "structures/safety_berm.glb", 0.7230, 8.2, 15.0, {"tilt": True}),
    ("F_BermaV_S", "structures/safety_berm.glb", 0.7230, -8.2, 165.0, {"tilt": True}),
    # ---- TORENTUL: podeaua cheiului e sub apa (rapa 0, `custom_ravine_water` la +17,05 in generator), deci pe
    # ea stau doar bolovani: blocuri informi la 1,3-1,8x, care ies din apa, si moloz pe la maluri.
    ("F_BolovanP1", "rocks/block_informe_a.glb", _FC, -11.5, 25.0, {"along": 4.0, "scale": 1.4, "coliziune": "none"}),
    ("F_BolovanP2", "rocks/block_informe_b.glb", _FC, -18.5, 110.0, {"along": -1.5, "scale": 1.7, "coliziune": "none"}),
    ("F_BolovanP3", "rocks/block_informe_a.glb", _FC, -24.0, 200.0, {"along": 6.0, "scale": 1.3, "coliziune": "none"}),
    ("F_BolovanP4", "rocks/block_informe_b.glb", _FC, -31.0, 60.0, {"along": 1.0, "scale": 1.8, "coliziune": "none"}),
    ("F_BolovanP5", "rocks/block_informe_a.glb", _FC, -38.5, 300.0, {"along": 5.0, "scale": 1.5, "coliziune": "none"}),
    ("F_BolovanP6", "rocks/block_informe_b.glb", _FC, -46.0, 150.0, {"along": 0.0, "scale": 1.6, "coliziune": "none"}),
    ("F_BolovanP7", "rocks/block_informe_b.glb", _FC, 10.0, -30.0, {"along": 1.5, "scale": 1.4, "coliziune": "none"}),
    ("F_MolozP1", "rocks/rubble_pile_a.glb", _FC, -27.0, 0.0, {"along": -4.5, "coliziune": "none"}),
    ("F_MolozP2", "rocks/rubble_pile_b.glb", _FC, -42.0, 90.0, {"along": 8.0, "coliziune": "none"}),
    ("F_MolozP3", "rocks/rubble_pile_b.glb", _FC, -15.0, 220.0, {"along": 8.5, "coliziune": "none"}),
    # ---- malurile din stanga (buza amonte la along -21, aval la +18): castani si ginestra cu coroana peste
    # gol, ca pe versantii din bara; de pe pod se vad in jos, de la intrare incadreaza cheiul.
    # ProbeRace 32 (seed 13): o masina scoasa pe stanga de camionul 2 la capul podului s-a oprit intre modulul de
    # berma F_BermaE_S (lat -8,2, hull), ginestra M1 (lat -11, hull) si trunchiul lui M1 (lat -14): buzunar. Deci
    # ginestra de pe maluri e fantoma, iar castanii cei mai apropiati stau la >= 18 m de axa.
    ("F_CastanM1", "plants/chestnut_tree_b.glb", _FC, -18.5, 10.0, {"along": -24.0, "coliziune": "trunk"}),
    ("F_CastanM2", "plants/chestnut_tree_a.glb", _FC, -23.0, 200.0, {"along": -23.0, "coliziune": "trunk"}),
    ("F_CastanM5", "plants/chestnut_tree_b.glb", _FC, -33.0, 70.0, {"along": -23.5, "coliziune": "trunk"}),
    ("F_CastanM6", "plants/chestnut_tree_a.glb", _FC, -43.0, 130.0, {"along": -24.0, "coliziune": "trunk"}),
    ("F_GinestraM1", "plants/ginestra_fiorita.glb", _FC, -11.0, 60.0, {"along": -27.5, "scale": 1.3, "coliziune": "none"}),
    ("F_GinestraM3", "plants/ginestra_fiorita.glb", _FC, -28.0, 20.0, {"along": -22.0, "scale": 1.4, "coliziune": "none"}),
    ("F_GinestraM4", "plants/ginestra_fiorita.glb", _FC, -38.0, 160.0, {"along": -22.5, "scale": 1.4, "coliziune": "none"}),
    ("F_CastanM3", "plants/chestnut_tree_a.glb", _FC, -18.5, 120.0, {"along": 20.0, "coliziune": "trunk"}),
    ("F_CastanM4", "plants/chestnut_tree_b.glb", _FC, -25.0, -20.0, {"along": 19.5, "coliziune": "trunk"}),
    ("F_CastanM7", "plants/chestnut_tree_a.glb", _FC, -36.0, 40.0, {"along": 20.0, "coliziune": "trunk"}),
    ("F_GinestraM2", "plants/ginestra_fiorita.glb", _FC, -11.5, 10.0, {"along": 24.0, "scale": 1.3, "coliziune": "none"}),
    ("F_GinestraM5", "plants/ginestra_fiorita.glb", _FC, -30.5, 100.0, {"along": 19.0, "scale": 1.4, "coliziune": "none"}),
] + _vegetatie_perete()

# Podeaua cheiului e plata la +16,70 (`--decor --no-manual-batch` + `--scan=0.703,0.724,0.001,-52,12,4 --under`,
# 31 oct 2026); bolovanii la 16,45 (ingropati sub apa de la +17,05). Malurile: amonte +43,5..43,7 la along
# -22..-24, aval +42,0..42,1 la +19..20; castanii pe trunchi (coroana trece peste gol, minimul amprentei minte).
_PODEA = 16.67
KIT_Y = {
    "F_BermaE_D": 44.06, "F_BermaE_S": 44.06, "F_BermaV_D": 41.89, "F_BermaV_S": 41.89,
    "F_BolovanP1": 16.45, "F_BolovanP2": 16.45, "F_BolovanP3": 16.45, "F_BolovanP4": 16.45,
    "F_BolovanP5": 16.45, "F_BolovanP6": 16.45, "F_BolovanP7": 16.45,
    "F_MolozP1": _PODEA, "F_MolozP2": _PODEA, "F_MolozP3": _PODEA,
    "F_CastanM1": 43.5, "F_CastanM2": 43.5, "F_CastanM5": 43.45, "F_CastanM6": 43.4,
    "F_GinestraM1": 44.0, "F_GinestraM3": 43.5, "F_GinestraM4": 43.45,
    "F_CastanM3": 41.95, "F_CastanM4": 41.95, "F_CastanM7": 41.95,
    "F_GinestraM2": 41.85, "F_GinestraM5": 41.95,
}
