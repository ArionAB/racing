# Brief asset — Camionul care mută despărțitorul + blocul (`sf_median_truck.glb`, `sf_median_block.glb`)

Brief auto-conținut pentru un agent Blender extern (Blender MCP). Nu presupune acces la repo:
tot contractul e aici. Sursele din care e derivat sunt [style_bible.md](../style_bible.md),
[blender_export.md](../blender_export.md), [scripts/palette.gd](../../scripts/palette.gd), foaia
de assets [sanfrancisco_inventory.md](sanfrancisco_inventory.md) (H3, §1.5) și hazardul
`scenes/hazards/movable_median_hazard.gd` (gabaritele placeholderului: `truck_size`
2,6 × 3,2 × 10,0 m; blocul 3,0 × 0,6 × 0,95 m vizual, 1,3 m coliziune). Brief-ul pistei:
`docs/track_briefs/san_francisco.md` §7 pașii 1d și 2b.

Surse reproductibile (de creat de agent): `tools/blender/build_sf_median.py`.

> **Prompt de dat agentului:** de la linia orizontală de mai jos în jos e paste-ready. Restul
> paginii sunt note pentru noi. **Cele două GLB-uri intră în joc abia după un cod care lipsește**
> (§11), dar se pot modela de acum: contractul de mai jos nu depinde de el.

---

## 1. Ce construiești

Două piese low-poly și stilizate, pentru un joc de curse cu mașinuțe de jucărie în stil dioramă
(ton *Art of Rally*: machetă de masă, NU foto-realist):

1. **Un utilaj lent care mută bariera de beton dintre sensurile unui pod.** E un vehicul lung și
   scund, cu cabină de șofer **la ambele capete**, care încalecă rândul de blocuri. Blocurile
   trec pe sub el printr-un tunel cu un transportor în S, iar bariera iese pe partea cealaltă,
   mutată lateral.
2. **Blocul de beton al barierei.** E o piesă scurtă care se repetă de ~90–145 de ori, cap la cap.

## 2. Rolul lor în cadru

Pe tablierul podului roșu, cele două sensuri sunt despărțite de un rând de blocuri. Utilajul face
naveta pe pod cu 4 m/s și mută bariera în spatele lui. Banda jucătorului se îngustează sau se
lărgește după unde e utilajul. Camera e la 10 m deasupra drumului, 12,5 m în spatele mașinii,
privind în jos la 29°. Utilajul se vede de sus, din 3/4, de la 10 la 170 m, iar blocurile de la
2 m (lângă mașină) la 200 m (rândul care se pierde în față).

**Testul de reușită:** din camera de joc, utilajul citește „mașinărie de drum care face ceva cu
bariera”: lung, scund, cu blocuri care intră pe dedesubt într-o parte și ies mutate în cealaltă.
Rândul de blocuri citește „barieră de beton”, nu „bordură” și nici „zid”.

## 3. Formă și dimensiuni (unitate: 1 = 1 m; mașina de referință = 4,2 m)

### 3.1 Utilajul — `sf_median_truck.glb`

**Gabaritul e contract.** Jocul are o cutie de coliziune fixă de **2,6 (lățime) × 3,2
(înălțime) × 10,0 (lungime) m**, iar inteligența artificială a mașinilor citește aceeași cutie.
**Tot modelul stă în ea**: AABB ≤ 2,6 × 3,2 × 10,0, de la y = 0.

- **Două cabine** de șofer, câte una la fiecare capăt (utilajul merge în ambele sensuri), lungi
  de 1,8 m, de la +1,1 la +3,2, cu geamuri mari pe față și pe laterale.
- **Corpul dintre ele** (6,4 m), de la +1,15 la +2,7: carcasa transportorului, cu o balustradă
  joasă și groasă (≥ 0,08 m) pe acoperiș și o lumină de avertizare rotundă pe mijloc (în gabarit).
- **Tunelul de dedesubt:** pe toată lungimea, pe mijloc, un gol de **1,0 m lățime și 1,15 m
  înălțime** (de la y = 0 la +1,15), prin care trec blocurile (0,95 m). În tunel, **roțile
  transportorului**: un șir de role ⌀ 0,5 m (8 laturi), vizibile din lateral, așezate pe un S
  blând de la o margine a tunelului la cealaltă.
