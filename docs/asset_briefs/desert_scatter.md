# Brief asset — Filler de margine ("desert_scatter", `desert_scatter.glb`)

Brief auto-conținut pentru un agent Blender (Blender MCP). Surse:
[style_bible.md](../style_bible.md) + [blender_export.md](../blender_export.md) +
[scripts/palette.gd](../../scripts/palette.gd).

> **Prompt de dat agentului** — de la linia orizontală în jos e paste-ready.

---

Construiește **5 piese mărunte de umplutură pentru deșert** (obiecte separate în
același `.glb`), pentru un joc de curse cu mașinuțe de jucărie în stil **diorámă
de deșert** (ton *Art of Rally*). Rezultat: un `.glb` cu **un singur material
partajat**.

Piesele se așază la **1.5–4 m de asfalt**, fără coliziune — mașina trece prin ele.
Rolul lor e să dea senzația de îngustime a canionului, nu să oprească pe nimeni.

> **Acesta e cel mai strâns buget din tot proiectul.** Se instanțiază ~115
> exemplare pe pistă, deci fiecare triunghi în plus se înmulțește cu 115. **Zero
> bevel** peste tot: la mărimea asta nu se vede, dar s-ar plăti de 115 ori.

**Piese și dimensiuni** (unitate: 1 = 1 m):

| nume | mărime | descriere |
|---|---|---|
| `Bush_A` | 0.95 × 0.62 m | tufă uscată, masă neregulată turtită |
| `Bush_B` | 0.68 × 0.48 m | tufă mai mică |
| `Pebbles_A` | ~0.35 m | 2 pietricele plate |
| `Pebbles_B` | ~0.42 m | 3 pietricele plate |
| `Grass_Tuft` | ~0.55 m | smoc din 3 lame late, înclinate |

- Tufele: **fără frunze individuale** — la 60 km/h ar fi zgomot vizual, și ar
  costa de 115 ori.
- Smocul: **lame late, nu fire**. Trei prisme înclinate citesc ca smoc de la
  distanță și costă ~24 de triunghiuri.
- Pietricelele: sub 30 cm, plate — sugerează sfărâmătură căzută de la baza
  falezei.

**Culoare — FĂRĂ texturi proprii. UV → sloturi de atlas** (32 sloturi, v = 0.5):
- **Vegetație** (tufe, smoc) → u = **0.421875** (dry_vegetation)
- **Pietricele** → u = **0.109375** (rock_light) și **0.078125** (sand_shadow),
  alternativ

**Vertex colors = AO copt (grayscale):**
- Tufe: **jumătatea de jos net mai închisă** (~0.45 jos → 1.0 sus). Fără
  gradientul ăsta tufele par lipite pe nisip, nu crescute din el.
- Pietricele: gradient mai blând (~0.55 jos).

**Scară, origine:**
- Originea fiecărei piese la **bază, centrată în XZ**.
- Buget: **≤ 40 triunghiuri fiecare, ≤ 200 total.**
- **Bevel: 0** peste tot.

**Export:** glTF Binary, `desert_scatter.glb`, 5 obiecte, Mesh + UVs + Vertex
Colors + Normals, Apply Modifiers ON, Y-up.

---

## Note pentru noi (nu fac parte din prompt)

- **Sloturi:** dry_vegetation=13 (u=0.421875), rock_light=3 (u=0.109375),
  sand_shadow=2 (u=0.078125).
- **Generat de** [tools/blender/build_desert_scatter.py](../../tools/blender/build_desert_scatter.py).
- Rezultat la prima generare: **148 tris total** (26/26/24/36/36) — singurul asset
  al canionului care a intrat în buget din prima încercare, exact fiindcă a fost
  proiectat cu bevel zero de la început.
- **Fără coliziune în joc**, deliberat: `track_decor.gd` le pune ca
  `MeshInstance3D` direct, nu sub `StaticBody3D`. Vezi tensiunea artă-vs-gameplay
  din planul de canion — style_bible cere prop-uri la 2–4 m de drum, dar la
  distanța aia coliziunea ar face cursa nejucabilă.
- **Checklist la primire:**
  1. ≤ 40 tris fiecare, ≤ 200 total
  2. cele 5 obiecte cu numele exacte
  3. origine la bază, XZ centrat
  4. AO în vertex colors, jumătatea de jos mai închisă la tufe
