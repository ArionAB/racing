export const meta = {
  name: 'machu-val-3',
  description: 'Valul 3 Machu Picchu: rejudecarea oarba a celor 6 POI-uri deja construite (dupa scarp_tint) + constructor pe B si E, singurele zone goale',
  phases: [
    { title: 'Rejudecata', detail: 'critic orb pe POI-urile existente, pe lumea de ACUM' },
    { title: 'Constructie', detail: 'B si E, in worktree frate' },
    { title: 'Judecata oarba', detail: 'critic separat, context proaspat' },
  ],
}

const REPO = 'D:/GameDev/ignition-spike'
const GODOT = 'D:\\GameDev\\Godot_v4.7-stable_win64_console.exe'
const SCRATCH = 'C:/Users/Arion/AppData/Local/Temp/claude/d--GameDev-ignition-spike/74e515a1-c703-4f42-aaf2-ba914a36b188/scratchpad'

// ---------------------------------------------------------------------------
// Ce s-a schimbat de cand au judecat criticii ultima data: `scarp_tint`.
// Toate cele 6 POI-uri construite au fost judecate pe o lume in care fata
// oricarei caderi avea culoarea ierbii. Verdictele lor sunt despre o lume care
// nu mai exista, deci NU se pot folosi ca sa se decida ce mai e de facut.
// ---------------------------------------------------------------------------
const REJUDECATE = [
  { key: 'a', frac: '0.00', zona: 'Piata Sacra' },
  { key: 'c', frac: '0.33', zona: 'Poarta Soarelui si creasta' },
  { key: 'd', frac: '0.49', zona: 'Cascada de terase' },
  { key: 'f', frac: '0.70', zona: 'Malul raului' },
  { key: 'g', frac: '0.82', zona: 'Serpentinele' },
  { key: 'h', frac: '0.97', zona: 'Cornisa Podului Incas' },
]

const POIS = [
  {
    key: 'b', zone: 'ZoneB_DrumulIncas', name: 'B — Drumul Incas',
    fracs: '0.08, 0.14, 0.18', hazard: '--cloud-at=5.0',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_B.png',
    vezi: `drum TAIAT IN STANCA cu perete pe o parte, gura de TUNEL cu arc de
piatra, trepte alaturi, vegetatie agatata pe perete. Pe dreapta, fara parapet,
defileul.`,
    piese: `moss_boulder_a/b/c, bromeliad, tree_fern, orchid_cluster (accent roz,
RAR, la 2-3 m de banda), inca_stair_a/b, trail_marker.`,
    capcana: `1. **custom_step_ranges (0.0405-0.2034) e DEJA pe traseu**, iar
   treptele NU exista in coliziune (track.gd:_step_ranges — comentariul e
   explicit): sunt doar mesh vizual + 3 cm de zgomot pe raycast
   (Car.STEP_NOISE_M). NU pune geometrie de treapta cu prag peste 0,3 m peste
   carosabil: devine ZID. ProbeBuried pe toata urcarea.
2. **COAMA de la frac 0.186 e a ta ca LOC, dar NU e a ta ca decizie.** E
   singura repunere reproductibila din tot turul si singura coama din tot turul
   (tools/SvMpCoame.tscn): panta se rastoarna de la +11,5% la -9,5% pe ~25 m,
   masina decoleaza si aterizeaza pe coborare. Seed 2 da 0/1/1/2 pe patru
   rulari. **Nu incerca s-o repari cu decor** si nu atinge traseul — masoara
   inainte/dupa cu ProbeRace --seed=2 rulat de PATRU ori si raporteaza daca
   decorul tau a schimbat cifra. Detalii: docs/track_briefs/
   machu_picchu_stare_poi.md §3.6.
3. **Caderea din dreapta e o TAIETURA VERTICALA, si scarp_tint n-o prinde.**
   Masurat pe mesh: peretii verticali apar la 28-35 grade (grila de teren e
   ~15,8 m, o cadere de 20 m intinsa pe o celula nu poate fi mai abrupta).
   Daca peretele tau citeste verde, NU cobori pragul global — spune-o in
   raport, e o limita de rezolutie a grilei, nu o greseala a ta.`,
    istoric: `POI NOU, zona are 0 noduri de decor. Relieful EXISTA pe intervalul
tau: rapa 0 (0.0734-0.3556, latime 75, partea +1) cu podea la -40. Masurat cu
SvMpBuza: pe dreapta prima cadere de 3 m e la 17,5 m dincolo de asfalt, de 25 m
la 22,9 m. Pe stanga e versantul care urca.`,
  },
  {
    key: 'e', zone: 'ZoneE_Pod', name: 'E — Podul de franghie',
    fracs: '0.57, 0.60, 0.63', hazard: '--rope-load=2.6,0.5',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_E.png',
    vezi: `scanduri pe cabluri intre DOUA TURNURI de piatra, autobuzul galben pe
tablier, DEFILEUL dedesubt.`,
    piese: `bamboo_clump, moss_boulder_*, tree_fern, polylepis_a/b,
inca_house_b. Plus apa raului la -40 (shader v12, ca la Serengeti).`,
    capcana: `**POI-ul E NU construieste podul.** Tablierul si turnurile sunt
facute IN COD (rope_bridge_hazard.gd:313-392), hazardul e cablat in
Track15.tscn:48. Tu construiesti ce e IN JURUL lui.

**GORJA EXISTA — verific-o inainte sa "repari" ceva.** Am masurat-o eu (lead)
inainte sa pornesti, fiindca prima mea masuratoare a fost gresita si vreau sa
n-o repeti: o raza verticala sub tablier loveste PLACILE PODULUI
(Plate3/Plate7, AnimatableBody3D), nu terenul, si raporteaza "gol 0". Cu raza
continuata sub ele, TerrainBody e la **-40.30**, tablierul la **-20.00** —
adica exact cei 20 m ceruti de brief, pe cel putin 30 m in ambele parti.
Sonda: tools/SvMpE.tscn. **Filtreaza dupa numele corpului lovit** in orice
sonda proprie.

CE E REAL DE REPARAT, vazut pe captura: terenul de LANGA tablier urca inapoi la
cota lui, deci podul citeste ca traversare peste o adancitura, nu peste un gol.
Buza de plecare, peretii defileului si raul la -20 sub tablier sunt exact
treaba ta. Memoriile: apa-iluminata-v12 (pata gri = panza opaca, lipseste
Fresnel-ul din chase cam), strop-apa-particule, celula-de-apa-plana-peste-mal.

Si: afundarea podului sub masa se verifica pe CAPTURA cu --rope-load=2.6,0.5
(memoria efecte-invizibile-nu-se-numara), nu numarand instante.`,
    istoric: `POI NOU, zona are 0 noduri de decor. Rapele de pe intervalul tau:
2 (0.5269-0.5834, viaduct, podea -40) si 3 (0.5834-0.6611, partea +1, podea
-40).`,
  },
]

