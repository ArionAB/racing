export const meta = {
  name: 'machu-val-5',
  description: 'Recompozitia teraselor pe A si D: adancime de silueta, nu asize pe fata piesei',
  phases: [
    { title: 'Recompozitie', detail: 'A si D, in worktree frate' },
    { title: 'Judecata oarba', detail: 'critic separat, context proaspat' },
  ],
}

const REPO = 'D:/GameDev/ignition-spike'
const GODOT = 'D:\\GameDev\\Godot_v4.7-stable_win64_console.exe'
const SCRATCH = 'C:/Users/Arion/AppData/Local/Temp/claude/d--GameDev-ignition-spike/d634728c-7e44-4549-b925-fb5babd8856d/scratchpad'

// ---------------------------------------------------------------------------
// DE CE VALUL ASTA EXISTA, si de ce NU e inca o runda de "mai pune piese".
//
// Sase critici orbi, pe trei POI-uri, au cerut acelasi lucru: "blocuri
// individuale cu muchie proprie, nu lespezi continue", "poarta se citeste ca
// un decupaj de carton". Lead-ul a incercat DOUA cai pe FATA piesei si le-a
// masurat pe amandoua:
//
//   normal map pe clasa, la scara x6 ... +3 %  pe muchii grosiere (tinta +45 %)
//   3 benzi de asiza in mesh, +2,2 % tri ... 0 % (pe H chiar SCADE)
//
// Captura a aratat de ce: zidurile AU deja blocuri cu rosturi, din textura
// triplanara. Nu lipsesc rosturile. Ce lipseste e ADANCIMEA SILUETEI — in
// referinta terasele se decupeaza una peste alta, la noi sunt placi netede
// late, oricate muchii ar avea pe fata.
//
// Deci problema nu e a piesei, e a ASEZARII. Asta e primul val cu contract
// scris pe adancime, nu pe materie.
// ---------------------------------------------------------------------------

const POIS = [
  {
    key: 'a', zone: 'ZoneA_PiataSacra', name: 'A — Piata Sacra',
    fracs: '0.00, 0.02, 0.035', hazard: '',
    start: '2.68 straturi medii, 56.2 % raze cu 3+',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_A.png',
    inventar: `1172 de noduri: 612 inca_wall_b, 128 inca_wall_c, 96 tree_fern,
93 bromeliad, 62 inca_wall_a, 40 moss_boulder_a, plus pavajul (317 placi
A_PavajCurti) si iarba (145 placi) din valul 4.`,
    specific: `**Plafonul de cadru e REAL si masurat, si nu e al tau.** Din
cadru, 37-40 % e drum si 12-15 % e cer, deci decorului ii raman ~48 %; bara are
85 %, fiindca e o vedere de trei sferturi de sus a unei cetati, iar camera de
joc priveste IN LUNGUL unui drum de 18 m latime. **Nu incerca sa umpli cadrul**
— ai pierde rundele pe ceva ce tine de camera. Lucreaza la ADANCIMEA celor
~48 %, nu la cat ocupa.

Zona are deja terase cu podea (platforme la cote diferite, fete de sprijin,
scari) si curti pavate. **Nu le desface.** Le pui una PESTE alta in adancime.`,
  },
  {
    key: 'd', zone: 'ZoneD_Terase', name: 'D — Cascada de terase',
    fracs: '0.45, 0.49, 0.52', hazard: '',
    start: '1.87 straturi medii la frac 0.49, 25.7 % raze cu 3+ — CEA MAI PLATA de pe pista',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_D.png',
    inventar: `674 de noduri: 199 inca_wall_b, 179 inca_wall_c, 175 inca_wall_a,
45 water_channel, 32 inca_stair_a, 16 fountain_basin.`,
    specific: `**D e cazul cel mai clar de pe pista: 1,87 straturi medii, fata
de 2,68-2,79 pe A.** Un sfert din raze lovesc 3+ corpuri, fata de peste
jumatate pe A. Asta inseamna, literal, ca zidurile tale stau UNUL LANGA ALTUL,
nu unul peste altul.

**TERENUL DE SUB TINE E PLAT, si asta e decizie inchisa a dezvoltatorului.**
Masurat: prima cadere de 3 m e la 68 m dincolo de asfalt (pe C e la 11 m).
Dezvoltatorul a ales sa NU sape aici — D ramane zona de terase pe panta blanda.
Deci adancimea trebuie sa vina din CUM ASEZI, nu din teren. Nu cere relief si
nu-l fabrica.

Nota: bazinele turcoaz (fountain_basin) citesc ca PISCINE in captura de la
0.45, nu ca fantani incase. Daca le atingi oricum, e momentul.`,
  },
]

