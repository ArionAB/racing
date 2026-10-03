# Brief assets — Kyoto (`Track18`, temă `kyoto`)

**Contractul complet pentru instanța de assets (Blender).** Pe tiparul
`jodhpur_kit.md`; regulile generale sunt în `docs/blender_export.md` și
`docs/style_bible.md` §4. Brief-ul pistei: `docs/track_briefs/kyoto.md` (§0.1
regula de artă, §4 paleta, §5 assets cu cotele, §5.6 contractele pe cod).

**Fidelitatea față de planșă e criteriu de acceptare, nu inspirație** (§0.1).
Aici fiecare desen are propria decupare și se livrează cu o comparație alăturată.

| fișier | ce e | ce iei din el |
|---|---|---|
| `docs/track_briefs/img/kyoto_assets_v1/<nume>.png` | **decuparea piesei**, câte una pentru fiecare dintre cele 59 de desene, mărită 2× (`tools/blender/crop_kyoto_sheet.py`; montajul de control `_control.png`) | **referința de lucru a piesei:** silueta, numărul de elemente, proporțiile interne, culorile |
| `docs/track_briefs/img/kyoto_plan/inventar_v02.jpg` | planșa întreagă (12 rânduri) | scara relativă între piese dintr-un rând. **NU dimensiuni:** mașina de scară e desenată la fel pe toate rândurile |
| `docs/track_briefs/img/kyoto_plan/diorama_v02.jpg` | diorama | atmosfera și ansamblul. **Nu stilul** (e pictată). Unde se contrazic, planșa câștigă |
| `docs/track_briefs/img/kyoto_plan/kyoto_plan.png` | planul real al pistei | unde stă fiecare piesă; nu o folosești la modelare |

Decupările care nu sunt 1:1 cu numele piesei: `kitsune_statue.png` (ambele
vulpi), `kitsune_statue_a/_b.png` (câte una); `sika_deer_stand/graze/bow.png`;
`horizon_Higashiyama_A/B`, `horizon_Arashiyama_A`, `horizon_FarRoofs_A` (cele
4 noduri ale `kyoto_horizon.glb`).

**Corecturi decise de coordonator (suprascriu planșa):**
- semnul roșu de pe `paper_lantern` NU se modelează; **fără text, caractere,
  kanji, logo-uri nicăieri** (porți, plăcuțe, tren, barcă, ema);
- `momiji_a/b/c` au **SILUETE diferite** (nu doar culori): coroane din ciorchini
  turtiți / etaje cu goluri, **niciodată glob**;
- cotele vin din brief-ul pistei §5 și din tabelele de mai jos, **NU din planșă**.

## 0. Regulile care nu se negociază

1. **Categoria** e `assets/models/kyoto/{buildings,structures,props,vehicles,animals,plants,rocks}/`.
   `dio_lib.export_glb` primește calea cu categorie (`"kyoto/structures/x.glb"`;
   `kyoto_shapes.emit` pune prefixul singur).
2. **Asset nou = fișier nou.** Nu se suprascriu `props/daruma_otoshi.glb`,
   `structures/shishi_odoshi.glb`, `structures/torii_senbon.glb`,
   `structures/torii_large.glb`, `trees/cedar_dark.glb` (și nici folderul `trees/`:
   copacii noi merg în `plants/`, ca în brief §5).
3. **Instanța de assets nu atinge `scenes/` și `scripts/`.** Clasele de textură
   (`maple_*`, `ginkgo_gold`, `leaf_litter`, `machiya_wood`, `moss`),
   `PROP_COLLISION`, `CLASSES_BY_MODEL`, placerele de poduri, orizontul din temă,
   `DecorManual` și montarea în `Track18.tscn` sunt ale coordonatorului. Aici se
   livrează GLB + build script + preview + verify + inventar + comparații.
