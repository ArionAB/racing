# Track brief — San Francisco / strada care e rampa (`Track25`, temă `sanfrancisco`) — v0.1

> Concept de pistă, înaintea listei de assets. Scheletul e cel din
> `angkor.md` / `carrara.md`; secțiunile de assets (§5) sunt schițate, nu
> complete — se detaliază după ce traseul trece de ProbeLayout, de ProbeRace
> și de captura `--gamecam` (ordinea din memoria `diorama-din-geometria-reala`:
> traseu → gărzi verzi → captură adnotată → dioramă → foaie de assets → POI).
>
> **Prima pistă pe care strada însăși e rampa.** Pe toate celelalte piste
> săritura e un eveniment: una pe tur, pusă într-un loc (creasta Regelui
> Lepros, scena Kiyomizu, podul din Okinawa). Aici e **un lanț**: o stradă care
> coboară dealul în trepte — bloc abrupt, intersecție plată, bloc abrupt — și
> fiecare intersecție e o muchie de pe care zbori. Patru sărituri la rând, cu
> golful în față. Nicio clasă nouă de hazard nu ține pista în picioare:
> geometria o ține, și e **deja măsurată** (§7 pasul 1a, sonda din PR-ul ăsta).
>
> **v0.1 (10 nov 2026), alegerea dezvoltatorului** dintre trei propuneri (San
> Francisco / Wadi Rum → Petra / Islanda), după inventarul celor 15 piste și al
> celor ~60 de scripturi de hazard. Golurile pe care le umple:
> 1. **verbele de fun ca semnătură** — testul din CLAUDE.md e „drift + o
>    săritură + bumping”, dar semnătura aproape fiecărei piste e un ceas pe
>    care îl citești (lava, mareea, haboobul, autocarul, torentul, amurgul);
>    nicio pistă nu face din airtime identitatea ei;
> 2. **geografia** — Asia 8 piste, Europa 3, restul continentelor câte una;
>    cele trei orașe (Chongqing, Jodhpur, Kyoto) sunt toate asiatice. Aici: a
>    doua pistă din America de Nord și primul oraș occidental.
>
> Trei decizii luate la cerere, pe variante puse pe masă:
> 1. **Atmosfera: oră aurie, fără ceață** (aleasă peste „amiază de carte
>    poștală” și „ceață de dimineață care se ridică”; varianta propusă, cu un
>    front de ceață care intră pe sub pod, a fost acceptată **fără ceață**).
>    Deci: nicio vreme, niciun `FogCorridorHazard`, niciun zid care vine. Vezi
>    §4 pentru ce înseamnă „fără ceață” tehnic (pâcla de distanță a temei
>    rămâne — fără ea nu există fundal).
> 2. **Scurtătura: strada cu serpentine** (aleasă peste „scara dintre case” și
>    „magazia de pe chei”): drumul principal ocolește blocul pe bulevard,
>    scurtătura coboară pe ace de păr de cărămidă; **tramvaiul cu cablu trece
>    prin gura ei**, jos.
> 3. **Livrabilul de acum: brief-ul + testul de cutii gri al lanțului de
>    sărituri** (strada sintetică, sonda, și un lansator ca s-o poți conduce).
>
> Petra rămâne candidata pentru **canionul-culoar + viitura care te urmărește**,
> Islanda pentru **hazardul care te ajută** (gheizerul care te aruncă peste un
> cot de râu). Nu se exclud.
>
> **Trei lucruri din propunerea inițială s-au dovedit false la citirea
> codului**, și brief-ul le tratează ca atare (§3, §8): (1) **traficul din
> Jodhpur nu e refolosibil ca atare** — banda (stânga), viteza și mașina
> (`CAR_DATA_TUKTUK`) sunt constante în cod; (2) **`TRAIN_ALONG` nu e un
> tramvai** — vine din față și e letal pe ax; (3) **„fără ceață” nu poate fi
> literal** — `FAR_PLANE` e 380 m și inelele de fundal trebuie să stea sub
> `fog_end`.

## 0. Într-o propoziție

După-amiază târzie, cu soarele jos și cald în spate: pornești pe **faleza de
est**, printre palmieri, cu **turnul cu ceas** drept înainte; cotești la
dreapta și urci **strada tramvaiului**, o râpă de case pastel cu benzi de soare
la fiecare intersecție, depășind **tramvaiul cu cablu** care urcă pe mijloc cu
clopoțelul lui; sus, pe coamă, ocolești parcul cu **șirul de case pictate** și
chiparoși; apoi strada se rupe sub tine: **patru intersecții la rând, fiecare
o muchie**, cu **podul roșu în stânga** și **golful cu insula cu far
deschizându-se în ax pe măsură ce cobori** — zbori, aterizezi pe bloc, te
strângi pe plat, zbori iar; jos, pe terasă, alegi:
**bulevardul lat pe după colț** sau **strada cu serpentine de cărămidă**,
printre hortensii, cu tramvaiul trecând prin gura ei; ieși pe **cheiul de
nord**, pe scândurile pontonului, pe lângă **leii de mare** care latră de pe
plute, și te întorci pe faleză spre turn. Singura pistă din joc pe care **nu
sari o dată, sari în lanț**.

## 0.1 Regula de artă (ce NU e pista asta)

**Nu Jodhpur (var albastru + fort roșu + noapte care vine), nu Chongqing (beton
rece, noapte, ceață), nu Kyoto (lemn lăcuit + arțari), nu Okinawa / Ha Long
(mare tropicală turcoaz). Un oraș american pe dealuri, la malul unui golf
rece: case victoriene de lemn în culori pastel, cu bovindouri, coborând dealul
în trepte; asfalt închis cu zebre albe; cărămidă roșie pe strada cu serpentine;
un pod roșu-portocaliu pe apă albastru-închis; dealuri uscate, aurii, dincolo
de golf; lumină caldă, joasă, cu umbre lungi.** Ce trebuie să recunoască
jucătorul în 3 secunde: *„case pastel în trepte, strada care cade, golful jos,
podul roșu.”* Silueta **acoperișurilor în trepte** e pentru San Francisco ce
sunt turnurile-boboc pentru Angkor: se vede de pe orice stradă în pantă.

| pondere | strat |
|---|---|
| **35%** | casele: rânduri lipite, 2–3 niveluri (garaj la stradă + două etaje), **bovindou pe fiecare**, cornișă, scări la intrare; cinci pasteluri (crem, roz, mentă, albastru-pal, galben-unt) cu **ancadramente albe**; fiecare casă pe **soclul ei în pană**, deci acoperișurile coboară în trepte odată cu strada |
| **25%** | strada: asfalt închis (cea mai întunecată suprafață continuă — regula din `style_bible.md`), **zebre albe la fiecare muchie**, șinele tramvaiului încastrate, trotuare, mașini parcate **perpendicular** pe panta abruptă (cum se parchează acolo pe străzile abrupte), stâlpi și fire |
| **20%** | apa și cerul: golf albastru-închis, rece (`SEA_DEEP`, nu turcoaz), cer senin cu gradient cald spre soare; insula cu far, vele albe, un feribot |
| **10%** | verdele și auriul: chiparoși de Monterey bătuți de vânt, palmieri de Canare pe faleză, hortensii roz-albastre pe serpentine, **dealurile uscate aurii** de dincolo de golf |
| **10%** | accentele: **roșul podului**, roșul-vișiniu al tramvaiului, cărămida, semafoarele atârnate peste intersecții, papagalii verzi |

