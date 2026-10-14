# Brief assets — Transfăgărășan (`Track21`, temă `transfagarasan`) — kit v1

**Contractul complet pentru setul de assets (Blender).** E făcut pe tiparul
`okinawa_kit_v2.md`. Regulile generale sunt în `docs/blender_export.md` și
`docs/style_bible.md` §4. Brief-ul pistei e `docs/track_briefs/transfagarasan.md`:
- §0.1 regula de artă;
- §2.0 scara față de cameră;
- §4 paleta;
- §5 assets (auditul kitului alpin și piesele noi);
- §8 respectul, legalul și ce s-a respins;
- §9 prompturile ChatGPT, iar §9.2 rezultatul lor.

**Kitul alpin rămâne pe loc**: Track09 îl folosește până la swap. O parte
din el trece în Track21 așa cum e (§1.9).

**Fidelitatea față de planșă e criteriu de acceptare, nu inspirație** (§0.1
de mai jos). Fiecare desen are propria decupare și se livrează cu o
comparație alăturată.

| fișier | ce e | ce iei din el |
|---|---|---|
| `docs/track_briefs/img/transfagarasan_assets_v1/<nume>.png` | **decuparea piesei**, una pentru fiecare dintre cele 40 de desene (ursul are două: `brown_bear_walk`, `brown_bear_stand`), mărită 2×. Le face `tools/blender/crop_transfagarasan_sheet.py`, iar montajul de control e `_control.png` | **referința de lucru a piesei:** silueta, numărul de elemente, proporțiile interne, culorile. Unele decupări au la margine o fâșie din piesa vecină (`prometheus_statue`, `tunnel_portal_balea`, `cabana_balea_lac`, `retaining_wall_curve`, `bear_warning_sign`). Ignor-o |
| `docs/track_briefs/img/transfagarasan_plan/inventar_v02.jpg` | planșa întreagă (8 rânduri) | ordinea și ansamblul. **NU dimensiuni:** barajul e cât o casă, trenul cât o mașină |
| `docs/track_briefs/img/transfagarasan_plan/diorama_v02_iter2.jpg` | diorama acceptată | atmosfera, paleta în lumina de după-amiază, cum stau piesele împreună. **Nu stilul** (e pictată). Unde se contrazic, câștigă planșa, cu excepția corecturilor de mai jos |
| `docs/track_briefs/img/transfagarasan_plan/diorama_v02_iter1.jpg`, `_iter3.jpg` | generările respinse | nimic de modelat; păstrate pentru istoric (brief §9.2) |
| `docs/track_briefs/img/transfagarasan_plan/transfagarasan_plan.png` | planul real al pistei | unde stă fiecare piesă; nu îl folosești la modelare |

**Corecturi decise de coordonator (suprascriu planșa):**
- **Mașinile parcate NU au voie să semene cu Dacia.** Pe planșă,
  `parked_car_a` e un Logan și `parked_car_b` un Sandero/Duster (grila,
  farurile, silueta). Brief-ul §8 cere mașini **generice**: grilă simplă, fără
  siglă, faruri dreptunghiulare simple. Silueta trebuie să fie de mașinuță de
  jucărie (scurtă, lată, roți mari), nu de model anume. Cele două diferă ca
  tip: un hatchback mic și un break / SUV mic;
- **`vidraru_dam` are coronamentul DREPT în plan, iar arcul se citește pe
  verticală.** Corectura din brief §9.2 („barajul e arc”) a fost
  **remăsurată pe Track21**: coronamentul (fracțiile 0,078–0,123) are 96 m și
  o rază de **~3,2 km**, deci e drept, iar drumul e sursa de adevăr.
  Barajul-arc se citește din trei lucruri:
  - fața din aval **concavă pe verticală** (se lărgește spre bază);
  - culoarul îngust de stâncă în care stă;
  - turnul de priză.

  Planșa (zid drept) are deci dreptate în plan. Îi lipsesc doar profilul
  curb și rosturile verticale dintre ploturi;
- **`snow_wall` NU e din cuburi albe curate.** E zăpadă veche de iulie:
  - 3–4 straturi orizontale vizibile ca formă (trepte de 0,2–0,4 m pe fața
    tăiată de plug);
  - dungi de praf pe fața spre drum;
  - muchia de sus rotunjită, care se topește;
  - baza murdară.
- **Cabanele NU au balcoane sculptate.** Riscul e chalet-ul tirolez (brief
  §0.1). Cabana românească de munte are:
  - parter de piatră;
  - unul sau două niveluri de lemn;
  - acoperiș abrupt de tablă;
  - cel mult o terasă simplă, cu balustradă din scânduri drepte.

  `cabana_balea_cascada` trebuie să difere ca formă de `cabana_balea_lac`
  (pe planșă sunt aproape identice) și de `arges_house_a`;
- **`cable_cabin_large` e o cabină MARE, nu o gondolă.** Pe planșă e cât o
  gondolă de 6 locuri. Cabina de la Bâlea duce ~30 de oameni: o cutie cu
  geamuri pe toate laturile și cu podea plată. Proporțiile sunt în §1.7;
- **`bear_warning_sign` are pictograma „nu hrăniți urșii”** (brief §8), nu
  „atenție urși”: ursul, plus o mână cu mâncare tăiată de bara roșie.
  Triunghiul cu chenar roșu rămâne. **Fără text**;
- **`rock_tunnel_portal` e stâncă brută**, fără inelul de zidărie de pe
  planșă. Tunelurile scurte de pe malul Vidraru sunt tăiate în rocă fără
  căptușeală. Piesa e **un pinten întreg străpuns**, deschis la ambele capete
  (§1.1), fiindcă pe Track21 nu există încă masă de teren peste drum în C;
- **variantele diferă ca siluetă, nu doar ca scară.** `beech_tree_a`/`b` și
  `schist_outcrop_b`/`c` sunt aproape identice pe planșă;
- **fără vegetație lipită pe clădiri, ziduri și stânci.** Jnepenii, florile
  și iarba din jurul pieselor de pe planșă se pun la integrare (MultiMesh și
  `DecorManual`). Excepție: **iarba și mușchiul de pe creștetul stâncii
  Poenari** și de pe pintenul lui Prometeu, care fac parte din siluetă;
- **fără text, cifre sau logo-uri** nicăieri: semnele au doar pictograme,
  trenul n-are siglă, mașinile n-au număr de înmatriculare lizibil;
- **cotele vin din tabelele de mai jos**, NU din planșă.

## 0. Regulile care nu se negociază

1. **Categoria** e
   `assets/models/transfagarasan/{buildings,structures,rocks,plants,props,vehicles,animals,effects}/`.
   `dio_lib.export_glb` primește calea cu categorie
   (`"transfagarasan/structures/tunnel_portal_balea.glb"`).
