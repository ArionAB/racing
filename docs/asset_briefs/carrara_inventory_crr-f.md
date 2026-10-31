# Inventar — kit Carrara, val 2, constructorul crr-f (fundalul, §1.6)

Contract: `docs/asset_briefs/carrara_kit.md` §1.6, brief `docs/track_briefs/carrara.md`
§1, §4, §5.4. Fișierul ăsta e al grupei crr-f; coordonatorul îl contopește cu
`carrara_inventory.md` la integrare. **Fundalul e PROVIZORIU**: verdictul final se dă
pe pista reală, cu testul de anotimp (brief §6).

## Fișiere

| fișier | rol |
|---|---|
| `tools/blender/build_crr_horizon.py` | cele 3 creste; docstring-ul fiecărei funcții = lista de elemente |
| `tools/blender/preview_crr_horizon.py` | refolosește `preview_carrara.py`: `--compare` (decupare deasupra, randare dedesubt), `--views` (4 azimuturi × 3), `--lineup` |
| `tools/blender/measure_crr_horizon.py` | garda de cote pe GLB; `--selftest` scrie 3 copii sabotate și cere să pice |
| `tools/blender/verify_carrara.sh` | secțiunea „val 2, crr-f” |
| `tools/ProbeCarraraHorizon.tscn` | sonda din joc: unde cad crestele, ce vede camera de joc din ele (distanță, azimut, verticală, ocluzie prin teren), `cast_shadow` |
| `tools/ProbeThemesHash.tscn` | amprenta fiecărei teme din `Track.themes()` — dovada de bit-identitate |
| `scenes/tracks/track.gd` | tema `carrara`: `horizon_model`, `horizon_class`, `horizon_rings` |

## Cote măsurate (din GLB, `measure_crr_horizon.py`)

| nod | L × H × adâncime (m) | contract | vârfuri (cotă / proeminență) | tri |
|---|---|---|---|---:|
| `ApuanRidge_A` | 236,0 × 40,5 × 74,1 | 160–240 × 35–60 | 2 mari (40,5 / 38,3; 35,8 / 16,9) + 1 mic (27,6 / 8,8) | 9.658 |
| `ApuanRidge_B` | 200,0 × 51,1 × 93,3 | idem | 3 mari (45,3; 51,1; 46,7) + 2 dinți (37–39) | 10.246 |
| `ApuanRidge_C` | 168,0 × 57,2 × 68,4 | idem | 2 (57,2 / 50,1; 39,6 / 15,2) | 7.028 |

Total 26.932 tri, GLB 3,2 MB (muchii despicate pentru umbrire plată). Originea la bază
(Y min 0,000, bbox centrat la 0,00), scala/rotația aplicate pe fiecare rădăcină.
Siluete diferite: diferența medie a profilului normalizat A–B 0,156, A–C 0,165, B–C 0,201.

Aria pe sloturi: calcar `MARBLE_GREY` 47–49%, moloz `CORAL_SAND` 9–12%, pădure
`TROPICAL_GREEN` 33–34% + `DRY_VEGETATION` 6–9%. **Zero `FOAM_WHITE`**, zero sloturi noi.

Garda pică pe sabotaj (`--selftest`): nod redenumit, nod ridicat 5 m, nod scalat ×1,6
pe Y — toate trei PICĂ, originalul TRECE.

## Integrarea (track.gd, tema `carrara`)

Un inel per creastă, azimut fix, lungimea paralelă cu drumul cel mai apropiat:

| creastă | unghi | `clear` | scara inel (efectivă) | pivot în joc | față de sosea | cine o vede |
|---|---|---|---|---|---|---|
| C | −60 (NE) | 130 | 0,9 (0,78) | (117, −219) | 93 m | A 0.02, 0.06 |
| A | 128 (SV) | 140 | 0,9 (1,00) | (−205, 254) | 106 m | E 0.62–0.66, F 0.70 |
| B | 185 (V) | 170 | 0,85 (0,80) | (−500, −31) | 129 m | G 0.80, 0.88 |

`ProbeCarraraHorizon` (camera de joc 10 m / 12,5 m / fov 68, ocluzie prin teren):

| fracție | creasta | distanța | vârful în cadru (1 = muchia de sus) |
|---|---|---|---|
| 0.02 | C | 207–263 m | 1,00 (tăiat sus, voit) |
| 0.62 | A (+B la 550 m) | 206–309 m | 0,84 |
| 0.70 | A | 154–228 m | 0,88 |
| 0.80 | B | 178–228 m | 0,93 |
| 0.88 | B | 177–215 m | 0,99 |

0 mesh-uri de fundal care aruncă umbră. Pe starea dinaintea legării sonda PICĂ (0 creste,
5 fracții fără creastă).

Capturi înainte/după (`--gamecam`, `docs/asset_briefs/img/carrara_fidelity/ingame/`,
`horizon_ab_fXXX.png` = înainte | după): pixelii schimbați stau toți în banda de sus;
**sub 45% din înălțimea cadrului se schimbă 0–1 pixeli** la toate cele 6 fracții, deci
umbrele din prim-plan nu se mișcă. Creasta în cadru: V 0,54–0,85, saturație 0,05–0,15
(cerul ~0,9): se citește, nu e înghițită de ceață.

Materiale Track23 (`probe_decor --track=23`): **23 → 19**. Atlasul era deja pe pistă;
dispar cele 4 materiale plate ale movilelor de rezervă (`_build_horizon_fallback`).

## Fidelitate (comparațiile `apuan_ridge.png`, `apuan_ridge_b.png`)

| element | pe planșă | în GLB | OK/abatere |
|---|---|---|---|
| vârfuri A | 2 mari + 1 mic la mijloc, stânga cel mai înalt | idem (40,5 / 35,8 / 27,6) | OK |
| h/l A | ~0,15 (văzută ușor de sus) | 0,17 | OK (+13%) |
| vârfuri B | 4–5 ace, unele mici în spate | 3 mari + 2 dinți în spatele șeilor | OK |
| flancuri | calcar crem-gri cu coaste | `MARBLE_GREY`, fațete cu coaste/jgheaburi radiale | OK la 200 m; abatere de aproape: fără plăcile mari de calcar ale planșei |
| dâre de moloz | fâșii deschise pe jgheaburi | `CORAL_SAND` pe jgheaburi, 9–12% | OK, slabe în preview (contrast mic între sloturi) |
| pădurea | brâu dens de pini + galben, urcă pe flancuri | brâu pe sloturi + 50–64 bulgări pe poale + 14–22 pe jgheaburi | abatere: bulgări rotunzi, nu coroane conice; saturat la <150 m (0.06) |
| zăpadă / calotă | nu | nu | OK |

## Abateri

- **B stă la x ≈ −500**, cu spatele dincolo de marginea pânzei de teren (−495): din
  pistă nu se vede, iar creasta ascunde muchia lumii care se vedea înainte la G.
- **Inelele nu sunt la 200–300 m de centroid**: pista are ~700 m pe X, deci G stă la
  310 m de centroid. Contractul s-a citit ca „200–300 m de camera care o vede”.
- **La 0.06 C e la 144 m** (sub `fog_begin` 150): pădurea de la bază iese saturată.
- **Fața în umbră** (A văzută din E/F) iese mai închisă decât pereții carierei (V ~0,58
  la F); runda 2 a ridicat AO-ul (low 0,66 → 0,80) și tonul fețelor abrupte (0,72 → 0,86).

## Stare la oprire

2 runde din 3. GLB, legarea, gărzile și capturile sunt gata. Verdictul final e al
coordonatorului, pe capturi și pe testul de anotimp.
