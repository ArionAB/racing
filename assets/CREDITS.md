# Credite — assets externe cu atribuire obligatorie

Restul asset-urilor din `assets/models/` sunt CC0 (vezi `LICENSE_quaternius.txt`,
`LICENSE_rgsdev.txt` — atribuire neceruta) sau construite din cod
(`tools/blender/build_*.py`). Fisierul asta exista DOAR pentru sursele
**CC-BY**, unde atribuirea e o conditie a licentei, nu o curtoazie.

---

## cruise_boat.glb (Fiordland, Track16)

- **Titlu sursa:** "Cruise Ship" (fisier original `cruise_ship_-_toofan.glb`)
- **Autor:** sec20ad002
- **Sursa:** Sketchfab
- **Licenta:** CC-BY-4.0 (https://creativecommons.org/licenses/by/4.0/)
- **Modificari facute** (26 sep 2026, `tools/blender/build_fiordland_boats_reuse.py`):
  transformurile de nod aplicate direct pe geometrie; reorientat cu axa
  lunga pe Blender +Y (Godot local Z), ca transformurile existente din
  Track16.tscn sa ramana valide; scalat la 14,0 m lungime (cota vechiului
  `cruise_boat` inlocuit); originea mutata la linia de plutire (carena
  coboara sub Y=0, ca modelul vechi); cele 3 materiale FLAT originale
  (rosu/alb/gri-inchis, fara texturi) remapate pe sloturile de paleta ale
  jocului — alb si gri-inchis pe `FOAM_WHITE`/`VOLCANIC_BLACK`, rosul topit
  in `VOLCANIC_BLACK` (brief-ul cere "vaporase ALBE", fara dunga rosie);
  UV colapsat pe centrele sloturilor din `palette_atlas.png` (fara textura
  proprie, conform CLAUDE.md — materiale de clasa, nu per asset); AO copt
  in vertex colors; export cu un singur material comun (`PaletteAtlas`),
  zero imagini incorporate.

## kayak_a.glb / kayak_b.glb (Fiordland, Track16)

- **Titlu sursa:** "Canoe - Low Poly" (fisier original `canoe_-_low_poly.glb`)
- **Autor:** dannzjs
- **Sursa:** Sketchfab
- **Licenta:** CC-BY-4.0 (https://creativecommons.org/licenses/by/4.0/)
- **Modificari facute** (26 sep 2026, `tools/blender/build_fiordland_boats_reuse.py`):
  transformurile de nod aplicate direct pe geometrie; reorientat cu axa
  lunga pe Blender +Y (Godot local Z); scalat la 3,6 m lungime (cota
  vechilor kayak_a/kayak_b inlocuite); origine la baza; textura JPEG
  incorporata in sursa (unul din cele 3 materiale) **aruncata** — culoarea
  vine din atlasul de paleta al jocului (style_bible §4: un asset nu aduce
  niciodata texturi proprii); corpul remapat pe `CAR_BLUE` (kayak_a) /
  `CAR_YELLOW` (kayak_b) — exceptie deja declarata in kit-ul Fiordland
  (`tools/blender/verify_fiordland.sh --allow-car-slots`), cockpitul pe
  `VOLCANIC_BLACK`; UV colapsat pe sloturi; AO copt in vertex colors;
  export cu un singur material comun (`PaletteAtlas`), zero imagini
  incorporate.

Fisierele sursa nemodificate raman in
`D:/GameDev/downloaded assets/Boats/` (in afara repo-ului); `.blend`-urile
intermediare din pipeline (`assets/blender/fiordland_boat_v2.blend`,
`fiordland_kayak_a_v2.blend`, `fiordland_kayak_b_v2.blend`) sunt rezultatul
procesarii descrise mai sus, nu sursa originala.
