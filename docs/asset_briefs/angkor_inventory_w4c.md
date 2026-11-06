# Angkor — inventar val 4, grupul C: fundalul (`angkor_horizon`)

Piesa: `assets/models/angkor/effects/angkor_horizon.glb` (kit §1.8), generată de
`tools/blender/build_angkor_horizon.py`. Garda: `tools/blender/measure_angkor_w4c.py`
(în `verify_angkor.sh`, blocul „val 4, grupul C”). Randări: `tools/blender/preview_angkor_horizon.py`
(+ `compose_angkor_horizon.py`, PIL). Nu acceptat: decizia e a coordonatorului.

## Noduri (7, copii directi ai radacinii, volume inchise, fara coliziune)

| nod | lungime | cote Y | tri | sloturi | cum e facut |
|---|---|---|---|---|---|
| `Canopy_A` | 217 m | 0–32,1 | 3.656 | 21, 12 | cupole suprapuse de coroană (≈75), 8 dipterocarpi emergenți (trunchi + coroană în nori) |
| `Canopy_B` | 180 m | 0–33,2 | 3.012 | 21, 12 | idem, 6 emergenți, alt seed |
| `Canopy_C` | 230 m | 0–31,1 | 4.896 | 21, 12 | idem, 9 emergenți |
| `KulenRidge` | 300 m | 0–42,5 | 1.526 | 21 | heightfield închis, creastă lungă și plată cu un umăr |
| `StormBand_A` | 297 m | **46,0**–117,9 | 6.824 | 20, 29 | strat de bază cu fund PLAT la 46 m + 6 turnuri cu coroană de bile (conopidă de cumulus) |
| `StormBand_B` | 255 m | **54,0**–113,6 | 6.148 | 20, 29 | idem, baza la 54 m |
| `Paddies_W` | 254 m | 0–15,7 | 2.404 | 12, 17, 20, 21 | placă de diguri (21), 30 de parcele (12 câmp, 17 apă, ~42%), perdea de copaci joși, 13 palmieri de zahăr (trunchi 20, coroană 21) |

**Total: 28.466 triunghiuri** (țintă ≤ 40k). GLB ≈ 1 MB.

Convenții: ca la `carrara_horizon`/`fiordland_horizon`, noduri copii ale rădăcinii, centrate pe X/Y,
talpa la Y = 0. **Excepție declarată: `StormBand_*` își păstrează baza la cota 40–60 m**
(kit §1.8, norul plutește); fișierul rămâne cu min Y = 0 prin celelalte noduri
(`verify_glb --origin=assembly`). Culoare: doar sloturile din tabel; AO vertical copt (norii
0,50→0,80, vegetația 0,40→1,0 + `tint_gradient`).

Norii: `VOLCANIC_BLACK` 20 pe tot ce e sub ~40% din grosime și pe fețele orientate în jos (baza
plată e mereu 20), `MARBLE_GREY` 29 pe jumătatea de sus (linie de umbră ușor ondulată). Doar două
sloturi nu fac gradient neted: tranziția o dă AO-ul copt pe vârfuri.

## Ce face `Track._build_horizon` cu nodurile (citit în `track.gd`, nu modificat)

* `_extract_glb_node` păstrează nodul cerut **după nume** și setează `container.position =
  -kept.position`: **poziția X/Z din GLB e ignorată**. Nu există „azimut din poziția nodului”.
* Azimutul vine din INELE, în tema `angkor`: `horizon_rings` cu `count`, `near`, `far`, `clear`,
  `scale`, `picks` (sau `horizon_picks` paralel cu inelele) și, **opțional, `angle_deg`** (azimut
  fix: cos pe X, sin pe Z față de centroid; **est = 0°, nord = −90°, vest = 180°, sud = +90°**)
  plus `yaw_deg` (rotație Y fixă) și `dy` (cotă). Distanța e REZULTAT: pornește de la `near` și
  urcă din 6 în 6 m până la degajarea față de șosea.
* Fără `yaw_deg`, rotația Y e la zar: o bandă de 250 m ar putea sta cu capul spre privitor.
  Pentru benzi tangente la cerc: **`yaw_deg = 90 − angle_deg`** (comentariul din `track.gd`,
  „t = PI/2 − angle”).
* Scara reală = `scale` din inel × `randf_range(0.85, 1.2)` (se aplică și cotei bazei norilor).
* Poziție Y: `ground_y − 4 + dy`. `cast_shadow` OFF (`_fara_umbra_aruncata`). Materialul:
  `horizon_class` `""` → `apply_world_material` (atlas de paletă × AO din vertex colors) — cum
  fac Carrara/Fiordland.
* **Concluzie: nu e nevoie de cod nou.** Ajunge tema. Propunere (de pus în `angkor`, în loc de
  `"horizon_model": ""`):

