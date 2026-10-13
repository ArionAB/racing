# Inventar tf-g — fundalul (Transfăgărășan, Track21, valul 3)

Contract: `docs/asset_briefs/transfagarasan_kit.md` §1.8. Build: `tools/blender/build_tf_horizon.py`.
Preview: `tools/blender/preview_tf_g.py` (`--compare ridge|cloud|plain`, `--views ...`, `--game`).
Axe: Blender X lateral, Y adâncime, Z sus. Cote MĂSURATE pe GLB (`verify_glb.py`).

## assets/models/transfagarasan/effects/transfagarasan_horizon.glb

Șase noduri, copii direcți ai rădăcinii, fiecare un corp închis (elipsă / dreptunghi + evantai de bază la z=0),
originea la bază (XY centrat pe bbox, Z min = 0), scala aplicată (garda din `verify_transfagarasan.sh`),
un singur material (atlas). Fără excepții de verificare. Total **18 382 tri**.

| nod | L × l × h (m) | tri | sloturi | contract |
|---|---|---:|---|---|
| `FagarasRidge_A` (Negoiu) | 230,0 × 66,0 × 67,5 | 2 468 | MARBLE_GREY 29, FOAM_WHITE 22, TROPICAL_GREEN 21, CACTUS_GREEN 12 | 160–240 × 45–70: OK |
| `FagarasRidge_B` | 189,9 × 60,0 × 50,4 | 1 942 | idem | OK |
| `FagarasRidge_C` | 165,0 × 56,0 × 52,1 | 1 596 | idem | OK |
| `CloudSea_A` | 302,3 × 101,1 × 13,9 | 4 688 | FOAM_WHITE 22 | 200–300 × 8–15: lungime +2%, lățime 101 m (bulgării de pe margine ies din placa de 66 m) |
| `CloudSea_B` | 240,5 × 101,3 × 11,0 | 3 680 | FOAM_WHITE 22 | OK (aceeași notă de lățime) |
| `FagarasPlain_A` | 300,0 × 120,0 × 10,7 | 4 008 | TROPICAL_GREEN 21, CACTUS_GREEN 12, DRY_VEGETATION 13 | 300 × 120: OK; relief teren 1,6–4,2 m, 10,7 cu palcurile |

Umbrire plată (`flat_ao`), plus ton per fațetă (pantă la creastă; petice și palcuri la câmpie), copt în AO.
Materiale per pistă: GLB-ul adaugă 1 (atlasul). Clasa de integrare: **`horizon_class: ""`**
(culoarea e pictată în sloturi; o clasă `rock` ar șterge zăpada și poalele verzi — memoria
`efecte-de-fundal-cote-legate`).

## Fidelitate față de decupări (element | pe planșă | în GLB | verdict)

Comparații: `docs/asset_briefs/img/transfagarasan_fidelity/fagaras_ridge.png`, `cloud_sea.png`,
`fagaras_plain.png`, plus `*_views.png`.

### Creasta (`fagaras_ridge`, randat FagarasRidge_A)
| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| vârfuri | ~15 pe aceeași lungime | 8 (+3 dinți) pe bucată, 5–8 prin contract | abatere asumată (contract) |
| vârf dominant | 2 vârfuri mai înalte, mai late | un singur corn de 70 m, mai subțire și mai ascuțit | abatere: prea spiral |
| căldări cu zăpadă | câmpuri mari de zăpadă între vârfuri | 3 căldări + zăpadă pe fețe line; acoperire vizibil mai mică | abatere: mai puțină zăpadă |
| poale verzi | brâu verde îngust, neregulat | brâu verde până la ~10 m, fără ținte; poalele par o farfurie la capete | OK cu rezerve |
| contrast rock | piatră întunecată verzui, umbre adânci | gri deschis, tonul din pantă; mai plat | abatere |
| contur / silueta | zimțată, densă | zimțată, mai rară, saua adâncă | OK |

### Marea de nori (`cloud_sea`, CloudSea_A)
| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| strat plat + bulgări | bulgări înalți, suprapuși, cu goluri albastre | placă de 4 m + 62 bulgări (raze 15–29 m, până la 14 m) | OK ca structură |
| relief | turnuri înalte, văi între ele | bulgări aplatizați, relief mai jos | abatere: prea plat |
| culoare | alb cald sus, albastru în umbră | alb-gri uniform (doar FOAM_WHITE + AO) | abatere: fără albastru |

