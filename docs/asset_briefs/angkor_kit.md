# Brief assets — Angkor (`Track24`, temă `angkor`) — kit v1

**Contractul complet pentru setul de assets (Blender).** E făcut pe tiparul
`carrara_kit.md`. Regulile generale sunt în `docs/blender_export.md` și
`docs/style_bible.md` §4. Brief-ul pistei e `docs/track_briefs/angkor.md`:
- §0.1 regula de artă și §8 respectul pentru loc (**nicio statuie de Buddha**,
  nicio referință la filme, niciun nume de producător);
- §3 hazardele și consumatorii lor, §5.7 trecerea de contracte, iar §7 pasul 1
  ce a corectat ea;
- §4 paleta (**niciun slot nou**) și lumina;
- §7 pașii 0–6, cu cotele reale ale pistei;
- §9 prompturile ChatGPT, §9.3 rezultatul planșei.

**Fidelitatea față de planșă e criteriu de acceptare, nu inspirație.** Fiecare
desen are propria decupare și se livrează cu o comparație alăturată
(decupare | randare din GLB, aceeași vedere 3/4).

| fișier | ce e | ce iei din el |
|---|---|---|
| `docs/track_briefs/img/angkor_assets_v1/<nume>.png` | **decuparea piesei**, mărită 2×, una pentru fiecare dintre cele 44 de desene (plus `_scale_car`). Le face `tools/blender/crop_angkor_sheet.py`; montajul de control e `_control.png`, cu sursa fiecărei decupări între paranteze | **referința de lucru a piesei:** silueta, numărul de elemente, proporțiile interne, culorile. `_scale_car` e mașinuța de scară, nu se modelează |
| `docs/track_briefs/img/angkor_plan/inventar_v01_b.jpg` | **planșa acceptată**, baza | ansamblul, materialul pictat (lichen, dâre, uzură). **NU dimensiuni** |
| `docs/track_briefs/img/angkor_plan/inventar_v01_c.jpg` | corectura: turnurile Bayonului, uriașii, Regele Lepros, Angkor Wat | **suprascrie** planșa b pentru aceste 7 piese |
| `docs/track_briefs/img/angkor_plan/inventar_v01_a.jpg` | prima generare | **doar `tuk_tuk`** (remorca separată de motocicletă) |
| `docs/track_briefs/img/angkor_diorama_v03.jpg` | diorama acceptată | atmosfera, lumina de furtună, cum stau piesele împreună. Nu cotele (abaterile ei sunt în brief §9.1) |
| `docs/track_briefs/img/angkor_plan_adnotat.png` | planul real al pistei | unde stă fiecare piesă; nu îl folosești la modelare |

**Corecturi decise de coordonator (suprascriu planșa):**
- **Turnurile Bayonului sunt TURNURI, nu capete** (planșa c): bază în trepte,
  fețele doar în **treimea din mijloc**, etaje care se îngustează deasupra,
  vârf de boboc. Pe planșa b ies busturi cu coroană — exact ce critic orb n-a
  citit ca „față” la mostră (brief §7 pasul 0);
- **Angkor Wat n-are fețe** (planșa b le-a pus pe turnurile templului):
  fețele sunt ale Bayonului și ale Porții de Sud;
- **uriașii țin trupul naga în brațe** (planșa c), nu stau în meditație; la
  fel, **Regele Lepros** stă cu un genunchi ridicat, fără coroană (planșa c).
  Orice poză cu picioarele încrucișate pe soclu-lotus citește Buddha (brief §8);
- **elefantul n-are șa, n-are călăreț**, urechi mici, cap cu două boltiri
  (planșa b); scheletul e al elefantului din Serengeti (§1.3);
- **tuk-tuk-ul e o remorcă trasă de motocicletă** (planșa a), nu ricșa cu
  trei roți din planșa b;
- **fără vegetație lipită pe structuri**, cu două excepții care SUNT piesa:
  `ta_prohm_tree_gate` și `strangler_fig` (ficusul face parte din formă).
  Mușchiul și lichenul sunt pete de culoare (noduri subțiri), nu masă;
- **nimic alb, nicio cifră** în afară de cifra de pe `numbered_block`;
- **cotele vin din tabelele de mai jos**, NU din planșă: pe planșă poarta-copac
  e cât templul, iar călugărul e cât turnul Bayonului.

## 0. Regulile care nu se negociază

1. **Categoria** e
   `assets/models/angkor/{structures,kit,props,animals,vehicles,plants,effects}/`.
   `dio_lib.export_glb` primește calea cu categorie
   (`"angkor/structures/bayon_face_tower_a.glb"`).
