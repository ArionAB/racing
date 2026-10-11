# Brief assets — Okinawa (`Track20`, temă `okinawa`) — kit v2

**Contractul complet pentru setul de assets (Blender).** Pe tiparul
`monumentvalley_kit.md`; regulile generale sunt în `docs/blender_export.md` și
`docs/style_bible.md` §4. Brief-ul pistei: `docs/track_briefs/okinawa.md`
(§0.1 regula de artă, §2.0 scara față de cameră, §4 paleta, §5 assets, §9
prompturile ChatGPT). Kitul vechi (`okinawa_kit.md`, Track08) **rămâne pe loc**:
Track08 îl folosește până la swap, iar o parte din piese trec în Track20 așa
cum sunt (§1.9).

**Fidelitatea față de planșă e criteriu de acceptare, nu inspirație** (§0.1
de mai jos). Fiecare desen are propria decupare și se livrează cu o
comparație alăturată.

| fișier | ce e | ce iei din el |
|---|---|---|
| `docs/track_briefs/img/okinawa_assets_v1/<nume>.png` | **decuparea piesei**, una pentru fiecare dintre cele 48 de desene, mărită 2× (`tools/blender/crop_okinawa_sheet.py`; montajul de control `_control.png`) | **referința de lucru a piesei:** silueta, numărul de elemente, proporțiile interne, culorile. Unele decupări au o fâșie din piesa vecină la margine (linie neagră la `gusuku_arch_gate` și `wave_crest`, nor la `ie_island`, eticheta „waterspout” la `kerama_islands`): ignor-o |
| `docs/track_briefs/img/okinawa_plan/inventar_v02.jpg` | planșa întreagă (10 rânduri) | ordinea și ansamblul. **NU dimensiuni:** feribotul e cât o casă, tetrapodul cât un copac |
| `docs/track_briefs/img/okinawa_plan/diorama_v02.jpg` | diorama acceptată | atmosfera, paleta în lumina de după-amiază, cum stau piesele împreună. **Nu stilul** (e pictată). Unde se contrazic, planșa câștigă, cu excepția corecturilor de mai jos |
| `docs/track_briefs/img/okinawa_plan/diorama_v02_iter1.jpg` | prima generare | nimic de modelat; păstrată pentru istoric (vezi brief §9.2) |
| `docs/track_briefs/img/okinawa_plan/okinawa_plan.png` | planul real al pistei | unde stă fiecare piesă; nu o folosești la modelare |

**Corecturi decise de coordonator (suprascriu planșa):**
- **`fukugi_tree_a/b/c` NU sunt foioase cu coroană rotundă.** Fukugi
  (*Garcinia subelliptica*) e un **stâlp dens de frunziș**: coroană îngustă și
  înaltă (h/l ≈ 2,2–2,8), frunzișul coboară până la ~0,8 m de sol, trunchiul
  se vede doar ca un ciot scurt, verde **închis** lucios. Pe planșă cele trei
  sunt aproape identice și prea deschise. E piesa care face tunelul din POI B:
  plantați la 3–4 m unul de altul, trebuie să dea un **perete**, nu un șir de
  bile. Cele trei variante diferă prin înălțime și zveltețe (§1.3);
- **casele Ryukyu au shisa pe coamă**, nu mânerul roșu din planșă: un leu
  mic (~0,6 m) de teracotă pe vârful acoperișului în patru ape. Olanele au
  **liniile albe de mortar în relief** (coame și rosturi ridicate), nu doar
  culoare. În fața ușii stă paravanul ***hinpun*** (zid scurt, liber, între
  poartă și ușă). Cele trei case diferă prin formă și mărime, nu doar prin
  flori (§1.5);
- **fără vegetație lipită pe clădiri, ziduri, stânci de coastă și far.**
  Tufele, palmierii și florile din jurul pieselor de pe planșă se pun separat
  la integrare (MultiMesh și `DecorManual`). Excepție: **iarba de pe creștetul
  stâncilor-ciupercă și al modulului de faleză**, care e reală și face parte
  din siluetă;
- **`coral_stone_wall` e din pietre rotunjite, poroase, neregulate**, nu din
  blocuri dreptunghiulare ca pe planșă;
- **`notch_rock_a/b/c` au proporții distincte** (una înaltă și zveltă, una lată
  și joasă, una aplecată spre mare). Pe planșă sunt aproape identice;
- **`ryukyu_gate` trece PESTE drum**: golul e contract de cod (§1.1), nu
  proporție de desen;
- **`coastal_freighter` e vas de coastă cu punte deschisă și catarg-radar**,
  nu portcontainer: 2–4 lăzi mici sau paleți pe punte, nu stive de
  containere;