const CONTEXT = (p) => `
Construiesti decorul POI-ului **${p.name}** al pistei Machu Picchu (Track15,
index 8) din jocul de curse cu masinute de jucarie din ${REPO}.

WORKTREE: D:/GameDev/wt-mp-${p.key}, branch feat/mp-poi-${p.key}.
Verifica "git branch --show-current" INAINTE de fiecare commit
(memoria merge-ul-lasa-tree-ul-pe-main). NU face NICIODATA "git stash"
(memoria git-stash-partajat-intre-sesiuni: stash-ul e COMUN intre worktree-uri,
si exista deja unul al altcuiva in repo — nu-l atinge).
Binar Godot: ${GODOT}

CITESTE INTAI (sunt scrise pentru tine, nu le sari):
- docs/track_briefs/machu_picchu_poi_gauntlet.md — contractul per POI.
- docs/track_briefs/machu_picchu_stare_poi.md — starea si ce e deschis.
- docs/track_briefs/machu_picchu_val2_constatare.md — **de ce valul 2 a dat
  0/3**, si lectia care te priveste direct.
- docs/asset_briefs/machu_picchu_masuratori.md — inventarul MASURAT al kitului.
- docs/decor_manual.md si docs/bara_vizuala.md (regula zero: CAPTURA BATE CIFRA).

LECTIA VALULUI 2, ca sa n-o repeti: trei POI-uri au ars cate 3 runde fiindca
criticii cereau "buza / gol / stanca" pe zone unde caderea EXISTA dar avea
culoarea ierbii. S-a rezolvat la nivel de teren cu cheia de tema \`scarp_tint\`
(fata de stanca dupa PANTA). **Lumea ta arata deja altfel decat cea pe care au
judecat-o criticii valului 2.** Daca criticul tau cere tot "stanca", verifica
INTAI daca forma exista (masoara unghiul din ochiul camerei, nu panta pe harta)
si abia apoi adauga piese — memoria contrastul-nu-geometria.

FUNDATIA E GATA: cele 39 de GLB-uri sunt inregistrate ca ext_resource in
Track15.tscn cu id-uri "s_<stem>", DecorManual are cele 8 zone, PROP_COLLISION e
completat, clasa inca_stone exista si acopera toata zidaria.
Tu umpli **doar** DecorManual/${p.zone}. NU atinge alte zone.

BARA (tinta vizuala): ${p.bar}
DESCHIDE-O si uita-te la ea inainte sa asezi ceva. Ce trebuie sa se citeasca:
${p.vezi}

REGULA CARE SE INCALCA CEL MAI DES: **bara e LOOK, nu layout.** Compari
MATERIA — piatra, iarba, vegetatia, silueta — nu unde cade fiecare obiect.
Nu redesena traseul.

PIESELE POTRIVITE: ${p.piese}

CAPCANA SPECIFICA: ${p.capcana}

${p.istoric}

CUM SE ASEAZA (tiparul deja folosit pe C/D/H — CITESTE tools/gen_decor_mp_d.gd):
generator tools/gen_decor_mp_${p.key}.gd + wrapper .tscn. Puncte cheie:
- "--survey" INTAI: masoara terenul real pe intervalul tau si pune cifrele in
  antetul generatorului. La valul 2 asta a fost diferenta intre POI-uri care au
  livrat si POI-uri care au ars runde.
- Asezarea pe **fractie + parte + gol fata de MARGINEA drumului**, nu pe XYZ.
- Cota din **raycast pe TerrainBody-ul real**, NU din campul neted (memoria
  terrain-mesh-y-extrapoleaza). **Si filtreaza dupa numele corpului lovit** —
  vezi capcana lui E.
- Scara in metri, impartita la inaltimea masurata a piesei.
- Transform3D in .tscn e pe RANDURILE bazei (memoria tscn-transform-e-pe-randuri).
- NU pune "#" intre proprietatile unui nod in .tscn.

GARZILE (pe scena integrata din worktree-ul TAU, dupa fiecare pas):
  & $E --headless --path D:/GameDev/wt-mp-${p.key} --import
  & $E --headless --path D:/GameDev/wt-mp-${p.key} --script res://tools/probe_decor.gd -- --track=15
  & $E --headless --fixed-fps 60 --path D:/GameDev/wt-mp-${p.key} res://tools/ProbeBuried.tscn -- --track=8
  & $E --headless --fixed-fps 60 --path D:/GameDev/wt-mp-${p.key} res://tools/ProbeLaneClear.tscn -- --track=8
  & $E --headless --fixed-fps 60 --path D:/GameDev/wt-mp-${p.key} res://tools/ProbeRace.tscn -- --mode=race --track=8 --seconds=150 --seed=N
ATENTIE: probe_decor ia **--track=15**, restul iau **--track=8**.

PRAGURI, masurate pe main azi (18 sep):
- probe_decor **19 materiale**, 9312 prop-uri, 1 095 030 tri. Plafonul e **30**
  (ridicat de dezvoltator de la 20, cu motivul in machu_picchu.md §6; garda
  pica la 38). **Ai loc, dar plafonul NU e o alocatie de cheltuit**: un
  material nou se cere EXPLICIT in raport, cu ce cumpara. inca_stone acopera
  zidaria, macchia verdele de padure.
- ProbeRace **0 repuneri** pe seed 1 si 3. Seed 2 da **0/1/1/2 pe patru rulari**
  — e coama de la frac 0.186, preexistenta (§3.6). Daca vezi 1 pe seed 2, NU e
  regresia ta; daca vezi 2-3 pe seed 1 sau 3, e.
- ProbeBuried **0**. ProbeLaneClear **18, baza 20**.
- Panta 11,5 % si raza 9,0 m — daca se misca, ai atins traseul.
Citeste si [blocaj], lent, invers, carusel, % offroad, nu doar "repuneri"
(memoria zero-repuneri-ascunde-blocajul).

CAPTURA (din masina):
  & $E --rendering-driver vulkan --path D:/GameDev/wt-mp-${p.key} res://tools/Snapshot.tscn -- --track=8 --frac=<F> --gamecam ${p.hazard}
Fracturile tale: ${p.fracs}. Iesirea: "snapshots/machu picchu_joc.png"
(SPATIU in nume — intre ghilimele). **DESCHIDE pozele si uita-te la ele** dupa
fiecare runda; salveaza-le cu nume distincte in ${SCRATCH}/poi_${p.key}/.

COMITE dupa fiecare pas care trece o garda. Mesaje in romana, cu cifrele si
comanda care le-a produs. Fara "OK" fara cifra.
`

