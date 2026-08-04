# Style Bible — "Diorámă stilizată"

Direcția vizuală a jocului, cu valori numerice. **Orice asset nou se generează
împotriva acestui document.** Sursa: spec derivat din imaginea de referință
(diorámă miniaturală de deșert), adaptat la constrângerile de mobil.

Documentul a fost scris pentru deșert și rămâne calibrat pe el: toate
măsurătorile din §5, §6 și §14 sunt luate pe Dunele. De la pista Okinawa
încoace acoperă și un mediu **insular** — regulile de formă, scară, material și
compoziție sunt aceleași, doar familia de culori diferă (§1) și atmosfera se
recalibrează per temă (§5).

Referință de ton: *Art of Rally* / machetă de masă — **nu** miniatură fotorealistă.

---

## 1. Paletă

O singură textură pentru toată lumea: `assets/textures/palette_atlas.png`
(**512×512**: 32 de sloturi a câte 16px lățime). Indici și helper:
[scripts/palette.gd](../scripts/palette.gd). Fiecare slot e un patch texturat,
nu un pătrat de culoare uniformă — vezi §4.

| slot | rol | hex | folosit la |
|---|---|---|---|
| 0 | sand_light | `#E8C074` | nisip în soare, vârfuri de faleză |
| 1 | sand_mid | `#D4994D` | majoritatea terenului |
| 2 | sand_shadow | `#915D27` | nisip umbrit, tentă de AO |
| 3 | rock_light | `#C18446` | fețe de stâncă |
| 4 | rock_dark | `#67421F` | interior de faleză, crăpături |
| 5 | asphalt | `#4B4B4D` | șosea |
| 6 | asphalt_edge | `#696765` | margini tocite |
| 7 | kerb_red | `#BB3522` | borduri, marcaje |
| 8 | concrete | `#C8BDA9` | pod, fundații |
| 9 | wood_weathered | `#835C34` | scânduri, garduri |
| 10 | rust_metal | `#91461E` | butoaie, moară, turn de apă |
| 11 | painted_metal | `#7692A8` | containere, ornamente |
| 12 | cactus_green | `#5B7C34` | cactuși, tufe |
| 13 | dry_vegetation | `#AF9F4E` | smocuri de iarbă |
| 14-16 | **accente mașini** | `#E54839` `#2C82E8` `#F2D03C` | **doar mașini**, niciodată decor |
| 17 | reef_shallow | `#54BFB8` | apă peste recif |
| 18 | sea_deep | `#2E5F6B` | larg |
| 19 | coral_sand | `#E9DCC0` | nisip coraligen |
| 20 | volcanic_black | `#55535A` | bazalt de țărm |
| 21 | tropical_green | `#3F7A3C` | vegetație subtropicală |
| 22 | foam_white | `#E9F2F0` | creste de val, spumă |
| 23 | tile_terracotta | `#C4784F` | olane roșii |
| 24-31 | **rezervă** | magenta | negenerate intenționat — o greșeală de UV sare în ochi |

Sloturile 0-13 sunt mediul de **deșert**, 17-23 mediul **insular** (pista
Okinawa). Un asset folosește o familie sau alta, nu le amestecă. Ce n-a primit
slot propriu, fiindcă exista deja ceva potrivit: calcarul Ryukyu ia `concrete`
(8), bărcile sabani și stâlpii de debarcader iau `wood_weathered` (9), bordurile
rămân `kerb_red` (7).

**Regulă de saturație:** mediul stă la 0.45–0.60; mașinile la 0.85–1.00. Așa
mașinile se desprind mereu de fundal.
*Consecință măsurată la adăugarea insulei:* `tile_terracotta` a fost coborât de
la 0.69 la 0.60 saturație. Acoperișurile sunt o suprafață mare, iar un roșu
saturat le-ar fi pus în competiție cu `car_red`.

**Regulă de citire:** asfaltul (slot 5) trebuie să rămână **cea mai închisă
suprafață continuă** din scenă — linia de curs se citește la viteză.
*Consecință măsurată:* `volcanic_black` e `#55535A` (V 0.35), nu un negru real —
bazaltul de recif ar fi coborât sub asfalt (V 0.30) și ar fi mâncat linia de curs.

---

## 2. Scară și proporție

Unitate de referință: **mașina = 4.0 m lungime**.

| obiect | dimensiune |
|---|---|
| bordură | 0.35 m lățime |
| stâncă mică / medie / mare | 0.7 / 2.5 / 7 m |
| perete de faleză | 6–12 m |
| cactus | 2.8–4.5 m |
| turn de apă | 9.5 m |
| moară de vânt | 11 m |
| benzinărie | 8 × 6 × 5 m |
| pod de lemn | 8 m lungime |
| butoi / ladă / cauciuc | 0.9 / 1.1 / 0.9 m |
| stâlp de gard | 1.0 m |

