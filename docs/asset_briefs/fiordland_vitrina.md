# Vitrina kit Fiordland — măsurători

Toate cele 39 de piese (31 GLB native din `assets/models/fiordland/` + 8
reuse înregistrate în `Track16.tscn`) capturate individual, cu `--vitrina=`
în `tools/snapshot.gd`, camera de joc (`--gamecam`) și mașina jucătorului
(Muscle, `4,0 × 1,8 × 1,5 m`) în cadru ca scară de referință.

Planșa de contact: `docs/asset_briefs/img/fiordland_vitrina.png`.

## Metoda de măsurare — declarat explicit

**Toate cifrele de mai jos sunt măsurate pe CASETĂ / citite vizual din
captură, NU pe mască exactă a mesh-ului.** `tools/ProbeMasca.tscn` (mască
prin rasterizare pe triunghiuri) **nu se aplică** aici: matchează pe nume de
nod deja prezent în scena `Track` încărcată din `DecorManual`/hazarde, nu pe
o piesă instanțiată ad-hoc de `--vitrina` într-un container fără relație cu
zonele existente.

Am încercat întâi un segmentator automat (flood-fill pe fundal, excludere
după familie de culoare HSV: navy-asfalt, turcoaz-gheață/mare, gri-ceață,
portocaliu-bordură). **A eșuat repetat și a fost abandonat, cu motivul
păstrat aici ca lecție**, nu ascuns:

- Prima versiune (comparație cu culori eșantionate pe marginea cadrului)
  confunda fundalul cu piesa — `guard_rock`, `penguin_tawaki`, `snow_pole`
  au ieșit cu bbox **identic la bit** (25,86)-(1253,697), semn clar de
  mecanism neconectat (memoria `sonda-masoara-alt-obiect`).
- A doua versiune (flood-fill pe familie de nuanță) a confundat
  **acoperișul de lemn portocaliu al `lodge`-ului cu bordura portocalie a
  drumului** (ambele H≈0.06-0.08, S≈0.45-0.64 — coliziune reală de paletă,
  nu bug de prag) și **gheața turcoaz de lângă mal cu asfaltul navy**
  (H≈0.48 vs H≈0.55-0.72, benzi adiacente). Rezultat: piese mari (lodge,
  stirling_ledge, torrent_chute, cruise_boat) măsurate cu un bbox identic,
  de 3 pixeli, aparținând de fapt unei componente minuscule din altă parte
  a cadrului.
- Detectorul de mașină (roșu R-G>35) prindea și `chevron_sign`-ul de pe
  marginea pistei (roșu închis, R-G~93) — corectat prin prag pe
  luminozitate (R>180), dar a costat o rundă de măsurători greșite.

Cu paleta asta (culori plate, clase triplanare partajate — vezi
`docs/style_bible.md` §4) un segmentator de uz general pe culoare **nu e
fiabil**: decor și fundal/drum împart aceleași familii de nuanță prin
construcție. Măsurătorile de mai jos sunt deci **citite vizual din
capturi** (înălțime în pixeli estimată prin inspecție, nu prin algoritm),
cu mențiunea explicită „casetă” peste tot — memoria
`caseta-de-masura-contine-cer` aplicată aici pe altă cauză (nu cer, ci
confuzie de familie de culoare).

## Referință de scară

Mașina Muscle (`--gamecam --car`), în captură:

- la `--frac=0.95` (cotitura de plajă, ZonaA/lângă chei): **~70 px** înălțime
- la `--frac=0.50` (drum drept, coborâre lină): **~94 px** înălțime

(Diferența e distanța reală cameră-mașină la fiecare fracție — perspectivă,
nu eroare. Măsurate prin componenta conexă de roșu-saturat R>180, R-G>90,
R-B>90 — singura parte a auto-detecției care s-a dovedit robustă, verificat
identic pe toate capturile de la aceeași fracție.)

## Tabelul de măsurători

Coloana „raport" e înălțime-piesă / înălțime-mașină, **estimat vizual**
(±20-30%, nu o cifră de precizie). „—" = nu s-a putut estima un raport
util (piesă plată/orizontală, sau piesă abia vizibilă).

