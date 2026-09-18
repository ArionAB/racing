export const meta = {
  name: 'machu-val-2',
  description: 'Valul 2 de POI-uri Machu Picchu (C Poarta Soarelui, D Terasele, H Cornisa): constructor + critic orb pe fiecare',
  phases: [
    { title: 'Constructie', detail: 'un constructor per POI, in worktree frate' },
    { title: 'Judecata oarba', detail: 'critic separat, context proaspat, planse din blind_pair' },
  ],
}

const REPO = 'D:/GameDev/ignition-spike'
const GODOT = 'D:\\GameDev\\Godot_v4.7-stable_win64_console.exe'
const SCRATCH = 'C:/Users/Arion/AppData/Local/Temp/claude/d--GameDev-ignition-spike/74e515a1-c703-4f42-aaf2-ba914a36b188/scratchpad'

const POIS = [
  {
    key: 'c', zone: 'ZoneC_PoartaSoarelui', name: 'C — Poarta Soarelui si creasta',
    fracs: '0.24, 0.30, 0.33, 0.36', hazard: '',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_C.png',
    vezi: `poarta de piatra pe creasta cu CONDORUL pe stanca alaturata, aripile
desfacute; drumul pe MUCHIE, cu nor dedesubt de ambele parti; silueta se citeste
pe cer, nu pe un fundal de deal.`,
    piese: `inti_punku (Poarta Soarelui, gol MASURAT 13,98 m pe axa drumului —
sub 14 poarta devine perete, iar drumul are semi-latime 6,5 acolo), condor
(STATIC, asezat pe stanca la ~2 m), guardhouse (Casa Paznicului, la ~0.33 —
cadrul pozei clasice), rope_rail ca parapet PUNCTUAT (doar la cele doua ace),
moss_boulder_a/b/c, polylepis_a/b, trail_marker.`,
    capcana: `CEA MAI SCUMPA CAPCANA DE PE PISTA, si e deja platita o data la
valul 1: memoria umarul-ingust-ascunde-caderea. Ochiul e la 10 m, conteaza
UNGHIUL din primii metri, nu adancimea finala. Creasta ARE rapa (indicii 0 si 1,
pe 0.0734-0.3556), deci relieful exista — dar verifica pe captura ca se vede
caderea de AMBELE parti, nu doar pe una.
Memoria perete-paralel-nu-se-vede: doar serpentina spre interior infasoara
peretele. Brief-ul cere doua S-uri cu concavitatea spre cetate.
CAPTURA OBLIGATORIE la ~0.33 (Casa Paznicului): se vede cetatea SUB tine si
Huayna Picchu IN FATA, sau se vede taluz? Asta decide POI-ul.
Condorul e decor cu un os: actiunile Open/Close n-au declansator in cod, deci
NU incerca sa-l animezi — il asezi.`,
    istoric: `POI NOU, nimic construit inca. Dar valul 1 a platit doua lectii
care se aplica direct:
1. Zidaria: clasa inca_stone acopera ACUM toate piesele de piatra, inclusiv
   inti_punku. Nu mai trebuie sa faci nimic pentru asta.
2. Coronamentul: pe CAMPURI de ziduri, iarba (slot 12) intra in corp, nu ramane
   accent — altfel fiecare zid arata o dunga verde unde incepe talpa celui din
   spate. Pe creasta ai putine ziduri, deci probabil nu te atinge; daca pui un
   camp, tine minte.`,
  },
  {
    key: 'd', zone: 'ZoneD_Terase', name: 'D — Cascada de terase',
    fracs: '0.44, 0.49, 0.52', hazard: '--cross-at=12',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_D.png',
    vezi: `TERASE IN TREPTE cu o SCARA DE PIATRA care coboara DREPT prin ele —
asta e silueta care face POI-ul; canal de apa pe o parte; lame pe trepte; o casa
sus. Dungile alb/umbra de sub fiecare zid de terasa sunt identitatea.`,
    piese: `inca_wall_a/b/c cu COLIZIUNE pe trepte de 2,5 m, inca_stair_a/b
(scara care coboara drept prin terase), fountain_basin x16 in trepte,
water_channel, llama*, inca_house_b.`,
    capcana: `Terasele sunt TALUZ DE TEREN + piese de zid, NU TerrainStep
(respins la constructie: celula de teren e 7,9 m, o treapta de 2,5 m ar iesi
rampa de 17 grade, nu zid).
Rampa principala trebuie sa intre in zid FARA PRAG (memoria
suprafete-din-placi-plane: liniar pe portiuni, MIN nu produs). Pragul lateral
peste 0,3 m e zid — aici e INTENTIONAT zid (terasa de sub tine), dar nu pe rampa.
LAMELE sunt deja cablate la frac 0,490-0,498 si au fost REPARATE la fundatie
(aveau 53 cm, acum au 1,66 m). ProbeRace arata inca un blocaj ocazional la
frac 0.493-0.500: brief-ul lasa deschisa decizia "parcate pe interiorul acului
prind Autobuzul — de verificat daca parcarea pe exterior e mai cinstita".
E decizia TA, pe masuratoare: ruleaza ProbeRace cu --slice=0.42,0.56 inainte si
dupa ce le muti, si scrie cifra.
SOARELE: azimutul se alege ca zidurile sa arunce umbra pe treapta de sub ele.
Se REMASOARA (memoria azimutul-soarelui-fata-de-drum) — dar NU schimba tema,
ci raporteaza daca azimutul actual (-40, 45) nu da dungile.`,
    istoric: `POI NOU. Relieful exista pe intervalul tau (rapele 2 si 3, pe
0.5269-0.6611 partial, plus terenul modelat). Verifica pe survey INAINTE sa
construiesti: daca terasele tale cad in afara rapelor, spune-o — la valul 1
trei POI-uri au ars runde construind pe teren plat fiindca nimeni n-a verificat
intai (memoria criticul-cere-ce-zona-nu-poate-da).`,
  },
  {
    key: 'h', zone: 'ZoneH_Cornisa', name: 'H — Cornisa Podului Incas',
    fracs: '0.94, 0.97', hazard: '--bridge-at=0.24',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_H.png',
    vezi: `cornisa pe PERETE cu portal/poarta de piatra; golul pe o parte, zidul
pe cealalta; drumul se stramteaza vizibil catre poarta.`,
    piese: `main_gate (Poarta Principala; gol LIBER MASURAT 7,39 m, nu 8,39 cum
scrie inventarul — vezi mai jos), inca_bridge_ledge (cornisa, gol 4,23 m la
cota ei), rope_rail, moss_boulder_*, polylepis_a/b.`,
    capcana: `DOUA lucruri deschise, amandoua scrise si nerezolvate:
1. **main_gate are 7,39 m liber, nu 8,39 — si e mai INGUST decat drumul.**
   Asta e cifra pe care trebuie s-o intelegi inainte sa asezi poarta; am
   verificat-o eu (lead) inainte sa pornesti, ca sa n-o descoperi la runda 3.
   - Golul liber masurat pe geometrie, prin proiectia triunghiurilor pe planul
     (lateral, y), grila de 1 cm: **7,39 m, CONSTANT de la sol pana sub
     buiandrug** (docs/asset_briefs/machu_picchu_masuratori.md §3). Nu se
     stramteaza pe verticala, cum sugereaza cele trei cifre din inventar
     (8,390 / 7,410 / 6,000) — alea nu descriu piesa.
   - **Drumul la locul portii are 8,0 m.** Track15.tscn custom_width_segments
     are Vector3(0.9631, 0.9703, 4) — semi-latime 4,0 pe exact intervalul
     portii. Brief-ul §2 (randul H) descrie intentia: drumul se strange de la
     13 la 8 m, poarta livreaza 8,4 m, deci poarta INCADREAZA drumul cu 0,4 m
     joc de fiecare parte. Gatuirea trebuia sa fie a DRUMULUI, nu a pietrei.
   - Cu 7,39 m, intentia se inverseaza: poarta e cu **0,61 m mai ingusta decat
     carosabilul**, adica usciorii stau IN drum. Nu mai e un cadru, e un
     obstacol — si o masina care tine marginea intra in piatra.
   Deci: **masoara inainte sa concluzionezi, si nu repara in tacere.** Asaza
   poarta, apoi ruleaza ProbeRace --slice=0.92,1.00 pe cel putin 3 seed-uri si
   ProbeLaneClear, si raporteaza cifrele. Optiunile, daca plutonul chiar
   sufera, sunt trei si NICIUNA nu e a ta s-o alegi singur: (a) se lateste
   piesa la ~8,4 m, (b) se ingusteaza drumul sub 7,39 ca poarta sa redevina
   cadru, (c) se accepta ca poarta e o gatuire reala si se verifica doar ca e
   trecatoare. Raporteaza CE AI MASURAT si care varianta o recomanzi, cu
   motivul. Decizia se ia la integrare.
2. **Barnele aduc rampele podului mobil.** Reuse-ul LiftBridgeHazard pune un
   damb de 1,6 m pe cornisa, deci profilul nu mai citeste "barne peste gol";
   iar SUB gol terenul ramane la -0,3 m, deci nu e prapastie. Brief-ul §3 spune
   ca cere sapatura locala de 4 m. Verifica pe captura cu --bridge-at=0.24
   (barnele ridicate) si spune ce vezi.
Rapa 4 (0.912-0.9809) acopera intervalul tau, deci relieful exista.`,
    istoric: `POI NOU. main_gate si inti_punku au primit clasa inca_stone la
integrarea valului 1, deci portile sunt granit, nu atlas plat. Restul e de
construit.`,
  },
]

