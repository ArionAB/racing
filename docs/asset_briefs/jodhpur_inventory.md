# Inventar assets — Jodhpur (`Track17`), val 1: pilotul (v3)

Contract: `docs/asset_briefs/jodhpur_kit.md` §1.1, §3 pasul 1. Verdict kit:
`bash tools/blender/verify_jodhpur.sh` → `VERDICT KIT: OK` (2/2 GLB).

**v1 ȘI v2 au fost RESPINSE** (v1 pe fidelitate generală -- vezi „Jurnalul v1"
la finalul fișierului; v2 de criticul orb + șef, runda 3 -- arcele de bază
ascuțite în loc de rotunjite, cupola bulb/onion în loc de emisferă nervurată,
banda dublă de arcade inventată la bază, ușa casei lipsea complet din
comparație, scara casei arăta ca zăbrele, culorile desaturate sistematic).
Acest inventar descrie **v3**, care corectează toate punctele de mai sus.
Rezumat runda 3 la finalul fișierului ("Jurnalul v3").

Planșa de vocabular (fiecare formă lângă cutia de referință 4×1,8×1,5 m):
`docs/asset_briefs/img/jodhpur_shapes.png`, cu randări individuale apropiate
în `docs/asset_briefs/img/jodhpur_shapes_<forma>.png` (arch_round, arch_pointed,
arch_cusped, arcade, dome_hemisphere, dome_onion, chhatri, balustrade,
railing_brackets, balcony_band, chajja, crenel_rect, crenel_round,
solid_stair, stepped_plinth).

Comparațiile de fidelitate v3 (decupare ↔ randare din GLB exportat, culoare
FLAT hex×AO prin `preview_jodhpur.py --compare`, TASK C, cu bug-ul de
desaturare corectat — vezi jurnalul v3):
`docs/asset_briefs/img/jodhpur_fidelity/ghanta_ghar.png`,
`docs/asset_briefs/img/jodhpur_fidelity/blue_house_a.png`, adunate în
`docs/asset_briefs/img/jodhpur_fidelity_val1.png`.

## `buildings/ghanta_ghar.glb` (v3)

- **Triunghiuri:** 8 154 total (`Tower_Stone` 6 706, `Clock_Glow` 1 344,
  `Tower_Glow` 104) — SUB v2 (10 156), deși forma e mai complexă: panourile
  "box-margin" (fix runda 3, patru dreptunghiuri simple pe bounding-box-ul
  golului) costă mai puțin decât inelul radial defect din v2. Buget declarat
  în `verify_jodhpur.sh`: 8 600.
- **Cote măsurate din GLB** (`Tower_Stone`):
  - bază: **7,00 × 7,00 m** — exact cota din tabel.
  - înălțime: **21,88 m** față de **22 m** contract (**−0,5%**) — bugetul de
    înălțime v3 e calculat EXPLICIT pe fracții fixe din 22,0 m per tier
    (`_TW_PLINTH_H`...`_TW_CHHATRI_H`, vezi capul lui `build_ghanta_ghar`),
    nu "ce rămâne" alocat cupolei ca în v2 (care satura și rata cota cu
    −2,7%).
  - origine: la bază, centrată (`--origin=assembly`).
- **h/l siluetă (măsurat pe randarea de comparație, prag alpha vs fundal):**
  **2,54**, față de **2,17** pe decupare (**+16,8%**, PESTE banda ±15% —
  abatere semnalată onest, nu ascunsă: chhatri-ul + cupola ocupă
  proporțional mai mult din înălțime decât pe decupare, ca lanterna și
  cupola să rămână lizibile separat la scara jocului. Nerezolvată complet
  în runda asta — următorul pas ar fi comprimarea ușoară a chhatri-ului
  sau creșterea bazei).
- **Raport lățime bază/etaj-ceas** (cerut explicit de critic): **1,33**
  față de referința măsurată pe decupare **≈1,27** (**+4,7%**, în bandă —
  v2 avea 1,43).
- **Culoare** (`Tower_Stone`, eșantion pe zid direct luminat): HSV
  ≈(24°, 67%, 54%) față de referința măsurată pe decupare (18°, 55%, 64%) —
  saturația e acum foarte aproape de cea NATIVĂ a hex-ului `#B8703F`
  (65,8%), confirmând că bug-ul de desaturare (vezi jurnalul v3) e
  corectat.
