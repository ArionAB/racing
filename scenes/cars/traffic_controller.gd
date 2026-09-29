class_name TrafficController
extends CarController
## Creierul traficului de tuk-tuk-uri (Jodhpur, Track17, brief §3 „Traficul de
## tuk-tuk-uri"). Spre deosebire de AIController, care ISI ALEGE linia dupa
## viraje si trafic, un tuk-tuk are un SINGUR comportament, simplu si repetitiv
## — exact ce te-ai astepta de la un vehicul comercial care isi face rondul:
## tine banda stanga (India circula pe stanga), la viteza lui de croaziera,
## fara drift, fara turbo, fara scurtaturi (`route` 0 mereu).
##
## E un corp `Car` ADEVARAT (RigidBody3D cu suspensie pe raycast), nu un hazard
## cinematic — principiul 1 din CLAUDE.md ("masa decide, contactul e mecanica")
## cere ca imbrancelile cu tuk-tuk-urile sa treaca prin ACELASI solver ca intre
## masinile de cursa. `CarData.tuktuk.tres` ii da identitatea: usor (mass_factor
## 0.34 — retunat masurat fata de 0.45 din brief, vezi tools/probe_jod_tuk.gd)
## si cu centrul de masa ridicat (center_of_mass_y), deci se poate rasturna la
## o lovitura tare — asta e juice, nu bug.
##
## AI-ul de cursa il vede GRATIS: `Race._spawn_traffic` adauga fiecare
## tuk-tuk in `_ai_visible`, aceeasi lista pe care o primesc si masinile de
## cursa prin `AIController.configure` — deci `_avoid_line` (campul `traffic`
## de-acolo) il vede ca pe orice alt obstacol. Vezi brief §3, randul „Traficul
## de tuk-tuk-uri", coloana cod. Tuk-tuk-urile insele NU intra in `Race.cars`
## (clasament/tururi/HUD/race_finished) — vezi `Race._spawn_traffic`.

## Viteza de croaziera (m/s) — brief: 14 m/s, 41% din viteza de varf de baza.
const CRUISE_SPEED: float = 14.0
## Offset lateral fix fata de AXA drumului (m, semn ca `side_at`: pozitiv =
## dreapta sensului de mers). India circula pe STANGA, deci negativ.
const LANE_OFFSET_M: float = -2.2
## Cat se mai trage spre stanga cand claxoneaza (m) — brief: "se trage inca
## 0,5 m spre stanga".
const HONK_PULL_M: float = 0.5
## Sub cati metri, in spate, o masina mai rapida declanseaza claxonul.
const HONK_RANGE_M: float = 25.0
## Peste ce diferenta de viteza (m/s) o masina din spate conteaza ca "mai
## rapida" — sub atat, nu are sens sa se traga din drum pentru cineva care
## oricum nu o ajunge din urma.
const HONK_SPEED_DIFF: float = 6.0
## Cat tine tragerea spre stanga dupa ultimul claxon (s) — histereza mica, ca
## linia sa nu tremure intre doua cadre cand masina din spate oscileaza chiar
## in jurul pragului de viteza/distanta.
const HONK_HOLD_S: float = 1.2

## Viteza cu care un tuk-tuk ia buza unei sarituri de canal (m/s). ProbeJump pe
## Devkund (gol 15.4 m): Muscle cade la 20 m/s si trece la 24 cu +4.6 m marja.
const JUMP_SPEED: float = 26.0
## Pe cati metri dinaintea buzei isi ia elanul.
const JUMP_RUNUP_M: float = 40.0

