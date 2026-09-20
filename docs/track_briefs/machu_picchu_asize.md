# Asizele: de ce zidăria citește ca lespezi, și de ce nu e un reglaj

> Notă de lead, 20 sep 2026. Șase critici orbi, pe trei POI-uri (A, F, H) în
> valul 4, au cerut același lucru: *„blocuri individuale cu muchie proprie, nu
> lespezi continue"*, *„poarta se citește ca un decupaj de carton, nu ca piatră
> tăiată"*. Am măsurat înainte să repar, și premisa s-a schimbat de două ori.

## 1. Nu lipsește detaliul — măsurat

Energia de muchie, captură de joc față de bară, **pe originale** (vezi §2
pentru de ce contează):

| | contrast p5–p95 | energie muchii |
|---|---:|---:|
| noi (H) | 176 | **18,02** |
| bara (H) | 173 | **18,03** |

Identic. Reflexul „adaugă detaliu" ar fi mers exact în direcția greșită.

## 2. Capcana de măsurare care a dat primul răspuns fals

Prima rulare a redimensionat bara la mărimea capturii și a dat **4,69** —
adică „avem de 3,8× mai mult detaliu decât referința". Fals: interpolarea la
redimensionare **șterge muchiile fine**, deci măsura energia unei imagini
netezite. Se măsoară pe originale.

## 3. Ce lipsește de fapt: muchiile de FORMĂ

Testul care separă granulația de formă — blur progresiv, cât din energie
rămâne:

| | muchii totale | grosiere (blur 2px) | raport |
|---|---:|---:|---:|
| bara H | 18,03 | **4,67** | **25,9 %** |
| noi H | 18,23 | 3,23 | 17,7 % |
| bara A | 19,64 | **4,79** | **24,4 %** |
| noi A | 23,15 | 3,38 | 14,6 % |

Muchiile care supraviețuiesc blur-ului sunt cele de **formă**: contururi de
bloc, umbre de rost, siluete. Ale noastre sunt cu **~30 % mai puține**, deși
totalul e egal sau mai mare. Restul e granulație de textură triplanară —
zgomot uniform care nu descrie nimic.

Pe A e și mai clar: 23,15 muchii totale (cu 18 % peste bară) dar doar 14,6 %
grosiere. Prea mult zgomot, prea puțină formă.

## 4. De ce nu e un reglaj de clasă

`inca_stone` și `cut_stone` folosesc **aceeași dală** (`alpine_granite.png`) la
**aceeași scară triplanară** (0,28). Diferă doar tenta și `CLASS_LIFT`. Deci
rosturile nu pot veni din clasă — dala e identică peste tot, iar comentariul
din `palette.gd` care spune că la 0,28 „rosturile se citesc ca blocuri" descrie
o intenție care nu se verifică pe captură.

Scara e deja calibrată pentru zidărie reală (o repetiție la ~3,6 m pe blocuri
de 4,00 și 6,00 m). Coborârea ei ar da tapet, nu asize.

## 5. Cauza reală: geometria nu are blocuri

`inca_wall_a` are **208 triunghiuri** pentru un zid de 4,00 × 2,49 m.
`inca_wall_b`: **296** pentru 6,00 m. Adică o cutie cu câteva fațete — **nu
există muchii de bloc în mesh**, deci nici AO copt în vertex colors n-are ce
umbri, și nicio lumină nu poate desena un rost care nu există geometric.

**SSAO nu e o opțiune**: `docs/style_bible.md` §477 îl declară *interzis pe
mobil*, alături de SSR și volumetrice.

## 6. Ce ar rezolva, în ordinea costului

1. **Normal map pe clasa de zidărie.** Cel mai ieftin: zero triunghiuri,
   rosturile apar ca relief la lumină razantă. Costă un canal de textură în
   plus pe clasă (VRAM), și trebuie verificat pe device — dar e singurul care
   nu atinge nici geometria, nici numărul de piese.
