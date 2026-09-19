export const meta = {
  name: 'machu-val-4',
  description: 'Valul 4 Machu Picchu: A (incinte inchise), F (raul), H (cornisa) — pe lumea cu podeaua vaii',
  phases: [
    { title: 'Constructie', detail: 'A, F, H in worktree-uri frate' },
    { title: 'Judecata oarba', detail: 'critic separat, context proaspat' },
  ],
}

const REPO = 'D:/GameDev/ignition-spike'
const GODOT = 'D:\\GameDev\\Godot_v4.7-stable_win64_console.exe'
const SCRATCH = 'C:/Users/Arion/AppData/Local/Temp/claude/d--GameDev-ignition-spike/d634728c-7e44-4549-b925-fb5babd8856d/scratchpad'

// ---------------------------------------------------------------------------
// CE S-A SCHIMBAT DE LA VALUL 3: podeaua vaii (PR #393, merge-uit).
//
// Fundul rapelor nu mai e verde gol — 4698 de piese in 59 de noduri MultiMesh,
// pe sapte din opt zone. Criticii valului 3 au judecat o lume in care orice
// privire in jos dadea o suprafata goala. Lumea de acum arata altfel din
// FIECARE punct de unde se vede in vale, deci verdictele lor despre "gol jos"
// nu se mai pot refolosi.
//
// Pentru A, F si H asta conteaza direct: toate trei au podea pe intervalul lor
// (A 55 m latime, F 44-77 m, H 22-55 m).
// ---------------------------------------------------------------------------