2. **Asset nou = fișier nou.** Nimic nu se suprascrie în alte categorii;
   ce se refolosește (§1.8) rămâne unde e.
3. **Setul de piese nu atinge `scenes/`, `scripts/` și `tools/gen_angkor_route.py`.**
   Coordonatorul se ocupă de: intrările de clase/sloturi (`world_prop.gd`),
   cheile elefantului (`SPLIT_MODELS`, `SLOT_REMAP_BY_MODEL`,
   `WALK_CYCLE_SPEED_BY_MODEL`), `@export var model` pe `RimBoulderHazard`,
   șuvițele în `VineCurtain`, scoaterea machetelor (`Machete/*`,
   `BayonTurn*/Macheta`), `CameraZone`-urile cu `ceiling` explicit și montarea
   în `Track24.tscn` (prin generator). Aici se livrează: GLB, build script,
   preview, verify, inventar și comparații.
4. **Paletă: zero sloturi noi.** UV1 colapsat pe centrele sloturilor, AO copt
   în vertex colors, origine la bază (excepțiile sunt în tabele), scară
   metrică, **scala aplicată pe fiecare nod rădăcină** (memoria
   `scala-glb-neaplicata-la-radacina`). „Înainte” e −Z în Godot = **+Y în
   Blender**; „dreapta” e +X în ambele. Fața bogată stă pe +Y și se
   **măsoară** pe GLB.
5. **Gresia primește clasa `angkor_sandstone`** (deja pe main: dala
   `alpine_granite`, tentă (1,0, 0,86, 0,66), scară 0,28) pe nodurile
   `*_Stone`. Clasa triplanară șterge sloturile de pe corp, deci **lichenul și
   dârele sunt noduri copil separate** (memoriile `clase-pe-piese-de-kit`,
   `benzi-vertex-color-bisect`): `*_Lichen` (pete mici pe orizontale, pe
   pervazuri și pe vârfuri), `*_Streak` (dâre negre pe jumătatea de sus a
   fețelor verticale, sub cornișe). **Offsetul de origine se calculează o dată
   pe ansamblu**; verificarea e `verify_glb.py --origin=assembly`.
6. **Sculptura e geometrie, nu normal map** (memoria
   `normal-map-nu-da-silueta`). Fețele Bayonului și ale porții, elefanții în
   relief, apsarele, capetele naga: **relief de cel puțin 12–15 cm** la nas,
   sprâncene și buze, ca să facă umbră sub soarele de 24°. Regula: „se vede ca
   formă la 30 m din mașină, sub camera de joc (10 m sus, 12,5 m spate,
   fov 68)?” (memoria `verifica-cu-parametrii-lui`). Ce NU e geometrie:
   granulația gresiei (o dă clasa), porii fini ai lateritei, nervurile
   frunzelor.
7. **Fără texturi proprii.** Frunzele sunt mase de geometrie pe atlas (ca la
   copacii existenți), nu planuri cu alpha.
8. **Primitive rotunde: setează `segments`** (6–12; 12–16 pe arcuri și pe
   bobocul turnurilor).
9. **Verificarea e din fișier, nu din memorie:** `verify_glb.py` pe fiecare
   GLB; `preview_angkor.py` randează **din GLB-urile exportate**; verdictul
   setului e `bash tools/blender/verify_angkor.sh` → `VERDICT KIT: OK` **și**
   comparațiile de fidelitate aprobate. `verify` verde nu e livrare (memoria
   `harnasul-de-kit-nu-vede-forma-nici-culoarea`).
10. **Randările rulează pe GPU.** Înainte de orice randare cu fereastră:
    `mkdir D:/GameDev/.render_lock`; dacă eșuează, aștepți. `rmdir` imediat
    după.

### Sloturi pe roluri

Doar sloturi existente (`scripts/palette.gd`). Culoarea finală a gresiei o dă
clasa, nu slotul.

