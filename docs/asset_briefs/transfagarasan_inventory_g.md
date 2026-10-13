# Inventar tf-g — fundalul (Transfăgărășan, Track21, valul 3)

Contract: `docs/asset_briefs/transfagarasan_kit.md` §1.8. Build: `tools/blender/build_tf_horizon.py`.
Preview: `tools/blender/preview_tf_g.py` (`--compare ridge|cloud|plain`, `--views ...`, `--game`).
Axe: Blender X lateral, Y adâncime, Z sus. Cote MĂSURATE pe GLB (`verify_glb.py`).

## Decizia coordonatorului (13 oct 2026): PROVIZORIU, creasta rev. tf-g + norii tf-g2

Bucla se oprește aici: 3 runde la tf-g și 2 la reluarea tf-g2, fără convergență față de
decupare (memoria `gauntlet-iesirea-din-bucla`). GLB-ul livrat combină cea mai bine judecată
stare a fiecărei piese, judecată pe **captura de joc** (`horizon_game_300m.png`), nu pe 3/4:
- **creasta = rev. tf-g** (`efea5de7`): vârfuri de înălțimi diferite, care din camera de joc se
  citesc ca lanț muntos. Defectul ei e cunoscut: prea „Dolomiți” (ace izolate, Negoiu-obelisc).
  Peretele cu 12–13 dinți egali al reluării (`8fdbcf7e`) a corectat silueta în 3/4, dar din
  joc citea **pieptene / gard**, adică mai rău. Codul reluării rămâne în istoric, iar §1.8 din
  kit păstrează contractul inițial;
- **norii = tf-g2**: cocoașe de cumulus care se citesc din joc ca un șir de grămezi sub drum,
  față de fâșia albastră plată din rev. tf-g. Rămâne placa vizibilă din 3/4;
- **câmpia = rev. tf-g**, neschimbată (`PLAIN_HASH e15697de…`). La 300 m ocupă ~10 px.

Verdictul final se dă pe pista reală, la montare: cu ceața temei (140–370 m), la 300 m
rămâne doar silueta. Tabelele de fidelitate ale crestei de mai jos descriu reluarea tf-g2
(respinsă); pentru rev. tf-g, vezi abaterile din raportul ei: 8 vârfuri și 3 dinți pe bucată,
zăpadă puțină, rocă deschisă, Negoiu subțire.

## assets/models/transfagarasan/effects/transfagarasan_horizon.glb

Șase noduri, copii direcți ai rădăcinii, fiecare un corp închis (elipsă / dreptunghi + evantai de bază la z=0),
originea la bază (XY centrat pe bbox, Z min = 0), scala aplicată (garda din `verify_transfagarasan.sh`),
un singur material (atlas). Fără excepții de verificare. Total **16 942 tri** (creasta rev. tf-g, norii tf-g2, câmpia neschimbată: 4 008).

| nod | L × l × h (m) | tri | sloturi | contract |
|---|---|---:|---|---|
| `FagarasRidge_A` (Negoiu) | 230,0 × 66,0 × 67,5 | 2 468 | MARBLE_GREY, FOAM_WHITE, TROPICAL_GREEN, CACTUS_GREEN | 160–240 × 45–70: OK |
| `FagarasRidge_B` | 189,9 × 60,0 × 50,4 | 1 942 | idem | OK |
| `FagarasRidge_C` | 165,0 × 56,0 × 52,1 | 1 596 | idem | OK |
| `CloudSea_A` | 270,8 × 57,7 × 17,1 | 3 744 | FOAM_WHITE 22 | 200–300 × 8–15: grosime 17,1 (voit, verdictul tf-g2 permite ~18 m; stau sub drum) |
| `CloudSea_B` | 210,4 × 50,5 × 15,7 | 3 184 | FOAM_WHITE 22 | idem, 15,7 |
| `FagarasPlain_A` | 300,0 × 120,0 × 10,7 | 4 008 | TROPICAL_GREEN 21, CACTUS_GREEN 12, DRY_VEGETATION 13 | 300 × 120: OK; relief teren 1,6–4,2 m, 10,7 cu palcurile |

Umbrire plată (`flat_ao`), plus ton per fațetă (pantă la creastă; petice și palcuri la câmpie), copt în AO.
Materiale per pistă: GLB-ul adaugă 1 (atlasul). Clasa de integrare: **`horizon_class: ""`**
(culoarea e pictată în sloturi; o clasă `rock` ar șterge zăpada și poalele verzi — memoria
`efecte-de-fundal-cote-legate`).

