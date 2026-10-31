# Brief assets — Carrara (`Track23`, temă `carrara`) — kit v1

**Contractul complet pentru setul de assets (Blender).** E făcut pe tiparul
`transfagarasan_kit.md`. Regulile generale sunt în `docs/blender_export.md` și
`docs/style_bible.md` §4. Brief-ul pistei e `docs/track_briefs/carrara.md`:
- §0.1 regula de artă (riscul nr. 1: „pare iarnă”);
- §3 hazardele și consumatorii lor;
- §4 paleta (**niciun slot de zăpadă**);
- §5 assets, cu trecerea de contracte din cod la §5.6;
- §8 legalul (fără mărci pe utilaje) și ce s-a respins;
- §9 prompturile ChatGPT, iar §9.2 rezultatul lor.

**Fidelitatea față de planșă e criteriu de acceptare, nu inspirație** (§0.1
de mai jos). Fiecare desen are propria decupare și se livrează cu o
comparație alăturată.

| fișier | ce e | ce iei din el |
|---|---|---|
| `docs/track_briefs/img/carrara_assets_v1/<nume>.png` | **decuparea piesei** din planșa acceptată, mărită 2×, una pentru fiecare dintre cele 37 de desene. Le face `tools/blender/crop_carrara_sheet.py`, iar montajul de control e `_control.png`. Sufixul **`_b`** (`quarry_truck_b`, `quarry_excavator_b`, `wire_saw_b`, `chain_saw_crawler_b`, `drill_rig_b`, `apuan_ridge_b`) vine din a doua generare, unde piesa e desenată mai mare | **referința de lucru a piesei:** silueta, numărul de elemente, proporțiile interne, culorile. Unde există și `_b`, silueta e cea fără sufix, iar `_b` arată detaliul. `_scale_car` e mașinuța de scară, nu se modelează |
| `docs/track_briefs/img/carrara_plan/inventar_v01_a.jpg` | planșa acceptată (8 rânduri) | ordinea și ansamblul. **NU dimensiuni:** viaductul e cât trei case, stâlpul de 18 m cât biserica |
| `docs/track_briefs/img/carrara_plan/inventar_v01_b.jpg` | a doua generare | utilajele mai mari, creasta cu mai multe vârfuri. Derrick-ul de aici ține un bloc: **nu** se modelează blocul pe derrick (corectura de mai jos) |
| `docs/track_briefs/img/carrara_plan/diorama_v01_iter2.jpg` | diorama acceptată | atmosfera, paleta în lumina joasă de vară, cum stau piesele împreună. **Nu stilul** (e pictată) și **nu cotele**: pe dioramă E e la nivelul fundului carierei, în joc e la +45 (brief §9.2) |
| `docs/track_briefs/img/carrara_plan/diorama_v01_iter1.jpg` | prima generare | nimic de modelat; păstrată pentru istoric |
| `docs/track_briefs/img/carrara_plan_adnotat.png` | planul real al pistei | unde stă fiecare piesă; nu îl folosești la modelare |

**Corecturi decise de coordonator (suprascriu planșa):**
- **Utilajele NU sunt galben de construcții.** Pe planșă sunt galben
  saturat. Brief §4: galben-spălăcit `DRY_VEGETATION` 13 + rugină
  `RUST_METAL` 10. `CAR_YELLOW` 16 e interzis fără excepție: e al Taxiului.
  Aceeași regulă pentru semnele galbene;
- **`quarry_truck` e o basculantă rigidă îngustă, nu un dumper minier.** Pe
  planșă iese un camion de carieră de 3,6 m lățime. Contractele camioanelor
  (99–100% din mașini pe banda opusă, 1–2% contacte în ace) s-au **măsurat
  cu cutia camionului Kamaz, 2,68 m lat**, pe un drum de 9 m. Un camion mai
  lat schimbă culoarul liber și invalidează măsurătoarea. Cotele sunt în
  §1.1; proporțiile de jucărie (roți mari, cabină scurtă) rămân;
- **`derrick` NU ține bloc.** Codul agață sarcina separat
  (`marble_block_hooked`) și desenează singur cablul. Pe derrick rămân
  catargul, brațul și cârligul;
- **`quarry_excavator` are furcă, nu cupă**, iar riggul copiază
  `rusted_digger.glb` (§1.1): coliziunea brațului din cod e o cutie fixă
  potrivită pe acel rig;
- **fără vegetație și fără bolovani lipiți pe clădiri, viaduct și
  portaluri.** Chiparoșii, tufele și pietrele de la baza bisericii, a
  caselor, a viaductului și a portalului Marmifera se pun la integrare
  (MultiMesh și `DecorManual`). Excepție: mușchiul de pe zidăria portalului
  Marmifera, care e pată de culoare pe piatră, nu masă;
- **rezervorul de apă NU e albastru saturat.** E pe `PAINTED_METAL` 11
  (`#7692A8`, gri-albăstrui), ca orice tablă vopsită veche;
- **nimic alb.** `FOAM_WHITE` 22 nu apare pe nicio piesă (brief §4).
  Marmura e crem (`CORAL_SAND` 19), iar ce pe planșă pare alb e crem în
  lumină;
- **fără text, cifre sau logo-uri** nicăieri: semnele au doar pictograme,
  utilajele n-au marcă, numere sau plăcuțe lizibile;
