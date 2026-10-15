# Brief assets — Ha Long (`Track22`, temă `halong`)

**Contractul complet pentru instanța de assets (Blender MCP).** Nu presupune că
ai citit altceva: tot ce e nevoie e aici, plus fișierele de referință de mai
jos. Regulile generale ale pipeline-ului sunt în `docs/blender_export.md` și
`docs/style_bible.md` §4; șabloanele de lucru sunt kiturile anterioare —
`docs/asset_briefs/machu_picchu_kit.md`, `tools/blender/build_okinawa_*.py`
(cel mai apropiat vocabular: **aceeași rocă**), `verify_machupicchu.sh`,
`preview_machupicchu.py`.

Referințe vizuale:

| fișier | ce e |
|---|---|
| `docs/track_briefs/img/halong_assets_v1.jpg` | **planșa de inventar** (11 rânduri, numele scrise sub fiecare piesă) |
| `docs/track_briefs/img/halong_assets_v2_row1.jpg` | **rândul 1 regenerat** — versiunea bună a turnurilor (v1 era greșit, vezi mai jos) |
| `docs/track_briefs/img/halong_diorama_v1.jpg` | diorama de referință (stil, proporții, lumină) |
| `docs/track_briefs/img/halong_plan/halong_plan.png` | planul real al pistei, adnotat (unde stă fiecare piesă) |
| `docs/track_briefs/halong.md` | brief-ul pistei; §4 paleta, §5 assets, §2 POI-urile |

> **Planșa e sursă de siluete și culori, NU de dimensiuni.** Mașina de 4 m e
> desenată identic (58 px) în toate cele 10 rânduri, deci e un simbol de
> poziție, nu o scară. Luată de bună, ar da turnul la 12,3 m în loc de 55 și
> macacul la **4,6 m** în loc de 0,5. Cotele din acest fișier sunt singurele
> valabile. (Aceeași lecție, scrisă deja la Fiordland §9.1.)

> **Rândul 1: se folosește v2, nu v1.** Rândul 1 al planșei v1 era greșit —
> turnurile se lărgeau spre bază (măsurat pe `karst_tower_a`: 84 px la mijloc,
> **148 px** la bază, adică +76%), adică dealuri conice cu poală de bolovani, nu
> turnuri cu nișă de val. A fost regenerat, iar `halong_assets_v2_row1.jpg` e
> versiunea bună. Măsurat pe ea, cu umbra de contact exclusă:
>
> | piesă | nișă/mijloc (prag ≤ 0,70) | h/r (prag ≥ 2,50) |
> |---|---|---|
> | `karst_tower_a` | **0,48** ✔ | **4,94** ✔ |
> | `karst_tower_b` | **0,64** ✔ | **2,26** ✘ |
> | `karst_tower_c` | **0,42** ✔ | **3,75** ✔ |
>
> `karst_tower_a` a trecut de la **1,76** (v1) la **0,48**. Banda udă stă acum
> **în nișă** (luminanța cade la 50–70 la z 0,08–0,18, apoi urcă înapoi la
> bază), fără talus de bolovani.
>
> **`karst_tower_b` e desenat mai îndesat decât cota lui** (h/r 2,26 față de
> 2,81 din tabelul de mai jos): ar trebui cu ~20% mai îngust la mijloc.
> Verificat că nu e artefact de măsurare — e un bloc unitar care se desface în
> creastă dublă doar la vârf. Planșa a fost acceptată așa, fiindcă scopul
> regenerării era nișa și ea e rezolvată pe toate trei. **La construcție se ia
> cifra din tabel (h 45 m, r 16 m), nu silueta desenată.** `verify_halong.sh`
> testează h/r pe GLB, deci abaterea nu poate ajunge în kit.

## 0. Regulile care nu se negociază

1. **Categoria** e
   `assets/models/halong/{rocks,structures,buildings,plants,animals,vehicles,props}/`.
   `dio_lib.export_glb` primește calea cu categorie
   (`"halong/rocks/karst_tower_a.glb"`) și își face folderul.
2. **Asset nou = fișier nou.** Nu se suprascrie niciun GLB pe care Godot îl
   încarcă deja. `Track22.tscn` folosește acum, ca provizorii,
   `rocks/rock_large.glb`, `okinawa/structures/harbour_quay.glb` și
   `okinawa/vehicles/fishing_boat.glb` — **rămân neatinse**; piesele noi se
   exportă lângă ele, iar schimbul se face la integrare.
