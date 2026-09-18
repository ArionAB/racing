# Valul 2 (C, D, H): 0 din 3 câștigate orb — și de ce toate trei au pierdut la fel

> Constatare de lead, 18 sep 2026, după rularea `tools/gauntlet/machu_val2.js`
> (18 agenți, 3 POI-uri × 3 runde constructor + critic orb).
> **Rezultat: 0/3.** Dar cele nouă verdicte nu sunt nouă probleme.

## 1. Cele nouă verdicte spun un singur lucru

Trei critici independenți, pe trei POI-uri diferite, în nouă runde, cu context
proaspăt de fiecare dată, au cerut **același lucru**:

| POI | verdictul (esența) |
|---|---|
| **C** r1 | „la noi e doar drum gol pe o **coamă verde uniformă**" |
| **C** r2 | „drumul e lipit de un **versant de iarbă** care urcă continuu" |
| **C** r3 | „**nu există buză**: drumul stă pe un umăr de deal verde continuu" |
| **D** r1 | zidurile „nu rețin nimic", sunt lespezi „pe o **pantă verde continuă**" |
| **D** r2 | „solul din spatele unui zid e **la aceeași cotă** cu cel din față" |
| **D** r3 | „nu sunt o masă continuă în trepte — ziduri-lespede **peste o panglică verde**" |
| **H** r1 | „**lipsește GOLUL**… de cealaltă parte terenul e [plat]" |
| **H** r2 | „**lipsește peretele și golul**: drumul trece peste o pajiște continuă" |
| **H** r3 | „partea golului **nu are stâncă**… o pantă verde blândă" |

Asta e exact semnalul din memoria `criticul-cere-ce-zona-nu-poate-da`:
**când același verdict se repetă, cauza e sub stratul la care lucrează
constructorul.** La valul 1 lecția a costat trei POI-uri × 3 runde. Aici a
costat trei POI-uri × 3 runde **încă o dată**, fiindcă verificarea de dinainte
de construcție a fost „are POI-ul o râpă declarată pe interval?" — răspuns DA
pentru toate trei — și întrebarea aia **nu e cea care contează**.

## 2. Ce contează, măsurat

