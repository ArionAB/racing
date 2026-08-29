@tool
class_name RotatingSpanHazard
extends Node3D
## Pasajul rotativ din nodul Huangjuewan (Chongqing, brief §2 POI F si §3):
## un tronson de 12 m pe pivot central care se roteste, pe ciclu de ~25 s,
## intre DESCHIS (continua rampa) si INCHIS (te trimite pe rampa de serviciu).
##
## [b]Tiparul e al lui [LiftBridgeHazard][/b] — ceas propriu, telegraph inainte
## de comutare, o bucata de sosea care nu mai e acolo — cu doua diferente care
## conteaza:
##
##  1. [b]Se roteste, nu se ridica.[/b] Traveea de pe Okinawa urca DREPT si
##     lasa golul curat de la apa pana la cer, fiindca acolo golul e o
##     SARITURA: cine are viteza trece pe sub ea. Aici golul nu e o saritura,
##     e o DEVIERE — deci tronsonul se intoarce pe orizontala si ramane in
##     cadru, la 90°, ca sa se vada de departe ca pasajul nu se continua.
##  2. [b]Pedeapsa e +3 s, nu inotul.[/b] Brief §3: „inchis -> rampa de
##     serviciu (+3 s)". Golul deschis NU are voie sa fie o capcana mortala,
##     deci hazardul construieste el insusi ocolul: o rampa de serviciu care
##     face un cot in jurul golului si se intoarce pe pasaj dupa el, plus o
##     linie de bariere de santier (`construction_barrier.glb`) care inchide
##     banda directa cat tine ciclul. Cine ignora si semaforul, si barierele,
##     e SCOS pe ocol de ele — nu cade, si nu ramane in ele. Linia e oblica,
##     lunecoasa si imbranceste lateral (`gate_push`), fiindca un zid frontal
##     de bariere nu costa +3 s, ci sfarsitul cursei: criticul a masurat +18.7
##     s la prima versiune, cu masina in noua cicluri de marsarier.
##
## [b]Ce construieste nodul[/b] (tot, fara sa ceara nimic pistei): rampa de
## acces, pasajul de pe cele doua buze, golul, tronsonul rotitor, rampa de
## serviciu cu cotul ei, poarta de bariere si semaforul. Se trage in scena
## pistei ca [CablewayHazard] — un nod cu @export-uri — fiindca gimmickul are
## GEOMETRIE proprie (un gol in carosabil), iar un `HazardMarker` declara doar
## o fractie: pista ar fi trebuit sa stie sa taie o gaura in asfalt.
##
## [b]Cotele modelului nu se ghicesc[/b] (`tools/probe_cq_dims.gd`):
## `rotating_span.glb` are carosabilul la y = +0.17 fata de origine, latimea
## 6.82 m si lungimea 11.84 m. De aia `SPAN_DECK_TOP` exista: modelul se
## coboara cu atat ca suprafata lui sa cada exact pe pasajul construit aici.

const WorldProp = preload("res://scenes/props/world_prop.gd")
const SPAN_MODEL: String = "res://assets/models/chongqing/structures/rotating_span.glb"
const BARRIER_MODEL: String = "res://assets/models/chongqing/props/construction_barrier.glb"
## Cota carosabilului in modelul tronsonului. Nu e ghicita si nu e capatul de
## sus al modelului: e planul orizontal cu cea mai mare ARIE din banda
## centrala — 82.7 m2 la y = -0.17, adica exact 6.9 x 12 m de asfalt.
## Modelul se RIDICA cu atat ca suprafata lui sa cada pe pasajul construit
## aici. (Prima versiune avea +0.17, cota bordurii, si cu semnul invers:
## masina ar fi mers la 34 cm deasupra asfaltului desenat.)
const SPAN_DECK_Y: float = -0.17
## Bordurile modelului: doua praguri la x = +/-3.25, cu 0.34 m peste carosabil.
## Intra si in colizor, nu doar in imagine — cand tronsonul e pe pozitie, ele
## sunt singurul lucru dintre masina si golul de pe langa el (deck-ul are
## parapeti, dar peste gol nu se poate construi nimic fix).
const SPAN_KERB_X: float = 3.25
const SPAN_KERB_HEIGHT: float = 0.34
const SPAN_KERB_WIDTH: float = 0.5
## Latimea barierei de santier din GLB, pentru cate bucati intra pe poarta.
const BARRIER_WIDTH: float = 2.4
## Grosimea pasajului si a rampei de serviciu.
const DECK_THICK: float = 0.55
## Cat de sus sta carosabilul modulului peste axa citita din ruta, LA MIJLOC (m).
##
## [b]De ce e nevoie de el.[/b] Coloana citeste axa rutei, care e linia
## MEDIANA a soselei, nu fata ei de sus; in plus modulul isi taie placile in
## coarde de doi metri peste o curba. Suma celor doua a fost masurata: pe
## jumatatea din aval a modulului tablierul iesea intre 0.00 si 0.18 m SUB
## asfaltul pistei, deci raza rotii dadea in sosea, iar tablierul construit
## acolo nu se atingea niciodata — modulul exista pe hartie si nu exista sub
## roata.
##
## [b]De ce e STINS la capete.[/b] O ridicare uniforma muta problema in loc
## s-o rezolve: masurat, cu 0.22 m pe toata lungimea intrarea pe modul devenea
## un prag de 0.33 m — adica exact un zid, dupa memoria
## `suprafete-cu-goluri-si-praguri` (peste 0.3 m). Ridicarea se stinge deci
## liniar pe ultimii `SPINE_LIFT_FADE` metri de la fiecare capat: la mijloc
## tablierul e deasupra soselei si e el suprafata de rulare, la capete cade
## exact pe ea si racordul e o panta de sub un procent, nu o treapta.
const SPINE_LIFT: float = 0.06
## Pe cati metri de la fiecare capat al modulului se stinge ridicarea (m).
## 12 m la 0.20 m inseamna o panta de racord de 1.7% — sub panta soselei
## insesi (3.7% aici), deci invizibila la volan.
const SPINE_LIFT_FADE: float = 12.0
## Cat de sus sta marcajul peste asfalt (m). Suficient cat sa nu se bata cu
## placa (memoria `suprafete-suprapuse-si-valuri`: offsetul se DERIVA, si aici
## nu exista valuri, doar o placa plana), prea putin cat sa fie o treapta.
const MARK_LIFT: float = 0.03
## Latimea axei intrerupte si a bordurii de pe marginile carosabilului (m).
const MARK_WIDTH: float = 0.20
const KERB_WIDTH: float = 0.45
## Lungimea unei liniute de ax si a golului dintre ele (m). Aceleasi cifre ca
## pe soseaua principala, ca modulul sa nu se citeasca drept alt drum.
const DASH_ON: float = 3.0
const DASH_OFF: float = 4.0
## Cat de des se esantioneaza rampa de serviciu (m). Sub un metru cotul ei e
## neted; peste doi, imbinarile dintre placi devin praguri (memoria
## `suprafete-din-placi-plane`).
const SERVICE_STEP: float = 1.2
## Lampile de lucru ale modulului: cat de sus, la ce interval, cat de departe
## bat si cu ce culoare. Aceleasi cifre ca felinarele nodului din `.tscn`
## (energie 3.6, raza 19), ca modulul sa nu se citeasca drept alta lume.
const WORK_LIGHT_HEIGHT: float = 6.5
const WORK_LIGHT_STEP: float = 12.0
const WORK_LIGHT_RANGE: float = 19.0
const WORK_LIGHT_ENERGY: float = 3.6
const WORK_LIGHT_COLOR: Color = Color(1.0, 0.784, 0.549)
## Cati metri de pasaj mai raman fara parapet DUPA capatul ocolului, pe partea
## pe care el se intoarce in banda directa.
##
## [b]Zero de cand ocolul e facut din arce.[/b] Marginea de scurgere a existat
## pentru valul de sinus, care se reintorcea in banda sub 35° si ajungea pe
## pasaj inca la 4 m de axa: parapetul reincepea exact in capatul ocolului,
## si sonda masurase masina oprita in el la z=-18. Arcele se inchid TANGENT,
## deci masina e deja paralela cu banda si la 1.5 m de axa cand ocolul se
## termina — n-are ce sa mai atinga.
##
## Si nu e o curatenie estetica: cati metri de scurgere lasi, atatia metri de
## buza de pasaj raman fara parapet SI fara rampa alaturi, adica o cadere de
## 3 m fara nimic in fata ei. Masurat in aceeasi sesiune, pe o varianta cu
## palier: masina scoasa din al doilea cot a plecat lateral si a cazut exact
## acolo, y = -0.12, la 2 m dincolo de capatul ocolului.
const MERGE_RUNOUT: float = 0.0
## Cat de larga are voie sa fie pana dintre buza pasajului si marginea dinspre
## drum a ocolului inainte sa fie INCHISA cu parapet in loc sa fie UMPLUTA cu
## beton (m).
##
## Pana aia e triunghiul dintre banda directa si rampa care se desprinde din
## ea — la un nod rutier adevarat e pavat, si se numeste „gore". Aici nu e
## realism gratuit, e singura reparatie care tine: fara el, masina scoasa de
## poarta ajunge exact INTRE cele doua parapete (al pasajului, la 3.6 m, si al
## ocolului, care fuge in lateral cu ~40°) si intra intr-un fund de sac care
## se ingusteaza in fata ei. Sonda a masurat-o acolo, 32 s, zbatandu-se intre
## „fata-dr(ServiceRamp)" si „dr(Deck)". Cu triunghiul pavat, acelasi loc e
## asfalt: masina calca pe el si intra pe ocol virand, nu manevrand.
##
## Dincolo de latimea asta pana chiar e o gaura de 3 m, si acolo se pune
## parapetul — botul de beton dintre banda si rampa, ca in realitate.
const GORE_MAX: float = 12.0

## De la cati metri INAINTEA PORTII incepe pilotul sa mute linia.
##
## [b]Se masoara de la poarta, nu de la nod, si asta a fost chiar bugul.[/b]
## Prima versiune copia cifra de la gheizere (34 m) si o masura fata de
## `global_position` — dar la gheizere nodul E hazardul, pe cand aici nodul e
## la mijlocul golului, iar linia de bariere sta cu `_lip_near() + service_lead`
## (42 m masurati pe Track12) mai in amonte. Cu 46 m de la nod, pilotul incepea
## sa se mute la 4 m de bariere, cu mutarea abia schitata de estompare: adica
## exact blocajul pe care trebuia sa-l repare, doar cu cod in plus.
##
## [b]90 m, nu 30, si cifra se deriva din TIMP, nu din geometrie.[/b] 30 m era
## lungimea pe care ocolul se desprinde de banda (`service_lead`) — corect ca
## descriere a rampei, gresit ca fereastra de decizie. Pe Track12
## `bake_interval` e 3 m, deci 30 m inseamna 10 pasi de index, adica [b]1.1 s
## la 28 m/s[/b]: mai putin decat ii trebuie unei singure masini sa treaca de
## pe axa pe ocol, si mult mai putin decat ii trebuie unui pluton de sase s-o
## faca pe rand.
##
## Pretul a fost masurat pe pista reala, cu ProbeRace: masinile ajungeau la
## linia de bariere inca pe axa, se opreau in ea (`lat` 5.0-6.2, adica
## imbrancite in marginea de afara) si se ingramadeau unele in altele — patru
## repuneri pe un singur seed, toate in frac 0.733-0.739, plus blocaje in
## serie pe aceeasi felie.
##
## Fereastra se alege deci in secunde: ~3 s la viteza de croaziera a nodului
## (~30 m/s) inseamna 90 m. Sunt trei secunde in care mutarea e progresiva
## (`lerp` dupa distanta, ca la gheizere), deci nu smuceste volanul departe si
## e completa cand conteaza.
const AI_REACH_M: float = 90.0

## Grupul din care AI-ul isi ia pasajele, fara sa caute prin arbore.
## Conventia de la `fireball_geysers`.
const AI_GROUP: StringName = &"rotating_spans"

enum State {
	OPEN,           ## tronsonul continua pasajul
	TURNING_SHUT,   ## se roteste spre inchis
	SHUT,           ## pasajul e intrerupt, banda directa e barata
	TURNING_OPEN,   ## se roteste inapoi
}

