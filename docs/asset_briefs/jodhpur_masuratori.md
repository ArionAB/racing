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

## 8. Trecerea de lumină (ramura `jodhpur/poi-lumina`)

Comanda (cere fereastră; capturile serial):

```
Godot_v4.7-stable_win64_console.exe --path . --resolution 1280x720 res://tools/ProbeJodLumina.tscn -- --guard
    [--indigo=0.2] [--out=res://snapshots/jod_lumina/x]
```

Masca e **de clasă**, randată pe GPU pe același cadru (trecere de ID pe lume
înghețată, eroziune 3×3): var deschis, indigo, sol (teren ≤ 30°), stâncă
(teren > 30°), drum. 4 vederi × 5 eșantioane (ochi deplasat ±6 m sau 5 fracții
de joc). Celulele: **H / S (HSV a culorii medii) / L (luma Rec.601, 0–100)**,
la amestecul scenei (indigo 40%).

**F pe brațul de intrare (0,59–0,62) nu vede orașul**: `--scan` dă sub 6 000 px
de case pe cadru acolo (urcarea privește spre SV). Orașul intră în cadru la
vârful bastionului, 0,64–0,665 (până la 36 000 px); acolo e `F_joc`.

| vedere | dusk | var ÎNAINTE | indigo ÎNAINTE | sol ÎNAINTE | drum ÎNAINTE | luma cadru ÎNAINTE | var DUPĂ | indigo DUPĂ | sol DUPĂ | drum DUPĂ | luma cadru DUPĂ |
|---|---|---|---|---|---|---|---|---|---|---|---|
| D_ochi | 0,0 | 26 / 0.40 / 27 | 281 / 0.18 / 14 | 26 / 0.76 / 34 | — | 50 | 221 / 0.39 / 33 | 227 / 0.70 / 18 | 22 / 0.27 / 39 | — | 53 |
| D_ochi | 0,5 | 248 / 0.55 / 24 | 240 / 0.75 / 12 | 321 / 0.38 / 27 | — | 46 | 226 / 0.42 / 29 | 229 / 0.72 / 15 | 14 / 0.22 / 33 | — | 49 |
| D_ochi | 1,0 | 225 / 0.74 / 24 | 229 / 0.91 / 13 | 232 / 0.36 / 27 | — | 45 | 222 / 0.56 / 20 | 227 / 0.83 / 10 | 9 / 0.14 / 23 | — | 42 |
| D_joc | 0,0 | 27 / 0.43 / 30 | 5 / 0.23 / 21 | 26 / 0.76 / 34 | 16 / 0.65 / 16 | 33 | 224 / 0.32 / 38 | 231 / 0.46 / 29 | 22 / 0.28 / 40 | 341 / 0.25 / 19 | 38 |
| D_joc | 0,5 | 250 / 0.51 / 27 | 244 / 0.64 / 19 | 320 / 0.38 / 27 | 282 / 0.56 / 10 | 27 | 230 / 0.34 / 33 | 236 / 0.48 / 24 | 13 / 0.21 / 33 | 283 / 0.28 / 13 | 32 |
| D_joc | 1,0 | 225 / 0.72 / 25 | 229 / 0.86 / 16 | 232 / 0.36 / 27 | 238 / 0.56 / 11 | 26 | 223 / 0.51 / 21 | 228 / 0.72 / 13 | 7 / 0.14 / 22 | 263 / 0.37 / 8 | 23 |
| F_joc | 0,0 | 28 / 0.46 / 48 | 23 / 0.42 / 43 | 27 / 0.72 / 41 | 13 / 0.61 / 14 | 40 | 224 / 0.31 / 47 | 227 / 0.42 / 39 | 22 / 0.29 / 46 | 318 / 0.23 / 17 | 42 |
| F_joc | 0,5 | 261 / 0.39 / 41 | 260 / 0.44 / 36 | 325 / 0.39 / 32 | 284 / 0.57 / 10 | 34 | 229 / 0.27 / 44 | 232 / 0.34 / 38 | 10 / 0.23 / 38 | 286 / 0.31 / 13 | 37 |
| F_joc | 1,0 | 226 / 0.68 / 29 | 228 / 0.75 / 23 | 231 / 0.37 / 29 | 238 / 0.59 / 10 | 31 | 228 / 0.40 / 25 | 234 / 0.48 / 20 | 0 / 0.11 / 25 | 258 / 0.42 / 8 | 28 |
| F_ochi | 0,0 | 28 / 0.45 / 42 | 23 / 0.43 / 44 | 27 / 0.70 / 43 | 13 / 0.59 / 15 | 53 | 223 / 0.33 / 43 | 227 / 0.41 / 39 | 19 / 0.24 / 47 | 315 / 0.23 / 17 | 53 |
| F_ochi | 0,5 | 257 / 0.43 / 36 | 260 / 0.43 / 37 | 321 / 0.36 / 34 | 284 / 0.55 / 11 | 48 | 228 / 0.31 / 40 | 233 / 0.33 / 39 | 7 / 0.19 / 39 | 286 / 0.30 / 13 | 50 |
| F_ochi | 1,0 | 225 / 0.69 / 28 | 228 / 0.74 / 23 | 231 / 0.39 / 30 | 239 / 0.58 / 11 | 45 | 225 / 0.44 / 24 | 234 / 0.47 / 20 | 352 / 0.11 / 25 | 260 / 0.41 / 8 | 42 |

