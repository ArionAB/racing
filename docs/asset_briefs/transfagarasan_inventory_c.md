# Inventar Transfăgărășan — grupa tf-c („ursul”), valul 1

Piesa: `assets/models/transfagarasan/animals/brown_bear.glb`, scrisă de
`tools/blender/build_tf_bear.py`. Capturile le face `tools/blender/preview_tf_bear.py`
(separat de `preview_transfagarasan.py`, dar îi refolosește randarea: aceeași
lumină, fundal `#C4C4C4`, culoarea reală a slotului din UV). Fiecare cadru e
înghețat într-un mesh static din obiectul evaluat, deci captura arată geometria
deformată de schelet, nu poza de repaus.

```
D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- build_tf_bear.py
D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- preview_tf_bear.py -- --all
bash tools/blender/verify_transfagarasan.sh      # VERDICT KIT: OK
```

## Sursa și licența

**Mesh propriu, rig scris în cod** (rețeta elefantului și a țestoasei). Geometria e
a proiectului, deci nu există o licență terță.

| sursă căutată | ce are | de ce nu |
|---|---|---|
| `Animals/191 animals pack/animalpack.blend` (.fbx, .obj) | singurul urs: `Polar_Bear_Low_Poly` | **fără fișier de licență** (dosarul are doar capturi de ecran, `Yeni klasör`). În plus, silueta e de urs polar: gât lung, cap mic, fără cocoașa de umeri după care se citește ursul brun |
| `Ultimate Animated Animals - July 2021` (Quaternius, **CC0**, `License.txt`) | Wolf, Husky, Bull, schelete de patruped | mesh de lup, câine sau taur. Rig-ul n-are coloană pe care s-o controlăm pentru ridicarea în două labe, iar mesh-ul ar fi trebuit refăcut oricum |
| `Farm Animal Pack-glb`, `Godot_4.7_Animals...` (ithappy) | fermă, cerb, tigru, câine... | niciun urs |

Decuparea e un urs cu **fațete mari**, triunghiuri plate. Forma asta iese direct din
puține secțiuni transversale (elipse), unite în fâșii cu diagonale alternante, cu
jitter determinist și umbrite plat.

## Cote măsurate (pe mesh-ul evaluat cu scheletul aplicat)

Cotele sunt după revizia de formă și culoare (contractul revizuit al
coordonatorului, vezi „Fidelitate”).

| cotă | contract | măsurat | |
|---|---|---|---|
| lungimea în patru labe (bot–crupă, `Idle` cadrul 0) | 2,6 m | **2,58 m** | −0,8% |
| greabănul (cocoașa, `Idle` cadrul 0) | 1,4 m | **1,38 m**, la Y = +0,23 (deasupra labelor din față) | −1,4% |
| cocoașa peste crupă | 0,15–0,20 m | **0,19 m** (crupa 1,19 m) | OK |
| adâncimea burtă–spinare | ~0,80 din greabăn | burta la 0,32 m, adâncimea 1,06 m = **0,77** | OK |
| lățimea la umeri | ~1,1 m | **1,07 m** | OK |
| capul | ~0,50 lat, ~0,60 lung | ~0,58 lat (0,60 cu urechile), ~0,65 de la ceafă la nas | OK, puțin mai mare |
| înălțimea ridicat (`Stand`, cadrul final, ținut) | 3,0 m | **2,91 m** (2,93 la depășirea din cadrul 23) | −3% |
| baza, pe toate cadrele cheie ale celor 3 clipuri | 0 | 0,000 ±0,002 m | nicio labă în sol |
| originea | la bază, centrată | centru XY (0,000; 0,000), Y glTF de la 0,000 | OK |
| fața | +Y Blender = −Z Godot | osul `Head` la z = −0,70 în glTF, `Hips` la +0,88 | OK |

## Geometria, scheletul, clipurile

- **Triunghiuri:** 1.144. Un singur mesh, un material (atlasul).
- **Sloturi** (aria fețelor), după contractul revizuit:

| slot | arie | unde |
|---|---|---|
| `LARCH_RUST` 27 | **77,3%** | blana dominantă, inclusiv burta |
| `LOG_DARK` 28 | **22,1%** | gambele și labele din spate, jumătatea de jos a antebrațelor, tălpile labelor din față, partea de jos a coapselor și brațelor, sub bărbie |
| `SAND_MID` 1 | 0,2% | vârful botului |
| `VOLCANIC_BLACK` 20 | 0,4% | nasul, ochii, 4 gheare pe labă |

  Granița rust/dark e un prag pe înălțime + 0,22 × normala.z (în poza de repaus),
  cu un zgomot determinist pe fiecare fațetă. Urmează deci fațetele în trepte,
  nu o linie dreaptă, și nu există placă pe creastă. AO e gradient vertical
  0,60 → 1,00 (`COLOR_0`), nu raycast.
- **Oase (15):**
  - `Hips` e rădăcina, cu pivotul la articulația șoldului;
  - `Chest` are pivotul în mijlocul spatelui;
  - `Head` are pivotul la baza gâtului;
  - fiecare picior are 3 oase: `LegFU/LegFL/PawF_{L,R}` și `LegHU/LegHL/PawH_{L,R}`.

  Greutatea e **rigidă pe piese**: fiecare piesă e o insulă, iar piesele se
  suprapun la încheieturi. Armătura e la identitate pe nodul rădăcină `BrownBear`
  (scala și rotația sunt `None` în glTF), deci nu e nimic de aplicat.
- **Clipurile**, citite din GLB:

| clip | durata | buclă | ce face |
|---|---|---|---|
| `Idle` | **2,000 s** (48 de cadre la 24 fps) | se închide (primul cadru = ultimul). Bucla o pune `SlidingHazard._hook_animation` | respiră (pieptul se umflă 1°, umerii rămân pe loc), adulmecă: capul coboară 9° și se întoarce ±7° |
| `Walk` | **1,167 s** (28 de cadre) | se închide. Bucla o pune `_hook_animation` | **secvență laterală în patru timpi** (HL, FL, HR, FR), ca la ursul real. Fiecare labă stă 65% din ciclu pe sol, deci sunt mereu cel puțin două jos. Laba din sprijin merge înapoi **liniar** (IK în două segmente), așa că nu patinează. Corpul coboară până la 10 cm: „pasul greu”. Umerii se leagănă, iar capul dă din cap la fiecare pas din față |
| `Stand` | **1,167 s** (28 de cadre, sub telegraful de 1,2 s) | **nu** (se joacă o dată și ține ultimul cadru) | ține capul jos și adulmecă (cadrul 5), se ridică din șold (60°) și din mijlocul spatelui (18°), cu spatele întins cu 0,27 m. Depășește puțin (cadrul 23), apoi se așază (cadrul 28). **Poza finală:** trunchiul la ~78° (aplecat ușor înainte), genunchii îndoiți 12° cu tălpile plate. **Brațele depărtate 15°**, antebrațele atârnă din cot 46° înainte, laba moale în jos. Capul e scufundat 5 cm între umeri, cu botul 8° în jos, **întors 12°** ca pe decupare. Fără gesturi umane |

- **Fără root motion.** Toate cheile sunt pe oase, nodul nu se mișcă. Pe fiecare
  cheie, o „corecție de sol” pune punctul cel mai de jos pe y = 0. Corecția e
  ≤ 1,0 cm la `Walk` și 0 la `Idle`. La `Stand` e −3,6 cm: genunchii îndoiți
  coboară șoldul, iar tălpile rămân plate pe sol.
- **Revizia de formă n-a atins tehnica:** scheletul, IK-ul, clipurile și duratele
  sunt aceleași (recitite din GLB). În `Stand` s-au adăugat doar câteva rotații:
  brațele depărtate, antebrațul, genunchii și capul întors.
- **Viteza naturală a lui `Walk`:** laba din sprijin se duce înapoi cu **0,97 m/s**
  la ritm 1 (măsurat atât pe față, cât și pe spate), iar laba se ridică maximum
  0,13 m. Ursul **nu** e în `WALK_CYCLE_SPEED_BY_MODEL`, deci azi ar lua 1,5 m/s
  implicit și ar patina. La integrare ar trebui adăugat `&"brown_bear": 0.97`. Cu
  `sweep_speed = 1,8` de pe marker, ritmul iese 1,86 și un ciclu durează 0,63 s,
  adică un pas grăbit. Dacă se vrea „pas greu” și în joc, `sweep_speed` trebuie
  coborât spre ~1,2. Asta e decizia coordonatorului (`scripts/`, `scenes/`).
