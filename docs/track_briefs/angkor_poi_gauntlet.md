# Angkor: contractul per POI pentru gauntlet

> Fișa de lucru a perechilor constructor/critic pe Track24 (`angkor`, indexul 16).
> **Bara** e diorama acceptată `docs/track_briefs/img/angkor_diorama_v03.jpg`
> (brief §9.1), decupată per POI în `docs/track_briefs/img/bar_angkor/bara_poi_<X>.png`
> (`tools/bar/crop_angkor_bar.py`). **Planul real** al traseului e
> `docs/track_briefs/img/angkor_plan_adnotat.png`. Kitul (44 GLB) e descris în
> `docs/asset_briefs/angkor_kit.md`, iar ce s-a acceptat, cu cote măsurate, în
> `docs/asset_briefs/angkor_inventory*.md`. Brieful pistei
> (`docs/track_briefs/angkor.md`) dă intenția; **cotele vin din Track24 și din
> măsurători, nu din brief și nici din dioramă.**
>
> Ramura de bază: `angkor/poi-fundatie` (stivuită pe `angkor/kit-val1`, PR #660,
> nemergeat). Worktree-ul de integrare: `D:/GameDev/wt-angkor-poi-int`.

## Regula care se încalcă cel mai des

**Bara e look, nu layout.** Diorama comprimă 2,4 km într-un cadru de machetă:
Bayonul stă deasupra Porții de Sud, templul lângă Srah Srang. Pista noastră nu
face asta și nu trebuie să facă. Criticul compară **cum arată materia și ce
obiecte locuiesc locul**: gresia aurie cu licheni, laterita roșie a drumului,
apa de jad cu lotuși, coronamentul des de junglă, rădăcinile argintii. Nu
compară unde cade fiecare obiect.

**Abaterile declarate ale dioramei, care NU se iau din imagine:**
- **diagonala F → C** prin piața regală nu există (ChatGPT a desenat-o de două ori, brief §9.1);
- **fețele sculptate** (Bayon, Poarta de Sud, uriașii, Regele Lepros) sunt
  **datorie deschisă** a kitului (`angkor_kit.md` §1.1): la noi sunt simplificate.
  Un critic care cere „fețe mai expresive” a numit o diferență de asset, nu de
  decor → ieșire (c) imediată pe acel punct, nu rundă nouă;
- **furtuna spre est** (benzile de nori) nu e în fundal, decizie deschisă (kit §3).

## Ieșirea din buclă

Pe Serengeti, Machu Picchu, Fiordland și Carrara: **0 câștiguri orb** din 24 de
POI-uri. Diorama e o pictură randată; un cadru low-poly nu o bate orb oricâte
runde ar primi (memoria `gauntlet-iesirea-din-bucla`). Deci:

- **judecata rămâne oarbă**: `python tools/bar/blind_pair.py <a_noastră> <bara> <planșa> --seed N`,
  o planșă per rundă, A sau B, **o singură diferență numită**. Seed-ul și numele
  planșei se schimbă la fiecare rundă (memoria `critic-orb-coliziune-de-plansa`);
- **ieșirea e una din**: (a) criticul alege a noastră orb; (b) criticul nu mai
  numește nicio diferență reparabilă în decorul POI-ului; (c) criticul numește
  **aceeași diferență de două ori la rând** → cauza e sub decor (relief, lumină,
  shader, asset), bucla se oprește, decizia merge la dezvoltator;
- **maxim 4 runde per POI**;
- verdicte opuse între runde (cere des, apoi rar) = zgomot → ieșire
  (memoria `critic-orb-cere-densitate-apoi-oscileaza`);
- **acceptarea finală e verdictul dezvoltatorului la volan**, pe scena integrată.

## Cum se pune decorul (fundația)

**Generatorul e sursa de adevăr**: `tools/gen_angkor_route.py` scrie
`scenes/tracks/Track24.tscn`. **Nu edita .tscn-ul de mână.** Decorul fiecărui
POI stă în `tools/angkor_decor/zona_<x>.py` (formatul e în antetul fișierului),
iar jungla în masă în `tools/angkor_decor/jungla.py`. **Un constructor atinge doar
fișierul lui.** Piesele kitului deja montate de generator (turnurile Bayon,
porțile, balustradele naga, uriașii, terasa, bolțile, templul, galeria, Bakheng,
debarcaderul) **nu se mută** din fișierul de zonă; dacă una trebuie mutată, se
cere coordonatorului în raport.