const BUILD_SCHEMA = {
  type: 'object',
  properties: {
    done: { type: 'boolean' },
    pieces_placed: { type: 'number' },
    capture_paths: { type: 'array', items: { type: 'string' } },
    best_capture: { type: 'string', description: 'calea ABSOLUTA a capturii de trimis criticului' },
    guards: { type: 'string', description: 'cifrele, verbatim' },
    what_i_built: { type: 'string' },
    honest_gaps: { type: 'string' },
    commit_shas: { type: 'array', items: { type: 'string' } },
  },
  required: ['done', 'pieces_placed', 'best_capture', 'guards', 'what_i_built'],
}

const CRIT_SCHEMA = {
  type: 'object',
  properties: {
    chose: { type: 'string', description: 'A sau B — ALEGEREA, facuta INAINTE de a citi cheia' },
    ours_won: { type: 'boolean' },
    guessed_right: { type: 'boolean' },
    the_one_difference: { type: 'string' },
    why_it_matters: { type: 'string' },
    fingerprint_ok: { type: 'boolean' },
  },
  required: ['chose', 'ours_won', 'guessed_right', 'the_one_difference', 'fingerprint_ok'],
}

const criticPrompt = (captura, bar, out, seed, vezi) =>
  `Esti CRITIC VIZUAL pe un joc de curse arcade cu masinute de jucarie.
Judeci un singur lucru: **arata lumea noastra ca referinta?**

Ai in fata o plansa cu doua panouri, A si B. Unul e captura din jocul nostru,
celalalt e referinta. NU stii care e care, si asta e intentionat.

PLANSA se genereaza cu comanda asta, pe care o rulezi TU:

  cd ${REPO}
  python tools/bar/blind_pair.py "${captura}" "${bar}" "${out}" --seed ${seed}

PROTOCOLUL, in ordinea asta, fara sa sari niciun pas:
1. Ruleaza comanda. Ea tipareste o AMPRENTA si calea CHEII.
2. **DESCHIDE plansa** (${out}) si uita-te la ea. Nu judeca din cifre sau
   descrieri. Cu ochii.
3. Verifica in coltul din stanga-jos ca amprenta tiparita e aceeasi cu cea din
   numele fisierului-cheie. Daca nu e, plansa nu e a ta — opreste-te.
4. **ALEGE A sau B** — care panou arata mai mult ca o lume de joc coerenta,
   construita cu intentie: materie recognoscibila (piatra, iarba, vegetatie),
   silueta citibila, adancime, lumina care descrie forme.
5. ABIA ACUM citeste fisierul-cheie si afla care era care.
6. Raporteaza CINSTIT daca ai nimerit.

APOI numeste **SINGURA diferenta care conteaza**. Una. Cea mai importanta. Si
care sa fie **reparabila in decorul POI-ului** — nu "traseul e altfel" (traseul
e masurat si fix), nu "rezolutia difera", nu "referinta e desenata".

Contextul zonei, ca sa stii ce ar trebui sa se vada:
${vezi}

REGULI:
- **Lauda nu ajuta.** Daca a noastra e mai slaba, spune de ce, precis.
- **Dar nici incrancenarea.** Daca a noastra chiar castiga, spune asta la fel de
  limpede — miza e sa se termine, nu sa se prelungeasca.
- Nu repara nimic. Nu atinge cod. Doar judeca.`