- **cotele vin din tabelele de mai jos**, NU din planșă.

## 0. Regulile care nu se negociază

1. **Categoria** e
   `assets/models/carrara/{structures,buildings,props,vehicles,rocks,effects}/`.
   `dio_lib.export_glb` primește calea cu categorie
   (`"carrara/vehicles/quarry_truck.glb"`).
2. **Asset nou = fișier nou.** Nu se suprascrie nimic din alte categorii.
   Piesele refolosite (§1.7) rămân unde sunt.
3. **Setul de piese nu atinge `scenes/` și `scripts/`.** Coordonatorul se
   ocupă de:
   - clasele (`carrara_marble`, `tf_stone`, `roof_tiles`, toate deja pe
     main) și intrările din `CLASSES_CARRARA` / `SLOTS_CARRARA`
     (`world_prop.gd`);
   - schimbarea modelelor pe hazarde (`BusHazard.model`, `crane_model`,
     `slab_model`, modelul `RockfallHazard`, modelul excavatorului);
   - `DecorManual` și montarea în `Track23.tscn`.

   Aici se livrează: GLB, build script, preview, verify, inventar și
   comparații.
4. **Paletă: zero sloturi noi** (32 din 32 ocupate). Celelalte reguli de
   export:
   - UV1 colapsat pe centrele sloturilor;
   - AO copt în vertex colors;
   - origine la bază (excepțiile sunt în tabel);
   - scară metrică;
   - **scala aplicată pe fiecare nod rădăcină** (memoria
     `scala-glb-neaplicata-la-radacina`).

   „Înainte” e −Z în Godot = **+Y în Blender**. „Dreapta” e +X în ambele.
   Fața bogată a clădirilor stă pe +Y și se **măsoară** pe GLB, nu se
   presupune.
5. **Sloturile pe roluri** (tabelul de mai jos). Culoarea finală a
   marmurei și a zidăriei o dă clasa, nu slotul.
6. **Piesele care primesc clasă la integrare se sparg la export în noduri cu
   un singur material** (memoria `clase-pe-piese-de-kit`), cu sufixele din
   tabel: `*_Marble`, `*_Stone`, `*_Roof`, `*_Brick`. **Offsetul de origine
   se calculează o dată pe ansamblu.** Verificarea e
   `verify_glb.py --origin=assembly`.
7. **Ce NU e geometrie:** venele marmurei, dungile fine de fir, granulația
   prafului și a zidăriei. Toate vin din clasa `carrara_marble` (dungile
   ies din cota lumii, perioadă 0,7 m). **Ce ESTE geometrie:** formele care
   schimbă silueta sau umbra:
   - **fețele tăiate drept** ale blocurilor, cu muchiile vii (fără teșire
     rotundă: marmura tăiată cu fir are colțuri drepte);
   - **spărturile** blocurilor informe și ale molozului (fațete mari, nu
     zgomot);
   - **zimții** stâlpilor și ai ramei portalului galeriei (blocuri vizibile
     ca mase);
   - **arcele și pilele** viaductului;
   - **șenilele, roțile, brațele** utilajelor.

   Regula: „se vede ca formă la 30 m din mașină?”.
8. **Marmura se citește pe două tonuri:** fața în lumină pe `CORAL_SAND` 19
   și baza pe `MARBLE_GREY` 29 (patina), ca **noduri separate** (`*_Marble`
   și `*_MarbleBase`), fiindcă două sloturi pe același corp cu clasă
   triplanară se șterg reciproc (memoria `benzi-vertex-color-bisect`).
   `MARBLE_GREY` nu stă niciodată singur pe o față mare (brief §4). Dârele
   de rugină sunt fâșii înguste `LARCH_RUST` 27, nod `*_Rust` pe atlas.
9. **Fără text, fără cifre, fără logo-uri.**
10. **Primitive rotunde: setează `segments`** (6–12). Asta contează la
    roțile camionului, volantul mașinii de fir, tamburul cablului,
    rezervoare, conducte, lămpi și arcele viaductului (12–16 pe arc).
11. **Verificarea e din fișier, nu din memorie:**
    - `verify_glb.py` pe fiecare GLB;
    - `preview_carrara.py` randează **din GLB-urile exportate**;
    - verdictul setului e `bash tools/blender/verify_carrara.sh` →
      `VERDICT KIT: OK` **și** comparațiile de fidelitate aprobate (§0.1).

    `verify` verde nu e livrare (memoria
    `harnasul-de-kit-nu-vede-forma-nici-culoarea`).
12. **Randările rulează pe GPU.** Înainte de orice randare Blender/Godot cu
    fereastră: `mkdir D:/GameDev/.render_lock`. Dacă eșuează, alt proces
    randează, deci aștepți. `rmdir` imediat după.

### Sloturi pe roluri

Doar sloturi existente (`scripts/palette.gd`, constantele din `dio_lib.py`).
Hexul slotului e trecut ca să se vadă de ce s-a ales. Ținta din brief §4 se
atinge cu clasa, la integrare.

