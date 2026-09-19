# Machu Picchu — contractul per POI pentru gauntlet

> Fișa de lucru a celor 8 perechi constructor/critic. Bara e
> `docs/track_briefs/img/machu_picchu_v3.jpeg`, decupată per POI în
> `docs/track_briefs/img/bar_machu/bara_poi_<X>.png`
> (`tools/bar/crop_machu_bar.py`). Planul real al traseului, cu loturile de
> assets desenate, e `docs/track_briefs/img/machu_picchu_plan.png`.

## Regula care se încalcă cel mai des

**Bara nu e layout, e look.** Diorama e comprimată și stilizată: pune cetatea,
podul și serpentinele unele lângă altele într-un cadru pătrat, ceea ce pista
noastră nu face și nu trebuie să facă (traseul real e în `plan.png`, măsurat,
cu ProbeLayout verde). Criticul compară **cum arată materia** — piatra, iarba,
vegetația, silueta — nu unde cade fiecare obiect.

Corolar: un critic care spune „la noi podul nu e lângă terase" a comparat
layout-ul și a ratat sarcina. Singura diferență care contează e una pe care o
poți repara în decorul POI-ului.

## Ce se măsoară pe scena integrată (niciodată pe worktree-ul POI-ului)

| gardă | comandă | prag |
|---|---|---|
| ProbeRace | `res://tools/ProbeRace.tscn -- --mode=race --track=8 --seconds=150 --seed=N` | **0 repuneri**, mai multe seed-uri |
| probe_decor | `--script res://tools/probe_decor.gd -- --track=15` | **≤ 20 materiale** |
| ProbeBuried | `res://tools/ProbeBuried.tscn -- --track=8` | **0** |
| ProbeLaneClear | `res://tools/ProbeLaneClear.tscn -- --track=8` | **pe linia de bază** |
| ProbeLayout | `res://tools/ProbeLayout.tscn -- --track=8` | pantă **sub 13 %** (sonda pică abia la 22 %) |

`--import` înaintea oricărei serii. `probe_decor` ia **15**, restul **8**.

## Captura: ce comandă, pentru care POI

Toate din mașină, fișierul iese la `snapshots/machu picchu_joc.png`
(**spațiu în nume — se pune între ghilimele**):

```
& $E --rendering-driver vulkan --path D:/GameDev/ignition-spike `
    res://tools/Snapshot.tscn -- --track=8 --frac=<F> --gamecam [flaguri de hazard]
