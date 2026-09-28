# Brief assets — Jodhpur (`Track17`, temă `jodhpur`)

**Contractul complet pentru instanța de assets (Blender MCP).** Nu presupune
că ai citit altceva: tot ce trebuie e aici, plus fișierele de referință de mai
jos. Regulile generale ale pipeline-ului sunt în `docs/blender_export.md` și
`docs/style_bible.md` §4. Șabloanele de lucru sunt kitul Fiordland:
`docs/asset_briefs/fiordland_kit.md`, `tools/blender/build_fiordland_*.py`,
`verify_fiordland.sh`, `preview_fiordland.py`,
`docs/asset_briefs/fiordland_inventory.md`.

**Ce e diferit la kitul ăsta: fidelitatea față de planșă e criteriu de
acceptare, nu inspirație** (§0.1). La kiturile anterioare, piesele modelate au
ieșit departe de planșă, deși planșa era atașată. Aici fiecare piesă are
propria decupare din planșă și se livrează cu o comparație alăturată.

Referințe vizuale:

| fișier | ce e | ce iei din el |
|---|---|---|
| `docs/track_briefs/img/jodhpur_assets_v1/<nume>.png` | **decuparea piesei**, câte una pentru fiecare dintre cele 48 de desene, mărite 2× | **referința de lucru a piesei.** Silueta, numărul de elemente, proporțiile interne, culorile. E singura imagine pe care o deschizi când modelezi piesa |
| `docs/track_briefs/img/jodhpur_assets_v1.jpg` | planșa întreagă (12 rânduri) | scara relativă între piese dintr-un rând. **NU dimensiuni:** mașina de scară e desenată la fel în toate rândurile. Cotele sunt DOAR cele din tabelele de mai jos |
| `docs/track_briefs/img/jodhpur_diorama_v02.jpg` | diorama de referință (pictată, apus) | atmosfera și ansamblul (fortul sus, orașul albastru, fântâna, cenotaful pe lac), fundalul (§1.7). **Nu stilul:** diorama e pictată, cu textură de miniatură, iar planșa e cea curată. Unde se contrazic, planșa câștigă |
| `docs/track_briefs/jodhpur.md` | brief-ul pistei | §0.1 regula de artă, §4 paleta, §5 assets, §8 regulile de respect (vaca, fără logo-uri, fără text) |

## 0. Regulile care nu se negociază

1. **Categoria** e `assets/models/jodhpur/{buildings,structures,props,vehicles,animals,plants,rocks}/`.
   `dio_lib.export_glb` primește calea cu categorie
   (`"jodhpur/buildings/ghanta_ghar.glb"`) și își face folderul.
2. **Asset nou = fișier nou.** Nu se suprascrie niciun GLB existent. Placeholder-ul
   tuk-tuk-ului, `stromboli/vehicles/ape_piaggio.glb`, și `props/cow.glb` rămân
   neatinse.
3. **Instanța de assets nu atinge `scenes/` și `scripts/`.** Clasele de textură
   noi (`blue_lime_light`, `blue_lime_indigo`, `red_sandstone`, `rhyolite`,
   `rose_sandstone`), `PROP_COLLISION`, tema, `tuktuk.tres`, materialul de
   noapte al ferestrelor și montarea în `Track17.tscn` sunt ale instanței de
   gameplay. Aici se livrează GLB + build script + preview + verify + inventar +
   comparațiile de fidelitate.
4. **Paletă: zero sloturi noi.** UV1 colapsat pe centrele sloturilor
   (`slot_u`), AO copt în vertex colors, origine la bază (excepțiile sunt
   scrise în tabel), scară metrică, **scala aplicată pe fiecare nod rădăcină**
   (memoria `scala-glb-neaplicata-la-radacina`). „Înainte" e −Z în Godot, adică
   **+Y în Blender** (excepția e tuk-tuk-ul, §1.5). **Adaugă în `dio_lib.py`
   constanta `FLAMINGO_PINK = 31`**: există în `scripts/palette.gd:140`, dar
   lipsește din `dio_lib.py`, iar comentariul de acolo încă o numește rezervă
   magenta.

   | rol | slot | clasă la integrare (nu o faci tu) |
   |---|---|---|
   | var albastru al caselor (pereți, parapete) | `FOAM_WHITE` 22 | `blue_lime_light` / `blue_lime_indigo` (alb × tentă = albastru) |
   | gresia fortului (ziduri, porți, bastioane, palat, turnul cu ceas, poarta pieței) | `ROCK_LIGHT` 3 | `red_sandstone` |
   | gresia roz a fântânii | `SAND_MID` 1 | `rose_sandstone` |
   | stânca de riolit, bolovanii | `ROCK_DARK` 4 (aici e corect: riolit, nu bazalt) | `rhyolite` |
   | marmura cenotafului | `FOAM_WHITE` 22 + `MARBLE_GREY` 29 pe fețele umbrite | — |
   | lemn: uși, obloane, afetul tunului, tarabe, căruciorul | `WOOD` 9 (uși închise la culoare: `LOG_DARK` 28) | — |
   | fier: canaturile cu țepi, țeava tunului, balustrade | `PAINTED` 11 / `VOLCANIC_BLACK` 20 | — |
   | rezervoarele negre de pe acoperiș, tuk-tuk-ul | `LOG_DARK` 28 | — |
   | golurile de fereastră (ziua închise la culoare) | `VOLCANIC_BLACK` 20, **în nod `*_Glow`** (regula 7) | materialul de noapte |
   | coroane de neem/khejri, euforbii | `CACTUS_GREEN` 12 (pe fețele de sus `TROPICAL_GREEN` 21) | — |
   | trunchiuri | `LOG_DARK` 28 / `WOOD` 9 | — |
   | gălbenele, coarnele vacii | `LAVA_ORANGE` 30 (ca albedo) | — |
   | accente saturate (textile, copertine, tuk-tuk, păuni, turbane, șaua calului) | `CAR_RED` 14, `CAR_BLUE` 15, `CAR_YELLOW` 16, `FLAMINGO_PINK` 31, `TROPICAL_GREEN` 21 | **excepție declarată** cu `--allow-car-slots=<Nod>` |

   **Interzis:** `TILE_TERRACOTTA` 23 pe gresie (e țiglă și iese portocaliu).
   **Pe planșă, gresia e portocaliu-cărămiziu; în joc va fi `#A5553A` după
   tentă.** Nu încerca să prinzi culoarea planșei cu alt slot: slotul e cel din
   tabel, iar culoarea finală o dă clasa.
