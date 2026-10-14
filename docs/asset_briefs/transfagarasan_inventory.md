# Inventar — kitul Transfagarasan (Track21)

Contract: `docs/asset_briefs/transfagarasan_kit.md`. Cote MASURATE din GLB
(`verify_glb.py`, `measure_tf_gap.py`; Godot Y-up, Blender +Y = Godot -Z).
Build: `tools/blender/build_tf_road.py` (vocabular: `transfagarasan_shapes.py`).
Verdict: `bash tools/blender/verify_transfagarasan.sh` -> `VERDICT KIT: OK`.

## Valul 3 — integrat (13 oct 2026)

Kitul e complet: **36 de modele**. Inventarele pe grupe:
- `transfagarasan_inventory_g.md`, tf-g: `effects/transfagarasan_horizon.glb`
  (`FagarasRidge_A/_B/_C`, `CloudSea_A/_B`, `FagarasPlain_A`), **provizoriu**;
- `transfagarasan_inventory_h.md`, tf-h: `vehicles/ro_train.glb` și
  `vehicles/cable_cabin_large.glb`, acceptate.

`verify_transfagarasan.sh`: **VERDICT KIT: OK**. `ro_train` are în plus o
verificare: nodurile `Train_Loco/_Tender/_Wagon` sunt copii direcți ai rădăcinii.

**Abateri asumate:**
- **fundalul nu a convers** (3 runde tf-g, 2 la reluarea tf-g2). GLB-ul combină
  creasta tf-g, care din camera de joc citește lanț muntos, deși e prea
  „Dolomiți”, cu norii tf-g2. Peretele cu dinți egali al reluării citea
  pieptene. Verdictul final se dă pe pista reală;
- **contractul trenului și al cabinei avea cifre greșite** (17 m / 20 m,
  cabina 5,5 m). S-au corectat în kit §1.7 la scara de joc.

**De făcut la montarea în Track21:**
- **fundalul:**
  - tema `transfagarasan`: `horizon_model` = GLB-ul, `horizon_class` = `""`,
    plus inelele din `transfagarasan_inventory_g.md`;
  - creasta la est, la 200–260 m;
  - norii la est/sud-est, la 240–320 m;
  - câmpia la nord, la 280–340 m;
  - **cod nou:** `_build_horizon` pune azi fiecare piesă la `ground_y − 4`.
    Norii (17 m grosime) și câmpia cer o coborâre per inel (~−28 m), altfel
    se văd doar unde terenul e deja sub drum;
- **trenul:** `TrainHazard.model_path` =
  `res://assets/models/transfagarasan/vehicles/ro_train.glb`. Garnitura cu
  3 vagoane are ~45,5 m; se verifică pe ProbeRace că blocajul de la trecere
  nu crește;
- **cabina:** originea pe linia cablului, cablul pe X local, fără offset.
  Înlocuiește gondola alpină în `DecorManual`.

## Valul 2 — integrat (13 oct 2026)

Inventarele pe grupe:
- `transfagarasan_inventory_d.md`, tf-d: `vidraru_dam` (`Dam_Module`,
  `Dam_Tower`, `Dam_PowerHouse`), `poenari_ruin`, `prometheus_statue`;
- `transfagarasan_inventory_e.md`, tf-e: `cabana_balea_lac`,
  `cabana_balea_cascada`, `stana`, `arges_house_a`, `arges_house_b`,
  `souvenir_stall`;
- `transfagarasan_inventory_f.md`, tf-f: `parked_car_a`, `parked_car_b`,
  `motorbike`, `sheepdog`.

`verify_transfagarasan.sh`: **VERDICT KIT: OK**, cu verificare nouă pe baraj
(`measure_tf_deck.py`): nimic peste −0,05 m pe banda drumului (maximul măsurat
−0,080 m), iar parapetele au 1,100 m. Coordonatorul a acceptat toate piesele pe
comparații.

**Abateri asumate:**
- **turnul de priză al barajului** citește mic;
- **Prometeu** are poza frontală și simetrică;
- **Poenari:** flancurile X stau la 77° (contract 60–70°), deci de aproape se
  citește trunchi de con cu contraforturi. De la 190 m se citește ruină pe
  stâncă;
