# Track brief — Machu Picchu (`Track15`, temă `machupicchu`) — v0.1 (concept)

> Concept de pistă, înaintea listei de assets. Scheletul e cel din
> `serengeti.md` / `cappadocia.md`; secțiunile de assets (§5) sunt schițate,
> nu complete — se detaliază după ce traseul trece de ProbeLayout, de
> ProbeRace și de captura `--driver`.
> Prima pistă din **America de Sud**, prima cu **ruina ca și carosabil**
> (`ref_notes/05_jungla_ruine.md` — cel mai transferabil lucru din Ignition,
> amânat de trei piste), prima cu **suprafață care reacționează la masă**
> (podul de frânghie) și prima cu **cădere de ambele părți ale benzii** pe
> un sfert de tur (creasta).
>
> **v0.1 (13 sep 2026):** aleasă de dezvoltator între Tikal și Machu Picchu,
> **pentru popularitate** — e cel mai recunoscut sit din emisfera sudică, iar
> silueta lui (terasele + vârful Huayna Picchu) trebuie să fie ce vede
> jucătorul din mașină, nu de pe o poză. Runda întâi de propuneri a fost
> Angkor / Tikal / Sigiriya (junglă + templu). Tikal rămâne candidata pentru
> „junglă + piramide" (mingea din terenul de joc, saltul peste coronament,
> coronamentul ca tavan prin `CameraZone`); Uyuni rămâne candidata pentru
> altiplano. Nu se exclud: America de Sud poate avea două piste.

## 0. Într-o propoziție

Dimineață de iarnă andină (sezonul uscat, iunie–august) la Machu Picchu,
**soare tăios pe terase și un nor care urcă din defileu**: pornești din
Piața Sacră, între ziduri de granit fără mortar, urci pe **treptele Drumului
Incaș până la Poarta Soarelui** — cu defileul Urubamba căzând pe dreapta —
te întorci pe **creasta cu prăpastie de ambele părți** și **toată cetatea ți
se deschide sub tine, în față, cu Huayna Picchu ca un colț înfipt la
capătul ei**, cobori **cascada de terase** (zece trepte de 2,5 m, pe rampe
sau direct), traversezi defileul pe **podul de frânghie care se afundă și se
leagănă sub masa mașinilor**, atingi râul cu trenul albastru pe mal, urci
înapoi pe **serpentinele Hiram Bingham cu autobuzul coborând spre tine**, și
intri în cetate pe **cornișa Podului Incaș**, printr-o poartă trapezoidală
de 8 m (drumul de 13 m strâns la 8). Singura pistă din joc pe care **drumul e ruina** și pe care
suprafața de sub roți se mișcă fiindcă tu ești greu.

## 0.1 Regula de artă (ce NU e pista asta)

**Nu „ruine în junglă". O cetate de piatră albă pe o creastă verde, sub un
cer albastru, cu norul în vale.** Ce trebuie să recunoască jucătorul în 3
secunde: *„terase în trepte, ziduri de granit fără mortar, un munte ascuțit
în față, și sub mine e prăpastie."* Piatra potrivită perfect (fără rosturi
vizibile, colțuri rotunjite) e pentru Machu Picchu ce e tuful săpat pentru
Cappadocia.

| pondere | strat |
|---|---|
| **45%** | cetatea: ziduri și trepte de granit alb-cenușiu, nișe trapezoidale, terase în trepte cu iarbă scurtă, canale de apă, acoperișuri de paie pe câteva case |
| **25%** | relieful: creasta, Huayna Picchu ca vârf-flanc, pereții verzi ai defileului, râul Urubamba brun cu spumă la −40 m, norul care urcă |
| **20%** | pădurea de nori: queñual cu scoarță roșie răsucită, ferigi, bromelii, orhidee (accent), mușchi pe piatra din umbră |
| **10%** | oameni și viață: lame, autobuzul de pe serpentine, trenul de pe mal, un condor așezat pe o stâncă la Poarta Soarelui, rucsacuri și corturi la gara de jos |

Trei acte pe un tur, **aceeași paletă, altă proporție**: cetatea (alb-cenușiu
dominant, verde de terase), defileul (verde închis de pădure + brun de râu
+ alb de nor), serpentinele (pământ ocru + verde). Nu trei palete.

## 1. De ce Machu Picchu (referința reală, ce luăm din ea)

| loc real | ce luăm |
|---|---|
| **Șaua** dintre Muntele Machu Picchu (3082 m) și Huayna Picchu (2693 m), cetatea la 2430 m, râul la ~2000 m, în potcoavă în jurul sitului | **verticalitatea**: cetatea e pe o creastă cu gol de ambele părți; râul e „lumea de jos", tras aproape (§2.0), nu la 400 m |
| **Huayna Picchu**, colțul din spatele cetății în orice poză | **vârful-flanc**: 30 m înalt, la 40–60 m de bandă, la capătul de nord al cetății — intră în cadru **prin față**, când cobori de pe creastă |
| **Inti Punku (Poarta Soarelui)**, capătul Drumului Incaș, 290 m peste cetate — de aici vezi pentru prima dată situl | **dezvăluirea câștigată prin urcare** (`ref_notes/world_design.md`): urci 35 m pe trepte, te întorci, și cetatea e sub tine |
| **Drumul Incaș** (trepte de piatră, cornișe, tuneluri scurte în stâncă) | **ruina ca și carosabil**: treptele sunt drumul, cu margini în pantă (§3, capcana pragurilor > 0,3 m) |
| **Andenes** — terasele agricole, 40 de niveluri de 2–4 m cu ziduri de piatră, scări încastrate în ziduri | **cascada de terase**: decizia rampe (sigur) / direct în jos (rapid, opt sărituri de 2,5 m) |
| **Q'eswachaka**, ultimul pod incaș din frânghie de iarbă, țesut anual; podurile de frânghie au ținut tot imperiul | **hazardul-semnătură**: podul se afundă și se leagănă după masa de pe el (licență de loc: podul e din Apurímac, adus la Urubamba — ca hovercraftul la Baikal) |
| **Podul Incaș** (o cornișă tăiată în peretele de vest, cu bârne de lemn peste un gol de câțiva metri, scoase la nevoie) | **golul de pe cornișă**: bârnele lipsesc pe ciclu, sari sau frânezi (reuse `LiftBridgeHazard`, cu sensul inversat) |
| **Carretera Hiram Bingham**, 13 ace de păr, autobuzele Consettur urcă și coboară continuu | **serpentinele** + **autobuzul care coboară spre tine** (zid cu masă pe traseu fix, reuse mecanismul trenului) |
| **Aguas Calientes** și trenul PeruRail pe malul râului | **lumea de jos** e vie: trenul albastru trece pe mal la −30 m, decor cu mișcare, fără contact |
| **Norii care urcă din defileu dimineața** | **hazardul fals** (`05_jungla_ruine.md`, cascada): un nor alb îți ia vederea 4 s pe creastă; nu costă nimic, înveți să-l ignori |
| **Templul Soarelui** (zid curb), **Intihuatana** (piatra-ceas), **Templul celor Trei Ferestre**, **Casa Paznicului** (acoperiș de paie) | hero-assets de recunoaștere; Casa Paznicului e exact locul pozei clasice — și e locul de unde drumul privește spre nord (§2.0) |
| **Lamele** care pasc pe terase | traversarea de pe terase (reuse `TRAVERSARE`, rig-ul vacii) |
| **Condorul** | **nu zboară** (nu se vede, §2.0) — stă pe o stâncă la Poarta Soarelui, la nivelul ochilor, și își desface aripile când treci |

