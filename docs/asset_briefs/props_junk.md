# Brief asset — Gunoi bump-abil (`props_junk.glb`)

Brief auto-conținut. Sursele din care e derivat:
[style_bible.md](../style_bible.md) (estetică) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

Sursă reproductibilă: [tools/blender/build_props_junk.py](../../tools/blender/build_props_junk.py).

## De ce există

[#7](https://github.com/ArionAB/racing/issues/7) cere să transformăm „bidoanele /
anvelopele / lăzile **din decor static**" în `RigidBody`. **Alea nu existau.**
Căutate: niciun GLB de butoi, anvelopă sau ladă în `assets/models/`. Singurele
din tot proiectul sunt coapte în `gas_station.glb` (#D1), deci nu pot fi
instanțiate separat.

Issue-ul presupunea un decor care nu fusese construit niciodată. Fișierul ăsta e
prima lui jumătate; a doua e `RigidBody`-ul, în `scenes/`, la cealaltă instanță.

## Contractul, citit din cod

`scenes/props/road_marker.gd` e tiparul, și e deja `RigidBody3D` (masă 0.4,
`sleeping = true`). Două lucruri ies de acolo, și amândouă au schimbat ce am
livrat:

**1. Colizorul se măsoară din model, nu dintr-un nod `_col`.**
```gdscript
var measured := Track.model_aabb(model)      # road_marker.gd:33
cyl.radius = maxf(aabb.size.x, aabb.size.z) * 0.5
cyl.height = aabb.size.y
```
Deci proxy-uri de coliziune ar fi fost geometrie moartă care ar și **umflat
măsurătoarea**. N-am livrat niciunul. În schimb fiecare formă e aleasă să aibă un
AABB strâns — cilindri și cutii, nimic care iese în afară.

**2. Apelantul alege UN nod din GLB** și îl pasează gata ales
(`road_marker.gd:16-18`), fiindcă „110 copii identice se citesc ca un gard".
De aceea sunt **șase noduri frați**, nu un ansamblu.

## Ce conține

| nod | tris | AABB Godot (X × Y × Z) | rază cilindru |
|---|---|---|---|
| `Barrel_A` | 228 | 0.620 × 0.880 × 0.652 | 0.326 |
| `Barrel_B` | 228 | 0.601 × 0.860 × 0.632 | 0.316 |
| `Crate_A` | 132 | 0.930 × 0.650 × 0.730 | 0.465 |
| `Crate_B` | 44 | 0.620 × 0.480 × 0.550 | 0.310 |
| `TyreStack` | 480 | 0.921 × 0.746 × 0.918 | 0.461 |
| `Tyre` | 160 | 0.921 × 0.241 × 0.876 | 0.461 |
| | **1272** | | |

Toate șase: origine la bază, centrate în XZ, exportate la (0,0,0), scara lumii
(deci `model_scale = 1.0`).

Cotele sunt reale: butoiul de 55 de galoane are 0.59 m diametru și 0.88 m
înălțime; anvelopa are 0.95 m exterior.

## Decizii

- **Bugetul contează aici**, spre deosebire de valul 3: astea se **repetă**, iar
  repetiția e ce costă — lecția din #B1, unde popicele făceau 31% din toată
  pista. De aceea `Crate_B` are 44 de triunghiuri și nu 132.
- **Cercurile butoiului sunt `frustum`, nu `torus`.** Un tor de 10×4 costă 80 de
  triunghiuri, un inel drept 30, iar la 0.6 m diametru diferența nu există.
- **Lada nu are șipci individuale.** Opt cutii pentru un obiect care se repetă,
  ca să se citească ce se citește oricum din proporție și din chingi.
- **Lovituri pe butoaie**, prin împingerea vârfurilor spre axă. Un butoi perfect
  cilindric citește a obiect nou, iar astea sunt de aruncat la marginea drumului.
- **Teancul e rotit între tăvi** (13° per nivel). Un teanc perfect aliniat arată
  turnat, nu aruncat. Costă zero triunghiuri.
- **Praf pe fețele de sus**, prin `retag` — `SAND_SHADOW` pe capacul butoiului
  (acolo se adună apă și rugină), `SAND_MID` pe capacul lăzii. Zero triunghiuri.

## Ce rămâne de făcut în `scenes/`

Masele și frecarea, care sunt tuning de feel, nu de model. Punct de plecare din
mase reale, pentru un joc arcade unde vrei să zboare satisfăcător:

| | masă reală | sugestie |
|---|---|---|
| butoi gol | ~20 kg | 1.2 |
| ladă | ~25 kg | 1.5 |
| anvelopă | ~9 kg | 0.6 |
| teanc de 3 | ~27 kg | 2.0 |

Pentru comparație, `road_marker.gd` folosește `mass = 0.4` pe un stâlp de 1.2 m.
Restul — limita de corpuri active, `sleeping = true` până la impact — e chiar ce
cere #7 și e deja rezolvat în tiparul stâlpului.