Patru acte pe un tur, **aceeași paletă, altă proporție**: faleza (apă + palmieri
+ lemn), urcarea (case + umbră + benzi de soare), coama și coborârea (case +
cer + golf), cheiul (lemn + apă + lei de mare). **Lumina face casele**: fațada
la soare e pastel cald, cea în umbră e albastru-gri, iar bovindourile aruncă
umbre proprii — fără contrastul ăsta, pastelurile sunt cutii plate (memoriile
`geometria-fara-lumina-e-invizibila`, `contrastul-nu-geometria`).

## 1. Referința reală (ce luăm din fiecare loc)

Orașul real are ~11 × 11 km. Pista e o **dioramă de San Francisco**: șapte
locuri strânse pe ~2,2 km, în ordinea în care le leagă o plimbare reală de la
faleză peste deal și înapoi. Aceeași regulă ca la Angkor și Carrara.

| loc real | ce luăm |
|---|---|
| **Străzile de pe Russian Hill și Nob Hill**: grilă dreaptă trasă peste dealuri fără să le ocolească; blocuri cu pantă de 17–31% (Filbert și 22nd St: 31,5%), **intersecții plate** fiindcă strada transversală e orizontală | **POI D, semnătura**: lanțul de muchii. Panta reală e chiar cea care a ieșit din sondă (28%, §7 pasul 1a) — nu e exagerare de joc |
| **Hyde St spre nord**: coboară spre golf cu Alcatraz în ax și linia de tramvai pe ea; jos, placa turnantă de la Hyde & Beach | **direcția și priveliștea lui D**: insula cu far în față, podul în stânga; placa turnantă ca reper la capătul liniei (E) |
| **Strada Lombard, blocul cu serpentine** (1922): opt ace de păr pe ~180 m, cărămidă roșie, hortensii, pantă naturală de 27% îndulcită la 16%, sens unic în jos | **scurtătura** (E′): **trei ace din cele opt** (regula uriașilor de la Angkor: proporția, nu numărul), cărămidă, straturi de hortensii în interiorul virajelor |
| **Tramvaiele cu cablu** (1873): vagon deschis de lemn, ~15 km/h constant, clopoțel, călători pe scări; cablul merge într-un canal dintre șine | **două roluri**: corp lent și greu **pe bandă, în sensul cursei**, pe urcare (B); **trecere prin gura scurtăturii** (E′). Zumzetul cablului în canal e sunetul străzii |
| **„Doamnele pictate”** de la Alamo Square (1892–96): șir de case victoriene pe latura de est a parcului, cu fața spre vest, cu orașul în spate — fotografia se face după-amiaza | **POI C, respiroul**: șirul luminat frontal, văzut **din față**, peste parc (memoria `masoara-inainte-nu-langa`: drumul vine spre șir, nu pe lângă el) |
| **Fisherman's Wharf și leii de mare** (pe plute din 1989–90): debarcadere de lemn, magazii de chei, bărci de pescuit, capcane de crabi | **POI F**: carosabil de scândură, stâlpi de amarare cu goluri, plutele cu lei de mare ca teatru, lăzi și capcane de crabi care se împing |
| **Embarcadero și Ferry Building** (1898): bulevard de faleză cu palmieri de Canare și șine de tramvai; turnul cu ceas de 75 m | **POI A / G, startul și finalul**: grila cu turnul în ax; turnul la scara camerei (§2.0) |
| **Podul Golden Gate** (1937): turnuri de 227 m, culoarea „International Orange” | **reperul de fundal**, la nord-vest, pe inelul de orizont — se vede de pe coamă și de pe coborâre |
| **Alcatraz**: insulă stâncoasă la ~2 km de țărm, cu far | **reperul din ax al coborârii**, strâns la ~80 m de țărm (§2.0: adâncimea se citește prin proximitate) |
| **Poarta Dragonului** (1970) și felinarele din Chinatown | **punctuația urcării** (B): poarta pe o stradă laterală, șiruri de felinare peste stradă — teatru, în afara benzii |
| **Papagalii sălbatici de pe Telegraph Hill**, pescărușii, dealurile aurii din Marin | teatru și fundal |

Culorile locului: **pasteluri de lemn vopsit** cu ancadramente albe, **asfalt
închis** cu marcaje albe și galbene, **roșu-cărămiziu** pe serpentine,
**roșu-portocaliu** de pod, **vișiniu și crem** de tramvai, **albastru-închis
rece** de golf, **auriu-pai** de deal uscat, **verde-închis** de chiparos,
**roz și albastru** de hortensie. Lumina: caldă, joasă, cu umbre lungi (§4).

## 2.0 Verificarea cu camera

`ChaseCamera`: **10 m sus, 12,5 m în spate, 28,7° în jos, FOV 68°**. La distanța
`d` vezi în sus cel mult `10 + 0,093·d` m peste cota drumului; în jos, până la
63°.

- **Casele sunt la scara camerei.** O casă de 3 niveluri are 10–11 m: intră
  întreagă în cadru de la 0–10 m. Tot ce dă identitate (bovindou, cornișă,
  scara de la intrare, culoarea) stă **sub plafon** — spre deosebire de
  Chongqing, unde turnurile de lângă drum erau invizibile. Regula: **nimic peste
  4 niveluri lângă drum**; zgârie-norii există doar ca siluetă pe inelul de
  fundal, la 150–250 m.
- **De pe muchie vezi tot lanțul.** Cu blocul ales (§7 pasul 1a: 48 m de
  profil + 24 m de intersecție, 9,6 m cădere), muchia următoare e la 72 m și
  9,6 m mai jos, adică la **7,6° sub orizontală**; a patra, la 216 m și 28,8 m
  mai jos, tot la 7,6°. Toate în conul camerei (de la +5° la −63°). **Nu e
  creastă oarbă**: de pe prima muchie se văd celelalte trei. Zebra de pe
  fiecare muchie și semaforul atârnat deasupra ei sunt telegraful.
- **Singura creastă oarbă e sosirea pe coamă** (C): urci și nu vezi ce e
  dincolo. De aceea prima muchie vine **după** ocolul parcului, cu ≥ 70 m de
  elan drept, nu direct din urcare.
- **Golful se dezvăluie pe parcurs, nu dintr-odată — și asta e o limită, nu
  o alegere.** De pe prima muchie până la apă sunt ~355 m (4 × 72 m de lanț +
  ~65 m de bloc al serpentinelor), adică **la marginea lui `fog_end`** (~360,
  §4; `FAR_PLANE` e 380). De pe a doua muchie apa e la ~285 m, de pe a treia la
  ~210 m. O insulă la 2 km ar fi dincolo de planul îndepărtat; **insula stă la
  ~80 m de țărm** și intră limpede în cadru de pe a treia muchie (~290 m). Deci:
  prima muchie arată **lanțul, acoperișurile în trepte și podul** (pe inelul de
  fundal, la ≤ 300 m de coamă); a doua, apa; a treia, insula. E dezvăluirea
  prin traseu din `world_design.md`, doar că pe coborâre. Două pârghii dacă
  prima muchie iese săracă în captura `--gamecam`: blocul serpentinelor fără
  clădiri înalte (grădini, deci nimic nu astupă axul) și **strâmtoarea cu podul
  trasă pe flancul de vest al dealului**, ca apa să fie la ≤ 250 m în
  stânga-față de pe coamă.