| rol | slot (în GLB) | clasă la integrare (nu o faci tu) |
|---|---|---|
| marmura în lumină (blocuri, stâlp, rama galeriei, pilele viaductului, moloz, blocurile din bena camionului și de pe sanie) | **`CORAL_SAND` 19** (`#E9DCC0`) | `carrara_marble` pe `*_Marble` |
| patina bazei marmurei (treimea de jos a fețelor mari) | `MARBLE_GREY` 29 (`#B8B4AC`), doar ca nod `*_MarbleBase` | `carrara_marble` pe `*_MarbleBase` |
| dârele de rugină pe marmură | `LARCH_RUST` 27 (`#A8683A`), fâșii înguste | — (`*_Rust`, atlas) |
| marcajul de vopsea de pe blocuri (o dungă de 10 cm) | `LAVA_ORANGE` 30 (`#E8622D`), sub 1 m² în tot kitul | — |
| vopseaua utilajelor (galben-spălăcit) | **`DRY_VEGETATION` 13** (`#AF9F4E`) | — |
| rugina utilajelor (bene, lanțuri, cârlig, volant, catargul derrick-ului, rezervorul de motorină) | `RUST_METAL` 10 (`#91461E`) | — |
| cauciucuri, șenile, hidraulică, geamuri, goluri | `VOLCANIC_BLACK` 20 (`#55535A`) | — |
| praful de pe utilaje (aripi, șenile, partea de jos) | `SAND_SHADOW` 2 (`#915D27`), pete mici | — |
| tabla vopsită veche (rezervorul de apă, conductele, șinele) | `PAINTED_METAL` 11 (`#7692A8`) | — |
| containerul de birou | `CONCRETE` 8 (`#C8BDA9`), rama `ASPHALT_EDGE` 6 | — |
| lemnul (sania, traversele, tamburul, vagonetul, ușile, obloanele) | `WOOD_WEATHERED` 9 (`#835C34`), umbrit `LOG_DARK` 28 | — |
| obloanele verzi ale caselor | `CACTUS_GREEN` 12 (`#5B7C34`) | — |
| piatra satului și a portalului Marmifera | `MARBLE_GREY` 29 | `tf_stone` pe `*_Stone` |
| țigla | `TILE_TERRACOTTA` 23 (`#C4784F`) | `roof_tiles` pe `*_Roof` |
| cărămida viaductului | `TILE_TERRACOTTA` 23 | `roof_tiles` pe `*_Brick` |
| mușchiul de pe portalul Marmifera | `TROPICAL_GREEN` 21, pete | — |
| câmpul semnelor | `DRY_VEGETATION` 13; pictograma și chevronul `VOLCANIC_BLACK` 20 | — |
| sticla lămpilor (portalul galeriei, `work_lamp`) | `SAND_LIGHT` 0 (`#E8C074`), nod `*_Glow` | integrarea o poate aprinde |
| fundalul: vârfuri / dâre de moloz / pădurea de la bază | `MARBLE_GREY` 29 / `CORAL_SAND` 19 / `TROPICAL_GREEN` 21 + `DRY_VEGETATION` 13 | — |

> **De ce nu `CAR_YELLOW` pe utilaje:** style_bible §1 rezervă sloturile
> 14–16 mașinilor de joc. Un excavator galben saturat de 4 m ar fi cel mai
> saturat obiect din cadru, lângă Taxi. Pe main, `SLOTS_CARRARA` mută deja
> `rusted_digger` și `kamaz_truck` pe 13 + 10; piesele noi se nasc direct
> acolo.

Pista e **diurnă, lumină fixă**: nu se cer noduri `*_Glow` decât la lămpi.

## 1. Inventar și contracte

Convenții pentru tabele:
- dimensiunile sunt în metri, **în joc** (excepția: derrick-ul și blocul
  agățat, §1.2);
- `h/l` = înălțimea / lățimea siluetei pe decupare. Se verifică în
  comparație, cu toleranță de ±15%;
- triunghiurile se **raportează, fără plafon** (CLAUDE.md). Contează
  **materialele** (un nod = un material); garda pistei e de max 38;
- **modulele înlănțuibile** au capete identice, plane, la ±L/2 pe Y;
- **cotele de contract (goluri) se măsoară ca GOL**: proiecție pe plan, pe
  gabaritul caroseriei (memoriile `cota-de-contract-se-masoara-ca-gol`,
  `golul-se-masoara-pe-fereastra-lui`).

**Drumul**, din `Track23.tscn` și `tools/data/carrara_baked.csv`: **9 m** în
general (`custom_half_width = 4.5`), **10 m** pe piazzale (A), **8 m** în
galerie, pe E și în tunelul Marmifera, **~8,2 m** pe viaduct. Tunelurile
sunt tuburi din cod de **8 m** lățime, cu tavanul la **9 m** (galeria) și
**7 m** (Marmifera).

**Scara e decizie, nu defect** (brief §2.0). Sub o cameră la 10 m, un obiect
de la marginea drumului care trebuie **citit** cere ≥ 3–4 m, iar un reper
văzut de departe ≥ 15 m.

