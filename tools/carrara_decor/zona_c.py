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
]

KIT_Y = {
    "C_Informe1": 1.05, "C_Informe2": 1.63, "C_Informe3": 1.66, "C_Informe4": 1.66, "C_Informe5": 1.59,
}
