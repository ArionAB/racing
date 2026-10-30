# Inventar — kit Carrara (Track23), grupa crr-e: satul Colonnata și blocul-semn (kit §1.4)

Contract: `docs/asset_briefs/carrara_kit.md` §1.4. Fișierul e al grupei crr-e
(val 2); coordonatorul îl unește cu `carrara_inventory.md`. Colțul de muzeu
(`museum_set_*`) e al grupei crr-d și nu e aici.

## Fișiere

| fișier | rol |
|---|---|
| `tools/blender/build_crr_buildings.py` | cele cinci piese; docstring-ul fiecărei funcții = lista de elemente, scrisă înainte de geometrie. Helpere proprii: `prism_face` / `box_face` (geometrie pe o față, la coordonata ei absolută), `Openings` (goluri **reale**, tăiate boolean 0,24 m, cu fund negru, canat de ușă, montanți, ancadrament de piatră și obloane; pe tiparul `build_tf_buildings.Openings`, cu arc și oculus), `quoins`, `solve_pitch` / `gable_roof` (panta din cota coamei cerute), `emit_keep` (export fără nicio mutare: piesele se construiesc direct cu baza la 0) |
| `tools/blender/measure_crr_buildings.py` | garda de cote, pe GLB-ul exportat, în coordonate Godot (vezi mai jos) |
| `tools/blender/preview_crr_buildings.py` | `--compare`, `--views`, `--village`, `--all`; folosește `preview_carrara.py` **neschimbat** (exec) și adaugă doar camera per piesă și planșa satului |
| `tools/blender/compose_crr_buildings.py` | compunerea planșei satului (PIL) |
| `tools/blender/verify_carrara.sh` | secțiunea „val 2, crr-e”: `check --origin=assembly` pe cele cinci GLB-uri + `measure_crr_buildings.py` |

`carrara_shapes.py`, `preview_carrara.py` și celelalte builder-e nu s-au atins.
Acoperișurile folosesc `tin_roof` din `transfagarasan_shapes.py` (prin
`carrara_shapes`), cu nervurile puse ca **rânduri de olane**.

## Cote măsurate (din GLB, nu din build)

Axele glTF: X lateral, Y sus, Z adâncime (= −Y Blender). Fața bogată e pe +Y
Blender = **−Z Godot**. Originea e pe centrul corpului principal (nava, casa),
cu baza la 0; offsetul e zero prin construcție pe toate nodurile.

| piesă | cerut (kit §1.4) | măsurat | tri | noduri / sloturi | runde |
|---|---|---|---:|---|---:|
| `colonnata_church` | navă 14 × 8, coamă 10; clopotniță 4 × 4, 14 m cu cruce | navă **8,08 × 14,08** (zidăria la 7,0–7,3 m, cu pietrele de colț de 4 cm); coama **10,00**; clopotnița **4,08 × 4,08** (trunchiul la 6,2–6,5 m); vârful crucii **14,00**; ușa pe −Z. Ansamblul: 16,46 × 14,00 × 19,05 (X × Y × Z) | 7.268 | `Church_Stone` 29 · `Church_Roof` 23 · `Church_Wood` 9 + 28 · `Church_Void` 20 | 3 |
| `colonnata_house_a` | 9 × 7, două niveluri, coamă 8 | **9,08 × 7,08**, coama **8,00** pe X, hornul la +0,90 peste coamă | 2.342 | `House_Stone` 29 · `House_Roof` 23 · `House_Wood` 9 + 28 · `House_Shutter` 12 · `House_Void` 20 | 2 |
| `colonnata_house_b` | 8 × 7, coamă 8,5 | **7,08 (fronton) × 8,08**, coama **8,50** pe Z (fronton spre −Z), **hornul mare la +1,40** peste coamă | 2.516 | la fel ca A | 2 |
| `colonnata_house_c` | 10 × 7, coamă 7,5 | **10,08 × 7,09**, coama **7,50** pe X; scara + terasa în fața lui −Z: sus la **2,80**, întinse **6,86 m** pe X | 2.470 | la fel ca A | 2 |
| `quarry_sign_block` | bloc 3 × 2 × 2 | **3,00 × 2,00 × 2,00**; fața șlefuită (−Z) e un singur plan de 3,00 × 2,00, numai `Sign_Marble` | 44 | `Sign_Marble` 19 · `Sign_MarbleBase` 29 | 2 |