# ------------------------------------------------------------------- ritm

@export_group("Ritm")
## Ciclul complet (s). Brief: ~25, si NU divizor al turului.
@export_range(6.0, 120.0, 0.5) var period: float = 25.0
## Cat dureaza o rotatie, intr-un sens (s). Din el si din `period` ies cele
## doua rastimpuri de asteptare, egale.
@export_range(0.5, 20.0, 0.1) var turn_time: float = 4.0
## Cu cat inainte de fiecare rotatie se aprinde galbenul (s). Brief: 3.
@export_range(0.0, 10.0, 0.1) var telegraph_lead: float = 3.0
## Decalajul ciclului (0..1 din period).
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0
## Merge ceasul? Stins, tronsonul si poarta INGHEATA unde sunt — dar tot restul
## lucreaza mai departe: senzorul portii si ghiontul care te scoate pe ocol.
##
## Exista pentru sonde, si distinctia nu e un moft. Intrebarea „se descurca
## cine a intrat in bariere?" trebuie pusa cu pasajul inchis, altfel ciclul se
## redeschide sub masina si sonda masoara o plimbare printr-un nod fara
## obstacol. Prima versiune obtinea inghetul stingand `_physics_process`, ceea
## ce stingea si palnia — adica testul cel mai important rula pe un hazard
## caruia tocmai i se scosese mecanismul de scapare.
@export var clock_running: bool = true
## Cat se roteste tronsonul cand se inchide.
@export_range(15.0, 180.0, 1.0) var closed_angle_deg: float = 90.0

# -------------------------------------------------------------- geometrie

@export_group("Pasaj")
## Semilatimea carosabilului. Implicitul 3.4 e latimea modelului (6.82 m),
## care e si latimea POI-ului F din brief (7 m).
@export_range(2.0, 12.0, 0.1) var road_half_width: float = 3.4
## Lungimea golului = lungimea tronsonului (m).
@export_range(4.0, 30.0, 0.1) var span_length: float = 11.84
## Cat pasaj construieste hazardul dincolo de fiecare buza (m).
## Nu poate fi mai mic decat `service_lead`: ocolul se desprinde de pe pasaj,
## deci pasajul trebuie sa ajunga pana acolo.
@export_range(4.0, 60.0, 0.5) var deck_run: float = 34.0
## Cat de sus sta pasajul fata de originea nodului (m). Pe pista adevarata
## rampa e deja sus si asta ramane 0; in sonda ridica modulul deasupra
## soselei-test, ca golul sa fie gol.
@export_range(0.0, 30.0, 0.1) var deck_rise: float = 0.0
## Inaltimea parapetului de pe marginile pasajului (m). 0 = fara.
##
## Impreuna cu parapetul ocolului face din modul un CULOAR cu o singura
## iesire laterala — fereastra de desprindere a ocolului. Fara el, un pasaj
## inaltat are 40 m de margine deschisa de fiecare parte, si sonda a gasit
## imediat ce inseamna asta: masina oprita in poarta, cand a pornit iar, a
## iesit lateral pe langa banda de serviciu si a cazut 3 m in gol lateral.
@export_range(0.0, 2.0, 0.05) var deck_parapet: float = 0.9
## Lungimea rampelor care leaga pasajul de cota nodului. Ignorate la
## `deck_rise` = 0.
@export_range(2.0, 80.0, 0.5) var ramp_run: float = 24.0

@export_group("Rampa de serviciu")
## [b]Cele doua cifre de mai jos SUNT contractul de pedeapsa.[/b] Brief §3 si
## §2 randul F: „inchis -> rampa de serviciu (+3 s)". Pedeapsa NU se ia din
## franare impusa si nici dintr-o suprafata lenta pusa acolo doar ca sa manance
## timp — alea ar fi o taxa lipita peste gimmick, si jucatorul ar simti mana
## autorului. Se ia din DRUM: cotul iese mai departe si se strange mai tare,
## deci ridici piciorul si mergi mai mult.
##
## [b]De ce forma s-a schimbat (si de ce „mai lung" nu era raspunsul).[/b]
## Prima versiune era un val de sinus, 9 m lateral pe 40 m de z, si costa
## +1.90 s masurat — 63% din contract. Aritmetica spune de ce, si spune si ca
## nu se repara lungind ocolul. Un ocol parcurs la limita de aderenta costa
## `integrala ds / sqrt(a*R(s))`, iar pentru un val de sinus integrala aia iese
## `2.39 * sqrt(A/a)` — [b]nu depinde deloc de lungime[/b]: sinusul isi petrece
## metrii acolo unde e aproape drept si nu te incetineste. Cum linia dreapta
## de alaturi se lungeste si ea, un ocol de sinus mai lung costa MAI PUTIN,
## nu mai mult. Masurat exact asa: 9 m pe 40 m -> +1.90 s.
##
## Forma care chiar costa e cea cu [b]curbura constanta[/b]: trei arce de
## cerc (stanga φ, dreapta 2φ, stanga φ) in loc de val. Un arc te tine la
## `sqrt(a*R)` pe toata lungimea lui, nu doar in varf. La aceleasi gabarite
## (9 m pe 40 m) arcele dau R = 13.3 m in loc de 17.9 si +2.70 s in loc de
## +0.97 din model — aceeasi cutie, alt pret, fiindca timpul nu se cumpara cu
## metri, ci cu metri INTORSI.
##
## Raza si unghiul nu se mai regleaza separat: din `service_offset` (A) si din
## lungimea ocolului (`dz = 2*(span_length/2 + service_lead)`) ies singure
## `tan(φ/2) = 2A/dz` si `R = (dz^2 + 4A^2) / (16A)` — arcele cele mai LARGI
## care mai incap in cutia data. O raza mai mica ar incapea si ea (cu o
## portiune dreapta la mijloc), dar portiunea dreapta e exact locul in care
## masina accelereaza inapoi: o versiune cu palier a fost masurata in aceeasi
## sesiune si a iesit din al doilea cot cu 17 m/s, s-a invartit si a cazut de
## pe pasaj (y = -0.12). Palierul da timp la calcul si accidente pe pista.
##
## Pe ce parte ocoleste golul: +1 dreapta, -1 stanga sensului de mers.
@export_enum("Dreapta:1", "Stanga:-1") var service_side: int = 1
## Cat de departe iese cotul, masurat de la marginea pasajului (m).
@export_range(0.0, 40.0, 0.5) var service_offset: float = 24.0
## Latimea rampei de serviciu (m). Mai ingusta decat pasajul: si asta e o
## parte din pretul ocolului.
@export_range(3.0, 20.0, 0.1) var service_width: float = 5.0
## Cu cati metri inainte de buza se desprinde ocolul (si dupa cealalta buza
## se intoarce). Impreuna cu `service_offset` fixeaza raza arcelor (vezi mai
## sus). `deck_run` trebuie sa fie cel putin atat — ocolul se desprinde de pe
## pasaj, deci pasajul trebuie sa ajunga pana acolo.
@export_range(2.0, 60.0, 0.5) var service_lead: float = 30.0
## Cat din suma razelor primeste cotul de INTRARE (si cel de iesire), restul
## mergand la arcul din mijloc. 0.5 = trei arce cu aceeasi raza.
##
## [b]Nu e un reglaj de gust: cele doua capete ale ocolului au sarcini
## diferite.[/b] Cotul de intrare e locul in care se SCHIMBA BANDA — cu cat e
## mai larg, cu atat ocolul sta mai mult lipit de pasaj, fereastra de
## desprindere e mai lunga si linia de bariere are unde sa te scoata lin.
## Arcul din mijloc e cel care trece pe langa gol si care PLATESTE pedeapsa,
## deci il vrem stramt.
##
## Si nu costa nimic sa dai unuia din celalalt: suma razelor e fixata de cutie
## (`R1 + R2 = dz / (2 sin φ)`), deci fiecare metru dat cotului de intrare il
## ia arcul din mijloc, care se stramteaza si incetineste mai tare. Intrare
## blanda, mijloc stramt — amandoua in favoarea noastra.
##
## Cu 0.5 (trei arce egale) sonda a masurat si capatul celalalt al
## compromisului: mijlocul se largeste, pedeapsa scade, iar fereastra de
## desprindere se scurteaza atat incat masina imbrancita de poarta ramane in
## gura devierii.
@export_range(0.5, 0.9, 0.01) var service_entry_ratio: float = 0.58
## Inaltimea parapetului de pe marginile ocolului (m). 0 = fara.
##
## Nu e decor. Ocolul e o banda ingusta care iese in consola de pe un pasaj
## inaltat, iar prima rulare a sondei a aratat exact ce inseamna asta: masina
## a derapat pe exteriorul cotului, a cazut 3 m langa pasaj si a ramas
## intepenita in flancul lui — adica fix „capcana mortala" pe care contractul
## de pedeapsa (+3 s) o interzice. Parapetul face din ocol un CULOAR: te
## freci de el si pierzi secunde, nu turul.
@export_range(0.0, 2.0, 0.05) var service_parapet: float = 0.9

@export_group("Poarta")
## Cat de oblica e linia de bariere (grade). Oblica te ALUNECA spre ocol; pe
## zero e un zid frontal.
##
## [b]Ramane 22, si asta e o cifra masurata, nu prima care a parut buna.[/b]
## Prima reparatie a costului de +18.7 s a fost s-o urc la 38, pe ideea ca o
## linie mai oblica se aluneca mai bine. Sonda a aratat pretul: la 38° cutia
## rotita a barierei se intinde cu ~0.9 m mai mult in AMONTE si a inceput sa
## agate exact masina care lua ocolul corect — traversarea pe rampa de
## serviciu a sarit de la 7.02 la 23.37 s. Alunecarea o fac `gate_friction` si
## ghiontul tangential (`gate_push`); unghiul doar spune incotro.
@export_range(0.0, 60.0, 1.0) var gate_skew_deg: float = 22.0
## Cu ce viteza te scoate poarta spre ocol (m/s). Trebuie sa ramana SUB
## `gate_push_speed_max`, altfel alunecarea se opreste imediat ce a inceput
## (masina depaseste pragul si nu mai e ajutata) si iese o zvacnire, nu o
## alunecare.
##
## [b]Asta e diferenta dintre o palnie si un fund de sac.[/b] Geometria oblica
## singura nu ajunge: cauciucul se agata de linie, masina se opreste cu botul
## in ea, iar soferul (om sau AI) intra intr-o bucla de marsarier-si-inapoi —
## criticul a numarat noua cicluri si 18.33 s pana la desprindere. Barierele de
## santier sunt tabla pe ROTI: cine intra in ele le impinge si e deviat, nu
## zidit.
##
## Ghiontul e TANGENT LA LINIA DE BARIERE, adica in chiar planul ei, spre
## capatul dinspre ocol. Doua variante au fost masurate inainte si aruncate:
## un ghiont pur lateral muta masina din poarta intr-o pana intre pasaj si ocol
## (blocata 32 s la x = -5), iar unul tintit spre un punct de pe rampa cu 8-14 m
## in fata o scotea peste buza consolei (cazuta de pe pasaj, y = -0.08).
## Tangenta n-are cum sa faca niciuna: e chiar directia in care blocajul se
## ingusta.
@export_range(0.0, 25.0, 0.5) var gate_push: float = 4.5
## Peste viteza asta nu mai primesti ghiontul (m/s).
##
## Palnia e o iesire din BLOCAJ, nu un tobogan: cine trece pe langa bariere cu
## 20 m/s si-a facut treaba singur, iar un ghiont peste el ar fi un hazard
## invizibil care il muta de pe linia lui. Pragul e jos (viteza de om care
## merge pe jos) fiindca o varianta anterioara l-a pus la 9 si sonda a masurat
## pretul: masina care lua ocolul corect, dar incetinea in cot, primea ghiont
## dupa ghiont si iesea de pe consola la x = -16.
@export_range(0.0, 30.0, 0.5) var gate_push_speed_max: float = 6.0
## Frecarea colizorului portii. Aproape zero: barierele de santier sunt tabla
## pe roti, iar o linie oblica cu frecare normala te OPRESTE in loc sa te
## aluneca — vezi `gate_skew_deg`.
@export_range(0.0, 1.0, 0.01) var gate_friction: float = 0.05
## Cu cati metri DUPA desprinderea ocolului sta linia de bariere.
##
## [b]Se masoara de la desprindere, nu de la buza golului, si sta cat mai sus
## cu putinta.[/b] Multa vreme poarta a stat la capatul de JOS al ferestrei de
## desprindere — singurul loc in care ocolul se departase destul cat sa fie
## barata banda directa fara sa fie barat si el. Dar exact acolo ocolul se
## abate cu ~40° de la banda, iar o linie de bariere nu poate arunca o masina
## pe o rampa care fuge lateral mai repede decat poate ea vira: sonda a masurat
## masina oprita in gura devierii, cu 15-30 s pierdute in manevre.
##
## Sus, langa desprindere, ocolul se abate cu ~10° si masina aluneca pe el
## firesc. Ca sa poata sta acolo, poarta isi aduce cu ea si peretele lateral
## (`_build_gate_taper`), care e tot al PORTII — apare si dispare cu ciclul —
## si de aceea are voie sa stea peste banda directa, unde un parapet fix ar fi
## un zid permanent pe drum.
@export_range(0.5, 30.0, 0.5) var gate_lead: float = 6.0
## Cat poate intarzia inchiderea unei porti peste care sta o masina (s).
## Aceeasi usa cu senzor ca la telecabina: colizorul nu apare sub nimeni.
@export_range(0.0, 4.0, 0.05) var gate_hold_max: float = 1.5
## Cu cati metri se retrage linia de bariere de la marginea dinspre drum a
## rampei de serviciu (m) — adica cat de larga ramane gura devierii.
##
## Poarta si peretele ei lateral merg lipite de marginea ocolului, si „lipite"
## inseamna, pentru o masina de doi metri care intra virand, exact pe linia ei.
## Sonda a masurat pretul cand jocul a fost zero: masina care lua ocolul CORECT
## se freca de perete si cobora la 6.8 m/s prin gura devierii, adica pedeapsa
## nu mai venea din drum, ci dintr-un zid.
@export_range(0.0, 4.0, 0.1) var gate_clearance: float = 0.3
## Cat de GROS e colizorul portii (m). Nu e o alegere estetica, e o conditie
## de tunelare: la 30 m/s masina inainteaza 0.5 m intre doua cadre de fizica,
## iar un colizor de 0.5 m (cat barierele in sine) o lasa sa treaca prin el
## fara niciun contact — asa a picat prima rulare a sondei, cu masina iesita
## dincolo de gol cu poarta solida in urma ei. Peretele are deci grosimea a
## patru-cinci cadre de mers, invizibil in spatele barierelor.
@export_range(0.5, 6.0, 0.1) var gate_depth: float = 2.4

