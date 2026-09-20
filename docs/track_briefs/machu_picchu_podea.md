# Podeaua văii — stratul care lipsea pe axa verticală

> Notă de lead, 19 sep 2026. Pornit de la critica dezvoltatorului: *„când
> conduci la înălțime și vezi podeaua la mulți metri sub tine nu ar trebui să
> fie verde gol, ar trebui să pară o lume plină și jos — o pădure de copaci +
> stânci."* Varianta cerută: **(a) fără ceață, doar pe Machu Picchu**, ca să se
> izoleze o singură variabilă.

## 1. De ce era goală — trei mecanisme, niciunul reparabil pe POI

1. **`BANDS` din `track_decor.gd` măsoară lateral, nu vertical.** `off_min` și
   `off_max` sunt distanțe de la marginea asfaltului; ultima bandă (`far`) se
   oprește la **58 m**, și doar pentru `props_only: ["desert","alpine","baikal"]`.
   O podea la −50 m *cotă* nu intră în nicio bandă, oricât de late.
2. **`_allowed()` respinge explicit `spec.is_ravine`.** Comentariul spune de ce:
   *„un cactus plutind peste prăpastie ar strica exact efectul."* Corect lângă
   drum — și exact regula care ține fundul gol.
3. **Tema `machupicchu` are `"decor": "none"`** — benzile sunt stinse complet.

Deci podeaua nu putea fi reparată de niciun constructor de POI, oricâte runde
ar fi primit. E același tipar ca memoria `criticul-cere-ce-zona-nu-poate-da`.

**E defectul #147 pe cealaltă axă.** Comentariul benzii `far` descrie identic
problema orizontală: *„benzile se opreau la 26 m, siluetele de orizont încep la
150 m, între ele nu era NIMIC, și banda aia goală umple jumătate din cadru."*
Văzută de sus, podeaua goală umple la fel de mult cadru.

## 2. Unde e podea — măsurat pe tot turul, nu presupus

`tools/GenPodeaVale.tscn -- --survey`. Prag: sol cu ≥ 12 m sub cota drumului,
căutat lateral între 16 și 130 m.

| interval | parte | adâncime max | lățime podea |
|---|---|---:|---:|
| 0.08–0.35 (B + C) | dreapta | **54–84 m** | **121 m**, continuu |
| 0.16–0.21 (B) | stânga | 49–79 m | 33–88 m |
| 0.24–0.35 (C) | stânga | 25–31 m | 99–110 m |
| 0.38–0.51 (D) | ambele | 22–47 m | 33–88 m |
| 0.55–0.65 (E) | ambele | 12–20 m | 44–77 m |
| 0.78–0.90 (G) | ambele | 24–40 m | 66–121 m |
| 0.94–0.99 (H) | stânga | 12,3 m | 22–55 m |

## 3. Două corecții la diagnosticul anterior

**G are vale.** Lead-ul scrisese că G n-are, citind `SvMpSapa` (care se oprește
la +10 m lateral) și `SvMpProfil` pe direcția radială. Survey-ul de podea, care
caută până la 130 m, o găsește: 24–40 m adâncime pe 66–121 m lățime, începând
de la **38–60 m** lateral. Nu se vedea fiindcă niciuna din sondele anterioare
nu ajungea atât de departe. Memoria: `sonda-scurta-extrapolata-gresit`.

**D are podea deși terenul lui rămâne neatins.** Dezvoltatorul a închis decizia
de teren pe D (rămâne zonă de terase pe pantă blândă, fără critici). Asta rămâne
valid — dar podeaua lui de la 0.42 (−40 m) se umple oricum, fiindcă generatorul
merge pe tot turul. Nu e o reintrare pe decizia închisă: nu atinge terenul, pune
decor în golul care există deja.

## 4. Ce se așază

Generator propriu (`tools/gen_podea_vale.gd`), nu bandă nouă — fiindcă benzile
sunt stinse pe tema asta, și fiindcă așa nu se atinge nimic din ce folosesc
celelalte 8 piste. Izolarea cerută de dezvoltator e prin construcție.

