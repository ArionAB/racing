# Track brief — Stromboli (`Track11`, temă `stromboli`) — v2

> Concept de pistă + lista completă de assets. Secțiunea finală e un prompt
> paste-ready pentru generarea unei diorame de referință (ChatGPT / imagine),
> din care apoi se scriu brief-urile individuale de asset în `docs/asset_briefs/`
> și scripturile `tools/blender/build_*.py`. Harta interactivă cu loturile de
> assets la scară: `img/stromboli_map.html` (artefactul „Stromboli Recon").
>
> **v2 (22 aug 2026):** traseul URCĂ pe vulcan — serpentine până pe buza
> craterului, coborâre pe marginea Sciarei. v1 ocolea conul pe la poale și a
> picat la verificarea cu frustumul camerei (vezi §2.0): vulcanul nu s-ar fi
> văzut niciodată. Decizia dezvoltatorului: v2.

## 0. Într-o propoziție

Sfârșit de după-amiază pe insula Stromboli, „farul Mediteranei": pornești din
satul eolian alb, prinzi viteză pe plaja de nisip negru, apoi **urci în
serpentine prin terasele de malvasia până pe buza craterului** — cu marea și
satul căzând sub tine — arunci o privire **în craterul incandescent**, cobori
în picaj pe marginea Sciarei del Fuoco printre bombe, iar jos **limba de lavă
închide, tur după tur, ruta scurtă**. Singura pistă din joc al cărei traseu
optim se schimbă în timpul cursei — și singura pe care poți cădea și în mare,
și în crater.

## 1. De ce Stromboli (referința reală, ce luăm din ea)

| loc real | ce luăm |
|---|---|
| **Erupțiile stromboliene** (la 10–20 min, de ~2000 de ani) | contractul de design: hazard **ciclic, previzibil, învățabil**. Perioada în joc: ~45 s, sub durata turului, ca faza să se mute de la tur la tur |
| **Sciara del Fuoco** | versantul-canal pe care materialul incandescent se rostogolește din crater în mare — la noi e **coborârea**: drumul ține marginea canalului, bombele sar în paralel |
| **Buza craterului** | traseele turistice reale chiar urcă pe creastă la punctele de belvedere; la noi creasta devine carosabil — singurul loc din joc de unde camera poate vedea un crater |
| **Satul San Vincenzo** | case cubice albe eoliene cu terase și pergole (pulèra), biserica albă cu campanil, ulițe înguste, Ape Piaggio în loc de mașini |
| **Plajele de nisip negru** (Piscità, Ficogrande) | fâșie de coastă neagră cu bărci de pescari; nisipul adânc de lângă linie = pedeapsa de frecare |
| **Ginostra** | cătunul de pe flancul opus, „cel mai mic port din lume" — respiro tehnic, alb pe negru |
| **Terasele de malvasia** | ziduri de piatră neagră (muretti a secco), rânduri de viță — acum sunt etajul de jos al urcării |
| **Strombolicchio** | neck vulcanic în mare cu far în vârf — silueta-semnătură a fundalului, trasă în interiorul lui `fog_end` |
| **Vegetația mediteraneană** | măslini, smochini, opuntia, capere, ginestre — verde prăfuit pe negru |
| **Observatorul de la Punta Labronzo** | terasa cu copertină — POI la jumătatea urcării, primul loc cu vedere spre Sciara |

Culorile locului: negru de bazalt și nisip, alb de var, turcoaz de mare,
verde prăfuit de tufăriș, **portocaliu incandescent de lavă** (singurul slot
nou de paletă). Lumina: soare jos, cald (~20°), umbre lungi.

## 2.0 De ce traseul urcă (verificarea cu camera — motivul lui v2)

`ChaseCamera`: 12.5 m în spate, 10 m sus, 28.7° în jos, FOV 68°. Conul de
vedere: **~5° deasupra orizontalei, ~63° sub ea.** La distanță orizontală `d`
vezi în sus cel mult `10 + 0.093·d` metri:

- vârf de ~100 m la 120 m lateral (v1): vizibil până la **~21 m** — vezi un
  perete de pantă, nu un vulcan. Ca să încapă vârful în cadru ar trebui
  ~970 m distanță — de 2.5× peste `FAR_PLANE` (380 m). **Un vulcan înalt e
  invizibil de la poalele lui, la orice cotă rezonabilă.**
- în schimb camera vede **63° în jos**: de pe buză, craterul incandescent și
  marea de sub tine umplu cadrul. Tot ce e impresionant trebuie pus SUB
  jucător — regula din `ref_notes/world_design.md`, aplicată de data asta și
  la vulcanul nostru.

Consecința de design: **vulcanul nu se arată, se urcă.** Dezvăluirea
(sat → mare → crater) e câștigată prin altitudine, pe parcursul a ~40% din tur.

## 2. Traseul și punctele de interes (POI)

Lungime țintă **~2.0 km** (tur ~60 s, cursă 3 tururi ≈ 3:00 — limita de sus a
ferestrei din CLAUDE.md; trei tururi sunt necesare gimmick-ului). Sens:
antiorar — marea pe dreapta pe coastă și **tot pe dreapta, jos, de pe buza
craterului**. Punctul maxim: **~70 m**, pe buză. Fracțiile sunt orientative —
se măsoară cu ProbeLayout după desen. Conul e teren (`TerrainPeak`), buza și
serpentinele sunt carosabil pe el.

```
              [D] buza craterului (70 m)
             crater ◉ jos-stânga · marea jos-dreapta
            /                    \
   serpentine [C]                 [E] coborârea Sciarei (~19%)
   terase + observator             bombe în paralel, creste cu airtime
          |                            \
   [B] plaja neagră                 [F] bifurcația de lavă
          |                          scurt ↔ ocol (se închide per tur)
   [A] START sat ── [H] fumarole ── [G] Ginostra (port)
                     coasta de est, plată
```

| # | frac | POI | ce se întâmplă | lățime |
|---|---|---|---|---|
| **A** | 0.00 | **Start în piața satului** — biserica albă cu campanil, banner în carouri între case, pergole, un Ape parcat, bougainvillea | grilă pe dale albe-cenușii; uliță-culoar între case | 8 m |
| **B** | 0.05–0.13 | **Plaja neagră Piscità** — nisip negru bătătorit, bărci pe bușteni, plase; marea pe dreapta, **fără parapet** | fâșia rapidă a turului; nisipul adânc de lângă linie taie la ~45%; intri în mare → repunere ~2 s | 9 m |
| **C** | 0.16–0.42 | **Serpentinele** — urcarea mare: 8 → 70 m pe ~550 m de drum. Etajul de jos: terase de malvasia între ziduri de bazalt; etajul de mijloc: **observatorul** cu copertină (~35 m, prima vedere spre Sciara); etajul de sus: tufăriș ars și scorie. **Dezvăluirea**: la fiecare ac de păr, satul și marea cad tot mai jos în cadru; de la jumătate apare Strombolicchio | pantă medie ~12–13%, rampe de vârf 15–16% (precedent Baikal: 15.4%); ace de păr cu raze ≥ 16 m; parapet DOAR pe exteriorul a două ace (punctuație — unde nu vrem cădere), restul buză liberă → repunere | 7 m |
| **D** | 0.44–0.52 | **Buza craterului** — arc de ~150 m pe coamă: în stânga-jos **craterul incandescent** (camera îl vede: 63° în jos), guri de scorie, luminescență LAVA_ORANGE; în dreapta-jos marea, la ~70 m sub tine | cădere în crater = **distrugere** + repunere din stând; cădere în afară = repunere ~2 s; dacă pulsul ciclului (~45 s) te prinde pe buză, bombele pleacă de lângă tine — teatru maxim, 1 traiectorie reală peste coamă | 6.5 m (îngustarea de sus) |
| **E** | 0.54–0.66 | **Coborârea Sciarei** — zigzag pe marginea canalului: ~19% mediu, crestele dintre ace dau **airtime natural** pe fizica întreagă; bombele pulsului sar pe canal în paralel cu tine, 1–2 traiectorii taie drumul | viraje oarbe pe creste → **semnalizare în același pachet** (jaloane cu chevroane pe exterior, lecția din world_design: vizibilitatea pierdută se plătește cu semnalizare); cenușă (grip 0.85×) | 7 m |
| **F** | 0.68–0.76 | **Bifurcația de lavă** — la poalele Sciarei, pe câmpul de lavă veche: **ruta scurtă** taie câmpul (coardă ~120 m), **ocolul** cade spre țărm (arc ~190 m, scurta câștigă ~4–5 s). Limba de lavă nouă coboară CHIAR pe canalul pe care tocmai ai coborât — coerență: vezi de sus, în timpul coborârii, cât a avansat | **turul 1:** scurta liberă. **turul 2:** poartă de 4 m între două brațe incandescente. **turul 3:** închisă, zid de lavă semnalizat. Contact = distrugere + repunere din stând. AI-ul re-alege ruta per tur | scurtă 6 m / ocol 8 m |
| **G** | 0.78–0.83 | **Ginostra** — 4–5 case albe pe stâncă neagră, dana „celui mai mic port din lume", o barcă, un măgar care se ferește, scări albe | respiro: viraj strâns 6 m între case | 6 m |
| **H** | 0.86–0.96 | **Coasta de est + fumarolele** — întoarcere plată pe faleza joasă printre smochini și opuntia; 2–3 **fumarole** suflă coloane de abur peste drum | **hazard-teatru, cost zero** (clasa din ref 05): albire parțială ~0.5 s, șuier — atât. Înveți să treci cu turbo. Ultima șansă de depășire înainte de sat | 7 m |
| **A′** | 1.00 | intrare în sat pe sub o arcadă albă, sosire în piață | | 8 m |

**Ritmul turului:** sat (strâmt) → plajă (viteză) → serpentine (tehnic lung,
dezvăluirea) → buză (vârful emoțional: crater + frică de cădere) → picaj pe
Sciara (viteză + bombe + airtime) → bifurcație (decizia turului) → Ginostra
(strângere) → coastă cu fumarole (respiro fals, depășiri) → sat.

**Ciclul de erupție ≠ durata turului (45 s vs ~60 s), intenționat:** faza se
mută pe tur — o dată pulsul te prinde pe buză, altă dată în coborâre, altă
dată deloc. Bubuitul + coloana de cenușă anunță cu ~3 s înainte, de oriunde.

## 3. Hazarduri și mecanici (ce e nou pentru motor)

| mecanică | pe scurt | ce cere în cod |
|---|---|---|
| **Ciclul de erupție** | metronom global (~45 s): bubuit + tremur de cameră + coloană de cenușă, apoi pulsul de bombe | nod mic `EruptionCycle` cu signal; hazardele se abonează. Telegraph ~3 s |
| **Bombe incandescente** | 3–5 corpuri care sar pe canalul Sciarei, paralel cu coborârea E; 1–2 traiectorii taie drumul, 1 peste buza D | reuse `RockfallHazard` (trasee `Path3D`), declanșat de ciclu; mesh nou `volcanic_bomb` emisiv |
| **Limba de lavă pe tururi** | 3 stadii peste ruta scurtă (liber / poartă 4 m / închis); contact = distrugere | `LavaFlowHazard`: stadiu la `lap_completed` al liderului; `TrackBranch` există — nou: închiderea ramurii + AI care re-alege + semnalizare |
| **Căderea în crater** | interiorul buzei D = distrugere + repunere din stând (ca lava) | `custom_ravines` cu zonă de distrugere (variantă mică peste RespawnZone existent) |
| **Fumarole** | abur peste drum, ritm propriu, cost zero — teatru | particule + `Area3D` de albire ~0.5 s + sunet; fără fizică |
| **Nisip negru adânc** | frecare pe plajă, în afara benzii | reuse suprafețe pe interval (generalizate la Baikal) |
| **Cenușă** | grip 0.85× pe buză + coborâre | idem |
| **Marea ca pedeapsă** | plajă și buza exterioară fără parapet → repunere ~2 s | `custom_ravines` + `RespawnZone` (există) |
| **Semnalizare de pantă** | jaloane cu chevroane pe exteriorul acelor de păr și pe crestele oarbe ale coborârii | decor cu coliziune (există) — doar model `chevron_post` |
| *(rezervat)* inversare de comenzi la impactul cu bomba | clasa „sabotaj de control" din sisteme.md §3 | **NU în pachetul ăsta** — după experimentul separat pe rockfall-ul din Alpi |

Calibrarea pedepselor (din sisteme.md): distrugere/cădere ≈ 2 s + repornire
din stând ≈ 2 poziții; câștigul rutei scurte ≈ 4–5 s.

## 4. Paleta (un singur slot nou)

Neschimbată față de v1. **Au mai rămas sloturile 30–31**; Stromboli cere UNUL.

| slot | rol | hex propus |
|---|---|---|
| **30** | `LAVA_ORANGE` — lava, crăpăturile bombelor, luminescența craterului | `#E8622D`, saturație ~0.8 — semnalul pistei |
| 31 | rămâne rezervă (magenta în atlas) | — |

Reutilizate: `VOLCANIC_BLACK` 20 (bazalt, scorie, nisip negru), `FOAM_WHITE`
22 (case văruite, spumă), `REEF_SHALLOW` 17 / `SEA_DEEP` 18 (marea),
`TROPICAL_GREEN` 21 (tufăriș, viță), `MARBLE_GREY` 29 (cenușă, dalele
pieței), `TILE_TERRACOTTA` 23 (olane, ghivece), `WOOD_WEATHERED` 9 (bărci,
pergole), `RUST_METAL` 10 (scripete, balustrade), `KERB_RED` 7 (borduri,
chevroane), `DRY_VEGETATION` 13 (iarbă arsă), `ROCK_LIGHT`/`ROCK_DARK` 3/4
(stânca stratificată). Bougainvillea: `CAR_RED` 14 — abaterea conștientă de
tip serge, sub 1 m² total.

## 5. Lista completă de assets

Toate: low-poly stilizat (Art of Rally / machetă de masă), un singur material
= atlasul de paletă + AO în vertex colors; materiale de clasă doar unde scrie.
Origine la bază (linia solului / linia apei), +Y sus, „înainte" = −Z.
Dimensiunile sunt și în artefactul `img/stromboli_map.html`, la POI-ul lor.

> **✔ LIVRAT (august 2026): 36 de fișiere GLB, 36 986 de triunghiuri în total.**
> Tabelele de mai jos sunt PLANUL. Ce s-a construit efectiv, cu numele exacte
> de noduri și cifrele măsurate, e în **§5.7** — aia e sursa de adevăr pentru
> plasare. Trei nume diferă de plan (vezi §5.7), iar `start_banner_alley` nu
> există încă.
>
> Fiecare brief de asset din `docs/asset_briefs/` are secțiunea „Livrat" cu
> cotele măsurate și abaterile motivate.

### 5.1 Teren și suprafețe (generate din cod, cer texturi de clasă)
| asset | descriere | note |
|---|---|---|
| `lava_rock` (triplanar) | lavă veche pahoehoe: negru cu pliuri „de funie" și irizații gri | câmpul de la F, delta spre mare |
| `scoria_material` | scorie roșu-negru poroasă pe canalul Sciarei și etajul de sus al conului | dală în familia rock |
| `black_sand` | nisip negru cu urme de roți și dâre de val | plaja B; varianta adâncă mai mată |
| `ash_ground` | cenușă gri-deschis bătătorită pe buză și coborâre | poate refolosi dala de beton gradată spre MARBLE_GREY |
| decal `tire_tracks_black` | urme pe dalele albe ale satului și pe cenușă | clasa de decal existentă, culoare nouă |

### 5.2 Structuri mari (hero, unice)
| asset | dimensiuni | descriere |
|---|---|---|
| `stromboli_church.glb` | 12×8 m, campanil 14 m | biserica San Vincenzo stilizat: fronton curb, campanil cu trei goluri de clopot — POI-ul de start |
| `start_banner_alley.glb` | 10 m deschidere | banner în carouri între două case, sfori cu stegulețe |
| `observatory_terrace.glb` | 10×6 m, copertină la 4 m | terasa observatorului pe un ac de păr al urcării: parapet negru, copertină albă, binoclu cu fise |
| `strombolicchio.glb` | bază 30×22 m, stâncă 32 m, far +8 m | neck vulcanic zvelt cu far alb — fundal-erou la ~200 m în larg (sub `fog_end`) |
| `crater_bowl.glb` | Ø ~55 m, adânc 12–15 m | interiorul craterului văzut de pe buză: pereți de scorie în trepte, 3 guri cu buze LAVA_ORANGE emisive, fum (particulele din cod). E CE VEDE camera de pe D — piesa de rezistență vizuală |
| `lava_flow_stage1/2/3.glb` | limbi 40 / 60 / 80 m, lățime 8–12 m, crustă 0.5–1 m | râul de lavă în 3 stadii: crustă neagră, crăpături emisive; stadiul 2 lasă poarta de 4 m; stadiul 3 zid cu front bulbos |
| `volcanic_bomb.glb` (3 variante) | Ø 0.6 / 0.9 / 1.2 m | bolovani cu crustă crăpată incandescentă — proiectilele rockfall |
| `ginostra_pier.glb` | dană 8×3 m + scară 4 m | dana de beton, bolarzi, scară în stâncă |
| `fumarole_vent.glb` (3 variante) | Ø 0.8–1.5 m, h 0.4–0.8 m | guri cu depuneri galben-albe de sulf |
| `chevron_post.glb` | 1.2 m | jalon cu chevron roșu/alb — exteriorul acelor și crestele oarbe |

### 5.3 Satul eolian (kit modular — servește A și G)
| asset | dimensiuni | descriere |
|---|---|---|
| `aeolian_house_a.glb` | 7×6×4 m | casă cubică albă, terasă cu parapet rotunjit, obloane albastre/verzi |
| `aeolian_house_b.glb` | 9×7×5.5 m | două niveluri, scară exterioară, terasă cu pergolă |
| `aeolian_house_c.glb` | 5×5×3.5 m | căsuța mică / magazie |
| `pergola_pulera.glb` | 4×3 m, h 2.5 m | stâlpi albi cilindrici, grinzi de lemn |
| `white_wall.glb` (modul 3 m) | h 0.9 m | zid alb rotunjit; variantă cu poartă |
| `alley_stairs.glb` | modul 4 m | trepte late albe |
| `street_shrine.glb` | 1.5 m | edicolă cu nișă albastră |
| `ape_piaggio.glb` | 2.7×1.3×1.6 m | tricicleta Ape, verde, benă de lemn — static |
| `fishing_boat_small.glb` | 5 m | barcă pe bușteni de rulare |
| `fishing_boat_large.glb` | 7 m | ancorată la dana din G |
| `boat_winch.glb` | 2×1×1 m | scripete ruginit + bușteni |
| `nets_buoys_set.glb` | amprentă 2×2 m | plase, geamanduri portocalii |
| `bougainvillea.glb` (2 variante) | 2×2 m / arcadă 3 m | CAR_RED pe zid alb — accentul satului |
| `pot_cluster.glb` | Ø 0.3–0.6 m | teracotă, mușcate, opuntia mică |
| `donkey.glb` | 1.4 m la greabăn | figurant, se ferește la apropiere |

### 5.4 Flancul vulcanului (kit de pantă — servește C, D, E, H)
| asset | dimensiuni | descriere |
|---|---|---|
| `olive_tree.glb` (2 variante) | 5–7 m | trunchi răsucit, coroană argintie — etajul de jos |
| `fig_tree.glb` | 4–6 m | frunze mari, coroană lată — coasta H |
| `prickly_pear.glb` (2 variante) | 1.5–2.5 m | opuntia cu fructe |
| `caper_bush.glb` | 0.8 m | revărsată peste zid |
| `ginestra_bush.glb` (2 variante) | 1.5–2 m | vârfuri galbene desaturate — etajul de mijloc |
| `cane_clump.glb` | 3 m | trestie pe vâlcele |
| `terrace_wall.glb` (modul 3 m) | h 1.2 m | muretto a secco din bazalt — serpentinele de jos |
| `vine_row.glb` (modul 4 m) | h 0.8 m | malvasia joasă pe araci |
| `basalt_boulder.glb` (3 variante) | 1–3 m | fețe fațetate negre |
| `scoria_rock.glb` (3 variante) | 0.5–2 m | roșu-negru poroasă — etajul de sus + Sciara |
| `lava_slab_broken.glb` | set 2–4 m | plăci cordate rupte — marginile câmpului F |
| `coast_cliff_basalt.glb` (modular) | 10–20 m | faleze negre stratificate — coasta B și H |

### 5.5 Fundal și atmosferă (siluete, `horizon_class`)
| asset | descriere |
|---|---|
| conul vulcanului | `TerrainPeak` — de data asta traseul e PE el; trei etaje de culoare: verde jos, scorie la mijloc, cenușă sus |
| `island_silhouettes` | Panarea și Salina — siluete joase albăstrui (bandă plană) |
| plan de mare | există (Okinawa) — turcoaz spre larg, spumă la țărm |
| ceață | caldă, gălbuie; **`fog_end` ~300 m** (mai sus ca de obicei: de pe buză, diagonala până la sat e ~280 m — dezvăluirea trebuie să rămână în interiorul ceții, altfel v2 își pierde motivul) |
| particule | coloana de cenușă (pe ciclu); aburi de fumarole; scântei la bombe; praf negru la drift; fum din crater — CONSTANT, e reperul vizual al vârfului |

### 5.6 Sunet (referință pentru mai târziu)
bubuitul erupției (bas, ~3 s înaintea bombelor — telegraph-ul), sfârâitul
lavei, șuierul fumarolelor, vântul pe buză (se întărește cu altitudinea),
valuri pe nisip, clopot la start, greieri pe terase, măgarul din Ginostra.

## 5.7 Ce s-a livrat și cum se plasează

**Sursa de adevăr pentru plasare.** Tabelele §5.1–5.6 sunt planul; asta e ce
există pe disc, cu numele exacte de noduri (contract pentru `track_decor`) și
triunghiurile măsurate pe fișierul exportat.

### Abateri de nume față de plan (verifică-le înainte să cauți fișiere)

| plan (§5.2/5.3) | livrat | de ce |
|---|---|---|
| `lava_flow_stage1/2/3.glb` | **`effects/lava_flow.glb`**, un fișier cu 3 noduri | contractul cu `LavaFlowHazard` cere ca stadiile să împartă originea și coada — într-un singur fișier alinierea e garantată prin construcție |
| `nets_buoys_set.glb` | **`props/nets_buoys.glb`** | fără sufixul `_set` |
| `start_banner_alley.glb` | **nu există** | nu era în niciun brief de asset; POI A merge și fără el, dar bannerul în carouri lipsește de la linia de start |

### Inventarul complet (36 fișiere)

Rădăcina: `assets/models/stromboli/`.

| fișier | noduri | tris | POI |
|---|---|---|---|
| `structures/crater_bowl.glb` | `Crater_Bowl`, `Crater_Vents` | 2586 | D |
| `structures/strombolicchio.glb` | `Stack_Rock`, `Stack_Stairs`, `Lighthouse_White`, `Lighthouse_Lantern` | 1564 | fundal (larg) |
| `structures/observatory_terrace.glb` | `Terrace_Stone`, `Awning_Canvas`, `Terrace_Furniture` | 1562 | C (~frac 0.30) |
| `buildings/stromboli_church.glb` | `Church_Body`, `Church_Tower`, `Church_Trim` | 2296 | A |
| `buildings/aeolian_house_a.glb` | `House_A` | 836 | A, G |
| `buildings/aeolian_house_b.glb` | `House_B` | 1416 | A, G |
| `buildings/aeolian_house_c.glb` | `House_C` | 400 | A, G |
| `buildings/pergola_pulera.glb` | `Pergola_Frame`, `Pergola_Canopy` | 720 | A, G |
| `buildings/white_wall.glb` | `Wall_A`, `Wall_Gate`, `Wall_Corner` | 536 | A, G |
| `buildings/alley_stairs.glb` | `Alley_Stairs` | 396 | A, G |
| `buildings/street_shrine.glb` | `Shrine_Body`, `Shrine_Niche` | 498 | A, G, C |
| `vehicles/ape_piaggio.glb` | `Ape_Body`, `Ape_Wheels`, `Ape_Bed` | 636 | A |
| `vehicles/fishing_boat_small.glb` | `Boat_S_Hull`, `Boat_S_Trim`, `Boat_Rollers` | 350 | B |
| `vehicles/fishing_boat_large.glb` | `Boat_L_Hull`, `Boat_L_Trim`, `Boat_L_Cabin` | 350 | G (la dană) |
| `props/ginostra_pier.glb` | `Pier_Slab`, `Pier_Stairs`, `Pier_Fittings` | 612 | G |
| `props/boat_winch.glb` | `Boat_Winch` | 864 | B, G |
| `props/nets_buoys.glb` | `Net_Pile`, `Buoys` | 1348 | B, G |
| `props/fumarole_vent.glb` | `Fumarole_A/B/C` | 504 | H |
| `props/chevron_post.glb` | `Chevron_Post` | 84 | C, E |
| `props/bougainvillea.glb` | `Bougainvillea_A`, `Bougainvillea_B` | 3884 | A, G |
| `props/pot_cluster.glb` | `Pot_Cluster` | 2396 | A, G |
| `props/donkey.glb` | `Donkey` | 1276 | G |
| `effects/lava_flow.glb` | `Lava_Stage1/2/3` | 2596 | F |
| `effects/volcanic_bomb.glb` | `Bomb_S/M/L` | 654 | D, E |
| `trees/olive_tree.glb` | `Olive_Trunk_A/B`, `Olive_Canopy_A/B` | 808 | C (etaj jos) |
| `trees/fig_tree.glb` | `Fig_Trunk`, `Fig_Canopy` | 488 | H |
| `plants/prickly_pear.glb` | `Prickly_A/B` | 720 | H, C sus |
| `plants/caper_bush.glb` | `Caper_Bush` | 96 | C (pe ziduri) |
| `plants/ginestra_bush.glb` | `Ginestra_A/B` | 720 | C (etaj mijloc) |
| `plants/cane_clump.glb` | `Cane_Clump` | 432 | C (vâlcele) |
| `plants/vine_row.glb` | `Vine_Row` | 1160 | C (terase) |
| `rocks/terrace_wall.glb` | `Terrace_Wall_A/B/Corner` | 1248 | C |
| `rocks/basalt_boulder.glb` | `Basalt_A/B/C` | 346 | tot flancul |
| `rocks/scoria_rock.glb` | `Scoria_A/B/C` | 1108 | D, E |
| `rocks/lava_slab_broken.glb` | `Lava_Slab_A/B/C` | 528 | F |
| `rocks/coast_cliff_basalt.glb` | `Coast_Cliff_A/B` | 968 | B, H |

### Cum se plasează assets-urile (decor manual)

Procedura completă e în [decor_manual.md](../decor_manual.md); aici doar ce e
specific pistei ăsteia.

**1. Containerul.** În `Track11.tscn`, sub rădăcină, un `Node3D` numit
`DecorManual` cu scriptul `scenes/props/world_prop.gd`. **Fără script, toate
GLB-urile ies ALBE** — modelele n-au material propriu, culoarea vine din atlas.

**2. Grupează pe POI**, ca la Track10 (`1)START Khuzhir`, …). Convenția care
se citește ușor în arbore:

```
DecorManual
  1) A - Piata satului
  2) B - Plaja Piscita
  3) C - Serpentine
  4) D - Buza craterului
  5) E - Coborarea Sciarei
  6) F - Campul de lava
  7) G - Ginostra
  8) H - Coasta si fumarole
```

**3. Așezarea pe teren.** `PgDown` (Transform → Snap Object to Floor) lipește
obiectul de relief — terenul are coliziune. Excepțiile sunt piesele cu origine
NON-standard, care se așază pe cotă, nu pe sol:

| piesă | originea e la | cum se așază |
|---|---|---|
| `crater_bowl` | **coronament** (cuva coboară în −Y) | `y` = cota drumului de pe buză; centrul craterului din Track11 e la godot **(−109.2, y_buză, 268.3)**, în gaura din `custom_ravines[0]` |
| `strombolicchio` | **linia apei** | `y = sea_level`; poziția din hartă: godot **(−187, 0, −137)** |
| `ginostra_pier` | **linia apei** | `y = sea_level`; dana iese spre **−Z** (spre mare) |
| `fishing_boat_large` | **linia de plutire** | `y = sea_level` — plutește, nu se pune pe sol |
| `volcanic_bomb` | **centrul volumului** (se rostogolesc) | le pune `RockfallHazard` pe traseu, nu manual |
| `lava_flow` | coada, la sol | toate 3 stadiile la ACELAȘI transform (vezi mai jos) |

**4. Orientarea.** Fațadele și fețele „utile" sunt spre **−Z** (convenția
proiectului). Concret: biserica, casele, edicola, chevronul privesc spre −Z;
treptele terasei observatorului sunt spre **+Z**, iar binoclul spre −Z; scara
Strombolicchio e pe fața −Z.