- **fără text, cifre sau logo-uri** nicăieri: automatul e alb și gol,
  feribotul n-are nume, vasele n-au număr;
- **cotele vin din tabelele de mai jos**, NU din planșă.

## 0. Regulile care nu se negociază

1. **Categoria** e `assets/models/okinawa/{buildings,structures,rocks,plants,props,vehicles,animals,effects}/`.
   `dio_lib.export_glb` primește calea cu categorie
   (`"okinawa/structures/ryukyu_gate.glb"`).
2. **Asset nou = fișier nou.** Nu se suprascrie nimic din `structures/`,
   `trees/`, `buildings/`, `props/`, `vehicles/` (kitul vechi Okinawa e al lui
   Track08 până la swap) sau din alte categorii de piste.
3. **Setul de piese nu atinge `scenes/` și `scripts/`.** Clasele (`ok_limestone`,
   `ok_lacquer`), `PROP_COLLISION`, tema, `DecorManual`, `ship_model` și
   montarea în `Track20.tscn` sunt ale coordonatorului. Aici se livrează GLB +
   build script + preview + verify + inventar + comparații.
4. **Paletă: zero sloturi noi** (32 din 32 ocupate). UV1 colapsat pe centrele
   sloturilor, AO copt în vertex colors, origine la bază (excepțiile sunt în
   tabel), scară metrică, **scala aplicată pe fiecare nod rădăcină** (memoria
   `scala-glb-neaplicata-la-radacina`). „Înainte” e −Z în Godot = **+Y în
   Blender**; fața bogată a clădirilor stă pe +Y și se **măsoară** pe GLB, nu
   se presupune (memoria `fata-casei-nu-e-plus-z`).
5. **Sloturile pe roluri** (tabelul de mai jos). Culoarea finală a calcarului
   și a lacului roșu o dă clasa, nu slotul.
6. **Piesele care primesc clasă la integrare se sparg la export în noduri cu
   un singur material** (memoria `clase-pe-piese-de-kit`), cu sufixele din
   tabel (`*_Limestone`, `*_Roof`, `*_Plaster`, `*_Lacquer`, `*_Concrete`).
   **Offsetul de origine se calculează o dată pe ansamblu**; verificarea e
   `verify_glb.py --origin=assembly`.
7. **Ce NU e geometrie:** porii calcarului, petele, rosturile fine de zidărie
   vin din clasă. **Ce ESTE geometrie:** formele care schimbă silueta sau
   umbra: **nișa roasă de val la baza stâncilor-ciupercă** (*notch*, cea care
   face ciuperca), coamele de mortar de pe olane, **pietrele rotunde
   individuale** ale zidului de corali (rândurile de sus, care fac conturul),
   crenelurile și colțurile rotunjite ale zidului gusuku, streașina curbată a
   porții și a palatului. Regula: „se vede la 30 m din mașină ca formă?”.
8. **Calcarul Ryukyu se citește pe două tonuri:** suprafața palidă,
   gri-crem, și **nișele închise** (sub ciupercă, la baza falezei, sub
   streașina zidului). Nișa e geometrie plus AO, nu slot închis întins pe
   suprafață mare (memoria `rock-dark-nu-pe-bazalt`: `ROCK_DARK` pe calcar
   iese rugină).
9. **Fără text, fără cifre, fără logo-uri.**
10. **Primitive rotunde: setează `segments`** (6–12). Rezervorul de apă de pe
    acoperiș, felinarul farului, flotoarele, oglinda convexă, coloanele
    palatului: 8–12.
11. **Verificarea e din fișier, nu din memorie:** `verify_glb.py` pe fiecare
    GLB, iar `preview_okinawa.py` randează **din GLB-urile exportate**.
    Verdictul setului e `bash tools/blender/verify_okinawa_v2.sh` →
    `VERDICT KIT: OK` **și** comparațiile de fidelitate aprobate (§0.1).
    `verify` verde nu e livrare (memoria
    `harnasul-de-kit-nu-vede-forma-nici-culoarea`).
12. **Randările rulează pe GPU:** înainte de orice randare Blender/Godot cu
    fereastră, `mkdir D:/GameDev/.render_lock` (dacă eșuează, alt proces
    randează: așteaptă), `rmdir` imediat după.

### Sloturi pe roluri

Doar sloturi existente (`scripts/palette.gd`, constantele din `dio_lib.py`).
Hex-ul slotului e trecut ca să se vadă de ce s-a ales; ținta din brief §1 se
atinge cu clasa, la integrare.

