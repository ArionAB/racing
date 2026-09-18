# Prototip: sofer de jucarie + ragdoll (buggy deschis)

Stare: **prototip pe o masina si un model**, ramura `feat/ragdoll-buggy`.
Intrebarea la care raspunde: *e amuzant sa vezi figurina zburand din masina
la un accident?*

**Verdictul dezvoltatorului (18 sep 2026): da, e amuzant.** Directia dorita:
*toti* pilotii sa fie ragdoll, in decapotabile de tipuri diferite (nu neaparat
buggy-uri). Deocamdata prototipul ramane asa; garajul deschis e pasul urmator,
nedeschis inca. Documentul de fata spune ce s-a construit, ce reguli s-au
fixat si cum se testeaza.

## Cum se testeaza

- Garaj → **Buggy** (a sasea masina), sau tasta **6** intr-o cursa (debug).
- Pista recomandata: Dunele. Intra frontal intr-un perete la viteza de cursa
  sau sari de pe o creasta de la ~10 m: soferul zboara, camera ramane pe el
  ~1,7 s, apoi masina e repusa pe pista cu soferul la loc.
- Sonda regulilor (headless):
  `godot --headless --fixed-fps 60 --path . res://tools/ProbeEject.tscn`
- Captura momentului (cu fereastra): aceeasi scena cu `-- --capture`,
  salveaza `snapshots/eject_probe.png`.

## Ce s-a construit

| piesa | fisier | rol |
|---|---|---|
| buggy + figurina | `tools/blender/build_toy_buggy.py` → `assets/models/vehicles/toy_buggy.glb`, `toy_driver.glb` | caroserie deschisa cu 4 roti ca noduri separate; figurina din **7 piese rigide** (Hips, Torso, Head, Arm_L/R, Leg_L/R) cu originea in articulatie |
| presetarea | `scenes/cars/data/buggy.tres` | `open_cockpit`, `driver_model`, `driver_seat`, `palette_model` (campuri noi in `CarData`) |
| soferul asezat | `scenes/cars/driver.gd` | poza procedurala din acceleratia masinii: se lasa in viraj, capul se uita in viraj, bratele „tin volanul", in aer ridica bratele |
| ragdoll-ul | `scenes/cars/toy_ragdoll.gd` | fiecare piesa → `RigidBody3D` + cutie din AABB, legate cu `PinJoint3D` in articulatii; simuleaza 2,6 s, ingheata, dispare dupa inca 2,4 s |
| ejectarea | `Car._eject` / `_tick_eject` | semnal `ejected(car, ragdoll)`; comenzile se taie cat tine `eject_hold`, apoi `respawn()` |
| camera | `ChaseCamera.focus_on` | sta pe loc si priveste figurina; `snap_behind` (repunerea) o elibereaza |

## Reguli de design fixate (si de ce)