const CONTEXT = (p) => `
Construiesti decorul POI-ului **${p.name}** al pistei Machu Picchu (Track15,
index 8) din jocul de curse cu masinute de jucarie din ${REPO}.

WORKTREE: D:/GameDev/wt-mp-${p.key}, branch feat/mp-poi-${p.key}.
Verifica "git branch --show-current" INAINTE de fiecare commit
(memoria merge-ul-lasa-tree-ul-pe-main). NU face NICIODATA "git stash"
(memoria git-stash-partajat-intre-sesiuni: stash-ul e COMUN intre worktree-uri).
Binar Godot: ${GODOT}

CITESTE INTAI (sunt scrise pentru tine, nu le sari):
- docs/track_briefs/machu_picchu_poi_gauntlet.md — contractul per POI,
  tabelul de fracturi si flaguri, si regula care se incalca cel mai des.
- docs/track_briefs/machu_picchu.md §2 (POI-urile) si §4 (paleta/lumina).
- docs/asset_briefs/machu_picchu_masuratori.md — inventarul MASURAT al
  kitului: nume REALE de noduri, sloturi per nod, inaltimi, raze, coliziune.
  Brief-ul a gresit de doua ori la kitul asta; asta e sursa de adevar.
- docs/decor_manual.md — cum se aseaza decor manual.
- docs/bara_vizuala.md — regula zero: CAPTURA BATE CIFRA.

FUNDATIA E GATA (merge-uita pe main): cele 39 de GLB-uri sunt inregistrate ca
ext_resource in Track15.tscn cu id-uri "s_<stem>", DecorManual exista cu cele 8
zone, PROP_COLLISION e completat pe masuratoare, clasa inca_stone exista.
Tu umpli **doar** DecorManual/${p.zone}. NU atinge alte zone — alte doua POI-uri
lucreaza in paralel si integrarea le imbina.

BARA (tinta vizuala): ${p.bar}
DESCHIDE-O si uita-te la ea inainte sa asezi ceva. Ce trebuie sa se citeasca:
${p.vezi}

REGULA CARE SE INCALCA CEL MAI DES: **bara e LOOK, nu layout.** Diorama e
comprimata si stilizata; traseul real e altul si a trecut deja ProbeLayout.
Compari MATERIA — piatra, iarba, vegetatia, silueta — nu unde cade fiecare
obiect. Nu redesena traseul.

PIESELE POTRIVITE: ${p.piese}

CAPCANA SPECIFICA: ${p.capcana}

${p.istoric}

CUM SE ASEAZA (tiparul Serengeti, tools/gen_decor_ser_*.gd):
Scrie un generator tools/gen_decor_mp_${p.key}.gd + wrapper .tscn, dupa modelul
tools/gen_decor_ser_d.gd (CITESTE-L). Puncte cheie:
- "--survey" INTAI: masoara terenul real (cota la ±8/15/25/40 m lateral,
  semi-latimea, vectorul lateral, directia soarelui) pe intervalul tau de
  fracturi, si pune cifrele in antetul generatorului.
- Asezarea se face pe **fractie + parte + gol fata de MARGINEA drumului**, nu pe
  XYZ absolut.
- Cota vine din **raycast pe TerrainBody-ul real** (_sol_real), NU din campul
  neted: memoria terrain-mesh-y-extrapoleaza — prop-urile asezate pe el plutesc.
- Scara se cere **in metri**, impartita la inaltimea masurata a piesei.
- Generatorul scrie un fragment .part de linii "[node ...]", pe care il
  splice-uiesti sub nodul zonei in Track15.tscn.
- Transform3D in .tscn e pe RANDURILE bazei (memoria tscn-transform-e-pe-randuri):
  yaw pur = Transform3D(cos*s, 0, sin*s, 0, s, 0, -sin*s, 0, cos*s, x, y, z).
- NU pune "#" intre proprietatile unui nod in .tscn (memoria
  tscn-comentariu-taie-proprietati: opreste parserul).

GARZILE (pe scena integrata din worktree-ul TAU, dupa fiecare pas):
  & $E --headless --path D:/GameDev/wt-mp-${p.key} --import
  & $E --headless --path D:/GameDev/wt-mp-${p.key} --script res://tools/probe_decor.gd -- --track=15
  & $E --headless --fixed-fps 60 --path D:/GameDev/wt-mp-${p.key} res://tools/ProbeBuried.tscn -- --track=8
  & $E --headless --fixed-fps 60 --path D:/GameDev/wt-mp-${p.key} res://tools/ProbeLaneClear.tscn -- --track=8
  & $E --headless --fixed-fps 60 --path D:/GameDev/wt-mp-${p.key} res://tools/ProbeRace.tscn -- --mode=race --track=8 --seconds=150 --seed=N
  & $E --headless --path D:/GameDev/wt-mp-${p.key} --script res://tools/probe_manual.gd -- --track=15
ATENTIE: probe_decor ia **--track=15** (numar de scena), restul iau **--track=8**
(index). probe_decor --track=8 masoara OKINAWA si da verde.

PRAGURI, cu cifrele de PLECARE masurate pe scena integrata (main de azi):
- ProbeRace **0 repuneri**. Masurat azi pe main: **0 pe seed 1, 2 si 3**
  (offroad max 0.0% / 1.1% / 0.0%). E nedeterminist (memoria
  proberace-nedeterminism) — daca vezi 1, re-ruleaza inainte sa acuzi o
  regresie, dar daca vezi 2-3 constant, e a ta.
- probe_decor **19 materiale ACUM** (masurat pe main azi, 18 sep). Plafonul a
  fost ridicat la **30** de dezvoltator (docs/track_briefs/machu_picchu.md §6:
  cifra veche de 20 presupunea ca fiecare GLB costa un material, ceea ce e fals
  masurat — kitul costa zero, doar CLASA de textura costa 1). Garda pica la 38.
  **Ai loc, dar plafonul NU e o alocare de cheltuit:** un material nou se cere
  **explicit in raport**, cu motivul si cu ce cumpara vizual. Ce se poate
  refolosi, se refoloseste (inca_stone acopera TOATA zidaria, inclusiv portile;
  macchia acopera verdele de padure). Raporteaza cifra dupa fiecare runda.
- ProbeBuried **0**. ProbeLaneClear **18, baza 20** (verificat azi) — ai marja
  2, deci daca decorul tau intra in banda se vede imediat.
- Panta ramane **11,5 %** si raza minima **9,0 m** — daca se misca, ai atins
  traseul, ceea ce nu e treaba ta.
Si nu te uita doar la "repuneri": citeste [blocaj], lent, invers, carusel,
% offroad fata de starea de plecare (memoria zero-repuneri-ascunde-blocajul —
0 repuneri poate ascunde o regresie reala).

CAPTURA (din masina, ca sa vezi ce vede jucatorul):
  & $E --rendering-driver vulkan --path D:/GameDev/wt-mp-${p.key} res://tools/Snapshot.tscn -- --track=8 --frac=<F> --gamecam ${p.hazard}
Fracturile tale: ${p.fracs}. Iesirea: "snapshots/machu picchu_joc.png"
(SPATIU in nume — pune-l intre ghilimele). **DESCHIDE pozele si uita-te la ele**
dupa fiecare runda; salveaza-le cu nume distincte, altfel se suprascriu.

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

const MAX_RUNDE = 3

async function unPoi(p) {
  let feedback = ''
  let last = null
  const istoric = []

  for (let runda = 1; runda <= MAX_RUNDE; runda++) {
    const build = await agent(`${CONTEXT(p)}

