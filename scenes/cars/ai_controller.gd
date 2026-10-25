class_name AIController
extends CarController
## Creier AI: urmareste soseaua cu doua puncte de tintire (aproape = directie,
## departe = anticiparea virajului) si isi alege linia pe interiorul virajului.
## Foloseste ACELEASI comenzi ca jucatorul — fara viteza trisata, fara teleport
## (principiul de design nr. 5, "AI onest"): tot ce are in plus e ca nu greseste
## pedala.
##
## Doua lucruri il tin pe pista, ambele masurate cu tools/probe_race.gd:
##  · franeaza PROPORTIONAL cu cat de stramt e virajul care vine, nu binar in
##    ultima clipa (inainte: 4-13 izbituri de perete per masina per cursa);
##  · cand nu mai PROGRESEAZA, iese in marsarier VIRAT, nu drept inapoi in
##    obstacolul care l-a oprit, si dupa cateva incercari cere repunerea pe
##    pista. Fara asta o masina proptita in butucul caruselului statea acolo
##    pana la finalul cursei — marsarierul drept o punea la loc in acelasi
##    stalp, iar plasa de siguranta din race.gd nu o vedea (e proptita PE
##    sosea, iar aceea prinde doar impotmolirile din afara ei).

## Cat de departe se uita, ca fractie din viteza. Fix, cum era inainte, e gresit
## in ambele sensuri: la 30 m/s intri in viraj fara sa-l fi vazut, la 8 m/s
## tintesti dincolo de el si tai coltul.
const LOOKAHEAD_NEAR_FACTOR: float = 0.62
const LOOKAHEAD_NEAR_MIN: float = 9.0
const LOOKAHEAD_NEAR_MAX: float = 22.0
const LOOKAHEAD_FAR_FACTOR: float = 1.7
const LOOKAHEAD_FAR_MIN: float = 26.0
const LOOKAHEAD_FAR_MAX: float = 62.0

## Sub unghiul asta drumul e "drept" si se merge cu tot; peste el, viraj plin.
const CORNER_SOFT: float = 0.25
const CORNER_HARD: float = 1.10
## Cat de mult din viteza maxima ramane intr-un viraj plin.
const CORNER_SPEED_FLOOR: float = 0.44
## Cat de mult trage spre interiorul virajului (in half_width).
const INSIDE_BIAS: float = 0.55
const LINE_MAX: float = 0.8
## Cat se poate abate linia de la culoarul impus (`lane_forced_at`), in aceleasi
## unitati ca `line`: fractie din semilatime. 0.06 pe semilatimea de 9 m a
## pietei = ±0.54 m, adica jocul dintre doua masini pe aceeasi fanta.
const FORCED_SLACK: float = 0.06
## Depasire. Fara ochi pentru celelalte masini, un AI mai rapid ramanea lipit
## de bara autobuzului din fata, pe ACEEASI linie, pana la finalul cursei —
## arata prost si transforma orice masina lenta intr-un dop de pluton. Blocajul
## din fata ii muta acum LINIA (tinta laterala), nu pedalele: aceleasi comenzi
## cinstite, doar alt culoar — principiul 5, fara viteza trisata.
## Spatiu lateral intre AXELE masinilor la trecere. Cele mai late corpuri au
## ~2.1 m, deci 2.6 lasa ~jumatate de metru intre caroserii.
const AVOID_CLEARANCE_M: float = 2.6
## Fereastra de detectie in fata, ca fractie din viteza (m la m/s), cu limite.
const AVOID_WINDOW_FACTOR: float = 1.1
const AVOID_WINDOW_MIN: float = 14.0
const AVOID_WINDOW_MAX: float = 34.0
## Sub distanta asta mutarea de linie e completa; spre marginea ferestrei se
## estompeaza, ca sa nu smuceasca volanul pentru o masina aflata la 30 m.
const AVOID_FULL_M: float = 10.0
## Doar cine INCHIDE pe cel din fata are motiv sa schimbe banda...
const AVOID_MIN_CLOSING: float = 0.5
## ...cu exceptia coliziunii iminente: sub atatia metri ocolim indiferent de
## viteze, altfel doua masini cu aceeasi tinta de viteza merg bara la bara.
const AVOID_TAIL_M: float = 9.0

## Cati dintre AI iau scurtatura, cand pista are una.
##
## Nici 0%, nici 100%. La zero, bifurcatia n-ar exista pentru jucator ca decizie
## — n-ar avea cu cine sa se compare. La suta la suta, plutonul ar merge tot pe
## acolo si linia principala ar ramane goala. Cu ~40%, la fiecare tur vezi
## masini alegand diferit, ceea ce e chiar informatia de care ai nevoie ca sa
## decizi tu.
const SHORTCUT_CHANCE: float = 0.4
## Cat de mult incetineste AI-ul pe o banda uda.
const WET_SPEED_FACTOR: float = 0.78

## Anti-blocaj. Blocajul se masoara in PROGRES pe traseu, nu in viteza: o masina
## care se freaca de un obstacol cu 5 m/s nu e "in miscare", e blocata.
const PROGRESS_WINDOW: float = 2.0
const PROGRESS_MIN_M: float = 12.0
## Plasa rapida, pentru izbitura frontala care opreste masina pe loc.
const STALL_SPEED: float = 1.5
const STALL_TIME: float = 0.9
const REVERSE_TIME: float = 0.9
const RECOVER_TIME: float = 0.7
## Dupa atatea manevre esuate, cerem repunerea pe pista: mai bine 2 secunde
## pierdute decat o masina scoasa din cursa pentru totdeauna.
const MAX_ATTEMPTS: int = 3

## Usa de piatra (`SlidingHazard.Motion.USA`, Cappadocia POI F): singurul
## obstacol din joc care sta INCHIS pe banda directa cateva secunde, cu un
## ocol alaturi. Pilotul ii citeste ceasul (`door_blocks_in`) si decide ca un
## om: daca la sosire poarta va fi inchisa, ia ocolul — indiferent de
## `prefers_shortcut`, fiindca aici nu e o preferinta de linie, e zid.
##
## De ce nu ajunge `_avoid_line` sau `lane_forced_at`: prima vede doar
## masini, a doua da un culoar FIX; usa n-are culoar liber cand e inchisa,
## are doar ocolul. Acelasi motiv pentru care pasajul rotativ are `_span_line`.
##
## Raza de citire: ocolul se despica INAINTE de poarta, iar momeala
## (`Track.branch_lure`) lucreaza doar in `BRANCH_LURE_RANGE` de capul benzii,
## deci decizia trebuie luata cand usa e inca la zeci de metri. 120 m la
## ~25 m/s = ~5 s, mai putin decat orice stare a usii (deschisa 10 s, inchisa
## 6 s), deci predictia nu se poate rasuci intre decizie si sosire.
const DOOR_REACH_M: float = 120.0
## Marja pe estimarea sosirii: un pilot care franeaza pe viraj ajunge mai
## tarziu decat `along / speed`; se intreaba si „dar peste inca o secunda?".
const DOOR_ETA_SLACK: float = 1.0

## Torentul in pulsuri (Fiordland, `torrent_cycle.gd`, scurtatura Chasm): cat
## de departe (m, pe BUCLA PRINCIPALA) se citeste torentul inainte de furca —
## brief: „decizia se ia la furca, la ~80 m de perdea". 120 m la viteza
## minima realista de decizie (~11 m/s, ca la DOOR_REACH_M/AI_REACH_M) da
## ~11 s, mai mult decat un ciclu tipic de torent (14 s), deci decizia nu se
## poate rasuci intre "e liber" si "vine pulsul" chiar inainte de furca —
## acelasi motiv ca DOOR_REACH_M/TunnelSignalHazard.AI_REACH_M.
const TORRENT_REACH_M: float = 120.0
## Fractia din viteza curenta la care AI-ul presupune ca va merge, in cel mai
## rau caz, pe banda scurtaturii pana la perdea (virajele de la furca). Vezi
## `_torrent_blocks_branch`.
const TORRENT_BRANCH_SLOW: float = 0.6
## Zona (m, inainte de furca) in care linia e trasa ferm spre PARTEA OPUSA
## benzii cand torentul blocheaza — vezi `_torrent_lane_keep`.
##
## TREBUIE sa acopere `Track.BRANCH_SNAP_RANGE` (45 m): asta e raza in care
## `resolve_route` comuta ruta pe PROXIMITATE LATERALA, independent de
## steering — o zona de siguranta mai stramta decat 45 m ar lasa "gaura" intre
## unde `_torrent_lane_keep` inca nu actioneaza si unde `resolve_route` poate
## deja comuta. Bug gasit prin sonda (`probe_fiord_torent.gd`): cu 25 m aici,
## `take_branch` era corect fals (verificat cu trace direct: `blocks_in`
## prezicea SURGE corect la eta~3.7s), dar `resolve_route` comutase masina pe
## ruta 1 la ~20 m de furca — in afara zonei de 25 m, deci linia nu mai era
## trasa spre partea opusa la timp. 50 m = 45 (BRANCH_SNAP_RANGE) + 5 m marja.
const TORRENT_LANE_REACH_M: float = 50.0
## Tranzitie scurta la intrarea in zona — acelasi tipar ca SIGNAL_LANE_EASE_M.
const TORRENT_LANE_EASE_M: float = 8.0
## Cat de ferm se trage linia spre partea opusa benzii, ca fractie din
## LINE_MAX. 0.9 = aproape la limita, dar nu smucit (LINE_MAX insusi).
const TORRENT_LANE_TARGET_FRAC: float = 0.9
## Cine a ratat ocolul (a decis „deschisa" si s-a inselat, sau a fost
## imbrancit pe langa despicare) franeaza si ASTEAPTA in fata usii inchise,
## in loc sa intre in ea, sa se deblocheze in marsarier de trei ori si sa
## ceara repunere. De la distanta asta viteza-tinta coboara liniar spre zero.
const DOOR_BRAKE_M: float = 30.0
## Unde se opreste, masurat de la axa usii pana la botul masinii (raza pietrei
## 1.5 m + o lungime de masina).
const DOOR_STOP_M: float = 6.0

## Semaforul tunelului (Fiordland, brief §3 „Regula AI onest si semaforul"):
## AI-ul NU trece pe rosu — regula trebuie sa fie simpla si vizibil corecta,
## nu un profil de risc. Acelasi tipar ca usa de piatra (DOOR_*), dar fara
## ocol: singura alegere e sa astepte la linie.
##
## De ce nu se reutilizeaza direct `_door_closed_ahead`/`door_wait`: usa are
## un OCOL (banda cealalta), deci pilotul care rateaza fereastra alege intre
## „astept" si „ma duc pe alta banda" — cod care testeaza `car.route == 0` si
## cauta pe grupul usilor. Semaforul n-are banda alternativa (brief: „poarta
## cu decizie, nu cu orar" — decizia e a JUCATORULUI, AI-ul n-o are), deci
## arborele de decizie e mai simplu: gaseste cel mai apropiat semafor din
## fata, intreaba daca va fi rosu la sosire, si daca da, franeaza pana la
## linie si asteapta. Un al doilea camp (`_signal_block_m`), nu acelasi ca
## usa, ca cititorul sa vada dintr-o privire ca sunt DOUA mecanisme, nu unul
## impartit prin steaguri.
## Runda 3, punctul 2: coordonatorul a cerut sa aleg intre (a) un prag care
## scaleaza cu numarul de masini oprite in zona, sau (b) o zona de
## CONSTIENTIZARE mai lata (120 m) cu franare pe decelerarea normala a AI-ului.
## Aleg (b): e mai simplu de verificat (o singura cifra, nu un numarator live
## de masini) si mai robust — franarea proportionala de mai jos
## (`-(speed-target)/6.0`) deja scaleaza distanta de franare cu viteza, deci o
## zona mai lata inseamna doar ca AI-ul incepe sa reactioneze mai devreme, nu
## ca matematica de franare se schimba. Runda 2 folosea 40 m cu `red_hold`=18s
## (fata de 12s in runda 1) fara sa creasca — pe pista lunga (runda 3, ~2000m)
## masinile ajung la semafor cu viteza de croaziera mult mai mare (drepte
## lungi), deci 40 m insemna sub 2s de reactie la 25+ m/s. 120 m da ~5s la
## aceeasi viteza, comparabil cu DOOR_REACH_M (120m) de la usa de piatra.
const SIGNAL_BRAKE_M: float = 120.0
## Runda 2 (Fiordland): pe asfalt UD, distanta de franare declarata mai sus
## nu ajunge — e calibrata pe grip de uscat. Coordonatorul a diagnosticat
## corect: `RainCycle` uda TOT drumul (`Track.is_wet_at` intoarce true peste
## tot cat `rain_wet` e pornit), inclusiv urcarea de 7% spre linia de oprire de
## la portalul de est, iar AI-ul franeaza cu aceeasi distanta ca pe uscat si
## aluneca in coada — masurat: 11 repuneri langa semafor pe 16 seed-uri uscate
## fata de 3 pe linia de baza, si 16-33 blocaje/seed cu ploaia fortata.
## Fix: distanta de reactie se INMULTESTE cu 1.5 cand drumul de sub masina e
## ud — `track.is_wet_at(frac)` e informatie pe care un sofer o vede (asfaltul
## lucios, cauciucul care nu mai muscă), deci ramane "AI onest": nu i se da
## niciun bit despre semafor sau despre ciclul ploii, doar aceeasi citire de
## suprafata pe care o foloseste deja `route_is_wet` pentru viteza-tinta.
## Nimic altceva nu se schimba in franare — nici franarea proportionala, nici
## coada, nici pragurile semaforului insusi.
const SIGNAL_BRAKE_WET_FACTOR: float = 1.5
## Unde se opreste botul fata de linia de oprire (TunnelSignalHazard.
## ai_decision_point() e deja "linia, cu marja inapoi" — aici mai punem doar
## jumatate de lungime de masina, ca botul sa nu treaca de ea).
const SIGNAL_STOP_M: float = 2.0
## Cat de repede pleaca dupa ce prinde verde: fara isteric la volan (accelerare
## normala), dar fara nicio ezitare — franarea de mai sus il tine deja oprit
## EXACT la linie, deci "plecarea" e doar gazul normal din codul de pedale.
##
## Marja de "scurgere" a franarii: cat de mult sub linie (m) mai conteaza
## masina blocata de semafor, DACA e inca rosu. Franarea `target -> 0` e
## asimptotica, nu instanta — o masina mai are 2-4 m/s de elan exact cand
## indexul ei trece punctul de decizie. Masurat cu tools/probe_fiord_semafor.gd:
## fara marja, 2-8 treceri-pe-rosu pe 150s cu 1-2s de rosu inca ramas (nu
## coincidenta de esantionare — vezi RED_EDGE_S din sonda, care le desparte).
const SIGNAL_STOP_LEAK_M: float = 4.0
## Runda 2, punctul 3 (coada): cat spatiu se lasa fata de mașina OPRITA din
## fata, in coada de la semafor. Coordonatorul a diagnosticat corect ca
## presiunea de coada (nu franarea proprie) era sursa scurgerii peste linie
## masurate mai sus — cu 8 masini pe o banda de 7 m, fara nicio notiune de
## "cine e in fata mea si s-a oprit", fiecare AI tintea DOAR linia, iar
## mașina din spate (care nu vede coada, doar linia) intra in cea din fata.
const SIGNAL_QUEUE_GAP_M: float = 5.0
## Sub cat de mare viteza se considera o masina "oprita" pentru scopul cozii
## (nu 0 exact — fizica tremura langa zero).
const SIGNAL_QUEUE_STOPPED_SPEED: float = 1.0

