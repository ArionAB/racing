# Inventar — kitul Monument Valley (Track19)

Contract: `docs/asset_briefs/monumentvalley_kit.md`. Cotele sunt MASURATE din GLB
(`verify_glb.py`, Godot Y-up; Blender +Y = Godot -Z).

## rocks/west_mitten.glb (pilot, revizia 3 — volum: tapering, coloane pe patru fete, fusta inalta)

| nod | slot(uri) | tri |
|---|---|---:|
| `Mitten_Rock` | TILE_TERRACOTTA 23 + RUST_METAL 10 (fetele cu normala spre -X) | 5096 |
| `Mitten_Scree` | RUST_METAL 10 + LARCH_RUST 27 (fetele coastelor alternante, bolovani alternanti) | 3944 |
| `Mitten_Cap` | SAND_LIGHT 0 (contract schimbat din MARBLE_GREY 29) | 392 |
| total | `VERDICT KIT: OK` (`--origin=assembly`) | 9432 |

Cote masurate: peretele 29,1 m + calota 0,9 m = **30,0 m**, varf plat (coloane
28,8-29,1 m); la baza X -12..+13 (cu talpa si iesirile coloanelor), ~13-14 m
adancime, **se ingusteaza ~15%** spre varf (placa calotei X -10,6..+10,9); calota
depaseste cu ~0,45 m pe X si ~0,7 m pe Y; deget x **-21,1..-15,3** (5,8 m la
baza), **26,0 m**, gol ~2,2 m la baza (talpa coloanelor), ~4,6 m la mijloc;
fusta x -23,9..+23,9 (raza ~22-24 m), **7,4 m** inalta langa perete (bolovani
incluși), scade la 0 la margine; origine la baza turnului (XY pastrat, Z min = 0).

