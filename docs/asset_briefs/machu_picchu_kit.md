# Brief assets — Machu Picchu (`Track15`, temă `machupicchu`)

**Contractul complet pentru instanța de assets (Blender MCP).** Nu presupune
că ai citit altceva: tot ce e nevoie e aici, plus cele trei fișiere de
referință de mai jos. Regulile generale ale pipeline-ului sunt în
`docs/blender_export.md` și `docs/style_bible.md` §4; șabloanele de lucru
sunt kiturile anterioare: `docs/asset_briefs/serengeti_inventory.md`,
`tools/blender/build_serengeti_*.py`, `verify_serengeti.sh`,
`preview_serengeti.py`.

Referințe vizuale (sursa de adevăr pentru siluete și culori):

| fișier | ce e |
|---|---|
| `docs/track_briefs/img/machu_picchu_assets_v1.jpeg` | **planșa de inventar** (12 rânduri, numele de fișier scrise sub fiecare piesă) |
| `docs/track_briefs/img/machu_picchu_v3.jpeg` | diorama de referință (stil, proporții, cele trei accente) |
| `docs/track_briefs/img/machu_picchu_plan.png` | planul real al pistei, adnotat (unde stă fiecare piesă) |
| `docs/track_briefs/machu_picchu.md` | brief-ul pistei; §4 paleta, §5 assets, §2 POI-urile |

## 0. Regulile care nu se negociază

1. **Categoria** e `assets/models/machupicchu/{structures,buildings,rocks,plants,animals,vehicles,props}/`.
   `dio_lib.export_glb` primește calea cu categorie
   (`"machupicchu/structures/rope_bridge.glb"`) și își face folderul.
2. **Asset nou = fișier nou.** Nu se suprascrie niciun GLB pe care Godot îl
   încarcă deja (`props/cow.glb`, `vehicles/train.glb`, `vehicles/bus.fbx`
   rămân neatinse; se exportă fișiere noi lângă ele).
3. **Instanța de assets nu atinge `scenes/` și `scripts/`.** Integrarea în
   `Track15.tscn`, clasele de textură noi (`inca_stone` etc.) și temele sunt
   ale instanței de gameplay. Aici se livrează GLB + build script + preview +
   verify + inventar.
4. **Paletă: zero sloturi noi.** UV1 colapsat pe centrele sloturilor din
   atlas (`slot_u`), AO copt în vertex colors, origine la bază, scară metrică,
   −Z Godot = +Y Blender e „înainte". Sloturile legale pentru pista asta:

   | rol | slot |
   |---|---|
   | granit în soare (ziduri, trepte, pavaj, turnuri) | `MARBLE_GREY` 29 |
   | granit în umbră, rosturi adânci, nișe | `ROCK_LIGHT` 3 / `ROCK_DARK` 4 |
   | iarbă de terasă, mușchi pe piatră | `CACTUS_GREEN` 12 |
   | pădure de nori (coroane, ferigi, bambus) | `TROPICAL_GREEN` 21 |
   | umbră adâncă de pădure, lemn întunecat | `LOG_DARK` 28 |
   | scoarța roșie de queñual | `LARCH_RUST` 27 |
   | pământ ocru (serpentine, cornișă) | `SAND_SHADOW` 2 / `SAND_MID` 1 |
   | frânghie de iarbă, paie de acoperiș | `DRY_VEGETATION` 13 |
   | bârne, scânduri, stâlpi | `WOOD_WEATHERED` 9 |
   | alb (nor, lână de lamă, guler de condor, dungi de autobuz) | `FOAM_WHITE` 22 |
   | negru (condor, cauciucuri, geamuri) | `VOLCANIC_BLACK` 20 / `ASPHALT` 5 |
   | trenul PeruRail, autobuzul (accente saturate, **excepție declarată**) | `CAR_BLUE` 15, `CAR_YELLOW` 16 |
   | capul condorului, corturi | `KERB_RED` 7, `TILE_TERRACOTTA` 23 |
   | orhidee (accent rar, **excepție declarată**, ca flamingii) | `FLAMINGO_PINK` 31 |

   Excepțiile (CAR_* pe vehicule, 31 pe orhidee) se declară în
   `verify_machupicchu.sh` cu `--allow-car-slots=<Nod>` / `--allow-slots=31`.
