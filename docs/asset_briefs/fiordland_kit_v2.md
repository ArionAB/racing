# Brief assets — Fiordland (`Track16`) — kit v2: fidelitate față de planșă

**De ce există.** Dezvoltatorul (26 oct 2026): „o parte din asseturile din
Fiordland arată cam bland, ar trebui refăcute în Blender să semene mai mult cu
ce avem și să compari cu fișa de inventar". Comparația pe toată planșa
(`docs/asset_briefs/img/fiordland_fidelity/inainte/<nume>.png`, decupare
stânga | GLB-ul de pe main dreapta) arată că aproape tot kitul v1 e o
primitivă: stâncile sunt cutii cu capac verde, casele cutii fără ferestre,
cheiul o placă, bolovanii de avalanșă bile, fagii cuburi pe un băț.

Kitul v1 a fost construit pe contractul `fiordland_kit.md`, care spunea
explicit că planșa dă „siluete și culori" — dar nimeni n-a pus randarea
lângă desen. Aici **fidelitatea față de planșă e criteriu de acceptare**, pe
tiparul `okinawa_kit_v2.md` §0.1 și al memoriei
`blender-fidelitate-fata-de-plansa`.

## 0. Ce se schimbă față de v1 și ce NU

**Se suprascrie același fișier** (aceeași cale, același nume de nod). Spre
deosebire de Okinawa v2, aici nu există o pistă veche care să țină kitul v1:
Track16 e singurul consumator, iar `Track16.tscn` are **~1.800 de instanțe**
așezate de mână pe piesele astea (658 `chasm_rock`, 313 `tussock_clump`, 287
`guard_rock`, ~300 de fagi…). Calea identică păstrează uid-ul din `.import`,
deci scena rămâne validă fără nicio editare, **cu condiția ca piesa nouă să
ocupe același loc**. De aici cele trei contracte de mai jos.

### 0.1 Contractul care ține scena validă (nu se negociază)

1. **Numele nodurilor rămân EXACT** cele din tabelul §2 (inclusiv sufixele
   `.001`, care în Godot devin `_001`). `WorldProp` leagă clasele, coliziunea
   și rupturile de accent de ele (`scenes/props/world_prop.gd`:
   `CLASSES_BY_MODEL`, `PROP_COLLISION`, `SPLIT_MODELS`, `ACCENT_SPLIT`).
   Un nod nou, în plus, e permis doar unde scrie în §2.
2. **Gabaritul (AABB) rămâne în ±10% pe fiecare axă** față de coloana „AABB
   v1" din §2, și **originea e de același tip** (bază / assembly / center /
   waterline). Piesele sunt așezate pe teren, lângă drum, în pereți de
   bolovani: una care crește cu 30% intră în drum sau în vecina ei.
   Excepțiile (unde planșa cere altă proporție și locul permite) sunt scrise
   în §2 cu motiv.
3. **Benzile de culoare pe care jocul le rupe se păstrează.** `guard_rock`:
   corpul pe `MARBLE_GREY` 29 jos, mușchiul pe `TROPICAL_GREEN` 21 doar
   **deasupra** (suprapunere de y < 5% din înălțime). Ruptura de accent
   separă cele două după slot și pune `wet_gneiss` pe corp. `rata_tree`:
   florile pe `KERB_RED` 7, frunzișul pe 21+28 (frunzișul pleacă în
   `Rata_Accente` și ia `beech_canopy`).

### 0.2 Culoarea de pe ecran nu e mereu a slotului

Pe nodurile din tabelul de mai jos, jocul **înlocuiește slotul cu o clasă
triplanară** (textură + tentă). Acolo slotul nu contează. Contează **forma**
(silueta, fațetele, cavitățile, crăpăturile) și **AO-ul copt**, care rămâne
peste clasă. Comparația (`preview_fiordland_fidelity.py`) randează aceste
noduri pe tenta aproximativă a clasei, nu pe slot.

| fișier | nod | clasa în joc |
|---|---|---|
| `stirling_ledge` | `Wall` | `wet_gneiss` (gneis gri închis, rece) |
| `torrent_chute` | `Rock` | `wet_gneiss` |
| `chasm_rock` | `Rock.001` | `wet_gneiss` pe **tot nodul** (mușchiul pictat se pierde; dacă vrei mușchi vizibil, e geometrie, nu slot) |
| `guard_rock` | `Rock.002` | `wet_gneiss` pe slotul 29 (după ruptură), mușchiul 21 rămâne |
| `beech_a/b/c` | `Trunk*` / `Crown*` | `bark_beech` / `beech_canopy` |
| `beech_dead` | `Beech_Dead` | `bark_beech` |
| `driftwood` | `Driftwood` | `wet_wood` |
| `wharf` | `Wharf` | slotul 21 e remapat pe `MARBLE_GREY` (nu pune 21 pe chei) |
| `cafe_shed`, `lodge` | `House_Roof*` | atlas (forțat), deci slotul acoperișului contează |

### 0.3 Corecturile din v1 care rămân (decizii, nu stil)

- **Fără apă în GLB.** Perdelele de cascadă, spuma, bazinele le face codul
  (`WaterfallVisual`). Planșa le-a desenat la `stirling_ledge` și
  `torrent_chute`: acolo se modelează **albia de rocă**, nu apa.
- **Fără copaci în GLB-ul stâncilor.** Pe planșă `stirling_ledge` și
  `torrent_chute` au fagi pe vârf. Fagii se pun ca decor la integrare (sunt
  deja în scenă). Pe stâncă rămâne **platoul de mușchi și iarbă**, fiindcă
  el e formă, nu decor.
- **Fără lămpi la semafor.** `traffic_light_pole` nu se reface: dezvoltatorul
  l-a scos din pistă (796d8b82), iar lampa o face `TunnelSignalHazard`.
- **`kea` nu se reface**: dezvoltatorul l-a anulat (26 sep).
- **Cotele vin din §2**, nu din planșă (mașinuța de scară e desenată la fel
  de mică pe fiecare rând, deci planșa minte la scară).
