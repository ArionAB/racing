# Brief asset — Intrare de mină (`mine_portal.glb`)

Brief auto-conținut pentru un agent Blender (ex. Blender MCP). Nu presupune
acces la restul repo-ului — tot contractul e aici. Sursele din care e derivat:
[style_bible.md](../style_bible.md) (estetică) + [blender_export.md](../blender_export.md)
(pipeline) + [scripts/palette.gd](../../scripts/palette.gd) (indici de sloturi).

Referință vizuală: `assets/dunele_inspiration/sheet_railway_diorama.png` —
**portalul de tunel săpat în stâncă** din panoul de piese (dreapta, mijloc), plus
**piesele de șină** din banda de jos și **lăzile / gardul** din același panou.

> **Prompt de dat agentului** — de la linia orizontală de mai jos în jos e
> paste-ready. Restul paginii sunt note pentru noi.

---

Construiește o intrare de mină săpată într-un perete de stâncă, cu susțineri de
lemn, șină îngustă și un vagonet răsturnat. Low-poly, stilizată, pentru un joc de
curse cu mașinuțe de jucărie în stil diorámă de deșert (ton *Art of Rally* —
machetă de masă, NU foto-realist). Rezultat: un `.glb` cu trei obiecte, care
intră într-o lume cu un singur material partajat.

**Se așază lipit de o faleză.** Construiește-l cu **spatele plat** (fața −Y în
Blender), ca să se lipească de un perete de stâncă fără să plutească.

**Formă și dimensiuni** (unitate: 1 = 1 m; mașina de referință = 4.2 m):

Trei obiecte în același fișier, cu numele **exacte**:

### `Portal` — gura minei și cadrul, ≤ 600 triunghiuri

- **Movila de stâncă** în care e săpată gura: 9 m lățime × 6.5 m înălțime × 4 m
  adâncime, un elipsoid perturbat cu vârful teșit și **spatele retezat plat**.
  Stratificare orizontală în 3 benzi, alternând două sloturi de culoare.
- **Deschiderea**: **4.0 m lățime × 3.8 m înălțime**, arcuită în partea de sus.
  Suficient cât să se citească drept „intrare pe unde încape un vagonet".
- **Gura propriu-zisă**: NU tăia gol — nu avem operații booleene. Pune un **panou
  plat retras cu 1.4 m** în interiorul deschiderii, pe slot foarte închis.
  Perspectiva și AO fac restul; de la 40 m arată ca adâncime.
- **Cadru de grinzi**: doi montanți verticali de 0.35×0.35 m la marginile
  deschiderii, o buiandrugă orizontală deasupra de 0.40 m, și **două contrafișe
  înclinate** la 45° în colțurile de sus. Grinzi groase, NU zăbrele.
- **Grindă de coronament** deasupra buiandrugului, ieșită 0.4 m în consolă de
  fiecare parte.
- **Grămadă de steril** lateral, pe dreapta: o formă turtită de 4×3×1.5 m. Ăsta e
  detaliul care spune „mină activă" mai tare decât portalul însuși.

### `MineRail` — șina care iese din gură, ≤ 250 triunghiuri

- **Două șine** de 0.10×0.12 m, la ecartament **0.9 m** (mină îngustă, nu cale
  ferată normală), lungime **9 m**, plecând din gura minei spre +Y.
- **Traverse**: 12 bucăți de 1.4×0.20×0.12 m, la interval de 0.75 m. Astea sunt
  candidatul perfect pentru un ajutor de repetiție.
- Ultimii 2 m: traversele se rar-esc și șinele se termină **frânte**, ușor
  ridicate — linia se pierde, nu se oprește curat.
- Un **opritor** de lemn la capăt, opțional.

### `MineCart` — vagonetul răsturnat, ≤ 150 triunghiuri

- Cutie de 1.6×1.0×0.9 m, **răsturnată pe o parte**, lângă șină, nu pe ea.
  Un obiect răsturnat spune o poveste; unul drept e mobilier.
- Patru roți: prismatice cu **6 laturi**, rază 0.22 m. Două se văd, două sunt
  parțial în nisip.
- Un șasiu simplu sub cutie. Fără osii modelate, fără cuplaje.
- Câteva bucăți de minereu împrăștiate: 3 forme de 0.2 m, întrepătrunse cu solul.

