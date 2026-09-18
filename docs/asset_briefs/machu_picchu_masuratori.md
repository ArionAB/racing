# MÄƒsurÄƒtori kit Machu Picchu (`Track15`) â€” inventarul tehnic



Toate cifrele de mai jos sunt **citite din GLB-urile importate**, nu din brief.

Motivul e scris Ã®n `machu_picchu_inventory.md` Ã®nsuÈ™i: brief-ul a greÈ™it deja de

douÄƒ ori la kitul Äƒsta (lÄƒÈ›imea liberÄƒ a lui `main_gate`, axa trenului). Ce

urmeazÄƒ e sursa de adevÄƒr pentru maparea din `scenes/props/world_prop.gd`

(`PROP_COLLISION`, `SPLIT_MODELS`, `CLASSES_BY_MODEL`) È™i pentru plantarea pe POI.



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

`probe_machupicchu_kit.gd` a raportat **39 de fiÈ™iere .glb**, adicÄƒ tot kitul.



## 1. Inventar per piesÄƒ



`h` = Ã®nÄƒlÈ›imea AABB (m). `bazÄƒ x/z` = amprenta AABB (m). `razÄƒ bazÄƒ` = raza

maximÄƒ Ã®n XZ a vertecÈ™ilor din prima 15% din Ã®nÄƒlÈ›ime â€” cifra pe care se

decide `trunk`. `sloturi` = sloturile de atlas atinse de UV-uri, per nod.



| piesÄƒ | noduri REALE de mesh | tri | h (m) | bazÄƒ x Ã— z (m) | razÄƒ bazÄƒ (m) | sloturi (per nod) | coliziune |

|---|---|---:|---:|---|---:|---|---|

| `animals/condor` | `Condor` | 986 | 1.156 | 1.36 Ã— 0.92 | 0.73 | 0,3,4,7,20,22 | `none` |

| `animals/llama` | `LlamaMesh` (+ `Llama` Node3D, `Skeleton3D` 46 oase, `AnimationPlayer`) | 400 | 0.529 | 0.13 Ã— 0.44 | 0.30 | 4,22 | `none` |

| `animals/llama_b` | `LlamaMesh` (idem) | 400 | 0.529 | 0.13 Ã— 0.44 | 0.30 | 1,4 | `none` |

| `animals/llama_c` | `LlamaMesh` (idem) | 400 | 0.529 | 0.13 Ã— 0.44 | 0.30 | 4,28 | `none` |

| `buildings/guardhouse` | `House_Stone_001`, `House_Thatch_001` | 504 | 7.878 | 7.89 Ã— 5.20 | 4.01 | Stone 3,9,29 Â· Thatch 4,13 | `hull` |

| `buildings/inca_house_a` | `House_Stone`, `House_Thatch` | 548 | 4.825 | 6.85 Ã— 4.90 | 3.58 | Stone 3,4,29 Â· Thatch 4,13 | `hull` |

| `buildings/inca_house_b` | `House_Ruin` | 496 | 2.833 | 6.00 Ã— 4.21 | 3.64 | 3,12,29 | `hull` |

| `plants/bamboo_clump` | `Bamboo_Clump` | 958 | 5.010 | 2.47 Ã— 1.79 | 0.50 | 12,13,21 | `trunk` |

| `plants/bromeliad` | `Bromeliad` | 248 | 0.377 | 0.91 Ã— 0.90 | 0.46 | 12,21 | `none` |

| `plants/orchid_cluster` | `Orchid_Cluster` | 410 | 0.390 | 0.34 Ã— 0.34 | 0.17 | 21,31 | `none` |

| `plants/polylepis_a` | `Polylepis_A` | 598 | 4.190 | 2.55 Ã— 3.01 | 0.61 | 4,12,21,27 | `trunk` |

| `plants/polylepis_b` | `Polylepis_B` | 1098 | 6.798 | 4.71 Ã— 4.37 | 1.10 | 4,12,21,27 | `trunk` |

| `plants/tree_fern` | `Tree_Fern` | 768 | 3.306 | 4.13 Ã— 4.12 | 0.30 | 4,12,21,28 | `trunk` âš  |

| `props/backpack_pile` | `Backpack_Pile` | 288 | 0.694 | 1.15 Ã— 0.74 | 0.60 | 10,11,12,28 | `none` |

