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
  `godot --headless --path . --script res://tools/probe_decor.gd -- --track=1`.
  Contează mai ales numărul de materiale, nu triunghiurile.
