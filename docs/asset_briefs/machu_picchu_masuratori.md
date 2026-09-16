# Măsurători kit Machu Picchu (`Track15`) — inventarul tehnic

Toate cifrele de mai jos sunt **citite din GLB-urile importate**, nu din brief.
Motivul e scris în `machu_picchu_inventory.md` însuși: brief-ul a greșit deja de
două ori la kitul ăsta (lățimea liberă a lui `main_gate`, axa trenului). Ce
urmează e sursa de adevăr pentru maparea din `scenes/props/world_prop.gd`
(`PROP_COLLISION`, `SPLIT_MODELS`, `CLASSES_BY_MODEL`) și pentru plantarea pe POI.

## Comenzile care au produs tabelele

```powershell
$E = "D:\GameDev\Godot_v4.7-stable_win64_console.exe"

# 0. import invechit = masuratoare falsa (memoria import-invechit-falsifica-masuratoarea)
& $E --headless --path D:/GameDev/wt-mp-fundatie --import

# 1. inventarul per nod: nume, triunghiuri, AABB, raza la baza, histograma de sloturi
& $E --headless --path D:/GameDev/wt-mp-fundatie `
     --script res://tools/probe_machupicchu_kit.gd

# 2. golul LIBER pe axa drumului, pe piesele prin care se conduce
& $E --headless --path D:/GameDev/wt-mp-fundatie `
     --script res://tools/probe_mp_gaps.gd
```

Godot v4.7.stable.official.5b4e0cb0f. Ramura `feat/mp-fundatie`.
`probe_machupicchu_kit.gd` a raportat **39 de fișiere .glb**, adică tot kitul.

## 1. Inventar per piesă

`h` = înălțimea AABB (m). `bază x/z` = amprenta AABB (m). `rază bază` = raza
maximă în XZ a vertecșilor din prima 15% din înălțime — cifra pe care se
decide `trunk`. `sloturi` = sloturile de atlas atinse de UV-uri, per nod.

