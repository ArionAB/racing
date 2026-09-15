# Inventar assets — Machu Picchu (`Track15`)

GLB-uri în `assets/models/machupicchu/`, pe ramura `feat/machupicchu-kit`.
Sursa: `docs/asset_briefs/machu_picchu_kit.md` (contractul) și cele trei
referințe vizuale pe care le numește. Verificare:
`bash tools/blender/verify_machupicchu.sh` → **VERDICT KIT: OK**.
Planșele de control, randate **din GLB-urile exportate**:
`docs/asset_briefs/img/machupicchu_*.png` (`preview_machupicchu.py`).

| script | ce produce | stare |
|---|---|---|
| `build_machupicchu_hero.py` | Huayna Picchu, porțile, cornișa, sacrele | ✔ val 1 |
| `build_machupicchu_citadel.py` | ziduri, scări, case, fântâni, jgheaburi | în lucru (val 2) |
| `build_machupicchu_forest.py` | queñual, ferigi, bolovani cu mușchi, bambus, corturi | în lucru (val 3) |
| `build_machupicchu_horizon.py` | peretele defileului, muntele de sud | în lucru (val 3) |
| `build_machupicchu_animals.py` | lamele, condorul | nefăcut (val 4) |
| `build_machupicchu_vehicles.py` | autobuzul Consettur, trenul PeruRail | nefăcut (val 4) |

## Inventar

### `rocks/`, `structures/` — val 1 (7 piese, 5.137 tri)

| fișier | tri / buget | notă |
|---|---:|---|
| `rocks/huayna_picchu.glb` | 503 / 2.500 | 33 m bbox (30 peste origine + 3 îngropați), bază 79×73 m. Fațete late din 8 segmente, inele decalate pe X și Y pentru vârful aplecat, terase ancorate pe raza corpului. `--origin=assembly` |
| `structures/inti_punku.glb` | 1.092 / 1.800 | Poarta Soarelui, **gol măsurat 14,000 m** pe axa drumului. Fără buiandrug. Pragul treptei 0,100 m. `--origin=assembly` |
| `structures/main_gate.glb` | 588 / 1.500 | **8,390 bază / 7,410 sus / 6,000 liber sub buiandrug** (măsurat). `--origin=assembly` |
| `structures/inca_bridge_ledge.glb` | 914 / 2.500 | Cornișa Podului Incaș, **gol măsurat 4,250 m**, liber în GLB. `--origin=assembly` |
| `structures/sun_temple.glb` | 1.108 / 1.200 | Zid curb pe stâncă din `rock()` cu strate + bolovani la picior, coronament neregulat |
| `structures/intihuatana.glb` | 492 / 500 | Trepte cu vârfuri partajate: 160 muchii interioare, **0** bordură liberă (măsurat pre-bevel) |
| `structures/three_windows.glb` | 540 / 600 | Cele 3 ferestre trapezoidale; se înclină doar muchiile dinspre gol, nu capetele de zid |

### Valurile 2–4

Se completează pe măsură ce intră. Contractele sunt în brief §1.2–§1.5.

## Ce trebuie știut la integrare

### Piese din brief care NU s-au generat, cu motivul

Patru piese cerute inițial n-au **consumator în cod**: hazardele își construiesc
singure geometria, deci GLB-ul ar fi fost fișier mort, exportat, trecut prin
`verify_glb.py` cu OK, intrat în inventar și nevăzut niciodată în joc.

- **`rope_bridge.glb`, `bridge_tower_a.glb`, `bridge_tower_b.glb`** —
  `rope_bridge_hazard.gd` (`_build_visual`, `_build_towers`, liniile 313–392)
  face tablierul, cele 4 cabluri, legăturile **și turnurile** în `SurfaceTool`,
  deformate de `assets/shaders/rope_bridge.gdshader`. `Track15.tscn:48` îl
  instanțiază deja cu `deck_width = 11.0`. În plus cadrul cerut de brief era
  **greșit**: shaderul citește `-VERTEX.z / deck_length` cu originea la capătul
  apropiat, pe când brief-ul cerea lungimea pe X cu originea la centrul
  tablierului — un GLB construit după literă s-ar fi deformat pe axa greșită,
  decalat cu jumătate din lungime. Brief-ul a fost corectat (15 sep 2026).
  Dacă o captură din mașină arată că turnurile-cutii nu țin, instanța de
  gameplay deschide un `deck_model`/`tower_model` și **abia atunci** se comandă
  piesa, în cadrul real al hazardului.
