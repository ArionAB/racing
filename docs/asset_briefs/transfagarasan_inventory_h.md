# Transfagarasan - inventar val 3, tf-h (`ro_train`, `cable_cabin_large`)

Ramura `transfagarasan/kit-h`. Build: `tools/blender/build_tf_vehicles.py` (`TF_ONLY=ro_train|cable_cabin_large`).
Previews: `tools/blender/preview_tf_h.py` (`--compare`, `--views`, `--consist`, `--align`, `--scale`).
Verdict: `bash tools/blender/verify_transfagarasan.sh` -> `VERDICT KIT: OK`.

## Cote masurate (verify_glb, din GLB)

| nod | X (lungime) | inaltime | latime | tri | sloturi |
|---|---:|---:|---:|---:|---|
| `Train_Loco` | 17,00 | 4,41 (pantograf ridicat) | 3,12 | 8.816 | CAR_RED 14, ASPHALT_EDGE 6, VOLCANIC_BLACK 20, FOAM_WHITE 22 |
| `Train_Tender` (bagaje) | 5,00 | 3,64 | 3,12 | 2.932 | CAR_RED, ASPHALT_EDGE, VOLCANIC_BLACK |
| `Train_Wagon` | 20,00 | 3,64 | 3,12 | 5.776 | idem |
| `Cabin_Body` | 5,67 | 3,00 | 3,38 | 2.900 | CAR_RED 14 |
| `Cabin_Glass` | 5,56 | 1,06 | 3,27 | 60 | VOLCANIC_BLACK 20 |
| `Cabin_Cart` | 2,14 | 4,50 | 1,34 | 1.760 | ASPHALT_EDGE 6, VOLCANIC_BLACK 20 |

`ro_train.glb` 17.524 tri; `cable_cabin_large.glb` 4.720 tri, total 5,74 x 3,45 x 7,50 m, varful rotilor la y = 0 (`--origin=rim`).
Latimea 3,12 (nu 3,0) vine din ferestrele/clanturile iesite 6-9 cm pe flanc.

## Aliniere cu PeruRail (TrainHazard)

| | ro_train | perurail_train.glb | train.glb (implicit) |
|---|---|---|---|
| bot | +X | +X | +X |
| baza rotilor | y = 0,000 (loco 0,005: poligon 12 laturi) | 0,000 | 0,000 |
| ecartament (centru roata) | \|z\| = 0,45 | 0,45 (bandaj 0,53) | 0,45 |
| loco L x H x W | 17,0 x 4,41 x 3,12 | 8,9 x 3,59 x 2,86 | 8,09 x 3,58 x 2,87 |
| tender L x H | 5,0 x 3,64 | 5,0 x 3,62 | 5,21 x 2,35 |
| vagon L x H | 20,0 x 3,64 | 8,0 x 3,62 | 8,06 x 2,95 |

Atentie la integrare: lungimile din tabelul kit (17 / 20 m) sunt ~2x scara de joc a garniturilor existente (8-9 m).
Garnitura cu 3 vagoane = 3x20 + 5 + 17 + 4x1,2 = ~87 m (PeruRail ~43 m): trecerea blocheaza drumul ~2,2 s fata de ~1,3 s si viteza
implicita creste (span/CROSS). Daca e prea mult: `WAGON_COUNT` in `train_hazard.gd`, sau regenerez cu `hl` mai mic (constante in `build_train_*`).
`TrainHazard` nu are export de scara; `model_path = "res://assets/models/transfagarasan/vehicles/ro_train.glb"` e singurul setaj necesar.
Imagine: `docs/asset_briefs/img/transfagarasan_fidelity/ro_train_vs_perurail.png`.

## Fidelitate element cu element

| element | planșa | GLB | |
|---|---|---|---|
| loco: corp rosu, talpa gri, acoperis gri bombat | da | da | OK (gri neutru, ASPHALT_EDGE) |
| dunga galbena | da | NU (CAR_YELLOW interzis) | abatere declarata |
| loco: 2 usi + 4 ferestre + 2 grile pe parte | ~2+3+2 | 2+4+2 | OK |
| cabine la ambele capete (parbrize, 3 faruri) | 1 capat vizibil | 2 capete | OK |
| 2 pantografe, unul ridicat | 2 (brate rosii) | 2, brate rosii, 4,4 m | OK, mai mic decat pe planșa |
| 2 boghiuri, 8 roti | da | da | OK |
| vagon: ferestre + usa + capat negru | 3 + 1 | 6 + 2 usi pe parte, capat negru | pastrat tiparul, repetat (20 m) |
| ovalul cu text | da | omis | regula fara text |
| proportii: loco mai lunga ca vagonul | ~1,7x | 0,85x | ABATERE: cotele tabelului bat planșa |
| inaltime caroserie fata de lungime | corp inalt, scurt | lung si jos (h/l ~0,22 vs ~0,25) | in toleranta |
| cabina: colturi tesite, podea plata, bandă de geam, 10 montanti | da | da | OK |
| cabina: 2 geamuri mari pe fata lunga | da | 2 + colturi | OK dar geamurile se citesc ca banda neagra continua |
| cabina: proportie | aproape cub (~1,2:1) | 5,5 : 3,0 = 1,8:1 | ABATERE: cota din tabel |
| brat de zabrele in A + bara de carucior | da | picioare in A, coloana, gusee, bara | OK ca structura, mai putin detaliat |
| carucior: 4 roti | da | 4 | OK |

Scara cabinei: `cable_cabin_scale.png` (cabina ~2,3x gondola alpina Track09: 2,36 x 2,16 x 4,01 m, cabina ei ~2,6 m).

## Runde
1. Prima: `PAINTED_METAL` 11 pe talpa/acoperis/caruciorul iesea ALBASTRU fata de gri neutru din decupari; caruciorul era o placa plina.
2. A doua: talpa, acoperisul si caruciorul pe `ASPHALT_EDGE` 6 (abatere de la tabel, aceeasi decizie ca la acoperisurile din val 2);
   caruciorul cu obraji joasi + montanti (lattice); montanti de cabina mai groși. 1 runda ramasa/piesa, nefolosita.

## Stare la oprire
- Livrate: ambele GLB, verify OK (`VERDICT KIT: OK`), val 2 neatins (GLB-urile parked_car_a/b, motorbike identice la bit, `git status` curat pe ele).
- Abateri: proportiile trenului (loco mai scurta decat vagonul) si ale cabinei (prea lunga fata de planșa) urmeaza tabelul; fara dunga galbena; talpa/carucior pe ASPHALT_EDGE.
- Runda urmatoare: lungimi mai scurte pe tren daca coordonatorul vrea scara de joc (8-10 m); cabina 4,0 x 3,2 x 3,0 pentru silueta de cub; geam cu panouri separate (montanti mai inalti); detaliu de zabrele pe brat.
- Cabina: nodurile `Cabin_Body/_Glass/_Cart`, cablul trece pe X; se aseaza cu originea pe linia cablului.