| `props/tent_a` | `Tent_A` | 256 | 1.407 | 2.09 Ã— 2.27 | 1.46 | 13,23,28 | `hull` |

| `props/tent_b` | `Tent_B` | 256 | 1.407 | 2.09 Ã— 2.27 | 1.46 | 12,13,28 | `hull` |

| `rocks/gorge_far_wall` | `Gorge_Far_Wall` | 1706 | 75.393 | 196.00 Ã— 92.06 | 97.42 | 2,3,12,21,28,29 | `none` |

| `rocks/huayna_picchu` | `Huayna_Picchu` | 503 | 33.000 | 79.47 Ã— 73.47 | 40.80 | 2,3,12,21,28,29 | `none` |

| `rocks/machu_picchu_mountain` | `Machu_Picchu_Mountain` | 1126 | 60.500 | 146.71 Ã— 134.74 | 75.19 | 2,3,12,21,28,29 | `none` |

| `rocks/moss_boulder_a` | `Moss_Boulder_A` | 200 | 0.741 | 0.85 Ã— 0.74 | 0.37 | 3,12,29 | `hull` |

| `rocks/moss_boulder_b` | `Moss_Boulder_B` | 242 | 1.957 | 2.48 Ã— 2.35 | 0.94 | 3,12,29 | `hull` |

| `rocks/moss_boulder_c` | `Moss_Boulder_C` | 238 | 3.069 | 4.21 Ã— 3.38 | 1.73 | 3,12,29 | `hull` |

| `structures/fountain_basin` | `Basin`, `Water` | 266 | 0.600 | 1.88 Ã— 1.00 | 1.06 | Basin 3,4,29 Â· Water 17 | `hull` |

| `structures/inca_bridge_ledge` | `Inca_Bridge_Ledge` | 914 | 12.900 | 5.15 Ã— 30.00 | 15.28 | 3,4,12,29 | `mesh` |

| `structures/inca_stair_a` | `Inca_Stair_A` | 422 | 2.500 | 2.60 Ã— 3.00 | 3.16 | 3,12,29 | `hull` |

| `structures/inca_stair_b` | `Inca_Stair_B` | 798 | 5.000 | 2.60 Ã— 6.00 | 6.08 | 3,12,29 | `hull` |

| `structures/inca_wall_a` | `Inca_Wall_A` | 208 | 2.487 | 4.00 Ã— 0.83 | 2.03 | 3,12,29 | `hull` |

| `structures/inca_wall_b` | `Inca_Wall_B` | 296 | 2.487 | 6.00 Ã— 0.86 | 3.02 | 3,4,12,29 | `hull` |

| `structures/inca_wall_c` | `Inca_Wall_C` | 152 | 2.432 | 2.00 Ã— 0.85 | 1.06 | 3,12,29 | `hull` |

| `structures/inti_punku` | `Inti_Punku` | 1092 | 5.000 | 25.19 Ã— 5.00 | 12.16 | 3,4,29 | `mesh` |

| `structures/intihuatana` | `Intihuatana` | 492 | 2.720 | 5.95 Ã— 5.87 | 3.50 | 3,29 | `hull` |

| `structures/main_gate` | `Main_Gate` | 588 | 7.500 | 16.80 Ã— 2.70 | 8.45 | 3,4,29 | `mesh` |

| `structures/rope_rail` | `Rope_Rail` | 92 | 1.045 | 4.14 Ã— 0.15 | 2.07 | 9,13 | `none` |

| `structures/sun_temple` | `Sun_Temple` | 1108 | 5.586 | 8.79 Ã— 7.59 | 4.23 | 3,4,12,29 | `hull` |

| `structures/three_windows` | `Three_Windows` | 540 | 4.000 | 10.00 Ã— 1.15 | 5.03 | 3,4,29 | `hull` |

| `structures/trail_marker` | `Trail_Marker` | 76 | 1.200 | 0.52 Ã— 0.31 | 0.29 | 3,29 | `none` |

| `structures/water_channel` | `Water_Channel` | 36 | 0.300 | 4.00 Ã— 0.40 | 2.01 | 3,4,12,29 | `none` |

