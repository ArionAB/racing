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
var _unstick_timer: float = 0.0
var _unstick_reversing: bool = false
var _unstick_steer: float = 0.0
var _attempts: int = 0
## Masina pe care o ocolim acum si partea aleasa (-1 stanga, +1 dreapta).
## Tinem minte ALEGEREA per blocaj: fara histereza, un autobuz pe axa ar face
## urmaritorul sa penduleze stanga-dreapta la fiecare centimetru de deriva.
var _avoid_car: Car = null
var _avoid_side: float = 0.0

func configure(race_track: Track, rng: RandomNumberGenerator,
		cars: Array[Car] = []) -> void:
	track = race_track
	traffic = cars
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
	# Cineva mai lent pe culoarul nostru? Linia se muta pe langa el.
	line = _avoid_line(idx, speed, line, keep_off)
	var near := track.lookahead_point(idx, _lookahead_near(speed), line, car.route)
	# Bifurcatia: cine a decis ca o ia, tinteste banda cealalta cat timp cele
	# doua sunt inca lipite. Comutarea propriu-zisa de ruta o face Car, pe
	# proximitate laterala — aici doar ne mutam acolo la timp.
	# `prefers_shortcut` se trage o data pe cursa, dar o scurtatura poate fi
	# INCHISA la un moment dat (limba de lava de pe Stromboli, care creste tur
	# de tur). De-asta se intreaba pista de fiecare data, nu doar la start:
	# fara asta, un AI care a decis la turul 1 "o iau pe scurta" intra in zid
	# la turul 3.
	if prefers_shortcut and car.route == 0 and track.branch_is_open(1):
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

# --------------------------------------------------------------- depasirea

## Muta linia tinta pe langa cea mai apropiata masina care ne blocheaza
## culoarul. Intoarce linia nemodificata cand drumul e liber.
##
## Decizia se ia mereu fata de linia de BAZA (personalitate + interiorul
## virajului), nu fata de cea deja mutata: baza nu se schimba in timpul
## depasirii, deci nici verdictul "imi sta in drum / nu-mi sta" — fara asta,
## prima mutare reusita ar curata blocajul din propriul test si linia ar
## pendula intre cele doua raspunsuri la 60 Hz.
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
	var l_ok := cand_l >= -LINE_MAX
	var r_ok := cand_r <= LINE_MAX
	var target: float
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
	return lerpf(line, clampf(target, -LINE_MAX, LINE_MAX), t)

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
