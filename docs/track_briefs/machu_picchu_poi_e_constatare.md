# POI E (Podul de frânghie) — runda 1-2, ce s-a măsurat și ce rămâne

> Constatare de constructor, 18 sep 2026, branch `feat/mp-poi-e`.
> Zona pornea de la **0 noduri**. Acum are **1649 de piese**, 19 materiale.

## 1. Premisa cu care am pornit era greșită, și am măsurat-o înainte să construiesc

Brief-ul și captura de la 0.60 spuneau „podul citește ca o pajiște plată,
tablierul e la nivelul solului, fără defileu". **Prima jumătate e adevărată,
a doua nu.**

Cu raza filtrată pe RID-ul lui `TerrainBody` (capcana lui E: o rază verticală
sub tablier lovește `Plate3`/`Plate7`, corpurile `AnimatableBody3D` ale
hazardului, și raportează „gol 0"):

```
POD near (31,-20,-155) frac 0.5482  SOL -33.74  => gol 13.74 m
    mid  (14,-20,-155) frac 0.5572  SOL -40.30  => gol 20.30 m
    far  ( -3,-20,-155) frac 0.5662 SOL -40.30  => gol 20.30 m
```

Brief-ul cere 20 m sub tablier. **Îi aveam deja.** Și fracțiile din contract
(0.57 / 0.60 / 0.63) sunt **după** pod — podul e la 0.548-0.566. De aceea
captura de la 0.60 arăta o pajiște: se uita în altă parte.

Sondele: `tools/gen_decor_mp_e.gd --survey`, `tools/SvMpE2.tscn`,
`tools/SvMpE3.tscn`.

## 2. Ce lipsea de fapt, măsurat

**(a) Golul e un BAZIN, nu o crăpătură.** Podeaua plată la -40.30 ține pe
z = -205..-105 (100 m) și x = -28..+20 (48 m). În bară defileul e o fantă
îngustă cu un fir de apă albă.

**(b) Pereții sunt RAMPE, nu falezе.** Măsurat de la mijloc:

```
spre +X: 16 / 28 / 38 / 22 grade pe primii 40 m
spre -X: 25 / 28 / 32 grade
spre ±Z: 33 / 59 grade
```

`scarp_tint` (tema `machupicchu`, `track.gd:992`) pornește la
`scarp_slope_deg = 28` cu `scarp_fade_deg = 10`, deci rocă plină abia la 38.
**Pe fâșia de 16-28 de grade — exact cea pe care o vezi venind spre pod —
tenta de stâncă e zero sau parțială.** Asta e lecția valului 2 cu un etaj mai
jos: `scarp_tint` a reparat pantele abrupte, dar nu și rampele.

**(c) Podeaua de 100x48 m era complet goală**, deci gaura n-avea SCARĂ.

## 3. Ce am construit, și de ce ASTA și nu relief

Nu am atins nici tema (`scarp_slope_deg` e al întregii piste — coborât la 16
ar face stâncă din toate dealurile domoale din tur, inclusiv POI-uri deja
judecate), nici traseul.

- **Râul** pe podeaua de la -40.30, cu spumă pe pietre — firul alb din bară,
  și singurul lucru care dă scară unei găuri de 20 m.
- **Piatră pe fâșia de 9-34 de grade**, unde tenta nu ajunge (430 de bolovani).
- **Vegetație pe cele două buze** (165 de piese), coroana care desenează muchia.
- **Bolovani de ancoraj** la capetele tablierului, ca podul să plece de pe
  stâncă, nu din iarbă.

**POI-ul E nu construiește podul** (contract): tablierul, cablurile și
turnurile sunt în cod (`rope_bridge_hazard.gd`). N-am atins hazardul.

## 4. Cifrele de culoare, față de bară

Sonda: `masoara.py` (clasifică pixelii pe familii — piatră / verde / apă /
spumă — și dă HSV + acoperire).

| | bară | plecare (0.556) | acum (0.556) |
|---|---|---|---|
| piatră, acoperire | 38,3 % | 29,7 % | **39,5 %** |
| piatră, H/S/V | 38,3 / 0,44 / 0,59 | 35,2 / 0,43 / 0,47 | **35,4 / 0,46 / 0,56** |
| piatră, R−B | +65,6 | +51,1 | **+65,6** |
| verde, acoperire | 6,9 % | 45,0 % | 27,7 % |
| apă, acoperire | 30,5 % | 10,0 % | 18,9 % |
| apă, S | 0,03 | 0,08 | 0,08 |

**Piatra aterizează.** Și e o corecție de impresie: prima mea citire a barei
a fost „bolovanii noștri sunt nisipii, bara e gri" — **fals**. Bara e ea
însăși ocru cald (H 38, R−B +66); albastrul pe care îl vedeam era ceața
depărtării. `inca_stone` era corect de la început, iar defectul real era de
**SCARĂ**: doi bolovani de ~10 m flancau drumul ca niște dune și acopereau
chiar defileul pe care trebuiau să-l descrie.

## 5. Un material luat și dat înapoi

Runda 2 pusese clasa `macchia` pe coamă, cu argumentul scris în comentariu că
„e deja în cele 19 materiale". **Măsurat după: `probe_decor` a urcat la 20 —
deci nu era** (memoria `justificarea-din-comentariu-se-verifică`). Și n-a
cumpărat nimic: verdele a rămas V 0,63 / 27,7 % față de V 0,61 / 26,7 %.
Fiindcă verdele din cadru e **iarbă de teren**, nu frunzișul meu: 165 de
copaci nu mișcă un versant întreg. Un material care nu cumpără nimic se dă
înapoi.

## 6. Ce rămâne deschis, cinstit

1. **Verdele e încă de 4 ori peste bară** (27,7 % față de 6,9 %, V 0,63 față
   de 0,29). E tenta de iarbă a **temei**, nu decorul meu — un POI nu o poate
   repara din zona lui. E aceeași clasă de problemă ca `scarp_tint` la valul 2.
2. **Apa are nuanța încă pe partea caldă** (H 64,8 față de 208 pe bară), deși
   saturația și valoarea aterizează (S 0,08 / V 0,41 față de 0,03 / 0,39).
   Cauza e stratul de detaliu triplanar al lumii, care e cald și se vede ca un
   tipar de vârtejuri pe plăci — apa citește ca asfalt texturat. O clasă plată
   ar repara-o, dar costă +1 material și **nu o cer fără mandat**.
   Mecanismul cu plăci e cel pe care îl are și POI F; shaderul v12 real e
   stins pe temă (`"water": false`), fiindcă ar inunda toată pista.
3. **Afundarea nu se vede din mașină, deși EXISTĂ.** Verificat pe captură, nu
   numărând (memoria `efecte-invizibile-nu-se-numără`):
   `--rope-load=2.6,0.5` dă **săgeată 1,50 m**, `--rope-load=0.0,0.5` dă
   **0,01 m** — exact ce cere brief-ul. Dar între cele două capturi diferă
   **0,58 % din pixeli**, iar întinderea randată a tablierului e identică
   (rândurile 134-416 în ambele). Motivul e unghiul: de pe chase cam privești
   **în lungul** tablierului, iar o coborâre de 1,5 m la mijlocul unei
   deschideri de 34 m nu subîntinde aproape nimic. E o observație despre
   **cadru**, nu un defect al hazardului — și nu e reparabilă din decor.

## 7. Runda 3 — criticul are dreptate, si cauza e MASURATA, nu de impresie

Verdictul orb: „podul nu exista ca obiect — tablier maro plat la nivelul
solului, doua sfori galbene, fara turnuri, fara scanduri, fara catenara".
**Am masurat fiecare din cele trei, si toate trei sunt in COD, nu in decor.**

### (1) Turnurile sunt sub linia ochiului — nu pot rupe orizontul

`rope_bridge_hazard.gd:102-103`: `TOWER_SIZE = (1.2, 3.9, 1.2)`,
`TOWER_SINK = 1.5`. Deci **2,4 m vizibili** deasupra tablierului, pe o
latime de 1,2 m, langa un tablier de **11 m** latime (`deck_width = 11.0`,
Track15.tscn:98) si 34,24 m lungime.

Cota, exact:

```
varful turnului : deck - 1.5 + 3.9 = deck + 2.4  =>  y = -17.60
ochiul chase cam: deck + 3.2                     =>  y = -16.80
```

**Turnul e cu 0,80 m SUB ochiul camerei.** Nu e o problema de umbrire sau de
tenta: geometric nu are cum sa taie linia orizontului, fiindca se termina sub
ea. Unghiul subintins, fata de un turn ca in bara (~10 m, adica ~3x
autobuzul):

| distanta | acum (2,4 m) | bara (10 m) | raport |
|---|---|---|---|
| 10 m | 13,50 deg | 45,00 deg | 3,3x |
| 20 m |  6,84 deg | 26,57 deg | 3,9x |
| 34 m |  4,04 deg | 16,39 deg | 4,1x |

### (2) Scandurile exista ca geometrie, dar n-au NICIUN contrast

Pasul de scandura e rezolvabil pe ecran — nu asta e lipsa:

```
 5 m: 38,3 px/scandura     20 m: 2,4 px
10 m:  9,6 px/scandura     34 m: 0,8 px
```

Lipsa e de **valoare**. `_build_visual` da fiecarei scanduri o singura culoare
de vertex, `shade = 0.82 + 0.18 * fmod(k*0.618, 1)`, iar `_box` o scrie
identic pe toate cele 8 varfuri (`rope_bridge_hazard.gd:399`). Toate scandurile
stau pe **acelasi texel** din atlas (`Palette.uv(WOOD_SLOT)`), cu fata de sus
plana si normala unica. Rezulta o suprafata maro uniforma, cu o unduire de
valoare de cel mult 18 % — sub pragul la care ochiul citeste „scanduri".

Iar fanta dintre ele (`PLANK_GAP = 0.06`) nu ajuta: la unghiul razant din
chase cam se deschide 0,09 m la 5 m si 0,19 m la 10 m, pe o grosime de placa
de 0,16 m — practic inchisa, si oricum fara nimic intunecat dedesubt.

### (3) Cablurile nu cad — sunt drepte prin constructie

`_build_visual` aseaza cablul portant la `y = -PLANK_THICKNESS - 0.1`
**constant pe toata lungimea**, si balustrada la `RAIL_HEIGHT = 1.0`
constant. Amandoua sunt paralele cu tablierul, deci se deformeaza **impreuna
cu el** in vertex shader (`deck_drop(u)` se aplica la fel tuturor vertecsilor
de la acelasi `u`). O catenara adevarata cere ca **cablul sa urce spre
capete** in timp ce tablierul ramane jos — adica un termen care sa creasca
spre `u = 0` si `u = 1`, exact opusul lui `P(u) = 4u(1-u)`.

Cele doua „sfori galbene intinse drept" pe care le vede criticul sunt chiar
balustradele: slotul 13 (`DRY_VEGETATION`) e galben-pai, si sunt drepte
fiindca urmeaza tablierul.

### Ce inseamna asta pentru contractul POI-ului

Contractul spune „POI E nu construieste podul" — si e corect ca **decorul nu
trebuie sa dubleze podul**. Dar cele trei defecte pe care le numeste criticul
sunt toate in `rope_bridge_hazard.gd`, si niciunul nu e reparabil din
`DecorManual/ZoneE_Pod`: un turn pus ca prop langa tablier n-ar urma
deformarea, iar scandurile si catenara sunt vertecsi ai mesh-ului podului.

**Nu comit nimic in hazard fara mandat** (e gimmickul pistei, cu fizica
calibrata si garzi proprii — `tools/probe_machu_pod.gd`). Ridic intrebarea,
cu cifrele de mai sus.

## 8. Garzile din runda 3, pe scena integrata din worktree

Rulate dupa `--import`, toate pe `D:/GameDev/wt-mp-e`:

```
probe_decor --track=15   Track15  10961 prop  2809 desene  19 mat  1 372 214 tri  OK
ProbeBuried --track=8    1111 puncte | ingropate >1 m: 0 | tavane: 0            OK
ProbeLaneClear --track=8 18 probe blocate, sub linia de baza (20)               OK
ProbeRace seed 1         0 repuneri · 0.0% offroad · fara blocaj/invers/carusel
ProbeRace seed 3         0 repuneri · 0.0% offroad
ProbeRace seed 2         0 repuneri · 2.3% offroad
```

**19 materiale** din plafonul de 30: cele 1649 de piese ale zonei n-au adus
niciun material nou. Banda mea (0.55-0.65) merge la 27,8-30,1 m/s cu **0 %
lent si 0 pereti**. Seed 2 n-a dat coama de la 0.186 in rularea asta.

Afundarea, verificata pe captura, nu numarand:
`--rope-load=2.6,0.5` -> `PodFranghie sageata 1.50 m la mijloc, balans 0.00`.

## 9. Ce raman eu sa fi facut, si ce nu pot

Decorul zonei (rau, pereti, coame, ancoraj) e cel din rundele 1-2 si trece
toate garzile. **Runda 3 n-a adaugat piese**, fiindca niciunul din cele trei
defecte numite de critic nu e in decor:

- un turn pus ca prop langa tablier n-ar urma `deck_drop(u)`, deci s-ar
  desprinde vizibil de pod cand acesta se afunda cu 1,5 m sub autobuz;
- scandurile si catenara sunt vertecsi ai mesh-ului podului.

Capturile rundei: `E_r3_0.540.png`, `E_r3_0.548.png`, `E_r3_0.556.png`.
Cea de la **0.548** e cea mai cinstita: se vad ambele turnuri in prim-plan,
si sunt **mai scunde decat bolovanii de langa ele**.