3. **Instanța de assets nu atinge `scenes/` și `scripts/`.** Integrarea în
   `Track22.tscn`, clasa de textură `karst_limestone` și tema sunt ale
   instanței de gameplay. Aici se livrează GLB + build script + preview +
   verify + inventar.
4. **Paletă: zero sloturi noi.** UV1 colapsat pe centrele sloturilor din atlas
   (`slot_u`), AO copt în vertex colors, origine la bază, scară metrică,
   −Z Godot = +Y Blender e „înainte". Sloturile legale pentru pista asta:

   | rol | slot |
   |---|---|
   | calcar în soare (turnuri, faleze, portal, dig) | `ROCK_LIGHT` 3 |
   | calcar în umbră, nișa de val, interiorul grotei | `ROCK_DARK` 4 |
   | piatră cioplită (chei, parapet, pavajul pavilionului) | `MARBLE_GREY` 29 |
   | vegetație de carst (ficuși, bambus, tufe de creastă) | `TROPICAL_GREEN` 21 |
   | umbră adâncă de frunziș, lemn închis | `LOG_DARK` 28 |
   | bârne, plute, punți, catarge, rame de țarc | `WOOD_WEATHERED` 9 |
   | tablă ondulată, acoperișuri | `PAINTED_METAL` 11 |
   | **butoaie de plastic albastre** (accent declarat) | `CAR_BLUE` 15 |
   | **velă ruginie** (accent declarat) | `KERB_RED` 7 |
   | plase, frânghii, paie | `DRY_VEGETATION` 13 |
   | blana macacului, lemn spălat de soare | `SAND_SHADOW` 2 |
   | spumă la baza stâncii, var pe pavilion | `FOAM_WHITE` 22 |
   | negru (goluri de fereastră, gura grotei, cauciucuri de amortizare) | `VOLCANIC_BLACK` 20 |

   Excepțiile (15 pe butoaie, 7 pe velă) se declară în `verify_halong.sh` cu
   `--allow-car-slots=<Nod>` / `--allow-slots=7`.
   **Apa NU se modelează niciodată**: `water_*_slot` sunt ale temei
   (`TROPICAL_GREEN` / `SEA_DEEP` / `ROCK_LIGHT`), iar suprafața o face pista.
5. **Dungile și rosturile NU sunt geometrie.** Pe planșă calcarul are dungi
   verticale desenate; la noi ele vin din clasa triplanară `karst_limestone`
   (aceeași dală ca la calcarul Ryukyu din Okinawa, altă tentă — brief §4),
   aplicată la integrare. În GLB se modelează **doar silueta și fațetele mari**.
6. **Piesele care primesc clasă la integrare se sparg la export în obiecte de
   un singur material** (memoria `clase-pe-piese-de-kit`): turnul =
   `Tower_Rock` + `Tower_Scrub`; casa = `House_Timber` + `House_Roof` +
   `House_Raft` + `House_Drums`; jonca = `Hull` + `Sail` + `Rigging`;
   pavilionul = `Pavilion_Stone` + `Pavilion_Timber` + `Pavilion_Roof`.
7. **Suprafețele pe care se merge au vârfuri partajate** — fără plăci
   independente, fiindcă pentru fizica întreagă un prag de 15 cm e zid
   (memoria `suprafete-cu-goluri-si-praguri`). Aici: pragul portalului de
   grotă, platforma pavilionului, coama digului.
8. **Verificarea e din fișier, nu din memorie:** `verify_glb.py` pe fiecare GLB
   cu bugetul din tabel, `preview_halong.py` randează planșele **din GLB-urile
   exportate** în `docs/asset_briefs/img/halong_<grup>.png`. Verdictul kitului e
   `bash tools/blender/verify_halong.sh` → `VERDICT KIT: OK`.

## 1. Inventar și contracte

Bugetul de materiale al pistei e **≤ 30** (garda pică la 38, brief §6), iar
triunghiurile se raportează fără plafon — dar o primitivă lăsată la rezoluția
implicită sare cu zeci de mii dintr-un foc, deci `radial_segments`/`rings` se
declară explicit la fiecare primitivă (CLAUDE.md).

### 1.1 Hero: turnurile de carst — `build_halong_karst.py`