## Rasturnat sau oprit peste atata (s) -> se redreseaza singur (impuls "de
## jucarie" — brief: "o saritura de jucarie").
const UPSIDE_RECOVER_S: float = 2.5
## Oprit (in banda, nerasturnat) peste atata (s) -> reapare pe traseu.
const STUCK_RESPAWN_S: float = 6.0
## Sub ce viteza (m/s) tuk-tuk-ul conteaza ca "oprit" pentru ambele ceasuri de
## mai sus — nu 0 exact, fizica tremura langa zero (acelasi prag ca la AI).
const STOPPED_SPEED: float = 1.0
## Sub ce unghi (cos fata de UP) corpul e "rasturnat". Un tuk-tuk inclinat
## puternic dar inca pe roti (juice-ul de suspensie/impact) nu trebuie sa se
## redreseze singur imediat — doar cel chiar cu rotile in aer.
const UPSIDE_DOWN_COS: float = 0.35
## Impulsul de redresare (m/s echivalent, vezi _self_right): suficient sa-l
## puna inapoi pe roti fara sa para ca zboara.
const RECOVER_IMPULSE: float = 5.0
## Reaparitia nu are voie sa puna corpul peste alt corp — cauta un punct de pe
## traseu la cel putin atatia metri de ORICE masina de cursa (memoria
## `corp-cinematic-aparut-in-masina`: un corp aparut in interiorul altuia il
## azvarle cu sute de m/s).
const RESPAWN_CLEAR_M: float = 60.0
## Cati indici (pe traseu) se sare intre incercarile de gasire a unui punct de
## reaparitie liber — pas mic, ca sa nu rateze un culoar ingust de siguranta.
const RESPAWN_STEP_M: float = 20.0

## Toate masinile de CURSA (jucator + AI) — pentru regula de claxon si pentru
## verificarea de siguranta la reaparitie. NU celelalte tuk-tuk-uri: doua
## tuk-tuk-uri care se ajung din urma la aceeasi viteza nu au motiv sa se
## claxoneze reciproc (brief: masina "mai rapida", nu "orice masina").
var race_cars: Array[Car] = []
var track: Track

## Verbose: printeaza claxonul si redresarile/reaparitiile in consola — util la
## sonda si la ProbeRace cu trafic (brief §4(c)).
var verbose: bool = false

signal honked(tuktuk: Car)

var _upside_time: float = 0.0
var _stopped_time: float = 0.0
var _honk_hold: float = 0.0
var _steer: float = 0.0
var _throttle: float = 1.0

func configure(race_track: Track, cars: Array[Car] = []) -> void:
	track = race_track
	race_cars = cars

func update(delta: float) -> void:
	if track == null or car == null:
		return
	# Rasturnare/stagnare: verificata si tratata AICI, nu doar masurata — daca a
	# actionat (redresare sau reaparitie), ceasurile sunt deja taiate la 0 si
	# codul de mai jos ruleaza normal, pe pozitia noua, in acelasi cadru (nu
	# mai are sens sa mai directioneze catre o tinta veche).
	_watch_flip_and_stall(delta)

	# Niciodata pe scurtatura (brief: "nu ia scurtaturi, route 0 mereu") — dar
	# `Car._physics_process` cheama `track.resolve_route` NECONDITIONAT pentru
	# orice corp, doar dupa proximitate laterala (vezi Track.resolve_route),
	# indiferent de controller. Un tuk-tuk care trece aproape de o despicatura
	# ar fi comutat exact ca un AI — se forteaza inapoi pe ruta principala,
	# cu indexul recalculat pe ea (nu pastram un index de pe alta banda).
	if car.route != 0:
		car.route = 0
		car.road_index = track.closest_index_global(car.global_position, 0)

	var idx := car.road_index
	var speed := car.horizontal_speed()

	# --- linia: banda stanga fixa, +tragere suplimentara la claxon ---
	var hw := maxf(track.width_at_index(idx), 0.001)
	var target_lat := LANE_OFFSET_M
	if _honk_check(idx, speed):
		target_lat -= HONK_PULL_M
		_honk_hold = HONK_HOLD_S
	elif _honk_hold > 0.0:
		_honk_hold -= delta
		target_lat -= HONK_PULL_M
	var line := clampf(target_lat / hw, -1.0, 1.0)

	var near := track.lookahead_point(idx, _lookahead_m(speed), line, 0)
	var fwd := -car.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	_steer = clampf(_angle_to(fwd, near) * 2.2, -1.0, 1.0)

	# --- elanul de saritura (Devkund, brief §2 G2) ---
	# La 14 m/s un tuk-tuk nu trece niciun gol de canal: ar cadea in apa,
	# RespawnZone l-ar pune inapoi cu 70 m de elan (tot la 14 m/s) si ar cadea
	# iar, la nesfarsit — o coada de tuk-tuk-uri pe loc chiar pe dreapta de
	# lansare. Deci pe ultimii JUMP_RUNUP_M dinaintea buzei viteza e impinsa
	# spre JUMP_SPEED (motorul lui are plafon 18, deci impingerea e directa pe
	# corp, ca redresarea "de jucarie"). Dupa aterizare franeaza singur inapoi
	# la croaziera.
	var to_lip := track.jump_lip_ahead(idx, JUMP_RUNUP_M)
	if to_lip >= 0.0:
		var want := lerpf(JUMP_SPEED, CRUISE_SPEED, to_lip / JUMP_RUNUP_M)
		if speed < want:
			var r := track.route_at(0)
			var dir := r.baked[r.wrap_index(idx + 1)] - r.baked[r.wrap_index(idx)]
			dir.y = 0.0
			if dir.length_squared() > 0.001:
				var v := car.linear_velocity
				var add := dir.normalized() * (want - speed)
				car.linear_velocity = Vector3(v.x + add.x, v.y, v.z + add.z)
		_throttle = 1.0
		return

	# --- pedale: tinta fixa de croaziera, fara drift, fara turbo ---
	if speed > CRUISE_SPEED * 1.05:
		_throttle = clampf(-(speed - CRUISE_SPEED) / 6.0, -1.0, -0.1)
	else:
		_throttle = 1.0

