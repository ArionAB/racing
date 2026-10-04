# Inventar — kitul Monument Valley (Track19)

Contract: `docs/asset_briefs/monumentvalley_kit.md`. Cotele sunt MASURATE din GLB
(`verify_glb.py`, Godot Y-up; Blender +Y = Godot -Z).

## rocks/west_mitten.glb (pilot, revizia 3 — volum: tapering, coloane pe patru fete, fusta inalta)

| nod | slot(uri) | tri |
|---|---|---:|
| `Mitten_Rock` | TILE_TERRACOTTA 23 + RUST_METAL 10 (fetele cu normala spre -X) | 5096 |
| `Mitten_Scree` | RUST_METAL 10 + LARCH_RUST 27 (fetele coastelor alternante, bolovani alternanti) | 3944 |
| `Mitten_Cap` | SAND_LIGHT 0 (contract schimbat din MARBLE_GREY 29) | 392 |
| total | `VERDICT KIT: OK` (`--origin=assembly`) | 9432 |

Cote masurate: peretele 29,1 m + calota 0,9 m = **30,0 m**, varf plat (coloane
28,8-29,1 m); la baza X -12..+13 (cu talpa si iesirile coloanelor), ~13-14 m
adancime, **se ingusteaza ~15%** spre varf (placa calotei X -10,6..+10,9); calota
depaseste cu ~0,45 m pe X si ~0,7 m pe Y; deget x **-21,1..-15,3** (5,8 m la
baza), **26,0 m**, gol ~2,2 m la baza (talpa coloanelor), ~4,6 m la mijloc;
fusta x -23,9..+23,9 (raza ~22-24 m), **7,4 m** inalta langa perete (bolovani
incluși), scade la 0 la margine; origine la baza turnului (XY pastrat, Z min = 0).

Fidelitate: `docs/asset_briefs/img/monumentvalley_fidelity/west_mitten.png`
(decupare | randare), 4 azimuturi: `west_mitten_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| vârf | bloc cu vârf plat, calotă continuă | toate coloanele la 29,1 ±0,3 m, o placă continuă | OK |
| coloane | ~8 late pe fata lunga, teșite | ~24 pe TOT conturul (4 fete, colturi rotunjite din 2-3 coloane), 2-4 m, iesiri variate (+0,6 / -0,8..-1,2 m: ~30% in recese), muchii teșite, fata in V | OK; planșa are mai putine coloane, mai late |
| taper + praguri | masa mai larga jos, 2-3 retrageri | ingustare ~15% spre varf pe ambele axe, 2 praguri (~1/3, ~2/3) | OK |
| talpă | evazată ~20% | evazată pe Y ~1,4 m în ultimii ~5,8 m | OK (doar pe Y, nu pe X) |
| calotă | placă bej care depășește peretele, 2 trepte | o singură placă pe conturul coloanelor, +0,45/0,7 m, 2 trepte (0,9 + 0,4 m), SAND_LIGHT | OK; conturul planșei e mai festonat |
| fustă | coaste radiale, turnul asezat IN ea | 28 coaste radiale, 2 praguri de 0,3 m, urca la ~7,4 m langa perete, ~90 bolovani mari (margine/vai) + 40 mici | OK; coastele sunt mai netede decât pe planșă |
| deget | separat, bază groasă, 2 praguri, vârf rotunjit-ascuțit | separat, baza 5,8 m -> ~3 m, 2 praguri orizontale (8 și 17 m), ultimii ~2 m în 2 fatete -> vârf bont, 26 m | OK |
| gol de cer | vizibil până jos | 3,3 m la bază; vizibil din față și din 3 azimuturi; din spate degetul se suprapune corpului (acceptat) | OK |
| luminozități | stânga umbrită | fețele -X pe RUST_METAL | OK |
| proporție h/l turn | ~1,1-1,2 | 30/24 = 1,25 | la limita ±15% |

Abateri rămase: coloanele sunt tot prisme regulate (fara rupturi interne ca pe
planșă); taper-ul se citeste moderat din 3/4; degetul are doar ~2,2 m
fata de talpa coloanelor la baza (contract 3 m masurat de la perete); fusta e
mai neteda decat desenul, iar bolovanii mari sunt putini pe fata de jos.

## Stare la oprire

- Pilotul `west_mitten` livrat, revizia 3 făcută (volum: coloane pe patru fete cu
  taper si recese, fustă înaltă; păstrate vârful plat, calota SAND_LIGHT, coastele, degetul). Harnasul
  (`monument_shapes.py`, `preview_monument.py` + `compose_monument.py`,
  `verify_monumentvalley.sh`) funcționează.
- Vocabularul `monument_shapes.py` a fost refăcut la revizie (`wall_columns` pe
  tot conturul (rev. 3: sectoare pe arc, taper, recese), `cap_slab`, `scree_ribs`, `tapered_spire`); `east_mitten`
  și restul pot folosi aceleași funcții.
- `preview_monument.py` pune clasa `mv_sandstone` (#B8552E) pe nodurile `*_Rock`.