- **Fără text, fără cifre, fără logo-uri.** Excepția e `H`-ul heliportului,
  care e semn, nu text.

### 0.4 Ce se relaxează față de v1

- **Triunghiurile.** Bugetele v1 (72 de tri un bolovan, 300 un fag) sunt
  cauza principală a lipsei de detaliu. CLAUDE.md: triunghiurile nu au
  plafon, singurul veto e numărul de **materiale**, care aici e neschimbat
  (zero sloturi noi, aceleași clase). Coloana „buget v2" din §2 e
  orientativă: **piesele de masă (sute de instanțe) până la ~3×** v1, iar
  piesele unice cât cere planșa. `verify_fiordland.sh` primește bugetele
  noi, scrise de constructor cu cifra măsurată.
- **Ferestrele luminate.** v1 le interzicea fiindcă atlasul n-are emisiv.
  Pe planșă cabanele au geamuri calde, galben-portocaliu, și asta le face
  cabane. Se pun pe `SAND_LIGHT` 0 (`#E8C074`) ca **culoare**, nu emisie:
  citesc „geam cald" pe vremea ploioasă a pistei.
- **Etajele.** `cafe_shed` și `lodge` pot urca la două niveluri cu balcon,
  cum sunt pe planșă: amprenta (X/Z) rămâne în ±10%, înălțimea poate crește
  (vezi §2).

## 1. Referințe și unelte

| fișier | ce e |
|---|---|
| `docs/track_briefs/img/fiordland_assets_v1/<nume>.png` | **decuparea piesei**, mărită 3× (`tools/blender/crop_fiordland_sheet.py`, montajul `_control.png`). Referința de lucru: silueta, numărul de elemente, pozițiile lor, proporțiile interne, culorile |
| `docs/track_briefs/img/fiordland_assets_v1.jpg` | planșa întreagă |
| `docs/asset_briefs/img/fiordland_fidelity/inainte/<nume>.png` | comparația v1, ca să vezi de unde pleci |
| `tools/blender/preview_fiordland_fidelity.py` | `--compare a,b,c` → `docs/asset_briefs/img/fiordland_fidelity/<nume>.png` (decupare stânga, GLB-ul exportat dreapta, culoare reală + tenta clasei, AO) |
| `tools/blender/verify_fiordland.sh` | verdictul tehnic al kitului (bugete, sloturi, origini) |
| `docs/asset_briefs/fiordland_inventory.md` | ce s-a măsurat la v1, contractele înghețate (buza Stirling, `Boulder_A..D`, AABB autocar) |

Rulare (din rădăcina worktree-ului):

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_rocks.py
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_fiordland_fidelity.py -- --compare chasm_rock

**Randarea rulează pe GPU și e serială:** înainte de orice randare,
`mkdir D:/GameDev/.render_lock` (dacă eșuează, alt proces randează:
așteaptă și reîncearcă), `rmdir` imediat după.

## 1.1 Criteriul de acceptare (verdictul îl dă coordonatorul, nu constructorul)

Pentru fiecare piesă, comparația `fiordland_fidelity/<nume>.png` și, în
inventar, un tabel **element | pe planșă (poziție, formă, număr) | în
randare**. Elementele sunt cele care schimbă silueta sau umbra, la 30 m
din mașină: fațete, trepte, cavități, ferestre, balcoane, scânduri, rădăcini,
lame de iarbă. **Numărătoarea nu ajunge** (memoria
`numaratoarea-trece-amplasarea-nu`): contează **unde** stă elementul și ce
**formă** are. „Toate elementele prezente" scris de constructor nu e dovadă:
coordonatorul se uită la planșă.

**Silueta întâi, fațetarea după** (memoria `silueta-inainte-de-umbrire`).
Nu adăuga detalii pe o formă greșită: dacă silueta nu e a desenului,
reconstruiește volumul. Maximum **2 runde** pe aceeași piesă la același
constructor. Dacă nu converge, o reia un constructor nou, pornind de la
verdictul scris (memoria `kit-reluare-cu-constructor-nou`).

## 2. Inventar v2 — verdictul pe v1 și contractul fiecărei piese

AABB-urile sunt în **axele Godot** (Y în sus, înainte −Z), măsurate cu
`verify_glb.py` pe GLB-urile v1 de pe main (9f5dd770).

### Grupa A — stâncile mici (`build_fiordland_rocks.py`) — val 1

