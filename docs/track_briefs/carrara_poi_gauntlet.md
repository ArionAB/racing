# Carrara: contractul per POI pentru gauntlet

> Fișa de lucru a perechilor constructor/critic pe Track23. **Bara** e diorama
> acceptată `docs/track_briefs/img/carrara_plan/diorama_v01_iter2.jpg` (brief
> §9.2), decupată per POI în `docs/track_briefs/img/bar_carrara/bara_poi_<X>.png`
> (`tools/bar/crop_carrara_bar.py`). **Planul real** al traseului e
> `docs/track_briefs/img/carrara_plan_adnotat.png`. Kitul e descris în
> `docs/asset_briefs/carrara_kit.md`, iar ce s-a acceptat, cu cote măsurate, în
> `docs/asset_briefs/carrara_inventory*.md`. Brieful pistei
> (`docs/track_briefs/carrara.md`) dă intenția; **cotele vin din Track23 și din
> măsurători, nu din brief și nici din dioramă.**

## Regula care se încalcă cel mai des

**Bara e look, nu layout.** Diorama comprimă un bazin de ~500 m într-un cadru
de machetă: piazzale-ul, gradonii, fundul și galeria apar unele lângă altele.
Pista noastră nu face asta și nu trebuie să facă (traseul real e în planul
adnotat, cu ProbeLayout verde). Criticul compară **cum arată materia și ce
obiecte locuiesc locul**: marmura crem cu dungi de fir și dâre de rugină,
praful bej, utilajele galben-spălăcit, bălțile turcoaz opace, blocurile
stivuite, verdele castanilor. Nu compară unde cade fiecare obiect.

Un critic care spune „la noi gradonii nu se văd toți deodată” a comparat
layout-ul și a ratat sarcina. Singura diferență care contează e una pe care o
poți repara în decorul POI-ului.

**Defecte declarate ale dioramei, care NU se iau din imagine:**
- **E e desenat prea jos**: înălțimile vin din Track23 (E e la +45, scara are 5 fețe);
- **excavatorul e desenat pe stânga**: în joc stă pe **dreapta**, la ieșirea
  din coridorul de blocuri (frac 0,05). Decizia dezvoltatorului, cu zarul AI-ului;
- **nimic alb**: în dioramă blocurile ies spre alb, la noi marmura e **crem**,
  nu zăpadă (brief §4, regula v0.2: slotul 22 nu apare nicăieri);
- **utilajele nu sunt galben de mașină**: galben-spălăcit (slotul 13) plus
  rugină, niciodată `CAR_YELLOW` 16.

## Ieșirea din buclă (ca la Fiordland)

Pe Serengeti 0 din 8 POI-uri au câștigat orb, pe Machu Picchu 0 din 3, pe
Fiordland 0 din 8. Diorama e o pictură randată, iar un cadru low-poly nu o bate
orb, oricâte runde ar primi (memoria `gauntlet-iesirea-din-bucla`). Deci:

- **judecata rămâne oarbă**: `python tools/bar/blind_pair.py <a_noastră> <bara> <planșa> --seed N`,
  o planșă per rundă, A sau B, **o singură diferență numită**. Criticul verifică
  amprenta din colțul planșei față de cheie (memoria `critic-orb-coliziune-de-plansa`);
- **ieșirea din buclă e una din:**
  - (a) criticul alege a noastră orb;
  - (b) criticul **nu mai numește nicio diferență reparabilă în decorul POI-ului**;
  - (c) criticul numește **aceeași diferență de două ori la rând**. Atunci
    cauza e sub decor (relief, lumină, shader, asset) și **bucla se oprește**,
    cu decizia pusă în fața dezvoltatorului (memoria `criticul-cere-ce-zona-nu-poate-da`);
- **maxim 4 runde per POI**, chiar dacă nu s-a atins nicio ieșire;
- **acceptarea finală e verdictul dezvoltatorului la volan**, pe scena integrată.

## Cum se pune decorul (fundația)

**Generatorul e sursa de adevăr**: `tools/gen_carrara_route.py` scrie
`scenes/tracks/Track23.tscn`. **Nu edita .tscn-ul de mână**, se pierde la
regenerare. Decorul fiecărui POI stă într-un fișier propriu,
`tools/carrara_decor/zona_<x>.py`, iar formatul e descris în antetul lui. **Un
constructor atinge doar fișierul zonei lui.**

```
ITEMS = [ ("A_Nume", "rocks/block_stack_a.glb", 0.024, -9.2, 5.0, {"scale": 1.0}), ... ]
KIT_Y = { "A_Nume": 24.63, ... }
```