5. **Rosturile de zidărie NU sunt geometrie.** Pe planșă, zidurile, bastioanele
   și treptele au linii de blocuri desenate. Liniile vin din textura clasei
   (`red_sandstone`, `rose_sandstone`), triplanar, la integrare. **Geometrie
   sunt doar formele care schimbă silueta sau umbra:** creneluri, guri de
   tragere, cornișe, trepte, jharokha, arcade, nișe, soclul teșit. Regula de
   decizie e „se vede la 30 m din mașină ca formă?". Dacă da, e geometrie.
6. **Piesele care primesc clasă la integrare se sparg la export în obiecte cu
   un singur material** (memoria `clase-pe-piese-de-kit`). Un nod înseamnă un
   material potențial: casa albastră = `House_Wall` + `House_Trim` +
   `House_Glow`; poarta = `Gate_Stone` + `Gate_Doors`. **Offsetul de origine se
   calculează o dată pe ansamblu** și se aplică identic tuturor nodurilor
   (memoria `finish-recentreaza-fiecare-nod-separat`), iar verificarea e
   `verify_glb.py --origin=assembly`.
7. **Ferestrele și cadranele care se aprind noaptea sunt noduri separate, cu
   sufixul `_Glow`.** Pista trece de la apus la noapte în timpul cursei
   (`DuskCycle`, uniforma globală `dusk_lamps`). Niciun cod nu aprinde încă
   un GLB după nume (materialul de noapte e treaba instanței de gameplay), deci
   contractul tău e doar separarea: toate fețele de geam într-un nod
   `<Piesă>_Glow`, pe `VOLCANIC_BLACK` 20, **nu pe `LAVA_ORANGE`**. Ziua sunt
   găuri închise, ca pe planșă. Precedentul Chongqing punea geamurile pe
   slotul 30, iar ziua ieșeau portocalii. Aici pista începe ziua. Geamul e o
   față retrasă 0,15 m în perete, nu o față coplanară (altfel, fără lumină,
   nu se vede nimic).
8. **Fără text, fără cifre, fără logo-uri** (brief-ul pistei §8): cadranele
   turnului **fără cifre** (planșa le are; aici nu), tuk-tuk-ul fără marcă,
   tarabele fără firme.
9. **Verificarea e din fișier, nu din memorie:** `verify_glb.py` pe fiecare
   GLB, iar `preview_jodhpur.py` randează **din GLB-urile exportate**. Verdictul
   kitului e `bash tools/blender/verify_jodhpur.sh` → `VERDICT KIT: OK` **și**
   comparațiile de fidelitate aprobate (§0.1). `verify` verde nu e livrare
   (memoria `harnasul-de-kit-nu-vede-forma-nici-culoarea`).

### 0.1 Fidelitatea față de planșă — criteriul de acceptare

Planșa e sursa de **formă și culoare**. Tabelele de mai jos sunt sursa de
**cote și de contracte de cod**. Orice altă abatere de la planșă e o greșeală,
chiar dacă piesa „arată bine".

**Pentru fiecare piesă, în ordinea asta:**

1. **Deschide decuparea ei** (`jodhpur_assets_v1/<nume>.png`) și scrie în
   docstring-ul funcției de build **lista de elemente** a desenului, cu
   numere: câte etaje, câte ferestre pe fiecare față vizibilă, câte arcade,
   câte turnuri, câte cupole, câte creneluri pe latura lungă (±2), în ce parte
   urcă scara, ce iese din contur (balcon, rezervor, plantă, steag). Lista se
   scrie **înainte** de primul vertex. E contractul de fidelitate al piesei.
