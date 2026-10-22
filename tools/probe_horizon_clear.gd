extends SceneTree
## Garda de orizont: cat de aproape de SOSEA ajunge geometria siluetelor de fundal.
##
## `_build_horizon` verifica degajarea doar in PIVOTUL piesei. Pe Ha Long piesele
## au 150-320 m latime (x1.0-1.56 la scara, rotatie la zar), deci jumatatea unui
## sir de turnuri trecea peste drum desi pivotul era la 120 m — raportat de
## dezvoltator la volan ca "blocuri gri, unele chiar in mijlocul pistei" (oct 2026).
##
## Aici se masoara VERTECSII, nu pivotul: pentru fiecare silueta, distanta minima
## in plan XZ de la orice vertex aflat deasupra solului pana la axa soselei.
##
## Rulare:
##   godot --headless --path . --script res://tools/probe_horizon_clear.gd -- --track=22
## Fara --track, toate pistele. Iesire 1 daca vreo silueta are un vertex mai
## aproape de sosea decat MIN_CLEAR_M; `--sabotaj` coboara pragul invers (orice
## silueta pica) ca sa dovedeasca faptul ca garda chiar masoara ceva.

## Cat de aproape de axa soselei are voie sa ajunga o silueta de fundal. Sub
## `fog_begin` (90-140 m pe toate temele) silueta nu mai e "fundal" — se citeste
## cu muchii, ca un obiect apropiat. 100 m e marginea de jos a cetii pe cele mai
## multe teme, iar degajarea minima relaxata din `_build_horizon` e 66 m.
const MIN_CLEAR_M: float = 100.0

var _paths: Array[String] = []
var _index: int = 0
var _track: Node = null
var _frames: int = 0
var _fail: int = 0
var _sabotaj: bool = false
var _measured: int = 0


func _initialize() -> void:
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
		elif arg == "--sabotaj":
			_sabotaj = true
	for i in range(1, 30):
		var path := "res://scenes/tracks/Track%02d.tscn" % i
		if not ResourceLoader.exists(path):
			continue
		if only < 0 or only == i:
			_paths.append(path)


func _process(_delta: float) -> bool:
	if _paths.is_empty():
		push_error("probe_horizon_clear: nicio pista")
		quit(1)
		return true
	if _track == null:
		if _index >= _paths.size():
			# Zero siluete masurate = sonda goala, nu verde (memoria
			# garda-verde-pe-zero-masuratori).
			if _measured == 0:
				print("probe_horizon_clear: ZERO siluete masurate -> PICA")
				quit(1)
				return true
			print("probe_horizon_clear: %d siluete, %d sub %.0f m -> %s" % [
				_measured, _fail, MIN_CLEAR_M, "PICA" if _fail > 0 else "OK"])
			quit(1 if _fail > 0 else 0)
			return true
		_track = (load(_paths[_index]) as PackedScene).instantiate()
		root.add_child(_track)
		_frames = 0
		return false
	_frames += 1
	if _frames < 3:
		return false
	_measure(_paths[_index].get_file().get_basename(), _track)
	root.remove_child(_track)
	_track.free()
	_track = null
	_index += 1
	return false


func _pick_names(track: Node) -> Dictionary:
	var names := {}
	var rings: Array = track.call("theme_flag", "horizon_rings", [])
	for ring in rings:
		for p in ring.get("picks", []):
			names[String(p)] = true
	var theme_picks: Array = track.call("theme_flag", "horizon_picks", [])
	for group in theme_picks:
		for p in group:
			names[String(p)] = true
	return names


func _measure(label: String, track: Node) -> void:
	var names := _pick_names(track)
	var baked: PackedVector3Array = track.get("baked")
	if names.is_empty() or baked.is_empty():
		print("%s: fara siluete de orizont din GLB" % label)
		return
	var limit := 1e9 if _sabotaj else MIN_CLEAR_M
	for container in track.get_children():
		var c3 := container as Node3D
		if c3 == null:
			continue
		for child in c3.get_children():
			if not names.has(String(child.name)):
				continue
			var best := 1e12
			var best_at := Vector3.ZERO
			for mi in child.find_children("*", "MeshInstance3D", true, false) \
					+ ([child] if child is MeshInstance3D else []):
				var m := mi as MeshInstance3D
				if m.mesh == null:
					continue
				var xf := m.global_transform
				for s in m.mesh.get_surface_count():
					var verts: PackedVector3Array = \
						m.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
					for v in verts:
						var w := xf * v
						var d := _road_dist(baked, w)
						# Doar ce iese deasupra soselei din dreptul ei conteaza:
						# un colt ingropat sub teren nu se vede.
						if d.x < best and w.y > d.y - 1.0:
							best = d.x
							best_at = w
			_measured += 1
			var bad := best < limit
			if bad:
				_fail += 1
			print("%s %-12s pivot (%5.0f,%5.0f) scara %.2f  minim %6.1f m la (%5.0f,%5.0f,%4.0f) %s" % [
				label, child.name, c3.global_position.x, c3.global_position.z,
				c3.scale.x, best, best_at.x, best_at.z, best_at.y,
				"<- SUB PRAG" if bad else ""])


## (distanta XZ pana la cel mai apropiat punct de axa, cota acelui punct)
static func _road_dist(baked: PackedVector3Array, w: Vector3) -> Vector2:
	var nearest := 1e18
	var y := 0.0
	for i in range(0, baked.size(), 2):
		var dx := baked[i].x - w.x
		var dz := baked[i].z - w.z
		var d2 := dx * dx + dz * dz
		if d2 < nearest:
			nearest = d2
			y = baked[i].y
	return Vector2(sqrt(nearest), y)