Culorile locului: **alb-cenușiu de granit** (piatra e aproape albă în
soare), verde-oliv scurt de terase, verde închis-albăstrui de pădure de nori,
**roșu-cărămiziu de scoarță de queñual**, brun-verde de râu cu spumă albă,
ocru de drum de pământ, **paie aurii** de acoperișuri și de frânghie de pod,
alb de nor, **albastru-galben de tren**, roz de orhidee (accent rar). Lumina:
soare la **~40°**, alb-cald, sezon uscat, umbre tăioase (`theme_shadows =
true`) — **dungile de umbră de sub fiecare zid de terasă sunt identitatea
pistei**, cum era umbrela acaciei la Serengeti.

## 2.0 Verificarea cu camera (de ce cetatea e sub tine, și de ce vârful e în față)

`ChaseCamera`: **10 m sus, 12,5 m în spate, 28,7° în jos, FOV 68°**. Marginea
de sus a frustumului e la **~+5° peste orizontală**: la distanța `d` vezi în
sus cel mult `10 + 0.093·d` m. În jos vezi până la **63°**.

- **Poza clasică nu se poate fotografia, se poate conduce.** Poza e făcută
  de la Casa Paznicului, cu cetatea în față-jos și Huayna Picchu în spate.
  La noi drumul de pe creastă **coboară spre nord, prin dreptul Casei
  Paznicului**, deci exact cadrul ăla e parbrizul: terasele la −5…−25 m sub
  bandă umplu jumătatea de jos a ecranului (63° în jos ajung), iar Huayna
  Picchu, 30 m înalt la 50 m distanță, intră în cadru până la
  10 + 0,093·50 ≈ 14,7 m — adică **de aproape vârful nu se vede întreg**,
  se vede baza și flancul, iar vârful iese prin marginea de sus. Întreg se
  vede **de la Poarta Soarelui** (+35 m: vârful lui, la +30, e sub
  orizontala camerei, deci intră tot în cadru de la 250 m) — și apoi, pe
  măsură ce cobori spre el, muntele **crește** și umple cadrul: asta e
  corect, e dezvăluirea inversă. Dacă pe terase (D) flancul singur nu
  citește „munte", **`CameraZone`** (Cappadocia): cu presetul de cavernă
  marginea de sus urcă la ~+21°, și un vârf de 30 m intră întreg de la ~60 m
  — se decide pe captură `--driver`, nu anticipat. Memoria
  `munte-flanc-nu-fundal`: vârf îngust și aproape, trei etaje de culoare
  (granit deschis sus, verde închis, terase la bază).
- **Cetatea se urcă, apoi se privește de sus.** Din piață (0 m) zidurile de
  3 m sunt ziduri. De la Poarta Soarelui (+35 m), cu 63° în jos, cetatea la
  −35 m și 60–150 m distanță e **toată în cadru**. Dezvăluirea costă un
  sfert de tur de urcare, ca la Stromboli, și se plătește pe creastă.
- **Râul e la −40 m, nu la −400.** Lecția din `world_design.md` §2: adâncimea
  se citește prin proximitate, nu prin distanță; la 400 m râul ar fi ceață.
  Sub pod, râul e la −20 m față de tablier (−40 față de cetate), la 0–60 m
  lateral, cu spumă albă pe pietre — se vede **prin** pod, printre scânduri.
  Trenul de pe mal e la 60–120 m de creastă: în `fog_end`, cu culoare
  saturată, se vede mișcându-se.
- **Creasta e creastă, nu umăr.** Memoria `umarul-ingust-ascunde-caderea`:
  ochiul e la 10 m, ce contează e **unghiul**. Taluz > 45° în primii 3 m de
  la piatră, pe ambele părți. Zidul incaș de 0,6 m de pe margine e
  **punctuație** (`04_coasta.md`): pus unde nu vrem să cazi (la ace),
  scos unde vrem (pe dreaptă, unde defileul trebuie să se vadă).
  Memoria `perete-paralel-nu-se-vede`: creasta face **două S-uri cu
  concavitatea spre cetate**, ca terasele și Huayna Picchu să intre în cadru
  prin față, nu doar lateral.
- **Podul trebuie să se vadă că se mișcă.** De la 10 m înălțime, o afundare
  de 1,5 m pe 35 m de tablier e un unghi de 5° la mijloc — vizibil doar
  dacă **frânghiile laterale** și **stâlpii de capăt** dau referința: cablul
  care se lasă față de linia orizontului dintre turnuri. Balansul lateral
  de ±1,2 m se citește față de capătul opus al podului. Se verifică cu
  captură `--driver`, nu cu cifra (memoria `efecte-invizibile-nu-se-numara`).
  **`CameraZone` e la dispoziție** (Cappadocia): dacă afundarea nu se
  citește, un preset „pod" coboară camera la 7 m și apropie ținta — se
  decide pe captură, nu anticipat.
- **Condorul nu zboară.** La 40 m înălțime intră în cadru de la 320 m.
  Stă pe stâncă, la 2 m, lângă Poarta Soarelui.
- **Norul se vede fiindcă e jos.** Un nor care urcă din defileu vine
  **de sub bandă** — ca baloanele din Cappadocia: se vede 3–4 s ridicându-se
  pe perete înainte să-ți intre în drum. Un nor „de sus" nu s-ar vedea.

Consecința: **piața e respiro, urcarea e promisiune, creasta e balconul cu
cetatea în față-jos, terasele sunt coborârea în ce ai văzut, podul e
momentul, serpentinele sunt urcarea înapoi** — dezvăluire pe altitudine ca
la Stromboli și Serengeti, dar cu vârful-flanc care **crește** pe coborâre.

## 2. Traseul și punctele de interes (POI)

