# Brief asset — Kitul casei de rând victoriene (`sf_row_*.glb`)

Brief auto-conținut pentru un agent Blender extern (Blender MCP). Nu presupune acces la repo:
tot contractul e aici. Sursele din care e derivat sunt [style_bible.md](../style_bible.md),
[blender_export.md](../blender_export.md), [scripts/palette.gd](../../scripts/palette.gd), foaia
de assets [sanfrancisco_inventory.md](sanfrancisco_inventory.md) (K1, §1.2) și brief-ul pistei
`docs/track_briefs/san_francisco.md` (§0.1, §2.0, §4, §5.3, §7 pasul 0). Testul de loc de la
pasul 0 (`tools/sf_loc_decor.gd`, case construite din cod) a fixat gabaritul și paleta. Kitul
le transformă în GLB-uri.

Sursa reproductibilă (de creat de agent): `tools/blender/build_sf_row.py`.

> **Prompt de dat agentului:** de la linia orizontală de mai jos în jos e paste-ready. Restul
> paginii sunt note pentru noi. **Se livrează întâi pilotul (§9)**, se măsoară în joc, apoi
> restul.

---

## 1. Ce construiești

Un **kit de case victoriene de lemn, lipite în rând**, low-poly și stilizate, pentru un joc de
curse cu mașinuțe de jucărie în stil dioramă (ton *Art of Rally*: machetă de masă, NU
foto-realist). Orașul e un oraș american pe dealuri abrupte, la ora aurie: străzi drepte trase
peste dealuri, case pastel cu bovindouri, ale căror acoperișuri coboară în trepte odată cu
strada. Rezultatul: **7 fișiere `.glb`**, câte o casă fiecare.

## 2. Rolul lui în cadru

Casele sunt **35 % din ce vede jucătorul**. Ele fac recunoașterea locului în 3 secunde: „case
pastel în trepte, strada care cade”. Camera e la 10 m deasupra drumului, 12,5 m în spate, privind
în jos la 29°. O casă de 3 niveluri (10–13 m) **intră întreagă în cadru de aproape**. Fațadele
stau la 10,5 m de axa drumului, deci se văd din 3/4, de sus, la 10–60 m: bovindoul, cornișa,
ancadramentele albe, intrarea. Rândurile din spate se văd de la 60 la 300 m, mai ales prin
acoperișuri.

**Testul de reușită:** un rând de 6 case lipite pe o stradă în pantă de 28 %, în cinci culori,
citește „San Francisco / case victoriene” din camera de joc. Acoperișurile coboară în trepte, iar
fiecare bovindou își aruncă umbra pe fațadă.

**Ce NU e:** nu casă americană de suburbie (fără curte în față, fără gard alb), nu Jodhpur (fără
cuburi tencuite), nu Kyoto (fără lemn închis, fără streșini adânci).

## 3. Formă și dimensiuni

Unitate: 1 = 1 m; mașina de referință are 4,2 m.

### 3.1 Gabaritul comun (toate casele în afară de colț)

- **Amprenta: 7,0 m lățime (X) × 12,0 m adâncime (Z).** X de la −3,5 la +3,5, Z de la **−6,0
  (fațada, spre stradă)** la +6,0 (spatele). Casele se lipesc lateral, deci pereții laterali sunt
  **orbi** (fără ferestre, fără streașină care iese lateral peste ±3,5).
- **Podeaua parterului la Y = 0.** Trei niveluri de 3,2 m: parter (garaj) 0–3,2, etajul 1
  3,2–6,4, etajul 2 6,4–9,6. Streașina la **+9,6**.
- **Soclul (inclus în fiecare casă):** o fustă de beton **la fața pereților** (nu iese nici în
  față, nici lateral) de la Y = 0 până la **Y = −2,4**, pe toate cele patru laturi. Pe strada în
  pantă, jocul așază podeaua la cota trotuarului din capătul de **sus** al casei. Pe latura de
  vale, trotuarul coboară, iar fusta rămâne la vedere ca o pană. Pe 28 %, o casă de 7 m coboară
  1,96 m față de vecina ei, iar 2,4 m acoperă și asta, și îngroparea. **Nu modela pana**: terenul
  o taie singur din fusta dreaptă.
