# Monument Valley — contractul per POI pentru gauntlet

> Fișa de lucru a perechilor constructor/critic pe Track19 (`monumentvalley`).
> Bara e `docs/track_briefs/img/monument_plan/diorama_v02.jpg`, decupată per
> POI în `docs/track_briefs/img/bar_monument/<POI>.png` (marit, ≥ 1800 px;
> `tools/bar/crop_monument_bar.py`, cu justificarea fiecărei casete; planșa de
> control `bar_monument/_index.png` arată dreptunghiurile pe diorama).
> Densitatea apropiată de drum (butte-uri mici, ace de stâncă, hoodoo-uri la
> 10–60 m) e mai bună în `diorama_v02_iter1.jpg`: decupajele `*_iter1` vin de
> acolo și se folosesc **doar** pentru densitate și aranjament (asfaltul din
> iter1 continuă după grilă și pe cornișă: defect declarat în brief §9.0b).
> Planul real al traseului e `img/monument_plan/monument_plan.png`. Kitul (37 de
> GLB) e în `docs/asset_briefs/monumentvalley_kit.md` (cote, contracte) și
> `monumentvalley_inventory.md` (cotele măsurate din GLB).
> **Sursa de adevăr pentru traseu e măsurătoarea de mai jos
> (`tools/sv_mv_fractii.gd`), nu brief-ul §2.**
>
> Măsurătorile sunt pe `monument/poi-bara` = **3cbe5cbb** (main după PR #456,
> fundația de integrare) + această ramură (în `Track19.tscn` doar: cele 30 de `ext_resource`-uri ale kitului, `ZonaGospodarie` și
> metadata `fractii` a zonelor; traseul, terenul și hazardele sunt neatinse). Se
> re-rulează `godot --headless --path . res://tools/SvMvFractii.tscn` după orice
> atingere a traseului sau a terenului și se corectează tabelul.

## Regula care se încalcă cel mai des

**Bara nu e layout, e look.** Diorama e o machetă pictată, văzută de sus și din
colț, în care platoul, trei monoliți, canionul, cornișa și gospodăria încap
toate într-un cadru. Pista nu face asta și nu trebuie să facă asta: din mașină
Mittens sunt doi pereți la ~11 m de marginea asfaltului, canionul e un culoar,
cornișa are căderea pe dreapta și o mesă plată pe stânga. Criticul compară
**cum arată materia** — gresia roșie în trei etaje (grohotiș dungat, perete cu
fisuri verticale, calotă palidă), pământul roșu cu urme, salvia gri-verde în
tufe, rabbitbrush galben ca singur accent viu, asfaltul negru cu linie dublă
galbenă, lemnul cenușiu al stâlpilor — nu unde cade fiecare obiect.

Corolar: un critic care spune „la noi gospodăria nu e pe un platou în colț” sau
„la noi nu se vede peretele roșu sub tot asfaltul de sus” a comparat layout-ul
și a ratat sarcina. Singura diferență care contează e una pe care o poți repara
în decorul POI-ului.

**Defectele dioramei care NU se iau din imagine** (verificate pe decupajele
mărite 3–8×; brief §8, §9.0b și măsurătorile de mai jos le contrazic):

| în dioramă | în joc | de ce |
|---|---|---|
| fustele Mittens ating drumul; între ele e ~1 lățime de drum | pereții turnurilor la **10,4 m (WM) / 11,8 m (EM)** de MARGINEA asfaltului, fusta GLB la 7,6 / 9,1 m, conul de teren la ~3,5 m (§Premise 2) | scara de joc (turnuri de 30 m, nu 300 m); drumul nu poate fi acoperit de grohotiș |
| un perete roșu continuu de platou sub asfaltul de sus (H + A) | peretele există doar la A, la ~55 m SUD de axă (terenul cade 11,5 → 0 în 40 m); pe H terenul e **plat lateral** (rampa 0,8 → 12 m) | relief, nu decor (§H) |
| belvederul (ramadă, 3 camioane, turiști) e pe un promontoriu înalt peste drum, iar drumul e jos, între pereți | cornișa e plată pe stânga (±0,5 m pe ≥ 70 m): belvederul stă **la nivelul drumului**, la 25–45 m stânga; căderea de 13 m e pe DREAPTA | geometria reală a lui F (§Premise 4) |
| gospodăria e pe un platou din colțul NE, lângă Merrick | la est de B terenul urcă de la valea y = 0 la un raft plat y ≈ +4,3 la x ≥ 420; gospodăria stă pe raft, la 125–170 m de drum | §Premise 8 |
| caii din A au șa pe spate | fără șa și fără călăreț (brief §8) | respect, regulă de design |
| haboob-ul (zidul de praf, stânga-sus) intră în decupajul G2 | e al lui `HaboobHazard` (încă nescris), nu al decorului | hazard, nu decor |
| scurtătura G′ (dunele) lipsește | poziția vine din scenă: 0.645 → 0.754 | dispărută odată cu drumurile în plus |
| patru mașini de joc cu dâră de praf | traficul/cursa sunt cod | nu e decor |
| rezervor cilindric de oțel în gospodărie | kitul nu are rezervor | cerere de asset sau omis (§Gospodăria) |

Un critic care cere una din astea a citit diorama, nu pista.

**Pista are o singură lumină** (după-amiaza târzie, soare −18°, din VSV;
`custom_sun_rotation_deg` (−18, −70, 0)), fără `DuskCycle` (spre deosebire de
Jodhpur). Deci nu există `--dusk`. Haboob-ul nu există încă în cod (brief §3,
etapa 5), deci capturile se fac pe „vreme senină”; când vine `--haboob-at=`,
POI-urile G, F, G′ se re-capturează pe faze.

## Ieșirea din buclă (aceeași ca la Fiordland și Jodhpur)

Pe Serengeti 0/8 POI-uri au câștigat orb, pe Machu Picchu 0/3, pe Fiordland
0/8. O dioramă pictată nu se bate orb de un cadru low-poly. Deci:

- **judecata rămâne oarbă** (`blind_pair.py`, o planșă per rundă, A sau B, o
  singură diferență numită);
- **ieșirea din buclă e** una din: (a) criticul alege a noastră orb; (b)
  criticul **nu mai numește nicio diferență reparabilă în decorul POI-ului**;
  (c) criticul numește **aceeași diferență de două ori la rând** — atunci cauza
  e sub decor (relief, lumină, shader, clasă de textură, asset) și se
  **oprește bucla**, cu decizia pusă în fața dezvoltatorului (memoria
  `criticul-cere-ce-zona-nu-poate-da`); verdictele se pun unul lângă altul;
- **acceptarea finală e verdictul dezvoltatorului la volan**, pe scena
  integrată. Aici e o singură fază de lumină, dar **trei eșantioane de vreme
  după ce există haboob-ul** (liniște / telegraf / traversare) și 5 eșantioane
  pe captură (memoria `o-captura-nu-e-un-verdict`).

Locuri unde (c) e de așteptat de la început, ca să nu ardă runde: (1) peretele
roșu continuu sub H (relief), (2) belvederul „pe promontoriu” (relief), (3)
calota/fațetele Mittens (asset), (4) „conuri de grohotiș” la D dacă cer mai mult
decât `TerrainPeak` r 28 / h 4 m (relief, vezi §D).

## Ce se măsoară pe scena integrată (niciodată pe worktree-ul POI-ului)

**Convenția de indici pentru Monument: `--track=19` la TOATE uneltele.** 19 e peste
lungimea listei (13), deci se rezolvă ca număr de SCENĂ → indexul 12
(`GameState.resolve_track_index`). **Nu folosi `--track=12`**: ar merge (index 12
= Monument), dar 12 e și numărul scenei Chongqing și s-a confundat deja.

Liniile de bază sunt măsurate azi, pe starea de la 3cbe5cbb:

