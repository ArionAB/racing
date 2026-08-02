class_name Race
extends Node3D
## Orchestreaza o cursa: mediu, pista (aleasa din GameState), masini
## (jucatorul cu masina din garaj + lineup AI stabil), countdown cu rocket
## start, progres/pozitii, rezultate si avansarea campionatului.

const CAR_SCENE: PackedScene = preload("res://scenes/cars/Car.tscn")
## Pilotii sunt stabili intre curse (punctele de campionat raman pe slot).
const PILOTS: Array[String] = ["Tu", "Robo", "Vex", "Luna"]
## Lineup-ul AI: masina (index in GameState.CAR_DATA) + culoarea per slot.
const AI_CARS: Array[int] = [3, 1, 4] # Autobuzul, Politia, Pompierii
const AI_COLORS: Array[Color] = [
	Color(0.3, 0.8, 0.4), Color(0.8, 0.4, 0.9), Color(0.55, 0.75, 0.95)]

enum State { COUNTDOWN, RUNNING, FINISHED }

var state: State = State.COUNTDOWN
var track: Track
var player: Car
var cars: Array[Car] = []
var camera: ChaseCamera
var hud: RaceHUD

var _progress: Array[Dictionary] = []
var _countdown_left: float = 3.6
var _last_beep: int = -1
var _skid_parent: Node3D
var _drift_hold: Dictionary = {}
var _lap_start_ms: int = -1
var _best_lap_ms: int = -1
var _final_order: Array = [] # sloturi in ordinea sosirii
var _champion_shown: bool = false
## Cat sta fiecare masina impotmolita in afara soselei (secunde).
var _stalled: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	# Mediul (cer, soare, teren) e construit de pista — fiecare are tema ei.
	var track_scene := load(
		GameState.TRACK_SCENES[GameState.selected_track]) as PackedScene
	track = track_scene.instantiate() as Track
	add_child(track)
	_skid_parent = Node3D.new()
	_skid_parent.name = "SkidMarks"
	add_child(_skid_parent)
	_spawn_cars()
	camera = ChaseCamera.new()
	add_child(camera)
	camera.target = player
	_fit_camera_to_player()
	camera.snap_behind()
	hud = RaceHUD.new()
	add_child(hud)
	hud.restart_requested.connect(GameState.start_race)
	hud.menu_requested.connect(GameState.go_to_menu)
	hud.results_primary.connect(_on_results_primary)
	hud.setup_minimap(track, cars)
	hud.show_countdown("READY?")
	player.wall_hit.connect(func(_c: Car, impact: float) -> void:
		camera.add_trauma(clampf(impact / 45.0, 0.15, 0.5)))
	player.landed.connect(func(_c: Car, fall: float) -> void:
		camera.add_trauma(clampf(fall / 30.0, 0.1, 0.35)))
	player.boost_started.connect(func(_c: Car) -> void:
		camera.add_trauma(0.18))
	# Imbranceala se SIMTE proportional cu cat ai incasat: un autobuz care te ia
	# din spate zguduie ecranul, o atingere lateral aproape deloc.
	player.bumped.connect(func(_c: Car, _other: Car, delta_v: float) -> void:
		camera.add_trauma(clampf(delta_v / 40.0, 0.05, 0.35)))
	# Repunerea teleporteaza masina: camera trebuie sa sara cu ea, altfel
	# urmareste cateva cadre un punct de la 100m.
	player.respawned.connect(func(_c: Car) -> void:
		camera.snap_behind()
		camera.add_trauma(0.22)
		hud.flash_message("RATAT — repus pe pista"))

func _spawn_cars() -> void:
	var count := GameState.ai_count + 1
	var spawns := track.spawn_transforms(count)
	for i in count:
		var car := CAR_SCENE.instantiate() as Car
		car.track = track
		add_child(car)
		car.global_transform = spawns[i]
		car.road_index = track.closest_index_global(car.global_position)
		car.last_safe_index = car.road_index
		car.skid_parent = _skid_parent
		car.pilot_name = PILOTS[i % PILOTS.size()]
		if i == 0:
			player = car
			car.is_player = true
			car.apply_data(GameState.CAR_DATA[GameState.selected_car] as CarData)
			car.set_controller(PlayerController.new())
		else:
			var data_idx: int = AI_CARS[(i - 1) % AI_CARS.size()]
			car.apply_data(GameState.CAR_DATA[data_idx] as CarData,
				AI_COLORS[(i - 1) % AI_COLORS.size()])
			var ai := AIController.new()
			car.set_controller(ai)
			ai.configure(track, _rng)
			car.speed_scale = _rng.randf_range(0.88, 0.97)
		cars.append(car)
		var frac := track.frac_at(car.road_index)
		_progress.append({
			"frac": frac,
			"total": frac - 1.0 if frac > 0.5 else frac,
			"laps": 0,
		})

