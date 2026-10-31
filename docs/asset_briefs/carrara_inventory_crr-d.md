# Inventar — kit Carrara, val 2, constructorul crr-d

Contract: `docs/asset_briefs/carrara_kit.md` §1.2 (utilajele de decor) și §1.4
(colțul de muzeu). Ramura `carrara/kit-d`. Toate cotele de mai jos sunt
**măsurate pe GLB-ul exportat**, în coordonate Godot (Y sus, −Z înainte), de
gărzile din `tools/blender/measure_carrara_crr_d.py`.

## Fișiere

| fișier | rol |
|---|---|
| `tools/blender/build_crr_machines.py` | `build_wire_saw`, `build_chain_saw_crawler`, `build_drill_rig`, `build_museum_set_cart`, `build_museum_set_wheel`, `build_museum_set_sled` (docstring = lista de elemente, scrisă înainte de geometrie) + helperele `ring_x` (inel în jurul axei X), `spoke_x`, `crawler_track` (șenila completă, pe `_track_belt`), `emit_pivot` (offset o dată pe ansamblu, dar nodul cu pivot se mută prin `location`, ca originea lui să rămână în butuc), `_tapered_strip` / `_tapered_end`. `CRR_ONLY=<piesă>` reface o singură piesă |
| `tools/blender/preview_crr_d.py` | rulează `preview_carrara.py` **neschimbat**, cu camerele pieselor, feliile muzeului și `Blades` pe hexul RUST_METAL (are UV-uri reale, culoarea nu se poate citi din UV) |
| `tools/blender/crop_crr_d.py` | taie `museum_set.png` în trei felii (`img/carrara_fidelity/crops_crr_d/`), una pe GLB |
| `tools/blender/measure_carrara_crr_d.py` | gărzile `wire_saw`, `crawler`, `drill`, `cart`, `wheel`, `sled` |
| `tools/blender/verify_carrara.sh` | secțiunea „val 2, crr-d”: `verify_glb --origin=assembly` + garda + numele nodurilor pe fiecare piesă |
| `tools/probe_wire_saw.gd`, `tools/ProbeWireSaw.tscn` | sonda Godot: volantul se rotește cu `windmill.gd` sub un `WorldProp`; numele nodurilor față de maparea globală `prop_classes()` |

**Colțul de muzeu e în `build_crr_machines.py`**, nu în `build_crr_buildings.py`
(cum spune titlul kit §1.4): acela e al grupei crr-e, care lucrează în paralel.
Două grupe pe același fișier = conflict la integrare.

Nimic din `scenes/`, `scripts/`, `carrara_shapes.py`, `preview_carrara.py`,
`world_prop.gd`, `track.gd`, `gen_carrara_route.py` nu s-a schimbat.

## Cote măsurate față de contract