**Piesa care decide dacă pista citește „Ha Long".** Restul kitului e context.

| fișier | ce e | înălțime | buget |
|---|---|---|---|
| `rocks/karst_tower_a.glb` | turn zvelt, vertical | **55 m** | 900 tri |
| `rocks/karst_tower_b.glb` | turn lat, creastă dublă | **45 m** | 900 tri |
| `rocks/karst_tower_c.glb` | turn înclinat, o față în consolă | **65 m** | 1000 tri |
| `rocks/karst_stack_a.glb` | stâncă-ciupercă izolată | **15 m** | 400 tri |
| `rocks/karst_stack_b.glb` | idem, altă siluetă | **9 m** | 400 tri |
| `rocks/shore_boulder.glb` | bolovan rotunjit de mal | **2,5 m** | 150 tri |

**PROFILUL, care e contractul propriu-zis.** Un turn de carst e **cel mai
îngust la linia apei**: valurile i-au mâncat o nișă în bază, deci peretele de
deasupra **iese în consolă** peste apă. Raza, ca fracție din raza de la
jumătatea înălțimii:

| z (fracție din h) | rază | ce e |
|---|---|---|
| 0,00 | **0,80** | baza, în apă |
| **0,06** | **0,62** | **NIȘA DE VAL — cel mai îngust punct din tot turnul** |
| 0,15 | 0,92 | peretele iese înapoi peste nișă |
| 0,50 | **1,00** | mijloc, perete aproape vertical |
| 0,85 | 0,90 | sub creastă |
| 1,00 | 0,70 | vârf, cu tufe |

Pentru `karst_tower_a` (rază la mijloc **16 m**): bază Ø 25,6 m, **nișă la
3,3 m înălțime, Ø 19,8 m**, mijloc Ø 32,0 m, vârf Ø 22,4 m.
Pentru `karst_tower_b`: rază la mijloc 16 m. Pentru `karst_tower_c`: 18 m.

**Contractul măsurabil, verificat de `verify_halong.sh`:**
- **lățimea la nișă ≤ 0,70 × lățimea la mijloc** (ținta 0,62). Pe planșa v1 e
  1,76 — de aceea rândul 1 se ignoră;
- **h/r ≥ 2,5** (A: 3,44 · B: 2,81 · C: 3,61). Sub 1,5 e deal, nu turn — pragul
  e cel găsit la pasul 7 al pistei, când interiorul buclei citea ca masă de
  uscat;
- **fără talus de bolovani la bază.** Turnul intră curat în apă. Molozul se
  pune, dacă e nevoie, ca `shore_boulder` separat, la integrare;
- fund plat (piesa se îngroapă în teren), origine la bază.

Banda udă întunecată de la linia apei (`ROCK_DARK`) stă **în nișă**, nu peste
toată poala. Pe planșa v1 culoarea asta e deja corectă — doar geometria lipsea.

Cele trei turnuri trebuie să stea **într-un șir fără ca silueta să se repete**:
A vertical, B cu umeri și creastă dublă, C înclinat ~12° cu o față în consolă
mai pronunțată.

### 1.2 Grota — `build_halong_grotto.py`

| fișier | ce e | cote | buget |
|---|---|---|---|
| `structures/grotto_portal.glb` | gura grotei, calcar brut cu stalactite scurte | gol **9 m lat × 7 m înalt**; piesa ~18 m lată | 700 tri |

Golul se măsoară **pe gabaritul caroseriei, nu sub buiandrug** (memoria
`golul-se-masoara-pe-fereastra-lui`): o poartă trapezoidală cu 9 m la bază dar
care se strânge poate fi mai îngustă decât pare la cota mașinii. Contractul e
**≥ 8 m liberi la înălțimea de 2,5 m**.

Spatele piesei e plat, ca să se lipească de turn. Interiorul vizibil prin gol
e `ROCK_DARK`; `CameraZone` pe grotă (deja în `Track22.tscn`, frac 0,297–0,338,
tavan 11 m) se ocupă de cameră — **piesa nu modelează tunelul**, doar gura lui.

### 1.3 Satul plutitor — `build_halong_village.py`

