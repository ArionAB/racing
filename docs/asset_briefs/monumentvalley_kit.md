# Brief assets — Monument Valley (`Track19`, temă `monumentvalley`)

**Contractul complet pentru setul de assets (Blender).** Pe tiparul
`kyoto_kit.md`; regulile generale sunt în `docs/blender_export.md` și
`docs/style_bible.md` §4. Brief-ul pistei: `docs/track_briefs/monument_valley.md`
(§0.1 regula de artă, §2.0 scara față de cameră, §4 paleta, §5 assets, §9.0b
diorama acceptată).

**Fidelitatea față de planșă e criteriu de acceptare, nu inspirație** (§0.1
de mai jos). Fiecare desen are propria decupare și se livrează cu o
comparație alăturată.

| fișier | ce e | ce iei din el |
|---|---|---|
| `docs/track_briefs/img/monument_assets_v1/<nume>.png` | **decuparea piesei**, una pentru fiecare dintre cele 37 de desene, mărită 2× (`tools/blender/crop_monument_sheet.py`; montajul de control `_control.png`) | **referința de lucru a piesei:** silueta, numărul de elemente, proporțiile interne, culorile. Unele decupări au o fâșie din piesa vecină la margine: ignor-o |
| `docs/track_briefs/img/monument_plan/inventar_v02.jpg` | planșa întreagă (7 rânduri) | ordinea și ansamblul. **NU dimensiuni:** mașinuța de scară e minusculă față de case și uriașă față de Mittens |
| `docs/track_briefs/img/monument_plan/diorama_v02.jpg` | diorama acceptată | atmosfera, paleta în lumina de după-amiază, cum stau piesele împreună. **Nu stilul** (e pictată). Unde se contrazic, planșa câștigă |
| `docs/track_briefs/img/monument_plan/diorama_v02_iter1.jpg` | prima generare | doar densitatea stâncilor mici din vale |
| `docs/track_briefs/img/monument_plan/monument_plan.png` | planul real al pistei | unde stă fiecare piesă; nu o folosești la modelare |

**Corecturi decise de coordonator (suprascriu planșa):**
- **`cattle_guard` e PLAT**, nu o rampă în trepte ca pe planșă: o grilă de
  bare de oțel peste drum, la ≤ 0,15 m deasupra asfaltului, cu doi stâlpi
  scurți la capete (galben-negru);
- **fără text, cifre sau logo-uri** nicăieri (semnul are doar calul, mașinile
  n-au embleme, rucsacii n-au mărci);
- `west_mitten` și `east_mitten` sunt **oglindite**, nu identice: „degetul
  mare” e pe partea **dinspre drum** la fiecare (la West Mitten pe −X, la East
  Mitten pe +X, în coordonatele piesei). Pe planșă sunt aproape la fel;
- **cotele vin din tabelele de mai jos**, NU din planșă.

## 0. Regulile care nu se negociază

1. **Categoria** e `assets/models/monumentvalley/{rocks,plants,structures,buildings,props,vehicles,animals}/`.
   `dio_lib.export_glb` primește calea cu categorie
   (`"monumentvalley/rocks/west_mitten.glb"`).
2. **Asset nou = fișier nou.** Nu se suprascrie nimic din `rocks/`,
   `buildings/` (`water_tower.glb`, `windmill.glb` ale Dunelor rămân ale lor)
   sau din alte categorii de piste.
3. **Setul de piese nu atinge `scenes/` și `scripts/`.** Clasa `mv_sandstone`,
   `PROP_COLLISION`, tema, `DecorManual` și montarea în `Track19.tscn` sunt ale
   coordonatorului. Aici se livrează GLB + build script + preview + verify +
   inventar + comparații.
4. **Paletă: zero sloturi noi.** UV1 colapsat pe centrele sloturilor, AO copt
   în vertex colors, origine la bază (excepțiile sunt în tabel), scară metrică,
   **scala aplicată pe fiecare nod rădăcină** (memoria
   `scala-glb-neaplicata-la-radacina`). „Înainte” e −Z în Godot = **+Y în
   Blender**; fața bogată a clădirilor stă pe +Y și se **măsoară** pe GLB, nu se
   presupune (memoria `fata-casei-nu-e-plus-z`).
