# Critic pilot R1 — Jodhpur assets (ghanta_ghar, blue_house_a)

Metodă: măsurători PIL (silueta pe componenta conexă cea mai mare, profil de lățime pe fracții de înălțime, eșantioane de culoare mediane) + inspecție vizuală pe crop-uri cu grilă. Fără citire de cod/brief.

## Verdict rezumat

| Piesă | Verdict |
|---|---|
| `ghanta_ghar` | **FAIL** |
| `blue_house_a` | **FAIL** |

Ambele piese au silueta generală recognoscibilă (turn/casă cu etaj pe-acoperiș), dar diferă la nivel de detaliu arhitectural pe fiecare etaj și la culoare — exact tipul de abatere reclamat.

---

## 1. ghanta_ghar (turnul cu ceas)

### A. Lista de elemente — DOAR din referință (de jos în sus)

| # | Element | Înălțime relativă | Lățime relativă (față de bază) | Deschideri/față vizibilă | Note |
|---|---|---|---|---|---|
| 1 | Soclu/bază octogonală, ușor evazată | ~0-13% | 100% (cea mai lată) | 2 arcade ogivale mari, adânci (uși), colț tăiat octogonal | ton cărămiziu deschis, umbră adâncă în interior |
| 2 | Etaj cu deschideri mici | ~13-27% | ~92% | 2 ferestre mici arcuite (ogivale, subțiri) pe fața vizibilă | aceeași octogonală |
| 3 | Corp cu ceasuri | ~27-70% (cel mai înalt tronson) | ~65-75%, pereți verticali drepți, colț teșit vizibil | 2 cadrane de ceas rotunde (alb, cifre romane, ace negre) pe fețele vizibile | cel mai proeminent element, brâu orizontal sub și deasupra |
| 4 | Cornișă/balustradă cu merloane mici | ~70-77% | ~85% (ușor mai lată ca și corp de ceas) | mici crenele/dinți decorativi pe muchia superioară | linie subțire, silueta zimțată |
| 5 | Chhatri (foișor deschis, colonadă) | ~77-93% | ~90%, coloane subțiri, complet deschis (nu zidărie) | colonadă cu arce rotunjite, deschis pe tot perimetrul | fus stâlpișori rotunzi vizibili |
| 6 | Cupolă (dom bulbos, canelat) | ~93-100% | dom ≈70% din lățimea chhatri-ului | — | formă rotundă, plină, netedă, cu un vârf mic (finial scurt, subțire) |

Culori referință: pereți cărămiziu-somon cald (RGB ~163,101,74 / HSV H≈18°, S≈55%, V≈64%), cadran ceas alb curat, cupolă puțin mai deschisă/roz decât pereții (RGB ~242,166,121), uși/interior arcade aproape negre (umbră, RGB ~46,23,12).

### B. Comparație pe render

| # | Element | Prezent? | Observație |
|---|---|---|---|
| 1 | Bază octogonală, 2 arcade mari | **Greșit** | are 2 arcade mari JOS **plus** un rând de 4-5 arcade mici deasupra lor pe aceeași "bandă" — practic elementele 1+2 din referință sunt comprimate/suprapuse într-un singur tronson dublu-rând, iar planul e mai degrabă pătrat cu colțuri teșite decât octogonal curat |
| 2 | Etaj cu ferestre mici separat | **Absent ca tronson distinct** | contopit cu baza (vezi mai sus) |
| 3 | Corp cu ceasuri | **Prezent, dar deformat** | doar 2 cadrane vizibile (ok ca număr pe fața dată), dar sunt discuri **gri deschis, fără cifre și fără ace vizibile** (un singur semn neclar pe unul) — arată ca nișe goale, nu ca ceasuri citibile; proporția tronsonului e prea îngustă/comprimată vertical față de referință |
| 4 | Cornișă/balustradă zimțată | **Absent** | nu există bandă de merloane; trecerea de la corpul de ceasuri la chhatri e directă |
| 5 | Chhatri (colonadă deschisă) | **Greșit** | coloanele/arcele sunt **ogivale ascuțite**, nu rotunjite, iar spațiul citește mai degrabă ca o coroană cu crestături decât ca foișor deschis — nu se vede prin el ca în referință |
| 6 | Cupolă | **Formă greșită** | e o cupolă **canelată/fațetată tip "dovleac"**, mai ascuțită la vârf și cu caneluri verticale marcate, spre deosebire de forma netedă, rotunjită, bulboasă din referință; finial-ul e **mult mai lung și subțire** (aproape o antenă) față de vârful scurt din referință |

