extends Node
## Sonda de TUNARE: masoara ce simti pe pista, dar in cifre. Doua moduri, ambele
## headless, ca sa poti compara "inainte / dupa" la fiecare schimbare de fizica
## sau de AI (CLAUDE.md: verificare cu sonde inainte de commit).
##
##   race  — o cursa cu 4 AI pe o pista: tururi, timp in afara soselei, timp
##           mers incet, marsarier de anti-blocaj, repuneri, izbituri in pereti,
##           imbranceli si lovituri de la obstacolele mobile.
##   bump  — matricea de imbranceli intre masini: cine pe cine arunca si cu cat.
##           Aici se vede daca "grea impinge, usoara zboara" e adevarat.
##   cliff — arunca masini in unghi in peretii de canion, in mai multe puncte de
##           pe traseu, si raporteaza daca vreuna ramane intepenita. Peretii sunt
##           ~130 de forme convexe puse cap la cap; imbinarile dintre ele sunt
##           exact locul unde o masina se poate agata.
##
## Rulare (ca SCENA, nu ca --script: avem nevoie de autoload-urile GameState /
## AudioManager, iar acelea nu exista in modul --script):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn
##   ... -- --mode=bump
##   ... -- --mode=race --track=0 --seconds=150 [--car=0]
##   ... -- --mode=cliff --track=0

const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
## Seed fix: doua rulari ale aceleiasi versiuni trebuie sa dea aceleasi cifre,
## altfel comparatia "inainte / dupa" nu inseamna nimic.
const SEED: int = 20260729
## Suprascris cu --seed=N: acelasi cod, seed-uri diferite = mai multe curse
## independente. Un blocaj care apare la 1 din 5 seed-uri e tot un blocaj.
var _seed: int = SEED
## Masina jucatorului, index in GameState.CAR_DATA. Suprascris cu --car=N.
## 0 = Muscle, masina de referinta a proiectului.
var _player_car: int = 0
## Viteza de sosire a atacatorului in modul bump (m/s).
const BUMP_ENTRY_SPEED: float = 26.0

# --- modul cliff ---
## Cu ce viteza se arunca masina in perete.
const CLIFF_ENTRY_SPEED: float = 20.0
## Unghiul fata de directia drumului: 0 = paralel, 90 = perpendicular pe perete.
## 35° e cazul rau realist — o iesire larga din viraj, nu un impact frontal.
const CLIFF_ANGLE_DEG: float = 35.0
## Cat timp se urmareste fiecare caz. Generos: AI-ul are anti-blocaj cu marsarier,
## si vrem sa-i dam sansa sa-l foloseasca inainte sa-l declaram blocat.
const CLIFF_CASE_SECONDS: float = 8.0
## Sub viteza asta masina e considerata "oprita".
const CLIFF_STUCK_SPEED: float = 2.0
## Cat timp trebuie sa stea oprita ca sa fie declarata INTEPENITA. Peste durata
## manevrei de desprindere (frana + marsarier + reluare), ca sa nu confundam o
## recuperare reusita cu un blocaj.
const CLIFF_STUCK_SECONDS: float = 3.5
## Fractiile de traseu testate. Alese sa acopere: doua drepte, doua viraje, si
## doua zone unde sectiunile de faleza se imbina in unghi.
const CLIFF_FRACS: Array[float] = [0.12, 0.31, 0.44, 0.58, 0.73, 0.91]

var _mode: String = "race"
var _track_index: int = 0
var _seconds: float = 150.0

var _race: Node = null
var _elapsed: float = 0.0
var _stats: Array[Dictionary] = []
var _done: bool = false

## Pista taiata in felii egale, ca sa vezi UNDE se scurge viteza.
const BUCKETS: int = 20
var _bucket_speed: PackedFloat32Array = PackedFloat32Array()
var _bucket_samples: PackedInt32Array = PackedInt32Array()
var _bucket_slow: PackedInt32Array = PackedInt32Array()
var _bucket_walls: PackedInt32Array = PackedInt32Array()

