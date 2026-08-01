# Brief asset — Siluete de orizont ("butte", `butte.glb`)

Brief auto-conținut pentru un agent Blender (Blender MCP). Surse:
[style_bible.md](../style_bible.md) + [blender_export.md](../blender_export.md) +
[scripts/palette.gd](../../scripts/palette.gd).

> **Prompt de dat agentului** — de la linia orizontală în jos e paste-ready.

---

Construiește **5 formațiuni stâncoase mari pentru orizont** (obiecte separate în
același `.glb`), pentru un joc de curse cu mașinuțe de jucărie în stil **diorámă
de deșert** (ton *Art of Rally*). Rezultat: un `.glb` cu **un singur material
partajat**.

Se așază la **150–350 m** de pistă, deci contează **doar silueta**. Zero detaliu:
nimic din ce e mai mic de câțiva metri nu se vede de acolo.

Sunt reperele după care jucătorul se orientează pe pistă, deci fiecare are o formă
**distinctă** — trebuie să poți spune „sunt lângă cea înaltă și îngustă", nu să
vezi un șir de movile identice.

**Piese și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4 m):

| nume | L × A × Î | caracter |
|---|---|---|
| `Butte_A` | 34 × 28 × 25 m | apropiat, îndesat |
| `Butte_B` | 26 × 24 × 40 m | mediu |
| `Butte_C` | 22 × 20 × 60 m | turn îngust, cel mai înalt |
| `Mesa_A` | 62 × 34 × 18 m | lată și joasă |
| `Mesa_B` | 78 × 40 × 15 m | și mai lată |

- **Vârf plat** obligatoriu (siluetă de mesa) — un vârf rotund ar da o movilă.
- Construite din **1–2 trepte suprapuse**, fiecare mai îngustă decât cea de sub
  ea. Treptele sunt semnătura formei; un singur volum arată ca un deal.
- **Bevel: 0.** La 150 m+ o bandă de 15 cm e sub un pixel, dar ar adăuga
  geometrie la fiecare muchie a unei piese care există *doar* ca siluetă.

**Culoare — FĂRĂ texturi proprii. UV → sloturi de atlas** (32 sloturi, v = 0.5),
în gradient vertical:
- **Bază** → u = **0.140625** (rock_dark)
- **Corp** → u = **0.109375** (rock_light)
- **Coamă de sus** → u = **0.015625** (sand_light)

**Vertex colors = AO copt (grayscale):**
- **Bază puternic întunecată** (~0.26), vârf 1.0. Asta sugerează distanța
  (perspectivă atmosferică) fără ceață suplimentară și fără cost de runtime.

**Scară, origine:**
- Originea fiecărei formațiuni la **bază, centrată în XZ**.
- Buget: **≤ 180 triunghiuri fiecare**, ≤ 900 total.
- **Fără coliziune** — sunt pur decorative, nu se ajunge la ele.

**Export:** glTF Binary, `butte.glb`, 5 obiecte, Mesh + UVs + Vertex Colors +
Normals, Apply Modifiers ON, Y-up.

---

## Note pentru noi (nu fac parte din prompt)

- **Sloturi:** rock_dark=4, rock_light=3, sand_light=0.
- **Generat de** [tools/blender/build_butte.py](../../tools/blender/build_butte.py).
- Rezultat: **368 tris total** (80/80/80/64/64), mult sub buget.
- **Ce înlocuiesc:** cele 12 `SphereMesh` turtite din `_build_environment()`, care
  costau ~9.000 de triunghiuri (la rezoluția implicită Godot, 64×32) și arătau ca
  un șir de movile identice. Câștig net: ~6.500 de triunghiuri **și** de zece ori
  mai multă personalitate.
- **Cum se așază** (task „siluete la orizont"): în inele — 4 la 150–200 m (se văd
  peste faleze), 6 la 200–280 m, 4 la 280–350 m. Cele apropiate mai joase, cele
  depărtate mai înalte, ca să apară perspectivă. Cel puțin o formațiune dominantă
  vizibilă din linia de start și una din fiecare zonă de frânare majoră
  (style_bible §7).
- **Atenție la `camera.far`:** dacă se setează la 300, inelul de la 280–350 m e
  parțial tăiat. Fie inelul depărtat la 280–320, fie `far = 380`.
- **Discrepanță cunoscută:** `flat_top` retează vârful, deci înălțimea reală
  exportată e cu ~15% sub cea nominală (`Mesa_B`: 12.7 m față de 15). Irelevant
  pentru siluete la distanță, dar de știut dacă cineva se bazează pe cotă.
- **Checklist la primire:**
  1. ≤ 180 tris fiecare
  2. cele 5 obiecte cu numele exacte
  3. vârf plat, 1–2 trepte
  4. origine la bază, XZ centrat
  5. AO cu baza ~0.26