5. **Rosturile de piatră NU sunt geometrie.** Pe planșă zidurile sunt din
   cărămizi modelate; la noi rosturile vin dintr-o clasă de textură
   triplanară aplicată la integrare. Un zid e o cutie cu bevel, 2–4 umflături
   mari de piatră și fețele din umbră retag-uite pe `ROCK_LIGHT`. Sub 300 tri,
   fiindcă se multiplică de 90 de ori.
6. **Piesele care primesc clasă la integrare se sparg la export în obiecte de
   un singur material** (memoria `clase-pe-piese-de-kit`): casa = `House_Stone`
   + `House_Thatch`; fântâna = `Basin` + `Water`; podul = `Deck` + `Cables` +
   `Rails`. Un nod = un material potențial, deci nu mai multe decât e nevoie.
7. **Suprafețele pe care se merge au vârfuri partajate** (fără plăci
   independente — pragurile de 15 cm sunt ziduri pentru fizica întreagă).
   Aici: tablierul podului, treptele scărilor, pragul porților.
8. **Verificarea e din fișier, nu din memorie:** `verify_glb.py` pe fiecare
   GLB cu bugetul din tabel, `preview_machupicchu.py` randează planșele **din
   GLB-urile exportate** în `docs/asset_briefs/img/machupicchu_<grup>.png`.
   Verdictul kitului e `bash tools/blender/verify_machupicchu.sh` → `VERDICT KIT: OK`.

## 1. Inventar și contracte

Bugetele sunt plafoane. Dimensiunile sunt în metri. „Origine" = `finish(origin=...)`.