5. **Sloturile pe roluri** (tabelul de mai jos). Culoarea finală a stâncii o
   dă clasa `mv_sandstone`, nu slotul; nu încerca să prinzi roșul planșei cu
   alt slot.
6. **Piesele care primesc clasă la integrare se sparg la export în noduri cu un
   singur material** (memoria `clase-pe-piese-de-kit`). La stânci: `*_Rock`
   (peretele), `*_Scree` (grohotișul), `*_Cap` (calota). **Offsetul de origine
   se calculează o dată pe ansamblu**; verificarea e
   `verify_glb.py --origin=assembly`.
7. **Ce NU e geometrie:** rosturile fine, petele, textura de nisip vin din
   clasă. **Ce ESTE geometrie:** formele care schimbă silueta sau umbra, adică
   **coloanele verticale ale pereților** (fațete late de 1–3 m, cum se văd pe
   planșă), treptele grohotișului, bolovanii mari, calota în trepte. Regula:
   „se vede la 30 m din mașină ca formă?”.
8. **Stâncile se citesc pe trei etaje** (brief §0.1): grohotiș în trepte, cu
   bolovani, jos; perete vertical cu coloane la mijloc; calotă subțire și
   palidă sus. Un monolit fără cele trei etaje e o cutie.
9. **Fără text, fără cifre, fără logo-uri.**
10. **Primitive rotunde: setează `segments`** (6–12). Rezervorul turnului de
    apă, jgheabul morii, hoganul (8 laturi exact), roțile: 8–12.
11. **Verificarea e din fișier, nu din memorie:** `verify_glb.py` pe fiecare
    GLB, iar `preview_monument.py` randează **din GLB-urile exportate**.
    Verdictul setului e `bash tools/blender/verify_monumentvalley.sh` →
    `VERDICT KIT: OK` **și** comparațiile de fidelitate aprobate (§0.1).
    `verify` verde nu e livrare (memoria `harnasul-de-kit-nu-vede-forma-nici-culoarea`).
12. **Randările rulează pe GPU:** înainte de orice randare Blender/Godot cu
    fereastră, `mkdir D:/GameDev/.render_lock` (dacă eșuează, alt proces
    randează: așteaptă), `rmdir` imediat după.

### Sloturi pe roluri

Doar sloturi existente (`scripts/palette.gd`, constantele din `dio_lib.py`).

| rol | slot (în GLB) | clasă la integrare (nu o faci tu) |
|---|---|---|
| peretele de gresie (monoliți, mese, arc, turle) | `TILE_TERRACOTTA` 23, fețele din umbră `RUST_METAL` 10 | `mv_sandstone` pe `*_Rock` |
| grohotișul și bolovanii | `RUST_METAL` 10 + `LARCH_RUST` 27 în trepte alternante | `mv_sandstone` (sau nimic) pe `*_Scree`, decide coordonatorul |
| calota palidă | `SAND_LIGHT` 0 | — |
| salvia | smocurile `Sagebrush_Foliage`: `CACTUS_GREEN` 12 (toate); tulpinile `Sagebrush`: `WOOD` 9, frunze uscate `DRY_VEGETATION` 13 | o tentă gri-verde pe `Sagebrush_Foliage` (decide coordonatorul) |
| ienupărul (coroana) | `CACTUS_GREEN` 12 (oliv, decis pe randarea masurata) | — |
| trunchiuri, scânduri, stâlpi de lemn, gard, țarc | `WOOD` 9, fețele vechi/umbrite `LOG_DARK` 28 | — |
| yucca | `CACTUS_GREEN` 12 + `DRY_VEGETATION` 13 la vârfuri | — |
| *rabbitbrush* (florile) | `CAR_YELLOW` 16 (`--allow-car-slots=Rabbitbrush_Bloom`), tulpini `DRY_VEGETATION` 13 | — |
| tumbleweed | `LARCH_RUST` 27 (arama, ca decuparea) | — |
| semnul (rombul) | `CAR_YELLOW` 16 (`--allow-car-slots=Sign_Face`), calul `LOG_DARK` 28 | — |
| oțelul (grila, moara, cadrul turnului de apă) | `CONCRETE` 8, rugina `RUST_METAL` 10 | — |
| piatra postului de negoț, coșurile | `ROCK_LIGHT` 3 / `SAND_LIGHT` 0 | — |
| tencuiala și scândurile casei | `SAND_LIGHT` 0 / `CONCRETE` 8 | — |
| acoperișuri de tablă/carton | `ASPHALT_EDGE` 6 | — |
| hoganul (bușteni + pământ) | `WOOD` 9 + `SAND_MID` 1 pe acoperișul de pământ | — |
| pickup-ul ruginit | `RUST_METAL` 10, geamuri `VOLCANIC_BLACK` 20 | — |
| camionul de tur | `CAR_BLUE` 15 (`--allow-car-slots=Truck_Body`) | — |
| cal murg / roib | `WOOD` 9 + coama `LOG_DARK` 28 | — |
| cal pinto | `FOAM_WHITE` 22 + pete `WOOD` 9 | — |
| cal negru | `LOG_DARK` 28 / `VOLCANIC_BLACK` 20 | — |
| oaia | `FOAM_WHITE` 22, fața `LOG_DARK` 28 | — |
| corbul | `VOLCANIC_BLACK` 20 | — |
| turiștii | haine pe `CAR_BLUE` 15 / `CAR_RED` 14 / `SAND_MID` 1 (`--allow-car-slots=Tourist_Clothes`), piele `CORAL_SAND` 19 | — |
| goluri (ferestre, uși) | `VOLCANIC_BLACK` 20 | — |