@export_group("Constructie")
@export var span_model: PackedScene = null
@export var barrier_model: PackedScene = null
@export_range(0.2, 3.0, 0.05) var model_scale: float = 1.0
## Slotul de paleta al STRUCTURII: parapete, borduri, grinzi.
@export_range(0, 31) var deck_slot: int = Palette.CONCRETE
## Slotul de paleta al SUPRAFETEI PE CARE SE CONDUCE — tablierul si ocolul.
##
## [b]De ce e separat de `deck_slot`.[/b] Amandoua stateau pe CONCRETE, si de
## pe traseu iesea exact reclamatia dezvoltatorului: „ce e gri inchis pare sa
## pluteasca deasupra soselei". Masurat pe apropiere (frac 0.74, sonda de
## proiectie): `ServiceMesh` umple [b]34.5% din ecran la 35 m[/b] — adica in
## dreptul nodului o treime din cadru e o placa de beton palida, fara marcaj,
## fara bordura, care nu se citeste nici ca drum, nici ca teren, ci ca o masa
## suspendata. Iar ocolul E DRUM: e ruta pe care mergi cand pasajul e inchis.
##
## Beton ramane ce chiar e beton (parapetele, grinzile). Ce se conduce primeste
## asfalt, cu bordura si axa peste el (`_deck_markings`), fiindca „e drum" se
## citeste din marcaj, nu din culoare.
##
## [b]Nu ASPHALT (5), si asta e o cifra, nu un gust.[/b] Prima incercare a pus
## tablierul pe slotul soselei si a schimbat un defect cu opusul lui: pe o
## pista de NOAPTE, cu tablierul sub cota drumului si fara felinar deasupra
## lui, luminanta 0.295 se citeste ca o gaura, nu ca o banda (captura
## `mark2_0.74`, jumatatea dreapta a cadrului neagra). Si nu e putin din el in
## cadru: razele trase prin pixelii din dreapta-jos (sonda `probe_cq_r2h`) dau
## in [b]Deck la 18-22 m[/b] — tablierul E masa care umple sfertul ala de
## ecran, nu terenul, cum aratase intai o sonda pe AABB (camera statea in
## cutia terenului, deci raspunsul ei era „terenul" oriunde ai fi tintit).
##
## ASPHALT_EDGE (0.405) sta in aceeasi familie — tot drum — dar cu un ton
## peste, cat sa se vada unde e placa; bordura de CONCRETE (0.745) da muchia,
## iar axul alb citirea de banda. Aceeasi unealta ca pe Stromboli (memoria
## `rock-dark-nu-pe-bazalt`): variatia de VALOARE in familie, nu o culoare
## noua si nu un slot in plus.
@export_range(0, 31) var road_slot: int = Palette.ASPHALT_EDGE
## Slotul suprafetei OCOLULUI.
##
## Nu acelasi cu al tablierului, si nu din estetica: pe o pista de noapte doua
## suprafete pe acelasi slot inchis se contopesc intr-o singura pata neagra —
## prima incercare a mutat exact asa placa de beton in gaura de intuneric
## (captura `mark_0.74`). Ocolul e drum, deci ramane in familia asfaltului, dar
## pe varianta TOCITA: mai deschis cu un ton, deci se citeste ca alta banda,
## nu ca un gol. Aceeasi unealta ca la Stromboli (memoria
## `rock-dark-nu-pe-bazalt`): variatia de VALOARE in aceeasi familie, nu o
## culoare noua.
##
## Ocolul ramane pe acelasi ton cu tablierul: sunt aceeasi suprafata de
## condus, iar ce le desparte sunt CHEVRONII de pe ocol si axul de pe tablier —
## marcaj, nu culoare. Doua tonuri diferite ar fi spus „alt material", cand de
## fapt e acelasi drum care se bifurca.
@export_range(0, 31) var service_slot: int = Palette.ASPHALT_EDGE
## Slotul bordurii de pe marginile suprafetei carosabile a modulului.
@export_range(0, 31) var kerb_slot: int = Palette.CONCRETE
## Coliziune si pe separatorul de pe mijlocul tronsonului (0.43 m inaltime in
## GLB). Stins implicit: pe un carosabil de 6.8 m ar taia pasajul in doua
## benzi de 3 m, iar memoria `suprafete-cu-goluri-si-praguri` spune ca un prag
## de peste 0.3 m e zid. Se aprinde cand pista chiar vrea doua sensuri.
@export var median_collision: bool = false

@export_group("Urmarirea traseului")
## Modulul isi indoaie geometria dupa AXA SOSELEI, in loc s-o intinda plan.
##
## [b]De ce exista.[/b] Nodul Huangjuewan e o SPIRALA: pe cei 80 m ai modulului
## soseaua urca 3 m si se abate lateral cu 5. Un modul plan pus acolo e o
## coarda peste un arc — la capete iese cu metri intregi langa carosabil, iar
## la intrare lasa un prag. Prima incercare de reparatie a fost sa se caute un
## loc PLAN pe spirala; nu exista niciunul (masurat pe tot intervalul F,
## cel mai bun avea inca 1 m de diferenta pe +/-14 m), si mutatul modulului
## acolo unde panta e mai mica l-a scos de pe etajul 3 cerut de brief.
##
## Cu urmarirea pornita, cotele si abaterea laterala se citesc din ruta la
## `_ready` si intra intr-o „coloana" (`_spine`): tot ce construieste nodul —
## tablier, ocol, marcaj, parapete, poarta, lampi — se aseaza pe ea. Frameul
## local ramane cel drept (z de-a lungul drumului, x lateral), deci NICIUNA
## din formulele de geometrie (arcele ocolului, pana pavata, fereastra portii)
## nu se schimba: ele lucreaza mai departe in (x, z), iar coloana le duce la
## locul lor in lume.
##
## Stins, modulul ramane plan — asa il vrea sonda, care il pune pe o
## sosea-test dreapta si orizontala.
@export var follow_route: bool = false
## Ruta pistei pe care se muleaza modulul (0 = banda principala).
@export_range(0, 4) var follow_route_index: int = 0

## Coloana: pentru fiecare z local esantionat, abaterea laterala si cota
## soselei, in coordonatele nodului. Goala = modul plan.
var _spine: PackedVector2Array = PackedVector2Array()
## Pasul si capatul din amonte al coloanei (m, z local).
var _spine_step: float = 2.0
var _spine_z0: float = 0.0

var _span: AnimatableBody3D
var _gate: StaticBody3D
var _gate_shape: CollisionShape3D
var _gate_shapes: Array[CollisionShape3D] = []
var _gate_zone: Area3D
var _gate_meshes: Array[Node3D] = []
var _lamp: HazardLamp
var _service_points: PackedVector3Array = PackedVector3Array()
## Departarea de axa (m) si z-ul local ale fiecarui punct de ocol, in frameul
## DREPT — singurele care mai raspund la „cat de departe de sosea e asta" dupa
## ce `_at` a indoit punctele. Vezi nota din `_build_service`.
var _service_mags: PackedFloat32Array = PackedFloat32Array()
var _service_zs: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0
var _started: bool = false
var _state: State = State.OPEN
var _gate_hold: float = 0.0


func _ready() -> void:
	add_to_group(AI_GROUP)
	if follow_route and not Engine.is_editor_hint():
		# [b]Asteapta pista, si asta nu e o precautie.[/b] Nodul e COPIL al
		# pistei, iar in Godot copiii primesc `_ready` INAINTEA parintelui —
		# adica inainte ca `Track._ready` sa fi apelat `rebuild()`, deci
		# inainte sa existe rutele coapte. Masurat: construit in `_ready`,
		# coloana iesea goala (`spine_size=0`), modulul se aseza plan si
		# jumatatea lui din aval ateriza cu un metru peste sosea.
		#
		# Un cadru de fizica intarziere e invizibil: pana la primul cadru
		# nimeni nu conduce inca prin nod.
		call_deferred("_build_module")
	else:
		_build_module()


func _build_module() -> void:
	_build_spine()
	_build_decks()
	_build_service()
	_build_span()
	_build_gate()
	_build_lamp()
	# DUPA `_build_service()`: sirul de pe ocol se aseaza pe punctele lui.
	_build_work_lights()
	_apply_cycle(0.0)


# ---------------------------------------------------------------- coloana

