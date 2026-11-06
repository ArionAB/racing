# Inventar — kit Angkor, val 1, grupul C (elefantul asiatic)

Contract: `docs/asset_briefs/angkor_kit.md` §1.3 (cotele Serengeti din brief, 3,4 / 6,4, erau greșite; vezi nota de mai jos). Desen:
`docs/track_briefs/img/angkor_assets_v1/asian_elephant.png`. Pe tiparul
`angkor_inventory.md`.

| fișier | rol |
|---|---|
| `tools/blender/build_angkor_elephant.py` | `assets/models/angkor/animals/asian_elephant.glb`. **Reutilizează** Serengeti: citește `build_serengeti_animals.py` ca text, îl taie înainte de `results = []` și execută definițiile (`elephant_mesh`, `elephant_rig`, `elephant_animate`, `build_elephant`) în aceleași globale. Nimic din Serengeti nu e modificat sau copiat; `serengeti/animals/elephant.glb` e neatins. Apoi `build()` aplică forma asiatică **după rigging** |
| `tools/blender/measure_angkor_w1c.py` | garda pe GLB (fără Blender), cu `--selftest` |
| `tools/blender/preview_angkor.py` | extins compatibil: `--pose <nume>` (repaus + Walk la 1/4, 1/2, 3/4 + Trumpet), `--vs <nume> <cale sub assets/models>` (două elefanți la aceeași scară), intrarea `SPECS["asian_elephant"]`. `--compare/--views/--gamecam` merg neschimbate |
| `tools/blender/verify_angkor.sh` | blocul `# --- val 1, grupul C ---` (`verify_glb --origin=assembly` cu plasa 3000 ca la Serengeti, apoi garda și selftest-ul) |

## Cum se face forma (de ce DUPĂ rigging)

Clasificarea pe vertex din `elephant_rig` (fereastră pe **Y** pentru picioare,
nu prag pe X — nota `elefant-mesh-importat-rig-per-vertex`) e calibrată pe
geometria africană. Urechile micșorate înainte ar fi căzut sub `x_ear` și s-ar fi
lipit de cap. Deci: rig pe mesh-ul african (greutăți verificate), apoi aceeași
funcție `warp()`+`scl()` pe **vertecși și pe capetele oaselor**, ca scheletul să
rămână în piele:

- **urechi:** vertecșii cu os `EarL/R` plus partea din spate a clapei (legată de
  `Body` la Serengeti) se strâng spre rădăcina de pe cap (x ×0,55, y/z ×0,80).
  Partea din spate trece **pe osul urechii** (altfel la `Trumpet` clapa se rupea
  în două). Lățime totală 2,6 m față de 4,0 m;
- **spatele arcuit, convex:** maxim între picioare (3,05 m), umărul 2,90, șoldul 2,95;
  crupa se rotunjește doar în ultimii ~15% spre coadă (`RUMP_DROP`, mic). Runda 3 o
  coborâse mult și dădea un animal pocit; anulat în runda 4;
- **cap bombat:** două boltiri slabe la x ±0,30 și una de bază (`BUMP_*`);
  forma mesh-ului sursă are puțini vertecși pe frunte, deci boltirile sunt
  rotunjite, nu o creastă dublă clară (vezi deviații);
- **fildeși:** scurtați la 45% spre rădăcină (nu lipsesc: 56 de fețe pe slotul 29);
- **O SINGURĂ scară verticală** (×0,636) pentru tot animalul, calibrată pe **umăr**;
  scara pe Y deduce lungimea de 5,60 m **după** reformă (fildeșii scurtați nu mai
  sunt vârful), X ×0,92. Picioarele sunt îngroșate ×1,2 în X/Y (nu scurtate);
- **capul mai mic** (x/z ×0,88 spre +Y, pe Z după ceafă ca să nu apară treaptă),
  cu vârful sub spatele de la mijloc.

## Cote măsurate (din fișier, Godot, `measure_angkor_w1c.py elephant`)