const POIS = [
  {
    key: 'a', zone: 'ZoneA_PiataSacra', name: 'A — Piata Sacra',
    fracs: '0.00, 0.02, 0.035', hazard: '',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_A.png',
    vezi: `campuri de ZIDURI JOASE CARE INCHID INCINTE DREPTUNGHIULARE — nu
segmente razlete; doua case cu acoperis de paie; iarba scurta aprinsa intre
ziduri, mai deschisa decat panta din jur; pavaj de lespezi; lame care pasc; un
soclu/piatra-ceas pe movila.`,
    piese: `inca_wall_a/b/c (INLANTUIBILE: capete la ±2,0 / ±3,0 / ±1,0, rost
0,0000 — de asta se pot face incinte fara rosturi vizibile), three_windows,
sun_temple, intihuatana, inca_house_a/b, guardhouse, fountain_basin,
water_channel, llama*, trail_marker.`,
    capcana: `**INCINTELE INCHISE sunt tot POI-ul.** Verdictul criticului din
valul 3 e singurul din cele sase care NU era despre teren, si e precis:

  "tot construitul din cadru e o balustrada — un singur profil de perete,
   repetat, fara colt si fara interior".

Zona are **874 de noduri** si **niciun spatiu inchis**. Deci problema nu e
cantitatea, e ca zidurile merg paralel cu drumul si nu se intorc niciodata.
Un zid care face COLT si se inchide citeste a incinta; acelasi zid intins
drept citeste a balustrada, oricate piese ai pune.

Ce a cerut criticul valului 1 pe aceeasi zona, si s-a rezolvat: terasele au
acum PODEA (platforme de iarba la cote diferite, fete de sprijin, scari).
Pastreaz-o — nu o desface ca sa faci loc incintelor.

**intihuatana e langa grila de start**, iar masinile o pot atinge: pragurile
peste 0,3 m sunt ziduri pentru fizica intreaga. ProbeLaneClear dupa fiecare
pas, nu la final.

Semi-latime **9 m** — cel mai lat punct al pistei, deci ai loc lateral, dar
grila de start trebuie sa ramana libera.`,
    istoric: `ZONA ARE DEJA 874 de noduri (terase cu podea, din valul 1 runda 2).
NU o goli. Adaugi incinte inchise si repari ce citeste a balustrada.

Podeaua vaii e acum construita si pe intervalul tau: pe stanga, 55 m latime la
frac 0.00. Daca te uiti in jos de pe platou, vezi padure, nu verde gol.`,
  },
  {
    key: 'f', zone: 'ZoneF_MalulRaului', name: 'F — Malul raului',
    fracs: '0.67, 0.69, 0.71', hazard: '--train-at=0.55',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_F.png',
    vezi: `TRENUL albastru-galben pe mal, REPEZISURI ALBE printre bolovani,
cladire mica de gara, copaci pe mal.`,
    piese: `perurail_train (DEJA cablat la fundatie, la (-160,-33,-205), nu-l
reaseza), tent_a/b, backpack_pile, bamboo_clump, moss_boulder_*, inca_house_b.`,
    capcana: `**APA. Zona are 92 de piese si NICIO apa** — criticul valului 3:
"raul lipseste cu totul din zona numita malul raului".

Si e cea mai slaba zona de pe pista, cu un istoric care te priveste direct:
constructorul valului 1 a mers **26 de runde interne** incercand sa aseze un
rau pe teren plat (cornisa n-a existat pana la integrare) si **a derivat** —
runda 9 avea rau vizibil cu bolovani si apa turcoaz, runda 26 e mai slaba, cu
apa care citeste ca pete gri cu stropi albi.

**Reia de la cea mai bine judecata stare, nu de la ultima** (memoria
revenirea-e-o-mutare-valida). Uita-te in git log la ce a fost runda 9.

Apa: memoriile apa-iluminata-v12 (**pata gri = panza opaca, lipseste
Fresnel-ul din chase cam**), strop-apa-particule (culoare sRGB nu liniar),
celula-de-apa-plana-peste-mal (sorteaza dupa aria AABB cand obiectul e mare si
plat). Spuma e FOAM_WHITE.

**Albia veche e asezata pe cotele terenului DE DINAINTE de cornisa.** Verifica
cu --survey inainte sa repari orice: piesele existente pot pluti.`,
    istoric: `ZONA ARE 92 de noduri — cea mai saraca de pe pista. Cornisa (rapa
9, 0.6611-0.7400, partea +1, podea -40) a fost adaugata la integrarea valului 1,
DUPA ce constructorul isi asezase albia.

probe_manual raporteaza pe F plutiri reale de 9-13 m (FCort74 +13,4 m,
FVers17 +12,4, FRucsacGara64 +11,7). Alea sunt defecte, nu intentie — se repara
RE-RULAND generatorul pe cotele de acum, nu mutand noduri de mana.

Podeaua vaii e construita pe intervalul tau: 44-77 m latime, 12-20 m adancime.`,
  },
  {
    key: 'h', zone: 'ZoneH_Cornisa', name: 'H — Cornisa Podului Incas',
    fracs: '0.95, 0.97, 0.99', hazard: '--bridge-at=0.24',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_H.png',
    vezi: `CORNISA PE PERETE cu PORTAL/POARTA de piatra, golul pe o parte,
zidul pe cealalta.`,
    piese: `inca_wall_*, main_gate (DEJA plantat), moss_boulder_*, rope_rail,
trail_marker, polylepis_a/b.`,
    capcana: `**Doua lucruri sunt DECISE si nu sunt ale tale.**

1. **main_gate ramane la scara 1.** E livrat cu 8,390 m la baza, iar in
   fereastra gabaritului masinii (y 0,15-1,80) golul e **8,120 m pe un drum de
   8,00** — deci brief-ul se confirma cu marja +0,12 m. Cine il "corecteaza" la
   8,0 exact PIERDE marja. Masurat cu tools/ProbeMpHGate.tscn, si verificat
   dinamic: ProbeRace seed 1/2/3 pe scena cu poarta da 0 repuneri.

2. **TERENUL PLAT DE PE DREAPTA NU E AL TAU.** Masurat azi (SvMpSapa +
   SvMpBuza): pe dreapta lui H solul e la -0,4 m la +1 m, **-0,0 la +4 m** si
   **+0,5 la +10 m** — adica URCA. Si nu atinge -3 m **nici la 60 m** dincolo
   de asfalt. Criticii valului 2 si 3 au cerut de cinci ori "golul de pe
   dreapta"; au dreptate ca lipseste, dar **nu se poate construi din zona ta**.
   Dezvoltatorul stie si decizia lui e deschisa.

   **Daca criticul tau cere iar golul din dreapta: spune-o in honest_gaps si
   NU incerca sa-l fabrici cu decor.** Un perete de piese peste teren plat
   citeste a gard, nu a prapastie. Asta a costat deja 6 runde pe pista asta.

Pe STANGA insa golul exista: prima cadere de 3 m la 11,9 m de asfalt, si
podeaua vaii e acum construita acolo (22-55 m latime). Lucreaza pe partea aia.

**Barnele podului mobil**: reuse-ul LiftBridgeHazard pune un damb de 1,6 m pe
cornisa, iar sub gol terenul ramane la -0,3 m. Verificat pe captura cu
--bridge-at=0.24: profilul citeste "rampa maro lata peste drum", nu "barne
peste gol". E teren (sapatura locala de 4 m ceruta de brief §3), deci **nu-l
masca cu decor** — pune piatra pe buzele golului, ca marginea sa aiba capete
de stanca, si spune in raport ce ramane.`,
    istoric: `ZONA ARE 299 de noduri. probe_manual gaseste pe H o plutire reala:
masaPiatra267 la **-42,4 m**. Se repara re-ruland generatorul.

Podeaua vaii e construita pe stanga ta: 22-55 m latime, 12,3 m adancime.`,
  },
]

