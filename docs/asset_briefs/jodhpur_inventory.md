# Inventar assets — Jodhpur (`Track17`), val 1: pilotul (v2)

Contract: `docs/asset_briefs/jodhpur_kit.md` §1.1, §3 pasul 1. Verdict kit:
`bash tools/blender/verify_jodhpur.sh` → `VERDICT KIT: OK` (2/2 GLB).

**v1 a fost RESPINSĂ pe fidelitate** (vezi „Jurnalul v1" la finalul
fișierului). Acest inventar descrie **v2**, rescrisă cu un vocabular de forme
indo-saracenice nou (`tools/blender/jodhpur_shapes.py`) — arcade reale, cupole,
chhatri, balustrade, chajja, creneluri, scară solidă.

Planșa de vocabular (fiecare formă lângă cutia de referință 4×1,8×1,5 m):
`docs/asset_briefs/img/jodhpur_shapes.png`, cu randări individuale apropiate
în `docs/asset_briefs/img/jodhpur_shapes_<forma>.png` (arch_round, arch_pointed,
arch_cusped, arcade, dome_hemisphere, dome_onion, chhatri, balustrade,
railing_brackets, balcony_band, chajja, crenel_rect, crenel_round,
solid_stair, stepped_plinth).

Comparațiile de fidelitate v2 (decupare ↔ randare din GLB exportat, culoare
FLAT hex×AO prin `preview_jodhpur.py --compare`, TASK C):
`docs/asset_briefs/img/jodhpur_fidelity/ghanta_ghar.png`,
`docs/asset_briefs/img/jodhpur_fidelity/blue_house_a.png`, adunate în
`docs/asset_briefs/img/jodhpur_fidelity_val1.png`.

## `buildings/ghanta_ghar.glb`

- **Triunghiuri:** 10 156 total (`Tower_Stone` 8 756, `Clock_Glow` 848,
  `Tower_Glow` 552). Peste bugetul v1 (4 300) — vocabularul de arcade/cupolă/
  chhatri reale costă mai mult decât cutiile tesite din v1, dar produce forma
  corectă (brief: fidelitatea e criteriul, nu bugetul minim). Buget declarat
  în `verify_jodhpur.sh`: 10 500.
- **Cote măsurate din GLB** (`Tower_Stone`):
  - bază: **7,00 × 7,00 m** — exact cota din tabel.
  - înălțime: **21,41 m** față de **22 m** contract (**−2,7%**). Turnul
    alocă explicit `remaining = (22 − z_chhatri) × 1,06` cupolei+finialului
    (vezi comentariul din `build_ghanta_ghar`), dar profilul „onion" al
    cupolei saturează sub-liniar față de `finial_h` — creșterea factorului
    de la 1,0 la 1,06 a adus turnul doar de la 21,29 la 21,41 m. Abatere
    mică, sub pragul de refacere (±15% pe h/l, vezi mai jos), dar nescrisă
    complet în contract: rămasă ca notă pentru integrare (turnul poate fi
    rescalat pe Z cu ×1,028 dacă 22 m e cotă strictă de gameplay).
  - origine: la bază, centrată (`--origin=assembly`).
- **h/l siluetă (măsurat pe randarea de comparație, prag alpha vs fundal):**
  **2,48**, față de **2,17** pe decupare (**+14,3%**, la limita benzii
  ±15% — motivul: cupola+chhatri-ul (pasul 7-8) sunt proporțional mai înalte
  față de baza de 7 m decât în decupare, ca lanterna și cupola să rămână
  clar lizibile ca forme separate la scara jocului).
- **Tabel de fidelitate** (element din lista scrisă în docstring-ul
  `build_ghanta_ghar`, brief §0.1 pasul 1):

  | element | pe planșă | în GLB v2 | verdict |
  |---|---|---|---|
  | soclu în trepte (2-3 nivele) | soclu teșit, un nivel vizibil | `stepped_plinth`, 3 nivele | OK |
  | tier 1: gol mare în arc pe fiecare față | poartă mare centrată | `arch_opening` stil "pointed", 4 fețe, geam retras | OK — arc real, nu fantă |
  | tier 2: 3 nișe oarbe în arc pe fiecare față | 3 arcade joase | 3× `arch_opening` cu reveal mic + pilaștri de umplutură între ele | OK |
  | fus pătrat, 2 ferestre înalte în arc pe fiecare față | 2 goluri per față | 2× `arch_opening` pe fiecare din cele 4 fețe (8 total), cu pilastru central | OK — arce curbate reale, nu fâșii |
  | brâu orizontal, iesit în consolă | bandă îngustă | `balcony_band` circulară, între fus și ceas | OK |
  | etajul ceasului, 4 cadrane fără cifre | 2 vizibile din unghi, disc+ace | 4 cadrane `Clock_Glow`, disc FOAM_WHITE, ace VOLCANIC_BLACK, fără cifre | OK |
  | balcon pe console + creneluri mici dese | parapet crenelat + console | `balcony_band(crenellated=True)`, 16 merloane + console vizibile | OK |
  | chhatri: colonadă DESCHISĂ cu arce (nu cilindru plin cu găuri) | 4 arcade, stâlpi subțiri | `chhatri()`, 8 coloane, arce "cusped" deschise (`_arch_band`, fără umplutură între picioare), chajja proprie | OK — colonadă vizibil deschisă |
  | cupolă nervurată (ribbed) + finial | cupolă bombată + spiră | `dome(profile="onion", ribs=12)` + kalash (tijă+bulb) | OK |
  | fără cifre pe cadrane | — | confirmat | OK |