func _physics_process(delta: float) -> void:
	if state == State.COUNTDOWN:
		_tick_countdown(delta)
	else:
		_tick_race(delta)
	_update_hud()

# -------------------------------------------------------------- countdown

func _tick_countdown(delta: float) -> void:
	_countdown_left -= delta
	# Rocket start: masuram cat tine fiecare "creier" TURBO apasat.
	for car in cars:
		if car.controller != null and car.controller.is_turbo_pressed():
			_drift_hold[car] = float(_drift_hold.get(car, 0.0)) + delta
		else:
			_drift_hold[car] = 0.0
	if _countdown_left > 3.0:
		return
	if _countdown_left > 0.0:
		var number := ceili(_countdown_left)
		hud.show_countdown(str(number))
		if number != _last_beep:
			_last_beep = number
			AudioManager.play_sfx(&"count_beep")
		return
	_go()

func _go() -> void:
	state = State.RUNNING
	hud.show_countdown("GO!")
	AudioManager.play_sfx(&"go_beep")
	get_tree().create_timer(0.7, false).timeout.connect(
		func() -> void: hud.show_countdown(""))
	_lap_start_ms = Time.get_ticks_msec()
	for car in cars:
		car.race_active = true
		var hold := float(_drift_hold.get(car, 0.0))
		if car == player:
			if hold > 0.05 and hold <= 1.05:
				car.force_boost(1.2)
				hud.flash_message("ROCKET START!")
			elif hold > 1.05:
				hud.flash_message("Prea devreme...")
		elif _rng.randf() < 0.45:
			car.force_boost(0.8)

# ------------------------------------------------------------------ cursa

func _tick_race(delta: float) -> void:
	for i in cars.size():
		var car := cars[i]
		_watch_recovery(car, delta)
		var st := _progress[i]
		var frac := track.frac_at(car.road_index)
		var d := frac - float(st.frac)
		if d < -0.5:
			d += 1.0
		elif d > 0.5:
			d -= 1.0
		st.frac = frac
		if not car.finished:
			st.total = float(st.total) + d
		var laps := int(floor(float(st.total)))
		if laps > int(st.laps):
			st.laps = laps
			if car == player:
				_on_player_lap(laps)
			if laps >= GameState.total_laps and not car.finished:
				car.finished = true
	_update_positions()

## Plasa de siguranta a cursei: nimeni nu ramane blocat. Zonele de fly-off au
## RespawnZone-ul lor, dar mai exista doua feluri de a te pierde — sa cazi din
## lume si sa te impotmolesti in nisip fara sa mai poti iesi. Amandoua se
## termina cu repunerea pe ultimul checkpoint valid.
func _watch_recovery(car: Car, delta: float) -> void:
	if car.finished:
		return
	if car.global_position.y < -12.0:
		car.respawn()
		return
	var off_road := not track.is_on_road(car.road_index, car.global_position)
	if off_road and car.horizontal_speed() < 2.5:
		_stalled[car] = float(_stalled.get(car, 0.0)) + delta
		if float(_stalled[car]) > 5.0:
			_stalled[car] = 0.0
			car.respawn()
	else:
		_stalled[car] = 0.0

func _on_player_lap(laps: int) -> void:
	var now := Time.get_ticks_msec()
	if _lap_start_ms >= 0:
		var lap_ms := now - _lap_start_ms
		if _best_lap_ms < 0 or lap_ms < _best_lap_ms:
			_best_lap_ms = lap_ms
		if GameState.try_record(GameState.selected_track, lap_ms):
			hud.flash_message("RECORD NOU! " + _fmt_ms(lap_ms))
			AudioManager.play_sfx(&"drift_level", 1.5)
	_lap_start_ms = now
	if laps >= GameState.total_laps and state != State.FINISHED:
		_finish_race()

func _finish_race() -> void:
	state = State.FINISHED
	_update_positions()
	# Ordinea finala = pozitiile din clipa sosirii jucatorului (AI-ul din
	# spate isi pastreaza locul relativ; cursa e a jucatorului).
	var order := range(cars.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		return cars[a].race_position < cars[b].race_position)
	_final_order = order
	if GameState.champ_active:
		GameState.record_results(_final_order)
	hud.flash_message("FINISH — locul %d!" % player.race_position)
	get_tree().create_timer(1.5, false).timeout.connect(_show_results)

