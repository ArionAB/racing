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
puține secțiuni transversale, unite în fâșii cu diagonale alternante, cu jitter
determinist și umbrite plat.

## Cote măsurate (pe mesh-ul evaluat cu scheletul aplicat)

| cotă | contract (kit §1.6) | măsurat | |
|---|---|---|---|
| lungimea în patru labe (bot–crupă, `Idle` cadrul 0) | 2,6 m | **2,58 m** | −0,8% |
| greabănul (cocoașa, `Idle` cadrul 0) | 1,4 m | **1,39 m** | −0,7% |
| lățimea | — | 1,00 m | |
| înălțimea ridicat (`Stand`, cadrul final, ținut) | 3,0 m | **2,95 m** (2,97 la depășirea din cadrul 23) | −1,7% |
| baza, pe toate cadrele cheie ale celor 3 clipuri | 0 | 0,000 ±0,002 m | |
| originea | la bază, centrată | centru XY (0,000; 0,000), Y glTF de la 0,000 | OK |
| fața | +Y Blender = −Z Godot | osul `Head` la z = −0,70 în glTF, `Hips` la +0,88 | OK |

## Geometria, scheletul, clipurile

- **Triunghiuri:** 1.144. Un singur mesh, un material (atlasul).
- **Sloturi** (aria fețelor): `LOG_DARK` 28 = 85,3%, `LARCH_RUST` 27 = 14,3%
  (fețele cu normala în sus pe crupă și piept, peste 1,0 m: spatele și umerii),
  `VOLCANIC_BLACK` 20 = 0,4% (nasul, ochii, 4 gheare pe fiecare labă). AO e
  gradient vertical 0,60 → 1,00 (`COLOR_0`), nu raycast.
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
| `Idle` | **2,000 s** (48 de cadre la 24 fps) | se închide (primul cadru = ultimul, diferența 0,0000). Bucla o pune `SlidingHazard._hook_animation` | respiră (pieptul se umflă 1°, umerii rămân pe loc), adulmecă: capul coboară 9° și se întoarce ±7° |
| `Walk` | **1,167 s** (28 de cadre) | se închide (diferența 0,0000). Bucla o pune `_hook_animation` | **secvență laterală în patru timpi** (HL, FL, HR, FR), ca la ursul real. Fiecare labă stă 65% din ciclu pe sol, deci sunt mereu cel puțin două jos. Laba din sprijin merge înapoi **liniar** (IK în două segmente), așa că nu patinează. Corpul coboară până la 10 cm când laba e departe de verticală: ăsta e „pasul greu”. Umerii se leagănă, iar capul dă din cap la fiecare pas din față |
| `Stand` | **1,167 s** (28 de cadre, sub telegraful de 1,2 s) | **nu** (se joacă o dată și ține ultimul cadru) | ține capul jos și adulmecă (cadrul 5), se ridică din șold (60°) și din mijlocul spatelui (18°), cu spatele întins cu 0,27 m. Depășește puțin (cadrul 23), apoi se așază (cadrul 28). **Poza finală:** trunchiul la ~78° (aplecat ușor înainte, ca pe decupare), picioarele din spate verticale, cu tălpile întregi pe sol. **Labele din față atârnă**: brațul în jos, antebrațul spre înainte-jos, laba moale în jos. Capul e aproape orizontal, cu botul cu 8° în jos, scufundat 5 cm între umeri. Fără gesturi umane |

- **Fără root motion.** Toate cheile sunt pe oase, nodul nu se mișcă. Pe fiecare
  cheie, o „corecție de sol” pune punctul cel mai de jos pe y = 0. Corecția e
  ≤ 1,0 cm la `Walk` și 0 la `Idle`/`Stand`.
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

## Fidelitate (3 runde, maximul)

Comparațiile, cu decuparea în stânga și randarea din GLB în dreapta, la aceeași
înălțime:
- `docs/asset_briefs/img/transfagarasan_fidelity/brown_bear_walk.png`
  (`Walk`, cadrul 4);
- `docs/asset_briefs/img/transfagarasan_fidelity/brown_bear_stand.png`
  (`Stand`, cadrul final).

Planșa de cadre e `brown_bear_frames.png`: `Idle` 1, `Walk` 2, `Stand` la început,
la mijloc și la capăt. Etichetele numără cadrele de la 1. `brown_bear_stand_views.png`
arată poza `Stand` din 4 azimuturi.

Rundele:
1. Picioare subțiri, corp ca un tub (citea hienă), bot lung de câine, urechi ca
   niște coarne, cap cu căciulă ruginie, picioare din față ridicate ca de
   cerșetor în `Stand`.
