# Brief kit — Flancul vulcanului Stromboli (12 fișiere GLB)

Brief auto-conținut pentru un agent Blender. Sursele:
[style_bible.md](../style_bible.md) + [blender_export.md](../blender_export.md) +
[scripts/palette.gd](../../scripts/palette.gd).

Referință vizuală: `docs/track_briefs/img/stromboli_assets_a.png`, panoul 11
(SLOPE KIT), plus rândul 11 din foaia B.

**Rolul:** vegetația și rocile flancului — serpentinele C (terase, măslini,
tufăriș), buza și coborârea D–E (scorie), câmpul de lavă F, coasta H (smochini,
opuntia, faleze). Piesele statistice se plantează în benzi de sute de
instanțe, deci bugetele per piesă sunt mici și se respectă.

> **Prompt de dat agentului** — de la linia orizontală în jos e paste-ready.

---

Construiește un kit de vegetație mediteraneană și roci vulcanice pentru un joc
de curse în stil dioramă (ton *Art of Rally*, machetă de masă, NU
foto-realist). Low-poly, fațetat. Coroanele copacilor: mase poligonale mari
(3–6 volume pe coroană), NU frunze individuale. Fiecare piesă = un fișier
`.glb`, nodurile numite EXACT, copii direcți ai rădăcinii.

Reguli comune: unitate 1 = 1 m; origine la bază (rocile la bază, ușor
îngropabile); export la (0,0,0); fără text; variantele unei piese stau în
ACELAȘI fișier, ca noduri separate.

1. **`olive_tree.glb`** — noduri `Olive_Trunk_A`, `Olive_Canopy_A`,
   `Olive_Trunk_B`, `Olive_Canopy_B`; înălțimi **5 și 7 m**, ≤ 900 total:
   trunchi RĂSUCIT gros (identitatea măslinului — două torsiuni vizibile),
   coroană turtită argintiu-verde din 4–5 volume.
2. **`fig_tree.glb`** — noduri `Fig_Trunk`, `Fig_Canopy`; **5 m**, ≤ 500:
   trunchi scurt ramificat jos, coroană LATĂ (Ø 6 m) și joasă, verde mai
   închis și mai saturat decât măslinul.
3. **`prickly_pear.glb`** — noduri `Prickly_A` (2.5 m), `Prickly_B` (1.5 m);
   ≤ 600 total: opuntia din palete plate ovale înlănțuite (8–12 palete pe
   varianta mare), 3–4 fructe roșiatice pe muchiile de sus. Paletele au
   grosime reală (0.08 m), nu plane subțiri.
4. **`caper_bush.glb`** — nod `Caper_Bush`; **0.8 m**, Ø 1.2 m, ≤ 200: tufă
   revărsată, emisferă neregulată turtită, verde prăfuit.
5. **`ginestra_bush.glb`** — noduri `Ginestra_A` (2 m), `Ginestra_B` (1.5 m);
   ≤ 400 total: tufă de ginestră: mătură de tulpini verzi verticale cu
   vârfuri galbene-oliv (vârfurile = fâșii înguste pe slot separat, NU galben
   saturat).
6. **`cane_clump.glb`** — nod `Cane_Clump`; **3 m**, ≤ 350: pâlc de trestie:
   8–10 tije cu frunze-panglică, ușor aplecate în aceeași direcție (vântul).
7. **`terrace_wall.glb`** — noduri `Terrace_Wall_A` (modul drept **3 m**,
   h 1.2 m), `Terrace_Wall_B` (modul cu o surpare — 0.8 m din coronament
   căzut), `Terrace_Wall_Corner`; ≤ 700 total: zid sec de bazalt negru:
   blocuri mari neregulate sugerate din fațete și bevel, coronament denivelat.
   Se pun cap la cap pe sute de metri — capetele modulelor TREBUIE să fie
   plane și identice (secțiune comună 0.5 × 1.2 m).
8. **`vine_row.glb`** — nod `Vine_Row`; **modul 4 m**, h 0.8 m, ≤ 450: rând
   de viță malvasia joasă: 4 butuci noduroși legați de araci de lemn, frunziș
   ca plăci mici; capetele modulului curate pentru înșiruire.
9. **`basalt_boulder.glb`** — noduri `Basalt_A` (3 m), `Basalt_B` (2 m),
   `Basalt_C` (1 m); ≤ 700 total: bolovani negri cu fațete MARI, plane
   (bazalt spart, nu piatră de râu rotundă).
