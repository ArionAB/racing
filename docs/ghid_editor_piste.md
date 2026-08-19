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
   - `custom_theme` — `forest`, `desert`, `island` sau `baikal` (lac
     inghetat: marea e o placa de gheata pe care se calca, zapada peste tot pe
     uscat, soare jos; se combina cu `custom_ice_ranges`, vezi sectiunea 5);
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
   - `speed_factor` — plafonul de viteza PE banda (1 = cat soseaua, 0.85 =
     taie 15%). Vezi contragreutatea, mai jos.
   - `label` — nume pentru sonde (gol = numele nodului).
   - grupul **Suprafata** — cum ARATA banda (drum de tara, nisip, pietris).
     Vezi „Cum arata scurtatura", mai jos.
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
| `speed_factor` | plafon de viteza mai jos cat timp esti pe ea (0.5..1) | drum de tara: 0.85-0.9 — castigi doar daca o iei curat |

`speed_factor` nu se cumuleaza cu pedeapsa de offroad: pe iarba de LANGA banda
esti offroad (45%), pe banda esti la plafonul ei. Turbo-ul merge si aici.

(Pentru o portiune uda pe traseul PRINCIPAL, nu pe o scurtatura, vezi
`custom_wet_ranges` la sectiunea 5.)

Scurtatura da **timp, nu progres**: o masina de la jumatatea ei raporteaza
aceeasi fractie de tur ca una de la jumatatea portiunii ocolite, deci
clasamentul si numaratoarea de tururi raman corecte. Nu poti trisa un tur pe
aici, si nici nu trebuie sa-ti faci griji pentru asta.

### Cum arata scurtatura: grupul „Suprafata"

Banda NU e un model — e generata din cod, iar aspectul ei se alege din
Inspector, pe nodul `TrackBranch`, grupul **Suprafata**:

| camp | ce face |
|---|---|
| `surface` | reteta. **THEME** = ce spune tema pistei (nisip pe insula, drum de tara pe munte). **DIRT_ROAD** = doua fagase batatorite, brazda de iarba intre ele, margini zdrentuite care se topesc in pajiste, smocuri de iarba pe margini si pe brazda. **GRAVEL** = pietris batatorit, aceleasi margini, fara fagase si fara iarba. **SAND** = banda plata (bancul din Okinawa). |
| `tint` | culoarea pamantului. Alfa 0 = din tema. Se inmulteste cu granulatia texturii, deci alege-o cu ~15% mai deschisa decat vrei s-o vezi. |
| `rut_depth` | adancimea fagaselor (m). 3-5 cm se citesc din umbra; peste 8 arata sapat. Doar vizual — rotile ruleaza pe planul benzii. |
| `grass_center` | cat de inierbata e brazda: 0 = drum umblat des, 1 = poteca prin fan. Da si nuanta, si smocuri. |
| `edge_noise` | cat de neregulate sunt marginile (m). 0 = taiate cu rigla — adica exact „dreptunghi lipit peste teren". |
| `bumpiness` | denivelari de rulare (m amplitudine, gropi si valuri de 1-3 m). **Intra si in fizica**: suspensia le simte, caroseria se leagana. 0.03 = drum de tara, 0.06 = drum forestier. 0 = neted (implicit). |
| `tufts` | smocurile de iarba de pe margini si de pe brazda. Stinge-le daca numeri triunghiuri. |

Dupa orice schimbare: **Regenerate** pe radacina. Ca sa vezi rezultatul din
masina, nu de sus (vederile de sus mint despre margini si iarba):

```
godot --path . res://tools/Snapshot.tscn -- --track=N --route=1 --frac=0.5 --gamecam
```

`--route=1` e prima scurtatura (in ordinea din `Track.routes`: intai cele din
cod, apoi nodurile), iar `--frac` e din lungimea EI, nu din tur.

Ce face motorul pentru tine, ca sa stii ce sa NU incerci sa repari de mana:
- **terenul se aseaza pe banda**: pentru DIRT_ROAD/GRAVEL pajistea se si SAPA
  pana la cota benzii (nu doar se ridica, ca la nisip), deci poti desena poteca
  printr-un deal si ea ramane la vedere. Marginea benzii se ingroapa in teren,
  de aceea linia drumului e neregulata fara sa faci nimic;
- **iarba deasa a soselei ocoleste banda**, iar banda isi pune propriile
  smocuri (`tufts`);
- **praful de la roti** ia culoarea pamantului benzii (`tint`), nu a solului.