Ce s-a schimbat (motivul: albastrul vine din albedo, nu din lumină; lumina
rămâne aproape neutră în spațiul liniar, B/R ~0,9–1,2):

| fază | soare | ambient | ceață |
|---|---|---|---|
| 0 (tema) | `#FFB27A` → `#FFBC8C`, 1,0 | `#FFB27A` 0,30 → `#CAC0C4` 0,42 | `#E8A878` → `#8A94B8`, `fog_sun_scatter` 0,8 |
| 0,5 | `#FF8FA0` → `#FFA090`, 0,60 | `#B98FC0` 0,40 → `#BEB0B8` 0,42 | `#9A7FA8` → `#8A8CA0`, scatter 0,4 |
| 1 | `#8E9BD6` 0,32 → `#A4A0B4` 0,30 | `#8E9BD6` 0,45 → `#8A8690` 0,45 | `#3E4A7A` → `#45424E`, scatter 0 |

Respinse, măsurat: ambient albastru-rece `#9FA9D6` (varul H 224, dar nisipul H
280 S 0,14); ceață caldă `#B8A4A8` (orașul de pe F H 246 S 0,13 — la 150–300 m
e 50–70% ceață); ceață albastru-deschis `#ADB0C6` fără scatter (stânca
îndepărtată de pe D H 264). Garda: `--guard` pe valorile vechi → 21 de abateri,
exit 1; pe cele noi → OK. `probe_decor --track=17`: 12 materiale (neschimbat).
Planșele: `docs/track_briefs/img/jodhpur_lumina/`.

**Ce nu s-a atins:** asfaltul noaptea rămâne violet foarte închis (H 258–263,
S 0,37–0,42, L 8): albedo-ul drumului, nu lumina (la lumină neutră iese tot
H 264–271); materialele drumului nu se ating aici. Cerul (`sky_top`/`sky_horizon`)
nu e canal al `DuskCycle`, deci noaptea cerul rămâne violet-portocaliu la orizont.

## 9. Luminile de Diwali (ramura `jodhpur/poi-lumini`)

Critica oarbă pe C, E și H, de două ori la rând: luminile „lipsesc complet”.
Sursele existau (2 298 de candele, 2 319 becuri, 38 de felinare, 128 de lămpi
de fort), dar citeau ca „romburi portocalii plate” sau „discuri maro”: diya e
100 % lut (sloturile 23 + 10), fără slot de flacără; becul era o bipiramidă
emisivă fără halou; ferestrele `*_Glow` erau slotul 20 pe atlas, nelegate de
ceas. **Fără glow/bloom și fără OmniLight** (decizia dezvoltatorului din 30 sep).