| rol | slot (în GLB) | clasă la integrare (nu o faci tu) |
|---|---|---|
| calcarul Ryukyu (zidurile gusuku, stâncile-ciupercă, faleza, stânca-inimă, soclul palatului, farul de jos) | **`MARBLE_GREY` 29** (`#B8B4AC`), nișele `SAND_SHADOW` 2 în benzi înguste | `ok_limestone` pe `*_Limestone` |
| lacul roșu (porțile, palatul, stâlpii) | **`KERB_RED` 7** (`#BB3522`, cel mai aproape de `#B3261E`) | `ok_lacquer` pe `*_Lacquer`, dacă slotul iese „plastic” |
| ornamentele aurii (dragoni de coamă, capete de grindă) | `CAR_YELLOW` 16, puncte mici (`--allow-car-slots=*_Gold`) | — |
| olanele | `TILE_TERRACOTTA` 23 | `roof_tiles` pe `*_Roof` |
| mortarul de pe olane, coamele | `FOAM_WHITE` 22 | — |
| tencuiala albă (casele de beton, farul, cabina feribotului) | `FOAM_WHITE` 22 | `plaster` pe `*_Plaster` |
| tencuiala pastel a casei de beton b | `FLAMINGO_PINK` 31 | `plaster` pe `*_Plaster` |
| zidul de corali (pietre rotunde) | `CORAL_SAND` 19, rosturile `SAND_SHADOW` 2 | `coral_rock` pe `*_Coral` (clasa există, kitul vechi) |
| betonul (cheiul, digul, babalele, refugiul de autobuz, rezervoarele) | `CONCRETE` 8 | `concrete` pe `*_Concrete` |
| lemnul (uși, grinzi, canoe, suporturi de plase) | `WOOD` 9, umbrit `LOG_DARK` 28 | — |
| fukugi, banian, pin (coroane) | `TROPICAL_GREEN` 21 | tentă de întunecare la integrare (`#2E5A2C` e mai închis decât slotul) |
| cicadă, palmier-evantai | `CACTUS_GREEN` 12 + `TROPICAL_GREEN` 21 | — |
| trunchiuri | `WOOD` 9 / `LOG_DARK` 28 | `bark` pe `*_Bark` (clasa există) |
| hibiscus | `KERB_RED` 7 pe flori, `TROPICAL_GREEN` 21 | — |
| bougainvillea | `FLAMINGO_PINK` 31 pe flori, `TROPICAL_GREEN` 21 | — |
| oglinda convexă (rama și stâlpul) | `LAVA_ORANGE` 30 (doar albedo, **fără** clasa de lavă); oglinda `ICE_TURQUOISE` 24 | — |
| automatul | `FOAM_WHITE` 22, vitrina `VOLCANIC_BLACK` 20 | — |
| feribotul | suprastructura `FOAM_WHITE` 22, coca `CAR_BLUE` 15 (`--allow-car-slots=Ferry_Hull`), dunga `KERB_RED` 7, geamurile `VOLCANIC_BLACK` 20 | `plaster` pe `Ferry_Plaster` (opțional) |
| vasul de coastă | coca `KERB_RED` 7 / `CAR_BLUE` 15 (`--allow-car-slots=Freighter_Hull`), puntea `RUST` 10, cabina `FOAM_WHITE` 22 | — |
| barca de pescuit | `FOAM_WHITE` 22, dunga `CAR_BLUE` 15 (`--allow-car-slots=Boat_Stripe`) | — |
| plasele, flotoarele | `ICE_DEEP` 25 / `REEF_SHALLOW` 17 (plase), flotoarele `ICE_TURQUOISE` 24 + `SAND_LIGHT` 0 | — |
| bivolul | `LOG_DARK` 28, coarnele `MARBLE_GREY` 29 | — |
| stârcul | `FOAM_WHITE` 22, ciocul `CAR_YELLOW` 16 (`--allow-car-slots=Egret_Beak`), picioarele `VOLCANIC_BLACK` 20 | — |
| fundalul (insulele) | `TROPICAL_GREEN` 21, stânca `MARBLE_GREY` 29 | — |
| goluri (ferestre, uși, nișe adânci) | `VOLCANIC_BLACK` 20 | — |

> **Abatere de la brief §4, cu motiv:** brief-ul punea calcarul pe
> `ROCK_LIGHT` 3. Hexul lui e `#C18446`, adică gresie portocalie de deșert, iar
> ținta e `#CFC6B0` (gri-crem). Tenta clasei doar întunecă, deci din portocaliu
> nu se mai ajunge la crem (memoria `slot-ales-dupa-nume`). `MARBLE_GREY`
> (`#B8B4AC`) e la 15 unități de țintă; clasa `ok_limestone` aduce porii.

