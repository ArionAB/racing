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

- Triunghiuri: **8.350** (`Bayon_Stone` 6.234, `Bayon_Lichen` 1.900,
  `Bayon_Streak` 216). Fără plafon.
- Noduri și sloturi: `Bayon_Stone` = `ROCK_LIGHT` 3 (clasa `angkor_sandstone`
  la integrare); `Bayon_Lichen` = `LAVA_ORANGE` 30 (44 de pete) + `CACTUS_GREEN`
  12 (16 tufe); `Bayon_Streak` = `VOLCANIC_BLACK` 20 (nu `ROCK_DARK`). **Materiale: 3**
  (un nod = un material). Fără alb, fără `ROCK_DARK`, fără texturi proprii.
- Arii (din fișier): total 419 m² (include suprafețele ascunse dintre
  învelitorile suprapuse), lichen portocaliu **0,70%** (limita 3%, verificată de
  garda), verde 0,38%, dâre 0,64%.
- Origine: baza amprentei, centrat pe X și Z; scala 1 și rotația identitate pe
  cele trei rădăcini (verificat în `verify_angkor.sh`).
- Primitive rotunde: bobocul 14 laturi, finialul 8. Restul sunt prisme octogonale, cutii și
  învelitori convexe.
- AO copt în vertex colors (28 de raze, distanță 0,7 m, forță 1,35, plafon
  0,30): crăpăturile (fanta ochilor, linia gurii, rosturile) ies întunecate.

## Fidelitate

Imagini (`docs/asset_briefs/img/angkor_fidelity/`; din runda 5 și `bayon_face_tower_a_face.png`, close-up pe față din față și 3/4, ~1000 px, mod `--face`):
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

**Runda 5** (doar fața și diadema; 19.862 tri; garda verde). Ce s-a schimbat:
- **Ochi:** două pleoape SEPARATE (tuburi netede, semilună convexă în jos, colțul
  exterior coborât), cu suprafața puntii nasului între ele; deasupra fiecăreia o
  sprânceană arcuită moale, despărțită de pleoapă printr-un jgheab (suprafața
  fetei). Nu mai e nicio bandă continuă.
- **Rotunjit:** fața = cupolă ovală din inele (maxilar în arc, fără colțuri la
  bărbie), obrajii = elipsoizi 16×10, aripile nasului = bumbi rotunzi, buzele și
  pleoapele = tuburi netede (învelitori de inele eliptice), urechile = elipsoizi;
  umbrire netedă (prag 55°). Fără subdiviziune propriu-zisă: forma are
  segmentele în ea.
- **Nas:** ~0,27·H, bază lată, vârf rotund, fără creastă (corp din inele).
- **Buze:** sus arc ușor, jos plină, colțuri mai mici și urcate, două gropițe;
  lățime 0,36·H (~0,45 din fața de 0,82·H).
- **Diadema:** bandă PLATĂ (~0,3 m), lipită de frunte, fără surplomb, cu 3 rozete
  pe față; capacul de deasupra: surplomb 3 cm (era 8).
- Probleme în timpul rundei: primul val de margele-elipsoizi dădea „cârnați”
  (nu pleoape), iar un artefact de umbrire pe frunte (dungi verticale) și o
  cută la bărbie au fost corectate; garda a prins vârful nasului la 1,502.

**Verdict onest, runda 5 (oprire, cum s-a cerut).** Nu mai citește ca ochelari
(ochii sunt separați, cu groapă și sprânceană deasupra) și nu mai citește ca
Moai (fără creastă ascuțită, fără fălci pătrate, fără planuri). În schimb
citește **ca o față de desen animat prietenoasă**, nu ca un chip Bayon senin:
obrajii sunt prea mari și prea rotunzi („clovn”), buzele sunt două bare care la
distanță dau impresia unei mustăți, nasul e un con, iar fața e netedă și „de
cauciuc”, fără masa de piatră a modelului. În decuparea gamecam citește clar ca
față cu ochii închiși și zâmbet; ca „Bayon senin” nu o semnez. Nu am mai iterat.

