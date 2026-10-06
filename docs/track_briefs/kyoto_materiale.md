# Kyoto (Track18) — valul de materiale pe kit

> 4 oct 2026, ramura `kyoto/materiale`. Tiparul: `fiordland_materiale.md` /
> `serengeti_materiale.md`. Despre CE are textura de clasa si CE nu, pe tot
> kitul din `assets/models/kyoto/`. Inaintea valului, integrarea int-a clasase
> doar casele (lemn, var), coroanele, felinarele si pietrele.

## Bilant

- Garda de materiale (`tools/probe_decor.gd`, toate pistele): **Track18 29 -> 33 / 38**
  dupa valul 1, **-> 37 / 38 dupa valul 2** (vezi mai jos).
  Celelalte piste identice cu linia de baza (01 23, 08 21, 09 26, 10 23, 11 32,
  12 32, 13 21, 14 31, 15 16, 16 30, 17 24). Triunghiuri neschimbate.
- Zero PNG nou: `kawara` (dala `roof_tiles`), `bark_kyoto` (`bark`),
  `cedar_needles` (`pine_needles`) sunt clase noi pe dale deja in VRAM, cu tenta
  calculata prin bisectie in spatiu liniar (metoda din palette.gd, verificata:
  reproduce exact tenta `machiya_wood`). A patra, `wood`, e clasa existenta,
  fara tenta.
- `machiya_wood`, `moss`, `garden_stone` reutilizate pe piese noi: +0.
- **Defect reparat pe drum:** `temple_wall/Wall_Roof` lua tencuiala ALBA
  (`village_plaster`) prin prefixul GLOBAL `Wall_` al varului de Stromboli
  (`prop_classes()`). Acum e numit explicit in `CLASSES_BY_MODEL` -> `kawara`.

## Clasate

Instante numarate pe pista incarcata cu `tools/ProbeKyotoClase.tscn`
(WorldProp + CityFill + MeshForest + FlockProp).

| piesa · nod | instante | clasa | de ce (cifra) |
|---|---:|---|---|
| `machiya_a..e` · `Machiya_Roof` | 1 456 CityFill + 113 decor | `kawara` | 85% slot 20 + 15% slot 28. Tenta pe slotul 20 (85,83,90) -> (0.565, 0.748, 1.0); B plafonat (82.1). |
| `niomon_gate`, `inari_romon` · `Gate_Roof`; `kiyomizu_hondo` · `Hondo_Roof` | 3 | `kawara` | 52/48 sau 51/49 slot 20/28. |
| pagode (koyasu, sanjunoto, yasaka) · `Pagoda_Roof`; `kinkakuji` · `Kin_Roof`; `bell_tower` · `Bell_Roof`; `chozuya` · `Choz_Roof`; `tsutenkyo_roof_module` · `Tsu_Roof` | 13 | `kawara` | 6/28 sau 20/28, aproape 50/50. |
| `temple_wall` · `Wall_Roof` | 19 | `kawara` | 83% slot 20 — vezi defectul de mai sus. |
| `koyasu`/`sanjunoto` · `Pagoda_Windows`; `kinkakuji` · `Kin_Windows`; `bell_tower` · `Bell_Beams`; `chozuya` · `Choz_Beams` | 6 | `machiya_wood` | 100% slot 28 LOG_DARK = exact tinta lui `machiya_wood`. +0. |
| `bell_tower` · `Bell_Wood`; `chozuya` · `Choz_Wood`; `teahouse_front` · `Tea_Wood`; `tsutenkyo` · `Tsu_Rail`; `togetsukyo` · `Toget_Rail` | 35 | `wood` | 100% slot 9 (Toget_Rail 93%). Dala netentata (124,99,72) fata de slot (131,92,52): destul de aproape, fara clasa noua de tenta. |
| `momiji_a/b/c` · `Maple_Trunk`; `ginkgo` · `Ginkgo_Trunk`; `niwaki_pine` · `Pine_Trunk` | 8 324 MeshForest + 139 CityFill + 132 decor | `bark_kyoto` | 100% slot 9. Dala `bark` -> (131,92,52): (0.769, 0.668, 0.517). |
| `cedar_dark` · `Cedar_Dark` | 3 816 MeshForest + 192 tunel | `cedar_needles` | 97% slot 21 + 3% slot 28 (piciorul, sub prag — ca `beech_dead`). Dala `pine_needles` -> (63,122,60): (0.639, 0.932, 0.898). Stolul din tunelul de torii primeste clasa explicit (`torii_tunnel.gd`, `FlockProp.tri_class`). |
| `niwaki_pine` · `Pine_Crown` | 338 MeshForest + 50 | `cedar_needles` | 100% slot 21. |
| `karikomi_shrub_a/b` | 63 | `moss` | 63/37 slot 21/12 pe acelasi y (umbrirea tufei). +0. |
| `stepping_stones` | 4 | `garden_stone` | 83% slot 29. +0. |

