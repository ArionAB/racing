export const meta = {
  name: 'machu-val-1b',
  description: 'Valul 1, reluare pe terenul reparat: A, G, F — constructor + critic orb, pornind de la verdictele rundei precedente',
  phases: [
    { title: 'Constructie', detail: 'un constructor per POI, in worktree frate' },
    { title: 'Judecata oarba', detail: 'critic separat, context proaspat, planse din blind_pair' },
  ],
}

const REPO = 'D:/GameDev/ignition-spike'
const GODOT = 'D:\\GameDev\\Godot_v4.7-stable_win64_console.exe'
const SCRATCH = 'C:/Users/Arion/AppData/Local/Temp/claude/d--GameDev-ignition-spike/a127ddaa-ed44-4d8a-9e28-0290ec402731/scratchpad'

const POIS = [
  {
    key: 'a', zone: 'ZoneA_PiataSacra', name: 'A — Piata Sacra',
    fracs: '0.00, 0.02', hazard: '',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_A.png',
    vezi: `campuri de ziduri joase care INCHID INCINTE dreptunghiulare (nu segmente
razlete — asta e ce face cetatea sa citeasca drept cetate); doua case cu acoperis
de paie; iarba scurta APRINSA intre ziduri, vizibil mai deschisa decat panta din
jur; pavaj de lespezi; lame care pasc; un soclu/piatra-ceas pe movila.`,
    piese: `inca_wall_a (capete la ±2,0), inca_wall_b (±3,0), inca_wall_c (±1,0) —
se INLANTUIE cu rost 0,0000, deci incintele se construiesc din ele;
three_windows, sun_temple, intihuatana, inca_house_a/b, guardhouse,
fountain_basin, water_channel, llama/llama_b/llama_c, trail_marker.`,
    capcana: `intihuatana e langa grila si masinile o pot atinge — treptele au
varfuri partajate, iar pragurile peste 0,3 m sunt ZIDURI pentru fizica intreaga.
Semi-latimea e 9 m aici (cel mai lat punct al pistei, e respiro): nu ingusta
banda cu decor. Zidurile pietei sunt pereti CU MASA (contact = ricoseu), deci
coliziunea lor conteaza pentru gameplay, nu doar vizual.`,
    istoric: `S-A MAI LUCRAT LA POI-UL ASTA. Decorul tau de dinainte e DEJA pe
main (campul de incinte, casele, lamele) — nu-l reconstrui de la zero, il
duci mai departe.
Criticul orb l-a respins de TREI ori, si de fiecare data pe acelasi motiv, tot
mai precis. Verdictul lui final, cuvant cu cuvant:
  «Zidurile noastre nu INCHID nimic, si mai ales nu inchid un PLAN ORIZONTAL.
   In referinta fiecare traseu de zid coteste si se inchide, iar ce inchide are
   PODEA: o platforma de iarba plata, mai deschisa la culoare, asezata la ALTA
   COTA decat vecina ei, cu fata de sprijin vizibila si o scara intre niveluri.
   La noi zidurile sunt bare lungi paralele asezate una sub alta.»
Criticul rundei 2 ceruse concret: module in L si U (patru ziduri care se
intalnesc la colturi, cu o poarta de ~1,5 m intr-o latura), 6-8 incinte
distincte pe aceeasi grila, si doar 10-15% segmente razlete ca ruina.
CE S-A SCHIMBAT DE ATUNCI: nimic in terenul de la tine (A e la 0.00-0.02 si
n-are rapa). Deci PLATFORMELE la cote diferite trebuie sa vina din decor:
terase mici de teren plat inchise de ziduri, cu inca_stair_a/b intre niveluri.
Asta e sarcina rundei asteia, nu "mai multe ziduri".`,
  },
  {
    key: 'g', zone: 'ZoneG_Serpentine', name: 'G — Serpentinele Hiram Bingham',
    fracs: '0.76, 0.82, 0.88', hazard: '--bus-at=30',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_G.png',
    vezi: `DETALIUL CARE DECIDE POI-UL: fiecare ac are ZID DE SPRIJIN DE PIATRA pe
marginea EXTERIOARA. Asta face drumul sa citeasca drept taiat in versant, nu
drept poteca pe iarba. Plus quenuali cu SCOARTA ROSIE intre ace, autobuzul
galben pe un ac, peretele verde pe partea dinspre munte.`,
    piese: `polylepis_a/b (scoarta rosie = slot LARCH_RUST), inca_wall_a/b/c ca
zid de sprijin pe exteriorul acelor, moss_boulder_a/b/c, trail_marker, rope_rail.`,
    capcana: `Exportul "custom_lane_corridors (0,70, 0,909, +0,5)" tine AI-ul pe
dreapta fiindca AI-ul NU VEDE corpuri cinematice (memoria
obstacol-pe-drum-poate-fi-gimmick). Autobuzul e 3,6 m lat pe drum de 6,5 m si ia
acul LARG, pe jumatatea exterioara. Orice decor pus pe jumatatea lui ii taie
culoarul si blocheaza pista. Acele au raza >= 13 m pe axa — masurata, nu
negociabila. Ruleaza ProbeRace CU --slice=0.74,0.92: media pe tur ascunde un
hazard local.`,
    istoric: `S-A MAI LUCRAT LA POI-UL ASTA. Decorul tau de dinainte e DEJA pe
main (zidurile de sprijin, quenualii, bolovanii) — il duci mai departe.
Criticul orb l-a respins de TREI ori, de fiecare data pe ACELASI motiv:
  «Zidul de sprijin e pe partea GRESITA: la noi singura zidarie e peretele de
   pe partea dinspre munte (INTERIOR), iar marginea EXTERIOARA a acului — cea
   care cade in gol, exact cea ceruta de POI — e doar o buza de pamant brut.
   In referinta zidul e pe EXTERIOR, si suprafata drumului se termina exact PE
   capatul lui, cu golul dedesubt. Relatia aia produce cititul de "drum taiat
   in versant".»
CE S-A SCHIMBAT: **golul EXISTA acum.** Constructorul de dinainte (tu) a pus
patru scarpe verticale, cate una per ac, cu partea ALTERNANTA — indicii 5-8 din
custom_scarp_ravines, pe 0.7285-0.7885, 0.7785-0.8285, 0.8225-0.8675,
0.8665-0.9105. Masurat: terenul cade 9-14 m in primii 10 m de la ax, acolo unde
inainte era plat sau URCA.
Deci sarcina rundei asteia e exact ce cerea criticul si nu se putea: muta
zidaria pe marginea EXTERIOARA a fiecarui ac, asezata astfel incat muchia
drumului sa se termine pe ea si fata ei sa cada in scarpa. Peretele interior
ramane, dar nu el e subiectul.
ATENTIE: exteriorul ALTERNEAZA (ac 1 pe o parte, ac 2 pe cealalta) — asta e si
motivul pentru care scarpele sunt 1, -1, 1, -1. Deriva partea cu dot, nu ghici
(memoria rotatii-in-builder-semnul).`,
  },
  {
    key: 'f', zone: 'ZoneF_MalulRaului', name: 'F — Malul raului',
    fracs: '0.67, 0.70', hazard: '--train-at=0.5',
    bar: 'docs/track_briefs/img/bar_machu/bara_poi_F.png',
    vezi: `trenul albastru-galben pe mal (deja cablat, nu-l construi);
REPEZISURI ALBE printre bolovani — apa e jumatate din imagine si e ce
lipseste cel mai tare daca o ratezi; cladire mica de gara; copaci pe mal;
malul de pamant ocru.`,
    piese: `tent_a/b, backpack_pile, bamboo_clump, moss_boulder_a/b/c,
inca_house_b (gara mica), tree_fern. Trenul e deja pe pista.`,
    capcana: `APA. Shader-ul v12 de la Serengeti — memoriile apa-iluminata-v12
(pata gri = panza opaca; Fresnel din chase cam) si celula-de-apa-plana-peste-mal
(sorteaza dupa aria AABB cand obiectul e mare si plat). Spuma e FOAM_WHITE.
E cel mai jos punct al turului (-30 m): contrastul de cota fata de creasta e
tot rostul POI-ului. Apa = repunere (RespawnZone), deci unde pui apa conteaza
pentru gameplay.`,
    istoric: `S-A MAI LUCRAT LA POI-UL ASTA, si rezultatul e cel mai slab din
val — dar cauza nu era la constructor.
Ce s-a intamplat: constructorul a mers 26 de runde interne incercand sa aseze
un rau pe teren PLAT, fiindca rapa 3 se termina la 0.6611, adica exact unde
incepe malul. Raul n-avea unde sa stea. In plus a DERIVAT: runda 9 avea un rau
vizibil, cu bolovani si apa turcoaz; runda 26 e mai slaba, apa citeste ca pete
gri cu stropi albi (memoria revenirea-e-o-mutare-valida).
CE S-A SCHIMBAT: **exista acum o cornisa pe 0.6611-0.7400** (indice 9, fund
-42 m, latime 70). Terenul cade ~7 m in primii 10 m de la ax, acolo unde
inainte URCA cu 0.8 m.
Deci: NU ajusta local ce e acum in scena. Albia e asezata pe cotele terenului
VECHI, deci sta pe platou in loc de defileu — pe captura se vede apa pe malul
de sus. **Reasaza albia in cornisa noua**, si ia ca punct de plecare cea mai
bine judecata stare de dinainte (raul cu bolovani si spuma), nu ultima.
Apa: memoriile apa-iluminata-v12 (pata gri = panza opaca, lipseste Fresnel-ul
din chase cam) si strop-apa-particule (culoare sRGB, nu liniar). Spuma trebuie
sa iasa din PIETRE, adica sa aiba cauza vizibila, nu sa fie stropi pe o panza.`,
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
  & $E --headless --path D:/GameDev/wt-mp-${p.key} --script res://tools/probe_manual.gd -- --track=8
ATENTIE: probe_decor ia **--track=15** (numar de scena), restul iau **--track=8**
(index). probe_decor --track=8 masoara OKINAWA si da verde.

PRAGURI, cu cifrele de PLECARE masurate pe scena integrata (main de azi):
- ProbeRace **0 repuneri**. Masurat: 0 in 4 din 5 rulari, una a dat 1. E
  nedeterminist (memoria proberace-nedeterminism) — daca vezi 1, re-ruleaza
  inainte sa acuzi o regresie, dar daca vezi 2-3 constant, e a ta.
- probe_decor **20 materiale ACUM**, si plafonul cerut de dezvoltator e 20
  (garda pica abia la 38). **Nu mai e loc.** Daca ai nevoie de un material nou,
  spune-o explicit in raport cu motivul si cu ce cumpara — nu-l adauga in
  tacere. Prefera refolosirea claselor existente (inca_stone exista si acopera
  toata zidaria; macchia acopera verdele de padure).
- ProbeBuried **0**. ProbeLaneClear **18, baza 20** — ai marja 2, deci daca
  decorul tau intra in banda se vede imediat.
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
log(`valul 1: ${ok.length}/3 castigate orb`)
return { rezultate: rez, castigate: ok.map((r) => r.poi) }
