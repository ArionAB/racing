# Track brief — Stromboli (`Track11`, temă `stromboli`)

> Concept de pistă + lista completă de assets. Secțiunea finală e un prompt
> paste-ready pentru generarea unei diorame de referință (ChatGPT / imagine),
> din care apoi se scriu brief-urile individuale de asset în `docs/asset_briefs/`
> și scripturile `tools/blender/build_*.py`. Harta interactivă cu loturile de
> assets la scară: `img/stromboli_map.html` (artefactul „Stromboli Recon").

## 0. Într-o propoziție

Sfârșit de după-amiază pe insula Stromboli, „farul Mediteranei": sat eolian
alb, plajă de nisip negru, urcuș prin viță și smochini până sub **Sciara del
Fuoco** — iar vulcanul erupe **ciclic, la fix**, aruncând bombe incandescente
peste traversare și împingând, tur după tur, o **limbă de lavă** care închide
progresiv ruta scurtă. E singura pistă din joc al cărei traseu optim **se
schimbă în timpul cursei**: turul 3 e altă problemă decât turul 1.

## 1. De ce Stromboli (referința reală, ce luăm din ea)

| loc real | ce luăm |
|---|---|
| **Erupțiile stromboliene** (la 10–20 min, de ~2000 de ani) | contractul de design: hazard **ciclic, previzibil, învățabil** — exact gramatica hazardelor noastre. Perioada în joc: ~45 s, sub durata turului, ca faza să se mute de la tur la tur |
| **Sciara del Fuoco** | „alunecarea de foc" — versantul-canal pe care materialul incandescent se rostogolește din crater în mare; culoarul de hazard e desenat de natură |
| **Satul San Vincenzo** | case cubice albe eoliene cu terase și pergole (pulèra), biserica albă cu campanil, ulițe înguste, Ape Piaggio în loc de mașini |
| **Plajele de nisip negru** (Piscità, Ficogrande) | fâșie de coastă neagră cu bărci de pescari trase pe mal; nisipul adânc de lângă linie = pedeapsa de frecare |
| **Ginostra** | cătunul de pe flancul opus, „cel mai mic port din lume" — respiro tehnic, alb pe negru |
| **Terasele de malvasia** | ziduri de piatră neagră (muretti a secco), rânduri de viță joasă — urcarea care dezvăluie |
| **Strombolicchio** | neck vulcanic în mare cu far în vârf — silueta-semnătură a fundalului, trasă în interiorul lui `fog_end` |
| **Vegetația mediteraneană** | măslini, smochini, opuntia (limba-soacrei), capere, ginestre — verde prăfuit pe negru |
| **Observatorul de la Punta Labronzo** | terasa cu copertină de unde turiștii privesc erupțiile — POI înainte de Sciara |

Culorile locului: negru de bazalt și nisip, alb de var, turcoaz de mare,
verde prăfuit de tufăriș, **portocaliu incandescent de lavă** (singurul slot
nou de paletă). Lumina: soare jos, cald (~20°), umbre lungi — ora la care
lava emisivă începe să se citească fără să fie noapte.

## 2. Traseul și punctele de interes (POI)

Lungime țintă **~1.8 km** (tur ~55 s, cursă 3 tururi ≈ 2:50 — trei tururi
sunt necesare gimmick-ului: lava are trei stadii). Sens: antiorar (marea
rămâne pe dreapta pe toată coasta). Fracțiile sunt orientative — se măsoară
cu ProbeLayout după desen. Conul vulcanului e **flanc, nu fundal** (vezi
memoria `munte-flanc-nu-fundal`): vârful la ~100 m înălțime, la ~120 m
lateral de traversarea D, mereu în cadru pe jumătatea de vest a turului.

```
            [D] Sciara del Fuoco ←──── [C] observatorul Punta Labronzo
           bombe + buza spre mare              \  urcuș prin tufăriș
          /                                     [B] plaja neagră Piscità
   [E] bifurcația de lavă                        \  bărci, nisip adânc
   scurt ↔ ocol (se închide)                      [A] START — piața satului
          \                                      /
           [F] Ginostra (port)          [H] câmpul de fumarole
            \                          /   aburi peste drum
             [G] terasele de malvasia ── creasta cu priveliștea
                 (urcarea care dezvăluie: Strombolicchio + satul jos)
```

| # | frac | POI | ce se întâmplă | lățime |
|---|---|---|---|---|
| **A** | 0.00 | **Start în piața satului** — biserica albă cu campanil, banner în carouri întins între două case, terase cu pergole, un Ape parcat, bougainvillea pe ziduri | grilă pe dale albe-cenușii, grip normal; ulița e culoar strâmt între case | 8 m |
| **B** | 0.06–0.16 | **Plaja neagră Piscità** — drumul coboară pe fâșia de coastă: nisip negru bătătorit, bărci de pescari trase pe mal, plase, geamanduri; marea pe dreapta, **fără parapet** (parapetul e punctuație, nu regulă — ref 04); valuri cu spumă la 10 m de linie | banda bătătorită e rapidă; **nisipul negru adânc** de lângă linie taie viteza la ~45% (clasa „frecare"); intri în mare → repunere ~2 s | 9 m, fără pereți spre mare |
| **C** | 0.18–0.28 | **Urcușul la observator** — serpentină largă prin tufăriș (opuntia, capere, ginestre), ziduri joase de bazalt; sus, **terasa observatorului** cu copertină și parapet, primul loc de unde se vede Sciara întreagă și craterul fumegând | urcare ~30 m altitudine; primul telegraph al ciclului: dacă vulcanul bubuie acum, știi ce te așteaptă la D | 7 m |
| **D** | 0.30–0.42 | **Traversarea Sciara del Fuoco** — drumul taie canalul de scorie de-a curmezișul, la ~35 m peste mare; în dreapta buza cade direct în apă (**râpă fără parapet**, marea vizibilă jos, în interiorul lui `fog_end` — principiul din `world_design.md`); în stânga, canalul urcă spre crater | la fiecare puls al ciclului (~45 s), **3–5 bombe incandescente** sar în salturi pe canal și traversează drumul (reuse `RockfallHazard` pe trasee `Path3D`, declanșat de ciclu, nu de proximitate); lovitura te învârte (~1–2 s), căderea în mare = repunere | 8 m; suprafață de cenușă (grip 0.85×) |
| **E** | 0.46–0.58 | **Bifurcația de lavă** — câmpul de lavă veche (pahoehoe cordată, negru cu irizații): **ruta scurtă** taie câmpul drept (coardă ~120 m); **ocolul** coboară spre țărm pe lângă delta de lavă (arc ~190 m, câștig ~4–5 s pentru scurtă). Limba de lavă nouă coboară dinspre crater exact peste ruta scurtă | **turul 1:** scurta liberă, lava abia se vede sus. **turul 2:** limba a ajuns — scurta se îngustează la o poartă de 4 m între două brațe incandescente (atingi lava = distrugere + repunere din stând, calibrarea din sisteme.md). **turul 3:** închisă — zid de lavă cu crustă, semnalizat de la intrare; toți pe ocol. AI-ul re-alege ruta per tur | scurtă 6 m / ocol 8 m |
| **F** | 0.60–0.66 | **Ginostra** — cătunul minuscul: 4–5 case albe pe stâncă neagră, dana de beton a „celui mai mic port din lume", o barcă, un măgar care se ferește (figurant), scări albe | respiro tehnic: viraj strâns 6 m între case, singura strângere adevărată a turului | 6 m |
| **G** | 0.68–0.84 | **Terasele de malvasia** — urcarea lungă înapoi spre est: serpente printre ziduri de piatră neagră și rânduri de viță, măslini și smochini; la creastă (~45 m, punctul cel mai înalt) **priveliștea se deschide**: satul alb jos, marea, și **Strombolicchio cu farul** în larg — câștigată prin urcuș, nu servită (principiul „urcarea care dezvăluie") | urcare cu două ace de păr largi (raze ≥ 16 m, lecția din `viraje-stranse-puncte-pe-arc`); creasta e și kicker natural — pe fizica întreagă panta chiar lansează | 7 m |
| **H** | 0.86–0.96 | **Câmpul de fumarole** — coborâre prin zonă de pământ gălbui-alb cu guri de aburi; 2–3 **fumarole** suflă coloane de abur peste drum, în ritm propriu | **hazard-teatru, cost zero** (clasa care ne lipsește, ref 05): aburul albește parțial ecranul ~0.5 s, sunet de șuier — și atât. Înveți să treci prin el cu turbo | 7 m |
| **A′** | 1.00 | intrare în sat pe sub o arcadă albă între case, linia de sosire în piață | | 8 m |

**Ritmul turului:** sat (strâmt) → plajă (viteză, risc de mare) → urcuș
(tehnic) → Sciara (frică + bombe) → bifurcație (decizia turului) → Ginostra
(strângere) → terase (drift lung în urcare, priveliștea) → fumarole
(respiro fals) → sat.

**Ciclul de erupție ≠ durata turului (45 s vs ~55 s), intenționat:** faza se
mută de la tur la tur, deci Sciara nu e niciodată „mereu liberă" sau „mereu
bombardată" — dar bubuitul + coloana de cenușă te anunță cu ~3 s înainte,
de oriunde de pe pistă. Previzibil pe termen scurt, variat pe termen lung.

## 3. Hazarduri și mecanici (ce e nou pentru motor)

| mecanică | pe scurt | ce cere în cod |
|---|---|---|
| **Ciclul de erupție** | metronom global al pistei (~45 s): bubuit + tremur scurt de cameră + coloană de cenușă din crater (particule), apoi pulsul de bombe pe Sciara | nod mic `EruptionCycle` care emite un signal; hazardele se abonează. Telegraph audio-vizual cu ~3 s înainte |
| **Bombe incandescente** | 3–5 corpuri care sar în salturi pe canalul Sciarei și traversează drumul; lovitura = învârtire, nu oprire | reuse `RockfallHazard` (trasee `Path3D` există) cu declanșare de la ciclu în loc de proximitate; mesh nou `volcanic_bomb` cu emisiv |
| **Limba de lavă pe tururi** | 3 stadii de mesh peste ruta scurtă (liber / poartă de 4 m / închis); contact = distrugere + repunere | `LavaFlowHazard`: schimbă stadiul la signalul `lap_completed` al liderului; `TrackBranch` există (scurtătura de pe Alpi) — nou e **închiderea** ramurii + AI care re-alege ruta per tur + semnalizare la intrare |
| **Fumarole** | coloane de abur peste drum, ritm propriu, cost zero — teatru pur | emițător de particule + `Area3D` care albește parțial ecranul ~0.5 s + sunet; fără fizică |
| **Nisip negru adânc** | pedeapsa de frecare pe plajă, în afara benzii bătătorite | reuse mecanismul de suprafețe pe interval (generalizat la Baikal pentru gheață); doar valori + particule negre |
| **Cenușă pe Sciara** | grip 0.85× pe traversare — destul cât să se simtă, nu cât să enerveze | același mecanism de suprafețe |
| **Marea ca pedeapsă** | plajă fără parapet; intri în apă → repunere ~2 s | `custom_ravines` + `RespawnZone` (există) |
| **Buza fără parapet la D** | cădere de pe traversare în mare → repunere | idem |
| *(rezervat)* inversare de comenzi la impactul cu bomba | clasa „sabotaj de control" din sisteme.md §3 — autentic-Ignition (bolovanii lor exact asta făceau) | **NU în pachetul ăsta.** Se decide după experimentul separat pe rockfall-ul din Alpi; brief-ul doar rezervă locul |

Calibrarea pedepselor (din sisteme.md): distrugere/cădere ≈ 2 s + repornire
din stând ≈ 2 poziții; câștigul rutei scurte ≈ 4–5 s (echivalentul „corect"
al trenului lor de 14 s, redimensionat la turul nostru).

## 4. Paleta (un singur slot nou)

Lecția Baikal (6 sloturi din 8 propuse, rezerva aproape goală) se aplică
anticipat: **au mai rămas sloturile 30–31**. Stromboli cere UNUL.

| slot | rol | hex propus |
|---|---|---|
| **30** | `LAVA_ORANGE` — lava incandescentă, crăpăturile bombelor, poarta de la E | `#E8622D`, saturație ~0.8 — e **semnalul pistei**, are voie să concureze cu mașinile exact cum au voie panglicile serge |
| 31 | rămâne rezervă (magenta în atlas) | — |

Reutilizate: `VOLCANIC_BLACK` 20 (bazalt, scorie, nisip negru — sloturile
Okinawa fix pentru asta există), `FOAM_WHITE` 22 (case văruite, spumă),
`REEF_SHALLOW` 17 / `SEA_DEEP` 18 (marea), `TROPICAL_GREEN` 21 (tufăriș,
viță), `MARBLE_GREY` 29 (cenușă, pământul fumarolelor, dalele pieței),
`TILE_TERRACOTTA` 23 (olane, ghivece), `WOOD_WEATHERED` 9 (bărci, pergole),
`RUST_METAL` 10 (scripete de barcă, balustrade), `KERB_RED` 7 (borduri),
`DRY_VEGETATION` 13 (iarbă arsă de soare), `ROCK_LIGHT`/`ROCK_DARK` 3/4
(stânca veche stratificată). Bougainvillea: `CAR_RED` 14 — aceeași abatere
conștientă ca panglicile serge, suprafață sub 1 m² total, semnal de sat viu.

## 5. Lista completă de assets

Toate: low-poly stilizat (Art of Rally / machetă de masă), un singur material
= atlasul de paletă + AO în vertex colors; materiale de clasă doar unde scrie.
Origine la bază (linia solului / linia apei), +Y sus, „înainte" = −Z.
Dimensiunile sunt și în artefactul `img/stromboli_map.html`, la POI-ul lor.

### 5.1 Teren și suprafețe (generate din cod, cer texturi de clasă)
| asset | descriere | note |
|---|---|---|
| `lava_rock` (triplanar, clasa `rock_material` refolosită sau dală nouă) | lavă veche pahoehoe: negru cu pliuri „de funie" și irizații gri | câmpul de la E, delta spre mare |
| `scoria_material` | scorie roșu-negru poroasă pe canalul Sciarei | dală în familia rock |
| `black_sand` | nisip negru cu urme de roți și dâre de val | plaja B; varianta adâncă mai mată |
| `ash_ground` | cenușă gri-deschis bătătorită pe traversarea D | poate refolosi dala de beton gradată spre MARBLE_GREY |
| decal `tire_tracks_black` | urme pe dalele albe ale satului și pe cenușă | clasa de decal existentă, culoare nouă |

### 5.2 Structuri mari (hero, unice)
| asset | dimensiuni | descriere |
|---|---|---|
| `stromboli_church.glb` | 12×8 m, campanil 14 m | biserica San Vincenzo stilizat: volum alb cu fronton curb, campanil cu trei goluri de clopot, scară lată în față — POI-ul de start |
| `start_banner_alley.glb` | 10 m deschidere | banner în carouri întins între două case peste uliță, sfori cu stegulețe |
| `observatory_terrace.glb` | 10×6 m, copertină la 4 m | terasa observatorului: parapet de piatră neagră, copertină de pânză albă pe stâlpi, 2–3 mese, binoclu cu fise |
| `strombolicchio.glb` | bază 30×22 m, stâncă 32 m, far +8 m | neck vulcanic zvelt cu pereți aproape verticali, scară săpată în spirală, far alb cu lanternă în vârf — **fundal-erou**, plasat la ~200 m în larg (sub `fog_end`, cotele legate: siluetă < fog < FAR_PLANE) |
| `lava_flow_stage1/2/3.glb` | limbi 40 / 60 / 80 m lungime, 8–12 m lățime, crustă 0.5–1 m grosime | râul de lavă în 3 stadii: crustă neagră cu crăpături LAVA_ORANGE emisive; stadiul 2 lasă poarta de 4 m; stadiul 3 e zid continuu cu front bulbos |
| `volcanic_bomb.glb` (3 variante) | Ø 0.6 / 0.9 / 1.2 m | bolovani rotunjiți cu crustă crăpată incandescentă (emisiv în crăpături) — proiectilele rockfall-ului |
| `crater_vents.glb` | platou 25×25 m pe vârf | terasa craterului: 3 guri conice cu buze de scorie — sursa coloanei de cenușă (particulele din cod); vârful e `TerrainPeak`, asta e doar coronița |
| `ginostra_pier.glb` | dană 8×3 m, +scară 4 m | dana de beton a portului minuscul, bolarzi, o scară în stâncă, apă turcoaz |
| `fumarole_vent.glb` (3 variante) | Ø 0.8–1.5 m, h 0.4–0.8 m | guri de fumarole: cratere mici cu depuneri galben-albe de sulf pe buză (aburul din cod) |

### 5.3 Satul eolian (kit modular — servește A și F)
| asset | dimensiuni | descriere |
|---|---|---|
| `aeolian_house_a.glb` | 7×6×4 m | casă cubică albă, acoperiș-terasă cu parapet rotunjit, uși/obloane albastre sau verzi |
| `aeolian_house_b.glb` | 9×7×5.5 m | pe două niveluri, scară exterioară albă, terasă cu pergolă |
| `aeolian_house_c.glb` | 5×5×3.5 m | căsuța mică / magazie, un singur gol de ușă |
| `pergola_pulera.glb` | 4×3 m, h 2.5 m | pergolă eoliană: stâlpi albi cilindrici, grinzi de lemn, umbră de viță |
| `white_wall.glb` (modul 3 m) | h 0.9 m | zid alb rotunjit cu bancă înglobată; și varianta cu poartă |
| `alley_stairs.glb` | modul 4 m | trepte late albe între două ziduri |
| `street_shrine.glb` | 1.5 m | edicolă albă cu nișă albastră |
| `ape_piaggio.glb` | 2.7×1.3×1.6 m | tricicleta Ape, verde sau albastră, cu benă de lemn — parcată (static) |
| `fishing_boat_small.glb` | 5 m | barcă de lemn albastru-alb trasă pe nisip, pe bușteni |
| `fishing_boat_large.glb` | 7 m | barcă mai mare, ancorată la dana din F |
| `boat_winch.glb` | 2×1×1 m | scripete ruginit de tras bărcile + bușteni de rulare |
| `nets_buoys_set.glb` | set, 2×2 m amprentă | plase întinse, geamanduri portocalii/albe, lăzi de pește |
| `bougainvillea.glb` (2 variante) | 2×2 m pe zid / 3 m arcadă | tufă de bougainvillea CAR_RED pe perete alb — accentul satului |
| `pot_cluster.glb` | set Ø 0.3–0.6 m | ghivece de teracotă cu mușcate și opuntia mică |
| `donkey.glb` | 1.4 m la greabăn | măgarul din Ginostra — figurant static/PathMover lent, se ferește la apropiere |

### 5.4 Flancul vulcanului (kit de pantă)
| asset | dimensiuni | descriere |
|---|---|---|
| `olive_tree.glb` (2 variante) | 5–7 m | măslin cu trunchi răsucit, coroană argintie-verde |
| `fig_tree.glb` | 4–6 m | smochin cu frunze mari, coroană lată |
| `prickly_pear.glb` (2 variante) | 1.5–2.5 m | opuntia cu palete și fructe roșiatice |
| `caper_bush.glb` | 0.8 m | tufă de capere revărsată peste zid |
| `ginestra_bush.glb` (2 variante) | 1.5–2 m | ginestră cu vârfuri galbene (accent mic, desaturat) |
| `cane_clump.glb` | 3 m | pâlc de trestie de Canne pe lângă vâlcele |
| `terrace_wall.glb` (modul 3 m) | h 1.2 m | zid de terasă din bazalt negru fără mortar (muretto a secco) |
| `vine_row.glb` (modul 4 m) | h 0.8 m | rând de viță malvasia joasă, pe araci |
| `basalt_boulder.glb` (3 variante) | 1–3 m | bolovani negri cu fețe fațetate |
| `scoria_rock.glb` (3 variante) | 0.5–2 m | pietre de scorie roșu-negru, poroase |
| `lava_slab_broken.glb` | set 2–4 m | plăci de lavă cordată ruptă pentru marginile câmpului E |
| `coast_cliff_basalt.glb` (modular) | 10–20 m | faleze negre stratificate pentru linia coastei |

### 5.5 Fundal și atmosferă (siluete, `horizon_class`)
| asset | descriere |
|---|---|
| conul vulcanului | `TerrainPeak` (~100 m, la ~120 m de traversarea D) — **flanc, nu fundal**; trei etaje de culoare: verde jos, scorie la mijloc, cenușă sus |
| `island_silhouettes` | Panarea și Salina — două siluete joase albăstrui pe orizont (bandă plană) |
| plan de mare | există (Okinawa) — turcoaz spre larg, spumă la țărm |
| ceață | caldă, gălbuie; `fog_end` ~260 m; cer gradient crem → albastru pal |
| particule | coloana de cenușă din crater (pe ciclu); aburi de fumarole; scântei la contactul bombelor; praf negru la drift pe nisip; pescăruși (opțional) |

### 5.6 Sunet (referință pentru mai târziu)
bubuitul erupției (bas, cu ~3 s înaintea bombelor — ăsta e telegraph-ul),
sfârâitul lavei, șuierul fumarolelor, valuri pe nisip, clopot de biserică la
start, greieri pe terase, măgarul din Ginostra.

## 6. Bugete și costuri (estimare, se măsoară)

- triunghiuri: țintă sub **400k** (kit sat ~35k, flanc/vegetație ~110k,
  Strombolicchio ~8k, lavă+bombe ~20k, faleze ~40k, restul decor ~50k)
- materiale: atlas + `rock_material`/`lava_rock` + `scoria` + decal-uri +
  emisivul lavei → țintă **≤ 20**. Emisivul e UN material de clasă partajat
  (lavă + bombe + poartă), nu per asset
- lumină: o singură direcțională, joasă (~20°), caldă; umbrele lungi fac
  albul satului și negrul lavei să lucreze
- **de verificat devreme cu sonde:** cât costă emisivul + particulele de
  cenușă pe cadru; dacă flash-ul de abur al fumarolelor se vede (memoria
  `efecte-invizibile-nu-se-numara`: capturi, nu numărători)

## 7. Ordinea de construcție recomandată

1. `Track11.tscn` din `TrackFromPath`, temă `stromboli` (paletă + fog +
   horizon + `TerrainPeak` pentru con), traseul din §2 desenat, ProbeLayout OK.
   Bifurcația E de la ÎNCEPUT în traseu (lecția Baikal §10: scurtătura se
   măsoară, nu se speră — vezi §8 aici).
2. Suprafețele (nisip negru adânc, cenușă) + marea ca pedeapsă — sonda de
   feel: e fun un tur singur, cu drift pe plajă și săritura de pe creastă?
3. `EruptionCycle` + bombele pe Sciara (reuse rockfall) — al doilea test de
   feel: se citește telegraph-ul? te învârte sau te frustrează?
4. `LavaFlowHazard` cu cele 3 stadii + AI care re-alege ruta + semnalizarea.
   ProbeRace pe 3 tururi: AI-ul nu intră în lavă la turul 2–3, distribuțiile
   A/B (feature stins) rămân oneste — memoria `proberace-nedeterminism`.
5. Hero-assets în ordinea POI-urilor: biserica + kit sat, Strombolicchio,
   observatorul, lava (stadiile), fumarolele.
6. Kit flanc (statistice), fumarole-teatru, figuranți (măgar).
7. probe_decor, ProbeRace, tur de mână — verdictul de feel al dezvoltatorului.

## 8. Lecții aplicate anticipat (ca să nu le replătim)

- **Bifurcația e ocol real, nu bandă paralelă.** Baikal §10: o scurtătură are
  sens doar unde traseul ocolește ceva. Aici ocolul (arc ~190 m) și scurta
  (coardă ~120 m) se proiectează ÎMPREUNĂ, cu racorduri de rază ≥ 15 m și
  separare ≥ 2 × half_width; câștigul țintă 4–5 s se măsoară cu ProbeLayout
  înainte de orice decor.
- **Acele de păr din G:** raze > half_width, puncte eșantionate pe arc
  (memoriile `dunele-hairpin-pileup`, `viraje-stranse-puncte-pe-arc`).
- **Marginile spre mare:** goluri și praguri > 0.3 m sunt ziduri pentru
  raycast-ul suspensiei — marginile plajei se taie în pantă, nu în treaptă
  (memoria `suprafete-cu-goluri-si-praguri`).
- **Strombolicchio în interiorul lui `fog_end`** — altfel silueta există dar
  nu se vede (memoria `efecte-de-fundal-cote-legate`).
- **Emisivul lavei = un material de clasă partajat**, nu texturi per asset
  (CLAUDE.md, materiale per clasă; garda numără materialele).
- **Inversarea comenzilor NU intră aici** până nu trece experimentul separat
  pe rockfall-ul din Alpi. Dacă trece, bombele Sciarei sunt purtătorul natural
  (autentic-Ignition). Dacă nu, lovitura rămâne învârtire simplă.

---

## 9. Prompt pentru ChatGPT (dioramă de referință) — paste-ready

> Create a stylized low-poly **tabletop diorama** of a toy-car racing track on
> the **volcanic island of Stromboli, Italy, in late-afternoon golden light**.
>
> **STYLE (strict):** faceted, flat-shaded low-poly meshes like a Blender
> viewport render — **no fine surface texture, no painterly brushwork, no
> photorealism**. Chunky toy proportions: cars are stubby and ~1.3× wider than
> real cars; houses and trees are simplified into a few big planes. Soft baked
> ambient occlusion in the crevices, muted environment colors (~50% saturation)
> with only three saturated accents: the **glowing orange lava**, the
> bougainvillea on the white walls, and the toy cars. One single low warm sun
> (about 20° above the horizon) from the sea side, long soft shadows across the
> WHOLE overview. Sky is a plain gradient — warm cream at the horizon, pale
> blue at the zenith — no painted clouds except the volcano's ash plume. Show
> the diorama on a thin dark rounded-rectangle table base, from a raised 3/4
> view.
>
> **THE ISLAND [!]:** one steep volcanic cone (about 100 m tall at diorama
> scale) rises from the sea, with the racing loop wrapped around its LOWER
> flank — the summit crater is close and always visible above the track, not a
> distant backdrop. A thin **grey ash plume** rises from the crater. On the
> north-west flank a broad grey scree channel (**the Sciara del Fuoco**) runs
> straight from the crater down into the sea; a few **glowing orange bombs**
> are bouncing down it. Offshore, ~200 m from the island, a slender black sea
> stack with near-vertical walls and a small **white lighthouse on top**
> (Strombolicchio).
>
> **THE ROUTE — a single closed loop of about 1.8 km, counter-clockwise, the
> sea always on the right [!]:**
> 1. **Start/finish in a white Aeolian village square:** cubic flat-roofed
>    whitewashed houses with blue and green shutters, external staircases,
>    pergolas on round white pillars, a white church with a curved gable and a
>    14 m bell tower, a checkered banner strung between two houses over the
>    street, a green Piaggio Ape three-wheeler parked, magenta bougainvillea
>    spilling over white walls.
> 2. **A black-sand beach:** the road drops onto a strip of BLACK volcanic
>    sand along the water; wooden fishing boats pulled up on log rollers,
>    nets and orange buoys; **no guardrail toward the sea**; turquoise water
>    with white foam.
> 3. **A switchback climb** through dusty-green Mediterranean scrub — prickly
>    pears, caper bushes, yellow-tipped broom — between low black stone walls,
>    up to a small **observatory terrace** with a white canvas awning and a
>    stone parapet, looking straight at the Sciara.
> 4. **The Sciara crossing [!]:** the road cuts straight across the grey scree
>    channel, ~35 m above the sea, with the water visible directly below on
>    the right and the crater above on the left; glowing bombs bounce down the
>    channel across the road; the road surface here is pale grey ash.
> 5. **The lava fork [!] — the signature of this track:** on an old black
>    ropey lava field the route SPLITS: a short straight route across the
>    field, and a longer loop swinging toward the shore around a lava delta.
>    A fresh **orange-glowing lava tongue with a dark crust** is flowing down
>    from the crater toward the short route, shown just reaching it, leaving
>    only a narrow gap between two glowing arms. Red warning signs at the
>    split.
> 6. **Ginostra:** a tiny hamlet of 4–5 white houses on black rock above the
>    world's smallest harbor — a small concrete pier with one boat and white
>    stairs cut into the rock; the track squeezes between the houses.
> 7. **Malvasia vine terraces:** the long climb back — switchbacks between
>    dry-stone black basalt terrace walls, low vine rows on stakes, twisted
>    olive trees and broad fig trees; from the crest (the highest point of the
>    lap, ~45 m) the white village, the sea and the lighthouse sea stack are
>    all visible below.
> 8. **A fumarole field:** the descent crosses pale yellow-white ground where
>    small vents puff white steam columns across the road, then the loop
>    returns into the village under a white archway.
>
> **Details that matter:** the road is dark packed volcanic soil with
> red-and-white curbs only on the switchback corners; black deep sand borders
> the racing line on the beach; the sea is one continuous turquoise surface
> and clearly the lowest thing in the diorama; the lava and the bombs are the
> only strong orange in the scene; all white walls are slightly rounded, never
> sharp-cornered.
>
> Background: two faint blue island silhouettes on the horizon; a low warm sun
> with a soft halo; warm haze.
>
> Toy cars: 4–6 chunky low-poly racing cars in saturated red, blue, yellow,
> white — one drifting on the black beach, one mid-jump over the crest, two
> choosing different routes at the lava fork.
>
> Colors: basalt black #55535A, black sand slightly darker, whitewash
> #E9F2F0, sea turquoise #62B8C4 to deep #2F6E82, scrub green #5E7D4A, ash
> grey #B8B4AC, terracotta #C46A4C, **lava orange #E8622D (emissive)**, dry
> grass #AF9F4E.
>
> Deliver: (a) one wide 3/4 overview of the entire diorama with the loop
> clearly readable and the cone rising inside it; (b) one low driver's-eye
> shot on the black beach between the boats, with the white village behind
> and Strombolicchio out at sea; (c) one shot from the lava fork looking up
> the Sciara at the crater and its plume, bombs mid-bounce, with the two
> routes and the glowing tongue in the foreground.

## 10. Prompturi per asset (pentru referințele de Blender)

Diorama e pentru compoziție. Pentru fiecare asset se cere separat o planșă
curată; din ea se scrie brief-ul în `docs/asset_briefs/`. Șablonul:

> Same low-poly flat-shaded style as the Stromboli diorama (faceted meshes, no
> surface texture, soft AO, muted colors, one low warm sun). **Turnaround
> sheet** of `<ASSET>` on a plain neutral grey background, no scene, no ground
> clutter: front view, side view, top view and one 3/4 view, all orthographic,
> same scale, with a 1 m scale bar. Show only this object. `<ASSET-SPECIFIC LINE>`

`<ASSET>` + linia specifică, pentru hero-uri:

| asset | linia specifică |
|---|---|
| Stromboli church | white Aeolian church 12×8 m with curved gable and a 14 m bell tower with three bell openings, wide front steps |
| Strombolicchio | slender black volcanic sea stack, 30×22 m base, 32 m tall near-vertical walls, spiral stair cut into the rock, small white lighthouse (+8 m) with lantern on top |
| observatory terrace | 10×6 m stone terrace with black parapet, white canvas awning on poles at 4 m, two tables, a coin-operated binocular |
| lava flow (3 stages) | black-crusted lava tongue with glowing orange cracks and a bulbous front, three lengths: 40 m, 60 m (leaving a 4 m gap between two arms), 80 m solid wall |
| volcanic bomb ×3 | rounded boulders Ø 0.6 / 0.9 / 1.2 m with cracked crust, orange glow in the cracks |
| crater vents | 25×25 m summit terrace with three conical vents with scoria lips |
| Ginostra pier | 8×3 m concrete pier with bollards, 4 m white stair cut into black rock |
| fumarole vent ×3 | small craters Ø 0.8–1.5 m with yellow-white sulfur deposits on the lip |

Kituri (o planșă pe kit, obiectele aliniate pe un rând, aceeași scară):

| kit | conținut |
|---|---|
| village kit | Aeolian houses A/B/C (7×6×4, 9×7×5.5, 5×5×3.5 m) with blue/green shutters, pergola 4×3 m on round pillars, white wall 3 m module + gate variant, alley stairs 4 m, street shrine 1.5 m, Ape three-wheeler 2.7 m, fishing boats 5 m and 7 m, boat winch with log rollers, nets + buoys set, bougainvillea ×2, terracotta pot cluster, donkey (standing) |
| slope kit | olive tree ×2 (5–7 m), fig tree (4–6 m), prickly pear ×2 (1.5–2.5 m), caper bush 0.8 m, broom bush ×2 (1.5–2 m), cane clump 3 m, terrace wall 3 m module (h 1.2 m), vine row 4 m module (h 0.8 m), basalt boulders ×3 (1–3 m), scoria rocks ×3 (0.5–2 m), broken lava slabs 2–4 m, basalt coast cliff module 10–20 m |