- **Podul la cota ochiului de pe coamă.** Coama e la ~+53, camera la +63; la
  300 m vede până la +91. Un turn de pod de **45 m** (real 227) cu tablierul la
  +18 stă întreg sub marginea de sus a cadrului și iese peste linia apei. De pe
  chei (+3) îi vezi tablierul și jumătatea de jos a turnurilor — corect: podul
  e al coamei, nu al falezei. Azimutul se **măsoară** după traseu (memoria
  `reperul-se-vede-pe-patru-axe`).
- **Turnul cu ceas trebuie să încapă de pe grilă**: ≤ **32 m**, cu grila la
  ≥ 240 m de el (`10 + 0,093·240 ≈ 32`) — exact cifra turnului central de la
  Angkor.
- **În zbor** mașina urcă la 1,9 m peste drum (4,0 m cu turbo, măsurat). De
  văzut la turul de feel dacă urmărirea camerei pe verticală ține orizontul
  liniștit; dacă nu, se reglează camera, nu săritura.

## 2. Traseul și punctele de interes (POI)

Lungime țintă **~2,2 km** (tur ~70–76 s, 3 tururi ≈ 3:40 — fereastra Ignition
65–80 s). Sens: **orar**, cu dealul în interiorul buclei; golful la nord și la
est. Cote: faleza și cheiul **+3** (apa la 0), urcarea **+3 → +53**, coama
**+53**, lanțul **+53 → +14,6** (4 × 9,6 m), terasa **+14,6**, scurtătura și
bulevardul **+14,6 → +3**.

**Bugetul de înălțime decide forma.** 50 m de urcat la ≤ 11,5% (plafonul de
proiectare e 13%, măsurat cu ProbeLayout) înseamnă **~435 m de rampă**. De aceea
blocul ales e cel de 48 m (9,6 m cădere), nu cel de 60 m (13 m): patru blocuri
de 60 m ar fi cerut 52 + 12 = 64 m de deal și ~560 m de urcare. Lecția Angkor (Bakheng
coborât de la +38 la +31) aplicată înainte, nu după.

```
            N  (golful; insula cu far în ax, podul la NV)
   ┌──────────── [F] cheiul de nord: ponton, lei de mare (+3) ──────────┐
   │   ↑ tramvaiul trece prin gura scurtăturii                          │
   │  [E′] SCURTĂTURA: serpentine de cărămidă      [E] bulevardul       │
   │        (+14,6 → +3)                               pe după colț     ↓
   │  ───── terasa (+14,6) ─────                                   [G] faleza de est:
   │  [D] LANȚUL: 4 muchii, spre nord (+53 → +14,6)                     palmieri (+3)
   │   ↑                                                                ↓
   │  [C] coama: parcul, casele pictate, chiparoșii (+53)          [A] START, turnul
   │   ↑                                                                cu ceas în ax
   └─ [B] urcarea: strada tramvaiului, felinarele (+3 → +53) ←──────────┘
```

| # | frac | POI | ce se întâmplă | lățime |
|---|---|---|---|---|
| **A** | 0.00–0.10 | **Faleza de est** — grila pe bulevardul de faleză, spre sud: palmieri de Canare pe ambele părți, șine de tramvai încastrate (decor), golful pe stânga cu un pod gri de oțel în fundal; drept înainte, **turnul cu ceas** | spectacol + dreaptă de îmbrânceală la start. Apoi virajul de 90° la dreapta, pe strada tramvaiului | 14 m |
| **B** | 0.10–0.32 | **Urcarea** — spre vest, ~290 m la ~11,5%, între case lipite: stradă în umbră cu **benzi de soare la fiecare intersecție** (soarele intră pe străzile transversale); **tramvaiul cu cablu urcă pe mijloc**, în sensul cursei, la ~4,5 m/s — îl depășești pe stânga sau pe dreapta; șiruri de **felinare** peste stradă și **Poarta Dragonului** pe o laterală; viraj la dreapta și încă ~145 m de urcare spre nord | **corp pe bandă**: tramvaiul desparte plutonul în două. Urcarea e la pantă constantă: intersecțiile sunt **pictate, nu aplatizate** (o trecere 11% → 0% → 11% la viteză de cursă ar lansa mașinile în urcare — precedentul Machu Picchu, `machu_picchu_stare_poi.md`) | 14 m |
| **C** | 0.32–0.42 | **Coama** — ieși din urcare în lumină: parcul cu chiparoși, drumul îl ocolește venind **spre șirul de case pictate** (luminate frontal, cu orașul în spate), apoi virează la stânga, spre nord, de-a lungul lor; papagali verzi care se ridică din chiparoși; ≥ 70 m de elan drept | **respiro și vârful vizual**; niciun hazard. Elanul drept e contract: sub 28 m/s la prima muchie, primul zbor scade la 0,46 s (măsurat) | 14 m |
| **D** | 0.42–0.57 | **Lanțul** — strada cade spre golf: **patru intersecții plate, fiecare o muchie**, cu zebră albă pe muchie și semafor atârnat deasupra; între ele, blocuri de 28% cu mașini parcate perpendicular pe ambele părți și case în trepte; **insula cu far în ax, podul roșu în stânga-față**. Zbori ~0,63 s și ~21 m de pe fiecare; cu turbo, 0,82 s și 36 m | **semnătura pistei.** Geometrie pură, zero cod (§3). Fără hazard mobil și fără trafic pe lanț: aterizarea pe un corp pe care nu-l puteai vedea din aer e taxă, nu mecanică | 14 m |
| **E** | 0.57–0.72 | **Terasa și bulevardul** — la capătul lanțului, pe terasă, **bifurcația**: drumul principal cotește la stânga și ocolește blocul pe un bulevard lat (trei viraje de 90°, ~270 m, +14,6 → +3), cu **placa turnantă** a tramvaiului la colț și tramvaiul plecând de pe ea **pe bandă**, spre est | linie și viteză; tramvaiul de pe cheu e același care trece prin gura scurtăturii (un vehicul, două roluri) | 14 m |
| **E′** | ramură | **Strada cu serpentine** — drept înainte din terasă: **trei ace de păr** pe cărămidă roșie, ~115 m de drum pe ~65 m în linie dreaptă, straturi de **hortensii** în interiorul virajelor (moi: le tai, dar te încetinesc), borduri joase de cărămidă; jos, gura ei dă în strada tramvaiului | **scurtătura** — detaliu mai jos | 7 m |
| **F** | 0.72–0.86 | **Cheiul de nord** — spre est: carosabilul iese **pe pontonul de scândură** (stâlpi de amarare pe marginea dinspre apă, **cu goluri**), pe lângă magaziile de chei și **plutele cu lei de mare**; lăzi, capcane de crabi și conuri pe margine | **îmbrânceală + parapetul ca punctuație** (`04_coasta.md`): golurile sunt singurele locuri unde cazi în golf. `RespawnZone` pe apă; cădere ≈ 2 s ≈ 2 poziții. `BumpProp` pe lăzi | 12 m |
| **G** | 0.86–1.00 | **Înapoi pe faleză** — colțul de nord-est, apoi spre sud printre palmieri: un cot scurt în jurul unei piațete cu un tramvai vechi parcat, apoi **sprintul final spre turn** | reperul revenit; latura de est (~690 m în total cu A) se sparge în trei gesturi ca să nu fie o dreaptă de 20 s | 14 m |

