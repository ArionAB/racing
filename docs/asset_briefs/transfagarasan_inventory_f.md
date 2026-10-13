# Inventar Transfăgărășan — val 2, grupa tf-f (vehicule de decor + ciobănescul)

Contract: `transfagarasan_kit.md` §1.6 (`sheepdog`), §1.7 (`parked_car_a/b`,
`motorbike`), cu corectura de coordonator **„Mașinile parcate NU au voie să
semene cu Dacia”**. Trenul și cabina nu sunt aici (valul 3).

| fișier | ce |
|---|---|
| `tools/blender/build_tf_vehicles.py` | cele 3 vehicule (`TF_ONLY=<piesă>` reface una) |
| `tools/blender/build_tf_animals.py` | ciobănescul |
| `tools/blender/preview_tf_f.py` | `--compare/--views` (harnasul) + `--ab`, `--lineup`, `--herd` |
| `tools/blender/measure_tf_f.py` | `aabb` (gabarite din GLB, transformuri complete) și `legs` (% vârfuri sub `leg_top` pe nodul pe care îl ia `HerdHazard`) |
| `verify_transfagarasan.sh` | secțiunea „val 2, tf-f” |

`bash tools/blender/verify_transfagarasan.sh` → **VERDICT KIT: OK**.

## Gabaritul mașinii de joc (măsurat)

`scenes/cars/Car.tscn` nu conține forma de coliziune în text: e un `RigidBody3D`
cu `car.gd`. Carcasa o creează scriptul:

| sursă | lățime X | înălțime | lungime Z | notă |
|---|---:|---:|---:|---|
| `car.gd:482` (`_ready`, carcasa din Car.tscn) | **2,20** | 1,00 | **3,80** | talpa la +0,25 |
| `car.gd:550` (`apply_data`) | `body_width*0,9` | 1,00 | `body_length*0,85` | se aplică pe fiecare mașină |
| Muscle (`selected_car = 0`, implicită) | 1,80 | 1,00 | 3,71 | body 2,00 × 4,37 |
| Buggy / Taxi / Poliția | 1,87 / 1,85 / 1,80 | | 3,15 / 3,37 / 3,71 | |
| Pompierii / Autobuzul | 1,89 / 1,89 | | 4,22 / 4,73 | |

Modelele vizuale ale garajului (`measure_tf_f.py aabb`):
- `open_roadster` 2,10 × 1,60 × 4,37;
- `open_police` 2,06 × 1,88 × 4,36;
- `open_taxi` 2,18 × 2,06 × 3,96;
- `toy_buggy` 2,12 × 1,61 × 3,50.

**Decizia:** mașinile parcate sunt pe **carcasa din Car.tscn, 2,20 × 3,80**. Două motive:
- e cifra literală a contractului;
- stă în plaja vizuală a garajului (2,06–2,18 lățime, 3,50–4,37 lungime).

Pe carcasa efectivă a mașinii implicite (1,80 × 3,71), mașinile parcate ar fi
ieșit vizibil mai înguste decât mașina jucătorului (2,10). Coliziunea
mașinilor parcate rămâne a coordonatorului.

## Măsurat pe GLB (`measure_tf_f.py aabb`, axe Godot)

| piesă | X lățime | Y înălțime | Z lungime | contract | tri |
|---|---:|---:|---:|---|---:|
| `vehicles/parked_car_a.glb` | **2,200** | 1,625 | **3,808** | 2,20 × 3,80 | 3 768 |
| `vehicles/parked_car_b.glb` | **2,200** | 2,239 (1,91 la plafon, restul e cutia) | **4,364** | 2,20 × 4,37 (+15 %) | 5 364 |
| `vehicles/motorbike.glb` | 0,970 | **1,345** | **2,194** | 2,2 × 1,3, ~10° | 3 952 |
| `animals/sheepdog.glb` **rev. 2** | 0,674 | 1,318 (greabăn ~1,02) | 2,132 (trunchi 1,15) | 1,0 greabăn, trunchi 1,15 (contract revizuit) | 1 852 |