| piesă | contract | măsurat pe GLB | tri | noduri |
|---|---|---|---:|---|
| `vehicles/wire_saw.glb` | șasiu 2,5 × 1,6 × 1,4 pe două șine de 6 m, volant Ø 1,8; `Blades` cu originea în butuc, axa pe X | șine **6,000** pe Z, fire la x ±0,75; șasiul (`Saw_Paint`) **1,639 × 2,500**, vârful la **1,440** peste ciuperca șinei; `Blades` pivot (0,420; 1,300; −1,000), rotație identitate, scala 1, vârfurile centrate pe pivot în YZ (±0,000), rază **0,897**, grosime X 0,370; ansamblul X ±1,000, Y 0…2,197, Z ±3,000 | 9.296 (Blades 4.056) | `Blades`, `Saw_Paint`, `Saw_Rust`, `Saw_Rail`, `Saw_Water` (5) |
| `vehicles/chain_saw_crawler.glb` | 4,5 m lung fără lamă, 2,2 m înalt, lama 4 m | corpul Z ±2,250 (**4,500**), înălțimea **2,199**; lama Z −6,265…−2,183 (**4,082** pe Z), Y 0,05…1,65; **49** de dinți în relief (insule separate) | 8.824 | `Crawler_Paint`, `Crawler_Rust`, `Crawler_Black`, `Crawler_Blade` (4) |
| `vehicles/drill_rig.glb` | șasiu pe șenile 3,5 m, catarg 6 m | șenilele **3,474** pe Z; catargul (`Drill_Mast`) Y 0,200…6,200 (**6,000**), Z −2,36…−1,69 (în fața șenilelor); total Y **6,240**, Z −2,885…+2,050 | 10.968 | `Drill_Paint`, `Drill_Rust`, `Drill_Black`, `Drill_Mast` (4) |
| `props/museum_set_cart.glb` | vagonet 2 m pe 3 m de șină, bloc de 1 m | șina **3,000**; vagonetul (`Cart_Wood` peste 0,3 m) **1,988**; blocul 0,766 × 0,850 × **1,019**; înălțime totală 1,45 | 3.244 | `Cart_Wood`, `Cart_Rust`, `Cart_Marble`, `Cart_MarbleBase` (4) |
| `props/museum_set_wheel.glb` | roată Ø 2 m pe suport | roata (`Pulley_Rust`) **1,993 × 1,993** (Y × Z), 0,530 pe X; suportul (`Pulley_Wood`) pe sol, Y 0…0,322; total 2,12 | 5.220 | `Pulley_Rust`, `Pulley_Wood` (2) |
| `props/museum_set_sled.glb` | sanie veche 2,5 m cu funii | sania (`OldSled_Wood`) **2,492** pe Z, X ±0,903; frânghia Y 0,597…1,522 (stă pe sanie); total 1,52 | 3.404 | `OldSled_Wood`, `OldSled_Rope`, `OldSled_Rust` (3) |

Sloturi (din `verify_glb`):
- utilajele: `DRY_VEGETATION` 13 + `RUST_METAL` 10 + `VOLCANIC_BLACK` 20, plus `SAND_SHADOW` 2 (pete de praf pe cadrul șenilelor), `PAINTED_METAL` 11 (șinele mașinii de fir) și `REEF_SHALLOW` 17 (apa);
- muzeul: `WOOD_WEATHERED` 9 + `LOG_DARK` 28, `RUST_METAL` 10, marmura `CORAL_SAND` 19 / `MARBLE_GREY` 29 ca noduri separate, frânghia `SAND_MID` 1;
- **fără** `CAR_YELLOW` 16, **fără** `FOAM_WHITE` 22, fără text, cifre sau logo-uri.

Scala 1 și rotația identitate pe toate rădăcinile (verificat în
`verify_carrara.sh`). Primitive rotunde: 8–16 segmente (inele 16 sau 12,
cilindri 8–14, tori 12–14 × 8). `bash tools/blender/verify_carrara.sh` →
**`VERDICT KIT: OK`** pe tot kitul.

### Gărzile, verificate pe intrări greșite (sabotaj)

Copiile sabotate se fac rescriind JSON-ul / bufferul GLB-ului (vârfurile unui
nod mutate sau scalate, ori o rotație pusă pe nod).

| gardă | intrarea | rezultat |
|---|---|---|
| `wire_saw` | **prima variantă nesabotată** | PROBLEME, real: cutia de viteze era pe nodul vopselei și ducea șasiul la 2,84 pe Z. Mutată pe `Saw_Rust` |
| | `Blades` cu vârfurile mutate +0,3 pe Y | PROBLEME: „originea lui Blades nu e în butuc”, raza 1,197 |
| | `Blades` cu rotație de 90° pe Y | PROBLEME: „Blades are rotație” (+ ansamblul iese din ±1,0) |
| | `Saw_Rail` scalat 0,9 pe Z | PROBLEME: șinele 5,400 |
| | `quarry_truck.glb` | PROBLEME: lipsesc nodurile |
| `crawler` | `Crawler_Blade` scalat 0,9 pe Z | PROBLEME: lama 3,674 |
| | `drill_rig.glb` | PROBLEME: lipsesc nodurile |
| `drill` | **runda 2 nesabotată** | PROBLEME, real: canalul negru al catargului (pe `Drill_Black`, de la 0,8 m) intra în măsura șenilelor (3,90). Mutat pe `Drill_Mast` |
| | `Drill_Mast` scalat 0,9 pe Y | PROBLEME: catargul 5,400 |
| | `Drill_Mast` mutat 4 m înapoi | PROBLEME: catargul nu e în față |
| | `chain_saw_crawler.glb` | PROBLEME: lipsesc nodurile |
| `cart` | `Cart_Rust` scalat 1,2 pe Z | PROBLEME: șinele 3,600 |
| | `Cart_Marble` scalat 1,5 | PROBLEME: blocul 1,575 |
| `wheel` | `Pulley_Rust` scalat 0,9 | PROBLEME: roata 1,794 |
| | `Pulley_Wood` ridicat 0,2 | PROBLEME: suportul nu stă pe sol |
| `sled` | `OldSled_Wood` scalat 1,15 | PROBLEME: sania 2,866 |
| | `OldSled_Rope` coborât 0,6 | PROBLEME: frânghia coboară la −0,003 |
| | `museum_set_cart.glb` | PROBLEME: lipsesc nodurile |