### 1.1 Utilajele-hazard — `build_crr_machines.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `vehicles/quarry_truck.glb` **(pilot)** | **în anvelopa Kamaz-ului măsurat**: lățime **≤ 2,9 m** (cu oglinzi), lungime **7,6–8,2 m**, înălțime **≤ 3,4 m** cu blocurile din benă (`kamaz_truck.glb`: 2,68 × 3,13 × 8,0) | ~0,7 | basculantă rigidă cu **2 blocuri de marmură** în benă (1,4–1,6 m, `*_Marble`), cabină scurtă, 3 axe sau 2 axe cu roți mari, benă cu muchia din spate ridicată. **Consumator:** `BusHazard.model` (`PathMover._build_model`): **botul pe +Y în Blender** (−Z în Godot), originea jos la mijlocul amprentei, centrat pe X. Coliziunea e **o cutie din AABB-ul modelului** (`body_size` ignorat), deci nimic nu iese din contur: fără oglinzi lungi, fără scări atârnate. Noduri: `Truck_Body` (13), `Truck_Rust` (10), `Truck_Black` (20), `Truck_Marble`, `Truck_MarbleBase`. Se compară cu Kamaz-ul pe aceeași captură, iar ProbeRace se reia la schimbare (coordonatorul) |
| `vehicles/quarry_excavator.glb` | **rigul lui `rusted_digger.glb`**, măsurat: `body` **3,9 × 3,73 × 4,93 m** (X −1,95…1,95, Y 0…3,73, Z −2,45…2,48); `arm` **copil al lui `body`**, cu originea (pivotul) în **(0,55; 1,95; −0,42)** în Godot = (0,55; 0,42; 1,95) în Blender, brațul **coborât** în poza de export, ocupând X 0,09…1,01, Y 0,92…3,76, Z −5,70…−0,32 | ~0,5 | excavator pe șenile, **furcă cu două coarne** pentru blocuri (nu cupă), braț cu două segmente, contragreutate. **Consumator:** `ExcavatorHazard` (`find_child("body")`, `find_child("arm")`; AABB-ul lui `body` fără `arm` devine colizorul corpului, iar brațul are **o cutie fixă potrivită pe cotele de mai sus**). Toleranța pe pivot și pe cutia brațului: **±0,1 m**; în afara ei, cutia din cod lovește aer sau lasă brațul fără coliziune. **Atenție:** azi `_build_excavator` încarcă fix `rusted_digger.glb` (track.gd) și aplică `rust_metal` pe tot modelul; schimbarea modelului e punctul 1 din lista de cod a brief-ului §5.6, deci piesa așteaptă acel cod. Noduri-mesh sub `body` și `arm`: `*_Paint` (13), `*_Rust` (10), `*_Black` (20) |
| `structures/derrick.glb` | **modelat la scara codului, 1 : 0,7256**: catargul are pivotul brațului la **22,05 m** (constanta `JIB_HEIGHT`), brațul ajunge la **17,9 m** pe −Z (Godot). În joc, cu `model_scale` 0,7256: catarg de **16 m**, braț de **13 m**. Amprenta catargului: **3,6 × 3,6 m** la scara de model (constanta `MAST_SIDE`, colizorul) | ~1,0 | derrick în A-frame (corectura de sus: **un catarg, un braț**, nu portal cu două picioare): catarg zăbrelit, două picioare de sprijin înclinate spre spate, bază de bârne, braț zăbrelit lung, cârlig. **Fără bloc, fără cablu** (le face codul). **Consumator:** `CraneHazard.crane_model`: nodul **`Jib`** e **rădăcină separată**, cu originea în **balama** (0,0,0) și brațul pe −Z; codul îl mută pe pivot. Restul (catargul) e nodul **`TowerCrane`**, cu baza la 0. Picioarele de sprijin se deschid **de-a lungul drumului (±Z)**, nu pe X: turnul stă pe **stânga** sensului (`tower_side = −1`, x = −7), deci +X e **spre** drum (corectat după valul 1; versiunea veche spunea invers). Pe X nimic nu trece de 1,8 m de axă. Validat cu sonda `tools/probe_carrara_derrick.gd` pe `tower_crane.glb` × 0,7256: modelul nou trebuie să dea aceleași cote |
| `props/marble_block_hooked.glb` | **anvelopa constantei `SLAB_SIZE`, la scara de model**: blocul umple **4,6 × 2,99 × 2,2 m** (X × Y × Z), atârnat **sub** origine, de la Y −0,06 la −3,05 (exact ca `chongqing/props/prefab_slab.glb`). În joc, × 0,7256: **3,3 × 2,2 × 1,6 m** | ~0,65 | bloc de marmură în **două chingi** încrucișate, cu inelul cârligului deasupra. **Originea în punctul de agățare** (vârful chingilor). Coliziunea e cutia constantă din cod, deci blocul **o umple**: nu mai mic (colizor invizibil) și nu mai mare (bloc care trece prin mașini). Chingile și inelul pot urca peste Y −0,06, până la 0. `Block_Marble`, `Block_MarbleBase`, `Block_Strap` (`RUST_METAL`), `Block_Paint` (marcajul) |
| `props/lizza_sled.glb` | amprenta **2,4 × 2,4 m** (±0,05: la 2,6 m sonda pică pe timpul pierdut, 1,64 s > 1,6), talpa **0,4 m**, blocul **1,2–1,4 m** (v2: 1,22) pe jumătatea din spate, cu **puntea din față liberă ≥ 0,6 m** și vârfurile tălpilor ridicate la **≥ 0,6 m**; total ~1,7–1,9 m înălțime (v1, cu blocul de 2,0 pe toată sania, citea „ladă pe palet”) | ~1,0 | sanie de bârne de lizzatura: două tălpi groase, traverse, blocul legat cu **funii** groase încrucișate. **Consumator:** `RockfallHazard` cu `roll_model = false` (ramura `carrara/sonde-mec`): codul **recentrează modelul**, ia raza sferei de coliziune din **max(AABB.x, AABB.z) / 2** și pune **−Z pe direcția de mers**. Amprenta e exact cea validată de `tools/probe_carrara_sled.gd` (2,4 / 2,4, talpa de contact plată de la Z Godot +1,20 la −0,70): o sanie mai lungă mărește sfera și o face să plutească. Înălțimea blocului nu intră în sferă (`_half_h` coboară modelul). Tălpile pe +Y (Blender), cu vârful întors în sus după −0,70. Garda: `measure_carrara_crr_a.py sled`. `Sled_Wood`, `Sled_Rope` (`WOOD_WEATHERED` umbrit), `Sled_Marble`, `Sled_MarbleBase` |
| `rocks/block_informe_a.glb` | **3 m** în toate direcțiile (±10%) | ~0,85 | **blocul basculat** (brief §3, D) și decor: bloc neregulat, spart, cu **două-trei fețe tăiate drept** și restul fațete mari de spărtură. **Consumator:** `RockfallHazard` cu traseu și rostogolire: raza = max(AABB.x, AABB.z) / 2, deci **amprenta aproape pătrată** (X ≈ Z), altfel sfera nu se potrivește cu forma. `Informe_Marble` |

