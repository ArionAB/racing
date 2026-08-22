# Brief asset — Biserica din sat (`stromboli_church.glb`)

Brief auto-conținut pentru un agent Blender. Sursele:
[style_bible.md](../style_bible.md) + [blender_export.md](../blender_export.md) +
[scripts/palette.gd](../../scripts/palette.gd).

Referință vizuală: `docs/track_briefs/img/stromboli_assets_a.png`, panoul 2
(STROMBOLI CHURCH), plus vederea de sus din foaia B, panoul 2. **Simplifică
față de planșe**: au ieșit cu prea mult detaliu de zidărie — noi vrem volume
curate de var, în familia bisericii din Khuzhir (Baikal), nu o machetă de
catedrală.

> **Prompt de dat agentului** — de la linia orizontală în jos e paste-ready.

---

Construiește o biserică eoliană albă, mică, pentru un joc de curse cu mașinuțe
de jucărie în stil dioramă (ton *Art of Rally*, machetă de masă, NU
foto-realist). Low-poly, fațetat, volume simple văruite. Rezultat: un `.glb`
cu trei obiecte. E POI-ul liniei de start — mașinile trec pe lângă ea la
fiecare tur, la 10–15 m.

**Formă și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4.2 m):

### `Church_Body` — corpul, ≤ 1100 triunghiuri

- Volum principal **12 × 8 m**, înalt **6 m**, cu **fronton curb** pe fațadă
  (silueta baroc-mediteraneană: două volute laterale + segment de arc sus).
  Fațada e fața −Z.
- Acoperiș plat sau foarte ușor înclinat în spatele frontonului — NU șarpantă.
- **Trepte late** pe toată fațada: 3 trepte × 0.25 m.
- Colțuri și muchii **ușor rotunjite** (bevel generos — varul eolian nu are
  muchii vii).
- O ușă dreptunghiulară cu arc sus, **2.2 × 1.2 m**, ca panou plat retras
  0.3 m (fără gol tăiat), pe slotul albastru.
- Două ferestre mici arcuite pe fiecare latură lungă, panouri plate retrase.

### `Church_Tower` — campanilul, ≤ 900 triunghiuri

- Turn **3 × 3 m**, înalt **14 m**, lipit de colțul din dreapta-fațadă.
- **Trei goluri de clopot** pe registrul de sus (două pe fațadă, unul lateral),
  arcuite, cu panou întunecat retras; un clopot simplu (bipiramidă, ≤ 40 tris)
  în golul principal.
- Coronament în trepte + **cruce simplă** de 1 m în vârf.

### `Church_Trim` — accente, ≤ 300 triunghiuri

- Ancadramentele ușii și golurilor de clopot: rame plate de 0.15 m.
- Crucea, clopotul, mânerul ușii.
- Separat ca nod ca să poată primi alt slot decât corpul.

NU: olane detaliate, statui, vitralii, text, interior.

**Culoare — FĂRĂ texturi proprii. UV colapsate pe centrul slotului:**
- Corp, turn, trepte (var alb): **u = 0.703125, v = 0.5**
- Ușa și panourile ferestrelor (albastru-gri): **u = 0.359375, v = 0.5**
- Golurile de clopot (panouri retrase, întuneric): **u = 0.171875, v = 0.5**
- Ancadramente, cruce, clopot: **u = 0.921875, v = 0.5**

**Vertex colors = AO copt (grayscale):** gradient jos ~0.7 → sus 1.0; întunecă
sub fronton, în golurile de clopot (~0.35), sub trepte, pe retragerile ușii
și ferestrelor. Fără AO, varul iese carton.

**Scară, origine, orientare:**
- Origine la **baza**, centrată în XZ; fațada (frontonul + treptele) spre
  **−Z**. Export la (0,0,0), toate trei nodurile.
- Bevel 0.10 m pe var (rotunjimea e identitatea), 0.03 m pe accente.
- Buget total: **≤ 2300 triunghiuri**.

**Export:** glTF Binary `.glb`, nume `stromboli_church.glb`, trei obiecte:
`Church_Body`, `Church_Tower`, `Church_Trim`, copii direcți ai rădăcinii.
Mesh + UVs + Vertex Colors + Normals; Apply Modifiers ON.

---

## Note pentru noi (nu fac parte din prompt)

- **Sloturi:** `FOAM_WHITE` 22 (var — aceeași decizie ca zăpada Baikal: albul
  există deja, nu se duplică), `PAINTED_METAL` 11 (albastru-gri eolian pentru
  uși/obloane — #7692A8, exact rolul), `ASPHALT` 5 (goluri), `MARBLE_GREY` 29.
- **La integrare:** corpul poate primi clasa `plaster` (există de la farul
  Okinawa) cu UV cubic — de decis la primire, pe captură; dacă varul plat
  citește bine, rămâne pe atlas.
- **Destinație:** `assets/models/stromboli/buildings/stromboli_church.glb`;
  POI A (piața de start), DecorManual.
- **De raportat în PR:** captură de la nivelul drumului, ~25 m, cu o mașină
  pentru scară — testul e silueta frontonului + turnului contra cerului.
- **Checklist:** 3 noduri cu nume exacte; ≤ 2300 tris; fațada spre −Z;
  origine la bază; UV pe centre; `COLOR_0`.