| `vehicles/consettur_bus` | `Consettur_Bus` | 968 | 3.095 | 3.66 Ã— 6.16 | 3.52 | 0,5,16,20,22 | (hazard) |

| `vehicles/perurail_train` | `Train_Loco`, `Train_Tender`, `Train_Wagon` | 3934 | 3.615 | 8.90 Ã— 2.86 | 4.11 | fiecare 5,15,16,20 (+ Loco È™i 0) | (hazard) |



**Total kit: 24.611 triunghiuri pe 39 de fiÈ™iere, 44 de noduri de mesh.**



### Numele de noduri care contrazic aÈ™teptarea



Trei capcane pentru cine scrie mapÄƒri pe nume:



- **`guardhouse` are sufix `_001`**: nodurile sunt `House_Stone_001` /

  `House_Thatch_001`, nu `House_Stone` / `House_Thatch` ca la `inca_house_a`.

  O mapare scrisÄƒ pe `House_Stone` prinde casa È™i **rateazÄƒ** paznicul.

- **`inca_house_b` nu are `House_Stone` deloc** â€” un singur nod, `House_Ruin`.

- **`llama*.glb` au nodul de mesh `LlamaMesh`**, sub un `Node3D` numit `Llama`,

  sub un `Skeleton3D`. Numele de fiÈ™ier diferÄƒ (`llama`/`_b`/`_c`) dar **numele

  nodului e identic Ã®n toate trei** â€” memoria `nume-noduri-nu-sunt-unice` se

  aplicÄƒ direct: orice mapare pe `LlamaMesh` loveÈ™te toate trei variantele.



Cele trei lame diferÄƒ doar prin slot: `llama` pe 4+22 (FOAM_WHITE),

`llama_b` pe 1+4 (SAND_MID), `llama_c` pe 4+28 (LOG_DARK). Slotul 4 (ROCK_DARK,

copitele/botul) e comun, 48% din vertecÈ™i la toate trei.



## 2. Sloturi â€” ce cere `ACCENT_SPLIT` È™i ce NU suportÄƒ clasÄƒ triplanarÄƒ



**Toate cele 44 de noduri de mesh au UV COLAPSAT** (numÄƒrul de valori `u`

distincte e egal cu numÄƒrul de sloturi atinse, la fiecare nod). Deci contractul

atlasului e respectat peste tot: nicio piesÄƒ nu mÄƒturÄƒ lÄƒÈ›imea atlasului, nicio

piesÄƒ nu culege rezerva magenta. Verificarea e pe valori **distincte**, nu pe

`u_max âˆ’ u_min` (memoria `uv-colapsat-nu-e-un-interval`).



ConsecinÈ›a pentru texturile de clasÄƒ (memoria `clase-pe-piese-de-kit`): **43 din

44 de noduri au mai multe sloturi pe acelaÈ™i mesh**, deci o clasÄƒ triplanarÄƒ

pusÄƒ pe nod le-ar È™terge pe toate. Singurul nod mono-slot din tot kitul e

`Water` din `fountain_basin` (slot 17, REEF_SHALLOW, 100%).



Ce Ã®nseamnÄƒ concret: dacÄƒ vrei rosturi de piatrÄƒ pe zidÄƒrie (`inca_stone`), nu

poÈ›i pune clasa pe nodul Ã®ntreg â€” trebuie **ACCENT_SPLIT**. CandidaÈ›ii, ordonaÈ›i

dupÄƒ cÃ¢t de curat se separÄƒ accentul pe intervalul de `y` (memoria

`ruptura-accente-doua-sloturi`: se mÄƒsoarÄƒ intervalul de y, nu procentul):



| nod | corp (slot, %) | accent (slot, %) | y corp | y accent | se separÄƒ? |

|---|---|---|---|---|---|

| `Inca_Wall_A` | 3+29, 93.7% | 12 CACTUS_GREEN, 6.3% | 0.00â€“2.49 | **2.31â€“2.49** | **DA** â€” iarba stÄƒ doar pe coronament |

| `Inca_Wall_C` | 3+29, 91.5% | 12, 8.5% | 0.00â€“2.43 | **2.33â€“2.43** | **DA** |

