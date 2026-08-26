# Track brief — Chongqing (`Track12`, temă `chongqing`) — v0.1 (concept)

> Concept de pistă, înaintea listei de assets. Scheletul e cel din
> `stromboli.md`; secțiunile de assets (§5) sunt schițate, nu complete —
> se detaliază după ce traseul trece de ProbeLayout și de captura `--driver`.
> Prima pistă **urbană**, prima **de noapte**, prima cu **pista peste pistă**.
>
> **v0.1 (26 aug 2026):** integrat un concept extern (ChatGPT) — a schimbat
> regula de artă (§0.1), a adus pasajul rotativ, macaraua, nodul de trafic,
> culoarul de ceață și saltul peste scări; a fost respins acolo unde
> contrazicea frustumul camerei (§2.0) sau contractul de hazard ciclic.

## 0. Într-o propoziție

Noapte cu burniță în Chongqing, „orașul de ceață" de pe stânci, unde ieși
dintr-o piață și afli că ești la etajul 22: pornești de pe platoul de sus,
te prăbușești pe **scările Shibati** printre hamali, te strecori prin
**aleea cu hot-pot** în aburi și lampioane, ieși pe **cornișa de deasupra
lui Hongya Dong** — orașul-pe-piloni luminat auriu **sub tine**, iar și mai jos
cele două râuri de culori diferite — cobori pe **cheiul Chaotianmen**, apoi
**urci în spirală pe nodul rutier cu cinci etaje** (drumul trece peste el
însuși, sari de pe rampa de sus peste cea de jos), și închizi turul
**printr-un bloc de locuințe prin care trece monorailul**. Singura pistă din
joc în care lumea de dedesubt e făcută de oameni, nu de geologie.

## 0.1 Regula de artă (ce NU e pista asta)

**Nu „cyberpunk chinezesc". Un oraș construit peste el însuși.** Ce trebuie
să recunoască jucătorul în 3 secunde nu e neonul, ci: *„de ce e un drum sub
mine, un tren trece prin blocul ăla și râul e la 40 m mai jos?"*
Verticalitatea e pentru Chongqing ce e vulcanul pentru Stromboli: nu decor,
ci limbajul spațial al întregii piste.

| pondere | strat |
|---|---|
| **70%** | oraș-pe-munte + infrastructură: beton, piloni, rampe, pasaje, poduri, macarale, scări |
| **15%** | arhitectură tradițională: Hongya Dong, acoperișuri curbate, lampioane, hot-pot |
| **10%** | ceață / atmosferă / burniță |
| **5%** | neon — accent, nu identitate |

Paleta de noapte: gri de beton, albastru-gri întunecat, verde stins, portocaliu
cald, roșu de firme, galben de lămpi stradale, cyan rar. Luminile sunt forme
emisive simple, nu texturi detaliate.

## 1. De ce Chongqing (referința reală, ce luăm din ea)

| loc real | ce luăm |
|---|---|
| **Orașul pe stânci** (Yuzhong, între Jialing și Yangtze) | contractul de design: **verticalitate construită**. Nu vezi niciodată tot orașul; îl descoperi pe etaje, în jos |
| **Kuixinglou** — piața al cărei „parter" e etajul 22 al blocului de sub ea | POI de start: ieși din piață și sub tine e gol. Prima frică de cădere a turului |
| **Shibati (Cele 18 trepte)** — strada-scară veche | coborârea rapidă: trepte late = suprafață denivelată cu airtime mărunt; hamali „bang-bang" cu prăjini care se feresc |
| **Hongya Dong** — 11 etaje de case pe piloni agățate de faleză, luminate auriu noaptea | **hero-ul vizual**. Se vede de SUS, de pe cornișă, în timpul coborârii — exact ce vede camera (63° în jos) |
| **Chaotianmen** — confluența: Jialing verde, Yangtze maroniu, o linie clară între ele | „ceva jos, în adânc" al pistei: **apă în două culori**, vizibilă de pe cornișă și traversată pe pod |
| **Huangjuewan** — nodul rutier cu 5 etaje și 20 de rampe | **urcarea care dezvăluie** + pista peste pistă. Rampele spiralează, la fiecare etaj vezi mai mult din oraș sub tine |
| **Liziba** — stația de monorail din interiorul unui bloc de 19 etaje | hazard-semnătură: intri în bloc, trenul taie drumul |
| **Telecabina peste Yangtze** | scurtătura: cabina te trece peste golf și te scutește de o parte din urcare — dacă o prinzi |
| **Aleile cu hot-pot**, lampioane roșii, aburi din bucătării | respiro tehnic strâmt; aburii = clasa „fumarolă", cost zero |
| **„Orașul de ceață"** (雾都) și burnița | ceața motorului devine temă: `fog_end` mic e *corect* aici. Ploaia e ciclu de grip |