### Câmpia (`fagaras_plain`, FagarasPlain_A)
| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| fâșii de câmp | petice mari galben-oliv, verde | 7 fâșii înclinate 9°, petice de 55 m | OK ca structură |
| culoare | dominant galben-oliv | dominant verde închis, 2 fâșii DRY | abatere (kit cere „una" galbenă, am pus două) |
| pâlcuri | rânduri și pâlcuri de copaci, înalte | 5 pâlcuri de 2–4 bulgări (5–9 m) | OK ca număr; mai mici |
| dealuri în spate | albastre, în fundal | lipsesc (nu e în contract) | abatere asumată |

## Ce vede jucătorul (captura la 300 m)

`horizon_game_300m.png`: camera 10 m / −12,5 m, tinta la 5 m în față și +0,4 m, fov vertical 68; ridge baza la −4 m,
scara 1,1; nori la −26 m; câmpia la −30 m. Cadrul de sus e doar ~5,3° peste orizont: creasta apare ca o bandă de
~75 px din 720 (dinții de la 25–35 m se citesc, vârfurile de 70 m sunt tăiate). **Ceața temei la 300 m
(fog 140–370) amestecă ~70–75% din culoare**: creasta rămâne siluetă, norii și câmpia aproape dispar. Prin urmare:
inelul apropiat (200–230 m) pentru creastă, norii și câmpia coborâți mult sub drum ca să nu fie tăiați de linia
orizontului (câmpia la 300 m și la nivelul drumului ar ocupa ~1° = 10 px).
Presupuneri: culoarea ceții = `sky_horizon`; soarele din față-stânga (fețele spre cameră luminate).

## Runde

- Creasta: 3 (1: insulă cu fustă verde prea mare, vârfuri rare -> 2: contur dreptunghiular, poale mici, ton de
  pantă -> 3: zăpadă mai multă). Nu a convergit la densitate/zăpadă/contrast; raportat.
- Norii: 3 (placă + bulgari mici -> bulgari mari și mulți -> relief mai mare). Rămâne plat.
- Câmpia: 3 (culori -> petice -> două fâșii galbene). Rămâne mai întunecată decât planșa.
Harnasul de captură a avut un bug de materiale (`materials.clear()` reseta indicii) și de direcție a soarelui; corectate.

## Recomandare `horizon_rings` (tema `transfagarasan`, coordonatorul integrează)

`horizon_model` = `transfagarasan_horizon.glb`, `horizon_classes`/`horizon_class` = `""`, apoi:

| inel | near–far | piese | scară | azimut |
|---|---|---|---|---|
| creasta | 200–260 m, `clear` 80 | `FagarasRidge_A` (Negoiu) 1×, `_B` 1×, `_C` 1× | 1,0 | `at`/`angle_deg` pe est, ~±35° între ele |
| nori | 240–320 m | `CloudSea_A` 1×, `CloudSea_B` 1× | 1,0 | între creastă și drum, est/sud-est; **cere offset vertical −20…−30 m**: `_build_horizon` pune nodul la `ground_y − 4` fără parametru de cotă |
| câmpia | 280–340 m | `FagarasPlain_A` 1× | 1,0 | nord, pe inel; la fel, ideal −30 m |

Totalul e 6 noduri (18 k tri, 1 material). Dacă nu se adaugă un `dy` per inel, norii și câmpia se văd doar dacă
terenul de acolo e deja sub cota drumului.

## Stare la oprire

Livrate: GLB, build, preview, verify (`VERDICT KIT: OK`), comparații. **Neacceptat de coordonator.** Abateri
deschise: zăpadă și contrast pe creastă; relief și culoare pe nori; culoare (galben-oliv) și dealuri de fundal pe
câmpie; piesa de integrat cere un `dy` per inel în `_build_horizon`. Runda următoare: zăpadă pe faze mai
abrupte în jgheaburi, a doua tentă de rocă în umbră, bulgări mai înalți cu goluri, câmpie cu petice mai deschise.
