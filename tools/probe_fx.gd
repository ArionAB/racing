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
	# Implicit Dunele (asfalt), ca inainte. --track=1 duce sonda pe Okinawa
	# manual, singura pista cu drum de pamant: acolo praful si urmele apar si
	# PE sosea, nu doar in afara ei, si nu exista alt fel de a le vedea.
	GameState.selected_track = 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			GameState.selected_track = clampi(
				int(arg.trim_prefix("--track=")), 0,
				GameState.TRACK_SCENES.size() - 1)
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
	if _frames < 300:
		_ctrl.steer_cmd = 0.0
		_ctrl.drift_cmd = false
		# Privire in urma DE PE SOSEA, la viteza, inainte de orice drift: singurul
		# cadru in care se vede ce lasa masina pe drumul insusi. Aici, si nu dupa
		# drift, pentru ca pe Okinawa un drift tinut 170 de cadre scoate masina
		# de pe dig in mare — sonda a fost scrisa pentru Dunele.
		if _frames == 270:
			_look_back()
		if _frames == 280:
			_shot("fx_urme_sosea")
			# Numaratoarea AICI e controlul: pana in acest punct masinile au
			# mers doar pe sosea. Pe asfalt trebuie sa fie zero.
			_report_trails("dupa 4.5 s numai pe sosea")
		if _frames == 285:
			_restore_cam()
	# Faza 2: drift sustinut pe asfalt — fum + urme de cauciuc.
	elif _frames < 470:
		_ctrl.steer_cmd = 0.8
		_ctrl.drift_cmd = true
		if _frames == 440:
			_shot("fx_drift")
	# Faza 3: aruncam masina pe nisip, cu viteza — praf.
	elif _frames < 640:
		_ctrl.steer_cmd = 0.0
		_ctrl.drift_cmd = false
		if _frames == 470:
			var track := _race.track as Track
			var idx: int = _car.road_index
			var p: Vector3 = track.baked[idx]
			var dir := -_car.global_basis.z
			var out := dir.cross(Vector3.UP).normalized()
			_car.global_position = p + out * (track.half_width + 8.0) \
				+ Vector3.UP * 0.5
			_car.velocity = dir * 24.0
		# Tinem viteza pe nisip fara sa atingem Y, ca la ProbeLife.
		if _frames > 475 and _frames < 610:
			var fwd := -_car.global_basis.z
			_car.velocity.x = fwd.x * 22.0
			_car.velocity.z = fwd.z * 22.0
		if _frames == 600:
			_shot("fx_praf")
	# Faza 4: privim INAPOI, de sus, la solul peste care tocmai am trecut.
	#
	# Camera de joc sta in spatele masinii si se uita inainte, deci nu vede
	# NICIODATA ce lasa masina in urma. Fara captura asta, urmele de rulare pot
	# lipsi cu totul si sonda tot ar spune "OK".
	elif _frames < 660:
		if _frames == 645:
			_look_back()
		if _frames == 655:
			_shot("fx_urme")
	else:
		print("=== ProbeFx: capturi salvate ===")
		for s in _shots:
			print("  ", s)
		_report_trails("la final, dupa trecerea prin nisip")
		get_tree().quit(0)


## Cate urme de rulare s-au depus efectiv, per masina.
##
## O captura poate rata urmele din o suta de motive (cadru, unghi, lumina).
## Numaratoarea nu poate: ori sunt instante scrise in inelul din SandTrail, ori
## masina n-a lasat nimic. Pe o pista cu asfalt cifra TREBUIE sa fie zero pana
## cand cineva iese de pe drum — asa se vede si ca nu s-au pornit din greseala
## peste tot.
func _report_trails(eticheta: String) -> void:
	print("=== urme de rulare — %s ===" % eticheta)
	for car: Car in (_race.get("cars") as Array):
		var trail: SandTrail = null
		for child in car.get_children():
			if child is SandTrail:
				trail = child
		if trail == null:
			print("  %s: fara dara" % car.name)
			continue
		var used := 0
		var mm := trail.multimesh
		for i in mm.instance_count:
			if mm.get_instance_transform(i).basis.determinant() != 0.0:
				used += 1
		print("  %s: %d / %d  praf=%s" % [car.name, used, mm.instance_count,
			"da" if _dust_on(car) else "nu"])


## Ridica masina praf chiar ACUM? Perechea numarata a urmelor: pe drum de pamant
## amandoua trebuie sa fie pornite in acelasi timp, altfel dara apare din senin.
func _dust_on(car: Car) -> bool:
	var dust := car.get_node_or_null("Dust") as CPUParticles3D
	return dust != null and dust.emitting


## Camera proprie, la 12 m in spatele masinii si 9 m deasupra, uitandu-se in
## urma ei. Nu misca masina si nu opreste cursa — doar ia locul camerei de joc.
var _back_cam: Camera3D = null

func _look_back() -> void:
	if _back_cam == null:
		_back_cam = Camera3D.new()
		add_child(_back_cam)
		_back_cam.fov = 70.0
	var back := _car.global_basis.z # +Z e spatele masinii
	_back_cam.global_position = _car.global_position + back * 12.0 \
		+ Vector3.UP * 9.0
	_back_cam.look_at(_car.global_position + back * 26.0, Vector3.UP)
	_back_cam.make_current()


## Inapoi pe camera de joc, ca fazele urmatoare sa arate ce aratau si inainte.
func _restore_cam() -> void:
	var cam := _race.get("camera") as Camera3D
	if cam != null:
		cam.make_current()


func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var path := "res://snapshots/%s.png" % name
	img.save_png(ProjectSettings.globalize_path(path))
	_shots.append(path)
