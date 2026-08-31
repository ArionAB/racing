# Cappadocia (Track13) — starea la pauza, 31 aug 2026

Document de reluare. Ce e facut, ce e masurat, ce urmeaza, si pe ce ramura sta.

## 1. Poarta cifrelor (bara ceruta de dezvoltator)

| poarta | tinta | masurat | stare |
|---|---|---|---|
| ProbeLayout — panta MEDIE pe spirala | < 13% | **9.52%** | trecut |
| ProbeOverpass pe elice | verde | verde | trecut |
| materiale pe pista | <= 22 | **7** | trecut |
| ProbeBuried — carosabil ingropat | 0 | **0 / 984** | trecut |
| ProbeRace — repuneri pe 16 seed-uri | 0 | — | **de rulat dupa decor** |

## 2. Ramuri (worktree-uri sub .claude/worktrees/)

Toate pleaca din `feat/cappadocia-assets` (kitul de 45 GLB, PR #364).

| ramura | ce contine |
|---|---|
| `feat/capp-route` | **baza**: tema `cappadocia`, Track13.tscn (Path3D 123 puncte + 7 TerrainPeak + TerrainHollow), `TerrainHollow`, `ProbeBuried`, `docs/carosabil_ingropat.md` |
| `feat/capp-probes` | `CameraZone` + presetul de cavernă, `ProbeCavecam`, fix in `chase_camera.gd` |
| `feat/capp-under` | `ProbeHelix` + **fixul de motor** in `Track.is_on_road` (testul vertical lipsea pe ramura cu profil de latime) |
| `feat/capp-hazards` | `BalloonHazard` + `ProbeBalloon` |
| `feat/capp-poi-b` | padurea de hornuri — 38 commit-uri, cea mai avansata vizual (4/10) |
| `feat/capp-poi-c` | cornisa — 45 commit-uri, teren reparat, `ProbeSkyline` |
| `feat/capp-poi-a/d/e/f/g`, `feat/capp-faleza` | WIP salvat la limita de sesiune, **neverificat de sonde si nejudecat** |

## 3. Ce s-a invatat, si nu trebuie redescoperit

- **Comenzi.** Capturile cer `--rendering-driver vulkan` (D3D12 pica aici cu
  `CreateResource 0x80070057`). `probe_decor` e un **script MainLoop** si ia
  **numarul scenei (13)**; rulat ca scena sau cu `--track=6` nu masoara nimic si
  tot tipareste `VERDICT: OK`. Sondele-scena iau pozitia din lista (6).
  Un worktree nou cere un `--import` inainte sa vada fisiere noi.
- **Sonda verde, poza goala — de cinci ori.** Cauza de dedesubt: sondele
  masurau terenul **de langa masina**, camera se uita **inainte**. Vezi
  `ProbeSkyline` (masoara acum si in fata) si memoria `masoara-inainte-nu-langa`.
- **Nu se fotografiaza unde nu exista.** Noua runde s-au judecat pe frac
  0.24-0.28, exact gaura din cornisa. Masurat lateral (15/40/80/150 m):
  `0.20: -46.8 -48.0 -51.4 -59.4` si `0.32: -42.0 -45.5 -49.1 -50.3` sunt
  excelente si **nu s-au fotografiat niciodata**; `0.24: -1.7 +3.8 +8.8` e o
  gaura reala, inca nereparata.
- **Umbrele.** Azimutul soarelui e relativ la directia drumului si a fost ales
  pe traseul VECHI: umbrele bat la 133-169 grade fata de mers, adica inapoi
  peste camera. Vezi `azimutul-soarelui-fata-de-drum`.

## 4. Ce urmeaza (runda 10 era in curs la pauza)

Amandoi criticii orbi au cerut ACELASI lucru, si e primul de facut:

> **Ridica un perete care TAIE ORIZONTUL pe partea exterioara**, la 30-60 m,
> in benzi orizontale care ies in trepte. Nu mai sapa in jos — pamantul e sapat.
> Defectul fatal e ca ochiul merge de la marginea drumului pana la cer fara sa
> treaca peste nicio suprafata verticala. Elementul asta recupereaza testul
> umarului, adancimea, lizibilitatea stratelor si scara, dintr-o data.

Dovada: la frac 0.20 caderea e reala (-46 m) dar **baloanele stau la si peste
linia orizontului** — peretele de dincolo al vaii urca inapoi la aceeasi cota pe
ecran. Verificare de bun-simt inainte de orice livrare: daca esti pe o buza,
ce e in vale trebuie sa fie SUB linia orizontului.

Dupa perete, in ordine: strate care ies in trepte (offset orizontal pe banda, nu
doar Y constant); moloz adevarat la poalele conurilor (acum e o "duna neteda,
fara niciun bolovan"); usi cu adancime (acum sunt dreptunghiuri negre plate);
chiparosii sa nu fie mai inalti decat hornurile (fac conurile sa para de 6 m).

Nejudecate inca: **A** (sat), **D** (canion), **E** (vie + balonul aterizat),
**F** (subteran), **G** (stanca goala), **faleza**. Pentru F exista o capcana
masurata: `CameraZone.ceiling` e implicit 15.0, dar salile sunt de 16 si 18 m —
se pune pe fiecare zona cota REALA, altfel tavanul intra in cadru dupa pragul
de 25 m. Pentru cornisa: `ProbeBalloon` e ROSU intentionat pana cand tarusul
primeste o polita la <= 9.4 m de axul benzii.