| gardă | comandă | linia de bază / prag |
|---|---|---|
| ProbeRace | `--headless --fixed-fps 60 res://tools/ProbeRace.tscn -- --mode=race --track=19 --seconds=150 --seed=N` | **16 seed-uri** (1..16). Măsurat la 4 seed-uri: tur minim **60,9–63,4 s** (mediu 71,0–73,3), **2 repuneri/cursă, toate pe cai**: 6 din 8 la **0.155–0.158** (`CalC1/CalC2`, 300, z 204–210) și 2 din 8 la **0.770–0.772** (`CalG1/CalG2`); **0 `[blocaj]`**, 0 căderi la G2 (`saritura C2: treceri 9–10, caderi 0`). Caii sunt hazard cunoscut (AI-ul nu-i vede); decorul nu are voie să adauge repuneri în afara lor. Citește `[blocaj]`/lent/invers/carusel, nu doar repuneri (memoria `zero-repuneri-ascunde-blocajul`). `traffic_count` e 0 pe Track19: `--traffic` nu se aplică. Coloana `0.95–1.00: 16,6 m/s, 40 % lent` e pre-grila de start (mașinile stau în numărătoare), nu un defect |
| ProbeRace pe felie | idem + `--slice=A,B` | A: `0.985,1.0` apoi `0.0,0.056`; B: `0.056,0.127`; C: `0.127,0.185`; D: `0.185,0.26`; E: `0.26,0.434`; F: `0.442,0.60`; G: `0.60,0.826`; G2: `0.826,0.866`; H: `0.866,0.985` — **înainte ȘI după** orice piesă cu coliziune pe felie. Memoria `proberace-nedeterminism`: distribuții pe 16 seed-uri, nu o rulare |
| probe_decor | `--headless --path . --script res://tools/probe_decor.gd -- --track=19` | **≤ 38 materiale** (veto). Azi **22** (1750 prop-uri, 1,206 M triunghiuri, 991 prop-uri MultiMesh; sursele: `megakit_rocks`, `canyon_rocks`, `butte`, `cliff_wall`, `rock_arch`, `marker_post`, `water_tower`, `windmill`). Triunghiurile se raportează, nu pică. Un material nou se cere explicit în raport, cu ce cumpără vizual |
| probe_manual | `--script res://tools/probe_manual.gd -- --track=19` | **0 obiecte de reparat**; azi 3 obiecte în `DecorManual` (WM/EM/MB, scufundate prin proiect). Rularea în `--script` tipărește 2 `SCRIPT ERROR` din `_build_rockfall` („Nonexistent function 'new'”): artefact al modului `--script`, nu al scenei; verdictul `OK` rămâne valid |
| probe_solid | `--script res://tools/probe_solid.gd -- --track=19` | gabaritul mașinii trece liber pe toată linia; azi 3 corpuri (hull 1, mesh 2). Obligatoriu pentru orice piesă `hull`/`mesh` lângă drum (plimbă CHIAR corpul mașinii) |
| ProbeBuried | `res://tools/ProbeBuried.tscn -- --track=19` | **0** îngropate, **0** tavane (principal + Dunele; cel mai adânc +0,28 m la 0.682) |
| ProbeLaneClear | `res://tools/ProbeLaneClear.tscn -- --track=19` | **baza = 3**, exact: calul din G (`@AnimatableBody3D`, 0.780, lat −2,7: hazard intenționat) + 2× `ChannelKicker` la 0.835 (rampa săriturii G2, înainte, h 0,4 și 1,0). Orice raportare nouă e coliziune pe bandă; atribuie-o sau scoate piesa. Sabotaj verificat (`--sabotaj`) |
| ProbeCameraSolid | `res://tools/ProbeCameraSolid.tscn -- --track=19` | **1 incident = linia de bază**: 0.836, `ChannelKicker` între mașină și cameră (la 0,1 m). Orice incident nou e camera în solid |
| probe_decor_overlap | `--script res://tools/probe_decor_overlap.gd -- --track=19 --manual` | **0 piese peste asfalt, 0 îngropate în altă piesă** (regula de 55 % din cutie) — rulează pe `DecorManual` |
| ProbeLayout | `res://tools/ProbeLayout.tscn -- --track=19` | 2089,9 m, rază minimă **21,4 m la 0.87**, pantă maximă **9,8 % la 0.07**, apropiere de sine 50,7 m la 0.03; Dunele 164,8 m, câștig 63 m (28 %), rază minimă 129,9 m. Verdict OK. Constructorii de POI nu ating traseul |
| probe_manual / ProbeMasca | `res://tools/ProbeMasca.tscn -- --track=19 --frac=F --gamecam --match=<nod>` | pentru „se vede/nu se vede” pe cadrul de joc (memoria `masca-de-obiect-prin-rasterizare`); instanțele MultiMesh se citesc ca zero în `--headless` (memoria `multimesh-masuratoare-moarta`), deci densitatea vegetației se judecă pe captură, nu pe numărare |
| sv_mv_fractii | `res://tools/SvMvFractii.tscn` (headless) | nu e gardă; re-rulat după orice atingere de traseu/teren |

`--import` înaintea oricărei serii (memoria `import-invechit-falsifica-masuratoarea`)
și după FIECARE merge (memoria `merge-curat-scena-stricata`).
`probe_decor` și `probe_manual` pe `--track=19` verifică Monument (nu Baikal):
cu un număr mai mic decât 13 ar măsura altă pistă și ar da verde fals.

## Captura: ce comandă, pentru care POI

Din mașină, `--gamecam` (camera reală: 10 m sus, 12,5 m spate, fov 68 —
memoria `verifica-cu-parametrii-lui`). Snapshot **cere fereastră**, nu merge
`--headless` (memoria `snapshot-nu-merge-headless`); capturile se fac **serial**,
prin lacătul de GPU, gărzile în paralel (memoria `capturile-nu-se-paralelizeaza`).
Snapshot încarcă doar pista, nu cursa: caii (`SlidingHazard`) și bolovanii (pe
`--rock-at`) apar, traficul nu (oricum 0 pe Track19).

```
mkdir D:/GameDev/.render_lock || (aștepți: alt agent randează)
D:/GameDev/Godot_v4.7-stable_win64.exe --rendering-driver vulkan --path <worktree> \
    res://tools/Snapshot.tscn -- --track=19 --frac=<F> --gamecam [flaguri]
rmdir D:/GameDev/.render_lock
```

Calea PNG-ului se tipărește (`SNAPSHOT: …`, în `snapshots/`). Fracțiile sunt
**pe index** (cele pe care le ia `--frac`); pe Track19 divergența index–lungime
e de cel mult **0,0007 = 1,4 m** (la 0.997), deci nu contează aici. Flagurile
care există și se folosesc: `--rock-at=<ceas>` (bolovanii D/E), `--route=1`
(banda Dunele), `--eye/--look` (cameră liberă, pentru gospodărie și belvedere
când `--gamecam` nu le prinde), `--hide=<nod>`. **Nu e nevoie de niciun flag
nou** pentru POI-uri; `--haboob-at=` vine cu clasa haboob (brief §8).

| POI | frac de captură (index) | poziție (x, z) | flaguri | bară |
|---|---|---|---|---|
| A start | **0.000**, **0.020**; spre turn/moară din H: **0.960**, **0.985** | (210,−40), (252,−40); (126,−40), (178,−40) | — | `A`, `ORIZONT` |
| B coborâre | **0.050** (după viraj: dezvăluirea), **0.075**, **0.105** | (301,−16), (302,37), (301,99) | — | `B`, `B_iter1` |
| C grilă | **0.115** (semnul, 80 m înainte), **0.134** (înainte de grilă), **0.145** (după), **0.160** (caii) | (300,120), (300,160), (300,183), (300,214) | — | `C` |
| D poarta | **0.170**, **0.185** (pereții în parbriz), **0.2048** (în poartă), **0.225** | (300,235), (300,267), (300,308), (300,350) | `--rock-at` (BolovanD) | `D`, `WM`, `EM_MB` |
| E trecătoarea | **0.265** (colțul), **0.300**, **0.350** (defileu), **0.400**, **0.425** | (280,427), (209,444), (105,438), (2,449), (−51,446) | `--rock-at` (BolovanE) | `E`, `E_iter1` |
| E′ arcul | **0.405**, **0.4335** | (−9,448), (−68,445) | după `arc-v2` | `EArc` |
| F cornișa | **0.446**, **0.480**, **0.520**, **0.560**, **0.590** | (−94,445), (−160,430), (−197,356), (−180,275), (−189,214) | — | `F`, `F_belvedere` |
| G câmpia | **0.610**, **0.645** (furca), **0.690**, **0.735**, **0.790** | (−170,179), (−99,161), (−6,173), (63,128), (−22,71) | — | `G`, `G_iter1` |
| G′ Dunele | `--route=1` cu **0.05**, **0.16** (gura, 25 m), **0.55** | pe banda de 164,8 m | `--route=1` | `G` |
| G2 albia | **0.805**, **0.825**, **0.835** | (−53,64), (−83,37), (−93,19) | — | `G2` |
| H dreapta | **0.870**, **0.910**, **0.950**, **0.980** | (−61,−38), (22,−40), (105,−40), (168,−40) | — | `H` |
| Gospodăria | **0.965**, **0.990**, **0.015**, **0.040** (virajul A→B), **0.060** | (137,−40), (189,−40), (241,−40), (292,−34), (302,5) | `--eye/--look` spre (445,5,115) la nevoie | `GOSPODARIE` |

## Fracțiile reale ale traseului (NU cele din brief §2)

Măsurate pe `Track19.tscn` la 3cbe5cbb cu `tools/sv_mv_fractii.gd` (headless):
**2089,9 m**, 1045 puncte coapte, pas 2,0 m. Fracții pe index; pe lungime diferă cu
≤ 0,0007. Convenția de hartă: x est, z sud (z = −y din brief); sens orar pe plan.
Brief-ul §2.1 dă punctele în (x, y-nord); pista are z = −y.