Culorile locului: beton ud și gri-albastru, **auriu de Hongya Dong**, roșu
de lampioane, neon roz-magenta (singurul slot nou), verde/maro al celor două
râuri, cer de noapte gri-violaceu din ceață luminată de jos. Lumina: noapte —
o direcțională slabă, rece, de sus (luna prin ceață), **fără umbre**
(vezi §4).

## 2.0 Verificarea cu camera (de ce orașul e SUB drum, nu lângă el)

`ChaseCamera` vede **~5° deasupra orizontalei, ~63° sub ea**: la distanța
orizontală `d` vezi în sus cel mult `10 + 0.093·d` metri.

- **Un zgârie-nori de 100 m lângă drum e invizibil** — vezi un perete de
  fațadă de 12–15 m și atât. Deci NU se construiește orașul „în sus" pe
  lângă traseu; fațadele de lângă drum sunt pereți de coridor (2–4 etaje),
  cu detaliul în textura de clasă, nu în geometrie.
- **Tot ce e impresionant stă sub jucător:** Hongya Dong agățat sub cornișă,
  râurile, rampele inferioare ale nodului, cheiul. Turnurile există doar ca
  **siluete peste râu**, la 150–250 m, cu ferestre aprinse, sub `fog_end`.
- **Ceața ajută, nu încurcă:** Chongqing chiar așa arată. `fog_end` ~250 m,
  ceață gri-violacee luminată — turnurile de peste râu se sting în ea firesc.

- **„Trei drumuri deasupra mea" nu se poate vedea** — la 30 m distanță vezi
  cel mult 13 m înălțime. Un drum de deasupra se citește doar prin **piloni**
  și prin **burta pasajului** când treci pe sub el (un tavan scurt, umbrit,
  cu lămpi). Deci senzația de stivă se construiește **de sus în jos**: drumul
  pe care ai fost e sub tine, vizibil; cel pe care vei fi e anunțat de piloni
  și de tavanul de 2 secunde. Același motiv pentru care **pilonii înalți ai
  podului nu primesc geometrie** — nu-i vezi niciodată de pe carosabil.

Consecința: **orașul nu se arată, se coboară prin el** — apoi se recâștigă
pe spirală, etaj cu etaj.

## 2. Traseul și punctele de interes (POI)

Lungime țintă **~2.0 km** (tur ~60 s, 3 tururi ≈ 3:00). Sens: orar — golful
și râurile pe dreapta pe cornișă și pe chei. Cota maximă **~65 m** (platoul),
minimă **~5 m** (cheiul). Coborâre totală ~60 m pe 40% din tur, urcare ~60 m
pe 30% din tur — **pantele se măsoară cu ProbeLayout înaintea oricărui decor**
(media urcării pe spirală sub 13%, vârf sub 16%, precedent Baikal 15.4%).

```
   [A] START Kuixinglou (65 m) ── [G] Liziba: bloc + monorail (50→65 m)
        |                                     |
   [B] scările Shibati (65→35 m)      [F] nodul Huangjuewan (5→50 m)
        |                              spirală, pista peste pistă, kicker
   [C] aleea hot-pot (35 m)                   |
        |                              [E′] telecabina (scurtătură peste golf)
   [D] cornișa Hongya Dong (35→10 m)          |
        \___ [E] cheiul Chaotianmen (5 m) ── podul peste golf ___/
```