# --- mod cliff ---
var _cliff_cases: Array[Dictionary] = []
var _cliff_case: int = -1
var _cliff_car: Car = null
var _cliff_track: Track = null
var _cliff_time: float = 0.0
var _cliff_slow_time: float = 0.0
var _cliff_rows: Array[Dictionary] = []

# --- mod bump ---
var _bump_cases: Array[Dictionary] = []
var _bump_case: int = -1
var _bump_frames: int = 0
var _bump_attacker: Car = null
var _bump_victim: Car = null
var _bump_rows: Array[Dictionary] = []
var _bump_peak: float = 0.0
var _bump_attacker_loss: float = 0.0
## Directia initiala a victimei — diferenta finala e rotatia PRIMITA din lovitura.
var _bump_victim_yaw0: float = 0.0
## Cea mai mica viteza a atacatorului dupa contact: "zidul" se vede aici — pe
## modelul vechi cobora la ~0 chiar si intre mase egale, desi fizica cerea ca
## amandoua masinile sa-si continue drumul.
var _bump_attacker_floor: float = 0.0
var _bump_impulses_att: int = 0
var _bump_impulses_vic: int = 0
var _bump_impulse_peak_att: float = 0.0
var _bump_impulse_peak_vic: float = 0.0

## Controller de laborator: comenzi fixe, fara "creier".
class ScriptedController extends CarController:
	var throttle: float = 1.0
	var steer: float = 0.0

	func get_throttle() -> float:
		return throttle

	func get_steer() -> float:
		return steer


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--car="):
			_player_car = int(arg.trim_prefix("--car="))
	# Masina jucatorului se FIXEAZA, nu se mosteneste.
	#
	# `GameState.selected_car` se salveaza in `user://settings.cfg`, deci sonda
	# rula pe orice masina ai ales ultima data cand ai deschis jocul. Doua rulari
	# ale aceluiasi cod dadeau 3.96 si 3.57 tururi si arata ca o regresie de la
	# assets — de fapt se schimbase masina sub noi. Aceeasi capcana ca la
	# --mode=cliff, care nu-si seta `car.track` si masura altceva decat credea.
	GameState.selected_car = clampi(_player_car, 0, GameState.CAR_DATA.size() - 1)
	match _mode:
		"race":
			_start_race()
		"bump":
			_start_bump()
		"cliff":
			_start_cliff()
		_:
			push_error("probe_race: mod necunoscut '%s'" % _mode)
			get_tree().quit(1)


func _physics_process(delta: float) -> void:
	if _done:
		return
	match _mode:
		"bump":
			_tick_bump()
		"cliff":
			_tick_cliff(delta)
		_:
			_tick_race(delta)


func _finish() -> void:
	_done = true
	get_tree().quit(0)


# --------------------------------------------------------------- mod cursa

func _start_race() -> void:
	GameState.selected_track = _track_index
	GameState.champ_active = false
	GameState.total_laps = 99 # cursa nu se termina singura; o oprim pe timp
	_bucket_speed.resize(BUCKETS)
	_bucket_samples.resize(BUCKETS)
	_bucket_slow.resize(BUCKETS)
	_bucket_walls.resize(BUCKETS)
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)
	# Si rocket start-ul AI-ului trage la zaruri; fara seed fix, doua rulari ale
	# ACELUIASI cod pornesc diferit si "inainte / dupa" nu mai compara nimic.
	(_race._rng as RandomNumberGenerator).seed = _seed
	# Jucatorul primeste tot un creier AI: masuram pista, nu reflexele mele.
	var player: Car = _race.player
	var old: CarController = player.controller
	player.remove_child(old)
	old.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var car := cars[i]
		if car == player:
			var ai := AIController.new()
			car.set_controller(ai)
			ai.configure(_race.track, rng)
		else:
			(car.controller as AIController).line_offset = rng.randf_range(-0.35, 0.35)
		# Variatie onesta, dar determinista — altfel cifrele danseaza intre rulari.
		car.speed_scale = 1.0 if car == player else rng.randf_range(0.88, 0.97)
		_stats.append({
			"name": "%s (%s)" % [car.pilot_name, car.car_name],
			"offroad_s": 0.0, "slow_s": 0.0, "reverse_s": 0.0,
			"respawns": 0, "walls": 0, "wall_impact": 0.0,
			"bumps": 0, "bump_peak": 0.0,
			"slide_hits": 0, "carousel_hits": 0, "deflector_hits": 0,
			"speed_sum": 0.0, "samples": 0,
			"stuck_t": 0.0, "stuck_reports": 0,
		})
		car.respawned.connect(_on_respawn.bind(i))
		car.wall_hit.connect(_on_wall.bind(i))
		# Delta-v-ul REAL al imbrancelii, direct din model. Masurat ca diferenta
		# de viteza intre cadre ar aduna si gravitatia, aterizarile si turbo.
		# Conditionat: pe versiunile de dinaintea modelului de masa semnalul nu
		# exista, iar sonda trebuie sa poata masura si acele rulari (coloana
		# "bump/dv" ramane goala acolo, restul cifrelor sunt comparabile).
		if car.has_signal(&"bumped"):
			car.bumped.connect(_on_bumped.bind(i))


