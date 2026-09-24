# Brief assets — Fiordland (`Track16`, temă `fiordland`)

**Contractul complet pentru instanța de assets (Blender MCP).** Nu presupune
că ai citit altceva: tot ce trebuie e aici, plus fișierele de referință de mai
jos. Regulile generale ale pipeline-ului sunt în `docs/blender_export.md` și
`docs/style_bible.md` §4. Șabloanele de lucru sunt kitul Machu Picchu:
`docs/asset_briefs/machu_picchu_kit.md`, `tools/blender/build_machupicchu_*.py`,
`verify_machupicchu.sh`, `preview_machupicchu.py`,
`docs/asset_briefs/machu_picchu_inventory.md`.

Referințe vizuale:

| fișier | ce e | ce iei din el |
|---|---|---|
| `docs/track_briefs/img/fiordland_assets_v1.jpg` | **planșa de inventar** (12 rânduri, numele de fișier sub fiecare piesă) | **siluete și culori. NU dimensiuni:** mașina de scară e desenată la fel de mică în toate rândurile, deci cotele de pe planșă sunt greșite (avionul iese ~37 m, autocarul ~25 m). Cotele sunt DOAR cele din tabelele de mai jos |
| `docs/track_briefs/img/fiordland_diorama_v03.jpg` | diorama de referință | stilul (fețe plate, apă negru-verde, pădure închisă), proporțiile relative, cele trei accente |
| `docs/track_briefs/img/fiordland_plan.png` | planul real al pistei, adnotat | unde stă fiecare piesă |
| `docs/track_briefs/fiordland.md` | brief-ul pistei | §4 paleta, §5 assets, **§5.6 trecerea de contracte** (de ce unele piese NU se fac), §9.1 verdictul pe planșă |

## 0. Regulile care nu se negociază

1. **Categoria** e `assets/models/fiordland/{structures,buildings,rocks,plants,animals,vehicles,props,effects}/`.
   `dio_lib.export_glb` primește calea cu categorie
   (`"fiordland/rocks/stirling_ledge.glb"`) și își face folderul.
2. **Asset nou = fișier nou.** Nu se suprascrie niciun GLB pe care Godot îl
   încarcă deja: `effects/avalanche_boulders.glb`, `vehicles/bus.fbx`,
   `vehicles/open_bus.glb` și `rocks/mountain_peak.glb` rămân neatinse. Se
   exportă fișiere noi.
3. **Instanța de assets nu atinge `scenes/` și `scripts/`.** Integrarea în
   `Track16.tscn`, clasele de textură noi (`wet_gneiss`, `moss_carpet`),
   intrările din `PROP_COLLISION` și tema sunt ale instanței de gameplay. Aici
   se livrează GLB + build script + preview + verify + inventar.
4. **Paletă: zero sloturi noi.** UV1 colapsat pe centrele sloturilor din
   atlas (`slot_u`), AO copt în vertex colors, origine la bază (excepțiile
   sunt scrise în tabel), scară metrică. „Înainte" e −Z în Godot, adică +Y în
   Blender. Numele sunt cele din `dio_lib.py`:

   | rol | slot |
   |---|---|
   | gneis ud în lumină (pereți, stânci, bolovani) | `MARBLE_GREY` 29 |
   | dungile ude verticale, umbra din nișe, geamuri | `VOLCANIC_BLACK` 20 |
   | coronament de fag, mușchi pe piatră | `TROPICAL_GREEN` 21 |
   | trunchiuri negre, umbră adâncă de pădure, lemn putred | `LOG_DARK` 28 |
   | tussock, mușchi uscat, iarbă oliv | `CACTUS_GREEN` 12 |
   | pietriș, grohotiș | `SAND_SHADOW` 2 |
   | scânduri, bârne, cheiul de lemn, cabane | `WOOD` 9 |
   | beton, acoperișuri de tablă, containere | `CONCRETE` 8 / `PAINTED` 11 |
   | alb (zăpadă, vaporașe, burta pinguinului, avion) | `FOAM_WHITE` 22 |
   | flori de rata (accent rar) | `KERB_RED` 7 |
   | sub aripile kea (accentul viu al pistei) | `LAVA_ORANGE` 30 |
   | avion, caiace, creasta tawaki (accente saturate, **excepție declarată**) | `CAR_RED` 14, `CAR_BLUE` 15, `CAR_YELLOW` 16 |

   **Interzis:** `ROCK_DARK` 4 (iese maro pe granit, memoria
   `rock-dark-nu-pe-bazalt`), `ROCK_LIGHT` 3 (nu e în paleta pistei). Excepțiile
   CAR_* se declară în `verify_fiordland.sh` cu `--allow-car-slots=<Nod>`.
