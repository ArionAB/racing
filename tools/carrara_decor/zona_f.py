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

# Module de berma la capetele podului, inclinate cu panta drumului.
ITEMS = [
    # -X al modulului (panta) spre drum: pe dreapta yaw 0 (+X = dreapta), pe stanga 180. Usor deschise.
    # Capatul de E inainte de buza cheiului (la 0.7045 modulul de 6 m cadea 0.9 m pe lungime, la 0.7025 0.5 m).
    ("F_BermaE_D", "structures/safety_berm.glb", 0.7008, 8.2, -15.0, {"tilt": True}),
    ("F_BermaE_S", "structures/safety_berm.glb", 0.7008, -8.2, 195.0, {"tilt": True}),
    ("F_BermaV_D", "structures/safety_berm.glb", 0.7230, 8.2, 15.0, {"tilt": True}),
    ("F_BermaV_S", "structures/safety_berm.glb", 0.7230, -8.2, 165.0, {"tilt": True}),
]

KIT_Y = {
    "F_BermaE_D": 44.06, "F_BermaE_S": 44.06, "F_BermaV_D": 41.89, "F_BermaV_S": 41.89,
}
