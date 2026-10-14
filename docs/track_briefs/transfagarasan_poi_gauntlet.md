# Transfăgărășan — contractul per POI pentru gauntlet

> Fișa de lucru a perechilor constructor/critic pe Track21 (`transfagarasan`).
> Bara e `docs/track_briefs/img/transfagarasan_plan/diorama_v02_iter2.jpg` (a doua
> corecție, **acceptată**, brief §9.2), decupată per POI în
> `docs/track_briefs/img/bar_transfagarasan/<POI>.png` (mărit, ≥ 1800 px;
> `tools/bar/crop_transfagarasan_bar.py`, cu justificarea fiecărei casete în cod;
> planșa de control `bar_transfagarasan/_index.png` arată dreptunghiurile pe
> dioramă). **Nu există decupaje `_iter1`/`_iter3`**: iter1 are camera din sud, cu
> serpentine care urcă spre lac și un tunel-fundătură, iar iter3 pune semaforul
> peste serpentine și pierde ursul și tunelurile scurte; amândouă sunt respinse
> (brief §9.2) și un critic care primește o bucată din ele judecă altă pistă.
> Decupajele suplimentare față de cele 8 litere: `A_poenari`, `C_urs`, `F_oi`,
> `ORIZONT` (marea de nori) și `CREASTA` (zimții Făgărașului). Planul real al
> traseului e `img/transfagarasan_plan/transfagarasan_plan.png`. Kitul (36 GLB) e în
> `docs/asset_briefs/transfagarasan_kit.md` (cote, contracte) și
> `transfagarasan_inventory.md` (cotele măsurate din GLB, „Montarea în Track21”).
> **Sursa de adevăr pentru traseu e măsurătoarea de mai jos
> (`tools/sv_tf_fractii.gd`), nu brief-ul §2.**
>
> Măsurătorile sunt pe `transfagarasan/poi-bara` = **ee4627af** (montarea kitului:
> portaluri, baraj, ziduri, zăpadă, hazarde, clase) + această ramură (în
> `Track21.tscn` doar cele 8 noduri `ZonaA … ZonaH` cu `metadata/fractii`, goale;
> traseul, terenul, hazardele și piesele montate sunt neatinse). Se re-rulează
> `godot --headless --path . res://tools/SvTfFractii.tscn` după orice atingere a
> traseului sau a terenului și se corectează tabelul.
>
> **Citește întâi secțiunea „Probleme de nivel de pistă”** (spre sfârșit, înainte de
> valuri). Capturile „înainte” arată că o parte din ce lipsește față de bară nu se
> poate repara din decor: apa e „mare”, iarba e galbenă, fundalul e plat, lacul Bâlea
> e o farfurie, barajul n-are hău. Acolo bucla oarbă ar ieși pe (c) în prima rundă,
> pe fiecare POI, cu aceeași diferență.

## Regula care se încalcă cel mai des

**Bara nu e layout, e look.** Diorama e o machetă pictată, văzută de sus dintr-un
colț, în care satul, barajul, lacul, tunelurile, portalul, Bâlea Lac, patru
serpentine, cascada, Oltul, trenul și Poenari încap toate într-un cadru, cu
versanții apropiați de fiecare drum și cu stratul de nori sub tot. Pista nu face
asta și nu trebuie să facă asta: din mașină vezi o fâșie de ±50 m de teren și un
orizont; relieful lateral e de multe ori plat (§Premise). Criticul compară **cum
arată materia**, nu unde cade fiecare obiect:

- **șistul cristalin gri-verzui** (`#7E8478`, fețe luminate `#A3A796`, fisuri `#4A4E47`)
  în **lame înclinate** (foliație), nu bolovani rotunzi: aflorimente, zidurile de
  sprijin, grohotișul în conuri; **nu** tan/bej cald (creasta din captura
  `nivel_creasta_A_din_D` iese bej, vezi N3);
- **zăpada veche de iulie**: alb murdar (`#E8ECEE`), **umbră albastră**
  (`#B5C3D3`), dungi de praf (`#B9B2A4`), straturi vizibile ca formă, muchia de sus
  rotunjită, baza murdară; **nu** alb curat, nu cuburi;
- **molidul verde-negru** (`#23392B`, coloană îngustă și ascuțită), **jneapănul
  verde-închis albăstrui** (`#34503A`, tufă joasă, culcată, în pâlcuri), **fagul verde
  cald** (`#5E8A3A`, coroană rotundă) doar jos, la Argeș;
- **pajiștea alpină rece** (`#7D9A4E`) cu **bujor de munte magenta** (`#B63A7A`) în
  petice mici, niciodată aliniate; afine joase;
- **tabla**: acoperișuri argintii și roșii, apoi ruginie la cabane; **lemnul
  îmbătrânit** și **piatra** jos la cabane (acoperiș abrupt, fără balcoane sculptate);
- **betonul cald al barajului și al portalurilor** (`#B8B4AA`), cu **parapete
  alb-roșii** (`#EEEEEA` / `#C2312B`) la fiecare curbă;
- **apa**: lacul Vidraru **verde-închis** (`#2F5446`), lacul Bâlea **verde-albăstrui
  rece** (`#3F6F7A`, transparent la mal), Oltul **verde-cenușiu tulbure**
  (`#6E7F69`), cascada și spuma ca forme plate albe; **nu** turcoazul deschis de mare
  cu creste de val (așa randează azi toate apele, vezi N2);
- asfaltul **gri-albăstrui cu linie albă**, nu galbenă; cerul de 2 000 m, adânc sus
  și alb-cald la orizont; **zăpada caldă în soare și rece în umbră, pe același cadru**.

Corolar: un critic care spune „la noi baraj nu are hău de 40 m”, „la noi Poenari nu
e lipită de sat” sau „la noi lacul Bâlea nu e într-o căldare” a comparat layout-ul
(sau a găsit o problemă de nivel de pistă, cu locul ei mai jos) și a ratat sarcina.
Singura diferență care contează e una pe care o poți repara în decorul POI-ului.

**Defectele dioramei care NU se iau din imagine** (verificate pe decupajele mărite
față de pistă; brief §9.2 și măsurătorile de mai jos le confirmă):

| în dioramă | în joc | de ce |
|---|---|---|
| **barajul** e un arc masiv cu hăul adânc și lacul sus, pe tot frontul | coronament **drept** de **96 m** (0.078–0.123, rază ~3,2 km), semi 6,0; lacul la **+7,5** (4,5 m sub coronament), hău pe dreapta cu fundul la −28 și râul la −24 | kit §0: arcul se citește din profilul vertical, nu din plan; hăul se vede slab de pe coronament (N4) |
| **două tunele scurte de stâncă** lângă urs | **un singur** `rock_tunnel_portal` la **0.1384** (în B, la 1,3 m de axă), cu `ZoneCamera/TunelStanca` 0.1315–0.148; brief-ul le voia la ~0.17–0.19 | montarea (M-scena); al doilea portal nu e montat (decizie de integrare, vezi C) |
| **tunelul lung** cu portal și semafor chiar pe gură | tunel de **~70 m** între `Portal_S` (0.3171) și `Portal_N` (0.3499), semi 6,0; **stâlpul semaforului stă la 34 m ÎNAINTEA gurii** (`Lampa`, 0.3040, 7,5 m dreapta) | `HazardLamp`, brief §3.2 |
| **al doilea portal** înaintea serpentinelor, citit ca ieșire | e `Portal_N` (0.3499): ieșirea reală; în dioramă pare un al treilea tunel | abatere asumată, brief §9.2 |
| **lacul Bâlea** ca un lac larg, cu plajă, în căldare, cu cabana pe mal | disc de **Ø 68 m** (`LacBalea`, +40,3) la **43,5 m dreapta** (0.3573): începe la **9,5 m de axă**, deci la ~3 m de asfalt; terenul din jurul lui coboară spre exterior; **nu există căldare și nu e loc plat** pentru cabană (N5) | relief/cod |
| **satul pe un deal**, cu pajiști pe pante | A e **plat**: ±0,3 m pe 40 m pe ambele laturi, perete > 3 m abia la **68–86 m** | relief (N6) |
| **Poenari** lipită de sat, pe stâncă înaltă și vizibilă tot drumul | `Poenari` la **(−125, 215)**, **36,7 m STÂNGA** de axă la 0.985; ruina întreagă (28 m) intră în cadru doar de la **~190 m**: fereastra **0.775–0.900** (nu pe ultima dreaptă 0.90–0.98) | `sv_tf_fractii` (secțiunea „ferestre de vizibilitate”) |
| **ziduri mari de sprijin** pe toate fețele treptelor | **34 module** `retaining_wall_curve` la **6,8–7,2 m de axă** (lipite de asfalt), alternând laturile, pe 0.373–0.5725; **nu există module drepte** (terenul nu coboară destul lângă drepte); 20 dintre ele intră 0,11–0,18 m peste asfalt (baza gărzii) | montarea |
| **trenul** pe trecere, cu râul alături | `Trecere_nivel_A/B` la 0.798/0.8045 și `Tren` la 0.8007, **dar fără râu pe 0.775–0.845**: Oltul se întrerupe exact aici (N9) | rapele 4 și 5 nu se ating |
| **cascada** în trepte pe peretele din stânga | **nu există nod de cascadă** în `Track21.tscn`, iar **peretele din stânga e la 40–84 m** (nu la 15–30 m) (N7) | relief + cod |
| **podețul rupt** cu mașina în aer | `TrackChannel` „ParaulBalea” cu `jump` la **0.6791** (buza 0.6763 → aterizare 0.6819); mașina în aer e cursa; **nu e podeț rupt**, e un gol de 12 m cu `ChannelKicker` (portocaliu) | hazard din cod |
| **telecabina** cu 2 cabine peste lac, serpentine și pădure | **nu e montată** (nici cabina `cable_cabin_large`, nici pilonii, nici stațiile) | piesă de integrare (vezi §Fapte) |
| **oile** (30–40, albe) cu doi câini | `HerdHazard` (`OileAcPaior`, 0.4911): `sheep.glb` din Monument Valley + `sheepdog` (`zebra_ratio` 0,1) | hazard din cod |
| **utilajul galben/portocaliu** pe banda liberă, mașina roșie la semafor | `SemaforTunel` + `snowplow.glb` pe `bus_model`; `Utilaj_parcat` e alt snowplow, parcat la 8,3 m dreapta de 0.2956 | hazard din cod |
| **marea de nori** sub și în jurul bazei | `CloudSea_A/B` la 240–320 m, `dy −8`; **nu se citește** (N3) | cod `_build_horizon` |
| **ravens**, **mașinile de curse** | `raven.glb` există (Monument Valley); cursa e cod | nu e decor |

Un critic care cere una din astea a citit diorama, nu pista.

**Respectul și interdicțiile** (brief §8, regulă de design, nu opțiune):
- **ursul nu e hrănit, nu e rănit, nu e lovit „ca să sară”**: traversează și pleacă;
  indicatorul „nu hrăniți urșii” (`bear_warning_sign`) la coada lacului, cu pictogramă;
- **fără Dracula**: fără țepe, lilieci, sânge, castel gotic, „Vlad”; Poenari e o ruină
  pe o stâncă, atât;
- **fără simboluri politice** (drumul s-a construit în 1970–1974 la ordinul
  regimului), **fără loc religios** (mănăstiri, biserici, troițe, cruci);
- **fără mărci**: nimic Dacia, CFR, Top Gear, bere, caș cu etichetă; mașinile parcate
  sunt generice (`parked_car_a/b`, `motorbike`), **fără text lizibil**, fără sigle pe tren;
- în UI apare doar „Transfagarasan”; **„Bâlea”, „Vidraru”, „Poenari” nu apar** în
  nume vizibile jucătorului;
- **fără chalet tirolez**, bulbi de ceapă, Matterhorn; nu mai există `alpine_church`,
  `mountain_chalet_*`, `timber_sled`; fără vaci sau căruțe pe drum; fără oameni care
  hrănesc ursul; fără hotel de gheață; fără tren pe creastă; fără linii galbene.

**Lumina**: soare ~25° din **VNV** (`custom_sun_rotation_deg` (−25, −110, 0)), `#FFD9A8`,
energie 1,1; ambient rece `#B8CCE0` la 0,3 (umbre albastre pe zăpadă, **verzi-închise**
în molid, nu negre); o singură lumină directională, umbre dinamice (`theme_shadows`,
`shadow_distance` 90). **Nu există ciclu de zi.** Hazardele cu ceas se capturează în
fază forțată (`--cross-at`, `--signal`, `--avalanche-at`, `--herd-at`, `--train-at`);
valorile care chiar prind evenimentul sunt în §Captura.

## Ieșirea din buclă (aceeași ca la Okinawa, Fiordland, Monument Valley, Jodhpur)

Pe Serengeti 0/8 POI-uri au câștigat orb, pe Machu Picchu 0/3, pe Fiordland 0/8, pe
Okinawa 0/8. O dioramă pictată nu se bate orb de un cadru low-poly (memoria
`gauntlet-iesirea-din-bucla`). Deci:

- **judecata rămâne oarbă** (`blind_pair.py`, o planșă per rundă, A sau B, o singură
  diferență numită);
- **ieșirea din buclă e** una din: (a) criticul alege a noastră orb; (b) criticul **nu
  mai numește nicio diferență reparabilă în decorul POI-ului**; (c) criticul numește
  **aceeași diferență de două ori la rând** — atunci cauza e sub decor (relief,
  lumină, shader, clasă de textură, asset, apă) și se **oprește bucla**, cu decizia
  pusă în fața dezvoltatorului (memoria `criticul-cere-ce-zona-nu-poate-da`);
  verdictele se pun unul lângă altul;
- **acceptarea finală e verdictul dezvoltatorului la volan**, pe scena integrată, cu
  5 eșantioane pe captură (memoria `o-captura-nu-e-un-verdict`).

Locuri unde (c) e de așteptat de la început, **dacă „Problemele de nivel de pistă”
(N1–N10) nu se repară înainte**: culoarea ierbii (toate POI-urile), apa (B, C, E, G, H),
fundalul (toate), hăul (B), lacul Bâlea și terasa cabanei (E), peretele cascadei și
canalul (G), Oltul la trecere (H), valea (A). Fiecare e un buget de runde ars degeaba.

## Ce se măsoară pe scena integrată (niciodată pe worktree-ul POI-ului)

**Convenția de indici pentru Transfăgărășan: `--track=21` la TOATE uneltele.** 21 e
peste lungimea listei, deci se rezolvă ca număr de SCENĂ (`GameState.resolve_track_index`;
Track21 e indexul 14). `probe_decor` și `probe_manual` cu un număr mic ar măsura altă
pistă și ar da verde fals (memoria `probe-decor-numar-de-scena`).

Liniile de bază sunt măsurate azi (14 oct 2026), pe `ee4627af` + Zonele, înainte de orice
decor de POI. Rezultatele brute sunt rotunjite aici; unealta e cea din coloana 2.

