# Inventar — kitul Transfăgărășan, val 2, tf-e (clădirile)

Contract: `docs/asset_briefs/transfagarasan_kit.md` §1.3 (cabana are contract
revizuit după etapa 1). Build: `tools/blender/build_tf_buildings.py`.
Preview și măsurători: `tools/blender/preview_tf_e.py` (`--compare`,
`--views`, `--facade`). Verdict: `bash tools/blender/verify_transfagarasan.sh`
→ `VERDICT KIT: OK` (secțiunea „val 2, tf-e”).

Cotele sunt MĂSURATE pe GLB (`verify_glb.py --origin=assembly`, Godot Y-up;
Blender +Y = Godot −Z). Fața bogată e măsurată cu `preview_tf_e.py --facade`:
aria golurilor `*_Void` pe direcție și cât iese geometria peste corp.

**Golurile sunt reale.** Corpul plin e tăiat boolean pe 0,22 m. Fundul golului
e placa `*_Void`, așezată 2 mm în fața fundului tăiat, deci la **0,218 m** de
fața peretelui. Rama iese 5 cm în față și stă la 2 mm de perete.

**Tabla argintie e pe `ASPHALT_EDGE` 6** (`#696765`). E decizia
coordonatorului din valul 2: `PAINTED_METAL` 11 ieșea albastru. Tabla roșie
rămâne pe `KERB_RED` 7, iar cea ruginie pe `RUST_METAL` 10.

## Vocabular nou în `transfagarasan_shapes.py`

`tin_roof` nu mai e stub. Acoperiș de tablă cu fălțuiri:
- ape plane groase de 0,12 m, al căror cant se vede ca streașină;
- nervuri de 4,5 × 3,5 cm la 0,5 m, pe pantă, de la streașină la coamă (la
  `hip`, până la muchie);
- capac pe coamă și pe muchiile de hip;
- `kind="gable"` (două ape) sau `"hip"` (patru ape, coama de 2·(hx−hy));
- coama pe X sau pe Y;
- întoarce cotele fețelor de sus și de jos ale tablei, pe care se opresc
  pereții și frontoanele.

**Piese comune în `build_tf_buildings.py`:**
- `Openings`: goluri prin boolean, cu placa neagră și ramele;
- `stone_base`, `wood_bands`, `barge_boards`, `dormer`, `chimney`;
- `terrace`, cu `railing_boards` (balustradă din scânduri drepte).

## buildings/cabana_balea_lac.glb (contract revizuit, rev. 2)

| nod | slot | tri |
|---|---|---:|
| `Cabana_Stone` | MARBLE_GREY 29 (parter, pietre de colț, coș) | 508 |
| `Cabana_Wood` | WOOD_WEATHERED 9 (pereți, terasă, scară, borduri) + LOG_DARK 28 (brâuri, stâlpi de colț, rame, montanți) | 4 636 |
| `Cabana_Roof` | ASPHALT_EDGE 6 (acoperiș + 2 lucarne, falțuri) | 1 068 |
| `Cabana_Void` | VOLCANIC_BLACK 20 (43 de goluri, gura coșului, tubul de aerisire) | 556 |
| total | `--origin=assembly`, scala/rotația aplicate pe rădăcini | **6 768** |

| cotă | contract revizuit | GLB |
|---|---|---|
| amprenta (lemnul) | 13 × 10 m | 13,0 × 10,0 m (piatra 12,7 × 9,7 m + 3 cm pietre de colț) |
| parterul de piatră | 3 m | 3,0 m |
| nivelurile de lemn | 2 × 2,7 m, peretele lung ~8,4 m | 3,0 → 5,7 → 8,4 m; streașina (muchia) la 7,99 m |
| panta | ~45–48° | 45° |
| coama | ~13 m | **13,67 m** (capacul); tabla 13,59 m. Abatere +5%: peretele de 8,4 m plus semideschiderea de 5 m la 45° dau +5 m, deci cele două cote nu încap amândouă. Am păstrat cele două niveluri întregi |
| coșul | — | 15,0 m (1,3 m peste coamă) |
| bbox | — | 14,20 (X) × 16,43 (Y) × 15,02 m; Y de la −5,71 la +10,73 (piciorul scării) |

**Fața bogată, măsurată pe GLB (`--facade`):** **+Y în Blender = −Z în Godot**.
| direcție | goluri | ce iese peste corp |
|---|---:|---|
| **+Y** | **13,17 m²** (14 goluri) | **terasa + scara: 5,85 m** |
| −Y | 7,90 m² | 0,83 m (streașina) |
| +X (frontonul din decupare) | 7,14 m² (11 goluri) | 0,72 m (streașina) |
| −X | 4,49 m² | 0,72 m (streașina) |

**Imaginile:**
- comparația, cu camera la azimut 32° și elevație 22°:
  `docs/asset_briefs/img/transfagarasan_fidelity/cabana_balea_lac.png`;
- cele 4 azimuturi: `cabana_balea_lac_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| proporția | casă compactă, înaltă | 13 × 10 m, două niveluri întregi de lemn peste piatră | OK după contractul revizuit. Rev. 1 era o șură lungă și joasă |
| parter de piatră | gri, piatră brută | 3 m, 4 pietre de colț pe muchie | culoarea (aproape albă în preview) rămâne pe seama tentei `stone_wall` la integrare (verdictul coordonatorului) |
| lemnul | portocaliu | WOOD_WEATHERED, brâuri LOG_DARK la 3,0, 5,7 și 8,4 m, stâlpi de colț | mai rece decât desenul; rămâne pe tentă (verdictul coordonatorului) |
| acoperiș | abrupt, gri | 45°, ASPHALT_EDGE gri neutru, falțuri la 0,5 m, capac pe coamă, borduri de lemn | OK |
| lucarne | 1 | 2 (contractul), 2,4 m late | după contract |
| coș | cărămiziu | de piatră (contractul) | după contract |
| fronton +X | trei rânduri de ferestre + aerisire | 3 + 4 + 3 + aerisire (0,4 × 0,7 m) | OK |
| latura +Y | ferestre pe etaj, terasă, scară | parter 1 fereastră + ușă; nivelul 1: 4 ferestre + ușa spre terasă; nivelul 2: 5 ferestre | OK |
| terasă | simplă, la etaj | 5,2 × 2,4 m, la +3 m, balustradă din scânduri drepte pe 3 laturi | OK |
| scară | coboară spre privitor | 11 trepte, perpendiculară pe perete, spre +Y | OK |
| verandă de jos cu acoperiș propriu | da | lipsește | voit: corectura „cel mult o terasă simplă” |

**Rundele.** Rev. 1 a avut 3 runde (acceptată ca direcție de coordonator).
Rev. 2, pe contractul revizuit, a ieșit din prima rundă.

## Stare la oprire

Completată la finalul valului: vezi secțiunile pieselor de mai jos.
