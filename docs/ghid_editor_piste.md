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

Decor asezat de mana (o stanca exact ACOLO): adauga orice scena din
`assets/models/` ca nod copil, pozitioneaz-o si salveaz-o — supravietuieste
la Regenerate (vezi `docs/decor_manual.md`).

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
4. `probe_decor` daca ai adaugat mult decor manual (bugete tri/materiale).
5. Joaca un tur: e satisfacator drift + saritura + bumping? Intai feel,
   apoi continut.