func _tick_race(delta: float) -> void:
	_elapsed += delta
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var car := cars[i]
		var st := _stats[i]
		var speed := car.horizontal_speed()
		st.speed_sum = float(st.speed_sum) + speed
		st.samples = int(st.samples) + 1
		if not _race.track.is_on_road(car.road_index, car.global_position,
				car.route):
			st.offroad_s = float(st.offroad_s) + delta
		if speed < 4.0:
			st.slow_s = float(st.slow_s) + delta
		if car.controller != null and car.controller.get_throttle() < -0.5:
			st.reverse_s = float(st.reverse_s) + delta
		# Pe fizica intreaga contactele vin de la solver (contact_monitor e
		# pornit in Car._ready), nu din move_and_slide.
		for hit in car.get_colliding_bodies():
			if hit is SlidingHazard:
				st.slide_hits = int(st.slide_hits) + 1
			elif _is_under(hit as Node, "CarouselHazard"):
				# Rotorul caruselului e COPIL al hazardului, deci colizionerul
				# nu e niciodata hazardul insusi.
				st.carousel_hits = int(st.carousel_hits) + 1
			elif _is_under(hit as Node, "DeflectorHazard"):
				st.deflector_hits = int(st.deflector_hits) + 1
		# Harta pistei: unde anume se scurge viteza. Fara ea nu stii daca AI-ul
		# pierde in acelasi viraj de fiecare data sau imprastiat peste tot.
		var b := clampi(int(_race.track.frac_at(car.road_index, car.route)
			* float(BUCKETS)),
			0, BUCKETS - 1)
		_bucket_speed[b] += speed
		_bucket_samples[b] += 1
		if speed < 4.0:
			_bucket_slow[b] += 1
		_watch_stuck(car, st, speed, delta)
	if _elapsed >= _seconds:
		_report_race()


func _is_under(node: Node, type_name: String) -> bool:
	var walker := node
	while walker != null:
		if walker.is_class(type_name) or (walker.get_script() != null
				and (walker.get_script() as Script).get_global_name() == type_name):
			return true
		walker = walker.get_parent()
	return false


## Un blocaj adevarat nu e "o clipa de incetinire", e o masina care nu mai
## progreseaza. Il raportam cu loc si vinovat — altfel tunezi in orb.
func _watch_stuck(car: Car, st: Dictionary, speed: float, delta: float) -> void:
	if _race.state != Race.State.RUNNING or speed > 6.0:
		st.stuck_t = 0.0
		return
	st.stuck_t = float(st.stuck_t) + delta
	if float(st.stuck_t) < 3.0 or int(st.stuck_reports) >= 6:
		return
	st.stuck_t = 0.0
	st.stuck_reports = int(st.stuck_reports) + 1
	var touching: Array[String] = []
	for body in car.get_colliding_bodies():
		var hit := body as Node3D
		if hit != null:
			touching.append("%s@(%.0f,%.0f,%.0f)" % [_describe(hit),
				hit.global_position.x, hit.global_position.y, hit.global_position.z])
	print("[blocaj] t=%5.1fs  %-18s frac=%.3f  v=%4.1f  lat=%4.1f  poz=(%.0f,%.0f,%.0f)  atinge: %s" % [
		_elapsed, st.name, _race.track.frac_at(car.road_index, car.route), speed,
		_race.track.lateral_distance(car.road_index, car.global_position,
			car.route),
		car.global_position.x, car.global_position.y, car.global_position.z,
		", ".join(touching) if not touching.is_empty() else "-"])


