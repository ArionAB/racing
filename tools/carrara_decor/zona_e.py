# Decorul POI-ului E pe Track23 (Carrara), citit de tools/gen_carrara_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/carrara_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track23.tscn
# se regenereaza, nu se editeaza de mana.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("E_...")
#   glb      relativ la res://assets/models/carrara/ sau cale res:// completa (reuse din alte kituri)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale: "along" (m inainte), "scale" (uniform), "tilt" (urmeaza panta
#            drumului in lung), "coliziune" ("hull" implicit / "mesh" / "trunk" / "none"), "y" (cota
#            absoluta, altfel KIT_Y sau cota drumului - 0.3)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `ProbeCarraraMontaj.tscn -- --decor`. O piesa fara cota masurata sta la cota drumului - 0.3.
#
# GAUNTLET POI E (31 oct 2026). E e dreapta de 218 m de pe banca cea mai inalta (+45), de la gura de sus a
# galeriei (fata portalului la x 99,8, frac 0,5909) spre pod (x -115). Terenul, masurat cu
# `--scan=0.590,0.700,0.005,-40,16,4 --under`: platou PLAT la +44,7 pe toata stanga (-40 .. -4) si pe
# banca din dreapta pana la buza (lat +12); dincolo de buza, treapta E1 la +35,9 si restul scarii spre
# fundul carierei. Drumul sta la +45,0. Pozitiile in lung sunt `along` fata de fata portalului (_F0).
#
# Trei planuri, ca in bara (bara_poi_E: blocurile taiate in sir pe muchia drumului, peretele taiat cu
# dare de rugina, molozul la picior):
#   1. DREAPTA: cordonul CONTINUU de blocuri taiate pe banca, la lat ~+10 (intre berma din cod, 4,6-7, si
#      buza de la +12), cu moloz la picior (vezi `_sir_dreapta`). FANTOME: dincolo de berma o piesa solida face buzunarul in care ramane o masina
#      (A_R2a, valul 1); masinile care trec de berma aici cad oricum in PlasaE. Joase (1,5-2 m), deci
#      dezvaluirea amfiteatrului ramane intreaga peste ele.
#   2. STANGA, curtea de sus: blocul-semn (quarry_sign_block la 2,2x, fata slefuita spre camera),
#      mosorul, lampa si foreza intr-un nucleu de lucru, stive si moloz, toate la >= 9 m de axa.
#   3. STANGA, peretele taiat: fata de carieră de deasupra bancii, din blocuri mari (marble_block_c la
#      3x = 9 x 6 x 6 m) cap la cap pe lat -27, cu o a doua treapta in spate (4,5x, lat -35). Inchide
#      orizontul plat de bej din stanga (captura de baza 0,63: platou gol pana la creasta).
# Aripile de beton ale ramei galeriei (Track._tun_frame, TUNNEL_WING_*: 14 m, 2,5 m inaltime, de la
# semilatime la +3,5) sunt geometrie de cod, nu decor: se lasa, iar in spatele lor stau blocuri, ca
# aripile sa citeasca zid de sprijin al unei curti de blocuri, nu doua lame de beton pe platou gol.

_F0 = 0.5909
# Golul din perete pentru CAMIONUL 2: bucla lui se termina pe E la x -70 (along ~170) si iese din drum
# spre stanga, pana la lat -30 pe ~20 m inapoi (`truck_curve`, exit_off (8,7) (16,18) (20,30)), unde
# dispare. Peretele se intrerupe pe along 128-186: camionul iese printr-o spartura a fetei, ca pe un drum
# de serviciu, iar generatorul nu mai marcheaza nicio piesa `PREA APROAPE`.
_GOL_CAMION = (128.0, 186.0)