- `polylepis_a` (598 tri) — copacul de bază; `polylepis_b` (1098) — accent, rar
- `moss_boulder_a/b/c` — stânci, în pâlcuri
- **zero materiale noi**: toate piesele sunt deja în kitul Track15
- **`metadata/coliziune = "none"`** pe tot: la −50 m sub drum nu ajunge nicio
  mașină, iar un colizor acolo ar fi doar cost

Compoziția urmează `aranjamentul-bate-numarul`: pâlcuri, nu distanțe egale;
scară variabilă 1,05–1,95; ~30 % goluri intenționate, fiindcă o pădure continuă
fără poieni citește ca gazon. Cu adâncimea crește proporția de pădure față de
stâncă (fundul văii e umed, pereții sunt seci).

Praguri de refuz: pantă locală > 34° (pe perete copacii ar ieși din fațetă, și
se măsoară maximul pe patru direcții, nu media — un perete paralel cu raza nu
se vede altfel) și adâncime < 12 m.

## 5. Prima rulare: cifra care cere judecată

**5633 de piese, 2 368 292 de triunghiuri.** Pista era la 1 095 030 — deci
podeaua singură ar fi de două ori cât tot restul.

Nu încalcă nicio regulă: triunghiurile nu mai pică build-ul (decizia
dezvoltatorului, august 2026), materialele rămân **19** fiindcă nu intră nicio
piesă nouă, iar motivul din CLAUDE.md se aplică direct — cifra e pe toată pista,
iar ceața taie la 300 m pe tema asta, deci pe ecran nu ajunge niciodată toată.

Dar 2,37 M dintr-un foc se judecă pe captură, nu pe cifră: dacă din mașină se
văd puține piese, densitatea se taie și cifra scade proporțional. Verdictul se
ia din **vederea șoferului** (memoria `driver-view-for-composition`), la
fracțiunile cu cea mai mare expunere: 0.15 (B, −78 m), 0.28 (C, −69 m),
0.86 (G, −40 m).

Respinse la generare: 440 pe pantă, 4085 prea sus — adică filtrele lucrează,
nu umplu totul orbește.

## 6. Rezultatul livrat

**4698 de piese in 59 de noduri MultiMesh.** Nu noduri de scena: prima
versiune emitea 5633 de noduri individuale si Godot nu mai termina de incarcat
scena in 25 de minute (POI E stia deja lectia — 1651 de piese in 15 noduri).
Feliate in 12 segmente de tur, ca AABB-ul unui MultiMesh global sa nu fie cat
harta si culling-ul sa ramana util.

| garda | inainte | dupa |
|---|---:|---:|
| materiale | 19 | **19** |
| prop-uri | 9 312 | 16 927 |
| triunghiuri | 1 095 030 | 3 974 170 |
| ProbeLaneClear | 18 | **17** (baza 20) |
| ProbeBuried | 0 | **0** |
| ProbeRace seed 1/2/3 | 2/1/1 | **2/1/1** |

**Materialele nu se misca**: toate piesele erau deja in kitul Track15, iar
bolovanii poarta `tri_class = "inca_stone"`, clasa existenta. Axa care doare
pe mobil e neatinsa. Triunghiurile cresc de 3,6x, dar se raporteaza, nu pica
(decizia dezvoltatorului, aug 2026), si ceata taie la 300 m pe tema asta.

**ProbeRace da cifre IDENTICE cu baseline-ul de pe main** — aceleasi pozitii,
aceleasi secunde, acelasi 109.7s pentru ejectarea de la frac 0.501. Verificat
ruland sonda si pe main: cele doua repuneri de pe seed 1 sunt preexistente,
nu ale podelei. Decorul nu schimba nimic la condus, cum se si astepta de la
piese fara coliziune la -40 m sub drum.

## 7. Trei mecanisme neconectate, prinse pe rand

Cifra din generator a fost gresita de trei ori, si de fiecare data a prins-o o
verificare care privea REZULTATUL, nu raportul intermediar:

1. **Toate cele 60 de noduri aveau `positions` goale.** Indexarea unui
   `PackedVector3Array` dintr-un `Dictionary` intoarce o COPIE, deci
   `.append()` se pierdea in tacere. Generatorul raporta vesel "5633 de piese".
   Prins de: **captura identica la bit** cu cea fara podea.
   Memoria: `append-pe-copie-in-array-netipizat`.