**5. Modulele care se înșiruie** (`Wall_A/Gate/Corner`, `Alley_Stairs`,
`Vine_Row`, `Terrace_Wall_*`, `Coast_Cliff_A/B`) au **capete plane**, secțiune
identică. Se pun cap la cap la pasul lor exact — 3 m zidul, 4 m vița și scara,
10/15 m falezele. Un decalaj face rost vizibil la fiecare modul.

**6. Variantele din același fișier.** Un GLB cu mai multe noduri se
instanțiază o dată, iar variantele nefolosite se sting cu `visible = false` —
NU intră în numărătoarea gărzii (`probe_decor` numără doar ce se randează).
Așa se folosesc `House_A/B/C`, `Basalt_A/B/C`, `Lava_Stage1/2/3`.

**7. Materialul emisiv al lavei** se atașează la integrare, nu e în GLB. **UN
singur material de clasă**, partajat între `Crater_Vents`, `Lava_Stage*` și
`Bomb_*` — toate poartă slotul `LAVA_ORANGE` (30) în albedo. Garda numără
materialele, deci unul, nu trei.

### Cum se plasează hazardele

| hazard | nod / script | unde | cum se leagă |
|---|---|---|---|
| **`EruptionCycle`** | nod nou, copil al pistei | oriunde (e un metronom, n-are poziție) | emite semnal la ~45 s; bombele și particulele se abonează. Telegraph ~3 s înainte |
| **Bombele** | `RockfallHazard` (există) + `Path3D` sub `HazardMarker` | canalul Sciarei (E), 3–5 trasee paralele cu coborârea; 1–2 taie drumul, 1 peste buza D | traseele se desenează pe grilă și se verifică cu `Snapshot --rock-at` (memoria `rockfall-traseu-path3d`); mesh-ul: `Bomb_S/M/L`, pivot central |
| **`LavaFlowHazard`** | script NOU | ruta scurtă din F | instanțiază `lava_flow.glb` O DATĂ și comută `visible` între `Lava_Stage1/2/3` la `lap_completed` al liderului. **Toate trei au coada la origine** (y=0, cresc la 40/60/80 m), deci nodul NU se mută — dacă îl muți, limba sare în loc să avanseze |
| **Căderea în crater** | `custom_ravines` + zonă de distrugere | D, `custom_ravines[0]` (frac 0.466–0.522) există deja în `Track11.tscn` | distrugere + repunere din stând |
| **Fumarolele** | `props/fumarole_vent.glb` + particule + `Area3D` | H, 2–3 bucăți lângă drum | hazard-teatru: albire ~0.5 s + șuier, fără fizică. Asset-ul e DOAR conul |
| **Marea / buza exterioară** | `custom_ravines` + `RespawnZone` (există) | B (plaja) și exteriorul lui D | repunere ~2 s |
| **Suprafețe** | intervale pe traseu (generalizate la Baikal) | nisip adânc pe B (~45%), cenușă pe D–E (grip 0.85×) | nu cer assets |