| reper | brief | frac (index) | lungime | cotă | semi | poziție (x, z) |
|---|---|---|---|---|---|---|
| grila de start | 0.000 | **0.000** | 0 m | +12,0 | 7,0 | (210, −40) |
| viraj A (+81°, r ≈ 28) | „larg, dreapta” | **0.040** | 84 m | +12,0 | 7,0 | (292,5, −33,6) |
| cota maximă a platoului / începutul coborârii | coama 0.063 | **0.0555** / 0.0565 | 117–118 m | +12,0 | 7,0 | (301,6, −3,4) / (301,6, −1,9) |
| raza verticală minimă pe coamă | „airtime dacă geometria permite” | **151 m** la 0.0632 (airtime cere < 41) | | +11,7 | | (301,9, 11,9) |
| WM în cadru (≤ 50°) | | **0.050** | | | | |
| EM, Merrick în cadru | | **0.040** | | | | |
| capătul coborârii (y < 0,5) | asfaltul se termină 0.131 | **0.1273** | 266 m | +0,4 | 6,6 | (300,1, 145,7) |
| **grila C / începutul pământului** | 0.137 | **0.1368** | 287 m | 0,0 | 6,5 | (300,0, 166,1) |
| caii C (`CalC1/CalC2`, pe axă, crossing) | ~37 s | 0.1656 / 0.1675 | | 0,0 | | (300, 226,7 / 230,1) |
| WM: peretele cel mai aproape de axă | | **0.198** | | | | AABB x 249–283, z 292–309 |
| **poarta** (mijlocul WM–EM) | 0.206–0.297 (D) | **0.2048** | 429 m | +0,5 | 6,5 | (300,0, 308,6) |
| BolovanD (începe pe fusta lui WM) | | 0.2038 | | +6 → 0,5 | | (278,6,306) → (322,0,5,302) |
| EM: peretele cel mai aproape de axă | | **0.2096** | | | | AABB x 318–350, z 310–326 |
| viraj D (+52°, r ≈ 44) | 0.257, r 46 | **0.2593** | 542 m | +1,5 | 6,5 | (288,8, 419,1) |
| începutul lui E (semi 5,5) | 0.297 | **0.297** | 621 m | +2,9 | 5,5 | ~(220, 440) |
| defileul (`TrackCliffs`, gorge) | 0.33–0.42 | **0.3292–0.4191** | 688–876 m | +4,0 → +8,0 | 5,5 | (149,1, 438,6) → (−38,3, 446,5) |
| BolovanE (pornește pe zid, traversează) | | 0.3684 | | | | (72,9,478) → (69,3,426), traversează drumul la z ≈ 444 |
| **arcul E′** | 0.434 | **0.4335** | 906 m | +8,7 | 5,5 | (−68,3, 444,6) |
| începutul lui F (viraj +49°) | 0.434 | **0.4699** | 982 m | +10,1 | 6,0 | (−143,5, 443,0) |
| cornișa (`custom_ravines`, adânc 13 m, dreapta) | 0.434–0.600 | **0.470–0.600** | 982–1254 m | +10,1 → +13,6 | 6,0 | cădere −13,3 m la +14…+40 m dreapta, doar 0.485–0.585 |
| virajele F | | 0.5177 (+40°, r 57), 0.5684 (−32°, r 72) | | +12,0 / +13,5 | 6,0 | (−196,4, 361,1) / (−177,6, 257,2) |
| cota maximă | +13,5 | **0.5952** | 1245 m | **+14,06** | 6,0 | (−188,2, 202,1) |
| viraj +68° (coborârea în G) | 0.600 | **0.6010** | 1257 m | +13,4 | 6,0 | (−183,6, 191,1) |
| **furca Dunele** | 0.6457 | **0.6450** | 1348 m | +6,1 | 8,0 | (−99,9, 161,1) |
| **gura REALĂ G′** (gol margine–margine > 0) | | **25,0 m pe bandă** (lângă bucla 0.6555) | | +5,1 | 3,5 | (−76,0, 151,2) |
| revenirea Dunele | 0.7543 | **0.7541** | 1575 m | +0,4 | 8,0 | (49,5, 93,1) |
| virajele G | | 0.711 (−50°), 0.7455 (−61°), 0.8144 (+44°) | | +1,0 / +0,5 / −0,1 | 8,0 | (36,6, 168,6) / (59,8, 106,4) / (−70,2, 54,6) |
| caii G (`CalG1/CalG2`) | ~53 s | 0.7799 / 0.7818 | | +0,2 | | (−2,2 / −5,6, 76) |
| vârtejul (`VartejG`) | | 0.686 (cel mai apropiat) | | +1,0 | | (−8,7, 142), la 30,8 m de axă |
| **albia G2** (centrul) | 0.834–0.846 | **0.8383** (gol 0.834–0.846) | 1752 m | −0,5 | 7,9 | (−95,8, 13,0) |
| viraj +73° după albie | | 0.8450 | | −0,1 | 7,1 | (−95,7, −1,2) |
| **grila H / sfârșitul pământului** | 0.846 | **0.8593** | 1796 m | +0,5 | 7,0 | (−78,7, −25,6) |
| viraj +43° (intrarea în H) | | 0.8660 | | +0,8 | 7,0 | (−68, −34) |
| **dreapta H** | 0.846–1.000 | **0.870–0.9995** (z = −40, x −61 → 208) | | +1,0 → +11,9 | 7,0 | rampă de 3,8 %, plată lateral |
| rază minimă a pistei | 23,5 m | **21,4 m** la 0.87 | | | | |
| pantă maximă | 8,4 % | **9,8 %** la 0.07 (9,0 % pe 20 m) | | | | |

**Limitele de proprietate** (zona fiecărui POI, în fracții pe index și în lume;
metadata `fractii` din `Track19.tscn` le poartă acum):

| zonă | fracții | în lume |
|---|---|---|
| **A** | 0.985–1.000 + 0.000–0.056 | x ≥ 190, z ≤ +10 (platoul) |
| **B** | 0.056–0.127 | x 280–330, z −2 … 146 + valea până la x ≈ 400 |
| **C** | 0.127–0.185 | z 146 … 266 pe x = 300 |
| **D** | 0.185–0.260 | z 266 … 419 + Mittens/Merrick (WM (262,300), EM (338,318), MB (372,262)); **colțul r 44 de la 0.2593 e al lui D** |
| **E** | 0.260–0.434 | idx ≥ 0.26 (z ≥ 415), x 288 → −38; **fără cercul r 30 m din jurul arcului** (−68,3, 444,6) |
| **E′** | 0.4335 ± 30 m | cercul r 30 m (arcul îl remodelează alt agent în Blender; E nu atinge GLB-ul) |
| **F** | 0.442–0.600 | x −260 … −110, z 190 … 446 |
| **G** (+G′) | 0.600–0.826 | x −170 … 80, z 40 … 190 + banda Dunele |
| **G2** | 0.826–0.866 | x −130 … −50, z −40 … 60 (include grila H la 0.8593) |
| **H** | 0.866–0.985 | z = −40, x −68 … 190 |
| **Gospodăria** | vizibilă din 0.965–0.05 și 0.035–0.105 | x 425–470, z 70–170 |

**Față de brief §2** (dedesubt: fracții din brief vs. măsurat):

| POI | brief | măsurat | |
|---|---|---|---|
| A | 0.000–0.040 | grila 0.000, virajul 0.040, B începe la 0.056 | A se termină cu 0.016 mai târziu |
| B | 0.040–0.131 | 0.056–0.127 (coborârea) | **începe cu 0.016 mai târziu**; „coama la 0.063” e **virajul 0.040–0.050**, nu o creastă (§Premise 1) |
| C | 0.131–0.206 | 0.127–0.185 (grila 0.1368) | se termină cu 0.02 mai devreme |
| D | 0.206–0.297 | 0.185–0.260 (poarta 0.2048) | începe cu 0.02 mai devreme, se termină cu 0.037 mai devreme (viraj 0.2593) |
| E | 0.297–0.434 | 0.260–0.434 (defileu doar 0.329–0.419) | pereți doar pe 188 din 365 m (§Premise 3) |
| E′ | 0.434 | 0.4335 | ✓ |
| F | 0.434–0.600 | 0.442–0.600 (cornișa 0.470–0.600, căderea 0.485–0.585) | începutul lui F e deschis (fără rapă) pe 0.434–0.470 |
| G | 0.600–0.834 | 0.600–0.826 | |
| G′ | 0.64–0.80 | furca 0.645, gura la 25 m pe bandă, revenirea 0.754 | ✓ (Dunele 0.6457→0.7543 din §9.0b) |
| G2 | 0.834–0.846 | gol 0.834–0.846; zona 0.826–0.866 cu grila H | ✓ |
| H | 0.846–1.000 | **0.870–0.9995** (între 0.846 și 0.870: albia, virajul +73°, grila H, virajul +43°) | **începe cu 0.024 mai târziu** |

## Premise din brief găsite false (la 3cbe5cbb)

Nu sunt defecte de POI; sunt fapte despre pistă pe care constructorii trebuie
să le știe înainte să citească brief-ul §2 / §2.0. Toate sunt **măsurate** pe
scenă (`sv_mv_fractii.gd`), cu camera reală (10 m sus, 12,5 m în spate,
jumătate de cadru ±50°, margine de sus +5,25°) și ocluzie pe terenul real
(`_terrain_mesh_y`).

1. **Coama nu e o creastă și nu ascunde nimic.** Profilul: platou plat la +12,0 până
   la 0.0555, apoi pantă −6,5 … −8,7 %. **Raza verticală minimă pe 0.04–0.14 =
   151 m**; airtime la 34 m/s cere < 41 m (v²/g, g = 28), deci **nu există
   săritură** (brief §2.0 și §3: „altfel e dezvăluire și e destul” — e
   dezvăluire). Mai mult: **terenul nu ocluzează nicăieri** (0 din 13 eșantioane
   A/B). Ce ține valea ascunsă pe A nu e buza, ci **azimutul**: pe 0.000–0.039 spre
   Mittens și valea sunt +62…+91° (în afara ±50°). Dezvăluirea o face **virajul
   de la 0.040 (+81°, r ≈ 28)**: la 0.040 intră EM (+46°) și Merrick (+38°), la
   0.050 și WM (+13°). Consecință: „câmpia nu se vede din A” e adevărat, dar decorul
   din dreapta lui A (sud) e oricum în afara cadrului; contează ce e **în față și
   în stânga** pe A.
2. **Mittens nu sunt la „~18 m de marginea drumului”.** Centrele sunt la **38,0 m
   de axă** (cum zice brief-ul), dar GLB-urile sunt late: peretele lui WM
   (`Mitten_Rock`, AABB x 249–283) e la **16,9 m de axă = 10,4 m de MARGINE** (degetul
   de 26 m e spre drum, WM e rotit 180°), peretele lui EM la 18,3 / **11,8 m**; fustele
   (`*_Scree`) la 14,1 / 15,6 m de axă = **7,6 / 9,1 m de margine**; conul de teren
   (`TerrainPeak` r 28) la ~10 m de axă. Merrick e la 72 m de axă (**49,6 m de
   margine**, fusta la 40 m). Contractul „ambii Mittens la ≤ 50° pe ≥ 70 % din
   punctele coamă–poartă” **trece cu 90 %** (130 din 145), dar **vârfurile ies din cadru
   de sus devreme**: WM la ~0.115 (elevație +5,9° la 0.12), EM la ~0.125, Merrick la
   ~0.12; lateral, WM iese din ±50° la ~0.185 (+58° la 0.19), EM la ~0.195 (−62° la 0.20).
   **Fereastra „pereții în parbriz” e 0.14–0.19.**
3. **Defileul E are pereți doar pe 188 m, nu pe 285.** `custom_gorge_ranges`
   0.33–0.42 (**0.3292–0.4191**); pe 0.260–0.329 (143 m) și 0.419–0.434 nu există
   niciun perete, iar semilățimea e 5,5 de la 0.297. Terenul e **plat lateral pe
   ±60 m** (−0,3 m) pe tot E: zidurile și mesele sunt decor (`TrackCliffs` și
   `mesa_wall_module`), nu relief. Diorama are canion cap-coadă: cere
   `mesa_wall_module` pe 0.260–0.329.