Fidelitate: `docs/asset_briefs/img/monumentvalley_fidelity/west_mitten.png`
(decupare | randare), 4 azimuturi: `west_mitten_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| vârf | bloc cu vârf plat, calotă continuă | toate coloanele la 29,1 ±0,3 m, o placă continuă | OK |
| coloane | ~8 late pe fata lunga, teșite | ~24 pe TOT conturul (4 fete, colturi rotunjite din 2-3 coloane), 2-4 m, iesiri variate (+0,6 / -0,8..-1,2 m: ~30% in recese), muchii teșite, fata in V | OK; planșa are mai putine coloane, mai late |
| taper + praguri | masa mai larga jos, 2-3 retrageri | ingustare ~15% spre varf pe ambele axe, 2 praguri (~1/3, ~2/3) | OK |
| talpă | evazată ~20% | evazată pe Y ~1,4 m în ultimii ~5,8 m | OK (doar pe Y, nu pe X) |
| calotă | placă bej care depășește peretele, 2 trepte | o singură placă pe conturul coloanelor, +0,45/0,7 m, 2 trepte (0,9 + 0,4 m), SAND_LIGHT | OK; conturul planșei e mai festonat |
| fustă | coaste radiale, turnul asezat IN ea | 28 coaste radiale, 2 praguri de 0,3 m, urca la ~7,4 m langa perete, ~90 bolovani mari (margine/vai) + 40 mici | OK; coastele sunt mai netede decât pe planșă |
| deget | separat, bază groasă, 2 praguri, vârf rotunjit-ascuțit | separat, baza 5,8 m -> ~3 m, 2 praguri orizontale (8 și 17 m), ultimii ~2 m în 2 fatete -> vârf bont, 26 m | OK |
| gol de cer | vizibil până jos | 3,3 m la bază; vizibil din față și din 3 azimuturi; din spate degetul se suprapune corpului (acceptat) | OK |
| luminozități | stânga umbrită | fețele -X pe RUST_METAL | OK |
| proporție h/l turn | ~1,1-1,2 | 30/24 = 1,25 | la limita ±15% |

Abateri rămase: coloanele sunt tot prisme regulate (fara rupturi interne ca pe
planșă); taper-ul se citeste moderat din 3/4; degetul are doar ~2,2 m
fata de talpa coloanelor la baza (contract 3 m masurat de la perete); fusta e
mai neteda decat desenul, iar bolovanii mari sunt putini pe fata de jos.

## Grupa mv-a (sandstone_arch, east_mitten, merrick_butte, mesa_wall_module)

Build: `tools/blender/build_monument_rocks.py` (vocabular extins în `monument_shapes.py`:
`prism_xz`, `buttress`, `scree_boulders`, `mesa_run`, `mesa_scree`, `chamfer(skip=)`).
West Mitten nemodificat: 9432 tri, aceleași noduri. Verify: `VERDICT KIT: OK`
(`--origin=assembly`). Planșa grupei: `img/monumentvalley_fidelity_vala.png`.

| fișier | noduri | tri | cote măsurate |
|---|---|---:|---|
| `rocks/sandstone_arch.glb` | `Arch_Rock/_Scree/_Cap` | 5190 | 13,0 m înalt; puntea x ±12 (+1,1 talpa); adâncime Y ~7,4 m (rock), ~8,6 m cu calota; fusta până la x ±18 |
| `rocks/east_mitten.glb` | `EastMitten_Rock/_Scree/_Cap` | 8910 | turn 27,0 m, amprentă ~22 x 12 m, deget pe **+X** (centru x = 17,1), 23 m, fusta ≤ ~7,5 m |
| `rocks/merrick_butte.glb` | `Butte_Rock/_Scree/_Cap` | 11928 | 24,0 m, amprentă ~30 x 18 m, 3 contraforturi (13/18/11 m) pe fața +Y |
| `rocks/mesa_wall_module.glb` | `Mesa_Rock/_Scree/_Cap` | 2224 | 12,0 m pe Y, 14,0 m înalt, 6 m adânc (X −3..+3; 8,6 cu ieșirile și talpa), grohotiș 2,9 m (+X) / 1,9 m (−X) |

### CONTRACT ÎNGHEȚAT: golul arcului (`sandstone_arch.glb`, rev. 4 — masă plată cu gaură)

Măsurat cu `tools/blender/measure_arch_gap.py` pe GLB-ul exportat (re-importat),
proiecție pe planul XZ (drumul merge pe Y), TOATE nodurile (rocă + grohotiș +
calotă), grilă 5 cm; gol = regiune liberă de la sol, conectată la axa drumului.

- **lățime gol pe fereastra caroseriei (h 0–2 m): 15,45 m** (minim pe rânduri; contract ≥ 14)
- **înălțime liberă pe |x| ≤ 1,1 m: 8,95 m** (contract ≥ 7,5)
- lățimea golului: h 0,5 m 15,75 | h 2 m 15,45 | h 4 m 14,20 | h 6 m 12,30 | h 7,5 m 10,45
- intrados nominal superelipsă a = 7,9, b = 9,4, n = 2,4; blocurile inelului îl pot coborî în gol cu max 0,4 m (jos) / 0,7 m, deci nu e semicerc curat; nimic din grohotiș nu trece de x = ±7,9.
Orice modificare a arcului se re-măsoară cu scriptul (`VERDICT GOL: OK`).
Cote: 13,10 m înalt, ~28 m lat + talpă (42,7 m cu fusta), picioare ~7 m la bază, adâncime Y ~7,4 m (rock), 5836 tri.

### Fidelitate (decupare vs randare)

**sandstone_arch** (rev. 4, după al doilea verdict: extradosul nu mai urmează curba golului)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| siluetă | placă lată cu vârful ~orizontal, golul = gaură prin masă | vârf ~orizontal la ~12,5 m (±0,65 m per bloc, mai jos spre capete), timpanele pline | OK |
| blocuri | neregulate 2–5 m, teșite, decalate | 4 rânduri orizontale grosiere (3–3,8 m, fiecare mai retras cu 0,55 m) de blocuri late 3,5–6,5 m + inel de blocuri (3,2 m) în jurul golului; teșite, 2 felii pe adâncime cu ieșiri diferite | OK, dar rândurile rămân regulate (aspect de zid) |
| picioare | late, masive | ~7 m la bază, talpă evazată | OK |
| punte | ~5 m umeri, ~3 m coamă | ~3,5 m la coamă, mult mai mult la umeri (umplutură) | OK |
| intrados | trepte/neregulat | trepte 0,4–0,7 m între blocurile inelului | OK |
| calotă | 3–5 plăci separate, înălțimi diferite | 5 plăci PLATE (12,8–13,1 m), goluri 0,3 m | OK; dreptunghiuri teșite, fără contur festonat |
| grohotiș | bolovani la picioare | fustă + bolovani doar pe exterior | OK |

Abateri: arcul e ~28 m lat (tabel ~24 m) ca să iasă picioare de ~7 m cu golul păstrat;
blocurile sunt netede și rotunjite, rândurile prea regulate (zid); pe câteva fețe se văd
crăpături întunecate între inel și umplutură (felii cu ieșiri diferite).

**east_mitten** (runda 1)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| turn | bloc cu coloane late, vârf plat | ~16 coloane pe patru fețe, seed 23, 1,8–3,6 m (altă împărțire decât West) | OK |
| deget | pe dreapta, turlă, gol de cer | pe +X (oglindă), 23 m, gol ~3 m; din față (+Y) apare în STÂNGA, deci randarea de comparație e din spate (azimut 262) | OK, oglindirea declarată |
| calotă | placă bej în trepte | 2 trepte SAND_LIGHT | OK |
| fustă | coaste radiale, praguri | 28 coaste, 2 praguri, ~116 bolovani | OK; mai netedă |
| h/l | ~1,2 | 27/22 = 1,23 | OK |

**merrick_butte** (runda 1)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| bloc | lat, vârf plat, coloane | 24 m, ~14 coloane, taper 8% | OK |
| contraforturi | 2–3 pe fața lungă | 3 stâlpi (13/18/11 m), evazați, umăr înclinat | OK; mai netezi decât pe planșă |
| calotă | plată, în trepte | 2 trepte SAND_LIGHT | OK |
| grohotiș | fustă joasă, bolovani mulți | 64 coaste, ~130 bolovani | OK |
| h/l | ~0,8 | 24/30 = 0,8 | OK |

**mesa_wall_module** (runda 1)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| coloane | 4–5 pe modul | 5 (2 de capăt identice + 3), V pe față și spate | OK; mai uniforme decât planșa |
| capete | — | **identice**: aceleași puncte (x, z) la y = −6 și +6 (verificat pe GLB: 16/16 vârfuri Rock, 8/8 Cap, 42/42 Scree), plane, fără teșire pe colțurile de capăt; 3 module cap la cap în `mesa_wall_module_chain.png`: fără fisură | OK |
| calotă | continuă, bucăți | placă continuă în 2 trepte, capete plane | OK |
| grohotiș | bolovani la picior | coaste perpendiculare (perioadă 3 m) ≤ 3 m + 9 bolovani | OK; mai puțini bolovani decât planșa |

Abateri: coloanele rămân prisme netede (fără rupturi interne); grohotișul modulului e o
rampă cu coaste, puțini bolovani. Fața peretelui de masă e pe **+X** (spatele −X, mai
scund): coordonatorul îl rotește la montare.

## Stare la oprire

- Pilotul `west_mitten` livrat, revizia 3 făcută (volum: coloane pe patru fete cu
  taper si recese, fustă înaltă; păstrate vârful plat, calota SAND_LIGHT, coastele, degetul). Harnasul
  (`monument_shapes.py`, `preview_monument.py` + `compose_monument.py`,
  `verify_monumentvalley.sh`) funcționează.
- Vocabularul `monument_shapes.py` a fost refăcut la revizie (`wall_columns` pe
  tot conturul (rev. 3: sectoare pe arc, taper, recese), `cap_slab`, `scree_ribs`, `tapered_spire`); `east_mitten`
  și restul pot folosi aceleași funcții.
- `preview_monument.py` pune clasa `mv_sandstone` (#B8552E) pe nodurile `*_Rock`.

## Grupa mv-b: plante (`build_monument_plants.py`, revizia 3 dupa verdictul coordonatorului)

Verdict: `bash tools/blender/verify_monumentvalley.sh` -> `VERDICT KIT: OK` (juniper si
rabbitbrush cu `--origin=assembly`, rabbitbrush cu `--allow-car-slots=Rabbitbrush_Bloom`).
Comparatii: `img/monumentvalley_fidelity/<nume>.png`; planșa: `img/monumentvalley_fidelity_valb.png`.
Yucca acceptata (neschimbata).

**Verificarea culorilor (punctul 0).** Tabelul `PALETTE_HEX` din `preview_monument.py` e
IDENTIC cu `HEX` din `scripts/palette.gd` (verificat pe toate cele 32 de intrari). UV-urile din
GLB-uri (citite din fisier) cad exact pe sloturile intentionate, vezi coloana "sloturi (fete)".
Deci verdele "ierbos" NU e o eroare de mapare: slotul 12 chiar e `#5B7C34` (91,124,52),
iar randarea preview il da (70-77, 96-105, 39-43) dupa AO+lumina. Pe `juniper` randarea
masurata e (70,96,39), oliv-verde si nu mai palid; am pastrat 12 (nu 21) fiindca
TROPICAL_GREEN `#3F7A3C` e mai albastrui. Slotul 12 e "oliv sters" doar in comparatie cu 21.