Nodurile au fiecare un singur slot, cu excepția câinelui, care e un singur nod
cu trei sloturi (contractul `HerdHazard`):
- `parked_car_a`:
  - `Car_Body` CAR_BLUE 15 (1 208);
  - `Car_Glass` VOLCANIC_BLACK 20 (636);
  - `Car_Tyre` VOLCANIC_BLACK 20 (432);
  - `Car_Trim` ASPHALT 5 (396);
  - `Car_Hub` MARBLE_GREY 29 (832);
  - `Car_Lamp` FOAM_WHITE 22 (176): farurile și plăcuțele goale;
  - `Car_Tail` KERB_RED 7 (88).
- `parked_car_b`: aceleași noduri, cu `Car_Body` pe CAR_RED 14 (1 196) și
  `Car_Trim` de 2 060 (barele de plafon, cutia, buzele arcadelor).
- `motorbike`:
  - `Moto_Body` CAR_BLUE 15 (100);
  - `Moto_Metal` PAINTED_METAL 11 (1 840): furca, jantele, chiulasa, toba,
    gențile, parbrizul, cricul;
  - `Moto_Dark` VOLCANIC_BLACK 20 (1 988);
  - `Moto_Lamp` FOAM_WHITE 22 (12);
  - `Moto_Tail` KERB_RED 7 (12).
- `sheepdog` (rev. 2): un singur nod `Sheepdog` (1 852), cu CORAL_SAND 19,
  ASPHALT_EDGE 6 (pata, masca, urechile) și VOLCANIC_BLACK 20 (nasul, ochii).

Origini:
- vehiculele au originea în centrul amprentei, la sol, cu fața pe +Y Blender
  (−Z Godot);
- motocicleta e înclinată 10° spre −X, în jurul liniei de contact a roților;
  cricul atinge solul;
- câinele are originea la sol, între perechea de labe din față
  (Godot z = −0,50) și cea din spate (z = +0,50). Așa, `side` din shader-ul
  de galop desparte corect fața de spate.

### Contractul turmei (`sheepdog`)

`measure_tf_f.py legs` urmează DFS-ul din `HerdHazard._animal_mesh_from`.

| model | nodul luat de turmă | vârfuri | sub 0,45 m | sub 0,55 m |
|---|---|---:|---:|---:|
| `sheepdog.glb` rev. 2 | `Sheepdog` (singurul) | 2 680 | **21,9 %** | 34,0 % |
| `sheepdog.glb` rev. 1 (istoric) | `Sheepdog` | 1 538 | 24,4 % | 32,1 % |
| `monumentvalley/.../sheep.glb` | `Pose_Walk` | 1 187 | **37,4 %** | 46,0 % |
| `serengeti/.../wildebeest.glb` (referință) | `Wildebeest` | 550 | — | 36,7 % |

- La câine (rev. 2), burta e la 0,465 m și franjurii ei coboară la ~0,46 m,
  deci peste `leg_top` 0,45. Coada pornește de la ~0,80 m. Cu
  `leg_top = 0,45` se leagănă doar picioarele, labele și partea de jos a
  „pantalonilor”.
- Câinele are procentul mai mic decât oaia fiindcă trunchiul (loft-ul cu
  12 puncte pe inel), coama, capul și coada (bulgări `clump`) au mai multe
  vârfuri decât picioarele (tuburi cu 6 laturi). Shader-ul deplasează liniar pe y, deci un picior cu 3 inele
  se leagănă corect și cu puține vârfuri.
- `leg_top` e un singur uniform pe material, comun oii și câinelui, deci se
  alege la integrare pentru amândoi:
  - la 0,45 se leagănă picioarele oii și jumătatea de jos a burții ei
    (37 % din vârfuri);
  - la 0,55, la câine intră în leagăn și franjurii burții, cu o amplitudine
    de ≤ 3 cm.

## Fidelitate

Imaginile sunt în `docs/asset_briefs/img/transfagarasan_fidelity/`. Fiecare
comparație are decuparea în stânga și randarea din GLB în dreapta, pe
culoarea slotului:
- `parked_car_a.png` + `_views.png`;
- `parked_car_b.png` + `_views.png`;
- `motorbike.png` + `_views.png`;
- `sheepdog.png` + `_views.png`;
- **`parked_car_ab.png`**: A și B alăturate, din 3/4, profil, față și spate;
- **`parked_cars_vs_game.png`**: A, B și `open_roadster.glb` (mașina
  implicită), cu două cutii-sârmă:
  - cea neagră e carcasa din Car.tscn (2,2 × 1,0 × 3,8);
  - cea roșie, pe roadster, e carcasa lui efectivă (1,80 × 3,71);
