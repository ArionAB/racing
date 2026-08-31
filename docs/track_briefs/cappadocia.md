# Track brief — Cappadocia (`Track13`, temă `cappadocia`) — v0.1 (concept)

> Concept de pistă, înaintea listei de assets. Harta interactivă cu POI-urile,
> profilul, ceasurile și loturile la scară: `img/cappadocia_map.html`
> (artefactul „Cappadocia Recon"). Scheletul e cel din `chongqing.md`;
> secțiunile de assets (§5) sunt schițate, nu complete — se detaliază după ce
> traseul trece de ProbeLayout și de captura `--driver`.
> Prima pistă cu **subteran** (caverne + preset de cameră), prima cu **hazard
> care vine de jos** (baloanele urcă din vale), prima de **zori**.
>
> **v0.1 (30 aug 2026):** ales dintre trei propuneri (Chuquicamata /
> Cappadocia / Tonlé Sap); integrat un concept extern (ChatGPT) — a adus cele
> trei acte, hornul care se prăbușește în rampă, pânza aterizată, suflul
> arzătorului și rampa din stânca goală; a fost **întors pe dos** acolo unde
> contrazicea frustumul (baloanele erau „deasupra" — la noi urcă din vale, §2.0)
> și respins la porumbei/oi/olărie/vânt (§8).

## 0. Într-o propoziție

Zori de vară în Cappadocia: pornești dintr-un sat săpat în tuf, te strecori
printr-o **pădure de hornuri de zână** aproape lipite de drum, ieși pe
**cornișa de deasupra Văii Roșii** — sub tine, în vale, **zeci de baloane cu
aer cald se ridică** și unele urcă până la bandă — cobori într-un canion
roșu unde **un horn crăpat se prăbușește și îți face rampă**, treci printr-o
vie și pe lângă **un balon aterizat** care și-a întins pânza peste drum,
intri **sub pământ** în orașul subteran (săli cu coloane, **uși de piatră de
moară** care se rostogolesc, torțe, puțuri de lumină) și ieși **în spirală
prin interiorul unei stânci-castel goale** care te aruncă înapoi pe platou,
în lumină.
Singura pistă din joc în care lumea de dedesubt e **săpată**, nu construită.

## 0.1 Regula de artă (ce NU e pista asta)

**Nu „deșert cu stânci". O lume săpată în piatră moale, cu baloane sub tine.**
Ce trebuie să recunoască jucătorul în 3 secunde: *„drumul se strecoară
printre conuri de piatră cu ferestre, sub mine plutesc baloane, și în 20 de
secunde o să fiu sub pământ."* Tuful (moale, săpat, locuit) e pentru
Cappadocia ce e verticalitatea pentru Chongqing.

| pondere | strat |
|---|---|
| **55%** | geologie de tuf: hornuri de zână, conuri cu pălărie de bazalt, faleze în benzi roz-crem-roșu, cornișe |
| **20%** | lumea săpată: ferestre și uși în stâncă, porumbare, biserici rupestre, orașul subteran, torțe |
| **15%** | baloane: în vale (fundal viu) și la bandă (hazard); pânză aterizată |
| **10%** | viață: vie, plopi, o căruță cu oale (decor), porumbei (decor) |

Trei acte pe un tur, **aceeași paletă, altă proporție**: Göreme (crem
dominant), Valea Roșie (roșu-roz dominant), subteranul (întuneric + portocaliu
de torță). Nu trei palete.

## 1. De ce Cappadocia (referința reală, ce luăm din ea)

| loc real | ce luăm |
|---|---|
| **Göreme** — sat cu case și hoteluri săpate în conuri de tuf | POI de start: piața satului între hornuri locuite; ferestrele sunt găuri în con, nu clădiri |
| **Paşabağ (Valea Călugărilor)** — hornuri cu 2–3 pălării, cele mai dese | **pădurea de hornuri**: drumul șerpuiește PRINTRE ele, nu pe lângă; două se ating deasupra drumului (poartă) |
| **Valea Roșie / Valea Trandafirilor** — faleze în benzi roz-roșu-crem, cornișe la apus/răsărit | **cornișa**: buza văii, fără parapet pe dreapta; benzile de culoare sunt geometrie + vertex color |
| **Baloanele de la răsărit** (100+ pe dimineață, decolează din văi) | **hazardul-semnătură**, dar întors: baloanele urcă **din vale**, de sub bandă — exact unde vede camera (§2.0) |
| **Derinkuyu / Kaymaklı** — orașe subterane pe 8 niveluri, uși de piatră de moară, puțuri de ventilație | subteranul: săli mari (cavernă, nu tunel — §2.0), **piatra de moară** ca zid rulant, **puțurile** ca lumină și scurtătură |
| **Uçhisar / Ortahisar** — stâncile-castel, găurite ca un fagure | **stânca goală** cu spirala înăuntru (gimmick-ul: bază 70 m, ca să încapă o elice de 11%) + siluetă de fundal la 200+ m |
| **Erciyes** — vulcanul de 3.900 m care a făcut tuful | siluetă departe, sub `fog_end`, cu zăpadă; explică geologia dintr-o privire |
| **Podgoriile din văi**, plopii, porumbarele | viața: vie = iarbă lentă cu geometrie; porumbei = decor care țâșnește |
| **Ceramica din Avanos** | o căruță cu oale ca decor static cu coliziune la ieșirea din sat |

Culorile locului: **crem de tuf** în soare, roz prăfuit și **roșu-cărămiziu**
în benzi (Valea Roșie), pălării negre de bazalt, verde de vie și de plop,
baloane saturate (roșu, albastru, galben, alb, dungi), **portocaliu de torță**
în subteran, cer de zori (portocaliu jos → albastru pal sus). Lumina: soare
**jos, la 12–15°**, cald, cu umbre lungi — `theme_shadows` rămâne pornit (e
prima pistă unde umbrele lungi ale hornurilor sunt identitate); sub pământ
umbrele nu contează (tavan), AO-ul din vertex colors face contactul.

## 2.0 Verificarea cu camera (de ce baloanele urcă din vale, și de ce subteranul e cavernă)

`ChaseCamera`: **10 m sus, 12,5 m în spate, 28,7° în jos, FOV 68°**. Marginea
de sus a frustumului e la **~+5° peste orizontală**: la distanța `d` vezi în
sus cel mult `10 + 0.093·d` m.

- **„Baloane deasupra pistei" nu se vede.** Un balon la 30 m înălțime intră
  în cadru abia de la ~300 m — în ceață. Jucătorul n-ar vedea niciodată
  balonul coborând, doar coșul apărut din nimic. **Deci baloanele nu vin de
  sus, vin de jos**: traseul merge pe platou și pe cornișă **deasupra văii**,
  baloanele decolează din vale (−20…−40 m sub bandă) și **urcă până la
  nivelul drumului**. Un coș care se ridică lângă cornișă se vede 3–4 s
  înainte să-ți intre în bandă. Valea e scena, nu cerul.
- **Subteranul e cavernă, nu tunel.** Camera stă la 10 m; `_unclip` o
  împinge afară din orice perete, deci un tunel de 5 m ar prăbuși camera în
  mașină. **Tavan ≥ 15 m în săli**; gâturi de ≤ 10 m doar dacă sunt ≤ 15 m
  lungime (un clip de sub 1 s e tolerabil). Derinkuyu real are 1,8 m — la
  scara de jucărie, o mașinuță într-o sală de 15 m e chiar corect.
- **Tavanul se vede în față, nu deasupra.** Cu +5°, un tavan de 15 m intră
  în cadru de la ~50 m și „vine" spre tine. Ca să se vadă de la 25 m (și
  stalactitele, arcele, puțul de lumină), **preset de cameră „cavernă"**
  (§3): `height` 10 → 6,5 m, `look_height` 0,4 → 1,4 m, `base_fov` +6°.
  Pitch = atan(5,1/17,5) = 16,2°, jumătate de FOV = 37° → marginea de sus la
  **~+21°**. Lerp 0,5 s la intrare/ieșire (Area3D la gură), ca tranziția să
  fie un moment în sine. **Nu** vederea șoferului: feelingul e pe chase cam,
  touch-ul e calibrat pe ea, AI-ul n-are nimic de câștigat.
- **Hornurile de lângă drum sunt înalte și se văd** — până la 10 + 0,093·d:
  la 20 m vezi 12 m, la 40 m vezi 14 m. Deci hornurile de 12–18 m sunt
  exact plafonul frustumului (memoria `inaltimea-obiectelor-si-camera`):
  vârful cu pălărie se vede când te apropii, nu de departe. Cele de 30 m
  (Uçhisar) stau la 200+ m ca siluete.

Consecința: **valea e sub tine, subteranul e sub vale, stânca goală te scoate
înapoi sus** — turul e o buclă verticală de 50 m, coborâtă în două trepte și
urcată într-una.

## 2. Traseul și punctele de interes (POI)

Lungime țintă **~2.0 km** (tur ~70–75 s, 3 tururi ≈ 3:40 — în fereastra
Ignition 65–80 s din `ref_notes/sisteme.md`). Sens: **antiorar** — valea pe
dreapta (în AFARA buclei, ca apa la Chongqing/Stromboli). Cota maximă **~50 m**
(platoul), minimă **~12 m** (sălile din subteran). Coborâre în două trepte
(cornișă 46 → 33, canion 33 → 15), urcare într-una (spirala stâncii goale 12 → 50 pe
~350 m — 2 ture cu raza 28 m — ≈ **11%**, sub media de 13% — **se măsoară cu
ProbeLayout înaintea oricărui decor**). O elice într-un horn de 24 m diametru
ar fi ieșit la **42%**: de aceea gimmick-ul e o stâncă-castel de 70 m la
bază, nu un horn.

```
   [A] START Göreme (50 m) ──── [B] pădurea de hornuri (50→46 m)
        ↑                                    |
   [G] stânca goală: spirală + kicker  [C] cornișa Văii Roșii (46→33 m)
        (12→50 m)                             baloanele urcă din vale
        |                                    |
   [F] orașul subteran (12 m)          [D] canionul: hornul-rampă (33→15 m)
        piatra de moară, puțuri              |
        \____ [E] via + balonul aterizat (16→14 m) ____/
```

| # | frac | POI | ce se întâmplă | lățime |
|---|---|---|---|---|
| **A** | 0.00 | **Start în piața din Göreme** — dale de tuf, conuri locuite cu ferestre și uși, o terasă cu covoare, un plop, porumbar; la ieșire **căruța cu oale** (decor static cu coliziune, o fantă de 4 m pe lângă ea) | grilă pe piață; primul horn de lângă drum e la 6 m de bandă, ca să-i vezi pălăria | 9 m |
| **B** | 0.05–0.16 | **Pădurea de hornuri (Paşabağ)** — drumul șerpuiește **printre** conuri de 10–18 m la 2–4 m de bandă; două hornuri gemene se ating deasupra drumului = **poarta** (tavan scurt, 12 m, 8 m lungime); porumbeii țâșnesc dintr-un porumbar când treci (decor) | strângere tehnică 6 m în S-uri; umbrele lungi ale conurilor taie drumul (identitate vizuală) | 6–7 m |
| **C** | 0.18–0.36 | **Cornișa Văii Roșii** — drumul iese pe buza văii, **fără parapet pe dreapta**: sub tine, 30 m mai jos, fundul văii cu **20–30 de baloane** în diverse faze (pe pământ, umflându-se, în aer); benzile roz-roșu ale falezei sub bandă. **Coșurile care urcă**: 3 baloane ancorate pe fundul văii se ridică pe ciclu (~28 s, defazate) până la nivelul benzii și **coșul îți intră în bandă** 4 s, apoi coboară. La hairpinul din capăt, **balonul arzătorului**: un balon ancorat la 6 m de exteriorul curbei; pe ciclu (~17 s) arzătorul pornește (flacără vizibilă în frustum, 1 s telegraph) și **suflul te împinge spre exterior** — spre gol | **vârful vizual + hazardul-semnătură**. Cădere = repunere ~2 s. Coșul e platformă (`platform_velocity`): poți ateriza pe el la o săritură și te duce sus 2 s (câștig mic, spectaculos) | 7 m |
| **D** | 0.38–0.50 | **Canionul roșu** — coborâre în S între faleze în benzi, 7 m lățime; la mijloc **hornul crăpat**: un horn de 16 m stă în mijlocul drumului (ocolul e pe stânga, lung, 6 m); telegraph: pietricele + praf + trosnet (2 s), apoi **se prăbușește spre dreapta și devine rampă** — de pe ea sari peste un S întreg al ocolului (câștig ~3 s, aterizare pe canion; ratezi → în moloz, grip 0,8×) | **transformare de pistă**, vezi §3 pentru regula de ciclu | 6–7 m |
| **E** | 0.52–0.64 | **Via și balonul aterizat** — fundul văii: rânduri de vie (iarbă lentă cu geometrie, se trece prin ele = scurtătură lentă), plopi, o fermă; **un balon aterizează pe drum** pe ciclu (~45 s): coșul se pune pe bandă, pânza se dezumflă și **se întinde 20 m peste drum** (suprafață lentă 0,6×, culoare tare), apoi echipajul o „strânge" și balonul decolează | fâșia de viteză; decizia: prin vie (lent, sigur) sau pe drum (rapid, dacă pânza nu e jos) | 8 m |
| **F** | 0.66–0.82 | **Orașul subteran** — gura săpată în faleză (arc, torțe); **preset cameră cavernă** la intrare. **Sala 1** (tavan 16 m, coloane, alcove, un **puț de ventilație** cu coloană de lumină care cade pe drum); **gâtul cu piatra de moară**: două culoare — scurt (4 m, o **ușă de piatră de moară** de 3 m diametru se rostogolește în lăcaș pe ciclu ~23 s: închis = zid) și lung (+2,5 s, mereu liber); **Sala 2** (tavan 18 m, biserică rupestră cu arce, fresce abstracte, puțul al doilea) | opoziție de fază între culoare nu e nevoie (lungul e mereu deschis); contact cu piatra în mișcare = ești împins înapoi cu masă, nu distrus | 6–8 m |
| **G** | 0.84–0.98 | **Stânca goală** — din sala 2 drumul urcă **în spirală pe interiorul unei stânci-castel goale** (70 m la bază, 45 m înaltă, găurită ca Uçhisar; rampă elicoidală săpată, 2 ture cu raza 28 m, urcare 12 → 50 m), lumina de sus crește la fiecare tură, ferestre spre vale prin perete (vezi baloanele iar, tot mai de sus); la vârf **kickerul de ieșire**: sari prin gura stâncii pe platou, cu airtime, în lumină plină | urcare tehnică ~11%; interiorul e „pistă peste pistă" (spirala trece deasupra ei) → `custom_overpass_ranges` (PR #353), separare ≥ 12 m între ture (pas de 19 m/tură) | 6 m |
| **A′** | 1.00 | aterizare pe platou, 40 m până la linie | camera revine la preset normal la ieșirea din stâncă | 9 m |

**Ritmul turului:** sat (respiro) → hornuri (strângere + umbre) → cornișă
(vârful vizual + coșurile + suflul + frica de gol) → canion (hornul-rampă,
decizie) → vie (viteză, decizia pânzei) → subteran (întuneric, piatra de
moară, presiune) → spirala (urcare, lumina crește) → salt în lumină → sat.

**Ceasuri care nu împart durata turului** (lecția Stromboli): coșurile ~28 s
(3 baloane defazate cu 1/3), arzătorul ~17 s, piatra de moară ~23 s, balonul
aterizat ~45 s. Faza fiecăruia se mută de la tur la tur.

## 3. Hazarduri și mecanici (ce e nou pentru motor)

| mecanică | pe scurt | ce cere în cod |
|---|---|---|
| **Coșul care urcă din vale** (C) | balon ancorat pe fundul văii; pe ciclu urcă 30 m până la bandă, stă 4 s cu coșul în drum, coboară | **nou:** `BalloonHazard` — corp mobil pe traiectorie verticală (reuse `LiftBridgeHazard` ca mișcare + `platform_velocity` din telecabină pentru „poți sta pe coș"); pânza e mesh mare, coșul e coliziune; cablul de ancorare e o linie |
| **Suflul arzătorului** (C, hairpin) | flacără 1 s (telegraph) → impuls lateral 0,8 s spre exterior; ciclu ~17 s | **nou, mic:** `Area3D` + forță constantă pe `RigidBody3D` (avem `TyphoonHazard`, dar ăla e global; aici e local și direcțional). Flacăra = emisiv `LAVA_ORANGE` + particule cu count mic |
| **Hornul-rampă** (D) | horn în mijlocul drumului, crapă (2 s), cade, e rampă | **transformare de pistă — regula de ciclu, decizie de luat:** contractul (Chongqing §2) cere hazard ciclic, învățabil. Propunere: **o dată pe cursă, la moment fix** — cade când liderul trece prima dată (tur 1), rămâne rampă în tururile 2–3. E învățabil **între curse** (mereu același loc, același moment), nu între tururi. Alternativa strict ciclică (~40 s: cade → molozul se „așază" în praf → hornul se reface) e mai ieftină ca stare, dar mai puțin onestă în lumea de jucărie. **Dezvoltatorul alege**; codul e același (două stări + moloz `rockfall_hazard` + `FlyoffKicker` pe rampă) |
| **Piatra de moară** (F) | ușă de piatră de 3 m se rostogolește în lăcaș pe ciclu ~23 s: închide culoarul scurt | reuse `SlidingHazard` (mișcare liniară cu rotație pe axă) — mesh nou; contact în mișcare = împins înapoi (masă mare); închis = zid static |
| **Balonul aterizat** (E) | coș pe drum + pânză de 20 m peste bandă (grip 0,6×) pe ciclu ~45 s; decolează | reuse ciclu (`EruptionCycle` ca metronom) + suprafață pe interval (există); pânza = mesh cu 3 stări (umflat / dezumflat pe drum / strâns) |
| **Preset cameră cavernă** (F–G) | `height` 6,5, `look_height` 1,4, `base_fov` +6, lerp 0,5 s | **nou, mic:** `Area3D` la gură → `ChaseCamera` primește un preset țintă și interpolează cele trei `@export`-uri. Zero schimbări în `_unclip` |
| **Spirala în stâncă** (G) | rampă elicoidală, drumul peste el însuși ×2 | reuse `custom_overpass_ranges` (PR #353) + `is_on_road` cu toleranță verticală (Chongqing §7.1 — **verifică dacă a intrat**; dacă nu, se face aici) |
| **Puțurile de ventilație** (F) | coloane de lumină; la suprafață, două guri pe platou = **scurtătură în jos** (sari în puț → aterizezi în sala 1, câștig ~4 s, aterizare cu tremur) | reuse `RespawnZone` invers + `FlyoffKicker` scurt; puțul e un cilindru de 5 m cu podea de nisip (grip 0,8×) |
| **Poarta de hornuri gemene** (B) | tavan scurt de 12 m, 8 m lungime | decor cu coliziune; verifică `_unclip` pe 8 m (clip < 1 s) |
| **Căruța cu oale** (A) | decor static cu coliziune, fantă de 4 m | `world_prop`, zero cod |
| **Porumbeii** (B) | țâșnesc din porumbar la apropiere, decor | particule sau 6 quad-uri billboard pe `Area3D`; zero gameplay |
| **Golul de pe cornișă** | repunere ~2 s | `custom_ravines` + `RespawnZone` (există) |

Calibrare (sisteme.md): cădere ≈ 2 s ≈ 2 poziții; hornul-rampă reușit ≈ +3 s,
ratat ≈ −3 s; piatra închisă ≈ +2,5 s pe ocol; pânza pe drum ≈ +2 s dacă o
iei prin ea, via ≈ +1,5 s.

## 4. Paleta și lumina (fără slot nou — slotul 31 s-a consumat la Chongqing)

**Nu există slot liber.** Cappadocia se face **integral din sloturi existente**;
dacă rozul prăfuit al Văii Trandafirilor nu iese din crem + teracotă cu
vertex color (care doar întunecă — `surfacetool-clamp-vertex-color`), **aici
se ia decizia paletei la 64** (regenerarea atlasului, decizie separată).

| rol | slot existent |
|---|---|
| tuf în soare (hornuri, faleze, sat) | `CORAL_SAND` 19 (crem) — dominant |
| tuf mediu / umbrit | `SAND_MID` 1, `SAND_SHADOW` 2 |
| **benzile roșii ale Văii Roșii** | `TILE_TERRACOTTA` 23 (benzi late) + `LARCH_RUST` 27 (benzi înguste, ruginii) |
| pălăriile de bazalt ale hornurilor | `VOLCANIC_BLACK` 20 |
| interiorul subteranului, alcove | `ROCK_DARK` 4 + AO din vertex |
| **torțe, flacăra arzătorului, lumina din puțuri** | `LAVA_ORANGE` 30 (emisiv, reuse shader de lavă) |
| baloane | `CAR_RED` 14, `CAR_BLUE` 15, `CAR_YELLOW` 16, `FOAM_WHITE` 22, dungă `NEON_PINK` 31 (accent, un balon din zece) |
| coșuri de răchită, vie uscată | `DRY_VEGETATION` 13, `WOOD_WEATHERED` 9 |
| vie, plopi | `CACTUS_GREEN` 12 (vie), `TROPICAL_GREEN` 21 (plopi) |
| asfalt / pământ bătut | `ASPHALT` 5 / `ASPHALT_EDGE` 6 |
| oale, covoare | `RUST_METAL` 10 (lut ars), `KERB_RED` 7 (covoare) |
| Erciyes cu zăpadă (siluetă) | `MARBLE_GREY` 29 + `FOAM_WHITE` 22 |

**Lumina:** zori — direcțională caldă la **12–15° elevație**, dinspre est
(valea), umbre lungi pornite (`theme_shadows = true`, cascada de 90 m).
Ambient portocaliu-pal. `fog_end` ~300 m, ceață caldă, aurie (Erciyes și
Uçhisar în ea). **Sub pământ:** aceeași direcțională nu ajunge (tavan), deci
lumina e ambient scăzut + emisivele torțelor + coloanele de lumină ale
puțurilor (un con cu alpha, nu volumetrie). Contrastul întuneric → lumină la
ieșirea din horn e **gratuit**: doar tavanul dispare.

## 5. Assets (schiță — lista completă după ProbeLayout)

Categoria nouă `assets/models/cappadocia/` (memoria `assets-models-categorii`).

### 5.1 Teren și suprafețe (cod, clase de textură)
`tuff_banded` (faleze și cornișă — benzile roz-roșu în textura de clasă, nu
în geometrie), `tuff_plain` (hornuri, sat), `cave_wall` (subteran, cu dălți
de săpare), `dirt_road` (drum de pământ bătut în vale), decal `wheel_ruts`,
`vine_row` (iarbă lentă cu geometrie), `balloon_fabric` (pânza aterizată,
dungi).

### 5.2 Hero (unice)
| asset | note |
|---|---|
| `hollow_rock.glb` | stânca-castel goală: 70 m bază → 30 m vârf, 45 m înaltă, cu rampa elicoidală interioară (2 ture, raza 28 m, 6 m lățime, urcare 38 m), ferestre spre vale, gura de sus cu kicker — **cea mai grea piesă**; interiorul e pistă |
| `underground_hall_a.glb` / `_b.glb` | sala 1 (16 m tavan, coloane, alcove, puț) și sala 2 (18 m, arce de biserică rupestră, fresce abstracte) — pot fi kit de bucăți (coloană, arc, alcovă, tavan) |
| `millstone_door.glb` + `millstone_slot.glb` | ușa de piatră de 3 m diametru × 0,6 m + lăcașul din perete |
| `cracked_chimney.glb` (3 stări) | în picioare / căzut ca rampă / moloz |
| `balloon_kit` | `balloon_envelope_a/b/c.glb` (3 forme, 12 m înalt umflat), `balloon_basket.glb` (2×2 m răchită, arzător), `balloon_landed.glb` (pânză dezumflată 20×8 m), `balloon_tether.glb` (cablu + țăruș) |
| `twin_chimney_gate.glb` | poarta de hornuri gemene, 12 m sub arc |
| `cave_entrance.glb` | gura subteranului: arc săpat de 10 m, torțe |
| `vent_shaft.glb` | puțul de ventilație: cilindru de 5 m, gură la suprafață cu bordură |

### 5.3 Kit de tuf (modular, statistice)
`chimney_a/b/c/d.glb` (conuri 10–18 m cu pălărie de bazalt, unul cu ferestre),
`chimney_mushroom.glb`, `chimney_triple.glb`, `cave_house_a/b/c.glb` (conuri
locuite 8–12 m cu uși, ferestre, scară, balcon), `dovecote.glb` (porumbar
săpat cu găuri și vopsea albă), `rock_church_facade.glb`, `cliff_band_module.glb`
(felie de faleză în benzi, 20 m), `torch.glb`, `column_carved.glb`,
`arch_carved.glb`, `alcove.glb`, `poplar_a/b.glb` (plopi 12–16 m), `vine_row.glb`
(rând de vie 10 m pe araci), `farmhouse.glb`, `pottery_cart.glb`, `pot_stack.glb`,
`carpet_terrace.glb` (terasă cu covoare și perne), `pigeon_flock` (billboard).

### 5.4 Fundal (`horizon_class`)
`uchisar_castle.glb` (stânca-castel, 60 m, la 200+ m pe platou), `erciyes.glb`
(siluetă de vulcan cu zăpadă, sub `fog_end` 300), `balloon_far` (MultiMesh de
baloane simplificate, 30–40 în vale + 10 sus în ceață, mișcare lentă),
platoul cu hornuri-siluetă.

### 5.5 Sunet
arzătorul (telegraph — „fwoosh"), scârțâitul răchitei când coșul ajunge la
bandă, trosnetul hornului (telegraph), piatra de moară rostogolindu-se pe
piatră, ecou în săli (reverb pe zona subterană), porumbei, vântul la
ieșirea din horn, un ezan îndepărtat la start (o dată, atmosferă).

## 6. Bugete

- triunghiuri: raportate, fără plafon; stânca goală și sălile sunt piesele
  grele — se măsoară pe piesă; **hornurile de lângă drum sunt multe** (~40) —
  `chimney_*` sub 600 tri fiecare, cu `radial_segments` setat
- materiale: atlas + ~6 clase (§5.1) + emisiv (torțe/arzător, reuse lavă) +
  decal → țintă **≤ 22** (Chongqing a pornit tot de la 22)
- **umbre pornite** (identitatea de zori) — dacă testul pe device nu ține
  60 fps, se sting întâi în subteran (unde oricum nu se văd), apoi peste tot
- **de verificat devreme:** (1) preset de cameră în cavernă — captura
  `--driver` din sala 1: se vede tavanul? puțul de lumină?; (2) spirala
  hornului = pistă peste pistă cu separare 12 m — ProbeOverpass pe ea;
  (3) coșul ca platformă mobilă verticală (telecabina a ținut — `telecabina-platforma-mobila`)

## 7. Ordinea de construcție

1. **Sonde tehnice înaintea traseului:** (a) preset de cameră cavernă pe o
   sală-test de 15 m (captură `--driver`: tavan vizibil de la 25 m?);
   (b) `ProbeOverpass` pe o spirală elicoidală de 6 m lățime cu pas de 19 m
   (terenul nu urcă după ea? indexul ține pe ture?); (c) coșul ca platformă
   verticală (reuse ProbeCableway cu traiectorie verticală).
2. `Track13.tscn` din `TrackFromPath`, temă `cappadocia` (zori, fog 300,
   umbre pornite), traseul din §2. ProbeLayout pe pante (spirala < 13%).
3. Sonda de feel: hornuri → cornișă → canion → subteran → spirală, un tur
   singur. **Captura `--driver` de pe C**: se văd baloanele în vale? Dacă
   valea e prea adâncă (−40 m) și baloanele dispar în ceață, se ridică
   fundul văii la −25 m.
4. Coșurile care urcă + arzătorul (hazardul-semnătură); ProbeRace A/B pe
   distribuții.
5. Piatra de moară, balonul aterizat, hornul-rampă (cu decizia de ciclu).
6. Hero-assets: stânca goală, sălile, kitul de baloane, hornul crăpat.
7. Kit de tuf, fundal, figuranți; probe_decor, verdict la volan.

## 8. Lecții aplicate anticipat

- **Frustumul decide, și de data asta întoarce ideea pe dos:** baloanele
  urcă din vale, nu coboară din cer. Tot ce e „deasupra" în conceptul extern
  a fost mutat „dedesubt" sau „în față".
- **Subteran = cavernă ≥ 15 m + preset de cameră**, nu tunel și nu vedere
  de șofer. Tavanul se citește „venind spre tine", nu de deasupra.
- **Plafonul de înălțime al hornurilor de lângă drum se derivă** (10 + 0,093·d),
  nu se alege: 12–18 m lângă bandă, 30+ m doar ca siluete la 200 m.
- **Hazarduri distincte mecanic, unul per loc:** platformă (coș), impuls
  (arzător), transformare (horn), zid rulant (piatră), suprafață (pânză).
  Nimic nu dublează Alpii (rockfall e doar telegraph), Okinawa (taifunul e
  global, arzătorul e local) sau Stromboli.
- **Respins din conceptul extern, cu motiv:** porumbei ca obstrucție de
  vizibilitate (pedeapsă fără decizie — rămân decor), oi imprevizibile
  (încalcă „AI onest"; viața de lume e pe traseu fix), olărie/vie ca
  breakables fizice (RigidBody-uri mărunte în număr mare = exact ce omoară
  mobilul; vasele sunt decor, via e suprafață lentă), vânt ca mecanică de
  mediu (dublează Okinawa), blocajul de baloane cu camion (trei hazarduri
  într-o scenă — zgomot), „intri printr-o gaură și ieși 20 m mai sus"
  (teleportare — la noi e rampa condusă din stânca goală).
- **Fără slot nou de paletă.** Dacă rozul nu iese, decizia „64 de sloturi"
  se ia aici, explicit, nu strecurat.
- **Margini fără parapet tăiate în pantă**, raze > half_width cu puncte pe
  arc, separare verticală ≥ 12 m între ture.
- **Panta se calculează înainte de a desena gimmick-ul:** elicea în hornul de
  24 m dădea 42%; stânca de 70 m dă 11%. Geometria a schimbat assetul-erou
  înainte să existe.

## 9. Prompt pentru ChatGPT (dioramă de referință) — v0.1, paste-ready

Textul e și în artefactul „Cappadocia Recon", cu buton de copiere; se
atașează o captură a planului de acolo.

**v0.1a (30 aug):** după primele două randări (`img/cappadocia_v1.jpeg`,
`img/cappadocia_v2.png`) s-au adăugat trei HARD CONSTRAINTS — spirala era pe
exteriorul stâncii, pânza aterizată pe câmp, bucla neînchisă. Referința de
stil e **v1** (fațetat, bucla citibilă); din v2 se folosesc doar panourile
de jos, pentru vederea șoferului.

**v0.1b (30 aug):** `img/cappadocia_v3.jpeg` trece toate cele trei
constrângeri (spirala în interior, în cutaway; pânza peste drum; bucla închisă
cu ieșirea din vârful stâncii) — **v3 e referința de stil și de layout** pentru
gauntlet și pentru foaia de assets. Rămân de corectat la construcție, nu în
imagine: hornurile trebuie să fie *printre* bandă (în v3 drumul le ocolește),
iar sălile subterane sunt desenate stivuite, fără gura de intrare vizibilă.

> Create a stylized low-poly **tabletop diorama** of a toy-car racing track
> in **Cappadocia, Turkey, at sunrise** — the land of fairy chimneys, cave
> villages, underground cities and hot-air balloons. Use the attached
> top-down plan as the layout: same loop shape, same positions of the
> landmarks.
>
> HARD CONSTRAINTS (the previous render got these wrong — check them before anything else):
> 1. The spiral road is INSIDE the hollow castle-rock, never wrapped around its outside. Show the rock cut away (half removed) so the helix is visible inside the walls, with windows looking out.
> 2. The landed balloon's deflated envelope lies ACROSS the road, blocking the lane — not on a field or verge beside it. Cars must have to go through or around it.
> 3. The route must be one clearly closed loop: a jump ramp at the TOP of the hollow rock launches cars out onto the plateau back toward the village, and the red canyon is a real cut descending from the cornice to the valley floor (not just a ramp on the cliff face).
>
> **STYLE (strict):** faceted, flat-shaded low-poly meshes like a Blender
> viewport render — **no fine surface texture, no painterly brushwork, no
> photorealism**. Chunky toy proportions: cars are stubby and ~1.3× wider
> than real cars; rock formations are simplified into big smooth cones and
> banded cliffs. Soft baked ambient occlusion in the crevices. Muted
> cream-and-rose environment colors (~45% saturation) with only three
> saturated accents: the **hot-air balloons**, the **orange torch light in
> the caves**, and the toy cars. Lighting: a low warm sun from the right
> (about 13° above the horizon) casting long soft shadows from every
> chimney; the sky is a plain gradient from pale orange at the horizon to
> pale blue above, no clouds. Thin golden haze in the far distance. Show the
> diorama on a thin dark rounded-rectangle table base, from a raised 3/4
> view.
>
> **THE LAND [!]:** the whole diorama is a **cream-colored tuff plateau on
> the left/top that drops ~35 m into a red-and-rose banded valley on the
> right**. The plateau is covered in fairy chimneys — tall cream cones 10–18
> m high, many with a dark basalt cap, some with tiny carved windows and
> doors. The valley floor is where the balloons take off: 20–30 hot-air
> balloons in every phase (lying flat, half-inflated, lifting off, in the
> air below the cliff edge), in red, blue, yellow, white and striped. The
> underground city is **cut away** so it can be seen: a section of the
> plateau is removed like a slice of cake, revealing two big carved halls
> with columns and arches, torch-lit, and a huge hollow castle-rock with a spiral
> road inside it.
>
> **THE ROUTE — a single closed loop of about 2 km, counter-clockwise, the
> valley always on the right [!]:**
> 1. **Start/finish in the cave village square (plateau, top):** tuff paving,
>    three cone houses with doors, windows and a balcony carved into them,
>    a carpet terrace with cushions, one poplar tree, a white-painted
>    dovecote with pigeon holes. At the exit a **cart loaded with clay
>    pots** half blocks the road.
> 2. **The fairy-chimney forest [!]:** the road snakes tightly BETWEEN dense
>    cream cones 10–18 m tall with black basalt caps — some mushroom-shaped,
>    some triple — standing 2–4 m from the road; two twin chimneys lean
>    together and form a **gate** over the road; long shadows stripe the
>    road.
> 3. **The cliff cornice above the red valley [!] — the biggest feature:**
>    the road comes out onto the cliff edge with **no railing on the
>    right**; the cliff face below is banded rose-red-cream; on the valley
>    floor 30 m below dozens of balloons are inflating and lifting off, and
>    **three balloons are rising up the cliff face on tether cables, their
>    wicker baskets reaching road level** — one basket is right in the lane.
>    At the hairpin at the end of the cornice, **a tethered balloon sits
>    right next to the outside of the bend with its burner firing a big
>    flame**.
> 4. **The red canyon descent:** the road drops into a narrow canyon between
>    banded red cliffs; in the middle of the road stands a **cracked fairy
>    chimney that has toppled over and now lies as a rock ramp** — a car is
>    jumping off it over the bend; the long way round the fallen chimney is
>    still visible.
> 5. **The vineyard and the landed balloon (valley floor, bottom):** rows of
>    vines on wooden stakes, poplars, a small farmhouse; **a landed balloon
>    with its deflated striped envelope spread right across the road** and
>    its basket on the verge, tiny crew folding it.
> 6. **The underground city [!] (cut-away):** the road enters an arched cave
>    mouth with torches into a **big carved hall** (16 m ceiling, columns,
>    alcoves) lit by a shaft of daylight falling from a **ventilation
>    shaft** in the ceiling; in a narrow neck a **round millstone door 3 m
>    across** is rolling out of its slot to block the short passage, the
>    long passage beside it stays open; then a second hall with rock-church
>    arches and abstract frescoes.
> 7. **The hollow castle-rock [!] — the race gimmick:** from the second hall
>    the road climbs in a **spiral inside a huge hollow honeycombed rock**
>    (45 m tall, 70 m wide, cut away so the helix road is visible, 2 turns),
>    windows in the rock wall looking out over the balloon valley, and
>    **bursts out of the top on a jump ramp** back onto the plateau, landing
>    near the village.
>
> **Details that matter:** the road is pale dirt with tyre ruts on the
> plateau and in the valley, darker packed earth in the caves; red-and-white
> chevron posts only on the cornice bends; the valley is BELOW the road and
> the balloons are mostly BELOW the road level, with only the three tethered
> ones and the burner balloon reaching it; the elevation must read —
> plateau at the top, cornice, canyon, valley floor at the bottom, caves
> below that, and the hollow rock climbing back up; chimneys near the
> road are 10–18 m, the tall castle-rock and the volcano are far away.
>
> Background: the castle-rock of Uçhisar (a 60 m honeycombed rock with a
> village on its flanks) far on the plateau, the snow-capped cone of Mount
> Erciyes very far away in the haze, a few more balloons high up and far
> off.
>
> Toy cars: 4–6 chunky low-poly racing cars in saturated red, blue, yellow,
> white — one squeezing between chimneys, one drifting on the cornice with
> a basket rising beside it, one jumping off the fallen chimney, one inside
> the hollow rock spiral, one bursting out of the top.
>
> **PROP INVENTORY [!] — every item below must appear at least once, in its
> zone (this is the track's full asset list):**
> - *village square:* three cone houses, carpet terrace, poplar, dovecote,
>   pottery cart with pots, tuff paving.
> - *chimney forest:* cone chimneys with basalt caps (single, mushroom,
>   triple), the twin-chimney gate, a dovecote with pigeons bursting out.
> - *cornice:* banded cliff face, three tethered rising balloons with
>   baskets, the burner balloon at the hairpin, chevron posts, the valley
>   full of balloons below.
> - *canyon:* banded red cliffs, the toppled cracked chimney as a ramp,
>   rubble.
> - *valley floor:* vine rows on stakes, poplars, farmhouse, the landed
>   balloon with deflated envelope on the road, the basket, tiny crew.
> - *underground city:* arched cave mouth with torches, hall with columns
>   and alcoves, ventilation shaft with light column, millstone door and its
>   slot, rock-church arches with frescoes, torches.
> - *hollow rock:* the cut-away castle-rock with the spiral road, windows,
>   the exit ramp at the top.
> - *background:* Uçhisar castle rock, Mount Erciyes with snow, far
>   balloons.
>
> Colors: tuff cream #E8D9B8, tuff shadow #C9B48E, rose band #D9A08C, red
> band #B5573A, basalt cap #3A3532, cave dark #5A4636, **torch orange
> #F2A840 (emissive)**, dirt road #C9B28A, vine green #6E8A3C, poplar green
> #4F7A5A, balloon red #C8322B, balloon blue #2E5FA8, balloon yellow
> #E8B830, balloon white #F1EEE6, one striped balloon with pink #FF3FA4,
> sky horizon #F2B27A, sky top #B9CCE0.
>
> Deliver: (a) one wide 3/4 overview of the entire diorama matching the
> attached plan — plateau on the left/top, valley on the right, the
> cut-away underground city and hollow rock on the left; (b) one
> driver's-eye shot ON THE CORNICE — the banded cliff dropping away on the
> right, the balloon valley below, one basket rising into the lane ahead,
> the burner balloon at the hairpin; (c) one shot INSIDE the first
> underground hall from a low camera behind a car — the 16 m ceiling with
> columns, the shaft of daylight, torches, the millstone door rolling
> across the short passage ahead.

## 10. Prompt pentru inventarul de assets (ChatGPT) — v0.1, paste-ready

Toate assets-urile într-o singură foaie de referință, ca la Chongqing, cu
**numele de fișier scris sub fiecare piesă** — numele de pe foaie e
contractul cu `docs/asset_briefs/` și `tools/blender/build_*.py`. Varianta B
regenerează o singură piesă. Textul e și în artefactul „Cappadocia Recon",
cu buton de copiere.

```text
═══════════ VARIANTA A · FOAIA COMPLETĂ (toate assets-urile într-un singur fișier) ═══════════

Create a single tall REFERENCE SHEET of low-poly game assets for a sunrise racing track in Cappadocia, Turkey, in the same style as the attached low-poly diorama: faceted flat-shaded meshes, no fine surface texture, chunky tabletop-miniature proportions, soft baked ambient occlusion, muted cream-and-rose colors (~45% saturation), torches and burner flames as simple warm emissive shapes. Plain neutral grey background, assets organized in numbered titled panels, each panel with its own 1 m scale bar. EVERY panel and every piece inside a kit panel MUST carry a small caption with its exact file name written below it, e.g. "hollow_rock.glb", "chimney_a.glb" — these names are how we will identify the pieces. Captions and view labels (FRONT / SIDE / TOP / 3/4 / CUTAWAY) are the ONLY text allowed: no lettering on the objects themselves (frescoes are abstract shapes, no readable words).

1. hollow_rock.glb — HERO. A giant hollow castle-rock (like Uçhisar/Ortahisar), 45 m tall, 70 m wide at the base tapering to 30 m at the top, cream tuff honeycombed with small carved windows, a dark basalt cap; inside it a 6 m wide spiral road carved into the wall climbs 2 full turns (radius 28 m) from the floor to an opening at the top, exiting through the cap onto a short jump ramp; six rough windows through the wall at different heights; a 10 m arched entrance at the base. Views: exterior front, exterior side, top, and a CUTAWAY (half removed) showing the full spiral road. Use a car silhouette for scale.
2. underground_hall_kit (modular pieces, one panel, same scale): hall_column.glb (a 3 m thick carved tuff column, 16 m tall, rough and slightly tapered), hall_arch.glb (a 10 m wide, 12 m tall carved arch), hall_ceiling_module.glb (a 20×20 m slab of rough carved ceiling with tool marks), hall_alcove.glb (a 4 m wide carved storage alcove with clay jars), church_arch.glb (an 8 m rock-church arch with abstract fresco panels in ochre and red — no readable text), torch.glb (a 1 m wall torch on an iron bracket with a flame). Each piece labeled.
3. millstone_door.glb + millstone_slot.glb — a round tuff millstone door 3 m in diameter, 0.6 m thick, with a hole in the centre, shown in its slot (a carved recess in a wall that the stone rolls out of to block a 4 m passage). Show closed, half, open. Front, side, 3/4.
4. cracked_chimney.glb (three states, one panel) — a 16 m fairy chimney with a visible crack: (a) standing, (b) toppled and lying as a rock ramp about 20 m long rising 3 m, (c) a heap of rubble. Side and 3/4 for each.
5. balloon_kit (one panel, same scale): balloon_envelope_a.glb / _b.glb / _c.glb (three inflated hot-air balloon envelopes 12 m tall × 9 m wide — one plain, one with vertical panels of two colors, one with a horizontal striped band), balloon_basket.glb (a 2×2×1.2 m wicker basket with a burner frame and a visible burner flame above it), balloon_landed.glb (a deflated envelope spread flat and crumpled on the ground, 20 m long × 8 m wide, striped), balloon_tether.glb (a ground stake with a coiled cable). Each piece labeled.
6. twin_chimney_gate.glb — two fairy chimneys 15 m tall leaning together so their caps touch and form a gate with 12 m of clearance and an 8 m opening. Front, side, 3/4.
7. cave_entrance.glb — a 10 m wide, 12 m tall arched opening carved into a cliff face, with a stepped frame, two torches, a carved sun symbol above (abstract, no letters). Front, side, 3/4.
8. vent_shaft.glb — a vertical ventilation shaft: a 5 m diameter tube 20 m tall in cutaway, with a low carved rim at the top opening and a sand floor. Side cutaway, top.
9. TUFF KIT A — rock formations, one row, same scale, each piece labeled: chimney_a.glb / chimney_b.glb / chimney_c.glb / chimney_d.glb (single cream cones 10, 13, 16, 18 m tall with dark basalt caps — one with two tiny carved windows), chimney_mushroom.glb (a 12 m cone with a wide flat cap), chimney_triple.glb (three cones sharing one base, 14 m), cliff_band_module.glb (a 20 m long, 15 m tall slice of banded cliff — rose, red and cream layers, rounded top), rock_church_facade.glb (a 10 m cliff face with a carved church doorway and two windows).
10. TUFF KIT B — the cave village, one row, same scale, each piece labeled: cave_house_a.glb / cave_house_b.glb / cave_house_c.glb (inhabited cones 8, 10, 12 m tall with a wooden door, carved windows, one with a stair and a small balcony), dovecote.glb (a 6 m rock face with rows of pigeon holes and white-painted geometric marks), carpet_terrace.glb (a 6×4 m terrace with carpets, cushions and a low table), farmhouse.glb (a 10×6 m flat-roofed stone farmhouse with a wooden door), pottery_cart.glb (a 3 m wooden cart loaded with clay pots), pot_stack.glb (a 1.5 m stack of clay pots and amphorae).
11. VEGETATION KIT — one row, same scale, each piece labeled: poplar_a.glb / poplar_b.glb (slender poplar trees 12 and 16 m tall), vine_row.glb (a 10 m row of grape vines on wooden stakes, 1.5 m tall), shrub_dry.glb (a 1 m dry shrub), pigeon.glb (a single 0.3 m pigeon, for a flock).
12. BACKGROUND — one row: uchisar_castle.glb (a 60 m tall honeycombed rock castle with tiny carved windows and a village of small cube houses on its flanks — simple, it is only seen from 200 m), erciyes.glb (a very simple 3 km wide volcano silhouette with a snow cap, for the far horizon), balloon_far.glb (a very simple 8-sided balloon with basket, under 60 triangles, for a far crowd).
13. chevron_post.glb — reuse: 1.2 m post with red-and-white chevron plate (include for completeness).

═══════════ VARIANTA B · BLOCURI INDIVIDUALE (regenerare punctuală) ═══════════

STYLE HEADER — începe FIECARE prompt cu blocul ăsta:

Same low-poly flat-shaded style as the Cappadocia sunrise diorama reference (faceted meshes, no fine surface texture, chunky tabletop-miniature proportions, soft baked ambient occlusion, muted cream-and-rose colors ~45% saturation, torches and flames as simple warm emissive shapes). Turnaround sheet on a plain neutral grey background, no scene, no ground clutter: front view, side view, top view and one 3/4 view, all orthographic, same scale, with a 1 m scale bar. Show only this object. The only text allowed is the caption with the file name under the object.

──────────── 1 · hollow_rock.glb (primul: e gimmick-ul, interiorul e pistă) ────────────
Sheet of a giant hollow castle-rock, 45 m tall, 70 m wide at the base tapering to 30 m at the top, cream tuff honeycombed with small carved windows and a dark basalt cap; inside, a 6 m wide spiral road carved into the wall climbs 2 full turns (radius 28 m) from the floor to an opening at the top through the cap, ending in a short jump ramp; six rough windows through the wall at different heights; a 10 m arched entrance at the base. Add a CUTAWAY view with half the rock removed showing the whole spiral, with a small car for scale.

──────────── 2 · underground_hall_kit (o singură planșă, aceeași scară) ────────────
Sheet of a matched kit of carved-cave pieces lined up on one row, each labeled: hall_column.glb (3 m thick carved tuff column, 16 m tall, slightly tapered), hall_arch.glb (10 m wide, 12 m tall carved arch), hall_ceiling_module.glb (20×20 m slab of rough carved ceiling with tool marks), hall_alcove.glb (4 m carved storage alcove with clay jars), church_arch.glb (8 m rock-church arch with abstract ochre-and-red fresco panels, no text), torch.glb (1 m wall torch on an iron bracket with a flame).

──────────── 3 · millstone_door.glb + millstone_slot.glb ────────────
Sheet of a round tuff millstone door 3 m in diameter and 0.6 m thick with a central hole, in its carved wall slot, shown closed, half and open across a 4 m passage.

──────────── 4 · cracked_chimney.glb (trei stări) ────────────
Sheet of a 16 m fairy chimney with a visible crack in three states side by side: standing; toppled and lying as a rock ramp about 20 m long rising 3 m; a heap of rubble.

──────────── 5 · balloon_kit (o planșă) ────────────
Sheet of a matched hot-air balloon kit, same scale, each labeled: balloon_envelope_a/b/c.glb (three inflated envelopes 12 m tall × 9 m wide — plain, two-color vertical panels, horizontal striped band), balloon_basket.glb (2×2×1.2 m wicker basket with burner frame and a visible flame), balloon_landed.glb (deflated striped envelope crumpled flat on the ground, 20×8 m), balloon_tether.glb (ground stake with coiled cable).

──────────── 6 · twin_chimney_gate.glb · cave_entrance.glb · vent_shaft.glb (o planșă) ────────────
Sheet with three pieces, same scale, each labeled: two 15 m fairy chimneys leaning together with caps touching, 12 m clearance, 8 m opening; a 10 m wide, 12 m tall arched cave opening in a cliff face with a stepped frame, two torches and an abstract carved sun above; a 5 m diameter, 20 m tall ventilation shaft in cutaway with a carved rim at the top and a sand floor.

──────────── 7 · tuff kit A (formațiuni, o planșă) ────────────
Sheet of a matched kit lined up on one row, same scale, each labeled: chimney_a/b/c/d.glb (single cream cones 10, 13, 16, 18 m with dark basalt caps, one with two tiny carved windows), chimney_mushroom.glb (12 m cone with a wide flat cap), chimney_triple.glb (three cones on one base, 14 m), cliff_band_module.glb (20 m long, 15 m tall slice of banded cliff — rose, red, cream — rounded top), rock_church_facade.glb (10 m cliff face with a carved church doorway and two windows).

──────────── 8 · tuff kit B (satul, o planșă) ────────────
Sheet of a matched kit lined up on one row, same scale, each labeled: cave_house_a/b/c.glb (inhabited cones 8, 10, 12 m with wooden door, carved windows, one with a stair and balcony), dovecote.glb (6 m rock face with rows of pigeon holes and white geometric marks), carpet_terrace.glb (6×4 m terrace with carpets, cushions, low table), farmhouse.glb (10×6 m flat-roofed stone farmhouse), pottery_cart.glb (3 m wooden cart loaded with clay pots), pot_stack.glb (1.5 m stack of clay pots and amphorae).

──────────── 9 · vegetation kit + background (o planșă) ────────────
Sheet of two rows, same scale, each labeled. Row 1: poplar_a/b.glb (slender poplars 12 and 16 m), vine_row.glb (10 m row of vines on stakes, 1.5 m), shrub_dry.glb (1 m dry shrub), pigeon.glb (0.3 m pigeon). Row 2 (own scale bar): uchisar_castle.glb (60 m honeycombed rock castle with tiny windows and small cube houses on its flanks — simple), erciyes.glb (very simple volcano silhouette with snow cap), balloon_far.glb (8-sided balloon with basket, under 60 triangles).
```

## Istoric

- **v0.1 (30 aug 2026):** concept extern integrat — trei acte, hornul-rampă,
  pânza aterizată, suflul arzătorului, rampa din stânca goală; baloanele
  întoarse „de jos în sus" după frustum; respinse porumbei/oi/olărie/vânt.
- **v0 (30 aug 2026):** concept, ales dintre trei propuneri (Chuquicamata /
  Cappadocia / Tonlé Sap) — dezvoltatorul a ales subteranul + baloanele,
  după verificarea că tavanul se vede cu un preset de cameră, nu cu vederea
  șoferului.