| `Inca_Wall_B` | 3+29, 62.4% | 12, 6.3% | 0.00â€“2.49 | **2.30â€“2.49** | **DA** (dar mai are 4 ROCK_DARK 31.4% la 0.67â€“1.63, niÈ™ele) |

| `House_Ruin` | 3+29, 77.2% | 12, 22.8% | 0.00â€“2.83 | 0.85â€“2.83 | **NU** â€” muÈ™chiul urcÄƒ din 0.85, se suprapune cu zidul |

| `Moss_Boulder_A/B/C` | 3+29 | 12, 12â€“39% | â€” | A 0.38â€“0.74 Â· B 0.92â€“1.96 Â· C 0.97â€“3.07 | **DA pe A** (muÈ™chi doar pe capac); B/C se suprapun parÈ›ial |

| `Sun_Temple` | 3, 68.5% | 29 MARBLE_GREY, 25.5% | 0.00â€“5.59 | **2.15â€“5.59** | **DA** â€” coronamentul e clar peste bazÄƒ |

| `House_Stone` / `_001` | 3+29 | 9 WOOD (doar guardhouse) 16.4% | â€” | **0.00â€“2.50** | parÈ›ial â€” lemnul e Ã®n jumÄƒtatea de jos |

| `Huayna_Picchu` | 3 ROCK_LIGHT 37.2% | 12 CACTUS_GREEN **42.5%** | 3.40â€“33.00 | **0.00â€“11.40** | **DA** â€” vegetaÈ›ia e pe fustÄƒ, stÃ¢nca de la 3.40 Ã®n sus |

| `Machu_Picchu_Mountain` | 3, 14.3% | 21 TROPICAL_GREEN **45.7%** | 16.34â€“60.32 | 8.64â€“39.45 | parÈ›ial â€” se suprapun pe 16â€“39 m |

| `Gorge_Far_Wall` | 3, 29.6% | 21+12, 23.0% | 0.00â€“75.39 | 6.84â€“46.38 | **NU** â€” banda verde e Ã®n mijlocul peretelui |



**Piesele care NU cer ACCENT_SPLIT** (accentul e deja mic È™i localizat, sau

piesa e decor de orizont care nu primeÈ™te clasÄƒ): `Intihuatana` (doar 2 sloturi,

3+29, ambele piatrÄƒ â€” o clasÄƒ de piatrÄƒ pe tot nodul e corectÄƒ),

`Trail_Marker` (idem, 3+29), `Inti_Punku`, `Main_Gate`, `Three_Windows`

(3+4+29, toate trei sunt piatrÄƒ â€” accentul 4 ROCK_DARK e umbra buiandrugului,

4.3â€“4.4%, la `Main_Gate` fix Ã®n banda **5.94â€“6.06 m**, adicÄƒ grosimea

buiandrugului).



**AtenÈ›ie la slotul 12 (CACTUS_GREEN) pe zidÄƒrie**: apare pe *nouÄƒ* piese de

piatrÄƒ (`inca_wall_a/b/c`, `inca_stair_a/b`, `water_channel`, `sun_temple`,

`inca_bridge_ledge`, `house_ruin`) ca iarbÄƒ de coronament, Ã®ntre 2.4% È™i 22.8%.

E **acelaÈ™i slot** cu frunziÈ™ul de la `bromeliad`/`tent_b`/`moss_boulder`. O

mapare de clasÄƒ pe slotul 12 e globalÄƒ pe pistÄƒ â€” exact capcana `House_` din

`world_prop.gd`.



## 3. Golul liber pe piesele prin care se CONDUCE



MÄƒsurat cu `probe_mp_gaps.gd`, grilÄƒ de 1 cm, prin proiecÈ›ia triunghiurilor pe

planul (lateral, y). AABB-ul unei porÈ›i dÄƒ **anvergura**, nu deschiderea.



| piesÄƒ | anvergurÄƒ AABB | fereastra y | **gol liber mÄƒsurat** | brief | verdict |

|---|---:|---|---:|---:|---|

| `main_gate` | 16.80 m | 0.15–0.60 (la bază) | **8.30 m** | 8.39 m | aproape (poartă trapezoidală) |

| `main_gate` | **16.80 m** | **0.15–1.80 (GABARITUL MAȘINII)** | **8.12 m** | 8.00 m | **se confirmă, +0,12 m** |

