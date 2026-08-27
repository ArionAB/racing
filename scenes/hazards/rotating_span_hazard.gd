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
## Cat de des se esantioneaza rampa de serviciu (m). Sub un metru cotul ei e
## neted; peste doi, imbinarile dintre placi devin praguri (memoria
## `suprafete-din-placi-plane`).
const SERVICE_STEP: float = 1.6
## Cati metri de pasaj mai raman fara parapet DUPA capatul ocolului, pe partea
## pe care el se intoarce in banda directa.
##
## Fereastra de desprindere e simetrica geometric, dar manevra nu e: la
## intrare ocolul se departeaza de banda si ai toata lungimea lui ca sa treci
## pe el, iar la iesire se apropie si ajungi pe pasaj inca la 4 m de axa. Fara
## marginea asta de scurgere, parapetul pasajului reincepea exact in capatul
## ocolului si sonda a masurat rezultatul: masina se oprea in el la z=-18, cu
## ocolul terminat si banda directa la un metru.
const MERGE_RUNOUT: float = 8.0

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
@export_range(4.0, 60.0, 0.5) var deck_run: float = 20.0
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
## Pe ce parte ocoleste golul: +1 dreapta, -1 stanga sensului de mers.
@export_enum("Dreapta:1", "Stanga:-1") var service_side: int = 1
## Cat de departe iese cotul, masurat de la marginea pasajului (m).
@export_range(0.0, 40.0, 0.5) var service_offset: float = 9.0
## Latimea rampei de serviciu (m). Mai ingusta decat pasajul: si asta e o
## parte din pretul ocolului.
@export_range(3.0, 20.0, 0.1) var service_width: float = 5.0
## Cu cati metri inainte de buza se desprinde ocolul (si dupa cealalta buza
## se intoarce).
@export_range(2.0, 60.0, 0.5) var service_lead: float = 14.0
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
## Cu cati metri inaintea buzei sta poarta.
##
## Valoarea e o DORINTA, nu o pozitie finala: `_gate_z()` o aduce inauntrul
## ferestrei in care ocolul e lipit de pasaj. Poarta pusa dupa desprinderea
## ocolului inchide un fund de sac — masina care a ignorat semaforul se
## opreste intre bariere si parapeti, cu ocolul deja in spate, si singura
## iesire ar fi mersul in marsarier. Peste ramificatie, aceeasi linie oblica
## e o palnie: te freci de ea si te scoate pe ocol.
@export_range(0.5, 30.0, 0.5) var gate_lead: float = 3.0
## Cat poate intarzia inchiderea unei porti peste care sta o masina (s).
## Aceeasi usa cu senzor ca la telecabina: colizorul nu apare sub nimeni.
@export_range(0.0, 4.0, 0.05) var gate_hold_max: float = 1.5
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
## Slotul de paleta al pasajului si al rampei de serviciu.
@export_range(0, 31) var deck_slot: int = Palette.CONCRETE
## Coliziune si pe separatorul de pe mijlocul tronsonului (0.43 m inaltime in
## GLB). Stins implicit: pe un carosabil de 6.8 m ar taia pasajul in doua
## benzi de 3 m, iar memoria `suprafete-cu-goluri-si-praguri` spune ca un prag
## de peste 0.3 m e zid. Se aprinde cand pista chiar vrea doua sensuri.
@export var median_collision: bool = false

var _span: AnimatableBody3D
var _gate: StaticBody3D
var _gate_shape: CollisionShape3D
var _gate_zone: Area3D
var _gate_meshes: Array[Node3D] = []
var _lamp: HazardLamp
var _service_points: PackedVector3Array = PackedVector3Array()
var _time: float = 0.0
var _started: bool = false
var _state: State = State.OPEN
var _gate_hold: float = 0.0


func _ready() -> void:
	_build_decks()
	_build_service()
	_build_span()
	_build_gate()
	_build_lamp()
	_apply_cycle(0.0)


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
			Basis(Vector3.UP, deg_to_rad(closed_angle_deg) * frac),
			Vector3(0.0, deck_rise, 0.0))
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
	_gate_shape.disabled = not want
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