Pista e **diurnă, lumină fixă**: nu se cer noduri `*_Glow`. Excepție: lampa
farului (`Lighthouse_Lamp`, nod separat, `FOAM_WHITE`), ca integrarea să poată
decide un emisiv slab pe cerul de furtună.

## 1. Inventar și contracte

Dimensiuni în metri. `h/l` = înălțime/lățime a siluetei pe decupare (se
verifică în comparație, ±15%). Triunghiurile se **raportează, fără plafon**
(CLAUDE.md); contează **materialele** (un nod = un material). „Față” = +Y în
Blender = −Z în Godot. **Modulele înlănțuibile** au capete identice, plane, la
±L/2 pe Y. **Cotele de contract (goluri) se măsoară ca GOL** (proiecție pe
plan, memoria `cota-de-contract-se-masoara-ca-gol`).

**Scara e decizie, nu defect** (brief §2.0 și §8): sub o cameră la 10 m, un
obiect de la marginea drumului care trebuie **citit** cere ≥ 3–4 m, iar un
reper văzut de departe ≥ 15 m. Zidurile au 6–10 m, farul 20 m, palatul 16 m.

### 1.1 Castelul — `build_okinawa_castle.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `structures/ryukyu_gate.glb` **(pilot)** | ~**20 m** lat (X, peste drum), ~**11 m** înalt, ~5 m adânc; **golul ≥ 14 m lățime (±7,0 m) pe înălțimea caroseriei (2 m), înălțime liberă ≥ 6 m, măsurat ca GOL** | ~0,55 | poartă de tip Shureimon: **4 stâlpi roșii** pe fiecare parte, câte doi grupați, pe socluri de piatră; **acoperiș în două trepte** cu olane roșii și coame albe, streașini ușor curbate în sus la colțuri; panou orizontal sub acoperișul de sus (**gol, fără text**); 2 ornamente aurii pe coamă. Drumul (`custom_width_segments` 0,333–0,442) are **±6,0 m**; coliziunea `mesh` pe stâlpi, golul liber. Noduri `Gate_Lacquer`, `Gate_Roof`, `Gate_Limestone` (soclurile), `Gate_Gold`. **Asfaltul din decupare NU e în GLB** |
| `buildings/ryukyu_palace.glb` | **~32 × 18 m** amprentă, **16 m** la coamă, pe o platformă de piatră de **2,5 m** cu scară frontală | ~0,5 | sală lată pe două niveluri: pereți roșii cu **12–14 coloane** pe față, acoperiș mare în patru ape cu olane roșii și coame albe, **fronton curbat (karahafu)** deasupra intrării, 2 dragoni aurii pe capetele coamei. Platforma de calcar cu balustradă joasă, scara pe +Y. Noduri `Palace_Lacquer`, `Palace_Roof`, `Palace_Limestone`, `Palace_Gold`, `Palace_Wood` |
| `structures/gusuku_wall_curve.glb` | modul pe arc de **16 m** (coardă), **8 m** înalt, 2,5 m gros la bază, 1,6 m la creastă; două raze: `_A` R = 20 m, `_B` R = 40 m (două noduri-rădăcină în același GLB) | ~0,5 | zid de calcar **curb**, cu **colțuri rotunjite** și **ușor înclinat spre interior** (talus, ~8°), creastă rotunjită fără creneluri drepte, 3–4 benzi de asize vizibile ca formă. Capete plane, identice între module, ca să se înlănțuie pe orice rază. `Wall_Limestone` |
| `structures/gusuku_wall_straight.glb` | **12 m** lung (Y), **8 m** înalt, aceleași secțiuni | ~0,65 | modulul drept; capete identice cu cele ale celui curb. `Wall_Limestone` |
| `structures/gusuku_arch_gate.glb` | **14 m** lung, **8 m** înalt; bolta: **4 m** lată, **4,5 m** înaltă | ~0,55 | modul de zid cu **poartă boltită de piatră** (arc semicircular, 9–11 bolțari ca formă). Decor, nu e pe drum: deschiderea dă spre platforma palatului. `Arch_Limestone`, `Arch_Wood` (canatul de poartă, întredeschis) |

### 1.2 Coasta — `build_okinawa_coast.py`

