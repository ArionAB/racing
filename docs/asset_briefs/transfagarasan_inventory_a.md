# Inventar — kitul Transfagarasan, grupa tf-a („drumul”, val 1)

Contract: `docs/asset_briefs/transfagarasan_kit.md` §1.1. Cotele sunt MASURATE pe
GLB cu `verify_glb.py` si `measure_tf_gap.py`. Axele sunt Blender (X latime,
Y adancime, Z sus); fata e +Y in Blender, adica −Z in Godot.

Build: `tools/blender/build_tf_road.py` (toata grupa, plus pilotul). Vocabularul
e in `transfagarasan_shapes.py`, iar capturile se fac cu `tools/blender/preview_tf_a.py`
(`--compare`, `--views`, `--chain`), care sta peste harnasul
`preview_transfagarasan.py`, fara sa-l modifice. Verdictul se da cu
`bash tools/blender/verify_transfagarasan.sh` si a iesit **VERDICT KIT: OK**.
Comparatiile sunt in `docs/asset_briefs/img/transfagarasan_fidelity/<nume>.png`,
iar cele 4 azimuturi in `<nume>_views.png`.

## Rezumat

| piesa | commit | cote masurate (X × Y × Z) | tri | noduri (slot) |
|---|---|---|---:|---|
| `structures/snow_wall.glb` | `9338aa8c` | A: 2,50 × 8,00 × 4,01; B: 2,50 × 8,00 × 3,02 | 3 298 | `SnowWall_A`/`_B` (Empty) → `*_Snow` (FOAM_WHITE 22), `*_Dust` (CONCRETE 8) |
| `structures/rock_tunnel_portal.glb` | `b298d1b4` | 26,60 × 15,98 × 13,00 | 3 717 | `Rock_Schist` (MARBLE_GREY 29), `Rock_Grass` (TROPICAL_GREEN 21), `Rock_Void` (VOLCANIC_BLACK 20) |
| `structures/retaining_wall_straight.glb` | `aa12375c` | 2,01 × 8,00 × 5,00 (z −5..0) | 484 | `Wall_Stone` (MARBLE_GREY 29) |
| `structures/retaining_wall_curve.glb` | `aa12375c` | 2,35 × 8,70 × 5,00 (coarda 8,00 la x = 0) | 484 | `Wall_Stone` (MARBLE_GREY 29) |
| `props/snow_pole.glb` | `98d725bc` | 0,92 × 0,62 × 2,50 | 220 | `Pole_Paint_Red` (KERB_RED 7), `Pole_Paint_White` (FOAM_WHITE 22), `Pole_Stone` (MARBLE_GREY 29) |
| `props/road_works.glb` | `98d725bc` | 5,64 × 1,79 × 2,41 | 944 | `Works_Cone_1..4` (LAVA_ORANGE 30 + FOAM_WHITE), `Works_Barrier`, `Works_Sign` |
| `props/level_crossing.glb` | `98d725bc` | 18,83 × 0,55 × 8,52 (bratele ridicate) | 896 | `Crossing_Post_L/_R`, `Crossing_Lamp_L/_R` (KERB_RED), `Crossing_Gate_L/_R`, `Crossing_Boom_L/_R` |
| `props/bear_warning_sign.glb` | `98d725bc` | 1,20 × 0,62 × 2,49 | 288 | `BearSign_Plate`, `BearSign_Post` (ASPHALT_EDGE 6), `BearSign_Stone` (MARBLE_GREY) |
| `structures/tunnel_portal_balea.glb` (zapada rev. 4) | `3f34f809` | 50,54 × 20,24 × 13,97 | 4 960 | ca in pilot; `Portal_Snow` 4 894, `Portal_Dust` 20 |