| fisier | noduri (sloturi, fete) | tri | cote (m) | RGB randat masurat |
|---|---|---:|---|---|
| sagebrush | `Sagebrush`: WOOD 9 + DRY 13 (tulpini, frunze pe sol, 505 tri); `Sagebrush_Foliage`: CACTUS 12 (toate smocurile, 840 tri) | 1345 | 1,38 x 1,33 x 1,12 | verde slot 12 (tenta gri-verde = clasa la integrare) |
| juniper | `Juniper_Trunk` WOOD 9; `Juniper_Crown` CACTUS 12 | 2089 | 4,37 x 3,88 x 4,21 | coroana (70,96,39) |
| rabbitbrush | `Rabbitbrush` CACTUS 12 + DRY 13; `Rabbitbrush_Bloom` CAR_YELLOW 16 | 2424 | 1,54 x 1,53 x 1,21 | flori (163,141,43) |
| tumbleweed | `Tumbleweed` LARCH_RUST 27 | 2726 | 0,93 x 0,94 x 0,96 | (132,82,45) |

| piesa / element | pe decupare | in GLB | verdict |
|---|---|---|---|
| sagebrush | smocuri fine, gri-verzi | 15 smocuri-flacara pe 5 tulpini lemnoase ramificate, toate pe CACTUS 12 in `Sagebrush_Foliage` (rev. 4: fara amestec 29/12; paloarea vine din tenta de clasa) | structura OK; culoarea finala depinde de clasa/tenta coordonatorului |
| juniper trunchi | tulpini rasucite din pamant | 3 tulpini rasucite pornite din baza comuna, ramificate la 1,2-1,5 m, 2 ramuri joase orizontale | OK |
| juniper coroane | ciorchini la inaltimi diferite | 8 ciorchini turtiti (2 joase pe laturi), 5 bulgari fiecare | OK; desenul are volume mai mari si mai dese |
| rabbitbrush | perna densa, frunzis verde dedesubt | 48 ciorchini x 2 bulgari pe dom (treimile de sus/mijloc), inel de 18 frunzulite CACTUS 12, tulpini ascunse | perna OK; frunzisul e mai rar decat pe desen |
| tumbleweed | retea de crengute arama | neschimbat ca forma, culoare LARCH_RUST 27 | OK; bucle poligonale |
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