| gardă | comandă | linia de bază / prag |
|---|---|---|
| ProbeLaneClear | `res://tools/ProbeLaneClear.tscn -- --track=21` | **3 probe blocate** (garda are baza 2 în cod și raportează „REGRESIE”): **0.200 `AnimatableBody3D`** (ursul, hit-box real 1,07 × 1,38 × 2,58 m, la +2,3 m lateral; **decizia (a) a dezvoltatorului: rămâne obstacol greu**) și **0.675 `ChannelKicker`** (h 0,4 la 4,19 m și h 1,0 la 1,62 m, săritura din G). **Baza reală a pistei = 3.** Orice raportare nouă e coliziune pe bandă; atribuie-o sau scoate piesa. Linia de bază din probă se ridică la 3 la integrare, nu o face constructorul |
| probe_decor | `--headless --path . --script res://tools/probe_decor.gd -- --track=21` | **32 materiale** (31 002 prop-uri, 585 desene, **1 244 628 triunghiuri**, 153 unice; procedural 79 prop-uri / 24 materiale / 125 778 tri; `MultiMesh neatribuit` 29 570 prop-uri / 3 materiale / 776 905 tri; `alpine_pines` 586, `canyon_rocks` 256, `megakit_plants` 155, `megakit_rocks` 148, `alpine_shrub` 109, `stirling_ledge` 34, `boulder_roller` 9, `mine_portal` 8, `torrent_chute` 3). **Ținta brief-ului era ≤ 30 (inventarul de montare raportase 30); azi 32, garda pică la 38.** Triunghiurile se raportează, nu pică. Un material nou se cere explicit în raport, cu ce cumpără vizual. **Recomandare**: ținta se mută pe ≤ 34 cu motivul scris în brief, sau coordonatorul scoate la integrare scatterul moștenit din Track09/Fiordland care nu are ce căuta aici (`stirling_ledge` 34 prop-uri, `mine_portal` 8 prop-uri cu 3 materiale, `boulder_roller` 3 materiale, `torrent_chute` 2) |
| probe_decor_overlap | `--script res://tools/probe_decor_overlap.gd -- --track=21 --manual` | **22 piese peste asfalt**: 2 × `Dam_Module_Concrete` (**0,59 m** la (104, 242) și **0,48 m** la (137, 244)) și 20 de piese a căror listă sonda o taie la 12 rânduri (cele 10 afișate sunt `Wall_Stone`, 0,11–0,18 m: zidurile `ZidC*` la ~7,0 m de axă pe o pistă cu semi 7,0). Verdictul tipărit e „PROBLEMĂ — 2 piese” (cele două de la baraj). **E linia de bază și datoria montării, nu a POI-urilor** (B pentru baraj, F pentru ziduri); 0 îngropate în altă piesă. Pe restul: 0 piese noi peste asfalt |
| probe_manual | `--script res://tools/probe_manual.gd -- --track=21` | 82 obiecte, **1 „de reparat” = `Utilaj_parcat`** („ok / IN DRUM”, 8,4 m de axă, +0,41 m peste teren). Restul „ok”: `Prometeu` −1,72 m și `Poenari` −1,50 m față de teren (bază de stâncă îngropată, **intenționat**). Notă: sonda tipărește `Identifier not found: GameState/AudioManager` în `--script` (autoload-uri) și rulează totuși tabelul |
| probe_solid | `--script res://tools/probe_solid.gd -- --track=21` | **OK**: 70 corpuri, 126 forme (hull 57, mesh 12, trunk 1); „gabaritul mașinii trece liber pe toată linia șoselei”. Obligatoriu pentru orice piesă `hull`/`mesh` lângă drum (plimbă CHIAR corpul mașinii) |
| ProbeBuried | `res://tools/ProbeBuried.tscn -- --track=21` | **0 îngropate, 31 tavane** (tunelul, portalurile, stânca), cel mai adânc +0,00 m la 0.000. „Tavane 31” e baza (nu „0 tavane” ca la Okinawa) |
| ProbeCameraSolid | `res://tools/ProbeCameraSolid.tscn -- --track=21` | **2 incidente = baza**: **0.146** `Portal_Stanca_col` (camera la (175,6; 18,3; 218,9)) și **0.676** `ChannelKicker` între mașină și cameră (la 0,1 m; camera la (−50,9; 21,6; −332,7)); 12 probe informative cu un corp la < 0,5 m de cameră. Orice incident în afara lor e camera în solid |
| ProbeLayout | `res://tools/ProbeLayout.tscn -- --track=21` | **2140,0 m**, 1069 puncte, rază minimă **14,7 m la 0.51**, pantă maximă **12,2 % la 0.27**, apropiere de sine **31,7 m la 0.43**; verdict OK. Constructorii de POI nu ating traseul |
| probe_load_time (cu fereastră) | `--rendering-driver vulkan --script res://tools/probe_load_time.gd -- --track=21` | **3,78 / 3,31 / 3,32 s** (la rece / cald / cald, RTX 3070), față de Monument Valley **5,10 / 3,78 / 3,80 s** (aceeași mașină). Brief §6: ≤ Track19 + 0,5 s |
| **ProbeRace** | `--headless --fixed-fps 60 res://tools/ProbeRace.tscn -- --mode=race --track=21 --seconds=150 --seed=N --ai=7` | **16 seed-uri (1..16), 8 mașini, 150 s**: **52 repuneri în total (0–5 pe cursă, medie 3,3)**, **toate la hazarde**: **ursul 0.189–0.198: 36 repuneri** (+ **5 `[blocaj]` la 0.197–0.198**, v ≈ 1,6–4,6 m/s), **`Portal_S`/utilajul 0.309–0.318: 10** (`bus-hit` pe verde, ejectări „perete” 44–49 m/s), **avalanșa pe ramura 1 0.388–0.392: 5**, **săritura 0.683: 1**; **46 ejectări „perete”** (35 la urs, 10 la portal, 1 la 0.69), **0 ejectări „aterizare”**, 0 `carusel`, `invers` ≤ 2,9 s, `lent` ≤ 9,5 s, în afara drumului ≤ 1,2 %, 0 ieșiri din lume; tur minim **66,6–71,3 s** (2 ture pe cursă la cei mai rapizi), tur mediu 67–95 s; coloana `0.95–1.00: ~16 m/s, ~39 % lent` e pre-grila de start, nu un defect. **Tot ce e în afara celor patru locuri e zero**: decorul nu are voie să adauge repuneri sau `[blocaj]` nicăieri altundeva (memoria `zero-repuneri-ascunde-blocajul`; distribuții, nu o rulare: Jolt e multithread, memoria `proberace-nedeterminism`) |
| ProbeRace pe felie | idem + `--slice=A,B` | A: `0.9786,1.0` apoi `0.0,0.064`; B: `0.064,0.1535`; C: `0.1535,0.252`; D: `0.252,0.3171`; E: `0.3171,0.372`; F: `0.372,0.6268`; G: `0.6268,0.7036`; H: `0.7036,0.9786` — **înainte ȘI după** orice piesă cu coliziune pe felie; distribuții pe 16 seed-uri, nu o rulare (memoria `proberace-nedeterminism`) |
| sv_tf_fractii | `res://tools/SvTfFractii.tscn` (headless) | nu e gardă; re-rulat după orice atingere de traseu/teren |

`--import` înaintea oricărei serii (memoria `import-invechit-falsifica-masuratoarea`) și
după FIECARE merge (memoria `merge-curat-scena-stricata`).

## Captura: ce comandă, pentru care POI

Din mașină, `--gamecam` (camera reală: 10 m sus, 12,5 m în spate, fov 68 — memoria
`verifica-cu-parametrii-lui`). Snapshot **cere fereastră**, nu merge `--headless`
(memoria `snapshot-nu-merge-headless`); capturile se fac **serial**, prin lacătul de GPU,
gărzile în paralel (memoria `capturile-nu-se-paralelizeaza`). **Snapshot scrie mereu
`snapshots/transfagarasan_joc.png` (cu `--eye/--look`: `transfagarasan_liber.png`):
copiază fișierul după FIECARE captură** (altfel rămâne doar ultima) și verifică că s-a
scris.

```
mkdir D:/GameDev/.render_lock || (aștepți: alt agent randează)
D:/GameDev/Godot_v4.7-stable_win64.exe --rendering-driver vulkan --path <worktree> \
    res://tools/Snapshot.tscn -- --track=21 --frac=<F> --gamecam [flaguri]
cp snapshots/transfagarasan_joc.png <destinatie>
rmdir D:/GameDev/.render_lock
```

Fracțiile sunt **pe index** (cele pe care le ia `--frac`); pe Track21 divergența
index–lungime e de cel mult **0,0011 = 2,4 m** (la 0.30), deci nu contează nicăieri.

**Valorile de flaguri care chiar prind evenimentul** (verificate pe captură, 14 oct):

| hazard | flag | valoare | ce se vede |
|---|---|---|---|
| ursul | `--cross-at=` | **5.4–6.0** (ciclu 43,4 s, perioadă 31 s; 5.4 îl are deja pe carosabil, la −2,3 m de axă, mergând) | pată maro la 30–100 m; pentru ursul ridicat/aproape pune camera la `--frac=0.1993 − 0.006` și încearcă 4.5–5.2 (n-am prins `Stand` pe captură: de verificat) |
| semaforul | `--signal=` | **`red`** (și `green`) | lampa roșie aprinsă pe stâlp, la 34 m înaintea gurii; utilajul nu apare în poză |
| avalanșa | `--avalanche-at=` | **3.5** (telegraf: bulgări și praf la capătul ramurii 1) / **5.0** (traversare, 9/9 bucăți au trecut axa) | `AvalancheHazard` la 0.4004; `--frac=0.385–0.395` |
| oile | `--herd-at=` | **4.0** (turma pe ramura a treia) | `OileAcPaior` 0.4911; `--frac=0.485`; câinii, în turmă |
| trenul | `--train-at=` | **0.20** (fereastra de traversare e **0.1125–0.285** din ciclul de 40 s: `WARN` 4,5 s, `CROSS` 6,9 s; valorile 0.30–0.75 NU prind nimic) | garnitura de 3 vagoane pe trecere; `--frac=0.790` |

**Capturile de bază (fără decor)** sunt în `docs/track_briefs/img/transfagarasan_plan/poi_inainte/`
(`<POI>_f<frac>[_hazard].png`, 1280×720, `--track=21 --frac=<F> --gamecam`, plus flagul
din tabel). Ce arată:

- **A** (0.985, 0.020, 0.050): câmpie plată galben-oliv fără nicio vale, asfalt cu linie
  crem, câțiva molizi izolați din scatterul moștenit, `Poenari` ca o piramidă gri-albăstruie
  în stânga, grinda de start în față, la orizont o apă îndepărtată;
- **B** (0.060, 0.095, 0.125): coronament cu parapet alb-roșu, **apa lacului turcoaz cu
  valuri** în stânga, turnul de priză și pasarela în stânga, **în dreapta un „bol” verde
  fără perete și cu o băltoacă la fund** (hăul nu se citește), `Prometeu` portocaliu pe
  un bolovan, portalul de stâncă la capăt;
- **C** (0.165, 0.185, 0.190 cu `--cross-at`): lacul ca o **mare** cu spumă și reflexe, mal
  îngust de iarbă, ursul mic și întunecat pe carosabil, tabla indicatoare roșie, pâlc de
  molizi pe dreapta; în fundal pisc zimțat;
- **D** (0.255, 0.285, 0.300 cu `--signal=red`, 0.312): **pășune verde** pe toți versanții
  (nicio stâncă goală, nicio zăpadă pe versant), pereții `snow_wall` albi și cenușii care
  **citesc piatră**, stâlpul cu lampa roșie, **asfalt navy în umbră** pe ultima porțiune,
  portalul de beton cu gura neagră;
- **E** (0.330, 0.352, 0.358, 0.366): în tunel doi **pereți negri plani** (șanț, nu
  tunel); la 0.352 camera e **în placa portalului** (nu judeca de aici); la 0.358–0.366
  **dezvăluirea serpentinelor funcționează** (stiva de panglici sub tine), **lacul e un
  disc turcoaz pe un versant**, fără cabană, fără mașini parcate, fără taraba;
- **F** (0.376, 0.395 `--avalanche-at=3.5`, 0.485 `--herd-at=4.0`, 0.530): panglici cu
  parapete alb-roșii și zid de piatră pal pe margine, **versant de iarbă galbenă fără
  piatră și fără zăpadă**, câțiva molizi izolați, turma ca o claie gri-albă, bolovanii
  avalanșei albi;
- **G** (0.640, 0.665, 0.690): terenul drept pe dreapta e acoperit de **poligoane
  muștar/verde închis cu margini drepte** (canalul), triunghiul portocaliu al kickerului,
  o apă îngustă în depărtare, **nicio pădure densă și nicio cascadă**;
- **H** (0.730, 0.790 `--train-at=0.20`, 0.880, 0.955): **Oltul turcoaz cu spumă ca marea**
  pe dreapta (0.73, 0.88), **absent** la trecerea la nivel (0.79), trenul roșu peste iarbă
  fără râu, pe stânga versant de iarbă; la 0.955 `Poenari` pe stânga, un iaz pe dreapta;
- **N-uri** (camere libere `--eye/--look`, în aceeași mapă): `nivel_hau_coronament`
  (`--eye=104,22,236 --look=104,-8,300`), `nivel_hau_din_vale` (`--eye=104,-14,335 --look=104,10,240`),
  `nivel_nori_A_din_C` (`--eye=203,30,74 --look=333,12,20`), `nivel_nori_B_din_baraj`
  (`--eye=140,22,239 --look=260,8,272`), `nivel_creasta_A_din_D` (`--eye=240,48,-44 --look=382,30,-62`),
  `nivel_campie_nord` (`--eye=110,55,-215 --look=110,10,-620`); vezi §Probleme.

Sunt punctul de plecare al fiecărei perechi.

| POI | frac de captură (index) | poziție (x, z) | flaguri | bară |
|---|---|---|---|---|
| A valea Argeșului | **0.985**, **0.000**, **0.020**, **0.045**, **0.060** | (−146, 245), (−115, 262), (−73, 265), (−19, 263), (13, 258) | — | `A`, `A_poenari`, `ORIZONT` la 0.985 |
| B baraj | **0.060**, **0.085**, **0.100**, **0.120**, **0.140** | (13, 258), (63, 247), (95, 238), (137, 239), (174, 219) | — | `B`, `C` (lacul) |
| C malul lacului + urs | **0.160**, **0.180**, **0.195**, **0.215**, **0.240** | (200, 186), (211, 145), (210, 114), (203, 74), (240, 36) | `--cross-at=5.4` pe 0.185–0.195 | `C`, `C_urs` |
| D valea Caprei + portal | **0.255**, **0.280**, **0.300** (`--signal=red`), **0.312**, **0.3171** | (224, 13), (224, −25), (238, −59), (220, −79), (215, −87) | `--signal=red` pe 0.295–0.312 | `D` |
| E tunel + Bâlea Lac | **0.322**, **0.340**, **0.358**, **0.366**, **0.370** | (213, −98), (206, −136), (194, −173), (181, −184), (174, −189) | — (nu pune camera pe 0.349–0.353: e în placa lui `Portal_N`) | `E`, `CREASTA`, `ORIZONT` la 0.366 |
| F serpentine | **0.376**, **0.395**, **0.440**, **0.485**, **0.530**, **0.585** | (164, −195), (123, −195), (115, −227), (137, −259), (101, −291), (130, −324) | `--avalanche-at=3.5` pe 0.385–0.395; `--herd-at=4.0` pe 0.485 | `F`, `F_oi` |
| G Bâlea Cascadă | **0.630**, **0.650**, **0.665**, **0.690**, **0.700** | (34, −329), (−9, −332), (−40, −334), (−93, −324), (−115, −318) | — | `G` |
| H defileul Oltului | **0.720**, **0.760**, **0.790**, **0.880**, **0.955** | (−146, −291), (−189, −221), (−197, −156), (−202, 36), (−177, 192) | `--train-at=0.20` pe 0.775–0.805 | `H`, `A_poenari` la 0.955 |