| fișier | ce e | cote | buget |
|---|---|---|---|
| `buildings/floating_house_a.glb` | casă de lemn pe plută, tablă ondulată, terasă cu plase | **7 × 5 m**, 4 m înalt | 600 tri |
| `buildings/floating_house_b.glb` | variantă, alt acoperiș și altă culoare de lemn | idem | 600 tri |
| `structures/fish_farm.glb` | țarc pătrat de plase pe punți, **modular** (se înlănțuie) | **8 × 8 m** | 400 tri |
| `props/net_drying_rack.glb` | rastel de plase la uscat | 4 m lat, 3 m înalt | 250 tri |
| `structures/stone_quay.glb` | cheiul de piatră cu babale (start/sosire) | modul **12 m** | 350 tri |

Butoaiele albastre (`CAR_BLUE`) sunt **singurul accent saturat** aici și stau
numai sub plute și sub țarcuri. Satul e **locuit și întreținut**, nu sărăcăcios
— regula e în promptul de dioramă și rămâne.

### 1.4 Bărcile — `build_halong_boats.py`

| fișier | ce e | lungime | buget |
|---|---|---|---|
| `vehicles/fishing_junk.glb` | joncă cu velă ruginie cu lamele | **12 m** | 800 tri |
| `vehicles/sampan_a.glb` | barcă lungă joasă cu copertină de stuf | **7 m** | 400 tri |
| `vehicles/basket_boat.glb` | barcă-coș rotundă împletită | **2 m** | 200 tri |

Jonca e hazardul de la canal, deci se sparge în `Hull` + `Sail` + `Rigging`:
vela primește `KERB_RED`, restul `WOOD_WEATHERED`. Orientarea: **prova pe +Y
Blender** (= −Z Godot), ca la trenul de pe Machu Picchu, unde orientarea
greșită a costat o rundă (memoria `machu-picchu-assets-kit`).

### 1.5 Drumul — `build_halong_road.py`

| fișier | ce e | cote | buget |
|---|---|---|---|
| `structures/coast_parapet.glb` | parapet jos de piatră-beton, **înlănțuibil** | modul **6 m**, 0,9 m înalt | 200 tri |
| `structures/stone_dike.glb` | marginea digului de piatră, **înlănțuibilă** | modul **8 m** | 250 tri |

Parapetul e cel pe care stau maimuțele (POI G), deci coama lui are o fâșie
plată de ≥ 0,35 m lățime.

### 1.6 Vegetația — `build_halong_plants.py`

| fișier | ce e | înălțime | buget |
|---|---|---|---|
| `plants/karst_ficus_a.glb` | ficus pitic cu **rădăcini aeriene pe stâncă** | **6 m** | 400 tri |
| `plants/karst_ficus_b.glb` | variantă, coroană mai deschisă | **4,5 m** | 400 tri |
| `plants/bamboo_clump.glb` | pâlc de bambus înalt și subțire | **7 m** | 300 tri |
| `plants/scrub_tuft.glb` | tufă joasă gri-verde, pentru vârfuri de turn | **0,8 m** | 120 tri |

Coroanele sunt **rare și deschise, nu brocoli** — aceeași cotă ca la fagii din
Fiordland, unde planșa a dat brocoli și kitul a impus altceva. Ficușii și
bambusul merg pe **MultiMesh** peste ~1 000 de piese (brief §6, memoria
`decor-in-masa-cere-multimesh`), deci bugetul de triunghiuri e strict.

### 1.7 Belvederea — `build_halong_belvedere.py`

| fișier | ce e | cote | buget |
|---|---|---|---|
| `structures/belvedere_pavilion.glb` | pavilion deschis de piatră și lemn, pe platformă pavată cu balustradă | **6 m lat, 4 m înalt** | 700 tri |

**De ce există piesa asta, deși nu era în §5.2.** Verdictul la volan a fost
„belvedere nu am știut unde este". Măsurat atunci (`halong_frustum_table.py`):
turnurile se văd **14/14, întregi**, apa în jos pe **17/17** puncte — deci
vizibilitatea era bună. Ce lipsea era **marginea locului**: vârful durează
3,8 s la viteză de joc, iar nimic nu spunea „aici e punctul". Pavilionul e
reperul construit care rezolvă asta; `CameraZone` cu `fov_bonus +8` (deja în
scenă) doar lărgește cadrul.

Nu e un templu și nu are acoperiș de olane curbate — e un pavilion sobru de
belvedere. (Lista de interdicții din promptul de dioramă se aplică și aici.)

### 1.8 Animale — `build_halong_animals.py`