### Scurtătura: strada cu serpentine (E′)

**Intrarea** e drept înainte din terasă, printr-un gang dintre două case cu un
indicator de viraje (fără text). **Trei ace de păr** la rază de ax ~8 m,
carosabil de 7 m (`branch_half_width` 3,5), benzile la ≥ 16 m una de alta
(regula `≥ 2 × half_width`, memoria `dunele-hairpin-pileup`; virajele desenate
cu 3–4 puncte pe arc, memoria `viraje-stranse-puncte-pe-arc`). Cade 11,6 m pe
~115 m de drum, adică ~10%.

**De ce plătește.** Bulevardul are ~270 m cu trei viraje de 90° (≈ 10,5–11 s);
serpentinele, conduse în drift, ≈ 9 s. Țintă: **−1,5 s curată, +1 s cu o
bordură atinsă**. Și plătește a doua oară: driftul încarcă bara de 2,5 ori mai
repede (`turbo_drift_multiplier`), deci **ieși din serpentine cu bara plină
chiar dacă ai ars-o pe lanț**. E decizia de turbo a pistei (principiul 2):
*ard turbo pe lanț pentru zboruri mai lungi și o refac în serpentine, sau o țin
și iau bulevardul plin?* Cifrele se măsoară pe o stradă sintetică înaintea
traseului (§7 pasul 1b) — sunt estimări, nu măsurători.

**Hortensiile** sunt straturile din interiorul fiecărui ac: fără coliziune,
`speed_factor` de iarbă (45%), cu petale care zboară (`SoftVegetation` +
`PropDebris`). Tai virajul prin ele și pierzi mai mult decât câștigi — dar
arată bine când o faci.

**Hazardul: tramvaiul din gură.** Tramvaiul pleacă de pe placa turnantă și
merge spre est pe strada de jos, **prin fața gurii scurtăturii**, la ~4,5 m/s;
ocupă gura ~3 s dintr-un ciclu de **29 s**. Telegraful e **înălțimea**: din
primul ac te uiți în jos și îl vezi venind de-a lungul străzii (tiparul
belvederii de la Ha Long), plus clopoțelul. Ieși în el = corp greu, ghiont și
~2 s pierdute (`soft_contact`, fără ejectare); îl citești = ieși în spatele lui
și îl depășești pe cheu.

**AI onest.** AI-ul ia scurtătura cu `SHORTCUT_CHANCE` 0,4 și vede tramvaiul ca
pe orice corp cu `ai_reads_lane`. Dacă ProbeRace arată AI-ul lovind tramvaiul în
gură în > 30% din treceri, tramvaiul intră în grupul `branch_gate`
(`shortcut_open()`, citit de `Track.branch_is_open` — vaca din Jodhpur, lava din
Stromboli): AI-ul nu intră când gura va fi ocupată, pe aceeași informație pe
care o are jucătorul (poziția vizibilă, nu faza). Altfel nu se scrie nimic.

### Ceasuri care nu împart durata turului (lecția Stromboli)

Tramvaiul de pe urcare **41 s**, cel de pe cheu **29 s**. Niciunul nu e
multiplu de ~73. Fazele de start se aleg astfel încât plutonul să nu dea peste
tramvai în primul viraj al turului 1 (memoria `ceasul-porneste-in-prima-faza`).

**Ritmul turului:** faleză (start, îmbrânceală) → urcare (tramvaiul, benzile de
soare) → coamă (respiro, casele pictate) → **lanț (patru zboruri)** → terasă
(decizia) → serpentine sau bulevard → chei (scânduri, apă, lei de mare) →
faleză (sprint).

## 3. Hazarduri și mecanici (ce e nou pentru motor)

Acoperirea claselor din `ref_notes/sisteme.md` §3:

| clasă (Ignition) | aici |
|---|---|
| teatru | leii de mare, papagalii, pescărușii, clopoțelul și zumzetul cablului, felinarele, velele de pe golf, aburul din capacele de canal |
| frecare | hortensiile din serpentine |
| oprire | **nu** (trenul e al Transfăgărășanului) |
| sabotaj de control | **nu** |
| **aruncare** | **lanțul de muchii** (4 pe tur), căderea în golf de pe ponton |
| **poartă de timing** | tramvaiul din gura scurtăturii |
| **corp pe bandă** | tramvaiul de pe urcare; mașinile parcate și lăzile (le arunci tu) |
| starea lumii | **nu** (deliberat: după muson, amurg, haboob și maree, lumea asta stă pe loc și te lasă să conduci) |

| mecanică | pe scurt | ce cere în cod |
|---|---|---|
| **Lanțul de muchii** (D) | patru blocuri: muchie, 28% pe 24 m, racord 17% → 7%, intersecție plată de 24 m | **zero cod** — geometrie de traseu, cu ferestrele declarate în `metadata/jump_crests` (excepția numită a ProbeLayout, ca la Angkor). **Contract măsurat** (§7 pasul 1a): airtime 0,58–0,70 s la plafon pentru toate cele 10 mașini, 0,77–0,85 s cu turbo; aterizare pe bloc, niciodată pe intersecție; **0 incidente în ~1.400 de zboruri** solo și în 1.020 în pluton. Profilul **nu** se schimbă fără sondă: forma lui, nu căderea, decide dacă aterizarea e sigură |
| **Mașinile parcate** (D, B) | parcate perpendicular pe trotuar; aterizezi strâmb, intri în ele | **reuse** `BumpProp` (masă per piesă) + `PropDebris`. **Zero cod.** Masa aleasă ca Autobuzul să le arunce și Poliția să ricoșeze. **Niciuna pe carosabil și niciuna în zona de aterizare** (primii 45 m după muchie rămân liberi pe toată lățimea) |
| **Tramvaiul de pe urcare** (B) | vagon greu, ~4,5 m/s, pe șinele din mijloc, **în sensul cursei**; ciclu 41 s | **reuse** `BusHazard` pe `Path3D`, cu `soft_contact` + `ai_reads_lane` (camioanele din Carrara, validate cu AI-ul). **Nu** `TRAIN_ALONG` (vine din față, letal pe ax, max 110 m de dreaptă). De verificat **în sensul cursei** la pasul 1c: Carrara le-a măsurat în sens invers. Model nou `cable_car.glb`, un singur corp |
| **Tramvaiul din gură** (E, E′) | același tip de vagon, pe strada de jos, trece prin fața gurii scurtăturii; ciclu 29 s | **reuse** `BusHazard` (al doilea nod); eventual grupul `branch_gate` (decis de ProbeRace). **Nu** `TrainHazard`: are viteza și timpii constante (26 m/s), cere trei noduri de tren în model, iar AI-ul nu îl citește deloc |
| **Serpentinele** (E′) | §2 | `TrackBranch` pe ruta cu indexul 1 + suprafață de cărămidă (`road_tint` / suprafața ramurii) + `SoftVegetation` pe hortensii. **Zero cod**, dacă sonda 1b confirmă că AI-ul le trece |
| **Pontonul** (F) | carosabil de scândură, stâlpi cu goluri, apă | **reuse** `RespawnZone` pe golf, plasa de mare **sub** cota apei (memoria `ziduri-invizibile-ale-lumii`); scândura e clasă de textură pe carosabil, nu punte fizică (pontonul care se leagănă e semnătura Ha Long-ului) |
| **Leii de mare, papagalii, pescărușii** | teatru | **reuse** `FlockProp`; leii de mare sunt statici pe plute (lătrat pe sunet), **nu traversează** — traversarea de animale e a Serengeti-ului, a Ha Long-ului și a Transfăgărășanului |
| **Zebra și semaforul de pe muchie** (D) | telegraful fiecărei sărituri | decal pe carosabil + GLB atârnat; fără coliziune la înălțimea mașinii în zbor (**semaforul stă la ≥ 8 m peste muchie**: zborul cu turbo urcă la 4,0 m peste drum) |

