# Inventar — kitul Transfagarasan (Track21)

Contract: `docs/asset_briefs/transfagarasan_kit.md`. Cote MASURATE din GLB
(`verify_glb.py`, `measure_tf_gap.py`; Godot Y-up, Blender +Y = Godot -Z).
Build: `tools/blender/build_tf_road.py` (vocabular: `transfagarasan_shapes.py`).
Verdict: `bash tools/blender/verify_transfagarasan.sh` -> `VERDICT KIT: OK`.

## Stare la oprire (pilot, rev. 2, 13 oct 2026)

Facut: harnasul (shapes, preview `--compare/--views/--sheet`, compose, verify,
`measure_tf_gap.py` cu `--window`) si `structures/tunnel_portal_balea.glb` pe
**contractul nou** (placa masiva, gura teșita, zapada care invaluie; kit §1.1
actualizat in acelasi commit). Rev. 1 (arcada cu cornisa) a fost respinsa de
coordonator din vina contractului. Rev. 2: 3 din 3 runde folosite (runda 3 = doar zapada, pe verdictul coordonatorului). Verdict KIT:
OK; acceptarea ramane a coordonatorului. Nimic altceva din kit nu e inceput.
Stub-uri pentru valul 1: `schist_blade`, `dry_stone_wall`, `tin_roof`. In
shapes raman `ring_stack`/`snow_layers` (peretele cu trepte, pentru `snow_wall`;
portalul nu le mai foloseste). Portalul foloseste `extrude_xz`, `tilt_front`,
`tube_lining`, `faceted_block`, `dust_patch`.

## structures/tunnel_portal_balea.glb

| nod | slot | tri |
|---|---|---:|
| `Portal_Concrete` | CONCRETE 8 | 36 |
| `Portal_Snow` | FOAM_WHITE 22 (bulgari = convex hull pe elipsoid jitterat, rotit) | 1896 |
| `Portal_Dust` | CONCRETE 8 (10 FETE mutate din zapada, 5 pe parte; nu volume) | 10 |
| `Portal_Void` | VOLCANIC_BLACK 20 (10 m, fara podea/capace) | 10 |
| total | `--origin=assembly`, scala/rotatia aplicate pe radacini | 1952 |

Cote masurate: **47,3 x 20,5 x 14,1 m** (X x Y x Z-sus; Y peste ~17 din contract: potcoava si calota merg pana la ~-19 m); placa 26,0 x 6,0 x 11,0 m.
Origine pe axa drumului, y = 0 la fata placii (baza), baza la 0. Fata doar pe +Y
(Blender; -Z Godot); a doua gura = acelasi GLB rotit 180. Nicio zapada la y > -2,5 (placa iese 2,5 m din ea; garda in build); |x| >= 13 la sol in fata placii.
Preview-ul pune un plan negru la y = -12, DOAR in randare.

### CONTRACT: golul (`measure_tf_gap.py --window=6.5`, proiectie pe plan, 5 cm)

| fereastra | portal nou | `mountain_tunnel` x(1,5; 1,25; 1,0), fara asfalt | contract |
|---|---|---|---|
| lateral, banda caroseriei 0-2 m | **14,85 m** (x -7,42..+7,45) | **11,95 m** (x -5,83..+6,12) | >= 13,0 |
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
**da, in linii mari (gura neagra intr-o placa groasa, zapada pe laturi si deasupra), dar mound-ul e mai rar decat pe planșă** (gura neagra intr-o placa, inconjurata de zapada pe laturi
si deasupra); abaterile de forma sunt mai jos.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| placa | bloc gros, tan, latura ~1/4 din latime, fata usor inclinata | 26 x 11 x 6 m (6/26 = 0,23), fata inclinata 5°, muchii vii | OK ca masa; latura ei e ascunsa de movila din 3/4 (pe planșă se vede), culoarea e #B8B4AA din clasa, mai gri-bej decat tan-ul din desen |
| gura teșită | dreptunghi cu umeri teșiti, ~55-58% din latime, interior intunecat | 15 m (58%), stalpi 6,5 m, tesituri 45° de 2 m, buiandrug 8,5 m, interior negru 10 m | OK |
| movila pe laturi | potcoava de blocuri unghiulare, 9-10 m langa placa, ~4 m la capete, infasoara placa | 2 inele pe un arc de elipsa (a 16/20 m, b 10,5/13,6 m, centru y = -8), 7 pozitii pe parte, stivuite pe 1-4 niveluri, + 3 gramezi interioare; bulgari de 5-6 m cu fete plane in toate directiile | FORMA OK (nu mai sunt cutii), MASA abatere: potcoava iese rara si mai joasa decat desenul (varful de 9-10 m abia se atinge langa placa), cu goluri intre bulgari; arcul se inchide mai putin decat pe planșă |
| calota deasupra | zapada peste si in spatele placii | 3 randuri x 7 bulgari de 7-8 m, de la ~10 m la ~13 m, la ~10 m in spate | OK ca masa; marginile ies ca niste pietre, nu o panza continua |
| praful | pete inchise pe fete | 5 fete pe parte mutate pe `Portal_Dust` (fara volume noi) | OK ca mecanism; la scara de joc se citeste putin (fete mici, 1-3 m2) |
| asfalt/marcaje | pe decupare | exclus | OK |
| text | — | fara | OK |

Runde: 1 (cutii in coloane) -> 2 (calota neregulata) -> 3 (bulgari pe elipsoid,
potcoava, praf pe fete). Abaterile de masa de mai sus raman asa.