// --- FAZA 1: rejudecarea celor sase POI-uri deja construite -----------------
// Ruleaza INAINTE de constructori: daca unul dintre ele castiga acum, e primul
// POI terminat de pe pista, si aia schimba ce mai e de facut.
async function rejudeca(r) {
  const capt = `${SCRATCH}/rejudecata/${r.key}_f${r.frac}.png`
  const out = `${SCRATCH}/rejudecata/plansa_${r.key}.png`
  const bar = `docs/track_briefs/img/bar_machu/bara_poi_${r.key.toUpperCase()}.png`
  const gata = await agent(`Faci O SINGURA captura din jocul nostru, pentru o judecata oarba.

  cd ${REPO}
  & ${GODOT} --rendering-driver vulkan --path ${REPO} res://tools/Snapshot.tscn -- --track=8 --frac=${r.frac} --gamecam

Iesirea e "snapshots/machu picchu_joc.png" (SPATIU in nume — intre ghilimele).
Copiaz-o la: ${capt}
(fa directorul daca nu exista). Apoi DESCHIDE-O si descrie in doua propozitii
ce se vede — atat, nu judeca si nu repara nimic.

Zona e POI ${r.key.toUpperCase()} (${r.zona}).`,
    { label: `captura:${r.key}`, phase: 'Rejudecata' })
  if (!gata) return null

  const crit = await agent(criticPrompt(capt, bar, out, 31 + r.key.charCodeAt(0), r.zona),
    { label: `rejudec:${r.key}`, phase: 'Rejudecata', schema: CRIT_SCHEMA, effort: 'high' })
  if (!crit) return { poi: r.key, won: false, diff: 'critic esuat' }
  log(`rejudecata ${r.key.toUpperCase()}: ${crit.ours_won ? 'CASTIGAT' : 'nu'} — ${(crit.the_one_difference || '').slice(0, 100)}`)
  return { poi: r.key, zona: r.zona, won: crit.ours_won, guessed: crit.guessed_right, diff: crit.the_one_difference, why: crit.why_it_matters }
}