| | măsurat | contract |
|---|---:|---|
| umăr (corp, Body dominant, la picioarele din față) | **2,900 m** | 2,8–3,0 |
| spate la mijloc / șold (la picioarele din spate) | 3,047 / 2,951 m (șold = umăr +0,051) | mijloc ≥ umăr + 0,10; șold ≥ umăr − 0,20 |
| vârful capului | 2,878 m (sub spatele de la mijloc) | ≤ spatele de la mijloc |
| lungime cu trompa (Z) | **5,600 m** | 5,4–5,8 |
| înălțime totală | 3,047 m (= spatele de la mijloc; capul nu mai e punctul cel mai înalt) | ≤ 3,4 (garda mea) |
| lățime cu urechi | 2,605 m | ≤ 2,8 (garda mea; african 4,0) |
| min Y | 0,000 | origine la sol (la mijlocul lungimii, ca la Serengeti: `SlidingHazard` centrează cutia pe origine) |
| `Walk` | 1,500 s (min–max al intrărilor: cadrele 1…37 la 24 fps → 0,042…1,542) | 1,5 s |

**Notă despre contract:** „umăr 3,4 / lungime 6,4” pentru elefantul din Serengeti
nu e ce are fișierul. Măsurat cu aceeași garda pe `serengeti/animals/elephant.glb`:
umăr **4,62 m**, lungime **6,20 m**, înălțime totală 4,66 m, lățime 4,00 m. Mesh-ul
african din pachet e un butoi înalt. Raportul cerut (2,9 / 5,6) e deci
**mult mai jos** decât al lui, nu „0,85×”; de aceea picioarele și corpul s-au
scalat diferit (o scară uniformă dădea un pui). Pe cota asiatică corectă,
elefantul asiatic e cu ~37% mai jos decât cel din Serengeti la aceeași lungime ±10%.

## Schelet și animații

Identic cu Serengeti (comparat nod cu nod: aceeași ierarhie `Elephant > Elephant_Mesh,
Body > Head > EarL, EarR, Trunk1 > Trunk2; Body > LegFL/FR/RL/RR, Tail`). 11 oase,
animațiile `Trumpet` și `Walk` (32 + 1 canale, ca la Serengeti), mesh `Elephant_Mesh`,
rădăcina `Elephant` fără scală/rotație. Greutăți rigide pe vertex, ca la
Serengeti, cu o singură schimbare: clapa urechii întreagă pe `EarL/R`.

## Triunghiuri, materiale, sloturi

- **1.100 triunghiuri** (același mesh decimat), 72 kB. Fără plafon (CLAUDE.md);
  plasa verify 3000.
- **1 material** (`PaletteAtlas`), UV pe sloturi, ca la Serengeti.
- Sloturi: **2** (`MARBLE_GREY`, pielea) · **22** (`FOAM_WHITE`, fildeșii) ·
  **29** (`SAND_SHADOW`, labele). Garda cere mulțimea identică cu a fișierului
  din Serengeti. AO = gradient vertical copt ca acolo.

## Fidelitate

Imagini în `docs/asset_briefs/img/angkor_fidelity/`: `asian_elephant.png`
(decupare | randare 3/4), `asian_elephant_views.png` (4 azimuturi),
`asian_elephant_vs.png` (**cu Serengeti, aceeași scară**, 3/4 și profil),
`asian_elephant_pose.png` / `_pose34.png` (repaus + Walk 1/4, 1/2, 3/4, profil și
3/4), `asian_elephant_trumpet.png`, `asian_elephant_gamecam.png` (animalul stă cu
spatele la cameră, fiindcă fața e pe +Y).

| element al desenului | în GLB |
|---|---|
| corp rotunjit, picioare groase și drepte | da; picioarele îngroșate, o singură scară verticală |
| urechi mici, rotunjite | mici (aria ~½ din a celei africane), dar **colțuroase** (low-poly), nu cu marginea ondulată din desen |
| cap cu două boltiri | boltiri slabe: mesh-ul are foarte puțini vertecși pe frunte; din profil se citește cap bombat, din față o frunte ușor în două |
| spate cel mai înalt la mijloc | da, +0,15 m peste umăr; șoldul +0,05 peste umăr, rotunjit doar spre coadă |
| fildeși scurți, fără șa, fără călăreț | da |
| coada cu smoc | nu: coada e cea africană, subțire |
| piele de culoare caldă | clasa `elephant_hide` la integrare; preview-ul arată slotul gri |

## Rundele (4)

1. **Prima:** scară uniformă pe Z până la 2,9 m (÷0,59). Rezultat: **pui** —
   picioare scurte, cap mic, corp turtit. Cauza: mesh-ul african e înalt (4,6 m).