2. **Garda de proximitate acoperea doar pilcul principal.** Satelitii se asaza
   cu raycast propriu si o ocoleau: din 904 piese gresit plasate ramaneau 707.
   Mutata in `_raw`, poarta unica prin care trece ORICE piesa.
   Prins de: **ProbeRace**, care a gasit piese la 1,4 m de masina la frac 0.501.
3. **Sonda mea de verificare era moarta.** `SvPodeaVie` raporta "cote
   0.0 .. 0.0" pe toate cele 5633 de instante. Am adaugat x/z ca martor:
   **0 din 5633** aveau vreo componenta nenula — instantele nu erau CITITE, nu
   erau asezate la zero. Memoria: `multimesh-masuratoare-moarta`.

Si un al patrulea, care era un fals pozitiv al lead-ului: cele 623 de piese
"peste -12 m" pareau gresite, dar cota ABSOLUTA nu e criteriul. Verificate una
cate una, piesa de la +12,3 are drumul cel mai apropiat la +25,0 — deci e la
12,7 m SUB el. Pe un munte, podeaua unei vai poate fi la cota pozitiva.

## 8. Ce a ramas descoperit, si e decizie de teren

Vederea libera din vale (`img/mp_podea_vale.png`) arata podeaua plina — dar si
ca e o **campie plata**, care se intinde pana la orizont fara maluri. Valea de
-78 m e reala si masurata, dar de pe drum nu se citeste ca prapastie: vezi
padure mai jos, nu o margine de care sa-ti fie frica.

Critica initiala avea deci **doua straturi**:
1. podeaua goala — **rezolvat aici**;
2. lipsa malurilor — **teren, nu decor**, aceeasi decizie inchisa pentru D si
   inca deschisa pentru H.

Al doilea nu s-a atins: e decizie de dezvoltator, si nu se mascheaza cu decor.

## 9. Raul lui F: de ce nu se poate aseza (masurat, 20 sep 2026)

Toti trei criticii valului 4 au cerut apa pe F. Zona are 132 de noduri si
**zero apa** — au dreptate literal. Dar premisa ceruta de brief (raul la -30 m,
cel mai jos punct al pistei) nu exista in teren.

**Mecanismul, gasit in cod.** `track_side_sampler.gd`:
`target = maxf(target, floor_y)` — podeaua declarata e un **plafon inferior**,
nu o comanda. Rapa 9 (intervalul lui F) are podea `-42` declarata, dar sapa
doar 14 m sub un drum aflat la -25…-29, deci fundul iese la -39…-43 si podeaua
nu se atinge niciodata.

**Doua reglaje incercate, ambele partiale:**

| | latimea vaii la 0.69 | incepe la | adancime |
|---|---:|---:|---:|
| initial (adancime 14, podea -42) | 22 m | 49 m | 13,8 |
| adancime 17 | 33 m | 16 m | 13,8 |
| adancime 20 + podea -52 | **44 m** | **16 m** | 14,3 |

Valea s-a **largit de doua ori** si s-a apropiat de drum de trei ori — dar
adancimea nu se misca.

**De ce.** Profilul lateral complet pe F (`SvMpProfil`, restrans la 0.66-0.74):

```
F dr | -10.3  -2.9  -2.6  -6.4   0.3   0.1  -3.5   5.9   7.4  10.1
F st |   0.2   0.8   0.2  -5.1  -0.7  -1.0  -4.7  -0.7  -0.1  -1.5
     |  10 m  20 m  30 m  40 m  50 m  60 m  70 m  80 m  90 m 100 m
```

Pe dreapta terenul cade -10,3 m la 10 m si **URCA inapoi la -2,9** la 20 m. Nu
e vale, e o crestatura ingusta care se inchide imediat. Pe stanga e plat. Nu
exista `custom_peaks` acolo — e relieful de BAZA al pistei, iar `_smin` cu
terenul existent limiteaza cat poate sapa rapa.

**S-a revenit la configuratia originala.** Ca raul sa aiba unde curge, trebuie
redesenat relieful de baza pe intervalul lui F — ceea ce atinge terenul sub
cele 132 de piese deja asezate si cere re-rularea generatorului. E aceeasi
forma ca decizia inchisa pentru D: **teren, nu decor.**
