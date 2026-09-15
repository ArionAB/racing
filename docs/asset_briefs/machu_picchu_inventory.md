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

### `structures/`, `buildings/` — val 2 (13 piese, 3.894 tri)

| fișier | tri / buget | notă |
|---|---:|---|
| `structures/inca_wall_a.glb` | 208 / 300 | **Contractul de înlănțuire dovedit:** capete la x = ±2,0000, lungime 4,0000, rost **0,0000** la îmbinare |
| `structures/inca_wall_b.glb` | 296 / 300 | Capete la ±3,0000, 2 nișe |
| `structures/inca_wall_c.glb` | 152 / 200 | Capete la ±1,0000 (rotunjirea colțului deplasa X; acum e doar pe Y) |
| `structures/fountain_basin.glb` | **266 / 200 (+33%)** | Peste buget, **decizie** — vezi abaterile |
| `structures/water_channel.glb` | 36 / 100 | Capete la ±2,0000 |
| `structures/trail_marker.glb` | 76 / 80 | — |
| `structures/rope_rail.glb` | 92 / 200 | Stâlpii la ±2,0; bbox-ul include capătul care iese |
| `buildings/inca_house_b.glb` | 496 / 500 | Ruina, un singur nod — n-a fost atinsă de problema acoperișurilor |
| `structures/inca_stair_a.glb` | **422 / 300 (+41%)** | Trepte cu vârfuri partajate (rise 0,25 m), obraji în trepte; peste buget, **decizie** |
| `structures/inca_stair_b.glb` | **798 / 500 (+60%)** | Idem, 20 de trepte |
| `buildings/inca_house_a.glb` | 548 / 700 | `House_Stone` + `House_Thatch`. `--origin=assembly` |
| `buildings/guardhouse.glb` | 504 / 800 | Trei ziduri, pantă abruptă, streașină 0,6. `--origin=assembly` |

Acoperișurile au cerut **patru iterații**, toate eșuate identic, până s-a găsit
cauza reală (originea per nod — vezi secțiunea de metodă). Dovada că stau acum pe
ziduri, dincolo de planșă: bbox-ul lui `House_Thatch` pe Y e **2,260 → 4,825**
(începe la streașină 2,5, se termină puțin peste coamă 4,5); înainte era
**0,000 → 2,566**, adică picat la sol. La guardhouse: **2,057 → 7,878** față de
coama la 7,46.

### `plants/`, `rocks/`, `props/` — val 3 (15 piese)

| fișier | tri / buget | notă |
|---|---:|---|
| `plants/polylepis_a.glb` | 598 / 1.000 | Coroană aproape sferică, coborâtă la 0,76 din înălțime |
| `plants/polylepis_b.glb` | 1.098 / 1.400 | Două trunchiuri din aceeași bază |
| `plants/tree_fern.glb` | 768 / 900 | — |
| `plants/bromeliad.glb` | **248 / 200 (+24%)** | Peste buget, declarat |
| `plants/orchid_cluster.glb` | **410 / 200 (+105%)** | Peste buget, declarat; `--allow-slots=31` |
| `plants/bamboo_clump.glb` | **958 / 600 (+60%)** | Peste buget, declarat |
| `rocks/moss_boulder_a/b/c.glb` | 200/200, 242/250, 238/300 | Mușchiul e retag pur pe fețele de sus |
| `props/tent_a.glb`, `tent_b.glb` | 256 / 300 fiecare | Cele mai bune piese din set (dom, țăruși, corzi) |
| `props/backpack_pile.glb` | 288 / 400 | Piesa cea mai slabă: la 1 m citește a cutii, nu a bagaje |
| `rocks/gorge_far_wall.glb` | 1.706 / 5.000 | **196,0 × 75,4 m** măsurat (cerut 200×80), săgeata arcului 58,4 m. `--origin=assembly` |
| `rocks/machu_picchu_mountain.glb` | 1.126 / 1.500 | **146,7 × 60,5 m** măsurat (cerut 150×60), fără trepte pe creastă (salt max 4,9 m) |

### Valul 4

Se completează. Contractele reale (citite din cod, nu din brief) sunt mai jos,
la „Contracte pentru valul 4".

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

- **`main_gate` are 8,4 m liber la bază, nu 4 — cauza: semi-lățime citită ca
  lățime.** Brief-ul **pistei** scria în v0.1 „4 m", care e **semi-lățimea**
  drumului (coloana din dreapta a tabelului POI), nu lățimea lui: drumul are
  13 m, strâns la 8 în poartă. O poartă de 4 m pe un drum de 8 m ar fi fost zid
  cu fantă, nu gâtuire — mașinile AI și jucătorul s-ar fi blocat acolo. Piesa
  s-a construit după brief-ul de **assets** §1.1 (8,4 bază / 7,4 sus / 6,0 liber
  sub buiandrug), care închide aritmetic. **Brief-ul pistei a fost corectat pe
  tree-ul principal (15 sep 2026)**: §2 POI H și tabelul de assets spun acum 8 m
  liber la bază / 6 m sub buiandrug, cu cauza notată acolo. Nu mai există
  contradicție.
  **Cota livrată e 8,390 m** (măsurată pe geometrie), adică peste cei 8 m ceruți
  — dacă cineva „corectează" vreodată piesa la 8,0 exact, pierde marja, nu
  câștigă conformitate.
- **`huayna_picchu` are baza 79×73 m, nu ~90.** Perturbația per coloană, cea
  care dă fațetele cerute de brief, scade raza medie. Compromis conștient între
  fațete late (silueta de la 250 m) și diametrul nominal.