Calibrare (sisteme.md): tramvai lovit ≈ +1,5–2 s; serpentine curate ≈ −1,5 s,
cu bordură ≈ +1 s; cădere în golf ≈ 2 s ≈ 2 poziții; mașină parcată ≈ +0,3 s;
lanțul ≈ 0 s (e plăcere, nu taxă).

**Regula „AI onest”:** AI-ul vede aceleași corpuri ca jucătorul (tramvaiele prin
`ai_reads_lane`), fără informație despre fază. Pe lanț nu primește nimic în
plus: n-are control în aer (`air_pitch_rate` e doar al jucătorului) și tot
aterizează — măsurat, §7.

## 4. Paleta și lumina (fără slot nou)

**Regula: niciun slot nou** (toate cele 32 sunt luate; lista reală e în
`scripts/palette.gd`, tabelul din `style_bible.md` e depășit de la slotul 24
încolo). Identitatea vine din **clase de pastel pe o singură dală de lemn** și
din lumină.

- **Casele**: baza pe `CORAL_SAND` 19 / `FOAM_WHITE` 22, cu **o clasă nouă de
  scândură orizontală `sf_clapboard`** (dungile de scândură sunt detaliul care
  ține pastelul să nu fie plat — memoria `muchii-de-forma-nu-granulatie`) și
  cinci tente prin `atint:` (o tentă = un material, ca albastrul Jodhpurului):
  crem, **roz** (`FLAMINGO_PINK` 31), **albastru-pal** (familia `PAINTED_METAL`
  11), **mentă** (`ICE_TURQUOISE` 24 tentat — nu există slot de mentă),
  **galben-unt** (`SAND_LIGHT` 0, **nu** `CAR_YELLOW`). Tenta doar întunecă:
  pastelul se obține de la o bază deschisă, nu se „luminează” un slot închis
  (memoria `surfacetool-clamp-vertex-color`). Ancadramente `FOAM_WHITE` 22,
  acoperișuri `VOLCANIC_BLACK` 20, uși de garaj `WOOD_WEATHERED` 9.
- **Strada**: `ASPHALT` 5 / `ASPHALT_EDGE` 6; zebrele și marcajele ca **decal**
  `FOAM_WHITE` (cum a fost rangoli-ul la Jodhpur), șinele ca fâșii
  `PAINTED_METAL`, fără coliziune.
- **Cărămida**: nu există clasă de cărămidă. Clasă nouă `sf_brick` pe textura
  `roof_tiles` (cum a făcut Carrara), tentată spre `TILE_TERRACOTTA` 23 /
  `KERB_RED` 7; pe carosabilul ramurii prin `road_tint`.
- **Podul**: `KERB_RED` 7 (`#BB3522`) — la câteva unități RGB de vopseaua reală
  (`#C0362C`). **Nu** `LAVA_ORANGE` 30, care aduce masca de lavă și iese „ars”
  (memoria `slot-reutilizat-intre-piste`).
- **Tramvaiul**: `KERB_RED` 7 + `CORAL_SAND` 19 + `LOG_DARK` 28; nu culorile
  mașinilor de joc.
- **Apa**: `SEA_DEEP` 18, shaderul de apă v12 — rece și închisă, ca să nu
  citească „Okinawa”.
- **Vegetația și fundalul**: chiparoși pe `TROPICAL_GREEN` 21 umbrit, palmieri
  din reuse, dealurile de dincolo de golf pe `DRY_VEGETATION` 13 cu clasa
  `macchia_dry`.
- **Lumina — abatere asumată de la ora aurie reală.** Soare **cald**
  (`FFD2A0`-ish, energie ~1,25) la **~28°**, nu la 10–15°, și **aliniat cu
  strada lanțului la ±20°, din spate** (deci dinspre sud-sud-vest, lanțul
  coborând spre nord). Motivul e geometric: o casă de 10 m aruncă la 28° o
  umbră de ~19 m; cu soarele la 20° față de axul străzii, doar ~6,5 m din ea
  cad pe carosabil — **lanțul rămâne la soare**. Cu soarele de-a curmezișul, ar
  cădea ~18 m: toată strada în umbră, ca fundul căldării de la Carrara. Ambient
  **rece și mic** (`BCCCE8`-ish, ~0,40; raport soare/ambient ≥ 3 — cifrele
  Carrarei, după corecția de cyan). **Umbre pornite**; pe telefon, profilul
  ieftin (`GameState.SHADOW_DISTANCE_MOBILE`, 55 m) acoperă umbre de 19 m.
- **Urcarea e în umbră, și e bine**: pe axa est–vest casele de pe partea de sud
  umbresc strada. E râpa de umbră care face coama să pară lumină — dar cere
  **benzile de soare** de la intersecții și fațadele de nord luminate, altfel e
  un tunel. Pe cheu și pe faleză, clădirile de pe partea de sud stau la ≥ 20 m
  de drum sau au ≤ 6 m. **Contract** (pasul 0 și pasul 4): ≥ 60% din
  carosabilul turului la soare, **≥ 80% pe lanț**.
- **„Fără ceață”, tehnic.** Nicio ceață ca vreme și niciun hazard de ceață.
  Rămâne **pâcla de distanță a temei**, la maximul folosit până acum
  (`fog_end` ~360, sub `FAR_PLANE` 380), caldă și subțire, în familia solului
  (memoria `ceata-in-familia-solului`). Fără ea, inelele de fundal (podul,
  dealurile, orașul) s-ar tăia la planul îndepărtat: inel < `fog_end` <
  `FAR_PLANE` (memoria `efecte-de-fundal-cote-legate`). **Confirmat de
  dezvoltator (10 nov 2026):** „fără ceață” = fără ceață ca vreme și fără
  hazard de ceață.
- **Azimutul soarelui se remăsoară** după fiecare redesenare de traseu (memoria
  `azimutul-soarelui-fata-de-drum`); umbrele pe siluetele de fundal, stinse
  (memoria `caster-departat-fura-umbra`).

## 5. Assets (schiță — lista completă după ProbeLayout)

### 5.1 Teren și suprafețe (cod, clase de textură)

- asfalt cu zebre, marcaje și șine (decal-uri); urme pe `RoadWear`
- cărămida serpentinelor (`sf_brick`), scândura pontonului (clasă pe `wood`)
- dealul ca relief (`TerrainPeak`), golful ca `custom_lagoon` cu apă la cota 0
- trotuare la aceeași cotă cu carosabilul (un prag > 0,3 m e zid pentru
  suspensie — memoria `suprafete-cu-goluri-si-praguri`)