(pozițiile sunt citite din punctele coapte la fracția dată; verifică pe captură.)

## Fracțiile reale ale traseului (NU cele din brief §2)

Măsurate pe `Track21.tscn` la `ee4627af` cu `tools/sv_tf_fractii.gd` (headless): **2140,0 m**,
**1069 puncte coapte**, pas 2,0 m, cota drumului de la **0,0** (grila) la **+43,0** (tunel),
cota medie **+16,8**. Convenția de hartă: x est, **z sud (z = −y din brief)**, sens
**antiorar** pe plan. Brief-ul §2 dă punctele în (x, y-nord); pista are z = −y. Stânga
= offset lateral negativ, dreapta = pozitiv. Fracții pe index (cele de aici), pe lungime
diferă cu ≤ 0,0011.

| reper | brief | frac (index) | lungime | cotă | semi | poziție (x, z) |
|---|---|---|---|---|---|---|
| grila de start | A 0,97 | **0.000** | 0 m | 0,0 | 7,0 | (−115, 262), heading 106° |
| colț H→A (−40°, r~57) | | **0.9766** | 2089,5 m | +0,5 | 7,0 | (−157,9; 235,9) |
| `Poenari` | 0,84–0,94 | **0.985** (lung 0.9848) | | −1,3 (nod) | | (−125, 215), **36,7 m STÂNGA** |
| urcarea A→B (4 % → 9,3 %) | A→B 0,06 | 0.02–0.06 | 43–128 m | +1,5 → +8,6 | 7,0 | (−90, 264) → (−3, 262) |
| **coronament** (`custom_width_segments` semi 6,0) | 0,077–0,122 | **0.078–0.123** (lung 167–262 m) | 95 m | +12,0 | **6,0** | (49,6; 250,1) → (139,5; 238,9) |
| `Dam_01…06` (module de 16 m) | | 0.0814 / 0.0889 / 0.0973 / 0.1038 / 0.1113 / 0.1197 | | +12,0 | | (57,9; 247,9) … (136,6; 239,4) |
| `Dam_Turn` (turnul de priză, stânga/lac) | | 0.0973 | | +12,0 | | (88,8; 239,7) |
| `Dam_Centrala` (centrala, dreapta/hău) | | 0.1038 | | +12,0 | | (104,6; 238,2) |
| **rapa 2 = hăul** (dreapta, adâncime 40, podea −28, lățime 60, apă la −24) | | **0.074–0.128** (lung) | 160–274 m | | | |
| **rapa 0 = lacul Vidraru** (stânga, adâncime 30, podea +3, lățime 120, apă la **+7,5**) | | **0.080–0.135** (lung) | 172–290 m | | | |
| `Prometeu` | | **0.1291** | | +10,3 (nod; terenul +11,98) | | (162,0; 241,4), **13 m DREAPTA** |
| `Portal_Stanca` (portal de stâncă, 34 m lung) | C ~0,17 | **0.1384** (+ `ZoneCamera/TunelStanca` 0.1315–0.148) | | +11,6 | 7,0 | (171,4; 220,0), 1,3 m de axă |
| viraj −45° (r~51) = **capătul lui B** | B→C 0,15 | **0.1515** | 324,0 m | +13,0 | 7,0 | (193,8; 202,6) |
| rapa 1 (stânga, adânc 20, podea +3, lățime 150, **fără apă declarată**) | | 0.135–0.245 (lung) | 290–525 m | | | |
| `Semn_urs` (pictograma, 9,2 m dreapta) | | **0.1777** | | +14,9 | | (219,0; 150,8) |
| viraj −36° (r~63) | | 0.1899 | 406,0 m | +16,4 | 7,0 | (212,8; 123,9) |
| **ursul** (`HazardMarker` SLIDING, `sweep_speed` 1,2) | ~0,20 | **0.1993** (marker, pe axă) | 427 m | +17,8 | 7,0 | (206,4; 104,3) |
| viraj +70° (r~33) | | 0.2142 | 457,6 m | +19,9 | 7,0 | (203,1; 74,3) |
| 12 jaloane `snow_pole` | | **0.2498 → 0.3994** (`Jalon00 … Jalon16`) | | +27 → +38 | | la 7–8 m de axă |
| **viraj −110° (r~21)** = capătul lui C, primul ac din valea Caprei | D 0,24 | **0.2423** | 517,8 m | +25,6 | 7,0 | (239,7; 30,9) |
| viraj +119° (r~19), **panta maximă 12,0 % la 0.2750** | | **0.2666** | 570,1 m | +31,3 | 7,0 | (207,1; −5,6) |
| `Utilaj_parcat` (snowplow parcat, „IN DRUM”) | | 0.2956 | | +38,4 | | (248,1; −54,6), 8,3 m dreapta |
| viraj −96° (r~24) | | 0.2919 | 624,3 m | +37,5 | 7,0 | (240,0; −44,1) |
| `Zapada_S00…S11` / `Zapada_D00…D10` (18 module `snow_wall`) | | **0.2703 → 0.3115** | | +32 → +41 | | la 10,4–11,0 m de axă (fața la 9,75 m) |
| `Lampa` (stâlpul semaforului) | | **0.3040** | | +39,8 | | (236,5; −72,2), 7,5 m dreapta |
| **`Portal_S`** (intrarea în tunel; semi 6,0 de la 0.317) | ~0,315 | **0.3171** | 678 m | +42,1 | **6,0** | (214,3; −88,7) |
| viraj +35° (r~66) | | 0.3190 | 682,6 m | +42,1 | 6,0 | (213,6; −93,2) |
| `SemaforTunel` (nodul `TunnelSignalHazard`) | 0,315 | 0.3199 | | +42,2 | | (220,6; −96,6) |
| `Santier_tunel` (`road_works`) | | 0.3237 | | +42,3 | | (216,0; −103,2), 4,3 m dreapta |
| **`Portal_N`** (ieșirea; capătul semi 6,0) | | **0.3499** | 748 m | +43,0 | 6,0 → 7,0 | (200,1; −157,3) |
| **cota maximă** (în tunel) | | **0.3442** | 735,8 m | **+43,02** | 6,0 | (203,6; −145,4) |
| rapa 3 = **lacul Bâlea** (dreapta, adânc 5, podea +37, lățime 55, **fără apă**) | | 0.347–0.382 (lung) | 743–818 m | | | |
| `LacBalea` (disc Ø68, +40,3, mesh pe scenă) | | 0.3573 | | +40,3 | | (232,6; −193,7), **43,5 m dreapta** (9,5 → 77,5 m de axă) |
| viraj −49° (r~47) = **capătul lui E** | E→F 0,37 | **0.3686** | 789,0 m | +42,4 | 7,0 | (175,8; −188,0) |
| `ZidC01…C34` (zid de sprijin curb) | | **0.3732 → 0.5725** | | +42 → +18,7 | | la 6,8–7,2 m de axă, alternând |
| parapete (`custom_parapets`) | | **0.377 → 0.626**, cu **gol 0.488–0.498** (scurtătura, neconstruită) | 807–1340 m | | | |
| **`Avalansa`** (`HazardMarker` AVALANCHE, perioada 75 s) | ~0,40 | **0.4004** | | +38,5 | 7,0 | (110,3; −195,0) |
| **ac 1** (+144°, r~16) | ac1 | **0.4191** | 897,2 m | +37,0 | 7,0 | (80,0; −212,2) |
| **ac 2** (−144°, r~16) | ac2 | **0.4668** | 998,3 m | +31,0 | 7,0 | (164,8; −242,1) |
| **oile** (`OileAcPaior`, `HerdHazard`) | ~0,49 | **0.4911** | 1050 m | +27,8 | 7,0 | (122,3; −259,0) |
| **ac 3** (+144°, r~16; raza minimă pe pistă **14,7 m la 0.51**) | ac3 | **0.5154** | 1103,2 m | +25,0 | 7,0 | (80,2; −275,6) |
| **ac 4** (−141°, r~16) = ultimul ac | ac4 | **0.5631** | 1204,3 m | +19,0 | 7,0 | (165,0; −305,5) |
| coborârea spre G (`F jos`) | | 0.6268 | 1342 m | +14,0 | 7,0 | (38,8; −328,2) |
| **săritura** (`ParaulBalea`, `TrackChannel` jump, gap 12) | ~0,67 | **0.6791** (buza 0.6763 → aterizare 0.6819) | 1453 m | +10,8 | 7,0 | (−72,4; −328,1) |
| viraj −36° (r~64) = **capătul lui G** | G→H 0,70 | **0.7016** | 1501,5 m | +9,0 | 7,0 | (−118,1; −316,7) |
| rapa 4 = **Oltul**, partea de N (dreapta, adânc 10, podea −4, lățime 45, apă la **+3,4**) | | **0.705–0.775** (lung) | 1510–1659 m | | | |
| viraj −37° (r~62) | | 0.7465 | 1597,5 m | +7,0 | 7,0 | (−183,6; −247,3) |
| `Trecere_nivel_A` / `_B` (brațe ridicate) | ~0,80 | **0.7979 / 0.8045** | | +5,2 / +4,9 | | (−198,9; −138,9) / (−200,3; −125,0) |
| **trenul** (`TrainHazard`, `ro_train`, perioada 40 s, `half_rail` 65) | ~0,80 | **0.8007** | 1713 m | +5,0 | 7,0 | (−199,7; −131,9) |
| **FĂRĂ apă pe 0.775–0.845** (între rapele 4 și 5) | | 0.775–0.845 (≈ 150 m) | 1659–1810 m | | | trecerea la nivel e **în** acest gol |
| rapa 5 = **Oltul**, partea de S (dreapta, adânc 10, podea −5, lățime 45, apă la **−2,5**) | | **0.845–0.975** (lung) | 1810–2088 m | | | |
| viraj −40° (r~57) = **capătul lui H** | H→A 0,97 | **0.9766** | 2089,5 m | +0,5 | 7,0 | (−157,9; 235,9) |

Rază minimă a pistei **14,7 m la 0.51**; pantă maximă **12,2 % la 0.27**; separare minimă
**31,7 m la 0.43** (între ramurile serpentinei, 17,7 m de margine la margine). Centroidul (26, −62).
Hazardele cu ceas (lung): urs 427 m → semafor 686 m (**259 m**), semafor → avalanșă 856 m
(**170 m**), avalanșă → oi 1050 m (**194 m**), oi → săritură 1453 m (fără ceas), → tren 1713 m
(**660 m**), tren → urs (peste start) ≈ 854 m. Două distanțe sub 200 m (170 și 194), asumate în brief §3.

**Limitele de proprietate** (zona fiecărui POI; metadata `fractii` din `Track21.tscn` le
poartă acum; granițele sunt **virajele-colț măsurate**: colțul aparține POI-ului care se
termină cu el, ca să nu se calce două POI-uri):

| zonă | fracții (index) | lungime | în lume (x, z) | semi |
|---|---|---|---|---|
| **A** | 0.9786–1.000 + 0.000–0.064 | ~180 m | x −156…20, z 238…266 | 7,0 |
| **B** | 0.064–0.1535 (colțul r~51 de la 0.1515 e al lui B) | ~192 m | x 20…195, z 200…257 | 7,0 / **6,0 pe coronament** |
| **C** | 0.1535–0.252 (acul r~21 de la 0.2423 e al lui C) | ~211 m | x 195…240, z 15…200 | 7,0 |
| **D** | 0.252–0.3171 (se termină la gura `Portal_S`) | ~138 m | x 207…240, z −87…15 | 7,0 → 6,0 |
| **E** | 0.3171–0.372 (tunel + lac + colțul r~47 de la 0.3686) | ~118 m | x 171…215, z −191…−87 | **6,0** în tunel, 7,0 |
| **F** | 0.372–0.6268 (patru ace) | ~548 m | x 39…171, z −328…−191 | 7,0 |
| **G** | 0.6268–0.7036 (colțul r~64 de la 0.7016 e al lui G) | ~163 m | x −121…39, z −335…−315 | 7,0 |
| **H** | 0.7036–0.9786 (colțul r~57 de la 0.9766 e al lui H) | ~588 m | x −205…−121, z −315…238 | 7,0 |

**Față de brief §2** (brief vs. măsurat):

| POI | brief | măsurat | |
|---|---|---|---|
| A | 0,97 → 0,06 | 0.9786 → 0.064 (grila la 0.000) | ✓ |
| B | 0,06 → 0,15 | 0.064 → 0.1535; coronamentul 0.078–0.123 | ✓ (brief 0,077–0,122) |
| C | 0,15 → 0,24 | 0.1535 → 0.252 | se termină cu 0.012 mai târziu: acul −110° (0.2423) e al lui C |
| D | 0,24 → 0,32 | 0.252 → 0.3171 | ✓; semaforul pe stâlp la 0.3040, gura la 0.3171 |
| E | 0,32 → 0,37 | 0.3171 → 0.372 | ✓; tunelul are ~70 m, nu ~60 |
| F | 0,37 → 0,62 | 0.372 → 0.6268 | ✓; parapetele 0.377–0.626 |
| G | 0,62 → 0,70 | 0.6268 → 0.7036 | ✓; săritura 0.6791 (brief ~0,67) |
| H | 0,70 → 0,97 | 0.7036 → 0.9786 | ✓; trenul 0.8007 (brief ~0,80) |

Distanța minimă dintre drumurile POI-urilor (m, pe curba coaptă, cu granițele de mai sus; folosită
la valuri):

|  | A | B | C | D | E | F | G | H |
|---|---|---|---|---|---|---|---|---|
| **A** | | 0 | 185 | 316 | 395 | 458 | 554 | 0 |
| **B** | 0 | | 0 | 188 | 287 | 391 | 551 | 176 |
| **C** | 185 | 0 | | 2 | 104 | 215 | 393 | 353 |
| **D** | 316 | 188 | 2 | | 1 | 114 | 300 | 408 |
| **E** | 395 | 287 | 104 | 1 | | 2 | 193 | 320 |
| **F** | 458 | 391 | 215 | 114 | 2 | | 3 | 163 |
| **G** | 554 | 551 | 393 | 300 | 193 | 3 | | 0 |
| **H** | 0 | 176 | 353 | 408 | 320 | 163 | 0 | |

Cifrele 0–3 = vecini pe traseu (granița e cifrată: colțul aparține POI-ului care se termină cu el).
Bucla e un inel de 8 POI-uri, deci **A-B, B-C, C-D, D-E, E-F, F-G, G-H, H-A sunt adiacente**.
Perechile non-adiacente cu **< 150 m**: **C–E (104 m)** și **D–F (114 m)**, câte o sală de teren între ele
(D între C și E; E între D și F).

## Premise din brief găsite false (la ee4627af)

Nu sunt defecte de POI; sunt fapte despre pistă pe care constructorii trebuie să le știe înainte
să citească brief-ul §1/§2 sau diorama. Toate sunt **măsurate** pe scenă (`sv_tf_fractii.gd`, profil
lateral cu `_terrain_mesh_y`, pas 2 m până la 200 m) sau pe captură.