Ce trebuie sa faci TU: **capetele desenate sa fie la cota drumului**, iar
coborarea/urcarea sa inceapa dupa 10-15 m, nu chiar din asfalt. O banda care
pleaca de pe sosea si cade 4 m in primii 18 m (scurtatura din cod a Alpilor)
ramane sub teren pe racord: langa asfalt terenul e blocat la cota soselei si
nu se sapa, ca sa nu-i fuga pamantul de sub margine.

### Limitele si verificarea

Geometria are aceleasi reguli ca orice curba de pista, si **nu se relaxeaza
aici**: raza virajului > latimea benzii, iar banda sa stea la >= 2× latime de
bucla principala pe portiunile paralele.

Sonda benzilor spune, punct cu punct, daca banda e sub teren (o banda ingropata
exista in fizica si nu se vede — asa era scurtatura din cod a Alpilor pana in
aug 2026, 58 din 90 de puncte sub pajiste):

```
godot --headless --fixed-fps 60 --path . res://tools/ProbeBranch.tscn -- --track=N
```

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
ochi — fractia creste uniform cu distanta parcursa pe tur. Mai exact, sonda
care tipareste fractia FIECARUI punct de control din nodul Path (plus cota
terenului la 20/50/90 m stanga-dreapta, ca sa vezi daca rapa/muntele au ajuns
acolo, si media cotelor drumului, de care depinde `custom_sea_level_offset`):

```
godot --headless --fixed-fps 60 --path . res://tools/ProbePathFracs.tscn -- --track=N
```

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
| `custom_train_along_fracs` | tren PE SENS (Baikal): sina in lungul soselei, trenul vine din fata; drumul ramane deschis pe margini, moartea e pe axa. Cere ~100 m de drum drept (sina se scurteaza singura la cat e drept); AI-ul stie sa se tina de margine (`Track.lane_bias_at`). Sonda: `ProbeTrainAlong` |
| `custom_hummock_fracs` | torosuri (Baikal): creste de gheata peste culoar, kicker-e naturale mici (0.75 m pe 5.5 m) — la 30 m/s decolezi scurt, la 20 abia saltezi |
| `custom_ice_slab_fracs` | placi de gheata libere care se balanseaza sub masini (Baikal); doar pe `custom_ice_ranges`. Sonda: `ProbeIceSlab` |
| `custom_ice_ranges` | portiuni de GHEATA pe traseu: **interval** (frac_start, frac_end) — alta suprafata, nu asfalt ud: grip ~1.5 (drift-ul devine modul de condus), banda proprie fara borduri/linie/umeri, bete cu stegulete, vantul temei sufla doar aici (tema `baikal`) |
| `custom_cornice_ravines` | care dintre `custom_ravines` sunt CORNISE (indici): buza la 0.5 m de asfalt — drum de munte, viaduct — nu vale lina de fly-off |
| `custom_viaduct_ravines` | care dintre `custom_ravines` sunt VIADUCTE (indici): golul e si SUB sosea, tablierul ramane in aer pe fusta lui, umerii de pietris se sting; dedesubt pui pilele/arcadele din kit sub `DecorManual` (Baikal: `railway_viaduct.glb`, module End/Pier/Arch pe axa, baza la cota drumului − 12.7 / − 13.9 la pile). Se combina cu `custom_cornice_ravines` ca sa cazi de pe margine. Verifici din lateral cu `Snapshot --eye=x,y,z --look=x,y,z` |

Decor asezat de mana (o stanca exact ACOLO): adauga orice scena din
`assets/models/` ca nod copil, pozitioneaz-o si salveaz-o — supravietuieste
la Regenerate (vezi `docs/decor_manual.md`).

### Poarta de start: `custom_gate_model`

Poarta e primul lucru pe care il vezi la countdown, deci tine de identitatea
pistei, nu de mobilierul comun. Se schimba pe **doua** nivele, fiindca sunt
doua intrebari diferite:

- **Pe TEMA** — cheia `gate_model` in intrarea temei din `Track.themes()`.
  O primesc toate pistele temei. Asta vrei cand poarta e a *lumii*: toate
  pistele de Baikal au poarta de busteni.
- **Pe PISTA** — `custom_gate_model` in Inspector, pe nodul radacina, cu
  butonul de fisier. Suprascrie tema. Asta vrei cand doar pista aia are
  poarta ei.

