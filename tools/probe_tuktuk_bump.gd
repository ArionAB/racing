extends Node
## Teatrul Angkorului: tuk-tuk-urile (remorca si motocicleta, `BumpProp` cu masa proprie) pe pista
## adevarata. Pentru fiecare masina din lista, o lovitura de 15 m/s in cateva piese, venind dinspre
## drum: cat a pierdut masina din viteza, cat s-a deplasat piesa.
##   Contract: Buggy-ul (usor) simte remorca, dar n-o ia ca pe un zid; Autobuzul o arunca.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTuktukBump.tscn -- --track=16

const RACE_SCENE := "res://scenes/race/Race.tscn"
const SPEED := 15.0
const CARS := ["buggy", "bus"]
const PER_CAR := 2

var _race: Race
var _t := 0.0
var _go_t := -1.0
var _pieces: Array[BumpProp] = []
var _car_i := 0
var _hit_n := 0
var _target: BumpProp
var _from := Vector3.ZERO
var _ram_t := 0.0
var _v_before := 0.0
var _v_after := -1.0
var _hit_t := -1.0
var _armed := false


func _ready() -> void:
	var idx := 16
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	GameState.selected_track = idx
	GameState.champ_active = false
	GameState.total_laps = 99
	GameState.ai_count = 0
	_race = (load(RACE_SCENE) as PackedScene).instantiate() as Race
	add_child(_race)


func _physics_process(delta: float) -> void:
	_t += delta
	if _race.state != Race.State.RUNNING:
		return
	if _go_t < 0.0:
		_go_t = _t
		for n in get_tree().get_nodes_in_group(&"bump_props"):
			var b := n as BumpProp
			if String(b.name).begins_with("Remorca") or String(b.name).begins_with("Moto"):
				_pieces.append(b)
		print("[tuktuk] %d piese (remorci + motociclete) din %d bump-abile" % [
			_pieces.size(), get_tree().get_nodes_in_group(&"bump_props").size()])
		for b in _pieces:
			print("[tuktuk]   %s %.0f kg la %s" % [b.name, b.mass, b.global_position.snapped(Vector3.ONE * 0.1)])
		return
	if _t - _go_t < 2.0:
		return
	if not _armed:
		_aim()
		return
	var p := _race.player
	_ram_t += delta
	var moved := is_instance_valid(_target) and _target.global_position.distance_to(_from) > 0.05
	if not moved:
		_v_before = p.horizontal_speed()
	elif _hit_t < 0.0:
		_hit_t = _ram_t
	if _hit_t >= 0.0 and _v_after < 0.0 and _ram_t >= _hit_t + 0.3:
		_v_after = p.horizontal_speed()
	if _ram_t > 2.5:
		var d := _target.global_position.distance_to(_from) if is_instance_valid(_target) else -1.0
		print("[tuktuk] %s vs %s (%.0f kg): piesa deplasata %.1f m, masina %.1f -> %.1f m/s (%.0f%%)" % [
			CARS[_car_i], _target.name, _target.mass, d, _v_before, _v_after,
			100.0 * _v_after / maxf(_v_before, 0.1)])
		_hit_n += 1
		_armed = false
		if _hit_n >= PER_CAR:
			_hit_n = 0
			_car_i += 1
			if _car_i >= CARS.size():
				print("VERDICT: OK")
				get_tree().quit(0)
				set_physics_process(false)


func _aim() -> void:
	var p := _race.player
	if _hit_n == 0:
		p.apply_data(load("res://scenes/cars/data/%s.tres" % CARS[_car_i]) as CarData)
		await get_tree().physics_frame
	# Piesele ating-ul deja loviti sunt mutate: ia urmatoarea neatinsa, alternand remorca/moto.
	var want := "Remorca" if _hit_n != 1 else "Moto"
	_target = null
	for b in _pieces:
		if is_instance_valid(b) and String(b.name).begins_with(want) and b.sleeping \
				and b.global_position.distance_to(b._home.origin) < 0.3:
			_target = b
			break
	if _target == null:
		print("[tuktuk] nicio piesa %s neatinsa" % want)
		_hit_n += 1
		return
	_pieces.erase(_target)
	var r: TrackRoute = _race.track.route_at(0)
	var i := r.closest_index_global(_target.global_position)
	var dir := _target.global_position - r.baked[i]
	dir.y = 0.0
	dir = dir.normalized()
	_from = _target.global_position
	var from := _from - dir * 10.0
	var q := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 6.0, from + Vector3.DOWN * 10.0)
	q.exclude = [p.get_rid()]
	var hit := p.get_world_3d().direct_space_state.intersect_ray(q)
	from.y = ((hit.position as Vector3).y if not hit.is_empty() else _from.y) + 1.0
	p.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), from)
	p.velocity = dir * SPEED
	p.angular_velocity = Vector3.ZERO
	_ram_t = 0.0
	_v_before = 0.0
	_v_after = -1.0
	_hit_t = -1.0
	_armed = true
