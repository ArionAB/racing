# Serengeti (Track14) — starea constructiei POI-urilor

> Instantaneu la pauza sesiunii de gauntlet (8 sep 2026). Se actualizeaza la reluare.

**Toate cele 8 POI-uri exista si sunt MERGEATE** in `D:/GameDev/wt-ser-main`
(branch `feat/serengeti-poi`, **112 commit-uri peste main**, arbore CURAT).
Scena integrata are toate zonele populate — **2.173 de noduri de decor**:

| zona | noduri | zona | noduri |
|---|---:|---|---:|
| ZoneA_Camp | 279 | ZoneE_Buza | 296 |
| ZoneB_RaulDeGnu | 277 | ZoneF_Serpentine | 177 |
| ZoneC_VadulMara | 119 | ZoneG_FundulCraterului | 129 |
| ZoneD_PadureaDeCeata | 506 | ZoneH_Spartura | 390 |

Dupa merge au intrat si reparatii globale: ceata in familia pamantului (nu a
cerului), apa care nu mai e neagra (cauza era `water_dim`, nu ambientul),
`sea_level_offset` consecvent, linie de baza ProbeLaneClear pentru Track14,
si campia departata care nu lipsea — o stergea ceata (`fog_max`).

**NU s-a facut PR-ul.** Nu s-a facut push (regula: niciodata push pe main,
merge doar prin PR).

## Ce ruleaza / ce s-a oprit

Bucla `/loop` a fost OPRITA la cererea dezvoltatorului. Ultimul workflow lansat
a fost integrarea (`wf_78a7affb-038`); merge-ul si reparatiile lui sunt comise,
dar **verdictul criticului de ansamblu nu a fost inregistrat** in jurnal — se
reia de acolo.

## Cum se reia

1. Import + garzi pe scena integrata:
```
E=D:/GameDev/Godot_v4.7-stable_win64_console.exe
$E --headless --path D:/GameDev/wt-ser-main --import
$E --headless --fixed-fps 60 --path D:/GameDev/wt-ser-main res://tools/ProbeLayout.tscn -- --track=7
$E --headless --fixed-fps 60 --path D:/GameDev/wt-ser-main res://tools/ProbeRace.tscn -- --mode=race --track=7 --seconds=150
$E --headless --fixed-fps 60 --path D:/GameDev/wt-ser-main res://tools/ProbeLaneClear.tscn -- --track=7
$E --headless --path D:/GameDev/wt-ser-main --script res://tools/probe_decor.gd -- --track=14
```
2. Capturi per POI (`--gamecam`): A 0.97 · B 0.06 `--herd-at=4` · C 0.13
   `--hippo-at=0.12` · D 0.26 · E 0.40 · F 0.555 · G 0.77 · H 0.84.
3. Critic orb pe ansamblu fata de `scratchpad/ref/ref_ansamblu.png`.
4. Valul 4 de reparatii (lista de mai jos), apoi PR.

## Diferentele ramase, numite de critici cu cifre

Niciun POI n-a fost inca ales de criticul orb. Ce a ramas, per bucata:

- **A — Land Rover fara silueta.** REPARAT dar NEVERIFICAT: commit `e0fcfc0`
  adauga `SLOT_REPAINT_BY_BOX` in `world_prop.gd` (repictare pe caseta in spatiu
  local, pe centroidul triunghiului, cu vertecsi despartiti). Trebuie o captura
  care sa confirme ca rotile si parbrizul se citesc. Ramane si degajarea de
  iarba de ~1.5 m in jurul rover-elor.
- **B — turma e o RETEA, nu un rau.** Jitter >= 0.5 din pas pe ambele axe, yaw
  ±30°, corpuri care se SUPRAPUN, densitate care creste spre axa drumului, praf
  pe fasia de traversare. Tinta masurabila: acoperirea de pixeli de animal in
  caseta turmei scade sub 50% (de la 63.5%, referinta 43.0%) **fara** sa scada
  numarul de instante.
- **C — verdict nelivrat** (criticul rundei 3 a picat pe limita). Se cere din
  nou critica pe starea actuala, fara alte schimbari.
