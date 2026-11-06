# Inventar — kit Angkor, val 1, grupul A

Contract: `docs/asset_briefs/angkor_kit.md` §1.1 (b, c) și §1.2 (Poarta de Sud).
Pe tiparul `angkor_inventory.md` (pilotul). Piesele: `bayon_face_tower_b.glb`,
`bayon_face_tower_c.glb`, `south_gate_face_tower.glb`. **Nu e acceptare**: forma se
judecă pe imagini, iar acceptarea e a coordonatorului.

Fețele sunt **simplificate, în stilul rundei 6** (decizia dezvoltatorului, 6 nov
2026): sprâncene și ochi-semilună separați, nas pană scurtă, un zâmbet, fără
discuri de obraz. Sculptura reală rămâne datorie deschisă (kit §1.1).

## Fișiere

| fișier | rol |
|---|---|
| `tools/blender/build_angkor_bayon.py` | `VARIANTE` are acum `b` și `c`; `c` poartă un dicționar `ruin` (colțul de sus, colțul bazei, nișa). Funcții noi: `broken_step`, `rubble`, `shaft_with_niche`, `make_warp` |
| `tools/blender/build_angkor_gate_south.py` | poarta; docstring cu lista de elemente scrisă înainte de geometrie |
| `tools/blender/angkor_shapes.py` | doar parametri opționali, fără efect pe `a`: `block_courses(skip=)`, `oct_prism(warp=)`, `tier(warp=, finial_skip=)` (GLB-ul `a` rebuilduit are aceleași 8.350 tri) |
| `tools/blender/preview_angkor.py` | intrări `SPECS` pentru b, c și poartă (`views_aspect`, `bury`, `face_center`, `face_dist`) |
| `tools/blender/measure_angkor_w1a.py` | garda porții + `--selftest` |
| `tools/blender/verify_angkor.sh` | blocul `# --- val 1, grupul A ---` |

## Cote măsurate (din fișier, coordonate Godot)

| | X | Z | înălțime Y | min Y |
|---|---:|---:|---:|---:|
| `bayon_face_tower_b.glb` | −1,500…+1,500 (**3,000**) | idem (**3,000**) | **9,003** | 0,000 |
| `bayon_face_tower_c.glb` | −1,500…+1,500 (**3,000**) | idem (**3,000**) | **9,004** | 0,000 |
| `south_gate_face_tower.glb` | **19,000** | **8,000** | **22,008** | 0,000 |

Poarta (garda `measure_angkor_w1a.py gate`, proiecție pe planul de-a curmezișul
drumului, triunghiuri tăiate cu dreptunghiul, inclusiv cele degenerate în proiecție):
- **golul la 0–2,5 m: 7,500 m** (cerut ≥ 7,2; nimic din juge în ±3,6 m; juga e un plan la |x| = 3,75);
- **înălțimea liberă în ±3,6 m: 8,400 m** (cerut ≥ 8; fața de jos a buiandrugului);
- centrat pe X și Z, originea la bază și la mijlocul golului.

## Triunghiuri, materiale, sloturi

| piesă | total | Stone | Lichen | Streak | materiale |
|---|---:|---:|---:|---:|---:|
| `bayon_face_tower_b` | 8.250 | 6.134 | 1.900 | 216 | 3 |
| `bayon_face_tower_c` | 7.854 | 6.150 | 1.488 | 216 | 3 |
| `south_gate_face_tower` | 15.322 | 11.646 | 3.028 | 648 | 3 |

Sloturi ca în pilot: `*_Stone` = `ROCK_LIGHT` 3 (clasa `angkor_sandstone`),
`*_Lichen` = `LAVA_ORANGE` 30 + `CACTUS_GREEN` 12, `*_Streak` = `VOLCANIC_BLACK` 20.
Lichen portocaliu: b 0,72%, c 0,53%, poartă 0,50% (limita 3%). Scala 1 / rotație
identitate pe rădăcini (verificat). Fără alb, fără `ROCK_DARK`, fără texturi proprii.
Poarta: primitive rotunde doar bobocul (14) și finialul (8).

## Imagini (`docs/asset_briefs/img/angkor_fidelity/`)

`bayon_face_tower_b.png`, `bayon_face_tower_c.png` (decupare | randare),
`bayon_face_tower_c_views.png` (4 azimuturi), `south_gate_face_tower.png`,
`…_views.png`, `…_gamecam.png`, `…_face.png` (close-up pe o față, din față și 3/4).

## Fidelitate