### Măsurători cantitative (profil de lățime pe silueta izolată, px)

Referință (h_total ≈ 791 px, exclude eticheta): lățimea crește constant de la vârf (≈11px la f=0.02) la maxim ≈350px la f=0.75 (baza), fără trepte bruște — profil **continuu, tronconic**, coerent cu un turn cu tronsoane suprapuse lin.

Render (h_total ≈ 593 px): lățime ≈124-130px în banda ceasurilor (f=0.02-0.08 = cupolă/chhatri, secțiune subțire), apoi salt la ≈200px la f=0.10 (chhatri→corp ceas), relativ constantă ≈200px până la f=0.65, apoi salt la ≈248-290px pentru bază (f=0.70-0.98). Deci render-ul are **trepte discrete, în scări**, nu tranziția lină din referință — confirmă vizual că fiecare tronson e prea "cutie" și tranzițiile prea abrupte.

Raport lățime bază / lățime maximă corp ceas: referință ≈ 350/276 ≈ **1.27**; render ≈ 290/203 ≈ **1.43** — baza render-ului e proporțional mai lată/evazată față de corp decât în referință (>15% peste).

### C. Culoare (RGB median, eșantion pereți/cadran/cupolă)

| Zonă | Referință RGB (HSV) | Render RGB (HSV) | Match? |
|---|---|---|---|
| Perete principal | 163,101,74 (H18°, S55%, V64%) | 119,96,75 (H29°, S37%, V47%) | **Nu** — render mai închis (V -17pp) și mult mai puțin saturat (S -18pp); familia de nuanță (cărămiziu cald) e păstrată grosier dar tonul e stins, cenușiu |
| Cadran ceas | alb curat ~250,250,250 | gri 195-202,195-202,194-201 (aproape neutru, fără alb pur) | **Nu** — ar trebui să fie alb distinct, contrastant; în render e un gri mediu, șters, apropiat ca luminanță de zidărie |
| Cupolă / acoperiș superior | 242,166,121 (mai deschis și mai cald decât pereții) | 233,233,233 (gri neutru complet) | **Nu** — cupola render-ului și-a pierdut culoarea caldă, e literal gri (posibil material implicit/neaplicat) |

Ordinea de luminanță (cupolă mai deschisă ca pereții, cadran cel mai deschis dintre toate) se păstrează parțial în render, dar **saturația e sistematic prea joasă** — piesa arată "spălăcită", nu cărămiziu-teracotă cum e referința.

### D. Verdict: **FAIL**
Motive: bandă dublă de arcade la bază (element inventat, nu în referință), cadrane de ceas nedescifrabile (fără cifre/ace — deși acceptat ca regulă generală, aici e mai grav: lipsesc și complet contrastul alb), lipsă bandă crenelată, colonadă cu arce ascuțite în loc de rotunjite, cupolă fațetată/conică în loc de bulb neted, finial disproporționat de lung, culori desaturate pe toate zonele (perete -18pp S, cupolă complet decolorată la gri).

### E. Fix-uri concrete