2. **A doua:** scară pe tronsoane (picioare ×0,62, corp ×0,55–0,65), X ×0,92,
   arc pe spate, boltiri mai mari. Mai stocat, cu cap mai mare, aproape de desen,
   dar boltirile ieșeau două **coarne ascuțite**. Garda a prins în același timp două
   greșeli ale mele: lungimea 5,24 (fildeșii scurtați scoteau capul din calcul) și
   durata `Walk` 1,542 (durata e max − min, nu max).
3. **A treia:** boltiri mai largi și mai joase, crupa coborâtă (garda: crupa era
   mai sus decât umărul), clapa urechii mutată pe osul ei (la `Trumpet` se rupea).

4. **A patra** (verdictul coordonatorului: în profil animalul părea ghemuit,
   cu crupa lăsată între picioare scurte și strâmbe). Anulat `RUMP_DROP` mare (acum
   0,30, doar în ultimii ~15%); **o singură scară verticală** în loc de tronsoane;
   picioarele îngroșate în X/Y, nu scurtate; capul ×0,88 și boltirile reduse (vârful
   capului sub spatele de la mijloc); garda raportează șoldul, umărul, spatele de la
   mijloc și vârful capului, cu verificare moale șold ≥ umăr − 0,20 și cap ≤ spate.
   **Ghimpele la Walk (cadrul 2):** nu era o greutate greșită într-un vârf izolat, ci
   colțul de sus al clapei urechii, un vârf pe `Body` cu |x| african 1,02 care
   scăpa de micșorare (pragul era 1,0) și rămânea 0,13 m deasupra spatelui. Pragul
   coborât la 0,82, colț plafonat moale (`EAR_TOP`), iar greutățile urechii au acum
   rampă spre rădăcină (Ear/Head sau Ear/Body), nu 1,0 rigid (77 de vârfuri); în plus
   măsurat cu o sondă temporară: abaterea față de media vecinilor la Walk (cadrele 10
   și 28) nu mai are nicio ureche în primele locuri (rămân cusăturile
   picior/burtă, 0,08–0,11 m, ca la Serengeti). Toate cadrele de Walk
   (`asian_elephant_pose.png`, `_pose34.png`) și Trumpet recitite după ultimul build.

## Deviații și limite (de spus coordonatorului)

- **Cotele de la Serengeti din brief (3,4 / 6,4) sunt greșite** (4,62 / 6,20) —
  vezi mai sus. Contractul asiatic e respectat pe fișier.
- **Provența mesh-ului:** același mesh ca la Serengeti („191 animals pack”, fără
  fișier de licență în dosar, vezi `transfagarasan_inventory_c.md`), remodelat
  puternic dar nu refăcut. Decizia rămâne a coordonatorului.
- **Boltirile capului** sunt modeste (densitatea mesh-ului); o dublă boltire clară
  cere vertecși noi pe frunte (subdiviziune locală), nefăcută.
- **Walk:** ritm și amplitudine sunt cele din Serengeti (±14° pe picioare);
  corpul mai scund are pași mai scurți → **riscul de alunecare a labelor** (vezi mai
  jos). Cheile `Body.location.z` (0,04 m) n-au fost rescalate dacă
  `action.fcurves` nu există în Blender 5.2 (strat de acțiuni nou); efect sub 1 cm.
- Blender rulat o singură dată pe build; nu s-a rulat Godot (nu e cache de import
  în acest worktree).

## La integrare (coordonatorul, în cod)

1. Cheia `asian_elephant` în `SPLIT_MODELS`, `SLOT_REMAP_BY_MODEL` și
   `WALK_CYCLE_SPEED_BY_MODEL` (aceleași valori ca `elephant` ca punct de plecare;
   ruptura de accente e legată de numele `Elephant_Mesh`, deci clasa `elephant_hide`
   se aplică la fel).
2. Ritmul mersului se **măsoară** cu `tools/probe_foot_slide.gd` (labele sunt cu ~35%
   mai jos și corpul cu 10% mai scurt decât la Serengeti: viteza de ciclu
   probabil trebuie mărită).
3. Importul Godot (`--import`) pentru `animals/asian_elephant.glb`; apoi
   `ProbeRace` pe `[blocaj]` în piață (kit §1.3, pasul 5).
4. Capul e pe +Y în Blender = −Z în Godot, ca la Serengeti.