4. **Paletă: zero sloturi noi.** UV1 colapsat pe centrele sloturilor, AO copt în
   vertex colors, origine la bază (excepțiile sunt în tabel), scară metrică,
   **scala aplicată pe fiecare nod rădăcină** (memoria
   `scala-glb-neaplicata-la-radacina`). „Înainte" e −Z în Godot = **+Y în
   Blender** (fața bogată a clădirilor stă pe +Y; se **măsoară** pe GLB, nu se
   presupune — memoria `fata-casei-nu-e-plus-z`).
5. **Sloturile pe roluri** (tabelul de mai jos). Culoarea finală o dă clasa
   (unde există), nu slotul; nu încerca să prinzi culoarea planșei cu alt slot.
6. **Piesele care primesc clasă la integrare se sparg la export în obiecte cu
   un singur material** (memoria `clase-pe-piese-de-kit`). Un nod = un material
   potențial. **Offsetul de origine se calculează o dată pe ansamblu**
   (`kyoto_shapes.emit`); verificarea e `verify_glb.py --origin=assembly`.
7. **Rosturile de zidărie, fibra lemnului, petele NU sunt geometrie** (vin din
   clasă). **Geometrie sunt formele care schimbă silueta sau umbra**: streșini
   curbate, nervurile de țiglă (kawara), console, balustrade, trepte,
   felinare. Regula: „se vede la 30 m din mașină ca formă?".
8. **Țigla kawara e din atlas** (`VOLCANIC_BLACK` 20) **cu nervurile în
   geometrie**, fără clasă și fără a atinge `CLASS_TINT["roof_tiles"]`
   (brief pistei §4). `kyoto_shapes.hip_roof` o face (rânduri la ~0,8 m).
9. **Fără text, fără cifre, fără logo-uri** (vezi corecturile de mai sus).
10. **Primitive rotunde: setează `segments`** (6–12; bambusul `moso_culm` 6).
11. **Verificarea e din fișier, nu din memorie:** `verify_glb.py` pe fiecare
    GLB, iar `preview_kyoto.py` randează **din GLB-urile exportate**. Verdictul
    kitului e `bash tools/blender/verify_kyoto.sh` → `VERDICT KIT: OK` **și**
    comparațiile de fidelitate aprobate (§0.1). `verify` verde nu e livrare.
12. **Randările rulează pe GPU:** înainte de orice randare Blender/Godot cu
    fereastră, `mkdir D:/GameDev/.render_lock` (dacă eșuează, alt proces
    randează: așteaptă), `rmdir` imediat după.

### Sloturi pe roluri

Doar sloturi existente (`scripts/palette.gd`, constantele din `dio_lib.py`) și
clasele Kyoto existente (`palette.gd:858-867, 1091-1099`).