> ⚠️ **Lățimea șoselei rămâne cea de gameplay (12–16 m), NU cei 5.2 m din spec.**
> Vezi §9 Conflicte.

**Trucurile care fac lumea să pară MACHETĂ (nu deșert real):**
- Scară verticală exagerată ×1.18 față de cea orizontală
- Prop-uri așezate nefiresc de aproape de șosea (2–4 m), ca la un mocheta de trenuleț
- Spațiere regulată intenționat (grupuri la 18–25 m), nu geologic realistă
- Marginea terenului tăiată vertical, ca polistirenul decupat
- Obiectele supradimensionate cu 10–20% față de mașină (mai ales cactuși și butoaie)

---

## 3. Limbaj de formă

**Bevel** (consistent peste tot — semnătura care ține stilul unitar):
prop-uri 0.04 m · clădiri 0.08 m · stânci 0.15 m

**Stânci:** 70% rotunjite / 30% fațetate; straturi orizontale la 0.4–0.8 m;
**niciodată colțuroase**. **Acoperișuri:** pantă 18°. Nimic perfect cubic.

**Buget de triunghiuri — scalat cu numărul de INSTANȚE, nu cu importanța.**
Ce se repetă de 100+ ori pe pistă e scump; ce apare o dată e aproape gratis.

- **Umplutură** (zeci–sute de instanțe): stâlp de marcaj 90 · gard 60 · ladă 80 ·
  butoi 120 · cactus 180 · stâncă mare 250 · secțiune de faleză 350
- **Landmark hero** (o instanță pe pistă): **1000–5000**, cât cere silueta

Cifrele de hero au fost 900/1200/1800 și **erau derivate greșit** — din cât de
sărac era jocul în ziua în care le-am scris, nu din vreo constrângere. Prima
benzinărie cu ferestre reale a ieșit 4864 și e perfect în regulă: o instanță,
material comun, zero draw call-uri în plus. Plafonul de pistă din
`probe_decor.gd` (300k din august 2026, upgrade-ul grafic) e garda reală, iar
el are loc berechet. Faleza a urcat de la 200 la 350/secțiune odată cu trecerea
la 12 variante cu siluete distincte — ×130 de instanțe pe Dunele înseamnă ~45k,
acoperit de plafonul nou.

**Ce rămâne strâmt e repetiția.** Un triunghi în plus pe stâlpul de marcaj costă
×24 pe Dunele și ×62 pe Track02. Acolo numără fiecare.

**Stâncile de canion se construiesc în TREPTE** (august 2026, după foaia de
referință a canionului). Lespezi suprapuse, fiecare mai îngustă decât cea de
dedesubt, cu **buză vizibilă** între ele și **fustă de moloz** la bază —
`Builder.mesa()` în dio_lib. Buza e ce se citește de la 100 m, când granulația
texturii s-a topit deja în mipmap; fără ea o stâncă de 8 m și una de 1 m arată
identic, doar la scări diferite. Molozul nu e decor: ascunde linia unde stânca
intră în nisip, care altfel e o elipsă perfectă și trădează obiectul ca lipit
peste teren.

> ⚠️ **`taper` se alege pe clasă de mărime, nu o dată pentru toate.** Pereții
> aproape verticali (0.06) sunt corecți pentru mesa, dar sub ~2 m dau o cutie:
> o treaptă joasă, verticală, cu 5 laturi și fără bevel *chiar e* o cutie.
> Clasa mică merge la 0.30–0.40, adică bolovan rotunjit cu capac plat.

> ⚠️ **Când stivuiești volume, calculează cota din capacul REAL al piesei de
> dedesubt** — `Builder.flat_top_z()`, niciodată o fracție ghicită din înălțime.
> `flat_top=True` retează vârful, deci o piesă cerută de 2 m are capacul la
> 1.64 m (`Builder.FLAT_TOP_FRAC`). Piesa de deasupra ajunge în aer, iar prin
> fantă vezi **spatele peretelui din față** — care e backface și e tăiat de
> culling, deci gaura arată ca o crăpătură spre interiorul stâncii. Nu e o
> greșeală teoretică: în august 2026 aveau fante **18 din 35** de piese de rocă
> din joc (14 stânci de canion, toate cele 3 butte-uri, Cliff_H), până la 91 cm.
> Suprapunerea îngropată e gratis — triunghiurile ascunse există oricum.
> Garda e `check_slits()` / `report_slits()` din dio_lib, apelată din build-urile
> familiei de rocă. NU o rula pe structuri (case, turnuri pe picioare): acolo
> golurile pe verticală sunt intenționate.

