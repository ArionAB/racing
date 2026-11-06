# Inventar — kit Angkor (Track24)

Contract: `docs/asset_briefs/angkor_kit.md`. Acest fișier e al pilotului
(harnas + `bayon_face_tower_a`); piesele din valurile următoare se adaugă aici.

## Harnasul

| fișier | rol |
|---|---|
| `tools/blender/angkor_shapes.py` | vocabular: `Frame` (sistem local u/w/z cu yaw), `hull`, `stone_box`, `stepped_base`, `block_courses` (rânduri de blocuri în relief), `tier` (etaj cu nervuri, cornișă, frontoane, finialuri), `lotus_bud`, **`face_relief(b, origin, yaw_deg, H, ...)`** (fața Bayon ca geometrie, parametrizată pe înălțimea feței `H`), `lichen_spot`, `streak`, `emit_angkor` (finish pe fiecare nod, offset de origine calculat o dată pe ansamblu, export în `assets/models/angkor/`) |
| `tools/blender/build_angkor_bayon.py` | `bayon_face_tower_a` (docstring = lista de elemente, scrisă înainte de geometrie); `VARIANTE` e dicționarul de parametri (etaje, boboc, `ruin`), deci `b` și `c` sunt schimbări de parametri; `ANK_ONLY=<a\|b\|c>` reface o singură piesă |
| `tools/blender/preview_angkor.py` | din GLB-ul exportat: `--compare <nume>` (decupare \| randare, 3/4, #C4C4C4, culori reale din UV, `*_Stone` pe tinta clasei), `--views <nume>` (4 azimuturi), `--gamecam <nume>` (camera de joc) |
| `tools/blender/compose_angkor.py` | compunerea cu PIL (reia `compare`/`montage` din `compose_transfagarasan.py`, adaugă `--gamecam`) |
| `tools/blender/measure_angkor.py` | garda anvelopei Bayon, citește GLB-ul (JSON + accesoare + transformări) în coordonate Godot; `--selftest` o dovedește pe copii sabotate |
| `tools/blender/verify_angkor.sh` | `verify_glb` pe fiecare GLB (`--origin=assembly`, plasă de 1.000.000), anvelopa, nodurile, scala/rotația pe rădăcini, GLB-uri nedeclarate, `VERDICT KIT` |

Culoarea gresiei din preview: `#AD9877`, **derivată**, nu ghicită. Clasa
`angkor_sandstone` = dala `alpine_granite.png` × tentă (1,0, 0,86, 0,66)
(`scripts/palette.gd`). Media dalei în spațiu liniar e (0,4167, 0,3652, 0,2771);
× tentă = (0,4167, 0,3140, 0,1829) liniar = `#AD9877` sRGB (aplicată direct în
sRGB ar da `#A68660`; materialul Godot înmulțește în liniar). `palette.gd` o
numește provizorie: se recalibrează pe captura pistei.

## bayon_face_tower_a.glb — cote măsurate (Godot, din fișier)

| | X | Z | înălțime Y | min Y |
|---|---:|---:|---:|---:|
| `bayon_face_tower_a.glb` | −1,500 … +1,500 (**3,000**) | −1,500 … +1,500 (**3,000**) | **9,004** | 0,000 |
| contract | nimic dincolo de ±1,5; lățimea 2,9–3,0 | idem | 9,0 ±0,1 | ≈ 0 |

Garda (`measure_angkor.py bayon`) citește fișierul, nu build-ul. Vârful nasului
e la 1,49 (nucleul de 1,19 + 0,30 m de relief), treapta de jos la 1,50 exact.

- Triunghiuri: **7.022** (`Bayon_Stone` 4.906, `Bayon_Lichen` 1.900,
  `Bayon_Streak` 216). Fără plafon.
- Noduri și sloturi: `Bayon_Stone` = `ROCK_LIGHT` 3 (clasa `angkor_sandstone`
  la integrare); `Bayon_Lichen` = `LAVA_ORANGE` 30 (44 de pete) + `CACTUS_GREEN`
  12 (16 tufe); `Bayon_Streak` = `VOLCANIC_BLACK` 20 (nu `ROCK_DARK`). **Materiale: 3**
  (un nod = un material). Fără alb, fără `ROCK_DARK`, fără texturi proprii.
- Arii (din fișier): total 446 m² (include suprafețele ascunse dintre
  învelitorile suprapuse), lichen portocaliu **0,70%** (limita 3%, verificată de
  garda), verde 0,35%, dâre 0,60%.
- Origine: baza amprentei, centrat pe X și Z; scala 1 și rotația identitate pe
  cele trei rădăcini (verificat în `verify_angkor.sh`).
- Primitive rotunde: bobocul 14 laturi, finialul 8. Restul sunt prisme octogonale, cutii și
  învelitori convexe.
- AO copt în vertex colors (28 de raze, distanță 0,7 m, forță 1,35, plafon
  0,30): crăpăturile (fanta ochilor, linia gurii, rosturile) ies întunecate.

## Fidelitate

Imagini (`docs/asset_briefs/img/angkor_fidelity/`):
`bayon_face_tower_a.png` (decupare | randare), `bayon_face_tower_a_views.png`
(4 azimuturi), `bayon_face_tower_a_gamecam.png` (camera de joc: cadrul de
1920×1080 la jumătate, lângă decuparea turnului la pixeli nativi, mărită 3×;
două cadre, turnul pe axa drumului și cu 4 m în dreapta).

### Cele trei runde

**Runda 1** (primul build, 18.894 tri). Turn, nu bust: bază în 3 trepte, soclu,
patru fețe în treimea din mijloc, patru etaje, boboc. Ce a ieșit prost, văzut
în randare: sprâncenele grele și oblice dădeau o privire furioasă, ochii păreau
mijiți, **bobocul de lotus dispărea printre frontoane**, lichenul era atât de
mic încât nu se vedea, soclul era o masă netedă, iar pilaștrii de colt (0,4 m)
făceau din față o „fereastră”.

**Runda 2.** Bobocul mai înalt (0,95 m în loc de 0,84) și **ultimul etaj fără
frontoane/finialuri**, ca să rămână el vârful; rânduri de blocuri în relief pe
trepte și pe soclu (`block_courses`, 4 cm, rosturi de 3,5 cm); pilaștri de 0,3 m;
sprâncene mai subțiri și mai drepte, pleoape mai bombate, buza de jos mai
subțire, zâmbet 0,6 în loc de plin; pete de lichen mai mari.

**Runda 3** (22.634 → 7.726 tri). Obrajii eliptici ieșeau ca două discuri
roz-clovn: **scoși**. Zâmbet 0,45 (fața calmă a Bayonului, nu rânjetul), apoi
buze puțin mai pline (lățime 0,165·H, grosime +20%) fiindcă pe camera de joc
gura dispărea. Bevel 0 pe `Bayon_Stone` (cutiile și învelitorile nu mai
primesc 3,7× triunghiuri; la 40 m nu se vedea), în schimb AO mai tare (distanță
0,7, forță 1,35). Lichen 44 + 16 pete, mărite.
Garda a prins în runda 3 un defect real: o pată de lichen de pe treapta de jos
ieșea cu 1 mm din patrat (Z = 1,501); fixat (`rw ≤ 0,40·lățimea pervazului`).

**Runda 4** (corectura coordonatorului după runda 3; 7.022 tri). Cinci schimbări:
1. **Fără nișă și fără pilaștri.** Blocul fețelor (3,0–6,6 m) are jumătate-lățimea
   1,28 și e cel mai lat element de deasupra bazei; fusul de sub el are 1,20
   (≈ 2,4 m), deci fețele sunt umflătura. Fața se bombează în afară (trei straturi:
   nucleu, obraji, față), diadema stă direct pe frunte și face trecerea spre
   etaje, urechile cu lobi lungi stau la colțuri, unde se întâlnesc două fețe.
2. **Fața rescrisă** (`face_relief`): lată (0,80·H, maxilar lat, fără bărbie
   ascuțită); sprânceană = arc continuu care urcă din puntea nasului (nu bară);
   pleoape grele, închise, semilună cu partea convexă în jos; nas lat și plat cu
   aripi late; buze late (mai late decât aripile nasului), cea de jos mai plină,
   colțurile ridicate (zâmbet 0,9). Adâncimea e în nas (0,15 m peste obraz),
   buze, pleoape și masa obrajilor, nu într-un raft de sprânceană.
3. **Fața mărită:** H = 3,0 m (era 2,2), în 3,0–6,6 m.
4. **Vârful:** frontoanele triunghiulare și țepii de colț scoși; etajele sunt
   două rânduri de blocuri octogonale (colțuri chanfrenate), fiecare mai îngust,
   sub o cornișă subțire, cu mici finialuri rotunjite la colțuri; con continuu
   până la boboc (0,83 m).
5. **Dârele:** 14 în total, scurte, late sus și ascuțite jos, doar sub cornișa
   gâtului și sub primele două etaje; 0,60% din arie (era 2,84%).
Baza rămâne 3,0 m la treapta de jos (1,50 / 1,40 / 1,30). Garda confirmă ±1,5.
Două iterații interne în rundă: prima versiune a ochilor ieșea ca ochelari de
soare (pleoapă + arc separat + punte), iar buzele, ca o dungă; ochii au devenit
o singură masă sprânceană-pleoapă, buzele s-au îngroșat și zâmbetul a crescut.

### Element cu element (după runda 4)

| element | pe desen | în GLB | verdict |
|---|---|---|---|
| siluetă | turn, fețele în mijloc, con de etaje | 3,0 × 9,0 m; bază 0–1,5, fus 1,5–2,7, fețe 3,0–6,6, 4 etaje, boboc | OK: fețele SUNT volumul turnului; etajele fac un con din rânduri; mai în trepte decât conul desenului |
| baza | piramidă în trepte, mai lată decât corpul | 3 trepte 1,50 / 1,40 / 1,30, blocuri în relief; fus de 2,4 m | OK |
| blocul fețelor | fețele umplu lățimea turnului | 2,56 m pe latură (nucleu), cu fața bombată; ~3,0 m sprânceană–bărbie | OK |
| fețe | rotunde, senine, ochi închiși, zâmbet | late, pleoape grele, nas lat, buze late; **fațetate** (învelitori convexe) și mai „de piatră” | citește ca față cu zâmbet; încă puțin masivă/„moai” față de desen |
| urechi | lobi lungi lângă față | la colțuri, 0,1 m în relief | OK |
| diademă | bandă cu nervuri peste frunte | bandă arcuită cu 11 nervuri, direct pe frunte | OK; seamănă și cu o „streașină” văzută de sus |
| urna | punct pe frunte | **absentă, voit** (brief §8) | abatere voită |
| etaje | 4–5 rânduri, colțuri rotunjite | 4 etaje × 2 rânduri octogonale + cornișe subțiri | OK; mai plate/disciplinate decât blocurile desenului |
| vârf | boboc de lotus | boboc de revoluție 14 laturi, 8 + 8 petale | OK; mai colțuros |
| lichen | pete portocalii pe tot | 44 + 16 pete, doar pe orizontale, 0,70% / 0,35% | **abatere voită** (contract) |
| dâre | negre sub cornișe | 14, scurte, ascuțite, 0,60% | OK; încă albăstrii |
| culoare | ocru saturat | gresie `#AD9877` (clasa) + AO | **abatere voită** |
| iese din contur | nimic | nimic dincolo de ±1,5 (măsurat) | OK |

## Camera de joc (`--gamecam`) — verdict onest, nu acceptare

Camera la 10 m înălțime și 12,5 m în spatele unui punct aflat la 30 m înaintea
turnului, fov 68°, soare la 24° din spatele camerei, baza îngropată 1 m.
După runda 4 fața are ~35 px înălțime la rezoluția nativă (era ~25) și ocupă
mijlocul turnului pe toată lățimea. În decuparea mărită 3× citește ca „turn
făcut din fețe”: bloc lat cu nasul ca muchie luminată, ochi închiși sub sprâncene,
gură largă, urechi la colțuri, coroană de etaje deasupra; nu mai e un tablou
într-un cadru. Seren: în general da (pleoape grele, zâmbet); nu e caricatură,
dar are ceva de „statuie de insulă” prin nasul lung și fălcile pătrate. La 1×
(cadrul întreg) rămân vizibile mai ales silueta de con, blocul lat din mijloc și
umbra nasului; ochii și gura sunt puncte. Verdictul real îl dă criticul orb
(§1.1: „față”/„chip” la ≥ 2 din 3 capturi).

## Abateri rămase, pe față

1. Fețele sunt din învelitori convexe: fațetate, cu muchii vizibile la aproape
   și mai „moai” decât desenul (nas lung, fălci pătrate).
2. Lichenul e mult mai discret decât în desen (contract: sub 3%, pe orizontale);
   dârele sunt încă albăstrii (`VOLCANIC_BLACK`).
3. Fără bevel pe gresie: muchiile sunt vii.
4. Etajele sunt plăci octogonale netede; desenul are blocuri vizibile pe ele.
5. Diadema citește uneori ca streașină.