- **Abateri cunoscute și motiv:**
  - **Înălțimea** 21,41 m vs 22 m (−2,7%) — vezi mai sus.
  - **h/l** 2,48 vs 2,17 (+14,3%) — la limita benzii, decizie deliberată
    pentru lizibilitatea chhatri-ului/cupolei la scara jocului.
  - **Stilul "cusped"** (multifoil) al arcelor de chhatri nu se distinge
    vizual clar de "pointed" la distanța/rezoluția randării de comparație —
    festoanele (`_arch_profile` stil "cusped") sunt subtile. Se citește
    totuși ca arcadă corectă din unghiul de joc (10 m sus, 12,5 m spate);
    de verificat separat cu `--driver` la integrare dacă merită accentuate.

## `buildings/blue_house_a.glb`

- **Triunghiuri:** 4 979 total (`House_Wall` 812, `House_Trim` 39,
  `House_Rail` 4 128 — scara solidă + balustrada domină bugetul, ca și în
  v1, dar acum e o masă reală, nu trepte plutitoare). Buget declarat: 5 300.
- **Cote măsurate din GLB** (`House_Wall`):
  - amprentă (fără cornișa care iese): ~**6,2 × 6,6** m (cornișa `chajja`
    adaugă ~0,3 m pe fiecare parte pe fețele cu streașină) față de **6×6 m**
    contract — cornișa proeminentă e cerută explicit de brief ("cornice cu
    lip proeminent"), deci nu e o abatere de corp, ci geometria cerută.
  - înălțime totală (cu cutia de pe acoperiș): **8,06 m**; pereții +
    parapetul ating exact **6,5 m** cum cere contractul.
  - origine: la bază, centrată (`--origin=assembly`).
- **h/l siluetă:** **0,99** față de **0,95** pe decupare (**+4,2%**, bine în
  bandă).
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB v2 | verdict |
  |---|---|---|---|
  | corp cubic, parapet + cornișă proeminentă | parapet cu buză | `chajja` pe toate 4 laturile, profil cu dedesubt înclinat, umbră vizibilă | OK |
  | ușă în arc pe fața din față | arc, lemn | `arch_opening(style="round")`, placă WOOD retrasă, gol real | OK — arc curbat real (v1 aproxima cu colț teșit) |
  | 2 ferestre cu obloane pe fața laterală | obloane deschise | goluri reale (`arch_opening`) + obloane WOOD suprapuse | OK — golul e real, nu doar obloanele pictate (bug-ul v1) |
  | scară exterioară SOLIDĂ, latura dreaptă, urcă spre spate | masă în trepte, obraz plin | `solid_stair` cu obraz plin, trepte pline (nu foi suspendate), nosing alb | OK — fix-ul central al v2 |
  | balustradă pe console de-a lungul scării | bară + stâlpi | `railing_on_brackets`, console triunghiulare vizibile | OK |
  | cutie pe acoperiș, retrasă stânga-spate | volum simplu cu parapet | prezent, poziție/dimensiune păstrate din v1 | OK |

- **Abateri cunoscute și motiv:**
  - **Culoarea e mai palidă decât decuparea** — măsurat direct pe randare:
    fața cu ușa (+Y local) cade pe partea umbrită a AMBELOR lumini
    direcționale ale hărnașului (`sun` la azimut≈35°, `fill` opus, ambele
    dau produs scalar negativ cu normala +Y). Izolat cu AO forțat la 1,0,
    materialul (`#8FB0DC`) randează corect, saturat (217,238,255). Fix
    parțial aplicat: `fill.energy` 1,1→2,6 și ambientul de fundal 1,0→1,8
    (`preview_jodhpur.py::_neutral_shot`) — a adus pixelii din (113,124,137)
    la (149,163,179), vizibil albastru dar tot sub saturația hex-ului țintă.
    **Nerezolvat complet**: hărnașul de comparație are un unghi de lumină
    fix, potrivit pentru piese simetrice (turnul), dar nu pentru o clădire
    asimetrică unde fața de interes cade sistematic în umbră. O soluție mai
    bună ar cere fie o a treia lumină dedicată feței +Y, fie o rotire a
    hărnașului per-piesă — nu implementată aici (risc de a strica turnul,
    care depinde de aceleași unghiuri).
  - **Scara e vizibil o masă mare** în cadrul comparației — redusă de două
    ori (rulaj 5,4 m → 3,3 m → 2,5 m, lățime 1,1 m → 0,75 m) față de prima
    încercare, care umplea diagonal tot cadrul. Rămâne mai proeminentă decât
    pe decupare (unde scara ocupă vizual mai puțin din siluetă), dar nu mai
    domină compoziția și nu mai ascunde ușa.

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
  nu după slot).
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
    textură de clasă proxy la tentă FLAT (TASK C) — motivul real nu era
    materialul (izolat, corect), ci unghiul camerei/luminii hărnașului,
    care pune fața de interes a acestei piese asimetrice în umbră. Parțial
    compensat prin creșterea fill+ambient; nerezolvat complet (vezi
    „Abateri cunoscute" mai sus).

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