2. **Asset nou = fișier nou.** Nu se suprascrie nimic din kitul alpin
   (`structures/`, `trees/`, `buildings/`, `props/`, `vehicles/`, `scatter/`,
   `rocks/`), al lui Track09 până la swap, sau din alte categorii de piste.
3. **Setul de piese nu atinge `scenes/` și `scripts/`.** Coordonatorul se
   ocupă de:
   - clasele (`tf_schist`, `snow`, `concrete`, `plaster`, `pine_needles`) și
     `PROP_COLLISION`;
   - tema și `DecorManual`;
   - modelul ursului pe `HazardMarker`, `alt_model` din `HerdHazard` și
     `model_path` din `TrainHazard`;
   - montarea în `Track21.tscn`.

   Aici se livrează: GLB, build script, preview, verify, inventar și
   comparații.
4. **Paletă: zero sloturi noi** (32 din 32 ocupate). Celelalte reguli de
   export:
   - UV1 colapsat pe centrele sloturilor;
   - AO copt în vertex colors;
   - origine la bază (excepțiile sunt în tabel);
   - scară metrică;
   - **scala aplicată pe fiecare nod rădăcină** (memoria
     `scala-glb-neaplicata-la-radacina`).

   „Înainte” e −Z în Godot = **+Y în Blender**. „Dreapta” e +X în ambele.
   Fața bogată a clădirilor stă pe +Y și se **măsoară** pe GLB, nu se
   presupune (memoria `fata-casei-nu-e-plus-z`).
5. **Sloturile pe roluri** (tabelul de mai jos). Culoarea finală a șistului,
   a zăpezii și a betonului o dă clasa, nu slotul.
6. **Piesele care primesc clasă la integrare se sparg la export în noduri cu
   un singur material** (memoria `clase-pe-piese-de-kit`), cu sufixele din
   tabel: `*_Schist`, `*_Snow`, `*_Concrete`, `*_Plaster`, `*_Roof`.
   **Offsetul de origine se calculează o dată pe ansamblu.** Verificarea e
   `verify_glb.py --origin=assembly`.
7. **Ce NU e geometrie:** porii și sclipirea de mică ale șistului, granulația
   zăpezii, rosturile fine de beton. Toate vin din clasă. **Ce ESTE
   geometrie:** formele care schimbă silueta sau umbra:
   - **lamele înclinate ale șistului** (foliația, la 30–50°, toate în aceeași
     direcție pe o piesă);
   - **treptele de strat** ale pereților de zăpadă;
   - **profilul concav** al barajului;
   - **zimții** zidurilor de la Poenari;
   - **pietrele individuale** de pe creasta zidurilor de sprijin.

   Regula: „se vede ca formă la 30 m din mașină?”.
8. **Șistul se citește pe două tonuri:** suprafața gri-verzuie și **fisurile
   închise dintre lame**. Fisura se face din geometrie plus AO, nu cu un slot
   închis întins pe o suprafață mare. Pentru fisuri, `ROCK_DARK` e interzis:
   e maro și pe stâncă rece iese rugină (memoria `rock-dark-nu-pe-bazalt`).
9. **Fără text, fără cifre, fără logo-uri.**
10. **Primitive rotunde: setează `segments`** (6–12). Asta contează la
    stâlpii de zăpadă, conuri, roțile mașinilor și ale motocicletei, becurile
    trecerii la nivel, roțile de caș și cilindrul turnului de priză (8–12).
11. **Verificarea e din fișier, nu din memorie:**
    - `verify_glb.py` pe fiecare GLB;
    - `preview_transfagarasan.py` randează **din GLB-urile exportate**;
    - verdictul setului e `bash tools/blender/verify_transfagarasan.sh` →
      `VERDICT KIT: OK` **și** comparațiile de fidelitate aprobate (§0.1).

    `verify` verde nu e livrare (memoria
    `harnasul-de-kit-nu-vede-forma-nici-culoarea`).
12. **Randările rulează pe GPU.** Înainte de orice randare Blender/Godot cu
    fereastră: `mkdir D:/GameDev/.render_lock`. Dacă eșuează, alt proces
    randează, deci aștepți. `rmdir` imediat după.

### Sloturi pe roluri

Doar sloturi existente (`scripts/palette.gd`, constantele din `dio_lib.py`).
Hexul slotului e trecut ca să se vadă de ce s-a ales. Ținta din brief §1 se
atinge cu clasa, la integrare.

