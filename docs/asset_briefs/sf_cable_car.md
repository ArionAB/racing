# Brief asset — Vagonul de cablu (`cable_car.glb`)

Brief auto-conținut pentru un agent Blender extern (Blender MCP). Nu presupune acces la repo:
tot contractul e aici. Sursele din care e derivat sunt [style_bible.md](../style_bible.md),
[blender_export.md](../blender_export.md), [scripts/palette.gd](../../scripts/palette.gd), foaia
de assets [sanfrancisco_inventory.md](sanfrancisco_inventory.md) (H2, §1.1) și brief-ul pistei
`docs/track_briefs/san_francisco.md` (§3, §4, §7 pașii 1c, 5 și 2b).

Sursa reproductibilă (de creat de agent): `tools/blender/build_sf_cable_car.py`.

> **Prompt de dat agentului:** de la linia orizontală de mai jos în jos e paste-ready. Restul
> paginii sunt note pentru noi.

---

## 1. Ce construiești

Un **vagon de tramvai cu cablu**, low-poly și stilizat, pentru un joc de curse cu mașinuțe de
jucărie în stil dioramă (ton *Art of Rally*: machetă de masă, NU foto-realist). Orașul e un oraș
american pe dealuri, la malul unui golf rece, la ora aurie. Vagonul e deschis, de lemn, cu
călători care stau pe scări. Rezultatul e un `.glb` care intră într-o lume cu un singur material
partajat (un atlas de culori).

## 2. Rolul lui în cadru

E un **obstacol mobil greu** pe care jucătorul îl depășește. Urcă încet (5 m/s) pe mijlocul unei
străzi abrupte, în sensul cursei, iar al doilea trece prin gura unei scurtături. Camera jocului e
la 10 m deasupra drumului și la 12,5 m în spatele mașinii, privind în jos la 29°. Vagonul se vede
**din spate și de sus, în 3/4**, de la 10 până la 180 m.

Testul de reușită: la 60–180 m, din camera de joc, citește imediat „tramvai cu cablu de lemn”:
corpul roșu-vișiniu cu panouri crem, capetele deschise cu băncile spre exterior, acoperișul cu
lanternou, călătorii agățați pe scări. De aproape (10–20 m, când îl depășești) se văd băncile,
stâlpii, clopotul și călătorii.

## 3. Formă și dimensiuni (unitate: 1 = 1 m; mașina de referință = 4,2 m)

**Gabaritul e contract fizic.** Jocul măsoară cutia de coliziune a vagonului din chenarul
modelului (AABB). Toate măsurătorile de joc s-au făcut pe o cutie de **2,5 × 3,2 × 8,5 m**.

- **AABB-ul final: exact 2,50 (lățime, X) × 3,20 (înălțime, Y) × 8,50 (lungime) m**, toleranță
  ±0,02. **Nimic nu iese din el**: niciun braț de călător, niciun clopot, nicio oglindă. Ce iese
  lățește corpul fizic.
- **Roțile și boghiurile:** două boghiuri scunde, la 1,6 m de fiecare capăt, roți ⌀ 0,6 m (8
  laturi), de la y = 0 la 0,6. Roțile stau sub caroserie (ascunse pe jumătate de o fustă).
- **Podeaua:** la +0,75. Sub ea, o fustă de lemn închisă până la +0,25.
- **Scările laterale (running boards):** pe toată lungimea, pe ambele părți, la +0,45, adânci de
  0,25 m, deci marginea lor e la ±1,25 (marginea gabaritului). **Corpul are ±1,0 m** (2,0 m lățime).
- **Cele trei secțiuni** (de la față, −Z, spre spate):
  - **capătul deschis din față** (~2,6 m): fără pereți laterali, cu **bănci longitudinale spre
    exterior** (spate în spate, pe axa vagonului), stâlpi verticali la colțuri și la mijloc (secțiune
    ≥ 0,10 m, nu mai subțiri), un parapet jos de 0,5 m la capătul din față, cu un far rotund;
  - **cabina închisă din mijloc** (~3,3 m): pereți, câte 3 ferestre pe parte (golurile adâncite
    0,08 m, nu găuri prin care se vede), ușă dublă pe fiecare parte;
  - **capătul deschis din spate** (~2,6 m), ca cel din față, cu parapet și un al doilea far.
- **Acoperișul:** de la +2,75 la +3,05, cu streașina peste capetele deschise (până la ±1,05),
  plus un **lanternou** (clerestory) mai îngust pe mijloc, până la +3,20. Capetele acoperișului
  ușor curbate în jos (bombate), ca la vagoanele vechi.