${runda === 1 ? `RUNDA 1 a RELUARII. Decorul de dinainte e pe main; citeste sectiunea
"S-A MAI LUCRAT LA POI-UL ASTA" de mai sus si du-l mai departe de acolo.
Nu reconstrui ce merge deja, si nu porni de la zero.` :
`RUNDA ${runda}. Un critic a comparat captura ta cu bara, ORB (fara etichete),
si NU a ales-o pe a noastra. Verdictul lui, cuvant cu cuvant:

  «${feedback}»

Reparati EXACT asta. Nu reconstrui tot ce mergea; nu adauga lucruri pe care
criticul nu le-a cerut. Daca dupa ce te uiti la bara crezi ca verdictul e
gresit, ai voie sa spui asta CU DOVADA (captura + masuratoare) — un refuz
motivat e livrare valida. Dar ai voie o singura data, si trebuie sa arati
de ce.`}

Cand esti gata: fa capturile, DESCHIDE-le, si alege-o pe cea mai
reprezentativa pentru POI (nu cea mai frumoasa — cea care arata cel mai cinstit
cum se vede zona din masina). Salveaza fiecare captura cu nume DISTINCT in
${SCRATCH}/poi_${p.key}/ si da calea ABSOLUTA in "best_capture".`,
      { label: `constr:${p.key}:r${runda}`, phase: 'Constructie', schema: BUILD_SCHEMA })

    if (!build || !build.best_capture) {
      log(`POI ${p.key} runda ${runda}: constructorul n-a produs captura — opresc`)
      break
    }
    last = build

    const out = `${SCRATCH}/plansa_${p.key}_r${runda}.png`
    const seed = runda * 17 + p.key.charCodeAt(0)

    const crit = await agent(`Esti CRITIC VIZUAL pe un joc de curse arcade cu masinute de jucarie.