| rol | slot (în GLB) | clasă la integrare (nu o faci tu) |
|---|---|---|
| șistul (aflorimente, grohotiș, stânca Poenari, pintenul lui Prometeu, portalul de stâncă) | **`MARBLE_GREY` 29** (`#B8B4AC`); fisurile `VOLCANIC_BLACK` 20, în benzi înguste | `tf_schist` pe `*_Schist` |
| zăpada (pereții, portalul Bâlea) | **`FOAM_WHITE` 22**; dungile de praf `CONCRETE` 8 (`#C8BDA9`, aproape de `#B9B2A4`) | `snow` pe `*_Snow` |
| betonul (barajul, portalul Bâlea, turnul de priză, centrala, soclurile) | `CONCRETE` 8 | `concrete` pe `*_Concrete` |
| dungile roșii (parapetul barajului, stâlpii de zăpadă, barierele, chenarul semnelor) | `KERB_RED` 7 | — |
| câmpul alb al semnelor, barierele, crucea Sf. Andrei | `FOAM_WHITE` 22 | — |
| pictogramele, carcasele luminilor | `VOLCANIC_BLACK` 20 | — |
| conurile de șantier | `LAVA_ORANGE` 30 (doar albedo, **fără** clasa de lavă), benzile `FOAM_WHITE` 22 | — |
| cărămida de la Poenari | `TILE_TERRACOTTA` 23 | — |
| piatra zidurilor de la Poenari, zidurile de sprijin, parterul cabanelor | `MARBLE_GREY` 29 | `stone_wall` pe `*_Stone` (decizie la integrare) |
| tabla acoperișurilor (argintie) | **`ASPHALT_EDGE` 6** (`#696765`, gri neutru). **Revizuit în valul 2** (decizia coordonatorului, pentru toate clădirile): `PAINTED_METAL` 11 (`#7692A8`) ieșea albastru în comparație, iar tenta clasei doar întunecă, deci din albastru nu se ajunge la gri | `*_Roof` (clasa o luminează la integrare) |
| tabla roșie (`arges_house_b`) | `KERB_RED` 7 | `*_Roof` |
| tabla ruginită (stâna, anexe) | `RUST_METAL` 10 | — |
| tencuiala albă a caselor din vale | `FOAM_WHITE` 22 | `plaster` pe `*_Plaster` |
| lemnul (cabane, stână, țarc, tarabă, garduri) | `WOOD_WEATHERED` 9, umbrit `LOG_DARK` 28 | — |
| jneapănul | `LOG_DARK` 28 (ca molizii din brief §4) | `pine_needles` pe `*_Needles` |
| fagul: coroana | `TROPICAL_GREEN` 21 | `beech_canopy` (există, Fiordland). Tenta se recalculează pe fagul european, mai cald |
| fagul: trunchiul (scoarță **netedă, gri**, nu maro) | `MARBLE_GREY` 29 | — |
| bujorul de munte | flori `FLAMINGO_PINK` 31, frunziș `TROPICAL_GREEN` 21 | magenta `#B63A7A` din tentă, dacă slotul iese prea pal (se măsoară) |
| afinul | frunziș `TROPICAL_GREEN` 21, bobițe `ICE_DEEP` 25 (`#2F6E82`) | — |
| ursul | blana `LOG_DARK` 28, vârfurile (umeri, spate) `LARCH_RUST` 27, botul și ghearele `VOLCANIC_BLACK` 20 | se măsoară să nu iasă „vacă maro” (brief §4) |
| ciobănescul | blana `CORAL_SAND` 19 (`#E9DCC0`); pata de pe umăr, masca și urechile `ASPHALT_EDGE` 6 (`#696765`, gri închis neutru; rev. 1 pe `MARBLE_GREY` ieșea prea deschis); nasul și ochii `VOLCANIC_BLACK` 20 | — |
| Prometeu (bronz) | `LARCH_RUST` 27 (`#A8683A`), umbrit `LOG_DARK` 28; fulgerul `CAR_YELLOW` 16 (`--allow-car-slots=*_Bolt`) | — |
| caşul și fructele de pe tarabă | caș `SAND_LIGHT` 0, zmeură `KERB_RED` 7, afine `ICE_DEEP` 25 | — |
| mașinile parcate | caroseria `CAR_BLUE` 15 / `CAR_RED` 14 (`--allow-car-slots=Car_Body`), geamuri și cauciucuri `VOLCANIC_BLACK` 20, plastic `ASPHALT` 5 | — |
| motocicleta | rezervorul `CAR_BLUE` 15 (`--allow-car-slots=Moto_Body`), restul `VOLCANIC_BLACK` 20 / `PAINTED_METAL` 11 | — |
| trenul | caroseria `CAR_RED` 14 (`--allow-car-slots=Train_Loco,Train_Tender,Train_Wagon`), banda `PAINTED_METAL` 11, geamurile `VOLCANIC_BLACK` 20 | — |
| cabina telecabinei | `CAR_RED` 14 (`--allow-car-slots=Cabin_Body`), geamurile `VOLCANIC_BLACK` 20, căruciorul `PAINTED_METAL` 11 | — |
| fundalul: creasta / norii / câmpia | `MARBLE_GREY` 29 + `FOAM_WHITE` 22 / `FOAM_WHITE` 22 / `TROPICAL_GREEN` 21, `CACTUS_GREEN` 12, `DRY_VEGETATION` 13 | — |
| goluri (ferestre, uși, gura tunelului) | `VOLCANIC_BLACK` 20 | — |

> **Abateri de la brief §4, cu motiv:**
> - **șistul** era pe `ROCK_LIGHT` 3. Hexul lui e `#C18446`, gresie
>   portocalie, iar ținta e `#7E8478`, gri-verzui. Tenta clasei doar
>   întunecă, deci de la portocaliu nu se ajunge la verzui, fiindcă albastrul
>   ar trebui să crească de la 70 la 120 (memoria `slot-ales-dupa-nume`).
>   Pe `MARBLE_GREY` (`#B8B4AC`), raportul spre țintă e (0,68; 0,73; 0,70),
>   toate sub 1, deci tenta ajunge acolo. E aceeași decizie ca la calcarul
>   din Okinawa;
> - **oile și câinii** erau pe `SAND_LIGHT` 0. Acela e `#E8C074`, nisip
>   galben. Lâna crem e `CORAL_SAND` 19, ca oaia din Monument Valley, care se
>   refolosește (§1.9).

Pista e **diurnă, lumină fixă**: nu se cer noduri `*_Glow`. Excepție sunt
luminile trecerii la nivel (`Crossing_Lamp`, nod separat), ca integrarea să
le poată aprinde. Luminile active vin oricum din `TrainHazard`.

## 1. Inventar și contracte

Convenții pentru tabele:
- dimensiunile sunt în metri;
- `h/l` = înălțimea / lățimea siluetei pe decupare. Se verifică în
  comparație, cu toleranță de ±15%;
- triunghiurile se **raportează, fără plafon** (CLAUDE.md). Contează
  **materialele** (un nod = un material);
- **modulele înlănțuibile** au capete identice, plane, la ±L/2 pe Y;
- **cotele de contract (goluri) se măsoară ca GOL**: proiecție pe plan, pe
  gabaritul caroseriei (memoriile `cota-de-contract-se-masoara-ca-gol`,
  `golul-se-masoara-pe-fereastra-lui`).

**Lățimile de drum** vin din `Track21.tscn`: **14 m** în general
(`custom_half_width = 7`), **12 m** pe coronament și în tunel
(`custom_width_segments`, 0,078–0,123 și 0,317–0,350).

**Scara e decizie, nu defect** (brief §2.0 și §8). Sub o cameră la 10 m, un
obiect de la marginea drumului care trebuie **citit** cere ≥ 3–4 m, iar un
reper văzut de departe ≥ 15 m. Cotele de joc:
- hăul barajului are 40 m;
- Poenari are 28 m (stânca plus zidurile);
- Prometeu are 9 m;
- ursul ridicat are 3 m.

