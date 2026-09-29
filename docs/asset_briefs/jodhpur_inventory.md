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

## Val 2b — repere

Contract: `docs/asset_briefs/jodhpur_kit.md` §1.3, §3 pasul 2 ("întâi
`fort_gate_jai`... apoi restul" — reperele §1.3 s-au livrat separat, ca al
doilea grup al valului cetății/reperelor). Build script:
`tools/blender/build_jodhpur_landmarks.py`. Verdict kit:
`bash tools/blender/verify_jodhpur.sh` → `VERDICT KIT: OK` (7/7 GLB, 2 din
pilot + 5 din acest val).

Comparațiile de fidelitate (decupare ↔ randare din GLB exportat, tentă FLAT
hex×AO, `preview_jodhpur.py --compare`):
`docs/asset_briefs/img/jodhpur_fidelity/market_gate.png`,
`.../stepwell_flight_module.png`, `.../stepwell_corner.png`,
`.../stepwell_pavilion.png`, `.../jaswant_thada.png`, adunate în
`docs/asset_briefs/img/jodhpur_fidelity_val2b.png`.

### `structures/market_gate.glb`

- **Triunghiuri:** 8 416 total (`Gate_Stone` 6 920, `Gate_Doors` 1 408,
  `Gate_Glow` 88). Buget declarat: 9 000.
- **Cote măsurate din GLB** (`Gate_Stone`, `--origin=assembly`):
  - lățime totală: **35,89 m** față de **34 m** contract (+5,6% — turnurile
    ies puțin peste lățimea nominală; păstrat, fiindcă tăierea le-ar fi
    subțiat sub pragul de lizibilitate la 30 m).
  - înălțime: **17,28 m** față de **17 m** contract (+1,6% — bugetul de
    înălțime al chhatri-ului de pe fiecare turn a fost recalculat explicit
    din suprapunerea măsurată cupolă+finial peste `col_h`, vezi jurnalul mai
    jos; rămâne o mică depășire, acceptată).
  - adâncime: **7,2 m** față de **6 m** nominal (soclul în trepte iese lateral
    și în adâncime, ca pe decupare).
  - **golul, măsurat ca GAP pe planul porții** (memoria
    `cota-de-contract-se-masoara-ca-gol`): **18,40 m**, față de contractul
    **≥ 18,0 m** — verificat direct din constanta de construcție
    `GATE_GAP_W`, confirmat și pe `Gate_Stone` (arcul nu îngustează golul,
    `reveal=0`).
  - **cheia arcului: 11,60 m** față de contractul **≥ 11,0 m** (măsurată ca
    `crown_z`, tipărită de scriptul de build la fiecare rulare).
  - origine: la bază, comună pe ansamblu (`--origin=assembly` — `Gate_Doors`
    și `Gate_Glow` nu ating solul separat, fiind geometrie mică îngropată în
    `Gate_Stone`).
- **Tabel de fidelitate** (element / pe planșă / în GLB / verdict):

  | element | pe planșă | în GLB | prezent? |
  |---|---|---|---|
  | 2 turnuri OCTOGONALE subțiri, cu chhatri deschis + cupolă mică + finial în vârf | turnuri cu cupole bulboase mici | `b.cylinder(segments=8)` (octogonal) + `chhatri(arch_style="round")` + `dome(profile="onion")` pe fiecare turn | **prezent** |
  | parapet CRENELAT DREPT între turnuri, dese | creneluri triunghiulare/dreptunghiulare dese | `crenellation(style="rectangular", width=0.55, gap=0.42)` | **prezent** |
  | arc central TURTIT (segmental), nu ascuțit | arc cu vârf abia marcat | `arch_opening(style="round")` cu `rise` mic explicit (`gate_rise≈2,8` din `gate_pier_h≈8,8`) — aproximează segmentalul cerut de abaterea permisă | **prezent**, dar arcul se citește mai degrabă ca gol dreptunghiular decât curbat la unghiul de comparație (`reveal=0`, fără firidă vizibilă) — vezi abateri |
  | canaturi de lemn DESCHISE, cu țepi de fier (grilă mică) | canaturi cu țepi vizibili | `doorb.box` per canat (WOOD) + grilă 3×5 țepi mici (GLOW) — nod separat `Gate_Doors` | **prezent** |
  | soclu TEȘIT care iese LATERAL, cu bolovani la bază | umăr de stâncă la baza turnurilor | `stepped_plinth` (2 nivele, mai lat decât turnul) + 5 bolovani `ROCK_DARK` per parte, poziții/dimensiuni aleatoare (seed fix) | **prezent** |
  | fante de tragere verticale pe turnuri | fante subțiri | `bg.box` (GLOW), o fantă per turn, pe fața exterioară | **prezent** |

- **Abateri cunoscute și motiv:**
  - **Arcul central nu se citește curbat** în randarea de comparație — la
    `reveal=0` (fără firidă retrasă) și la unghiul camerei (azimut 35°,
    elevație 18°) pe o piesă de 34 m lățime × 6 m adâncime, golul citește ca
    un dreptunghi cu colțuri tăiate, nu ca un arc plin. Geometria arcului
    (profilul `_arch_profile("round", ...)`) există și e corectă (verificat
    separat, randare frontală directă) — e o limitare a unghiului de
    comparație pe o piesă atât de lată, nu a formei. Nu s-a găsit un unghi
    alternativ care să rămână în contractul camerei brief §0.1 pasul 3
    (unghi fix, ~35°/18°, pentru toate piesele).
  - **Randarea de comparație e puternic "în rafuit"** (raking): piesa e de
    2× mai lată decât înaltă (34×17) și doar 6 m adâncă — la azimutul fix de
    35°, camera vede fațada aproape din lungul ei, nu frontal. Verificat cu
    un test dedicat (cub cu fețe colorate, la 34×6×17): fața dominantă în
    cadru E fațada (+Y), nu muchia — deci orientarea e corectă, dar
    proporția extremă a piesei tot produce o perspectivă mai oblică decât la
    piesele aproape cubice ale pilotului. Nu e o eroare de construcție.
  - **Lățimea (35,89 m) și adâncimea (7,2 m) depășesc ușor cotele nominale**
    din tabel (34 m / 6 m) — turnurile + bolovanii ies peste linia de bază.
    Cota de contract cu adevărat critică (golul, ≥18 m) e respectată exact.

### `structures/stepwell_flight_module.glb`

- **Triunghiuri:** 2 508 (`Well_Stone`, nod unic). Buget declarat: 3 600.
- **Cote măsurate din GLB:** **12,15 × 3,00 × 2,50 m** față de **12 × 3 × 2,5 m**
  contract (+1,3% pe lățime, din capetele de îmbinare). Origine la bază,
  centrată (`--origin` implicit, `base`).
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB | prezent? |
  |---|---|---|---|
  | 3 V-uri de trepte inversate, ~4 m per V | 3 vârfuri clare, egal distanțate | `_flight_steps` × 3, vârfuri la x=-4/0/+4, praguri joase la x=-6/-2/+2/+6 | **prezent** |
  | trepte REALE (0,3 m/treaptă), nu rosturi de zidărie desenate | trepte cu umbră proprie | fiecare treaptă = cutie solidă (`WELL_STEP_H=0,3`), coboară fizic până la nivelul următor | **prezent** |
  | capete PLANE pentru înlănțuire | capete drepte, verticale | bandă verticală de 0,15 m la x=±6 | **prezent** |

- **Abateri cunoscute:** niciuna semnificativă — piesa a fost corectă din
  prima randare (nu a necesitat reorientare/rotație, spre deosebire de
  celelalte 4 piese ale valului).

### `structures/stepwell_corner.glb`

- **Triunghiuri:** 968 (`Well_Stone`, nod unic). Buget declarat: 2 400.
- **Cote măsurate din GLB:** **6,30 × 6,30 × 3,12 m** față de **6 × 6 × 3 m**
  contract (+5% pe plan, din coping-ul care iese peste zid). Origine la bază.
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB | prezent? |
  |---|---|---|---|
  | colț interior în L, două ziduri la 90° | ziduri clare, colț ascuțit | 2 plăci verticale (zid de fundal) la x=s-0,15/y=s-0,15, unite în colț | **prezent** |
  | flux de trepte pe FIECARE zid, coborând spre colțul interior | trepte descendente spre centru pe ambele brațe | 2 seturi de trepte reale (0,3 m/treaptă), urcând de la colț (jos) spre capătul exterior (sus) | **prezent** |
  | coronament plat (coping) pe muchia de sus | bandă subțire pe creastă | bandă de 0,12 m grosime pe muchia de sus a fiecărui zid | **prezent** |

- **Abateri cunoscute și motiv (rezolvate, documentate ca lecție):**
  - **Prima randare arăta DOAR doi pereți plini, fără nicio treaptă
    vizibilă** — cauza: `finish(origin="base")` recentrează piesa pe bbox,
    iar zidurile (construite lângă x=y=s) ajungeau pe partea +X/+Y, exact
    spre cameră, blocând complet vederea spre interiorul în trepte (colțul
    ajungea cu spatele la cameră). Fix: rotație 180° în jurul lui Z aplicată
    vertex-cu-vertex după `to_object()`, ca interiorul deschis să ajungă cu
    fața spre cameră. Comparația finală arată clar ambele fluxuri de trepte.

### `structures/stepwell_pavilion.glb`

- **Triunghiuri:** 10 094 total (`Well_Stone` 9 968 aprox, `Well_Glow` mic —
  vezi verify pentru split exact; nodul GLOW poate fi gol dacă `arcade
  (glass=False)` nu scrie nimic în `bg`, caz în care `_finish_or_none` îl
  omite din fișier — **aici a rămas doar `Well_Stone`**, verificat cu
  `verify_glb.py`, deci `Well_Glow` NU apare ca nod separat în acest export).
  Buget declarat: 10 500.
- **Cote măsurate din GLB** (`--origin=assembly`): **20,55 × 7,6 × 13,06 m**
  față de **20 × 6 × 9 m + cupolă până la 12 m** contract — lățimea e
  aproape exactă (+2,7%), adâncimea puțin peste (pavilionul central iese în
  față), înălțimea totală (13,06 m) ușor peste cota cupolei (12 m,
  +8,8%, din marja `dome_r`/`drum_h`/`finial_h` calculată pe `remaining`).
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB | prezent? |
  |---|---|---|---|
  | arcade pe DOUĂ etaje, pe toată lungimea galeriei | ~4 arce vizibile per parte per etaj | `arcade(n_bays=9)` × 2 etaje, arce rotunjite deschise (`glass=False`) | **prezent** |
  | chhatri mic la FIECARE capăt | cupolițe mici la colțuri | `chhatri(n_columns=6)` la ambele capete, deasupra acoperișului galeriei | **prezent** |
  | pavilion CENTRAL mai înalt, iesit în față, cu balcon la etaj | corp central proeminent | corp central (`cw=5, cd=7,4`), arc de intrare la parter, `balcony_band`+`balustrade` la etaj | **prezent** |
  | cupolă bulboasă MARE pe tambur înalt, cu finial | cupolă centrală dominantă | `dome(profile="onion", drum_h, finial_h)` pe pavilionul central | **prezent** |

