# Inventar assets — Serengeti / Ngorongoro (`Track14`)

**33 GLB-uri, ~50.800 triunghiuri, 1,7 MB** în `assets/models/serengeti/`.
Sursa: cele 12 rânduri din planșa de referință `docs/track_briefs/img/serengeti_assets_v1.jpeg`
(+ rândul de flamingi cerut separat) și `docs/track_briefs/serengeti.md` §5.
Verificare: `bash tools/blender/verify_serengeti.sh` → **VERDICT KIT: OK**.
Planșele de control, randate **din GLB-urile exportate**: `docs/asset_briefs/img/serengeti_*.png`
(`preview_serengeti.py`).

| script | ce produce |
|---|---|
| `build_serengeti_animals.py` | gnu, zebră (importate, statice), elefant (rig în cod), hipopotam, crocodil |
| `build_serengeti_rocks.py` | kopje-uri, leul, spărtura, bolovani, termitiere, hoitul cu vulturi |
| `build_serengeti_plants.py` | acacii, fever tree, smochin, euphorbia, baobab, copac uscat, flamingi |
| `build_serengeti_camp.py` | boma Maasai, coarne Ankole, cort, Land Rover, foc, balon aterizat, Lengai, peretele opus |

## Inventar

### `animals/` (5 piese, 5.528 tri)

| fișier | tri | notă |
|---|---:|---|
| `wildebeest.glb` | 868 | **static**, din taurul Quaternius decimat 2418 → 720 + barbă/coamă/coadă Builder; 2,4 m lung, 1,36 m înalt; 30% din vârfuri sub 0,55 m (contractul shader-ului turmei) |
| `zebra.glb` | 680 | static, din Farm Animal Pack decimat 1354 → 680; dungile sunt fețe pe VOLCANIC_BLACK / FOAM_WHITE, nu textură |
| `elephant.glb` | 1.634 | **rig în cod**: 11 oase (Body, Head, Trunk1/2, EarL/R, 4 picioare, Tail), acțiuni `Walk` (1,5 s) și `Trumpet` (telegraful); 3,4 m la umăr, 6,4 m lung |
| `hippo_back.glb` | 1.210 | spinare + cap, 2,5 × 4,8 × 1,35 m, mesh rigid; se urcă/coboară din cod (HippoHazard) |
| `crocodile.glb` | 1.136 | 4 m, static, pe mal |

### `rocks/` (12 piese, 16.500 tri)

| fișier | tri | notă |
|---|---:|---|
| `kopje_camp.glb` | 2.870 | **14 m**, nu 6 ca pe planșă: leul intră în cadru de la 43 m (brief §2 POI A) |
| `lion_kopje.glb` | 1.436 | leu culcat 2,4 m, capul e insulă separată |
| `kopje_kicker.glb` | 1.952 | rampă-pană de 8 × 6 × 2,8 m (19°) cu vârfuri partajate + bolovani; `origin=base_axis`, rampa spre +Y (−Z Godot) |
| `crater_gap.glb` | 5.296 | două fețe de 40 m, **12 m liber** între ele, drumul pe axa Y; `origin=assembly` |
| `kopje_boulder_a/b/c.glb` | 158 / 178 / 178 | 2 / 4 / 6 m, strate MARBLE_GREY / ROCK_DARK |
| `termite_mound_a/b.glb` | 330 / 398 | 1,5 / 3 m, TILE_TERRACOTTA |
| `carcass_vultures.glb` | 2.112 | hoit + 3 vulturi **pe pământ** (brief §2.0: în cer nu se văd) |
| `lengai.glb` | 238 | con de 180 m, 24 de segmente, vârf FOAM_WHITE; la 290–300 m |
| `crater_far_wall.glb` | 5.384 | arc de 200 m de trepte cu pădure pe creastă; la 200 m |

### `plants/` (10 piese, 13.564 tri)

| fișier | tri | notă |
|---|---:|---|
| `acacia_umbrella_a/b/c.glb` | 1.176 / 1.418 / 1.462 | 7 / 8,5 / 10 m, coroană plată lată cât înălțimea, din bulgari turtiți (umbra e identitate → volum închis) |
| `fever_tree.glb` | 1.188 | 10 m, trunchi SAND_LIGHT |
| `fig_tree.glb` | 3.494 | 14 m, coroană densă pe două etaje, licheni FOAM_WHITE — pădurea de ceață (D) |
| `euphorbia.glb` | 1.558 | candelabru 4 m |
| `baobab.glb` | 1.360 | 22 m, **doar siluetă la 150+ m** |
| `dead_tree.glb` | 404 | 6 m |
| `flamingo.glb` / `flamingo_wings.glb` | 692 / 812 | 1,2 m; **slotul 31** (NEON_PINK) — excepție declarată în verify |