| rol | slot (în GLB) | clasă la integrare |
|---|---|---|
| gresia (temple, porți, turnuri, kit, statui) | **`ROCK_LIGHT` 3** pe `*_Stone` | `angkor_sandstone` |
| lichenul portocaliu (pete mici, orizontale) | `LAVA_ORANGE` 30, nod `*_Lichen`, **sub 3% din aria piesei** | — |
| lichenul și mușchiul verde-gălbui | `CACTUS_GREEN` 12, nod `*_Lichen` (sau `*_Moss` dacă piesa le are pe amândouă) | — |
| dârele negre sub cornișe | **`VOLCANIC_BLACK` 20**, nod `*_Streak`. **Nu `ROCK_DARK` 4** (iese rugină, memoria `rock-dark-nu-pe-bazalt`) | — |
| laterita (blocuri, ziduri de incintă, debarcaderul) | `LARCH_RUST` 27, nod `*_Laterite`; porii sunt AO, plus câteva cavități mari în geometrie | — |
| cărămida (turnuleț-altar Bakheng, soclul debarcaderului) | `TILE_TERRACOTTA` 23, nod `*_Brick` | `roof_tiles` (de confirmat la integrare) |
| trunchiurile și rădăcinile argintii (tetrameles, ficus, poarta-copac, rădăcina-rampă) | **`CORAL_SAND` 19** cu AO cald, nod `*_Root` / `*_Trunk` | — |
| coronamentul | `TROPICAL_GREEN` 21, umbrit spre interior | — |
| palmierul de zahăr | trunchi `WOOD_WEATHERED` 9, evantaie `CACTUS_GREEN` 12 + `TROPICAL_GREEN` 21 | — |
| lianele | `TROPICAL_GREEN` 21; rădăcinile aeriene `CORAL_SAND` 19 | — |
| lotușii / nuferii | flori `FLAMINGO_PINK` 31, frunze `CACTUS_GREEN` 12 + `TROPICAL_GREEN` 21 | — |
| elefantul | **sloturile elefantului din Serengeti** (2 și 29 pe piele; fildeșii pe accent) | `elephant_hide` prin ruptura de accente (§1.3) |
| roba călugărului | `LAVA_ORANGE` 30 (accent; piesa e mică) | — |
| tuk-tuk-ul: vopseaua stinsă | `PAINTED_METAL` 11; acoperișul `TILE_TERRACOTTA` 23; scaunele și podeaua `WOOD_WEATHERED` 9; roți, șa, ghidon `VOLCANIC_BLACK` 20 | — |
| lemnul restauratorilor | `WOOD_WEATHERED` 9, umbrit `LOG_DARK` 28 | — |
| cifra de pe `numbered_block` | `CORAL_SAND` 19, nod `*_Paint` (singurul marcaj permis) | — |
| fundalul | coronament `TROPICAL_GREEN` 21, creasta `CACTUS_GREEN` 12 + ceață, norii `VOLCANIC_BLACK` 20 / `MARBLE_GREY` 29, orezăriile `CACTUS_GREEN` 12 + apă `REEF_SHALLOW` 17 | — |

> **Interzise pe tot kitul:** `CAR_RED`/`CAR_BLUE`/`CAR_YELLOW` (14–16, ale
> mașinilor de joc; tuk-tuk-ul roșu de pe planșă devine `PAINTED_METAL`),
> `FOAM_WHITE` 22, `ROCK_DARK` 4 pe gresie. **`ROCK_LIGHT` fără clasă iese
> portocaliu** pe atlas (pasul 6, balustradele): de aceea gresia e mereu pe
> `*_Stone`, ca să primească `angkor_sandstone`.

Pista e **diurnă**, cu ploaie; nu se cer noduri `*_Glow`.

## 1. Inventar și contracte

Convenții:
- dimensiunile sunt în metri, **în joc**;
- `h/l` = înălțimea / lățimea siluetei pe decupare, verificată în comparație cu
  ±15%;
- triunghiurile se **raportează, fără plafon** (CLAUDE.md). Contează
  **materialele** (un nod = un material); garda pistei e de max 38, estimarea
  brief-ului ~24;
- **modulele înlănțuibile** au capete identice, plane, la ±L/2 pe Y;
- **golurile prin care trec mașini se măsoară ca GOL**: proiecție pe plan, pe
  gabaritul caroseriei (memoriile `cota-de-contract-se-masoara-ca-gol`,
  `golul-se-masoara-pe-fereastra-lui`); porțile primesc `coliziune="mesh"`
  (brief §7 pasul 1: carcasa convexă implicită astupă deschiderea).

**Drumul, din `tools/gen_angkor_route.py`**: **9 m** în general (A, D, F, G,
H), **8 m** prin templu (B), **7 m** pe Bakheng (C), **14 m** pe terasa
Bayonului (E), **7 m** în Poarta de Sud (pâlnie), **6 m** pe scurtătura prin
galerie. Cote: calea de vest +3, cetatea pe dâm (poarta +14, Bayon +20, coama
terasei +18, piața regală +14), Bakheng +31.

**Scara e decizie, nu defect** (brief §2.0): turnurile Angkor Wat au 32 m,
nu 65, ca să încapă în cadru de pe grilă.

