# Inventar — kitul Monument Valley (Track19)

Contract: `docs/asset_briefs/monumentvalley_kit.md`. Cotele sunt MASURATE din GLB
(`verify_glb.py`, Godot Y-up; Blender +Y = Godot -Z).

## rocks/west_mitten.glb (pilot, revizia 2 dupa verdictul coordonatorului)

| nod | slot(uri) | tri |
|---|---|---:|
| `Mitten_Rock` | TILE_TERRACOTTA 23 + RUST_METAL 10 (fetele cu normala spre -X) | 1960 |
| `Mitten_Scree` | RUST_METAL 10 + LARCH_RUST 27 (fetele coastelor alternante, bolovani alternanti) | 3544 |
| `Mitten_Cap` | SAND_LIGHT 0 (contract schimbat din MARBLE_GREY 29) | 236 |
| total | `VERDICT KIT: OK` (`--origin=assembly`) | 5740 |

Cote masurate: peretele 29,1 m + calota 0,9 m = **30,0 m**, varf plat (variatie
coloane 0,3 m); X -12..+12 (24 m), adancime ~13-14 m; calota depaseste cu ~0,45 m
pe X si ~0,7 m pe Y (placa X -12,45..+12,45); deget x **-21,1..-15,3** (5,8 m
la baza, ~3,5 m pe la 2/3), **26,0 m**, gol **3,3 m** fata de corp la baza
(2,85 m la nivelul calotei); fusta x -24..+24,8 (raza ~22-24 m), **4,5 m** inalta
(bolovani incluși); origine la baza turnului (XY pastrat, Z min = 0).