Pista e **diurnă, lumină fixă**: nu se cer noduri `*_Glow`.

## 1. Inventar și contracte

Dimensiuni în metri. `h/l` = înălțime/lățime a siluetei pe decupare (se
verifică în comparație, ±15%). Triunghiurile se **raportează, fără plafon**
(CLAUDE.md); contează **materialele** (un nod = un material). „Față” = +Y în
Blender = −Z în Godot. **Modulele înlănțuibile** au capete identice, plane, la
±L/2 pe Y. **Cotele de contract (goluri) se măsoară ca GOL** (proiecție pe plan,
memoria `cota-de-contract-se-masoara-ca-gol`).

### 1.1 Monoliții — `build_monument_rocks.py`

**Scara e decizie, nu defect** (brief §2.0): Mittens reali au ~300 m; aici au
45 m, ca să intre întregi în cadru de pe coamă. În pistă, conul mare de
grohotiș e **teren** (`TerrainPeak`, rază 28 m, ~15 m înalt). GLB-ul aduce
**turnul plus o fustă de grohotiș de 0–8 m (inaltimea maxima lângă perete)** cu bolovani, care ascunde
îmbinarea cu terenul. **Originea e la baza turnului** (pe cota la care
`TerrainPeak` se termină), nu la baza conului.

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `rocks/west_mitten.glb` **(pilot)** | turn **30 m** înalt, amprentă ~24 × 13 m; „degetul” **26 m**, lat 4–5 m, la **3 m** de corp pe −X; fusta de grohotiș până la raza ~22 m, înaltă ≤ 8 m lângă perete, scăzând la 0 la margine | ~1,1 (turn) | corp cu ~24 coloane late (2–4 m) pe tot conturul (patru fețe, colțuri rotunjite), peretele se îngustează ~15% spre vârf, calotă în 2 trepte; **degetul e o piesă separată, cu gol de cer între ea și corp** (silueta e reperul pistei: fără gol, testul de 3 secunde pică). Noduri `Mitten_Rock`, `Mitten_Scree`, `Mitten_Cap` |
| `rocks/east_mitten.glb` | turn **27 m**, amprentă ~22 × 12 m; deget **23 m** pe **+X** | ~1,1 | oglinda lui West Mitten, cu altă împărțire a coloanelor (să nu fie copie) |
| `rocks/merrick_butte.glb` | turn **24 m**, amprentă ~30 × 18 m, fără deget | ~0,8 | bloc lat, calotă plată în trepte, 2–3 contraforturi pe fața lungă |
| `rocks/mesa_wall_module.glb` | **12 m** lung (Y), **14 m** înalt, 6 m adânc, grohotiș la picior ≤ 3 m | ~1,2 | perete de masă înlănțuibil: **capete plane identice la ±6 m pe Y**, 4–5 coloane, calota continuă. Pentru trecătoarea E și cornișa F |
| `rocks/sandstone_arch.glb` | ~**24 m** lat, **13 m** înalt; **golul ≥ 14 m lățime și ≥ 7,5 m înălțime liberă, măsurat ca GOL** pe gabaritul caroseriei (h 2 m) | ~0,55 | arc de gresie peste drum (E′): două picioare masive, puntea groasă de 3–4 m, calota palidă. **Consumator:** `_build_arch` azi încarcă `rocks/rock_arch.glb` fix — integrarea îl face cheie de temă (coordonatorul) |