| piesă | noduri REALE de mesh | tri | h (m) | bază x × z (m) | rază bază (m) | sloturi (per nod) | coliziune |
|---|---|---:|---:|---|---:|---|---|
| `animals/condor` | `Condor` | 986 | 1.156 | 1.36 × 0.92 | 0.73 | 0,3,4,7,20,22 | `none` |
| `animals/llama` | `LlamaMesh` (+ `Llama` Node3D, `Skeleton3D` 46 oase, `AnimationPlayer`) | 400 | 0.529 | 0.13 × 0.44 | 0.30 | 4,22 | `none` |
| `animals/llama_b` | `LlamaMesh` (idem) | 400 | 0.529 | 0.13 × 0.44 | 0.30 | 1,4 | `none` |
| `animals/llama_c` | `LlamaMesh` (idem) | 400 | 0.529 | 0.13 × 0.44 | 0.30 | 4,28 | `none` |
| `buildings/guardhouse` | `House_Stone_001`, `House_Thatch_001` | 504 | 7.878 | 7.89 × 5.20 | 4.01 | Stone 3,9,29 · Thatch 4,13 | `hull` |
| `buildings/inca_house_a` | `House_Stone`, `House_Thatch` | 548 | 4.825 | 6.85 × 4.90 | 3.58 | Stone 3,4,29 · Thatch 4,13 | `hull` |
| `buildings/inca_house_b` | `House_Ruin` | 496 | 2.833 | 6.00 × 4.21 | 3.64 | 3,12,29 | `hull` |
| `plants/bamboo_clump` | `Bamboo_Clump` | 958 | 5.010 | 2.47 × 1.79 | 0.50 | 12,13,21 | `trunk` |
| `plants/bromeliad` | `Bromeliad` | 248 | 0.377 | 0.91 × 0.90 | 0.46 | 12,21 | `none` |
| `plants/orchid_cluster` | `Orchid_Cluster` | 410 | 0.390 | 0.34 × 0.34 | 0.17 | 21,31 | `none` |
| `plants/polylepis_a` | `Polylepis_A` | 598 | 4.190 | 2.55 × 3.01 | 0.61 | 4,12,21,27 | `trunk` |
| `plants/polylepis_b` | `Polylepis_B` | 1098 | 6.798 | 4.71 × 4.37 | 1.10 | 4,12,21,27 | `trunk` |
| `plants/tree_fern` | `Tree_Fern` | 768 | 3.306 | 4.13 × 4.12 | 0.30 | 4,12,21,28 | `trunk` ⚠ |
| `props/backpack_pile` | `Backpack_Pile` | 288 | 0.694 | 1.15 × 0.74 | 0.60 | 10,11,12,28 | `none` |
| `props/tent_a` | `Tent_A` | 256 | 1.407 | 2.09 × 2.27 | 1.46 | 13,23,28 | `hull` |
| `props/tent_b` | `Tent_B` | 256 | 1.407 | 2.09 × 2.27 | 1.46 | 12,13,28 | `hull` |
| `rocks/gorge_far_wall` | `Gorge_Far_Wall` | 1706 | 75.393 | 196.00 × 92.06 | 97.42 | 2,3,12,21,28,29 | `none` |
| `rocks/huayna_picchu` | `Huayna_Picchu` | 503 | 33.000 | 79.47 × 73.47 | 40.80 | 2,3,12,21,28,29 | `none` |
| `rocks/machu_picchu_mountain` | `Machu_Picchu_Mountain` | 1126 | 60.500 | 146.71 × 134.74 | 75.19 | 2,3,12,21,28,29 | `none` |
| `rocks/moss_boulder_a` | `Moss_Boulder_A` | 200 | 0.741 | 0.85 × 0.74 | 0.37 | 3,12,29 | `hull` |
| `rocks/moss_boulder_b` | `Moss_Boulder_B` | 242 | 1.957 | 2.48 × 2.35 | 0.94 | 3,12,29 | `hull` |
| `rocks/moss_boulder_c` | `Moss_Boulder_C` | 238 | 3.069 | 4.21 × 3.38 | 1.73 | 3,12,29 | `hull` |
| `structures/fountain_basin` | `Basin`, `Water` | 266 | 0.600 | 1.88 × 1.00 | 1.06 | Basin 3,4,29 · Water 17 | `hull` |
| `structures/inca_bridge_ledge` | `Inca_Bridge_Ledge` | 914 | 12.900 | 5.15 × 30.00 | 15.28 | 3,4,12,29 | `mesh` |
| `structures/inca_stair_a` | `Inca_Stair_A` | 422 | 2.500 | 2.60 × 3.00 | 3.16 | 3,12,29 | `hull` |
| `structures/inca_stair_b` | `Inca_Stair_B` | 798 | 5.000 | 2.60 × 6.00 | 6.08 | 3,12,29 | `hull` |
| `structures/inca_wall_a` | `Inca_Wall_A` | 208 | 2.487 | 4.00 × 0.83 | 2.03 | 3,12,29 | `hull` |
| `structures/inca_wall_b` | `Inca_Wall_B` | 296 | 2.487 | 6.00 × 0.86 | 3.02 | 3,4,12,29 | `hull` |
| `structures/inca_wall_c` | `Inca_Wall_C` | 152 | 2.432 | 2.00 × 0.85 | 1.06 | 3,12,29 | `hull` |
| `structures/inti_punku` | `Inti_Punku` | 1092 | 5.000 | 25.19 × 5.00 | 12.16 | 3,4,29 | `mesh` |
| `structures/intihuatana` | `Intihuatana` | 492 | 2.720 | 5.95 × 5.87 | 3.50 | 3,29 | `hull` |
| `structures/main_gate` | `Main_Gate` | 588 | 7.500 | 16.80 × 2.70 | 8.45 | 3,4,29 | `mesh` |
| `structures/rope_rail` | `Rope_Rail` | 92 | 1.045 | 4.14 × 0.15 | 2.07 | 9,13 | `none` |
| `structures/sun_temple` | `Sun_Temple` | 1108 | 5.586 | 8.79 × 7.59 | 4.23 | 3,4,12,29 | `hull` |
| `structures/three_windows` | `Three_Windows` | 540 | 4.000 | 10.00 × 1.15 | 5.03 | 3,4,29 | `hull` |
| `structures/trail_marker` | `Trail_Marker` | 76 | 1.200 | 0.52 × 0.31 | 0.29 | 3,29 | `none` |
| `structures/water_channel` | `Water_Channel` | 36 | 0.300 | 4.00 × 0.40 | 2.01 | 3,4,12,29 | `none` |
| `vehicles/consettur_bus` | `Consettur_Bus` | 968 | 3.095 | 3.66 × 6.16 | 3.52 | 0,5,16,20,22 | (hazard) |
| `vehicles/perurail_train` | `Train_Loco`, `Train_Tender`, `Train_Wagon` | 3934 | 3.615 | 8.90 × 2.86 | 4.11 | fiecare 5,15,16,20 (+ Loco și 0) | (hazard) |