```
ITEMS = [ ("A_Lotus3", "plants/lotus_cluster.glb", 0.021, -12.5, 30.0, {"y": 1.62, "coliziune": "none"}), ... ]
KIT_Y = { "A_Lotus3": 1.62 }
FOREST = [ {"kind": "disc", "at": (0.02, -40.0), "radius": 25.0, "claim": True}, ... ]   # luminiș, fără specii
```

- `frac` e pe **index**, `lateral` e la **dreapta** sensului de cursă; `yaw` + = spre stânga;
- `"world": (x, z)` pune piesa absolut (pentru interiorul buclei, departe de drum);
- după orice schimbare: `python tools/gen_angkor_route.py scenes/tracks/Track24.tscn`.
  Generatorul tipărește fiecare piesă cu frac, lateral, cotă și cota drumului;
- **cotele se măsoară, nu se ghicesc**:
  `godot --headless --fixed-fps 60 --path . res://tools/ProbeCarraraMontaj.tscn -- --track=16 --decor --no-batch`
  dă terenul minim/mediu/maxim de sub amprenta fiecărei piese, cât plutește și
  distanța la marginea drumului. **`--no-batch` e obligatoriu** (altfel decorul e
  copt în MultiMesh și sonda nu măsoară nimic). Cota se trece în `KIT_Y` ca teren
  minim − 0,03 m (memoria `origin-base-ridica-tot-obiectul`). Apa: șanțurile au
  cota apei în `custom_ravine_water` (generator, `WATER_AW`); lotușii stau pe ea;
- **luminișurile**: un disc `FOREST` cu `"claim": True` și **fără specii** scoate
  jungla în masă din interiorul lui (piețe, temple, platforme). Fișierele de zonă se
  citesc **înaintea** junglei, deci luminișul câștigă;
- **coliziunea** e automată, din `world_prop.gd` (`hull` implicit). **AI-ul nu
  vede decorul static** (memoria `obstacol-pe-drum-poate-fi-gimmick`): orice piesă
  cu corp la mai puțin de ~3 m de marginea asfaltului se dovedește cu ProbeRace;
- **materiale**: clasele vin din `CLASSES_ANGKOR` (`world_prop.gd`) și din atlas.
  Un asset nu aduce textură proprie. Bugetul e **≤ 38** per pistă; un material nou
  se cere explicit în raport, cu ce cumpără vizual. Piesele reuse (alte kituri) pot
  ieși pe culorile altei teme: verifică pe captură, nu pe cifră
  (memoria `monocromia-se-masoara-dupa-remap`);
- **decor în masă**: peste ~1000 de noduri, scena nu mai termină de încărcat
  (memoria `decor-in-masa-cere-multimesh`): tot ce e mulțime (copaci, tufe) merge
  în `FOREST`, nu în `ITEMS`;
- **Index vs scenă** (memoria `probe-decor-numar-de-scena`): `probe_decor` și
  `probe_manual` iau numărul de **scenă (24)**; snapshot, ProbeRace, ProbeBuried,
  ProbeLaneClear, ProbeLayout și ProbeCarraraMontaj iau **indexul (16)**.

## Ce se măsoară

`--import` la crearea worktree-ului și după orice GLB nou
(memoria `import-invechit-falsifica-masuratoarea`). Liniile de bază sunt pe
`angkor/poi-fundatie` (6 nov 2026), în §„Linia de bază” de mai jos.

| gardă | comandă | contract |
|---|---|---|
| ProbeRace | `bash tools/angkor_race_run.sh "$PWD" <dir> 5`, apoi `python tools/angkor_race_sum.py <dir_bază> <dir>` | **zero repuneri/ejectări/`[blocaj]` noi atribuibile zonei** (citește unde sunt, nu doar totalul: memoria `zero-repuneri-ascunde-blocajul`; nedeterminism: compară distribuții, memoria `proberace-nedeterminism`) |
| probe_decor | `--headless --path . --script res://tools/probe_decor.gd -- --track=24` | materiale ≤ 38 |
| probe_manual | `--headless --path . --script res://tools/probe_manual.gd -- --track=24` | zero piese noi plutind / îngropate / pe drum |
| ProbeLaneClear | `res://tools/ProbeLaneClear.tscn -- --track=16` | exact linia de bază |
| ProbeBuried | `res://tools/ProbeBuried.tscn -- --track=16` | OK |
| ProbeLayout | `res://tools/ProbeLayout.tscn -- --track=16` | OK |
| ProbeAngkorPas6 | `res://tools/ProbeAngkorPas6.tscn` | OK (mecanicile pasului 6) |