4. **Cornișa F: căderea e pe DREAPTA, dar doar pe 0.485–0.585, iar pe stânga e loc.**
   Rapa (`custom_ravines` 0.47–0.60, adânc 13) dă **−13,3 m la +14 … +40 m dreapta**
   (la 0.52, 0.56), lată de ~45 m; **malul îndepărtat revine la nivelul drumului la
   +55 … +60 m**, deci „valea dedesubt” e un șanț, nu valea deschisă (valea G e la
   ≥ 90 m est de F). **Pe stânga terenul e plat la ±0,5 m pe ≥ 70 m, pe 344 m
   continuu** (0.435–0.60, ≥ 25 m lățime plată): **există loc pentru belvedere**, la
   nivelul drumului, nu pe promontoriu. Belvederul la (−215…−230, +15, 300…380) e în
   cadru pe **0.355–0.505** (din E până în prima treime din F), nu din mijlocul lui F.
5. **`custom_landmarks` din A sunt piesele vechi ale Dunelor.** Turnul de apă (id 0,
   `buildings/water_tower.glb`, rust_metal) la 0.012 și moara (id 2, `windmill.glb`) la
   0.028, ambele **stânga** (nord) — vezi `probe_decor`: `water_tower` 1 prop,
   `windmill` 4. Kitul are `water_tower` și `windmill_pump`: A le înlocuiește și
   scoate cele două intrări din `custom_landmarks` (singura atingere de proprietăți
   rădăcină permisă lui A).
6. **Turnul de apă și moara „pe ax în H” sunt pe axă, dar la 265 m, nu 150–250 m.**
   H e dreapta z = −40 (x −61 → 208), iar axa continuă drept până la x ≈ 292 (virajul A):
   turnul/moara la (325…335, −40) sunt **pe ax** și în cadru pe **0.905–1.000 și
   0.000–0.040**, la 265 m de la x = 60 (0.93), 130 m de la grilă; sub `fog_end` 360,
   deci „luminate din față”, prăfuite de ceață (perspectivă aeriană).
7. **Postul de negoț „în stânga” (nord) nu se vede decât dacă stă înaintea grilei.**
   La (250, −75) e în cadru pe 0.000–0.005 și pe H 0.87–1.0; la grila de start (x = 210)
   azimutul spre el e −41°, după 40 m scade sub −60°. Se pune la **x 280–295, z −70 … −85**
   (30–45 m nord de axă): rămâne în cadru de la grilă până la ~0.02 și de pe H.
8. **Gospodăria: nu există loc la > 80 m de drum pe valea y = 0.** Terenul e plat la
   y = 0 la est de B doar la x 340–380 (≤ 70 m de drum), apoi urcă; **raftul exterior
   x 420–470, z 60–200 e plat la y ≈ +4,3 (±0,3 m)**, la 125–170 m de drum (relief
   24×24 m: 1,1–1,7 m). Candidații măsurați (relief ≤ 1,6 m, la ≥ 55 m de monoliți):
   (430,+6,5,230), (440,+5,6,240), (450,+5,3,250) — dar sunt la 66 m de Merrick și se văd
   doar din B târziu; **pe raftul de la z 70–170 gospodăria e în cadru de pe grila de
   start și din virajul A→B (0.965–0.05) și din coborârea B (0.035–0.09)**, la
   130–250 m (în ceață: pâclă caldă). Se pune acolo (`ZonaGospodarie`).
9. **Gura G′ nu e la furcă**: furca (0.645, y +6,1) e pe virajul de coborâre; banda
   stă pe asfaltul buclei primii **25,0 m** (la 10,5 m de bucla la 21 m, 19 m la 42 m);
   gura reală (golul margine–margine > 0) e la (−76,0, 151,2), y +5,1, lângă bucla
   0.6555 (memoria `banda-inchisa-nu-e-ruta`). **Vizibilă de pe cornișă**: în cadru de
   la 0.485, 0.515–0.565 (212–273 m) și 0.600–0.650 (127–50 m); ocluzată la 0.580
   (azimut +70°). Brief-ul „gura e vizibilă de pe cornișă” e confirmat, în aceste ferestre.
   Câștigul: 63 m din 228 (28 %).
10. **Albia G2: se vede de la 87 m și e un șanț transversal.** Centrul albiei (−95,8, 13)
    intră în cadru de la **0.800** (87 m, azimut +32°, elevație −9°); la 0.780 (125 m)
    e ocluzat; malul la 25 m lateral e vizibil din 0.80–0.82. Profilul lateral la 0.840
    e **−4,8 … −5,0 m pe tot ±25 m** (`reach` 40, `fade` 14, adânc 5, gol 8 m): albia
    **taie drumul perpendicular**, nu e o ravenă longitudinală. Raza verticală 281 m (nu
    rampă în sine: săritura e dată de `ChannelKicker`, linia de bază ProbeLaneClear 2
    raportări + 1 incident ProbeCameraSolid la 0.835–0.836).
11. **Rockfall-urile taie banda în exact locurile lui D și E.** `BolovanD` (278, 6, 306)
    traversează la (322, 0,5, 302) peste **poarta** (0.2038); `BolovanE` (72, 9, 478)
    pornește pe zid și traversează drumul la z ≈ 444 (0.3684) ajungând la (69, 3, 426).
    Culoarele lor (D: x 270–330, z 296–312; E: x 60–82, z 420–482) rămân libere.
12. **Coliziunea Mittens e `mesh` (nu `hull`)** și piesele din `DecorManual` (3 turnuri +
    3 `_col`) au corp automat; deci un `hull` pus „într-un gol de cer” dintre turn și deget
    nu e permis. `Mitten_Scree`/`Cap` sunt sărite din colizor (conul de teren e dedesubt).
13. **Lipsesc din cod** (nu le cere de la decor): `HaboobHazard` (brief §3), tumbleweed-urile
    lui, `--haboob-at=`, firele de telegraf (kitul spune: „firele nu sunt în GLB, le face
    codul”), sunetul grilei. Primul constructor care are stâlpi (A) scrie firele (§A).
14. **Rază minimă 21,4 m (nu 23,5) și pantă 9,8 % (nu 8,4)**: ambele peste pragurile
    ProbeLayout (rază ≥ 9, pantă < 13). Lungimea 2089,9 m ≈ 2,1 km ✓.
15. **Caii dau repuneri în linia de bază** (8 din 8 în cele 4 seed-uri): 0.155–0.158 și
    0.770–0.772. Nu sunt o regresie de decor; nu se „repară” din decor (AI-ul nu vede
    corpuri cinematice; memoria `monument-valley-track-project`).

## Fapte din fundație (PR #456, main 3cbe5cbb)

- **Kitul e plasabil:** `PROP_COLLISION` pe toate cele 37 de GLB (`mesh` Mittens + arc;
  `hull` monoliți mici, grohotiș, structuri, clădiri, vehicule; `trunk` ienupăr, semn,
  stâlp de telegraf; `none` plante mici, animale, oameni, grilă, gard, orizont),
  `CLASSES_BY_THEME["monumentvalley"]` cu 13 chei pe fișier: gresia `mv_sandstone` pe
  `*_Rock`/`*_Scree`, `mv_cap` pe `*_Cap`, `mv_sage` pe `Sagebrush_Foliage`. **Nu
  comite niciun `.glb.import` regenerat local.** Un asset nu aduce niciodată texturi
  proprii (CLAUDE.md).
- **`DecorManual`** are `WM_Turn`, `EM_Turn`, `MB_Turn` (reale, scufundate, cu `_col`) și
  zonele goale `ZonaA … ZonaH`, `ZonaEArc`, `ZonaG2` (+ `ZonaGospodarie`, adăugată de
  această ramură), plus **30 de `ext_resource` `s_<stem>`** puse dinainte, ca nimeni să
  nu mai adauge linii în antetul scenei (cauza conflictelor garantate între constructori
  care scriu toți în `Track19.tscn`). **Fiecare constructor adaugă noduri doar în zona
  lui.** Excepții scrise: A modifică `custom_landmarks`; E poate modifica
  `custom_gorge_ranges`; D poate modifica `Peaks/*` (conuri) — fiecare declară în raport.
- **Scatterul procedural** (`track_decor.gd::_place_monumentvalley_prop`, benzi `hug` /
  `mid` / `far` / `back`, `MV_ROAD_CLEAR_M` = 1,4 m) pune deja salvie, rabbitbrush,
  yucca, ienupăr, grupuri `talus_boulders_*` și `canyon_rocks` pe toată pista (991 de
  prop-uri MultiMesh). **Butte-urile mici, acele, hoodoo-urile, structurile, clădirile,
  vehiculele, animalele statice și oamenii NU sunt în scatter**: vin doar din
  `DecorManual`.
- **Relief:** terenul urmărește drumul (plat lateral ±40–60 m la cota drumului pe aproape
  tot traseul), platoul A la +12 cu bluff-ul `EscarpaA` la sud, conuri `TerrainPeak` r 28
  / h 4 m sub Mittens/Merrick, cornișa F (`custom_ravines`) cu `PlasaCornisa` (respawn),
  albia G2 (`TrackChannel` uscat + `ChannelKicker`). **Treptele de piatră nu sunt teren.**
- **Clasele de lumină** sunt calibrate (sol roșu `ground_tint` (0,80, 0,36, 0,20), drum
  `dirt_road_tint` (0,62, 0,46, 0,38), ceață `D9A57A` 120 → 360 m, `fog_max` 0,62, umbre
  `shadow_distance` 90). Nu se reglează ambientul din POI.
- **Orizontul:** 11 siluete (`horizon_mesas.glb`) pe două inele (190–260 m și 250–340 m),
  fără umbră.
- **Cifrele de plecare** (scena de azi): probe_decor **22 materiale**; probe_manual **0**;
  ProbeBuried **0/0**; ProbeLaneClear **3**; ProbeCameraSolid **1**; probe_solid OK;
  probe_decor_overlap **0/0**; ProbeLayout OK. ProbeRace 4 seed-uri: 2 repuneri/cursă (toate
  pe cai), **0 `[blocaj]`**, tur minim 60,9–63,4 s.
- **Deschis de la fundație:** arcul `sandstone_arch` îl refac în Blender (`arc-v2`, alt agent:
  coloane ca Mittens, golul înghețat 15,45 × 8,95 m); „conuri de grohotiș” la D; Mittens
  tăiate de sus din cadru pe B (confirmat: din ~0.115, §Premise 2).

## Contractele per POI