const CONTEXT = (p) => `
Recompui decorul POI-ului **${p.name}** al pistei Machu Picchu (Track15, index
8) din jocul de curse cu masinute de jucarie din ${REPO}.

**NU e o runda de "mai pune piese".** Zona ta are deja decor bogat si merge-uit.
Sarcina e sa-l REASEZI ca sa capete adancime, nu sa adaugi materie.

WORKTREE: D:/GameDev/wt-mp-${p.key}, branch feat/mp-poi-${p.key}.
Fa **git merge main** la inceput. Verifica "git branch --show-current" INAINTE
de fiecare commit. NU face NICIODATA "git stash" (e COMUN intre worktree-uri,
si exista deja unul al altcuiva in repo).
Binar Godot: ${GODOT}

## CONTRACTUL, pe cifra — citeste-l de doua ori

Tinta nu e "mai multe blocuri". E **adancimea de silueta**, masurata cu
\`tools/SvAdancime.tscn\`: cate corpuri distincte loveste o raza trasa din ochiul
soferului pana la fundal.

  & $E --headless --path D:/GameDev/wt-mp-${p.key} res://tools/SvAdancime.tscn

Cifra ta de plecare: **${p.start}**
Pentru comparatie, cea mai adanca felie de pe pista acum e 2,79 (frac 0.02).

**Tinta: +0,6 straturi medii fata de plecare, si +15 puncte la "%% raze cu 3+".**
Daca ajungi acolo si captura nu arata mai bine, SPUNE-O — cifra e un
instrument, nu scopul.

## CE S-A INCERCAT DEJA SI A PICAT — nu relua

Doua cai pe **fata piesei**, ambele masurate de lead, ambele zero:

| cale | cost | castig pe muchii grosiere |
|---|---|---|
| normal map pe clasa, scara x6 | 1 canal de textura | **+3 %** (tinta +45 %) |
| 3 benzi de asiza in mesh | +2,2 % triunghiuri | **0 %**, pe H scade |

Zidurile **au deja** blocuri cu rosturi, din textura triplanara — verifica pe
captura daca nu ma crezi. Deci:

- **NU** cere modificari de asset (mesh sau textura). Ambele cai sunt inchise.
- **NU** adauga piese doar ca sa umpli. Cadrul e deja plin pe A.
- **DA**: aseaza piesele existente ca sa se DECUPEZE una peste alta in
  adancime. O terasa care iese in fata si ascunde jumatate din cea de dupa ea
  face mai mult decat 50 de ziduri noi.

Detaliile complete: \`docs/track_briefs/machu_picchu_asize.md\` §8-§10.

## CE AI IN ZONA

${p.inventar}

${p.specific}

## BARA (tinta vizuala): ${p.bar}

DESCHIDE-O. Ce te intereseaza aici NU e materia (aia e deja buna) ci
**cum se suprapun planurile**: ce ascunde ce, cate straturi numeri de la
prim-plan la fundal, unde o muchie taie peste alta.

## GARZILE (dupa fiecare pas)

  & $E --headless --path D:/GameDev/wt-mp-${p.key} --import
  & $E --headless --path D:/GameDev/wt-mp-${p.key} --script res://tools/probe_decor.gd -- --track=15
  & $E --headless --fixed-fps 60 --path D:/GameDev/wt-mp-${p.key} res://tools/ProbeBuried.tscn -- --track=8
  & $E --headless --fixed-fps 60 --path D:/GameDev/wt-mp-${p.key} res://tools/ProbeLaneClear.tscn -- --track=8
  & $E --headless --fixed-fps 60 --path D:/GameDev/wt-mp-${p.key} res://tools/ProbeRace.tscn -- --mode=race --track=8 --seconds=150 --seed=1
ATENTIE: probe_decor si probe_manual iau **--track=15**; restul **--track=8**.

PRAGURI pe main: **16 materiale** (au SCAZUT de la 20 cand siluetele de orizont
au inlocuit sferele de rezerva), ProbeLaneClear **17** (baza 20), ProbeBuried
**0**, ProbeRace seed 1 = **2 repuneri PREEXISTENTE** (verificate pe main curat,
cifre identice la secunda).

## CAPTURA

**Snapshot NU merge cu --headless** — randarea cere fereastra, iar cu --headless
se blocheaza tacut pana la timeout, fara eroare clara:

  & $E --path D:/GameDev/wt-mp-${p.key} res://tools/Snapshot.tscn -- --track=8 --frac=<F> --gamecam ${p.hazard}

Fracturile tale: ${p.fracs}. Iesire: "snapshots/machu picchu_joc.png"
(SPATIU in nume). **--out= e IGNORAT.** Copiaza-le cu nume distincte in
${SCRATCH}/val5_${p.key}/.

**DESCHIDE pozele si uita-te la ele.** Cifra de adancime poate urca fara ca
imaginea sa se schimbe — atunci ai gresit pârghia, si trebuie spus.

COMITE dupa fiecare pas care trece o garda. Mesaje in romana, cu cifrele si
comanda care le-a produs.
`