**Rundele 3–5, pe scurt, și de ce a picat fiecare** (fețe construite din cod):
- **Runda 3:** fața de 2,2 m ca placă într-o nișă între pilaștri. A picat: citea
  ca **mască într-un cadru**, iar fața era prea mică pentru camera de joc (~25 px).
- **Runda 4:** fața de 3,0 m, blocul fețelor = lățimea turnului. Corpul turnului a
  fost acceptat; fața a picat: **Moai** (nas lung cu creastă, obraji plani, falcă
  pătrată) și ochi-ochelari (sprânceană și pleoapă într-o bandă peste nas).
- **Runda 5:** forme netede (elipsoizi, tuburi). A picat: **clovn / desen animat**
  (obraji-discuri, buze-bare ca mustața, nas conic, aspect de cauciuc).

**Runda 6** (decizia dezvoltatorului, 6 nov 2026: fără față sculptată; 8.350 tri).
Înapoi la blocul de piatră fațetat din runda 4, cu fața redusă la câteva forme
MARI și PUȚIN ADÂNCI: două sprâncene separate (arcuri, ~7 cm relief, fără
bandă); doi ochi separați, semilună convexă în jos, ca o creastă de pleoapă cu
o a doua creastă dedesubt și jgheabul între ele (nimic nu trece peste nas); nas
pană scurtă și lată (~0,25·H, vârf bont, relief ≤ 0,12 m); o singură gură
largă (0,36·H, ~0,45 din fața de 0,82·H), colțurile urcate, două părți apropiate
care citesc ca o buză cu linie; fără discuri de obraz, fără bile la nări sau în
colțuri, fără gropițe; maxilarul e un contur rotunjit tăiat în bloc; urechile
la colțuri; diadema plată cu 3 rozete rămâne (runda 5). Etajele, dârele,
baza și fusul rămân din runda 4. Garda verde, anvelopa ±1,5 exactă.

**Datorie deschisă — fețele sculptate.** Fețele sunt simplificate prin decizia
dezvoltatorului (6 nov 2026) după cinci runde de fețe din cod. Ele cer sculptură
reală mai târziu (image-to-3D din decupare, modele CC-BY/CC0 sau modelare
manuală). Aceeași decizie se aplică pieselor sculptate din valurile următoare:
`south_gate_face_tower`, `deva_giant`/`asura_giant`, `leper_king_statue`,
`naga_head`, reliefurile de elefanți. (Textul și în `angkor_kit.md` §1.1.)

### Element cu element (după runda 4)

| element | pe desen | în GLB | verdict |
|---|---|---|---|
| siluetă | turn, fețele în mijloc, con de etaje | 3,0 × 9,0 m; bază 0–1,5, fus 1,5–2,7, fețe 3,0–6,6, 4 etaje, boboc | OK: fețele SUNT volumul turnului; etajele fac un con din rânduri; mai în trepte decât conul desenului |
| baza | piramidă în trepte, mai lată decât corpul | 3 trepte 1,50 / 1,40 / 1,30, blocuri în relief; fus de 2,4 m | OK |
| blocul fețelor | fețele umplu lățimea turnului | 2,56 m pe latură (nucleu), cu fața bombată; ~3,0 m sprânceană–bărbie | OK |
| fețe | rotunde, senine, ochi închiși, zâmbet | după runda 6: placă ovală fațetată, sprâncene și ochi-semilună separați, nas pană scurtă, un zâmbet | calm, citește ca „față sculptată în piatră”; **simplificată** (datorie deschisă), nu portret |
| urechi | lobi lungi lângă față | la colțuri, 0,1 m în relief | OK |
| diademă | bandă cu nervuri peste frunte | bandă plată ~0,3 m cu 3 rozete, fără surplomb | OK |
| urna | punct pe frunte | **absentă, voit** (brief §8) | abatere voită |
| etaje | 4–5 rânduri, colțuri rotunjite | 4 etaje × 2 rânduri octogonale + cornișe subțiri | OK; mai plate/disciplinate decât blocurile desenului |
| vârf | boboc de lotus | boboc de revoluție 14 laturi, 8 + 8 petale | OK; mai colțuros |
| lichen | pete portocalii pe tot | 44 + 16 pete, doar pe orizontale, 0,70% / 0,35% | **abatere voită** (contract) |
| dâre | negre sub cornișe | 14, scurte, ascuțite, 0,64% | OK; încă albăstrii |
| culoare | ocru saturat | gresie `#AD9877` (clasa) + AO | **abatere voită** |
| iese din contur | nimic | nimic dincolo de ±1,5 (măsurat) | OK |