### 1.2 Stânci mici și grohotiș — `build_monument_rocks_small.py`

Se înmulțesc pe tur (zeci de exemplare), deci **siluete distincte între ele**
și fără fețe inutile. Origine la bază.

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `rocks/butte_small_a.glb` | **14 m**, amprentă ~10 m | ~1,1 | bloc cu calotă, pe con de grohotiș propriu (aici conul e în GLB) |
| `rocks/butte_small_b.glb` | **18 m**, amprentă ~7 m | ~1,8 | turlă îngustă pe con |
| `rocks/butte_small_c.glb` | **12 m**, amprentă ~11 m | ~0,9 | bloc în trepte (2–3 etaje care se strâng) |
| `rocks/rock_fin.glb` | **12 m** înalt, 4 m lat, 2,5 m gros | ~3 | aripă subțire, verticală |
| `rocks/hoodoo.glb` | **7 m** | ~2,5 | coloană cu „cap” de piatră mai lat, pe un con mic |
| `rocks/talus_boulders_a.glb` | ~**4 × 4 × 2,5 m** | ~0,6 | grup de 5–7 bolovani colțuroși; un singur nod `Talus_Scree` |
| `rocks/talus_boulders_b.glb` | ~**5 × 4 × 2 m** | ~0,4 | grup mai lat și mai jos, 8–10 bolovani |

### 1.3 Plante — `build_monument_plants.py`

Un nod per material (trunchi / coroană / flori). Coliziunea (`trunk` la
ienupăr, `none` la restul) e a coordonatorului. Plantele mici se vor pune pe
MultiMesh, deci **un singur mesh compact**, fără noduri inutile.

| fișier | cote | h/l | contract |
|---|---|---:|---|
12–16 smocuri mici, verticale, în formă de flacără, pe tulpini lemnoase ramificate (WOOD 9, nod `Sagebrush`); toate smocurile pe CACTUS_GREEN 12 în nodul `Sagebrush_Foliage` (clasă la integrare: tentă gri-verde); dom cu goluri |
| `plants/juniper.glb` | **4 m** înalt, ~4,5 m lat | ~0,9 | trunchi răsucit care se ramifică în 3–4 brațe, coroane în ciorchini turtiți, cu goluri (nu glob) |
| `plants/yucca.glb` | **1,2 m** | ~1,1 | rozetă de 25–35 de frunze lanceolate pe un ciot scurt |
| `plants/rabbitbrush.glb` | **1,2 m**, 1,4 m lat | ~0,85 | tufă de tulpini cu **ciorchini galbeni** deasupra; nod `Rabbitbrush_Bloom` |
| `plants/tumbleweed.glb` | **Ø 0,9 m**, aproximativ sferic | ~0,9 | rețea deschisă de crenguțe (nu bilă plină): ~15–20 de bucle subțiri. **Consumator nou:** `HaboobHazard` |

