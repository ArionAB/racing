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

## Unde stau

Toate modelele Baikal sunt sub **`assets/models/baikal/<categorie>/`**, nu
imprastiate prin categoriile comune.

```
assets/models/
  baikal/
    buildings/   banya, khuzhir_church, log_house_a/b/c
    props/       fish_rack, husky_dog, ice_kit, nerpa_seal, serge_pole,
                 shore_kit, village_props, village_signpost, well_crane,
                 woodpile
    rocks/       shaman_rock
    structures/  ice_grotto_arch, power_pylon_soviet,
                 railway_tunnel_portal, rail_track, start_gate_logs,
                 viaduct_pier / viaduct_arch / viaduct_end
    trees/       forest_kit
    vehicles/    hovercraft_khivus, kamaz_truck, train_baikal, uaz_bukhanka
  buildings/     (celelalte piste)
  trees/         ...
```

Pista intai, categoria a doua — DELIBERAT in ordinea asta. Cu 125 de modele in
repo, `trees/` si `buildings/` comune devenisera un morman in care nu se mai
vedea ce e al cui. Categoria ramane al doilea nivel (nu se pierde) tocmai ca o
cautare dupa "flowers" sa scoata florile de pe TOATE pistele, nu doar dintr-un
folder plat pe pista.

⚠️ **Structura pe doua niveluri cere garzi RECURSIVE.** `probe_watertight.gd`
scana un singur nivel si a orbit tacut pe tot kitul la mutare — de la 331 la
257 de mesh-uri masurate, fara niciun avertisment. E reparat (`_collect_glb`),
dar orice unealta noua care umbla prin `assets/models/` trebuie sa coboare
recursiv.

## Ce contine

56 de fisiere. Triunghiurile sunt MASURATE pe GLB.

**UN FISIER PE PIESA.** Toate kiturile (sat, gheata, padure, mal, serge) sunt
sparte: o piesa = un GLB, cu originea la baza ei. Se refera direct, fara `keep`
si fara `Track._extract_glb_node()`.

Raman multi-nod doar **ANSAMBLURILE** — biserica (`Church_Body/Roof/Dome`),
viaductul, tunelul, grota, hovercraftul, trenul si Stanca Samanului: acolo
nodurile impart o origine si se instantiaza impreuna, deci spargerea le-ar
rupe.

Fiecare piesa merge in CATEGORIA ei, nu toate in `props/`: bolovanii si faleza
la `rocks/`, tufele la `plants/`, cabana de vanatoare la `buildings/`, scara de
mal la `structures/`.

Numarul de materiale nu se schimba (tot atlasul), deci nici draw call-urile:
batch-ul se face pe material, nu pe fisier. Castigul masurat e in ALTA parte —
iesirea generatorului de decor a scazut de la **2614 la 384 de linii**, fiindca
piesele nu mai carauza dupa ele fratii stinsi cu `visible = false`. Cele **349
de plasari reale si transformarile lor raman IDENTICE la bit**.