| piesă | instanțe | noduri | AABB v1 (X × Y × Z) | origine | buget v1 → v2 | ce arată v1 / ce cere planșa |
|---|---:|---|---|---|---|---|
| `chasm_rock` | **658** | `Rock.001` | 6,00 × 2,50 × 4,72 | bază | 416 → ~1.200 | v1: o pâine netedă cu două pastile negre lipite pe vârf. Planșa: **lespede de gneis rotunjită, cu muchii fațetate în trepte și blocuri căzute pe margine; 2 marmite ADÂNCI (cilindri săpați, cu pereți verticali și fund închis), una mai mare în față**. Atenție: e folosită și ca piatră generică (261 `gneisWall`, 78 `grohotisGramada`, 50 `waterline`): marmitele stau doar pe fața de sus, iar flancurile sunt stâncă fațetată, ca piesa să citească „stâncă" și din lateral, cu marmitele nevăzute |
| `guard_rock` | **287** | `Rock.002` | 1,18 × 0,58 × 0,70 | bază | 72 → ~250 | v1: o prismă hexagonală turtită, plată sus. Planșa: **bolovan fațetat, mai înalt decât lat** (h/l ≈ 0,8–0,9), cu fețe mari plane în unghiuri diferite și o față de rupere înclinată. **Excepție de cotă: Y poate urca la 0,80 m** (e parapet, nu obstacol de carosabil). Mușchiul e o bandă pe treimea de sus și pe muchii (benzi de y, §0.1.3) |
| `scree_slab` | 52 | `Rock.003` | 5,00 × 1,20 × 8,00 | bază | 264 → ~900 | v1: o placă maro plată cu 4 pietricele. Planșa: **con de grohotiș cu vârf fațetat și blocuri mari, înconjurat de un inel de 25–40 de pietre separate pe sol**. v1 a respins conul („apron pe pantă"). Compromis: **o movilă joasă, alungită pe Z**, cu creasta fațetată, nu un con ascuțit, plus pietrele din jur. Coliziunea e `none` (se calcă), deci se poate să fie mai înaltă: Y până la 1,5 m. Sloturi `MARBLE_GREY` 29 pe pietre, `SAND_SHADOW` 2 doar pe golurile dintre ele |

### Grupa B — pădurea (`build_fiordland_forest.py`) — val 1

| piesă | instanțe | noduri | AABB v1 | origine | buget v1 → v2 | ce arată v1 / ce cere planșa |
|---|---:|---|---|---|---|---|
| `beech_a` | 121 | `Trunk`, `Crown` | 3,7 × 7,5 × 4,1 (**excepție: coroana X/Z până la 6,0 m**; înălțimea ±10%, trunchiul rămâne coloană la origine) | assembly | 228 → ~700 | v1: 3 cuburi verzi pe un băț înclinat. Planșa: **trunchi gros și drept cu evazare la bază (3–4 rădăcini), care se desface în 3–5 ramuri groase; coroana e un nor de 8–14 mase fațetate grupate în ETAJE, cu goluri între ele prin care se vede cerul, și forma de ansamblu mai lată decât înaltă**. Contractul v1 (trunchi negru subțire, „nu brocoli") cade: planșa câștigă. Rămâne doar ideea golurilor între etaje |
| `beech_b` | 82 | `Trunk.001`, `Crown.001` | 4,7 × 10,6 × 5,0 (**excepție: coroana X/Z până la 8,0 m**) | assembly | 292 → ~800 | idem, mai înalt, coroana mai asimetrică (ramura joasă iese pe o parte, cum e pe planșă) |
| `beech_c` | 101 | `Trunk.002`, `Crown.002` | 7,5 × 14,3 × 7,2 (**excepție: coroana X/Z până la 11,0 m**) | assembly | 292 → ~900 | idem, cel mai înalt și cel mai lat, 4 etaje |
| `beech_dead` | 66 | `Beech_Dead` | 2,9 × 8,5 × 3,3 | bază | 136 → ~400 | v1: un băț verde cu 4 ace. Planșa: **trunchi gros, rupt la vârf (ciot), cu evazare și rădăcini la bază, și 6–8 crengi groase care se ramifică din nou în crenguțe**, toate conice. Fără verde pe trunchi (mușchiul doar ca petice mici, dar nodul ia `bark_beech` oricum) |
| `rata_tree` | 13 | `Rata` | 4,3 × 3,7 × 4,2 | bază | 354 → ~900 | v1: o bilă verde cu 3 fețe roșii. Planșa: **copăcel cu trunchi vizibil și ramuri, coroană în 6–9 smocuri separate, fiecare stropit cu 4–8 ciorchini roșii mici** (florile sunt puncte pe suprafață, nu fețe mari). **Excepție de cotă: Y poate urca la 5 m** (contractul v1 cerea 5 m, a ieșit 3,67). Sloturi: §0.1.3 |
| `tussock_clump` | **313** | `Tussock_Clump` | 0,68 × 0,80 × 0,68 | bază | 144 → ~450 | v1: 6 fire verzi drepte. Planșa: **smoc des de 20–30 de lame curbate în afară, ca o fântână, cu vârfurile aplecate, galben-oliv la vârf și verde la bază**; 2–3 smocuri lipite. `CACTUS_GREEN` 12 + `SAND_LIGHT` 0 pe vârfuri, sau `tint_gradient` |
| `stump` | 1 | `Stump` | 1,1 × 0,8 × 1,0 | bază | 68 → ~400 | v1: o prismă cu 2 țepi. Planșa: **ciot evazat cu 5–6 rădăcini lungi care se întind pe sol, tăietură plană sus cu inele, mușchi verde pe rădăcini și la bază** |
| `driftwood` | 37 | `Driftwood` | 4,0 × 0,4 × 0,6 | bază | 52 → ~300 | v1: un băț frânt. Planșa: **buștean gros culcat, cu capătul rupt zdrențuit și 3–4 crengi groase care se ridică din el, câteva căzute pe sol**. Excepție de cotă: Y până la 1,5 m (crengile ridicate), X/Z în ±10% |
| `chasm_bridge_rail` | 1 | `Rail_L`, `Rail_R` | 12,2 × 1,4 × 40,5 | waterline | 336 → ~1.200 | v1: două grinzi. Planșa: **gard de lemn: stâlpi pătrați la ~2,5 m, cu 2 rânduri de scânduri orizontale**. Contract înghețat: Rail_L/R la X = ±5,84, lungimea 40 m, `waterline` (geometria încalecă Y=0) |

### Grupa C — satul (`build_fiordland_village.py`) — val 1

| piesă | inst. | noduri | AABB v1 | origine | buget v1 → v2 | ce arată v1 / ce cere planșa |
|---|---:|---|---|---|---|---|
| `wharf` | 2 | `Wharf` | 4,6 × 2,6 × 20,1 | bază (axă) | 376 → ~1.500 | v1: o cutie gri cu 4 butoni. Planșa: **zid de cheu din blocuri de piatră în asize (rânduri decalate, rosturi adânci), punte de piatră/lemn deasupra și stâlpi groși de lemn (babale) la colțuri, cu capac**. Capete plane la Z = ±10,05 (contract v1) |
| `cafe_shed` | 2 | `House_Wall`, `House_Roof` | 5,8 × 3,7 × 4,6 | assembly | 308 → ~1.800 | v1: o cutie maro cu placă albastră. Planșa: **cabană din lemn închis (`LOG_DARK` 28) pe două niveluri, acoperiș în două ape de tablă gri cu streașină, ferestre calde (`SAND_LIGHT` 0) cu ramă, ușă, scări de intrare**. Amprenta X/Z ±10%, **Y până la 6,5 m** |
| `lodge` | 2 | `House_Wall.001`, `House_Roof.001` | 17,1 × 6,2 × 8,1 | assembly | 636 → ~3.000 | v1: o cutie maro cu acoperiș albastru. Planșa: **lodge lung pe două niveluri, balcon continuu la etaj cu balustradă, 8–10 ferestre calde pe fațadă, două uși, acoperiș gri în două ape cu nervuri (`corrugate`)**. Amprenta ±10%, Y până la 8 m. Corectura v1 („un singur nivel") cade |
| `heli_pad` | 1 | `HeliPad` | 11,7 × 0,3 × 12,0 | bază | 178 → ~800 | v1: un disc palid cu fețe albe aleatoare. Planșa: **tambur din blocuri de piatră pe margine, platformă întunecată (`VOLCANIC_BLACK` 20 / `ASPHALT_EDGE`), cerc alb și H alb în relief mic**. Coliziunea `none` (se calcă): **Y maxim 0,4 m** |
| `luggage_container` | 1 | `Container` | 2,4 × 2,6 × 6,1 | bază | 88 → ~500 | v1: cutie albastru-bej. Planșa: **container gri închis cu nervuri verticale (`corrugate`) pe laterale, ramă la capete, uși duble cu balamale pe capăt** |
| `road_sign_blank` | 1 | `RoadSign` | 1,6 × 2,5 × 0,1 | bază | 36 → ~200 | aproape bun. Planșa: **stâlpi de metal gri (nu lemn), panou verde cu bordură albă și ramă groasă** |
| `snow_pole` | 47 | `SnowPole` | 0,06 × 2,0 × 0,06 | bază | 40 → ~80 | aproape bun. Planșa: **benzi alternante roșu-alb pe toată înălțimea (4–5 benzi)**, nu doar vârful |

### Grupa D — stâncile-hero (`build_fiordland_rocks.py`) — val 2, după A

| piesă | noduri | AABB v1 | origine | ce arată v1 / ce cere planșa |
|---|---|---|---|---|
| `stirling_ledge` | `Wall`, `Overhang`, `Shelf` | 21,6 × 26,6 × 39,6 | assembly | v1: 4 cilindri bej în dungi, cu o placă. Planșa: **masiv de gneis în coloane verticale fațetate (prisme lungi, rupte în trepte), cu fețe mari plane, platou cu mușchi și iarbă sus, terase mici cu mușchi pe flanc, blocuri căzute la bază**. Contractele înghețate din `fiordland_inventory.md` rămân: buza surplombului la **+14,0 m**, nișa ≥ 5 m liber deasupra `Shelf`, coliziune `mesh` |
| `torrent_chute` | `Rock` | 11,0 × 16,0 × 24,0 | assembly | v1: o cutie bej cu capac verde. Planșa: **masiv fațetat, cu jgheab adânc tăiat pe toată înălțimea (albie de rocă cu trepte), blocuri la gură, platou cu mușchi**. Buza jgheabului la +14,0 m, coliziune `none` |

### Grupa E — vehiculele și avalanșa — val 2

| piesă | noduri | AABB v1 | origine | ce arată v1 / ce cere planșa |
|---|---|---|---|---|
| `coach_fiordland` | `Coach` | 3,06 × 3,29 × 8,66 | bază | v1: o cutie albă pe una verde. Planșa: **autocar cu caroserie verde (`TROPICAL_GREEN` 21 sau `CACTUS_GREEN` 12), bandă de geamuri negre continuă cu montanți, parbriz mare înclinat, acoperiș alb cu aer condiționat, roți cu jante în pasaje decupate, faruri**. **AABB-ul e contract de gameplay (≤ 3,0 × 3,2 × 8,5 + bevel, `TunnelSignalHazard`): nu crește** |
| `bush_plane` | `Plane` | 8,0 × 1,9 × 7,5 | center | v1: corect ca idee, subțire. Planșa: **fuzelaj cu volum (bot rotunjit, cabină cu geamuri), aripă sus pe montanți, coadă cu derivă roșie, dungi roșii, tren fix cu roți și carenaje, elice**. Anvergura 8,0 m, origine centru |
| `kayak_a`, `kayak_b` | `KayakA`, `KayakB` | 1,6 × 0,6 × 3,6 | bază | acum: o barcă pneumatică cu volan (reuse „Canoe – Low poly", 6.775 tri), nu caiac. Planșa: **caiac sit-on-top, fuzelat la ambele capete, 2 cockpituri negre, punte cu nervuri**. `kayak_a` roșu-portocaliu (`KERB_RED` 7 / `LAVA_ORANGE` 30), `kayak_b` galben (`CAR_YELLOW` 16). Cota: **0,6 × 0,35 × 3,6** (contractul v1). Se face din Builder și **înlocuiește reuse-ul** |
| `cruise_boat` | `Boat` | 4,8 × 6,2 × 14,0 | waterline | acum: un feribot cu coș (reuse „Cruise Ship – toofan", decizia dezvoltatorului #2, 26 sep: cutia albă v1 nu citea vapor). Planșa: **vaporaș de croazieră alb, cu carenă curbată, două punți cu șir lung de geamuri negre, punte de sus deschisă cu balustradă și bănci, pupă cu platformă de lemn**. Se construiește din Builder și **intră în joc DOAR dacă bate reuse-ul pe comparație și la camera de joc**. Altfel rămâne reuse-ul |
| `tree_avalanche` | `Boulder_A..D` | ~2,6 / 1,9 / 1,6 / 1,5 (max X,Z) | **center** | v1: bile cu țepi. Planșa: **trunchiuri rupte cu rădăcini și crengi, bolovani cu mușchi**. Contractul `AvalancheHazard` rămâne: **raport de laturi ≤ 1,5 : 1** (piesa se rostogolește într-o sferă de coliziune), deci fiecare nod e un ghem: bolovan fațetat prins în 2–4 trunchiuri scurte rupte, cu rădăcini evazate și crengi, A = mai mult rocă, D = mai mult lemn |

### Grupa F — fundalul și pinguinul — val 2

| piesă | noduri | ce arată v1 / ce cere planșa |
|---|---|---|
| `fiordland_horizon` | `FarWall_A`, `FarWall_B`, `SnowRidge_A`, `SnowRidge_B` | v1: piramide cu 3 benzi plate de culoare. Planșa: **FarWall = perete abrupt și lung, cu creasta zimțată neregulat, fețe de gneis închis acoperite de pădure (pete verde închis care urcă pe ravene), 2–4 cascade albe subțiri**; **SnowRidge = masiv cu 2–3 vârfuri, fațete mari, zăpadă în pete care coboară pe ravene (nu calotă plată), stâncă gri închis dedesubt**. Contractul v1 rămâne: volume închise lizibile din orice azimut (yaw aleator), noduri cu nume fix, `cast_shadow` OFF la integrare |
| `penguin_tawaki` | `Penguin` | v1: un prism cu cap galben. Planșa: **corp în formă de pară, aplecat ușor în față, aripioare pe lângă corp, cap negru rotund cu sprânceana galbenă care trece de ochi spre ceafă, cioc portocaliu-roșu gros, labe roz**. Cota 0,75 m |

### Nu se refac

`traffic_light_pole` (scos din pistă), `kea` (anulat), `CloudBank_A` (cod),
`fern_clump_a/b` (reuse `plants/fern_cluster.glb`).

## 3. Valuri

| val | grupa | constructor | worktree / ramură |
|---|---|---|---|
| 1 | A stâncile mici | Sonnet | `D:/GameDev/wt-fiord-v2-a` / `fiord/kit-v2-a` |
| 1 | B pădurea | Sonnet | `D:/GameDev/wt-fiord-v2-b` / `fiord/kit-v2-b` |
| 1 | C satul | Sonnet | `D:/GameDev/wt-fiord-v2-c` / `fiord/kit-v2-c` |
| 2 | D stâncile-hero | Sonnet | după A, pe același script |
| 2 | E vehicule + avalanșă | Sonnet | — |
| 2 | F fundal + pinguin | Sonnet | — |

Integrarea e a coordonatorului, în `D:/GameDev/wt-fiord-kit-v2` /
`fiord/kit-v2`: merge pe grupe, `--import`, `verify_fiordland.sh`, capturi
de joc pe Track16 (camera de joc, nu doar planșa), `probe_manual` /
`probe_decor` (decor plutitor sau îngropat după schimbarea formei),
`ProbeLaneClear` și `ProbeRace` (coliziunea hull s-a schimbat pe sute de
instanțe), apoi `bash tools/verify_local.sh` înainte de PR.

## Livrare grupa C

Ramura `fiord/kit-v2-c`, script `tools/blender/build_fiordland_village.py`
(`traffic_light_pole` neatins, GLB identic). Comparatii:
`docs/asset_briefs/img/fiordland_fidelity/{wharf,cafe_shed,lodge,heli_pad,luggage_container,road_sign_blank,snow_pole}.png`.
`verify_fiordland.sh`: toate piesele grupei C sunt OK; `cruise_boat`, `kayak_a/b`
(grupa E, neatinse aici) dau PROBLEME si inainte de aceasta livrare.
Bugete noi in `verify_fiordland.sh`: wharf 2300, cafe 2100, lodge 3700,
heli 1150, container 950, semn 160, jalon 90.

| piesa | AABB Godot X x Y x Z | tri |
|---|---|---:|
| wharf | 4,77 x 2,88 x 20,0 (capete plane la Z=±10) | 2076 |
| cafe_shed | 5,90 x 6,39 x 4,90 | 1960 |
| lodge | 17,2 x 7,74 x 8,10 | 3520 |
| heli_pad | 12,08 x 0,39 x 12,07 | 1052 |
| luggage_container | 2,40 x 2,60 x 6,10 | 864 |
| road_sign_blank | 1,66 x 2,53 x ~0,23 | 140 |
| snow_pole | 0,05 x 2,00 x 0,05 | 80 |

Culorile cladirilor: pereti `LOG_DARK` 28, acoperis `ASPHALT_EDGE` 6 cu nervuri
`ASPHALT` 5, geamuri `SAND_LIGHT` 0, accente de lemn `WOOD` 9. Fara sloturi noi.

| element | pe plansa | in randare |
|---|---|---|
| wharf: zid din asize | 4 randuri de blocuri decalate, rosturi adanci | 4 randuri de inaltimi diferite (0,50/0,38/0,50/0,37), blocuri de 0,7-2,1 m, iesite 2-10 cm, cu fata tesita (bloc tronconic, 12 tri), rosturi de 6 cm pe miez negru, 3 tonuri de gri |
| wharf: puntea | lespede palida, margini cu lespezi | punte `ASPHALT_EDGE` (gri inchis) cu 5 rosturi, zid coborat la 1,75 m ca babalele sa urce ~0,95 m peste punte in limita Y, coronament din lespezi pe ambele margini |
| wharf: babale | 4 stalpi groși de lemn cu capat taiat, doi lipiti de fata | 6 babale groase (r 0,27, capac 0,31): 3 piloti lipiti de fata +X pana peste coronament + 3 pe marginea -X, ~0,95 m peste punte, capete `SAND_LIGHT` |
| lodge: etaje, balcon | 2 niveluri, galerie la etaj | 2 niveluri, balcon continuu cu balustrada (2 lise) si 7 stalpi de sprijin |
| lodge: ferestre | grupuri calde la parter, sir la etaj, 2 la capat | parter fata: 4 ferestre + 2 usi cu geam; etaj: 8 ferestre; capete: 2+2 + una in fronton; spate 5+6 |
| lodge: acoperis | 2 ape de tabla gri cu nervuri, streasina | 2 ape, nervuri la 0,65 m, coama cu capac, streasina 1,05 m fata / 0,85 spate, frontoane inchise |
| cafe_shed | 2 niveluri, balcon, trepte dreapta, ferestre calde | idem la scara mica: 2+3 ferestre fata, usa cu trepte, balcon, capete cu 2+2 |
| heli_pad | tambur din blocuri pe 2 randuri, platforma, inel alb, H | 2 randuri x 26 blocuri, platforma `ASPHALT`, inel alb 32 segmente, H din 3 bare, relief 5 cm, Y 0,39 |
| container | nervuri verticale, rama la capete, usi duble | corp, laterale, acoperis si usi pe ACELASI slot gri inchis (`ASPHALT_EDGE`), nervurile ies doar din geometrie + AO (10/4 nervuri); rama cu 4 stalpi si 8 sine pe `ASPHALT`, usi duble cu tije si balamale pe ambele capete |
| road_sign | panou verde inchis, bordura alba groasa, 2 stalpi gri cilindrici | rama alba, camp `TROPICAL_GREEN` cu culoarea de vertex (AO) inmultita cu 0,38 in build (niciun slot verde existent nu e destul de inchis), 2 stalpi gri r 0,09 cu coliere |
| snow_pole | rosu sus, alb, rosu, alb jos | 4 benzi: alb, rosu, alb, rosu (de jos in sus) |

Diferente ramase, cinstit:
- wharf: blocurile sunt tronconice (tesite) dar tot poliedre drepte, fara
  rotunjirea pietrei de pe plansa; babalele par subtiri pe o piesa de 20 m; piesa are 20 m, plansa arata un tronson scurt (scara din brief).
  Puntea iese mai deschisa si mai uniforma decat cea de pe plansa.
- cladiri: peretii sunt busteni orizontali plati; pe plansa lemnul e mai
  neregulat, cu geamuri mai mici si multe, iar etajul e o galerie adanca.
  Ferestrele sunt toate la fel (cutie + montanti), culoarea lor calda e palida.
  Trimul de lemn e `WOOD` doar pe balcon/pervaz, restul `LOG_DARK`.
- container: un singur gri; fara pata de rugina de pe capatul din plansa.
- semn: verdele e slotul 21 intunecat prin vertex color; ramane putin mai saturat decat cel de pe plansa.
- jalon: rosul `KERB_RED` e mai inchis decat portocaliul de pe plansa.

## Livrare grupa A

Script: `tools/blender/build_fiordland_rocks.py` (v2, runda 2; `stirling_ledge` /
`torrent_chute` neatinse). Comparatii:
`docs/asset_briefs/img/fiordland_fidelity/{chasm_rock,guard_rock,scree_slab}.png`.
Bugete verify: 1500 / 200 / 3300. Zero sloturi noi.

| piesa | AABB Godot (X x Y x Z) | tri |
|---|---|---|
| `chasm_rock` | 6,03 x 2,50 x 4,48 | 1.372 |
| `guard_rock` | 1,11 x 0,80 x 0,67 | 150 |
| `scree_slab` | 5,20 x 1,47 x 7,94 | 3.114 |

### chasm_rock
| element | pe plansa | in randare |
|---|---|---|
| corp | o lespede monolitica, mai lata la baza | un miez prismatic cu contur neregulat (14 colturi) + inel de 14 coloane de flanc inclinate spre interior |
| flancuri | coloane verticale de inaltimi diferite, coboara spre fata | inaltimi 0,9-2,4 m, mai joase spre -Y (fata) |
| suprafata de sus | continua, contur neregulat, fara coroana | o singura fata de sus usor frantă; nimic ridicat deasupra ei |
| marmite | 2 taiate in suprafata, 3 lobi, pereti verticali inchisi; mare in fata-centru | 2 (boolean DIFFERENCE, prisme in 3 lobi), adancime ~1,5 m, pereti si fund VOLCANIC_BLACK |
| blocuri | 2-3 blocuri late la baza | 3 blocuri ghemuite la baza |

### guard_rock
| element | pe plansa | in randare |
|---|---|---|
| volum | bloc inalt (h/l ~0,85), putine plane mari | ~10 plane (invelitoare convexa, topire 12 grade); h 0,80 / l 1,11 = 0,72 |
| creasta | muchie verticala unde se intalnesc 2 fete | punctele din fata (x=0) formeaza creasta |
| plan de sus | inclinat | plan inclinat spre +X |
| muschi | pete pe plan, pe flancuri joase si in crapatura | pete: jumatate din planul de sus, flancurile joase din spate/capete, o petica in crapatura (fata libera) |

### scree_slab
| element | pe plansa | in randare |
|---|---|---|
| movila | un con cu varful spre spate, fete plane mari in 2-3 griuri | un singur mesh (grila de inaltimi, triunghiuri plane), varf deplasat spre +Y, patch-uri MARBLE_GREY / VOLCANIC_BLACK |
| fusta | blocuri la baza | 5 blocuri ghemuite |
| inel | 25-40 pietre separate | 22 pietre ghemuite rotunjit-poliedrice, fara piramide; fara SAND_SHADOW |

### Goluri ramase (oneste)
- `chasm_rock`: conturul de sus e prea neted fata de plansa (contur aproape oval, nu 3 lobi pe margine), iar marmitele par putin adanci din camera planseta; flancurile sunt coloane aproape uniforme ca latime. Trepte mai putine decat pe plansa.
- `guard_rock`: planele sunt mai putine si mai rare decat pe plansa; petele de muschi sunt taiate pe plane (colturoase), nu organice.
- `scree_slab`: varful e jos (1,47 m vs un con inalt pe plansa) si fetele sunt triunghiuri mici, nu placi mari; culorile sunt in pete mari, nu pe fete individuale. 3,1k tri, peste tinta 1.500-2.000.

## Livrare grupa B

Script: `tools/blender/build_fiordland_forest.py` (layout citit pe pixeli din
decupare + `_fit`, care itereaza scalarea pozitiilor pana cand extinderea
nimereste cotele). Comparatii: `docs/asset_briefs/img/fiordland_fidelity/<nume>.png`.
`verify_fiordland.sh`: bugetele grupei B actualizate, toate OK; verdictul
kitului ramane PROBLEME doar din `cruise_boat` / `kayak_a/b` (grupa E, pre-existent).

Fagii: trunchiul (baza la origine, raza 0,36 / 0,44 / 0,55) e coloana unica;
originea nu mai e centrata pe bbox-ul coroanei, ci pe baza trunchiului.

| piesa | AABB masurat (X x Y x Z) | tri |
|---|---|---:|
| beech_a | coroana 6,00 x 4,5..7,5 x 5,60; total inaltime 7,50 | 1004 |
| beech_b | coroana 8,00 x 3,8..10,6 x 7,39; total inaltime 10,60 | 906 |
| beech_c | coroana 11,01 x 4,6..14,3 x 10,18; total inaltime 14,30 | 978 |
| beech_dead | 2,90 x 8,50 x 2,90 (Z era 3,3 in v1: un arbore mort mai ingust e acceptat) | 524 |
| rata_tree | 4,30 x 5,00 x 4,20 | 830 |
| tussock_clump | 0,68 x 0,80 x 0,68 | 720 |
| stump | 1,10 x 0,80 x 1,00 | 304 |
| driftwood | 4,00 x 1,35 x 0,62 | 256 |
| chasm_bridge_rail | 11,96 x 1,40 x 40,46 (Rail_L/R centrate la +-5,84) | 720 |

| element | pe planșă | in randare |
|---|---|---|
| fagi: coroana | umbrela larga peste ~60% din inaltime, 8-9 mase festonate care se contopesc, cateva goluri intunecate | 8-9 mase aplatizate (8 seg x 2 inele + 2 umflaturi de margine), pozitii din pixeli, latime ~0,8 x inaltime; se suprapun mai mult decat inainte, dar contururile raman mai netede/poligonale decat marginea festonata a desenului; golurile dintre etaje sunt mai mari decat pe planșă |
| fagi: trunchi | partea de jos goala ~35-40%, apoi furca in V in 3-4 ramuri groase care intra in coroana | trunchi evazat cu 4 radacini, furca la ~36% din inaltime cu ramuri groase spre mase (curbate: intai in sus, apoi afara); se vad intre masele de jos, dar doar 1-2 simultan |
| beech_b | ramura joasa pe o parte | masa joasa stanga-fata iesita lateral |
| beech_dead | trunchi conic aplecat, baza evazata, 4-6 crengi groase curbate in sus cu 1-2 furci, varf zdrentuit | trunchi evazat si usor aplecat, 5 crengi curbate (J) cu 2 furci fiecare, varf cu 3 aschii; crengile pornesc mai sus/mai dese decat pe planșă si sunt mai subtiri la capete |
| rata | copacel, trunchi ~35%, 6-9 smocuri deschise, flori in petice | trunchi ~40% care se ramifica, 8 mase cu cer intre ele, 5 petice de flori turtite (rosu 7) pe masa, putin ridicate |
| tussock | fantana de 25-40 lame subtiri 30-70 grade, varfuri aplecate, 2-3 sub-smocuri | 3 sub-smocuri x 12 lame, arc cu varful aplecat, baza verde 12 / varf paiu 13; rar si cu lame prea late/drepte fata de desen (care e un smoc dens) |
| stump | 5-6 creste joase late, mușchi in petice, taietura deschisa cu inele | 6 radacini lungi si joase, mușchi in petice (12), taietura SAND_LIGHT + inel; radacinile raman conice (sectiune circulara), nu creste late turtite |
| driftwood | buștean cu capat zdrentuit, crengi rotunde in unghiuri diferite, cateva pe sol | buștean + 4 crengi conice rotunde (unghiuri diferite, una cu furca) + 2 cazute, 6 aschii la capat; fara noduri/curbura |
| chasm_bridge_rail | stalpi patrati la ~2,5-3 m, 2 scanduri groase | 15 stalpi 0,20 m la 2,86 m, scanduri 0,08 x 0,22 m decalate, LOG_DARK cu petice WOOD; fara vena lemnului |

Goluri sincere: silueta coroanei fagilor e mai aproape de desen dar nu are
marginea festonata; tussock-ul e mai rar decat desenul; radacinile ciotului
sunt conice; nu am verificat in joc, doar pe comparatie.

## Livrare grupa E

Ramura `fiord/kit-v2-e`, scripturi `tools/blender/build_fiordland_vehicles.py`
(autocar, avion, caiace, candidatul `cruise_boat_builder`) si
`build_fiordland_avalanche.py`. Partea de canoe a fost scoasa din
`build_fiordland_boats_reuse.py` (reuse-ul de vapor ramane). Comparatii:
`docs/asset_briefs/img/fiordland_fidelity/{coach_fiordland,bush_plane,kayak_a,kayak_b,cruise_boat_builder,tree_avalanche}.png`
(intrare noua `cruise_boat_builder` in `preview_fiordland_fidelity.py`, foloseste decuparea `cruise_boat`;
camera avionului mutata pe azimut 130 ca sa vada botul ca pe plansa).
`verify_fiordland.sh`: `VERDICT KIT: OK`. Bugete: coach 3600, plane 1900,
kayak 1300, avalansa 2600, cruise_boat (reuse descarcat, 1640 tri) 1700,
cruise_boat_builder 4300.

| piesa | AABB Godot X x Y x Z | tri |
|---|---|---:|
| coach_fiordland | 3,03 x 3,21 x 8,62 (contract <= 3,06 x 3,29 x 8,66) | 3492 |
| bush_plane (origine centru) | 8,00 x 1,89 x 7,33 | 1852 |
| kayak_a / kayak_b | 0,60 x 0,35 x 3,60 | 1222 / 1222 |
| cruise_boat_builder (waterline) | 4,84 x 6,20 (-1,2..5,0) x 13,94 | 4196 |
| Boulder_A / B / C / D | 2,59x2,08x2,02 / 1,89x1,65x1,65 / 1,59x1,19x1,19 / 1,49x1,14x1,19 | 463 / 578 / 589 / 908 |

Raport de laturi max pe noduri: A 1,28, B 1,15, C 1,34, D 1,31 (<= 1,5).
Sloturi: coach `CACTUS_GREEN` 12 caroserie, `FOAM_WHITE` acoperis,
`VOLCANIC_BLACK` geamuri, `MARBLE_GREY` dungi, `SAND_LIGHT` faruri;
avion `FOAM_WHITE` + `CAR_RED`; caiac A `KERB_RED` corp + `LAVA_ORANGE` punte,
B `CAR_YELLOW`, cockpit `VOLCANIC_BLACK`; avalansa `VOLCANIC_BLACK`/`ASPHALT_EDGE`
roca, `LOG_DARK` lemn, `TROPICAL_GREEN` muschi. Zero sloturi noi.

| element | pe plansa | in randare |
|---|---|---|
| coach: caroserie | verde-lime, jos, fata rotunjita | verde `CACTUS_GREEN`, profil lateral cu fata inclinata; mai inchis decat lime-ul plansei (nu exista un slot mai deschis), fata e plana, nu bombata |
| coach: geamuri | banda neagra continua cu montanti, de la usa pana in spate | banda neagra pe toata lungimea cu 8 montanti verzi, geam spate |
| coach: parbriz | mare, inclinat, cu rame | panou negru inclinat 30 grade, 2 rame verzi laterale |
| coach: acoperis | alb, aer conditionat ca placi gri | cutie alba, 2 unitati `ASPHALT_EDGE` (1,25x1,6 si 0,8x0,9) |
| coach: roti | 2 puncte, roti cu janta in pasaje decupate | 4 roti (anvelopa 14 laturi + janta + butuc) in pasaje taiate IN profil (arc de 0,7 m) cu perete interior negru |
| coach: faruri | 2 mari, jos, calde | 2 cilindri `SAND_LIGHT` + 2 cutii, grila neagra, bara neagra |
| plane: fuzelaj | volum rotund, bot cu spinner rosu | loft eliptic 10 sectiuni, spinner rosu, dunga rosie pe flanc de la nas la coada |
| plane: aripa | sus, 2 montanti subtiri, varfuri rosii | plan 6,8+2x0,6 m, grosime 0,12, varfuri rosii, 2x2 montanti negri |
| plane: coada | deriva rosie inalta, stabilizator cu varfuri rosii | deriva rosie extrudata, stabilizator alb cu varfuri rosii |
| plane: cabina | geamuri multe, parbriz mare | geam lateral lung pe fiecare parte + parbriz inclinat |
| plane: tren/elice | 2 roti mari cu picior, roata de bot, elice | picioare, 2 carenaje albe, roti cu jante, roata de bot, elice cu 1 bara-doua pale (negre) |
| kayak: forma | fuzelat la ambele capete, sheer ridicat la capete | bucla cu 15 sectiuni, latime ~ (1-|u|^2,3)^0,55, sheer 0,085 m si rocker |
| kayak: cockpituri | 2 negre in treimea de mijloc, cu scaun | 2 ovale negre cu coaming de culoarea corpului la y=-0,48 si +0,52 |
| kayak: punte | nervuri, mansoane | punte pe a doua culoare (A) / aceeasi (B), 2 nervuri + 2 cleme la fiecare capat |
| cruise: carena | alba, evazata, banda neagra sub linie | 8 sectiuni, evazare 0,45 m pe 1,1 m, banda neagra sub linia apei |
| cruise: doua punti, geamuri | sir lung de geamuri negre, punte de sus deschisa | 8 geamuri negre pe parter, front inclinat cu geamuri, timonerie cu 3 geamuri + parbriz |
| cruise: punte deschisa | balustrada, banci rosiatice | balustrada alba 3 laturi, 3 randuri x 2 banci `TILE_TERRACOTTA` cu spatar |
| cruise: pupa | platforma de lemn | puntea de la pupa (1,5 m) pe `WOOD`, cu balustrada |
| avalansa: structura | trunchi rupt cu radacini si ramuri, bolovani cu muschi | fiecare nod = bolovan fatetat (6-8 laturi) + 2-4 trunchiuri scurte, taiat/rupt (splinter), unul sau doua cu talpa evazata + 5-6 radacini, 1-2 ciot de ramura; A mult stanca, D mult lemn |

Despre `cruise_boat_builder` (parere cinstita): citeste mai clar "vaporas de excursie" decat
reuse-ul (feribot cu cos), fiindca are sirul lung de geamuri, punte deschisa cu banci si
balustrada si platforma de lemn la pupa, adica exact elementele plansei. Dar e cutie
curata: carena are doar evazare usoara, nu curbura de pe plansa, cabina e un bloc cu
colturi drepte, iar cu 4200 tri e de 2,5x reuse-ul. La camera de joc (14 m lungime) l-as
alege pentru identitate; decizia si verificarea pe Track16 raman ale coordonatorului.
Fisierul din joc `cruise_boat.glb` nu e atins.

Diferente ramase:
- coach: verdele iese ~(88,120,50) fata de lime-ul plansei; fata plata si colturile drepte; dunga laterala e doar gri-deschis, fara efectul de uzura.
- plane: fuzelajul e mai subtire decat al plansei; elicea e o singura bara inclinata; fara fereastra de usa separata.
- kayak: coca e mai ingusta in sectiune (cota de 0,35 m limiteaza adancimea); fara scaune in cockpit.
- avalansa: lemnul e brun saturat (nu exista gri-brun in paleta), muschiul `TROPICAL_GREEN` iese mai viu decat verdele-oliv al plansei; radacinile citesc ca niste cioturi scurte, nu ca o panza de radacini; bolovanul e fatetat grosier (7-8 laturi).