- **Roțile utilajului:** câte 4 boghiuri (2 pe parte) **în afara tunelului**, roți ⌀ 0,8 m,
  pe y 0…0,8, cu aripi.
- **Dungi de avertizare** la ambele capete (chevroane roșu-alb ca geometrie, panouri în relief de
  0,02 m, nu textură). Faruri la ambele capete.
- Fără text, fără sigle, fără număr.

### 3.2 Blocul — `sf_median_block.glb`

- **3,00 m lungime (X) × 0,60 m lățime (Z) × 0,95 m înălțime (Y).** Nimic nu iese din
  gabaritul ăsta.
- **Profil în „T” cu laturi verticale:** baza de 0,60 m până la +0,70, apoi un gât de 0,30 m
  (+0,70…+0,80) și un cap de 0,45 m (+0,80…+0,95), pe care îl apucă transportorul. **Fețele
  laterale sunt verticale** până la +0,70, nu în pantă (profilul „New Jersey” în pantă e
  interzis: o barieră în pantă aruncă mașinile peste ea).
- **Capetele:** o îmbinare cu balama groasă, un cep pe un capăt și o mufă pe celălalt, ca blocurile
  puse cap la cap la 3,0 m să pară legate. Teșituri de 0,05 m pe muchii.
- Un **reflector** mic pe fiecare față laterală (0,15 × 0,10 m, relief 0,01).

## 4. Orientare

Ambele piese privesc spre **−Z în Godot**, adică **+Y în Blender** (exportatorul glTF face `(x, y,
z) → (x, z, −y)`). Utilajul: lungimea pe Z (de la −5,0 la +5,0), lățimea pe X. E simetric față-spate.
**Blocul: lungimea pe X** (de la −1,5 la +1,5), lățimea pe Z: blocurile se pun cap la cap pe X.

## 5. Culoare — FĂRĂ texturi proprii

UV → sloturi dintr-un atlas de paletă (32 de sloturi orizontale). Fiecare față își colapsează
toate UV-urile pe **un singur punct**, centrul slotului: `u = (slot + 0,5) / 32`, `v = 0,5`.

| slot | nume | **u** | hex | unde |
|---|---|---|---|---|
| 11 | `painted_metal` | **0.359375** | `#7692A8` | caroseria utilajului (gri-albastru: rece, distinct de roșul podului și de betonul blocurilor) |
| 7 | `kerb_red` | **0.234375** | `#BB3522` | chevroanele (jumătate) |
| 22 | `foam_white` | **0.703125** | `#E9F2F0` | chevroanele (cealaltă jumătate), farurile, reflectoarele blocului |
| 20 | `volcanic_black` | **0.640625** | `#55535A` | geamuri, roți, interiorul tunelului, rolele |
| 30 | `lava_orange` | **0.953125** | `#E8622D` | **doar** lumina de avertizare (o piesă mică) |
| 8 | `concrete` | **0.265625** | `#C8BDA9` | **blocul** (tot, în afară de reflectoare) |

**Interzise:** 14, 15, 16 (culorile mașinilor; un utilaj galben ar concura cu ele). Galbenul de
șantier se înlocuiește aici cu gri-albastrul plus chevroanele.

## 6. Vertex colors = AO copt

Un strat de Color Attribute, gri, înmulțit peste culoare. 1,0 = neatins, ~0,5 = adânc.
Obligatoriu.

- Utilajul: gradient 0,6 jos → 1,0 sus; **tunelul ~0,45** (trebuie să citească drept gol întunecat
  din care ies blocurile); sub cabine și între roți ~0,55.
- Blocul: 0,75 la bază → 1,0 pe cap; gâtul T-ului ~0,65 (umbra de sub cap e ce desenează profilul
  de sus).
- Eșantioane: 32.

## 7. Scară, origine, bevel

- Originea la **baza obiectului (y = 0), centrată în X și Z**, pentru amândouă.
- Scara 1 și rotația 0 aplicate pe nodul rădăcină.
- Bevel **0,04 m** (prop / vehicul) pe utilaj; pe bloc doar teșiturile de 0,05 din §3.2.