**Coliziunea decorului** vine automat din `world_prop` pentru piesele care o
cer (memoria `decor-manual-coliziune`); se verifică cu `probe_solid`, care
plimbă gabaritul mașinii — nu se socotește pe AABB.

**Înainte de benzile statistice** (kitul de flanc, plantat cu sutele):
măsoară **tris/pas** pe lungimea benzii, nu după plantare (memoria
`vegetatie-cost-pe-pas`). Cinci piese din kitul de flanc sunt peste bugetul
lor de bandă — ordinea de tăiere e în `stromboli_slope_kit.md`.

## 6. Bugete și costuri (estimare, se măsoară)

- triunghiuri: țintă sub **400k**. **Măsurat pe assets-urile livrate: 36 986
  de triunghiuri pentru TOATE cele 36 de fișiere, o instanță din fiecare.**
  Cifra pe pistă depinde de câte instanțe plantezi — kitul de flanc e cel care
  se înmulțește cu sutele, deci acolo se măsoară tris/pas, nu la sfârșit.
  Estimarea inițială de mai jos s-a dovedit prea mare pe hero-assets
  (crater_bowl ~10k estimat → **2586** real) și prea mică pe unele piese mici
- materiale: atlas + `rock_material`/`lava_rock` + `scoria` + decal-uri +
  emisivul lavei → țintă **≤ 20**. Emisivul e UN material de clasă partajat
  (lavă + bombe + crater), nu per asset