## Fidelitate față de decupări (element | pe planșă | în GLB | verdict)

Comparații: `docs/asset_briefs/img/transfagarasan_fidelity/fagaras_ridge.png`, `cloud_sea.png`,
`fagaras_plain.png`, plus `*_views.png`.

### Creasta (`fagaras_ridge`, randat FagarasRidge_A) — reluare tf-g2
| element | pe planșă / în verdict | în GLB | verdict |
|---|---|---|---|
| linie continuă | perete, șeile coboară ~15–25% | un singur perete; șeile au 16–24% din dinte (măsurat pe funcția de înălțime, §„Măsurători”) | OK |
| dinți | ~12–15 mărunți, triunghiulari | A 13, B 12, C 12 (maxime locale cu proeminență ≥ 2,5% din hmax) | OK |
| Negoiu | un dinte cu ~15–20% mai înalt, nu obelisc | 65,8 m față de 57,2 și 54,5 la vecini (+15% / +21%), flancul îl face masă | OK; încă cel mai ascuțit dinte pe randare |
| coaste | muchii oblice din dinți spre poale, fețe în umbră | evantai (0,85·x/(L/2) + 0,30 pe față), flanc +X în ton 0,45–0,60 | OK ca structură; coastele sunt mai drepte și mai regulate decât pe planșă |
| căldări / culoare | scobituri largi cu zăpadă, între coaste | jgheaburi tot mai adânci spre poale, FOAM_WHITE; acoperire 42% (+Y și −Y) pe fața de sus (z > 30% hmax) | OK pe cifră; pe randare zăpada citește ca **dungi verticale**, nu câmpuri largi |
| verde | limbi sub coaste, treimea de jos | limbi până la 4 + 17 m sub coaste + brâu de 6 m | OK; verdele e mai închis decât pe planșă |
| rocă | verzui închis, umbre adânci | gri cald, ton 0,45–0,65 în umbră; mai deschis decât planșa | abatere |
| conturul din față | zimțat | dinți pe un perete, clopot lent (capete ~70% din max) | OK |

### Marea de nori (`cloud_sea`, CloudSea_A) — reluare tf-g2
| element | pe planșă / în verdict | în GLB | verdict |
|---|---|---|---|
| grămezi | cumulus în cocoașe, 6–10 pe bucată | 8 grămezi în zigzag (y ±0,20 W) pe A, 7 pe B; 44 + 37 bulgări | OK ca număr |
| bulgări înalți | aspect 0,6–0,9 | principal ~0,7–0,9, sateliți ~0,55–0,9, vârfuri 12–17 m | OK |
| goluri / văi | se vede adânc, mai închis | baza de 3 m, ton 0,55, iese prin golurile dintre grămezi | abatere: golurile sunt gri, nu albastre (un singur slot FOAM_WHITE) |
| contur de sus | cocoașe de 6–15 m cu șei | A: 12 cocoașe (proeminență ≥ 3 m), șa minimă 5,6 m; B: 9 | OK pe cifră |
| aspect în plan | nori care umplu suprafața | bulgării acoperă ~55–60% din placă; placa e vizibil mai goală decât planșa | abatere: din 3/4 încă se citește „grămezi pe placă” |

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

## Reluare (tf-g2)

Constructor nou, plecat de la verdictul coordonatorului și de la decupări, nu de la forma tf-g. Anulat: „5–8 vârfuri pe
o bucată” (acum 12–15 dinți pe perete continuu; kit §1.8 corectat). Metodă: SILUETA ÎNTÂI.
- Creasta: anvelopa crestei s-a EXTRAS din `fagaras_ridge.png` (200 de coloane, `ENV` în `build_tf_horizon.py`) și s-a
  comprimat (0,40 + 0,60·env, fiindcă clopotul decupării e umflat de perspectiva de sus); dinții (`_crest_knots`) sunt
  profilul liniar-frânt peste ea. Silueta brută a decupării are doar ~7 crestături (dinții din spate se suprapun peste cei din
  față), deci numărul de dinți e din verdict, nu din imagine. Coastele, căldările și culorile s-au adăugat DUPĂ ce
  silueta a stat (liste de elemente în docstring-urile `_ridge` și `_cloud`, scrise înaintea codului).