### 1.2 Utilajele de decor — `build_crr_machines.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `vehicles/wire_saw.glb` | șasiu **2,5 × 1,6 × 1,4 m** pe două șine de **6 m**, volant **Ø 1,8 m** | ~0,35 | mașina de fir diamantat: motorul-cutie, **volantul** vertical cu spițe (`segments` 16), firul ca buclă subțire spre perete, **jetul de apă** ca 2–3 fâșii scurte. **Volantul e nodul `Blades`** (consumatorul e `windmill.gd`: rotește copilul cu acest nume în jurul axei lui), cu originea în **butucul volantului** și axa pe X (Godot). `Saw_Paint`, `Saw_Rust`, `Blades` (`RUST_METAL`), `Saw_Rail` (`PAINTED_METAL`), `Saw_Water` (`REEF_SHALLOW` 17) |
| `vehicles/chain_saw_crawler.glb` | **4,5 m** lung (fără lamă), **2,2 m** înalt; lama **4 m** | ~0,4 | ferăstrău-lanț pe șenile: corp jos, cabină mică, **lama lungă** cu dinți (relief, nu textură). **Fără peretele de marmură** de pe decupare: lama se termină liber, integrarea o bagă într-un perete real. Decor static, coliziune `hull` |
| `vehicles/drill_rig.glb` | șasiu pe șenile **3,5 m**, catarg **6 m** | ~1,6 | mașina de forat: șasiu pe șenile, catargul vertical cu ghidaje și burghiul, furtunuri hidraulice. Decor static |

### 1.3 Structuri — `build_crr_structures.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `structures/ponti_di_vara.glb` | **36 m** lung (Y; golul măsurat pe Track23 are **~31 m** pe ax), drumul la cota 0, pilele coboară **26 m** (fundul cheii e la +17, drumul la +43); 3 arce | ~0,75 | viaduct: **trei arce de cărămidă** (`*_Brick`) pe **pile de marmură** (`*_Marble`), cu cornișă și două goluri rotunde de drenaj. **Drumul e asfalt din cod**; viaductul îl **ține**, nu îl acoperă: originea pe axa drumului la cota 0, geometria **atârnă sub Y = 0** (`--origin=rim`), **nimic peste Y = −0,05 între \|x\| ≤ 4,6**. Parapetul de 0,9 m la \|x\| 4,7…5,3, ca nod separat **`Viaduct_Parapet`**, ca integrarea să-l poată stinge (pe pod stă azi berma de moloz din cod, `custom_parapets`). Coliziunea: `mesh` (precedentul `vidraru_dam`), fiindcă `hull` ar umple arcele (brief §5.6). Fără tufe la baza pilelor |
| `structures/gallery_portal.glb` | rama **18 m** lată × **15 m** înaltă × **3 m** adâncime; **golul ≥ 10,0 m lățime și ≥ 10,5 m înălțime liberă, măsurat ca GOL** | ~0,85 | gura galeriei Ravaccione: **o deschidere dreptunghiulară tăiată drept** în marmură, cu rama din **blocuri mari vizibile** (6–10 blocuri) și **o lampă** sus pe buiandrug (`Portal_Glow`). **De ce golul atât de mare:** codul construiește deja rama de beton a tubului (`_tun_frame`: exteriorul **9,6 × 9,8 m** pe galerie, adâncime 1,2 m, plus aripi de 14 m lungime și 2,5 m înălțime spre exterior) și nu are export de oprire. GLB-ul se pune **peste** rama codului (precedentul Transfăgărășan), deci golul trece de ea pe toate laturile, iar rama codului rămâne ca o căptușeală interioară. Fața doar pe +Y; spatele intră în munte. Interiorul `VOLCANIC_BLACK` doar în primii 2 m (`Portal_Void`). `Portal_Marble`, `Portal_MarbleBase`, `Portal_Rust` (dârele), `Portal_Glow`, `Portal_Void`. Coliziunea `mesh` |
| `structures/marmifera_portal.glb` | **14 m** lat × **11 m** înalt × 2,5 m; **golul ≥ 10,0 m lățime pe 0–6 m și cheia arcului la ≥ 8,5 m, măsurat ca GOL** | ~0,8 | portal feroviar vechi de **piatră**: arc în plin cintru din bolțari, fruntar de piatră brută, **pete de mușchi** (`Portal_Moss`), două șine care intră în tunel (`Portal_Rail`, `PAINTED_METAL`, pot fi și pe drum: se taie la integrare dacă deranjează). Același motiv pentru gol: rama codului e **9,6 × 7,8 m** aici. Fără tufe și bolovani lipiți (corectura de sus). `Portal_Stone`, `Portal_Moss`, `Portal_Rail`, `Portal_Glow`, `Portal_Void` |
| `structures/gallery_pillar.glb` *(amânat)* | **3 × 3 × 18 m** | ~6 | stâlp de marmură cu fețe tăiate, din 5–6 tronsoane vizibile. **Nu are încă consumator:** sala de 16 m din galerie (brief §3) cere lărgirea tubului în builder, care **nu s-a construit** (pe Track23 tubul are 8 m pe toată lungimea). Se modelează doar dacă sala intră în cod (memoria `brief-cere-glb-cod-il-face-deja`) |

