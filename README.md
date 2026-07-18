# Ignition Spike — prototip 3D de weekend

**Scop:** sa masuram ce costa un racer 3D in stil Ignition (low-poly, chase cam,
denivelari) INAINTE de a decide un pivot de la proiectul 2D. E un spike de
aruncat — codul nu e "produs", e un instrument de masura.

## Ce contine

- Masinuta low-poly (cuburi + cilindri, proportii de jucarie) cu fizica arcade
  pe `CharacterBody3D` — aceeasi filosofie ca in racing 2D: grip lateral
  amortizat, drift pe Space, tuning prin `@export`
- Pista 3D generata din puncte de control (`Curve3D` -> mesh de tip panglica),
  cu doua dealuri si o coborare — exact ce nu se poate in 2D top-down
- Chase cam cu urmarire lina si FOV care creste cu viteza (senzatia Ignition)
- Cronometru de tur + best lap (asta e "gameplay-ul": bate-ti timpul)

## Controale

W/S accelerare/frana · A/D viraj · Space drift · R reset la linia de start

## Checklist de evaluat in weekend

Dupa 2-3 ore de joaca si umblat prin cod, raspunde-ti in scris:

1. **Feel:** Se simte mai bine decat 2D-ul cu camera rotativa? Cu cat?
2. **Cost pista:** Cat ti-a luat sa modifici traseul (punctele din
   `track_3d.gd`)? Extrapoleaza: cat ar costa 5 piste bune, cu decor?
3. **Cost arta:** masinuta e 6 cuburi. Cat ar costa un garaj de masini
   adevarate + decoruri? (Blender sau asset packs)
4. **Perf:** Ce FPS ai? (proiectul 2D tinteste 60fps pe telefoane mid-range)
5. **Lipsurile invizibile:** AI pe 3D (raycast-uri, navigatie pe panta),
   camera care nu intra in pereti, umbre pe mobil — nimic din astea nu e facut.

Daca dupa checklist raspunsul e "vreau 3D-ul", planul corect e: termina intai
felia 2D (feel + un build pe telefon), apoi porneste proiectul 3D cu lectiile
invatate. Logica de joc (drift CTR, items, rubber-banding, race flow) se
porteaza aproape 1:1.