| `main_gate` | 16.80 m | 0.15–5.80 (sub buiandrug) | 7.42 m | 6.00 m | mai larg decât se cere |

| `inti_punku` | 25.19 m | 0.15â€“4.80 | **13.98 m** | 14.000 m | **confirmat** |

| `inca_bridge_ledge` | 30.00 m | 8.00â€“11.00 (cota corniÈ™ei) | **4.23 m** | 4.25 m | **confirmat** |

| `inca_bridge_ledge` | 30.00 m | 0.15â€“12.80 (toatÄƒ Ã®nÄƒlÈ›imea) | 3.75 m | â€” | se strÃ¢nge mai jos |



### `main_gate`: golul depinde de înălțime (poarta e trapezoidală)

Ușciorii sunt în **taluz**, deci golul **se strâmtează cu înălțimea** — de
aceea inventarul are trei cifre care par să se contrazică (8,390 / 7,410 /
6,000) și **niciuna nu e greșită**: sunt luate la înălțimi diferite.
Buiandrugul e la **5,94–6,06 m** (slot 4, 4,3 % din vertecși), deci gabaritul pe
înălțime e 5,94 m, aproape de cei 6,00 declarați.

**Cifra care decide gameplay-ul e cea pe fereastra caroseriei** (`y = 0,15`,
sub prag, până la `1,80`, peste cel mai înalt plafon): **8,120 m**. Cerința
brief-ului (8 m liber pentru îmbrânceala cu 4 mașini) **se confirmă**, marjă
**+0,12 m**. Detaliile și retragerea concluziei contrare: mai jos, §3.1.

### ~~Poarta e mai îngustă decât drumul~~ — **RETRAS: poarta e TRAPEZOIDALĂ** (18 sep 2026)



> Secțiunea asta a susținut, pe 18 sep, că `main_gate` e cu 0,61 m mai îngustă

> decât carosabilul și că ușciorii stau în drum. **E greșit, și a fost

> infirmat în aceeași zi de constructorul POI-ului H** (`ProbeMpHGate.tscn`,

> rulată și independent). Se păstrează scrisă fiindcă eroarea e instructivă.



**Ce s-a ratat: poarta e trapezoidală**, deci golul **se strâmtează cu

înălțimea**. Măsurătoarea de 7,39 m din §3 e corectă — dar e luată pe

fereastra `y = 0,15–5,80` (până sub buiandrug), adică **la o înălțime la care

mașina nu trece**. Măsurat pe trei ferestre:



| fereastră de înălțime | gol liber | ce e |

|---|---:|---|

| `0,15–0,60` | **8,300 m** | „8,390 bază" din inventar |

| **`0,15–1,80`** | **8,120 m** | **gabaritul caroseriei — cifra care contează** |

| `0,15–5,80` | **7,420 m** | „7,410 sus" din inventar, și cei 7,39 din §3 |



**Cele trei cifre din inventar sunt toate corecte.** Nu se contrazic și nu

descriu greșit piesa — le lipsea doar **fereastra la care au fost luate**.

Nu se corectează nimic în inventar.



Și contractul de gameplay **se confirmă**: brief-ul cere 8 m liber pentru

îmbrânceala cu 4 mașini; în fereastra caroseriei sunt **8,120 m**, marjă

**+0,12 m**. La locul unde cade poarta (frac 0,963–0,965) drumul are exact

8,00 m, deci poarta e cu **6 cm mai largă de fiecare parte decât carosabilul**:

**încadrează drumul**, cum voia brief-ul. Gâtuirea rămâne a **drumului**.



**Lecția:** un gol nu e un număr, e un număr **plus fereastra pe care a fost

măsurat**. Când două măsurători ale „aceleiași" deschideri nu se potrivesc,

întreabă întâi **la ce înălțime** — înainte să declari una greșită. Memoria:

`golul-se-masoara-pe-fereastra-lui`.



Aritmetica plutonului de mai jos rămâne valabilă — și devine mai comodă:

prin 8,12 m, cele patru mașini (6,92 m de metal) au **1,20 m de joc**.



## 4. Coliziunea propusÄƒ, cu motivul mÄƒsurat



Tiparul e cel din `world_prop.gd:61` (`PROP_COLLISION`). Fiecare linie de mai