- **Clopotul:** pe acoperișul capătului din față, ⌀ 0,25 m, în gabarit.
- **Mânerul de prindere (grip):** o pârghie înaltă de 1,2 m în capătul din față, lângă ax (piesa
  care trage cablul din canal).
- **Călătorii statici:** 6–8 în picioare pe scări (3–4 pe fiecare parte, ținându-se de stâlpi) și
  4 așezați pe băncile exterioare. **Figurine de jucărie**, nu oameni realiști: corp-capsulă,
  cap-sferă (8 laturi), înalți de ~1,7 m. Cei de pe scări stau **în interiorul gabaritului**:
  lipiți de corp, înclinați ușor spre interior. Fără fețe, fără logo-uri pe haine.
- **Fără text, fără număr de linie, fără sigle** (nici pe laterale, nici pe capete). Un dreptunghi
  crem gol pe locul destinației e permis.

> Pentru scară: vagonul e de două ori cât mașina de jucărie (4,2 m) și mai înalt decât ea cu
> 1,7 m. Pe stradă, lângă el, mașina trebuie să pară mică.

## 4. Orientare

Fața (capătul cu mânerul și clopotul) privește spre **−Z în Godot**, adică **+Y în Blender**:
exportatorul glTF face `(x, y, z) → (x, z, −y)`, deci Blender +Y devine Godot −Z. „Dreapta” e +X în
ambele. Jocul pune în fața capătului −Z o bară oblică invizibilă (botul deflector), deci capătul
din față trebuie să fie chiar cel de pe −Z.

## 5. Culoare — FĂRĂ texturi proprii

UV → sloturi dintr-un atlas de paletă (32 de sloturi orizontale). Fiecare față își colapsează
toate UV-urile pe **un singur punct**, centrul slotului: `u = (slot + 0,5) / 32`, `v = 0,5`. Nu e
nevoie să încarci vreo imagine; contează doar coordonata UV. Materialul e înlocuit la runtime.

| slot | nume | **u** | hex | unde |
|---|---|---|---|---|
| 7 | `kerb_red` | **0.234375** | `#BB3522` | caroseria de jos (fustă, panourile de sub ferestre), capetele acoperișului |
| 19 | `coral_sand` | **0.609375** | `#E9DCC0` | panourile crem de deasupra, ramele ferestrelor, acoperișul |
| 28 | `log_dark` | **0.890625** | `#4A3526` | lemnul închis: băncile, stâlpii, parapetele, scările, mânerul |
| 20 | `volcanic_black` | **0.640625** | `#55535A` | geamurile, roțile, boghiurile, interiorul umbrit |
| 10 | `rust_metal` | **0.328125** | `#91461E` | clopotul, balustradele de alamă |
| 22 | `foam_white` | **0.703125** | `#E9F2F0` | farurile, dreptunghiul de destinație (gol) |
| 11 | `painted_metal` | **0.359375** | `#7692A8` | hainele călătorilor (1) |
| 9 | `wood_weathered` | **0.296875** | `#835C34` | hainele călătorilor (2) |
| 1 | `sand_mid` | **0.046875** | `#D4994D` | fețele și mâinile călătorilor |
| 2 | `sand_shadow` | **0.078125** | `#915D27` | părul, pantofii |

**Interzise:** sloturile 14, 15, 16 (roșul, albastrul și galbenul mașinilor de joc: mașinile
rămân singurele obiecte saturate din cadru) și slotul 30 (`lava_orange`). Roșul vagonului e
`kerb_red`, nu altul.

## 6. Vertex colors = AO copt

Un strat de Color Attribute, gri, care se înmulțește peste culoare în joc. 1,0 = neatins,
~0,5 = adânc. **Fără el vagonul e o pată plată**: nu e opțional.

- Gradient vertical: 0,6 la nivelul roților, 1,0 pe acoperiș.
- Întunecă: sub streașina acoperișului, interiorul capetelor deschise (sub bănci, ~0,55), golurile
  ferestrelor, între boghiuri, locul unde stau călătorii lipiți de corp.
- Eșantioane: 32.

## 7. Scară, origine, bevel

- Originea la **baza roților (y = 0), centrată în X și Z** pe gabarit.
- Scara aplicată pe nodul rădăcină (scale 1, rotație 0 la export).
- Bevel **0,04 m** pe muchiile caroseriei și ale acoperișului (piesă-vehicul). Pe stâlpi și pe
  călători nu e nevoie.

## 8. Triunghiuri

**Fără plafon** (e un vehicul-hero, două instanțe pe pistă), dar măsurat și raportat. Orientativ:
8.000–15.000. Fără șuruburi, nituri, cabluri subțiri sau balustrade mai subțiri de 0,08 m: la
distanță sclipesc pe telefon. Detaliul structural e dorit (bănci, stâlpi, lanternou, boghiuri).