1. **Nu există vale: A e câmpie.** Pe A terenul lateral e **plat la cota drumului (−0,3…+0,3 m) pe
   40 m**, pe ambele laturi; peretele (> 3 m) apare abia la **68–86 m**. „Valea Argeșului” cu versanți
   împăduriți nu e relief: se face din **rânduri de fag** la 15–40 m și din orizont (N6).
2. **Tunelurile scurte din C nu sunt în C și nu sunt două.** Un singur `Portal_Stanca` la **0.1384**
   (în B, la 1,3 m de axă, 34 m lung, camera la 0.146 e baza ProbeCameraSolid); al doilea, din dioramă și
   din brief (~0,17 / „C tunele” la 0.1871), **nu există**.
3. **Hăul barajului nu se citește de pe coronament.** Rapa 2 are fundul la **−28** și lățimea 60; la
   10–60 m dreapta terenul e la −27…−40 m față de drum, dar parapetul (1,1 m) și camera (10 m sus, 28,7°
   în jos) arată un **bol verde cu o băltoacă**, iar peretele opus e o pantă lină de iarbă care urcă la +1,5
   m la 100 m (N4). Fața din aval a barajului (GLB, 40 m) apare doar ca dungă sub coronament, de la
   stânga spre dreapta, doar din vale.
4. **Lacul Vidraru nu e un mal plat.** Pe baraj apa e la **2 m de margine, 4,5 m sub drum** (+7,5);
   pe C (0.16–0.22) **apa la 10–16 m, cu cădere > 3 m la 6–8 m** (lacul e **7–15 m sub drum**, mal îngust
   de iarbă ca o terasă). Rapa 1 n-are apă declarată; apa din C vine totuși din celulele rapei 0.
5. **Valea Caprei nu e „zigzag larg”.** Sunt **trei ace** (−110°, +119°, −96°) de **r 19–24 m**, pante de
   **10–12 %** între ele; terenul e **asimetric** (perete +11…+23 m la 20–40 m pe o latură, cădere
   −7…−10 pe cealaltă) și **verde pe toți versanții** (N1). Stâna din brief („D stână” (180, 5)) cade la
   **27 m** de drum, în interiorul acelor.
6. **Semaforul nu e pe gura tunelului.** Stâlpul (`Lampa`) e la **0.3040**, la 7,5 m dreapta, **34 m
   înaintea gurii** (0.3171); utilajul parcat (`Utilaj_parcat`, 0.2956) e la 8,3 m dreapta și **sonda îl
   marchează „IN DRUM”**; **ProbeRace** are ejectări la `Portal_S` (0.309–0.318) din coliziunea cu
   utilajul care iese pe verde.
7. **Tunelul e un șanț, nu un tunel.** Între portaluri (**0.3171–0.3499, ~70 m**) pereții sunt doi pereți
   negri plani (relief `MasivTunel`), fără tavan vizibil din cameră; `ProbeBuried` numără 31 de tavane;
   interiorul nu se decorează (E poate ține doar portalurile și `road_works`).
8. **Lacul Bâlea nu e într-o căldare și nu lasă loc de cabană.** Discul (R 34, +40,3) începe la **9,5 m
   de axă**; între asfalt (6,2 m) și disc rămân **3 m**. În stânga, perete **+2,3 m la 10 m, +17 m la 20 m**.
   **Nu există nicăieri la E un platou plat de ~30 × 30 m** pentru cabană (13 × 10 m), 8–10 mașini, 4
   tarabe (N5).
9. **Serpentinele au 32 m între ramuri, dar fâșia dintre ele e de ~18 m de iarbă între parapete**
   (separare minimă 31,7 m; asfalt 14 m). Zidurile de sprijin (34 de module, doar curbe) stau **lipite de
   marginea asfaltului pe o parte a fiecărei ramuri**, nu pe fața fiecărei trepte. **Scurtătura ciobanilor**
   (`TrackBranch`, brief §3.1.4) **nu există în scenă** (o singură rută); există doar golul din
   parapet **0.488–0.498**.
10. **G nu are perete de cascadă la stânga.** Pe 0.63–0.70 pe stânga terenul urcă > 3 m abia la **40–84 m**
    (+15…+21 m la 80 m); pe dreapta la 84–134 m. **Nu există nod `WaterfallVisual`/`WaterfallHazard`** în
    `Track21.tscn`: cascada „procedurală” din brief §5.3 nu e construită (N7).
11. **Oltul nu e continuu.** Apa pe dreapta există doar în rapa 4 (**0.705–0.775**, la 10–14 m de margine) și
    rapa 5 (**0.845–0.975**, la 10–12 m); **pe 0.775–0.845 (≈ 150 m) nu e apă deloc**, iar acolo stau
    trecerea la nivel și trenul, pe iarbă plată. Peretele de defileu pe stânga e abia la 16–58 m (0.80–0.88:
    +26/+22 m la 40 m, +7/+5 m la 20 m) (N9).
12. **Poenari nu e „în stânga-față pe ultima dreaptă”.** Întreagă (creștet 28 m peste nod) e în cadru
    **numai pe 0.775–0.900**; pe 0.90–0.98 vârful iese din cadru (plafonul camerei: 10 + 0,092 · d m). La
    start (0.985) e la 36,7 m STÂNGA și apare ca o piramidă gri-albăstruie (clasa `tf_stone`), cu
    nodul **1,5 m sub teren** (bază îngropată, intenționat).
13. **Scatterul moștenit e încă activ.** 586 `alpine_pines` (molid conic, 5–13 m, bun), 256 `canyon_rocks`
    (pe `tf_schist`), 155 `megakit_plants`, 148 `megakit_rocks`, 109 `alpine_shrub`, 34 **`stirling_ledge`**
    (Fiordland), 9 `boulder_roller`, 8 `mine_portal`, 3 `torrent_chute`, 29 570 de prop-uri MultiMesh:
    vin din tema `alpine` copiată. Decizia „ce rămâne” e a integrării (`track_decor.gd` nu e al
    constructorilor); până atunci capturile vor avea molizi izolați pe iarbă, bolovani de canion și
    ziduri `stirling_ledge`.
14. **`--train-at` din documentație nu prinde trenul.** Fereastra de traversare e **0.1125–0.285** din ciclul
    de 40 s (nu 0.55, ca la pistele cu ciclu de 18 s). Valorile 0.30–0.75 dau poza fără tren.
15. **Hazardele dau toată linia de bază a ProbeRace.** Vezi tabelul ProbeRace: ursul (0.189–0.198),
    utilajul de la `Portal_S` (0.309–0.318), avalanșa pe ramura 1 (0.388–0.392) și săritura (0.683).
    Decorul **nu are voie să adauge nimic** în afara lor (memoria `zero-repuneri-ascunde-blocajul`).

## Fapte din fundație și montare (ramura `transfagarasan/montare`, `ee4627af`)

- **Kitul e plasabil:** 36 GLB în `assets/models/transfagarasan/` (`buildings`, `structures`,
  `rocks`, `plants`, `props`, `animals`, `vehicles`, `effects`); clase pe tema `transfagarasan`:
  `tf_schist`, `tf_stone`, `tf_jneapan`, `tf_beech`, `tf_bloom`, plus `snow`, `concrete`
  existente; tencuiala pe atlas (clasa `plaster` ieșea bej-maronie); tabla argintie, tabla ruginie,
  trunchiul fagului și blana ursului sunt rezolvate prin **remapare de slot** (`SLOT_REMAP_BY_THEME`),
  nu prin clasă. **Nu comite niciun `.glb.import` regenerat local** (memoria
  `textura-noua-import-mipmaps`); în acest worktree `.import`-urile sunt neurmărite.
- **Piese montate acum, care NU se mută** (nodurile din `DecorManual`, în grupurile proprii):
  - `ZonaTunel`: `Portal_S` (0.3171), `Portal_N` (0.3499), `Santier_tunel` (`road_works`, 0.3237) —
    coliziune `mesh`, `camera_blocker`; golul portalului Bâlea **14,85 × 7,40 m**;
  - `ZonaBaraj`: `Dam_01…06` + `Dam_Turn`, `Dam_Centrala` (turn și centrală cu transformul modulului
    lângă care stau), coliziune `mesh` (trimesh-ul dă parapetul 1,1 m și peretele din aval);
  - `ZonaZiduri`: `ZidC01…C34` (`retaining_wall_curve`, `hull`);
  - `ZonaZapada`: 18 × `snow_wall` (A 4,0 m / B 3,0 m, `hull`) + 12 × `snow_pole`;
  - `ZonaRepere`: `Prometeu`, `Portal_Stanca` (golul 15,40 × 7,60 m), `Semn_urs`, `Poenari`,
    `Trecere_nivel_A/B`;
  - `Utilaj_parcat` direct sub `DecorManual` (snowplow, „IN DRUM”, 8,3 m dreapta);
  - `LacBalea` (mesh disc), `ZoneCamera/TunelStanca`, `Peaks/{MasivTunel, CreastaVest, CreastaCentru}`;
  - hazardele (`Hazarduri/*`): `Urs`, `SemaforTunel`(+`Lampa`), `Avalansa`, `OileAcPaior`, `Tren`,
    `ParaulBalea`. **Nu se ating.**
- **Nu există încă în scenă** (de pus de POI-uri): casele din Argeș, stâna, cabanele (Lac, Cascadă),
  tarabele, mașinile parcate, motocicletele, aflorimentele, grohotișurile, plantele (fag, jneapăn, bujor,
  afin), `rock_tunnel_portal` al doilea, stațiile și cabinele telecabinei, `bear_warning_sign` suplimentare,
  cascada, orice vegetație în masă proprie kitului.
- **Mutarea pieselor provizorii:** nu există piese provizorii de mutat (grupurile `Zona*` existente
  sunt ale montării și rămân; nodurile `ZonaA…ZonaH` de decor sunt separate, goale, sub `DecorManual`).
  **`Utilaj_parcat`** e singura piesă „de reparat” (garda o marchează): se mută la ≥ 12 m de axă, **de
  către E sau D** (cine pornește primul), după ce se confirmă că nu stă pe banda de coadă a semaforului.
- **Zonele goale `ZonaA … ZonaH`** sunt în `Track21.tscn` sub `DecorManual` (`metadata/fractii` = fracțiile
  reale de mai sus). **Nu s-au pus `ext_resource`-uri noi în antet** (sunt 23, deschise de fundație și montare): fiecare
  constructor adaugă `ext_resource`-urile lui în blocul propriu, cu `id` prefixat de litera zonei (`a_…`,
  `b_…`), iar coordonatorul le rezolvă mecanic la integrare (concatenare). Hazardele (`Hazarduri/*`) și
  proprietățile rădăcină (`custom_ravines`, `custom_ravine_*`, `custom_parapets`, `custom_width_segments`)
  **nu se ating**; dacă o problemă de nivel cere schimbarea lor, o face coordonatorul (vezi N-urile).
- **Relief:** `Peaks` (3 marker-i: `MasivTunel` R160 +85, `CreastaVest` R200 +105, `CreastaCentru` R140
  +92), cele 6 rape, `LacBalea`. **Treptele și zidurile nu sunt teren.**
- **Stare la oprire a kitului** (inventarele pe grupe): zăpada portalului Bâlea rămâne rev. 2 („lespezi
  stratificate” din cameră, acceptabil); ursul ridicat are trunchi cilindric; Poenari de aproape e trunchi
  de con cu contraforturi (de la 190 m și 50 m citește ruină pe stâncă); `snow_wall` din cuburi stratificate
  (rev. a fost refăcut ca straturi, dar în D citește „piatră albă lumpy”: vezi N1); beech_tree_a are trunchi
  întunecat prin remapare; turnul de priză citește mic; Prometeu are poza frontală simetrică; cabana Bâlea Lac
  are coama la 13,67 m; **creasta Făgărașului (`FagarasRidge_*`) e provizorie** (citește lanț muntos dar
  „prea Dolomiți”), norii (`CloudSea_*`) la fel; fundalul nu a convers în 5 runde.
- **Orizontul:** `transfagarasan_horizon.glb`, **6/6 siluete** (0 cu degajare relaxată): 3 creste la 200–330 m
  (E/NE/SE), 2 nori la 240–320 m (`dy −8`), 1 câmpie la 280–340 m (N, `dy 0`).
- **Cifrele de plecare** (scena de azi) sunt în tabelul gărzilor de mai sus.

## Piesele kitului: unde merg, cu cotele lor

(Cote din `transfagarasan_inventory_*.md`, măsurate din GLB; X × Y × Z-sus, m. „Față” = +Y Blender = −Z Godot:
**derivă rotația cu produs scalar, nu o ghici**, memoriile `rotatii-in-builder-semnul`,
`azimut-blender-vs-godot`.)

| piesă | cote | coliziune (`PROP_COLLISION`) | merge la |
|---|---|---|---|
| `buildings/arges_house_a` | 10,4 × 11,4 × 7,2 (casă 9 × 7 + prispă 1,6) | hull | **A** (sat; 6–8) |
| `buildings/arges_house_b` | 13,0 × 12,1 × 6,8 (casă 6 × 8 + șură 5 × 4) | hull | **A** (sat; 5–7) |
| `buildings/stana` | colibă 4 × 5 (coamă 3,2) + țarc 14,35 × 10,35 (gard 1,2–1,4) | hull | **D** (1–2) |
| `buildings/cabana_balea_lac` | 13 × 10, coamă 13,7, bbox 14,2 × 16,4 × 15,0 (scara) | hull | **E** (1) |
| `buildings/cabana_balea_cascada` | casă 12 × 9 + anexă L 6 × 5, bbox 18,9 × 11,9 × 8,8; tablă pe `LARCH_RUST` | hull | **G** (1) |
| `props/souvenir_stall` | 3,5 × 2,0 × 2,8 | hull | **E** (4) |
| `vehicles/parked_car_a` | 2,20 × 1,63 × 3,81 | hull | **E** (4–5) |
| `vehicles/parked_car_b` | 2,20 × 2,24 × 4,36 | hull | **E** (4–5) |
| `vehicles/motorbike` | 0,97 × 1,35 × 2,19 | hull | **E** (4) |
| `vehicles/ro_train` | loco 10,8 + bagaje 5,0 + 3 vagoane 8,3 (garnitura ~45,5 m) | none (hazard) | **nu se pune** (e pe `Tren`) |
| `vehicles/cable_cabin_large` | corp 4,2 × 3,3 × 3,4 + cărucior 3,0 × 4,0 × 1,4 | none | **integrare** (linia E→G) |
| `rocks/schist_outcrop_a/b/c` | 6,4 × 6,8 × 6,0 / 6,9 × 8,9 × 3,5 / 4,0 × 5,0 × 7,9 | hull | **B, C, D, E, F, H** (15–20) |
| `rocks/scree_cone` | 13,5 × 6,8 × 4,1 (con cu o latură plană) | none | **D, E, F, H** (8) |
| `plants/beech_tree_a/b` | 10,3 × 10,7 × 11,6 / 10,0 × 6,9 × 10,3 | trunk | **A, B, C** (150+; MultiMesh) |
| `plants/jneapan_a/b` | 4,1 × 3,9 × 1,2 / 3,3 × 2,7 × 1,35 | none | **D, E, F** (80+, pâlcuri) |
| `plants/bujor_de_munte` | 1,4 × 1,3 × 0,64 | none | **D, E, F** (30+ petice) |
| `plants/afin` | 0,85 × 0,93 × 0,5 | none | **D, E, F** (la pâlcuri de jneapăn) |
| `animals/sheepdog` | 0,67 × 1,32 × 2,13 | none | (în turmă, hazard) |
| `animals/brown_bear` | 2,58 lung, 1,38 greabăn, 2,91 ridicat | none | (hazard) |
| `props/bear_warning_sign` | 1,2 × 0,6 × 2,5 | trunk | C (există 1; max 1 în plus la coada lacului) |
| `props/snow_pole`, `snow_wall`, `road_works`, `level_crossing`, `prometheus_statue`, `structures/*` | montate | | **nu se atinge** |
| **kit alpin refolosit** | | | |
| `props/cow` (animat, 2,6 m) | | hull | **A** (4–5, în pajiște, nu pe drum) |
| `vehicles/hay_cart`, `props/hay_bale`, `props/wood_stack`, `structures/wooden_fence` | 0,8–2,5 / 1,2 m | | **A** (stoguri, căruță, garduri), **D** (țarcul stânei folosește propriul gard) |
| `buildings/cable_car_station` | 14 × 8 × 8 | | **E** (sus), **G** (jos) |
| `structures/cable_car_pylon` | ~18 | | **integrare** (linia telecabinei) |
| `scatter/snow_patch` | 5 × 5 × 0,2 | none | **E, F** (20+ petice pe versantul nordic) |
| `trees/alpine_pines` (molid, 5–13 m) | | trunk | **G, H** (250+; MultiMesh), **D** (rar) |
| `plants/alpine_shrub`, `flowers/flower_cluster` | 1,2 / 0,6 | none | umplutură de pajiște (E, F) |
| `rocks/canyon_rocks`, `rock_large` (pe `tf_schist`) | S/M/L | | bolovani de grohotiș |
| `rocks/mountain_peak` (100 × 80 × 80, pe `tf_schist`) | | | **NU** (citește deal verde, N1) |
| `structures/stream_bridge` | 18 × 5 × 3 | | G (podețul rupt: doar o jumătate pe mal, dacă la volan se vrea) |
| `vehicles/snowplow` | 5 × 2,2 × 2,3 | | `Utilaj_parcat` (montat), utilajul din tunel (hazard) |
| `monumentvalley/animals/raven` | | none | creasta, 3–5 (umplutură) |