### 1.1 Hero — `build_machupicchu_hero.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `structures/rope_bridge.glb` | tablier **35,0 × 11,0** m (X × Z Blender: X = lungimea, Y Blender = lățimea), plăci de 0,15 grosime | 3.000 | **Piesa cea mai importantă.** Trei noduri: `Deck` (scânduri transversale, un singur mesh, vârfuri partajate, **o secțiune la fiecare 0,5 m pe lungime** — 70 de secțiuni — fiindcă `RopeBridgeHazard` deformează mesh-ul în shader după doi parametri: săgeata și unghiul lateral; plăcile trebuie să aibă rezoluție pe lungime, nu pe lățime), `Cables` (4 cabluri de iarbă împletită: două sub marginile tablierului, două balustrade la 1,0 m deasupra, tuburi cu 6 segmente, aceleași secțiuni la 0,5 m, **drepte** în GLB — sagul îl dă codul), `Rails` (legături verticale de frânghie între cablul de sus și cel de jos, la fiecare 1,0 m, pe ambele părți). **Originea: centrul tablierului, la fața de sus a scândurilor** (podul stă în scenă la `(13.71, −20, −155)`, capetele la x = ±17,12). Verify cu `--origin=assembly`. Sloturi: scânduri `WOOD_WEATHERED`, cabluri și legături `DRY_VEGETATION`. Fără turnuri în fișierul ăsta. |
| `structures/bridge_tower_a.glb`, `bridge_tower_b.glb` | 4 × 4 la bază, **5,0** înalt, ușor trapezoidale | 600 fiecare | Turnuri de ancorare din piatră potrivită, cu două găuri prin care trec cablurile la 1,0 și la 0,1 m. `a` cu o nișă trapezoidală spre pod, `b` cu o treaptă. Origine la bază, centrată. Sloturi `MARBLE_GREY` / `ROCK_LIGHT`. Se așază la integrare la x = ±17,5 față de pod. |
| `rocks/huayna_picchu.glb` | **30 m** înalt, bază ~90 m diametru, vârf ascuțit ușor aplecat | 2.500 | Vârful-flanc din brief §2.0. **Trei etaje de culoare, ca retag pe fețe, nu ca volum:** coroană de granit `MARBLE_GREY` (treimea de sus, fețe mari, tăioase), flanc `TROPICAL_GREEN` + `LOG_DARK` în umbră, bază `CACTUS_GREEN` cu 3–4 terase mici (trepte de 2 m, vârfuri partajate). Baza se îngroapă 3 m în teren (geometria coboară la −3 sub origine; `--origin=assembly`). Se vede de la 50 m din mașină, deci fațetele mari; de la 250 m de la Poarta Soarelui, deci silueta contează. `rock()` din Builder cu `taper` mare, nu `mesa()` (memoria: mesa la 40 m dă butoaie). |
| `structures/inti_punku.glb` | două încăperi de 5 × 4 × 5 m înalte, **14,0 m liber între ele** pe axa drumului | 1.800 | Poarta Soarelui. Drumul la POI C are semi-lățime 6,5 (13 m lat), deci poarta **nu are buiandrug**: sunt două camere de piatră fără acoperiș, cu nișe trapezoidale, care flanchează drumul, plus o treaptă lată de granit între ele (prag de 0,1 m max, vârfuri partajate, muchii teșite). Originea pe axa drumului, la bază (`--origin=assembly`, ca `crater_gap` de la Serengeti). Drumul trece pe **Y Blender**. |
| `structures/main_gate.glb` | deschidere trapezoidală **8,4 m la bază, 7,4 m sus, 6,0 m liber sub buiandrug**; tocul 1,2 m gros, 7,5 m total înalt | 1.500 | Poarta Principală (POI H). Drumul acolo are semi-lățime 4 (8 m), deci 8,4 liber. Buiandrug monolit, toc de granit, un rest de zid de 3 m de fiecare parte. Originea pe axa drumului, la bază (`--origin=assembly`). Drumul pe Y Blender. |
| `structures/inca_bridge_ledge.glb` | perete de stâncă **30 m** lung × **12 m** înalt cu o cornișă de 1,5 m tăiată în el la bază, **gol de 4,25 m** la mijloc | 2.500 | Cornișa Podului Incaș (POI H): peretele stă pe DREAPTA drumului (în sensul de mers), cornișa e vizuală (drumul real e terenul). Golul e liber în GLB: bârnele sunt piesa mobilă a hazardului. Origine pe axa golului, la baza cornișei (`--origin=assembly`). Sloturi `ROCK_LIGHT` / `ROCK_DARK`, mușchi `CACTUS_GREEN` pe pervazuri. |
| `structures/inca_bridge_beams.glb` | 3 bârne de **4,6 × 0,3 × 0,25** m, la 0,5 m una de alta, un singur nod `Beams` | 120 | Traveea scoasă pe ciclu (`LiftBridgeHazard`, 6 s din 28). Origine la baza bârnelor, centrată pe gol. `WOOD_WEATHERED`. |
| `structures/sun_temple.glb` | zid curb (semicerc r 4 m, 3,5 m înalt) pe o stâncă de 6 × 6 × 2 m, o fereastră | 1.200 | Templul Soarelui. `MARBLE_GREY` pe zid, `ROCK_LIGHT` pe stâncă. Origine la bază. |
| `structures/intihuatana.glb` | movilă cu 3 trepte (6 m diametru, 1,5 m) + piatra-ceas 1,2 m | 500 | Vârfuri partajate pe trepte (e lângă grilă, mașinile o pot atinge). |
| `structures/three_windows.glb` | zid de **10 × 0,9 × 4** m cu 3 ferestre trapezoidale (1,0 jos / 0,8 sus / 1,4 înalte) | 600 | Silueta piaței, pe stânga grilei. Origine la bază, centrată. |