### 1.1 Turnurile Bayonului — **pilotul** (`build_angkor_bayon.py`)

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `structures/bayon_face_tower_a.glb` **(pilot)** | amprenta **3,0 × 3,0 m** (±0,1, toleranța în **interior**: nimic nu iese din pătrat), înălțimea **9,0 m** de la origine | ~2,5 | **Consumator:** `Obstacole/BayonTurn0..2` din generator: un `StaticBody3D` cu cutia **3 × 9 × 3 m**, cu baza **îngropată 1 m** sub terasă (se văd ~8 m). Modelul înlocuiește `Macheta` și **umple cutia**: o cornișă care iese din pătrat trece prin mașini fără să le atingă, un pătrat mai mic lasă un zid invizibil. Forma (planșa c): bază în 2–3 trepte (0–2,5 m), **fețele în treimea din mijloc** (~3–6 m), câte una pe fiecare latură, **~2,2 m** de la frunte la bărbie, ochi închiși, zâmbet; deasupra, 3–4 etaje care se îngustează, vârf de boboc de lotus. Fețele sunt pe ±X și ±Y. Noduri: `Bayon_Stone`, `Bayon_Lichen`, `Bayon_Streak`. **Corectura coordonatorului după runda 3: fața ~3,0 m (nu 2,2), în ~3,0–6,5 m, fără nișă/pilaștri, blocul fețelor = lățimea turnului** |
| `structures/bayon_face_tower_b.glb` | ca `a` | ~2,5 | alt număr de etaje (`a` 4, `b` 3) și alt boboc, aceleași fețe; pe drum stau unul lângă altul la 33 m, deci diferența se vede din mers |
| `structures/bayon_face_tower_c.glb` | ca `a`; molozul **în amprentă** | ~2,3 | **parțial ruinat**: un colț de sus prăbușit, o nișă spartă în bază, blocuri căzute **lipite de bază, în interiorul pătratului de 3 m** (pe un drum de 14 m, un bloc în afara cutiei ar fi un obstacol fără coliziune). Turnurile **nu se sparg** în joc (brief §8): ruina e formă, nu stare |

**Datorie deschisă — fețele sculptate.** Fețele turnurilor sunt **simplificate prin
decizia dezvoltatorului (6 nov 2026)**, după cinci runde de fețe construite din
cod (mască într-un cadru → Moai → clovn → ochelari/desen animat): acum sunt
câteva forme mari și puțin adânci (sprâncene, ochi-semilună, nas pană scurtă,
un zâmbet), fără pretenția unui portret. Ele cer **sculptură reală, mai târziu**:
image-to-3D pornind de la decupare, modele CC-BY/CC0 sau modelare manuală. **Aceeași
decizie se aplică celorlalte piese sculptate, când le vine valul:** fețele de la
`south_gate_face_tower`, `deva_giant`/`asura_giant`, `leper_king_statue`,
`naga_head` și reliefurile de elefanți (`elephant_terrace_*`). Nu se mai încearcă
fețe „din primitive” pe ele; se livrează forme simple lizibile, iar sculptura
rămâne în lista de datorii.

Verificare specifică: critic orb pe capturi `--gamecam` de pe terasa E, cu
întrebarea „ce vezi pe turn?”. Contractul e „față” / „chip” / „Buddha-face”
(oricare) la ≥ 2 din 3 capturi. La mostră, cutiile au primit 0 din 10.