5. **Fagul se multiplică de 200+ ori.** Sub 300 tri pe exemplar, fără excepție.
   Pe planșă fagii sunt „brocoli" pe trunchi brun gros, iar asta e exact ce NU
   vrem. Vezi §1.4.
6. **Piesele care primesc clasă la integrare se sparg la export în obiecte cu
   un singur material** (memoria `clase-pe-piese-de-kit`). Un nod înseamnă un
   material potențial: peretele Stirling = `Wall` + `Moss`; casa = `House_Wall`
   + `House_Roof`; fagul = `Trunk` + `Crown`.
7. **Apa nu se modelează niciodată.** Perdelele de cascadă (Stirling, Bowen,
   cele 5 de ploaie, torentul), spray-ul, bazinele și marea le construiește
   `WaterfallVisual` în cod. Un GLB cu apă ar dubla-o.
8. **Verificarea e din fișier, nu din memorie:** `verify_glb.py` pe fiecare
   GLB cu bugetul din tabel, iar `preview_fiordland.py` randează planșele
   **din GLB-urile exportate** în `docs/asset_briefs/img/fiordland_<grup>.png`.
   **Fiecare planșă are în cadru o cutie de 4,0 × 1,8 × 1,5 m (mașina de
   referință)**, fiindcă planșa ChatGPT a arătat cât de ușor scapă scara.
   Verdictul kitului e `bash tools/blender/verify_fiordland.sh` →
   `VERDICT KIT: OK`.

## 1. Inventar și contracte

Bugetele sunt plafoane. Dimensiunile sunt în metri. „Origine" înseamnă
`finish(origin=...)`. Drumul trece pe **Y Blender**, iar „dreapta" în sensul
de mers e **+X Blender**.