### 1.4 Repere și sat — `build_crr_buildings.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `buildings/colonnata_church.glb` | navă **14 × 8 m**, coamă **10 m**; clopotnița **4 × 4 m**, **14 m** cu acoperișul piramidal și crucea (brief §5.2) | ~1,1 | biserică de piatră: navă cu acoperiș în două ape și o absidă / anexă joasă, **clopotniță pătrată** cu două ferestre arcuite sus și acoperiș piramidal de țiglă, cruce. Ușă arcuită pe +Y. **Fără chiparoși și tufe** (corectura de sus). `Church_Stone`, `Church_Roof`, `Church_Wood` (ușa), `Church_Void` |
| `buildings/colonnata_house_a.glb` | **9 × 7 m**, două niveluri, coamă **8 m** | ~0,85 | casă de piatră, acoperiș în **două ape** de țiglă, obloane verzi, ușă arcuită. `House_Stone`, `House_Roof`, `House_Wood`, `House_Shutter` (`CACTUS_GREEN`), `House_Void` |
| `buildings/colonnata_house_b.glb` | **8 × 7 m**, coamă **8,5 m** | ~0,95 | **altă siluetă**: casa mai înaltă, cu frontonul spre +Y și o lucarnă sau un horn mare |
| `buildings/colonnata_house_c.glb` | **10 × 7 m**, coamă **7,5 m** | ~0,75 | **altă siluetă**: casa cu **scară exterioară de piatră** pe latură până la etaj (ca pe decupare) și o terasă mică |
| `props/quarry_sign_block.glb` | bloc **3 × 2 × 2 m** | ~0,65 | blocul-semn: un bloc de marmură cu **o față șlefuită** (un singur plan, fără vene modelate) pe +Y, restul fețe tăiate. **Fără text.** `Sign_Marble`, `Sign_MarbleBase` |
| `props/museum_set_cart.glb`, `props/museum_set_wheel.glb`, `props/museum_set_sled.glb` | vagonet **2 m** pe 3 m de șină cu un bloc de 1 m; roata de fir elicoidal **Ø 2 m** pe suport; sania veche **2,5 m** cu funii | — | colțul de muzeu din A. **Trei GLB-uri, nu unul cu variante**: `keep_variants` nu există în `world_prop` (brief §5.6), deci un GLB cu trei noduri le-ar randa pe toate trei. Rugină și lemn vechi, mai închise decât utilajele vii |

### 1.5 Kitul de carieră — `build_crr_kit.py`

Kitul se repetă mult (MultiMesh și `DecorManual`), deci **un singur mesh
compact per variantă**, fără noduri inutile, cu excepția separării
`*_Marble` / `*_MarbleBase` cerute de regula 8.