```

`--gamecam` = camera reală de joc (compoziție). `--driver` = parametri înghețați
(`MEASURE_*`) pentru comparații de luminanță între build-uri. Pentru bară se
folosește **`--gamecam`**: bara e despre cum arată, iar jucătorul vede camera de joc.

| POI | frac | flaguri de hazard |
|---|---|---|
| A Piața Sacră | 0.00, 0.02 | — |
| B Drumul Incaș | 0.08, 0.14, 0.18 | `--cloud-at=5.0` la 0.14 (norul acoperă) |
| C Poarta Soarelui | 0.24, 0.30, 0.36 | — |
| D Terase | 0.44, 0.49, 0.52 | `--cross-at=` pentru lame |
| E Podul | 0.57, 0.60, 0.63 | `--rope-load=2.6,0.5` (autobuz la mijloc), și `0.9,0.5` |
| F Malul râului | 0.67, 0.70 | `--train-at=0.5` |
| G Serpentinele | 0.76, 0.82, 0.88 | `--bus-at=30` |
| H Cornișa | 0.94, 0.97 | `--bridge-at=0.24` (bârnele ridicate) |

## Cele opt contracte

Fiecare: **ce se vede în decupaj** (obligația vizuală) + **ce cere brief-ul**
(obligația de gameplay) + **capcana specifică** (memoria care se aplică).

### A — Piața Sacră (frac 0.00, zona `ZoneA_PiataSacra`)

Din decupaj: câmpuri de **ziduri joase care închid incinte dreptunghiulare** —
nu segmente răzlețe; două case cu acoperiș de paie; **iarbă scurtă aprinsă**
între ziduri, mai deschisă decât panta din jur; pavaj de lespezi; lame care pasc;
un soclu/piatră-ceas pe movilă.

Brief: grila pe pavaj de granit între Templul celor Trei Ferestre (stânga) și
Templul Principal; Intihuatana în față-sus pe movilă; zidurile piaței sunt
**pereți cu masă** (contact = ricoșeu); pavajul e suprafața cea mai rapidă.
Semi-lățime 9 m — e respiro, cel mai lat punct al pistei.

Piese: `inca_wall_a/b/c` (înlănțuibile: capete la ±2,0 / ±3,0 / ±1,0, rost
0,0000), `three_windows`, `sun_temple`, `intihuatana`, `inca_house_a/b`,
`guardhouse`, `fountain_basin`, `water_channel`, `llama*`, `trail_marker`.

Capcana: **incintele închise sunt ce face cetatea să citească drept cetate.**
Ziduri împrăștiate citesc a ruină generică. Și: `intihuatana` e lângă grilă,
mașinile o pot atinge — treptele au vârfuri partajate, pragurile peste 0,3 m
sunt ziduri pentru fizica întreagă.

### B — Drumul Incaș (frac 0.04–0.20, `ZoneB_DrumulIncas`)

Din decupaj: drum **tăiat în stâncă** cu perete pe o parte, gură de **tunel cu
arc de piatră**, trepte alături, vegetație agățată pe perete.

Brief: urcare pe trepte 0 → 35 m (10,6 %), pe flancul Muntelui Machu Picchu; pe
dreapta **fără parapet**, defileul; pe stânga peretele cu mușchi și bromelii; un
tunel scurt (12 m, tavan 6 m); la 0.14 **norul** urcă din dreapta și acoperă
drumul 4 s. Semi-lățime 6 m.

Piese: `moss_boulder_a/b/c`, `bromeliad`, `tree_fern`, `orchid_cluster`
(accent roz, rar, la 2–3 m de bandă), `inca_stair_a/b`, `trail_marker`.

Capcana: `custom_step_ranges` e deja pe traseu (0.0405–0.2034) — treptele
**vizuale** vin cu mesh-ul, coliziunea rămâne pantă lină. Nu pune geometrie de
treaptă cu prag > 0,3 m peste carosabil: devine zid. ProbeBuried pe toată urcarea.

### C — Poarta Soarelui și creasta (frac 0.22–0.40, `ZoneC_PoartaSoarelui`)

Din decupaj: **poartă de piatră pe creastă** cu **condorul pe stânca alăturată**,
aripile desfăcute; drumul pe muchie; nor dedesubt, de ambele părți.

Brief: treci prin `inti_punku` (**gol de 14,0 m** pe axa drumului — contract
înghețat în geometrie, drumul are semi-lățime 6,5 acolo); condorul pe stânca din
dreapta; ac larg de 150°; creasta coboară spre nord cu **gol de ambele părți**,
două S-uri cu concavitatea spre cetate; la 0.33 Casa Paznicului — **cadrul pozei
clasice**; zid incaș de 0,6 m **doar la cele două ace** (punctuație).

Capcana, cea mai scumpă de pe pistă: memoria `umarul-ingust-ascunde-caderea` —
ochiul e la 10 m, contează **unghiul**, nu adâncimea. Taluz > 45° în primii 3 m
de la piatră, pe ambele părți, altfel creasta citește a umăr și tot POI-ul e
ratat. Și `perete-paralel-nu-se-vede`: doar serpentina spre interior înfășoară
peretele. Captura obligatorie: de la Casa Paznicului (≈0.33) — **se vede cetatea
sub tine și Huayna Picchu în față, sau se vede taluz?**

### D — Cascada de terase (frac 0.42–0.54, `ZoneD_Terase`)

Din decupaj: **terase în trepte** cu **scară de piatră care coboară drept prin
ele**, canal de apă pe o parte, lame pe trepte, o casă sus.

Brief: 10 terase de 2,5 m, ziduri de granit, iarbă scurtă; linia principală
**zigzag pe rampe** (4 ace, 12,5 %); **scurtătura**: drept în jos, 8 căderi de
2,5 m; lamele traversează terasa a 5-a (ciclu ~27 s, deja cablate la frac
0,490–0,498); 16 fântâni în trepte pe dreapta.

Piese: `inca_wall_a/b/c` pe trepte de 2,5 m **cu coliziune**, `inca_stair_a/b`,
`fountain_basin` ×16, `water_channel`, `llama*`, `inca_house_b`.

Capcana: terasele sunt **taluz de teren + piese de zid**, nu `TerrainStep`
(respins la construcție: celula de teren e 7,9 m, o treaptă de 2,5 m ar ieși
rampă de 17°). Rampa principală trebuie să intre în zid **fără prag**
(`suprafete-din-placi-plane`: liniar pe porțiuni, **min**, nu produs). Pragul
lateral > 0,3 m e zid — aici e *intenționat* zid (terasa de sub tine), dar nu pe
rampă. ProbeBumpRigid pe 8 căderi: nicio răsturnare, 4 mașini.

**Soarele:** azimutul se alege ca zidurile teraselor să arunce umbră pe treapta
de sub ele — dungile alb/umbră sunt identitatea POI-ului. Se **remăsoară**
(memoria `azimutul-soarelui-fata-de-drum`).

### E — Podul de frânghie (frac 0.56–0.64, `ZoneE_Pod`)

Din decupaj: **scânduri pe cabluri** între **două turnuri de piatră**, autobuzul
galben pe tablier, defileul dedesubt.

Brief: 35 m, `deck_width` 11; se **afundă** sub masă (autobuz 2,6 ≈ 1,5 m;
sport 0,9 ≈ 0,6 m) și se **leagănă** ±1,2 m. Hazardul e deja construit și
cablat (`Track15.tscn:48`), tablierul și turnurile sunt făcute **în cod**
(`rope_bridge_hazard.gd:313-392`), nu din GLB.

Deci POI-ul E **nu construiește podul** — construiește ce e în jurul lui: buza
de plecare, râul la −20 m sub tablier cu spumă albă pe pietre, pereții
defileului, `bamboo_clump` pe mal.

Capcana: memoria `efecte-invizibile-nu-se-numara` — afundarea se verifică pe
**captură** cu `--rope-load=2.6,0.5`, nu numărând. Dacă turnurile-cutii din cod
nu țin la captură, **atunci** se deschide un `deck_model`/`tower_model` în hazard
și abia apoi se comandă piesa — în cadrul real al hazardului, nu după literă.

### F — Malul râului (frac 0.66–0.72, `ZoneF_MalulRaului`)

Din decupaj: **trenul albastru-galben** pe mal, **repezișuri albe printre
bolovani**, clădire mică de gară, copaci pe mal.

Brief: cel mai jos punct (−30 m); calea ferată pe mal, trenul trece pe ciclu
40 s **fără să taie drumul** (deja cablat la (−160, −33, −205), estacadă de
lemn, 130 m de șină); gară mică, corturi, rucsacuri; râul brun-verde cu
repezișuri. Semi-lățime 8 m. Apă = repunere (`RespawnZone`).

Piese: `perurail_train` (cablat la fundație), `tent_a/b`, `backpack_pile`,
`bamboo_clump`, `moss_boulder_*`, `inca_house_b`.

Capcana: apa. Shader-ul v12 de la Serengeti — memoriile `apa-iluminata-v12`
(pata gri = pânză opacă; Fresnel din chase cam) și `celula-de-apa-plana-peste-mal`
(sortează după aria AABB când obiectul e mare și plat). Spuma e `FOAM_WHITE`.

### G — Serpentinele Hiram Bingham (frac 0.74–0.92, `ZoneG_Serpentine`)

Din decupaj, **detaliul care decide POI-ul**: fiecare ac are **zid de sprijin de
piatră pe marginea exterioară**. Asta face drumul să citească drept *tăiat în
versant*, nu drept potecă pe iarbă. Plus queñuali cu **scoarță roșie** între ace,
autobuzul galben pe un ac.

Brief: 5 ace, urcare 9,1 %, peretele pe stânga, golul pe dreapta; autobuzul
coboară pe traseu fix (deja cablat, ciclu 75 s, 3,6 m lat, ia acul larg); acele
au **rază ≥ 13 m pe axă** (măsurat: la 10 m sportul nu ține interiorul).
Semi-lățime 6,5 m.

Piese: `polylepis_a/b` (scoarța roșie = `LARCH_RUST`), `inca_wall_*` ca zid de
sprijin, `moss_boulder_*`, `trail_marker`, `rope_rail`.

Capcana: `custom_lane_corridors (0,70, 0,909, +0,5)` ține AI-ul pe dreapta
fiindcă **AI-ul nu vede corpuri cinematice** (memoria
`obstacol-pe-drum-poate-fi-gimmick`). Orice decor pus pe jumătatea autobuzului
îi taie culoarul. ProbeRace cu `--slice=0.74,0.92` — media pe tur ascunde un
hazard local.

### H — Cornișa Podului Incaș (frac 0.94–1.00, `ZoneH_Cornisa`)

Din decupaj: **cornișă pe perete** cu **portal/poartă de piatră**, golul pe o
parte, zidul pe cealaltă.

Brief: cornișă tăiată în peretele de vest, peretele pe dreapta, golul pe stânga;
**golul cu bârne** de 4,25 m, bârnele lipsesc 6 s din 28 (cablat, frac 0,9435);
apoi **Poarta Principală** (`main_gate`, **8,4 m liber la bază**, 6 m sub
buiandrug — gâtuire de la 13 la 8 m); flancul lui Huayna Picchu în dreapta, la
40 m, umplând marginea cadrului.

Capcana declarată în brief, **încă nerezolvată**: reuse-ul `LiftBridgeHazard`
aduce rampele podului mobil — un dâmb de 1,6 m pe cornișă, deci profilul nu mai
citește „bârne peste gol"; iar sub gol terenul rămâne la −0,3 m, deci nu e
prăpastie. Cere săpătură locală de 4 m. Verifică pe captură cu `--bridge-at=0.24`.

Și: `main_gate` e livrat la 8,390 m. Cine îl „corectează" la 8,0 exact pierde
marja, nu câștigă conformitate.

## Bucla oarbă

1. Constructorul lucrează în `D:/GameDev/wt-mp-<poi>` pe `feat/mp-poi-<poi>`,
   comite după fiecare pas care trece o gardă.
2. Face captura din mașină la fracțiile din tabel.
3. Criticul, **context proaspăt**, primește planșa din
   `python tools/bar/blind_pair.py "<captura>" "docs/track_briefs/img/bar_machu/bara_poi_<X>.png" "<out>.png" --seed <N>`.
   **O singură planșă per rundă** — patru planșe cu aceeași referință = ghicit
   din repetiție (docs/bara_vizuala.md).
4. Criticul **deschide** planșa, verifică amprenta din colțul stânga-jos, alege
   A sau B, **apoi** citește cheia `<out>.png.<sig>.key`, și raportează cinstit
   dacă a nimerit.
5. Numește **o singură** diferență care contează, reparabilă în decorul POI-ului.
6. Dacă a noastră nu câștigă → rundă nouă. Dacă da → gărzile pe scena integrată,
   apoi merge.

Seed-ul planșei se schimbă la fiecare rundă, și numele fișierului la fel:
amprenta cheii e hash pe argumente, iar refolosirea unui nume între runde a
făcut deja doi critici să se judece unul pe altul.