Calcarul se citește pe două tonuri (regula 8). Stâncile se repetă pe coastă,
deci **siluetele trebuie să fie distincte între ele**.

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `rocks/notch_rock_a.glb` | **8–9 m** înaltă, capul ~7 m lat, piciorul ~3 m | ~1,2 | **înaltă și zveltă**: picior subțire, roasă adânc la bază (nișa ~1,5 m înaltă, de jur-împrejur), cap fațetat cu iarbă și 2–3 tufe joase pe creștet (singura vegetație lipită permisă). 3–5 bolovani la picior. `Notch_Limestone`, `Notch_Grass` |
| `rocks/notch_rock_b.glb` | **5 m**, capul ~9 m lat | ~0,55 | **lată și joasă**: cap mare ca o masă, picior scurt și gros |
| `rocks/notch_rock_c.glb` | **6,5 m**, capul ~6 m | ~1,0 | **aplecată**: capul deplasat ~2 m față de picior, ca roasă dintr-o parte |
| `rocks/heart_rock.glb` | **7 m** înalt, ~8 m lat | ~0,9 | două lobi rotunjiți care se unesc jos într-un vârf **înfipt în apă**; inima se citește din **+Y și din −Y** (se vede de pe pod și de pe plajă). 3–4 bolovani mici în jur. `Heart_Limestone`. Numele „Heart Rock” nu apare nicăieri |
| `rocks/limestone_cliff_module.glb` | **12 m** lung (Y), **14 m** înalt, 5 m adânc | ~1,1 | faleză de calcar pentru cornișa E: **perete cu nișă de val la bază** (~2 m), fațete verticale late de 1,5–3 m, creștet cu iarbă. Capete plane identice la ±6 m pe Y, ca să se înlănțuie. `Cliff_Limestone`, `Cliff_Grass` |
| `buildings/cape_lighthouse.glb` | turn **20 m** (Ø 3,6 m la bază, 2,6 m sus), galerie și felinar în vârf; casa paznicului **6 × 5 × 3,5 m** alături; soclu de calcar ~2 m | ~2,6 (turnul) | far **alb** (nu roșu-alb), ușor conic, 2–3 ferestre mici pe verticală, galerie cu balustradă (`segments` 12), felinar cu acoperiș în cupolă. Casa paznicului cu acoperiș plat. Fără stâncile din jur (le pune decorul, din `notch_rock`). Noduri `Lighthouse_Plaster`, `Lighthouse_Limestone`, `Lighthouse_Metal` (`VOLCANIC_BLACK`), `Lighthouse_Lamp` |
| `structures/coral_stone_wall.glb` | modul **4 m** lung (Y), **1,2 m** înalt, 0,8 m gros | — | zid uscat din **pietre rotunjite neregulate** (rândul de sus, 7–9 pietre, face conturul; restul e masă cu forme mari), fără mortar. Capete la ±2 m. Pentru tunelul de fukugi (B), sat și grădini. `Coral_Wall_Coral` |

### 1.3 Plante — `build_okinawa_plants.py`

Un nod per material (trunchi / coroană / flori). Plantele mici și fukugi
merg pe MultiMesh, deci **un singur mesh compact per variantă**, fără noduri
inutile. Coliziunea (`trunk` la arbori, `none` la tufe) e a coordonatorului.

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `plants/fukugi_tree_a.glb` | **7 m** înalt, **2,8 m** lat | ~2,5 | **coloană densă** (corectura de sus): 5–7 mase de frunziș suprapuse pe verticală, conturul aproape drept pe laturi, vârf rotunjit; frunzișul coboară la ~0,8 m; trunchi vizibil doar ~0,8 m. `Fukugi_Bark`, `Fukugi_Leaves` |
| `plants/fukugi_tree_b.glb` | **8,5 m**, 3 m | ~2,8 | mai înalt și mai zvelt, vârf mai ascuțit |
| `plants/fukugi_tree_c.glb` | **5,5 m**, 2,6 m | ~2,1 | mai scund și mai plin, o masă laterală ieșită (asimetric) |
| `plants/ryukyu_pine.glb` | **9 m**, ~9 m lat | ~1,0 | trunchi răsucit, aplecat, care se ramifică în 3–4 brațe; coroanele sunt **perne turtite** orizontale, cu goluri între ele (ca bonsai), nu glob. `Pine_Bark`, `Pine_Leaves` |
| `plants/cycad.glb` | **2,2 m**, 2,6 m lat | ~0,85 | trunchi scurt, gros, cu solzi (inele în geometrie), rozetă de **14–18 frunze rigide**, penate, arcuite. `Cycad_Bark`, `Cycad_Leaves` |
| `plants/fan_palm.glb` | **6 m**, coroană ~4 m | ~1,4 | palmier-evantai (nu cocotier): trunchi drept cu inele, **10–12 frunze în evantai rotund**, plisate, plus 2–3 frunze uscate atârnate. `Palm_Bark`, `Palm_Leaves` |
| `plants/bougainvillea.glb` | **1,6 m**, 2,4 m lat | ~0,65 | tufă căzătoare, care se revarsă peste ziduri: o variantă cu spatele plat (se lipește de zid), ciorchini magenta peste frunziș. `Bougainvillea_Leaves`, `Bougainvillea_Bloom`. Pornire posibilă: `build_bougainvillea.py` (Stromboli), **fișier nou** |