**DA:** siluete mari și lizibile, grinzi groase, colțuri rotunjite, spațiu negativ
**NU:** șuruburi mici, balustrade subțiri, stânci zimțate, detaliu de frecvență înaltă

---

## 4. Suprafață și uzură

**Texturi de suprafață DA, texturi unice per asset NU.**

> Revizuit după comparația cu *Reckless Racing 3* și *Beach Buggy Racing* — jocuri
> de mobil care arată mai bine decât noi cu hardware mai slab (BBR rula pe iPhone
> 7). Diferența principală nu e poligonajul, sunt **culorile plate**: la viteză, o
> suprafață de sute de m² fără nicio variație citește ca plastic. Versiunea
> anterioară a acestui paragraf interzicea orice textură; regula era prea strictă
> și ne costa exact lucrul pe care îl invidiam la referințe.

Ce e permis:
- **Atlasul de paletă** (`palette_atlas.png`, 512×512) — dă **culoarea**, câte un
  slot per rol. Generat de
  [tools/generate_palette_atlas.gd](../tools/generate_palette_atlas.gd).

  > ⚠️ Patch-urile texturate din atlas **nu se văd pe prop-uri**. UV-urile lor
  > sunt colapsate pe un punct, deci derivata e zero și fața citește un singur
  > texel. Măsurat: faleza avea deviație **0.76** cu atlas texturat cu tot.
  > Detaliul vine din stratul de mai jos, nu de aici.

- **Stratul de detaliu triplanar** — sursa reală a texturii de suprafață.
  `detail_albedo` + `uv2_triplanar` în `Palette.world_material()`. Triplanarul își
  calculează coordonatele din poziția și normala vârfului, deci **nu citește
  niciun UV**: assets-urile rămân neatinse și materialul rămâne unul singur.
  `uv2_scale = 0.35` → o repetiție la **2.86 m**.

  **Masca per slot** (`detail_mask.png`, 32×1 RGBA) face din slot un canal de
  autorat: nisip/rocă/bazalt 1.00 · lemn 0.85 · beton 0.75 · rugină 0.70 ·
  asfalt 0.55 · olane 0.55 · vegetație 0.45 · bordură 0.35 · metal vopsit 0.30 ·
  apă 0.25–0.30 · spumă 0.20 · **accente mașini 0.00**
  (§1 — mașinile rămân cele mai curate suprafețe din cadru).
  Apa și spuma stau jos deliberat: stratul de detaliu e o textură de *rocă*, iar
  la intensitate mare face marea să arate ca noroi.

