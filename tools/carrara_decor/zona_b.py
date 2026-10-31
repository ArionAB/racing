# Decorul POI-ului B pe Track23 (Carrara), citit de tools/gen_carrara_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/carrara_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track23.tscn
# se regenereaza, nu se editeaza de mana.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("B_...")
#   glb      relativ la res://assets/models/carrara/ sau cale res:// completa (reuse din alte kituri)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale: "along" (m inainte), "scale" (uniform), "tilt" (urmeaza panta
#            drumului in lung), "coliziune" ("hull" implicit / "mesh" / "trunk" / "none"), "y" (cota
#            absoluta, altfel KIT_Y sau cota drumului - 0.3)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `ProbeCarraraMontaj.tscn -- --decor`. O piesa fara cota masurata sta la cota drumului - 0.3.

# Geometria masurata (ProbeCarraraMontaj --scan, 31 oct 2026), lateral + = dreapta sensului:
#   T1 0.058-0.093 (+25, spre E): berma din cod la +6, bancul +7.5..+12.5, buza la +13 (jos: platoul lui T2);
#       stanga plata (+24.3) pana departe.
#   ac1 0.094-0.118 (dreapta): interiorul = dreapta, NIMIC acolo; exteriorul = stanga.
#   rampa 0.118-0.145 (spre V): stanga cade la -12 (fara berma, fara plasa), dreapta = platoul T2.
#   T2 0.145-0.168 (+16, spre V): berma la -6, bancul -7.5..-11, buza la -12; dreapta plata pana la
#       peretele F1 de la +21..+24. PlasaA ocupa +13.5..+25 (banda de cadere de pe T1): decorul sta sub +13.
#   ac2 0.178-0.208 (stanga): interiorul = stanga, NIMIC acolo; exteriorul = dreapta.
#   rampa 0.208-0.232 (spre E): dreapta cade la +13 spre fund (0.5); stanga = platoul T3.
#   T3 0.232-0.266 (+7, spre E): berma la +6, bancul +7.5..+12.5, buza la +13; stanga plata pana la
#       peretele F2 de la -26. PlasaT2 ocupa -14..-25.5 pana la x -6 (frac 0.247): dupa ea, piciorul
#       peretelui e liber.
# Camionul 1 (spre noi): banda stanga pe T1, T2 (dupa 0.160) si T3; banda dreapta pe ac1 si rampa lui.
# Decorul sta pe partea opusa, sau la >= 8 m de banda lui (generatorul marcheaza sub 6 m).
# Masinile de fir: yaw -150 pe dreapta (+150 pe stanga) ca fata volantului (axa X) sa se vada din camera
# de joc; pe peretele F2 yaw +90, firul (-Z) spre perete. Volantul se invarte (windmill.gd pe `Blades`).
SAW = "vehicles/wire_saw.glb"


def _spin(phase):
    return {"spin": {"axis": (1, 0, 0), "rpm": 30, "phase": phase}}