1. **Baza**: elimină rândul superior de 4-5 arcade mici; păstrează UN singur nivel cu 2 arcade ogivale mari și adânci per față (≈45-50% din lățimea feței, ≈55% din înălțimea tronsonului bazei), separat vizual printr-un brâu orizontal de etajul de deasupra.
2. **Etaj ferestre mici**: adaugă-l ca tronson distinct între bază și corpul de ceas (≈14% din înălțimea totală), cu 2 ferestre mici, ogivale, subțiri per față vizibilă.
3. **Cadrane ceas**: recolorează discul în alb pur (nu gri), adaugă cifre/marcaje minime pe margine (chiar simplificate, dar contrast clar) — brief-ul spune fără numerale pictate ca text, dar tot trebuie ac/marcaj vizibil de "ceas", nu disc gol; mărește tronsonul pe verticală cu ~10-15%.
4. **Bandă crenelată**: introdu o cornișă zimțată (mici merloane) între corpul de ceas și chhatri — element lipsă complet.
5. **Chhatri**: schimbă arcele coloanei din ogivale-ascuțite în arce rotunjite/semicirculare; lărgește spațiile deschise ca lumina să treacă vizual prin foișor.
6. **Cupolă**: înlocuiește forma canelată-conică cu o cupolă bulboasă netedă (profil de ceapă/dom), scurtează finial-ul la ~1/3 din lungimea actuală.
7. **Culoare globală**: crește saturația pereților spre S≈50-55% (H≈18-20°, cărămiziu cald, nu gri-maro); cupola trebuie să fie un ton mai deschis și mai cald decât pereții (nu gri neutru) — verifică dacă materialul cupolei chiar are textura/paleta aplicată sau a rămas pe default.

---

## 2. blue_house_a (casa albastră)

### A. Lista de elemente — DOAR din referință (de jos în sus)

| # | Element | Înălțime relativă | Lățime relativă | Detalii |
|---|---|---|---|---|
| 1 | Corp principal (cub), zid plin | 0-78% din total | 100% (bază lățime) | pereți drepți, un soclu discret la bază |
| 2 | Ușă | centrat vertical pe corp, ~40-51% din înălțimea corpului | ~22% din lățimea feței | ușă din lemn (maro cald), dreptunghiulară, pe fața din față, colț stânga-centru |
| 3 | Cornișă/parapet la acoperiș | ~78-85% | 100%+ (ușor ieșită în consolă) | bandă albă/deschisă la culoare, marchează limita corpului principal |
| 4 | Terasă/acoperiș plat | ~85% | — | suprafață plată, se vede parapetul |
| 5 | Cameră mică pe-acoperiș ("penthouse") | 85-100% (≈22% din total) | ~35-40% din lățimea corpului, centrată pe fața din spate/lateral | volum cub simplu, aceleași culori |
| 6 | Scară exterioară | de la nivelul solului până la terasă, pe fața dreapta | lățime ≈ 1/4-1/3 din fața laterală | scară deschisă, cu trepte și balustradă albă zimțată vizibilă, urcă în zig-zag (se vede întoarcerea), solidă/plină pe contur exterior dar goală pe interior (se văd treptele) |

Culori referință: pereți albastru mediu-saturat (RGB ~108,147,210, H≈217°, S≈49%, V≈82%), ușă maro lemn cald (RGB ~130,76,37), cornișă/balustradă aproape albă.

### B. Comparație pe render

| # | Element | Prezent? | Observație |
|---|---|---|---|
| 1 | Corp principal | Prezent | proporție corp/total ≈79% — se potrivește bine cu referința (~78%) |
| 2 | Ușă pe fața din față | **Absent** | pe fața frontală vizibilă în ambele randări (fidelity crop și pilot) NU există o ușă dreptunghiulară de lemn; există doar o mică nișă/proeminență joasă (parcă o treaptă sau soclu), nu o deschidere |
| 3 | Cornișă/parapet | Prezent, corect poziționat | bandă deschisă la culoare la ~78-85%, se potrivește |
| 4 | Terasă | Prezent | ok |
| 5 | Cameră pe-acoperiș | Prezent, proporție ok | ≈21% din total, aproape identic cu referința (22%) |
| 6 | Scară exterioară | **Prezent dar formă greșită** | în loc de trepte solide cu balustradă continuă, apare o structură care arată ca o **scară metalică/zăbrele albe subțiri, aproape transparentă**, mai degrabă ca un grătar decorativ decât ca o scară fizică plină; nu se văd trepte clare de călcat |