const CONTEXT = (p) => `
Construiesti decorul POI-ului **${p.name}** al pistei Machu Picchu (Track15,
index 8) din jocul de curse cu masinute de jucarie din ${REPO}.

WORKTREE: D:/GameDev/wt-mp-${p.key}, branch feat/mp-poi-${p.key}.
Ramura exista deja si e pe main-ul de dinaintea podelei — **fa "git merge main"
la inceput**, altfel construiesti pe o lume veche.
Verifica "git branch --show-current" INAINTE de fiecare commit
(memoria merge-ul-lasa-tree-ul-pe-main). NU face NICIODATA "git stash"
(memoria git-stash-partajat-intre-sesiuni: stash-ul e COMUN intre worktree-uri,
si exista deja unul al altcuiva in repo — nu-l atinge).
Binar Godot: ${GODOT}

CITESTE INTAI (sunt scrise pentru tine, nu le sari):
- docs/track_briefs/machu_picchu_poi_gauntlet.md — contractul per POI.
- docs/track_briefs/machu_picchu_stare_poi.md — starea si ce e deschis.
- docs/track_briefs/machu_picchu_val3_constatare.md — de ce valul 3 a dat 0/6.
- docs/track_briefs/machu_picchu_podea.md — **ce s-a schimbat in lume de
  atunci**, si trei feluri in care o cifra poate minti.
- docs/asset_briefs/machu_picchu_masuratori.md — inventarul MASURAT al kitului.
- docs/decor_manual.md si docs/bara_vizuala.md (regula zero: CAPTURA BATE CIFRA).

TREI LECTII PLATITE DEJA PE PISTA ASTA, ca sa nu le repeti:

1. **Cand criticul repeta acelasi verdict de doua ori, opreste-te si verifica
   stratul de dedesubt.** Nu esti slab — ti se cere ceva ce zona ta nu poate
   produce. A costat 3 POI-uri x 3 runde la valul 1, si inca 3 x 3 la valul 2.
   Memoria: criticul-cere-ce-zona-nu-poate-da.

2. **O cifra care iese perfect din prima nu e succes, e mecanism neconectat.**
   La podeaua vaii, generatorul a raportat "5633 de piese" de trei ori la rand
   cu bug-uri diferite: positions goale (append pe o COPIE dintr-un Dictionary),
   garda care acoperea doar pilcul principal nu si satelitii, si o sonda proprie
   care citea instante MultiMesh ca (0,0,0). **De fiecare data le-a prins o
   verificare care privea REZULTATUL** (captura, ProbeRace), nu raportul.

3. **ProbeRace se ruleaza la INCEPUT, nu la final** (memoria
   proberace-la-inceput-nu-la-final). Garzile geometrice nu conduc. Si citeste
   [blocaj]/lent/invers/carusel/%offroad, nu doar "repuneri"
   (memoria zero-repuneri-ascunde-blocajul).

FUNDATIA E GATA: cele 39 de GLB-uri sunt inregistrate ca ext_resource in
Track15.tscn cu id-uri "s_<stem>", DecorManual are cele 8 zone (acum 9, cu
ZonePodeaVale), PROP_COLLISION e completat, clasa inca_stone exista.
Tu umpli **doar** DecorManual/${p.zone}. NU atinge alte zone, si **in special
nu ZonePodeaVale** — aia e podeaua vaii, tocmai merge-uita.

BARA (tinta vizuala): ${p.bar}
DESCHIDE-O si uita-te la ea inainte sa asezi ceva. Ce trebuie sa se citeasca:
${p.vezi}

REGULA CARE SE INCALCA CEL MAI DES: **bara e LOOK, nu layout.** Compari
MATERIA — piatra, iarba, vegetatia, silueta — nu unde cade fiecare obiect.
Nu redesena traseul.

PIESELE POTRIVITE: ${p.piese}

CAPCANA SPECIFICA: ${p.capcana}

${p.istoric}

CUM SE ASEAZA (tiparul deja folosit — CITESTE tools/gen_decor_mp_d.gd si
tools/gen_podea_vale.gd): generator tools/gen_decor_mp_${p.key}.gd + wrapper
.tscn. Puncte cheie:
- "--survey" INTAI: masoara terenul real pe intervalul tau si pune cifrele in
  antetul generatorului. La valul 2 asta a fost diferenta intre POI-uri care au
  livrat si POI-uri care au ars runde.
- Asezarea pe **fractie + parte + gol fata de MARGINEA drumului**, nu pe XYZ.
- Cota din **raycast pe TerrainBody-ul real**, NU din campul neted (memoria
  terrain-mesh-y-extrapoleaza), **si filtreaza dupa numele corpului lovit** —
  o raza verticala poate lovi o placa de pod sau un prop, nu solul.
- **Peste ~1000 de piese: emite MultiMesh (FlockProp), nu noduri de scena.**
  5633 de noduri individuale au facut Track15.tscn sa treaca de la 10 300 la
  32 835 de linii si Godot nu mai termina de incarcat scena in 25 de minute.
  Feliaza pe segmente de tur, altfel AABB-ul e cat harta si culling-ul moare.
  Vezi tools/gen_podea_vale.gd, functia _emit_buckets.
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
La fel probe_manual — ia **numar de scena**, deci --track=15. Sase constructori
au rulat-o cu --track=8 (adica Okinawa), au primit verde, si 528 de piese au
ramas plutind.

PRAGURI, remasurate pe main AZI (19 sep, dupa merge-ul podelei):
- probe_decor **19 materiale**, 15 992 prop-uri, 3 581 290 tri. Plafonul e
  **30** (garda pica la 38). **Plafonul NU e o alocatie de cheltuit**: un
  material nou se cere EXPLICIT in raport, cu ce cumpara vizual.
- ProbeLaneClear **17**, linia de baza 20.
- ProbeBuried **0** ingropate, 0 tavane.
- ProbeRace seed 1 da **2 repuneri** (un [blocaj] la frac 0.573 si o
  [ejectare] la 0.501), seed 2 si 3 dau **1**. **Astea sunt PREEXISTENTE** —
  verificate ruland sonda si pe main curat, cifre identice la secunda. Daca
  vezi mai mult decat atat, e al tau.
- Panta 11,5 % si raza 9,0 m — daca se misca, ai atins traseul.

CAPTURA (din masina). **Snapshot NU merge cu --headless** — randarea cere
fereastra, iar cu --headless procesul se blocheaza tacut pana la timeout, fara
sa scrie nimic si fara eroare clara (m-a costat ore azi):
  & $E --path D:/GameDev/wt-mp-${p.key} res://tools/Snapshot.tscn -- --track=8 --frac=<F> --gamecam ${p.hazard}
Fracturile tale: ${p.fracs}. Iesirea: "snapshots/machu picchu_joc.png"
(SPATIU in nume — intre ghilimele). **--out= e IGNORAT.**
**DESCHIDE pozele si uita-te la ele** dupa fiecare runda; copiaza-le cu nume
distincte in ${SCRATCH}/poi_${p.key}/.

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
    honest_gaps: { type: 'string', description: 'ce NU ai putut face din zona ta, si de ce' },
    commit_shas: { type: 'array', items: { type: 'string' } },
  },
  required: ['done', 'pieces_placed', 'best_capture', 'guards', 'what_i_built', 'honest_gaps'],
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
e masurat si fix), nu "rezolutia difera", nu "referinta e desenata", si nu
"lipseste relieful/golul" daca terenul e plat acolo (pe unele zone chiar e, si
e o decizie deschisa a dezvoltatorului, nu o omisiune a constructorului).

Contextul zonei, ca sa stii ce ar trebui sa se vada:
${vezi}

REGULI:
- **Lauda nu ajuta.** Daca a noastra e mai slaba, spune de ce, precis.
- **Dar nici incrancenarea.** Daca a noastra chiar castiga, spune asta la fel de
  limpede — miza e sa se termine, nu sa se prelungeasca.
- Nu repara nimic. Nu atinge cod. Doar judeca.`

