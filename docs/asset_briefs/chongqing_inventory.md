# Chongqing — inventar de assets (planşa `img/Chongqing_assets.png`)

Un fişier per piesă, sub `assets/models/chongqing/<categorie>/`.
Sloturi: doar cele existente (31 rămâne rezerva magenta; `NEON_PINK` e o
decizie de integrare, nu de build — firmele neon folosesc KERB_RED/CAR_RED
până când slotul se deschide).

| # planşă | fişier | script |
|---|---|---|
| 1 | `structures/hongya_dong.glb` | build_chongqing_hongya.py |
| 2 | `buildings/liziba_block.glb` | build_chongqing_liziba.py |
| 3 | `vehicles/monorail_train.glb` | build_chongqing_monorail.py |
| 4 | `vehicles/cableway_cabin.glb`, `structures/cableway_tower.glb` | build_chongqing_cableway.py |
| 5 | `structures/ramp_straight_10m.glb`, `ramp_arc_15deg.glb`, `pillar_round.glb`, `parapet_module.glb`, `launch_ramp.glb`; `props/construction_barrier.glb` | build_chongqing_interchange.py |
| 6 | `structures/rotating_span.glb` | build_chongqing_rotating_span.py |
| 7 | `structures/tower_crane.glb`, `props/prefab_slab.glb` | build_chongqing_crane.py |
| 8 | `vehicles/cargo_ship.glb` | build_chongqing_ship.py |
| 9 | `structures/bay_bridge.glb` | build_chongqing_bridge.py |
| 10 | `buildings/kuixinglou_pavilion.glb` | build_chongqing_pavilion.py |
| 11 | `structures/stone_stairway.glb` | build_chongqing_stairway.py |
| 12 | `structures/footbridge.glb` | build_chongqing_footbridge.py |
| 13 | `props/crossing_barrier.glb` | build_chongqing_crossing.py |
| 14 | `props/cliff_railing.glb` | build_chongqing_railing.py |
| 15 | `props/lamp_lantern_{a,b,c}.glb`, `neon_sign_{a,b,c,d}.glb`, `bollard.glb`, `bicycle.glb`, `mailbox_wall.glb`, `scooter.glb`, `table_stools.glb`, `steam_vent.glb`, `laundry_line.glb`, `porter.glb` | build_chongqing_kit_a.py |
| 16 | `buildings/shophouse_{a,b,c}.glb`, `restaurant_front.glb`, `tower_silhouette_{a,b,c}.glb`; `vehicles/bus.glb`, `mini_car_{a,b,c}.glb`; `props/container.glb` | build_chongqing_kit_b.py |
| 17 | `props/chevron_post.glb` | există deja (`props/chevron_post.glb`) — se reutilizează |


## Rezultat (48 GLB-uri, 171732 triunghiuri)

Toate trec `verify_glb.py`: sloturi legale, AO copt in vertex colors,
originea pe contractul cerut de fiecare piesa.

| fisier | tris |
|---|---:|
| `buildings/kuixinglou_pavilion.glb` | 12072 |
| `buildings/liziba_block.glb` | 20300 |
| `buildings/restaurant_front.glb` | 3692 |
| `buildings/shophouse_a.glb` | 2200 |
| `buildings/shophouse_b.glb` | 2992 |
| `buildings/shophouse_c.glb` | 2068 |
| `buildings/tower_silhouette_a.glb` | 2024 |
| `buildings/tower_silhouette_b.glb` | 2948 |
| `buildings/tower_silhouette_c.glb` | 1408 |
| `props/bicycle.glb` | 1488 |
| `props/bollard.glb` | 320 |
| `props/cliff_railing.glb` | 1020 |
| `props/construction_barrier.glb` | 640 |
| `props/container.glb` | 2112 |
| `props/crossing_barrier.glb` | 940 |
| `props/lamp_lantern_a.glb` | 1060 |
| `props/lamp_lantern_b.glb` | 1876 |
| `props/lamp_lantern_c.glb` | 652 |
| `props/laundry_line.glb` | 840 |
| `props/mailbox_wall.glb` | 1716 |
| `props/neon_sign_a.glb` | 376 |
| `props/neon_sign_b.glb` | 904 |
| `props/neon_sign_c.glb` | 376 |
| `props/neon_sign_d.glb` | 992 |
| `props/porter.glb` | 1008 |
| `props/prefab_slab.glb` | 684 |
| `props/scooter.glb` | 1188 |
| `props/steam_vent.glb` | 404 |
| `props/table_stools.glb` | 1332 |
| `structures/bay_bridge.glb` | 1308 |
| `structures/cableway_tower.glb` | 3588 |
| `structures/footbridge.glb` | 7392 |
| `structures/hongya_dong.glb` | 62988 |
| `structures/launch_ramp.glb` | 704 |
| `structures/parapet_module.glb` | 220 |
| `structures/pillar_round.glb` | 656 |
| `structures/ramp_arc_15deg.glb` | 2640 |
| `structures/ramp_straight_10m.glb` | 528 |
| `structures/rotating_span.glb` | 1152 |
| `structures/stone_stairway.glb` | 4276 |
| `structures/tower_crane.glb` | 5368 |
| `vehicles/bus.glb` | 1080 |
| `vehicles/cableway_cabin.glb` | 1152 |
| `vehicles/cargo_ship.glb` | 2992 |
| `vehicles/mini_car_a.glb` | 992 |
| `vehicles/mini_car_b.glb` | 992 |
| `vehicles/mini_car_c.glb` | 992 |
| `vehicles/monorail_train.glb` | 3080 |
| **TOTAL** | **171732** |
