# Brief asset — Conductă spartă (`pipe_leak.glb`)

Brief auto-conținut pentru un agent Blender (ex. Blender MCP). Nu presupune
acces la restul repo-ului — tot contractul e aici. Sursele din care e derivat:
[style_bible.md](../style_bible.md) (estetică) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

Referință vizuală: `assets/dunele_inspiration/sheet_wave1_props.png`, banda
**BROKEN PIPE VARIANTS** (mijloc, pe toată lățimea). Foaia are 7 variante; cerem
3 din ele.

> **Prompt de dat agentului** — de la linia orizontală de mai jos în jos e
> paste-ready. Restul paginii sunt note pentru noi.

---

Construiește **trei variante** de conductă industrială spartă, low-poly,
stilizate, pentru un joc de curse cu mașinuțe de jucărie în stil diorámă de
deșert (ton *Art of Rally* — machetă de masă, NU foto-realist). Rezultat: un
`.glb` cu trei obiecte, care intră într-o lume cu un singur material partajat.

## ⚠️ Orientarea duzei e contract

> ### Gura din care iese apa se orientează spre **+Y în Blender**.

Motorul rotește modelul presupunând că gura arată într-o direcție anume. Reține
conversia glTF: Blender **+Y** devine Godot **−Z**, iar codul cere „duza spre
−Z". Deci în Blender construiești gura spre **+Y**.

**Formă și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4.2 m):

Trei obiecte în același fișier, cu numele **exacte**:

### `Pipe_Broken` — piesa principală, ≤ 300 triunghiuri

Conductă orizontală ruptă, care scuipă spre drum.
- **Corp**: tub cu **8 laturi**, rază exterioară **0.55 m**, lungime **3.6 m**.
- **Gura ruptă** la capătul dinspre +Y: capătul e **deschis** (nu-l capaci), cu
  marginea tăiată oblic și **neregulată** — 3–4 vârfuri deplasate cu ±0.12 m, ca
  o ruptură. Modelează un **inel interior** cu rază 0.44 m pe adâncime 0.35 m, ca
  să se vadă grosimea peretelui. Ăsta e detaliul care face țeava să pară țeavă și
  nu buștean.
- **Două coliere** (inele) la 1.0 m și 2.4 m: rază exterioară 0.66 m, lățime
  0.12 m. Dacă ai ajutorul `torus()`, folosește-l cu 8 segmente majore și 5
  minore; altfel un prismatic inelar.
- **Suport de beton** sub conductă, la 2.6 m: 1.0×0.8×0.6 m, cu conducta așezată
  într-o șa.
- **Pietre desprinse** la gură: 3 forme mici de 0.2–0.35 m, întrepătrunse cu
  solul.
- Nu modela apa. Jetul se face cu particule în motor.

### `Pipe_Elbow` — cot, ≤ 160 triunghiuri

Segment cotit la 90°, ca al doilea din foaie. Rază 0.5 m, brațe de 1.4 m fiecare,
cu un colier la îmbinare. Ambele capete deschise.

### `Pipe_Segment` — segment drept intact, ≤ 100 triunghiuri

Tub simplu de 2.2 m, rază 0.5 m, un colier la mijloc, capete deschise. Se
împrăștie prin decor ca material de șantier.

NU: filete, robinete cu roată de manevră, șuruburi de flanșă, țevi subțiri
ramificate, text pe conductă.

**Culoare — FĂRĂ texturi proprii. UV → sloturi dintr-un atlas de paletă** (32
sloturi orizontale). Fiecare față își colapsează toate UV-urile pe **un singur
punct**, centrul slotului:
- Metal ruginit (corpul conductei, colierele): **u = 0.328125, v = 0.5**
- Interiorul țevii și gura ruptă: **u = 0.078125, v = 0.5**
- Suport de beton: **u = 0.265625, v = 0.5**
- Pietrele desprinse: **u = 0.140625, v = 0.5**
- Nu e nevoie să încarci vreo imagine în Blender; contează doar coordonata UV.
  Materialul se înlocuiește ulterior.

**Vertex colors = ambient occlusion copt (grayscale), se înmulțește peste
culoare în engine:**
- Gradient vertical: jos mai închis (~0.55), sus spre 1.0.
- Întunecă **puternic în interiorul țevii** — adâncimea gurii e principalul efect
  vizual al obiectului. Coboară spre 0.35 acolo.
- Întunecă și sub conductă, la contactul cu suportul, în jurul colierelor.
- 1.0 = neatins, ~0.5 = adânc/umbrit. Fără el iese plat — e obligatoriu.

**Scară, origine, orientare:**
- Originea (pivotul) la **baza obiectului, centrată în XZ**, pentru fiecare din
  cele trei.
- Toate trei se **exportă la origine** (0,0,0), nu decalate.
- Gura lui `Pipe_Broken` spre **+Y în Blender**. Vezi avertismentul de sus.
- Bevel **0.03 m**.
- Buget: `Pipe_Broken` ≤ **300**, `Pipe_Elbow` ≤ **160**, `Pipe_Segment` ≤ **100**.

**Export:**
- glTF Binary **(.glb)**, un fișier, nume `pipe_leak.glb`, cu **trei** obiecte:
  `Pipe_Broken`, `Pipe_Elbow`, `Pipe_Segment`, ca **copii direcți ai rădăcinii**.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere, lumini sau
  materiale complexe.
- **Apply Modifiers: ON** (bevel-ul să fie în geometrie). Y-up: implicit.

---

## Note pentru noi (nu fac parte din prompt)

- **Ce înlocuiește:** `garden_hose.glb` — un furtun de grădină, **activ pe
  Dunele** (`custom_hose_fracs = [0.478]` în `Track01.tscn`), care traversează
  șoseaua într-un canion de deșert. 748 de triunghiuri pentru un furtun; 300
  ajung pentru o conductă.
- **Contractul de orientare** vine din `scenes/props/water_hose.gd:25-26`:
  ```gdscript
  position = Vector3(road_width * 0.5 + 2.5, 0, 0)
  rotation.y = PI / 2   # duza modelului (-Z) se intoarce spre drum
  ```
  Plus `model_scale = 0.45` — dacă cerem o conductă de 3.6 m, scara aia se
  recalibrează. De raportat lungimea reală în PR.
- **Cele două variante extra sunt bonus peste issue-ul original** (#53 cerea doar
  conducta spartă). Sunt ieftine și dau instanței de gameplay material de
  împrăștiat prin decorul de șantier, lângă excavator.
- **Sloturi folosite:** `rust_metal` = 10, `sand_shadow` = 2, `concrete` = 8,
  `rock_dark` = 4.
- **Fișier nou. NU se atinge `garden_hose.glb`.**
- **Checklist la primire:** trei noduri cu numele exacte, copii direcți ai
  rădăcinii; bugetele per nod; gura lui `Pipe_Broken` verificată pe direcția
  corectă; UV pe centre; `COLOR_0`; origini la bază, toate la (0,0,0).
