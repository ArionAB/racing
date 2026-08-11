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

---

## 3b. Scurtaturi: nodul TrackBranch

O a doua banda de asfalt care se desprinde din traseu si revine mai tarziu.
Vizual, e un nod **TrackBranch** (tot un Path3D, deci se deseneaza exact ca
traseul principal):

1. Click dreapta pe radacina pistei → **Add Child Node** → cauta `TrackBranch`.
2. Selecteaza-l si deseneaza curba cu toolbar-ul Path3D, ca la traseu.
3. In Inspector: `branch_half_width` (0 = cat pista), `wet`, `label`.
4. **Regenerate** → banda apare, cu materialul de scurtatura al temei.

**Capetele NU se deseneaza.** Tragi doar mijlocul benzii; unde se desprinde si
unde revine se citeste automat de pe bucla principala, ca punctul cel mai
apropiat de primul si de ultimul punct al curbei tale. Asa muti traseul
principal si scurtatura se reataseaza singura — un capat desenat de mana ar fi
ramas in urma si ar fi lasat o treapta in aer.

Din asta iese **singura regula pe care trebuie s-o tii minte: primul si ultimul
punct se deseneaza LANGA sosea** (sub ~25 m). Mai departe, „cel mai apropiat
punct de pe bucla" devine o intrebare prost pusa — raspunsul e arbitrar si se
schimba din nimic. Daca treci pragul, primesti un avertisment in Output care
iti spune exact de la ce distanta s-a agatat.

**Contragreutatea nu e optionala.** O scurtatura fara pret e un cadou: o iei
mereu, deci nu mai e o decizie. Ai doua parghii, si se aleg din LUME, nu dintr-un
tabel:

| parghie | ce face | exemplu |
|---|---|---|
| `branch_half_width` | mai ingusta: singur incapi, in trafic nu | poteca de pasune din Alpii (3.2 fata de 7.0) |
| `wet` | grip lateral taiat cat timp esti pe ea | bancul de nisip din Okinawa |

Scurtatura da **timp, nu progres**: o masina de la jumatatea ei raporteaza
aceeasi fractie de tur ca una de la jumatatea portiunii ocolite, deci
clasamentul si numaratoarea de tururi raman corecte.

Limitele de geometrie sunt cele ale oricarei curbe de pista si **nu se
relaxeaza aici**: raza virajului > latimea benzii, iar banda sa stea la >= 2x
latime de bucla principala pe portiunile paralele. Dupa ce desenezi, ruleaza
**ProbeRace** — el e arbitrul care spune daca AI-ul chiar trece pe acolo.

Sonda dedicata (construieste o pista cu si fara varf si compara):

```
godot --headless --fixed-fps 60 --path . res://tools/ProbePeaks.tscn
```

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

## 6. Ce NU se poate inca vizual (exista in cod, cere-le cand ai nevoie)

- **Borduri pe alese** — bordurile apar automat pe orice viraj peste un prag
  de curbura; nu se pot inca opri/forta pe un viraj anume.
- **Latime variabila pe sectoare** — latimea e inca una singura pe toata pista.
  Jumatate din drum e facuta: toate generatoarele intreaba deja
  `Track.width_at(frac)` in loc sa citeasca `half_width` direct, deci profilul
  pe sectoare e o schimbare intr-o singura functie. Vezi #236.

---

## 7. Checklist inainte de commit

1. **Regenerate** + salveaza scena.
2. `ProbeLayout` pe pista ta → VERDICT OK (raze, pante, apropieri).
3. `probe_decor` daca ai adaugat mult decor manual (bugete tri/materiale).
4. Joaca un tur: e satisfacator drift + saritura + bumping? Intai feel,
   apoi continut.
