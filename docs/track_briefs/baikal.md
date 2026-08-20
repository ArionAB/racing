# Track brief — Baikal (`Track10`, temă `baikal`)

> Concept de pistă + lista completă de assets. Secțiunea finală e un prompt
> paste-ready pentru generarea unei diorame de referință (ChatGPT / imagine),
> din care apoi se scriu brief-urile individuale de asset în `docs/asset_briefs/`
> și scripturile `tools/blender/build_*.py`.

## 0. Într-o propoziție

Iarnă pe lacul Baikal, insula Olkhon: jumătate de tur pe **autostrada de gheață**
turcoaz cu crăpături negre și bule de metan înghețate — drift permanent, vânt
lateral, hovercraft, plăci care crapă sub pluton — și jumătate pe mal, prin
satul de pescari Khuzhir, pe lângă Stânca Șamanului cu stâlpii buriați cu
panglici, și pe viaductul Căii Ferate Circum-Baikal, printr-un tunel de piatră.
E singura pistă din joc pe care **drift-ul e modul principal de condus**, nu
unealta de viraj.

## 1. De ce Baikal (referința reală, ce luăm din ea)

| loc real | ce luăm |
|---|---|
| **Gheața Baikalului** (feb–mar) | plan turcoaz transparent, crăpături negre în rețea, „bule de metan" albe înghețate în straturi, torosuri (creste de gheață spartă, albastre, 1–3 m) |
| **Insula Olkhon, capul Burhan / Stânca Șamanului** | două colțuri de marmură albă-cenușie cu licheni roșii, ieșite în lac; loc sacru buriat |
| **Serge** (stâlpi rituali buriați) | stâlpi de lemn cu panglici colorate (albastru, alb, galben, roșu, verde) — SINGURELE accente saturate din decor în afara mașinilor |
| **Satul Khuzhir** | case de bârne închise, garduri de scânduri, fum din hornuri, sănii, lăzi, uscătoare de pește (omul) |
| **Hovercraftul „Khivus"** | ambarcațiune pe pernă de aer, portocalie/albă, care traversează lacul cu jet de zăpadă |
| **Grotele de gheață** de la capurile Olkhonului | stânci îmbrăcate în țurțuri și valuri de gheață înghețate pe loc |
| **Calea Ferată Circum-Baikal** | viaducte de piatră cu arcade, tuneluri săpate în faleză, tren scurt |
| **Nerpa** (foca de Baikal) | figurant pe gheață, lângă copcă |
| **Pădure de larice + mesteceni** pe mal, dealuri joase cu iarbă galbenă sub zăpadă rară | fundal și margini |

Culorile locului: turcoaz de gheață, alb-albăstrui, negru de crăpătură, gri de
marmură, lemn închis aproape negru, ruginiu de larice iarna, galben-pai de iarbă
uscată; cer alb-lăptos spre roz la orizont (soare jos, ora 15:00). Panglicile
serge și hovercraftul sunt accentele.

## 2. Traseul și punctele de interes (POI)

