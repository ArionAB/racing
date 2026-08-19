# Kit Baikal — assets din foaia de referinta (pista `Track10`, tema `baikal`)

Sursa formelor: planşa de turnaround-uri din `docs/track_briefs/baikal.md` §9
(cele 13 pozitii: Shaman Rock, serge, viaduct, tunel, grota, biserica,
hovercraft, tren, pilon, poarta de start, village kit, ice kit, forest kit).

Ca si `okinawa_kit.md`, documentul asta **nu e o comanda pentru un agent
Blender extern**: modelele exista, construite din `tools/blender/build_baikal_*.py`.
E CONTRACTUL de integrare — ce nume de noduri cauta Godot si de ce arata
piesele asa cum arata. Fara el, integrarea porneste tacit pe fallback (fiecare
punct de incarcare e pazit de `ResourceLoader.exists()`, deci un nume gresit nu
crapa nimic — se vede abia la urmatorul screenshot).

## Ce contine

Nouasprezece fisiere. Cotele si triunghiurile sunt MASURATE pe GLB, nu
declarate.

| fisier | noduri | tris | scriptul sursa |
|---|---|---|---|
| `rocks/shaman_rock.glb` | `Shaman_Crag_Big`, `Shaman_Crag_Small`, `Shaman_Ice` | 1376 | `build_baikal_shaman.py` |
| `props/serge_pole.glb` | `Serge_A/B/C` | 4020 | `build_baikal_shaman.py` |
| `structures/railway_viaduct.glb` | `Viaduct_Pier`, `Viaduct_Arch`, `Viaduct_End` | 9340 | `build_baikal_railway.py` |
| `structures/railway_tunnel_portal.glb` | `Tunnel_Portal`, `Tunnel_Bore`, `Tunnel_Niche` | 7480 | `build_baikal_railway.py` |
| `structures/ice_grotto_arch.glb` | `Grotto_Rock`, `Grotto_Ice`, `Icicle_A..D` | 6224 | `build_baikal_grotto.py` |
| `buildings/khuzhir_church.glb` | `Church_Body`, `Church_Roof`, `Church_Dome` | 3706 | `build_baikal_grotto.py` |
| `vehicles/hovercraft_khivus.glb` | `Khivus_Skirt/Hull/Cabin/Fan` | 1968 | `build_baikal_vehicles.py` |
| `vehicles/train_baikal.glb` | `Baikal_Loco`, `Baikal_Carriage_A/B` | 5600 | `build_baikal_vehicles.py` |
| `structures/power_pylon_soviet.glb` | `Pylon_Soviet` | 6764 | `build_baikal_vehicles.py` |
| `structures/start_gate_logs.glb` | `StartGate_Logs` | 2348 | `build_baikal_vehicles.py` |
| `buildings/village_kit.glb` | `LogHouse_A/B/C`, `Banya`, `FishRack`, `Well`, `Woodpile`, `Signpost` | 13392 | `build_baikal_village.py` |
| `props/village_props.glb` | `PlankFence`, `FenceGate`, `Sled`, `BarrelsCrates` | 5528 | `build_baikal_village.py` |
| `vehicles/uaz_bukhanka.glb` | `UAZ_Bukhanka` | 1128 | `build_baikal_village.py` |
| `vehicles/kamaz_truck.glb` | `Kamaz_Truck` | 3624 | `build_baikal_village.py` |
| `props/ice_kit.glb` | `Toros_A/B/C`, `IceSlabCracked`, `IceRoadMarker`, `IceRoadSign`, `IceHole`, `FisherTent_Green/Orange`, `IceBlockStack`, `FrozenBoat`, `IceShards` | 8110 | `build_baikal_ice.py` |
| `trees/forest_kit.glb` | `LarchWinter_A/B/C`, `BirchWinter_A/B/C`, `PineSiberian_A/B` | 54272 | `build_baikal_forest.py` |
| `props/shore_kit.glb` | `ShrubSnow`, `GrassTuftDry`, `BoulderLichen_A/B/C`, `CliffFaceOlkhon`, `HuntingCabin`, `ShoreStaircase` | 5816 | `build_baikal_forest.py` |
| `props/husky_dog.glb` | `Husky_Dog` (armatura, 7 oase) + `Husky_Dog_Mesh` | 1164 | `build_baikal_animals.py` |
| `props/nerpa_seal.glb` | `Nerpa_Seal` (armatura, 4 oase) + `Nerpa_Seal_Mesh` | 1164 | `build_baikal_animals.py` |

**Total: 143 024 de triunghiuri**, tot lotul. Bugetul din brief §6 era ~400k pe
pista cu tot cu teren, din care ~120k doar padurea — kitul intra confortabil.
Padurea singura face 54k, sub jumatate din alocarea ei.

