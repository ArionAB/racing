# Carrara — starea POI-urilor după gauntlet (valul 1: A, B, C; valul 2: D–H) (31 oct 2026)

Nota de predare a primului val de decor pe Track23 (temă `carrara`, index 15,
scena 23). Contractul e `docs/track_briefs/carrara_poi_gauntlet.md`; aici e ce
s-a întâmplat pe el. D–H nu sunt începute.

## Pe scurt

- **A, B, C sunt populate** în `tools/carrara_decor/zona_a.py`, `zona_b.py`,
  `zona_c.py`, iar Track23.tscn e regenerat din ele (integrarea pe
  `carrara/poi-abc`).
- **Bălțile turcoaz din fundul carierei există** (C): 6 scobituri `TerrainHollow`
  (`BALTI` în generator) plus apa râpei 1 la cota +0,35, stil opac
  (`custom_water_styles`). Saturația pe masca bălții: 0,36–0,51 (contractul: ≥ 0,25).
- **Niciun POI n-a câștigat orb** (0/3, ca Serengeti, Machu Picchu, Fiordland).
  Toate trei au ieșit pe regula (c) după 3 runde.
- **Acceptarea finală e la volan**, pe scena integrată.

## Cum s-a ieșit din buclă, per POI

| POI | runde | ieșire | ce a cerut criticul, pe runde | cauza sub decor |
|---|---|---|---|---|
| A Piazzale | 3 | (c) | r1 blocuri risipite uniform, culori de jucărie → r2 niciun nucleu de lucru, nicio clădire → r3 curtea goală, totul într-un rând depărtat | platoul de la start e un câmp plat de ~80 m, iar contractul ține prim-planul (plutonul, primii 100 m) și dreapta (dezvăluirea bălților) libere; orice cantitate de decor rămâne mică pe atâta bej |
| B Gradonii | 3 | (c), oscilație | r1 lipsește cordonul de pe margini → r2 blocurile „beton murdar”, înclinate aleator, vrea șiruri drepte → r3 șirurile citesc „stâlpișori”, vrea moloz neregulat | **relieful**: treptele n-au fețe verticale tăiate (criticul r3: „relieful e o pantă netedă”); și **culoarea** `carrara_marble` (vezi mai jos) |
| C Fundul | 3 | (c) r2 = r3 | r1 malurile bălților goale → r2 blocurile mici, gri-închis/maro „cutii” → r3 blocurile „cuburi de beton gri-albăstrui” | **culoarea** `carrara_marble` pe fețele din umbră; pereții râpei albastru-gri |

**Tiparul dominant:** marmura citește „beton gri-albăstrui cu pete maro” (B r1, B r2,
C r2, C r3). Nu e așezarea: fețele de sus ies crem, fețele din umbră iau
albastrul cerului, iar textura triplanară a clasei are pete închise. Afectează
A, B, C deodată, deci se repară o singură dată, pe clasă/lumină, nu per POI.

## Starea finală, per POI

| POI | commit final | piese | ce e acolo |
|---|---|---|---|
| A | `8f6bfd90` | 45 | un nucleu de lucru în stânga-mijlocul cadrului de la 0,01: birou de șantier pe două niveluri (containerele), excavator static de decor, două grămezi mari, roata și vagonetul de muzeu (1,6×), foraj, cisterne; R1/R2 pe buza dinspre gol; castani și ginestra sub buză |
| B | `71344388` | 255 (224 fantome) | 14 șiruri regulate de blocuri pe margini și pe buzele bancurilor; 6 grupuri de lucru (4 mașini de fir cu volantul rotindu-se, foraj, mosoare, stive); moloz la piciorul lui F1 în volumul plasei |
| C | `10ff1771` | 88 | bălțile; 15 grămezi de blocuri pe maluri; șir de blocuri spre balta mare (lat +13); ferăstrăul-lanț cu lama în perete + stivă + con; conuri de grohotiș la pereți; lămpile de la portal la ±11,5 |

## Schimbări în afara fișierelor de zonă (aprobate de coordonator)

- `gen_carrara_route.py`: opțiunea `"spin"` pe piesele de decor (`windmill.gd` pe
  nodul `Blades`, axa X pentru `wire_saw`); fără nicio piesă cu spin, Track23
  iese identic la bit.
