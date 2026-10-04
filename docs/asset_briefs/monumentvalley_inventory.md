# Inventar — kitul Monument Valley (Track19)

Contract: `docs/asset_briefs/monumentvalley_kit.md`. Cotele sunt MASURATE din GLB
(`verify_glb.py`, Godot Y-up; Blender +Y = Godot -Z).

## rocks/west_mitten.glb (pilot, revizia 2 dupa verdictul coordonatorului)

| nod | slot(uri) | tri |
|---|---|---:|
| `Mitten_Rock` | TILE_TERRACOTTA 23 + RUST_METAL 10 (fetele cu normala spre -X) | 1960 |
| `Mitten_Scree` | RUST_METAL 10 + LARCH_RUST 27 (fetele coastelor alternante, bolovani alternanti) | 3544 |
| `Mitten_Cap` | SAND_LIGHT 0 (contract schimbat din MARBLE_GREY 29) | 236 |
| total | `VERDICT KIT: OK` (`--origin=assembly`) | 5740 |

Cote masurate: peretele 29,1 m + calota 0,9 m = **30,0 m**, varf plat (variatie
coloane 0,3 m); X -12..+12 (24 m), adancime ~13-14 m; calota depaseste cu ~0,45 m
pe X si ~0,7 m pe Y (placa X -12,45..+12,45); deget x **-21,1..-15,3** (5,8 m
la baza, ~3,5 m pe la 2/3), **26,0 m**, gol **3,3 m** fata de corp la baza
(2,85 m la nivelul calotei); fusta x -24..+24,8 (raza ~22-24 m), **4,5 m** inalta
(bolovani incluși); origine la baza turnului (XY pastrat, Z min = 0).

Fidelitate: `docs/asset_briefs/img/monumentvalley_fidelity/west_mitten.png`
(decupare | randare), 4 azimuturi: `west_mitten_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| vârf | bloc cu vârf plat, calotă continuă | toate coloanele la 29,1 ±0,3 m, o placă continuă | OK |
| coloane pe fața lungă | ~8 late, teșite | 8 coloane (~3 m), muchii teșite cu 2 fatete pe colț, fața în V | OK; planșa are coloane mai neregulate |
| praguri orizontale | 2-3 retrageri | 2 (la ~1/3 și ~2/3), retragere ~0,45 m | OK |
| talpă | evazată ~20% | evazată pe Y ~1,4 m în ultimii ~5,8 m | OK (doar pe Y, nu pe X) |
| calotă | placă bej care depășește peretele, 2 trepte | o singură placă pe conturul coloanelor, +0,45/0,7 m, 2 trepte (0,9 + 0,4 m), SAND_LIGHT | OK; conturul planșei e mai festonat |
| fustă | coaste radiale, 1-2 praguri slabe, bolovani la margine/în văi | 28 coaste radiale (vale/creastă), 2 praguri de 0,3 m, ~70 bolovani mari (la margine, în văi) + 40 mici dincolo de margine | OK ca structură; coastele sunt mai netede decât pe planșă |
| deget | separat, bază groasă, 2 praguri, vârf rotunjit-ascuțit | separat, baza 5,8 m -> ~3 m, 2 praguri orizontale (8 și 17 m), ultimii ~2 m în 2 fatete -> vârf bont, 26 m | OK |
| gol de cer | vizibil până jos | 3,3 m la bază; vizibil din față și din 3 azimuturi; din spate degetul se suprapune corpului (acceptat) | OK |
| luminozități | stânga umbrită | fețele -X pe RUST_METAL | OK |
| proporție h/l turn | ~1,1-1,2 | 30/24 = 1,25 | la limita ±15% |

Abateri rămase: peretele e mai "geometric" decât planșa (prisme regulate, aceeași
adâncime); capătul X (fața de 13 m) citit din azimut 35 e o față lată, netezită;
fusta e mai joasă și mai netedă decât desenul; gol la nivelul calotei 2,85 m
(contract 3 m, la bază 3,3 m).

## Stare la oprire

- Pilotul `west_mitten` livrat, revizia 2 făcută (vârf plat, coloane late
  teșite, calotă SAND_LIGHT, fustă cu coaste, deget bont). Harnasul
  (`monument_shapes.py`, `preview_monument.py` + `compose_monument.py`,
  `verify_monumentvalley.sh`) funcționează.
- Vocabularul `monument_shapes.py` a fost refăcut la revizie (`wall_columns` cu
  teșire + 3 segmente, `cap_slab`, `scree_ribs`, `tapered_spire`); `east_mitten`
  și restul pot folosi aceleași funcții.
- `preview_monument.py` pune clasa `mv_sandstone` (#B8552E) pe nodurile `*_Rock`.

## Grupa mv-b: plante (`build_monument_plants.py`, revizia 3 dupa verdictul coordonatorului)

Verdict: `bash tools/blender/verify_monumentvalley.sh` -> `VERDICT KIT: OK` (juniper si
rabbitbrush cu `--origin=assembly`, rabbitbrush cu `--allow-car-slots=Rabbitbrush_Bloom`).
Comparatii: `img/monumentvalley_fidelity/<nume>.png`; planșa: `img/monumentvalley_fidelity_valb.png`.
Yucca acceptata (neschimbata).

**Verificarea culorilor (punctul 0).** Tabelul `PALETTE_HEX` din `preview_monument.py` e
IDENTIC cu `HEX` din `scripts/palette.gd` (verificat pe toate cele 32 de intrari). UV-urile din
GLB-uri (citite din fisier) cad exact pe sloturile intentionate, vezi coloana "sloturi (fete)".
Deci verdele "ierbos" NU e o eroare de mapare: slotul 12 chiar e `#5B7C34` (91,124,52),
iar randarea preview il da (70-77, 96-105, 39-43) dupa AO+lumina. Pe `juniper` randarea
masurata e (70,96,39), oliv-verde si nu mai palid; am pastrat 12 (nu 21) fiindca
TROPICAL_GREEN `#3F7A3C` e mai albastrui. Slotul 12 e "oliv sters" doar in comparatie cu 21.