Recuzita (stalpi, capre, carcase) foloseste ASPHALT_EDGE 6 (#696765); tabelul
de sloturi nu are un rol pentru stalpi gri. Niciun slot nou.

## Goluri (CONTRACT, masurate ca GOL: proiectie pe plan, grila de 5 cm, tot GLB-ul)

| piesa | fereastra | masurat | contract |
|---|---|---|---|
| `rock_tunnel_portal` | lateral, banda caroseriei 0–2 m | **15,40 m** (x −7,68..+7,72) | ≥ 15,0 |
| `rock_tunnel_portal` | inaltime libera in \|x\| ≤ 6,5 | **7,60 m** | ≥ 7,0 |
| `rock_tunnel_portal` | lateral la 1 m / 2 m | 15,60 / 15,60 m | — |
| `tunnel_portal_balea` (dupa zapada rev. 4) | lateral 0–2 m | **14,90 m** (x −7,43..+7,47) | ≥ 13,0 (inghetat 14,85) |
| `tunnel_portal_balea` | inaltime libera in \|x\| ≤ 6,5 | **7,40 m** | ≥ 7,0 (inghetat 7,40) |

Proiectia ia **tot pintenul**, deci cifra e valabila la ambele capete si pe toata
lungimea. La Balea placa si captuseala sunt neatinse. Diferenta de +0,05 m fata
de 14,85 e cuantizarea grilei de 5 cm: gura are aceleasi coordonate. Verificat
direct pe GLB-ul Balea:
- zapada din banda placii (\|x\| < 13) sta la y ≤ −2,16 (in spatele fetei);
- bratele ajung in fata pana la y = +1,28, dar numai la \|x\| ≥ 13;
- in \|x\| < 7,75 nu e zapada sub 9,11 m.

## structures/snow_wall.glb

Comparatia e `snow_wall.png`, vederile in `snow_wall_views.png`, iar
inlantuirea in **`snow_wall_chain.png`**: 4 module `SnowWall_A` pe R = 30 m (la
axa), cu pasul de 14,59° ales asa incat muchiile exterioare (+X) sa se atinga si
cele interioare sa se suprapuna.

- **Capete identice.** Toata variatia e periodica pe 8 m: cotele straturilor,
  treptele, ondularea crestei, praful. Scobiturile au cuspida la ±4 m.
- **Rost.** Pe dreapta nu exista. Pe curba, fata spre drum e concava, iar acolo
  modulele se intrepatrund 0,32 m; liniile de strat fac un mic decalaj de
  ~0,08 m la imbinare. Nu e gol.
- **Regula de integrare** propusa: pasul de 8 m se masoara pe fata dinspre
  exteriorul curbei.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| silueta | perete lung, h/l ~0,5 | 4 / 8 = 0,50 (A) | OK |
| randurile de blocuri | 3 randuri × ~7 coloane de cuburi fatetate | **corectura**: 4 straturi (A) / 3 (B), cu trepte de 0,22–0,30 m pe fata spre drum (−X) | abatere ceruta de corectura |
| coloanele | ~7 | 7 scobituri de freza (1,14 m, adanci 0,11 m), cu muchii verticale | OK (ritmul se pastreaza fara rosturi de cuburi) |
| creasta | neregulata, un bloc retezat | rotunjita, ondulata ±0,1 m | OK |
| praful | — (alb curat) | **corectura**: pete pe triunghiuri in benzile de la baza straturilor, pe praguri si la baza (cea mai murdara) | OK; slotul CONCRETE iese bej pe alb, contrast mare |
| fata din spate | (nevazuta) | umar convex 2,5 → 1,2 m | OK |
| culoarea | alb-albastrui | FOAM_WHITE; clasa `snow` la integrare | OK |

Runde: 2.
1. Praful iesea in dreptunghiuri. Pe curba erau goluri, dar cauza era camera:
   importul glTF lasa radacinile in QUATERNION.
2. Praful e ales pe triunghi, pe doua randuri pe banda, cu zgomot decalat cu
   cota.

## structures/rock_tunnel_portal.glb

Comparatia e `rock_tunnel_portal.png`, randata frontal (azimut 78, ca
decuparea); vederile sunt in `rock_tunnel_portal_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| masa | dom ascutit, ~12–14 blocuri mari, h/l ~0,6 | dom cu umeri inalti, 26,6 × 13 m (h/l 0,49); capete din benzi de sist la 40° rupte in blocuri iesite inegal 0–1,8 m; ~25 de lame pe flancuri si pe crestet | **abatere**: silueta iese arcada groasa de stanca, nu domul ascutit. Golul cerut (15,4 × 7,6 din 26 × 13) da gurii 59% din latime si 79% din inaltime, fata de ~45% / ~55% pe planșă. Se repara din contract, nu din forma: pinten mai lat (~32–34 m) sau bolovani `canyon_rocks` lipiti de flancuri la integrare |
| inelul de zidarie | 13 bolțari + stalpi | **corectura**: fara | OK |
| foliatia | (blocuri fara directie) | toate lamele la 40°, urca spre +X | OK (regula 7) |
| gura | arc pe pereti verticali | bolta din 12 fatete, jitter spre exterior, asimetrica | OK |
| interiorul | intunecat | `Rock_Void` doar in primii 2 m la fiecare capat; restul e sist cu AO | OK (contract). Prin tunel se vede fundalul: piesa e deschisa la ambele capete |
| muschiul / iarba | pete galben-verzi pe toate blocurile | **corectura**: doar pe crestet (`Rock_Grass`, 109 fete), in petice intre lame joase; loc pentru 2–3 fagi | OK; TROPICAL_GREEN e mai saturat decat muschiul de pe planșă |
| bolovanii de la picior | 6–8 | nu sunt in GLB (ii pune integrarea, ca sa nu intre in banda) | decizie, vezi mai jos |

Runde: 3.
1. Domul era paralel cu bolta, deci iesea un pod subtire, iar crestetul era un
   gazon plat.
2. Profil ascutit, blocuri de capat mai groase si mai iesite, lame joase pe
   crestet.
3. Doar camera, frontala ca decuparea; forma e cea din runda 2.

Determinism: booleanul EXACT da aceeasi topologie la fiecare rulare (3 119
tri pe `Rock_Schist`, 109 fete de iarba, acelasi gol), dar octetii difera
uneori intre rulari (ordinea elementelor). Un rebuild poate deci sa arate
GLB-ul „modificat” fara schimbare de forma.

## structures/retaining_wall_straight.glb / retaining_wall_curve.glb

Comparatiile sunt `retaining_wall_straight.png` si `retaining_wall_curve.png`,
plus `*_views.png`.

- **Originea** e pe marginea drumului (x = 0), la cota crestei (z = 0). Zidul
  atarna pana la −5 m (`--origin=rim`).
- **Fata spre vale** e +X, de la 1,2 m sus la 2,0 m jos (talus ~9°).
- **Curba:** R = 23 m la x = 0, unghiul pe capat e ±10,0°, coarda la x = 0 are
  8,00 m. Capetele sunt plane (radiale), cu aceeasi sectiune ca la modulul drept.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| proportia | h/l ~0,4 (dreapta), ~0,45 (curba) | 5 / 8 = 0,63 | abatere ceruta de tabel (cota 5 m) |
| randul de sus | ~11 pietre de coronament | **contract**: 8 pietre/modul (7 intregi + 2 jumatati care fac o piatra peste rost), iesite 0,10–0,20 m, rosturi de 5 cm, creasta plana la 0 | OK fata de contract; mai putine decat pe planșă |
| corpul | ~40 de pietre rotunjite in 4–5 asize | **contract**: masa cu fete mari (4 randuri de fatete, jitter ±0,2 m); piatra o da clasa `stone_wall` | abatere ceruta de contract. Fara clasa, in preview iese bloc gri |
| curba | fata **concava** spre privitor | fata **convexa** spre vale (+X), cum cere tabelul | abatere ceruta de tabel |
| capetele | — | plane, identice; piatra de peste rost e taiata plan la ambele capete | OK |
| verde in rosturi | putin | nu (fara vegetatie lipita) | corectura |

Runde: 2. In runda 1 corpul era aproape plat (jitter de 0,09 m invizibil).

## props/snow_pole.glb

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| stalpul | gros, dungi rosu-alb | Ø 0,08 m (8 segmente, contract), 5 dungi R-A-R-A-R de 0,43 m | OK; mai subtire decat pe planșă (cota contractului) |
| bolovanul | morman de 3–4 pietre cu muschi | bolovan de 0,39 m + 3 mici, fara muschi | OK (corectura vegetatiei) |

Runde: 1.

## props/road_works.glb

Fiecare element e nod cu pivot la baza lui:
- `Works_Cone_1..4` la (2,55; 0,65), (1,0; 0,75), (−0,55; 0,6), (−1,75; 0,8);
- `Works_Barrier` la (1,0; −0,45);
- `Works_Sign` la (−2,3; −0,5).

Vazut din fata (+Y), +X e in stanga; asezarea reproduce decuparea: semnul in
dreapta, bariera in stanga.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| conurile | 3, cu 2 benzi albe si talpa patrata | **4** (tabel), 0,75 m, 10 segmente | OK |
| bariera | scandura cu dungi diagonale, capete albe, 2 capre in A | 3 m × 1,1 m, 10 dungi la ~45°, capete albe, capre ASPHALT_EDGE | OK |
| semnul | triunghi, omul cu lopata, 2 stalpi | latura 1,2 m (aleasa: tabelul nu o da), varful la 2,4 m, relief de 1,5 cm, spate gri | OK |
| semaforul | — | nu (`HazardLamp`, cod) | OK |

Runde: 2.
1. Culorile semnului erau inversate (vezi deciziile), stalpii ieseau peste
   triunghi, iar pictograma era oglindita.
2. Toate trei reparate.

## props/level_crossing.glb

- **Asezare:** stalpii la x = ±9,0 m, carcasele la ±7,85 m, balamalele la
  (±7,6; 0,24; 0,92).
- **Brate:** au 7,5 m, sunt ridicate vertical si au originea nodului pe
  balama.
- **Coborare:** `Crossing_Boom_L` se roteste +90° in jurul +Y Blender
  (= −90° in jurul +Z Godot) si cade spre +X, adica spre axa drumului.
  `_R` se roteste invers.
- **Lentilele** stau in nodurile separate `Crossing_Lamp_L/_R` (KERB_RED,
  10 segmente).

In comparatie, ansamblul `_R` e mutat langa `_L`, numai acolo
(`preview_tf_a.py`, `compare_shift`).

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| crucea Sf. Andrei | alb cu chenar rosu, pe stalp | 2,85 m sus, brate de 1,0 m | OK |
| lampile | 2 rotunde, rosii, aprinse, in carcasa neagra | 2 lentile Ø 0,24 m pe placa neagra, cu viziere | OK; aprinderea o face integrarea |
| bratul | dungat, ~9–10 dungi, usor aplecat, gros | 10 dungi de 0,75 m, 0,16 × 0,10 m, **vertical** (contract) | abatere: pe planșă e aplecat si ~2× stalpul; aici are 7,5 m (~2,7× stalpul) |
| carcasa | gri, cu contragreutate | cutie gri pe soclu, contragreutate sub balama | OK |

Runde: 2. In runda 1 lampile si bratul erau prea subtiri.

## props/bear_warning_sign.glb

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| triunghiul | chenar rosu lat, camp alb | latura 1,2 m, chenar de 0,1 m, camp iesit 5 mm, spate gri | OK |
| pictograma | ursul (atentie urși) | **corectura**: „nu hraniti ursii”: ursul (spre stanga privitorului) + mana cu marul + bara rosie diagonala; relief de 1,5 / 2 cm | OK. La 1,2 m mana cu marul se citeste ca „mana cu bila”; de la 30 m se citesc doar ursul si bara |
| stalpul | gri | 2,4 m, ASPHALT_EDGE | OK |
| bolovanul | morman cu muschi | 1 mare + 4 mici, fara muschi | OK (corectura) |

Runde: 2. In runda 1 straturile coplanare isi furau slotul (campul iesea negru).

## structures/tunnel_portal_balea.glb — zapada rev. 4

Placa, gura si captuseala sunt neatinse (contractul inghetat). Comparatia e
`tunnel_portal_balea.png`, randata cu harnasul `preview_transfagarasan.py`.

**Vocabularul.** Bulgarii (`bulgar`) sunt aproape izotropi: raport 1 : 0,92 :
0,86, raza jitterata ±6%, hull din 14–18 puncte. Pozitiile vin dintr-un camp de
inaltime:
- **bratele:** de la \|x\| 13 la 24, 10,8 m langa placa → ~4,6 m la capete;
  fata movilei e la y = −1 langa placa si vine in fata pana la y ≈ +1,3 la
  capete;
- **calota:** de la y = −2,5 pana la −17,5, urca la ~13–14 m.

**Densitatea.** Campul e umplut pe o grila jitterata: pas 2,8 m, raza ~2,0 m,
strat 2,6 m. Asta da o suprapunere de 30% pe orizontala si 35% pe verticala, deci
masa e continua. Din 246 de bulgari se pastreaza doar coaja: 178.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| masa | bulgari fatetati de ~2,5–3 m, lipiti, fara goluri | bulgari de ~4 m diametru, masa continua | OK; mai „gramada” decat zidul de blocuri de pe planșă |
| potcoava | brate care invaluie placa si vin in fata | brate trase inainte la capete, calota legata de ele | OK |
| inaltimea langa placa | ~cat placa | 10,8 m in camp; vizual ~80% din placa din unghiul de comparatie | abatere mica |
| calota | urca in spatele placii | de la y = −2,5 (partea din fata a crestei placii ramane libera), pana la ~14 m | OK |
| praful | — | 10 fete pe parte pe bulgarii de jos din fata, mutate pe `Portal_Dust` | OK; se vad ca pete bej pe fatete |

Runde (din 3):
1. r = 1,35: iesea pietris. Regula de excludere ridica bulgarii calotei la
   ≥ 0,9 m peste creasta placii, de unde o fanta neagra.
2. r = 2,0 si regula restransa la „nimic in fata fetei”: fanta a disparut.
3. Hull din 10–13 puncte, pentru fatete mai mari: au iesit cioburi
   neregulate, iar runda a fost **respinsa**.

**Starea finala** e hull-ul din runda 2 cu inaltimea bratelor din runda 3
(10,8 m in loc de 10,4). Inaltimea e o schimbare independenta de forma
bulgarelui; s-a randat o data pentru confirmare.

Triunghiurile cresc de la 898 (rev. 2) la **4 960**. Nu exista plafon
(CLAUDE.md), iar numarul de materiale ramane acelasi (4 noduri).

## Decizii luate singur, cu motiv

1. **`snow_wall`, variantele.** Sunt radacini goale (`SnowWall_A`, `SnowWall_B`),
   cu copiii `*_Snow` / `*_Dust`. Contractul cere atat variante ca radacini,
   cat si noduri de un singur material, iar o radacina goala le impaca pe
   amandoua: Godot alege copilul direct dupa nume, si clasa merge pe sufixul
   copilului.
2. **`rock_tunnel_portal` are al treilea nod, `Rock_Void`.** Contractul numeste
   doar `Rock_Schist` si `Rock_Grass`, dar clasa `tf_schist` pusa pe tot
   obiectul ar sterge negrul primilor 2 m (memoria `clase-pe-piese-de-kit`).
3. **Bolovanii de la piciorul portalului de stanca nu sunt in GLB.** Pe
   decupare stau langa asfalt; ii pune integrarea din `canyon_rocks`, unde
   banda o permite.
4. **Originea zidurilor de sprijin e pe marginea drumului** (x = 0), nu pe
   centrul crestei. Asa raza de 23 m din tabel se aplica direct pe x = 0, iar
   modulul se aseaza pe marginea asfaltului.
5. **Latura semnului de santier e 1,2 m** (tabelul nu o da), ca semnul cu
   ursul. La 0,9 m pictograma nu se citea.
6. **Straturile semnelor au rosturi de 2 mm.** `assign_uvs` ia slotul fetei
   pre-bevel celei mai apropiate de centrul poligonului. Doua fete coplanare
   isi fura culoarea: campul alb iesea negru (fata din spate a pictogramei),
   chenarul iesea alb. E o capcana generala pentru orice relief lipit.
7. **`build_tf_road.py` curata scena inainte de fiecare piesa.** La build-ul
   complet, zidul curb iesea cu nodul `Wall_Stone.001`, iar Godot cauta
   nodurile dupa nume.
8. **Pivotii recuzitei sunt nodurile ei.** Fiecare element e construit cu baza
   lui la origine si asezat prin `location`, ca integrarea sa-l mute separat.
   Bratele barierei au pivotul pe balama.

## Stare la oprire (13 oct 2026)

Toate piesele grupei tf-a (§1.1) sunt construite, comparate si comise, iar
zapada portalului Balea e refacuta (rev. 4). `VERDICT KIT: OK`. Acceptarea
ramane a coordonatorului, pe comparatii.

Deschise pentru coordonator:
- **Silueta `rock_tunnel_portal`**: vezi tabelul piesei. Abaterea vine din
  contract, iar propunerea de reparatie e acolo.
- **Unificarea lamelor de sist**: `schist_blade` din `transfagarasan_shapes.py`
  e varianta minima tf-a si trebuie unificata cu
  `tf_shapes_nature.schist_blade` (tf-b) la integrare.
- **Camerele tf-a** sunt in `preview_tf_a.py` (`SPECS.update`). Se pot muta in
  `SPECS` din harnas la integrare; `--chain` si `compare_shift` raman in
  wrapper.
