# Brief asset — Bolovan rostogolitor (`boulder_roller.glb`)

Brief auto-conținut pentru un agent Blender (ex. Blender MCP). Nu presupune
acces la restul repo-ului — tot contractul e aici. Sursele din care e derivat:
[style_bible.md](../style_bible.md) (estetică) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

Referință vizuală: `assets/dunele_inspiration/sheet_wave1_props.png`, panoul
**BOULDERS & ROCKS** — folosește silueta bolovanilor mari din rândul de sus.
Cote: `sheet_scale_rocks_cactus_barrels.png`, rândul **LARGE (6-10m)**, dar la
scara cerută mai jos.

> **Prompt de dat agentului** — de la linia orizontală de mai jos în jos e
> paste-ready. Restul paginii sunt note pentru noi.

---

Construiește un bolovan care se rostogolește peste șosea ca obstacol mobil,
low-poly, stilizat, pentru un joc de curse cu mașinuțe de jucărie în stil
diorámă de deșert (ton *Art of Rally* — machetă de masă, NU foto-realist).
Rezultat: un `.glb` care intră într-o lume cu un singur material partajat.

## ⚠️ Originea e în CENTRU, nu la bază

Ăsta e **singurul asset din tot proiectul** cu originea în centrul geometriei.
E intenționat: motorul îl rotește pe loc în timp ce îl translatează, iar o
origine la bază l-ar face să sară în loc să se rostogolească.

Bbox pe Y de la **−2.5 la +2.5**. Nu-l așeza pe sol.

**Formă și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4.2 m):
- **Diametru ~5.0 m** pe toate axele (motorul îl scalează ulterior la 2.6 m în
  joc). Abaterile între axe: maximum ±5%, altfel rostogolirea pare că se
  poticnește.
- Un singur obiect, numit **`Boulder`**.
- Formă de bolovan, **nu sferă**: fațete mari și neregulate, 8–10 laturi pe
  orizontală, 5–6 inele pe verticală.
- **Fără concavități.** Nicio adâncitură, nicio scobitură. O suprafață convexă e
  ce face rostogolirea lizibilă.
- **2–3 fețe plane mai mari**, ca la un bolovan proaspăt desprins dintr-un
  perete de stâncă. Astea sunt tot ce trebuie ca să pară rupt, nu erodat.
- Câteva pietricele NU se adaugă — obiectul se mișcă, orice satelit ar pluti.

NU: crăpături modelate, mușchi, stratificare fină, forme de fasole cu talie.

**Culoare — FĂRĂ texturi proprii. UV → sloturi dintr-un atlas de paletă** (32
sloturi orizontale). Fiecare față își colapsează toate UV-urile pe **un singur
punct**, centrul slotului:
- Corp de stâncă (majoritatea fețelor): **u = 0.140625, v = 0.5**
- Fețele proaspăt sparte (cele 2–3 plane): **u = 0.109375, v = 0.5**
- Nu e nevoie să încarci vreo imagine în Blender; contează doar coordonata UV.
  Materialul se înlocuiește ulterior.

Contrastul dintre cele două spune „s-a desprins acum din perete", ceea ce leagă
obstacolul de falezele de deasupra drumului.

**Vertex colors = ambient occlusion copt (grayscale), se înmulțește peste
culoare în engine:**
- **Gradient RADIAL, nu vertical.** Obiectul se rotește, deci un gradient
  vertical s-ar învârti cu el și ar arăta greșit. Întunecă spre interiorul
  concavităților dintre fațete, lasă crestele spre 1.0.
- 1.0 = neatins, ~0.5 = adânc/umbrit. Fără el iese plat — e obligatoriu.

**Scară, origine, orientare:**
- Originea (pivotul) **în centrul geometriei**, nu la bază. Vezi avertismentul
  de sus.
- Fără orientare preferată — obiectul se rotește continuu.
- Bevel **0.10 m** — generos, ca fațetele să se citească rotunjite.
- Buget: **≤ 220 triunghiuri.** O singură instanță pe pistă, deci e larg.

**Export:**
- glTF Binary **(.glb)**, un fișier, nume `boulder_roller.glb`, un obiect
  `Boulder`.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere, lumini sau
  materiale complexe.
- **Apply Modifiers: ON** (bevel-ul să fie în geometrie). Y-up: implicit.

---

## Note pentru noi (nu fac parte din prompt)

- **Ce înlocuiește:** `beach_ball.glb` — o minge de plajă care se rostogolește
  peste șosea în canionul de deșert. Rămășiță din tema abandonată „jucării în
  ladă de nisip"; comentariul din `scenes/tracks/track.gd:896` o spune pe față.
- **Verificatorul va da eroare, și e corect.** `verify_glb.py` testează „baza la
  Y=0"; asset-ul ăsta e centrat pe origine intenționat. Abaterea se notează în
  PR cu referire la `scenes/hazards/sliding_hazard.gd:106-107`
  (`_pivot.position = Vector3.UP * roll_radius`). Restul verificărilor (UV,
  `COLOR_0`, buget) trebuie să treacă curat.
- **Nu-l face să semene cu `Cluster_L1`** din `rock_cluster.glb` — ăla e
  bolovanul static din decor *și* cel care cade în `RockfallHazard`. Ăsta trebuie
  să se distingă în mișcare.
- **Diametrul e contract.** Godot are `model_scale = 0.52` și `roll_radius = 1.3`
  derivate din cei 5.0 m (`track.gd:902-903`). Alt diametru → două numere de
  schimbat în cod.
- **Sloturi folosite:** `rock_dark` = 4 (u = 0.140625), `rock_light` = 3
  (u = 0.109375).
- **Fișier nou. NU se atinge `beach_ball.glb`.**
- **Checklist la primire:** un nod `Boulder`; ≤ 220 tris; UV pe centre de slot;
  bbox Y de la −2.5 la +2.5; `COLOR_0` prezent.