def _sir_dreapta():
    """Cordonul de pe banca din dreapta, pe muchia dinspre gol (lat ~10, buza la +12).

    Runda 1 a criticului orb: sirul de cuburi izolate la 7 m citea "stalpisori de trafic, praf gol intre
    ei". In bara cordonul e CONTINUU: blocuri taiate cap la cap, doua-trei marimi, unele puse doua
    randuri, moloz unghiular la picior si varsat peste buza. Deci: un rand de baza cu goluri de 0,3-0,6 m
    (marble_block_c pe lung, 3 m, alternat cu marble_block_b, 2 m, cu scara si abateri mici), un al
    doilea rand (marble_block_a) pe fiecare al treilea bloc, si gramezi de moloz la picior / peste buza.
    Totul FANTOMA (vezi antetul): dincolo de berma, orice piesa solida e buzunar.
    """
    out = []
    jit = [2.0, -3.0, 1.0, 4.0, -2.0, 0.0, 3.0, -4.0, 1.5, -1.0]
    lat_j = [0.0, 0.35, -0.3, 0.2, -0.4, 0.3, -0.1]
    k = 0
    a = 18.0
    while a <= 208.0:
        big = k % 3 != 1
        sc = [1.0, 1.15, 1.25, 1.05][k % 4]
        if k % 7 == 5:
            # grup de blocuri mici (1,5 m), doua alaturate: sirul se rupe in grupuri de marimi diferite
            out.append((f"E_SirMic{k:02d}", "rocks/marble_block_a.glb", _F0, 9.2, 90.0 + jit[(k + 1) % len(jit)],
                        {"along": a + 0.8, "coliziune": "none"}))
            glb, half, h, sc = "rocks/marble_block_a.glb", 0.75, 1.5, 1.0
            a = a + 1.9
        elif big:
            glb, half, h = "rocks/marble_block_c.glb", 1.5 * sc, 2.0 * sc
        else:
            glb, half, h = "rocks/marble_block_b.glb", 1.0 * sc, 2.0 * sc
        a_c = a + half
        out.append((f"E_Sir{k:02d}", glb, _F0, 10.0 + lat_j[k % len(lat_j)], 90.0 + jit[k % len(jit)],
                    {"along": a_c, "scale": sc, "coliziune": "none"}))
        if big and k % 3 == 0:
            # al doilea rand: un bloc de 1,5 m pe blocul mare, decalat spre drum
            out.append((f"E_SirSus{k:02d}", "rocks/marble_block_a.glb", _F0, 9.6 + lat_j[(k + 2) % len(lat_j)],
                        90.0 - jit[k % len(jit)], {"along": a_c - 0.4, "coliziune": "none",
                                                   "y": 44.66 + h - 0.05}))
        # moloz: banda CONTINUA la piciorul blocurilor, pe partea dinspre DRUM (lat ~8,3, intre berma si
        # blocuri: partea pe care o vede camera), cate o gramada la fiecare bloc, plus aschii (informe_b
        # mic) si moloz varsat peste buza (lat 12,3) la un bloc din trei. Runda 2 a criticului orb: "nicio banda de moloz; blocuri
        # identice la pas egal" — gramezile la un bloc din patru, la 0,8x si sub buza, nu se vedeau.
        out.append((f"E_SirMoloz{k:02d}", "rocks/rubble_pile_b.glb" if k % 2 else "rocks/rubble_pile_a.glb",
                    _F0, 8.3 + lat_j[(k + 4) % len(lat_j)], jit[k % len(jit)] * 25.0,
                    {"along": a_c + half * 0.5, "scale": [0.75, 0.9, 0.7, 0.85][k % 4],
                     "coliziune": "none", "y": 44.45}))
        if k % 3 == 1:
            # si varsat peste buza, dincolo de blocuri
            # (lat 11,3: centrul pe banca, marginea peste buza; la 12,3 jumatate atarna peste treapta E1)
            out.append((f"E_SirBuza{k:02d}", "rocks/rubble_pile_a.glb", _F0, 11.3, jit[(k + 5) % len(jit)] * 25.0,
                        {"along": a_c, "scale": 1.1, "coliziune": "none", "y": 44.1}))
        if k % 2 == 0:
            out.append((f"E_SirAschie{k:02d}", "rocks/block_informe_b.glb", _F0, 8.4 + lat_j[k % len(lat_j)],
                        jit[(k + 3) % len(jit)] * 30.0, {"along": a_c + half + 0.2,
                                                         "scale": [0.5, 0.7, 0.6][k % 3],
                                                         "coliziune": "none", "y": 44.6}))
        a = a_c + half + [0.3, 0.6, 0.4, 0.5][k % 4]
        k += 1
    return out