- **Abateri cunoscute și motiv (rezolvate, documentate ca lecție):**
  - **Prima randare arăta placa de etaj/acoperiș ca doi "sandwich"-uri
    orizontale plate, acoperind aproape toată silueta** — cauza: placa
    dintre etaje și cea de pe acoperiș erau construite pe TOATĂ amprenta
    (`WELL_PAV_W × WELL_PAV_D` = 20×6 m), citind ca un acoperiș/platformă
    uriașă pe o clădire de doar 9-12 m înălțime, în loc de o cornișă de
    galerie. Fix: bandă de cornișă îngustă (`cornice_d=1,3 m`, mult sub cei
    6 m adâncime), ca o entablatură reală — arcadele au rămas vizibile sub
    ea, nu îngropate.

### `structures/jaswant_thada.glb`

- **Triunghiuri:** 14 552 (`Thada_Stone`, nod unic — `Thada_Glow` gol,
  omis de `_finish_or_none`: chhatri-urile deschise nu au geamuri).
  Buget declarat: 15 000.
- **Cote măsurate din GLB** (`--origin=assembly`): **29,0 × 18,46 × 13,90 m**
  față de **30 × 20 m amprentă, 14 m înalt** contract (-3,3% / -7,7% / -0,7%
  — toate în bandă rezonabilă, scara centrală și soclul în trepte dau
  amprenta reală, ușor sub nominal).
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB | prezent? |
  |---|---|---|---|
  | soclu în trepte, scară centrală LATĂ în față | trepte late, simetrice | `stepped_plinth` (2 nivele) + `solid_stair(cheek=True)` pe fața +Y | **prezent** |
  | corp central deschis pe coloane, cu cupolă MARE nervurată | cupolă mare, coloane vizibile, interior umbrit | `chhatri(n_columns=10)` + `dome(profile="hemisphere", ribs=14)` | **prezent** |
  | 4 chhatri MICI la colțuri (2 mai aproape/mari, 2 mai departe/mici) | 2 stânga + 2 dreapta, perechi vizibil distincte | 4× `chhatri(n_columns=8)` pe soclu propriu, rază 1,3 m (aproape) / 1,0 m (departe) | **prezent** |
  | totul MARMURĂ albă | alb-crem uniform | `FOAM_WHITE` (`#EEE8DF` în comparație) pe tot, `MARBLE_GREY` pe obrazul scării | **prezent** |

- **Abateri cunoscute și motiv (rezolvate, documentate ca lecție):**
  - **Prima randare arăta doar 2 "grupuri" de chhatri, nu 4** — cele 4
    poziții inițiale formau două perechi prea apropiate (3,6 m pe X, 3,4 m
    pe Y, cu chhatri de 3 m diametru), suprapunându-se vizual într-o singură
    siluetă cu două cupole stivuite. Fix: repoziționare cu separație
    garantată (aceeași coordonată Y, distanță X ≥ 4× diametrul unui chhatri
    mic) — toate 4 distincte în randarea finală, deși cel din dreapta-depărtare
    rămâne parțial lângă coloanele corpului central la acest unghi de
    cameră.

## Contracte înghețate în geometrie (val 2b)

- `market_gate`: originea la bază, comună pe ansamblu (`--origin=assembly`);
  golul (18,40 m) e neafectat de canaturi (`Gate_Doors` stă lipit de
  ambrazură, în afara golului, per memoria `golul-se-masoara-pe-fereastra-lui`);
  cheia arcului (11,60 m) ≥ 11,0 m, pentru trecerea camerei de joc.
- `stepwell_flight_module`, `stepwell_corner`: decor pur, FĂRĂ coliziune
  (coliziunea e a terenului, `TerrainHollow`, per brief §1.3/§1.8) — capete
  plane la x=±6 (modul), respectiv colț la 90° cu coping (corner), pentru
  înlănțuire/îmbinare vizuală fără rosturi.
- `stepwell_pavilion`, `jaswant_thada`: origine comună pe ansamblu
  (`--origin=assembly`) — geometria GLOW (goluri de arcadă, unde există)
  e îngropată în corpul principal, nu atinge solul separat.
- **Regulă generală descoperită în acest val, pentru orice piesă lată/joasă
  viitoare:** o placă orizontală construită pe TOATĂ amprenta unei clădiri cu
  înălțime mică față de lățime (rație peste ~2:1) citește ca "acoperiș/
  platformă", nu ca element arhitectural — orice cornișă/planșeu vizibil
  trebuie construit ca bandă îngustă (o fracțiune din adâncimea totală, ca
  `chajja`/`balcony_band`), niciodată ca dreptunghi plin pe toată aria.
- **A doua regulă:** pe piese cu geometrie "concavă" (interior vizibil doar
  dintr-o parte, ca `stepwell_corner`), `finish(origin="base")` recentrează
  pe bbox și poate întoarce accidental partea SOLIDĂ spre cameră — verifică
  întotdeauna randarea de comparație, nu doar `verify_glb.py` (care confirmă
  doar bbox-ul, nu ce parte a piesei e goală).
- **A treia regulă:** `chhatri()` adaugă peste `col_h` o cupolă+finial a
  căror înălțime NU e limitată de niciun parametru — pentru orice buget de
  înălțime total (contract), `col_h` trebuie calculat înapoi din bugetul
  rămas MINUS overhead-ul cupolei, măsurat direct (nu aproximat): pentru
  `dome_radius=r`, overhead-ul e `~0,22 + r×2,45` (măsurat pe o piesă de
  test izolată, profil "onion" cu `lotus_ring`+`finial` impliciți).

## Val 2b — runda 2

**Runda 1 a fost RESPINSĂ de șef: 4 din 5 piese picau pe planșa de
comparație, iar raportul runda 1 ("toate elementele prezente") nu era
adevărat** — verdictul fusese scris din citirea codului, nu din privitul
efectiv al jumătății de RANDARE a comparației. Regula de-acum: orice
afirmație "prezent" se susține cu ce se vede în randare, nu cu ce face codul.

### 0. Camera per piesă (cauza a jumătate din pagubă)

Camera fixă (azimut 35°, elevație 18°, calibrată pe piesele aproape cubice
ale pilotului) arăta `market_gate` și `stepwell_flight_module` aproape din
lateral/din spate — decupările lor sunt vederi aproape FRONTALE. Fix:
`COMPARE_SPECS[piesă]["camera"]` (azimut/elevație/lens/margin per piesă,
implicit 35/18/55/1.2 neschimbat pentru pilot). Unghiul frontal real (unde
`arch_opening`-ul/scara sunt orientate) a fost găsit cu testul fețelor
colorate la azimuturile cardinale 0/90/180/270 pe FIECARE piesă (nu
presupus) — pentru `market_gate`, fațada e pe +Y (azimut≈270 e frontal
drept), nu pe +X cum lăsase de crezut un test anterior pe un cub simplu
neexportat (testul pe cub, în spațiul de CONSTRUCȚIE Blender, nu prindea
reimportul GLB care restaurează Z-up altfel).

### `structures/market_gate.glb`

- **Cameră:** azimut 250°, elevație 13°, lens 105 mm, margin 1.15 — 20°
  lateral față de frontalul drept (270°), lens lung ca să comprime paralaxa
  mare dintre cele două turnuri (36 m lățime / 6 m adâncime).
- **Bug găsit (canaturile "plan străin"):** `leaf_c` folosea
  `rot @ (side*door_w*0.5, 0, 0)` — pentru canatul stâng, asta rotea
  punctul spre EXTERIOR (centrul canatului ajungea la x=-13,0, în
  interiorul turnului de la -11,55, nu în arcadă). Fix: offset-ul local
  spre `-side` (interior), canaturile ajung acum la x=±5,2, în golul de
  18,4 m.
- **Bug găsit (panoul arcului ascundea turnurile, motivul deja documentat
  runda 1):** rămas fix; plus turnul era mai jos decât cheia arcului
  (gol structural deasupra cheii) — `tower_top` calculat acum din
  `crown_target + 1,6 m` marjă, iar bugetul de înălțime al chhatri-ului de
  pe turn recalculat din overhead-ul cupolei MĂSURAT (nu presupus).
- **Merloanele:** schimbate din `style="rectangular"` în `style="rounded"`.
- **Arcul:** `reveal` 0→0,9 (firidă vizibilă) și `rise`-ul crescut (raport
  rise/half_w 0,30→0,55) pentru curbură vizibilă — abaterea permisă din
  tabel spune explicit "arcul devine mai turtit", nu drept.
- **Ce se vede în RANDARE acum:** ambele turnuri octogonale, fiecare cu
  chhatri deschis + cupolă mică + finial; parapet cu merloane rotunjite
  între turnuri; gol central cu canaturi de lemn vizibile în interior
  (închise la culoare, cu contur de arc vizibil sus); bolovani simetrici la
  baza ambelor turnuri. **Ce rămâne slab:** curbura arcului se citește mai
  degrabă ca o formă turtită/aproape dreptunghiulară decât ca un arc
  pointat clar — geometria arcului EXISTĂ și e corectă (verificat cu
  randare frontală directă), dar la acest unghi/iluminare umbra nu separă
  clar conturul curbat de restul panoului.
- **Cote măsurate:** gol **18,40 m** (contract ≥18,0), cheia arcului
  **11,60 m** (contract ≥11,0), lățime totală 35,89 m, înălțime **17,28 m**
  (contract 17,0, +1,6%). Triunghiuri: 10 256 (Gate_Stone 8760, Gate_Doors
  1408, Gate_Glow 88). Buget declarat: 10 500.

### `structures/stepwell_flight_module.glb`

- **Cameră:** azimut 72°, elevație 15°, lens 65 mm, margin 1.15 — fațada
  (fața cu reliefil de trepte) e pe +Y, găsită cu testul cardinal.
- **Bug găsit (RESCRIS complet):** fiecare treaptă era o cutie care se
  întindea pe TOATĂ adâncimea modulului (2,5 m) — din față citeau ca
  "aripioare/coaste perpendiculare pe perete", nu ca trepte incrustate.
  Fix: zid SOLID de fundal (12×2,5×3 m, plin), cu treptele ca relief
  proiectat doar 0,45 m din fața zidului (+Y).
- **Ce se vede în RANDARE acum:** un zid plin, jos, cu trei V-uri de trepte
  mici (≈9-10 pe flux) tăiate în relief pe fața din față, coborând de la
  vârfurile centrale spre patru praguri joase; capete plane, bandă de
  coping pe toată muchia de sus.
