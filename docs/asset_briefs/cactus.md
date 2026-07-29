# Brief asset — Cactuși saguaro ("cactus", `cactus.glb`)

Brief auto-conținut pentru un agent Blender (Blender MCP). Nu presupune acces la
restul repo-ului — tot contractul e aici. Surse din care e derivat:
[style_bible.md](../style_bible.md) (estetică) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

> **Prompt de dat agentului** — de la linia orizontală în jos e paste-ready.
> Restul paginii sunt note pentru noi.

---

Construiește **2–3 variante de cactus saguaro** low-poly și stilizate (obiecte
separate în același `.glb`), pentru un joc de curse cu mașinuțe de jucărie în
stil **diorámă de deșert** (ton *Art of Rally* — machetă de masă, NU
foto-realist). Rezultat: un `.glb` cu **un singur material partajat**. Prop de
umplutură (filler), dar cu siluetă supradimensionată — vinde scara de machetă.

**Formă și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4 m):
- **Înălțime**: **2.8 – 4.5 m** (variază per exemplar). Supradimensionat
  intenționat față de mașină (style_bible §2).
- **Trunchi**: coloană de revoluție, **8 laturi**, rază ~0.26 m, cu un ușor bulge
  la mijloc și **vârf rotunjit** (dom, nu con ascuțit). Coaste verticale subtile
  opționale (doar dacă rămân groase — altfel omite-le).
- **Brațe**: **0, 1 sau 2** per exemplar (variație de siluetă). Fiecare braț =
  un cot orizontal scurt care iese din trunchi + o coloană verticală cu capăt
  rotunjit (forma clasică de saguaro cartoon). Rază ~0.15 m, 6 laturi.
- Bevel **consistent 0.04 m** (prop).

**Culoare — FĂRĂ texturi proprii. UV → sloturi dintr-un atlas de paletă** (32
sloturi orizontale). Toate fețele își colapsează UV-urile pe **un singur punct**,
centrul slotului (v = 0.5 mereu):
- **Verde de cactus** (tot corpul) → u = **0.390625**
- Nu încărca nicio imagine în Blender; contează doar coordonata UV.

**Vertex colors = ambient occlusion copt (grayscale), se înmulțește peste
culoare:**
- **Jumătatea de jos net mai închisă** (style_bible §4 — vegetație): jos ~0.5,
  sus spre 0.95, cu tranziție mai agresivă în treimea de jos.
- Întunecă unde brațele se prind de trunchi (interiorul cotului).
- 1.0 = neatins, ~0.5 = adânc. Obligatoriu — fără el iese plat.

**Scară, origine, orientare:**
- Originea fiecărui cactus la **bază, centrată în XZ**, ca să stea pe sol la Y=0.
- Buget: **≤ 180 triunghiuri per cactus**. Zero detaliu de frecvență înaltă
  (spini, coaste fine) — se pierd la viteză și costă.

**Export:**
- glTF Binary **(.glb)**, un fișier, nume `cactus.glb`, cu 2–3 obiecte-cactus
  separate (le instanțiem individual).
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere/lumini/materiale
  complexe.
- **Apply Modifiers: ON** (bevel în geometrie). Y-up: implicit.

---

## Note pentru noi (nu fac parte din prompt)

- **Există deja o variantă GDScript** — [scenes/props/cactus.gd](../../scenes/props/cactus.gd)
  (`@tool class_name Cactus`, revoluție + brațe, UV → CACTUS_GREEN, AO în vertex
  colors, ~200 tris, parametric prin `height`/`arms`/`variant`). E filler
  zero-dependențe, validabil headless — [blender_export.md](../blender_export.md)
  recomandă explicit GDScript pentru cactus. **Dacă modelăm cactusul în Blender
  (pentru sursă `.blend` commit-uită + coerență cu restul), ștergem `cactus.gd`.**
  Altfel îl păstrăm ca fallback. Nu ținem ambele active în lume.
- **Sloturi folosite:** cactus_green=12 (u=0.390625). u = (slot+0.5)/32.
- **Commit sursa `.blend` + `.glb`** — nu doar exportul.
- **Checklist la primire** (`res://assets/models/cactus.glb`):
  1. ≤ 180 triunghiuri per cactus
  2. UV pe centrul slotului cactus_green (0.390625)
  3. origine la bază, XZ centrat; stă pe sol la Y=0
  4. AO în vertex colors, jumătatea de jos mai închisă
  5. instanțiere cu `Palette.apply_world_material(glb)` → un singur material