2. **Modelează după listă, la cotele din tabel.** Unde cota din tabel
   schimbă proporția față de desen, **coloana „abatere permisă"** spune ce se
   schimbă și ce se păstrează. În afara ei, proporțiile interne ale desenului
   (raportul etajelor, poziția ușii, lățimea turnurilor față de arcadă) se
   păstrează.
3. **Randează comparația:** `preview_jodhpur.py --compare <nume>` scrie
   `docs/asset_briefs/img/jodhpur_fidelity/<nume>.png`, cu **decuparea în
   stânga și randarea GLB-ului în dreapta**, la aceeași înălțime în pixeli.
   Randarea cere:
   - același unghi ca planșa: 3/4 din stânga-față, azimut ≈ 35°, elevație ≈ 18°
     (`preview.shot(azimuth=35, elevation=18)`), cu fațada principală spre
     cameră;
   - lumină de zi neutră și fundal gri deschis `#CFCFCF`, ca pe planșă;
   - **culoare reală, nu monocrom:** `dio_lib.atlas_material()` aplicat pe
     piesă, iar pe nodurile care primesc clasă la integrare, textura clasei
     (`preview.apply_class`) **înmulțită cu tenta din tabel**, numai în
     preview. Casele albastre trebuie să iasă albastre în comparație, nu albe.
     Harnasul actual randează monocrom, adică exact golul prin care au trecut
     piesele greșite până acum.
4. **Verifică pe imagine, element cu element, față de lista de la pasul 1**,
   și scrie rezultatul în inventar ca tabel: element | pe planșă | în GLB |
   OK/abatere. Pe lângă listă, verifică:
   - **raportul înălțime/lățime al siluetei** în comparație, față de cel
     măsurat pe decupare (coloana `h/l` din tabele, măsurată pe decupare, la
     unghiul planșei). Abaterea peste ±15% fără motiv scris în coloana
     „abatere permisă" înseamnă refacere;
   - **ordinea luminozităților** între părți (ușa mai închisă decât peretele,
     acoperișul copertinei mai deschis decât lemnul etc.) să fie aceeași ca pe
     planșă;
   - **ce iese din contur** pe planșă (steag, rezervor, plantă, balcon) să
     iasă și în GLB.
5. **Piesa se acceptă doar după ce comparația e văzută** de tine și atașată
   în PR. La finalul fiecărui val, toate comparațiile valului se adună într-o
   singură planșă, `jodhpur_fidelity_val<N>.png`, pentru verdictul
   dezvoltatorului. **Valul următor nu pornește înainte de verdict.**

**Ce NU e fidelitate:** textura pictată (rosturi, pete, fibra lemnului) nu se
copiază în geometrie (regula 0.5). Animalele sunt netede pe planșă; în GLB sunt
low-poly cu fațete mari, dar **silueta și petele de culoare** (fața neagră a
langurului, coarnele portocalii, ochii de pe coada păunului ca puncte) rămân.

## 1. Inventar și contracte

Dimensiunile sunt în metri. `h/l` e raportul siluetei pe decupare (vezi
§0.1 pasul 4). Triunghiurile se raportează, **fără plafon** (CLAUDE.md), cu
excepția pieselor multiplicate, unde bugetul e scris. **Setează `segments` /
`rings` la orice primitivă rotundă** (rezervoare, cupole, coloane): 8–16, nu
implicitul.

### 1.1 Pilotul — `build_jodhpur_pilot.py`

Două piese, făcute primele și trimise la verdict **înaintea oricărei alte
piese**: una de gresie, una albastră. Ele validează harnasul de comparație și
cele două clase de culoare.

| fișier | cote | h/l | contract | abatere permisă |
|---|---|---:|---|---|
| `buildings/ghanta_ghar.glb` | **22 m** înalt, bază **7 × 7** m | 2,17 | Reperul lui H. De jos în sus, ca pe decupare: soclu teșit, fus pătrat cu 2 ferestre înalte în arc pe fiecare față, un brâu, **4 cadrane rotunde** (câte unul pe față, discul `FOAM_WHITE`, acele `VOLCANIC_BLACK`, în nodul `Clock_Glow`), balconul pe console, lanterna cu 4 arcade și cupola cu turlă. Noduri `Tower_Stone` (`ROCK_LIGHT`), `Clock_Glow`, `Tower_Glow` (geamurile). Originea la bază, centrată | **fără cifre pe cadrane** (regula 0.8) |
| `buildings/blue_house_a.glb` | **6 × 6** m, 2 etaje, **6,5 m** până la parapet | 0,95 | Cub cu parapet, ușă în arc (`WOOD`), 2 ferestre cu obloane pe fața laterală, **scară exterioară pe latura dreaptă, care urcă spre spate** până la terasă, cu balustradă albă. Cutia de pe acoperiș (casa scării) ca pe decupare. Noduri `House_Wall` (`FOAM_WHITE`, tentă `blue_lime_light` în preview), `House_Trim` (uși, obloane), `House_Glow` | — |

### 1.2 Cetatea — `build_jodhpur_fort.py`