| fisier | noduri | tris |
|---|---|---|
| `baikal/buildings/banya.glb` | `Banya` | 868 |
| `baikal/buildings/hunting_cabin.glb` | `HuntingCabin` | 1248 |
| `baikal/buildings/khuzhir_church.glb` | `Church_Body`, `Church_Dome`, `Church_Roof` | 3706 |
| `baikal/buildings/log_house_a.glb` | `LogHouse_A` | 2012 |
| `baikal/buildings/log_house_b.glb` | `LogHouse_B` | 2540 |
| `baikal/buildings/log_house_c.glb` | `LogHouse_C` | 1616 |
| `baikal/plants/grass_tuft_dry.glb` | `GrassTuftDry` | 616 |
| `baikal/plants/shrub_snow.glb` | `ShrubSnow` | 592 |
| `baikal/props/barrels_crates.glb` | `BarrelsCrates` | 1464 |
| `baikal/props/fence_gate.glb` | `FenceGate` | 1468 |
| `baikal/props/fish_rack.glb` | `FishRack` | 1144 |
| `baikal/props/fisher_tent_green.glb` | `FisherTent_Green` | 508 |
| `baikal/props/fisher_tent_orange.glb` | `FisherTent_Orange` | 508 |
| `baikal/props/frozen_boat.glb` | `FrozenBoat` | 962 |
| `baikal/props/husky_dog.glb` | `Husky_Dog_Mesh` | 1164 |
| `baikal/props/ice_block_stack.glb` | `IceBlockStack` | 264 |
| `baikal/props/ice_hole.glb` | `IceHole` | 1208 |
| `baikal/props/ice_road_marker.glb` | `IceRoadMarker` | 192 |
| `baikal/props/ice_road_sign.glb` | `IceRoadSign` | 384 |
| `baikal/props/ice_shards.glb` | `IceShards` | 616 |
| `baikal/props/ice_slab_cracked.glb` | `IceSlabCracked` | 1708 |
| `baikal/props/nerpa_seal.glb` | `Nerpa_Seal_Mesh` | 1164 |
| `baikal/props/plank_fence.glb` | `PlankFence` | 1584 |
| `baikal/props/serge_pole_a.glb` | `Serge_A` | 1340 |
| `baikal/props/serge_pole_b.glb` | `Serge_B` | 1164 |
| `baikal/props/serge_pole_c.glb` | `Serge_C` | 1516 |
| `baikal/props/sled.glb` | `Sled` | 1012 |
| `baikal/props/toros_a.glb` | `Toros_A` | 308 |
| `baikal/props/toros_b.glb` | `Toros_B` | 616 |
| `baikal/props/toros_c.glb` | `Toros_C` | 836 |
| `baikal/props/village_signpost.glb` | `Signpost` | 360 |
| `baikal/props/well_crane.glb` | `Well` | 488 |
| `baikal/props/woodpile.glb` | `Woodpile` | 4364 |
| `baikal/rocks/boulder_lichen_a.glb` | `BoulderLichen_A` | 294 |
| `baikal/rocks/boulder_lichen_b.glb` | `BoulderLichen_B` | 286 |
| `baikal/rocks/boulder_lichen_c.glb` | `BoulderLichen_C` | 266 |
| `baikal/rocks/cliff_face_olkhon.glb` | `CliffFaceOlkhon`, `CliffFaceOlkhon_Ice` | 622 |
| `baikal/rocks/shaman_rock.glb` | `Shaman_Crag_Big`, `Shaman_Crag_Small`, `Shaman_Ice` | 1376 |
| `baikal/structures/ice_grotto_arch.glb` | 6 noduri | 6224 |
| `baikal/structures/power_pylon_soviet.glb` | `Pylon_Soviet` | 6764 |
| `baikal/structures/rail_track.glb` | `RailTrack` | 924 |
| `baikal/structures/railway_tunnel_portal.glb` | `Tunnel_Portal`, `Tunnel_Bore`, `Tunnel_Bore_Ice`, `Tunnel_Niche` | 7480 |
| `baikal/structures/viaduct_pier.glb` | `Viaduct_Pier`, `RailDeck_Pier` | 924 |
| `baikal/structures/viaduct_arch.glb` | `Viaduct_Arch`, `Viaduct_Arch_Ice`, `RailDeck_Arch` | 5732 |
| `baikal/structures/viaduct_end.glb` | `Viaduct_End`, `RailDeck_End` | 2684 |
| `baikal/structures/shore_staircase.glb` | `ShoreStaircase` | 1892 |
| `baikal/structures/start_gate_logs.glb` | `StartGate_Logs` | 2348 |
| `baikal/trees/birch_winter_a.glb` | `BirchWinter_A` | 4368 |
| `baikal/trees/birch_winter_b.glb` | `BirchWinter_B` | 4368 |
| `baikal/trees/birch_winter_c.glb` | `BirchWinter_C` | 4368 |
| `baikal/trees/larch_winter_a.glb` | `LarchWinter_A` | 13140 |
| `baikal/trees/larch_winter_b.glb` | `LarchWinter_B` | 13140 |
| `baikal/trees/larch_winter_c.glb` | `LarchWinter_C` | 13140 |
| `baikal/trees/pine_siberian_a.glb` | `PineSiberian_A` | 874 |
| `baikal/trees/pine_siberian_b.glb` | `PineSiberian_B` | 874 |
| `baikal/vehicles/hovercraft_khivus.glb` | 4 noduri | 1968 |
| `baikal/vehicles/kamaz_truck.glb` | `Kamaz_Truck` | 3624 |
| `baikal/vehicles/train_baikal.glb` | `Baikal_Carriage_A`, `Baikal_Carriage_B`, `Baikal_Loco` | 5600 |
| `baikal/vehicles/uaz_bukhanka.glb` | `UAZ_Bukhanka` | 1128 |

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
python tools/blender/verify_glb.py assets/models/baikal/props/serge_pole.glb \
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