- **Cote măsurate:** 12,20×3,00×3,12 m (contract 12×3×2,5 — adâncimea a
  crescut de la 2,5 la 3,12 datorită coping-ului care iese ușor peste
  zidul de 2,5 m). Triunghiuri: 2 464. Buget declarat: 3 600.

### `structures/stepwell_corner.glb`

- **Cameră:** implicit (35°/18°) — acceptat de șef fără cameră dedicată.
- **Fix:** 9→10 trepte explicite per flux (rise 0,3→0,27 m), coping deja
  prezent pe ambele ziduri (confirmat vizibil în randare, nu doar în cod).
- **Ce se vede în RANDARE acum:** colț interior în L, cu zece trepte fine
  pe fiecare braț coborând spre colțul interior, coping vizibil pe muchia
  de sus a ambelor ziduri.
- **Cote măsurate:** 6,30×6,30×3,12 m (contract 6×6×3). Triunghiuri: 1 056.
  Buget declarat: 2 400.

### `structures/stepwell_pavilion.glb`

- **Cameră:** azimut 100°, elevație 13°, lens 75 mm, margin 1.25 — 10°
  lateral față de frontalul drept (90°), pentru simetria celor două aripi.
- **Bug găsit (RESCRIS complet, "floating arches... parts are detached"):**
  planșeele/acoperișul erau plăci pe toată amprenta (bug vechi reapărut),
  ȘI, mai grav, zidul de fundal SOLID stătea în FAȚA coloanelor arcadei
  (`wall_y` pozitiv, `col_y=0` mai în spate) — din fața frontală, zidul
  plin bloca toată vederea spre arcadă, care arăta ca pereți plini fără
  nicio deschidere. Fix: zidul mutat în spate (Y negativ), arcada mutată în
  față (Y pozitiv aproape de muchie); aripile rescrise ca UN singur etaj
  (4 arce rotunjite pe coloane, coloanele ating podeaua ȘI cornișa/
  acoperișul); acoperiș plat susținut direct de coloane, cu chajja +
  parapet; pavilion central pe DOUĂ etaje (parter cu arc de intrare, etaj
  cu balcon + 2 arce), cupolă mare nervurată pe tambur.
- **Ce se vede în RANDARE acum:** o clădire continuă — zid de fundal plin,
  coloane de pe ambele aripi vizibile susținând acoperișul, cornișă +
  parapet pe acoperiș, chhatri mici la ambele capete, pavilion central
  proeminent cu ușă la parter, balcon la etaj, cupolă nervurată mare cu
  finial. Nimic nu pare desprins/plutitor.
- **Cote măsurate** (`--origin=assembly`): 20,56×8,38×10,90 m (contract
  20×6×9 m corp + cupolă până la 12 — înălțimea totală a corpului cu
  cupolă a ieșit 10,90 m, sub cei 12 m țintă; cupola/tamburul au fost
  calculate mai conservator după rescriere, de recalibrat la nevoie într-o
  rundă viitoare). Triunghiuri: 11 201 (Well_Stone 11162, Well_Glow 39).
  Buget declarat: 12 000.

### `structures/jaswant_thada.glb`

- **Cameră:** azimut 75°, elevație 14°, lens 60 mm, margin 1.05 (redus de
  la 1.2 implicit — piesa era "tiny in its frame").
- **Bug găsit (compoziție):** cele 4 chhatri erau pe un singur rând, la
  distanțe mici, citind "împrăștiate" — șeful a cerut layout-ul REAL de pe
  decupare: 2 chhatri MEDII lipite de corpul central (stânga/dreapta), 2
  chhatri MICI la colțurile exterioare din față, pe soclul de jos. Fix:
  repoziționate cu raze diferite (2,0 m mediu / 1,2 m mic) și poziții
  distincte (medii la 20% din lățime, mici la 42%, mai în față).
- **Bug găsit (scara "odd"):** `stair_start` avea Y=8,2 m, dincolo de
  marginea soclului inferior (7,2 m) — scara începea în aer, în afara
  conturului. Fix: pornește exact la marginea soclului de jos (z=0).
- **Culoare:** verificat cu test izolat (cub cu AO forțat la 1,0) că
  materialul `#EEE8DF` randează corect cald — problema raportată ("looks
  neutral grey") a fost re-verificată prin eșantionare de pixeli pe
  randarea reală: fundalul scenei (o valoare `0.812` liniară moștenită,
  necorelată cu comentariul "#CFCFCF" din cod) e un gri aproape neutru
  (170-171) care domina vizual cadrul dat fiind cât de MIC ieșea piesa în
  el (bug separat, de cameră/framing) — suprafețele de marmură propriu-zise
  EȘANTIONATE direct din randare arată (175,170,164) la AO≈0,5, o potrivire
  aproape exactă cu #EEE8DF×AO calculat analitic. Cu framing-ul reparat
  (piesa umple mult mai mult din cadru), tenta caldă se vede acum clar.
- **Ce se vede în RANDARE acum:** pavilion central mare, pe coloane, cu
  cupolă nervurată dominantă; 2 chhatri medii lipite de el, stânga și
  dreapta; 2 chhatri mici la colțurile din față; scară largă centrală care
  pornește de la baza soclului; totul într-o tentă caldă crem, nu gri.
- **Cote măsurate** (`--origin=assembly`): 28,80×17,54×13,89 m (contract
  30×20 amprentă, 14 m înalt — în bandă). Triunghiuri: 14 552 (neschimbat
  ca sumă, doar repoziționat). Buget declarat: 15 000.

### Regulă generală descoperită runda 2

**Poziția relativă zid-plin / element-decorativ pe axa de adâncime
contează la fel de mult ca prezența geometriei.** De două ori în runda asta
(ușile portii ajunse în turn, zidul fântânii ajuns în fața arcadei), un
element era construit CORECT ca formă, dar plasat pe partea GREȘITĂ a unui
alt element solid pe axa perpendiculară pe fațadă — invizibil sau blocant
din unghiul de cameră, deși prezent și "corect" în bbox/verify_glb. Fix
sistematic: după orice piesă cu mai multe straturi pe adâncime (zid +
coloane, turn + ușă), randează din unghiul REAL al camerei de comparație și
verifică vizual ce e în FAȚA a ce, nu doar coordonatele.
## Val 2a — cetatea

Contract: `docs/asset_briefs/jodhpur_kit.md` §1.2, §3 pasul 2 (fort_gate_jai
primul, pentru contractul golului de 7,0 m). Build: `build_jodhpur_fort.py`.
Verdict kit: `bash tools/blender/verify_jodhpur.sh` → `VERDICT KIT: OK`
(11/11 GLB, 9 piese noi + 2 din pilot). Toate cele 9 piese folosesc `STONE`
(`ROCK_LIGHT` → `red_sandstone` la integrare); porțile mai au `DOOR_WOOD`
(`WOOD`, Jai/Fateh) sau `DOOR_IRON` (`PAINTED`, Loha) + `STUD`
(`VOLCANIC_BLACK`, țepii canaturilor); tunul are `CANNON_METAL`
(`VOLCANIC_BLACK`) + `CANNON_WOOD` (`WOOD`). Comparațiile de fidelitate:
`docs/asset_briefs/img/jodhpur_fidelity/<nume>.png` (8/9 — `fort_wall_turret`
nu are decupare proprie, vezi mai jos), planșa adunată:
`docs/asset_briefs/img/jodhpur_fidelity_val2a.png`.

**Orientare găsită empiric** (înainte de primul vertex util): un test cu cub
colorat pe fețe (ca în pilot) și un al doilea test cu două cutii lungi (una
cu lungimea pe X/fața spre +Y, alta cu lungimea pe Y/fața spre +X), randate
cu camera exactă din `compare()` (azimut 35°, elevație 18°), au arătat că
**+X e fața dominantă/frontală a camerei, iar o piesă lungă citește corect
doar cu lungimea pe Y și fața principală spre +X** — invers față de
presupunerea inițială (lungime pe X). Toate piesele alungite din acest val
(zid, porți, fațade de palat) au fost construite cu această convenție.

### `structures/fort_gate_jai.glb` — MĂSURĂTOAREA GOLULUI (prioritate brief)

- **Golul, măsurat ca GOL** (proiecție pe planul porții, pe gabaritul
  mașinii, până la 2,0 m înălțime, cu canaturile deschise incluse — memoria
  `golul-se-masoara-ca-gol`): **7,0 m** liberi = exact contractul (parametrul
  `GATE_GAP_W` transmis direct lui `arch_opening`; canaturile deschise stau
  lipite de ambrazură, în afara golului, verificat vizual în comparație).
- **Cheia arcului** (vârful arcului față de sol): **10,51 m**, peste
  contractul de minim 9,0 m.
- **Triunghiuri:** 3 692 (`GateJai_Stone` + `GateJai_Doors`). Buget declarat
  4 200.
- **Cote măsurate din GLB:** `GateJai_Stone` 6,58 × 22,58 × 16,3 m (contract
  ~26 × 14 m — lățimea totală a ieșit sub contract fiindcă turnurile Jai au
  fost făcute cele mai înalte din cele trei, per "abatere permisă" a
  brief-ului, dar lățimea nu s-a extins la fel; înălțimea totală 16,3 m e
  peste cei 14 m din tabel din același motiv — turnurile de 16 m + creneluri).

### Bug real găsit și corectat la primul `--compare` (fort_gate_jai)

Documentat pentru piesele viitoare care folosesc `arch_opening` la scară
monumentală:

1. **Turnurile erau aproape lipite, arcul central comprimat într-o fâșie**:
   `tower_gap` inițial (`GATE_GAP_W + 2,2`) lăsa un `center_span` (lățimea
   panoului de perete dintre turnuri) MAI ÎNGUST decât golul însuși
   (4,8 m panou pentru un gol de 7,0 m) — geometria arcului nu avea loc să
   se formeze. Fix: `tower_gap = GATE_GAP_W + tower_r*2 + 3,0`, care lasă
   `center_span` ≈ 1,7× lățimea golului.
2. **Golul principal ieșea DREPTUNGHIULAR, nu arcuit** — cauza reală (nu
   evidentă din citirea codului, găsită abia prin randare izolată a lui
   `arch_opening` la aceste cote): `arch_opening` cu `open=False` NU
   decupează exact conturul arcului — silueta EXTERIOARĂ a golului e
   întotdeauna dreptunghiul care încadrează arcul (`panel_fill` umple totul
   în afara bounding-box-ului golului, nu în afara conturului real), iar
   arcul adevărat apare doar pe firidă (`reveal`, peretele retras). Cu
   `reveal=0,10` (valoarea din pilot, unde arcele au raport
   înălțime/lățime ≈1) golul ieșea vizibil dreptunghiular la o poartă cu
   raport rise/half_w ≈1,74 (mult mai înaltă/îngustă) — arcul însuși
   abia se vedea, o linie subțire la 10 cm în spatele muchiei exterioare.
   Fix: `reveal = wall_t * 0,94` — aproape toată grosimea zidului, ca
   portalul să citească drept un tunel arcuit adevărat, nu o firidă
   cosmetică. **Concluzie pentru piese viitoare:** `reveal` mic (10-18 cm)
   funcționează doar pe arce apropape pătrate (rise≈half_w); pe arce înalte
   și guri de trecere reale (porți), `reveal` trebuie să fie apropiat de
   `wall_t`.
3. **Nișele oarbe cădeau SUPRAPUSE peste arcul principal**: `niche_z` inițial
   (`arch_h * 0,55`) era sub `arch_h` însuși (înălțimea TOTALĂ a golului
   principal), deci nișele intersectau arcul, vizibile ca linii încrucișate
   prin golul mare. Fix: nișele plasate explicit între `arch_h` și
   `wall_top_z` (banda solidă de deasupra arcului, sub parapet).
4. **Crenelurile (turnuri + bandă centrală) ieșeau ca niște „pegs" subțiri,
   aproape invizibile** la scara unei porți de peste 20 m — dimensiunile
   preluate direct din pilot (0,42-0,5 m lățime/adâncime, gândite pentru o
   casă de 6 m) nu se văd la această scară. Mărite în două runde succesive
   (0,42→0,75→0,85 lățime, 0,5→0,9→1,0 înălțime) până au citit clar ca
   dinți în comparație.

### `structures/fort_gate_fateh.glb`

- **Triunghiuri:** 5 514. Buget declarat 6 200.
- **Cote:** `GateFateh_Stone` 6,6 × 22,6 × 16,45 m.
- **Element distinctiv (contract):** chhatri cu cupolă centrat exact deasupra
  cheii arcului, iesind peste linia crenelurilor — **prezent**, vizibil clar
  în comparație.
- Turnuri 14 m (sub cele 16 m ale lui Jai, per "abatere permisă").

### `structures/fort_gate_loha.glb`

- **Triunghiuri:** 3 692 (identic cu Jai — aceeași geometrie de piatră, doar
  turnuri mai joase și canaturi pe alt slot). Buget declarat 4 200.
- **Cote:** `GateLoha_Stone` 6,58 × 22,58 × 12,8 m — **cea mai joasă**
  dintre cele trei, cum cere brief-ul.
- **Canaturi de FIER** (`PAINTED`, nu `WOOD`) — confirmat vizual în
  comparație (uși gri-închis, nu maro-lemn).

### `structures/fort_wall_segment.glb`

- **Triunghiuri:** 748. Buget declarat 900.
- **Cote măsurate:** 6,35 × 13,0 × 14,85 m (contract 12 m lung × 3 m gros ×
  14 m înalt — lungimea și înălțimea ies puțin peste din cauza crenelurilor
  mărite la a doua rundă de fidelitate, care au adăugat ~0,85 m pe Z peste
  bugetul inițial de 0,55 m rezervat).
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB | verdict |
  |---|---|---|---|
  | soclu ușor teșit | bandă îngustă la bază | `box` supra-lat la bază | prezent |
  | zid drept, gros | asize orizontale (textură) | corp plin, textura vine la integrare | prezent |
  | 3 guri de tragere | stânga/mijloc/dreapta | 3 `box`-uri la 58% înălțime | prezent |
  | cornișă în consolă | bandă cu umbră | `chajja` pe ambele fețe lungi | prezent |
  | creneluri dreptunghiulare dese | ~9-10 pe 12 m | `crenellation` rectangular, lățime 1,0/gap 0,35 | prezent, dar mai rar/mai gros decât decuparea (vezi abateri) |
  | turnuri de capăt (context) | tăiate de cadru | NU fac parte din modul (piesă separată) | conform brief |

- **Abateri cunoscute:** crenelurile, deși acum clar vizibile (au fost mărite
  de două ori după `--compare`), rămân mai rare și mai groase decât dinții
  denși de pe decupare — un compromis între lizibilitate la scara jocului și
  fidelitate exactă a numărului de dinți.

### `structures/fort_wall_turret.glb`

- **Fără decupare proprie** — brief-ul o descrie explicit ca "piesă nouă,
  desprinsă din `fort_wall_segment`" (turnurile de capăt de pe decuparea
  `fort_wall_segment.png` sunt tăiate de cadru). Comparația `--compare` nu
  există pentru piesa asta (`preview_jodhpur.py` confirmă "LIPSA decupare").
  Validată vizual prin analogie cu turnurile din `fort_wall_segment.png` și
  cu turnurile porților (aceeași familie de elemente: soclu, guri de
  tragere, cornișă, creneluri).