- **Parterul:** pe jumătatea **+X**, ușa de garaj (2,6 × 2,4 m, adâncită 0,12 m, cu panouri
  orizontale în relief). Pe jumătatea **−X**, **intrarea adâncită**: o nișă de 1,4 m lățime și
  1,0 m adâncime în fațadă, cu ușa (1,0 × 2,3 m, cu fereastră deasupra) în fundul nișei, la
  Y = 0, și o **scară de 7 trepte care coboară în nișă**, de la Y = 0 la Y = −2,1, prin fustă.
  Pe stradă plată, treptele de jos se îngroapă singure. **Nimic nu iese din planul fațadei sub
  +3,3 m**: scările sunt în nișă, nu pe trotuar.
- **Bovindoul** (pe jumătatea +X, deasupra garajului): de la **Y = +3,3 la +9,35**, iese
  **0,9 m** din fațadă (până la Z = −6,9). Două forme (§3.2): teșit (trei fețe, cele laterale la
  45°, fața de 2,6 m) sau pătrat (2,8 m lățime). Câte o fereastră pe fiecare față și pe fiecare
  etaj. Console albe dedesubt, cornișă albă deasupra. **Umbra lui pe fațadă ține pastelul să nu
  fie plat**, deci ieșirea de 0,9 m nu se micșorează.
- **Jumătatea −X a etajelor:** câte două ferestre înalte (0,95 × 1,85 m) pe etaj, adâncite
  0,1 m, cu ancadrament alb și cornișă mică deasupra.
- **Brâul alb** între parter și etajul 1 (la +3,2, 0,25 m înalt, iese 0,06 m) și **scândurile
  albe de colț** (verticale, la X ±3,45, pe toată înălțimea).
- **Peretele e neted.** Scândura orizontală o dă **textura**, la integrare. Nu modela scânduri.
- **Spatele:** simplu, cu 4–6 ferestre și o streașină. **Fără scară de incendiu** (e subțire și
  sclipește pe telefon).

### 3.2 Cele 7 case

| fișier | fațada | bovindoul | acoperișul (vizibil de pe stradă) |
|---|---|---|---|
| `sf_row_a_canted.glb` | **A, Italianate**: ferestre înalte cu „sprâncene” (cornișe arcuite) | teșit | plat, ascuns de o **cornișă grea cu console** (0,7 m înaltă, iese 0,45 m), deasupra lui +9,6 |
| `sf_row_a_square.glb` | A | pătrat | ca mai sus |
| `sf_row_b_canted.glb` | **B, Queen Anne**: fronton spre stradă | teșit | **două ape**, coama pe Z, fronton triunghiular pe fațadă (+9,6 → +12,6), bordură albă pe muchii, **solzi** în fronton ca 3–4 benzi în relief (nu solzi mici) |
| `sf_row_b_square.glb` | B | pătrat | ca mai sus |
| `sf_row_c_canted.glb` | **C, Stick**: montanți verticali albi în relief pe fațadă | teșit | **fațadă falsă**: un atic drept care urcă la +10,8 și ascunde acoperișul în pantă din spate |
| `sf_row_c_square.glb` | C | pătrat | ca mai sus |
| `sf_row_corner_turret.glb` | **colțul de intersecție** | turnuleț | amprenta **9,0 × 12,0 m**, două fațade (−Z și −X, ambele la stradă); pe colțul (−X, −Z) un **turnuleț octogonal** ⌀ 3,2 m, de la +3,3 până la +12,5, cu acoperiș conic până la +15,0. Pereții +X și +Z sunt orbi (se lipesc de vecini) |

> Regula de înălțime (brief §2.0): nimic peste 4 niveluri lângă drum. Toate au 3; turnulețul e
> punctul cel mai înalt, la 15 m.

## 4. Orientare

Fațada privește spre **−Z în Godot**, adică **+Y în Blender**: exportatorul glTF face `(x, y, z) →
(x, z, −y)`, deci Blender +Y devine Godot −Z. „+X” e același în ambele. Garajul e pe +X,
intrarea pe −X. Jocul oglindește casa când are nevoie de garaj pe cealaltă parte.

## 5. Culoare — FĂRĂ texturi proprii

UV → sloturi dintr-un atlas de paletă (32 de sloturi orizontale). Fiecare față își colapsează
toate UV-urile pe **un singur punct**, centrul slotului: `u = (slot + 0,5) / 32`, `v = 0,5`. Nu
încarci nicio imagine.

**Două noduri pe casă, unul per material:**
- **`Row_Wall`**: doar pereții de scândură (fațada, laturile, spatele, fețele bovindoului, pereții
  turnulețului). În GLB, pe slotul **19 `coral_sand`** (u = **0.609375**, `#E9DCC0`). La
  integrare, jocul pune pe acest nod textura de scândură într-unul din cele cinci pasteluri
  (crem, roz, albastru-pal, mentă, galben-unt). **Tot ce nu e scândură iese din nodul ăsta**,
  altfel se vopsește și el în pastel.