## Fereastra (|z| minim, |z| maxim) in care ocolul e destul de aproape de
## pasaj ca sa poti trece de pe unul pe altul. In afara ei intre cele doua
## benzi e aer, deci acolo pasajul are parapet.
##
## Geometria e explicita, nu esantionata: ocolul are axa la
## `road_half_width*0.45 + service_offset*sin(u*PI)` de la centru, deci
## marginea lui dinspre drum e la atat minus jumatate din latime. Fereastra e
## multimea de u pentru care marginea aia n-a depasit inca buza pasajului.
## Gol daca ocolul nu se desprinde niciodata (e lipit tot drumul).
func _merge_window() -> Array[float]:
	if service_offset <= 0.01:
		return []
	var z_in := _lip_near() + service_lead
	var reach := road_half_width + 0.2 + service_width * 0.5 - road_half_width * 0.45
	var k := reach / service_offset
	if k >= 1.0:
		return [] # ocolul ramane lipit de pasaj pe toata lungimea
	var u0 := asin(clampf(k, -1.0, 1.0)) / PI
	return [z_in * (1.0 - 2.0 * u0), z_in]


## Cat de departe de axa e AXA ocolului la un z dat (m), si cat de departe e
## marginea lui dinspre drum. `INF` daca acolo nu exista ocol.
func _service_center_mag(z: float) -> float:
	if service_offset <= 0.01:
		return INF
	var z_in := _lip_near() + service_lead
	if absf(z) > z_in:
		return INF
	var u := (z_in - z) / (2.0 * z_in)
	return road_half_width * 0.45 + service_offset * sin(u * PI)


func _service_inner_mag(z: float) -> float:
	var c := _service_center_mag(z)
	return INF if is_inf(c) else c - service_width * 0.5


## Unde sta efectiv linia de bariere (z local). Vezi nota de la `gate_lead`.
func _gate_z() -> float:
	var z := _lip_near() + gate_lead
	var win := _merge_window()
	if win.size() == 2 and win[1] - win[0] > 2.0:
		z = clampf(z, win[0] + 1.0, win[1] - 1.0)
	return z


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
		_slab(st, body, Vector3(-hw, deck_rise, z0), Vector3(hw, deck_rise, z0),
			Vector3(hw, deck_rise, z1), Vector3(-hw, deck_rise, z1))
		_deck_parapets(st, body, absf(z0), absf(z1), sign_z, deck_rise, deck_rise)
		if deck_rise <= 0.01:
			continue
		var z2 := sign_z * (lip + deck_run + ramp_run)
		_slab(st, body, Vector3(-hw, deck_rise, z1), Vector3(hw, deck_rise, z1),
			Vector3(hw, 0.0, z2), Vector3(-hw, 0.0, z2))
		_deck_parapets(st, body, absf(z1), absf(z2), sign_z, deck_rise, 0.0)
	var mi := PaletteBox.emit(st, "DeckMesh")
	if mi != null:
		body.add_child(mi)


