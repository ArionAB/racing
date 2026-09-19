# Constatările valului 1 — două probleme care NU sunt ale POI-urilor

Scrise de lead după ce s-a uitat la capturile rundelor 1–4 ale lui A și G,
înainte de verdictele criticilor. Amândouă sunt de **fundație**, nu de POI:
niciun constructor nu le poate repara din zona lui, și amândouă se vor repeta
pe toate cele opt.

## 1. Clasa de zidărie acoperă doar jumătate din piesele de piatră

Pe captura `poi_a/A_r1_f002.png` se văd **două materiale de piatră unul lângă
altul**: `intihuatana` și capacele mici sunt gri-albăstrui (granit corect),
zidurile lungi sunt maro-lemn. Bara are o singură zidărie gri-crem peste tot.

Cauza, citită în `world_prop.gd` `CLASSES_BY_MODEL` (L875–890): clasa
`inca_stone` e pusă pe `inca_wall_a`, `inca_wall_b`, `inca_stair_a/b`,
`inca_bridge_ledge`, `inca_house_a`, `guardhouse`.

**Lipsesc, fără nicio notă de respingere:**
`inca_wall_c`, `sun_temple`, `three_windows`, `intihuatana`, `main_gate`,
`inti_punku`.

(`inca_house_b` și `fountain_basin` sunt respinse *explicit*, cu motiv — alea
sunt decizii, nu scăpări.)

`inca_wall_c` e cel mai grav: e zidul de înlănțuire folosit **împreună** cu
a și b, deci același gard se randează în două materiale. `main_gate` și
`inti_punku` sunt porțile prin care treci — cele mai privite bucăți de piatră
din tur.

**De reparat la integrare, nu acum**: cele trei worktree-uri ale valului 1
împart `world_prop.gd`, iar un fix pe main acum garantează conflicte.

## 2. Terenul de sub decor nu e terenul din bară

Pe `poi_g/G_r4_f082.png` serpentinele trec printr-o **pajiște verde blândă**.
În bară, aceleași serpentine sunt tăiate într-un perete abrupt, cu ziduri de
sprijin și cădere pe exterior.

Măsurat, din surveyul propriu al constructorului (`G_r1_survey.txt`), cota
solului față de drum la frac 0.760–0.780:

| frac | −40 m | −25 m | −15 m | **−8 m** | **+8 m** | +15 m | +25 m | +40 m |
|---|---|---|---|---|---|---|---|---|
| 0.760 | +5.6 | +5.4 | +3.5 | **−0.3** | **−0.5** | −4.4 | −6.4 | −6.3 |
| 0.770 | +3.3 | +3.0 | +1.6 | **−0.3** | **−0.5** | −6.5 | −9.5 | −9.6 |
| 0.775 | +3.1 | +2.1 | +0.7 | **−0.3** | **−0.4** | −6.7 | −15.8 | −20.7 |

La **±8 m de ax terenul e plat** (−0,3…−0,5 m). Căderea începe abia la 15–40 m.
Adică drumul stă pe un platou cu o pantă îndepărtată, nu pe o cornișă.

Memoria `umarul-ingust-ascunde-caderea` spune exact asta: ochiul e la 10 m și
contează **unghiul din primii metri**, nu adâncimea finală. O cădere de 20 m
care începe la 25 m lateral nu se vede din mașină; una de 6 m care începe la
3 m se vede.

**Consecința pentru brief:** §2 POI G cere „peretele pe stânga, golul pe
dreapta"; §2.0 cere pentru creastă „taluz > 45° în primii 3 m de la piatră".
Terenul actual nu livrează asta nicăieri pe G — și probabil nici pe C
(creasta) sau H (cornișa), care au aceeași cerință.

### Cauza exactă: cele trei POI-uri ale valului 1 sunt exact cele fără râpă

`Track15.tscn:77` declară cinci râpe, pe intervalele:

| râpă | de la | până la | lățime |
|---|---|---|---|
| 0 | 0.0734 | 0.3556 | 200 m |
| 1 | 0.2215 | 0.3556 | 70 m |
| 2 | 0.5269 | 0.5834 | 60 m |
| 3 | 0.5834 | 0.6611 | 90 m |
| 4 | 0.9120 | 0.9809 | 40 m |

Intervalele POI-urilor valului 1:

- **A (0.00–0.02)** — înainte ca râpa 0 să înceapă (0.0734). Fără râpă.
- **F (0.66–0.72)** — râpa 3 se termină la **0.6611**, adică exact unde începe
  malul râului. Aproape tot POI-ul e fără râpă — de aceea **nu există râu**.
- **G (0.74–0.92)** — cade fix în golul dintre râpa 3 (0.6611) și râpa 4
  (0.9120). Fără râpă pe toate cele cinci ace.

Nu e coincidență că toate trei citesc a pajiște: **sunt singurele trei zone
din tur fără relief declarat.** POI-urile B, C, D, E, H au râpă și foarte
probabil nu vor avea problema asta.

Se repară în `Track15.tscn` prin extinderea râpelor 3 și 4 (sau două râpe noi
pe 0.66–0.74 și 0.74–0.91), plus `custom_ravine_widths` pentru ca panta să
înceapă **aproape de bandă**, nu la 15–40 m. Dar e **decizie de traseu**:
se face o dată, pe scena integrată, cu ProbeLayout (panta să rămână sub 13 %),
ProbeRace (0 repuneri — o râpă nouă lângă bandă poate arunca mașini) și
ProbeBuried după. Nu de trei constructori în paralel.

## Ce se face cu ele

Niciuna nu oprește valul 1: decorul plasat rămâne bun și se reintegrează.
Amândouă intră în **pasul de integrare al valului**, pe un worktree propriu,
cu gărzile pe scena integrată. Criticii valului 1 vor numi foarte probabil una
dintre ele ca „singura diferență care contează" — dacă o fac, e confirmare
independentă, nu muncă dublă.
