# Valul 3: 0/6 la rejudecată, 0/2 la construcție — și ce spun cifrele

> Notă de lead, 19 sep 2026. Rulat `tools/gauntlet/machu_val3.js`
> (24 de agenți: 6 rejudecăți oarbe + 2 POI-uri × 3 runde constructor/critic).
> **Toate cele opt verdicte au fost „nu a noastră".** Dar rezultatul e util,
> fiindcă de data asta verdictele converg pe ceva măsurabil.

## 1. Rejudecata: `scarp_tint` n-a fost de ajuns, și criticii spun de ce

Cele șase POI-uri construite au fost judecate prima oară pe o lume în care fața
oricărei căderi avea culoarea ierbii. `scarp_tint` a intrat după. Rejudecate pe
lumea de acum, **niciunul n-a câștigat** — dar patru din șase verdicte spun
același lucru, iar acum e o propoziție despre **teren**, nu despre culoare:

| POI | esența verdictului |
|---|---|
| **C** | „caderea din stânga… e o singură spoială verde-palidă, fără rocă expusă" |
| **D** | terasele sunt „ziduri izolate, nu pământ susținut în trepte"; „n-au pe ce să coboare" |
| **G** | „**terenul, nu materialele, e defectul**" — zidul „atârnă în aer peste iarbă" |
| **H** | „nu există stâncă lângă drum"; „nu există cădere pe dreapta, deci `scarp_tint` n-are pantă pe care să se aplice" |

Criticii lui **G** și **H** au făcut legătura singuri, fără s-o aibă în prompt:
un reglaj de tentă care lucrează **pe pantă** nu are pe ce să se aplice acolo
unde panta nu există. Asta confirmă, din a treia direcție independentă,
măsurătoarea `SvMpBuza` din valul 2.

**A** e singurul verdict despre decor, nu despre teren: „tot construitul din
cadru e o balustradă — un singur profil de perete, repetat, fără colț și fără
interior". Piața Sacră are 874 de noduri și niciun **spațiu închis**. Ăsta e
reparabil în zonă, fără să se atingă terenul.

**F** la fel: „râul lipsește cu totul din zona numită malul râului". F are 92
de piese, fără apă și fără tren — cea mai slabă zonă de pe pistă.

## 2. Construcția: B și E au livrat, dar n-au câștigat

### B — Drumul Incaș: 314 piese, și **acum drumul chiar e tăiat în stâncă**

Zona era goală. Constructorul a mers 7 runde interne. Captura de la frac 0.11
arată exact ce ceruseră criticii: perete stratificat care pornește **din
marginea asfaltului**, vegetație agățată pe el, drumul ca poliță scobită.

Criticul rundei 3 a cerut **gura de tunel cu arc de piatră** — singurul element
din decupaj care lipsește. Kitul n-are piesă de tunel; brief-ul o cere (12 m,
tavan 6 m). Rămâne deschis: e o piesă de comandat, nu o așezare.

`probe_manual` raportează 202 „îngropate" și 170 „IN DRUM" pe B. **Verificat, nu
sunt defecte:** cea mai apropiată piesă e la **6,6 m** de ax, iar carosabilul
are semi-lățime 6,0–6,5 acolo — deci totul e **în afara** drumului, doar în
marja de curtoazie de 2 m a sondei. `ProbeLaneClear` dă **0 blocaje** pe tot
intervalul lui B. „Îngropat" e intenția: piesele de perete intră în faleză.

### E — Podul de frânghie: 1651 de piese în 15 noduri MultiMesh

Râu la −40,12 cu spumă, bolovani în albie, doi pereți de flanc, ancoraje.
Golul **există** și e măsurat de trei ori independent: `TerrainBody` la
**−40,30** lângă marginile tablierului (nu doar pe axă), deci **20,3 m** sub
deck. Și carosabilul **chiar e tăiat**: `_span_holes` = `(609, 20)`, adică frac
0,5482–0,5662, exact tablierul.

**Toți trei criticii au spus totuși „nu există gol sub tablier".** Nu greșesc ce
văd: pereții gorjei sunt în **V, cu iarbă**, măsurați de constructor la
**16–38°**, iar `scarp_tint` intră la 28° și e plin abia la 38. Din mașină se
vede un șanț ierbos, nu o prăpastie — golul e real dar **necitibil**.

## 3. Pragul `scarp_tint`: testat, și NU e pârghia

Ipoteza evidentă era coborârea pragului de la 28° la 16°. **Testat pe ramură
separată, respins pe captură:** la frac 0.82 diferența e invizibilă.
Măsurat de ce: banda 16–28° conține 951 de vertecși pe toată pista, din care
doar **304 sub 40 m de drum**. Restul sunt la 40–100 m sau în ceață.

Nu s-a comis. O schimbare globală de temă, pe toate POI-urile, pentru un câștig
care nu se vede din mașină, ar fi exact tiparul „plafon mutat până nu mai
măsoară nimic" din CLAUDE.md.

## 4. Ce rămâne, în ordinea impactului

1. **Relieful lateral pe D, G și H** — trei critici independenți spun că e
   același defect, iar `SvMpBuza` îl confirmă numeric. `machu_picchu_teren_D.md`
   are propunerea măsurată pentru D (două râpe cu parte alternantă). G și H cer
   aceeași analiză. **Decizie de dezvoltator: atinge terenul.**
2. **Pereții gorjei lui E**, de la V ierbos la fațete de rocă. **Testat și
   respins varianta ieftină:** `custom_scarp_ravines` pe râpele 2/3 nu schimbă
   nimic — măsurat, cifrele sunt **identice la zecimală** înainte și după
   (96 de vertecși în gorjă, unghi mediu **14,3°**, 37,5 % peste 28°, 19,8 % cu
   tentă de piatră).

   Motivul e în cod: în `_carve_ravines`, ramura de **viaduct** rulează **după**
   cea de scarp și **suprascrie `rim`** (`rim = RAVINE_VIADUCT_RIM`). Râpa 2 e
   viaduct, deci flagul de scarp pe ea e **mort prin construcție**; râpa 3 nu e
   viaduct, dar începe la 0.5834, iar podul e 0.5482–0.5662 — adică integral în
   râpa 2. **Un flag ignorat în tăcere e o capcană**: merită ori un
   `push_warning`, ori ordinea inversată, ori documentat în `terrain_hollow`-ul
   de lângă.

   Ce rămâne: unghiul **mediu de 14,3°** spune că gorja e un **bazin larg**, nu
   o crăpătură. Niciun prag de tentă n-o poate face să citească drept prăpastie
   — cere geometrie (pereți mai abrupți sau piese de faleză), nu culoare.
3. **A: incinte închise** (874 de piese, zero spații închise) și **F: râul**
   (92 de piese, fără apă). Amândouă reparabile **în zonă**, fără teren.
4. **Tunelul lui B** — piesă de comandat.
5. Cele **528 + 269** de piese raportate de `probe_manual`: se citesc **per
   caz**, nu ca total. Pe B și G majoritatea sunt intenție (perete, zid de
   sprijin); pe F și H plutirile de 9–13 m sunt defecte reale.
