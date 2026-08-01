# Brief asset — Secțiuni de faleză ("cliff_wall", `cliff_wall.glb`)

Brief auto-conținut pentru un agent Blender (Blender MCP). Nu presupune acces la
restul repo-ului — tot contractul e aici. Surse din care e derivat:
[style_bible.md](../style_bible.md) (estetică) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

> **Prompt de dat agentului** — de la linia orizontală în jos e paste-ready.
> Restul paginii sunt note pentru noi.

---

Construiește **6 secțiuni modulare de perete de canion**, low-poly și stilizate
(obiecte separate în același `.glb`), pentru un joc de curse cu mașinuțe de jucărie
în stil **diorámă de deșert** (ton *Art of Rally* — machetă de masă, NU
foto-realist). Rezultat: un `.glb` cu **un singur material partajat**.

Secțiunile se așază **cap la cap** pe marginea unei șosele, la pas de 14 m, ca să
formeze un perete continuu de canion.

**Formă și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4 m):
- **Lățime: exact 15.0 m** pe X. Pasul de așezare e 14 m, deci secțiunile se
  suprapun 1 m — fără suprapunere rămân fisuri vizibile.
- **Înălțimi**, câte una per variantă: **6.5 / 8.0 / 9.5 / 11.0 / 7.5 / 10.0 m**.
- Adâncime pe Y: 5–7.5 m, proporțional cu înălțimea.
- **Fața dinspre drum (−Y) aproape verticală** (75–85°). Spatele cade în trepte.
- **Vârf plat** — siluetă de mesa, nu vârf ascuțit. Asta e semnătura peisajului.
- **Straturi orizontale** la 0.4–0.8 m (rocă sedimentară), 70% rotunjit / 30%
  fațetat, **niciodată colțuros sau zimțat**.
- **Capetele pe X plate, cu profil identic** între variante, ca să se lipească
  fără fisuri.
- Bevel **0.15 m** (stâncă).

**Al doilea obiect per variantă: cutia de coliziune.**
Fiecare `Cliff_X` are perechea `Cliff_X_col` — o cutie simplă (12 triunghiuri)
care acoperă doar **fața dinspre drum**, puțin mai lată pe X decât mesh-ul vizual
(ca să se suprapună cu vecinele) și mai îngustă pe Y. Motivul: un convex hull din
mesh-ul vizual creează colțuri între secțiuni vecine, în care mașinile se
înțepenesc.

**Culoare — FĂRĂ texturi proprii. UV → sloturi dintr-un atlas de paletă** (32
sloturi orizontale). Toate fețele își colapsează UV-urile pe **un singur punct**,
centrul slotului (v = 0.5 mereu):
- **Corp de stâncă** → u = **0.109375** (rock_light)
- **Bază și crăpături** → u = **0.140625** (rock_dark)
- **Coama de sus** → u = **0.015625** (sand_light)
- Nu încărca nicio imagine în Blender; contează doar coordonata UV.

**Vertex colors = ambient occlusion copt (grayscale), se înmulțește peste
culoare:**
- **AO agresiv la bază** (~0.30), urcând spre 1.0 la vârf. În joc falezele **nu au
  umbre dinamice** (buget mobil), deci tot volumul vine de aici — fără AO puternic
  arată ca un decal plat lipit lângă drum.
- Obligatoriu; fără el iese plat.

**Scară, origine, orientare:**
- Originea fiecărei secțiuni la **bază, centrată în XZ**.
- Fața dinspre drum la **Y = 0 sau negativ** (Godot o rotește spre șosea).
- Buget: **≤ 200 triunghiuri per secțiune vizuală** (cutia de coliziune nu intră
  la socoteală).

**Export:**
- glTF Binary **(.glb)**, un fișier, nume `cliff_wall.glb`, cu 12 obiecte:
  `Cliff_A..F` + `Cliff_A_col..F_col`.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere/lumini.
- **Apply Modifiers: ON**. Y-up: implicit.

---

## Note pentru noi (nu fac parte din prompt)

- **Sloturi:** rock_light=3 (u=0.109375), rock_dark=4 (u=0.140625),
  sand_light=0 (u=0.015625). u = (slot+0.5)/32.
- **Generat de** [tools/blender/build_cliff_wall.py](../../tools/blender/build_cliff_wall.py),
  cu helper-ul `Builder.rock(..., taper, wall_axis)` din `dio_lib.py`.
- **Capcana de formă, întâlnită la prima generare:** un elipsoid cu `taper` mare
  produce o **movilă conică**, nu un perete. Pentru faleze trebuie `taper ≈ 0.16`
  plus `wall_axis="y"`, care ține fața dinspre drum verticală și lasă doar spatele
  să se retragă.
- **Capcana de buget:** bevel-ul de 0.15 adaugă geometrie la fiecare muchie. Prima
  versiune (7 laturi, 5 straturi, plus o „poală" separată la bază) ieșea 310
  tris/secțiune. La 6 laturi și 4 straturi, fără poală, iese ~185. Poala ascundea
  linia de contact cu nisipul — o rezolvă gratis AO-ul de teren din
  `_build_terrain`.
- **Checklist la primire** (`res://assets/models/cliff_wall.glb`):
  1. ≤ 200 triunghiuri per secțiune vizuală
  2. cele 6 perechi `Cliff_X` + `Cliff_X_col` prezente, cu numele exacte
  3. lățime 15 m pe X, capete cu profil identic
  4. origine la bază, XZ centrat
  5. AO în vertex colors, bază ~0.30
  6. instanțiere cu `Palette.apply_world_material(glb)` → un singur material