### 1.1 Drumul — `build_tf_road.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `structures/tunnel_portal_balea.glb` **(pilot, contract rev. 2)** | **placa de beton masiva 26 m (X) x 11 m (Z) x 6 m (Y)**, muchii vii, fata din fata (+Y) inclinata inapoi ~5 grade. Totalul cu zapada ~**48 x ~17 x ~13 m** | ~0,42 (beton) | **Fata doar pe +Y**: piesa NU e simetrica fata-spate (spatele intra in munte); a doua gura primeste acelasi GLB rotit 180 grade. Fara cornisa, contraforturi sau rama iesita. **Gura dreptunghiulara cu umeri TESITI** (nu arc): 15 m la baza, stalpi verticali pana la 6,5 m, tesituri 45 grade de 2 m, buiandrug drept la 8,5 m (~58% din latime). **Golul, MASURAT CA GOL: >= 13,0 m pe 0-2 m si >= 7,0 m inaltime libera in fereastra \|x\| <= 6,5** (cu cotele de mai sus ~14,9 m si ~7,4 m). `Portal_Void` captuseste peretii SI tavanul pe grosimea placii + 4 m in spate (10 m, fara podea; doar in preview, plan negru la y = -12). **Zapada INVELUIE portalul** (planșa bate corectura `snow_wall` aici): pe laturi movila de 6-8+ blocuri mari, fatetate, 9-10 m langa placa, cobora la ~4 m la 11 m spre exterior, de la \|x\| >= 13 (nimic in banda drumului); peste placa si in spatele ei o calota pana la ~13 m, la 10 m in spate; placa iese ~1 m din movila in fata. Praf: 2-3 bucati scurte, inclinate, neregulate pe parte. Origine pe axa drumului, y = 0 la fata placii, baza la 0, scala aplicata. Noduri: `Portal_Concrete` (CONCRETE 8), `Portal_Snow` (FOAM_WHITE 22), `Portal_Dust` (CONCRETE 8), `Portal_Void` (VOLCANIC_BLACK 20). Coliziunea o decide coordonatorul. Azi stau provizoriu 2 x `structures/mountain_tunnel.glb` scalat ~1,5 x 1,25, care trece ProbeRace; golul nou se compara cu el |
| `structures/rock_tunnel_portal.glb` **(contract revizuit dupa val 1)** | **pinten străpuns**: **34 m** lat la bază (X), **20 m** înalt, **16 m** lung pe Y (drumul trece prin el). Silueta **în dom / triunghi**: masa urcă spre un vârf deasupra gurii, flancurile coboară până la sol pe ambele părți (h/l ~0,6, ca pe decupare). **Golul ≥ 15,0 m (±7,5) pe 0–2 m, înălțime liberă ≥ 7,0 m, măsurat ca GOL**, la ambele capete și pe toată lungimea (gura ~45% din lățime, ~38% din înălțime) | ~0,6 | tunel scurt **în rocă brută** (corectura de sus): gura neregulată, cu fețe de șist la vedere și fără inel de zidărie. Lamele de șist sunt înclinate în aceeași direcție pe toată piesa. Pe față, **3–5 contraforturi de stâncă ies în relief** de lângă gură (blocuri ca mase distincte, ca pe decupare). Iarba (`TROPICAL_GREEN`) doar pe trepte și pe creștet, unde integrarea pune 2–3 fagi. Deschis la ambele capete, interiorul `VOLCANIC_BLACK` doar în primii 2 m. În **preview**, plan negru la y = −14 în spate (ca la Bâlea), ca gura să nu arate fundalul. `Rock_Schist`, `Rock_Grass`, `Rock_Void` |
| `structures/snow_wall.glb` | modul **8 m** lung (Y), **4 m** înalt, 2,5 m gros la bază și 1,2 m sus | ~0,5 | perete de zăpadă veche lângă asfalt (corectura de sus). Fața spre drum (−X) e **tăiată vertical** de plug, cu **3–4 trepte de strat** și dungi de praf. Fața dinspre versant (+X) e rotunjită, iar muchia de sus e topită și ondulată. Capete plane, identice la ±4 m pe Y. Două variante ca noduri-rădăcină în același GLB: `SnowWall_A` (4 m), `SnowWall_B` (3 m). `*_Snow` + `*_Dust` (`CONCRETE`, dungile) |
| `structures/retaining_wall_straight.glb` **(contract revizuit dupa val 1)** | modul **8 m** lung (Y), **5 m** înalt, 1,2 m gros sus, 2 m la bază | ~0,6 | zid de sprijin din **piatră uscată** pentru acele de păr. Fața spre vale (+X) e ușor înclinată (talus ~10°). **Corpul:** **12–18 pietre MARI ca formă** (0,8–1,4 m) pe fața unui modul, în rânduri neregulate. Fiecare piatră e o față cu **inset de 4–6 cm** și muchie ușor teșită, ca rosturile să facă umbră (formă la 30 m; granulația o dă clasa `stone_wall`). **Creasta:** un rând de **pietre de coronament LIPITE, în același plan** (coping), plană la cota 0 (aici stă marginea drumului) și ieșită **5 cm** peste fața zidului; fără blocuri separate cu goluri între ele. Capete la ±4 m, identice. Origine pe marginea drumului (x = 0), la cotă 0, zidul atârnă dedesubt (`--origin=rim`). `Wall_Stone` |
| `structures/retaining_wall_curve.glb` **(contract revizuit dupa val 1)** | modul pe arc de **8 m** (coardă) pe **R = 23 m** (marginea exterioară a acului de păr: fillet 16 m + semilățimea 7 m), aceleași secțiuni | ~0,6 | același zid (corp din pietre mari cu inset, coronament lipit), curb, cu fața convexă spre vale. Capetele sunt identice cu ale modulului drept, ca să se înlănțuie. `Wall_Stone` |
| `props/snow_pole.glb` | **2,5 m**, Ø 0,08 m (`segments` 8), pe un bolovan mic de 0,4 m | — | stâlp de zăpadă cu **5 dungi** alternante alb-roșu (planșa). `Pole_Paint` (`KERB_RED` + `FOAM_WHITE`, două noduri), `Pole_Stone` |
| `props/road_works.glb` | grup pe **6 × 2 m**: 4 conuri de **0,75 m**, o barieră cu capre de **3 m** lungime și 1,1 m înălțime, un semn triunghiular pe stâlp de **2,4 m** | — | recuzita șantierului din tunel (brief §3): conuri cu 2 benzi albe, bariera cu dungi diagonale roșu-alb, semn cu **pictograma de lucrări** (omul cu lopata). **Fără semafor**: lampa e `HazardLamp`, în cod (brief §5.3). Fiecare element e nod separat (`Works_Cone_1..4`, `Works_Barrier`, `Works_Sign`), ca integrarea să le poată muta |
| `props/level_crossing.glb` | două ansambluri, câte unul pe fiecare parte a drumului: stâlp cu **crucea Sf. Andrei** (2,8 m) și **bariera** (braț de **7,5 m**, peste o bandă) | — | crucea alb-roșie, **fără text**, cu două lămpi rotunde sub ea (`Crossing_Lamp`, `segments` 10). Bariera e **ridicată vertical** în poza de export, cu pivotul brațului în nodul `Crossing_Boom_L`/`_R` (originea nodului pe balama), ca integrarea să o poată coborî. Luminile clipitoare și stâlpii de avertizare vin deja din `TrainHazard._build_gates`, iar piesa se pune lângă ei, nu în locul lor |
| `props/bear_warning_sign.glb` | triunghi cu latura de **1,2 m** pe stâlp de **2,4 m**, cu un bolovan la bază | — | pictograma **„nu hrăniți urșii”** (corectura de sus): ursul și o mână cu mâncare, tăiate de bara roșie. Chenarul `KERB_RED`, câmpul `FOAM_WHITE`, pictograma `VOLCANIC_BLACK`, făcută din **relief de 1–2 cm**, nu din textură. **Fără text** |

### 1.2 Baraj și repere — `build_tf_landmarks.py`