## Reproiectare (banda de autocar, brief `docs/track_briefs/fiordland.md` §3
## „optiunea 0", 22 sep 2026): dupa 4 runde esuate cu OPRIREA completa a unei
## flote de 8 AI la o singura banda (coada se scurgea peste linie, 11 treceri
## pe rosu pe 16 seed-uri — vezi istoricul in TunnelSignalHazard), gimmick-ul
## devine banda de autocar FARA oprire. `TunnelSignalHazard.mode == LANE`
## (implicit) inlocuieste TOT blocul SIGNAL_BRAKE_M/SIGNAL_STOP_M/coada de mai
## sus cu o singura regula: cat lampa e rosie ("autocar in tunel sau intra in
## <= clear_hold s"), AI-ul tine banda DREAPTA in zona tunelului — nu franeaza,
## nu se opreste, nu face coada. `mode == STOP` (vechi) ramane pe codul de mai
## sus, nefolosit pe pistele noi, pastrat pentru sonde de regresie.
##
## De ce nu se reutilizeaza `_fireball_line`/`_span_line` direct: ambele
## intorc un OFSET FIX derivat din geometria hazardului lor (gura gheizerului,
## poarta rotativa); aici tinta e o BANDA (jumatate de sosea), nu un punct, iar
## decizia depinde de `is_red()`, nu de o faza calculata local — mai simplu sa
## se scrie separat decat sa se generalizeze tiparul pentru un singur hazard.
##
## Zona in care se aplica REGULA: de la SIGNAL_LANE_REACH_M inainte de linia
## de oprire (portalul de est) pana la capatul tunelului (portalul de vest,
## `tunnel_length` mai departe) — brief: „de la AI_REACH_M inainte de
## portalul de est pana la portalul de vest".
##
## NU se foloseste `TunnelSignalHazard.AI_REACH_M` (130 m) direct — mult mai
## mare aici, dupa masuratori repetate cu sonda pe Track16 (tunelul e UD
## permanent, `custom_wet_ranges` — grip lateral redus, acelasi motiv pentru
## care franarea veche avea SIGNAL_BRAKE_WET_FACTOR): la 130 m, si chiar la
## 250 m, o masina care intra in zona aproape de axa nu reuseste sa convearga
## fizic la tinta pana la portalul de vest — masurat, acelasi seed, run
## repetat: uneori converge curat (Kai: -2.0 -> +3.0 in 40 m), alteori ramane
## „lipita" de axa (-0.1..+0.3 m) pe zeci de metri, cu semnul comandat corect
## (`line_out`) dar pozitia REALA neschimbata — semn de grip limitat pe
## asfaltul ud, nu de logica gresita (ProbeRace documenteaza chiar el
## nedeterminismul fizicii intre rulari identice). Zona larga (350 m,
## aproape 1/6 din pista) da orice masina destul drum sa convearga chiar si
## in cel mai lent caz observat.
const SIGNAL_LANE_REACH_M: float = 350.0
## Cat de aproape de intrarea in zona se face tranzitia liniei (m): scurt
## dinadins — regula trebuie sa fie STRICTA (veto „AI onest": 0 masini pe
## banda stanga pe rosu), nu o preferinta care se instaleaza incet pe toata
## zona. O tranzitie prea lunga ar lasa AI-ul in banda gresita chiar la
## intrarea in tunel daca rosul apare chiar cand masina trece de punctul de
## decizie.
const SIGNAL_LANE_EASE_M: float = 12.0
## Centrul benzii DREPTE (m fata de axa, semn ca `side_at`: pozitiv = dreapta
## sensului de mers).
##
## Runda 3 (geometrie, coordonator): tunelul a crescut la semilatime 4.5
## (9 m). Citirea corecta a rundei 2 — masurat, regula de banda era ACTIVA
## in 100% din ejectari si vitezele (42-59 m/s) sunt de coliziune bruta, nu
## de sincronizare: cu autocarul (3.6 m) la -2.0 si masina (2.2 m) la +1.5
## pe un tunel de 8 m, marginile lor erau la doar 0.6 m distanta — orice
## clatinare pe asfalt ud (custom_wet_ranges) insemna contact cu un corp
## CINEMATIC (masa infinita, memoria `corp-cinematic-aparut-in-masina`):
## depenetrare violenta, nu o eroare de linie. Fixul e marja, nu regula.
## +2.0 acum (ocupa +0.9..+3.1 cu semilatimea masinii ~1.1 m) fata de
## autocarul la -2.4 (ocupa -3.9..-0.9): 1.8 m intre ele, de trei ori
## marja veche (0.6 m).
const SIGNAL_RIGHT_LANE_M: float = 2.0

var track: Track
## Linia "de personalitate" a pilotului: fiecare are alt culoar preferat pe
## portiunile drepte. Peste ea se adauga tragerea spre interiorul virajului.
var line_offset: float = 0.0
## Toate masinile din cursa (referinta partajata la lista din race.gd), ca
## pilotul sa vada cine ii sta in fata. Goala in sondele care nu o dau — atunci
## depasirea pur si simplu nu se activeaza.
var traffic: Array[Car] = []

var _steer: float = 0.0
var _throttle: float = 1.0
var _drift: bool = false
var _turbo: bool = false

var _stall_time: float = 0.0
var _last_index: int = -1
## Ruta pe care se stia masina la ultima masuratoare de progres.
var _last_route: int = 0
## Ia sau nu scurtatura, decis o data pe cursa.
##
## Nu toti o iau, si asta e chiar poanta: principiul 5 din CLAUDE.md cere AI
## ONEST — variatie prin LINII diferite, nu prin viteza trisata. O bifurcatie
## pe care jumatate din pluton o alege altfel produce depasiri reale, fara sa
## dea nimanui un avantaj artificial.
var prefers_shortcut: bool = false
var _progress_m: float = 0.0
var _progress_timer: float = 0.0
## Metri pana la o usa de piatra care VA FI inchisa cand ajungem la ea, pe
## banda pe care suntem. INF = nicio usa in fata (sau usa deschisa la sosire).
var _door_block_m: float = INF
## Indexul de traseu al fiecarei usi, pe ruta 0 — scanare completa o data,
## nu per cadru (cheie: instance id).
var _door_index: Dictionary = {}
## Indexul pe BUCLA PRINCIPALA al furcii fiecarui torent (cheie: instance
## id) — scanare completa o data, ca la usi/semafoare.
var _torrent_index: Dictionary = {}
## Semnul lateral (fata de axa buclei principale, la furca) pe care se
## departeaza banda torentului — vezi `_torrent_lane_keep`. Cheie: instance
## id, calculat o data (geometria furcii nu se schimba in timpul cursei).
var _torrent_side_sign: Dictionary = {}
## Metri pana la semaforul din fata care VA FI rosu cand ajungem la linia de
## oprire. INF = niciunul in raza de decizie, sau va fi verde la sosire.
var _signal_block_m: float = INF
## Indexul de traseu al fiecarui semafor gasit (ca la usi: scanat o data per
## instanta, cheie = instance id).
var _signal_index: Dictionary = {}
## Doar pentru sonde: `false` = AI-ul ignora tubul (garda trebuie sa prinda
## contacte cu el — altfel nu e armata).
var reads_shishi: bool = true
## Per tub (cheie: instance id): indexul de pista, semnul lateral al pivotului,
## angajamentul pe banda exterioara si cat de instalata e linia (0..1).
var _shishi_index: Dictionary = {}
var _shishi_sign: Dictionary = {}
var _shishi_latched: Dictionary = {}
var _shishi_blend: Dictionary = {}
## Doar pentru sonde: `false` = AI-ul ignora daruma-otoshi (garda trebuie sa prinda
## contacte cu discul — altfel nu e armata).
var reads_daruma: bool = true
## La fel pentru carul de festival (`gion_matsuri_hazard.gd`): `false` = AI-ul il ignora
## (garda trebuie sa prinda contacte cu el). Citeste prin aceeasi cale ca daruma.
var reads_gion: bool = true
## Per daruma (cheie: instance id): indexul de pista si decizia luata la intrarea in
## raza — {lift: bool, clear_at: float (ceas propriu, s)}.
var _daruma_index: Dictionary = {}
var _daruma_state: Dictionary = {}
var _daruma_now: float = 0.0
## Doar pentru sonde: `false` = AI-ul ignora leul shishimai (garda trebuie sa prinda
## contacte cu el — altfel nu e armata).
var reads_shishimai: bool = true
## Per leu (cheie: instance id): indexul de pista, semnul lateral al lui +X local fata
## de dreapta soselei, banda aleasa (m, + = dreapta), cat de instalata e (0..1) si
## timpul pana la urmatoarea re-evaluare (s).
var _shishimai_index: Dictionary = {}
var _shishimai_sign: Dictionary = {}
var _shishimai_lane: Dictionary = {}
var _shishimai_blend: Dictionary = {}
var _shishimai_timer: Dictionary = {}
var _unstick_timer: float = 0.0
var _unstick_reversing: bool = false
var _unstick_steer: float = 0.0
var _attempts: int = 0
## Masina pe care o ocolim acum si partea aleasa (-1 stanga, +1 dreapta).
## Tinem minte ALEGEREA per blocaj: fara histereza, un autobuz pe axa ar face
## urmaritorul sa penduleze stanga-dreapta la fiecare centimetru de deriva.
var _avoid_car: Car = null
var _avoid_side: float = 0.0
## Perechea de gheizere pe care o traversam acum si culoarul ales pentru ea.
##
## Se tine minte din acelasi motiv ca `_avoid_car`: fara angajament, pilotul
## pendula. Masurat pe ProbeRace, doua cadre consecutive cereau side=-1 si
## side=+1 (perechea cea mai apropiata se schimba, si fiecare are alta faza),
## deci masina smucea stanga-dreapta in loc sa treaca prin culoarul liber.
var _fb_pair: Node = null
var _fb_side: float = 0.0
## Pasajul rotativ pe care suntem angajati acum, si pe ce parte l-am luat.
## Se tine minte din acelasi motiv ca `_fb_pair`: raspunsul „deschis / inchis"
## chiar se schimba sub masina (rotatia tine 4 s), iar un culoar ales si tinut
## bate unul recalculat impecabil in fiecare cadru si niciodata urmat.
var _span_node: Node = null
var _span_side: float = 0.0

## Muchia fara parapet (`Track.ai_drop_edges`, fantana din Jodhpur): limitele
## liniei pe cadrul curent, in aceleasi fractii ca `line`. In afara unei
## muchii declarate sunt exact ±LINE_MAX, deci tot ce le citeste (inclusiv
## `_avoid_line`) face ce facea inainte — bit cu bit, pe orice alta pista.
var _line_lo: float = -LINE_MAX
var _line_hi: float = LINE_MAX
## Latura muchiei (-1 stanga, +1 dreapta, 0 = nicio muchie aici).
var _drop_side: float = 0.0
## Cat de departe in fata/spate (m, pe directia masinii) e „alaturi" pentru
## regula de a nu inchide usa (`_drop_alongside`): o lungime de caroserie si
## ceva — cine e la 8 m in fata se ocoleste cu `_avoid_line`, nu se striveste.
const DROP_ALONGSIDE_M: float = 6.5
## Cat din viteza-tinta ramane intr-un viraj plin cu muchia pe EXTERIOR.
const DROP_OUTSIDE_SPEED: float = 0.8
## Marginea (m, de la marginea asfaltului la axa masinii) pe partea OPUSA
## muchiei, in zona declarata: o caroserie si ceva.
const DROP_FAR_MARGIN_M: float = 1.4

func configure(race_track: Track, rng: RandomNumberGenerator,
		cars: Array[Car] = []) -> void:
	track = race_track
	traffic = cars
	line_offset = rng.randf_range(-0.28, 0.28)
	var chance := SHORTCUT_CHANCE
	if race_track != null and race_track.ai_shortcut_chance >= 0.0:
		chance = race_track.ai_shortcut_chance
	prefers_shortcut = rng.randf() < chance

