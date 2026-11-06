# Angkor, val 3, grupul A: `angkor_wat_temple`

Fișier: `assets/models/angkor/structures/angkor_wat_temple.glb` (nodurile `Temple_Stone`, `Temple_Lichen`,
`Temple_Streak`). Script: `tools/blender/build_angkor_temple.py` (vocabularul din
`build_angkor_gates_w.py` e executat cu `ANK_ONLY=none`, nu copiat: `bx`, `wall_faces`, `column`,
`round_tier`/`lotus_tower`, `gable`, `scatter_lichen`). Gardă: `tools/blender/measure_angkor_w3a.py`
(cu `--selftest`), în `verify_angkor.sh`, blocul „val 3, grupul A".

## Orientare
Originea e în centrul soclului, talpa la z = 0. **Scara axială și porticul de intrare sunt pe +Y în
Blender** (fața bogată; −Z în Godot). Coordonatorul îl rotește ca fața să privească spre vest/start.
Pe celelalte trei laturi stau doar porticuri cu fronton (fără scară).

## Cotele (măsurate pe GLB, coordonate Godot)
| element | cerut | măsurat |
|---|---|---|
| amprentă | ≤ 64,5 × 64,5 | 64,12 × 64,12 |
| vârf central | 36 ± 0,5, în 1 m de (0,0) | 36,016, abatere 0,03 m |
| vârfuri de colț | 30 ± 0,5, în 1 m de (±17,±17) | 30,015 ×4, abatere 0,03 m |

Soclul de jos: trei lespezi (jumătăți 32 / 31,2 / 30,4, până la z = 3). Terasa a doua: 44 × 44 în trei trepte
(23,6 / 22,8 / 22) până la **+8**. Platforma centrală până la +14. Galerii în inel: jos (jumătăți 24,6–30) și
sus (15,5–21), cu zid cu blocuri, colonadă, arhitravă, acoperiș pantat (hull convex) cu nervuri rare și
antefixe; porticuri cu fronton ascuțit; pavilioane de colț; două scări intermediare și scara de jos.

## Turnurile (fără fețe)
Bază pătrată cu blocuri, apoi etaje **rotunde bombate** (`round_tier`), cu mici frontonașe ascuțite pe
cele patru axe ale primelor trei etaje, boboc de lotus cu finial. Central: 6 etaje (r 6,3 → 3,0), bază 12,4 m.
Colț: 5 etaje (r 4,2 → 2,2), bază 7,6 m, ridicate din pavilioane de 7,8 × 7,8 m.

## Costuri
~51.200 triunghiuri (Stone 46.386, Lichen 3.664, Streak 1.152), 3 noduri, 3 materiale-slot (gresie 3,
lichen 30/12, dare 20), 4,0 MB. Sub ținta de 60k. **LOD-urile nu sunt făcute aici** (nu am rulat Godot;
importul le generează din mesh; cerut de coordonator la integrare). Coliziune doar pe soclu: o face coordonatorul.

## Imagini
`docs/asset_briefs/img/angkor_fidelity/`: `angkor_wat_temple.png` (comparație), `_views.png`,
`_gamecam_240.png` (de la 240 m, cum se vede de pe grilă), `_gamecam_100.png`.

## Citire onestă (nu acceptare)
- Siluetă: turnuri rotunde, bombate, în quincunx; după decupare nu citește ca Maya (fără trepte plate la
  turnuri). Mai slab decât decuparea: bobocul e mai neted (fără rânduri de petale pe etaje), culorile lipsesc
  (previzualizarea e monocromă pe slotul gresiei).
- Scara de jos citește slab din camera de joc joasă (trepte mici, în umbra galeriei).
- Acoperișurile galeriilor sunt lungi și plate ca niște șoproane; frontoanele sunt mici față de decupare.
- **La 240 m / înălțime 10 m / fov 68, vârful turnului central ajunge la marginea de sus a cadrului și
  finialul e tăiat** (36 m la 240 m e ~6° peste orizont, marginea cadrului e la ~6°). Pe axă se văd trei turnuri
  distincte; cele două din spate sunt acoperite parțial de cele din față (quincunx văzut pe axă). Lățimea e mică
  (la 240 m ocupă ~13% din cadru).
- `--gamecam` din `preview_angkor.py` nu aplică `gc_yaw` pe obiectele importate din GLB (rotation_mode
  quaternion): intrarea `gc_yaw: 180` din SPECS nu are efect; imaginile `_gamecam_*` au fost randate cu un
  script de scratch care pune `rotation_mode = "XYZ"`. Nu am modificat codul `preview_angkor.py` (doar SPECS).