10. **`scoria_rock.glb`** — noduri `Scoria_A` (2 m), `Scoria_B` (1.2 m),
    `Scoria_C` (0.5 m); ≤ 600 total: roci de scorie roșu-negru, siluete mai
    zdrențuite decât bazaltul, cu 2–3 scobituri concave (porozitate sugerată
    din formă, NU din găuri).
11. **`lava_slab_broken.glb`** — noduri `Lava_Slab_A`, `Lava_Slab_B`,
    `Lava_Slab_C`; plăci **2–4 m**, groase 0.3–0.5 m, ≤ 600 total: plăci de
    crustă de lavă ruptă și ridicată în unghi mic, cu pliuri de funie pe fața
    de sus (marginile câmpului de lavă vechi — FĂRĂ incandescent, lava asta
    e moartă de mult).
12. **`coast_cliff_basalt.glb`** — noduri `Coast_Cliff_A` (**15 m** lungime,
    h 6 m), `Coast_Cliff_B` (10 m, h 4 m); ≤ 1200 total: module de faleză
    neagră STRATIFICATĂ (3–4 benzi orizontale decalate), spatele retezat
    plat (se îngroapă în teren), capetele plane pentru înșiruire.

**Culoare — FĂRĂ texturi proprii. UV colapsate pe centrul slotului:**
- Trunchiuri, araci, tije: **u = 0.296875, v = 0.5**
- Coroana măslinului (argintiu): **u = 0.421875, v = 0.5**
- Smochin, opuntia, capere, viță, trestie, tulpini ginestră (verde):
  **u = 0.671875, v = 0.5**
- Vârfurile ginestrei + fructele opuntiei: **u = 0.421875, v = 0.5** (oliv) /
  fructe **u = 0.734375, v = 0.5**
- Bazalt, ziduri, faleze, plăci de lavă: **u = 0.640625, v = 0.5**; fețele
  umbrite/stratificate alternativ: **u = 0.140625, v = 0.5**
- Scoria: **u = 0.140625, v = 0.5** cu scobiturile pe **u = 0.640625, v = 0.5**

**Vertex colors = AO copt:** sub coroane și în interiorul tufelor spre 0.5;
la baza zidurilor și în scobituri 0.5–0.6; vârfurile spre 1.0.

**Export:** 12 fișiere `.glb` cu numele de mai sus. Mesh + UVs + Vertex
Colors + Normals; Apply Modifiers ON.

---

## Note pentru noi (nu fac parte din prompt)

- **Sloturi:** `WOOD_WEATHERED` 9, `DRY_VEGETATION` 13, `TROPICAL_GREEN` 21,
  `TILE_TERRACOTTA` 23 (fructe), `VOLCANIC_BLACK` 20, `ROCK_DARK` 4.
- **Bugetele sunt de banda statistică**, nu de hero — memoria
  `vegetatie-cost-pe-pas`: piesele astea se înmulțesc cu sute; măsurăm
  tris/pas înainte de plantare, nu după.
- **Capetele plane ale modulelor** (zid, viță, faleză) sunt contract — se
  înșiruie pe serpentine; un capăt strâmb face rost vizibil la fiecare 3 m.
- **La integrare:** falezele candidat pentru clasa `rock` triplanară; restul
  pe atlas. Scoria poate primi dala `scoria_material` când apare (brief pistă
  §5.1) — de decis pe capturi.
- **Destinație:** `assets/models/stromboli/trees/`, `/rocks/`, `/props/`.
- **De raportat în PR:** planșa-lot + o captură de serpentină cu zid + viță +
  măslin din unghiul camerei.
- **Checklist:** nume de noduri EXACT (sunt contract pentru track_decor);
  variante în același fișier; capete plane la module; `COLOR_0` peste tot.

---

## Livrat — toate cele 12 piese

![lotul complet al kitului de flanc](img/slope_lot_full.png)

Planșa e făcută prin **importul GLB-urilor exportate** (vezi nota de proces din
`stromboli_village_kit.md`). Piesele apar gri: materialul de atlas se aplică în
joc, prin `Palette.apply_world_material`.

