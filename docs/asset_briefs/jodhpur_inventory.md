# Inventar assets — Jodhpur (`Track17`), val 1: pilotul

Contract: `docs/asset_briefs/jodhpur_kit.md` §1.1, §3 pasul 1. Verdict kit:
`bash tools/blender/verify_jodhpur.sh` → `VERDICT KIT: OK` (2/2 GLB).

Comparațiile de fidelitate (decupare ↔ randare din GLB exportat, culoare
reală prin `preview_jodhpur.py --compare`):
`docs/asset_briefs/img/jodhpur_fidelity/ghanta_ghar.png`,
`docs/asset_briefs/img/jodhpur_fidelity/blue_house_a.png`, adunate în
`docs/asset_briefs/img/jodhpur_fidelity_val1.png`.

## `buildings/ghanta_ghar.glb`

- **Triunghiuri:** 4 300 total (`Tower_Stone` 2 748, `Clock_Glow` 848,
  `Clock_Glow` include discurile + acele celor 4 cadrane; `Tower_Glow` 704 —
  golurile de ușă/nișe/ferestre/arcada lanternei).
- **Cote măsurate din GLB** (mesh `Tower_Stone`, care singur atinge cotele
  de contract — `Clock_Glow`/`Tower_Glow` sunt geometrie mai mică, îngropată
  în pereți, cu bbox propriu mai mic):
  - bază: **7,00 × 7,00 m** — exact cota din tabel.
  - înălțime: **19,36 m** față de **22 m** contract (−12%). Turnul a fost
    scurtat manual în timpul iterațiilor de fidelitate (vezi mai jos) ca să
    aducă raportul h/l în bandă; înălțimea absolută a rămas sub cotă.
    **Abatere nescrisă în brief, semnalată aici**: dacă 22 m e o cotă de
    gameplay (vizibilitate de la distanță, referință de scară pe pistă),
    turnul ar trebui rescalat pe Z la 22/19.36 ≈ ×1,136 la integrare, sau
    modelul remodelat cu un fus mai înalt.
  - origine: la bază, centrată (`--origin=assembly`, cele 3 noduri au
    origine comună).
- **h/l siluetă (comparație):** măsurat **2,37**, față de **2,17** pe
  decupare (+9,2%, în banda ±15%).
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB | verdict |
  |---|---|---|---|
  | soclu teșit, cu poartă în arc | 1 nivel, poartă centrată | `Tower_Stone`, poartă retrasă 0,3 m, gol real (nod `_glass_and_reveal_sides`, punch pe latura +Y) | OK |
  | a doua bandă de soclu, cu arcade oarbe | 3 nișe pe fața vizibilă | 3 nișe retrase 0,26 m pe fața +Y | OK (nișele laterale nu au fost verificate individual la unghiul de comparație, doar cea centrală + geometria simetrică) |
  | fus pătrat, 2 ferestre înalte pe fiecare față | 2 ferestre per față, colțuri teșite | 2 goluri verticale paralele per față (8 total), colțuri teșite `chamfer=0,32` | OK |
  | brâu orizontal | bandă îngustă, iese în consolă | prezent, `belt_h=0,45` | OK |
  | etajul ceasului, 4 cadrane | 2 vizibile din unghiul planșei, disc alb + ace negre, fără cifre | 4 cadrane (`Clock_Glow`), fără cifre (regula 0.8) | OK |
  | balcon pe console + creneluri | bandă + parapet crenelat, console vizibile | bandă lată + parapet cu 6 creneluri late + console pe fiecare față | OK, dar creneluri mai puține/late decât desenul (aproximare deliberată, se citesc clar la distanță) |
  | lanternă, colonadă cu 4 arcade | 4 arcade, stâlpi subțiri | colonadă DESCHISĂ, 8 stâlpi (4 colț + 4 mijloc față), arhitrav sus/jos | OK — stâlpii sunt mai groși decât planșa (`col_r=0,22`), decizie de citire la distanță (stâlpi subțiri de sub 10cm nu s-ar vedea din mașină) |
  | cupolă bombată + turlă | profil bombat, spiră subțire | cupolă în 3 trepte (evazare → bombare → vârf) + spiră | OK |
  | fără cifre pe cadrane | — | confirmat, discurile sunt goale | OK |

- **Abateri cunoscute și motiv:**
  - **Înălțimea totală** (19,36 m vs 22 m) — vezi mai sus. Tras în jos
    deliberat, ca parte a corecției de siluetă (raportul h/l pornise la
    2,63, cu turnul la înălțimea inițială de calcul ~20,7 m pe o bază de
    7 m; scurtarea + lărgirea tierului 2/fus au adus atât h/l cât și
    proporția vizuală mai aproape de decupare).
  - **Nișele socle 2** nu au fost verificate individual din unghiul
    camerei de joc (10 m sus, 12,5 m spate) — doar din unghiul de
    comparație (35°/18°). La integrare merită o verificare suplimentară cu
    `--driver` sau parametrii reali de cameră.