| rol | slot (în GLB) | clasă la integrare (nu o faci tu) |
|---|---|---|
| vermilion sacru (porți, pagode, Niōmon, Rōmon, torii) | `LAVA_ORANGE` 30 | — (atlas; lacul e neted). Verifici pe captură că nu iese „ars"; dacă da, coordonatorul trece pe `CAR_RED` |
| grinzi *kasagi*, lemn de templu, console, fațete de streașină | `LOG_DARK` 28 | — |
| stâlpi/balustrade brun-roșcat (pagodă, poduri, scenă) | `WOOD` 9 | `machiya_wood` pe casele de oraș (la pagodă/pod: fără clasă) |
| lemn de machiya | `WOOD` 9 (nod `Machiya_Wood`), `LOG_DARK` 28 (rame, nod `Machiya_Trim`) | `machiya_wood` pe `Machiya_Wood` |
| țigla kawara | `VOLCANIC_BLACK` 20, nervuri în geometrie | — |
| tencuiala albă (machiya, `temple_wall`, panouri) | `FOAM_WHITE` 22 | `village_plaster` (reutilizat, netentat) pe nodul `*_Plaster` |
| piatră (felinare, zidul ciclopic, socluri, vulpi) | `MARBLE_GREY` 29, `CONCRETE` 8, `ROCK_LIGHT` 3 | `old_stone` / `granite` pe nodul `*_Stone` |
| aur (Kinkaku-ji, sorin) | `CAR_YELLOW` 16 (+ `SAND_LIGHT` 0 pe fețele de sus) | — ; exceptie `--allow-car-slots=<Nod>` |
| arțar carmin | `KERB_RED` 7 | `maple_crimson` pe `Maple_Crown` |
| arțar roșu-portocaliu | `LAVA_ORANGE` 30 (slotul nu contează cu clasa pe nod; **evită** `CAR_RED` ca să nu ceri excepție) | `maple_orange` |
| arțar ruginiu | `LARCH_RUST` 27 | clasa ruginiu (`leaf_litter` sau a treia clasă de arțar, decide coordonatorul) |
| ginkgo | `CAR_YELLOW` 16 (`--allow-car-slots=Ginkgo_Crown`) | `ginkgo_gold` |
| covor / grămadă de frunze | `LARCH_RUST` 27 | `leaf_litter` |
| mușchi (movile, pietre, ziduri) | `TROPICAL_GREEN` 21 | `moss` pe nodul `*_Moss` |
| pini niwaki, tufe karikomi | `TROPICAL_GREEN` 21 / `CACTUS_GREEN` 12 | — (sau `moss`, decide coordonatorul) |
| bambus (tulpini) | `TROPICAL_GREEN` 21 + `DRY_VEGETATION` 13 la noduri | — |
| umbrele și bănci ceainărie, trenul | `CAR_RED` 14 (`--allow-car-slots=<Nod>`) | — |
| cerbi | `SAND_MID` 1, pete `CORAL_SAND` 19 | — |
| goluri (ferestre, uși deschise) | `VOLCANIC_BLACK` 20, nod separat unde piesa primește clasă | — |

Pista e **diurnă, lumină fixă** (brief §4): nu se cer noduri `*_Glow`.

## 1. Inventar și contracte

Dimensiuni în metri. `h/l` = înălțime/lățime a siluetei pe decupare, la unghiul
planșei (se verifică în comparație, ±15%). Triunghiurile se **raportează, fără
plafon** (CLAUDE.md); contează **materialele** (un nod = un material).
„Față" = +Y în Blender = −Z în Godot. **Modulele înlănțuibile** au capete
identice, plane, la ±L/2 pe Y. **Cotele de contract (goluri) se măsoară ca GOL**
(proiecție pe plan, memoria `cota-de-contract-se-masoara-ca-gol`).

Coliziunea la integrare (brief §5.6) e a coordonatorului; coloana e doar ca să
știi ce nod trebuie să existe.

### 1.1 Pagodele — `build_kyoto_pagodas.py`

| fișier | cote | h/l | contract | abatere permisă |
|---|---|---:|---|---|
| `structures/yasaka_pagoda.glb` **(pilot, făcut)** | **24 m** înaltă, streașina de jos ~12 m | ~1,5 | 5 etaje, 5 acoperișuri în patru ape cu colțuri ridicate, console sub fiecare, balustradă pe etajele 2–5, sorin aurit (~19% din înălțime). Noduri `Pagoda_Roof`, `Pagoda_Body`, `Pagoda_Windows`, `Pagoda_Spire`. Origine la bază, centrată. Coliziune `mesh`/`hull` (decor) | lățimea poate ieși cu ≤15% mai mare decât pe decupare (perspectiva de 3/4) |
| `structures/sanjunoto_pagoda.glb` | ~**18 m** (cota nu e în brief — de confirmat) | ~1,6 | 3 etaje **vermilion** (`LAVA_ORANGE`), acoperișuri gri, parter cu var alb în jos și soclu alb, sorin | — |
| `structures/koyasu_pagoda.glb` | **14 m** | ~1,6 | 3 etaje vermilion, sorin; **ținta săriturii** (aterizarea e pe teren, nu pe pagodă) | — |

### 1.2 Arborii — `build_kyoto_trees.py`

