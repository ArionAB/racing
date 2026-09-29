# Măsurători kit Jodhpur (`Track17`) — inventarul tehnic

Toate cifrele de mai jos sunt **citite din GLB-urile importate**, nu din
brief și nici din `jodhpur_inventory.md`. Sunt sursa de adevăr pentru maparea
din `scenes/props/world_prop.gd` (`PROP_COLLISION`, `SPLIT_MODELS`,
`CLASSES_BY_MODEL`) și `tools/probe_decor.gd`, pe modelul
`fiordland_masuratori.md`. Unde o cifră contrazice brief-ul, se spune care
cifră e greșită (§5).

## Comenzile care au produs tabelele

```powershell
$E = "D:\GameDev\Godot_v4.7-stable_win64_console.exe"
# 0. import proaspăt (memoria import-invechit-falsifica-masuratoarea)
& $E --headless --path D:/GameDev/wt-jod-poi-base --import
# 1. inventarul per nod: nume, triunghiuri, AABB (DUPĂ transformul rădăcinii), rază la bază, sloturi
& $E --headless --path D:/GameDev/wt-jod-poi-base --script res://tools/probe_machupicchu_kit.gd -- --dir=jodhpur
# 2. golul porților ca GOL + profilul terenului pe E (§4)
& $E --headless --fixed-fps 60 --path D:/GameDev/wt-jod-poi-base res://tools/ProbeJodPorti.tscn -- --track=10 [--scale=1.3]
```