| fișier | ce e | înălțime | buget |
|---|---|---|---|
| `animals/macaque.glb` | macac cu coadă lungă, **static**, două poze în același GLB (șezând drept / ghemuit) | **0,5 m** | 350 tri |

Static, ca gnu-ul și zebra de pe Serengeti (memoria `serengeti-assets-kit`):
intră în `MultiMesh`-ul lui `HerdHazard`, care e deja în `Track22.tscn`.
**0,5 m, nu 4,6 m** — cât ar ieși dacă s-ar lua scara de pe planșă.

### 1.9 Fundal — `build_halong_horizon.py`

| fișier | ce e | cote | buget |
|---|---|---|---|
| `rocks/karst_horizon_a.glb` | șir de turnuri, planul apropiat | lat **150 m**, înalt 50 m | 600 tri |
| `rocks/karst_horizon_b.glb` | planul mijlociu, mai palid și mai plat | lat **230 m**, înalt 45 m | 500 tri |
| `rocks/karst_horizon_c.glb` | planul depărtat, siluetă aproape plată | lat **320 m**, înalt 40 m | 400 tri |

Spate plat, **`cast_shadow` OFF** — o siluetă scalată care aruncă umbră stinge
direcționala (memoria `caster-departat-fura-umbra`). Cele trei planuri plus
ceața în strat sunt ce face belvederea să funcționeze (brief §5.2); rândul 10
al planșei v1 e corect și se folosește ca referință.

### 1.10 Ce NU se generează

Verificat în cod, nu presupus — memoria `brief-cere-glb-cod-il-face-deja`, care
a costat 4 piese fără consumator pe Machu Picchu:

| piesă | cine o face deja |
|---|---|
| tablierul de ponton, butoaiele lui, scândurile | `PontoonRoadHazard._build_visual()` + `assets/shaders/pontoon_road.gdshader`. **Cotele se iau din clasă, nu invers.** |
| terasa de abraziune (banda de jos) | `TrackBranch` — nodul `BandaDeJos` e deja în `Track22.tscn` |
| foaia de apă a mareei | `TideHazard` (cutie scalată pe Y, materialul mării) |
| masa turnurilor și a insulei | `TerrainPeak` din teren. Din kit vine **silueta**, nu volumul |
| suprafața mării, spuma, adâncimile | tema `halong` (`water_*_slot`) |
| tunelul grotei în sine | gaura o declară pista; din kit vine doar **gura** |
| podul de plute (tablier) | se decide la integrare: dacă îl face `RopeBridgeHazard`, kitul dă doar balustrada |

## 2. Livrabile

- GLB-urile în `assets/models/halong/<categorie>/`;
- `tools/blender/build_halong_*.py` (unul per grup de mai sus);
- `tools/blender/verify_halong.sh` → `VERDICT KIT: OK`, cu gărzile de la §1.1
  (raportul nișă/mijloc și h/r) scrise ca **test, nu ca notă**;
- `tools/blender/preview_halong.py` → planșe randate **din GLB-uri** în
  `docs/asset_briefs/img/halong_<grup>.png`;
- `docs/asset_briefs/halong_inventory.md` — tabelul final cu cote și bugete
  măsurate, nu cerute.

## 3. Ordinea de lucru (valuri, fiecare cu verify + preview + commit)

Valuri de **trei**, nu de opt (memoria `valuri-de-trei-nu-opt-agenti`: opt
constructori ard bugetul și niciun critic nu mai rulează).

1. **Val 1 — hero:** `karst_tower_a/b/c`, `karst_stack_a/b`, `shore_boulder`,
   `grotto_portal`. Nimic altceva nu contează dacă turnurile nu ies. Garda de
   siluetă (§1.1) se scrie **înaintea** primei piese.
2. **Val 2 — sat și bărci:** `floating_house_a/b`, `fish_farm`,
   `net_drying_rack`, `stone_quay`, `fishing_junk`, `sampan_a`, `basket_boat`.
3. **Val 3 — drum, plante, repere:** `coast_parapet`, `stone_dike`,
   `karst_ficus_a/b`, `bamboo_clump`, `scrub_tuft`, `belvedere_pavilion`,
   `macaque`, `karst_horizon_a/b/c`.

După fiecare val: `verify_halong.sh`, preview din GLB, commit. Verdictul final
al kitului e la volan, pe pistă, nu pe planșă.
