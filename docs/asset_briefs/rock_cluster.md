# Brief asset — Grupuri de bolovani ("rock_cluster", `rock_cluster.glb`)

Brief auto-conținut pentru un agent Blender (Blender MCP). Surse:
[style_bible.md](../style_bible.md) + [blender_export.md](../blender_export.md) +
[scripts/palette.gd](../../scripts/palette.gd).

> **Prompt de dat agentului** — de la linia orizontală în jos e paste-ready.

---

Construiește **5 grupuri de bolovani** low-poly și stilizate (obiecte separate în
același `.glb`), pentru un joc de curse cu mașinuțe de jucărie în stil **diorámă
de deșert** (ton *Art of Rally* — machetă de masă, NU foto-realist). Rezultat: un
`.glb` cu **un singur material partajat**.

**Regula centrală: UN GRUP = UN SINGUR MESH.** Patru pietre așezate împreună
într-un obiect costă un draw call în joc, în loc de patru. Cu ~180 de grupuri pe
o pistă, asta e diferența între 180 și 700+ de instanțe.

**Formă și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4 m):

| nume | mărime | conținut |
|---|---|---|
| `Cluster_S1` | 0.85 m | 3 pietricele |
| `Cluster_S2` | 0.70 m | 2 pietricele |
| `Cluster_M1` | 2.4 m | 1 bolovan + 2 sateliți |
| `Cluster_M2` | 2.6 m | 1 bolovan + 1 satelit |
| `Cluster_L1` | 6.2 m | 1 dominant + 2 sateliți |

- Pietrele dintr-un grup **se întrepătrund** (offseturile mai mici decât razele).
  Un grup în care pietrele doar se ating citește ca obiecte separate puse alături,
  nu ca formațiune.
- **Rotunjite (70%) sau fațetate (30%), niciodată zimțate.** Straturi orizontale
  unde mărimea o permite.
- **Bevel scalat cu dimensiunea**: 0 pentru grupurile S, 0.08 pentru M, 0.15
  pentru L. Pe o pietricică de 40 cm, o bandă de 15 cm e o treime din obiect —
  arată umflat și dublează triunghiurile.

**Culoare — FĂRĂ texturi proprii. UV → sloturi de atlas** (32 sloturi, v = 0.5):
- **Corp de piatră** → u = **0.109375** (rock_light)
- **Pietre mici / de la bază** → u = **0.140625** (rock_dark)

**Vertex colors = AO copt (grayscale):** bază ~0.45, vârf 1.0. Întunecă unde
pietrele se ating între ele. Obligatoriu.

**Scară, origine:**
- Originea fiecărui grup la **bază, centrată în XZ**.
- Buget: **S ≤ 100, M ≤ 240, L ≤ 350** triunghiuri. Total ≤ 900.

**Export:** glTF Binary, `rock_cluster.glb`, 5 obiecte, Mesh + UVs + Vertex Colors
+ Normals, Apply Modifiers ON, Y-up.

---

## Note pentru noi (nu fac parte din prompt)

- **Sloturi:** rock_light=3, rock_dark=4.
- **Generat de** [tools/blender/build_rock_cluster.py](../../tools/blender/build_rock_cluster.py).
- **Bugetele au fost revizuite în sus** față de estimarea din plan (60/130/250,
  total 630). Estimarea aia ignora ce costă bevel-ul: adaugă geometrie la fiecare
  muchie, iar un grup de 3 pietre are de ~3 ori mai multe muchii decât o piatră.
  Compensarea s-a făcut unde contează — grupurile S, cele mai numeroase pe pistă,
  au primit bevel zero (180 → 60 tris).
- **Unde se folosesc** (benzi de decor, `track_decor.gd`): S în banda lipită de
  drum (fără coliziune), M în banda de mijloc, L1 în banda din spate.
- **Coliziune în joc:** un singur `SphereShape3D` pe propul dominant, nu unul per
  piatră.
- **Checklist la primire:**
  1. bugetele de mai sus respectate
  2. cele 5 obiecte cu numele exacte
  3. origine la bază, XZ centrat
  4. AO în vertex colors
  5. doar sloturile rock_light / rock_dark