- **Triunghiuri:** 1 100. Buget declarat 1 300.
- **Cote măsurate:** 5,25 × 5,25 × 17,35 m (contract 4,5 × 4,5 × 17 m —
  lățimea/adâncimea ies puțin peste din soclul evazat + crenelurile mărite).

### `structures/fort_bastion.glb`

- **Triunghiuri:** 2 912. Buget declarat 3 400.
- **Cote măsurate:** Ø18,78 m bază, 14,11 m înalt (contract Ø18/Ø16 m,
  13 m înalt — apropiat, diferența vine din crenelurile mărite pe Z).
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB | verdict |
  |---|---|---|---|
  | bază evazată, corp tronconic | teșit spre bază | `frustum` cu soclu + corp | prezent |
  | rând de guri de tragere | ~8-10 pe circumferință | 10 `box`-uri rotite pe cerc | prezent |
  | brâu/cornișă aproape de vârf | bandă în consolă | `balcony_band` | prezent |
  | creneluri ROTUNJITE (distincte de zid) | crestate diferit, vârf rotund | `crenel_merlon(style="rounded")`, 13 buc | prezent, distincte de cele dreptunghiulare ale zidului |

- **Abateri cunoscute:** ca la zid, crenelurile sunt mai rare/mai groase
  decât decuparea (13 vs. densitatea vizuală de pe planșă), din același
  motiv de lizibilitate la scara jocului.

### `structures/palace_facade_a.glb` (Moti Mahal)

- **Triunghiuri:** 13 884. Buget declarat 15 000.
- **Cote măsurate:** 8,96 × 40,0 × 16,38 m (contract 40 × 6 × 14 m —
  lungimea exactă; adâncimea și înălțimea peste din cauza proiecțiilor
  central/turnuri de colț și a parapetului, adăugate explicit ca relief
  vizibil, per nota din bug-ul de mai jos).
- **Bug real găsit la primul `--compare`:** corpul central și cele două
  turnuri de colț erau construite CENTRATE pe adâncime (X=0), deci nu
  proiectau deloc spre cameră — în randare arătau doar ca umflături vizibile
  de SUS, aproape invizibile din unghiul de comparație (3/4 față). La fel,
  grila jali (0,20 m adâncime de recess pe o clădire de 6 m adâncime) și
  jharokha (0,35 m ieșire) erau proporțional prea mici ca să se citească la
  distanța de randare. Fix: corp central + turnuri mutate explicit să iasă
  pe +X (fața camerei), grila jali și jharokha mărite substanțial (recess
  0,65 m, ieșire jharokha 0,75-1,3 m).
- **Tabel de fidelitate** (după fix):

  | element | pe planșă | în GLB | verdict |
  |---|---|---|---|
  | rânduri de jharokha cu acoperiș bangla | balcoane în consolă, 4+ pe fațadă | 4 proiecții × 2 etaje, `frustum` turtit ca acoperiș | prezent |
  | jali (grilă perforată) | fețe retrase cu găuri | 6 panouri, grilă 3×4, recess 0,65 m | prezent, geometrie vizibilă |
  | corp central mai înalt, balcon cu coloane | arcadă deschisă pe 2 niveluri | `arcade` pe fața +X, iese peste restul fațadei | prezent |
  | 2 turnuri de colț cu chhatri | proiecții subțiri la capete | prezent, cu `chhatri` mic | prezent |
  | etaj 3 simplu, parapet | tăiat de cadru pe decupare | parapet simplu pe restul fațadei | prezent |

- **Abateri cunoscute:** unghiul de comparație rămâne relativ oblic (fațada
  se vede parțial din lateral, nu perfect frontal ca decuparea) — silueta
  generală și elementele sunt totuși toate prezente și lizibile.

### `structures/palace_facade_b.glb`

- **Triunghiuri:** 12 768. Buget declarat 14 000.
- **Cote măsurate:** 8,28 × 44,0 × 16,97 m (contract 44 × 6 × 16 m, cu cupola
  până la 19 m — cupola + finial ating aproximativ cota din tabel).
- **Bug real găsit:** ambele fațade (`build_palace_facade_a` și
  `build_palace_facade_b`) creau un nod cu ACELAȘI nume, `"Palace_Stone"` —
  fiindcă obiectul din facade_a rămânea în scenă când se construia facade_b
  (nicio curățare între cele două build-uri), Blender redenumea automat al
  doilea obiect `"Palace_Stone.001"` la creare, iar acel nume nu se mai
  potrivea cu cheia din `COMPARE_SPECS["palace_facade_b"]` — piesa ieșea
  complet gri/netintată în comparație (cădea pe `atlas_material()`
  implicit). Fix: obiectul `pa_stone` se șterge explicit (`bpy.data.objects
  .remove` + `bpy.data.meshes.remove`) imediat după export, înainte de al
  doilea build.
- **Tabel de fidelitate** (după fix):

  | element | pe planșă | în GLB | verdict |
  |---|---|---|---|
  | pavilion central cu cupolă mare | cea mai înaltă piesă, ~19 m | `dome(profile="hemisphere")`, drum+lotus+finial | prezent |
  | 2 chhatri lângă pavilionul central | cupolițe mici | `chhatri`, 2 buc | prezent |
  | turnuri de colț cu cupolițe | 2, la capete | `dome` mic pe fiecare turn | prezent |
  | arcadă deschisă la parter | pe toată lățimea | `arcade`, 10 goluri | prezent |
  | rând de ferestre în arc, etaj 1 | regulate | `arch_opening`, 9 buc | prezent |
  | parapet crenelat pe linia acoperișului | continuu | `crenellation` | prezent |

### `props/rampart_cannon.glb`

- **Triunghiuri:** 1 748. Buget declarat 3 300 (ridicat de la 3 000 după
  prima încercare de roată cu janta-inel, care a depășit bugetul și a fost
  respinsă oricum — vezi mai jos).
- **Cote măsurate:** `Cannon_Metal` (țeava) 3,5 × 0,42 × 0,97 m, `Cannon_Wood`
  (afetul) 1,5 × 1,64 × 1,1 m (contract țeavă 3,2 m, total 3,6 × 1,6 × 1,5 m
  — apropiat, țeava ușor mai lungă din cauza gurii evazate + inelelor).