Un copac = **un nod de trunchi + un nod de coroană** (clasele se leagă per
nod). Coliziune `trunk` la integrare; trunchiul are rază 0,5–0,7 m.

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `plants/momiji_a.glb` **(pilot, făcut)** | **8 m** × ~11 m lat | 0,75 | Coroană carmin din ~13 ciorchini turtiți cu margine lobată, în etaje, goluri între ei; trunchi cu furcă la 2,5 m. `Maple_Trunk` (`WOOD`), `Maple_Crown` (`KERB_RED`) |
| `plants/momiji_b.glb` | **8,5 m** × ~10 m | 0,85 | roșu-portocaliu; **altă siluetă decât a**: coroană mai înaltă, în 3 etaje înguste, „pagodă", cu gol mare sub etajul de jos. `Maple_Trunk`, `Maple_Crown` (`LAVA_ORANGE`) |
| `plants/momiji_c.glb` | **7 m** × ~11 m | 0,65 | ruginiu; coroană lată, tabulară, doi „brațe" asimetrice, trunchi înclinat. `Maple_Crown` (`LARCH_RUST`) |
| `plants/ginkgo.glb` | **11 m** × ~7 m | 1,5 | coroană **în con**, aurie, în ciorchini în trepte; `Ginkgo_Trunk`, `Ginkgo_Crown` (`CAR_YELLOW`, `--allow-car-slots=Ginkgo_Crown`) |
| `plants/niwaki_pine.glb` | **5 m** × ~7 m | 0,7 | pin tuns în „nori" (4–5 plăcuțe verzi rotunjite) pe trunchi sinuos; `Pine_Trunk`, `Pine_Crown` |
| `plants/moso_culm.glb` | **20 m** înălțime, Ø 0,25 m | — | o tulpină, **`radial_segments` 6**, noduri (inele) la ~1,2 m (`DRY_VEGETATION`), vârf cu 2–3 frunze. Pentru MultiMesh: un singur mesh |
| `plants/bamboo_crown.glb` | **~4 m lat × 9 m** | 2,2 | tufă de 10–14 tulpini cu frunze în vârf; `Bamboo_Culms`, `Bamboo_Leaves` |

### 1.3 Sala, scena și porțile — `build_kyoto_halls.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `structures/niomon_gate.glb` | ~**20 m** lat, **13 m** înalt; **golul ≥ 11 m** liber | 0,6 | poartă vermilion cu 2 etaje: acoperiș mare gri cu streașină curbată, galerie cu balustradă la etajul 2, stâlpi vermilion, **gol măsurat ca GOL ≥ 11 m lățime, pe înălțimea caroseriei (2 m)**. Noduri `Gate_Wood` (`LAVA_ORANGE` + `LOG_DARK`), `Gate_Roof`, `Gate_Plaster`. Coliziune `mesh`: stâlpii laterali pot fi solizi, golul nu |
| `structures/inari_romon.glb` | ~**18 m** lat, **12 m** înalt; **gol ≥ 11 m** | 0,65 | poartă-turn vermilion, același contract de gol |
| `structures/kakezukuri_scaffold.glb` | **6 m** lat × **16 m** înalt (modul, adânc ~6) | 2,3 | rețea de stâlpi și grinzi de lemn (`WOOD`/`LOG_DARK`), repetabilă; **coliziune `mesh`** (decor pur, nu bloc solid); capete plane pentru înlănțuire; nod `Scaffold_Wood` |
| `structures/kiyomizu_hondo.glb` | ~**30 m** lat × 20 adânc × 14 înalt (cu scena) | 0,5 | sala principală: acoperiș în patru ape mare, gri-închis, pe `LOG_DARK`; **fața dinspre scenă (+Y) e cea bogată**: verandă pe piloni, scară de lemn, pereți albi cu stâlpi. Noduri `Hondo_Roof`, `Hondo_Wood`, `Hondo_Plaster`. Puntea scenei e drum (cod), nu GLB |

### 1.4 Pavilionul de aur — `build_kyoto_kinkakuji.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `structures/kinkakuji.glb` | **14 m** înalt, ~13 m lat | 1,05 | 3 etaje: **jos lemn natural** (`LOG_DARK`/`WOOD`, nod `Kin_Wood`), **două etaje de sus aur** (`CAR_YELLOW`, nod `Kin_Gold`, galerii cu balustrade), acoperișuri gri (`Kin_Roof`), fenix aurit pe creastă; doi pini mici la bază **nu fac parte din GLB** (se pun din `niwaki_pine`). Decor pur, fără variantă oglindită |