| fisier | noduri (sloturi, fete) | tri | cote (m) | RGB randat masurat |
|---|---|---:|---|---|
| sagebrush | `Sagebrush`: WOOD 9 + DRY 13 (tulpini, frunze pe sol, 505 tri); `Sagebrush_Foliage`: CACTUS 12 (toate smocurile, 840 tri) | 1345 | 1,38 x 1,33 x 1,12 | verde slot 12 (tenta gri-verde = clasa la integrare) |
| juniper | `Juniper_Trunk` WOOD 9; `Juniper_Crown` CACTUS 12 | 2089 | 4,37 x 3,88 x 4,21 | coroana (70,96,39) |
| rabbitbrush | `Rabbitbrush` CACTUS 12 + DRY 13; `Rabbitbrush_Bloom` CAR_YELLOW 16 | 2424 | 1,54 x 1,53 x 1,21 | flori (163,141,43) |
| tumbleweed | `Tumbleweed` LARCH_RUST 27 | 2726 | 0,93 x 0,94 x 0,96 | (132,82,45) |

| piesa / element | pe decupare | in GLB | verdict |
|---|---|---|---|
| sagebrush | smocuri fine, gri-verzi | 15 smocuri-flacara pe 5 tulpini lemnoase ramificate, toate pe CACTUS 12 in `Sagebrush_Foliage` (rev. 4: fara amestec 29/12; paloarea vine din tenta de clasa) | structura OK; culoarea finala depinde de clasa/tenta coordonatorului |
| juniper trunchi | tulpini rasucite din pamant | 3 tulpini rasucite pornite din baza comuna, ramificate la 1,2-1,5 m, 2 ramuri joase orizontale | OK |
| juniper coroane | ciorchini la inaltimi diferite | 8 ciorchini turtiti (2 joase pe laturi), 5 bulgari fiecare | OK; desenul are volume mai mari si mai dese |
| rabbitbrush | perna densa, frunzis verde dedesubt | 48 ciorchini x 2 bulgari pe dom (treimile de sus/mijloc), inel de 18 frunzulite CACTUS 12, tulpini ascunse | perna OK; frunzisul e mai rar decat pe desen |
| tumbleweed | retea de crengute arama | neschimbat ca forma, culoare LARCH_RUST 27 | OK; bucle poligonale |
