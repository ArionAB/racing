# Okinawa — starea POI-urilor după gauntlet (10 oct 2026)

Nota de predare a sesiunii de decor pe cele 8 POI-uri ale pistei Okinawa
(Track20, temă `okinawa`). Contractul e `docs/track_briefs/okinawa_poi_gauntlet.md`,
kitul `docs/asset_briefs/okinawa_kit_v2.md`; aici e ce s-a întâmplat pe ele.

## Pe scurt

- **Toate cele 8 zone sunt populate** (`DecorManual/ZonaA` … `ZonaH`), fiecare cu
  generatorul ei `tools/gen_decor_ok_<x>.gd` + scriptul de lipire `tools/apply_zone_<x>.py`.
  Peste ele, o trecere globală de densitate (`DecorManual/Densitate`,
  `tools/gen_decor_ok_dens.gd`) pe banda de 2–15 m de lângă drum în A, C, D, F.
- **Niciun POI n-a câștigat orb** (0/8), ca pe Fiordland, Serengeti și Machu Picchu.
  Toate au ieșit pe regula (c): aceeași diferență de două ori, cu cauza sub decor.
- **Acceptarea finală e la volan**, pe scena integrată (testul amânat: „facem testul după”).

## Cum s-a ieșit din buclă, per POI

| POI | runde | ieșire | diferența care s-a repetat | cauza sub decor |
|---|---|---|---|---|
| A Portul și satul | 2 | (c) r1=r2 | sol gol între case | **solul satului** e nisip gri-bej (teren/temă); în bară satul stă pe verde |
| B Aleea de fukugi | 2 | (c) r1=r2 | stratul jos de flori lângă zid | densitate globală (rezolvată de trecerea de densitate) |
| C Trestia | 2 | (c) r1=r2 | trestia rară, „iarbă” | **asset-ul** `sugar_cane_clump`: fire subțiri, verde închis |
| D Castelul și poarta | 2 | (c) r1=r2 | fâșiile drum–zid goale | densitate globală (rezolvată de trecerea de densitate) |
| E Capul și cornișa | 2 | oscilație (pâlcuri → continuu) | muchia de calcar dintre drum și mare | **faleza provizorie** (`limestone_cliff_module`/`_b`, fără coliziune) |
| F Coborârea și podul | 2 | (c) r1=r2 | malul și pajiștea goale lângă pod | densitate (malurile F umplute de trecerea de densitate, în afara pasajului 0.630–0.685) |
| G Insula mică | 2 | (c) r1=r2 | pandanus „vedetă”, de scară reală | **asset/scară** pandanus; hibiscusul roșu citește „buruiană” |
| H Digul | 2 | (c) | valul de la 0.8811: placă albă plată, nu spumă | **hazardul valului** (vizualul din cod), nu decor |

**Tiparul dominant:** densitatea în banda de 2–15 m (A, B, C, D, F). De aceea trecerea
globală de la final, nu încă o rundă pe fiecare POI.

## Decizii care rămân la tine

1. **Solul satului (A).** Nisip gri-bej uniform; bara are satul pe verde. E teren/temă,
   nu decor.
2. **Trestia (C).** `sugar_cane_clump` e fire subțiri, verde închis. Cere un asset de câmp
   (`sugar_cane_field_patch`) și o culoare verde-gălbuie (clasa care deschide).
3. **Calcarul.** Toate piesele de calcar și zidul de corali stau pe `ok_limestone`
   (gri-crem). Bolovanii `coral_rock` ies gri-închis și plați; bara are calcar crem rotunjit.
4. **Fukugi.** Izolat citește conic (asset); e pus doar în pâlcuri.
5. **Faleza de la E.** `limestone_cliff_module`/`_b` sunt provizorii (din kit), fără
   coliziune; muchia de calcar dintre drum și mare n-a convins orb.
6. **Pasajul podului (0.630–0.685).** Haotic din fundație: repuneri, blocaje, ejectări la
   intrarea pe traveea ridicată; plus incidentul de cameră de la 0.672–0.678 (`LiftSpan`
   între mașină și cameră). Vezi cifrele de mai jos.