## Captura

`bash tools/angkor_capture.sh "$PWD" <frac> <out.png> [flaguri]` — din mașină, cu
camera reală de joc (`--gamecam`), **serial**, cu lacătul de GPU
(`D:/GameDev/.render_lock`, comun tuturor sesiunilor). Snapshot **nu merge headless**.
O captură nu e un verdict (memoria `o-captura-nu-e-un-verdict`): se fac 2–3 per
POI, planșa oarbă se face pe cea mai reprezentativă.

Capturile de bază (înainte de gauntlet) sunt în
`docs/track_briefs/img/angkor_poi/baza/<POI>_<frac>.png`.

| POI | frac (index) | capturi | bară |
|---|---|---|---|
| **A** calea de vest | 0,000–0,058 | 0,010 · 0,040 | `bara_poi_A` |
| **B** prin Angkor Wat | 0,058–0,114 | 0,075 · 0,100 | `bara_poi_B` |
| **C** Phnom Bakheng | 0,114–0,318 | 0,200 · 0,290 | `bara_poi_C` |
| **D** calea uriașilor | 0,318–0,403 | 0,340 · 0,390 | `bara_poi_D` |
| **E** Bayonul | 0,403–0,498 | 0,430 · 0,470 | `bara_poi_E` |
| **F** piața regală / terasa | 0,498–0,649 | 0,550 · 0,620 | `bara_poi_F` |
| **G** Ta Prohm | 0,649–0,761 | 0,690 · 0,740 · scurtătura `--route=1` 0,700 | `bara_poi_G` |
| **H** Srah Srang | 0,761–1,000 | 0,820 · 0,930 | `bara_poi_H` |

## Valurile

Câte trei agenți grei, niciodată opt (memoria `valuri-de-trei-nu-opt-agenti`).
Două POI-uri care se calcă pe decor nu merg în același val.

Capturile de bază (`r0`) arată trei diferențe față de bară care **nu sunt ale
niciunui POI** și pe care criticul le-ar numi pe toate opt: (1) **nu există
junglă** — câmp de iarbă oliv peste tot; (2) **drumul e asfalt închis cu linie
albă întreruptă** pe A, B, D, E, F (citește „șosea modernă”), iar în bară e
laterită roșie peste tot; (3) **apa e turcoaz-cyan luminos**, în bară e jad opac.
Se repară o dată, global (memoria `critic-orb-cere-densitate-apoi-oscileaza`):

- **Valul 1: J (jungla în masă), S (suprafețele: drumul și apa), E (Bayonul).**
  Runda 1 a fiecăruia se face **din contract**, fără critic; criticul orb judecă
  prima dată pe scena integrată J + S + E, ca să nu ardă runde pe drumul și apa
  care oricum se schimbă. E nu atinge suprafețele.
- **Valul 2: A, D, G** (pe baza integrată; G e cel mai dependent de junglă).
- **Valul 3: B, C, F, H.** (B lângă A: după valul 2.)

**Filtrul coordonatorului:** pe tot gauntlet-ul, criticul e întrebat de
**primele trei** diferențe în ordinea importanței; coordonatorul trimite
constructorului prima care e a POI-ului lui. Una globală (junglă, drum, apă,
cer, fețe sculptate) se notează la „global”, nu se dă POI-ului.

## Contractele (valul 1: J, S, E; A urmează în valul 2)

Fiecare contract are trei părți: **ce se vede în decupaj** (obligația vizuală),
**ce cere brieful** (gameplay-ul, care nu se strică) și **capcana**.

### J — Jungla în masă (toată pista, `jungla.py`)

**Din decupaj (toate opt):** coronament **continuu și des** de copaci cu coroane
late în etaje (tetrameles, dipterocarp), trunchiuri argintii cu rădăcini-contrafort,
palmieri de zahăr pe malurile apei și pe orezării, subarboret verde (ferigi,
arbuști) la marginea drumului. Junglă **și în interiorul buclei**, nu doar pe margini:
monumentele ies DIN junglă.

