# Transfagarasan - inventar val 3, tf-h (`ro_train`, `cable_cabin_large`)

Ramura `transfagarasan/kit-h`. Build: `tools/blender/build_tf_vehicles.py` (`TF_ONLY=ro_train|cable_cabin_large`).
Previews: `tools/blender/preview_tf_h.py` (`--compare`, `--views`, `--consist`, `--align`, `--scale`).
Verdict: `bash tools/blender/verify_transfagarasan.sh` -> `VERDICT KIT: OK`.

## Reluare (tf-h2)

Constructorul din tf-h a fost respins de coordonator pe ambele piese; tf-h2 le-a refacut de la decupare + verdict.
Cifrele din kit §1.7 (loco 17 m, vagon 20 m, cabina 5,5 x 3,2 x 3,0) sunt **ANULATE**: scara de joc a garniturilor
existente e 8-9 m pe piesa, iar cabina de pe planșa e aproape un cub.

- Tren: loco ~11 m, tender ~5 m, vagon ~8,5 m, h ~3,6 m (fara pantograf), latime ~2,9 m. Banda gri lata jos (z 0,95..1,50)
  + linie FOAM_WHITE subtire la limita rosu/gri (galbenul e slot de masini). Pantograf-romb de ~3,5 m (1/3 din loco) pe postament.
- Cabina: ~4,2 x 3,4 x 3,3 m, colturi rotunjite pe verticala, geamuri ~50% din inaltime (panouri inalte intre montanti
  rosii latiti, adancite ~4 cm), brau rosu plin jos, acoperis bombat cu rama, brat in A, carucior = grinda joasa de 3 m pe X cu 4 roti.

## Cote masurate (din GLB)

| nod | X (lungime) | inaltime | latime | tri | sloturi |
|---|---:|---:|---:|---:|---|
| `Train_Loco` | 10,80 | 4,44 (pantograf ridicat; ~3,6 fara) | 2,92 | 8.984 | CAR_RED 14, ASPHALT_EDGE 6, VOLCANIC_BLACK 20, FOAM_WHITE 22 |
| `Train_Tender` (bagaje) | 5,00 | 3,58 | 2,92 | 2.976 | idem |
| `Train_Wagon` | 8,30 | 3,58 | 2,92 | 5.240 | idem |
| `Cabin_Body` | 4,21 | 3,30 | 3,41 | 2.676 | CAR_RED 14 |
| `Cabin_Glass` | 4,13 | 1,62 | 3,33 | 200 | VOLCANIC_BLACK 20 |
| `Cabin_Cart` (brat + carucior) | 3,00 | 4,00 | 1,40 | 1.672 | ASPHALT_EDGE 6, VOLCANIC_BLACK 20 |

`ro_train.glb` 17.200 tri; `cable_cabin_large.glb` 4.548 tri, total 4,21 x 3,41 x 7,25 m, varful rotilor la y = 0 (`--origin=rim`), cablul pe X.

## Aliniere cu PeruRail (TrainHazard)

| | ro_train | perurail_train.glb | train.glb (implicit) |
|---|---|---|---|
| bot | +X | +X | +X |
| baza rotilor | y = 0,00 (loco 0,01: poligon 12 laturi) | 0,000 | 0,000 |
| ecartament (centru roata) | \|z\| = 0,45 | 0,45 (bandaj 0,53) | 0,45 |
| loco L x H x W | 10,8 x 4,44 x 2,92 | 8,9 x 3,59 x 2,86 | 8,09 x 3,58 x 2,87 |
| tender L x H | 5,0 x 3,58 | 5,0 x 3,62 | 5,21 x 2,35 |
| vagon L x H | 8,3 x 3,58 | 8,0 x 3,62 | 8,06 x 2,95 |
| garnitura cu 3 vagoane (+ 4 x 1,2 m) | **~45,5 m** | ~42,7 m | ~42 m |

Garnitura e cu ~7% mai lunga decat PeruRail (loco cerut ~11 m, vagon ~8,5 m): drumul sta blocat ~1,4x. Daca e prea mult: `hl` in
`build_train_loco` (5,0 -> 4,6 ia 0,8 m) sau `WAGON_COUNT` in `train_hazard.gd`. `model_path = "res://assets/models/transfagarasan/vehicles/ro_train.glb"`
e singurul setaj necesar. Imagine: `docs/asset_briefs/img/transfagarasan_fidelity/ro_train_vs_perurail.png`.

## Fidelitate element cu element

| element | planșa | GLB | |
|---|---|---|---|
| loco: corp rosu, banda gri lata jos, acoperis gri bombat | da | da (banda 0,95..1,50) | OK; din sus acoperisul gri domina mai mult decat pe planșa |
| linie subtire deschisa la limita | galbena | FOAM_WHITE 22 | abatere declarata (galben = slot de masini) |
| loco: usi + ferestre + grile pe parte | ~2+3+2 | 2+3+2 | OK |
| cabine la ambele capete (parbrize, 3 faruri) | 1 capat vizibil | 2 capete | OK |
| 2 pantografe, mari, unul ridicat | 2, brate rosii inalte | 2 romburi de ~3,5 m, varf 4,4 m | OK ca marime/citire; mai turtit decat pe planșa (plafon 4,4 m) |
| 2 boghiuri, 8 roti | da | da | OK |
| vagon: ferestre + usa + capat negru | 3 + 1 | 4 + 2 usi pe parte, capat negru | OK |
| ovalul cu text | da | omis | regula fara text |
| proportii: loco mai lunga ca vagonul | ~1,7x | 1,3x | mai putin decat planșa (cota de joc 10,8 / 8,3) |
| cabina: proportie cub | ~1,2:1 | 4,2 x 3,4 x 3,3 = 1,27:1 | OK |
| cabina: colturi rotunjite vertical, montanti de colt curbati | da | da | OK |
| cabina: geamuri ~50% inaltime, panouri inalte, montanti latiti | da | 4 pe lung, 3 pe scurt, z 1,38..3,0 | OK; geam plat negru-gri fara reflexii |
| cabina: brau rosu plin jos ~40% | da | 0..1,35 m (41%) | OK |
| cabina: acoperis bombat + rama | da | da | OK |
| brat A ingustat in sus + carucior lung orizontal cu 4 roti | da | 4 picioare in A, coloana, carucior 3 m, 4 roti | OK; bratul e piramida simpla, mai putin zabrele |

Scara cabinei: `cable_cabin_scale.png` (cabina ~1,8x lungimea gondolei alpine Track09).

## Runde
- tf-h (predecesor): 2 runde, respins (scara 17/20 m, flanc rosu pana la talpa, pantograf-fir, cabina "butoi" 1,8:1 cu banda de geam).
- tf-h2 cabina: runda 1 (acceptata de constructor; 1 runda ramasa).
- tf-h2 tren: runda 1 (reconstructie) + runda 2 (banda 1,60 -> 1,50, brate pantograf 14 -> 19 cm, usi 1,62 -> 1,55). Max atins.

## Stare la oprire
- Livrate: ambele GLB, verify OK (`VERDICT KIT: OK`), val 2 neatins (parked_car_a/b, motorbike: `git status` curat pe ele).
- Abateri: loco/vagon 1,3x (nu 1,7x ca pe planșa); pantograf turtit de plafonul 4,4 m; linie alba in loc de galbena; brat de cabina fara zabrele fine; garnitura ~45,5 m vs 42,7 PeruRail.
- Trenul: verdict de fidelitate de dat de coordonator pe `ro_train.png`; daca banda gri tot nu citeste destul, e decizie de slot (acoperisul si banda impart ASPHALT_EDGE).