Lungime țintă **~1.7 km** (tur ~50 s, cursă 3 tururi ≈ 2:30). Sens: orar.
Fracțiile sunt orientative — se măsoară cu ProbeLayout după desen. Harta 2D
(`img/baikal_map.html`, artefactul „Baikal Recon") folosește aceleași litere.

```
            [F] viaduct CFR + tunel        [E] tabăra pescarilor + nerpa
   deal cu larici ──────────────────────────────── plajă de gheață
  /                                                          \
[G] pădure de mesteceni                                    [D] grota de gheață (cap)
  |                                                              |
[A] START Khuzhir (sat)                                    [C] câmpul de plăci crăpate
  \                                                          /
   [B] Stânca Șamanului + serge ──── coborâre pe gheață ── [B'] autostrada + torosuri
                                                             ^ hovercraft traversează
```

| # | frac | POI | ce se întâmplă | lățime |
|---|---|---|---|---|
| **A** | 0.00 | **Start în Khuzhir** — ulița principală a satului, pe mal la ~12.5 m peste lac, poartă de start din bârne, case de lemn pe ambele părți, fum, sănii parcate, câini husky (PathMover) | grilă de start pe zăpadă bătătorită, grip normal | 8 m |
| **B** | 0.10 | **Stânca Șamanului** — drumul iese pe promontoriu, la ~12 m peste lac; în stânga cele două colțuri de marmură (cu gulerul de gheață `Shaman_Ice` la bază), în dreapta șirul de **serge** cu panglici; viraj larg cu vedere spre lac | panglicile flutură (shader vertex-wind); primul viraj de drift pe zăpadă; ~~scurtătură strâmtă *printre* stâlpi~~ — **retrasă**, vezi §10: traseul e drept aici, nu există ocol de tăiat | 7 m |
| **B→B'** (B2 pe hartă) | 0.12–0.21 | **Rampa de coborâre pe gheață** — pantă 15% de pe mal pe lac (măsurat cu ProbeLayout: 15.4% la 0.14; coada rampei se stinge în trepte 0.7 → 0.22 → 0.12 m ca drumul de pe lac să rămână plat — PR #300), marcaje cu bețe și stegulețe roșii ale drumului de gheață | intri pe gheață cu viteză; primul moment de „alunecă totul" | 7 → 10 m |
| **B'** | 0.20–0.38 | **Autostrada de gheață** — plan larg turcoaz cu bule de metan sub roți și crăpături negre; **torosuri** în șiruri diagonale (kicker-e naturale, 0.6–1.2 m), un camion Kamaz parcat, indicatoare rutiere înfipte în gheață; **hovercraftul** traversează diagonal la ~0.30 (H pe hartă) | grip lateral gheață (~1.5, sub `wet`); **vânt lateral** constant dinspre larg; săritură de pe toros; hovercraftul te orbește cu jet de zăpadă + push lateral | 10–12 m (fără pereți; marginea = zăpadă adâncă = offroad 45%) |
| **C** | 0.40–0.485 | **Câmpul de plăci crăpate** — un câmp de presiune RIDICAT ~0.4 m peste placa lacului (rampe naturale la intrare/ieșire), spart Voronoi în plăci poligonale de 5–8 m cu fisuri de apă neagră între ele; apa se vede DOAR în fisuri, nu ca ramă (implementat în #314: `IceFieldHazard`, generat din probele traseului) | 3–4 **plăci „vii"**, marcate cinstit cu față vizibil mai închisă (gheață subțire, se vede apa prin ea), pânză albă de crăpături și fisuri mai late în jur: se **înclină** spre colțul încărcat (arc rapid, o simți cât ești pe ea, trosnet mic), iar sub încărcare mare — 2+ mașini, o mașină grea sau **turbo** (dublează apăsarea) — se **rup**: trosnet mare, țâșnitură, placa se scufundă sub linia apei 2 s și cine e pe ea e repus. Skill-ul = citești câmpul și alegi linia | 22 m (semilățime 11), câmpul iese ~5 m lateral de culoar; AI-urile se împrăștie prin `line_offset` |
| **D** | 0.55 | **Grota de gheață** — capul stâncos al insulei, drumul trece pe sub un arc de stâncă îmbrăcat în țurțuri și „valuri" de gheață înghețată; lumină albastră | tunel scurt (25 m), țurțuri cad când treci (particule + 1 obstacol mic care cade pe bandă), ieșire în viraj strâns pe gheață → drift obligatoriu | 6 m (îngustare) |
| **E** | 0.62 | **Tabăra pescarilor** — copci în gheață, corturi mici, lăzi de pește, sănii, un UAZ „pâine" verde parcat, **nerpa** care se uită și se scufundă când vii; uscătoare de omul pe mal | figurant + obstacole statice; scurtătură pe zăpadă printre corturi (`speed_factor` 0.85) | 9 m |
| **E→F** | 0.66–0.72 | **Rampa de urcare pe mal** — pe sub viaductul CFR, apoi urcare pe lângă el până la nivelul liniei | ieșirea de pe gheață: grip-ul revine brusc — schimbarea de suprafață E momentul de skill | 7 m |
| **F** | 0.74–0.84 | **Viaductul Circum-Baikal + tunelul** — drumul urcă PE terasamentul căii ferate (linia în mijloc, kerb-uri = șine), viaduct de piatră cu 5 arcade peste un golf, apoi **tunel** săpat în faleză | **trenul** vine din tunel spre tine (nou: pe SENSUL tău, nu perpendicular) — te bagi în nișa laterală a tunelului sau ieși la timp; pe viaduct fără parapet: cazi 12 m pe gheață → repunere | 6.5 m |
| **G** | 0.86–0.96 | **Pădurea de mesteceni și larici** — coborâre în S prin pădure rară, zăpadă, lumină printre trunchiuri, un stâlp de înaltă tensiune sovietic ruginit, o cabană de vânătoare | zăpadă = grip normal-scăzut (0.75× asfalt), porțiuni cu polei (`wet_ranges`, cauză: umbra pădurii); ultimul drift înainte de sat | 7 m |
| **A'** | 1.00 | intrare în sat pe lângă biserica mică de lemn cu cupolă albastră | linia de sosire | 8 m |

**Ritmul turului:** sat (tehnic) → promontoriu (viraj larg, priveliște) → gheață
(viteză + drift + haos) → grotă (strângere) → tabără (respiro) → viaduct
(precizie, frică de înălțime, tren) → pădure (drift final) → sat.

## 3. Hazarduri și mecanici (ce e nou pentru motor)

| mecanică | pe scurt | ce cere în cod |
|---|---|---|
| **Suprafață gheață** | grip lateral ~1.5 pe interval / poligon; particule de gheață în loc de praf; sunet de scrâșnet diferit | `custom_surface_ranges` generic (interval, grip, sunet, particule) — generalizarea lui `wet_ranges` |
| **Vânt lateral** | forță constantă pe RigidBody pe porțiunea de lac, cu rafale (sinus + zgomot), direcție fixă dinspre larg; stegulețele și panglicile arată direcția | `WindZone` (Area3D) + shader vertex-wind pe stegulețe |
| **Câmpul de plăci** | fractură Voronoi ridicată peste lac, fisuri cu apă neagră; plăci vii `AnimatableBody3D` care se înclină spre încărcare și se rup (scufundare + repunere) sub 2+ mașini / mașină grea / turbo; trosnet (`ice_crack`) | `IceFieldHazard` (#314; a înlocuit `IceSlabHazard` — placa singulară nu se simțea: pitch mic, arc moale, fără consecință, și sub cota drumului lupta cu colliderul lacului) |
| **Hovercraft** | `PathMover` rapid (25 m/s) pe traseu diagonal în buclă, cu emițător de particule în spate + `Area3D` de push lateral | PathMover + `push_area` opțional (nou, mic) |
| **Torosuri-kicker** | creste de gheață cu coliziune de rampă mică | decor cu coliziune (există) — doar model |
| **Țurțuri care cad** | în grotă, la trecerea mașinii, 1–2 țurțuri se desprind (mesh mic care cade, apoi dispare) | variantă de `rockfall` cu declanșare la trecere, fără traseu |
| **Tren pe sens** | trenul iese din tunel PE banda ta; nișa laterală în tunel e refugiul | `TrainHazard` cu direcție longitudinală (nou: azi e perpendicular) |
| **Nerpa** | figurant care se scufundă în copcă la apropiere | PathMover + trigger de proximitate (mic) |
| **Viaduct fără parapet** | cădere pe gheață → repunere | `custom_ravines` + `RespawnZone` (există) |

## 4. Paleta (sloturi noi în rezerva 24–31)

| slot | rol | hex propus |
|---|---|---|
| 24 | ice_turquoise | `#7FC4C9` |
| 25 | ice_deep | `#2F6E82` |
| 26 | ice_crack (negru-albastru) | `#1A2A33` |
| 27 | snow_white | `#EEF2F4` (sau reuse 22 foam_white) |
| 28 | larch_rust | `#A8683A` |
| 29 | log_dark (bârne) | `#4A3526` |
| 30 | marble_grey | `#B8B4AC` |
| 31 | ribbon_accents (mini-atlas de 5 culori pentru serge) | `#2C82E8 #FFFFFF #F2D03C #E54839 #3F7A3C` |

Reutilizate: `wood_weathered` 9 (garduri, sănii), `rust_metal` 10 (Kamaz, stâlp
înaltă tensiune, UAZ), `concrete` 8 (viaduct), `dry_vegetation` 13 (iarbă
galbenă sub zăpadă), `asphalt` 5 (doar în sat). Saturație mediu 0.45–0.60;
serge + hovercraft pot urca la ~0.75, sunt „semnalele" pistei.

## 5. Lista completă de assets

Toate: low-poly stilizat (Art of Rally / machetă de masă), un singur material =
atlasul de paletă + AO în vertex colors; materiale de clasă doar unde scrie
(`ice_material` triplanar pentru gheață, `rock_material` pentru marmură /
faleză). Origine la bază (linia solului / linia gheții), +Y sus, „înainte" = −Z.
Bugete de triunghiuri orientative.

### 5.1 Teren și suprafețe (generate din cod, cer texturi de clasă)
| asset | descriere | note |
|---|---|---|
| `ice_material` (triplanar) | textură de gheață: turcoaz cu rețea de crăpături negre + „bule de metan" albe în straturi (discuri albe suprapuse, semitransparente pictate, NU alpha real) | 2 dale: `ice_clear` (autostrada) și `ice_cracked` (câmpul de plăci, fisuri late cu apă neagră) |
| `snow_material` | zăpadă bătătorită cu urme de roți și sanie, albăstruie în umbră | pe mal, în sat, în pădure |
| `snow_deep` (offroad) | zăpadă afânată, mai albă, cu cruste | marginile gheții și ale drumului |
| decal `tire_tracks_ice` | urme de cauciuc negre pe gheață (clasa de decal existentă, culoare nouă) | pe linia ideală, în viraje |

### 5.2 Structuri mari (hero, unice)
| asset | dimensiuni | descriere |
|---|---|---|
| `shaman_rock.glb` | 2 colțuri: 22×14×18 m și 15×10×12 m | marmură albă-cenușie cu vene, licheni roșu-cărămiziu pe fețele sudice, gheață la bază; siluetele reale (doi „dinți" cu o șa între ei) |
| `serge_pole.glb` (3 variante) | 2.5 m înalt, Ø 20 cm | stâlp de lemn cioplit cu 3 crestături, panglici de 60–90 cm în 5 culori (mesh plan, vertex-wind); un șir de 13 pe promontoriu |
| `railway_viaduct.glb` (modular: pilă + arcadă + capăt) | arcadă 12 m deschidere, 12 m înălțime; 5 arcade | piatră cenușie cioplită, terasament de pietriș, șine + traverse pe deasupra (șinele = kerb-ul pistei), țurțuri sub arcade |
| `railway_tunnel_portal.glb` | 7×7 m gură, 40 m lungime | portal de piatră cu boltă, placă cu „1904" pe frontispiciu (placă în relief, fără text real), interior cu nișe laterale la 12 m (refugiul), gheață pe pereți |
| `ice_grotto_arch.glb` | 12 m deschidere, 9 m înalt, 25 m adâncime | stâncă de faleză îmbrăcată în țurțuri lungi (1–3 m) și „draperii" de gheață; interior albastru; 3–4 țurțuri separate (`icicle_dropper.glb`) ca piese detașabile |
| `khuzhir_church.glb` | 9×7 m, turlă 12 m | biserică mică de lemn, albă cu cupolă albastră și cruce; POI de sosire |
| `hovercraft_khivus.glb` | 9×3.5×3 m | ambarcațiune pe pernă de aer: fustă neagră gonflată, cabină alb-portocalie cu geamuri, elice carenată în spate cu grilă; PathMover, jet de zăpadă din cod |
| `train_baikal.glb` | locomotivă 14 m + 2 vagoane 12 m | locomotivă diesel verde-închis cu bot rotund (stil sovietic M62), vagoane verzi cu dungi galbene, gheață pe acoperiș, far galben — hazard |
| `power_pylon_soviet.glb` | 25 m | stâlp de înaltă tensiune metalic ruginit, cu izolatori; 3–4 pe deal, legați cu fire (linii simple) |
| `start_gate_logs.glb` | 10 m lățime | poartă de start din bârne rotunde, panou de lemn, stegulețe înghețate |

### 5.3 Satul Khuzhir (kit modular)
| asset | dimensiuni | descriere |
|---|---|---|
| `log_house_a/b/c.glb` | 8×6×5 m, 10×7×6 m, 6×5×4 m | case de bârne închise la culoare (log_dark), tocuri de fereastră albastre sau albe cu ornamente sculptate (nalichniki) — 2 culori de toc, acoperiș de tablă verde sau ardezie cu zăpadă groasă, horn cu fum (particule din cod) |
| `plank_fence.glb` (modular 3 m) | 1.6 m | gard de scânduri verticale gri-brun, cu poartă și zăpadă pe muchii |
| `banya.glb` | 4×3×3 m | baia mică de bârne, aburi la ușă |
| `fish_dryer.glb` | 3×1.5×2 m | ramă de lemn cu șiruri de omul (pește argintiu) atârnat |
| `sled_wooden.glb` | 1.8 m | sanie de lemn cu tălpi metalice; 5–6 în sat și tabără |
| `uaz_bukhanka.glb` | 4.5×2×2.2 m | dubă „pâine" UAZ, verde-oliv sau bej, zăpadă pe capotă; parcată (static) |
| `kamaz_truck.glb` | 8×2.5×3 m | camion portocaliu-ruginiu cu prelată; parcat pe gheață (static) |
| `well_crane.glb` | 4 m | fântână cu cumpănă |
| `woodpile.glb` | 3×1×1.5 m | stivă de lemne acoperită cu zăpadă |
| `barrels_crates.glb` | set | butoaie albastre, lăzi de pește, canistre |
| `husky_dog.glb` (animat) | 0.6 m la greabăn | câine husky alb-gri, animații Idle/Walk/Run — figurant PathMover |
| `village_signpost.glb` | 3 m | stâlp cu săgeți de lemn (fără text) |

### 5.4 Gheața și lacul
| asset | dimensiuni | descriere |
|---|---|---|
| `toros_ridge_a/b/c.glb` | 4–10 m lung, 0.6–1.5 m înalt | creste de plăci de gheață sparte, împinse una peste alta, turcoaz-albastru, muchii albe; cu coliziune de rampă (kicker) |
| `ice_slab_cracked.glb` | placă 7×7 m, grosime 0.8 m | placă poligonală cu muchii de gheață albă, apă neagră pe margine — corpul hazardului care se înclină |
| `ice_road_marker.glb` | 1.5 m | băț de lemn cu steguleț roșu / triunghi reflectorizant, la fiecare 20 m pe drumul de gheață |
| `ice_road_sign.glb` | 2 m | indicator rutier rusesc (cerc alb cu margine roșie, fără cifre) înfipt într-un bloc de gheață |
| `ice_hole.glb` (copcă) | Ø 0.5 m | gaură rotundă în gheață cu apă neagră, zăpadă scoasă în jur, undiță și scăunel |
| `fisher_tent.glb` (2 variante) | 2×2×1.8 m | cort mic de iarnă, verde sau portocaliu decolorat, cu horn de sobă |
| `nerpa_seal.glb` (animat) | 1.3 m | focă gri-argintie rotundă cu ochi mari; Idle (se uită), Dive (se scufundă) |
| `ice_block_stack.glb` | 1×1×0.5 m per bloc | blocuri de gheață tăiate, stivuite (transparență pictată) |
| `frozen_boat.glb` | 5 m | barcă de lemn prinsă în gheață la mal, pe jumătate îngropată în zăpadă |
| `ice_shard_debris.glb` | set mic | cioburi de gheață sparte pentru marginile plăcilor |

### 5.5 Mal, deal, pădure
| asset | dimensiuni | descriere |
|---|---|---|
| `larch_winter.glb` (3 variante) | 10–16 m | larice fără ace (siluete ruginii, ramuri fine) — mesh de crengi în 3 planuri încrucișate + trunchi |
| `birch_winter.glb` (3 variante) | 8–14 m | mesteacăn cu trunchi alb cu dungi negre, coroană de crengi violacee, zăpadă pe ramuri |
| `pine_siberian.glb` (2 variante) | 12–18 m | pin siberian verde-închis cu zăpadă pe „palme" |
| `shrub_snow.glb` | 1 m | tufe uscate sub zăpadă |
| `grass_tuft_dry.glb` | 0.4 m | smocuri de iarbă galbenă ieșind din zăpadă |
| `boulder_lichen.glb` (3 variante) | 1–3 m | bolovani gri cu licheni portocalii și capac de zăpadă |
| `cliff_face_olkhon.glb` (modular) | 15–30 m | falezele insulei: rocă stratificată gri-brun cu gheață scursă pe ea |
| `hunting_cabin.glb` | 5×4×3.5 m | cabană de bârne cu verandă, în pădure |
| `wooden_stairs_shore.glb` | 12 m | scări de lemn care coboară de pe faleză la gheață (decor la Stânca Șamanului) |

### 5.6 Fundal și atmosferă (siluete, `horizon_class`)
| asset | descriere |
|---|---|
| `mountain_ring_baikal.glb` | inel de munți joși cu zăpadă (Munții Primorsky), la 300+ m, siluete albăstrui-albe |
| `far_shore_forest` | fâșie de pădure întunecată pe malul opus (bandă plană cu textură) |
| `sun_disc_low` | soare jos, alb-gălbui, cu halou (sprite în cer) |
| ceață | `fog` alb-lăptos, `fog_end` ~260 m; cer gradient alb → roz pal → albastru pal în zenit |
| particule | zăpadă spulberată la sol pe direcția vântului; fum de horn; jet de zăpadă al hovercraftului; cioburi de gheață la drift |

### 5.7 Sunet (referință pentru mai târziu)
gheața care „cântă" (troznet lung, ambient), vânt, scrâșnet de gheață la
drift, trosnet scurt la placa care se înclină, elicea hovercraftului, sirena
trenului din tunel, câini care latră în sat, nerpa care suflă.

## 6. Bugete și costuri (estimare, se măsoară)

- triunghiuri: țintă sub 400k pe pistă (kit sat ~40k, pădure ~120k cu 3
  planuri pe copac, viaduct+tunel ~15k, gheață teren ~30k, restul decor ~60k)
- materiale: atlas + `ice_material` + `snow_material` + `rock_material` +
  decal-uri + hovercraft/tren (pot sta pe atlas) → țintă **≤ 20**
- lumină: o singură direcțională, joasă (elevație ~15°), caldă; umbre lungi

## 7. Ordinea de construcție recomandată

Stadiu (18 aug 2026, PR #283–#290, toate în main):

| pas | ce e făcut | unde |
|---|---|---|
| 1 traseu + temă | `Track10.tscn` (traseul din §2, 1603 m, editabil din nodul Path), tema `baikal`: placă înghețată cu coliziune, zăpadă la linia gheții, soare jos, vânt; cornișa viaductului | #283 |
| 2 gheață + vânt | `custom_ice_ranges` (grip 1.5, bandă proprie, bețe cu stegulețe), `wind_at`; textura de clasă `ice` pictată (`tools/paint_ice.py`) pe placă și bandă | #283, #287 |
| 3 hazarde | câmpul de plăci crăpate la C (`IceFieldHazard` #314, a înlocuit cele 3 plăci `IceSlabHazard` din #284); hovercraft = figurant cu suflu pe larg + traversări pe culoar (0.30 hovercraft, 0.50 sania pescarului); tren PE SENS pe viaduct (`TrainHazard.along_road` + AI care se ține de margine); torosuri (`custom_hummock_fracs`, 2 buc.); arcada grotei (granit, placeholder) | #284–#286, #288, #290, #314 |
| 4 decor | props `baikal` (iarnă: pini, stânci, petice de zăpadă; fără flori/fân/garduri); satul de la start din landmark-uri (chalet-uri, biserică, baracă) — toate provizorii până la kit | #288, #289 |
| sonde | `ProbePathFracs`, `ProbeIce` (6 pași), `ProbeIceSlab`, `ProbeTrainAlong`; ProbeLayout OK, ProbeRace 0 repuneri, probe_decor 263k tris / 29 materiale | — |

Rămân, în ordinea din §3/§5: modelele (hovercraft Khivus pe markerul de la
0.30, nerpa, grota cu țurțuri, viaduct de piatră, kitul de sat/gheață/pădure,
serge, Stânca Șamanului), țurțurii care cad la trecere, sunetul (gheața care
„cântă", vânt, elice), și — cel mai important — verdictul de feel al
dezvoltatorului la volan: gripul 1.5 și vântul 2.2·√2 m/s² sunt prima
măsurătoare, nu ultima.

1. `Track10.tscn` din `TrackFromPath`, temă `baikal` (paletă + fog + horizon),
   traseul desenat, ProbeLayout OK.
2. Suprafața de gheață + vânt (mecanicile noi) — sonda de feel: e fun un tur
   singur, doar cu drift pe gheață? Dacă nu, restul nu contează.
3. Hero-assets în ordinea POI-urilor: Stânca Șamanului + serge, viaduct +
   tunel, grotă, hovercraft, tren.
4. Kit sat + kit pădure (statistice).
5. Placa care se înclină, țurțuri, nerpa (hazardele mici).
6. probe_decor, ProbeRace, tur de mână.

---

## 8. Prompt pentru ChatGPT (dioramă de referință) — v2, paste-ready

> v1 a produs o dioramă cu inventarul corect, dar cu drumul ca inel de asfalt
> ÎN JURUL lacului (gheața era ornament în mijloc), tunelul doar pentru tren,
> serge pe un pod, grota izolată în lac și un stil prea pictat-fin. v2 corectează
> exact astea. Corecțiile sunt marcate cu **[!]** ca să le poți întări dacă
> generatorul le ignoră din nou.

> Create a stylized low-poly **tabletop diorama** of a toy-car racing track set on
> **frozen Lake Baikal, Olkhon Island, Siberia, late winter**.
>
> **STYLE (strict):** faceted, flat-shaded low-poly meshes like a Blender viewport
> render — **no fine surface texture, no painterly brushwork, no photorealism**.
> Chunky toy proportions: cars are stubby and ~1.3× wider than real cars, houses
> and trees are simplified into a few big planes. Soft baked ambient occlusion in
> the crevices, muted environment colors (~50% saturation) with only three
> saturated accents: the ribbons on the ritual poles, the hovercraft, and the toy
> cars. One single low warm sun from the left (about 15° above the horizon), long
> soft blue shadows across the WHOLE overview. Sky is a plain gradient — milky
> white at the horizon, pale pink, pale blue at the zenith — no painted clouds.
> Show the diorama on a thin dark rounded-rectangle table base, from a raised 3/4
> view.
>
> **THE ROUTE — this is the important part [!]:** the racing route is a single
> closed loop of about 1.7 km. **Half of the loop is ON the lake ice** and half is
> on the shore. On the ice there is **NO asphalt at all** — the racing line is
> only marked by thin wooden sticks with small red flags every ~20 m, driven
> straight into the ice. Asphalt / packed snow road exists only on the shore
> half. The lake ice is a wide open plain the cars drift across, not a pond in
> the middle of a ring road.
>
> Clockwise, the loop passes:
> 1. **Start/finish in a Siberian fishing village** (Khuzhir), on the shore, on
>    packed snow: dark log cabins with carved blue/white window frames, snowy tin
>    roofs, chimney smoke, plank fences, wooden sleds, an olive-green UAZ van,
>    racks of drying fish, husky dogs, a small white wooden church with a blue
>    onion dome, a start gate built from round logs with a checkered banner.
> 2. **The Shaman Rock cape [!]:** the road leaves the village onto a rocky
>    promontory. On the lake side stand two white-grey marble crags with orange
>    lichen; on the land side, **on the ground of the cape (not on a bridge)**,
>    a row of 13 wooden Buryat ritual poles (serge) with fluttering ribbons in
>    blue, white, yellow, red, green. A wooden staircase leads from the cape down
>    to the ice. The road curves wide around the poles.
> 3. **A ramp DOWN onto the ice [!]:** the road descends a snowy 15% slope from
>    the cape onto the frozen lake, and the asphalt ends there — from here on
>    only red-flag sticks mark the way.
> 4. **The ice highway:** turquoise transparent ice with a web of black cracks
>    and layered white frozen methane bubbles; the marked lane runs across it,
>    crossing **diagonal ridges of broken pale-blue ice (hummocks)** used as small
>    jumps; an old orange Kamaz truck parked on the ice; a Russian round road
>    sign frozen into an ice block; a white-and-orange **hovercraft** crossing
>    the marked lane at an angle, trailing a plume of snow.
> 5. **The cracked-slab field [!] — ON the route:** the marked lane goes straight
>    through a field of big polygonal ice plates with wide dark fissures showing
>    black water; one plate is tilted with a toy car sliding on it.
> 6. **The ice grotto [!] — ON the route:** the lane reaches a rocky cape of the
>    island and passes **under a natural cliff arch** draped in long icicles and
>    frozen "curtains" of ice, glowing blue inside. Not an isolated cave in the
>    lake — a cliff the road tunnels through.
> 7. **An ice-fishing camp:** round holes in the ice, small green/orange winter
>    tents with stove pipes, crates, sleds, and a round grey **Baikal seal (nerpa)**
>    peeking out of a hole next to the lane.
> 8. **The ramp back to shore + the railway [!]:** the lane passes UNDER a stone
>    railway viaduct (Circum-Baikal Railway, five stone arches spanning an inlet,
>    ~12 m above the ice), then climbs the embankment and **the road runs ON TOP of
>    the railway, between the rails, across the viaduct with no guardrail, and
>    INTO the same stone tunnel portal the train uses**, cut into the cliff. A
>    short dark-green Soviet diesel locomotive with two green carriages is coming
>    out of that tunnel toward the cars.
> 9. **A birch and larch forest** on low snowy hills: white birch trunks with
>    black stripes, rusty-orange leafless larches, dark Siberian pines with snow
>    on the branches, dry yellow grass through the snow, lichen-covered boulders,
>    a rusty Soviet high-voltage pylon, a small log hunting cabin. The road
>    snakes down through the trees back to the village.
>
> **Details that matter:** red-and-white curbs on the shore-road corners; all
> ribbons and flags blow in the SAME direction (wind from the open lake); the
> shore half has real elevation (the railway section is the highest point, the
> lake is the lowest); the ice is one continuous surface, and it is clearly the
> lowest, flattest, largest thing in the diorama.
>
> Background: a ring of low snowy blue mountains and a dark forest strip on the
> far shore, fading into haze; a low pale sun with a soft halo.
>
> Toy cars: 4–6 chunky low-poly racing cars in saturated red, blue, yellow,
> white, drifting on the ice with small ice-shard puffs.
>
> Colors: ice turquoise #7FC4C9, deep ice #2F6E82, crack black-blue #1A2A33,
> snow #EEF2F4, larch rust #A8683A, dark logs #4A3526, marble grey #B8B4AC,
> weathered wood #835C34, rust metal #91461E, dry grass #AF9F4E.
>
> Deliver: (a) one wide 3/4 overview of the entire diorama with the route clearly
> readable as one loop; (b) one low driver's-eye shot on the ice lane between the
> red-flag sticks, with the Shaman Rock and serge poles behind and the hovercraft
> crossing ahead; (c) one shot from the ice looking up at the viaduct with the
> road on top of the rails and the train emerging from the tunnel.

## 9. Prompturi per asset (pentru referințele de Blender)

Diorama e pentru compoziție. Pentru fiecare asset se cere separat o planșă
curată; din ea se scrie brief-ul în `docs/asset_briefs/`. Șablonul:

> Same low-poly flat-shaded style as the Baikal diorama (faceted meshes, no
> surface texture, soft AO, muted colors, one low warm sun). **Turnaround sheet**
> of `<ASSET>` on a plain neutral grey background, no scene, no ground clutter:
> front view, side view, top view and one 3/4 view, all orthographic, same scale,
> with a 1 m scale bar. Show only this object. `<ASSET-SPECIFIC LINE>`

`<ASSET>` + linia specifică, pentru hero-uri:

| asset | linia specifică |
|---|---|
| Shaman Rock | two white-grey marble crags (22×14×18 m and 15×10×12 m) with a saddle between, orange lichen on the sunny faces, ice at the base |
| serge pole (×3 variants) | 2.5 m carved wooden post with three notches, ribbons 60–90 cm in blue/white/yellow/red/green; show ribbon planes as flat strips |
| railway viaduct (modular) | one pier + one 12 m stone arch + one end piece, grey dressed stone, gravel bed, rails and sleepers on top, icicles under the arch |
| tunnel portal | 7×7 m stone arch portal with a blank plaque, 40 m tunnel with side niches every 12 m, ice on the walls |
| ice grotto arch | 12 m wide, 9 m tall, 25 m deep cliff arch draped in icicles and frozen curtains, blue interior; 4 detachable icicles |
| Khuzhir church | small white wooden church 9×7 m, 12 m blue onion-dome tower with a cross |
| hovercraft Khivus | 9×3.5×3 m: black inflated skirt, white-and-orange cabin with windows, ducted propeller with grille at the rear |
| Baikal train | dark-green Soviet M62-style diesel locomotive (14 m, rounded nose, yellow headlight) + two green carriages with a yellow stripe, ice on the roofs |
| Soviet power pylon | 25 m rusty lattice pylon with insulators |
| log start gate | 10 m wide gate of round logs, wooden panel, frozen small flags |

Kituri (o planșă pe kit, obiectele aliniate pe un rând, aceeași scară):

| kit | conținut |
|---|---|
| village kit | log houses A/B/C (8×6×5, 10×7×6, 6×5×4 m) with carved window frames in 2 colors, plank fence 3 m module + gate, banya, fish-drying rack, wooden sled, UAZ van, Kamaz truck, well with sweep, woodpile, barrels + crates, signpost, husky dog (T-pose) |
| ice kit | hummock ridges A/B/C (4–10 m), cracked slab 7×7 m, red-flag stick, road sign in ice block, ice hole with rod and stool, fisher tent ×2, nerpa seal (idle pose), stacked ice blocks, frozen boat, ice shards |
| forest kit | winter larch ×3 (10–16 m), winter birch ×3 (8–14 m), Siberian pine ×2 (12–18 m), snowy shrub, dry grass tuft, lichen boulders ×3, cliff face module 15–30 m, hunting cabin, wooden shore staircase 12 m |

## 10. Scurtăturile: măsurate, nu obținute (august 2026)

Brief-ul cere două scurtături — §2 la **B** (printre serge, `branch_half_width`
2.5) și la **E** (printre corturi, `speed_factor` 0.85). **Niciuna nu poate
exista acolo**, și motivul e geometric, nu de reglaj.

O scurtătură are sens doar unde traseul OCOLEȘTE ceva: câștigul e diferența
dintre arc și coardă. Măsurat pe toată bucla, fereastră cu fereastră:

| zonă | frac | arc | coardă | câștig posibil |
|---|---|---|---|---|
| serge (B) | 0.085–0.132 | 78 m | 76 m | **3 m** |
| tabăra (E) | 0.455–0.515 | 101 m | 102 m | **0 m** |
| intrarea în sat | 0.925–0.005 | 122 m | 90 m | 33 m |
| intrarea în sat, larg | 0.88–0.04 | 241 m | 136 m | 88 m |

Pe B și E traseul e aproape drept — nu există ocol de tăiat, deci orice bandă
desenată acolo iese **mai lungă** decât drumul principal (măsurat: −46% și
−117%). Nu e o problemă de unde pui punctele.

Singurul ocol real e **intrarea în sat**. Acolo o bandă trece ProbeLayout
(câștig 18–24 m), dar **pică ProbeRace**: 9–11% offroad, 2–9 lovituri de
perete, o repunere. Cauza e a doua constrângere, care se compune cu prima:
banda trebuie să stea la `2 × half_width` = 14 m de buclă, deci racordurile ies
cu **raza 3.5–8 m**, când cel mai strâns viraj de pe pista principală are 15.7 m.
Mașinile nu pot intra la unghiul ăla cu viteza cu care ajung acolo. Lățirea
benzii înrăutățește (2 → 8 pereți): atrage mai multe mașini într-un racord care
tot nu le poate primi.

Concluzia e aplicată (PR #300): rândul B din §2 nu mai cere scurtătura, iar
harta 2D (`img/baikal_map.html`) o spune explicit la POI-ul B.

**Ce ar debloca scurtăturile:** un cot mai pronunțat pe traseul principal, care
să creeze ocolul de tăiat. Intrarea în sat e candidatul natural — e oricum felia
cea mai lentă a turului (16.6 m/s, 35% timp „lent", raza 15.7 m), deci un traseu
retrasat acolo rezolvă două lucruri odată. Asta cere însă mutat puncte pe Path3D,
adică o decizie de traseu, nu una de decor.