Fiecare: **ce se vede în decupaj** (obligația vizuală) + **cifre din brief §9.0
alocate acestui POI** + **piesele** (cu coliziunea din `PROP_COLLISION`) +
**densitatea lângă drum** pe benzi (distanță de la MARGINEA asfaltului: 0–10 / 10–30 /
30–60 m) + **ce e interzis** + **gărzile** + **capturile**.

### Reguli comune

- **Banda liberă:** nimic cu coliziune la < 2,5 m de MARGINEA asfaltului (scatterul
  folosește deja 1,4 m + umărul de 2 m); ProbeLaneClear cere banda (semilățime + 0,5 m)
  liberă. Nimic cu prag > 0,3 m pe bandă (memoria `suprafete-cu-goluri-si-praguri`).
- **Gabaritul camerei:** camera stă 10 m sus, 12,5 m în spate; ce trece peste drum (arc,
  grilă) cere golul măsurat ca GOL, pe gabaritul caroseriei și al camerei (memoriile
  `cota-de-contract-se-masoara-ca-gol`, `golul-se-masoara-pe-fereastra-lui`). Înălțimea
  vizibilă la distanța d e 10 + 0,092·d m peste cota drumului (brief §2.0).
- **Orientarea:** în kit „fața” = +Y Blender = −Z Godot; `mesa_wall_module` are fața pe +X
  (spatele −X, mai scund) și se rotește la montare; `trading_post` are prispa pe fața
  „+Y” (−Z Godot), `hogan` ușa spre +Y. Derivă rotația cu produs scalar, nu o ghici
  (memoria `rotatii-in-builder-semnul`). Modulele înlănțuibile au capete identice plane
  la ±6 m (`mesa_wall_module`) / ±2 m (`wire_fence`).
- **Peste ~1000 de piese: MultiMesh feliat**, nu noduri (memoria
  `decor-in-masa-cere-multimesh`). `DecorManual` = piesele hero și primul rând cu
  coliziune; plantele mici și bolovanii fără coliziune în MultiMesh. Instanțele
  MultiMesh nu se citesc în `--headless`: verifică pe captură/`ProbeMasca`.
- **Aranjamentul bate numărul** (memoria `aranjamentul-bate-numarul`): nu grilă, jitter
  ≥ 0,5 din pas, yaw variat, grupări de 2–3 (perechi de butte-uri), densitate care **crește
  spre drum**, interiorul suprafeței, nu doar un tiv. Rabbitbrush galben **doar** în
  petice (accentul viu al pistei): niciodată aliniat.
- **Materiale:** ≤ 38 (azi 22); piesele kitului folosesc clasele din temă; tenta de clasă
  se decide la integrare (memoria `tenta-de-clasa-se-decide-la-integrare`).
- **Interdicții de conținut** (brief §8): fără saguaro, tipi, saloon, diligență, text sau
  logo-uri lizibile, fără călăreți, **fără șa**, hogan = doar locuință (fără decor), „Navajo”
  nu apare în niciun nume de nod/fișier.
- **Nu atinge** GLB-uri, `.glb.import`, `track.gd`/`track_decor.gd`, traseul, `Hazarduri/*`.
- **Plafonul de proprietate:** doar nodurile din zona proprie (+ excepțiile scrise).

### A — Startul pe platou (0.985–1.000 + 0.000–0.056)

Din decupaj (`A`, `ORIZONT`): **postul de negoț** de piatră cu prispă de lemn și coș, un
**pickup vechi** parcat în fața lui, **turnul de apă** de lemn pe schelet în X, **moara de
vânt** cu rotor și **jgheab rotund** de oțel, **3–5 cai** la jgheab, **stâlpi de telegraf cu
fire** în șir, **gard de sârmă**, platoul care se rupe într-un perete roșu spre vale,
orizontul de mese în spate (bara `ORIZONT`).

Cifre din §9.0 alocate: 1 post + 1 pickup + 1 turn + 1 moară cu jgheab; **3 cai statici** (restul
de cai: hazardele); **6 stâlpi de telegraf** pe A (cu fire); gard de sârmă ~80 m (20 de
segmente); 2 corbi pe stâlpi; 2 grupuri de talus; 2 ienuperi (`trunk`), 2 petice de rabbitbrush.

Piese și coliziune: `trading_post` (12 × 9 m, 5 m, `hull`), `pickup_old` (5,2 × 2,0 × 1,9, `hull`),
`water_tower` (11 m, `hull`), `windmill_pump` (turn 9 m + jgheab Ø 3 m, `hull`), `horse_bay` /
`horse_pinto` / `horse_black` (`none`), `raven` (`none`), `telegraph_pole` (8 m, `trunk`),
`wire_fence` (`none`), `talus_boulders_a/b` (`hull`), `juniper` (`trunk`), `rabbitbrush`.
Opțional (P2): 6 × `mesa_wall_module` pe marginea platoului la sud (x 195–275, z +8 … +16,
fața spre sud, ≥ 50 m de axă; terenul cade 11,5 → 0 în 40 m, deci se citește ca perete).

Poziții (măsurate): **postul la x 280–295, z −70 … −85**, prispa spre drum (sud, +Z), gol de
≥ 8 m între post și ghirlandă; **turnul la (325, −40)**, **moara la (335, −45)**, pe axa lui H
(în cadru 0.905–1.0 și 0.000–0.040); pickup parcat lângă post, **nu pe grilă** (memoria
`corp-cinematic-aparut-in-masina`).

Densitate: **0–10 m:** stâlpii de telegraf (șir pe partea de nord, la ~7 m de margine,
spațiere 25–35 m), gardul la ~9 m; fără coliziune la < 2,5 m. **10–30 m:** postul, pickup-ul,
jgheabul, caii, 1 grup de talus, ienupăr. **30–60 m:** turnul și moara (peste 30 m), 1–2 petice
de rabbitbrush, marginea platoului la 55 m sud.

Interzis: grila (0.000) liberă pe 30 m în față și 15 m lateral; `custom_landmarks` rămân doar
cele două intrări înlocuite (turnul/moara de la Dunele ies); nimic > 4 m în axa lui H între
x 190 și 320, în afară de turn și moară (acolo se citește reperul).

**Firele de telegraf:** le scrie A (cod, `ImmediateMesh`/MultiMesh pe catenară, ca sforile de
becuri; `cast_shadow` OFF; nu intră în numărătoarea de materiale mai mult de 1) și le reutilizează B
și H. Fără fire, „telegraful” din diorama (reperul pe orizont) e doar niște bețe.

Gărzi: ProbeLaneClear (baza 3), probe_solid (hull-urile), probe_manual, probe_decor ≤ 38,
probe_decor_overlap, ProbeCameraSolid, ProbeRace `--slice=0.985,1.0` + `--slice=0.0,0.056`
(16 seed-uri; pre-grila nu se judecă). Capturi: 0.000, 0.020, 0.960, 0.985 vs `A` + `ORIZONT`.

Capcana: memoria `corp-cinematic-aparut-in-masina` (un `AnimatableBody3D` atribuit aproape = viteză
uriașă; caii statici nu sunt hazard); prima grilă a pistei trebuie lăsată curată.

### B — Coborârea US-163 (0.056–0.127)

Din decupaj (`B`, `B_iter1`): asfalt negru cu **linie dublă galbenă**, **șir de stâlpi de telegraf cu
fire** pe marginea estică, **gard de sârmă**, salvie în tufe, rabbitbrush galben în petice, **butte-uri
mici și ace de stâncă în perechi și grupări la 15–45 m**, grohotiș la picior (iter1), în capătul
drumului **Mittens și Merrick** (siluete), gospodăria vizibilă în dreapta-sus.

Cifre din §9.0 alocate: **8 stâlpi de telegraf** (partea ESTICĂ = stânga la mers; poziția din
dioramă, ca să rămână dreapta/vest pentru butte-uri și să nu taie Mittens; brief §2 zice „pe
dreapta”: **decizie: stânga**), gard ~150 m, **4 formațiuni** (`butte_small_b` + `butte_small_c`
ca pereche la 30–45 m est, `rock_fin` 1, `hoodoo` 1), 3 grupuri de talus, 1 corb pe stâlp,
3 ienuperi, 3 petice de rabbitbrush.

Piese: `telegraph_pole`, `wire_fence`, `butte_small_b/c` (`hull`), `rock_fin` (`hull`), `hoodoo`
(`hull`), `talus_boulders_a/b`, `juniper`, `raven`. Firele: helperul lui A.

Densitate: **0–10 m:** stâlpii (la 7 m de margine, est), gardul (9 m), tufe; **10–30 m:** 1 butte + 1
rock_fin (partea vest, 20–30 m), talus, ienuperi; **30–60 m:** perechea butte_small_b/c (est,
40–55 m), hoodoo-ul (vest, 45 m). Nimic în **axa de privire spre Mittens** (±8° față de direcția de
mers) mai înalt de 4 m între 0.05 și 0.12: Mittens sunt reperul (în cadru 0.040–0.115).

Gospodăria e a lui B (`ZonaGospodarie`, vezi mai jos): propunerea e ca B să o ia, ca să se vadă și
de pe grilă, nu doar de pe coborâre.

Interzis: aproape de Merrick (centru (372, 262), fusta la 40 m de margine): zona < 60 m de
centrul lui e a lui D; coama nu primește rampă artificială (nu e kicker).

Gărzi: ProbeLaneClear, probe_solid, probe_manual, probe_decor, probe_decor_overlap,
ProbeCameraSolid, ProbeRace `--slice=0.056,0.127`. Capturi: 0.050, 0.075, 0.105 vs `B` + `B_iter1`.

### C — Grila pentru vite și începutul Valley Drive (0.127–0.185)

Din decupaj (`C`): **grila** (bare de oțel peste drum, doi stâlpi galben-negru de capăt), **romb
galben cu cal desenat**, asfaltul care se termină drept și **pământul roșu cu urme**, praf de la
mașină, Mittens în fundal.

Cifre din §9.0 alocate: 1 grilă (la 0.1368), **1–2 semne** (unul la 80 m înainte, la z ≈ 128, unul
la grilă), caii (hazard, nu decor: `CalC1/CalC2`), 3 stâlpi de telegraf (șirul de la B se termină la
grilă), gard care se oprește la grilă (stâlpi de capăt), 2 grupuri de talus, 2 petice de rabbitbrush.

