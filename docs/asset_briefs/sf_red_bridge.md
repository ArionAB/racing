# Brief asset — Podul roșu carosabil, kit modular (`sf_bridge_*.glb`)

Brief auto-conținut pentru un agent Blender extern (Blender MCP). Nu presupune acces la repo:
tot contractul e aici. Sursele din care e derivat sunt [style_bible.md](../style_bible.md),
[blender_export.md](../blender_export.md), [scripts/palette.gd](../../scripts/palette.gd), foaia
de assets [sanfrancisco_inventory.md](sanfrancisco_inventory.md) (H1, §1.6, §4) și brief-ul
pistei `docs/track_briefs/san_francisco.md` (§2.0, §4, §7 pașii 1d și 2b). Geometria de joc vine
din `tools/gen_sf_route.py` (blocul „PODUL ROȘU pe Track25”, `:1655–1780`) și din `Track25.tscn`
(`Pod/`).

Sursa reproductibilă (de creat de agent): `tools/blender/build_sf_bridge.py`.

> **Prompt de dat agentului:** de la linia orizontală de mai jos în jos e paste-ready. Restul
> paginii sunt note pentru noi. **Numele real al podului nu se folosește nicăieri**, nici în
> fișiere, nici în comentarii: e „podul roșu”.

---

## 1. Ce construiești

Un **pod suspendat roșu-portocaliu**, low-poly și stilizat, pentru un joc de curse cu mașinuțe de
jucărie în stil dioramă (ton *Art of Rally*: machetă de masă, NU foto-realist). Pista trece **pe
el**, dus-întors: e locul de start și de sosire. Un design generic, robust, de jucărie, nu copia
unui pod real.

Podul se livrează ca **kit de piese separate** (câte un `.glb` fiecare), pe care jocul le
asamblează din cod pe geometria lui exactă. Toate piesele sunt **pur vizuale**: jocul are deja
coliziunea (parapete, picioare, carosabil), iar piesele tale se îmbracă peste ea.

## 2. Rolul lui în cadru

E **eroul pistei**. Camera e la 10 m deasupra drumului, 12,5 m în spatele mașinii, privind în jos
la 29°, cu câmp vizual vertical de 68°. **La distanța `d`, cadrul vede cel mult 10 + 0,093·d m
peste carosabil.** Consecința, măsurată pe geometria pistei:

- de pe grila de start, portalul cel mai apropiat e la 123 m: se văd **picioarele și traversa de
  jos (+15)**; cel de-al doilea portal e la 223 m și se vede până la ~+31;
- pe tablier treci **pe sub traversa de jos**; portalul iese din cadru pe sus sub 60 m;
- **partea de sus a turnului (+39…+45) aproape nu intră niciodată în cadru**: doar de la ≥ 310 m,
  în pâclă.

Deci **identitatea podului stă în primii 30 m ai turnului și în cabluri**: picioarele cu trepte și
caneluri, traversa de jos cu panoul ei, cablurile groase care urcă oblic și ies din cadru pe sus,
parapetele roșii care încadrează drumul. Pune detaliul acolo. Partea de sus rămâne simplă, dar
completă (se vede ca siluetă de pe mal).

**Testul de reușită:** din camera de joc, de pe grilă (123–223 m) și de pe tablier (0–60 m),
citește imediat „pod suspendat roșu”, fără niciun nume.

## 3. Cadrul comun al pieselor

Unitate: 1 = 1 m. Mașina de referință are 4,2 m.

**Cadrul podului (în coordonatele Godot):** axa X e de-a lungul podului (0 = capătul de vest al
tablierului, +X spre est), Y în sus (0 = **fața carosabilului**), Z lateral (0 = axa podului). Apa
e la Y = −20. Fiecare piesă de mai jos își dă originea în cadrul ăsta.

| element de joc (EXISTĂ, nu-l modelezi) | unde |
|---|---|
| carosabilul (asfalt, două benzi, cu despărțitor de beton pe mijloc) | Y = 0, pe \|Z\| ≤ 16,0 |
| coliziunea parapetelor | cutii de 0,5 × 1,2 m, de la \|Z\| = 12,2 (fața interioară) la 12,7; Y 0…1,2; X −12…212 |
| coliziunea evazărilor de la capete | cutii de 10 × 1,2 × 0,5 m, rotite cu 20° spre exterior, din X −12 spre vest și din X 212 spre est |
| coliziunea picioarelor portalurilor | cutii de 3 × 3 m, centrate la X 50 și X 150, Z ±14,5; Y −30…+45 |
| tablierul | X 0…200 peste apă; palierele X −36…0 și 200…236 pe uscat |

