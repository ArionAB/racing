# Brief asset — Arcadă de stâncă (`rock_arch.glb`)

Brief auto-conținut pentru un agent Blender (ex. Blender MCP). Nu presupune
acces la restul repo-ului — tot contractul e aici. Sursele din care e derivat:
[style_bible.md](../style_bible.md) (estetică) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

Referință vizuală: `assets/dunele_inspiration/sheet_scale_rocks_cactus_barrels.png`,
rândul **LARGE (6–10m)**, ultima formă din dreapta — arcada. Stilul de
stratificare din tot rândul ăla e exact ce vrem.

**Atenție la scară:** arcada din foaie e de 6–10 m. A noastră e mult mai mare,
fiindcă trebuie să treacă peste o șosea de 14 m. Ia din foaie **stilul de
stâncă**, nu cotele.

> **Prompt de dat agentului** — de la linia orizontală de mai jos în jos e
> paste-ready. Restul paginii sunt note pentru noi.

---

Construiește o arcadă naturală de stâncă peste o șosea — un pod erodat pe sub
care trec mașinile. Low-poly, stilizată, pentru un joc de curse cu mașinuțe de
jucărie în stil diorámă de deșert (ton *Art of Rally* — machetă de masă, NU
foto-realist). Rezultat: un `.glb` cu patru obiecte, care intră într-o lume cu un
singur material partajat.

## ⚠️ Deschiderea și degajarea sunt cote de gameplay

> ### Deschidere liberă între picioare: minimum **20 m** la bază.
> ### Degajare verticală deasupra solului: minimum **9 m**, pe toată lățimea de 20 m.

Șoseaua are 14 m de asfalt plus umeri; mașinile trec pe sub arcadă **în aer**,
după sărituri. Mai îngust și se lovesc de picioare la depășire; mai jos și ai un
plafon invizibil care omoară curse.

Degajarea de 9 m se măsoară în punctul cel mai jos al intradosului, nu la mijloc.

**Formă și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4.2 m):

Patru obiecte în același fișier, cu numele **exacte**:

### `Arch_L` și `Arch_R` — picioarele (vizuale)

- **Asimetrie obligatorie.** `Arch_L` gros și eroziat la bază: amprentă ~9×7 m,
  înălțime până la naștere ~10 m. `Arch_R` mai zvelt: amprentă ~6×5 m, până la
  ~11 m. O arcadă simetrică arată construită, nu erodată.
- Fiecare picior: 2–3 mase suprapuse care se **întrepătrund**, nu o formă
  continuă. Fiecare masă = un elipsoid perturbat cu 7–8 laturi pe orizontală și
  4–5 inele pe verticală, cu vârful teșit.
- **Stratificare orizontală vizibilă**: 3–4 benzi care alternează două sloturi de
  culoare. Nu modela crăpături — alternanța de valoare face toată treaba și costă
  zero triunghiuri. (Dacă ai ajutorul `retag()`, e exact cazul lui.)
- Bazele se lărgesc într-o poală de grohotiș — o treaptă de 1.5 m înălțime în
  jurul fiecărui picior.

### `Arch_Span` — traversa

- De la ~10 m la **15–17 m** înălțime totală, întinsă între vârfurile picioarelor.
- **Intradosul** (fața de dedesubt) e o curbă lină, nu o linie dreaptă — punctul
  cel mai jos la 9 m, urcând spre picioare. E ce face arcada să arate erodată de
  apă.
- Grosime la cheie ~2.5 m, îngroșându-se spre nașteri până la ~5 m.
- Aceeași stratificare ca la picioare, continuând vizual peste ele.

### `Arch_col` — proxy de coliziune

- **Două cutii simple**, una per picior, într-un singur obiect. Fiecare aliniată
  pe amprenta piciorului, ușor **mai mică** decât vizualul (cu ~0.4 m pe fiecare
  latură), înălțime până la 8 m.
- **Traversa NU primește coliziune.** Nicio mașină n-ar trebui s-o atingă, iar o
  formă concavă acolo e o capcană.
- 12 triunghiuri per cutie. Fără bevel, fără AO fină — obiectul e invizibil.

NU: vegetație pe arcadă, cuiburi, găuri modelate în traversă, praf, pietricele
plutitoare.