def _perete_stanga():
    """Fata taiata din stanga: treapta din fata (lat -27, 6 m) si cea din spate (lat -35, 9 m)."""
    out = []
    k = 0
    a = 20.0
    lat_j = [0.0, 0.7, -0.5, 0.3, -0.8, 0.5]
    sc_j = [3.0, 3.25, 3.0, 3.4, 3.1, 3.0]
    while a <= 212.0:
        if _GOL_CAMION[0] <= a <= _GOL_CAMION[1]:
            a += 9.0
            continue
        out.append((f"E_Perete{k:02d}", "rocks/marble_block_c.glb", _F0, -27.0 + lat_j[k % 6], 90.0,
                    {"along": a, "scale": sc_j[k % 6]}))
        k += 1
        a += 9.0
    k = 0
    a = 26.0
    while a <= 212.0:
        if _GOL_CAMION[0] - 6.0 <= a <= _GOL_CAMION[1]:
            a += 13.5
            continue
        out.append((f"E_PereteSus{k:02d}", "rocks/marble_block_c.glb", _F0, -36.0 + lat_j[(k + 3) % 6], 90.0,
                    {"along": a, "scale": 4.5}))
        k += 1
        a += 13.5
    return out



def _moloz_stanga():
    """Runda 3 a criticului orb: "podeaua bancii e o placa goala, cu cateva stive razlete; in bara molozul
    e ingramadit la piciorul fiecarui perete taiat si risipit printre blocuri — banca arata lucrata, nu
    maturata". Deci: un sort de moloz la piciorul peretelui din stanga (fata lui e la lat ~-24), aschii
    risipite pe platou intre nucleul de lucru si drum (fantome: mici, unele la 4-5 m de asfalt) si ginestra
    pe sort. Nimic in golul camionului 2 (along 128-186)."""
    out = []
    k = 0
    a = 22.0
    while a <= 210.0:
        if not (_GOL_CAMION[0] - 4.0 <= a <= _GOL_CAMION[1] + 2.0):
            out.append((f"E_Sort{k:02d}", "rocks/rubble_pile_a.glb" if k % 2 else "rocks/rubble_pile_b.glb",
                        _F0, -22.6 + (0.6 if k % 3 == 0 else -0.3), (k * 67) % 360,
                        {"along": a, "scale": [1.2, 1.45, 1.1, 1.35][k % 4], "coliziune": "none", "y": 44.5}))
            if k % 3 == 1:
                out.append((f"E_SortGinestra{k:02d}", "plants/ginestra_fiorita.glb", _F0, -20.4, (k * 41) % 360,
                            {"along": a + 3.0, "scale": 1.4, "coliziune": "none"}))
        k += 1
        a += 6.5
    # aschii pe platou: informe_b la 0,4-0,7x si gramezi mici, pe o grila neregulata
    k = 0
    for a in [24.0, 33.0, 52.0, 61.0, 99.0, 108.0, 116.0, 124.0, 190.0, 199.0, 206.0]:
        for lat in (-9.0, -14.5, -19.0):
            if (k * 7) % 5 == 3:
                k += 1
                continue
            sh = (k % 4 - 1.5) * 1.3
            glb = "rocks/rubble_pile_b.glb" if k % 4 == 0 else "rocks/block_informe_b.glb"
            sc = 0.55 if k % 4 == 0 else [0.4, 0.55, 0.7][k % 3]
            out.append((f"E_Aschie{k:02d}", glb, _F0, lat + sh * 0.6, (k * 89) % 360,
                        {"along": a + sh, "scale": sc, "coliziune": "none", "y": 44.55}))
            k += 1
    return out