**Total kit: 24.611 triunghiuri pe 39 de fișiere, 44 de noduri de mesh.**

### Numele de noduri care contrazic așteptarea

Trei capcane pentru cine scrie mapări pe nume:

- **`guardhouse` are sufix `_001`**: nodurile sunt `House_Stone_001` /
  `House_Thatch_001`, nu `House_Stone` / `House_Thatch` ca la `inca_house_a`.
  O mapare scrisă pe `House_Stone` prinde casa și **ratează** paznicul.
- **`inca_house_b` nu are `House_Stone` deloc** — un singur nod, `House_Ruin`.
- **`llama*.glb` au nodul de mesh `LlamaMesh`**, sub un `Node3D` numit `Llama`,
  sub un `Skeleton3D`. Numele de fișier diferă (`llama`/`_b`/`_c`) dar **numele
  nodului e identic în toate trei** — memoria `nume-noduri-nu-sunt-unice` se
  aplică direct: orice mapare pe `LlamaMesh` lovește toate trei variantele.

Cele trei lame diferă doar prin slot: `llama` pe 4+22 (FOAM_WHITE),
`llama_b` pe 1+4 (SAND_MID), `llama_c` pe 4+28 (LOG_DARK). Slotul 4 (ROCK_DARK,
copitele/botul) e comun, 48% din vertecși la toate trei.

## 2. Sloturi — ce cere `ACCENT_SPLIT` și ce NU suportă clasă triplanară

**Toate cele 44 de noduri de mesh au UV COLAPSAT** (numărul de valori `u`
distincte e egal cu numărul de sloturi atinse, la fiecare nod). Deci contractul
atlasului e respectat peste tot: nicio piesă nu mătură lățimea atlasului, nicio
piesă nu culege rezerva magenta. Verificarea e pe valori **distincte**, nu pe
`u_max − u_min` (memoria `uv-colapsat-nu-e-un-interval`).

Consecința pentru texturile de clasă (memoria `clase-pe-piese-de-kit`): **43 din
44 de noduri au mai multe sloturi pe același mesh**, deci o clasă triplanară
pusă pe nod le-ar șterge pe toate. Singurul nod mono-slot din tot kitul e
`Water` din `fountain_basin` (slot 17, REEF_SHALLOW, 100%).

Ce înseamnă concret: dacă vrei rosturi de piatră pe zidărie (`inca_stone`), nu
poți pune clasa pe nodul întreg — trebuie **ACCENT_SPLIT**. Candidații, ordonați
după cât de curat se separă accentul pe intervalul de `y` (memoria
`ruptura-accente-doua-sloturi`: se măsoară intervalul de y, nu procentul):

| nod | corp (slot, %) | accent (slot, %) | y corp | y accent | se separă? |
|---|---|---|---|---|---|
| `Inca_Wall_A` | 3+29, 93.7% | 12 CACTUS_GREEN, 6.3% | 0.00–2.49 | **2.31–2.49** | **DA** — iarba stă doar pe coronament |
| `Inca_Wall_C` | 3+29, 91.5% | 12, 8.5% | 0.00–2.43 | **2.33–2.43** | **DA** |
| `Inca_Wall_B` | 3+29, 62.4% | 12, 6.3% | 0.00–2.49 | **2.30–2.49** | **DA** (dar mai are 4 ROCK_DARK 31.4% la 0.67–1.63, nișele) |
| `House_Ruin` | 3+29, 77.2% | 12, 22.8% | 0.00–2.83 | 0.85–2.83 | **NU** — mușchiul urcă din 0.85, se suprapune cu zidul |
| `Moss_Boulder_A/B/C` | 3+29 | 12, 12–39% | — | A 0.38–0.74 · B 0.92–1.96 · C 0.97–3.07 | **DA pe A** (mușchi doar pe capac); B/C se suprapun parțial |
| `Sun_Temple` | 3, 68.5% | 29 MARBLE_GREY, 25.5% | 0.00–5.59 | **2.15–5.59** | **DA** — coronamentul e clar peste bază |
| `House_Stone` / `_001` | 3+29 | 9 WOOD (doar guardhouse) 16.4% | — | **0.00–2.50** | parțial — lemnul e în jumătatea de jos |
| `Huayna_Picchu` | 3 ROCK_LIGHT 37.2% | 12 CACTUS_GREEN **42.5%** | 3.40–33.00 | **0.00–11.40** | **DA** — vegetația e pe fustă, stânca de la 3.40 în sus |
| `Machu_Picchu_Mountain` | 3, 14.3% | 21 TROPICAL_GREEN **45.7%** | 16.34–60.32 | 8.64–39.45 | parțial — se suprapun pe 16–39 m |
| `Gorge_Far_Wall` | 3, 29.6% | 21+12, 23.0% | 0.00–75.39 | 6.84–46.38 | **NU** — banda verde e în mijlocul peretelui |