- **Tabel de fidelitate** (lista scrisă în docstring-ul `build_ghanta_ghar`
  — REscrisă runda 3 după notele șefului, care au prioritate față de
  critic pe arce/cupolă):

  | element | pe planșă (+ nota șefului) | în GLB v3 | prezent? |
  |---|---|---|---|
  | soclu în trepte (2 nivele) | soclu teșit, 2 trepte | `stepped_plinth`, 2 nivele | **prezent** |
  | tier 1, cel mai lat: UN arc ROTUNJIT mare pe fiecare față (~50% lățime, ~70% înălțime) | poartă mare, cap rotunjit | `arch_opening(style="round")`, 4 fețe, un singur gol per față | **prezent** — banda dublă inventată din v2 eliminată |
  | cornișă + balustradă joasă în consolă | bandă + parapet | `balcony_band` + `balustrade`, merloane mici dese | **prezent** |
  | tier 2, mai îngust: O fereastră mică cu arc ROTUNJIT pe fiecare față | fereastră mică, cap rotunjit | `arch_opening(style="round")`, un singur gol per față | **prezent** — cele 3 lansete ascuțite din v2 eliminate |
  | cornișă | bandă | `balcony_band` | **prezent** |
  | etajul ceasului: disc ALB curat, ramă subțire închisă, ace, FĂRĂ cifre | disc alb, cifre romane (nu se reproduc, regula 0.8) | `Clock_Glow` cu doi cilindri concentrici (ramă VOLCANIC_BLACK + disc FOAM_WHITE, tentă flat `#F2F2F2`/`#2A2A2E`) + ace | **prezent**, contrast vizibil rama/disc |
  | galerie în consolă cu balustradă/parapet crenelat, MAI LATĂ decât etajul ceasului | balcon + creneluri | `balcony_band(crenellated=True)` cu `gal_r = clock_hw*1,15` (explicit mai lată) | **prezent** |
  | chhatri deschis: coloane cu arce ROTUNJITE, clar deschis, chajja LATĂ | 4 arcade, stâlpi subțiri, deschis | `chhatri(arch_style="round")`, 8 coloane, arce deschise (`_arch_band`, `open=True`), `chajja_out=0,45` | **prezent** — arcele ascuțite din v2 eliminate |
  | cupolă EMISFERICĂ NERVURATĂ (nu onion, nu con), finial SCURT (≤10% din total) | cupolă bombată netedă | `dome(profile="hemisphere", ribs=12)`, `finial_h` limitat explicit la `min(..., TW_H*0.10)` | **prezent** — profilul "onion" din v2 înlocuit |
  | fără cifre pe cadrane | — | confirmat | **prezent** |

- **Abateri cunoscute și motiv:**
  - **h/l 2,54 vs 2,17** (+16,8%, peste bandă) — vezi mai sus.
  - **Stilul "cusped"** (multifoil) folosit inițial pentru chhatri a fost
    înlocuit cu "round" în runda 3, per nota șefului — arcele rotunjite
    ale chhatri-ului se citesc acum clar deschis, cu interior vizibil
    întunecat prin arcadă.

## `buildings/blue_house_a.glb` (v3)

- **Triunghiuri:** 5 117 total (`House_Wall` 856, `House_Trim` 13,
  `House_Rail` 4 222, `House_Glow` 26 — nod nou runda 3, vezi jurnalul).
  Buget declarat: 5 300.
- **Cote măsurate din GLB** (`House_Wall`):
  - amprentă (fără cornișa care iese): ~**6,3 × 6,6** m față de **6×6 m**
    contract — cornișa `chajja` proeminentă explică diferența (geometrie
    cerută, nu abatere de corp).
  - înălțime totală (cu cutia de pe acoperiș): **8,06 m**; pereții +
    parapetul ating **6,5 m** cum cere contractul.
  - origine: la bază, centrată (`--origin=assembly`).
- **h/l siluetă:** **0,97** față de **0,95** pe decupare (**+2,5%**, bine în
  bandă).
- **Culoare** (`House_Wall`, eșantioane pe zidul principal): HSV
  ≈(214°, 35%, 68-74%) față de referința măsurată pe decupare (217°, 49%,
  82%) — hue aproape identic, saturația e acum cea NATIVĂ a hex-ului
  `#8FB0DC` (35% — confirmat cu test izolat), corectată de la 17% (jurnalul
  v3). Rămâne sub cei 49% ai decupării (decuparea e un render stilizat,
  boostat) — dacă se dorește saturație mai mare, e o decizie de clasă de
  textură (`blue_lime_light`), nu de instanță de asset.
