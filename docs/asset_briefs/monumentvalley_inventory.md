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