- Materiale: 4 la biserică, 5 la fiecare casă, 2 la bloc (un nod = un material).
  La integrare, clasele cad pe materiale **deja existente pe Track23** (vezi mai jos).
- Niciun `FOAM_WHITE` 22, niciun slot de mașină (14–16), fără text. Scala și
  rotația sunt la identitate pe toate rădăcinile (garda din `verify_carrara.sh`).
- Primitivele rotunde: arcele au 8 laturi pe semicerc (16 pe cerc), oculii 12.

### h/l (pe imaginea de comparație, 3/4)

| piesă | kit | decupare (cu copacii) | randare | față de kit |
|---|---:|---:|---:|---:|
| church | 1,10 | 0,85 | 0,96 | −13% |
| house_a | 0,85 | 0,74 | 0,88 | +4% |
| house_b | 0,95 | 0,75 | 1,03 | +8% |
| house_c | 0,75 | 0,69 | 0,80 | +6% |
| sign_block | 0,65 | 0,94 | 0,84 | +29% față de kit, −11% față de decupare |

Pe decupări, copacii și pietrele lățesc silueta, deci h/l-ul lor iese mai mic.
La bloc, 0,65 e raportul cotelor (2 / 3), dar în 3/4 se vede și fața de sus,
deci comparația corectă e cu decuparea (0,94 → 0,84).

## Garda și sabotajele (rulate pe 31 oct 2026)

`measure_crr_buildings.py` verifică, pe fiecare piesă, numele exacte ale
nodurilor, sloturile pe nod (din UV) și absența sloturilor interzise, apoi:
- **biserica**: vârful crucii 14,0 ±0,05; clopotnița 4 × 4 (+0…+0,12);
  coama navei 10,0 ±0,10; nava 8 × 14 (+0…+0,12); ușa pe −Z;
- **casele**: amprenta pe zidărie, în banda de 0,5 m de sub streașină
  (+0…+0,12); coama ±0,08 și axa ei; hornul (B ≥ 1,0 m peste coamă, A și C
  sub 1,0); la C, scara și terasa (2,6–3,0 m, ≥ 6 m pe X);
- **blocul**: 3 × 2 × 2 ±0,01; fața −Z e un plan care acoperă 3 × 2 și nu
  conține patină.

Copiile sabotate s-au scris cu `measure_crr_structures.py sabotage` (se schimbă
doar JSON-ul nodului), apoi s-a rulat garda neschimbată:

| sabotaj | rezultat |
|---|---|
| `Church_Roof` +0,30 m | **pică**: coama navei 10,30 |
| `Church_Stone` × 1,04 pe X și Z | **pică**: clopotnița 4,24, nava 8,40 |
| `Church_Wood` −0,20 m (crucea) | **pică**: vârful 13,80 |
| `House_Roof` (A) +0,20 m | **pică**: coama 8,20 |
| `House_Stone` (A) × 1,03 pe X | **pică**: amprenta 9,35 |
| `House_Stone` (B) −0,50 m | **pică**: hornul la +0,90 < 1,0 |
| `House_Stone` (C) +2,0 m pe Z | **pică**: fără scară/terasă în fața lui −Z |
| `Sign_MarbleBase` −0,03 m pe Z (pe fața șlefuită) | **pică**: blocul 2,01, fața șlefuită 0,67 înaltă, patină pe ea |
| `Sign_Marble` × 1,02 pe X | **pică**: 3,06 |
| originalele (control) | **trec** |

Prima rulare a gărzii a picat pe biserică din vina **ferestrelor de măsură**,
nu a modelului: banda de 10,1–10,7 m tăia bolțarii clopotniței (ies 5 cm), iar
filtrul de navă tăia chiar peretele +X al navei. Ferestrele s-au mutat pe
trunchi (6,2–6,5 m) și pe zone fără ancadramente. Modelul nu s-a schimbat.

