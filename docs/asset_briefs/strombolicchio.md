# Brief asset — Strombolicchio (`strombolicchio.glb`)

Brief auto-conținut pentru un agent Blender. Sursele:
[style_bible.md](../style_bible.md) + [blender_export.md](../blender_export.md) +
[scripts/palette.gd](../../scripts/palette.gd).

Referință vizuală: `docs/track_briefs/img/stromboli_assets_a.png`, panoul 3
(STROMBOLICCHIO — front / side / top / ¾).

**Rolul:** fundal-erou. Stă la ~200 m în larg și e silueta-semnătură a pistei —
apare la jumătatea urcării și rămâne reperul mării de pe buză. Se vede DOAR de
la 150–250 m, prin ceață caldă: siluetă și contrast, nu detaliu.

> **Prompt de dat agentului** — de la linia orizontală în jos e paste-ready.

---

Construiește un neck vulcanic negru care iese din mare, cu un far alb mic în
vârf, pentru un joc de curse în stil dioramă (ton *Art of Rally*, machetă de
masă). Low-poly, fațetat, citibil ca SILUETĂ de la 200 m. Rezultat: un `.glb`
cu patru obiecte.

**Formă și dimensiuni** (unitate: 1 = 1 m):

### `Stack_Rock` — stânca, ≤ 1400 triunghiuri

- Bază **30 × 22 m** la linia apei, înălțime **32 m**, pereți **aproape
  verticali** (silueta e un dinte zvelt, nu un con): lățimea la vârf ~14 × 10 m.
- Fațete mari verticale cu 2–3 polițe orizontale înguste — coloane de bazalt
  stilizate, nu stâncă rotundă.
- Vârful: platou ușor înclinat pentru far.
- La linia apei, un guler de 1 m ușor evazat (unde bate valul).

### `Stack_Stairs` — scara, ≤ 350 triunghiuri

- O scară îngustă (0.8 m) care urcă în **zigzag pe fața stâncii** de la un mic
  prag la linia apei până la platou: 4–5 rampe drepte cu podeste, geometrie de
  panglică (trepte sugerate prin 6–8 praguri pe rampă, nu 100 de trepte reale).
- Un parapet-muret scund (0.4 m) pe exteriorul rampelor.

### `Lighthouse_White` — farul, ≤ 500 triunghiuri

- Turn cilindric alb (prismă cu 10 laturi), **Ø 3 m, înalt 6.5 m**, pe un soclu
  pătrat de 4 × 4 × 1 m, cu o balustradă simplă sus.
- O căsuță-anexă mică (3 × 2 × 2 m) lipită de soclu.

### `Lighthouse_Lantern` — lanterna, ≤ 150 triunghiuri

- Lanterna de **1.5 m** peste turn: tambur cu 8 laturi + calotă; separată ca
  nod (la integrare poate primi un emisiv slab / sclipire).

NU: valuri modelate, pescăruși, antene, text, detaliu de zidărie.

**Culoare — FĂRĂ texturi proprii. UV colapsate pe centrul slotului:**
- Stânca: **u = 0.640625, v = 0.5**; polițele umbrite: **u = 0.140625, v = 0.5**
- Gulerul de la linia apei (spumă): **u = 0.703125, v = 0.5**
- Scara + muret: **u = 0.921875, v = 0.5**
- Far + anexă + soclu (alb): **u = 0.703125, v = 0.5**
- Lanterna: **u = 0.359375, v = 0.5**

**Vertex colors = AO copt:** stânca mai închisă jos (~0.6) spre 1.0 sus;
întunecă sub polițe și sub podestele scării; farul aproape curat (0.85–1.0).

**Scară, origine, orientare:**
- Originea la **LINIA APEI**, centrată în XZ (gulerul evazat la y=0; nimic
  relevant sub 0 — o fustă de 2 m sub linia apei e ok, se îneacă în mare).
- Fața cu scara spre **−Z**. Export la (0,0,0), toate nodurile.
- Bevel 0.2 m pe stâncă, 0.05 m pe far.
- Buget total: **≤ 2400 triunghiuri**.

**Export:** glTF Binary `.glb`, nume `strombolicchio.glb`, patru obiecte:
`Stack_Rock`, `Stack_Stairs`, `Lighthouse_White`, `Lighthouse_Lantern`,
copii direcți ai rădăcinii. Mesh + UVs + Vertex Colors + Normals; Apply
Modifiers ON.

---

## Note pentru noi (nu fac parte din prompt)

- **Sloturi:** `VOLCANIC_BLACK` 20, `ROCK_DARK` 4, `FOAM_WHITE` 22,
  `MARBLE_GREY` 29, `PAINTED_METAL` 11.
- **Cotele sunt legate** (memoria `efecte-de-fundal-cote-legate`): se plantează
  la ~200 m de coastă, sub `fog_end` 300 al temei și sub FAR_PLANE 380 —
  altfel există dar nu se vede. Poziție luată din harta Stromboli Recon
  (map ~(120, 372) → godot (−187, 0, −137)).
- **La integrare:** stânca poate primi clasa `rock` triplanară dacă silueta
  iese plată prin ceață; de decis pe captura de pe buză, nu dinainte.
- **Destinație:** `assets/models/stromboli/structures/strombolicchio.glb`.
- **De raportat în PR:** captură din joc DE PE BUZĂ (frac ~0.49) și de pe
  plajă (frac ~0.09) — testul e silueta prin ceață, nu detaliul de aproape.
- **Checklist:** 4 noduri cu nume exacte; ≤ 2400 tris; origine la linia apei
  (memoria `decor-manual-din-cod`: originile pe linia apei); scara spre −Z.