## Piese cu contract de MECANICA (nu doar decor)

Cinci piese sunt cerute de hazardele din brief §3, deci geometria lor e
constransa de fizica, nu de estetica:

- **`Toros_A/B/C`** sunt *kickere*. Profilul pe directia de mers urca lin pana
  la 70% din lungime, apoi coboara: o creasta cu perete vertical n-ar lansa
  masina, ar opri-o. Placile individuale se inclina, dar niciuna nu iese peste
  profilul de rampa — altfel roata loveste o treapta.
- **`IceSlabCracked`** e corpul lui `IceSlabHazard`. Fata de sus e PLANA (se
  roteste in joc; orice neregularitate s-ar citi ca tremurat), variatia e doar
  in conturul poligonal si in muchia de gheata sparta.
- **`Icicle_A..D`** sunt noduri SEPARATE fiindca pista le desprinde la trecere.
  Originea fiecaruia e la punctul de agatare (sus), nu la mijloc: cad rotindu-se
  in jurul prinderii.
- **`Tunnel_Niche`** e refugiul din mecanica trenului-pe-sens. Adancimea de
  2.8 m e derivata din latimea masinii (2.2 m), nu aleasa estetic. Nisele sunt
  goluri REALE in `Tunnel_Bore`, la fiecare 12 m, alternand stanga/dreapta.
- **`Nerpa_Seal`** are actiunea **`Dive`** pe langa `Idle`, declansata la
  proximitate. Ultimul cadru o lasa sub nivelul gheții, ca pista sa poata stinge
  nodul fara sa se vada disparitia.

## Orientari (contract cu Godot)

- **Cladiri si poarta de start:** fata de prezentare spre **+Y in Blender**
  (= **−Z in Godot**), ca la tot restul proiectului.
- **Hovercraft si tren:** botul spre **+X in Blender** — `PathMover` si
  `TrainHazard` deplaseaza piesa spre +X local (vezi `build_train.py`).
- **Animale:** botul spre **+Y in Blender** (= −Z in Godot), ca vaca si
  testoasa.
- **Viaductul e MODULAR:** pila + arcada de 12 m + capat. Patul de cale ferata
  iese la aceeasi cota (`DECK_Z`) pe toate trei, altfel sinele fac trepte la
  imbinari. Numarul de arcade se decide in pista, nu in asset.

## Animatii (numele sunt contract)

| asset | actiuni | note |
|---|---|---|
| `husky_dog.glb` | `Idle` (2 s), `Walk` (1 s), `Run` (0.6 s) | mers in DIAGONALA (trap): stangul fata cu dreptul spate. Perechea pe aceeasi parte ar arata ca o jucarie stricata. `Run` e galop, cu spinarea arcuita — postura in care un caine de sanie se recunoaste cel mai bine |
| `nerpa_seal.glb` | `Idle` (2.5 s), `Dive` (1 s) | `Dive` NU e ciclica: se joaca o data, la trigger |

Actiunile sunt datablock-uri GLOBALE in Blender, iar `clear_built` sterge doar
mesh-uri. La construirea celui de-al doilea animal in aceeasi sesiune, `Idle`
exista deja si noua actiune devine `Idle.001`, iar `stash_actions` pune in NLA
ce gaseste — nerpa a plecat o data cu cinci actiuni, dintre care `Walk` si `Run`
erau ale CAINELUI. De aia exista `_clear_animals()`, care sterge si armaturile,
si actiunile.

## Paleta: sase sloturi noi (24–29)

Brief-ul cerea opt; doua au picat la integrare, si motivul e acelasi in ambele
cazuri — **un slot e o CULOARE, nu o eticheta semantica**:

- `snow_white` (propus 27) e in cifre acelasi alb-albastrui ca `FOAM_WHITE`
  (22). `SNOW_WHITE` e alias peste el.
- `ribbon_accents` (propus 31) cerea CINCI culori intr-un slot, ce atlasul nu
  poate reprezenta.

Sloturile reale: `ICE_TURQUOISE` 24, `ICE_DEEP` 25, `ICE_CRACK` 26,
`LARCH_RUST` 27, `LOG_DARK` 28, `MARBLE_GREY` 29. **30–31 raman rezerva** si se
randeaza magenta, ca greselile de UV sa sara in ochi.

Gheata si marmura au primit textura proprie in generatorul de atlas
(`_ice`, `_marble`): bulele de metan inghetate in straturi si fisurile sunt
DESENUL suprafetei pe Baikal, nu o rupere de monotonie — de aceea amplitudinea
lor e mai mare decat la celelalte sloturi (deviatie de luminanta masurata:
σ 17.1 pe gheata, fata de ~5 pe lemn).

### Exceptia panglicilor serge