- **Texturi tileabile gri** pentru suprafețele mari (teren, șosea, umeri,
  borduri). Astea au UV-uri reale, deci folosesc același strat **fără**
  triplanar. Se înmulțesc peste albedo, deci nu aduc culori noi. Centrul lor e
  **alb**, nu gri mediu — o textură centrată pe 0.5 ar întuneca totul cu 50% și
  ar spăla culoarea.

  Vin din fotografii trecute prin modul GRI al lui
  `process_class_textures.gd`, nu din zgomot procedural. Au **două**
  componente, și asta e o lecție măsurată: prima încercare a folosit doar
  fotografia, cu media și deviația globală normalizate la cele ale texturii
  procedurale — pe hârtie o înlocuire neutră. Măsurat, a ieșit o **regresie**
  (asfalt σ 2.91 → 1.69). Energia unei fotografii stă la frecvențe joase, iar
  sonda din §14 măsoară deviația *înăuntrul* unei dale de 8 px: aceeași deviație
  globală, mutată acolo unde nu se vede la viteză. Fotografia aduce structura
  (pete, crăpături, urme de reparații), granulația procedurală (`grain`) rămâne
  pentru frecvența înaltă — la scară de bloc de 4 texeli.

  > ⚠️ `grain` **nu e un rest istoric**, și s-a demonstrat de două ori. A doua
  > oară a fost în august 2026: la trecerea pe surse la scara corectă părea
  > logic că fotografia aduce ea granulația, așa că a fost tăiat 0.26 → 0.14 pe
  > asfalt. Rezultat măsurat: σ **3.12 → 1.96**, sub valoarea de dinaintea
  > întregii schimbări. Deviația in-dală a texturii finale spune de ce: 18.27
  > înainte, 16.32 după.

  **Fiecare scară își cere propria sursă, la scara ei reală.** Versiunea din
  #132 folosea aceeași fotografie **aeriană** pe ambele treceri. Sursele erau
  scanări de 20 m (nisip) și 30 m (asfalt), afișate la 3.1 și 3.5 m: granulația
  ieșea de ~8 ori prea mică, sub un texel, și o mânca mipmap-ul. Se vedea în
  cifre — asfaltul măsura p25..p75 de 2.76..3.60, adică o panglică fără
  variație. Azi fiecare suprafață are două texturi:

  | trecere | repetiție | sursă | ce dă |
  |---|---|---|---|
  | micro (UV1) | 3.1–3.5 m | scanare de 2–3 m | granulă, agregat, crăpături |
  | macro (UV2) | ~45 m | aeriană de 20–30 m | pete, petice, arce de cauciuc |

  Trecerea macro **nu e doar „pete lente"**: la 10 m de cameră un pixel acoperă
  ~1.3 cm, deci un texel macro se întinde pe ~7 pixeli. E și o a doua sursă de
  granulație, mărită — de aceea are și ea `grain`.

  **Expunerea se ține prin PRODUSUL mediilor**, fiindcă cele două treceri se
  înmulțesc. La nisip produsul se păstrează direct (ambele la 0.850). La asfalt
  nu se putea: ca a doua trecere să nu întunece șoseaua, mediile ar fi trebuit
  la 0.92/0.94, iar acolo `grain` nu mai încape (media plus jumătatea
  amplitudinii trece de 1.0 și vârfurile se retează). Compensarea s-a mutat
  atunci în **culoarea** din `Track._build_road`, împărțită la media macro.

  > ⚠️ **Pe o bandă îngustă, granulația fină nu ajunge niciodată pe ecran.**
  > Umărul șoselei (1.3 m) a primit textură de pietriș la 1.8 m/repetiție — exact
  > scara reală a scanării — și a ieșit perfect **plat**, deși sonda de materiale
  > confirma UV-uri corecte și textura legată. Banda ocupă ~25 px pe ecran chiar
  > în prim-plan, deci îi revin ~15 texeli pe pixel și GPU-ul alege un mip de
  > 32×32, adică media texturii. Șoseaua, cu aceleași UV-uri pătrate, se vede
  > pentru că e de zece ori mai lată. Reparația are două părți: **scară mai mare**
  > (5 m la umeri, 3.5 m la borduri — mai mare decât adevărul, dar vizibilă) și
  > **variație pe vertex color**, care nu trece prin mipmap deloc (petele de praf
  > din `SHOULDER_PATCH_*`, uzura per bucată de bordură din `KERB_WEAR_DEPTH`).
  > Variația pe vertecși e centrată pe 1.0, nu doar întunecătoare — altfel ar
  > coborî luminozitatea medie a benzii și ar strica expunerea în tăcere.

**Cele patru scări de detaliu**, fiecare cu sursa ei — dacă una lipsește, se vede:

| scară | ce dă | de unde vine |
|---|---|---|
| siluetă | forma pe cer | geometrie |
| blocuri 2–4 m | benzi de valoare | `strata_slots` în `Builder.rock()` (sloturi diferite per inel) |
| strate ~0.7 m | linii de rocă | `detail_rock.png`, triplanar |
| granulație ~5 cm | suprafață | aceeași textură, aceeași trecere |