- lumină: o singură direcțională, joasă (~20°), caldă
- **de verificat devreme cu sonde:** pantele reale ale serpentinelor și
  coborârii (ProbeLayout pe profil — media 12–13% / 19%, vârf sub 16% pe
  urcare), costul emisivului + particulele de crater pe cadru, vizibilitatea
  satului de pe buză la `fog_end` 300 (captură `--driver` din D, memoria
  `driver-view-for-composition`)

## 7. Ordinea de construcție recomandată

1. `Track11.tscn` din `TrackFromPath`, temă `stromboli` (paletă + fog 300 +
   horizon + `TerrainPeak` pentru con), traseul din §2 cu serpentinele și
   buza, ProbeLayout OK **inclusiv pe pante** (asta e riscul nr. 1 al lui v2 —
   se validează înaintea oricărui decor). Bifurcația F de la început în traseu.
2. Sonda de feel pe urcare-buză-coborâre: e fun un tur singur, cu drift în
   serpentine și airtime pe crestele coborârii? **Captura `--driver` de pe
   buză: se vede craterul? se vede satul jos?** Dacă nu, v2 se reface aici,
   nu după decor.
3. Suprafețele (nisip negru, cenușă) + marea/craterul ca pedeapsă.
4. `EruptionCycle` + bombele pe Sciara (reuse rockfall) — se citește
   telegraph-ul? te învârte sau te frustrează?