## Contractele per POI

Fiecare: **ce se vede în decupaj** (obligația vizuală) + **cifre alocate** (din brief §9, prompt:
„DENSITY”, rotunjite pe lungimea reală) + **piesele** + **ce e lateral** (măsurat) + **densitatea
lângă drum** pe benzi (distanță de la MARGINEA asfaltului: 0–10 / 10–30 / 30–60 m) + **ce e interzis**
+ **gărzile** + **capturile**. Cifrele totale pe pistă (brief §9): **150+ fagi** (valea A–B–C), **250+
molizi** (G și pereții defileului H), **80+ pâlcuri de jneapăn** (D și F), **30+ petice de bujor**,
**15–20 aflorimente de șist**, **8 conuri de grohotiș**, **20+ petice de zăpadă** pe versantul nordic,
**12–15 case** (A), **4–5 vaci**, **8–10 mașini + 4 motociclete + 4 tarabe** (E), stâna cu țarc, stâlpi
de electricitate în vale (nu există piesă: proxy `wood_stack` verticalizat nu; **sar**).

### Reguli comune

- **Banda liberă:** nimic cu coliziune la < 2,5 m de MARGINEA asfaltului; ProbeLaneClear cere banda
  (semilățime + 0,5 m) liberă. Nimic cu prag > 0,3 m pe bandă (memoria `suprafete-cu-goluri-si-praguri`).
  Semilățimea: **A/C/D/F/G/H 7,0, B 6,0 pe coronament (0.078–0.123), E 6,0 în tunel**. Parapetele F
  (beton alb-roșu 1,1 m, corp `Parapet` trimesh) stau la 0,25 m de margine: **decorul stă dincolo de ele**.
- **Gabaritul camerei:** camera stă 10 m sus, 12,5 m în spate; ce trece peste drum (portalurile, linia
  telecabinei) cere golul măsurat ca GOL pe gabaritul caroseriei și al camerei (memoriile
  `cota-de-contract-se-masoara-ca-gol`, `golul-se-masoara-pe-fereastra-lui`). Înălțimea vizibilă la
  distanța d e 10 + 0,092·d m peste cota drumului (de aceea Poenari de 28 m cere ≥ 190 m).
- **Piese în masă:** peste ~1000 de piese **MultiMesh feliat**, nu noduri (memoria
  `decor-in-masa-cere-multimesh`; scatterul curent are deja 29 570 prop-uri MultiMesh); `DecorManual` =
  piesele hero și primul rând cu coliziune; vegetația în masă (fag, molid, jneapăn, bujor, afin, petice de
  zăpadă) în MultiMesh. Costul vegetației: piese = lungime/pas, apoi probe (memoria `vegetatie-cost-pe-pas`).
  Instanțele MultiMesh nu se citesc în `--headless`: verifică pe captură/`ProbeMasca`.
- **Generator de .tscn din cod pe teren real** (memoria `decor-manual-din-cod`): `DecorManual` e sursa de
  adevăr, nu codul; piesele sunt noduri în `.tscn` pe tot parcursul, cu `_terrain_mesh_y` pentru cotă
  (memoria `terrain-mesh-y-extrapoleaza`: nu așeza pe extrapolare); corpul fizic vine automat din
  `world_prop` (`probe_solid` plimbă gabaritul). Un `.tscn` editat de mână nu se rescrie din cod (memoria
  `tscn-editat-de-mana-nu-se-rescrie`): verifică `git status` înainte; editorul Godot deschis rescrie
  `.tscn` (memoria `editor-godot-deschis-rescrie-tscn`); comentariile `#` între proprietăți taie parserul.
- **Aranjamentul bate numărul** (memoria `aranjamentul-bate-numarul`): nu grilă, jitter ≥ 0,5 din pas, yaw
  variat, grupări de 2–3, **densitate care crește spre drum**; bujorul **doar în petice**, accentul viu;
  vegetația **în etaje de altitudine, în pâlcuri, niciodată uniformă** (fag jos, molid la mijloc, jneapăn
  deasupra liniei pădurii, pajiște deasupra).
- **Materiale:** ținta brief ≤ 30 e **depășită de azi (32)**, garda pică la 38 (§Garzi): fiecare constructor
  raportează ce materiale NOI adaugă (clase, tente), coordonatorul însumează; piesele kitului folosesc clasele
  din temă; tenta de clasă se decide la integrare (memoria `tenta-de-clasa-se-decide-la-integrare`). Un
  asset nu aduce niciodată texturi proprii (CLAUDE.md). **Culoarea se măsoară în joc, după remap și după
  lumină** (memoria `monocromia-se-masoara-dupa-remap`): `tf_schist` trebuie să ajungă ~`#7E8478`.
- **Nimic peste asfalt** (`probe_decor_overlap`: 0 piese noi peste baza de 22), nimic îngropat în altă piesă
  (regula de 55 % din cutie).
- **Capturi serial** (lacătul de GPU), **gărzi în paralel**; copiază `snapshots/transfagarasan_joc.png`
  după fiecare.
- **Interdicții de conținut** (brief §8): vezi mai sus (urs, Dracula, politică, religie, mărci, text).
- **Nu atinge** GLB-uri, `.glb.import`, `track.gd` / `track_decor.gd` / `track_from_path.gd` / `world_prop.gd`,
  traseul, `Hazarduri/*`, `custom_*` din rădăcină, grupurile `Zona{Tunel,Baraj,Ziduri,Zapada,Repere}`.
- **Plafonul de proprietate:** doar nodurile din zona proprie (`DecorManual/Zona<litera>`).
- **Atenție la `_terrain_mesh_y` pe versant**: pe F și D terenul alternează între ramuri; o piesă pusă
  „la 20 m de drum” poate sta pe ramura de jos sau pe cea de sus (memoria `pista-peste-pista`): cota se
  ia de la teren, nu de la drum, și se verifică pe captură din mașină.

### A — Valea Argeșului (0.9786–1.000 + 0.000–0.064; semi 7,0)

Din decupaj (`A`, `A_poenari`, `ORIZONT`): **satul** de 12–15 case cu **acoperiș de tablă** (argintiu, roșu,
verde-gri) și prispă, **garduri de lemn**, **stoguri de fân**, **căruță**, **4–5 vaci** pe pajiște, **drum de
pământ** printre case (nu pe pista noastră), **livadă**; **Poenari** = ruină de cărămidă și piatră pe un colț
de stâncă **gri-verzuie cu iarbă pe creștet**, **fag** la poale, râul jos; **molizi și fagi** de jur împrejur,
molizii în pâlcuri; cer cu nori joși la orizont.

Lateral (măsurat): **plat −0,3…+0,3 m pe 40 m, ambele laturi**; perete > 3 m la **68–86 m**; **fără apă** pe 200 m;
`Poenari` la 36,7 m stânga (0.985). **Terenul la 80 m e +3…+6 m** (rampa spre interior): satul se așază **pe
plat, la 12–60 m**, nu pe pantă. Pe 0.975 DREAPTA e +13 m la 100 m (versant), STÂNGA +7 m.

Cifre alocate: **12–15 case** (arges_house_a/b), **5–7 stoguri** + 1 `hay_cart` + 8 `wood_stack`, **4–5 `cow`**
(la ≥ 15 m de axă, în gard), **~70 fagi** (A; restul în B și C), 8–10 molizi izolați, **gard de lemn** pe
~120 m (`wooden_fence`), 2 aflorimente (`schist_outcrop`) lângă Poenari, **~12 petice de bujor** nu (cota lor e
sus: aici doar flori de pajiște `flower_cluster` ~15). **`Poenari` rămâne** (montat); i se adaugă doar fagi la
poale și iarbă; **nu se mută** (plafon: vârful trebuie să intre sub plafonul cadrului de la ~190 m).

Piese: `arges_house_a/b`, `beech_tree_a/b`, `cow`, `hay_cart`, `hay_bale`, `wood_stack`, `wooden_fence`,
`schist_outcrop_a/b/c`, `flower_cluster`, `alpine_pines` (rar). Coliziune: casele `hull`, fagii `trunk`, vacile
`hull` (cum sunt în tabel), gardurile `hull` jos, stogurile nu.

Densitate: **0–10 m:** pajiște scurtă, 1–2 stâlpi de lemn, tufe mici (nimic cu coliziune la < 2,5 m);
**10–30 m:** gardul, primul rând de case (fațada spre drum), fagi în pâlcuri de 3–5; **30–60 m:** al doilea rând de
case, livada (fagi rari), stogurile, vacile, molizii în depărtare.

Interzis: **grila (0.000, (−115, 262)) liberă pe 30 m în față și 15 m lateral** (poarta de start e o
`start_gate` din temă); **nimic cu coliziune pe banda de start**; **corpuri cinematice atribuite aproape de
grilă** (memoria `corp-cinematic-aparut-in-masina`: vacile statice, nu `AnimatableBody3D`); vaci sau căruțe
**pe drum**; casă cu balcon sculptat (nu există); biserică, troiță, cruce; **Dracula/gotic la Poenari**;
nimic în **culoarul de repunere al grilei**. **A nu are baraj, lac sau tunel.** `Poenari` nu primește
lumini, flamuri, steaguri.

Gărzi: ProbeLaneClear (baza 3), probe_solid, probe_manual (`Utilaj_parcat` e baza 1, nu al lui A),
probe_decor (materiale: baza 32), probe_decor_overlap (baza 22, nu a lui A), ProbeCameraSolid (baza 2),
ProbeRace `--slice=0.9786,1.0` + `--slice=0.0,0.064` (16 seed-uri; baza: **0 repuneri**, pre-grila nu se
judecă). Capturi: 0.985, 0.000, 0.020, 0.045, 0.060 vs `A` + `A_poenari`; `ORIZONT` la 0.985.

Capcana: relieful plat (N6): fără rânduri de fagi la 15–40 m și un orizont ridicat, satul citește „câmp cu
case”; `ceata-in-familia-solului`; clasa `tf_stone` face Poenari albastră (măsoară în joc).

### B — Barajul (0.064–0.1535; semi 7,0 → 6,0 pe coronament 0.078–0.123)

Din decupaj (`B`, `C` pentru lac): **zidul de beton gri cald** cu rosturi verticale, **parapet alb-roșu**
continuu pe coronament, **turn de priză** pe partea lacului, **centrala** la picior cu apă spumegând,
**Prometeu** (bronz, fulger) pe un pinten de stâncă în dreapta-sus, **lacul verde-închis** în spatele
coronamentului; **hăul** cu stânci de șist și molizi, **râul** jos.

Lateral (măsurat): pe coronament **STÂNGA** apă la **2 m de margine, 4,5 m sub drum** (lac `+7,5`), mal îngust;
**DREAPTA** cădere > 3 m la **2 m de margine**, fundul la **−33…−40 m** față de drum (râu la −24 absolut) pe
10–60 m, apoi **+1,5…+2,6 m la 100 m** (peretele opus e o pantă lină, nu un zid). Înainte de coronament
(0.064–0.078): plat ±0,6 m pe 40 m, perete > 3 m la 84–94 m. Pe 0.130–0.145: dreapta plat, stânga lacul la
**4–12 m**.

Cifre alocate: **3 aflorimente de șist** la capătul de est (pintenul lui Prometeu, 0.125–0.135, în dreapta,
**la ≥ 10 m de axă**), 1 con de grohotiș pe versantul dinspre lac, **~40 fagi** pe versanții de la 0.064–0.078 și
0.130–0.1535, **8 molizi** pe pintenul din dreapta, 6 petice de iarbă/flori pe taluz; **zero** piese pe coronament
(parapetul și baza barajului sunt montate). `Prometeu` și `Dam_*` **nu se mută**.

Piese: `schist_outcrop_a/b/c`, `scree_cone`, `beech_tree_a/b`, `alpine_pines`, `afin`/`jneapan` (taluz).
Coliziune: aflorimentele `hull`, fagii `trunk`.

Densitate: **0–10 m:** pe coronament nimic; la rampă iarbă și 1–2 bolovani la ≥ 2,5 m; **10–30 m:** stânci
pe pintenul din dreapta, molizi izolați; **30–60 m:** versanții împăduriți (fag jos, molid sus).

Interzis: **nimic pe coronament** și **nimic care ascunde fața din aval** (dreapta, 0.080–0.128, la 6–40 m);
nu se pun construcții în hău; **nu se mută** `Prometeu` sau modulele; **relieful hăului** (rapa 2, rapa 0)
**nu se atinge** de POI: cerut „hău mai adânc / perete opus” = **(c)** (N4); fără text, fără mărci pe
centrală; **datoria montării** (2 × `Dam_Module_Concrete` 0,48–0,59 m peste asfalt) o rezolvă coordonatorul.

Gărzi: **ProbeRace `--slice=0.064,0.1535` pe 16 seed-uri înainte și după** (baza: **0 repuneri**),
ProbeLaneClear (baza 3), **ProbeCameraSolid** (baza include 0.146 `Portal_Stanca_col`), probe_solid, ProbeBuried,
probe_decor, probe_decor_overlap (baza 22, 2 de la baraj), probe_manual. Capturi: 0.060, 0.085, 0.100, 0.120,
0.140 vs `B` (+ `C` pentru lac); plus camerele libere `nivel_hau_coronament` / `nivel_hau_din_vale` (în
`poi_inainte/`).