### 1.4 Drum, gard și semne — `build_monument_road.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `props/cattle_guard.glb` | **14 m** lat (pe X, peste drum), **2,4 m** lung (Y), bare la **≤ 0,15 m** deasupra cotei 0; stâlpi de capăt 1,2 m la x = ±7,3 | — | **PLAT** (corectura de mai sus): 10–12 bare de oțel pe Y, ramă, doi stâlpi galben-negru. **Fără coliziune la integrare** (se trece prin ea); doar vizual + sunet |
| `props/open_range_sign.glb` | stâlp **2,6 m**, romb 0,9 m | — | romb galben cu **silueta unui cal** în relief (nod separat), fără text. `Sign_Face`, `Sign_Post` |
| `structures/telegraph_pole.glb` | **8 m**, traversă 2 m la 7,2 m | — | stâlp de lemn, traversă, 2–3 izolatori; **firele nu sunt în GLB** (le face codul, între stâlpi) |
| `structures/wire_fence.glb` | segment **4 m** (Y), 1,2 m înalt | — | 2 stâlpi la capete + 3 fire; **înlănțuibil**, capete la ±2 m |
| `structures/windmill_pump.glb` | turn **9 m**, rotor Ø 2,5 m; jgheab rotund Ø 3 m, 0,6 m | ~2 | moară cu rotor de pale și coadă, pe turn de oțel; jgheab de oțel alături. Rotorul pe nod separat `Windmill_Rotor`, cu pivotul la centru (se poate învârti) |
| `structures/water_tower.glb` | **11 m**, rezervor Ø 3,2 m | ~2,4 | rezervor de lemn cu doage și capac conic pe turn de lemn în X; scară |
| `structures/corral.glb` | **10 × 8 m**, 1,5 m | — | țarc de lemn, 3 bare orizontale, o poartă |
| `structures/shade_ramada.glb` | **5 × 4 × 3 m** | ~0,7 | 4–6 stâlpi, acoperiș de bârne și crengi (cu goluri), masă cu bănci dedesubt |

### 1.5 Clădiri — `build_monument_buildings.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `buildings/trading_post.glb` | **12 × 9 m**, 5 m la streașină, coș 7,5 m | ~0,55 | piatră, prispă de lemn pe fața **+Y** cu 4–5 stâlpi, 2 ferestre și ușă pe față, acoperiș plat cu parapet, coș de piatră. **Fără firmă și fără text** |
| `buildings/homestead_house.glb` | **9 × 7 m**, 5,5 m la coamă | ~0,7 | casă modulară de scânduri, acoperiș în două ape, prispă mică, coș |
| `buildings/hogan.glb` | **Ø 7 m**, 3,5 m | ~0,5 | **exact 8 laturi** din bușteni orizontali, acoperiș de pământ în dom turtit, ușa spre +Y (spre est la integrare). **Locuință, nu loc de ceremonie**: fără nimic decorat |

### 1.6 Vehicule și oameni — `build_monument_vehicles.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `vehicles/pickup_old.glb` | **5,2 × 2,0 × 1,9 m** | — | pickup rotunjit anii '50, ruginit, roți cu `segments` 10; fără embleme |
| `vehicles/tour_truck.glb` | **5,5 × 2,2 × 2,6 m** | — | 4×4 cu bancheta deschisă și cadru de bare; albastru; fără embleme, fără număr |
| `props/tourist_group.glb` | 4 oameni, **1,6–1,8 m**, o singură piesă | — | doi cu aparate foto ridicate, rucsaci; low-poly, fără fețe detaliate, fără mărci |

### 1.7 Animale — `build_monument_animals.py`