- **`inca_bridge_beams.glb`** — `LiftBridgeHazard._build_span()`
  (`lift_bridge_hazard.gd:406-460`) derivă traveaua din `near_lip`/`far_lip`
  **pe tick**, iar colizorul e un `ConvexPolygonShape3D` generat din aceleași
  colțuri (`:474-488`). Clasa n-are export `model`/`model_node`. Cotele fixe din
  brief (3 bârne de 4,6 m) nu pot respecta prin construcție golul care se
  recalculează. Nodul e deja configurat procedural în `Track15.tscn:90-106`.
  Golul de 4,25 m din `inca_bridge_ledge` rămâne liber, neschimbat.

Și, ca la Serengeti:

- `cloud_bank` — pânză billboard din cod (`CloudRiseHazard`), nu GLB.
- `chevron_post` — reuse din `assets/models/chongqing/props/chevron_post.glb`.
- `cow.glb` — rămâne placeholder-ul lamelor până intră `llama.glb`.

### Abateri de la planșă / brief, cu motiv

- **`main_gate` are 8,4 m, nu 4 m.** Brief-ul **pistei** §2 POI H scrie „4 m
  lățime"; brief-ul de **assets** §1.1 cere 8,4 bază / 6,0 liber. S-a construit
  după al doilea, fiindcă închide aritmetic: drumul are semi-lățime 4 (8 m lat),
  iar o poartă de 4 m pe un drum de 8 m e zid cu fantă, nu gâtuire — mașinile
  AI și jucătorul s-ar bloca acolo. **Decizia dezvoltatorului (15 sep 2026):
  piesa rămâne la 8,4, iar contradicția se notează DOAR aici** — rândul din
  `docs/track_briefs/machu_picchu.md` §2 POI H rămâne neschimbat, deci cele două
  cifre circulă în continuare. De ținut minte la integrare.
- **`huayna_picchu` are baza 79×73 m, nu ~90.** Perturbația per coloană, cea
  care dă fațetele cerute de brief, scade raza medie. Compromis conștient între
  fațete late (silueta de la 250 m) și diametrul nominal.
- **`WOOD_WEATHERED` nu există ca nume în `dio_lib`** — constanta e `WOOD`,
  același slot 9. Irelevant pentru piesele livrate, dar brief-ul îl numește așa.

### Origini care NU sunt la baza bbox-ului

`--origin=assembly` pe piesele compuse la care nu tot atinge solul:
`huayna_picchu` (baza îngropată 3 m — `base_axis` normalizează minimul la 0,
deci îngroparea se exprimă ca offset la așezare), `inti_punku` și `main_gate`
(originea pe axa drumului, între camere), `inca_bridge_ledge` (originea pe axa
golului, la baza cornișei), plus la valurile următoare `condor`,
`gorge_far_wall`, `machu_picchu_mountain`.

### Sloturi de paletă

Zero sloturi noi. Excepțiile declarate în `verify_machupicchu.sh`:
`--allow-slots=31` (FLAMINGO_PINK pe `orchid_cluster`, accent rar ca flamingii
de la Serengeti) și `--allow-car-slots` pe vehicule (`Consettur_Bus` cu
CAR_YELLOW, `Train_Loco,Train_Tender,Train_Wagon` cu CAR_BLUE/CAR_YELLOW —
brief §0.4 declară vehiculele excepție).

### Contracte de gameplay înghețate în geometrie

- **`inti_punku`: 14,0 m liber** pe axa drumului — drumul la POI C are
  semi-lățime 6,5 (13 m lat), deci sub 14 poarta devine perete.