| mecanism | unde | cost |
|---|---|---|
| `LampHalo` + `lamp_halo.gdshader`: billboard ADITIV, cădere continuă `(1-d)^3`, miez care se albește spre centru; per instanță culoare, rază miez/halou, alungire, fază de pâlpâire | candele (`FlockProp.halo_enabled`, flacăra la `(0; 0,075; 0)` în spațiul piesei), becuri, felinare, lămpile fortului | **+1 material** pentru toate |
| tăierea din brief §6: între 45 și 60 m pătratul se strânge la miez; miezul are minim 0,0022 rad (~1,2 px la 720p) ca să nu clipească | în shader, nu în disciplină | overdraw-ul scade odată cu raza |
| `jod_window.gdshader` (`shader:jod_window`): albedo-ul atlasului + emisie caldă `smoothstep(t0, t0+0,08, dusk_lamps)` | toate `*_Glow` (case, haveli, turn + cadran, poartă de piață, 3 porți de fort, zid, turn de zid, fațadele palatului, pavilionul fântânii, `FarCity_A_Glow`) | **+1 material** |
| decaluri doar-emisie (gradient radial) pe fațadele primului rând de pe H, pas 7 m, `normal_fade` 0,5, stinse la 55–75 m; energia urcă cu `DuskCycle.lamps_value` (×0,3 la apus → ×1 noaptea) | `StreetLights.facade_wash` (31 de decaluri) | 0 materiale; o proiecție pe pixelii atinși, sub plafonul mobil de 8 decaluri/mesh |

**Pragurile ferestrelor.** Brief-ul: turul 1 soare jos, turul 2 se aprind
lămpile. `dusk_lamps` = 0,15 → 0,6 → 1,0, deci turul 2 (dusk 0,33–0,67) e
`dusk_lamps` ≈ 0,45–0,73. Fiecare clădire își trage pragul `t0` din hash-ul
poziției în [0,40; 0,70], cu tranziție de 0,08: prima casă începe la 0,40
(dusk ≈ 0,28, finalul turului 1), ultima e plină la 0,78 (dusk ≈ 0,6). La
dusk 0 (0,15) toate sunt stinse, la dusk 0,5 (0,6) ~40 % ard plin și încă ~27 % sunt în tranziție, la
dusk 1 ard toate cu excepția a 12 % (`off_ratio`, case rămase stinse: un oraș
cu toate ferestrele aprinse citește a carton), cu intensitate 0,65–1,15 între
case. Candelele și becurile de Diwali ard de la dusk 0 (e Diwali, bara le
arată aprinse la apus); doar haloul lor crește cu noaptea (×0,45 → ×1), fiindcă
un halou plin peste cerul de apus spală fundalul.

**Costul halourilor pe cadru** (`snapshot.gd` → `HALO:`, aceeași formulă de
rază ca shaderul, dusk 1, camera de joc 1280×720):

| cadru | instanțe în frustum | cu halou întreg (< 45 m) | pixeli acoperiți | overdraw aditiv |
|---|---|---|---|---|
| C 0,160 (candelele) | 4 131 (1 718 candele) | 465 | 391 523 | 0,42 ecrane |
| E 0,505 (porțile) | 92 | 25 | 129 356 | 0,14 ecrane |
| H 0,950 (ghirlandele, cel mai rău) | 3 569 (1 251 becuri) | 684 | 714 685 | **0,78 ecrane** |

Fragmentul e fără textură (o lungime, un cub, un smoothstep), deci 0,78
ecrane înseamnă sub un ecran de umplere ieftină pe cadrul cel mai rău. Pe H,
80 % din pixeli vin din becurile de pe sfori. Dacă device-ul nu ține: întâi
`halo_far_begin/end` 45/60 → 30/40, apoi `bulb_halo_m` 0,6 → 0,4.

**Lumina caldă pe fațade, A/B pe lume înghețată** (H 0,950, dusk 1,
`--no-facade-wash`): 13,8 % din cadru se schimbă; pe pixelii atinși, fațada
stângă trece de la H 354 / S 0,15 / V 0,46, R−B +16 la H 16 / S 0,35 / V 0,61,
R−B +54, iar cea dreaptă de la H 258 / V 0,40, R−B −12 la H 11 / V 0,60,
R−B +52. Adică varul rece din spatele ghirlandelor capătă pata caldă a
becurilor; departe de sfori rămâne albastru.

**Gărzile:** `ProbeJodLumina --guard` OK (ferestrele aprinse nu mută
măștile de clasă peste praguri); `probe_decor --track=17` **22 de materiale**
(20 → 22: halou + ferestre), OK; `probe_manual --track=17`, `ProbeBuried`,
`ProbeLaneClear` (31, exact baza) OK.

