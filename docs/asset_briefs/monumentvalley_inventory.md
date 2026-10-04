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

## Grupa mv-a (sandstone_arch, east_mitten, merrick_butte, mesa_wall_module)

Build: `tools/blender/build_monument_rocks.py` (vocabular extins în `monument_shapes.py`:
`prism_xz`, `buttress`, `scree_boulders`, `mesa_run`, `mesa_scree`, `chamfer(skip=)`).
West Mitten nemodificat: 9432 tri, aceleași noduri. Verify: `VERDICT KIT: OK`
(`--origin=assembly`). Planșa grupei: `img/monumentvalley_fidelity_vala.png`.

| fișier | noduri | tri | cote măsurate |
|---|---|---:|---|
| `rocks/sandstone_arch.glb` | `Arch_Rock/_Scree/_Cap` | 5190 | 13,0 m înalt; puntea x ±12 (+1,1 talpa); adâncime Y ~7,4 m (rock), ~8,6 m cu calota; fusta până la x ±18 |
| `rocks/east_mitten.glb` | `EastMitten_Rock/_Scree/_Cap` | 8910 | turn 27,0 m, amprentă ~22 x 12 m, deget pe **+X** (centru x = 17,1), 23 m, fusta ≤ ~7,5 m |
| `rocks/merrick_butte.glb` | `Butte_Rock/_Scree/_Cap` | 11928 | 24,0 m, amprentă ~30 x 18 m, 3 contraforturi (13/18/11 m) pe fața +Y |
| `rocks/mesa_wall_module.glb` | `Mesa_Rock/_Scree/_Cap` | 2224 | 12,0 m pe Y, 14,0 m înalt, 6 m adânc (X −3..+3; 8,6 cu ieșirile și talpa), grohotiș 2,9 m (+X) / 1,9 m (−X) |

### CONTRACT ÎNGHEȚAT: golul arcului (`sandstone_arch.glb`, rev. 3 — blocuri)

Măsurat cu `tools/blender/measure_arch_gap.py` pe GLB-ul exportat (re-importat),
proiecție pe planul XZ (drumul merge pe Y), TOATE nodurile (rocă + grohotiș +
calotă), grilă 5 cm; gol = regiune liberă de la sol, conectată la axa drumului.

- **lățime gol pe fereastra caroseriei (h 0–2 m): 15,35 m** (minim pe rânduri; contract ≥ 14)
- **înălțime liberă pe |x| ≤ 1,1 m: 8,85 m** (contract ≥ 7,5)
- lățimea golului: h 0,5 m 15,65 | h 2 m 15,35 | h 4 m 14,30 | h 6 m 12,30 | h 7,5 m 10,45
- intrados nominal superelipsă a = 7,9, b = 9,4, n = 2,4; fiecare bloc îl poate coborî în gol cu max 0,4 m (jos) / 0,7 m (sus), deci nu e un semicerc curat; nimic din grohotiș nu trece de x = ±7,9.
Orice modificare a arcului se re-măsoară cu scriptul (`VERDICT GOL: OK`).
Cote: 13,09 m înalt, picioarele ~7 m late la bază (talpă evazată), adâncime Y ~7,4 m (rock), 4648 tri.

### Fidelitate (decupare vs randare)

**sandstone_arch** (rev. 3, după verdictul coordonatorului: viaduct neted → limbaj de blocuri)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| picioare | masive, late jos, din blocuri | ~7 m la bază, blocuri stivuite (rânduri 3–5,4 m; 2 blocuri pe grosime unde > 5,4 m), teșite, decalate ±0,4–0,8 m, 2 felii pe adâncime cu ieșiri diferite | OK, dar mai zvelte decât pe planșă |
| punte | grosime variabilă (5 m umeri, 3 m coamă) | ~3,2 m la coamă, ~5–6 m la umeri | OK |
| intrados | nu e semicerc | trepte ±0,4–0,7 m între blocuri | OK, abatere mică (rămâne lizibil ca arc) |
| calotă | 3–5 plăci separate, goluri, înălțimi diferite | 5 plăci, goluri 0,3 m, plafoane la 12,75–13,1 m | OK; plăcile urmăresc curba la umeri |
| grohotiș | bolovani la picioare | fustă + bolovani doar pe exterior | OK |
| h/l | ~0,55 | 13/28 = 0,47 | la limita; lățimea a crescut (picioare late, contract: ~24 m) |