**v1 statice** (tiparul Serengeti, gnu/zebra statice): două poze ca noduri
separate în același GLB, `Pose_Stand` și `Pose_Walk`, ca integrarea să aleagă.
Riggingul pentru traversare (`SlidingHazard`) e o etapă ulterioară, pe
pipeline-ul vacii (PR #270), dacă verdictul la volan îl cere.

| fișier | cote | contract |
|---|---|---|
| `animals/horse_bay.glb` | **2,4 m** lung, greabăn 1,6 m | murg cu coamă și coadă negre, picioare negre jos; **fără șa și fără călăreț** (precedentul `baraat_horse` avea) |
| `animals/horse_pinto.glb` | idem | alb cu pete mari maro (petele în geometrie/sloturi, ca pe decupare) |
| `animals/horse_black.glb` | idem | negru |
| `animals/sheep.glb` | **1,3 m** lung | oaie albă, fața și picioarele închise |
| `animals/raven.glb` | anvergură **1,0 m** | corb cu aripile deschise; nod `Raven_Wings` separat |

### 1.8 Fundal — `build_monument_horizon.py`

`rocks/horizon_mesas.glb` cu noduri copii directe ale rădăcinii, **volume
închise lizibile din orice azimut, origine la bază** (consumator
`Track._build_horizon`): `EagleMesa_A` (~90 × 30 × 28 m), `BrighamsTomb_A`
(~40 × 25 × 35 m), `Stagecoach_A` (~50 × 20 × 30 m), `KingOnThrone_A` (~30 ×
20 × 32 m), `Spires_A` (3 turle de 25–35 m, numele nu apar în joc),
`FarMesa_A`, `FarMesa_B` (benzi joase, ~150 × 20 × 15 m). Cele trei etaje se
păstrează și aici, dar cu fațete mai mari. Fără coliziune; `cast_shadow` OFF la
integrare.

### 1.9 Ce NU se generează

Conurile mari de grohotiș sub Mittens (teren), pereții trecătorii (`TrackCliffs`
din cod; `mesa_wall_module` doar completează), drumurile, albia G2, dunele
scurtăturii, firele de telegraf, haboob-ul (shader) și praful (particule).

## 2. Livrabile

| fișier | ce |
|---|---|
| `tools/blender/build_monument_{rocks,rocks_small,plants,road,buildings,vehicles,animals,horizon}.py` | rulabile headless: `D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- build_monument_rocks.py`. **Docstring-ul fiecărei funcții de piesă conține lista de elemente** (§0.1 pasul 1), scrisă înainte de primul vertex. Vocabularul comun (perete cu coloane, grohotiș în trepte, calotă) e în `monument_shapes.py` |
| `tools/blender/preview_monument.py` | `--compare <nume>` (decupare ↔ randare), `--views <nume>` (4 azimuturi), `--sheet <val> a,b,c` |
| `tools/blender/verify_monumentvalley.sh` | o rulare, un verdict, excepțiile declarate cu motiv |
| `docs/asset_briefs/monumentvalley_inventory.md` | cote măsurate, tri, noduri, tabele de fidelitate, contracte înghețate (golul arcului), **„Stare la oprire”** |
| `docs/asset_briefs/img/monumentvalley_fidelity/<nume>.png` | comparațiile alăturate |

## 0.1 Fidelitatea față de planșă — criteriul de acceptare

Planșa e sursa de **formă și culoare**; tabelele de aici sunt sursa de **cote
și de contracte de cod**.

1. **Deschide decuparea** și scrie în docstring **lista de elemente** cu
   numere: câte coloane pe fața lungă, câte trepte de grohotiș, câți bolovani,
   ce iese din contur. Înainte de primul vertex.
2. **Modelează după listă**, la cotele din tabel. În rest, proporțiile interne
   ale desenului se păstrează.
3. **Randează comparația** (`preview_monument.py --compare <nume>`): decuparea
   în stânga, randarea GLB-ului în dreapta, aceeași înălțime în pixeli, 3/4 din
   față, lumină de zi neutră, fundal `#C8C8C8`, **culoare reală**: fiecare față
   pe culoarea slotului ei din atlas (recuperat din UV), nodurile `*_Rock` pe
   hex-ul clasei `mv_sandstone` (`#B8552E`).
4. **Verifică pe imagine, element cu element**, nu doar numărând (memoria
   `numaratoarea-trece-amplasarea-nu`): poziția, forma, `h/l` (±15%), ordinea
   luminozităților, ce iese din contur. Tabel în inventar: element | pe planșă
   | în GLB | OK/abatere.
5. **Maximum 3 runde pe piesă.** Dacă tot nu seamănă, se raportează abaterea
   cinstit în inventar, nu se declară „trece”.
6. **Piesa se acceptă doar după ce comparația e văzută** de coordonator.

## 3. Ordinea de lucru (valuri de ~3 constructori; fiecare cu verify + comparații + commit)

0. **Pilot:** harnasul (`monument_shapes.py`, `preview_monument.py`,
   `verify_monumentvalley.sh`) + `west_mitten`. Coordonatorul judecă
   comparația înainte de valul 1: Mittens e reperul pistei.
1. **Valul 1:**
   - **mv-a** — `east_mitten`, `merrick_butte`, `mesa_wall_module`,
     `sandstone_arch` (golul arcului se măsoară ÎNAINTE de orice altceva);
   - **mv-b** — stâncile mici (§1.2) și plantele (§1.3);
   - **mv-c** — drum, gard și semne (§1.4).
2. **Valul 2:**
   - **mv-d** — clădirile (§1.5) și vehiculele/oamenii (§1.6);
   - **mv-e** — animalele (§1.7);
   - **mv-f** — fundalul (§1.8).

Lucrează în worktree-ul indicat în prompt (ramura `monument/kit-<grupa>`). Nu
comite pe `main`, nu folosi `git stash` (e comun tuturor worktree-urilor), nu
face push.
