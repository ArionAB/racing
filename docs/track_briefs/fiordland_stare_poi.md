# Fiordland — starea POI-urilor după gauntlet (26 sep 2026)

Nota de predare a sesiunii de decor pe cele 8 POI-uri ale pistei Fiordland
(Track16, temă `fiordland`, index 9). Contractul e
`docs/track_briefs/fiordland_poi_gauntlet.md`; aici e ce s-a întâmplat pe el.

## Pe scurt

- **Toate cele 8 zone sunt populate** (`DecorManual/ZoneA_Chei` … `ZoneH_Mal`),
  fiecare cu generatorul ei `tools/gen_decor_fiord_<x>.gd` + `GenDecorFiord<X>.tscn`.
- **Niciun POI n-a câștigat orb** (0/8, criticii au ghicit de fiecare dată) —
  ca pe Serengeti (0/8) și Machu Picchu (0/3). Toate au ieșit pe regula (c) sau
  pe o repetiție pe care am tratat-o la fel (vezi tabelul).
- **Acceptarea finală e la volan**, pe uscat și în ploaie, pe scena integrată.

## Cum s-a ieșit din buclă, per POI

| POI | runde | ieșire | diferența care s-a repetat | cauza sub decor |
|---|---|---|---|---|
| A Cheiul | 3 | (c) r2=r3 | vaporașul citește „cutie albă” | silueta GLB `cruise_boat` văzută de la 10 m |
| B Cornișa | 5 | (c) r4=r5 | peretele de gneis monocrom, fără dungi ude | scara triplanară `wet_gneiss` (6,25 m/repetiție) pe piese de 2,5 m; lipsa peretelui în relief |
| C Stirling | 6 | repetiție r4=r6 (neconsecutivă, decizia coordonatorului) | bazinul de spumă nu se citește | bazinul există (FoamPool); de la 0.28 e la 37 m, la 0.297 camera e în perdea |
| D Chasm | 3 | (c) r2=r3 | coronamentul plat, „gard viu” | asset-ul `beech_*`: coroane din plăci orizontale |
| E Portalul | 3 | (c) r2=r3 | grohotișul „lipsește” (591 piese puse) | movila tunelului bej cu textură de zidărie, munții-con netezi |
| F Coborârea | 3 | (c) r2=r3 | molozul înșirat, fără trunchiuri | tipul de moloz permis de gameplay (AI-ul nu vede decor static) |
| G Bowen | 3 | repetiție r1=r3 (pădurea) | pădurea rară/regulată | asset-ul fagului (ca D) |
| H Malul | 6 | oscilație pe pădure (4 din 6 verdicte) | fagii: rari → clone → goi → prea deși | asset-ul fagului (ca D, G) |

**Tiparul dominant:** pădurea de fag a fost numită pe B, D, G, H. Nu e așezarea
(s-au încercat rânduri decalate, jitter, clustere, goluri) — e silueta asset-ului.

## Reparate pe drum (fundație comună, nu decor de POI)

- **Solul și apa** (c4b992e7): solul ieșea alb-gri cu granulație de nisip pe toată
  pista, apa turcoaz placeholder. `scarp_tint` pe pantă (mecanism existent, nesetat
  pe temă), `ground_tint` mușchi închis, chei `water_*` pe SEA_DEEP cu fațete mari.
- **Bolovanii cu mușchi** (a4491e4d + caa57bb3): `moss_boulder_*` ieșeau damier /
  alb / portocaliu (sloturi brute ale reuse-ului MP); `SLOT_REMAP_BY_THEME` — care
  **nu se aplica niciodată la runtime** (DecorManual rula înaintea temei) până la
  `call_deferred`.
- **Gneisul** (0f83d9aa, 46a05dbd): `wet_gneiss` 0,40 pe `stirling_ledge`/`torrent_chute`;
  `CLASSES_BY_THEME` pune `wet_gneiss` pe `chasm_rock` doar pe tema fiordland.
- **Acoperișurile tan** (ae21609a): `House_Roof` lua maparea globală `roof_tiles` a
  satului Okinawa; excepție pe fișier (`ATLAS_PREFIX`) pentru `cafe_shed`/`lodge`.
- **Vopseaua plată** (`PLAIN_PREFIX`): carena `cruise_boat` și `luggage_container`
  primeau triplanarul de lemn al lumii.
- **Cascada Bowen** (2ab5cf33): lipsea din scenă (doar markerul kickerului). Perdea
  permanentă, decorativă, fără forță, în bazin (partea sgn=−1).
- **Gărzi reparate:** `probe_manual` — scutirea „pe stâncă” era pe NUME, acum e test
  fizic (a prins 6 plutitoare ascunse); `fiord_frustum_table.py` — citea prima curbă
  din scenă (a avionului), acum `Curve3D_fiordland`; sondă nouă
  `probe_pileup_footprint.gd` (amprenta pieselor `none` pe carosabil).