Capcana: memoriile `umarul-ingust-ascunde-caderea` (verifică **unghiul** hăului din cameră, nu adâncimea),
`rapa-cu-latime-reteza-relieful`, `masoara-inainte-nu-langa`, `caster-departat-fura-umbra`.

### C — Malul lacului și ursul (0.1535–0.252; semi 7,0)

Din decupaj (`C`, `C_urs`): **ursul brun ridicat în două labe** la marginea pădurii, **două portaluri scurte de
stâncă brută** (fără căptușeală), **pinteni de șist cu iarbă și molizi**, **lacul verde-închis** pe stânga,
drum pe mal cu **fagi** pe dreapta, indicator cu pictograma urs.

Lateral (măsurat): **STÂNGA apa la 10–16 m de margine, cădere > 3 m la 6–8 m** (lacul 7–15 m sub drum), la 0.22
perete +8 m la 80 m; **DREAPTA plat −0,3…+0,6 m pe 20 m, apoi +2…+5 m** (0.20), perete > 3 m la 50 m (0.20) /
98 m (0.16) sau **cădere** −4…−5 m la 40–80 m (0.22–0.235). Ursul e **pe axă** (0.1993, lat 0,1 m) și are hit-box
real; `Semn_urs` la 9,2 m dreapta (0.1777). **Portalul de stâncă din dioramă e la 0.1384 (în B); al doilea nu
există.**

Cifre alocate: **~40 fagi** pe dreapta (10–60 m), 3 aflorimente de șist (pinteni), 2 conuri de grohotiș,
**12 molizi** (pâlcuri de 3–4, nu aliniați), jneapăn nu (altitudinea nu e încă acolo), 8 petice de flori; **al
doilea `rock_tunnel_portal` la ~0.187** (waypoint „C tunele”, (214, 130)) **doar dacă** coordonatorul îl aprobă
(cere masă de teren peste drum + `ZoneCamera` + ProbeCameraSolid; **nu e decizia constructorului**).

Piese: `beech_tree_a/b`, `schist_outcrop_a/b/c`, `scree_cone`, `alpine_pines`, `bear_warning_sign` (cel montat
rămâne), `afin`. Coliziune: aflorimentele `hull`, fagii `trunk`.

Densitate: **0–10 m:** pe stânga nimic (mal îngust, cădere), pe dreapta iarbă și tufe joase; **10–30 m:** fagi, molizi
și aflorimente pe dreapta; **30–60 m:** pădurea de fag, pintenii.

Interzis: **nimic în culoarul ursului** (`Urs` traversează de la dreapta la stânga pe 0.1993, ±12 m pe axă: nimic cu
coliziune la < 8 m de axă pe 0.185–0.205); **ursul nu se hrănește**: fără mâncare, fără oameni lângă el; nimic care
ascunde lacul din cameră pe stânga (0.16–0.22) și nimic pe malul lacului la < 3 m de margine; **relieful
(rapa 1) și apa nu se ating** (apa citită ca „mare” = N2, **(c)**); fără Dracula.

Gărzi: **ProbeRace `--slice=0.1535,0.252` pe 16 seed-uri** (**baza: toate repunerile la urs 0.189–0.198 și 11
`[blocaj]`/ejectări „perete” la 0.198**; decorul adaugă **zero**, comparați pe distribuții), ProbeLaneClear
(0.200 = ursul), ProbeCameraSolid, probe_solid, ProbeBuried, probe_decor, probe_decor_overlap. Capturi: 0.160,
0.180, 0.195 (`--cross-at=5.4`), 0.215, 0.240 vs `C` + `C_urs`.

Capcana: `obstacol-pe-drum-poate-fi-gimmick` (AI-ul nu vede decorul static; ursul **nu** e decor), `reperul-se-vede-pe-patru-axe`
(ursul se vede din 0.17–0.198, la 10–90 m), `franare-de-coada-blocaj-reciproc`.

### D — Valea Caprei și portalul (0.252–0.3171; semi 7,0 → 6,0)

Din decupaj (`D`): **zăpadă veche** pe versantul din stânga și între pereții de la portal (**strat murdar, umbre
albastre**), **portalul de beton plat** între pereți de zăpadă, **semaforul pe stâlp cu consolă** (roșu), **utilajul
portocaliu** și o mașină roșie la coadă, **linia albă de oprire**, **șist gri-verzui cu fețe luminate** deasupra,
**molizi și jneapăn la poale**, stâlpi alb-roșii; în fundal marginea căldării.

Lateral (măsurat): **acele −110°/+119°/−96°**; teren **asimetric**: 0.25 STÂNGA apă la 76 m / cad 12, perete DR 20 m (+10 m la
80 m); 0.27 STÂNGA plat până la 40 m, perete > 3 m la 80 m (max +14 m pe 100 m), DREAPTA cădere −2…−5 m la 20–80 m; 0.29 STÂNGA perete +3,6…+11,2 m la 20–40 m, DREAPTA
−10 m la 80 m; **0.305–0.315: DREAPTA perete +11…+21 m la 20–40 m** (flancul tunelului), STÂNGA cădere −5…−9 m la 40–80 m.
`Zapada_*` la 10,4–11,0 m de axă, `Jalon*` la 7,9 m, `Utilaj_parcat` la 8,3 m, `Lampa` la 7,5 m (toate dreapta).

Cifre alocate: **stâna** cu țarc (`stana`, 1) în interiorul acelor, la 25–30 m de drum, cu gardul propriu; **~40 de pâlcuri de
jneapăn** (`jneapan_a/b` + `afin`), **8 petice de bujor** pe fâșiile de iarbă, **4 aflorimente** de șist pe versantul stâng
(fețe luminate), **2 conuri de grohotiș**, **12 molizi** la poale (nu pe linia pădurii: D e **deasupra** ei), peticele de
zăpadă `snow_patch` (6) pe versant; **piesele montate** (`snow_wall` 18, `snow_pole` 12, `Portal_S`, `Santier_tunel`) **rămân**;
`Utilaj_parcat` se mută la **≥ 12 m de axă** (garda îl marchează „IN DRUM”).

Piese: `stana`, `jneapan_a/b`, `afin`, `bujor_de_munte`, `schist_outcrop_a/b/c`, `scree_cone`, `snow_patch`, `alpine_pines`
(rar). Coliziune: stâna `hull`, aflorimentele `hull`, restul `none`.

Densitate: **0–10 m:** `snow_wall` (existent), stâlpi, tufe joase de jneapăn la ≥ 2,5 m; **10–30 m:** aflorimentele și pâlcurile
de jneapăn; **30–60 m:** stâna, grohotișurile, petice de zăpadă, versantul.

Interzis: **coada semaforului** (0.285–0.317): nimic pe banda liberă și nimic care ascunde stâlpul `Lampa` din cameră pe stânga;
**utilajul iese pe banda liberă** (offset −2,6): nimic în culoarul lui; `Portal_S` nu se mută și nu i se scoate
`camera_blocker`; **relieful și culoarea versantului** (iarbă în loc de șist/zăpadă) **nu se repară din decor** (N1, **(c)**);
fără cruci/troițe lângă stână; fără oameni.

Gărzi: **ProbeRace `--slice=0.252,0.3171` pe 16 seed-uri înainte și după** (**baza: 0.309–0.318 = utilajul/semaforul**, `bus-hit`
la `Portal_S`, ejectări „perete” 44–49 m/s), **probe_solid** (stâna, aflorimentele), ProbeLaneClear, probe_decor_overlap, probe_manual
(`Utilaj_parcat` de reparat), ProbeBuried, **ProbeCameraSolid**, probe_decor. Capturi: 0.255, 0.285, 0.300 (`--signal=red`), 0.312,
0.3171 vs `D`.

Capcana: `adancimea-siluetei-nu-fata-piesei`, `azimutul-soarelui-fata-de-drum` (D se urcă spre N: soarele din stânga-spate;
zăpada cu muchia aprinsă, umbre albastre spre cameră), `harnas-sintetic-comportament-emergent` (coada AI la semafor se măsoară pe
pista reală).

### E — Tunelul și lacul Bâlea (0.3171–0.372; semi 6,0 în tunel, 7,0)

Din decupaj (`E`): **lac turcoaz-verzui rece** cu mal de piatră, **cabana de piatră și lemn** cu acoperiș abrupt de tablă, **8–10
mașini și motociclete parcate** pe o terasă, **4 tarabe de lemn**, **bujori magenta în petice**, **jneapăn**, zăpadă pe versant,
molizi rari; în dreapta-jos **ieșirea din tunel**.

Lateral (măsurat): **STÂNGA perete +1…+3,5 m la 10 m, +11…+19 m la 20 m, +34…+44 m la 80 m** (masivul); **DREAPTA**: discul `LacBalea` (9,5
→ 77,5 m de axă, `L`), terenul alături −1…−6 m la 10–40 m, **−14 m la 80 m**; la 0.325–0.34 dreapta e perete (+17…+25 m la 20–40 m,
tunelul). **Nu există un platou plat** de 30 × 30 m (N5). **Camera 0.349–0.353 stă în placa `Portal_N`**; dezvăluirea serpentinelor are
28–51 din 69 de puncte de drum F în cadru de la camera 0.350–0.370 (la 20–200 m).

Cifre alocate: `cabana_balea_lac` (1) + **terasă pentru 8–10 mașini** (`parked_car_a/b`) + **4 motociclete** + **4 tarabe**
(`souvenir_stall`) **doar dacă există platou** (N5; altfel se pun pe stânga, în pantă, cu soclu, **marcat provizoriu**), 3 aflorimente de
șist, 2 conuri de grohotiș, **~10 pâlcuri de jneapăn**, **6 petice de bujor** (accentul magenta), **6 petice de zăpadă** (`snow_patch`),
stația de sus a telecabinei (`cable_car_station`, 1, **pe stânga, la ≥ 14 m de axă**, înălțime 8 m, nu deasupra drumului).

Piese: `cabana_balea_lac`, `parked_car_a/b`, `motorbike`, `souvenir_stall`, `schist_outcrop_*`, `scree_cone`, `jneapan_a/b`, `bujor_de_munte`,
`afin`, `snow_patch`, `cable_car_station` (kit alpin), `raven` (3). Coliziune: cabana/mașinile/tarabele `hull`.

Densitate: **0–10 m:** pe stânga stânci de la 3 m; pe dreapta iarbă și 2–3 jaloane; **10–30 m:** mașinile, tarabele, cabana, bujori;
**30–60 m:** versantul cu zăpadă, aflorimente, creasta în fundal.

Interzis: **nimic în tunel** (între portaluri: `Santier_tunel`, `road_works`, utilajul); `Portal_S/N` nu se mută; **nimic în fața lui `Portal_N`**
care ascunde dezvăluirea (0.350–0.372: nimic peste 3 m înălțime în axa spre F, pe 60 m); nu se atinge `LacBalea`
(mesh) și nu se adaugă apă; **nu se pun mașini „în mișcare”**; fără text lizibil pe table (taraba: pictograme); fără balcon sculptat; fără
hotel de gheață (iarnă).

Gărzi: **ProbeRace `--slice=0.3171,0.372`** (baza: **ejectările „perete” la `Portal_S` 0.317–0.318** sunt ale lui D/semaforului; E adaugă
**0**), ProbeLaneClear, **ProbeCameraSolid** (zona camerei sub portal), probe_solid (cabana, mașinile), ProbeBuried (31 tavane = baza),
probe_decor, probe_decor_overlap, probe_manual. Capturi: 0.322, 0.340, 0.358, 0.366, 0.370 vs `E`; dezvăluirea cu `CREASTA`/`ORIZONT`.

Capcana: `masoara-inainte-nu-langa` (dezvăluirea e **înainte**), `verifica-cu-parametrii-lui` (camera la 10 m), `geometria-fara-lumina-e-invizibila`,
`conul-e-casa-nu-stanca` (aflorimentele: lame, nu conuri).

### F — Serpentinele (0.372–0.6268; semi 7,0)

Din decupaj (`F`, `F_oi`): **patru ace de păr stivuite**, **zid de sprijin de piatră** pe fața fiecărei trepte, **parapet alb-roșu** pe marginea de vale,
**oile (30–40, crem, nu albe) cu doi câini negri** pe ramura a treia, **fâșii de iarbă cu bujori magenta și molizi** între ramuri, **jneapăn**,
**zăpadă și șist** pe versantul de sus, o mașină roșie pe ramura de jos; telecabina deasupra (integrare).

Lateral (măsurat): terenul **alternează între ramuri** (32 m între axe, fâșie de ~18 m între parapete): la 0.43 STÂNGA −5,7…−20 m, DREAPTA +0,4…+48 m;
la 0.46 STÂNGA −1…−10 m, DREAPTA +3,5…+12 m; la 0.49 STÂNGA +3…+17 m, DREAPTA −4…−11 m; la 0.55 DREAPTA +5…+20 m, STÂNGA −1…−3 m; **fără apă nicăieri**;
`ZidC*` la 6,8–7,2 m de axă (34, curbe). Versantul de sus (dreapta/stânga după ramură) e **iarbă galbenă** (N1). Golul din parapet **0.488–0.498**
și coridorul oilor (`corridor_m` 14, `body_reach` 18) trebuie lăsate libere.

Cifre alocate: **~40 pâlcuri de jneapăn** pe fâșiile dintre ramuri și pe versant, **10 petice de bujor** (accentul), **4 aflorimente** de șist pe
versantul de sus, **3 conuri de grohotiș**, **14 petice de zăpadă** (`snow_patch`) pe versantul nordic, **12 molizi** izolați, **2 pâlcuri de
afin**; zidurile de sprijin **drepte** nu se adaugă (terenul nu coboară destul), dar curbele din montare **rămân**; telecabina (linie, 2 cabine,
piloni) e **integrare**, nu F.

Piese: `jneapan_a/b`, `afin`, `bujor_de_munte`, `schist_outcrop_a/b/c`, `scree_cone`, `snow_patch`, `alpine_pines`, `flower_cluster`, `raven`.
Coliziune: aflorimentele `hull`; restul `none`.

Densitate: **0–10 m:** **parapetele sunt barieră**: dincolo de ele iarbă și flori, nimic înalt; **10–30 m:** fâșiile dintre ramuri (18 m): jneapăn,
bujori, 1–2 aflorimente joase; **30–60 m:** versantul: zăpadă, șist, molizi izolați, grohotiș.

Interzis: **`ProbeRace` rămâne la baza lui** (ejectări/repuneri pe 0.388–0.392 = avalanșa, ramura 1); decorul **nu intră** pe ramuri, **nu scade
separarea** dintre ele sub 31,7 m; **nu se pun obstacole în acele de păr** (raza 14,7 m e aproape de pragul AI de ~14 m); **golul din parapet
0.488–0.498** și culoarul oilor (0.485–0.497) rămân libere; **nimic în limba avalanșei** (0.400–0.43, pe versantul de deasupra ramurii 1);
`Avalansa`/`OileAcPaior` nu se ating; **datoria montării**: 20 `Wall_Stone` care intră 0,11–0,18 m peste asfalt (le repară coordonatorul, nu F).