### Gabaritul liber — nimic din ce modelezi nu intră aici

1. **\|Z\| < 12,2, de la Y = −0,3 la Y = +13,8, pe toată lungimea:** benzile și despărțitorul.
2. **Între picioare (\|Z\| < 13,0), sub Y = +13,8:** acolo trece camera jocului.
3. **Pe \|Z\| < 16,0, piesele de sub tablier stau sub Y = −0,3** (sub asfalt), ca să nu răzbată
   prin el.

## 4. Piesele

Toate pe atlas (§6). **Un nod-mesh per material**, cu sufixul `_Steel` (oțelul roșu) sau
`_Concrete` (betonul). Nimic altceva în fișier: nicio coliziune, niciun nod gol.

### 4.1 `sf_bridge_tower.glb` — turnul-portal (×2 în joc)

Originea: pe axa turnului (X = 0 al piesei), la Y = 0 (fața carosabilului), Z = 0. Jocul îl pune la
X 50 și X 150.

- **Două picioare** centrate la Z = ±14,5, de la **Y = −30 la Y = +45**. **Secțiunea nu iese
  niciodată din pătratul de 3,0 × 3,0 m** (X ±1,5, Z de la ±13,0 la ±16,0). Picioarele se
  îngustează **în trepte, spre interiorul pătratului**: 3,0 m până la +18, 2,6 m de la +18 la +32,
  2,2 m de la +32 la +45. Pe fețele dinspre X+ și X− și pe cea exterioară, **caneluri verticale
  adâncite** (3 pe față, 0,15 m adâncime): ele dau umbra care face piciorul să nu fie un stâlp
  plat.
- **Traversa de jos:** între fețele interioare ale picioarelor (Z de la −13,0 la +13,0),
  **cu fundul la Y ≥ +13,8**, grosime 2,4 m pe X. Deasupra ei, un **panou de portal** în trepte,
  până la +19,5: două sau trei registre cu adâncituri verticale. E piesa cea mai văzută din
  turn.
- **Traversa de sus:** cu centrul la +39 (de la +37,8 la +40,2), cu un panou asemănător până la
  +43,5.
- **Capetele picioarelor:** un capac cu cușeta cablului (saddle), Y +44…+45, unde cablul
  principal trece peste turn la Z = ±14,5.
- **Pila de beton** (`_Concrete`): un bloc care cuprinde ambele picioare, X ±4,5, Z ±19,0, de la
  Y = −30 la **Y = −16** (iese 4 m din apă). Margine teșită sus. Sub tablier, deci în afara
  gabaritului.

### 4.2 `sf_bridge_deck_8.glb` — segmentul de tablier, 8 m (×25)

Originea: X = 0 (începutul segmentului), Y = 0, Z = 0. Segmentul merge de la X 0 la X 8. Jocul le
pune cap la cap de la X 0 la X 200.

- **Grinzile laterale** (fasciile care se văd din lateral): două, la Z de la ±15,9 la ±16,4, de la
  **Y = +0,25 la Y = −4,0**. Pe fața exterioară, **ferma în relief, nu ferma găurită**: un stâlp la
  capătul panoului, două diagonale groase în „V” (bare de 0,4 m, relief 0,2 m) și o talpă jos.
  Fără goluri prin care se vede: o fermă fină sclipește pe telefon.
- **Intradosul** (fața de dedesubt): o placă pe Z ±16,4, de la Y = −0,6 la −1,0.
- **O grindă transversală** pe segment, la X = 0, sub intrados: de la Y = −1,0 la −2,5, pe Z ±15,9.
- Nimic peste Y = −0,3 pe \|Z\| < 15,9 (gabaritul 3).

### 4.3 `sf_bridge_parapet_8.glb` — parapetul, 8 m, ambele părți (×28)

Originea: X = 0, Y = 0, Z = 0. Merge de la X 0 la X 8. Jocul le pune de la X −12 la X 212.

- Doi pereți plini, **fața interioară exact la Z = ±12,2**, cea exterioară la ±12,7, de la Y = 0 la
  **Y = +1,2**. Aceasta e și coliziunea jocului: mașina freacă peretele, deci ce vede jucătorul
  trebuie să fie exact acolo.
