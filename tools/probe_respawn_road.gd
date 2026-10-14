extends Node
## #494: repunerea te aseaza pe drum, cu botul pe sensul de mers?
##
## Pentru fiecare pista, din `--samples` checkpoint-uri uniforme pe traseu (si pe
## fiecare banda deschisa), ia exact transformul pe care il foloseste
## `Car.respawn` (`Track.recovery_transform(index, 14)`) si verifica:
##   drum    — `is_on_road` la indexul cel mai apropiat (lateral + etaj);
##   sens    — botul pe tangenta drumului (cos > 0.9 pe orizontala);
##   sol     — sub masina e sol la cel mult 2,5 m (nu golul unei sarituri);
##   gabarit — cutia caroseriei (cu 0,5 m de joc lateral) nu atinge nimic.
##   godot --headless --path . res://tools/ProbeRespawnRoad.tscn -- [--track=4] [--samples=120]

const BACKOFF_M := 14.0
const BODY := Vector3(1.9, 0.8, 4.0)
const SIDE_CLEAR_M := 0.5

var _samples := 120
## `--axa`: doar axa (`Track.recovery_transform`), fara cautarea de loc liber
## din `Car._clear_recovery_transform` — linia de baza (28 / 1971 pe main).
var _axis_only := false
var _car: Car


func _ready() -> void:
	await get_tree().process_frame
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--samples="):
			_samples = int(arg.trim_prefix("--samples="))
		elif arg == "--axa":
			_axis_only = true
	var total_bad := 0
	var total := 0
	for ti in GameState.TRACK_SCENES.size():
		if only >= 0 and ti != only:
			continue
		var track := (load(GameState.TRACK_SCENES[ti]) as PackedScene).instantiate() as Track
		get_tree().root.add_child(track)
		# O masina reala, inghetata departe de pista: doar ca sa-i chemam
		# cautarea de loc liber (are nevoie de lume si de propriul colizor).
		_car = (load("res://scenes/cars/Car.tscn") as PackedScene).instantiate() as Car
		_car.track = track
		track.add_child(_car)
		_car.apply_data(GameState.CAR_DATA[0] as CarData)
		_car.global_position = Vector3(0, 5000, 0)
		_car.on_start_grid = true
		for f in 4:
			await get_tree().physics_frame
		var res := _probe(track)
		total_bad += res.x
		total += res.y
		print("[respawn-road] %-28s probleme %d / %d" % [
			GameState.track_label(ti), res.x, res.y])
		track.queue_free()
		await get_tree().process_frame
	print("[respawn-road] TOTAL probleme %d / %d" % [total_bad, total])
	print("VERDICT: %s" % ("OK" if total_bad == 0 else "PROBLEMA"))
	get_tree().quit(0)


func _probe(track: Track) -> Vector2i:
	var bad := 0
	var cases := 0
	var printed := 0
	var space := track.get_world_3d().direct_space_state
	for route in track.routes.size():
		if route != 0 and not track.branch_is_open(route):
			continue
		var r: TrackRoute = track.route_at(route)
		var n := r.baked.size()
		var count := _samples if route == 0 else maxi(_samples / 6, 4)
		for s in count:
			var i := s * n / count
			if route != 0 and i < 2:
				continue
			var t := track.recovery_transform(i, BACKOFF_M, route)
			if not _axis_only:
				_car.last_safe_index = i
				_car.last_safe_route = route
				t = _car._clear_recovery_transform(BACKOFF_M)
				# Pe o banda, cautarea poate continua pe bucla (inaintea furcii).
				var used := _car.last_safe_route
				var why_car := _check(track, space, t, used)
				cases += 1
				if why_car != "":
					bad += 1
					if printed < 10:
						printed += 1
						print("    ruta %d->%d idx %d frac %.3f pos (%.0f, %.1f, %.0f): %s" % [
							route, used, i, float(i) / float(n), t.origin.x,
							t.origin.y, t.origin.z, why_car])
				continue
			var why := _check(track, space, t, route)
			cases += 1
			if why != "":
				bad += 1
				if printed < 10:
					printed += 1
					print("    ruta %d idx %d frac %.3f pos (%.0f, %.1f, %.0f): %s" % [
						route, i, float(i) / float(n), t.origin.x, t.origin.y,
						t.origin.z, why])
	return Vector2i(bad, cases)


func _check(track: Track, space: PhysicsDirectSpaceState3D, t: Transform3D,
		route: int) -> String:
	var why: PackedStringArray = []
	var pos := t.origin
	var r: TrackRoute = track.route_at(route)
	var gi := r.closest_index_global(pos)
	if not track.is_on_road(gi, pos, route):
		why.append("in afara drumului")
	var tan := r.baked[r.wrap_index(gi + 2)] - r.baked[r.wrap_index(gi - 2)]
	tan.y = 0.0
	var fwd := -t.basis.z
	fwd.y = 0.0
	if tan.length() > 0.01 and fwd.length() > 0.01 \
			and fwd.normalized().dot(tan.normalized()) < 0.9:
		why.append("bot deviat (cos %.2f)" % fwd.normalized().dot(tan.normalized()))
	var down := PhysicsRayQueryParameters3D.create(pos, pos + Vector3.DOWN * 6.0)
	var hit := space.intersect_ray(down)
	if hit.is_empty():
		why.append("fara sol sub masina")
	elif pos.y - (hit.position as Vector3).y > 2.5:
		why.append("sol la %.1f m sub" % (pos.y - (hit.position as Vector3).y))
	var box := BoxShape3D.new()
	box.size = BODY + Vector3(SIDE_CLEAR_M * 2.0, 0.0, 0.0)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = box
	# Cutia sta cu talpa la 0,35 m peste locul unde ar fi rotile pe sol.
	var base_y := (hit.position as Vector3).y if not hit.is_empty() else pos.y - 1.2
	q.transform = Transform3D(t.basis, Vector3(pos.x, base_y + 0.35 + BODY.y * 0.5, pos.z))
	var hits := space.intersect_shape(q, 4)
	if not hits.is_empty():
		var names: PackedStringArray = []
		for h: Dictionary in hits:
			var c := h.collider as Node
			names.append(String(c.name) if c != null else "?")
		why.append("gabarit atins: %s" % ", ".join(names))
	return "; ".join(why)