7. **Tromba (G, 0.775–0.79)** e pe drum (hazard); la r1 au apărut 2–3 evenimente acolo,
   la r2 niciunul. De urmărit la volan.
8. **Bougainvillea** iese magenta saturat (tenta `ok_bloom`).
9. **Tetrapozii (H).** Mutați pe `ok_limestone` doar pe tema okinawa (ieșeau bej-maro pe
   `concrete`), scalați 2,2–2,6×. Forma asset-ului vechi (`tetrapod`, Track08) citește
   „ciot vertical”, nu pastilele grase culcate din bară: asset nou dacă vrei mai aproape.
10. **Valul (H)** e o placă albă opacă; bara are spumă fragmentată peste șosea. E vizualul
    hazardului, nu decor.
11. **Hibiscusul** domină banda după trecerea de densitate (1 478 de piese noi) și are
    flori roșii saturate. Criticul lui G l-a citit „buruiană”. O variantă mai puțin roșie
    (asset sau tentă) ar schimba mult la cost mic.
12. **Pandanus „vedetă”** n-a prins loc: banda e îngustă unde stă bine. Scara lui e de
    asset.

## Reparate pe drum

- **Tencuiala și zidul de corali** (e55650e8): `plaster` făcea casele bej, `coral_rock`
  (ancoră VOLCANIC_BLACK) scotea zidurile negre. Tencuiala pe atlas, coralul pe `ok_limestone`.
- **Scatterul vechi**: cocotierii scoși, `coral_rock` → `ok_limestone` doar pe okinawa;
  Track08 bit-identic.
- **`probe_solid`** era neînarmat pe Track20 (`range(1,20)`): reparat la `range(1,21)`.
- **`probe_decor_overlap`** sare acum mesh-urile ascunse (variantele stinse dădeau fals).
- **`probe_decor`**: atribuirea pe surse pentru kitul Okinawa după fișierul strămoș
  (casele ieșeau `village_house`, pinii `alpine_pines`); totalurile erau corecte.
- **`FlockProp`**: exporturile `mesh_name`/`view_m` și `tri_class = "atint:<nume>"`.
- **Tetrapozii provizorii** (`Dig_tetrapozi`, 42) stăteau pe fundul apei; înlocuiți de
  ZonaH.

## Încărcarea și coacerea decorului

Cu toate zonele integrate, pista ajunsese la **8,80 s** de încărcare la rece (baza
fundației 3,08 s; plafonul brief-ului ≤ 5,6 s): 3 712 noduri `WorldProp` sub
`DecorManual`, fiecare instanțiind GLB-ul întreg cu variantele stinse.

`tools/bake_okinawa_decor.py` (cu manifestul `tools/bake_okinawa_manifest.gd`) coace
nodurile **fără coliziune** în stoluri `FlockProp`, pe zonă × GLB × nod de mesh × celulă
de 80 m (`DecorManual/<Zona>/Coacere`). Re-rulabil și idempotent:

```
python tools/bake_okinawa_decor.py --godot /d/GameDev/Godot_v4.7-stable_win64_console.exe
```

- 2 394 de noduri → 312 stoluri; rămân `WorldProp` 1 318 (cele cu coliziune `hull`/`mesh`/
  `trunk`, plus grupurile sub 3 instanțe).
- **8,80 → 5,20 s** la rece (4,13 s la cald); desene 7 342 → **3 662**; prop-uri și
  triunghiuri identice (−2 bougainvillea duplicate la aceeași coordonată); 29 materiale.
- Capturi A/B la 6 fracții: identice la ochi, diferențele sunt faza valurilor
  (`docs/track_briefs/img/okinawa_plan/coacere/`).
- **Abatere asumată:** pe tema okinawa, umbra de contact de sub vegetație și copaci e
  disc plat (`prop_contact_flat`, ca la Track19), nu urmărește relieful. Fără ea
  încărcarea rămânea la 7,3 s.
- **Generatoarele rămân sursa de adevăr.** După o schimbare de decor: rulezi generatorul
  zonei, apoi convertorul, apoi `--import`. Dacă se schimbă tema, coacerea se reface de
  la scena necoaptă (discurile de contact se scriu la coacere).
