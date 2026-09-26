# Fiordland — contractul per POI pentru gauntlet

> Fișa de lucru a celor 8 perechi constructor/critic. Bara e
> `docs/track_briefs/img/fiordland_diorama_v03.jpg` (diorama acceptată, brief
> §9.0), decupată per POI în `docs/track_briefs/img/bar_fiordland/bara_poi_<X>.png`
> (`tools/bar/crop_fiordland_bar.py`). Planul real al traseului e
> `docs/track_briefs/img/fiordland_plan.png`. Kitul (31 GLB) e descris în
> `docs/asset_briefs/fiordland_inventory.md`, iar măsurătoarea reală a fiecărei
> piese în `docs/asset_briefs/fiordland_masuratori.md` (fundația). **Sursa de
> adevăr pentru cote e măsurătoarea, nu brief-ul**: brief-ul a greșit deja la
> înălțimea fagilor, a ratei și a avionului.

## Regula care se încalcă cel mai des

**Bara nu e layout, e look.** Diorama e comprimată și stilizată: pune Stirling,
cornișa și tunelul unele lângă altele într-un cadru de machetă, iar pista
noastră nu face și nu trebuie să facă asta (traseul real e în `plan.png`,
măsurat, cu ProbeLayout verde). Criticul compară **cum arată materia** — gneisul
ud, apa negru-verde cu fațete, pădurea de fag, spuma, silueta — nu unde cade
fiecare obiect.

Corolar: un critic care spune „la noi tunelul nu e lângă cascadă" a comparat
layout-ul și a ratat sarcina. Singura diferență care contează e una pe care o
poți repara în decorul POI-ului.

**Trei defecte ale dioramei sunt declarate în brief §9.0 și NU se iau din
imagine:** Stirling stă pe un ciot de drum la nivelul mării (în joc cade **pe
cornișă**, la +32 m); autocarul iese din tunel în același sens cu mașinile (în
joc vine **din față**, pe banda stângă); avionul e la ~2× scara lui (anvergura
reală e 8 m). Un critic care cere una din astea trei a citit diorama, nu
pista.

## Ieșirea din buclă (schimbată față de Serengeti și Machu Picchu)

Pe Serengeti 0 din 8 POI-uri au câștigat orb; pe Machu Picchu 0 din 3. Ambele
sesiuni s-au oprit pe buget, nu fiindcă a ieșit bucla. Diorama e o pictură
randată și un cadru low-poly nu o bate orb, oricâte runde ar primi. Deci:

- **judecata rămâne oarbă** (`blind_pair.py`, o planșă per rundă, A sau B,
  o singură diferență numită);
- **ieșirea din buclă e** una din: (a) criticul alege a noastră orb; (b)
  criticul **nu mai numește nicio diferență reparabilă în decorul POI-ului**;
  (c) criticul numește **aceeași diferență de două ori la rând** — atunci
  cauza e sub decor (relief, lumină, shader, asset) și se **oprește bucla**,
  cu decizia pusă în fața dezvoltatorului (memoria
  `criticul-cere-ce-zona-nu-poate-da`);
- **acceptarea finală e verdictul dezvoltatorului la volan**, pe uscat ȘI în
  ploaie (sunt două piste), pe scena integrată.

## Ce se măsoară pe scena integrată (niciodată pe worktree-ul POI-ului)

Convenția de indici (memoria `probe-decor-numar-de-scena`): **`probe_decor` și
`probe_manual` iau numărul de SCENĂ (16); toate celelalte iau INDEXUL (9).**
Cu `--track=9` la `probe_decor` măsori altă pistă și dai verde fals.