func _lookahead_m(speed: float) -> float:
	return clampf(speed * 0.9, 8.0, 18.0)

func _angle_to(fwd: Vector3, point: Vector3) -> float:
	var to_point := point - car.global_position
	to_point.y = 0.0
	if to_point.length_squared() < 0.001:
		return 0.0
	return fwd.signed_angle_to(to_point.normalized(), Vector3.UP)

## Claxonul: o masina de cursa mai rapida (>HONK_SPEED_DIFF), in spate, la
## <HONK_RANGE_M — brief: "cand te apropii din spate la < 25 m si > 6 m/s
## diferenta, claxoneaza". Distanta se masoara PE AXA DRUMULUI (acelasi tipar
## ca AIController._avoid_line), nu euclidian: intr-un viraj strans doua masini
## la 25 m de drum pot fi la cativa metri euclidian una de alta pe benzi
## diferite.
func _honk_check(idx: int, my_speed: float) -> bool:
	var r := track.route_at(0)
	if r == null or r.count() == 0:
		return false
	var n := r.count()
	for other in race_cars:
		if other == null or not is_instance_valid(other) or other.route != 0:
			continue
		var d := idx - other.road_index # pozitiv = celalalt e IN SPATE
		if r.closed:
			if d > n / 2:
				d -= n
			elif d < -n / 2:
				d += n
		var behind_m := float(d) * track.curve.bake_interval
		if behind_m <= 0.0 or behind_m > HONK_RANGE_M:
			continue
		if other.horizontal_speed() - my_speed < HONK_SPEED_DIFF:
			continue
		honked.emit(car)
		if verbose:
			print("[tuk-tuk] %s claxoneaza — %s la %.1f m in spate, +%.1f m/s"
				% [car.pilot_name, other.pilot_name, behind_m,
					other.horizontal_speed() - my_speed])
		return true
	return false

## Cat sub cota drumului (m) inseamna "cazut din lume" — acelasi prag ca
## `Race._watch_recovery` (plasa de siguranta a masinilor de cursa). Tuk-
## tuk-urile NU sunt in `Race.cars`, deci plasa aia nu le vede: un tuk-tuk
## impins peste o margine ar cadea la nesfarsit, fara nicio redresare (viteza
## de cadere trece de STOPPED_SPEED, deci `_stopped_time` n-ar mai creste).
const FALL_BELOW_M: float = 25.0

## Rasturnare, stagnare si cadere din lume — brief §3: "Rasturnat sau oprit
## > 2,5 s: se ridica singur... Oprit > 6 s in banda: reapare". Caderea nu e
## in brief (Jodhpur n-avea inca prapastii cand a fost scris), dar e acelasi
## gen de plasa pe care orice alt corp din cursa o are deja.
func _watch_flip_and_stall(delta: float) -> void:
	var up_dot := car.global_transform.basis.y.dot(Vector3.UP)
	var flipped := up_dot < UPSIDE_DOWN_COS
	var speed := car.horizontal_speed()
	if flipped:
		_upside_time += delta
	else:
		_upside_time = 0.0
	if speed < STOPPED_SPEED:
		_stopped_time += delta
	else:
		_stopped_time = 0.0

	var route := track.route_at(0)
	if route != null and route.count() > 0:
		var ref_y: float = route.baked[route.wrap_index(car.road_index)].y
		if car.global_position.y < ref_y - FALL_BELOW_M:
			_respawn_clear()
			return
	if _upside_time > UPSIDE_RECOVER_S:
		_self_right()
		return
	if _stopped_time > STUCK_RESPAWN_S:
		_respawn_clear()
		return