## Rampa de serviciu: un cot care iese lateral inainte de buza, trece pe langa
## gol si se intoarce pe pasaj dupa cealalta buza.
##
## Costul ei nu e lungimea in plus (cativa metri), ci VIRAJELE: doua coturi pe
## o banda mai ingusta te obliga sa ridici piciorul, si de acolo vin secundele
## din contractul de pedeapsa. Sonda le masoara.
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
	for i in n + 1:
		var u := float(i) / float(n)
		var z := lerpf(z_in, z_out, u)
		# Cotul: o SINGURA functie neteda intre cele doua racorduri, deci
		# nicio imbinare de portiuni care sa lase prag (memoria
		# `suprafete-din-placi-plane`).
		var bulge := sin(u * PI)
		var x := side * (road_half_width * 0.45 + service_offset * bulge)
		pts.append(Vector3(x, deck_rise, z))
	_service_points = pts
	var half_w := service_width * 0.5
	# Fereastra de desprindere: singurul loc in care marginea dinspre drum a
	# ocolului n-are voie sa aiba parapet.
	var win := _merge_window()
	for i in n:
		var a := pts[i]
		var b := pts[i + 1]
		var dir := b - a
		dir.y = 0.0
		if dir.length_squared() < 1e-6:
			continue
		var lat := Vector3(-dir.z, 0.0, dir.x).normalized() * half_w
		_slab(st, body, a - lat, a + lat, b + lat, b - lat)
		# Parapetul creste doar unde marginea a IESIT de pe pasaj: peste
		# carosabil ar fi un zid fix pe banda directa, iar in consola e
		# singurul lucru care tine masina pe ocol.
		for edge_sign: float in [-1.0, 1.0]:
			var ea := a + lat * edge_sign
			var eb := b + lat * edge_sign
			if absf(ea.x) <= road_half_width + 0.2 					or absf(eb.x) <= road_half_width + 0.2:
				continue
			# Marginea dinspre axa drumului e cea pe care se INTRA pe ocol.
			# Un parapet acolo, unde ocolul tocmai se desprinde, e un zid pus
			# de-a curmezisul manevrei de schimbare de banda — sonda a oprit
			# masina in capatul lui, la 6 m de gol. Deci pe partea dinspre drum
			# parapetul lipseste EXACT pe fereastra de desprindere, si exista
			# peste tot in rest.
			#
			# „In rest" a insemnat initial doar in dreptul golului (|z| sub
			# lip+2), si intre el si fereastra ramanea o pana de AER: ocolul se
			# departeaza de pasaj mai repede decat isi ia parapetul, deci la
			# z = 8..13 exista un culoar de ~3 m intre buza pasajului si
			# marginea ocolului, fara nimic dedesubt. Sonda a cazut fix in el
			# (masina scoasa din bariere, y de la 3.0 la 1.39, rasturnata la
			# up.y 0.57). Parapetul urca acum pana la buza ferestrei.
			var outer := absf(ea.x) > absf(a.x)
			var inner_free: float = win[0] if win.size() == 2 else _lip_near() + 2.0
			if not outer and absf((ea.z + eb.z) * 0.5) > inner_free:
				continue
			_parapet(st, body, ea, eb)
	var mi := PaletteBox.emit(st, "ServiceMesh")
	if mi != null:
		# Cu 2 cm sub pasaj: capetele ocolului se suprapun peste carosabil, iar
		# doua suprafete coplanare se bat in z-buffer. Coliziunea RAMANE la
		# cota pasajului — nu se coboara si ea, altfel racordul ar fi o treapta
		# de 2 cm exact pe linia de rulare.
		mi.position = Vector3(0.0, -0.02, 0.0)
		body.add_child(mi)


## Parapetii unei portiuni de pasaj, pe amandoua marginile, in pasi de ~2 m
## ca sa poata lipsi exact peste fereastra de desprindere a ocolului.
func _deck_parapets(st: SurfaceTool, body: StaticBody3D, za: float, zb: float,
		sign_z: float, ya: float, yb: float) -> void:
	if deck_parapet <= 0.01:
		return
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
		for edge_sign: float in [-1.0, 1.0]:
			# Fereastra de desprindere se taie doar din marginea pe care
			# chiar iese ocolul; cealalta ramane inchisa peste tot.
			if in_window and is_equal_approx(edge_sign, side):
				continue
			_parapet(st, body,
				Vector3(edge_sign * hw, y_a, sign_z * z_a),
				Vector3(edge_sign * hw, y_b, sign_z * z_b), deck_parapet)


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


## O placa: mesh pe atlas + colizor convex cu talpa sub ea.
func _slab(st: SurfaceTool, body: StaticBody3D, a: Vector3, b: Vector3,
		c: Vector3, d: Vector3) -> void:
	PaletteBox.quad_slab(st, a, b, c, d, DECK_THICK, deck_slot)
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
	_span.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, deck_rise, 0.0))
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
		near_x = side * maxf(inner, -road_half_width)
	var center_x := (far_x + near_x) * 0.5
	_gate.transform = Transform3D(basis, Vector3(center_x, deck_rise, gz))
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


## Semaforul de santier, pe marginea dinspre ocol, inaintea portii.
func _build_lamp() -> void:
	var side := signf(float(service_side))
	var at := Vector3(side * (road_half_width + 1.2), deck_rise, _gate_z() + 8.0)
	var post := PaletteBox.instance(Vector3(0.24, 3.2, 0.24),
		Palette.PAINTED_METAL, at + Vector3.UP * 1.6)
	post.name = "SignalPost"
	add_child(post)
	_lamp = HazardLamp.new()
	_lamp.name = "SignalHead"
	add_child(_lamp)
	_lamp.position = at + Vector3.UP * 3.2


# ---------------------------------------------------------- pentru sonde

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
		out.append(to_global(Vector3(0.0, deck_rise, z)))
	return out