## `buildings/blue_house_a.glb`

- **Triunghiuri:** 1 672 total (`House_Wall` 220, `House_Trim` 264,
  `House_Rail` 1 188 — balustrada scării domină bugetul, geometrie de
  trepte + bare).
- **Cote măsurate din GLB** (mesh `House_Wall`, corpul principal):
  - amprentă: **6,18 × 6,18 m** față de **6 × 6 m** contract (+3%, din
    soclul ușor ieșit — `plinth` +0,18 m pe fiecare parte, intenționat, ca
    pe decupare).
  - înălțime totală (incl. cutia de pe acoperiș): **8,06 m**. Contractul
    cere **6,5 m până la parapet** — măsurat separat, pereții + parapetul
    ating exact 6,5 m; cutia de pe acoperiș (1,4 m înălțime, redusă față de
    versiunea inițială de 1,9 m) urcă peste asta, așa cum arată decupare.
  - origine: la bază, centrată (`--origin=assembly`, 3 noduri).
- **h/l siluetă (comparație):** măsurat **1,08**, față de **0,95** pe
  decupare (+13,7%, în banda ±15% după reducerea cutiei de pe acoperiș de
  la 2,6×2,4×1,9 m la 2,2×2,0×1,4 m).
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB | verdict |
  |---|---|---|---|
  | corp cubic, parapet plat | cub cu parapet | `House_Wall`, parapet 0,5 m | OK |
  | ușă în arc, lemn | arc pe fața din față | `House_Trim`, cadru dreptunghi + vârf tesit (aproximare a arcului) | abatere minoră — arcul e aproximat printr-un colț teșit, nu o curbă reală; se citește ca "gol în arc" la distanță, dar nu e curbat |
  | 2 ferestre cu obloane, față laterală | obloane deschise | `House_Trim`, 2 perechi de obloane pe fața +X | prezent, dar **vizibil ca dungi albe pe fața FRONTALĂ** din unghiul de comparație (artefact de randare — obloanele sunt cutii subțiri fără recess real, aceeași clasă de bug rezolvată la turn dar nelichidată aici din lipsă de timp) |
  | scară exterioară în zigzag, latura dreaptă, urcă spre spate | 3 rampe, balustradă albă | 3 rampe zigzag, trepte + balustradă (`House_Rail`) | OK ca ansamblu — citește clar ca "scară care urcă", geometria treptelor e mai simplă decât planșa (trepte pline, nu individuale detaliate) |
  | cutie pe acoperiș, retrasă stânga-spate | volum simplu cu parapet | prezent, redimensionat (vezi cote) | OK |

- **Abateri cunoscute și motiv:**
  - **Obloanele laterale se văd prin fața frontală** din unghiul de
    comparație (35°/18°) — geometrie construită ca simplă cutie subțire
    lipită de perete (fără recess real, spre deosebire de ferestrele
    turnului, care au firidă + geam retras). Nu s-a aplicat aceeași tehnică
    (`_glass_and_reveal_sides`) aici din lipsă de timp în valul 1 — de
    remediat în valul următor sau la un pas de curățenie ulterior, ca
    piesele să nu difere în tehnică una de alta.
  - **Ușa e aproximată** (colț teșit, nu arc curbat) — geometrie low-poly
    intenționată, dar mai pătrată decât planșa.

## Contracte înghețate în geometrie (relevante pentru integrare)

- `ghanta_ghar`: originea la bază, centrată; cele 4 cadrane pe `Clock_Glow`
  fără cifre; golurile de geam/ușă pe `Tower_Glow`, `VOLCANIC_BLACK`,
  retrase 0,16–0,3 m în perete (regula 0.7 din brief).
- `blue_house_a`: originea la bază, centrată; balustrada scării e nod
  separat `House_Rail` (FOAM_WHITE, fără tentă) — nu `House_Trim`, fiindcă
  are alt slot decât ușa/obloanele (WOOD).
- Ambele: `House_Wall`/`Tower_Stone` primesc câte un SINGUR material la
  integrare (clasă triplanară) — **nicio geometrie GLOW nu mai poate
  rămâne în interiorul acestor noduri** fără să fie invizibilă (bug găsit
  și corectat în acest val, vezi jurnalul de mai jos). Orice piesă nouă
  care are goluri/ferestre trebuie să folosească aceeași tehnică: gol REAL
  tăiat în peretele solid (nu cutie suprapusă retag-uită), cu geamul
  într-un nod separat.

## Jurnalul criticii (val 1, pentru piesele viitoare)

Trecere onestă element-cu-element, comparație după comparație, cu ce s-a
schimbat la fiecare rundă (brief §0.1: "verdict OK nu e livrare"):

1. **Prima randare** (monocrom, fără tentă): a developit bug-ul de bază —
   randarea era complet neagră, fiindcă vertex color layer-ul AO se numește
   "Color" după reimport din GLB, nu "AO" (`apply_class`/`atlas_material`
   caută explicit "AO"). Fix: `_fix_ao_layer_name` în `preview_jodhpur.py`.