## Citeste axa soselei si o pastreaza ca abatere fata de frameul drept al
## nodului, pe toata amprenta modulului.
##
## [b]Se face O DATA, la `_ready`, si nu la fiecare cadru.[/b] Geometria
## modulului e statica: singurul lucru care se misca e tronsonul rotitor, si
## el se roteste in jurul pivotului lui. Ce se schimba aici e doar unde sunt
## asezate placile.
##
## Esantionarea merge pe INDECSII rutei, nu pe o cautare de proiectie: ruta e
## o spirala care trece de patru ori peste aceeasi amprenta xz, iar o cautare
## dupa cel mai apropiat punct ar putea sari pe alt etaj (memoria
## `pista-peste-pista`). Se pleaca de la indexul nodului si se merge in sus si
## in jos pe lista, exact ca masina.
func _build_spine() -> void:
	_spine = PackedVector2Array()
	if not follow_route or Engine.is_editor_hint():
		return
	var track := _find_track()
	if track == null:
		return
	var route := track.route_at(follow_route_index)
	if route == null or route.count() < 8:
		return
	var n := route.count()
	var here := route.closest_index_global(global_position)
	# Sensul rutei fata de sensul modulului: modulul merge spre -Z local.
	var fwd_local := -global_transform.basis.z
	var route_fwd := route.baked[(here + 1) % n] - route.baked[here]
	var forward_sign := 1.0 if route_fwd.dot(fwd_local) >= 0.0 else -1.0
	# Cat de departe trebuie sa ajunga coloana: capatul cel mai indepartat al
	# oricarei placi pe care o pune nodul.
	var reach := _lip_near() + maxf(deck_run, service_lead) + ramp_run + 8.0
	var step := 2.0
	var count := int(ceil(reach / step))
	var inv := global_transform.affine_inverse()
	var samples: Array[Vector2] = []
	# De la amonte (z pozitiv) spre aval (z negativ), ca `_spine_z0` sa fie
	# capatul de start si indexarea sa iasa crescatoare.
	for k in range(count, -count - 1, -1):
		var target_z := float(k) * step
		var p := _route_point_at(route, here, forward_sign, -target_z)
		var local := inv * p
		samples.append(Vector2(local.x, local.y))
	_spine_z0 = float(count) * step
	_spine_step = step
	var out := PackedVector2Array()
	for v in samples:
		out.append(v)
	_spine = out


## Pista de sub nod. URCA prin arbore, nu `get_parent()`: modulul poate sta
## sub un nod de organizare (tiparul de la `FireballGeyser._road_half`).
func _find_track() -> Track:
	var t: Track = null
	var n := get_parent()
	while n != null and t == null:
		t = n as Track
		n = n.get_parent()
	return t


## Punctul de pe ruta aflat la `along` metri IN FATA (pe sensul de mers) fata
## de indexul de plecare. Interpoleaza intre doi indecsi vecini.
func _route_point_at(route: TrackRoute, from_index: int, forward_sign: float,
		along: float) -> Vector3:
	var n := route.count()
	var spacing := route.length() / float(maxi(n, 1))
	var steps := along * forward_sign / maxf(spacing, 0.001)
	var base := int(floor(steps))
	var t := steps - float(base)
	var i0 := ((from_index + base) % n + n) % n
	var i1 := (i0 + 1) % n
	return route.baked[i0].lerp(route.baked[i1], t)


## Abaterea coloanei la un z local: (lateral, cota). Fara coloana, (0, 0).
func _spine_at(z: float) -> Vector2:
	if _spine.is_empty():
		return Vector2.ZERO
	var u := (_spine_z0 - z) / _spine_step
	var i0 := clampi(int(floor(u)), 0, _spine.size() - 1)
	var i1 := clampi(i0 + 1, 0, _spine.size() - 1)
	var t := clampf(u - float(i0), 0.0, 1.0)
	return _spine[i0].lerp(_spine[i1], t)


## Directia coloanei la un z local, in planul XZ al nodului (unitara).
## Pe modulul plan e chiar -Z.
func _spine_dir(z: float) -> Vector3:
	var d := 0.5
	var a := _spine_at(z + d)
	var b := _spine_at(z - d)
	var v := Vector3(b.x - a.x, 0.0, -2.0 * d)
	return v.normalized() if v.length_squared() > 1e-9 else Vector3.FORWARD


## Un punct al modulului, dus de pe frameul drept pe coloana.
##
## [b]`x` e o abatere PERPENDICULARA pe axa drumului, nu pe axa nodului.[/b]
## Pe un modul plan cele doua coincid; pe unul care urmeaza o curba, diferenta
## e chiar ce tine latimea benzii constanta prin viraj — masurat cu abaterea
## laterala pe amprenta modulului, care fara asta se ingusteaza cu cosinusul
## unghiului.
func _at(x: float, z: float) -> Vector3:
	if _spine.is_empty():
		return Vector3(x, deck_rise, z)
	var s := _spine_at(z)
	var dir := _spine_dir(z)
	var lat := Vector3(-dir.z, 0.0, dir.x)
	var p := Vector3(s.x, 0.0, z) + lat * x
	# [b]Cota se citeste de la statia PUNCTULUI, nu de la cea de plecare.[/b]
	# Pe o coloana curba, un punct impins cu `x` metri in lateral aluneca si
	# de-a lungul drumului — cu atat mai mult cu cat `x` e mai mare. Ocolul
	# iese 24 m in lateral, si masurat asa: cota lui venea de la statia
	# nedeplasata si iesea cu pana la 0.64 m PESTE tablier. Consecinta se
	# vedea in sonda transversala ca un prag de 0.98 m la frac 0.7345, offset
	# +1 m — un zid in mijlocul benzii, in care masina chiar s-a oprit
	# (13 -> 0.1 m/s in 1.5 s).
	#
	# `p.z` e chiar statia unde a ajuns punctul: coloana e parametrizata pe z
	# local, deci proiectia e gratuita.
	var s2 := _spine_at(p.z)
	return Vector3(p.x, deck_rise + s2.y + _spine_lift(p.z), p.z)


## Ridicarea tablierului la un z local: plina la mijloc, stinsa la capete.
##
## Capatul fata de care se stinge e cel mai APROPIAT capat de suprafata
## carosabila, nu capatul tablierului: ocolul se desprinde si se reintoarce cu
## `service_lead`, adica mai devreme decat se termina tablierul, iar masurat pe
## `deck_run` singur reintrarea pe ocol ramanea un prag de 0.21 m. Cu capatul
## ocolului luat in calcul, si el se aseaza pe sosea acolo unde o atinge.
func _spine_lift(z: float) -> float:
	if _spine.is_empty():
		return 0.0
	var lip := _lip_near()
	var end_z := lip + deck_run
	if service_offset > 0.01:
		end_z = minf(end_z, lip + service_lead)
	var d := end_z - absf(z)
	return SPINE_LIFT * clampf(d / SPINE_LIFT_FADE, 0.0, 1.0)


# --------------------------------------------------------------- ceasuri

## Cat sta nemiscat, in fiecare din cele doua capete ale ciclului.
func hold_time() -> float:
	return maxf((period - 2.0 * turn_time) * 0.5, 0.1)


func _phase_of(t: float) -> State:
	var hold := hold_time()
	if t < hold:
		return State.OPEN
	if t < hold + turn_time:
		return State.TURNING_SHUT
	if t < 2.0 * hold + turn_time:
		return State.SHUT
	return State.TURNING_OPEN


## Fractia de rotatie (0 = deschis, 1 = inchis) la momentul t din ciclu.
func _turn_fraction(t: float) -> float:
	var hold := hold_time()
	match _phase_of(t):
		State.OPEN:
			return 0.0
		State.TURNING_SHUT:
			return smoothstep(0.0, 1.0, (t - hold) / turn_time)
		State.SHUT:
			return 1.0
		_:
			return 1.0 - smoothstep(0.0, 1.0,
				(t - 2.0 * hold - turn_time) / turn_time)


## Cate secunde mai sunt pana la urmatoarea rotatie (indiferent de sens).
func seconds_to_turn(t: float) -> float:
	var hold := hold_time()
	if t < hold:
		return hold - t
	if t < hold + turn_time:
		return 0.0
	if t < 2.0 * hold + turn_time:
		return 2.0 * hold + turn_time - t
	return 0.0


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _span == null:
		return # modulul se construieste amanat (vezi `_ready`)
	if not _started:
		_started = true
		_time = phase * period
	if clock_running:
		_time += delta
	_apply_cycle(delta)


func _apply_cycle(delta: float) -> void:
	var t := fposmod(_time, period)
	_state = _phase_of(t)
	var frac := _turn_fraction(t)
	if _span != null:
		# O SINGURA scriere de transform pe cadru (Jolt + sync_to_physics,
		# memoria `jolt-sync-transform-o-singura-scriere`).
		_span.transform = Transform3D(
			_span_rest_basis() * Basis(Vector3.UP, deg_to_rad(closed_angle_deg) * frac),
			_at(0.0, 0.0))
	_tick_gate(delta, frac)
	_push_cars()
	_tick_lamp(t)


## Poarta e solida de cum tronsonul a plecat din deschis si pana s-a intors.
## Colizorul NU apare sub o masina care e chiar in ea: la fel ca usa
## telecabinei, inchiderea asteapta (cel mult `gate_hold_max`) si pana atunci
## banda ramane libera.
##
## Senzorul lucreaza DOAR pe tranzitie — o poarta deja solida ramane solida
## cat tine ciclul, chiar daca cineva intra in ea. Prima versiune reevalua
## conditia in fiecare cadru si a picat sonda in modul cel mai urat cu putinta:
## masina lansata spre poarta intra in zona senzorului, poarta se DESCHIDEA
## in fata ei, si trecea nestingherita peste gol cu pasajul inchis. Adica exact
## pe dos — senzorul e acolo ca sa nu apara un zid sub o masina oprita, nu ca
## sa dispara unul in fata uneia lansate.
func _tick_gate(delta: float, frac: float) -> void:
	if _gate_shape == null:
		return
	var want := frac > 0.02
	if not want:
		_gate_hold = 0.0
	elif _gate_shape.disabled and not _cars_in_gate().is_empty() 			and _gate_hold < gate_hold_max:
		_gate_hold += delta
		want = false
	for sh in _gate_shapes:
		sh.disabled = not want
	for m in _gate_meshes:
		m.visible = frac > 0.02


## Ghiontul care te scoate spre ocol, cat poarta e solida.
##
## Se aplica DOAR cand poarta chiar bareaza (`disabled == false`): cu pasajul
## deschis linia nu exista, si o zona care imbranceste acolo ar fi un hazard
## invizibil. Directia e +X local inmultit cu partea ocolului — adica exact
## incotro trebuie sa pleci.
func _push_cars() -> void:
	if _gate_zone == null or _gate == null or _gate_shape == null \
			or _gate_shape.disabled:
		return
	if gate_push <= 0.0:
		return
	# Tangenta liniei de bariere, spre capatul dinspre ocol. `_gate.global_basis.x`
	# e chiar axa lunga a liniei (cutia e construita pe X), iar semnul o intoarce
	# spre partea pe care ocolul se desprinde.
	var dir := _gate.global_basis.x * signf(float(service_side))
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		return
	dir = dir.normalized()
	for b in _gate_zone.get_overlapping_bodies():
		var car := b as Car
		if car == null:
			continue
		if car.horizontal_speed() > gate_push_speed_max:
			continue
		# Se ADUCE la o viteza de alunecare, nu se ADUNA un impuls.
		#
		# Prima varianta aduna `gate_push` la fiecare 0.35 s cat masina statea in
		# poarta, si sonda a masurat unde duce asta: componenta tangentiala
		# creste din ghiont in ghiont, masina pleaca lateral de pe pasaj si
		# ajunge la x = -24, cazuta. Un plafon face din el ce trebuia sa fie —
		# o alunecare de-a lungul barierelor, cu viteza omului care impinge.
		var along := car.velocity.dot(dir)
		if along < gate_push:
			car.velocity += dir * (gate_push - along)


func _cars_in_gate() -> Array:
	var out: Array = []
	if _gate_zone == null:
		return out
	for b in _gate_zone.get_overlapping_bodies():
		if b is Car:
			out.append(b)
	return out


## Semaforul de santier: verde cat pasajul e deschis si nu urmeaza nimic,
## GALBEN INTERMITENT pe `telegraph_lead` secunde inainte de rotatie, rosu cat
## se roteste si cat e inchis.
func _tick_lamp(t: float) -> void:
	if _lamp == null:
		return
	var to_turn := seconds_to_turn(t)
	match _state:
		State.OPEN:
			if to_turn <= telegraph_lead:
				_lamp.blink(1, fmod(t, 0.5) < 0.25)
			else:
				_lamp.set_lit(0)
		State.SHUT:
			if to_turn <= telegraph_lead:
				_lamp.blink(1, fmod(t, 0.5) < 0.25)
			else:
				_lamp.set_lit(2)
		_:
			_lamp.set_lit(2)


# ------------------------------------------------------------ constructie

func _lip_near() -> float:
	return span_length * 0.5


## Lungimea ocolului pe axa drumului (m): de la desprindere pana la reintrare.
func _service_span() -> float:
	return 2.0 * (_lip_near() + service_lead)


