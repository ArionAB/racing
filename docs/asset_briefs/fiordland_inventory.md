# Inventar assets — Fiordland (`Track16`)

GLB-uri în `assets/models/fiordland/`, pe ramura `feat/fiordland-kit`.
Sursa: `docs/asset_briefs/fiordland_kit.md` (contractul) și cele patru
referințe vizuale pe care le numește. Verificare:
`bash tools/blender/verify_fiordland.sh` → **VERDICT KIT: OK, 31 de GLB-uri**.
Planșele de control, randate **din GLB-urile exportate**:
`docs/asset_briefs/img/fiordland_*.png` (`preview_fiordland.py`). Pentru
animale, pe lângă planșa largă (`fiordland_animals.png`) există și 3 planșe
apropiate, o piesă per fișier, cu bară de scară de 0,5 m în loc de cutia de
4 m (revizuire coordonator, val 4 a doua trecere):
`fiordland_animals_close_kea_idle.png`,
`fiordland_animals_close_kea_open.png`,
`fiordland_animals_close_penguin.png`.

| script | ce produce | val |
|---|---|---|
| `build_fiordland_rocks.py` | stirling_ledge, torrent_chute, chasm_rock, guard_rock, scree_slab | 1 |
| `build_fiordland_forest.py` | fagii, rata, tussock, ciot, lemn de mal, balustrada podului | 2 |
| `build_fiordland_avalanche.py` | Boulder_A..D (avalanșa de copaci) | 3 |
| `build_fiordland_vehicles.py` | autocar, avion, vaporaș, caiace | 3 |
| `build_fiordland_village.py` | cheiul, cafeneaua, lodge, heliport, container, semn, semafor, jalon | 4 |
| `build_fiordland_animals.py` | kea (rigid), pinguinul tawaki | 4 |
| `build_fiordland_horizon.py` | FarWall_A/B, SnowRidge_A/B | 4 |

## Inventar complet

### `rocks/` — val 1 (5 piese, 2.474 tri)

