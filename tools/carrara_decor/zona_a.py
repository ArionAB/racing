# Decorul POI-ului A pe Track23 (Carrara), citit de tools/gen_carrara_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/carrara_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track23.tscn
# se regenereaza, nu se editeaza de mana.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("A_...")
#   glb      relativ la res://assets/models/carrara/ sau cale res:// completa (reuse din alte kituri)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale: "along" (m inainte), "scale" (uniform), "tilt" (urmeaza panta
#            drumului in lung), "coliziune" ("hull" implicit / "mesh" / "trunk" / "none"), "y" (cota
#            absoluta, altfel KIT_Y sau cota drumului - 0.3)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `ProbeCarraraMontaj.tscn -- --decor`. O piesa fara cota masurata sta la cota drumului - 0.3.

# Coridorul de blocuri pe ambele parti, containerul, rezervorul, lampa. Coridorul din stanga se opreste
# inainte de iesirea camionului 1 (x > -50, lat -7 .. -34).
ITEMS = [
    ("A_StivaS1", "rocks/block_stack_b.glb", 0.012, -9.0, 3.0),
    ("A_BlocS2", "rocks/marble_block_c.glb", 0.018, -8.6, -4.0),
    ("A_StivaS3", "rocks/block_stack_a.glb", 0.024, -9.2, 5.0),
    ("A_StivaS4", "rocks/block_stack_b.glb", 0.031, -9.0, -2.0),
    ("A_BlocS5", "rocks/marble_block_b.glb", 0.036, -8.5, 7.0),
    ("A_StivaS6", "rocks/block_stack_a.glb", 0.042, -9.1, -5.0),
    ("A_StivaD1", "rocks/block_stack_a.glb", 0.014, 9.2, -3.0),
    ("A_StivaD2", "rocks/block_stack_b.glb", 0.021, 9.4, 4.0),
    ("A_BlocD3", "rocks/marble_block_c.glb", 0.027, 9.0, 2.0),
    ("A_StivaD4", "rocks/block_stack_b.glb", 0.034, 9.4, -6.0),
    ("A_StivaD5", "rocks/block_stack_a.glb", 0.040, 9.2, 3.0),
    ("A_Container", "buildings/office_container.glb", 0.004, -13.0, 90.0),
    ("A_Rezervor", "props/fuel_tank.glb", 0.0085, -12.5, 0.0),
    ("A_Lampa", "props/work_lamp.glb", 0.046, 9.5, 180.0),
]

KIT_Y = {
    "A_StivaS1": 24.65, "A_BlocS2": 24.64, "A_StivaS3": 24.63, "A_StivaS4": 24.62, "A_BlocS5": 24.63,
    "A_StivaS6": 24.62, "A_StivaD1": 24.67, "A_StivaD2": 24.67, "A_BlocD3": 24.67, "A_StivaD4": 24.67,
    "A_StivaD5": 24.67, "A_Container": 24.66, "A_Rezervor": 24.65, "A_Lampa": 24.67,
}