const BUILD_SCHEMA = {
  type: 'object',
  properties: {
    done: { type: 'boolean' },
    depth_before: { type: 'string', description: 'straturi medii + % raze 3+, la inceput' },
    depth_after: { type: 'string', description: 'aceleasi cifre, la final' },
    pieces_moved: { type: 'number' },
    pieces_added: { type: 'number' },
    best_capture: { type: 'string', description: 'calea ABSOLUTA a capturii de trimis criticului' },
    guards: { type: 'string', description: 'cifrele, verbatim' },
    what_i_did: { type: 'string' },
    honest_gaps: { type: 'string', description: 'ce NU ai putut face, si de ce' },
    commit_shas: { type: 'array', items: { type: 'string' } },
  },
  required: ['done', 'depth_before', 'depth_after', 'best_capture', 'guards', 'what_i_did', 'honest_gaps'],
}

const CRIT_SCHEMA = {
  type: 'object',
  properties: {
    chose: { type: 'string', description: 'A sau B — ALEGEREA, facuta INAINTE de a citi cheia' },
    ours_won: { type: 'boolean' },
    guessed_right: { type: 'boolean' },
    the_one_difference: { type: 'string' },
    is_about_depth: { type: 'boolean', description: 'diferenta numita e despre suprapunere/adancime, sau despre altceva?' },
    fingerprint_ok: { type: 'boolean' },
  },
  required: ['chose', 'ours_won', 'guessed_right', 'the_one_difference', 'fingerprint_ok'],
}