**Din brief:** §5.4 (specii: `tetrameles_a/b`, `dipterocarp`, `strangler_fig`,
`sugar_palm`, plus reuse `trees/banyan`, `plants/fern_cluster`,
`halong/plants/bamboo_clump`, `plants/tropical_shrub`). Piețele, templele și apa
rămân libere: incinta Angkor Wat (peluza dintre galerie și templu), piața regală
(F), platforma de sus Bakheng (C), terasa Bayonului (E), bazinele (Srah Srang,
șanțurile, bazinele de reflexie). Bakheng urcă „în serpentine sub coronament”
(întuneric verde).

**Capcana:**
- doar `MeshForest` (fantome, fără coliziune); primul rând cu trunchi lângă drum
  e treaba POI-urilor, nu a junglei;
- apa: `max_below_road_m` mic pe zonele de lângă șanțuri, ca să nu urce copaci din
  apă; măsoară pe captură, nu presupune;
- **costul**: triunghiuri × instanțe; `MeshForest` tipărește totalul și LOD-urile.
  Comparația cu Kyoto/Carrara (pădurile deja livrate) e linia de plafon
  (memoria `plafon-masurat-nu-presupus`); `ProbePerf` dacă ai dubii, cu încălzire
  (memoria `probe-perf-incalzire-gpu`);
- **clasele**: speciile reuse trebuie să iasă pe paleta Angkor (verde de junglă,
  nu verdele Ha Long sau Kyoto) — `CLASSES_BY_MODEL` / `CLASSES_ANGKOR`; verifică
  pe captură;
- inelele de fundal (`horizon_rings`, `clear` 120) stau dincolo: jungla nu trebuie
  să le dubleze până la zidul lumii (memoria `ziduri-invizibile-ale-lumii`).

### S — Suprafețele: drumul și apa (toată pista, în generator)

**Din decupaj (toate opt):** drumul e **laterită roșie de pământ**, fără marcaje,
cu margini moi; pe căile de peste șanțuri (A, D) e **pavaj de gresie** cald, tot
fără marcaje; apa șanțurilor, a bazinelor și a Srah Srang e **jad opac**,
verde-albăstrui saturat, nu turcoaz luminos; malurile și solul de sub junglă sunt
verde-închis / pământ, nu iarbă oliv uniformă.

**Din brief** (§4): laterita pe `custom_dirt_ranges` cu tentă `TILE_TERRACOTTA` 23;
gresia `ROCK_LIGHT` 3 + clasa `angkor_sandstone`; apa „`REEF_SHALLOW` 17 împins spre
verde, saturat, nu luminos” (memoria `apa-stilizata-de-noapte`: saturația, nu
luminanța), opacă (memoria `apa-iluminata-v12`); ceața în familia solului
(memoria `ceata-in-familia-solului`). **Niciun slot nou.**

**S e singurul care atinge în generator** suprafața drumului (`custom_road_surface`,
`custom_dirt_ranges`, marcajele), stilul apei și tenta solului din tema `angkor`
(`track.gd`). Mecanismele există pe alte piste (Carrara: `custom_water_styles`;
drumurile de pământ pe Serengeti, Machu Picchu, Monument Valley): citește-le înainte
să scrii cod nou; dacă e nevoie de cod nou în `track.gd`, **opt-in pe temă/cheie**,
cu hash neutru pe celelalte piste (memoria `fiordland-poi-gauntlet-sesiune`, lecția 2:
verifici cu hash, nu cu afirmația).

**Capcana:**
- **gripul**: `custom_dirt_ranges` poate schimba aderența (praf = iarbă lentă?).
  Citește ce face suprafața în fizică înainte; contractul e **zero schimbare de
  gameplay** — ProbeRace (tur mediu, repuneri) față de bază. Dacă laterita vizuală
  cere suprafață de drum cu altă fizică, separă vizualul de fizică;
- ploaia (`RainCycle`) udă laterita (`track.rain_wet`, stropi roșii): verifică
  capturi și pe ploaie (frac cu ploaia pornită, flagul de ceas din snapshot);
- pe ramura scurtăturii (`TrackBranch`), suprafața e rețeta temei + tentă (GRAVEL a
  dat ejectări, kit §3) — nu o schimba fără ProbeRace;
