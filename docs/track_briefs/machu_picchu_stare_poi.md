# Machu Picchu (Track15) — starea decorului, și ce a rămas

> Notă de predare, 16 sep 2026. Sesiunea s-a oprit deliberat după terminarea
> agenților în lucru, nu la un punct de finalizare. Tot ce e descris aici e
> **comis**; ce nu e comis e spus ca atare.
>
> Bara vizuală e `docs/track_briefs/img/machu_picchu_v3.jpeg`, decupată per POI
> în `docs/track_briefs/img/bar_machu/` (`tools/bar/crop_machu_bar.py`).
> Contractul per POI e în `machu_picchu_poi_gauntlet.md`.

## 1. Ce e gata și merge-uit pe main

### Bucata 0 — fundația (PR-ul `feat/mp-fundatie`, 8 commit-uri)

- **Kitul de 39 de GLB-uri e înregistrat și plasabil**: `ext_resource` cu
  id-uri `s_<stem>` în `Track15.tscn`, `DecorManual` cu cele 8 zone
  (`ZoneA_PiataSacra` … `ZoneH_Cornisa`), `PROP_COLLISION` completat pe
  măsurătoare, stem-urile în `KNOWN` din `probe_decor.gd`.
- **Inventarul tehnic măsurat**: `docs/asset_briefs/machu_picchu_masuratori.md`
  — nume reale de noduri, histogramă de sloturi per nod, înălțimi, raze,
  moduri de coliziune cu motiv. **E sursa de adevăr**, nu brief-ul: brief-ul
  greșise deja de două ori la kitul ăsta.
- **Cele 3 piese cu consumator sunt cablate**: `consettur_bus` pe
  `AutobuzConsettur` (cutia vine din AABB, 3,66 m), `perurail_train` pe
  `TrenPeruRail` (cele 3 noduri găsite după nume exact — nu cade pe cutii),
  `llama/_b/_c` pe `Lama1..4`.
- **Clasa `inca_stone`** (tentă și lift calculate din media ponderată pe arie
  a sloturilor de zidărie, pe dala existentă `alpine_granite` — zero VRAM nou).
- **`ProbeLaneClear` e ARMATĂ** pentru Track15 și verificată prin sabotaj.

### Runda 2 a valului 1 (ultima rulare a sesiunii)

Cei trei constructori au mai livrat o rundă pe terenul reparat, înainte ca
sesiunea să se oprească:

- **A** — terasele au acum **podea**, nu doar ziduri: platforme de iarbă la
  cote diferite, fețe de sprijin vizibile, scări între niveluri. Exact ce
  ceruse criticul orb de trei runde („nu închid un **plan orizontal**").
- **G** — zidul se face din **asize**, nu dintr-o piesă întinsă (criticul citea
  „lespezi" fiindcă piesele traversau muchia).
- **F** — râul s-a mutat din platou **în gorjă**, pe cornișa adăugată la
  integrare.

Materialele au **scăzut** la 19 (de la 20) deși prop-urile au crescut de la
3232 la 3880 — constructorii au consolidat, n-au adăugat. Deci mai e o unitate
de marjă sub plafonul cerut.

**Niciunul n-a ajuns la criticul orb în runda asta** — sesiunea s-a oprit
la granița dintre constructori și critici, deliberat.

### Valul 1 — POI-urile A, G, F (merge-uite, dar **nu terminate**)

Decor plasat în cele trei zone, plus două reparații de nivel de pistă pe care
niciun constructor nu le putea face din zona lui:

- **Relief pe F și G.** Cele trei POI-uri ale valului erau singurele zone din
  tur **fără nicio râpă declarată** — de aceea citeau a pajiște, și de aceea
  POI F n-avea râu deloc. S-au adăugat patru **scarpe** pe ace (indici 5–8,
  parte alternantă 1/−1/1/−1, fiindcă pe serpentină exteriorul schimbă latura
  la fiecare ac) și o **cornișă** pe malul râului (indice 9).
  Măsurat la 10 m de ax: frac 0.80 de la −0,0 m la **−9,4 m**; 0.84 de la −0,6
  la **−13,6**; 0.70 (F) de la +0,8 la **−6,9**.
- **Clasele de zidărie complete.** Lipseau `inca_wall_c` (zidul de înlănțuire —
  același gard se randa în două materiale), `sun_temple`, `three_windows`,
  `intihuatana`, `main_gate`, `inti_punku`. Cost: **zero materiale** (clasa e
  cache-uită per clasă).

## 2. Cifrele de plecare pentru orice sesiune următoare

Măsurate pe main, după `--import`. **Astea sunt referința de regresie.**

| gardă | comandă | cifră |
|---|---|---|
| probe_decor | `--script res://tools/probe_decor.gd -- --track=15` | **19 materiale**, 3880 prop, 601 804 tri |
| ProbeBuried | `res://tools/ProbeBuried.tscn -- --track=8` | 0 îngropate, 0 tavane |
| ProbeLaneClear | `res://tools/ProbeLaneClear.tscn -- --track=8` | **18**, linia de bază 20 |
| ProbeLayout | `res://tools/ProbeLayout.tscn -- --track=8` | 1986,4 m, rază 9,0 m @0.41, **pantă 11,5 % @0.16** |
| ProbeRace | `res://tools/ProbeRace.tscn -- --mode=race --track=8 --seconds=150 --seed=N` | **0 repuneri pe seed 1, 3, 4, 5, 7**; seed 2 dă 0/1/1/2 pe 4 rulări — cauza e **diagnosticată**, vezi §3.6 |

Binar: `D:\GameDev\Godot_v4.7-stable_win64_console.exe`.
**`probe_decor` ia `--track=15` (număr de scenă); toate celelalte iau
`--track=8` (index).** `probe_decor --track=8` măsoară Okinawa și dă verde.

## 3. Ce a rămas de făcut

### 3.1 ~~Decizia care blochează restul~~ — **LUATĂ (18 sep 2026): plafonul e 30**

Dezvoltatorul a ridicat plafonul de materiale de la 20 la **30**, cu motivul
scris în `machu_picchu.md` §6. Garda propriu-zisă rămâne la 38.

Cifra veche de 20 fusese pusă când se credea că fiecare GLB costă un material.
**E fals, măsurat**: kitul de 39 de piese costă **zero** (toate pe atlas); ce
costă e **clasa de textură**, unu per clasă. Comparativ, pe pistele deja
livrate (`probe_decor` fără `--track`, o rulare le dă pe toate): Cappadocia
**21**, Track01 **23**, Baikal **23**, Track09 **26**, Serengeti **31**,
Stromboli **32**, Chongqing **32**. Machu Picchu era la **19** cu cinci POI-uri
nefăcute — **cea mai ieftină pistă din joc**.

**Plafonul nu e o alocație de cheltuit.** Rămâne regula că un material nou se
cere **explicit în raport**, cu motivul și cu ce cumpără vizual; ce se poate
refolosi, se refolosește. Marja e acolo ca un POI care chiar are nevoie — apa
la E, ceța norului la B — să nu se blocheze.
Memorie: `plafon-masurat-nu-presupus`.

### 3.2 POI-uri nefăcute: B, C, D, E, H

Contractele lor sunt scrise în `machu_picchu_poi_gauntlet.md` (ce se vede în
decupajul barei + ce cere brief-ul + capcana specifică).
**Toate cinci au râpă pe intervalul lor**, deci n-ar trebui să lovească
problema valului 1 — dar se verifică pe survey înainte de a construi.

Worktree-urile există deja: `D:/GameDev/wt-mp-<poi>`, branch `feat/mp-poi-<poi>`,
toate pe main-ul curent.

Valul 2 (C, D, H) e **comis în repo** la `tools/gauntlet/machu_val2.js` și a
fost **lansat pe 18 sep 2026** — harnașamentul e cel de la valul 1 (constructor
+ critic orb pe `blind_pair.py`, buclă de 3 runde), cu contractele celor trei
POI-uri și cu lecțiile valului 1 în prompt. Cifrele de plecare din prompt au
fost **remăsurate pe main** înainte de lansare.

Rămân pentru un val 3: **B** (și vezi §3.6 — coama e diagnosticată, dar decizia
nu e a constructorului) și **E** (podul; POI-ul nu construiește podul, ci
malurile — vezi contractul).

### 3.3 POI F se reia, nu se ajustează

POI F (malul râului) e **cel mai slab** din val. Constructorul a mers 26 de
runde interne încercând să așeze un râu pe teren plat (cornișa n-a existat
până la integrare), și a **derivat**: runda 9 avea un râu vizibil cu bolovani
și apă turcoaz, runda 26 e mai slabă — apa citește ca pete gri cu stropi albi.
Albia e așezată pe cotele terenului **vechi**, deci stă pe platou în loc de
defileu.

Se reia de la cea mai bine judecată stare, pe terenul nou
(memoria `revenirea-e-o-mutare-valida`). Apa: memoriile `apa-iluminata-v12`
(pata gri = pânză opacă, lipsește Fresnel-ul din chase cam) și
`strop-apa-particule`.

### 3.4 Două lucruri deschise, măsurate și nerezolvate

- **`main_gate` are 7,39 m liber, nu 8,39.** Deschiderea reală între uşciori,
  măsurată prin proiecția triunghiurilor, e constantă de la sol până sub
  buiandrug. Inventarul scrie trei cifre (8,390 / 7,410 / 6,000) care nu
  descriu piesa. Brief-ul pistei cere **8 m** la bază pentru îmbrânceala cu 4
  mașini la POI H. **Nu s-a corectat nimic în tăcere** — se verifică cu
  ProbeRace (`--slice=0.92,1.00`) când POI H plantează poarta, și abia atunci
  se decide: se lărgește piesa, se lărgește drumul, sau se acceptă cifra.
- **Bârnele Podului Incaș aduc rampele podului mobil.** Reuse-ul
  `LiftBridgeHazard` pune un dâmb de 1,6 m pe cornișă (profilul nu mai citește
  „bârne peste gol"), iar sub gol terenul rămâne la −0,3 m, deci nu e
  prăpastie. Brief-ul §3 spune că cere săpătură locală de 4 m. Nefăcut.

### 3.6 O slăbiciune reală la frac 0.187–0.190 (POI B, neconstruit)

Seed 2 rulat de **trei ori** a dat 0, 1 și 3 repuneri — deci nedeterminism
Jolt, cum era de așteptat (memoria `proberace-nedeterminism`). **Dar locul nu e
aleatoriu**: repunerile se grupează la frac **0.187–0.190**, cota +36 m,
pozițiile (244…246, 36, 124…129). Aia e coama urcării pe treptele Drumului
Incaș — adică **POI B, pe care nu l-a construit încă nimeni**. Mașinile ies în
afară acolo. A treia rulare a arătat și o repunere la frac 0.554 (podul de
frânghie).

Pe seed-urile 1, 3, 4: **0 repuneri**.

Nu s-a reparat, fiindcă e în intervalul lui B și se face când se construiește
B, cu `ProbeRace --slice=0.15,0.22` înainte și după. Scris ca să nu se piardă:
e prima repunere reproductibilă ca **loc** din toată sesiunea.

### 3.5 Niciun POI n-a câștigat încă orb

Ăsta e criteriul de terminare și **nu e atins de niciunul**. Criticii au ghicit
corect de fiecare dată care e captura noastră.

Dar verdictele lor sunt utile și specifice, nu vagi:
- **A:** „zidurile nu închid nimic, și mai ales nu închid un **plan orizontal**
  — în referință ce se închide are **podea**: platformă de iarbă la altă cotă,
  cu fața de sprijin vizibilă și o scară între niveluri."
- **G:** „zidul de sprijin e pe partea **greșită** — la noi pe marginea dinspre
  munte ca o bordură de grădină; în referință pe **exterior**, cu suprafața
  drumului terminându-se exact pe el și fața lui căzând în gol."

Ambele erau imposibil de reparat înainte (nu exista gol, nu existau cote).
**Acum sunt reparabile**, iar bucla a fost relansată exact pe ele.

#### DIAGNOSTICAT (18 sep 2026): e **coama**, nu marginea

Cauza e găsită și măsurată. Nu e nevoie să se mai caute.

**Reproducerea.** Seed 2 rulat de patru ori: **2, 0, 1, 1** repuneri. Primele
trei rulări ale zilei dăduseră 0 — deci *trei* rulări curate nu sunt o
dovadă că a dispărut (memoria `proberace-nedeterminism`). Un eveniment prins:
`[repunere] t=23.3s Kai (Taxi) frac=0.186 poz=(243,36,130)`.

**Unde cădea, de fapt.** Prima ipoteză — mașina iese pe dreapta, în defileu —
**e falsă**. Poziția repunerii, proiectată pe ax: offset lateral **−0,19 m**,
adică **pe mijlocul drumului**, la 6,31 m *înăuntru* față de margine — și la
**+1,2 m deasupra axului**. Mașina nu era pe prăpastie; era **în aer**.

**Cauza: coama.** Profilul longitudinal (pas de ~3 m) arată exact la frac
**0.186** răsturnarea pantei:

| frac | cotă ax | pantă |
|---|---:|---:|
| 0.160 | +31,6 | **+11,6 %** |
| 0.180 | +34,7 | +3,3 % |
| **0.186** | **+34,8** | **−1,1 %**  ← coama |
| 0.200 | +33,7 | −7,8 % |
| 0.210 | +32,0 | **−9,5 %** |

Adică o răsturnare de **~21 de puncte de pantă** (+11,5 → −9,5) pe ~25 m.
`ProbeLayout` raportează panta maximă a pistei **11,5 % la frac 0.16** — chiar
înaintea coamei. O mașină care urcă cu viteză **decolează peste vârf** și
aterizează pe o coborâre de −9,5 % care îi fuge de sub roți.

E comportamentul așteptat la **fizica întreagă**: memoria
`car-nu-e-lansat-de-panta` e marcată ISTORIC tocmai fiindcă la `RigidBody3D`
panta **chiar** lansează (M3.75). Nu e un defect de decor și **nu e ceva ce
poate repara constructorul lui B din zona lui**.

**Ce NU e cauza** (verificat, ca să nu se mai testeze):
- *treptele* — `custom_step_ranges` (0.0405–0.2034) acoperă zona, dar treptele
  **nu există în coliziune** (`track.gd:_step_ranges`, comentariul e explicit);
  tot ce fac e ±3 cm de zgomot pe raycast (`Car.STEP_NOISE_M`) — nu ridică o
  mașină cu 1,2 m;
- *marginea din dreapta* — cade brutal (−1,9 m la 1 m, −20…−45 m la 2 m, pe
  tot intervalul), dar repunerea e pe **mijloc**, nu pe margine. Căderea e
  intenția brief-ului („pe dreapta fără parapet, defileul"), nu un bug.

**Decizia rămâne deschisă, e de gameplay, nu de decor.** Opțiuni:
(a) se **acceptă** — e un salt pe cea mai abruptă urcare din tur, deci e
    exact „elevație folosită agresiv" din CLAUDE.md, iar 1 repunere la ~3
    rulări e a unui AI, nu a jucătorului (mașina jucătorului: 0);
(b) se **îmblanzește coama** — se întinde răsturnarea pe mai mulți metri din
    `Path3D`, ceea ce atinge traseul (a trecut deja ProbeLayout) — deci nu e
    treaba unui constructor de POI;
(c) se **lațește aterizarea** — semi-lățimea e deja 6,5 acolo.

Se măsoară cu `ProbeRace --seed=2`, **de cel puțin 4 ori**, înainte și după.
O singură rulare verde nu înseamnă nimic aici.

Sonda de măsură: `tools/SvMpB.tscn` (profil lateral + căderea față de margine).

**Și e SINGURA coamă de pe pistă.** Inventarul pe tot turul
(`tools/SvMpCoame.tscn`: răsturnare de semn a pantei, fereastră ±8 indici,
prag ±3 %) găsește **exact una**, la frac **0.185**, amplitudine 8,3 puncte pe
fereastra scurtă. Singurul loc cu repuneri reproductibile din tot turul
coincide cu singura coamă din tot turul — nu mai e o corelație, e mecanismul.

## 4. Lecția de metodă care merită dusă mai departe

**Când criticul orb repetă același verdict de două ori aproape neschimbat,
oprește bucla și verifică stratul de dedesubt.** Nu constructorul e slab — i se
cere ceva ce bucata lui nu poate produce prin construcție. La valul 1 asta a
costat trei POI-uri × 3 runde plus 26 de runde interne pe F, toate pe teren
care n-avea relief. Verdictele identice sunt un semnal despre **sistem**, nu
despre muncă.

Salvată ca memorie: `criticul-cere-ce-zona-nu-poate-da`.

Celelalte memorii scrise în sesiunea asta:
`probe-decor-numar-de-scena`, `garda-fara-linie-de-baza-iese-zero`,
`garda-verde-pe-zero-masuratori`, `scala-glb-neaplicata-la-radacina`,
`cota-de-contract-se-masoara-ca-gol`, `zero-repuneri-ascunde-blocajul`.
