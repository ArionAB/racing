# Foi de referință vizuală

Imagini generate pentru a transmite **siluetă, proporție și inventar** către
agentul care modelează în Blender. Nu sunt assets de joc și nu intră în build —
`.gdignore` oprește Godot din a le importa ca texturi.

## Cum se citesc

O imagine aici **nu e o țintă de reprodus.** Asset-urile se scriu în cod din
primitivele din [`tools/blender/dio_lib.py`](../../tools/blender/dio_lib.py), deci
o referință se *descompune* în cutii, cilindri și stânci — nu se recreează.

Ce se preia: **silueta, proporțiile, inventarul, aranjarea maselor mari.**

Ce **nu** se preia: rugina, murdăria, striațiile, orice detaliu de suprafață.
Astea vin la runtime dintr-un strat triplanar partajat
(`Palette.world_material()`), iar `docs/style_bible.md` §3 interzice explicit
detaliul de frecvență înaltă modelat în geometrie — dispare la 60 km/h și
transformă silueta în zgomot.

Randările de mai jos au toate finisaj foto-ish. **Ignoră-l.**

## Foile

| fișier | ce conține | briefuri derivate |
|---|---|---|
| `sheet_wave1_props.png` | Stâlpi de marcaj, bolovani, poartă START/FINISH, schelet de dinozaur, excavator ruginit, variante de țeavă spartă. Plus umplutură: ladă, tambur de cablu, pompă de petrol, teanc de cauciucuri, con, semn de reparații, barieră, tufe. | `marker_post`, `boulder_roller`, `start_gate`, `dino_bones`, `rusted_digger`, `pipe_leak` |
| `sheet_scale_rocks_cactus_barrels.png` | **Foaia de scară.** Variante numite, fiecare cu înălțimea în metri, plus o mașină de referință de 4.0 m. Cactuși 0.8–3.0 m, butoaie 0.9 m, stânci de canion small 0.5–2 m / medium 2–5 m / large 6–10 m. Conține și o **arcadă de stâncă**. | `rock_arch`; referință de cotă pentru tot restul |
| `sheet_railway_diorama.png` | Diorama de cale ferată: locomotivă, vagoane, piese de șină, **portal de tunel săpat în stâncă**, semnale de trecere, turn de apă, moară, șopron, lăzi, gard. | `mine_portal`; referință pentru trenul deja implementat |
| `sheet_canyon_road.png`, `sheet_canyon_wide.png` | Referințele originale de atmosferă: drum prin canion de deșert, fără bariere, cu stânci și cactuși lipiți de șosea. Au dat direcția generală a pistei Dunele. | — |

## Nota de scară

`sheet_scale_rocks_cactus_barrels.png` e cea mai utilă foaie din folder, fiindcă
rezolvă singura limitare reală a unei imagini: **o poză nu poate purta scara.**
Aia are cotele scrise pe ea.

Mașina ei de referință e 4.0 m; a noastră e **4.2 m** (`body_length` din
`scenes/cars/data/muscle.tres`). Diferența de 5% e sub pragul de vizibilitate —
folosește cotele foii ca atare.

Briefurile mai vechi din `docs/asset_briefs/` spun „mașina de referință = 4 m".
E aceeași aproximare, nu o contradicție.