### 1.5 Poduri — `build_kyoto_bridges.py`

Placerul pe curbă e cod nou al coordonatorului (module cu origine în centru pe
axă, nivelul punții la y = 0, −Z înainte). **Parapetul procedural există deja**;
GLB-ul aduce acoperiș, stâlpi, piloni. Balustrada de pe planșă se modelează ca
nod separat `*_Rail`, ca să poată fi stinsă.

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `structures/tsutenkyo_roof_module.glb` | **6 m** lung (Y); drumul real **±4,5 m** + parapet procedural; stâlpi la ±5,4, liber interior **≥10,4 m**, **înălțime liberă ≥4,5 m deasupra punții pe tot ±4,5 m** (stâlpi 4,95 m, grinzi la ~5,0; măsurat 4,65 m; autobuzul/pompierii depășesc 2 m și modulul e fără coliziune), streașină ±6,9, coama ~+8,3 (sursa: `Track18.tscn` `custom_width_segments`, frac 0,449–0,466) | 0,3 | acoperiș de țiglă pe stâlpi, părți deschise, capete identice; `Tsu_Roof`, `Tsu_Wood`, `Tsu_Rail`; coliziune `none` |
| `structures/togetsukyo_module.glb` | **10 m** lung; drumul real **±7,0 m** (frac 0,832–0,894): punte ±7,6, balustradă ±7,4, liber interior 14,3 m; înalt (cu piloni) ~3,4 | 0,25 | punte joasă pe piloni de lemn; `Toget_Wood`, `Toget_Rail`; `none` |
| `structures/iron_truss_bridge.glb` | travee **~20,8 m**, lat 4,5; drumul real **±6,0 m** (frac 0,804); **gol înghețat 15,15 m × ≥6,25 m** (culee la |x|≥7,6), ~6,3 m deasupra drumului | 0,4 | pod feroviar cu zăbrele, roșu-ruginiu (`RUST`/`CAR_RED` cu excepție), **drumul trece pe dedesubt**: deschiderea liberă ≥ 11 m lat, ≥ 6 m înălțime, măsurată ca GOL; `mesh` |

### 1.6 Orașul — `build_kyoto_town.py`

Case care se multiplică (zeci): **fațada spre drum e bogată, spatele simplu**.
Fiecare: `Machiya_Wood` (clasă `machiya_wood`), `Machiya_Trim` (rame/zăbrele
`LOG_DARK`), `Machiya_Plaster` (`FOAM_WHITE`), `Machiya_Roof` (țigla).

| fișier | cote | h/l | contract (elemente pe decupare) |
|---|---|---:|---|
| `buildings/machiya_a.glb` | **6,5 × 9 m**, 7,5 m | 1,1 | 2 etaje, acoperiș în două ape cu creasta paralelă cu strada, streașină intermediară peste parter, zăbrele kōshi, **noren alb** în ușă |
| `buildings/machiya_b.glb` | idem | 1,1 | **noren albastru**, fereastră cu pereți albi sus |
| `buildings/machiya_c.glb` | idem | 1,1 | 3 ferestre mari sus, zăbrele fine jos |
| `buildings/machiya_d.glb` | idem | 1,1 | **jaluzele de bambus** (`SAND_MID`) pe etaj |
| `buildings/machiya_e.glb` | idem | 1,1 | ca b, fără noren, cu ferestre divizate |
| `props/teahouse_front.glb` | ~3 × 2,4 × 3 m | 0,9 | bancă roșie + umbrelă roșie *nodate-gasa* pe stâlp central, cutie de lemn la picior. `Tea_Red` (`CAR_RED`, `--allow-car-slots=Tea_Red`), `Tea_Wood` |
| `props/paper_lantern.glb` | **3,6 m** înalt | 2,5 | stâlp de lemn cu braț, felinar alb de hârtie stins, cu bandă neagră sus și jos, **fără semn roșu** (corectura coordonatorului) |
| `structures/temple_wall.glb` | modul **8 m** × 0,6 × 3,2 | 0,35 | zid alb cu capac de țiglă și soclu de piatră; capete plane; `Wall_Plaster`, `Wall_Roof`, `Wall_Stone` |