jos are cifra care o susÈ›ine, nu lista de plecare.



### `mesh` â€” se conduce PRIN ele



- **`main_gate`** (8,12 m gol pe gabaritul mașinii, buiandrug la 5,94 m) È™i **`inti_punku`**

  (13.98 m gol). Un `hull` convex peste o poartÄƒ e un **bloc plin**: la

  `main_gate` ar fi un zid de 16.80 Ã— 7.50 m fix peste drum, la `inti_punku`

  25.19 Ã— 5.00 m. Golul mÄƒsurat e chiar contractul de gameplay.

- **`inca_bridge_ledge`** (gol 4.23 m la cota corniÈ™ei, 3.75 m mai jos). Piesa e

  o corniÈ™Äƒ cu **gol vertical pe 12.90 m Ã®nÄƒlÈ›ime**: hull-ul ar astupa exact

  prÄƒpastia peste care sare `LiftBridgeHazard`. AcelaÈ™i motiv ca `crater_bowl`

  la Stromboli â€” cine cade trebuie sÄƒ CADÄ‚.



### `trunk` â€” bazÄƒ Ã®ngustÄƒ, coroanÄƒ latÄƒ



Criteriul mÄƒsurat e raportul **razÄƒ la bazÄƒ / semi-lÄƒÈ›ime AABB**. Sub 0.5 =

coroana depÄƒÈ™eÈ™te masiv trunchiul, deci hull-ul te opreÈ™te Ã®n aer. Patru piese

trec pragul; toate celelalte 35 sunt â‰¥ 0.76.



| piesÄƒ | razÄƒ bazÄƒ | semi-lÄƒÈ›ime | raport |

|---|---:|---:|---:|

| `tree_fern` | 0.30 | 2.07 | **0.15** |

| `bamboo_clump` | 0.50 | 1.24 | **0.40** |

| `polylepis_a` | 0.61 | 1.51 | **0.41** |

| `polylepis_b` | 1.10 | 2.36 | **0.47** |



âš  **`tree_fern` cere `TRUNK_FRACTION` corectat pe instanÈ›Äƒ.** `world_prop.gd:2535`

calculeazÄƒ raza cilindrului ca `max(aabb.size.x * 0.13, 0.22)`. Pentru feriga

arborescentÄƒ asta dÄƒ **0.54 m**, faÈ›Äƒ de raza realÄƒ a stipei de **0.30 m** â€”

cilindrul automat e de **1.8Ã—** prea gros, adicÄƒ un stÃ¢lp invizibil cu 24 cm mai

lat de fiecare parte decÃ¢t trunchiul care se vede. Celelalte trei ies sub raza

mÄƒsuratÄƒ (0.32 / 0.33 / 0.61 faÈ›Äƒ de 0.50 / 0.61 / 1.10), deci sunt sigure.

Verificat: `max(4.13*0.13, 0.22) = 0.537`.



### `none` â€” fantome



- **Decor de orizont**, exact ca `lengai` / `crater_far_wall` la Serengeti:

  `gorge_far_wall` (**196.00 Ã— 75.39 Ã— 92.06 m**), `machu_picchu_mountain`

  (**146.71 Ã— 60.50 Ã— 134.74 m**), `huayna_picchu` (**79.47 Ã— 33.00 Ã— 73.47 m**).

  Un hull pe oricare din ele e un corp fizic cÃ¢t o pistÄƒ Ã®ntreagÄƒ.

- **Accente mici fÄƒrÄƒ masÄƒ**: `bromeliad` (0.38 m Ã®nÄƒlÈ›ime), `orchid_cluster`

  (0.39 m), `backpack_pile` (0.69 m), `trail_marker` (1.20 m, razÄƒ bazÄƒ 0.29 m),

  `condor` (1.16 m, aripi ca insule de mesh separate â€” fÄƒrÄƒ AnimationPlayer Ã®n

  fiÈ™ier, static, confirmat). Toate sub Ã®nÄƒlÈ›imea capotei.

- **`water_channel`** (0.30 m Ã®nÄƒlÈ›ime, 4.00 m lungime) â€” jgheab care ZACE pe

  sol, ca `rail_track` la Baikal. Un hull ar fi un **prag de 30 cm** pe linia

  de curs; pragurile peste 0.3 m sunt ziduri pentru fizica Ã®ntreagÄƒ, iar Äƒsta e

  chiar la limitÄƒ. Se pun zeci de bucÄƒÈ›i cap la cap.

