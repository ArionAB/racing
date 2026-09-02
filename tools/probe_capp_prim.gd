extends Node
## CARE hornuri ocupa prim-planul cadrului de sofer, si cu ce suprafata.
##
## Exista fiindca reprosul criticului e despre "cele trei stanci-erou din
## prim-plan, care ocupa 60% din cadru" — o afirmatie despre CADRU, nu despre
## lume. Fara lista lor pe nume, orice reparatie de palarie/usa/poala se
## imprastie pe 55 de noduri din care in cadru se vad 6.
##
## Proiecteaza AABB-ul fiecarui ChimneyShape in camera lui Snapshot --driver si
## raporteaza aria ecran (fractie din cadru) plus distanta, sortat descrescator.
##
##   godot --headless --path . res://tools/ProbeCappPrim.tscn -- --track=6 --frac=0.05

const MEASURE_DIST := 7.5
const MEASURE_HEIGHT := 2.6
const MEASURE_FOV := 60.0
const MEASURE_LOOK_AHEAD := 14.0
const MEASURE_LOOK_HEIGHT := 1.4


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	var fracs: Array[float] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--frac="):
			fracs.append(float(arg.trim_prefix("--frac=")))
	if fracs.is_empty():
		fracs = [0.05, 0.06]
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 6:
		await get_tree().process_frame

	var shapes: Array[Node] = []
	_collect(track, shapes)
	var pts := track.baked
	var n := pts.size()

	for frac in fracs:
		var i0 := int(frac * float(n)) % n
		var focus: Vector3 = pts[i0]
		var ahead: Vector3 = pts[(i0 + 12) % n]
		var dir := (ahead - focus).normalized()
		var eye := focus - dir * MEASURE_DIST + Vector3.UP * MEASURE_HEIGHT
		var target := focus + dir * MEASURE_LOOK_AHEAD + Vector3.UP * MEASURE_LOOK_HEIGHT
		var cam := Camera3D.new()
		get_tree().root.add_child(cam)
		cam.fov = MEASURE_FOV
		cam.near = 0.05
		cam.far = 400.0
		cam.global_position = eye
		cam.look_at(target, Vector3.UP)
		await get_tree().process_frame

		print("")
		print("=== hornuri in prim-plan, frac %.3f ===" % frac)
		print("  ochi=(%.1f, %.2f, %.1f)" % [eye.x, eye.y, eye.z])
		var rows: Array = []
		for s in shapes:
			var n3 := s as Node3D
			var ab := _world_aabb(n3)
			if ab.size == Vector3.ZERO:
				continue
			# Proiecteaza cele 8 colturi; sare daca tot AABB-ul e in spate.
			var minx := 1e9; var maxx := -1e9; var miny := 1e9; var maxy := -1e9
			var front := 0
			for c in 8:
				var p := ab.get_endpoint(c)
				if cam.is_position_behind(p):
					continue
				front += 1
				var sp := cam.unproject_position(p)
				minx = minf(minx, sp.x); maxx = maxf(maxx, sp.x)
				miny = minf(miny, sp.y); maxy = maxf(maxy, sp.y)
			if front == 0:
				continue
			# Aria intersectata cu ecranul 1280x720.
			var ix := maxf(0.0, minf(maxx, 1280.0) - maxf(minx, 0.0))
			var iy := maxf(0.0, minf(maxy, 720.0) - maxf(miny, 0.0))
			var area := (ix * iy) / (1280.0 * 720.0)
			if area <= 0.0005:
				continue
			rows.append({
				"name": n3.name,
				"area": area,
				"dist": eye.distance_to(ab.get_center()),
				"h": ab.size.y,
				"x": (minx + maxx) * 0.5,
			})
		rows.sort_custom(func(a, b): return a["area"] > b["area"])
		for r in rows:
			print("  %-16s aria %5.1f%%  dist %5.1f m  h %5.1f m  x_ecran %6.0f" % [
				r["name"], r["area"] * 100.0, r["dist"], r["h"], r["x"]])
		cam.queue_free()
	get_tree().quit()


func _collect(node: Node, out: Array[Node]) -> void:
	if node is ChimneyShape:
		out.append(node)
	for c in node.get_children():
		_collect(c, out)


func _world_aabb(n3: Node3D) -> AABB:
	var acc := AABB()
	var first := true
	var stack: Array[Node] = [n3]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		var mi := nd as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var ab := mi.global_transform * mi.mesh.get_aabb()
		if first:
			acc = ab
			first = false
		else:
			acc = acc.merge(ab)
	return acc