func update(delta: float) -> void:
	if track == null or car == null:
		return
	var speed := car.horizontal_speed()
	_watch_progress(delta, speed)
	if _unstick_timer > 0.0:
		_drive_unstick(delta)
		return

	# --- unde merge drumul ---
	var idx := car.road_index
	var far := track.lookahead_point(idx, _lookahead_far(speed), 0.0, car.route)
	var fwd := -car.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	# unghi cu semn fata de UP: pozitiv = tinta e la stanga = steer pozitiv
	var a_far := _angle_to(fwd, far)
	# 0 pe drept, 1 in virajul cel mai stramt.
	var severity := clampf(
		(absf(a_far) - CORNER_SOFT) / (CORNER_HARD - CORNER_SOFT), 0.0, 1.0)

	# --- linia: pe interiorul virajului care vine ---
	# _side_at (deci si lateral_frac) e pozitiv spre DREAPTA soselei, iar un
	# a_far pozitiv inseamna viraj la stanga: interiorul e in sens invers.
	var line := clampf(line_offset - signf(a_far) * severity * INSIDE_BIAS,
		-LINE_MAX, LINE_MAX)
	# Muchie fara parapet (apa fantanii, Jodhpur): linia nu mai merge cu roata
	# pe buza. No-op cand pista nu declara nimic aici (limitele raman ±LINE_MAX).
	_drop_limits(idx, speed)
	line = clampf(line, _line_lo, _line_hi)
	# Sector cu hazard PE AXA (trenul pe sens de pe Baikal): pilotul se tine
	# de margine, pe partea lui de personalitate. Zero peste tot in rest.
	var keep_off := track.lane_bias_at(idx)
	if keep_off > 0.0:
		var side_pref := signf(line_offset) if absf(line_offset) > 0.02 else 1.0
		line = side_pref * maxf(absf(line), keep_off)
	# Blocaj de decor cu o SINGURA fanta (piata din Goreme, Cappadocia POI A):
	# un zid continuu de oale de la -9.0 la +5.6, cu trecerea doar in dreapta.
	#
	# De ce nu se rezolva din `_avoid_line`: aia se uita NUMAI la `traffic`,
	# adica la celelalte masini. Decorul static nu exista pentru ea, deci
	# pilotul isi urma linia de curse drept in zid, tur de tur — 25 de repuneri
	# pe 3 seed-uri, masurat. Si nici `lane_bias_at` nu ajunge: aia da o
	# MARIME si lasa malul pe seama personalitatii, ceea ce e corect pentru
	# trenul de pe Baikal (liber pe amandoua partile) si gresit aici, unde
	# malul ales gresit e zid.
	#
	# Se citeste aici, dar se IMPUNE dupa `_avoid_line` (vezi mai jos): altfel
	# ocolirea unei masini lente muta linia inapoi in zid. Masurat: cu impunerea
	# doar inainte, seed 4 tinea o masina intr-o bucla de 14 repuneri, lovind
	# teancurile la lat 3.1-3.7 m — adica taman unde o dusese ocolirea.
	var forced := track.lane_forced_at(idx)
	if absf(forced) > 0.001:
		line = clampf(forced, -LINE_MAX, LINE_MAX)
	# Gheizerele de foc din craterul Stromboli: culoarul liber se SCHIMBA in
	# timp, deci nu se poate rezolva cu `lane_bias_at` (aia tine pilotul pe o
	# parte FIXA, bun pentru un tren pe axa, inutil aici).
	#
	# Fara asta pilotii intrau direct in coloane. Masurat cu ProbeRace pe felia
	# craterului (0.45-0.50), A/B in acelasi worktree cu gheizerele stinse:
	#   stinse:  21.1 m/s,  0 pereti,  3 repuneri
	#   aprinse: 10.2 m/s, 33 pereti, 53 repuneri, nimeni peste 0.5 tururi
	# Adica exact esecul caruselului: un hazard pe care AI-ul nu-l poate citi
	# devine ambuteiaj. Cu linia de mai jos + gurile departate: 2 pereti, 14
	# repuneri, masini care termina tururi.
	line = _fireball_line(speed, line)
	# Pasajul rotativ (Chongqing, brief §2 POI F): la fel ca gheizerele, culoarul
	# liber se schimba IN TIMP — deschis se trece pe axa, inchis pe rampa de
	# serviciu — deci nici aici `lane_bias_at` nu ajuta (aia tine pilotul pe o
	# parte fixa). Vezi `RotatingSpanHazard.ai_safe_side`.
	line = _span_line(speed, line)
	# Cineva mai lent pe culoarul nostru? Linia se muta pe langa el.
	line = _avoid_line(idx, speed, line, keep_off)
	# Banda de autocar (Fiordland, brief §3 „optiunea 0"): pe rosu, in zona
	# tunelului, banda dreapta e IMPUSA — vine dupa ocolirea de trafic
	# (`_avoid_line`) fiindca e regula de siguranta cu veto, nu o preferinta
	# de linie; o masina care tocmai a inceput sa ocoleasca pe stanga in zona
	# trebuie trasa inapoi pe dreapta, nu invers.
	line = _signal_lane_keep(idx, speed, line)
	# Torentul in pulsuri (Fiordland, scurtatura Chasm): cand blocheaza,
	# linia e trasa ferm spre partea OPUSA benzii chiar la furca — plasa de
	# siguranta impotriva comutarii pe proximitate a lui `Track.resolve_route`
	# (vezi antetul `_torrent_lane_keep`). Vine dupa `_avoid_line`, ca ocolirea
	# unei masini din trafic sa nu impinga linia inapoi spre banda.
	line = _torrent_lane_keep(idx, speed, line)
	# Shishi-odoshi (Kyoto): tubul care bate peste interiorul drumului. NU se
	# franeaza pentru el — doar trece pe banda exterioara (vezi `_shishi_line`).
	line = _shishi_line(idx, speed, line)
	# Shishimai (Kyoto, POI H): leul danseaza lateral peste sosea, dar nu o inchide —
	# ramane mereu un culoar. NU se franeaza: se alege banda libera pe fereastra de
	# sosire (vezi `_shishimai_line`).
	line = _shishimai_line(idx, speed, line)
	# CULOARUL UNIC are ultimul cuvant. Pe restul pistei ocolirea poate folosi
	# toata latimea; intr-un blocaj cu o singura fanta, orice metru in afara
	# fantei e zid, deci linia se strange inapoi in ea. Fereastra e ingusta
	# (+5.75..+7.00 m masurat la 0.0297), asa ca se lasa doar o toleranta mica
	# in jurul culoarului — destul cat doua masini sa nu se atinga, prea putin
	# cat sa iasa vreuna din fanta.
	if absf(forced) > 0.001:
		var lo := forced - FORCED_SLACK
		var hi := forced + FORCED_SLACK
		line = clampf(line, minf(lo, hi), maxf(lo, hi))
		line = clampf(line, -LINE_MAX, LINE_MAX)
	line = _alley_gate_line(idx, line)
	# Muchia fara parapet are ultimul cuvant, dupa ocolire: nici depasirea nu
	# trece pe buza, nici nu inchide usa celui de langa noi spre apa.
	if _drop_side != 0.0:
		line = _drop_alongside(idx, line)
	var near := track.lookahead_point(idx, _lookahead_near(speed), line, car.route)
	# Bifurcatia: cine a decis ca o ia, tinteste banda cealalta cat timp cele
	# doua sunt inca lipite. Comutarea propriu-zisa de ruta o face Car, pe
	# proximitate laterala — aici doar ne mutam acolo la timp.
	# `prefers_shortcut` se trage o data pe cursa, dar o scurtatura poate fi
	# INCHISA la un moment dat (limba de lava de pe Stromboli, care creste tur
	# de tur). De-asta se intreaba pista de fiecare data, nu doar la start:
	# fara asta, un AI care a decis la turul 1 "o iau pe scurta" intra in zid
	# la turul 3.
	_door_block_m = _door_closed_ahead(speed)
	# Semaforul tunelului: se citeste INDEPENDENT de usa de piatra (nu e o
	# ramura a aceleiasi decizii — sunt doua mecanisme, brief-uri diferite),
	# dar cu ACELASI tipar: distanta pana la linie, sau INF daca drumul e
	# liber la sosire.
	_signal_block_m = _signal_red_ahead(speed)
	var take_branch := prefers_shortcut and car.route == 0 and track.branch_is_open(1) \
		and not _torrent_blocks_branch(speed)
	# Usa de piatra inchisa la sosire: ocolul nu mai e o preferinta, e singurul
	# drum. Vezi DOOR_REACH_M.
	if car.route == 0 and _door_block_m < INF:
		take_branch = true
	_alley_approach = false
	if take_branch:
		var lure := track.branch_lure(car.global_position, _lookahead_near(speed), idx)
		if lure != Vector3.INF:
			near = lure
			# Momit spre o banda cu poarta ingustata: de la capul benzii,
			# tinta e pe axa portii si viteza se plafoneaza (vezi mai jos).
			if track.branch_gate(1) != null:
				var br := track.route_at(1)
				var bi := br.closest_index_global(car.global_position)
				near = _alley_gate_aim_on(1, bi, near)
				if br.dists[bi] <= float(track.branch_gate(1).gate_dist_m):
					_alley_approach = true
	if car.route != 0:
		near = _alley_gate_aim_on(car.route, idx, near)
	_steer = clampf(_angle_to(fwd, near) * 2.2, -1.0, 1.0)

	# --- pedale: viteza-tinta din cat de stramt e ce urmeaza ---
	var target := car.max_speed * lerpf(1.0, CORNER_SPEED_FLOOR, severity)
	# Muchie fara parapet pe EXTERIORUL virajului (iesirea din virajul de
	# intrare in fantana, apa pe stanga unui viraj la dreapta): iesirea larga
	# duce spre apa, deci pilotul intra mai incet. Fals peste tot unde nu e
	# declarata o muchie (`_drop_side` = 0).
	if _drop_side != 0.0 and signf(a_far) == _drop_side:
		target *= lerpf(1.0, DROP_OUTSIDE_SPEED, severity)
	# Poarta ingustata a ulicioarei: de la desprinderea benzii pana dupa
	# poarta, cu plafon de viteza — ca sa aiba timp sa se aseze pe axa.
	if _alley_approach:
		target = minf(target, ALLEY_GATE_SPEED)
	# Coloana la poarta ingustata: cine e in spate urmareste masina din fata
	# pe fereastra portii, nu intra peste ea in gol. Vezi ALLEY_FOLLOW_*.
	var gate_follow := _alley_gate_follow(idx)
	_gate_hold = gate_follow < 1.0
	if gate_follow < INF:
		target = minf(target, gate_follow)
	# Pe banda uda ridica piciorul, ca un sofer.
	#
	# Fara asta AI-ul intra pe bancul de nisip cu viteza de asfalt, aluneca si
	# iese in apa: masurat, 27% din timp in afara soselei si tururile scadeau de
	# la 2.5 la 1.6. Nu era o problema de fizica — grip-ul taiat isi facea exact
	# treaba — ci de sofer care nu se uita la suprafata.
	if track.route_is_wet(car.route):
		target *= WET_SPEED_FACTOR
	# Usa inchisa in fata, fara ocol la indemana: opreste si asteapta sa se
	# deschida. Vezi DOOR_BRAKE_M.
	var door_wait := _door_block_m < DOOR_BRAKE_M
	# Rosu la sosire: franeaza si opreste EXACT la linie — brief §3, "AI
	# onest si semaforul": niciun AI nu trece pe rosu, indiferent de cat de
	# mult ar castiga jucatorul trecand. Vezi SIGNAL_BRAKE_M/SIGNAL_STOP_M.
	#
	# Runda 2 (Fiordland): pe ud, fereastra de reactie se largeste cu
	# SIGNAL_BRAKE_WET_FACTOR — vezi comentariul de la constanta. Se citeste
	# UD la pozitia CURENTA a masinii (`idx`), nu la linia de oprire: un sofer
	# simte asfaltul de sub el acum, nu ghiceste starea de la 100 m in fata.
	var signal_brake_m := SIGNAL_BRAKE_M
	if track.is_wet_at(track.frac_at(idx, car.route)):
		signal_brake_m *= SIGNAL_BRAKE_WET_FACTOR
	var signal_wait := _signal_block_m < signal_brake_m
	if signal_wait:
		var stop_m := maxf(_signal_block_m - SIGNAL_STOP_M, 0.0)
		# Runda 2, punctul 3: coada. Fara asta fiecare AI tintea DOAR linia —
		# cel din spate accelera spre linie exact cand cel din fata era deja
		# oprit langa ea, si-l impingea peste ea (diagnosticul coordonatorului
		# pentru cele 43-72 contacte/150s masurate initial).
		stop_m = minf(stop_m, _signal_queue_gap(idx))
		target = minf(target, stop_m * 1.2)
	if door_wait:
		target = minf(target, maxf(_door_block_m - DOOR_STOP_M, 0.0) * 1.2)
	# Daruma-otoshi (Kyoto): discul traverseaza TOATA soseaua, deci nu exista banda
	# libera — se scapa prin timing. Ridic piciorul ca sa trec DUPA disc (niciodata
	# pana la oprire: plafonul are podea), sau trec inainte de lovitura.
	target = minf(target, _daruma_cap(idx, speed))
	# Zid de praf (Monument Valley, HaboobHazard): in miezul lui un sofer prudent
	# ridica piciorul cu ~10%. Fara viteza trisata si fara vedere speciala — vezi
	# `speed_zone_scale`.
	var zone_scale := speed_zone_scale()
	target *= zone_scale
	# In zona de prudenta banda de toleranta de 6% dispare: viteza reala a masinilor
	# sta sub `max_speed` (drag), deci cu banda tinta redusa cu 10% nu ar fi
	# frant niciodata (masurat pe ProbeHaboob: -2,6% fata de -10% cerut).
	var brake_band := 1.0 if zone_scale < 0.999 else 1.06
	if speed > target * brake_band:
		# Franare proportionala cu depasirea, nu o smucitura fixa.
		_throttle = clampf(-(speed - target) / 6.0, -1.0, -0.15)
	else:
		_throttle = 1.0
	# Oprit in fata usii: nici gaz, nici marsarier. Fara ramura asta, tinta
	# zero ar da `_throttle = -0.15` la nesfarsit si masina ar da inapoi pana
	# in pluton.
	if door_wait and target < 1.0 and speed < 2.0:
		_throttle = 0.0
	# Oprit in spatele celui blocat in poarta ingustata: la fel.
	if _gate_hold and speed < 2.0:
		_throttle = 0.0
	# Oprit la linia de oprire: nici gaz, nici marsarier, exact ca la usa —
	# altfel tinta zero ar franeaza la nesfarsit spre spate in pluton.
	if signal_wait and target < 1.0 and speed < 2.0:
		_throttle = 0.0

	# --- drift (handbrake) pe viraje sustinute: si vireaza, si umple bara ---
	# Eliberat si cand pilotul CONTRAVOLANEAZA: cu maparea CTR (oct 2026),
	# volanul in sens opus nu mai intoarce masina in drift, doar largeste
	# alunecarea — deci corectia spre exterior nu vine pana nu lasi frana de
	# mana. Exact ce face un om: prinde spatele eliberand butonul. Fara regula
	# asta pilotul statea cu frana trasa si contravolan plin si iesea pe iarba
	# (ProbeRace Track0: offroad 6-13% fata de 0-1% pe main).
	if not _drift:
		if severity > 0.34 and speed > car.drift_min_speed * 1.2:
			_drift = true
	elif severity < 0.12 or speed < car.drift_min_speed * 0.7 			or (car.is_drifting and _steer * car.drift_dir < -0.15):
		_drift = false

	# --- turbo: pe drept, si oprit inainte de viraj, ca sa nu-l irosim in perete
	if not _turbo:
		if car.turbo_charge > 0.6 and severity <= 0.0 and _throttle > 0.0:
			_turbo = true
	elif car.turbo_charge < 0.05 or severity > 0.25:
		_turbo = false
	# Un sofer prudent in zid nu arde turbo: altfel tinta redusa nu s-ar vedea in
	# viteza reala (turbo-ul depaseste plafonul).
	if zone_scale < 0.999:
		_turbo = false