- **ciobănescul:** pata de pe flanc e geometrică, iar picioarele par stâlpi;
- **cabana Bâlea Lac:** coama e la 13,67 m (contract ~13), fiindcă două
  niveluri de lemn la 45° nu încap sub 13 m;
- **tabla ruginie** e foarte saturată, iar tenta o corectează la integrare.

**Decizii de contract luate în val:**
- **tabla argintie e pe `ASPHALT_EDGE` 6, nu pe `PAINTED_METAL` 11.** Hexul
  #7692A8 e albastru, iar tenta doar întunecă;
- **cabana Bâlea Lac** are 13 × 10 m, cu două niveluri de lemn;
- **petele ciobănescului** sunt pe `ASPHALT_EDGE`;
- **`verify_glb.py --rim-above`**: `--origin=rim` cu geometrie admisă peste 0,
  necesară pentru parapet și turn.

**De făcut la montarea în Track21:**
- **barajul:** 6 × `Dam_Module` pe fracțiile 0,078–0,123; turnul și centrala
  primesc transformul modulului lângă care stau;
- **Poenari:** amplasat ca vârful turnului să intre sub plafonul cadrului de la
  190 m, care lipsește cu ~1 m;
- **turma:** `HerdHazard.alt_model` = `sheepdog.glb`, `zebra_ratio` ~0,1, iar
  `leg_top` comun cu oaia, ales pe captura din joc;
- **coliziunea:** mașinile parcate, motocicleta, gardurile și țarcul cer
  colizori simpli;
- **tentele:**
  - `concrete` pe `*_Concrete`;
  - `stone_wall` pe `*_Stone`;
  - `plaster` pe `*_Plaster`;
  - tabla `*_Roof` luminată;
  - `tf_schist` pe `Poenari_Schist` și pe `Statue_Schist`.

## Valul 1 — integrat (13 oct 2026)

Inventarele pe grupe, fiecare cu cote, triunghiuri, noduri, tabele de
fidelitate și „Stare la oprire”:
- `transfagarasan_inventory_a.md`, tf-a, drumul: `snow_wall`,
  `rock_tunnel_portal`, `retaining_wall_straight/curve`, `snow_pole`,
  `road_works`, `level_crossing`, `bear_warning_sign`;
- `transfagarasan_inventory_b.md`, tf-b, stânci și plante:
  `schist_outcrop_a/b/c`, `scree_cone`, `jneapan_a/b`, `beech_tree_a/b`,
  `bujor_de_munte`, `afin`;
- `transfagarasan_inventory_c.md`, tf-c: `brown_bear`, animat (`Idle`,
  `Walk`, `Stand`).

`bash tools/blender/verify_transfagarasan.sh` dă **VERDICT KIT: OK** pe ramura
integrată. Golurile: Bâlea 14,85 × 7,40 m, stânca 15,40 × 7,60 m.

**Toate piesele au fost acceptate de coordonator pe comparații.** Abaterile
asumate (detaliile sunt în inventarele pe grupe):
- **zăpada portalului Bâlea** rămâne rev. 2, cu blocuri prea cubice. Rev. 3 și
  rev. 4 au fost respinse: au ieșit cioburi, apoi grindină. Verdictul final se
  dă pe captura din joc;
- **pe fața portalului de stâncă** blocurile ies ca plăci înclinate, nu ca
  poliedrele groase de pe planșă (3 runde din 3);
- **ursul ridicat** are trunchiul cilindric (h/l 1,96 față de ținta de 1,68).
  Se reverifică pe captura din joc;
- **`beech_tree_a`:** trunchiul gri-deschis citește subțire, iar coroana are
  un gol central. La integrare, trunchiul se întunecă din tentă;
- **zidurile de sprijin** au pietre mai regulate decât pe planșă.