### 1.2 Porțile și templul — `build_angkor_gates.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `structures/south_gate_face_tower.glb` | lățime **~19 m** (X), adâncime **~8 m** (Y), vârful **17–19 m** (corectura coordonatorului, runda 4: vârful 17–19 m); **golul la nivelul drumului ≥ 7,2 m** lățime (măsurat ca gol, la 0–2,5 m înălțime; banda e 7,0), înălțimea liberă **≥ 8 m** | ~1,1 | turnul cu **patru fețe** (câte una pe fiecare latură) peste o **singură** deschidere îngustă, cu arc în trepte; elefanți în relief cu trompele până la pământ pe ambele aripi, **pe fața exterioară, nu în gol**. Originea: baza, la mijlocul golului; drumul trece pe Y. Machetele `Poarta_*` arată anvelopa. `coliziune="mesh"`. **`CameraZone` cu `ceiling` = înălțimea liberă**, declarată de coordonator. Elefantul (§1.3) trebuie să se vadă **încadrat de gol** de la capătul căii (pasul 4) |
| `structures/aw_west_gopura.glb` | lungime **50–70 m** (X, de-a curmezișul drumului), adâncime ~10 m, turnul central **14–16 m**; **golul central ≥ 10,0 m** (drum de 9 m), înălțime liberă **≥ 8 m** | ~0,25 | galerie lungă cu trei turnuri, colonade pe ambele părți ale trecerii centrale. Drumul trece prin mijloc, pe Y. `coliziune="mesh"`, `CameraZone` cu tavan. Fără vegetație lipită |
| `structures/ta_prohm_tree_gate.glb` | ~14 m lățime, 7–9 m până la ramura cea mai înaltă (copacul întreg 18–22 m); **golul ≥ 6,6 m** (ramura are 6 m), înălțime liberă **≥ 5,5 m**, **nicio rădăcină în gol sub 5,5 m** | ~1,0 | turnul-poartă mic strâns de un ficus uriaș: rădăcinile argintii se revarsă **peste acoperiș și pe laturi**, nu prin trecere. Intrarea scurtăturii cu dominoul (`TrackBranch` în G). Noduri: `Gate_Stone`, `Gate_Lichen`, `Gate_Root` (`CORAL_SAND`), `Gate_Canopy` (`TROPICAL_GREEN`). `coliziune="mesh"` |
| `structures/angkor_wat_temple.glb` | **în anvelopa machetelor `Machete/AW_*`** din `Track24.tscn`: soclul **64 × 64 m** în trepte până la +8, al doilea soclu 44 × 44; turnul central **la ±0, vârful la +36**; turnurile de colț în **(±17, ±17)**, vârful **la +30** (cotele sunt față de baza modelului) | ~0,55 | **planșa c**: cinci turnuri-boboc **în quincunx** (nu pe un rând: de pe grilă se văd cinci, cu centralul în spate), terasele în trepte cu galerii și colonade, scara axială spre vest (+Y). **Fără fețe.** Verificarea din brief §2.0 (turnurile întregi în cadru de pe grilă, dezvăluirea de pe Bakheng) s-a făcut pe machete, deci vârfurile **nu urcă**. E fundal: coliziune doar pe soclu; LOD obligatoriu |

### 1.3 Elefantul asiatic — `build_angkor_elephant.py`

| fișier | cote | contract |
|---|---|---|
| `animals/asian_elephant.glb` | **2,8–3,0 m** la umăr, **5,4–5,8 m** lung (cu trompa); elefantul din Serengeti are 3,4 / 6,4 m | **Același schelet ca `serengeti/animals/elephant.glb`**: 11 oase (`Body`, `Head`, `Trunk1/2`, `EarL/R`, `LegFL/FR/RL/RR`, `Tail`), acțiunile **`Walk`** (1,5 s) și **`Trumpet`**. `StrideDriver` conduce picioarele și `Body` după nume; clipul păstrează trompa, urechile, coada. Mesh-ul se cheamă **`Elephant_Mesh`** (toată mecanica de ruptură și clasa `elephant_hide` e legată de nume). Forma (planșa b): urechi **mici și rotunjite**, cap cu **două boltiri**, spatele cel mai înalt **la mijloc**, fildeși scurți sau lipsă, **fără șa și fără călăreț**. Greutățile pe vertex cu **fereastră pe Y**, nu prag pe X (memoria `elefant-mesh-importat-rig-per-vertex`: piciorul din față rupt de trompă la `Trumpet`). **La integrare** (coordonatorul): cheia `asian_elephant` în `SPLIT_MODELS`, `SLOT_REMAP_BY_MODEL`, `WALK_CYCLE_SPEED_BY_MODEL` (ritmul se măsoară cu `tools/probe_foot_slide.gd`), apoi ProbeRace pe `[blocaj]` în piață (pasul 5: 6–8 s oprite pe seed) |