## Numele unui corp generat procedural nu spune nimic (@StaticBody3D@31);
## mesh-ul copil si culoarea lui spun exact ce bucata de pista e.
func _describe(body: Node3D) -> String:
	if not body.name.begins_with("@"):
		return String(body.name)
	for child in body.get_children():
		var mi := child as MeshInstance3D
		if mi == null:
			continue
		var mat := mi.material_override as StandardMaterial3D
		var tint := "?" if mat == null else "#%s" % mat.albedo_color.to_html(false)
		return "%s[%s]" % [body.get_class(), tint]
	return String(body.name)


func _on_bumped(_car: Car, _other: Car, delta_v: float, index: int) -> void:
	_stats[index].bumps = int(_stats[index].bumps) + 1
	_stats[index].bump_peak = maxf(float(_stats[index].bump_peak), delta_v)


func _on_respawn(car: Car, index: int) -> void:
	_stats[index].respawns = int(_stats[index].respawns) + 1
	# Unde a fost repusa: o repunere in acelasi loc, tur de tur, e o bucla
	# (masina cade, e repusa fara elan, cade iar) — vezi CHANNEL_FALL_BACKOFF.
	print("[repunere] t=%5.1fs  %-18s frac=%.3f  poz=(%.0f,%.0f,%.0f)" % [
		_elapsed, _stats[index].name,
		_race.track.frac_at(car.road_index, car.route),
		car.global_position.x, car.global_position.y, car.global_position.z])


func _on_wall(car: Car, impact: float, index: int) -> void:
	_stats[index].walls = int(_stats[index].walls) + 1
	_stats[index].wall_impact = maxf(float(_stats[index].wall_impact), impact)
	var b := clampi(int(_race.track.frac_at(car.road_index, car.route)
			* float(BUCKETS)),
		0, BUCKETS - 1)
	_bucket_walls[b] += 1


func _report_race() -> void:
	var track: Track = _race.track
	var cars: Array[Car] = _race.cars
	print("\n=== CURSA: %s — %.0fs, %d masini ===" % [
		track.track_name, _elapsed, cars.size()])
	print("%-20s %6s %6s %8s %7s %7s %5s %6s %9s %6s %6s %6s" % [
		"masina", "tururi", "v_med", "offroad", "lent", "invers",
		"resp", "pereti", "bump/dv", "minge", "carus", "deviat"])
	var worst_offroad := 0.0
	var total_respawns := 0
	var laps: Array[float] = []
	for i in cars.size():
		var st := _stats[i]
		var done := float(_race._progress[i].total)
		laps.append(done)
		var avg := float(st.speed_sum) / maxf(float(st.samples), 1.0)
		var off_pct := float(st.offroad_s) / _elapsed * 100.0
		worst_offroad = maxf(worst_offroad, off_pct)
		total_respawns += int(st.respawns)
		print("%-20s %6.2f %6.1f %7.1f%% %6.1fs %6.1fs %5d %6d %4d/%4.1f %6d %6d %6d" % [
			st.name, done, avg, off_pct, float(st.slow_s), float(st.reverse_s),
			int(st.respawns), int(st.walls), int(st.bumps), float(st.bump_peak),
			int(st.slide_hits), int(st.carousel_hits), int(st.deflector_hits)])
	laps.sort()
	print("--- ritm: cel mai rapid %.2f tururi, cel mai lent %.2f (ecart %.2f)" % [
		laps[laps.size() - 1], laps[0], laps[laps.size() - 1] - laps[0]])
	print("--- repuneri totale: %d · cel mai mult in afara soselei: %.1f%%" % [
		total_respawns, worst_offroad])
	print("\n--- unde se scurge viteza (felie de pista -> v_med, %% lent, pereti)")
	for b in BUCKETS:
		var samples := maxi(_bucket_samples[b], 1)
		var avg := _bucket_speed[b] / float(samples)
		var slow_pct := float(_bucket_slow[b]) / float(samples) * 100.0
		var bar := "#".repeat(int(avg / 2.0))
		print("  %.2f-%.2f  %5.1f m/s %5.1f%% lent %3d pereti  %s" % [
			float(b) / float(BUCKETS), float(b + 1) / float(BUCKETS),
			avg, slow_pct, _bucket_walls[b], bar])
	_finish()