- **Cheile pornesc de la timpul 0.** Exportatorul scrie timp = cadru / fps.
  Cu cheile de la cadrul 1, clipurile ieșeau 1,208 s (`Stand` depășea
  telegraful), iar bucla ar fi stat un cadru pe loc.

## Fidelitate

Comparațiile, cu decuparea în stânga și randarea din GLB în dreapta, la aceeași
înălțime:
- `docs/asset_briefs/img/transfagarasan_fidelity/brown_bear_walk.png`
  (`Walk`, cadrul 4, camera la azimut 45°, ca decuparea);
- `docs/asset_briefs/img/transfagarasan_fidelity/brown_bear_stand.png`
  (`Stand`, cadrul final, azimut 50°: brațul drept al ursului e în stânga
  imaginii și capul spre dreapta, ca pe decupare).

Planșa de cadre e `brown_bear_frames.png`: `Idle` 1, `Walk` 2, `Stand` la început,
la mijloc și la capăt. Etichetele numără cadrele de la 1. `brown_bear_stand_views.png`
arată poza `Stand` din 4 azimuturi.

h/l se măsoară pe bounding box-ul pixelilor ursului: saturație > 28 sau
luminanță < 120, aceeași mască pe decupare și pe randare.

### Prima serie (3 runde): respinsă de coordonator pe formă și culoare

În patru labe se citea jder sau câine: spinare dreaptă, fără cocoașă, cutie
lungă, cap mic. Ridicat era un stâlp (h/l 2,48). Blana era `LOG_DARK`, cu o „șa”
ruginie pe creastă. Tehnica a fost acceptată.

### A doua serie (contract revizuit, 3 runde)

1. Corp rotund (elipse) și adânc, cu cocoașa la 1,40 m și crupa la 1,22 m, plus
   picioare mai groase și cap mare. Am trecut culoarea pe `LARCH_RUST` dominant și
   am pus brațele depărtate, genunchii îndoiți și capul întors în `Stand`.
   Rezultat: în patru labe citea urs. Ridicat însă burta (închisă în repaus)
   devenea toată fața ursului, deci un piept negru; botul `SAND_MID` era prea mare
   și citea cioc.
2. Crupa și pieptul mai late (1,12 m la șold), antebrațul mai înainte. Pe
   trunchi rămâne închisă doar fâșia de sub burtă. Am micșorat botul deschis la
   vârf și am mutat camera de mers la azimutul decupării.
3. Am echilibrat culoarea: rugina ~75%, închisul ~25%. Labele din față nu mai
   sunt „mănuși” închise: doar talpa e închisă, iar antebrațul are rugina
   corpului până la jumătate.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| silueta în patru labe, h/l | 0,69 | **0,65** | OK (−6%) |
| cocoașa de umeri, cel mai înalt punct, peste labele din față | da | 1,38 m la Y = +0,23, cu 0,19 m peste crupă | OK |
| spinarea coboară spre crupă | da | da | OK |
| corp rotund și adânc, nu cutie | da | secțiuni eliptice, adâncimea 0,77 din greabăn | OK |
| picioare groase, labe late | da | brațul și coapsa 0,44–0,50 m sus, labele 0,34 m | OK |
| cap mare, frunte lată, bot îngustat, urechi rotunde scurte | da | ~0,58 × 0,65 m, urechi-disc | OK. Botul rămâne ceva mai lung și mai drept decât pe decupare |
| culoarea | maro-roșcat uniform | `LARCH_RUST` 75%, picioarele de jos `LOG_DARK` | OK. În patru labe citește urs roșcat cu „șosete” închise, fără pete. Vaca (`WOOD` + pete crem) nu are cocoașă, iar ursul nu are pete |
| silueta ridicată, h/l | 1,68 (coordonator); **1,79** măsurat de mine pe decupare cu masca de mai sus | **1,96** | +9,5% față de 1,79, deci în ±15%. Față de 1,68 e **+17%, peste toleranță**. Diferența dintre cele două citiri ale decupării vine probabil din mască (umbra de pe sol, marginea gri) |
| trunchi în formă de pară | lat jos | șoldul 1,12 m, umerii ~1,0 m | **parțial**: lățimea e acolo, dar trunchiul tot citește cilindru, nu pară cu burtă bombată |
| brațe groase, depărtate, antebrațele atârnă în față | da | 15° depărtare, antebrațul 46° înainte, laba moale | OK |
| picioare scurte, groase, genunchi ușor îndoiți | da | 12° la genunchi, talpa plată | OK |
| capul coborât între umeri, întors | da | scufundat 5 cm, întors 12° spre dreapta imaginii | OK |
| fâșia închisă de sub burtă | burta e ușor mai închisă | **scoasă** (`BELLY_BELOW = 0`, decizia coordonatorului): ridicat citea ca o eșarfă în diagonală pe flanc | burta e roșcată ca restul corpului |
| ochii / nasul | închiși | `VOLCANIC_BLACK` (`#55535A`), la soare gri | rămâne de la prima serie |