**Barajul.** Drumul de pe coronament e asfalt din cod. Barajul îl **ține**,
nu îl acoperă. Orientarea: drumul pe +Y, **lacul pe −X (stânga)**, **hăul pe
+X (dreapta)**, ca pe Track21, unde drumul merge spre est cu lacul la nord.

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `structures/vidraru_dam.glb` | trei noduri-rădăcină. **`Dam_Module`:** **16 m** lung (Y), coronament **14 m** lat (X: drumul de 12 m + câte 1 m), **40 m** de la coronament la piciorul din aval, **9 m** pe fața din amonte (coronament +12, apa la +7,5, fundul la +3). **`Dam_Tower`:** turnul de priză, 6 × 6 m, +8 m peste coronament, cu o pasarelă de 6 m spre coronament. **`Dam_PowerHouse`:** centrala de la picior, 14 × 9 × 8 m | ~2,5 (modulul, din lateral) | **originea fiecărui nod e la cota drumului**, pe axă, iar geometria **atârnă sub Y = 0** (`--origin=rim`, ca la `crater_bowl`). Fără geometrie peste Y = −0,05 între \|x\| ≤ 6,0 (acolo e asfaltul). **Parapetul**: \|x\| între 6,25 și 7,0, **1,1 m** înalt, beton cu dungi roșii (`KERB_RED`, ca parapetele de pe serpentine). Fața din aval e **concavă pe verticală** (corectura de sus): verticală sus, se lărgește în ultimii 15 m. Are rosturi verticale între ploturi (o canelură de 0,3 m la capetele modulului) și 3 benzi orizontale de cofraj ca trepte de 5 cm. Capete plane la ±8 m. 6 module = coronamentul de 96 m. Turnul: cilindru (`segments` 12) cu cabina de vane sus și ferestre. Centrala: cutie de beton cu ferestre înalte și ieșirea apei ca gol `VOLCANIC_BLACK`. `*_Concrete`, `Dam_Rail` (`KERB_RED`), `*_Void` |
| `props/prometheus_statue.glb` | **9 m** total: soclu de stâncă **3 m** (Ø ~4 m) + figura **6 m** cu brațul ridicat | ~1,6 | figură masculină de **bronz**, stilizată, cu fațete mari, în picioare. **Brațul drept ridicat** ține **fulgerul în zig-zag** (3 segmente, 1,5 m). Fără inscripție pe soclu. Silueta se citește din spate și din lateral: e pe pintenul de la capătul de est al barajului, iar drumul trece pe lângă el. `Statue_Bronze`, `Statue_Bolt`, `Statue_Schist` (soclul, cu iarbă pe creștet) |
| `buildings/poenari_ruin.glb` **(contract revizuit după val 2: stânca)** | stânca **18 m**, **MOVILĂ conică, nu tambur**: baza **~36 × 28 m**, creștetul doar cât ține incinta, **~25 × 15 m**, flancurile la **60–70°** în trepte neregulate. Conturul e rupt de **4–6 mase mari** (contraforturi de stâncă de 6–10 m) care ies din flancuri la înălțimi diferite, cu **3–4 ravene verticale** adânci între ele; văzută de sus, amprenta nu are nicio muchie dreaptă mai lungă de ~6 m. Marginea creștetului e **neregulată** (blocuri care ies peste ea, iarba coboară în limbi pe ravene, fără inel continuu). Molozul de la picior rămâne. Zidurile **10 m** pe creștet (incintă ~22 × 12 m); **talpa de piatră e subțire și discontinuă** (bucăți sub ziduri, nu inel), iar unde lipsește ruina pornește din stâncă, îngropată 0,3 m | ~0,85 | **ruină**, nu castel întreg (brief §8: **fără Dracula**): incintă dreptunghiulară alungită cu **2 turnuri** (unul rectangular, unul semicircular, ca ruina reală). Zidurile sunt **rupte la înălțimi diferite**, cu breșe, și au creneluri **doar** pe bucăți. Cărămida (`TILE_TERRACOTTA`) e sus, piatra (`MARBLE_GREY`) pe alocuri la bază. **Fără acoperișuri, fără turle ascuțite, fără steaguri.** Stânca de șist are mușchi și iarbă pe trepte, care fac parte din siluetă. Pe flancul nevăzut (−Y) are **o scară** în zig-zag, doar ca formă, ca semn al celor 1 480 de trepte. Coliziune `mesh` pe stâncă (stă lângă drum, la final). Noduri `Poenari_Schist`, `Poenari_Brick`, `Poenari_Stone`, `Poenari_Grass` |

### 1.3 Clădiri — `build_tf_buildings.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `buildings/cabana_balea_lac.glb` **(contract revizuit după etapa 1 a valului 2)** | **13 × 10 m**, parter de piatră **3 m** + **două niveluri de lemn de câte 2,7 m** (peretele lung ~8,4 m până la streașină), pantă ~45–48°, coama la **~13 m** | ~0,7 | cabană de munte: **parter de piatră**, **două niveluri întregi de lemn**, **acoperiș abrupt** de tablă argintie (`ASPHALT_EDGE`), cu 2 lucarne și un coș de piatră. Pe frontonul +X: trei rânduri de ferestre plus aerisirea. Pe +Y: o **terasă simplă** la +3 m, cu balustradă din scânduri drepte (corectura de sus) și o scară. Ferestrele sunt în rânduri regulate. Rev. 1 (16 × 10 m, coama la 11 m) citea „șură lungă și joasă”. `Cabana_Stone`, `Cabana_Wood`, `Cabana_Roof`, `Cabana_Void` |
| `buildings/cabana_balea_cascada.glb` | **12 × 9 m** + anexă **6 × 5 m**; **8 m** la coamă | ~0,6 | **altă formă** (corectura de sus): **un singur nivel** de lemn pe soclu de piatră, cu podul mansardat și o **anexă joasă în L**. Acoperiș de tablă **ruginie** (`RUST_METAL`), prispă de-a lungul fațadei lungi. Stă lângă stația de jos a telecabinei (`cable_car_station.glb`, refolosită) |
| `buildings/stana.glb` | coliba **5 × 4 m**, **3,2 m** la coamă; țarcul **14 × 10 m**, gard de **1,2 m** | ~0,5 (coliba) | stâna: colibă joasă de **scânduri verticale**, acoperiș în două ape de șindrilă, coș de tablă, **țarcul** din pari și 3 rânduri de bârne, cu **o poartă deschisă**. Un butuc de despicat lemne lângă colibă. Fără oi (vin din turmă și din decor). `Stana_Wood`, `Stana_Roof`, `Stana_Fence` |
| `buildings/arges_house_a.glb` | **9 × 7 m**, **6,5 m** la coamă; gard de 1,2 m pe +Y | ~0,7 | casă din vale: **pereți albi tencuiți**, **prispă de lemn** pe stâlpi pe +Y, **acoperiș în patru ape de tablă argintie**, streașină largă, ferestre cu ramă de lemn. **Gard de scânduri** în față, cu poartă. `House_Plaster`, `House_Wood`, `House_Roof` |
| `buildings/arges_house_b.glb` | **8 × 6 m** + șură **5 × 4 m**; **6 m** | ~0,75 | **altă formă**: casa cu **fronton de scânduri** spre drum și acoperiș în două ape de **tablă roșie** (`KERB_RED`), cu șura de lemn alăturată. Pereții tencuiți `FOAM_WHITE` (nu verde ca pe planșă). Același gard |
| `props/souvenir_stall.glb` | **3,5 × 2 m**, **2,8 m** | ~0,8 | tarabă de lemn cu acoperiș într-o apă din scânduri. Pe tejghea: **roți de caș** (`segments` 10) și **coșuri** cu zmeură și afine. Sub streașină atârnă **caș afumat în coajă de brad** (cilindri mici, maro). **Fără text, fără firmă** |