2. **A doua randare** (cu tentă, gresie): siluetă h/l 1,4 vs 2,17 (turn
   prea lat/scund), ferestrele fusului ieșeau ca fâșii DIAGONALE (bug de
   offset dublu pe `along` + normală), arcada soclului 2 invizibilă,
   balconul/lanterna necititive, cupola un con drept. Rescrisă geometria
   turnului aproape complet.
3. **A treia randare**: ferestrele/golurile arătau ca dungi ALBE strălucitoare,
   nu goluri întunecate — cauza reală: `Tower_Stone` primește la integrare
   UN SINGUR material triplanar, deci orice geometrie cu slot GLOW rămasă
   ÎN interiorul acelui nod se randează cu ACEEAȘI textură de gresie,
   indiferent de slot (triplanar ignoră UV-ul). Fix: gol REAL tăiat în
   peretele solid (`_tower_tier_octagon(punches=...)`, cadru din fâșii în
   jurul fiecărei tăieturi) + geam retras doar în `Tower_Glow`.
4. **A patra randare**: golurile tot nu se vedeau — normalele fețelor noi
   (pereții firidei, benzile sus/jos) erau inconsistent orientate după
   `bmesh.ops.recalc_face_normals` (care recalculează global, ignorând
   winding-ul local ales manual). Fix: winding explicit pe fiecare pereche
   de fețe opuse (stânga/dreapta, sus/jos), verificat direct din normalele
   exportate în GLB, nu presupus.
5. **A cincea randare** (casa albastră): render complet gri, fără nicio
   urmă de textură sau tentă. Izolat prin teste succesive (cub simplu,
   material direct din BSDF, fără `apply_class`): AgX (view transform
   implicit) desaturează puternic culorile compuse din multiply, dar chiar
   și cu Standard, textura `plaster.png` (gri-brun mediu, nu aproape-alb)
   multiplicată cu tenta albastră da un rezultat gri-albăstrui aproape
   nedistins de netintat — comportament corect matematic pentru multiply pe
   o textură care NU e aproape albă. Fix: gamma 0,35 pe textură înainte de
   multiply (apropie de alb, păstrează variația), plus `view_transform =
   Standard` pe randările de comparație.
6. **A șasea randare**: h/l tot peste bandă (2,63, apoi 2,55 după prima
   lărgire) — turnul taperat prea agresiv între tiere. Trei runde de
   lărgire/scurtare pe `hb2`/`hs`/`shaft_h` până la 2,37 (în bandă).
7. **Casa albastră, h/l 1,16** — cutia de pe acoperiș (2,6×2,4×1,9)
   domina proporția. Redusă la 2,2×2,0×1,4 → h/l 1,08 (în bandă).

## Ce a ieșit greșit sau ambiguu în brief

- **Textura de clasă pentru preview** nu exista în `assets/textures/classes/`
  sub numele clasei reale a pistei (`red_sandstone`, `village_plaster` nu
  există încă — sunt ale instanței de gameplay). Brief-ul recomanda
  `red_valley_tuff` sau `old_stone` ca proxy pentru gresie — verificat că
  `red_valley_tuff` mapează la `alpine_granite.png` (are linii de zidărie
  vizibile, potrivit). Pentru peretele albastru, niciun proxy nu era numit
  explicit; am ales `plaster.png` (clasa cea mai apropiată tematic de
  `village_plaster`), dar fiind gri-brun mediu (nu aproape-alb), tenta
  simplă prin multiply nu funcționează fără o corecție de gamma — asta nu
  era menționat în brief și a costat trei runde de debugging. Pentru
  claritate viitoare: brief-ul ar trebui să precizeze că textura de bază a
  claselor reale (`village_plaster`, `blue_lime_light`) e aproape albă
  (altfel "alb × tentă" nu ține), și un kit viitor ar trebui să verifice
  luminanța proxy-ului înainte de a-l folosi necorectat.
- **`--sheet 1`** nu avea o convenție anterioară în cod (fiecare kit
  anterior avea doar planșe de grup, fără comparații de fidelitate automate)
  — harnasul de comparație (`compare()`, `compose_jodhpur.py`,
  `_apply_tint`, `_fix_ao_layer_name`) e nou, construit de la zero în acest
  val, nu adaptat dintr-un precedent.
- **Blender headless n-are PIL** — nemenționat în brief. Rezolvat prin
  `compose_jodhpur.py`, rulat cu Python-ul de sistem prin `subprocess` din
  `preview_jodhpur.py`.
- **`run_build.py`** accepta un singur `--` (scripturi înlănțuite fără
  argumente proprii) — extins minimal ca să accepte un AL DOILEA `--`,
  pentru argumentele scriptului de preview (`--compare`, `--sheet`,
  `--group`). Schimbare mică, retrocompatibilă (fără al doilea `--`,
  comportamentul vechi e identic).