- **Tabel de fidelitate** (lista REscrisă runda 3, după ce un test cu cub
  colorat pe fețe a arătat care e fața dominantă în cadrul de comparație):

  | element | pe decupare | în GLB v3 | prezent? |
  |---|---|---|---|
  | usă dreptunghiulară de lemn, JUMĂTATEA STÂNGĂ a feței principale | ușă maro, prag mic | `arch_opening(style="round", pier_h≈0,94*h)` aproximează dreptunghi, WOOD, prag `House_Wall` | **prezent** — pe ACEEAȘI față ca scara (bug v2: fețe diferite) |
  | scară SOLIDĂ, obraz/dedesubt COLORAT albastru, treimea DREAPTĂ a aceleiași fețe | masă în trepte, obraz plin | `solid_stair(cheek_slot=WALL)`, obraz albastru (nu alb), nosing+balustradă albe | **prezent** — obrazul alb din critică e acum WALL (albastru) |
  | parapet cu cornișă proeminentă | bandă cu buză | `chajja` pe toate 4 laturile | **prezent** |
  | cutie pe acoperiș, retrasă spre spate | volum simplu | prezent, poziție păstrată | **prezent** — acum vizibil ALBASTRU (nu alb, vezi jurnal) |
  | linii parazite pe fața laterală (fără corespondent) | — | eliminat: geometria de pe fața ascunsă (-Y, ferestre) nu mai intră în cadrul de comparație | **absent (corect)** |

- **Abateri cunoscute și motiv:**
  - **Saturația** (35% vs 49% pe decupare) — vezi mai sus, decizie de
    clasă de textură, nu de geometrie/asset.
  - **Ușa e parțial aproape de marginea cadrului** în randarea de
    comparație — vizibilă, dar mică; repoziționarea feței (+X în loc de
    +Y) a fost determinată empiric (test cu cub colorat pe fețe), nu
    dintr-o formulă analitică a azimutului camerei — la o piesă viitoare
    cu geometrie asimetrică, testul cu cubul ar trebui rulat ÎNAINTE de a
    poziționa elementele, nu după.

## Contracte înghețate în geometrie (relevante pentru integrare)

- `ghanta_ghar`: originea la bază, centrată; cele 4 cadrane pe `Clock_Glow`
  fără cifre; golurile de geam pe `Tower_Glow`, `VOLCANIC_BLACK`, retrase în
  perete; chhatri-ul e o colonadă REALĂ (fără fund), deci `Tower_Glow` are o
  placă de fundal doar acolo unde e nevoie să blocheze cerul prin arcade
  (moștenit din v1 — verificat că tehnica veche se mai aplică, dar
  chhatri-ul v2 folosește propriul chajja/cupolă mică, nu placa de fundal a
  turnului v1).
- `blue_house_a`: originea la bază, centrată; `House_Rail` conține ATÂT
  scara solidă (slot WALL, prin `solid_stair(tread_slot=WALL)`) CÂT ȘI
  balustrada (slot FOAM_WHITE fără tentă, prin `railing_on_brackets`) — două
  sloturi diferite pe același nod, intenționat (nodul se numește după rol,
  nu după slot). **Nou în v3:** `House_Glow` (geamurile ferestrelor,
  VOLCANIC_BLACK) e acum un nod SEPARAT de `House_Trim` (ușa, WOOD) — v2
  le amesteca pe amândouă în `bg`/`House_Trim` ca efect secundar (funcția
  `arch_opening` scrie în Builder-ul primit chiar dacă apelantul nu reține
  valoarea de retur), ceea ce rupea tenta flat de comparație (un singur hex
  pe nod picta greșit fie ușa, fie geamul) și bbox-ul nodului sărea pe toată
  adâncimea casei.
- **Regula generală descoperită în acest val, pentru orice piesă viitoare
  cu `arch_opening`:** o cutie plină construită SEPARAT pe aceeași față ca
  un `arch_opening` (panoul lui propriu) z-fightează la randare (critică
  găsită și corectată de două ori în acest val — vezi jurnalul v2 mai jos).
  `arch_opening` își construiește SINGUR panoul din jurul golului
  (`panel_w`/`panel_h`); apelantul nu mai adaugă o cutie plină în același loc.
  Pentru un tier cu mai multe goluri pe aceeași față, panourile trebuie să
  fie strict mai înguste decât celula lor (`panel_w < cell_width`), cu un
  pilastru de umplutură între ele — panouri adiacente lipite muchie-la-muchie
  produc cusături de bevel (a doua critică).