**Baza, măsurată pe codul din 84e4c308** (fișierele scoase temporar în
worktree, apoi restaurate): Track17 avea 20 de materiale și 769 de desene; acum
22 și 820 (+51: pătratele de halou, decalurile și părțile `jod_window` ale
caselor din `CityFill`). **Neutralitatea:** `probe_decor` pe Track12, 14 și 16
identic la cifră (32/31/30 de materiale, aceleași desene și triunghiuri) cu și
fără schimbare. **ProbeRace, 8 seed-uri:** 10 repuneri acum față de 11 pe bază
(0/3/3/0/1/2/0/1 față de 1/5/1/0/1/2/0/1), zero `[blocaj]` în ambele; aceeași
distribuție, fără nimic fizic atins (halourile și decalurile n-au corp).

## 10. A doua trecere de lumină, „cald + albastru” (ramura `jodhpur/poi-lumina2`)

Criticii orbi din gauntletul pe POI-uri au numit de 9 ori „lumina rece de
apus” ca diferență nereparabilă din decor (H ×4, A, D ×2, D′, F). Cererea
dezvoltatorului: apus mai portocaliu/saturat (soarele și cerul), gresia și
solul calde, casele rămân albastre. Garda `ProbeJodLumina --guard` e aceeași
(varul H 195–230, S ≥ 0,25 la dusk 0; sol/stâncă calde).

**Măsurătoarea:** `ProbeJodLumina --fracs=0.02,0.198,0.38,r1:0.360,0.505,0.67,0.95`
(camera de joc pe 5 eșantioane ±0,004 în jurul cadrului-erou; `r1:` = ruta 1,
ulicioara). Sonda are acum două clase doar măsurate, `gresie`
(`red_sandstone` + `rose_sandstone`) și `cer`; `_verdict` nu le citește, deci
garda nu s-a schimbat. „Înainte” = aceeași sondă pe lumina integrării
0feda59e (fișierele de scenă scoase temporar, apoi reaplicate).
Celule: **H / S / L** (HSV al culorii medii pe mască; L = luma 0–100). Pe E
varul are sub 7 000 px (poarta ascunde orașul), deci rândul lui nu contează.

