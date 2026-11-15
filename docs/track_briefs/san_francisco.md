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

> **Traseul de acum: bucla B200, construită în jurul podului roșu (decizia dezvoltatorului
> din 15 nov 2026, §7 pasul 2b).** Planul: `docs/asset_briefs/img/sf_route/sf_route_plan.png`.
> Tot ce urmează după acest chenar (schema, tabelul POI, cotele faleză/cheu) descrie **bucla
> veche** (pașii 2–5). Lanțul, scurtătura, ocolul, tramvaiul 2 și cheiul de nord au rămas în
> aceleași coordonate. Latura de est (faleza A/G) și turnul cu ceas din axul ei au dispărut.
>
> ```
>             N  (golful)
>   ┌── [F] cheiul de nord (+3) ──────────┐
>   │ [E′] serpentine   [E] ocolul 400 m   │ [G] strada de întors spre pod (+3 → +20)
>   │ ── terasa / furca (+14,6) ──         ↓
>   │ [D] LANȚUL, 4 muchii, spre N         └→ ═══ PODUL ROȘU, +20, tablier 200 m ═══ ⟳ balonul
>   │  ↑                                   ┌← ═══ START / SOSIRE pe banda spre oraș ═══   (malul
>   │ [C] coama (+53): brațul de 84 m spre V ↓ primul viraj (R30)                       celălalt)
>   │  ↑ elanul de 96 m                     [B] strada tramvaiului 1, spre S (+20 → +53)
>   └─────────── coama ←── colțul de sus ←──┘
> ```
>
> | # | frac | POI | ce se întâmplă |
> |---|---|---|---|
> | **P** | 0.00–0.11 | **Podul, spre oraș** — grila pe palierul de pe malul celălalt, banda spre oraș (sud). 36 m de palier, tablierul de 200 m la +20 cu despărțitorul mobil, palierul de la baza podului, S-ul de 60 m. **Circulație pe stânga.** | dreapta de îmbrânceală la start (~330 m până la primul viraj), banda îngustă sau lată după camion |
> | **B** | 0.11–0.26 | **Primul viraj** (90°, R30, la stânga), apoi **strada tramvaiului 1 spre S**: 292 m la 11,4 %, +20 → +52, cu tramvaiul pe ax | corp pe bandă; **urcarea merge spre soare** (§4, pasul 2b: la soare, dar în contra-lumină) |
> | **C** | 0.26–0.33 | **Colțul de sus** (R24, la dreapta), brațul coamei de 84 m spre V (+53), virajul R36 spre N, elanul de 96 m | respiro; tramvaiul 1 iese drept înainte la colț |
> | **D** | 0.33–0.49 | **Lanțul**, neschimbat: patru muchii spre N, +53 → +14,6 | semnătura |
> | **E / E′** | 0.49–0.65 | Terasa și furca; **ocolul de 400 m** sau **serpentinele**; tramvaiul 2 în gura scurtăturii, neschimbat | decizia |
> | **F** | 0.65–0.68 | **Cheiul de nord**, spre E, la +3 (scurtat: se termină la x 120). **Pontonul** pe x 40–120 (pasul 6) | căderea în golf printre stâlpi, ~2 s |
> | **G** | 0.68–0.78 | Colțul de NE, apoi **strada de întors spre pod**, spre S, care urcă +3 → +20 pe 172 m (11,5 %, racorduri de 24 m) | |
> | **P′** | 0.78–1.00 | Virajul de 90° la stânga spre pod (R24), S-ul de 60 m, **podul spre larg** (banda de nord), **întoarcerea-balon** pe malul celălalt (R40–R20–R40, S-uri de 60 m), sosirea | al doilea pasaj peste pod, cu bariera mutată de camion între timp |
>
> Lungimea: **2.571 m** pe curba coaptă (2.563 m pe poligon; planul de hârtie dădea 2.571 m). Tur
> mediu **82,9 s** în ProbeRace (8 × 16 × 250 s), minim 77,3 s: cu ~3 s **peste** fereastra de
> 65–80 s (estimarea de pe hârtie: ~82 s).

Lungime țintă **~2,35 km** (tur ~76–78 s, 3 tururi ≈ 3:50 — fereastra Ignition
65–80 s; a crescut de la ~2,2 km când ocolul scurtăturii s-a lungit la 400 m,
sonda 1b). Sens: **orar**, cu dealul în interiorul buclei; golful la nord și la
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
| **E** | 0.57–0.72 | **Terasa și bulevardul** — la capătul lanțului, pe terasă, **bifurcația**: drumul principal cotește la stânga și ocolește blocul pe un bulevard lat (trei viraje de 90°, **~400 m**, +14,6 → +3; măsurat la 1b: cu 270 m scurtătura nu câștigă la nicio formă), cu **placa turnantă** a tramvaiului la colț și tramvaiul plecând de pe ea **pe bandă**, spre est | linie și viteză; tramvaiul de pe cheu e același care trece prin gura scurtăturii (un vehicul, două roluri) | 14 m |
| **E′** | ramură | **Strada cu serpentine** — drept înainte din terasă: **trei ace de păr la raza 16** pe cărămidă roșie, ~265 m de drum, straturi de **hortensii** pe ziduri joase de cărămidă în interiorul acelor (**solide**, retrase 2 m de la carosabil); jos, gura ei dă în strada tramvaiului | **scurtătura** — detaliu mai jos (forma măsurată la §7, pasul 1b) | 9 m |
| **F** | 0.72–0.86 | **Cheiul de nord** — spre est: carosabilul iese **pe pontonul de scândură** (stâlpi de amarare pe marginea dinspre apă, **cu goluri**), pe lângă magaziile de chei și **plutele cu lei de mare**; lăzi, capcane de crabi și conuri pe margine | **îmbrânceală + parapetul ca punctuație** (`04_coasta.md`): golurile sunt singurele locuri unde cazi în golf. `RespawnZone` pe apă; cădere ≈ 2 s ≈ 2 poziții. `BumpProp` pe lăzi | 12 m |
| **G** | 0.86–1.00 | **Înapoi pe faleză** — colțul de nord-est, apoi spre sud printre palmieri: un cot scurt în jurul unei piațete cu un tramvai vechi parcat, apoi **sprintul final spre turn** | reperul revenit; latura de est (~690 m în total cu A) se sparge în trei gesturi ca să nu fie o dreaptă de 20 s | 14 m |

### Scurtătura: strada cu serpentine (E′)

> **Forma de mai jos e cea măsurată la §7 pasul 1b (runda 2, decizia
> dezvoltatorului din 11 nov 2026).** Forma inițială (ace la raza 8, carosabil de
> 7 m, ~115 m de drum, hortensii moi, ocol de 270 m) a picat la toate punctele
> contractului și e păstrată doar în istoricul de la 1b.

**Intrarea** e drept înainte din terasă, printr-un gang dintre două case cu un
indicator de viraje (fără text). Un viraj de 90° la raza 16, apoi **trei ace de
păr la raza de ax 16 m**, cu carosabil de 9 m (`branch_half_width` 4,5) și virajele
desenate cu 3–4 puncte pe arc (memoria `viraje-stranse-puncte-pe-arc`). Urmează un
viraj de 90° la raza 16 la ieșire și gura. **~265 m de drum**, cu o cădere de 11,6 m.
Raza 8 nu se poate conduce: fără drift, nicio mașină din garaj nu virează mai
strâns de 9,2 m, iar AI-ul nu coboară sub 0,44 × vmax (`CORNER_SPEED_FLOOR`).

**De ce plătește.** Bulevardul are **~400 m** cu trei viraje de 90° (măsurat: 14,3 s);
scurtătura curată ia 12,7–12,8 s, adică **−1,5..−1,6 s** solo și ~−0,8 s mediana
în pluton. **O bordură atinsă costă +2,6 s**, deci scurtătura ajunge să piardă
+1,1 s față de ocol. La 450 m de ocol câștigul trecea de 3 s, iar o atingere tot
câștiga; de aceea s-a ales 400. Bara de turbo: scurtătura o umple de la zero cu
~2 s mai devreme decât ocolul (5,5 s față de 7,6 s), dar și ocolul o umple. Argumentul
„o refaci în serpentine” e real, dar mic.

**Hortensiile** stau pe un **bloc plin de ~0,8 m** (zid de cărămidă cu strat
deasupra), **retras 2 m de la carosabil** în interiorul fiecărui ac, cu
acostamentul de 2 m moale. Măsurat: orice bordură de la 0,2 m în sus e zid pentru
suspensie, deci nu există bordura joasă „pe care o calci”. O bordură subțire cu
strat moale în spate prindea AI-ul între ele. Lipit de margine, blocul îl lovește
AI-ul. Fără bloc, linia dreaptă peste straturi câștiga 1–5 s. Pe exterior, fațade
la 1 m. Petalele (`PropDebris`) zboară când îl atingi.

**Interiorul virajelor de 90° de la intrare și ieșire: moale și LA COTA
DRUMULUI.** Acolo erau 19 din 23 de repuneri ale sondei: terenul săpat după cel
mai apropiat punct de bandă stătea cu 0,5–0,7 m sub carosabil, iar AI-ul care
taie virajul lovea marginea ca pe un zid (memoria
`treapta-teren-interior-viraj-ramura`). Contract pe Track25: cota terenului la
0,5 m dincolo de margine, pe tot interiorul virajelor ramurii, ≥ cota drumului
− 0,3 m.

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

Tramvaiul de pe urcare **~66 s**, cel de pe cheu **29 s**. Niciunul nu e
multiplu de ~73. (Urcarea avea inițial 41 s, dar 290 m la 4,5 m/s înseamnă 64 s
de mers: în 41 s nu încape. Dezvoltatorul a ales pe 10 nov 2026 ciclul de ~66 s,
cu tramvaiul pe toată urcarea. Vezi §7, pasul 1c.) Fazele de start se aleg astfel încât plutonul să nu dea peste
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
| **Mașinile parcate** (D, B) | parcate perpendicular pe trotuar; aterizezi strâmb, intri în ele | **reuse** `BumpProp` (masă per piesă) + `PropDebris`. **Cod minim** (pasul 6): opțiunea `max_footprint` a `BumpProp` (plafonul de 2 m în plan). Masa aleasă ca Autobuzul să le arunce și Poliția să ricoșeze — **nu se pot atinge odată cu „+0,3 s”**, vezi §7 pasul 6 (ales 70 kg). **Niciuna pe carosabil și niciuna în zona de aterizare** (primii 45 m după muchie rămân liberi pe toată lățimea) |
| **Tramvaiul de pe urcare** (B) | vagon greu, ~4,5 m/s, pe șinele din mijloc, **în sensul cursei**; ciclu ~66 s, pe toată urcarea | **reuse** `BusHazard` pe `Path3D`, cu `soft_contact` + `ai_reads_lane` **+ flagurile noi `ai_same_direction` și `pitch_to_ground`** (pasul 1c: fără ele AI-ul nu citește un corp care merge în sensul cursei, iar pe 11,5% vagonul stă orizontal, cu botul în drum). Intră pe ax dintr-o stradă laterală și **iese drept înainte** la colțul unde cursa cotește. Ieșirea laterală taie banda celor care depășesc, măsurat. **Nu** `TRAIN_ALONG` (vine din față, letal pe ax, max 110 m de dreaptă). Model nou `cable_car.glb`, un singur corp |
| **Tramvaiul din gură** (E, E′) | același tip de vagon, pe strada de jos, trece prin fața gurii scurtăturii; ciclu 29 s | **reuse** `BusHazard` (al doilea nod); eventual grupul `branch_gate` (decis de ProbeRace). **Nu** `TrainHazard`: are viteza și timpii constante (26 m/s), cere trei noduri de tren în model, iar AI-ul nu îl citește deloc |
| **Serpentinele** (E′) | §2 | `TrackBranch` pe ruta cu indexul 1 + suprafață de cărămidă (`road_tint` / suprafața ramurii) + **bloc solid** cu hortensii în interiorul acelor (nu `SoftVegetation` pe tot stratul) + acostament la cota drumului pe interiorul virajelor de 90°. **Zero cod de joc** (sonda 1b, runda 2) |
| **Pontonul** (F) | carosabil de scândură, stâlpi cu goluri, apă | **reuse** `RespawnZone` pe golf, plasa de mare **sub** cota apei (memoria `ziduri-invizibile-ale-lumii`); scândura e clasă de textură pe carosabil, nu punte fizică (pontonul care se leagănă e semnătura Ha Long-ului). **Făcut la pasul 6**: `custom_wood_deck_ranges`, rapă-cornișă spre golf, stâlpi moi, `ai_drop_edges` |
| **Leii de mare, papagalii, pescărușii** | teatru | **reuse** `FlockProp`; leii de mare sunt statici pe plute (lătrat pe sunet), **nu traversează** — traversarea de animale e a Serengeti-ului, a Ha Long-ului și a Transfăgărășanului |
| **Zebra și semaforul de pe muchie** (D) | telegraful fiecărei sărituri | decal pe carosabil + GLB atârnat; fără coliziune la înălțimea mașinii în zbor (**semaforul stă la ≥ 8 m peste muchie**: zborul cu turbo urcă la 4,0 m peste drum) |