Element suplimentar nedocumentat în referință: pe fața laterală stângă a render-ului apare o formă de **scară/balustradă metalică verticală subțire** (linii paralele), care nu corespunde niciunui element din referință pe acea față.

### C. Culoare (RGB median)

| Zonă | Referință RGB (HSV) | Render RGB (HSV) | Match? |
|---|---|---|---|
| Perete principal | ~108,147,210 (H217°, S49%, V82%) | ~156,171,188 (H212°, S17%, V74%) | **Nu** — hue aproape identic (217° vs 212°, diferență mică, OK), dar saturația render-ului e de 3x mai mică (49%→17%) — casa arată gri-albăstruie pală, nu albastru viu |
| Ușă | 130,76,37 (maro lemn cald) | — (nu există ușă vizibilă) | **N/A — element lipsă** |
| Cornișă | 121,153,210 | 144,157,172 | aceeași problemă de desaturare |
| Cameră pe-acoperiș | 73,108,173 (mai închisă, mai saturată ca pereții) | 250,255,255 (aproape alb pur) | **Nu** — în referință acoperișul mic e mai închis/saturat decât corpul; în render e alb-gri deschis, complet decolorat |

### D. Verdict: **FAIL**
Motive: ușa frontală lipsește complet (element obligatoriu, poziție/culoare/formă nereproduse), scara exterioară e o schemă de zăbrele subțiri în loc de trepte solide cu balustradă plină, culoarea e sistematic desaturată pe toate suprafețele (S -30pp până la -49pp față de referință), camera de pe-acoperiș a pierdut orice tentă albastră (aproape alb pur vs. albastru mai închis în referință). Proporțiile de volum (corp/penthouse/total) sunt însă corecte, în limita a ~15%.

### E. Fix-uri concrete

1. **Ușă**: adaugă o deschidere dreptunghiulară pe fața din față, centrată stânga-centru, ≈22% din lățimea feței, ≈50% din înălțimea corpului, cu panou de lemn maro cald (RGB apropiat de 130,76,37) — momentan fața e oarbă.
2. **Scară**: înlocuiește structura de zăbrele/linii subțiri cu o scară solidă — trepte late, pline, cu balustradă continuă albă zimțată vizibilă din profil (ca în referință), care urcă vizibil în zig-zag pe toată înălțimea corpului.
3. **Element parazit pe fața laterală**: elimină liniile verticale paralele tip grilaj/scară secundară de pe fața stângă — nu au corespondent în referință.
4. **Culoare pereți**: crește saturația de la ~17% la ~45-50% păstrând hue-ul (H≈215°) — albastru mediu viu, nu gri-albăstrui pal.
5. **Culoare cameră pe-acoperiș**: aplică material albastru (ușor mai închis decât corpul principal, nu alb) — pare să nu aibă deloc textură/culoare aplicată momentan.
6. **Cornișă**: după corectarea saturației pereților, verifică din nou dacă cornișa iese suficient de deschisă la culoare prin contrast (în referință e aproape albă pe fond albastru mediu — contrast ridicat, trebuie păstrat).

---

## Concluzie generală

Ambele piese păstrează volumetria generală (proporția corp/acoperiș, poziția scării/turlei), ceea ce arată că geometria de bază a fost citită corect din referință. Dar la ambele apar aceleași două tipuri de eroare sistematică:

1. **Detaliile de fațadă (arcade, ferestre, uși) sunt fie inventate greșit (turnul: bandă dublă de arcade), fie complet omise (casa: ușa lipsește)** — nu sunt variații minore, sunt elemente structurale ale silueții.
2. **Desaturare severă și pierdere de culoare pe elementele secundare** (cupola turnului e gri pur, camera de pe-acoperiș a casei e aproape albă) — sugerează materiale neaplicate sau paletă greșită pe piesele adăugate ulterior corpului principal, nu doar o eroare de iluminare la randare.

Recomandare: nu se livrează niciuna din cele două piese fără o rundă de corecție pe punctele de mai sus, urmată de o nouă comparație măsurată (nu doar verificare vizuală rapidă).