Godot v4.7.stable.official.5b4e0cb0f, ramura `jodhpur/poi-fundatie` (din
`origin/jodhpur/track17` = 4ac84517, adică după PR #424). Sonda a găsit
**50 de fișiere .glb**, tot kitul.

**Scara pe rădăcini:** citită direct din chunk-ul JSON al fiecărui .glb
(memoria `scala-glb-neaplicata-la-radacina`): **toate cele 50 au scală și
rotație unitare pe fiecare nod rădăcină.** AABB-urile de mai jos sunt deci și
cele pe care le vede `Track.model_aabb` / colizorul.

**Coliziuni de nume de fișier cu alte kituri:** una singură —
`plants/euphorbia.glb` are același stem ca `serengeti/plants/euphorbia.glb`.
Toate mapările din `world_prop.gd` sunt cheiate pe stem, deci intrările
Serengeti (`SPLIT_MODELS`, `ACCENT_HOLDS_CLASS`, `CLASSES_BY_MODEL` →
`acacia_canopy` pe accent) s-ar fi aplicat și cactusului Jodhpur (vezi
pasul 2: ruptura Serengeti e limitată acum la cele 8 zone Serengeti).
Coliziuni de nume de NOD (cheia trebuie să fie pe fișier, memoria
`nume-noduri-nu-sunt-unice`): `House_Wall`/`House_Trim`/`House_Glow`/
`House_Rail` (și la `fiordland/buildings/cafe_shed`), `Crown`/`Trunk` (fagii
Fiordland), `Well_Stone` (3 piese ale fântânii), `Palace_Stone`/`Palace_Glow`
(ambele fațade), `Canopy*`/`Goods*`, `Gate_Stone`/`Gate_Doors`. La import
Godot rescrie `.001` → `_001` (`House_Wall_001` pe casa c, `_002` pe d, `_003`
pe e, `_004` pe haveli).

## 1. Inventar per piesă

`h` = înălțimea AABB (m). `L × l` = amprenta AABB pe X × Z în Godot (m).
`rază bază` = raza maximă în XZ a vertecșilor din primele 15% din înălțime.
Sloturile sunt cele din `scripts/palette.gd` (toate UV-urile sunt COLAPSATE pe
centrul slotului — nicio piesă nu mătură atlasul). Consumatorul e POI-ul din
brief §2 sau codul care o citește.

| piesă | noduri de mesh REALE (Godot) | tri | h | L × l (X × Z) | origine | rază bază | sloturi | consumator |
|---|---|---:|---:|---|---|---:|---|---|
| `animals/baraat_horse` | `Horse`, `Saddle`, `Rider` (+ schelet, clip `Walk`) | 1974 | 2.41 | 0.74 × 2.50 | bază | 0.65 | multi | `PathMover` — procesiunea pe trotuarul D |
| `animals/black_kite_bird` | `Kite` (rig `KiteRig`, clip `Fly`) | 508 | 0.18 | 1.50 × 0.87 | **centru** (y −0.09..0.09) | 0.27 | 9,16,28 | `PathMover` (`stick_to_ground=false`) — uliii sub F |
| `animals/langur` | `Langur` | 988 | 0.70 | 0.67 × 0.94 | bază | 0.56 | 20,29 | DecorManual E (parapet) |
| `animals/peacock_closed` | `Peacock` | 2500 | 1.03 | 0.47 × 2.14 | bază | 1.07 | 1,13,15,16,21,22,29 | DecorManual D/F (ziduri) |
| `animals/peacock_fanned` | `Peacock` | 4568 | 1.00 | 1.60 × 0.44 | bază | 0.12 | 1,15,16,21,22,29 | DecorManual D/F — **1,6 × 1,0 m, nu 1,6 × 1,4** (brief) |
| `animals/zebu_cow` | `Cow_Body`, `Bell` (schelet 12 oase; clipuri `GetUp`/`Lie`/`LieDown`/`Stand`/`Walk`) | 2682 | 1.88 | 0.79 × **2.72** | bază | 0.99 | 20,22,30,31 + clopoțel 16 | `CowGate.model` — **NELEGAT azi** în Track17 (pasul 4) |
| `buildings/blue_house_a` | `House_Wall` (22 84.8% + **9 WOOD 15.2%**, y 2.93..4.03), `House_Rail` 22, `House_Trim` 9, `House_Glow` 20 | 5117 | 8.06 | 7.15 × 6.62 | bază | 4.67 | vezi coloana 2 | DecorManual D/H + `CityFill` |
| `buildings/blue_house_b` | `House_Wall` (22 81.6% + **12 9.6%** planta y 3.2..4.6 + **28 8.7%** rezervor y 9.5..10.4), `House_Rail` 22, `House_Trim` 9, `House_Glow` 20 | 5932 | 10.37 | 6.82 × 7.55 | bază | 4.79 | | idem |
| `buildings/blue_house_c` | `House_Wall_001` (22 81.6% + **28 18.4%** rezervor y 5.9..7.4), `House_Trim_001` 9, `House_Glow_001` 20 | 4430 | 7.36 | 7.50 × 7.67 | bază | 5.08 | | idem |
| `buildings/blue_house_d` | `House_Wall_002` 22 100%, `House_Rail_001` **20** (balustradă neagră), `House_Trim_002` 9, `House_Glow_002` 20 | 5624 | 8.80 | 7.50 × 8.01 | bază | 5.20 | | idem |
| `buildings/blue_house_e` | `House_Wall_003` 22 100%, `House_Rail_002` 22 (scara de pe față), `House_Trim_003` 9, `House_Glow_003` 20 | 5642 | 8.84 | 7.40 × 6.26 | bază | 4.61 | | idem |
| `buildings/ghanta_ghar` | `Tower_Stone` 3, `Tower_Glow` 20, `Clock_Glow` 20+22 | 8154 | 21.88 | 7.00 × 7.00 | bază | 4.95 | | DecorManual A/H (reperul lui H) |
| `buildings/haveli_facade` | `House_Wall_004` 22, `House_Trim_004` 9, `House_Glow_004` 20 | 4796 | 11.10 | 10.92 × 7.43 | bază | 6.28 | | DecorManual D/F |
| `plants/euphorbia` | `Euphorbia` (12 82.5%, 21 10%, 4 7.5%) | 280 | 2.21 | 0.75 × 1.97 | bază | 0.45 | | DecorManual G |
| `plants/khejri_tree` | `Trunk` 9, `Crown` 12+21 | 346 | 6.07 | 6.97 × 7.30 | bază | 0.47 | | DecorManual A/B/D/G/H |
| `plants/neem_tree` | `Trunk` 9, `Crown` 12+21 | 386 | 7.02 | 7.77 × 8.64 | bază | 0.78 | | idem |
| `props/baraat_band` | `Band_Dhol`, `Band_Hands`, `Band_SmallDrum`, `Band_Trumpet` | 1490 | 1.80 | 3.64 × 0.93 | bază | 1.72 | multi (14,16,22,…) | `PathMover` — procesiunea D (static, merge cu calul) |
| `props/chai_stall` | `Stall_Wood` 0+9, `Stall_Metal` 11 | 1016 | 2.60 | 2.11 × 2.67 | bază | 1.58 | | DecorManual B |
| `props/diya` | `Diya` 23+10 | 22 | 0.05 | 0.09 × 0.11 | bază | 0.04 | | `FlockProp` — candele pe praguri/trepte (C, D, E, F) |
| `props/floating_diya` | `Floating_Diya` 21+23+10 | 38 | 0.05 | 0.24 × 0.24 | bază | 0.13 | | `FlockProp` pe apă (C, G2) |
| `props/marigold_garland` | `Garland` 30 | 640 | 1.09 | 2.59 × 0.15 | **sus** (atârnă în jos 1,09) | 0.55 | | DecorManual A/B |
| `props/rampart_cannon` | `Cannon_Wood` 9, `Cannon_Metal` 20 | 4080 | 1.52 | 3.58 × 1.42 | bază | 1.84 | | DecorManual F (ceasul salvelor — cod nescris) |
| `props/rooftop_clutter` | `Clutter_Base` 9+22+28, `Clutter_Laundry` 16+31 | 1204 | 1.96 | 3.00 × 2.50 | bază | 1.95 | | DecorManual D/F (acoperișuri) |
| `props/rooftop_tank` | `Tank_Body` 28 | 544 | 1.28 | 1.25 × 1.25 | bază | 0.60 | | DecorManual D/F (acoperișuri) |
| `props/spice_sacks` | `Sacks` 1, `Spice` 14+16 | 1232 | 0.65 | 1.48 × 0.84 | bază | 0.76 | | DecorManual B |
| `props/stall_canopy_a/_b/_c` | `Canopy(_001/_002)` 0, `Canopy_Wood(_nnn)` 9, `Goods(_nnn)` 14/16/21/30 | 1520 fiecare | 2.60 | 3.50 × 3.10 | bază | 1.80 | | DecorManual B |
| `props/textile_strip` | `Poles` 9, `Cloth` 14,16,21,30,31 | 599 | 2.60 | 10.15 × 0.15 | bază | 5.08 | | DecorManual B (peste stradă, 7–9 m) |
| `props/thela_cart` | `Cart_Wheels` 9, `Cart_Wood` 9, `Cart_Fruit` 14,16,21,30 | 3632 | 1.11 | 2.44 × 1.20 | bază | 1.11 | | DecorManual B |
| `props/zipline_rider` | `Zip_Pulley`, `Zip_Rider` | 678 | 1.65 | 0.48 × 1.28 | **scripete** (y −1.65..0) | 0.90 | multi | `PathMover` pe cablu F — **cablul (cod) nu există** |
| `rocks/jodhpur_horizon` | `UmaidBhawan_A` 1+3, `FarCity_A` **22 100%**, `FarCity_A_Beige` 0+28, `FarCity_A_Glow` 20, `DesertRidge_A`/`_B` 1+2+4 | 4752 | 35.0 | 200 × 60 (grup) | bază | — | | `Track._build_horizon` (tema, pasul 3b) |
| `rocks/rhyolite_boulder_a` | `Rhyolite_Boulder_A` 4 | 40 | 2.00 | 2.40 × 3.00 | bază | 1.64 | | DecorManual G/E/F |
| `rocks/rhyolite_boulder_b` | `Rhyolite_Boulder_B` 4 | 44 | 1.80 | 2.20 × 3.50 | bază | 1.86 | | idem |
| `rocks/rhyolite_boulder_c` | `Rhyolite_Boulder_C` 4 | 36 | 1.60 | 2.00 × 2.50 | bază | 1.37 | | idem |
| `rocks/rock_slab` | `Rock_Slab` 4 | 44 | 0.80 | 2.50 × 4.00 | bază | 2.03 | | DecorManual G2 (aterizarea) |
| `structures/fort_bastion` | `Bastion_Stone` (3 79.1% + **20 20.9%** guri de tragere, y 5.3..8.9) | 4848 | 13.79 | 18.78 × 18.78 | bază | 9.39 | | DecorManual F/E |
| `structures/fort_gate_fateh` | `GateFateh_Stone` 3, `GateFateh_Glow` 20, `GateFateh_Doors` 9+20 | 19580 | 16.46 | 8.64 × **32.74** | bază, pe axul golului | 16.47 | | DecorManual E |
| `structures/fort_gate_jai` | `GateJai_Stone` 3, `GateJai_Glow` 20, `GateJai_Doors` 9+20 | 15108 | 16.28 | 8.64 × 32.74 | idem | 16.46 | | DecorManual E |
| `structures/fort_gate_loha` | `GateLoha_Stone` 3, `GateLoha_Glow` 20, `GateLoha_Doors` 11+20 | 15012 | 14.19 | 8.64 × 32.74 | idem | 16.46 | | DecorManual E |
| `structures/fort_wall_segment` | `Wall_Stone` 3, `Wall_Glow` 20 | 1280 | 13.98 | 3.60 × 12.00 | bază | 6.26 | | DecorManual E/F |
| `structures/fort_wall_turret` | `Turret_Stone` 3, `Turret_Glow` 20 | 2876 | 16.98 | **7.50** × 7.50 | bază | 4.50 | | DecorManual E/F |
| `structures/jaswant_thada` | `Thada_Stone` (22 97%, 29 3%) | 14552 | 13.89 | 28.80 × 17.54 | bază | 15.24 | | DecorManual G/G2 |
| `structures/market_gate` | `Gate_Stone` 3, `Gate_Glow` 20, `Gate_Doors` 9+20 | 21048 | 16.93 | **40.35** × 7.00 | bază | 20.30 | | DecorManual A (peste grilă) |
| `structures/palace_facade_a` | `Palace_Stone` 3, `Palace_Glow` 20 | 19924 | 13.71 | 8.35 × 40.00 | bază | 20.43 | | DecorManual F |
| `structures/palace_facade_b` | `Palace_Stone` 3, `Palace_Glow` 20 | 23286 | 15.78 | 8.40 × 44.70 | bază | 22.35 | | DecorManual F |
| `structures/stepwell_corner` | `Well_Stone` 1 | 1056 | 3.12 | 6.30 × 6.30 | bază | 4.24 | | DecorManual C |
| `structures/stepwell_flight_module` | `Well_Stone` 1 | 2464 | 3.12 | 12.20 × 3.00 | bază | 6.19 | | DecorManual C (3 etaje × pereții gropii) |
| `structures/stepwell_pavilion` | `Well_Stone` 1, `Well_Glow` 20 | 11810 | 10.90 | 20.56 × 8.38 | bază | 10.82 | | DecorManual C (capătul de vest) |
| `vehicles/tuktuk` | `Tuktuk_Body` (28 56.7%, 16, 30, 20, 29, 14, 11), `Tuktuk_Roof` 16, `Wheel_Front`/`Wheel_Rear_L`/`Wheel_Rear_R` 20+11 | 5060 | 1.80 | 1.40 × 2.61 | sol; roțile cu originea în **centrul osiei, y 0,22** | 1.31 | | `CarData` `tuktuk.tres` (pasul 3a) |

**Total kit: 236 482 de triunghiuri pe 50 de fișiere** (suma lui `TOTAL tri`
din sondă). Cele mai grele: `palace_facade_b` 23 286,
`market_gate` 21 048, `palace_facade_a` 19 924, `fort_gate_fateh` 19 580.

**Orientare** (confirmată pe AABB): porțile, zidul și fațadele au lungimea
pe **Z** în Godot, deci **axa de trecere a porților e X**; `market_gate` are
lungimea pe X, deci se trece pe **Z**. Tuk-tuk-ul are roata din față la
z = +0,80 (botul spre **+Z**, cum cere `model_rotation_deg` 180 din
`car.gd`), vaca are lungimea pe Z (2,72 m, în intervalul 2,6–2,9 cerut de
ulicioara de 3,2 m).

## 2. Piese fără consumator (sau cu consumator nescris)

Nicio piesă nu e fără loc în brief. Dar **cinci au nevoie de cod care nu
există încă** — le semnalez ca să nu fie descoperite de un constructor de POI:

| piesă | ce lipsește |
|---|---|
| `zipline_rider` | cablul („îl trage codul, pe curbă", kit §1.6) — nu există niciun cod de cablu; `PathMover` mută doar figura |
| `rampart_cannon` | salvele (ceas 31 s + fum/flacără, brief §3) — piesa e doar decor static până atunci |
| `zebu_cow` | `CowGate.model` era gol (cutia placeholder) — **legat la pasul 4**; dar `CowGate` nu redă nicio animație, deci vaca stă în picioare și când e „culcată” |
| `*_Glow` (case, turn, porți, fațade, orizont) | nu devin emisive noaptea: niciun material de clasă nu e legat de `dusk_lamps` (DuskCycle) — ferestrele rămân `VOLCANIC_BLACK` la `dusk = 1` |
| `diya`, `floating_diya` | `FlockProp` le poate purta, dar flacăra (shader `diya_flame`) nu există |

## 3. Coliziunea (decizia `PROP_COLLISION`)

Rapoartele rază-bază / semi-lățime: `neem_tree` 0,78 / 4,32 = **0,18**,
`khejri_tree` 0,47 / 3,65 = **0,13** → `trunk` (hull-ul coroanei de 7–8 m ar
opri mașina în aer). `euphorbia` rămâne `trunk` (intrarea Serengeti existentă,
raport 0,45 / 0,99 = 0,46, corectă și aici).

| mod | piese | motiv |
|---|---|---|
| `hull` (implicit) | casele a–e, haveli, `ghanta_ghar`, zidul, turnul de zid, bastionul, fațadele, cenotaful, tarabele (`stall_canopy_*`, `chai_stall`), `thela_cart`, `spice_sacks`, bolovanii, lespedea | pereți cu masă (brief: „tarabele sunt pereți cu masă, nu decor fantomă"); zidul e un bloc plin, hull = zidul (brief-ul zicea `mesh` pentru zid: pe un corp convex e identic, și mai ieftin) |
| `mesh` | `fort_gate_jai/fateh/loha`, `market_gate` | se TRECE prin ele: hull-ul ar umple golul și ar face zid peste drum |
| `trunk` | `neem_tree`, `khejri_tree` (+ `euphorbia` existent) | coroana depășește masiv baza |
| `none` | `stepwell_flight_module`, `stepwell_corner`, `stepwell_pavilion` | contract (kit §1.3): coliziunea e a terenului (`TerrainHollow`), modulele sunt decor lipit de perete |
| `none` | `baraat_horse`, `baraat_band`, `peacock_closed/fanned`, `langur`, `black_kite_bird`, `zipline_rider`, `zebu_cow` | teatru / figuranți (brief §3, §8: procesiunea e fără coliziune); vaca își face singură cutia în `CowGate` |
| `none` | `diya`, `floating_diya`, `marigold_garland`, `textile_strip`, `rampart_cannon` | sub linia capotei sau deasupra benzii; tunul e `none` prin contract (kit §1.2) |
| `none` | `rooftop_tank`, `rooftop_clutter`, `tuktuk`, `jodhpur_horizon` | pe acoperișuri (niciodată atinse — corpuri inutile); tuk-tuk-ul e `Car`, nu decor; orizontul e fundal |

## 4. Porțile cetății față de drumul din E (punctul 3c)

### 4.1 Golul, măsurat ca GOL

`ProbeJodPorti`: triunghiurile TUTUROR nodurilor vizibile (piatră + canaturi
deschise + glow), proiectate pe planul lateral × înălțime, rasterizate pe 1 cm;
banda liberă care conține axa pe fereastra caroseriei **0,15..2,00 m**; cheia
= cea mai joasă cotă ocupată pe |lat| ≤ 0,3 m.

| poartă | gol (m) | lateral | cheie (m) | lățime totală (m) |
|---|---:|---|---:|---:|
| `fort_gate_jai` | **7,160** | −3,58 .. +3,58 | **9,353** | 32,74 |
| `fort_gate_fateh` | 7,160 | idem | 9,353 | 32,74 |
| `fort_gate_loha` | 7,160 | idem | 9,353 | 32,74 |
| `market_gate` | **18,390** | −9,196 .. +9,194 | **11,342** | 40,35 |

Confirmă independent inventarul (`fort3`: 7,156 / 9,351; `market_gate` 18,40
/ 11,60 — cheia porții pieței iese **11,34, nu 11,60**: diferența e fereastra
de ±0,3 m pe panta arcului ascuțit, ca la `fort2`; tot ≥ 11,0).

### 4.2 Unde încap pe E (0,470..0,590)

Profilul terenului real (raycast pe corpuri, nu sampler-ul) sub amprenta
turnurilor, față de cota drumului, și locul rămas față de ORICE alt braț al
zigzagului (puncte la > 40 m pe traseu, marginea lor de asfalt). Semilățimea e
`width_at(frac)`. Extras (tot tabelul în log-ul sondei):

| frac | semi | rază (m) | pantă | teren sub turnuri, scara 1,0 (st / dr, min..max) | loc față de alt braț, 1,0 / 1,3 (st, dr) |
|---|---:|---:|---:|---|---|
| 0,486 | **6,1** | 468 | 6,1% | −0,6..+0,2 / −0,6..+0,3 | 29 / 22 — 29 / 21 |
| 0,508 | 4,5 | 118–219 | 8,6% | −0,6..+1,8 / −1,3..+0,3 | 15 / 15 — 12 / 12 |
| 0,530 | 4,5 | 426 (scurt) | 9,9% | −1,5..+0,4 / −0,7..+1,3 | 15 / 17 — 13 / 16 |
| 0,552 | 4,5 | 50–65 | 10,7% | −0,7..+2,0 / −2,1..+0,4 | 15 / 14 — 11 / 10 |
| 0,572 | 4,5 | 366–1109 | 9,3% | −1,8..+0,4 / −0,7..+0,4 | 14 / 30 — 10 / 29 |

Acele în unghi drept (raza 12–15 m) sunt la 0,498, 0,518–0,522, 0,542,
0,558–0,566. Dreptele de după ele (unde se pune poarta: „fiecare după un ac")
sunt la **0,506–0,510**, **0,530**, **0,550–0,554** și **0,570–0,578**.

**Ce încape:**

- **Turnurile NU intră în alt braț al zigzagului**, nici la scara 1,3: cel mai
  mic loc rămas e **10,0 m** (0,552, dreapta, la 1,3). Brațele sunt la
  ≥ 22 m ax la ax (ProbeLayout), deci porțile de 32,7 m (și 42,6 m) au loc.
- **Taluzul e mic:** terenul sub amprenta turnurilor stă la −2,1..+2,0 m față
  de drum pe toate dreptele de mai sus (la 1,3: −3,4..+4,7 m, cel mai rău la
  0,550 dreapta). Adică **terenul a fost netezit de drum pe o bandă largă**,
  iar un turn de poartă se așază cu baza la cota drumului și se îngroapă
  ≤ 2 m în partea de deal / are nevoie de ≤ 2–3 m de soclu îngropat în partea
  de vale. Nu se taie nimic din piesă.
- **Adâncimea porții** (8,64 m la 1,0, 11,2 m la 1,3) cere o dreaptă de cel
  puțin atât: 0,530 e cea mai scurtă (un singur eșantion drept, ~8 m, între
  ace de 31 și 53 m) — poarta de acolo stă pe o curbă ușoară.

**Ce NU încape — premisa din brief e contradictorie:** brief §2 rândul E cere
**semilățimea 4,5 m la porți (drum de 9,0 m)** și **„poarta are 7 m liber"**
în aceeași celulă. La scara 1,0 golul e **7,16 m < 9,0 m**: ușciorii intră
**0,92 m pe fiecare parte a asfaltului**. Pe deasupra, **cheia 9,35 m e sub
camera de joc**: `ChaseCamera` stă la 10 m sus, 12,5 m în spate; pe panta de
~10% a lui E, când camera trece prin planul porții mașina e cu ~1,2 m mai sus,
deci camera e la **~11,2 m** peste pragul porții — prin piatra de deasupra
arcului (kitul cerea cheia ≥ 11 m exact pentru `market_gate` din acest motiv;
la porțile cetății s-a cerut doar ≥ 9 m).

**Propunerea (scară uniformă 1,30, rotație pe tangentă):**

| | scara 1,00 | **scara 1,30** |
|---|---:|---:|
| gol | 7,16 m (< drumul de 9,0) | **9,31 m** (drumul + 0,15 pe parte) |
| cheie | 9,35 m (< camera, ~11,2) | **12,16 m** (> camera, marjă ~0,9 m) |
| lățime / înălțime Jai | 32,7 / 16,3 m | 42,6 / 21,2 m |
| loc minim față de alt braț | 13,8 m | 10,0 m |

- Rotația: axa X a porții pe tangenta drumului (`basis.x = tangent`,
  `basis.z = stânga`), baza la cota drumului din centru, coborâtă 0,3 m.
- Pozițiile propuse: **Jai 0,508**, **Fateh 0,530** (sau 0,552 dacă dreapta
  scurtă de la 0,530 strică adâncimea), **Loha 0,572**. **Nu Jai la
  0,482–0,490**: acolo drumul are semilățimea 5,5–6,5 (11–13 m), mai mare
  decât orice gol.
- **Alternativa care păstrează „dopul" de 7 m din brief:** scara 1,0 +
  `custom_width_segments` îngustat la **3,5** pe ±6 m în jurul fiecărei porți
  (ușciorii în linie cu marginea, nu în drum) + `CameraZone` cu `ceiling`
  ≤ 9 m pe poartă. Mai mult cod, și AI-ul nu vede decorul static (memoria
  `obstacol-pe-drum-poate-fi-gimmick`), deci îngustarea trebuie să fie a
  DRUMULUI, nu a decorului. Recomand 1,30: „dopul" rămâne virajul în unghi
  drept + tuk-tuk-ul din poartă, nu ușciorul.
- Nimic nu e montat în scenă ca decor final (task-ul cere doar contractul);
  POI E decide între cele două.

## 5. Premise din brief / inventar găsite false la măsurătoare

| unde | scria | măsurat |
|---|---|---|
| brief §2 E | poarta 7 m liber ȘI drumul 4,5 semi (9 m) | contradicție: ușciorii intră 0,92 m în asfalt pe fiecare parte (§4) |
| brief §5.2 / kit §1.2 | porțile ~26 × 14 m | 32,74 m lățime, 14,2–16,5 m înălțime (abatere declarată în PR #424) |
| kit §1.2 | cheia ≥ 9 m ajunge | camera de joc trece la ~11,2 m peste prag pe panta lui E → cheia 9,35 e sub cameră |
| inventar `market_gate` | cheia 11,60 | 11,34 (fereastra ±0,3 m pe arcul ascuțit) |
| kit §1.2 `fort_wall_turret` | 4,5 × 4,5 m | 7,50 × 7,50 m la bază (AABB cu soclul), 16,98 m înalt |
| kit §1.6 `peacock_fanned` | evantai 1,6 × 1,4 | 1,60 × 1,00 m |
| `plants/euphorbia.glb` | piesă nouă | același stem ca `serengeti/plants/euphorbia.glb` → moștenea mapările Serengeti |
| kit §1.4 „≤ 300 tri pe casă simplă" | | casele au **4 430–5 932 tri** (decizii ale dezvoltatorului pe fidelitate, PR #424) → orașul-umplutură de ~1000 case ar fi ~5M tri; vezi pasul 5 |
| kit §1.4 `House_Wall` pe `FOAM_WHITE` | | a/b/c au accente pe ACELAȘI nod (obloane 9 15%, plantă 12, rezervor 28 până la 18%) → ruptură de accente obligatorie înainte de clasă (pasul 2) |

## 6. Linia de bază a gărzilor (starea curată, înainte de fundație)

| gardă | număr | rezultat |
|---|---|---|
| `probe_decor --track=17` | scenă | 16 materiale, 126 prop-uri, 77 638 tri, OK |
| `probe_manual --track=17` | scenă | „nicio pistă nu are DecorManual" (nimic de verificat) |
| `ProbeBuried --track=10` | index | 0 îngropate, 0 tavane (principal + Ulicioara) |
| `ProbeLayout --track=10` | index | OK — 2042,0 m; rază min 7,3 m @0,20; pantă max 14,2% @0,88; apropiere de sine 22,0 m @0,15 |
| `ProbeLaneClear --track=10` | index | 28 blocate, **nearmată** (pistă fără linie de bază → exit 0) — toate 28 pe `AlleyGatePostA/B` (poarta de 4 m a ulicioarei, gimmick) |
| `ProbeJodTuk` | — | TRECUT: Poliția 24,6%, Autobuzul 9,2% la 30 m/s bot-în-spate, 12/12 valori distincte, redresat 2,50 s, în mers 3,43 s |

## 7. Gărzile pe scena integrată (după pașii 2–5 ai fundației)

`--track=17` = numărul de scenă (doar `probe_decor` și `probe_manual`),
`--track=10` = indexul din `GameState` (restul). ProbeRace cu 6 mașini (implicitul
sondei), 150 s, seed 1..8.

| gardă | înainte (4ac84517) | după fundație | notă |
|---|---|---|---|
| `probe_decor --track=17` | 16 materiale, 126 prop-uri, 77 638 tri | **12 materiale**, 1179 prop-uri / 202 desene, 2 884 254 tri | −5: vaca placeholder (2) și fundalul procedural; +1: `blue_lime_indigo` (restul claselor noi nu apar încă: nicio piesă de fort/fântână/stâncă în scenă). Plafonul veto e 38 |
| `probe_manual --track=17` | fără DecorManual | DecorManual, 0 obiecte, OK | zonele sunt goale |
| `ProbeBuried --track=10` | 0 / 0 | 0 / 0 | |
| `ProbeLayout --track=10` | OK | OK, neschimbat | rază min 7,3 m @0,20 (acul fântânii) și pantă 14,2% @0,88 — sonda le trece |
| `ProbeLaneClear --track=10` | 28, **nearmată** (exit 0) | **armată la 28**; sabotaj 34 → REGRESIE, exit 1 | toate 28 pe `AlleyGatePostA/B` |
| `ProbeJodClase --track=10` | — | OK, 6 materiale pe kit; sabotaj → exit 1 | nou |
| `ProbeJodOrizont --track=10` | — | 10/10 siluete, FarCity_A pe `blue_lime_light`, umbră stinsă | nou |
| `ProbeJodTukModel` | — | TRECUT (tuktuk.glb, 3 roți la sol, bot înainte) | nou |
| `ProbeJodTuk` | TRECUT 24,6% / 9,2% | identic la bit | fizica nu citește mesh-ul (raza 0,22 în ambele) |
| `sv_hazard_orient --scene=17 --decor` | — | „0 noduri suspecte" — **pe zero măsurători** | Track17 n-are `Hazarduri`, iar DecorManual e gol: garda nu are încă ce măsura |

**ProbeRace --mode=race --track=10 --seconds=150, seed 1..8:**

| | fără trafic (`--traffic=0`) | cu trafic (`--traffic=6`) | fără trafic, vaca placeholder (A/B) |
|---|---:|---:|---:|
| repuneri (total 8 seed-uri) | 4 | 10 | 5 |
| `[blocaj]` | 2 | 2 | 2 |
| lent (s, sumă) | 212,8 | 225,7 | 213,3 |
| invers (s, sumă) | 41,0 | 46,4 | 40,8 |
| carusel | 0 | 0 | 0 |
| tururi medii în 150 s | 1,927 | 1,913 | 1,926 |

- Cele 2 `[blocaj]` sunt la **acul fântânii** (frac 0,196–0,199, Pompierii /
  Autobuzul ieșiți lateral 7–8 m, ating `TerrainBody`/umerii) — geometrie de
  traseu, nu decor.
- Repunerile se strâng la **0,347–0,350** (poz ≈ (−169, 8, −87)) = furca
  ulicioarei: 3 fără trafic, **9 cu trafic** (seed 2: 5). A/B cu vaca
  placeholder dă același tipar (4 la 0,347–0,350), deci **nu vine din
  `zebu_cow.glb`**; e preexistent și îl amplifică traficul. De văzut la POI D.
- Felia 0,95–1,00 „40% lent" pe toate seed-urile e grila de start (plecarea
  de pe loc intră în felie), identică cu și fără trafic.
- Costul traficului: −0,014 tururi în 150 s (~−0,7%, ~0,5 s pe tur) —
  în ținta brief-ului (+2…+5 s pe cursă).
