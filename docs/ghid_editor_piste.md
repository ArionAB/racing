# Ghid: cum iti construiesti propria pista in editor

Ghidul e pentru lucrul VIZUAL, cu mouse-ul, in editorul Godot — fara sa scrii
cod. Totul se sprijina pe `TrackFromPath` (`scenes/tracks/track_from_path.gd`):
tu desenezi traseul si asezi reperele, generatorul construieste restul
(asfalt, borduri, pereti, teren, decor) la fiecare **Regenerate**.

Regula de aur: **doar ce asezi tu de mana se salveaza in scena** (curba,
varfurile de munte, decorul manual). Tot ce genereaza codul se reconstruieste
mereu din ele — deci poti da Regenerate oricand, fara sa strici nimic.

---

## 1. O pista noua, de la zero

1. **Scene → New Scene**, radacina **Node3D**.
2. Trage scriptul `scenes/tracks/track_from_path.gd` peste nodul radacina
   (sau Attach Script si alege-l).
3. Salveaza scena in `scenes/tracks/` — de ex. `Track02.tscn` (PascalCase,
   ca celelalte).
4. Prima data cand se deschide, scriptul isi face singur un nod copil
   **Path** cu un circuit de pornire — ai de unde sa tragi.
5. Pe nodul radacina, in Inspector, seteaza:
   - `custom_name` — numele pistei (apare in meniu si da samanta lumii);
   - `custom_theme` — `forest`, `desert` sau `island`;
   - `custom_half_width` — JUMATATEA latimii soselei, in metri
     (7 = standard; mai ingust = tehnic, mai lat = vitezomanie).

Ca s-o poti juca, adaug-o in `scripts/autoload/game_state.gd`:
`TRACK_SCENES` (calea scenei) si `TRACK_NAMES` (numele afisat). Atat.

---

## 2. Drumul: forma, lungime, cote, inclinare

Selecteaza nodul copil **Path** — punctele curbei apar in viewport, iar sus
apare toolbar-ul Path3D.

- **Muti un punct:** click pe el, trage de sagetile gizmo-ului.
- **Adaugi un punct:** butonul „Add Point" din toolbar, apoi click pe curba
  unde vrei sa-l inserezi. Mai multe puncte = traseu mai lung / mai detaliat.
- **Stergi un punct:** „Delete Point" + click pe el.
- **Cota soselei = Y-ul punctului.** Trage un punct in sus si drumul urca
  acolo. Inclinarea (panta) nu se seteaza separat — e diferenta de Y dintre
  puncte vecine, impartita la distanta dintre ele.
- **Manerele bezier se ignora.** Generatorul isi face singur tangente netede
  (Catmull-Rom) doar din POZITIILE punctelor — nu pierde timp cu ele.

Dupa orice modificare: selecteaza radacina si bifeaza **Regenerate** in
Inspector. Pista se reconstruieste pe loc. Apoi **salveaza scena**.

### Regulile geometrice (platite scump, respecta-le)

- **Raza virajului > half_width** (deci > 7 m la latimea standard). Sub atat,
  asfaltul se pliaza peste el insusi si masinile se blocheaza acolo.
- **Doua portiuni paralele la >= 2 × half_width** una de alta, altfel se ating.
- **Viraj mai strans de ~90°? Pune 3-4 puncte PE arc**, la distante egale —
  cu un singur punct in colt, curba iese mai stransa decat ai desenat-o
  (masurat: 9 m in loc de 14 pe Alpii).
- **Panta sub ~22%**, altfel masina fie decoleaza, fie se tarie.

Arbitrul tuturor regulilor de mai sus e sonda de geometrie — ruleaz-o din
radacina proiectului, in terminal:

```
godot --headless --fixed-fps 60 --path . res://tools/ProbeLayout.tscn -- --track=N
```

(N = indexul pistei in `TRACK_SCENES`; iti spune raza minima, panta maxima si
unde e problema, ca fractie 0..1 din tur.)

---