**Culoare — FĂRĂ texturi proprii. UV → sloturi dintr-un atlas de paletă** (32
sloturi orizontale). Fiecare față își colapsează toate UV-urile pe **un singur
punct**, centrul slotului:
- Benzi de stâncă închisă: **u = 0.140625, v = 0.5**
- Benzi de stâncă deschisă: **u = 0.109375, v = 0.5**
- Intradosul traversei (fața de dedesubt) și adânciturile: **u = 0.078125, v = 0.5**
- Poala de grohotiș de la bază: **u = 0.046875, v = 0.5**
- Nu e nevoie să încarci vreo imagine în Blender; contează doar coordonata UV.
  Materialul se înlocuiește ulterior.

Intradosul întunecat e ce face arcada să pară **grea**. Nu-l sări.

**Vertex colors = ambient occlusion copt (grayscale), se înmulțește peste
culoare în engine:**
- Gradient vertical: jos mai închis (~0.55), sus spre 1.0.
- Întunecă **puternic sub traversă** — coboară spre 0.35 pe intrados. Ăsta e
  efectul principal: umbra de sub arcadă.
- Întunecă și unde masele se întrepătrund, și la baza picioarelor.
- 1.0 = neatins, ~0.5 = adânc/umbrit. Fără el iese plat — e obligatoriu.

**Scară, origine, orientare:**
- Originea (pivotul) la **baza obiectului, centrată în XZ**, pentru fiecare din
  cele patru. Centrul XZ = mijlocul deschiderii, adică sub cheia arcadei.
- Toate patru se **exportă la origine** (0,0,0), nu decalate.
- Axa deschiderii (direcția în care trece drumul) pe **Y în Blender**.
- Bevel **0.15 m** pe vizuale (fațete mari, rotunjire generoasă), **0** pe `Arch_col`.
- Buget: **≤ 1000 triunghiuri** pentru cele trei vizuale la un loc, **≤ 24**
  pentru coliziune.

**Export:**
- glTF Binary **(.glb)**, un fișier, nume `rock_arch.glb`, cu **patru** obiecte:
  `Arch_L`, `Arch_R`, `Arch_Span`, `Arch_col`, ca **copii direcți ai rădăcinii**.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere, lumini sau
  materiale complexe.
- **Apply Modifiers: ON** (bevel-ul să fie în geometrie). Y-up: implicit.

---

## Note pentru noi (nu fac parte din prompt)

- **De ce ăsta e cel mai important asset din lot.** `style_bible.md` §7 cere un
  landmark dominant la fiecare 4–6 secunde — 7–9 pe turul Dunelor. Avem 4. Dar
  toate patru au același defect: **treci pe lângă ele**. Arcada e singura prin
  care **treci**. Un tur cu un moment prin care intri e un tur pe care ți-l
  amintești.
- **Tiparul de proxy de coliziune** e în `tools/blender/build_cliff_wall.py:94-107`,
  iar convenția de nume `X` ↔ `X_col` e documentată în
  [cliff_wall.md](cliff_wall.md). Aici am strâns cele două cutii într-un singur
  obiect fiindcă vizualele sunt trei și o corespondență 1:1 n-ar avea sens.
- **`rock()` din `dio_lib` e unealta.** `build_cliff_wall.py` arată cum, cu
  `strata_slots` și `wall_axis`. Golul de sub arcadă **nu se taie** — nu avem
  operații booleene; e spațiul dintre cele trei mase.
- **Sloturi folosite:** `rock_dark` = 4, `rock_light` = 3, `sand_shadow` = 2,
  `sand_mid` = 1.
- **Partea instanței de gameplay:** intrare în `_LANDMARKS` (`track.gd:1357`), o
  poziție în `custom_landmarks` din `Track01.tscn`, și o **degajare la faleze**,
  ca `TrackCliffs` să nu ridice un zid prin arcadă (`LANDMARK_CLEAR` e deja 25 m,
  probabil ajunge).
- **De raportat în PR:** bbox-ul printat (dovadă pentru deschidere și degajare) și
  o captură **de la nivelul drumului, din față, la ~60 m**. Vederea de sus minte
  despre cum se citește o arcadă.
- **Checklist la primire:** patru noduri cu numele exacte; deschidere ≥ 20 m;
  degajare ≥ 9 m pe toată lățimea; ≤ 1000 tris vizibile; UV pe centre; `COLOR_0`.
