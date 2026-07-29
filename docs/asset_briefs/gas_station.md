# Brief asset — Benzinărie ("gas station", `gas_station.glb`)

Brief auto-conținut pentru un agent Blender (Blender MCP). Nu presupune acces la
restul repo-ului — tot contractul e aici. Surse din care e derivat:
[style_bible.md](../style_bible.md) (estetică) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

> **Prompt de dat agentului** — de la linia orizontală în jos e paste-ready.
> Restul paginii sunt note pentru noi.

---

Construiește o benzinărie mică de șosea (roadside gas station), low-poly și
stilizată, pentru un joc de curse cu mașinuțe de jucărie în stil **diorámă de
deșert** (ton *Art of Rally* — machetă de masă, NU foto-realist). Rezultat: un
`.glb` care intră într-o lume cu **un singur material partajat**. E o piesă
"hero" — landmark vizibil de la distanță, siluetă mare și lizibilă, zero detaliu
de frecvență înaltă.

**Formă și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4 m; gabarit
total ≈ **8 × 6 × 5 m**):
- **Fundație / dală de beton**: 8 × 6 m, groasă 0.2 m, la sol. Ușor mai mare
  decât clădirea, ca o platformă.
- **Clădire principală**: cutie ~5 × 4 m amprentă, pereți până la **3.2 m**,
  **acoperiș în pantă 18°** (coamă la ~4.6 m). Nimic cubic perfect — pantă
  vizibilă. O ușă și 1–2 ferestre mari (doar geometrie inset, fără sticlă reală).
- **Copertină (canopy) peste pompe**: acoperiș plat/ușor înclinat ~4 × 3 m
  sprijinit pe **2 stâlpi groși**, la înălțime ~3.6 m, în față-lateral, ca să
  acopere insula de pompe. Grinzi groase (~0.2 m).
- **2 pompe de benzină** sub copertină: cutii ~0.6 × 0.4 × **1.2 m**, cu un cioc
  scurt (furtun sugerat printr-un bloc, NU tub subțire).
- **Panou "GAS STATION"** pe fațadă/roofline: o placă dreptunghiulară ~2.4 × 0.7 m,
  ridicată peste streașină. Fără text 3D — se citește prin culoare + siluetă.
  Opțional o stea simplă (bloc turtit) lângă panou.
- Bevel **consistent 0.08 m** pe toate muchiile (semnătura stilului — colțuri
  rotunjite, nimic tăios).

**Culoare — FĂRĂ texturi proprii. UV → sloturi dintr-un atlas de paletă** (32
sloturi orizontale). Fiecare față își colapsează toate UV-urile pe **un singur
punct**, centrul slotului (v = 0.5 mereu):
- **Lemn decolorat** (pereți clădire, stâlpi copertină) → u = **0.296875**
- **Metal ruginit** (acoperiș clădire, acoperiș copertină) → u = **0.328125**
- **Beton** (dală fundație, fața panoului "GAS", corp pompe) → u = **0.265625**
- **Metal vopsit** (accente pompe, ramă panou, ornamente) → u = **0.359375**
- **Roșu bordură/accent** (steaua, dunga panoului, detalii pompe) → u = **0.234375**
- **Asfalt** (sticla ferestrelor/ușii, ca "gol" întunecat) → u = **0.171875**
- Nu încărca nicio imagine în Blender; contează doar coordonata UV. Materialul
  se înlocuiește ulterior în engine.

**Regulă de citire (obligatorie):** panoul și accentele roșii NU trebuie să fie
mai închise decât asfaltul — asfaltul rămâne cea mai închisă suprafață din lume.

**Vertex colors = ambient occlusion copt (grayscale), se înmulțește peste
culoare în engine:**
- Gradient vertical: jos mai închis (~0.55), sus spre 1.0.
- Întunecă unde se ocluză: sub copertină, sub streașină, în colțurile dintre
  pereți, sub dală, între pompe.
- 1.0 = neatins, ~0.5 = adânc/umbrit. Fără el iese plat — e obligatoriu.

**Scară, origine, orientare:**
- Originea (pivotul) la **baza obiectului, centrată în XZ** (centrul dalei), ca
  să stea direct pe sol la poziționare.
- Fața cu pompele orientată spre **-Z** (spre stradă/camere).
- Buget: **≤ 1800 triunghiuri**. Fără șuruburi, furtunuri subțiri, balustrade —
  se pierd la viteză. Siluetă mare și lizibilă.

**Export:**
- glTF Binary **(.glb)**, un fișier, nume `gas_station.glb`.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere, lumini sau
  materiale complexe.
- **Apply Modifiers: ON** (bevel-ul în geometrie). Y-up: implicit.

---

## Note pentru noi (nu fac parte din prompt)

- **Referința foto ≠ suprafață.** Poza de kit are rugină foto-realistă și
  ferestre reflectante; noi le reducem la blocuri + AO în vertex colors. Poza dă
  *silueta și inventarul* (clădire + copertină + 2 pompe + panou), nu suprafața.
- **Sloturi folosite** (din [palette.gd](../../scripts/palette.gd)): wood_weathered=9
  (u=0.296875), rust_metal=10 (0.328125), concrete=8 (0.265625), painted_metal=11
  (0.359375), kerb_red=7 (0.234375), asphalt=5 (0.171875). Dacă se schimbă
  ordinea în palette.gd, se recalculează u = (slot+0.5)/32.
- **Commit sursa `.blend` + `.glb`** (regula de onboarding) — nu doar exportul,
  ca oricine din echipă să poată edita ulterior.
- **Checklist la primire** (`res://assets/models/gas_station.glb`):
  1. triunghiuri ≤ 1800
  2. UV-urile nimeresc centrele sloturilor (verifică pompele = beton, acoperiș = rugină)
  3. origine la bază, centrată XZ; stă pe sol la Y=0
  4. există un strat de vertex color (AO), nu doar geometrie plată
  5. instanțiere cu `Palette.apply_world_material(glb)` → un singur material
- Text "GAS STATION" real: **nu** se modelează. Dacă îl vrem lizibil mai târziu,
  se adaugă un slot de decal separat în atlas — decizie ulterioară.
