extends Node
## Sonda VIZUALA pentru intrarea in apa: stropul, inelul si spray-ul de la roti.
##
## Ruleaza cursa reala pe o pista cu apa, ia masina jucatorului, o aseaza cu
## viteza pe sosea inainte de un canal cu apa (vad, parau) si salveaza capturi
## din camera de joc in jurul intrarii. Tipareste si tranzitia `in_water` si
## starea emitatoarelor, ca lectia din ProbeFx sa nu se repete: „emite" si „se
## vede" sunt intrebari diferite, iar sonda raspunde la amandoua.
##
##   godot --rendering-driver vulkan --path . res://tools/ProbeSplash.tscn -- --track=14
##
## `--track=` accepta si pozitia din lista, si numarul scenei (resolve_track_index).
## `--channel=<label>` alege canalul (implicit primul cu apa proprie);
## `--speed=` viteza de intrare (implicit 22 m/s); `--back=` cati metri
## inainte de canal porneste (implicit 45).

const RACE_SCENE: String = "res://scenes/race/Race.tscn"

class StraightController extends CarController:
	func get_throttle() -> float:
		return 1.0
	func get_steer() -> float:
		return 0.0
	func is_drift_pressed() -> bool:
		return false


var _race: Node = null
var _frames: int = 0
var _car: Car = null
var _shots: Array[String] = []
var _speed: float = 22.0
var _back: float = 45.0
var _label: String = ""
var _entered_at: int = -1
var _placed: bool = false
var _spray_seen: bool = false
var _burst_seen: bool = false
var _tag: String = ""


func _ready() -> void:
	var track_arg := 14
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_arg = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--speed="):
			_speed = float(arg.trim_prefix("--speed="))
		elif arg.begins_with("--back="):
			_back = float(arg.trim_prefix("--back="))
		elif arg.begins_with("--channel="):
			_label = arg.trim_prefix("--channel=")
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
	var resolved := GameState.resolve_track_index(track_arg)
	if resolved < 0:
		push_error("probe_splash: --track=%d nu e o pista din lista" % track_arg)
		get_tree().quit(1)
		return
	GameState.selected_track = resolved
	GameState.selected_car = 0
	GameState.champ_active = false
	GameState.total_laps = 99
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames == 5:
		_car = _race.player as Car
		var old: CarController = _car.controller
		_car.remove_child(old)
		old.free()
		_car.set_controller(StraightController.new())
		_car.race_active = true
		# Adversarii stau pe loc: sonda se uita la o singura masina.
		for other: Car in (_race.get("cars") as Array):
			if other != _car:
				other.freeze = true
		return
	if _car == null:
		return
	if _frames == 30 and not _placed:
		_placed = true
		if not _place_before_channel():
			get_tree().quit(2)
			return
	if not _placed:
		return
	if _frames > 30 and _frames < 400:
		# Tinem viteza pe orizontala (ca ProbeLife): sonda testeaza intrarea,
		# nu acceleratia.
		var fwd := -_car.global_basis.z
		fwd.y = 0.0
		fwd = fwd.normalized()
		var v := _car.velocity
		var h := Vector3(v.x, 0.0, v.z).length()
		if h < _speed and _entered_at < 0:
			_car.velocity = fwd * _speed + Vector3.UP * v.y
	if _car.in_water and _entered_at < 0:
		_entered_at = _frames
		print("probe_splash: INTRARE in apa la cadrul %d, pozitia %s, viteza %.1f m/s" % [
			_frames, _car.global_position, _car.horizontal_speed()])
		var burst := _car.get_node_or_null("WaterBurst") as CPUParticles3D
		print("  WaterBurst.emitting=%s  culoare=%s" % [
			str(burst.emitting) if burst != null else "lipsa",
			str(burst.color) if burst != null else "-"])
	if _entered_at > 0:
		var spray := _car.get_node_or_null("WaterSpray") as CPUParticles3D
		var burst := _car.get_node_or_null("WaterBurst") as CPUParticles3D
		if spray != null and spray.emitting:
			_spray_seen = true
		if burst != null and burst.emitting:
			_burst_seen = true
		var dt := _frames - _entered_at
		if dt == 3:
			_shot("splash_intrare")
		elif dt == 12:
			_shot("splash_strop")
		elif dt == 30:
			_shot("splash_spray")
		elif dt == 70:
			_shot("splash_iesire")
		elif dt == 90:
			_finish()
	elif _frames > 600:
		print("probe_splash: masina N-A INTRAT in apa in 600 de cadre (in_water niciodata true)")
		_finish()


## Aseaza masina pe sosea, `_back` metri inainte de canalul ales, cu botul
## spre el. Canalul e cel cu apa proprie (parau sau vad), nu unul la nivelul
## marii.
func _place_before_channel() -> bool:
	var track := _race.track as Track
	var chosen: Dictionary = {}
	for ch in track._channels:
		var drop := float(ch.get("water_y_drop", -1.0))
		if drop < 0.0 and not bool(ch.get("ford", false)):
			continue
		if _label != "" and String(ch.get("label", "")) != _label:
			continue
		chosen = ch
		break
	if chosen.is_empty():
		print("probe_splash: pista n-are canal cu apa proprie (parau/vad)")
		return false
	var idx: int = chosen["index"]
	var baked: PackedVector3Array = track.baked
	# Inapoi pe traseu pana la `_back` metri.
	var i := idx
	var walked := 0.0
	while walked < _back:
		var j := (i - 1 + baked.size()) % baked.size()
		walked += baked[i].distance_to(baked[j])
		i = j
	var fwd := (baked[(i + 1) % baked.size()] - baked[i])
	fwd.y = 0.0
	fwd = fwd.normalized()
	_car.global_transform = Transform3D(
		Basis.looking_at(fwd, Vector3.UP), baked[i] + Vector3.UP * 0.6)
	_car.velocity = fwd * _speed
	_car.road_index = i
	_car.last_safe_index = i
	var o: Vector3 = chosen["origin"]
	print("probe_splash: canal '%s' la %s (apa la y=%.2f), masina pornita din %s la %.0f m/s" % [
		String(chosen.get("label", "?")), o,
		track.water_level_at(o), baked[i], _speed])
	return true


func _finish() -> void:
	print("=== ProbeSplash: capturi salvate ===")
	for s in _shots:
		print("  ", s)
	print("in_water a devenit true: %s (cadrul %d)" % [
		"DA" if _entered_at > 0 else "NU", _entered_at])
	print("WaterBurst a emis: %s   WaterSpray a emis: %s" % [
		"DA" if _burst_seen else "NU", "DA" if _spray_seen else "NU"])
	get_tree().quit(0 if (_entered_at > 0 and _burst_seen and _spray_seen) else 1)


func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var path := "res://snapshots/%s%s.png" % [name, _tag]
	img.save_png(ProjectSettings.globalize_path(path))
	_shots.append(path)