# --------------------------------------------------------------- depasirea

## Muta linia tinta pe langa cea mai apropiata masina care ne blocheaza
## culoarul. Intoarce linia nemodificata cand drumul e liber.
##
## Decizia se ia mereu fata de linia de BAZA (personalitate + interiorul
## virajului), nu fata de cea deja mutata: baza nu se schimba in timpul
## depasirii, deci nici verdictul "imi sta in drum / nu-mi sta" — fara asta,
## prima mutare reusita ar curata blocajul din propriul test si linia ar
## pendula intre cele doua raspunsuri la 60 Hz.
## Muta linia pe culoarul pe care gheizerul va fi JOS cand ajungem noi acolo.
##
## Intreaba perechea cea mai apropiata din fata cu `ahead` = timpul nostru de
## sosire, nu cu „acum": la 25 m/s, o pereche la 30 m se schimba de doua ori
## pana ajungem. Raspunsul e despre momentul sosirii.
##
## Se aplica doar in raza de decizie a perechii (`AI_REACH_M`) si doar cat timp
## e IN FATA — dupa ce am trecut de ea, linia se intoarce la ce cerea virajul.
func _fireball_line(speed: float, line: float) -> float:
	var geysers := get_tree().get_nodes_in_group(FireballGeyser.AI_GROUP)
	if geysers.is_empty():
		return line
	# Distanta se masoara PE AXA DRUMULUI, nu pe directia botului.
	#
	# Prima versiune folosea `to.dot(-basis.z)` si rata perechile: craterul e o
	# bucla, deci o pereche la 30 m de drum sta mult in lateral fata de unde
	# priveste masina, iar proiectia iesea mica. Masurat pe ProbeRace, pilotul
	# „vedea" gheizerul abia de la 0.2-9.4 m — prea tarziu ca sa mai schimbe
	# culoarul. Pe indici de traseu, 30 m de drum inseamna 30 m de drum si in
	# viraj.
	var n_pts: int = track.route_at(car.route).count()
	var my_idx: int = car.road_index
	var bake: float = track.curve.bake_interval
	var best: FireballGeyser = null
	var best_d := INF
	for node in geysers:
		var g := node as FireballGeyser
		if g == null:
			continue
		var g_idx: int = track.closest_index_global(g.global_position, car.route)
		var d_idx := g_idx - my_idx
		if d_idx < -n_pts / 2:
			d_idx += n_pts
		elif d_idx > n_pts / 2:
			d_idx -= n_pts
		var along := float(d_idx) * bake
		# Doar ce e in FATA si in raza de decizie.
		if along < 0.0 or along > FireballGeyser.AI_REACH_M:
			continue
		if along < best_d:
			best_d = along
			best = g
	if best == null:
		_fb_pair = null
		return line
	# Timpul pana ajungem. Cu viteza mica, plafonat: la 2 m/s „sosirea" ar fi
	# peste 15 s si raspunsul ar fi despre alt ciclu.
	var ahead := clampf(best_d / maxf(speed, 6.0), 0.0, 6.0)
	var side := 0.0
	if _fb_pair == best and absf(_fb_side) > 0.01:
		# Deja angajati pe perechea asta: TINEM culoarul ales.
		#
		# Reevaluarea in fiecare cadru era exact bug-ul: la 25 m/s masina
		# strabate raza de decizie in ~1.4 s, adica o treime de ciclu, deci
		# raspunsul „corect" chiar se schimba sub ea. Un culoar ales tarziu si
		# tinut bate unul recalculat impecabil si niciodata urmat.
		side = _fb_side
	else:
		side = best.safe_side(ahead)
		_fb_pair = best
		_fb_side = side
	if absf(side) < 0.01:
		return line
	# Cat de lateral: se DERIVA din geometria perechii, nu se alege (vezi
	# `FireballGeyser.ai_line_offset` — culoarul liber tine de la marginea
	# drumului pana la buza zonei de impact, iar masina sta la mijlocul lui).
	var target := clampf(side * best.ai_line_offset(), -LINE_MAX, LINE_MAX)
	# MUTARE PROGRESIVA, ca la `_avoid_line`: aproape = mutare completa, departe
	# = abia schitata.
	#
	# Prima versiune intorcea `target` direct si a fost masurata ca fiind mai rea
	# decat nimic: la 30 m de gheizer pilotul smucea volanul dintr-o data, iesea
	# de pe sosea si se bloca INAINTE sa ajunga la crater (lat 0.6 m -> 5.8 m ->
	# 12.2 m in trei zecimi de secunda). Numarul lateral era corect; saltul spre
	# el nu.
	var t := clampf(1.0 - best_d / FireballGeyser.AI_REACH_M, 0.0, 1.0)
	return lerpf(line, target, t)



## Muta linia pe culoarul pe care pasajul rotativ va fi TRECABIL cand ajungem
## noi acolo: pe axa cat e deschis, pe rampa de serviciu cat e inchis.
##
## Aceeasi forma ca `_fireball_line`, si din acelasi motiv (vezi
## `RotatingSpanHazard.ai_safe_side` pentru ce s-a masurat fara ea): distanta pe
## AXA DRUMULUI, nu pe directia botului, fiindca nodul e pe o spirala si o
## proiectie pe bot ar raporta metri gresiti exact in curba; intrebarea se pune
## cu timpul nostru de sosire; iar culoarul ales se TINE, nu se recalculeaza.
##
## Mutarea e progresiva ca la gheizere: departe abia schitata, aproape completa.
## Un salt direct pe tinta a fost deja masurat ca fiind mai rau decat nimic pe
## craterul Stromboli — volanul smucit scotea masina de pe sosea inainte sa
## ajunga la hazard.
func _span_line(speed: float, line: float) -> float:
	var spans := get_tree().get_nodes_in_group(RotatingSpanHazard.AI_GROUP)
	if spans.is_empty():
		return line
	var n_pts: int = track.route_at(car.route).count()
	var my_idx: int = car.road_index
	var bake: float = track.curve.bake_interval
	var best: RotatingSpanHazard = null
	var best_d := INF
	for node in spans:
		var sp := node as RotatingSpanHazard
		if sp == null:
			continue
		# Fata de POARTA, nu fata de originea nodului: aia sta la mijlocul
		# golului, cu ~42 m mai in aval decat linia de bariere. Vezi
		# `RotatingSpanHazard.AI_REACH_M`.
		var s_idx: int = track.closest_index_global(sp.ai_decision_point(), car.route)
		var d_idx := s_idx - my_idx
		if d_idx < -n_pts / 2:
			d_idx += n_pts
		elif d_idx > n_pts / 2:
			d_idx -= n_pts
		var along := float(d_idx) * bake
		if along < 0.0 or along > RotatingSpanHazard.AI_REACH_M:
			continue
		if along < best_d:
			best_d = along
			best = sp
	if best == null:
		_span_node = null
		return line
	var ahead := clampf(best_d / maxf(speed, 6.0), 0.0, 6.0)
	var side := 0.0
	if _span_node == best and absf(_span_side) > 0.01:
		side = _span_side
	else:
		side = best.ai_safe_side(ahead)
		_span_node = best
		_span_side = side
	if absf(side) < 0.01:
		return line
	var target := clampf(side * best.ai_line_offset(), -LINE_MAX, LINE_MAX)
	var t := clampf(1.0 - best_d / RotatingSpanHazard.AI_REACH_M, 0.0, 1.0)
	return lerpf(line, target, t)

## Shishi-odoshi (Kyoto, `shishi_odoshi_hazard.gd`): cat de departe (m) se citeste
## unghiul tubului. La ~20 m/s sunt 7 s — deci tubul se citeste in toata faza
## de umplere, nu doar la lovitura.
const SHISHI_REACH_M: float = 150.0
## Cat de incet presupunem ca ajungem, in cel mai rau caz, la tub (fractie din
## viteza curenta; virajele dinaintea lui il pot incetini). Sosirea e o
## FEREASTRA [rapid, lent], nu un moment (memoria `eta-cu-viteza-curenta-minte-
## pe-banda-cu-viraje`).
const SHISHI_SLOW: float = 0.7
## Cel mai repede ajunge la fractia asta din viteza de croaziera a masinii, iar
## cel mai lent nu coboara sub SLOW_FLOOR din ea (accelereaza pe drum).
const SHISHI_FAST: float = 0.95
const SHISHI_SLOW_FLOOR: float = 0.55
## Cat de repede (1/s) se instaleaza / se desface linia exterioara. Pe 1 s la
## 25 m/s: o mutare de 25 m, nu un smucit.
const SHISHI_BLEND_RATE: float = 1.2
## Dupa tub, cati metri mai tine linia exterioara (lungimea masinii).
const SHISHI_PASSED_M: float = 4.0

## Banda de autocar (Fiordland, brief §3 „optiunea 0" — vezi comentariul de la
## SIGNAL_LANE_EASE_M): cat un TunnelSignalHazard `mode == LANE` e ACTIV
## (rosu ACUM, sau va prinde masina inauntru — vezi `active` mai jos) si masina
## e in ZONA lui (de la SIGNAL_LANE_REACH_M inainte de linia de oprire pana la
## capatul tunelului), linia e IMPUSA pe banda dreapta — brief: „AI-ul care e
## in zona tunelului tine banda dreapta; pe verde (si fara sa-l prinda rosul
## inauntru) are toata latimea".
##
## Runda 2 (coordonator): declansator ANTICIPAT, nu doar `is_red()` chiar
## acum — o masina intrata pe verde chiar inainte sa vina rosul altfel n-ar
## avea niciun motiv sa tina dreapta pana cand lampa CHIAR se schimba, desi un
## sofer care socoteste "ies eu la timp?" ar sti dinainte. `blocks_in(eta)` cu
## eta = timpul pana la PORTALUL DE VEST (nu pana la linie) raspunde exact la
## intrebarea aia, cu acelasi bit pe care il are un om (lampa + viteza
## proprie) — „AI onest", nu informatie in plus.
##
## Regula e STRICTA (veto „AI onest": 0 masini pe banda stanga pe rosu), nu o
## preferinta care se instaleaza treptat ca la gheizere/pasaj — tranzitia
## (`SIGNAL_LANE_EASE_M`) e scurta, doar cat sa nu smuceasca volanul chiar la
## intrarea in zona, nu o ezitare de zeci de metri.
##
## De ce se citeste pe ORICE ruta (fara filtrul `car.route == 0` de la usa de
## piatra): semaforul n-are un ocol pe alta banda — zona lui e chiar drumul
## principal prin tunel, deci se aplica indiferent de ruta curenta.
func _signal_lane_keep(idx: int, speed: float, line: float) -> float:
	var signals := get_tree().get_nodes_in_group(TunnelSignalHazard.AI_GROUP)
	if signals.is_empty():
		return line
	var r := track.route_at(car.route)
	if r == null:
		return line
	var n_pts := r.count()
	var bake: float = track.curve.bake_interval
	for node in signals:
		var sig := node as TunnelSignalHazard
		if sig == null or sig.mode != TunnelSignalHazard.Mode.LANE:
			continue
		var key := sig.get_instance_id()
		if not _signal_index.has(key):
			_signal_index[key] = track.closest_index_global(
				sig.ai_decision_point(), car.route)
		var d_idx: int = int(_signal_index[key]) - idx
		if d_idx < -n_pts / 2:
			d_idx += n_pts
		elif d_idx > n_pts / 2:
			d_idx -= n_pts
		var along := float(d_idx) * bake
		# Zona: de la SIGNAL_LANE_REACH_M INAINTE de linie (along pozitiv, ne
		# apropiem) pana la capatul tunelului (along negativ pana la
		# -tunnel_length, deja angajati in tunel — semnul lui `along` scade pe
		# masura ce trecem de linie, la fel ca la usa de piatra si la semafor
		# in modul STOP).
		if along > SIGNAL_LANE_REACH_M or along < -sig.tunnel_length:
			continue
		# Runda 2 (coordonator): declansator ANTICIPAT, nu doar reactiv la
		# `is_red()` chiar acum. Un sofer care se apropie de tunel nu se uita
		# doar la lampa in clipa actuala, ci socoteste "daca intru ACUM, ies
		# inainte sa vina rosul?" — exact `blocks_in()`, deja folosit de
		# `_signal_red_ahead` pentru decizia veche de franare, aplicat aici cu
		# ETA pana la PORTALUL DE VEST (capatul tunelului), nu pana la linia de
		# oprire: intrebarea nu e "ajunge rosul la mine", e "ajunge rosul
		# INAUNTRU cat sunt eu acolo". Acelasi bit pe care il are un om (lampa +
		# propria viteza) — „AI onest".
		#
		# Distanta pana la portalul de vest: `along` e distanta pana la LINIE
		# (portalul de est), iar tunelul se intinde pana la `along ==
		# -tunnel_length` — deci distanta ramasa pana la capat e
		# `along + tunnel_length`, valabila si inainte de linie (along > 0,
		# inca n-am intrat) si dupa (along < 0, deja inauntru).
		var dist_to_west := along + sig.tunnel_length
		var eta_west := dist_to_west / maxf(speed, 10.0)
		var active := sig.is_red() or sig.blocks_in(eta_west)
		if not active:
			continue
		var hw: float = track.width_at_index(idx) if car.route == 0 \
			else r.half_width
		# BUG GASIT runda 2 (vezi TunnelSignalHazard.tunnel_half_width):
		# width_at_index() poate raporta semilatimea sectorului DINAINTE
		# (rampa de tranzitie de 30 m se aplica dupa capatul lui, catre
		# half_width GLOBAL) chiar in interiorul tunelului declarat, langa
		# linie -- masurat, `hw=6.5` in loc de 4.0 in tot tunelul. Plafonam
		# cu semilatimea REALA a tunelului, cunoscuta de hazard, nu dedusa
		# din profilul de latime (care ramane corect pentru restul pistei).
		hw = minf(hw, sig.tunnel_half_width)
		hw = maxf(hw, 0.001)
		var target := clampf(SIGNAL_RIGHT_LANE_M / hw, 0.0, LINE_MAX)
		# Tranzitie scurta la INTRAREA in zona (along aproape de
		# SIGNAL_LANE_REACH_M); in restul zonei (inclusiv tot tunelul), linia
		# e ferm pe tinta.
		var t := clampf(
			(SIGNAL_LANE_REACH_M - along) / SIGNAL_LANE_EASE_M, 0.0, 1.0)
		var result := lerpf(line, target, t)
		if OS.get_environment("SIGNAL_LANE_TRACE") == "1":
			var actual_lat := r.side_at(idx).dot(car.global_position - r.baked[r.wrap_index(idx)])
			print("[signal-lane] %s along=%.1f hw=%.2f target=%.3f t=%.2f line_in=%.3f line_out=%.3f actual_lat=%.2f red=%s blocks_in=%.1fs" %
				[car.pilot_name, along, hw, target, t, line, result, actual_lat,
					sig.is_red(), eta_west])
		return result
	return line