| piesă | fracție | raport vs. mașină | culoare (observație) | clasă textură |
|---|---|---|---|---|
| kea (Idle) | 0.50 | ~0,2× | verde-gri, aripi strânse | atlas (fără clasă) |
| kea (Open) | 0.50 | ~0,2× (anvergură vizibilă) | verde-gri, aripi întinse orizontal | atlas |
| penguin_tawaki | 0.50 | ~0,3× | gri-negru, formă ovală joasă | atlas |
| cafe_shed | 0.95 | ~2,6× | acoperiș portocaliu, pereți gri-albăstrui | atlas (var/lemn) |
| lodge | 0.95 | ~3,5× (clipat parțial în cadru) | acoperiș maro-portocaliu lemn, pereți gri | atlas |
| tree_avalanche | 0.95 | ~1,3× | verde-închis, grămadă compactă de bușteni | atlas |
| beech_a | 0.95 | ~2,2× | coroană verde, trunchi maro | atlas |
| beech_b | 0.95 | **clipat sus din cadru** (side=12 insuficient) | coroană verde | atlas |
| beech_c | 0.95 | **clipat sus din cadru** (side=14 insuficient) | coroană verde, mai înaltă ca beech_b | atlas |
| beech_dead | 0.95 | ~2,0× | trunchi uscat maro-negru, crengi subțiri | atlas |
| rata_tree | 0.95 | ~1,6× | tufă densă verde-închis, compactă | atlas |
| tussock_clump | 0.50 | **abia vizibil** (~0,15×) | verde pal, fir subțire | atlas |
| driftwood | 0.50 | ~0,3× (orizontal, lungime dominantă) | maro deschis, buștean lung | atlas |
| kayak_a | 0.50 | ~0,25× | albastru (CAR_BLUE), formă îngustă | atlas |
| kayak_b | 0.50 | ~0,25× | galben-negru (CAR_YELLOW) | atlas |
| luggage_container | 0.95 | ~2,7× (include adâncimea, perspectivă) | dungi albastru-alb | atlas |
| road_sign_blank | 0.95 | ~0,7× | panou verde pe 2 stâlpi | atlas |
| snow_pole | 0.50 | ~0,3× | alb-roșu, jalon subțire | atlas |
| stump | 0.95 | ~0,4× | verde-maro, formă joasă rotunjită | atlas |
| traffic_light_pole | 0.95 | ~1,3× | stâlp gri, carcasă albastră **fără lămpi vizibile** (confirmat: 2 alveole goale, conform inventarului) | atlas |
| chasm_rock | 0.95 | ~1,4× | gri cu vârf verde (mușchi), marmite negre vizibile | atlas |
| fiordland_horizon | 0.95, side=60 | **umple cadrul** (side prea mic pt. o piesă de 90-180m) | maro-brun cu dungi verticale întunecate clar vizibile | **wet_gneiss (NU se aplică — vezi nota de mai jos)** |
| guard_rock | 0.50 | ~0,17× | verde, formă mică ovoidă | atlas |
| scree_slab | 0.95 | ~0,8× (lat, jos) | maro-portocaliu, placă înclinată | atlas |
| stirling_ledge | 0.95, side=30 | **clipat, doar marginea vizibilă** (side insuficient pt. 40m lățime) | gri-albăstrui, textură vizibilă dar cadru insuficient | wet_gneiss (aplicat pe `.Wall`) |
| torrent_chute | 0.95, side=20 | **clipat, umple colțul din dreapta** | maro-brun cu dungi verticale — **wet_gneiss vizibil clar** | wet_gneiss (aplicat pe `.Rock`) |
| chasm_bridge_rail | 0.95 | ~1,1× | lemn deschis, balustradă | atlas |
| heli_pad | 0.95 | ~0,3× (disc jos, lat) | alb-gri, disc plat | atlas |
| wharf | 0.95 | ~1,7× (lat dominant) | punte verde, pereți gri | atlas |
| bush_plane | 0.95 | ~1,6× (anvergură dominantă) | fuzelaj alb, coadă roșie | atlas |
| coach_fiordland | 0.95, side=16 | **clipat parțial** (side insuficient) | verde-alb, autocar | atlas |
| cruise_boat | 0.95, side=20 | **clipat, doar prova vizibilă** | corp alb | atlas (`waterline`) |
| fern_cluster | 0.50 | **abia vizibil** (~0,1×) | verde închis, formă mică | atlas |
| nerpa_seal | 0.50 | **abia vizibil** (~0,1×) | gri, formă ovală joasă | atlas |
| tree_fern | 0.95 | ~1,8× | verde, formă de palmier | atlas |
| moss_boulder_a | 0.95 | ~0,6× | gri cu vârf verde mușchi | atlas |
| moss_boulder_b | 0.95 | ~0,7× | gri cu vârf verde mușchi, mai rotund | atlas |
| moss_boulder_c | 0.95 | ~0,6× | gri cu vârf verde mușchi | atlas |
| chevron_sign | 0.95 | ~0,3× | roșu-alb, panou de semnalizare | atlas |
| wooden_pier | 0.95 | ~1,0× (clipat parțial dreapta) | lemn maro, structură pe piloni | atlas |

