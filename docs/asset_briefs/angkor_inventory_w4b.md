# Inventar — kit Angkor, val 4, grupul B (vegetatia mica)

Contract: `docs/asset_briefs/angkor_kit.md` §1.7. Build: `tools/blender/build_angkor_plants.py`
(helperii `spline`, `bx`, `wall_faces` se incarca din `build_angkor_gates_w.py`). Garda:
`tools/blender/measure_angkor_w4b.py` (in `verify_angkor.sh`, blocul `# --- val 4, grupul B ---`).
Randari: `preview_angkor.py --compare` (doar SPECS adaugate) si `preview_angkor_w4b.py`
(`--compare` cu suvitele desfacute pe X, `--views`, `--curtain`).
Imagini: `docs/asset_briefs/img/angkor_fidelity/` — `strangler_fig.png`, `vine_strands.png`,
`lotus_cluster.png`, `water_lily_pads.png` (+ `_views`), `vine_curtain_60.png`, `vine_curtain_144.png`.
Verdictul de acceptare e al coordonatorului.

## Cote masurate din fisier (coordonate Godot)

| piesa | contract | masurat | noduri |
|---|---|---|---|
| strangler_fig | ~10 m, zid ~5 m | X 9,01 x Y 9,77 x Z 7,60; zidul `Fig_Stone` 5,00 | `Fig_Stone` (3), `Fig_Root` (19), `Fig_Leaves` (21 + 12) |
| vine_strands | 4–6 `Strand_*`, 3,0–4,5 m, ~0,3 lat | 6 suvite: 4,40 / 3,80 / 3,40 / 4,50 / 3,00 / 3,60; latime 0,16–0,44; max Y 0,000–0,003 | `Strand_0..5` (liane 21: 0, 2, 4; radacini 19: 1, 3, 5) |
| lotus_cluster | 1,5–3 m, ≤ 0,4 | 2,45 x 1,90 in plan; Y 0,000–0,370 | `Lotus_Leaves` (21 + 12), `Lotus_Flowers` (31, 21, 12) |
| water_lily_pads | 1,5–3 m, ≤ 0,05 | 2,38 x 2,24; Y 0,002–0,043; 7 pad-uri, fiecare cu crestatura | `Lily_Pads` (21 + 12) |

Originea: ficus — baza, pe axa zidului; suvite — **punctul de agatare (sus), atarna pe −Y Godot**,
transformari identitate (toate 6 suprapuse in origine: consumatorul le ia pe rand, previzualizarea le
desface 0,9 m); lotus/nuferi — cota apei (stinghie la 0,000 / 0,002). Nimic peste originea suvitelor
(max Y ≤ 0,003).

## Triunghiuri

| piesa | tri |
|---|---:|
| strangler_fig | 20.226 (piatra 1.632, radacini 13.974, frunze 4.620) |
| vine_strands | 1.302 — pe suvita: 254 / 276 / 158 / 226 / 158 / 230 (toate ≤ 300) |
| lotus_cluster | 1.236 |
| water_lily_pads | 840 |

`verify_glb`: lotusul foloseste slotul 31 → `--allow-slots=31` (exceptie declarata, ca la
`penguin_tawaki`); suvitele cer `--origin=rim` (atarna sub Y=0); ficusul si plantele de apa `assembly`.

## Perdeaua (`--curtain`, camera de joc, perdeaua la 40 m inaintea masinii)

Suvitele sunt scalate pe Z ca varful sa cada la 0,7–2,3 m (factor 0,73–1,43, medie ~1,05). Masurat pe
masca de alfa, pe axa drumului (13 m): fractia de coloane de pixeli cu cel putin o suvita.

| varianta | coloane 2,4–4,8 m | coloane 0,7–2,3 m |
|---|---:|---:|
| 60 suvite (15 x 4 randuri, pas 0,87) | 90,0% | 66,8% |
| 144 suvite (36 x 4, pasul 0,36 din cod) | 100% | 92,3% |

Contractul „≥ 60% din latimea benzii la 40 m” e atins in ambele, dar cu 60 de suvite doar la limita pe
banda de jos (66,8%). Atentie: jumatate din suvitele livrate sunt argintii (3 din 6); `VineCurtain` are
`root_share` 0,12 — la 50% perdeaua iese vizibil mai bej decat cea de azi.

## Fidelitate (citire onesta, nu acceptare)

- **strangler_fig:** citeste ca zid cu fascicul de radacini turtite care curg peste coama si pe ambele
  fete si se rasfira pe sol; fasciculul (3 groase + frati subtiri + legaturi laterale) e apropiat de desen.
  **Slab:** trunchiul de deasupra zidului e un sul de sfori netezite, nu radacini care se unesc; coronamentul
  e o ciuperca rotunda (desenul: smoc plat si mic, zid in trepte, nise); zidul e prea regulat si inalt; radacinile
  sunt mai late/palide decat cele ale desenului, iar „gaura” de sub radacini lipseste. 20k tri, din care
  14k radacini — scump pentru decor pe marginea drumului.
- **vine_strands:** lianele au frunze romb pliate, prea putine si ascutite fata de frunzele-inima ale desenului;
  radacinile argintii citesc ca fire palide cu noduri (cea rasucita si cea cu radacinite se vad). De la 40 m
  suvitele sunt linii subtiri; perdeaua citeste ca „gard de liane” rar, nu ca zid dens de frunze.
- **lotus_cluster:** frunze rotunde concave, doua ridicate, patru flori; florile sunt mici fata de desen
  (desenul: flori mari, centru galben) si **ies liliachii**, nu roz: slotul 31 (D2A0BE) e un roz-lila de la
  atlas, deci culoarea e a slotului, nu a geometriei. Fara centru galben (capsula e 12, mica).
- **water_lily_pads:** pad-uri rotunde cu crestatura si centru mai deschis, plate; desenul are lobi/nervuri si
  galben-verde, aici sunt discuri curate, verde inchis. Citeste ca nuferi, dar „simplu”.

## Garda

`measure_angkor_w4b.py`: anvelope, nume, sloturi, `Strand_*` (4–6, identitate, max Y ≤ 0,05, 3,0–4,5 m,
latime 0,1–0,45, ≤ 300 tri), inaltimi lotus/nufar, crestatura pe fiecare pad (arie proiectata < 95% din
discul bbox), ficus 10 ± 1,5. `--selftest`: suvita in sus, 5,5 m, cu varful peste origine, cu scala, a
saptea suvita; nufar ridicat 0,3 m; nufari fara crestatura; lotus ridicat 0,5 m; ficus turtit — toate pica,
originalele trec.