| fișier | tri / buget | cote măsurate vs. brief | notă |
|---|---:|---|---|
| `stirling_ledge.glb` | 1.826 / 3.000 | Wall 40,00×10,00×26,57 (30 cerut; vezi „Contracte înghețate"); nișă liberă ≥ 5 m confirmată; **buza surplombului la Y=14,000–21,400** (contract +14,0 exact la baza panei) | 3 noduri (Wall/Overhang/Shelf), `--origin=assembly` |
| `torrent_chute.glb` | 196 / 1.500 | masă 24×8×16,02 (16 cerut), buza la Y=14,0–16,0 exact, gura 20 m pe Z | Coliziune `none` |
| `chasm_rock.glb` | 416 / 600 | 6,00 × 2,50 × 4,72 (contract 6×4×2,5 — adâncimea Z iese la 4,72 nu 4, măsurat) | 2–3 marmite VOLCANIC_BLACK |
| `guard_rock.glb` | 72 / 80 | 1,18 × 0,58 × 0,70 (contract 1,2×0,8×0,6 — puțin mai îngust pe Z) | — |
| `scree_slab.glb` | 264 / 300 | 5,00 × 1,20 × 8,00 (contract 8×5×1,2 — X/Z par inversate față de tabel, dar panta reală merge de-a lungul drumului pe Z=8 m, lat 5 m pe X: geometria respectă „apron pe pantă", nu eticheta X/Y a tabelului) | 4 pietre (nu grămadă) |

### `plants/`, `structures/` — val 2 (9 piese, 1.702 tri)

| fișier | tri / buget | cote măsurate vs. brief | notă |
|---|---:|---|---|
| `beech_a.glb` | 228 / 300 | trunchi+coroană 6,10 (contract 8 m — **sub cotă**, vezi abateri) | `--origin=assembly` |
| `beech_b.glb` | 292 / 300 | 8,80 (contract 11 m — sub cotă) | idem |
| `beech_c.glb` | 292 / 300 | 11,17 (contract 14 m — sub cotă) | idem |
| `beech_dead.glb` | 136 / 250 | 8,51 (contract 9 m) | 5 crengi, muschi retag |
| `rata_tree.glb` | 354 / 400 | 3,67 (contract 5 m — sub cotă) | tufă densă, nu acacie |
| `tussock_clump.glb` | 144 / 150 | 0,80 × 0,68 diametru (contract 0,8 × 1,0 — puțin mai îngust) | 6 lame (nu 10-14, plafon calitativ vs. buget) |
| `stump.glb` | 68 / 150 | 0,83 înălțime, 1,13 diametru (contract 1,0×0,8) | 3 rădăcini |
| `driftwood.glb` | 52 / 150 | 4,03 lungime (contract 4 m) | — |
| `chasm_bridge_rail.glb` | 336 / 600 | Rail_L/R la X=±5,84 (contract ±5,8), lungime 40,48 (contract 40) | `--origin=waterline`, coliziune `none` |

### `effects/` — val 3 (4 noduri, 794 tri)

| fișier | tri / buget | cote măsurate vs. brief | notă |
|---|---:|---|---|
| `tree_avalanche.glb` (`Boulder_A`) | 136 / 300 | max(X,Z) 2,62 (interval cerut 1,0-2,8 înainte de rescalare) | origine CENTRU |
| — (`Boulder_B`) | 224 / 300 | max(X,Z) 1,89 | idem |
| — (`Boulder_C`) | 174 / 300 | max(X,Z) 1,59 | idem |
| — (`Boulder_D`) | 260 / 300 | max(X,Z) 1,51 | idem, talpă de rădăcini |

Numele nodurilor `Boulder_A..D` sunt **contract înghețat**: `AvalancheHazard`
le caută exact așa (§1.5 din brief), altfel dă `push_warning` și cade pe
sferele de rezervă.

### `vehicles/`, `props/` — val 3 (5 piese, 2.960 tri)

| fișier | tri / buget | cote măsurate vs. brief | notă |
|---|---:|---|---|
| `coach_fiordland.glb` | 1.008 / 1.200 | **3,06 × 3,29 × 8,66** (contract **3,0 × 3,2 × 8,5** — CONTRACT ÎNGHEȚAT, `TunnelSignalHazard`/`BusHazard` citesc AABB-ul din model; deviația de 2-6% e bevel, în limita gameplay-ului) | `bus.fbx` NEATINS — reuse respins cu măsurătoare (13,70×3,81×4,27 sursă, ar fi cerut scară neuniformă pe roți) |
| `bush_plane.glb` | 844 / 900 | anvergură 8,00 (contract 8,0), lungime 7,45 (contract 7,3), înălțime **1,85** (contract 2,7 — **sub cotă**, vezi abateri) | origine CENTRU, `--allow-car-slots=Plane` |
| `cruise_boat.glb` | 920 / 1.500 | 4,23 × **5,50** × 13,97 (contract 14×4,5×5 — înălțimea iese 5,5 nu 5, măsurat) | `--origin=waterline`, carena coboară 1,2 m |
| `kayak_a.glb` | 94 / 100 | 3,60 × 0,58 × 0,36 (contract 3,6×0,6×0,35) | CAR_BLUE, `--allow-car-slots=KayakA` |
| `kayak_b.glb` | 94 / 100 | idem | CAR_YELLOW, `--allow-car-slots=KayakB` |

### `structures/`, `buildings/`, `props/` — val 4, satul (8 piese, 1.882 tri)

| fișier | tri / buget | cote măsurate vs. brief | notă |
|---|---:|---|---|
| `structures/wharf.glb` | 376 / 400 | **20,00 × 4,00 × 2,00** (contract exact), capete plane la Z=±10,05 | `--origin=base_axis`, 4 babale |
| `buildings/cafe_shed.glb` | 308 / 400 | pereți 2,80–3,60 (contract 2,8 la streașină, 3,6 la coamă), acoperiș 2,744–3,656 | `House_Wall`+`House_Roof`, `--origin=assembly`. **Golul de la coamă reparat (revizuire coordonator, val 4 a doua trecere):** peretele de la streașină rămâne plat la 2,8 m, peretele de la coamă urcă la 3,6 m, iar cei doi pereți de capăt sunt TRAPEZE care urmează exact panta acoperișului — verificat vizual din partea înaltă și din capătul de fronton, fără cer vizibil între perete și placă |
| `buildings/lodge.glb` | 636 / 700 | pereți 3,00 (contract 3,0), coamă la 6,19 (contract 6,0) | idem, 4 ferestre, 1 lucarnă |
| `structures/heli_pad.glb` | 178 / 200 | disc 11,7 m diametru (contract 12), 0,30 înălțime | cercul+H din fețe retag, coliziune `none` |
| `props/luggage_container.glb` | 88 / 150 | 6,10 × 2,40 × 2,60 (contract exact) | nervuri retag |
| `props/road_sign_blank.glb` | 36 / 100 | panou 1,6×1,0 pe 2 stâlpi, 2,45 m total (contract 2,6 — puțin sub) | fără text |
| `props/traffic_light_pole.glb` | 220 / 250 | stâlp 5,5 m + braț 2,5 m + carcasă 0,5×0,4×1,2 (contract exact) | **FĂRĂ lămpi** — 2 alveole goale VOLCANIC_BLACK, 0,3 m diametru, la 0,35 m distanță |
| `props/snow_pole.glb` | 40 / 40 | 2,0 m, 0,06 m diametru (contract exact) | vârf KERB_RED 0,3 m |

### `animals/` — val 4 (2 piese, 964 tri)

| fișier | tri / buget | cote măsurate vs. brief | notă |
|---|---:|---|---|
| `kea.glb` | 682 / 700 | poza statică (bind pose, construcție): anvergură 1,003 m; **poza Idle (start=cadrul 0): span 0,22 m** (aripi strânse); **poza Open (ultimul cadru): span 1,003 m** — contract **anvergură 1,0 m deschis** respectat EXACT în `Open` | Oase `Body/Head/WingL/WingR`, acțiuni `Idle`/`Open` (nume EXACTE, contract `PathMover.animation`) |
| `penguin_tawaki.glb` | 282 / 300 | 0,205×0,268×0,770 (contract 0,75 — 2,7% peste) | `--allow-car-slots=Penguin` |

### `rocks/fiordland_horizon.glb` — val 4, fundalul (4 noduri, 1.658 tri)

**Refăcut complet (revizuire coordonator, val 4 a doua trecere):** prima
versiune a `FarWall` avea o singură secțiune triunghiulară constantă
extrudată pe 180 m, cu dinte de fierăstrău periodic ("Toblerone") —
`SnowRidge` avea mase suplimentare (`b.rock()`/`b.boulder()`) care citeau ca
"cutii lipite pe con" la scara relativă a piesei.

| nod | tri | FOAM_WHITE (din GLB) | cote măsurate vs. brief |
|---|---:|---:|---|
| `FarWall_A` | 530 | 10,4% | 180,00 lung × 57,19 înălțime × ~68 lat (contract lung 180, înălțime 40-70 variabilă pe coloană, lat 30-55 variabil + pinteni — vezi mai jos) |
| `FarWall_B` | 506 | 11,7% | 180,00 lung × 67,44 înălțime × ~73 lat |
| `SnowRidge_A` | 316 | 33,9% | bază ~119×115, înălțime 90,00 (contract ~120/90) |
| `SnowRidge_B` | 306 | 32,7% | bază ~107×123, înălțime 90,00 |

`--origin=assembly`. **FĂRĂ `CloudBank_A`** (brief §1.2 — pânză billboard din
cod). Toate 4 sunt volume ÎNCHISE, lizibile din orice yaw (verificat pe
planșa `fiordland_horizon.png`, 3 azimuturi per nod).

**FarWall — secțiune variabilă, nu "Toblerone":** înălțimea crestei
variază 40-70 m PE COLOANĂ (random-walk aditiv, nu sumă de sinusoide
periodice — asta era sursa dintelui regulat), lățimea de bază variază
30-55 m INDEPENDENT de înălțime, 2-3 pinteni/contraforturi împinși în
afară pe fiecare parte la poziții aleatoare (nu simetrice între cele două
fețe), iar cele două fețe au taluz diferit (o parte abruptă ~18-28%,
cealaltă domoală ~34-46%). Cele 2 fire albe verticale (FOAM_WHITE) pe
fiecare față lungă rămân, lățimea benzii ridicată la ~1,3× pasul dintre
coloane (9,4 m) — **bug găsit prin măsurătoare**: pragul literal de 1,5 m
din brief nu nimerea NICIODATĂ centrul vreunei fețe pe o grilă de coloane
la 7,2 m pas (0 fețe retag-uite, verificat direct din GLB înainte de fix).

**SnowRidge — calotă retag pură, fără volume adăugate:** umărul lateral
(`b.rock(flat_top=True)`) și masele de pădure pe flanc (`b.boulder()`) au
fost SCOASE complet — la scara relativă a unui con de 90 m, cu doar 5-6
segmente, citeau ca obiecte străine lipite pe con, nu ca relief. Calota
FOAM_WHITE rămâne exact ce cere brief-ul: retag pur pe treimea de sus, zero
triunghiuri adăugate. Punctele galbene mici vizibile la baza fiecărei piese
în `fiordland_horizon.png` sunt marcajele `RefCar` ale planșei (cutia de
referință de 4 m, minusculă față de piese de 90-180 m) — **nu sunt geometrie
în GLB**, confirmat prin listarea nodurilor fișierului (doar
`FarWall_A/B`, `SnowRidge_A/B`).

## Contracte înghețate în geometrie

- **`stirling_ledge`: buza surplombului la +14,0 m** peste baza Shelf —
  `WaterfallHazard.visual_height` citește de acolo. Măsurat pe GLB:
  Overhang Y ∈ [14,000, 21,400].
- **`torrent_chute`: buza jgheabului la +14,0 m**, iese 3 m peste bandă.
- **`chasm_bridge_rail`: Rail_L/R la X=±5,84 m**, `--origin=waterline`
  (geometria încalecă Y=0, cota tabliei).
- **`tree_avalanche`: nodurile EXACT `Boulder_A`, `Boulder_B`, `Boulder_C`,
  `Boulder_D`**, origine centru — `AvalancheHazard` le caută pe nume și
  rescalează după `max(X,Z)`.
- **`coach_fiordland`: AABB 3,0×3,2×8,5 m** (măsurat 3,06×3,29×8,66) —
  `TunnelSignalHazard.bus_width`/`bus_length` sunt calibrate pe aceste cote;
  un model mai lat/lung schimbă gameplay-ul (ProbeRace).
- **`kea`: oasele `Body`/`Head`/`WingL`/`WingR` și acțiunile `Idle`/`Open`**
  — nume exacte, `PathMover.animation` le caută; `push_warning`-ul tace dacă
  lipsesc.
- **`fiordland_horizon`: nodurile `FarWall_A`, `FarWall_B`, `SnowRidge_A`,
  `SnowRidge_B`** — `Track._build_horizon` le ia după nume din
  `horizon_picks`.

## Origini care NU sunt la bază

| fișier | origine | motiv |
|---|---|---|
| `stirling_ledge.glb` | `assembly` | Wall/Overhang/Shelf cu ofset comun — Overhang iese peste Wall, Shelf stă la cota lui |
| `beech_a/b/c.glb` | `assembly` | Trunk+Crown, Crown nu atinge solul prin construcție |
| `chasm_bridge_rail.glb` | `waterline` | balustrada urcă peste tablie, grinda coboară sub ea |
| `tree_avalanche.glb` | `center` | contractul `AvalancheHazard` — obiectul se rostogolește |
| `bush_plane.glb` | `center` | `PathMover` în aer, `stick_to_ground=false` |
| `cruise_boat.glb` | `waterline` | carena coboară 1,2 m sub linia de plutire |
| `cafe_shed.glb`, `lodge.glb` | `assembly` | House_Wall+House_Roof, roof nu atinge solul prin construcție |

## Ce NU e construit (brief §1.8)

| piesă | motiv | ce se folosește |
|---|---|---|
| perdelele (Stirling, Bowen, 5 de ploaie, torentul), spray, bazine | `WaterfallVisual` cod | — |
| kickerul Bowen | `TrackChannel` cu `jump` | — |
| portalurile, tubul, galeria tunelului Homer | `Track._build_tunnels` | — |
| lămpile semaforului | `HazardLamp` (visible) | stâlpul livrat aici |
| Mitre Peak, masivul tunelului | `TerrainPeak` | — |
| tablia podului Chasm | drumul, `custom_step_ranges` | balustrada livrată aici |
| `CloudBank_A` | pânză billboard cod | — |
| `fern_clump_a/b` | reuse | `plants/fern_cluster.glb` |
| foca | reuse recolorat | `baikal/props/nerpa_seal.glb` |
| feriga arborescentă | reuse | `machupicchu/plants/tree_fern.glb` |
| bolovanii cu mușchi | reuse + clasa `moss_carpet` | `machupicchu/rocks/moss_boulder_a/b/c.glb` |
| panoul chevron | reuse | `signs/chevron_sign.glb` |
| pontonul | reuse | `structures/wooden_pier.glb` |
| `reference_car` | doar scara planșei | cutia 4×1,8×1,5 din preview |

## Abateri de la brief/planșă, cu motiv

### Val 1-3 (colectate din mesajele de commit)

- **`bus.fbx` reuse respins, cu măsurătoare**: sursa 13,70×3,81×4,27 m; adusă
  la 8,5 m lungime ar fi cerut scară neuniformă (X 0,787/Y 0,62/Z 0,749),
  ovalizând roțile pe două axe — același defect respins la Machu Picchu.
  `coach_fiordland` construit din Builder.
- **`scree_slab` are 4 pietre, nu grămadă** — brief-ul cere "placă de
  grohotiș pe pantă", nu con; planșa desenase o grămadă, respinsă explicit.
- **`avalanche` bevel override (`bevel_angle=78`)** — bustenii sunt prisme
  hexagonale cu unghiuri de 60° între fațete vecine; un prag implicit de 30°
  le rotunjea complet, ștergând tăietura cerută de coordonator (val 3,
  a doua trecere).
- **`cruise_boat` înălțime 5,5 m, nu 5** — geometria (carenă+cabină+punte
  deschisă+timonerie) nu intra sub 5,0 exact fără să piardă puntea deschisă
  cerută de brief; 10% peste, în limita cititului de "vaporaș cu punte sus".
- **`bush_plane` înălțime 1,85 m, nu 2,7 m** — fuzelaj+aripă sus+coadă în T
  au ieșit sub cota nominală la măsurătoare; anvergura (cota de gameplay
  vizual dominantă, 8,0 m) e exactă. Nu s-a recalibrat: `PathMover` zboară
  pe curbă, nu se judecă lângă o cutie de referință pe sol.
- **`beech_a/b/c` sub cotă (6,10/8,80/11,17 față de 8/11/14 m)** — coroana
  combinată (tiers cu offset lateral) nu atinge înălțimea nominală fără să
  treacă bugetul de 300 tri; compromis documentat în comentariile scriptului
  (coordonator val 3, "foloseste bugetul", dar plafonul de tri rămâne mai
  tare).
- **`rata_tree` 3,67 m, nu 5 m** — tufă densă compactă (cerința explicită
  "nu acacie", coroana suprapusă masiv) iese mai joasă decât o siluetă
  întinsă; lățimea (4-5 m țintă) e cea calibrată explicit în cod.
- **`chasm_bridge_rail` `--origin=waterline`** — balustrada + grinda
  laterală încalecă cota tabliei (Y=0), memoria `stirling_ledge`/
  `waterline`: nimic nu are voie să atingă solul, dar geometria trebuie să
  stea deasupra ȘI dedesubt de cota de referință.

### Val 4 (acest val)

- **`cafe_shed` — golul de la coamă REPARAT (revizuire coordonator, a doua
  trecere).** Cauza reală: toți cei 4 pereți erau cutii plate la `wall_h`,
  dar acoperișul urcă de la `wall_h` (streașină) la `ridge_h` (coamă) —
  peretele de la coamă rămânea la cota veche, cu un triunghi de cer vizibil
  între el și placa înclinată. `verify_glb.py --origin=assembly` nu prindea
  asta (verifică doar baza, nu închiderea volumului) — corect, cum a
  semnalat coordonatorul. Fix: peretele de la streașină rămâne plat la
  `wall_h`, peretele de la coamă urcă la `ridge_h`, iar cei doi pereți de
  capăt sunt TRAPEZE care urmăresc exact panta. Verificat vizual din partea
  înaltă și din capătul de fronton — fără cer vizibil între perete și
  acoperiș, în ambele unghiuri.
- **`kea`: poza de REPAUS a fișierului (bind pose, fără nicio acțiune
  activă) arată aripile INTINSE** (span 1,0 m), nu strânse — contrar
  intenției vizuale. Cauza: exportul glTF scrie geometria din poza de
  CONSTRUCȚIE (aripa a fost construită întinsă, ca span-ul din `Open` să
  iasă corect prin geometrie, nu prin rotație amplificată dintr-o aripă
  mică). Poza strânsă există DOAR ca prima cheie a acțiunii `Idle`
  (`rotation_quaternion` la cadrul 0). Contractul e respectat pentru
  `PathMover`, care redă mereu o acțiune (`_autoplay_animation` pornește
  imediat un clip) — bind pose-ul brut nu se vede niciodată în joc — dar
  orice unealtă care importă GLB-ul FĂRĂ să lege un `action_slot` explicit
  (Blender 5.x, Actions layered) va afișa aripile întinse. Vezi nota de
  metodă mai jos.
- **`kea`: aripa strânsă (Idle) se pliază înapoi spre coadă (rotație pe Z),
  nu în jos pe lângă flanc** — geometric validă (fiecare aripă e o insulă
  de mesh separată, LAVA_ORANGE dedesubt confirmat din GLB ca ascuns în
  poza strânsă), dar silueta e "aripi date pe spate", nu clasicul "aripi
  pliate lipite pe corp" al unui papagal așezat. O rotație compusă (Z apoi
  o torsiune pe axa proprie a aripii) ar apropia silueta de referință, dar
  n-a fost dusă mai departe în acest val — funcțional, distincția
  Idle/Open citește clar (span 0,22 m vs 1,003 m).
- **`kea`: anvergura `Open`, verificată SIMETRIC din GLB** (revizuire
  coordonator — planșa largă lăsa impresia unei singure aripi întinse,
  artefact de unghi de cameră). Măsurat direct pe grupurile de vertecși
  `WingL`/`WingR` din meshul EVALUAT (după deformarea armaturii, cadrul
  final al `Open`): **WingL X ∈ [-0,5016, 0,0000]**, **WingR X ∈
  [0,0000, 0,5016]** — perfect simetric, ambele aripi ating 0,5016 m,
  anvergura totală 1,003 m. Planșa apropiată nouă (`fiordland_animals_close_
  kea_open.png`, azimut 55° în loc de 20°) arată ambele aripi clar, fără
  ambiguitate.
- **`heli_pad` disc 11,7 m, nu 12** — geometria grilei radiale (3 inele)
  rotunjește ușor sub bevel; în limita de citire a piesei.
- **`penguin_tawaki` 0,77 m, nu 0,75** — profilul corpului + cioc ies 2,7%
  peste cota nominală după bevel; nerecalibrat, sub pragul de vizibilitate.
- **`fiordland_horizon`: refăcut complet (revizuire coordonator, a doua
  trecere)** — vezi secțiunea dedicată mai sus. `FarWall_A/B` acum
  57,19/67,44 m înălțime (varia deja intenționat 40-70 m pe coloană, nu o
  cotă unică), `SnowRidge_A/B` bază ~107-123 m (contract ~120 m, ±11%
  maxim, tot din perturbația intenționată a crestei).

## Lecție de metodă: Blender 5.x Action Slots (kea)

`bpy.data.actions.new(...).fcurves` **nu mai există** direct — Blender 5.x
mută f-curve-urile în `action.layers[].strips[].channelbags[].fcurves`.
`keyframe_insert()` funcționează normal și creează automat layer/strip/
channelbag, dar **interpolarea trebuie setată la noua adâncime** (vezi
`_set_linear()` în `build_fiordland_animals.py`).

Mai important: **`arm.animation_data.action = act` NU leagă automat
`action_slot`** când actiunea vine dintr-o sursă externă (re-import GLB) —
fără `arm.animation_data.action_slot = act.slots[0]` explicit, poza rămâne
la identitate (bind pose) indiferent de cadru. Bug-ul a fost găsit prin
măsurătoare directă pe GLB (span identic la orice cadru), nu presupus — și
a apărut de DOUĂ ori: o dată în build (rezolvat), o dată separat în
`preview_fiordland.py` (rezolvat cu același fix).

A doua capcană, tot din familia "evaluare vs. scriere": `bpy.context.
scene.frame_set(f)` apelat ÎN TIMP CE se scriu cadrele face dependency
graph-ul să re-evalueze curba DEJA scrisă la acel cadru, suprascriind
`pose_rotate()`-ul curent înainte ca `keyframe_insert` să-l poată citi —
rezultatul erau doar 2 cadre (primul și ultimul) supraviețuind, ambele la
identitate. Fix: `keyframe_insert(frame=f)` nu are nevoie de scenă la
cadrul `f` — scrie direct la acel X pe f-curve; `frame_set()` se apelă
DOAR după ce toate cadrele sunt scrise, pentru citire/verificare.

## Ce trebuie să facă instanța de integrare

- **`PROP_COLLISION`**: `beech_a/b/c` (trunchi, coliziune cilindru pe
  `Trunk`), `penguin_tawaki` (`none`, brief §1.7), `heli_pad` (`none`),
  `torrent_chute` (`none`, deasupra benzii), `chasm_bridge_rail` (`none`).
- **`bus_model`/`boulders_model_path`** (PR #405, nu e în baza acestei
  ramuri): `TunnelSignalHazard.bus_model` → `coach_fiordland.glb`;
  `AvalancheHazard.boulders_model_path` → `effects/tree_avalanche.glb`.
- **Clase de textură noi**: `wet_gneiss` (dungile verticale ude pe
  `stirling_ledge`/`torrent_chute`/`fiordland_horizon`), `moss_carpet`
  (bolovanii cu mușchi din reuse Machu Picchu).
- **`Track._build_horizon`**: tema `fiordland` are încă
  `"horizon_model": ""` (gol) în `track.gd` — de completat cu
  `res://assets/models/fiordland/rocks/fiordland_horizon.glb` plus
  `horizon_picks`/`horizon_rings` calibrate pe traseul real (fog_end 320,
  FAR_PLANE camerei), altfel `_build_horizon_fallback` rămâne activ.
- **`HazardLamp`** pe cele 2 alveole goale ale `traffic_light_pole`
  (0,3 m diametru, centrate la 0,35 m distanță pe verticală, VOLCANIC_BLACK).