Piese: `cattle_guard` (14 m lat pe X, 2,4 m lung, bare ≤ 0,15 m, **`none`**, se trece peste ea),
`open_range_sign` (stâlp 2,6 m, romb 0,9 m, `trunk`), `telegraph_pole`, `wire_fence`.
Grila: rotația zero pe Y (drumul merge pe Z, deci lățimea de 14 m pe X ✓), semilățimea la 0.1368 e
6,5 → stâlpii de capăt la ±7,3 m = 0,8 m în afara marginii; **fără coliziune la integrare**.

Densitate: **0–10 m:** stâlpii grilei, semnul (1,5 m în afara marginii), gardul; **10–30 m:** talus,
petice; **30–60 m:** nimic nou (butte-urile sunt ale lui D la sud și B la nord).

Interzis: nimic > 4 m în **cercul r 25 m** în jurul grilei, în afară de stâlpii ei; caii traversează la
0.1656 pe axă: nimic cu coliziune pe culoarul lor (z 220–236); fără vizibilitate redusă pe grilă (nu
e oprire, e huruit).

Gărzi: ProbeLaneClear, ProbeRace `--slice=0.127,0.185`, 16 seed-uri: repunerile la 0.155–0.158 sunt
baza (cai); orice repunere în plus lângă grilă e a decorului. ProbeCameraSolid. Capturi: 0.115, 0.134,
0.145, 0.160 vs `C`.

### D — Poarta dintre Mittens (0.185–0.260, + Mittens, Merrick)

Din decupaj (`D`, `WM`, `EM_MB`): **West Mitten** (turn cu coloane late, **deget separat** cu gol de cer,
fustă de grohotiș cu bolovani, calotă palidă) și **East Mitten** de o parte și de alta a drumului de
pământ, **Merrick** lat în spate dreapta cu contraforturi; grohotiș dungat roșu-brun jos, perete
portocaliu-roșu cu fisuri verticale și dungi de lac de deșert, calotă gri-roz; bolovani căzuți la
picior, salvie și rabbitbrush galben între ei.

Ce există deja: WM (262, 300), EM (338, 318), MB (372, 262), cu corp `mesh`/`hull`, conuri
`TerrainPeak` r 28 / h 4 m; `BolovanD`. **Peretele WM e la 10,4 m și EM la 11,8 m de margine
(§Premise 2); fustele la 7,6 / 9,1 m.** Diorama le pune mai aproape: spațiul dintre fustă și
drum (2,5 … 8 m de margine) e al decorului.

Cifre din §9.0 alocate: **30+ bolovani căzuți per monolit** — GLB-urile aduc deja ~130 pe WM și
~116 pe EM, deci D adaugă **6 grupuri de talus pe umerii porții** (3 pe fiecare parte, 2,5–8 m de
margine, cu goluri deliberate de ≥ 6 m între grupuri) + **3 grupuri în jurul bazei lui Merrick**
(spre drum); **2 formațiuni** (`rock_fin` la 45–55 m est de EM, `butte_small_b` în spatele lui
Merrick, > 60 m); 3 petice de rabbitbrush; 2 ienuperi.

Piese: `talus_boulders_a/b` (`hull`), `rock_fin`, `butte_small_b` (`hull`), `rabbitbrush`, `juniper`
(`trunk`). **Nu se adaugă stânci mari lângă poartă**: Mittens sunt reperul.

Densitate: **0–10 m:** talus pe umeri (grupuri de 5–10 bolovani, hull la ≥ 2,5 m de margine),
tufe; **10–30 m:** grohotiș și fustele existente; **30–60 m:** `rock_fin`, perechi de bolovani,
petice.

Interzis (bandă liberă, gabarit, coliziuni): culoarul `BolovanD` (x 270–330, z 296–312) liber;
**gaura de cer dintre turn și deget** nu primește nimic; nu se mută WM/EM/MB și nu se scot
`metadata/scufundat`; între cele două turnuri, pe ±8 m de axă, nimic > 4 m; niciun `hull` peste
conul de teren (probe_decor_overlap, regula de 55 %). **Cererea de relief** (dacă criticul cere de
două ori „fusta mai mare”): `Peaks/*` (`radius_m`/`TerrainPeak`) — D le poate modifica, cu
ProbeBuried și ProbeRace înainte și după (e relief: ieșirea (c)).

Gărzi: **ProbeRace `--slice=0.185,0.26` pe 16 seed-uri înainte și după** (poarta e dop de
vizibilitate, nu de bandă), ProbeLaneClear (baza 3), probe_solid (hull-urile de talus lângă
bandă), probe_decor_overlap, probe_manual, ProbeBuried, ProbeCameraSolid, probe_decor ≤ 38.
Capturi: 0.170, 0.185, 0.2048, 0.225 (`--rock-at` pentru bolovan) vs `D`, `WM`, `EM_MB`.

Capcana: memoriile `munte-flanc-nu-fundal` (un masiv se simte doar la < 40 m), `adancimea-siluetei-
nu-fata-piesei`, `harnasul-de-kit-nu-vede-forma-nici-culoarea`; **pereții în parbriz abia pe
0.14–0.19** (§Premise 2): captura la 0.2048 e în poartă și vede doar fusta; contrastul WM (umbră)
vs EM (lumină, fața de vest spre drum) e din soare, nu din decor.

### E — Trecătoarea dintre mese (0.260–0.434, fără cercul arcului)

Din decupaj (`E`, `E_iter1`): **pereți verticali roșii** de ~3 lungimi de mașină pe ambele părți,
**în umbră adâncă cu muchii aprinse**, grohotiș larg la picior, tufe galbene la margine, drumul de
pământ pe fund, la intrare **mesele mari** (blocuri late, în trepte).

Brief: singurul loc închis; **contralumină** (soarele de 18° în față); asfaltul **nu** devine o
pată (memoria `umbra-fara-culoare-e-negru-mort`).

Ce există: `TrackCliffs` pe **0.3292–0.4191** (188 m, la 0,8 m de drum, 12 m); `BolovanE`
(culoarul x 60–82, z 420–482 liber); arcul la 0.4335 (E′, nu E).

Cifre din §9.0 alocate: **`mesa_wall_module` pe 0.260–0.329** (143 m, drumul e deschis aici): **≥ 20
de module** (≈ 10 pe parte, lanț continuu ≥ 85 %), fața spre drum la **≥ 9 m de axă** (3,5 m de
margine, semi 5,5) cu o tranziție de 20 m de la 30 m spre 9 m la capete; **~10 module în spatele
falezelor** `TrackCliffs` pe 0.329–0.419 (a doua linie, 14 m înălțime, ca să nu se vadă ceruri
printre ele); **1 `butte_small_a`** în colțul de intrare (30–60 m sud); grohotiș: **12 grupuri de
talus** la piciorul pereților (cele dinspre drum cu `hull`, la ≥ 2,5 m); 4 petice de rabbitbrush.

Piese: `mesa_wall_module` (14 m înalt, 12 m lung, `hull`; fața pe +X: se rotește), `butte_small_a`,
`talus_boulders_a/b`, `rabbitbrush`. **E nu atinge `sandstone_arch.glb`** (îl refac în Blender,
alt agent); în cercul r 30 m din jurul (−68,3, 444,6) nu pune nimic cu coliziune.

Densitate: **0–10 m:** fața pereților (la 3,5 m de margine în partea deschisă), grohotiș; **10–30 m:**
a doua linie de module, talus, tufe; **30–60 m:** butte-ul de colț, mesele de la intrare.

Interzis (bandă liberă, gabarit, coliziuni): **semilățime 5,5 → bandă liberă 6,0 m de la axă**; nimic
cu prag > 0,3 m; fără stânci pe traseul de rostogolire; fără piese cu golul măsurat < 12 m între
fețe; **nu se atinge traseul**. Dacă `custom_gorge_ranges` trebuie extins (0.329 → 0.30) e o
excepție declarată în raport, cu ProbeRace înainte/după.

Gărzi: **ProbeRace `--slice=0.26,0.44` pe 16 seed-uri înainte și după, cu `[blocaj]` citit** (culoar
de 11 m cu pereți hull: aici apar blocajele), ProbeLaneClear, probe_solid, ProbeCameraSolid (pereți
la 3,5 m de margine: camera 10 m sus, 12,5 m în spate; cere tavan), ProbeBuried, probe_decor ≤ 38,
probe_decor_overlap. Capturi: 0.265, 0.300, 0.350, 0.400 (`--rock-at` pentru BolovanE) vs `E`,
`E_iter1`; verifică pe pixel că asfaltul nu e o pată (HSV, familii de întunecate).

Capcana: lecția podului Fiordland (măsoară săgeata înainte de gol), `perete-paralel-nu-se-vede`
(pereții laterali nu se văd pe cadru: contează cei din față, la colțurile 0.265 și 0.425).

### E′ — Arcul (0.4335 ± 30 m) — AMÂNAT până după `arc-v2`

Din decupaj (`EArc`): **punte masivă de gresie** cu gol, **blocuri mari** (4 rânduri), calotă palidă în
plăci, picioare late cu grohotiș, masina verde care trece pe sub el.

Arcul e pus de `Track._build_arch` (tema: `sandstone_arch.glb`), cu golul înghețat **15,45 × 8,95 m**.
**Nu se pune nimic înainte de merge-ul `monument/arc-v2`** (alt agent, GLB nou, fustă posibil
diferită). După: 2 grupuri de talus și 4 petice de rabbitbrush la picioare (în afara golului și la ≥ 2,5 m
de margine), 2 ienuperi pe calotă-teren; fără piese în gol sau pe puntea de peste. Gărzi: ProbeCameraSolid
(camera trece pe sub arc), `--slice=0.42,0.45`, `probe_solid` (golul liber), `ProbeLaneClear`.

### F — Cornișa de la Artist's Point (0.442–0.600)

Din decupaj (`F`, `F_belvedere`): **drumul pe buza unei mese**, perete vertical cu cădere pe dreapta,
**fără parapet**; pe stânga **belvederul**: o **ramadă** de stâlpi și crengi cu masă, **3 camioane de tur**
deschise (albastre), **6–8 turiști** cu aparate foto, ienuperi și rabbitbrush pe mesa plată; pereții în
trepte cu calote palide, grohotiș la picior.