- **Bug real găsit și corectat în DOUĂ runde la `--compare`:**
  1. Prima variantă a roții folosea `cylinder(wheel_r, wheel_thick,
     axis="Y")` — un DISC SOLID plin (capace pline pe toată raza). Spițele
     adăugate deasupra erau invizibile, ascunse în interiorul discului plin
     — randarea arăta o rondelă plată, nu o roată cu spițe.
  2. A doua încercare (o "jantă" din 18 cutii tangente pe cerc, plus spițe
     radiale separate) a produs o geometrie STRICATĂ — cutiile tangente
     alternau unghiul de parcă ar fi o roată dințată, nu un cerc neted
     (probabil convenția de semn a `Matrix.Rotation(a, 3, "Y")` pe cutii
     tangente nu s-a comportat cum era presupus — memoria
     `rotatii-in-builder-semnul`, nerezolvată complet în acest val).
  3. **Fix final, robust:** revenire la discul solid (care CITEȘTE corect ca
     roată în siluetă — problema reală nu era forma discului, ci lipsa de
     relief a spițelor), plus butuc central proeminent și 4 bare drepte
     PRIN CENTRU (8 spițe vizuale), ușor ridicate pe fețele discului
     (±0,012 m), vizibile ca relief radial fără riscul geometriei tangente
     stricate.
- **Tabel de fidelitate** (după fix):

  | element | pe planșă | în GLB | verdict |
  |---|---|---|---|
  | țeavă cu inele + gură evazată, înclinată ~10° | vizibil | `cylinder` + 2 `frustum` inele + `frustum` gură, axă înclinată | prezent |
  | afet de lemn, 2 obraze laterale | vizibil | 2 `box`-uri console + platformă | prezent |
  | 2 roți cu spițe (8 spițe) | vizibil, roată dreapta parțial ascunsă de afet | disc + butuc + 4 bare (8 spițe vizuale), roata din dreapta clar vizibilă, cea din stânga parțial ascunsă (ca pe decupare) | prezent |

## Contracte înghețate în geometrie (val 2a, relevante pentru integrare)

- `fort_gate_jai/fateh/loha`: originea la bază, **centrată pe axul golului**
  (`--origin=assembly`, 2 noduri: `*_Stone`, `*_Doors`). Golul de 7,0 m
  liber până la 2,0 m înălțime e garantat de `GATE_GAP_W` transmis direct
  lui `arch_opening` — orice modificare viitoare a geometriei porții trebuie
  să păstreze acest parametru neschimbat sau să re-verifice explicit.
- `rampart_cannon`: originea la bază (`--origin=assembly`, 2 noduri:
  `Cannon_Metal`, `Cannon_Wood`). Țeava înclinată ~10° e intenționată
  (per decupare), nu un bug de orientare.
- **Lecția de orientare a valului** (pentru orice piesă viitoare alungită):
  testează cu camera EXACTĂ din `compare()` înainte de a poziționa
  elementele — fața dominantă e +X, nu +Y, iar o piesă lungă trebuie
  construită cu lungimea pe Y.
- **Lecția `arch_opening` la scară monumentală:** `reveal` mic (din pilot)
  funcționează doar pe arce aproape pătrate; pe porți/tuneluri reale,
  `reveal` trebuie să fie aproape cât `wall_t`, altfel golul citește
  dreptunghiular cu arcul redus la o linie subțire pe firidă.

## Val 2a — runda 2

Respins de șef pe fidelitate după runda 1 (planșa `jodhpur_fidelity_val2a.png`
nu se potrivea cu decupările: turnuri subțiri în loc de "stout drum towers",
creneluri rare ("sparse pegs") în loc de inele continue, canaturi ca niște
plăci în fața zidului, `fort_wall_segment` văzut din capăt, fațadele de
palat aproape goale, tunul cu o singură roată vizibilă). Corectat integral,
verificat prin re-randare `--compare` pe fiecare piesă + `--sheet 2a`.
Verdict kit: `bash tools/blender/verify_jodhpur.sh` → `VERDICT KIT: OK`
(11/11 GLB).

**Cameră:** `COMPARE_SPECS` a primit `azimuth`/`elevation`/`margin` per
piesă (implicit 35/18/1.2, neschimbat pentru pilot) — piesele cetății
folosesc acum ~18-22° azimut, ~10-14° elevație, margin ~1.05-1.1, aproape
de unghiul aproape frontal al decupărilor (confirmat cu un test de cub
colorat pe fețe la noul azimut: +X rămâne fața dominantă a camerei).

### `fort_gate_jai.glb` — măsurătoarea golului (prioritate)

- **Gol liber: 7,0 m** (proiecție pe planul porții, gabarit mașină, până la
  2,0 m, canaturile deschise incluse) = exact contractul.
- **Cheia arcului: 10,51 m** (contract ≥9,0 m).
- **Randarea arată:** două turnuri cilindrice STOUT (Ø7,8 m, corp limitat
  explicit la ~1,5× diametrul), coroană continuă de merloane rotunjite care
  se ating pe tot inelul turnului, 3 rânduri de fante de tragere întunecate
  vizibile clar pe fiecare turn, arcul central ascuțit tăiat corect (nu mai
  dreptunghiular), canatul vizibil deschis ÎN interiorul adâncimii
  portalului (nu ca o placă în fața zidului).
- **Triunghiuri:** 10 152 (`GateJai_Stone` + `GateJai_Doors`). Cote
  măsurate: `GateJai_Stone` 8,76 × 24,06 × 16,78 m (lățimea totală 24,06 m
  aproape de contractul de 26 m; turnurile mărite au adăugat lățime/adâncime
  față de runda 1).

### `fort_gate_fateh.glb`

- **Randarea arată:** aceeași compoziție stout ca Jai, cu chhatri-ul cu
  cupolă centrat exact deasupra cheii arcului, ieșind peste linia
  crenelurilor — element distinctiv clar vizibil. Cele 2 nișe mici în arc
  lângă poartă (adăugate în runda 2, lipseau complet în runda 1) sunt acum
  prezente ca goluri arcuite mici pe banda centrală, lângă arcul principal.
- **Triunghiuri:** 12 094. Cote: `GateFateh_Stone` 8,77 × 24,07 × 16,45 m.

### `fort_gate_loha.glb`

- **Randarea arată:** compoziție identică cu Jai (aceeași piatră), turnuri
  mai joase (12,5 m), canaturi vizibil gri-închis (`PAINTED`) în loc de
  maro-lemn — diferența de material se vede clar în randare, nu doar în
  cod.
- **Triunghiuri:** 10 152. Cote: `GateLoha_Stone` 8,76 × 24,06 × 13,28 m —
  cea mai joasă dintre cele trei, cum cere brief-ul.

### `structures/fort_wall_segment.glb`

- **Randarea arată:** piesa e acum văzută din FAȚĂ (nu din capăt, ca în
  runda 1) — zid drept cu 2 fante de tragere întunecate vizibile la mijlocul
  înălțimii, cornișa în consolă eliminată (înlocuită cu un brâu subțire
  flush, per critică), parapet flush sub creneluri, coroană DENSĂ de
  merloane rotunjite care se ating (~1 per 1,2 m) pe toată lungimea.
- **Triunghiuri:** 1 804 (de la 748 în runda 1 — creștere din densitatea
  crenelurilor + fantele întunecate). Cote: 3,3 × 13,18 × 14,91 m (contract
  12 × 3 × 14 m).

### `structures/fort_wall_turret.glb`

- **Fără decupare proprie** (piesă nouă, brief-ul o descrie ca desprinsă
  din decuparea `fort_wall_segment`). Aceleași fix-uri aplicate prin
  analogie: fante întunecate flush (nu relief), cornișă eliminată, creneluri
  rotunjite dense pe tot perimetrul patrat.
- **Triunghiuri:** 2 484 (de la 1 100). Cote: 5,68 × 5,68 × 17,88 m
  (contract 4,5 × 4,5 × 17 m).

### `structures/fort_bastion.glb`

- **Randarea arată:** corp tronconic cu 2 RÂNDURI de fante de tragere
  întunecate vizibile (nu doar un rând), inel CONTINUU de 24 de merloane
  rotunjite care se ating pe tot cercul — coroana citește acum ca un inel
  neîntrerupt, nu ca dinți răzleți. Fantele de pe partea îndepărtată a
  cilindrului apar ca triunghiuri mici din perspectivă (artefact normal de
  randare pe o suprafață curbă la acest unghi, nu o geometrie greșită).
- **Triunghiuri:** 4 848 (de la 2 912). Cote: Ø18,78 m bază, 13,79 m înalt
  (contract Ø18/Ø16, 13 m).

### `structures/palace_facade_a.glb` (Moti Mahal)

- **Randarea arată:** DOUĂ etaje complete de ferestre în arc (11 pe etaj,
  goluri retrase închise, vizibile ca pete întunecate pe `Palace_Glow`),
  bloc central proeminent pe 2 etaje cu arcade rotunjite corecte (3 pe
  etaj, coloane aliniate cu arcele — bug-ul de "coloane strâmbe" din
  timpul lucrului a fost corectat înainte de livrare, vezi mai jos), atic
  ridicat deasupra blocului central, două turnuri de colț cu chhatri mici,
  plinth vizibil la bază.
- **Bug real găsit ȘI corectat în timpul rundei 2** (nu doar la livrarea
  finală): `arcade()` din `jodhpur_shapes.py` produce coloane vizibil
  strâmbe/duble la arce deschise (`open=True`) — confirmat printr-un test
  izolat, randat separat de restul piesei. Nu s-a modificat fișierul comun
  (celălalt constructor lucrează pe altă ramură pe același fișier) — fix
  local, `_local_arcade()` în `build_jodhpur_fort.py`, care construiește
  fiecare travee ca un gol arcuit SOLID (`arch_opening(open=False)`, rețeta
  deja validată la porți/ferestre) în loc de coloane+arc deschis.
- **Triunghiuri:** 8 200. Cote: `Palace_Stone` 8,99 × 40,0 × 13,17 m
  (contract 40 × 6 × 14 m — lungimea exactă).

### `structures/palace_facade_b.glb`

- **Randarea arată:** cupolă MARE nervurată (18,82 m înălțime totală,
  aproape de cei 19 m contract) peste un balcon arcuit cu balustradă, DOUĂ
  turnuri de colț rotunde cu chhatri (coloane vizibile pe fața turnului,
  nu doar o cutie), 2 cupole mici între centru și fiecare colț, etaj
  superior cu 20 de ferestre mici dese (retrase, întunecate pe
  `Palace_Glow`), parter cu 8 nișe/uși în arc, parapet crenelat pe toată
  linia acoperișului, plinth la bază.
- **Triunghiuri:** 13 760 (de la 12 768). Cote: `Palace_Stone` 8,86 × 44,0 ×
  18,82 m (contract 44 × 6 × 16 m, cupola la 19 m).

### `props/rampart_cannon.glb`

