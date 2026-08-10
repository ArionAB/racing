# Decor așezat de mână, direct în editorul Godot

Pistele se construiesc din cod (`Track.rebuild()`): asfalt, pereți, teren,
faleze, decor procedural — tot. Documentul ăsta e despre cealaltă cale: pui tu
un obiect exact unde vrei, cu mouse-ul, în viewportul 3D.

## De ce merge (și de ce nu mergea înainte)

`rebuild()` șterge toți copiii nodului pistă înainte să genereze din nou. Regula
de acum, din `scenes/tracks/track.gd`:

- nod cu `owner == null` → l-a adăugat codul → se șterge la fiecare rebuild;
- nod cu `owner != null` → l-ai așezat tu în editor și s-a salvat în `.tscn` →
  **rămâne**;
- `Path3D` rămâne oricum (curba editabilă).

„Owner" nu e ceva ce setezi tu: orice nod adăugat din editor și salvat în scenă
îl primește automat. Practic: ce vezi în arborele de scene rămâne, ce apare doar
după rulare dispare la următorul rebuild.

## Pașii

1. Deschide `scenes/tracks/Track01.tscn` (Dunele). Scriptul e `@tool`, deci
   pista se construiește singură în editor — vezi terenul și drumul real, nu o
   linie goală.
2. Selectează rădăcina `Track01` → `Ctrl+A` (Add Child Node) → `Node3D` →
   redenumește-l `DecorManual`. E doar un container, ca să nu-ți amesteci
   obiectele printre cele generate.
3. Cu `DecorManual` selectat, apasă butonul de script din dreapta numelui și
   alege „Load" → `scenes/props/world_prop.gd`. Fără el, orice GLB pus dedesubt
   iese **alb**: modelele noastre n-au material propriu, culorile vin din atlasul
   comun, iar scriptul ăsta aplică materialul lumii pe tot subarborele.
4. Din panoul FileSystem, trage un `.glb` din `assets/models/` peste nodul
   `DecorManual` din arbore (ex. `cactus.glb`, `rocks.glb`, `props_junk.glb`,
   `barrel*`, `dino_bones.glb`).
5. Poziționează-l:
   - `F` centrează camera pe obiectul selectat;
   - `W` / `E` / `R` = mutare / rotire / scalare;
   - meniul **Transform** din bara viewportului 3D → **Snap Object to Floor**
     (`PgDown`) îl lipește de teren — terenul are coliziune, deci funcționează;
   - `Ctrl` ținut apăsat activează snap-ul pe grilă.
6. Coliziune, dacă vrei să te lovești de obiect (implicit treci prin el):
   adaugă un `StaticBody3D` ca părinte al modelului și un `CollisionShape3D` cu
   un `BoxShape3D` / `CylinderShape3D` sub el. Pentru decor mărunt (tufe, oase,
   gunoaie) e mai bine fără — mașina care se agață de un cactus e frustrantă.
7. `Ctrl+S`. Rulează cursa (`F5` sau `scenes/race/Race.tscn`) — obiectul e acolo.
   Bifa **Regenerate** din Inspector reconstruiește pista fără să-l atingă.

## Ce NU se pune așa

Hero-assets-urile mari (turn de apă, benzinărie, moară, semn Route 66, ecran
drive-in, stâlp GAS, casă de sat) au deja un sistem propriu: array-ul
`custom_landmarks` din Inspectorul rădăcinii, cu `Vector3(fracție_pe_traseu,
latură ±1, id_model)`. Trecând pe acolo primesc automat coliziunea măsurată din
AABB, distanța corectă față de asfalt, orientarea spre drum și **texturile de
clasă** (lemn, beton, metal ruginit) — vezi tabelul `_LANDMARKS` din
`track.gd`. Puse de mână sub `DecorManual` ar ieși toate pe atlas, adică fără
detaliul de suprafață.

La fel: rampele, hazardele, arcadele, minele, trenul, râpele — toate au câte un
array `custom_*` în Inspector.

## Limite de știut

- **Generatorul nu te vede.** Decorul procedural nu evită obiectele tale; se
  poate suprapune. Dacă se întâmplă, mută-l tu.
- **Terenul se poate schimba sub tine.** Dacă tragi de punctele curbei, relieful
  se recalculează și obiectele pot rămâne suspendate sau îngropate — refă
  Snap Object to Floor.