Cifre din §9.0 alocate: **1 ramadă + 3 `tour_truck` + 2 × `tourist_group` (= 8 oameni)** la (−215 … −230,
+15, 300 … 380) — 25–45 m STÂNGA, la nivelul drumului (§Premise 4), în cadru pe 0.355–0.505; **2
formațiuni** (`hoodoo` 40–60 m stânga, `butte_small_c` 50 m stânga); **4 ienuperi** pe mesă (`trunk`, ≥ 6 m
de margine); 5 petice de rabbitbrush; 6 grupuri de talus pe fundul șanțului din dreapta (nu se ajunge acolo,
`none` suficient); **opțional (P2):** 8 `mesa_wall_module` pe buza îndepărtată a șanțului (+58 m dreapta,
fața spre drum) pentru „a doua mesă”.

Piese: `shade_ramada` (5 × 4 × 3, `hull`), `tour_truck` (5,5 × 2,2 × 2,6, `hull`), `tourist_group`
(4 oameni, `none`), `hoodoo`, `butte_small_c`, `juniper`, `rabbitbrush`, `talus_boulders_a/b`,
`mesa_wall_module`.

Densitate: **0–10 m:** nimic cu coliziune pe stânga la < 2,5 m; tufe; **10–30 m:** belvederul (marginea
lui la ≥ 25 m de axă: nu-l poți lovi din bandă), ienuperi la 12+ m; **30–60 m:** hoodoo, butte, ramada;
dreapta: doar piese `none` în șanț.

Interzis: **nimic pe cornișa dreaptă la < 14 m lateral** (căderea; `PlasaCornisa` repune); **sectorul de
haboob**: pe azimut −50 … −10° față-stânga, la 60–330 m, nu se pun mase > 6 m (haboob-ul se vede
în stânga-față ~30° la ~300 m, brief §2.0); belvederul sub 5 m ca înălțime generală; nu se schimbă
rapa/relieful (**(c) dacă se cere „promontoriu”**).

Gărzi: ProbeRace `--slice=0.442,0.60` pe 16 seed-uri (căderi și `[blocaj]`), ProbeLaneClear,
ProbeBuried, probe_solid, probe_decor ≤ 38, probe_manual (belvederul pe teren real), ProbeCameraSolid.
Capturi: 0.446, 0.480, 0.520, 0.560, 0.590 vs `F`, `F_belvedere`; belvederul se verifică și din 0.400.

Capcana: memoria `masoara-inainte-nu-langa` (belvederul stă înaintea camerei în 0.355–0.505, nu lateral
în 0.55); `perete-paralel-nu-se-vede`; `umarul-ingust-ascunde-caderea` (verifică UNGHIUL căderii, nu
adâncimea, din camera de joc).

### G — Câmpia deschisă și scurtătura G′ (0.600–0.826; Dunele 0.645–0.754)

Din decupaj (`G`, `G_iter1`): S-urile drumului de pământ cu urme, **vegetație în tufe** (salvie gri-verde,
ienupăr întunecat, rabbitbrush galben ca accent viu), **butte-uri mici și ace de stâncă în perechi/
grupări la 15–60 m** (iter1: 3 formațiuni pe ~300 m de drum), bolovani rari, urme vechi de cauciuc, caii
și vârtejul în fundal (hazarduri), pământ roșu continuu.

Cifre din §9.0 alocate: **5 formațiuni** (`butte_small_a`, `butte_small_c` în interiorul S-urilor;
`rock_fin` 1; **`hoodoo` 2 de o parte și de alta a gurii G′**, ca reper citibil de pe cornișă la 212 m, la
≥ 8 m de marginea benzii); **6 grupuri de talus** (`hull`, ≥ 2,5 m de margine); **4 ienuperi**; 8 petice
de rabbitbrush; 2 corbi (la sol, fără stâlp).

Piese: `butte_small_a/c` (`hull`), `rock_fin`, `hoodoo`, `talus_boulders_a/b`, `juniper`, `rabbitbrush`,
`yucca`, `raven`. Nimic cu `hull` mai aproape de marginea benzii Dunele decât 2,5 m.

Densitate: **0–10 m:** scatterul existent + petice; **10–30 m:** 1–2 grupuri de talus pe 100 m, ienupăr,
perechi de bolovani; **30–60 m:** formațiunile (1 la ~150 m, în interiorul S-urilor, la 30–55 m), acolo unde
vântul/haboob-ul trece (deschis, fără ziduri).

Interzis: **primii 25 m de bandă G′ sunt asfaltul buclei**: nimic cu coliziune acolo și nici pe cei 7 m
(2 × 3,5) ai benzii după gură (memoria `banda-inchisa-nu-e-ruta`); **cercul r 20 m în jurul
`VartejG` (−8,7, 142)** și culoarul cailor G (z 70–82, x −12 … 4) fără coliziune; pe bandă nicio prag > 0,3 m
(`suprafete-cu-goluri-si-praguri`); haboob-ul traversează G: deschis, fără ziduri.

Gărzi: **ProbeRace `--slice=0.60,0.826` pe 16 seed-uri** (baza: 2 repuneri/8 seed-uri la 0.770–0.772,
cai), ProbeLaneClear (și pe ruta Dunele), probe_solid, ProbeBuried (Dunele: +0,28 m la 0.682),
ProbeLayout (Dunele neschimbate), probe_manual, probe_decor ≤ 38. Capturi: 0.610, 0.645, 0.690, 0.735,
0.790 și `--route=1` (0.05, 0.16, 0.55) vs `G`, `G_iter1`.

Capcana: memoria `amprenta-hull-nu-raza-nominala` (hull-ul e mai mare decât raza nominală);
`garzile-se-uitau-doar-la-carosabil`; dacă criticul cere de două ori „dune de nisip” (diorama nu le are),
e hazard/teren: **(c)**.

### G2 — Albia secată și grila H (0.826–0.866)

Din decupaj (`G2`): **ravena** cu maluri tăiate de nisip palid, **calul/caii** la marginea ei, **a doua
grilă + romb galben** în spate, vegetație rară pe maluri. (Praful din stânga e haboob-ul: nu se compară.)

Cifre din §9.0 alocate: **grila H** la 0.8593 (−78,7, −25,6) și **1 `open_range_sign`**; **2 stâlpi de
telegraf** lângă ea (restul sunt ai lui H); **1 `hoodoo`** pe malul albiei (≥ 20 m lateral); **4 grupuri de
talus** pe maluri (≥ 12 m de axă; `none`/fără coliziune în apropierea săriturii); 1 corb; 3 petice de
rabbitbrush.

Piese: `cattle_guard` (`none`), `open_range_sign` (`trunk`), `telegraph_pole`, `hoodoo`,
`talus_boulders_a/b`, `raven`. **Grila e perpendiculară pe direcția drumului** la 0.8593 (direcția h ≈ 054° față de nord;
axa X a grilei rotită cu θ pe Y e (cos θ, 0, −sin θ), perpendiculară pe (sin h, 0, −cos h) când θ = −h = −54°; verifică cu dot, memoria `rotatii-in-builder-semnul`); semilățimea 7,0 = grila de 14 m
exact: stâlpii de capăt la ±7,3.

Densitate: **0–10 m:** grila + stâlpii ei, semnul; **10–30 m:** talus pe maluri (în afara culoarului de
zbor: nimic cu coliziune pe ±15 m lateral pe 30 m dinaintea kicker-ului la 0.834 și pe 40 m după, spre
aterizare); **30–60 m:** hoodoo-ul, petice.

Interzis: culoarul de zbor/aterizare al `ChannelKicker` (0.834–0.846 + 30 m în față, 40 m în spate); nimic în
albie (ar schimba repunerea); **ProbeLaneClear rămâne 3**, **ProbeCameraSolid rămâne 1** (0.836);
orice piesă nouă în apropierea kicker-ului cere `--slice=0.82,0.87` înainte și după.

Gărzi: **ProbeRace `--slice=0.826,0.866` pe 16 seed-uri** (săritura C2: treceri/căderi), ProbeLaneClear,
ProbeCameraSolid, ProbeBuried, probe_decor ≤ 38. Capturi: 0.805, 0.825, 0.835 vs `G2`.

Capcana: unghiul căderii (memoria `umarul-ingust-ascunde-caderea`): ochiul la 10 m, elevația spre fundul
albiei e −15° la 0.82 și −44° la 0.838 — albia se vede „de sus”, nu din față; „ravenă îngustă” din dioramă
e un șanț transversal în joc (§Premise 10).

### H — US-163 înapoi (0.866–0.985)

Din decupaj (`H`): asfalt negru cu **linie dublă galbenă**, **șir de stâlpi de telegraf cu fire** pe partea
de nord, gard de sârmă, un cal și un corral, **dust devil la distanță**, în capăt turnul de apă și moara
(ale lui A), orizontul de mese. **Peretele roșu continuu sub drum NU se ia** (e relief; §Defecte).

Cifre din §9.0 alocate: **12 stâlpi de telegraf** (nord, spațiere ~22 m, 270 m) cu firele lui A; gard
~200 m; **1 `butte_small_b`** (nord, 40–60 m); 2 grupuri de talus; 1 corb; 3 petice de rabbitbrush.
**Cererea de relief** (decizia coordonatorului înainte de val 3): rapă pe dreapta (`custom_ravines`, latura
+1) pe 0.90–0.985 dacă se vrea peretele; fără ea, H se judecă fără perete (diferență declarată).

Piese: `telegraph_pole`, `wire_fence`, `butte_small_b`, `talus_boulders_a/b`, `raven`, `rabbitbrush`.

Densitate: **0–10 m:** stâlpii (la 7 m de margine, nord), gardul (9 m); **10–30 m:** talus, petice;
**30–60 m:** butte-ul. Axa de privire (z = −40, x 190 … 330) liberă: turnul și moara trebuie să se vadă din
0.905.

Interzis: **nimic cu coliziune pe dreapta de turbo** (ProbeLaneClear); `custom_landmarks`; turnul/moara
(ale lui A); nimic mai înalt decât stâlpii de 8 m în afara lor (cadrul vede 10 + 0,092·d); relieful.