- **Fața interioară e plană.** Poate avea panouri adâncite de cel mult 0,04 m, dar **nimic nu iese
  spre drum**.
- Pe fața exterioară: montanți la 2,0 m (relief 0,15 m spre exterior).
- O mână curentă rotunjită sus, care poate depăși **doar spre exterior** (până la ±12,85).

### 4.4 `sf_bridge_flares.glb` — evazările de la capete (×2)

Originea: X = 0 = capătul parapetului drept, Y = 0, Z = 0. Piesa merge **spre −X**: fiecare perete
pornește din (X 0, Z ±12,2) și se duce, pe 10 m, la 20° spre exterior, până la (X −9,40,
Z ±15,62) (fața interioară). Același profil ca parapetul: 1,2 m, 0,5 m grosime. Jocul pune
piesa la X −12 și, rotită cu 180°, la X 212.

### 4.5 `sf_bridge_cable_main.glb` — cablurile deschiderii centrale (×1)

Originea: pe axa turnului de vest (X = 0 al piesei = X 50 al podului), Y = 0, Z = 0. Piesa merge
de la X 0 la X 100 (până la turnul de est).

- **Două cabluri principale**, la Z = ±14,5, **diametrul 1,0 m** (10 laturi). Fiecare e o parabolă
  de la (X 0, Y +44,5) la (X 100, Y +44,5), cu punctul de jos la **(X 50, Y +3,0)**.
- **Tiranții (hangers):** verticali, la X = 10, 20, …, 90 (9 pe parte), **diametrul 0,35 m**
  (6 laturi), de la cablu până la Y = +0,25 (pe grinda laterală). **Puțini și groși:** firele
  subțiri sclipesc pe telefon.
- Cablul trece peste parapet și în afara lui (Z 14,5 > 12,7): nu atinge gabaritul.

### 4.6 `sf_bridge_cable_side.glb` — cablul deschiderii laterale (×2)

Originea: pe axa turnului (X = 0 al piesei), Y = 0, Z = 0. Piesa merge **spre −X**, de la turn
până la ancoraj, pe 50 m.

- Două cabluri la Z = ±14,5, ⌀ 1,0 m, de la (X 0, Y +44,5) la (X −50, Y +4,0), ca arc de parabolă
  concav în sus (vârful parabolei e dincolo de ancoraj): Y = 4,0 + 40,5·((X + 50)/50)².
- Tiranți la X = −10, −20, −30, −40, ⌀ 0,35 m, până la Y = +0,25.
- Jocul pune piesa la turnul de vest (X 50, spre vest) și, rotită cu 180°, la turnul de est
  (X 150, spre est).

### 4.7 `sf_bridge_anchor.glb` — ancorajul de capăt (×2)

Originea: X = 0 = capătul tablierului, Y = 0, Z = 0. Piesa e modelată pentru capătul de vest
(podul continuă spre +X). Capătul de est primește aceeași piesă, rotită cu 180°.

- **Doi piloni de ancoraj** (`_Concrete` cu capac `_Steel`), pe Z de la ±13,2 la ±17,8, X de la
  −6 la +2, de la Y = −24 la **Y = +6**, în trepte (mai lați jos). Cablul lateral intră în ei la
  (X 0, Y +4,0, Z ±14,5): lasă o gură de cușetă acolo.
- **Culeea** (zidul de sub capătul tablierului): X de la −1 la +1, Z ±16,4, Y de la −1,0 la −24.
- Pilonii stau **dincolo de parapet** (Z > 12,7) și pe trotuarul la care mașina nu ajunge. Nimic
  pe \|Z\| < 13,2 deasupra lui Y = −0,3.

### 4.8 Opționale (dacă rămâne timp)

- `sf_bridge_walkway_8.glb`: trotuarul exterior, pe Z de la ±12,7 la ±16,4, cu fața de sus la
  **Y = +0,20** (deasupra asfaltului, nu la nivel cu el) și o bordură roșie de 0,3 m la margine.
  Acoperă fâșia de asfalt care iese dincolo de parapet.
- `sf_bridge_lamp.glb`: felinar pe trotuarul exterior, la Z ±13,6, înalt de 6 m, stâlp ⌀ 0,3 m,
  capul ⌀ 0,6 m. Originea la baza stâlpului.