- **`rope_rail`** (1.045 m Ã®nÄƒlÈ›ime, **0.15 m grosime**, 4.14 m lungime,

  92 tri). E un parapet de frÃ¢nghie: hull-ul lui e o placÄƒ de 4 m lungime pe

  marginea drumului, exact unde maÈ™ina atinge la depÄƒÈ™ire. Nu e obstacol, e

  semnal vizual de margine.

- **`llama*`** â€” figuranÈ›i; È™i oricum se monteazÄƒ pe `SlidingHazard`, care Ã®È™i

  face colizorul lui.



### `hull` implicit â€” restul (21 de piese)



`guardhouse`, `inca_house_a/b`, `tent_a/b`, `moss_boulder_a/b/c`,

`fountain_basin`, `inca_stair_a/b`, `inca_wall_a/b/c`, `intihuatana`,

`sun_temple`, `three_windows`. Toate au raport razÄƒ/semi-lÄƒÈ›ime â‰¥ 0.76, adicÄƒ

baza e la fel de latÄƒ ca silueta â€” hull-ul convex e o aproximare onestÄƒ.



DouÄƒ note:



- **`inca_stair_a/b` au raport > 2.0** (3.16/1.50 È™i 6.08/3.00), fiindcÄƒ â€žraza

  la bazÄƒ" pe o scarÄƒ mÄƒsoarÄƒ diagonala treptei de jos, nu un trunchi. Sunt

  rampe pe care se URCÄ‚; `hull`-ul unei scÄƒri e o **panÄƒ**, nu un capac plan,

  deci e corect. DacÄƒ o capturÄƒ aratÄƒ cÄƒ maÈ™ina se urcÄƒ pe capac Ã®n loc sÄƒ

  atingÄƒ treptele, atunci se trece pe `mesh` (tiparul `kopje_kicker`).

- **`fountain_basin` are nodul `Water` la y = 0.50, un quad plan de 2 triunghiuri.**

  `hull`-ul lui e degenerat (grosime zero). Nu deranjeazÄƒ â€” bazinul are 0.60 m â€”

  dar dacÄƒ `world_prop` scoate un avertisment de shape degenerat, Äƒsta e

  vinovatul.



### Vehiculele nu trec prin `PROP_COLLISION`



`consettur_bus` È™i `perurail_train` sunt consumate de hazarde

(`bus_hazard.gd`, `train_hazard.gd`), care Ã®È™i fac colizoarele lor. Confirmat pe

geometrie:



- **`Consettur_Bus`** â€” un singur nod, AABB **3.66 Ã— 3.09 Ã— 6.16 m**, origine la

  sol, centrat pe XZ (`pos.x = âˆ’1.83 = âˆ’3.66/2`, `pos.z = âˆ’3.08 = âˆ’6.16/2`).

  Lungimea e pe **Z**, deci â€žÃ®nainte = âˆ’Z" din inventar e consistent cu forma.

- **`perurail_train`** â€” trei noduri cu numele exacte cerute de

  `train_hazard.gd`: `Train_Loco` (1390 tri, 8.90 m pe X), `Train_Tender`

  (1228 tri, 5.00 m pe X), `Train_Wagon` (1316 tri, 8.00 m pe X). **Lungimea e

  pe X la toate trei**, deci botul pe +X se confirmÄƒ din geometrie, nu doar din

  cod. Baza roÈ›ilor la **y = 0.000** pe toate trei. Total 3934 tri.



## 5. Costul de materiale â€” avertisment pentru plantare



`probe_decor --track=15` pe `main` dÄƒ **20 de materiale**, toate din

`procedural (track.gd)`, cu plafonul cerut de dezvoltator la **â‰¤ 20**. Kitul are

**39 de GLB-uri**, iar un GLB pe atlas costÄƒ **1 material**.



Asta Ã®nseamnÄƒ cÄƒ plantarea kitului nu poate fi â€žmai punem un prop": **fiecare

fiÈ™ier .glb distinct instanÈ›iat pe Track15 adaugÄƒ un material peste cele 20 de

