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

- Triunghiuri: **8.330** (`Bayon_Stone` 5.422, `Bayon_Lichen` 1.900,
  `Bayon_Streak` 1.008). Fără plafon.
- Noduri și sloturi: `Bayon_Stone` = `ROCK_LIGHT` 3 (clasa `angkor_sandstone`
  la integrare); `Bayon_Lichen` = `LAVA_ORANGE` 30 (44 de pete) + `CACTUS_GREEN`
  12 (16 tufe); `Bayon_Streak` = `VOLCANIC_BLACK` 20 (nu `ROCK_DARK`). **Materiale: 3**
  (un nod = un material). Fără alb, fără `ROCK_DARK`, fără texturi proprii.
- Arii (din fișier): total 447 m² (include suprafețele ascunse dintre
  învelitorile suprapuse), lichen portocaliu **0,86%** (limita 3%, verificată de
  garda), verde 0,28%, dâre 2,84%.
- Origine: baza amprentei, centrat pe X și Z; scala 1 și rotația identitate pe
  cele trei rădăcini (verificat în `verify_angkor.sh`).
- Primitive rotunde: bobocul 14 laturi, finialul 8. Restul sunt cutii și
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

### Element cu element

| element | pe desen | în GLB | verdict |
|---|---|---|---|
| siluetă | turn subțire, fețele în mijloc, etaje care se îngustează | TURN: 3,0 × 9,0 m (h/l = 3,0), bază 0–1,5, soclu 1,5–2,7, fețe 3,0–6,1, 4 etaje, boboc | OK ca structură; mai **în trepte și mai cutie** decât desenul, care e un con continuu |
| baza | trepte largi de blocuri | 3 trepte (1,50 / 1,38 / 1,27), blocuri în relief | OK |
| soclu | rânduri mari de blocuri sub fețe | 3 rânduri de blocuri, cornișă dublă pe gât | OK |
| fețe | 2 vizibile, ochi închiși, zâmbet, nas lat, urechi cu lobi lungi | 4 (câte una pe latură), ~2,2 m sprânceană–bărbie, ochi închiși (pleoape cu fantă), nas lat 0,30 m în relief, buze pline, urechi cu lobi | OK ca citire; **fațetate** (învelitori convexe), mai „sculptate în piatră” și mai puțin rotunjite decât desenul |
| diademă | bandă arcuită cu nervuri, fronton | bandă arcuită cu 9 nervuri + fronton | OK |
| urna de pe frunte | punct pe frunte | **absentă, voit** (iconografie de Buddha, brief angkor.md §8) | abatere voită |
| pilaștri de colt | coloană îngustă între fețe | 4 pilaștri de 0,3 m | mai prezenți decât pe desen: fața stă într-o „fereastră” |
| etaje | 4–5, colțuri cu ornamente ascuțite | 4 etaje, frontoane la mijlocul laturii, finialuri în colțuri | OK; ornamentele sunt piramide simple |
| vârf | boboc de lotus cu petale | boboc de revoluție (14 laturi), 8 + 8 petale-învelitori, finial | OK ca rol; mai colțuros decât desenul |
| lichen | pete portocalii mari, mult, și pe fețe verticale | 44 portocalii + 16 verzi, **doar pe orizontale**, 0,86% / 0,28% din arie | **abatere voită** (contract: sub 3%, pe orizontale); pe randările de la înălțimea ochiului pervazurile abia se văd, deci piesa e mult mai „curată” decât desenul |
| dâre | negre sub cornișe | 2,84% din arie, benzi pe jumătatea de sus a pereților, sub cornișe | OK ca loc; mai înguste, mai dure și mai albăstrii (`VOLCANIC_BLACK`) decât cele pictate |
| culoare | ocru-portocaliu saturat | gresie `#AD9877` (clasa) + AO | **abatere voită** (paleta; culoarea o dă clasa) |
| iese din contur | nimic | nimic dincolo de ±1,5 | OK (măsurat) |

## Camera de joc (`--gamecam`) — verdict onest, nu acceptare

Camera la 10 m înălțime și 12,5 m în spatele unui punct aflat la 30 m înaintea
turnului, fov 68°, soare la 24° din spatele camerei, baza îngropată 1 m.
**La rezoluția nativă a cadrului (1920×1080) fața are ~25 px înălțime**: se
vede o bandă de diademă, o pată luminoasă cu nasul ca o muchie și gura ca o
liniuță; ca „față” citește marginal. În decuparea mărită 3× (pixeli nativi,
nu randare nouă) citește clar: sprâncene, ochi închiși, nas, gură, urechi. Ce
ține citirea: relieful la nas/sprâncene care aruncă umbră sub soarele jos și
AO în fanta ochilor și în linia gurii. Ce o slăbește: fața e doar ~25% din
înălțimea turnului (contract: 2,2 m din 9,0), iar planul feței e mai întunecat
decât nucleul din jur, deci pare o „mască într-o nișă”. Verdictul real îl dă
criticul orb pe capturi din joc (§1.1: „față”/„chip” la ≥ 2 din 3 capturi).

## Abateri rămase, pe față

1. Fețele sunt din învelitori convexe: fațetate, cu muchii vizibile la
   aproape. Rotunjirea (subdiviziune sau profile de revoluție pe obraz) n-a
   încăput în buget de muncă în pilot.
2. Lichenul e prea discret față de desen (contract), iar dârele sunt albăstrii.
3. Fără bevel pe gresie: muchiile sunt vii; clasa triplanară va da rosturile
   fine, dar nu muchiile rotunjite ale desenului.
4. Silueta e în trepte; desenul are etajele mai late la bază și mai
   continue spre vârf.
5. Pe cadrul nativ din joc fața e mică (vezi mai sus). Dacă criticul orb o
   respinge, pârghiile sunt ale coordonatorului (contractul: 2,2 m) — fața
   mai mare cere ori nucleu mai lat, ori ieșit din cutia de 3 m.