- `frac` e pe **index** (axa coaptă), `lateral` e la **dreapta** sensului de cursă;
- `glb` e relativ la `res://assets/models/carrara/` sau cale `res://` completă
  (reuse: `res://assets/models/props/beech_tree_a.glb` și altele);
- după orice schimbare: `python tools/gen_carrara_route.py scenes/tracks/Track23.tscn`.
  Generatorul tipărește fiecare piesă cu frac, lateral, cotă și distanța la
  camioane / turnul derrick-ului (`<-- PREA APROAPE` = mută piesa);
- **cotele se măsoară, nu se ghicesc**:
  `godot --headless --fixed-fps 60 --path . res://tools/ProbeCarraraMontaj.tscn -- --decor`
  dă terenul minim de sub amprenta fiecărei piese. Cota se trece în `KIT_Y` ca
  teren minim − 0,03 m (memoria `origin-base-ridica-tot-obiectul`). O piesă fără
  cotă stă la cota drumului − 0,3;
- **coliziunea** e automată, din `world_prop.gd` (`hull` implicit; `"coliziune"`
  în opțiuni pentru `mesh` / `trunk` / `none`). **AI-ul nu vede decorul
  static** (memoria `obstacol-pe-drum-poate-fi-gimmick`): orice piesă la mai
  puțin de ~3 m de marginea asfaltului se dovedește cu ProbeRace;
- **materiale**: clasele vin din `CLASSES_CARRARA` (`world_prop.gd`) și din
  atlas. Un asset nu aduce textură proprie. Bugetul e **≤ 38 de materiale**
  per pistă; un material nou se cere explicit în raport, cu ce cumpără vizual;
- **Index vs scenă** (memoria `probe-decor-numar-de-scena`): `probe_decor` și
  `probe_manual` iau numărul de **scenă (23)**; snapshot, ProbeRace, ProbeBuried,
  ProbeLaneClear și ProbeLayout iau **indexul (15)**.

## Ce se măsoară (pe worktree-ul POI-ului înainte de raport, pe scena integrată la final)

`--import` înaintea oricărei serii (memoria `import-invechit-falsifica-masuratoarea`).

| gardă | comandă | linia de bază pe main (31 oct 2026, după valul POI A/B/C; vezi `carrara_stare_poi.md`) |
|---|---|---|
| ProbeRace | `SEEDS=16 PAR=5 bash tools/carrara_race_run.sh <dir>`, apoi `python tools/carrara_race_sum.py <dir>` | per 16 seed-uri ~**9 / 2 / 8** (repuneri / ejectări / blocaje; serie integrată A/B/C: 10/4/10), aproape toate la excavator (0,036–0,055), pe E/F (0,67–0,70) și în acul de la 0,147; o ejectare rară în rama portalului galeriei (0,398, 2 din 96 de seed-uri, deschisă). Contractul: **zero `[blocaj]`/repuneri noi atribuibile zonei** (citește unde sunt, nu doar totalul; memoria `zero-repuneri-ascunde-blocajul`). Nedeterminism: compară distribuții (memoria `proberace-nedeterminism`) |
| probe_decor | `--headless --path . --script res://tools/probe_decor.gd -- --track=23` | **25 de materiale** (≤ 38), 858 de desene |
| probe_manual | `--headless --path . --script res://tools/probe_manual.gd -- --track=23` | **5** (viaductul și cele 4 portaluri, care stau PESTE drum prin construcție). Contractul: **zero noi** |
| ProbeCarraraMontaj | `res://tools/ProbeCarraraMontaj.tscn -- --decor` | OK, 381 de piese |
| ProbeLaneClear | `res://tools/ProbeLaneClear.tscn -- --track=15` | **9** (exact linia de bază) |
| ProbeBuried | `res://tools/ProbeBuried.tscn -- --track=15` | OK, 0 îngropate |
| ProbeLayout | `res://tools/ProbeLayout.tscn -- --track=15` | OK |

## Captura: ce comandă, pentru care POI

Din mașină, `--gamecam` (camera reală de joc: 10 m sus, 12,5 m spate, fov 68;
memoria `verifica-cu-parametrii-lui`). Snapshot **nu merge headless** (cere
fereastră), iar capturile se fac **serial, cu lacătul de GPU**
(`until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 5; done` … `rmdir D:/GameDev/.render_lock`;
memoria `capturile-nu-se-paralelizeaza`). Gărzile headless merg în paralel.