Judeci un singur lucru: **arata lumea noastra ca referinta?**

Ai in fata o plansa cu doua panouri, A si B. Unul e captura din jocul nostru,
celalalt e referinta. NU stii care e care, si asta e intentionat.

PLANSA se genereaza cu comanda asta, pe care o rulezi TU (nu altcineva):

  cd ${REPO}
  python tools/bar/blind_pair.py "${build.best_capture}" "${p.bar}" "${out}" --seed ${seed}

PROTOCOLUL, in ordinea asta, fara sa sari niciun pas
(docs/bara_vizuala.md, sectiunea "Judecata oarba"):
1. Ruleaza comanda. Ea tipareste o AMPRENTA si calea CHEII.
2. **DESCHIDE plansa** (fisierul ${out}) si uita-te la ea. Nu judeca din
   raportul constructorului, nu din cifre, nu din descrieri. Cu ochii.
3. Verifica in coltul din stanga-jos al plansei ca amprenta tiparita e aceeasi
   cu cea din numele fisierului-cheie. Daca nu e, plansa nu e a ta — opreste-te.
4. **ALEGE A sau B** — care panou arata mai mult ca o lume de joc coerenta,
   construita cu intentie: materie recognoscibila (piatra, iarba, vegetatie),
   silueta citibila, adancime, lumina care descrie forme.
5. ABIA ACUM citeste fisierul-cheie si afla care era care.
6. Raporteaza CINSTIT daca ai nimerit.

APOI, partea care conteaza cel mai mult: numeste **SINGURA diferenta care
conteaza** intre a noastra si referinta. Una. Cea mai importanta. Si care sa
fie **reparabila in decorul POI-ului** — nu "traseul e altfel" (traseul e
masurat si fix), nu "rezolutia difera", nu "referinta e desenata".

Contextul POI-ului, ca sa stii ce ar trebui sa se vada:
${p.vezi}

REGULI:
- **Lauda nu ajuta.** Daca a noastra e mai slaba, spune de ce, precis.
- **Dar nici incrancenarea.** Daca a noastra chiar castiga, spune asta la fel
  de limpede — miza e sa se termine, nu sa se prelungeasca.
- Nu repara nimic. Nu atinge cod. Doar judeca.`,
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

const rez = await parallel(POIS.map((p) => () => unPoi(p)))
const ok = rez.filter(Boolean).filter((r) => r.won)
log(`valul 2: ${ok.length}/3 castigate orb`)
return { rezultate: rez, castigate: ok.map((r) => r.poi) }