| # | frac | POI | ce se întâmplă | lățime |
|---|---|---|---|---|
| **A** | 0.00 | **Start în piața Kuixinglou** — dale de granit ude, o pagodă-chioșc, bănci, stâlpi cu lampioane; parapetul din capătul pieței dă spre **gol**: sub el, 22 de etaje de bloc și orașul. La ieșire, **nodul de trafic**: bulevardul e blocat de mașinuțe și autobuze, cu **o singură fantă** de 3 m între două autobuze | grilă pe piață; ieșirea spre B trece pe LÂNGĂ parapet — prima privire în jos; fanta e decor static cu coliziune (cost zero, foarte Ignition) — o ratezi → bumping pe autobuz | 9 m |
| **B** | 0.04–0.14 | **Coborârea Shibati** — drumul coboară în S pe lângă **scara uriașă**: trepte late, magazine vechi cu obloane, rufe pe sârme, **hamali cu prăjini** și pietoni mărunți pe scară, sub tine. La jumătate, **rampa peste scări**: un kicker te aruncă în diagonală PESTE scară, tăind un S întreg al drumului (câștig ~3 s; aterizare pe palier, ratezi → ești pe trepte, tremur + grip 0.8× până revii) | scurtătura nr. 1; scara e suprafață în trepte ≤ 15 cm (sub raza roții), drumul e asfalt; pietonii sunt figuranți SUB linia camerei — exact unde vede | 8 m |
| **C** | 0.16–0.24 | **Aleea hot-pot** — coridor strâmt între restaurante, lampioane roșii, mese pe trotuar, **aburi din bucătării** peste drum, un scuter parcat | strângere tehnică 6 m; aburii albesc ecranul ~0.5 s (clasa fumarolă) | 6 m |
| **D** | 0.26–0.44 | **Cornișa Hongya Dong** — drumul iese pe buza falezei, **fără parapet pe dreapta**: sub tine, etajele de case pe piloni luminate auriu, acoperișuri curbate, apoi cheiul și **confluența în două culori**. Coborâre în S larg pe cornișă | **vârful emoțional al turului.** Cădere = repunere ~2 s; parapet doar pe exteriorul unui viraj (punctuație). Ploaia ciclică se citește cel mai bine aici (reflexii aurii pe asfalt ud) | 7 m |
| **E** | 0.46–0.58 | **Cheiul Chaotianmen** — drept lung la nivelul apei: dană, containere, o navă cargo care trece pe sub pod, stația de jos a telecabinei; apoi **culoarul de ceață** (60–80 m: vezi doar stopuri, firme și marcaje) din care ieși direct pe **podul peste golf** — orașul se deschide sub tine dintr-o dată | fâșia de viteză a turului; apa pe dreapta, fără parapet pe chei. **Sirena de ceață** anunță nava: siajul ei **inundă cheiul jos** (val peste drum, grip scade 2 s — `WaveSurge`). **Bifurcație**: podul (ocol, ~220 m, plat) sau telecabina (E′). De pe pod se văd: nava, cheiul, rampele de jos ale nodului, Hongya Dong în spate | 9 m |
| **E′** | 0.50 | **Telecabina** — platforma-cabină pleacă din stația de jos la interval fix (~20 s), traversează golful în 8 s și te lasă la **etajul 2 al nodului F** — sari peste podul + primul etaj al spiralei (câștig ~4–5 s). Dacă ratezi fereastra de ~3 s de îmbarcare, cabina e plecată → mergi pe pod | risk/reward pe **timing vizibil**: cabina se vede venind pe cablu, jos, de pe cornișa D. AI-ul o ia doar dacă ajunge în fereastră | cabină 5×4 m |
| **F** | 0.60–0.82 | **Nodul Huangjuewan** — spirală de rampe pe piloni: 3 etaje, urcare 5 → 50 m, drumul trece **peste el însuși** de două ori; la etajul 2 o **rampă de lansare** (kicker scurt) te aruncă peste rampa de la etajul 1 pe rampa de la etajul 3 (scurtătura a doua a turului, cu aterizare de precizie — ratezi → cazi pe etajul 1 și refaci o buclă). Pe etajul 3, **pasajul în construcție**: un tronson de 12 m **se rotește** pe ciclu (~25 s) între „deschis" (continuă rampa) și „închis" (te trimite pe rampa de serviciu, +3 s). Deasupra, **macaraua** leagănă un prefabricat peste rampă. **Dezvăluirea**: la fiecare etaj vezi mai mult din chei, râuri, Hongya Dong; când treci pe sub un etaj, vezi burta lui ca tavan scurt și pilonii | urcare ~13%; parapet de beton pe exterior (ăsta e un pod, nu o faleză), pe interior **gol** spre etajele de jos; chevroane pe curbele oarbe. Pasajul rotativ = `LiftBridgeHazard` (Okinawa) în altă haină; macaraua = braț rotitor (`CarouselHazard`), contact = te învârte, nu te distruge | 7 m |
| **G** | 0.84–0.96 | **Liziba** — drumul intră **în bloc** (nivelul 8 e „parterul" nostru): hol lung cu stâlpi, cutii poștale, biciclete; la mijloc **monorailul taie holul** pe o traversare la nivel, cu barieră și clopoțel; ieșirea pe o pasarelă spre piață | hazard mobil pe orar (~35 s, ≠ tur): tren de 3 vagoane, 60 km/h, telegraph 3 s (clopoțel + lumini + bariera coboară). Contact = ești aruncat (masă mare), nu distrus | 7 m |
| **A′** | 1.00 | pasarelă → piață, sosire pe lângă parapet | | 9 m |

**Ritmul turului:** piață (respiro + privire în gol) → scări (viteză + tremur)
→ alee (strângere + aburi) → cornișă (vârful vizual + frica de cădere + ploaie)
→ chei (viteză, decizia telecabinei) → spirală (urcare tehnică, dezvăluire,
saltul peste pistă) → bloc + monorail (presiune de timing) → piață.

**Ceasuri care nu împart durata turului** (lecția Stromboli): telecabina
~20 s, pasajul rotativ ~25 s, monorailul ~35 s, nava ~40 s, ploaia ~50 s.
Faza fiecăruia se mută de la tur la tur. Regula: **fiecare hazard e ciclic și
învățabil** — set piece-uri unice („drumul își schimbă nivelul o dată pe
cursă") nu intră: nu se învață și costă cât o pistă.

## 3. Hazarduri și mecanici (ce e nou pentru motor)

| mecanică | pe scurt | ce cere în cod |
|---|---|---|
| **Pista peste pistă** (F, kickerul) | drumul se suprapune pe verticală de două ori + un salt de pe un etaj pe altul | **riscul nr. 1** — vezi §7.1: NU e (doar) `closest_index_global` (ăla e deja 3D); sunt trei lucruri: terenul, testul „pe șosea" și fereastra de index. Se repară ÎNAINTE de desenul pistei, cu sondă |
| **Monorailul prin bloc** (G) | tren pe orar ~35 s, taie drumul la nivel, telegraph 3 s | reuse `TrainHazard` (traseu Path3D, orar, masă); nou: barieră animată + clopoțel + faruri. Bariera e teatru, nu coliziune (pedeapsa e trenul) |
| **Telecabina** (E′) | platformă care pleacă la interval, transportă mașina 8 s peste golf, o lasă la etajul 2 | **riscul nr. 2** — mașină în repaus pe corp mobil (memoria `coliziune-contact-si-platforma`: platforma = capcane cunoscute; Jolt + `sync_to_physics` scrie transformul întreg). Sondă separată înainte de brief-ul v1. **Fallback** dacă nu ține: cabinele devin obstacole mobile care coboară peste chei (traversează drumul la 1.5 m — treci doar pe sub / între ele) |
| **Ploaia ciclică** | rafală ~15 s la ~50 s: asfalt ud (grip 0.85×), picături pe ecran, sunet; apoi se zvântă | metronom global ca `EruptionCycle` + suprafață pe interval (există) comutată de ciclu; particule cu count mic. **Reflexiile** = trucul ieftin: asfaltul ud e o clasă de textură mai închisă + specular, nu screen-space |
| **Pasajul rotativ** (F) | tronson de 12 m care se rotește pe ciclu ~25 s; închis → rampa de serviciu (+3 s) | reuse `LiftBridgeHazard` (Okinawa) cu rotație în loc de ridicare; semafor de șantier ca telegraph |
| **Macaraua** (F) | braț care leagănă un prefabricat peste rampa de sus; contact = învârtit, nu distrus | reuse `CarouselHazard` / `ExcavatorHazard` (braț rotitor cu masă); doar mesh nou |
| **Culoarul de ceață** (E) | 60–80 m în care vezi doar emisive (stopuri, firme, marcaje); ieșire bruscă pe pod | generalizarea clasei „albire" a fumarolei: `Area3D` + rampă de densitate/culoare a ceții, fără volumetrie; marcajele drumului devin emisive slab |
| **Siajul navei** (E) | sirenă (telegraph 3 s) → nava trece pe sub pod → val peste cheiul jos, grip 0.7× timp de 2 s | reuse `WaveSurge` + un vehicul pe `Path3D` (nava) |
| **Nodul de trafic** (A) | bulevard blocat, o fantă de 3 m între două autobuze | decor static cu coliziune (`world_prop`), zero cod |
| **Saltul peste scări** (B) | kicker care taie un S al drumului peste scara uriașă; ratezi → pe trepte, grip 0.8× | reuse `FlyoffKicker`; scara = teren în trepte ≤ 15 cm |
| **Aburii din bucătării** (C) | albire ~0.5 s + sunet | reuse `FumaroleHazard`, zero cod |
| **Hamalii** (B) | figuranți care se feresc la apropiere | reuse măgarul din Stromboli (`donkey` → `porter`) |
| **Golul de pe cornișă / chei / interiorul spiralei** | repunere ~2 s | `custom_ravines` + `RespawnZone` (există) — DAR repunerea sub pod e exact cazul de la riscul nr. 1 |
| **Bifurcația pod ↔ telecabină** | ocol real, nu bandă paralelă; câștig 4–5 s | `TrackBranch` există; nou: ramura condiționată de fereastra cabinei, AI care decide pe timp |

Calibrare (sisteme.md): cădere ≈ 2 s ≈ 2 poziții; telecabina prinsă ≈ +4–5 s;
saltul reușit peste etaj ≈ +3 s, ratat ≈ −4 s.

## 4. Paleta, lumina și noaptea (un singur slot nou — ultimul)

**Slot 31** (ultimul liber): `NEON_PINK` `#FF3FA4` — firme, tuburi, reflexia
lor în asfalt ud. Accent, sub 1% din pixeli. Restul e reutilizat:

| rol | slot existent |
|---|---|
| beton ud, piloni, rampe | `CONCRETE` 8, `MARBLE_GREY` 29 |
| asfalt, asfalt ud | `ASPHALT` 5 / `ASPHALT_EDGE` 6 (udul e textura de clasă, nu slot) |
| geam, sticlă de noapte, cer | `ICE_DEEP` 25, `ICE_TURQUOISE` 24 |
| **auriul lui Hongya Dong**, lămpi cu sodiu, ferestre aprinse | `LAVA_ORANGE` 30 (emisivul din Stromboli, refolosit ca lumină caldă) |
| lampioane, bariere, chevroane | `CAR_RED` 14, `KERB_RED` 7 |
| acoperișuri curbate, olane | `TILE_TERRACOTTA` 23 |
| lemnăria caselor pe piloni | `LOG_DARK` 28, `WOOD_WEATHERED` 9 |
| monorail, cabină, containere | `PAINTED_METAL` 11, `RUST_METAL` 10 |
| Jialing / Yangtze | `TROPICAL_GREEN` 21 întunecat / `SAND_SHADOW` 2 (maroniu) |

**Noaptea e o decizie de performanță, nu doar de atmosferă:**
- o singură direcțională, slabă (~0.35), rece, aproape verticală — luna prin
  ceață; ambient ridicat, gri-violaceu. **`theme_shadows = false`** — noaptea
  nu are umbre citibile, deci prima pistă care scapă complet de cascada de
  umbre (cel mai scump lucru pe mobil). Contactul cu solul, pe care umbrele
  îl dădeau, vine aici din **AO în vertex colors + ferestrele aprinse**.
- **UN material emisiv de clasă partajat** (`neon_emissive`, pe modelul
  shaderului de lavă: culoarea din poziția în spațiul obiectului, fără UV) —
  firme, lampioane, faruri de monorail, tuburile telecabinei. Nu per asset.
- **Ferestrele aprinse sunt în textura de clasă** (`facade_night`, triplanar,
  cu grilă de ferestre 30% aprinse, calde) — exact lecția din style_bible §4:
  detaliul pictat, nu geometria. O clasă pentru toate blocurile, siluetele
  de peste râu inclusiv.
- **Fără post-procesare**: bloom-ul lipsește, deci emisivul se saturează
  vizual prin contrast cu ambientul întunecat, nu prin glow. Halo-uri pe
  lampioane = un quad billboard cu alpha, dacă e nevoie, cu count limitat.

## 5. Assets (schiță — lista completă după ProbeLayout)

### 5.1 Teren și suprafețe (cod, clase de textură)
`concrete_wet` (rampe, chei), `asphalt_wet` (comutat de ploaie), `granite_tiles`
(piața), `stone_stairs` (Shibati — treptele sunt geometrie, textura dă uzura),
`facade_night` (toate fațadele), decal `puddle` (bălți statice cu reflexie
falsă a neonului), `neon_emissive` (clasă emisivă partajată).

### 5.2 Hero (unice)
| asset | note |
|---|---|
| `hongya_dong.glb` | 11 etaje de case pe piloni în trepte pe faleză, ~60×25×45 m, acoperișuri curbate, ferestre aprinse (clasă) — **se vede doar de sus și din lateral**, deci detaliu pe acoperișuri și pe fațada spre râu, nimic pe spate |
| `liziba_block.glb` | blocul traversat: hol interior 7 m lățime × 90 m + fațada de intrare/ieșire; monorailul intră pe o latură |
| `monorail_train.glb` | 3 vagoane, ~9 m fiecare, faruri emisive |
| `cableway_cabin.glb` + `cableway_towers.glb` | cabină-platformă 5×4 m; două turnuri + cablu |
| `interchange_kit` (modular) | rampă dreaptă 10 m, arc 15°, pilon, parapet, rampă-kicker |
| `cruise_ship.glb` | navă luminată la chei, 60 m, fundal-erou al lui E |
| `kuixinglou_pavilion.glb` | chioșcul-pagodă din piață |

### 5.3 Kit urban (modular, statistice)
lampion (3 variante), stâlp cu firmă neon (4), masă+scaune de restaurant,
scuter, obloane de magazin, rufe pe sârmă, cutii poștale, biciclete, container
(există `PAINTED_METAL`), bolard, jardinieră, hamal (figurant, reuse rig).

### 5.4 Fundal (`horizon_class`)
turnuri-siluetă cu `facade_night` la 150–250 m peste râu (sub `fog_end` 250),
podul Qiansimen ca siluetă, planul de apă în două culori (reuse plan Okinawa,
cu linia de confluență în shader), ceață luminată de jos.

### 5.5 Sunet
clopoțelul barierei (telegraph), monorailul pe grindă, ploaia pe tablă,
claxoane departe, sfârâitul hot-pot-ului, hamalii strigând, cablul telecabinei.

## 6. Bugete

- triunghiuri: sub **400k**; nodul rutier și Hongya Dong sunt cele două
  piese grele — se măsoară pe piesă înainte de plantare
- materiale: atlas + ~6 clase (§5.1) + emisiv + decal-uri → țintă **≤ 22**
  (Stromboli a ajuns la 28; aici pornim mai jos pentru că noaptea mută
  detaliul în 2 texturi de fațadă)
- **umbre stinse** (câștigul net al nopții) — bugetul recuperat se cheltuie
  pe emisiv și pe particulele de ploaie
- **de verificat devreme:** repunerea sub pod (riscul 1), platforma mobilă
  (riscul 2), captura `--driver` de pe cornișa D — se vede Hongya Dong? se
  vede confluența? sau se vede ceață?

## 7. Ordinea de construcție

1. **Sonde tehnice înaintea traseului:** (a) pista suprapusă (§7.1) cu o
   pistă-test în care drumul trece peste el însuși; (b) mașina pe platformă
   mobilă pe Jolt (telecabina). Dacă (b) pică, telecabina devine obstacol
   mobil — briefingul v1 se scrie știind asta.

### 7.1 Pista peste pistă — ce e de fapt de reparat (citit în cod, 26 aug)

Nota din `world_design.md §3` dă vina pe cele trei apeluri
`closest_index_global`. Citit în cod, **ăla e deja 3D**
(`TrackRoute.closest_index_global` compară `distance_squared_to` pe XYZ), deci
la spawn/repunere alege etajul corect. Problemele reale sunt în altă parte:

1. **Terenul urmărește drumul printr-o medie 2D.** `TrackSideSampler.ground_y`
   face media ponderată a cotelor punctelor coapte din raza `GROUND_ROAD_RADIUS`,
   după distanța în XZ. La o încrucișare suprapusă (etaj 1 la 5 m, etaj 3 la
   35 m) terenul se așază **la media lor** — îngroapă etajul de jos și lasă în
   aer pe cel de sus. `custom_viaduct_ravines` nu ajută: viaductul sapă o râpă
   și sub drum, deci ar săpa și sub etajul de jos.
   **Cere:** un tip nou de tronson, **pasaj pe piloni** (`custom_overpass_ranges`
   sau similar): punctele din interval sunt **excluse** din tragerea terenului
   (weight 0 în `ground_y`), tablierul primește fusta de beton + parapet
   (există: `deck_sides` din `_bridge_mix`), fără umeri de pietriș, iar pilonii
   vin din kit (DecorManual). Terenul urmează astfel doar etajul de jos.
2. **„Pe șosea" e un test 2D.** `TrackRoute.lateral_distance`/`is_on_road`
   compară doar XZ. O mașină căzută de pe etajul 3 pe etajul 1, care încă ține
   indexul etajului 3, e „pe șosea" (își reînnoiește `last_safe_index` pe
   etajul de SUS — repunerea ulterioară ar fi un câștig gratuit).
   **Cere:** toleranță verticală în `is_on_road` (|Δy| peste ~6 m = nu ești pe
   banda aia). Pragul se derivă din săritura maximă a kickerelor (mașina în aer
   deasupra drumului trebuie să rămână „pe șosea"), iar **separarea minimă
   între etaje** devine o regulă de desen: > 2× toleranța, adică ≥ 12–15 m.
3. **Fereastra de index nu vede alt etaj.** `closest_index` caută ±8/+24 de
   puncte (~72 m de-a lungul rutei). După o cădere pe etajul de jos (sau după
   saltul reușit 2→3, care e la ~150 m de rută în față), indexul rămâne agățat
   și fracția de tur îngheață.
   **Cere:** la **aterizare** (`landed`, sau primul cadru cu `is_on_floor`
   după aer), dacă |Δy| față de punctul indexului curent depășește toleranța,
   o **rescanare globală o singură dată** (3D, deci alege etajul corect). Asta
   e exact mecanismul de la comutarea rutelor (`resolve_route` scanează global
   o dată per comutare), extins la etaje. Progresul din `race.gd` (delta de
   fracție cu wrap la ±0.5) încasează saltul înainte ca progres — corect pentru
   kickerul proiectat — și căderea ca regres.

**Sonda:** `ProbeOverpass` — pistă-test din `TrackFromPath` cu un tronson pe
piloni care trece la 15 m peste o secțiune anterioară; trei scenarii tipărite:
(i) tur curat pe ambele etaje (terenul nu ridică/îngroapă niciunul, cotele
roților vs. cota drumului); (ii) cădere de pe etajul de sus → indexul se mută
pe etajul de jos în ≤ 1 s de la aterizare, `last_safe_index` NU rămâne sus;
(iii) repunere sub pasaj → mașina apare pe etajul pe care a căzut, nu pe cel
de deasupra.
2. `Track12.tscn` din `TrackFromPath`, temă `chongqing` (noapte, fog 250,
   umbre stinse), traseul din §2 cu spirala și bifurcația. ProbeLayout pe pante.
3. Sonda de feel: scări → cornișă → chei → spirală, un tur singur.
   **Captura `--driver` de pe D.** Dacă orașul de sub tine nu se citește, se
   reface aici.
4. Monorailul (reuse tren) + bariera; ploaia ciclică + asfaltul ud.
5. Telecabina (sau fallback-ul) + AI-ul care decide pe fereastră; ProbeRace
   A/B pe distribuții.
6. Hero-assets: Hongya Dong, blocul Liziba, kit nod, cabina, nava.
7. Kit urban, siluete, figuranți; probe_decor, verdict la volan.

## 8. Lecții aplicate anticipat

- **Frustumul decide:** orașul stă SUB drum; nimic mai înalt de 4 etaje
  lângă carosabil, turnurile doar peste râu ca siluete (§2.0).
- **Vizibilitatea pierdută se plătește cu semnalizare**: curbele oarbe ale
  spiralei și intrarea în bloc primesc chevroane/semafoare în același pachet.
- **Adâncimea se citește prin proximitate**: Hongya Dong începe la 5 m sub
  buza cornișei, nu la 50; râurile la ~30 m sub cornișă, în interiorul ceții.
- **Pista peste pistă e cod, nu doar desen** — și nu cel bănuit: terenul,
  testul 2D „pe șosea" și fereastra de index (§7.1), nu scanarea globală.
- **Margini fără parapet tăiate în pantă**, trepte ≤ 15 cm, raze de spirală
  > half_width cu puncte pe arc.
- **Un singur emisiv de clasă; ferestrele în textură.** Garda numără
  materialele — noaptea nu e scuză pentru un material per firmă.
- **Respins din conceptul extern, cu motiv:** liftul (aceeași platformă
  mobilă ca telecabina, fără decizia de timing — dacă sonda pică, pică
  amândouă; dacă trece, telecabina aduce mai mult), „drumul își schimbă
  nivelul o dată pe cursă" (set piece unic, nu ciclic — nu se învață),
  startul printre zgârie-nori (invizibili de la 5° în sus — sunt siluete
  peste râu), pilonii înalți ai podurilor (idem).
- **Ultimul slot de paletă se consumă aici.** Următoarea pistă după Chongqing
  nu mai are slot nou — sau paleta trece la 64 (decizie separată, cu
  regenerarea atlasului).

## Istoric

- **v0.1 (26 aug 2026):** concept extern integrat — regula 70/15/10/5,
  pasaj rotativ, macara, nod de trafic, culoar de ceață, salt peste scări,
  siajul navei; respinse liftul și set piece-ul unic.
- **v0 (26 aug 2026):** concept, ales dintre trei propuneri (Chongqing /
  Tonlé Sap / Cappadocia) — dezvoltatorul a ales verticalitatea urbană.