### 1.4 Stânci — `build_tf_rocks.py`

Șistul se citește pe lame (regula 7) și pe două tonuri (regula 8). Stâncile
se repetă pe tot versantul, deci **siluetele trebuie să fie distincte între
ele**.

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `rocks/schist_outcrop_a.glb` | **6 m** înalt, 5 m lat | ~1,2 | **3–4 lame** înclinate la ~40°, suprapuse ca niște cărți, cu o lamă dominantă. 4–6 blocuri la picior. `Schist_Schist` |
| `rocks/schist_outcrop_b.glb` | **3,5 m**, **8 m** lat | ~0,45 | **joasă și lată**: o creastă de lame aproape culcate (~25°), ca un dinte de ferăstrău văzut din lateral |
| `rocks/schist_outcrop_c.glb` | **8 m**, 4 m | ~2,0 | **un ac**: o singură lamă verticală, crăpată pe lung în două, cu un umăr la jumătate |
| `rocks/scree_cone.glb` | **Ø 12 m**, **4 m** înalt | ~0,35 | **con de grohotiș** de la piciorul unui perete: pantă de ~35° spre vale, vârful lipit de perete (o latură e plană, −Y, se lipește de stâncă), din **pietre plate de șist**, nu din bulgări rotunzi. Coliziune `none` (e în afara drumului) |

### 1.5 Plante — `build_tf_plants.py`

Fiecare nod are un singur material (trunchi / coroană / flori). Plantele mici
merg pe MultiMesh, deci **un singur mesh compact per variantă**, fără noduri
inutile. Coliziunea (`trunk` la arbori, `none` la tufe) e a coordonatorului.

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `plants/jneapan_a.glb` | **1,2 m** înalt, **4 m** lat | ~0,3 | **jneapăn**: tufă **culcată**. 4–6 ramuri groase pornesc din centru culcate pe sol și se ridică la capete, cu perne dense de ace verde-închis pe ele. **Nu e un brad mic.** `Jneapan_Bark`, `Jneapan_Needles` |
| `plants/jneapan_b.glb` | **1,5 m**, **3 m** | ~0,5 | mai compact și mai înalt, asimetric, cu o pernă ieșită într-o parte |
| `plants/beech_tree_a.glb` | **13 m**, coroană **10 m** | ~1,3 | **fag european**: trunchi drept, **gri, neted**, ramificat sus. Coroana e ovală și largă, din 5–7 mase. `Beech_Bark`, `Beech_Leaves` |
| `plants/beech_tree_b.glb` | **10 m**, coroană **9 m**, ușor aplecat | ~1,1 | **altă siluetă** (corectura de sus): trunchiul se desface în **două** de la 3 m, coroana e asimetrică și mai joasă, ca un fag de margine de pădure |
| `plants/bujor_de_munte.glb` | **0,6 m**, **1,2 m** lat | ~0,5 | tufă joasă și deasă, cu **ciorchini de flori magenta** la vârful ramurilor (~40% din suprafața de sus). `Bujor_Leaves`, `Bujor_Bloom` |
| `plants/afin.glb` | **0,5 m**, **0,9 m** lat | ~0,55 | tufă măruntă, verde, cu **bobițe albastru-închis** în puncte mici. `Afin_Leaves`, `Afin_Berry` |

### 1.6 Animale — `build_tf_bear.py`, `build_tf_animals.py`

| fișier | cote | contract |
|---|---|---|
| `animals/brown_bear.glb` **(animat)** | **2,6 m** lung în patru labe (greabăn **1,4 m**), **3,0 m** ridicat | **urs brun** cu fațete mari, pe pipeline-ul vacii (`build_cow_animated.py`) sau al elefantului (mesh propriu + rig per-vertex, memoria `elefant-mesh-importat-rig-per-vertex`). Scheletul îl alege constructorul. **Clipuri:** `Idle`, `Walk`, **`Stand`**. `Stand` = se ridică în două labe și ține poza; `SlidingHazard` îl joacă pe durata telegrafului (1,2 s, `sliding_hazard.gd:108`). Poza `Stand` e cea din `brown_bear_stand.png`: **capul jos între umeri, labele din față atârnând, fără gesturi umane**. Fără root motion (`SlidingHazard` mișcă nodul). Origine la bază, centrată, **fața spre +Y** în Blender (convenția vacii, ca `face_travel` să meargă). AO = gradient vertical, nu raycast (blana se mișcă). Ghearele și botul `VOLCANIC_BLACK`. Azi pe marker stă provizoriu `props/cow.glb` (`model_scale` 0,9). **Fără sânge, fără rană, fără ursul care cade** (brief §8: contactul te oprește pe tine) |
| `animals/sheepdog.glb` **(contract revizuit după val 2)** | **1,0 m** la greabăn, **trunchiul 1,15 m** (umăr–crupă); pieptul adânc ≥ 0,55 din greabăn, burta la ~0,46 m (**peste** `leg_top` 0,45) | ciobănesc românesc (mioritic / carpatin). Rev. 1 citea „oaie palidă” / „capră pe picioroange” din camera de joc. **Trunchi masiv și adânc**; **coama** lățoasă pe gât și piept face fața mai lată decât crupa. **Picioare scurte și groase** (≥ 0,18 m sus), cu „pantaloni” de blană care lărgesc conturul la coapsă, labe late. **Cap mare** (~0,40 m lat), bot scurt și lat, urechi atârnate. **Coada**: smoc mare, stufos, curbat în sus, ca masă aproape cât capul. **Contur lățos**: `clump` (`tf_shapes_nature.py`) pe piept, gât, pantaloni și coadă; fără cutii cu muchii drepte. Corpul `CORAL_SAND`; pata de pe umăr, masca și urechile pe **`ASPHALT_EDGE` 6**, cu margini pe fațete, fără trepte. **Static**, cu **contractul `HerdHazard`** (`herd_hazard.gd:58-62`): **un singur `MeshInstance3D`** (turma ia primul găsit), origine la sol, **−Z înainte în Godot** (+Y în Blender), picioarele sub ~0,45 m, procentul de vârfuri sub 0,45 m raportat. Shader-ul de galop leagănă vârfurile de sub `leg_top`, iar valoarea se reglează la integrare |

