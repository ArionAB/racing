extends Node
## Sonda de CAMERA: aceeasi bucata de cursa, fotografiata cu setari diferite de
## camera, ca sa se poata alege intre ele uitandu-te, nu discutand.
##
## De ce nu ajunge Snapshot.tscn --gamecam: acolo camera e pusa pe traseu de
## mana, fara masina si fara miscare. Or intrebarea la o camera e exact "cat de
## mare e masina in cadru si cat vezi din pista in fata ei", deci poza trebuie
## sa aiba masina in ea, la viteza, in aceleasi puncte de fiecare data.
##
## Masina e condusa de AI (deterministic la --fixed-fps), deci acelasi cadru
## inseamna aceeasi pozitie pe pista in toate rulările: diferenta dintre doua
## poze cu acelasi index e NUMAI camera.
##
##   godot --rendering-driver vulkan --path . res://tools/ProbeCam.tscn -- \
##       --preset=inalta [--track=0] [--car=0]
##
## Presetarile traiesc AICI, nu in chase_camera.gd: sunt material de tuning, iar
## jocul are voie sa stie doar de cea castigatoare. Cand una castiga, valorile ei
## se scriu in ChaseCamera si presetarea ramane in tabel ca istoric al alegerii.

const RACE_SCENE: String = "res://scenes/race/Race.tscn"

## Cadrele la care se fotografiaza. Alese pe traseul Dunelor: dreapta lunga cu
## viteza maxima, intrarea in viraj, apoi un al treilea punct dupa creasta.
const SHOTS: Array[int] = [260, 420, 620, 900, 1150, 1400, 1440, 1480]

## Presetari de camera. `nume: {parametru: valoare}` — cheile sunt proprietati
## ale lui ChaseCamera, deci o presetare gresita crapa zgomotos, nu tacut.
const PRESETS: Dictionary = {
	# Camera din joc, ca etalon. Valorile vin din ChaseCamera, nu duplicate aici.
	"actuala": {},
	# Mai sus si mai in spate, cu FOV mai stramt: teleobiectivul e ce face lumea
	# sa arate a macheta. Unghiul urca la ~27°.
	"macheta": {
		"distance": 11.0, "height": 7.6, "base_fov": 60.0,
		"look_ahead": 4.0, "look_height": 0.40,
	},
	# Varianta "de sus", aproape de vederea izometrica a lui Ignition: masina
	# mica, se vede tot virajul urmator.
	"inalta": {
		"distance": 13.0, "height": 10.6, "base_fov": 52.0,
		"look_ahead": 5.0, "look_height": 0.40,
	},
	# Aceeasi inaltime ca "inalta", dar cu FOV-ul larg pastrat. Teleobiectivul
	# aplatizeaza si linisteste imaginea — exact senzatia de viteza pe care o
	# vrem. Aici testam daca putem avea si vederea de sus, si viteza.
	"inalta_larga": {
		"distance": 12.5, "height": 10.0, "base_fov": 68.0,
		"look_ahead": 5.0, "look_height": 0.40,
	},
	# Candidatul final: geometria lui "inalta_larga" plus rotatia lenesa. Camera
	# de sus rezolva ce se VEDE; lenea rezolva cum se MISCA — o camera care se
	# aseaza instant in spatele masinii citeste ca simulator, una care ramane in
	# urma iti arata masina din trei sferturi in viraj.
	"ignition": {
		"distance": 12.5, "height": 10.0, "base_fov": 68.0,
		"look_ahead": 5.0, "look_height": 0.40,
		"follow_speed": 3.6, "aim_smooth": 5.0, "aim_vel_weight": 0.40,
		"anchor_vel_weight": 0.12, "roll_max_deg": 1.2,
		"speed_pullback": 0.10, "fov_speed_kick": 8.0,
	},
	# Ca "macheta", dar cu camera LENESA: se roteste incet dupa masina, deci in
	# viraj o vezi din trei sferturi in loc de mereu din spate. Asta e jumatatea
	# de caracter pe care distanta singura n-o da.
	"lenesa": {
		"distance": 11.0, "height": 7.6, "base_fov": 60.0,
		"look_ahead": 4.0, "look_height": 0.40,
		"follow_speed": 3.0, "aim_smooth": 4.0, "aim_vel_weight": 0.35,
		"anchor_vel_weight": 0.10, "roll_max_deg": 0.0,
		"speed_pullback": 0.10, "fov_speed_kick": 5.0,
	},
}