Nu „există o râpă", ci **la câți metri de marginea asfaltului începe căderea**.
Sonda: `tools/SvMpBuza.tscn` (cât de departe lateral, dincolo de margine, până
cazi 3 / 10 / 25 m; „−" = nu se atinge nici la 60 m).

```
POI                parte   semi_lat   -3m    -10m   -25m
A 0.00-0.04        dr      9.00      -       -       -
A 0.00-0.04        st      9.00    80.8    87.5      -
B 0.04-0.20        dr      6.32    17.5    19.7    22.9
B 0.04-0.20        st      6.32    77.6    87.0      -
C 0.22-0.40        dr      6.42    11.2    17.5    24.1
C 0.22-0.40        st      6.42    21.0    39.0    89.2
D 0.42-0.54        dr      6.00    69.6    89.7      -     <<< POI D
D 0.42-0.54        st      6.00    67.7      -       -     <<< POI D
E 0.56-0.64        dr      7.15     2.6    28.1      -
E 0.56-0.64        st      7.15    40.8    59.6      -
F 0.66-0.72        dr      7.04    15.4    46.8      -
F 0.66-0.72        st      7.04    50.0    73.8      -
G 0.74-0.92        dr      6.50    27.5    38.2    81.1
G 0.74-0.92        st      6.50    12.7    29.0    84.8
H 0.94-1.00        dr      6.76      -       -       -     <<< POI H
H 0.94-1.00        st      6.76    11.6    51.4      -
```

**În referință căderea începe LA MARGINEA DRUMULUI.** La noi, prima cădere de
3 m e la 11–27 m dincolo de asfalt pe majoritatea POI-urilor, iar pe **D** la
**68–70 m**. Din mașină, cu ochiul la 10 m, între asfalt și gol se vede un
**șorț verde** de zeci de metri. De-asta toți criticii au scris „pajiște".

## 3. De ce, în cod

`track_side_sampler.gd`:

```
const RAVINE_INNER: float = 4.0    # râpă obișnuită: buza la 4 m de margine
const RAVINE_RIM:   float = 16.0   # …plus 16 m de racord = 20 m de rampă
const RAVINE_CORNICE_INNER: float = 0.5   # cornișă: buza LIPITĂ de asfalt
const RAVINE_CORNICE_RIM:   float = 6.0
```

O râpă fără flag de cornișă **nu e o faleză, e un taluz**: umăr de 4 m, apoi
rampă de 16 m. Comentariul din cod o spune deja („o cornișă obișnuită e o buză
urmată de o PANTĂ"). Cornișa e ce arată ca referința.

Maparea râpelor pe POI-uri (`custom_ravines`, cu `custom_cornice_ravines`):

| POI | râpe care îi ating intervalul |
|---|---|
| A | **niciuna** |
| B | 0 (dr) |
| C | 0 (dr), 1 (st) — indicele 1 a primit flag de cornișă **în valul ăsta** |
| **D** | **doar 2, cu `side = 0`** |
| E | 2 (ax), 3 (dr) |
| F | 3 (dr), 9 (dr) |
| G | 4, 5, 6, 7, 8, 9 |
| H | 4 (st) |

**Cazul D e cel mai clar.** Singura lui râpă, indicele 2, are `side = 0`, iar
`w == 0` sare filtrul de latură (`ravine_at`) — combinat cu flag-ul de viaduct,
sapă **SUB** drum, nu lângă el. Deci POI D **nu are nicio cădere laterală**, și
constructorul lui a avut dreptate când a refuzat să „repare" asta din zona lui:
nu era a lui. Criticul a avut și el dreptate: lipsea.

## 4. Ce NU e cauza

- **Nu e lenea constructorilor.** Toți trei au raportat cinstit unde se opresc,
  cu măsurători. C a găsit singur că `inca_wall_c` are 2,00 m, nu 6,00, și că
  toate `moss_boulder_*` poartă slotul 12 (deci ieșeau pete verzi în iarbă).
  D a **construit** varianta cu trepte late cerută de bară, a capturat-o lângă
  cea densă, a constatat că citește mai prost pe banda de 6,6 m disponibilă, și
  s-a întors la varianta mai bine judecată. H a confirmat contractul porții pe
  fereastra corectă.
- **Nu e lipsa pieselor.** Cele trei POI-uri au pus 187 + 175 + ~200 de piese,
  cu **zero materiale noi** (19, neschimbat) și toate gărzile pe linia de bază.
- **Nu e bara greșit citită.** Verdictele sunt despre materie și siluetă, exact
  ce cere protocolul, nu despre layout.

## 5. Ce s-a făcut (18 sep 2026)

> Secțiunea a fost scrisă ca listă de opțiuni. Între timp s-a și **măsurat**,
> iar diagnosticul de mai sus s-a dovedit **doar pe jumătate corect**.

**Corecție la §2–3.** `SvMpSapa` (cotă drum vs cotă sol la +1/+4/+10 m) arată
că **POI C are căderea**: −1,6 m la +1 m, dar **−13,1 m la +4 m** și
**−30,7 m la +10 m**. Deci pe C nu lipsea terenul. **POI D chiar e plat**
(−12,7 la drum, −12,2 la +10 m) — acolo diagnosticul stă în picioare.

**Cauza reală pe C, G, H: contrastul, nu geometria.** Fața căderii, versantul
de dincolo și fundalul aveau **toate** `ground_tint` #5F6B3E. O prăpastie și o
pajiște fără diferență de culoare sunt aceeași suprafață pentru ochi.
Constructorul lui C o scrisese în raport: *„nu lipsește căderea, lipsește
CONTRASTUL care o face citibilă."*

**Rezolvat** (decizia dezvoltatorului, cheia `scarp_tint`): față de stâncă
după **pantă**, nu după cotă — `rock_band_tint` exista, dar se ia din
`v.y - rock_line`, iar golurile de aici coboară SUB drum, deci nicio linie de
nivel nu le prinde. Cost: **zero materiale**; celelalte piste au cifre
identice. Două lucruri găsite pe captură, nu prin raționament: panta per
**celulă** dă pătrate (se ia per vertex), iar prima tentă **se aplica dar nu se
vedea** (verificat pe vertex colors). Memoria: `contrastul-nu-geometria`.

### Ce rămâne de decis (tot teren)

1. **Flag de cornișă pe râpele POI-urilor care n-au** — cel mai ieftin, o linie
   în `custom_cornice_ravines`. Mută buza de la 4 m la 0,5 m. Nu schimbă
   traseul, deci ProbeLayout nu se mișcă. **Se verifică pe captură**, nu pe
   cifră.
2. **Râpă nouă pentru D** (și una declarată pentru A), cu latură reală, nu
   `side = 0`. D are nevoie de gol lateral ca terasele să aibă pe ce cădea.
3. **De verificat la fiecare:** `ProbeRace` pe felie înainte/după — o buză la
   0,5 m de asfalt e o buză de pe care se cade, și memoria
   `zero-repuneri-ascunde-blocajul` spune să citim și `[blocaj]`/lent/offroad.

**Regula de proces care lipsea, și care se adaugă în gauntlet:** înainte de a
porni un constructor pe un POI, nu se întreabă „are râpă pe interval?", ci se
rulează `SvMpBuza` și se citește **distanța de la margine până la cădere**.
Peste ~8 m, POI-ul nu poate câștiga orb indiferent câte piese primește, și
constructorul va arde rundele pe ceva ce nu ține de el.