## Verificarea clasei `wet_gneiss`

Contract citit din `scenes/props/world_prop.gd` (`CLASSES_BY_MODEL`, secțiunea
„Fiordland: GNEISUL UD"): clasa se aplică **explicit DOAR** pe
`stirling_ledge.Wall` și `torrent_chute.Rock`.

**Diferență față de premisa din task**: `fiordland_horizon` este
**explicit EXCLUS** din `wet_gneiss` — comentariul din cod spune clar:

> NU se aplică pe fiordland_horizon (FarWall_*/SnowRidge_*): acolo
> TROPICAL_GREEN/LOG_DARK/MARBLE_GREY/FOAM_WHITE sunt BENZI DE ALTITUDINE
> pictate intenționat [...] o clasă triplanară ar șterge exact
> stratificarea pe care tema o cere explicit (`horizon_class: ""`).

Deci „fiordland_horizon trebuie să arate wet_gneiss" din brief-ul acestei
sarcini **nu corespunde cu codul actual** — orizontul are propriul sistem de
bandă pe altitudine (verificat vizual: peretele arată maro-brun uniform cu
umbrire pe verticală în captură, nu dungile fine specifice `wet_gneiss`).
Am marcat asta explicit în tabel în loc să raportez tăcut „OK" pe o premisă
falsă (memoria `justificarea-din-comentariu-se-verifica`).

Pe `stirling_ledge` și `torrent_chute`: dungile verticale întunecate se
văd clar în capturi (confirmat vizual, ambele la `--vitrina-side` mare
pentru piese cu lățime 24-40 m). Nu am reușit o mostră HSV precisă pe
zona exactă a dungii (coordonatele încercate au căzut pe drum/umbră de
câteva ori) — verdictul „aplicat" se bazează pe inspecție vizuală directă
a capturii, nu pe o cifră de contrast.

## Coliziune (`PROP_COLLISION` din `world_prop.gd`)

Nu am rulat un test dedicat cu mașina condusă prin fiecare piesă (flagul
`--car` din `snapshot.gd` doar așază mașina înghețată pe grilă, nu o mișcă
prin scenă — nu există un mecanism în `Snapshot.tscn` care să simuleze
coliziunea). Raportez modul de coliziune **declarat în cod**, citit direct
din tabelul `PROP_COLLISION`, pe modelele Fiordland:

- `trunk` (cilindru pe trunchi): `beech_a/b/c`, `beech_dead`
- `mesh` (colizor exact): `stirling_ledge` (nișa din spatele surplombei e
  gol real, un hull ar astupa-o)
- `none` (fantomă, nu oprește mașina): `penguin_tawaki`, `heli_pad`,
  `torrent_chute`, `chasm_bridge_rail`, `scree_slab`, `snow_pole`,
  `kayak_a`, `kayak_b`, `fiordland_horizon`, `bush_plane`
- `hull` (implicit, poliedru convex): restul — `cafe_shed`, `lodge`,
  `chasm_rock`, `guard_rock`, `wharf`, `coach_fiordland`, `cruise_boat`,
  `traffic_light_pole`, `luggage_container`, `driftwood`, `stump`,
  `road_sign_blank`, `tussock_clump`, `tree_avalanche`, `rata_tree`

Fiecare mod are un motiv scris explicit în comentariile din `world_prop.gd`
(citat parțial în raportul de handoff). N-am validat empiric niciuna dintre
aceste decizii — sunt raportate ca „ce spune codul", nu ca „verificat prin
condus".

## Punct ÎNCHIS (runda 1, POI A, 25 sep 2026): acoperișurile ieșeau tan — CAUZĂ GĂSITĂ ȘI REPARATĂ

`cafe_shed` și `lodge` au `House_Roof`/`House_Roof_001` pe slotul 11
`PAINTED_METAL` (UV exact la centrul slotului, u = 0,3594; atlas albastru-gri
(117,145,167), verificat direct din `palette_atlas.png`, nu presupus). În
captură acoperișul măsura **#BB8967** (tan) la yaw 0 și yaw 180.

**Ambele ipoteze din revizuirea precedentă au fost testate și RESPINSE, cu
captură:**

1. **Reflexie speculară** (`metallic_specular` 0,15 pe fața orizontală) —
   testat cu `--vitrina=cafe_shed --rain=1` (schimbă soarele): acoperișul
   rămâne #BB8967 identic sub ploaie. Respinsă.
2. **Fața de sus primește alt slot la runtime** — testat cu un remap de probă
   11 → 8 (CONCRETE) în `SLOT_REMAP_BY_MODEL["cafe_shed"]`: **acoperișul nu
   s-a schimbat deloc**. Asta a fost semnalul că piesa nu citește slotul din
   atlas prin mecanismul de remap — nu ajunge acolo deloc. Respinsă (remapul
   de probă a fost scos din cod după test, nu a rămas pe ramură).

**Cauza reală**, găsită instanțiind `cafe_shed.glb` sub un `WorldProp` real și
citind `material_override`/`albedo_texture` pe scena încărcată: `House_Roof`
primea `albedo_texture = res://assets/textures/classes/roof_tiles.png` —
NU atlasul comun. Media acelei texturi e (154,113,82), adică exact tanul
raportat, cu vertex color ridicând ușor valoarea. `roof_tiles` e clasa
landmark-ului Okinawa (`village_house.glb`, `_LANDMARKS[6]` din `track.gd`):
`"House_Roof": "roof_tiles"` intră GLOBAL în `WorldProp.prop_classes()`
(`Palette.apply_class_materials`), iar `_class_for` face `begins_with`, nu
egalitate exactă — deci prinde și `House_Roof_001` al lui `lodge`. Coliziune
de nume de nod între kituri (memoria `nume-noduri-nu-sunt-unice`), nu slot,
nu lumină.

**Reparat în `world_prop.gd`** (o singură dată, cum cere brief-ul — POI H
preia rezolvarea fără lucru suplimentar): adăugat sentinela
`Palette.ATLAS_PREFIX` (nou, în `palette.gd`), care forțează explicit
`world_material()` pe o parte a unui model prin `CLASSES_BY_MODEL`, distinct
de "nicio intrare" (bug-ul vechi: un string gol în mapare era tratat ca
"nimic de făcut" și nodul rămânea pe materialul greșit din pasul global).
`CLASSES_BY_MODEL["cafe_shed"]["House_Roof"]` și
`CLASSES_BY_MODEL["lodge"]["House_Roof_001"]` sunt acum `ATLAS_PREFIX`.
`House_Wall`/`House_Wall_001` NU colidau (maparea globală n-are nicio cheie
`House_Wall*`) și au rămas neatinse. `village_house`/Okinawa nu e atins:
mapările noi sunt cheie pe fișier (`cafe_shed`/`lodge`), landmark-ul 6 rămâne
neschimbat. Verificat pe captură (`--vitrina=cafe_shed`, `--vitrina=lodge`):
ambele acoperișuri ies acum albastru-gri metalic, ca `luggage_container` pe
același slot.
