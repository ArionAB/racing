# Decorul POI-ului C pe Track23 (Carrara), citit de tools/gen_carrara_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/carrara_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track23.tscn
# se regenereaza, nu se editeaza de mana.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("C_...")
#   glb      relativ la res://assets/models/carrara/ sau cale res:// completa (reuse din alte kituri)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale: "along" (m inainte), "scale" (uniform), "tilt" (urmeaza panta
#            drumului in lung), "coliziune" ("hull" implicit / "mesh" / "trunk" / "none"), "y" (cota
#            absoluta, altfel KIT_Y sau cota drumului - 0.3)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `ProbeCarraraMontaj.tscn -- --decor`. O piesa fara cota masurata sta la cota drumului - 0.3.

# Blocuri informe pe margini; totul sta la > 15 m de turnul derrick-ului (raza sarcinii 13 m).
ITEMS = [
    # Pe dreapta podeaua e plata (1.1-1.7) pana la 13 m; pe stanga peretele ravenei urca de la -10 m.
    # Blocurile stau la 12.5 m pe dreapta: la 8.5 m, C_Informe3 (0.375, iesirea din cotul 2 la
    # stanga, exteriorul e DREAPTA) a dat o ejectare-perete la 30 m/s pe ProbeRace (s5, ambele serii).
    # Pe stanga doar unde e INTERIORUL cotului (0.370, cotul 2); exteriorul cotului 1 (0.345) ramane gol.
    ("C_Informe1", "rocks/block_informe_a.glb", 0.298, 12.5, 20.0),
    ("C_Informe2", "rocks/block_informe_b.glb", 0.338, 12.5, -35.0),
    ("C_Informe3", "rocks/block_informe_a.glb", 0.375, 12.5, 50.0),
    ("C_Informe4", "rocks/block_informe_b.glb", 0.370, -8.8, 10.0),
    ("C_Informe5", "rocks/block_informe_b.glb", 0.352, 12.5, 50.0),

    # Ferastraul-lant pe senile (brief par.2 C: "taie la perete"): pe podeaua de +1.70 dintre balta P4 si
    # coltul peretelui de S (fata N-S de la x ~266-270, masurata cu ProbeCarraraHmap --sample). Lama e pe -Z
    # (Z -6.27 .. -2.18, inventarul crr-d), deci yaw 0 o duce spre E, in fata: corpul x 257.8-262.3, varful
    # lamei la x 266.3, unde peretele e deja la +6 (lama sta la +1.7 .. +3.3) -> ~1.3 m de lama in marmura.
    # Lat +20: departe de linia de cursa si de iesirea cotului 2. Cota: talpa senilelor e la +0.10 peste
    # origine (AABB masurat), deci KIT_Y = terenul minim - 0.03 - 0.10.
    # "along" 1.5: originea iese la x 259.0 pe indexul lui 0.3849 (nu 260), iar fara el doar ultimii 0.3 m ai
    # lamei atingeau piciorul peretelui (teren 2.6 la x 265, ProbeCarraraHmap --sample); cu 1.5 varful e la
    # x 266.7, unde peretele e la +7.6 -> ~1.5 m de lama in marmura.
    ("C_FerastrauLant", "vehicles/chain_saw_crawler.glb", 0.3849, 20.0, 0.0, {"along": 1.5}),
    # Moloz la piciorul taieturii, intre ferastrau si peretele de S (lat +14, peste pragul de 12.5).
    ("C_MolozTaietura", "rocks/rubble_pile_b.glb", 0.3878, 14.0, 30.0),

    # Gura galeriei cu lumini: doua lampi de santier de o parte si de alta a portalului (fata la x 290.1),
    # cu 4 m in fata lui, intoarse spre masinile care vin. Lat +-9: in dreptul stalpilor ramei.
    ("C_LampaGalerieD", "props/work_lamp.glb", 0.3975, 9.0, 180.0),
    ("C_LampaGalerieS", "props/work_lamp.glb", 0.3975, -9.0, 180.0),

    # Malul de calcit al baltilor: blocuri si moloz pe marginea dinspre drum a fiecarei balti (baltile sunt
    # scobituri TerrainHollow din generator, `BALTI`). Toate pe dreapta, la >= 15 m de axa.
    ("C_MalP1Bloc", "rocks/marble_block_b.glb", 0.2959, 37.0, 15.0),
    ("C_MalP1Moloz", "rocks/rubble_pile_a.glb", 0.3017, 42.0, -20.0),
    ("C_MalP2Moloz", "rocks/rubble_pile_b.glb", 0.3211, 32.9, 10.0),
    ("C_MalP2Bloc", "rocks/marble_block_a.glb", 0.3337, 31.0, 25.0),
    ("C_MalP3Bloc", "rocks/marble_block_c.glb", 0.3443, 38.0, -10.0),
    ("C_MalP3Moloz", "rocks/rubble_pile_a.glb", 0.3511, 26.9, 40.0),
    ("C_MalP4Moloz", "rocks/rubble_pile_b.glb", 0.3752, 15.6, -15.0),
    ("C_MalP4Bloc", "rocks/marble_block_a.glb", 0.3810, 15.0, 20.0),
    ("C_MalP5Moloz", "rocks/rubble_pile_a.glb", 0.3617, 24.1, 15.0),
    ("C_MalP5Bloc", "rocks/marble_block_b.glb", 0.3656, 15.7, -25.0),

    # Blocuri razlete pe podea (diorama: cuburi crem imprastiate intre balti).
    # Sirul de blocuri pe marginea dinspre balti a dreptei de sub derrick (diorama: cuburile de langa drum),
    # la lat +13.5 / +14 (pragul de 12.5 al lui C) si la > 15 m de turnul derrick-ului (generatorul verifica).
    ("C_MarginePodea1", "rocks/marble_block_c.glb", 0.3046, 13.5, 4.0),
    # (al doilea bloc, la 0.321 / lat +14, a scos o ejectare la 28 m/s pe ProbeRace s13: e interiorul de
    # dinaintea cotului 1, unde masinile taie peste podea. Scos.)
    ("C_BlocPodea1", "rocks/marble_block_b.glb", 0.3085, 24.0, 12.0),
    ("C_BlocPodea2", "rocks/marble_block_c.glb", 0.3714, 33.8, -30.0),
    ("C_BlocPodea3", "rocks/marble_block_a.glb", 0.3694, 30.3, 40.0),
    # Moloz la piciorul peretelui de N al dreptei spre portal (stanga, dupa iesirea din cotul 2).
    ("C_MolozPereteS1", "rocks/rubble_pile_a.glb", 0.3810, -11.0, 0.0),
    ("C_MolozPereteS2", "rocks/rubble_pile_b.glb", 0.3880, -10.5, 60.0),
]

