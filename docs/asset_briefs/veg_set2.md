# Brief asset — Vegetație runda 2 (`fern_cluster`, `broadleaf_shrub`, `flowers_coral`)

Trei piese de umplutură pentru tivul de umăr și subarboretul din Track08
(imaginea de referință a drumului de coastă). Spre deosebire de brief-urile de
landmark, ăsta documentează un set construit **in-house, procedural** — nu e un
prompt pentru un agent extern. Sursa reproductibilă e
[tools/blender/build_veg_set.py](../../tools/blender/build_veg_set.py)
(secțiunea „Runda 2"), pe vocabularul din `dio_lib` (`leaf_crown`, `blades`,
`core_mound`, `flower_heads`).

Setul original de cinci piese (#208) nu are brief — regula rămâne că filler-ul
procedural se documentează în capul generatorului; fișierul ăsta există doar
pentru că runda 2 ia o **decizie de paletă** care trebuie să fie găsibilă.

## 1. De ce există

Rotația de vegetație măruntă avea 7 specii, toate smoc sau rozetă. Tivul
continuu de la umăr (Verge_Umar) și subarboretul (Sub_Palmieri) repetau
aceleași două siluete la nesfârșit. Lipseau:

- **arcul** — `Fern_Cluster`, numai fronde pe unghiul de aur, fără miez
  (miezul i-ar umple exact golul dintre fronde care o face ferigă);
- **plinul** — `Broadleaf_Shrub`, miez + coroană cu frunze late
  (`width_f 0.22`), silueta de gard viu; gabarit ~78% din `tropical_shrub`,
  ca să încapă în tiv fără să-l înghită;
- **a treia culoare de floare** — `Flowers_Coral`.

## 2. Decizia de paletă (motivul brief-ului)

Referința are flori roz. **Nu există slot roz legal**: 14–16 sunt accentele
mașinilor, 24–31 se randează magenta intenționat. Singurul ton cald-pal din
mediul insular e `CORAL_SAND` (19), care lângă terracotta și alb citește a
floare decolorată de soare — decizia e **asta**, nu un slot nou în atlas.
Capetele stau la 0.24 m (regula de la alb: sub 20 cm discul înmulțit cu AO
dispare), dar sunt 10, nu 12: coralul e accentul rar, nu covorul.

## 3. Măsurat (`verify_glb.py`: toate OK)

| piesă | tris (buget 900) | bbox | sloturi |
|---|---|---|---|
| `plants/fern_cluster.glb` | 784 | 1.42 × 1.29 × 0.55 m | tropical_green, cactus_green |
| `plants/broadleaf_shrub.glb` | 728 | 1.80 × 1.83 × 0.94 m | tropical_green, cactus_green |
| `flowers/flowers_coral.glb` | 776 | 1.51 × 1.39 × 0.65 m | + coral_sand |

```
python tools/blender/verify_glb.py assets/models/plants/fern_cluster.glb 900
python tools/blender/verify_glb.py assets/models/plants/broadleaf_shrub.glb 900
python tools/blender/verify_glb.py assets/models/flowers/flowers_coral.glb 900
```

AO copt în vertex colors (`AO_VEG`), gradient de tentă `TINT_LUSH`, origine la
bază centrată în XZ, volume închise (materialul de lume e CULL_BACK). Contract
complet: [blender_export.md](../blender_export.md).

## 4. Unde intră

`track08.gd`: în `pajiste_species` (rotația Pajiste + Sub_Palmieri, cu
ponderile vechi scăzute ca să nu crească costul mediu) și ca straturi rare în
`Verge_Umar` (tufa lată la pas 40 m, coralul la 55 m — linia tivului are
~2.6 km pe ambele laturi, fiecare metru de pas costă zeci de mii de tris).