## 3. Munti si dealuri: nodul TerrainPeak

Terenul urmareste singur soseaua — dar un munte care NU e sub drum nu apare
de la sine: trebuie declarat. Vizual, asta e un nod **TerrainPeak**:

1. Click dreapta pe radacina pistei → **Add Child Node** → cauta
   `TerrainPeak`.
2. Trage-l in viewport unde vrei masivul: **X/Z = unde sta, Y = cota
   varfului** (tragi in sus = munte mai inalt).
3. In Inspector, `radius_m` = raza la care muntele moare in terenul din jur.
   Crucea gizmo-ului se intinde pana la raza, ca sa vezi amprenta.
4. **Regenerate** → terenul se ridica intr-un dom cu zgomot de relief pe
   flancuri (nu un con de strung).

Ce trebuie sa stii ca sa nu te lupti cu el:

- **Asfaltul castiga mereu.** Muntele e stins complet pe o banda de ~6 m de
  la marginea drumului si revine la putere plina abia la ~32 m. Poti trasa
  soseaua in jurul lui sau chiar PESTE el — drumul ramane la cota curbei
  tale, iar muntele se ridica doar pe langa. Intre doua serpentine ramane un
  val de teren la mijloc: citirea corecta de drum taiat in coasta.
- **Vrei drum DE munte, nu drum LANGA munte?** Ridica si punctele curbei
  (Y-ul lor), nu doar varful — terenul de langa drum sta la cota drumului,
  deci urcarea o desenezi tu in curba.
- Mai multe varfuri se combina intre ele (doua dealuri apropiate = o creasta).
- Poti grupa nodurile sub un Node3D „Peaks" ca sa tii scena ordonata —
  cautarea e recursiva.
- Un deal mic = raza mica (20-40 m) si Y mic (5-10 m). Un masiv ca in Alpi =
  raza 130-210 m, varf 120-160 m.

Sonda dedicata (construieste o pista cu si fara varf si compara):

```
godot --headless --fixed-fps 60 --path . res://tools/ProbePeaks.tscn
```

---

## 3b. Scurtaturi: nodul TrackBranch

O a doua banda de asfalt care se desprinde din traseu si revine mai tarziu.
Vizual, e un nod **TrackBranch** (tot un Path3D, deci se deseneaza exact ca
traseul principal).

### Pas cu pas

1. Click dreapta pe radacina pistei → **Add Child Node** → cauta `TrackBranch`.
2. Selecteaza nodul. E gol la inceput, deci trebuie sa-i pui primul punct:
   din toolbar-ul Path3D de sus alege **Add Point** si da click in viewport,
   acolo unde vrei sa INCEAPA scurtatura — **langa sosea**, nu in camp.
3. Mai da click de cateva ori de-a lungul ocolului pe care il vrei. Ultimul
   punct il pui tot **langa sosea**, acolo unde banda revine pe traseu.
4. Ridica punctele pe Y cat sa urmareasca terenul, exact ca la traseul
   principal (cota unui punct = Y-ul lui).
5. In Inspector, pe nodul `TrackBranch`:
   - `branch_half_width` — JUMATATEA latimii benzii. **0 = cat pista.**
   - `wet` — banda uda, cu grip lateral taiat.
   - `label` — nume pentru sonde (gol = numele nodului).
6. Selecteaza **radacina** pistei si bifeaza **Regenerate**.
7. **Salveaza scena.**

Poti pune oricate: fiecare nod `TrackBranch` e o banda. Le poti grupa sub un
`Node3D` ca sa tii scena ordonata — cautarea e recursiva, ca la munti.

### Capetele NU se deseneaza

Tragi doar mijlocul benzii. Unde se desprinde si unde revine se citeste automat
de pe bucla principala, ca punctul cel mai apropiat de primul si de ultimul
punct al curbei tale. Asa muti traseul principal si **scurtatura se reataseaza
singura** — un capat desenat de mana ar fi ramas in urma la prima ajustare si ar
fi lasat o treapta in aer.