## Unghiul maxim cu care ocolul se abate de la banda directa (rad).
##
## Nu se alege: iese din cutie. Cu `A = service_offset` si `dz` lungimea
## ocolului, cele trei arce inchid figura doar daca `tan(φ/2) = 2A/dz`.
func _service_turn() -> float:
	if service_offset <= 0.01:
		return 0.0
	return 2.0 * atan(2.0 * service_offset / _service_span())


## Suma razelor (m). Si ea iese din cutie: `R1 + R2 = dz / (2*sin φ)`.
## Ce se poate alege e doar IMPARTIREA ei — vezi `service_entry_ratio`.
func _radius_sum() -> float:
	var phi := _service_turn()
	if phi <= 0.001:
		return INF
	return _service_span() / (2.0 * sin(phi))


## Raza cotului de intrare si de iesire (m): cat de repede se desprinde
## ocolul de banda directa.
func entry_radius() -> float:
	var sum := _radius_sum()
	return INF if is_inf(sum) else sum * service_entry_ratio


## Raza arcului din mijloc (m) — cel care trece pe langa gol si care fixeaza
## viteza pe ocol.
func service_radius() -> float:
	var sum := _radius_sum()
	return INF if is_inf(sum) else sum * (1.0 - service_entry_ratio)


## Viteza la care aderenta mai tine masina pe arcul din mijloc (m/s), cu
## acceleratia laterala data. Nu e o limita impusa de cod — nimeni nu frineaza
## masina — e cifra pe care o citeste soferul din geometrie.
func service_speed(lateral_accel: float = 16.0) -> float:
	var r := service_radius()
	return INF if is_inf(r) else sqrt(lateral_accel * r)


## Profilul lateral al ocolului: ce fractie din `service_offset` e atinsa la
## fractia `u` de lungime (0 = desprinderea, 1 = reintrarea).
##
## Trei arce de cerc: `φ` intr-un sens pe raza de intrare, `2φ` in celalalt pe
## raza din mijloc, `φ` inapoi pe raza de intrare — adica o schimbare de banda
## dusa pana la capat si intoarsa. Se desprinde si se reintoarce TANGENT la
## banda directa (spre deosebire de valul de sinus de la prima versiune, care
## pleca sub 35°), deci intrarea pe ocol e o manevra de schimbare de banda,
## nu o smucitura.
func _profile(u: float) -> float:
	if service_offset <= 0.01:
		return 0.0
	var dz := _service_span()
	var amp := service_offset
	var phi := _service_turn()
	var r1 := entry_radius()
	var r2 := service_radius()
	var q := r1 * sin(phi) # lungimea unui cot de intrare, pe axa drumului
	var zeta := clampf(u, 0.0, 1.0) * dz
	var h := 0.0
	if zeta <= q:
		h = r1 - sqrt(maxf(r1 * r1 - zeta * zeta, 0.0))
	elif zeta >= dz - q:
		var d := dz - zeta
		h = r1 - sqrt(maxf(r1 * r1 - d * d, 0.0))
	else:
		var e := zeta - dz * 0.5
		h = (amp - r2) + sqrt(maxf(r2 * r2 - e * e, 0.0))
	return clampf(h / amp, 0.0, 1.0)


## Fereastra (|z| minim, |z| maxim) in care ocolul e destul de aproape de
## pasaj ca sa poti trece de pe unul pe altul. In afara ei intre cele doua
## benzi e aer, deci acolo pasajul are parapet.
##
## Se cauta prin esantionare, nu prin `asin`: profilul nu mai e un sinus, ci
## trei arce lipite, iar formula scrisa pentru sinus ar fi raspuns in
## continuare — doar gresit, si fara sa se planga.
## Fereastra e multimea de u pentru care marginea dinspre drum a ocolului
## n-a depasit inca buza pasajului. Gol daca ocolul nu se desprinde niciodata.
## Fereastra (|z| minim, |z| maxim) pe care pana dintre pasaj si ocol e destul
## de ingusta cat sa fie pavata (vezi `GORE_MAX`). Contine intotdeauna
## fereastra de desprindere, si se intinde mai jos decat ea.
func _gore_window() -> Array[float]:
	if service_offset <= 0.01:
		return []
	var z_in := _lip_near() + service_lead
	var edge := road_half_width + 0.18
	var n := 400
	var lo := -1.0
	for i in n + 1:
		var u := 0.5 * float(i) / float(n)
		var inner := road_half_width * 0.45 + service_offset * _profile(u) 			- service_width * 0.5
		if inner - edge > GORE_MAX:
			lo = z_in * (1.0 - 2.0 * u)
			break
	if lo < 0.0:
		lo = -z_in # ocolul nu se departeaza niciodata atat: pavat pe tot
	return [lo, z_in]


func _merge_window() -> Array[float]:
	if service_offset <= 0.01:
		return []
	var z_in := _lip_near() + service_lead
	# [b]Limita e marginea PARAPETULUI, nu a carosabilului.[/b] Fereastra
	# spune „de aici incolo ocolul s-a departat destul cat parapetul benzii sa
	# nu-l mai incurce" — deci se compara cu locul unde chiar sta parapetul
	# (`road_half_width + 0.18`), plus latimea lui (0.35) si o marja de masina.
	# Cu vechiul `+0.2` fereastra se inchidea cu 2.5 m mai devreme decat
	# trebuia, iar in acei metri parapetul crestea EXACT peste gura devierii:
	# ProbeRace a gasit masinile oprite acolo, la `lat` 5.9-6.4, cu ocolul
	# vizibil la 8 m si un perete de 0.6 m intre ele.
	var lim := road_half_width + 0.18 + 0.35 + 1.2
	var n := 400
	for i in n + 1:
		var u := 0.5 * float(i) / float(n)
		var inner := road_half_width * 0.45 + service_offset * _profile(u) 			- service_width * 0.5
		if inner > lim:
			return [z_in * (1.0 - 2.0 * u), z_in]
	return [] # ocolul ramane lipit de pasaj pe toata lungimea


## Cat de departe de axa e AXA ocolului la un z dat (m), si cat de departe e
## marginea lui dinspre drum. `INF` daca acolo nu exista ocol.
func _service_center_mag(z: float) -> float:
	if service_offset <= 0.01:
		return INF
	var z_in := _lip_near() + service_lead
	if absf(z) > z_in:
		return INF
	var u := (z_in - z) / (2.0 * z_in)
	return road_half_width * 0.45 + service_offset * _profile(u)


func _service_inner_mag(z: float) -> float:
	var c := _service_center_mag(z)
	return INF if is_inf(c) else c - service_width * 0.5


## Unde sta efectiv linia de bariere (z local). Vezi nota de la `gate_lead`.
func _gate_z() -> float:
	var win := _merge_window()
	if win.size() != 2 or win[1] - win[0] <= 2.0:
		return _lip_near() + gate_lead
	return clampf(win[1] - gate_lead, win[0] + 1.0, win[1] - 1.0)


## Pasajul de pe cele doua buze plus rampele de racord.
func _build_decks() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new()
	body.name = "Deck"
	add_child(body)
	var hw := road_half_width
	var lip := _lip_near()
	for sign_z: float in [1.0, -1.0]:
		var z0 := sign_z * lip
		var z1 := sign_z * (lip + deck_run)
		_deck_strip(st, body, hw, z0, z1)
		_deck_parapets(st, body, absf(z0), absf(z1), sign_z, deck_rise, deck_rise)
		if deck_rise <= 0.01:
			continue
		var z2 := sign_z * (lip + deck_run + ramp_run)
		_slab(st, body, Vector3(-hw, deck_rise, z1), Vector3(hw, deck_rise, z1),
			Vector3(hw, 0.0, z2), Vector3(-hw, 0.0, z2))
		_deck_parapets(st, body, absf(z1), absf(z2), sign_z, deck_rise, 0.0)
	_deck_markings(st)
	var mi := PaletteBox.emit(st, "DeckMesh")
	if mi != null:
		body.add_child(mi)


## Marcajul de pe tablier: bordura pe margini si axa intrerupta pe mijloc.
##
## [b]Asta e ce transforma o placa intr-un drum.[/b] Fara el modulul e o dala
## de beton de 14 x 80 m langa sosea, si de la volan se citeste exact cum a
## spus dezvoltatorul — „ce e gri inchis pare sa pluteasca deasupra soselei".
## Cu bordura si axa, aceeasi geometrie se citeste ca o continuare a
## carosabilului, si atunci [b]golul din mijlocul ei devine informatie[/b]: nu
## mai e o margine de platou, e o banda care se opreste.
##
## Marcajul se opreste in dreptul golului: acolo chiar nu mai e drum.
func _deck_markings(st: SurfaceTool) -> void:
	var hw := road_half_width
	var lip := _lip_near()
	# DOAR portiunea ORIZONTALA. Rampele de racord coboara la cota nodului,
	# iar o banda plana intinsa peste ele ar pluti la capat cu tot atatia metri
	# cat coboara rampa — adica ar adauga chiar defectul pe care il repara.
	var far := lip + deck_run
	for sign_z: float in [1.0, -1.0]:
		# Bordura pe amandoua marginile, pe toata lungimea tablierului.
		for edge_sign: float in [-1.0, 1.0]:
			var x := edge_sign * (hw - KERB_WIDTH * 0.5)
			_mark_strip(st, x, sign_z * lip, sign_z * far, KERB_WIDTH, kerb_slot)
		# Axa intrerupta, pe mijloc.
		var z := lip
		while z < far:
			var z_end := minf(z + DASH_ON, far)
			_mark_strip(st, 0.0, sign_z * z, sign_z * z_end, MARK_WIDTH,
				Palette.FOAM_WHITE)
			z += DASH_ON + DASH_OFF


## Marcajul de pe ocol: bordura pe amandoua marginile.
##
## Axa de mijloc lipseste deliberat — ocolul e o banda ingusta cu un singur
## sens de mers, iar o axa pe ea ar spune „doua benzi" pe 5 m latime. In locul
## ei merg CHEVRONI: liniute scurte, transversale, la interval fix. Ele fac
## doua lucruri deodata — dau suprafetei textura care lipseste (fara ea placa
## e o pata uniforma, oricat de deschisa ar fi) si spun „deviere", care e chiar
## ce e ocolul.
func _service_markings(st: SurfaceTool, pts: PackedVector3Array,
		half_w: float) -> void:
	var run := 0.0
	for i in pts.size() - 1:
		var seg := pts[i].distance_to(pts[i + 1])
		var prev := run
		run += seg
		if int(prev / (DASH_ON + DASH_OFF)) != int(run / (DASH_ON + DASH_OFF)):
			var a2 := pts[i]
			var b2 := pts[i + 1]
			var d2 := b2 - a2
			d2.y = 0.0
			if d2.length_squared() > 1e-6:
				var lat2 := Vector3(-d2.z, 0.0, d2.x).normalized() 					* (half_w - KERB_WIDTH)
				var fw2 := d2.normalized() * (MARK_WIDTH * 0.5)
				var mid := (a2 + b2) * 0.5 + Vector3.UP * MARK_LIFT
				PaletteBox.quad_slab(st, mid - lat2 - fw2, mid + lat2 - fw2,
					mid + lat2 + fw2, mid - lat2 + fw2, 0.01, Palette.FOAM_WHITE)
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var dir := b - a
		dir.y = 0.0
		if dir.length_squared() < 1e-6:
			continue
		var lat := Vector3(-dir.z, 0.0, dir.x).normalized() 			* (half_w - KERB_WIDTH * 0.5)
		for edge_sign: float in [-1.0, 1.0]:
			var ea := a + lat * edge_sign + Vector3.UP * MARK_LIFT
			var eb := b + lat * edge_sign + Vector3.UP * MARK_LIFT
			var w := Vector3(-dir.z, 0.0, dir.x).normalized() * (KERB_WIDTH * 0.5)
			PaletteBox.quad_slab(st, ea - w, ea + w, eb + w, eb - w,
				0.01, kerb_slot)