## 8. Triunghiuri

- Utilajul: o instanță. Orientativ 4.000–6.000.
- **Blocul: ~90 de instanțe pe tablier și pe paliere, ~145 cu zidurile de la capete**, deci **≤ 120 de triunghiuri**. Profilul în T, îmbinarea și
  reflectoarele, nimic altceva.

## 9. Export

- Două glTF Binary (.glb): **`sf_median_truck.glb`** (nod-mesh `MedianTruck_Body`) și
  **`sf_median_block.glb`** (nod-mesh `MedianBlock`). Câte un singur nod-mesh, direct sub
  rădăcină.
- Include: Mesh, **UVs**, **Vertex Colors**, Normals. Fără camere, lumini, texturi, coliziune.
- **Apply Modifiers: ON.** Y-up: implicit.
- Înainte de livrare: tipărește AABB-ul în coordonate Godot. Utilajul ≤ 2,6 × 3,2 × 10,0, blocul
  exact 3,00 × 0,95 × 0,60 (X × Y × Z), ambele cu y-ul minim 0.

---

## 10. Note pentru noi (nu fac parte din prompt)

**Checklist la primire:**
```
python tools/blender/verify_glb.py assets/models/sanfrancisco/vehicles/sf_median_truck.glb 8000 --front=-Z
python tools/blender/verify_glb.py assets/models/sanfrancisco/props/sf_median_block.glb 120
```
Slotul 30 (`lava_orange`) e legal în `verify_glb` (`LEGAL_SLOTS` = 0–13, 17–30).

## 11. Ce cod lipsește (inventarul §1.5) — nu e treaba agentului Blender

`MovableMedianHazard` n-are export de model:
- blocurile sunt un `BoxMesh` 3,1 × 0,95 × 0,6 în `MultiMesh`, cu transformul ridicat la
  `block_height / 2` (`movable_median_hazard.gd:208–226`, `:293`);
- utilajul e o cutie `truck_size` plus o cabină placeholder (`:297–335`), cu lungimea pe +X local,
  rotită cu 180° la schimbarea sensului (`:344`).

De adăugat: `@export var truck_model: PackedScene` (instanțiat sub `Camion`, rotit cu −90° ca −Z
din GLB să cadă pe +X local; cutia de coliziune rămâne `truck_size`) și `@export var block_mesh:
Mesh` (sau `block_model` + `block_node`), cu decalajul de origine schimbat (GLB-ul are originea la
bază, nu la centru). Cu exporturile goale, totul rămâne ca acum. Gărzile de reluat după integrare:
lotul ProbeRace al podului (`tools/sf_route_race.sh`, secțiunea `--- PODUL` din
`sf_route_report.py`): 0 treceri peste despărțitor, 0 frontale, contactul cu bariera în banda
4,6–5,5 %. Plus `ProbeLaneClear --track=17` la linia de bază (50).

Zidurile moi din S (`Pod/CapS`, 80 m × 0,6 m pe axă, 1,3 m peste drum) pot primi vizual același
bloc, pus în rând de generator (26 de blocuri pe fiecare). Și aici e date, nu cod.

**Materiale:** ambele pe atlas. Cele 3 materiale placeholder (blocurile, camionul, cabina) dispar.

## 12. Abateri și dependențe

- **Utilajul are 10 m, nu ~16 m ca utilajele reale de mutat bariera:** e cutia măsurată la 1d și 2b
  (navetă de 110 m pe tablierul de 200 m).
- **Două cabine:** codul întoarce utilajul cu 180° la capete. Cu două cabine, întoarcerea nu se
  vede, iar utilajul pare să meargă înapoi, ca cele reale.
- Între parapetele roșii ale podului (`sf_red_bridge.md`): roșul podului, betonul blocurilor și
  gri-albastrul utilajului sunt trei valori distincte.
- **Diorama** (`img/sf_route/sf_diorama_v1.jpg`) desenează pe tablier o furgonetă gri. **Nu e
  referință:** utilajul rămâne cel de mai sus (scund, cu tunel, cu două cabine), fiindcă trebuie
  să citească „mută bariera”, nu „mașină în trafic”.