| POI | dusk | var | gresie | sol | cer | luma cadru |
|---|---|---|---|---|---|---|
| A 0,020 | 0,0 | 225 / 0.29 / 42 → **228 / 0.32 / 42** | 13 / 0.73 / 39 → **9 / 0.74 / 36** | 19 / 0.25 / 43 → **18 / 0.43 / 44** | 23 / 0.32 / 84 → **19 / 0.59 / 69** | 35.9 → **35.3** |
| A 0,020 | 0,5 | 232 / 0.32 / 35 → **232 / 0.35 / 37** | 6 / 0.73 / 30 → **5 / 0.74 / 30** | 7 / 0.19 / 36 → **15 / 0.39 / 38** | 25 / 0.35 / 84 → **13 / 0.62 / 64** | 30.6 → **31.0** |
| A 0,020 | 1,0 | 223 / 0.50 / 22 → **223 / 0.50 / 22** | 3 / 0.60 / 18 → **3 / 0.60 / 18** | 355 / 0.12 / 23 → **18 / 0.41 / 23** | 26 / 0.40 / 82 → **305 / 0.45 / 25** | 23.2 → **21.6** |
| C 0,198 | 0,0 | 227 / 0.24 / 45 → **235 / 0.26 / 45** | 16 / 0.61 / 40 → **14 / 0.57 / 42** | 13 / 0.33 / 39 → **15 / 0.37 / 42** | 16 / 0.29 / 82 → **12 / 0.54 / 68** | 34.0 → **35.0** |
| C 0,198 | 0,5 | 237 / 0.29 / 38 → **238 / 0.31 / 38** | 13 / 0.61 / 35 → **11 / 0.57 / 37** | 8 / 0.32 / 35 → **12 / 0.37 / 38** | 18 / 0.31 / 82 → **6 / 0.56 / 63** | 31.1 → **32.0** |
| C 0,198 | 1,0 | 223 / 0.50 / 24 → **223 / 0.51 / 24** | 14 / 0.57 / 25 → **14 / 0.58 / 25** | 5 / 0.29 / 23 → **14 / 0.41 / 23** | 20 / 0.36 / 79 → **299 / 0.44 / 24** | 24.7 → **22.9** |
| D 0,380 | 0,0 | 224 / 0.31 / 38 → **227 / 0.35 / 40** | 281 / 0.10 / 74 → **305 / 0.13 / 72** | 12 / 0.15 / 42 → **18 / 0.34 / 45** | 22 / 0.31 / 84 → **17 / 0.58 / 69** | 31.1 → **31.4** |
| D 0,380 | 0,5 | 229 / 0.37 / 32 → **229 / 0.41 / 34** | 282 / 0.11 / 68 → **309 / 0.12 / 68** | 1 / 0.14 / 38 → **14 / 0.33 / 40** | 23 / 0.34 / 83 → **11 / 0.61 / 64** | 28.0 → **28.1** |
| D 0,380 | 1,0 | 223 / 0.52 / 21 → **223 / 0.52 / 21** | 271 / 0.20 / 31 → **270 / 0.20 / 30** | 345 / 0.11 / 24 → **16 / 0.37 / 24** | 25 / 0.39 / 81 → **304 / 0.45 / 25** | 21.5 → **17.4** |
| D′ r1 0,360 | 0,0 | 221 / 0.42 / 32 → **221 / 0.47 / 36** | 7 / 0.56 / 27 → **5 / 0.53 / 29** | 20 / 0.22 / 38 → **21 / 0.41 / 40** | 24 / 0.26 / 87 → **18 / 0.53 / 72** | 31.7 → **32.4** |
| D′ r1 0,360 | 0,5 | 225 / 0.44 / 29 → **225 / 0.48 / 32** | 4 / 0.57 / 24 → **2 / 0.54 / 26** | 11 / 0.19 / 33 → **18 / 0.40 / 36** | 17 / 0.31 / 82 → **8 / 0.57 / 64** | 28.0 → **28.5** |
| D′ r1 0,360 | 1,0 | 222 / 0.54 / 20 → **222 / 0.54 / 20** | 2 / 0.58 / 15 → **3 / 0.58 / 15** | 2 / 0.12 / 22 → **20 / 0.45 / 22** | 20 / 0.35 / 77 → **300 / 0.44 / 24** | 20.7 → **16.3** |
| E 0,505 | 0,0 | 0 / 0.11 / 63 → **342 / 0.15 / 60** | 12 / 0.69 / 35 → **8 / 0.67 / 35** | 18 / 0.39 / 41 → **19 / 0.44 / 44** | 22 / 0.31 / 83 → **17 / 0.58 / 69** | 35.2 → **35.5** |
| E 0,505 | 0,5 | 8 / 0.21 / 59 → **357 / 0.18 / 58** | 7 / 0.68 / 28 → **5 / 0.66 / 30** | 15 / 0.39 / 37 → **17 / 0.44 / 40** | 24 / 0.34 / 82 → **12 / 0.60 / 64** | 30.4 → **31.3** |
| E 0,505 | 1,0 | 24 / 0.35 / 59 → **24 / 0.34 / 58** | 6 / 0.61 / 19 → **7 / 0.62 / 19** | 18 / 0.38 / 28 → **22 / 0.49 / 28** | 26 / 0.39 / 80 → **311 / 0.43 / 26** | 23.4 → **22.4** |
| F 0,670 | 0,0 | 221 / 0.40 / 34 → **222 / 0.44 / 37** | 8 / 0.65 / 24 → **6 / 0.60 / 27** | 14 / 0.32 / 47 → **15 / 0.38 / 49** | 24 / 0.26 / 83 → **17 / 0.49 / 69** | 39.2 → **37.4** |
| F 0,670 | 0,5 | 225 / 0.42 / 30 → **225 / 0.46 / 33** | 6 / 0.65 / 21 → **4 / 0.61 / 23** | 6 / 0.30 / 40 → **11 / 0.37 / 43** | 20 / 0.29 / 78 → **12 / 0.54 / 62** | 33.7 → **32.3** |
| F 0,670 | 1,0 | 222 / 0.53 / 20 → **222 / 0.53 / 20** | 4 / 0.63 / 15 → **5 / 0.64 / 14** | 360 / 0.25 / 25 → **12 / 0.38 / 25** | 22 / 0.34 / 72 → **302 / 0.38 / 24** | 25.5 → **17.3** |
| H 0,950 | 0,0 | 238 / 0.14 / 48 → **257 / 0.20 / 45** | 4 / 0.51 / 50 → **360 / 0.52 / 47** | 333 / 0.09 / 50 → **2 / 0.19 / 51** | 22 / 0.32 / 84 → **18 / 0.59 / 69** | 41.0 → **39.9** |
| H 0,950 | 0,5 | 248 / 0.27 / 37 → **250 / 0.30 / 37** | 358 / 0.47 / 44 → **357 / 0.49 / 43** | 331 / 0.09 / 46 → **2 / 0.18 / 48** | 24 / 0.35 / 84 → **12 / 0.62 / 64** | 37.5 → **36.8** |
| H 0,950 | 1,0 | 224 / 0.50 / 24 → **224 / 0.50 / 23** | 353 / 0.42 / 25 → **352 / 0.42 / 24** | 329 / 0.12 / 27 → **5 / 0.25 / 27** | 26 / 0.40 / 81 → **305 / 0.45 / 25** | 32.5 → **28.1** |