- **`sheepdog_herd.png`**: câinele printre 6 oi (`Pose_Walk`, spacing ca pe
  Track21), cu roadster-ul pe drum. În stânga e cadrul camerei de joc
  (12,5 m în spate, 10 m sus, ținta la 5 m în față, fov vertical 68); în
  dreapta, aceeași direcție de privire, mai aproape.

### parked_car_a — 3 runde

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| silueta | sedan Logan, capotă lungă, portbagaj | hatchback de jucărie: capotă scurtă, seră mare, hayon aproape vertical, roți mari | **corectura** (nu Dacia) |
| roți | 4, jante argintii cu spițe | 4 × R 0,40, disc argintiu + capac, fără spițe | OK; spițele nu se văd la 30 m |
| arcade | decupate | decupate în flanc (talpa urcă pe cercul arcadei) | OK |
| geamuri | parbriz, lunetă, 3 laterale pe parte | parbriz, lunetă, 3 laterale pe parte (plăci la 1,4 cm de caroserie) | OK |
| oglinzi | 2 | 2, în culoarea caroseriei | OK |
| faruri | în Y (Dacia) | 2 dreptunghiuri albe | **corectura** |
| grilă | bară cromată + siglă | o fantă neagră | **corectura** |
| bare | caroserie + plastic jos | plastic ASPHALT | abatere de rol (kit §0: plastic ASPHALT) |
| plăcuță | cu caractere | albă, goală | regula 9 |
| bare de plafon | 2 | nu (sunt semnul lui B) | abatere voită |
| culoare | albastru închis | CAR_BLUE `#2C82E8`, mai deschis | slotul din kit |

Rundele:
1. Cutie de SUV, cu plafon plat și înalt (1,71 m); citea „Niva”, nu hatchback.
2. Plafonul coborât la 1,62 m, parbrizul mai culcat, capota scade spre bot,
   roțile la R 0,40, eleronul micșorat.
3. Geamurile laterale mărite până la muchia plafonului, iar geamul din față
   prelungit spre stâlpul A.

**Abateri rămase:**
- caroseria e plinuță, cu sera încă înaltă (toy). Pe decupare plafonul e mai
  bombat și mai lung spre spate;
- fără linii de uși și mânere.

### parked_car_b — 1 rundă

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| silueta | SUV compact Duster | break/SUV înalt, cu plafon lung și drept, stâlpul D vertical, garda la sol mare | **corectura**; tipul diferă de A |
| arcade | cu plastic gri închis | buză-tub ASPHALT pe fiecare arcadă | OK |
| bare de plafon | 2 | 2 pe 3 piciorușe | OK |
| cutia de plafon | — | 1,20 × 0,86 × 0,26 m, pe bare | contract |
| faruri / grilă | Duster / Dacia | dreptunghiuri + fantă | **corectura** |
| placare jos | bandă închisă pe uși | bandă ASPHALT | OK |
| stopuri | — | orizontale, în colțuri | OK |
| lungime | — | 4,364 (A × 1,148) | OK |

**Abateri:**
- fața lui B are același vocabular ca A (dreptunghiuri + fantă): cele două
  diferă ca siluetă, culoare și echipament, nu ca față;
- înălțimea cu cutia e 2,24 m, mai înaltă decât orice mașină din garaj
  (maximum 2,06).

### motorbike — 3 runde

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| roți | 2 egale, jante cu spițe | față R 0,37 / spate R 0,35; anvelopă-tor, inel metalic, 6 spițe, disc negru | OK |
| furcă | tuburi aurii | 2 tuburi PAINTED_METAL, la ~27° | OK (culoarea vine din slot) |
| carenaj + far | semicarenaj sport-turism | semicarenaj unghiular + far dreptunghiular + cioc (aventură) | contract |
| parbriz | mediu, transparent | înalt, PAINTED_METAL | OK; „sticla” e gri-albăstruie |
| ghidon | îngust, oglinzi | lat, 2 apărători de mâini, 2 oglinzi | contract |
| rezervor | albastru, cu flancuri | albastru, cu flancuri + capace laterale până la coadă | OK |
| șa | în două trepte | în două trepte | OK |
| motor | gri închis | carter negru + chiulasă metalică + scut | OK |
| tobă | pe dreapta | pe dreapta, ridicată | **ascunsă** în 3/4 de geanta din dreapta |
| genți | — | 2, metal cu capac negru, pe ramă | contract |
| cric | lateral, stânga | stânga; motocicleta înclinată 10° pe el | contract |