## Lungimea de arc (m) de la indexul `idx` la `idx + d_idx` pe ruta `r`, cu semn
## (negativ = punctul e in spatele nostru). Suma segmentelor coapte, nu un
## produs cu `bake_interval`. Dincolo de 600 de pasi intoarce o valoare uriasa:
## apelantul oricum ignora tot ce e mai departe de raza lui.
func _arc_to(r: TrackRoute, idx: int, d_idx: int, bake: float) -> float:
	var steps := absi(d_idx)
	if steps > 600:
		return signf(float(d_idx)) * 1.0e6
	var n := r.count()
	var total := 0.0
	var sgn := 1 if d_idx >= 0 else -1
	var i := idx
	for _k in steps:
		var a: Vector3 = r.baked[((i % n) + n) % n]
		var b: Vector3 = r.baked[(((i + sgn) % n) + n) % n]
		total += a.distance_to(b)
		i += sgn
	return total * float(sgn)


## Shishi-odoshi: cand tubul va bate in fereastra mea de sosire, ma mut pe linia
## exterioara (banda libera de langa pivot). Niciodata frana.
##
## Citeste doar ce vede si un om: unghiul tubului (`blocks_between` pe ceasul lui)
## si propria viteza. Angajamentul se TINE (latch) pana trec de tub — fara el,
## linia ar oscila in clipa in care fereastra de pericol trece pe langa estimare.
func _shishi_line(idx: int, speed: float, line: float) -> float:
	if not reads_shishi:
		return line
	var nodes := get_tree().get_nodes_in_group(ShishiOdoshiHazard.AI_GROUP)
	if nodes.is_empty():
		return line
	var r := track.route_at(car.route)
	if r == null or r.count() == 0:
		return line
	var n_pts := r.count()
	var bake: float = track.curve.bake_interval
	var dt := get_physics_process_delta_time()
	for node in nodes:
		var hz := node as ShishiOdoshiHazard
		if hz == null:
			continue
		var key := hz.get_instance_id()
		if not _shishi_index.has(key):
			var hi := track.closest_index_global(hz.ai_decision_point(), car.route)
			_shishi_index[key] = hi
			_shishi_sign[key] = signf(r.side_at(hi).dot(
				hz.global_transform.basis.x * float(hz.side)))
		var d_idx: int = int(_shishi_index[key]) - idx
		if d_idx < -n_pts / 2:
			d_idx += n_pts
		elif d_idx > n_pts / 2:
			d_idx -= n_pts
		# Metri REALI pe axa pana la tub, nu `d_idx * bake_interval`: bake_interval
		# e un MAXIM, punctele coapte se indesesc langa nodurile curbei, iar eroarea
		# masurata aici a fost de 16 m din 42 — destul cat sa angajezi banda
		# exterioara cu o secunda prea tarziu.
		var along := _arc_to(r, idx, d_idx, bake)
		var in_zone := along <= SHISHI_REACH_M and along >= -SHISHI_PASSED_M
		if not in_zone:
			_shishi_latched.erase(key)
		elif not _shishi_latched.has(key):
			var ahead := maxf(along, 0.0)
			# Sosirea e o FEREASTRA, si viteza de ACUM nu o ancoreaza: la iesirea din
			# viraj masina accelereaza (masurat: un pilot care vedea 15 m/s la 150 m
			# a ajuns cu 33 si s-a angajat pe exterior abia la 42 m — prea tarziu).
			# Un pilot isi stie masina: cel mai repede = viteza ei de croaziera,
			# cel mai lent = o fractie din viteza de acum sau din croaziera.
			var cruise: float = car.max_speed * car.speed_scale
			var eta_fast := ahead / maxf(maxf(speed, cruise * SHISHI_FAST), 10.0)
			var eta_slow := ahead / maxf(maxf(speed * SHISHI_SLOW, cruise * SHISHI_SLOW_FLOOR), 8.0)
			if hz.blocks_between(eta_fast, eta_slow):
				_shishi_latched[key] = true
				if OS.get_environment("SHISHI_TRACE") == "1":
					print("[shishi] %s angajat along=%.1f v=%.1f eta=[%.2f, %.2f] ceas=%.2f" % [car.pilot_name, along, speed, eta_fast, eta_slow, hz.clock()])
		var blend: float = _shishi_blend.get(key, 0.0)
		blend = move_toward(blend,
			1.0 if _shishi_latched.has(key) else 0.0, dt * SHISHI_BLEND_RATE)
		_shishi_blend[key] = blend
		if blend <= 0.0:
			continue
		var hw: float = maxf(track.width_at_index(idx) if car.route == 0 			else r.half_width, 0.001)
		var target := clampf(
			float(_shishi_sign[key]) * absf(hz.ai_safe_lane_m()) / hw,
			-LINE_MAX, LINE_MAX)
		return lerpf(line, target, blend)
	return line


## Daruma-otoshi (Kyoto, `daruma_otoshi_hazard.gd`): cat de departe (m) se citeste
## ciocanul tras inapoi. Telegraful dureaza ~3,5 s, deci la ~25 m/s se vede de la
## 90 m; 140 m acopera si perioada de repaus, ca sa ne putem pregati.
const DARUMA_REACH_M: float = 140.0
## Cat de jos coboara plafonul de viteza (fractie din croaziera): niciodata oprire.
const DARUMA_FLOOR: float = 0.5
## Dupa turn, cati metri mai tine decizia (lungimea masinii + amprenta discului).
const DARUMA_PASSED_M: float = 8.0
## Marja de siguranta peste sfarsitul ferestrei de pericol (s).
const DARUMA_EXTRA_S: float = 0.2

## Inmultitorul tintei de viteza din zonele care cer prudenta (grupul
## `ai_speed_zones`, metoda `ai_speed_scale_at(pos) -> float`). 1.0 cand nu e nicio
## zona in scena (grup gol = zero cost). Citeste doar ce poate simti si un om:
## unde se afla masina fata de zona.
const AI_SPEED_ZONE_GROUP: StringName = &"ai_speed_zones"

func speed_zone_scale() -> float:
	var nodes := get_tree().get_nodes_in_group(AI_SPEED_ZONE_GROUP)
	if nodes.is_empty():
		return 1.0
	var scale := 1.0
	for node in nodes:
		if node.has_method("ai_speed_scale_at"):
			scale = minf(scale, float(node.call("ai_speed_scale_at", car.global_position)))
	return scale


## Daruma-otoshi: cand discul va traversa in FEREASTRA mea de sosire [rapid, lent]
## (`blocks_between`), aleg intre doua lucruri, o singura data, si tin alegerea:
##   - ridic piciorul si ajung DUPA ce discul a eliberat soseaua (daca viteza
##     necesara nu coboara sub `DARUMA_FLOOR` din croaziera);
##   - altfel nu ating nimic: ajung inaintea loviturii (plafon fara efect).
## Citeste doar ce vede si un om: ciocanul tras (ceasul hazardului prin
## `window_rel`) si propria viteza. Intoarce plafonul de viteza (INF = niciunul).
func _daruma_cap(idx: int, speed: float) -> float:
	# Doua feluri de hazard cu ceas pe sosea citesc prin aceeasi cale: discul daruma
	# (traverseaza intr-o secunda) si carul de festival Gion Matsuri (traverseaza incet,
	# in ~5 s). Contractul e acelasi: `ai_decision_point`, `blocks_between`, `window_rel`,
	# `ai_margin`. Apelurile merg prin `call`, fiindca cele doua clase nu au parinte comun
	# (daruma ramane neatinsa).
	var nodes: Array[Node] = []
	if reads_daruma:
		nodes.append_array(get_tree().get_nodes_in_group(DarumaOtoshiHazard.AI_GROUP))
	if reads_gion:
		nodes.append_array(get_tree().get_nodes_in_group(GionMatsuriHazard.AI_GROUP))
	if nodes.is_empty():
		return INF
	var r := track.route_at(car.route)
	if r == null or r.count() == 0:
		return INF
	var n_pts := r.count()
	var bake: float = track.curve.bake_interval
	_daruma_now += get_physics_process_delta_time()
	var cap := INF
	var cruise: float = car.max_speed * car.speed_scale
	for node in nodes:
		var hz := node as Node3D
		if hz == null:
			continue
		var margin: float = float(hz.get("ai_margin"))
		# Podeaua plafonului de viteza: fiecare hazard o poate cobori (carul de festival
		# ocupa soseaua ~4 s, nu ~1 s ca discul, deci ridicarea trebuie sa mearga mai jos).
		var floor_frac := DARUMA_FLOOR
		var own_floor: Variant = hz.get("ai_floor")
		if own_floor != null:
			floor_frac = float(own_floor)
		var key := hz.get_instance_id()
		if not _daruma_index.has(key):
			_daruma_index[key] = track.closest_index_global(hz.call(&"ai_decision_point") as Vector3, car.route)
		var d_idx: int = int(_daruma_index[key]) - idx
		if d_idx < -n_pts / 2:
			d_idx += n_pts
		elif d_idx > n_pts / 2:
			d_idx -= n_pts
		var along := _arc_to(r, idx, d_idx, bake)
		if along > DARUMA_REACH_M or along < -DARUMA_PASSED_M:
			_daruma_state.erase(key)
			continue
		if not _daruma_state.has(key):
			var ahead := maxf(along, 0.0)
			var eta_fast := ahead / maxf(maxf(speed, cruise * SHISHI_FAST), 10.0)
			var eta_slow := ahead / maxf(maxf(speed * SHISHI_SLOW, cruise * SHISHI_SLOW_FLOOR), 8.0)
			var st := {"lift": false, "clear_at": 0.0}
			if bool(hz.call(&"blocks_between", eta_fast, eta_slow)):
				var w: Vector2 = hz.call(&"window_rel", eta_fast)
				var wait_v := ahead / maxf(w.y + margin + DARUMA_EXTRA_S, 0.1)
				if wait_v >= cruise * floor_frac:
					st["lift"] = true
					st["clear_at"] = _daruma_now + w.y
				if OS.get_environment("DARUMA_TRACE") == "1":
					print("[daruma] %s along=%.1f v=%.1f eta=[%.2f, %.2f] fereastra=[%.2f, %.2f] -> %s" % [car.pilot_name, along, speed, eta_fast, eta_slow, w.x, w.y, "RIDIC" if st["lift"] else "TREC"])
			_daruma_state[key] = st
		var state: Dictionary = _daruma_state[key]
		if not state["lift"] or along < 0.0:
			continue
		var left: float = float(state["clear_at"]) - _daruma_now + margin + DARUMA_EXTRA_S
		if left <= 0.0:
			continue
		cap = minf(cap, maxf(along / left, cruise * floor_frac))
	return cap


## Shishimai (Kyoto, `shishimai_hazard.gd`): de cat de departe (m) se vede leul si pana
## cat dupa el (m) tine decizia. La ~25 m/s, 90 m = 3,5 s: destul sa vezi dansul si,
## in ultimele 1,4 s, ghemuirea dinaintea atacului.
const SHISHIMAI_REACH_M: float = 90.0
const SHISHIMAI_PASSED_M: float = 6.0
## Cat de repede se muta linia pe banda aleasa (1/s).
const SHISHIMAI_BLEND_RATE: float = 3.5
## La cat timp re-evaluez banda (s): leul se misca, fereastra mea se ingusteaza.
const SHISHIMAI_REEVAL_S: float = 0.12
## Semilatimea masinii + eroarea de urmarire a liniei (m).
const SHISHIMAI_CAR_HALF_M: float = 1.6