- **`WOOD_WEATHERED` nu există ca nume în `dio_lib`** — constanta e `WOOD`,
  același slot 9. Irelevant pentru piesele livrate, dar brief-ul îl numește așa.

#### Piese peste buget, fiecare cu cifra și motivul

Bugetul e **plafon pentru formă, nu invers**: o piesă care intră în buget
pierzându-și semnătura nu e o piesă livrată. Cinci piese rămân peste, declarat:

- **`fountain_basin` 266/200 (+33%)** — 6 volume × 12 tri × 3,67 (multiplicatorul
  de bevel măsurat) = 264. `bevel_angle` nu ajută: toate muchiile unei cutii sunt
  de 90°, deci se califică mereu. Singurele pârghii tăiau buza bazinului sau gura
  de apă — exact ce face piesa să se citească pe planșa strânsă. **Decizie.**
- **`inca_stair_a` 422/300 (+41%)** și **`inca_stair_b` 798/500 (+60%)** —
  aduse de la 646 și 1.246 prin rărirea coloanelor obrazului la fiecare a 3-a
  treaptă, fără să se atingă treptele. Mai departe se pierde citirea de „zid în
  trepte", adică exact ce a reparat ocluzia. **Decizie.**
- **`bromeliad` 248/200, `orchid_cluster` 410/200, `bamboo_clump` 958/600** —
  tăiate până la bevel zero, `stations=3`, mai puține frunze/tulpini, noduri din
  `box` în loc de `cylinder`. Tăierea următoare atingea silueta unor piese care
  se văd de la 3–4 m în pădurea de nori.

#### Alte abateri ale valului 3

- **Orhideea are o petală-lamelă + labelum per floare**, nu trei petale. Brief-ul
  cere „5 flori pe tije" — numărul de *flori* se respectă; la 0,4 m și buget 200,
  petalele 2 și 3 costau 80 tri/floare și nu se distingeau.
- **Mușchiul de pe bolovani e retag pur, fără volum.** Două variante cu volum au
  fost încercate și respinse (pietricele lipite / capac cusut peste stâncă);
  brief-ul cere la literă „fețele de SUS retag `CACTUS_GREEN`".
- **Fără volume de vegetație pe creasta `gorge_far_wall`.** Peretele e o *pânză*
  (două foi cusute), deci nu există „a îngropa" ceva în ea — obiectul trece prin
  ea și atârnă pe dedesubt. Pădurea rămâne benzi de retag; volumul de vegetație e
  problema integrării (scatter pe teren, unde există sol).
- **Queñualul a ieșit inițial identic cu o acacie-umbrelă** (coroană plată pe
  trunchi gol): cauza era `squash=0.55`, rețeta acaciei de la Serengeti.

#### Două trimiteri greșite în brief-ul de assets (§1.6)

Brief-ul dă `crater_far_wall` de la Serengeti ca analog pentru `gorge_far_wall`,
dar îl caută în `build_serengeti_rocks.py`: piesa e de fapt în
**`build_serengeti_camp.py`**, iar bugetul ei e **6.000 cu `--origin=assembly`**,
nu 5.000. Nu schimbă nimic la piesa livrată (1.706 tri), dar costă o căutare.

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

**Nici planșa nu vede culoarea.** `preview.py` nu referențiază `atlas_material`
/ `ATLAS`, deci toate planșele randează monocrom (gri-bej) — inclusiv orhideea,
singurul accent saturat din kit. Consecința practică: mușchiul-retag, benzile de
culoare de pe peretele defileului și rozul orhideei **nu pot fi judecate din
harnașamentul ăsta**; verdictul lor rămâne pentru integrare, în Godot. Planșa
dovedește silueta, `verify_glb.py` dovedește sloturile; culoarea *compusă* nu e
dovedită de niciunul.

**`finish` re-centrează fiecare nod pe bbox-ul LUI.** `finish(origin="base")` →
`set_origin_base(obj, center_xy=True)` (`dio_lib.py:1291`) calculează
`dx = -(min+max)/2`, `dy` la fel, `dz = -min(z)` — **pe obiectul curent**. Pe o
piesă cu mai multe noduri construite în același cadru (casa: `House_Stone` +
`House_Thatch`), fiecare nod e apoi mutat separat: zidurile stau (talpa e deja la
0), dar acoperișul coboară până când *streașina lui* ajunge la 0, deci se
desprinde de casă cu ~2,5 m și se re-centrează și pe XY pe extentul lui. Efectul
e independent de geometria acoperișului — de aceea **trei algoritmi diferiți au
eșuat identic** și a costat valul 2 patru iterații. Pe piesele compuse, offsetul
se calculează **o dată pe ansamblu** și se aplică identic tuturor nodurilor
(`set_origin_base` întoarce chiar vectorul), iar verificarea e `--origin=assembly`.

Un corolar despre regula „fișier identic la bit = schimbarea n-a ajuns la
geometrie": e bună, dar **întreabă întâi dacă cifra depinde de ce ai schimbat**.
Numărul de triunghiuri depinde de topologie, nu de poziție: două cutii mutate
rămân 88 de triunghiuri, iar un bevel a cărui *lățime* se schimbă tesește
aceleași muchii (se califică după unghi), deci dă același număr. În ambele cazuri
identitatea e normală, nu simptom.

## Ce NU e făcut

Integrarea în `Track15.tscn` (plantarea pe POI, clasele de textură, tema), rig-ul
condorului (vezi mai sus), și planșele colorate — previzualizarea randează gri,
fără atlas: verifică forma, originea și orientarea, nu culoarea.