De aici iese **singura regula pe care trebuie s-o tii minte: primul si ultimul
punct se deseneaza langa sosea, sub ~25 m.** Mai departe, „cel mai apropiat
punct de pe bucla" devine o intrebare prost pusa: raspunsul e arbitrar si se
schimba din nimic.

Cat de arbitrar — masurat pe scurtatura din cod a Alpilor, ale carei puncte
sunt waypoint-uri de mijloc, nu capete: primul sta la **33.8 m** de asfalt, si
de acolo racordul iese la fractia **0.825** in loc de 0.754. Niciuna nu e
gresita; intrebarea e proasta la distanta aia.

Daca treci pragul, pista se construieste oricum, dar primesti in **Output** un
avertisment cu distanta reala:

```
Track: scurtatura 'Ocolul' pleaca de la 34 m de sosea (prag 25) —
deseneaza capatul LANGA drum, altfel punctul de racord e ales arbitrar
```

**Banda nu apare deloc?** Uita-te tot in Output — sunt doua cazuri in care e
ignorata pe fata, cu mesaj:

- capetele cad pe acelasi punct de pe bucla (ocolul e prea scurt sau prea
  lipit de drum) — **trage-l mai departe de traseu la mijloc**;
- nodul n-are niciun punct desenat.

### Contragreutatea nu e optionala

O scurtatura fara pret e un cadou: o iei mereu, deci nu mai e o decizie. Ai
doua parghii, si se aleg din LUME, nu dintr-un tabel:

| parghie | ce face | exemplu |
|---|---|---|
| `branch_half_width` | mai ingusta: singur incapi, in trafic nu | poteca de pasune din Alpii (3.2 fata de 7.0) |
| `wet` | grip lateral taiat cat timp esti pe ea | bancul de nisip din Okinawa |

(Pentru o portiune uda pe traseul PRINCIPAL, nu pe o scurtatura, vezi
`custom_wet_ranges` la sectiunea 5.)

Scurtatura da **timp, nu progres**: o masina de la jumatatea ei raporteaza
aceeasi fractie de tur ca una de la jumatatea portiunii ocolite, deci
clasamentul si numaratoarea de tururi raman corecte. Nu poti trisa un tur pe
aici, si nici nu trebuie sa-ti faci griji pentru asta.

### Limitele si verificarea

Geometria are aceleasi reguli ca orice curba de pista, si **nu se relaxeaza
aici**: raza virajului > latimea benzii, iar banda sa stea la >= 2× latime de
bucla principala pe portiunile paralele.

Arbitrul e **ProbeRace**, nu ochiul: el spune daca AI-ul chiar trece pe acolo
sau se opinteste la jonctiune. Se uita la timpul petrecut in afara soselei, la
marsarierul de anti-blocaj si la repuneri — exact simptomele unei benzi prea
stramte.

```
godot --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn -- --mode=race --track=N
```

Daca masinile se blocheaza la intrarea sau la iesirea din banda, **largeste
scurtatura** — nu ajusta cifra pana pare bine.

---

## 4. Gropi, rape, prapastii

Perechea pe MINUS a muntilor: `custom_ravines` pe nodul radacina. Fiecare
intrare e un **Vector4 (frac_start, frac_end, adancime_m, latura)**:

- fractiile sunt pozitii pe tur, 0..1 (0 = linia de start, 0.5 = jumatatea
  turului);
- latura: `1` = dreapta sensului de mers, `-1` = stanga, `0` = ambele;
- rapa incepe la cativa metri de asfalt, ca sa nu-ti apara groapa sub roti.

Ca sa afli fractia unui loc: ruleaza ProbeLayout (vezi mai sus) sau numara pe
ochi — fractia creste uniform cu distanta parcursa pe tur.

---

## 4b. Apa care TAIE drumul: nodul TrackChannel

Rapele de mai sus sapa pe LANGA sosea. Un canal trece pe **dedesubt**: terenul
dispare, soseaua ramane cu un gol, iar peste gol se pune ori un pod mobil, ori
o trambulina. E singura structura din joc care rupe drumul in doua.