### 1.4 Satul și portul — `build_okinawa_village.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `buildings/ryukyu_house_a.glb` | casă **8 × 7 m**, **5 m** la vârful acoperișului; curtea cu zid de corali **14 × 12 m** | ~0,55 | casă joasă cu **acoperiș în patru ape** de olane roșii, **coame și rosturi albe în relief**, **shisa pe vârful acoperișului** (0,6 m); streașină largă pe stâlpi de lemn pe +Y (prispa); zid de corali jur-împrejur, **intrare fără poartă** pe +Y, iar **paravanul *hinpun*** (zid liber, 3 × 1,6 m) la 2 m în spatele intrării. Noduri `House_Roof`, `House_Mortar`, `House_Wood`, `House_Coral`, `House_Plaster` (pereții), `House_Shisa` |
| `buildings/ryukyu_house_b.glb` | casă **10 × 7 m**, 5,5 m; curte 16 × 12 | ~0,5 | **două corpuri** în L (casa + anexa mai joasă), două acoperișuri |
| `buildings/ryukyu_house_c.glb` | casă **6 × 6 m**, 4,5 m; curte 11 × 10 | ~0,6 | casa mică, acoperiș mai abrupt, intrarea pe o latură (curtea cu colțul tăiat) |
| `buildings/concrete_house_a.glb` | **9 × 8 m**, **6,5 m** (două niveluri) + rezervor | ~0,75 | cub de beton alb, **acoperiș plat cu parapet**, **rezervor cilindric** (Ø 1,6 m, 1,8 m, `segments` 10) pe picioare pe acoperiș, ferestre cu jaluzele ca formă, scară exterioară, sârmă de rufe pe acoperiș (2 stâlpi + 3–4 rufe). `Concrete_Plaster`, `Concrete_Concrete` (rezervorul, parapetul), `Concrete_Wood` |
| `buildings/concrete_house_b.glb` | **8 × 7 m**, 4 m (un nivel) + 2 rezervoare | ~0,6 | variantă joasă, tencuială **pastel** (`FLAMINGO_PINK`), două rezervoare |
| `structures/harbour_quay.glb` | modul **12 m** lung (Y), 6 m lat, **2,2 m** peste apă (+ 1,5 m sub) | — | chei de beton cu **scară de coborâre în apă** pe o latură, 3 babale, **anvelope de acostare** pe fața spre apă. Capete identice la ±6 m pe Y. **Originea la linia apei** (`--origin=waterline`). `Quay_Concrete`, `Quay_Rubber` (`VOLCANIC_BLACK`) |
| `structures/bus_stop_shelter.glb` | **4 × 2 m**, 2,8 m | ~0,7 | refugiu de autobuz cu **acoperiș de olane roșii**, stâlpi de lemn, perete din spate de corali, bancă. **Fără tăbliță, fără orar**. `Shelter_Roof`, `Shelter_Wood`, `Shelter_Coral` |
| `props/vending_machine.glb` | **1,8 × 1,0 × 0,8 m** | ~1,8 | automat alb, vitrină închisă (rând de 6–8 „sticle” ca forme simple, fără etichete), fantă de jos. **Fără text, fără logo**. `Vending_Plaster`, `Vending_Glass` |
| `props/convex_mirror.glb` | stâlp **3 m**, oglinda Ø **0,8 m** | — | stâlp portocaliu cu oglindă rotundă (ramă portocalie, `segments` 12), înclinată ușor în jos. `Mirror_Frame`, `Mirror_Glass` |
| `props/fishing_net_rack.glb` | **4 m** lung, 2 m înalt | — | cadru de lemn (2 capre + bară), **3–4 plase atârnate** cu flotoare. `Rack_Wood`, `Rack_Net` |

### 1.5 Vapoare și bărci — `build_okinawa_vessels.py`