„De la 30 m, din spate-sus, se citește URS BRUN?” În patru labe (planșa de cadre)
**da**: masă roșcată rotundă, cocoașă, cap mare cu urechi rotunde, picioare
scurte închise. Din spate (vederile ridicat 215°/305°) e o masă roșcată uniformă
cu picioarele închise. Nu se confundă cu vaca.

## Verificări

- `verify_glb.py`: `VERDICT: OK`, fără excepții. Origine `base`, sloturile 1, 20,
  27 și 28 sunt legale, AO 0,60–1,00.
- `check_glb_anims.py ... Idle Walk Stand`: `OK`, `skins=1`.
- `verify_transfagarasan.sh`: am adăugat secțiunea „valul 1, tf-c”, cu `check` pe
  urs plus `check_glb_anims`. → **`VERDICT KIT: OK`**.
- **Sonda Godot** (temporară, ștearsă după rulare), după `--import` în worktree:
  - un singur `AnimationPlayer`, cu clipurile `Idle` 2,000 s, `Stand` 1,167 s și
    `Walk` 1,167 s, fiecare cu 18 piste. Importul le lasă one-shot (`loop_mode` 0);
  - după bucla pusă ca în `_hook_animation`, `Walk` e `LOOP_LINEAR`;
  - scheletul chiar deformează: între începutul și capătul lui `Stand`, `Hips` se
    rotește cu 60,0°, iar `Chest` se mută cu 0,27 m. Prima variantă a sondei citea
    `get_bone_global_pose` imediat după `seek` și dădea delta 0. Poza globală nu
    se reîmprospătează în același tick, așa că sonda citește acum poza locală
    (memoria `sonda-masura-alt-obiect`);
  - rădăcina are scala 1, deci colizorul din `SlidingHazard` iese la mărimea reală.

  Sonda a rulat pe geometria din prima serie. Revizia n-a schimbat clipurile,
  scheletul sau rădăcina (recitite din GLB): AABB-ul nou e 1,07 × 1,38 × 2,58 m.

## Decizia coordonatorului

**Acceptat.** Trunchiul ridicat rămâne cilindru, cu h/l 1,96, adică +17% față de
ținta de 1,68. E o abatere scrisă: poza e ținută 1,2 s și se vede din spate-sus.
Verdictul final pe ea se dă pe captura din joc, la integrare. Fâșia închisă de
sub burtă a fost scoasă (`BELLY_BELOW = 0`); burta e acum `LARCH_RUST`.

## Stare la oprire

- Piesa e acceptată și comisă pe `transfagarasan/kit-c`: GLB, build, comparații,
  planșe și acest inventar.
- Tălpile stau pe sol: baza e 0,000 ±0,002 m pe toate cadrele cheie ale celor
  trei clipuri, după ultimul rebuild.
- De făcut la integrare (`scripts/` și `scenes/` nu sunt ale mele):
  1. de reverificat în joc, pe captură, poza `Stand` (trunchiul e cilindru,
     h/l 1,96);
  2. intrarea `&"brown_bear": 0.97` în `WALK_CYCLE_SPEED_BY_MODEL` și
     `sweep_speed` pe marker;
  3. montarea pe `Hazarduri/Urs` în `Track21.tscn`, în locul vacii, cu
     `model_scale` 1,0.