Vizual, e un nod **TrackChannel** (un Marker3D, ca `TerrainPeak`).

### Pas cu pas

1. Click dreapta pe radacina pistei → **Add Child Node** → cauta `TrackChannel`.
2. Trage nodul in viewport **langa soseaua** pe care vrei sa o taie. Nu trebuie
   sa-l nimeresti exact pe asfalt: canalul taie la punctul de pe traseu cel mai
   apropiat de nod.
3. In Inspector:
   - `gap` — cati metri de sosea LIPSESC. **Vezi avertismentul de mai jos.**
   - `depth` — cat de adanca e albia sub cota drumului.
   - `water_y_drop` — cat de jos sta APA. Diferenta `depth − water_y_drop` e
     grosimea reala a apei (18 − 15 = 3 m: albie larga cu firicel de apa).
     Pune **-1** pe o pista cu mare, si canalul se umple din ea.
   - `water_half` / `bank` — latimea apei si cat de lat urca malul.
   - `reach` / `fade` — cat tine albia in fiecare parte si pe cati metri se
     stinge in terenul din jur.
   - `jump` — **bifat** = trambulina, se trece din saritura. **debifat** = pod
     cu travee ridicatoare, se trece asteptand.
   - `label` — nume pentru sonde (gol = numele nodului).
4. Selecteaza **radacina** pistei si bifeaza **Regenerate**.
5. **Salveaza scena.**

Crucea gizmo-ului se intinde cat `reach`, deci vezi amprenta albiei inainte de
primul Regenerate. Poti pune oricate noduri; se pot grupa sub un `Node3D`,
cautarea e recursiva ca la munti.

### Fractia NU se declara

Ca la scurtaturi: se citeste din pozitia nodului. Muti nodul, se muta taietura
— fara sa remasori nimic. (Distanta se masoara in plan, deci un canal de langa
un drum care urca se agata de bucata de deasupra lui, nu de cea care se
intampla sa fie la aceeasi inaltime.)

### `gap` NU e o cifra libera — se masoara, in DOUA trepte

Asta e capcana care costa cel mai mult timp daca o afli tarziu. Un gol prea
mare nu e "mai greu", e **imposibil pentru jumatate din garaj**.

1. **`tools/ProbeJump.tscn`** — de la ce viteza se trece:
   ```
   godot --headless --fixed-fps 60 --path . res://tools/ProbeJump.tscn -- --track=2
   ```
   Tipareste un tabel viteza → a trecut / a cazut. Masinile au plafoane intre
   **30 si 37 m/s** (autobuzul 30, Muscle 37), plus **11 m/s** cat arde turbo.
2. **`tools/ProbeRace.tscn`** — arbitrul. Sonda de saritura spune ce poate o
   masina; cursa spune ce face PLUTONUL.

Masurat pe Alpii (august 2026), si merita citit ca avertisment:

| `gap` cerut | obtinut | rezultat |
|---|---|---|
| 26 m | 26.8 m | se trecea de la 24 m/s — sub viteza de croaziera a oricui. O formalitate. |
| 38 m | 36.3 m | cerea turbo... dar autobuzul si pompierii cadeau **la fiecare tur**: 16 repuneri intr-o cursa de 150 s. |
| 22 m | 21.8 m | trec toate, zero repuneri, si tot cere viteza. |

Concluzia care se generalizeaza: **"turbo-only" nu incape** cat timp garajul are
masini de 30 m/s si turbo-ul da +11. Daca ProbeRace arata blocaje in albie,
micsoreaza golul — nu cosmetiza cifra.

Retine si ca **golul obtinut difera de cel cerut**: capetele cad pe puncte de pe
curba coapta. Cifra care conteaza e cea tiparita de sonde.

### Ce se mai verifica

- **`depth` sub ~10 m** = masina coboara taluzul rostogolindu-se si se intoarce
  in cursa, deci frica dispare. Peste, o prinde `RespawnZone`.