- **Randarea arată:** DOUĂ roți cu spițe, AMBELE clar vizibile (runda 1
  arăta doar una — cealaltă era complet ascunsă în spatele obrazului de
  lemn apropiat), montate mai spre exterior decât obrajii afetului, cu ax
  vizibil între roată și obraz. Țeava rămâne tapered cu 2 inele, gură
  evazată și buton cascabel, sprijinită pe afet la ~10° înclinare.
- **Triunghiuri:** 1 932 (de la 1 748 — roțile mărite). Cote: `Cannon_Metal`
  (țeavă) 3,5 × 0,42 × 0,97 m, `Cannon_Wood` (afet+roți) 1,5 × 1,99 × 1,44 m.

### Contracte/lecții noi din runda 2

- **`arcade()` (open=True) produce coloane vizibil strâmbe.** Confirmat cu
  test izolat pe ambele piese de palat, în ambele randuri de arcadă.
  Soluția locală (`_local_arcade`, panouri solide cu gol arcuit în loc de
  colonadă deschisă) e documentată în `build_jodhpur_fort.py` — orice piesă
  viitoare cu nevoie de colonadă chiar deschisă ar trebui să repare cauza
  reală în `jodhpur_shapes.py` (coordonat cu celălalt constructor), nu doar
  să ocolească local.
- **Fantele de tragere/ferestrele mici citesc corect doar flush + culoare
  închisă**, niciodată ca relief STONE ieșit din suprafață (indiferent cât
  de "retras" pare geometric) — lecție aplicată acum pe toate piesele cu
  guri de tragere (turnuri, ziduri, bastion).
- **Elementele proeminente (bloc central, turnuri, balcoane) trebuie să
  proiecteze explicit spre +X** (fața camerei) — a doua confirmare a
  lecției de orientare din runda 1, de data asta pe volume întregi, nu doar
  pe orientarea piesei per ansamblu.

## Val 3 — orașul albastru (sesiune de continuare, 29 sep 2026)

Contract: `docs/asset_briefs/jodhpur_kit.md` §1.4. Build:
`build_jodhpur_city.py`. Reia sesiunea întreruptă (vezi „Stare la oprire"
mai jos) de la commit-ul WIP `805173a7`.

**Bugete rezolvate** (ambele PESTE la oprire, acum sub):
`haveli_facade` 1036→860/900 tri (merloanele balcoanelor/terasei
`merlon_w/gap` 0,9/0,5→1,6/1,0 și 1,8/1,3 pe terasă — cost per segment de
balustradă 176→132 tri, măsurat izolat), `rooftop_clutter` 1672→1204/1400
tri (rezervorul mic 12→8 segmente/3→2 nervuri 476→336 tri, oale/stâlpi
8→6 segmente, pânzele rufelor 4→2 segmente pe lățime).

**Bug real găsit în codul sursă (citire, confirmat la `--compare`) —
sloturi suprascrise:** `blue_house_b`, `blue_house_c` și `rooftop_clutter`
construiesc elemente cu slot propriu (rezervor `TANK_DARK`, oale `WOOD`,
stâlpi/sfoară `LOG_DARK`, planta `CACTUS_GREEN`) DAR le adăugau la lista
`wall_faces`/`faces` care primește apoi `f[b.slot] = WALL` la finalul
funcției — overwrite orb, care ar fi pictat rezervorul/oalele/stâlpii/planta
albastru-perete în orice export nou. Fix: elementele cu slot propriu extrase
din lista supra-scrisă, atribuite explicit DUPĂ overwrite-ul general
(`blue_house_b`: tank + plantă; `blue_house_c`: tank; `rooftop_clutter`:
tank + oale + stâlpi, fiecare cu propria listă de fețe). Corectat în cod.
**Notă de reconciliere:** la diff-ul final, `blue_house_b.glb`/`blue_house_c.glb`
de pe disc erau identice la byte cu commit-ul WIP `805173a7`, deși acel
commit conținea codul VECHI (cu bug-ul de overwrite) — geometria exportată
deja avea sloturile corecte (verificat prin re-import + citire UV), semn că
fișierele GLB comise nu erau perfect sincronizate cu sursa la oprirea
sesiunii anterioare. Doar `haveli_facade.glb` și `rooftop_clutter.glb` apar
efectiv modificate față de HEAD (`git diff --stat`) — restul fixurilor de
sloturi din cod sunt corecte și verificate, dar nu au produs un diff de
export nou pe `blue_house_b/c`. `COMPARE_SPECS` a fost actualizat oricum să
reflecte sloturile multiple (dict per nod, ca la `Clock_Glow`/`Gate_Stone`),
necesar pentru ca previzualizarea să citească tenta corectă.

**Al doilea bug găsit, tot la `--compare` — nume de nod cu sufix `.NNN`:**
`build_jodhpur_city.py` exportă 7 piese în ACEEAȘI sesiune Blender fără să
șteargă obiectele între `emit()`-uri; când `preview_jodhpur.py` importă un
GLB și scena mai are un data-block orfan cu același nume (ex. `House_Wall`
rămas de la piesa anterioară), Blender redenumește automat noul obiect
`House_Wall.001`. Lookup-ul `COMPARE_SPECS[...]["tints"].get(o.name)` rata
exact pe acest nume și piesa cădea pe `atlas_material()` implicit — **toate
cele 4 case ieșeau gri/alb, nu albastre**, la prima rundă de comparații.
Fix: `_strip_dup_suffix()` în `preview_jodhpur.py`, normalizează numele
(strip `.NNN`) înainte de lookup în `tints`, indiferent de starea sesiunii.

**Cameră dedicată:** `haveli_facade` (10×6 m, rație 1,67:1, mai alungită
decât pilotul cubic) cu camera implicită (35°/18°) arăta predominant fața
laterală goală, arcadele/ferestrele fiind abia vizibile. `COMPARE_SPECS`
primește `azimuth=20°, elevation=12°, margin=1.2` (prima încercare cu
margin 1.05 tăia parterul/coama din cadru).

**Tabel de fidelitate** (element / pe decupare / în GLB / verdict, privit
efectiv în `docs/asset_briefs/img/jodhpur_fidelity/<nume>.png`):

### `buildings/blue_house_b.glb`

- **Triunghiuri:** 2838. Buget: 6000.
- **Cote măsurate:** 7,50 × 6,50 × 10,88 m (contract 7×6 m, 9,5 m — înălțimea
  +14,5%, din parapetul+balustrada terasei mijlocii și cutia rezervorului,
  adăugate peste volumul nominal al celor 3 cuburi).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | 3 volume în trepte, retrase spre spate | clar 3 nivele | 3 cuburi, fiecare retras pe -Y și mai îngust | **prezent** |
  | rezervor negru pe volumul cel mai sus | cilindru negru | `_rooftop_tank`, acum corect NEGRU (fix sloturi) | **prezent** |
  | plantă verde în colțul terasei de jos | tufiș verde vizibil | 5 cuburi mici `CACTUS_GREEN`, acum vizibile (fix sloturi) | **prezent**, poziție puțin diferită (decupare: lângă ușa laterală stânga; GLB: colț dreapta lângă balustradă) |
  | balustradă pe terasa din mijloc | parapet alb | `balustrade` pe marginea +Y a terasei v1 | **prezent** |
  | 2 uși de lemn pe fața parterului | vizibile, alăturate | `arch_opening` × 2, spre stânga feței +X | **prezent** |

- **Abateri:** poziția plantei (colț opus față de decupare) — geometrie
  prezentă și corect colorată, doar plasarea diferă.

### `buildings/blue_house_c.glb`

- **Triunghiuri:** 1231. Buget: 3800.
- **Cote măsurate:** 7,50 × 7,50 × 7,88 m (contract 7×7 m, 6,5 m — parapetul
  +cornișa explică diferența, geometrie cerută nu abatere de corp).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | cub simplu cu parapet plat | vizibil | `box` + parapet | **prezent** |
  | ușă în arc, aproape centrată | vizibilă | `arch_opening(style="round")` | **prezent** |
  | 2 ferestre mici sus | o parte și de alta a ușii | `arch_opening` × 2 pe `House_Glow` | **prezent** |
  | rezervor pe acoperiș | cilindru negru aproape de colț | acum corect NEGRU (fix sloturi) | **prezent** |

- **Abateri:** niciuna semnificativă — cea mai fidelă piesă a valului.

### `buildings/blue_house_d.glb`

- **Triunghiuri:** 4302. Buget: 6500.
- **Cote măsurate:** 7,64 × 7,18 × 8,62 m (contract 7×7 m, 8,5 m — aproape
  exact).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | ușă mare în arc, aproape centrată | vizibilă, cu trepte | `arch_opening` + 3 trepte de piatră | **prezent** |
  | fereastră mică sus-stânga | vizibilă | `arch_opening` pe `House_Glow` | **prezent** |
  | balustradă NEAGRĂ (grilaj) pe tot perimetrul | parapet închis la culoare | `railing_on_brackets` pe slot GLOW, vizibil negru pe fond albastru | **prezent**, cel mai clar contrast al valului |
  | cameră mică pe acoperiș, retrasă spre spate | volum mic, fără geamuri vizibile | cub retras pe -Y | **prezent** |

- **Abateri:** niciuna semnificativă. Tenta INDIGO (`#4F6FB8`) se distinge
  clar de tenta LIGHT a celorlalte case în comparație.

### `buildings/blue_house_e.glb`

- **Triunghiuri:** 3287. Buget: 6500.
- **Cote măsurate:** 8,20 × 6,49 × 8,50 m (contract 7×6 m, 8,5 m — lățimea
  +17%, din scara exterioară proeminentă pe fața +X, geometrie cerută).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | volum principal (2 etaje) + volum scund alăturat (1 etaj) | formă în L vizibilă | corp principal `h=6.0` + volum scund `h=3.2` alăturat pe +Y | **prezent** |
  | 2 uși pe corpul principal | alăturate, spre stânga | `arch_opening` × 2 | **prezent** |
  | scară exterioară solidă, urcă spre dreapta | vizibilă clar, balustradă albă | `solid_stair` + `railing_on_brackets`, pe fața +X | **prezent** |
  | etaj 3 mic, retras, deasupra corpului înalt | volum mic sus | cub retras | **prezent** |

- **Abateri:** niciuna semnificativă — toate elementele din listă sunt
  prezente și în poziția corectă.

### `buildings/haveli_facade.glb`

