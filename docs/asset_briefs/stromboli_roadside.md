# Brief asset — Piese de margine Stromboli (`fumarole_vent.glb` + `chevron_post.glb` + `ginostra_pier.glb`)

Brief auto-conținut pentru un agent Blender. Sursele:
[style_bible.md](../style_bible.md) + [blender_export.md](../blender_export.md) +
[scripts/palette.gd](../../scripts/palette.gd).

Referință vizuală: `docs/track_briefs/img/stromboli_assets_a.png`, panourile
7 (FUMAROLE VENTS), 8 (CHEVRON POST), 9 (GINOSTRA PIER). **Corecție la
ponton:** în foaia A a ieșit movilă de stâncă; forma corectă e **dana de beton
curată** din foaia B (panoul 10, stânga-jos) + scara albă în stâncă.

> **Prompt de dat agentului** — de la linia orizontală în jos e paste-ready.
> Sunt TREI fișiere mici, descrise pe rând.

---

Construiește trei piese de margine de drum pentru un joc de curse pe o insulă
vulcanică, în stil dioramă (ton *Art of Rally*, machetă de masă). Low-poly,
fațetat, fără text nicăieri.

## Fișierul 1: `fumarole_vent.glb` — trei obiecte

### `Fumarole_A` / `Fumarole_B` / `Fumarole_C` — ≤ 220 triunghiuri fiecare
- Conuri mici de pământ crustos: diametre la bază **0.8 / 1.2 / 1.5 m**,
  înălțimi **0.4 / 0.6 / 0.8 m**, cu **gura deschisă** în vârf (Ø 0.2–0.4 m,
  panou întunecat retras înăuntru — fără gol tăiat).
- Crusta: pământ gri-albicios ars, fațete neregulate.
- **Depuneri de sulf pe buză**: un inel neregulat de geometrie plată
  galben-oliv în jurul gurii + 2–3 limbi care se scurg pe con.
- Aburul NU se modelează — vine din particule în engine.

## Fișierul 2: `chevron_post.glb` — un obiect

### `Chevron_Post` — ≤ 120 triunghiuri
- Stâlp de lemn închis **0.12 × 0.12 m**, înalt **1.2 m**.
- Placă dreptunghiulară **0.6 × 0.45 m** montată sus, perpendiculară pe
  privire (fața spre −Z), cu **modelul chevron ca GEOMETRIE**: 3 săgeți roșii
  pe fond alb, fiecare săgeată un poligon separat ușor extrudat (0.01 m) —
  dungi geometrice, NU literă, NU textură.
- Sensul săgeților: spre **+X** (dreapta privitorului); pista îl oglindește
  prin scale la plantare unde trebuie invers.

## Fișierul 3: `ginostra_pier.glb` — trei obiecte

### `Pier_Slab` — ≤ 300 triunghiuri
- **Dană de beton curată**: placă **8 × 3 m**, groasă 0.8 m, pe două picioare
  scunde de beton; muchia spre mare ușor teșită; fața de sus cu 2–3 rosturi
  sugerate din bevel.

### `Pier_Stairs` — ≤ 250 triunghiuri
- Scară **albă, văruită**, lată 1.2 m, care urcă **4 m** dintr-un capăt al
  danei pe stânca neagră: 2 rampe cu un podest, muret alb scund pe exterior
  (aceeași familie cu scările satului).
- Include sub ea o pană de stâncă neagră fațetată (2 × 3 × 4 m) pe care e
  tăiată — scara nu plutește.

### `Pier_Fittings` — ≤ 150 triunghiuri
- **Doi bolarzi** (ciuperci de 0.4 m) pe dană, un **inel de acostare** pe
  muchie, un colac de frânghie (tor turtit, opțional).

NU (toate trei): text, valuri, alge, oameni, plase (plasele sunt în kitul de
sat).

**Culoare — FĂRĂ texturi proprii. UV colapsate pe centrul slotului:**
- Fumarole — crusta: **u = 0.921875, v = 0.5**; gura (întuneric):
  **u = 0.171875, v = 0.5**; sulful: **u = 0.421875, v = 0.5**
- Chevron — stâlp: **u = 0.296875, v = 0.5**; placa fond: **u = 0.703125,
  v = 0.5**; săgețile: **u = 0.234375, v = 0.5**
- Ponton — beton: **u = 0.265625, v = 0.5**; scara + muret (var):
  **u = 0.703125, v = 0.5**; stânca: **u = 0.640625, v = 0.5**; bolarzi +
  inel + frânghie: **u = 0.328125, v = 0.5**

**Vertex colors = AO copt:** gurile fumarolelor spre 0.3; sub placa
chevronului și sub dană ~0.6; restul 0.8–1.0.

**Scară, origine, orientare:**
- Fumarole: origine la bază, centrată. Chevron: origine la baza stâlpului,
  placa spre −Z. Ponton: `Pier_Slab` cu originea la **linia apei** (fața de
  sus a danei la +0.8), dana ieșind spre **−Z** (spre mare); `Pier_Stairs` și
  `Pier_Fittings` poziționate relativ la aceeași origine, exportate împreună
  la (0,0,0).
- Bevel 0.03–0.08 m după piesă.
- Bugete: `fumarole_vent.glb` ≤ 660; `chevron_post.glb` ≤ 120;
  `ginostra_pier.glb` ≤ 700.

**Export:** trei fișiere glTF Binary cu obiectele numite exact ca mai sus,
copii direcți ai rădăcinii. Mesh + UVs + Vertex Colors + Normals; Apply
Modifiers ON.

---

## Note pentru noi (nu fac parte din prompt)

- **Sloturi:** `MARBLE_GREY` 29 (crustă fumarole), `DRY_VEGETATION` 13
  (sulful — oliv-gălbui, nu galben pur: accentele saturate rămân lava și
  mașinile), `ASPHALT` 5 (goluri), `WOOD_WEATHERED` 9, `FOAM_WHITE` 22,
  `KERB_RED` 7 (chevron — aceleași dungi ca bordurile), `CONCRETE` 8,
  `VOLCANIC_BLACK` 20, `RUST_METAL` 10.
- **Fumarolele** primesc la integrare particulele + `Area3D` de albire
  (hazard-teatru, brief pistă §3) — asset-ul e doar conul.
- **Chevronul** se plantează pe exteriorul acelor de păr și pe crestele oarbe
  ale coborârii (semnalizarea vine în același pachet cu traseul —
  world_design). Sensul se decide la plantare prin rotire/oglindire pe nod
  (memoria `multimesh-oglindire-culling`: oglindirea în MultiMesh se aruncă —
  deci chevroanele se pun ca noduri, nu în MultiMesh, dacă au nevoie de
  scale.x = −1).
- **Destinație:** `assets/models/stromboli/props/`.
- **De raportat în PR:** chevronul de la 25 m din unghiul camerei (se citește
  săgeata?); pontonul de pe apă la 30 m.
- **Checklist:** nume exacte; bugete; fumarolele cu gura întunecată; săgețile
  chevron geometrie, nu textură; dana cu origine la linia apei.