- **Nu pune landmark-uri pe malul de aterizare.** Un chalet declarat la 4
  miimi dupa rapa a blocat autobuzul la fiecare tur — cladirea are coliziune,
  iar masina vine prin aer si nu o poate evita. Lasa ~2 sectoare libere dupa gol.
- **Nici hazarde mobile peste gol**: un obstacol care matura soseaua exact acolo
  ar matura peste vid.

---

## 5. Restul reperelor de pe radacina (toate ca fractii 0..1)

| Export | Ce pune |
|---|---|
| `custom_ramp_fracs` | rampe de saritura |
| `custom_flyoff_fracs` | creasta care te arunca in aer (cu plasa de respawn — cere o rapa dedesubt!) |
| `custom_hazard_fracs` | obstacol mobil care matura drumul |
| `custom_train_fracs` | trecere de cale ferata cu tren |
| `custom_carousel_fracs` | morisca rotitoare (timing) |
| `custom_deflector_fracs` | bariera oblica (iti schimba linia) |
| `custom_arch_fracs` | arcada de stanca peste drum |
| `custom_gorge_ranges` | defileu: faleze care strang drumul de ambele parti (interval) |
| `custom_landmarks` | cladiri-reper: (fractie, parte ±1, id model — lista in track_from_path.gd) |
| `custom_mine_spots` / `custom_dino_spots` | intrare de mina / sit cu schelet (fractie, parte ±1) |
| `custom_rockfall_fracs` | bolovani care cad de pe faleza |
| `custom_hose_fracs` | conducta sparta care pulseaza apa |
| `custom_wet_ranges` | portiuni UDE de sosea: **interval** (frac_start, frac_end) |
| `custom_wave_fracs` | val care spala soseaua (**cere o tema cu mare**) |

Decor asezat de mana (o stanca exact ACOLO): adauga orice scena din
`assets/models/` ca nod copil, pozitioneaz-o si salveaz-o — supravietuieste
la Regenerate (vezi `docs/decor_manual.md`).

### Portiunile ude: `custom_wet_ranges`

Pe interval, grip-ul lateral scade (de la 8.0 la 3.6 — intre asfalt si drift,
deci **aluneci dar tii linia**) si asfaltul se vede mai inchis la culoare.
Marginile se sting treptat, ca sa nu iasa o dunga trasa cu rigla.

Doua reguli:

- **Udul are nevoie de o CAUZA vizibila.** O balta aparuta din senin intr-un
  desert e o taxa, nu un hazard. Pe Dunele intervalul incepe fix la conducta
  sparta (`custom_hose_fracs = 0.478`, interval `0.478 → 0.53`): apa se scurge
  pe drum dupa ea. Alte cauze bune: un vad, o scurgere de pe stanci, irigatie.
- **Nu e acelasi lucru cu `wet` de pe o scurtatura.** Acolo udul e pretul unui
  ocol mai scurt (ai o alternativa uscata). Aici e pe linia pe care oricum
  mergi, deci nu-ti ofera o alegere de ruta — iti schimba traiectoria si decizia
  de turbo.

Grip-ul se poate schimba per tema cu steagul `wet_grip` (0 = implicitul masinii).

---

## 5b. Pistele definite in COD (Okinawa, Alpii) — si ele editabile

Track08 si Track09 nu au exporturile `custom_*` — traseul, rapele si reperele
lor sunt scrise in `track08.gd` / `track09.gd`. Dar drumul si muntii lor se
pot edita la fel:

1. Deschide scena (ex. `Track09.tscn`) si bifeaza **Regenerate** pe radacina.
   PRIMA bifare creeaza nodul **Path** cu punctele reale ale traseului —
   geometrie identica, doar ca de-acum curba e a ta.
2. Trage de puncte exact ca la orice pista custom (sectiunea 2), Regenerate,
   salveaza scena. Din momentul in care nodul Path exista, el CASTIGA in fata
   punctelor din cod.
