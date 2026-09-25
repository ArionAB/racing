# Măsurători kit Fiordland (`Track16`) — inventarul tehnic

Toate cifrele de mai jos sunt **citite din GLB-urile importate**, nu din
brief. Sursa de adevăr pentru maparea din `scenes/props/world_prop.gd`
(`PROP_COLLISION`, `SPLIT_MODELS`, `CLASSES_BY_MODEL`) și `tools/probe_decor.gd`
(`KNOWN`/`VARIANT_SOURCE`), pe modelul `machu_picchu_masuratori.md`.

## Comenzile care au produs tabelul

```powershell
$E = "D:\GameDev\Godot_v4.7-stable_win64_console.exe"

# 0. import invechit = masuratoare falsa (memoria import-invechit-falsifica-masuratoarea)
& $E --headless --path D:/GameDev/wt-fiord-fundatie --import

# 1. inventarul per nod: nume, triunghiuri, AABB, raza la baza, histograma de sloturi
& $E --headless --path D:/GameDev/wt-fiord-fundatie `
     --script res://tools/probe_machupicchu_kit.gd -- --dir=fiordland
```

Godot v4.7.stable.official.5b4e0cb0f. Ramura `feat/fiord-fundatie`.
`probe_machupicchu_kit.gd --dir=fiordland` a raportat **31 de fișiere .glb**,
tot kitul (`bash tools/blender/verify_fiordland.sh` → VERDICT KIT: OK, 31).

## 1. Inventar per piesă

`h` = înălțimea AABB (m). `bază x/z` = amprenta AABB (m). `rază bază` = raza
maximă în XZ a vertecșilor din prima 15% din înălțime — cifra pe care se
decide `trunk` (prag folosit la Machu Picchu: raport rază-bază/semi-lățime
< 0,5 → `trunk`).

| piesă | noduri REALE de mesh | tri | h (m) | bază x × z (m) | rază bază (m) | sloturi (per nod) |
|---|---|---:|---:|---|---:|---|
| `animals/kea` | `KeaMesh` (+ `Kea` Node3D, `Skeleton3D` 4 oase `Body/Head/WingL/WingR`, `AnimationPlayer` `Idle`/`Open`) | 682 | 0.490 | 1.00 × 0.23 | 0.10 | 12,20,30 |
| `animals/penguin_tawaki` | `Penguin` | 282 | 0.770 | 0.41 × 0.27 | 0.10 | 7,16,20,22 |
| `buildings/cafe_shed` | `House_Roof`, `House_Wall` | 308 | 3.656 | 5.80 × 4.57 | 3.33 | Roof 11,20 · Wall 9,20 |
| `buildings/lodge` | `House_Wall_001`, `House_Roof_001` | 636 | 6.185 | 17.07 × 8.10 | 8.72 | Wall 9,20 · Roof 11,20 |
| `effects/tree_avalanche` | `Boulder_A`, `Boulder_B`, `Boulder_C`, `Boulder_D` | 794 (136/224/174/260) | 2.149 (grup) | 2.62 × 1.85 (grup) | 0.39–0.93 per bucată | fiecare 21,28,29 |
| `plants/beech_a` | `Trunk`, `Crown` | 228 | 7.030 | 5.10 × 5.00 | 0.81 | Trunk 28 · Crown 21,28 |
| `plants/beech_b` | `Trunk_001`, `Crown_001` | 292 | 10.189 | 6.10 × 6.36 | 0.77 | Trunk 28 · Crown 21,28 |
| `plants/beech_c` | `Trunk_002`, `Crown_002` | 292 | 13.501 | 9.38 × 9.55 | 1.03 | Trunk 28 · Crown 21,28 |
| `plants/beech_dead` | `Beech_Dead` | 136 | 8.515 | 2.93 × 3.27 | 0.68 | 12,28 |
| `plants/rata_tree` | `Rata` | 354 | 3.667 | 4.29 × 4.19 | 2.00 | 7,21,28 |
| `plants/tussock_clump` | `Tussock_Clump` | 144 | 0.804 | 0.68 × 0.69 | 0.05 | 2,12 |
| `props/driftwood` | `Driftwood` | 52 | 0.384 | 4.03 × 0.58 | 2.00 | 9 |
| `props/kayak_a` | `KayakA` | 94 | 0.361 | 0.58 × 3.60 | 1.80 | 15,20 |
| `props/kayak_b` | `KayakB` | 94 | 0.361 | 0.58 × 3.60 | 1.80 | 16,20 |
| `props/luggage_container` | `Container` | 88 | 2.600 | 2.40 × 6.10 | 3.27 | 8,11,20 |
| `props/road_sign_blank` | `RoadSign` | 36 | 2.450 | 1.60 × 0.08 | 0.55 | 8,21 |
| `props/snow_pole` | `SnowPole` | 40 | 2.000 | 0.05 × 0.06 | 0.03 | 7,22 |
| `props/stump` | `Stump` | 68 | 0.828 | 1.13 × 1.00 | 0.69 | 12,28 |
| `props/traffic_light_pole` | `TrafficPole` | 220 | 5.500 | 0.50 × 2.61 | 1.30 | 8,11,20 (2 alveole VOLCANIC_BLACK goale, fără lămpi — contract) |
| `rocks/chasm_rock` | `Rock_001` | 416 | 2.500 | 6.00 × 4.72 | 3.02 | 20,21,29 |
| `rocks/fiordland_horizon` | `SnowRidge_A`, `FarWall_A`, `SnowRidge_B`, `FarWall_B` | 1658 | 90.000 (grup) | 180.00 × ~123 (grup) | 64.9–92.9 per nod | fiecare 2,21,22,28(,29) |
| `rocks/guard_rock` | `Rock_002` | 72 | 0.585 | 1.18 × 0.70 | 0.03 | 21,29 |
| `rocks/scree_slab` | `Rock_003` | 264 | 1.196 | 5.00 × 8.00 | 4.70 | 2,29 |
| `rocks/stirling_ledge` | `Shelf`, `Wall`, `Overhang` | 1826 | 26.568 | 21.55 × 39.60 (grup) | 21.42 | fiecare 20,21,29 |
| `rocks/torrent_chute` | `Rock` | 196 | 16.025 | 11.00 × 24.00 | 14.38 | 20,21,29 |
| `structures/chasm_bridge_rail` | `Rail_L`, `Rail_R` | 336 | 1.400 | 12.24 × 40.48 (grup) | 20.92 | fiecare 9 |
| `structures/heli_pad` | `HeliPad` | 178 | 0.300 | 11.70 × 12.00 | 6.00 | 8,22 |
| `structures/wharf` | `Wharf` | 376 | 2.640 | 4.56 × 20.10 | 10.19 | 20,21,29 |
| `vehicles/bush_plane` | `Plane` | 844 | 1.850 | 8.00 × 7.45 | 3.73 | 11,14,20,22 |
| `vehicles/coach_fiordland` | `Coach` | 1008 | 3.293 | 3.06 × 8.66 | 4.55 | 20,21,22 |
| `vehicles/cruise_boat` | `Boat` | 920 | 5.500 | 4.23 × 13.97 | 4.39 | 9,20,22 |

**Total kit: ~10.586 triunghiuri pe 31 de fișiere.**

Toate UV-urile sunt COLAPSATE (2-5 valori u distincte per nod, pe centrele
sloturilor din atlas) — nicio piesă nu mătură lățimea atlasului.

## 2. Rapoarte rază-bază / semi-lățime (decizia `trunk` vs `hull`)

Semi-lățime = jumătate din maximul(bază x, bază z).

| piesă | rază bază | semi-lățime | raport | decizie |
|---|---:|---:|---:|---|
| `beech_a` | 0.81 | 2.55 | 0.318 | `trunk` |
| `beech_b` | 0.77 | 3.18 | 0.242 | `trunk` |
| `beech_c` | 1.03 | 4.78 | 0.216 | `trunk` |
| `beech_dead` | 0.68 | 1.64 | 0.415 | `trunk` (are un singur nod, nu Trunk/Crown — coliziune pe tot corpul e acceptabilă, silueta e relativ subțire) |
| `rata_tree` | 2.00 | 2.15 | 0.930 | `hull` (tufă densă, nu copac cu coroană dezlipită de trunchi — brief-ul o descrie explicit "nu acacie") |
| `penguin_tawaki` | 0.10 | 0.21 | 0.476 | `none` (contract, brief §1.7) |
| `heli_pad` | 6.00 | 6.00 | 1.0 | `none` (contract — disc jos, se calcă peste) |
| `torrent_chute` | 14.38 | 12.00 | 1.20 | `none` (contract — deasupra benzii) |
| `chasm_bridge_rail` | 20.92 | 20.24 | 1.03 | `none` (contract — balustradă subțire pe margine, `waterline`-like) |
| `scree_slab` | 4.70 | 4.00 | 1.18 | `none` (placă joasă de grohotiș pe pantă, 1.2 m înălțime — hull ar fi o treaptă falsă; se calcă) |
| `snow_pole` | 0.03 | 0.03 | 1.0 | `none` (jalon subțire, decorativ, memoria `caseta-de-masura-exclude-defectul` nu se aplică — e literalmente un băț) |
| `kayak_a`/`kayak_b` | 1.80 | 1.80 | 1.0 | `none` (obiecte joase pe mal/apă, nu obstacole de coliziune pentru mașină) |
| `fiordland_horizon` (toate 4 noduri) | 64.9–92.9 | ~90 | ~0.7–1.0 | `none` (fundal, pânze de 90-180 m — un hull ar fi un corp fizic cât o pistă) |

Restul (implicit `hull`): `cafe_shed`, `lodge`, `chasm_rock`, `guard_rock`,
`stirling_ledge` (`mesh`, vezi mai jos), `wharf`, `bush_plane` (`none`,
`PathMover` zboară), `coach_fiordland`/`cruise_boat`/`traffic_light_pole`/
`luggage_container`/`driftwood`/`stump`/`road_sign_blank`/`tussock_clump`
(hull implicit).

## 3. `stirling_ledge`: verificare nișă vs. hull

Nodul `Shelf` (pragul uscat) e la y ∈ [0.38, 0.40], aabb pos (0, 0.38, -15.00)
size (3.00, 0.02, 30.00) — o placă subțire de 3 m lățime. `Wall` ocupă
x ∈ [-1.90, 11.58], iar `Overhang` iese la x ∈ [-9.97, 3.50], y ∈ [14.00, 21.40].
Nișa liberă sub surplomb (între `Wall` și fața interioară a `Overhang`,
pe verticala 0.40→14.00 m) e deschisă pe cei 3 m ai `Shelf`-ului — un hull
convex pe întreg nodul `stirling_ledge` ar închide geometric acest gol
(hull-ul unui obiect concav "umple" concavitatea). De aceea piesa e `mesh`
(coliziune pe geometria reală, nu pe hull), la fel ca `inca_bridge_ledge` la
Machu Picchu.

## 4. Diferențe față de `fiordland_inventory.md`

Nicio diferență semnificativă de cotă — toate cifrele măsurate aici coincid
cu cele deja raportate în inventar (stirling_ledge Wall 26.57 h, Overhang
Y∈[14.00,21.40]; torrent_chute buza 14.0–16.0; coach_fiordland 3.06×3.29×8.66;
tree_avalanche Boulder_A..D; fiordland_horizon FarWall/SnowRidge). Inventarul
e deja sursa corectă; măsurătoarea de mai sus o confirmă independent, din
fișier, așa cum cere pasul 1.

O singură notă nouă, utilă pentru pasul 2: `beech_dead` e UN SINGUR nod
(`Beech_Dead`), nu `Trunk`+`Crown` ca `beech_a/b/c` — nu poate primi coliziune
`trunk` pe un subnod separat; decizia de mai sus (`trunk` pe tot corpul, rată
0.415) e cea mai apropiată aproximare rezonabilă a unui trunchi uscat subțire.