`bash tools/blender/verify_carrara.sh` → `VERDICT KIT: OK` (tot kitul, cu cele
cinci piese noi).

## Fidelitate

Imagini în `docs/asset_briefs/img/carrara_fidelity/`: `<nume>.png` (decupare |
randare, 3/4, pe azimutul decupării), `<nume>_views.png` (4 azimuturi) și
`colonnata_village.png`. Planșa satului are două benzi:
- **sus**: biserica și cele trei case alăturate, la scară comună;
- **jos**: aceeași lineup cu camera jocului la 150 m (FOV vertical 68°, 1080p,
  camera la 7 m sub baza satului), decupată și mărită ×4 NEAREST. Satul are
  acolo **385 × 77 px** pe ecran. Se citesc turnul cu crucea, acoperișurile de
  țiglă, hornul mare al lui B și treapta scării lui C. Obloanele sunt pete de
  1–2 px.

Azimuturile: decupările bisericii, ale casei B și ale blocului sunt din
stânga-față (azimut 125: +Y în stânga ecranului, −X în dreapta). Cele ale
caselor A și C sunt din dreapta-față (azimut 55: +X în stânga, +Y în dreapta).

Rundele:
- **biserica r1 → r2:** ferestrele clopotniței au trecut de la 1,10 la 1,77 m
  înălțime (decuparea le are cât o nouă parte din turn), brâul a coborât la
  8,6 m, iar streașina piramidei a crescut de la 0,30 la 0,45 m;
- **r2 → r3, toate clădirile:** pe acoperiș, olanele au acum 24 cm la pasul de
  0,55 m și placa are 24 cm. În r1–r2, cu 13 cm la 0,34 m, acoperișul citea
  **tablă cutată**, nu țiglă;
- **casa B r2:** fereastra de pod a devenit pătrată (pe decupare nu e oculus);
- **blocul r2:** camera s-a mutat pe azimutul 55. Pe decupare, capătul de 2 × 2
  e în stânga și latura lungă în dreapta.

### colonnata_church

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| clopotnița | pătrată, pe stânga, cu fante, brâu, 2 ferestre arcuite sus, piramidă de țiglă, cruce | la fel, pe +X, 2 ferestre arcuite pe **fiecare** față (8), fante 2 + 2 + 1, cruce LOG_DARK la 14,0 | OK ca elemente. **Abatere de proporție:** pe decupare trunchiul e ~4 lățimi (≈ 16 m la 4 m lățime), iar la cotele kitului (4 × 4, 14 m cu crucea) iese ~2,75 lățimi: turnul citește mai îndesat |
| nava | bloc înalt cu frontonul spre față, oculus + fereastră pe fronton, 2 ferestre pe latură | 8 × 14, coama 10, oculus + fereastră pe fronton, 2 + 2 ferestre laterale, fereastră arcuită + oculus în spate | OK. Nava de 14 m e mai lungă decât pe decupare (acolo pare aproape pătrată); cota e din kit |
| pronaosul | corp jos în față, ușă arcuită cu ancadrament, fereastră mică, oculus în fronton | la fel: ușă 1,5 × 3,0 cu 9 bolțari și toc, fereastră, oculus, 2 trepte | OK |
| anexa | corp jos pe dreapta, fronton spre dreapta cu oculus și fereastră înaltă arcuită | pe −X, la fel; plus o fereastră mică pe față | OK |
| acoperișurile | țiglă portocalie, streașini groase, dolie între cele două acoperișuri joase | `TILE_TERRACOTTA`, rânduri de olane, placă de 24 cm, dolia apare din intersecție | OK |
| pietre de colț | colțuri din blocuri | alternante, ieșite 4 cm | OK, subtile |
| culoare | crem-auriu cald | `*_Stone` pe #8E8C82 (ținta `tf_stone`) | **abatere voită**: tenta o dă clasa la integrare (brief §4: gri-cald). Pe preview satul e gri, iar decuparea e crem |
| chiparoși, tufe, bolovani, dale | da | nu | **abatere voită** (corectura de kit) |