### 1.1 Stâncile-hero — `build_fiordland_rocks.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `rocks/stirling_ledge.glb` | perete **40 m** lung (Y) × **10 m** adânc (+X) × **30 m** înalt; nișă concavă de **30 m** lungime, **4 m** adâncime în perete și **7 m** înălțime liberă; surplombul cu **buza la +14,0 m**, ieșit **9 m** spre −X din fața peretelui | 3.000 | **Piesa cea mai importantă a kitului, și planșa a ratat-o** (bloc cu copaci pe vârf, fără surplomb, fără prag). Peretele stă pe DREAPTA drumului (+X). Fața peretelui e planul X = 0, iar originea e la baza feței, centrată pe Y (`--origin=assembly`). **Buza surplombului e la +14,0 m** pentru că perdeaua din cod (`WaterfallHazard.visual_height` = 14 m pe `StirlingFalls`) cade de acolo: dacă buza e mai sus, apa pornește din aer; dacă e mai jos, iese prin rocă. Buza se întinde pe cei 30 m ai nișei (lungimea perdelei, `length` = 30) și iese 9 m peste drum (3 m de prag + 6 m de perdea). Sub buză, **nișa** e locul pragului uscat: fundul ei (nod `Shelf`, 3 m lat × 30 m, fața de sus **la cota originii**) e separat de restul, cu `MARBLE_GREY` + mușchi `TROPICAL_GREEN`. Cota finală a pragului (+0 sau +1,5 m cu rampe) se decide la integrare, cu vârfuri partajate (memoria `suprafete-din-placi-plane`); de aceea `Shelf` e nod separat și se poate scoate. Tavanul nișei trebuie să lase **≥ 5 m liber** deasupra `Shelf` (o mașină pe suspensie plus camera de 10 m sus și 12,5 m în spate nu trebuie să taie roca: verifică în preview cu cutia de referință pe `Shelf`). Deasupra buzei, peretele urcă la 30 m, cu un platou plat în vârf (pe el se pun fagi la integrare; **fără copaci în GLB**). Dungi verticale ude: fețe retag-uite pe `VOLCANIC_BLACK` în benzi de 0,5–1,5 m care coboară de pe buză, nu pete. Noduri: `Wall`, `Overhang`, `Shelf`, `Moss`. Fără apă (regula 0.7). **Nu** modela partea de sub drum (cele 30 m până la mare): e rapa din teren (`custom_ravines`). |
| `rocks/torrent_chute.glb` | masă de stâncă **24 m** lungă (Y) × **8 m** adâncă (+X) × **16 m** înaltă; jgheabul are gura de **20 m** lățime pe Y, buza la **+14,0 m** | 1.500 | Torentul din scurtătură (`TorrentCycle`, perdea `length` 20, `visual_height` 14, pe banda de 6,4 m). Aceeași logică ca la Stirling: buza jgheabului la +14 m, ieșită **3 m** spre −X peste marginea benzii, pentru că apa cade din ea peste drumul de pământ. Deasupra buzei se vede marginea lacului suspendat: o cuvetă de 6 × 4 m, goală (apa o face codul, dacă vrea), cu fund `VOLCANIC_BLACK`. Originea e la baza feței dinspre bandă, centrată pe gură (`--origin=assembly`). Planșa a desenat apa în jgheab, dar aici **nu se desenează**: jgheabul e o albie de rocă cu fundul `VOLCANIC_BLACK` (ud) și marginile `MARBLE_GREY`. Noduri: `Rock`, `Moss`. Coliziune `none` (§5.6): e deasupra benzii, nu pe ea. |
| `rocks/chasm_rock.glb` | **6 × 4 × 2,5** m | 600 | Marmitele din Chasm: o lespede rotunjită cu 2–3 gropi cilindrice (0,8–1,5 m diametru, 0,6–1,0 m adâncime), fundul gropilor `VOLCANIC_BLACK`, restul `MARBLE_GREY` cu mușchi pe muchia de sus. Silueta de pe planșă e bună. |
| `rocks/guard_rock.glb` | **1,2 × 0,8 × 0,6** m | 80 | Bolovan scund pentru marginea cornișei, rar (cornișa n-are parapet: câte unul la 30–50 m). `MARBLE_GREY`, mușchi sus. |
| `rocks/scree_slab.glb` | **8 × 5 × 1,2** m | 300 | Placă de grohotiș pe panta de sub portal: o pantă joasă de pietre mici, **nu** con (planșa l-a desenat grămadă). Fețe `SAND_SHADOW` + `MARBLE_GREY`. Coliziune `none`, e în afara drumului. |

### 1.2 Fundalul — `build_fiordland_horizon.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `rocks/fiordland_horizon.glb` | un fișier, noduri numite: `FarWall_A`, `FarWall_B` **180 × 45 × 70** m; `SnowRidge_A`, `SnowRidge_B` **90 m** înalte, bază ~120 m | 5.000 total | Consumatorul e `Track._build_horizon`: ia nodurile **după nume** (`picks` din `horizon_rings`), le așază pe inele la 150–300 m de centroid, le scalează ×0,85–1,4 și le dă un **yaw ALEATOR**. De aceea planșa greșește: **„flat-backed" nu merge**, o placă văzută din spate dă o fațadă goală. Fiecare nod e un **volum închis**, lizibil din orice azimut: `FarWall_*` e o creastă lungă și îngustă cu pereți abrupți pe ambele fețe, cu benzi orizontale de pădure (`LOG_DARK` / `TROPICAL_GREEN`), fețe de gneis `MARBLE_GREY` și **2 fire albe verticale** (`FOAM_WHITE`, 1,5 m late) pe fiecare față lungă. `SnowRidge_*` sunt vârfuri cu calotă `FOAM_WHITE` pe treimea de sus, apoi `MARBLE_GREY`, apoi pădure la bază (trei etaje, memoria `munte-flanc-nu-fundal`). Originea fiecărui nod e la bază, centrată. Fațete mari: se văd de la 200 m prin ceață. `cast_shadow` OFF se pune la integrare. **`CloudBank_A` NU se face:** norul e pânză billboard din cod (precedentul Machu Picchu, memoria `particule-muchia-nu-numarul`). |