## `windmill.gd` → `Blades`: calea există, fără cod nou

`windmill.gd` se atașează azi **doar** din `track.gd` (`_build_landmark`, pe
`_LANDMARKS` cu `spin`); `world_prop.gd` nu atașează niciun script. Dar o
instanță de GLB din `DecorManual` poate purta singură scriptul în scenă:

```
[node name="MasinaDeFir" parent="DecorManual/..." instance=ExtResource("k_wire_saw")]
transform = ...
script = ExtResource("<windmill.gd>")
axis = Vector3(1, 0, 0)
rpm = 30.0
```

Ordinea merge: `_ready` al copilului (windmill.gd: atlasul pe tot și găsește
`Blades`) rulează înaintea lui `WorldProp._ready` al lui `DecorManual`, care pune
apoi clasele. **`axis` trebuie setat**: implicitul morii e (0, 0, 1).

**Dovada** (`godot --headless --fixed-fps 60 --path . res://tools/ProbeWireSaw.tscn`,
exact montajul de mai sus, sub un `WorldProp`):

| | axa X (contractul) | axa Z (implicitul morii, sabotaj) |
|---|---|---|
| rotație după 20 de cadre la 30 rpm | 60,0° | 60,0° |
| deplasarea pivotului | 0,00000 m | 0,00000 m |
| centrul jantei față de pivot, în planul YZ | 0,000 m | 0,000 m |
| axa X a bazei după | (1, 0, 0) | (0,454; 0,891; 0) — **pică** |
| cutia volantului în lume, înainte / după | 0,370 × 1,793 × 1,793 / 0,370 × 1,790 × 1,791 | 0,382 × 1,802 × 1,793 / 1,695 × 1,004 × 1,793 — **pică** |
| verdict | OK | PICĂ, cum trebuie |

Plus: materialul lui `Blades` sub `WorldProp` nu e atlasul lumii, ci clasa pe
UV `rust_metal` (vezi mai jos); `WorldProp` face corpul de coliziune. Din toate
cele șase GLB-uri, **doar `Blades`** prinde o clasă din maparea globală
`WorldProp.prop_classes()`; restul nodurilor rămân pe atlas până la
`CLASSES_CARRARA`. Sonda: `VERDICT: OK`, ieșire 0.

**De ce `Blades` are UV-uri reale (cube_uvs, latura 2,2 ca la moară), nu slotul
RUST_METAL:** `prop_classes()` adună clasele din `Track._LANDMARKS`, unde
`"Blades": "rust_metal"` e o clasă **pe UV** (`class_material`), aplicată pe
prefix de nume, global. Orice nod numit `Blades` dintr-un `WorldProp` o primește.
Pe UV colapsate ar citi un singur texel; triplanar de lume nu se poate (roata se
rotește, textura ar curge). Consecință: **pe atlasul brut (fără clasă) volantul
ar citi sloturi la întâmplare**. Calea `WorldProp` îi pune mereu clasa, deci în
joc e corect; un montaj în afara unui `WorldProp` trebuie să-i pună
`rust_metal` explicit.

