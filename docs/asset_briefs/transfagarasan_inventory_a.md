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
| `structures/snow_wall.glb` | `9338aa8c`, praf `5c2426f5` | A: 2,50 × 8,00 × 4,01; B: 2,50 × 8,00 × 3,02 | 3 298 | `SnowWall_A`/`_B` (Empty) → `*_Snow` (FOAM_WHITE 22), `*_Dust` (CONCRETE 8) |
| `structures/rock_tunnel_portal.glb` (contract revizuit) | `a8b2c0a6` | 34,00 × 16,00 × 20,00 | 5 464 | `Rock_Schist` (MARBLE_GREY 29), `Rock_Grass` (TROPICAL_GREEN 21), `Rock_Void` (VOLCANIC_BLACK 20) |
| `structures/retaining_wall_straight.glb` (contract revizuit) | `16b40b53` | 2,00 × 8,00 × 5,00 (z −5..0) | 1 034 | `Wall_Stone` (MARBLE_GREY 29) |
| `structures/retaining_wall_curve.glb` (contract revizuit) | `16b40b53` | 2,35 × 8,69 × 5,00 (coarda 8,00 la x = 0) | 1 034 | `Wall_Stone` (MARBLE_GREY 29) |
| `props/snow_pole.glb` | `98d725bc` | 0,92 × 0,62 × 2,50 | 220 | `Pole_Paint_Red` (KERB_RED 7), `Pole_Paint_White` (FOAM_WHITE 22), `Pole_Stone` (MARBLE_GREY 29) |
| `props/road_works.glb` | `98d725bc` | 5,64 × 1,79 × 2,41 | 944 | `Works_Cone_1..4` (LAVA_ORANGE 30 + FOAM_WHITE), `Works_Barrier`, `Works_Sign` |
| `props/level_crossing.glb` | `98d725bc` | 18,83 × 0,55 × 8,52 (bratele ridicate) | 896 | `Crossing_Post_L/_R`, `Crossing_Lamp_L/_R` (KERB_RED), `Crossing_Gate_L/_R`, `Crossing_Boom_L/_R` |
| `props/bear_warning_sign.glb` | `98d725bc` | 1,20 × 0,62 × 2,49 | 288 | `BearSign_Plate`, `BearSign_Post` (ASPHALT_EDGE 6), `BearSign_Stone` (MARBLE_GREY) |
| `structures/tunnel_portal_balea.glb` | **rev. 2** (rev. 4 `3f34f809`, revenita in `99ffddcb`) | 48,4 × 17,6 × 13,2 | 898 | ca in pilot (`transfagarasan_inventory.md`) |

