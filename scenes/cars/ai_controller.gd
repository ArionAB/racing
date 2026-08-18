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

var track: Track
## Linia "de personalitate" a pilotului: fiecare are alt culoar preferat pe
## portiunile drepte. Peste ea se adauga tragerea spre interiorul virajului.
var line_offset: float = 0.0

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
var _unstick_timer: float = 0.0
var _unstick_reversing: bool = false
var _unstick_steer: float = 0.0
var _attempts: int = 0

func configure(race_track: Track, rng: RandomNumberGenerator) -> void:
	track = race_track
	line_offset = rng.randf_range(-0.28, 0.28)
	prefers_shortcut = rng.randf() < SHORTCUT_CHANCE

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
	# Sector cu hazard PE AXA (trenul pe sens de pe Baikal): pilotul se tine
	# de margine, pe partea lui de personalitate. Zero peste tot in rest.
	var keep_off := track.lane_bias_at(idx)
	if keep_off > 0.0:
		var side_pref := signf(line_offset) if absf(line_offset) > 0.02 else 1.0
		line = side_pref * maxf(absf(line), keep_off)
	var near := track.lookahead_point(idx, _lookahead_near(speed), line, car.route)
	# Bifurcatia: cine a decis ca o ia, tinteste banda cealalta cat timp cele
	# doua sunt inca lipite. Comutarea propriu-zisa de ruta o face Car, pe
	# proximitate laterala — aici doar ne mutam acolo la timp.
	if prefers_shortcut and car.route == 0:
		var lure := track.branch_lure(car.global_position, _lookahead_near(speed))
		if lure != Vector3.INF:
			near = lure
	_steer = clampf(_angle_to(fwd, near) * 2.2, -1.0, 1.0)

	# --- pedale: viteza-tinta din cat de stramt e ce urmeaza ---
	var target := car.max_speed * lerpf(1.0, CORNER_SPEED_FLOOR, severity)
	# Pe banda uda ridica piciorul, ca un sofer.
	#
	# Fara asta AI-ul intra pe bancul de nisip cu viteza de asfalt, aluneca si
	# iese in apa: masurat, 27% din timp in afara soselei si tururile scadeau de
	# la 2.5 la 1.6. Nu era o problema de fizica — grip-ul taiat isi facea exact
	# treaba — ci de sofer care nu se uita la suprafata.
	if track.route_is_wet(car.route):
		target *= WET_SPEED_FACTOR
	if speed > target * 1.06:
		# Franare proportionala cu depasirea, nu o smucitura fixa.
		_throttle = clampf(-(speed - target) / 6.0, -1.0, -0.15)
	else:
		_throttle = 1.0

	# --- drift (handbrake) pe viraje sustinute: si vireaza, si umple bara ---
	if not _drift:
		if severity > 0.34 and speed > car.drift_min_speed * 1.2:
			_drift = true
	elif severity < 0.12 or speed < car.drift_min_speed * 0.7:
		_drift = false

	# --- turbo: pe drept, si oprit inainte de viraj, ca sa nu-l irosim in perete
	if not _turbo:
		if car.turbo_charge > 0.6 and severity <= 0.0 and _throttle > 0.0:
			_turbo = true
	elif car.turbo_charge < 0.05 or severity > 0.25:
		_turbo = false

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
	if _unstick_timer > 0.0:
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