### colonnata_house_a / _b / _c

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| A: corp, acoperiș | corp lung, culcat, două ape | 9 × 7, coama pe X, streașina spre +Y (fața bogată) | OK |
| A: goluri | fronton cu ușă arcuită + fereastră + lucarnă; pe latură 4 ferestre cu obloane | la fel (+ 2 + 1 pe spate și pe −X) | OK |
| A: horn | mic, lângă fronton | la +X, cu +0,90 peste coamă | OK |
| B: corp | mai înalt, cu frontonul în față | 7 × 8, pereți 5,9, coama pe Y (fronton spre +Y) | OK |
| B: horn mare | gros, la capătul frontonului | 1,1 × 0,9 m, +1,40 peste coamă | OK: e semnătura siluetei |
| B: goluri | ușă arcuită pe fronton, a doua ușă pe latură, 2 ferestre cu obloane sus, una mică jos | la fel; fereastra de pod e pătrată (r2) | OK |
| C: scară + terasă | scară de piatră pe latură până la etaj, terasă cu balustradă de lemn | 10 trepte de 0,28 m, terasă 3 × 1,8 m pe soclu plin, cu gură de pivniță arcuită, balustradă LOG_DARK + WOOD, ușă la etaj | OK. Gura de pivniță nu e pe decupare (acolo soclul e acoperit de tufe) |
| C: horn | la capătul opus frontonului vazut | la −X | OK |
| obloanele | verde închis | `CACTUS_GREEN` 12 (#5B7C34) | slotul cerut de kit. Pe preview iese **mai deschis și mai saturat** decât pe decupare |
| acoperișurile | olane, streașină groasă | olane de 24 cm la 0,55 m, placă de 24 cm | OK după r3 |
| culoare zidăriei | crem cald | ținta `tf_stone` | abatere voită (vezi biserica) |

**Siluetele diferă** (planșa satului): A e un corp lung și culcat cu horn mic,
B e un bloc înalt cu frontonul în față și hornul mare, C e un corp lung și jos
cu pana scării și cubul terasei lipite pe o latură.

### quarry_sign_block

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| bloc | crem, muchii vii | 3 × 2 × 2, muchii vii, două colțuri sparte sus în spate | OK |
| rost orizontal la jumătate | da (pe decupare par două blocuri suprapuse) | nu | **abatere voită**: kitul cere **un** bloc cu fața șlefuită într-un singur plan |
| venele | portocalii, desenate | nu sunt geometrie | regula 7: le dă clasa `carrara_marble` |
| patina | — | treimea de jos a laturilor și a spatelui pe `MARBLE_GREY`; **nu** pe fața șlefuită (fâșia de jos a feței e `Sign_Marble`, coplanară) | regula 8, cu excepția feței șlefuite (motivul: e șlefuită) |
| text | nu | nu | OK |

## Clasele la integrare (`CLASSES_CARRARA`, `world_prop.gd`, NEATINS aici)

**Coliziuni de nume, verificate pe nodurile tuturor GLB-urilor din
`assets/models/`** (scanare pe JSON-ul fișierelor) și pe cheile lui
`WorldProp.prop_classes()` (globale, pe prefix de nume):
- `House_Stone` apare în 4 fișiere (`buildings/village_house`,
  `machupicchu/inca_house_a`, `transfagarasan/arges_house_a/b`; plus
  `House_Stone.001` în `guardhouse`). `House_Roof` apare în 9 fișiere,
  `House_Wood` în 6, `House_Void` în 2. Și mai important, **`House_Stone` și
  `House_Roof` sunt chei GLOBALE** în `Track._LANDMARKS` (landmark-ul
  `village_house`: `stone_wall` / `roof_tiles`). Deci `prop_classes()` le prinde
  pe casele Colonnata la `_ready`, sincron, iar intrarea pe fișier de mai jos
  (aplicată deferred, de `_apply_theme_classes`) le suprascrie. `House_A/B/C`
  (Stromboli, global) **nu** prind numele noastre (`House_Stone` nu începe cu
  `House_A`).
- `Church_Roof` există în `baikal/khuzhir_church`, dar nu ca cheie globală.
  `Church_Tower` e cheie globală (Stromboli), de aceea niciun nod nu e numit
  `Church_Tower*`. `Church_Stone`, `Church_Wood` și `Church_Void` sunt noi.
- `Sign_Marble` și `Sign_MarbleBase` sunt noi (`Sign_Body` e la `quarry_sign_a/b`).
  `Sign_` nu e cheie globală.

Intrările propuse (**cheie pe fișier**; prefixul `Sign_Marble` prinde și
`Sign_MarbleBase`, ca la restul kitului):

```gdscript
## Satul Colonnata (kit §1.4, crr-e): piatra pe `tf_stone`, tigla pe `ok_roof`.
## `House_Stone` / `House_Roof` sunt si chei GLOBALE (Track._LANDMARKS,
## village_house -> stone_wall / roof_tiles), deci prop_classes() le prinde
## intai; intrarea pe fisier de aici le suprascrie (deferred).
const _CRR_ROOF: String = Palette.TRI_PREFIX + "ok_roof"
const _CRR_HOUSE := {"House_Stone": _TF_STONE, "House_Roof": _CRR_ROOF}
...
	"colonnata_church": {"Church_Stone": _TF_STONE, "Church_Roof": _CRR_ROOF},
	"colonnata_house_a": _CRR_HOUSE,
	"colonnata_house_b": _CRR_HOUSE,
	"colonnata_house_c": _CRR_HOUSE,
	"quarry_sign_block": {"Sign_Marble": _CRR_MARBLE},
```

**Țigla pe `ok_roof`, nu pe `roof_tiles`** (brieful pistei și kitul spun
`roof_tiles`). Motivele:
1. comentariul existent din `CLASSES_CARRARA` (viaductul) spune că
   `roof_tiles` pe tema carrara a ieșit **aproape albă**, iar `ok_roof` (aceeași
   dală, `roof_tiles.png`, cu tentă) a ieșit corect;
2. `ok_roof` și `tf_stone` sunt **deja pe Track23** (viaductul și Marmifera),
   deci satul adaugă **0 materiale**. Cu `roof_tiles` ar fi +1.

Nevăzut în joc, deci de verificat la integrare. `*_Wood`, `*_Shutter` și
`*_Void` rămân pe atlas (nu sunt în mapare și nu se potrivesc cu nicio cheie
globală).

## Contracte înghețate

- Fața bogată pe −Z Godot, măsurată: ușa bisericii (Z mediu −10,6 față de
  centrul −2,3), latura cu ferestre la A, frontonul la B, scara și terasa la C,
  fața șlefuită a blocului.
- Originea: centrul navei sau al casei, baza la 0. **Biserica nu e centrată pe
  bbox**: ansamblul e pe X −7,85…+8,61 și pe Z −11,80…+7,25.
- Numele de noduri (verificate în `verify_carrara.sh`).
- Coliziunea: neimpusă. Satul stă la 120–160 m de drum, deci `hull`-ul implicit
  e suficient.

## Stare la oprire

- Cele cinci piese sunt construite, măsurate, cu garda dovedită pe sabotaj, iar
  comparațiile au fost privite element cu element: biserica în 3 runde, restul
  în 2. `verify_carrara.sh` → `VERDICT KIT: OK`. Importul Godot s-a rulat
  (`.import` comise lângă GLB-uri).
- Nu s-au atins `scenes/` și `scripts/`. Rămân coordonatorului:
  - intrările din `CLASSES_CARRARA` (mai sus);
  - montarea satului pe versantul din G (`DecorManual`);
  - chiparoșii, castanii și tufele de la baza clădirilor.
- Nevăzut: piesele în joc, cu fereastră (clasele `tf_stone` / `ok_roof`,
  lumina temei, umbrele). Nemăsurat pe pistă: azimutul și ocluzia satului din
  coborârea G (memoria `reperul-se-vede-pe-patru-axe`).
- Deschise (estetic):
  - clopotnița e mai îndesată decât pe decupare (cotele kitului);
  - verdele obloanelor e mai deschis decât pe decupare (slotul cerut);
  - nava e lungă de 14 m, iar decuparea o arată aproape pătrată;
  - blocul-semn n-are rostul orizontal al decupării.