// --- FAZA 2: constructor + critic pe B si E ---------------------------------
const MAX_RUNDE = 3

async function unPoi(p) {
  let feedback = ''
  let last = null
  const istoric = []

  for (let runda = 1; runda <= MAX_RUNDE; runda++) {
    const build = await agent(`${CONTEXT(p)}

${runda === 1 ? `RUNDA 1. Zona e GOALA (0 noduri de decor). Incepe cu "--survey".` :
`RUNDA ${runda}. Un critic a comparat captura ta cu bara, ORB, si NU a ales-o pe
a noastra. Verdictul lui, cuvant cu cuvant:

  «${feedback}»

Reparati EXACT asta. Nu reconstrui ce mergea; nu adauga lucruri pe care criticul
nu le-a cerut. Daca dupa ce te uiti la bara crezi ca verdictul e gresit, ai voie
sa spui asta CU DOVADA (captura + masuratoare) — un refuz motivat e livrare
valida. Dar ai voie o singura data, si trebuie sa arati de ce.`}

Cand esti gata: fa capturile, DESCHIDE-le, si alege-o pe cea mai reprezentativa
(nu cea mai frumoasa — cea care arata cel mai cinstit cum se vede zona din
masina). Salveaza-le cu nume DISTINCT in ${SCRATCH}/poi_${p.key}/ si da calea
ABSOLUTA in "best_capture".`,
      { label: `constr:${p.key}:r${runda}`, phase: 'Constructie', schema: BUILD_SCHEMA })

    if (!build || !build.best_capture) {
      log(`POI ${p.key} runda ${runda}: constructorul n-a produs captura — opresc`)
      break
    }
    last = build

    const out = `${SCRATCH}/plansa_${p.key}_r${runda}.png`
    const crit = await agent(
      criticPrompt(build.best_capture, p.bar, out, runda * 23 + p.key.charCodeAt(0), p.vezi),
      { label: `critic:${p.key}:r${runda}`, phase: 'Judecata oarba', schema: CRIT_SCHEMA, effort: 'high' })

    istoric.push({ runda, ours_won: crit ? crit.ours_won : null, diff: crit ? crit.the_one_difference : 'critic esuat' })

    if (crit && crit.ours_won) {
      log(`POI ${p.key}: CASTIGAT orb in runda ${runda}`)
      return { poi: p.key, name: p.name, won: true, runde: runda, build, crit, istoric }
    }
    feedback = crit ? `${crit.the_one_difference} — ${crit.why_it_matters || ''}` : 'criticul a esuat'
    log(`POI ${p.key} runda ${runda}: nu a castigat — ${feedback.slice(0, 110)}`)
  }

  return { poi: p.key, name: p.name, won: false, runde: MAX_RUNDE, build: last, istoric }
}

// Rejudecata INTAI (ieftina, si schimba ce stim), apoi constructorii.
const rejud = await parallel(REJUDECATE.map((r) => () => rejudeca(r)))
const castigate_rejud = rejud.filter(Boolean).filter((r) => r.won)
log(`rejudecata: ${castigate_rejud.length}/6 castigate orb pe lumea de ACUM`)

const rez = await parallel(POIS.map((p) => () => unPoi(p)))
const ok = rez.filter(Boolean).filter((r) => r.won)
log(`valul 3: ${ok.length}/2 castigate orb`)

return {
  rejudecata: rejud,
  rejudecata_castigate: castigate_rejud.map((r) => r.poi),
  constructie: rez,
  castigate: ok.map((r) => r.poi),
}