KIT_Y = {
    "C_Informe1": 1.05, "C_Informe2": 1.63, "C_Informe3": 1.39, "C_Informe4": 1.66,
    "C_Informe5": 1.59, "C_FerastrauLant": 1.51, "C_MolozTaietura": 1.73, "C_MalP1Bloc": 0.04,
    "C_MalP1Moloz": -0.07, "C_MalP2Moloz": 0.74, "C_MalP2Bloc": 0.93, "C_MalP3Bloc": -0.61,
    "C_MalP3Moloz": -0.28, "C_MalP4Moloz": 1.01, "C_MalP4Bloc": 0.56, "C_MalP5Moloz": 0.03,
    "C_MalP5Bloc": -0.3, "C_MarginePodea1": 0.9, "C_BlocPodea1": 0.58, "C_BlocPodea2": 1.67,
    "C_BlocPodea3": 1.67, "C_MolozPereteS1": 2.5, "C_MolozPereteS2": 2.54,
    # lampile nu ies in `--decor` (AABB nul dupa coacerea DecorManual, ca A_Lampa): terenul minim din
    # ProbeCarraraHmap --sample pe 3x3 puncte ale amprentei (1.6 x 1.5 m), minus 3 cm.
    "C_LampaGalerieD": 3.11, "C_LampaGalerieS": 3.57,
}