## O banda de marcaj de-a lungul lui Z local, la x dat.
func _mark_strip(st: SurfaceTool, x: float, z0: float, z1: float,
		width: float, slot: int) -> void:
	var hwm := width * 0.5
	var lift := Vector3.UP * MARK_LIFT
	# Pe coloana banda se segmenteaza: o liniuta lunga intinsa drept peste o
	# curba ar iesi de pe carosabil la capete, exact defectul pe care coloana
	# il repara.
	var n := maxi(int(ceil(absf(z1 - z0) / 2.0)), 1)
	for i in n:
		var za := lerpf(z0, z1, float(i) / float(n))
		var zb := lerpf(z0, z1, float(i + 1) / float(n))
		PaletteBox.quad_slab(st,
			_at(x - hwm, za) + lift, _at(x + hwm, za) + lift,
			_at(x + hwm, zb) + lift, _at(x - hwm, zb) + lift, 0.01, slot)


## Rampa de serviciu: un cot care iese lateral inainte de buza, trece pe langa
## gol si se intoarce pe pasaj dupa cealalta buza.
##
## Costul lui are doua parti si nici una nu e o taxa: COTURILE (doua, pe o
## banda mai ingusta, te obliga sa ridici piciorul) si PALIERUL dintre ele —
## zecile de metri pe care le faci cu viteza scoasa de primul cot, inainte sa
## te lase al doilea sa accelerezi. Contractul din brief (+3 s) se plateste
## din a doua parte; prima singura daduse 1.90 s. Sonda masoara suma.
func _build_service() -> void:
	if service_offset <= 0.01:
		return
	var side := signf(float(service_side))
	var lip := _lip_near()
	var z_in := lip + service_lead
	var z_out := -z_in
	var body := StaticBody3D.new()
	body.name = "ServiceRamp"
	add_child(body)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := maxi(int(ceil((z_in - z_out) / SERVICE_STEP)), 4)
	var pts := PackedVector3Array()
	# [b]Departarea de axa se TINE MINTE, nu se reciteste din punct.[/b] Pe
	# modulul plan „cat de departe de axa e punctul asta" era chiar `p.x`, si
	# tot codul de mai jos (pana pavata, parapetele) asa il afla. Pe modulul
	# indoit `_at` amesteca in `.x` si abaterea coloanei, deci `p.x` nu mai
	# raspunde la intrebarea aia — iar consecinta a fost masurata pe pista:
	# pana pavata nu se mai construia, si intre marginea soselei si ocol
	# ramanea o GAURA cu un parapet de 0.7 m in fata ei. ProbeRace a gasit
	# masinile exact acolo, imbrancite de poarta la `lat` 5.0-6.3, oprite in
	# perete si intrate una in alta.
	var mags := PackedFloat32Array()
	for i in n + 1:
		var u := float(i) / float(n)
		var z := lerpf(z_in, z_out, u)
		# Cotul: o singura functie CONTINUA IN PANTA intre cele doua racorduri
		# (`_profile`), deci nicio imbinare de portiuni care sa lase prag sau
		# frantura (memoria `suprafete-din-placi-plane`).
		var mag := road_half_width * 0.45 + service_offset * _profile(u)
		mags.append(mag)
		pts.append(_at(side * mag, z))
	_service_points = pts
	_service_mags = mags
	_service_zs = PackedFloat32Array()
	for i in n + 1:
		_service_zs.append(lerpf(z_in, z_out, float(i) / float(n)))
	var half_w := service_width * 0.5
	_service_markings(st, pts, half_w)
	# Pana pavata dintre pasaj si ocol (vezi `GORE_MAX`): tot pe lungimea ei
	# marginea dinspre drum a ocolului da in beton, nu in gol, deci nici acolo
	# nu primeste parapet.
	var gore := _gore_window()
	var edge := road_half_width + 0.18
	for i in n:
		var a := pts[i]
		var b := pts[i + 1]
		var dir := b - a
		dir.y = 0.0
		if dir.length_squared() < 1e-6:
			continue
		var lat := Vector3(-dir.z, 0.0, dir.x).normalized() * half_w
		_slab(st, body, a - lat, a + lat, b + lat, b - lat, service_slot,
			i == 0 or i == n - 1)
		var mag_a := mags[i]
		var mag_b := mags[i + 1]
		var za := _service_zs[i]
		var zb := _service_zs[i + 1]
		_gore_slab(st, body, mag_a, mag_b, za, zb, half_w, edge, gore)
		# Parapetul creste doar unde marginea a IESIT de pe pasaj: peste
		# carosabil ar fi un zid fix pe banda directa, iar in consola e
		# singurul lucru care tine masina pe ocol.
		for edge_sign: float in [-1.0, 1.0]:
			var ea := a + lat * edge_sign
			var eb := b + lat * edge_sign
			var outer := edge_sign > 0.0 if side > 0.0 else edge_sign < 0.0
			var mag_e_a := mag_a + edge_sign * side * half_w
			var mag_e_b := mag_b + edge_sign * side * half_w
			var z_mid := absf((za + zb) * 0.5)
			var inner_free: float = gore[0] if gore.size() == 2 else _lip_near() + 2.0
			if outer:
				# Marginea dinspre gol: parapet peste tot unde a IESIT de pe pasaj.
				# Peste carosabil ar fi un zid fix pe banda directa.
				if mag_e_a <= edge and mag_e_b <= edge:
					continue
			else:
				# Marginea dinspre axa drumului e cea pe care se INTRA pe ocol, si
				# ea are un singur reper: POARTA.
				#
				# In amonte de poarta lipseste — acolo schimbi banda, si un parapet
				# ar fi un zid de-a curmezisul manevrei (sonda a oprit masina in
				# capatul lui, la 6 m de gol, cand incepea mai devreme).
				#
				# Din dreptul portii in aval exista FARA INTRERUPERE, si se leaga de
				# capatul dinspre ocol al liniei de bariere: acolo marginea dinspre
				# drum a ocolului si capatul portii sunt, prin constructie, acelasi
				# punct. Peretele iese astfel dintr-o bucata — banda inchisa pe o
				# parte, devierea pe cealalta — si masina imbrancita de poarta nu mai
				# are pe unde sa treaca pe partea gresita a lui.
				#
				# Cat a fost o bucata cu o fanta de un metru intre capatul portii si
				# inceputul parapetului, sonda a masurat exact ce inseamna fanta: la
				# 25 m/s masina trecea prin ea in doua cadre si ajungea in pana
				# dintre banda si rampa, unde a stat 32 s.
				if z_mid > inner_free:
					continue
			_parapet(st, body, ea, eb)
	_gore_nose(st, body, gore, edge)
	var mi := PaletteBox.emit(st, "ServiceMesh")
	if mi != null:
		# Cu 2 cm sub pasaj: capetele ocolului se suprapun peste carosabil, iar
		# doua suprafete coplanare se bat in z-buffer. Coliziunea RAMANE la
		# cota pasajului — nu se coboara si ea, altfel racordul ar fi o treapta
		# de 2 cm exact pe linia de rulare.
		mi.position = Vector3(0.0, -0.02, 0.0)
		body.add_child(mi)


## Pana pavata dintre buza pasajului si marginea dinspre drum a ocolului, pe
## o portiune de ocol. Nu face nimic acolo unde ocolul e inca peste pasaj (n-au
## ce sa lege) sau unde s-a departat prea mult (acolo e gol, si primeste
## parapet, nu beton).
func _gore_slab(st: SurfaceTool, body: StaticBody3D, center_mag_a: float,
		center_mag_b: float, za: float, zb: float, half_w: float, edge: float,
		gore: Array[float]) -> void:
	if gore.size() != 2:
		return
	var side := signf(float(service_side))
	# Marginea dinspre drum a ocolului, ca DEPARTARE de axa (nu ca `.x`).
	var mag_a := center_mag_a - half_w
	var mag_b := center_mag_b - half_w
	if mag_a <= edge and mag_b <= edge:
		return # ocolul e inca peste carosabil
	var z_mid := absf((za + zb) * 0.5)
	if z_mid < gore[0] or z_mid > gore[1]:
		return
	var ia := maxf(mag_a, edge)
	var ib := maxf(mag_b, edge)
	# Fiecare colt trece prin coloana, ca pana sa se indoaie odata cu drumul.
	_slab(st, body, _at(side * edge, za), _at(side * ia, za),
		_at(side * ib, zb), _at(side * edge, zb))


## Botul de beton din capatul penei pavate, pe amandoua jumatatile.
##
## Pana se termina acolo unde ocolul s-a departat de pasaj cu `GORE_MAX`, si
## dincolo de capatul ei e gol de 3 m. Fara peretele asta de-a curmezisul,
## masina care se freaca de parapetul benzii inchise merge pe pana pana se
## termina si CADE — masurat: iesita la x=-5, y de la 3 la 0, cu 32 s pierdute
## in vale. Cu el, se opreste in bot, ca in realitate, si vireaza pe ocol
## avand toata latimea penei la dispozitie.
func _gore_nose(st: SurfaceTool, body: StaticBody3D, gore: Array[float],
		edge: float) -> void:
	if gore.size() != 2 or service_offset <= 0.01:
		return
	var side := signf(float(service_side))
	for sign_z: float in [1.0, -1.0]:
		var z := sign_z * gore[0]
		var inner := _service_inner_mag(z)
		if is_inf(inner) or inner <= edge + 0.2:
			continue
		# Botul se opreste cu un metru INAINTE de marginea ocolului. Capatul lui
		# lipit de ea sta chiar pe linia pe care intra masina care ia devierea
		# corect, iar sonda a masurat-o acolo: viteza minima pe ocol cadea de la
		# 14.6 la 6.8 m/s, adica pretul ocolului incepea sa fie dat de un colt de
		# beton. Metrul lasat liber nu deschide nicio scurtatura — pe langa bot se
		# intra tot pe ocol.
		_parapet(st, body, _at(side * edge, z),
			_at(side * (inner - 1.0), z))


## Parapetii unei portiuni de pasaj, pe amandoua marginile, in pasi de ~2 m
## ca sa poata lipsi exact peste fereastra de desprindere a ocolului.
func _deck_parapets(st: SurfaceTool, body: StaticBody3D, za: float, zb: float,
		sign_z: float, ya: float, yb: float) -> void:
	if deck_parapet <= 0.01:
		return
	# Parapetul pasajului lipseste EXACT cat tine fereastra de desprindere —
	# nici un metru mai mult. Pe portiunea aia treci de pe banda pe ocol; sub
	# ea, acelasi parapet e peretele care desparte banda inchisa de deviere,
	# si el e cel care tine masina scoasa de poarta pe ocol.
	#
	# S-a incercat, in aceeasi sesiune, sa lipseasca pe toata pana pavata: cu
	# peretele ala scos, masina imbrancita de poarta la x=-5 s-a intors linistit
	# pe banda directa si a mers pana in tronsonul rotit, unde s-a oprit cu botul
	# in el, pe buza golului (y min 2.74, rasturnata pe 0.80). Devierea nu mai
	# devia.
	var win := _merge_window()
	var side := signf(float(service_side))
	var hw := road_half_width + 0.18
	var n := maxi(int(ceil(absf(zb - za) / 2.0)), 1)
	for i in n:
		var ua := float(i) / float(n)
		var ub := float(i + 1) / float(n)
		var z_a := lerpf(za, zb, ua)
		var z_b := lerpf(za, zb, ub)
		var y_a := lerpf(ya, yb, ua)
		var y_b := lerpf(ya, yb, ub)
		var z_mid := (z_a + z_b) * 0.5
		# Sensul de mers e -Z, deci `sign_z < 0` e jumatatea pe care ocolul se
		# INTOARCE in banda: acolo fereastra tine cat scurgerea manevrei.
		var hi := win[1] + (MERGE_RUNOUT if sign_z < 0.0 else 0.0) 			if win.size() == 2 else 0.0
		var in_window := win.size() == 2 and z_mid > win[0] and z_mid < hi
		# [b]Si peste PANA PAVATA, unde parapetul n-are ce sa pazeasca.[/b]
		# Fereastra de desprindere se inchide acolo unde ocolul s-a departat
		# de banda, dar intre capatul ei si capatul penei mai raman metri in
		# care pana e asfalt continuu de la sosea pana la ocol — si acolo
		# parapetul creste FIX peste culoarul de traversare. Masurat pe
		# pista: banda z 12-18 (frac 0.742-0.745) avea pana pavata la lat
		# 7.5, un parapet de 0.6 m la lat 8.0 si ocolul de-abia la 8.5;
		# ProbeRace a gasit acolo masini tarandu-se cu 1.7-3.7 m/s fara sa
		# atinga nimic, adica frecandu-se de el.
		#
		# Pe pana parapetul nu pazeste nicio cadere: sub el e beton, nu gol.
		var gore_w := _gore_window()
		var inner_here := _service_inner_mag(sign_z * z_mid)
		var on_gore := false
		if gore_w.size() == 2 and not is_inf(inner_here):
			on_gore = z_mid >= gore_w[0] and z_mid <= gore_w[1] and inner_here > hw
		for edge_sign: float in [-1.0, 1.0]:
			# Fereastra de desprindere se taie doar din marginea pe care
			# chiar iese ocolul; cealalta ramane inchisa peste tot.
			if (in_window or on_gore) and is_equal_approx(edge_sign, side):
				continue
			# Pe coloana, cotele vin din ea; `ya`/`yb` raman pentru rampele de
			# racord ale sondei, care coboara la cota soselei-test.
			var pa := _at(edge_sign * hw, sign_z * z_a) 				if _spine.is_empty() == false and is_equal_approx(y_a, deck_rise) 				else Vector3(edge_sign * hw, y_a, sign_z * z_a)
			var pb := _at(edge_sign * hw, sign_z * z_b) 				if _spine.is_empty() == false and is_equal_approx(y_b, deck_rise) 				else Vector3(edge_sign * hw, y_b, sign_z * z_b)
			_parapet(st, body, pa, pb, deck_parapet)