- **Bugetul rămâne bugetul.** După o sesiune de așezat, rulează garda:
  `godot --headless --path . --script res://tools/probe_decor.gd -- --track=8`.
  Contează mai ales numărul de materiale, nu triunghiurile. (Atenție: aici
  `--track=` e numărul din numele fișierului — sonda își compune singură calea
  `Track%02d.tscn` — pe când `probe_manual.gd` de mai jos ia indexul din
  `GameState.TRACK_SCENES`. Aceeași pistă, două numere.)

## Grupare pe zone

La câteva zeci de obiecte, o listă plată sub `DecorManual` nu se mai poate citi.
De aceea decorul se pune în `Node3D`-uri de zonă, numite după secțiunile
traseului din scriptul pistei (`Zone01_StartCauseway`, `Zone02_Harbour`, …). Așa
poți ascunde toate zonele în afară de cea la care lucrezi — bifa `visible` pe
nodul de zonă stinge tot subarborele.

Nodurile de zonă **rămân la transformarea identitate**: poziție `(0,0,0)`, fără
rotație, scală `1,1,1`. Motivul e că altfel toate cifrele de dedesubt devin
relative la ele: nu mai poți citi o poziție fără s-o compui în cap, iar un diff
în `.tscn` nu mai spune unde e obiectul. Cu zona la identitate, transformarea
fiecărui prop **este** poziția lui în lume.

Corolarul: **nu agăța un prop de alt prop.** E ușor de făcut accidental (tragi
GLB-ul peste nodul greșit din arbore) și arată la fel în viewport, dar scala
părintelui se propagă la copii, iar mutarea părintelui târăște după ea obiecte
pe care nu voiai să le atingi. Pe Track08 ajunseseră 30 de prop-uri agățate de
trei stânci, unele pe trei niveluri (`coral_rock2/coconut_palm7/sabani_boat`).

## Verifică ce ai așezat

Primele două limite de mai sus nu se văd din editor, așa că au și o sondă:

```
godot --headless --path . --script res://tools/probe_manual.gd -- --track=1
```

Pentru fiecare obiect din `DecorManual` scrie cota lui, cota terenului de sub
el și distanța până la axul șoselei, apoi dă `VERDICT: OK` sau numără câte sunt
de reparat. Prima rulare (#151) a găsit, din nouă obiecte: unul la **128 m în
aer**, patru care pluteau, și patru așezate **pe carosabil** — o arcadă la 2.2 m
de axul drumului. Nimic nu se vedea, fiindcă nodul stătea pe `visible = false`.

**Coliziunea nu vine de la sine.** Un obiect mare așezat manual lângă șosea, dar
fără `StaticBody3D`, arată ca un perete prin care treci — mai rău decât lipsa
lui. Ori îi pui coliziune, ori îl ții destul de departe cât să nu-l atingi.

## Promovarea: din sketchpad în scenografie

Din august 2026 (#201), `DecorManual` e un **sketchpad**, nu destinația finală.
Compoziția se schițează în editor exact ca mai sus, iar când e bună se
**promovează în scenografie**: fiecare piesă devine un spec `spot` cu
`face: "world"` — poziție XZ, orientare și scală literale — în fișierul de
date al pistei (pe Track08: `scenes/tracks/track08_manual_specs.gd`, apelat
din `_scenography()`).

De ce merită pasul în plus:

- **y-ul se re-derivă din `ground_y` la fiecare rebuild** — piesele promovate
  nu mai rămân suspendate sau îngropate când se mișcă terenul; exact clasa de
  accident pe care o vânează `probe_manual` dispare prin construcție.
- **Intră în `TrackDecorBatch.bake()`** — pe Track08, promovarea celor 186 de
  piese a tăiat desenele de la 1061 la 505.
- **Diff-urile sunt cod**, nu transformări binare într-un `.tscn` de 40 KB.

Mecanic: converter-ul din #201 (scratchpad) citește subarborele `DecorManual`
și emite fișierul de specs; după aceea nodurile se șterg din `.tscn`, iar
`probe_manual` trebuie să raporteze `0 obiecte`. Pentru offseturile specurilor
noi scrise de mână, măsoară terenul cu:

```
godot --headless --path . --script res://tools/survey_terrain.gd -- --track=8 --from=0.48 --to=0.64
```