const criticPrompt = (captura, bar, out, seed, zona) =>
  `Esti CRITIC VIZUAL pe un joc de curse arcade cu masinute de jucarie.
Judeci un singur lucru: **arata lumea noastra ca referinta?**

Ai in fata o plansa cu doua panouri, A si B. Unul e captura din jocul nostru,
celalalt e referinta. NU stii care e care.

  cd ${REPO}
  python tools/bar/blind_pair.py "${captura}" "${bar}" "${out}" --seed ${seed}

PROTOCOLUL, fara sa sari niciun pas:
1. Ruleaza comanda. Tipareste o AMPRENTA si calea CHEII.
2. **DESCHIDE plansa** (${out}) si uita-te la ea. Cu ochii, nu din cifre.
3. Verifica amprenta din coltul stanga-jos.
4. **ALEGE A sau B.**
5. ABIA ACUM citeste cheia.
6. Raporteaza CINSTIT daca ai nimerit.

APOI numeste **SINGURA diferenta care conteaza**.

Contextul zonei: ${zona}

**CE SA NU NUMESTI** (masurat deja, inchis, si a costat 9 runde):
- "lipsesc blocurile / asizele / rosturile" — zidurile AU blocuri cu rosturi,
  din textura. Doua incercari de a adauga mai multe (normal map la scara x6 si
  relief in mesh) au dat +3 % si 0 %. Daca asta vezi, uita-te mai atent: chiar
  lipsesc, sau sunt acolo si altceva e problema?
- "lipseste relieful / golul / panta" pe zone unde terenul e plat prin decizie
  a dezvoltatorului.
- "traseul e altfel", "rezolutia difera", "referinta e desenata".

**CE MERITA NUMIT**, daca il vezi: cum se suprapun planurile. Ce ascunde ce.
Cate straturi numeri de la prim-plan la fundal. Daca o muchie taie peste alta
sau totul sta intr-un singur plan.

REGULI:
- **Lauda nu ajuta.** Daca a noastra e mai slaba, spune de ce, precis.
- **Dar nici incrancenarea.** Daca a noastra castiga, spune-o la fel de limpede.
- Nu repara nimic. Doar judeca.`

async function poiLoop(p) {
  const runde = []
  for (let r = 1; r <= 3; r++) {
    const istoric = runde.length
      ? `\n\nRUNDE ANTERIOARE:\n${runde.map((x, i) => `Runda ${i + 1}: a ales ${x.chose}, a noastra ${x.ours_won ? 'A CASTIGAT' : 'a pierdut'}. Diferenta: ${x.the_one_difference}`).join('\n')}\n\n**Daca acelasi verdict apare a doua oara aproape neschimbat, opreste-te si verifica stratul de dedesubt** — s-ar putea sa ti se ceara ceva ce zona ta nu poate produce. Scrie-o in honest_gaps.`
      : ''

    const build = await agent(
      CONTEXT(p) + istoric + `\n\nRUNDA ${r} din 3. Recompune, masoara adancimea inainte si dupa, capteaza, raporteaza.`,
      { label: `recomp:${p.key}:r${r}`, phase: 'Recompozitie', schema: BUILD_SCHEMA },
    )

    if (!build?.best_capture) {
      runde.push({ chose: '-', ours_won: false, the_one_difference: 'fara captura' })
      continue
    }

    const seed = 5000 + r * 23 + p.key.charCodeAt(0)
    const out = `${SCRATCH}/val5/plansa_${p.key}_r${r}_s${seed}.png`
    const crit = await agent(
      criticPrompt(build.best_capture, p.bar, out, seed, p.name),
      { label: `critic:${p.key}:r${r}`, phase: 'Judecata oarba', schema: CRIT_SCHEMA },
    )

    runde.push({ ...crit, build })
    if (crit?.ours_won) return { poi: p.key, castigat: true, runda: r, runde, build }
  }
  return { poi: p.key, castigat: false, runde }
}

phase('Recompozitie')
const rez = await parallel(POIS.map((p) => () => poiLoop(p)))

return {
  castigate: rez.filter((r) => r?.castigat).map((r) => r.poi),
  detalii: rez.map((r) => ({
    poi: r?.poi,
    castigat: r?.castigat ?? false,
    adancime: r?.runde?.at(-1)?.build
      ? `${r.runde.at(-1).build.depth_before} -> ${r.runde.at(-1).build.depth_after}`
      : '?',
    runde: (r?.runde ?? []).map((x) => ({
      ales: x.chose, a_castigat: x.ours_won, despre_adancime: x.is_about_depth,
      diferenta: x.the_one_difference,
    })),
    mutate: r?.runde?.at(-1)?.build?.pieces_moved,
    garzi: r?.runde?.at(-1)?.build?.guards,
    goluri_cinstite: r?.runde?.at(-1)?.build?.honest_gaps,
  })),
}