### 5.2 Hero (unice)

- `cable_car.glb` — vagon deschis de lemn, un singur corp, cu călători pe scări
  (statici); folosit de ambele tramvaie
- `sf_clock_tower.glb` — ≤ 32 m (§2.0), coliziune doar pe soclu
- `sf_turntable.glb` — placa turnantă de la capătul liniei
- `sf_dragon_gate.glb` — pe o stradă laterală, în afara benzii, cu coliziune,
  nu se sparge
- `sf_pier_shed.glb` — magazia de chei cu fronton arcuit
- `sf_painted_row` — de fapt kit (§5.3), dar cele șase case de la parc sunt
  variantele cele mai bogate

### 5.3 Kituri (modulare)

- **casa de rând** — 3 module de fațadă × 2 tipuri de bovindou, colț de
  intersecție cu turnuleț; un nod per material (`House_Wall`, `House_Trim`),
  originea ansamblului la bază, față = −Z în Godot (regulile kitului Jodhpur)
- **soclul în pană** — piesa care face „casele în trepte”: la 28%, o casă de
  7 m lățime coboară **1,96 m** față de vecina ei. Contract de kit: soclul se
  scalează cu panta, casa stă pe fața lui orizontală
- rândul din față (≤ 40 m de drum): noduri `DecorManual` cu coliziune; restul
  prin `CityFill` cu `row_mode` (rândurile lipite ale Kyoto-ului), feliat la
  125 m, `visibility_end_m` 260, `shadow_proxy` — reglajele care au dus Kyoto
  de la 30 la 60 fps pe telefon
- **LOD-uri pe tot ce se reconstruiește din cod** (CLAUDE.md, cele 169 de case
  albastre): `MeshCpu.surface_lods` / `generated_lods`
- mobilier de stradă: **mașini parcate** (3 caroserii, culori stinse), hidrant,
  cutie poștală fără siglă, automate de ziare, coșuri, conuri, stâlpi cu fire
  (puține și groase — firele subțiri sclipesc pe mobil), **semafor atârnat**,
  felinare de hârtie, lăzi și capcane de crabi, stâlpi de amarare

### 5.4 Vegetație

- chiparos de Monterey (coroană plată, aplecată de vânt) — silueta parcului
- palmier de Canare (faleza) — de comparat cu palmierii existenți din reuse
- **hortensii** (roz, albastru) — tufe pentru `SoftVegetation`
- platani de stradă, gazonul parcului

### 5.5 Fundal (`horizon_class`)

- `effects/sf_horizon.glb` — **podul roșu** la nord-vest (turn 45 m), **insula
  cu far** la nord (aproape, ~80 m de țărm), dealurile aurii dincolo de golf,
  un pod gri și un oraș generic de turnuri la est și sud-est

### 5.6 Sunet

Clopoțelul tramvaiului (telegraful gurii), zumzetul cablului în canal (stratul
de fundal al urcării), lătratul leilor de mare, pescăruși, papagali, scârțâitul
scândurilor pe ponton. Bufnitura de aterizare există (`ImpactSound` pe semnalul
`landed`) — pe lanț se va auzi de patru ori pe tur, de verificat că nu obosește.

### 5.7 Trecerea de contracte (pasul 1 din §7, memoria `brief-cere-glb-cod-il-face-deja`)

Înainte de primul GLB, verdict pe consumatorul fiecărei piese din §5.2: (1)
`BusHazard` acceptă un model cu un singur corp și un `model_yaw`? (2) `CityFill`
`row_mode` știe să așeze rânduri **pe pantă**, cu soclu, sau pune casele pe
teren înclinat? — de aici depinde dacă „casele în trepte” e kit sau cod; (3)
suprafața unei ramuri poate primi `road_tint` separat de bucla principală? (4)
`RespawnZone` pe golf vs plasa de mare existentă.

## 6. Bugete

- **triunghiuri**: raportate, fără plafon; `radial_segments` pe orice primitivă
  din cod
- **materiale**: atlas + 5 pasteluri + ancadrament + cărămidă + scândură + apă
  + asfalt/decal-uri + vegetație (3–4) + tramvai + fundal + urme → estimat
  **~27**, plafon de joc **38** (Jodhpur 24, Kyoto 33). Fiecare pastel în plus
  costă un material: **cinci, nu opt**
- **GPU — riscul pistei**: **casele**. Sunt cele mai multe corpuri din cadru și
  toate aruncă umbră. Măsuri: LOD obligatoriu, `CityFill` feliat cu
  `shadow_proxy`, blocuri pline (fațade pe perimetru, fără curți), fundalul
  fără umbre. Se măsoară cu `ProbePerf --attrib`, nu se ghicește
- **riscul vizual**: (1) **„oraș generic”** — antidotul e pastelul + bovindoul +
  treptele; (2) **strada în umbră** (§4); (3) **pastelul plat** — clasa de
  scândură și umbra bovindoului. Toate trei se măsoară la pasul 0
- **riscul de feel**: (1) **incidentele de aterizare** — măsurate, vezi §7;
  rămâne de văzut pe pista reală, cu case, mașini parcate și pluton; (2)
  **sosirea oarbă pe coamă**; (3) **oboseala**: patru sărituri identice pe tur,
  trei tururi — dacă devin rutină, a patra muchie primește blocul lung (zbor
  mai lung cu turbo) sau lanțul scade la trei. Verdictul e al dezvoltatorului,
  la volan
- **de verificat devreme**: (1) lanțul la volan, pe sonda din PR-ul ăsta; (2)
  serpentinele: AI-ul le trece? (sonda 1b); (3) tramvaiul în sensul cursei, pe
  `[blocaj]` (sonda 1c); (4) captura `--gamecam` de pe prima muchie: se văd
  insula și podul, sau pâclă?

## 7. Ordinea de construcție

0. **Testul de loc** (înaintea traseului — aici se decide paleta). O stradă
   sintetică de ~80 m, în pantă, cu șase case în trepte pe clasa `sf_clapboard`
   în cele cinci pasteluri, o muchie cu zebră, o mașină parcată, golful și
   podul în fundal, lumina din §4, camera de joc reală (`--gamecam`). Cinci
   capturi amestecate cu câte 5 din **Jodhpur, Kyoto, Chongqing și Okinawa**, la
   un critic orb: „ce fel de loc e fiecare?” și „care seamănă între ele?”.
   **Contract**: ≥ 3 din 5 citite ca „San Francisco / oraș american pe deal”,
   ≤ 1 din 5 confundată cu altă pistă. Tot acolo: fracția de carosabil la
   soare, ΔV soare/umbră pe fațade ≥ 0,28, pastelurile distincte între ele după
   remap (memoria `monocromia-se-masoara-dupa-remap`). Dacă pică: se intervine
   pe tente și pe soare, **nu** pe loc.