### 1.7 Templele — `build_kyoto_shrine.py`

| fișier | cote | contract |
|---|---|---|
| `structures/votive_torii_cluster.glb` | 6 porți în șir, cea mare 4,2 m înaltă, descrescând | șir de torii vermilion, cu *kasagi* negru, stâlpi cu bază neagră (`LAVA_ORANGE` + `LOG_DARK`); NU suprascrie `torii_senbon` |
| `props/kitsune_statue_a.glb`, `_b.glb` | 1,9 × 0,9 × 0,9 m | vulpe albă pe soclu de piatră, **bavetă roșie** (`CAR_RED`, `--allow-car-slots`), cheie în gură; a și b diferă prin poză (decupările `_a`, `_b`); `hull` |
| `props/stone_lantern_a.glb`, `_b.glb` | 2,4 m / 1,7 m | tōrō în 6 piese (soclu, fus, platformă, cutie cu ferestre, acoperiș, cioc), `_b` mai scund și mai lat; `MARBLE_GREY`; `hull` |
| `props/yukimi_lantern.glb` | 1,3 m | felinar scund pe trei picioare, cu acoperiș larg (malul iazului) |
| `structures/small_shrine.glb` | 3 × 2,6 × 3,4 m | altărel vermilion cu acoperiș gri, soclu de piatră, uși |
| `props/ema_rack.glb` | 3,2 × 0,5 × 2,4 m | cadru de lemn cu 3 × 4 plăcuțe **goale**, mic acoperiș |
| `structures/bell_tower.glb` | 5 × 5 × 6 m | pavilion deschis pe 4 stâlpi, acoperiș gri, clopot de bronz verde (`TROPICAL_GREEN`) |
| `props/chozuya.glb` | 3,2 × 2,2 × 2,8 m | bazin de piatră sub acoperiș mic, 4 stâlpi, 3 căușe |
| `structures/cyclopean_wall.glb` | modul **8 m** × 2,5 × 4 m, taluzat | piatră mare ciclopică în poligoane, **mușchi pe nod separat `Cyc_Moss`**, `Cyc_Stone`; capete plane |

### 1.8 Grădina și pădurea — `build_kyoto_garden.py`

| fișier | cote | contract |
|---|---|---|
| `props/shiba_fence.glb` | modul 3 m × 0,15 × 1,1 | gard de nuiele între stâlpi cu legături; capete identice |
| `plants/karikomi_shrub_a.glb`, `_b.glb` | Ø ~1,6 m / ~2,0 m | tufe rotunjite fațetate (nu sfere: ~20 fețe mari) |
| `rocks/garden_rock_a.glb`, `_b`, `_c` | 1,6 / 1,3 / 1,2 m | piatră cu fețe mari; a și c cu **mușchi la bază (nod `Rock_Moss`)** |
| `rocks/stepping_stones.glb` | 3 plăci, ~2,6 m total | plăci octogonale joase |
| `rocks/moss_mound.glb` | 3 × 2,4 × 1 m | movilă de mușchi cu pietre ieșite; `Moss_Mound` (`TROPICAL_GREEN`, clasă `moss`), `Moss_Stone` |
| `props/leaf_pile.glb` | Ø 1,6 × 0,5 m | grămadă de frunze (plăci mici roșu-ruginii, `LARCH_RUST`); coliziune `none`; mesh-ul e doar grămada |

### 1.9 Vehicule și oameni — `build_kyoto_people.py`