### 1.4 Terasa, Regele Lepros, rădăcina, debarcaderul — `build_angkor_terrace.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `kit/elephant_terrace_module.glb` | **L = 8,0 m** (Y), înălțime **4,0 m** (fața de vest a terasei, piața +14 → coama +18), grosime ≤ 1,5 m | ~0,5 | zid cu procesiune de elefanți în relief (2–3 pe modul), cornișă sus. **NU e suprafață de rulare** (brief §7 pasul 1): carosabilul e panglica din spline, deci **nimic peste cota 4,0** (coama e la nivelul drumului). Fața sculptată pe +X (spre piață, la integrare se rotește). Capete plane, înlănțuibile |
| `kit/elephant_terrace_end.glb` | ca modulul, cu capătul de nord: L 6–8 m | ~0,5 | capătul terasei, cu **muchia vie** de la care se sare (creasta e profilul traseului: `CREST_PROFILE`, cădere de 4,4 m pe 12 m). Pe planșă e identic cu modulul: diferența e capătul întors și treptele laterale |
| `kit/elephant_trunk_pillar.glb` | 4,0 m înălțime, ~1,6 × 1,6 m | ~2,5 | stâlp-cap de elefant cu trompa în jos, se intercalează între module |
| `props/leper_king_statue.glb` | statuia **~2,4 m** șezând, soclul ~1,2 m (total ~3,6) | ~1,1 | **planșa c**: un genunchi ridicat, o mână pe genunchi, păr simplu, **fără coroană, fără aureolă**. Pe marginea coamei, **în afara benzii**; coliziune pe soclu |
| `structures/giant_root_ramp.glb` | lățime **≥ 7,0 m** (ramura are 6), înălțime **1,2 m**, lungime **6–8 m** | ~0,25 | rădăcina uriașă de la ieșirea scurtăturii, prin spărtura zidului. **Suprafața de rulare e un plan înclinat unic** (≤ 20%), fără praguri: rădăcinile mici și nodurile stau **pe laterale și dedesubt**, nu pe pantă (memoriile `suprafete-cu-goluri-si-praguri`: >0,3 m lateral e zid; `suprafete-din-placi-plane`). Coliziunea e `world_prop` pe mesh; aterizarea trebuie să cadă **pe banda principală** (sonda o verifică la integrare). `Root_Ramp` (`CORAL_SAND`) |
| `structures/srah_srang_landing.glb` | ~14 × 8 m, trepte care coboară **1,5 m** până sub cota apei | ~0,35 | debarcaderul de laterită pe stânga lui H: platformă, trepte spre apă, doi lei de gresie, capete naga. Originea la cota platformei (+0,5 deasupra apei la integrare). Decor, coliziune pe platformă |

### 1.5 Kitul modular — `build_angkor_kit.py`

| fișier | cote | contract |
|---|---|---|
| `kit/gallery_column.glb` | 3,5 m, secțiune 0,5 × 0,5 m | stâlp pătrat cu bază și capitel în trepte |
| `kit/gallery_roof.glb` | **L 4,0 m**, lățime 4,0 m, coama la ~2 m peste baza acoperișului | acoperiș în consolă cu țigle curbe de piatră; se așază pe stâlpi (pasul stâlpilor 4,0 m) |
| `kit/gallery_relief_wall.glb` | **L 4,0 m**, h 3,5 m, grosime 0,6 m | basorelief continuu (apsare / procesiune) pe +Y; relieful ≥ 6 cm (se vede doar la lumina joasă) |
| `kit/gallery_corner.glb` | 4,0 × 4,0 m | colțul galeriei, se îmbină cu modulele la ±2 m |
| `kit/naga_balustrade.glb` | **L 4,0 m**, înălțime **1,0 m**, grosime **≤ 0,6 m** | trupul șarpelui pe stâlpi scurți. **Se potrivește cu balustrada din cod** (stilul 3 din `Track._build_parapets`: zid de 1,0 m, gros 0,5 m, cu coliziunea lui): modulul e îmbrăcămintea vizuală a acelui zid, deci nu iese din el cu mai mult de 0,05 m |
| `kit/naga_balustrade_gap.glb` | L 4,0 m, aceeași secțiune | același modul, rupt, cu bucăți căzute **pe partea dinspre șanț** (golurile din balustradă sunt goluri de joc, pasul 6: ~7 m) |
| `kit/naga_head.glb` | ~2,5 m înălțime, 1,6 m lățime | capul ridicat cu șapte guri, în evantai; capătul balustradei, la intrarea pe cale. Vine **după** capătul desfăcut al balustradei din cod (`BALUSTRADE_FLARE_*`), nu pe el |
| `kit/deva_giant.glb`, `kit/asura_giant.glb` | ~3,0 m șezând, adâncime **≤ 1,6 m** | **planșa c**: șezând pe soclu jos, **ambele brațe în jurul trupului naga**, care trece prin poală și iese din amprentă pe ambele părți la **aceeași secțiune și înălțime cu `naga_balustrade`**, ca rândul să se lege. Deva calm, cu coroană conică; asura cu ochi bulbucați, colți, încruntat. **Se pun în MultiMesh (27 + 27)**: un singur mesh per material, fără ierarhie |
| `kit/bakheng_terrace_tier.glb` | **L 8,0 m**, h 1,5 m | un etaj de terasă în trepte, pe flancul dealului (decor, nu carosabil) |
| `kit/bakheng_shrine_tower.glb` | ~4 m, amprenta 2,5 × 2,5 m | turnuleț-altar de cărămidă (`*_Brick`), cu ușă oarbă |
| `kit/bakheng_side_stair.glb` | h 3,0 m, lățime 2,0 m | scară abruptă și îngustă; **decor lateral, niciodată pe carosabil** (brief §8) |
| `kit/vault_intact.glb` | **L 4,0 m**; **golul interior ≥ 6,6 m** lățime, cheia la **≥ 6,5 m** | bolta în consolă (trepte de piatră, nu arc roman) peste scurtătura de 6 m. Coliziune pe pereți. Cu `CameraZone` și tavanul declarat |
| `kit/vault_broken.glb` | ca `vault_intact` | aceeași boltă prăbușită: **acoperișul deschis** (blocurile dominoului cad prin el de la 6 m, la 2 m de axă), moloz **pe margini, nu pe bandă** |
| `props/fallen_block.glb` | **anvelopa bolovanului de acum**: AABB-ul `rocks/boulder_roller.glb` × 0,5 (se măsoară în pilot), amprentă aproape pătrată | blocul sculptat care cade în dominou. **Consumator:** `RimBoulderHazard` cu `@export var model` (cod mic, coordonatorul; azi e `DEFAULT_MODEL`): codul centrează modelul și pune clasa temei `rockfall_class` = `angkor_sandstone`. Un bloc mai mare schimbă strivirile (11,5% → ?) și cere ProbeRace |
| `props/restoration_prop.glb` | ~3 m | sprijin de lemn al restauratorilor care ține un perete înclinat |
| `props/laterite_block.glb`, `props/rubble_pile.glb` | 0,6–1,2 m / ~2 m | laterita roșie poroasă; moloz de gresie (fațete mari) |
| `props/numbered_block.glb` | ~0,8 m | bloc cu **o cifră** pictată (`*_Paint`), restaurarea anastilozei; singurul marcaj din kit |

