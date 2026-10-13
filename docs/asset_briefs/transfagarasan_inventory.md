# Inventar — kitul Transfagarasan (Track21)

Contract: `docs/asset_briefs/transfagarasan_kit.md`. Cote MASURATE din GLB
(`verify_glb.py`, `measure_tf_gap.py`; Godot Y-up, Blender +Y = Godot -Z).
Build: `tools/blender/build_tf_road.py` (vocabular: `transfagarasan_shapes.py`).
Verdict: `bash tools/blender/verify_transfagarasan.sh` -> `VERDICT KIT: OK`.

## Stare la oprire (pilot, 13 oct 2026)

Facut: harnasul (shapes, preview `--compare/--views/--sheet`, compose, verify,
`measure_tf_gap.py`) si `structures/tunnel_portal_balea.glb`. Verdict KIT: OK.
Comparatia a fost vazuta de constructor in 2 runde (din 3 permise); acceptarea
ramane a coordonatorului. Nimic altceva din kit nu e inceput. Stub-uri in
`transfagarasan_shapes.py` pentru valul 1: `schist_blade`, `dry_stone_wall`,
`tin_roof` (fara corp, NotImplementedError). `snow_layers` e gata pentru
`snow_wall` (alt profil: `profile=`).

## structures/tunnel_portal_balea.glb

| nod | slot | tri |
|---|---|---:|
| `Portal_Concrete` | CONCRETE 8 | 956 |
| `Portal_Snow` | FOAM_WHITE 22 | 232 |
| `Portal_Dust` | CONCRETE 8 (dungile; nod separat, fara clasa de beton) | 288 |
| `Portal_Void` | VOLCANIC_BLACK 20 (captuseala 3 m, fara capace) | 24 |
| total | `--origin=assembly`, scala/rotatia aplicate pe radacini | 1500 |

Cote: betonul 22,0 x ~4,0 (corp 3,2 + contraforturi/cornisa) x 11,0 m; cu zapada
**34,0 x 8,06 x 11,0 m** (zapada 8 m pe Y: abatere decisa, vezi mai jos). Origine
pe axa drumului, baza la 0, simetric fata-spate si stanga-dreapta. Fara asfalt.
Gura: jamburi la ±6,75 m pana la 7,2 m, arc turtit cu sageata 1,35 m (cheia 8,55 m).

### CONTRACT: golul (`measure_tf_gap.py`, proiectie pe plan, grila 5 cm)

| fereastra | portal nou | `mountain_tunnel` x(1,5; 1,25; 1,0), fara asfalt | contract |
|---|---|---|---|
| lateral, banda caroseriei 0-2 m | **13,40 m** (x -6,70..+6,70) | **11,95 m** (x -5,83..+6,12) | >= 13,0 |
| lateral la 0,15-2 m | 13,40 m | 11,95 m | — |
| lateral la 1 m / 2 m (benzi de 5 cm) | 13,50 / 13,40 m | 11,95 / 12,00 m | — |
| inaltime libera minima | **7,15 m** (jamburi; mediana 8,15) | **5,20 m** (mediana 6,65) | >= 7,0 |

Brut (scara 1): `mountain_tunnel` are 7,95 m gol si 4,20 m inaltime libera.
Noul portal NU e mai ingust decat cel provizoriu — e mai lat cu 1,45 m si mai
inalt cu 1,95 m. Observatie: golul provizoriu (11,95 m, asimetric) e mai ingust
decat drumul din tunel (±6,0 = 12 m) si trece totusi ProbeRace; noul gol
acopera drumul cu ~0,7 m pe parte. Fereastra "la 0 m" a lui `mountain_tunnel`
nu se citeste (asfaltul din GLB-ul lui, scos cu `--floor=0.12`, lasa 29 m).
Captuseala `Portal_Void` strange golul cu 0,03 m pe parte si e inclusa in cifre.

### Fidelitate

Comparatia: `docs/asset_briefs/img/transfagarasan_fidelity/tunnel_portal_balea.png`
(decupare | randare din GLB, 3/4, culoare reala; `*_Concrete` pe #B8B4AA, `*_Snow`
pe #E8ECEE), 4 azimuturi: `tunnel_portal_balea_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| frontispiciu | placa plata de beton, ~1,4:1 in 3/4, adanca, ocupa centrul | placa plata 22 x 10,35 m + cornisa, corp 3,2 m | abatere: pe desen gura e ~55% din latime si frontispiciul pare masiv; aici gura (13,4 m, contract) e 61% din 22 m, iar adancimea de 4 m il face sa para o arcada subtire |
| cornisa | banda sus, usor iesita | placa + filet, 0,38/0,18 m iesite pe fata si spate | OK |
| gura | pentagon cu umeri tesiti, interior intunecat | arc turtit 10 fatete (contract), umerii nu sunt tesiti | abatere decisa de contract (arc segmental) |
| rama gurii | buza/cant in jurul golului | rama 0,45 m, 0,12 m iesita, fata si spate | OK |
| contraforturi | nu se disting clar | 2 pe fiecare fata, 1,8 m lat, 0,4 iesite, 4,3 m, capat in panta | OK (cerute de contract) |
| zapada | 5-6 blocuri fatetate pe parte, inalte (~60% din portal), infasoara portalul | 4 straturi cu trepte 0,3 m, 4 m (36% din 11), 8 m pe Y, nu infasoara | ABATERE MARE: contractul (4 m) si corectura "snow_wall" (straturi) bat desenul; masa e mai mica si mai "tort cu etaje" decat desenul |
| praf | — (corectura) | dungi pe fetele ±Y la baza fiecarui strat | OK; prea regulate/tan-bej la citire |
| captuseala umbra | interior intunecat | 3 m pe jamburi+arc; vizibila doar pe un jamb din 3/4 | OK |
| asfalt/marcaje | pe decupare | exclus (contract) | OK |
| text/placuta | — | fara | OK |

Runde: 1 (zapada 6 m pe Y) -> 2 (8 m, profil mai plin). Ce a ramas nerezolvat si
se raporteaza: proportia frontispiciului si masivitatea zapezii.