1. **Sondele tehnice** (piste sintetice în `tools/`, nu `Track25`).

   **1a. Lanțul de muchii — FĂCUT (10 nov 2026, PR-ul ăsta).**

   Unelte: `tools/gen_sf_sonda.py` scrie `tools/SondaSf<Profil>.tscn` (o buclă
   `TrackFromPath`: elan plat, N blocuri, întoarcere care urcă înapoi);
   `tools/probe_sf_crest.gd` trece **fiecare mașină din garaj** pe stradă, cu un
   pilot de probă care ține gazul la fund și axa, și măsoară pe fiecare muchie.

   ```
   python tools/gen_sf_sonda.py
   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfCrest.tscn -- \
       --scene=res://tools/SondaSfPlan28s.tscn --modes=14,22,max,t1,t3 --lats=0,-4,4
   godot --path . res://tools/DriveScene.tscn -- --scene=res://tools/SondaSfPlan28s.tscn
   ```

   A treia comandă e **cu fereastră**: conduci tu strada (implicit singur, 5
   ture; `--ai=3`, `--car=N`). Recordurile din salvare nu se ating.

   Zece profiluri, fiecare cu 4 blocuri. Coloanele sunt la plafonul mașinii
   (33,9–34,3 m/s la muchie) și, în paranteză, cu turbo (43–45,5 m/s):

   | profil | bloc / cădere | airtime med [min–max] | zbor | înălțime peste drum | viteză normală la aterizare | incidente / zboruri |
   |---|---|---|---|---|---|---|
   | pantă constantă **20%** | 60 m / 9,2 m | 0,38 [0,33–0,43] (0,63) | 13 m (27) | 0,9 m (1,8) | 6 m/s (9) | 0 / ~600 |
   | pantă constantă **24%** | 60 m / 11,1 m | 0,51 [0,45–0,57] (0,79) | 17 m (34) | 1,4 m (2,7) | 8 (13) | 1 / ~600 |
   | pantă constantă **28%** | 60 m / 13,0 m | 0,63 [0,57–0,70] (0,93) | 21 m (40) | 1,9 m (3,9) | 9 (17) | **1 / ~1.600** |
   | **28% scurt — ALES** | **48 m / 9,6 m** | **0,63 [0,58–0,70] (0,82)** | **21 m (36)** | **1,9 m (4,0)** | **11 (17)** | **0 / ~1.400** |
   | 28% lung | 72 m / 16,4 m | 0,62 (0,95) | 21 m (41) | 1,9 m (3,9) | 9 (13) | 0 / ~800 |
   | pantă constantă **32%** | 60 m / 14,4 m | 0,73 [0,67–0,80] (1,03) | 24 m (44) | 2,4 m (4,9) | 10 (21) | 1 / ~600 |
   | 28% + intersecție de 12 m | 60 m / 13,0 m | 0,68 (0,97) | 23 m (42) | 2,3 m (4,6) | 10 (19) | 2 / ~600 ¹ |
   | 28% + intersecție de 36 m | 60 m / 13,0 m | 0,64 (0,92) | 21 m (39) | 2,1 m (4,0) | 9 (17) | 0 / ~600 |
   | trambulina Angkor ×4 | 60 m / 8,6 m | 0,68 [0,60–0,73] (0,82) | 22 m (34) | 3,2 m (4,9) | 14,5 (18) | **4 / ~600** |
   | trambulina scurtă / abruptă | 48–60 m | 0,68 / 0,77 | 22 / 25 m | 3,1 / 3,3 m | 14,5 | 3 / 2 din ~600 |

   ¹ aceeași trecere (Monster, +4 m lateral), ieșită la fel în două rulări; a
   treia rulare identică n-a reprodus-o. Jolt rulează pe mai multe fire
   (memoria `proberace-nedeterminism`).

   **Ce a ieșit:**

   - **Lanțul funcționează.** Toate cele 10 mașini zboară de pe fiecare muchie,
     din prima până la a patra, la orice abatere laterală încercată (până la
     ±5 m pe un carosabil de ±7).
   - **Panta decide airtime-ul, aproape liniar**: 20% → 0,38 s, 24% → 0,51 s,
     28% → 0,63 s, 32% → 0,73 s. Sub ~24% la viteză de cursă nu mai e zbor, e
     hop. **28% e și panta reală** a străzilor abrupte din oraș.
   - **Forma blocului decide siguranța, nu căderea.** Trambulina Angkor (muchie
     de 37%, apoi pantă care se îndulcește) dă zboruri mai înalte (3,2 m) și
     aterizări mai dure (14,5 m/s pe normală), cu **9 ejectări în ~1.800 de
     zboruri** (0,5%). Blocul de pantă constantă aterizează la 9–11 m/s: **5 în
     ~6.800** pe toată familia, iar la 28% cu intersecții de ≥ 24 m, **1 în
     ~4.400** (0,02%). Cinci incidente urmărite: de fiecare dată mașina a lovit **chiar
     carosabilul** (`RoadTop`), cu viteza orizontală întoarsă într-un singur
     tick (Δv 44–59 m/s), **în porțiunea concavă** a profilului — pe trambulină
     la 24–31 m după muchie, pe blocul de 28% la 39 m (Autobuzul, cu turbo,
     exact unde începe racordul). Tangajul nu e cauza: pe trambulină Autobuzul
     aterizează curent cu botul la −15…−21° față de drum, fără incident. **Regula:
     aterizarea pe plan, racordul după.**
   - **Viteza nu crește de-a lungul lanțului.** Ipoteza de plecare („fiecare
     săritură e mai lungă decât cea dinainte”) e **falsă**: plafonul de viteză
     ține mașina la ~34 m/s la fiecare muchie. Crescendo-ul îl dă doar turbo-ul
     (+11 m/s → zbor de 36 m în loc de 21). Asta e decizia jucătorului, nu a
     pistei — principiul 2.
   - **Lanțul se vindecă singur.** Intrat cu 28 m/s (ieșire slabă din ocolul
     parcului sau repunere), primul zbor e 0,46 s, iar la a doua muchie mașina
     e din nou la plafon.
   - **Masa se vede.** Autobuzul zboară 0,58–0,60 s și aterizează în bot (−7°,
     −18° cu turbo); Buggy-ul, Taxiul și Hot rod-ul, 0,68–0,70 s; Poliția
     aterizează dreaptă (−1°). Identitate fără niciun reglaj.
   - **Intersecția: 24–36 m.** La 12 m, racordul blocului de sus intră în
     muchia următoare și spline-ul face un mic kicker (+5%): zboruri cu 8% mai
     lungi și un incident.
   - **AI-ul îl conduce** fără frână (`--ai`: 120 de zboruri, 0 incidente); la
     a treia muchie ajunge peste plafon (36,9 m/s), deci arde turbo acolo de
     capul lui.
   - **Plutonul.** ProbeRace, 8 mașini × 8 seed-uri × 150 s. Pe blocul ales
     (48 m): **1.020 de zboruri**, airtime mediu 0,55–0,60 s (max 0,73), **0
     repuneri, 0 ejectări, 0 `[blocaj]`**; cea mai dură aterizare 19,6 m/s, față
     de pragul de ejectare de 34. Pe blocul de 60 m: 1.009 zboruri, aceleași
     zerouri (max 0,75 s, 20 m/s). Rezerva e cea din memoria
     `harnas-sintetic-comportament-emergent`: e o buclă de sondă, fără
     scurtătură, tramvai sau viraj înaintea lanțului — verdictul de pluton se
     dă pe pista reală.

   **Decizia dezvoltatorului (10 nov 2026): patru blocuri scurte.** Întrebarea
   „patru sărituri pe bloc de 48 m sau trei pe bloc de 72 m” e închisă; varianta
   cu trei rămâne doar rezerva descrisă mai jos (strada de comparație:
   `tools/SondaSfPlan28lX3.tscn`, nerulată prin sondă în forma cu trei blocuri).

   **De ce blocul scurt**, deși cel lung aterizează turbo-ul pe plan: bugetul
   de înălțime (§2). Patru blocuri scurte cad 38,4 m; patru lungi, 65,6 m. Cu
   turbo, zborul de 35–38 m aterizează pe racordul blocului scurt, la 17 m/s pe
   normală — **0 incidente în 200 de zboruri cu turbo**, dar mecanismul de mai
   sus spune că acolo e locul sensibil. Dacă pista reală arată ejectări la
   aterizarea cu turbo, mutarea validă e **planul mai lung decât zborul cu
   turbo** — blocul de 72 m, deci **trei muchii în loc de patru** (49 m de
   cădere, un deal cu ~11 m mai înalt și ~95 m de urcare în plus) — nu altă
   formă de bloc. Blocul de 60 m **nu** e soluția: zborul cu turbo aterizează
   exact la începutul racordului lui (acolo a fost incidentul Autobuzului).

   **Ce NU spune sonda:** cum se simte. Pilotul de probă nu greșește, strada
   n-are case, mașini parcate sau cameră judecată de un om. Verdictul de feel e
   al dezvoltatorului, cu `DriveScene`.

   **1b. Serpentinele** (de făcut): stradă sintetică cu trei ace la raza 8 și
   carosabil de 7 m, lângă un ocol de 270 m cu trei viraje de 90°. Contract:
   AI-ul trece acele fără `[blocaj]`; trecerea curată câștigă 1–2 s față de
   ocol; cu o bordură atinsă pierde. Precedentul e `SondaCarrara` (ace la raza
   16, lățite până la urmă la 9 m din cauza AI-ului) — **raza 8 e sub tot ce
   s-a măsurat până acum**, deci e primul lucru care poate pica.

   **1c. Tramvaiul în sensul cursei** (de făcut): `BusHazard` pe o dreaptă în
   urcare de 11,5%, 4,5 m/s, pe ax. Contract pe `[blocaj]` și pe coada de AI din
   spatele lui (memoria `franare-de-coada-blocaj-reciproc`), cu sabotaj
   (`ai_reads_lane` stins → trebuie să pice).