## Shishimai: leul ocupa o fasie de ~3 m dintr-o sosea de 14 m si se misca dupa un
## ritm pe care il vede si un om (dansul lateral; ghemuirea si capul intors anunta
## atacul). Citesc doar atat: unde va fi fasia in FEREASTRA mea de sosire [rapid,
## lent] (nu la un singur moment: `eta-cu-viteza-curenta-minte-pe-banda-cu-viraje`)
## si aleg banda libera cea mai apropiata de linia mea. Nu franez. Atacul intra in
## prezicere doar dupa ce telegraful lui a inceput (`center_seen_at`).
func _shishimai_line(idx: int, speed: float, line: float) -> float:
	if not reads_shishimai:
		return line
	var nodes := get_tree().get_nodes_in_group(ShishimaiHazard.AI_GROUP)
	if nodes.is_empty():
		return line
	var r := track.route_at(car.route)
	if r == null or r.count() == 0:
		return line
	var n_pts := r.count()
	var bake: float = track.curve.bake_interval
	var dt := get_physics_process_delta_time()
	var cruise: float = car.max_speed * car.speed_scale
	for node in nodes:
		var hz := node as ShishimaiHazard
		if hz == null:
			continue
		var key := hz.get_instance_id()
		if not _shishimai_index.has(key):
			var hi := track.closest_index_global(hz.ai_decision_point(), car.route)
			_shishimai_index[key] = hi
			var sg := signf(r.side_at(hi).dot(hz.global_transform.basis.x))
			_shishimai_sign[key] = sg if sg != 0.0 else 1.0
		var d_idx: int = int(_shishimai_index[key]) - idx
		if d_idx < -n_pts / 2:
			d_idx += n_pts
		elif d_idx > n_pts / 2:
			d_idx -= n_pts
		var along := _arc_to(r, idx, d_idx, bake)
		if along > SHISHIMAI_REACH_M or along < -SHISHIMAI_PASSED_M:
			_shishimai_lane.erase(key)
			_shishimai_blend.erase(key)
			_shishimai_timer.erase(key)
			continue
		var hw: float = maxf(track.width_at_index(idx) if car.route == 0 			else r.half_width, 0.001)
		var sgn: float = _shishimai_sign[key]
		var timer: float = float(_shishimai_timer.get(key, 0.0)) - dt
		if timer <= 0.0 or not _shishimai_lane.has(key):
			timer = SHISHIMAI_REEVAL_S
			# Fereastra de sosire in gabaritul leului: intru cand botul meu ajunge la
			# nasul lui, ies cand coada mea trece de coada lui; cel mai repede = viteza
			# de croaziera, cel mai lent = o fractie din viteza de acum.
			var scale := hz.model_scale
			var enter := maxf(along - (hz.hit_front * scale + 1.5), 0.0)
			var leave := maxf(along + (hz.hit_back * scale + 1.5), 0.0)
			var v_fast := maxf(maxf(speed, cruise * SHISHI_FAST), 10.0)
			var v_slow := maxf(maxf(speed * SHISHI_SLOW, cruise * SHISHI_SLOW_FLOOR), 8.0)
			var t0 := enter / v_fast
			var t1 := leave / v_slow
			var lane_max := LINE_MAX * hw
			var mine := line * hw * sgn # linia mea, in cadrul leului (+X local)
			var occ := hz.occupied_interval(t0, t1)
			var prev: float = float(_shishimai_lane.get(key, mine))
			# histerezis: raman pe banda aleasa cat timp ramane (macar pe jumatate) libera
			if _shishimai_lane.has(key) and hz.clearance(prev, SHISHIMAI_CAR_HALF_M, occ) >= hz.ai_lane_margin * 0.5:
				_shishimai_lane[key] = prev
			else:
				_shishimai_lane[key] = hz.ai_choose_lane(mine, SHISHIMAI_CAR_HALF_M, t0, t1, lane_max)
			if OS.get_environment("SHISHIMAI_TRACE") == "1":
				print("[shishimai] %s along=%.1f v=%.1f t=[%.2f, %.2f] ocupat=[%.1f, %.1f] linia=%.1f -> banda=%.1f ceas=%.2f" % [car.pilot_name, along, speed, t0, t1, occ.x, occ.y, mine, float(_shishimai_lane[key]), hz.clock()])
		_shishimai_timer[key] = timer
		var blend: float = move_toward(float(_shishimai_blend.get(key, 0.0)), 1.0, dt * SHISHIMAI_BLEND_RATE)
		_shishimai_blend[key] = blend
		var target := clampf(float(_shishimai_lane[key]) * sgn / hw, -LINE_MAX, LINE_MAX)
		return lerpf(line, target, blend)
	return line


func _avoid_line(idx: int, speed: float, line: float, keep_off: float) -> float:
	if traffic.is_empty():
		return line
	var r := track.route_at(car.route)
	if r == null or r.count() == 0:
		return line
	var n := r.count()
	var window := clampf(speed * AVOID_WINDOW_FACTOR,
		AVOID_WINDOW_MIN, AVOID_WINDOW_MAX)

	# Cel mai apropiat blocaj DIN FATA, pe aceeasi ruta. O masina de pe
	# scurtatura traieste in alt spatiu de indecsi — comparatia n-ar avea sens.
	var best: Car = null
	var best_ahead := window
	for other in traffic:
		if other == null or other == car or not is_instance_valid(other):
			continue
		if other.route != car.route:
			continue
		var d := other.road_index - idx
		if r.closed:
			if d > n / 2:
				d -= n
			elif d < -n / 2:
				d += n
		var ahead_m := float(d) * track.curve.bake_interval
		if ahead_m <= 0.0 or ahead_m > best_ahead:
			continue
		if speed - other.horizontal_speed() < AVOID_MIN_CLOSING \
				and ahead_m > AVOID_TAIL_M:
			continue
		best = other
		best_ahead = ahead_m
	if best == null:
		_avoid_car = null
		return line

	# Unde sta blocajul pe latimea soselei, in aceleasi fractii ca `line`.
	var bidx: int = best.road_index
	var hw := track.width_at_index(bidx) if car.route == 0 else r.half_width
	hw = maxf(hw, 0.001)
	var blocker_lat := r.side_at(bidx).dot(
		best.global_position - r.baked[r.wrap_index(bidx)]) / hw
	var gap_frac := AVOID_CLEARANCE_M / hw
	# Histereza pe iesire: odata pornita ocolirea, n-o abandonam pentru ca
	# blocajul a derivat la fix un gabarit de linia noastra.
	var clear_frac := gap_frac * (1.25 if _avoid_car == best else 1.0)
	if absf(blocker_lat - line) >= clear_frac:
		_avoid_car = null
		return line

	# Partea de trecere: cea cu mai mult asfalt (candidatul mai aproape de axa),
	# pastrata cat tine acelasi blocaj daca inca incape.
	var cand_l := blocker_lat - gap_frac
	var cand_r := blocker_lat + gap_frac
	# `_line_lo`/`_line_hi` = ±LINE_MAX peste tot in afara unei muchii fara
	# parapet (`Track.ai_drop_edges`), deci testul e cel vechi.
	var l_ok := cand_l >= _line_lo
	var r_ok := cand_r <= _line_hi
	var target: float
	# In elanul unei sarituri (`Track.ai_keep_side_at`), cu blocajul LANGA
	# noi (sub AVOID_TAIL_M): trecerea e pe partea pe care suntem deja. Regula
	# „mai aproape de axa" de mai jos ar trimite masina de pe margine prin
	# caroseria vecinului — si doua masini frecate una de alta ajung la buza
	# prea lente. Vezi `TrackChannel.ai_keep_side_run_m`.
	if car.route == 0 and best_ahead < AVOID_TAIL_M and track.ai_keep_side_at(idx):
		var my_lat := r.side_at(idx).dot(
			car.global_position - r.baked[r.wrap_index(idx)]) / hw
		if my_lat < blocker_lat and l_ok:
			_avoid_side = -1.0
		elif my_lat >= blocker_lat and r_ok:
			_avoid_side = 1.0
		_avoid_car = best
	if _avoid_car == best and _avoid_side < 0.0 and l_ok:
		target = cand_l
	elif _avoid_car == best and _avoid_side > 0.0 and r_ok:
		target = cand_r
	elif l_ok and (not r_ok or absf(cand_l) <= absf(cand_r)):
		target = cand_l
		_avoid_side = -1.0
	elif r_ok:
		target = cand_r
		_avoid_side = 1.0
	else:
		# Drum prea ingust pentru orice ocolire: ramanem pe linie, in spate.
		_avoid_car = null
		return line
	# Sector cu hazard pe axa (trenul de pe Baikal): nu traversam axa ca sa
	# depasim — mai bine cateva secunde in spatele autobuzului decat sub tren.
	if keep_off > 0.0 and absf(line) > 0.01 and signf(target) != signf(line):
		_avoid_car = null
		return line
	_avoid_car = best

	# Aproape = mutare completa; departe = abia schitata.
	var t := clampf((window - best_ahead) / maxf(window - AVOID_FULL_M, 0.001),
		0.0, 1.0)
	return lerpf(line, clampf(target, _line_lo, _line_hi), t)

## Limitele liniei pe muchia fara parapet (`Track.ai_drop_edges`). In afara
## unei muchii declarate: ±LINE_MAX si `_drop_side` = 0, adica exact ce era.
##
## Marginea se masoara de la marginea asfaltului la AXA masinii si se
## converteste in fractie pe latimea cea mai INGUSTA dintre aici si punctul de
## tintire: tinta de aproape se pune pe latimea de la indexul ei (vezi
## `Track.lookahead_point`), iar la intrarea in fantana soseaua se strange de
## la 6,5 la 4,5 m chiar la iesirea din viraj — o fractie calculata pe 6,5 ar
## cadea la 1,6 m de buza pe 4,5.
func _drop_limits(idx: int, speed: float) -> void:
	_line_lo = -LINE_MAX
	_line_hi = LINE_MAX
	_drop_side = 0.0
	if car.route != 0:
		return
	var edge := track.ai_drop_edge_at(idx)
	if edge.x == 0.0:
		return
	var steps := int(_lookahead_near(speed) / maxf(track.curve.bake_interval, 0.001))
	# Cea mai INGUSTA latime pana la tinta, nu doar capetele: sectoarele de
	# latime din fantana au trepte de 2 m (6,5 -> 4,5) la 0.133, 0.163 si
	# 0.217, iar o linie calculata pe latimea de aici ducea masina pe
	# portiunea lata drept in treapta.
	var hw := track.width_at_index(idx)
	for k in range(1, steps + 1):
		hw = minf(hw, track.width_at_index(idx + k))
	hw = maxf(hw, 0.001)
	var lim := clampf(1.0 - edge.y / hw, 0.0, LINE_MAX)
	# Si partea cealalta, cu o margine mica: pe dreapta fantanii umarul e sub
	# buza asfaltului (0,3-0,5 m, adica perete la urcare), iar o masina
	# impinsa acolo de regula de mai jos se infunda — masurat.
	var far_lim := clampf(1.0 - DROP_FAR_MARGIN_M / hw, 0.0, LINE_MAX)
	_drop_side = edge.x
	if edge.x < 0.0:
		_line_lo = -lim
		_line_hi = far_lim
	else:
		_line_hi = lim
		_line_lo = -far_lim

## Nu inchide usa: in zona cu muchie fara parapet, o masina ALATURI de noi
## (sub DROP_ALONGSIDE_M pe directia de mers) ramane cu culoarul ei — linia
## noastra nu se apropie de ea sub AVOID_CLEARANCE_M, fie ca vine de la
## tragerea spre apex, fie de la o ocolire. Spre apa, mereu, ca sa nu
## impingem vecinul in ea; spre perete, cand vecinul e deja la limita lui,
## fiindca ocolirea care nu mai are voie pe stanga (limita de mai sus) trece
## pe dreapta, iar vecinul de acolo era impins peste treapta de latime, sub
## buza, unde se infunda (masurat: Tu il impingea pe Vex de la -1,2 la
## +5,9 m, seed 11).
##
## De ce nu ajunge `_avoid_line`: aia vede doar ce e IN FATA. Masurat pe
## Track17 (seed 3, cu decorul bazarului): Luna (masina grea) e cu 0,5 m in
## fata lui Tu, pe dreapta lui, la 25 m de acul de la fund; tragerea spre
## interior (apa) o muta spre stanga si-l impinge pe Tu, care e deja langa
## muchie, in apa — Luna nu-l vede, fiindca e alaturi, nu in fata.
func _drop_alongside(idx: int, line: float) -> float:
	var r := track.route_at(0)
	if r == null or r.count() == 0:
		return line
	var hw := maxf(track.width_at_index(idx), 0.001)
	var base_pt := r.baked[r.wrap_index(idx)]
	var side := r.side_at(idx)
	var fwd := -car.global_transform.basis.z
	var my_lat := side.dot(car.global_position - base_pt) / hw
	var gap_frac := AVOID_CLEARANCE_M / hw
	var out := line
	for other in traffic:
		if other == null or other == car or not is_instance_valid(other):
			continue
		if other.route != 0:
			continue
		var d := other.global_position - car.global_position
		if absf(fwd.dot(d)) > DROP_ALONGSIDE_M:
			continue
		var o_lat := side.dot(other.global_position - base_pt) / hw
		# Cel mult cat suntem ACUM: regula opreste inchiderea usii, nu ne
		# impinge spre marginea cealalta (pe dreapta fantanii e un umar sub
		# buza asfaltului, iar o masina impinsa acolo se infunda — masurat).
		# Spre muchie: mereu. Spre partea opusa: doar cand vecinul de acolo nu
		# mai are unde sa se dea (e la un gabarit de limita lui) — altfel, in
		# plutonul din virajul de intrare, regula tinea masinile de pe stanga
		# lipite de muchie (masurat: 26 de treceri cu roata pe buza fata de 7).
		var toward_drop := (o_lat < my_lat) == (_drop_side < 0.0)
		if o_lat < my_lat:
			if toward_drop or o_lat <= _line_lo + gap_frac:
				out = maxf(out, minf(o_lat + gap_frac, minf(my_lat, _line_hi)))
		else:
			if toward_drop or o_lat >= _line_hi - gap_frac:
				out = minf(out, maxf(o_lat - gap_frac, maxf(my_lat, _line_lo)))
	return clampf(out, _line_lo, _line_hi)

## Metri pana la prima usa de piatra de pe banda noastra care va fi INCHISA
## cand ajungem la ea (INF daca nu e niciuna, sau va fi deschisa). Doar pe
## ruta 0: ocolul e tocmai banda pe care usa nu exista, iar `closest_index`
## al usii pe ocol ar cadea la un capat al lui si ar frana degeaba.
func _door_closed_ahead(speed: float) -> float:
	if car.route != 0:
		return INF
	var doors := get_tree().get_nodes_in_group(SlidingHazard.DOOR_GROUP)
	if doors.is_empty():
		return INF
	var n_pts: int = track.route_at(0).count()
	var bake: float = track.curve.bake_interval
	var best := INF
	for node in doors:
		var door := node as SlidingHazard
		if door == null:
			continue
		var key := door.get_instance_id()
		if not _door_index.has(key):
			_door_index[key] = track.closest_index_global(door.ai_decision_point(), 0)
		var d_idx: int = int(_door_index[key]) - car.road_index
		if d_idx < -n_pts / 2:
			d_idx += n_pts
		elif d_idx > n_pts / 2:
			d_idx -= n_pts
		var along := float(d_idx) * bake
		if along < 0.0 or along > DOOR_REACH_M or along >= best:
			continue
		var eta := along / maxf(speed, 6.0)
		if door.door_blocks_in(eta) or door.door_blocks_in(eta + DOOR_ETA_SLACK):
			best = along
	return best