| fișier | cote | contract |
|---|---|---|
| `rocks/marble_block_a.glb`, `_b`, `_c` | cuburi de **1,5 / 2 / 3 m** (`_c` ușor alungit, 3 × 2 × 2) | **cel mai ieftin kit din joc**: cutie de **12 triunghiuri**, muchii vii; venele și dungile de fir le dă clasa. Varianta `_b` are dunga de vopsea (`Block_Paint`, `LAVA_ORANGE`) pe o latură |
| `rocks/block_stack_a.glb`, `_b` | stivă de **2** și de **3** blocuri (2 m), ușor decalate între ele | blocurile ca mase separate, nu un prism; decalaj 0,1–0,3 m și rotație ±5° |
| `rocks/block_informe_b.glb` | **2 m**, mai turtit decât `_a` | bucată spartă, fațete mari |
| `rocks/rubble_pile_a.glb`, `_b` | **Ø 4 m**, **1,5 m** / **Ø 3 m**, **1,2 m** | grămezi de moloz din **fragmente unghiulare** (15–25 de bucăți), nu bulgări rotunzi. Coliziune `none` |
| `structures/safety_berm.glb` | modul **6 m** (Y), **0,6 m** înalt, 1,4 m lat | dâmb de blocuri și moloz, **în pantă spre drum** (−X) și abrupt spre gol (+X). Capete la ±3 m, identice, ca să se înlănțuie. **Notă:** berma de pe terase e azi din cod (`custom_parapets` stilul 2) și trece ProbeRace; modulul GLB e pentru punctuație (capete de pod, piazzale), nu o înlocuiește |
| `props/work_lamp.glb` | **3 m**, trepied | trepied galben-spălăcit cu **două reflectoare** (`Lamp_Glow`) |
| `props/cable_reel.glb` | **Ø 1,6 m**, 1 m lat | tambur de lemn cu cablu negru înfășurat |
| `props/water_tank.glb` | **Ø 2 m**, **3 m** cu picioarele | rezervor vertical pe 4 picioare, **`PAINTED_METAL`** (corectura de sus) |
| `props/fuel_tank.glb` | **4 × 2 m**, **2,4 m** | rezervor orizontal de motorină pe șei, scară, ruginit (`RUST_METAL`) |
| `buildings/office_container.glb` | **6 × 2,5 × 2,6 m** | container de șantier: ferestre, ușă, trepte metalice; `CONCRETE` cu rama `ASPHALT_EDGE` |
| `props/quarry_sign_a.glb`, `_b` | panou **1,2 × 0,8 m** pe doi stâlpi de **1,8 m** | `_a` cu **chevron** dublu, `_b` cu pictograma **blocului suspendat**. Câmpul `DRY_VEGETATION`, desenul `VOLCANIC_BLACK` în **relief de 1–2 cm**. **Fără text** |
| `props/pipe_run.glb` | modul **6 m** (Y), două conducte **Ø 0,4 m** pe 3 suporturi de marmură | conducte de apă pe terase; capete la ±3 m, ca să se înlănțuie. `Pipe_Metal`, `Pipe_Marble` |

### 1.6 Fundal — `build_crr_horizon.py`

`effects/carrara_horizon.glb` cu noduri copii directe ale rădăcinii. Sunt
**volume închise, lizibile din orice azimut, cu originea la bază**.
Consumatorul e `Track._build_horizon`, prin `horizon_model` în tema
`carrara`. Inelul e la **200–300 m**, sub `fog_end` 300 (brief §4, §5.4),
deci la 250 m camera vede cel mult **~33 m** peste cota drumului. Siluetele
mai înalte de atât se taie sus, iar asta e voit.

| nod | cote | contract |
|---|---|---|
| `ApuanRidge_A`, `_B`, `_C` | 160–240 m lungime, **35–60 m** înălțime | 2–3 vârfuri de calcar pe o bucată, flancuri **crem-gri** (`MARBLE_GREY`) cu **dâre de moloz deschise** (`CORAL_SAND`) care coboară pe flanc, **pădure verde-cald la bază** (`TROPICAL_GREEN` și `DRY_VEGETATION`, mase joase). **Fără calotă albă, fără zăpadă** (brief §5.4: calota = Alpi). Siluetele diferă între ele; `apuan_ridge_b` arată varianta cu mai multe vârfuri |

Fără coliziune. `cast_shadow` OFF la integrare (memoria
`caster-departat-fura-umbra`).

### 1.7 Ce NU se generează (refolosit sau făcut de cod)

| desen pe planșă / reper | ce se folosește | de ce |
|---|---|---|
| castanii | `transfagarasan/plants/beech_tree_a/b.glb` | brief §4; `CLASSES_CARRARA` le pune deja `tf_beech` |
| ginestra | `stromboli/plants/ginestra_bush.glb` | semnul verii, brief §4 |
| chiparoșii, tufele de lângă casele de pe planșă | scatter-ul pistei la integrare | corectura de sus |
| molozul mare, conurile de grohotiș | `rocks/rock_cluster.glb`, `transfagarasan/rocks/scree_cone.glb` | pe `carrara_marble` (`CLASSES_CARRARA`) |
| zidurile de sprijin la rampe | `transfagarasan/structures/retaining_wall_*.glb` | brief §5.3 |
| camionul parcat din A, recuzita de șantier | `baikal/vehicles/kamaz_truck.glb`, `transfagarasan/props/road_works.glb` | brief §5.3 |
| — | fețele gradonilor, terasele, fundul carierei, cheile | teren din cod (`custom_bench_patches`, `custom_ravines`) pe `carrara_marble` |
| — | tuburile galeriei și ale tunelului, rama lor de beton | `TunnelSignalHazard` (`tube_only`, `tube_class`) |
| — | berma continuă de pe terase și de pe pod | `custom_parapets` stilul 2 |
| — | cablul derrick-ului, colizoarele hazardelor | codul hazardelor |
| — | bălțile de marmettola, pârâul din chei | apa locală din cod |

Doar pentru piesele din tabel: dacă la integrare o piesă refolosită arată
evident altfel decât decuparea ei, coordonatorul o trece în „de refăcut” în
inventar. Nu e treaba setului.

## 2. Livrabile