# ---------------------------------------------------------------- mod bump

## Fiecare caz: atacatorul intra din spate in victima oprita, la aceeasi viteza.
## Daca modelul de masa e corect, dv-ul victimei creste cu raportul de mase, iar
## atacatorul greu isi pierde mult mai putina viteza decat cel usor.
func _start_bump() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 2, 400)
	shape.shape = box
	shape.position = Vector3(0, -1, 0)
	ground.add_child(shape)
	add_child(ground)
	var garage := GameState.CAR_DATA
	# (atacator, victima) — perechile care conteaza pentru principiul de design.
	for pair: Array in [[3, 0], [0, 3], [0, 1], [1, 0], [4, 2], [2, 4], [0, 0]]:
		_bump_cases.append({
			"attacker": garage[pair[0]] as CarData,
			"victim": garage[pair[1]] as CarData,
			"kind": "spate",
		})
	# Loviturile DIRECTIONALE: acelasi contact, alt loc pe caroserie.
	#   colt    — din spate, dar prins pe coltul victimei (PIT): trebuie sa o
	#             roteasca vizibil, in timp ce lovitura centrata de mai sus nu.
	#   lateral — in plin, perpendicular (T-bone): victima impinsa si sucita.
	for c: Array in [[0, 0, "colt"], [0, 0, "lateral"], [3, 1, "lateral"]]:
		_bump_cases.append({
			"attacker": garage[c[0]] as CarData,
			"victim": garage[c[1]] as CarData,
			"kind": c[2],
		})
	_next_bump_case()


func _next_bump_case() -> void:
	if _bump_attacker != null:
		_bump_attacker.queue_free()
		_bump_victim.queue_free()
		_bump_attacker = null
	_bump_case += 1
	if _bump_case >= _bump_cases.size():
		_report_bump()
		return
	var c := _bump_cases[_bump_case]
	var att := c.attacker as CarData
	var vic := c.victim as CarData
	var kind := String(c.kind)
	# Victima sta pe loc, cu botul spre -Z; atacatorul soseste deja lansat:
	# masuram impactul, nu accelerarea. Amandoua in liber — O SINGURA izbitura.
	_bump_victim = _spawn_bump_car(vic, Vector3(0, 0.6, 0), 0.0)
	match kind:
		"lateral":
			# T-bone: atacatorul vine perpendicular, dinspre +X, tintit putin
			# spre spatele victimei ca sa existe brat de parghie (in realitate
			# lovitura in dreptul centrului de masa doar impinge).
			var gap_x: float = (att.body_length + vic.body_width) * 0.5 + 4.0
			_bump_attacker = _spawn_bump_car(att,
				Vector3(gap_x, 0.6, vic.body_length * 0.25), 0.0)
			_bump_attacker.rotate_y(PI / 2.0) # cu botul spre -X, incotro merge
			_bump_attacker.velocity = Vector3(-BUMP_ENTRY_SPEED, 0, 0)
		"colt":
			# PIT: din spate, dar decalat lateral — contactul prinde coltul.
			var gap: float = (att.body_length + vic.body_length) * 0.5 + 4.0
			_bump_attacker = _spawn_bump_car(att,
				Vector3(vic.body_width * 0.45, 0.6, gap), 0.0)
			_bump_attacker.velocity = Vector3(0, 0, -BUMP_ENTRY_SPEED)
		_:
			var gap: float = (att.body_length + vic.body_length) * 0.5 + 4.0
			_bump_attacker = _spawn_bump_car(att, Vector3(0, 0.6, gap), 0.0)
			_bump_attacker.velocity = Vector3(0, 0, -BUMP_ENTRY_SPEED)
	_bump_victim_yaw0 = _bump_victim.rotation.y
	_bump_frames = 0
	_bump_peak = 0.0
	_bump_attacker_loss = 0.0
	_bump_attacker_floor = BUMP_ENTRY_SPEED
	_bump_impulses_att = 0
	_bump_impulses_vic = 0
	_bump_impulse_peak_att = 0.0
	_bump_impulse_peak_vic = 0.0