Abateri: arcul e mai larg (~28 m + talpă) decât ~24 m din tabel, ca să iasă picioare de ~7 m
lățime cu golul păstrat; blocurile sunt mai netede și mai rotunjite decât roca din decupare;
puntea rămâne mai subțire/regulată decât pe planșă.

**east_mitten** (runda 1)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| turn | bloc cu coloane late, vârf plat | ~16 coloane pe patru fețe, seed 23, 1,8–3,6 m (altă împărțire decât West) | OK |
| deget | pe dreapta, turlă, gol de cer | pe +X (oglindă), 23 m, gol ~3 m; din față (+Y) apare în STÂNGA, deci randarea de comparație e din spate (azimut 262) | OK, oglindirea declarată |
| calotă | placă bej în trepte | 2 trepte SAND_LIGHT | OK |
| fustă | coaste radiale, praguri | 28 coaste, 2 praguri, ~116 bolovani | OK; mai netedă |
| h/l | ~1,2 | 27/22 = 1,23 | OK |

**merrick_butte** (runda 1)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| bloc | lat, vârf plat, coloane | 24 m, ~14 coloane, taper 8% | OK |
| contraforturi | 2–3 pe fața lungă | 3 stâlpi (13/18/11 m), evazați, umăr înclinat | OK; mai netezi decât pe planșă |
| calotă | plată, în trepte | 2 trepte SAND_LIGHT | OK |
| grohotiș | fustă joasă, bolovani mulți | 64 coaste, ~130 bolovani | OK |
| h/l | ~0,8 | 24/30 = 0,8 | OK |

**mesa_wall_module** (runda 1)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| coloane | 4–5 pe modul | 5 (2 de capăt identice + 3), V pe față și spate | OK; mai uniforme decât planșa |
| capete | — | **identice**: aceleași puncte (x, z) la y = −6 și +6 (verificat pe GLB: 16/16 vârfuri Rock, 8/8 Cap, 42/42 Scree), plane, fără teșire pe colțurile de capăt; 3 module cap la cap în `mesa_wall_module_chain.png`: fără fisură | OK |
| calotă | continuă, bucăți | placă continuă în 2 trepte, capete plane | OK |
| grohotiș | bolovani la picior | coaste perpendiculare (perioadă 3 m) ≤ 3 m + 9 bolovani | OK; mai puțini bolovani decât planșa |

Abateri: coloanele rămân prisme netede (fără rupturi interne); grohotișul modulului e o
rampă cu coaste, puțini bolovani. Fața peretelui de masă e pe **+X** (spatele −X, mai
scund): coordonatorul îl rotește la montare.

## Stare la oprire

- Pilotul `west_mitten` livrat, revizia 3 făcută (volum: coloane pe patru fete cu
  taper si recese, fustă înaltă; păstrate vârful plat, calota SAND_LIGHT, coastele, degetul). Harnasul
  (`monument_shapes.py`, `preview_monument.py` + `compose_monument.py`,
  `verify_monumentvalley.sh`) funcționează.
- Vocabularul `monument_shapes.py` a fost refăcut la revizie (`wall_columns` pe
  tot conturul (rev. 3: sectoare pe arc, taper, recese), `cap_slab`, `scree_ribs`, `tapered_spire`); `east_mitten`
  și restul pot folosi aceleași funcții.
- `preview_monument.py` pune clasa `mv_sandstone` (#B8552E) pe nodurile `*_Rock`.