- **Triunghiuri:** 860. Buget: **900** (strict, per brief).
- **Cote măsurate:** 10,47 × 6,20 × 12,70 m (contract 10×6 m, 11 m —
  înălțimea +15,5%, din parapetul terasei + friza de sub cornișă, peste
  cele 3 etaje nominale).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | parter: 3 arcade mari deschise | goluri clare pe toată fața | `_cheap_arch_opening(open=True)` × 3 | **prezent**, geometria octogonală (colț tăiat) citește ca arc turtit la unghiul comparației |
  | etaj 1 și 2: 3 ferestre + balcon de piatră pe console | goluri închise + relief de balcon vizibil sub fiecare rând | `_cheap_arch_opening(open=False)` × 3/etaj + `chajja`+`balustrade` continuu | **abatere**: ferestrele/balcoanele nu se disting clar în randare — fațada celor 2 etaje mijlocii citește aproape plată la acest unghi, relieful balconului (0,45 m ieșire) e prea subțire ca umbră la distanța de comparație |
  | terasă cu balustradă pe toată lățimea | parapet crenelat vizibil sus | `balustrade`, merloane rare | **prezent** |
  | friză decorativă sub cornișă | bandă sub streașină | `chajja` îngust continuu | **prezent**, discret |

- **Abateri cunoscute și motiv:** golurile etajelor 1/2 (ferestre + balcoane)
  nu se citesc clar separate în comparație — la bugetul de 900 tri (strict),
  `_cheap_arch_opening` a fost redus la varianta cea mai ieftină posibil
  (fără firidă de adâncime pe ferestrele închise, vezi comentariul de cost
  din cod), iar la unghiul de cameră ales asta lasă etajele mijlocii
  vizual plate. Corectarea ar cere fie relief mai adânc (cost peste 900),
  fie un unghi de cameră diferit care să prindă umbra ferestrelor — netestat
  în runda asta. Geometria golurilor EXISTĂ la cotele corecte (verificat în
  cod, `arch_h`/`arch_w` per etaj), doar lizibilitatea la acest unghi/scară
  e sub cea a restului pieselor.

### `props/rooftop_tank.glb`

- **Triunghiuri:** 544. Buget: 700.
- **Cote măsurate:** Ø1,25 × 1,28 m (contract Ø1,2 × 1,4 m — apropiat).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | cilindru negru cu nervuri orizontale (3-4) | vizibile clar | `_rooftop_tank`, `n_ribs=4`, `segments=12` | **prezent** |
  | capac ușor bombat | vizibil | `frustum` + `cylinder` mic | **prezent** |

- **Abateri:** niciuna — cea mai fidelă piesă a valului, aproape identică
  cu decuparea.

### `props/rooftop_clutter.glb`

- **Triunghiuri:** 1204. Buget: 1400.
- **Cote măsurate:** 3,00 × 2,50 × 1,96 m (contract placă 3×2,5 m, stâlpi
  1,8 m — aproape exact).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | placă de terasă albastră | vizibilă | `box` pe slot WALL | **prezent** |
  | rezervor mic negru, colț stânga-spate | vizibil | acum corect NEGRU (fix sloturi) | **prezent** |
  | 2 grămezi de oale/lucruri | maro/lemn, spre mijloc/dreapta | acum corect MARO (fix sloturi) | **prezent** |
  | 2 stâlpi + sfoară | negru/lemn închis | acum corect NEGRU (fix sloturi) | **prezent** |
  | 2 rufe: galben (stânga), roz (dreapta) | vizibile clar, ușor lăsate | `_cloth` × 2, pe `Clutter_Laundry` | **prezent** |

- **Abateri:** niciuna semnificativă după fixul de sloturi — toate
  elementele din listă sunt prezente și corect colorate.

## Val 3b — bazarul (aceeași sesiune, 29 sep 2026)

Contract: `docs/asset_briefs/jodhpur_kit.md` §1.5. Build:
`build_jodhpur_bazaar.py` (fișier nou). Brief-ul nu dă bugete stricte de
triunghiuri pentru bazar (doar cote) — bugetele de mai jos sunt cele
declarate în `emit()`, calibrate pe măsurătoare, nu presupuse (memoria
`plafon-masurat-nu-presupus`).

**Bug real găsit la primul `--compare`:** funcția `_build_stall_canopy`
construia fețele copertinei pe `b.bm` (Builder-ul lemnului) în loc de
`bc.bm` (Builder-ul dedicat `Canopy`) — nodul `Canopy` ieșea cu 0 vertecși,
iar `emit()` crăpa la calculul de bounding box (`min()` pe listă goală).
Fix: toate apelurile `bm.faces.new`/`bm.verts.new` din bucla copertinei
mutate pe `bc.bm`.

**A doua rundă de corecții, după ce toate 8 au exportat și au fost privite:**

- **`stall_canopy_a/b/c`:** grămezile de marfă (cilindri coloraţi deasupra
  lăzilor) erau aproape invizibile la raza/înălțimea inițială (0.11/0.14 m)
  — mărite la 0.19/0.22 m, acum se văd clar ca „grămezi", nu ca puncte.
- **`thela_cart`:** roțile foloseau `METAL_DARK` (VOLCANIC_BLACK), dar
  brief-ul §1.5 cere explicit „4 roți de LEMN cu spițe" — corectat la
  `CRATE_WOOD`. La randare, spițele erau invizibile pe fondul negru uniform;
  cu lemnul, discul/butucul/spițele se disting clar.
- **`textile_strip`:** camera implicită (azimut 5°, aproape din lungul
  stâlpilor pe axa X) arăta piesa din MUCHIE — o bandă îngustă aproape
  ilizibilă. Fix: azimut 80° (aproape perpendicular pe axa X), ca să se
  vadă lățimea/culorile celor 7 panze.
- **`chai_stall`:** oalele de metal aveau tentă gri neutru (`#8A8A8E`),
  decuparea arată metal închis-cald — corectat la `#4A4238`.

**Tabel de fidelitate** (element / pe decupare / în GLB / verdict, privit
efectiv în `docs/asset_briefs/img/jodhpur_fidelity/<nume>.png`):

### `props/stall_canopy_a.glb`, `_b.glb`, `_c.glb`

- **Triunghiuri:** 1520 fiecare. Buget declarat: 1600 (măsurat — 1400
  inițial era o estimare fără măsurătoare; forma completă din brief nu
  încape sub 1500).
- **Cote măsurate:** 3,50 × 3,10 × 2,60 m (contract 3×2,5 m, copertină la
  2,6 m — lățimea/adâncimea peste din streașina copertinei, care iese
  intenționat peste amprenta stâlpilor).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | 4 stâlpi de lemn | vizibili la colțuri | `cylinder` × 4 | **prezent** |
  | copertină lăsată (catenară), înclinată spre spate | curbură moale vizibilă | 4 segmente, `sag` parabolic + pantă front/back | **prezent**, silueta curbată se citește clar |
  | tejghea/ramă de lemn joasă | vizibilă la baza stâlpilor | 4 grinzi orizontale | **prezent**, mai subțire (sârmă) decât masa solidă de pe decupare — abatere minoră |
  | lăzi cu marfă în trepte (2-3 niveluri) | grămezi colorate vizibile | 3 niveluri de ladă + grămezi cilindrice colorate deasupra | **prezent**, corectat runda 2 (grămezile inițiale erau prea mici) |
  | culoare copertină: a=galben, b=roz, c=verde | clar diferențiate | `CAR_YELLOW`/`FLAMINGO_PINK`/`TROPICAL_GREEN` | **prezent** |

- **Abateri cunoscute:** rama/tejgheaua joasă citește mai degrabă ca un
  cadru de bare decât ca o masă solidă — decuparea arată o structură mai
  plină. Nu s-a corectat în runda asta (element secundar, lăzile cu marfă
  domină corect cadrul).

### `props/textile_strip.glb`

- **Triunghiuri:** 599. Buget declarat: 1600.
- **Cote măsurate:** 10,15 × 0,15 × 2,60 m (contract 10 m între stâlpi,
  pânze 0,9×1,6 m — lungimea exactă).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | 2 stâlpi + sfoară lăsată | vizibili la capete | `cylinder` × 2 + `box` segmentate pe catenară | **prezent** |
  | 7 pânze colorate | portocaliu, galben, roz, roșu, verde, galben, roz | 7 pânze, `TS_COLORS` cu aceleași 7 culori (poziționate în ordine, dar unele adiacențe diferă ușor de decupare) | **prezent** |
  | margine de jos crestată (zimți) | vizibilă | 3 „dinți" per pânză, geometrie (colț tăiat) | **prezent** |
  | pânze opace | vizibile clar, nu transparente | fără alpha, atlas fără canal alpha | **prezent** |

- **Abateri cunoscute și motiv (rezolvate):** camera implicită (azimut 35°)
  arăta piesa aproape din muchie (stâlpii pe axa X, camera aproape aliniată
  cu ei) — corectat la azimut 80°. După fix, toate 7 pânze sunt clar
  vizibile și distincte.

### `props/spice_sacks.glb`

- **Triunghiuri:** 1232. Buget declarat: 1400.
- **Cote măsurate:** 1,48 × 0,84 × 0,65 m (contract 1,6×1,0×0,9 m — puțin
  sub, cei 3 saci sunt compacti).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | 3 saci de iută cu gura răsfrântă | 2 mari în prim-plan, al 3-lea mai mic/parțial vizibil în spate | `frustum`+`cylinder`×3 per sac × 3 saci, al treilea mai mic, poziționat median-spate | **prezent** |
  | conuri de condiment: roșu, galben | vizibile clar, umplu gura sacului | `frustum` deasupra fiecărui sac, roșu/galben (al 3-lea tot roșu) | **prezent** |

- **Abateri:** niciuna semnificativă — cea mai fidelă piesă a bazarului,
  aproape identică cu decuparea la prima randare.

### `props/thela_cart.glb`