Calibrare (sisteme.md): tramvai lovit ≈ +2–2,7 s (măsurat la 1c; ținta inițială
de 1,5–2 s a fost revizuită de dezvoltator: vagon greu, în urcare); serpentine curate ≈ −1,5 s (măsurat −1,5..−1,6 s cu ocol de 400 m),
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
  cad pe carosabil — **lanțul rămâne la soare**. **Corectat la pasul 0:** calculul
  e pe teren plat. Pe panta de 28% care coboară în sensul luminii umbra iese de
  ~2× mai lungă, iar la −20° lanțul stătea la soare doar 67,6%. **Ales: 28° / azimut
  −12° față de stradă → 85,1%**, și ambientul coborât la **0,32** (raport 3,9).
  Azimutul se remăsoară pe traseul real. Cu soarele de-a curmezișul, ar
  cădea ~18 m: toată strada în umbră, ca fundul căldării de la Carrara. Ambient
  **rece și mic** (`BCCCE8`-ish, ~0,40; raport soare/ambient ≥ 3 — cifrele
  Carrarei, după corecția de cyan). **Umbre pornite**; pe telefon, profilul
  ieftin (`GameState.SHADOW_DISTANCE_MOBILE`, 55 m) acoperă umbre de 19 m.
- **(Bucla veche. Pe B200 urcarea merge spre S, adică spre soare: e la soare, dar în contra-lumină,
  88,6 % față de 19,5 %. Vezi §7 pasul 2b.)** **Urcarea e în umbră, și e bine**: pe axa est–vest casele de pe partea de sud
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

- `effects/sf_horizon.glb` — **insula cu far** la nord (aproape, ~80 m de țărm), dealurile
  aurii dincolo de golf, un pod gri și un oraș generic de turnuri la sud și sud-vest
- **Fără pod de fundal în NV** (decizia dezvoltatorului din 15 nov 2026: B200, nu „B200 + pod de
  fundal”). Podul roșu e acum **carosabil** (§7 pasul 2b), deci nu mai stă pe inel. Consecința
  acceptată: de pe muchii podul nu se mai vede din față. De pe muchia 1 tablierul e la 358–525 m,
  la +49° (dreapta), deci în ceață și în afara axului. De pe muchia 4 e la 271–470 m, la +86°.