Ordinea e: pista > tema > `Track.DEFAULT_GATE_MODEL`
(`assets/models/structures/start_gate.glb`).

Scrie `none` de mana in campul din Inspector ca sa nu ai **nicio** poarta.

Ce face singur, deci nu ai de potrivit cifre:

- **se scaleaza** pe latimea soselei + 1.2 m degajare pe fiecare parte, din
  bbox-ul masurat al modelului (nu din literale) — acelasi GLB iese 16.4 m pe
  o pista de 14 m si 18.4 m pe una de 16 m;
- **isi ia coliziunea** pe cele doua picioare, la inaltimea masurata;
- **primeste atlasul comun** (`Palette.apply_world_material`), deci GLB-ul are
  nevoie de UV-uri spre sloturi de paleta ca restul assetelor
  (vezi `docs/style_bible.md` §4);
- **se aseaza** pe linia de start, intoarsa pe directia de mers.

Contractul de orientare e cel din tot proiectul: fata de prezentare spre
**+Y in Blender** (= **−Z in Godot**). Poarta se intoarce spre masinile care
VIN, adica in sens invers mersului — `Basis.looking_at(-start_direction())`.
Cu semnul plus, poarta era pe linia de start, scalata corect, cu orientarea
"valida" in orice cifra — dar la countdown vedeai spatele panoului.

In campul din Inspector poti avea fie o cale `res://`, fie un `uid://` (butonul
de fisier scrie UID). Amandoua merg: UID-ul se traduce in cale la citire.

O cale gresita nu te lasa fara poarta in tacere: se plange in Output si cade
pe cea implicita. Sonda: `ProbeGate` — verifica pe fiecare pista ce model a
ajuns efectiv in scena, latimea dupa scalare, pozitia si orientarea.

```
godot --headless --fixed-fps 60 --path . res://tools/ProbeGate.tscn
```

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
   altfel se sare, cu avertisment in Output), placa de gheata (basculant sub
   masini — are sens doar pe o portiune din `custom_ice_ranges`; si prin
   `custom_ice_slab_fracs`), tren pe sens (sina in lungul soselei, vine din
   fata; cere drum drept — si prin `custom_train_along_fracs`).
4. **Regenerate** pe radacina + **salveaza scena.**

Le poti grupa sub un `Node3D` — cautarea e recursiva, ca la munti.

Avantajul fata de fractii: fractia se **recalculeaza** la fiecare Regenerate din
pozitia nodului. Muti doua puncte de control, si obstacolul ramane pe asfalt in
loc sa alunece pe langa drum.

### Toate campurile din Inspector, pe rand

| Camp | Ce face |
|---|---|
| `kind` | tipul de gimmick (lista de la pasul 3) |
| `deflector_side` | **doar pentru deflector**: pe ce parte a soselei sta panta (Dreapta/Stanga). Restul tipurilor o ignora. Nu se deduce din pozitia nodului — un nod tras cu 20 cm peste mijloc ar fi intors panta fara ca nimeni sa fi cerut asta. |
| `model` | GLB-ul din `assets/models/` (gol = decide tema) |
| `model_scale` | 1.0 = cat l-a construit Blender |
| `model_node` | ce PIESA din GLB se pastreaza, cand fisierul are mai multe obiecte (ex. `Driftwood_Log` din `scatter/beach_clutter.glb`); gol = tot fisierul |
| `face_travel` | se uita incotro merge — **obligatoriu la animale** |
| `roll` | se rostogoleste (doar bolovanii din bariera mobila; bolovanul care CADE se rostogoleste oricum) |
| `rock_speed` | **doar pentru bolovan (`ROCKFALL`) cu traseu**: viteza de croaziera pe traseu, m/s (implicit 9). Porneste din loc si accelereaza pana aici. |
| `rock_pause` | **doar bolovan cu traseu**: cat sta ascuns intre doua treceri, secunde (implicit 3) |
| `rock_stick_to_ground` | **doar bolovan cu traseu**: cota din teren (raycast), nu din curba — implicit bifat. Stins = urmeaza exact cota curbei. |
| `motion` | **doar pentru bariera mobila** (`SLIDING`): Pendulare = dus-intors fara oprire (implicitul); Traversare = tractorul din Ignition — asteapta pe acostament, trece, se opreste pe partea cealalta |
| `tri_class` | clasa de material triplanar (ex. `rock`, `snow`), nu o textura proprie; gol = ce da tema |