**Feribotul e vaporul podului** (`LiftBridgeHazard.ship_model`), deci cotele
lui sunt contract de cod: traveea urcă 5 m peste puntea de +8,5 m
(`lift_bridge_hazard.gd:63`), iar vaporul trebuie să **depășească asfaltul**
(altfel podul nu are de ce să se ridice) și să **încapă sub travee**.

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `vehicles/island_ferry.glb` | **28 m** lung, **8 m** lat; **vârful (catargul) la 11,0 ± 0,5 m peste linia apei**; pescaj 2 m | ~0,4 | feribot de insule: coca albastră cu dungă roșie, **două punți** albe cu ferestre în bandă, puntea de sus deschisă cu balustradă, comandă în față, coș și catarg scurt. **Originea la linia apei** (`--origin=waterline`), **prova pe +Y** (în Godot −Z, `ship_bow_neg_z = true`, implicitul). Un singur nod-rădăcină `Island_Ferry` cu copiii `Ferry_Hull`, `Ferry_Plaster`, `Ferry_Stripe`, `Ferry_Glass`. Azi pista folosește provizoriu `fiordland/vehicles/cruise_boat.glb` ×2 |
| `vehicles/coastal_freighter.glb` | **34 m** lung, 8 m lat, catarg-radar la ~12 m | ~0,35 | vas de coastă cu **punte deschisă** (corectura de sus), cabina pe pupă, **catarg cu radar** pe cabină, macara de punte. Origine la linia apei, prova pe +Y. **Decor static** în afara canalului (brief §9: „așteaptă la intrare”); hazardul folosește un singur model. `Freighter_Hull`, `Freighter_Deck`, `Freighter_Plaster`, `Freighter_Glass` |
| `vehicles/fishing_boat.glb` | **9 m** lung, 2,8 m lat, cabina 3,2 m | ~0,45 | barcă de pescuit cu cabină în față, catarg mic, dungă albastră. Origine la linia apei. `Boat_Hull`, `Boat_Stripe`, `Boat_Glass` |

### 1.6 Animale — `build_okinawa_animals.py`

**Statice** (tiparul Serengeti): două poze ca noduri separate în același GLB,
`Pose_Stand` și `Pose_Walk`.

| fișier | cote | contract |
|---|---|---|
| `animals/water_buffalo.glb` | **2,8 m** lung, greabăn 1,5 m | bivol de apă gri-negru, **coarne lungi curbate pe spate**, fără jug |
| `animals/egret.glb` | **0,9 m** înalt | stârc alb, gât în S, cioc galben, picioare negre; poza `Pose_Stand` + `Pose_Fly` (aripi deschise, 1,4 m anvergură) |

### 1.7 Fundal — `build_okinawa_horizon.py`

`effects/okinawa_horizon.glb` cu noduri copii directe ale rădăcinii,
**volume închise, lizibile din orice azimut, origine la bază** (consumator
`Track._build_horizon`, `horizon_model` în tema `okinawa`):
`IeIsland_A` (insula Ie: platou jos ~120 × 60 × 8 m, cu **un singur con
abrupt** de ~45 m excentric, conul se recunoaște), `Kerama_A`, `Kerama_B`,
`Kerama_C` (insule joase, împădurite, cu faleze palide, 40–90 m lungime,
12–25 m înălțime). Fațete mari. Fără coliziune; `cast_shadow` OFF la
integrare (memoria `caster-departat-fura-umbra`).

### 1.8 Condiționat — `storm_wall`

Brief §4: peretele de furtună de la SE vine **din cer**, dacă `sky` permite
asimetria pe azimut. Coordonatorul măsoară asta la integrarea temei. **Nu se
construiește până nu e cerut explicit**; dacă se cere, contractul e o fâșie de
nori fațetați de ~400 m lungime, cu perdele de ploaie, `MARBLE_GREY` +
`VOLCANIC_BLACK`, origine la bază.

### 1.9 Ce NU se generează (refolosit sau făcut de cod)

| desen pe planșă | ce se folosește | de ce |
|---|---|---|
| `tetrapod` | `structures/tetrapod.glb` (kitul vechi), scalat 1,4–1,8× | forma e deja corectă; brief §5.1 |
| `pandanus`, `banyan` | `trees/pandanus.glb`, `trees/banyan.glb`, scalate ~1,6× | corecte botanic; brief §5.1 |
| `hibiscus` | `plants/hibiscus_bush.glb` | idem |
| `sugar_cane_field_patch` | `plants/sugar_cane_clump.glb` pe MultiMesh | câmpul e plasare, nu piesă |
| `sabani_canoe` | `vehicles/sabani_boat.glb` | — |
| `float_pile` | `scatter/beach_clutter.glb` (`Net_Floats`, `Fishing_Crate`) | — |
| `shisa_pair` | `props/shisa_statue.glb` + `shisa_statue_closed.glb`, scalate ~1,5× la poartă | kitul vechi are deja perechea corectă (gura deschisă + închisă); pe planșă amândoi au gura deschisă |
| `sea_turtle` | `props/sea_turtle.glb` (animat) | — |
| `waterspout` | `effects/typhoon.glb` (`TyphoonHazard`) | revizia vizuală (spray la bază, pe apă) e a coordonatorului, la integrare |
| `wave_crest` | `effects/wave_surge.glb` (`WaveSurge`) | refăcut în aug 2026 |
| — | pilonii și traveea podului | `LiftBridgeHazard` (`bridge_ramp.glb` + turnuri) |
| — | marea, golful, canalul, terenul | cod |