3. **Munti:** masivele Alpilor sunt DEJA noduri TerrainPeak in Track09.tscn
   (MasivCentral si UmarulDeSud) — le tragi ca pe orice nod, Regenerate, si
   muntele se muta. Noduri noi se adauga la fel, oriunde. Dupa o mutare
   serioasa, remasoara cu ProbeAlpineTerrain (regulile de calibrare sunt in
   comentariul din `track09.gd`).
4. **Canale:** paraul din valea Alpilor e DEJA un nod TrackChannel in
   Track09.tscn (`ParaulVaii`) — exemplul viu al sectiunii 4b. Il tragi si
   rapa il urmeaza, fara sa remasori fractia. Nodurile se ADUNA la ce declara
   codul in `_channel_specs()`, deci poti folosi si una, si alta.

**Atentie la fractii:** pe pistele din cod, rapele, parapetii si hazardele
sunt legate de fractii de tur MASURATE pentru traseul actual (ex. cornisa
Alpilor la 0.462-0.472). Un retus mic nu strica nimic; o reasezare mare a
traseului muta toate reperele — dupa, ruleaza ProbeLayout si verifica din
masina ca gimmick-urile au ramas unde le e locul.

Daca vrei sa te intorci la traseul din cod: sterge nodul Path si Regenerate.

---

## 5c. Latime variabila: drumul se strange si se deschide

`custom_half_width` da latimea de baza a pistei. Peste ea se pot declara
**sectoare cu latimea lor** — un defileu care strange drumul, o portiune de
start care il deschide.

Deocamdata se declara in cod, cu un script propriu peste `TrackFromPath`:

```gdscript
@tool
extends TrackFromPath

func _width_segments() -> Array[Vector3]:
	# (frac_start, frac_end, half_width)
	return [
		Vector3(0.40, 0.55, 3.5),  # defileu: jumatate din latime
		Vector3(0.80, 0.90, 9.0),  # se deschide inainte de start/finish
	]
```

Fara nicio declaratie, latimea e constanta peste tot — adica exact
comportamentul dinainte, pentru toate pistele existente.

### Ce face singur

- **Trecerea are lungime.** Latimea nu sare de la o valoare la alta: se
  interpoleaza neted pe **30 m** de fiecare parte a sectorului (rampele stau in
  AFARA intervalului, deci pe interiorul lui ai chiar latimea ceruta).
- **Tot ce tine de latime urmeaza profilul**, nu doar asfaltul: bordurile,
  umerii, peretii, chevron-urile, gardurile, hazardele mobile (isi taie cursa
  dupa latimea de la fractia LOR), buza rapelor, malul lagunei si sloturile de
  decor.
- **Penalizarea de offroad** foloseste marginea locala, deci o portiune largita
  nu te mai penalizeaza pe asfaltul ei propriu.
- **AI-ul** isi calculeaza linia cu latimea de la punctul spre care se uita, nu
  cu cea de sub el — altfel ar tinti langa asfalt intrand intr-o strangere.

### De ce 30 m si nu 3

Marginea asfaltului e si marginea fasiei de coliziune. Daca latimea sare cu
3.5 m intre doua inele de drum aflate la ~2 m unul de altul, apare un **prag
lateral** de 3.5 m — iar masina e un `CharacterBody3D` fara step-up, deci un
prag lateral nu e o denivelare, e un **perete**: te opresti in el mergand drept,
in mijlocul soselei. Cu rampa de 30 m, o ingustare de 3.5 m urca la ~0.33 m pe
inel, adica margine oblica.

### Ce se plange in Output

Declaratiile stricate nu opresc pista, dar spun ce n-au inteles: sector gol,
latime negativa, latime sub 2 m (nu mai incape o masina cu spatiu de manevra),
si sectoare care se suprapun (castiga primul). Un sector poate trece peste linia
de start (`Vector3(0.95, 0.05, 4.0)`) — e tratat corect.

---