### 1.3 Cheiul și satul — `build_fiordland_village.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `structures/wharf.glb` | **20 × 4 × 2** m, 4 babale | 400 | Marginea de piatră a cheiului de start. Blocuri `MARBLE_GREY`, babale `VOLCANIC_BLACK`. Capete plane la y = ±10, ca să se înlănțuie. Pontonul de lemn **nu** se face: reuse `structures/wooden_pier.glb`. |
| `buildings/cafe_shed.glb` | **5 × 4** m, pereți 2,8, acoperiș de tablă într-o apă până la 3,6 | 400 | Cafeneaua de pe chei. `House_Wall` `WOOD` (închis prin AO), `House_Roof` `PAINTED` gri. Ușă și o fereastră mare `VOLCANIC_BLACK`, **fără ferestre luminate** (planșa le are portocalii; nu avem emisiv în atlas). |
| `buildings/lodge.glb` | **16 × 7** m, pereți 3,0, acoperiș în două ape până la 6,0 | 700 | Lodge-ul lung de lângă pista de avioane. Aceleași noduri și sloturi ca `cafe_shed`. Un singur nivel cu lucarnă, nu două etaje (planșa exagerează). |
| `structures/heli_pad.glb` | disc **12 m** diametru × 0,3 m | 200 | Heliportul gol. `CONCRETE`, cercul și H-ul din fețe retag-uite `FOAM_WHITE` (geometrie, nu textură: H-ul e din 3 dreptunghiuri tăiate în capac). Coliziune `none`. |
| `props/luggage_container.glb` | **6,1 × 2,4 × 2,6** m | 150 | Container de 20 ft, `PAINTED` gri, nervuri pe laturi ca retag `VOLCANIC_BLACK`, **nu** geometrie. |
| `props/road_sign_blank.glb` | panou **1,6 × 1,0** pe 2 stâlpi, 2,6 m înalt total | 100 | Panou verde gol, `CACTUS_GREEN`, stâlpi `CONCRETE`. **Fără text, fără glif.** |
| `props/traffic_light_pole.glb` | stâlp **5,5 m** + braț 2,5 m + carcasă 0,5 × 0,4 × 1,2 m | 250 | **Doar stâlpul și carcasa. Lămpile NU** (le face `HazardLamp`, care le aprinde prin `visible`). În carcasă sunt 2 alveole goale `VOLCANIC_BLACK` (0,3 m diametru, la 0,35 m una de alta, pe verticală), iar lămpile se centrează în ele la integrare. Originea la baza stâlpului. **Planșa a desenat lămpile; aici nu se desenează.** |
| `props/snow_pole.glb` | **2,0 m**, 0,06 m diametru | 40 | Jalon de zăpadă. `FOAM_WHITE` cu vârful de 0,3 m `KERB_RED`. |