ITEMS = [
    # ---- T1: sirul de blocuri pe muchia bancului din dreapta, teatrul de fir, cateva stive pe stanga
    ("B_T1_Rand1", "rocks/marble_block_b.glb", 0.061, 11.0, 8.0),
    ("B_T1_Rand2", "rocks/block_stack_a.glb", 0.066, 10.8, -5.0),
    ("B_T1_Mosor", "props/cable_reel.glb", 0.0685, 8.6, 30.0),
    ("B_T1_Sarma", SAW, 0.0715, 9.9, -150.0, _spin(0.0)),
    ("B_T1_Taiat", "rocks/marble_block_c.glb", 0.0755, 10.6, 90.0),
    ("B_T1_Rand3", "rocks/block_informe_b.glb", 0.080, 10.3, 20.0),
    ("B_T1_Rand4", "rocks/marble_block_a.glb", 0.0835, 11.2, -12.0),
    ("B_T1_Rand5", "rocks/block_stack_b.glb", 0.088, 10.8, 6.0),
    ("B_T1_Rand6", "rocks/marble_block_a.glb", 0.0585, 11.2, 14.0, {"scale": 0.8}),
    ("B_T1_Rand7", "rocks/marble_block_b.glb", 0.0635, 11.3, -9.0, {"scale": 0.7}),
    ("B_T1_Rand8", "rocks/marble_block_a.glb", 0.078, 11.3, 5.0, {"scale": 0.9}),
    ("B_T1_Rand9", "rocks/marble_block_b.glb", 0.0858, 10.9, 18.0, {"scale": 0.75}),
    ("B_T1_Rand10", "rocks/marble_block_a.glb", 0.0905, 10.6, -6.0, {"scale": 0.8}),
    ("B_T1_S5", "rocks/marble_block_a.glb", 0.0715, -13.5, 25.0, {"scale": 0.8}),
    ("B_T1_S6", "rocks/marble_block_b.glb", 0.083, -19.5, -12.0, {"scale": 1.0}),
    ("B_T1_S1", "rocks/block_stack_b.glb", 0.068, -15.0, 12.0),
    ("B_T1_S2", "rocks/marble_block_c.glb", 0.074, -17.0, 70.0),
    ("B_T1_S3", "rocks/rubble_pile_a.glb", 0.080, -14.5, 0.0),
    ("B_T1_S4", "rocks/block_informe_a.glb", 0.086, -16.0, 35.0),
    # ---- ac1: berme doar la varf, pe EXTERIOR (stanga), panta (-X) spre drum = yaw 180; blocuri dincolo
    ("B_Ac1_Berma1", "structures/safety_berm.glb", 0.101, -10.0, 180.0, {"tilt": True}),
    ("B_Ac1_Berma2", "structures/safety_berm.glb", 0.105, -10.0, 180.0, {"tilt": True}),
    ("B_Ac1_Berma3", "structures/safety_berm.glb", 0.109, -10.0, 180.0, {"tilt": True}),
    ("B_Ac1_Bloc1", "rocks/marble_block_b.glb", 0.103, -13.5, 15.0),
    ("B_Ac1_Bloc2", "rocks/block_stack_a.glb", 0.107, -13.5, -10.0),
    # ---- rampa ac1 -> T2: blocuri pe muchia din stanga (fara berma acolo); dreapta e partea camionului: goala
    ("B_R1_Rand1", "rocks/marble_block_b.glb", 0.124, -9.8, 6.0),
    ("B_R1_Rand2", "rocks/marble_block_a.glb", 0.131, -9.9, -9.0),
    ("B_R1_Rand3", "rocks/block_informe_b.glb", 0.138, -9.8, 25.0),
    ("B_R1_Rand4", "rocks/marble_block_a.glb", 0.1275, -10.0, 12.0, {"scale": 0.8}),
    ("B_R1_Rand5", "rocks/marble_block_b.glb", 0.1345, -10.0, -5.0, {"scale": 0.75}),
    ("B_R1_Rand6", "rocks/marble_block_a.glb", 0.1415, -10.1, 20.0, {"scale": 0.9}),
    # ---- T2: stanga = sirul de pe muchie. Dreapta: teatrul abia de la 0.162: pana acolo camionul e pe banda DREAPTA
    # (H1_INNER, lane1) si impinge masinile spre dreapta (ProbeRace r1 s4: o masina impinsa la 0.153 in mosor/moloz).
    ("B_T2_Mosor", "props/cable_reel.glb", 0.1625, 9.6, 15.0),
    ("B_T2_Moloz", "rocks/rubble_pile_b.glb", 0.1595, 12.2, 40.0),
    ("B_T2_Sarma2", SAW, 0.165, 10.3, -150.0, _spin(240.0)),
    ("B_T2_Taiat2", "rocks/block_informe_a.glb", 0.1685, 11.3, 25.0),
    ("B_T2_Foraj", "vehicles/drill_rig.glb", 0.172, 10.8, -90.0),
    ("B_T2_Bloc", "rocks/marble_block_b.glb", 0.1755, 11.2, -6.0),
    ("B_T2_R6", "rocks/marble_block_a.glb", 0.1455, -10.3, -14.0, {"scale": 0.8}),
    ("B_T2_R7", "rocks/marble_block_b.glb", 0.151, -10.2, 8.0, {"scale": 0.7}),
    ("B_T2_R8", "rocks/marble_block_a.glb", 0.1563, -10.3, 3.0, {"scale": 0.9}),
    ("B_T2_R9", "rocks/marble_block_b.glb", 0.1615, -10.2, -10.0, {"scale": 0.75}),
    ("B_T2_R10", "rocks/marble_block_a.glb", 0.1672, -10.3, 16.0, {"scale": 0.8}),
    ("B_T2_R1", "rocks/marble_block_b.glb", 0.148, -10.0, 5.0),
    ("B_T2_R2", "rocks/block_stack_a.glb", 0.154, -10.0, -8.0),
    ("B_T2_R3", "rocks/marble_block_a.glb", 0.159, -10.2, 10.0),
    ("B_T2_R4", "rocks/block_informe_b.glb", 0.164, -10.0, 30.0),
    ("B_T2_R5", "rocks/marble_block_b.glb", 0.170, -10.2, -4.0),
    # ---- ac2: berme la varf, pe EXTERIOR (dreapta), panta spre drum = yaw 0; blocuri dincolo
    ("B_Ac2_Berma1", "structures/safety_berm.glb", 0.193, 10.0, 0.0, {"tilt": True}),
    ("B_Ac2_Berma2", "structures/safety_berm.glb", 0.197, 10.0, 0.0, {"tilt": True}),
    ("B_Ac2_Berma3", "structures/safety_berm.glb", 0.201, 10.0, 0.0, {"tilt": True}),
    ("B_Ac2_Bloc1", "rocks/block_stack_b.glb", 0.195, 13.5, 10.0),
    ("B_Ac2_Bloc2", "rocks/marble_block_b.glb", 0.199, 13.5, -15.0),
    # ---- rampa ac2 -> T3: muchia din dreapta (cade spre fund, fara berma), stanga sub banda de cadere
    ("B_R2_Rand1", "rocks/marble_block_b.glb", 0.212, 10.0, -6.0),
    ("B_R2_Rand2", "rocks/block_informe_b.glb", 0.220, 10.0, 15.0),
    ("B_R2_Rand3", "rocks/marble_block_a.glb", 0.227, 10.2, 4.0),
    ("B_R2_Rand4", "rocks/marble_block_a.glb", 0.216, 10.2, 9.0, {"scale": 0.8}),
    ("B_R2_Rand5", "rocks/marble_block_b.glb", 0.2235, 10.1, -12.0, {"scale": 0.75}),
    ("B_R2_Rand6", "rocks/marble_block_a.glb", 0.23, 10.3, 2.0, {"scale": 0.9}),
    ("B_R2_S1", "rocks/rubble_pile_b.glb", 0.218, -11.8, 20.0),
    # ---- T3: dreapta = sirul de pe muchie + teatrul. Stanga: doar langa drum, inainte de 0.247; dupa, platoul de sub
    # rampa acului 1 (cade la -12 fara berma si fara plasa) e locul unde aterizeaza masinile cazute: ProbeRace r1 s3,
    # o masina cazuta de pe rampa a lovit teava de la -16 cu 28.7 m/s (ejectare). Piciorul peretelui F2 ramane gol.
    ("B_T3_R1", "rocks/block_stack_b.glb", 0.234, 10.8, -4.0),
    ("B_T3_Sarma", SAW, 0.241, 9.9, -150.0, _spin(60.0)),
    ("B_T3_Taiat", "rocks/marble_block_c.glb", 0.2445, 10.8, 90.0),
    ("B_T3_R2", "rocks/marble_block_a.glb", 0.250, 11.2, 7.0),
    ("B_T3_Sarma3", SAW, 0.2575, 9.9, -150.0, _spin(300.0)),
    ("B_T3_R3", "rocks/block_informe_b.glb", 0.255, 10.8, -20.0),
    ("B_T3_R4", "rocks/marble_block_b.glb", 0.260, 11.0, 5.0),
    ("B_T3_R5", "rocks/block_stack_a.glb", 0.264, 10.8, -7.0),
    ("B_T3_R6", "rocks/marble_block_a.glb", 0.2365, 11.2, 10.0, {"scale": 0.8}),
    ("B_T3_R7", "rocks/marble_block_b.glb", 0.2475, 11.1, -8.0, {"scale": 0.7}),
    ("B_T3_R8", "rocks/marble_block_a.glb", 0.2528, 11.3, 15.0, {"scale": 0.9}),
    ("B_T3_R10", "rocks/marble_block_a.glb", 0.262, 11.2, 20.0, {"scale": 0.8}),
    ("B_T3_S3", "rocks/marble_block_a.glb", 0.239, -12.5, -15.0, {"scale": 0.9}),
    ("B_T3_S4", "rocks/marble_block_b.glb", 0.2455, -12.8, 22.0, {"scale": 0.8}),
    ("B_T3_S1", "rocks/rubble_pile_a.glb", 0.236, -12.0, 0.0),
    ("B_T3_S2", "rocks/marble_block_b.glb", 0.242, -11.5, 12.0),
]