## 5d. Obstacole trase cu mana: nodul HazardMarker

Tabelul de la 5 pune obstacolele pe **fractii scrise de mana**. Alternativa, si
cea recomandata cand stii UNDE vrei obstacolul dar nu si la ce fractie cade: un
nod **HazardMarker** tras pe sosea in viewport.

### Pas cu pas

1. Click dreapta pe radacina pistei → **Add Child Node** → `HazardMarker`.
2. Trage nodul **pe asfalt**, acolo unde vrei obstacolul. Y-ul e ignorat —
   fiecare gimmick isi aseaza singur cota (bolovanul cade pe asfalt, caruselul
   se planteaza in mijlocul drumului), deci un nod tras prea sus nu lasa nimic
   plutind.
3. In Inspector, `kind`: bariera mobila, bolovan, morisca, tren, tromba,
   deflector, creasta, excavator, avalansa, val (valul cere o tema cu mare —
   altfel se sare, cu avertisment in Output).
4. **Regenerate** pe radacina + **salveaza scena.**

Le poti grupa sub un `Node3D` — cautarea e recursiva, ca la munti.

Avantajul fata de fractii: fractia se **recalculeaza** la fiecare Regenerate din
pozitia nodului. Muti doua puncte de control, si obstacolul ramane pe asfalt in
loc sa alunece pe langa drum.

### Cu ce se imbraca obstacolul (grupul „Model")

Implicit, un obstacol tras in viewport primeste haina TEMEI. Daca vrei alt
obiect exact acolo — o vaca, un car cu fan, o barca — completeaza in Inspector:

| Camp | Ce face |
|---|---|
| `model` | GLB-ul din `assets/models/` (gol = decide tema) |
| `model_scale` | 1.0 = cat l-a construit Blender |
| `face_travel` | se uita incotro merge — **obligatoriu la animale** |
| `roll` | se rostogoleste (doar bolovanii) |
| `tri_class` | clasa de material (ex. `rock`), nu o textura proprie |

Se aplica azi la **bariera mobila** (`SLIDING`); bolovanul si deflectorul isi
construiesc inca vizualul din cod.

Doua reguli care nu-s de gust:

- **`face_travel` la orice are un „inainte".** O vaca care traverseaza cu
  umarul inainte nu traverseaza, pluteste.
- **`roll` doar la bolovani.** Un car cu fan care se da peste cap traversand
  ulita e exact greseala pe care o evita barca sabani din Okinawa.

---

## 6. Ce NU se poate inca vizual (exista in cod, cere-le cand ai nevoie)

- **Borduri pe alese** — bordurile apar automat pe orice viraj peste un prag
  de curbura; nu se pot inca opri/forta pe un viraj anume. Ce POTI face azi:
  le stingi pe toata pista, din tema (`"kerbs": false`, ca pe Alpii), sau le
  lasi peste tot. Granularitatea pe viraj e #235.
- **Latime variabila pe sectoare** — se declara in COD (`_width_segments()`,
  vezi sectiunea 5c), nu inca dintr-un export pe radacina.

---

## 7. Checklist inainte de commit

1. **Regenerate** + salveaza scena.
2. `ProbeLayout` pe pista ta → VERDICT OK (raze, pante, apropieri).
3. Ai desenat scurtaturi? **Verifica Output-ul** dupa Regenerate: un
   avertisment de capat prea departe de sosea inseamna ca racordul e ales
   arbitrar. Apoi `ProbeRace --mode=race` — AI-ul e cel care spune daca banda
   chiar se poate parcurge.
4. Ai pus un **TrackChannel** cu `jump`? `ProbeJump` pentru pragul de viteza,
   apoi **obligatoriu** `ProbeRace` — golul care se trece cu o masina poate
   opri plutonul (vezi tabelul din sectiunea 4b).
5. `probe_decor` daca ai adaugat mult decor manual (bugete tri/materiale).
6. Joaca un tur: e satisfacator drift + saritura + bumping? Intai feel,
   apoi continut.