2. **Scena**: `Track25.tscn` din `TrackFromPath` prin `tools/gen_sf_route.py`
   (pas de control 12 m, uniform — pasul mixt supraîncarcă spline-ul); tema
   `sanfrancisco` doar cu lumină, cer, pâclă și sol. ProbeLayout: pantă < 13% în
   afara ferestrelor `jump_crests`, rază > half_width, benzi paralele la
   ≥ 2 × half_width, bucla la < 420 m de centroid. `Track25` în
   `GameState.TRACK_SCENES` / `TRACK_NAMES` (indexul 17; `--track=17` sau `25`
   la snapshot / probe_race / probe_layout, **doar 25** la probe_decor /
   probe_manual) și în `EXCLUDED` din `tools/probe_world_cup.gd`.
3. **ProbeRace devreme** (memoria `proberace-la-inceput-nu-la-final`): 8 mașini
   × 16 seed-uri; se citesc `[blocaj]`, lent și invers, nu doar repunerile.
4. **Turul de feel, capturile `--gamecam`, tabelul de frustum**; apoi planul de
   sus adnotat, dioramă, foaia de assets.
5. Tramvaiele, cu A/B pe ProbeRace. 6. Serpentinele, pontonul, mașinile
   parcate. 7. Hero. 8. Kituri, fundal, teatru, sunet; `probe_decor`; testul de
   citire final; **verdictul dezvoltatorului la volan**.

## 8. Lecții aplicate anticipat, și ce a fost respins

- **Săritura s-a măsurat înaintea traseului**, nu după decor: profilul blocului
  e ales din zece, pe ~10.000 de zboruri măsurate, înainte să existe un metru
  de pistă.
- **Bugetul de înălțime înaintea formei** (Angkor a coborât Bakheng după ce
  traseul ieșise 2,8 km).
- **Frustumul decide înălțimile**: case ≤ 4 niveluri, turnul 32 m, podul 45 m.
- **Hazarduri distincte mecanic**: lanț de sărituri (nou ca idee, zero cod),
  corp lent în sensul cursei, poartă de timing la gura unei ramuri. Nimic nu
  dublează trenul, avalanșa, vârtejul, mareea sau pontonul.
- **Respins, cu motiv:**
  - **ceața** (frontul care intră pe sub pod, sirena de ceață) — decizia
    dezvoltatorului; ar fi fost și a treia vreme-care-vine după haboob și
    muson;
  - **traficul pe sens** — e semnătura Jodhpurului, iar în cod e legat de el
    (bandă pe stânga, 14 m/s, `CAR_DATA_TUKTUK`); refolosirea cere bandă,
    viteză și `CarData` per pistă, plus o rundă de măsurători. Orașul „plin de
    mașini” se obține din **mașinile parcate**, care nu costă cod. Rămâne
    decizie deschisă pentru v0.2, implicit **nu**;
  - **`TRAIN_ALONG` și `TrainHazard` pentru tramvai** — vezi §3;
  - **scurtătura pe scări** (treptele dintre case) — o treaptă peste 0,3 m e
    zid pentru suspensie; ar fi fost scări false, ca la Machu Picchu;
  - **cele opt ace reale** — trei; opt ar fi cerut ~300 m de ramură și un ocol
    de peste 400 m;
  - **cutremurul** (strada care crapă) — dezastru real al orașului; nu e decor;
  - **noaptea cu neon** — Chongqing e noapte, Jodhpur e amurg;
  - **fuga pe insulă** — insula e siluetă cu far, nu loc de condus;
  - **trecerea de lei de mare / pietoni** — traversările sunt ale altor piste;
    aici nimic viu nu intră pe bandă.
- **Respect pentru loc:** fără sărăcie ca decor (fără corturi, fără oameni ai
  străzii); Chinatown înseamnă poartă și felinare, **fără temple și fără text
  lizibil**; fără steaguri.
- **Nume și legal** (nu e aviz juridic — de verificat înaintea listing-ului):
  „San Francisco” e toponim; în UI apare doar el. **Nicio referință la filme**
  (urmărirea celebră pe străzile astea nu se citează: fără mașina verde, fără
  nume). **Fără mărci și fără livrea reală**: tramvaiul n-are numele liniei sau
  al operatorului, magaziile și debarcaderele n-au firme, cutia poștală n-are
  siglă. **Zgârie-norul-piramidă nu apare ca reper** (silueta lui e marcă a
  companiei) — fundalul e un oraș generic. Podul e monument public și apare ca
  fundal; **nu** intră în iconiță sau în grafica de magazin până nu se verifică.
  Semnele și plăcuțele de stradă sunt fără text.
- **Cariera (modul de joc):** pista intră în `CareerConfig` doar prin decizia
  dezvoltatorului; până atunci, ca Ha Long, Carrara și Angkor, **doar cursă
  rapidă**.

## 9. Prompt pentru ChatGPT (dioramă de referință)

Se scrie la pasul 4, **după** ce există `Track25` și captura reală de sus
adnotată (memoria `diorama-din-geometria-reala`: referința e geometria din joc,
nu un plan schematic). Până atunci, schema din §2 e doar ordinea locurilor.