## Un tronson de parapet intre doua puncte de pe marginea ocolului.
func _parapet(st: SurfaceTool, body: StaticBody3D, a: Vector3, b: Vector3,
		height: float = -1.0) -> void:
	if height < 0.0:
		height = service_parapet
	if height <= 0.01:
		return
	var fwd := b - a
	var length := fwd.length()
	if length < 0.05:
		return
	fwd /= length
	var right := Vector3.UP.cross(fwd).normalized()
	var basis := Basis(right, Vector3.UP, fwd)
	# Se suprapun cu 10 cm pe imbinari, ca sa nu ramana fante intre tronsoane.
	var size := Vector3(0.35, height, length + 0.1)
	var mid := (a + b) * 0.5 + Vector3.UP * (height * 0.5)
	var xf := Transform3D(basis, mid)
	PaletteBox.add(st, xf, size, deck_slot)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.transform = xf
	body.add_child(shape)


## Carosabilul tablierului intre doua cote z, segmentat pe coloana.
##
## O singura placa intinsa peste 34 m de spirala ar fi chiar coarda peste arc
## pe care coloana o repara — deci se taie in bucati de doi metri, la fel ca
## ocolul (`SERVICE_STEP`), si fiecare bucata isi ia colturile din `_at`.
func _deck_strip(st: SurfaceTool, body: StaticBody3D, hw: float,
		z0: float, z1: float) -> void:
	var n := maxi(int(ceil(absf(z1 - z0) / 2.0)), 1)
	for i in n:
		var za := lerpf(z0, z1, float(i) / float(n))
		var zb := lerpf(z0, z1, float(i + 1) / float(n))
		# Peretii de capat doar la capetele SIRULUI: intre bucati ei ies prin
		# fata vecinei si se vad ca dungi negre (vezi `PaletteBox.quad_slab`).
		_slab(st, body, _at(-hw, za), _at(hw, za), _at(hw, zb), _at(-hw, zb),
			-1, i == 0 or i == n - 1)


## Directia laterala a coloanei la un z local (unitara, spre +x).
func _lat_at(z: float) -> Vector3:
	var dir := _spine_dir(z)
	return Vector3(-dir.z, 0.0, dir.x)


## Orientarea de repaus a tronsonului rotitor: aliniat cu coloana in dreptul
## golului, nu cu axa nodului. Pe modulul plan e identitatea.
##
## [b]Are si TANGAJ, nu doar directie.[/b] Tronsonul e o placa rigida de 12 m
## asezata pe o rampa care urca 3.7%: tinut orizontal, un capat al lui iese cu
## 0.44 m peste asfalt si celalalt intra sub el — masurat exact asa inainte de
## a fi inclinat. Cu tangajul soselei, placa se aseaza pe drum si pragul de la
## capete scade la sub 0.1 m.
##
## Inclinarea se pune INAINTEA rotatiei de inchidere (`rest * turn`), deci
## tronsonul se roteste in jurul verticalei LUI, ca un pod rotitor adevarat pe
## o rampa inclinata — nu in jurul verticalei lumii, care l-ar face sa se
## infiga cu un colt in tablier cat se intoarce.
func _span_rest_basis() -> Basis:
	if _spine.is_empty():
		return Basis.IDENTITY
	var lip := _lip_near()
	var a := _at(0.0, lip)
	var b := _at(0.0, -lip)
	var fwd := (b - a).normalized()
	return Basis.looking_at(fwd, Vector3.UP)


## O placa: mesh pe atlas + colizor convex cu talpa sub ea.
func _slab(st: SurfaceTool, body: StaticBody3D, a: Vector3, b: Vector3,
		c: Vector3, d: Vector3, slot: int = -1, caps: bool = true) -> void:
	PaletteBox.quad_slab(st, a, b, c, d, DECK_THICK,
		road_slot if slot < 0 else slot, caps)
	var shape := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	hull.points = PackedVector3Array([a, b, c, d,
		a + Vector3.DOWN * DECK_THICK, b + Vector3.DOWN * DECK_THICK,
		c + Vector3.DOWN * DECK_THICK, d + Vector3.DOWN * DECK_THICK])
	shape.shape = hull
	body.add_child(shape)


## Tronsonul rotitor: corp animat cu pivot in centrul golului.
func _build_span() -> void:
	_span = AnimatableBody3D.new()
	_span.name = "Span"
	_span.sync_to_physics = true
	add_child(_span)
	_span.transform = Transform3D(_span_rest_basis(), _at(0.0, 0.0))
	var hw := road_half_width
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(hw * 2.0, DECK_THICK, span_length)
	shape.shape = box
	shape.position = Vector3(0.0, -DECK_THICK * 0.5, 0.0)
	_span.add_child(shape)
	for kerb_sign: float in [-1.0, 1.0]:
		var kerb := CollisionShape3D.new()
		var kbox := BoxShape3D.new()
		kbox.size = Vector3(SPAN_KERB_WIDTH, SPAN_KERB_HEIGHT, span_length) 			* model_scale
		kerb.shape = kbox
		kerb.position = Vector3(kerb_sign * SPAN_KERB_X * model_scale,
			SPAN_KERB_HEIGHT * 0.5 * model_scale, 0.0)
		_span.add_child(kerb)
	if median_collision:
		var med := CollisionShape3D.new()
		var mbox := BoxShape3D.new()
		mbox.size = Vector3(0.82, 0.43, span_length)
		med.shape = mbox
		med.position = Vector3(0.0, 0.215, 0.0)
		_span.add_child(med)
	var scene := span_model if span_model != null else load(SPAN_MODEL) as PackedScene
	var inst: Node3D = scene.instantiate() as Node3D if scene != null else null
	if inst != null:
		inst.scale = Vector3.ONE * model_scale
		inst.position = Vector3(0.0, -SPAN_DECK_Y * model_scale, 0.0)
		Palette.apply_object_class_materials(inst, WorldProp.prop_classes(), model_scale)
		_span.add_child(inst)
	else:
		_span.add_child(PaletteBox.instance(
			Vector3(hw * 2.0, DECK_THICK, span_length), deck_slot,
			Vector3(0.0, -DECK_THICK * 0.5, 0.0)))


## Poarta de bariere: o linie oblica de `construction_barrier.glb` peste banda
## directa, cu UN colizor comutabil in spatele ei.
func _build_gate() -> void:
	_gate = StaticBody3D.new()
	_gate.name = "Gate"
	add_child(_gate)
	var side := signf(float(service_side))
	var skew := deg_to_rad(gate_skew_deg) * side
	var basis := Basis(Vector3.UP, skew)
	var gz := _gate_z()
	# Poarta inchide BANDA DIRECTA, nu tot drumul. Capatul ei dinspre ocol se
	# opreste in marginea ocolului; ce e dincolo ramane liber, fiindca exact
	# acolo trebuie sa te scoata.
	#
	# Prima versiune intindea linia peste toata latimea (6.8 m) si sonda a
	# aratat pretul: masina oprita in bariere avea in stanga un culoar de 2.4 m
	# — mai ingust decat manevra — si a stat 20 s intr-o intoarcere din trei
	# miscari fara sa iasa. O bariera care blocheaza si ocolul nu mai e o
	# deviere, e un fund de sac.
	var far_x := -side * (road_half_width + 0.3)
	var inner := _service_inner_mag(gz)
	var near_x := side * (road_half_width + 0.3)
	if not is_inf(inner) and inner < road_half_width:
		# Capatul dinspre ocol se opreste cu `gate_clearance` metri INAINTE de
		# marginea lui, ca gura devierii sa ramana mai lata decat masina.
		near_x = side * maxf(inner - gate_clearance, -road_half_width)
	var center_x := (far_x + near_x) * 0.5
	var g_dir := _spine_dir(gz)
	var g_yaw := atan2(-g_dir.x, -g_dir.z)
	_gate.transform = Transform3D(Basis(Vector3.UP, g_yaw + skew), _at(center_x, gz))
	# Linia oblica trebuie sa fie o PANTA, nu un zid: cu frecarea implicita
	# masina se agata de ea si se opreste (masurat de critic: 18.33 s pana la
	# desprindere). Materialul se pune pe corp, nu pe forma — colizorul portii
	# se aprinde si se stinge, materialul ramane.
	var slick := PhysicsMaterial.new()
	slick.friction = gate_friction
	slick.bounce = 0.0
	_gate.physics_material_override = slick
	var width := absf(far_x - near_x) / cos(skew) + 0.4
	_gate_shape = CollisionShape3D.new()
	_gate_shape.name = "GateWall"
	var box := BoxShape3D.new()
	box.size = Vector3(width, 1.3, gate_depth)
	_gate_shape.shape = box
	_gate_shape.position = Vector3(0.0, 0.65, 0.0)
	_gate_shape.disabled = true
	_gate.add_child(_gate_shape)
	_gate_shapes.append(_gate_shape)

	var scene := barrier_model if barrier_model != null else load(BARRIER_MODEL) as PackedScene
	var count := maxi(int(ceil(width / BARRIER_WIDTH)), 1)
	for i in count:
		var x := -width * 0.5 + BARRIER_WIDTH * (float(i) + 0.5)
		var piece: Node3D = null
		if scene != null:
			piece = scene.instantiate() as Node3D
		if piece != null:
			piece.scale = Vector3.ONE * model_scale
			Palette.apply_object_class_materials(piece, WorldProp.prop_classes(),
				model_scale)
		else:
			piece = PaletteBox.instance(Vector3(BARRIER_WIDTH * 0.95, 1.35, 0.3),
				Palette.KERB_RED, Vector3(0.0, 0.68, 0.0))
		piece.position = Vector3(x, 0.0, 0.0)
		_gate.add_child(piece)
		_gate_meshes.append(piece)

	_build_gate_taper(gz, scene)

	# Zona senzorului: mai groasa decat poarta, ca sa vada masina care tocmai
	# o strabate.
	_gate_zone = Area3D.new()
	_gate_zone.name = "GateZone"
	_gate_zone.monitorable = false
	var zs := CollisionShape3D.new()
	var zbox := BoxShape3D.new()
	zbox.size = Vector3(width, 2.6, gate_depth + 2.0)
	zs.shape = zbox
	zs.position = Vector3(0.0, 1.3, 0.0)
	_gate_zone.add_child(zs)
	_gate.add_child(_gate_zone)


