# Credite — sursa ecranului CREDITS din joc

Fisierul asta e **sursa unica** a creditelor: ecranul CREDITS din joc
(`scenes/ui/credits_panel.gd`) il citeste la rulare si afiseaza tot ce e in
el. Nu exista nicio alta lista in cod. Ajunge in build-ul exportat prin
`include_filter` din `export_presets.cfg` (un `.md` nu e resursa Godot, deci
fara filtru ar lipsi de pe telefon); garda `ProbeCredits` pica daca filtrul
nu-l mai acopera.

**Gramatica citita de joc** (restul textului e ignorat, deci notele in romana
pot sta liber intre intrari):

- `## Grup` — titlul unei sectiuni pe ecran (in engleza).
- `### Intrare` — un credit; titlul se afiseaza ca atare.
- `- **Cheie:** valoare` — un camp al intrarii, afisat ca `Cheie: valoare`.
  Randurile indentate de sub el continua valoarea. **Cheile si valorile se
  scriu in engleza** — jucatorul le vede asa cum sunt.
- `License` incepe cu un identificator cunoscut (`MIT`, `OFL-1.1`, `CC0-1.0`,
  `CC-BY-4.0`); textul integral al licentei vine din motorul Godot
  (`Engine.get_license_info()`), nu se copiaza aici.
- `Path` (doar pentru addon-uri) nu se afiseaza: leaga intrarea de folderul din
  `addons/`, iar garda verifica ca fiecare addon are intrare si ca linia de
  copyright din `LICENSE`-ul lui e cea de aici.

Ce intra aici: orice sursa externa care ajunge in build, plus mentiunile de
curtoazie pentru sursele CC0 (atribuire neceruta, dar datorata moral). Pentru
**CC-BY** intrarea e conditie a licentei: titlu, autor, sursa, licenta si
modificarile facute. Asset-urile construite din cod (`tools/blender/build_*.py`)
nu au nevoie de intrare. Audio are registrul lui complet, fisier cu fisier:
`docs/audio_licente.md`; aici sta doar rezumatul afisat in joc.

Istoric: modelele CC-BY de pe Fiordland (vaporul „Cruise Ship" de sec20ad002 si
canoea „Canoe - Low Poly" de dannzjs) au fost inlocuite cu modele Builder pe
26 oct 2026 (c2935786, d75031d8); nu mai sunt in joc, deci nici aici.

---

## Game

### Toy Racer
- **Created by:** ArionAB
- **Built with:** Godot Engine (see "Godot Engine" below)

## Fonts

### Barlow Condensed
- **Author:** Jeremy Tribby / The Barlow Project Authors
- **Copyright:** 2017 The Barlow Project Authors
- **License:** OFL-1.1 (SIL Open Font License 1.1)
- **Source:** https://github.com/jpt/barlow (via Google Fonts)

Fontul HUD-ului (SemiBold + Medium), fisierele `.ttf` originale, nemodificate.
Textul integral al licentei e si in `assets/fonts/LICENSE_barlow_OFL.txt`. OFL
nu cere atribuire pe ecran, dar cere ca nota de copyright si licenta sa insoteasca
fontul distribuit — pe telefon fontul e in pachet, deci nota sta aici. Conditiile
pe care le respectam: fontul nu se vinde separat, iar numele rezervat („Barlow")
nu se foloseste pentru o versiune modificata — si nu modificam nimic.

## Audio

### Sound effects
- **Made by:** synthesized in code for this game; no third-party recordings,
  sample libraries or AI-generated audio
- **Music:** none

Registrul complet, fisier cu fisier: `docs/audio_licente.md` (59 de fisiere,
toate din `tools/generate_sfx.gd` / `tools/generate_sfx_car.gd`).

## 3D models and textures

### Quaternius
- **Assets:** low poly models (Ultimate Animated Animals, Stylized Nature
  MegaKit, Train Pack), reshaped and recolored for this game
- **Author:** Quaternius (https://quaternius.com)
- **License:** CC0-1.0 (public domain, attribution not required)

Dovada: `assets/models/LICENSE_quaternius.txt`,
`assets/blender/vendor/train_pack/LICENSE_quaternius.txt`; folosite in
`build_cow_animated.py`, `build_machupicchu_animals.py`,
`build_serengeti_animals.py` (gnu), `build_megakit_*.py`, `build_train.py`.

### RgsDev
- **Assets:** low poly vehicles
- **Author:** Raphael Gonçalves (RgsDev)
- **License:** CC0-1.0 (public domain, attribution not required)

Dovada: `assets/models/LICENSE_rgsdev.txt`, commit e838fa82 (cele 5 `.fbx` din
`assets/models/vehicles/`).

### Kenney
- **Assets:** Watercraft Kit (lift bridge ramp and ship, reshaped)
- **Author:** Kenney (https://www.kenney.nl)
- **License:** CC0-1.0 (public domain, attribution not required)

Dovada: `tools/blender/build_lift_bridge.py` (antet: „Kenney Watercraft Pack
(CC0)"), commit 33bdd13e.

### Poly Haven
- **Assets:** photo textures, regraded to the game palette
- **Author:** Poly Haven (https://polyhaven.com)
- **License:** CC0-1.0 (public domain, attribution not required)

Dovada: comentariile per clasa din `tools/process_class_textures.gd` si
commit-urile 12352dbb, a0952957, c7a50131.

## Software

### Proton Scatter
- **Author:** HungryProton
- **Copyright:** 2019 HungryProton
- **License:** MIT
- **Path:** addons/proton_scatter

### Road Generator
- **Author:** Moo-Ack! Productions (TheDuckCow)
- **Copyright:** 2024 Moo-Ack! Productions
- **License:** MIT
- **Source:** https://github.com/TheDuckCow/godot-road-generator
- **Path:** addons/road-generator

### Waterways
- **Author:** Kasper Arnklit Frandsen
- **Copyright:** 2023 Kasper Arnklit Frandsen
- **License:** MIT
- **Path:** addons/waterways

Addon-ul n-are fisier `LICENSE` in repo; licenta si copyright-ul sunt in antetul
fiecarui script (`# Copyright © 2023 Kasper Arnklit Frandsen - MIT License`).

### Debug Draw 3D
- **Author:** DmitriySalnikov
- **Copyright:** 2026 DmitriySalnikov
- **License:** MIT
- **Source:** https://github.com/DmitriySalnikov/godot_debug_draw_3d
- **Path:** addons/debug_draw_3d

Extensia nativa intra in build-ul de iOS (`.godot/extension_list.cfg`), deci
licenta ei e datorata chiar daca jocul nu o apeleaza.