**Piesele care NU cer ACCENT_SPLIT** (accentul e deja mic și localizat, sau
piesa e decor de orizont care nu primește clasă): `Intihuatana` (doar 2 sloturi,
3+29, ambele piatră — o clasă de piatră pe tot nodul e corectă),
`Trail_Marker` (idem, 3+29), `Inti_Punku`, `Main_Gate`, `Three_Windows`
(3+4+29, toate trei sunt piatră — accentul 4 ROCK_DARK e umbra buiandrugului,
4.3–4.4%, la `Main_Gate` fix în banda **5.94–6.06 m**, adică grosimea
buiandrugului).

**Atenție la slotul 12 (CACTUS_GREEN) pe zidărie**: apare pe *nouă* piese de
piatră (`inca_wall_a/b/c`, `inca_stair_a/b`, `water_channel`, `sun_temple`,
`inca_bridge_ledge`, `house_ruin`) ca iarbă de coronament, între 2.4% și 22.8%.
E **același slot** cu frunzișul de la `bromeliad`/`tent_b`/`moss_boulder`. O
mapare de clasă pe slotul 12 e globală pe pistă — exact capcana `House_` din
`world_prop.gd`.

## 3. Golul liber pe piesele prin care se CONDUCE

Măsurat cu `probe_mp_gaps.gd`, grilă de 1 cm, prin proiecția triunghiurilor pe
planul (lateral, y). AABB-ul unei porți dă **anvergura**, nu deschiderea.

| piesă | anvergură AABB | fereastra y | **gol liber măsurat** | brief | verdict |
|---|---:|---|---:|---:|---|
| `main_gate` | 16.80 m | 0.15–0.60 (la bază) | **7.39 m** | 8.39 m | **NU se confirmă** |
| `main_gate` | 16.80 m | 0.15–5.80 (sub buiandrug) | **7.39 m** | 6.00 m | mai larg decât se cere |
| `inti_punku` | 25.19 m | 0.15–4.80 | **13.98 m** | 14.000 m | **confirmat** |
| `inca_bridge_ledge` | 30.00 m | 8.00–11.00 (cota cornișei) | **4.23 m** | 4.25 m | **confirmat** |
| `inca_bridge_ledge` | 30.00 m | 0.15–12.80 (toată înălțimea) | 3.75 m | — | se strânge mai jos |

### `main_gate`: 7.39 m liber, nu 8.39 — cifra din inventar e alta cotă

`machu_picchu_inventory.md` scrie „**8,390 bază** / 7,410 sus / 6,000 liber sub
buiandrug (măsurat)". Pe geometrie, deschiderea reală între ușciori e **7.39 m,
constantă de la sol până sub buiandrug** — nu se strânge de la 8.39 la 6.00 pe
verticală, cum sugerează cele trei cifre. Buiandrugul e la **5.94–6.06 m** (slot
4, 4.3% din vertecși), deci gabaritul pe înălțime e 5.94 m, apropiat de cei
6.00 declarați.