## Rândurile pentru `world_prop.gd` (de integrat de coordonator)

Nu am atins fișierul. Propuneri, de măsurat pe captură înainte de commit:

```gdscript
# CLASSES_CARRARA (pe numele de fisier):
	# Muzeul (crr-d): blocul din vagonet pe marmura pistei; prefixul prinde si _MarbleBase.
	"museum_set_cart": {"Cart_Marble": _CRR_MARBLE},
	# Optional, rugina utilajelor de decor pe triplanarul de rugina (noduri pe UN slot):
	"wire_saw": {"Saw_Rust": Palette.TRI_PREFIX + "rust_metal"},
	"chain_saw_crawler": {"Crawler_Rust": Palette.TRI_PREFIX + "rust_metal"},
	"drill_rig": {"Drill_Rust": Palette.TRI_PREFIX + "rust_metal"},
	"museum_set_wheel": {"Pulley_Rust": Palette.TRI_PREFIX + "rust_metal"},

# HULL_SKIP_PARTS (pe numele de fisier):
	# Apa (balta de 1,2 cm + jeturile in aer) si sinele cu firul (firul urca la
	# 2,1 m pe rola de intindere: hull-ul nodului ar fi o pana invizibila peste
	# fata masinii) nu primesc corp.
	"wire_saw": ["Saw_Water", "Saw_Rail"],
```

Ce **nu** trebuie mapat:
- `Blades` cu `TRI_PREFIX`: clasa pe UV îi vine deja din `prop_classes()`, iar
  triplanarul ar curge pe roata care se rotește;
- `Crawler_Blade` (bara neagră + dinții de rugină pe același nod), `*_Wood` de
  la muzeu (scândurile 9 + 28) și `*_Paint` (vopsea + grile/praf): o clasă ar
  șterge al doilea slot.

Coliziune: implicitul `hull` (pe părți) pe toate șase e corect ca formă. Două
note: la `drill_rig`, hull-ul lui `Drill_Black` leagă șenilele de bara kelly
(până la 5,9 m), adică o pană de aer peste fața corpului, unde mașinile oricum
lovesc corpul; la `chain_saw_crawler` lama e un corp convex subțire, deci se
poate lovi (contractul cere `hull`).

## Fidelitate

Imagini (decupare | randare din GLB, culoare reală pe sloturi, marmura pe ținta
clasei): `docs/asset_briefs/img/carrara_fidelity/<nume>.png` și
`<nume>_views.png` (4 azimuturi), pentru toate șase. Toate au folosit cele 3
runde. Culoarea utilajelor (galben-spălăcit 13 față de galbenul planșei) e
**abatere voită** (corectura kitului) și nu se mai repetă mai jos.

### wire_saw (3 runde)

R1: volantul subțire, cu spițe înguste, părea mic lângă cutie. R2: spițe late,
**stâlpul de întindere** cu rola sus în fața volantului (planșa), fir mai gros,
mânerul de ridicare în locul coșului. R3: camera mai din profil și obiectiv de
85 mm (cu 55, perspectiva micșora capătul din față), plus capătul firului retras
în șine (ieșea 1 mm peste 3,0 și muta pivotul). După gardă: cutia de viteze pe
rugină.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| șinele | două grinzi-profil lungi, plăci sub ele | 2 șine-profil de 6 m (talpă, inimă, ciupercă), 8 traverse-placă | OK |
| căruciorul | cutia pe 4 roți mici pe șine | ramă joasă, 4 roți + 2 sub sub-ramă, cutii de osie | OK |
| motorul-cutie | cutie lungă, teșită, galbenă cu rugină | 2,5 × 1,6, teșită sus, 2 uși în relief, grilă, 5 pete de rugină, buson, mâner | OK |
| volantul | mare, gros, 6 spițe late, janta cu șuruburi | Ø 1,8, janta cu canal (16 seg.), 6 spițe late, 12 șuruburi, butuc cu capac | OK ca elemente; spițele citesc „stea”, nu disc cu găuri ovale |
| raport volant / lungimea cutiei | ~1,15 | 1,8 / 2,5 = **0,72** | **abatere de proporție** impusă de cotele kitului |
| transmisia | arbore din cutie în butuc, țeavă în L | cutie de viteze, piedestal în A, arbore pe X, țeava în L | OK |
| firul + rola | firul coboară din rola de sus la rola de jos, spre apă | stâlp de întindere cu rolă, rolă de ghidare jos, 2 fire spre perete | OK |
| apa | jet și baltă sub rolă | 3 fâșii de jet + balta | OK |