- `gen_carrara_route.py` (constructorul C): `BALTI`, stilul apei, apa râpei 1.
- `world_prop.gd`, `CLASSES_CARRARA`: `fuel_tank` pe rugina mată (`_CRR_RUST`),
  `office_container` pe `plain` (fibra triplanară citea scândură; +1 material).

## Gărzi pe scena integrată

Pe `carrara/poi-abc`, cu main (#624) adus în ramură:

| gardă | rezultat | linia de bază pe main |
|---|---|---|
| `bash tools/verify_local.sh` | OK, 62 de pași | — |
| probe_decor `--track=23` | OK, **25 de materiale** (≤ 38), 858 de desene, 931 de prop-uri | 19 materiale |
| probe_manual `--track=23` | 5 (viaductul + 4 portaluri), zero noi | 5 |
| ProbeCarraraMontaj `--decor` | OK, 381 de piese | OK, 25 |
| ProbeLaneClear `--track=15` | OK, 9, exact linia de bază | 9 |
| ProbeBuried / ProbeLayout `--track=15` | OK / OK | OK / OK |
| ProbeRace 32 seed-uri (prima integrare) | 18 / 5 / 15 (repuneri / ejectări / blocaje) | per 16 seed-uri: 8/2/16, 6/1/15, 11/5/4 (trei serii de bază ale constructorilor) |
| ProbeRace 16 seed-uri (după R2 fantomă și main) | 10 / 4 / 10 | idem |

**Unde cad incidentele:** la excavator (0,036–0,055, hazardul lui A), pe E/F
(0,669–0,700, neatinse) și la acul de la 0,147 (aceeași repunere ca pe bază).

**Două lucruri citite pe nume:**
- *seed 14, prima integrare*: o mașină s-a înțepenit între bermă și `A_R2a`
  (0,042, lat 6,3), în coada excavatorului. Rândul R2 de pe buză e acum fantomă
  (piesele dincolo de berma fizică rămân doar vizuale); seria a doua n-are nicio
  atingere de decor.
- **deschis:** ejectarea în rama portalului galeriei (0,398, ~36 m/s, intrare în
  diagonală dinspre marginea dreaptă). Apare în 2 din 96 de seed-uri cu decorul lui C
  și în 0 din 52 de seed-uri de bază. Lămpile au fost mutate la ±11,5 și tot apare.
  Mașina lovește rama, nu o piesă de decor; tiparul (intrări în diagonală în ramă)
  e descris în generator din runda 0. Nu e nici atribuit, nici exclus.

## Decizii pentru dezvoltator

1. **Culoarea marmurei** (A, B, C): clasa `carrara_marble` și lumina pe fețele din
   umbră. E diferența repetată de 4 ori.
2. **Platoul de la start** (A): îl îngustăm sau îi dăm relief în generator, acceptăm
   decor lângă grilă (dovedit pe ProbeRace) sau îl judeci la volan.
3. **Treptele** (B): fețe verticale tăiate pe gradoni (relief, nu decor).
4. **Rampa acului 1** (0,118–0,145): cădere de ~6 m pe stânga, fără bermă și fără
   plasă; o mașină căzută a lovit decorul de pe T3 la 28,7 m/s. Bermă/plasă în generator?
5. **Bălțile nu se văd de la start**: sunt la 250–300 m, în ceață. Ar cere apă pe o
   râpă a lui B.
6. **Asseturi lipsă**: turnul de piatră pătrat, magazia cu acoperiș de tablă
   (substituite), ginestra fără flori galbene (remap de slot pe temă), castanul
   citit „blob verde saturat”.
7. **Opțiunea `hide`** în generator (stâna fără gard): cerere a constructorului A.
8. **Malul de calcit din shader** (lățimea benzii `shore`): cerere a constructorului C.
9. **Desene**: cordonul lui B trece probe_decor de la 278 la ~640 de desene. Piesele
   pe triplanar de lume (`carrara_marble`) rămân noduri la coacerea DecorManual
   (proiecția nu supraviețuiește MultiMesh-ului pe Mobile), deci nu se grupează.
   De măsurat pe device.
10. **Scurtătura prin baltă** (TrackBranch la 0,33): rămâne decizia ta; P3, în
    interiorul cotului 1, e locul pregătit.

## Unde sunt capturile și planșele

`C:/Users/Arion/AppData/Local/Temp/claude/d--GameDev-ignition-spike/8205edc4-f7e3-4cef-990e-1b59ae886720/scratchpad/poi/`
(`a|b|c/r1..r3/` capturile, `sheets/plansa_*` planșele oarbe cu cheile).
Scratchpad-ul sesiunii nu e permanent; capturile finale reprezentative sunt
copiate în `docs/track_briefs/img/carrara_poi/`.

## Runda 1b (31 oct 2026): deciziile dezvoltatorului, aplicate

Dezvoltatorul a raspuns la deciziile de mai sus: decor permis langa grila (2), fete verticale pe trepte (3),
asseturile lipsa se fac (6), desenele raman asa (7), baltile de langa derrick sunt ok (5). Raman deschise:
culoarea marmurei (1) si bariera de pe panta de dupa acul 1 (4). Trei constructori Opus, integrati pe
`carrara/poi-abc-v2`.

| ramura | ce | ieșire orb |
|---|---|---|
| `carrara/a-grila` | curtea pe tot drumul vazut de la grila (x -170..-60), patru planuri: margine la 4-6 m, curte la 13-27 m, depozit la 28-34 m, perete de blocuri in trei trepte (8/11/14 m) pe stanga; dreapta = fantome dincolo de berma. 116 piese | 0/4, (c): de doua ori „solul gri-albastru rece si lumina plata” — tema, nu decorul |
| `carrara/trepte-verticale` | fetele ERAU verticale (82-86 grade); se citeau panta fiindca fetele care coboara de la drum nu se vad din chase cam, iar cele vizibile se terminau in racorduri de 22-28 m. Fetele continua dincolo de ace, fiecare banc de 21 m e in doua trepte (polite T2N +20,5, M +12,5), `BENCH_FINE_DIV` 8 -> 16, plase noi PlasaM/PlasaMCapat. In cadrul de joc: panta lina 6,0 -> 2,9 %, fata verticala 15 -> 22 % | 0/2, (c): „o singura stanca, fara ritm de trepte” — ramane textura fetei (strate, nu blocuri taiate) si unghiul camerei |
| `carrara/kit-a-lipsa` | `stone_tower.glb`, `tin_shed.glb`, `chestnut_tree_a/b.glb` (macchia cu tenta oliv: H 112/S 0,69 -> H 84/S 0,57), `ginestra_fiorita.glb` (~92 % galben); `ginestra_bush` pierdea florile din cauza maparii globale `Ginestra_ -> macchia`, reparat pe tema carrara | — |

**Integrarea** (`e6800129`): inlocuitorii lui A -> asseturile noi; treptele lui B au pus o buza la lat +12,5 pe
dreapta startului (polita la +20,2), deci A_Castan7/8 coboara pe polita, iar A_RGc, A_MuzeuRoata, A_RSc,
A_CiobR3/R5 se muta sub buza (masurat pe toate piesele, inclusiv cele coapte).

**Garzi pe scena integrata:** verify_local OK (66 de pasi); probe_decor 24 de materiale, 226 de desene,
509k triunghiuri; probe_manual 5; ProbeLaneClear 9; ProbeBuried/ProbeLayout OK. ProbeRace 32 de seed-uri:
13 / 4 / 24 (repuneri / ejectari / blocaje) — 21 din 24 de blocaje la excavator (0,046-0,052, hazardul
lui A, ca pe main), zero atingeri de decor, zero incidente la buza T1 (0,078) si la portalul galeriei (0,398).
Capturi: `img/carrara_poi/a_int2_f001.jpg`, `b_int2_f016.jpg`.

## Valul 2 (31 oct 2026): D, E, F, G, H

Trei constructori Opus pe baza `carrara/poi-abc-v2` (#637), integrați pe `carrara/poi-val2`. Niciun POI n-a
câștigat orb (0/5, ca toate celelalte); acceptarea e la volan.

| ramura | POI | ieșire orb | ce s-a făcut | cauza sub decor |
|---|---|---|---|---|
| `carrara/poi-dh` | D galeria | (b), r1 | aripile portalurilor (cod, `Track._tun_frame`, 14 m beton) pe marmură și în pantă 2,5 → 1,1 m prin două exporturi noi pe `TunnelSignalHazard` (`frame_class`, `wing_end_height_m`; amprentele Track16/Track21 neschimbate); moloz în spatele aripilor; conducta de serviciu în tub (fără coliziune) | „gri-albăstrui, fără planuri tăiate” = culoarea marmurei + relieful |
| `carrara/poi-dh` | H Marmifera | plafonul de 4 runde | tunelul pe praf (nu mai e asfalt cu linie albă); portalul pe `carrara_marble`, fără mușchi; stânci pe capac și pe umerii movilei; castani, ginestra, excavator parcat | portalul oscilează `tf_stone` (albastru) ↔ marmură (se pierde în tot); tunelurile sunt luminate |
| `carrara/poi-ef` | E platoul de sus | plafonul de 4 runde | 280 de piese: cordon de blocuri pe buza din dreapta (fantome), perete tăiat în două trepte pe stânga cu gol pentru camionul 2 | grohotișul des din bară e textură pictată |
| `carrara/poi-ef` | F podul | (c), r3 | podul pe praf; râpa 0 adâncită (+16,7, arcele libere); torentul turcoaz (+1 material); stânci în peretele cheiului, bolovani în apă | peretele de teren de 26 m cu triplanarul întins |
| `carrara/poi-g-ravaneto` | G ravaneto + Colonnata | (c), r3 | 58 de piese (Colonnata în S2, turnuri, colțul SV) + pădure în masă `PadureMasa` (MeshForest, ~1.890 de instanțe); satul pe marmură + țiglă pe atlas | ravaneto-ul gol cerut de brief, solul rece, lipsește un arbust verde jos |

**Integrarea:** praful a fost unit pe toată bucla (fiecare constructor scosese asfaltul doar de pe zona lui:
podul F, tunelul H) — două intervale în generator, nu `custom_road_surface = "dirt"`. `world_prop` și generatorul
au avut conflicte aditive (portalul Marmiferei + satul; `ZONE_META` + `FOREST`). Track23 regenerat. Capturi pe
cusături (0,70 / 0,725 / 0,83 / 0,935): `img/carrara_poi/val2_cusaturi.jpg` — fără pădure pe pod sau în gura H.

**Respinsă:** propunerea de a termina camionul 2 la capul podului (`b_near(-118, 112)`). Ieșirea lui din drum
(ultimii ~20 m, până la lat −30) ar cădea pe tablier, deasupra cheiului de 26 m.

**Gărzi pe `carrara/poi-val2`:** verify_local OK (66 de pași); probe_decor **23 de materiale**, 1.571 de desene
statice (toate feliile LOD ale pădurii; pe cadru: medie 139 / vârf 289, ProbePerf al constructorului G);
probe_manual 5; ProbeLaneClear 9; ProbeBuried / ProbeLayout / ProbeCarraraMontaj OK.

ProbeRace 32 de seed-uri: **23 / 6 / 23** (repuneri / ejectări / blocaje), față de 13 / 4 / 24 pe #637:
- excavatorul (0,034–0,052, A, neatins în valul 2): 14 repuneri, 5 ejectări, 20 de blocaje;
- E/F (0,679–0,699): 8 repuneri, toate la întâlnirea cu camionul 2 la t ≈ 57–61 s — mașini împinse în afara
  drumului care acum cad în cheiul adâncit; constructorul E/F măsurase aceeași rată (3 / 16);
- D 0,432: o ejectare în peretele tubului, departe de portaluri (aceeași clasă ca 0,479 din logurile vechi);
- zero atingeri de decor din valul 2, zero incidente în G.

### Decizii noi pentru dezvoltator

1. **Tunelurile par luminate ziua** (D, H): tema lasă ~35 % din soare în tuburi (`shadow_opacity` 0,65), iar
   `CameraZone` stinge doar ambientul.
2. **Sala din galeria D** (stâlpi de marmură, bloc răsturnat, puț de lumină): tubul are o singură lățime (8 m,
   exact drumul). Planul constructorului: 3 noduri de tunel sau profil variabil, piesa de stâlp, ROCKFALL la 0,48.
3. **Camionul 2** pe E/F: întâlnirea frontală la t ≈ 60 s e acum principala sursă de repuneri în afara lui A.
4. **Arbust verde jos** pentru subarboret (G): lipsește din kit.
5. **Vârful de triunghiuri** cu pădurea: 1,44 M la 0,70 (G văzut de pe pod). Cu `FOREST_FAR_MIN = 0`: 1,10 M,
   dar coroanele de departe se rup.
6. **Galbenul excavatorului** e saturat (atlas `Body_Paint`); **o gaură de teren** lângă capacul H, nevăzută
   din cameră; **treptele amfiteatrului** din dreapta podului (lat +29) — o mașină blocată o dată, în afara
   plaselor.

### Deciziile dezvoltatorului după valul 2 (31 oct 2026)

1. tunelurile luminate: **rămân așa**; 2. sala din galeria D: **da** (mai jos); 3. camionul 2: **e în regulă**;
4. arbustul verde: **rămâne așa**; 5. vârful de triunghiuri al pădurii: **rămâne așa**. Culoarea marmurei:
tot nedecisă.

**Atenție la stivă:** #638 a fost merge-uit în baza lui (`carrara/poi-abc-v2`), nu în main — valul 2 intră
în main abia cu PR-ul sălii, care îl conține.

## Sala galeriei D (31 oct – 1 nov 2026)

Ramura `carrara/sala-d` (valul 2 + main + sala). Brief §2 POI D: 16 m lățime, tavan înalt, doi stâlpi de marmură
PE carosabil, blocul basculat. Captura de joc: `img/carrara_poi/sala_d.jpg` (stânga: banda dreaptă, blocul în
rostogolire, ambii stâlpi; dreapta: pe lângă peretele stâng, trecând de stâlpul 1).

| ce | cum |
|---|---|
| lățimea | **o singură declarație**: drumul D e rupt în trei sectoare lipite (4 / 8 / 4 m semilățime) într-o fereastră de curgere (`width_flow_windows`, panta 1/15): ~60 m de evazare de fiecare parte, ~80 m la 16 m (0,505–0,543). Fereastra trece cu ~37 m de capetele sectorului, altfel rampa de 30 m a sectorului sălii lăsa o treaptă de 1,5 m pe marginea ei (`_validate_width_flow`) |
| tubul | `TunnelSignalHazard.hall_ceiling/hall_from_m/hall_to_m`: pe interval pereții merg pe marginea drumului (`Track.width_at_index`), tavanul urcă proporțional până la 16 m, piciorul movilei rămâne pe cota veche. Fără sală, profil constant: **Track16/Track21 bit-identice** (ProbeTunelHash, aceleași md5 înainte/după) |
| stâlpii | `gallery_pillar.glb` (nou, 3 × 3 × 18 m, 6 tronsoane, 112 tri), la 0,5145 / lat −1,5 și 0,5300 / lat +1,5, coliziune `hull`. Pe mijloc se trece doar în slalom; lipit de un perete, drept |
| AI-ul | `custom_lane_bias` (export nou, 0,4932–0,534, 0,70): pilotul ține marginea pe partea lui de personalitate, iar `Track.lane_floor_at` o face **podea tare după ocolire**. Fără podea, depășirea trăgea linia spre axă: AI-ul lovea stâlpul 2 cu 30–42 m/s în 7 din primele 8 seed-uri |
| blocul | `RockfallHazard` cu traseu (`BlocSala`, `block_informe_a`): de pe patul de moloz din dreapta (0,5077), 2,2 m de cădere, rostogolit pe banda dreaptă până la lat +0,5; 1,9 s de mers, ciclu 29 s, clopot 2 s. Curba se scrie RELATIV la marker (în lume ieșea dublată) |
| decorul | moloz + bloc informe sub bloc, trei lămpi de șantier, conducta mutată pe peretele de 8 m al sălii (în evazare peretele fuge 1/15, un modul drept de 6 m ar ieși în bandă) |
| clase | `gallery_pillar` în `CLASSES_CARRARA`, `Informe_Marble` în `CARRARA_MOVING_CLASSES`: fără ele stâlpul și blocul rămâneau pe atlasul brut (dungi de zebră). Zero materiale noi |

**Gărzi:** probe_decor **23 de materiale** (neschimbat); ProbeLaneClear **13** (9 + cele 4 sonde pe stâlpi,
linia de bază mutată cu motivul scris); ProbeBuried / ProbeLayout / ProbeCarraraMontaj OK; verify_carrara cu
stâlpul declarat.

**ProbeRace, 16 seed-uri pe versiunea finală: 6 / 2 / 12** (repuneri / ejectări / blocaje), **zero incidente în
sală** (0,47–0,57). Pe drum: podea 0,62 → 3 ejectări în stâlpul 2 pe 16 seed-uri (0,96 m de aer), podea 0,70 → 0.
Blocul strivește ~1,5 mașini pe cursă (loviri `RockfallHazard` 0,8 → 2,3 pe seed, sania inclusă), fără repuneri.
Restul incidentelor sunt la excavator (0,044–0,049), ca pe #637/#638.

**Rămas:** puțul de lumină din tavan (făcut pe 1 nov, mai jos); culoarea marmurei, ca peste tot. Verdictul la
volan e al dezvoltatorului.

**Verdictul (1 nov 2026):** dezvoltatorului îi place sala, iar performanța pe pistă e bună. #640 merge-uit în
main. Culoarea marmurei: **rămâne așa** (decizie, nu se mai întreabă).

## Puțul de lumină (1 nov 2026)

Ramura `carrara/put-lumina`. O gaură reală în tavanul sălii, între cei doi stâlpi, cu o rază de soare care
cade prin ea pe drum. Captura: `img/carrara_poi/put_lumina.jpg` (stânga: apropierea pe axă, raza după stâlpul 1;
dreapta: de aproape, raza scaldă stâlpul 2, prin gură se vede cerul).

| ce | cum |
|---|---|
| gaura | `TunnelSignalHazard.shaft_from_m/shaft_to_m/shaft_lateral` (8 m pe lungime, lateral −3,5…+2,5): pe fâșiile tubului cu mijlocul în interval nu se desenează nici tavanul, nici creasta movilei, iar `_tun_shaft_walls`/`_tun_shaft_end` închid golul dintre ele (pereții puțului). Profilele tubului cu puț își mută ruptura tavanului și creasta movilei pe marginile găurii, scalate cu lățimea secțiunii (același număr de vertecși pe tot tubul). Poziția: `zona_d.SHAFT`, mijlocul dintre stâlpi |
| de ce n-a cerut capac separat | Teama veche: paritatea ProbeBuried. Măsurat: raza în sus din axă trece prin gaură și nu lovește nimic (0 fețe = afară), iar pereții puțului sunt verticali, deci paraleli cu raza. Lateralul e asimetric, ca niciun segment de tavan să nu fie centrat pe axă (`TUNNEL_MOUND_CREST`). ProbeBuried `--track=23` OK |
| raza | `LightShaft` (conul aditiv al Cappadociei, material partajat), pus de `_tun_shaft_light` în centrul găurii, cât sala de înalt. Tenta = soarele temei, pal; intensitate 0,22 (0,12 nu se vedea pe marmura luminată) |
| capcana | Primele două capturi la intensități diferite au ieșit **identice la pixel**: conul nu se desena deloc de la distanță. `LightShaft` avea stingerea după distanță **inversată** (min 4 > max 1,5, iar Godot inversează atunci sensul): raza se vede doar de la sub 4 m. Export nou `LightShaft.fade_m`, implicit tot (4; 1,5), deci Cappadocia rămâne cum e; Carrara cere (1,5; 5): se vede de departe, se topește doar când camera trece prin ea. **Raza din caverna Cappadociei are aceeași inversare și probabil nu se vede de la distanța camerei** — neatinsă aici, de verificat separat |
| bit-identitate | ProbeTunelHash `--scenes=16,21`: aceleași amprente ca înainte (Fiordland `31f5ea47…`, Transfăgărășan `f95ad866…`) |

Fără efect pe condus: raza n-are coliziune, gaura e la 16 m deasupra drumului.

**Gărzi:** `verify_local.sh` OK (66 pași); probe_decor Carrara **24 de materiale** (+1: materialul razei, partajat; plafon 38); ProbeBuried `--track=23` OK.