Recuzita (stalpi, capre, carcase) foloseste ASPHALT_EDGE 6 (#696765); tabelul
de sloturi nu are un rol pentru stalpi gri. Niciun slot nou.

## Goluri (CONTRACT, masurate ca GOL: proiectie pe plan, grila de 5 cm, tot GLB-ul)

| piesa | fereastra | masurat | contract |
|---|---|---|---|
| `rock_tunnel_portal` (contract revizuit) | lateral, banda caroseriei 0–2 m | **15,40 m** (x −7,70..+7,70) | ≥ 15,0 |
| `rock_tunnel_portal` | inaltime libera in \|x\| ≤ 6,5 | **7,60 m** | ≥ 7,0 |
| `rock_tunnel_portal` | lateral la 1 m / 2 m | 15,55 / 15,60 m | — |
| `tunnel_portal_balea` (rev. 2, dupa revert) | lateral 0–2 m | **14,85 m** | ≥ 13,0 (inghetat 14,85) |
| `tunnel_portal_balea` | inaltime libera in \|x\| ≤ 6,5 | **7,40 m** | ≥ 7,0 (inghetat 7,40) |

Proiectia ia **tot pintenul**, deci cifra e valabila la ambele capete si pe
toata lungimea. Portalul Balea e inapoi pe rev. 2: build-ul complet il
reproduce octet cu octet, iar golul remasurat dupa revert e exact cel inghetat.

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
| praful | — (alb curat) | **corectura** (dupa verdictul coordonatorului): DOAR pe banda de la baza primului strat si pe MUCHIILE treptelor (buza + prag); petice lungi, alese pe quad, nu pe triunghi; aria e A 1,85 m² / B 1,52 m² (43% / 38% din cea veche, 4,34 / 4,03 m²) | OK |
| fata din spate | (nevazuta) | umar convex 2,5 → 1,2 m | OK |
| culoarea | alb-albastrui | FOAM_WHITE; clasa `snow` la integrare | OK |

Runde: 2, plus corectura de praf.
1. Praful iesea in dreptunghiuri. Pe curba erau goluri, dar cauza era camera:
   importul glTF lasa radacinile in QUATERNION.
2. Praful e ales pe triunghi, pe doua randuri pe banda, cu zgomot decalat cu
   cota.

Coordonatorul a acceptat forma (trepte, freze, lantul, capete) si a cerut o
corectura de praf: iesea in patrate bej, pixelate si prea dese. Acum sta doar
pe primul strat si pe muchiile treptelor, ales pe quad pe coloane intregi, cu
zgomot de frecventa joasa. Acoperirea pe eticheta e exacta (cuantila), iar
randul de sus al benzii de baza primeste mai putin, deci margine in trepte.

## structures/rock_tunnel_portal.glb (contract revizuit)

Contractul revizuit de coordonator, aplicat in kit §1.1 in acelasi commit:
- pinten de **34 m** la baza si **20 m** inalt, cu silueta in dom / triunghi
  (h/l ~0,6), lung de 16 m pe Y;
- golul ≥ 15 × 7;
- 3–5 contraforturi in relief langa gura;
- iarba doar pe trepte si pe crestet;
- in preview, plan negru la y = −14.

Comparatia e `rock_tunnel_portal.png`, randata frontal (azimut 78), cu planul
negru doar in comparatie: in cele 4 vederi el plutea ca un panou. Vederile sunt
in `rock_tunnel_portal_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| silueta | dom / triunghi, varf deasupra gurii, flancuri pana la sol, h/l ~0,6 | triunghi cu flancuri drepte, 34 × 20 m (h/l 0,59), varful la 19,7 m putin la dreapta gurii; fata se lasa inapoi cu inaltimea (baza ±8 m, varful ±4 m) | OK |
| gura | ~45% din latime | 15,4 / 34 = 45%; 7,6 / 20 = 38% din inaltime | OK |
| blocurile fetei | mase mari, distincte, colturoase | benzi de sist groase (2,6–4 m) la 40°, rupte in blocuri de 3–5 m, iesite inegal (y 6,0..7,3) | **abatere ramasa**: blocurile citesc tot ca placi inclinate (foliatia la 40°), nu ca poliedrele groase de pe planșă |
| contraforturile | blocuri mari in relief langa gura | 4: langa gura stanga (pana la 11,2 m) si dreapta (9,6 m), jos la stanga, deasupra gurii; ies ~1 m peste blocurile fetei (pana la y = 8) | OK |
| inelul de zidarie | 13 bolțari + stalpi | **corectura**: fara | OK |
| foliatia | (blocuri fara directie) | toate lamele la 40°, urca spre +X | OK (regula 7) |
| interiorul | intunecat | `Rock_Void` in primii 2 m ai stancii (y 4,6..6,6, cu aceeasi lasare); in runda veche ieseau dungi negre in fata blocurilor, acum nu mai ies | OK |
| iarba | pete pe fetele de sus | `Rock_Grass`: fetele cu normala z > 0,86 de la 3 m in sus (trepte + crestet), 69 de fete | OK; TROPICAL_GREEN e mai saturat decat muschiul de pe planșă |
| bolovanii de la picior | 6–8 | nu sunt in GLB (ii pune integrarea) | decizie, vezi mai jos |

Runde (din 3):
1. Arcada rotunda; blocurile, subtiri, citeau sindrila.
2. Contur triunghiular, blocuri groase tinute in urma contraforturilor, iarba
   mai rara.
3. Fata lasata inapoi: vederile citesc nas de munte, nu paine extrudata.

Determinism: booleanul EXACT da aceeasi topologie si acelasi gol la fiecare
rulare, dar octetii pot diferi intre rulari (ordinea elementelor).

## structures/retaining_wall_straight.glb / retaining_wall_curve.glb (contract revizuit)

Contractul revizuit de coordonator, aplicat in kit §1.1 in acelasi commit:
- corpul din 12–18 pietre MARI cu inset de 4–6 cm si muchie tesita;
- coronament din pietre LIPITE, in acelasi plan, iesite 5 cm.

Comparatiile sunt `retaining_wall_straight.png` si `retaining_wall_curve.png`,
plus `*_views.png`.

- **Originea** e pe marginea drumului (x = 0), la cota crestei (z = 0). Zidul
  atarna pana la −5 m (`--origin=rim`).
- **Fata spre vale** e +X, de la 1,15 m sub coronament la 2,0 m jos (talus ~10°).
- **Curba:** R = 23 m la x = 0, unghiul pe capat e ±10,0°, coarda la x = 0 are
  8,00 m. Capetele sunt plane (radiale), cu aceeasi sectiune ca la modulul drept.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| proportia | h/l ~0,4 (dreapta), ~0,45 (curba) | 5 / 8 = 0,63 | abatere ceruta de tabel (cota 5 m) |
| corpul | ~40 de pietre rotunjite, colturoase, in 4–5 asize, cu rosturi inchise | 17 pietre MARI (1,3–2,2 × ~1,1 m) in 4 randuri neregulate (4-5-4-4), cu rosturi decalate; contur de 8 laturi (colturi tesite aleator 0,12–0,32 m), fata retrasa 5 cm pe contur si bombata 6 cm; rosturi de 5 cm latime si 6 cm adancime, cu goluri triunghiulare in colturi | OK fata de contract (12–18); pietrele sunt mai alungite si mai regulate decat pe planșă, iar tesiturile colturilor sunt destul de egale |
| coronamentul | rand continuu de pietre plate, lipite | 8 pietre LIPITE, fata de sus plana la z = 0, iesite 5 cm, intre ele doar tesitura de 3 cm | OK |
| curba | fata **concava** spre privitor | fata **convexa** spre vale (+X), cum cere tabelul | abatere ceruta de tabel |
| capetele | — | plane, identice; rosturile periodice, piatra de peste rost e taiata plan la ambele capete | OK |
| verde in rosturi | putin | nu (fara vegetatie lipita) | corectura |

Runde (din 3):
1. Blocuri dreptunghiulare: citeau zidarie din piatra taiata.
2. Contur de piatra de camp (8 laturi) si fata bombata.

## props/snow_pole.glb (acceptat)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| stalpul | gros, dungi rosu-alb | Ø 0,08 m (8 segmente, contract), 5 dungi R-A-R-A-R de 0,43 m | OK; mai subtire decat pe planșă (cota contractului) |
| bolovanul | morman de 3–4 pietre cu muschi | bolovan de 0,39 m + 3 mici, fara muschi | OK (corectura vegetatiei) |

Runde: 1.

## props/road_works.glb (acceptat)

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

## props/level_crossing.glb (acceptat)

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
| bratul | dungat, ~9–10 dungi, usor aplecat, gros | 10 dungi de 0,75 m, 0,16 × 0,10 m, **vertical** (contract) | OK (coordonatorul: drept si vertical, cum s-a cerut) |
| carcasa | gri, cu contragreutate | cutie gri pe soclu, contragreutate sub balama | OK |

Runde: 2. In runda 1 lampile si bratul erau prea subtiri.

## props/bear_warning_sign.glb (acceptat)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| triunghiul | chenar rosu lat, camp alb | latura 1,2 m, chenar de 0,1 m, camp iesit 5 mm, spate gri | OK |
| pictograma | ursul (atentie urși) | **corectura**: „nu hraniti ursii”: ursul (spre stanga privitorului) + mana cu marul + bara rosie diagonala; relief de 1,5 / 2 cm | OK |
| stalpul | gri | 2,4 m, ASPHALT_EDGE | OK |
| bolovanul | morman cu muschi | 1 mare + 4 mici, fara muschi | OK (corectura) |

Runde: 2. In runda 1 straturile coplanare isi furau slotul (campul iesea negru).

## structures/tunnel_portal_balea.glb: zapada ramane rev. 2

**Zapada portalului ramane rev. 2; verdictul final se da pe captura din joc la
integrare, nu in Blender.** (Decizia coordonatorului, care opreste bucla.)

Rev. 4 (`3f34f809`: bulgari izotropi intr-o masa continua, in potcoava) citea
„gramada de grindina / floricele”: icosaedri rotunzi si mici, fara masa.
Vocabularul planșei sunt BLOCURI cu fete fatetate, iar rev. 2 era mai aproape
de ea.

Revenirea s-a facut in `99ffddcb` (`git revert 3f34f809`). Acelasi commit
continea si trei lucruri care nu tin de zapada, repuse in `b282dfdf`:
- curatarea scenei intre piese;
- declararea tf-a in verify;
- docstring-ul din shapes.

Golul remasurat: **14,85 × 7,40 m**. Build-ul complet reproduce rev. 2 octet cu
octet: 898 tri, cotele si nodurile din `transfagarasan_inventory.md`.

## Decizii luate singur, cu motiv

1. **`snow_wall`, variantele.** Sunt radacini goale (`SnowWall_A`, `SnowWall_B`),
   cu copiii `*_Snow` / `*_Dust`. Contractul cere atat variante ca radacini,
   cat si noduri de un singur material, iar o radacina goala le impaca pe
   amandoua: Godot alege copilul direct dupa nume, si clasa merge pe sufixul
   copilului.
2. **`rock_tunnel_portal` are al treilea nod, `Rock_Void`.** Contractul il
   numeste acum; initial nu-l numea, dar clasa `tf_schist` pusa pe tot obiectul
   ar sterge negrul primilor 2 m (memoria `clase-pe-piese-de-kit`).
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
9. **Portalul de stanca se lasa inapoi** (y' = y (1 − 0,025 z)). Contractul nu o
   cere, dar fara ea pintenul de 16 m extrudat citea paine din 3/4. Baza ramane
   la ±8 m, deci lungimea pe Y e tot 16 m.
10. **Planul negru al portalului de stanca e doar in comparatie.** In cele 4
    vederi plutea ca un panou fara sens.

## Stare la oprire (13 oct 2026, dupa verdictele coordonatorului)

Acceptate de coordonator: `snow_pole`, `road_works`, `bear_warning_sign`,
`level_crossing`, iar `snow_wall` cu corectura de praf (facuta, `5c2426f5`).

Refacute pe contractul revizuit, cu kit §1.1 actualizat in acelasi commit
(acceptarea ramane a coordonatorului, pe comparatii):
- `retaining_wall_straight` / `_curve` (`16b40b53`, 2 runde);
- `rock_tunnel_portal` (`a8b2c0a6`, 3 runde).

Zapada portalului Balea: rev. 2, prin revert. Verdictul final se da pe captura
din joc. `VERDICT KIT: OK`.

Deschise:
- **Fata portalului de stanca** (vezi tabelul): blocurile citesc placi
  inclinate, nu poliedre groase. Cele 3 runde s-au terminat.
- **Unificarea lamelor de sist**: `schist_blade` din `transfagarasan_shapes.py`
  e varianta minima tf-a si trebuie unificata cu
  `tf_shapes_nature.schist_blade` (tf-b) la integrare.
- **Camerele tf-a** sunt in `preview_tf_a.py` (`SPECS.update`, `backdrop`,
  `compare_shift`, `--chain`). Se pot muta in harnas la integrare.