### 1.4 Pădurea — `build_fiordland_forest.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `plants/beech_a.glb`, `beech_b.glb`, `beech_c.glb` | **8 / 11 / 14 m** înălțime | **< 300** fiecare | Fag argintiu (*Nothofagus menziesii*). **Trunchi NEGRU (`LOG_DARK`) și SUBȚIRE**: 0,25–0,45 m la bază, ușor aplecat sau cu o cotitură, gol pe prima jumătate de înălțime. **Coroana e 3–4 volume turtite în ETAJE** (discuri neregulate, de 2–4 ori mai late decât înalte), la înălțimi diferite, pe ramuri scurte. Cerul se vede printre ele. **Nu** o bilă, **nu** brocoli: planșa a greșit exact aici. `TROPICAL_GREEN` pe fețele de sus ale volumelor, `LOG_DARK` pe cele de jos (umbra sub etaj). Noduri `Trunk` + `Crown`. Test în preview: silueta de la 30 m trebuie să arate goluri între etaje; dacă e un singur contur plin, e greșit. |
| `plants/beech_dead.glb` | **9 m** | 250 | Fag uscat: trunchi și 4–6 crengi goale `LOG_DARK`, 2–3 petice de mușchi `CACTUS_GREEN`. Silueta de pe planșă e bună. |
| `plants/rata_tree.glb` | **5 m** | 400 | Rata în floare: trunchi `LOG_DARK`, coroană `TROPICAL_GREEN` din 4–5 volume, cu 8–12 ciorchini `KERB_RED` pe fețele de sus. Accent rar (3–4 pe tur). |
| `plants/tussock_clump.glb` | **0,8 m** înalt, 1,0 m diametru | 150 | Smoc de tussock: 10–14 lame `CACTUS_GREEN`, vârfuri `SAND_SHADOW`. Pe platoul de lângă portal. |
| `props/stump.glb` | **1,0 m** diametru × 0,8 m | 150 | Ciot cu mușchi: `LOG_DARK`, capac `CACTUS_GREEN`, 3 rădăcini. Pe el stau papagalii la POI D. |
| `props/driftwood.glb` | **4 m** lung | 150 | Trunchi decolorat pe mal, `WOOD`. |
| `structures/chasm_bridge_rail.glb` | **40 m** lung (Y); două balustrade la **X = ±5,8** | 600 | **Doar balustradele și grinzile laterale. Tablia NU** (o face drumul: `custom_step_ranges` 0,406–0,424 dă vibrația și gripul, iar drumul acolo are semi-lățimea 5,5). Stâlpi la 4 m, două rânduri de mână curentă, grindă laterală de 0,4 × 0,3 m sub fiecare balustradă. `WOOD`. Noduri `Rail_L`, `Rail_R`. Originea pe axa drumului, la cota tabliei, centrată pe Y (`--origin=assembly`). Coliziune `none` (§5.6). |

### 1.5 Avalanșa de copaci — `build_fiordland_avalanche.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `effects/tree_avalanche.glb` | 4 noduri: `Boulder_A`, `Boulder_B`, `Boulder_C`, `Boulder_D` | 300 fiecare | **Contractul e al `AvalancheHazard`, nu al planșei.** Hazardul ia nodurile **după nume** (exact `Boulder_A..D`), face din ele **9 bucăți** (lista `BOULDERS` din `avalanche_hazard.gd`), scalează fiecare nod ca **max(X, Z) = 1,0–2,8 m** și le **rostogolește** în jurul centrului, cu o **sferă** de coliziune de 0,82 × raza. Consecințe: (1) **originea în CENTRUL volumului**, nu la bază (`--origin=center`); (2) **fiecare nod e compact, cu raport de laturi ≤ 1,5 : 1**. Un buștean lung de 4 m (cum a desenat planșa) ar fi scalat la 2,8 m și s-ar rostogoli ca o elice, cu sfera de coliziune lovind în gol. Deci fiecare formă e un **ghem**: un bolovan `MARBLE_GREY` prins în 2–4 trunchiuri scurte rupte (`LOG_DARK`), cu rădăcini și mușchi `TROPICAL_GREEN`. Cele 4 forme diferă prin raportul rocă/lemn (A: mai mult rocă, D: mai mult lemn). Modelul e dimensionat liber (hazardul îl rescalează), dar ține cele 4 forme la scară comună, ~2 m. Calea se trece din pistă prin cheia nouă de spec a lui `_build_avalanche`, livrată de PR-ul `fix/fiord-kit-hooks`. |