- **D — MistPatch e o PODEA opaca.** 602 panze UNSHADED de 10-17 m culcate la
  0.3-0.9 m taie bazele trunchiurilor. Micsoreaza la 4-6 m, ridica la 1.2-2.2 m,
  rareste sub 1.0 straturi (de la 2.74), scoate din UNSHADED. Criteriu: pe
  treimea stanga se vede sol la baza a cel putin jumatate din trunchiurile din
  prim-plan.
- **E — caderea in crater e un PERETE neted, nu un bol.** Sparge `E_Flanc` in
  3-4 trepte (berme de 6-10 m), bolovani si tufe pe fiecare treapta la scara
  descrescatoare. Criteriu (ProbeMasca --group la frac 0.40): cel putin 3 benzi
  distincte de y intre buza si lac, cu diferenta de valoare intre ele.
- **F — punctul hero sta IN coridor.** Muta captura in exteriorul cotului de la
  frac 0.60-0.63, la 60-90 m lateral si 25-40 m peste bratul de sus, cu privirea
  inapoi spre perete. Criteriu: minim 3 benzi disjuncte de asfalt, fiecare peste
  2% din cadru, cu aria totala sub 20% (azi: o banda la ~45%).
- **G — flamingii sunt un TIV de tarm.** Populeaza si interiorul apei mici, cu
  densitate descrescatoare spre larg, plus cateva in zbor jos. Criteriu: raportul
  roz/apa peste 0.3 (azi 0.007, referinta 0.699) si banda verticala peste 0.4
  (azi 0.128).
- **H — granitul e cea mai LUMINOASA masa** (V median 0.745) cand in referinta e
  cea mai inchisa (0.424). Coboara albedo-ul clasei de granit la 0.42-0.45 si
  sub mediana ierbii, **fara** sa atingi ambientul cald castigat in runda 4.

## Regula transversala (6 valuri de critica o repeta)

**Aranjamentul bate numarul.** Valul 1 avea mai multi pixeli de animal decat
referinta si citea mai mort. Tiparele de evitat, toate platite:
- scatter pe GRILA = „instante plasate", nu lume vie;
- panze de efect jos + UNSHADED = podea opaca care taie bazele;
- un rand pe contur („tiv") lasa suprafata din spate goala;
- o silueta goala nu se repara prin apropiere — se taie in GLB (sau, ca la
  rover, se repicteaza pe caseta de geometrie);
- o singura nuanta pe toata adancimea = problema de LUMINA (azimut,
  cast_shadow), nu de densitate.

## Capcana de metoda (a costat 3 lansari)

8 constructori paraleli la efort inalt consuma tot bugetul de sesiune in ~15
minute si niciun critic nu mai apuca sa ruleze. **Valuri de 3** merg: valul 1
(36 de agenti) si valul 3 (30) s-au terminat fara nicio cadere.

Alta capcana, verificata si respinsa: o captura dintr-un worktree de POI arata
campia GOALA nu fiindca s-a stricat ceva, ci fiindca fiecare branch contine doar
zona lui populata. Verificarea reala a luminii globale se face DOAR pe scena
integrata.

## Unelte

- Pagina de progres: https://claude.ai/code/artifact/5ca011b8-e48c-4f0e-a782-aa1a5b4d5805
  (regenerare: `python scratchpad/gen_progress.py`, apoi republicare pe aceeasi cale)
- Jurnal: `scratchpad/progress.jsonl` (`plog.py <piesa> <rol> <runda> <status> "<text>"`)
- Referinte decupate per POI: `scratchpad/ref/ref_[A-H].png`, ansamblu `ref_ansamblu.png`
- Capturi: `scratchpad/caps/`, planse oarbe: `scratchpad/crit/`, garzi: `scratchpad/guards/`
- Handoff-ul fundatiei (id-uri ext_resource, fractii masurate, comenzi): `scratchpad/handoff_fundatia.md`

## Fractii masurate (NU cele din brief, care sunt vechi)

turma 0.075 · vad 0.144 (apa 0.136-0.152, hipopotami 0.142-0.149) · vartej 0.802
· padurea 0.196-0.339 · buza 0.362-0.482 · serpentine 0.500-0.715 (ace la 0.511/
0.562/0.613/0.670) · spartura 0.853. `--herd-at=4` pune pulsul pe drum;
`--hippo-at=0.12` ridica spinarile. Orice punct: ProbeFrac `-- --track=7 --at=x,y,z`.
