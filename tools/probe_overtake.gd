extends Node
## Depaseste AI-ul rapid o masina lenta, sau sta lipit de bara ei?
##
## Reproduce exact scenariul reclamat: un autobuz lent pe axa soselei, o masina
## rapida in spate, pe ACEEASI linie. Inainte de ochii pentru trafic
## (AIController._avoid_line), urmaritorul ramanea proptit in bara autobuzului
## — aceeasi tinta laterala, masa dubla in fata, nicio iesire.
##
## Ruleaza CA SCENA (masinile au nevoie de autoload-uri):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeOvertake.tscn
##   ... -- --track=0 --no-avoid --scenarios=3
##
## `--no-avoid` e contra-proba A/B: acelasi scenariu cu traficul negat
## (lista goala), adica exact comportamentul vechi. Acolo doar raporteaza,
## fara prag de trecere.
##
## Trei scenarii pe fractii diferite de tur (drept sau viraj, cum pica pista),
## fiecare cu timeout. Fizica pe Jolt nu e determinista intre rulari
## (vezi memoria proberace-nedeterminism), de-aia pragul e "2 din 3", nu
## o cifra exacta.

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
## Fractiile de tur unde incepe fiecare scenariu.
const START_FRACS: Array[float] = [0.1, 0.4, 0.7]
## Autobuzul merge la 40% din viteza lui — clar mai lent, dar nu parcat:
## un obstacol static l-ar prinde plasa de anti-blocaj, nu depasirea.
const BUS_SPEED_SCALE: float = 0.4
## Cat de departe in spate porneste urmaritorul (m, pe traseu).
const START_GAP_M: float = 18.0
## Depasirea e reusita cand urmaritorul e cu atat INAINTEA autobuzului (m).
const PASSED_M: float = 6.0
const TIMEOUT_S: float = 25.0
## Sub distanta asta intre CENTRE numaram "bara la bara" (m). Autobuzul are
## 5.46 m, muscle car-ul 4.2: lipite fata-spate, centrele stau la ~4.8 m.
const CONTACT_M: float = 5.4

var _track_index: int = 0
var _avoid: bool = true
var _scenarios: int = START_FRACS.size()
var _failed: bool = false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
		elif arg == "--no-avoid":
			_avoid = false
		elif arg.begins_with("--scenarios="):
			_scenarios = int(arg.trim_prefix("--scenarios="))
	var track_scene := load(GameState.TRACK_SCENES[_track_index]) as PackedScene
	var track := track_scene.instantiate() as Track
	add_child(track)
	await get_tree().physics_frame

	print("")
	print("=== depasire pe %s (%s) ===" % [GameState.TRACK_NAMES[_track_index],
		"cu ochi pentru trafic" if _avoid else "FARA (contra-proba)"])
	print("scenariu  start_frac  depasit_in(s)  bara_la_bara(s)  rezultat")
	var passed := 0
	for i in _scenarios:
		var frac := START_FRACS[i % START_FRACS.size()]
		var out: Dictionary = await _run_scenario(track, frac, 20260823 + i)
		var ok: bool = out.pass_t >= 0.0
		if ok:
			passed += 1
		print("   %d       %.2f      %s        %6.1f         %s" % [i, frac,
			("%9.1f" % out.pass_t) if ok else "  timeout",
			out.contact_s, "trecut" if ok else "NEDEPASIT"])
	print("")
	if _avoid:
		_failed = passed < 2
		print("REZULTAT: %s (%d/%d depasiri; prag 2, timeout %.0f s)"
			% ["PICAT" if _failed else "TRECUT", passed, _scenarios, TIMEOUT_S])
	else:
		print("REZULTAT: informativ (%d/%d depasiri fara evitare)"
			% [passed, _scenarios])
	get_tree().quit(1 if _failed else 0)


## Un scenariu: autobuz lent pe axa la `frac`, muscle car la START_GAP_M in
## spate, tot pe axa. Intoarce {pass_t: s sau -1, contact_s: s}.
func _run_scenario(track: Track, frac: float, seed_v: int) -> Dictionary:
	var r := track.route_at(0)
	var n := r.count()
	var bus_idx := int(frac * float(n)) % n
	var back := int(START_GAP_M / maxf(track.curve.bake_interval, 0.001))
	var chase_idx := ((bus_idx - back) % n + n) % n

	var bus := _spawn(track, bus_idx, 3, seed_v) # bus.tres e indexul 3
	var chaser := _spawn(track, chase_idx, 0, seed_v + 7) # muscle = indexul 0
	bus.speed_scale = BUS_SPEED_SCALE
	chaser.speed_scale = 1.0
	# Amandoi pe axa: cazul reclamat, aceeasi linie. Fara zarul de
	# personalitate, scenariul chiar testeaza evitarea, nu norocul ofsetului.
	(bus.controller as AIController).line_offset = 0.0
	(chaser.controller as AIController).line_offset = 0.0
	(bus.controller as AIController).prefers_shortcut = false
	(chaser.controller as AIController).prefers_shortcut = false
	if _avoid:
		var traffic: Array[Car] = [bus, chaser]
		(chaser.controller as AIController).traffic = traffic

	# Autobuzul pleaca primul o secunda, sa fie deja in mers cand il prindem.
	bus.race_active = true
	bus.on_start_grid = false
	for _f in 60:
		await get_tree().physics_frame
	chaser.race_active = true
	chaser.on_start_grid = false

	var pass_t := -1.0
	var contact_s := 0.0
	var t := 0.0
	var dt := 1.0 / 60.0
	while t < TIMEOUT_S:
		await get_tree().physics_frame
		t += dt
		if bus.global_position.distance_to(chaser.global_position) < CONTACT_M:
			contact_s += dt
		var d := chaser.road_index - bus.road_index
		if d > n / 2:
			d -= n
		elif d < -n / 2:
			d += n
		if float(d) * track.curve.bake_interval > PASSED_M:
			pass_t = t
			break

	bus.queue_free()
	chaser.queue_free()
	await get_tree().physics_frame
	return {"pass_t": pass_t, "contact_s": contact_s}


func _spawn(track: Track, idx: int, data_index: int, seed_v: int) -> Car:
	var car := load(CAR_SCENE).instantiate() as Car
	car.track = track
	add_child(car)
	car.global_transform = track.route_at(0).recovery_transform(idx, 0.0)
	car.route = 0
	car.road_index = track.closest_index_global(car.global_position)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.apply_data(GameState.CAR_DATA[data_index] as CarData)
	var ai := AIController.new()
	car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	ai.configure(track, rng)
	car.race_active = false
	car.on_start_grid = true
	return car