func _show_results() -> void:
	var rows: Array[Dictionary] = []
	for rank in _final_order.size():
		var slot: int = _final_order[rank]
		var car := cars[slot]
		var right := ""
		if GameState.champ_active:
			right = "+%d p  (total %d)" % [
				GameState.CHAMP_POINTS[rank], GameState.champ_points[slot]]
		rows.append({
			"name": "%d. %s (%s)" % [rank + 1, car.pilot_name, car.car_name],
			"color": car.body_color,
			"right": right,
			"is_player": car.is_player,
		})
	var title := "REZULTATE — " + track.track_name
	var primary := "RESTART"
	if GameState.champ_active:
		title = "CURSA %d/%d — %s" % [GameState.champ_round + 1,
			GameState.CHAMP_ROUNDS, track.track_name]
		primary = "CLASAMENT FINAL" if GameState.champ_is_last_round() \
			else "URMATOAREA CURSA"
	hud.show_results(title, rows, primary)

func _on_results_primary() -> void:
	if not GameState.champ_active:
		GameState.start_race()
		return
	if _champion_shown:
		GameState.start_championship()
		return
	if GameState.champ_is_last_round():
		_show_champion()
	else:
		GameState.champ_next_race()

## Clasamentul final al campionatului, sortat dupa puncte.
func _show_champion() -> void:
	_champion_shown = true
	var slots := range(cars.size())
	slots.sort_custom(func(a: int, b: int) -> bool:
		return GameState.champ_points[a] > GameState.champ_points[b])
	var rows: Array[Dictionary] = []
	for rank in slots.size():
		var slot: int = slots[rank]
		var car := cars[slot]
		rows.append({
			"name": "%d. %s (%s)" % [rank + 1, car.pilot_name, car.car_name],
			"color": car.body_color,
			"right": "%d puncte" % GameState.champ_points[slot],
			"is_player": car.is_player,
		})
	var champion := cars[slots[0]]
	var title := "CAMPION: %s!" % champion.pilot_name
	AudioManager.play_sfx(&"go_beep", 1.3)
	hud.show_results(title, rows, "CAMPIONAT NOU")

# -------------------------------------------------------------------- HUD

func _update_positions() -> void:
	var order := range(cars.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		return float(_progress[a].total) > float(_progress[b].total))
	for rank in cars.size():
		cars[order[rank]].race_position = rank + 1

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1: _swap_player_car(0)
		KEY_2: _swap_player_car(1)
		KEY_3: _swap_player_car(2)
		KEY_4: _swap_player_car(3)
		KEY_5: _swap_player_car(4)

func _swap_player_car(index: int) -> void:
	player.apply_data(GameState.CAR_DATA[index] as CarData)
	_fit_camera_to_player()

## Camera se retrage proportional cu lungimea vehiculului (autobuzul ar
## umple ecranul la distanta potrivita pentru muscle car).
##
## Coeficientii au coborat odata cu trecerea la unghiul Ignition: pentru Muscle
## dau acum 6.8m / 2.55m in loc de 8.5m / 3.5m, adica ~7° in jos in loc de ~11°.
## Panta pe body_length a scazut si ea (0.70 -> 0.52), altfel autobuzul ar fi
## ramas cu unghiul vechi in timp ce masinile mici capatau unul nou.
func _fit_camera_to_player() -> void:
	if player.data != null:
		camera.distance = 4.2 + player.data.body_length * 0.52
		camera.height = 1.70 + player.data.body_length * 0.17

func _update_hud() -> void:
	var lap_text := "--:--.-"
	if _lap_start_ms >= 0 and state != State.COUNTDOWN:
		lap_text = _fmt_ms(Time.get_ticks_msec() - _lap_start_ms)
	var best_text := _fmt_ms(_best_lap_ms) if _best_lap_ms >= 0 else "--:--.-"
	var lap_no := clampi(int(_progress[0].laps) + 1, 1, GameState.total_laps)
	var champ_line := ""
	if GameState.champ_active:
		champ_line = "   cursa %d/%d" % [
			GameState.champ_round + 1, GameState.CHAMP_ROUNDS]
	var record_ms := GameState.best_lap(GameState.selected_track)
	var record_text := _fmt_ms(record_ms) if record_ms > 0 else "--:--.-"
	var info := "%3.0f km/h   loc %d/%d   tur %d/%d%s\ntur:  %s\nbest: %s   rec: %s\n%s pe %s   [SPACE] turbo  [SHIFT] drift" % [
		player.horizontal_speed() * 3.6, player.race_position, cars.size(),
		lap_no, GameState.total_laps, champ_line, lap_text, best_text,
		record_text, player.car_name, track.track_name]
	hud.set_info(info)
	hud.set_turbo(player.turbo_charge, player.is_boosting)

func _fmt_ms(ms: int) -> String:
	@warning_ignore("integer_division")
	return "%d:%02d.%d" % [ms / 60000, (ms % 60000) / 1000, (ms % 1000) / 100]