### chain_saw_crawler (3 runde)

R1: lama aproape orizontală, la nivelul punții. R2: lama coborâtă 10°,
blocul motorului mai înalt, grila pe el. R3: lama coborâtă **13,5°** din
mijlocul corpului (rădăcina la 1,30 m), înălțimea barei 0,60, vârful la ~0,05 m
de sol.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| șenilele | lungi, joase, roți mari la capete | 2 × 32 de zale, roți de rugină, 4 role, cadru vopsit cu praf | OK |
| corpul | compact, motorul în spate cu grilă | punte + bloc de motor cu grilă, contragreutate, balustradă, coș | OK; mai lung și mai „cutie” decât planșa (4,5 m impus) |
| cabina | mare, în față-stânga | mică, pe stânga-mijloc, 2,2 m | **abatere**: cabina e mai mică decât pe planșă |
| capul de tăiere | braț, reductor, cilindru, furtun | toate patru | OK |
| lama | lungă, coborâtă spre sol, dinți pe toată muchia | 4,0 m, coborâtă 13,5°, nas rotunjit, 49 de dinți în relief | OK |
| peretele de marmură | pe decupare | lipsește | **voit** (kitul: integrarea bagă lama într-un perete real) |
| `h/l` (cutia) | ~0,4 | 2,2 / 8,5 = 0,26 | abatere: planșa scurtează lama în 3/4; la aceeași cameră proporția se citește la fel |

### drill_rig (3 runde)

R1: burghiul din plăci rare (citea ca o perie). R2: spirala deasă (5 × 16
trepte, ax gros), canalul negru pe catarg. R3: a doua coloană subțire legată de
catarg (planșa: cadru din două tuburi), capul lărgit peste ambele; camera mutată
din față-dreapta (la −50° burghiul stătea în spatele catargului).

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| șenilele | 2, roți de rugină | 2 × 30 de zale, roți, 4 role | OK |
| corpul | capotă cu grilă, cutie pe capotă | punte, capotă, cutia filtrului, grila pe −X, contragreutate | OK |
| cabina | pe flancul dinspre cameră, geam mare | pe −X, față | **abatere**: din azimutul planșei cabina nu se vede (stă pe partea cealaltă) |
| catargul | cadru înalt din două coloane, ghidaje, coroana sus | cheson 0,40 cu canal negru + coloană de 0,20, 4 coliere, 2 ghidaje, coroana cu 2 role | OK |
| brațul + cilindrul | braț curbat spre mijlocul catargului, cilindru sub el | braț frânt în 2 segmente + cilindru negru cu tijă | OK |
| capul rotativ + burghiul | cutie pe catarg, burghiu spiralat gros până la papuc | cap vopsit, bara kelly neagră, spirală deasă de rugină, vârf conic, papucul pătrat | OK |
| `h/l` (cutia) | ~1,6 | 6,24 / 4,93 = 1,27 | abatere de −20 % pe cutie; în comparația 3/4 se citește apropiat |

### museum_set_cart (3 runde)

R1: blocul de 0,98 m era mai lat decât interiorul cutiei (0,80 la podea) și
ieșea prin pereți. R2: blocul 0,74 × 1,00 × 0,85, încape. R3: roți de r 0,25,
ieșite în afara ramei, cameră mai joasă.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| șina | 2 fire, traverse scurte | 2 fire de 3 m, 5 traverse, una strâmbă | OK |
| roțile | 4, mari, vizibile sub cutie | 4, r 0,25, cu buză, butuc, cutii de osie | OK |
| cutia | evazată, scânduri, colțuri de fier | evazată 1,7 → 2,0, 3 scânduri pe perete cu rosturi, 4 colțuri, 2 benzi pe latură, ramă, mâner | OK; scândura din mijloc pe LOG_DARK citește mai dungat decât planșa |
| blocul | cub mare, iese mult peste ramă | 0,74 × 1,00 × 0,85, iese ~0,25 m, colț spart | **abatere**: mai mic și iese mai puțin decât pe planșă (cutia de 2 m nu încape un cub de 1 m lățime) |