Lungime țintă **~2.1 km** (tur ~72 s, 3 tururi ≈ 3:40 — în fereastra
Ignition 65–80 s din `ref_notes/sisteme.md`). Sens: **defileul pe dreapta**
— pe creastă Urubamba e exteriorul buclei, cetatea și terasele interiorul;
la coborârea de pe creastă spre nord Huayna Picchu e în față. (v0.1 scria
„orar”; în convenția Track13/14 asta e **antiorar** — construit cu
exteriorul pe dreapta, cum cer cele cinci mențiuni ale defileului.)
Cote: piața **0 m**, Poarta Soarelui **+35 m**, baza teraselor **−20 m**,
tablierul podului **−20 m**, râul **−40 m**, malul cu trenul **−30 m**,
vârful Huayna Picchu **+30 m** (decor, nu se conduce). Urcarea pe trepte
(0 → 35 pe ~330 m ≈ **10,6%**), creasta (35 → 5 pe ~300 m ≈ 10%),
cascada de terase (5 → −20 pe ~200 m ≈ 12,5% pe rampe; direct e mai
abrupt, e săritură, nu pantă), spre râu (−20 → −30 pe 100 m), serpentinele
(−30 → 0 pe ~330 m ≈ **9,1%**). **Măsurat cu ProbeLayout** (14 sep 2026, `feat/mp-track`): 1985,6 m, rază
minimă 9,0 m la 0,40, pantă maximă **11,5 %** la 0,16, apropiere de sine
21,4 m — OK. **ProbeRace** fără decor, 4 seed-uri: 1,7–2,2 tururi în 150 s,
**0 repuneri**, 0 % în afara șoselei.

```
   [A] START Piața Sacră (0 m) ────── [B] Drumul Incaș: trepte (0→35 m)
        ↑                                        |
   [H] cornișa Podului Incaș (0 m)         [C] Poarta Soarelui + creasta (35→5 m)
        |                                  cetatea sub tine, Huayna Picchu în față
   [G] serpentinele Hiram Bingham                |
        autobuzul coboară (−30→0 m)         [D] cascada de terase (5→−20 m)
        |                                        |
   [F] malul râului, trenul (−30 m) ──── [E] podul de frânghie (−20 m)
```

