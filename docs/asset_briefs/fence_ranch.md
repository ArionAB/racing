# Brief asset — Gard de ranch (`fence_ranch.glb`)

Brief auto-conținut pentru un agent Blender (ex. Blender MCP). Nu presupune
acces la restul repo-ului — tot contractul e aici. Sursele din care e derivat:
[style_bible.md](../style_bible.md) (estetică) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

Sursa reproductibilă: [tools/blender/build_fence_ranch.py](../../tools/blender/build_fence_ranch.py).

Referință vizuală: conceptul „Canyon Circuit", panoul **TRACK SIDE DETAILS** —
marginile drumului umplute cu detalii care fac lumea să pară locuită.

> **Prompt de dat agentului** — de la linia orizontală de mai jos în jos e
> paste-ready. Restul paginii sunt note pentru noi.

---

## 1. Ce construiești

Construiește **trei module de gard de ranch** (lemn decolorat), low-poly și
stilizate, pentru un joc de curse cu mașinuțe de jucărie în stil diorámă de
deșert (ton *Art of Rally* — machetă de masă, NU foto-realist). Rezultat: un
`.glb` cu trei obiecte, care intră într-o lume cu un singur material partajat.

## 2. Rolul lui în cadru

Gardul e **textură de margine**, nu reper: nu trebuie să-l observi, trebuie să
observi că marginea drumului nu mai e nisip gol. Se pune în **rânduri scurte**
pe porțiunile drepte, deci modulele se înlănțuie cap la cap — capetele lor
trebuie să se potrivească fără să lase fantă vizibilă.

Testul care spune că a reușit: la 40 m, din chase cam, rândul citește ca un
gard continuu care urmează terenul, nu ca niște bețe înfipte în nisip.

## 3. Formă și dimensiuni

Unitate: 1 = 1 m; mașina de referință = 4.2 m.

Trei obiecte în același fișier, cu numele **exacte** `Fence_A`, `Fence_B`,
`Fence_C`. Toate au **lungimea de 4.0 m pe axa X**, cu stâlpii la
`x = ±1.9` — ca modulele puse la pas de 4 m să se atingă.

- **`Fence_A` — întreg.** Doi stâlpi prismatici cu 4 laturi, secțiune
  0.14 × 0.14 m, înălțime **1.15 m**. Două lise orizontale între ei, late
  0.16 m și groase 0.06 m, la înălțimile **0.62 m** și **1.00 m**.
- **`Fence_B` — obosit.** Aceeași geometrie, dar stâlpii înclinați ~7° pe două
  axe (o singură axă pare drept din jumătate din unghiuri) și lisa de sus
  lăsată la un capăt cu ~8 cm.
- **`Fence_C` — rupt.** Un singur stâlp (cel din stânga), lisa de jos ruptă la
  ~60% din lungime, lisa de sus căzută pe pământ (culcată, sprijinită oblic).
  Fără geometrie zdrențuită — o față oblică la ruptură ajunge.

NU: sârmă, cuie, șuruburi, șipci verticale dese, stâlpi cilindrici cu multe
laturi, lise mai subțiri de 5 cm (dispar la 40 m și transformă silueta în
zgomot, style_bible §3).

## 4. Orientare

Gardul se întinde pe **X**. Fața lui privește spre **-Z în Godot**, adică spre
**+Y în Blender** — exportatorul glTF face `(x, y, z) -> (x, z, -y)`, deci
**Blender +Y devine Godot -Z**.

## 5. Culoare — FĂRĂ texturi proprii

UV → sloturi dintr-un atlas de paletă (32 sloturi orizontale). Fiecare față își
colapsează toate UV-urile pe **un singur punct**, centrul slotului:
`u = (slot + 0.5) / 32`, `v = 0.5`.

- Tot gardul (stâlpi + lise): **u = 0.296875, v = 0.5** (`wood_weathered`).

Un accent de culoare pe gard ar fi greșit: gardul e fundal, iar accentele sunt
o resursă rară care se cheltuie pe seturi (vezi issue-ul de accente).