5. `LavaFlowHazard` cu 3 stadii + AI care re-alege + semnalizare. ProbeRace
   pe 3 tururi: AI-ul nu intră în lavă la turul 2–3; distribuții A/B
   (memoria `proberace-nedeterminism`).
6. Hero-assets în ordinea POI-urilor: biserica + kit sat, **crater_bowl**,
   Strombolicchio, observatorul, lava (stadiile), fumarolele, chevroanele.
   **✔ FĂCUT** (august 2026) — vezi §5.7.
7. Kit flanc (statistice), figuranți. probe_decor, ProbeRace, tur de mână —
   verdictul de feel al dezvoltatorului. **✔ assets FĂCUTE**; plantarea și
   sondele rămân.

> **Stare reală (august 2026): pașii 1–7 sunt făcuți, mai puțin plantarea.**
> Ce rămâne e **decorul manual** (§5.7) și verdictul de feel al
> dezvoltatorului, la volan.

### Ce au găsit sondele la pașii 2–5

**Pasul 2 — validat, după trei reparații.** Prima captură `--driver` de pe
buză a picat, și fiecare cauză a fost alta decât părea:

1. *Tema era Okinawa cu alt traseu.* `inland_tint` = `TROPICAL_GREEN` la 0.75,
   copiat de la insula tropicală: captura de sus arăta o insulă **verde**.
   Reparat cu **trei etaje de culoare** pe con, din mecanisme care existau
   deja (zero cod nou, zero sloturi noi): verde doar la poale (0.40), scorie
   de la 18 m (`rock_band_tint`, mecanismul alpin), cenușă de la 48 m
   (`snow_tint`).
