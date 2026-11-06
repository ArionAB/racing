# Angkor, val 4, grupul A: copacii (kit §1.7)

Script: `tools/blender/build_angkor_trees.py`. Garda: `tools/blender/measure_angkor_w4a.py` (bloc `val 4, grupul A` in `verify_angkor.sh`). Preview: `preview_angkor.py --compare/--views <nume>`, `preview_angkor_w4a.py --grove`.

| piesa | inaltime | triunghiuri (Trunk + Leaves) | note |
|---|---|---|---|
| `plants/tetrameles_a.glb` | 26,95 m | 3.224 (920 + 2.304) | 7 contraforturi-placa, intindere 8,98 m, inaltime 3,19 m; 8 ramuri, 4 ciorchini de mase |
| `plants/tetrameles_b.glb` | 25,78 m | 2.808 (1.016 + 1.792) | 9 contraforturi mai scurte, intindere 9,82 m, inaltime 3,31 m; 6 ramuri, coroana mai lata |
| `plants/dipterocarp.glb` | 35,35 m | 2.424 (632 + 1.792) | trunchi curat 22 m, evazare mica (aripi 1,7-2,6 m), coroana de ~12,5 m |
| `plants/sugar_palm.glb` | 15,70 m | 2.356 (396 + 1.960) | trunchi `WOOD` cu 5 inele de cicatrici, 20 de evantaie de 7 degete |

Noduri: `Tree_Trunk` + `Tree_Leaves` (doua materiale/noduri, ca `banyan.glb`); originea la baza trunchiului; fara bevel. Sloturi: scoarta `CORAL_SAND` 19 cu AO cald (exponenti 0,85/1,25/1,75), frunzis `TROPICAL_GREEN` 21 cu mase `CACTUS_GREEN` 12 sus si pe margini; palmier: trunchi `WOOD_WEATHERED` 9, evantaie 12 + 21.

Plafon de triunghiuri al gardei: 3.500 per copac (plasa pentru accidente, nu tel; referinte: `beech_a` 228, banyan ~1-2k; copacii astia sunt mult mai inalti). Atentie: sunt de 2-10 ori mai grei decat copacii existenti; la sute de instante in MultiMesh coordonatorul poate cere o runda de reducere (mase cu 7 segmente / 3 inele taie ~25%).

## Lectii aplicate din w1b
Contraforturile sunt aripi plate (trapeze subtiri 0,36 -> 0,10 m pe o curba concava), nu tuburi. Coroana: ciorchini de mase turtite pe ramuri, la inaltimi diferite, nu calota.

## Rezerve cinstite (nu e acceptare)
- Contraforturile se citesc ca aripi, dar sunt putine si drepte fata de desen (care are o ghemotoace de radacini sinuoase); fiecare e subtire spre varf.
- Coroanele sunt "mase rotunde" faceted, inca aproape de brocoli, doar mai neregulate; sub desen ca bogatie de frunze.
- Palmierul: coroana e un snop ascutit, nu evantaie clar palmate; oblata, nu sfera. Trunchiul e drept si netezit, fara inelele evidente din desen.
- Dipterocarpul: coroana mica si inalta cum cere brief-ul, dar mult mai saraca decat desenul.
- Verificate doar prin randari Blender (fara Godot); clasele/materialele din joc nevazute.

Imagini: `docs/asset_briefs/img/angkor_fidelity/{tetrameles_a,tetrameles_b,dipterocarp,sugar_palm}{,_views}.png`, `angkor_trees_grove_gamecam.png`, `angkor_trees_grove_far.png`.