**Ce s-a schimbat și de ce:**

| pârghie | înainte | după | de ce |
|---|---|---|---|
| soare (dusk 0 / 0,5) | `#FFBC8C` 1,0 / `#FFA090` 0,60 | `#FF9050` 0,85 / `#FF7A50` 0,55 | apus portocaliu saturat; mai slab ca să nu spele varul |
| ambient (0 / 0,5) | `#CAC0C4` 0,42 / `#BEB0B8` 0,42 | `#C8C4D0` 0,50 / `#BEB4C4` 0,48 | umplerea mai tare ține fațadele albastre sub soarele portocaliu |
| cer (tema, dusk 0) | top (0,42; 0,35; 0,62), orizont (1,0; 0,70; 0,48) | top (0,55; 0,28; 0,50), orizont (1,0; 0,48; 0,22) | cer de apus portocaliu → magenta |
| cer (DuskCycle, canal nou) | fix pe temă (noaptea rămânea apus, L 72–82) | chei 0,5 `#5A3A78` / `#F06A3A`, 1 `#1A1834` / `#4A2E44` | noaptea cerul se închide (L 24–26) |
| discul soarelui | `sun_angle_max` 30° fix | 30 → 18 → 0° | pata întunecată (vezi mai jos) |
| `fog_sky_affect` | 0,15 | 0,08 | ceața albastră spală mai puțin cerul |
| `fog_sun_scatter` | 0,8 / 0,4 / 0 | 1,0 / 0,6 / 0 | ceața spre soare (D, A) mai caldă |
| sol `ground_tint` | (0,62; 0,56; 0,46) | (0,78; 0,50; 0,30) | nisip ocru, nu gri-bej |
| sol pe zone (fântâna / fortul + G) | (1,0; 0,68; 0,62) / (0,73; 0,51; 0,47) | (1,0; 0,64; 0,50) / (0,80; 0,50; 0,38) | solul de pe F ieșea roz-gri (H 355, S 0,19) |
| `scarp_tint` | (0,42; 0,30; 0,27) | (0,46; 0,30; 0,24) | stânca în aceeași familie caldă |

Tenta gresiei (`red_sandstone`/`rose_sandstone`) NU s-a atins: gresia era deja
caldă (H 2–16, S 0,51–0,74) și rămâne (H 0–14, S 0,52–0,74); o tentă mai
saturată fusese respinsă de critic pe E.

**Respinse, măsurat:** ceață mov-caldă `#9690B0` (orașul de pe F: H 239–240,
S 0,22–0,23 — garda pică, 2 abateri); soare `#FF9E5C` la energie 1,0 cu
ambientul vechi (F_joc var S 0,24, F_ochi 0,23 — pică). Ceața rămâne
`#8A94B8`: orașul văzut de pe bastion stă la 150–300 m, adică 50–70 % ceață,
iar albastrul lui e în mare parte albastrul ceții.