| fișier | cote | contract |
|---|---|---|
| `vehicles/sagano_train.glb` | ~**25 m** × 2,4 × 3,2 | locomotivă + 3 vagoane în linie dreaptă, **−Z înainte**, roșu-brun de epocă (`CAR_RED`/`LOG_DARK`, excepție de nod), **fără livrea**; un singur corp (`PathMover`, AABB) |
| `vehicles/jinrikisha.glb` | 2,6 × 1,2 × 1,9 m | ricșă roșie cu capotă neagră, roți cu spițe, alergător (pălărie conică) în față; `PathMover`; −Z înainte |
| `vehicles/yakatabune.glb` | 9 × 2,2 × 2,4 m | barcă de lemn cu acoperiș pe stâlpi, deschisă pe laturi; −Z înainte, plutește (`stick_to_ground = false`) |
| `props/monk_sweeper.glb` | 1,75 m | călugăr cu pălărie conică, kimono gri-închis, mătură de bambus; static (teatru) |

### 1.10 Animalele — `build_kyoto_animals.py`

Rig-uri cu helperele din `dio_lib.py` (`make_armature`, `weight_ramp`,
`pose_rotate`, `stash_actions`), rețeta `build_cow_animated.py`.

| fișier | cote | contract |
|---|---|---|
| `animals/sika_deer.glb` | 1,6 m lung, 1,1 m la spate (în picioare) | cerb cu pete albe; **rest pose = `Stand`**; acțiuni `Stand`, `Graze`, `Bow` (nume exacte). Capul spre +Y. `none` |
| `animals/crow.glb` | anvergură **1,6 m** | cioară neagră cu aripile larg deschise; origine în centru; `Fly` (buclă); `none` |

### 1.11 Fundalul — `build_kyoto_horizon.py`

`rocks/kyoto_horizon.glb`: noduri `Higashiyama_A`, `Higashiyama_B` (dealuri
joase cu pădure de toamnă, petice roșii și aurii pe verde-închis, ~**200 × 45 ×
30 m**), `Arashiyama_A` (munte verde mai înalt, **~220 × 70 × 55 m**),
`FarRoofs_A` (bandă de acoperișuri gri care se pierde în pâclă, **~150 × 12 ×
10 m**). **Copii direcți ai rădăcinii, volume închise lizibile din orice azimut,
origine la bază** (consumator `Track._build_horizon`). **Fără Turnul Kyoto, fără
clădiri moderne.** Referința: decupările `horizon_*.png` (siluetă și culoare),
nu stil. Fără coliziune; `cast_shadow` OFF la integrare.

### 1.12 Ce NU se generează

Puntea scenei, `SaritaScena`, râpele, apa, puntea podurilor, particulele
(frunze care cad, stropi), decalul `leaf_carpet`, reflexia pavilionului,
placerul de poduri și bariera de bambus din `moso_culm` (MultiMesh) sunt cod/teren.
Existente, neatinse: `daruma_otoshi`, `shishi_odoshi` (orfan), `torii_senbon`,
`torii_large`, `cedar_dark`. Din planșa v0.2 lipsesc `stone_stairs_decor` și
`river_stones` (în §5.3 al brief-ului pistei): nu se fac fără decupare.

## 2. Livrabile

| fișier | ce |
|---|---|
| `tools/blender/build_kyoto_{pagodas,trees,halls,kinkakuji,bridges,town,shrine,garden,people,animals,horizon}.py` | rulabile headless: `D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- build_kyoto_pagodas.py`. **Docstring-ul fiecărei funcții de piesă conține lista de elemente** (§0.1 pasul 1), scrisă înainte de primul vertex. Vocabularul (acoperiș în patru ape, ciorchine de arțar, inele de sorin) e în `kyoto_shapes.py` |
| `tools/blender/preview_kyoto.py` (+ `compose_kyoto.py`) | `--compare <nume>` (decupare ↔ randare), `--views <nume>` (4 azimuturi, control propriu), `--solo`, `--sheet <val> a,b,c` |
| `tools/blender/verify_kyoto.sh` | o rulare, un verdict, excepțiile declarate cu motiv |
| `docs/asset_briefs/kyoto_inventory.md` | cote măsurate, tri, noduri, tabele de fidelitate, contracte înghețate, **„Stare la oprire"** |
| `docs/asset_briefs/img/kyoto_fidelity/<nume>.png` | comparațiile alăturate |