### 1.7 Vehicule — `build_tf_vehicles.py`

| fișier | cote | h/l | contract |
|---|---|---:|---|
| `vehicles/parked_car_a.glb` | **la gabaritul mașinii de joc**, adică lățimea și lungimea carcasei din `scenes/cars/Car.tscn`, **măsurate, nu presupuse** | — | **hatchback mic generic** (corectura de sus: **nu Dacia**), proporții de jucărie (roți mari, cabină scurtă), `CAR_BLUE`. Grila e o fantă simplă, farurile sunt dreptunghiuri, plăcuța e goală. Decor static, cu coliziunea a coordonatorului. `Car_Body`, `Car_Glass`, `Car_Tyre` |
| `vehicles/parked_car_b.glb` | ca `a`, cu +15% lungime | — | **break mic / SUV mic generic**, `CAR_RED`, bare de acoperiș și un bagaj pe portbagajul de sus (o cutie de 1,2 m) |
| `vehicles/motorbike.glb` | **2,2 m** lung, 1,3 m înalt | ~0,6 | motocicletă de turism-aventură, generică, pe cric lateral (înclinată ~10°), cu 2 genți laterale. **Fără siglă.** `Moto_Body`, `Moto_Metal` |
| `vehicles/ro_train.glb` *(ultimul val)* | **la scara de joc** (rev. val 3: cifrele vechi de 17 m / 20 m s-au anulat, fiindcă o garnitură de ~87 m dubla timpul de blocaj al drumului): locomotiva **~11 m**, tenderul ~5 m, vagonul **~8,5 m**, înălțimea ~3,6 m fără pantograf, lățimea ~2,9 m; ~45 m cu 3 vagoane (PeruRail ~43) | ~0,25 | locomotivă **electrică** cu pantograf și cabine la ambele capete, roșie cu bandă gri, plus un vagon de călători roșu-gri. **Fără sigle, fără numere.** `TrainHazard` extrage nodurile **după nume**: `Train_Loco`, `Train_Tender` (aici un vagon de bagaje scurt, ca nodul să existe, tiparul PeruRail), `Train_Wagon`. Botul, ecartamentul și baza roților se copiază din `machupicchu/vehicles/perurail_train.glb`: **botul pe +X**, roțile la y = 0 (`machu_picchu_inventory.md:82`). Altfel garnitura plutește sau se înfige în șina procedurală |
| `vehicles/cable_cabin_large.glb` *(ultimul val)* | cabina **~4,2 × 3,4 × 3,3 m**, aproape cub, ca pe planșă (rev. val 3: 5,5 × 3,2 × 3,0 citea butoi) + brațul în A + căruciorul de ~3 m pe cablu; total **~7,3 m** | ~1,5 | cabină **mare** (corectura de sus): o cutie roșie cu colțuri rotunjite pe verticală, **geamuri pe toate laturile** în jumătatea de sus, ca panouri înalte între montanți roșii, cu un brâu roșu plin jos și podea plată. Brațul e un stâlp în A, iar căruciorul e o grindă joasă pe cablu, cu 4 roți. **Originea pe linia cablului** (vârful căruciorului), cu geometria atârnând sub ea (`--origin=rim`). Decor static: Track09 folosea gondola la fel (`DecorManual`) |

### 1.8 Fundal — `build_tf_horizon.py`

`effects/transfagarasan_horizon.glb` cu noduri copii directe ale rădăcinii.
Sunt **volume închise, lizibile din orice azimut, cu originea la bază**.
Consumatorul e `Track._build_horizon`, prin `horizon_model` în tema
`transfagarasan`. Inelul e la **200–340 m**, deci la 300 m camera vede cel
mult **~38 m** peste cota drumului (brief §2.0). Siluetele mai înalte de atât
se taie sus, iar asta e voit.

| nod | cote | contract |
|---|---|---|
| `FagarasRidge_A`, `_B`, `_C` | 160–240 m lungime, **45–70 m** înălțime | creasta zimțată: 5–8 vârfuri pe o bucată, **căldări glaciare** ca scobituri cu zăpadă (`FOAM_WHITE`) și flancuri `MARBLE_GREY`. Una dintre ele are un vârf dominant (Negoiu). Nu un pisc izolat (brief §0.1) |
| `CloudSea_A`, `_B` | 200–300 m lungime, 8–15 m grosime | **marea de nori** din văile depărtate: un strat plat, fațetat, cu bulgări rotunzi pe muchia de sus. `FOAM_WHITE`. Se așază **sub** cota drumului, în văi (brief §1) |
| `FagarasPlain_A` | 300 × 120 m, 2–4 m relief | câmpia Țării Făgărașului: fâșii de câmp (3 verzi, una galben-uscat `DRY_VEGETATION`) și 4–6 pâlcuri de copaci ca mase joase |

Fără coliziune. `cast_shadow` OFF la integrare (memoria
`caster-departat-fura-umbra`).

### 1.9 Ce NU se generează (refolosit sau făcut de cod)