| # | frac | POI | ce se întâmplă | lățime (semi-lățime, convenția Serengeti: `custom_width_segments`; drumul real e dublu) |
|---|---|---|---|---|
| **A** | 0.00 | **Start în Piața Sacră** — grila pe pavaj de granit între Templul celor Trei Ferestre (stânga) și Templul Principal; în față-sus, pe movilă, Intihuatana; ziduri de 2–3 m cu nișe trapezoidale, iarbă scurtă în piață, două lame care pasc (decor); Huayna Picchu în spate (nu se vede la start — se vede în dreptul lui, la H, ca recompensă de tur) | respiro; zidurile piaței sunt pereți cu masă (contact = ricoșeu), pavajul e suprafața cea mai rapidă a pistei | 9 m |
| **B** | 0.04–0.20 | **Drumul Incaș spre Poarta Soarelui** — drumul iese din cetate pe poarta de sud-est și **urcă pe trepte de piatră** (treaptă 0,25 m × 1,2 m, margini în pantă — §3), pe flancul Muntelui Machu Picchu; pe dreapta, **fără parapet**, defileul: pădure de nori, râul la −40…−75 m; pe stânga peretele cu mușchi, bromelii, un **tunel scurt în stâncă** (12 m, tavan 6 m — sub 15 m lungime, clip tolerabil, Cappadocia §2.0); la 0.14 **norul**: un val alb urcă pe perete din dreapta și acoperă drumul 4 s (§3, hazard fals) | urcare tehnică **10,6%** pe trepte; treptele sunt „ruina ca și carosabil" — vibrația roților pe trepte se **aude și se simte** (suspensia pe raycast le citește), dar nu costă viteză. Cădere în defileu = repunere ~2 s | 6 m |
| **C** | 0.22–0.40 | **Poarta Soarelui și creasta** — treci prin Inti Punku (o poartă de piatră de 5 m cu două încăperi), **condorul** pe stânca din dreapta își desface aripile; te întorci 150° pe un ac larg și **cetatea e sub tine, în față**; creasta coboară spre nord: **gol de ambele părți** (dreapta defileul, stânga terasele la −5…−25 m), două S-uri cu concavitatea spre cetate; la 0.33 **Casa Paznicului** (acoperiș de paie, cadrul pozei clasice) — de aici Huayna Picchu e în față, la 50 m; zid incaș de 0,6 m doar la cele două ace | **vârful vizual.** Creasta e riscul pur al pistei: fără hazard, doar lățime și cădere; aici se arde turbo pe dreapta dintre S-uri, cu cetatea sub roți. Cădere = repunere ~2 s, de oricare parte | 6–7 m |
| **D** | 0.42–0.54 | **Cascada de terase** — drumul intră în terasele de est: **10 terase de 2,5 m**, ziduri de granit, iarbă scurtă; linia principală **zigzag pe rampe** încastrate în ziduri (4 ace strânse, 12,5%); **scurtătura**: drept în jos peste terase, 8 căderi de 2,5 m una după alta (fizica întreagă: fiecare zid e o mică săritură, aterizare pe iarbă 0,85× grip); **lamele** traversează terasa a 5-a pe ciclu ~24 s (§3); canale de apă cu 16 fântâni în trepte pe dreapta (decor, apă) | decizia: rampe (sigur, +3 s) sau direct (rapid, dar 8 aterizări la rând — botul jos = te înfigi în zidul următor; **măsurat în `ProbeMachuTeren`: și Autobuzul poate** — coboară pe roți la 12 și 20 m/s, pierde 0,3–1,3 s față de sport; v0.1 presupunea că masa îl aruncă prea departe, fals cu fizica reală; scurtătura e pentru toți, avantajul celor ușoare e doar timpul). Huayna Picchu **crește** în față pe măsură ce cobori | 6 m (rampe) / liber (direct) |
| **E** | 0.56–0.64 | **Podul de frânghie** — de la baza teraselor drumul iese pe o buză și **podul Q'eswachaka** de 35 m traversează defileul lateral: tablier de bârne pe 4 cabluri de iarbă împletită, două turnuri de piatră la capete, balustrade de frânghie la 1 m (vizuale, nu coliziune); sub el, la −20 m, râul cu pietre și spumă | **hazardul-semnătură** (§3): tablierul **se afundă** sub masă (Autobuzul, factor de masă 2,6 ≈ 1,5 m la mijloc; sportul, factor 0,9 ≈ 0,6 m) și **se leagănă lateral** când intri descentrat sau când două mașini sunt pe el; mașina ușoară aflată pe pod când intră una grea e **ridicată** de val. Fără pereți: cădere = repunere ~2 s. Turbo pe pod = mai puțin timp pe suprafața care se mișcă, dar afundarea la viteză te lansează la ieșire | 5,5 m |
| **F** | 0.66–0.72 | **Malul râului** — coborâre scurtă pe pământ ocru până la −30 m, pe lângă calea ferată de pe mal: **trenul PeruRail** (albastru cu galben, 3 vagoane cu ferestre în tavan) trece pe ciclu ~40 s, **fără să taie drumul** (decor cu mișcare — trenul care blochează e la Baikal); gara mică, corturi, rucsacuri; râul Urubamba pe dreapta, brun-verde cu repezișuri albe | contrast de cotă: ești în fundul lumii pe care ai văzut-o de sus la C; cel mai jos punct al turului. Apă = repunere (`RespawnZone`) | 8 m |
| **G** | 0.74–0.92 | **Serpentinele Hiram Bingham** — urcare pe drum de pământ tăiat în perete: **5 ace de păr** (13 reale, comprimate), peretele pe stânga, golul pe dreapta, queñuali cu scoarță roșie printre ace; **autobuzul Consettur** (galben-alb, masă efectivă 2000, 7 m/s) **coboară pe traseu fix** pe ciclu ~35 s și ocupă 2/3 din lățime; se vede venind de la două ace mai sus (telegraph natural: claxon la fiecare ac) | urcare **9,1%**; „zidul care coboară": nu te oprește (nu e trenul), te **împinge** spre exterior dacă ești pe partea lui — pe ac, exteriorul e golul. **Acele au raza ≥ 13 m pe axă** (măsurat în `ProbeMachuTeren`: la 10 m sportul nu ține interiorul nici fără autobuz, raza lui minimă fără drift e 9,5 m; la 13 m interiorul rămâne liber cu autobuzul de 3,6 m care ia acul larg). Decizia: aștepți în interiorul acului sau treci pe lângă el cu roțile pe margine | 6,5 m |
| **H** | 0.94–1.00 | **Cornișa Podului Incaș** — drumul intră pe o cornișă de 1 m tăiată în peretele de vest (lărgită la 6 m la scara de jucărie), peretele pe dreapta, golul pe stânga; **golul cu bârne** (4 m): 3 bârne de lemn peste gol, **scoase pe ciclu ~28 s** timp de 6 s (reuse `LiftBridgeHazard` inversat) — cu viteză sari, fără viteză frânezi; apoi **Poarta Principală** trapezoidală (**8 m liber la bază**, 7 m sus, 6 m sub buiandrug, tocul de granit — v0.1 scria „4 m", care e semi-lățimea drumului din coloana din dreapta; corectat 15 sep 2026 la construcția piesei, `main_gate.glb` e livrat la 8,4 m liber), și **flancul lui Huayna Picchu în dreapta**, la 40 m, umplând marginea cadrului — ultima recompensă înainte de piață | fereastra de timing pe cea mai rapidă intrare a turului; poarta e **gâtuire** (drumul se strânge de la 13 la 8 m pentru 4 mașini = îmbrânceală cu masă) | 6 m → 4 m (poartă) |

**Ritmul turului:** piață (respiro) → trepte (urcare, nor, promisiune) →
Poarta Soarelui (dezvăluire, condor) → creastă (risc pur, turbo cu cetatea
sub roți) → terase (decizie: rampe sau direct) → pod (momentul, masa) →
râu (fundul lumii, trenul) → serpentine (urcare tehnică, autobuzul) →
cornișă (timing, gâtuire) → piață.

**Ceasuri care nu împart durata turului** (lecția Stromboli): norul
**~31 s** (4 s acoperit), lamele **~24 s**, trenul **~40 s** (decor),
autobuzul **~35 s** (o coborâre completă durează ~18 s, apoi urcă gol pe
cealaltă parte, invizibil), bârnele **~28 s** (6 s lipsă). Podul nu are
ceas: reacționează la mașini. Faza fiecăruia se mută de la tur la tur.

## 3. Hazarduri și mecanici (ce e nou pentru motor)

Acoperirea celor cinci clase din `ref_notes/sisteme.md` §3:

| clasă (Ignition) | aici |
|---|---|
| **teatru** | **norul de pe creastă** (hazardul fals — prima dată frânezi, a doua oară treci cu turbo), condorul, trenul, fântânile |
| frecare | iarba teraselor (0,85×), pământul serpentinelor umed la ace (0,9×) |
| oprire | nimic de peste 3 s: autobuzul împinge, nu blochează (trenul de 12 s e la Baikal) |
| sabotaj de control | **niciunul** — creasta și podul cer control întreg; e decizia pistei (vârtejul e la Serengeti) |
| aruncare | podul (valul de tablier), terasele (căderi), bârnele lipsă, autobuzul (ghiont spre gol) |

| mecanică | pe scurt | ce cere în cod |
|---|---|---|
| **Podul de frânghie** (E) | tablier de 35 m pe 4 cabluri, `deck_width` 11 (= drumul de semi-lățime 5,5; pus pe pistă în `feat/mp-pod2`, golul din carosabil prin contractul pasajului rotativ `road_hole_span()`, plasa viaductului coborâtă cu `net_ceiling_drop()`; ProbeRace 4 seed-uri, ~48 de treceri de AI, 0 căderi); două moduri: **afundare** (parabolă cu săgeata la mijloc, amplitudinea din suma maselor de pe tablier ponderată cu poziția — factor de masă 2,6 (Autobuz) ≈ 1,5 m, 0,9 (sport) ≈ 0,6 m, ridicare 0,25 m la capete când mijlocul e jos) și **balans lateral** (pendul, ±1,2 m, excitat de intrarea descentrată și de viraj pe tablier, amortizare 3 s); mașina de pe tablier primește viteza tablierului | **nou:** `RopeBridgeHazard`. **NU** lanț de `RigidBody3D` (30 de corpuri + joint-uri pe mobil = nu). Două ecuații de arc-amortizor pe pod (săgeată, unghi lateral), rezolvate analitic pe tick; tablierul e **8 plăci `AnimatableBody3D` cu `sync_to_physics`**, așezate pe curba analitică o dată pe tick (memoria `jolt-sync-transform-o-singura-scriere`: `global_transform` întreg, nu poziție + rotație separat), **niciodată spawnate lângă mașină** (memoria `corp-cinematic-aparut-in-masina`: plăcile există permanent). Viteza plăcii intră în mașină prin `platform_velocity` (reuse telecabină) — de aia „valul" ridică mașina ușoară și balansul o împinge. Vizual: tablierul e **un singur mesh** deformat în vertex shader din aceiași doi parametri (săgeată, unghi), cablurile la fel; plăcile sunt invizibile. **Se verifică devreme** (§7): captură `--driver` cu Autobuzul la mijloc — se vede afundarea? |
| **Cascada de terase** (D) | 10 terase de 2,5 m; rampe încastrate în ziduri pentru linia principală; scurtătura e cădere liberă peste ziduri | **zero hazard, geometrie:** `TerrainStep` ca primitivă de teren **s-a respins la construcție** — grila de teren are celula de 7,9 m, deci o treaptă de 2,5 m iese rampă de o celulă (~17°), nu zid, iar sub drum cuantizarea ar crea praguri laterale > 0,3 m. Terasele sunt un **taluz de teren** (rapă cu taluz, nu cornișă, pe stânga crestei) plus **piesele de zid `inca_wall_*`** din §5.3 cu coliziune, așezate pe trepte de 2,5 m; rampa principală intră în zid fără prag. Memoria `suprafete-din-placi-plane`: liniar pe porțiuni, **min**, nu produs. Memoria `suprafete-cu-goluri-si-praguri`: pragul lateral > 0,3 m e zid — aici e **intenționat** zid (terasa de sub tine), dar rampa principală trebuie să intre în zid fără prag. ProbeBumpRigid pe 8 căderi la rând: nu se răstoarnă niciuna dintre cele 4 mașini |
| **Treptele Drumului Incaș** (B) | trepte de 0,25 × 1,2 m ca suprafață de drum, 330 m | **făcut (`feat/mp-sonde`):** `custom_step_ranges` pe `TrackFromPath` (tiparul intervalelor ude) + în `Car` un termen `0,03·sin(2π·s/1,2)` adunat la compresia raycast-ului; coliziunea rămâne pantă lină, treptele vizuale vin cu mesh-ul. Măsurat: 0,00 % pierdere de viteză pe 100 m la 10,6 %, σ compresie 0,022 m față de 0,0003 fără; semnal `steps_changed` pentru audio. Așa ocolim capcana din `05_jungla_ruine.md` (roata cade în orice gol) fără să pierdem senzația. Lecția `carosabil-ingropat-garda`: ProbeBuried pe toată urcarea |
| **Norul** (B–C) | val alb care urcă din defileu pe perete și acoperă drumul 4 s, ciclu ~31 s; vizibil 3–4 s înainte, urcând. **Făcut:** `CloudRiseHazard` extinde `FogCorridorHazard` (frac 0,140, culoar 40 × 18 m, urcă de la −36 la +4 m), pânză billboard cu gradient radial, zero efect pe mașină; pe captură acoperă jumătatea dreaptă a cadrului, se citește ca val, nu ca ecran alb | **nou, mic:** `CloudRiseHazard` — reuse `FogCorridorHazard` (ceață locală cu culoare proprie, alb) cu volumul **în mișcare pe verticală** pe ciclu (reuse metronomul `EruptionCycle`); cost 0 pe mașină (clasa teatru); particule cu count mic + pânză billboard cu margine moale (memoria `particule-muchia-nu-numarul`) |
| **Autobuzul** (G) | corp cinematic (masă practic infinită) pe `Path3D` care coboară serpentinele la 7 m/s, **ciclu 75 s** (coborârea de 434 m durează 62 s la 7 m/s, 13 s ascuns sus — „35 s” din v0.1 nu încăpea), claxon la fiecare ac; **pus pe pistă (`feat/mp-autobuz`, frac 0,909 → 0,70)** după redesenarea celor 4 ace la **13,9 m** pe axă (erau 9,9–11,4); AI-ul nu vede corpuri cinematice, deci ține dreapta prin `custom_lane_corridors (0,70, 0,909, +0,5)`, autobuzul e pe cealaltă jumătate; ProbeRace 4 seed-uri: 0 repuneri, 0 contacte, felia la 24 m/s; **3,6 m lat** (măsurat: la 4,2 m pe drum de 6,5 m interiorul acului nu rămâne liber geometric) și ia acul **larg**, pe jumătatea exterioară; contractul măsurat: pe partea lui ești **scos de pe bandă spre exterior (≥ 3 m)**, nu oprit (max 0,7 s sub 5 m/s); pe interior zero contact | reuse mecanismul `TrainHazard` (corp pe traseu, `sync_to_physics`) cu mesh de autobuz și **fără oprire**: contactul e `DeflectorHazard` care merge (ca elefantul din Serengeti). **AI-ul trebuie să-l vadă** (memoria `obstacol-pe-drum-poate-fi-gimmick`): `HazardMarker` „așteaptă în interiorul acului" pe waypoint, **ProbeRace la început** |
| **Bârnele Podului Incaș** (H) | travee de 4,25 m peste gol, lipsește 6 s din 28 | **făcut (`feat/mp-hazarde`, frac 0,9435):** `LiftBridgeHazard` cu exporturi noi `descend`, `period`, `open_hold`, `standalone_hole` (golul din carosabil prin `road_hole_span()`), fără turnuri/corăbii. Măsurat: AI-ul sare golul la 27–28 m/s, 0 căderi pe 4 seed-uri. **Deschis:** reuse-ul aduce rampele podului mobil, un dâmb de 1,6 m pe cornișă (profilul nu mai e „bârne peste gol”), iar sub gol terenul rămâne la −0,3 m — cere săpătură locală de 4 m ca să fie prăpastie |
| **Lamele** (D) | 4 lame traversează terasa a 5-a, ciclu măsurat 27 s (traversare 7,4 s) | **făcut (frac 0,490–0,498):** `HazardMarker` SLIDING `TRAVERSARE`, `cow.glb` până la `llama.glb` (rig-ul vacii, memoria `asset-animat-pipeline`); **zero cod**. Măsurat: parcate pe interiorul acului prind Autobuzul (seed 4: 7,7 s lent, 6 contacte) — de verificat la volan dacă parcarea pe exterior e mai cinstită |
| **Trenul** (F) | locomotivă + tender + 3 vagoane pe mal, ciclu 40 s, nu taie drumul | **făcut:** `TrainHazard` fără trecere la nivel, pe estacadă de lemn la (−160, −33, −205), 130 m de șină, la 35–70 m de drumul de pe mal; `train.glb` (clasa PeruRail la hero-assets). **Măsurat contra §2.0:** de pe creastă trenul **nu se vede** (malul e la 400+ m, în ceață), se vede doar din F/G — decor cu mișcare acolo, nu „lumea de jos” de pe creastă |
| **Condorul** (C) | stă pe stâncă; `Area3D` la 25 m → desface aripile 2 s, apoi le strânge | decor cu un os; zero gameplay |
| **Fântânile** (D) | 16 bazine în trepte cu apă care curge dintr-unul în altul | decor: apă (shader-ul de la Serengeti v12) + o pânză de „fir" pe bazin; zero gameplay |
| **Golurile** | defileul (B, C, E, G, H), râul (F) | `custom_ravines` + `RespawnZone` (există) |

Calibrare (sisteme.md): cădere de pe creastă/pod/cornișă ≈ 2 s ≈ 2
poziții, terase direct reușit ≈ −3 s / răsturnat ≈ +4 s, autobuz pe ac
≈ +2 s (așteptare sau ghiont), bârne lipsă cu frânare ≈ +2,5 s, nor ≈ 0 s
(dacă nu frânezi), lamă lovită ≈ −0,5 s.

**Regula „AI onest" și podul:** AI-ul nu primește nicio informație despre
starea podului — conduce pe aceleași plăci, primește aceeași
`platform_velocity`. Dacă ProbeRace arată că AI-ul cade de pe pod în > 20%
din treceri, se pune un `HazardMarker` „intră centrat, fără viraj" pe
waypoint-urile de pe tablier, nu se trișează cu grip.

## 4. Paleta și lumina (fără slot nou)

**Nu există slot liber** (31 s-a consumat la Chongqing / Serengeti).
Machu Picchu se face **integral din sloturi existente**; granitul alb-cenușiu
și verdele scurt sunt deja în atlas de la Baikal și Serengeti:

| rol | slot existent |
|---|---|
| granitul cetății (ziduri, trepte, pavaj — dominant) | `MARBLE_GREY` 29 (fețe în soare) + `ROCK_LIGHT` 3 (umbră) — clasa `inca_stone` cu rosturi **în textura de clasă**, nu în geometrie |
| mușchiul pe piatra din umbră, terasele | `CACTUS_GREEN` 12 (oliv, iarbă de altitudine — ca pe buza Ngorongoro) |
| pădurea de nori (pereții defileului) | `TROPICAL_GREEN` 21 + `LOG_DARK` 28 (umbră adâncă) |
| queñual (scoarța roșie răsucită) | `LARCH_RUST` 27 — slotul de larice e exact roșul-cărămiziu al scoarței |
| drumul de pământ al serpentinelor, cornișa | `SAND_SHADOW` 2 + `SAND_MID` 1 — **nu** `ASPHALT`: a doua pistă fără asfalt |
| râul Urubamba | `SEA_DEEP` 18 (brun-verde, în shader-ul v12 cu tentă) + `FOAM_WHITE` 22 (repezișuri) |
| podul de frânghie (cabluri de iarbă, bârne) | `DRY_VEGETATION` 13 (frânghie de paie) + `WOOD_WEATHERED` 9 (bârne) |
| acoperișuri de paie (Casa Paznicului, case) | `DRY_VEGETATION` 13 |
| norul | `FOAM_WHITE` 22 cu alpha, ceață locală albă |
| trenul PeruRail | `CAR_BLUE` 15 + `CAR_YELLOW` 16 — accent saturat, singurul din vale |
| autobuzul | `CAR_YELLOW` 16 + `FOAM_WHITE` 22 |
| lame | `FOAM_WHITE` 22 / `SAND_MID` 1 / `LOG_DARK` 28 (trei culori de blană) |
| condor | `VOLCANIC_BLACK` 20 + `FOAM_WHITE` 22 (guler) + `KERB_RED` 7 (cap) |
| orhidee, bromelii înflorite | `FLAMINGO_PINK` 31 — accent rar, pe pereți, la 2–3 m de bandă |
| Huayna Picchu (vârf) | `MARBLE_GREY` 29 sus / `TROPICAL_GREEN` 21 flanc / `CACTUS_GREEN` 12 bază — trei etaje (memoria `munte-flanc-nu-fundal`) |

**Lumina:** soare la **~40°**, alb-cald, sezon uscat. Azimutul se alege ca
**zidurile teraselor să arunce umbră pe treapta de sub ele** când cobori
(D) — dungile alb/umbră sunt identitatea; și ca fața de vest a Huayna
Picchu să fie în lumină când e în față (C–D). **Se remăsoară la fiecare
redesenare de traseu** (memoria `azimutul-soarelui-fata-de-drum`). Umbre
pornite; **`shadow_distance` trebuie să acopere zidurile teraselor de la
creastă** (memoria `umbre-exista-dar-cascada-e-scurta`: de la +35 m, terasele
sunt la 60–150 m — cascada de 90 m nu ajunge; se testează 150 m, și se
stinge întâi pe device dacă nu ține). `sky_top` albastru andin saturat,
`sky_horizon` albastru pal, `fog` alb-gri **în familia norului**, nu a
solului (aici ceața **e** norul; memoria `ceata-in-familia-solului` se
aplică invers: solul verde-gri nu poate fi mai deschis decât norul). `fog_end`
~300 m (peretele opus al defileului în ea). Raportul soare/ambient **≥ 3,5**
(memoria `geometria-fara-lumina-e-invizibila`): granitul alb tentează la
ambient mare, și atunci zidurile fără mortar devin o suprafață plată.

## 5. Assets (schiță — lista completă după ProbeLayout)

Categoria nouă `assets/models/machupicchu/` (memoria `assets-models-categorii`).

### 5.1 Teren și suprafețe (cod, clase de textură)
`inca_stone` (granit cu rosturi de piatră potrivită, triplanar — ziduri,
trepte, pavaj), `inca_steps` (suprafață de drum: trepte vizuale pe pantă
de coliziune), `terrace_grass` (iarbă scurtă cu benzi de valoare),
`cloud_forest` (verde închis, ferigi, pe pereți), `dirt_road` (pământ ocru
cu urme — serpentine), `river_rapids` (apă v12 + spumă), decal `tyre_on_stone`
(urme negre pe granit alb în piață — `RoadWear`).

### 5.2 Hero (unice)
| asset | note |
|---|---|
| `rope_bridge.glb` (tablier 35 m + 4 cabluri + balustrade, **un singur mesh** cu UV-ul pe lungime pentru deformarea din shader) + `bridge_tower_a/b.glb` (turnuri de piatră) | **cea mai importantă piesă**; deformarea e în shader din 2 parametri, nu în os. Sub 3.000 tri |
| `inti_punku.glb` | Poarta Soarelui: poartă de 5 m cu două încăperi, pe creastă |
| `main_gate.glb` | Poarta Principală trapezoidală, **8,4 m liber la bază** (semi-lățimea drumului e 4), 6 m sub buiandrug, toc de granit |
| `guardhouse.glb` | Casa Paznicului: trei pereți + acoperiș de paie în două ape |
| `sun_temple.glb` | Templul Soarelui: zidul curb pe stâncă, fereastra solstițiului |
| `intihuatana.glb` | piatra-ceas pe movila ei cu trepte |
| `three_windows.glb` | Templul celor Trei Ferestre (zidul cu trei ferestre trapezoidale — silueta din piață) |
| `huayna_picchu.glb` | vârful-flanc, 30 m, cu terase mici pe umăr (Templul Lunii e pe partea nevăzută — nu se face) |
| `inca_bridge_ledge.glb` | cornișa cu bârnele: perete + treaptă de 6 m + travee de 3 bârne (pe `LiftBridgeHazard`) |
| `llama.glb` (animat: `Walk`, `Idle`, `Graze`) | rig-ul vacii re-proporționat (gât lung), **întâi Quaternius** (memoria `asset-animat-pipeline`); 3 clase de culoare |
| `condor.glb` (aripi pe un os, `Open`/`Close`) | așezat, 1,2 m; anvergură 3 m desfăcut |
| `consettur_bus.glb` | autobuz scurt, galben-alb; **reuse mesh-ul Autobuzului din garaj** cu clasa de culoare schimbată, dacă proporțiile țin |
| `perurail_train.glb` | reuse `assets/models/vehicles/train.glb` cu 3 vagoane și clasa PeruRail (albastru + galben, ferestre în tavan) |

### 5.3 Kit de cetate (modular, statistice)
`inca_wall_a/b/c.glb` (ziduri 2–3 m cu nișe trapezoidale, capete drepte
ca să se înlănțuie), `inca_stair_a/b.glb` (scări încastrate în ziduri de
terasă), `inca_house_a/b.glb` (case cu frontoane, cu/fără acoperiș de
paie), `fountain_basin.glb` (bazin de fântână, 16 în trepte),
`water_channel.glb`, `polylepis_a/b.glb` (queñual răsucit, 4–7 m, scoarță
roșie), `tree_fern.glb`, `bromeliad.glb`, `orchid_cluster.glb` (accent),
`moss_boulder_a/b/c.glb`, `bamboo_clump.glb` (mal), `tent_a/b.glb`,
`backpack_pile.glb`, `trail_marker.glb` (piatră cu inscripție), `rope_rail.glb`
(parapet de frânghie pe creastă, decor).

### 5.4 Fundal (`horizon_class`)
`gorge_far_wall` (peretele opus al defileului, la 200–250 m, benzi de
verde), `machu_picchu_mountain` (muntele de sud, 60 m, ca siluetă la 150+
m — **nu** se conduce pe el; Poarta Soarelui e pe umărul lui), `cloud_bank`
(bancuri de nor jos în vale, plane cu alpha, la 150 m), **`cast_shadow` OFF
pe tot orizontul** (memoria `caster-departat-fura-umbra`).

### 5.5 Sunet
vântul pe creastă (crește cu altitudinea), scârțâitul podului (crește cu
afundarea — telegraph natural al masei), bârnele care cad, claxonul
autobuzului la fiecare ac (telegraph), fluierul trenului din vale (reverb
lung), norul (liniște + umezeală), apa fântânilor, lamele, un strigăt de
condor la Poarta Soarelui (o dată pe tur), roțile pe trepte (vibrație
periodică la B — e sunetul-semnătură al urcării).

## 6. Bugete

- triunghiuri: raportate, fără plafon; kitul de ziduri se multiplică
  (150+ piese) — sub 300 tri per zid, rosturile în textură, nu în geometrie;
  terasele sunt teren, nu asset
- materiale: atlas + ~7 clase (§5.1) + shader-ul podului (deformare) + apă +
  ceață locală (nor) + decal → țintă **≤ 20**
- fizică: 8 plăci de pod (permanente) + autobuz + tren + 4 lame + bârne;
  ieftin față de Serengeti (fără bazin de 16 corpuri). Riscul pistei e
  **GPU pe terase**: zeci de ziduri cu umbre la 150 m de cascadă — se
  măsoară `shadow_distance` 90 vs 150 pe captură înainte de decor
- **umbre pornite** (dungile teraselor) — dacă testul pe device nu ține
  60 fps, se scurtează cascada la 90 m (terasele de aproape își păstrează
  dungile), apoi se sting
- **de verificat devreme:** (1) podul — captură `--driver` cu Autobuzul la
  mijloc și sportul intrând: se vede afundarea și valul? (memoria
  `efecte-invizibile-nu-se-numara`); (2) treptele ca suprafață: ProbeBuried
  pe urcare + captură laterală că treptele nu plutesc peste pantă; (3)
  captura `--driver` de la Casa Paznicului: se vede cetatea sub tine și
  Huayna Picchu în față, sau se vede taluz? (memoria
  `umarul-ingust-ascunde-caderea`); (4) 8 căderi la rând pe terase cu cele 4
  mașini, ProbeBumpRigid: nicio răsturnare

## 7. Ordinea de construcție

> **Stare (14 sep 2026, PR de integrare):** pașii 1–3 și 5–6 sunt făcuți fără decor
> (sonde, Track15, pod, trepte, bârne, nor, lame, tren, autobuz), toate gărzile
> verzi pe scena integrată. Urmează pasul 4 (verdict la volan + captura de la
> Casa Paznicului cu decor) și 7–8 (hero-assets, kit, POI cu constructor + critic).

1. **Sonde tehnice înaintea traseului** (`tools/ProbeMachu.tscn`): (a)
   podul — 8 plăci pe curbă analitică, `platform_velocity`, Autobuz + sport
   simultan: afundare, val, balans, fără mașină înfiptă în placă; (b) treptele
   ca suprafață: raycast pe pantă lină + zgomot ±3 cm, ProbeBuried; (c)
   terasele: 8 căderi de 2,5 m la rând, 4 mașini, fără răsturnare; (d)
   autobuzul cu `DeflectorHazard` pe ac: ghiontul e spre exterior, cu masă.
2. `Track15.tscn` din `TrackFromPath`, temă `machupicchu` (soare 40°, fog
   300 alb, umbre pornite, `shadow_distance` de testat), traseul din §2,
   `TerrainStep` pentru terase, `TerrainPeak` pentru Huayna Picchu.
   ProbeLayout pe pante (urcare < 13%). `GameState`: Track15 = **indexul 8**.
3. **ProbeRace la început, nu la final** (memoria
   `proberace-la-inceput-nu-la-final`): 8 mașini, 16 seed-uri, fără decor —
   ajung la linie? AI-ul trece podul și serpentinele cu autobuzul?
4. Sonda de feel: piață → trepte → creastă → terase → pod → serpentine, un
   tur singur. **Captura `--driver` de la Casa Paznicului** (C): se vede
   cetatea? Dacă nu, taluzul se taie mai abrupt sau creasta se ridică.
5. Podul (hazardul-semnătură) + terasele; ProbeRace A/B pe distribuții.
6. Norul, autobuzul, bârnele, lamele, trenul, condorul.
7. Hero-assets: pod, porți, Casa Paznicului, Huayna Picchu, lama.
8. Kit de cetate, pădure de nori, fundal, figuranți; probe_decor, verdict la
   volan.

## 8. Lecții aplicate anticipat, și ce a fost respins

- **Frustumul decide:** cetatea se urcă, apoi se privește de sus, în față;
  vârful e flanc care crește pe coborâre; condorul stă; norul urcă de jos.
- **Poza clasică e parbrizul, nu fundalul:** creasta coboară spre nord prin
  dreptul Casei Paznicului; toată orientarea pistei e derivată de aici.
- **Ruina e carosabil, dar coliziunea e pantă:** treptele trăiesc în mesh
  și în zgomotul de raycast, nu în corpul de coliziune. E singurul fel în
  care „ruina ca și carosabil" din Ignition nu cade în capcana pragurilor.
- **Suprafața cu masă, nu hazard cu ceas:** podul nu are fază — reacționează
  la cine e pe el. E prima suprafață din joc care face masa mașinii
  **vizibilă** fără contact între mașini.
- **Un hazard nou cu adevărat, restul reuse:** `RopeBridgeHazard` e singura
  clasă nouă mare; norul, autobuzul, bârnele, lamele, trenul sunt reuse cu
  parametri. Decizie asumată din comparația cu Tikal: aici identitatea e
  geometria (creasta, terasele, cetatea), nu numărul de mecanici.
- **Creasta e creastă:** taluz > 45° pe ambele părți, S-uri cu concavitatea
  spre cetate, parapet ca punctuație (doar la ace).
- **AI onest cu podul și cu autobuzul:** aceleași plăci, aceeași
  `platform_velocity`; dacă nu trece, waypoint de așteptare / de centrare, nu
  grip în plus.
- **Respins, cu motiv:** condor care zboară (nu se vede), ploaie ciclică
  (dublează Chongqing; sezonul uscat e alegerea de lumină), cutremur /
  alunecare de teren „huayco" (set piece unic, nu ciclic — regula din
  Chongqing §2), bolovani pe serpentine (dublează Serengeti F; autobuzul e
  contrapunctul), trenul care taie drumul (dublează Baikal; aici e decor cu
  mișcare), Scările Morții de pe Huayna Picchu ca scurtătură (65° — nici cu
  rampă ascunsă nu ține; vârful se privește), Templul Lunii (pe partea
  nevăzută a vârfului — nu se face ce nu se vede), turiști (figuranți statici
  ar fi trebuit să fie sute ca să se citească; rămân rucsacurile și corturile
  de la gară), lame care fug de mașini (pulsul neînvățabil — își țin linia),
  vedere a șoferului (feelingul e pe chase cam; `CameraZone` e opțiunea de
  preset, decisă pe captură).