var _race: Node = null
var _frames: int = 0
var _preset: String = "actuala"
var _shots: Array[String] = []


func _ready() -> void:
	var track_index := 0
	var car_index := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			_preset = arg.trim_prefix("--preset=")
		elif arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--car="):
			car_index = int(arg.trim_prefix("--car="))
	if not PRESETS.has(_preset):
		push_error("probe_cam: presetare necunoscuta '%s' (am: %s)"
			% [_preset, ", ".join(PRESETS.keys())])
		get_tree().quit(1)
		return
	# Aceleasi alegeri fixate ca la ProbeRace: masina si pista se dau din linia
	# de comanda, nu din user://settings.cfg, altfel doua rulari ale aceluiasi
	# cod compara camere pe masini diferite.
	GameState.selected_track = track_index
	GameState.selected_car = car_index
	GameState.champ_active = false
	GameState.total_laps = 99
	# Fara adversari: `race.gd` isi randomizeaza propriul RNG in _ready (viteza
	# fiecarui AI), iar o imbranceala la start ar muta masina intre presetari.
	# Intrebarea de aici e incadrarea, si aia n-are nevoie de pluton.
	GameState.ai_count = 0
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames == 3:
		_apply_preset()
		# AI la volan: e singurul pilot determinist din proiect si tine linia,
		# deci pozele ies din aceleasi puncte la fiecare presetare.
		var car := _race.player as Car
		var old: CarController = car.controller
		car.remove_child(old)
		old.free()
		var ai := AIController.new()
		car.set_controller(ai)
		# Samanta FIXA, altfel comparatia minte. Prima rulare a probei a scos
		# masina la 86 km/h intr-o presetare si 133 in alta, la acelasi cadru:
		# `RandomNumberGenerator.new()` se auto-randomizeaza, deci AI-ul alegea
		# alta linie si alta franare de fiecare data, iar diferenta dintre poze
		# nu mai era camera.
		var rng := RandomNumberGenerator.new()
		rng.seed = 20260804
		ai.configure(_race.track as Track, rng)
		car.race_active = true
		return
	if _frames in SHOTS:
		# Pista intra in nume: fara ea, o rulare pe alta pista suprascrie tacut
		# pozele precedente si compari fara sa stii doua trasee diferite.
		_shot("cam_%s_%s_%d" % [_preset,
			GameState.TRACK_NAMES[GameState.selected_track].to_lower(),
			SHOTS.find(_frames) + 1])
	if _frames > SHOTS[SHOTS.size() - 1]:
		print("=== ProbeCam '%s': capturi salvate ===" % _preset)
		for s in _shots:
			print("  ", s)
		get_tree().quit(0)


func _apply_preset() -> void:
	var cam := _race.camera as ChaseCamera
	var values: Dictionary = PRESETS[_preset]
	for key: String in values:
		assert(key in cam, "probe_cam: ChaseCamera n-are proprietatea '%s'" % key)
		cam.set(key, values[key])
	cam.snap_behind()
	print("camera '%s': distanta %.2f  inaltime %.2f  fov %.1f  unghi %.1f°"
		% [_preset, cam.distance, cam.height, cam.base_fov, cam.pitch_degrees()])


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "res://snapshots/%s.png" % shot_name
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://snapshots"))
	img.save_png(ProjectSettings.globalize_path(path))
	_shots.append(path)
