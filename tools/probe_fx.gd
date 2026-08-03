extends Node
## Sonda VIZUALA pentru efectele de gameplay: fum de drift, urme de cauciuc,
## praf de off-road. Ruleaza cursa reala (camera de joc, masina jucatorului) si
## salveaza capturi de ecran in snapshots/.
##
## De ce exista: ProbeLife verifica doar `emitting == true` — adica emitatorul
## PORNESTE. Nu spune nimic despre daca particula se si VEDE de la camera de
## joc: marime, culoare pe fundalul respectiv, alpha. Exact golul prin care
## "praful merge" si jucatorul nu vede nimic.
##
##   godot --rendering-driver vulkan --path . res://tools/ProbeFx.tscn

const RACE_SCENE: String = "res://scenes/race/Race.tscn"

## Comenzi fixe: plina viteza, virare, drift tinut apasat.
class DriftController extends CarController:
	var steer_cmd: float = 0.0
	var drift_cmd: bool = false

	func get_throttle() -> float:
		return 1.0

	func get_steer() -> float:
		return steer_cmd

	func is_drift_pressed() -> bool:
		return drift_cmd


var _race: Node = null
var _frames: int = 0
var _car: Car = null
var _ctrl: DriftController = null
var _shots: Array[String] = []


func _ready() -> void:
	GameState.selected_track = 0
	GameState.selected_car = 0
	GameState.champ_active = false
	GameState.total_laps = 99
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames == 5:
		_car = _race.player as Car
		_ctrl = DriftController.new()
		var old: CarController = _car.controller
		_car.remove_child(old)
		old.free()
		_car.set_controller(_ctrl)
		_car.race_active = true
		return
	if _car == null:
		return
	# Faza 1: acceleram in linie dreapta pana la viteza de drift.
	if _frames < 160:
		_ctrl.steer_cmd = 0.0
		_ctrl.drift_cmd = false
	# Faza 2: drift sustinut pe asfalt — fum + urme de cauciuc.
	elif _frames < 320:
		_ctrl.steer_cmd = 0.8
		_ctrl.drift_cmd = true
		if _frames == 300:
			_shot("fx_drift")
	# Faza 3: aruncam masina pe nisip, cu viteza — praf.
	elif _frames < 500:
		_ctrl.steer_cmd = 0.0
		_ctrl.drift_cmd = false
		if _frames == 330:
			var track := _race.track as Track
			var idx: int = _car.road_index
			var p: Vector3 = track.baked[idx]
			var dir := -_car.global_basis.z
			var out := dir.cross(Vector3.UP).normalized()
			_car.global_position = p + out * (track.half_width + 8.0) \
				+ Vector3.UP * 0.5
			_car.velocity = dir * 24.0
		# Tinem viteza pe nisip fara sa atingem Y, ca la ProbeLife.
		if _frames > 335 and _frames < 470:
			var fwd := -_car.global_basis.z
			_car.velocity.x = fwd.x * 22.0
			_car.velocity.z = fwd.z * 22.0
		if _frames == 460:
			_shot("fx_praf")
	else:
		print("=== ProbeFx: capturi salvate ===")
		for s in _shots:
			print("  ", s)
		get_tree().quit(0)


func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var path := "res://snapshots/%s.png" % name
	img.save_png(ProjectSettings.globalize_path(path))
	_shots.append(path)
