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
- **CI are o gardă de draw call-uri.** Dacă pică pasul „Draw-call guard", ai
  adăugat probabil un `StandardMaterial3D.new()` într-o buclă de decor: fiecare
  instanță își primește materialul ei, iar asta se plătește direct în fps pe
  mid-range. Folosește `_flat_material()` din `track.gd` (cache pe culoare) și
  cuantifică variațiile de nuanță în câteva trepte, nu continuu. Rulezi local cu:
  ```
  godot --headless --path . --script res://tools/probe_decor.gd
  ```
  Aceeași comandă cu `-- --track=2` raportează o singură pistă.

## 5. Context ca să nu te pierzi (stare curentă, iulie 2026)

- Proiectul a crescut haotic o vreme (un membru a adăugat conținut direct pe
  `main`, fără PR-uri — tema de pistă "Dunele": excavator, dino-landmark,
  sandbox). Conținutul **rămâne** (nu se taie), dar de-acum orice muncă nouă
  trece prin board + PR, nu direct pe `main`.
- **Focus curent: o singură pistă dusă la capăt — Dunele** — înainte de a
  porni piste noi. Layout țintă ~6-7 momente distincte, un gimmick semnătură
  (fly-off + respawn ca plasă de siguranță, plus carusel SAU deviator ca
  element memorabil), props curate prin Blender MCP.
- **Stil vizual**: am decis să mergem peste flat-color pur, spre "stylized"
  (texturi pictate, umbrire coaptă) — testăm pe PC/editor Godot deocamdată,
  nu pe telefon. Checkpoint obligatoriu: primul test pe device real imediat
  după ce Dunele e "done", înainte de piste suplimentare la aceeași
  fidelitate (riscul e să nu încapă în bugetul mobil — vezi "Constrângeri
  mobile 3D" din CLAUDE.md).
- `style.md`/`style_bible.md` — ghidul de stil vizual (paletă, referințe) —
  întreabă echipa de status/locație curentă, nu există încă commis în repo.
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
