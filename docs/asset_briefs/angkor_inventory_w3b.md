# Inventar — kit Angkor, val 3, grupul B (galeria + Bakheng)

Contract: `docs/asset_briefs/angkor_kit.md` §1.5. Build: `tools/blender/build_angkor_kit.py`
(docstring = lista de elemente, scrisa inainte de geometrie; helperii gopurei se incarca din
`build_angkor_gates_w.py`, nu se copiaza). Garda: `tools/blender/measure_angkor_w3b.py` (in
`verify_angkor.sh`, blocul `# --- val 3, grupul B ---`). Randari: `preview_angkor.py --compare`
(doar SPECS adaugate) si `preview_angkor_w3b.py --gallery / --bakheng` (ansambluri).
Imagini: `docs/asset_briefs/img/angkor_fidelity/<nume>.png` si `gallery_assembly.png`,
`bakheng_assembly.png`. Verdictul de acceptare e al coordonatorului.

## Cote masurate din fisier (coordonate Godot; chain Blender +Y = Godot -Z)

| piesa | contract | masurat (X x Y x Z) | noduri |
|---|---|---|---|
| gallery_column | 0,5 x 3,5 x 0,5 | 0,500 x 3,520 x 0,500 | Stone, Lichen, Streak |
| gallery_roof | 4,0 x ~2,0 x 4,0 (L pe Z) | 4,000 x 2,028 x 4,000; capete **+-2,0000** | Stone, Lichen |
| gallery_relief_wall | 4,0 x 3,5 x 0,6 (L pe X, relief pe +Y) | 4,000 x 3,528 x 0,612; capete **+-2,0000** | Stone, Lichen, Streak |
| gallery_corner | 4,0 x 4,0 | 4,000 x 5,528 (pereti 3,5 + acoperis 2,0) x 4,000 | Stone, Lichen |
| bakheng_terrace_tier | L 8,0 x h 1,5 (L pe X) | 8,000 x 1,528 x 4,040 (adancime); capete **+-4,0000** | Stone, Lichen, Streak |
| bakheng_shrine_tower | ~4 x 2,5 x 2,5 | 2,500 x 4,021 x 2,500 | Brick (23), Stone, Lichen, Streak |
| bakheng_side_stair | h 3,0, latime 2,0 | 2,024 x 2,940 x 3,460 (lungimea rampei) | Stone, Lichen, Streak |

(Inaltimile includ lichenul de 2–2,8 cm de pe orizontale.) Originea: baza, pe axa modulului.

**Inaltimea de rezemare a acoperisului: 3,5 m** (varful stalpului = varful zidului de relief). Acoperisul
se pune cu baza modulului (arhitrava, z = 0) la z = 3,5, deci coama ajunge la 5,5 m.

## Conventia de montaj (galerie)

- Pas 4,0 m. Stalpii stau cu axa pe planul de imbinare al modulelor, la x = -1,5; zidul de relief la
  x = +1,7 (x 1,4..2,0), cu fata sculptata spre interior (se roteste 90 de grade fata de modulul brut,
  la fel ca terasa elefantilor). Axele de lant difera, deci: acoperisul pe Y, zidul si etajul de terasa pe X
  (relieful pe +Y, §0.4); in joc se rotesc.
- **Coltul** (viraj la stanga: intra dinspre -Y, iese spre -X) are peretii E si N cu relief spre interior si
  acoperisul cu vale la SW si cosar la NE. **N-are stalpi proprii:** se sprijina pe stalpii de capat ai
  bratelor, la (-1,5; -2,0) si (-2,0; -1,5). Fara ei, coltul SW al acoperisului sta in aer.
- Fiecare apsara: 5 pe modul, centre la -1,6 … +1,6 (pas 0,8), deci ritmul continua peste rost.

## Triunghiuri, materiale

| piesa | tri | noduri/materiale |
|---|---:|---|
| gallery_column | 952 | 3 (gresie 3; lichen 30+12; dare 20) |
| gallery_roof | 1.280 | 2 |
| gallery_relief_wall | 1.840 | 3 |
| gallery_corner | 3.182 | 2 |
| bakheng_terrace_tier | 2.624 | 3 |
| bakheng_shrine_tower | 5.622 | 4 (caramida `TILE_TERRACOTTA` 23 pe `_Brick`) |
| bakheng_side_stair | 3.072 | 3 |

Fara alb, fara `ROCK_DARK`, fara texturi proprii; lichen portocaliu 0,3–1,8% din arie (< 3%).

## Fidelitate (citire onesta, nu acceptare)

| piesa | pe desen | in GLB | verdict |
|---|---|---|---|
| column | fus cu blocuri, trepte jos, capitel evazat | 7 randuri de blocuri decalate, 3 trepte, 2 inele + evazare + abac | citeste; **mai zvelt** decat desenul (contractul cere 3,5 x 0,5); fara muchii sparte |
| roof | pantat, tigle curbate, rand de blocuri pe coama, rezemat pe stalpi | invelis convex cu 4 nervuri, antefixe, 4 blocuri pe coama | citeste ca acoperis pantat/butoi; **corbelul in trepte de pe desen e netezit** intr-o panta, nervurile dau tiglele |
| relief_wall | 7 apsare in panou, rama sus/jos | 5 apsare blocate (fusta trapez, bust, brate frante, tiara in 3 trepte), relief 11 cm, soclu + cornisa cu blocuri | citesc ca siluete de personaje, **nu ca dansatoare**; fara portrete (decizia de simplificare) |
| corner | colt cu stalpi si acoperis | doi pereti in L cu relief interior, acoperis cu vale + cosar | acoperisul citeste; **desenul are stalpi pe laturile deschise, aici vin din lant** |
| tier | grămada de blocuri in trepte | 3 randuri cu fata trasa inapoi, blocuri de grosime variata, rosturi lipsa, coronament, lespezi pe fata de sus | citeste ca etaj de terasa; **mai regulat** decat desenul (fara scara frontala; scara e piesa separata) |
| shrine | caramida, usa oarba, varf in trepte | soclu, corp pe 10 randuri, usa oarba pe +Y + nise pe celelalte, 3 etaje, varf de gresie | citeste foarte aproape de desen; usa nu e intunecata (panou de gresie) |
| stair | scara abrupta cu obraji de blocuri | 12 trepte din lespezi, doi obraji cu coronament in trepte | citeste; obrajii sunt mai drepti decat desenul |

## Runde

Runda 1: toate sapte pe prima trecere. Runda 2: dare prea mari (arata ca niste tepi) reduse; tiara apsarei din
sageata in 3 trepte; fata de sus a etajului in lespezi; obrajii scarii in randuri orizontale. Garda a prins un
defect real inainte de runda 2: mana si cotul ultimei apsare treceau de +-2,0 cu 2,5 cm si
lasau 36 de varfuri in banda dinaintea capatului zidului (capat nelant), reparate prin
reducerea pozei bratelor.

## Abateri si deschise

1. Sculptura apsarelor e simplificata (kit "Datorie deschisa"); o sculptura reala vine mai tarziu.
2. Axele de lant difera (acoperis Y; zid, etaj X), cf. contractului; coordonatorul roteste la montaj.
3. Coltul cere stalpii de capat ai bratelor (vezi mai sus). Lantul B nu e testat dincolo de o travee.
4. Ansamblul Bakheng: etajele se sprijina cu 0,9 m intre ele, iar spatele iese in deal (tampon verde in randare).
5. Sabotajele din `--selftest` sunt in memorie pe lista de triunghiuri a fisierului real; garda pica pe toate 6
   si trece pe cele 4 originale (column, roof, wall, tier).