azi.** Cifra de verificat dupÄƒ fiecare val de plantare e:



```powershell

& $E --headless --path D:/GameDev/wt-mp-fundatie `

     --script res://tools/probe_decor.gd -- --track=15

```



**`--track=15` e NUMÄ‚RUL DE SCENÄ‚**, nu poziÈ›ia Ã®n `TRACK_SCENES`. `--track=8`

mÄƒsoarÄƒ Okinawa È™i dÄƒ verde fals. (Toate celelalte sonde â€” `ProbeLayout`,

`ProbeBuried`, `ProbeLaneClear` â€” iau `--track=8`, poziÈ›ia.)



Nu am plantat nimic, deci cifra de 20 e neschimbatÄƒ; e linia de bazÄƒ faÈ›Äƒ de

care se citeÈ™te primul val.



> **CORECÈšIE (pasul 4, clasele de texturÄƒ).** Fraza de mai sus â€” â€žfiecare fiÈ™ier

> .glb distinct instanÈ›iat pe Track15 adaugÄƒ un material" â€” e **falsÄƒ**, È™i a

> fost cititÄƒ greÈ™it din tabelul lui `probe_decor`. Coloana `mat.` e

> `all_mats.size()`, un set **deduplicat global pe `instance_id`**, iar blocul

> â€žpe surse" de sub el numÄƒrÄƒ acelaÈ™i material o datÄƒ pentru **fiecare sursÄƒ**

> Ã®n care apare. De aceea rÃ¢ndurile `GLB: train 1 materiale`, `GLB: cow 1` etc.

> par sÄƒ se adune la 20 fÄƒrÄƒ sÄƒ se adune de fapt: materialul lor **e** atlasul,

> deja numÄƒrat Ã®n cele 20 procedurale.

>

> MÄƒsurat direct (`tools/probe_mp_class_cost.gd`, care planteazÄƒ 26 de piese de

> kit Ã®n Track15 È™i numÄƒrÄƒ exact ca garda): **16 materiale unice, 156 de noduri

> pe acelaÈ™i `Palette.world_material()`**. Kitul de 39 de GLB-uri costÄƒ

> **ZERO** materiale, nu 39.

>

> ConsecinÈ›a pentru buget: aritmetica â€ž20 + 7 clase = 27 > 20" nu se aplicÄƒ.

> Pe `feat/mp-fundatie` Track15 pleacÄƒ de la **17** materiale, iar plafonul real

> al garzii e **38**, nu 20 â€” deci existÄƒ loc. Ce costÄƒ e **clasa**, nu piesa:

> un material per clasÄƒ, oricÃ¢te piese o poartÄƒ (`triplanar_class_material` e

> cache-uit per clasÄƒ).



## 6. Ce NU spune mÄƒsurÄƒtoarea asta



- **Culoarea compusÄƒ.** Sloturile de mai sus sunt indici Ã®n atlas; cum aratÄƒ

  muÈ™chiul-retag, benzile de pe `gorge_far_wall` È™i rozul orhideei se judecÄƒ

  abia pe capturÄƒ din maÈ™inÄƒ, Ã®n Godot, dupÄƒ remap (memoria

  `monocromia-se-masoara-dupa-remap`). Tabelul de sloturi spune **din ce** e

  fÄƒcutÄƒ culoarea, nu **cum aratÄƒ**.

- **DacÄƒ propunerea de coliziune È›ine Ã®n cursÄƒ.** `hull`/`trunk`/`mesh` de mai

  sus sunt derivate din geometrie, dar verdictul e `ProbeLaneClear` +

  `ProbeRace` dupÄƒ plantare. `ProbeLaneClear` **nu are azi linie de bazÄƒ pentru

  Track15** (`tools/probe_lane_clear.gd:180-189`), deci iese 0 orice ar gÄƒsi â€”

  garda nu e armatÄƒ pÃ¢nÄƒ nu se scrie Ã®n `BASELINE`.

- **Forma.** Niciuna din cifrele de aici nu vede dacÄƒ o piesÄƒ e un con neted sau

  o stÃ¢ncÄƒ cu caracter (lecÈ›ia `verify_glb.py` din inventar). PlanÈ™a È™i captura

  rÄƒmÃ¢n singurele care o prind.