2. Picioarele îngroșate la ~0,4 m, burta coborâtă la 0,48 m, cap mare cu bot
   scurt, urechi rotunde, crupa rotunjită la spate. Rugina a plecat de pe
   creștet. Brațele în `Stand` erau tot la piept.
3. Brațele atârnă (paw la ~1,4 m), capul iese mai sus dintre umeri, șoldul e mai
   lat decât pieptul, nasul e doar vârful botului, spatele mai întins
   (2,95 m ridicat).

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| silueta în patru labe, h/l | 0,67 | 0,59 | OK (−12%, în ±15%) |
| cocoașa de umeri, cel mai înalt punct | da | da, 1,39 m peste labele din față | OK |
| șaua după cocoașă, crupa mai joasă | da, ~0,87 | da, crupa 1,21 m = 0,87 | OK |
| capul mai jos decât cocoașa, lat, bot scurt | da | da, creștetul ~1,29 (fără urechi) | OK, dar botul e mai „cutie” decât pe decupare |
| urechi mici, rotunde | 2 | 2 discuri cu 6 laturi | OK |
| ochi / nas închiși | da | da (`VOLCANIC_BLACK`) | OK. Slotul e gri închis `#55535A`, deci la soare iese mai deschis decât negrul de pe decupare |
| 4 picioare groase, labe plate mari | da | da, ~0,40 m la umăr, labe 0,34 × 0,40 m | OK. Pe decupare umărul curge în picior, la noi se vede îmbinarea crupă/piept/picior |
| gheare închise | 4 pe labă | 4 pe labă | OK |
| culoarea | maro mediu-deschis uniform, fețele luminate portocalii | `LOG_DARK` închis + `LARCH_RUST` pe spate/umeri | **abatere asumată**: sloturile sunt cele din tabelul de roluri (kit §0). Ursul iese mai închis decât decuparea, iar spatele ruginiu se citește ca o „șa”. Nu seamănă cu vaca (`WOOD` maro mediu + pete crem): e mai închis, n-are pete, are cocoașă |
| silueta ridicată, h/l | 1,68 | **2,48** | **ABATERE, în afara ±15%.** Ursul ridicat e mult mai zvelt decât cel de pe decupare: trunchiul are 1,0 m lățime pe 2,95 m, iar decuparea e un urs-jucărie „îndesat”, cu umerii lați și brațele depărtate de corp |
| trunchi aproape vertical, ușor aplecat înainte | da | ~78° | OK |
| labele din față atârnă în fața pieptului, fără gest uman | da | da: brațul jos, antebrațul înainte, laba moale | OK |
| capul pe umeri, botul înainte | da | da, scufundat 5 cm, botul −8° | OK. Pe decupare capul e întors ușor spre dreapta, la noi e drept |
| tălpile întregi pe sol, picioarele drepte | da | da | OK |

**Ce ar repara a 4-a rundă, dacă o cere coordonatorul:**
- pieptul mai lat în `Stand`: piesele pieptului și crupei cu ~+0,12 m pe X;
- brațele depărtate lateral, cu o rotație de ~12° în jurul lui Y pe `LegFU` în poza
  ridicată;
- antebrațul mai lung, ca labele să coboare spre șold.

## Verificări

- `verify_glb.py`: `VERDICT: OK`, fără excepții. Origine `base`, sloturile 20, 27 și
  28 sunt legale, AO 0,60–1,00.
- `check_glb_anims.py ... Idle Walk Stand`: `OK`, `skins=1`.
- `verify_transfagarasan.sh`: am adăugat secțiunea „valul 1, tf-c”, cu `check` pe
  urs plus `check_glb_anims`. → **`VERDICT KIT: OK`**.
- Sonda Godot (temporară, `tools/_probe_bear_tmp.gd`, necomisă): vezi „Stare la
  oprire”.

## Stare la oprire

- GLB, build, preview, comparațiile și planșele sunt livrate și comise pe
  `transfagarasan/kit-c`.
- Deschis pentru coordonator:
  1. silueta ridicată e prea zveltă (h/l 2,48 față de 1,68). Am făcut 3 runde,
     iar reparația e scrisă mai sus;
  2. intrarea `&"brown_bear": 0.97` în `WALK_CYCLE_SPEED_BY_MODEL` și
     `sweep_speed` pe marker (`scripts/` și `scenes/` nu sunt ale mele);
  3. montarea pe `Hazarduri/Urs` în `Track21.tscn`, în locul vacii cu
     `model_scale` 0,9, cu `model_scale` 1,0 (ursul e construit la scară reală).