| fișier | cote | h/l | contract | abatere permisă |
|---|---|---:|---|---|
| `structures/fort_wall_segment.glb` | **12 m** lung (Y) × **3 m** gros × **14 m** înalt | 0,34 | Modul de zid înlănțuibil: capete plane la y = ±6. Crenelurile pe planșă sunt **dreptunghiulare, dese, cu un parapet ieșit în consolă** sub ele. Guri de tragere pe un rând sub parapet. Soclu ușor teșit la bază. `Wall_Stone`. Coliziune `mesh` la integrare | Decuparea arată **un tronson de ~3 module între două turnuri**, de aici `h/l` 0,34. Turnurile de capăt sunt piesa de mai jos, nu fac parte din modul. Compară modulul cu mijlocul tronsonului |
| `structures/fort_wall_turret.glb` | **4,5 × 4,5** m, **17 m** înalt | — | Turnul pătrat de la capetele tronsonului de pe decupare (piesă nouă, desprinsă din `fort_wall_segment`). Depășește zidul cu 3 m, cu creneluri proprii și 2 guri de tragere pe față | — |
| `structures/fort_bastion.glb` | Ø **18 m** la bază, Ø **16 m** sus, **13 m** înalt | 0,66 | Burj rotund, teșit, cu **creneluri rotunjite la vârf** (pe decupare sunt crestate altfel decât ale zidului), un rând de guri de tragere și un brâu. `Bastion_Stone`. `segments` 24 | — |
| `structures/fort_gate_jai.glb`, `fort_gate_fateh.glb`, `fort_gate_loha.glb` | ~**26 m** lățime totală, **14 m** înalte; **golul 7,0 m** | 0,42–0,44 | Două turnuri rotunde crenelate de o parte și de alta a unei arcade ascuțite, cu **canaturi de lemn deschise, bătute cu țepi de fier**. **Golul se măsoară ca GOL**, pe proiecția pe planul porții, pe gabaritul caroseriei (memoria `golul-se-masoara-pe-fereastra-lui`): 7,0 m liberi de la drum până la **2,0 m** înălțime, **cu canaturile deschise incluse**. Canaturile stau lipite de ambrazură, în afara celor 7 m, nu în gol. Cheia arcului ≥ **9 m**. Noduri `Gate_Stone`, `Gate_Doors` (`WOOD` + țepi `VOLCANIC_BLACK` ca geometrie mică, 3 × 5 pe canat). Originea la bază, **centrată pe axul golului** | Planșa le desenează aproape identic. Diferențele se păstrează și se accentuează, ca să se distingă din mașină: **Jai** are turnurile cele mai înalte (16 m) și creneluri ca pe decupare; **Fateh** are **chhatri-ul (chioșcul cu cupolă) peste arc**, ca pe decupare; **Loha** e cea mai joasă și mai simplă, cu canaturi de fier (`PAINTED`) în loc de lemn |
| `structures/palace_facade_a.glb` | **40 m** lung × **6 m** adânc × **14 m** înalt, 3 etaje | 0,29 | Fațada Moti Mahal după decupare: **rânduri de jharokha** (balcoane ieșite în consolă, cu acoperiș curbat bangla) pe primele două etaje, jali (paravane perforate) ca **fețe retrase cu grilă de 3 × 4 găuri** (geometrie), corp central mai înalt. Al treilea etaj e simplu (tăiat de cadru). `Palace_Stone`, `Palace_Glow` | Brief-ul pistei dădea 20 × 18 m. **Decuparea e un palat lung** (h/l 0,29), iar nicio cotă nu e contract de cod (e decor `DecorManual`), deci **proporția planșei câștigă** |
| `structures/palace_facade_b.glb` | **44 × 6 × 16** m (cupola centrală până la 19 m) | 0,30 | Simetrică: **pavilion central cu cupolă** și două chhatri, **turnuri de colț cu cupolițe**, arcade pe parter. Aceleași noduri | idem |
| `props/rampart_cannon.glb` | țeava **3,2 m**, total **3,6 × 1,6 × 1,5** | 0,42 | Țeavă `VOLCANIC_BLACK` cu inele și gura evazată, afet `WOOD` cu **2 roți cu spițe** (8 spițe, geometrie). Pe planșă țeava e ridicată ~10°. Coliziune `none` | — |

### 1.3 Piesele-reper — `build_jodhpur_landmarks.py`