- **Texturi de CLASĂ** (august 2026 — direcția nouă, validată de pilotul
  village_house + conversia Dunelor). O clasă de suprafață = un material cu
  textură reală, partajat de toate assets-urile din clasa aia. Pipeline-ul
  complet, obligatoriu pentru orice textură externă:

  ```
  sursă externă (PolyHaven CC0 / ComfyUI / pachet cumpărat)
    → assets/textures/classes/src/
    → tools/process_class_textures.gd   (512², desaturare + gradare spre
                                          ANCORA de paletă, gain/lift per clasă)
    → Palette.class_material(cls)        (UV-uri reale, ex. proiecție cubică)
      sau Palette.triplanar_class_material(cls)  (UV-uri colapsate, zero
                                          re-export — rocă, metal ruginit)
  ```

  Gradarea spre ancoră NU e opțională: fotografii din surse diferite au
  fiecare lumina și saturația lor, iar nefiltrate dau „asset soup". Gradate,
  devin o extensie a paletei. Clase active: `rock` (faleze/butte/arcadă/
  bolovani, triplanar), `rust_metal` (turn de apă/excavator/conductă
  triplanar; moară pe UV cubic), `wood` (turnul morii),
  `roof_tiles`/`plaster`/`stone_wall` (village_house, UV cubic).

  > ⚠️ **Sursa se alege prin măsurătoare, pe două criterii, nu din miniatură.**
  > Gradarea păstrează luminanța sursei prin construcție — deci nu poate
  > repara o fotografie subexpusă. Prima sursă de lemn (`weathered_planks`)
  > avea media 69/255 față de 97.5 a ancorei, iar turnul morii a ieșit o
  > siluetă neagră în cadru. A doua (`planks_brown_10`, media 102.9) a ieșit
  > din prima. Al doilea criteriu e **uniformitatea luminii pe dală**: prima
  > sursă avea jumătatea dreaptă vizibil mai închisă, iar pe o suprafață care
  > se repetă dezechilibrul ăla devine benzi.
  >
  > Ritualul e o unealtă, nu un snippet rescris de fiecare dată:
  > ```
  > godot --headless --path . --script res://tools/measure_texture_src.gd \
  >     -- --dir=<folder cu candidați> --anchor=D4994D
  > ```
  > Scoate media (cu raportul față de ancoră), deviația globală, deviația
  > **in-dală** și dezechilibrul stânga/dreapta și sus/jos. Pentru o textură
  > **multiplicativă** (suprafețe) media nu contează — se renormalizează oricum;
  > criteriul e cât din deviație stă în-dală, fiindcă normalizarea scalează
  > toate frecvențele cu același factor. Așa a fost aleasă `gravelly_sand`
  > (reține 0.88) în locul aerianei de dinainte (0.735).
  > **Verifică și scara reală a sursei** (`api.polyhaven.com/info/<asset>` →
  > `dimensions`): trebuie să fie apropiată de repetiția din joc.

  **Aceeași clasă poate costa două materiale.** `rust_metal` are azi două
  instanțe pe Dunele: una triplanară (turn de apă, pe UV-uri colapsate) și una
  pe UV-uri reale (moara). Nu e risipă și nu se poate evita — sunt două
  mecanisme de proiecție diferite — dar garda le numără pe amândouă, deci se
  ține minte când se calculează bugetul de 38.

  **Ce rămâne DELIBERAT pe paletă, fără texturi**: mașinile și accentele lor
  (§1), semnele cu text/branding (route66, gas_pole, start_gate — textul e
  pictat prin sloturi și o textură l-ar distruge) și prop-urile mărunte
  (marker_post, scatter, cactus, dino_bones — sub 1 m, textura nu se citește).

  **Ce se mișcă nu primește triplanar de LUME.** Proiecția de lume își ia
  coordonatele din poziția vertexului în scenă: pe un obiect fix e exact ce
  vrem (benzile curg continuu peste secțiuni vecine), pe unul care se mișcă
  textura „înoată" pe suprafață. Varianta corectă e proiecția în spațiul
  **obiectului** (`Palette.object_triplanar_class_material`,
  `uv1_world_triplanar = false`): textura se rotește odată cu mesh-ul.
  Așa merge boulder_roller-ul, pe clasa `rock` a falezelor din care se
  desprinde. Scara se înmulțește cu factorul de scalare al nodului — proiecția
  citește vertecșii *dinainte* de transformare, deci fără corecție un model
  desenat la 5 m și pus în joc la 0.52 ar arăta straturi de două ori mai mari
  decât faleza de lângă el.

Ce rămâne interzis: **texturi unice per asset** (doar per clasă), texturi de
murdărie pictate manual per asset, surse externe nefiltrate prin gradare.

Plafon: atlasul **nu depășește 512×512**; texturile de clasă la fel. Peste
atât se pierde avantajul de VRAM fără câștig vizibil la viteza de joc.

| material | roughness | uzură |
|---|---|---|
| nisip | 0.95 | doar AO din paletă |
| stâncă | 0.88 | fețele de jos spre `rock_dark` |
| asfalt | 0.82 | praf spre `sand_mid` pe margini |
| lemn | 0.80 | fețele de sus decolorate +10% valoare |
| metal ruginit | 0.76 | jos mai închis, sus decolorat |
| metal vopsit | 0.60 | fețele de sus spre `concrete` |
| plastic | 0.55 | doar decolorare ușoară |
| vegetație | 0.90 | jumătatea de jos mai închisă prin AO |

---

## 5. Lumină

| parametru | valoare |
|---|---|
| soare: elevație / azimut | 42° / 315° (din stânga-sus) |
| culoare soare | `#FFD6A3`, intensitate 1.25 |
| ambient / cer | `#C9D9E6` |
| tentă de umbră | `#6B7284` (**nu** gri neutru) |
| moliciune umbre | 0.35 |
| bounce cald din nisip | `#E2B77A`, putere 0.18 |

Godot: `rotation_degrees = Vector3(-42, 135, 0)` pentru soare (elevație 42°,
azimut 315°).