Doar pentru piesele din tabel: dacă la integrare o piesă refolosită arată
evident altfel decât decuparea ei, coordonatorul o trece în „de refăcut” în
inventar. Nu e treaba setului.

## 2. Livrabile

| fișier | ce |
|---|---|
| `tools/blender/build_okinawa_{castle,coast,plants,village,vessels,animals,horizon}.py` | rulabile headless: `D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- build_okinawa_castle.py`. **Docstring-ul fiecărei funcții de piesă conține lista de elemente** (§0.1 pasul 1), scrisă înainte de primul vertex. Vocabularul comun (zid de calcar cu talus, acoperiș de olane cu coame, piatră de corali) e în `okinawa_shapes.py` |
| `tools/blender/preview_okinawa.py` | `--compare <nume>` (decupare ↔ randare), `--views <nume>` (4 azimuturi), `--sheet <val> a,b,c` |
| `tools/blender/verify_okinawa_v2.sh` | o rulare, un verdict, excepțiile declarate cu motiv. **`verify_okinawa.sh` rămâne al kitului vechi** |
| `docs/asset_briefs/okinawa_inventory.md` | cote măsurate, tri, noduri, tabele de fidelitate, contracte înghețate (golul porții, vârful feribotului), **„Stare la oprire”** |
| `docs/asset_briefs/img/okinawa_fidelity/<nume>.png` | comparațiile alăturate |

## 0.1 Fidelitatea față de planșă — criteriul de acceptare

Planșa e sursa de **formă și culoare**; tabelele de aici (cu corecturile de
sus) sunt sursa de **cote și de contracte de cod**.

1. **Deschide decuparea** și scrie în docstring **lista de elemente** cu
   numere: câți stâlpi, câte trepte de acoperiș, câte pietre pe creasta
   zidului, câte mase de frunziș, ce iese din contur. Înainte de primul
   vertex. Unde o corectură de sus contrazice decuparea, lista urmează
   corectura și o spune.
2. **Modelează după listă**, la cotele din tabel. În rest, proporțiile
   interne ale desenului se păstrează.
3. **Randează comparația** (`preview_okinawa.py --compare <nume>`): decuparea
   în stânga, randarea GLB-ului în dreapta, aceeași înălțime în pixeli, 3/4
   din față, lumină de zi neutră, fundal `#C8C8C8`, **culoare reală**: fiecare
   față pe culoarea slotului ei din atlas (recuperat din UV), nodurile
   `*_Limestone` pe `#CFC6B0`, `*_Lacquer` pe `#B3261E`.
4. **Verifică pe imagine, element cu element**, nu doar numărând (memoria
   `numaratoarea-trece-amplasarea-nu`): poziția, forma, `h/l` (±15%), ordinea
   luminozităților, ce iese din contur. Tabel în inventar: element | pe
   planșă | în GLB | OK/abatere.
5. **Maximum 3 runde pe piesă.** Dacă tot nu seamănă, se raportează abaterea
   cinstit în inventar, nu se declară „trece”.
6. **Piesa se acceptă doar după ce comparația e văzută** de coordonator.

## 3. Ordinea de lucru (valuri de ~3 constructori; fiecare cu verify + comparații + commit)

0. **Pilot:** harnasul (`okinawa_shapes.py`, `preview_okinawa.py`,
   `verify_okinawa_v2.sh`) + `ryukyu_gate`. **Golul porții se măsoară ÎNAINTE
   de orice altceva.** Coordonatorul judecă comparația înainte de valul 1:
   poarta e reperul culmii.
1. **Valul 1:**
   - **ok-a**: palatul și zidurile (§1.1, fără poartă);
   - **ok-b**: coasta (§1.2);
   - **ok-c**: plantele (§1.3), **fukugi primul**, cu o captură de 6
     exemplare la 3,5 m unul de altul (tunelul) alături de cea izolată.
2. **Valul 2:**
   - **ok-d**: satul și portul (§1.4); casa Ryukyu e piesa-erou, deci
     `ryukyu_house_a` se judecă înaintea lui `b` și `c`;
   - **ok-e**: vapoarele (§1.5), cu **vârful feribotului măsurat** față de
     11,0 ± 0,5 m, plus animalele (§1.6);
   - **ok-f**: fundalul (§1.7).

Lucrează în worktree-ul indicat în prompt (ramura `okinawa/kit-<grupa>`). Nu
comite pe `main`, nu folosi `git stash` (e comun tuturor worktree-urilor), nu
face push.