**Lama de șist rămâne în două implementări, decizie de integrare.** E vorba de
`tf_shapes_nature.py` (tf-b: `foliation_stack`, `schist_slab`, folosite la
aflorimente) și de `transfagarasan_shapes.schist_blade` (tf-a, varianta
minimă din portalul de stâncă). Unificarea ar fi schimbat un GLB deja
acceptat, deci nu s-a făcut. Piesele noi de șist folosesc
`tf_shapes_nature.py`.

**De făcut la montarea în Track21** (coordonatorul, în `scripts/` / `scenes/`):
- **ursul:**
  - în `WALK_CYCLE_SPEED_BY_MODEL` din `sliding_hazard.gd` se adaugă
    `&"brown_bear": 0.97`, altfel labele patinează;
  - `sweep_speed` de pe `Hazarduri/Urs` coboară de la 1,8 spre ~1,2, pentru
    pasul greu;
  - `model_scale` 1,0 în locul vacii.
- **trecerea la nivel:** brațele se coboară rotind `Crossing_Boom_L/_R` cu
  −90° în jurul +Z (Godot).
- **tentele de clasă:**
  - `tf_schist` pe `*_Schist`, cu ținta `#7E8478`;
  - `*_Crack` rămâne pe atlas;
  - bujorul trece spre magenta `#B63A7A`;
  - coroana fagului pe `beech_canopy`, recalculată;
  - trunchiul fagului întunecat.

## Decizia coordonatorului (13 oct 2026): ACCEPTAT pe rev. 2

Piesa e **acceptată în starea rev. 2**: placa, gura teșită și golul
(14,85 × 7,40 m) sunt contractul înghețat. Zăpada are abateri cunoscute
(blocuri prea cutioare, movila pe două coloane, dungi ca bețișoare).
Runda 3 (`70abe521`) a făcut bulgări unghiulari pe potcoavă, dar a pierdut
masa: cioburi rare și subțiri, citite ca hârtie mototolită, nu ca munte de
zăpadă. S-a revenit la rev. 2 (`87dfc307`), adică la starea cel mai bine
judecată.

**Zăpada portalului se reface în valul 1**, de constructorul lui `snow_wall`,
după ce vocabularul de zăpadă al kitului e stabilit și acceptat. Punctul de
plecare e generatorul de bulgări din `70abe521`
(`git show 70abe521:tools/blender/transfagarasan_shapes.py`), cu două reguli:
- bulgări aproape izotropi (jitter mic, fără cioburi);
- densitate de masă continuă, cu suprapunere ≥ 30%.

În joc, laturile movilei stau oricum lipite de versantul din `TerrainPeak` și
de modulele `snow_wall` de pe urcarea D. Deci placa și gura, care sunt bune,
duc citirea.

## Stare la oprire (pilot, rev. 2, 13 oct 2026)

Facut: harnasul (shapes, preview `--compare/--views/--sheet`, compose, verify,
`measure_tf_gap.py` cu `--window`) si `structures/tunnel_portal_balea.glb` pe
**contractul nou** (placa masiva, gura teșita, zapada care invaluie; kit §1.1
actualizat in acelasi commit). Rev. 1 (arcada cu cornisa) a fost respinsa de
coordonator din vina contractului. Rev. 2: 2 runde din 3 folosite. Verdict KIT:
OK; acceptarea ramane a coordonatorului. Nimic altceva din kit nu e inceput.
Stub-uri pentru valul 1: `schist_blade`, `dry_stone_wall`, `tin_roof`. In
shapes raman `ring_stack`/`snow_layers` (peretele cu trepte, pentru `snow_wall`;
portalul nu le mai foloseste). Portalul foloseste `extrude_xz`, `tilt_front`,
`tube_lining`, `faceted_block`, `dust_patch`.

## structures/tunnel_portal_balea.glb

| nod | slot | tri |
|---|---|---:|
| `Portal_Concrete` | CONCRETE 8 | 36 |
| `Portal_Snow` | FOAM_WHITE 22 (≈ 28 blocuri convexe) | 780 |
| `Portal_Dust` | CONCRETE 8 (6 bucati) | 72 |
| `Portal_Void` | VOLCANIC_BLACK 20 (10 m, fara podea/capace) | 10 |
| total | `--origin=assembly`, scala/rotatia aplicate pe radacini | 898 |