## Jurnalul criticii (v2, pentru piesele viitoare)

Trecere onestă, rundă cu rundă (brief §0.1: "verdict OK nu e livrare"):

1. **TASK A, plansa de vocabular**: prima randare de ansamblu
   (`jodhpur_shapes.png`) a ieșit prea mică/fără etichete ca să verifice
   forma — comutat pe randări individuale apropiate per formă
   (`jodhpur_shapes_<forma>.png`).
2. **`_arch_profile("pointed")` avea o eroare matematică reală**: formula
   inițială a celor doi centri ("two-centred arch") plasa punctele arcului
   MULT în afara lui `[-half_w, half_w]` (măsurat: x până la 2,34 pentru
   half_w=0,7) — arcul degenera într-o formă complet greșită. Rescris cu
   derivarea corectă a razei/centrului din condiția ca cercul să treacă prin
   piciorul arcului ȘI prin cheie.
3. **`arch_opening` nu construia panoul propriu**: prima versiune presupunea
   că apelantul are deja o cutie plină și doar adăuga o "firidă" alături —
   exact capcana documentată în `build_jodhpur_pilot.py` v1 (o cutie plină
   suprapusă unui gol nu se vede niciodată din exterior). Rescris ca
   `arch_opening` să construiască SINGUR panoul complet (inel plin între
   dreptunghiul panoului și conturul golului).
4. **Proiecția radială a marginii exterioare a panoului producea un fan de
   cioburi pe panouri înalte și înguste** (ferestrele fusului turnului,
   panel_h/panel_w ≈ 3): razele dintr-un centru fix loveau muchiile
   stânga/dreapta la înălțimi foarte diferite între puncte vecine ale
   arcului, dând un inel zig-zag. Vizibil direct în randare ca "cioburi/
   fulgere" pe tot fusul. Rescris complet: umplutura panoului se face din
   4 dreptunghiuri simple (sus/jos/stânga/dreapta, pe bounding-box-ul
   golului), garantat plane indiferent de raportul panel_w/panel_h.
5. **Panouri adiacente la lățime plină (fără pilastru între ele) produceau
   cusături de bevel** pe tier2 (3 nișe) și fus (2 ferestre) — a doua sursă
   de "cioburi", separată de #4. Fix: panouri strict mai înguste decât
   celula lor + pilastru de umplutură.
6. **Rotația `atan2(nx, ny)` pentru fețe cardinale era greșită pe 2 din 4
   fețe**: formula (copiată dintr-un context diferit, aliniere pe direcția
   unui segment) mapează +Y local pe `(-nx, ny)`, nu pe `(nx, ny)` — corect
   doar când `nx=0`. Pe fețele ±X, arcele/cornișele ieșeau în oglindă/pe
   partea greșită. Corectat la `atan2(-nx, ny)` (verificat direct cu
   `Matrix.Rotation` + produsul rotației pe (0,1,0)).
7. **`chajja` nu accepta `rotation`**: cornișa casei albastre, aplicată pe
   toate 4 laturile cu un unghi calculat, ieșea toată orientată spre +Y
   (implicit), făcând peretele `House_Wall` să aibă bbox 12,6 m lățime în
   loc de ~6,6 m. Adăugat parametrul `rotation` la `chajja`.
8. **`dome(profile="hemisphere")` avea profilul de rază INVERSAT** (raza
   creștea spre vârf în loc să scadă la 0) — cupola ieșea ca un tub deschis,
   invizibilă din exterior (fără capac). Aceeași eroare de principiu (dar
   profil scris manual, nu formulă) afecta și "onion": ultimul punct avea
   rază nenulă. Ambele profiluri corectate să ajungă la rază 0 în vârf.
9. **Scara solidă (`solid_stair`) construită prima dată pe toată adâncimea
   casei** (rulaj 5,4 m pentru 6,5 m urcare) — prea lină și lungă, domina
   cadrul complet (randarea arăta o rampă uriașă diagonală peste tot
   frontul casei, ascunzând ușa). Scurtată de două ori (rulaj, lățime) până
   a devenit o piesă laterală compactă, nu o compoziție dominantă.
10. **Culoarea `blue_house_a` a rămas palidă** chiar după trecerea de la
    textură de clasă proxy la tentă FLAT (TASK C) — motivul PĂREA a fi
    unghiul camerei/luminii hărnașului. **CORECȚIE runda 3: motivul real
    era altul** — vezi jurnalul v3 mai jos (bug de conversie sRGB→liniar),
    găsit abia după ce fix-ul de unghi de lumină NU a rezolvat complet
    problema.