## 9. Export

- glTF Binary **(.glb)**, un fișier, **`cable_car.glb`**.
- **Un singur nod-mesh**, `CableCar_Body` (tot vagonul e pe atlas, deci un material). Fără noduri
  goale între rădăcină și mesh.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere, lumini, texturi incorporate,
  animații, armături.
- **Apply Modifiers: ON.** Y-up: implicit.
- Verificare înainte de livrare: tipărește AABB-ul exportat (în coordonatele Godot) și numărul de
  triunghiuri. AABB-ul trebuie să fie 2,50 × 3,20 × 8,50 m ±0,02, cu y-ul minim 0.

---

## 10. Note pentru noi (nu fac parte din prompt)

**Consumatorul (verificat în cod, inventarul §1.1):** `BusHazard` → `PathMover._build_model`
(`scenes/props/path_mover.gd:285–320`). Instanțiază GLB-ul, îl rotește cu `model_yaw`
(`:76`), aplică clasele și **măsoară cutia de coliziune pe AABB** (`Track.model_aabb`). Botul
deflector se croiește pe cutia măsurată (`bus_hazard.gd:218–293`). Zero cod nou.

**Integrarea (coordonatorul):** în `tools/gen_sf_route.py` (blocul TRAMVAIELE, ~`:1630–1640`),
`model = ExtResource("res://assets/models/sanfrancisco/vehicles/cable_car.glb")` pe ambele noduri
`Tramvaie/Tramvai1` și `Tramvai2`, `model_yaw = 0`. `body_size` și `placeholder_*` rămân, ca
rezervă. Garda: `bash tools/sf_route_race.sh <dir>` + `python tools/sf_tram_report.py`. Contactul
pe întâlnire trebuie să rămână în banda de la 2b (tramvaiul 1: 1,3–3,2 %, tramvaiul 2: 2,1–5,5 %),
iar `ProbeLaneClear --track=17` la linia de bază (50).

**Checklist la primire:**
```
python tools/blender/verify_glb.py assets/models/sanfrancisco/vehicles/cable_car.glb 20000 --front=-Z
```
1. AABB 2,50 × 3,20 × 8,50 ±0,02, min Y = 0, centrat în XZ;
2. un singur nod `CableCar_Body`, toate UV-urile pe centre de slot, niciun slot 14–16 sau 30;
3. stratul `COLOR_0` (AO) există;
4. fața pe −Z (`--front=-Z`): clopotul și mânerul pe −Z;
5. o captură `--gamecam --bus-at=26` (tramvaiul 1 pe stradă) și `--bus-at=19` (tramvaiul 2 în
   gură), comparate cu `img/sf_route/b200_tramvai1_gamecam.png`.

**Materiale:** vagonul cade pe atlasul lumii (deja numărat). Cele 6 materiale placeholder ale
tramvaielor (3 pe instanță) dispar: garda de materiale scade cu 6.

**Respect și legal (brief §8):** fără numele liniei, al operatorului sau livreaua reală. Roșul cu
crem e generic.

## 11. Abateri de la brief și de ce

- **Corpul are 2,0 m, nu 2,4 ca vagonul real.** Scările și călătorii trebuie să încapă în cei
  2,5 m pe care sunt măsurate contactele (pașii 1c, 5, 2b). Un vagon real cu călători pe scări ar
  avea ~3,1 m.
- **Lungimea, 8,5 m în loc de ~8,3:** e placeholderul măsurat.

## 12. Dependențe și compoziție

- Pe stradă, lângă el: casele de rând pastel (`sf_painted_row_kit.md`), șinele încastrate în
  asfalt (decal), canalul cablului dintre șine. Pe strada în pantă de 11,4 %, jocul îl înclină după
  drum (`pitch_to_ground`), deci roțile trebuie să atingă planul y = 0 la ambele boghiuri.
- Al doilea vagon trece prin fața gurii străzii cu serpentine de cărămidă (hortensii roz și
  albastre). Contrastul e roșul vagonului pe cărămidă: de aceea caroseria de jos e `kerb_red`,
  iar partea de sus crem.
- **Diorama** (`img/sf_route/sf_diorama_v1.jpg`, inventarul §3.1) confirmă culorile (roșu-vișiniu
  jos, crem sus) și scara pe stradă. Acolo vagoanele sunt mai închise. **Brief-ul păstrează
  capetele deschise**, cu bănci spre exterior și călători pe scări: asta e silueta care citește
  „vagon de cablu”, nu „tramvai”. Diorama arată și **un al treilea vagon, parcat pe placa
  turnantă** din colțul de NV. E **același `cable_car.glb`**, pus ca decor static (inventarul H4),
  deci modelul nu se schimbă.