## 5. Orientare

Cadrul din §3 e în coordonatele Godot. Exportatorul glTF face `(x, y, z) → (x, z, −y)`: **Blender
+Y devine Godot −Z**, iar Blender +Z devine Godot +Y. „+X” e același în ambele. Modelează deci cu
Z-ul podului pe **−Y Blender**. Toate piesele sunt simetrice în Z, deci contează doar ca X-ul și
Y-ul să fie corecte.

## 6. Culoare — FĂRĂ texturi proprii

UV → sloturi dintr-un atlas de paletă (32 de sloturi orizontale). Fiecare față își colapsează
toate UV-urile pe **un singur punct**, centrul slotului: `u = (slot + 0,5) / 32`, `v = 0,5`. Nu
încarci nicio imagine; contează doar coordonata UV.

| slot | nume | **u** | hex | unde |
|---|---|---|---|---|
| 7 | `kerb_red` | **0.234375** | `#BB3522` | **tot oțelul**: picioare, traverse, panouri, cabluri, tiranți, parapete, grinzi, capace (nodurile `_Steel`) |
| 8 | `concrete` | **0.265625** | `#C8BDA9` | pile, ancoraje, culee, trotuarul exterior (nodurile `_Concrete`) |
| 22 | `foam_white` | **0.703125** | `#E9F2F0` | doar sticla felinarelor (în nodul `_Steel` al felinarului) |

**Interzise:** 14, 15, 16 (culorile mașinilor) și **30 (`lava_orange`)**: iese „ars” sub lumina
caldă. Roșul podului e `kerb_red`, care e la câteva unități RGB de culoarea reală a vopselei.

## 7. Vertex colors = AO copt

Un strat de Color Attribute, gri, care se înmulțește peste culoare în joc. 1,0 = neatins, ~0,5 =
adânc. **Obligatoriu.**

- Turnul: gradient vertical 0,55 la pila de beton → 1,0 la vârf; canelurile și adânciturile
  panourilor ~0,6; sub traverse ~0,65.
- Segmentul de tablier: intradosul ~0,5 (e mereu în umbră); grinzile laterale 0,75 jos → 0,95 sus.
- Parapetul: 0,8 la bază → 1,0 sus (perete plat: gradient blând).
- Cablurile: 1,0 (fără AO; sunt subțiri față de lume).
- Eșantioane: **64** pe suprafețele mari (turn, pile, ancoraje), 32 în rest.

## 8. Scară, origine, bevel

- Originile sunt cele din §4, nu „baza centrată”: piesele se asamblează pe cadrul podului.
- Scara 1 și rotația 0 aplicate pe nodul rădăcină la export.
- Bevel: **0,08 m** pe turn, pile și ancoraje (clădire); **0,04 m** pe parapet și pe grinzi;
  **fără bevel** pe cabluri și tiranți (cilindri cu puține laturi).

## 9. Triunghiuri

Fără plafon (e un hero, o instanță), dar măsurate și raportate. Segmentele se repetă, deci acolo
contează fiecare triunghi. Orientativ:

| piesă | instanțe | țintă |
|---|---|---|
| turnul | 2 | 6.000–8.000 |
| segmentul de tablier | 25 | ≤ 600 |
| parapetul | 28 | ≤ 300 |
| evazările | 2 | ≤ 300 |
| cablul principal | 1 | ≤ 3.000 |
| cablul lateral | 2 | ≤ 1.500 |
| ancorajul | 2 | ≤ 2.500 |

Fără nituri, șuruburi, zăbrele fine, cabluri sub ⌀ 0,3 m sau balustrade subțiri.

## 10. Export

- Câte un glTF Binary (.glb) pe piesă, cu numele din §4:
  `sf_bridge_tower.glb`, `sf_bridge_deck_8.glb`, `sf_bridge_parapet_8.glb`,
  `sf_bridge_flares.glb`, `sf_bridge_cable_main.glb`, `sf_bridge_cable_side.glb`,
  `sf_bridge_anchor.glb` (+ opționalele `sf_bridge_walkway_8.glb`, `sf_bridge_lamp.glb`).
- Noduri: `<Piesă>_Steel`, `<Piesă>_Concrete` (de ex. `Tower_Steel`, `Tower_Concrete`), copii
  direcți ai rădăcinii. Fără noduri goale, fără coliziune, fără sufixul `_col`.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere, lumini, texturi, animații.