- **Triunghiuri:** 3028. Buget declarat: 3100 (măsurat — cele 4 roți cu
  spițe reale costă ~380 tri/roată după bevel, cerute explicit de brief
  „4, nu 2 — planșa câștigă"; 2200 inițial era o estimare fără măsurătoare).
- **Cote măsurate:** 3,00 × 1,20 × 0,83 m (contract 2,4×1,2×1,1 m — lățimea
  peste din mânerul de împins proeminent pe -X, geometrie cerută de
  decupare, nu abatere de corp).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | platformă de lemn cu ramă | vizibilă, bordură ridicată | `box` + 4 borduri | **prezent** |
  | 4 roți de lemn cu spițe (nu 2 de bicicletă) | vizibile, spițe distincte | `_wheel` × 4, disc+butuc+4 bare, acum pe `CRATE_WOOD` | **prezent**, corectat runda 2 (inițial metal negru, spițe invizibile) |
  | grămadă de fructe colorate (verde, galben, portocaliu, roșu) | vizibilă, umple platforma | 11 cilindri colorați, 2 niveluri | **prezent** |

- **Abateri cunoscute:** niciuna semnificativă după fixul de material al
  roților.

### `props/chai_stall.glb`

- **Triunghiuri:** 896. Buget declarat: 1600.
- **Cote măsurate:** 2,90 × 2,40 × 2,50 m (contract 2,5×2,0×2,6 m —
  apropiat).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | 4 stâlpi + acoperiș de pânză bej, aproape plat | vizibil, panta ușoară | `box` pe 2 fețe, pantă front/back 0,20 m | **prezent** |
  | tejghea de lemn joasă + 2 dulapuri laterale | vizibile | 3 `box`-uri | **prezent** |
  | 2 oale de metal + o ceainică | vizibile pe tejghea | `cylinder` × 2 + corp+cioc ceainică | **prezent**, culoare corectată runda 2 (gri → metal cald închis) |

- **Abateri cunoscute:** spațiul dintre stâlpul central și cel din dreapta
  citește parțial gol în comparație (decuparea are mai multă masă vizuală
  în acea zonă) — element secundar, nu afectează lizibilitatea tarabei.

### `props/marigold_garland.glb`

- **Triunghiuri:** 640. Buget declarat: 800 (măsurat — fără bevel pe
  icosfere, deja rotunjite prin `subdivisions`; 2400 inițial supraestima
  costul).
- **Cote măsurate:** 2,59 × 0,15 × 1,09 m (contract 2,5 m deschidere, 0,8 m
  lăsare — apropiat).

  | element | pe decupare | în GLB | verdict |
  |---|---|---|---|
  | margele portocalii pe o catenară | vizibile, dese | 22 icosfere (`subdivisions=1`), rază variabilă | **prezent** |
  | 5 ciucuri care atârnă | vizibili, mai mari decât mărgelele | 5×2 icosfere (bulb mare+mic) sub catenară | **prezent** |

- **Abateri:** niciuna semnificativă — a doua cea mai fidelă piesă a
  bazarului.

## Stare la oprire (val 3, oprire de urgență — dezvoltatorul închide PC-ul)

**Sesiune întreruptă în timpul lucrului la `build_jodhpur_city.py`** (brief
§1.4, casele + `haveli_facade` + props de acoperiș). Commit WIP:
`805173a7` pe `feat/jodhpur-kit-city`. **NIMIC din val 3 nu e verificat
vizual încă** (fără `--compare`, fără planșă de fidelitate) — tot ce
urmează e doar "buildul rulează și `verify_glb.py` trece pe cotă/buget",
nu un verdict de fidelitate.

### Ce există (exportat, dar NEVERIFICAT vizual)

Toate cele 7 piese din `buildings/blue_house_{b,c,d,e}.glb`,
`buildings/haveli_facade.glb`, `props/rooftop_{tank,clutter}.glb` s-au
construit și exportat cu succes din `build_jodhpur_city.py` (commit
`805173a7`). Listele de elemente (brief §0.1 pasul 1) sunt scrise în
docstring-urile fiecărei funcții `build_blue_house_*`/`build_haveli_facade`
din fișier, citite din decupări. Contractul de noduri (House_Wall/
House_Trim/House_Glow(+House_Rail)) e respectat pe toate — bug găsit și
corectat în sesiune: primele versiuni scriau ușile pe Builder-ul greșit
(`bglow` în loc de `bg`), ceea ce ar fi exportat `House_Trim` gol și
`House_Glow` cu uși maro în loc de geamuri negre — vezi istoricul commit-ului
pentru fix.

Triunghiuri la ultima rulare (buget vs. măsurat):

| piesă | tris | buget | status |
|---|---:|---:|---|
| blue_house_b | 2838 | 6000 | sub buget |
| blue_house_c | 1231 | 3800 | sub buget |
| blue_house_d | 4302 | 6500 | sub buget |
| blue_house_e | 3287 | 6500 | sub buget |
| haveli_facade | 860 | 900 | sub buget (fix: merloane mai late/rare pe balcoane+terasă, 176→132 tri/segment) |
| rooftop_tank | 544 | 700 | sub buget |
| rooftop_clutter | 1204 | 1400 | sub buget (fix: rezervor mic 12→8 segmente/3→2 nervuri, oale/stâlpi 8→6 segmente, pânze 4→2 segmente) |

### Ce NU e făcut

1. **`haveli_facade` peste buget** (1036 vs 900 — brief-ul dă 900 ca
   plafon explicit pentru piesa asta, spre deosebire de casele simple unde
   depășirea motivată e acceptabilă). S-a scris un vocabular ieftin propriu
   (`_cheap_arch_opening`, colț tăiat în loc de profil de arc cu `steps`)
   ca să înlocuiască `arch_opening` (prea scump la 9 goluri pe un buget de
   900), a coborât de la 3954 → 1036 tri în 4 runde, dar tot 136 tri peste.
   Pasul următor: fie mai taie o balustradă/chajja, fie — dacă geometria
   rămasă e deja minimul pentru lista de elemente a briefului (3 arcade +
   6 ferestre + 2 balcoane continue + parapet terasă + friză) — se scrie
   onest numărul și motivul (ca la casele simple, brief §1.4) și se cere
   verdictul dezvoltatorului dacă 900 rămâne strict sau se acceptă o mică
   depășire.
2. **`rooftop_clutter` peste buget** (1672 vs 1400) — nu s-a atins deloc încă
   în sesiunea asta după prima rulare reușită; probabil cablurile/rufele
   (`_cloth`, 4 segmente × 2 rufe × Builder separat `bl`) costă mai mult
   decât părea. Netratat.
3. **ZERO comparații de fidelitate** (`preview_jodhpur.py --compare`) rulate
   pe vreo piesă din val 3 — pasul 3 din brief §0.1 ("randează comparația,
   UITĂ-TE la ea, scrie ce arată") nu s-a făcut deloc încă. Tot ce e mai sus
   sunt măsurători de cotă/tri, NU dovadă de fidelitate față de decupare.
4. **`build_jodhpur_bazaar.py` nu există încă** — niciuna din cele 8 piese
   de bazar (stall_canopy_a/b/c, textile_strip, spice_sacks, thela_cart,
   chai_stall, marigold_garland) nu are nicio linie de cod scrisă.
5. **`verify_jodhpur.sh` nu a fost extins** cu liniile pentru val 3 (nici
   casele, nici bazarul).
6. **`COMPARE_SPECS`/`WAVE_PIECES` din `preview_jodhpur.py` nu au fost
   extinse** cu cheia `"3"` sau cu tentele/camerele per piesă din val 3.
7. **`docs/asset_briefs/img/jodhpur_fidelity_val3.png` nu există.**
8. **Niciun commit de grup** (case / haveli+props acoperiș / bazar) — doar
   commit-ul WIP de mai sus, cu tot ce exista la momentul opririi.

### Ce ar trebui să facă următoarea sesiune, în ordine

1. Reia din `build_jodhpur_city.py` (commit `805173a7`, branch
   `feat/jodhpur-kit-city`, worktree `D:/GameDev/wt-jod-city`).
2. Rezolvă bugetul `haveli_facade` (900) — vezi punctul 1 de mai sus.
3. Rezolvă bugetul `rooftop_clutter` (1400).
4. Adaugă `COMPARE_SPECS` pentru toate cele 7 piese din val 3 în
   `preview_jodhpur.py` (tente: light `#8FB0DC`, indigo `#4F6FB8`,
   trim/alb din atlas, `*_Glow` închis, ca în restul kitului).
5. Rulează `--compare` pe fiecare piesă, UITĂ-TE la randare, scrie tabelul
   de fidelitate (element/decupare/GLB/verdict) în inventar — pasul care
   lipsește complet acum.
6. Iterează geometria pe ce arată randarea greșit (aproape sigur: cel puțin
   o piesă va avea fața greșită spre cameră sau proporții greșite — istoricul
   valurilor 1/2a/2b arată că asta se întâmplă aproape mereu la prima
   randare).
7. Abia după verdictul vizual pe toate piesele din `build_jodhpur_city.py`,
   trece la `build_jodhpur_bazaar.py` (8 piese noi).
8. Extinde `verify_jodhpur.sh`, `WAVE_PIECES["3"]`, randează
   `jodhpur_fidelity_val3.png`, rulează verify complet, commit pe grupuri.

## Val 3 — încheiat (sesiune de continuare, 29 sep 2026)

Toți cei 8 pași de mai sus sunt făcuți. Rezumat (detaliile complete sunt în
secțiunile „Val 3 — orașul albastru" și „Val 3b — bazarul" de mai sus):

- Bugetele `haveli_facade` (860/900) și `rooftop_clutter` (1204/1400)
  rezolvate.
- Bug real de sloturi suprascrise orb (rezervor/oale/stâlpi/plantă pictate
  WALL) corectat în cod pe `blue_house_b/c` și `rooftop_clutter`.
- Bug real de geometrie pe Builder greșit (`Canopy` gol, fețele ajungeau în
  `Canopy_Wood`) corectat pe cele 3 `stall_canopy_*`.
- `COMPARE_SPECS`/`WAVE_PIECES["3"]` extinse cu toate cele 15 piese (7
  oraș + 8 bazar), inclusiv camere dedicate pentru piesele alungite
  (`haveli_facade`, `textile_strip`) — camera implicită (azimut 35°) nu
  funcționează pe piese cu o axă mult mai lungă decât celelalte.
  `_strip_dup_suffix()` adăugat în `preview_jodhpur.py` — Blender adaugă
  sufix `.NNN` la nume de nod duplicate rămase în sesiune, ceea ce rata
  lookup-ul de tentă și scotea piese gri la prima rundă de comparații.
- Toate cele 15 piese noi rulate prin `--compare`, privite efectiv, tabel
  de fidelitate scris în inventar; câteva runde de corecții după privit
  (grămezi de marfă mărite, roți de lemn nu metal, cameră `textile_strip`,
  culoare oale `chai_stall`).
- `verify_jodhpur.sh` extins cu ambele valuri (3 și 3b) — `VERDICT KIT: OK`,
  36/36 GLB.
- `docs/asset_briefs/img/jodhpur_fidelity_val3.png` generată (15 piese).
- 2 commit-uri de grup (case+haveli+props acoperiș, apoi bazarul) pe
  `feat/jodhpur-kit-city`, push la fiecare.

**Ce nu s-a terminat / abateri rămase, documentate onest** (nu blocante,
nu ascunse):

- `haveli_facade`: ferestrele + balcoanele etajelor 1/2 nu se disting clar
  în comparație la bugetul strict de 900 tri (geometria există la cotele
  corecte, dar relieful e prea subțire pentru unghiul/scara comparației).
- `stall_canopy_*`: rama/tejgheaua joasă citește ca un cadru de bare, nu ca
  masă solidă (element secundar, lăzile cu marfă domină corect cadrul).
- `chai_stall`: spațiul dintre stâlpul central și cel din dreapta citește
  parțial gol față de decupare (element secundar).
- Hex-urile de tentă pentru culorile bazarului (`#F2C230`, `#D94A38`,
  `#3FA556`, `#E8792E`, `#E874A1`) sunt aproximări rezonabile, nu extrase
  dintr-o sursă exactă a paletei native — de recalibrat dacă la integrarea
  în Godot culorile ies vizibil diferite de decupare.
