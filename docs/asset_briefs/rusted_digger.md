# Brief asset — Excavator ruginit (`rusted_digger.glb`)

Brief auto-conținut pentru un agent Blender (ex. Blender MCP). Nu presupune
acces la restul repo-ului — tot contractul e aici. Sursele din care e derivat:
[style_bible.md](../style_bible.md) (estetică) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

Referință vizuală: `assets/dunele_inspiration/sheet_wave1_props.png`, panoul
**RUSTY EXCAVATOR** (mijloc). Silueta din foaie e exact ce vrem.

> **Prompt de dat agentului** — de la linia orizontală de mai jos în jos e
> paste-ready. Restul paginii sunt note pentru noi.

---

Construiește un excavator ruginit low-poly, stilizat, pentru un joc de curse cu
mașinuțe de jucărie în stil diorámă de deșert (ton *Art of Rally* — machetă de
masă, NU foto-realist). Rezultat: un `.glb` cu două obiecte, care intră într-o
lume cu un singur material partajat.

## ⚠️ Al doilea obiect e brațul, și numele lui e contract

> ### Un obiect trebuie să se numească exact **`arm`** (litere mici).

Motorul îl caută după nume și îi animează rotația pe X — brațul coboară peste o
bandă de drum ca obstacol. Fără nodul `arm`, brațul rămâne nemișcat **dar
coliziunea tot comută**: o barieră invizibilă în mijlocul șoselei.

**Pivotul lui `arm`** trebuie să fie la articulația cu corpul, nu la baza
geometriei. Setează originea obiectului acolo.

**Formă și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4.2 m):

### `body` — șasiu, șenile și cabină

- **Șenile**: două blocuri alungite, 4.8 m lungime × 0.9 m lățime × 1.0 m
  înălțime, la ±1.5 m pe lateral. Roțile de capăt: câte un prismatic cu **8
  laturi** la fiecare capăt, rază 0.5 m. NU modela zalele individual — o tăietură
  de 6–8 caneluri longitudinale pe fața exterioară sugerează șenila și costă
  nimic.
- **Platformă rotativă** peste șenile: cutie 3.2×2.6×0.7 m, de la 1.0 la 1.7 m.
- **Cabină**: cutie 1.6×1.5×1.9 m, de la 1.7 la 3.6 m, decalată pe o parte.
  Ferestre: goluri sugerate cu slot închis, cu ramă groasă de 0.10 m dacă ai
  ajutorul `window()`; altfel plăci întunecate retrase cu 0.06 m.
- **Motor / contragreutate** în spatele platformei: cutie 1.4×2.2×1.1 m, cu un
  tub de eșapament vertical (prismatic 6 laturi, rază 0.10 m, înălțime 0.9 m).
- Înălțime totală ~3.6 m, lungime ~5.3 m.

### `arm` — brațul articulat, pivotat la articulație

- **Braț principal**: grindă 3.4 m lungime, secțiune 0.55×0.45 m, plecând de la
  articulația de pe platformă.
- **Antebraț**: grindă 2.2 m, secțiune 0.42×0.38 m, la ~40° față de primul.
- **Cupă**: o formă în „C" din 3 cutii, deschidere ~1.1 m, cu **4 dinți** —
  cutii mici de 0.15 m, nu conuri.
- **Doi cilindri hidraulici**: prismatice cu 6 laturi, rază 0.11 m. Doi, nu patru.
- **Originea obiectului la articulația cu platforma**, aproximativ (0.0, 0.6, 1.9)
  în coordonate Blender relative la baza excavatorului.

NU: furtunuri, cabluri, scări, oglinzi, plăcuțe, șuruburi, zale de șenilă
individuale.

**Culoare — FĂRĂ texturi proprii. UV → sloturi dintr-un atlas de paletă** (32
sloturi orizontale). Fiecare față își colapsează toate UV-urile pe **un singur
punct**, centrul slotului:
- Caroserie vopsită decolorată (platformă, cabină, brațe): **u = 0.359375, v = 0.5**
- Metal ruginit (șenile, cupă, hidraulice, eșapament): **u = 0.328125, v = 0.5**
- Ferestre și goluri: **u = 0.078125, v = 0.5**
- Nu e nevoie să încarci vreo imagine în Blender; contează doar coordonata UV.
  Materialul se înlocuiește ulterior.

Aici `PAINTED` (albastrul) **e permis și dorit** — pe o mașinărie e exact ce
trebuie, spre deosebire de structurile din peisaj unde s-a citit rece.

**Vertex colors = ambient occlusion copt (grayscale), se înmulțește peste
culoare în engine:**
- Gradient vertical: jos mai închis (~0.55), sus spre 1.0.
- Întunecă: sub platformă, între șenile, în interiorul cupei, la articulații.
- Pe `arm` folosește un gradient **slab** — obiectul se rotește, deci un gradient
  vertical puternic ar arăta greșit când brațul e coborât.
- 1.0 = neatins, ~0.5 = adânc/umbrit. Fără el iese plat — e obligatoriu.

**Scară, origine, orientare:**
- `body`: origine la **bază, centrată în XZ**.
- `arm`: origine **la articulație** (vezi mai sus). Va avea deci o translație de
  nod în GLB — e corect și așteptat.
- Excavatorul privește spre **+Y în Blender**.
- Bevel **0.05 m**.
- Buget: **≤ 900 triunghiuri în total** pe ambele obiecte.

**Export:**
- glTF Binary **(.glb)**, un fișier, nume `rusted_digger.glb`, cu **două**
  obiecte: `body` și `arm`, ca **copii direcți ai rădăcinii**.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere, lumini sau
  materiale complexe.
- **Apply Modifiers: ON** (bevel-ul să fie în geometrie). Y-up: implicit.

---

## Note pentru noi (nu fac parte din prompt)

- **Ce înlocuiește:** `toy_excavator.glb` — excavator de plastic din tema
  abandonată „ladă de nisip". Noduri actuale: `bucket`, `arm`, `body`. Noi cerem
  doar `body` + `arm`; cupa intră în `arm`, fiindcă oricum se rotește cu el.
- **Rigul actual, ca referință de proporție:** corp 5.10 × 4.90 × 7.10 m, pivotul
  brațului la `(0.8, 3.0, −1.4)`, brațul ajunge la Z −7.3.
  `scenes/hazards/excavator_hazard.gd:31-41` are colizoare potrivite manual pe
  rigul ăsta (`model_scale = 0.75`, corp `3.4³` la `(0,1.7,1.0)`, braț
  `1.6 × 2.0 × 4.6` la `(0,1.1,−2.9)`, `raise_angle = 0.55`).
  **Cerem un excavator vizibil mai mic** (5.3 m lungime în loc de 7.1) fiindcă
  cel actual e supradimensionat față de mașina de 4.2 m. De raportat cotele reale
  în PR ca să se recalibreze colizoarele.
- **Sloturi folosite:** `painted` = 11 (u = 0.359375), `rust_metal` = 10
  (u = 0.328125), `sand_shadow` = 2 (u = 0.078125).
- **Fișier nou. NU se atinge `toy_excavator.glb`.**
- **Checklist la primire:** două noduri, `body` și `arm`, copii direcți ai
  rădăcinii; **`arm` scris cu litere mici**; ≤ 900 tris total; pivotul lui `arm`
  la articulație; UV pe centre; `COLOR_0`.