KIT_Y = {
    "B_T1_Rand1": 24.67, "B_T1_Rand2": 24.67, "B_T1_Sarma": 24.67, "B_T1_Taiat": 24.6, "B_T1_Rand3": 24.23,
    "B_T1_Rand4": 23.77, "B_T1_Rand5": 22.82, "B_T1_Rand6": 24.67, "B_T1_Rand7": 24.67, "B_T1_Rand8": 24.44,
    "B_T1_Rand9": 23.21, "B_T1_Rand10": 22.51, "B_T1_S5": 24.52, "B_T1_S6": 23.67, "B_T1_S1": 24.46,
    "B_T1_S2": 24.24, "B_T1_S3": 24.04, "B_T1_S4": 23.4, "B_Ac1_Berma1": 21.72, "B_Ac1_Berma2": 20.97,
    "B_Ac1_Berma3": 19.99, "B_Ac1_Bloc1": 20.97, "B_Ac1_Bloc2": 20.1, "B_R1_Rand1": 17.6, "B_R1_Rand2": 17.21,
    "B_R1_Rand3": 16.38, "B_R1_Rand4": 17.36, "B_R1_Rand5": 16.91, "B_R1_Rand6": 16.11, "B_T2_Moloz": 15.67,
    "B_T2_Sarma2": 15.61, "B_T2_Taiat2": 15.45, "B_T2_Foraj": 15.0, "B_T2_Bloc": 14.68, "B_T2_R6": 15.74,
    "B_T2_R7": 15.67, "B_T2_R8": 15.67, "B_T2_R9": 15.66, "B_T2_R10": 15.58, "B_T2_R1": 15.67,
    "B_T2_R2": 15.67, "B_T2_R3": 15.67, "B_T2_R4": 15.64, "B_T2_R5": 15.32, "B_Ac2_Berma1": 12.41,
    "B_Ac2_Berma2": 11.78, "B_Ac2_Berma3": 11.16, "B_Ac2_Bloc1": 11.93, "B_Ac2_Bloc2": 11.46, "B_R2_Rand1": 9.55,
    "B_R2_Rand2": 8.47, "B_R2_Rand3": 7.47, "B_R2_Rand4": 9.09, "B_R2_Rand5": 7.97, "B_R2_Rand6": 7.07,
    "B_R2_S1": 8.78, "B_T3_R1": 6.78, "B_T3_Sarma": 6.67, "B_T3_Taiat": 6.67, "B_T3_R2": 6.67,
    "B_T3_Sarma3": 6.65, "B_T3_R3": 6.67, "B_T3_R4": 6.6, "B_T3_R5": 6.45, "B_T3_R6": 6.71,
    "B_T3_R7": 6.67, "B_T3_R8": 6.67, "B_T3_R10": 6.55, "B_T3_S3": 6.69, "B_T3_S4": 6.67,
    "B_T3_S1": 6.71, "B_T3_S2": 6.67,
    # mosoarele nu apar in --decor (mesh-ul lor intra in coacerea DecorManual): cota din --scan, teren plat
    "B_T1_Mosor": 24.67, "B_T2_Mosor": 15.67,
}