**Unghiul ăsta nu e decorativ.** Codul a stat multă vreme pe `(-48, -30)`: soarele
bătea aproape vertical *și dinspre spatele camerei*, deci umbrele cădeau sub și în
spatele stâncilor, unde nu le vede nimeni. La 42° din stânga, umbra unei faleze de
10 m se întinde ~11 m pe nisip, transversal pe drum — indiciul de volum pe care îl
căutam. Schimbarea unghiului **invalidează calibrarea de expunere**: soarele mai
jos dă mai puțină lumină directă (a fost nevoie de 1.12 → 1.42).

### Umbre dinamice — abatere asumată de la CLAUDE.md

CLAUDE.md cere „umbre ieftine sau blob shadows". Rulăm totuși **umbre reale**, o
singură cascadă ortogonală pe 90 m, decis după comparația cu RR3/BBR: fără contact
cu solul, orice obiect pare lipit peste fundal. Rămâne o singură lumină
direcțională — doar că acum aruncă. Dincolo de 90 m preia ceața, deci lipsa lor nu
se vede.

Comutatorul e **`Track.theme_shadows`**. Dacă primul test pe device nu ține 60 fps,
se stinge de acolo și AO-ul copt rămâne singura sursă de volum.

`CLIFF_AO_STRENGTH` a coborât 0.45 → 0.22 odată cu ele: AO-ul radial și umbra
dinamică **se adună**, iar la 0.45 baza falezelor ieșea aproape neagră.

**Expunerea se calibrează prin măsurare, nu din ochi.** Cerul de deșert e albastru
intens; luat ca sursă de ambient, își lasă nuanța pe tot ce e deschis la culoare —
măsurat, nisipul ieșea `#EAD8CD` (gri-roz) în loc de `#D8A86A`, cu canalul albastru
urcat de la `0x6A` la `0xCD`. Nu era o problemă de luminozitate (roșul și verdele
erau corecte), deci nici expunerea, nici energia soarelui n-o puteau repara: alea
scad toate cele trei canale deodată.

Soluția pe temă de deșert: ambient dintr-o **culoare caldă** (`#E2B77A`, bounce-ul
de nisip din tabelul de mai sus), nu din cer. Plus soare `0.8` și
`tonemap_exposure 0.75` — valori găsite măsurând pixelii dintr-un snapshot față de
ținta din §1, care au coborât eroarea de la 198 la 10 (din 255).

Procedura, dacă trebuie refăcută:
1. `godot --path . res://tools/Snapshot.tscn -- --track=0 --frac=0.2 --size=40`
2. media pe o zonă de nisip, departe de drum
3. comparată cu `#D8A86A`

---

## 6. Atmosferă

Cer: zenit `#6EA9E6` → orizont `#F6D6A8`.
Ceață `#E8CDA3`, începe la 90 m, plină la 250 m (Godot: `FOG_MODE_DEPTH`).
Heat haze foarte subtil (amplitudine 0.005, 0.3 Hz).

La distanță: saturație −15%, contrast −20%, luminozitate +8%.

---

## 7. Compoziție

- Un landmark dominant vizibil la fiecare **4–6 secunde** (la 120–180 m)
- Densitate: **18–25 prop-uri per 100 m** de traseu
- Grupuri de 4–8 obiecte; teren gol în fața landmark-urilor majore
- **Niciodată** prop-uri înalte în apexul virajului (blochează citirea)
- 8 m liberi în zonele de frânare; stânci mari doar pe exteriorul virajelor

---

## 8. Post-procesare

**Implementat (august 2026):** MSAA 2x (`project.godot`, aproape gratis pe
GPU-urile mobile tile-based — se rezolvă în tile memory) și bloom subtil
(`_build_environment`: intensity 0.25, bloom 0.04, threshold 1.1 — peste alb,
deci doar vârfurile reale de lumină înfloresc; nivelurile 2–3 active).
Comutatorul de device e `Track.theme_glow`, a doua setare de stins după
`theme_shadows` dacă testul pe device nu ține 60fps.

Rămase specificate, neimplementate: vignette 0.10 · sharpen 0.08 (candidate de
tăiere — cost fix de fill rate pe tot ecranul, efect vizibil doar în capturi).

**Interzis pe mobil:** SSAO, SSR, volumetrice scumpe, reflexii complexe.
(AO vine copt în vertex colors, nu din ecran.)

---

## 9. Ramă de diorámă

Bază de lemn: înălțime 1.2 m, grosime 0.08 m, culoare `#6A4C35`, mat, muchie de
placaj vizibilă. Nisipul se termină **brusc, tăiat la 90°** — asta vinde scara de
machetă.