| element | pe desen | în GLB | verdict |
|---|---|---|---|
| **b** etaje | 3 etaje late, boboc mare | 3 etaje (0,50/0,46/0,42 m), boboc r 0,43 cu 10 petale | OK; diferența față de `a` (4 etaje, 8 petale) se citește în siluetă |
| **c** colț de sus | colț prăbușit | colțul (+X,+Y) al etajelor 3–4 coborât și tras spre axă, fără finialuri | **slab**: citește ca etaje „strâmbe”, nu ca zid căzut; bobocul rămâne întreg |
| **c** nișă | spartă în bază | fereastră 0,65 × 0,40 m, adâncă 0,32 m, pe fața +Y, blocuri lipsă | OK, se vede ca gaură întunecată |
| **c** moloz | blocuri lipite de bază | 11 blocuri 0,4–0,7 m în triunghiul rămas la colțul (−X,+Y) al bazei (treptele 0 și 1 tăiate pe diagonală); toate în ±1,49 | OK pe geometrie (garda); pe imagine sunt mici față de desen |
| poartă siluetă | piramidă joasă, turn central | aripi în trepte (10,0 / 7,4 / 5,0 m), turn central de 12 m | mai înalt și mai subțire decât desenul (cote obligate de contract: gol 8 m, vârf 20–23 m) |
| poartă gol | arc în trepte | gol dreptunghiular de 7,5 × 8,4 m; arcul în trepte e **relief** în afara golului (pilaștri și grinzi în două trepte) | **abatere voită**: un arc în console ar fi intrat în banda ±3,6 m |
| fețe | patru, zâmbitoare | patru, H = 4,6 m, stilul rundei 6 | simplificate (datorie deschisă) |
| elefanți | cu fildeși, trompa jos | 4 siluete blocate de ~3,6 m, trompa până la sol, ureche, fildeș, coadă; pe +Y și −Y, câte unul pe aripă, fața spre exterior | citesc ca „elefant” abia de aproape; în gamecam sunt blocuri |
| lichen | verde-gălbui bogat | 70 + 26 pete, 0,5% | **abatere voită** (contract) |

## Runde

- **Bayon b**: o rundă (parametri); aprobat de mine ca „diferit de a”.
- **Bayon c**: **3 runde.** (1) colț de sus și bază în colțul (+X,−Y): pe randare totul
  era în spatele turnului. (2) mutat: baza în (−X,+Y), nișa pe fața +Y; colțul de sus
  încă prea fin. (3) tăieturi mai mari ale bazei, blocuri mai mari și mai multe, colț de
  sus tras cu 0,85·jumătate-lățime; rămâne slab (vezi tabel).
- **Poartă**: **2 runde.** (1) aripi drepte de 9,6 m: citea ca o masă cu un cap deasupra,
  elefanții de 3 m erau puncte. (2) aripi în trepte, cornișe pe fiecare treaptă, elefanți
  de 3,6 m, fața treptei cu blocuri; silueta e acum mai aproape de piramida desenului.
  O trecere a ieșit cu lățimea 19,10 (un bloc de parapet): corectat, acum 19,000.

## Camera de joc (`--gamecam`) — citire onestă

Camera la 10 m sus, 12,5 m în spate, punctul la 30 m în fața porții, fov 68, fără
îngropare. **Turnul central e tăiat de marginea de sus a cadrului**: la 30 m, cu
camera de joc, fața de 4,6 m a turnului nu încape. Se văd aripile în trepte, golul și, doar jos, bărbia
primei fețe. Fețele se citesc de la ~60–80 m, nu de aproape; elefanții de la 30 m sunt
două pete cu forma unui bloc cu picioare. Verdictul îl dă criticul orb pe capturile
din joc (poarta e în pâlnia de 7 m a pistei).

## Abateri și riscuri

1. Fețele simplificate (datorie deschisă); elefanții în relief la fel, siluete blocate.
2. Arcul în trepte e relief, nu consolă (golul rămâne dreptunghi liber).
3. `c`: prăbușirea de sus slabă. Se poate înlocui cu blocuri separate cazute pe etaj.
4. Coliziune `mesh` pe poartă: soclul (0,4 m) se întinde pe ±4,0 m în Z, deci mașina
   care trece pe lângă aripă îl atinge cu 0,5 m înaintea peretelui; pe gol nu e nimic.
5. Fără Godot în acest worktree: `.import` neprodus; clasele `Gate_Stone` →
   `angkor_sandstone` și `CameraZone.ceiling` = 8,4 m sunt ale coordonatorului.