2. *Drumul era nisip auriu.* `DIRT_ROAD_COLOR` e constanta deșertului.
   Adăugat `dirt_road_tint` ca aceeași cheie de temă ca `ice_road_tint` de pe
   Baikal, plus accesorul `dirt_road_color()`. Temele care n-o declară rămân
   neatinse.
3. *Nu se citea altitudinea* — defectul real. Profilul confirma că traseul
   **urcă** (3.7 → 60.8 m pe 40% din tur), iar ravena craterului funcționa
   (14.4 m măsurați). Dar `CraterPeak` (rază 60) cădea aproape integral în
   banda de protecție a asfaltului (`PEAK_ROAD_FULL` = 32 m, iar șoseaua trece
   la 42 m de centru): ieșea o **mesa cu vârf plat**.
   > Reparația n-a fost o cotă, ci o înțelegere: **craterul e o gaură, nu o
   > culme.** Interiorul buzei îl face `crater_bowl.glb`, nu terenul.
   > `CraterPeak` șters; `FlanculConului` urcat la 72 m și lățit la rază 200.

**Verdict: trece.** De pe buză marea e jos în cadru, peretele craterului cade
în stânga, serpentinele se văd ca fiind *sub* tine.

Măsurat: urcare medie **7–9%** (brief-ul cere 12–13%, deci mai blând, nu mai
abrupt), panta maximă la frac 0.64 — coborârea Sciarei, unde brief-ul chiar
vrea ~19%.

**Pasul 3 — suprafețe afânate.** Cenușa și nisipul negru adânc folosesc
**același mecanism ca gheața de pe Baikal** (`is_loose_at` + `loose_grip`),
nu unul nou: e același fel de lucru — o porțiune pe care grip-ul e altul — iar
două mecanisme s-ar tuna separat și ar diverge. Declarate în `Track11.tscn` ca
`custom_loose_ranges`: plaja B (0.05–0.13) și buza + coborârea D–E (0.44–0.66),
la 6.8 din 8 (0.85×, cifra din §3).

**Pasul 4 — `EruptionCycle`.** Un nod fără geometrie, care bate ritmul (45 s,
telegraph 3 s) și **sincronizează ceasurile** tuturor hazardelor dintr-un grup.
Bombele sunt `RockfallHazard`-uri cu traseu, fiecare cu `period` + `phase` — pe
cont propriu ar bate fiecare în ritmul lui și pe pistă ar ploua cu pietre
continuu. Erupția reală e un **puls**: liniște lungă, apoi câteva secunde în
care sar toate. Aia se poate învăța, deci e mecanică, nu taxă.

**Pasul 5 — `LavaFlowHazard`.** Verificat cu sondă, stadiile se comută corect:

| tur | stadiu | vizibil | scurtătura |
|---|---|---|---|
| 1 | 0 | `Lava_Stage1` | DESCHISĂ |
| 2 | 1 | `Lava_Stage2` | DESCHISĂ (poarta de 4 m) |
| 3 | 2 | `Lava_Stage3` | **ÎNCHISĂ** |

Poarta de 4 m rămâne **deschisă** deliberat: măsurat pe mesh, culoarul are
4.00 m liberi iar mașina 1.8 m — trece, dar cere linie curată. Aia e decizia
pe care o vindem, deci n-o luăm noi de la jucător.