Rundele:
1. Jantele erau discuri pline, iar ciocul era o scândură.
2. Jante cu inel și spițe, carterul negru, aripa joasă peste roată, ciocul ca
   pană.
3. Capace laterale albastre sub șa, furca îngroșată.

**Abateri rămase:**
- carenajul și rezervorul se citesc ca blocuri unghiulare separate, mai puțin
  fluide decât decuparea;
- zona motorului e aglomerată de tuburi negre;
- aripa față și ciocul ies destul de mult în față.

### sheepdog — REV. 2, pe contractul revizuit (2 runde din 2)

Rev. 1 (3 runde, istoric): din camera de joc citea „oaie palidă” sau „capră pe
picioroange”, adică o cutie lungă pe patru bețe. Coordonatorul a revizuit
contractul (kit §1.6 și rândul „ciobănescul” din tabelul de sloturi,
actualizate în același commit).

| element | contractul rev. 2 / planșa | în GLB | verdict |
|---|---|---|---|
| trunchi | masiv, adânc, 1,15 m umăr–crupă, pieptul ≥ 0,55 din greabăn, burta peste 0,45 | loft continuu, de la +0,56 la −0,59 (1,15 m); spinarea la 1,01–1,05; burta la 0,465 (adâncime 0,55–0,58) | OK |
| coama | masă lățoasă pe gât și piept, fața mai lată decât crupa | `clump`-uri: gâtul (0,56 lat), jaboul, 2 pe laturile pieptului; fața are ~0,67 m lățime, crupa ~0,50 | OK |
| picioare | scurte, groase (≥ 0,18 m sus), labe late | tuburi de 0,23–0,25 m sus și 0,18 jos, de la 0,62 m la sol; labe de 0,19 × 0,23 | OK; din profil încă se văd drepte, ca stâlpi |
| pantaloni | conturul se lărgește la coapsă | 2 `clump`-uri pe fiecare coapsă din spate (0,24 × 0,34 × 0,40) + franjuri după picioarele din față | OK |
| cap | mare (~0,40 m), bot scurt și lat, urechi atârnate | craniu de 0,40 × 0,34 × 0,34, închis; bot alb de 0,25 lat; urechi atârnate, închise | OK |
| masca / dunga | cap gri-închis, dungă albă pe frunte, bot alb | craniu ASPHALT_EDGE, dungă albă mică pe frunte, bot alb, nas și ochi negri | OK; dunga e un smoc mic, pe planșă e mai lată |
| pata | gri-închis, pe umăr, coborând pe flanc | `clump` plat pe spate + câte unul pe fiecare flanc, ASPHALT_EDGE, margini pe fațete | **abatere**: pe flanc pata iese ca o placă cu muchie dreaptă de jos, nu ca pata organică de pe planșă |
| coada | smoc mare, stufos, curbat în sus, ca masă aproape cât capul | 5 `clump`-uri pe arc: iese înapoi din crupă și se ridică până la ~1,24 m | OK; e mai mult „pompon pe arc” decât panașul continuu de pe planșă |
| contur lățos | zimțat | `clump` pe spinare, piept, gât, pantaloni, coadă și franjurii burții | OK ca formă; fațetele sunt mari, nu fir |

Rundele:
1. Contractul nou aplicat. Coada a ieșit coloană verticală de bulgări,
   smocurile de pe flanc păreau umflături, iar dunga de pe frunte ieșea ca un
   corn.
2. Coada pusă pe arc, cu bulgări mari suprapuși; smocurile de flanc mutate jos
   ca franjuri ai burții (peste 0,46 m); dunga aplatizată; pata de pe flanc
   apropiată de suprafață.

