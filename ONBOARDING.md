# Onboarding — Toy Racer

Bun venit în echipă. Citește întâi [CLAUDE.md](CLAUDE.md) (viziune, principii
de design, arhitectură) — e sursa de adevăr a proiectului. Documentul de
față e doar "cum te apuci de treabă", nu o repetă.

## 1. Instalează uneltele

- **Godot 4.7** (exact versiunea — proiectul folosește `config/features
  4.7`): [godotengine.org/download](https://godotengine.org/download)
- **Git** + acces la repo `https://github.com/ArionAB/racing`
- **Blender** (ultima versiune stabilă) — doar dacă lucrezi pe props/artă 3D
- **uv** (package manager Python) — necesar pentru serverul Blender MCP, vezi
  pasul 3

## 2. Clonează și rulează

```
git clone https://github.com/ArionAB/racing.git
```

Deschide `project.godot` în Godot 4.7 și apasă Play (pornește
`MainMenu.tscn`).

Controale desktop: `W/S` accelerare/frână · `A/D` viraj · `Space` drift ·
`R` reset · `1/2/3` schimbă mașina.

## 3. Conectează Blender MCP (dacă lucrezi pe props/artă)

Folosim [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp) —
expune API-ul `bpy` al Blender ca unelte pe care Claude le poate apela direct
în timp ce modelezi.

1. Instalează Blender + `uv`.
2. În Blender: `Edit → Preferences → Add-ons → Install`, selectează
   `addon.py` din repo-ul de mai sus, activează-l. Apare un panou
   "BlenderMCP" în sidebar (tasta `N`) cu buton **Start MCP Server**.
3. În Claude Code: `claude mcp add` ca să înregistrezi serverul (sau
   `Settings → Developer → Edit Config` în Claude Desktop).
4. Test rapid: cere-i lui Claude să genereze un prop simplu (con, cilindru)
   direct în scena deschisă, ca să confirmi conexiunea înainte să te bazezi
   pe ea pentru props reale.

### Ordinea de pornire contează (prima capcană)

**Deschide Blender și apasă „Start MCP Server" ÎNAINTE de a porni Claude
Code.** Serverul `blender-mcp` deschide o conexiune la addon la primul apel și
o ține în cache. Dacă pornește când Blender nu ascultă încă, socket-ul rămâne
mort pentru toată sesiunea — și nu se repară de la sine când deschizi Blender
ulterior.

Simptomul e derutant: fiecare unealtă Blender întoarce

```
Communication error with Blender: Incomplete JSON response received
```

chiar și pentru un `print("ping")`. Pare o problemă în Blender, dar Blender
nici măcar nu primește cererea. Rezolvarea e `/mcp reconnect blender` în
Claude Code, cu Blender deja pornit. Dacă nici asta nu ajută, ai probabil
procese `uvx blender-mcp` orfane din reporniri anterioare —
`Get-Process -Name uv,blender-mcp | Stop-Process`, apoi repornește Claude Code.

### Diagnostic în trei pași

Când ceva nu merge, izolează stratul vinovat înainte să umbli aiurea:

1. **Ascultă portul?** Addon-ul deschide `127.0.0.1:9876`:
   ```powershell
   Get-NetTCPConnection -State Listen | Where-Object LocalPort -eq 9876 |
     Select-Object LocalPort, OwningProcess,
       @{n='Proc';e={(Get-Process -Id $_.OwningProcess).ProcessName}}
   ```
   Nimic afișat → addon-ul nu e activat sau n-ai apăsat „Start MCP Server".
2. **Răspunde addon-ul?** Portul deschis nu garantează că Blender procesează —
   cât timp e în Edit mode sau într-un dialog modal, addon-ul nu răspunde.
   Handshake direct, ocolind complet stratul MCP:
   ```python
   import socket, json
   s = socket.create_connection(("127.0.0.1", 9876), timeout=10)
   s.sendall(json.dumps({"type": "get_scene_info", "params": {}}).encode())
   print(s.recv(65536).decode())
   ```
   JSON cu `"status": "success"` → addon-ul e viu și sănătos.
3. **Merge și prin MCP?** Dacă pasul 2 reușește dar uneltele Claude tot
   eșuează, vina e la procesul `uvx blender-mcp`, nu la Blender — vezi
   secțiunea de mai sus.

Flux practic: brainstorm prop → modelare asistată în Blender (via MCP) →
export `.glb` → import în Godot → **commit inclusiv sursa `.blend`**, nu doar
exportul, ca oricine din echipă să poată modifica ulterior propul.

## 4. Workflow de echipă — reguli obligatorii

- **Nu pusha direct pe `main`.** Branch per task → PR → minim 1 review →
  merge. (`main` a primit direct commit-uri până acum — de-acum, nu mai.)
- **Board**: tab-ul `Projects` din repo (GitHub Projects, integrat, gratuit).
  Ia-ți un task de pe coloana `To Do`, mută-l în `In Progress` cât timp
  lucrezi, PR-ul cu `Closes #N` îl mută automat în `Done` la merge.
- Commit-uri mici, descriptive (uită-te la `git log` pentru stil).
- Pentru schimbări de fizică/gameplay: verificare headless
  (`--headless --fixed-fps 60`) înainte de commit — convenție din CLAUDE.md.
- **CI are o gardă de scenă**, cu două metrici.

  **Materiale (testul principal).** Prag: **maxim 34 pe pistă**, măsurat acum la
  26/23/24/23. Dacă pică cu `MAT`, ai adăugat probabil un
  `StandardMaterial3D.new()` într-o buclă de decor: fiecare instanță își primește
  materialul ei, iar asta se plătește direct în fps pe mid-range. Folosește
  `_flat_material()` din `track.gd` (cache pe culoare) și cuantifică variațiile
  de nuanță în câteva trepte, nu continuu.

  > Testul a fost multă vreme un **raport** mesh-uri procedurale / material, și
  > nu măsura ce credea. Atribuirea pe surse mergea pe numele nodului-părinte,
  > presupunând că rădăcina unui GLB instanțiat se cheamă ca fișierul. Măsurat,
  > se cheamă `@Node3D@571`. Pe Dunele, **372 de prop-uri de pe atlas se numărau
  > ca „procedurale"**, raportul ieșea 16.76 în loc de 1.96, și garda trecea
  > orice. Atribuirea merge acum pe **numele variantei** (`Bush_A`, `Cliff_C`),
  > care e oricum un contract impus în briefuri și în `verify_glb.py`.
  >
  > Chiar reparat, raportul penaliza direcția dorită: cu cât muți mai mult decor
  > pe atlas, cu atât `proc_meshes` scade și raportul cade. Numărul care contează
  > e câte materiale distincte randează o pistă, fiindcă ăla e numărul de draw
  > calls.

  **Triunghiuri.** Raportate la fiecare rulare, prag `MAX_TRIS_PER_TRACK = 150000`.
  **Nu e o limită de hardware** — un telefon mid-range duce câteva sute de mii de
  triunghiuri pe cadru, iar cifra de aici e pe toată pista, din care ceața taie
  tot ce e peste 250 m. E un prag de *alarmă*, calibrat să prindă clasa de
  accident (primitive lăsate la rezoluția implicită, care sar cu zeci de mii
  dintr-un foc), nu un buget de artă. Constrângerea reală pe mobil e draw calls,
  de aceea testul principal e numărătoarea de materiale. Dacă pică cu `TRIS`, uită-te la tabelul pe surse,
  care arată exact de unde vin.

  > Prima măsurătoare a găsit **147k tris pe Dunele**, din care ~110k veneau din
  > primitive Godot lăsate la rezoluția implicită: un `SphereMesh` are 64×32 =
  > 4.224 triunghiuri, deci fiecare tufă de 40 cm avea geometria unei planete.
  > Cu `radial_segments`/`rings` setate, aceeași scenă a coborât la **36k**, fără
  > nicio diferență vizibilă. **Când creezi o primitivă în cod, setează-i
  > segmentele** — implicitul e gândit pentru randare offline, nu pentru mobil.

  Rulezi local cu:
  ```
  godot --headless --path . --script res://tools/probe_decor.gd
  ```
  Aceeași comandă cu `-- --track=2` raportează o singură pistă.

  **Adaugi un GLB nou în lume?** Trebuie trecut în lista `KNOWN` din
  `tools/probe_decor.gd`. Altfel mesh-urile lui sunt puse la socoteală drept
  „procedurale", raportul sare la valori absurde și garda trece orice — devine
  decorativă exact când ai cea mai mare nevoie de ea.

- **Integrezi un asset nou? Verifică ce formă a ieșit coliziunea:**
  ```
  godot --headless --path . --script res://tools/probe_dims.gd
  ```
  Tipărește cotele de coliziune ale prop-urilor mari, citite din AABB-ul
  modelului. Dacă regenerezi un GLB cu alte dimensiuni și cifra de aici **nu**
  se schimbă, ai găsit un număr hardcodat care trebuie scos.

  > Cotele astea stăteau într-un tabel scris de mână și **trei din ele erau deja
  > greșite** față de geometrie: benzinăria declarată 6.0 pe Z când modelul are
  > 6.58 (jumătate de metru de clădire prin care treceai), moara 9.0 când turnul
  > are 10.95, șasiul excavatorului 3.4 când are 5.32. Nimic nu compară un număr
  > dintr-un dicționar cu un mesh.

  **AABB-ul nu e răspunsul peste tot.** Pentru mase compacte (clădiri, turnuri,
  porți, șasiuri) e o aproximare bună. Pentru o piesă **diagonală sau în L** e
  mai rău decât o cutie potrivită de mână: brațul excavatorului măsurat dă 3.60 m
  înălțime pentru un braț de vreo 1 m grosime, fiindcă AABB-ul unei diagonale
  cuprinde tot dreptunghiul din jurul ei. Acolo cutia rămâne scrisă explicit, dar
  **scalată cu modelul**, și se re-potrivește cu sonda când se schimbă rigul.

- **Sonda de cursă fixează mașina jucătorului** (`--car=0`, Muscle, implicit).
  `GameState.selected_car` se salvează în `user://settings.cfg`, deci înainte
  sonda rula pe orice mașină ai ales ultima dată când ai deschis jocul. Două
  rulări ale **aceluiași cod** dădeau 3.96 și 3.57 tururi și arătau ca o regresie
  de la assets. Dacă vrei alt punct de vedere, `--car=3` rulează pe autobuz.

- **Praf și legănat de vegetație** (#29) au sondă proprie, fiindcă nicio altă
  verificare nu le atinge:
  ```
  godot --headless --fixed-fps 60 --path . res://tools/ProbeLife.tscn
  ```
  `--mode=race` raportează `offroad 0.0%` — AI-ul stă pe asfalt tot turul, deci
  praful nu se aprinde niciodată acolo. Iar o captură statică nu poate arăta o
  mișcare. Sonda împinge o mașină în afara șoselei și verifică amplitudinea reală
  a legănatului pe o tufă înregistrată.

  **ProbeLife spune că emitorul pornește; nu spune că se și VEDE ceva.** Pentru
  asta există sonda vizuală, care rulează cursa reală și salvează capturi din
  camera de joc:
  ```
  godot --rendering-driver vulkan --path . res://tools/ProbeFx.tscn
  ```
  A prins două bug-uri pe care `emitting == true` nu le putea prinde: praful
  colorat mai deschis decât nisipul (invizibil pe fundal luminos) și
  `vertex_color_is_srgb` lipsă pe materialele de particule — culorile sRGB
  citite ca liniare ieșeau cu ~1.5 trepte mai deschise, deci TOATE particulele
  din joc randau spălăcit.

- **Schimbi camera? Fotografiază, nu descrie.** Sonda de cameră rulează aceeași
  bucată de cursă (AI cu sămânță fixă, fără adversari) și salvează capturi din
  aceleași puncte, cu setări diferite de cameră:
  ```
  godot --rendering-driver vulkan --fixed-fps 60 --path . res://tools/ProbeCam.tscn \
      -- --preset=ignition [--track=0]
  ```
  Presetările stau în `tools/probe_cam.gd`; `--preset=actuala` fotografiază exact
  camera din joc, deci e coloana de referință a oricărei comparații.

  > Camera a fost tunată de două ori „din amintire" și a rămas de fiecare dată o
  > cameră de NFS. A treia oară, patru variante puse una lângă alta au arătat în
  > zece secunde ce nu se vedea în discuții: în acul de păr cu stânca din mijloc
  > de pe Dunele, la 19° stânca **acoperă ieșirea din viraj**. Tot acolo s-a
  > văzut și că FOV-ul strâmt (52°) omoară senzația de viteză exact cât câștigă
  > înălțimea — de aia camera e sus **și** largă (28.7°, FOV 68).

- **CI verifică și anti-blocajul în pereții de canion.** Aruncă mașini în unghi
  în faleze, în 12 puncte de pe traseu, și pică dacă vreuna rămâne înțepenită.
  ```
  godot --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn -- --mode=cliff --track=0
  ```

- **Pentru decizii de compoziție, folosește vederea de joc:**
  ```
  godot --path . res://tools/Snapshot.tscn -- --track=0 --frac=0.35 --gamecam
  ```
  Snapshot-urile ortografice de sus turtesc tot ce e vertical și **mint despre
  densitatea decorului** — ceva ce de sus pare presărat poate strânge cadrul
  perfect din mașină.

- **Pentru „arată plat?", nu te baza pe ochi — măsoară:**
  ```
  godot --path . res://tools/Snapshot.tscn -- --track=0 --frac=0.20 --driver
  godot --headless --path . --script res://tools/measure_surface.gd \
      -- --image=snapshots/dunele_sofer.png
  ```
  Sonda dă deviația de luminanță pe dale mici, adică **textura de suprafață**, nu
  contrastul dintre obiecte. Cifrele curente și țintele sunt în
  `docs/style_bible.md` §14.

  > ⚠️ `--driver` e **instrument de măsură**, cu parametri înghețați
  > (`MEASURE_*` în `snapshot.gd`). Nu-l sincroniza cu camera când aceasta se
  > schimbă — altfel toate cifrele din istoricul de PR-uri devin incomparabile.
  > Pentru compoziție e `--gamecam`, care citește camera reală.

## 5. Context ca să nu te pierzi (stare curentă, iulie 2026)

- Proiectul a crescut haotic o vreme (un membru a adăugat conținut direct pe
  `main`, fără PR-uri — tema de pistă "Dunele": excavator, dino-landmark,
  sandbox). Conținutul **rămâne** (nu se taie), dar de-acum orice muncă nouă
  trece prin board + PR, nu direct pe `main`.
- **Focus curent: o singură pistă dusă la capăt — Dunele** — înainte de a
  porni piste noi. Layout țintă ~6-7 momente distincte, un gimmick semnătură
  (fly-off + respawn ca plasă de siguranță, plus carusel SAU deviator ca
  element memorabil), props curate prin Blender MCP.
- **Stil vizual**: am trecut de la flat-color pur la "stylized". Reperul e
  **Reckless Racing 3 / Beach Buggy Racing** — jocuri de mobil care arată mai
  bine decât noi cu hardware mai slab (BBR rula pe iPhone 7). Diagnosticul:
  problema nu era poligonajul, erau **culorile plate** și lipsa de contact cu
  solul. Concret: atlas texturat 512×512 (fiecare slot e un patch, nu un pătrat
  de culoare), texturi tileabile pe teren și asfalt, AO copt la baza falezelor.
  **Fără umbre dinamice** — BBR n-are nici el, folosește lumină coaptă.
  Checkpoint obligatoriu: primul test pe device real după ce Dunele e "done".
- **Tema desert e acum canion** (august 2026): pereți de stâncă în loc de gardul
  roșu, decor pe benzi paralele cu drumul, siluete de butte la orizont. Vezi
  `docs/style_bible.md` §12–13 pentru ce s-a implementat și ce am învățat.
- `docs/style_bible.md` — ghidul de stil vizual, **commis în repo**.
- Build mobil (Android/iOS, export presets, CI) — neatins încă, e treabă de
  mai târziu, după ce Dunele e gata.

## 6. Unde găsești lucrurile

- `CLAUDE.md` — viziune, principii de design, arhitectură, roadmap M0-M4
- `README.md` — pitch scurt + cum rulezi
- `assets/models/` — props 3D (`.glb`/`.fbx`); `LICENSE_rgsdev.txt` e
  licența pachetului CC0 folosit pentru mașini
- `scenes/` — organizat pe responsabilitate: `cars/`, `tracks/`, `hazards/`,
  `main_menu/`, `race/`, `ui/`
- `scripts/autoload/` — sisteme globale (`GameState`, `AudioManager`)
- `tools/` — utilitare de dezvoltare (snapshot, generare SFX/texturi)