**Pata întunecată de pe cer (dusk 0,5–1):** `ProceduralSkyMaterial`
*amestecă* cerul spre `culoarea × energia` soarelui pe 30° în jurul lui, nu
adună. Când soarele scade la 0,30 (luna gri-lilă), discul iese mai închis
decât orizontul: o pată gri-albăstruie de ~30° deasupra lui (F 0,670 și D′ în
planșa dusk 1, coloana „înainte”; urma ei și pe F la dusk 0,5). Raza scade
acum cu ceasul (30 → 18 → 0°); pe captura F la dusk 1 pata dispare (luma pe
coloanele de cer, rândurile 5–60: 80–213 înainte, 41–83 după). Cerul se
scrie în trepte de 0,01 din `dusk` (schimbarea materialului cerului reface
harta de radianță). `ground_bottom` urmează ceața ceasului (legătura din
`_build_environment`).

**Garda:** `ProbeJodLumina --guard` → **OK** la dusk 0 / 0,5 / 1. Cea mai
strânsă: F_ochi dusk 0 var S **0,27**, F_joc 0,28 (prag 0,25); F la 0,5:
S 0,23–0,24 (prag 0,20). Luma cadrului noaptea 17–20 (prag 12; înainte
21–25). `probe_decor --track=17`: **24 de materiale** (identic cu baza, pe
toate coloanele); `--track=16`: 30, identic la cifră cu și fără schimbare. În
`track.gd` s-a atins doar dicționarul temei `jodhpur`; `DuskCycle` există
doar în Track17.

**Ce n-a mers / rămâne:** varul **luminat de soare** pe H (fațadele spre vest)
trece de la H 238 / S 0,14 la H 257 / S 0,20: mai saturat, dar spre lila, nu
albastru — soarele portocaliu pe albastru dă mov; lumina nu poate face mai
mult fără să răcească tot. Fortul îndepărtat văzut de pe D rămâne rece
(gresie H 305, S 0,13): e 70 % ceață albastră. Banda de deșert îndepărtat din
cadrul F rămâne albastru-pal — aceeași ceață, aceeași constrângere. Pavajul
(umerii, ulicioara) și asfaltul nu sunt atinse. Garda pe F are marjă mică
(0,02–0,03 pe S): orice încălzire suplimentară a luminii trece prin ea.

Planșele: `docs/track_briefs/img/jodhpur_lumina2/plansa_dusk0.jpg` și
`plansa_dusk1.jpg` (7 POI-uri, înainte | după, camera de joc).

### 10.1 După merge-ul cu decorul lui D (runda 3–4)

`--guard` pe integrare: 2 abateri. Cauzele, separate:

- **D_ochi dusk 0, „sol H 234” — măsurătoare greșită.** Ochiul fix
  (0, 27, −140) nu mai vede nisipul de aproape (acoperișurile noi îl ascund):
  toți cei 8 126 px de „sol” din masca de ID stăteau pe rândurile 307–357,
  adică banda de teren de la orizont, la peste 250 m, ieșită (172, 176, 211) =
  culoarea ceții. **Fix în sondă:** terenul mai departe decât distanța la care
  ceața acoperă o treime din culoare (derivată din ceața scenei: 198 m) trece
  în clasa `rest`, nejudecată. Pragurile nu s-au atins. D_ochi mai are acum
  654 px de sol apropiat (H 21, S 0,47), sub `MIN_PX`: vederea aceasta nu mai
  judecă solul, pe care îl judecă D_joc (H 19, S 0,41).
- **F_ochi dusk 0, „var H 231 S 0,26” — lumină reală.** Orașul văzut de pe
  bastion, la 150–300 m, e 50–70 % ceață; casele noi ale lui D au adăugat
  pixeli (56 292 → 59 120) și media a trecut de 230 cu un grad. **Fix:**
  ceața de dusk 0 `#8A94B8` → `#8898B8` (H 226 → 220, aceeași luminanță):
  F_ochi var **227 / 0,27**, F_joc **224 / 0,29** (erau 231 / 0,26 și
  228 / 0,28); cerul, solul și gresia neschimbate la cifră pe toate vederile.

`--guard` → OK la dusk 0 / 0,5 / 1. `probe_decor --track=17`: 24 de materiale.