- **Fără slot nou de paletă.** `LARCH_RUST` 27 face queñualul, `MARBLE_GREY`
  29 granitul, `FLAMINGO_PINK` 31 orhideele; dacă albul granitului nu iese
  din `MARBLE_GREY` + `ROCK_LIGHT` cu benzi de valoare, se ia decizia „64 de
  sloturi" aici, explicit.
- **Panta se calculează înainte de a desena gimmick-ul:** 35 m pe 330 m dă
  10,6%; dacă ProbeLayout dă peste 13% după ce urcarea primește tunelul și
  S-urile, se lungește urcarea, nu se coboară Poarta Soarelui (sub 30 m
  cetatea nu mai e „sub tine").

## 9. Prompt pentru ChatGPT (dioramă de referință) — v0.1, paste-ready

Se atașează o captură a planului din §2 (harta „Machu Picchu Recon", de
făcut după ce traseul trece de ProbeLayout).

> Create a stylized low-poly **tabletop diorama** of a toy-car racing track
> at **Machu Picchu, Peru, on a crisp dry-season morning** — a white granite
> Inca citadel on a knife-edge ridge, stepped terraces, a sharp green peak
> at one end, and a deep river gorge with a cloud rising out of it. Use the
> attached top-down plan as the layout: same loop shape, same positions of
> the landmarks.
>
> **STYLE (strict):** faceted, flat-shaded low-poly meshes like a Blender
> viewport render — **no fine surface texture, no painterly brushwork, no
> photorealism**. Chunky toy proportions: cars are stubby and ~1.3× wider
> than real cars; llamas are simplified into big smooth blocks with a few
> facets. Soft baked ambient occlusion under every wall, tree and animal.
> Muted grey-and-green environment colors (~45% saturation) with only three
> saturated accents: the **blue-and-yellow train** in the gorge, the
> **yellow bus** on the switchbacks, and the toy cars. Lighting: a bright
> warm sun about 40° above the horizon, casting a **crisp dark stripe of
> shadow under every terrace wall** and lighting the white granite almost
> white; **a clear saturated Andean blue sky**, with a **soft white cloud
> bank lying low in the gorge** and one tongue of cloud climbing the cliff
> toward the road. Thin white haze in the far distance. Show the diorama
> on a thin dark rounded-rectangle table base, from a raised 3/4 view.
>
> **THE LAND [!]:** the diorama is a **narrow saddle ridge** with the
> citadel on top, a **sharp green peak (Huayna Picchu) rising ~30 m at the
> north end**, a taller rounded mountain shoulder at the south end with a
> stone gate on it, and **steep green cloud-forest walls dropping on both
> sides** into a gorge with a brown-green river with white rapids at the
> bottom. The east flank of the ridge is a **staircase of ten grass
> terraces** with white stone retaining walls. Twisted red-barked trees,
> tree ferns and mossy boulders grow on the slopes.
>
> **THE ROUTE — a single closed loop of about 2 km, clockwise, the gorge on
> the right along the ridge [!]:**
> 1. **Start/finish in the Sacred Plaza (top of the ridge, middle):** a
>    paved granite square between mortarless stone walls with trapezoid
>    niches, a wall with three trapezoid windows, a carved stone pillar on a
>    small mound, two llamas grazing.
> 2. **The Inca Trail up to the Sun Gate:** the road leaves the citadel and
>    **climbs on wide stone steps** along the south mountain's flank, the
>    gorge falling away on the right with no railing, a short rock tunnel,
>    and a **white cloud tongue climbing the cliff onto the road**.
> 3. **The Sun Gate and the ridge [!] — the biggest feature:** a stone
>    gateway with two rooms on the shoulder, a **condor perched on a rock**
>    beside it with wings spread; then the road turns and runs **down the
>    knife-edge ridge toward the peak**, drop-offs on both sides, past a
>    small stone house with a thatched roof — the whole citadel and its
>    terraces spread out below and ahead, the peak straight ahead.
> 4. **The terrace cascade:** the road zigzags down ten grass terraces on
>    ramps set into the white walls; one car is jumping straight down the
>    terraces instead; a line of llamas crosses one terrace; a staircase
>    of small stone fountains runs down beside them.
> 5. **The rope bridge [!] — the second biggest feature:** a **straw-colored
>    grass-rope suspension bridge** with a plank deck and rope handrails
>    spans a side gorge between two stone towers; it **sags deeply under a
>    big yellow bus-car in the middle** and a small red car near the end is
>    lifted on the bulge; the river with white rapids is far below.
> 6. **The river bank:** the road dips to the river past a tiny station
>    with tents and backpacks; a **blue-and-yellow train with roof windows**
>    runs along the bank on its own track, not crossing the road.
> 7. **The switchbacks:** an ochre dirt road climbs the cliff in five
>    hairpins between twisted red-barked trees; a **yellow-and-white bus is
>    coming down** the hairpins toward the cars, filling most of the road.
> 8. **The Inca Bridge ledge:** the road enters a narrow ledge cut into the
>    west cliff, crosses a **gap bridged by three wooden beams** (one car
>    jumping it), passes through a **trapezoid stone gateway**, and returns
>    to the plaza with the green peak right beside it.
>
> **CARS:** 6–8 chunky toy cars in saturated colors (red, blue, yellow, a
> white police car, a big red fire truck, a long yellow bus), spread around
> the loop, one drifting on the granite plaza. Nothing else on the diorama
> is saturated except the train and the bus.