### 1.6 Viață — `build_angkor_life.py`

| fișier | cote | contract |
|---|---|---|
| `vehicles/tuk_tuk.glb` | **două noduri-rădăcină**: `Moto` (~1,9 × 0,7 m) și `Remorca` (**≤ 2,0 m** pe latura lungă în plan, ~1,4 m lat, ~2,0 m înalt cu acoperișul) | **planșa a**: motocicletă care trage o remorcă acoperită cu bănci. Două rădăcini fiindcă `BumpProp` primește piese de **cel mult 2 m** în plan (brief §7 pasul 6, amânat): integrarea poate face fiecare piesă împingabilă cu masa ei, sau ansamblul colizor static. Vopsea stinsă, **fără mărci, fără numere** |
| `animals/monk_standing.glb` | **1,7 m** | călugăr în robă șofran, în picioare. Fundal, departe de bandă (brief §8). Static |

Macacii se refolosesc (`halong/animals/macaque.glb`, §1.8).

### 1.7 Vegetația — `build_angkor_plants.py`

Piesele merg în MultiMesh feliat (memoria `decor-in-masa-cere-multimesh`),
deci **un mesh per material, fără ierarhie adâncă**, LOD-uri generate. Riscul
GPU al pistei e frunzișul (brief §6): frunzele sunt mase de geometrie pe
atlas, nu plăci cu alpha.

| fișier | cote | contract |
|---|---|---|
| `plants/tetrameles_a.glb`, `_b.glb` | **22–28 m**; contraforturile **3–4 m** înălțime, întinse pe 8–10 m | trunchi drept, pal-argintiu, rădăcini-contrafort ca niște aripi; coroană lată și plată sus. `a` și `b` diferă la contraforturi și la coroană. Ele spun „Ta Prohm”, nu banyanul (brief §7 pasul 0) |
| `plants/strangler_fig.glb` | ~10 m, zidul inclus ~5 m | ficus ale cărui rădăcini **înfășoară un zid de gresie** (zidul e parte din piesă: `Fig_Stone` primește clasa). Decor pe marginea scurtăturii și în B |
| `plants/sugar_palm.glb` | **12–16 m** | Borassus: trunchi drept și gol, coroană **sferică** de evantaie. Silueta Cambodgiei pe orezării (fundalul de vest) și pe digurile de lângă șanț |
| `plants/dipterocarp.glb` | **30–38 m** | copac de coronament, foarte înalt, trunchi lung fără ramuri, coroană în nori. Marea de junglă văzută de pe Bakheng |
| `plants/vine_strands.glb` | 4–6 noduri-rădăcină `Strand_*`, fiecare **3,0–4,5 m** lung, ~0,3 m lat | șuvițe de liane (verzi) și rădăcini aeriene (argintii), **originea în punctul de agățare (sus)**, atârnând pe −Z Blender. **Consumator:** `VineCurtain` (cod, pasul 6) le va pune în MultiMesh în locul panglicilor de acum, cu legănare în shader: perdeaua de la **5,0 m** cu vârfurile la **0,7–2,3 m** peste asfalt, 4 rânduri. Contractul perdelei: **≥ 60% din lățimea benzii acoperită la 40 m** (se remăsoară cu șuvițele livrate) |
| `plants/lotus_cluster.glb`, `plants/water_lily_pads.glb` | 1,5–3 m în plan, **≤ 0,4 m** peste apă (nuferii ≤ 0,05) | originea la **cota apei**; frunzele plate, florile `FLAMINGO_PINK`. Pe șanțuri și în Srah Srang |