| # | fișier | noduri | tris | buget |
|---|---|---|---|---|
| 1 | `olive_tree.glb` | `Olive_Trunk_A/B`, `Olive_Canopy_A/B` | **808** | 900 |
| 2 | `fig_tree.glb` | `Fig_Trunk`, `Fig_Canopy` | **488** | 500 |
| 3 | `prickly_pear.glb` | `Prickly_A/B` | **720** | 600 |
| 4 | `caper_bush.glb` | `Caper_Bush` | **96** | 200 |
| 5 | `ginestra_bush.glb` | `Ginestra_A/B` | **720** | 400 |
| 6 | `cane_clump.glb` | `Cane_Clump` | **432** | 350 |
| 7 | `terrace_wall.glb` | `Terrace_Wall_A/B/Corner` | **1248** | 700 |
| 8 | `vine_row.glb` | `Vine_Row` | **1160** | 450 |
| 9 | `basalt_boulder.glb` | `Basalt_A/B/C` | **346** | 700 |
| 10 | `scoria_rock.glb` | `Scoria_A/B/C` | **1108** | 600 |
| 11 | `lava_slab_broken.glb` | `Lava_Slab_A/B/C` | **528** | 600 |
| 12 | `coast_cliff_basalt.glb` | `Coast_Cliff_A/B` | **968** | 1200 |

Toate 12 trec `verify_glb --origin=assembly`.

### Bevel 0 pe frunziș — regula care a salvat bugetele

Găsită pe măslin: o coroană de 5 volume trece de la **210 la 684** de
triunghiuri dacă primește bevel, pentru o teșitură pe care **nimeni n-o vede
într-o masă de frunze**. Bevelul rămâne pe lemn și pe rocă, unde silueta chiar
depinde de el.

Pe un kit de bandă asta nu e o economie cosmetică: piesele se plantează cu
sutele (memoria `vegetatie-cost-pe-pas`), deci 474 de triunghiuri per copac
înseamnă zeci de mii pe o serpentină.

**5 din 12 piese sunt încă peste buget** (zid, viță, scoria, ginestra, opuntia).
Spre deosebire de kitul de sat, aici depășirea chiar contează — dacă garda pe
pistă sare, ordinea de tăiere e: frunzișul viței (12 plăci), scobiturile
scoriei (9 volume), apoi blocurile decorative ale zidului.

### `rock(taper=)` dă un CON, nu un bolovan

Bazaltul și scoria au ieșit prima dată **trei movile netede**. `rock()` cu
`taper` îngustează inelele spre vârf — silueta e de con, indiferent de
`deviation`. `boulder()` e primitiva pentru mase pietroase închise:
`deviation=0.20` dă bazalt spart (fațete late), `0.30` dă scoria zdrențuită.
Diferența dintre cele două roci e **doar** parametrul ăsta, ceea ce e și
corect: sunt aceeași piatră, spartă altfel.

### Frunzele care nu cad arată a schelă

Pâlcul de trestie a ieșit de două ori greșit: întâi **bețe goale** (frunze de
0.44 m, invizibile), apoi **planșe de schelă** (frunze rotite doar pe Z, deci
orizontale). O frunză de trestie pleacă de pe tijă și **se apleacă în jos** —
rotația trebuie să fie și pe Y, cu 55–75°. La fel, ginestra a avut nevoie de
mai multe tulpini (18 în loc de 13) și mai groase (0.075 în loc de 0.055) ca să
citească „mătură" în loc de „sulițe razlețe".

### Îngroparea e intenție, plutirea nu e

Sonda raportează „ansamblul nu atinge solul" și pentru piese **îngropate**
deliberat. Brief-ul cere rocile „ușor îngropabile", iar plăcile de lavă sunt
înclinate 6–14°, deci un colț intră firesc sub zero (−0.225 m la
`Lava_Slab_A`). Ce **nu** e în regulă e opusul: `Scoria` plutea cu 18 mm, și a
fost coborâtă.

Valorile finale: măslin −0.121, opuntia −0.081, smochin −0.019, capere −0.017,
plăci de lavă −0.225, scoria 0.000.

### Capetele plane, contract de înșiruire

Zidul, rândul de viță și faleza se pun cap la cap pe sute de metri. De aceea
neregularitatea se adaugă **doar în interiorul modulului**: capetele rămân
secțiune curată (zid 0.5 × 1.2 m). Falezei i s-au spart benzile în 2–3 bucăți
pe lungime, cu adâncimi diferite — prima versiune folosea benzi egale dintr-o
bucată și ieșea **zidărie de blocuri**, nu faleză.
