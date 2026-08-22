# Brief asset — Craterul (`crater_bowl.glb`)

Brief auto-conținut pentru un agent Blender (ex. Blender MCP). Nu presupune
acces la restul repo-ului — tot contractul e aici. Sursele:
[style_bible.md](../style_bible.md) + [blender_export.md](../blender_export.md) +
[scripts/palette.gd](../../scripts/palette.gd).

Referință vizuală: `docs/track_briefs/img/stromboli_assets_a.png`, panoul 1
(CRATER BOWL — front / side cutaway / top / ¾), plus secțiunea lungă prin
crater din foaia B, panoul 1.

**De ce e primul asset al pistei:** camera de urmărire vede 63° în JOS.
Buza craterului e carosabil (Track11, frac 0.47–0.52), iar interiorul ăsta e
CE VEDE jucătorul când trece pe ea. E piesa de rezistență vizuală a pistei.

> **Prompt de dat agentului** — de la linia orizontală în jos e paste-ready.

---

Construiește interiorul unui crater vulcanic activ, văzut de sus, pentru un joc
de curse cu mașinuțe de jucărie în stil dioramă (ton *Art of Rally* — machetă
de masă, NU foto-realist). Low-poly, fațetat. Rezultat: un `.glb` cu două
obiecte, într-o lume cu un singur material partajat.

**Contextul de amplasare:** craterul se așază într-o gaură deja săpată în
teren; drumul jocului trece chiar pe buza lui. Jucătorul îl vede aproape
exclusiv DE SUS și DIN LATERAL-SUS, de la 10–20 m — fundul și pereții
contează, exteriorul aproape deloc.

**Formă și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4.2 m):

### `Crater_Bowl` — cuva, ≤ 2400 triunghiuri

- **Inel exterior**: diametru **58 m** la coronament, cu o fustă scurtă de 3 m
  în afară, teșită în jos, ca să se îngroape în teren fără muchie vizibilă.
- **Interiorul coboară în trepte** până la **−13 m**: 4–5 terase inelare
  neregulate de scorie, fiecare cu fața verticală de 1.5–3 m și podestul
  înclinat spre centru. Terasele NU sunt cercuri concentrice curate — rupe-le
  în arce decalate, cu surpări locale (2–3 pene de grohotiș care taie peste
  două terase).
- **Fundul**: un platou neregulat de ~18 m diametru la −13 m.
- Silueta generală: cuvă, nu pâlnie — pereții abrupți sus, fundul lat.
- Fațete mari, low-poly; muchiile teraselor ușor neregulate în plan.

### `Crater_Vents` — gurile active, ≤ 700 triunghiuri

- **Trei conuri mici** pe fundul cuvei, descentrate (nu în mijloc): Ø 4 m /
  3 m / 2.5 m, înalte 1.5–2.5 m, cu gura teșită.
- **Buzele gurilor și 3–4 crăpături radiale** care pleacă din ele pe fund:
  fâșii de geometrie plată, late 0.3–0.6 m, ușor scufundate — astea primesc
  culoarea incandescentă (vezi mai jos) și, în engine, emisiv.
- Crăpăturile sunt geometrie separată pe fund, NU textură.

NU: lavă lichidă modelată, stalactite, fum modelat (fumul vine din particule
în engine), text, schele sau obiecte umane.

**Culoare — FĂRĂ texturi proprii. UV → sloturi dintr-un atlas de paletă** (32
sloturi orizontale). Fiecare față își colapsează toate UV-urile pe **un singur
punct**, centrul slotului:

- Terase, pereți, fustă exterioară (scorie închisă): **u = 0.640625, v = 0.5**
- Fețele verticale din umbră ale teraselor, alternativ: **u = 0.140625, v = 0.5**
- Podestele prăfuite de cenușă, coronamentul: **u = 0.921875, v = 0.5**
- Conurile gurilor: **u = 0.640625, v = 0.5**
- **Buzele gurilor + crăpăturile radiale (incandescent): u = 0.953125, v = 0.5**
- Nu încărca nicio imagine; contează doar coordonata UV.

**Vertex colors = ambient occlusion copt (grayscale):**
- Gradient general cu adâncimea: coronament ~1.0 → fund ~0.45.
- Întunecă tare sub fețele verticale ale teraselor (~0.4).
- **Crăpăturile și buzele incandescente rămân la 1.0** — orice AO peste ele
  omoară semnalul; ele trebuie să iasă în evidență, nu să se îngroape.

**Scară, origine, orientare:**
- Originea la **nivelul coronamentului, centrată în XZ** — cuva coboară în
  −Y de la origine. (Se așază la cota drumului de pe buză.)
- Export la (0,0,0). Fără direcție „înainte" — obiectul e radial.
- Bevel 0.15 m pe muchiile teraselor.
- Buget total: **≤ 3100 triunghiuri**.

**Export:** glTF Binary `.glb`, nume `crater_bowl.glb`, două obiecte:
`Crater_Bowl`, `Crater_Vents`, copii direcți ai rădăcinii. Include Mesh,
UVs, Vertex Colors, Normals. Apply Modifiers ON. Fără camere/lumini.

---

## Note pentru noi (nu fac parte din prompt)

- **Sloturi:** `VOLCANIC_BLACK` 20 (scorie), `ROCK_DARK` 4 (fețe umbrite),
  `MARBLE_GREY` 29 (cenușă), `LAVA_ORANGE` 30 (incandescent — slot adăugat în
  același PR cu brief-ul ăsta).
- **La integrare:** `Crater_Vents` primește materialul de clasă emisiv al
  lavei (partajat cu `lava_flow` și `volcanic_bomb` — UN material, garda
  numără). Fumul din guri = particule din cod, pe `EruptionCycle`.
- **Destinație:** `assets/models/stromboli/structures/crater_bowl.glb`;
  se plantează la centrul craterului din Track11 (godot −109.2, y buza, 268.3),
  în gaura săpată de `custom_ravines[0]`.
- **De raportat în PR:** captură DE SUS + de pe buză de la ~10 m (unghiul
  camerei de joc: 28.7° în jos). Testul: terasele se citesc ca adâncime?
  crăpăturile portocalii se văd de pe buză?
- **Checklist la primire:** 2 noduri cu numele exacte; ≤ 3100 tris; origine la
  coronament; UV pe centre; `COLOR_0` prezent; crăpăturile la AO 1.0.
