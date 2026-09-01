extends Node
## CINE UMPLE MARGINILE CADRULUI, si la ce COTE.
##
## Runda 27 cere strate rosii pe prim-plan si plan median, nu pe orizont. Ca sa
## le pui acolo trebuie sa stii CE piese ocupa banda 16-45 m si ce interval de
## Y de LUME acopera fiecare — banda de strat se taie pe cota, deci o cifra
## gresita o pune sub pamant sau deasupra palariei.
##
## Tipareste, pentru fiecare prop din DecorManual care are macar un pixel in
## cadru: distanta, aria pe ecran, cutia pe ecran si intervalul global de Y.
##   godot --headless --path . res://tools/ProbeCappStrate.tscn -- --frac=0.06
const MD := 7.5
const MH := 3.2
const MF := 68.0
const MLA := 14.0
const MLH := 1.2
const W := 1280
const H := 720


func _ready() -> void:
	await get_tree().process_frame
	var frac := 0.06
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frac="):
			frac = float(a.split("=")[1])
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 5:
		await get_tree().process_frame
	var cam := Camera3D.new()
	cam.fov = MF
	cam.near = 0.05
	cam.far = 400.0
	add_child(cam)
	get_viewport().size = Vector2i(W, H)
	await get_tree().process_frame
	var route: Object = t.route_at(0)
	var pts: PackedVector3Array = route.baked
	var n: int = pts.size()
	var idx: int = int(frac * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir: Vector3 = (ahead - focus).normalized()
	cam.global_position = focus - dir * MD + Vector3.UP * MH
	cam.look_at(focus + dir * MLA + Vector3.UP * MLH, Vector3.UP)
	await get_tree().process_frame
	print("camera la ", cam.global_position, "  focus Y=", focus.y)

	var dm: Node = t.get_node_or_null("DecorManual")
	if dm == null:
		push_error("fara DecorManual")
		get_tree().quit()
		return
	var rows: Array = []
	_walk(dm, cam, rows)
	rows.sort_custom(func(a, b): return a["d"] < b["d"])
	print("=== propuri cu pixeli in cadru, dupa distanta ===")
	print("dist   arie%%  x0..x1   y0..y1   Ylume min..max   parinte/nume  (model)")
	for r in rows:
		print("%6.1f %5.2f  %4d..%4d %4d..%4d  %6.1f..%6.1f  %s (%s)" % [
			r["d"], r["area"], r["x0"], r["x1"], r["y0"], r["y1"],
			r["ymin"], r["ymax"], r["path"], r["model"]])
	get_tree().quit()


func _walk(node: Node, cam: Camera3D, rows: Array) -> void:
	for c in node.get_children():
		var sp := c as Node3D
		if sp == null:
			continue
		if sp.scene_file_path.is_empty():
			_walk(sp, cam, rows)
			continue
		var aabb := _world_aabb(sp)
		if aabb.size == Vector3.ZERO:
			continue
		var x0 := 1e9
		var x1 := -1e9
		var y0 := 1e9
		var y1 := -1e9
		var vis := false
		for i in 8:
			var p: Vector3 = aabb.get_endpoint(i)
			if cam.is_position_behind(p):
				continue
			vis = true
			var s := cam.unproject_position(p)
			x0 = minf(x0, s.x)
			x1 = maxf(x1, s.x)
			y0 = minf(y0, s.y)
			y1 = maxf(y1, s.y)
		if not vis:
			continue
		if x1 < 0.0 or x0 > float(W) or y1 < 0.0 or y0 > float(H):
			continue
		var cx := clampf(x0, 0.0, W)
		var cx2 := clampf(x1, 0.0, W)
		var cy := clampf(y0, 0.0, H)
		var cy2 := clampf(y1, 0.0, H)
		var area := 100.0 * (cx2 - cx) * (cy2 - cy) / float(W * H)
		if area < 0.05:
			continue
		var ctr := aabb.get_center()
		rows.append({
			"d": cam.global_position.distance_to(ctr),
			"area": area,
			"x0": int(x0), "x1": int(x1), "y0": int(y0), "y1": int(y1),
			"ymin": aabb.position.y, "ymax": aabb.position.y + aabb.size.y,
			"path": String(sp.get_parent().name) + "/" + String(sp.name),
			"model": sp.scene_file_path.get_file().get_basename(),
		})


func _world_aabb(root: Node3D) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		var mi := nd as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.visible:
			continue
		var a := mi.global_transform * mi.mesh.get_aabb()
		if first:
			out = a
			first = false
		else:
			out = out.merge(a)
	return out