- **Inelul de orizont trece dincolo de malul celălalt.** La E de tablier e acum uscat (dealurile
  aurii, cu întoarcerea-balon la +20), iar zidul lumii e la 475 m de centroid. Siluetele de pe
  inel (dealuri, orașul generic) stau dincolo de mal, sub `fog_end`, nu peste strâmtoarea de sub
  pod. Pe fosta latură de est e acum golf deschis spre S.

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

   **FĂCUT (10–11 nov 2026) — PASS.** Unelte: `tools/gen_sf_loc.py` → `tools/SfLoc.tscn`
   (+ `sf_loc_decor.gd`), clasa `sf_clapboard` (`tools/gen_sf_clapboard.py`) cu cinci
   tente, `sf_brick` definită, tema `sanfrancisco` în `track.gd`, sonda
   `tools/ProbeSfLoc.tscn`, capturile în `docs/asset_briefs/img/sf_loc/` (cheia:
   `sf_loc_cheie.json`, lângă folder). Reproducere: `bash tools/sf_loc_measure.sh`,
   `bash tools/sf_loc_capture_all.sh`, `python tools/sf_loc_shuffle.py`.

   | contract | valoare | țintă |
   |---|---|---|
   | critic orb: capturi SF citite „San Francisco” | **5 / 5**, încredere mare | ≥ 3 / 5 |
   | capturi SF confundate cu altă pistă | **0** | ≤ 1 |
   | soare pe carosabilul lanțului | 85,1% | ≥ 80% |
   | ΔV soare/umbră pe fațade (N·L ≥ 0,25 vs ≤ 0; inclusiv razantele: 0,286) | 0,325 | ≥ 0,28 |
   | ΔE2000 minim între pasteluri, după remap (albedo / cadru) | 15,0 / 14,5 | ≥ 10 |
   | materiale în scenă | 16 | ≤ 38 |

   Reglaje: soarele (vezi §4), ambientul 0,40 → 0,32, tentele în trei runde (albastrul
   saturat, cremul deschis, rozul și galbenul coborâte un pas ca să nu se taie la V = 1).
   **Ce a spus criticul de purtat mai departe:** (1) casele par „înclinate,
   forfecate”. Geometria e verticală; e perspectiva camerei de joc, cu pitch în jos
   pe 28%. De verificat pe traseu și, dacă e nevoie, de corectat din pitch-ul
   camerei pe lanț, nu din case. (2) Trotuarele sunt goale: mobilierul din §5.3. (3)
   Cadrele de pe lanț seamănă între ele: pe traseu fiecare muchie primește un
   reper diferit. (4) Soclurile ies pe trotuar ca trepte (pentru kit). Punctul tare:
   podul plus casele victoriene au dat cea mai sigură recunoaștere din tot setul.

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
   al dezvoltatorului, cu `DriveScene`. **Dat pe 10 nov 2026** (`SondaSfPlan28s`,
   `--ai=3`): „se simt bine acele sărituri”. Lanțul de patru blocuri e aprobat.

   **1b. Serpentinele — FĂCUT (10–11 nov 2026): forma s-a schimbat.** Inițial:
   stradă sintetică cu trei ace la raza 8 și carosabil de 7 m, lângă un ocol de
   270 m cu trei viraje de 90°. Contract: AI-ul trece acele fără `[blocaj]`;
   trecerea curată câștigă 1–2 s față de ocol; cu o bordură atinsă pierde.

   Unelte: `tools/gen_sf_serpentine.py` (implicit forma aleasă; antetul ține
   istoricul variantelor) + `sf_serp_gen_all.sh` → `tools/SondaSfSerp*.tscn`;
   sonda `tools/probe_sf_serp.gd` (moduri `solo` / `race` / `curb` / `dump`;
   `--walls`, `--inner`, `--soft90`), loturi `sf_serp_run.sh`, tabele `sf_serp_sum.py`.
   `probe_lane_clear.gd` primește `--scene=`.

   **Runda 1: raza 8 pică la toate punctele.**
   - Fără drift, raza minimă e 9,2 m la toate mașinile, iar AI-ul nu coboară sub
     0,44 × vmax. Iese larg din fiecare ac.
   - Cu fațade pe exterior: `[blocaj]` la 34% din treceri, repunere la 13%.
   - Trei ace plus virajele de legătură fac 161 m, nu 115.
   - Scurtătura pierde +1,6..+3 s față de ocolul de 270 m, la orice rază și lățime
     (R8–R16, 7–9 m).
   - Hortensiile moi se taie în linie dreaptă, cu un câștig de −5 s.
   - Ce a salvat-o: ocolul mai lung (R8 cu 400 m: −1,9..−2,7 s).

   **Decizia dezvoltatorului (11 nov 2026): R16 / 9 m, ocol lung, interior solid.**
   Runda 2:

   | ocol | scurtătura curată (AI / pro), solo | o bordură atinsă | linia dreaptă |
   |---|---|---|---|
   | **400 m** | **−1,53 / −1,62 s** | **+1,1 s** (pierde) | +7..+13 s, neterminată |
   | 450 m | −3,0 / −3,1 s | −0,4 s (tot câștigă) | +7,5 s |

   Pluton cu `SHORTCUT_CHANCE` 0,4, 8 mașini × 16 seed-uri, ocol de 400 m: ocolul
   are **0 incidente** în 271 de treceri; scurtătura câștigă ~0,8–0,9 s la mediană.
   Repunerile pe scurtătură, pe variante:

   | interior | `[blocaj]` | repuneri |
   |---|---|---|
   | bloc lipit de margine | — | 50% (forțat) |
   | bloc retras 1 m | — | 19% |
   | bloc retras 2 m și la virajele de 90° | 5,0% | 8,3% |
   | **bloc retras 2 m doar la ace, virajele de 90° moi** | **2,2%** | **7,4%** |

   **Repunerile rămase (7,4%) nu țin de formă.** 19 din 23 sunt ejectări în două
   puncte fixe, pe interiorul virajelor de 90°, unde terenul săpat stă cu 0,53–0,73 m
   sub carosabil (memoria `treapta-teren-interior-viraj-ramura`; ProbeLaneClear nu
   le vede). Pe Track25 se rezolvă cu acostament la cota drumului (contractul din
   §2). **Verdictul de pluton se dă pe pista reală**, la pasul 3.

   Alte cifre: o bordură de cărămidă oprește mașina la 60–90°, de la 0,2 m în sus.
   ProbeLaneClear pe forma finală: 0 sonde blocate. Inițial găsea 38, toate
   artefacte ale generatorului (banda pe `deck` nu săpa terenul), reparate prin
   trecerea pe `gravel`. Bara de turbo: vezi §2.

   **1c. Tramvaiul în sensul cursei — FĂCUT (10 nov 2026), PASS.** `BusHazard` pe o
   dreaptă în urcare de 11,5%, 4,5 m/s, pe ax. Contract pe `[blocaj]` și pe coada
   de AI din spatele lui (memoria `franare-de-coada-blocaj-reciproc`), cu sabotaj
   (`ai_reads_lane` stins → trebuie să pice).

   Forma din main **nu** accepta cazul. Trei lipsuri, rezolvate cu cod minim în
   spatele a două flaguri, ambele implicit stinse (Carrara și Machu Picchu neatinse:
   cu flagurile stinse expresiile sunt identice):
   - `BusHazard.ai_same_direction`: AI-ul citește corpul și când merge în sensul
     cursei (`_bus_line` cerea `oncoming`). Partea depășirii o alege fiecare mașină
     după unde e față de tramvai, deci plutonul se desparte. Banda ocupată include
     lateralul tramvaiului peste 1,5 s, pentru intrarea lui din strada laterală.
   - `BusHazard.pitch_to_ground`: vagonul se înclină după pantă. Fără el, pe 11,5%
     coada stă la +0,49 m și botul la −0,49 m în drum, iar Muscle s-a înfipt sub
     coadă.

   Unelte: `tools/gen_sf_tramvai.py` (`SondaSfTramvai*.tscn`), `tools/probe_sf_tramvai.gd`
   (contact solo), `tools/sf_tramvai_race.sh` + `sf_tramvai_report.py` (pluton).
   8 mașini × 200 s; baza fără tramvai: 0 `[blocaj]`, 0 repuneri.

   | variantă | seed-uri | `[blocaj]` | repuneri | întâlniri cu contact | pierdere / întâlnire med / p90 / max |
   |---|---|---|---|---|---|
   | ieșire laterală (v1) | 16 | 2 | 0 | 23,1% | 0,07 / 3,71 / 5,9 s |
   | **ieșire drept înainte, faza 0,66** | 16 | **0** | **0** | **2,2%** din 359 | **0,05 / 0,27 / 2,85 s** |
   | idem, faza 0 (stres pe turul 1) | 8 | 0 | 0 | 0,9% din 320 | 0,10 / 0,45 / 2,8 s |
   | **SABOTAJ** (`ai_reads_lane` stins) | 16 | **169** | 0 | **73,5%** | 1,89 / 10,5 / 31,9 s |

   - Coada de AI practic nu există: 0,8% din întâlniri coboară sub 10 m/s. Depășirea
     se face 95% pe stânga (tramvaiul intră din dreapta), iar pe faza 0 se împarte
     44 / 56.
   - Contact solo (Poliția, Muscle, Buggy, Autobuzul, la 26–32 m/s): **0 ejectări în
     12 lovituri**, 2,1–2,7 s pierdute. **Cost acceptat de dezvoltator** (11 nov 2026),
     în locul țintei de 1,5–2 s.
   - **Regulile pentru traseu:** tramvaiul iese **drept înainte** la colț. Faza se
     transferă împreună cu cele 3,6 s de countdown în care ceasul deja merge.
     Nemăsurat: la colțul din vârf, cei care l-au depășit pe stânga îi taie fața ca
     să vireze la dreapta. De verificat pe Track25.
   - Ciclul: ~66 s, pe toată urcarea (decizia din §2, „Ceasuri”).

   **1d. Podul roșu carosabil (dus-întors, despărțitor mobil) — SONDĂ FĂCUTĂ (13 nov
   2026), mecanismul ține; legarea în Track25 rămâne de decis.** Decizia
   dezvoltatorului din 13 nov: podul roșu din fundal (§5.5) devine **carosabil**, dus-întors
   pe același tablier, cu un **despărțitor de beton mobil** între sensuri. Un camion lent
   mută bariera pe diagonală, ca mașinile care mută despărțitorul pe podurile reale, deci
   banda ta se îngustează sau se lărgește după unde e camionul. Numele real al podului nu
   se folosește nicăieri.

   Unelte:
   - `scenes/hazards/movable_median_hazard.gd` + `MovableMedian.tscn` (`MovableMedianHazard`,
     hazard nou);
   - `tools/gen_sf_pod.py` scrie strada sintetică `tools/SondaSfPod*.tscn` (`Fix` = bariera
     fixă la axă, `Cap` = faza pentru captură);
   - sonda `tools/probe_sf_pod.gd` (`--mode=race|solo`, `--config=mobil|fix|orb|static`);
   - loturile `sf_pod_race.sh` / `sf_pod_solo.sh`, tabelele `sf_pod_report.py` /
     `sf_pod_solo_report.py`, capturile `sf_pod_capture.sh`.

   **Forma sondei.** Un „os de câine” de 1.626 m: două benzi paralele, axele la 12,4 m
   (`half_width` 6). Rampa de acces urcă 11 m la 11,5%. Tablierul are **300 m**, la +23 m
   peste apă, cu palier de 36 m la fiecare capăt. Parapetele exterioare sunt verticale, de
   1,2 m, la |z| = 12,2, deci tablierul are 24,4 m. Turnurile sunt portaluri roșii cu
   picioarele în afara tablierului și traversa la +15 m (la +10 m tăia camera). La capete
   sunt baloane de întoarcere, la raza 20 / 40. Plasa viaductului stă sub tablier, iar
   SeaRespawn sub apă.

   Pe pod, benzile au `half_width` **9,8** (6 + 3,5 + jumătatea blocului): fiecare bandă
   trebuie să fie „pe drum” până la fața barierei când aceasta e pe partea cealaltă.
   Altfel, `is_on_road` ar taxa lățimea câștigată ca iarbă (45%). Deci pe pod cele două
   șosele **se suprapun** pe 7,6 m la mijloc, despărțite fizic de barieră. ProbeLayout
   măsoară pe `half_width`-ul de bază și trece: rază minimă 18,8 m, pantă maximă 12,7%
   (racordurile rampei), apropiere 12,5 m. Suprapunerea e voită. Marginea șoselei late
   iese 3,8 m dincolo de parapet, un pervaz la care nu ajunge nimeni.

   **Despărțitorul** e o funcție de poziția camionului, nu o stare ascunsă:
   `offset(s) = 3,5 · racord(s) · (2·smoothstep(S de 30 m centrat pe camion) − 1)`.
   - În spatele camionului bariera e la −3,5 m, în fața lui la +3,5 m. Când trece, o
     întoarce.
   - Racordul fix are 30 m la fiecare capăt, de la axă (unde continuă despărțitorul fix) la
     poziția mobilă. Fiecare bandă se îngustează la ieșirea de pe pod.
   - Banda îngustă are **8,4 m**, cea largă **15,4 m**.
   - Camionul (cutie gri de 2,6 × 3,2 × 10 m, rotită după S) face naveta pe 210 m, la
     4 m/s, cu 6 s de oprire la capete. Ciclul e de **117 s**, adică 2,3 tururi de sondă.
   - Blocurile sunt **100 × `AnimatableBody3D`**, mișcate doar în fereastra S-ului (cel mult
     11 pe tick, o singură scriere de transform). Vizual sunt un singur MultiMesh.
   - Coliziunea blocului are **1,3 m**, iar vizualul 0,95 m. Cu 0,95 m, un Buggy îmbrâncit
     a urcat pe muchie și a trecut pe sensul opus.
   - Blocurile mobile și camionul au **contact moale** (`soft_hit_crush`): strivire, fără
     ejectarea șoferului.
   - Capul despărțitorului fix e un atenuator de impact, tot moale.
   - Totul e în export vars.

   **AI onest.** `AIController._median_line`, în spatele `MovableMedianHazard.ai_reads_corridor`
   (implicit stins). Linia se strânge între fața barierei de **acum** (sau a camionului) și
   parapet, cu cea mai strânsă față din fereastra pe care o vede în față (1,3 s de drum,
   12–50 m). Nu citește faza camionului. Fereastra prinde și capul despărțitorului fix: cu
   citirea pornită abia pe despărțitor, o mașină care depășea pe stânga a intrat în cap și a
   ajuns pe sensul opus. Cu flagul stins, funcția iese la prima linie.

   Pistele existente rămân neschimbate, verificat cu ProbeRace × 150 s, același cod față de
   main (0daeb26e):
   - **Carrara** (`--track=15`): 4/4 seed-uri **identice cifră cu cifră** (repuneri,
     `[blocaj]`, ejectări, tur mediu).
   - **Machu Picchu** (`--track=8`): 7/8 identice. Al optulea (seed 4) e bimodal din
     Jolt: rulat de două ori pe ramură, a dat o dată cifrele din main și o dată altele.

   **Solo** (pilot scriptat cu gazul la fund, 10 mașini × 4 faze ale camionului, un tur =
   trecerea pe dus și pe întors):

   | pilot | treceri | contacte cu bariera / camionul | treceri peste despărțitor | ejectări / repuneri |
   |---|---|---|---|---|
   | `hug` (freacă bariera, intră în fiecare S) | 80 | 335 / 45 | **0** | **0 / 0** |
   | `line` (linie fixă la z 2,5, pe care bariera o taie) | 80 | 0 / 80 (camionul, la 31,9 m/s) | **0** | **0 / 0** |
   | `hug` cu blocuri **dure** (prima formă) | 92 | 339 / 49 | 0 | **12 / 12** (dv 27–40, toate în S-ul care vine spre mașină) |

   Un zid care se mișcă spre tine nu e un zid pe care l-ai ratat: de aici contactul moale.
   Pilotul iese pe axa benzii după contact, ca un om.

   **ProbeRace pe sondă** (8 mașini × 16 seed-uri × 200 s, ~1.030 de treceri peste pod pe
   variantă). Pierderea e față de mediana trecerii cu bariera fixă, per mașină și sens:

   | variantă | `[blocaj]` | repuneri | ejectări | treceri peste despărțitor | frontale pe coridor | treceri cu contact barieră / camion | pierdere / trecere med / p90 / max |
   |---|---|---|---|---|---|---|---|
   | fix (bariera la axă, fără camion) | 0 | 0 | 0 | 0 | 0 | 1,3% / — | 0,00 / 0,30 / 0,65 s |
   | **mobil** | **0** | **0** | **0** | **0** | **0** | **8,9% / 1,1%** | **0,00 / 0,31 / 7,6 s** |
   | SABOTAJ `orb` (AI-ul nu citește bariera) | 0 | 3 | 2 | **3** | 0 | **31,7% / 12,6%** | 0,03 / 0,76 / 5,1 s |
   | SABOTAJ `static` (citește bariera de la t = 0) | 0 | 0 | 0 | 0 | 0 | **20,7% / 6,3%** | 0,02 / 0,48 / 4,8 s |

   Alte cifre, pe varianta mobilă:
   - turul mediu e 50,0 s, la fel ca la cea fixă;
   - o trecere peste pod durează 9,1 s;
   - **49% din timpul pe tablier** banda e îngustă (< 10 m);
   - pe tablier sunt 21,6 depășiri / seed, **45% dintre ele în banda îngustă**;
   - coada din spatele camionului: 0,2% din întâlniri coboară sub 10 m/s;
   - pierderea pe o trecere cu contact cu bariera e de 0,22 s mediană, 0,75 s p90; cu
     camionul, 0,63 / 0,78 s.

   **Sabotajul pică**, dar trebuie spus pe ce: **pe contacte și pe treceri, nu pe
   `[blocaj]`**.
   - Fără citire, contactele cresc de 3,6 ori cu bariera și de 11 ori cu camionul.
   - Apar 3 treceri peste despărțitor: două mașini urcate pe barieră în S, una pe lângă
     capul despărțitorului fix.
   - Contactul moale și S-ul blând (19°) nu opresc pe nimeni, deci `[blocaj]` rămâne 0 în
     toate variantele. Garda acestui hazard e procentul de treceri cu contact, nu
     `[blocaj]`.

   **Ce a picat pe drum (sonda, nu podul):**
   - **Ieșirea din balon lipită de capul despărțitorului.** Trasa de cursă (apex înăuntru,
     ieșire în afară) ducea mașinile spre despărțitor. Au fost 4 ejectări pe latura lui și 3
     treceri pe lângă cap, la fel și cu bariera fixă. S-a rezolvat cu un S de 60 m în care
     benzile se despart cu 8 m înainte de balon.
   - **Transform3D în `.tscn` e scris pe RÂNDURI.** Rampa despărțitorului și evazările
     parapetului au ieșit oglindite: un Buggy s-a oprit de pe 32 m/s în vârful evazării.
   - **Racordul rapei.** `RAVINE_FADE_FRAC` sapă înaintea capătului declarat. Cu rapa până la
     10 m de capete, palierul stătea pe gol.

   **Regula pentru traseu:** coridorul cu două sensuri începe cu **≥ 60 m drepți** după
   ultimul viraj. Capul despărțitorului e atenuator moale, iar AI-ul îl citește din timp.

   Capturi `--gamecam`: `docs/asset_briefs/img/sf_pod/pod_tablier_camion_gamecam.png`
   (tablierul, cu camionul și S-ul în față) și `pod_ac_gamecam.png` (din întoarcere, spre
   pod).

   Ca s-o conduci:
   `godot --path . res://tools/DriveScene.tscn -- --scene=res://tools/SondaSfPod.tscn --ai=3`.
   Verdictul de feel e al dezvoltatorului.

   **Ce rămâne de decis (dezvoltatorul):** *(punctele 1 și 2 sunt închise: decizia din 15 nov 2026 e
   B200, pasul 2b; ciclul camionului e de 63 s.)*
   1. **Unde se leagă în Track25 și cât costă turul.** Pe sondă, dus-întorsul de la capătul
      podului la capătul podului ia **~28 s**: 9,1 s + 9,9 s de întoarcere + 9,1 s.
      - Pe Track25 (2.424 m, ~77 s), o ramificație dus-întors adaugă ~900 m (2 × 372 m de
        pod cu paliere, plus întoarcerea), deci **~+25–28 s → tur ~103–105 s**. Asta e mult
        peste fereastra de 65–80 s.
      - Variante: tablier mai scurt (200 m = −6 s), podul în locul unei bucăți existente
        din tur (de ex. latura de est, pe care o înlocuiește), sau doar dus pe pod.
      - Planul din memorie: final de tur, înainte de sosire.
   2. **Ciclul camionului pe Track25:** cu turul de ~105 s, 117 s e aproape un tur întreg
      (regula „ceasuri care nu împart turul”). Se alege după lungimea finală (de ex.
      ~80 s sau ~150 s).
   3. **Pervazul de 3,8 m** dincolo de parapet (artefact al benzilor late): pe Track25,
      parapetul pe marginea șoselei înseamnă alt mod de a declara suprapunerea (lățime
      asimetrică), cod în `Track`.
   4. **Mobil:**
      - 100 de corpuri statice, din care ≤ 11 mișcate pe tick;
      - scriptul hazardului costă 80 µs median / 125 µs p99 pe tick pe desktop;
      - un MultiMesh pentru blocuri.

      De măsurat pe iPhone cu ProbePerf când intră în Track25.

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

   > **Cifrele de la pașii 2–3 sunt ale BUCLEI VECHI** (faleza de est, startul la turn). Bucla
   > de acum e B200 (pasul 2b), iar gărzile și ProbeRace-ul ei sunt refăcute acolo.

   **Pașii 2–3 — FĂCUȚI (11 nov 2026).** `tools/gen_sf_route.py` scrie
   `scenes/tracks/Track25.tscn`, geometria gri a serpentinelor
   (`track25_serp_gri.obj`) și planul `docs/asset_briefs/img/sf_route/sf_route_plan.png`.
   Hărțile coapte sunt în `tools/data/sf_route_*.tsv`; generatorul avertizează când
   sunt vechi. Garda proprie: `tools/ProbeSfRoute.tscn`, care măsoară cota
   acostamentului la virajele ramurii și are sabotaj. Cursa se rulează cu
   `tools/sf_route_race.sh` + `sf_route_report.py` (ProbeRace `--sf`). Pista e la
   indexul 17, „San Francisco”.

   | | valoare |
   |---|---|
   | lungime / tur mediu (8 × 16 × 250 s) | 2.424 m / **77,4 s** (minim 72,1) |
   | ProbeLayout | OK: raza minimă 13,5 m, panta maximă 12,0% în afara muchiilor, apropierea 46,5 m |
   | ProbeLaneClear | 0 blocate (linia de bază 0); sabotajul pică |
   | acostamentul la virajele ramurii | minim −0,29 m (contract ≥ −0,30); fără el −0,65 m, 100/100 picate |
   | lanțul | 1.525 de zboruri, airtime median 0,57 s (0,67 s pe muchia 3, unde AI-ul arde turbo), aterizarea la cel mult 27 m |
   | ejectări pe lanț | 5 în ~9.200 de zboruri (0,05%), Autobuzul sau Pompierii, în genunchiul dintre 28% și racord. **Acceptat de dezvoltator** (11 nov): rămân 4 blocuri, cifra se urmărește |
   | scurtătura față de ocol | 13,42 s față de 13,87 s mediană (câștig 0,45 s; 1,38 s între cele mai bune); repunere la 1,6%, `[blocaj]` la 4,8% din treceri |
   | restul turului | 0 `[blocaj]`, 0 ejectări |

   **Abateri față de §2, măsurate:**
   - **Urcarea:** 462 m la 11,4%, nu ~435. Fără racordurile de 24 m, spline-ul trecea de 13%.
   - **Apa:** e la ~460 m de muchia 1, nu la ~355. Blocul serpentinelor R16 are 154 m în adâncime, nu 65. De pe muchia 1 se vede golful de est, nu apa din ax.
   - **Latura de est:** după decizia dezvoltatorului (11 nov), e spartă în trei gesturi: colțul de NE la R30, cotul piațetei (2 × 45° la R36, deplasare de 29,6 m spre V) și devierea de pe faleză (2 × 30° la R50). Dreptele au 172, 172 și 242 m, cu 202 m de îmbrânceală după grilă. În prima variantă era o dreaptă de ~540 m.
   - **Soarele:** strada lanțului merge pe azimut 0° (spre N), deci `custom_sun_rotation_deg = (−28, −12, 0)`.
   - **De urmărit:** pâcla temei (`fog_max` 0,55, aproape albă) arată a ceață pe captura de pe muchia 1, fără inelul de fundal. Se reduce când intră fundalul și se arată dezvoltatorului.