**AI-ul re-alege.** `prefers_shortcut` se trage o dată pe cursă în
`AIController`, deci fără nimic altceva un AI care a decis la turul 1 „o iau pe
scurtă" ar intra în zid la turul 3. Adăugat `Track.branch_is_open(index)`,
întrebat la fiecare cadru.

**ProbeRace pe Stromboli** (150 s, 6 mașini): **0 repuneri, 0 atingeri de
pereți**, toate mașinile termină tururi, ecart de ritm 0.46 tururi. Nimeni nu
se blochează pe urcare. Singura felie „lentă" (0.95–1.00, 17.1 m/s) e
**startul**, nu un defect: felia vecină 0.00–0.05 are 28.6 m/s și 0% lent, iar
geometria de acolo e dreaptă (rază ~999 m).

### Capcane de proces (ca să nu se replătească)

**Indicii de pistă diferă între unelte.** `Snapshot` și `ProbeRace` folosesc
**poziția în listă** (`GameState.TRACK_SCENES`) — Stromboli e **4**.
`survey_terrain` folosește **numărul scenei** — Track**11**. Un `--track=11`
dat la ProbeRace se lovește de `Out of bounds` și apoi toarnă zeci de mii de
erori derivate, care ascund cauza.

**Un UID greșit nu dă eroare, dă alt asset.** Prima instanță de lavă din
`Track11.tscn` avea UID-ul lui `crater_bowl` — scena se încărca fără să se
plângă, dar nodurile erau `Crater_Bowl`/`Crater_Vents`. S-a văzut doar fiindcă
`LavaFlowHazard` avertizează pe nume lipsă (avertismentul din `okinawa_kit.md`,
pus în cod). **Verifică UID-ul în `.glb.import`, nu îl copia dintr-o linie
vecină.**

## 8. Lecții aplicate anticipat (ca să nu le replătim)

- **Frustumul decide ce se vede, nu intenția.** v1 a picat exact pe asta
  (§2.0). Orice POI vizual nou se verifică cu `10 + 0.093·d` înainte să intre
  în brief — și cu o captură `--driver` după.
- **Vizibilitatea pierdută se plătește cu semnalizare** (world_design):
  crestele coborârii și acele de păr primesc chevroane ÎN ACELAȘI pachet cu
  traseul, nu ca follow-up.
- **Pantele se măsoară cu ProbeLayout înainte de decor** — media 12–13% pe
  urcare (rampe sub 16%, precedent Baikal 15.4%), ~19% pe coborâre. Peste
  asta, serpentinele se lungesc, nu se forțează.
- **Bifurcația e ocol real, nu bandă paralelă** (Baikal §10): ocolul
  (~190 m) și scurta (~120 m) se proiectează împreună, racorduri ≥ 15 m,
  separare ≥ 2 × half_width, câștig țintă 4–5 s măsurat.
- **Acele de păr:** raze > half_width, puncte eșantionate pe arc (memoriile
  `dunele-hairpin-pileup`, `viraje-stranse-puncte-pe-arc`).
- **Marginile fără parapet se taie în pantă, nu în treaptă** — praguri
  > 0.3 m sunt ziduri pentru raycast (memoria `suprafete-cu-goluri-si-praguri`).
- **Strombolicchio și satul văzut de pe buză stau sub `fog_end`** (memoria
  `efecte-de-fundal-cote-legate`) — de-asta fog-ul temei urcă la ~300 m.
- **Emisivul lavei = UN material de clasă partajat** (CLAUDE.md; garda
  numără materialele).
- **Inversarea comenzilor NU intră** până nu trece experimentul separat pe
  rockfall-ul din Alpi. Dacă trece, bombele Sciarei sunt purtătorul natural.

---

## 9. Prompt pentru ChatGPT (dioramă de referință) — v2, paste-ready