NU: felinare cu geam, cabluri, scări, cărucioare cu detaliu de tablă, panouri cu
text, pânze de păianjen, lilieci.

**Culoare — FĂRĂ texturi proprii. UV → sloturi dintr-un atlas de paletă** (32
sloturi orizontale). Fiecare față își colapsează toate UV-urile pe **un singur
punct**, centrul slotului:
- Grinzi, traverse, cutia vagonetului: **u = 0.296875, v = 0.5**
- Șine, roți, feronerie: **u = 0.328125, v = 0.5**
- Stâncă, benzi închise: **u = 0.140625, v = 0.5**
- Stâncă, benzi deschise: **u = 0.109375, v = 0.5**
- **Gura minei** (panoul retras) și adânciturile: **u = 0.078125, v = 0.5**
- Grămada de steril și minereul: **u = 0.046875, v = 0.5**
- Nu e nevoie să încarci vreo imagine în Blender; contează doar coordonata UV.
  Materialul se înlocuiește ulterior.

Lemnul îmbătrânit e **miezul** asset-ului. Dacă un element ezită între lemn și
metal, alege lemn.

**Vertex colors = ambient occlusion copt (grayscale), se înmulțește peste
culoare în engine:**
- Gradient vertical: jos mai închis (~0.55), sus spre 1.0.
- Întunecă **foarte puternic pe panoul din gura minei** — coboară spre **0.25**.
  Adâncimea aia falsă e tot efectul obiectului.
- Întunecă și sub buiandrug, în spatele contrafișelor, sub vagonet, între traverse.
- 1.0 = neatins, ~0.5 = adânc/umbrit. Fără el iese plat — e obligatoriu.

**Scară, origine, orientare:**
- Originea (pivotul) la **baza obiectului, centrată în XZ**, pentru fiecare din
  cele trei.
- Toate trei se **exportă la origine** (0,0,0), nu decalate.
- **Gura minei privește spre +Y în Blender**; spatele plat e spre −Y.
- Bevel **0.06 m** pe lemn și vagonet, **0.12 m** pe stâncă.
- Buget: **≤ 1000 triunghiuri** pe toate trei la un loc.

**Export:**
- glTF Binary **(.glb)**, un fișier, nume `mine_portal.glb`, cu **trei** obiecte:
  `Portal`, `MineRail`, `MineCart`, ca **copii direcți ai rădăcinii**.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere, lumini sau
  materiale complexe.
- **Apply Modifiers: ON** (bevel-ul să fie în geometrie). Y-up: implicit.

---

## Note pentru noi (nu fac parte din prompt)

- **De ce ăsta și nu alt landmark.** `style_bible.md` §7 cere 7–9 landmark-uri pe
  turul Dunelor; avem 4. Mina are un avantaj peste celelalte candidate: **se
  leagă de ce e deja în joc**. Pista are un tren care traversează șoseaua
  (`scenes/hazards/train_hazard.gd`, la `frac 0.37`). O mină cu vagonet și șină
  îngustă explică de ce există o cale ferată în mijlocul deșertului. Lumea începe
  să aibă o poveste, nu doar obiecte.
- **Cele trei obiecte separate sunt intenționate**, nu o comoditate: instanța de
  gameplay poate așeza `MineRail` și `MineCart` la distanță de portal, sau le
  poate refolosi lângă calea ferată existentă. Un obiect unic ar bloca asta.
- **Sloturi folosite:** `wood_weathered` = 9, `rust_metal` = 10, `rock_dark` = 4,
  `rock_light` = 3, `sand_shadow` = 2, `sand_mid` = 1.
- **Ecartamentul de 0.9 m e deliberat.** Șina trenului de pe pistă e de ecartament
  normal; una îngustă spune „industrială, veche, de mină" fără niciun cuvânt.
- **De raportat în PR:** o captură **de la nivelul drumului, la ~50 m**, din
  unghiul din care ar trece o mașină. Nu de sus. Testul e dacă gura minei citește
  ca adâncime sau ca o pată neagră.
- **Checklist la primire:** trei noduri cu numele exacte, copii direcți ai
  rădăcinii; ≤ 1000 tris total; spatele portalului plat; gura pe direcția
  corectă; UV pe centre; `COLOR_0`; origini la bază, toate la (0,0,0).

