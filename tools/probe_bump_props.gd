extends Node
## #489: decorul mic bump-abil. Pe o cursa reala:
##   1. numara BumpProp-urile pistei (si plafonul), verifica ca la 3 s dupa GO,
##      fara niciun contact, dorm si stau pe loc (nu „explodeaza" la nastere
##      din colizorii statici vecini);
##   2. pune jucatorul la 9 m in fata piesei celei mai apropiate de drum si il
##      trimite in ea cu 15 m/s: cat s-a deplasat piesa si cata viteza a
##      pierdut masina (trebuie sa fie imprastiere, nu zid).
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeBumpProps.tscn -- --track=12

const RACE_SCENE := "res://scenes/race/Race.tscn"
const RAM_SPEED := 15.0

var _race: Race
var _t := 0.0
var _go_t := -1.0
var _phase := ""
var _props: Array[BumpProp] = []
var _start: Dictionary = {}
var _target: BumpProp
var _target_from := Vector3.ZERO
var _ram_t := 0.0
var _v_before := 0.0
var _v_after := -1.0
var _hit_t := -1.0
var _fails: PackedStringArray = []
var _ai_mode := false
const TRIES := 4
var _tried := 0
var _hits := 0
var _done: Array[BumpProp] = []


func _ready() -> void:
	var idx := 5
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	GameState.selected_track = idx
	GameState.champ_active = false
	GameState.total_laps = 99
	# `--ai`: plutonul complet, fara lovitura sondei — cate piese imprastie AI-ul
	# in primele 40 s (gimmick-ul de la Cappadocia, #508).
	_ai_mode = OS.get_cmdline_user_args().has("--ai")
	GameState.ai_count = 5 if _ai_mode else 0
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
			_props.append(b)
			_start[b] = b.global_position
		print("[bump-props] %s: %d piese (plafon %d)" % [
			GameState.track_label(GameState.selected_track), _props.size(),
			BumpProp.MAX_PER_TRACK])
		if _props.is_empty():
			_fails.append("nicio piesa bump-abila pe pista")
			_finish()
		return
	var p := _race.player
	if _ai_mode:
		if _t - _go_t > 40.0:
			var moved := 0
			for b in _props:
				if not is_instance_valid(b) or b.global_position.distance_to(_start[b]) > 0.5:
					moved += 1
			print("[bump-props] plutonul AI, 40 s: %d din %d piese imprastiate" % [moved, _props.size()])
			_finish()
		return
	match _phase:
		"":
			if _t - _go_t > 3.0:
				var awake := 0
				var moved := 0
				for b in _props:
					if not is_instance_valid(b):
						continue
					if not b.sleeping:
						awake += 1
					if b.global_position.distance_to(_start[b]) > 0.05:
						moved += 1
						print("[bump-props]   %s mutata %.2f m fara contact" % [b.name,
							b.global_position.distance_to(_start[b])])
				print("[bump-props] fara contact, la 3 s: %d treze, %d mutate > 5 cm" % [awake, moved])
				if moved > 0:
					_fails.append("%d piese s-au miscat fara contact" % moved)
				_aim(p)
		"ram":
			_ram_t += delta
			var moved := is_instance_valid(_target) \
				and _target.global_position.distance_to(_target_from) > 0.05
			if not moved:
				_v_before = p.horizontal_speed()
			elif _hit_t < 0.0:
				_hit_t = _ram_t
			if _hit_t >= 0.0 and _v_after < 0.0 and _ram_t >= _hit_t + 0.3:
				_v_after = p.horizontal_speed()
			if _ram_t > 2.0:
				var d := 0.0
				if is_instance_valid(_target):
					d = _target.global_position.distance_to(_target_from)
				print("[bump-props] lovita %s (%.1f kg): deplasata %.1f m; masina %.1f m/s inainte, %.1f m/s la 0,3 s dupa"
					% [_target.name, _target.mass, d, _v_before, _v_after])
				# Piesa pe trotuar, dupa un obstacol: masina nu ajunge la ea —
				# nu e verdict despre piesa. Conteaza doar loviturile reale.
				if d >= 1.0:
					_hits += 1
					if _v_after < _v_before * 0.6:
						_fails.append("masina oprita de %s (%.1f -> %.1f m/s)"
							% [_target.name, _v_before, _v_after])
				_tried += 1
				if _tried < TRIES and _tried < _props.size():
					_aim(p)
				else:
					print("[bump-props] lovituri reale %d din %d incercari" % [_hits, _tried])
					if _hits == 0:
						_fails.append("nicio piesa lovita nu s-a miscat")
					_finish()


## Piesa cea mai apropiata de axa drumului. Masina vine pe TANGENTA drumului,
## pe linia laterala a piesei, de la 9 m: din directia jucatorului ar fi
## trecut prin case (pe Chongqing a lovit un zid, nu scuterul).
func _aim(p: Car) -> void:
	var r: TrackRoute = _race.track.route_at(0)
	var best_d := INF
	var best_i := 0
	_ram_t = 0.0
	_v_before = 0.0
	_v_after = -1.0
	_hit_t = -1.0
	for b in _props:
		if not is_instance_valid(b) or _done.has(b):
			continue
		var i := r.closest_index_global(b.global_position)
		var d := r.lateral_distance(i, b.global_position)
		if d < best_d:
			best_d = d
			best_i = i
			_target = b
	_done.append(_target)
	_target_from = _target.global_position
	var tan := r.baked[r.wrap_index(best_i + 1)] - r.baked[r.wrap_index(best_i - 1)]
	tan.y = 0.0
	var dir := tan.normalized()
	var from := _target_from - dir * 9.0
	var q := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 6.0,
		from + Vector3.DOWN * 10.0)
	q.exclude = [p.get_rid()]
	var hit := p.get_world_3d().direct_space_state.intersect_ray(q)
	from.y = ((hit.position as Vector3).y if not hit.is_empty() else _target_from.y) + 1.0
	p.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), from)
	p.velocity = dir * RAM_SPEED
	p.angular_velocity = Vector3.ZERO
	print("[bump-props] tinta %s la %.1f m de axa drumului" % [_target.name, best_d])
	# `--control`: aceeasi lansare, fara tinta — cat franeaza drumul singur.
	if OS.get_cmdline_user_args().has("--control"):
		_target.global_position += Vector3.DOWN * 500.0
		_target.freeze = true
	_phase = "ram"


func _finish() -> void:
	for f in _fails:
		print("    " + f)
	print("VERDICT: %s" % ("OK" if _fails.is_empty() else "PROBLEMA"))
	get_tree().quit(0)
	set_physics_process(false)