ITEMS = [
    # ---- In spatele aripilor ramei (along 1-15): stanga solid (dupa un zid de 2,5 m nu ajunge nimeni),
    # dreapta fantome (pe banca de dincolo de aripa, ca sirul).
    ("E_AripaS1", "rocks/block_stack_b.glb", _F0, -9.6, 92.0, {"along": 4.0}),
    ("E_AripaS2", "rocks/marble_block_c.glb", _F0, -10.6, 88.0, {"along": 8.5}),
    ("E_AripaS3", "rocks/block_stack_a.glb", _F0, -11.6, 95.0, {"along": 13.0}),
    ("E_AripaD1", "rocks/marble_block_b.glb", _F0, 9.6, 91.0, {"along": 5.0, "coliziune": "none"}),
    ("E_AripaD2", "rocks/block_stack_a.glb", _F0, 10.8, 87.0, {"along": 11.0, "coliziune": "none"}),
    # ---- nucleul de lucru din stanga: blocul-semn, foreza, mosorul, lampa, stive, moloz
    ("E_BlocSemn", "props/quarry_sign_block.glb", _F0, -15.5, 155.0, {"along": 44.0, "scale": 2.2}),
    ("E_SemnMoloz", "rocks/rubble_pile_b.glb", _F0, -11.5, 20.0, {"along": 50.0}),
    ("E_Lampa", "props/work_lamp.glb", _F0, -10.0, 200.0, {"along": 38.0}),
    ("E_Foreza", "vehicles/drill_rig.glb", _F0, -16.0, 75.0, {"along": 80.0}),
    ("E_Tambur", "props/cable_reel.glb", _F0, -11.5, 30.0, {"along": 72.0}),
    ("E_StivaF1", "rocks/block_stack_b.glb", _F0, -20.0, 92.0, {"along": 89.0}),
    ("E_StivaF2", "rocks/block_stack_a.glb", _F0, -12.5, 84.0, {"along": 94.0}),
    ("E_MolozF", "rocks/rubble_pile_a.glb", _F0, -21.0, 140.0, {"along": 70.0}),
    ("E_Stiva3", "rocks/block_stack_b.glb", _F0, -13.0, 94.0, {"along": 128.0}),
    ("E_Stiva4", "rocks/marble_block_c.glb", _F0, -12.0, 86.0, {"along": 133.5}),
    ("E_Informe1", "rocks/block_informe_a.glb", _F0, -19.5, 40.0, {"along": 120.0}),
    ("E_Moloz2", "rocks/rubble_pile_b.glb", _F0, -13.0, 200.0, {"along": 192.0}),
    ("E_Stiva5", "rocks/block_stack_a.glb", _F0, -18.0, 91.0, {"along": 175.0}),
    ("E_Ginestra1", "plants/ginestra_fiorita.glb", _F0, -22.5, 0.0, {"along": 104.0, "scale": 1.3}),
    ("E_Ginestra2", "plants/ginestra_fiorita.glb", _F0, -22.0, 90.0, {"along": 186.0, "scale": 1.3}),
] + _sir_dreapta() + _perete_stanga() + _moloz_stanga()

# Platoul e plat la +44,70 (drumul +45,0): implicitul (drum - 0,3 = 44,66) e chiar teren - 0,03 aproape
# peste tot (`--decor --no-manual-batch`, 31 oct 2026). Aici doar piesele de la capete, unde platoul coboara
# spre portal (along 20) si spre cheiul podului (along > 195).
KIT_Y = {
    "E_Perete00": 44.52, "E_Perete12": 44.56, "E_Perete13": 44.46, "E_Perete14": 44.29,
    "E_PereteSus00": 44.53, "E_PereteSus08": 44.54, "E_PereteSus09": 44.36,
}
