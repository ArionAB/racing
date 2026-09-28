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