| fișier | cote | h/l | contract | abatere permisă |
|---|---|---:|---|---|
| `structures/market_gate.glb` | **34 m** lățime totală, **17 m** înaltă, adâncime 6 m; **golul ≥ 18 m**, cu cheia ≥ **11 m** | 0,46 | Peste grila de start. Două turnuri octogonale subțiri cu chhatri, parapet crenelat drept între ele, canaturi deschise, **soclul teșit care iese lateral** ca pe decupare. Golul se măsoară ca GOL (proiecție pe plan, memoria `cota-de-contract-se-masoara-ca-gol`). Cheia ≥ 11 m pentru că prin poartă trece camera (10 m sus, 12,5 m în spate). `Gate_Stone`, `Gate_Doors` | Pe decupare, arcada e ~30% din lățime. La 18 m de gol ajunge la ~53%: arcul devine **mai turtit** (segmental), turnurile își păstrează lățimea și forma, parapetul se lungește. **Nu** crește înălțimea ca să păstreze raportul |
| `structures/stepwell_flight_module.glb` | **12 m** lat × **3 m** înalt × 2,5 m adânc | 0,21 | Modul de perete de fântână: **3 V-uri de trepte inversate** pe lățime, ca pe decupare (4 m pe V). Treptele sunt geometrie (0,3 m pe treaptă), cu umbră adevărată (memoria `silueta-inainte-de-umbrire`). Capete plane la x = ±6, ca să se înlănțuie; modulele se suprapun pe 3 etaje. `Well_Stone` (`SAND_MID`). **Decor pur, fără coliziune** (coliziunea e a terenului, `TerrainHollow`) | — |
| `structures/stepwell_corner.glb` | **6 × 6 × 3** m | 0,41 | Colț interior: câte un flux de trepte pe fiecare perete, care se întâlnesc în colț ca pe decupare | — |
| `structures/stepwell_pavilion.glb` | **20 × 6** m, 2 etaje, **9 m** + cupola centrală până la **12 m** | 0,33 | Galeria cu coloane de la capătul de vest: **arcade pe ambele etaje** (numără-le pe decupare), chhatri central cu cupolă, cupolițe la colțuri. `Well_Stone` | — |
| `structures/jaswant_thada.glb` | **30 × 20** m amprentă (cu scările), **14 m** înalt | 0,45 | Cenotaful: soclu în trepte, **scara centrală largă în față**, corpul central cu **cupola mare**, **4 chhatri mici la colțuri**, altele mai mici pe soclu (numără-le pe decupare). `FOAM_WHITE`, cu `MARBLE_GREY` pe dedesubturi. `Thada_Glow` pe golurile arcadelor | — |

### 1.4 Orașul albastru — `build_jodhpur_city.py`

Casele se multiplică (sute de exemplare), deci **≤ 300 tri pe casă simplă**
(brief-ul pistei §6; `haveli_facade` ≤ 900). Casele sunt pe **două tente**, iar
preview-ul le arată pe cea din coloană.

| fișier | cote | h/l | tentă în preview | contract (elementele de pe decupare) |
|---|---|---:|---|---|
| `buildings/blue_house_a.glb` | pilotul, §1.1 | 0,95 | light | — |
| `buildings/blue_house_b.glb` | **7 × 6** m, **3 etaje în trepte**, 9,5 m | 1,09 | light | trei volume care se retrag spre spate, rezervor negru pe cel mai înalt, **o plantă verde în colțul terasei de jos**, balustradă pe terasa din mijloc |
| `buildings/blue_house_c.glb` | **7 × 7** m, 2 etaje, 6,5 m | 0,88 | light | cub simplu cu parapet, ușă în arc pe față, 2 ferestre mici sus, **rezervor pe acoperiș** |
| `buildings/blue_house_d.glb` | **7 × 7** m, 2 etaje + cameră pe acoperiș, 8,5 m | 0,88 | indigo | **terasă cu balustradă** pe tot perimetrul, camera de pe acoperiș retrasă spre spate |
| `buildings/blue_house_e.glb` | **7 × 6** m, 2 + 1 etaje, 8,5 m | 0,83 | light | volum în L, **scară exterioară pe față** care urcă spre dreapta până la terasa de jos |
| `buildings/haveli_facade.glb` | **10 × 6** m, 3 etaje, **11 m** | 0,92 | **indigo** | casa bogată: **arcade pe parter, balcoane de piatră cu console pe etajele 1 și 2**, ferestre în arc (numără-le), balustradă pe terasă. `≤ 900` tri |
| `props/rooftop_tank.glb` | Ø **1,2** × **1,4** m | 0,79 | — | cilindru `LOG_DARK` cu **nervuri orizontale** și capac bombat. `segments` 12. Se pune pe sute de acoperișuri |
| `props/rooftop_clutter.glb` | placă **3 × 2,5** m, stâlpi 1,8 m | 0,70 | light | placa de terasă, rezervor mic, oale, **două rufe (galben și roz) pe o sfoară între doi stâlpi**, ca pe decupare |

Noduri pe fiecare casă: `House_Wall`, `House_Trim` (uși `WOOD`, obloane,
balustrade albe `FOAM_WHITE` **fără tentă**, adică nod separat de perete),
`House_Glow`. **Ușile și ferestrele sunt goluri retrase**, nu dreptunghiuri
pictate: noaptea, golul face forma casei (memoria `contrastul-nu-geometria`).