### 1.2 Kitul de cetate — `build_machupicchu_citadel.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `structures/inca_wall_a.glb` | **4,0 × 0,8 × 2,5** m | 300 | Zidul de terasă / de cetate standard. **Capetele sunt plane, exact la x = ±2,0**, ca să se înlănțuie fără rost vizibil. Vârf ușor rotunjit (bevel 0,08). Regula 0.5: fără cărămizi. |
| `structures/inca_wall_b.glb` | **6,0 × 0,8 × 2,5** m, 2 nișe trapezoidale | 300 | Nișele sunt adâncituri de 0,3 m (retag `ROCK_DARK` în fund). Capete la x = ±3,0. |
| `structures/inca_wall_c.glb` | **2,0 × 0,8 × 2,5** m, capăt de zid cu colț rotunjit | 200 | Terminație / colț. |
| `structures/inca_stair_a.glb` | 10 trepte, **rise 2,5**, run 3,0, lățime 2,0 | 300 | Scară încastrată în zidul de terasă. Trepte cu vârfuri partajate (contrafață verticală + calcă). Origine la baza primei trepte, urcă spre +Y Blender. |
| `structures/inca_stair_b.glb` | 20 de trepte, rise 5,0 | 500 | Aceeași, dublă. |
| `buildings/inca_house_a.glb` | **6 × 4** m, ziduri 2,5, frontoane până la 4,5, acoperiș de paie în două ape | 700 | Noduri `House_Stone` + `House_Thatch`. Ușă trapezoidală, o fereastră. |
| `buildings/inca_house_b.glb` | 6 × 4, **fără acoperiș**, frontoane rupte la înălțimi diferite | 500 | Ruina — un singur nod. |
| `buildings/guardhouse.glb` | **7 × 4** m, trei ziduri (deschisă spre −Y Blender), acoperiș de paie abrupt (55°), streașină 0,6 | 800 | Casa Paznicului (POI C, 0,33 — cadrul pozei clasice). `House_Stone` + `House_Thatch`. |
| `structures/fountain_basin.glb` | bazin **1,5 × 1,0 × 0,6** m, gură de apă pe o latură | 200 | Noduri `Basin` (`MARBLE_GREY`) + `Water` (un quad plan la 0,5 m, `REEF_SHALLOW` — primește shader-ul de apă la integrare). 16 se pun în trepte pe POI D. |
| `structures/water_channel.glb` | **4,0 × 0,4 × 0,3** m, jgheab | 100 | Capete plane la ±2,0. |
| `structures/trail_marker.glb` | piatră în picioare 0,5 × 0,3 × 1,2 m, o dungă incizată | 80 | — |
| `structures/rope_rail.glb` | 2 stâlpi de lemn de 1,0 m la 4,0 m distanță + o frânghie cu săgeată de 0,15 | 200 | Parapet de creastă, doar la ace (brief §2.0). `WOOD_WEATHERED` + `DRY_VEGETATION`. Capete la x = ±2,0. |

### 1.3 Pădurea de nori și gara — `build_machupicchu_forest.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `plants/polylepis_a.glb` | **4 m**, trunchi răsucit, coroană mică | 1.000 | Queñual: trunchi `LARCH_RUST` cu 2–3 „foi" de scoarță desprinse (plăci subțiri `LARCH_RUST` / `ROCK_DARK`), coroană `TROPICAL_GREEN` din 4–6 bulgări turtiți. `taper_sweep` pe o cale sinuoasă. |
| `plants/polylepis_b.glb` | **7 m**, două trunchiuri din aceeași bază | 1.400 | Idem. |
| `plants/tree_fern.glb` | **4 m**, trunchi fibros + 8 frunze în evantai | 900 | `leaf_vfold` pentru frunze, `LOG_DARK` pe trunchi. |
| `plants/bromeliad.glb` | rozetă **0,6** m | 200 | `TROPICAL_GREEN`, vârfuri `CACTUS_GREEN`. Pentru pereții stâncoși (se așază înclinat la integrare). |
| `plants/orchid_cluster.glb` | **0,4** m, 5 flori pe tije | 200 | Flori `FLAMINGO_PINK` (31, excepție declarată), frunze `TROPICAL_GREEN`. Singura plantă saturată. |
| `rocks/moss_boulder_a/b/c.glb` | **1 / 2,5 / 4** m | 200 / 250 / 300 | `boulder()`; fețele de sus retag `CACTUS_GREEN` (mușchi), restul `MARBLE_GREY` / `ROCK_LIGHT`. |
| `plants/bamboo_clump.glb` | **5 m**, 7–9 tulpini | 600 | `TROPICAL_GREEN` tulpini, noduri `DRY_VEGETATION`. Pe mal (POI E/F). |
| `props/tent_a.glb`, `tent_b.glb` | cort dom **2,2 × 2,2 × 1,4** m | 300 fiecare | `a` `TILE_TERRACOTTA` (portocaliu stins), `b` `CACTUS_GREEN`. Fermoar ca linie `LOG_DARK`. |
| `props/backpack_pile.glb` | grămadă **1,0 × 0,8 × 0,7** m, 4 rucsacuri | 400 | `PAINTED_METAL`, `RUST_METAL`, `LOG_DARK`, `CACTUS_GREEN` — fără CAR_*. |