# ----------------------------------------------------- mod cliff (anti-blocaj)

## Peretii de canion sunt ~130 de forme convexe puse cap la cap, cu suprapunere
## de 1m. Suprapunerea exista tocmai ca sa nu ramana fisuri intre ele — dar
## "fara fisuri" e o afirmatie care trebuie verificata, nu presupusa: o masina
## intepenita intr-o imbinare inseamna cursa terminata pentru jucator.
##
## Testul: arunca masina in unghi in perete, la viteza, in mai multe puncte de pe
## traseu, si urmareste daca ramane oprita. Deliberat FARA repunere automata —
## plasa de siguranta din race.gd ar ascunde exact problema pe care o cautam.
func _start_cliff() -> void:
	GameState.selected_track = _track_index
	_cliff_track = (load(GameState.TRACK_SCENES[_track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(_cliff_track)
	var n := _cliff_track.baked.size()
	for frac in CLIFF_FRACS:
		var idx := int(frac * float(n)) % n
		# Ambele laturi: peretele interior si cel exterior au offseturi diferite,
		# deci si imbinari diferite.
		for side: float in [-1.0, 1.0]:
			_cliff_cases.append({"idx": idx, "side": side, "frac": frac})
	_next_cliff_case()


func _next_cliff_case() -> void:
	if _cliff_car != null:
		_cliff_car.queue_free()
		_cliff_car = null
	_cliff_case += 1
	if _cliff_case >= _cliff_cases.size():
		_report_cliff()
		return
	var c := _cliff_cases[_cliff_case]
	var idx: int = c["idx"]
	var side: float = c["side"]
	var n := _cliff_track.baked.size()
	var p: Vector3 = _cliff_track.baked[idx]
	var fwd: Vector3 = (_cliff_track.baked[(idx + 1) % n] - p).normalized()
	var lat := fwd.cross(Vector3.UP).normalized() * side

	# Pornim de pe banda dinspre perete, indreptati spre el sub CLIFF_ANGLE_DEG.
	var start := p + lat * (_cliff_track.half_width * 0.5) + Vector3.UP * 0.6
	var dir := fwd.rotated(Vector3.UP, deg_to_rad(CLIFF_ANGLE_DEG) * -side) \
		.normalized()

	_cliff_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_cliff_car)
	_cliff_car.apply_data(GameState.CAR_DATA[0] as CarData)
	# FARA linia asta sonda masoara cu totul altceva decat crede.
	#
	# Car._physics_process sare peste actualizarea lui road_index cand track e
	# null, deci indexul ramane 0 pe veci; AIController vireaza atunci spre
	# lookahead_point(0, ...), adica spre LINIA DE START, indiferent unde e
	# masina; iar supapa lui de scapare, car.respawn(), iese imediat pentru ca
	# respawn() cere track != null. Rezultatul: masuram "tine manevra de
	# marsarier a AI-ului peste 2 m/s", nu "te prinde geometria falezei".
	_cliff_car.track = _cliff_track
	_cliff_car.road_index = _cliff_track.closest_index_global(start)
	_cliff_car.last_safe_index = _cliff_car.road_index
	_cliff_car.global_position = start
	_cliff_car.look_at(start + dir, Vector3.UP)
	_cliff_car.race_active = true
	# Un AI adevarat la volan, nu comenzi fixe.
	#
	# Prima versiune folosea ScriptedController cu volanul drept: masina intra in
	# perete si impingea in el la infinit, deci iesea "intepenita" oriunde —
	# inclusiv pe forest, care n-are faleze, doar gardul rosu de dinainte (3 din
	# 12, apoi 9 din 12 cand am adaugat un viraj fix). Masura lipsa de reactie, nu
	# geometria.
	#
	# AIController stie sa dea marsarier si sa reia linia, adica exact ce ar face
	# un jucator. Daca NICI EL nu scapa, atunci chiar e o capcana de geometrie.
	var ai := AIController.new()
	_cliff_car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + _cliff_case
	ai.configure(_cliff_track, rng)
	_cliff_car.velocity = dir * CLIFF_ENTRY_SPEED
	_cliff_time = 0.0
	_cliff_slow_time = 0.0


func _tick_cliff(delta: float) -> void:
	if _cliff_car == null:
		return
	_cliff_time += delta
	var speed := Vector2(_cliff_car.velocity.x, _cliff_car.velocity.z).length()
	# Primele 0.4s sunt zborul pana la perete; nu conteaza pentru "intepenit".
	if _cliff_time > 0.4 and speed < CLIFF_STUCK_SPEED:
		_cliff_slow_time += delta
	else:
		_cliff_slow_time = 0.0
	if _cliff_time >= CLIFF_CASE_SECONDS \
			or _cliff_slow_time >= CLIFF_STUCK_SECONDS:
		var c := _cliff_cases[_cliff_case]
		_cliff_rows.append({
			"frac": c["frac"],
			"side": c["side"],
			"stuck": _cliff_slow_time >= CLIFF_STUCK_SECONDS,
			"exit_speed": speed,
			"stuck_time": _cliff_slow_time,
		})
		_next_cliff_case()


func _report_cliff() -> void:
	print("\n=== ANTI-BLOCAJ IN PERETII DE CANION (%s) ==="
		% GameState.TRACK_NAMES[_track_index])
	print("intrare %.0f m/s la %.0f°, intepenit = sub %.1f m/s mai mult de %.1fs"
		% [CLIFF_ENTRY_SPEED, CLIFF_ANGLE_DEG, CLIFF_STUCK_SPEED,
			CLIFF_STUCK_SECONDS])
	print("%8s %6s %12s %10s" % ["fractie", "parte", "viteza iesire", "stare"])
	print("-".repeat(40))
	var stuck := 0
	for row in _cliff_rows:
		if row["stuck"]:
			stuck += 1
		print("%8.2f %6s %9.1f m/s %10s" % [
			row["frac"], "st" if float(row["side"]) < 0.0 else "dr",
			row["exit_speed"], "INTEPENIT" if row["stuck"] else "ok"])
	print("\n%d cazuri, %d intepenite" % [_cliff_rows.size(), stuck])
	print("VERDICT: %s" % ("PROBLEMA" if stuck > 0 else "OK"))
	_done = true
	get_tree().quit(1 if stuck > 0 else 0)


func _spawn_bump_car(data: CarData, pos: Vector3, throttle: float) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	# Pozitia INAINTE de add_child: corpul intra in serverul de fizica direct
	# la locul lui. Setata dupa, exista un cadru in care ambele masini stau
	# suprapuse la origine — depenetrarea o arunca pe victima pe ACOPERISUL
	# atacatorului, unde platforma mobila o cara cu viteza proprie zero si
	# cazul masoara o plimbare, nu o izbitura (primul rand din matrice iesea
	# cu 0 impulsuri si victima "impinsa" 21 m).
	car.position = pos
	add_child(car)
	car.apply_data(data)
	car.race_active = true
	var ctrl := ScriptedController.new()
	ctrl.throttle = throttle
	car.set_controller(ctrl)
	car.bumped.connect(_on_bump_impulse)
	return car


## Numaram impulsurile REALE emise de Car._resolve_bump: daca dv-ul masurat e
## zero dar impulsurile curg, inseamna ca move_and_slide le anuleaza (masina e
## intrepatrunsa), nu ca modelul de imbranceala tace.
func _on_bump_impulse(car: Car, _other: Car, delta_v: float) -> void:
	if car == _bump_attacker:
		_bump_impulses_att += 1
		_bump_impulse_peak_att = maxf(_bump_impulse_peak_att, delta_v)
	else:
		_bump_impulses_vic += 1
		_bump_impulse_peak_vic = maxf(_bump_impulse_peak_vic, delta_v)


func _tick_bump() -> void:
	if _bump_attacker == null:
		return
	_bump_frames += 1
	if _bump_frames > 3: # dupa ce au coborat pe sol
		_bump_peak = maxf(_bump_peak, _bump_victim.horizontal_speed())
		_bump_attacker_loss = maxf(_bump_attacker_loss,
			BUMP_ENTRY_SPEED - _bump_attacker.horizontal_speed())
		# Podeaua de viteza abia DUPA ce izbitura a avut loc — inainte de
		# contact atacatorul merge cu viteza de intrare si cifra n-ar spune nimic.
		if _bump_impulses_att + _bump_impulses_vic > 0:
			_bump_attacker_floor = minf(_bump_attacker_floor,
				_bump_attacker.horizontal_speed())
	if _bump_frames < 90:
		return
	var c := _bump_cases[_bump_case]
	var att := c.attacker as CarData
	var vic := c.victim as CarData
	var kind := String(c.kind)
	# Distanta dintre centre la final vs. suma semi-gabaritelor pe directia
	# loviturii: sub 1.0 inseamna ca atacatorul a "inghitit" victima si o cara
	# in el, nu a imbrancit-o.
	var touching := (att.body_length + vic.body_length) * 0.5 \
		if kind != "lateral" else (att.body_length + vic.body_width) * 0.5
	var apart := _bump_attacker.global_position - _bump_victim.global_position
	apart.y = 0.0
	var pushed := _bump_victim.global_position
	pushed.y = 0.0
	_bump_rows.append({
		"attacker": att.display_name, "victim": vic.display_name,
		"kind": kind,
		"ratio": att.mass_factor / vic.mass_factor,
		"victim_dv": _bump_peak, "attacker_loss": _bump_attacker_loss,
		"attacker_floor": _bump_attacker_floor,
		"pushed": pushed.length(), "sep": apart.length() / touching,
		"yaw_deg": absf(rad_to_deg(wrapf(
			_bump_victim.rotation.y - _bump_victim_yaw0, -PI, PI))),
		"impulses": _bump_impulses_att + _bump_impulses_vic,
		"impulse_peak": maxf(_bump_impulse_peak_att, _bump_impulse_peak_vic),
	})
	_next_bump_case()


func _report_bump() -> void:
	print("\n=== IMBRANCELI (atac la %.0f m/s in masina oprita) ===" % [
		BUMP_ENTRY_SPEED])
	print("frana atac = varful de viteza pierduta; v_min atac = podeaua de dupa")
	print("contact (aproape de zero inseamna \"zid\", nu transfer de impuls)")
	print("%-12s %-12s %-7s %8s %11s %11s %10s %8s %7s %6s %8s %6s" % [
		"atacator", "victima", "tip", "m_a/m_v", "dv victima", "frana atac",
		"v_min atac", "impinsa", "separ", "rotita", "impuls", "dv_max"])
	for row in _bump_rows:
		print("%-12s %-12s %-7s %8.2f %10.1f %10.1f %10.1f %8.1f %7.2f %5.0f° %6d %8.1f" % [
			row.attacker, row.victim, row.kind, row.ratio,
			row.victim_dv, row.attacker_loss, row.attacker_floor,
			row.pushed, row.sep, row.yaw_deg,
			row.impulses, row.impulse_peak])
	_finish()
