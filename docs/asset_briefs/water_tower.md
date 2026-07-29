# Brief asset — Turn de apă (`water_tower.glb`)

Brief auto-conținut pentru un agent Blender (ex. Blender MCP). Nu presupune
acces la restul repo-ului — tot contractul e aici. Sursele din care e derivat:
[style_bible.md](../style_bible.md) (estetică) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

> **Prompt de dat agentului** — de la linia orizontală de mai jos în jos e
> paste-ready. Restul paginii sunt note pentru noi.

---

Construiește un turn de apă low-poly, stilizat, pentru un joc de curse cu
mașinuțe de jucărie în stil diorámă de deșert (ton *Art of Rally* — machetă de
masă, NU foto-realist). Rezultat: un `.glb` care intră într-o lume cu un singur
material partajat.

**Formă și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4 m):
- Înălțime totală ≈ **9.5 m**.
- **Picioare / schelă**: de la 0 la 5.7 m. **4 picioare groase, evazate** —
  amprentă la sol ~4.6×4.6 m, sus ~2.8×2.8 m. Grinzi de ~0.25 m grosime. Două
  inele orizontale de legătură (la 2.0 m și 4.0 m) și **o singură diagonală
  groasă per față** — NU fermă fină, NU zăbrele subțiri.
- **Rezervor**: cilindru cu **12–14 laturi**, de la 5.7 la 8.0 m, rază ~1.5 m.
- **Acoperiș conic**: 8.0 → 9.2 m, streașină ușor peste rezervor (rază ~1.7 m).
- **Finial**: cilindru mic pe vârf, 9.2 → 9.5 m, rază ~0.12 m.
- **Scară** (opțională): o singură față, doar dacă rămâne *chunky* — două
  balustre groase + câteva trepte groase. Dacă iese subțire, omite-o.

**Culoare — FĂRĂ texturi proprii. UV → sloturi dintr-un atlas de paletă** (32
sloturi orizontale). Fiecare față își colapsează toate UV-urile pe **un singur
punct**, centrul slotului:
- Metal ruginit (rezervor, acoperiș, finial, inele): **u = 0.328125, v = 0.5**
- Lemn decolorat (picioare, diagonale, scară): **u = 0.296875, v = 0.5**
- Nu e nevoie să încarci vreo imagine în Blender; contează doar coordonata UV.
  Materialul se înlocuiește ulterior.

**Vertex colors = ambient occlusion copt (grayscale), se înmulțește peste
culoare în engine:**
- Gradient vertical: jos mai închis (~0.55), sus spre 1.0.
- Întunecă unde se ocluză: sub rezervor, unde picioarele se întâlnesc, sub
  streașina acoperișului, în interiorul schelei.
- 1.0 = neatins, ~0.5 = adânc/umbrit. Fără el iese plat — e obligatoriu.

**Scară, origine, orientare:**
- Originea (pivotul) la **baza obiectului, centrată în XZ**, ca să stea direct
  pe sol la poziție.
- Bevel **consistent 0.08 m** pe toate muchiile (semnătura stilului — colțuri
  rotunjite, nimic tăios).
- Buget: **≤ 900 triunghiuri**. Fără șuruburi, balustrade subțiri sau detaliu
  de frecvență înaltă — se pierde la viteză. Siluetă mare și lizibilă.

**Export:**
- glTF Binary **(.glb)**, un fișier, nume `water_tower.glb`.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere, lumini sau
  materiale complexe.
- **Apply Modifiers: ON** (bevel-ul să fie în geometrie). Y-up: implicit.

---

## Note pentru noi (nu fac parte din prompt)

- **Referința foto ≠ suprafață.** Poza de kit are rugină și zăbrele fine
  foto-realiste; noi le simplificăm la grinzi groase + AO în vertex colors.
  Poza dă *silueta și inventarul*, nu suprafața.
- **Sloturi folosite:** `rust_metal` = 10 (u = (10+0.5)/32 = 0.328125),
  `wood_weathered` = 9 (u = (9+0.5)/32 = 0.296875). Dacă se schimbă ordinea în
  [palette.gd](../../scripts/palette.gd), se recalculează u.
- **Checklist de verificare la primire** (`res://assets/models/water_tower.glb`):
  1. triunghiuri ≤ 900
  2. UV-urile nimeresc centrele sloturilor (metal 0.328125 / lemn 0.296875)
  3. origine la bază, centrată XZ; stă pe sol la Y=0
  4. există un strat de vertex color (AO), nu doar geometrie plată
  5. instanțiere cu `Palette.apply_world_material(glb)` → un singur material
- Dacă turnul trece, ăsta e șablonul; următoarele hero-uri (moară, benzinărie,
  container, semne, pod) se derivă schimbând doar §Formă și §Sloturi.