## Peretele lateral al portii: linia de bariere nu se opreste unde se termina
## banda directa, ci coteste si merge IN AVAL de-a lungul marginii dinspre drum
## a ocolului, pana acolo unde ocolul a iesit de pe pasaj si parapetul lui fix
## preia treaba.
##
## Asta e ce transforma poarta dintr-un zid intr-o palnie. Fara el, masina
## alunecata pe linie ajunge, dupa capatul ei, intr-o banda inca deschisa spre
## gol si trebuie sa vireze singura 40°; cu el, e purtata pe langa un perete
## care se desface incet (~20°) si iese pe ocol cu viteza in ea.
##
## E al PORTII, nu al pasajului: se aprinde si se stinge odata cu ea. De-aia
## are voie sa taie banda directa — cand tronsonul e la locul lui, peretele nu
## exista, si drumul e drum.
func _build_gate_taper(gz: float, scene: PackedScene) -> void:
	var win := _merge_window()
	if win.size() != 2:
		return
	var side := signf(float(service_side))
	var z_end := win[0]
	if gz - z_end < 1.0:
		return
	var steps := maxi(int(ceil((gz - z_end) / 4.0)), 1)
	# Punctele se iau de pe COLOANA, apoi se aduc in coordonatele corpului
	# portii cu inversa transformului lui — nu prin scaderea unei origini
	# drepte, care pe o curba n-ar mai fi originea portii.
	var to_gate := _gate.transform.affine_inverse()
	var prev := _at(side * (_service_inner_mag(gz) - gate_clearance), gz)
	for i in steps:
		var z := lerpf(gz, z_end, float(i + 1) / float(steps))
		var inner := _service_inner_mag(z)
		if is_inf(inner):
			break
		var cur := _at(side * (inner - gate_clearance), z)
		var seg := cur - prev
		var length := seg.length()
		if length < 0.2:
			prev = cur
			continue
		var fwd := seg / length
		var right := Vector3.UP.cross(fwd).normalized()
		var mid := (prev + cur) * 0.5
		# In coordonatele corpului portii (care e deja rotit cu skew).
		var local := to_gate * mid
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.5, 1.3, length + 0.2)
		shape.shape = box
		shape.transform = Transform3D(
			to_gate.basis * Basis(right, Vector3.UP, fwd),
			local + Vector3.UP * 0.65)
		shape.disabled = true
		_gate.add_child(shape)
		_gate_shapes.append(shape)
		var count := maxi(int(round(length / BARRIER_WIDTH)), 1)
		for k in count:
			var t := (float(k) + 0.5) / float(count)
			var at := prev.lerp(cur, t)
			var piece: Node3D = null
			if scene != null:
				piece = scene.instantiate() as Node3D
			if piece != null:
				piece.scale = Vector3.ONE * model_scale
				Palette.apply_object_class_materials(piece,
					WorldProp.prop_classes(), model_scale)
			else:
				piece = PaletteBox.instance(
					Vector3(BARRIER_WIDTH * 0.95, 1.35, 0.3),
					Palette.KERB_RED, Vector3(0.0, 0.68, 0.0))
			piece.transform = Transform3D(
				to_gate.basis * Basis(right, Vector3.UP, fwd),
				to_gate * at)
			_gate.add_child(piece)
			_gate_meshes.append(piece)
		prev = cur


## Lampile de lucru de deasupra tablierului si a ocolului.
##
## [b]De ce a fost nevoie de ele, si de ce nu s-a rezolvat din culoare.[/b]
## Reclamatia era ca modulul „pare sa pluteasca deasupra soselei", si prima
## banuiala a fost slotul de paleta. Masurat, banuiala era gresita: geometria
## tablierului sta deja in majoritate pe CONCRETE (luminanta 0.745, cel mai
## deschis slot de suprafata), cu normalele in sus, si TOT iesea neagra in
## captura. Explicatia e tema: Chongqing e o pista de NOAPTE, cu soare 0.35 si
## ambiental 0.40, iar soseaua principala se vede doar fiindca are felinare pe
## ea. Modulul n-avea niciunul — cele 17 lumini ale nodului sunt la 30-40 m,
## adica dincolo de `omni_range`-ul lor de 19 m.
##
## Deci lipsa nu era de albedo, era de LUMINA. Un santier de noapte are lampi
## de lucru; astea sunt ele. Fara umbre (tema le tine stinse) si cu stingere
## la distanta, ca sa nu coste nimic cand modulul nu e in cadru.
func _build_work_lights() -> void:
	var lip := _lip_near()
	var side := signf(float(service_side))
	var spots: Array[Vector3] = []
	# Doua siruri pe tablier, de o parte si de alta a golului.
	for sign_z: float in [1.0, -1.0]:
		var z := lip + 6.0
		while z < lip + deck_run:
			spots.append(_at(-side * (road_half_width - 1.0), sign_z * z)
				+ Vector3.UP * WORK_LIGHT_HEIGHT)
			z += WORK_LIGHT_STEP
	# Si pe ocol, unde e chiar suprafata care umple cadrul pe apropiere.
	if service_offset > 0.01 and _service_points.size() > 2:
		var i := 0
		while i < _service_points.size():
			var p := _service_points[i]
			spots.append(p + Vector3.UP * WORK_LIGHT_HEIGHT
				+ _lat_at(p.z) * side * (service_width * 0.5 + 0.8))
			i += int(WORK_LIGHT_STEP / SERVICE_STEP)
	for k in spots.size():
		var l := OmniLight3D.new()
		l.name = "WorkLight%d" % k
		l.position = spots[k]
		l.light_color = WORK_LIGHT_COLOR
		l.light_energy = WORK_LIGHT_ENERGY
		l.light_specular = 0.25
		# Tema Chongqing ruleaza fara umbre; o lampa care le-ar aprinde ar
		# incalca si constrangerea mobila („o singura lumina care arunca").
		l.shadow_enabled = false
		l.omni_range = WORK_LIGHT_RANGE
		l.omni_attenuation = 1.2
		l.distance_fade_enabled = true
		l.distance_fade_begin = 130.0
		l.distance_fade_length = 40.0
		add_child(l)


## Semaforul de santier, pe marginea dinspre ocol, inaintea portii.
func _build_lamp() -> void:
	var side := signf(float(service_side))
	var at := _at(side * (road_half_width + 1.2), _gate_z() + 8.0)
	var post := PaletteBox.instance(Vector3(0.24, 3.2, 0.24),
		Palette.PAINTED_METAL, at + Vector3.UP * 1.6)
	post.name = "SignalPost"
	add_child(post)
	_lamp = HazardLamp.new()
	_lamp.name = "SignalHead"
	add_child(_lamp)
	_lamp.position = at + Vector3.UP * 3.2


# ---------------------------------------------------------- pentru sonde

func gore_window() -> Array[float]:
	return _gore_window()


func gate_z_pub() -> float:
	return _gate_z()


func service_points_local() -> PackedVector3Array:
	return _service_points


func spine_dump() -> PackedVector2Array:
	return _spine


func spine_z0() -> float:
	return _spine_z0


func spine_step() -> float:
	return _spine_step


func at_dump(x: float, z: float) -> Vector3:
	return _at(x, z)


func state() -> State:
	return _state


func cycle_time() -> float:
	return fposmod(_time, period)


## Deschis = tronsonul continua pasajul.
func is_open() -> bool:
	return _state == State.OPEN


func turn_fraction() -> float:
	return _turn_fraction(cycle_time())


## Ce bec e aprins: 0 verde, 1 galben, 2 rosu, -1 stins (intre clipiri).
func lamp() -> int:
	return _lamp.lit() if _lamp != null else -1


## Unde sta linia de bariere (z local) si fereastra de desprindere a
## ocolului — sonda are nevoie de amandoua ca sa stie unde sa se uite.
func gate_z() -> float:
	return _gate_z()


func service_turn() -> float:
	return _service_turn()


func merge_window() -> Array[float]:
	return _merge_window()


func service_center_mag(z: float) -> float:
	return _service_center_mag(z)


func service_inner_mag(z: float) -> float:
	return _service_inner_mag(z)


## Peretele portii, in coordonatele nodului: [x stanga, x dreapta].
func gate_extent() -> Array[float]:
	if _gate == null or _gate_shape == null:
		return []
	var w: float = (_gate_shape.shape as BoxShape3D).size.x * cos(
		deg_to_rad(gate_skew_deg))
	return [_gate.position.x - w * 0.5, _gate.position.x + w * 0.5]


func gate_solid() -> bool:
	return _gate_shape != null and not _gate_shape.disabled


func gate_hold() -> float:
	return _gate_hold


func span_body() -> AnimatableBody3D:
	return _span


## Axa rampei de serviciu, in coordonate GLOBALE: ce urmeaza un sofer (sau un
## AI) cand pasajul e inchis. Tot de aici isi ia sonda traseul de ocol.
func service_waypoints() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for p in _service_points:
		out.append(to_global(p))
	return out


## Axa benzii directe, in coordonate globale: de la desprinderea ocolului,
## peste tronson, pana dincolo de cealalta buza.
func direct_waypoints() -> Array[Vector3]:
	var z0 := _lip_near() + service_lead
	var out: Array[Vector3] = []
	var n := 12
	for i in n + 1:
		var z := lerpf(z0, -z0, float(i) / float(n))
		out.append(to_global(_at(0.0, z)))
	return out


# ------------------------------------------------------------ pentru AI

## Pe ce parte se trece peste `ahead` secunde: 0 = pe axa (pasajul e deschis),
## `service_side` = pe ocol (e inchis, sau se va fi inchis pana ajungem).
##
## [b]Exista din acelasi motiv ca `FireballGeyser.safe_side`, si costul lipsei
## lui a fost masurat la fel.[/b] Cat timp modulul a plutit la 3 m deasupra
## soselei (`deck_rise` de sonda ramas in pista), niciun pilot n-a dat vreodata
## peste el, deci nimeni n-a observat ca AI-ul nu stie sa-l citeasca. Prima
## rulare cu modulul CHIAR pe traseu a aratat ce inseamna: plutonul mergea pe
## axa direct in linia de bariere si se opreau unii in altii — blocaje in serie
## la frac 0.638-0.644, cu masini oprite pe axa (lat +/-0.4 m) la 3-5 m INAINTE
## de poarta, adica exact in fata ei, fara sa fi incercat vreodata ocolul.
## `gate_push` scoate O masina din bariere; nu poate desface un pluton de sase
## care s-a proptit in ea.
##
## Raspunsul e despre momentul SOSIRII, nu despre acum: la 25 m/s, 46 m
## inseamna ~1.8 s, iar ciclul e de 25 s cu rotatii de 4 s — deci intrebarea
## „e deschis?" pusa acum poate avea alt raspuns cand ajungi. Se intreaba cu
## `ahead` fix cum face pilotul la gheizere.
##
## Se raspunde „pe ocol" si cat tine ROTATIA, nu doar starea inchisa: un
## tronson care tocmai a plecat din deschis nu mai e pod, e o placa oblica
## peste gol.
func ai_safe_side(ahead: float) -> float:
	var t := fposmod(_time + ahead, period)
	return 0.0 if _phase_of(t) == State.OPEN else signf(float(service_side))


## Cat de lateral sta linia AI-ului cand raspunsul e „pe ocol", ca fractie din
## semilatimea soselei (pozitiv spre `service_side`).
##
## Se DERIVA din geometria ocolului, nu se alege: tinta e axa rampei de
## serviciu acolo unde ea se desprinde de banda directa (adica in dreptul
## portii), fiindca acolo trebuie sa fii deja cand ajungi la linia de bariere.
## Mai departe pe ocol pilotul urmeaza oricum soseaua — ce ii lipsea era exact
## mutarea DINAINTEA portii.
func ai_line_offset() -> float:
	if service_offset <= 0.01 or road_half_width <= 0.0:
		return 0.0
	var c := _service_center_mag(_gate_z())
	if is_inf(c):
		return 0.0
	return clampf(c / road_half_width, 0.0, 1.0)


## Unde sta linia de bariere, in coordonate globale: reperul fata de care
## masoara pilotul, nu originea nodului (care e la mijlocul golului, cu zeci
## de metri mai in aval). Vezi `AI_REACH_M`.
func ai_decision_point() -> Vector3:
	return to_global(_at(0.0, _gate_z()))
