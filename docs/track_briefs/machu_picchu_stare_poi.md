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
| ProbeRace | `res://tools/ProbeRace.tscn -- --mode=race --track=8 --seconds=150 --seed=N` | **0 repuneri pe seed 1, 3, 4**; seed 2 dă 0/1/3 (vezi §3.6) |

Binar: `D:\GameDev\Godot_v4.7-stable_win64_console.exe`.
**`probe_decor` ia `--track=15` (număr de scenă); toate celelalte iau
`--track=8` (index).** `probe_decor --track=8` măsoară Okinawa și dă verde.

## 3. Ce a rămas de făcut

### 3.1 Decizia care blochează restul: plafonul de materiale

**Suntem la 20 din 20**, cu cinci POI-uri nefăcute. Garda propriu-zisă pică
abia la **38**.

Plafonul de 20 din brief §6 a fost pus când se credea că fiecare GLB costă un
material. **E fals, măsurat**: kitul de 39 de piese costă **zero** materiale
(toate pe atlas), iar ce costă e **clasa de textură**, unu per clasă indiferent
de câte piese o poartă. Deci cifra 20 nu mai descrie ce se credea că descrie.

**Nu s-a luat decizia asta** — e a dezvoltatorului. Variantele:
(a) 20 rămâne linie fermă, iar POI-urile rămase refolosesc clasele existente;
(b) plafonul urcă explicit, cu motivul scris, până undeva sub 38.
Până se decide, valul 2 are în prompt instrucțiunea să nu adauge materiale în
tăcere.

### 3.2 POI-uri nefăcute: B, C, D, E, H

Contractele lor sunt scrise în `machu_picchu_poi_gauntlet.md` (ce se vede în
decupajul barei + ce cere brief-ul + capcana specifică).
**Toate cinci au râpă pe intervalul lor**, deci n-ar trebui să lovească
problema valului 1 — dar se verifică pe survey înainte de a construi.

Worktree-urile există deja: `D:/GameDev/wt-mp-<poi>`, branch `feat/mp-poi-<poi>`,
toate pe main-ul curent.

Valul 2 (C, D, H) e **scris și gata de lansat**:
`<scratchpad>/val2.js` — harnașamentul e cel de la valul 1 (constructor +
critic orb pe `blind_pair.py`, buclă de 3 runde), cu contractele celor trei
POI-uri și cu lecțiile valului 1 în prompt.

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

### 3.4 Două lucruri deschise — unul închis, unul încă deschis

- **`main_gate`: ÎNCHIS. Cele trei cifre sunt trei tăieturi prin aceeași piesă,
  nu o contradicție.** Ușciorii sunt în TALUZ — poarta e trapezoidală, cum o
  descrie chiar brief-ul — deci golul se strâmtează cu înălțimea. Măsurat de POI
  H cu `tools/ProbeMpHGate.tscn` (proiecția triunghiurilor pe planul
  (lateral, y), grilă de 1 cm, memoria `cota-de-contract-se-masoara-ca-gol`):

  | fereastră pe y | gol liber | cifra din inventar |
  |---|---:|---|
  | 0,15–0,60 m | **8,300 m** | „8,390 bază" |
  | 0,15–1,80 m (**gabaritul mașinii**) | **8,120 m** | — |
  | 0,15–5,80 m (până sub buiandrug) | **7,420 m** | „7,410 sus", și 7,39 din §3 |

  `masuratori.md` §3 a măsurat până sub buiandrug și a citit corect 7,39 — dar
  mașina nu trece pe la 5,8 m înălțime. În fereastra pe care o ocupă caroseria
  golul e **8,120 m pe un drum de 8,00 m**, deci brief-ul se **confirmă** cu
  marjă +0,12 m. Poarta rămâne la scara 1: „corectată" la 8,0 s-ar pierde marja.
  Verificat și dinamic, nu doar geometric (memoria
  `proberace-la-inceput-nu-la-final`): ProbeRace seed 1/2/3 pe scena cu poarta
  plantată dă **0 repuneri, offroad max 0,0%**.
- **Bârnele Podului Incaș aduc rampele podului mobil. ÎNCĂ DESCHIS — e teren,
  nu decor.** Reuse-ul `LiftBridgeHazard` pune un dâmb de 1,6 m pe cornișă, iar
  sub gol terenul rămâne la −0,3 m. Verificat pe captură de POI H
  (`--bridge-at=0.24`, `H_FINAL_f09435.png`): cu bârnele ridicate profilul
  citește **o rampă maro lătă peste drum**, nu „bârne peste gol", și nu se vede
  nicio prăpastie dedesubt — exact cum o descrie brief-ul §3, care cere
  săpătură locală de 4 m. **Nefăcut, și nu s-a mascat cu decor**: e o modificare
  de teren, iar traseul a trecut deja ProbeLayout. Ce a făcut decorul e să pună
  piatră pe buzele golului, ca marginea să aibă capete de stâncă.

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