| gardă | comandă | prag |
|---|---|---|
| ProbeRace | `res://tools/ProbeRace.tscn -- --mode=race --track=9 --seconds=150 --seed=N` | seed 1..8, **tur minim ≥ 1,64, 0 `[blocaj]`**; repunerile pe distribuția bazei (~9 pe 8 seed-uri, la portalul de est t≈47 s). Rulează și cu `--rain=1`. Citește `[blocaj]`/lent/invers, nu doar repuneri (memoria `zero-repuneri-ascunde-blocajul`) |
| probe_decor | `--script res://tools/probe_decor.gd -- --track=16` | **≤ 38 materiale** (garda); azi ~28 cu particulele de runtime, pe care `probe_decor` NU le numără (+1 real). Un material nou se **cere explicit în raport**, cu ce cumpără vizual |
| ProbeBuried | `res://tools/ProbeBuried.tscn -- --track=9` | **0** îngropate, **0** tavane (ramura de tavan e armată pentru tunel) |
| ProbeTunel | `res://tools/ProbeTunel.tscn -- --track=9 --expect-tube` | gol 9,00 / tavan 6,46 / benzi / CameraZone — verde |
| ProbeLaneClear | `res://tools/ProbeLaneClear.tscn -- --track=9` | **pe linia de bază** (armată la fundație; fără linie de bază pare verde dar nu e — memoria `garda-fara-linie-de-baza-iese-zero`) |
| ProbeLayout | `res://tools/ProbeLayout.tscn -- --track=9` | 2159 m, pantă < 13 % |
| probe_manual | `--script res://tools/probe_manual.gd -- --track=16` | **0 obiecte de reparat** (plutitoare / îngropate) |
| fiord_frustum_table | `python tools/fiord_frustum_table.py` | **PICĂ pe F1 și pe main** (Mitre nevăzut de pe coborâre, decizia (b): rămâne); nu e regresie dacă F1 e singurul roșu; **regenerează grila** (`SvFiordVarfGrid --track=16 --out=tools/data/fiord_varf_grid`) dacă ai atins relieful |
| **sv_hazard_orient** | `--script res://tools/sv_hazard_orient.gd -- --scene=16 --decor` | **0 noduri suspecte** în afara celor cunoscute (avalanșa e orientată din cod; stâlpul de semafor n-are axă). Se rulează după ORICE piesă cu axă montată: pe 25 sep toate cele 6 perdele erau rotite 50–107° de 5 zile fără ca cineva să măsoare |

Cifrele de plecare după fundație (25 sep 2026, `feat/fiord-fundatie`): probe_decor
**23 materiale** (orizontul de rezervă cu 5 materiale a fost înlocuit de GLB-ul
cu 1), ProbeLaneClear **8**, probe_manual **0**, ProbeRace uscat 8/8 tur minim
1,62–1,67 cu 0–3 repuneri (un blocaj tranzitoriu de 3 s la **furca
scurtăturii**, frac 0,356 lat 6,2, apare pe ~1 rulare din 11 — slăbiciune a
furcii, nu a decorului), ploaie 2/2 tur minim 1,57–1,59.

`--import` înaintea oricărei serii (memoria `import-invechit-falsifica-masuratoarea`).

## Captura: ce comandă, pentru care POI

Din mașină, `--gamecam` (camera reală de joc: 10 m sus, 12,5 m spate, fov 68 —
memoria `verifica-cu-parametrii-lui`). **`--rain=0` explicit**: `RainCycle`
pornește la `start_clock` 35, prima ploaie la 60 s; captura implicită e
uscată, dar spune-o în comandă. Pentru POI-urile cu identitate de ploaie (B,
C, D) se face **și** o captură `--rain=1`.

```
& $E --rendering-driver vulkan --path <worktree> `
    res://tools/Snapshot.tscn -- --track=9 --frac=<F> --gamecam --rain=0 [flaguri]