Am păstrat runda 2: coada și burta, care sunt puncte de contract, sunt mai
bune. Pata de flanc a ieșit mai plată (placă) decât în runda 1, iar asta e
abaterea rămasă.

**Captura cu turma** (`sheepdog_herd.png`, camera de joc: 12,5 m în spate, 10 m
sus, fov vertical 68; turma la ~9–11 m în fața mașinii, adică ~23 m de cameră).
Întrebarea „de la 30 m se vede un câine mare printre oi?”:
- **în cadrul de joc întreg (stânga): se vede un animal DIFERIT**, mai înalt
  decât oile, alb cu cap închis, cu pete închise pe spate și coada ridicată.
  Animalul are însă ~25 px în 1280 × 720, iar „câine” ca specie se citește
  la limită: din pete și coada sus, nu din formă;
- **în vederea apropiată (dreapta), da**: câine mare, alb cu cap închis,
  printre oi, mai înalt cu o treime decât ele;
- pe culoare se deosebește acum de oi prin capul închis și pete (ASPHALT_EDGE),
  nu doar prin siluetă, cum era la rev. 1.

## Decizii luate singur

1. **Gabaritul** e carcasa din Car.tscn (2,20 × 3,80), nu carcasa efectivă a
   mașinii Muscle (1,80 × 3,71). Motivul e mai sus.
2. **Lungimea câinelui** e lungimea trunchiului (de la vârful umărului la
   vârful crupei). La rev. 1 am interpretat „1,3 m” ca trunchi; contractul
   rev. 2 fixează explicit trunchiul, la 1,15 m. De la nas la vârful
   cozii are 2,13 m. În turmă, `ANIMAL_LEN` e 1,7.
3. **Un nod pe slot la vehicule:** am pus 7 noduri pe mașină în loc de cele 3
   numite în contract:
   - farurile, stopurile, jantele și plasticul au primit fiecare nodul lor;
   - jantele sunt pe MARBLE_GREY (argintiu), iar farurile și plăcuța goală
     pe FOAM_WHITE. Niciunul nu e în tabelul de sloturi;
   - stopurile sunt pe KERB_RED, inclusiv la motocicletă.
4. **Gențile motocicletei** sunt pe PAINTED_METAL, ca aluminiul, nu pe
   MARBLE_GREY, ca să rămână în sloturile contractului. Parbrizul e tot pe
   PAINTED_METAL.
5. **Bare de plafon doar pe B** (pe planșă le are și A), ca să difere
   tipurile.

## De făcut la integrare (coordonatorul)

- `HerdHazard` de pe Track21:
  - `alt_model = res://assets/models/transfagarasan/animals/sheepdog.glb`;
  - `zebra_ratio` ~0,1 (1 câine la ~10 oi);
  - `leg_top` comun cu oaia: 0,45 sau 0,55, de verificat pe captura de joc.
- Coliziunea mașinilor parcate (cutia de 2,2 × 3,8 / 2,2 × 4,37) și a
  motocicletei.
- Dacia, pe captura din joc: ambele mașini au grila-fantă și farurile
  dreptunghiulare. Dacă tot citesc „Dacia” prin culoare (B roșu ca Duster-ul
  de pe planșă), se poate muta B pe alt slot de mașină.

## Stare la oprire (13 oct 2026)

**Făcut:** toate 4 piesele, plus verify, preview, `measure_tf_f.py` și
inventarul.

**Rundele:**

| piesă | runde folosite |
|---|---|
| `parked_car_a` | 3 / 3 |
| `parked_car_b` | 1 / 3 |
| `motorbike` | 3 / 3 |
| `sheepdog` | rev. 1: 3 / 3; rev. 2 (contract revizuit): 2 / 2 |

Coordonatorul a acceptat `parked_car_a`, `parked_car_b` și `motorbike` (13 oct
2026). Rundele rămase pe B nu se mai folosesc. `sheepdog` rev. 2 așteaptă
verdictul.

**Abaterile cu cel mai mare risc:**
- **câinele (rev. 2):** pata de pe flanc e o placă cu muchie dreaptă; coada
  e din bulgări (pompon), nu un panaș continuu; în cadrul de joc întreg
  animalul are ~25 px, iar „câine” se citește la limită;
- **motocicleta:** carenajul e din blocuri unghiulare.
