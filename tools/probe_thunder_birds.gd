extends Node
## Teatrul Angkorului: stolul de egrete care se ridica la tunet (`ThunderBirds`).
##   1. la tunet (semnalul REAL al LightningFlash, nu apel direct) se ridica un stol: `lifts` creste,
##      stolul e vizibil, iar dupa ~1,5 s pasarile s-au departat de cuib;
##   2. dupa `flight_time` stolul dispare (nod ascuns, `_process` oprit);
##   3. acoperirea: pe cate din 100 de puncte ale traseului exista un cuib eligibil in fata masinii.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeThunderBirds.tscn -- --track=16

const RACE_SCENE := "res://scenes/race/Race.tscn"

var _race: Race
var _t := 0.0
var _go_t := -1.0
var _birds: ThunderBirds
var _flash: LightningFlash
var _phase := 0
var _t_phase := 0.0
var _origin := Vector3.ZERO
var _fails: PackedStringArray = []


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
		_birds = _race.track.get_node_or_null("PasariTunet") as ThunderBirds
		_flash = _race.track.get_node_or_null("Hazarduri/Fulger") as LightningFlash
		if _birds == null or _flash == null or _birds.multimesh == null:
			print("[birds] LIPSESC: stol=%s fulger=%s mm=%s" % [_birds, _flash,
				_birds.multimesh if _birds != null else null])
			print("VERDICT: PROBLEMA")
			get_tree().quit(1)
			return
		print("[birds] %d cuiburi, %d pasari, mesh %d triunghiuri" % [_birds.roosts.size(), _birds.birds,
			_birds.multimesh.mesh.get_surface_count()])
		_coverage()
		# Jucatorul la inceputul zonei D (cuiburi in fata).
		var r: TrackRoute = _race.track.route_at(0)
		var i := int(r.baked.size() * 0.34)
		var p := _race.player
		var dir := (r.baked[r.wrap_index(i + 3)] - r.baked[i])
		dir.y = 0.0
		p.global_transform = Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP), r.baked[i] + Vector3.UP)
		p.velocity = Vector3.ZERO
		return
	_t_phase += delta
	match _phase:
		0:
			if _t_phase > 1.0:
				print("[birds] vizibil inainte de tunet: %s" % _birds.visible)
				if _birds.visible:
					_fails.append("stolul e vizibil fara tunet")
				_flash.thunder.emit(0.8)
				print("[birds] tunet emis: lifts=%d activ=%s vizibil=%s" % [_birds.lifts, _birds.active, _birds.visible])
				if _birds.lifts != 1 or not _birds.visible:
					_fails.append("tunetul n-a ridicat stolul")
				_origin = _birds.pose(0).origin
				_phase = 1
				_t_phase = 0.0
		1:
			if _t_phase > 2.0:
				var far := 0.0
				var xs: Array[String] = []
				for k in _birds.birds:
					var o := _birds.pose(k).origin
					far = maxf(far, o.distance_to(_origin))
					if k < 3:
						xs.append(str(o.snapped(Vector3.ONE * 0.1)))
				print("[birds] la 2 s: cea mai departata pasare la %.1f m de cuib; ex %s" % [far, ", ".join(xs)])
				if far < 8.0:
					_fails.append("pasarile nu s-au departat (%.1f m)" % far)
				_phase = 2
				_t_phase = 0.0
		2:
			if _t_phase > _birds.flight_time + 1.2:
				print("[birds] dupa zbor: activ=%s vizibil=%s" % [_birds.active, _birds.visible])
				if _birds.active or _birds.visible:
					_fails.append("stolul n-a disparut dupa zbor")
				for f in _fails:
					print("    " + f)
				print("VERDICT: %s" % ("OK" if _fails.is_empty() else "PROBLEMA"))
				get_tree().quit(0)
				set_physics_process(false)


func _coverage() -> void:
	var r: TrackRoute = _race.track.route_at(0)
	var n := 100
	var ok := 0
	var gaps: PackedStringArray = []
	for k in n:
		var i := int(float(r.baked.size()) * k / n)
		var d := r.baked[r.wrap_index(i + 3)] - r.baked[i]
		if _birds.pick_roost(r.baked[i], d) != Vector3.INF:
			ok += 1
		else:
			gaps.append("%.2f" % (float(k) / n))
	print("[birds] acoperire: %d din %d puncte au un cuib in fata; fara: %s" % [ok, n, " ".join(gaps)])