- apa: `probe_manual` și lotușii stau pe cota apei — schimbi culoarea, nu cota.

### A — Calea de vest (frac 0,000–0,058, `zona_a.py`)

**Din decupaj:** drumul roșu pe malul șanțului de jad, **lotuși deși, roz, și nuferi**
pe toată apa; **balustrada naga** cu capul în evantai la capete; gopura și cele
cinci turnuri aurii **oglindite** în apă; jungla și palmierii pe malul opus.

**Din brief:** grila pe calea de 9 m peste șanț; balustrada are **goluri**
(`naga_balustrade_gap`, prăbușiri — singurele locuri unde cazi în șanț);
`RespawnZone` pe șanț. Balustradele există (generatorul, stil 3, valul 2 al kitului).

**Capcana:**
- grila de start și primii ~100 m sunt plutonul strâns: nimic cu corp la mai
  puțin de 3 m de asfalt pe 0,00–0,05 fără ProbeRace;
- golurile din balustradă schimbă coliziunea (zidul din cod e continuu): un gol
  adevărat cere schimbare în generator → **se cere coordonatorului**, nu se face
  din fișierul zonei;
- lotușii stau pe cota apei, cu `coliziune: none`; măsoară cota apei, nu o ghici;
- capul naga de la începutul balustradei e la capătul desfăcut (ejectări la start,
  pasul 6): nu adăuga piese solide acolo.

### E — Bayonul (frac 0,403–0,498, `zona_e.py`)

**Din decupaj:** **pădurea de turnuri cu fețe** (nu doar cele 3 de pe drum) pe
terasă și pe margini, zidul terasei cu creneluri/balustrade de piatră, drumul roșu
printre turnuri, jungla deasă în spate. (Fața din stânga decupajului e Poarta de
Sud, a lui D: nu o construi aici.)

**Din brief:** 3 turnuri PE carosabil (`BayonTurn0..2` + `bayon_face_tower_a/b/c`,
existente, cu culoarul AI `custom_lane_bias` 0,72); **restul pădurii de turnuri pe
margini, la 4–20 m**; fum de tămâie; semi-umbră între turnuri; rampa de est spre
piața regală.

**Capcana:**
- **ProbeLaneClear** are linia de bază cu turnurile pe drum; orice turn nou de pe
  margine cu corp la mai puțin de 4 m de asfalt e un obstacol nou → ProbeRace pe
  felia E (`blocaje_E`, `pereti_E` în `angkor_race_sum.py`);
- turnurile de margine (9 m) intră în cadrul camerei de joc: plafonul din frustum
  (memoria `inaltimea-obiectelor-si-camera`), nu ascunde turnurile de pe drum;
- fumul de tămâie: particule cu plafon de count, panza cu textură de cădere
  (memoria `particule-muchia-nu-numarul`); dacă cere cod nou, se cere coordonatorului.

## Raportul constructorului (la fiecare rundă)

- SHA-urile (comite după fiecare pas care trece o gardă);
- piesele adăugate (nume, frac, lateral, cotă);
- capturile (căi absolute);
- gărzile cu cifre față de linia de bază;
- ce a cerut criticul în runda precedentă și ce s-a schimbat.

Constructorul **nu își judecă singur planșa oarbă**: o face criticul, pe planșa
produsă de coordonator.

## Linia de bază (angkor/poi-fundatie, 6 nov 2026)

| gardă | linia de bază |
|---|---|
| probe_decor | 782 de prop-uri, 183 de desene, **16 materiale** (≤ 38), 991k triunghiuri |
| probe_manual | OK |
| ProbeLaneClear | **41** (7 Bayon + 34 rampa-rădăcină INAINTE) |
| ProbeBuried / ProbeLayout / ProbeAngkorPas6 | OK |
| ProbeRace (16 seed-uri × 8 mașini × 250 s) | log-urile în `D:/GameDev/_angkor_race/baza` (din valul 3b al kitului): **repuneri 7 / ejectări 6 / blocaje 19** pe 16 seed-uri, tur mediu 81,5 s, domino 9,7% striviri, airtime 0,66 s. Ejectările: turnul Bayon b ×2 (0,615), creasta (0,441 ×2), coridorul scurtăturii ×3 (0,676–0,732). Avertismentul „6 siluete de orizont n-au încăput” e preexistent |

## Valul 2: contractele D și G (A e mai sus)