## Camera de joc (`--gamecam`) — verdict onest, nu acceptare

Camera la 10 m înălțime și 12,5 m în spatele unui punct aflat la 30 m înaintea
turnului, fov 68°, soare la 24° din spatele camerei, baza îngropată 1 m.
Fața are ~35 px la rezoluția nativă. În decuparea 3× citește ca „turn de piatră
cu o față calmă pe fiecare latură”: ochi închiși ca două semilune, nas pană,
zâmbet discret, urechi la colțuri, coroană de etaje. Nu e portret, nu e mască,
nu e caricatură. La 1× (cadrul întreg) rămân silueta de con, blocul lat din
mijloc și o pată mai luminoasă cu urme de trăsături; trăsăturile fine se pierd,
pentru că sunt joase (voit). Verdictul real îl dă criticul orb.

## Abateri rămase, pe față

1. **Fețele sunt simplificate, nu sculptate** (datorie deschisă, vezi mai sus).
2. Placa feței e netedă și lată; fără modelarea obrajilor și a buzelor din desen.
3. Lichenul e mult mai discret decât în desen (contract); dârele sunt albăstrii.
4. Fără bevel pe gresie; etajele sunt plăci octogonale netede.

## Integrare pe Track24 (coordonator, 6 nov 2026)

**Acceptat** după runda 6, cu datoria deschisă de mai sus (fețele simplificate).
Schimbarea e scrisă de `tools/gen_angkor_route.py` (scena rămâne generată):

- `Obstacole/BayonTurn0..2` își păstrează **corpul** (cutia de 3 × 9 × 3 m, baza la
  1 m sub terasă); macheta gri (`Macheta`, `Mesh_bayon`) e scoasă;
- vizualul e `DecorManual/BayonA0..2` = `bayon_face_tower_a.glb`, cu originea pe
  baza cutiei (cota terasei − 1) și `metadata/coliziune = "none"` (corpul e al
  cutiei). Toate trei pe varianta `a` până la valul 1 (`b`, `c`);
- clasa: `CLASSES_ANGKOR` în `world_prop.gd` (`Bayon_Stone` → `angkor_sandstone`),
  intrarea `"angkor"` în `CLASSES_BY_THEME`. Lichenul și dârele rămân pe atlas.

Gărzi: `ProbeAngkorPas6` OK (turnurile și podeaua de linie neschimbate);
`probe_manual --track=24` OK (bazele la 0,70–0,75 m sub teren, adică îngropate
cât trebuie, fiindcă terasa e drumul); `probe_decor --track=24` **19 materiale**
(plafon 38). Cele trei turnuri apar ca „MultiMesh neatribuit” (25.050 tris =
3 × 8.350): decorul manual e copt în loturi. **Găsit pe drum:** `probe_decor`
scana doar `Track01..23`, deci Angkor n-a avut niciodată garda de materiale —
singura cu drept de veto; bucla merge acum până la 99.

În joc (`--gamecam`, `img/angkor_montaj/bayon_E_0415.png`, `bayon_E_0430.png`):
turnul cel mai apropiat se citește „turn de piatră cu față calmă” (ochi, nas,
zâmbet vizibile pe clasa de gresie). Terasa e încă asfalt cu marcaj (puntea de
gresie e la pasul 8, brief §5.1).
