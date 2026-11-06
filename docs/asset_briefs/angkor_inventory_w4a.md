# Angkor, val 4, grupul A: copacii (kit §1.7)

Script: `tools/blender/build_angkor_trees.py`. Garda: `tools/blender/measure_angkor_w4a.py` (bloc `val 4, grupul A` in `verify_angkor.sh`). Preview: `preview_angkor.py --compare/--views <nume>`, `preview_angkor_w4a.py --grove`.

| piesa | inaltime | triunghiuri (Trunk + Leaves) | note |
|---|---|---|---|
| `plants/tetrameles_a.glb` | 27,00 m | 2.348 (836 + 1.512) | 7 contraforturi-placa, intindere 8,98 m, inaltime 3,06 m; 8 ramuri, 4 ciorchini de mase |
| `plants/tetrameles_b.glb` | 25,77 m | 2.084 (908 + 1.176) | 9 contraforturi mai scurte, intindere 9,82 m, inaltime 3,16 m; 6 ramuri, coroana mai lata |
| `plants/dipterocarp.glb` | 35,37 m | 1.808 (632 + 1.176) | trunchi curat 22 m, evazare mica (aripi 1,7-2,6 m), coroana de ~12,5 m |
| `plants/sugar_palm.glb` | 14,47 m | 2.330 (220 + 2.110) | trunchi `WOOD` cu baza mai groasa si 3 inele; 22 de frunze (petiol 1,9-2,2 m + evantai de 8 pene de acordeon, notat) culcate pe sfera coroanei + 3 frunze uscate pe trunchi (`WOOD` 9); coroana ~5,8 m |

Noduri: `Tree_Trunk` + `Tree_Leaves` (doua materiale/noduri, ca `banyan.glb`); originea la baza trunchiului; fara bevel. Sloturi: scoarta `CORAL_SAND` 19 cu AO cald (exponenti 0,85/1,25/1,75), frunzis `TROPICAL_GREEN` 21 cu mase `CACTUS_GREEN` 12 sus si pe margini; palmier: trunchi `WOOD_WEATHERED` 9, evantaie 12 + 21.

Plafon de triunghiuri al gardei: 2.500 per copac (coborat de la 3.500 dupa verdictul coordonatorului). Trimul: masele de frunzis au 7 segmente x 3 inele (nu 8 x 4), contraforturile 5 trapeze (nu 6, cu inaltimea ridicata cu 0,4 m ca masura sa ramana 3-4 m); tinte: tetrameles <= 2.400, dipterocarp <= 2.000, palmier <= 2.500. Silueta din grove nu s-a schimbat vizibil.

## Lectii aplicate din w1b
Contraforturile sunt aripi plate (trapeze subtiri 0,36 -> 0,10 m pe o curba concava), nu tuburi. Coroana: ciorchini de mase turtite pe ramuri, la inaltimi diferite, nu calota.

## Rezerve cinstite (nu e acceptare)
- Palmierul (runda a doua): coroana citeste acum ca o bila de evantaie plisate si taiate, dar e mai densa si mai neteda decat desenul (care are degete lungi si subtiri si goluri luminoase), cu 5-6 evantaie de sus aproape plate ca niste farfurii; bila e ~5,8 m, nu 6-7. Frunzele uscate de pe trunchi abia se vad.
- Cei trei copaci mari: aceleasi observatii ca la prima runda (coroane faceted "mase rotunde", contraforturi putine si drepte fata de desen).
- Verificate doar prin randari Blender (fara Godot).

Imagini: `docs/asset_briefs/img/angkor_fidelity/{tetrameles_a,tetrameles_b,dipterocarp,sugar_palm}{,_views}.png`, `angkor_trees_grove_gamecam.png`, `angkor_trees_grove_far.png`.
