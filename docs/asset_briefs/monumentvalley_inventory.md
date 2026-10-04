# Inventar — kitul Monument Valley (Track19)

Contract: `docs/asset_briefs/monumentvalley_kit.md`. Cotele sunt MASURATE din GLB
(`verify_glb.py`, Godot Y-up; Blender +Y = Godot -Z).

## rocks/west_mitten.glb (pilot)

| nod | slot(uri) | tri |
|---|---|---:|
| `Mitten_Rock` | TILE_TERRACOTTA 23 + RUST_METAL 10 (fetele cu normala spre -X) | 828 |
| `Mitten_Scree` | RUST_METAL 10 + LARCH_RUST 27 (terase alternante, bolovani alternanti) | 2776 |
| `Mitten_Cap` | MARBLE_GREY 29 | 184 |
| total | `VERDICT KIT: OK` (`--origin=assembly`) | 3788 |

Cote masurate: turn 29,1 m perete + 0,9 m calota = **30,0 m**; peretele X
-12..+12 (24 m), adancime ~13-14,5 m (coloanele ies +-0,7); deget **x -19,95..
-14,9** (~5 m la baza, ~3,5 m la mijloc), **26,0 m** (25,5 + calota 0,5), gol
**2,9 m** fata de corp pe -X; fusta pana la x -23,7..+23,2 / z +-18,5 (raza ~22 m),
inalta **5,0 m** (bolovani incluși); origine la baza turnului (XY pastrat, Z min = 0).

Fidelitate: `docs/asset_briefs/img/monumentvalley_fidelity/west_mitten.png`
(decupare | randare), 4 azimuturi: `west_mitten_views.png`. 3 runde facute.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| coloane pe fața lungă | ~11 | 12, fiecare cu V pe față (2 fațete), 3 segmente cu prag | OK ca număr; abatere: la noi sunt prisme drepte, pe planșă coloanele sunt teșite/rotunjite și mai late |
| umeri | stânga/dreapta în trepte | 3 trepte stânga, 3 dreapta | OK |
| calota | strat palid festonat, 2 trepte | 2 trepte (0,5 + 0,4) pe 6 coloane de sus | OK ca formă; **abatere de culoare**: MARBLE_GREY e gri rece, planșa are bej cald (slot impus de contract) |
| fusta de grohotiș | ~5 terase, caneluri radiale, urcă ~1/6 | 6 terase, tilt radial, 5,0 m (1/6) | OK; abatere: terasele se citesc mai concentrice/netede decât pe planșă |
| bolovani | ~18 mari + ~25 mici | 60 mari (1,3-3,5 m, ≤ 5 m cota) + 26 mici | OK; mai colțuroși ar ajuta |
| deget | separat, ~85% din turn, 2 trepte de umăr, vârf rotunjit | separat, 26 m (87%), 3 coloane, umăr la 12,5 m, **vârf plat tăiat (tesit slab)** | abatere: vârful nu e rotunjit-ascuțit ca pe planșă |
| gol de cer | vizibil până jos | 2,9 m, vizibil din față și din 3 azimuturi; din spate degetul se suprapune corpului | OK |
| luminozități | stânga umbrită, față mai caldă | fețele -X pe RUST_METAL, restul TERRACOTTA | OK |
| proporție h/l turn | ~1,1-1,2 | 30/24 = 1,25 | în ±15% la limită |

## Stare la oprire

- Pilotul `west_mitten` livrat și verificat; harnasul (`monument_shapes.py`,
  `preview_monument.py` + `compose_monument.py`, `verify_monumentvalley.sh`)
  funcționează. Alte piese: nenecesare în pilot.
- Abateri deschise (runde 3/3 consumate): vârful degetului nerotunjit,
  coloane prismatice (fără teșituri mari), culoarea calotei (slot).
- `preview_monument.py` pune clasa `mv_sandstone` (#B8552E) pe nodurile `*_Rock`.