Ce înseamnă: cifra de 7.41 m din inventar („7,410 sus") e de fapt deschiderea,
iar 8.390 e altceva — probabil distanța între fețele exterioare ale ușciorilor
minus grosimea, sau o cotă pre-bevel. **Nu am comis nicio corecție în
`machu_picchu_inventory.md`** — cine o face trebuie să spună care dintre cele
trei cifre e greșită, nu doar să suprascrie.

Consecința de gameplay e că poarta e **mai strâmtă decât se credea**: brief-ul
pistei cere „8 m liber la bază" pe un drum de 13 m. 7.39 m e sub cei 8, deși
inventarul raportează marjă pozitivă. Cu mașinile AI care intră în pluton acolo,
asta se verifică cu `ProbeLaneClear` și `ProbeRace` după plantare, nu din tabel.

## 4. Coliziunea propusă, cu motivul măsurat

Tiparul e cel din `world_prop.gd:61` (`PROP_COLLISION`). Fiecare linie de mai
jos are cifra care o susține, nu lista de plecare.

### `mesh` — se conduce PRIN ele

- **`main_gate`** (7.39 m gol, buiandrug la 5.94 m) și **`inti_punku`**
  (13.98 m gol). Un `hull` convex peste o poartă e un **bloc plin**: la
  `main_gate` ar fi un zid de 16.80 × 7.50 m fix peste drum, la `inti_punku`
  25.19 × 5.00 m. Golul măsurat e chiar contractul de gameplay.
- **`inca_bridge_ledge`** (gol 4.23 m la cota cornișei, 3.75 m mai jos). Piesa e
  o cornișă cu **gol vertical pe 12.90 m înălțime**: hull-ul ar astupa exact
  prăpastia peste care sare `LiftBridgeHazard`. Același motiv ca `crater_bowl`
  la Stromboli — cine cade trebuie să CADĂ.

### `trunk` — bază îngustă, coroană lată

Criteriul măsurat e raportul **rază la bază / semi-lățime AABB**. Sub 0.5 =
coroana depășește masiv trunchiul, deci hull-ul te oprește în aer. Patru piese
trec pragul; toate celelalte 35 sunt ≥ 0.76.

| piesă | rază bază | semi-lățime | raport |
|---|---:|---:|---:|
| `tree_fern` | 0.30 | 2.07 | **0.15** |
| `bamboo_clump` | 0.50 | 1.24 | **0.40** |
| `polylepis_a` | 0.61 | 1.51 | **0.41** |
| `polylepis_b` | 1.10 | 2.36 | **0.47** |

⚠ **`tree_fern` cere `TRUNK_FRACTION` corectat pe instanță.** `world_prop.gd:2535`
calculează raza cilindrului ca `max(aabb.size.x * 0.13, 0.22)`. Pentru feriga
arborescentă asta dă **0.54 m**, față de raza reală a stipei de **0.30 m** —
cilindrul automat e de **1.8×** prea gros, adică un stâlp invizibil cu 24 cm mai
lat de fiecare parte decât trunchiul care se vede. Celelalte trei ies sub raza
măsurată (0.32 / 0.33 / 0.61 față de 0.50 / 0.61 / 1.10), deci sunt sigure.
Verificat: `max(4.13*0.13, 0.22) = 0.537`.

### `none` — fantome

- **Decor de orizont**, exact ca `lengai` / `crater_far_wall` la Serengeti:
  `gorge_far_wall` (**196.00 × 75.39 × 92.06 m**), `machu_picchu_mountain`
  (**146.71 × 60.50 × 134.74 m**), `huayna_picchu` (**79.47 × 33.00 × 73.47 m**).
  Un hull pe oricare din ele e un corp fizic cât o pistă întreagă.
- **Accente mici fără masă**: `bromeliad` (0.38 m înălțime), `orchid_cluster`
  (0.39 m), `backpack_pile` (0.69 m), `trail_marker` (1.20 m, rază bază 0.29 m),
  `condor` (1.16 m, aripi ca insule de mesh separate — fără AnimationPlayer în
  fișier, static, confirmat). Toate sub înălțimea capotei.
- **`water_channel`** (0.30 m înălțime, 4.00 m lungime) — jgheab care ZACE pe
  sol, ca `rail_track` la Baikal. Un hull ar fi un **prag de 30 cm** pe linia
  de curs; pragurile peste 0.3 m sunt ziduri pentru fizica întreagă, iar ăsta e
  chiar la limită. Se pun zeci de bucăți cap la cap.
- **`rope_rail`** (1.045 m înălțime, **0.15 m grosime**, 4.14 m lungime,
  92 tri). E un parapet de frânghie: hull-ul lui e o placă de 4 m lungime pe
  marginea drumului, exact unde mașina atinge la depășire. Nu e obstacol, e
  semnal vizual de margine.
- **`llama*`** — figuranți; și oricum se montează pe `SlidingHazard`, care își
  face colizorul lui.

### `hull` implicit — restul (21 de piese)

`guardhouse`, `inca_house_a/b`, `tent_a/b`, `moss_boulder_a/b/c`,
`fountain_basin`, `inca_stair_a/b`, `inca_wall_a/b/c`, `intihuatana`,
`sun_temple`, `three_windows`. Toate au raport rază/semi-lățime ≥ 0.76, adică
baza e la fel de lată ca silueta — hull-ul convex e o aproximare onestă.

Două note:

- **`inca_stair_a/b` au raport > 2.0** (3.16/1.50 și 6.08/3.00), fiindcă „raza
  la bază" pe o scară măsoară diagonala treptei de jos, nu un trunchi. Sunt
  rampe pe care se URCĂ; `hull`-ul unei scări e o **pană**, nu un capac plan,
  deci e corect. Dacă o captură arată că mașina se urcă pe capac în loc să
  atingă treptele, atunci se trece pe `mesh` (tiparul `kopje_kicker`).
- **`fountain_basin` are nodul `Water` la y = 0.50, un quad plan de 2 triunghiuri.**
  `hull`-ul lui e degenerat (grosime zero). Nu deranjează — bazinul are 0.60 m —
  dar dacă `world_prop` scoate un avertisment de shape degenerat, ăsta e
  vinovatul.

### Vehiculele nu trec prin `PROP_COLLISION`

`consettur_bus` și `perurail_train` sunt consumate de hazarde
(`bus_hazard.gd`, `train_hazard.gd`), care își fac colizoarele lor. Confirmat pe
geometrie:

- **`Consettur_Bus`** — un singur nod, AABB **3.66 × 3.09 × 6.16 m**, origine la
  sol, centrat pe XZ (`pos.x = −1.83 = −3.66/2`, `pos.z = −3.08 = −6.16/2`).
  Lungimea e pe **Z**, deci „înainte = −Z" din inventar e consistent cu forma.
- **`perurail_train`** — trei noduri cu numele exacte cerute de
  `train_hazard.gd`: `Train_Loco` (1390 tri, 8.90 m pe X), `Train_Tender`
  (1228 tri, 5.00 m pe X), `Train_Wagon` (1316 tri, 8.00 m pe X). **Lungimea e
  pe X la toate trei**, deci botul pe +X se confirmă din geometrie, nu doar din
  cod. Baza roților la **y = 0.000** pe toate trei. Total 3934 tri.

## 5. Costul de materiale — avertisment pentru plantare

`probe_decor --track=15` pe `main` dă **20 de materiale**, toate din
`procedural (track.gd)`, cu plafonul cerut de dezvoltator la **≤ 20**. Kitul are
**39 de GLB-uri**, iar un GLB pe atlas costă **1 material**.

Asta înseamnă că plantarea kitului nu poate fi „mai punem un prop": **fiecare
fișier .glb distinct instanțiat pe Track15 adaugă un material peste cele 20 de
azi.** Cifra de verificat după fiecare val de plantare e:

```powershell
& $E --headless --path D:/GameDev/wt-mp-fundatie `
     --script res://tools/probe_decor.gd -- --track=15
```

**`--track=15` e NUMĂRUL DE SCENĂ**, nu poziția în `TRACK_SCENES`. `--track=8`
măsoară Okinawa și dă verde fals. (Toate celelalte sonde — `ProbeLayout`,
`ProbeBuried`, `ProbeLaneClear` — iau `--track=8`, poziția.)

Nu am plantat nimic, deci cifra de 20 e neschimbată; e linia de bază față de
care se citește primul val.

## 6. Ce NU spune măsurătoarea asta

- **Culoarea compusă.** Sloturile de mai sus sunt indici în atlas; cum arată
  mușchiul-retag, benzile de pe `gorge_far_wall` și rozul orhideei se judecă
  abia pe captură din mașină, în Godot, după remap (memoria
  `monocromia-se-masoara-dupa-remap`). Tabelul de sloturi spune **din ce** e
  făcută culoarea, nu **cum arată**.
- **Dacă propunerea de coliziune ține în cursă.** `hull`/`trunk`/`mesh` de mai
  sus sunt derivate din geometrie, dar verdictul e `ProbeLaneClear` +
  `ProbeRace` după plantare. `ProbeLaneClear` **nu are azi linie de bază pentru
  Track15** (`tools/probe_lane_clear.gd:180-189`), deci iese 0 orice ar găsi —
  garda nu e armată până nu se scrie în `BASELINE`.
- **Forma.** Niciuna din cifrele de aici nu vede dacă o piesă e un con neted sau
  o stâncă cu caracter (lecția `verify_glb.py` din inventar). Planșa și captura
  rămân singurele care o prind.