// --- Bucla: constructor -> critic orb, pana la 3 runde ----------------------
async function poiLoop(p) {
  const runde = []
  for (let r = 1; r <= 3; r++) {
    const istoric = runde.length
      ? `\n\nRUNDE ANTERIOARE (verdictele criticului orb, context proaspat de fiecare data):\n${runde.map((x, i) => `Runda ${i + 1}: a ales ${x.chose}, a noastra ${x.ours_won ? 'A CASTIGAT' : 'a pierdut'}. Diferenta numita: ${x.the_one_difference}`).join('\n')}\n\n**Daca acelasi verdict apare a doua oara aproape neschimbat, nu mai adauga piese pe aceeasi axa** — verifica daca ti se cere ceva ce zona ta nu poate produce si scrie-o in honest_gaps.`
      : ''

    const build = await agent(
      CONTEXT(p) + istoric + `\n\nRUNDA ${r} din 3. Construieste, ruleaza garzile, capteaza, si raporteaza.`,
      { label: `build:${p.key}:r${r}`, phase: 'Constructie', schema: BUILD_SCHEMA },
    )

    if (!build?.best_capture) {
      runde.push({ chose: '-', ours_won: false, the_one_difference: 'constructorul nu a produs captura' })
      continue
    }

    const seed = 4000 + r * 17 + p.key.charCodeAt(0)
    const out = `${SCRATCH}/val4/plansa_${p.key}_r${r}_s${seed}.png`
    const crit = await agent(
      criticPrompt(build.best_capture, p.bar, out, seed, p.vezi),
      { label: `critic:${p.key}:r${r}`, phase: 'Judecata oarba', schema: CRIT_SCHEMA },
    )

    runde.push({ ...crit, build })
    if (crit?.ours_won) return { poi: p.key, castigat: true, runda: r, runde, build }
  }
  return { poi: p.key, castigat: false, runde }
}

phase('Constructie')
const rez = await parallel(POIS.map((p) => () => poiLoop(p)))

return {
  castigate: rez.filter((r) => r?.castigat).map((r) => r.poi),
  detalii: rez.map((r) => ({
    poi: r?.poi,
    castigat: r?.castigat ?? false,
    runde: (r?.runde ?? []).map((x) => ({
      ales: x.chose, a_castigat: x.ours_won, ghicit: x.guessed_right,
      diferenta: x.the_one_difference,
    })),
    piese: r?.build?.pieces_placed,
    garzi: r?.build?.guards,
    goluri_cinstite: r?.build?.honest_gaps,
  })),
}