- **Apply Modifiers: ON.** Y-up: implicit.
- Înainte de livrare: tipărește pentru fiecare piesă AABB-ul în coordonate Godot și numărul de
  triunghiuri, apoi verifică de mână gabaritul din §3 (cel mai ușor de stricat: fundul traversei de
  jos ≥ +13,8; fața interioară a parapetului la 12,2; picioarele în 3 × 3).
- Un randaj de control: podul asamblat (2 turnuri, 25 de segmente, 28 de parapete, cablurile,
  ancorajele) văzut **dintr-o cameră la 10 m peste carosabil, la 123 m de primul turn, privind în
  jos la 29°, FOV vertical 68°**. Așa îl vede jucătorul de pe grilă.

---

## 11. Note pentru noi (nu fac parte din prompt)

**Consumatorul (inventarul §1.6):** azi nimic nu încarcă un GLB de pod. `Pod/` din `Track25.tscn`
e scris de `gen_sf_route.py:1700–1760`: parapete și evazări (`StaticBody`, cu meshuri gri `*M`),
`CapS` (zidurile moi din S), `Turnuri` (picioare cu coliziune, traverse fără), `Despartitor`.

**Integrarea (coordonatorul, date în generator, fără cod de motor):**
1. sub `Pod/Model`, câte un nod `DecorManual` (scena `WorldProp`) pe instanță, cu
   `metadata/coliziune = "none"`. Transformurile sunt în cadrul podului: origin = (X_D0 = 270,
   DECK_Y = 20, GZ = −228,626), rotație 0;
2. se scot meshurile `*M` gri (parapete, evazări, picioare, traverse); **cutiile de coliziune
   rămân** neatinse;
3. dacă `DecorManual` coace piesele în `MultiMesh` (`TrackDecorBatch`), LOD-urile se poartă cu
   `MeshCpu.surface_lods` (CLAUDE.md);
4. umbre: turnurile și parapetele aruncă umbră (sunt aproape de drum); cablurile pot avea umbra
   stinsă dacă `ProbePerf` o cere;
5. gărzile: `probe_decor --track=25` (materialele trebuie să scadă cu 2: `Mat_pod_gri` și
   `Mat_pod_rosu`), `ProbeLayout --track=17`, `ProbeLaneClear --track=17` (linia de bază 50),
   capturile `b200_grila_pod_gamecam` și `b200_tablier_camion_gamecam` refăcute și comparate.

**Dacă tablierul se scurtează la 170 m** (decizia deschisă de la 2b): turnurile la X 42,5 și
127,5, deschiderile 85 / 42,5 m. Cablurile se scalează pe X cu 0,85 (secțiunea se turtește
invizibil pe X), iar segmentele de 8 m nu mai dau un număr întreg: ultimul se scalează pe X.
Turnul, parapetul și ancorajul nu se schimbă.

**Checklist la primire:**
```
python tools/blender/verify_glb.py assets/models/sanfrancisco/structures/sf_bridge_tower.glb 12000 --origin=assembly
python tools/blender/verify_glb.py assets/models/sanfrancisco/structures/sf_bridge_parapet_8.glb 600
```
`verify_glb` verifică sloturile, AO-ul și numărul de triunghiuri. **Originile pieselor nu sunt
„baza centrată”**, deci verificarea de bază la Y = 0 nu se aplică (turnul coboară la −30). Garda
reală e una nouă de gabarit, care citește GLB-urile și verifică cotele din §3 (pe tiparul
`measure_carrara_truck.py` / `measure_angkor.py`). De scris o dată cu integrarea.

## 12. Abateri și dependențe

- **Portalurile la 45 m, nu la 227 m:** §2.0 din brief-ul pistei (frustumul decide înălțimile).
  Chiar și la 45 m, sus nu se vede: §2.
- **Coliziunea nu e a GLB-ului:** contractele măsurate la 1d și 2b (0 treceri peste despărțitor,
  0 frontale, contact cu bariera 4,6–5,5 %) stau pe cutiile generate. Vizualul se mulează pe ele,
  nu invers.
- **Despărțitorul și camionul** sunt în `sf_median_truck.md`: se văd între parapete, deci roșul
  podului, betonul blocurilor și gri-albastrul camionului trebuie să rămână trei valori distincte.