- **ProbeRace** (baf7e7e3 + fixul de la podeț): decor pe traiectoria aterizării
  Bowen (pietriș fără gardă, hull-ul bolovanilor > raza nominală → `HULL_SAFETY_MULT`
  1,4) și la furca Chasm (marmite în calea autobuzelor).

## Gărzile pe scena integrată

Pe `fiord/poi-integrare` după toate merge-urile, `--import` înainte:

| gardă | rezultat | prag |
|---|---|---|
| probe_decor `--track=16` | **27 materiale**, 5192 prop-uri | ≤ 38 (+2 cerute la POI H: `concrete`, `village_plaster`, clase existente) |
| probe_manual `--track=16` | OK, 0 de reparat | 0 |
| ProbeBuried `--track=9` | 0 îngropate, 86 tavane | 86 = tunelul, și pe main (contractul zicea greșit „0 tavane”) |
| ProbeTunel `--expect-tube` | OK | verde |
| ProbeLaneClear `--track=9` | 8 | baza 8 |
| ProbeLayout `--track=9` | OK, pantă max 12,7 % | < 13 % |
| ProbeFiordScurtatura | TRECE | TRECE |
| sv_hazard_orient `--scene=16` | 1 suspect: AvalansaF | cunoscut |
| fiord_frustum_table | PICĂ pe F1 | ca pe main, decizia (b) |
| ProbeRace uscat seed 1–8 | tur min 1,62–1,68; **0 [blocaj] pe decor**; 3 [blocaj] generice (asfalt/acostament) la 0.608/0.882 | main: 1,53–1,66 |
| ProbeRace ploaie seed 1–2 | tur min 1,58 / 1,57; 0 [blocaj] | main: 1,60 / 1,57 |

Poarta literală „tur minim ≥ 1,64 pe toate 8 seed-uri” nu e atinsă pe seed 8
(1,62) și nu e atinsă nici pe main (seed 1: 1,53); distribuția integrării e la
nivelul sau peste a lui main.

## Decizii deschise pentru dezvoltator

1. **Fagul** (`beech_a/b/c`): coroane din plăci orizontale citesc „gard viu” /
   „lollipop” pe 4 POI-uri. Refacere în Blender cu coroane în mase rotunjite, sau
   acceptat la volan.
2. **Vaporașul** (`cruise_boat`): citește „cutie” de la camera de joc. Refacere cu
   carenă curbată și cabină cu geamuri vizibile de sus, sau acceptat.
3. **Gneisul ud pe piese mici**: scară triplanară separată pentru piese < 3 m (+0–1
   material), sau acceptat.
4. **Relieful**: peretele în sus pe cornișă (B) și nișa Stirling (C) cer un mecanism
   de falie liniară (cod nou); prototipul cu `TerrainPeak` a dat dealuri conice și nu
   e recomandat (`fiord/poi-relief`, neunit). **Rezolvat 26 sep 2026, `fiord/falie`:**
   nod `Faleze/PereteCornisa` (`CliffFace.cut_wall`, deja folosit pe Cappadocia și
   Machu Picchu — reutilizat, zero cod nou în `cliff_face.gd`), frac 0,052–0,271,
   `side=-1` (opus golfului). Terenul de pe partea muntelui era plat pe toată
   cornișa, deci `cut_min_rise_m=30` declară înălțimea peretelui direct, ca la
   taietura dintre buclele Serengeti. Nișa Stirling **nu a cerut relief nou**:
   e deja geometrie GLB (`stirling_ledge`, Wall/Overhang/Shelf), iar peretele nou
   se oprește la 0,271 ca să nu se suprapună cu ea. Hash pe `ground_y` identic la
   bit pe Track09/11/13/14/16 (mecanismul e placed geometry, nu atinge terenul);
   probe_manual/probe_decor/ProbeRace neschimbate pe alte piste; 0 incidente noi
   pe B/C în 8 seed-uri. **Runda 2 (26 sep, corecție de compoziție):** peretele
   înghițea decorul de gneis din fața lui și fața citea artificial (linii albe
   de cusătură UV). Talpa peretelui (`cut_edge_offset_m` 0,2→12,0) s-a mutat
   dincolo de banda de bolovani (măsurat, nu presupus: `gneisWall`/`wallFoot`
   p95 lateral 11,7/10,9 m), fanul feței s-a strâns (`cut_batter_m`/
   `cut_facet_m`/`cut_tread_m` reduse) ca și coama să rămână în spate, iar
   `CliffFace` a primit un export opt-in nou (`material_class`, gol = vechiul
   `world_material()`, bit-identic pe celelalte piste) prin care fața ia
   aceeași clasă triplanară `wet_gneiss` pe care o folosește deja decorul
   (`chasm_rock`) — zero materiale noi, dispar liniile de cusătură. 119 din
   226 de fagi din primul rând (deveniți geometric interiori peretelui după
   mutarea tălpii) au fost scoși direct din scenă. Gardă nouă permanentă:
   `tools/probe_wall_overlap.gd` (AABB decor vs. peretele REAL construit,
   pe frac/lateral/înălțime) — țintă și rezultat 0. ProbeRace 8 seed-uri,
   minim de tur 1,61–1,65 (seed 1 excepție cunoscută, Autobuzul la tunel),
   0 incidente la frac ≤ 0,30 pe toate cele 8.