| desen pe planșă / reper | ce se folosește | de ce |
|---|---|---|
| `sheep` | `monumentvalley/animals/sheep.glb` (deja pe `HerdHazard`, `Track21.tscn`) | crem, `Pose_Stand` / `Pose_Walk`, contractul turmei e deja măsurat. Dacă pe captura de joc nu citește „oaie de stână”, se trece la „de refăcut” |
| molizii | `trees/alpine_pines.glb` | brief §5.1 |
| stâlpii telecabinei, stația de jos | `structures/cable_car_pylon.glb`, `buildings/cable_car_station.glb` | brief §5.1 |
| podețul (rupt la săritură), podurile din defileu | `structures/stream_bridge.glb` | brief §5.1 |
| utilajul din tunel, plugul parcat | `vehicles/snowplow.glb` | brief §3.1.2 |
| căruța, stogurile, lemnele, vacile, gardurile | `vehicles/hay_cart.glb`, `props/hay_bale.glb`, `props/wood_stack.glb`, `props/cow.glb`, `structures/wooden_fence.glb` | decor în sat (brief §5.1) |
| bulgării avalanșei | `effects/avalanche_boulders.glb` | brief §3 |
| peticele de zăpadă, florile mărunte | `scatter/snow_patch.glb`, `flowers/flower_cluster.glb` | brief §5.1 |
| blocurile mari, baza de orizont | `rocks/canyon_rocks.glb`, `rocks/rock_large.glb`, `rocks/mountain_peak.glb` | pe `tf_schist`, brief §5.1 |
| trenul, dacă `ro_train` nu ajunge | `vehicles/train.glb` | implicitul lui `TrainHazard` |
| — | parapetele alb-roșii de pe serpentine | `Track._build_parapets` (`custom_parapets`, PR #481) |
| — | cascada | `WaterfallVisual` procedural (Fiordland) |
| — | lacurile, Oltul, terenul, creasta din mijloc | cod (`custom_ravine_water`, `LacBalea`, `TerrainPeak`) |
| — | semaforul de la tunel | `HazardLamp` (PR #481) |
| — | stâlpii și luminile de la trecerea la nivel, trestle-ul | `TrainHazard` |

Doar pentru piesele din tabel: dacă la integrare o piesă refolosită arată
evident altfel decât decuparea ei, coordonatorul o trece în „de refăcut” în
inventar. Nu e treaba setului.

## 2. Livrabile

| fișier | ce |
|---|---|
| `tools/blender/build_tf_{road,landmarks,buildings,rocks,plants,animals,vehicles,horizon}.py`, `build_tf_bear.py` | rulabile headless: `D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- build_tf_road.py`. **Docstring-ul fiecărei funcții de piesă conține lista de elemente** (§0.1 pasul 1), scrisă înainte de primul vertex. Vocabularul comun e în `transfagarasan_shapes.py`: lamă de șist, zid de piatră uscată cu rândul de sus, perete de zăpadă cu trepte, acoperiș de tablă cu fălțuiri |
| `tools/blender/preview_transfagarasan.py` | `--compare <nume>` (decupare ↔ randare), `--views <nume>` (4 azimuturi), `--sheet <val> a,b,c` |
| `tools/blender/verify_transfagarasan.sh` | o rulare, un verdict, excepțiile declarate cu motiv |
| `docs/asset_briefs/transfagarasan_inventory.md` | cote măsurate, tri, noduri, tabele de fidelitate, contracte înghețate (golurile portalurilor, originea barajului, clipurile ursului) și **„Stare la oprire”** |
| `docs/asset_briefs/img/transfagarasan_fidelity/<nume>.png` | comparațiile alăturate |

## 0.1 Fidelitatea față de planșă — criteriul de acceptare

Planșa e sursa de **formă și culoare**. Tabelele de aici, cu corecturile de
sus, sunt sursa de **cote și de contracte de cod**.

1. **Deschide decuparea** și scrie în docstring **lista de elemente**, cu
   numere: câte lame de șist, câte trepte de zăpadă, câte pietre pe creasta
   zidului, câte mase de coroană, câte turnuri la Poenari, ce iese din
   contur. Lista se scrie înainte de primul vertex. Unde o corectură de sus
   contrazice decuparea, lista urmează corectura și o spune.
2. **Modelează după listă**, la cotele din tabel. În rest, proporțiile
   interne ale desenului se păstrează.
3. **Randează comparația** (`preview_transfagarasan.py --compare <nume>`):
   - decuparea în stânga, randarea GLB-ului în dreapta, la aceeași înălțime
     în pixeli;
   - 3/4 din față, lumină de zi neutră, fundal `#C4C4C4`;
   - **culoare reală**: fiecare față pe culoarea slotului ei din atlas
     (recuperat din UV), nodurile `*_Schist` pe `#7E8478`, `*_Snow` pe
     `#E8ECEE`, `*_Concrete` pe `#B8B4AA`.
4. **Verifică pe imagine, element cu element**, nu doar numărând (memoria
   `numaratoarea-trece-amplasarea-nu`): poziția, forma, `h/l` (±15%), ordinea
   luminozităților, ce iese din contur. Rezultatul intră ca tabel în
   inventar: element | pe planșă | în GLB | OK/abatere.
5. **Maximum 3 runde pe piesă.** Dacă tot nu seamănă, abaterea se raportează
   cinstit în inventar, nu se declară „trece”.
6. **Piesa se acceptă doar după ce coordonatorul a văzut comparația.**

## 3. Ordinea de lucru (valuri de ~3 constructori; fiecare cu verify + comparații + commit)

0. **Pilot:** harnasul (`transfagarasan_shapes.py`,
   `preview_transfagarasan.py`, `verify_transfagarasan.sh`) plus
   `tunnel_portal_balea`. **Golul portalului se măsoară ÎNAINTE de orice
   altceva** și se compară cu `mountain_tunnel.glb` scalat, cel care trece
   azi ProbeRace. Coordonatorul judecă comparația înainte de valul 1:
   portalul e locul semaforului.
1. **Valul 1** (gata, 13 oct 2026, integrat pe `transfagarasan/kit-val1`; stare în `transfagarasan_inventory.md`):
   - **tf-a**: restul drumului (§1.1), cu **`snow_wall` primul** (pe lângă
     captura izolată, una cu 4 module înlănțuite pe o curbă) și
     `rock_tunnel_portal` cu golul măsurat;
     după ce `snow_wall` e acceptat, **reface zăpada portalului Bâlea** cu
     același vocabular. Placa, gura și golul nu se ating (inventar,
     „Decizia coordonatorului”);
   - **tf-b**: stâncile și plantele (§1.4, §1.5). **`schist_outcrop_a`
     primul**, apoi **jneapănul**, cu o captură de 8 tufe la 3 m una de alta
     (pâlcul de pe versant) alături de cea izolată;
   - **tf-c**: **ursul** (§1.6), fiindcă e piesa cea mai lungă. Se
     livrează cu capturi din cele trei clipuri: un cadru din `Idle`, două
     din `Walk`, iar `Stand` la început, la jumătate și la capăt.
2. **Valul 2** (gata, 13 oct 2026, integrat pe `transfagarasan/kit-val2`):
   - **tf-d**: barajul și reperele (§1.2), cu **originea barajului
     verificată** (`--origin=rim`, nimic peste −0,05 m pe drum);
   - **tf-e**: clădirile (§1.3). `cabana_balea_lac` se judecă înaintea
     celorlalte;
   - **tf-f**: vehiculele de decor și ciobănescul (§1.6, §1.7, fără tren și
     cabină).
3. **Valul 3** (gata, 13 oct 2026, integrat pe `transfagarasan/kit-val3`):
   - **tf-g**: fundalul (§1.8), **provizoriu**: creasta din runda tf-g,
     norii din reluarea tf-g2, câmpia neschimbată. Verdictul se dă pe
     pista reală;
   - **tf-h**: `ro_train` și `cable_cabin_large`, acceptate după reluarea
     tf-h2.

Lucrează în worktree-ul indicat în prompt (ramura
`transfagarasan/kit-<grupa>`). Nu comite pe `main`, nu folosi `git stash`
(e comun tuturor worktree-urilor), nu face push.