Cote masurate: **48,4 x 17,6 x 13,2 m** (X x Y x Z-sus); placa 26,0 x 6,0 x 11,0 m.
Origine pe axa drumului, y = 0 la fata placii (baza), baza la 0. Fata doar pe +Y
(Blender; -Z Godot); a doua gura = acelasi GLB rotit 180. Zapada nu iese in fata
fetei placii la baza (max y = 0 sub 3 m; deasupra, buza calotei la -0,6 m).
Preview-ul pune un plan negru la y = -12, DOAR in randare.

### CONTRACT: golul (`measure_tf_gap.py --window=6.5`, proiectie pe plan, 5 cm)

| fereastra | portal nou | `mountain_tunnel` x(1,5; 1,25; 1,0), fara asfalt | contract |
|---|---|---|---|
| lateral, banda caroseriei 0-2 m | **14,85 m** (x -7,42..+7,43) | **11,95 m** (x -5,83..+6,12) | >= 13,0 |
| lateral la 1 m / 2 m (benzi 5 cm) | 14,90 / 14,90 m | 11,95 / 12,00 m | — |
| inaltime libera, fereastra \|x\| <= 6,5 (in gol) | **7,40 m** | **5,20 m** | >= 7,0 |
| inaltime libera minima pe tot golul | 6,50 m (stalpii, inainte de tesitura) | 5,20 m | — |

Noul gol e mai lat cu 2,9 m si mai inalt cu 2,2 m decat provizoriul, deci nu
e mai ingust. Captuseala `Portal_Void` strange golul cu 0,03 m pe parte si e in cifre.

### Fidelitate

Comparatia: `docs/asset_briefs/img/transfagarasan_fidelity/tunnel_portal_balea.png`
(decupare | randare din GLB, 3/4, culoare reala, `*_Concrete` pe #B8B4AA,
`*_Snow` pe #E8ECEE), 4 azimuturi: `tunnel_portal_balea_views.png`.
Intrebarea coordonatorului: „se citeste ca gura de tunel in munte de zapada?” —
**da, in linii mari** (gura neagra intr-o placa, inconjurata de zapada pe laturi
si deasupra); abaterile de forma sunt mai jos.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| placa | bloc gros, tan, latura ~1/4 din latime, fata usor inclinata | 26 x 11 x 6 m (6/26 = 0,23), fata inclinata 5°, muchii vii | OK ca masa; latura ei e ascunsa de movila din 3/4 (pe planșă se vede), culoarea e #B8B4AA din clasa, mai gri-bej decat tan-ul din desen |
| gura teșită | dreptunghi cu umeri teșiti, ~55-58% din latime, interior intunecat | 15 m (58%), stalpi 6,5 m, tesituri 45° de 2 m, buiandrug 8,5 m, interior negru 10 m | OK |
| movila pe laturi | 5-6 blocuri mari, fatetate, inalte, infasoara portalul in arc | 10 blocuri/parte (8 pe lateral + 2 interioare), 9,6 m langa placa -> ~4 m la 11 m, fatetate prin hull | abatere: arata ca o scara de cuburi mari, mai joasa si mai alungita decat desenul; nu infasoara pe curba (stau pe 2 coloane drepte) |
| calota deasupra | zapada peste si in spatele placii, urca spre fundal | 4 randuri x 4-5 blocuri neregulate, de la 10,3 m pana la ~13,2 m, la ~10 m in spate; buza peste placa | OK ca idee; blocurile par mai mici/mai plate decat masa continua din desen |
| dungi de praf | pete inchise inegale pe blocurile de jos | 3 bucati/parte, scurte, inclinate (-19..+14°) | abatere: citesc ca betisoare tan; prea contrastante si prea subtiri pentru o patare |
| asfalt/marcaje | pe decupare | exclus | OK |
| text | — | fara | OK |

Runde: 1 (blocuri in grila regulata pe calota) -> 2 (calota neregulata, praf
adus la fata, buza calotei trasa inapoi).