```
godot --path <worktree> res://tools/snapshot.tscn -- --track=15 --frac=<F> --gamecam [flaguri]
```

O captură nu e un verdict (memoria `o-captura-nu-e-un-verdict`): planșa oarbă
se face pe **cea mai reprezentativă** din cele 2–3 ale POI-ului, iar celelalte
se păstrează pentru raport.

| POI | frac (din generator, 31 oct 2026) | captură | flaguri | bară |
|---|---|---|---|---|
| **A** piazzale | 0,000–0,058 | 0,01 · 0,03 · 0,05 | — (excavatorul pornește cu brațul jos) | `bara_poi_A` |
| **B** gradonii | T1 0,058–0,081 · ac1 0,099–0,110 · T2 0,145–0,168 · ac2 0,185–0,203 · T3 0,232–0,266 | 0,07 · 0,105 · 0,16 · 0,25 | `--bus-at=<s>` (camionul 1 în cadru) | `bara_poi_B` |
| **C** fundul | podea 0,296 · cot 1 0,330 · cot 2 0,371 · portal 0,400 | 0,30 · 0,33 · 0,36 | `--crane-at=<s>` (blocul derrick-ului peste drum) | `bara_poi_C` |
| D galeria | 0,400–0,592 | (val ulterior) | | `bara_poi_D` |
| E cariera de sus | 0,592–0,696 | (val ulterior) | | `bara_poi_E` |
| F podul | ~0,714 | (val ulterior) | | `bara_poi_F` |
| G ravaneto | 0,714–0,911 (sania la 0,769) | (val ulterior) | `--rock-at=<s>` | `bara_poi_G` |
| H Marmifera | 0,951–0,974 | (val ulterior) | | `bara_poi_H` |

## Piesele disponibile

**Kitul Carrara** (`assets/models/carrara/`; cote și sloturi în inventare):
- roci: `marble_block_a/b/c`, `block_stack_a/b`, `block_informe_a/b`, `rubble_pile_a/b`;
- recuzită: `cable_reel`, `fuel_tank`, `water_tank`, `work_lamp`, `pipe_run`,
  `quarry_sign_a/b`, `office_container`;
- structuri: `safety_berm` (deja în cod ca bermă continuă: nu dubla),
  `gallery_portal`, `marmifera_portal`, `ponti_di_vara`;
- **valul 2** (după integrarea lui; vezi `carrara_inventory_crr-d/e/f.md`):
  `wire_saw` (volantul `Blades` se rotește), `chain_saw_crawler`, `drill_rig`,
  `museum_set_cart/wheel/sled`, `quarry_sign_block`, satul `colonnata_*`, fundalul.

**Reuse** (cu clase deja mapate pe tema Carrara): `beech_tree_a/b` (castanii,
coroana pe `tf_beech`), `scree_cone` (pe `carrara_marble`), `ginestra_bush`
(Stromboli, flori galbene).

**Hazardele nu se mută din zonă**: camioanele (`BusHazard` pe curbe), derrick-ul,
excavatorul și sania sunt în generator, nu în fișierele de zonă. Decorul le
ocolește: generatorul marchează piesele la mai puțin de 6 m de curba unui
camion sau la mai puțin de 15 m de turnul derrick-ului.

## Contractele (valul POI 1: A, B, C)

Fiecare contract are trei părți: **ce se vede în decupaj** (obligația
vizuală), **ce cere brieful** (gameplay-ul, care nu se strică) și **capcana**
(memoria care se aplică).

### A — Piazzale-ul (frac 0,00–0,06, `zona_a.py`)

**Din decupaj:**
- platoul mare de **pulbere bej bătătorită**;
- **blocuri crem stivuite** câte 2–3 pe marginea dinspre gol;
- **magazia joasă cu acoperiș de tablă**;
- **excavatorul cu furcă**;
- **roata de fir** pe suport, **vagonetul cu un bloc**;
- o **cabană / turn de piatră pătrat**;
- rezervoarele albastre lângă portalul Marmifera;
- **lizieră verde-galbenă** (castani, ginestra) pe muchia de sub platou.

**Din brief:** start pe grilă, coridorul de blocuri pe ambele părți (există:
11 piese), containerul, rezervorul, lampa, **colțul de muzeu**
(`museum_set_cart/wheel/sled`, valul 2), bălțile se văd **23 m sub tine** pe
dreapta, peste bermă. Excavatorul e hazardul, deja montat la 0,05 pe dreapta.