2b. **Bucla reconstruită în jurul podului (B200) — FĂCUTĂ (15 nov 2026), gărzile trec; feel-ul
   rămâne de judecat.** **Decizia dezvoltatorului (15 nov 2026):** Track25 se reconstruiește
   exact ca în planul `docs/asset_briefs/img/sf_pod_plan/sf_pod_plan_B200.png`, **fără pod de
   fundal** (§5.5). Acceptat de la început: din față, de pe muchii, podul nu se mai vede.

   **Unelte:**
   - `tools/gen_sf_route.py` scrie bucla B200 implicit. `SF_LAYOUT=vechi` păstrează bucla veche
     ca istoric: scrie doar cu `SF_LAYOUT_WRITE=1` sau `SF_OUT=`, iar `gen_sf_pod_plan.py` o
     folosește. `SF_START=far0` dă startul alternativ.
   - Hărțile coapte sunt `tools/data/sf_route_fracmap.tsv` (B200) și
     `sf_route_vechi_fracmap.tsv`. Hărțile sunt pe buclă și pe linia de start.
   - `Track.world_half_extent_m` e un export nou, implicit 420. Track25 îl are la 475.
   - `MovableMedianHazard.cushion_near_m`: atenuator și la capătul −X al coridorului, implicit 0.
   - Observatorul `tools/probe_sf_watch.gd` (ProbeRace `--sf`) măsoară acum și podul. Steaguri:
     `--median-fix` (A/B), `--median-blind` și `--median-static` (sabotaje).
     `tools/sf_route_report.py` are secțiunea `--- PODUL` și zonele noi.
   - `tools/probe_sf_light.gd` (`ProbeSfLight.tscn`): soarele pe traseul real, cu case-cutie.
   - Sonda oglindită `tools/SondaSfPodStanga.tscn`: `MIRROR=1` în `gen_sf_pod.py`.
   - ProbeLayout are excepția numită `metadata/two_way_corridors`.

   **Forma.** Bucla are 2.571 m și e orară. Startul e pe pod. Vezi tabelul POI din §2. Cotele:
   podul și capetele lui la +20, strada tramvaiului 1 urcă de la +20 la +53, lanțul și restul
   au rămas cum erau, strada de întors urcă de la +3 la +20.

   Podul pe pistă păstrează geometria sondei 1d:
   - axele benzilor sunt la 12,4 m, iar semilățimea pe tablier e de 9,8 m;
   - parapetele sunt verticale, de 1,2 m, la 12,2 m de axă, cu evazări la capete;
   - portalurile roșii au traversele la +15 și +39, fără coliziune;
   - rapele de sub tablier sunt viaduct (adâncime 60, podeaua la −8), cu plasa viaductului (marja
     12) sub tablier și SeaRespawn sub apă (apa e la +0,02);
   - **despărțitorul**: un nod `MovableMedianHazard`, fix pe palierele de 36 m și mobil pe cei
     200 m de tablier, cu **atenuator moale la ambele capete**;
   - **`plus_dir_side = −1`, deci circulație pe stânga**;
   - `ai_reads_corridor` e aprins. Track25 e singura pistă cu acest nod.

   Placeholder gri peste tot, în afară de portaluri.

   **Abateri față de planul B200, cu motive:**
   1. **Zidul lumii (420 m, fix în cod) e acum un export pe pistă.** Se măsoară de la centroid,
      deci mutarea buclei nu ajută: centroidul se mută cu ea. Singura alternativă era să
      reformez bucla (tablier mai scurt sau balonul mai la V), adică să schimb planul aprobat.
      Exportul are o linie de cod. Pe celelalte piste rămâne 420, deci sunt neschimbate.
      Pe Track25 marginea cea mai depărtată e la 449 m, iar zidul e la 475 m.
   2. **Golful.** Malul orașului e la x 190 în dreptul străzii de întors. Mai la S e la capul
      podului (x 264), ca dealul străzii tramvaiului 1 să aibă flanc de E. Strâmtoarea de sub
      pod merge până la malul celălalt (x 476), iar dincolo e uscat cu dealurile aurii, până la
      110 m N de axa podului. Pe fosta latură de est e golf deschis.
   3. **Planul punea linia de start „pe banda spre oraș imediat după întoarcere”.** Linia e
      exact acolo, la capul despărțitorului de pe malul celălalt (`far1`). Grila stă la 8–32 m
      în spate, pe ieșirea din S. ProbeRace n-a arătat nicio problemă acolo sau la primul viraj
      (mai jos), deci **alternativa `far0` n-a fost necesară și n-a fost rulată**. E în
      generator.
   4. **Camionul**: 4 m/s, cu 4 s de oprire la capete, pe o navetă de 110 m. Ciclul e de 63 s,
      nu 117 s ca în sondă. Faza: la verde camionul e la capătul de E, deci banda spre oraș e
      lată pe aproape tot tablierul.
   5. **Pervazul de 3,8 m** (asfaltul benzii late dincolo de parapet) a rămas ca la sondă. Se
      vede în captură.

   **Gărzi:**

   | gardă | rezultat |
   |---|---|
   | ProbeLayout `--track=17` | OK. Raza minimă 13,5 m, panta maximă 12,7 % la 0.76 (racordul rampei de întors spre pod; < 13). Apropierea în afara coridoarelor e 15,3 m. Cele două sensuri ale podului sunt la 12,3 m: **excepție numită** (`two_way_corridors`, coridorul plus S-urile) |
   | ProbeSfRoute (acostamentul virajelor ramurii) | OK: minim −0,29 m (contract ≥ −0,30); apa la +0,02 |
   | ProbeLaneClear `--track=17` | 50, identic în 2 rulări (linia de bază 6 → 50). 38 sunt blocurile despărțitorului și camionul, pe firul lateral de +3,3 m, unde bariera îngustează banda prin design. 9 sunt tramvaiul 1 pe strada rotită, 3 tramvaiul 2. **Sabotajul pică: 53 > 50** |
   | sonda oglindită (circulație pe stânga), 8 × 16 × 200 s | 0 `[blocaj]`, **0 treceri peste despărțitor, 0 frontale**. Contact cu bariera 9,7 % (pe dreapta: 8,9 %), cu camionul 0,4 % (1,1 %). O ejectare a unui Hot rod pe despărțitorul fix dur al rampei sondei (nu există pe Track25). **Hazardul și `_median_line` merg oglindit fără nicio schimbare de cod**: `plus_dir_side` le acoperă pe amândouă |

   **ProbeRace, 8 mașini × 16 seed-uri × 250 s, `--track=17 --sf`.** `bash tools/sf_route_race.sh <dir>
   [--no-tram | --median-fix | --median-blind --tram-blind]`, apoi `python tools/sf_route_report.py <dir>`
   și `python tools/sf_tram_report.py <dir_no_tram> <etichetă>=<dir> ...`.

   | lot | tur mediu / minim | `[blocaj]` (zone) | repuneri | ejectări | pe lanț (ejectări / zboruri) |
   |---|---|---|---|---|---|
   | **B200, despărțitor mobil, tramvaie** | **82,9 / 77,3 s** | 15 (toate în serpentine) | 8 (serpentine) | 5 (serpentine) | **0 / 1.528** |
   | fără tramvaie | 82,1 / 76,8 s | 19 (serpentine) | 10 (9 serpentine, 1 cheu) | 6 (serpentine) | 0 / 1.532 |
   | despărțitor FIX (A/B) | 83,0 / 77,4 s | 7 (serpentine 4, **pod 2**, ocol 1) | 5 (serpentine 4, **pod 1**) | 3 (serpentine) | 0 / 1.534 |
   | **SABOTAJ** (`--median-blind --tram-blind`) | 89,6 / 77,0 s | **252** (urcare 207, colțul de sus 26, pod 12, strada de jos 6) | 5 | 3 | 0 / 1.435 |

   La **primul viraj** după start și pe pod nu există niciun `[blocaj]` și nicio repunere în
   loturile cu despărțitor mobil. Felia 0.10–0.15 (primul viraj) are 31,7 m/s și 0 % lent.

   **Podul.** O trecere înseamnă capul despărțitorului → capul celălalt, ~8,3 s.

   | lot | treceri | cu contact barieră / camion / atenuator | **peste despărțitor** | **frontale în coridor** | bandă îngustă (< 10 m) | coada după camion (< 10 m/s) |
   |---|---|---|---|---|---|---|
   | **mobil, tramvaie** | 753 | **3,9 % / 0 % / 0,1 %** | **0** | **0** | 31 % din timp | 0 |
   | mobil, fără tramvaie | 769 | 6,4 % / 0,3 % / 0,4 % | **1** | **1** | 31 % | 0,3 % |
   | FIX | 754 | 2,1 % / — / 0,4 % | **1** | 0 | 0 % | — |
   | **SABOTAJ** (AI-ul nu citește bariera) | 667 | **29,8 % / 3,1 %** / 0,7 % | 0 | **2** | 29 % | **3,6 %** |

   - **Contractul „0 treceri, 0 frontale” ține în lotul principal, dar NU în toate loturile.**
     - Lotul fără tramvaie (despărțitor mobil): un Robo (Poliția) intră în coridor pe la capul
       de la baza podului, cu 9,7 m/s. Venea încet din virajul de 90° (R24, la stânga), prin S, și
       a trecut pe partea greșită a capului. A mers apoi 21 s pe banda spre oraș, în sens opus,
       atingând bariera de 3 ori, camionul de 2 ori și atenuatorul o dată. Frontala e a lui, cu
       pachetul turului 2.
     - Lotul FIX: un ocol pe lângă capul de pe malul celălalt, cu 6,4 m/s, după balon.
     - Ambele sunt la **capetele** coridorului, la viteză mică, după un viraj la stânga a cărui
       ieșire largă duce spre axă. E exact lecția sondei 1d (ieșirea din balon spre capul
       despărțitorului). Frecvența: 2 din ~2.300 de treceri.
     - Remedii posibile, nefăcute (de decis):
       - capul despărțitorului început mai devreme, în S, ca o insulă care desparte;
       - virajul de la baza podului mai larg (R24 → R36);
       - AI-ul să citească și capul pe partea lui când vine din viraj.
   - **Sabotajul pică clar pe contacte**: bariera 29,8 % față de 3,9 %, camionul 3,1 % față de
     0 %, coada 3,6 % față de 0, plus 2 frontale. Nu pică pe treceri. La sondă era la fel:
     contactul moale nu urcă pe nimeni peste barieră.
   - **A/B fix–mobil**: turul e identic (83,0 față de 82,9 s). Despărțitorul fix are mai puține
     contacte (2,1 %), dar a dat 2 `[blocaj]` și o repunere pe pod: o Poliție lipită de blocurile
     de la axă. Cel mobil n-a dat niciunul. Banda e îngustă 31 % din timp, contra 49 % la sondă,
     pentru că tablierul e mai scurt.

   **Tramvaiele** (aceeași definiție ca la pasul 5; pierderea e față de lotul fără tramvaie):

   | | tramvaiul 1 (strada rotită, spre S) | tramvaiul 2 (gura) | camionul despărțitorului |
   |---|---|---|---|
   | curbă / viteză / ciclu | 328 m, 5,0 m/s, **66 s** | 106 m, 4,5 m/s, **29 s** | navetă 110 m, 4 m/s + 2 × 4 s, **63 s** |
   | **tur (82,9 s) / ciclu** | **1,26** | **2,86** | **1,32** |
   | faza | 0,130 (era 0,196: plutonul ajunge cu ~4,3 s mai târziu la baza urcării) | 0,568 (era 0,564) | 0,387 (la verde, oprit la capătul de E) |
   | întâlniri / cu contact | 301 / **1,3 %** (pasul 5: 2,2–2,7 %) | 190 / **2,1 %** (1,3–3,1 %) | 753 / 0 % |
   | coadă < 10 m/s | 0,7 % | 2,1 % | 0 % |
   | pierdere med / p90 / max | 0,22 / 0,76 / 3,8 s | 0,79 / 2,41 / 9,9 s | — |
   | contacte după loc | colțul de sus 1, intrare 1, pe ax 2 | pe ax 9, ieșire 2, gura 1 | — |
   | turul 1 | 128 de întâlniri, 2 cu contact | 81, 0 cu contact | — |
   | **SABOTAJ** | **79,2 %** contact, coadă 76 %, 207 + 26 `[blocaj]` | **55,6 %**, coadă 49 % | 3,1 % contact (AI-ul orb) |
   | FIX (martor) | 1,3 % | 2,6 % | — |

   Niciun ceas nu împarte turul: 1,26, 2,86 și 1,32 stau departe de numerele întregi și de
   jumătăți. Viteza tramvaiului 1 rămâne 5,0 m/s. La 4,5 m/s ciclul ar fi ~73 s, deci turul / ciclul
   ar fi 1,14, prea aproape de 1. Pe strada rotită depășirea se împarte 43 % pe stânga, 57 % pe
   dreapta.

   **Scurtătura față de ocol** (porțile de la pasul 3, furcă → gură + 20 m):

   | lot | mediană | cele mai bune | serpentine: repuneri / `[blocaj]` din treceri |
   |---|---|---|---|
   | fără tramvaie | +0,14 s | +1,34 s | 4,5 % / 9,5 % |
   | **cu tramvaie** | **+1,27 s** | +1,32 s | 4,8 % / 9,1 % |
   | FIX | +1,29 s | +1,43 s | 2,4 % / 2,4 % |
   | pasul 5 (bucla veche), cu tramvaie | +0,57 / +0,71 s | +1,3 / +1,65 s | — |

   - Scurtătura câștigă în toate loturile.
   - Cu tramvaiul 2, cine vine pe ocol îl ajunge pe ax, de aceea mediana crește.
   - **Serpentinele au de ~2 ori mai multe `[blocaj]` decât la pasul 3 (4,8 %).** Aproape toate
     sunt în turul 1, la t ≈ 50 s: pachetul ajunge acolo mai strâns după startul pe pod. Lotul
     FIX a dat doar 2,4 %, deci variația dintre loturi e mare.
   - **Ejectările pe lanț**: 0 în ~6.000 de zboruri, pe toate loturile (bucla veche: ~0,05 %).

   **Lumina** (`ProbeSfLight`; case-cutie cu gabaritul de la pasul 0: fațada la 10,5 m, 10,5 m
   înălțime, străzi transversale la 72 m; soarele pistei 28° / −12°). Modelul reproduce pasul 0:
   lanțul are aici 87 %, iar pe strada sintetică avea 85,1 %.

   | stradă | bucla veche | **B200** | unghi mers – soare (B200) | fațadele străzii (N·L) |
   |---|---|---|---|---|
   | lanțul | 87,2 % | **87,0 %** | 168° (soarele din spate) | ±0,18 |
   | urcarea (strada tramvaiului 1) | **19,5 %** (spre V: în umbră, ca în §4) | **88,6 %** | **12°: 100 % contra-lumină** | **±0,18** (amândouă razante) |
   | brațul coamei | 12,8 % | 26,9 % | 78° | ±0,86 |

   Urcarea spre S **nu mai e râpa de umbră din §4**. E la soare, dar în contra-lumină: camera
   vede fețele umbrite. Ambele rânduri de case primesc soarele razant, deci fațadele urcării
   pierd contrastul soare/umbră. Am măsurat și alte azimuturi, cu `--sun=28,AZ`:

   | soarele | lanțul | urcarea | contra-lumină pe urcare |
   |---|---|---|---|
   | −12 (actual) | 87,0 % | 88,6 % | 100 % |
   | −30 | 41,6 % | 49,7 % | 100 % |
   | −50 | 23,4 % | 23,7 % | 100 % |

   Lanțul și urcarea sunt antiparalele: orice soare care luminează lanțul din spate bate în fața
   urcării. **Soarele n-a fost schimbat**, e decizie de artă. Contractul „≥ 80 % pe lanț” cere
   soarele de acum.

   **Carrara și Machu Picchu: neschimbate.** ProbeRace × 150 s, ramura față de main e3a0f0bd,
   dintr-un worktree temporar al lui main; `--track=15` = Carrara, `--track=8` = Machu Picchu.
   - Carrara: seed-urile 1 și 3 identice cifră cu cifră.
   - Machu Picchu: seed-urile 2 și 4 identice.
   - Seed-urile care difereau (Carrara 2, 4; Machu Picchu 1, 3) au rulat de 3 ori pe fiecare
     parte. Fiecare rezultat al ramurii apare și pe main:
     - Carrara seed 4: 72,32 / 71,88 s pe ambele părți;
     - Machu Picchu seed 3: 77,82 s, 7 repuneri, 2 `[blocaj]`, pe ambele părți;
     - Machu Picchu seed 1: 74,34 s, 4 repuneri, pe ramură la a treia rulare.

     E bimodalitatea Jolt, nu o regresie (memoria `proberace-nedeterminism`).
   - Carrara: 0 repuneri, 0 `[blocaj]` pe ambele părți.

   **Capturi `--gamecam`** (`docs/asset_briefs/img/sf_route/`):
   - `b200_grila_pod_gamecam.png`: din spatele grilei. Se vede linia, capul despărțitorului,
     portalul și tablierul.
   - `b200_tablier_camion_gamecam.png`: pe tablier, spre oraș. Se văd S-ul barierei și camionul.
   - `b200_muchia1_gamecam.png`: prima muchie.
   - `b200_tramvai1_gamecam.png`: strada rotită, cu tramvaiul pe ax, `--bus-at=26`.

   Planul e `sf_route_plan.png`. Capturile au o singură mașină (snapshot-ul nu pune grila).

   `bash tools/verify_local.sh` pe ramură: **OK, 75 de pași**.

   **Nemăsurat:**
   - feel-ul la volan;
   - costul pe iPhone (100 de corpuri + camionul pe Track25);
   - captura cu toată grila de 8 mașini;
   - alternativa de start `far0`.

   **Runda 2 (15 nov 2026): capetele despărțitorului, cu main adus în ramură.** Coordonatorul a
   tratat cele 2 ocoliri ale capetelor ca **contract picat**: dezvoltatorul cere 0 treceri pe
   contrasens.

   **Main e adus în ramură prin merge** (41 de commit-uri, între ele #729
   `release/unelte-indici-pista` și #725 `release/verify-paralel`), fără conflicte. Ce înseamnă
   acum `--track=` pentru Track25:
   - ProbeRace citește `--track=` ca text. `17` e tot indexul Track25, dar e un număr ambiguu
     (scena Track17 e Jodhpur) și sonda avertizează. `tools/sf_route_race.sh` cere acum
     `--track=Track25`.
   - ProbeLayout, ProbeLaneClear și snapshot iau tot numărul: `--track=17` încarcă Track25
     (verificat pe eticheta tipărită).
   - Track25 are acum `scenes/tracks/info/Track25.tres` (id `san_francisco`), venit din main.

   **Remediul ales: zidul din S.** Am încercat întâi remediul cel mai puțin invaziv care
   garantează rezultatul fizic. Ambele ocoliri au fost ale unor mașini LENTE, împinse larg
   dintr-un viraj la stânga. Citirea mai devreme a AI-ului (prima variantă propusă) nu oprește o
   mașină împinsă, iar zidul o oprește. Virajul de la baza podului a rămas R24.

   Zidul: capul despărțitorului **începe în S**.
   - E un zid moale (`soft_hit_crush`, ca atenuatorul), de 0,6 m, cu 1,3 m de coliziune peste
     drum, pe axa podului.
   - Are 80 m la fiecare capăt: S-ul de 60 m plus 20 m spre viraj sau balon, lipit de capul
     despărțitorului (`Pod/CapS`, `CAP_S_EXTRA`).
   - În S benzile sunt la 6,2–14,2 m de axă. Generatorul verifică faptul că nicio axă de bandă
     nu trece la mai puțin de 6,0 m de zid.
   - Gărzile sunt neschimbate: ProbeLayout OK, ProbeSfRoute −0,29 m, ProbeLaneClear 50 (exact
     linia de bază; sabotajul dă 53).

   **ProbeRace pe ramura cu main**, 8 × 16 × 250 s, cu zidul:

   | lot | tur mediu | treceri pe pod | **peste despărțitor** | **frontale în coridor** | contact barieră / camion / atenuator | coada după camion | `[blocaj]` |
   |---|---|---|---|---|---|---|---|
   | mobil, rularea 1 | 82,9 s | 742 | **0** | **0** | 5,5 % / 0 / 0,8 % | 0 | 17 (14 în serpentine) |
   | mobil, rularea 2 | 83,0 s | 744 | **0** | **0** | 4,6 % / 0 / 0,4 % | 0 | 15 |
   | fără tramvaie | 82,2 s | 770 | **0** | **0** | 5,5 % / 0 / 0,5 % | 0 | 15 |
   | FIX | 82,6 s | 758 | **0** | **0** | 1,2 % / — / 0,5 % | — | 9 |
   | **SABOTAJ** (`--median-blind --tram-blind`) | 90,5 s | 659 | 0 | 0 | **31,6 % / 3,9 %** / 0 | **3,5 %** | **231** |

   - **Contractul ține în toate loturile**: 0 treceri pe contrasens și 0 frontale în coridor, în
     ~3.000 de treceri. Runda 1 avea 2 din ~2.300.
   - Frontalele „oriunde” (5–7 pe lot) sunt la furcă și în serpentine (23 din 24): mașini
     răsucite în îmbulzeala din turul 1, nu pe pod.
   - **Sabotajul pică în continuare**: contact cu bariera 31,6 % față de 4,6–5,5 %, cu camionul
     3,9 % față de 0, coadă 3,5 %. Tramvaiele au 85 % și 50 % contact și 231 de `[blocaj]`.
   - Tramvaiele în cele două rulări mobile: tramvaiul 1 are 3,2 % / 2,3 % contact, tramvaiul 2 are
     5,5 % / 3,7 %. Runda 1 dădea 1,3 % și 2,1 %, iar pasul 5 1,3–3,1 %. Pierderea mediană a
     rămas 0,22 s și 0,8 s. Zidul nu atinge tramvaiele, deci diferența e între loturi.
   - Lanțul: câte o ejectare în rularea 2 și în lotul FIX, 1 din ~1.530 de zboruri (~0,07 %, ca
     pe bucla veche).
   - Scurtătura câștigă +1,0 / +1,1 s la mediană cu tramvaie.

   **Jucătorul: poate intra intenționat pe contrasens pe la capete?** Am scris o sondă nouă,
   `tools/probe_sf_contrasens.gd` (`ProbeSfContrasens.tscn`). Un pilot scriptat ține gazul la
   fund, cu plafon de 22 m/s, și urmează puncte de hartă care încearcă să treacă pe banda opusă.

   | scenariu | cu zidul | fără zid (`--cap-s=0`) |
   |---|---|---|
   | A: la baza podului, tăiat prin S pe banda opusă | **blocat** (oprit de zid) | trece, 156 m pe contrasens |
   | C: pe malul celălalt, ieșit din balon, tăiat prin S pe banda opusă | **blocat** | trece, 116 m |
   | B: la baza podului, ocolit pe la capătul de V al zidului, peste insula dintre viraje, apoi virajul benzii spre oraș luat invers | trece (86 m, 15,7 s off-road) | trece |
   | D: din balon, ieșirea benzii spre larg luată invers | trece (116 m) | trece |

   **Prin S nu se mai poate trece pe banda opusă: zidul o împiedică fizic la ambele capete.** Pe
   contrasens se mai ajunge doar conducând pista invers, pe o bucată de drum luată în sens opus
   (B, D), cum se poate pe orice pistă. Asta cere ocolul de pe la capătul zidului (B: ~16 s
   off-road) sau balonul parcurs invers. Ca să fie închis și asta, ar trebui ziduri pe marginea
   exterioară a virajelor și a balonului. N-am pus: e decizie de design (pista cu ziduri unde
   până acum n-avea).

   `bash tools/verify_local.sh` pe ramura cu main și cu zidul: **OK, 79 de pași**.

   **De decis (dezvoltatorul):**
   1. **Turul de 82,9 s** e cu ~3 s peste fereastra de 65–80 s. Pârghiile: tablierul de 170 m
      (~−2 s) sau ocolul scurtat (decis la 1b la 400 m).
   2. ~~Cele 2 treceri pe lângă capetele despărțitorului~~ — **rezolvat în runda 2** (zidul din S, 0
      în toate loturile). Rămâne de decis doar dacă se închide și contrasensul „pista condusă
      invers” (scenariile B, D).
   3. **Lumina pe urcare**: contra-lumina e acceptată sau se lucrează pe ea (casele, ambientul,
      fațadele luminate de jos). Soarele nu se poate muta fără să piardă lanțul.
   4. Pervazul de 3,8 m dincolo de parapet.
   5. Startul `far1` (planul), păstrat. Alternativa există, dacă grila pe ieșirea din balon nu
      se simte bine la volan.

4. **Turul de feel, capturile `--gamecam`, tabelul de frustum**; apoi planul de
   sus adnotat, dioramă, foaia de assets.
5. Tramvaiele, cu A/B pe ProbeRace.

   > **Cifrele de la pasul 5 sunt ale BUCLEI VECHI.** Pe B200 (pasul 2b), tramvaiul 1 urcă pe
   > strada rotită spre S, cu faza refăcută. Tramvaiul 2 a rămas pe loc. Tabelele noi sunt la 2b.

   **FĂCUT (12–13 nov 2026) — PASS după runda 2.** Runda 1 (mai jos, păstrată ca istoric) a lăsat
   tramvaiul 2 pe unirea fluxurilor, cu 14–22% contact. Runda 2, pe decizia dezvoltatorului, l-a
   scos de pe ax **înainte de unire**: tramvaiul 2 ajunge la 1,3–3,1% contact. Ambele sunt `BusHazard` pe `Path3D`, generate de
   `tools/gen_sf_route.py` (nodurile `Tramvaie/Tramvai1`, `Tramvai2`), cu flagurile de la 1c:
   `soft_contact`, `ai_reads_lane`, `ai_same_direction`, `pitch_to_ground`. Placeholder gri de
   2,5 × 3,2 × 8,5 m (`cable_car.glb` nu există încă). Capturi: `docs/asset_briefs/img/sf_route/sf_tramvai1_gamecam.png`
   și `sf_tramvai2_gamecam.png` (`--bus-at=14`).

   | | tramvaiul 1 (urcarea) | tramvaiul 2, runda 1 (vezi runda 2 mai jos) |
   |---|---|---|
   | traseu | intră din strada laterală din dreapta, la 20 m după colțul A/B, și iese **drept înainte** la colțul de sus, cu 16 m dincolo de axa laturii de nord | intră din dreapta cu 36 m înaintea gurii, trece prin fața ei și iese în dreapta la 30 m după ea (`x` = 50) |
   | curbă / viteză / ciclu | 328 m, **5,0 m/s**, 66 s (tur / ciclu = 1,17) | 128 m, 4,5 m/s, **29 s** (2,67) |
   | faza / la verde | 0,196 / 82 m pe curbă: e deja pe ax, la mijlocul urcării, când vine plutonul | 0,608 / 94 m |

   **Abateri, măsurate:**
   - **Tramvaiul 1 merge cu 5,0 m/s, nu cu 4,5.** Strada are 292 m, dar curba are 328 m
     (strada laterală, colțul și ieșirea). La 4,5 m/s, ciclul ar fi fost de ~77 s, adică **exact
     turul mediu**: tramvaiul ar fi stat în același loc la fiecare tur. 5,0 m/s păstrează ciclul
     de 66 s ales de dezvoltator, pe toată urcarea.
   - **Tramvaiul 2 nu pleacă de pe placa turnantă.** Ocolul de 400 m (1b) a mutat placa la 125 m
     de gură. Curba placă → gură → ieșire are ~165 m (37 s), iar 37 s ≈ turul / 2. Placa rămâne
     reper de decor. Varianta „două vagoane pe placă” (`TRAM2_LAYOUT=placa`: ciclul de 58 s
     fiecare, defazate cu jumătate) a fost măsurată și respinsă: contact 22%, 14 `[blocaj]` la
     colțul plăcii, unde vagonul intră pe carosabil prin exteriorul virajului.
   - **Flag nou `BusHazard.ai_branch_reach_m`** (implicit 0). Cu citirea globală de 90 m, AI-ul
     din serpentine se așeza pe linia tramvaiului 2 încă din al treilea ac. Mergea fără drift și
     se oprea în strat. Trecerile prin scurtătură care îl întâlneau pierdeau 2,4 s la mediană,
     **fără contact**, iar scurtătura pierdea 0,82 s la mediană față de ocol. Acum, de pe
     scurtătură, AI-ul îl citește doar pe 35 m. Pe buclă rămân 90 m: cu 35 m peste tot,
     contactele urcau.
   - **`AIController`**: la trecerea de pe scurtătură pe buclă, AI-ul recitește corpul
     `ai_same_direction` în coordonatele rutei noi (indexul, lateralul, partea aleasă).
     Corectură de cod; efectul pe cifre e sub zgomot (`--no-bus-route-reset` face A/B-ul).

   Unelte: `bash tools/sf_route_race.sh <dir> [--no-tram | --tram-only=1|2 | --tram-blind]`
   (ProbeRace `--sf`; observatorul `tools/probe_sf_watch.gd`), apoi `python tools/sf_tram_report.py
   <dir_fără_tramvaie> <etichetă>=<dir> ...`. Tabelul folosește definiția de la 1c: întâlnirea
   ține de la 60 m în spatele tramvaiului până la 8 m în fața lui. Pierderea se calculează pe
   urcare pentru tramvaiul 1 și pe furcă → gură + 70 m pentru tramvaiul 2, față de mediana
   aceleiași mașini fără tramvaie. Măsurătoarea: 8 mașini × 16 seed-uri × 250 s.

   | variantă | `[blocaj]` (zone) | tram. | întâlniri | cu contact | coadă < 10 m/s | pierdere med / p90 / max |
   |---|---|---|---|---|---|---|
   | **fără tramvaie** | 11 (toate în serpentine, 8 într-un seed) | — | — | — | — | — |
   | **cu tramvaie** | 6 (urcare 2, strada de jos 3, serpentine 1) | 1 | 408 | **2,5%** | 2,7% | 0,14 / 1,05 / 8,9 s |
   | | | 2 | 241 | **14,5%** | 11,2% | 0,28 / 3,33 / 13,3 s |
   | idem, a doua rulare (fără recitirea rutei) | 16 (serpentine 11) | 1 / 2 | 400 / 241 | 2,2% / 17,4% | 2,8% / 14,5% | 0,17 / 0,98 ; 0,37 / 4,83 s |
   | doar tramvaiul 1 | 4 (serpentine) | 1 | 413 | 3,1% | 3,4% | 0,17 / 1,12 / 6,8 s |
   | doar tramvaiul 2 | 32 (29 în serpentine, în turul 1, trei seed-uri) | 2 | 250 | 22,4% | 19,6% | 0,85 / 3,96 / 10,8 s |
   | **SABOTAJ** (`--tram-blind`) | **256** (urcare 218, strada de jos 35) | 1 / 2 | 313 / 293 | **78% / 74%** | 79% / 63% | tramvaiul 1: 2,33 / 10,7 / 40 s |

   Repunerile au rămas între 4 și 12 în toate variantele, aproape toate în serpentine, ca la
   bază (7). **Ejectările pe lanț: 1 pe lot în toate variantele**, ~0,05% din zboruri, aceeași
   cifră ca la pasul 3. Turul mediu: 77,3 s fără tramvaie, 78,2 s cu ele.

   **Scurtătura față de ocol** (aceleași porți ca la pasul 3):

   | | mediană | cele mai bune | treceri cu contact cu tramvaiul 2 |
   |---|---|---|---|
   | fără tramvaie | ocolul e mai lent cu **0,47 s** | 1,35 s | — |
   | cu tramvaie (trei rulări) | **−0,31 / −0,03 / −0,24 s** (scurtătura pierde) | 1,44 / 1,43 / 1,52 s | 23,8% / 20,3% / 31,7% |

   **Ce a ieșit:**
   - **Tramvaiul 1 trece contractul de la 1c.** Contact 2,2–3,1% din întâlniri, coadă 3%, pierdere
     mediană 0,14–0,17 s. Plutonul se desparte pe din două: 47–52% depășesc pe stânga. În turul 1
     sunt 128 de întâlniri, toate pe ax, cu 1 contact.
   - **Colțul de sus, neverificat la 1c: DA, acolo sunt contactele.** 16 din 18 contacte cu
     tramvaiul 1 sunt la colț (`x` < −70): cei care l-au depășit pe stânga vin în fața lui ca să
     vireze la dreapta. În 2 din 3 rulări cu tramvaiul 1 au apărut și 1–2 `[blocaj]` la colț
     (t ≈ 182 s). Un contact costă 0,6–1,9 s la mediană.
   - **Tramvaiul 2 e de 5–8 ori mai lovit decât tramvaiul 1.** Are 14–22% contact și 11–20% coadă.
     Contactele sunt din spate, la viteză mică (mediana 7–8 m/s), în gură și imediat după ea, pe
     ax. Acolo cele două fluxuri (ocolul și scurtătura) se unesc chiar în coada lui. Variantele
     încercate (citirea de 90 m și de 35 m, recitirea rutei, două vagoane de pe placă) au dat
     10–23%. Diferențele dintre ele sunt de ordinul zgomotului dintre două rulări identice (14,5%
     față de 22,4%). **Niciuna nu aduce tramvaiul 2 la nivelul tramvaiului 1.**
   - **Sabotajul pică clar:** 256 de `[blocaj]` față de 6, contact 74–78% față de 2,5–14,5%.
     Garda măsoară.
   - **`branch_gate`: la limită.** Pragul din §2 este peste 30% din trecerile prin scurtătură cu
     contact. Trei rulări au dat 23,8%, 20,3% și 31,7%, adică 25% pe toate cele 582 de treceri.
     Conform regulii, nu se scrie. Cifra stă însă lângă prag.
   - Gărzi: `ProbeSfRoute` OK, cu acostamentul de la −0,29 m. `ProbeLayout --track=17` OK.
     `ProbeLaneClear --track=17` dă 6 raportări, toate corpurile tramvaielor la ceasul de
     încărcare. Linia de bază a trecut de la 0 la 6, iar sabotajul pică (9 > 6).

   **Deciziile dezvoltatorului (13 nov 2026)** pe cele patru întrebări ale rundei 1:
   1. și 2. Tramvaiul 2 **se mută de pe unire**: trece prin fața gurii și părăsește axul
      înainte ca ocolul și scurtătura să se unească. Rămâne poarta de timing a gurii. **Fără
      `branch_gate`**. Ocolul nu se lungește acum.
   3. Tramvaiul 1 la 5,0 m/s: **aprobat**. Placa turnantă rămâne decor.
   4. Contactele de la colțul de sus: **acceptate**, AI-ul nu se schimbă.

   **Runda 2 — tramvaiul 2 iese spre mal (`TRAM2_LAYOUT=stanga`, implicit în generator).**
   - **Traseul:** intră din strada laterală din dreapta, la `x` = −60, adică 55 m înaintea
     gurii. Merge pe ax. La `x` = −2 virează la stânga (raza 14) spre mal, în fața gurii.
     Iese de pe carosabil pe la `x` ≈ 12, înainte de reîntâlnire (`x` ≈ 22). Capătul liniei e
     un **petic de chei** de 34 × 22 m, tăiat din golf (`LAGOON`) doar pentru varianta asta: acolo
     se ascunde vagonul.
   - **Curba și ciclul:** curba are 106 m. La 4,5 m/s ciclul rămâne de **29 s** (2,67 față de
     tur), din care 23,5 s vizibil. Faza e 0,564 (76 m pe curbă la verde).
   - Captura `sf_tramvai2_gamecam.png` (`--bus-at=19`) îl arată virând spre mal în fața gurii.

   | variantă (8 × 16 × 250 s) | `[blocaj]` | tram. | întâlniri | cu contact | coadă < 10 m/s | pierdere med / p90 / max |
   |---|---|---|---|---|---|---|
   | **fără tramvaie** (cu peticul de chei) | 13 (toate în serpentine) | — | — | — | — | — |
   | **cu tramvaie** | 9 (serpentine 5, urcare 2, strada de jos 2) | 1 | 409 | 2,7% | 3,2% | 0,19 / 1,08 / 6,4 s |
   | | | 2 | 161 | **3,1%** | 2,5% | 0,73 / 2,92 / 10,6 s |
   | idem, repetare | 7 (serpentine 6, urcare 1) | 1 | 415 | 2,2% | 1,7% | 0,18 / 1,02 / 5,5 s |
   | | | 2 | 155 | **1,3%** | 1,9% | 0,52 / 2,92 / 6,7 s |
   | **SABOTAJ** (`--tram-blind`) | **235** (urcare 216, gura și strada de jos 18) | 1 / 2 | 313 / 218 | **78% / 61%** | 76% / 53% | 2,33 / 9,26 s ; 1,43 / 4,27 s |

   | scurtătura față de ocol (furcă → gură + 20 m) | mediană | cele mai bune | treceri cu contact cu tramvaiul 2 |
   |---|---|---|---|
   | fără tramvaie | +0,36 s | +1,40 s | — |
   | cu tramvaie (două rulări) | **+0,57 / +0,71 s** | +1,65 / +1,30 s | 4,5% / 2,0% |
   | runda 1, pentru comparație | −0,31 / −0,03 / −0,24 s | ~1,45 s | 20–32% |

   **Ce a ieșit:**
   - **Contractul e atins.** Tramvaiul 2 are 1,3–3,1% contact pe întâlnire, cât tramvaiul 1
     (2,2–2,7%). Coada e de 2–2,5%. `[blocaj]` 7–9, față de 13 fără tramvaie.
   - **Scurtătura câștigă din nou:** +0,57–0,71 s la mediană față de ocol, iar între cele mai
     bune treceri +1,3–1,65 s. E chiar puțin peste linia de bază: ocolul îl întâlnește pe ax pe
     tramvai, scurtătura iese după el.
   - **Pierderea mediană pe întâlnire e mai mare decât la tramvaiul 1** (0,5–0,7 s față de
     0,2 s). Cine vine pe ocol îl ajunge pe ax, chiar înainte de gură, și trebuie să-l ocolească.
     p90 e de 2,9 s, iar contactele sunt rare.
   - **Sabotajul pică:** 235 de `[blocaj]`, contact 61–78%.
   - **Ejectări pe lanț:** 0–2 pe lot (~0,05%), ca înainte. Turul mediu: 77,3 s fără tramvaie,
     77,9 s cu ele.
   - **Gărzi:** `ProbeLaneClear --track=17` dă tot 6 (tramvaiul 2 apare acum pe INAINTE la
     0,670). `ProbeSfRoute` și `ProbeLayout` sunt OK.

   Nemăsurat: feel-ul la volan (DriveScene sau iPhone) și tramvaiul jucătorului cu cameră reală.
   Placeholderul se rotește pe loc ~1 s când reapare la capătul de start, în afara carosabilului.

6. **Serpentinele, pontonul, mașinile parcate — FĂCUT (15 nov 2026)**, pe B200, din
   `tools/gen_sf_route.py` (ramura `sanfrancisco/pas6`). Ultimele elemente care schimbă jocul;
   după ele rămân doar vizualul și sunetul. Totul e placeholder: cărămida și scândura sunt
   clasele de textură existente, mașinile parcate sunt cutii pe atlasul de paletă, hortensiile
   sunt sfere.

   **Golful lipsea pe B200 (găsit de agentul foii de assets, reparat aici).** Poligonul
   `custom_lagoon` era corect, dar fundul lagunei se calculează ca `media șoselei − lagoon_depth`
   (`TrackSideSampler._carve_lagoon`), cu implicitul 20. Pe bucla veche media era mică; pe B200
   podul și străzile de la +20 au urcat-o la ~23,4, deci fundul ieșea la **+3,4, peste apă (0)**.
   Apa rămânea doar în rapele-viaduct de sub pod. Generatorul scrie acum `lagoon_depth = media + 8`
   (fundul la −8, ca rapele podului). Capturi de sus: `p6_sus_inainte_golf.png` /
   `p6_sus_dupa_golf.png` (`docs/asset_briefs/img/sf_route/`). Consecința: golful e acum apă și
   lângă cheu, la est de strada de întors și în jurul capului de pod. Loturile D și E de mai jos
   sunt cu golful reparat; A, B, C au fost înainte sau imediat după (vezi tabelul).

   **Unde a ajuns pontonul și de ce.** Pe B200 cheiul de nord a rămas în aceleași coordonate
   (`y` 454, la +3), scurtat până la colțul de NE (`x` 120). Golful e imediat la nord de el, deci
   **pontonul încape fără să mute traseul**: `x` 40 → 120 (80 m), de la 18 m după reîntâlnire până
   la începutul colțului de NE. Alte locuri cercetate și respinse: strada de întors spre pod (urcă
   +3 → +20 pe toată lungimea, apa e la 33 m de ea) și colțul de NE (apa e la ~40 m de exteriorul
   lui). Pe ponton:
   - carosabilul are scândura clasei `wood` (export nou `custom_wood_deck_ranges` pe
     `TrackFromPath`, care scrie cheia de temă `wood_deck_ranges` a Kyoto-ului doar pentru pista
     asta; culoarea în temă, `wood_deck_color`). Aceeași geometrie și coliziune ca șoseaua;
   - spre golf e o **rapă-cornișă** pe latura de nord (−1), cu fundul la −8 și lățimea de 60 m.
     Fracțiile rapei sunt pe **lungime** (`_dists / _total_len` în sampler), nu pe indice ca
     muchiile: cu indicele, primii 14 m nu se săpau. Adâncimea e 200 (cu podeaua la −8), fiindcă
     rapa se stinge pe `RAVINE_FADE_FRAC` (~51 m) de la fiecare capăt: cu 30, pe 80 m cornișa
     ajungea sub apă doar la mijloc;
   - **stâlpi de amarare** gri (0,5 × 0,8 × 0,5 m) la 0,3 m dincolo de asfalt, din 6 în 6 m
     (goluri de 5,5 m), **de la `x` 52** (primii 12 m fără stâlpi, vezi mai jos), cu contact moale
     (`soft_hit_crush`);
   - **AI onest**: `ai_drop_edges` pe ponton (latura stângă, marginea 2,5 m), ca la fântâna din
     Jodhpur. AI-ul vede muchia, nu pe cine îl împinge;
   - căderea ajunge în apă și în plasa de mare (SeaRespawn, plafonul la −1,18, apa la +0,02).

   Garda `tools/ProbeSfPonton.tscn` (raze verticale pe coliziunea reală, din 4 în 4 m): carosabil
   la +3 (abatere 0,00 m); spre golf, la 1,5 m de asfalt, solul e cu ≥ 2,53 m sub drum, iar la 8 m
   e la ≤ −3,83 (sub apă); spre oraș, la 1,5 m, abaterea e de 0,30 m (≤ 0,35); plasa e sub apă și
   peste fund. **Sabotajul** (`--side=1`, părțile inversate) pică pe 4 puncte.

   **Căderea, măsurată solo** (`ProbeSfPonton --fall`): 7 mașini × 3 goluri; pilotul trage de
   volan spre golul dintre doi stâlpi, cade, e repus, apoi ține axa până la capătul pontonului.

   | | rezultat |
   |---|---|
   | căderi | **20 / 21** (Poliția a lovit un stâlp moale la golul 3: −1,85 s, fără cădere) |
   | repunerea | **pe carosabil** în toate, pe axa cheiului, cu 7–9 m înaintea golului |
   | pierderea față de aceeași trecere fără cădere | **mediană 2,27 s** (1,98–2,65) — ținta ≈ 2 s |

   **Mașinile parcate.** `scenes/props/sf_parked_car.gd`: trei caroserii placeholder (sedan,
   hatchback, dubă), 3,7 × 1,9 m, până la 1,6 m înălțime, în culori stinse (`PAINTED_METAL`,
   `CORAL_SAND`, `CONCRETE`) pe `Palette.world_material()`, deci **zero materiale noi**. La rulare,
   după primul pas de fizică, coboară pe sol cu o rază verticală și devin `BumpProp` cu masă de
   mașină de joc și `home` (se întorc la locul lor când nu e nimeni la 30 m).
   - **Cod minim, nu zero cod.** `BumpProp.wrap` refuza orice piesă mai mare de **2 m în plan**
     (AABB-ul piesei pe X și Z, fără rotația rădăcinii) sau **1,8 m înălțime**. O mașină parcată
     are 3,7 m. Opțiune nouă `max_footprint` în `opts`; fără ea, regula de la #489 e neschimbată
     pe celelalte piste. Mașina parcată cere 4,5 m (încape și caroseria de 4,2 m a foii de
     assets). **Plafonul de înălțime (1,8 m) a rămas**: o dubă reală mai înaltă de 1,8 m ar deveni
     zid static. De decis la foaia de assets (vezi „de decis”).
   - **42 de mașini**: 30 pe lanț (4 pe fiecare parte a blocurilor 1–3 și 3 pe blocul 4, la 46,6,
     49,5, 56,0 și 62,5 m după muchie, adică pe racordul final și pe intersecția plată) și 12 pe
     strada tramvaiului 1 (două grupuri de câte 3 pe fiecare parte, la `y` 120 și 30, departe de
     intrarea tramvaiului). Perpendiculare pe trotuar, cu capătul dinspre drum la 0,4 m dincolo de
     asfalt. Generatorul verifică fiecare colț al fiecărei caroserii: **niciunul pe carosabil**
     (cel mai apropiat colț e la 7,40 m de axă, carosabilul are 7,0 m) și **niciunul în primii 45 m
     după vreo muchie**.

   **Calibrarea** (`tools/ProbeSfParked.tscn`): teren plat, mașina la 30 m/s, mașina parcată
   perpendiculară pe drum, cu botul intrat 0,6–1,8 m în lățimea ei. Pierderea până la +100 m,
   față de aceeași trecere fără mașină parcată:

   | masa mașinii parcate | Poliția (90 kg) | Taxiul (115) | Autobuzul (260) | mediana tuturor | aruncată de Poliție / de Autobuz |
   |---|---|---|---|---|---|
   | 40 kg | +0,27..+0,60 s | +0,32..+0,60 | +0,18..+0,35 | **+0,35 s** | 26–51 m / 34–64 m |
   | **70 kg (ales)** | **+0,48..+0,92** | **+0,50..+0,90** | **+0,32..+0,55** | **+0,57 s** | 21–39 m / 31–56 m |
   | 100 kg | +0,63..+1,13 | +0,65..+1,13 | +0,43..+0,72 | +0,73 s | 18–31 m / 29–50 m |
   | 140 kg | +0,82..+1,35 | +0,80..+1,35 | +0,57..+0,92 | +0,92 s | 15–24 m / 26–43 m |

   0 ejectări în toate cele 84 de lovituri (și Muscle, Hot rod, Monster). **Cele două cerințe nu
   se pot atinge odată:** la masa la care lovitura costă ~0,3 s (40 kg), Poliția aruncă mașina
   parcată aproape la fel de departe ca Autobuzul; ca Poliția să „ricoșeze” (să piardă mult și s-o
   miște puțin), mașina parcată trebuie să cântărească peste ~140 kg, iar lovitura costă ~1 s.
   Nicio masă nu întoarce Poliția: botul unei mașini perpendiculare e lovit în axa de mers, deci
   mașina de joc își pierde viteza, nu direcția. **Ales: 70 kg**, la mijloc: Autobuzul pierde
   0,3–0,55 s și o aruncă la 31–56 m, Poliția pierde de ~1,7 ori mai mult. Masa e un export
   (`SF_PARK_MASS` în generator, `mass_kg` pe nod).

   **Lanțul cu mașinile parcate** (`probe_sf_crest.gd` pe Track25: sonda știe acum să lucreze în
   cadrul străzii dintr-o pistă reală, din `metadata/sf_chain_azimuth_deg`). Toată flota (10
   mașini), modurile `max`, `t1`–`t4` (turbo înaintea fiecărei muchii), abaterile 0, −4 și +4 m,
   adică 600 de zboruri pe variantă, A/B cu și fără mașini parcate:

   | | cu mașini parcate | fără |
   |---|---|---|
   | zboruri | 600 | 600 |
   | airtime median la plafon / cu turbo | 0,63–0,64 / 0,81–0,83 s | identic |
   | zborul cel mai lung (turbo) | 37,6 m | 37,6 m |
   | mașini parcate atinse | **0** | — |
   | ejectări | 2 | 5 |

   **0 incidente noi.** Toate cele 7 ejectări (în ambele variante) sunt pe `RoadTop`, la 21–37 m
   după muchie, în racordul concav: mecanismul cunoscut de la 1a (aterizarea cu turbo pe racord,
   decizia celor 4 blocuri scurte). Pe strada sintetică aceeași sondă dădea 0 din ~1.400; pe
   Track25 dă 2–5 din 600 pe aceeași geometrie. Diferența dintre variante (2 față de 5) e Jolt:
   mașinile parcate stau la 7,4 m de axă, iar cele trei ejectări în plus (în varianta FĂRĂ ele)
   sunt la abaterile −4 și 0 m.

   **ProbeRace, 8 mașini × 16 seed-uri × 250 s, `--track=Track25`.** `2b` = main (3c039143),
   rulat în același worktree înainte de orice schimbare. Pasul 6 a trecut prin trei stări:
   - **A**: prima formă (golful încă uscat, stâlpi duri de la `x` 43, fațada intrării la 1 m,
     70 kg);
   - **B, C**: golful reparat, stâlpi moi, fațada de pe exteriorul primului viraj de 90 retrasă la
     4 m. B și C sunt aceeași stare, rulată de două ori;
   - **D, E**: starea finală (ca B/C, plus primii 12 m ai pontonului fără stâlpi), rulată de două
     ori.

   | lot | tur mediu | repuneri / `[blocaj]` / ejectări (total) | serpentine: repuneri / `[blocaj]` din treceri | ejectări la intrarea în serpentine (2, 319) | lanț: ejectări / zboruri | scurtătura − ocol, mediană (cele mai bune) | tramvai 1 / 2: întâlniri cu contact | pod: contact barieră, peste / frontale |
   |---|---|---|---|---|---|---|---|---|
   | **2b (main)** | 82,66 s | 7 / 7 / 7 | 4,1 % / 2,9 % | 4 | 0 / 1.529 | +1,14 (+1,27) s | 1,3 % / 2,4 % | 5,4 %, 0 / 0 |
   | A | 82,81 | 8 / 10 / 7 | 2,8 % / 4,5 % | 1 | 1 / 1.529 | +0,98 (+1,37) | 2,0 % / 1,7 % | 5,3 %, 0 / 0 |
   | B | 82,98 | 8 / 19 / 3 | 1,7 % / **9,8 %** | 0 | 1 / 1.526 | +1,23 (+1,42) | 0,3 % / 2,7 % | 5,9 %, 0 / 0 |
   | C (= B, repetat) | 82,75 | 5 / 8 / 4 | 1,7 % / 4,5 % | 0 | 1 / 1.529 | +1,29 (+1,17) | 1,0 % / 2,7 % | 5,2 %, 0 / 0 |
   | **D (final)** | **82,61** | **4 / 7 / 2** | **1,1 % / 3,9 %** | **0** | **0 / 1.526** | **+1,39 (+1,39)** | **1,0 % / 5,0 %** | **6,1 %, 0 / 0** |
   | **E (final, repetat)** | **82,63** | **8 / 8 / 7** | **2,7 % / 4,3 %** | **0** | **0 / 1.529** | **+1,26 (+1,28)** | **1,0 % / 4,0 %** | **4,9 %, 0 / 0** |

   Pasul 6, pe loturi (`--- PASUL 6`):

   | lot | ponton: treceri / căderi / ejectări pe stâlp | mașini parcate: piese urnite (pe cursă) | impacturi distincte / tur-mașină | resturi pe carosabil (s-piesă) / în zona de aterizare | aterizări / ejectări la < 8 m de resturi |
   |---|---|---|---|---|---|
   | A | 390 / 0 / 2 (stâlpi duri, `x` 43) | 22 (1,4) | — | 13,3 / 0 | 0 / 0 |
   | B | 388 / 2 / 2 (stâlpi moi, `x` 43) | 27 (1,7) | — | 0 / 0 | 0 / 0 |
   | C | 384 / 1 / 0 | 21 (1,3) | — | 0 / 0 | 0 / 0 |
   | **D** | **385 / 1 / 0** | **22 (1,4)** | **0,033 (D + E)** | **0 / 0** | **0 / 0** |
   | **E** | **388 / 2 / 2 (stâlpi moi, `x` 55)** | **15 (0,9)** | | **6,3 / 0** | **0 / 0** |

   Trecerile prin serpentine care au atins blocul solid al unui ac (`STRAT`, fără repunere): D + E
   **n = 27, mediana 15,90 s față de 14,88 s pe ocol, deci scurtătura pierde 1,03 s** (B–E: n = 57,
   −1,24 s).

   **Ce a ieșit:**
   - **Turul nu se mișcă**: 82,61–82,98 s pe toate loturile, față de 82,66 s pe 2b.
   - **Serpentinele trec contractul.** Scurtătura curată câștigă **+1,26..+1,39 s** la mediană (2b:
     +1,14 aici, +1,27 la 2b runda 2). O bordură atinsă **pierde 1,03 s** față de ocol (ținta ≈ 1 s).
     Repunerile scad (4,1 % → 1,1–2,7 %), `[blocaj]` rămâne în banda lui (2,9 % pe 2b aici, 9,1 %
     pe 2b runda 2; pe pasul 6: 3,9–4,5 %, cu un lot de 9,8 % — B, cu două seed-uri care fac 12 din
     17, toate în turul 1, la t ≈ 51–59 s). Variația dintre loturi identice (B și C: 9,8 % și
     4,5 %) e mai mare decât orice efect: e îmbulzeala turului 1, ca la 2b.
   - **Cum am scăzut repunerile fără să ating forma:** pe 2b, 4 din 7 ejectări din serpentine erau
     în **același punct** (2, 319): exteriorul primului viraj de 90 de la intrare, unde plutonul
     vine din terasă cu ~30 m/s și cine iese larg lovește frontal fațada de la 1 m. Fațada de pe
     exteriorul acestui viraj (segmentele 0–2 ale ramurii) stă acum la **4 m** de carosabil
     (`SF_ENTRY_WALL_OFF`; trotuar / grădină în fața casei, de rezolvat în kit). Pe B–E: **0
     ejectări acolo** în 64 de curse. Carosabilul, acele, blocurile solide și celelalte fațade sunt
     neschimbate.
   - **Pontonul.** Căderi: 1–2 pe lot, **0,26–0,52 % din treceri, ~0,005 pe tur-mașină**, toate la
     `x` 49–54, adică imediat după vărsarea fluxurilor de la reîntâlnire (ocol + scurtătură), nu pe
     tot pontonul. AI-ul nu cade sistematic. Plus 0–2 ejectări pe lot pe **primul stâlp** întâlnit
     (`lovit=Stalpi`), tot acolo, tot în turul 1 sau 2. Contactul moale (`soft_hit_crush`) nu le
     oprește: mașina e deja cu jumătate peste muchie și atinge în același tick și fusta șoselei,
     iar `Car` ejectează când lovitura nu e „doar moale”. Mutarea stâlpilor cu 12 m mai la est
     (D/E) a mutat ejectarea după ei (`x` 52), nu a scos-o. O ejectare acolo costă cât o cădere
     (repunere, ~2 s), deci contractul „greșeala costă ~2 s” ține; e trecută la „de decis”.
   - **Mașinile parcate.** ~1 impact pe cursă (0,033 pe tur-mașină; o mașină lovită o împinge pe
     vecina, de aceea „piese urnite” e ~1,8 × impacturile). Jumătate pe strada tramvaiului 1, în
     turul 1 (t ≈ 15–20 s): plutonul îngrămădit de după primul viraj. Pe lanț, mai ales pe blocul
     1. **Resturile nu ajung în zona de aterizare**: 0 s în primii 45 m după vreo muchie, 0
     aterizări și 0 ejectări la mai puțin de 8 m de o piesă urnită, în toate loturile. Cât stau pe
     carosabil: 0–13 s-piesă pe 16 curse, apoi se întorc la loc (`home`).
   - **Lanțul în pluton**: 3 ejectări în 7.636 de zboruri pe loturile pasului 6 (**0,04 %**), toate pe
     racordul de după muchie, la 23–25 m după ea, niciuna lângă o mașină parcată. 2b: 0 / 1.529 aici,
     ~0,05–0,07 % pe loturile vechi.
   - **Tramvaiele și podul**: tramvaiul 1 la 0,3–2,0 % contact (2b: 1,3 %), tramvaiul 2 la 1,7–5,0 %
     (2b: 2,4 % aici, 3,7–5,5 % la 2b runda 2); bariera 4,9–6,1 % (5,4 %), **0 treceri peste
     despărțitor și 0 frontale în coridor** pe toate cele 6 loturi.

   **Unelte noi sau schimbate:**
   - `tools/gen_sf_route.py`: blocul „PASUL 6”. Steaguri: `SF_PAS6=0` (scena 2b), `SF_PONTON=0`,
     `SF_PARCATE=0`, `SF_HORTENSII=0`, `SF_PARK_MASS`, `SF_BOLLARD_STEP`, `SF_BOLLARD_FROM`,
     `SF_PONT_X0/X1`, `SF_DROP_MARGIN`, `SF_ENTRY_WALL_OFF`;
   - `tools/ProbeSfPonton.tscn` (`probe_sf_ponton.gd`): garda pontonului, `--side=1` (sabotaj),
     `--fall` (căderea solo);
   - `tools/ProbeSfParked.tscn` (`probe_sf_parked.gd`): calibrarea mașinilor parcate;
   - `tools/probe_sf_crest.gd`: rulează și pe Track25 (`--scene=res://scenes/tracks/Track25.tscn`),
     cu incidentul `PARCATA`;
   - `tools/probe_sf_watch.gd` + `sf_route_report.py`: secțiunea `--- PASUL 6` (trecerile pe ponton,
     căderile, piesele urnite, cât stau resturile pe carosabil și în zona de aterizare, aterizările
     și ejectările lângă resturi), zona `ponton`, steagurile `STRAT` / `FATADA` pe trecerile prin
     serpentine, obiectul lovit la fiecare ejectare (`lovit=`).

   **Gărzi:**

   | gardă | rezultat |
   |---|---|
   | ProbeLayout `--track=17` | OK |
   | ProbeSfRoute | OK, acostamentul −0,29 m (contract ≥ −0,30); apa la +0,02 |
   | ProbeLaneClear `--track=17` | **50, exact linia de bază**: mașinile parcate (stratul 9) și stâlpii (dincolo de asfalt) nu intră. Sabotajul pică (53 > 50) |
   | ProbeSfPonton | OK; sabotajul pică |
   | `probe_decor --track=25` (numărul scenei) | OK, **26 de materiale** (≤ 38): +1 scânduri, +1 hortensii |
   | `verify_local.sh` | **OK, 79 de pași** (prima rulare a picat doar pe `.uid`-ul necomis al scriptului nou, reparat) |

   **Capturi `--gamecam`** (`docs/asset_briefs/img/sf_route/`): `p6_serpentine_gamecam.png`
   (cărămida și hortensiile pe blocul solid, `--route=1`), `p6_ponton_gamecam.png` (scândura,
   stâlpii, golful; `p6_ponton_inainte_golf_gamecam.png` e aceeași vedere cu golful uscat),
   `p6_lant_parcate_gamecam.png` (blocul 2, mașinile parcate pe intersecție). Plus cele două
   capturi de sus ale golfului.

   **Nemăsurat:** feel-ul la volan; costul unei lovituri în mașina parcată în pluton (calibrarea e
   solo, pe teren plat); costul pe iPhone al celor 42 de corpuri (adormite, deci aproape zero până
   la prima lovitură).

   **Deciziile dezvoltatorului (15 nov 2026)** pe cele cinci întrebări ale pasului (masa mașinilor parcate, primul stâlp, plafonul de înălțime al `BumpProp`, fațada de la intrare, petalele):
   1. Mașinile parcate rămân la **70 kg**.
   2. Primul stâlp rămâne cum e: fără stâlpi pe primii 12 m, stâlpii de la `x` 52.
   3. **Plafonul de înălțime al `BumpProp` se deschide per piesă** (făcut, mai jos). Nicio dubă nu
      se pune acum.
   4. Fațada de 4 m de la intrarea în serpentine rămâne; intră în brief-ul kitului de case.
   5. **Petalele: da** (făcut, mai jos).

   **3. `max_height` în `BumpProp.wrap`.** Opțiune nouă în `opts`, lângă `max_footprint`; fără ea,
   plafonul rămâne 1,8 m pe toate pistele. De ce exista plafonul: e regula de mărime de la #489
   („decor mic”), nu o limită de fizică. Ce trebuie știut pentru o piesă înaltă: stratul 9 nu e văzut
   de razele suspensiei, de cameră și de căutarea locului de repunere, deci o dubă răsturnată poate
   trece prin cadrul camerei, iar o repunere poate cădea lângă ea. Sonda `tools/ProbeBumpTall.tscn`:
   o cutie de 1,9 × 2,4 × 4,2 m (duba), 70 și 140 kg, perpendiculară pe drum sau cu flancul spre el,
   intrată 0,6 / 1,2 / 2,0 m în lățimea mașinii, lovită la 30 m/s de Poliție, Taxi, Autobuz, Buggy
   și Monster:

   | | rezultat |
   |---|---|
   | ejectări | **0 / 60** |
   | duba lovită: urnită sau doar răzuită | **60 / 60**; răsturnată (≥ 45°) în 37, alunecată 0,2–104 m |
   | duba ca zid (mașina oprită > 1 s sau la `x` 160 după > 12 s) | **0 / 60** (cel mai lent: 9,15 s, Poliția în flancul unei dube de 140 kg; normal ~4,9 s) |
   | mașina blocată sub dubă | **0 / 60** |
   | **sabotaj**: fără `max_height`, aceeași cutie | **refuzată** (`wrap` întoarce null), plafonul de 1,8 m neschimbat |

   **5. Petalele hortensiilor.** `scenes/props/sf_hydrangea_petals.gd`, nodul
   `SerpentineGri/HortensiiPetale`, scris de generator cu centrul feței de sus a fiecărui bloc.
   Ascultă semnalul `Car.impact` (tipul `wall`) și reacționează doar când corpul lovit e blocul solid
   existent (`SerpStraturi`). **Nicio coliziune nouă, nicio zonă nouă.** Petalele sunt rafalele de
   frunze ale managerului comun `PropDebris`, roz și albastre alternativ: **3 rafale × 8 plăci,
   același material partajat** (culoarea e pe particulă). Anti-spam pe trei niveluri: pragul și
   pauza de 0,2 s ale impacturilor mașinii, **1 s de pauză pe fiecare strat**, 0,12 s pauza globală a
   managerului. Managerul se cere la încărcarea pistei: creat amânat la prima cerere, ar fi pierdut
   prima rafală. Sonda `tools/ProbeSfPetals.tscn`:
   - o mașină reală intră în blocul acului 2: **1 rafală**, la 0,42 s;
   - frecarea, sintetic: 30 de impacturi în 1,5 s pe același strat dau **2 rafale** (plafonul 3);
     **sabotajul** (pauza stratului 0) dă 10 și pică;
   - 0 corpuri de coliziune sub nodul petalelor.

   `probe_decor --track=25`: **26 de materiale**, neschimbat (≤ 38). Captura, cu fereastră, cu camera
   de joc în spatele mașinii, la 0,15 s după lovitură: `docs/asset_briefs/img/sf_route/
   p6_petale_hortensii_gamecam.png` (`godot --path . res://tools/ProbeSfPetals.tscn --
   --capture=res://snapshots/sf_petale.png`). Petalele se văd, dar sunt puține și mici: 8 plăci
   de 0,42 m, cât permite managerul comun.
7. Hero. 8. Kituri, fundal, teatru, sunet; `probe_decor`; testul de
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