1. **Ejectarea e vizualizarea repunerii, nu o pedeapsa noua.** La capatul
   ferestrei fara sofer vine `respawn()`, exact ca la orice ratare. Costul
   ramane TIMP, ca peste tot in joc (CLAUDE.md: nu exista stare „distrus").
2. **Nu se ejecteaza din imbranceli intre masini.** Bumping-ul e mecanica
   (principiul 1); pedepsirea lui ar fi pedepsirea jocului. Declansatoarele
   sunt doar peretii (`eject_wall_dv`, 26 m/s delta-v orizontal) si
   prabusirile (`eject_land_speed`, 34 m/s) — praguri masurate, vezi mai jos.
3. **Ragdoll-ul nu se ciocneste cu nicio masina** (exceptii de coliziune pe
   grupul `cars`). Un corp pe asfalt ar fi un obstacol pe care AI-ul nu-l
   vede, iar un contact cu propria masina ar da un impuls fantoma.
4. **Ragdoll-ul nu scrie nimic in starea jocului.** E teatru. ProbeRace
   trebuie sa dea aceleasi cifre cu sau fara el.
5. **AI-ul e ejectat dupa aceleasi reguli** — dar doar din masini deschise.
   Azi e una singura, deci AI-ul (care conduce celelalte 5) nu zboara.

## Ce s-a masurat

`ProbeEject` (toate trecute): o singura ejectare la impact la 29 m/s, 7
corpuri, trunchiul zboara ~5 m in 0,5 s si trece peste o bariera de 1,3 m,
zero contacte ragdoll-masina pe toate cadrele, soferul e inapoi pe scaun
dupa 1,1 s; atingerea la 9 m/s nu ejecteaza; prabusirea de la 24 m (37 m/s)
ejecteaza, saritura de la 12 m (26 m/s) nu.

`ProbeRace` pe Dunele, 150 s, seed 1, buggy pe locul jucatorului: 3,72
tururi (Muscle facea 3,80), o repunere (ejectarea de la un perete), AI-ul
neschimbat ca ritm (2,8–3,6 tururi).

## Garajul deschis (pasul 2, dupa verdict)

Cele 5 FBX-uri RgsDev (inchise) au fost inlocuite cu decapotabile de tipuri
diferite, construite in `tools/blender/build_open_garage.py` (piesele comune —
figurina, rotile, exportul — in `toy_driver_parts.py`). Identitatea din `.tres`
(viteza, grip, masa, suspensie) NU s-a schimbat; s-au schimbat modelul,
dimensiunile si scaunul soferului.

| masina | model | tip | sofer |
|---|---|---|---|
| Muscle | `open_roadster.glb` | roadster lung si jos, doua locuri, aripioare | tricou albastru |
| Politia | `open_police.glb` | roadster usor, capota alba, bara de impingere, girofaruri pe arc | galben |
| Taxi | `open_taxi.glb` | cutie galbena fara acoperis, carouri, firma pe arc, bancheta | verde |
| Autobuzul | `open_bus.glb` | autobuz turistic descoperit, 4 randuri de banci, soferul sus in fata-stanga | rosu |
| Pompierii | `open_firetruck.glb` | cabina deschisa, cisterna, rezervor, scara, furtun | galben |
| Buggy | `toy_buggy.glb` | prototipul | albastru |

Toate au `open_cockpit = true`, deci **toti pilotii, AI inclusiv, sunt
ejectati dupa aceleasi reguli**. Previzualizari: `snapshots/open_*_preview.png`
si `open_garage_lineup.png`. Bugete: 2,5–3,5k triunghiuri per vehicul,
~0,8k per sofer.

## Pragurile, masurate cu tot garajul deschis

Cand toate cele 6 masini au sofer, ejectarea se intampla si AI-ului, deci
pragurile din `Car` au fost tunate pe ProbeRace (150 s, 6 masini), nu pe
impresii. `ProbeRace` are acum coloana `ejec p/a` (perete/aterizare), linii
`[ejectare]` cu cauza si marimea, si „cea mai dura aterizare FARA ejectare"
— cifra care spune cat de aproape e o saritura proiectata de prag.

| prag | initial | final | de ce |
|---|---|---|---|
| `eject_wall_dv` | 18 | **26** | la 18, Dunele dadea 16 ejectari (o masina la ~50 s, cel mai rapid pierdea o jumatate de tur): pragul prindea atingerile oblice de 20–25 m/s. La 26 ramane izbitura frontala. |
| `eject_land_speed` | 24 | **34** | la 24, saritura PROIECTATA peste golul de pe Alpii (frac 0.71, aterizare la 24–30 m/s) arunca fiecare sofer, tur de tur: 11 ejectari. Saritura e distractia, nu accidentul. 34 m/s = cadere de la ~20 m la g=28. |

Dupa tunare (seed 1, 150 s):

| pista | ejectari | cauza | cea mai dura aterizare fara ejectare |
|---|---|---|---|
| Dunele | 7 (seed 2: 4) | toate la tractorul care traverseaza drumul (frac 0.15, 33–49 m/s) si la bariera de la linie (0.997, 26–30 m/s) | 18–20 m/s |
| Alpii | 1 | perete, autobuzul | 28.5 m/s (golul) |
| Cappadocia | 0 | — | 13 m/s |
| Machu Picchu | 1 | perete | 12.5 m/s |

Constatarea colaterala de pe Dunele: AI-ul intra in tractor si in bariera
mobila la viteza maxima, tur de tur — hazarde pe care nu le citeste (vezi nota
de memorie „obstacol pe drum poate fi gimmick"). Inainte costa un ricoseu;
acum costa o ejectare. E o problema de AI, nu de prag, si ramane deschisa.

## Ce ramane deschis

- Sunet propriu pentru ejectare; alte declansatoare (strivire, tren).
- Ejectarea la caderea in gol (repunerea de la −25 m): azi soferul se
  reaseaza tacut, fiindca la adancimea aia camera n-ar vedea figurina.
- Soferi cu identitate pe PILOT (`Race.PILOTS`), nu pe masina: azi culoarea
  tricoului vine din `.tres`, deci doi AI in acelasi model au acelasi sofer.
- Verdictul de feel pe garajul intreg: sunt cele 5 siluete destul de
  diferite intre ele din chase cam? (ProbeRace nu poate raspunde la asta.)
- AI-ul sa citeasca tractorul si bariera de pe Dunele (vezi mai sus).