## Livrat (#C2)

![portalul de la 50 m și de aproape, cu șina și vagonetul](img/mine_portal_drum.png)

Stânga e captura cerută de issue: **de la nivelul drumului, la ~50 m**, cu o
mașină de 4.2 m pentru scară. Dreapta, aceeași scenă de la 20 m. Șina și
vagonetul sunt așezate manual pentru poză — sunt obiecte separate tocmai ca
instanța de gameplay să le poată pune unde vrea.

### Cote

| nod | tris | dimensiuni |
|---|---|---|
| `Portal` | **652** | 11.61 × 7.15 × 7.14 m |
| `MineRail` | **192** | 1.40 × 0.50 × 10.10 m |
| `MineCart` | **136** | 2.01 × 1.96 × 1.47 m |
| **total** | **980** / 1000 | |

- deschiderea: **4.00 × 3.80 m**, gura retrasă cu 1.40 m
- spatele plat la **Y = −3.57** față de origine; fața (gura) spre **+Y în
  Blender = −Z în Godot**
- capătul șinei dinspre gură e la **Y = −5.05** față de originea lui `MineRail`

### Golul trebuie să fie spațiu ÎNTRE mase

Brieful cere să nu se taie gol — corect, n-avem booleene — și spune să pui „un
panou plat retras cu 1.4 m în interiorul deschiderii". Prima versiune a făcut
exact asta și **nu se vedea nimic**: movila e un solid, deci panoul stătea în
interiorul ei și îl ascundea propria față din față.

Un gol care nu se taie trebuie să fie **spațiu între mase** — același principiu
ca la arcada din #C1. Movila e acum trei mase: doi umeri de 2.5 m și un capac
peste deschidere. Umerii ies înguști fiindcă o deschidere de 4 m într-o movilă de
9 m nu lasă mai mult.

Tot din prima rulare: cadrul de grinzi era la `FRONT_Y = 2.10`, iar fața movilei
ajunge la ~4.35 la înălțimea deschiderii — deci și cadrul era îngropat. Cotele de
suprafață ale unui `rock()` nu se pot presupune, se măsoară.

### Abateri de la brief

- **Gura e `asphalt` (5), nu `sand_shadow` (2).** Același motiv ca la cabina
  excavatorului din #77: `sand_shadow` e `#A97A4A`, un maro mediu, iar la render
  gura ieșea o pată maronie, nu o gaură. Argumentul e din docstring-ul lui
  `window()`: *„slotul cel mai închis din lume citește ca gol, nu ca sticlă"*.
  Adâncimea falsă e tot efectul obiectului, deci merită slotul cel mai închis.
- **Bevel 0 pe `MineRail` și `MineCart`.** Brieful cere 0.06. Măsurat: șina are
  192 de triunghiuri brute (× 3.67 = **705**, la un buget de 250), vagonetul 136
  (× 3.67 = **499**, la un buget de 150). Nu există tăiere care să le salveze —
  12 traverse *sunt* șina, patru roți *sunt* un vagonet. Și, spre deosebire de
  portal, aici bevel-ul nici nu se vede: o teșitură de 6 cm pe o traversă de
  0.20 m înseamnă 30% din piesă, adică lemn umflat, nu lemn cioplit. Clasele de
  bevel din `style_bible` §3 sunt proporționale cu obiectul.
- **`Portal` iese 652, peste cei 600 din brief.** Totalul rămâne **980 din 1000**,
  iar 1000 e constrângerea din issue; împărțirea 600/250/150 era un plan, nu un
  contract. Cele 52 în plus au plătit trecerea de la o masă la trei, adică exact
  ce face gura să se citească.
- **Cota movilei se scrie compensat.** `rock(flat_top=True)` retează vârful la
  82% din înălțimea dată, deci pentru o movilă de 6.5 m se scrie 7.93.

### Originea per piesă e corectă aici

Spre deosebire de arcada din #C1, unde cele cinci noduri formează un singur
obiect și trebuie să-și păstreze pozițiile relative, cele trei piese de aici sunt
independente prin design: brieful cere explicit ca instanța de gameplay să poată
așeza șina și vagonetul departe de portal, sau lângă calea ferată existentă. Deci
`finish(origin="base")` per obiect, și toate exportate la (0,0,0).
