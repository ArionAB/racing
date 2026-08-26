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