### 1.8 Fundalul — `build_angkor_horizon.py`

`effects/angkor_horizon.glb`, cu noduri copii directe ale rădăcinii, **volume
închise, lizibile din orice azimut, cu originea la bază**. Consumatorul e
`Track._build_horizon`, prin `horizon_model` în tema `angkor` (azi gol).
`fog_end` e **280 m**, deci inelul stă la **200–260 m**.

| nod | cote | contract |
|---|---|---|
| `Canopy_A/B/C` | 150–250 m lungime, 20–35 m înălțime | marea de coronament: mase rotunjite, vârfuri de dipterocarp care ies din ea |
| `KulenRidge` | ~300 m, 30–45 m | creasta joasă și plată spre **nord-est** (Phnom Kulen) |
| `StormBand_A/B` | 200–300 m lungime, baza la 40–60 m | **banda de nori de furtună spre est**, ca geometrie (brief §7 pasul 0: fără ea, cerul violet citea „amurg”, nu „furtună”). Gri-violet închis, cu baza plată și vârfuri de turn |
| `Paddies_W` | ~250 m | orezării cu diguri și palmieri de zahăr spre **vest** |

Fără coliziune, `cast_shadow` OFF la integrare (memoria
`caster-departat-fura-umbra`).

### 1.9 Ce NU se generează (refolosit sau făcut de cod)

| reper | ce se folosește | de ce |
|---|---|---|
| macacii | `halong/animals/macaque.glb` (`FlockProp` pe balustrade) | brief §5.3 |
| banyanul, ferigile, bambusul, tufele tropicale | `trees/banyan.glb`, `plants/fern_cluster.glb`, `halong/plants/bamboo_clump.glb`, `plants/tropical_shrub.glb` | brief §5.4 |
| drumul de laterită, căile de gresie, șanțurile, apa | cod (`custom_dirt_ranges`, `custom_ravines`, `custom_ravine_water`) | brief §5.1 |
| balustradele de coliziune | cod (stilul 3, pasul 6) | kitul naga e doar îmbrăcămintea lor (§1.5) |
| ploaia, fulgerul, frunzele perdelei | cod (`RainCycle`, `LightningFlash`, `PropDebris.leaf_burst`) | pasul 6 |
| tuk-tuk-ul cu trei roți din planșa b | — | corectura de sus |

## 2. Valuri

Trei constructori pe val, nu mai mulți (memoria `valuri-de-trei-nu-opt-agenti`),
în worktree-uri separate, integrați într-un worktree pe main (memoria
`orchestrare-agenti-worktree-frate`). Fiecare val se încheie cu
`VERDICT KIT: OK`, comparațiile aprobate de coordonator și o captură
`--gamecam` cu piesele montate (o captură nu e verdict: 5 eșantioane).

| val | piese | de ce în ordinea asta |
|---|---|---|
| **pilot** | harnasul (`angkor_shapes.py`, `preview_angkor.py`, `verify_angkor.sh`) + `bayon_face_tower_a` | consumator gata (`BayonTurn*`), contractul cel mai strict (cutia de 3 × 9 × 3) și testul de citire „față” |
| **1** | `bayon_face_tower_b/c`; `south_gate_face_tower`; `aw_west_gopura` + `ta_prohm_tree_gate`; `asian_elephant` | piesele prin care treci sau în care intri: deblochează `CameraZone`-urile amânate la pasul 6 și elefantul real |
| **2** | terasa (3 piese) + `leper_king_statue` + `giant_root_ramp`; bolțile + `fallen_block`; naga + uriașii | piesele-hazard și cele care se leagă de cod (balustrada, dominoul) |
| **3** | `angkor_wat_temple`; Bakheng (3); galeria (4); `srah_srang_landing`; tuk-tuk, călugăr, blocurile mici | fundalul mare și decorul |
| **4** | vegetația (8 fișiere) + `angkor_horizon` | ultimul: depinde de clasele piatră/rădăcină deja văzute în joc, iar `vine_strands` cere și codul `VineCurtain` |

După valul 4, brief §7 pasul 8: `probe_decor`, testul de loc repetat pe pista
reală, **verdict la volan** (al dezvoltatorului).