## Torentul in pulsuri (Fiordland, brief „Torentul in pulsuri"): scurtatura
## Chasm e blocata cand ajungem la perdea in mijlocul unui PULS. Diferit de
## usa de piatra/semafor: aici NU exista franare/asteptare — cine e blocat
## pur si simplu NU ia scurtatura in ciclul asta, ia bucla principala (vezi
## `take_branch` mai sus, unde asta e un AND simplu pe conditia existenta).
##
## AI ONEST: exact aceleasi trei bituri pe care le are jucatorul la furca —
## FAZA torentului (vizibila: fir subtire/anunt/plin), DISTANTA pana la
## furca si PROPRIA viteza (ca sa estimeze ETA, cum ar face un sofer la
## volan). Niciun bit despre ceasul intern, despre ploaie, sau despre cat
## mai are perdeaua — `TorrentCycle.blocks_in()` face exact calculul cu care
## un om ar decide „ies eu la timp inainte sa vina puslul", nu-i da AI-ului
## raspunsul direct.
##
## Aceeasi forma ca `_door_closed_ahead`: distanta pe bucla pana la furca,
## ETA din viteza curenta, `blocks_in` cu marja de o secunda SI cu marja de
## traversare (`cross_s()` — daca ajunge la timp dar pulsul vine cat inca e
## SUB perdea, tot e blocat).
func _torrent_blocks_branch(speed: float) -> bool:
	if car.route != 0:
		return false
	var torrents := get_tree().get_nodes_in_group(TorrentCycle.AI_GROUP)
	if torrents.is_empty():
		return false
	var n_pts: int = track.route_at(0).count()
	var bake: float = track.curve.bake_interval
	for node in torrents:
		var torrent := node as TorrentCycle
		if torrent == null or torrent.branch_index != 1:
			continue
		var key := torrent.get_instance_id()
		if not _torrent_index.has(key):
			_torrent_index[key] = track.closest_index_global(
				torrent.ai_decision_point(), 0)
		var d_idx: int = int(_torrent_index[key]) - car.road_index
		if d_idx < -n_pts / 2:
			d_idx += n_pts
		elif d_idx > n_pts / 2:
			d_idx -= n_pts
		var along := float(d_idx) * bake
		if along < 0.0 or along > TORRENT_REACH_M:
			continue
		# Metri pe BANDA de la intrare pana la perdea: `branch_frac` e
		# fractia din lungimea rutei, deci `branch_frac * route.length()`.
		var branch_route := track.route_at(1)
		var along_branch := 0.0
		if branch_route != null:
			along_branch = torrent.branch_frac * branch_route.length()
		# Sosirea NU e un moment, e o FEREASTRA: cel mai devreme ajung daca tin
		# viteza de acum; cel mai tarziu daca virajele benzii (raza 19 m la
		# furca) ma incetinesc la TORRENT_BRANCH_SLOW din ea. Un om la volan
		# socoteste la fel („ajung in 4-6 s, pulsul vine in 5 — nu intru").
		# Cu un singur moment + 1 s slack, masurat pe scena unita: 5 intrari
		# de AI in puls din 30 (memoria: eta cu viteza curenta minte pe o
		# banda cu viraje). Aceleasi informatii ca jucatorul, doar cu marja.
		var v := maxf(speed, 6.0)
		var eta_fast := (along + along_branch) / v
		var eta_slow := along / v + along_branch / (v * TORRENT_BRANCH_SLOW)
		if torrent.blocks_between(eta_fast, eta_slow + DOOR_ETA_SLACK):
			return true
	return false

## Trage linia spre partea OPUSA benzii torentului, aproape de furca, cand
## torentul blocheaza — plasa de siguranta pentru `_torrent_blocks_branch`.
##
## GASIT PRIN SONDA (`probe_fiord_torent.gd`, verificarea AI onest): cu doar
## `take_branch=false` (steering-ul normal tinteste bucla, fara sa mai
## priveasca spre lure-ul benzii), `Track.resolve_route` tot putea comuta
## masina pe ruta 1 — comutarea de ruta se face pe PROXIMITATE LATERALA
## (banda mai apropiata decat bucla + o histereza de 1.5 m), independent de
## ce a decis AI-ul sa faca cu volanul. O masina cu personalitate de linie
## (`line_offset`) sau impinsa de trafic (`_avoid_line`, care ruleaza INAINTE
## de bifurcatie) putea sa fie, la metri de furca, marginal mai aproape de
## banda decat de axa buclei — si comuta ruta desi `take_branch` era fals in
## fiecare cadru. Masurat: 5 intrari AI in SURGE pe 4 seed-uri inainte de fix.
##
## Fix: acelasi tipar ca `_signal_lane_keep` (linie IMPUSA intr-o zona
## ingusta din fata unui hazard cu veto) — cand blocat, langa furca
## (`TORRENT_LANE_REACH_M`), linia e trasa ferm spre partea opusa benzii, ca
## nicio combinatie de personalitate+trafic sa nu mai ajunga mai aproape de
## banda decat de axa. Se aplica DUPA `_avoid_line` (acelasi motiv ca la
## semafor: e regula de siguranta cu veto, nu preferinta de linie).
func _torrent_lane_keep(idx: int, speed: float, line: float) -> float:
	if car.route != 0:
		return line
	var torrents := get_tree().get_nodes_in_group(TorrentCycle.AI_GROUP)
	if torrents.is_empty():
		return line
	var n_pts: int = track.route_at(0).count()
	var bake: float = track.curve.bake_interval
	for node in torrents:
		var torrent := node as TorrentCycle
		if torrent == null or torrent.branch_index != 1:
			continue
		var key := torrent.get_instance_id()
		if not _torrent_index.has(key):
			_torrent_index[key] = track.closest_index_global(
				torrent.ai_decision_point(), 0)
		var fork_idx: int = int(_torrent_index[key])
		if not _torrent_side_sign.has(key):
			# Semnul lateral al benzii fata de axa buclei, la furca: banda
			# torentului e mereu departe de axa (nu pe axa), deci un singur
			# esantion (primul punct al ei) da semnul stabil pentru toata cursa.
			var branch_route := track.route_at(1)
			var sgn := 1.0
			if branch_route != null and not branch_route.baked.is_empty():
				var side := track.route_at(0).side_at(fork_idx)
				var to_branch := branch_route.baked[0] - track.route_at(0).baked[fork_idx]
				sgn = signf(side.dot(to_branch))
				if sgn == 0.0:
					sgn = 1.0
			_torrent_side_sign[key] = sgn
		var d_idx: int = fork_idx - idx
		if d_idx < -n_pts / 2:
			d_idx += n_pts
		elif d_idx > n_pts / 2:
			d_idx -= n_pts
		var along := float(d_idx) * bake
		# Zona: de la TORRENT_LANE_REACH_M inainte de furca pana chiar la ea
		# (along negativ inseamna am trecut deja de indexul furcii pe ruta 0 —
		# nu ar trebui sa se intample cat suntem pe ruta 0, dar tratam la fel
		# ca semaforul: fara cod separat pentru "deja angajati").
		if along > TORRENT_LANE_REACH_M or along < 0.0:
			continue
		var blocked := _torrent_blocks_branch(speed)
		if not blocked:
			continue
		var opposite_sign: float = -float(_torrent_side_sign[key])
		var target := opposite_sign * LINE_MAX * TORRENT_LANE_TARGET_FRAC
		var t := clampf((TORRENT_LANE_REACH_M - along) / TORRENT_LANE_EASE_M, 0.0, 1.0)
		line = lerpf(line, target, t)
	return line

## Metri pana la semaforul din fata care VA FI rosu cand ajungem la linia de
## oprire, SAU pe care nu am cum sa-l traversam complet inainte sa vina rosul
## (INF daca niciunul in raza, sau drumul e limpede — vezi runda 2, punctul 2
## mai jos). Aceeasi forma ca `_door_closed_ahead`, dar FARA filtrul de ruta:
## semaforul n-are un ocol pe alta banda, deci se citeste pe orice ruta pe
## care se afla masina.
##
## „AI onest si semaforul" (brief §3): nu se cere niciun bit in plus fata de
## ce vede si jucatorul — lampa (prin hazard), distanta pana la linie si
## PROPRIA viteza (ca sa estimeze cat ii ia sa traverseze — un om ar face
## acelasi calcul la volan).
func _signal_red_ahead(speed: float) -> float:
	var signals := get_tree().get_nodes_in_group(TunnelSignalHazard.AI_GROUP)
	if signals.is_empty():
		return INF
	var r := track.route_at(car.route)
	if r == null:
		return INF
	var n_pts := r.count()
	var bake: float = track.curve.bake_interval
	var best := INF
	for node in signals:
		var sig := node as TunnelSignalHazard
		if sig == null:
			continue
		# Reproiectare (banda de autocar): franarea/coada de mai jos sunt
		# contractul VECHI (mode STOP). Pe LANE (implicit), AI-ul nu se opreste
		# niciodata la semafor — vezi `_signal_lane_keep` pentru regula noua.
		if sig.mode != TunnelSignalHazard.Mode.STOP:
			continue
		var key := sig.get_instance_id()
		if not _signal_index.has(key):
			_signal_index[key] = track.closest_index_global(
				sig.ai_decision_point(), car.route)
		var d_idx: int = int(_signal_index[key]) - car.road_index
		if d_idx < -n_pts / 2:
			d_idx += n_pts
		elif d_idx > n_pts / 2:
			d_idx -= n_pts
		var along := float(d_idx) * bake
		# SIGNAL_STOP_LEAK_M: o masina care franeaza spre 0 nu se opreste chiar
		# PE linie — mai are cativa metri de elan cand indexul ei trece de
		# punctul de decizie (masurat: 2-4 m/s la 1-2s de rosu ramas, adica
		# exact "along" trecand de 0 inainte ca viteza sa fi ajuns la zero).
		# Fara marja, `_signal_block_m` sare la INF EXACT in clipa cand mai
		# conteaza, gazul se elibereaza, si masina "se scurge" peste linie cat
		# inca e rosu. Cat ramane rosu, un mic exces sub linie tot conteaza
		# blocat — nu schimba nimic pentru masinile normale (care se opresc
		# mult inainte de linie), doar prinde coada franarii.
		if along < -SIGNAL_STOP_LEAK_M or along > TunnelSignalHazard.AI_REACH_M \
				or along >= best:
			continue
		var eta := maxf(along, 0.0) / maxf(speed, 6.0)
		# Aceeasi marja ca la usa: un pilot care franeaza pe viraj ajunge mai
		# tarziu decat `along / speed` — se intreaba si peste inca o secunda.
		var arrives_on_red := sig.blocks_in(eta) or sig.blocks_in(eta + DOOR_ETA_SLACK) \
			or (along < 0.0 and sig.is_red())
		# Runda 3, punctul 3: „intru doar daca pot iesi" devine CONSERVATOR.
		# Runda 2 folosea `max(speed, 10)` — un PLAFON DE JOS, care presupunea
		# optimist ca o masina rapida la decizie ramane rapida tot tunelul.
		# Masurat: 7-9 contacte-pe-verde/seed (ar trebui 0) — exact simptomul
		# unei mașini care a decis "ies la timp" pe viteza de pe apropiere
		# (25-30+ m/s), dar incetineste real in tunel (banda uda, coridorul pe
		# dreapta, coada) sub cat presupusese la intrare.
		# Fix: PLAFON DE SUS la 18 m/s — viteza REALA in tunelul ud si in
		# coridorul ingust nu trece de-atat, indiferent cat de repede vine
		# masina pe apropiere. `min(speed, 18)`, nu `max(speed, 10)`: o masina
		# la 30 m/s pe apropiere e tratata ca 18 in tunel (conservator), una la
		# 8 m/s ramane la 8 (nu se umfla optimist la 10 ca inainte). Marja
		# crescuta la 2.0 s (de la 1.0), cerut explicit.
		# Doar la APROPIERE (along >= 0): o masina care a trecut deja linia e
		# angajata — nu mai are sens sa "decida" ca nu poate iesi cand e deja
		# in tunel (ar franao la mijloc, cu tunnel_length intreg in formula in
		# loc de distanta ramasa — mult mai periculos decat orice intarziere).
		var cant_clear := false
		if not arrives_on_red and along >= 0.0:
			var green_left_at_arrival := sig.green_seconds_left() - eta
			var cross_needed := sig.tunnel_length / minf(speed, 18.0) + 2.0
			cant_clear = green_left_at_arrival < cross_needed
		if arrives_on_red or cant_clear:
			best = along
	return best

## Runda 2, punctul 3: cat mai am pana la mașina OPRITA din fata mea, in coada
## de la semafor — INF daca nu e nicio mașina oprita in fata (pe raza de
## `SIGNAL_BRAKE_M`, aceeasi fereastra ca semaforul insusi). Aplicat DOAR cat
## `signal_wait` e activ (vezi `update()`): tinta de frana devine
## `min(distanta_pana_la_linie, distanta_pana_la_masina_oprita - GAP)`, ca
## fiecare AI sa se opreasca in spatele celui dinaintea lui, nu doar in
## spatele liniei — coada se formeaza pe randuri, in loc sa se comprime prin
## impingere fizica (diagnosticul coordonatorului: asta era sursa reala a
## scurgerii peste linie, nu franarea proprie).
##
## Masurata pe AXA DRUMULUI (ca la `_avoid_line`), nu pe distanta euclidiana:
## intr-un tunel drept diferenta e mica, dar tiparul ramane consistent cu
## restul fisierului.
func _signal_queue_gap(idx: int) -> float:
	if traffic.is_empty():
		return INF
	var r := track.route_at(car.route)
	if r == null:
		return INF
	var n := r.count()
	var best := INF
	for other in traffic:
		if other == null or other == car or not is_instance_valid(other):
			continue
		if other.route != car.route:
			continue
		if other.horizontal_speed() >= SIGNAL_QUEUE_STOPPED_SPEED:
			continue # conteaza doar cele deja OPRITE -- o masina care inca se
			# apropie nu e "coada", e inca in propria ei franare
		var d := other.road_index - idx
		if r.closed:
			if d > n / 2:
				d -= n
			elif d < -n / 2:
				d += n
		var ahead_m := float(d) * track.curve.bake_interval
		if ahead_m <= 0.0 or ahead_m > SIGNAL_BRAKE_M:
			continue
		best = minf(best, ahead_m)
	if best == INF:
		return INF
	return maxf(best - SIGNAL_QUEUE_GAP_M, 0.0)

