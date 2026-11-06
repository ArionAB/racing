# Inventar — kit Angkor, val 3, grupul C (viață și piese mici)

Contract: `docs/asset_briefs/angkor_kit.md` §1.4–§1.6. Decizia dezvoltatorului (6 nov 2026): tot ce e sculptural e **simplificat**
(leii, capetele naga, călugărul sunt volume lizibile din hull-uri, nu sculptură; datorie deschisă, §1.1).

| fișier | rol |
|---|---|
| `tools/blender/build_angkor_life.py` | cele 6 GLB (`ANK_ONLY=landing|tuk|monk|laterite|rubble|numbered` reface una) |
| `tools/blender/measure_angkor_w3c.py` | garda pe GLB (coordonate Godot), cu `--selftest` (3 sabotaje) |
| `tools/blender/preview_angkor.py` | doar intrări noi în `SPECS` |
| `tools/blender/verify_angkor.sh` | blocul `# --- val 3, grupul C ---` |

## Piese (cote măsurate pe GLB, coordonate Godot)
| piesă | cote | triunghiuri | noduri / sloturi |
|---|---|---:|---|
| `structures/srah_srang_landing.glb` | 14,00 × 8,08 m; Y −1,70…+2,88; suprafața platformei la Y = 0 (dale ridicate 2,5 cm, 165 m² la \|Y\|<0,05) | 19.824 | `Landing_Laterite` (27), `Landing_Stone` (3), `Landing_Lichen` (12 + 30) |
| `vehicles/tuk_tuk.glb` | `Moto` 0,80 × 1,89 × 1,04; `Remorca` 1,44 lat × **1,956** lung × **1,77** înalt | 3.372 | `Moto_Paint/_Black`; `Remorca_Paint/_Roof/_Wood/_Black` (11 / 20 / 23 / 9) |
| `animals/monk_standing.glb` | 0,60 × 0,32 × **1,70** | 606 | `Monk_Robe` (30), `Monk_Skin` (23) |
| `props/laterite_block.glb` | 1,00 × 0,60 × 0,52 | 9.408 | `Block_Laterite` (27) |
| `props/rubble_pile.glb` | 2,12 × 1,71 × 0,95 | 652 | `Rubble_Stone` (3), `Rubble_Lichen` |
| `props/numbered_block.glb` | 0,80 × 0,59 × 0,58, cifra „7” ridicată 3 cm | 908 | `Block_Stone` (3), `Block_Paint` (19), `Block_Lichen` |

Toate folosesc același atlas (un singur material de paletă); „materiale” = noduri/sloturi de mai sus. Zero sloturi noi, fără `CAR_*`.

## Decizii și abateri de declarat
- **Tuk-tuk, două rădăcini** (`Moto`, `Remorca`): obiecte goale cu translație pe rădăcină și scală/rotație identice; geometria fiecărei piese e centrată pe
  rădăcina ei, deci integrarea o poate împacheta în `BumpProp` separat. Limita `BumpProp` (`bump_prop.gd`): **2,0 m în plan, 1,8 m înălțime**
  (aici înălțimea e prag strict). Remorca: 1,956 × 1,77 — sub amândouă; de aceea **înălțimea e 1,77, nu „~2,0” din tabel** (2,0 ar fi făcut-o
  statică). Moto are 0,80 lățime (ghidonul + mânere), nu ~0,7. Împreună stau în poziția de tractare (Remorca la y<0, carligul la y=0).
  Vopseaua e `PAINTED_METAL` 11 = albastru-gri stins (nu roșul din planșă: roșul ar fi `CAR_*`, interzis).
- **Piele:** nu există slot de piele; `Monk_Skin` ia `TILE_TERRACOTTA` 23 (ten cald). De confirmat de coordonator.
- **Debarcader:** origine la cota platformei (geometria traversează Y=0, deci verificarea e `--origin=waterline`, ca la ponton). Scara 6 trepte × 0,25 = 1,5 m,
  corpurile coboară la −1,7 (sub apă). Leii pe socluri de laterită cu capac de gresie; capete naga în evantai (5 glugi) la capete, cu corp-balustradă joasă pe marginea platformei. Capetele sunt blocuri cu pană, nu cobre.
- **Laterita:** porii sunt cavități reale (grilă subdivizată, gropi cu adâncime 3–7 cm) + AO copt. Sunt **mult mai puțini și mai mari** decât în planșă (acolo e un fagure des).
- **Moloz:** 10 blocuri cu colțuri mutate (fațete mari), un tambur de coloană cu inele, un buiandrug cu creastă, fragmente mici; lichen discret.
- **Bloc cu cifră:** `Block_Paint` = prismă în formă de „7” (singurul marcaj din kit). Din +Y privitorul vede +X în stânga, deci conturul e oglindit pe X.

## Ce am văzut (citire onestă, nu acceptare)
Imagini: `docs/asset_briefs/img/angkor_fidelity/` — `<nume>.png` (decupare | randare) pentru toate cele 6, plus `srah_srang_landing_views.png`, `tuk_tuk_views.png`, `numbered_block_views.png`. 3 runde pe laterită, 2–3 pe celelalte.
- **Debarcader:** compoziția (platformă, scară, doi lei pe socluri, două capete naga) se citește. Dar leii sunt blocuri simpliste („păpuși”), nu lei; naga sunt evantaie crenelate, mici față de planșă. Planșa e mult mai înaltă și mai compactă; la 14 × 8 m cu scara de 1,5 m raportul iese plat. Laterita e plată ca textură (fără pete).
- **Tuk-tuk:** silueta „motocicletă + remorcă acoperită cu bănci” se citește, acoperișul curbat e bun. Motocicleta e schematică (cadru subțire, motor-cutie), mai slabă decât restul; culoarea albastră stinsă diferă clar de planșă.
- **Călugăr:** siluetă corectă (cap ras, robă pe un umăr, umărul drept gol), dar rigid și cu brațe drepte ca de manechin; fără pliuri.
- **Bloc laterită:** citește „bloc poros cu goluri”, nu fagurele des din planșă.
- **Moloz:** gramadă de blocuri cu fațete; mai puțin compactă decât planșa, cu cinci-șase blocuri mici împrăștiate.
- **Bloc numerotat:** cel mai apropiat de planșă; cifra citește clar. Mușchiul e cinci pete verzi plate, nu dârele din planșă.

## Garda (`measure_angkor_w3c.py`)
Plicuri ±10% pe toate; tuk-tuk: exact două rădăcini `Moto`/`Remorca`, latura orizontală ≤ 2,0, înălțime ≤ 1,8, scală/rotație identice; debarcader: platforma la Y=0±0,05.
`--selftest`: remorca de 2,3 m, tuk-tuk într-o singură rădăcină, platforma ridicată 0,2 m — toate pică, originalele trec.