**Coama de pe acoperisuri.** Pe acoperisuri slotul 28 nu e umbrire: e coama si
streasina (intervalul lui de y il cuprinde pe al slotului 20 la ambele capete),
deci nu se poate rupe ca accent. Clasa il sterge deliberat. Pe captura (poarta
Romon, f0.47) dunga bruna de coama citea „scandura" pe un acoperis de tigla.

**Scara acelor.** `cedar_needles` a pornit la scara dalei-sursa (0.6) si a dat
pe padurea Inari detaliu fin +17%, mediu -5% fata de atlas (masurat pe f0.47,
diferente de blur 1 px / 4 px). La 0.3: fin +25%, mediu la nivelul atlasului.
Castig mic — acesta e cel mai slab lot al valului.

## Valul 2: rosul, bambusul, Kiyomizu

Cererea dezvoltatorului dupa capturile din joc: „peste tot unde avem materialul
rosu (pagoda, umbrele, pod, tren), padurea de bambus Arashiyama, Kiyomizu".
Erau exact nodurile MIXTE refuzate in valul 1. Rezolvarea: **ruptura pe slot**
(`Palette.split_accents`, pe triunghi), scopata pe tema
(`WorldProp.SPLIT_MODELS_BY_THEME` / `ACCENT_SPLIT_BY_THEME["kyoto"]`), cu
clasele in `CLASSES_BY_THEME["kyoto"]` (se aplica DUPA ruptura amanata).
Piesele de arhitectura au sloturile pe fete separate, deci ruptura e exacta.

| piesa · nod | ruptura (corp / accent) | clasa corp / accent |
|---|---|---|
| pagode · `Pagoda_Body` | 30 / var 22 + lemn 28 | `shu_vermilion` / atlas |
| `niomon_gate`, `inari_romon` · `Gate_Wood` | 30 / 9 + 28 | `shu_vermilion` / atlas |
| `torii_senbon`, `torii_large` (tunel + bulevard + portile mari) | 30 / kasagi 28 + soclu 20 | `shu_vermilion` / atlas |
| `small_shrine` · `Shrine_Wood`; `Shrine_Roof` | 30 / rest; 6+28 / fascia 30 | `shu_vermilion` / atlas; `kawara` / `shu_vermilion` |
| `votive_torii_cluster` · `Torii_Wood` | — (100% 30) | `shu_vermilion` |
| `kiyomizu_hondo` · `Hondo_Wood` (stalpii scenei) | 28 / 9 | `machiya_wood` / `wood` |
| `kakezukuri_scaffold` · `Scaffold_Wood` | 9 / 27 + 8 | `wood` / atlas |
| `kinkakuji` · `Kin_Wood`; `togetsukyo` · `Toget_Wood`; `tsutenkyo` · `Tsu_Wood` | 9 / 28 | `wood` / `machiya_wood` |
| `moso_culm` (9 154 in MeshForest) · `Moso_Culm` | 12 / inelele 13 | `bamboo_culm` / atlas |
| `bamboo_crown` · `Bamboo_Culms` | 21 / inelele 13 | `bamboo_culm` / atlas |
| `iron_truss_bridge` · `Truss_Iron`; `teahouse_front` · `Tea_Red` (umbrelele); `kitsune` · `Fox_Bib` | — (100% 14) | `shu_red` |
| `sagano_train` · `Train_Body`; `jinrikisha` · `Rick_Red` (MOBILE) | — | `shu_red`, in spatiul OBIECTULUI |