## Impuls "de jucarie" care il pune inapoi pe roti — nu e o simulare de
## rasturnare reala (n-avem nici timp, nici nevoie de-atat), doar o rotatie
## rapida spre orientarea normala plus un mic salt, ca un tuk-tuk de jucarie
## impins cu mana inapoi in picioare.
func _self_right() -> void:
	if verbose:
		print("[tuk-tuk] %s se redreseaza singur (rasturnat %.1fs)"
			% [car.pilot_name, _upside_time])
	var fwd := -car.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length_squared() < 0.001:
		fwd = Vector3.FORWARD
	fwd = fwd.normalized()
	car.global_transform = Transform3D(
		Basis.looking_at(fwd, Vector3.UP), car.global_position + Vector3.UP * 0.6)
	car.linear_velocity = Vector3.UP * RECOVER_IMPULSE
	car.angular_velocity = Vector3.ZERO
	_upside_time = 0.0
	_stopped_time = 0.0

## Reaparitia: un punct pe traseu la >= RESPAWN_CLEAR_M de ORICE masina de
## cursa. NU pune corpul peste alt corp (memoria `corp-cinematic-aparut-in-
## masina`) — cauta in pasi mici pornind de la pozitia curenta, ca reaparitia
## sa ramana pe undeva prin apropiere, nu sa sara la capatul opus al pistei.
func _respawn_clear() -> void:
	var r := track.route_at(0)
	if r == null or r.count() == 0:
		return
	var n := r.count()
	var step := maxi(1, int(RESPAWN_STEP_M / maxf(track.curve.bake_interval, 0.001)))
	var start_idx := car.road_index
	var candidate := start_idx
	var found := false
	for tries in (n / maxi(step, 1)) + 1:
		candidate = ((start_idx + tries * step) % n + n) % n
		if _is_clear_of_cars(candidate):
			found = true
			break
	if not found:
		# Pista e plina de masini pe toata lungimea (n-ar trebui sa se
		# intample cu 8 masini pe kilometri de asfalt) — mai bine ramanem pe
		# loc decat sa punem corpul peste altul.
		if verbose:
			print("[tuk-tuk] %s nu are unde reaparea (pista prea aglomerata)"
				% car.pilot_name)
		_stopped_time = 0.0
		return
	var pos := r.baked[r.wrap_index(candidate)] + Vector3.UP * 0.5
	var dir := (r.baked[r.wrap_index(candidate + 1)]
		- r.baked[r.wrap_index(candidate)])
	dir.y = 0.0
	if dir.length_squared() < 0.001:
		dir = Vector3.FORWARD
	car.global_transform = Transform3D(
		Basis.looking_at(dir.normalized(), Vector3.UP), pos)
	car.linear_velocity = dir.normalized() * CRUISE_SPEED
	car.angular_velocity = Vector3.ZERO
	car.route = 0
	car.road_index = candidate
	car.last_safe_index = candidate
	car.last_safe_route = 0
	if verbose:
		print("[tuk-tuk] %s a reaparut la index %d (>= %.0f m de orice masina)"
			% [car.pilot_name, candidate, RESPAWN_CLEAR_M])
	_upside_time = 0.0
	_stopped_time = 0.0

func _is_clear_of_cars(idx: int) -> bool:
	var r := track.route_at(0)
	var n := r.count()
	for other in race_cars:
		if other == null or not is_instance_valid(other):
			continue
		var od := other.road_index
		if other.route != 0:
			# O masina pe scurtatura nu are index comparabil pe ruta
			# principala — distanta ei EUCLIDIANA e verificarea de rezerva.
			var pos := r.baked[r.wrap_index(idx)]
			if pos.distance_to(other.global_position) < RESPAWN_CLEAR_M:
				return false
			continue
		var d := idx - od
		if r.closed:
			if d > n / 2:
				d -= n
			elif d < -n / 2:
				d += n
		if absf(float(d) * track.curve.bake_interval) < RESPAWN_CLEAR_M:
			return false
	return true

func get_steer() -> float:
	return _steer

func get_throttle() -> float:
	return _throttle

func is_drift_pressed() -> bool:
	return false

func is_turbo_pressed() -> bool:
	return false