Gărzi: **ProbeRace `--slice=0.372,0.6268` pe 16 seed-uri înainte și după** (baza: 2–3 repuneri pe seed, majoritatea la 0.388–0.392; **0 `[blocaj]`**,
nicio ejectare de „aterizare”), ProbeLaneClear, probe_solid, **ProbeCameraSolid**, probe_decor_overlap (baza 22: 20 sunt `ZidC*`), probe_decor, probe_manual.
Capturi: 0.376, 0.395 (`--avalanche-at=3.5`), 0.440, 0.485 (`--herd-at=4.0`), 0.530, 0.585 vs `F` + `F_oi`.

Capcana: `perete-paralel-nu-se-vede` (peretele paralel cu drumul nu se vede: contează fâșiile din față, la ace), `dunele-hairpin-pileup`,
`pista-peste-pista` (pe ramurile 2–4 cota terenului vine de la ramura de sus sau de jos), `ceata-in-familia-solului`.

### G — Bâlea Cascadă (0.6268–0.7036; semi 7,0)

Din decupaj (`G`): **molid verde-negru des** pe versant și pe ambele maluri, **cascadă în trepte** (alb-turcoaz) pe un perete de șist, **cabana de lemn**
(stația de jos a telecabinei) lângă, **podețul de lemn rupt** peste pârâu, **apă verde-cenușie** jos, **cablul** cu cabina roșie deasupra.

Lateral (măsurat): **plat −0,3…−0,1 m pe 40 m pe ambele laturi** la 0.63–0.65; **STÂNGA perete > 3 m abia la 40–84 m** (+15…+21 m la 80 m);
DREAPTA plat până la 84–134 m; **la 0.67–0.69 (canalul)** −2…−3 m pe ambele laturi (bancă de canal), cădere > 3 m la 20–32 m; **fără apă** în afară
de canal. Poligoanele muștar/verde-închis ale canalului acoperă dreapta pe 0.655–0.70 (N8).

Cifre alocate: **~140 molizi** (`alpine_pines`, MultiMesh feliat, în pâlcuri, mai deși spre drum; peste ~1000 de piese se feliază),
**`cabana_balea_cascada` (1)** + `cable_car_station` (jos, 1), 3 aflorimente de șist (baza peretelui din stânga), 2 conuri de grohotiș, **cascada** =
**`WaterfallVisual`** ca decor pe peretele din stânga (de adăugat de coordonator, N7; **nu are hazard**), pârâul rămâne cel din `TrackChannel`;
`stream_bridge` rupt **doar dacă** se cere la volan; **corbi 3**.

Piese: `alpine_pines`, `cabana_balea_cascada`, `cable_car_station`, `schist_outcrop_*`, `scree_cone`, `afin`, `raven`. Coliziune: cabana `hull`, molizii `trunk`,
aflorimentele `hull`.

Densitate: **0–10 m:** iarbă și bolovani de pârâu la ≥ 2,5 m; **10–30 m:** molizi deși pe dreapta, cabana pe stânga (la ≥ 14 m); **30–60 m:** pădurea densă,
peretele cu cascada.

Interzis: **nimic în culoarul săriturii** (0.665–0.69: ±25 m de axă, `ParaulBalea`, `ChannelKicker` la 0.675); **nimic care atinge canalul sau
kickerul**; `ProbeCameraSolid` rămâne cu 0.676 ca bază; **fără pod întreg**; fără cruci; **relieful** (peretele cascadei) și **bancile canalului nu se
repară din decor** (N7, N8, **(c)**).

Gărzi: **ProbeRace `--slice=0.6268,0.7036` pe 16 seed-uri** (**baza: 0.683 = aterizarea**, 1 repunere pe 16; decorul adaugă 0), ProbeLaneClear (**0.675 kicker = baza**),
ProbeCameraSolid (0.676), probe_solid, probe_decor, probe_decor_overlap, probe_manual. Capturi: 0.630, 0.650, 0.665, 0.690, 0.700 vs `G`.

Capcana: `vegetatie-cost-pe-pas` (250 molizi pe G + H: MultiMesh), `decor-in-masa-cere-multimesh`, `strop-apa-particule`, `apa-iluminata-v12` (cascada în contralumină).

### H — Defileul Oltului (0.7036–0.9786; semi 7,0)

Din decupaj (`H`, `A_poenari`): **râu lat verde-cenușiu** pe dreapta, **maluri de stâncă împădurită**, **calea ferată** pe malul celălalt, **trenul roșu** cu **bariere și
lumini** la trecerea la nivel, **molid și fag** pe pereți, **Poenari** în final.

Lateral (măsurat): **DREAPTA apă la 10–14 m de margine** (rapa 4: 0.72, 0.76; rapa 5: 0.88, 0.92, 0.96), **cădere > 3 m la 8–10 m**; **lipsește pe 0.775–0.845** (N9);
**STÂNGA perete > 3 m la 16–72 m** (+20…+72 m la 40–80 m în 0.76–0.84; +4…+10 m la 80 m în 0.88–0.96); `Tren` pe axă (0.8007, sina taie drumul în diagonală, `half_rail`
65); `Poenari` la stânga.

Cifre alocate: **~110 molizi** pe pereții defileului (MultiMesh), **~30 fagi** spre A, **5 aflorimente** (peretele stâng), **2 conuri de grohotiș**, **stâlpi de
electricitate în vale** nu (nu există piesă), **jneapăn nu**; **trenul, barierele, luminile și sina rămân** (montate/hazard); `Poenari` rămâne.

Piese: `alpine_pines`, `beech_tree_a/b`, `schist_outcrop_*`, `scree_cone`, `afin`, `raven`. Coliziune: aflorimentele `hull`, copacii `trunk`.

Densitate: **0–10 m:** iarbă/pietriș, borduri de sină; **10–30 m:** molizi pe stânga, aflorimente joase; **30–60 m:** pereții cu molid și fag, cerul deasupra.

Interzis: **sina și culoarul trenului** (`half_rail` 65 m ⇒ ±65 m de-a lungul sinei, care taie drumul la ~60°: X local al nodului `Tren` = (−0,80; −0,60)): nimic cu coliziune pe 0.78–0.82; **brațele de
barieră** (`Trecere_nivel_*`) nu se ating; **trenul nu primește sigle**; nimic pe banda liberă; **râul** (rapa 4/5) **nu se atinge** (N9, **(c)**); `Poenari` nu se
mută; fără troițe, fără mănăstire (Cozia e aici în realitate: **nu se pune**).

Gărzi: **ProbeRace `--slice=0.7036,0.9786` pe 16 seed-uri înainte și după** (baza: **0 repuneri**), ProbeLaneClear, probe_solid, probe_decor, probe_decor_overlap, probe_manual, ProbeBuried,
ProbeCameraSolid. Capturi: 0.720, 0.760, 0.790 (`--train-at=0.20`), 0.880, 0.955 vs `H`.

Capcana: `hazard-dezaliniat-contamineaza-verdictul` (trenul pe axă), `ceasul-porneste-in-prima-faza`, `zero-repuneri-ascunde-blocajul`.

## Probleme de nivel de pistă

Tot ce un constructor de POI **nu poate repara din decor**: relief, teren, apă, lumină, fundal, canal, unelte. Pornesc de la ce se știa
(fundalul plat, `mountain_peak` pe `tf_schist`) și adaug ce arată capturile „înainte” și măsurătoarea. Pentru fiecare: **ce, unde, dovadă,
reparație propusă, cine, înainte sau după valuri.** Ordinea e a impactului pe bucla oarbă (câte POI-uri pică pe (c) dacă nu se repară).

**N1. Culoarea terenului și lipsa stâncii/zăpezii pe versant (toate POI-urile).** Dovadă: pe toate capturile „înainte” iarba iese **oliv-galbenă**
(H 51–66°, S 0,33–0,46, V 0,47–0,58, `#88894C`, `#82884A`, `#8E8551`) față de ținta `#7D9A4E` (H 83°, S 0,49, V 0,60), deși `ground_tint` din temă
**e deja** `(0.49, 0.60, 0.31)` = țintă; deci devierea e de **lumină + shader de teren** (soare `#FFD9A8` energie 1,1 + `terrain_splat`), nu de
tentă. În plus **versanții sunt iarbă 100 %** (D, F, G, H): niciun taluz de șist gol, nicio zăpadă pe versantul nordic (doar `snow_wall` și
bulgării avalanșei), deși brief §0.1 cere „versant verde-cenușiu fără copaci cu zăpadă pe margini” (identitatea pistei). `snow_wall` din D citește
„piatră albă lumpy”, `mountain_peak` pe `tf_schist` citește deal verde (cunoscut din montare). **Reparație**: (a) în tema `transfagarasan`
(`track.gd`): temperează `sun_color` spre neutru-cald (de ex. `#FFE6C4`) și remăsoară HSV-ul pe captură până iarba iese H 78–86°; (b) `scarp_tint`/
„linia zăpezii” pe pantă și altitudine: versantul > ~10° pe șist gri-verzui `tf_schist`, peste cota +30 petice de zăpadă (în shader, nu decor); (c)
decide `mountain_peak` (scos din teme sau trecut pe atlas). **Cine**: coordonatorul (teme, shader). **Înainte de valuri: DA** — fără ea fiecare
critic spune „iarbă galbenă / versant fără stâncă” de două ori și bucla ajunge pe (c) în 2 runde, pe 8/8 POI-uri.

**N2. Apa: toate sunt „mare” (B, C, E, G, H).** Dovadă: lacul Vidraru (B, C), Oltul (H), pârâul (G) și iazul de la 0.955 randează **turcoaz deschis**
(H 185–195°, S 0,34–0,41, V 0,56; `#54808F`, `#5F8C90`) **cu creste de val albe** (`water_foam` 0,15 nu le oprește), față de ținte: Vidraru `#2F5446`
(H 158°, V 0,33), Oltul `#6E7F69` (H 108°, S 0,17), Bâlea `#3F6F7A`. Tema are `water_shallow_slot` = `ICE_TURQUOISE`, `water_deep_slot` = `SEA_DEEP`: de sus,
adâncimea mică arată doar slotul „shallow”. **Reparație**: culoare per apă (lac vs râu vs lac glaciar), de ex. un al patrulea câmp în `custom_ravine_water`
(sau o tentă pe tema `transfagarasan` care taie turcoazul și adaugă spumă 0 pe lac), foam off / valuri off pe lac și pe Olt; apa lacului Bâlea să fie tot apă de
rapă (N5), nu un mesh. **Cine**: coordonatorul (`track.gd` `_water_material`, scena). **Înainte de valuri: DA** (5 din 8 POI-uri).

**N3. Fundalul: marea de nori, câmpia și culoarea crestei.** Dovadă (captură + măsurătoare): `CloudSea_A` stă la (333, 9, 21), `CloudSea_B` la (260, 3, 273), `FagarasPlain_A` la (26, 9, −390),
`FagarasRidge_A/B/C` la (382, 12, −62) / (308, 13, −259) / (352, 14, 167). Terenul la 340–500 m de centroid e la **±3 m de cota medie a drumului** (la 380 m: +0,1…+2,4 m pe N, E, V, −4…−8 m pe S–SE,
−17 m doar la SV; la 250–300 m apar „bolți” de +11…+24 m la E) și `_build_horizon` pune piesele la `ground_y − 4` (nori cu `dy −8`, câmpia cu `dy 0`). `CloudSea_*` au 15–17 m grosime:
rămâne la suprafață ~5 m, deci **în capturile `nivel_nori_A_din_C` și `nivel_nori_B_din_baraj` norii apar ca niște bolovani albi mici la linia orizontului** (lângă baza crestei, respectiv în dreapta lui
Prometeu), nu ca o mare. În `nivel_creasta_A_din_D` creasta (provizorie) iese **bej-tan cald**, cu vârfuri albe, nu gri-verzui, fără zăpadă în căldări; în `nivel_campie_nord` câmpia e o întindere
plată olive spre haze, fără contrast. Cota de coborâre din inventarul tf-g: **~−28 m** per inel pentru nori, nu −8. **Reparație**: (a) `dy −28` la inelele nor (câmpia `dy −12`, ca să se vadă pătrunzând în vale);
(b) un inel de relief coborât (teren cu pantă ieșind în afară peste ~300 m) ca să existe „vale” sub nori; (c) clasa crestei: `tf_schist` sau tentă pe atlas pentru `FagarasRidge_*` (acum citește bej), plus
zăpadă în căldări. **Cine**: coordonatorul (cod `_build_horizon`; cheia `dy` există deja în tema `transfagarasan`). **Înainte de valuri: DA** (orizontul e în fiecare cadru; fără el criticul cere „marea de nori” de la 8/8).

**N4. Barajul: hăul și fața din aval nu se citesc (B).** Dovadă: `nivel_hau_coronament` — din cameră vezi un bol verde cu o băltoacă; peretele opus urcă lin spre
+1,5 m; `nivel_hau_din_vale` — fața de beton apare doar ca dungă sub coronament, restul feței e acoperit de teren, râul/centrala pe o placă izolată, iar canionul e un V
fără perete opus. Rapa 2: podea −28, lățime 60, adâncime 40; nodul `Prometeu` e **1,7 m sub teren**. **Reparație**: rapa 2 mai îngustă (lățime ≤ 40) și
cu **perete opus abrupt** (`custom_cornice_ravines` include deja 0 și 2; ridică marginea opusă la +8…+15 m peste coronament pe 20 m), asigură că fața din aval GLB
(modulele 16 m) rămâne descoperită până la −25 m, ridică `Prometeu` +1,7 m sau sapă pintenul; **ProbeCameraSolid** și `probe_buried` după. **Cine**: coordonatorul
(`Track21.tscn` rape). **Înainte de valul lui B: DA** (B-ul nu are altă identitate decât hăul).

**N5. Lacul Bâlea: disc fără căldare și fără terasă (E).** Dovadă: `LacBalea` e un `CylinderMesh` (R 34, h 0,1) la +40,3, centrul la 43,5 m dreapta; începe la **9,5 m de axă**; rapa 3
(podea +37, lățime 55, adâncime 5, **fără apă**) e **mai îngustă (55) decât discul (68)**; terenul la 80 m dreapta e −13,7…−20 m, deci marginea îndepărtată a discului **atârnă deasupra versantului**
(în `E_f0.358`: farfurie turcoaz pe pantă). Nu există platou pentru cabană + 8–10 mașini + tarabe. **Reparație**: înlocuiește discul cu apă de rapă (aceeași culoare ca N2), lățește rapa 3 la ≥ 90 și
deepens la −8, cu **platou plat** de ~35 × 30 m la 12–45 m de axă pe dreapta (sau mută lacul la 60 m și lasă terasa) — `terrain_pad_m` lărgește pânza
(memoria `rapa-cu-latime-reteza-relieful`). **Cine**: coordonatorul. **Înainte de valul lui E: DA.**

**N6. Valea Argeșului și defileul sunt plate (A, parțial H).** Dovadă: A ±0,3 m pe 40 m, perete > 3 m la 68–86 m; „valea” din dioramă e o albie cu versanți împăduriți. **Reparație**:
doi `TerrainPeak`/„bluff” de rază 60–80, +20…+30 m, la 45–60 m de axă pe fiecare latură a lui A (cu o spărtură pentru Poenari), sau `custom_cuttings` de 20–40 m; pe H stânga e deja perete. **Cine**: coordonatorul
(`Peaks`). **Înainte de valul lui A: recomandat** (fără ele A rămâne „câmp cu case”, ieșire (c) în 2 runde); dacă nu se face, A merge cu rânduri de fagi ca „pereți”.