### `buildings/`, `props/` (6 piese, 11.146 tri)

| fișier | tri | notă |
|---|---:|---|
| `maasai_boma.glb` | 7.966 | 4 colibe + 40 de mănunchiuri de spini + Maasai cu suliță; shuka = **CAR_RED** (excepție, brief §4) |
| `ankole_horns.glb` | 276 | 1,2 m deschidere, origine la bază: se parentează pe capul lui `props/cow.glb` |
| `safari_tent.glb` | 328 | 3,6 × 4,4 m, cu prelată pe stâlpi |
| `land_rover.glb` | 720 | 4,2 m, decor, CACTUS_GREEN |
| `campfire.glb` | 1.304 | flacăra pe LAVA_ORANGE (emisiv la integrare, reuse shader lavă) |
| `safari_balloon_landed.glb` | 552 | pânză 12 × 8 m pe CAR_YELLOW / TROPICAL_GREEN (excepție), coș WOOD |

`chevron_post` **nu se generează** — reuse din `assets/models/chongqing/props/chevron_post.glb`.

## Ce trebuie știut la integrare

### Abateri de la planșă, cu motiv

- **Gnu-ul și zebra n-au schelet** (brief §3): turma e MultiMesh cu galopul în vertex shader (`HerdHazard._herd_material`), deci mesh-ul e static, în poza de repaus. Placeholder-ul din cutii se înlocuiește cu `wildebeest.glb`; convențiile țin (origine la sol, −Z înainte, picioarele sub 0,55 m).
- **Kopje-ul de start e 14 m**, nu ~6 ca pe planșă (aritmetica frustumului, brief §2 POI A).
- **Hipopotamul are o singură stare** (spinarea); „gura deschisă" de pe planșă nu e o piesă, e o poză, iar HippoHazard nu are animație. Dacă se vrea, e un al doilea GLB.
- **Spărtura e din pereți cu fațete late**, nu din trepte (`mesa` dădea butoaie hexagonale la 40 m). Vezi `serengeti_gap.png`.

### Origini care NU sunt la baza bbox-ului

- `kopje_kicker` (`base_axis`): originea pe axa rampei, ca rampa să se lipească de marginea drumului; rampa e spre +Y Blender = −Z Godot.
- `crater_gap` (`assembly`): originea pe axa drumului, între cele două fețe.
- `lengai`, `crater_far_wall` (`base_axis`): fundal, nu se centrează.
- `elephant`: armătura + mesh; `--origin=assembly` în verify.

### Sloturi de paletă

Zero sloturi noi. Trei excepții declarate în `verify_serengeti.sh`: CAR_RED pe shuka (boma), CAR_YELLOW pe pânza balonului aterizat, **slotul 31** (NEON_PINK, definit de Chongqing) pe flamingi — `verify_glb.py` a primit `--allow-slots=` pentru asta.

### Contracte de gameplay înghețate în geometrie

- **Rampa kicker-ului**: 8 m lungime, 2,8 m înălțime (19°), 6 m lată — o singură pană cu vârfuri partajate; aterizarea peste râu se calibrează în `FlyoffKicker`, nu în mesh.
- **Spărtura**: 12 m liber — drum de 7 m + umeri; sub 12 m nu încape `custom_half_width` 6,5 + umăr.
- **Elefantul**: `Walk` = 36 de cadre la 24 fps (1,5 s), `Trumpet` = 36 de cadre, revine la repaus; SlidingHazard alege după viteză (`Walk`), telegraful cere `Trumpet` explicit — **HazardMarker/SlidingHazard nu știu încă de `Trumpet`**, e treaba integrării.
- **Flamingii**: două stări ca două GLB-uri; „valul de decolare" se face din cod (schimbă mesh-ul instanței + translație).

### Ce NU e făcut

Integrarea în `Track14.tscn` (plantarea pe POI, clasele de textură `savanna_grass` / `laterite_road` / `soda_crust` / `granite`, tema cu `props: "serengeti"`), planșele de control colorate (previzualizarea randează gri, fără atlas — verifică forma, nu culoarea), și `flamingo_far` (billboard-ul din cod, nu din GLB).