```

Snapshot **nu merge headless** (memoria `snapshot-nu-merge-headless`): cere
fereastră. Capturile se fac **serial**, gărzile în paralel (memoria
`capturile-nu-se-paralelizeaza`).

| POI | frac (măsurate 25 sep 2026) | flaguri | bară |
|---|---|---|---|
| A Cheiul | 0.00, 0.03 | — (plus `--frac=0.97` privind înapoi spre chei) | `bara_poi_A` + `bara_poi_MITRE` |
| B Cornișa | 0.10, 0.17, 0.22 | `--rain=1` la 0.10 (cascada de ploaie B1 activă) | `bara_poi_B` + `bara_poi_MITRE` |
| C Stirling | 0.28, 0.297, 0.31 | `--rain=1` la 0.297 (perdeaua cu 30 % mai grea) | `bara_poi_C` |
| D Chasm | 0.35, 0.40, 0.415, 0.44 | `--torrent-at=<s>` pe bandă (`--route=1` pentru scurtătură) | `bara_poi_D` |
| E Portalul | 0.50, 0.56, 0.605 | `--bus-at=<s>` (autocarul în gura tunelului) | `bara_poi_E` |
| F Coborârea | 0.70, 0.75, 0.79 | avalanșa: **flag lipsă** — `--rock-at` mișcă doar `RockfallHazard`; constructorul F adaugă `--avalanche-at=<s>` în `snapshot.gd` pe tiparul `--rock-at` în prima rundă | `bara_poi_F` |
| G Bowen | 0.84, 0.858, 0.87 | — | `bara_poi_G` |
| H Malul | 0.91, 0.95, 0.98 | avionul/vaporașul: `PathMover` cu ceas — se aduce în cadru pe tiparul `--train-at` | `bara_poi_H` |

## Fracțiile reale ale traseului (NU cele din brief §2, care sunt vechi)

Măsurate pe `Track16.tscn` de pe main (25 sep 2026, lungime 2159,2 m):

| reper | frac | cotă |
|---|---|---|
| grilă / chei | 0.00 | 0 m |
| cascadă de ploaie B1 / B2 | 0.100 / 0.170 | +7,6 / +20,2 |
| **Stirling** (perdea 30 m) | **0.297** (segment 0.273–0.323, semi 6) | +31,9 |
| furca scurtăturii / revenirea | 0.366 / 0.462 | +15 |
| cascadă de ploaie Chasm | 0.400 | +19,3 |
| podețul (`custom_step_ranges`) | 0.406–0.424 (semi 5,5) | |
| torentul | mijlocul benzii (`branch_frac` 0,5) | |
| **portalul de est** + semafor | **0.612** | +44,7 |
| tunelul (ud, `custom_wet_ranges`) | 0.612–0.694 | 45 → 27 |
| cascadă de ploaie F1 | 0.719 | +21,4 |
| **avalanșa** | **0.750** | +15,7 |
| cascadă de ploaie F2 | 0.790 | +7,8 |
| **kickerul Bowen** | **0.858** (râpa 0.84–0.902, fund −8) | +0,2 |
| malul | 0.90–1.00 | 0 |
| Mitre Peak (insulă) | cel mai aproape de 0.160, la 99,5 m de asfalt | dom 69,4 m |

Râpele: marea pe 0.011–0.279 (fund −30, lățime 220, **cornișă**), Chasm pe
0.341–0.444 (fund +7, lățime 25), Bowen pe 0.84–0.902 (fund −8), marea pe
0.919–0.999 (fund −30, cornișă). Semi-lățimi: 8 pe chei și mal, 6 pe cornișă
și Stirling, 6,5 pe D/E, 5,5 pe podeț, 4,5 în tunel (9 m gol), 7 pe coborâre.

## Cele opt contracte

Fiecare: **ce se vede în decupaj** (obligația vizuală) + **ce cere brief-ul**
(obligația de gameplay) + **piesele** (cele din kit + reuse, toate plasabile
după fundație) + **capcana specifică** (memoria care se aplică).

Piese comune tuturor zonelor: `beech_a/b/c` (fagul, coliziune `trunk`),
`beech_dead`, `moss_boulder_a/b/c` (reuse MP, clasa `moss_carpet`),
`fern_cluster` (reuse), `tree_fern` (reuse MP), `guard_rock`, `tussock_clump`.
**Fagii sunt sub cotă** (6,1 / 8,8 / 11,2 m față de 8 / 11 / 14 ceruți):
decizia de scară se ia **o dată, la fundație/captura de kit**, nu per POI.

### A — Cheiul (frac 0.00–0.06, `ZoneA_Chei`)

Din decupaj: **zid de piatră cu babale** pe marginea apei, **ponton de lemn** cu
două **vaporașe albe** legate și caiace colorate, **cafeneaua** cu acoperiș de
tablă și pereți de lemn închis, **pinguini mici pe pietre** (jumătate din
înălțimea unei mașini), apa **negru-verde, plată, cu fațete mari**. Peste apă
(decupajul MITRE): domul cu calotă albă și pădure la bază.

Brief: grila pe asfalt ud lângă ponton; pontonul, magazia și zidul sunt
**pereți cu masă** (contact = ricoșeu); apa de lângă chei = repunere
(`RespawnZone` — verifică că există pe 0.011–0.06, altfel o adaugi); peste
apă Mitre Peak **ca perete negru cu baza în mare** (decizia (b) din 21 sep:
vârful e al cheiului și cornișei, nu al ieșirii din tunel); în spate, Bowen ca
fir alb în perete.

Piese: `wharf` (capete plane la ±10, se înlănțuie), `wooden_pier` (reuse),
`cruise_boat` ×2 (**origine la linia de plutire**, carena coboară 1,2 m;
unul static la ponton, unul pe `PathMover` cu `stick_to_ground=false` pe apă,
ciclu ~120 s), `kayak_a/b`, `cafe_shed`, `penguin_tawaki` ×3 (`none`),
`driftwood`, `guard_rock`.

**Vitrina kitului** (`docs/asset_briefs/fiordland_vitrina.md`, planșa
`img/fiordland_vitrina.png`, flag `Snapshot --vitrina=<stem>`): fagii măsoară
7,0 / 10,2 / 13,5 m în joc (nu se scalează), autocarul, vaporașul, stânca și
jgheabul citesc corect. **Deschis:** acoperișurile `cafe_shed`/`lodge` ies
**tan** (#BB8967) deși stau pe slotul 11 albastru-gri — prima rundă a POI A
face A/B-ul din vitrina.md înainte de orice altceva.

Capcana: **apa.** Memoriile `apa-iluminata-v12` (pata gri = pânză opacă;
Fresnel din chase cam), `apa-stilizata-de-noapte` (saturația, nu luminanța;
variația în reflexii) și `celula-de-apa-plana-peste-mal`. Diorama are apă
negru-verde cu fațete mari — dacă a noastră e turcoaz plat (așa e azi
placeholder-ul), POI-ul e ratat indiferent de chei. Și `ziduri-invizibile-ale-lumii`:
zidul lumii e la 420 m de centroid, vaporașul pe `PathMover` nu iese din el.

### B — Cornișa fiordului (frac 0.06–0.27, `ZoneB_Cornisa`)

Din decupaj: drum **tăiat în peretele de gneis**, peretele **gri cu dungi ude
verticale negre** și mușchi în crăpături pe dreapta, **marea jos pe stânga,
fără parapet**, **rata cu flori roșii** ca accent rar, mașini pe muchie.

Brief: urcare 8,8 % pe cornișă, marea la −5…−30 m pe stânga (râpa 0 e
cornișă, fund −30, lățime 220); două S-uri, al doilea cu concavitatea spre
perete; cascade de ploaie la 0.100 și 0.170 (doar în faza de ploaie); jos
**Seal Rock** cu 4 foci; vaporașul traversează la 100 m; peste apă Bowen
întreagă. Turbo pe dreapta dintre S-uri.

Piese: `nerpa_seal` (reuse Baikal, recolorat `LOG_DARK`) ×4 pe o stâncă în
apă, `rata_tree` (3–4 pe TOT turul, nu pe metru), `guard_rock` (câte unul la
30–50 m, cornișa n-are parapet), `moss_boulder_*`, `fern_cluster`, `tussock`,
`beech_*` rari pe versantul de sus. **Peretele de gneis e teren** (râpa +
`horizon_class`), nu GLB — dacă peretele nostru citește plat, e problemă de
**clasă de textură** (`wet_gneiss`, făcută la fundație) și de lumină, nu de
decor.

Capcana, cea mai scumpă: memoria `umarul-ingust-ascunde-caderea` — ochiul e la
10 m, contează **unghiul** din primii 3 m de la asfalt, nu adâncimea finală.
Cornișa pe stânga trebuie să se vadă **cădere**, nu umăr de iarbă. Memoria
`perete-paralel-nu-se-vede`: doar S-ul spre interior înfășoară peretele —
captura la 0.17 (al doilea S) e cea decisivă. Memoria `reperul-se-vede-pe-patru-axe`:
Mitre se vede de pe B1 100 %, de pe A slab (75 % ceață) — nu muta ceața.
Memoria `caster-departat-fura-umbra`: nimic din orizont cu `cast_shadow`.

### C — Cascada Stirling (frac 0.273–0.323, `ZoneC_Stirling`)

Din decupaj: **perdea albă lată** care cade de pe **buza de rocă** direct
**peste drum**, **bazin alb** cu spray la bază, mașina **în** perdea, peretele
din spatele ei **întunecat și ud**, mușchi pe buză.

Brief: nișă concavă în perete; cascada de 45 m cade de pe surplomb **peste un
prag** și se lățește peste drum pe 30 m; două linii: **prin perdea** (drumul,
6 m) sau **în spatele ei** (pragul `Shelf` de 3 m, uscat, 0,9× grip, vezi
fiordul *prin* apă). Forța în jos scalată cu viteza; în ploaie perdeaua e cu
30 % mai grea → pragul câștigă.

Fundația a montat `stirling_ledge.glb` **paralel cu drumul, pe dreapta**: fața
peretelui la **8,0 m** de axă (semi 6 + sagita de 1,8 m a drumului pe cei
40 m ai peretelui + pragul `probe_manual` de semi+2), buza `Overhang` la
**+14,0** peste jumătatea dinspre perete a perdelei (perdeaua: 6 m lățime
centrată pe axă, 30 m lungime **de-a lungul drumului** — reparată la fundație,
era rotită 90°). `Shelf` (pragul uscat) e la +0,38 în GLB, la 8–11 m de axă,
deci **în afara asfaltului**: linia „în spatele perdelei" din brief e azi doar
cei 3 m de asfalt uscat dintre perdea (+3) și marginea drumului (+6); dacă
POI-ul C vrea pragul de piatră ca bandă, e o decizie cu dezvoltatorul (cere
lărgirea segmentului sau mutarea perdelei), nu decor. **POI-ul C nu mută piesa** —
construiește ce e în jurul ei: mușchiul pe buză și în nișă (`Moss` e nod
separat), bolovanii uzi la baza peretelui, **bazinul alb** (spuma e
`FOAM_WHITE`, ceața joasă de 20 m există din perdea v2), fagii pe platoul de
deasupra peretelui („fără copaci în GLB", brief §1.1), `rata_tree` un
exemplar, `guard_rock` pe marginea mării.

Capcana: memoria `diferenta-on-off-cere-lume-inghetata` — perdeaua se judecă
pe captură cu ploaia în fază fixă (`--rain=0` și `--rain=1`, `--rain-clock`),
nu pe cadre întâmplătoare. Verdictul la volan din 21 sep: perdeaua citea
„draperie de fire"; v2 a reparat direcția, splash-ul și parbrizul — dacă
criticul mai spune „fire", e **shader**, nu decor: oprește bucla (regula c).
Memoria `suprafete-cu-goluri-si-praguri`: nimic cu prag > 0,3 m pe pragul
uscat de 3 m, altfel e zid și linia a doua dispare. ProbeRace cu
`--slice=0.27,0.33` înainte/după.

### D — Chasm și pădurea de mușchi (frac 0.323–0.46, `ZoneD_Chasm`)

Din decupaj: **pădure de fag** cu **trunchiuri negre subțiri** și coronament
**în etaje** (cerul se vede printre ele), **bolovani înveliți în mușchi**,
**râul alb** săpat în marmite, **podețul de scânduri** cu balustradă de lemn,
**doi kea** pe un ciot.

Brief: drumul intră într-o vale laterală (râpa 1, fund +7, lățime 25), coboară
sub coronament (lumina scade natural, fără `CameraZone`); podeț 0.406–0.424
(0,85× grip, `custom_step_ranges` dă vibrația — **tablia e drumul**, GLB-ul
are doar balustradele); râul Cleddau la −8 m, ceață de râu, râu = repunere;
buturuga cu 2 kea (`Idle`, capul urmărește liderul e opțional). Scurtătura
`ScurtaturaChasm` 0.366–0.462 cu **torentul în pulsuri** la mijloc
(`torrent_chute.glb` montat la fundație): drumul vechi de pământ prin pădure,
banda 3,2 m — decorul îi dă **pereți**: trunchiuri și bolovani aproape,
mușchi, ca banda să citească „drum vechi", nu poteca pe iarbă.

Piese: `beech_a/b/c` (**200+**, `MultiMesh` obligatoriu peste ~1000 de piese
— memoria `decor-in-masa-cere-multimesh`; sub 1000, noduri în `DecorManual`),
`beech_dead`, `moss_boulder_a/b/c`, `chasm_rock` (marmitele, în albie),
`chasm_bridge_rail` — **atenție: podețul e pe curbă** (sagita 2,16 m pe
38,4 m), iar balustrada dreaptă de 40 m cu șinele la ±5,84 taie tăblia (semi
5,5) la capete; fundația a scos-o. Opțiuni pentru POI D: două jumătăți de 20 m
rotite pe tangentă, sau refacerea GLB-ului pe arc — decizie de asset, se
scrie în raport, nu se strecoară. `torrent_chute` e montat la fundație
paralel cu banda, pe partea opusă traseului principal, fața la 4,5 m de axa
benzii, buza la +14 peste marginea ei; POI D verifică pe captură cu
`--torrent-at` că pulsul cade DIN jgheab. `stump` + `kea` ×2 (`PathMover` sau static cu
`Idle`), `tree_fern`, `fern_cluster`, `driftwood` pe mal.

Capcana: memoria `aranjamentul-bate-numarul` — scatter pe GRILĂ citește
„instanțe plasate", nu pădure; jitter, yaw, densitate crescândă spre râu.
Memoria `podeaua-vaii-e-banda-lipsa`: benzile de vegetație se opresc lateral,
nu coboară pe fund — râul trebuie să aibă **albie** cu bolovani, nu podea
de râpă goală. Memoria `particule-muchia-nu-numarul` pentru ceața de râu.
**AI-ul nu vede decor static** (memoria `obstacol-pe-drum-poate-fi-gimmick`):
niciun trunchi pe banda de 3,2 m a scurtăturii; ProbeRace cu
`--slice=0.34,0.47` și `ProbeFiordScurtatura.tscn` (4×2×2) înainte/după.

### E — Urcarea și portalul de est (frac 0.46–0.612, `ZoneE_Portal`)

Din decupaj: **gura de beton** cu **galerie de avalanșă** (arcade) și
semaforul pe stâlp, **masivul de granit gol** deasupra, **grohotiș** pe pantă,
**chevron-uri** pe urcare, pădurea se rărește spre portal, autocarul în gură.

Brief: urcare 12 % pe drum tăiat în grohotiș, **panouri de zonă de avalanșă**
(chevron + fără text), jaloane; portalul la 0.612 (+45, punctul cel mai
înalt); tubul, portalurile cu **aripi-pâlnie** și galeria sunt **cod**
(`Track._build_tunnels` din `SemaforTunel`) — **POI-ul E nu construiește
tunelul**. Stâlpul de semafor cu `HazardLamp` e montat la fundație.

Stâlpul `traffic_light_pole` e la fundație la 10,3 m de axă, dar cele două
`HazardLamp` rămân create de `SemaforTunel` pe poziția lor veche, **nu în
alveolele stâlpului** — POI-ul E le aliniază (offsetul lămpii e în
`tunnel_signal_hazard.gd`; alveolele: 0,3 m diametru, la 0,35 m pe verticală).

Piese: `chevron_sign` (reuse), `road_sign_blank`, `snow_pole`, `scree_slab`
(**placă pe pantă**, nu con; `none`), `tussock_clump` pe platou, `beech_*`
tot mai rari, `beech_dead` lângă portal, `guard_rock`, `moss_boulder_*`.

Capcana: portalul e pe **culoarul autocarului**: AI-ul ține dreapta pe roșu,
autocarul iese pe stânga la 18 m/s — **nimic** pe cei 9 m ai gurii și pe
aripi. Aripile-pâlnie sunt acolo fiindcă fără ele rama ejecta 8/10 curse la
0.610 — nu le acoperi cu decor care să facă același lucru. Memoria
`hazard-dezaliniat-contamineaza-verdictul`: dacă mutați ceva la portal,
verificați cu `ProbeTunel` înainte de ProbeRace. Din decupaj lipsește ce nu
avem: **galeria de avalanșă cu arcade** nu e în kit (§1.8: portalurile sunt
cod) — criticul care o cere numește o decizie de asset, nu de decor: regula (c).

### F — Coborârea spre fiord și avalanșa (frac 0.694–0.84, `ZoneF_Coborare`)

Din decupaj: drum **în pante prin pădure rară**, **cicatricea** avalanșei ca
fâșie goală de **granit lucios** cu **trunchiuri și bolovani rostogoliți**
peste drum, mașina pe pantă.

Brief: ieșire din tunel la +27, coborâre 8 % (7 m semi); la 0.750
`AvalansaF` (ciclu 90 s, `tree_avalanche.glb` cu `Boulder_A..D` cablat la
fundație, 9 bucăți rostogolite); cascade de ploaie la 0.719 și 0.790;
`ScarPeakF` (masivul cicatricei) există deja pe versant. Decizia (b): fiordul
NU e „în față" aici (e în dreapta-spate, la 87–138°) — nu încerca să-l aduci.

Piese: `beech_*` rari, `beech_dead` pe cicatrice, `moss_boulder_*`, `guard_rock`,
`scree_slab` pe cicatrice, `driftwood` ca trunchiuri căzute **în afara
drumului**, `tussock`.

Capcana: cicatricea se citește prin **contrast de clasă** (granit lucios
`wet_gneiss` față de pădure), nu prin număr de bolovani — memoria
`contrastul-nu-geometria`. Avalanșa mișcă bucăți **peste drum**: decorul din
fâșia ei (0.74–0.76, toată lățimea + 15 m lateral) trebuie să fie `none` sau
absent, altfel bucățile se blochează în el (verifică în log că 9 bucăți ajung
la râu). Memoria `avalansa-alpii-ciclu-implicit`: perioada vine din marker
(90), nu din implicit. Captura avalanșei cere flagul nou `--avalanche-at`.

### G — Kickerul Bowen (frac 0.84–0.90, `ZoneG_Bowen`)

Din decupaj: **cascadă înaltă** în perete pe dreapta, **bazin de apă albă** cu
spray, kicker de piatră, mașina **în spray**, pietriș, pădure pe amândouă
malurile.

Brief: baza cascadei Bowen (45 m, în perete pe dreapta), traversare pe
**kicker de piatră de 6 m** peste bazinul de cădere (râpa 2, fund −8, 18 m de
apă albă — `KickerBowen` e `TrackChannel` cu `jump`, `water_half` 6, există);
aterizare pe pietriș 0,85×; `RespawnZone` în bazin. De aici Stirling se vede
întreagă peste apă.

Piese: perdeaua Bowen e `WaterfallVisual` din cod (una din cele 7 perdele) —
POI-ul G construiește **peretele** din care cade (bolovani mari `moss_boulder`,
`chasm_rock` în bazin, `guard_rock`), **pietrișul** aterizării (clasă
`SAND_SHADOW`, nu GLB), spuma bazinului (`FOAM_WHITE`), pădurea pe maluri,
`driftwood` la apă.

Capcana: memoria `ProbeRace` la 0.858 — saltul e reglat (gap 12); orice
piesă cu coliziune pe traiectoria de zbor sau pe aterizare (0.85–0.875,
±7 m) schimbă distribuția: ProbeRace `--slice=0.83,0.90` obligatoriu.
Memoria `strop-apa-particule`: spray-ul poartă viteza mașinii, culoare sRGB.
Peretele cascadei e **teren** (`horizon_class` / râpa) — dacă citește plat,
e clasă de textură, nu decor (regula c).

### H — Malul și pista de avioane (frac 0.90–1.00, `ZoneH_Mal`)

Din decupaj: **lodge lung** cu acoperiș în două ape, **containere**,
**heliport cu H alb**, **pista de avioane paralelă** cu drumul, **avionul mic**
aterizând cu umbra pe pistă, fagi rari, cheiul în stânga-jos.

Brief: drum drept pe mal (semi 8), satul (lodge, magazii, heliport gol),
**pista de avioane paralelă la 20 m pe dreapta**: avionul vine din spate la
25 m, coboară de-a lungul drumului, atinge pista la 80 m în față (ciclu ~50 s,
`PathMover` cu `stick_to_ground=false`, **origine în centrul fuzelajului**),
umbra lui trece peste mașini; container de bagaje, caiace, pinguini; apa pe
stânga = repunere; dreapta lungă = locul de turbo.

Acoperișul `lodge` are aceeași problemă de culoare ca la POI A (vitrina.md):
se rezolvă o dată, la A, și se preia aici.

Piese: `lodge`, `cafe_shed` (ca magazie), `luggage_container` ×2–3,
`heli_pad` (`none`), `bush_plane` (`PathMover`, curbă în aer care coboară
paralel cu drumul), `snow_pole`/`road_sign_blank` ca balize, `kayak_*`,
`penguin_tawaki`, `driftwood`, `beech_*` rari. **Pista de avioane nu are GLB**:
e o fâșie plată de `CONCRETE`/`SAND_SHADOW` pe teren (PaletteBox sau bandă de
teren aplatizată la cota drumului), cu marcaje ca fețe `FOAM_WHITE`.

Capcana: avionul de 8 m anvergură la 25 m înălțime e **mic în cadru** — umbra
lui pe drum e ce se vede (memoria `caster-departat-fura-umbra` merge în
sens invers aici: avionul TREBUIE să arunce umbră, deci `cast_shadow` ON și
în `shadow_distance`, memoria `umbre-exista-dar-cascada-e-scurta`). Memoria
`corp-cinematic-aparut-in-masina`: un `PathMover` atribuit aproape de grilă =
viteză uriașă în primul cadru; punctul de start al curbei departe de mașini.
Memoria `eta-cu-viteza-curenta-minte`: avionul n-are gameplay, dar dacă
umbra lui trece peste grila de start în countdown, se vede ca bug.

## Bucla oarbă

1. Constructorul (Sonnet) lucrează în `D:/GameDev/wt-fiord-poi-<x>` pe
   `fiord/poi-<x>`, plecat din main după merge-ul fundației; `--import` la
   creare; comite după fiecare pas care trece o gardă; **prima rundă începe cu
   `git status` / `git diff`** (lucrul necomis al unui predecesor întrerupt).
2. Face captura din mașină la fracțiile din tabel, cu flagurile de hazard.
3. Criticul, **context proaspăt**, primește planșa din
   `python tools/bar/blind_pair.py "<captura>" "docs/track_briefs/img/bar_fiordland/bara_poi_<X>.png" "<out>.png" --seed <N>`.
   **O singură planșă per rundă** (docs/bara_vizuala.md).
4. Criticul **deschide** planșa, verifică amprenta din colț, alege A sau B,
   **apoi** citește cheia `<out>.png.<sig>.key` și raportează cinstit dacă a
   nimerit.
5. Numește **o singură** diferență care contează, reparabilă în decorul
   POI-ului. Lauda nu ajută.
6. Ieșirea din buclă: regulile (a)/(b)/(c) de mai sus. La (a) sau (b): gărzile
   pe scena integrată, apoi merge. La (c): oprire și decizie.

Seed-ul planșei se schimbă la fiecare rundă, și numele fișierului la fel:
amprenta cheii e hash pe argumente, iar refolosirea unui nume între runde a
făcut deja doi critici să se judece unul pe altul (memoria
`critic-orb-coliziune-de-plansa`).

**Valuri de 3 POI-uri în paralel, niciodată 8** (memoria
`valuri-de-trei-nu-opt-agenti`). Ordinea propusă: val 1 = B, C, D (identitatea
pistei: cornișa, Stirling, pădurea); val 2 = A, G, H (apa și satul); val 3 =
E, F (portalul, avalanșa) + reluarea POI-ului cel mai slab din valurile 1–2.
Integrarea într-un worktree dedicat pe main; gărzile **doar pe scena
integrată** (un worktree de POI are numai zona lui populată, restul pare
regres).