Nu e nevoie să încarci vreo imagine în Blender; contează doar coordonata UV.
Materialul e înlocuit oricum la runtime de `Palette.apply_world_material()`.

## 6. Vertex colors = AO copt

Grayscale, se înmulțește peste culoare în engine. 1.0 = neatins, ~0.5 = adânc.
**Fără el prop-ul e o pată de culoare plată** — nu e opțional.

- Gradient vertical pe stâlpi: 0.55 la bază → 1.0 sus.
- Întunecă la îmbinarea lisă/stâlp și pe fața ruptă a lui `Fence_C`.
- Eșantioane: 24 ajung — piesele sunt mici și rare în geometrie.

## 7. Scară, origine, bevel

- Origine la **baza obiectului, centrată în XZ** (`finish(origin="base")`),
  fiecare variantă la (0,0,0).
- Bevel **0.02 m** (prop mic; mai mult mănâncă lisa de 6 cm).

## 8. Buget de triunghiuri

**≤ 220 de triunghiuri per modul**, măsurat după bevel.

> Patru cutii (doi stâlpi + două lise) = 48 de triunghiuri brute; bevel-ul
> multiplică cu ~3.7x, deci ~180. `Fence_C` iese natural mai ieftin.
> Se instanțiază în rânduri — la 8 rânduri × 5 module sunt 40 de instanțe,
> deci fiecare triunghi costă 40 (lecția `marker_post`).

## 9. Export

- glTF Binary **(.glb)**, un fișier, nume `fence_ranch.glb`, cu **trei**
  obiecte: `Fence_A`, `Fence_B`, `Fence_C`, ca **copii direcți ai rădăcinii**,
  exportate la origine.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere, lumini sau
  texturi incorporate.
- **Apply Modifiers: ON** (bevel-ul să fie în geometrie). Y-up: implicit.

---

## 10. Note pentru noi (nu fac parte din prompt)

**Măsurat:** `Fence_A` **176** / `Fence_B` **176** / `Fence_C` **132** de
triunghiuri (total 484), din 220 bugetul per modul. Verdict `verify_glb.py`:
**OK**. Lungimi: 3.94 / 3.97 / 3.41 m; înălțimi 1.15 / 1.26 / 1.15 m.
Pasul de plasare (`FENCE_PITCH` în track.gd) e **3.94**, adică lungimea reală a
lui `Fence_A` — la 4.0 modulele ar fi lăsat o fantă de 6 cm la fiecare
îmbinare.

```
python tools/blender/verify_glb.py assets/models/structures/fence_ranch.glb 220
```

- **Slot folosit:** `wood_weathered` = 9 (u = 0.296875).
- **Fără coliziune la plasare.** Un gard de 1.15 m cu colizor lângă șosea e
  exact genul de obiect de care te agăți; rolul lui e vizual.

## 11. Abateri de la brieful original și de ce

- **`Fence_B` se înclină în jurul axei LUNGI (X), nu pe două axe ca
  `marker_post`.** Prima variantă a copiat rețeta stâlpului (înclinare pe X
  *și* pe Y) și a ieșit **1.62 m înălțime în loc de 1.15**: pentru un obiect
  de 4 m, o rotație de 7° pe Y ridică un capăt cu 49 cm, iar `finish` coboară
  apoi tot gardul până atinge solul. Un stâlp de 1.2 m nu simte asta, un gard
  de 4 m devine balansoar. Rămâne 1.5° pe Y, cât să nu fie perfect drept.
- **Lisele se fac din `beam`, nu din `box`.** `beam` merge între două puncte,
  deci lisa lăsată la un capăt (`drop`) iese din geometrie, nu dintr-o rotație
  făcută de mână care ar fi lăsat capetele în aer.

## 12. Dependențe și compoziție

- Ajutoare din `dio_lib`: `Builder.box` / `Builder.beam`.
- Plasarea: rânduri scurte pe porțiunile DREPTE (detecția de curbură din
  `_build_chevrons`, cu condiția inversată), la marginea deschisă, cu
  variantele amestecate ca la `_MARKER_PICKS`.