## 0.1 Fidelitatea față de planșă — criteriul de acceptare

Planșa e sursa de **formă și culoare**; tabelele de aici sunt sursa de **cote și
de contracte de cod**. Orice altă abatere de la planșă e o greșeală, chiar dacă
piesa „arată bine".

1. **Deschide decuparea** (`kyoto_assets_v1/<nume>.png`) și scrie în docstring
   **lista de elemente** cu numere: câte etaje/acoperișuri, câți ciorchini,
   câte ferestre pe fiecare față, ce iese din contur. Înainte de primul vertex.
2. **Modelează după listă**, la cotele din tabel. În afara coloanei „abatere
   permisă", proporțiile interne ale desenului se păstrează.
3. **Randează comparația** (`preview_kyoto.py --compare <nume>`): decuparea în
   stânga, randarea GLB-ului în dreapta, aceeași înălțime în pixeli, 3/4 din
   față, lumină de zi neutră, fundal `#CFCFCF`, **culoare reală**: fiecare față
   pe culoarea slotului ei din atlas (recuperat din UV), nodurile cu clasă pe
   hex-ul clasei (`maple_crimson` = `#BB3522` etc.).
4. **Verifică pe imagine, element cu element**, nu doar numărând (memoria
   `numaratoarea-trece-amplasarea-nu`): poziția pe fața corectă, forma
   (curbat/drept, cu goluri/plin), `h/l` al siluetei (±15%), ordinea
   luminozităților, ce iese din contur. Tabel în inventar: element | pe planșă
   | în GLB | OK/abatere.
5. **Maximum 3 runde pe piesă.** Dacă tot nu seamănă, se raportează abaterea
   cinstit (inventarul), nu se declară „trece".
6. **Piesa se acceptă doar după ce comparația e văzută** de coordonator. La
   finalul fiecărui val, comparațiile se adună într-o planșă
   (`preview_kyoto.py --sheet`).

**Ce NU e fidelitate:** textura pictată (rosturi, fibră, pete) nu se copiază în
geometrie (regula 7). Animalele sunt netede pe planșă; în GLB sunt low-poly cu
fațete mari, dar **silueta și petele de culoare** rămân.

## 3. Ordinea de lucru (valuri de ~3 piese grele; fiecare cu verify + comparații + commit)

0. **Pilot (făcut):** `yasaka_pagoda`, `momiji_a` + harnasul (decupări,
   `preview_kyoto`, `verify_kyoto`, vocabular).
1. **Contractele de gol/coliziune:** `niomon_gate`, `inari_romon`,
   `kakezukuri_scaffold` (golul ≥ 11 m se măsoară ca GOL, înainte de orice altceva).
2. **Hero:** `kiyomizu_hondo`, `kinkakuji`, `sanjunoto_pagoda` + `koyasu_pagoda`.
3. **Arborii:** `momiji_b`, `momiji_c`, `ginkgo`, `niwaki_pine` (siluetele
   diferite se compară între ele pe o singură planșă).
4. **Orașul:** `machiya_a…e`, `teahouse_front`, `paper_lantern`, `temple_wall`
   (fața se măsoară pe GLB).
5. **Podurile:** `tsutenkyo_roof_module`, `togetsukyo_module`, `iron_truss_bridge`.
6. **Templele:** felinare, altărel, ema, clopotniță, chozuya, ziduri, torii,
   vulpi.
7. **Grădina și pădurea:** gard, tufe, pietre, mușchi, grămada de frunze, bambus.
8. **Contractele de cod:** tren, ricșă, barcă, călugăr; apoi cerb și cioară (rig).
9. **Fundalul:** `kyoto_horizon.glb`.

Lucrează în worktree-ul `D:/GameDev/wt-kyoto-kit` (ramura `kyoto/kit`). Nu
comite pe `main`, nu folosi `git stash` (e comun tuturor worktree-urilor), nu
face push.