### 1.4 Animale — `build_machupicchu_animals.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `animals/llama.glb`, `llama_b.glb`, `llama_c.glb` | **1,7 m** la cap, 1,1 la greabăn, 1,4 lung | 400 fiecare | **Import, nu Builder** (memoria `asset-animat-pipeline`): sursa e `D:\GameDev\downloaded assets\Ultimate Animated Animals - July 2021-…\glTF\Alpaca.gltf` (Quaternius, CC0, animat) — rețeta din `build_cow_animated.py`: se păstrează doar mesh-ul parentat pe armatură, `remove_doubles` înainte de `Decimate` (memoria `decimare-mesh-importat`), acțiunile păstrate **`Idle`, `Eating`, `Walk`, `Gallop`** (exact numele astea: `SlidingHazard._hook_animation` le caută; `Eating` e pășunatul de pe planșă), NLA stash cu `mute=True`, `export_glb(..., animations=True)`, `save_blend(compress=True)`. Rotația/scara rămân pe nodul armaturii. AO doar gradient vertical. Origine la sol, −Z Godot înainte. Trei exporturi din același build cu alte sloturi pe blană: `llama` `FOAM_WHITE`, `llama_b` `SAND_MID`, `llama_c` `LOG_DARK`; botul și copitele `ROCK_DARK`. Dacă alpaca nu ține proporțiile (gât prea scurt), a doua sursă e `Farm Animal Pack-glb\Llama.glb` (static) cu rig-ul vacii re-parentat. |
| `animals/condor.glb` | așezat **1,2 m** înalt, pe o stâncă de 1,5 × 1,2 × 0,8; anvergură **3,0 m** deschis | 900 | **Rig în cod** (rețeta țestoasei/elefantului: `mesh_islands`, `make_armature`, `weight_ramp`, `pose_rotate`, `stash_actions`). Oase: `Body`, `Head`, `WingL`, `WingR`. Două acțiuni: **`Open`** (aripile se desfac de la strâns la 3 m în 0,8 s, apoi țin 1,2 s; 48 de cadre la 24 fps) și **`Close`** (invers). Corp `VOLCANIC_BLACK`, guler `FOAM_WHITE`, cap `KERB_RED`, cioc `SAND_LIGHT`, stânca `ROCK_LIGHT`. Origine la baza stâncii. `--origin=assembly`. Codul pentru `Area3D` la 25 m e al integrării. |

### 1.5 Vehicule — `build_machupicchu_vehicles.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `vehicles/consettur_bus.glb` | **3,6 lat × 3,0 înalt × 6,0 lung** | 1.200 | `BusHazard` ia AABB-ul din model (`body_size` e doar placeholder-ul). Autobuz scurt de turiști, galben cu bandă albă, geamuri mari `ASPHALT`, roți `VOLCANIC_BLACK`. Sloturi `CAR_YELLOW` + `FOAM_WHITE` (excepție `--allow-car-slots=Consettur_Bus`). **Înainte = −Z Godot = +Y Blender.** Origine la sol, centrată. Întâi încearcă reuse: importă `assets/models/vehicles/bus.fbx` (autobuzul din garaj), re-mapează sloturile, scalează la cotele de mai sus; dacă proporțiile nu țin (prea lung), Builder de la zero. **Nu suprascrie `bus.fbx`.** |
| `vehicles/perurail_train.glb` | locomotivă 2,8 × 3,6 × 9 m, vagoane 2,8 × 3,6 × 8 m | 3.000 | `TrainHazard` extrage nodurile **după nume**: `Train_Loco`, `Train_Tender`, `Train_Wagon` (vezi `train_hazard.gd:38-41` și `build_baikal_railway.py` pentru tiparul). PeruRail n-are tender: `Train_Tender` e un vagon scurt de bagaje (5 m), ca nodul să existe. Locomotivă diesel `CAR_BLUE` cu bandă `CAR_YELLOW`, vagon cu **ferestre în tavan** (`ASPHALT` pe geamuri), boghiuri `VOLCANIC_BLACK`. Înainte = −Z Godot. Origine la nivelul șinei. Excepție `--allow-car-slots=Train_Loco,Train_Tender,Train_Wagon`. Ecartamentul și poziția pe boghiuri: copiază-le din `train.glb` (importă-l și măsoară), altfel garnitura plutește sau se înfige în șina procedurală. |

