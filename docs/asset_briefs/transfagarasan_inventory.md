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