5. **Valea de sub podeț** (D): gata de unit dacă spui da — `fiord/poi-relief`
   f2ad9480, râpa 1 era pe aceeași parte cu scurtătura și protecția benzii o
   aplatiza; side +1 → −1 dă valea de −8 m din brief. Gărzile verzi.
6. **Kickerul Bowen**: `[blocaj]` generice la aterizare (asfalt/acostament, fără
   decor atins) mai dese decât pe main. De reglat banda de aterizare cu trafic real.
7. **Stâlpul semaforului** (`trafficPoleEast`): îngropat în movila tunelului; lămpile
   aliniate în alveole nu se văd.
8. **Movila tunelului**: iese bej cu textură de zidărie, nu granit gol.
9. **Git**: `stash@{0}` „WIP on fiord/poi-h” e lăsat de un constructor care a
   încălcat regula; munca e comisă pe `fiord/poi-h`, stash-ul e redundant.

## Deciziile dezvoltatorului (26 sep 2026)

| # | decizie | livrat |
|---|---|---|
| 1 | fagul | neatins (nedecis) |
| 2 | vaporașul | înlocuit cu „Cruise Ship – toofan”; caiacele cu „Canoe – Low poly” (CC-BY-4.0, `assets/CREDITS.md`) |
| 3 | gneisul ud pe piese mici | **ignorat** |
| 4 | relieful (peretele B / nișa C) | `Faleze/PereteCornisa` (`CliffFace.cut_wall`), frac 0,052–0,271 — vezi §4 de mai sus (`fiord/falie`, 26 sep) |
| 5 | valea de sub podeț | unită (f2ad9480), plus râu transversal și podeț real (`PodetChasm`, `TrackChannel` static) |
| — | Stirling „nu simt nimic” | impact lateral + yaw + shake + picurat + sfx (`WaterfallHazard`, grupul „Impact la intrare”) |
| — | torentul „nu are impact” | același impact, mai dur, prin `TorrentCycle`; parbrizul ud pornește acum și la torent |
| — | avalanșa | 10 s |

Rămân deschise: 1, 6, 7, 8 de mai sus; caiacele din zona H (`malKayak`) nu
apar (generatorul le respinge pe cotă — preexistent); `sealRock1` ridicat manual
de dezvoltator e semnalat „plutește” de `probe_manual`.

### Valul din 26 sep, după #416/#417

| decizie | stare |
|---|---|
| 1 fagul | **refăcut** în Blender: mase rotunjite în loc de plăci (`build_fiordland_forest.py`, `_crown_tier`); aceleași triunghiuri |
| 4 relieful B/C | **rezolvat** cu `CliffFace` (vezi mai sus); nișa C era deja `stirling_ledge.glb`; 119 fagi `wallForest*` scoși (erau în perete) |
| 6 kickerul Bowen | **lăsat așa** (decizia dezvoltatorului); buclele de repunere de acolo sunt nedeterministe (același seed: 7 / 0) |
| 7 stâlpul semaforului | **scos** (dezvoltatorul, 796d8b82); lampa e reconstruită de `TunnelSignalHazard` |
| 8 movila tunelului | `wet_gneiss` în loc de `alpine_granite` (bej → gri rece); **forma** (bloc cu față verticală) încă citește „zid” — nedecis |
| sunet | **amânat** |
| vaporașul pe traseu | adăugat manual de dezvoltator (796d8b82) |
| kea | **anulat**: pe o pistă unde nimeni nu oprește la roșu, kea pe capotă nu are când să aterizeze |
### Acceptate la volan după PR #416 (26 sep 2026)

- Scurtătura din pădure câștigă +1,35…+1,93 s pe uscat (peste fereastra 0,5–1,5):
  **acceptat**, `ProbeFiordScurtatura` free rămâne roșu în cunoștință de cauză.
- Stirling `push_speed` 9: **bine așa**.
- `sealRock1` ridicat: **intenționat** (probe_manual îl raportează, se ignoră).
- Spuma râului colțuroasă: se rezolvă cu atlasul de culori.
- Caiacele lipsă din zona H: **ok așa**.