- **`Row_Trim`**: tot restul, pe atlas:

| slot | nume | **u** | hex | unde |
|---|---|---|---|---|
| 22 | `foam_white` | **0.703125** | `#E9F2F0` | ancadramente, cornișe, console, brâu, scânduri de colț, bordura frontonului, ramele ferestrelor |
| 20 | `volcanic_black` | **0.640625** | `#55535A` | acoperișurile, sticla ferestrelor (ușor adâncită) |
| 8 | `concrete` | **0.265625** | `#C8BDA9` | soclul (fusta), treptele |
| 9 | `wood_weathered` | **0.296875** | `#835C34` | ușa de garaj |
| 28 | `log_dark` | **0.890625** | `#4A3526` | ușa de intrare, interiorul nișei |
| 10 | `rust_metal` | **0.328125** | `#91461E` | (opțional) felinarul de lângă ușă, numărul casei NU (fără cifre) |

**Interzise:** 14, 15, 16 (culorile mașinilor), 30, 31. Fără text, fără cifre, fără steaguri.

## 6. Vertex colors = AO copt

Un strat de Color Attribute, gri, care se înmulțește peste culoare. 1,0 = neatins, ~0,5 = adânc.
**Obligatoriu**, dar **blând pe pereți**: un gradient tare le fură tocmai luminozitatea pastelului.

- `Row_Wall`: gradient vertical **0,78 la bază → 1,0 sus**; ~0,7 sub bovindou și sub cornișă.
- `Row_Trim`: nișa intrării ~0,55, golurile ferestrelor ~0,6, sub console ~0,6, fusta 0,7 → 0,85.
- Eșantioane: 64 pe pereți (suprafețe mari), 32 în rest.

## 7. Scară, origine, bevel

- Originea la **(0, 0, 0) = centrul amprentei, la nivelul podelei parterului** (nu la fundul
  fustei). Colțul: centrul amprentei de 9 × 12 m.
- Scara 1 și rotația 0 aplicate pe nodul rădăcină.
- Bevel **0,08 m** pe muchiile exterioare ale volumului, cornișelor și bovindoului (clădire).
  **Fără bevel** pe ferestre și pe muchiile ascunse între case.

## 8. Triunghiuri

Casele se repetă de **sute de ori** pe pistă. Aici contează fiecare triunghi. Țintă **≤ 2.500 pe
casă** (Row_Wall + Row_Trim), ≤ 3.500 colțul, măsurate după bevel. Bevelul înmulțește cu ~3,7,
deci se pune doar pe muchiile care fac silueta. Fețele din spate și laterale: minimul. Fără
balustrade subțiri, fără scări de incendiu, fără ornamente sub 0,08 m.

## 9. Pilotul — se livrează întâi, singur

**`sf_row_b_canted.glb`** (Queen Anne, bovindou teșit), cu tot ce cere §3–§8. Plus un randaj de
control: **un rând de 6 copii** lipite (la 7,0 m), pe o stradă în pantă de 28 % (fiecare casă
coborâtă cu 1,96 m față de cea de dinainte), văzut **dintr-o cameră la 10 m peste stradă și
12,5 m în spatele unui punct de pe axa ei, privind în jos la 29°, FOV vertical 68°**, cu fațadele
la 10,5 m de axa străzii. Restul de 6 case vin după ce pilotul e acceptat.

## 10. Export

- Câte un glTF Binary (.glb) pe casă, cu numele din §3.2.
- În fiecare: **exact două noduri-mesh**, `Row_Wall` și `Row_Trim`, copii direcți ai rădăcinii.
  Fără noduri goale, **fără coliziune și fără proxy `_col`**: jocul face coliziunea singur.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere, lumini, texturi.
- **Apply Modifiers: ON.** Y-up: implicit.
- Înainte de livrare: tipărește AABB-ul în coordonate Godot și triunghiurile pe nod. Verifică:
  X ±3,5 (±4,5 la colț), fața la Z = −6,0 cu bovindoul până la −6,9, Y de la −2,4 la cel mult
  +12,6 (+15,0 la colț).

---

## 11. Note pentru noi (nu fac parte din prompt)