**Ce s-a închis în valul 1** (verdictele: `D:/GameDev/_angkor_race/critic/verdicte.md`):
J și S au ieșit pe (c) după două runde orbe (4/4 REF de fiecare dată). Pădurea
citește „plantație de trunchiuri goale în rânduri” (r1 mesteacăn → r2 eucalipt):
cauza e **forma asset-ului** (coroana sus și plată), nu culoarea. Lumina: r1 prea
dură → r2 murdară, ambele „cer roz-mov plat” față de „lumină aurie caldă + nori
violeți”: decizia cerului/furtunii. **Ambele sunt la dezvoltator.** În valul 2 se
filtrează ca globale: copacii, lumina, cerul, fețele sculptate, materialul gresiei.

### D — Calea uriașilor și Poarta de Sud (frac 0,318–0,403, `zona_d.py`)

**Din decupaj:** calea dreaptă cu **șirurile de uriași care țin naga** pe ambele
părți (există: deva/asura pe balustrada din cod), **bazinele cu lotuși** pe
laturile căii, Poarta de Sud cu fețe la capăt (există), elefantul în piață
(hazardul, există), jungla închisă în jurul porții.

**Din brief:** coborâre rapidă pe flancul de nord al dealului, apoi dreapta de
120 m peste șanțul Angkor Thom; piața de 9 m după poartă, unde traversează elefantul.

**Capcana:**
- **elefantul**: nimic în piață pe traseul lui (`SlidingHazard` TRAVERSARE) și nimic
  care să-l ascundă în deschiderea porții (e citit prin poartă, brief §2 D);
- dreapta e de drafting și îmbrânceli: nimic cu corp pe ea; lotușii pe cota apei,
  `coliziune: none`;
- blocajele de bază sunt **la poarta elefantului (0,367–0,371)**, 10–20 pe 16
  seed-uri: zero în plus (citește-le pe frac);
- zidul de incintă Angkor Thom (laterită, `LARCH_RUST` 27) de o parte și de alta a
  porții e decor, dar e și rama pâlniei: nu-l aduce la mai puțin de 3 m de asfalt.

### G — Ta Prohm (frac 0,649–0,761, `zona_g.py`; scurtătura e `--route=1`)

**Din decupaj și din ambele runde oarbe** (criticul a numit-o de două ori ca
decor G): **ruinele** — galerii de gresie cu mușchi prăbușite, buiandrugi, uși,
blocuri căzute, ziduri de incintă din laterită **înghițite de rădăcini**; ficusul
uriaș cu rădăcini argintii peste ziduri; perdele de liane verzi; ferigi.

**Din brief:** drumul principal ocolește incinta pe ~150 m (arc larg, rapid);
perdeaua de liane la 0,70 (există, `VineCurtain`); scurtătura prin galeria
prăbușită (există: bolți, dominoul, rampa-rădăcină, poarta-copac). Kitul:
`kit/vault_intact`, `vault_broken`, `gallery_*`, `props/rubble_pile`,
`fallen_block`, `laterite_block`, `numbered_block`, `restoration_prop`,
`plants/strangler_fig`, `vine_strands`, `structures/ta_prohm_tree_gate`.

**Capcana:**
- **scurtătura**: coridorul are deja 3 ejectări de bază (0,676–0,732, pereți solizi):
  nimic cu corp nou în coridor sau la ieșirea peste rădăcină; dominoul și rampa
  nu se mută;
- perdeaua (fără coliziune) trebuie să rămână „zid verde” la 40–60 m: nu pune
  ruine solide în fața ei pe bandă;
- ruinele de lângă drumul principal: arc rapid, mașinile ies larg — corp la ≥ 4 m
  de margine, ProbeRace citit pe 0,65–0,76.

**Deciziile dezvoltatorului după valul 1 (6 nov 2026):**
- **Copacii: acceptați deocamdată, datorie** (ca fețele sculptate). Forma asset-urilor de
  junglă (trunchi gol înalt, coroană plată sus) rămâne; criticii care o numesc se filtrează
  ca globali. De revenit cu un val de asset-uri (copaci cu coroană joasă, lată, în etaje).
- **Cerul și lumina: gradient de cer pe azimut + soare mai cald** (piersică spre soare,
  violet de furtună spre est), opt-in pe temă, hash neutru pe celelalte piste — S, runda 3.