**N7. Cascada: nici perete, nici nod (G).** Dovadă: stânga G are perete > 3 m abia la 40–84 m; nu există niciun `WaterfallVisual` în `Track21.tscn` (componenta Fiordland cere `build(size, spray_count)` apelat de un hazard; un
decor-fără-hazard n-are încă un wrapper). **Reparație**: un nod-wrapper de decor (`WaterfallDecor`, ~20 linii: `_ready → WaterfallVisual.build`) + un `TerrainPeak` de rază ~40, +30 m, la 20–30 m STÂNGA
pe 0.65–0.68, pe care să stea cascada (28 m vizibili). **Cine**: coordonatorul. **Înainte de valul lui G: DA.**

**N8. Canalul „ParaulBalea”: poligoane muștar/verde-închis (G).** Dovadă: `G_f0.665` — pe dreapta drumului (0.655–0.70) sunt **plăci plane de culoare galben-muștar ondulat și verde închis cu margini drepte** (cel puțin
pe ~100 × 40 m) și un triunghi portocaliu (kickerul); nu e decor (cauza între `terrain_splat` și materialul băncii canalului: **nedeterminat**, vezi „ce n-am putut măsura”). **Reparație**:
verifică materialul băncii (`TrackChannel` `bank`/`reach`) și splat-ul; temă pentru stânci de pârâu. **Cine**: coordonatorul. **Înainte de valul lui G: DA.**

**N9. Oltul se întrerupe la trecerea la nivel (H).** Dovadă: rapa 4 se termină la 0.775, rapa 5 începe la 0.845; între ele ≈ 150 m fără apă, iar `Tren` (0.8007) și `Trecere_nivel_*` (0.798/0.8045) sunt **în gol**, pe iarbă plată.
**Reparație**: o singură rapă 0.705–0.975 sau o a treia rapă 0.775–0.845 cu aceeași apă (+0 … −2,5, linie de cădere continuă), cu malul opus la ~40 m și sina pe un rambleu; sau mută
trecerea. **Cine**: coordonatorul (rape, `Tren`). **Înainte de valul lui H: DA.**

**N10. Tunelul e un șanț și semaforul/utilajul dau baza de repuneri (E, D).** Dovadă: `E_f0.330` (pereți negri plani, fără tavan citit), `ProbeBuried` 31 tavane; ProbeRace: ejectări „perete” 44–49 m/s la `Portal_S`
(`bus-hit`, utilajul iese pe verde). **Reparație**: ținta e „se citește tunel”, dar tavanul e `MasivTunel` (relief); de judecat la volan; nu se promite din decor. Utilajul (`bus_lane_offset −2,6`) și
`Utilaj_parcat` (8,3 m) sunt datoria coordonatorului (hazard). **Înainte de valuri: nu** (se judecă la volan).

**N11. Garda de materiale (32 > 30) și scatterul moștenit.** Dovadă: probe_decor azi 32 materiale; `stirling_ledge` (34), `mine_portal` (8, 3 materiale), `boulder_roller` (3), `torrent_chute` (2) vin din
tema `alpine`/Fiordland. **Reparație**: scoate scatterul care n-are ce căuta (−6…7 materiale) sau mută ținta la ≤ 34. **Cine**: coordonatorul. **Înainte de valuri: DA** (altfel primul POI cu un material nou
„pică” ținta fără vină).

**N12. Unelte.** (a) `ProbeLaneClear` are baza 2 și cere 3 (ursul): ridică la 3; (b) `Snapshot --train-at` merge doar cu 0.1125–0.285 (documentat aici); (c) `Snapshot --cross-at` nu prinde `Stand` (de verificat 4.5–5.2); (d)
`probe_manual`/`probe_solid` în `--script` tipăresc erori de autoload (rulează, dar zgomotos). **Cine**: coordonatorul. **Înainte de valuri: (a) DA, restul opțional.**

**Rezumat**: N1, N2, N3 se repară **înainte de orice val** (toate POI-urile); N4 înainte de B, N5 înainte de E, N6 înainte de A (recomandat), N7+N8 înainte de G, N9 înainte de H; N10, N12 se judecă la volan.

## Ce n-a fost măsurat (și de ce)

- **Cauza poligoanelor muștar/verde de la G (N8)**: nu am izolat dacă vin din `terrain_splat` sau din banca `TrackChannel`; `Snapshot --hide=` n-a fost încercat. Decide coordonatorul cu o captură A/B pe
  noduri ascunse.
- **Ursul în `Stand`**: `--cross-at` 5.4/6.0 îl prinde mergând; ridicat n-am prins (de încercat 4.5–5.2 și apropiat la `--frac=0.19`).
- **Baza ProbeRace per felie**: n-am rulat `--slice` separat; baza pe felii e **derivată** din cele 16 curse întregi (poziția fiecărui eveniment), deci „0 în afara celor patru locuri” e măsurat pe pistă
  întreagă, nu pe felie.
- **Culorile pe instanțe apropiate** (bujor, jneapăn, zăpadă și beton pe fețe luminate): n-au piese montate încă; se măsoară după fiecare POI (`monocromia-se-masoara-dupa-remap`).
- **Tavanul tunelului** (E): doar din captură și din `ProbeBuried` (31 tavane); nu am măsurat dacă camera vede tavan în tunel.
- **Telecabina**: nu există în scenă, deci traseul cablului, înălțimea pilonilor și gabaritul față de camera de joc sunt neverificate.
- **Device fizic**: nimic măsurat pe telefon (M4 amânat); toate cifrele de timp sunt pe RTX 3070.

## Starea valului 1 (A, C, F) — integrat pe `transfagarasan/poi-integrare`, 14 oct 2026

| POI | runde | ieșire | ce s-a făcut | ce a rămas |
|---|---|---|---|---|
| A | 2 + curățenie | (c): criticul a repetat verdictul de densitate după ce clusterele și pădurea erau acolo | 2 grupuri de 7 case, 1 500 de molizi, 55 de fagi, vaci, căpițe, poteci; gardurile MultiMesh scoase (rămâneau segmente răzlețe) | căpițele `hay_bale` citesc „franzelă”; pădurea intră pe terenul lui B până la x ≈ 62 (păstrată) |
| C | 3 | (c) după ultima rundă | 162 de molizi pe 3 rânduri, fâșie de jneapăn, afin și șist la 3,5–9 m, fagi doar ca accent | molizii se citesc tot ca masă cu goluri; groapa de la 0.24 e relief |
| F | 3 | (c): zăpada e sub 0,4 % din cadru | 416 molizi în 3 trepte, 302 tufe de jneapăn, 92 de bujori, 23 de aflorimente, 52 de bănci de zăpadă (`snow_wall` îngropat) | **zăpada cere relief**: versantul cel mai înalt e limba avalanșei (liberă prin contract), iar panta e netedă — decizia dezvoltatorului |

Toți criticii au ales referința 5/5 în fiecare rundă (ca pe Okinawa, Fiordland și Serengeti).

**Reparații centrale** făcute de coordonator în timpul valului, fără material nou:
- cheia de temă `pine_crown_class`: molizii din benzi trec pe `tf_jneapan`;
- `Poenari_Brick` trece pe `tf_stone`;
- tabla argintie (`arges_house_a`, `cabana_balea_lac`) trece pe `PAINTED_METAL`, măsurată în joc la gri-albăstrui (95, 112, 114);
- scoarța jneapănului trece pe `tf_jneapan`, fiindcă crenguțele ieșeau portocalii. **Rularea din nou a generatoarelor C și F pierde această cheie.**

**Convenție pentru valurile următoare:** pe FlockProp, clasa se scrie `tri_class = "tf_*"` (triplanar), **niciodată `class:tf_*`**: cele două căi țin cache-uri separate, deci aceeași clasă s-ar număra ca 2 materiale. Procesele Godot se opresc doar după PID-ul propriu, niciodată cu `taskkill /IM`.

**Scena integrată** (gărzile sunt toate la linia de bază):

| măsură | valoare |
|---|---|
| materiale | 35 (plafon 38): **B, D, E, G și H nu mai au voie să adauge** |
| triunghiuri | 3,76 M (bază 1,24 M) |
| încărcare | 4,4 s la rece, 3,8–3,9 s la cald |

ProbeRace pe 16 seed-uri: 49 de repuneri (urs 36, portal 9, avalanșă 2, plus 2 neașteptate în afara zonelor de decor):
- **0.120, seed 2**: autobuzul Nyx, la baraj (B), determinist. Se verifică la B;
- **0.266, seed 14**: nedeterminist.

Mai sunt 2 `[blocaj]` noi la 0.320 (`Portal_S`, seed 6).

## Bucla oarbă

1. Constructorul (Sonnet, memoria `coordonator-fable-constructori-sonnet`) lucrează în `D:/GameDev/wt-tf-poi-<x>` pe `transfagarasan/poi-<x>`, plecat din vârful ramurii după merge-ul
   fundației (`transfagarasan/poi-bara`); `--import` la creare; comite după fiecare pas care trece o gardă; **prima rundă începe cu `git status` / `git diff`**; **niciodată `git stash`**
   (memoria `git-stash-partajat-intre-sesiuni`); lucrează dintr-un git worktree separat (memoria `shared-worktree-collision`).
2. Face captura din mașină la fracțiile din tabel, cu `--gamecam` și flagurile de hazard, prin lacătul de GPU, **copiind `snapshots/transfagarasan_joc.png` după fiecare**. 5 eșantioane pe verdict.
3. Criticul, **context proaspăt**, primește planșa din:

   ```
   python tools/bar/blind_pair.py "<captura>" "docs/track_briefs/img/bar_transfagarasan/<POI>.png" "<out>.png" --seed <N>
   ```

   (verificat pe `D_f0.312.png` vs `D.png`: scrie `<out>.png` și `<out>.png.<amprenta>.key`; amprenta din colțul stânga-jos al planșei trebuie să fie cea din cheie.)
   **O singură planșă per rundă.** Decupajul-bară se mărește la rezoluție plină înainte de verdict (memoria `numaratoarea-trece-amplasarea-nu`).
4. Criticul **deschide** planșa, alege A sau B, **apoi** citește cheia și raportează cinstit dacă a nimerit.
5. Numește **o singură** diferență care contează, reparabilă în decorul POI-ului.
6. Ieșirea din buclă: (a)/(b)/(c). La (a) sau (b): gărzile pe scena integrată, apoi merge. La (c): oprire și decizie.

Seed-ul planșei și numele fișierului se schimbă la fiecare rundă (memoria `critic-orb-coliziune-de-plansa`). Verdictul de fidelitate nu se deleagă constructorului.

**Ce primește criticul pentru fiecare POI** (decupajul, nu toată dioramă): A → `A` (+ `A_poenari` la 0.985); B → `B`; C → `C` și `C_urs`; D → `D`; E → `E` (+ `ORIZONT`/`CREASTA` pentru dezvăluire); F → `F` și `F_oi`;
G → `G`; H → `H`. **Ce NU i se cere**: layout (unde stă satul, cât de aproape e peretele), poziția barajului, forma lacului: doar materia (§ regula „bara nu e layout, e look”).

## Valurile (câte 3 POI-uri, niciodată 8)

Memoria `valuri-de-trei-nu-opt-agenti`. Regula: **două POI-uri care se calcă pe decor nu merg în același val** (un worktree nu vede ce pune celălalt). Distanța minimă dintre drumuri e în
tabelul de mai sus; vecinii pe traseu sunt la 0–3 m, deci niciodată în același val; **C–E (104 m)** și **D–F (114 m)** nu sunt vecini, dar sunt apropiate, deci le țin în valuri diferite.

**Propunerea mea (nicio pereche adiacentă într-un val; toate distanțele ≥ 185 m):**

| val | POI-uri | de ce |
|---|---|---|
| **1** | **A, C, F** | A–C 185 m, A–F 458 m, C–F 215 m. **A** = satul (cel mai mult decor mic, banca de teste a kitului: case, vaci, fagi MultiMesh; fără hazard). **C** = mal + urs (puțină piesă, dar prima apă și primul hazard: scoate repede N2). **F** = serpentinele (**identitatea pistei**, trei hazarde, raza 14,7 m la limita AI, singurul loc cu scurtătura viitoare: riscul `[blocaj]` se află cel mai devreme) |
| **2** | **B, D, G** | B–D 188 m, B–G 551 m, D–G 300 m. **B** = barajul (după N4), **D** = portalul și zăpada (identitatea; semaforul/utilajul; datoria `Utilaj_parcat`), **G** = pădurea MultiMesh + cascada (după N7/N8). B și D sunt vecini cu C (val 1), G cu F (val 1): se integrează **înainte** să pornească |
| **3** | **E, H** | E–H 320 m. **E** = Bâlea Lac (se judecă **după** D și F gata: dezvăluirea leagă tunelul de serpentine; N5), **H** = Olt + tren (după N9; se leagă de A și G, ambele gata) |

Dependențe: B și D sunt vecine cu C, deci **C se integrează înainte** de val 2; la fel F înainte de G și E; D înainte de E; A și G înainte de H. Fiecare val se integrează într-un worktree dedicat (memoria
`orchestrare-agenti-worktree-frate`) înainte să pornească următorul; gărzile **doar pe scena integrată**; după fiecare merge: `--import` și verifică ramura înainte de commit (memoria
`merge-ul-lasa-tree-ul-pe-main`) și că reparațiile chiar au ajuns (memoria `reparat-pe-ramura-nu-inseamna-livrat`). **Val 4:** reluarea celui mai slab + trecerea de integrare (scatterul moștenit,
telecabina, `ProbeRace` complet, `probe_load_time`, verdictul la volan) + swap-ul pe indexul 2 (brief §7).

**Înaintea valului 1: N1, N2, N3, N11 și N12(a).** Fără ele, fiecare val consumă buget pe aceeași diferență.

**Riscuri de conflict între constructori:**

- `Track21.tscn` unic: nu au fost puse `ext_resource`-uri noi în antet; fiecare constructor își pune `ext_resource`-urile cu `id` prefixat de literă (`a_…`) și coordonatorul concatenează; sub `Zona…` proprie doar noduri.
- **Colțurile comune:** în valuri nu există perechi adiacente, deci nu se calcă.
- **Telecabina** (linie, piloni, 2 cabine în `PathMover`, cele două stații) e **piesă de integrare** (E–F–G în trei valuri): stațiile le pun E și G, linia o face coordonatorul în val 4.
- **Materialele:** `probe_decor` se măsoară pe scena integrată; trei constructori pe worktree-uri separate nu văd suma. Azi 32 (ținta 30, garda 38): fiecare constructor raportează ce materiale NOI adaugă (clase, tente),
  coordonatorul însumează; **max +2 per POI** până se hotărăște ținta.
- **Hazardele care taie banda** (urs, semafor, avalanșă, oi, tren, săritură) au culoare libere declarate mai sus; orice piesă cu `hull` pe ele schimbă distribuția ProbeRace.
- **Scatterul moștenit** (`stirling_ledge`, `mine_portal`, `boulder_roller`, `torrent_chute`, `alpine_pines` conic) e al integrării, nu al constructorilor.
- **Disk:** D: era la 99 % când am lucrat (7 GB liberi): fiecare worktree nou aduce ~1,2 GB de `.godot`; nu porni mai mult de 3 deodată.