**Consumatorii (inventarul §1.2):**
- **Rândul din față (≤ 40 m de drum):** noduri `DecorManual` scrise de generator, cu podeaua la
  cota trotuarului din capătul de sus + bordura (0,15), ca la `tools/sf_loc_decor.gd:298–301`. GLB-ul
  are `metadata/coliziune = "none"`, iar coliziunea o scrie generatorul ca **cutie pe planul
  fațadei**, 7 × 12 m, de la −2,4 la +9,6 (tiparul `Corp_<n>` din `sf_loc_decor.gd`). Motivul:
  hull-ul convex implicit (`world_prop.gd:60–96`) ar include bovindoul, adică un zid invizibil pe
  trotuar, la 0,9 m în fața garajului. `WorldProp` nu citește proxy-uri `_col` din GLB.
- **Rândurile din spate:** `CityFill` cu `row_mode`, `row_house_w = 7.0`, `row_front_m = 6.0`
  (originea e în centrul amprentei), `row_back_to_back_m = 12.0`. Treptele de acoperiș ies fără
  cod, iar fusta rămâne îngropată (casa e la cota de jos). Ca fusta să se vadă: o opțiune de
  „casa la `hmax`” (inventarul §1.2).
- **Cele cinci pasteluri** cer o decizie (inventarul §1.2, §7 punctul 1): o listă de clase de
  perete în `CityFill` și o metadata pe instanță în `WorldProp`, sau cinci copii de fișier pe
  casă. Kitul nu se schimbă în niciuna. Clasele există (`palette.gd:987–991`, tentele
  `:1352–1356`). Maparea `Row_Wall` → clasă se face pe prefix (`Palette._class_for`,
  `palette.gd:2614`), în `CLASSES_BY_MODEL` / `CLASSES_BY_THEME`.
- **Oglindirea** (garaj pe stânga): `scale.x = −1` pe instanță. **De verificat la integrare** că
  umbrirea iese corectă și în `MultiMesh`-ul din `CityFill`. Dacă nu, se cer variante `_m`.

**Checklist la primire:**
```
python tools/blender/verify_glb.py assets/models/sanfrancisco/buildings/sf_row_b_canted.glb 2500 --front=-Z
```
`verify_glb` verifică baza la Y = 0. Aici fusta coboară la −2,4, deci se așteaptă un avertisment
pe bază. Garda reală e AABB-ul din §10. Apoi pilotul se pune pe strada sintetică a pasului 0
(`tools/SfLoc.tscn`, în locul caselor din cod) și se refac măsurătorile de acolo cu
`bash tools/sf_loc_measure.sh`: ΔV soare/umbră ≥ 0,28, ΔE2000 între pasteluri ≥ 10, fracția de
carosabil la soare pe lanț ≥ 80 %. Criticul orb de la pasul 0 a spus: (1) casele par „forfecate”
(perspectiva camerei; nu se corectează din case), (4) **soclurile ieșeau pe trotuar ca trepte**.
Kitul corectează (4): fusta e la fața peretelui, iar scara e în nișă, nu pe trotuar.

**Materiale:** 5 (pastelurile) + atlasul (deja numărat). Bugetul e în inventar, §2.

**LOD și umbre (CLAUDE.md, inventarul §4):** LOD-urile vin din import. `CityFill` le poartă
(`generate_lods`, `city_fill.gd:72`). Umbra pe rândurile din spate prin `shadow_proxy`
(`:81`). Riscul GPU al pistei sunt casele (brief §6): se măsoară cu `ProbePerf --attrib`.

## 12. Abateri și dependențe

- **Fațada de la intrarea în serpentine (E') stă la 4 m de carosabil, nu la 1 m** (pasul 6,
  PR #735; decizia dezvoltatorului, 15 nov 2026). Acolo erau 4 din 7 ejectări din serpentine,
  pe exteriorul primului viraj de 90°. Kitul nu se schimbă: la plasare, generatorul lasă în fața
  acelei case **trotuar lat sau o grădină** (strat ridicat de hortensii, ca în serpentine), nu
  gol de teren.

- **Fusta dreaptă în loc de soclul-pană care se scalează cu panta** (brief §5.3): același efect
  vizual, fără scalare neuniformă. Terenul și trotuarul taie pana singure, iar o singură piesă
  merge pe orice pantă până la ~30 %.
- **Scara de la intrare e în nișă, nu în fața casei:** corectura criticului de la pasul 0 și a
  coliziunii (nimic pe trotuar).
- Lângă case: semaforul atârnat (M2), felinarele (M3), mașinile parcate perpendicular (M1),
  chiparoșii de pe coamă (V1). Casele pictate de la coamă (K2) vin din acest kit, mai bogate,
  după pilot.