| fișier | ce |
|---|---|
| `tools/blender/build_crr_{machines,structures,buildings,kit,horizon}.py` | rulabile headless: `D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- build_crr_machines.py`. **Docstring-ul fiecărei funcții de piesă conține lista de elemente** (§0.1 pasul 1), scrisă înainte de primul vertex. Vocabularul comun e în `carrara_shapes.py`: bloc tăiat cu bază de patină, bucată spartă, șenilă, braț zăbrelit, arc de bolțari, acoperiș de țiglă |
| `tools/blender/preview_carrara.py` | `--compare <nume>` (decupare ↔ randare), `--views <nume>` (4 azimuturi), `--sheet <val> a,b,c` |
| `tools/blender/verify_carrara.sh` | o rulare, un verdict, excepțiile declarate cu motiv |
| `docs/asset_briefs/carrara_inventory.md` | cote măsurate, tri, noduri, tabele de fidelitate, contracte înghețate (anvelopa camionului, rigul excavatorului, scara derrick-ului, golurile portalurilor, originea viaductului) și **„Stare la oprire”** |
| `docs/asset_briefs/img/carrara_fidelity/<nume>.png` | comparațiile alăturate |

## 0.1 Fidelitatea față de planșă — criteriul de acceptare

Planșa e sursa de **formă și culoare**. Tabelele de aici, cu corecturile de
sus, sunt sursa de **cote și de contracte de cod**.

1. **Deschide decuparea** și scrie în docstring **lista de elemente**, cu
   numere: câte blocuri în rama galeriei, câte arce și pile la viaduct, câte
   axe la camion, câte segmente la brațul excavatorului, câte spițe la
   volant, câte ferestre pe fațada caselor, ce iese din contur. Lista se
   scrie înainte de primul vertex. Unde o corectură de sus contrazice
   decuparea, lista urmează corectura și o spune.
2. **Modelează după listă**, la cotele din tabel. În rest, proporțiile
   interne ale desenului se păstrează.
3. **Randează comparația** (`preview_carrara.py --compare <nume>`):
   - decuparea în stânga, randarea GLB-ului în dreapta, la aceeași înălțime
     în pixeli;
   - 3/4 din față, lumină de zi neutră, fundal `#C4C4C4`;
   - **culoare reală**: fiecare față pe culoarea slotului ei din atlas
     (recuperat din UV), nodurile `*_Marble` pe `#E8D6B2`, `*_MarbleBase`
     pe `#B8B4AC` (slotul), `*_Stone` pe `#8E8C82` (ținta `tf_stone`),
     `*_Roof` și `*_Brick` pe `#C4784F` (slotul).
4. **Verifică pe imagine, element cu element**, nu doar numărând (memoria
   `numaratoarea-trece-amplasarea-nu`): poziția, forma, `h/l` (±15%), ordinea
   luminozităților, ce iese din contur. Rezultatul intră ca tabel în
   inventar: element | pe planșă | în GLB | OK/abatere. **La utilaje,
   culoarea din comparație e galben-spălăcit, nu galbenul planșei**: abaterea
   e voită (corectura de sus) și se notează, nu se repară.
5. **Maximum 3 runde pe piesă.** Dacă tot nu seamănă, abaterea se raportează
   cinstit în inventar, nu se declară „trece”.
6. **Piesa se acceptă doar după ce coordonatorul a văzut comparația.**

## 3. Ordinea de lucru (valuri de ~3 constructori; fiecare cu verify + comparații + commit)

0. **Pilot:** harnasul (`carrara_shapes.py`, `preview_carrara.py`,
   `verify_carrara.sh`) plus **`quarry_truck`**. E singura piesă-hazard cu
   consumator gata pe Track23 (`BusHazard.model`), deci se poate schimba
   imediat și se reia ProbeRace pe camioane. **Anvelopa se măsoară ÎNAINTE de
   orice altceva** și se compară cu `kamaz_truck.glb`. Coordonatorul judecă
   comparația și ProbeRace înainte de valul 1.
1. **Valul 1:**
   - **crr-a**: utilajele-hazard rămase (§1.1): `derrick` +
     `marble_block_hooked` **primele** (cotele de scară se verifică cu
     `probe_carrara_derrick.gd`), apoi `lizza_sled`, `block_informe_a` și
     `quarry_excavator` (rigul măsurat față de `rusted_digger`);
   - **crr-b**: structurile (§1.3): `ponti_di_vara` primul, cu **originea
     verificată** (`--origin=rim`, nimic peste −0,05 m pe drum), apoi cele
     două portaluri cu **golul măsurat ca gol**;
   - **crr-c**: kitul de carieră (§1.5). `marble_block_a/b/c` primele, cu o
     captură de 12 blocuri în stivă alături de cea izolată, ca să se vadă
     că marmura citește crem, nu albă.
2. **Valul 2:**
   - **crr-d**: utilajele de decor (§1.2) și colțul de muzeu (§1.4);
   - **crr-e**: satul și blocul-semn (§1.4). `colonnata_church` se judecă
     înaintea caselor;
   - **crr-f**: fundalul (§1.6), **provizoriu**: verdictul se dă pe pista
     reală, cu testul de anotimp din brief §6.
3. **Amânat:** `gallery_pillar`, doar dacă sala din galerie intră în cod.

Lucrează în worktree-ul indicat în prompt (ramura `carrara/kit-<grupa>`).
Nu comite pe `main`, nu folosi `git stash` (e comun tuturor
worktree-urilor), nu face push.