## Jurnalul criticii (v3, runda 3 — critic orb + șef au respins v2)

Trecere onestă, rundă cu rundă:

1. **Arcele de la bază erau ascuțite ("pointed"), nu rotunjite ("round")**
   — nota șefului (prioritate față de critic pe acest punct) a cerut
   explicit arce cu cap rotunjit la tier 1/2. Toate apelurile
   `arch_opening` de pe aceste tiere schimbate din `style="pointed"` în
   `style="round"`.
2. **Banda dublă de arcade la bază era INVENTATĂ** — v2 avea un tier1 cu
   UN arc mare ȘI un tier2 cu 3 nișe, dar ambele citeau ca "etaj dublu" pe
   aceeași bandă vizuală (proporțiile nu separau clar cele două tiere).
   Rescris cu un buget de înălțime explicit per tier (`_TW_T1_H`,
   `_TW_CORNICE1_H`, `_TW_T2_H`...), calculat să însumeze EXACT 22,0 m —
   nu "ce rămâne" alocat cupolei, ca în v2 (care rata cota cu −2,7%).
3. **Cupola era "onion" (bulb), nu emisferă nervurată** — nota șefului
   (prioritate față de critic, care ceruse tot un profil bombat/neted) a
   cerut explicit `profile="hemisphere"` cu `ribs>0`. Schimbat.