### 1.6 Vehicule — `build_fiordland_vehicles.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `vehicles/coach_fiordland.glb` | **3,0 lat × 3,2 înalt × 8,5 lung** | 1.200 | Autocarul din tunelul Homer. **Cotele sunt ale corpului de joc**, nu ale unui autocar real de 12 m: `TunnelSignalHazard` are `bus_width` 3,0 și `bus_length` 8,5, calibrate pe banda de 9 m (`bus_lane_offset` −2,4), iar `BusHazard` ia AABB-ul din model. Un model mai lat sau mai lung schimbă gameplay-ul (ProbeRace), deci **nu depăși nicio cotă**. Întâi reuse: importă `assets/models/vehicles/bus.fbx`, re-mapează sloturile pe `FOAM_WHITE` (caroserie) + `TROPICAL_GREEN` (bandă și fusta de jos) + `VOLCANIC_BLACK` (geamuri, roți), scalează la cote. Farurile sunt fețe `FOAM_WHITE` pe botul din față. **Înainte = −Z Godot = +Y Blender**, origine la sol, centrată. Nod `Coach`. **Nu suprascrie `bus.fbx`.** Se montează prin exportul nou `bus_model` din `TunnelSignalHazard` (PR `fix/fiord-kit-hooks`). Planșa l-a desenat verde-lime: culorile de aici câștigă. |
| `vehicles/bush_plane.glb` | anvergură **8,0 m**, lungime **7,3 m**, înălțime 2,7 m | 900 | Monomotor cu aripa sus (tip Cessna, fără nume și fără înmatriculare). `FOAM_WHITE` + dungi `CAR_RED` pe fuzelaj și la vârfurile aripilor, geamuri `VOLCANIC_BLACK`, elice cu disc gri `PAINTED` (nu pale separate), **trenul coborât** (aterizează). `PathMover` în aer (`stick_to_ground=false`): **originea în centrul fuzelajului** (pe curbă), `--origin=center`, înainte −Z Godot. Excepție `--allow-car-slots=Plane`. Silueta de pe planșă e bună, **scara nu** (acolo iese ~37 m anvergură). |
| `vehicles/cruise_boat.glb` | **14 × 4,5 × 5** m | 1.500 | Vaporaș alb cu punte deschisă sus, `FOAM_WHITE`, geamuri `VOLCANIC_BLACK`, puntea `WOOD`. **Fără dungă roșie** (planșa o are; diorama v0.3 a scos-o). `PathMover` pe apă: **originea la linia de plutire**, centrată, înainte −Z Godot. Carena coboară 1,2 m sub origine. **Nu** `tall_ship.glb`. |
| `props/kayak_a.glb`, `kayak_b.glb` | **3,6 × 0,6 × 0,35** m | 100 fiecare | `kayak_a` `CAR_BLUE`, `kayak_b` `CAR_YELLOW` (paleta brief-ului §4; planșa are roșu și galben). Cockpit `VOLCANIC_BLACK`. Excepție `--allow-car-slots=Kayak`. |

### 1.7 Animale — `build_fiordland_animals.py`

| fișier | cote | tri | contract |
|---|---|---:|---|
| `animals/kea.glb` | **0,5 m** înălțime așezat; anvergură **1,0 m** deschis | 700 | **Rig în cod**, rețeta condorului de la Machu Picchu (`build_machupicchu_animals.py`: `mesh_islands`, `make_armature`, `weight_ramp`, `pose_rotate`, `stash_actions`). Oase `Body`, `Head`, `WingL`, `WingR`. Acțiuni **`Idle`** (legănat ușor al capului, 48 de cadre) și **`Open`** (aripile se desfac în 0,6 s și țin 1,0 s, 40 de cadre la 24 fps). Numele exacte, pentru că `PathMover.animation` le caută. Spate și aripi `CACTUS_GREEN` (oliv), **dedesubtul aripilor `LAVA_ORANGE`** (se vede doar în `Open`), cioc curbat `VOLCANIC_BLACK`. Originea la gheare. Ambele poze de pe planșă sunt bune ca siluetă. |
| `animals/penguin_tawaki.glb` | **0,75 m** înalt (jumătate din înălțimea unei mașini) | 300 | Pinguinul cu creastă din Fiordland, static, în picioare. Spate și cap `VOLCANIC_BLACK`, burtă `FOAM_WHITE`, **o sprânceană galbenă de o parte și de alta a capului, până la ceafă** (`CAR_YELLOW`; asta îl face tawaki, iar pe planșă abia se vede), cioc `KERB_RED` închis. Excepție `--allow-car-slots=Penguin`. Coliziune `none` la integrare. |