### 1.6 Fundal — `build_machupicchu_horizon.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `rocks/gorge_far_wall.glb` | arc de **200 m** lung × **80 m** înalt, concav spre drum | 5.000 | Peretele opus al defileului, la 200–250 m, în ceață. Benzi orizontale de verde (`TROPICAL_GREEN` / `LOG_DARK` / `CACTUS_GREEN`) ca retag, două fețe de granit `MARBLE_GREY`. `--origin=assembly` (base_axis). `cast_shadow` OFF la integrare. |
| `rocks/machu_picchu_mountain.glb` | **60 m** înalt, 150 m bază, umăr rotunjit | 1.500 | Muntele de sud, siluetă la 150+ m; Poarta Soarelui stă pe umărul lui. **Fără terase** (nu se vede de aproape, planșa le are degeaba). `--origin=assembly`. |

### 1.7 Ce NU se generează

- `cloud_bank` — norul e pânză billboard cu textură cu cădere continuă, din cod
  (memoria `particule-muchia-nu-numarul`, `CloudRiseHazard`). Nu e GLB.
- `chevron_post` — reuse `assets/models/chongqing/props/chevron_post.glb`.
- `cow.glb` — rămâne placeholder-ul lamelor până intră `llama.glb`.
- treptele Drumului Incaș, tunelul, terasele ca relief — sunt teren
  (`custom_step_ranges`, `TerrainPeak`), nu assets.

## 2. Livrabile

| fișier | ce |
|---|---|
| `tools/blender/build_machupicchu_{hero,citadel,forest,animals,vehicles,horizon}.py` | build-urile, rulabile headless: `D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- build_machupicchu_hero.py` |
| `tools/blender/preview_machupicchu.py` | planșele de control **din GLB-urile exportate**, în `docs/asset_briefs/img/machupicchu_<grup>.png` (camera cu `clip_end` 5000 pentru fundal; `hide_render` pe tot ce nu e în listă) |
| `tools/blender/verify_machupicchu.sh` | o rulare, un verdict, excepțiile declarate cu motiv |
| `docs/asset_briefs/machu_picchu_inventory.md` | inventarul final: tri per piesă, abaterile de la planșă cu motiv, originile care nu sunt la bază, contractele înghețate în geometrie, ce nu e făcut (modelul `serengeti_inventory.md`) |
| `assets/blender/*.blend` | sursele (`save_blend`, comprimat pe cele animate) |

## 3. Ordinea de lucru (valuri, fiecare cu verify + preview + commit)

1. **Hero:** podul primul (singurul cu risc tehnic: rezoluția pe lungime
   pentru shader), apoi turnurile, Huayna Picchu, porțile, ledge-ul, sacrele.
2. **Cetate:** zidul `a` primul și verificat că se înlănțuie (două instanțe cap
   la cap în preview, fără rost), apoi restul kitului.
3. **Pădure + gară + fundal.**
4. **Animale + vehicule** (importurile: lama, autobuzul, trenul; rig-ul condorului).

Lucrează într-un worktree separat pe o ramură nouă (`feat/machupicchu-kit`),
rulează `godot --headless --path . --import` o dată după `git worktree add`,
commit per val, PR la final. Nu comite niciodată pe `main`.