Din transformul nodului conteaza DOAR pozitia (X/Z — Y-ul e ignorat, vezi
pasul 2). **Rotation si Scale nu fac nimic**: orientarea obstacolului se
deriva din directia drumului, iar marimea vine din `model_scale`. Restul
proprietatilor din Inspector (`gizmo_extents` de la Marker3D) sunt doar
marimea crucii vizuale din editor — scriptul o seteaza la 3 m ca sa vezi
amprenta obstacolului inainte de primul Regenerate.

### Cu ce se imbraca obstacolul (grupul „Model")

Implicit, un obstacol tras in viewport primeste haina TEMEI. Daca vrei alt
obiect exact acolo — o vaca, un car cu fan, o barca — completeaza grupul
„Model" din tabelul de mai sus.

Se aplica azi la **bariera mobila** (model complet), **bolovan** (model +
piesa + scara + clasa; implicit `rocks/boulder_roller.glb`, bolovanul rotund
modelat pentru rostogolire), **morisca** (modelul devine turnul morii de vant,
#245) si **deflector** (model + piesa + scara + clasa). Tren, tromba, creasta,
excavator, avalansa si val isi construiesc vizualul din cod si ignora grupul.

La bolovan orice GLB merge, cu originea unde o fi: hazardul il centreaza pe
cutia lui si il roteste in jurul propriului mijloc, iar raza sferei de
coliziune se masoara din model (`rock_large.glb` cu `model_node = Rock_Large`
la `model_scale` 0.6 e un bolovan coltuos de ~2 m, de exemplu). Modelul
implicit e convex si aproape sferic tocmai ca rostogolirea sa nu se
poticneasca — un model foarte alungit se va vedea „saltand".

Doua reguli care nu-s de gust:

- **`face_travel` la orice are un „inainte".** O vaca care traverseaza cu
  umarul inainte nu traverseaza, pluteste.
- **`roll` doar la bolovani.** Un car cu fan care se da peste cap traversand
  ulita e exact greseala pe care o evita barca sabani din Okinawa.

### Bolovanul cu traseu desenat (`ROCKFALL` + Path3D)

Fara nimic in plus, bolovanul cade pe ciclul vechi: pista masoara singura de
pe ce parte e versantul si piatra coboara pe o dreapta inventata din cod —
care, pe multe portiuni, „pluteste" fara sa vina de undeva anume. Ca sa
spui TU de unde vine si pe unde merge:

1. Sub nodul `HazardMarker` (kind = `ROCKFALL`) → **Add Child Node** →
   `Path3D`.
2. Deseneaza curba cu **Add Point**, din vederea de sus: **primul punct sus
   pe deal sau pe buza falezei** (de acolo se desprinde), apoi peste sosea,
   iar **ultimul punct unde vrei sa dispara** (la poalele peretelui opus, in
   rapa, in vale). Nu-ti bate capul cu cotele — cu `rock_stick_to_ground`
   bifat, piatra isi ia inaltimea din teren cu un raycast si sare de pe buza
   falezei in parabola. Curba e drumul pe care CALCA piatra.
3. **Regenerate** pe radacina + salveaza.

Ce face bolovanul pe traseu: apare la primul punct, prinde viteza pana la
`rock_speed`, se **rostogoleste continuu** (unghiul rotit = distanta parcursa /
raza, tot drumul, si in aer), umbra pe asfalt creste in ultimele 1.4 s inainte
sa treaca peste drum, striveste ce prinde (3 s la 70% din viteza) si il
imbranceste in directia in care mergea, apoi la capatul curbei dispare, sta
`rock_pause` secunde si o ia de la inceput. Ciclul e determinist — cu doua
noduri pe pista, fractia da defazarea.

Nodul HazardMarker ramane pe asfalt (el da fractia si locul umbrei: umbra se
pune sub punctul curbei cel mai apropiat de nod). Un traseu care ocoleste
nodul cu 10 m pune umbra la 10 m de unde cade piatra — semnul ca nodul sau
curba trebuie mutate.

Verificare headless: `tools/ProbeRockfall.tscn` (traseu, rostogolire fara
alunecare, raza masurata din model, strivire).

### Modelele cu schelet se anima singure

Un GLB cu schelet si animatii (vaca Quaternius de pe Alpi) isi alege singur
ciclul, dupa **viteza reala** a obstacolului: parcat **paste** (Eating/Idle),
la pas **merge** (Walk), peste ~3 m/s **galopeaza** (Gallop) — deci aceeasi
vaca paste pe acostament in Traversare si incetineste in capetele pendularii,
fara nicio setare. Conventia numelor de animatii vine din
`tools/blender/build_cow_animated.py`; un GLB fara schelet ramane rigid, ca
pana acum. Verificare vizuala: `tools/ProbeCow.tscn`. Aceeasi conventie o
respecta si testoasa de pe Okinawa (`Walk`/`Idle`, rig facut in cod in
`build_sea_turtle.py`) — pe PathMover se anima singura.

---

## 5e. Figuranti animati pe traiectorie proprie: nodul PathMover

Obstacolele de la 5d stau PE sosea si matura carosabilul. Un **figurant** e
altceva: tractorul care se plimba pe langa drum, barca de pe lac, animalul
care paste intre doua tufe — miscare care da viata lumii, pe margine, fara sa
fie gimmick de cursa. Traiectoria o desenezi tu, exact ca traseul.

### Pas cu pas

1. Click dreapta pe radacina pistei → **Add Child Node** → `PathMover`
   (e un Path3D, deci are acelasi gizmo de desenat curbe ca traseul).
2. Deseneaza traiectoria cu **Add Point**, din vederea de sus, fara grija
   cotelor: cu `stick_to_ground` bifat (implicitul), figurantul isi ia cota
   din teren cu un raycast si urca dealul singur. Il stingi doar pentru barca,
   care sta pe cota curbei (linia apei).
3. In Inspector, grupul de infatisare — acelasi contract ca la HazardMarker:
   - `model` — GLB-ul din `assets/models/` (gol = cutie galbena placeholder,
     gabarit de tractor: se vede din prima ca e substituent, nu arta);
   - `model_node` — ce piesa din GLB se pastreaza (gol = tot fisierul);
   - `model_scale`, `tri_class` — ca la HazardMarker;
   - `model_yaw` — corectie de orientare, in grade: daca figurantul merge cu
     spatele sau cu umarul inainte, de aici se indreapta. (Convenția
     asseturilor e „înainte = −Z"; un GLB exportat corect n-are nevoie de ea —
     vaca a mers cu spatele pe Alpi fiindca era exportata invers, si s-a
     reparat la sursa, in `build_cow_animated.py`, nu de aici.)
   - `animation` — clipul din GLB redat in bucla, cu numele EXACT din fisier
     (vaca are `Idle`, `Eating`, `Walk`, `Gallop`). Gol = automat: un clip de
     mers cand `speed` > 0, unul de repaus cand e parcat. Un nume gresit se
     anunta la consola si cade pe automat.
   - `animation_speed` — viteza de redare a clipului: ciclul de mers e
     exportat pentru un anumit ritm, iar la o `speed` mai mare copitele
     patineaza; de aici se potriveste.
4. Grupul **Miscare**:
   - `speed` — m/s; **0 = parcat**, util cat timp asezi curba;
   - `travel_mode` — **BUCLA** pentru trasee inchise (tractorul da ture;
     inchide curba unde a inceput, altfel se vede teleportarea) sau
     **DUS_INTORS** pentru trasee deschise (animalul intre doua tufe;
     intoarcerea la capete e lina, ca o manevra, nu un snap);
   - `phase` — de unde porneste pe curba (0..1): doi figuranti pe aceeasi
     bucla cu faze diferite nu merg lipiti unul de altul;
5. Grupul **Suflu** (hovercraftul de pe Baikal): `push_radius` — raza (m) in
   care figurantul IMPINGE masinile dinspre el (acceleratie `push_accel`, scade
   liniar cu distanta; 0 = nu impinge); `plume` — jet de zapada in spate cat
   timp se misca. Nu inlocuieste coliziunea, o completeaza: pe gheata iti muta
   linia, pe asfalt abia se simte. Un figurant care trece RAR prin culoar nu e
   hazard — pentru „traverseaza cand vii" foloseste HazardMarker cu `motion =
   Traversare` (5d); suflul e pentru cel care se plimba pe larg.
6. Grupul **Leganare** (pe pivotul vizual, nu pe coliziune): `bob_amplitude`
   = saltare pe verticala (barca pe valuri), `rock_amplitude` = ruliu in jurul
   axei de mers (tractor pe drum de tara), `sway_frequency` = ritmul.
7. **Salveaza scena.** Nodul e al tau, deci supravietuieste la Regenerate, ca
   orice decor manual.

### Ce stie singur

- **Coliziune cinstita**: corpul e AnimatableBody3D cu `sync_to_physics`, ca
  trenul — masina care intra in el se ciocneste real. Dar figurantii NU imping
  inapoi ca obstacolele de pe carosabil: stau pe margine, iar cine iese de pe
  sosea ca sa-i loveasca isi asuma ciocnirea, ca la orice perete.
- **GLB cu schelet** → porneste singur ciclul de mers in bucla (prefera
  animatia „walk", altfel prima din fisier).

Sonda dedicata: `tools/ProbePathMover.tscn`.

---

## 6. Ce NU se poate inca vizual (exista in cod, cere-le cand ai nevoie)

- **Borduri pe alese** — bordurile apar automat pe orice viraj peste un prag
  de curbura; nu se pot inca opri/forta pe un viraj anume. Ce POTI face azi:
  le stingi pe toata pista, din tema (`"kerbs": false`, ca pe Alpii), sau le
  lasi peste tot. Granularitatea pe viraj e #235.
- **Latime variabila pe sectoare** — se declara in COD (`_width_segments()`,
  vezi sectiunea 5c), nu inca dintr-un export pe radacina.
- **Iarba densa de margine** (covorul de fire care se leagana, de pe Alpii) —
  se activeaza per TEMA, in cod: `"dense_grass": true` si plafonul de
  altitudine `dense_grass_max_y` in `themes()` din `track.gd`. Banda
  (0.35–7 m de la asfalt), densitatea si distanta de topire sunt constante in
  `scenes/tracks/track_grass.gd`. Costul e in triunghiuri (axa ieftina), dar
  cifra per pista creste serios — dupa activare ruleaza `probe_decor` si
  ridica pragul pistei DOAR cu masuratoarea in fata.

---

## 7. Checklist inainte de commit

1. **Regenerate** + salveaza scena.
2. `ProbeLayout` pe pista ta → VERDICT OK (raze, pante, apropieri).
3. Ai desenat scurtaturi? **Verifica Output-ul** dupa Regenerate: un
   avertisment de capat prea departe de sosea inseamna ca racordul e ales
   arbitrar. Apoi `ProbeBranch` (banda e la vedere, nu sub teren?) si
   `ProbeRace --mode=race` — AI-ul e cel care spune daca banda chiar se
   poate parcurge.
4. Ai pus un **TrackChannel** cu `jump`? `ProbeJump` pentru pragul de viteza,
   apoi **obligatoriu** `ProbeRace` — golul care se trece cu o masina poate
   opri plutonul (vezi tabelul din sectiunea 4b).
5. `probe_decor` daca ai adaugat mult decor manual (bugete tri/materiale).
6. Joaca un tur: e satisfacator drift + saritura + bumping? Intai feel,
   apoi continut.

---

## 8. Mai multe sesiuni pe acelasi repo (Claude in paralel)

Pe repo lucreaza de obicei mai multe sesiuni deodata, fiecare pe alta
functionalitate. Regulile de mai jos au fost platite fiecare cu un accident:

1. **Fiecare sesiune intr-un `git worktree` propriu**, pe ramura ei
   (`git worktree add -b feat/x .claude/worktrees/x main`). Doua sesiuni pe
   acelasi checkout isi calca una alteia fisierele si scena salvata de una
   ajunge in commit-ul celeilalte.
2. **Niciodata `git stash`.** Stiva de stash e a REPO-ULUI, nu a
   worktree-ului: `git stash pop` scoate stash@{0}, oricine l-ar fi pus.
   S-a intamplat (aug 2026): un pop dintr-un worktree a scos stash-ul altei
   sesiuni si a trebuit reconstruit de mana. Pentru A/B fata de main foloseste
   inca un worktree pe `main` (detached), sau `git show main:cale > temp`.
3. **Niciodata push pe `main`; merge doar prin PR.** Ramura ta se rebazeaza
   pe main inainte de merge, nu invers.
4. **Working tree-ul comun (`d:\GameDev\ignition-spike`) poate avea
   modificari necomise ale dezvoltatorului** (scene desenate in editor).
   Nu le atinge, nu le comite din alta sesiune, nu presupune ca sunt ale
   tale. Daca PR-ul tau schimba comportamentul unei scene pe care el o
   editeaza chiar atunci (ex. noduri `TrackBranch` noi), spune-o in PR.
5. `.godot/` e per worktree: prima rulare intr-un worktree nou cere
   `godot --headless --import --path .` (dureaza ~1 min), altfel sondele
   pica pe resurse neimportate.