- **`main_gate`: 8,4 m la bază, 6,0 m liber sub buiandrug** — vezi abaterea.
- **`inca_bridge_ledge`: gol de 4,25 m**, contract cu `Track15.tscn:90-106`
  (`gap = 4.25`).
- **Trepte cu vârfuri partajate** pe `intihuatana` (e lângă grilă, mașinile o pot
  atinge) și pe treapta din `inti_punku` (prag 0,1 m): pragurile peste 0,3 m
  sunt ziduri pentru fizica întreagă.

### Contracte pentru valul 4 — citite din cod, nu din brief

Din cele 45 de piese, **doar trei au consumator**; restul e decor pur, așezat
manual (tema declară `decor: "none"` la `track.gd:1022`, deci `TrackDecor` nici
nu rulează). Contractele celor trei:

- **`consettur_bus.glb`** — `bus_hazard.gd:176-184` + `path_mover.gd:240-270`.
  Cutia de coliziune se măsoară pe **AABB-ul modelului**; `body_size` e doar
  placeholder-ul folosit când lipsește modelul. **Înainte = −Z local.** Origine
  la sol, centrată pe XZ. `model_yaw` permite corecția pe instanță.
- **`perurail_train.glb`** — `train_hazard.gd:39-41`. Noduri căutate după nume
  **exact** (`Train_Loco`, `Train_Tender`, `Train_Wagon`), doar printre copiii
  **direcți**; dacă lipsește oricare, se aruncă toată garnitura și se cade pe
  cutii (`:381-386`) — deci `Train_Tender` trebuie să existe chiar dacă PeruRail
  n-are tender. **Botul spre +X, NU −Z: brief-ul §1.5 greșește aici**
  (`build_train.py:19`, `train_hazard.gd:335-339`). Ecartament `|z| = 0.45`
  (`GAUGE_HALF`), baza roților la `y = 0`, `RAIL_TOP = 0.28`. **Nu** copia
  `RAIL_GAUGE = 1.52` din `build_baikal_railway.py` — ăla e șina de decor.
- **`llama.glb`** — `sliding_hazard.gd:103-105, 371`. Acțiuni cerute exact:
  `Idle`, `Eating`, `Walk`, `Gallop` (case-sensitive). **Fără un clip numit fix
  `Walk`, tot rig-ul e ignorat în tăcere.** Cele patru lame sunt deja cablate în
  `Track15.tscn:120-158` cu `cow.glb` ca placeholder.

**Condorul:** acțiunile `Open`/`Close` din brief §1.4 **n-au niciun
declanșator** — nimic din `scenes/` nu le caută. Modelul e util ca decor; rig-ul
se face doar când instanța de gameplay scrie `Area3D`-ul de 25 m.

## Metodă — ce a costat și ce se ia mai departe

**`verify_glb.py` nu vede forma.** Măsoară sloturi, AO, origine, număr de
triunghiuri. La valul 1, `huayna_picchu` a ieșit **con perfect neted** și a
trecut cu `VERDICT: OK` la 522/2.500 tri; `sun_temple` era un semicilindru
extrudat pe un soclu tăiat drept; `intihuatana`, discuri concentrice. Toate trei
verzi. Singurul test care le-a prins a fost **planșa randată** — deci planșa se
citește după fiecare export, nu doar verdictul.

Corolarul: **bugetul de triunghiuri e un plafon, nu o țintă de economisit.** O
piesă la 20% din buget care arată netedă nu e eficientă, e formă lipsă
(`sun_temple` a crescut de la 548 la 1.108 ca să capete caracter).

Și: **cotele de contract nu sunt verificate de nimic.** Lățimile libere,
pragurile, capetele plane se măsoară explicit pe geometrie și se scriu aici.
Vârfurile partajate se verifică pe topologia **pre-bevel** — pe GLB bevel-ul
sparge muchiile și cifra ar trece și fără cusătură.

## Ce NU e făcut

Integrarea în `Track15.tscn` (plantarea pe POI, clasele de textură, tema), rig-ul
condorului (vezi mai sus), și planșele colorate — previzualizarea randează gri,
fără atlas: verifică forma, originea și orientarea, nu culoarea.