- Din cele 5,2 s rămase, ~2 s sunt construirea umbrelor de contact (funcție veche a
  pistei, comună). E următorul loc de câștigat dacă testul pe telefon cere.

## Gărzile pe scena integrată

Pe `okinawa/poi-integrare` după toate merge-urile, cu `--import` înainte:

| gardă | rezultat | față de bază |
|---|---|---|
| ProbeLaneClear | 4 probe blocate | exact baza |
| ProbeBuried | 0 îngropate, 0 tavane | exact baza |
| probe_solid | OK | = |
| probe_decor | **29 materiale**, 12 923 prop-uri, 3 662 desene, 14,87 M triunghiuri | 24 → 29 materiale (plafon 30) |
| probe_decor_overlap `--manual` | 0 peste asfalt | baza avea 1 (zidul provizoriu D), reparat |
| probe_manual | 117 „de reparat”, toate intenționate | 112 la E (pietre și faleză pe taluz), 4 ziduri gusuku ale lui D pe umăr (6,5–7,2 m de axă), poarta D peste drum |
| ProbeCameraSolid | 1 incident la 0.672–0.678 (`LiftSpan`) | exact baza |
| probe_load_time | 5,20 / 4,13 / 4,22 s | baza 3,08 s; plafon 5,6 s |
| `verify_local` | OK (10 pași) | = |
| ProbeRace, 16 seed-uri | **70 repuneri, 17 blocaje, 21 ejectări „perete”, toate pe 0.635–0.675** (pasajul podului); zero în rest. A doua rulare, înainte de densitate și coacere: 69 / 9 / 21 | baza: 47 / 11 / 11, aceleași locuri. Mai multe evenimente, nicio locație nouă; LaneClear și probe_solid arată că decorul nu intră pe bandă. 0.635 e punctul de reapariție după incidentele de la 0.661. **De judecat la volan** |

**Ce costă cel mai mult:** `cycad` (~2 700 triunghiuri pe piesă, ~3,4 M în total). Dacă
testul pe telefon nu ține 60 fps, primul loc de tăiat (după umbrele dinamice, cum spune
CLAUDE.md).

## Iesirea/intrarea de pe drum si sensul valului (#607, #608, #609 — 31 oct 2026)

- **#608/#607, cauza:** soseaua sta la +1,6..2,0 m, deci regula de zid „exterior SAU inaltat > 1 m" punea gardul invizibil (`wall_visible` false) pe ambele parti, pe tot turul, si pe uscat. Il tinea si pe cel care ramasese afara. Fix: `walls_water_only` pe tema `okinawa` (gardul doar unde la 3/8/15 m in afara fundul e sub mare, ca pe Ha Long). Garda: `tools/ProbeEdgeCross.tscn --track=20` (masina reala, 66 puncte x 2 parti x iesire/intrare, verdict PICAT pe zid invizibil pe uscat; cu flagul oprit: 17 cazuri).
- **Inventar (132 iesiri, 103 intrari testate, 29 fara teren = mare):** iesiri blocate 114 -> 66, intrari blocate 83 -> 44. Ce a ramas e INTENTIONAT si vizibil: satul/aleea (A-C: `aZid`, `bZid`, `Fukugi`, `Gard`, case), castelul (D), rapele cu parapet de pod (0.54-0.59, 0.67-0.70, 0.84-0.93), tetrapozii digului (H), rampa podului ridicator. Decizie de design deschisa: ziduri/garduri de sat fara nicio poarta (0.015-0.27).
- **#609:** `HazardMarker.wave_travel = -1` pe markerul „Val": creasta merge din dreapta spre stanga. Pe dig marea e pe ambele parti (cota +0,5 m la 3-8 m, -0,2 la 15 m, -4,6 la 25 m); stanga e marea larga (tetrapozi), dreapta golful. Brieful (§3) cerea valul dinspre larg = din stanga; sensul cerut de dezvoltator il aduce dinspre golf. Reversibil: `wave_travel = 1`. Garda: `tools/ProbeWaveDir.tscn --track=20 --expect=left`.
- **ProbeRace, 4 seed-uri, 200 s:** dupa 2 repuneri (ambele pe 0.635-0.666, podul), inainte 7 (aceeasi zona); zero la val (0.881).