Dincolo de ramă: doar cer în cursă. Rama întreagă se vede în meniuri / photo mode
/ camere de replay.

---

## 10. Ce NU se poate real-time (și înlocuitorul)

| lux de render offline | înlocuitor pe mobil |
|---|---|
| depth of field | doar în replay/photo mode |
| global illumination | 1 lumină direcțională + ambient + AO copt |
| bounce path-traced | culoare de ambient caldă |
| detaliu micro de rocă | doar variație de siluetă |
| texturi hi-res | atlas de paletă |
| contact shadows | vertex AO |
| zgârieturi micro | omise complet |
| atmosferă volumetrică | ceață exponențială simplă |

---

## 11. Reguli de coerență (cele care se uită cel mai ușor)

1. **Același bevel** peste tot — altfel obiectele par importate din alt joc.
2. **Rotații în trepte de 15°**, exceptând stâncile și vegetația împrăștiată —
   păstrează senzația de așezat de mână.
3. **Teren: variație max ±3.5 m pe orice 50 m.** Relieful mare se face din
   *assets de faleză* (6–12 m), nu din heightmap. Vezi §12.
4. **Vertex colors pentru AO** pe absolut fiecare asset; zero texturi unice
   *per asset*. Texturi partajate *per clasă* sunt permise dacă sunt decise
   explicit (august 2026, modelul BBR2): `trim_rock.png` e albedo-ul întregii
   clase de rocă (faleze, butte, arcadă, bolovani), aplicat triplanar în
   spațiul lumii prin `Palette.rock_material()` — pietre individuale cu mortar
   și bevel fals pictate, un singur material nou pentru toată clasa. (Restul
   texturii de suprafață vine din stratul partajat — §4.)
5. **Asfaltul rămâne cea mai închisă suprafață continuă.**

---

## 12. Conflicte cu gameplay-ul (decizii luate conștient)

Spec-ul e condus de artă și nu cunoaște pilonii de joc. Două abateri asumate:

**a) Lățimea șoselei.** Spec: 5.2 m. Noi păstrăm **12–16 m**. Pilonul #1 e
*bumping cu masă* între 4 mașini plus depășiri; la 5.2 m (≈2.9 lățimi de mașină)
nu există loc de îmbrânceli, iar startul pe 2 coloane nu încape. Compensăm senzația
de îngustime **vizual**: prop-uri aproape de bandă, faleze care strâng cadrul.

**b) Relief.** Regula ±3.5 m/50 m intră în conflict cu canionul procedural de 24 m
din `track.gd` (`CANYON_HEIGHT`). Rezolvare: terenul rămâne domol (±3.5 m), iar
canionul devine **geometrie de faleză** (assets de 6–12 m) așezată pe margine —
mai aproape și de spec-ul de inventar (35 secțiuni de faleză).

> **Implementat** (august 2026) în [track_cliffs.gd](../scenes/tracks/track_cliffs.gd):
> 6 variante de secțiune (6.5–11 m), lățime 15 m, pas de 14 m cu suprapunere de
> 1 m, ~130 de secțiuni pe Dunele. Fiecare își aduce propria coliziune convexă
> (nodurile `Cliff_X_col` din GLB), toate sub un `StaticBody3D` per latură.
> Gardul roșu de 1.3 m a dispărut complet de pe tema desert.

---

## 13. Ce am învățat construind canionul

Lucruri care nu se deduc din spec și care au costat iterații:

1. **Deciziile de compoziție se iau din vederea șoferului**, nu din snapshot-uri
   ortografice de sus — acelea turtesc tot ce e vertical și mint despre
   densitate. `Snapshot.tscn -- --frac=0.35 --driver`.
2. **Bevel-ul se scalează cu obiectul.** Cei 0.15 m din §3 sunt pentru bolovani
   mari; pe o pietricică de 40 cm o bandă de 15 cm e o treime din obiect și
   dublează triunghiurile. Grupurile mici au primit bevel zero.
3. **Densitatea din §7 (18–25 prop-uri/100 m) e o densitate liniară pe traseu**,
   împărțită pe benzi și pe două laturi. Nu produce singură senzația de canion —
   banda lipită de drum are nevoie de pas mult mai mic decât sugerează cifra.
4. **Un elipsoid dă o movilă, nu un perete.** Falezele au nevoie de o față
   verticală explicită (`taper` mic + `wall_axis`), altfel ies conice.
5. **Piesele mărunte trebuie supradimensionate 40–110%.** La scara reală, o tufă
   de 60 cm pur și simplu nu se vede de la înălțimea camerei.