### 1.5 Bazarul și traficul — `build_jodhpur_bazaar.py`, `build_jodhpur_vehicles.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `props/stall_canopy_a.glb`, `_b`, `_c` | **3 × 2,5** m, copertina la **2,6 m** | 0,72–0,76 | Tarabă de lemn cu **4 stâlpi, copertină de pânză ușor lăsată** și lăzi cu marfă în trepte (grămezi de fructe/condimente ca volume mici colorate). Copertina: **a** `CAR_YELLOW`, **b** `FLAMINGO_PINK`, **c** `TROPICAL_GREEN`, ca pe decupare. Excepție `--allow-car-slots=Canopy,Goods` |
| `props/textile_strip.glb` | **10 m** între stâlpi, pânzele de 0,9 × 1,6 m | 0,55 | **7 pânze** (ordinea culorilor ca pe decupare: portocaliu, galben, roz, roșu, verde, galben, roz) pe o sfoară. **Pânzele sunt opace**, cu margine de jos crestată în geometrie (nu alpha: atlasul n-are alpha). Stâlpii într-un nod separat, `Poles`, pentru că peste stradă sfoara se leagă de case, nu de stâlpi. Coliziune `none` |
| `props/spice_sacks.glb` | **1,6 × 1,0 × 0,9** m | 0,61 | 3 saci de iută (`WOOD`/`SAND_MID`) cu gura răsfrântă și **conuri de condimente**: roșu (`CAR_RED`), galben (`CAR_YELLOW`) |
| `props/thela_cart.glb` | **2,4 × 1,2 × 1,1** m | 0,53 | Platformă de lemn cu ramă, **4 roți de lemn cu spițe** (pe decupare sunt 4, nu 2 roți de bicicletă: planșa câștigă), grămadă de fructe colorate |
| `props/chai_stall.glb` | **2,5 × 2,0 × 2,6** m | 0,77 | Tarabă cu **acoperiș de pânză bej** (`SAND_LIGHT`), tejghea de lemn, 2 oale de metal (`PAINTED`) și o ceainică |
| `props/marigold_garland.glb` | **2,5 m** deschidere, 0,8 m lăsare | 0,58 | Ghirlandă de gălbenele (`LAVA_ORANGE`, **ca albedo**) pe catenară, cu **5 ciucuri** care atârnă. Mărgelele: icosfere cu `subdivisions` 1. Coliziune `none` |
| `vehicles/tuktuk.glb` | **2,6 lung × 1,4 lat × 1,8 înalt** | 0,70 | **Contract `Car` (`scenes/cars/car.gd:2431-2470`), nu hazard.** (1) **Botul spre −Y în Blender** (+Z în Godot), pentru că `tuktuk.tres` păstrează `model_rotation_deg` 180, iar `car.gd` decide stânga/dreapta roților presupunând rotația de 180°. (2) Originea rădăcinii **la sol**, centrată. (3) **Roțile sunt noduri separate, copii direcți ai rădăcinii**, cu originea în **centrul osiei**: `Wheel_Front` (numele conține „front", deci virează), `Wheel_Rear_L`, `Wheel_Rear_R`, raza 0,22 m. `car.gd` citește raza din `position.y` al primei roți, deci **toate trei la aceeași înălțime**. (4) Caroseria (`Tuktuk_Body`, `LOG_DARK`), acoperișul (`Tuktuk_Roof`, `CAR_YELLOW`), jumătatea de jos galbenă și aripa roții din față ca pe decupare, parbriz `VOLCANIC_BLACK`, bancheta din spate, far rotund. **Fără logo, fără număr** (regula 0.8). Excepție `--allow-car-slots=Tuktuk_Roof,Tuktuk_Body`. Coliziunea e cutia din `body_length`/`body_width`, nu modelul. Cele două desene de pe planșă sunt **ambele din față**, deci spatele se face după fotografia oricărei autoricșe Bajaj, fără marcă: bancheta deschisă, prelata ruloată, stopurile |

### 1.6 Animalele, oamenii și teatrul mobil — `build_jodhpur_animals.py`, `build_jodhpur_theatre.py`

Rig-urile se fac cu helperele din `dio_lib.py` (`mesh_islands` L1603,
`make_armature` L1642, `weight_ramp` L1674, `pose_rotate` L1699,
`stash_actions` L1714) și se exportă cu `export_glb(..., animations=True)`.
Rețeta vacii: `build_cow_animated.py`.

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `animals/zebu_cow.glb` | **2,6 m** de la bot la crupă (coada atârnă), **1,5 m** la cocoașă în picioare | 0,76 / 0,72 | Vaca zebu: **cocoașă clară deasupra umerilor, salba (pielea de sub gât)**, coarne scurte curbate în sus, `LAVA_ORANGE`, **ghirlandă de gălbenele** pe gât și clopoțel `CAR_YELLOW`, corp `FOAM_WHITE`, bot și copite `VOLCANIC_BLACK`. **Capul spre +Y în Blender** (−Z în Godot), originea la sol. **Rest pose = în picioare.** Acțiuni: `Stand`, `LieDown`, `Lie`, `GetUp`, `Walk` (nume exacte). `Lie` trebuie să arate ca a doua decupare (`zebu_cow_lie.png`): picioarele strânse sub corp, capul sus. **Consumatorul real:** `CowGate` (`scenes/hazards/cow_gate.gd:152`, export `model`) ia coliziunea din AABB-ul modelului în rest pose și **azi nu redă nicio animație** (cablarea acțiunilor e a instanței de gameplay). De aceea AABB-ul în rest pose trebuie să aibă **lungimea pe Y între 2,6 și 2,9 m**: e cutia care închide ulicioara de 3,2 m. Excepție `--allow-car-slots=Bell` |
| `animals/peacock_closed.glb`, `animals/peacock_fanned.glb` | închis: **2,0 m** cu trena, 1,0 m înalt; deschis: evantai **1,6 × 1,4** m | 0,57 / 0,59 | **Două fișiere statice**, câte unul pe poză (nimic nu cere animație). Gât și piept `CAR_BLUE`, trenă `TROPICAL_GREEN`, **ochii de pe trenă ca discuri mici** (`CAR_BLUE` pe `CAR_YELLOW`), cu 12–20 pe evantai, nu textură. Moțul de pe cap. Excepție `--allow-car-slots=Peacock`. Coliziune `none` |
| `animals/langur.glb` | **0,7 m** așezat, coada **1,0 m** | 0,80 | Așezat pe vine, cu mâinile pe genunchi, ca pe decupare: blană `MARBLE_GREY`, **fața, mâinile și picioarele `VOLCANIC_BLACK`**, coada lungă curbată pe sol. Static |
| `animals/black_kite_bird.glb` | anvergură **1,5 m** | 0,58 | Aripi deschise, vârfurile cu pene „degete", coada în furcă. `LOG_DARK`, cioc `CAR_YELLOW`. **Rig cu o acțiune `Fly`** (bătaie lentă, 32 de cadre, buclă), fiindcă `PathMover` alege automat clipul care conține „fly". **Originea în centrul corpului** (`--origin=center`; zboară pe curbă cu `stick_to_ground = false`) |
| `animals/baraat_horse.glb` | **2,4 m** lung, **2,4 m** cu călărețul | 0,77 | Cal alb (`FOAM_WHITE`) cu **valtrap brodat** (`CAR_RED`/`CAR_YELLOW`/`TROPICAL_GREEN` în benzi), căpăstru împodobit, **mirele în alb cu turban roșu și pelerină**. Capul spre +Y. Acțiune **`Walk`** (pas, buclă; rețeta `build_donkey.py`). Excepție `--allow-car-slots=Saddle,Rider` |
| `props/baraat_band.glb` | **4 figuri** pe un rând de 4 m, **1,8 m** înalte | 0,45 | O singură piesă, statică: toboșar cu dhol mare, trompetist, toboșar cu tobă mică, al patrulea cu mâinile în șold. **Turbane `CAR_RED`, veste roșii, cămăși și pantaloni albi** (`FOAM_WHITE`). Figuri low-poly (≤ 400 tri fiecare) |
| `props/zipline_rider.glb` | figura **1,7 m**, **2,2 m** de la scripete la tălpi | 0,49 | Scripetele, hamul, figura atârnată cu picioarele înainte, **cască `CAR_YELLOW`, bluză `CAR_RED`**, pantaloni `PAINTED`. **Originea în scripete**, pentru că `PathMover` (cu `stick_to_ground = false`) îl mută pe curba cablului. Cablul **nu** e în GLB (îl trage codul, pe curbă). Înainte = +Y |

### 1.7 Stânca, plantele, candelele și fundalul — `build_jodhpur_nature.py`, `build_jodhpur_horizon.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `rocks/rhyolite_boulder_a.glb`, `_b`, `_c` | **3,0 × 2,4 × 2,0** / **3,5 × 2,2 × 1,8** / **2,5 × 2,0 × 1,6** | 0,69 / 0,53 / 0,63 | Fațete mari, plate, ca pe decupare (planșa e deja în stilul corect aici). **Muchii drepte și fețe mari**, nu rotunjite. `ROCK_DARK`. ≤ 200 tri |
| `rocks/rock_slab.glb` | **4,0 × 2,5 × 0,8** | 0,33 | Lespede joasă, cu marginile teșite. `ROCK_DARK` |
| `plants/euphorbia.glb` | **2,2 m** | 1,13 | Thor: **un trunchi scurt din care urcă 6–8 coloane** muchiate (5 fețe), de înălțimi diferite, ca un candelabru. `CACTUS_GREEN`. ≤ 300 tri |
| `plants/neem_tree.glb` | **7 m** | 0,81 | Coroană **plină, rotundă, din 5–7 volume** pe un trunchi cu 3 crengi principale. Noduri `Trunk` + `Crown`. ≤ 400 tri |
| `plants/khejri_tree.glb` | **6 m** | 0,81 | Copac de deșert: trunchi răsucit, **coroană rară, turtită, în umbrelă**, din 4–6 plăci, cu cerul vizibil printre ele. Diferența față de neem e silueta, nu culoarea. `Trunk` + `Crown`. ≤ 400 tri |
| `props/diya.glb` | Ø **0,10 m**, 0,05 m | — | Candela de lut (`TILE_TERRACOTTA` e interzis pe gresie, dar e corect pe lut ars), **o singură plasă** (merge pe `FlockProp`, care ia un singur mesh). Flacăra NU (o face shaderul `diya_flame`). ≤ 24 tri |
| `props/floating_diya.glb` | Ø **0,25 m** | — | Candela pe un talger de frunză (`TROPICAL_GREEN`), o singură plasă. ≤ 40 tri |
| `rocks/jodhpur_horizon.glb` | noduri `UmaidBhawan_A` (palatul cu cupolă, **60 × 30 × 35** m), `FarCity_A` (bandă de case albastre și bej, **150 × 20 × 12** m), `DesertRidge_A`, `DesertRidge_B` (dealuri joase de riolit, **200 × 60 × 30** m) | — | Consumatorul e `Track._build_horizon` (`track.gd:4848`): ia nodurile **după nume exact, copii direcți ai rădăcinii**, le dă **yaw aleator** și le îngroapă 4 m. Deci fiecare nod e un **volum închis, lizibil din orice azimut** (nu fațadă plată), cu originea la bază. Referința e **diorama** (palatul cu cupolă de pe dealul din dreapta, dealurile în ceață), nu planșa. `FarCity_A` are un nod-copil `FarCity_A_Glow` cu ferestre. `≤ 5.000` tri total |

### 1.8 Ce NU se generează

| piesă | de ce | ce se folosește |
|---|---|---|
| stânca fortului | `TerrainPeak` (`Track17.tscn`, `Peaks/FortRock`) | zidurile se așază pe ea |
| groapa fântânii | `TerrainHollow` (`Hollows/FountainHollow`) | modulele de trepte ca decor |
| kickerul Devkund, apa, lacul | `TrackChannel`, `custom_ravines`, shader | — |
| poarta ulicioarei | `alley_gate.gd` o face procedural | — |
| sforile de becuri | MultiMesh de sfere în cod, pe catenară | — |
| artificiile, flăcările, halourile | shadere `firework`, `diya_flame` | — |
| altarul de stradă | reuse, recolorat | `stromboli/buildings/street_shrine.glb` |
| rufele, scuterul, bicicleta, scaunele | reuse | `chongqing/props/laundry_line.glb`, `scooter.glb`, `bicycle.glb`, `table_stools.glb` |
| bougainvillea, tufa uscată | reuse | `stromboli/props/bougainvillea.glb`, `cappadocia/plants/shrub_dry.glb` |
| `doorstep_diyas` | se compun din `diya.glb` pe `FlockProp` | §1.7 |
| mașina de scară | e doar scara de pe planșă | cutia de 4 × 1,8 × 1,5 din preview |

## 2. Livrabile

| fișier | ce |
|---|---|
| `tools/blender/build_jodhpur_{pilot,fort,landmarks,city,bazaar,vehicles,animals,theatre,nature,horizon}.py` | build-urile, rulabile headless: `D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- build_jodhpur_pilot.py`. **Docstring-ul fiecărei funcții de piesă conține lista de elemente** (§0.1 pasul 1) |
| `tools/blender/preview_jodhpur.py` | (1) planșele de grup **din GLB-urile exportate**, în `docs/asset_briefs/img/jodhpur_<grup>.png`, fiecare cu cutia de referință de 4 × 1,8 × 1,5 m în cadru; (2) **`--compare <nume>`**: comparația decupare ↔ randare (§0.1 pasul 3) în `docs/asset_briefs/img/jodhpur_fidelity/<nume>.png`; (3) **`--sheet <val>`**: planșa de fidelitate a valului |
| `tools/blender/verify_jodhpur.sh` | o rulare, un verdict, excepțiile `--allow-car-slots` declarate cu motiv, `--origin=assembly` / `center` unde e cazul |
| `docs/asset_briefs/jodhpur_inventory.md` | inventarul final: tri per piesă, **cotele măsurate din GLB** față de tabel, **tabelul de fidelitate al fiecărei piese** (element / planșă / GLB / verdict), abaterile cu motiv, originile care nu sunt la bază, contractele înghețate în geometrie (golurile de 7,0 și 18 m, roțile tuk-tuk-ului, AABB-ul vacii, `*_Glow`) |
| `assets/blender/*.blend` | sursele (`save_blend`, comprimat pe cele animate) |

## 3. Ordinea de lucru (valuri; fiecare cu verify + comparații + commit + verdict)

1. **Pilotul** (§1.1): `ghanta_ghar` și `blue_house_a`, plus harnasul de
   comparație. **Stop pentru verdictul dezvoltatorului** pe
   `jodhpur_fidelity_val1.png`. Aici se decide dacă nivelul de fidelitate e
   cel dorit, înainte să existe 40 de piese greșite în același fel.
2. **Cetatea și reperele** (§1.2, §1.3): întâi `fort_gate_jai` (contractul
   golului), apoi restul.
3. **Orașul și bazarul** (§1.4, §1.5 fără tuk-tuk).
4. **Contractele de cod:** tuk-tuk-ul, vaca, uliul, tiroliana, procesiunea.
5. **Natura, candelele, fundalul** (§1.7).

Lucrează într-un worktree separat pe ramura nouă `feat/jodhpur-kit`, **pornită
din `jodhpur/track17`** (acolo sunt decupările și `CowGate`). Rulează
`godot --headless --path . --import` o dată după `git worktree add`. Commit pe
fiecare val și PR la final. Nu comite niciodată pe `main`. Nu folosi
`git stash` (e comun tuturor worktree-urilor).