4. **Ușa casei albastre LIPSEA complet din randarea de comparație** —
   cauza reală (gasită abia după un test dedicat, vezi #7) nu era
   geometria (ușa exista, la coordonatele corecte), ci faptul că fusese
   pusă pe fața +Y, care se dovedește a fi fața ÎNGUSTĂ/laterală în cadrul
   camerei folosite de `compare()`, nu fața dominantă.
5. **Scara arăta ca "zăbrele/linii subțiri"** — de fapt geometria era deja
   solidă (`solid_stair(cheek=True)`), dar obrazul avea slotul WALL, care
   în v2 NU avea nicio tentă declarată în `COMPARE_SPECS` și cădea pe
   `atlas_material()` (textura de paletă UV simplă) — pe un obraj retras,
   fără lumină directă, asta randează aproape alb, citind ca linii subțiri
   pe fundal deschis, nu ca masă plină. Fix: tentă declarată pentru
   `House_Rail`.
6. **Toate nodurile fără tentă explicit declarată în `COMPARE_SPECS`
   (Clock_Glow, Tower_Glow, House_Trim, House_Rail) cădeau pe
   `atlas_material()` implicit** — de-aici cupola/acoperișul "gri/aproape
   alb" semnalate de critic. Fix: tentă explicită pentru FIECARE nod din
   fiecare piesă (`Tower_Stone`, `Clock_Glow`, `Tower_Glow`, `House_Wall`,
   `House_Rail`, `House_Trim`, `House_Glow`).
7. **`Clock_Glow` amestecă DOUĂ sloturi în același nod** (discul FOAM_WHITE
   + acele VOLCANIC_BLACK) — contract înghețat, nu se desparte. O tentă
   flat unică (un singur hex per nod) ar fi pictat greșit fie discul, fie
   acele. Adăugată `_apply_multi_flat_tint`: citește slotul din UV.x
   (`round(u * SLOTS - 0.5)`, UV-urile fiind colapsate pe centrul
   slotului) și aplică un material diferit per față, prin
   `material_index`.
8. **Testul empiric care a găsit fața dominantă a camerei**: un cub cu cele
   6 fețe colorate distinct (roșu=+X, verde=-X, albastru=+Y, galben=-Y,
   alb=+Z, negru=-Z), randat cu EXACT camera din `_neutral_shot`, a arătat
   că **+X e fața mare/dominantă din cadru, +Y e fața îngustă din
   dreapta** — invers față de presupunerea inițială. Ușa+scara mutate de
   pe +Y pe +X (ferestrele, invizibile în decupare oricum, mutate pe -Y).
9. **Geamurile ferestrelor și ușa erau în ACELAȘI Builder** (`bg`) — desi
   codul nu reținea `res_w["glass"]` (rezultatul funcției pentru geamuri)
   într-o variabilă, `arch_opening` scrie oricum în `bg` ca efect secundar
   al parametrului primit. `House_Trim` (exportat din `bg`) amesteca ușa
   (WOOD) cu geamurile (VOLCANIC_BLACK) — bbox-ul lui sărea pe toată
   adâncimea casei, iar tenta flat picta greșit una din cele două. Fix:
   Builder separat `bglow`, exportat ca nod nou `House_Glow`.
10. **CAUZA REALĂ a desaturării sistematice (17% vs 35-49% țintă), pe
    AMBELE piese, confirmată cu un test izolat** (cub simplu, AO forțat la
    1,0, fără alt multiply): `_flat_material` punea `int(hex,16)/255`
    (fracția sRGB) direct în `Base Color`-ul unui Principled BSDF, care
    așteaptă valori LINIARE. Blender aplică apoi conversia liniar→afișaj
    (sRGB) A DOUA OARĂ la randare — o dublă curbă gamma, care comprimă
    orice culoare spre mijlocul intervalului (desaturează), INDIFERENT de
    view_transform (Standard sau AgX — ambele presupun input liniar).
    Bug-ul exista de la introducerea `_apply_flat_tint` (TASK C, val
    anterior) și afecta silențios FIECARE tentă flat din fișier — turnul
    (portocaliu, mai aproape de mijlocul intervalului HSV) mascase
    parțial defectul, fiind mai puțin vizibil la ochi decât pe un albastru
    saturat. Fix: `_srgb_to_linear()`, aplicată pe fiecare canal înainte
    de a intra în `Base Color`. Verificat: saturația randată a urcat de la
    17% la 35% (= saturația NATIVĂ a hex-ului `#8FB0DC`), un match aproape
    exact. **Aceasta a fost cauza principală a "culorii palide" raportate
    în runda 2 și parțial în runda 1** — încercările anterioare de a
    compensa prin unghiul luminii/ambient (fill 1,1→2,6, ambient 1,0→1,8)
    atacaseră un simptom corelat (fața umbrită agravează desaturarea deja
    prezentă), nu cauza.
11. **După fix-ul #10, energiile de lumină calibrate pentru simptomul greșit
    (prea mari) supra-expuneau** — reduse din nou la valori rezonabile
    (soare 2,4, fill 1,0, ambient 0,5) după ce bug-ul real a fost corectat.

## Ce a ieșit greșit sau ambiguu în brief

- **TASK A cerea un vocabular „slot-aware, low-poly, segments
  parametrizate"** — nu preciza dacă funcțiile trebuie să fie metode pe
  `Builder` sau funcții libere care primesc `b`. Am ales funcții libere
  (ca `arch_outline`/`_arch_outline`, precedentele citate în brief), fiindcă
  `arch_opening`/`chhatri` au nevoie de DOI Builder-i (piatră + glow), ceea
  ce nu se potrivește natural cu `self` unic al unei metode.
- **Contractul `panel_w`/`panel_h` din `arch_opening` nu era cerut explicit
  de brief** — a apărut din necesitate (funcția trebuie să știe cât de mare
  e peretele din jurul golului). Consecința: orice apelant trebuie să
  gândească explicit dimensiunea panoului, nu doar a golului — cost mic de
  ergonomie, dar owner-ship clar asupra geometriei (nu mai există ambiguitate
  „cine construiește peretele").

# Jurnalul v1 (istoric — piesele respinse, păstrat pentru context)

_Comparațiile de fidelitate v1 nu mai există pe disc (suprascrise de v2);
tabelul și jurnalul de mai jos documentează DE CE au fost respinse, ca
referință pentru viitoarele piese._

## `buildings/ghanta_ghar.glb` (v1, RESPINSĂ)

Turn cu fante dreptunghiulare în loc de arcade, fără balustrade vizibile,
acoperiș piramidal drept în loc de cupolă, 19,36 m înălțime față de 22 m
contract, culoare brun-cenușiu închis în loc de gresie portocalie.

## `buildings/blue_house_a.glb` (v1, RESPINSĂ)

Casă gri (nu albastră — bug de textură de clasă lipsă), ușă pe fața greșită,
scară din trepte individuale plutitoare (fără obraz solid dedesubt).

## Cauza rădăcină (v1 → v2)

Niciun ajutor din `dio_lib.py` nu știa să deseneze un arc, o cupolă sau o
scară solidă — tot ce exista erau cutii, cilindri și prisme drepte. Fără
vocabular, orice construcție directă din primitive degenerează în cutii
tesite. TASK A (acest val, v2) a adăugat vocabularul
(`tools/blender/jodhpur_shapes.py`) înainte de a reconstrui piesele.