```gdscript
"horizon_model": "res://assets/models/angkor/effects/angkor_horizon.glb",
"horizon_class": "",
"horizon_picks": [["StormBand_A"], ["StormBand_B"], ["KulenRidge"], ["Paddies_W"], ["Canopy_A", "Canopy_B", "Canopy_C"]],
"horizon_rings": [
    {"count": 1, "angle_deg": -20.0, "yaw_deg": 110.0, "near": 200.0, "far": 260.0, "clear": 60.0, "scale": 0.9, "dy": -34.0, "picks": ["StormBand_A"]},
    {"count": 1, "angle_deg": 22.0,  "yaw_deg": 68.0,  "near": 200.0, "far": 260.0, "clear": 60.0, "scale": 0.9, "dy": -34.0, "picks": ["StormBand_B"]},
    {"count": 1, "angle_deg": -52.0, "yaw_deg": 142.0, "near": 200.0, "far": 260.0, "clear": 60.0, "scale": 1.0, "picks": ["KulenRidge"]},
    {"count": 1, "angle_deg": 180.0, "yaw_deg": -90.0, "near": 200.0, "far": 260.0, "clear": 60.0, "scale": 1.0, "picks": ["Paddies_W"]},
    {"count": 10, "near": 200.0, "far": 260.0, "clear": 60.0, "scale": 1.0, "picks": ["Canopy_A", "Canopy_B", "Canopy_C"]},
],
```
(`clear` de la ~60 m e o presupunere: se calibrează pe pista reală; inelul cu `count` 10 mai
trage și peste sectoarele est/vest, de filtrat dacă se vrea doar pe restul arcului.)

## Atenție mare: cadrul camerei de joc NU ajunge la nori (măsurat, `ring_est_game*.png`)

Camera de joc: la 10 m, 12,5 m în spate, privește 5 m înaintea mașinii la 0,4 m, fov vertical 68°
⇒ înclinată ~28,7° în jos ⇒ **marginea de sus a cadrului e la ≈ +5° peste orizont**. La 240 m,
asta e ~21 m peste ochi (~31 m peste sol). Așadar:

* baza norilor la 46–54 m peste sol (≈ +8…+10° la 240 m) **iese din cadru**: în cadrul de joc
  nu se vede niciun nor (`angkor_horizon_ring_est_game.png`: doar vârfurile coronamentului);
* cu `dy = −34` (baza la 12–20 m) se vede doar fâșia de jos a burții norilor
  (`..._est_game_dy.png`); turnurile, singurele care spun „furtună”, tot nu intră;
* coronamentul de 32 m abia atinge marginea de sus. Pe viraje/vitezele mari (FOV mărit) cadrul
  urcă câteva grade, dar nu schimbă concluzia.

Deci, în cadrul de joc de la nivelul solului, geometria furtunii adaugă cel mult o fâșie întunecată
sub marginea de sus; ca să conteze trebuie ori mutată mult mai jos și mai aproape, ori completată
cu un gradient de cer pe azimut (shader), ori citită din cadre unde camera se ridică (creste, sărituri).

## Citire (onestă)

* Panoramic (`ring_est_pano*.png`, camera orizontală, fov orizontal 110°): cele două bande sunt
  **nori de furtună plauzibili, nu munți**: bază plată și întunecată, turnuri rotunjite în „conopidă”,
  violet-gri după ceață, plutesc cu cer sub ele. Totuși, corpul de jos e un dom lat și neted care,
  din față, citește și ca „deal întunecat cu bile deasupra” (jos închis, sus deschis, fără
  detaliu de ploaie). Verdict: **mai aproape de „furtună” decât de „amurg”, dar neacceptat** — nu
  poate fi judecat din cadrul de joc (vezi mai sus), doar din panoramă.
* Vest (`ring_vest_pano.png`): orezăriile sunt o fâșie subțire (cota 0,7 m, la 235 m abia se văd);
  scena o duc palmierii (12–16 m) și perdeaua de copaci. Câmpul/apa nu se citesc ca în referință.
* Coronament: cupole suprapuse cu dipterocarpi „ciuperci”; citește a junglă, nu a pădure de conifere;
  emergenții cu trunchi subțire sunt corecți ca siluetă, dar uniformi.
* `KulenRidge`: dâmb verde neted, plat; funcționează ca fundal, fără detaliu.

## Randări

`docs/asset_briefs/img/angkor_fidelity/`:
`angkor_horizon_row.png` (decuparea deasupra, nodurile dedesubt, scara 0,2),
`angkor_horizon_ring_{est,vest,nordest}_{pano,game}[_dy].png` (ring, camera în centru la 10 m;
ceață aproximată 42%, cer sky_top→sky_horizon din tema `angkor`, sol plat — fără relief real).