### museum_set_wheel (3 runde)

R1: spițe subțiri, jantă îngustă. R2: jantă dublă de 0,48, spițe late. R3:
capre în A până la butuc ascundeau fața roții; acum **leagăn** jos sub jantă, iar
spițele sunt și mai late.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| janta | dublă, două coroane, șuruburi | două flanșe, canal, bandă interioară (16 seg.), 2 × 16 șuruburi | OK |
| spițele | disc cu goluri în lacrimă | 8 spițe late (0,40 → 0,32) | OK ca citire; golurile sunt triunghiulare, nu lacrimă |
| butucul | mare, cu capac | Ø 0,48 cu capace | OK |
| suportul | nu se vede (roata stă pe sol) | leagăn de lemn: 2 tălpi, 2 legături, 4 pene sub jantă | **abatere voită**: kitul cere „pe suport” |

### museum_set_sled (3 runde)

R1: funiile de legătură făceau un cort peste colac, țărușii erau stâlpi. R2:
funiile strâng colacul pe flancuri și peste capac, în cruce, țărușii scurți. R3:
secțiunea frânghiei la 8 laturi (contractul de segmente).

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| tălpile + traversele | grămadă de bârne, capete ieșite | 2 tălpi cu vârful întors, 5 traverse de lungimi diferite, al doilea rând | OK |
| colacul | mare, spire stivuite, legat peste | 6 spire + spirală sus, 4 funii în cruce | OK |
| fierăria | — | colțare, scoabe | OK |
| culoarea frânghiei | cânepă deschisă | `SAND_MID` 1 | **abatere de tabel**: rolul „frânghie” nu e în tabelul de sloturi; ales cel mai apropiat de planșă (crr-a a pus frânghia saniei pe LOG_DARK, pe crem) |

## Contracte înghețate (crr-d)

- **wire_saw:** `Blades` cu rotație identitate, scala 1, vârfurile centrate pe
  pivot în planul YZ (±0,02), rază 0,90 ±0,03, subțire pe X; pivotul la
  (0,420; 1,300; −1,000) Godot; UV-uri reale pentru clasa `rust_metal`;
  `windmill.gd` cu **`axis = Vector3(1, 0, 0)`**. Șinele 6,0 pe Z la x ±0,75,
  ansamblul în ±1,0 × ±3,0, originea pe axa șinelor la sol.
- **chain_saw_crawler:** originea în centrul mașinii (fără lamă), lama pe −Z
  Godot cu vârful la **Z −6,265**, rădăcina la −2,18; corpul ±2,25.
- **drill_rig:** originea în centrul șenilelor; catargul în față (−Z), Y
  0,20…6,20; burghiul la Z −2,5.
- **muzeul:** trei GLB-uri; originea centrată, la sol.

## Stare la oprire

- Cele șase piese sunt exportate, verificate (`VERDICT KIT: OK`), cu gărzile
  rulate și pe intrări sabotate, comparațiile și cele 4 azimuturi văzute piesă
  cu piesă. Sonda `ProbeWireSaw` → `VERDICT: OK`. `--import` rulat, `.import`
  comise. Commit-uri pe `carrara/kit-d`.
- Abateri **nerezolvate** (după 3 runde, raportate, nu declarate „trece”):
  volantul mic față de cutie (cotele kitului); cabina ferăstrăului mică; cabina
  mașinii de forat pe partea ascunsă; blocul din vagonet mai mic decât pe
  planșă; frânghia pe un slot din afara tabelului.
- Neverificat: aspectul în Godot cu lumina temei și clasele propuse; rotația
  volantului pe Track23 (piesele nu sunt montate, e treaba coordonatorului);
  numărul de materiale pe pistă după `CLASSES_CARRARA`.