Fidelitate: `docs/asset_briefs/img/monumentvalley_fidelity/west_mitten.png`
(decupare | randare), 4 azimuturi: `west_mitten_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| vârf | bloc cu vârf plat, calotă continuă | toate coloanele la 29,1 ±0,3 m, o placă continuă | OK |
| coloane pe fața lungă | ~8 late, teșite | 8 coloane (~3 m), muchii teșite cu 2 fatete pe colț, fața în V | OK; planșa are coloane mai neregulate |
| praguri orizontale | 2-3 retrageri | 2 (la ~1/3 și ~2/3), retragere ~0,45 m | OK |
| talpă | evazată ~20% | evazată pe Y ~1,4 m în ultimii ~5,8 m | OK (doar pe Y, nu pe X) |
| calotă | placă bej care depășește peretele, 2 trepte | o singură placă pe conturul coloanelor, +0,45/0,7 m, 2 trepte (0,9 + 0,4 m), SAND_LIGHT | OK; conturul planșei e mai festonat |
| fustă | coaste radiale, 1-2 praguri slabe, bolovani la margine/în văi | 28 coaste radiale (vale/creastă), 2 praguri de 0,3 m, ~70 bolovani mari (la margine, în văi) + 40 mici dincolo de margine | OK ca structură; coastele sunt mai netede decât pe planșă |
| deget | separat, bază groasă, 2 praguri, vârf rotunjit-ascuțit | separat, baza 5,8 m -> ~3 m, 2 praguri orizontale (8 și 17 m), ultimii ~2 m în 2 fatete -> vârf bont, 26 m | OK |
| gol de cer | vizibil până jos | 3,3 m la bază; vizibil din față și din 3 azimuturi; din spate degetul se suprapune corpului (acceptat) | OK |
| luminozități | stânga umbrită | fețele -X pe RUST_METAL | OK |
| proporție h/l turn | ~1,1-1,2 | 30/24 = 1,25 | la limita ±15% |

Abateri rămase: peretele e mai "geometric" decât planșa (prisme regulate, aceeași
adâncime); capătul X (fața de 13 m) citit din azimut 35 e o față lată, netezită;
fusta e mai joasă și mai netedă decât desenul; gol la nivelul calotei 2,85 m
(contract 3 m, la bază 3,3 m).

## Stare la oprire

- Pilotul `west_mitten` livrat, revizia 2 făcută (vârf plat, coloane late
  teșite, calotă SAND_LIGHT, fustă cu coaste, deget bont). Harnasul
  (`monument_shapes.py`, `preview_monument.py` + `compose_monument.py`,
  `verify_monumentvalley.sh`) funcționează.
- Vocabularul `monument_shapes.py` a fost refăcut la revizie (`wall_columns` cu
  teșire + 3 segmente, `cap_slab`, `scree_ribs`, `tapered_spire`); `east_mitten`
  și restul pot folosi aceleași funcții.
- `preview_monument.py` pune clasa `mv_sandstone` (#B8552E) pe nodurile `*_Rock`.

## Grupa mv-c: drum, gard, semne (`build_monument_road.py`)

Comparatii: `docs/asset_briefs/img/monumentvalley_fidelity/<nume>.png`; planșa grupei:
`docs/asset_briefs/img/monumentvalley_fidelity_valc.png`. `verify_monumentvalley.sh` -> `VERDICT KIT: OK`
(toate cu `--origin=assembly`; singura exceptie de slot de masina: `Sign_Face` CAR_YELLOW).

| fisier | noduri | tri | cote masurate (X x Y x Z, m) |
|---|---|---:|---|
| props/cattle_guard | Guard_Steel, Guard_Posts | 704 | 14,85 x 2,40 x 1,20; bare sus la 0,148 m; **stalpi la x = +-7,3** (1,2 m, 0,25 m), grila x +-7,0 |
| props/open_range_sign | Sign_Post, Sign_Face (CAR_YELLOW), Sign_Horse (VOLCANIC_BLACK) | 272 | 1,37 x 0,20 x 2,63 |
| structures/telegraph_pole | Pole_Wood, Pole_Insulators | 216 | 2,02 x 0,32 x 8,04 (3 izolatori, fara fire) |
| structures/wire_fence | Fence_Posts, Fence_Wire | 872 | 0,27 x **4,00** x 1,20 (capete plane la y = +-2,0) |
| structures/windmill_pump | Mill_Steel, Mill_Trough, **Windmill_Rotor** (pivot la butuc, 0; 0,55; 9,0) | 1364 | 3,0 x 6,1 x 10,27; rotor Ø 2,5, jgheab Ø 3 |
| structures/water_tower | Tower_Timber, Tank_Wood, Tank_Hoops | 1046 | 4,48 x 4,83 x 11,06; rezervor Ø 3,2 |
| structures/corral | Corral_Wood, Corral_Gate | 696 | 10,06 x 8,06 x 1,50 |
| structures/shade_ramada | Ramada_Frame, Ramada_Roof | 1080 | 5,14 x 4,34 x 3,05 |

Fidelitate (element | planșa | GLB | verdict):

| piesa | element | planșa | GLB | verdict |
|---|---|---|---|---|
| cattle_guard | forma | rampa in trepte | PLAT, corectura coordonatorului | abatere decisa |
| | bare | ~9-10 busteni | 11 bare tubulare de otel | OK |
| | capete | cadre galbene inclinate | blocuri galben/negru plate + 2 stalpi | OK |
| open_range_sign | romb + stalp | romb galben cu chenar | romb CAR_YELLOW, chenar lemn, stalp 2,6 m | OK |
| | cal | siluet negru, mers | contur 2D de 51 puncte extrudat 3 cm: gat arcuit ~40 grade, cap lung, coama, piept adanc, coada atarnata, 4 picioare subtiri (o pereche in pas), VOLCANIC_BLACK | OK (citeste ca cal; colturos, coada atinge marginea rombului) |
| telegraph_pole | stalp, traversa, V, izolatori | 1 stalp, traversa groasa, 2 sprijine, 2 izolatori albi | la fel + al 3-lea izolator in varf | OK |
| wire_fence | stalpi + fire | 2 stalpi, 4 fire cu tepi | 2 stalpi rotunzi 8 laturi (1,17 / 1,23 m), 4 fire subtiri (r 0,018, 4 laturi, LOG_DARK), tepi in cruce CONCRETE la 0,5 m | OK |
| windmill_pump | turn, rotor, coada, jgheab | turn mai scurt si lat, jgheab mare inalt (~0,8 m), pale intunecate | turn 9 m mai zvelt, jgheab 0,6 m, pale pale | **abatere** de proportie (cotele contractului), culoare |
| water_tower | rezervor cu cercuri, capac conic, X, scara | idem | idem (2 deschideri X, 4 cercuri, 12 laturi) | OK; fara arcul de jos |
| corral | 3 bare, stalpi, poarta | busteni rotunjiti, colturi suprapuse | stalpi 0,26, bare Ø 0,17, poarta inchisa cu diagonala | OK ca structura, mai drept/curat |
| shade_ramada | 4+ stalpi, acoperis haotic, masa | stalpi rotunzi, acoperis dens neregulat | 6 stalpi patrati, 17 chirpici + 10 pane, masa+2 banci | **abatere**: acoperisul e mai rar si mai regulat |

Abateri: corral 10,06 x 8,06 (stalpii de colt ies cu 3 cm); wire_fence are stalpii flush pe
capete, deci doua segmente inlantuite dau un stalp dublu de 0,36 m; cattle_guard fara text si
fara fire intre stalpi.

## Grupa mv-d: cladiri, vehicule, oameni

Build: `build_monument_buildings.py`, `build_monument_vehicles.py` (vocabular nou: `monument_pen.py`, penita
cu transformare pentru piese compuse). Camere: `preview_specs_d.py`. Comparatii:
`docs/asset_briefs/img/monumentvalley_fidelity/<nume>.png`; planșa grupei:
`docs/asset_briefs/img/monumentvalley_fidelity_vald.png`. `verify_monumentvalley.sh` -> `VERDICT KIT: OK`
(`--origin=assembly` la toate; `--allow-car-slots=Truck_Body` si `=Tourist_Clothes` conform brief §0).

| fisier | noduri | tri | cote masurate (X x Y x Z, m) |
|---|---|---:|---|
| buildings/trading_post | Post_Stone, Post_Wood, Post_Roof, Post_Openings | 1064 | 12,06 x 9,25 x 7,54; parapet 5,0; cos 7,5 |
| buildings/homestead_house | Home_Walls, Home_Stone, Home_Wood, Home_Roof, Home_Openings | 1184 | 7,16 x 9,24 x 6,62; coama ~5,5, cosul pana la 6,6 |
| buildings/hogan | Hogan_Logs, Hogan_Roof, Hogan_Openings | 1846 | 7,34 x 7,56 x 3,54; EXACT 8 laturi (apotema 3,5), 56 busteni |
| vehicles/pickup_old | Pickup_Body, Pickup_Glass, Pickup_Trim, Pickup_Wheels | 772 | 2,05 x 5,23 x 1,90; roti 10 segmente, botul pe +Y |
| vehicles/tour_truck | Truck_Body (CAR_BLUE), Truck_Glass, Truck_Trim, Truck_Seats, Truck_Wheels | 1092 | 2,25 x 5,49 x 2,60; roti 10 segmente, botul pe +Y |
| props/tourist_group | Tourist_Clothes (CAR_BLUE/CAR_RED/SAND_MID), Tourist_Skin, Tourist_Gear | 1524 | 3,64 x 0,74 x 1,81; 4 oameni 1,58-1,75 m (+palarii) |

**Fata cladirilor, MASURATA pe GLB** (`tools/blender/measure_front_glb.py`: aria goluri `*_Openings` orientate spre
exterior, in coordonate Godot): trading_post **-Z** (7,5 m2 fata de ~2,0 pe laturi), homestead_house **-Z**
(4,5 fata de 2,3), hogan **-Z** (1,9, usa; fereastra 0,5 pe latura vecina -X/-Z). Adica +Y in Blender, cum cere brief-ul.

Fidelitate (element | planșa | GLB | verdict):

| piesa | element | planșa | GLB | verdict |
|---|---|---|---|---|
| trading_post | corp | zid de piatra mare, caramiziu-bej | volum 11,6 x 6,8, SAND_MID, 4 colturi cu pietre alternante | OK (zidaria fina vine din clasa) |
| | prispa | 4-5 stalpi, acoperis lean-to jos, treapta | 5 stalpi rotunzi, lean-to, treapta | OK |
| | fata | usa la mijloc, 2 ferestre | usa + 2 ferestre, 1 pe fiecare latura | OK |
| | acoperis | **inclinat, in trepte, bej** | **plat cu parapet** (contract §1.5), tabla gri ASPHALT_EDGE | **abatere decisa** de contract; culoarea gri (slot) cade pe tonul planșei doar cu clasa |
| | cos | mare, central-spate, blocuri | 1,3 m patrat, 7,5 m, 2 sloturi alternante, gura neagra, spate-stanga | OK ca forma; mai subtire decat pe planșa |
| homestead_house | siluet | doua ape, fronton pe fata, prispa lean-to | idem | OK |
| | pereti | scanduri orizontale gri-bej | CONCRETE + 6 nervuri SAND_LIGHT | OK |
| | ferestre | 2 pe lateral dreapta, 1 in fronton | 2 pe fiecare lateral, 1 in fronton | OK |
| | cos | pe panta dreapta, caramiziu | pe panta dreapta, 2 sloturi | OK |
| | acoperis | maro-gri | tabla gri inchis | OK (mai inchis) |
| hogan | pereti | busteni orizontali, capete iesite | 7 randuri x 8 laturi, capete iesite, 2 sloturi | OK |
| | acoperis | dom in trepte cu panouri, horn de lemn | 2 trepte SAND_MID + guler + gaura neagra | OK; fara nervuri radiale (mai neted), ton mai galben |
| | usa/fereastra | usa de lemn inchis, fereastra pe stanga | usa neagra cu rama + treapta, fereastra pe latura vecina | OK; usa gri-inchis in loc de maro (slot VOLCANIC_BLACK) |
| pickup_old | silueta | capota lunga rotunjita, cabina, bena | capota/cabina/bena din volume cu colturi tesite | **abatere**: mai colturos, aripile rotunde doar ca bombe interioare |
| | detalii | grila, bara bej, faruri rotunde | grila + bara CONCRETE, 2 faruri 10 laturi | OK |
| | culoare | rugina portocalie | RUST (10), geamuri VOLCANIC_BLACK | OK |
| tour_truck | silueta | 4x4 box, bena lunga, cadru de bare | capota + caroserie cu pereti + cadru 4 x 2 stalpi | OK; capota mai colturoasa |
| | cadru | bare negre, ~3 arcuri | 4 arcuri de bare (6 laturi), 2 sine | OK |
| | banchete | 3 randuri x 2, caramel | 3 x 2, WOOD | OK; spatare mai joase decat pe planșa |
| | caroserie | albastru, aripi gri-negre | CAR_BLUE; **fara aripi negre** | **abatere** minora |
| tourist_group | oameni | 4, doi cu aparat foto, rucsaci | 4, aparate ridicate la P1 si P4, rucsaci | OK |
| | proportii | naturale, picioare lungi | trunchi dreptunghiular, membre drepte (low-poly) | OK ca nivel cerut; **abatere**: fara mers/inclinari |
| | haine | albastru/portocaliu/kaki, palarii | CAR_BLUE/CAR_RED/SAND_MID, sapci + palarii | OK |

Abateri: camionul si pickup-ul n-au caroserie rotunjita fina (primitive cu muchii tesite);
trading_post-ul are acoperis plat conform contractului, nu cel in trepte de pe planșa; dimensiunile `X` ale
hoganului (7,34) includ capetele de busteni la colturi, nu doar apotema de 7,0.