Panglicile folosesc sloturile de MASINA (`CAR_BLUE`, `FOAM_WHITE`,
`CAR_YELLOW`, `CAR_RED`, `TROPICAL_GREEN`) — abatere **constienta** de la
style_bible §1. Regula exista ca masinile sa ramana cele mai saturate obiecte
din cadru; panglicile sunt fasii de 60–90 cm pe 13 stalpi, sub un metru patrat
in total, si semnaleaza **vantul**, care aici e mecanica. Garda o accepta doar
DECLARAT:

```
python tools/blender/verify_glb.py assets/models/props/serge_pole.glb \
    --origin=assembly --allow-car-slots=Serge
```

Doua alte piese au cerut initial aceleasi sloturi si **nu** au primit exceptie,
fiindca sunt suprafete mari: dunga trenului (38 m de garnitura) a trecut pe
`DRY_VEGETATION`, iar betele de marcaj de pe gheata (zeci, la fiecare 20 m) pe
`KERB_RED`. Diferenta dintre cazuri e suprafata, nu principiul.

## Verificare

```
# build (toate scripturile, headless)
D:/Blender/blender.exe --background --factory-startup \
    --python tools/blender/run_build.py -- \
    build_baikal_shaman.py build_baikal_railway.py build_baikal_grotto.py \
    build_baikal_vehicles.py build_baikal_village.py build_baikal_ice.py \
    build_baikal_forest.py build_baikal_animals.py

# contractul de export, per fisier
python tools/blender/verify_glb.py assets/models/<cat>/<nume>.glb --origin=assembly
```

Toate cele 19 trec cu `VERDICT: OK` (serge cu `--allow-car-slots=Serge`).

## Ce a prins randarea de control si numaratoarea nu

Fiecare piesa a fost randata (`tools/blender/preview.py`) inainte de a fi
considerata gata. Sapte defecte au trecut nestingherite de numaratoarea de
triunghiuri si au picat abia la imagine — merita listate, fiindca sunt clase de
greseala, nu accidente:

1. **Panglicile serge pluteau** langa stalp. `box` se roteste in jurul
   propriului centru, deci un lant de cutii rotite se rupe de ancora. Reparat cu
   `beam` (leaga doua PUNCTE).
2. **Lichenul iesea dreptunghiular** — "stickere" rosii pe marmura. Un slot se
   aplica pe FATA INTREAGA, iar fetele stancii au 1–4 m; niciun prag nu repara
   asta. Mutat in vertex colors, care interpoleaza.
3. **Bolta viaductului era un morman.** Voussoir-urile se roteau cu
   complementul unghiului polar, deci axa lor lunga iesea RADIALA in loc de
   tangenta. Se verifica numeric: produsul scalar dintre axa lunga si raza
   trebuie sa fie 0.
4. **Tunelul era un butoi pe camp** — inele complete de zidarie, cu exteriorul
   la vedere, 20 020 de triunghiuri pentru un obiect din care se vede doar fata
   dinauntru. Refacut ca suprafata interioara: **2376**, de 8.4 ori mai putin.
5. **Placa de gheata statea in picioare.** `Builder.prism` primeste un contur
   **XZ** si extrudeaza pe **Y** — un contur (x, y) dat direct iese vertical.
   De aici `_slab_plate()` in `build_baikal_ice.py`.
6. **Cupola bisericii lipsea**, cu crucea plutind in cer. `revolve` se OPRESTE
   la prima raza ≤ 0 si o face apex; profilul incepea cu `(0.00, 0.00)`.
7. **Gheata din grota era invizibila** — draperiile erau la 25 cm in INTERIORUL
   rocii. Grota iesea o arcada de piatra seaca, adica exact ce nu e.

Plus doua de compozitie: a treia fereastra a casei cadea peste usa (toc fara
geam), iar zapada pinilor era ingropata in con (pini complet verzi). Vezi
[[efecte-invizibile-nu-se-numara]].

## Ce NU e in lot

- **Materialele de clasa** (`ice_material` triplanar cu dale `ice_clear` /
  `ice_cracked`, `snow_material`, `snow_deep`, decalul `tire_tracks_ice`) —
  sunt suprafete de teren, se fac in `tools/paint_ice.py` si in tema pistei, nu
  ca GLB-uri. Textura de clasa `ice` exista deja (PR #287).
- **Fundalul** (`mountain_ring_baikal`, `far_shore_forest`, `sun_disc_low`) —
  `horizon_class` si cerul sunt tema, nu assets.
- **Particulele** (jet de zapada, fum de horn, cioburi la drift) si **sunetul**.
- **Integrarea in `Track10.tscn`** — piesele exista, dar nu sunt inca asezate pe
  pista. Urmatorul pas, dupa contractul asta.
