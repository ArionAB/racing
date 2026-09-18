# Prototip: sofer de jucarie + ragdoll (buggy deschis)

Stare: **prototip pe o masina si un model**, ramura `feat/ragdoll-buggy`.
Intrebarea la care raspunde: *e amuzant sa vezi figurina zburand din masina
la un accident?* Verdictul e al dezvoltatorului, la volan. Documentul de
fata spune ce s-a construit, ce reguli s-au fixat si cum se testeaza.

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
   sunt doar peretii (`eject_wall_dv`, 18 m/s delta-v orizontal) si
   caderile (`eject_land_speed`, 24 m/s).
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
dupa 1,1 s; atingerea la 9 m/s nu ejecteaza; caderea de la 16 m (28 m/s)
ejecteaza, saritura de la 5 m (14 m/s) nu.

`ProbeRace` pe Dunele, 150 s, seed 1, buggy pe locul jucatorului: 3,72
tururi (Muscle facea 3,80), o repunere (ejectarea de la un perete), AI-ul
neschimbat ca ritm (2,8–3,6 tururi).

## Ce NU e decis (si ar urma daca verdictul e „da")

- Restul garajului: cele 5 FBX-uri RgsDev sunt inchise; ar trebui inlocuite
  cu variante deschise (autobuz turistic descoperit, camion de pompieri cu
  cabina deschisa etc.). E costul mare al ideii.
- Soferi cu identitate pe pilot (`Race.PILOTS`): culori pe casca/tricou.
- Alte declansatoare (strivire, tren) si un sunet propriu pentru ejectare.
- Ejectarea la caderea in gol (repunerea de la −25 m): azi soferul se
  reaseaza tacut, fiindca la adancimea aia camera n-ar vedea figurina.