**Capcana:**
- grila de start și primele 100 m sunt plutonul strâns: nimic nou la mai puțin
  de 3 m de asfalt pe 0,00–0,05 fără ProbeRace;
- coridorul din stânga se oprește înainte de ieșirea camionului 1 (x > −50);
- pe dreapta, nimic nu acoperă vederea spre bălți (e momentul de dezvăluire de la start).

### B — Gradonii (frac 0,058–0,266, `zona_b.py`)

**Din decupaj:**
- **trepte cu fețe verticale crem, cu dungi orizontale de fir și dâre de rugină**
  (există deja pe teren, clasa `carrara_marble`);
- pe fiecare **banc plat**, **blocuri răzlețe și moloz** la piciorul peretelui;
- **șirul de blocuri pe muchia dinspre gol**;
- drumul în ace;
- **camionul basculant** (hazardul, există).

**Din brief:**
- **teatrul de pe terase, la 3–5 m de bandă**: mașini de fir cu volantul
  învârtindu-se și jetul de apă (`wire_saw`, valul 2), blocuri proaspăt tăiate,
  cabluri (`cable_reel`, `pipe_run`);
- **bermele doar la vârful acelor** (berma continuă din cod e deja pe marginile cu gol).

**Capcana:**
- **camionul vine din față**: decorul de pe terase stă pe partea **opusă**
  curbei camionului, iar generatorul marchează `PREA APROAPE` sub 6 m;
- în ace, interiorul e linia de cursă și linia de scăpare a AI-ului: nimic pe
  interiorul acelor (memoria `dunele-hairpin-pileup`);
- nimic pe banda de cădere a mașinilor (RespawnZone sub muchii).

### C — Fundul carierei (frac 0,296–0,400, `zona_c.py`)

**Bălțile NU există încă pe Track23** (31 oct 2026): pasul 6 al brief-ului nu
le-a pus. Există doar podeaua râpei 1 (fundul carierei, `ravines` în
generator). Ele sunt obligația principală a lui C și se construiesc din
mecanismele existente:
- `custom_ravine_water` (indicele râpei, cota ABSOLUTĂ a apei, elanul la
  repunere), cu o adâncitură locală în podea ca apa să rămână **bălți**, nu
  un lac pe tot fundul (`custom_ravine_floor_slopes` sau un mecanism de teren
  local, de citit în `TrackSideSampler`);
- `custom_water_styles`, pentru turcoazul opac: `REEF_SHALLOW` 17 spre
  `CORAL_SAND` 19, mată, `water_dim` ridicat;
- **contractul măsurabil** (brief §4): balta rămâne **turcoaz, nu gri**,
  adică saturație ≥ 0,25 pe masca bălții, măsurată pe captură
  (memoria `apa-iluminata-v12`: aici opacul e corect).

**Doar constructorul C atinge în generator liniile de apă / podea ale râpei 1**
(nimeni altcineva nu le atinge). **Scurtătura prin marginea bălții**
(`TrackBranch` la 0,33, brief §2) nu există și e gameplay, nu decor: nu intră
în gauntlet, decizia e a dezvoltatorului.

**Din decupaj:**
- podea de praf **cu bălți turcoaz opace** cu margine de calcit;
- **derrick-ul cu blocul agățat** (hazardul, există);
- **mașina de tăiat cu lanț pe șenile, cu lama în perete** (`chain_saw_crawler`, valul 2);
- **blocuri informe și moloz** împrăștiate pe podea (5 există);
- **gura galeriei** cu lumini (portalul există).

**Din brief:**
- ferăstrăul-lanț **taie la perete**: lama intră în fața de marmură, deci se
  așază cu vârful lamei în perete, nu în aer;
- drumul plat de 9 m e ud (grip scăzut, `custom_wet_ranges`, există).

**Capcana:**
- **turnul derrick-ului**: nimic la mai puțin de 15 m (raza sarcinii 13 m);
- **ejectarea la 30 m/s** de la `C_Informe3` la 8,5 m: blocurile pe exteriorul
  cotului 2 stau la ≥ 12,5 m;
- pe stânga, peretele ravenei urcă de la −10 m.

## Raportul constructorului (la fiecare rundă)

- SHA-urile;
- piesele adăugate (nume, frac, lateral, cotă);
- capturile (căi absolute);
- gărzile cu cifre față de linia de bază;
- ce a cerut criticul în runda precedentă și ce s-a schimbat.

Constructorul **nu își judecă singur planșa oarbă**: o face criticul, pe
planșa produsă de coordonator.
