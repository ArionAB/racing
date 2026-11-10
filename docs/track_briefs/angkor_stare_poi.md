# Angkor: starea gauntlet-ului de POI (7 nov 2026)

> Nota de predare a gauntlet-ului de decor pe Track24. Contractul e
> `angkor_poi_gauntlet.md`; verdictele orbe, întregi, sunt în
> `D:/GameDev/_angkor_race/critic/verdicte.md` (în afara repo-ului). Ramura de
> integrare: `angkor/poi-fundatie`, stivuită pe `angkor/kit-val1` (PR #660).

## Ce s-a făcut

| piesă | ce a pus | runde oarbe | ieșire |
|---|---|---|---|
| **J** jungla în masă | `MeshForest`: 13.132 de copaci în inele + pâlcuri, luminișuri pe monumente; trunchiurile remapate CORAL_SAND → LOG_DARK | 2 (A, C, E, G) | **(c)** forma asset-ului: „plantație de trunchiuri goale” — **datorie acceptată** |
| **S** suprafețele | gresie fără marcaje pe căi, apa de jad, sol oliv, banda de umăr stinsă, soare auriu la 24°, **cer pe azimut** (piersică spre soare, violet spre est; opt-in `sky_azimuth`) | 2 + decizia cerului | **(c)** lumina → decizia dezvoltatorului, livrată |
| **A** calea de vest | 310 lotuși/nuferi în derive, bordura malului, moloz la balustradă | 3 (r1–r3) | (c) material + asset (pavaj, balustradă, templul văzut din cale) |
| **B** prin Angkor Wat | calea procesională cu naga și macaci, călugări, terase, calea de nord cu lotuși | 1 | (c) asset (lipsesc turnurile din cadru) + material |
| **C** Phnom Bakheng | piramida în 5 etaje, 11 turnulețe, scări, naga, coridoare de vedere | 3 | (c) material („teracotă”) + teren plat în cadru |
| **D** calea uriașilor | 126 de lotuși, zidul Angkor Thom (de la 17 m), moloz-fantomă la poartă | 1 | (c) asset (uriașii/naga, datoria de sculptură); decor rămas: bordura bazinelor |
| **E** Bayonul | 26 de turnuri cu fețe în două rânduri, zidul terasei, moloz | 3 | (c) asset (fețele, datorie) |
| **F** piața regală | Phimeanakas în trepte, curtea palatului, piața cu blocuri/călugări/tuk-tuk | 1 | (c) material (gazon în loc de pavaj) + asset |
| **G** Ta Prohm | incinta la 18 m, 5 galerii-fragment, ușa, ficuși, moloz, luminișuri | 3 | (c) asset (rădăcinile peste ziduri) + material |
| **H** Srah Srang | 176 de lotuși (bazin + șanț), bordura bazinului, palmieri, tuk-tuk-uri pe debarcader | 1 | (c) material + shader (apa fără reflexii) |

**Orb: 0 din 8 în runda 3** (0/24 pe toată sesiunea), ca pe toate pistele
anterioare: diorama e o pictură. Bucla s-a oprit pe (c): după decor, ce separă
cadrele de bară e **sub decor**.

## Ce numesc criticii, după decor (runda 3, 8/8)

1. **Copacii** (8/8): trunchiuri goale cu coroană plată sus → „plantație”. Datorie
   acceptată de dezvoltator (6 nov); de revenit cu un val de copaci cu coroană joasă.
2. **Materialul de piatră** (7/8): portocaliu-saturat, neted, fără mușchi și fără
   asize; piramidele în trepte citesc „teracotă / maya”, terasele stivuite „cherestea”,
   pavajul căilor „pământ bătătorit”. Clasa `angkor_sandstone` + tenta pieselor de kit.
   **Decizie deschisă.**
3. **Sculptura** (E, D, A, F): fețele Bayonului, uriașii, naga, fața terasei cu
   elefanți — datoria de sculptură (kit §1.1).
4. **Lumina și cerul în cadru** (6/8): ceața roz-mov dintre trunchiuri și lumina
   uniformă; cerul pe azimut se vede plin doar în vederi largi.

**Decor reparabil rămas, mic:** bordura de piatră la bazinele D, liane verzi și
subarboret mai des la G, lotuși roz (nu mov) la H, terasele stivuite ale lui B.

## Gameplay (ProbeRace, 16 seed-uri × 8 mașini × 250 s)

| | int1 (J+S+E) | int3 (toate 8) | **int4 (final)** |
|---|---|---|---|
| repuneri | 6 | 5 | **4** |
| ejectări | 6 | 5 | **3** |
| blocaje (la poarta elefantului) | 10 (9) | 28 (28) | **21 (19)** |
| tur mediu | 81,5 s | 81,8 s | **81,9 s** |
| zboruri / airtime | 385 / 0,65 | 384 / 0,65 | **384 / 0,65** |
| domino | 8,1% | 10,3% | **10,4%** |

**Prinse de ProbeRace în gauntlet:** zidul lui G la 11,5 m (100 de repuneri: AI-ul
taie interiorul virajelor la ~14 m → regula de 18 m) și zidul lui D la 10,4 m (închidea
ocolul pe lângă turnul porții; A/B: 28 cu zid / 14 fără / 19 la 17 m). Gărzile pe scena
finală: 15 materiale (≤ 38), probe_manual / LaneClear (41) / Buried / Layout / Pas6 OK.

## Reparate pe drum (în afara zonelor)

- **Cupola verde pe calea uriașilor** (din valul 4 al kitului): `Canopy_A` (196 m) din
  inelul de orizont, cu degajarea măsurată în pivot → `horizon_footprint` + `clear` 40.
- Opțiunea `child` în ITEMS (Moto-ul tuk-tuk-urilor puse din zone).
- Capturile de bază în `angkor_poi/baza/` (`r0/` era ignorat de `.gitignore`).

## Decizii deschise pentru dezvoltator

1. **Materialul de piatră** (7/8 critici): mai puțin saturat, mușchi și asize pe clasa
   `angkor_sandstone` și pe tenta kitului — sau acceptat.
2. **Pavajul pieței regale (F)**: suprafață de dale pe `custom_bench_patches` — sau gazon.
3. **Bordura de laterită** (A, H): citește „cărămizi roșii”; piesă de gresie sau scoasă.
4. **Gopura de nord + parapet pe calea de nord (B)**: generator.
5. **Golurile din balustrada naga (A)**: generator (zidul din cod e continuu).
6. **Mărimea scenei**: ~1.740 de noduri (lotușii); de măsurat încărcarea pe telefon,
   altfel lotușii trec în MultiMesh.
7. **Verdictul la volan** pe scena integrată — acceptarea finală.