- Norii: grămezi în zigzag, bulgări de aspect 0,55–0,9, bază joasă întunecată.
- `FagarasPlain_A`: neatinsă. Amprentă SHA-1 pe vârfuri + AO + număr de fețe, identică înainte și după
  (`e15697de…`, 12 024 vârfuri, 4 008 tri; se afișează la fiecare build ca `PLAIN_HASH`), dimensiuni 300,0 × 120,0 × 10,7.
- Harnasul (`preview_tf_g.py`, `compose_tf_g.py`) nemodificat.

### Măsurători (din build)
| nod | hmax | dinți / cocoașe | șa minimă (10–90% lungime) | zăpadă pe fața de sus |
|---|---|---|---|---|
| A | 64,5 | 13 | 58% din hmax (e și clopotul de capăt; șeile locale 16–24%) | 42% / 42% |
| B | 50,0 | 12 | 67% | 41% / 43% |
| C | 53,1 | 12 | 67% | 45% / 41% |
| CloudSea_A | 17,1 | 12 cocoașe | 5,6 m | – |
| CloudSea_B | 15,7 | 9 cocoașe | 0 (capetele) | – |

Siluetă: comparația numerică pe mască binară NU s-a făcut (silueta decupării e netedă, deci n-ar fi spus nimic despre dinți);
s-a comparat vizual, în `fagaras_ridge.png`, și pe numere de mai sus.

## Runde (tf-g2)

- Creasta: 2. R1: perete cu dinți + coaste verticale, Negoiu ac îngust, rocă prea deschisă. R2: șa lângă Negoiu ridicată
  (masă, nu ac), evantai de coaste mai înclinat (0,85 în loc de 0,5), rocă mai închisă în umbră.
- Norii: 2. R1: 8 bulgări mici pe placă mare (pietricele). R2: grămezi de 5–6 bulgări în zigzag, placă mai mică și mai deschisă.
- Câmpia: neatinsă (3 runde tf-g, acceptată provizoriu).

## Recomandare `horizon_rings` (tema `transfagarasan`, coordonatorul integrează)

`horizon_model` = `transfagarasan_horizon.glb`, `horizon_classes`/`horizon_class` = `""`, apoi:

| inel | near–far | piese | scară | azimut |
|---|---|---|---|---|
| creasta | 200–260 m, `clear` 80 | `FagarasRidge_A` (Negoiu) 1×, `_B` 1×, `_C` 1× | 1,0 | `at`/`angle_deg` pe est, ~±35° între ele |
| nori | 240–320 m | `CloudSea_A` 1×, `CloudSea_B` 1× | 1,0 | între creastă și drum, est/sud-est; **cere offset vertical −20…−30 m**: `_build_horizon` pune nodul la `ground_y − 4` fără parametru de cotă |
| câmpia | 280–340 m | `FagarasPlain_A` 1× | 1,0 | nord, pe inel; la fel, ideal −30 m |

Totalul e 6 noduri (16,9 k tri, 1 material). Dacă nu se adaugă un `dy` per inel, norii și câmpia se văd doar dacă
terenul de acolo e deja sub cota drumului.

## Stare la oprire

Livrate (tf-g2): GLB reexportat, `verify_glb` OK, `verify_transfagarasan.sh` -> `VERDICT KIT: OK`, comparațiile
(`fagaras_ridge`, `cloud_sea`, `*_views`, `horizon_game_300m`). Câmpia neschimbată.
**Creasta**: perete continuu cu 12–13 dinți, coaste, căldări, limbi verzi: structura din verdict e acolo. **Rămân
deschise (PROVIZORIU, 2 runde consumate):** zăpada citește ca dungi verticale, nu ca câmpuri largi între coaste;
dinții sunt mai înalți și mai ascuțiți decât pe planșă (Negoiu cel mai mult); coastele sunt prea regulate; rocă prea deschisă;
poalele verzi prea închise. **Norii**: grămezi, dar din 3/4 încă se citește „grămezi pe o placă”; golurile sunt gri, nu albastre;
placa vizibilă. În joc (`horizon_game_300m.png`) norii stau sub cota drumului și se citesc ca un șir de cocoașe; creasta ca perete
dințat. Integrarea cere tot un `dy` per inel în `_build_horizon` (v. tabelul de mai sus); cu grosimea de 17 m norii au nevoie de ~−28 m.