func _lookahead_near(speed: float) -> float:
	return clampf(speed * LOOKAHEAD_NEAR_FACTOR,
		LOOKAHEAD_NEAR_MIN, LOOKAHEAD_NEAR_MAX)

func _lookahead_far(speed: float) -> float:
	return clampf(speed * LOOKAHEAD_FAR_FACTOR,
		LOOKAHEAD_FAR_MIN, LOOKAHEAD_FAR_MAX)

func _angle_to(fwd: Vector3, point: Vector3) -> float:
	var to_point := point - car.global_position
	to_point.y = 0.0
	if to_point.length_squared() < 0.001:
		return 0.0
	return fwd.signed_angle_to(to_point.normalized(), Vector3.UP)

# ------------------------------------------------------------- anti-blocaj

## Progresul se masoara pe TRASEU (indexul de pe curba), nu in metri parcursi:
## o masina care se invarte pe loc sau se freaca de un perete macina metri fara
## sa avanseze in cursa.
func _watch_progress(delta: float, speed: float) -> void:
	_hook_respawn()
	if _unstick_timer > 0.0:
		return
	# Asteptarea in fata usii de piatra e progres zero DELIBERAT, nu blocaj:
	# altfel plasa de stall ar porni marsarierul dupa 0.9 s si, dupa trei
	# incercari, repunerea — adica exact ce evita asteptarea.
	if _door_block_m < DOOR_BRAKE_M:
		_reset_progress()
		return
	# Acelasi scutire pentru asteptarea la semafor: altfel dupa 0.9 s de rosu
	# AI-ul ar incepe manevra de deblocare (marsarier virat) STAND la linie,
	# ar rata verdele care oricum vine, si dupa 3 incercari s-ar repune singur
	# — exact defectul pe care semaforul cu iesire nu trebuie sa-l aiba.
	if _signal_block_m < SIGNAL_BRAKE_M:
		_reset_progress()
		return
	# Si asteptarea in coloana la poarta ingustata (`_alley_gate_follow`):
	# masina din fata isi face singura manevra; a noastra doar asteapta.
	if _gate_hold:
		_reset_progress()
		return
	# Plasa rapida: izbitura frontala care opreste masina pe loc.
	if speed < STALL_SPEED:
		_stall_time += delta
		if _stall_time > STALL_TIME:
			_begin_unstick()
			return
	else:
		_stall_time = 0.0

	var n := track.baked.size()
	if _last_index < 0:
		_last_index = car.road_index
		_last_route = car.route
	# Schimbarea de ruta reindexeaza masina complet: indexul de pe scurtatura
	# n-are nicio relatie cu cel de pe bucla principala. Fara resetarea asta,
	# saltul s-ar citi ca "n-a avansat deloc" (sau ca mers inapoi), iar AI-ul
	# ar intra in manevra de deblocare exact in clipa in care tocmai a intrat
	# pe scurtatura — apoi, dupa trei incercari, s-ar repune singur.
	if car.route != _last_route:
		_last_route = car.route
		_last_index = car.road_index
		_progress_timer = 0.0
		_progress_m = 0.0
		return
	var d := car.road_index - _last_index
	if d > n / 2:
		d -= n
	elif d < -n / 2:
		d += n
	_last_index = car.road_index
	_progress_m += float(d) * track.curve.bake_interval
	_progress_timer += delta
	if _progress_timer < PROGRESS_WINDOW:
		return
	if _progress_m < PROGRESS_MIN_M:
		_begin_unstick()
	else:
		_attempts = 0 # merge cursa; uitam incercarile vechi
	_reset_progress()

## Repunerea muta masina pe traseu (inapoi, uneori zeci de metri — vezi
## `Track.ai_progress_reset_on_respawn`). Fereastra de progres de dinainte nu
## mai spune nimic despre masina de acum: se incepe una noua, fara incercarile
## vechi si fara o manevra de deblocare ramasa pe jumatate. Doar pe pistele
## care cer asta; in rest semnalul nici nu se leaga.
var _respawn_hooked: bool = false

func _hook_respawn() -> void:
	if _respawn_hooked or car == null or track == null:
		return
	_respawn_hooked = true
	if track.ai_progress_reset_on_respawn:
		car.respawned.connect(_on_car_respawned)

func _on_car_respawned(_c: Car) -> void:
	_unstick_timer = 0.0
	_unstick_reversing = false
	_attempts = 0
	_reset_progress()

func _reset_progress() -> void:
	_progress_timer = 0.0
	_progress_m = 0.0
	_stall_time = 0.0
	_last_index = car.road_index if car != null else -1

func _begin_unstick() -> void:
	_reset_progress()
	_attempts += 1
	if _attempts > MAX_ATTEMPTS:
		# Am incercat cinstit si tot suntem infipti — cerem repunerea.
		_attempts = 0
		_unstick_timer = 0.0
		# Runda 3, punctul 2: diagnostic optional (AI_UNSTICK_TRACE=1), ca sa
		# se poata deosebi „paznicul de progres a cerut repunerea" de o
		# RespawnZone (cascada Stirling, canalul Bowen, mare/rau) — semnalul
		# `respawned` nu duce cine a chemat-o. Raporteaza si starea celui mai
		# apropiat semafor din fata: daca e rosu sau la cate secunde de la
		# ultimul verde, ca sa se vada daca masina statea intr-o coada legitima
		# la semafor cand paznicul a decis ca "nu progreseaza".
		if OS.get_environment("AI_UNSTICK_TRACE") == "1":
			var frac := track.frac_at(car.road_index, car.route) \
				if track != null else -1.0
			var sig_state := "fara semafor in grup"
			for node in get_tree().get_nodes_in_group(TunnelSignalHazard.AI_GROUP):
				var sig := node as TunnelSignalHazard
				if sig == null:
					continue
				sig_state = "rosu" if sig.is_red() else \
					"verde(%.1fs ramase)" % sig.green_seconds_left()
				break
			print("[unstick-respawn] %s frac=%.3f pos=(%.0f,%.0f,%.0f) semafor=%s"
				% [car.pilot_name, frac, car.global_position.x,
					car.global_position.y, car.global_position.z, sig_state])
		car.respawn()
		return
	# Directia in care trebuie sa ajunga botul: spre centrul soselei, in fata.
	var fwd := -car.global_transform.basis.z
	fwd.y = 0.0
	var to_center := _angle_to(fwd.normalized(),
		track.lookahead_point(car.road_index, 8.0, 0.0, car.route))
	# Semnul de virare cand mergem INAINTE. Zero (perfect aliniati) tot trebuie
	# sa devina o alegere, altfel manevra iese in linie dreapta inapoi in acelasi
	# obstacol — exact bucla pe care o reparam.
	_unstick_steer = signf(to_center) if absf(to_center) > 0.05 else 1.0
	_unstick_reversing = true
	_unstick_timer = REVERSE_TIME

func _drive_unstick(delta: float) -> void:
	_unstick_timer -= delta
	_drift = false
	_turbo = false
	if _unstick_reversing:
		_throttle = -1.0
		# In marsarier, Car inverseaza efectul virajului (reverse_sign), deci
		# semnul se inverseaza si aici ca botul sa plece TOT spre centru.
		_steer = -_unstick_steer
		if _unstick_timer <= 0.0:
			_unstick_reversing = false
			_unstick_timer = RECOVER_TIME
	else:
		_throttle = 1.0
		_steer = _unstick_steer
		if _unstick_timer <= 0.0:
			_reset_progress()

func get_steer() -> float:
	return _steer

func get_throttle() -> float:
	return _throttle

func is_drift_pressed() -> bool:
	return _drift

func is_turbo_pressed() -> bool:
	return _turbo


## Poarta ingustata a unei benzi (`AlleyGate`, ulicioara Jodhpur): golul are
## 4 m, masina 2,1, deci marja e +-0,95 m. Linia de cursa obisnuita (pana la
## +-LINE_MAX din semilatimea benzii de 3,2 = +-2,56 m) ducea masina cu
## 1-1,5 m langa axa si botul la 8-13 grade: masurat pe 16 seed-uri, 10
## ejectari de perete, toate pe stalpii portii. Pe ultimii
## ALLEY_GATE_APPROACH_M inainte de poarta si pana la ALLEY_GATE_AFTER_M dupa,
## linia se strange pe axa, la (golul - jumatatea caroseriei - marja) din
## semilatimea benzii. Doar pe benzile care AU poarta (Track.branch_gate).
const ALLEY_GATE_APPROACH_M: float = 25.0
const ALLEY_GATE_AFTER_M: float = 6.0
const ALLEY_GATE_MARGIN_M: float = 0.3

## Linia stransa singura nu ajunge (masurat, runda 2): masina iese din curba
## buclei pe dreapta benzii (+1,5 m) si, cu tinta de urmarire la 15-20 m in
## fata, corecteaza prea incet — ajunge la poarta tot la +1,4 m. Pe fereastra
## de apropiere tinta devine punctul de pe AXA benzii chiar dupa poarta, deci
## unghiul de corectie creste pe masura ce poarta se apropie.
const ALLEY_GATE_AIM_T: float = 0.55
const ALLEY_GATE_AIM_MIN_M: float = 6.0
const ALLEY_GATE_AIM_MAX_M: float = 14.0

## Viteza maxima pe apropierea portii ingustate (m/s). Masurat (runda 2):
## AI-ul ajungea la poarta cu 25-35 m/s si nu mai avea timp sa corecteze
## +1,5 m din curba buclei in cei ~14 m dintre comutare si poarta.
const ALLEY_GATE_SPEED: float = 15.0
var _alley_approach: bool = false

func _alley_gate_aim_on(route: int, idx: int, near: Vector3) -> Vector3:
	var gate := track.branch_gate(route)
	if gate == null:
		return near
	var r := track.route_at(route)
	if r == null or r.dists.is_empty():
		return near
	var d: float = r.dists[clampi(idx, 0, r.dists.size() - 1)]
	var gd := float(gate.gate_dist_m)
	if d < gd - ALLEY_GATE_APPROACH_M or d > gd:
		return near
	_alley_approach = true
	# Urmarire pura pe AXA benzii, cu distanta de tinta proportionala cu
	# viteza (stabila: o tinta fixa dupa poarta oscila +-1,4 m, masurat).
	var aim_d := d + clampf(car.horizontal_speed() * ALLEY_GATE_AIM_T,
		ALLEY_GATE_AIM_MIN_M, ALLEY_GATE_AIM_MAX_M)
	var j := idx
	while j < r.baked.size() - 1 and r.dists[j] < aim_d:
		j += 1
	return r.baked[j]


## Coloana la poarta ingustata (runda 3, POI D Jodhpur): ultimul [blocaj]
## ramas pe ulicioara era a doua masina (autobuz) care intra in poarta de 4 m
## peste prima, deja lenta sau blocata in ea — doua caroserii de 2,2+ m intr-un
## gol in care incape una. Pe fereastra portii (ALLEY_GATE_APPROACH_M inainte,
## ALLEY_FOLLOW_EXIT_M dupa), viteza-tinta se leaga de masina din fata de pe
## ACEEASI banda: viteza ei plus un termen proportional cu golul peste
## ALLEY_FOLLOW_GAP_M; sub ALLEY_FOLLOW_STOPPED_SPEED se opreste la gol.
## AI onest: citeste doar pozitia si viteza masinii din fata, pe care un sofer
## le vede. Doar pe benzile care AU poarta (`Track.branch_gate`), deci pe
## pistele fara `AlleyGate` intoarce mereu INF.
const ALLEY_FOLLOW_GAP_M: float = 9.0
const ALLEY_FOLLOW_EXIT_M: float = 10.0
const ALLEY_FOLLOW_REACH_M: float = 35.0
const ALLEY_FOLLOW_K: float = 0.8
const ALLEY_FOLLOW_STOPPED_SPEED: float = 3.0
var _gate_hold: bool = false

func _alley_gate_follow(idx: int) -> float:
	if traffic.is_empty():
		return INF
	var gr := car.route
	if gr == 0:
		if not _alley_approach:
			return INF
		gr = 1
	var gate := track.branch_gate(gr)
	if gate == null:
		return INF
	var r := track.route_at(gr)
	if r == null or r.dists.is_empty():
		return INF
	var gd := float(gate.gate_dist_m)
	var my_d: float
	if car.route == gr:
		my_d = r.dists[clampi(idx, 0, r.dists.size() - 1)]
	else:
		var bi := r.closest_index_global(car.global_position)
		my_d = r.dists[bi]
		if bi == 0:
			my_d = -car.global_position.distance_to(r.baked[0])
	if my_d < gd - ALLEY_GATE_APPROACH_M or my_d > gd + ALLEY_GATE_AFTER_M:
		return INF
	var cap := INF
	for other in traffic:
		if other == null or other == car or not is_instance_valid(other):
			continue
		if other.route != gr:
			continue
		var od: float = r.dists[clampi(other.road_index, 0, r.dists.size() - 1)]
		if od > gd + ALLEY_FOLLOW_EXIT_M:
			continue
		var gap := od - my_d
		if gap <= 0.0 or gap > ALLEY_FOLLOW_REACH_M:
			continue
		var room := maxf(gap - ALLEY_FOLLOW_GAP_M, 0.0)
		var v := other.horizontal_speed()
		if v < ALLEY_FOLLOW_STOPPED_SPEED:
			cap = minf(cap, room * 1.2)
		else:
			cap = minf(cap, v + room * ALLEY_FOLLOW_K)
	return cap


func _alley_gate_line(idx: int, line: float) -> float:
	if car.route == 0:
		return line
	var gate := track.branch_gate(car.route)
	if gate == null:
		return line
	var r := track.route_at(car.route)
	if r == null or r.dists.is_empty():
		return line
	var d: float = r.dists[clampi(idx, 0, r.dists.size() - 1)]
	var gd := float(gate.gate_dist_m)
	if d < gd - ALLEY_GATE_APPROACH_M or d > gd + ALLEY_GATE_AFTER_M:
		return line
	var half_body := 1.05
	if car.data != null:
		half_body = car.data.body_width * 0.5
	var room := maxf(float(gate.half_opening_m) - half_body - ALLEY_GATE_MARGIN_M, 0.0)
	var k := room / maxf(r.half_width, 0.1)
	return clampf(line, -k, k)
