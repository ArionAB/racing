# Decorul POI-ului C pe Track24 (Angkor), citit de tools/gen_angkor_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/angkor_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track24.tscn
# se regenereaza (`python tools/gen_angkor_route.py scenes/tracks/Track24.tscn`), nu se editeaza de mana.
# Fractiile zonei (pe INDEX): 0.114-0.318.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("C_...")
#   glb      relativ la res://assets/models/angkor/ ("kit/naga_head.glb") sau cale res:// completa (reuse)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, + = spre STANGA, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale:
#     "along"      m inainte pe axa fata de frac (negativ = inapoi)
#     "scale"      uniform
#     "y"          cota ABSOLUTA; altfel KIT_Y[nume]; altfel cota drumului + "dy" (implicit -0,3)
#     "dy"         decalaj fata de cota drumului in punctul de pe axa
#     "world"      (x, z) in Godot, absolut: ignora frac/lateral; yaw devine absolut (0 = -Z al piesei spre nord, -Z)
#     "coliziune"  "hull" (implicit in world_prop) / "mesh" / "trunk" / "none"
#     "anchor"     (x, y, z) local = metadata/ancora_sol pentru probe_manual (piese cu originea in aer)
#     "scufundat"  True: infipta prin proiect (probe_manual o iarta daca varful iese din teren)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `godot --headless --path . res://tools/ProbeCarraraMontaj.tscn -- --track=16 --decor`.
# FOREST: zone MeshForest (fantome, fara coliziune) — vezi jungla.py; FOREST_GLBS = stem -> glb.

ITEMS = [
]

KIT_Y = {
}

# ---- POI C: templul-munte Phnom Bakheng. Terenul (masurat cu --wgrid pe harta Godot) are un platou la
# +29..31 intre x -140 si -115 (z -230..-185) care coboara spre E: la x -90 e ~+24, la x -80 ~+20. Soseaua
# urca pe x -56 (la dreapta lui, spre N) si trece pe sus pe z ~ -254, deci piramida sta in interiorul
# buclei, cu FATA spre E (se vede de pe urcare), cu etaje de 6 m treapta si 1,9 m inaltime, platforma de
# sus (+32,1) fiind la ~26 m de axa platformei (x -138) si sub inaltimea camerei (+10 m peste sosea).
# Modulele sunt etajul kitului (8 x 1,5 x 4,04 m) la scara S: L = 12,8, h = 2,4, adancime 6,5.
S = 1.6
MOD = 8.0 * S - 0.1                  # pas intre module, cu o ghidare de 10 cm de suprapunere
CZ = -213.0                          # axa piramidei (Godot z)
YAW_E = -90.0                        # -Z al piesei spre E (+X)
# (nume, x fata, cota baza, nr. module): fiecare etaj incepe cu 6 m mai in spate si cu 1,9 m mai sus
LEVELS = [(-88.0, 23.8, 4), (-94.0, 25.7, 3), (-100.0, 27.6, 3), (-106.0, 29.5, 2), (-112.0, 31.4, 2)]
TOP_Y = 31.4 + 1.5 * S               # fata de sus a ultimului etaj

ITEMS = []
KIT_Y = {}
for li_, (fx_, by_, n_) in enumerate(LEVELS):
    for mi_ in range(n_):
        zc_ = CZ + (mi_ - (n_ - 1) / 2.0) * MOD
        nm_ = f"C_Tier{li_}_{mi_}"
        ITEMS.append((nm_, "kit/bakheng_terrace_tier.glb", 0.0, 0.0, YAW_E,
                      {"world": (fx_ - 4.04 * S / 2.0, zc_), "scale": S, "y": by_, "scufundat": True}))


# Scara centrala: una pe etaj, pe axa, lipita de fata etajului urmator (varful ei = fata de sus a etajului).
# Rampa kitului: h 2,94 x lungime 3,46 x latime 2,02 la scara 1.
for li_, (fx_, by_, n_) in enumerate(LEVELS):
    rise_ = 1.5 * S if li_ == 0 else 1.9
    sc_ = rise_ / 2.94
    y0_ = by_ if li_ == 0 else LEVELS[li_ - 1][1] + 1.5 * S
    ITEMS.append((f"C_Stair{li_}", "kit/bakheng_side_stair.glb", 0.0, 0.0, YAW_E,
                  {"world": (fx_ + 3.46 * sc_ / 2.0, CZ), "scale": sc_, "y": y0_, "scufundat": True}))

# Balustrade naga pe paliere, de-o parte si de alta a scarii (modul de 4 m, lungimea pe X dupa yaw 90).
for li_ in range(1, 4):
    fx_ = LEVELS[li_ - 1][0]
    for sg_ in (-1, 1):
        ITEMS.append((f"C_Naga{li_}{'N' if sg_ < 0 else 'S'}", "kit/naga_balustrade.glb", 0.0, 0.0, 90.0,
                      {"world": (fx_ - 3.0, CZ + sg_ * 2.4), "y": LEVELS[li_ - 1][1] + 1.5 * S, "scufundat": True}))

# Turnuletele-altar: trei pe etajul de sus (cel din mijloc mai mare), cate doua pe fiecare palier dedesubt.
TOWERS = [(-115.0, CZ, 1.8), (-115.0, CZ - 8.0, 1.4), (-115.0, CZ + 8.0, 1.4)]
for li_ in range(4):
    fx_, by_, n_ = LEVELS[li_]
    TOWERS.append((fx_ - 3.0, CZ - (n_ * MOD) / 2.0 + 4.5, 1.15))
    TOWERS.append((fx_ - 3.0, CZ + (n_ * MOD) / 2.0 - 4.5, 1.15))
for ti_, (tx_, tz_, ts_) in enumerate(TOWERS):
    ty_ = TOP_Y if ti_ < 3 else LEVELS[(ti_ - 3) // 2][1] + 1.5 * S   # palierul etajului (ti_-3)//2
    ITEMS.append((f"C_Shrine{ti_}", "kit/bakheng_shrine_tower.glb", 0.0, 0.0, YAW_E,
                  {"world": (tx_, tz_), "scale": ts_, "y": ty_, "scufundat": True}))

FOREST = [
    {"kind": "disc", "center": (-95.0, CZ - 14.0), "radius": 19.0, "claim": True, "label": "templul-munte Bakheng nord"},
    {"kind": "disc", "center": (-95.0, CZ + 14.0), "radius": 19.0, "claim": True, "label": "templul-munte Bakheng sud"},
    {"kind": "disc", "center": (-112.0, CZ), "radius": 15.0, "claim": True, "label": "templul-munte Bakheng sus"},
    # culoare de vedere dinspre urcare (x -56) si dinspre bucla de sus (z -254) spre fata templului
    {"kind": "disc", "center": (-74.0, CZ + 12.0), "radius": 14.0, "claim": True, "label": "vedere Bakheng urcare 1"},
    {"kind": "disc", "center": (-74.0, CZ - 14.0), "radius": 14.0, "claim": True, "label": "vedere Bakheng urcare 2"},
    {"kind": "disc", "center": (-92.0, -246.0), "radius": 9.0, "claim": True, "label": "vedere Bakheng bucla 1"},
    {"kind": "disc", "center": (-76.0, -245.0), "radius": 9.0, "claim": True, "label": "vedere Bakheng bucla 2"},
]