**Cod nou.** `MeshForest` si `FlockProp` nu stiau de ruptura: `mesh_forest.gd`
rupe acum nodul in doua suprafete (`_split_part`), iar `FlockProp.split_keep`
pune accentul intr-un stol-copil `_Accente` cu aceleasi transformari (portile
din tunel). Piesele mobile intra prin `WorldProp.KYOTO_MOVING_CLASSES` (in
`prop_classes()`, nume unice in tot `assets/models/`, verificat cu grep), iar
`PathMover` le reaplica AMANAT: trenul sta sub `DecorManual`, al carui
`apply_class_materials` rescria subarborele in varianta DE LUME (textura ar fi
„inotat" pe vagoane). Reaplicarea e scopata pe lista Kyoto: generala, muta si
piesele mobile de pe Baikal/Stromboli (masurat: Track10 si Track11 +1 material).

**Dala.** Prima incercare a fost `concrete` ridicata (pata de lac fara fibra) si
a dat MAI PUTIN detaliu decat atlasul cu stratul de detaliu partajat — masurat
pe capturi, diferenta de blur 1 px: pod 4.85 -> 4.65, bambus 3.11 -> 2.74. Pe o
culoare saturata ridicata, R se taie si variatia ramane doar pe G/B. Cu dala
`wood` ridicata la 0.65 (deviatia de luminanta a rezultatului 27.5 fata de
14.6): pod **4.85 -> 5.91**, bambus **3.11 -> 3.89**, tunelul de torii 2.13 ->
2.27. Pentru rosu imaginea e ROTITA 90 de grade (`CLASS_LIFT_ROTATE`): cu
scandurile orizontale stalpii toriilor pareau din discuri stivuite; pe bambus
rosturile orizontale raman — la scara 0.5 cad la ~0.33 m si se citesc noduri.
Rosul iese cu 14% sub slot (R 200 din 232): lac invechit, ales in locul a 32%
pixeli taiati la ridicarea care ar fi atins tinta.

**Buget.** +3 clase de lume (`shu_vermilion`, `shu_red`, `bamboo_culm`) + 1
varianta de obiect (`shu_red` pe tren/ricsa) = 37 / 38. Doua imagini ridicate
noi in memorie (rosu rotit, bambus), 512² fiecare.

## Refuzate, cu cifra

| piesa | motiv |
|---|---|
| `kinkakuji` · `Kin_Gold` | foita de aur e neteda: culoarea plata e materialul. |
| `paper_lantern` · `Lantern_Wood`, `ema_rack`, `shiba_fence` | piese sub 0,3 m sau panouri subtiri (mipmap). |
| vehicule `gion_boko`, `yakatabune`, `shishimai`, `daruma_otoshi`, animale | pictate, multe sloturi pe acelasi nod; hazardele isi tin culorile de citire. |
| `kyoto_horizon` | petice de toamna pictate intentionat (`horizon_class: ""`). |
| esafodajul kakezukuri · stalpii LARCH_RUST 27 | mai deschisi decat orice clasa de lemn de pe pista; raman pictati. |

## Sonde (raman in repo)

- `tools/probe_kyoto_kit_clase.gd` (`-s`) — inventarul kitului: arie pe slot,
  interval de y pe slot, latimea gabaritului, UV colapsat/real, clasa de azi.
- `tools/ProbeKyotoClase.tscn -- --track=18` — pe pista incarcata, clasa
  ajunsa PE OBIECT, pe cele patru drumuri (WorldProp, CityFill, MeshForest pe
  suprafete, FlockProp), plus lista claselor construite. A prins defectul
  `Wall_Roof` inainte de orice modificare.

## Deschis

1. **Bugetul: 37 / 38.** Urmatoarea clasa pe Kyoto cere sa scoata una. Prima
   candidata e `cedar_needles` (cel mai slab castig masurat, fin +25%, mediu
   egal cu atlasul).
2. **Podul de fier** poarta fibra de lemn rosie (`shu_red` pe `wood`): mai bogat
   decat rosul plat, dar e lemn, nu metal. Verdict la volan.
3. **Nuanta kawara** iese gri-mov sub lumina temei. Verdictul dezvoltatorului.
4. **Reflexia Pavilionului de Aur** are propriile materiale (`alt` in sonda) si
   ramane pe culorile vechi.
5. Piesele mobile de pe Baikal/Stromboli primesc clasele in varianta de LUME
   cand stau sub un `DecorManual` (acelasi mecanism ca trenul Kyoto). Nu e
   reparat aici — schimba alte piste.
