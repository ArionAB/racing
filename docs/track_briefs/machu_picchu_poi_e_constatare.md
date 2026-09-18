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