### 1.8 Ce NU se generează

Fiecare rând are un consumator care face deja piesa sau un asset existent
(brief-ul pistei §5.6):

| piesă | de ce | ce se folosește |
|---|---|---|
| perdelele (Stirling, Bowen, 5 de ploaie, torentul), spray, bazine | `WaterfallVisual` le face în cod, cu un shader partajat | — |
| kickerul Bowen | `TrackChannel` cu `jump` (`KickerBowen`) | — |
| portalurile, tubul și galeria tunelului Homer | `Track._build_tunnels` din nodul `SemaforTunel` | — |
| lămpile semaforului | `HazardLamp` | stâlpul din §1.3 |
| Mitre Peak, masivul tunelului | `TerrainPeak` (teren regenerat) | — |
| tablia podului din Chasm | drumul, prin `custom_step_ranges` | balustrada din §1.4 |
| `CloudBank_A` | pânză billboard din cod | — |
| `fern_clump_a/b` | reuse | `plants/fern_cluster.glb` |
| foca | reuse, recolorată `LOG_DARK` | `baikal/props/nerpa_seal.glb` |
| feriga arborescentă | reuse | `machupicchu/plants/tree_fern.glb` |
| bolovanii cu mușchi | reuse + clasa `moss_carpet` la integrare | `machupicchu/rocks/moss_boulder_a/b/c.glb` |
| panoul chevron | reuse | `signs/chevron_sign.glb` |
| pontonul | reuse | `structures/wooden_pier.glb` |
| `reference_car` | e doar scara de pe planșă | cutia de 4 × 1,8 × 1,5 din preview |

## 2. Livrabile

| fișier | ce |
|---|---|
| `tools/blender/build_fiordland_{rocks,horizon,village,forest,avalanche,vehicles,animals}.py` | build-urile, rulabile headless: `D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- build_fiordland_rocks.py` |
| `tools/blender/preview_fiordland.py` | planșele de control **din GLB-urile exportate**, în `docs/asset_briefs/img/fiordland_<grup>.png`, **fiecare cu cutia de referință de 4 × 1,8 × 1,5 m în cadru** (camera cu `clip_end` 5000 pentru fundal; `hide_render` pe tot ce nu e în listă, memoria `blender-preview-cub-implicit`) |
| `tools/blender/verify_fiordland.sh` | o rulare, un verdict, excepțiile declarate cu motiv |
| `docs/asset_briefs/fiordland_inventory.md` | inventarul final: tri per piesă, **cotele măsurate din GLB** față de cele din tabel, abaterile de la planșă cu motiv, originile care nu sunt la bază, contractele înghețate în geometrie (buza la +14, `Boulder_A..D`, 3,0 × 8,5), ce nu e făcut (modelul `machu_picchu_inventory.md`) |
| `assets/blender/*.blend` | sursele (`save_blend`, comprimat pe cele animate) |

## 3. Ordinea de lucru (valuri, fiecare cu verify + preview + commit)

1. **Stâncile-hero:** `stirling_ledge` primul, fiindcă e singura piesă pe care
   planșa n-o dă corect și e judecată de aproape, din mașină, prin perdea. În
   preview: vedere laterală cu buza la +14 m cotată și cutia de referință pe
   `Shelf` sub tavan. Apoi `torrent_chute`, restul stâncilor.
2. **Fagii:** `beech_a` primul, verificat pe siluetă (golurile dintre etaje)
   și pe buget (< 300) **înainte** de `b`/`c`. Apoi restul pădurii.
3. **Avalanșa + vehiculele** (contracte de cod: nume de noduri, cote de corp,
   origini).
4. **Satul, animalele, fundalul.**

Lucrează într-un worktree separat pe o ramură nouă (`feat/fiordland-kit`),
rulează `godot --headless --path . --import` o dată după `git worktree add`,
commit per val, PR la final. Nu comite niciodată pe `main`. Nu folosi
`git stash` (e comun tuturor worktree-urilor).
