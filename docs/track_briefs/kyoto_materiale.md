# Kyoto (Track18) — valul de materiale pe kit

> 4 oct 2026, ramura `kyoto/materiale`. Tiparul: `fiordland_materiale.md` /
> `serengeti_materiale.md`. Despre CE are textura de clasa si CE nu, pe tot
> kitul din `assets/models/kyoto/`. Inaintea valului, integrarea int-a clasase
> doar casele (lemn, var), coroanele, felinarele si pietrele.

## Bilant

- Garda de materiale (`tools/probe_decor.gd`, toate pistele): **Track18 29 -> 33 / 38**.
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

## Refuzate, cu cifra

| piesa | motiv |
|---|---|
| `torii_senbon`, `torii_large` (tunelul, gimmick-ul E') | 57-60% slot 30 + 33-35% slot 28 (kasagi) + 7-8% slot 20 (soclu), intervale separate — ruptura ar fi curata, DAR portile sunt `FlockProp` (un MultiMesh, UN material). O clasa pe stol ar sterge kasagi-ul negru. In plus, lacul vermilion e o suprafata neteda: culoarea plata e chiar materialul. Vezi Deschis 1. |
| `votive_torii_cluster` · `Torii_Wood` | 100% slot 30, dar acelasi argument de lac; o clasa vermilion ar cere CLASS_LIFT (R tinta 232 > media dalei `wood`). |
| `niomon_gate`/`inari_romon` · `Gate_Wood` | 74-77% slot 30, plus grinda 9 (8,4-9,2 m) si 28 pe aproape toata inaltimea. Mixt. |
| `kiyomizu_hondo` · `Hondo_Wood` | 59/38 slot 28/9 pe acelasi y (stalpii scenei). O clasa ar sterge contrastul stalp/grinda. |
| `kinkakuji` · `Kin_Wood`, `togetsukyo` · `Toget_Wood`, `kakezukuri_scaffold` | 9/28 (sau 9/27) intercalate pe acelasi y. |
| `tsutenkyo` · `Tsu_Wood` | 9 la -1,25..4,95, 28 la 4,22..7,97: suprapunere 0,73 m (8%). Ruptura posibila, nefacuta in valul asta (6 instante). |
| pagode · `Pagoda_Body` | vermilion + var + lemn intercalate (30/22/28). |
| `kinkakuji` · `Kin_Gold` | foita de aur e neteda: culoarea plata e materialul. |
| `bamboo_crown` · `Bamboo_Culms`, `moso_culm` | tulpini de 10-16 cm: textura cade in mipmap. |
| `paper_lantern` · `Lantern_Wood`, `ema_rack`, `shiba_fence` | piese sub 0,3 m sau panouri subtiri (mipmap). |
| `small_shrine` | acoperisul are fascia vermilion (21%) pe acelasi y; piatra are var pe capac. |
| vehicule (`gion_boko`, `jinrikisha`, `sagano_train`, `yakatabune`), `shishimai`, `daruma_otoshi`, animale | vopsite/pictate, multe sloturi; hazardele isi tin culorile de citire. |
| `kyoto_horizon` | petice de toamna pictate intentionat (`horizon_class: ""`). |

## Sonde (raman in repo)

- `tools/probe_kyoto_kit_clase.gd` (`-s`) — inventarul kitului: arie pe slot,
  interval de y pe slot, latimea gabaritului, UV colapsat/real, clasa de azi.
- `tools/ProbeKyotoClase.tscn -- --track=18` — pe pista incarcata, clasa
  ajunsa PE OBIECT, pe cele patru drumuri (WorldProp, CityFill, MeshForest pe
  suprafete, FlockProp), plus lista claselor construite. A prins defectul
  `Wall_Roof` inainte de orice modificare.

## Deschis

1. **Tunelul de torii.** Daca se vrea textura pe stalpii vermilion: `FlockProp`
   ar trebui sa accepte o ruptura (corp cu clasa + stol-copil `_Accente` pe
   atlas, aceleasi transformari) si o clasa vermilion cu CLASS_LIFT. Intai
   verdict la volan: lacul plat poate fi exact ce trebuie.
2. **Reflexia Pavilionului de Aur** are propriile materiale (`alt` in sonda):
   acoperisul reflectat ramane pe culoarea veche. La distanta jocului nu se
   distinge; de verificat pe captura de aproape daca deranjeaza.
3. **Nuanta kawara** iese gri-mov sub lumina temei (soare #FFD8A8 + ambient
   albastru) — acoperisurile vechi pe slotul 20 ieseau bleumarin sub aceeasi
   lumina. Verdictul dezvoltatorului pe captura.
4. `Tsu_Wood` (ruptura 8%) si `Hondo_Wood` (scena Kiyomizu, hero) — candidate
   pentru un val urmator, cu ruptura sau re-export pe noduri separate.