2. **Kit de zidărie cu blocuri modelate** — variantă de `inca_wall_*` cu
   rosturi reale (estimat 600–900 tri față de 208). E comandă la pipeline-ul
   Blender, ca gura de tunel din `machu_picchu_tunel.md`. Cel mai bun
   rezultat, cel mai mare cost.
3. **Accept.** Cetatea se citește ca piatră la distanța de condus; defectul se
   vede pe poartă, care ocupă o treime din cadru la frac 0,97.

**Nu s-a făcut niciuna** — 1 și 2 sunt decizii de buget (VRAM, respectiv o
comandă de asset), iar 3 e decizie de dezvoltator.

## 7. Ce s-a rezolvat în schimb

Lumina, care era **jumătate din problemă**: pe suprafețe arse la V = 1,000 nu
se vede nicio muchie, oricâte ar fi. `sun_energy` 1,80 → 1,35 și
`ambient_energy` 0,45 → 0,46 scad eroarea totală față de bară de la 26,7 la
13,1 — cu **51 %**. Detaliile în commit-ul de lumină.

Dar `blur1%` rămâne 38,7 în toate variantele de lumină testate, deci asizele
sunt o problemă **independentă**, nu una pe care lumina o rezolvă.

## 8. Optiunea 1 (normal map) — INCERCATA SI RESPINSA PE CIFRA, 20 sep 2026

Decizia dezvoltatorului a fost "incearca 1 intai, avem loc de draw calls
(19 din 38)". S-a facut, complet, si **nu functioneaza**. Scris aici ca sa nu
se reincerce.

**Ce s-a construit:** `tools/paint_inca_stone_normal.py` — normal map tileabil
512x512, cu scara legata de `CLASS_TRIPLANAR_SCALE` (0,28 = o repetitie la
3,57 m, deci 143 px = 1 m): 8 randuri de 0,45 m, ~5 blocuri de 0,71 m pe rand,
decalaj de jumatate de bloc intre randuri, rost de 2,5 cm, fata bombata convex.
Cablat prin `CLASS_NORMAL` / `CLASS_NORMAL_SCALE` in `palette.gd`.

**Verificat ca mecanismul e CONECTAT** (memoria `sonda-masura-alt-obiect`:
cifre identice la zecimala = suspiciune de mecanism mort). Sonda a aratat
`normal_enabled = true`, textura incarcata, si **822 din 1186** de mesh-uri
din Piata Sacra o poarta. Deci nu e neconectat.

**Rezultatul, pe muchii grosiere (blur 2 px), tinta = bara 4,67:**

| varianta | muchii totale | GROSIERE | % din tinta |
|---|---:|---:|---:|
| fara normal | 18,23 | 3,23 | 69 % |
| normal x1 | 18,55 | **3,23** | 69 % |
| normal **x6** (exagerat intentionat) | 20,58 | **3,34** | 71 % |

La o scara de **sase ori** peste normal, muchiile grosiere urca cu **3 %**,
cand tinta cere +45 %. Muchiile TOTALE insa cresc (18,2 -> 20,6) — adica
normal map-ul chiar adauga detaliu, dar **detaliu FIN, care moare la blur**.
Exact defectul pe care incerca sa-l repare.

**De ce, si de ce era previzibil:** un normal map nu schimba silueta si nu
muta niciun pixel — modifica doar cum cade lumina pe o suprafata care ramane
plana. Umbra de rost pe care o produce are latimea rostului (2,5 cm la 3,57 m
de textura, adica sub un pixel la distanta de condus) si dispare la primul
mipmap. Muchiile de FORMA din bara sunt contururi de bloc care se decupeaza
pe fundal — alea cer geometrie, nu iluminare.

**S-a aruncat, nu s-a reglat mai departe** — conditia era scrisa in antetul
generatorului inainte de masuratoare, tocmai ca sa nu se ajunga la "mai cresc
putin contrastul pana iese ceva" (tiparul "prag mutat pana nu mai masoara
nimic" din CLAUDE.md).

**Ce ramane:** optiunea 2 (kit de zidarie cu blocuri modelate, 600-900 tri
fata de 208 — comanda Blender) sau optiunea 3 (accept). Optiunea 1 e INCHISA.
