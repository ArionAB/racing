extends Node
## Cat se deplaseaza masinile pe grila de start CAT TIMP curge countdown-ul.
##
## Intrebarea la care raspunde: "masinile stau pe loc la start" e o intentie sau
## un fapt? Raportul din joc era ca uneori pleaca singure inainte de GO. Cauza nu
## era input-ul (comenzile sunt blocate de `race_active`), ci gravitatia: se
## aplica oricum, iar move_and_slide o proiecteaza pe planul podelei, deci pe
## asfalt inclinat devine viteza orizontala in josul pantei. Nimic n-o frana —
## frecare statica nu modelam, iar drag-ul e proportional cu viteza.
##
## Ruleaza CA SCENA: masinile au nevoie de autoload-urile GameState/AudioManager.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeStartGrid.tscn
##   ... -- --track=2 --seconds=3.6
##
## Pentru fiecare slot de pe grila tipareste deplasarea totala fata de pozitia de
## spawn si viteza la finalul countdown-ului. Pragul de trecere e sub un
## centimetru: o masina care sta chiar sta.

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
## Cat tine countdown-ul in race.gd. Sonda nu instantiaza Race (aia porneste
## camera, HUD, audio), ci reproduce doar starea relevanta: masini spawnate pe
## grila, cu `race_active` fals, lasate sa ruleze fizica.
const COUNTDOWN_SECONDS: float = 3.6
## Sub atat consideram ca masina a stat pe loc (m). Un centimetru pe 3.6 s e
## zgomot numeric, nu alunecare.
const PASS_DRIFT_M: float = 0.01

var _track_index: int = -1 # -1 = toate pistele
var _seconds: float = COUNTDOWN_SECONDS
var _failed: bool = false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
	var tracks: Array[int] = []
	if _track_index >= 0:
		tracks.append(_track_index)
	else:
		for i in GameState.TRACK_SCENES.size():
			tracks.append(i)
	for idx in tracks:
		await _probe_track(idx)
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT",
		" (prag %.3f m pe %.1f s de countdown)" % [PASS_DRIFT_M, _seconds])
	get_tree().quit(1 if _failed else 0)


func _probe_track(index: int) -> void:
	var track_scene := load(GameState.TRACK_SCENES[index]) as PackedScene
	var track := track_scene.instantiate() as Track
	add_child(track)
	# O pista se construieste in _ready; asteptam un cadru ca geometria si
	# coliziunile ei sa existe inainte de a pune masini peste.
	await get_tree().physics_frame

	var count := GameState.ai_count + 1
	var spawns := track.spawn_transforms(count)
	var cars: Array[Car] = []
	var start_pos: Array[Vector3] = []
	for i in count:
		var car := load(CAR_SCENE).instantiate() as Car
		car.track = track
		add_child(car)
		car.global_transform = spawns[i]
		car.route = 0
		car.road_index = track.closest_index_global(car.global_position)
		car.apply_data(GameState.CAR_DATA[GameState.selected_car] as CarData)
		# AI la volan, ca sonda sariturii: fara controller masina n-are throttle,
		# deci ar sta pe loc si dupa GO — iar contra-proba de mai jos ar acuza
		# inghetul pentru o masina care de fapt n-are cine s-o conduca.
		var ai := AIController.new()
		car.set_controller(ai)
		var rng := RandomNumberGenerator.new()
		rng.seed = 20260813 + i
		ai.configure(track, rng)
		# Exact ca in cursa reala: pana la GO, masina e pe grila si inghetata.
		car.race_active = false
		car.on_start_grid = true
		cars.append(car)
		start_pos.append(car.global_position)

	var frames := int(_seconds * 60.0)
	for _f in frames:
		await get_tree().physics_frame

	print("")
	print("=== ", GameState.TRACK_NAMES[index], " (", count, " masini) ===")
	print("slot  deplasare(m)  orizontal(m)  viteza_finala(m/s)  pe_asfalt")
	for i in cars.size():
		var moved := cars[i].global_position - start_pos[i]
		var flat := Vector3(moved.x, 0.0, moved.z).length()
		var speed := cars[i].horizontal_speed()
		# Grila creste in spate cu fiecare rand (8 m per rand), deci o grila mai
		# mare poate impinge ultimul rand pe iarba sau intr-un viraj. Verificam,
		# nu presupunem.
		var on_road := track.is_on_road(
			cars[i].road_index, cars[i].global_position, cars[i].route)
		var mark := "" if flat <= PASS_DRIFT_M else "   <-- ALUNECA"
		if flat > PASS_DRIFT_M:
			_failed = true
		if not on_road:
			mark += "   <-- IN AFARA SOSELEI"
			_failed = true
		print("  %d   %8.3f      %8.3f      %8.3f        %s%s"
			% [i, moved.length(), flat, speed, "da" if on_road else "NU", mark])

	# Contra-proba: dezghetul chiar dezgheata. Fara ea, o masina blocata pe veci
	# ar trece testul de mai sus cu note maxime — remediu mai rau decat boala.
	var after: Array[Vector3] = []
	for car in cars:
		after.append(car.global_position)
		car.race_active = true
		car.on_start_grid = false
	for _f in int(1.5 * 60.0):
		await get_tree().physics_frame
	var launched := 0
	for i in cars.size():
		var gone := cars[i].global_position.distance_to(after[i])
		if gone > 1.0:
			launched += 1
	print("dupa GO: %d/%d masini au pornit (1.5 s)" % [launched, cars.size()])
	if launched < cars.size():
		_failed = true

	for car in cars:
		car.queue_free()
	track.queue_free()
	await get_tree().physics_frame