> Create a stylized low-poly **tabletop diorama** of a toy-car racing track on
> the **volcanic island of Stromboli, Italy, in late-afternoon golden light**.
>
> **STYLE (strict):** faceted, flat-shaded low-poly meshes like a Blender
> viewport render — **no fine surface texture, no painterly brushwork, no
> photorealism**. Chunky toy proportions: cars are stubby and ~1.3× wider than
> real cars; houses and trees are simplified into a few big planes. Soft baked
> ambient occlusion in the crevices, muted environment colors (~50% saturation)
> with only three saturated accents: the **glowing orange lava and crater**,
> the bougainvillea on the white walls, and the toy cars. One single low warm
> sun (about 20° above the horizon) from the sea side, long soft shadows
> across the WHOLE overview. Sky is a plain gradient — warm cream at the
> horizon, pale blue at the zenith — no painted clouds except the volcano's
> ash plume. Show the diorama on a thin dark rounded-rectangle table base,
> from a raised 3/4 view.
>
> **THE ISLAND [!]:** one steep volcanic cone rises from the sea and **the
> racing track CLIMBS IT**: the road switchbacks up the flank, runs along the
> **crater rim** at the top (~70 m at diorama scale), and dives back down
> along the scree channel. The open crater bowl is visible from above: stepped
> scoria walls and three vents **glowing orange**, with constant smoke. A thin
> grey ash plume rises from it. On the north-west flank a broad grey scree
> channel (**the Sciara del Fuoco**) runs from the crater straight into the
> sea; glowing orange bombs bounce down it. Offshore, ~200 m out, a slender
> black sea stack with a small **white lighthouse on top** (Strombolicchio).
>
> **THE ROUTE — a single closed loop of about 2 km, counter-clockwise, the
> sea always on the right [!]:**
> 1. **Start/finish in a white Aeolian village square:** cubic flat-roofed
>    whitewashed houses with blue and green shutters, external staircases,
>    pergolas on round white pillars, a white church with a curved gable and a
>    14 m bell tower, a checkered banner strung between two houses, a green
>    Piaggio Ape three-wheeler, magenta bougainvillea on white walls.
> 2. **A black-sand beach:** the road runs along BLACK volcanic sand at the
>    water line; wooden fishing boats on log rollers, nets, orange buoys; no
>    guardrail toward the turquoise sea.
> 3. **The switchback climb [!] — the biggest feature:** the road zigzags UP
>    the volcano's flank in 5–6 hairpins: the lower hairpins between dry-stone
>    black terrace walls with low vine rows and twisted olive trees; a small
>    **observatory terrace with a white awning** on a middle hairpin; the
>    upper hairpins through burnt scrub and red-black scoria. Red-and-white
>    chevron posts on the outside of the hairpins; below, the white village
>    and the sea drop away — this climb must visibly GAIN height.
> 4. **The crater rim [!]:** at the top the road runs along the rim itself:
>    on the inner side the glowing crater bowl directly below, on the outer
>    side the sea far below. Narrow, no guardrail on either side.
> 5. **The Sciara descent [!]:** the road plunges back down in a tight zigzag
>    along the edge of the grey scree channel, glowing bombs bouncing down
>    the channel beside it.
> 6. **The lava fork — the race gimmick:** at the foot of the channel, on an
>    old black ropey lava field, the route SPLITS: a short straight route
>    across the field and a longer loop swinging toward the shore. A fresh
>    **orange-glowing lava tongue with a dark crust** flows down from the
>    channel toward the short route, just reaching it, leaving a narrow gap
>    between two glowing arms. Red warning signs at the split.
> 7. **Ginostra:** a tiny hamlet of 4–5 white houses on black rock above the
>    world's smallest harbor — a concrete pier, one boat, white stairs; the
>    track squeezes between the houses.
> 8. **The east-coast return:** a flat road on low black cliffs among fig
>    trees and prickly pears, crossing a pale **fumarole field** where small
>    vents puff white steam columns across the road, then back into the
>    village under a white archway.
>
> **Details that matter:** the road is dark packed volcanic soil with
> red-and-white curbs only on hairpin corners; the sea is one continuous
> turquoise surface and clearly the lowest thing in the diorama; the crater
> bowl, the lava tongue and the bombs are the ONLY strong orange; all white
> walls are slightly rounded, never sharp-cornered; the elevation must read
> clearly — village and beach at sea level, rim at the top, one continuous
> climb and one continuous descent.
>
> Background: two faint blue island silhouettes on the horizon; a low warm
> sun with a soft halo; warm haze.
>
> Toy cars: 4–6 chunky low-poly racing cars in saturated red, blue, yellow,
> white — one drifting through a hairpin mid-climb, one on the crater rim,
> one mid-jump on the descent, two choosing different routes at the lava fork.
>
> **PROP INVENTORY [!] — every item below must appear at least once, in its
> zone (this is the track's full asset list):**
> - *village square:* the church with bell tower, the checkered banner, cubic
>   houses in 3 sizes, pergolas, low white walls with one gate, white alley
>   stairs, a small street shrine with a blue niche, terracotta pot clusters
>   with geraniums, the green Ape three-wheeler, bougainvillea.
> - *black beach:* wooden fishing boats on log rollers, a rusty boat winch,
>   nets with orange buoys, black basalt boulders.
> - *the climb:* black dry-stone terrace walls, low vine rows, twisted olive
>   trees, prickly pears, caper bushes, yellow-tipped broom bushes, cane
>   clumps, the observatory terrace with white awning, red-and-white chevron
>   posts on the hairpins.
> - *rim and descent:* the open crater bowl with three glowing vents, glowing
>   volcanic bombs in three sizes, red-black porous scoria rocks.
> - *the lava fork:* the glowing lava tongue (mid stage, with the 4 m gap),
>   broken ropey lava slabs, two red warning signs.
> - *Ginostra:* the concrete pier with one larger boat, white stairs in the
>   rock, 4–5 white houses, a standing donkey.
> - *east coast:* fig trees, prickly pears, pale fumarole vents puffing
>   steam, low black stratified sea cliffs.
> - *offshore:* the Strombolicchio sea stack with its white lighthouse; two
>   faint island silhouettes on the horizon.
>
> Colors: basalt black #55535A, black sand slightly darker, whitewash
> #E9F2F0, sea turquoise #62B8C4 to deep #2F6E82, scrub green #5E7D4A, ash
> grey #B8B4AC, terracotta #C46A4C, **lava orange #E8622D (emissive)**, dry
> grass #AF9F4E.
>
> Deliver: (a) one wide 3/4 overview of the entire diorama with the loop
> clearly readable climbing the cone; (b) one driver's-eye shot ON THE CRATER
> RIM — glowing bowl below on the left, the sea and the white village far
> below on the right, Strombolicchio in the distance; (c) one shot from the
> lava fork looking up the Sciara: the zigzag descent road on its edge, bombs
> mid-bounce, the glowing tongue and the two routes in the foreground.

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
| crater bowl | open crater Ø 55 m, 12–15 m deep: stepped scoria walls, three vents with glowing orange lips, seen from above |
| Strombolicchio | slender black volcanic sea stack, 30×22 m base, 32 m tall near-vertical walls, spiral stair, small white lighthouse (+8 m) on top |
| observatory terrace | 10×6 m stone terrace with black parapet, white canvas awning on poles at 4 m, two tables, a coin-operated binocular |
| lava flow (3 stages) | black-crusted lava tongue with glowing orange cracks and a bulbous front, three lengths: 40 m, 60 m (4 m gap between two arms), 80 m solid wall |
| volcanic bomb ×3 | rounded boulders Ø 0.6 / 0.9 / 1.2 m with cracked crust, orange glow in the cracks |
| Ginostra pier | 8×3 m concrete pier with bollards, 4 m white stair cut into black rock |
| fumarole vent ×3 | small craters Ø 0.8–1.5 m with yellow-white sulfur deposits on the lip |
| chevron post | 1.2 m post with red-and-white chevron plate |

Kituri (o planșă pe kit, obiectele aliniate pe un rând, aceeași scară):

| kit | conținut |
|---|---|
| village kit | Aeolian houses A/B/C (7×6×4, 9×7×5.5, 5×5×3.5 m) with blue/green shutters, pergola 4×3 m on round pillars, white wall 3 m module + gate variant, alley stairs 4 m, street shrine 1.5 m, Ape three-wheeler 2.7 m, fishing boats 5 m and 7 m, boat winch with log rollers, nets + buoys set, bougainvillea ×2, terracotta pot cluster, donkey (standing) |
| slope kit | olive tree ×2 (5–7 m), fig tree (4–6 m), prickly pear ×2 (1.5–2.5 m), caper bush 0.8 m, broom bush ×2 (1.5–2 m), cane clump 3 m, terrace wall 3 m module (h 1.2 m), vine row 4 m module (h 0.8 m), basalt boulders ×3 (1–3 m), scoria rocks ×3 (0.5–2 m), broken lava slabs 2–4 m, basalt coast cliff module 10–20 m |

---

## Istoric

- **v1** (PR #323): buclă pe la poalele conului, traversare plată a Sciarei,
  urcare separată pe terase (45 m). Retrasă: verificarea cu frustumul camerei
  (§2.0) a arătat că vulcanul nu s-ar vedea niciodată din traseu — camera
  vede 5° în sus și 63° în jos, deci un con de 100 m e invizibil de la bază.
- **v2** (acest document): traseul urcă pe vulcan — serpentine, buza
  craterului, coborâre pe Sciara. Decizia dezvoltatorului, 22 aug 2026.