Gărzi: ProbeRace `--slice=0.866,0.985`, ProbeLaneClear, probe_solid, probe_manual (rampa de 3,8 %, piesele
pe teren real), probe_decor ≤ 38, probe_decor_overlap. Capturi: 0.870, 0.910, 0.950, 0.980 vs `H`.

### Gospodăria din vale (`ZonaGospodarie`, x 425–470, z 70–170, y ≈ +4,3)

Din decupaj (`GOSPODARIE`): **casă modulară de scânduri** cu prispă mică (alb-gri), **hogan** cu 8 laturi
și acoperiș de pământ în dom turtit, **țarc de lemn** cu 3 bare și cai, **~10 oi**, un **pickup** vechi,
**gard**, un rezervor cilindric (kitul nu are: omis sau cerere de asset), ienuperi.

Cifre din §9.0: 1 casă + 1 hogan + 1 țarc + 1 pickup + 10 oi + **3 cai statici** + 3 ienuperi + gard ~40 m.

Piese: `homestead_house` (9 × 7 × 5,5, `hull`), `hogan` (Ø 7 m, 3,5 m, `hull`, ușa spre **est** = rotația −90° pe Y,
derivată; locuință, nu loc de ceremonie: nimic decorat), `corral` (10 × 8 × 1,5, `hull`), `pickup_old`
(`hull`), `sheep` (`none`), `horse_*` (`none`), `wire_fence`, `juniper` (`trunk`).

Poziții: pe raftul plat (relief ≤ 1,7 m pe 24 × 24 m), ≥ 120 m de drum, vizibil din 0.965–0.05 și 0.035–0.09;
**zero coliziune relevantă pentru bandă** (la 125–170 m); verifică vizibilitatea cu `--eye/--look`, nu cu `--gamecam`.

Gărzi: probe_manual (piese pe teren real, nu plutitoare), probe_decor ≤ 38, probe_decor_overlap. Capturi:
0.965, 0.990, 0.015, 0.040, 0.060 vs `GOSPODARIE`. Respectul (§8): fără hogan ceremonial, fără
„Navajo” în nume, fără oameni în costum, caii fără șa.

## Bucla oarbă

1. Constructorul (Sonnet, memoria `coordonator-fable-constructori-sonnet`) lucrează în
   `D:/GameDev/wt-mv-poi-<x>` pe `monument/poi-<x>`, plecat din vârful ramurii după
   merge-ul fundației (`3cbe5cbb` + ramura asta); `--import` la creare; comite după fiecare pas
   care trece o gardă; **prima rundă începe cu `git status` / `git diff`**; **niciodată
   `git stash`** (memoria `git-stash-partajat-intre-sesiuni`); lucrează dintr-un git worktree
   separat (memoria `shared-worktree-collision`).
2. Face captura din mașină la fracțiile din tabel, cu `--gamecam` și flagurile de hazard, prin
   lacătul de GPU. 5 eșantioane pe verdict (memoria `o-captura-nu-e-un-verdict`).
3. Criticul, **context proaspăt**, primește planșa din
   `python tools/bar/blind_pair.py "<captura>" "docs/track_briefs/img/bar_monument/<POI>.png" "<out>.png" --seed <N>`.
   **O singură planșă per rundă.** Decupajul bară se mărește la rezoluție plină înainte de verdict
   (memoria `numaratoarea-trece-amplasarea-nu`: numărul nu e dovada, contează poziția și forma).
4. Criticul **deschide** planșa, alege A sau B, **apoi** citește cheia și raportează cinstit dacă a nimerit.
5. Numește **o singură** diferență care contează, reparabilă în decorul POI-ului.
6. Ieșirea din buclă: (a)/(b)/(c). La (a) sau (b): gărzile pe scena integrată, apoi merge. La (c): oprire
   și decizie.

Seed-ul planșei și numele fișierului se schimbă la fiecare rundă (memoria `critic-orb-coliziune-de-plansa`).
Verdictul de fidelitate nu se deleagă constructorului (memoria `numaratoarea-trece-amplasarea-nu`).

## Valurile (câte 3 POI-uri, niciodată 8)

Memoria `valuri-de-trei-nu-opt-agenti`. Regula de compunere: **două POI-uri care se calcă pe decor nu merg
în același val** — un worktree nu vede ce pune celălalt. Distanța minimă dintre drumurile POI-urilor
(m, măsurată pe curba coaptă):

|  | A | B | C | D | E | F | G | G2 | H |
|---|---|---|---|---|---|---|---|---|---|
| **A** | | 6 | 156 | 276 | 428 | 436 | 189 | 250 | 6 |
| **B** | 6 | | 6 | 126 | 279 | 480 | 237 | 370 | 130 |
| **C** | 156 | 6 | | 6 | 159 | 416 | 238 | 406 | 226 |
| **D** | 276 | 126 | 6 | | 6 | 365 | 273 | 457 | 333 |
| **E** | 428 | 279 | 159 | 6 | | 6 | 273 | 417 | 475 |
| **F** | 436 | 480 | 416 | 365 | 6 | | 6 | 191 | 262 |
| **G** | 189 | 237 | 238 | 273 | 273 | 6 | | 6 | 75 |
| **G2** | 250 | 370 | 406 | 457 | 417 | 191 | 6 | | 6 |
| **H** | 6 | 130 | 226 | 333 | 475 | 262 | 75 | 6 | |

Cifra 6 = vecini pe traseu (granița se scrie ca cifră, mai sus); celelalte sunt separații reale.

**Propunerea coordonatorului: val 1 = D, A, E. O confirm**, cu patru condiții scrise:

1. **D–E împart colțul** (0.2593, (289, 419)): granița e **idx 0.260 / z ≥ 415 = E**, colțul r 44 = D.
   Altfel nu se calcă nimic: skirt-ul lui EM se termină la z 335, la 84 m de colț.
2. **A–D 276 m, A–E 428 m**: nu au teren comun. A și H sunt vecini: granița e x = 190 (A ≥ 190).
3. **E nu atinge GLB-ul arcului** și nu pune nimic în cercul r 30 m din jurul (−68,3, 444,6); E′ vine după
   `arc-v2`, ca mini-pas separat (nu în val 1).
4. **Conflicte de fișier: toți scriu în `Track19.tscn`.** Antetul (`ext_resource`) e deja rezolvat (30 de
   `s_<stem>` puse dinainte, de pe ramura asta); fiecare adaugă noduri doar sub `Zona…` proprie, iar
   proprietățile rădăcină au proprietari unici: **A: `custom_landmarks`; E: `custom_gorge_ranges`; D:
   `Peaks/*`**. Orice altă atingere de scenă se raportează.

De ce D, A, E în același val: D e identitatea (poarta) și riscul de bandă; E are riscul cel mai mare de
`[blocaj]` pe culoarul de 11 m; A e ieftin și scrie **firele de telegraf** de care au nevoie B și H
(secvențiere: B și H vin după merge-ul lui A).

| val | POI-uri | de ce |
|---|---|---|
| **1** | **D, A, E** | identitatea (poarta Mittens), startul + helperul de fire, trecătoarea (riscul de blocaj). A–D 276 m, A–E 428 m; D–E doar pe colț, cu graniță cifrată |
| **2** | **B (+ gospodăria), F, G2** | B după A (firele); F după E (aceeași latură de vest/sud, dar la 365–436 m); G2 la 191 m de F și 370 m de B. B–C și C–D adiacente: C nu intră aici |
| **3** | **C, G (+G′), H** | C după B și D (grila continuă șirul de stâlpi); G și H la 75 m (G S2 vs intrarea H): 75 m e destul fiindcă G nu pune piese pe la x < −40, dar H (z = −40) trebuie să vadă ce a lăsat G2 (val 2) la grila H; **H cere decizia de relief** (peretele) înainte de pornire |
| **4** | reluarea celui mai slab + **E′** (după `arc-v2`) + trecerea de integrare (3 eșantioane de haboob când există) | |

Perechi adiacente care NU ajung în același val: A–B (A val 1, B val 2), B–C (2/3), C–D (3/1: dar D se
integrează înainte să pornească C), D–E (același val, graniță cifrată), E–F (1/2), F–G (2/3), G–G2
(3/2), G2–H (2/3), H–A (3/1). Fiecare val se integrează într-un worktree dedicat (memoria
`orchestrare-agenti-worktree-frate`) înainte să pornească următorul; gărzile **doar pe scena integrată**;
după fiecare merge: `--import` și verifică ramura înainte de commit (memoria `merge-ul-lasa-tree-ul-pe-main`)
și că reparațiile de pe ramuri chiar au ajuns (memoria `reparat-pe-ramura-nu-inseamna-livrat`).

**Riscuri de conflict între constructori (rezumat):**

- `Track19.tscn` unic: mitigat prin `ext_resource`-uri puse dinainte + proprietari unici pentru proprietățile
  rădăcină (mai sus). Dacă un constructor are nevoie de un `ext_resource` care nu e în listă (de ex. un GLB
  de altă categorie), îl cere coordonatorului, nu îl adaugă în antet.
- **Firele de telegraf** (A) sunt cod partajat: dacă B pornește înaintea merge-ului lui A, scrie propriul helper și
  se dublează.
- **Merrick:** zona de 60 m din jurul centrului lui e a lui D; B vede Merrick în cadru (−15…−33°) dar nu pune
  piese acolo.
- **Gospodăria:** o ia B (vizibilă de pe grilă și din 0.035–0.09). Dacă B nu are buget, rămâne a lui A (cade în
  0.965–0.05): **un singur proprietar**, scris în promptul ambilor.
- **Materialele:** probe_decor se măsoară pe scena integrată; trei constructori pe worktree-uri separate nu văd
  suma. Toți lucrează cu piese ale kitului (atlas + clase), deci puțin probabil să crească materialele; verifică
  la integrare (≤ 38, azi 22).
- **Hazardele care taie banda** (BolovanD, BolovanE, caii, vârtejul, kicker-ul) au culoare libere declarate mai sus;
  orice piesă cu `hull` pe ele schimbă distribuția ProbeRace.