6. **Un UV colapsat nu vede nicio textură.** Am construit un atlas de 512×512 cu
   granulație și straturi, l-am pus în joc, și n-a schimbat absolut nimic — pentru
   că derivata UV era zero. Trei luni de „hai să facem atlasul mai bun" n-ar fi
   reparat asta; o linie de `uv2_triplanar` a reparat-o.
7. **Sensul unei texturi contează cât conținutul.** `sky_cover` se *adună* peste
   cer, nu se înmulțește: cu norii scriși ca gri-închis pe alb, cerul a ieșit
   complet alb. Verifică întotdeauna dacă textura e aditivă sau multiplicativă
   înainte să-i alegi fondul.

---

## 14. Cum se măsoară

„Arată plat" e o părere. Deviația de luminanță e un număr pe care oricine îl poate
reproduce, și singurul mod onest de a ști dacă o schimbare a ajutat.

```
godot --path . res://tools/Snapshot.tscn -- --track=0 --frac=0.20 --driver
godot --headless --path . --script res://tools/measure_surface.gd \
    -- --image=snapshots/dunele_sofer.png
```

Sonda taie imaginea în dale de 8 px și măsoară deviația **înăuntrul** fiecărei
dale — deci textura de suprafață, nu contrastul dintre obiecte. Dalele reci
(cerul) se ignoră.

| zonă | înainte de stratul de detaliu | după texturi de clasă (aug. 2026) | după surse pe scări (aug. 2026) |
|---|---|---|---|
| faleză | **0.76** | **0.66** | 6.14 ¹ |
| nisip | 1.48 | **2.82** | **4.02** |
| asfalt | 0.93 | **3.27** | **3.42** |
| umăr | — | 2.23 | **4.00** |
| cadru întreg | 1.12 | **3.39** | **3.44** |

¹ Coloana a treia e măsurată A/B față de ramura de bază, pe **aceleași
patch-uri**, la `--frac=0.18` — deci comparabilă doar pe orizontală, în
interiorul ei. Falezei nu i s-a schimbat nimic în lucrarea asta; cifra ei diferă
de coloana vecină doar pentru că patch-ul standard e altul.

> ⚠️ Patch-ul `umar` din `PATCHES_DUNELE` **nu există** — banda e prea îngustă
> pentru un dreptunghi standard. Cifrele de mai sus vin de la
> `--patch=umar:0.0203,0.7444,0.0898,0.7750`, verificat prin eșantionarea culorii
> medii (166,105,59 = praf, nu nisip). Prima variantă a patch-ului cădea de fapt
> pe **nisip** (203,156,87) și „măsura" umărul la 7.96 — un număr care spunea că
> banda plată de plastic e cea mai texturată suprafață din cadru.

> ⚠️ Coloana din dreapta e **remăsurată** pe patch-urile de mai jos, nu copiată
> din PR-uri vechi. Valorile de faleză care circulau înainte (~6 și ~9.4) au fost
> luate pe alte regiuni, la altă fracție de traseu — nu sunt comparabile cu ce
> dă comanda din acest paragraf, iar cifra reală pe patch-ul standard e **0.66**,
> aceeași înainte și după conversia rocii la textură de clasă. Când reiei
> măsurătoarea, compară cu ramura de bază pe **aceleași patch-uri**, nu cu
> tabelul: un număr fără regiunea lui nu înseamnă nimic.

```
--patch=faleza:0.19,0.28,0.42,0.46 --patch=nisip:0.02,0.60,0.30,0.80 \
--patch=asfalt:0.40,0.75,0.62,0.95
```

Referință (imaginile din `assets/dunele_inspiration/`): nisip ~36, stâncă ~40.
**Nu țintim acolo** — aceea e o randare statică de prezentare, iar prea multă
variație la 60 km/h devine zgomot și strică citirea liniei de curs.

> ⚠️ **`--driver` e instrument de măsură, nu captură de ecran.** Parametrii lui
> sunt înghețați în `MEASURE_*` din `snapshot.gd`. Dacă cineva îi „sincronizează"
> cu camera când aceasta se schimbă, toate cifrele σ din istoricul de PR-uri devin
> incomparabile. Pentru compoziție există `--gamecam`.

**Expunerea se verifică separat**, comparând nisipul însorit cu `#D4994D`:

```
godot --path . res://tools/Snapshot.tscn -- --track=0 --frac=0.2 --size=40
```

Prag: eroare ≤ 12/255 per canal. Se reia **de fiecare dată** când se schimbă
stratul de detaliu, unghiul soarelui sau energia luminii — toate trei mișcă
rezultatul, iar valoarea greșită se propagă tăcut în toate deciziile ulterioare de
culoare.
